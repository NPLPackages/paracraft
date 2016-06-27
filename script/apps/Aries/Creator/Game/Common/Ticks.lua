--[[
Title: Ticks
Author(s): LiXizhi
Date: 2014/7/3
Desc: Check to see if it is a tick.  usually used by class with a real time framemove function. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Ticks.lua");
local Ticks = commonlib.gettable("MyCompany.Aries.Game.Common.Ticks");
function SomeClass:IsTick(deltaTime)
	if(not self.ticks) then
		self.ticks = Ticks:new():Init(20);
	end
	return self.ticks:IsTick(deltaTime)
end

function SomeClass:FrameMove(deltaTime) 
	if(not self:IsTick(deltaTime)) then
		return;
	end
	-- main loop
end
-------------------------------------------------------
]]
local Ticks = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.Ticks"));

Ticks.motion_fps = 20;
Ticks.inverse_motion_fps = 1/Ticks.motion_fps;

function Ticks:ctor()
end

-- default to 20 FPS
function Ticks:Init(nFPS)
	if(nFPS) then
		self.invervalSeconds = 1/nFPS;
	end
	return self;
end

-- check to see if we should tick. For example, some function may be called with deltaTime in 30fps, 
-- however, we only want to process at 20FPS, such as physics, we can use this function is easily limit function calling rate. 
-- @param deltaTime: delta time in seconds, since last call
-- @param func_name: default to "FrameMove". this can be any string. 
-- @param intervalSeconds: default to 1/20
function Ticks:IsTick(deltaTime, func_name, intervalSeconds)
	func_name = func_name or "FrameMove";
	local elapsed_time = self[func_name] or 0;
	intervalSeconds = intervalSeconds or self.inverse_motion_fps;
	elapsed_time = elapsed_time + deltaTime;
	local bIsTick;
	if(elapsed_time >= intervalSeconds) then
		bIsTick = true;
		elapsed_time = elapsed_time - intervalSeconds;
		if(elapsed_time > intervalSeconds) then
			elapsed_time = intervalSeconds;
		end
	end
	self[func_name] = elapsed_time;
	return bIsTick;
end

-- @param func_name: can be nil
function Ticks:GetElapsedTime(func_name)
	return self[func_name or "FrameMove"];
end