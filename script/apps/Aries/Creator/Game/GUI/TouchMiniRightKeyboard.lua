--[[
Title: Touch Virtual Mini-Keyboard
Author(s): LiXizhi
Date: 2018/3/21
Desc: minikeyboard for use on touch device like pad or phone
- ctrl+Z: touch drag ctrl key to space(Z) key
- ctrl+Y: touch drag ctrl key to A(Y) key
- ctrl+S: touch drag ctrl key to S key
- RMB: drag RMB button up and down for camera zoom in and out
- F: drag F button up and down to move camera up and down when in fly mode 
- Ctrl, Shift, Alt, RMB: one can use one finger to drag and hold on these buttons in sequence to simulate multiple key down at the same time. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchMiniRightKeyboard.lua");
local TouchMiniRightKeyboard = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchMiniRightKeyboard");
local kb = TouchMiniRightKeyboard:new():Init("TouchMiniRightKeyboard");
kb:SetTransparency(0.5)
kb:Show(true);

-- static singleton to show at default left bottom position
TouchMiniRightKeyboard.CheckShow(true);
TouchMiniRightKeyboard.GetSingleton():LoadKeyboardLayout({{{name="A", vKey = DIK_SCANCODE.DIK_A}, {name="C", vKey = DIK_SCANCODE.DIK_C}}, {{name="B", vKey = DIK_SCANCODE.DIK_B}}})
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchSession.lua");
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
NPL.load("(gl)script/ide/System/Windows/Mouse.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
local Mouse = commonlib.gettable("System.Windows.Mouse");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local TouchSession = commonlib.gettable("MyCompany.Aries.Game.Common.TouchSession");
local Screen = commonlib.gettable("System.Windows.Screen");
local TouchMiniKeyboard = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchMiniKeyboard");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local TouchMiniRightKeyboard = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.GUI.TouchMiniRightKeyboard"));
TouchMiniRightKeyboard:Property("Name", "TouchMiniRightKeyboard");
TouchMiniRightKeyboard.name = "default_TouchMiniRightKeyboard";

-- default to 0.5 second. 
TouchMiniRightKeyboard.hover_press_hold_time = 500;

-- @param name: displayname
-- @param vKey: virtual key scan code. 
TouchMiniRightKeyboard.DefaultKeyLayout = {
	{name="Space", main = true, colorid=1, vKey = DIK_SCANCODE.DIK_SPACE, default_pos_x = 0, default_pos_y = 83, img="Texture/Aries/Creator/keepwork/MiniKey/6_112X112_32bits.png;0 0 112 112", width=112, height=112,default_width=112, default_height=112},

	{name="Esc", colorid=1, vKey = DIK_SCANCODE.DIK_ESCAPE, default_pos_x = 0, default_pos_y = 0, default_off_pos_x = -17, default_off_pos_y = 98, is_child = true, img="Texture/Aries/Creator/keepwork/MiniKey/7_86X86_32bits.png;0 0 86 86", width=86, height=86,default_width=86, default_height=86},
	-- {name="Enter", colorid=1, vKey = DIK_SCANCODE.DIK_RETURN, default_pos_x = 0, default_pos_y = 0, default_off_pos_x = -86, default_off_pos_y = 38, is_child = true, img="Texture/Aries/Creator/keepwork/MiniKey/8_86X86_32bits.png;0 0 86 86", width=86, height=86,default_width=86, default_height=86},
	{name="KeyBoard", colorid=1, default_pos_x = 0, default_pos_y = 0, default_off_pos_x = -76, default_off_pos_y = -55, is_child = true, img="Texture/Aries/Creator/keepwork/MiniKey/9_86X86_32bits.png;0 0 86 86", width=86, height=86,default_width=86, default_height=86},
	{name="F", colorid=1, vKey = DIK_SCANCODE.DIK_F, flyUpDown = true, default_pos_x = 0, default_pos_y = 0, default_off_pos_x = 10, default_off_pos_y = -83, is_child = true, img="Texture/Aries/Creator/keepwork/MiniKey/10_86X86_32bits.png;0 0 86 86", width=86, height=86,default_width=86, default_height=86},
};

TouchMiniRightKeyboard.ColorMaskList = {
	normal = "Texture/Aries/Creator/keepwork/MiniKey/17_86X86_32bits.png;0 0 86 86",
	pressed = "Texture/Aries/Creator/keepwork/MiniKey/15_86X86_32bits.png;0 0 86 86",
	gray = "Texture/Aries/Creator/keepwork/MiniKey/3_94X88_32bits.png;0 0 94 88",
}

TouchMiniRightKeyboard.MainItemColorMaskList = {
	normal = "Texture/Aries/Creator/keepwork/MiniKey/16_112X112_32bits.png;0 0 112 112",
	pressed = "Texture/Aries/Creator/keepwork/MiniKey/12_112X112_32bits.png;0 0 112 112",
	gray = "Texture/Aries/Creator/keepwork/MiniKey/3_94X88_32bits.png;0 0 94 88",
}

function TouchMiniRightKeyboard:ctor()
	self.alignment = "_lt";
	self.zorder = -10;

	-- normalBtn, comboBtn, frequentBtn, mouseRight
	self.colors = { 
		{normal="#ffffff", pressed="#ffd21d"}, 
		{normal="#cccccc", pressed="#333333"}, 
		{normal="#8888ff", pressed="#3333cc"},
		{normal="#888888", pressed="#ff6600"},
	};

	self.finger_size = 10;
	self.transparency = 1;

	self.keylayout = TouchMiniRightKeyboard.DefaultKeyLayout;
	GameLogic:Connect("WorldLoaded", TouchMiniRightKeyboard, function()
		self:ChangeFlyBtImg()
	end, "UniqueConnection");
	-- Keyboard:SendKeyEvent("keyDownEvent", DIK_SCANCODE.DIK_RETURN)
	-- Keyboard:SendKeyEvent("keyUpEvent", DIK_SCANCODE.DIK_RETURN)
end

function TouchMiniRightKeyboard:LoadKeyboardLayout(keyLayout)
	local oldLayout = self.keylayout;
	self.keylayout = keyLayout or TouchMiniRightKeyboard.DefaultKeyLayout;
	if(self.keylayout ~= oldLayout) then
		local _parent = ParaUI.GetUIObject(self.id or self.name);
		if(_parent:IsValid()) then
			local visible = _parent.visible;
			self:CreateWindow();
			if(visible) then
				_parent.visible = true;
				_parent:ApplyAnim();
			end
		end
	end
end

local s_instance;
function TouchMiniRightKeyboard.GetSingleton()
	if(not s_instance) then
		s_instance = TouchMiniRightKeyboard:new():Init("TouchMiniRightKeyboard");
		-- s_instance:SetTransparency(0.5)
	end
	return s_instance;
end

-- static method
function TouchMiniRightKeyboard.CheckShow(bShow)
	TouchMiniRightKeyboard.GetSingleton():Show(bShow);
end


-- all input can be nil. 
-- @param name: parent name. it should be a unique name
-- @param left, top: left, top position where to show. 
-- @param width: if width is not specified, it will use all the screen space left from x. 
function TouchMiniRightKeyboard:Init(name, left, top, width)
	self.name = name or self.name;
	self:SetPosition(left, top, width);

	Screen:Connect("sizeChanged", self, self.OnScreenSizeChange, "UniqueConnection")
	return self;
end

function TouchMiniRightKeyboard:OnScreenSizeChange()
	self:SetPosition();
	if(self:isVisible()) then
		self:Show(true)
		self:SetTransparencyImp(0.2)
	end
end

-- @bShow: if nil, it will toggle show and hide. 
function TouchMiniRightKeyboard:Show(bShow)
	local _parent = self:GetUIControl();
	if(bShow  == nil) then
		bShow = not _parent.visible;
	end
	_parent.visible = bShow;
	self.bIsVisible = bShow;
end


function TouchMiniRightKeyboard:isVisible()
	return self.bIsVisible
end

function TouchMiniRightKeyboard:Destroy()
	TouchMiniRightKeyboard._super.Destroy(self);
	ParaUI.Destroy(self.id or self.name);
	self.id = nil;
end

-- @param alpha: 0-1 
function TouchMiniRightKeyboard:SetTransparency(alpha)
	if(self.transparency ~= alpha) then
		self.transparency = alpha;
		local _parent = self:GetUIControl();
		_guihelper.SetColorMask(_parent, format("255 255 255 %d",math.floor(alpha * 255)))
		_parent:ApplyAnim();
	end
	return self;
end

-- @param left: position where to show. default to one button width
-- @param top: default to 2/5 height of the screen
-- @param width: if width is not specified, use 1/3 height of the screen
function TouchMiniRightKeyboard:SetPosition(left, top, width)
	self.default_control_width = 225
	self.default_height = 720

	local ratio = math.min(1, Screen:GetHeight()/self.default_height);

	width =  width or self.default_control_width;
	self.width = math.floor(width * ratio);
	self.height = math.floor(self.width * 1.7)

	self.button_width = math.floor(self.width / 3);
	self.button_height = self.button_width;

	self.left = left or Screen:GetWidth() - width
	self.top = top or (Screen:GetHeight() - self.height)

	-- 50% padding between keys
	self.key_margin = math.floor(math.min(self.finger_size, self.button_width*0.11) * 0.5); 
	
	local main_item = self.keylayout[1]
	main_item.pos_x = main_item.default_pos_x * ratio
	main_item.pos_y = main_item.default_pos_y * ratio
	for index, item in ipairs(self.keylayout) do
		item.width = math.floor(item.default_width * ratio)
		item.height = math.floor(item.default_height * ratio)

		if item.default_off_pos_x and item.default_off_pos_y then
			item.off_pos_x = math.floor(item.default_off_pos_x * ratio)
			item.off_pos_y = math.floor(item.default_off_pos_y * ratio)
		end
	end

	self:CreateWindow();
end

function TouchMiniRightKeyboard:GetButtonWidth()
	return self.button_width;
end


function TouchMiniRightKeyboard:GetUIControl()
	local _parent = ParaUI.GetUIObject(self.id or self.name);
	
	if(not _parent:IsValid()) then
		_parent = ParaUI.CreateUIObject("container",self.name, self.alignment,self.left,self.top,self.width,self.height);
		_parent.background = "";
		_parent:AttachToRoot();
		_parent.zorder = self.zorder;
		-- _parent:SetScript("ontouch", function() self:OnTouch(msg) end);
		-- _parent:SetScript("onmousedown", function() self:OnMouseDown() end);
		-- _parent:SetScript("onmouseup", function() self:OnMouseUp() end);
		-- _parent:SetScript("onmousemove", function() self:OnMouseMove() end);
		_parent:SetField("ClickThrough", true);

		self.id = _parent.id;
	end
	return _parent;
end

-- simulate the touch event with id=-1
function TouchMiniRightKeyboard:OnMouseDown()
	local touch = {type="WM_POINTERDOWN", x=mouse_x, y=mouse_y, id=-1, time=0};
	self:OnTouch(touch);
end

-- simulate the touch event
function TouchMiniRightKeyboard:OnMouseUp()
	local touch = {type="WM_POINTERUP", x=mouse_x, y=mouse_y, id=-1, time=0};
	self:OnTouch(touch);
end

-- simulate the touch event
function TouchMiniRightKeyboard:OnMouseMove()
	local touch = {type="WM_POINTERUPDATE", x=mouse_x, y=mouse_y, id=-1, time=0};
	self:OnTouch(touch);
end

-- handleTouchEvent
function TouchMiniRightKeyboard:OnTouch(touch)
	-- handle the touch

	local touch_session = TouchSession.GetTouchSession(touch);

	local btnItem = self:GetButtonItem(touch.x, touch.y);
	-- let us track it with an item. 
	if(touch.type == "WM_POINTERDOWN") then
		if(btnItem) then
			touch_session:SetField("keydownBtn", btnItem);
			self:SetKeyState(btnItem, true);
			btnItem.isDragged = nil;
			if(btnItem.camera_zoom) then
				touch_session:SetField("cameraDist", GameLogic.options:GetCameraObjectDistance());
			elseif(btnItem.flyUpDown) then
				local focus_entity = EntityManager.GetFocus();
				if(focus_entity) then
					local x, y, z = focus_entity:GetPosition();
					touch_session:SetField("cameraPosY", y);
				end
			elseif btnItem.name == "Space" then
				GameLogic.DoJump()
			elseif btnItem.name == "KeyBoard" then
				local TouchVirtualKeyboardIcon = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchVirtualKeyboardIcon")
				TouchVirtualKeyboardIcon = TouchVirtualKeyboardIcon.GetSingleton()
				if TouchVirtualKeyboardIcon then
					local keyboard = TouchVirtualKeyboardIcon:GetKeyBoard()
					TouchVirtualKeyboardIcon:ShowKeyboard(not keyboard:isVisible())
					if keyboard:isVisible() then
						if(keyboard:IsFocusedMode()) then
							keyboard:SetTransparency(0.85, true);
						else
							keyboard:SetTransparency(TouchVirtualKeyboardIcon.default_transparency, true);	
						end
					end
				end

			end
		end
	elseif(touch.type == "WM_POINTERUPDATE") then
		local keydownBtn = touch_session:GetField("keydownBtn");
		if(keydownBtn and touch_session:IsDragging()) then
			keydownBtn.isDragged = true;
			local dx, dy = touch_session:GetOffsetFromStartLocation();

			if (keydownBtn.camera_zoom) then
				local cameraStartDist = touch_session:GetField("cameraDist");
				if(cameraStartDist) then
					local delta;
					local fingerSize = touch_session:GetFingerSize();
					if(dy>=0) then
						delta = (dy + fingerSize * 5) / (fingerSize * 5);
					else
						delta = (fingerSize * 5) / (-dy + fingerSize*5);
					end
					GameLogic.options:SetCameraObjectDistance(cameraStartDist*delta);
				end
			elseif(keydownBtn.flyUpDown) then
				local cameraPosY = touch_session:GetField("cameraPosY");
				if(cameraPosY) then
					local fingerSize = touch_session:GetFingerSize();
					local delta = dy / fingerSize;
					local focus_entity = EntityManager.GetFocus();
					if(focus_entity and not focus_entity:IsControlledExternally()) then
						keydownBtn.delta = delta;
						if (not keydownBtn.timer) then
							keydownBtn.timer = commonlib.Timer:new({callbackFunc = function(timer)
								focus_entity:MoveEntityByDisplacement(0, -keydownBtn.delta*0.02, 0);
							end})
							keydownBtn.timer:Change(0, 30);
						end
					end
				end
			end
			keydownBtn.hover_testing_btn = btnItem;
			-- finger is hovering another button instead of the initial button. 
			if(btnItem and btnItem~=keydownBtn) then
				if(not keydownBtn.auto_mouseup and btnItem.allow_hover_press and not btnItem.isKeyDown) then
					if(not btnItem.hover_press_start) then
						btnItem.hover_press_start = true;
						if (not btnItem.timer) then
							btnItem.timer = commonlib.Timer:new({callbackFunc = function(timer)
								if(keydownBtn.isKeyDown and  keydownBtn.hover_testing_btn == btnItem) then
									keydownBtn.hover_press_btns = keydownBtn.hover_press_btns or {};
									keydownBtn.hover_press_btns[btnItem] = true;
									self:SetKeyState(btnItem, true);
								end
							end})
							btnItem.timer:Change(self.hover_press_hold_time);
						end
					end
				elseif(keydownBtn.auto_mouseup and btnItem.auto_mouseup)then
					if(keydownBtn.isKeyDown) then
						self:SetKeyState(keydownBtn, false);
						touch_session:SetField("keydownBtn", btnItem);
						self:SetKeyState(btnItem, true);
					end
				end
			end
		end
		
	elseif(touch.type == "WM_POINTERUP") then
		local keydownBtn = touch_session:GetField("keydownBtn");
		if(keydownBtn) then
			if(keydownBtn.name=="Ctrl" and btnItem and btnItem.ctrl_name) then
				-- do a combo key.
				-- TODO: find a better way to send the actual key, instead of calling command directly. 

				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
				local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
				local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
				local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");

				if(btnItem.ctrl_name == "S") then
					GameLogic.QuickSave();
				elseif(btnItem.ctrl_name == "Y") then
					if(GameMode:IsAllowGlobalEditorKey()) then
						UndoManager.Redo();
					end
				elseif(btnItem.ctrl_name == "Z") then
					if(GameMode:IsAllowGlobalEditorKey()) then
						UndoManager.Undo();
					end
				end
			end
			self:SetKeyState(keydownBtn, false);
		end
	end
end


function TouchMiniRightKeyboard:SetKeyState(btnItem, isDown)
	if btnItem.img == nil then
		return
	end
	local parent = self:GetUIControl();
	local keyBtn = parent:GetChild(btnItem.name);
	btnItem.isKeyDown = isDown;
	if(isDown) then
		self:SetColorMask(btnItem, "pressed")
	else
		self:SetColorMask(btnItem, "normal")
		btnItem.hover_press_start = nil;

		local hover_press_btns = btnItem.hover_press_btns;
		if(hover_press_btns) then
			btnItem.hover_press_btns = nil;
			-- fire mouse up for all hover press btns
			for btn, _ in pairs(hover_press_btns) do
				self:SetKeyState(btn, false)
			end
		end

		if(btnItem.timer) then
			btnItem.timer:Change();
			btnItem.timer = nil;
		end
		btnItem.hover_testing_btn = nil;
	end

	if(isDown) then
		TouchMiniKeyboard.GetSingleton():SetTransparency(1);
	else
		TouchMiniKeyboard.GetSingleton():SetTransparency(0.2, true);
	end
	if(btnItem.click_only) then
		-- only send click event
		if(not isDown and not btnItem.isDragged) then
			self:SendRawKeyEvent(btnItem, true);
			self:SendRawKeyEvent(btnItem, false);
		end
	else
		self:SendRawKeyEvent(btnItem, isDown);
		
	end
end

function TouchMiniRightKeyboard:SendRawKeyEvent(btnItem, isDown)
	if(btnItem.vKey) then
		Keyboard:SendKeyEvent(isDown and "keyDownEvent" or "keyUpEvent", btnItem.vKey);
	end
end


function TouchMiniRightKeyboard:GetItemDisplayText(item, bFnPressed, bShiftPressed)
	if(item.name) then
		if(item.name2) then
			return format("%s\n%s", item.name2, item.name);
		else
			return item.name;
		end
	end
	return;
end

-- get button item by global touch screen position. 
function TouchMiniRightKeyboard:GetButtonItem(x, y)
	x = x - self.left;
	y = y - self.top;
	for _, item in ipairs(self.keylayout) do
		if x >= item.pos_x and x <= item.pos_x + item.width and y >= item.pos_y and y <= item.pos_y + item.height then
			return item;
		end
	end
end


-- private: calculate and create layout.  columns(16) * rows(5)
function TouchMiniRightKeyboard:CreateWindow()
	local _parent = self:GetUIControl();
	_parent:RemoveAll();
	_parent:Reposition(self.alignment,self.left,self.top,self.width,self.height);
	_parent.visible = false;

	local start_angle = 255
	local angle_dis = 52
	local radius = 95

	local main_item = self.keylayout[1]
	local main_pos_x = main_item.pos_x
	local main_pos_y = main_item.pos_y

	local main_item_center_pos_x = main_pos_x + main_item.width/2
	local main_item_center_pos_y = main_pos_y + main_item.height/2
	
	for index, item in ipairs(self.keylayout) do
		item.mask_object = nil;

		local pos_x = item.pos_x or 0
		local pos_y = item.pos_y or 0
		if item.is_child then
			pos_x = main_item_center_pos_x + math.cos(math.rad(start_angle)) * radius - item.width/2
			pos_y = main_item_center_pos_y - math.sin(math.rad(start_angle)) * radius - item.height/2

			item.pos_x = pos_x;
			item.pos_y = pos_y;	
			start_angle = start_angle + angle_dis
		end
		

		local keyBtn = ParaUI.CreateUIObject("container",item.name, "_lt", pos_x, pos_y, item.width, item.height);
		keyBtn:SetScript("ontouch", function() self:OnTouch(msg) end);
		keyBtn:SetScript("onmousedown", function() self:OnMouseDown() end);
		keyBtn:SetScript("onmouseup", function() self:OnMouseUp() end);
		keyBtn:SetScript("onmousemove", function() self:OnMouseMove() end);
		-- keyBtn:SetField("ClickThrough", false);
		keyBtn.background = item.img;
		-- keyBtn.enabled = false;
		item.key_object = keyBtn
		self:SetColorMask(item, "normal")
		_guihelper.SetUIColor(keyBtn, self.colors[1].normal);
		_parent:AddChild(keyBtn);
	end
end

function TouchMiniRightKeyboard:GetKeyBoard()
	if(not self.keyboard) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchVirtualKeyboard.lua");
		local TouchVirtualKeyboard = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchVirtualKeyboard");
		self.keyboard = TouchVirtualKeyboard:new():Init("TouchVirtualKeyboard");
		self.keyboard:Connect("hidden", self, function()
		end)
	end
	return self.keyboard;
end

function TouchMiniRightKeyboard:SetColorMask(item, state)
	state = state or "normal"
	if item.mask_object == nil then
		local mask = ParaUI.CreateUIObject("button",item.name .. "_mask", "_lt", item.pos_x, item.pos_y, item.width, item.height);
		_guihelper.SetUIColor(mask, self.colors[1].normal);
		mask.enabled = false;
		item.mask_object = mask
		local _parent = self:GetUIControl()
		_parent:AddChild(mask)
	end

	local mark_list = item.main and TouchMiniRightKeyboard.MainItemColorMaskList or TouchMiniRightKeyboard.ColorMaskList
	local mask = item.mask_object
	mask.background = mark_list[state] or mark_list["normal"];
end

function TouchMiniRightKeyboard:UpdataPosition()
	-- body
end

function TouchMiniRightKeyboard:SetTransparencyImp(alpha)
	local _parent = self:GetUIControl();
	_guihelper.SetColorMask(_parent, format("255 255 255 %d",math.floor(alpha * 255)))
	_parent:ApplyAnim();
end

function TouchMiniRightKeyboard:GetFlyBt()
	for _, item in ipairs(self.keylayout) do
		if item.flyUpDown then
			return item;
		end
	end
end

function TouchMiniRightKeyboard:ChangeFlyBtImg()
	local fly_bt = nil
	for _, item in ipairs(self.keylayout) do
		if item.flyUpDown then
			fly_bt = item.key_object;
			break
		end
	end
	if nil == fly_bt then
		return
	end

	local entity = EntityManager.GetFocus()
	local img = entity.bFlying and "Texture/Aries/Creator/keepwork/MiniKey/10_2_86X86_32bits.png;0 0 86 86" or "Texture/Aries/Creator/keepwork/MiniKey/10_86X86_32bits.png;0 0 86 86"
	fly_bt.background = img
end