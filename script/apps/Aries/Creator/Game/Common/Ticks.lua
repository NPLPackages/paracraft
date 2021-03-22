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

Ticks.intervalTime = 1/20;

function Ticks:ctor()
end

-- default to 20 FPS
function Ticks:Init(nFPS)
	self:SetFPS(nFPS)
	return self;
end

-- @param bIsMilliSecond: if true, we will use milliseconds, otherwise it is seconds. 
function Ticks:SetFPS(nFPS, bIsMilliSecond)
	if(nFPS) then
		if(bIsMilliSecond) then
			self.intervalTime = math.floor(1/nFPS * 1000);
		else
			self.intervalTime = 1/nFPS;
		end
	end
end


-- check to see if we should tick. For example, some function may be called with deltaTime in 30fps, 
-- however, we only want to process at 20FPS, such as physics, we can use this function is easily limit function calling rate. 
-- @param deltaTime: delta time in seconds, since last call
-- @param func_name: default to "FrameMove". this can be any string. 
-- @param intervalTime: default to 1/20
function Ticks:IsTick(deltaTime, func_name, intervalTime)
	func_name = func_name or "FrameMove";
	local elapsed_time = self[func_name] or 0;
	intervalTime = intervalTime or self.intervalTime;
	elapsed_time = elapsed_time + deltaTime;
	local bIsTick;
	if(elapsed_time >= intervalTime) then
		bIsTick = true;
		elapsed_time = elapsed_time - intervalTime;
		if(elapsed_time > intervalTime) then
			elapsed_time = intervalTime;
		end
	end
	self[func_name] = elapsed_time;
	return bIsTick;
end

-- similar to IsTick except that we will return the real time interval to be used as the second return value
-- @return boolean, interval: 
function Ticks:IsTickReal(deltaTime, func_name, intervalTime)
	func_name = func_name or "FrameMove";
	local elapsed_time = self[func_name] or 0;
	intervalTime = intervalTime or self.intervalTime;
	elapsed_time = elapsed_time + deltaTime;
	if(elapsed_time >= intervalTime) then
		if(elapsed_time >= intervalTime*2) then
			elapsed_time = intervalTime;
		end
		self[func_name] = 0
		return true, elapsed_time;
	elseif(elapsed_time >= (intervalTime - deltaTime*0.5) ) then
		self[func_name] = 0
		return true, elapsed_time;
	else
		self[func_name] = elapsed_time;
		return false;
	end
end


-- @param func_name: can be nil
function Ticks:GetElapsedTime(func_name)
	return self[func_name or "FrameMove"];
end

function Ticks:SetElapsedTime(time)
	self[func_name or "FrameMove"] = time or 0
end

function Ticks:GetCurrentInterval(func_name)
	return self[func_name or "FrameMove"] + self.intervalTime;
end