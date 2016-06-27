--[[
Title: Touch gesture recognizer
Author(s): LiXizhi
Date: 2014/11/12
Desc: touch gestures
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchGesturePinch.lua");
local TouchGesturePinch = commonlib.gettable("MyCompany.Aries.Game.Common.TouchGesturePinch")
local gesture_pinch = TouchGesturePinch:new({OnGestureRecognized = function(pinch_gesture)
	if(pinch_gesture:GetPinchMode() == "open") then
	else
	end
	return true;
end});
gesture_pinch:InterpreteTouchGesture(touch);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchSession.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local TouchSession = commonlib.gettable("MyCompany.Aries.Game.Common.TouchSession");
local TouchGesturePinch = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.TouchGesturePinch"));

-- how many pixels for both fingers to move before it is recognized as pinch. 
local nPinchThreshold = 20;

function TouchGesturePinch:ctor()
	self.isActive = nil;
end


function TouchGesturePinch:IsActive()
	return self.isActive;
end

-- return "open" or "closed" or nil.
function TouchGesturePinch:GetPinchMode()
	return self.pinch_mode;
end

function TouchGesturePinch:ResetLastDistance()
	self.lastDistance = self.distance;
end

function TouchGesturePinch:GetDeltaDistance()
	if(self.distance and self.lastDistance) then
		return self.distance - self.lastDistance;
	end
end


-- call this function whenever a touch event is received. 
-- @param touch: the current touch event received. 
-- @param touch_sessions: all active touch sessions, it nil, it will use the global one
-- @return true if gesture is active. 
function TouchGesturePinch:InterpreteTouchGesture(touch, touch_sessions)
	touch_sessions = touch_sessions or TouchSession.GetAllSessions();
	local finger_count = #(touch_sessions);
	if(finger_count == 2) then
		
		local touch1 = touch_sessions[1];
		local touch2 = touch_sessions[2];
		if( (touch1:GetMaxDragDistance()<nPinchThreshold and touch2:GetMaxDragDistance()) ) then
			self.isActive = false;
			self.lastDistance = nil;
			return;
		end
		self.distance = TouchSession:GetTouchDistanceBetween(touch1:GetCurrentTouch(), touch2:GetCurrentTouch());
		if(not self.lastDistance) then
			self.isActive = false;
			self.lastDistance = self.distance;
			return;
		end

		-- decide pinch mode
		local deltaDistance = self.distance - self.lastDistance;
		if(deltaDistance > 0) then
			self.pinch_mode = "open";
		else
			self.pinch_mode = "close";
		end
		
		self.isActive = self:handleGestureRecognized();
		return self.isActive;
	else
		self.isActive = false;
		self.lastDistance = nil;
	end
end

function TouchGesturePinch:handleGestureRecognized()
	if(self.OnGestureRecognized) then
		return self.OnGestureRecognized(self);
	else
		return true;
	end
end