--[[
Title: CodeAPI
Author(s): LiXizhi
Date: 2018/5/16
Desc: sandbox API environment
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI_Events.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCoroutine.lua");
local CodeCoroutine = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCoroutine");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local env_imp = commonlib.gettable("MyCompany.Aries.Game.Code.env_imp");

-- create a clone of some code block's actor
-- @param name: if nil or "myself", it means clone myself
-- @param msg: any mesage that is forwarded to clone event
function env_imp:clone(name, msg)
	self.codeblock:CreateClone(name, msg)
	env_imp.checkyield(self);
end

-- delete current cloned actor
function env_imp:delete()
	if(self.actor) then
		local actor = self.actor;
		if(self.co) then
			self.co:SetActor(nil);
		end
		actor:DeleteThisActor();
	end
	env_imp.checkyield(self);
end

function env_imp:registerCloneEvent(callbackFunc)
	self.codeblock:RegisterCloneActorEvent(callbackFunc);
	env_imp.checkyield(self);
end

-- @param text: any text, there is some predefined values, like "onCodeBlockStopped"
function env_imp:registerBroadcastEvent(text, callbackFunc)
	self.codeblock:RegisterTextEvent(text, callbackFunc);
	env_imp.checkyield(self);
end

-- @param text: any text, like "paracraft.macroplaform.GetIcon"
function env_imp:registerAgentEvent(text, callbackFunc)
	self.codeblock:RegisterAgentEvent(text, callbackFunc);
end

-- broadcast a global message.
-- @param msg: if nil, default to current actor's name
function env_imp:broadcast(text, msg)
	if(msg==nil and self.actor) then
		msg = self.actor:GetName();
	end
	self.codeblock:BroadcastTextEvent(text, msg);
	env_imp.checkyield(self);
end

-- broadcast a global message and wait for all its handlers are finished
-- @param msg: if nil, default to current actor's name
function env_imp:broadcastAndWait(text, msg)
	local isFinished = false;
	if(msg==nil and self.actor) then
		msg = self.actor:GetName();
	end
	self.codeblock:BroadcastTextEvent(text, msg, self.co:MakeCallbackFuncAsync(function()
		isFinished = true;
		env_imp.resume(self);
	end));
	if(not isFinished) then
		env_imp.yield(self);
	end
end

-- @param username: actor name or "@all". "@all" means broadcast
-- @param msg: msg.from is filled with sender's name if not provided.
function env_imp:broadcastTo(username, event_name, msg)
	msg = msg or {}
	if(type(msg) == "table" and self.actor) then
		msg.from = msg.from or self.actor:GetName();
	end
	if(username == "@all") then
		env_imp.broadcast(self, event_name, msg)
	else
		self.codeblock:BroadcastTextEventTo(username, event_name, msg);
		env_imp.checkyield(self);
	end
end

function env_imp:registerStartEvent(callbackFunc)
	self.codeblock:RegisterTextEvent("start", callbackFunc);
end

function env_imp:registerStopEvent(callbackFunc)
	self.codeblock:RegisterStopEvent(callbackFunc);
end

function env_imp:registerTickEvent(ticks, callbackFunc)
	self.codeblock:RegisterTickEvent(ticks, callbackFunc);
end

function env_imp:registerClickEvent(callbackFunc)
	self.codeblock:RegisterClickEvent(callbackFunc);
end

function env_imp:registerBlockClickEvent(blockid, callbackFunc)
	self.codeblock:RegisterBlockClickEvent(blockid, callbackFunc);
end

function env_imp:registerKeyPressedEvent(keyname, callbackFunc)
	self.codeblock:RegisterKeyPressedEvent(keyname, callbackFunc);
end

function env_imp:registerAnimationEvent(time, callbackFunc)
	self.codeblock:RegisterAnimationEvent(time, callbackFunc);
end

function env_imp:broadcastNetworkEvent(event_name, msg)
	self.codeblock:BroadcastNetworkEvent(event_name, msg);
end

function env_imp:registerNetworkEvent(event_name, callbackFunc)
	self.codeblock:RegisterNetworkEvent(event_name, callbackFunc);
end

function env_imp:sendNetworkEvent(username, event_name, msg)
	self.codeblock:SendNetworkEvent(username, event_name, msg);
end

-- @param cmd: full commands or just command name
-- @param params: parameters or nil. 
function env_imp:cmd(cmd, params)
	if(params ~= nil and params~="") then
		cmd = cmd.." "..tostring(params);
	end
	return self.codeblock:RunCommand(cmd)
end


