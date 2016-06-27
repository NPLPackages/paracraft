--[[
Title: Timed event
Author(s): LiXizhi
Date: 2014/2/23
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/TimedEvent.lua");
local TimedEvent = commonlib.gettable("MyCompany.Aries.Game.TimedEvent")
local entry = TimedEvent:new():Init(1, nil, function(entity, event)
	-- 
end);
-------------------------------------------------------
]]
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local block = commonlib.gettable("MyCompany.Aries.Game.block")

local TimedEvent = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.TimedEvent"));


function TimedEvent:ctor()
end

-- @param scheduledTime: in seconds
-- @param callbackFunc: function(entity, timedEvent)
function TimedEvent:Init(scheduledTime, name, callbackFunc)
	self.scheduledTime = scheduledTime;
	self.callbackFunc = callbackFunc;
	self.name = name;
	return self;
end

-- get the time of the event
function TimedEvent:GetTime()
	return self.scheduledTime;
end

-- fire the current event
function TimedEvent:FireEvent(entity)
	self.callbackFunc(entity, self);
end

