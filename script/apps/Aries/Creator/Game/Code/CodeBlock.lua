--[[
Title: CodeBlock
Author(s): LiXizhi
Date: 2018/5/16
Desc: 
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
local CodeActor = commonlib.gettable("MyCompany.Aries.Game.Code.CodeActor");
local CodeAPI = commonlib.gettable("MyCompany.Aries.Game.Code.CodeAPI");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local CodeBlock = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlock"));
CodeBlock:Property("Name", "CodeBlock");

function CodeBlock:ctor()
	self.timers = nil;
	self.timers_pool = nil;
	self.actors = {};
end

function CodeBlock:Init(entityCode)
	self.entityCode = entityCode;
	return self;
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

-- compile code
-- @param code: string
-- return error message if any
function CodeBlock:CompileCode(code)
	if(self.last_code ~= code) then
		self:Unload();
		self.last_code = code;
		self.code_func, self.errormsg = loadstring(code, self:GetFilename());
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

	self.code_env = nil;

	self:RemoveAllActors();
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
	local actor;
	local movie_entity = self:GetMovieEntity();
	if(movie_entity) then
		if movie_entity and movie_entity.inventory then
			for i = 1, movie_entity.inventory:GetSlotCount() do
				local itemStack = movie_entity.inventory:GetItem(i)
				if (itemStack and itemStack.count > 0 and itemStack.serverdata) then
					if (itemStack.id == block_types.names.TimeSeriesNPC) then
						actor = CodeActor:new():Init(itemStack, movie_entity);
						break;
					end
				end
			end
		end
	end
	if(actor) then
		self:AddActor(actor);
		-- use time 0
		actor:SetTime(0);
		actor:FrameMove(0, false);
		return actor;
	end
end

-- run code again 
function CodeBlock:Run()
	self:Unload();

	if(self.code_func) then
		self.isLoaded = true;
		local code_env = CodeAPI:new(self, self:CreateActor());
		local co = coroutine.create(function()
			self:RunImp(code_env);
			return nil, "finished";
		end)
		code_env.co = co;
		coroutine.resume(co);
	end
end

function CodeBlock:send_error(msg, code_env)
	-- TODO: show to user
end

-- this function may be nest-called such as inside the code_env.include() function. 
-- @param code_env: the code enviroment. echo and print method should be overridden to send. 
-- @return the result of the function call. 
function CodeBlock:RunImp(code_env)
	if(self.code_func) then
		setfenv(self.code_func, code_env);
		local ok, result = pcall(self.code_func);

		if(not ok) then
			LOG.std(nil, "error", "CodeBlock", "<Runtime error>: %s in %s", tostring(result), last_filename or "");
			if(not code_env.is_exit_call) then
				self:send_error(tostring(result));
			else
				if(code_env.exit_msg) then
					self:send_error(tostring(code_env.exit_msg));
				end
				code_env.is_exit_call = nil;
			end
		end		
		return result;
	end
end