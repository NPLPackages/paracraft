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
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeUIActor.lua");
local CodeUIActor = commonlib.gettable("MyCompany.Aries.Game.Code.CodeUIActor");
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
CodeBlock:Signal("actorClicked", function(actor, mouse_button) end);
CodeBlock:Signal("actorCloned", function(actor, msg) end);
CodeBlock:Signal("actorCollided", function(actor, fromActor) end);
CodeBlock:Signal("codeUnloaded", function() end);
CodeBlock:Signal("stateChanged", function() end);

function CodeBlock:ctor()
	self.timers = {};
	self.timers_pool = {};
	self.actors = commonlib.UnorderedArraySet:new();
	self.events = {};
	self.startTime = 0;
end

function CodeBlock:Init(entityCode)
	self.entityCode = entityCode;
	self:AutoSetFilename();
	return self;
end

function CodeBlock:GetBlockName()
	if(not self.codename) then
		self.codename = self.entityCode and self.entityCode:GetDisplayName() or "";
	end
	return self.codename;
end

function CodeBlock:AutoSetFilename()
	if(self.entityCode) then
		local x,y,z = self.entityCode:GetBlockPos();
		if(x) then
			self:SetFilename(format("%s_block(%d, %d, %d)", self:GetBlockName(), x,y,z));
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
	self:StopLastTempCode();
	if(not self.isLoaded) then
		return;
	end
	self.isLoaded = nil;
	self:Stop();
end

-- stop all nearby code entity
function CodeBlock:StopAll()
	if(self:GetEntity()) then
		self:GetEntity():Stop();
	end
end

-- restart all nearby code entity
function CodeBlock:RestartAll()
	if(self:GetEntity()) then
		self:GetEntity():Restart();
	end
end

-- remove everything to unloaded state. 
function CodeBlock:Stop()
	self:Disconnect("actorClicked");
	self:Disconnect("actorCloned");
	self:Disconnect("actorCollided");
	self:RemoveTimers();
	self:RemoveAllActors();
	self:RemoveAllEvents();
	self:StopLastTempCode();
	self:SetOutput(0);

	self.code_env = nil;
	self.isLoaded = nil;
	GameLogic.GetCodeGlobal():RemoveCodeBlock(self);
	self.codename = nil;
	self:codeUnloaded();
	self:stateChanged();
end

-- remove all timers without clearing actors.
function CodeBlock:Pause()
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
	self.refActors = nil;
	self.refCodeBlock = nil;
	
	self.isRemovingActors = true;
	for i, actor in ipairs(self:GetActors()) do
		actor:OnRemove();
		actor:Destroy();
	end
	self:GetActors():clear();
	self.isRemovingActors = false;
	self:EnableActorPicking(false);
end

function CodeBlock:OnRemoveActor(actor)
	if(not self.isRemovingActors) then
		self:GetActors():removeByValue(actor);
	end
end

-- private function: do not call this function. 
function CodeBlock:AddActor(actor)
	self:GetActors():add(actor);
	actor:Connect("beforeRemoved", self:GetReferencedCodeBlock(), self:GetReferencedCodeBlock().OnRemoveActor);
	GameLogic.GetCodeGlobal():AddActor(actor);
end

function CodeBlock:GetActors()
	return self.refActors or self.actors;
end

