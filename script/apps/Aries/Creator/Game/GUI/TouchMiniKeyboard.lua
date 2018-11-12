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
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchMiniKeyboard.lua");
local TouchMiniKeyboard = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchMiniKeyboard");
local kb = TouchMiniKeyboard:new():Init("TouchMiniKeyboard");
kb:SetTransparency(0.5)
kb:Show(true);

-- static singleton to show at default left bottom position
TouchMiniKeyboard.CheckShow(true);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchSession.lua");
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
NPL.load("(gl)script/ide/System/Windows/Mouse.lua");
local Mouse = commonlib.gettable("System.Windows.Mouse");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local TouchSession = commonlib.gettable("MyCompany.Aries.Game.Common.TouchSession");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Screen = commonlib.gettable("System.Windows.Screen");

local TouchMiniKeyboard = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.GUI.TouchMiniKeyboard"));
TouchMiniKeyboard:Property("Name", "TouchMiniKeyboard");
TouchMiniKeyboard.name = "default_TouchMiniKeyboard";

-- default to 0.5 second. 
TouchMiniKeyboard.hover_press_hold_time = 500;

function TouchMiniKeyboard:ctor()
	self.alignment = "_lt";
	self.zorder = -10;

	-- @param allow_hover_press: this will simulate pressing the multiple buttons at the same time. 
	self.keylayout = {
		{
			{name="F", col=1, colorid=2, vKey = DIK_SCANCODE.DIK_F, flyUpDown = true, click_only = true},
			-- left mouse button when pressed. otherwise it default to right. drag to scroll the camera
			{name="RMB", col=2, toggleRightMouseButton=true, colorid=4, camera_zoom = true, allow_hover_press = true}, 
		},
		{
			{name="Shift", col=1, colorid=2, vKey = DIK_SCANCODE.DIK_LSHIFT, allow_hover_press = true},
			{name="W", col=1, vKey = DIK_SCANCODE.DIK_W},
			{name="E", col=1, colorid=3, vKey = DIK_SCANCODE.DIK_E},
		},
		{
			{name="A", col=1, ctrl_name="Y", vKey = DIK_SCANCODE.DIK_A},
			{name="S", col=1, ctrl_name="S", vKey = DIK_SCANCODE.DIK_S},
			{name="D", col=1, vKey = DIK_SCANCODE.DIK_D},
		},
		{
			{name="Ctrl", col=1, colorid=2, vKey = DIK_SCANCODE.DIK_LCONTROL, allow_hover_press = true},
			{name="Space", col=1, ctrl_name="Z", vKey = DIK_SCANCODE.DIK_SPACE},
			{name="Alt", col=1, colorid=2, vKey = DIK_SCANCODE.DIK_LMENU, allow_hover_press = true},
		},
	}

	-- normalBtn, comboBtn, frequentBtn, mouseRight
	self.colors = { 
		{normal="#ffffff", pressed="#888888"}, 
		{normal="#cccccc", pressed="#333333"}, 
		{normal="#8888ff", pressed="#3333cc"},
		{normal="#888888", pressed="#ff6600"},
	};

	self.finger_size = 10;
	self.transparency = 1;
end

local s_instance;
function TouchMiniKeyboard.GetSingleton()
	if(not s_instance) then
		s_instance = TouchMiniKeyboard:new():Init("TouchMiniKeyboard");
		s_instance:SetTransparency(0.5)
	end
	return s_instance;
end

-- static method
function TouchMiniKeyboard.CheckShow(bShow)
	TouchMiniKeyboard.GetSingleton():Show(bShow);
end


-- all input can be nil. 
-- @param name: parent name. it should be a unique name
-- @param left, top: left, top position where to show. 
-- @param width: if width is not specified, it will use all the screen space left from x. 
function TouchMiniKeyboard:Init(name, left, top, width)
	self.name = name or self.name;
	self:SetPosition(left, top, width);
	return self;
end

-- @bShow: if nil, it will toggle show and hide. 
function TouchMiniKeyboard:Show(bShow)
	local _parent = self:GetUIControl();
	if(bShow  == nil) then
		bShow = not _parent.visible;
	end
	_parent.visible = bShow;
end

function TouchMiniKeyboard:Destroy()
	TouchMiniKeyboard._super.Destroy(self);
	ParaUI.Destroy(self.id or self.name);
	self.id = nil;
end

-- @param alpha: 0-1 
function TouchMiniKeyboard:SetTransparency(alpha)
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
function TouchMiniKeyboard:SetPosition(left, top, width)
	width =  width or math.floor(Screen:GetHeight() / 4 * 1.25);
	self.width = width;
	self.button_width = math.floor(self.width / 3);
	self.button_height = self.button_width;
	self.height = self.button_height * 4;

	self.left = left or self.button_width * 0.4;
	self.top = top or math.floor(Screen:GetHeight()/2 + self.button_height * 0.2);

	-- 50% padding between keys
	self.key_margin = math.floor(math.min(self.finger_size, self.button_width*0.11) * 0.5); 

	self:CreateWindow();
end

function TouchMiniKeyboard:GetButtonWidth()
	return self.button_width;
end


