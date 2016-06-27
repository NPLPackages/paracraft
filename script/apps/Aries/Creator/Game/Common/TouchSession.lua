--[[
Title: Touch Session
Author(s): LiXizhi
Date: 2014/9/23
Desc: Similar to TouchButton but with more advanced way to track and interprete touch movement. 
It is mostly used in 3d scene touch event handling. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchSession.lua");
local TouchSession = commonlib.gettable("MyCompany.Aries.Game.Common.TouchSession")
local session = TouchSession:new();
session:OnTouchEvent(touch);
-------------------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");

-- touch Session class
local TouchSession = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.TouchSession"));

-- when hovering, we allow user to accitentally move this amount of pixels at most. 
local touch_hover_dist_allowed = 10;
-- default to 10 pixels
local default_finger_size = 10;
-- default to 300 ms. 
local default_min_hold_time = 300;

TouchSession.attr = {};

function TouchSession:ctor()
end

local touch_sessions = commonlib.UnorderedArraySet:new();

-- public static function: 
function TouchSession.GetTouchSession(touch)
	if(touch) then
		local session;
		for i = 1, #touch_sessions do
			if(touch_sessions[i].id == touch.id) then
				session = touch_sessions[i];
				break;
			end
		end
		if(not session) then
			session = TouchSession:new({id = touch.id});
			touch_sessions:add(session);
		end
		session:OnTouchEvent(touch);
		return session;
	end
end

function TouchSession.GetAllSessions()
	return touch_sessions;
end

function TouchSession:GetCurrentTouch()
	return self.touch;
end

function TouchSession:GetTouchID()
	return self.id or 0;
end

function TouchSession:GetStartTouch()
	return self.touch_start or self.touch;
end

function TouchSession:GetFingerSize()
	return default_finger_size;
end

-- click time is smaller than 0.3 seconds, and the dragging distance is smaller than 10 pixels.
function TouchSession:IsTouchClick(start_touch, end_touch, min_hold_time, finger_size)
	if(start_touch and end_touch and (end_touch.time - start_touch.time) < (min_hold_time or default_min_hold_time) and 
		(self:GetMaxDragDistance() < (finger_size or default_finger_size))) then
		return true;
	end
end

function TouchSession:IsClick(min_hold_time, finger_size)
	return self:IsTouchClick(self.touch_start, self.touch, min_hold_time);
end

-- custom handler should always check this before processing 
function TouchSession:IsEnabled()
	return self.enabled ~= false;
end

-- a touch session is always enabled when first created or touch down event is received. 
-- since a touch session is shared by multiple gesture recognizers, 
-- some gesture logics may disable touch sessions to prevent other logics to further process this touch session.
function TouchSession:SetEnabled(bEnabled)
	self.enabled = bEnabled;
end

-- @param min_hold_time: default to 300 ms. 
-- @param finger_size: default to 10 pixels
function TouchSession:IsPressHold(min_hold_time, finger_size)
	if(self.touch_start and self.touch) then
		if((self.touch.time - self.touch_start.time) > (min_hold_time or default_min_hold_time) and 
			(self:GetMaxDragDistance() < (finger_size or default_finger_size))) then
			return true;
		end
	end
end

-- max drag distance
function TouchSession:GetMaxDragDistance()
	return self.max_delta or 0;
end

function TouchSession:GetBlocks()
	return self.blocks;
end

function TouchSession:GetBlockCount()
	if(self.blocks) then
		return #(self.blocks);
	else
		return 0;
	end
end

-- in ms seconds
function TouchSession:GetHoverTime()
	if(self.touch_begin_hover) then
		return commonlib.TimerManager.GetCurrentTime() - self.touch_begin_hover.time;
	else
		return 0;
	end
end

function TouchSession:GetOffsetFromStartLocation()
	if(self.touch_start and self.touch) then
		return self.touch.x - self.touch_start.x, self.touch.y - self.touch_start.y;
	else
		return 0, 0;
	end
end

-- public: call this when new touch event arrives.
function TouchSession:OnTouchEvent(touch)
	self.touch = touch;
	if(touch.type == "WM_POINTERDOWN") then
		self:SetEnabled(true);
		self:handleTouchDown(touch);
	elseif(touch.type == "WM_POINTERUPDATE") then	
		self:handleTouchMove(touch);
	elseif(touch.type == "WM_POINTERUP") then
		self:handleTouchUp(touch);
	end
end

-- static function:
function TouchSession:GetTouchDistanceABS(touch1, touch2)
	if(touch1 and touch2) then
		return math.max(math.abs(touch1.x - touch2.x), math.abs(touch1.y - touch2.y))
	else
		return 0;
	end
end

-- static function: 
function TouchSession:GetTouchDistanceBetween(touch1, touch2)
	if(touch1 and touch2) then
		local distSq = ((touch1.x - touch2.x)^2+(touch1.y - touch2.y)^2);
		if(distSq>0.001) then
			return math.sqrt(distSq);
		else
			return 0;
		end
	else
		return 0;
	end
end

-- whether a given block is in the selection array. 
function TouchSession:HasBlock(x,y,z)
	if(self.blocks_map) then
		local index = BlockEngine:GetSparseIndex(x, y, z);
		return self.blocks_map[index];
	end
end

function TouchSession:AddBlock(x,y,z,side)
	local index = BlockEngine:GetSparseIndex(x, y, z)
	if(not self.blocks_map) then
		self.blocks_map = {};
		self.blocks = {};
	end
	if(not self.blocks_map[index]) then
		self.blocks_map[index] = true;
		self.blocks[#self.blocks+1] =  {x,y,z,side=side};
	end
end

function TouchSession:ClearAllBlocks()
	self.blocks_map = nil;
	self.blocks = nil;
end

-- values are cleared on touch down
function TouchSession:GetField(name, default_value)
	return self.attr[name] or default_value;
end

-- values are cleared on touch down
function TouchSession:SetField(name,value)
	self.attr[name] = value;
end

-- get the time of the most recent event. 
function TouchSession:GetLastTime()
	if(self.touch) then
		return self.touch.time or 0;
	else
		return 0;
	end
end

function TouchSession:GetStartTime()
	if(self.touch_start) then
		return self.touch_start.time or 0;
	else
		return 0;
	end
end

function TouchSession:Reset()
	self.touch_start = nil;
	self.touch_begin_hover = nil;
	self.max_delta = 0;
	self.blocks = nil;
	self.blocks_map = nil;
	self.bSelected = nil;
	self.is_blocks_selected = false;
	self.attr = {};
	
	if(self.timer) then
		self.timer:Change();
	end
end

function TouchSession:handleTouchDown(touch)
	self:Reset();
	self.touch_start = commonlib.copy(touch);
	self.touch_begin_hover = self.touch_start;

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
end

function TouchSession:UpdateMaxDragDist(touch)
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
end

function TouchSession:UpdateHoverTouch(touch)
	self.touch_begin_hover = self.touch_begin_hover or touch;
	if(self:GetTouchDistanceABS(self.touch_begin_hover, touch) > touch_hover_dist_allowed) then
		self.touch_begin_hover = touch;
	end
end

function TouchSession:handleTouchMove(touch)
	self:UpdateMaxDragDist(touch);
	self:UpdateHoverTouch(touch);

	if(self.OnTouchMove) then
		self:OnTouchMove();
	end
end

function TouchSession:handleTouchUp(touch)
	if(self.OnTouchUp) then
		self.OnTouchUp(self);
	end
	if(self.OnTouchClick and self.IsTouchClick(self.touch_start,touch)) then
		self.OnTouchClick(self);
	end
	if(self.timer) then
		self.timer:Change();
	end
	-- remove from session array
	for i = 1, #touch_sessions do
		if(touch_sessions[i].id == touch.id) then
			touch_sessions:remove(i);
			break;
		end
	end
end

