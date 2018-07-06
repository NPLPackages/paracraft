--[[
Title: Code Coroutine
Author(s): LiXizhi
Date: 2018/5/30
Desc: call back functions or the main function that must be executed in a separate coroutine. 
All coroutines share the same CodeAPI environment, except for current actor. 
MakeCallbackFunc will restore last actor and coroutine context.
Run the same coroutine multiple times will cause the previous one to stop forever.
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCoroutine.lua");
local CodeCoroutine = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCoroutine");
local co = CodeCoroutine:new():Init(codeBlock);
co:SetFunction(func)
co:SetActor(actor)
co:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeActor.lua");
local CodeAPI = commonlib.gettable("MyCompany.Aries.Game.Code.CodeAPI");
local CodeCoroutine = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeCoroutine"));

function CodeCoroutine:ctor()
end

function CodeCoroutine:Init(codeBlock)
	self.codeBlock = codeBlock;
	return self;
end

function CodeCoroutine:Destroy()
	CodeCoroutine._super.Destroy(self);
end

function CodeCoroutine:SetFunction(code_func)
	self.code_func = code_func;
end

function CodeCoroutine:AddTimer(timer)
	self.timers = self.timers or {}
	self.timers[timer] = true;
end

function CodeCoroutine:RemoveTimer(timer)
	if(self.timers) then
		self.timers[timer] = nil;
	end
end

function CodeCoroutine:KillAllTimers()
	if(self.timers) then
		for timer, _ in pairs(self.timers) do
			self.codeBlock:KillTimer(timer);
		end
		self.timers = nil;
	end
end

function CodeCoroutine:KillTimer(timer)
	self:RemoveTimer(timer);
	self:GetCodeBlock():KillTimer(timer);
end

-- @param bRestoreContext: true to restore context. default to nil. One must set to true if the callbackFunc may invoke other coroutines
function CodeCoroutine:MakeCallbackFunc(callbackFunc, bRestoreContext)
	return function(...)
		local last_context = bRestoreContext and self:SaveCurrentContext();
		self:PrepareCodeContext();
		if(callbackFunc) then
			callbackFunc(...);
		end
		if(last_context) then
			self:RestoreContext(last_context);
		end
	end
end

function CodeCoroutine:SetTimer(callbackFunc, dueTime, period)
	local timer = self:GetCodeBlock():SetTimer(self:MakeCallbackFunc(callbackFunc), dueTime, period);
	self:AddTimer(timer);
	return timer;
end

function CodeCoroutine:SetTimeout(duration, callbackFunc)
	local timer = self:GetCodeBlock():SetTimeout(duration, function(timer)
		self:PrepareCodeContext();
		self:RemoveTimer(timer);
		if(callbackFunc) then
			callbackFunc(timer);
		end
	end);
	self:AddTimer(timer);
	return timer;
end

function CodeCoroutine:SetActor(actor)
	self.actor = actor;
end

function CodeCoroutine:GetActor()
	return self.actor;
end

function CodeCoroutine:GetCodeBlock()
	return self.codeBlock;
end

-- @return : "running", "dead", "suspended", nil
function CodeCoroutine:GetStatus()
	return self.co and coroutine.status(self.co);
end

function CodeCoroutine:InRunning()
	return not self.isStopped;
end

-- when stopped, it can no longer be resumed
function CodeCoroutine:Stop()
	self.isStopped = true;
	-- we need to stop the last coroutine timers, before starting a new one. 
	self:KillAllTimers();
end

-- @return saved context {co, actor};
function CodeCoroutine:SaveCurrentContext()
	local code_env = self:GetCodeBlock():GetCodeEnv();
	return {co = code_env.co, actor = code_env.actor};
end

-- restore context
function CodeCoroutine:RestoreContext(context)
	local code_env = self:GetCodeBlock():GetCodeEnv();
	code_env.co = context.co;
	code_env.actor = context.actor;
end

-- Run the same coroutine multiple times will cause the previous one to stop forever.
function CodeCoroutine:Run(msg, onFinishedCallback)
	self:Stop();
	self.isStopped = false;
	if(self.code_func) then
		self.co = coroutine.create(function()
			self:RunImp(msg);
			self.isStopped = true;
			if(onFinishedCallback) then
				onFinishedCallback();
			end
			return nil, "finished";
		end)
		local last_context = self:SaveCurrentContext();
		self:PrepareCodeContext();
		self:Resume();
		self:RestoreContext(last_context);
	end
end

function CodeCoroutine:RunImp(msg)
	local code_func = self.code_func;
	if(code_func) then
		setfenv(code_func, self:GetCodeBlock():GetCodeEnv());
		local ok, result = pcall(code_func, msg);

		if(not ok) then
			if(result:match("_stop_all_")) then
				self:GetCodeBlock():StopAll();
			elseif(result:match("_restart_all_")) then
				self:GetCodeBlock():RestartAll();
			else
				LOG.std(nil, "error", "CodeCoroutine", result);
				local msg = format(L"运行时错误: %s\n在%s", tostring(result), self:GetCodeBlock():GetFilename());
				self:GetCodeBlock():send_message(msg);
			end
		end
		return result;
	end
end

function CodeCoroutine:Resume(err, msg)
	if(self.co and not self.isStopped) then
		return coroutine.resume(self.co, err, msg);
	end
end

-- CAUTION: only call this inside coroutine
function CodeCoroutine:Yield()
	if(self.co) then
		return coroutine.yield();
	end
end

function CodeCoroutine:PrepareCodeContext()
	local code_env = self:GetCodeBlock():GetCodeEnv();
	code_env.co = self;
	code_env.actor = self:GetActor();
end
