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
local CodeAPI = commonlib.gettable("MyCompany.Aries.Game.Code.CodeAPI");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local CodeBlock = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlock"));
CodeBlock:Property("Name", "CodeBlock");

function CodeBlock:ctor()
	self.timers = nil;
end

function CodeBlock:Init(entityCode)
	self.entityCode = entityCode;
	return self;
end

function CodeBlock:Destroy()
	self:Unload();
	CodeBlock._super.Destroy(self);
end

function CodeBlock:SetTimeout(duration, callbackFunc)
	self.timers = self.timers or {};
	local timer = commonlib.Timer:new({callbackFunc = function(timer)
		if(callbackFunc) then
			callbackFunc();
		end
		self.timers[timer] = nil;
	end})
	timer:Change(duration);
	self.timers[timer] = true;
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
	if(self.isLoaded) then
		return;
	end
	self.isLoaded = nil;
	if(self.timers) then
		for timer, _ in pairs(self.timers) do
			timer:Change();
		end
		self.timers = nil;
	end
	self.code_env = nil;
	-- TODO: remove entities, etc
end

-- TODO: create or get the default actor
function CodeBlock:GetActor()
	
end


-- run code again 
function CodeBlock:Run()
	self:Unload();

	if(self.code_func) then
		self.isLoaded = true;
		local code_env = CodeAPI:new(self, self:GetActor());
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