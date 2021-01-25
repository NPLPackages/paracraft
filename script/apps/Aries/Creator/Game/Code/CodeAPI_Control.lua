--[[
Title: CodeAPI
Author(s): LiXizhi
Date: 2018/6/8
Desc: sandbox API environment
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI_Control.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCoroutine.lua");
local CodeCoroutine = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCoroutine");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local env_imp = commonlib.gettable("MyCompany.Aries.Game.Code.env_imp");

-- wait some time
-- @param seconds: in seconds, if nil, it is one tick or env_imp.GetDefaultTick(self)
function env_imp:wait(seconds)
	seconds = seconds or env_imp.GetDefaultTick(self);
	if(self.co) then
		self.co:SetTimeout(math.floor(seconds*1000), function()
			env_imp.resume(self);
		end) 
		env_imp.yield(self);
	end
end

-- Output a message and terminate all connected code block.
-- @param msg: output this message. usually nil. 
function env_imp:exit(msg)
	-- the caller use xpcall with custom error function, so caller will catch it gracefully and end the request
	self.is_exit_call = true;
	self.exit_msg = msg;
	error("_stop_all_");
end

-- stop the coroutine
function env_imp:terminate()
	error("_terminate_");
end

function env_imp:restart(msg)
	env_imp.wait(self, 1);
	error("_restart_all_");
end

-- return ok, result
function env_imp:xpcall(code_func, handleError, ...)
	return xpcall(code_func, handleError, ...);
end


-- make the current actor an agent of input entity. 
-- The entity could be current player or a network player on server.
-- @param entityName: "@p" means current player, or any valid player name or entity name. 
function env_imp:becomeAgent(entityName)
	if(self.actor) then
		local entity;
		if(entityName == "@p") then
			entity = EntityManager.GetPlayer();
		else
			entity = EntityManager.GetEntity(entityName);
		end
		self.actor:BecomeAgent(entity);
	else
		local actor = self.codeblock:CloneMyself()
		if(actor and self.co) then
			self.co:SetActor(actor);
			env_imp.becomeAgent(self, entityName);
		end
	end
end

-- set the code block output value, this is the wire signal that this code block will emit, 
-- the signal can be tracked by a block repeater. 
function env_imp:setOutput(result)
	if(self.codeblock) then
		self.codeblock:SetOutput(tonumber(result))
	end
end


-- run function in a new coroutine
function env_imp:run(mainFunc)
	if(type(mainFunc) == "function") then
		local last_co = self.co;
		local co = CodeCoroutine:new():Init(self.codeblock);
		co:SetActor(self.actor);
		co:SetFunction(mainFunc);
		co:Run();
		if(last_co) then
			last_co:SetCurrentCodeContext();
		end
	end
end

-- run function under the context of a given actor and wait for its return value
-- @param actor: actor name or the actor object
function env_imp:runForActor(actor, mainFunc)
	if(actor == "myself" or not actor) then
		actor = self.actor;
	elseif(type(actor) == "string") then
		actor = GameLogic.GetCodeGlobal():GetActorByName(actor);
	end
	if(type(actor) == "table" and type(mainFunc) == "function") then
		local isFinished = false;
		local last_co = self.co;
		-- share the same coroutine for a given actor to improve performance when there are tons of runForActor calls. 
		local co = self.codeblock:NewCoroutine();
		--local co = CodeCoroutine:new():Init(self.codeblock);
		co:SetActor(actor);
		co:SetFunction(mainFunc);
		local result, r2, r3, r4 = co:Run(nil, self.co:MakeCallbackFunc(function(...)
			isFinished = true;
			env_imp.resume(self, ...);
		end));	
		if(not isFinished) then
			return env_imp.yield(self);
		else
			return result, r2, r3, r4;
		end
	end
end

-- return after user has pressed enter key
-- @param callbackFunc: if there is a callback function, we will display OKCancel
-- @return nil or "OK"
function env_imp:alert(text, callbackFunc)
	local buttons
	if(callbackFunc) then
		buttons = _guihelper.MessageBoxButtons.OKCancel_CustomLabel;
	else
		buttons = _guihelper.MessageBoxButtons.OK_CustomLabel
	end

	local res;
	_guihelper.MessageBox(text, self.co:MakeCallbackFuncAsync(function(result)
		res = result;
		env_imp.resume(self)
	end), buttons)
	env_imp.yield(self);
	if(res == _guihelper.DialogResult.OK) then
		res = "OK"
	elseif(res == _guihelper.DialogResult.Cancel) then
		res = "Cancel"
	end

	if(callbackFunc and res == "OK") then
		callbackFunc(res);
	end
	return res;
end