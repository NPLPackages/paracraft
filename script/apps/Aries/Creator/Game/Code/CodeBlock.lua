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
	self.timers = nil;
	self.timers_pool = nil;
	self.actors = {};
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
		self.timers = self.timers or {};
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
		self.timers_pool = self.timers_pool or {};
		if(#self.timers_pool < 10) then
			self.timers_pool[#self.timers_pool+1] = timer;
		end
	end
end

function CodeBlock:SetTimeout(duration, callbackFunc)
	self:SetTimer(function(timer)
		if(callbackFunc) then
			callbackFunc();
		end
		self:KillTimer(timer);
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

	self.code_env = nil;
end

-- remove all timers without clearing actors.
function CodeBlock:Stop()
	self:RemoveTimers();
end

function CodeBlock:RemoveTimers()
	if(self.timers) then
		for timer, _ in pairs(self.timers) do
			timer:Change();
		end
		self.timers = nil;
	end
	if(self.timers_pool) then
		for _, timer in ipairs(self.timers_pool) do
			timer:Change();
		end
		self.timers_pool = nil;
	end
end

-- usually called when movie finished playing. 
function CodeBlock:RemoveAllActors()
	for i, actor in pairs(self.actors) do
		actor:OnRemove();
		actor:Destroy();
	end
	self.actors = {};
end

-- private function: do not call this function. 
function CodeBlock:AddActor(actor)
	self.actors[#(self.actors)+1] = actor;
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

function CodeBlock:OnTextEvent(text)
end

-- when the actor played through the given animation time (milliseconds)
function CodeBlock:RegisterTimeEvent(time, callbackFunc)
end


-- actor is clicked
function CodeBlock:RegisterClickEvent(callbackFunc)
end


function CodeBlock:RegisterKeyPressedEvent(keyname, callbackFunc)
end


function CodeBlock:RegisterTextEvent(text, callbackFunc)
end


function CodeBlock:BroadcastTextEvent(text)
end


function CodeBlock:BroadcastAndWaitTextEvent(text, callbackFunc, ...)
	
end