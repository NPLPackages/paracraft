--[[
Title: Touch Button
Author(s): LiXizhi
Date: 2014/9/23
Desc: handling OnTick, OnTouchClick, OnTouchDown, OnTouchUp
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchButton.lua");
local TouchButton = commonlib.gettable("MyCompany.Aries.Game.Common.TouchButton");
local btn = TouchButton:new({OnTick=function(self) end, OnTouchClick, OnTouchDown, OnTouchUp, OnTouchMove });
-- in the UI callback, just call following the touch event as input. 
btn:OnTouchEvent(touch);
-------------------------------------------------------
]]
-- touch button class
local TouchButton = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.TouchButton"));

-- NOT IMPLEMENTED YET:
-- press will timeout after 5 seconds by default. 
TouchButton.touch_hold_timeout = 5000;
-- default to 10 pixels
local default_finger_size = 10;
-- default to 300 ms. 
local default_min_hold_time = 300;

function TouchButton:ctor()
end

function TouchButton:GetCurrentTouch()
	return self.touch;
end

function TouchButton:GetStartTouch()
	return self.touch_start;
end

-- click time is smaller than 0.3 seconds, and the dragging distance is smaller than 10 pixels.
function TouchButton:IsTouchClick(start_touch, end_touch)
	if(start_touch and end_touch and (end_touch.time - start_touch.time) < default_min_hold_time and 
		(not self.max_delta or self.max_delta < default_finger_size)) then
		return true;
	end
end

-- @param min_hold_time: default to 300 ms. 
-- @param finger_size: default to 10 pixels
function TouchButton:IsPressHold(min_hold_time, finger_size)
	if(self.touch_start and self.touch) then
		if((self.touch.time - self.touch_start.time) > (min_hold_time or default_min_hold_time) and 
			(self:GetMaxDragDistance() < (finger_size or default_finger_size))) then
			return true;
		end
	end
end

function TouchButton:GetMaxDragDistance()
	return self.max_delta;
end

function TouchButton:GetOffsetFromStartLocation()
	if(self.touch_start and self.touch) then
		return self.touch.x - self.touch_start.x, self.touch.y - self.touch_start.y;
	else
		return 0, 0;
	end
end

function TouchButton:OnTouchEvent(touch)
	self.touch = touch;
	if(touch.type == "WM_POINTERDOWN") then
		self.touch_start = commonlib.copy(touch);
		self.max_delta = 0;
		if(self.timer) then
			self.timer:Change();
		end
		if(self.OnTick) then
			self.timer = self.timer or commonlib.Timer:new({callbackFunc = function(timer)
				self.OnTick(self);
			end})
			self.timer:Change(0,30);
		end
		if(self.OnTouchDown) then
			self.OnTouchDown(self);
		end
	elseif(touch.type == "WM_POINTERUPDATE") then	
		local touch_start = self.touch_start;
		if(touch_start) then
			local delta_x = (touch.x - touch_start.x);
			local delta_y = (touch.y - touch_start.y);
			if(delta_x~=0) then
				self.max_delta = math.max(self.max_delta or 0, math.abs(delta_x));
			end
			if(delta_y~=0) then
				self.max_delta = math.max(self.max_delta or 0, math.abs(delta_y));
			end
		end
		if(self.OnTouchMove) then
			self:OnTouchMove();
		end
	elseif(touch.type == "WM_POINTERUP") then
		if(self.OnTouchUp) then
			self.OnTouchUp(self);
		end
		if(self.OnTouchClick and self:IsTouchClick(self.touch_start,touch)) then
			self.OnTouchClick(self);
		end
		self.touch_start = nil;
		if(self.timer) then
			self.timer:Change();
		end
	end
end
