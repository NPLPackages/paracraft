--[[
Title: Code Event
Author(s): LiXizhi
Date: 2018/5/30
Desc: event callback for code API, it can fire for all actors or just one.
It will stop all previous event, before firing a new one
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeEvent.lua");
local CodeEvent = commonlib.gettable("MyCompany.Aries.Game.Code.CodeEvent");
local event = CodeEvent:new():Init(codeBlock, event_name);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCoroutine.lua");
local CodeCoroutine = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCoroutine");

local CodeEvent = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeEvent"));
CodeEvent:Property({"stopLastEvent", true, "IsStopLastEvent", "SetStopLastEvent", auto=true});
CodeEvent:Signal("beforeDestroyed");

function CodeEvent:ctor()
end

function CodeEvent:Init(codeBlock, event_name)
	self.codeBlock = codeBlock;
	self.name = event_name;
	self.callbackFunc = callbackFunc;
	return self;
end

function CodeEvent:Destroy()
	self:beforeDestroyed();
	CodeEvent._super.Destroy(self);
end

function CodeEvent:SetActor(actor)
	self.actor = actor;
end

function CodeEvent:SetFunction(callbackFunc)
	self.callbackFunc = callbackFunc;
end

function CodeEvent:SetIsFireForAllActors(bValue)
	self.isFireForAll = bValue;
end

function CodeEvent:GetCodeBlock()
	return self.codeBlock;
end

function CodeEvent:StopLastEvent(actor)
	if(actor) then
		actor:StopLastCodeEvent(self);
	else
		if(self.last_coroutine) then
			self.last_coroutine:Stop();
			self.last_coroutine = nil;
		end
	end
end

function CodeEvent:SetCodeEvent(actor, co)
	if(actor) then
		actor:SetCodeEvent(self, co);
	else
		if(self.last_coroutine) then
			self.last_coroutine:Stop();
		end
		self.last_coroutine = co;
	end
end

function CodeEvent:CanFire(actor, msg)
	if(self.canFireCallback) then
		return self.canFireCallback(actor, msg);
	else
		return true;
	end
end

-- @param callbackFunc: function(actor, msg) end
function CodeEvent:SetCanFireCallback(callbackFunc)
	self.canFireCallback = callbackFunc
end


function CodeEvent:IsRunningForActor(actor)
	if(actor) then
		return actor:IsRunningEvent(self);
	else
		if(self.last_coroutine) then
			return not self.last_coroutine:IsFinished();
		end
	end
end

function CodeEvent:FireForActor(actor, msg, onFinishedCallback, bIsImmediate)
	if(not self:CanFire(actor, msg)) then
		if(onFinishedCallback) then
			onFinishedCallback();
		end
		return
	end
	if(self:IsStopLastEvent()) then
		self:StopLastEvent(actor);
	elseif(self:IsRunningForActor(actor)) then
		if(onFinishedCallback) then
			onFinishedCallback();
		end
		return
	end
	local co = CodeCoroutine:new():Init(self:GetCodeBlock());
	co:SetActor(actor);
	co:SetFunction(self.callbackFunc);
	self:SetCodeEvent(actor, co);
	if(not bIsImmediate) then
		co:SetTimeout(self:GetCodeBlock():GetDefaultTick(), function()
			co:Run(msg, onFinishedCallback);
		end)
	else
		return co:Run(msg, onFinishedCallback);
	end
end

-- @return result if it is available
function CodeEvent:Fire(msg, onFinishedCallback, bIsImmediate)
	if(not self.isFireForAll) then
		return self:FireForActor(self.actor, msg, onFinishedCallback, bIsImmediate);
	else
		local actors = self:GetCodeBlock():GetActors();
		local nAgentCount = actors and (#actors) or 0;
		
		if(nAgentCount > 0) then
			local result;
			if(onFinishedCallback) then
				local finishedCount = 0;
				local oldFinishedCallback = onFinishedCallback;
				onFinishedCallback = function()
					finishedCount = finishedCount + 1;
					if(finishedCount == nAgentCount) then
						oldFinishedCallback(result);
					end
				end
			end				
			
			for i=nAgentCount, 1, -1  do
				local actor = actors[i];
				if(actor) then
					result = self:FireForActor(actor, msg, onFinishedCallback, bIsImmediate) or result;
				end
			end
			return result;
		else
			return self:FireForActor(self.actor, msg, onFinishedCallback, bIsImmediate);
		end
	end
end

