--[[
Title: CodeAPI
Author(s): LiXizhi
Date: 2018/5/16
Desc: sandbox API environment 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI.lua");
local CodeAPI = commonlib.gettable("MyCompany.Aries.Game.Code.CodeAPI");
local api = CodeAPI:new(codeBlock, codeActor);
-------------------------------------------------------
]]
-- all public environment methods. 
local s_env_methods = {
	"resume", 
	"yield", 
	"checkyield",
	"exit",
	"print",
	"log",
	"echo",
	"gettable",
	"createtable",
	"inherit",
	"say",
	"wait",
}

NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/MemoryActor.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local CodeAPI = commonlib.gettable("MyCompany.Aries.Game.Code.CodeAPI");
local env_imp = commonlib.gettable("MyCompany.Aries.Game.Code.env_imp");
CodeAPI.__index = CodeAPI;

-- SECURITY: expose global _G to server env, this can be useful and dangourous.
setmetatable(CodeAPI, {__index = function(tab, name)
	if(name == "__LINE__") then
		local info = debug.getinfo(2, "l")
		if(info) then
			return info.currentline;
		end
	end
	return _G[name];
end});


-- @param actor: CodeActor that this code API is controlling. 
function CodeAPI:new(codeBlock, actor)
	local o = {
		actor = actor,
		codeblock = codeBlock,
	};
	CodeAPI.InstallMethods(o);
	setmetatable(o, self);
	return o;
end

-- install functions to code environment
function CodeAPI.InstallMethods(o)
	for _, func_name in ipairs(s_env_methods) do
		local f = function(...)
			local self = getfenv(1);
			return env_imp[func_name](self, ...);
		end
		setfenv(f, o);
		o[func_name] = f;
	end
end


-- yield control until all async jobs are completed
-- @param bExitOnError: if true, this function will handle error 
-- @return err, msg: err is true if there is error. 
function env_imp:yield(bExitOnError)
	local err, msg;
	if(self.co) then
		if(self.fake_resume_res) then
			err, msg = unpack(self.fake_resume_res);
			self.fake_resume_res = nil;
			return err, msg;
		else
			err, msg = coroutine.yield(self);
			if(err and bExitOnError) then
				env_imp.exit(self);
			end
		end
	end
	return err, msg;
end

-- resume from where jobs are paused last. 
-- @param err: if there is error, this is true, otherwise it is nil.
-- @param msg: error message in case err=true
function env_imp:resume(err, msg)
	if(self.co) then
		if(coroutine.status(self.co) == "running") then
			self.fake_resume_res = {err, msg};
			return;
		else
			self.fake_resume_res = nil;
		end
		local res, err, msg = coroutine.resume(self.co, err, msg);
	end
end

-- calling this function 100 times will automatically yield and resume until next tick (1/30 seconds)
-- we will automatically insert this function into while and for loop. One can also call this manually
function env_imp:checkyield()
end

-- Output a message and terminate the current script
-- @param msg: output this message. usually nil. 
function env_imp:exit(msg)
	-- the caller use xpcall with custom error function, so caller will catch it gracefully and end the request
	self.is_exit_call = true;
	self.exit_msg = msg;
	error("exit_call");
end

-- simple log any object, same as echo. 
function env_imp:log(...)
	commonlib.echo(...);
end

function env_imp:echo(...)
	commonlib.echo(...);
end

-- similar to commonlib.gettable(tabNames) but in page scope.
-- @param tabNames: table names like "models.users"
function env_imp:gettable(tabNames)
	return commonlib.gettable(tabNames, self);
end

-- similar to commonlib.createtable(tabNames) but in page scope.
-- @param tabNames: table names like "models.users"
function env_imp:createtable(tabNames, init_params)
	return commonlib.createtable(tabNames, self);
end

-- same as commonlib.inherit()
function env_imp:inherit(baseClass, new_class, ctor)
	return commonlib.inherit(baseClass, new_class, ctor);
end

-- wait some time
-- @param seconds: in seconds
function env_imp:wait(seconds)
	if(seconds and seconds>0) then
		self.codeblock:SetTimeout(math.floor(seconds*1000), function()
			env_imp.resume(self);
		end) 
		env_imp.yield(self);
	end
end

-- say some text and wait for some time. 
-- @param text: if nil, it will remove text
-- @param duration: in seconds. if nil, it means forever
function env_imp:say(text, duration)
	if(duration) then
		env_imp.say(self, text);
		env_imp.wait(self, duration);
		env_imp.say(self, nil);
	else
		GameLogic.AddBBS("codeblock", text, 10000);
	end
end

