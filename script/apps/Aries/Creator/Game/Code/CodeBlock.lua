--[[
Title: CodeBlock
Author(s): LiXizhi
Date: 2018/5/16
Desc: In addition to object oriented programming(oop), paracraft code block features an memory-oriented-programming(mop) model. 
The smallest memory unit is an animation clip over time. So we can also call it animation-oriented programming model. 
A program is made up of code block, where each code block is associated with one movie block, which contains a short animation
clip for an actor. Code block exposes a `CodeAPI` that can programmatically control the actor inside the movie block. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlock.lua");
local CodeBlock = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlock");
local codeBlock = CodeBlock:new():Init(entityCode);
codeBlock:CompileCode('say("hi"); wait(2); say("bye")');
codeBlock:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeActor.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCompiler.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCoroutine.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeEvent.lua");
local CodeEvent = commonlib.gettable("MyCompany.Aries.Game.Code.CodeEvent");
local CodeCoroutine = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCoroutine");
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
local CodeActor = commonlib.gettable("MyCompany.Aries.Game.Code.CodeActor");
local CodeAPI = commonlib.gettable("MyCompany.Aries.Game.Code.CodeAPI");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local CodeBlock = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlock"));
CodeBlock:Property("Name", "CodeBlock");
CodeBlock:Property({"DefaultTick", 0.02, "GetDefaultTick", "SetDefaultTick", auto=true,});

CodeBlock:Signal("message", function(errMsg) end);

function CodeBlock:ctor()
	self.timers = {};
	self.timers_pool = {};
	self.actors = commonlib.UnorderedArraySet:new();
	self.events = {};
end

function CodeBlock:Init(entityCode)
	self.entityCode = entityCode;
	self:AutoSetFilename();
	return self;
end

function CodeBlock:AutoSetFilename()
	if(self.entityCode) then
		local x,y,z = self.entityCode:GetBlockPos();
		if(x) then
			self:SetFilename(format("block(%d, %d, %d)", x,y,z));
		end
	end
end

function CodeBlock:Destroy()
	self:Unload();
	CodeBlock._super.Destroy(self);
end

-- return the timer object
function CodeBlock:SetTimer(callbackFunc, dueTime, period)
	local timer;
	if(self.timers_pool and #self.timers_pool > 0) then
		timer = self.timers_pool[#self.timers_pool];
		self.timers_pool[#self.timers_pool] = nil;
		timer.callbackFunc = callbackFunc;
	else
		timer = commonlib.Timer:new({callbackFunc = callbackFunc})
	end
	self.timers[timer] = true;
	timer:Change(dueTime, period);
	return timer;
end

function CodeBlock:KillTimer(timer)
	timer:Change();
	if(self.timers[timer]) then
		self.timers[timer] = nil;
		if(#self.timers_pool < 10) then
			self.timers_pool[#self.timers_pool+1] = timer;
		end
	end
end

function CodeBlock:SetTimeout(duration, callbackFunc)
	return self:SetTimer(function(timer)
		self:KillTimer(timer);
		if(callbackFunc) then
			callbackFunc(timer);
		end
	end, duration, nil)
end

-- compile code and reload if code is changed. 
-- @param code: string
-- return error message if any
function CodeBlock:CompileCode(code)
	if(self.last_code ~= code) then
		self:Unload();
		self.last_code = code;
		self.code_func, self.errormsg = CodeCompiler:new():SetFilename(self:GetFilename()):Compile(code);
		if(not self.code_func and self.errormsg) then
			LOG.std(nil, "error", "CodeBlock", self.errormsg);
			local msg = self.errormsg;
			msg = format(L"编译错误: %s\n在%s", msg, self:GetFilename());
			self:send_message(msg);
		else
			self:send_message(L"编译成功!");
		end
	end
	return self.errormsg;
end

-- get default virtual code block filename. 
function CodeBlock:GetFilename()
	return self.filename or "";
end

function CodeBlock:SetFilename(filename)
	self.filename = filename;
end

function CodeBlock:IsLoaded()
	return self.isLoaded;
end

-- unload code and related entities
function CodeBlock:Unload()
	if(not self.isLoaded) then
		return;
	end
	self.isLoaded = nil;
	
	self:RemoveTimers();
	self:RemoveAllActors();
	self:RemoveAllEvents();

	self.code_env = nil;
end

-- remove all timers without clearing actors.
function CodeBlock:Stop()
	self:RemoveTimers();
	self:RemoveAllEvents();
end

function CodeBlock:RemoveAllEvents()
	for name, events in pairs(self.events) do
		for _, event in ipairs(events) do
			event:Destroy();
		end
	end
	self.events = {};
end

function CodeBlock:RemoveTimers()
	if(self.timers) then
		for timer, _ in pairs(self.timers) do
			timer:Change();
		end
		self.timers = {};
	end
	if(self.timers_pool) then
		for _, timer in ipairs(self.timers_pool) do
			timer:Change();
		end
		self.timers_pool = {};
	end
end

-- usually called when movie finished playing. 
function CodeBlock:RemoveAllActors()
	for i, actor in ipairs(self.actors) do
		actor:OnRemove();
		actor:Destroy();
	end
	self.actors:clear();
end

function CodeBlock:GetActors()
	return self.actors;
end

-- private function: do not call this function. 
function CodeBlock:AddActor(actor)
	self.actors:add(actor);
end

function CodeBlock:GetMovieEntity()
	return self.entityCode:FindNearByMovieEntity();
end

-- create a new actor from the nearby movie block. 
-- Please note one may create multiple actors from the same block.
-- return nil if no actor is found.
function CodeBlock:CreateActor()
	local actor = self:CreateFirstActorInMovieBlock();
	if(actor) then
		self:AddActor(actor);
		-- use time 0
		actor:SetTime(0);
		actor:FrameMove(0, false);
		actor:Connect("clicked", self, self.OnClickActor);
		return actor;
	end
end

-- private: 
function CodeBlock:CreateFirstActorInMovieBlock()
	local movie_entity = self:GetMovieEntity();
	if(movie_entity) then
		if movie_entity and movie_entity.inventory then
			for i = 1, movie_entity.inventory:GetSlotCount() do
				local itemStack = movie_entity.inventory:GetItem(i)
				if (itemStack and itemStack.count > 0 and itemStack.serverdata) then
					if (itemStack.id == block_types.names.TimeSeriesNPC) then
						return CodeActor:new():Init(itemStack, movie_entity);
					end
				end
			end
		end
	end
end

function CodeBlock:GetCodeEnv()
	if(not self.code_env) then
		self.code_env = CodeAPI:new(self);
	end
	return self.code_env;
end

function CodeBlock:IsLoaded()
	return self.isLoaded;
end

-- run code again 
function CodeBlock:Run()
	self:Unload();

	if(self.code_func) then
		self.isLoaded = true;
		local co = CodeCoroutine:new():Init(self);
		co:SetFunction(self.code_func);
		co:SetActor(self:CreateActor());
		return co:Run();
	end
end

function CodeBlock:send_message(msg, code_env)
	self.lastMessage = msg;
	self:message(msg);
end

function CodeBlock:GetLastMessage()
	return self.lastMessage;
end

-- @param msg: optional message to be passed to event callback
function CodeBlock:FireEvent(event_name, actor, msg)
	event_name = event_name or "";
	local events = self.events[event_name];
	if(events) then
		for _, event in ipairs(events) do
			if(actor) then
				event:SetActor(actor);
			end
			event:Fire(msg);
		end
	end
end

function CodeBlock:CreateEvent(event_name)
	event_name = event_name or "";
	local event = CodeEvent:new():Init(self, event_name);
	
	local events = self.events[event_name];
	if(not self.events[event_name]) then
		events = {};
		self.events[event_name] = events;
	end
	events[#events + 1] = event;
	return event;
end

-- when the actor start/end playing at the given time (milliseconds)
-- Only the start and end of an animation is fired. 
function CodeBlock:RegisterAnimationEvent(time, callbackFunc)
	if(callbackFunc and time) then
		local event = self:CreateEvent("onAnimateActor");
		event:SetIsFireForAllActors(false);
		event:SetCanFireCallback(function(actor, curTime)
			return (time == curTime);
		end);
		event:SetFunction(callbackFunc);
	end
end

function CodeBlock:OnAnimateActor(actor, time)
	self:FireEvent("onAnimateActor", actor, time)
end

-- actor is clicked
function CodeBlock:RegisterClickEvent(callbackFunc)
	local event = self:CreateEvent("onClickActor");
	event:SetIsFireForAllActors(false);
	event:SetFunction(callbackFunc);
end

function CodeBlock:OnClickActor(actor, mouse_button)
	self:FireEvent("onClickActor", actor)
end

function CodeBlock:GetKeyNameFromString(name)
	if(name and DIK_SCANCODE["DIK_"..string.upper(name)]) then
		return "DIK_"..string.upper(name);
	end
	return name;
end

function CodeBlock:GetStringFromKeyName(name)
	if(name) then
		return string.lower(name:gsub("^(DIK_)" ,""));
	end
end

-- @param keyname: if nil or "any", it means any key, such as "a-z", "space", "return", "escape"
-- case incensitive
function CodeBlock:RegisterKeyPressedEvent(keyname, callbackFunc)
	local event = self:CreateEvent("onKeyPressed");
	event:SetIsFireForAllActors(true);
	event:SetFunction(callbackFunc);
	keyname = self:GetKeyNameFromString(keyname);
	
	local function onEvent_(_, msg)
		if(not msg) then
			return 
		end
		local bFire;
		if(not keyname or keyname == "any") then
			bFire = true;
		elseif(keyname == msg.keyname) then
			bFire = true;
		end
		if(bFire) then
			event:Fire();
		end
	end
	event:Connect("beforeDestroyed", function()
		GameLogic.GetCodeGlobal():UnregisterKeyPressedEvent(onEvent_);
	end)
	GameLogic.GetCodeGlobal():RegisterKeyPressedEvent(onEvent_);
end


function CodeBlock:RegisterTextEvent(text, callbackFunc)
	local event = self:CreateEvent("onText"..text);
	event:SetIsFireForAllActors(true);
	event:SetFunction(callbackFunc);
	local function onEvent_(_, msg)
		event:Fire(nil, msg and msg.onFinishedCallback);
	end
	event:Connect("beforeDestroyed", function()
		GameLogic.GetCodeGlobal():UnregisterTextEvent(text, onEvent_);
	end)
	GameLogic.GetCodeGlobal():RegisterTextEvent(text, onEvent_);
end

-- @param onFinishedCallback: can be nil
function CodeBlock:BroadcastTextEvent(text, onFinishedCallback)
	if(type(text) == "string") then
		GameLogic.GetCodeGlobal():BroadcastTextEvent(text, onFinishedCallback);
	end
end

function CodeBlock:RegisterCloneActorEvent(callbackFunc)
	local event = self:CreateEvent("onCloneActor");
	event:SetFunction(callbackFunc);
end

-- create a clone of some code block's actor
-- @param name: if nil or "myself", it means clone myself
function CodeBlock:CreateClone(name)
	if(not name or name == "myself") then
		self:CloneMyself();
	else
		local codeBlock = self:GetCodeBlockByName(name);
		if(codeBlock) then
			codeBlock:CloneMyself();
		end
	end
end

function CodeBlock:GetCodeBlockByName(name)
	-- TODO
end

function CodeBlock:CloneMyself()
	local actor = self:CreateActor();
	if(actor) then
		self:FireEvent("onCloneActor", actor);
	end
end

function CodeBlock:DeleteActor(actor)
	if(actor and self.actors:contains(actor)) then
		actor:OnRemove();
		actor:Destroy();
		self.actors:remove(actor);
	end
end

-- blink the created actor 
function CodeBlock:HighlightActors()
	if(self.actors:last()) then
		for i = 1, math.min(10, #self.actors) do
			local actor = self.actors[i];
			actor:SetHighlight(true);
			commonlib.TimerManager.SetTimeout(function()  
				actor:SetHighlight(false);
			end, 1000 + i*100);
		end
	end
end