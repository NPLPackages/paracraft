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
CodeCoroutine:Signal("finished");
-- for debugging purposes
CodeCoroutine:Property({"description", nil, "GetDescription", "SetDescription", auto=true});

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

function CodeCoroutine:GetFreeTimer()
	-- only check one timer, in most cases, coroutine has just one wait timer. 
	local timer = self.timers and next(self.timers);
	if(timer and timer.isFreeTimer) then
		return timer;
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

-- @important: this function should be called inside coroutine, the caller must ensure that when callbackFunc called, 
-- it should NOT be inside any coroutine. Otherwise one should use MakeCallbackFuncAsync instead. 
function CodeCoroutine:MakeCallbackFunc(callbackFunc)
	return function(...)
		if(not self.isStopped) then
			self:SetCurrentCodeContext();
			if(callbackFunc) then
				callbackFunc(...);
			end
		end
	end
end

-- @important: this function should be called inside coroutine, the callbackFunc is gauranteed NOT to be inside any coroutine, because we use a timer for it. 
-- so it is always safe to call resume inside callbackFunc
function CodeCoroutine:MakeCallbackFuncAsync(callbackFunc)
	return function(p1, p2, p3, p4, p5)
		commonlib.TimerManager.SetTimeout(function()
			if(not self.isStopped) then
				self:SetCurrentCodeContext();
				if(callbackFunc) then
					callbackFunc(p1, p2, p3, p4, p5);
				end
			end	
		end, 0)
	end
end

function CodeCoroutine:SetTimer(callbackFunc, dueTime, period)
	local timer = self:GetCodeBlock():SetTimer(self:MakeCallbackFunc(callbackFunc), dueTime, period);
	self:AddTimer(timer);
	return timer;
end


function CodeCoroutine:SetTimeout(duration, callbackFunc)
	local timer = self:GetFreeTimer()
	if(timer) then
		timer.timeoutCallbackFunc = callbackFunc;
		timer.isFreeTimer = false;
		timer:Change(duration)
	else
		timer = self:GetCodeBlock():SetTimer(function(timer)
			if(timer.isFreeTimer) then
				timer.isFreeTimer = false;
				timer.timeoutCallbackFunc = nil;
				self:GetCodeBlock():KillTimer(timer)
				self:RemoveTimer(timer);
			else
				timer.isFreeTimer = true
				
				-- we will wait at least 1000 to see this timer will be reused again. 
				timer:Change(1000);

				local callback = timer.timeoutCallbackFunc;
				if(callback and not self.isStopped) then
					timer.timeoutCallbackFunc = nil;
					self:SetCurrentCodeContext()
					callback(timer);
				end
			end
		end, duration);
		timer.timeoutCallbackFunc = callbackFunc;
		timer.isFreeTimer = false;
		self:AddTimer(timer);
	end

	return timer;
end

function CodeCoroutine:SetActor(actor)
	if(self.actor~=actor) then
		if(self.actor) then
			self.actor:Disconnect("beforeRemoved", self, self.Stop);
		end
		self.actor = actor;
	end
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

function CodeCoroutine:IsRunning()
	return not self.isStopped;
end

-- the coroutine has finished the last line of its code, but it may not be stopped, since it may still contain valid timers such as playing animations. 
function CodeCoroutine:IsFinished()
	return self.isFinished;
end

function CodeCoroutine:SetFinished()
	if(not self.isFinished) then
		self.isFinished = true;
		self:finished();
		if(self.bAutoRelease and self.codeBlock) then
			self.codeBlock:AddCoroutineToFreePool(self);
		end
	end
end

-- whether we will add to auto release pool when this coroutine is finished. 
function CodeCoroutine:SetAutoReleasePool(bAutoRelease)
	self.bAutoRelease = bAutoRelease
end

-- when stopped, it can no longer be resumed
function CodeCoroutine:Stop()
	self.isStopped = true;
	self:SetFinished();
	-- we need to stop the last coroutine timers, before starting a new one. 
	self:KillAllTimers();
	if(self.codeBlock) then
		self.codeBlock:Disconnect("beforeStopped", self, self.Stop);
	end
	if(self.actor) then
		self.actor:Disconnect("beforeRemoved", self, self.Stop);
	end
end

function CodeCoroutine:SetCurrentCodeContext()
	GameLogic.GetCodeGlobal():SetCurrentCoroutine(self);
end

