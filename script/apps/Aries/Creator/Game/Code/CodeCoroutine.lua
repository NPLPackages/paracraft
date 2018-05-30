--[[
Title: Code Coroutine
Author(s): LiXizhi
Date: 2018/5/30
Desc: call back functions or the main function that must be executed in a separate coroutine. 
All coroutines share the same CodeAPI environment, except for current actor. 
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
	self:KillAllTimers();
	CodeCoroutine._super.Destroy(self);
end

function CodeCoroutine:AddTimer(timer)
	self.timers = self.timers or {}
	self.timers[timer] = true;
end

function CodeCoroutine:KillAllTimers()
	if(self.timers) then
		for timer, _ in pairs(self.timers) do
			self.codeBlock:KillTimer(timer);
		end
		self.timers = nil;
	end
end

function CodeCoroutine:SetFunction(code_func)
	self.code_func = code_func;
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

-- Run the same coroutine multiple times will cause the previous one to stop forever.
function CodeCoroutine:Run()
	if(self:GetStatus() == "dead") then
		-- TODO: we need to stop the last coroutine, before starting a new one. 
		return;
	end
	if(self.code_func) then
		self.co = coroutine.create(function()
			self:RunImp();
			return nil, "finished";
		end)
		self:Resume();
	end
end

function CodeCoroutine:RunImp()
	if(self.code_func) then
		setfenv(self.code_func, self:GetCodeBlock():GetCodeEnv());
		local ok, result = pcall(self.code_func);

		if(not ok) then
			LOG.std(nil, "error", "CodeCoroutine", result);
			if(not code_env.is_exit_call) then
				local msg = format(L"运行时错误: %s\n在%s", tostring(result), self:GetCodeBlock():GetFilename());
				self:GetCodeBlock():send_message(msg);
			else
				if(code_env.exit_msg) then
					self:GetCodeBlock():send_message(tostring(code_env.exit_msg));
				end
				code_env.is_exit_call = nil;
			end
		end		
		return result;
	end
end

function CodeCoroutine:Resume(err, msg)
	if(self.co) then
		self:PrepareCodeContext();
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