function TouchMiniKeyboard:GetUIControl()
	local _parent = ParaUI.GetUIObject(self.id or self.name);
	
	if(not _parent:IsValid()) then
		_parent = ParaUI.CreateUIObject("container",self.name, self.alignment,self.left,self.top,self.width,self.height);
		_parent.background = "";
		_parent:AttachToRoot();
		_parent.zorder = self.zorder;
		_parent:SetScript("ontouch", function() self:OnTouch(msg) end);
		_parent:SetScript("onmousedown", function() self:OnMouseDown() end);
		_parent:SetScript("onmouseup", function() self:OnMouseUp() end);
		_parent:SetScript("onmousemove", function() self:OnMouseMove() end);

		self.id = _parent.id;
	else
		_parent:Reposition(self.alignment,self.left,self.top,self.width,self.height);
	end
	return _parent;
end

-- simulate the touch event with id=-1
function TouchMiniKeyboard:OnMouseDown()
	local touch = {type="WM_POINTERDOWN", x=mouse_x, y=mouse_y, id=-1, time=0};
	self:OnTouch(touch);
end

-- simulate the touch event
function TouchMiniKeyboard:OnMouseUp()
	local touch = {type="WM_POINTERUP", x=mouse_x, y=mouse_y, id=-1, time=0};
	self:OnTouch(touch);
end

-- simulate the touch event
function TouchMiniKeyboard:OnMouseMove()
	local touch = {type="WM_POINTERUPDATE", x=mouse_x, y=mouse_y, id=-1, time=0};
	self:OnTouch(touch);
end

-- handleTouchEvent
function TouchMiniKeyboard:OnTouch(touch)
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
			if(btnItem and btnItem~=keydownBtn and btnItem.allow_hover_press and not btnItem.isKeyDown) then
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

function TouchMiniKeyboard:GetRightMouseButtonItem()
	return self.keylayout[1][2];
end

function TouchMiniKeyboard:GetCtrlKey()
	return self.keylayout[4][1];
end


function TouchMiniKeyboard:SetKeyState(btnItem, isDown)
	local parent = self:GetUIControl();
	local keyBtn = parent:GetChild(btnItem.name);
	btnItem.isKeyDown = isDown;
	if(isDown) then
		-- key down event
		_guihelper.SetUIColor(keyBtn, self.colors[btnItem.colorid or 1].pressed);
	else
		-- key up event
		_guihelper.SetUIColor(keyBtn, self.colors[btnItem.colorid or 1].normal);
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

	if(btnItem.name == "Ctrl") then
		for row = 1, #self.keylayout do
			for _, item in ipairs(self.keylayout[row]) do
				if (item.ctrl_name) then
					local keyBtn = parent:GetChild(item.name);
					if(isDown) then
						keyBtn.text = item.ctrl_name;
						_guihelper.SetUIColor(keyBtn, self.colors[3].normal);
					else
						keyBtn.text = self:GetItemDisplayText(item);
						_guihelper.SetUIColor(keyBtn, self.colors[item.colorid or 1].normal);
					end
				end
			end
		end
	end

	if(btnItem.toggleRightMouseButton) then
		local toggleMouseBtn = self:GetRightMouseButtonItem();
		if(toggleMouseBtn and toggleMouseBtn~=btnItem) then
			local keyBtn = parent:GetChild(toggleMouseBtn.name);
			if(isDown) then
				_guihelper.SetUIColor(keyBtn, self.colors[toggleMouseBtn.colorid or 1].pressed);
			else
				_guihelper.SetUIColor(keyBtn, self.colors[toggleMouseBtn.colorid or 1].normal);
			end
		end
		Mouse:SetTouchButtonSwapped(isDown);
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

function TouchMiniKeyboard:SendRawKeyEvent(btnItem, isDown)
	if(btnItem.vKey) then
		Keyboard:SendKeyEvent(isDown and "keyDownEvent" or "keyUpEvent", btnItem.vKey);
	end
end


function TouchMiniKeyboard:GetItemDisplayText(item, bFnPressed, bShiftPressed)
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
function TouchMiniKeyboard:GetButtonItem(x, y)
	x = x - self.left;
	y = y - self.top;
	for row = 1, #self.keylayout do
		for _, item in ipairs(self.keylayout[row]) do
			if (item.top and item.top <= y and y<=item.bottom and item.left <=x and x<=item.right) then
				return item;
			end
		end
	end
end


-- private: calculate and create layout.  columns(16) * rows(5)
function TouchMiniKeyboard:CreateWindow()
	local _parent = self:GetUIControl();
	_parent:RemoveAll();
	_parent.visible = false;
	
	local btn_margin = self.key_margin;
	for row = 1, #self.keylayout do
		local cols = self.keylayout[row];
		local left_col = 0;
		for _, item in ipairs(cols) do
			if (item.name) then
				-- get global screen position
				item.left = left_col*self.button_width;
				item.top = (row-1)*self.button_height;
				item.right = item.left + item.col*self.button_width;
				item.bottom = item.top + self.button_height;

				local keyBtn = ParaUI.CreateUIObject("button",item.name, "_lt", left_col*self.button_width + btn_margin, (row-1)*self.button_height+btn_margin, item.col*self.button_width-btn_margin*2, self.button_height-btn_margin*2);
				keyBtn.background = "Texture/whitedot.png";
				keyBtn.enabled = false;
				keyBtn.text = self:GetItemDisplayText(item);
				_guihelper.SetUIColor(keyBtn, self.colors[item.colorid or 1].normal);
				_guihelper.SetButtonFontColor(keyBtn, "#000000");
				_parent:AddChild(keyBtn);
			end
			left_col = left_col + item.col;
		end
	end
end