-- Run the same coroutine multiple times will cause the previous one to stop forever.
function CodeCoroutine:Run(msg, onFinishedCallback)
	self:Stop();

	if(self.code_func) then
		self.isStopped = false;
		self.isFinished = false;
		self.codeBlock:Connect("beforeStopped", self, self.Stop, "UniqueConnection");

		if(self.actor) then
			self.actor:Connect("beforeRemoved", self, self.Stop, "UniqueConnection");
		end
		setfenv(self.code_func, self:GetCodeBlock():GetCodeEnv());

		self.co = coroutine.create(function()
			local result, r2, r3, r4 = self:RunImp(msg);
			self:SetFinished();
			self.codeBlock:Disconnect("beforeStopped", self, self.Stop);
			if(self.actor) then
				self.actor:Disconnect("beforeRemoved", self, self.Stop);
			end
			if(onFinishedCallback) then
				onFinishedCallback(result, r2, r3, r4);
			end
			return result, r2, r3, r4;
		end)
			
		local ok, result, r2, r3, r4 = self:Resume();
		if(ok and self.isFinished) then
			return result, r2, r3, r4;
		end
	end
end

-- if the coroutine function is still running, this function will do nothing. Otherwise it will run. 
-- it will make the the same code coroutine object to be reusable. The same code_func can be invoked multiple times with the same C++ coroutine object. 
-- this will save some memory overhead, but yield/resume overhead still exists. 
-- see also: https://gist.github.com/LiXizhi/911069b7e7f98db76d295dc7d1c5e34a
-- 1. memory overhead: 0.26KB per coroutine
-- 2. yield/resume pair overhead: 0.0004 ms
--   if you have 1000 objects each is calling yield/resume at 60FPS, then the time overhead is 0.2*1000/500000*60*1000 = 24ms
--   and if you do not reuse coroutine, then memory overhead is 1000*60*0.26 = 15.6MB/sec
function CodeCoroutine:RunSingle(msg, onFinishedCallback)
	if(self.code_func and self.isFinished ~= false) then
		self.isStopped = false;
		self.isFinished = false;
		self.onFinishedCallback = onFinishedCallback;
		self.msg = msg;
		if(not self.co) then
			setfenv(self.code_func, self:GetCodeBlock():GetCodeEnv());
		
			self.codeBlock:Connect("beforeStopped", self, self.Stop, "UniqueConnection");
			if(self.actor) then
				self.actor:Connect("beforeRemoved", self, self.Stop, "UniqueConnection");
			end

			self.co = coroutine.create(function()
				while(true) do
					local result, r2, r3, r4 = self:RunImp(self.msg);
					self:SetFinished();
					if(self.onFinishedCallback) then
						self.onFinishedCallback(result, r2, r3, r4);
						self.onFinishedCallback = nil;
					end
					coroutine.yield(result, r2, r3, r4)
				end
			end)
		end

		local ok, result, r2, r3, r4 = self:Resume();
		if(ok and self.isFinished) then
			return result, r2, r3, r4;
		end
	end
end


local lastErrorCallstack = "";
function CodeCoroutine.handleError(x)
	lastErrorCallstack = commonlib.debugstack(2, 5, 1);
	return x;
end

function CodeCoroutine:RunImp(msg)
	local code_func = self.code_func;
	if(code_func) then
		local ok, result, r2, r3, r4 = xpcall(code_func, CodeCoroutine.handleError, msg);

		if(not ok) then
			if(result:match("_stop_all_")) then
				self:GetCodeBlock():StopAll();
			elseif(result:match("_terminate_")) then
				-- terminate only the coroutine
			elseif(result:match("_restart_all_")) then
				self:GetCodeBlock():RestartAll();
			else
				LOG.std(nil, "error", "CodeCoroutine", "%s\n%s", result, lastErrorCallstack);
				local msg = format(L"运行时错误: %s\n在%s", self:GetCodeBlock():BeautifyRuntimeErrorMsg(tostring(result)), self:GetCodeBlock():GetFilename());
				self:GetCodeBlock():send_message(msg, "error");
				if not string.match(result,"_block%(%d+, %d+, %d+%)") then --代码方块的直接报错不进行上报
					local ParacraftDebug = commonlib.gettable("MyCompany.Aries.Game.Common.ParacraftDebug");
					ParacraftDebug:SendErrorLog("NplRuntimeError", {
						errorMessage = msg,
						stackInfo = lastErrorCallstack,
					})
				end
			end
		end
		return result, r2, r3, r4;
	end
end

function CodeCoroutine:Resume(err, msg, p3, p4)
	if(self.co and not self.isStopped) then
		self:SetCurrentCodeContext();
		return coroutine.resume(self.co, err, msg, p3, p4);
	end
end

-- CAUTION: only call this inside coroutine
function CodeCoroutine:Yield()
	if(self.co) then
		return coroutine.yield();
	end
end