function CodeBlock:GetLastActor()
	return self:GetActors()[#self:GetActors()];
end

-- referencing codeblock. It will share actors in the referenced code blocks. 
function CodeBlock:SetReferencedCodeBlock(codeBlock)
	if(self ~= codeBlock) then
		if(codeBlock) then
			if(self.refActors ~= codeBlock:GetActors()) then
				self.refActors = codeBlock:GetActors();
				codeBlock:Connect("actorClicked", self, self.OnClickActor, "UniqueConnection");
				codeBlock:Connect("actorCloned", self, self.OnCloneActor, "UniqueConnection");
				codeBlock:Connect("actorCollided", self, self.OnCollideActor, "UniqueConnection");
				self.refCodeBlock = codeBlock;
			end
		elseif(self.refActors) then
			self.refActors = nil;
			self.refCodeBlock = nil;
		end
	end
end

function CodeBlock:HasReferencedCodeBlock()
	return self.refActors ~= nil;
end

function CodeBlock:GetReferencedCodeBlock()
	return self.refCodeBlock or self;
end

-- get the last actor in all nearby connected code block. 
function CodeBlock:FindNearbyActor()
	local actor = self:GetLastActor();
	if(not actor and self:GetEntity() and not self:HasReferencedCodeBlock()) then
		local function getLastActor_(codeEntity)
			local x,y,z = codeEntity:GetBlockPos();
			if(codeEntity:GetNearByMovieEntity(x,y,z)) then
				local codeblock = codeEntity:GetCodeBlock();
				if(codeblock) then
					self:SetReferencedCodeBlock(codeblock);
					actor = codeblock:GetLastActor();
				end
				return true;
			end
		end
		self:GetEntity():ForEachNearbyCodeEntity(getLastActor_);
	end
	return actor;
end

function CodeBlock:GetMovieEntity()
	return self.entityCode:FindNearByMovieEntity();
end

function CodeBlock:GetEntity()
	return self.entityCode;
end


-- create a new actor from the nearby movie block. 
-- Please note one may create multiple actors from the same block.
-- return nil if no actor is found.
function CodeBlock:CreateActor()
	local actor = self:CreateFirstActorInMovieBlock();
	if(actor) then
		actor:SetName(self.entityCode:GetDisplayName());
		self:AddActor(actor);
		-- use time 0
		actor:SetTime(0);
		actor:FrameMove(0, false);
		local parentCodeBlock = self:GetReferencedCodeBlock();
		if(self:IsActorPickingEnabled()) then
			actor:EnableActorPicking(true);
			actor:Connect("clicked", parentCodeBlock, parentCodeBlock.OnClickActor);
		else
			actor:EnableActorPicking(false);
		end
		actor:Connect("collided", parentCodeBlock, parentCodeBlock.OnCollideActor);
		return actor;
	end
end

function CodeBlock:EnableActorPicking(bEnabled)
	if(self:GetActors().enableActorPicking ~= bEnabled) then
		self:GetActors().enableActorPicking	= bEnabled;
		if(bEnabled) then
			local parentCodeBlock = self:GetReferencedCodeBlock();
			for i, actor in ipairs(self:GetActors()) do
				if(not actor:IsActorPickingEnabled()) then
					actor:EnableActorPicking(true);
					actor:Connect("clicked", parentCodeBlock, parentCodeBlock.OnClickActor);
				end
			end
		end
	end
end

function CodeBlock:IsActorPickingEnabled()
	return self:GetActors().enableActorPicking;
end

-- private: 
function CodeBlock:CreateFirstActorInMovieBlock()
	local movie_entity = self:GetMovieEntity();
	if(movie_entity) then
		if movie_entity and movie_entity.inventory then
			for i = 1, movie_entity.inventory:GetSlotCount() do
				local itemStack = movie_entity.inventory:GetItem(i)
				if (itemStack and itemStack.count > 0) then
					if (itemStack.id == block_types.names.TimeSeriesNPC) then
						return CodeActor:new():Init(itemStack, movie_entity);
					elseif (itemStack.id == block_types.names.TimeSeriesOverlay) then
						return CodeUIActor:new():Init(itemStack, movie_entity);
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

-- recompile and run
function CodeBlock:Restart()
	if(self:GetEntity()) then
		self:Unload();
		return self:Run();
	end
end

-- run code again 
function CodeBlock:Run()
	self:CompileCode(self:GetEntity():GetCommand());
	if(self.code_func) then
		self:ResetTime();
		self.isLoaded = true;
		self:stateChanged();
		local co = CodeCoroutine:new():Init(self);
		co:SetFunction(self.code_func);
		local actor = self:FindNearbyActor() or self:CreateActor();
		co:SetActor(actor);
		GameLogic.GetCodeGlobal():AddCodeBlock(self);
		return co:Run();
	end
end

function CodeBlock:send_message(msg)
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
	self:EnableActorPicking(true);
	local event = self:CreateEvent("onClickActor");
	event:SetIsFireForAllActors(false);
	event:SetFunction(callbackFunc);
end

function CodeBlock:OnClickActor(actor, mouse_button)
	self:FireEvent("onClickActor", actor);
	self:actorClicked(actor, mouse_button);
end

-- @param keyname: if nil or "any", it means any key, such as "a-z", "space", "return", "escape"
-- case incensitive
function CodeBlock:RegisterKeyPressedEvent(keyname, callbackFunc)
	local event = self:CreateEvent("onKeyPressed");
	event:SetIsFireForAllActors(true);
	event:SetFunction(callbackFunc);
	keyname = GameLogic.GetCodeGlobal():GetKeyNameFromString(keyname) or keyname;
	
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
			return true;
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
		event:Fire(msg and msg.msg, msg and msg.onFinishedCallback);
	end
	event:Connect("beforeDestroyed", function()
		GameLogic.GetCodeGlobal():UnregisterTextEvent(text, onEvent_);
	end)
	GameLogic.GetCodeGlobal():RegisterTextEvent(text, onEvent_);
end

-- @param onFinishedCallback: can be nil
function CodeBlock:BroadcastTextEvent(text, msg, onFinishedCallback)
	if(type(text) == "string") then
		GameLogic.GetCodeGlobal():BroadcastTextEvent(text, msg, onFinishedCallback);
	end
end

function CodeBlock:RegisterCloneActorEvent(callbackFunc)
	local event = self:CreateEvent("onCloneActor");
	event:SetFunction(callbackFunc);
end

-- create a clone of some code block's actor
-- @param name: if nil or "myself", it means clone myself
-- @param msg: any mesage that is forwared to clone event
function CodeBlock:CreateClone(name, msg)
	if(not name or name == "myself") then
		self:CloneMyself(msg);
	else
		local codeBlock = self:GetCodeBlockByName(name);
		if(codeBlock) then
			codeBlock:CloneMyself(msg);
		end
	end
end

function CodeBlock:GetCodeBlockByName(name)
	return GameLogic.GetCodeGlobal():GetCodeBlockByName(name);
end

function CodeBlock:CloneMyself(msg)
	local actor = self:CreateActor();
	if(actor) then
		self:GetReferencedCodeBlock():OnCloneActor(actor, msg);
	end
end

function CodeBlock:OnCloneActor(actor, msg)
	self:FireEvent("onCloneActor", actor, msg);
	self:actorCloned(actor, msg);
end

-- blink the created actor 
function CodeBlock:HighlightActors()
	local actors = self:GetActors();
	if(actors:last()) then
		for i = 1, math.min(10, #actors) do
			local actor = actors[i];
			actor:SetHighlight(true);
			commonlib.TimerManager.SetTimeout(function()  
				actor:SetHighlight(false);
			end, 1000 + i*100);
		end
	end
end

function CodeBlock:CreateGetActor()
	local env = self:GetCodeEnv();
	if(env) then
		return env.actor or self:FindNearbyActor() or self:CreateActor();
	end
end

function CodeBlock:GetActor()
	local env = self:GetCodeEnv();
	if(env) then
		return env.actor or self:FindNearbyActor();
	end
end

-- usually from help window. There can only be one temp code running. 
-- @param code: string
function CodeBlock:RunTempCode(code, filename)
	local code_func, errormsg = CodeCompiler:new():SetFilename(filename or "tempcode"):Compile(code);
	if(not code_func and errormsg) then
		LOG.std(nil, "error", "CodeBlock", errormsg);
		local msg = errormsg;
		msg = format(L"编译错误: %s\n在%s", msg, filename);
		self:send_message(msg);
	else
		local env = self:GetCodeEnv();
		if(env) then
			self:StopLastTempCode();
			local co = CodeCoroutine:new():Init(self);
			self.lastTempCodeCoroutine = co;
			self:stateChanged();
			local actor = env.actor or self:FindNearbyActor() or self:CreateActor();
			co:SetActor(actor);
			co:SetFunction(code_func);
			co:Run()
		end
	end
end

function CodeBlock:HasRunningTempCode()
	if(self.lastTempCodeCoroutine) then
		return true;
	end
end

function CodeBlock:StopLastTempCode()
	if(self.lastTempCodeCoroutine) then
		self.lastTempCodeCoroutine:Stop();
		self.lastTempCodeCoroutine = nil;
	end
end

-- in seconds
function CodeBlock:GetTime()
	return (commonlib.TimerManager.GetCurrentTime() - self.startTime)/1000;
end

function CodeBlock:ResetTime()
	self.startTime = commonlib.TimerManager.GetCurrentTime()
end

-- collision event is special that it will not overwrite the last event.
function CodeBlock:RegisterCollisionEvent(name, callbackFunc)
	local event = self:CreateEvent("onCollideActor");
	event:SetIsFireForAllActors(false);
	event:SetStopLastEvent(false);
	event:SetCanFireCallback(function(actor, fromActor)
		if(fromActor and fromActor:GetName() == name) then
			return true;
		end
	end);
	event:SetFunction(callbackFunc);
end

function CodeBlock:OnCollideActor(actor, fromActor)
	self:FireEvent("onCollideActor", actor, fromActor);
	self:actorCollided(actor, fromActor);
end

-- set code block entity's output value. default to nil.
function CodeBlock:SetOutput(result)
	if(self:GetEntity()) then
		self:GetEntity():SetLastCommandResult(result);
	end
end