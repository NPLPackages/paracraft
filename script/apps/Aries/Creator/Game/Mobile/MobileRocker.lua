--[[
Title: Rocker Function
Author(s): PBB
Date: 2023/10/27
Desc: Rocker UI

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileRocker.lua");
local MobileRocker = commonlib.gettable("MyCompany.Aries.Game.GUI.MobileRocker");
MobileRocker:Init("touch_mobile", 90, 300, 240, 240)
MobileRocker.CheckShow(true);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchSession.lua");
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
NPL.load("(gl)script/ide/System/Windows/Mouse.lua");
NPL.load("(gl)script/ide/Transitions/Tween.lua");
local Mouse = commonlib.gettable("System.Windows.Mouse");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local TouchSession = commonlib.gettable("MyCompany.Aries.Game.Common.TouchSession");
local Screen = commonlib.gettable("System.Windows.Screen");

local MobileRocker = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.GUI.MobileRocker"));
MobileRocker:Property("Name", "MobileRocker");
MobileRocker.name = "default_MobileRocker";


MobileRocker.DirectionKey = {
	Up = {"W"},
	Down ={"S"},
	Left = {"A"},
	Right = {"D"},
	UpLeft = {"W","A"},
	UpRight = {"W","D"},
	DownLeft = {"S","A"},
	DownRight = {"S","D"},
}

local key_maps = {
    W = DIK_SCANCODE.DIK_W,
    A = DIK_SCANCODE.DIK_A,
    S = DIK_SCANCODE.DIK_S,
    D = DIK_SCANCODE.DIK_D,
}

function MobileRocker:ctor()
	self.alignment = "_lt";
	self.zorder = -10;
end


local s_instance;
function MobileRocker.GetSingleton()
	if(not s_instance) then
		s_instance = MobileRocker:new():Init("MobileRocker");
	end
	return s_instance;
end

-- static method
function MobileRocker.CheckShow(bShow)
	local self = MobileRocker.GetSingleton()
	if bShow == MobileRocker.bShow then
		return
	end
	MobileRocker.bShow = bShow
	self:Show(bShow);
	if bShow then
		GameLogic.GetFilters():add_filter("basecontext_after_handle_mouse_event", function(event)
			self:handleMouseEvent(event)
			return event
		end);
	end
end


-- all input can be nil. 
-- @param name: parent name. it should be a unique name
-- @param left, top: left, top position where to show. 
-- @param width: if width is not specified, it will use all the screen space left from x. 
function MobileRocker:Init(name, left, top, width, height)
	self.name = name or self.name;
	self.is_touch_down = false
	self:HideTouchSprite(true)
	self:SetPosition(left, top, width, height);
	Screen:Connect("sizeChanged", self, self.OnScreenSizeChange, "UniqueConnection")
	return self;
end

function MobileRocker:OnScreenSizeChange()
	self:SetPosition();
	if(self:isVisible()) then
		self:Show(true)
	end
end

-- @bShow: if nil, it will toggle show and hide. 
function MobileRocker:Show(bShow)
	local _parent = self:GetUIControl();
	if(bShow  == nil) then
		bShow = not _parent.visible;
	end
	_parent.visible = bShow;
	self:RefreshRocker()
	self.bIsVisible = bShow;
end

function MobileRocker:isVisible()
	return self.bIsVisible
end

function MobileRocker:Destroy()
	MobileRocker._super.Destroy(self);
	ParaUI.Destroy(self.id or self.name);
	self.id = nil;
	self.name = nil
end

function MobileRocker:SetPosition(left, top, width, height)
	self.width = width	
	self.height = height
	self.left = left 
	self.top = top 
end

function MobileRocker:GetUIControl()
	local _parent = ParaUI.GetUIObject(self.id or self.name);
	
	if(not _parent:IsValid()) then
		_parent = ParaUI.CreateUIObject("container",self.name,self.alignment,self.left,self.top,self.width,self.height);
		_parent.background = "";
		_parent:AttachToRoot();
		_parent.zorder = 1001;
		_parent:SetScript("ontouch", function() self:OnTouch(msg) end);
		_parent:SetScript("onmousedown", function() self:OnMouseDown() end);
		_parent:SetScript("onmouseup", function() self:OnMouseUp() end);
		_parent:SetScript("onmousemove", function() self:OnMouseMove() end);

		self.id = _parent.id;
	end
	return _parent;
end

-- simulate the touch event with id=-1
function MobileRocker:OnMouseDown()
	local touch = {type="WM_POINTERDOWN", x=mouse_x, y=mouse_y, id=-1, time=0};
	self:OnTouch(touch);
end

-- simulate the touch event
function MobileRocker:OnMouseUp()
	local touch = {type="WM_POINTERUP", x=mouse_x, y=mouse_y, id=-1, time=0};
	self:OnTouch(touch);
end

-- simulate the touch event
function MobileRocker:OnMouseMove()
	local touch = {type="WM_POINTERUPDATE", x=mouse_x, y=mouse_y, id=-1, time=0};
	self:OnTouch(touch);
end

-- handleTouchEvent
function MobileRocker:OnTouch(touch)
	-- handle the touch
	local touch_session = TouchSession.GetTouchSession(touch);
	-- let us track it with an item. 
	self.is_ext = false
	if(touch.type == "WM_POINTERDOWN") then
		print("touch down============")
		self.is_touch_down = true
	elseif(touch.type == "WM_POINTERUPDATE") then
		if(touch_session:IsDragging()) then
			-- print("---------------=============")
			self:StartRockerMove(touch)
		end
		
	elseif(touch.type == "WM_POINTERUP") then
		print("touch up ============")
		self:StopMoveState()
		self:InitRockerPointPos()	
		self:HideTouchSprite()
		self.is_touch_down = false
	end
end

function MobileRocker:handleMouseEvent(event)
	if not event then
		return
	end
	local eventType = event:GetType() 
	if eventType == "mouseMoveEvent" then
		self:CreateTouchSprite()
		self:CheckTouchPos(event.x,event.y)
	end
end

function MobileRocker:SendRawKeyEvent(vKey, isDown)
	if(vKey) then
		Keyboard:SendKeyEvent(isDown and "keyDownEvent" or "keyUpEvent", vKey);
	end
end
-- is_ext 是否外部调用
function MobileRocker:ChangeMoveState(x, y, center_pos, is_ext)
	local state = self:GetDirectionState({x, y}, center_pos)
	if state == self.cur_move_state or state == nil then
		return
	end

	self:StopMoveState()
	
	self.cur_move_state = state
	self.is_ext = is_ext
	local key_name_list = MobileRocker.DirectionKey[self.cur_move_state]
	self:SetKeyListState(key_name_list, true)
end

function MobileRocker:StopMoveState()
	if self.cur_move_state then
		local last_key_name_list = MobileRocker.DirectionKey[self.cur_move_state]
		self:SetKeyListState(last_key_name_list, false)
		self.cur_move_state = nil
	end
end

function MobileRocker:SetKeyListState(key_name_list, state)
	for k, v in pairs(key_name_list) do
		local vKey = key_maps[v]
        if vKey then
            self:SendRawKeyEvent(vKey, state)
        end
	end
end

function MobileRocker:GetDirectionState(mouse_pos, center_pos)
	local param_x = mouse_pos[1] - center_pos[1]
	local param_y = mouse_pos[2] - center_pos[2]

	local rotation = math.atan2(-param_y,  param_x) * 180/math.pi  
	if rotation < 22.5 and rotation >= -22.5 then
		return "Right"
	elseif rotation < -22.5 and rotation >= -67.5 then
		return "DownRight"
	elseif rotation < -67.5 and rotation >= -112.5 then
		return "Down"
	elseif rotation < -112.5 and rotation >= -157.5 then
		return "DownLeft"
	elseif rotation < -157.5 or rotation >= 157.5 then
		return "Left"
	elseif rotation < 157.5 and rotation >= 112.5 then
		return "UpLeft"
	elseif rotation < 112.5 and rotation >= 67.5 then
		return "Up"
	elseif rotation < 67.5 and rotation >= 22.5 then
		return "UpRight"
	end
end

function MobileRocker:RefreshRocker(touch_x, touch_y)
	local bg_size = 240
	local point_size = 55
	if nil == self.rocker then
		-- print("create====================")
		
		self.rocker = ParaUI.CreateUIObject("container","rocker_root", "lt",0, 0, bg_size, bg_size);
		self.rocker.background = "";
		local parent = self:GetUIControl();
		parent:AddChild(self.rocker)
		self.rocker:SetField("ClickThrough", true);

		self.rocker_bg = ParaUI.CreateUIObject("container","rocker_bg", "lt",0, 0, bg_size, bg_size);
		self.rocker_bg.background = "Texture/Aries/Creator/keepwork/Mobile/icon/lunpan_224x224_32bits.png;0 0 224 224";
		self.rocker:AddChild(self.rocker_bg)
		self.rocker_bg:SetField("ClickThrough", true);

		
		self.rocker_point = ParaUI.CreateUIObject("container","rocker_point", "lt",bg_size/2 - point_size/2, bg_size/2 - point_size/2, point_size, point_size);
		self.rocker_point.background = "Texture/Aries/Creator/keepwork/Mobile/icon/caozuoqiu_56x56_32bits.png;0 0 56 56";
		self.rocker:AddChild(self.rocker_point)
		self.rocker_point:SetField("ClickThrough", true);
	end

	if not touch_x then
		self:InitRockerPointPos()
		return
	end
	local center_pos_x =  bg_size/2
	local center_pos_y = bg_size/2

	local rocker_point =  self.rocker_point
	local radius = bg_size/2

	local pos_x = touch_x - self.left
	local pos_y = touch_y - self.top
	-- 计算目标点离摇杆中心的距离
	local target_distance = (pos_x - center_pos_x ) ^ 2 + (pos_y - center_pos_y) ^ 2

	-- 计算夹角
	local param_y = pos_y - center_pos_y
	local param_x = pos_x - center_pos_x

	local rad = math.atan2(-param_y,  param_x)
	-- 计算圆上的点
	-- 得到圆盘中点到手指位置连成的直线与圆的交点
	local circle_pos_x = center_pos_x + math.cos(rad) * radius 
	local circle_pos_y = center_pos_y + math.sin(rad) * (-radius) 
	
	-- 计算摇杆在圆上的坐标
	local point_pos_x = circle_pos_x - rocker_point.width/2
	local point_pos_y = circle_pos_y - rocker_point.height/2
	if target_distance <= radius ^ 2 then
		point_pos_x = pos_x - rocker_point.width/2
		point_pos_y = pos_y - rocker_point.height/2
	end

	rocker_point.x = point_pos_x 
	rocker_point.y = point_pos_y

	self:ChangeMoveState(point_pos_x, point_pos_y, {center_pos_x,center_pos_y}, is_ext)
end

function MobileRocker:InitRockerPointPos()
	if self.rocker and self.rocker_point then
		local bg_size = self.rocker.width
		local point_width = self.rocker_point.width
		local point_height = self.rocker_point.height
		self.rocker_point.x = bg_size/2 - point_width/2
		self.rocker_point.y = bg_size/2 - point_height/2
	end
end

function MobileRocker:ShowRocker()	
	if self.rocker then
		self.rocker.visible = true
	end	
end

function MobileRocker:CreateTouchSprite()
	if not self.is_touch_down then
		return
	end
	if not self.touchSp or not self.touchSp:IsValid() then
		local x = mouse_x
		local y = mouse_y
		local __this = ParaUI.CreateUIObject("container","rocker_touch_sp", "_lt",x -30,y -30,60,60);
		__this.zorder = 100
		-- __this.background = ""
		__this:AttachToRoot();
		self.touchSp = __this

		self.touchSp:SetScript("onmousedown", function()  end);
		self.touchSp:SetScript("onmousemove", function() 
			local touch = {type="WM_POINTERUPDATE", x=mouse_x, y=mouse_y, id=-1, time=0};
			self:StartRockerMove(touch)			
		end);
		self.touchSp:SetScript("onmouseup", function()  
			self:StopMoveState()
			self:InitRockerPointPos()	
			self:HideTouchSprite(bDestroy)	
			self.is_touch_down = false	
		end);

		self:CheckTouchPos(x,y)
	else
		self.touchSp.visible = true
	end
end

function MobileRocker:CheckTouchPos(x,y)
	if self.touchSp and self.touchSp:IsValid() then
		self.touchSp.x = x - 30
		self.touchSp.y = y - 30
	end
end

function MobileRocker:HideTouchSprite(bDestroy)
	if self.touchSp and self.touchSp:IsValid() then
		self.touchSp.visible = false
	end
	if bDestroy then
		ParaUI.Destroy("rocker_touch_sp")
	end
end

function MobileRocker:HideRocker()
	if self.is_rocker_mode then
		self:InitRockerPointPos()
		return
	end
	if self.rocker then
		self.rocker.visible = false
	end
end

function MobileRocker:StartRockerMove(touch)
	local bg_size = 240
	local x = touch.x - self.left;
	local y = touch.y - self.top;
	local center_pos_x = bg_size / 2
	local center_pos_y = bg_size / 2
	local center_pos = {center_pos_x,center_pos_y}

	-- 判断距离
	local target_distance = (x - center_pos[1]) ^ 2 + (y - center_pos[2]) ^ 2
	if target_distance < 52 ^ 2 then
		self:StopMoveState()
		self:RefreshRocker(touch.x, touch.y)
		return
	end
	self:RefreshRocker(touch.x, touch.y)
end

function MobileRocker:OnCodeblockWindowShow(bShow)

end

function MobileRocker:OnScreenSizeChange()

end

function MobileRocker:OnDesktopModeChanged(mode)

end
