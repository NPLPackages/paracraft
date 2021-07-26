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
TouchMiniKeyboard.CheckShow(true);

-- static singleton to show at default left bottom position
TouchMiniKeyboard.CheckShow(true);
TouchMiniKeyboard.GetSingleton():LoadKeyboardLayout({{{name="A", vKey = DIK_SCANCODE.DIK_A}, {name="C", vKey = DIK_SCANCODE.DIK_C}}, {{name="B", vKey = DIK_SCANCODE.DIK_B}}})
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchSession.lua");
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
NPL.load("(gl)script/ide/System/Windows/Mouse.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchMiniRightKeyboard.lua");
NPL.load("(gl)script/ide/Transitions/Tween.lua");
local Mouse = commonlib.gettable("System.Windows.Mouse");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local TouchSession = commonlib.gettable("MyCompany.Aries.Game.Common.TouchSession");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Screen = commonlib.gettable("System.Windows.Screen");
local TouchMiniRightKeyboard = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchMiniRightKeyboard");

local TouchMiniKeyboard = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.GUI.TouchMiniKeyboard"));
TouchMiniKeyboard:Property("Name", "TouchMiniKeyboard");
TouchMiniKeyboard.name = "default_TouchMiniKeyboard";

-- default to 0.5 second. 
TouchMiniKeyboard.hover_press_hold_time = 500;

-- @param name: displayname
-- @param vKey: virtual key scan code. 
-- @param allow_hover_press: this will simulate pressing the multiple buttons at the same time. 
-- @param auto_mouseup: if the touch is no longer over a button, it will automatically fire the mouse up event. 
-- @param col: column span, default to 1. 
-- @param colorid: default to 1. we have 1,2,3,4 color themes for normalBtn, comboBtn, frequentBtn, mouseRight. 
-- @param ctrl_name: when ctrl key is pressed, this button may be transformed to another button. 
-- @param toggleRightMouseButton: whether to toggle right mouse button when this button is pressed. 
-- @param click_only: we will only send up and down event together when button is up.


TouchMiniKeyboard.DefaultKeyLayout = {
	{
		{name="Shift", dragcombo = true, col=1, colorid=2, ctrl_name="Shift", is_change_img = false, vKey = DIK_SCANCODE.DIK_LSHIFT, allow_hover_press = true, img="Texture/Aries/Creator/keepwork/MiniKey/zi3_94X88_32bits.png;0 0 94 88", only_read_visible = false},
		-- tricky: when W key is pressed, we will assume right mouse button is down, so that the user can simultaneously control player facing
		{name="W", col=1, vKey = DIK_SCANCODE.DIK_W, auto_mouseup = true, toggleRightMouseButton=false, img="Texture/Aries/Creator/keepwork/MiniKey/shang_94X88_32bits.png;0 0 94 88", only_read_visible = true},
		{name="RMB", col=1, toggleRightMouseButton=true, colorid=4, allow_hover_press = true, img="Texture/Aries/Creator/keepwork/MiniKey/4_94X88_32bits.png;0 0 94 88", only_read_visible = true, child_button = 
			{
				Top = {name = "LockRight", visible = false, img="Texture/Aries/Creator/keepwork/MiniKey/5_94X88_32bits.png;0 0 94 88", only_read_visible = false},
				Right = {name = "LockMiddle", visible = false, img="Texture/Aries/Creator/keepwork/MiniKey/11_94X88_32bits.png;0 0 94 88", only_read_visible = false},
			}
		}, 
	},
	{
		{name="A", col=1, ctrl_name="Y", is_change_img = true, vKey = DIK_SCANCODE.DIK_A, auto_mouseup = true, toggleRightMouseButton=false, img="Texture/Aries/Creator/keepwork/MiniKey/zuo_94X88_32bits.png;0 0 94 88", only_read_visible = true},
		{name="S", col=1, ctrl_name="S", is_change_img = true, vKey = DIK_SCANCODE.DIK_S, auto_mouseup = true, toggleRightMouseButton=false, img="Texture/Aries/Creator/keepwork/MiniKey/xia_94X88_32bits.png;0 0 94 88", only_read_visible = true},
		{name="D", col=1, vKey = DIK_SCANCODE.DIK_D, auto_mouseup = true, toggleRightMouseButton=false, img="Texture/Aries/Creator/keepwork/MiniKey/you_94X88_32bits.png;0 0 94 88", only_read_visible = true},
	},
	{
		{name="Ctrl",dragcombo = true, col=1, colorid=2, vKey = DIK_SCANCODE.DIK_LCONTROL, allow_hover_press = true, img="Texture/Aries/Creator/keepwork/MiniKey/zi1_94X88_32bits.png;0 0 94 88", only_read_visible = false},
		{name="Alt", col=1, ctrl_name="Z", is_change_img = true, colorid=2, vKey = DIK_SCANCODE.DIK_LMENU, allow_hover_press = true, img="Texture/Aries/Creator/keepwork/MiniKey/zi2_94X88_32bits.png;0 0 94 88", only_read_visible = false},
		{name="E", col=1, vKey = DIK_SCANCODE.DIK_E, auto_mouseup = true, img="Texture/Aries/Creator/keepwork/MiniKey/zi4_94X88_32bits.png;0 0 94 88", only_read_visible = false},
	},
};


TouchMiniKeyboard.RMBLockStateList = {
	NoLock = 0,
	LockRight = 1,
	LockMiddle = 2,
}

TouchMiniKeyboard.RMBLockStateToImg = {
	[TouchMiniKeyboard.RMBLockStateList.NoLock] = "Texture/Aries/Creator/keepwork/MiniKey/4_94X88_32bits.png;0 0 94 88",
	[TouchMiniKeyboard.RMBLockStateList.LockRight] = "Texture/Aries/Creator/keepwork/MiniKey/5_94X88_32bits.png;0 0 94 88",
	[TouchMiniKeyboard.RMBLockStateList.LockMiddle] = "Texture/Aries/Creator/keepwork/MiniKey/11_94X88_32bits.png;0 0 94 88",
}

TouchMiniKeyboard.ColorMaskList = {
	normal = "Texture/Aries/Creator/keepwork/MiniKey/2_94X88_32bits.png;0 0 94 88",
	pressed = "Texture/Aries/Creator/keepwork/MiniKey/1_94X88_32bits.png;0 0 94 88",
	gray = "Texture/Aries/Creator/keepwork/MiniKey/3_94X88_32bits.png;0 0 94 88",
}

TouchMiniKeyboard.DirectionKey = {
	Up = {"W"},
	Down ={"S"},
	Left = {"A"},
	Right = {"D"},
	UpLeft = {"W","A"},
	UpRight = {"W","D"},
	DownLeft = {"S","A"},
	DownRight = {"S","D"},
}

function TouchMiniKeyboard:ctor()
	self.alignment = "_lt";
	self.zorder = -10;
	self.alphaAnimSpeed = 10/256;
	self.rmb_lock_state = TouchMiniKeyboard.RMBLockStateList.NoLock
	-- normalBtn, comboBtn, frequentBtn, mouseRight
	self.colors = { 
		{normal="#ffffff", pressed="#888888"}, 
		{normal="#cccccc", pressed="#333333"}, 
		{normal="#8888ff", pressed="#3333cc"},
		{normal="#888888", pressed="#ff6600"},
	};

	self.finger_size = 10;
	self.transparency = 1;

	self.keylayout = TouchMiniKeyboard.DefaultKeyLayout;

	GameLogic:Connect("WorldLoaded", TouchMiniKeyboard, function()
		self:UpdateIconVisible()
		GameLogic.events:AddEventListener("game_mode_change", self.UpdateIconVisible, self, "TouchMiniKeyboard");
	end, "UniqueConnection");

	
end

-- @param keyLayout: if nil, it will load the default layout. 
-- otherwise, it should be a table of M*N, each item can be {name="E", vKey = DIK_SCANCODE.DIK_E}, with some options. 
-- for options and examples, see TouchMiniKeyboard.DefaultKeyLayout
--[[ e.g.
TouchMiniKeyboard.GetSingleton():LoadKeyboardLayout({ 
 { {name="A", vKey = DIK_SCANCODE.DIK_A}, {name="B", vKey = DIK_SCANCODE.DIK_B}, {name="C", vKey = DIK_SCANCODE.DIK_C} }, 
 { {name="C", vKey = DIK_SCANCODE.DIK_C}, {name="D", vKey = DIK_SCANCODE.DIK_D}, {name="C", vKey = DIK_SCANCODE.DIK_E} }, 
 { {name="F", vKey = DIK_SCANCODE.DIK_F}, {name="G", vKey = DIK_SCANCODE.DIK_G}, {name="H", vKey = DIK_SCANCODE.DIK_H} }, 
})
]]
function TouchMiniKeyboard:LoadKeyboardLayout(keyLayout)
	local oldLayout = self.keylayout;
	self.keylayout = keyLayout or TouchMiniKeyboard.DefaultKeyLayout;
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
function TouchMiniKeyboard.GetSingleton()
	if(not s_instance) then
		s_instance = TouchMiniKeyboard:new():Init("TouchMiniKeyboard");
		-- s_instance:SetTransparency(0.5)
	end
	return s_instance;
end

-- static method
function TouchMiniKeyboard.CheckShow(bShow)
	TouchMiniKeyboard.GetSingleton():Show(bShow);
	TouchMiniRightKeyboard.GetSingleton():Show(bShow);
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
	self.bIsVisible = bShow;
end

function TouchMiniKeyboard:isVisible()
	return self.bIsVisible
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
	self.default_height = 720
	self.default_button_width = 94
	self.default_button_height = 88
	self.default_key_margin = 5

	-- width =  width or math.floor(Screen:GetHeight() / 4 * 1.4);
	
	local ratio = Screen:GetHeight()/self.default_height

	-- self.width = width;

	
	self.button_width = self.default_button_width * ratio;
	self.width = self.button_width  *3
	
	self.button_height = self.default_button_height * ratio;
	self.height = self.button_height * 3;

	self.left = left or self.button_width * 0.4;
	self.top = top or math.floor(Screen:GetHeight() - self.height - self.button_height);

	-- 50% padding between keys
	self.key_margin = math.floor(math.min(self.finger_size, self.button_width*0.1) * 0.5);
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

function TouchMiniKeyboard:Print(...)
	local arg={...}
	local str = ""
	for index, v in ipairs(arg) do
		str = str .. ", " .. tostring(v)
	end
	str = str .. "   time:" .. os.time()
	commonlib.echo(str)
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
			end
		end
	elseif(touch.type == "WM_POINTERUPDATE") then
		local keydownBtn = touch_session:GetField("keydownBtn");
		if(keydownBtn and touch_session:IsDragging()) then
			
			if keydownBtn.name == "W" or keydownBtn.name == "A" or keydownBtn.name == "S" or keydownBtn.name == "D" then
				if self.cur_move_state == nil then
					local state = ""
					for k, v in pairs(TouchMiniKeyboard.DirectionKey) do
						if #v== 1 and keydownBtn.name == v[1] then
							state = k
							break
						end
					end
					self.cur_move_state = state
					local key_name_list = TouchMiniKeyboard.DirectionKey[self.cur_move_state]
					self:SetKeyListState(key_name_list, true)
				else
					self:ChangeMoveState(touch.x, touch.y)
				end
				
				return
			end
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
		if(keydownBtn and keydownBtn.img) then
			if self.cur_move_state then
				self:StopMoveState()
				return
			end
			-- if(keydownBtn.name=="Ctrl" and btnItem and btnItem.ctrl_name) then
			-- 	-- do a combo key.
			-- 	-- TODO: find a better way to send the actual key, instead of calling command directly. 

			-- 	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
			-- 	local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
			-- 	local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
			-- 	local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");

			-- 	if(btnItem.ctrl_name == "S") then
			-- 		GameLogic.QuickSave();
			-- 	elseif(btnItem.ctrl_name == "Y") then
			-- 		if(GameMode:IsAllowGlobalEditorKey()) then
			-- 			UndoManager.Redo();
			-- 		end
			-- 	elseif(btnItem.ctrl_name == "Z") then
			-- 		if(GameMode:IsAllowGlobalEditorKey()) then
			-- 			UndoManager.Undo();
			-- 		end
			-- 	end
			-- end

			if keydownBtn.child_button then
				local child_item = self:GetChildButtonItem(touch.x, touch.y, keydownBtn.child_button)
				if child_item and (child_item.name == "LockRight" or child_item.name == "LockMiddle") then
					self:ChangeMouseLockStata(child_item.name)
				end

				if btnItem and keydownBtn.name == "RMB" and btnItem.name == "RMB" then
					self:ChangeMouseLockStata("NoLock")
				end
			end

			if(btnItem and btnItem~=keydownBtn and keydownBtn.dragcombo) then
				local name = btnItem.name
				local vKey = btnItem.vKey
				if keydownBtn.name == "Ctrl" and btnItem.ctrl_name ~= nil then
					btnItem.name = btnItem.ctrl_name
					btnItem.vKey = DIK_SCANCODE["DIK_" .. btnItem.ctrl_name]
				end
				self:SetKeyState(btnItem, true);
				commonlib.TimerManager.SetTimeout(function()  
					self:SetKeyState(btnItem, false);
					self:SetKeyState(keydownBtn, false);

					btnItem.name = name
					btnItem.vKey = vKey
				end, 100)
			else
				self:SetKeyState(keydownBtn, false);
			end
			
		end
	end
end

function TouchMiniKeyboard:GetRMBItem()
	return self.keylayout[1][3];
end

function TouchMiniKeyboard:GetCtrlKey()
	return self.keylayout[4][1];
end

function TouchMiniKeyboard:GetCneterItem()
	return self.keylayout[2][2];
end

function TouchMiniKeyboard:SetKeyState(btnItem, isDown)
	local parent = self:GetUIControl();
	local keyBtn = parent:GetChild(btnItem.name);
	btnItem.isKeyDown = isDown;
	if(isDown) then
		-- key down event
	
		self:SetColorMask(btnItem, "pressed")
		-- _guihelper.SetUIColor(keyBtn, self.colors[btnItem.colorid or 1].pressed);
	else
		-- key up event
		-- _guihelper.SetUIColor(keyBtn, self.colors[btnItem.colorid or 1].normal);
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

	if(btnItem.name == "Ctrl") then
		-- for row = 1, #self.keylayout do
		-- 	for _, item in ipairs(self.keylayout[row]) do
		-- 		local keyBtn = item.key_object;
		-- 		if (item.ctrl_name) then
		-- 			if(isDown) then
		-- 				if item.is_change_img then
		-- 					keyBtn.background = string.format("Texture/Aries/Creator/keepwork/MiniKey/%s_94X88_32bits.png;0 0 94 88", item.ctrl_name)
		-- 				end
		-- 				_guihelper.SetUIColor(keyBtn, self.colors[3].normal);
		-- 			else
		-- 				keyBtn.background = item.img
		-- 				_guihelper.SetUIColor(keyBtn, self.colors[item.colorid or 1].normal);
		-- 			end
		-- 		elseif item.name ~= "Ctrl" then
		-- 			if(isDown) then
		-- 				_guihelper.SetUIColor(item.mask_object, self.colors[1].pressed)
		-- 				_guihelper.SetUIColor(keyBtn, self.colors[1].pressed)
		-- 			else
		-- 				_guihelper.SetUIColor(item.mask_object, self.colors[1].normal)
		-- 				_guihelper.SetUIColor(keyBtn, self.colors[1].normal)
		-- 			end
		-- 		end
		-- 	end
		-- end
		self:ChangeCtrlPressState(isDown)
	end

	if(btnItem.child_button) then
		for key, child_item in pairs(btnItem.child_button) do
			-- local keyBtn = parent:GetChild(child_item.name);
			local keyBtn = child_item.key_object
			if(isDown) then
				keyBtn.visible = true
				child_item.mask_object.visible = true
				-- keyBtn:ApplyAnim()
				-- _guihelper.SetUIColor(keyBtn, self.colors[3].normal);
			else
				keyBtn.visible = false
				child_item.mask_object.visible = false
				-- _guihelper.SetUIColor(keyBtn, self.colors[child_item.colorid or 1].normal);
			end
		end
	end

	if(btnItem.toggleRightMouseButton) then
		local toggleMouseBtn = self:GetRMBItem();
		if(toggleMouseBtn and toggleMouseBtn~=btnItem) then
			local keyBtn = parent:GetChild(toggleMouseBtn.name);
			if(isDown) then
				-- _guihelper.SetUIColor(keyBtn, self.colors[toggleMouseBtn.colorid or 1].pressed);
			else
				-- _guihelper.SetUIColor(keyBtn, self.colors[toggleMouseBtn.colorid or 1].normal);
			end
		end
		Mouse:SetTouchButtonSwapped(isDown or self.rmb_lock_state == TouchMiniKeyboard.RMBLockStateList.LockRight);
	end

	if(isDown) then
		self:SetTransparency(1);
	else
		self:SetTransparency(0.2, true);
	end

	self:SendRawKeyEvent(btnItem, isDown);
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
			if (item.visible and item.top and item.top <= y and y<=item.bottom and item.left <=x and x<=item.right) then
				return item;
			end
		end
	end
end

-- get button item by global touch screen position. 
function TouchMiniKeyboard:GetChildButtonItem(x, y, child_button)
	x = x - self.left;
	y = y - self.top;
	for index, item in pairs(child_button) do
		
		if (item.top and y >= item.top and y<=item.bottom and x >= item.left and x<=item.right) then
			return item;
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
				item.top = (row - 1)*self.button_height;
				item.right = item.left + (item.col or 1)*self.button_width;
				item.bottom = item.top + self.button_height;

				item.pos_x = item.left + btn_margin
				item.pos_y = item.top+btn_margin
				item.width = (item.col or 1)*self.button_width-btn_margin*2
				item.height = self.button_height-btn_margin*2

				local keyBtn = ParaUI.CreateUIObject("button",item.name, "_lt", item.pos_x, item.pos_y, item.width, item.height);
				keyBtn.background = item.img;
				keyBtn.enabled = false;
				-- keyBtn.text = self:GetItemDisplayText(item);
				item.key_object = keyBtn
				self:SetColorMask(item, "normal")
				_guihelper.SetUIColor(keyBtn, self.colors[1].normal);
				-- _guihelper.SetButtonFontColor(keyBtn, "#000000");
				_parent:AddChild(keyBtn);

				if item.child_button ~= nil then
					for key, child_item in pairs(item.child_button) do
						child_item.left = item.left
						child_item.top = item.top;
						child_item.right = item.right;
						child_item.bottom = item.bottom;

						if key == "Top" then
							child_item.top = item.top - self.button_height;
							child_item.bottom = item.top;
						else
							child_item.right = item.right + self.button_width;
							child_item.left = item.right
						end

						child_item.pos_x = child_item.left + btn_margin
						child_item.pos_y = child_item.top+btn_margin
						child_item.width = self.button_width-btn_margin*2
						child_item.height = self.button_height-btn_margin*2

						local child_keyBtn = ParaUI.CreateUIObject("button",item.name, "_lt", child_item.pos_x, child_item.pos_y, child_item.width, child_item.height);
						child_keyBtn.background = child_item.img;
						child_keyBtn.enabled = false;
						-- child_keyBtn.text = self:GetItemDisplayText(child_item);
						child_item.key_object = child_keyBtn
						
						if child_item.visible ~= nil then
							child_keyBtn.visible = child_item.visible
						end
						self:SetColorMask(child_item, "normal")
						_guihelper.SetUIColor(child_keyBtn, self.colors[1].normal);
						-- _guihelper.SetUIColor(child_keyBtn, self.colors[child_item.colorid or 1].normal);
						_guihelper.SetButtonFontColor(child_keyBtn, "#000000");
						_parent:AddChild(child_keyBtn);
					end
				end
			end
			left_col = left_col + (item.col or 1);
		end
	end

	self:UpdateIconVisible()

	self:SetTransparency(0.2, true)
end

function TouchMiniKeyboard:ChangeMouseLockStata(lock_name)
	self.rmb_lock_state = TouchMiniKeyboard.RMBLockStateList[lock_name]
	Mouse:SetTouchButtonSwapped(self.rmb_lock_state == TouchMiniKeyboard.RMBLockStateList.LockRight)
	self:UpdateRMBIcon()
end

function TouchMiniKeyboard:GetRMBLockState()
	return self.rmb_lock_state
end

function TouchMiniKeyboard:SetColorMask(item, state)
	state = state or "normal"
	if item.mask_object == nil then
		local mask = ParaUI.CreateUIObject("button",item.name .. "_mask", "_lt", item.pos_x, item.pos_y, item.width, item.height);
		_guihelper.SetUIColor(mask, self.colors[1].normal);
		mask.enabled = false;
		mask.visible = item.key_object.visible
		item.mask_object = mask
		local _parent = self:GetUIControl()
		_parent:AddChild(mask)
	end
	
	local mark_list = TouchMiniKeyboard.ColorMaskList
	local mask = item.mask_object
	mask.background = mark_list[state] or mark_list["normal"];

end

function TouchMiniKeyboard:ShowMacroCircle(item, is_show)
	if item.circle_object == nil then
		local off_size = 20
		local width = item.width + off_size
		local height = item.height + off_size
		local circle = ParaUI.CreateUIObject("button",item.name .. "_circle", "_lt", item.pos_x - off_size/2, item.pos_y - off_size/2, width, height);
		_guihelper.SetUIColor(circle, self.colors[1].normal);
		circle.enabled = false;
		
		circle.background = "Texture/Aries/Common/ThemeTeen/circle_32bits.png"
		item.circle_object = circle
		local _parent = self:GetUIControl()
		_parent:AddChild(circle)
	end
	
	local circle = item.circle_object
	circle.visible = is_show

end

function TouchMiniKeyboard:UpdateRMBIcon()
	local lock_state = self:GetRMBLockState()
	local lock_img = TouchMiniKeyboard.RMBLockStateToImg[lock_state]
	local btn = self:GetRMBItem().key_object
	btn.background = lock_img
end

-- 只读世界有些按钮不显示
function TouchMiniKeyboard:UpdateIconVisible()
	for row = 1, #self.keylayout do
		local cols = self.keylayout[row];
		local left_col = 0;
		for _, item in ipairs(cols) do
			if (item.key_object) then
				
				if GameLogic.Macros:IsPlaying() then
					self:SetItemButtonVisible(item, true)
				else
					if GameLogic.mode == "editor" then
						self:SetItemButtonVisible(item, true)
					elseif GameLogic.IsReadOnly() or GameLogic.mode == "game" then
						self:SetItemButtonVisible(item, item.only_read_visible)
					end
				end

			end
		end
	end
end

function TouchMiniKeyboard:SetItemButtonVisible(item, visible)
	item.visible = visible
	if item.key_object then
		item.key_object.visible = visible
	end

	if item.mask_object then
		item.mask_object.visible = visible
	end
end

function TouchMiniKeyboard:ShowMacroTip(buttons)
	if not self:isVisible() then
		return 0
	end
	local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")
	-- 这几个先暂时使用小键盘
	-- if buttons == "ctrl+DIK_Z" or buttons == "ctrl+DIK_Y" or buttons == "ctrl+DIK_S" then
	-- 	return 0
	-- end
	local buttons_list = {};
	local has_ctrl_key = false
	local has_y_s_z = false
	local shiled_list = {
		DIK_E = 1,
		DIK_W = 1,
		DIK_A = 1,
		DIK_S = 1,
		DIK_D = 1,
	}

	if shiled_list[buttons] then
		return 0
	end

	for text in buttons:gmatch("([%w_]+)") do
		text = Macros.ConvertKeyNameToButtonText(text)
		if text == "CTRL" then
			has_ctrl_key = true
		end

		if string.lower(text) == "y" or string.lower(text) == "s" or string.lower(text) == "z" then
			has_y_s_z = true
		end
		buttons_list[#buttons_list+1] = text;
	end

	
	local buttons_low_str = string.lower(buttons)
	local key_count = 0
	local mouse_count = 0

	local need_count = 0
	for text in buttons:gmatch("([%w_]+)") do
		if text == "right" or text == "left" then
			if text == "right" and self.rmb_lock_state ~= TouchMiniKeyboard.RMBLockStateList.LockRight or text == "left" and self.rmb_lock_state ~= TouchMiniKeyboard.RMBLockStateList.NoLock  then
				--self:ShowMacroCircle(self:GetRMBItem(), true)
				mouse_count = mouse_count + 1
			end
		else
			need_count = need_count + 1
			text = Macros.ConvertKeyNameToButtonText(text)

			for row = 1, #self.keylayout do
				for _, item in ipairs(self.keylayout[row]) do
					local lower_text = string.lower(text)
					if (lower_text == string.lower(item.name)) or (has_ctrl_key and item.ctrl_name and string.lower(item.ctrl_name) == lower_text) then
						self:ShowMacroCircle(item, true)
						key_count = key_count + 1
			
						break
					end
				end
			end
		end
	end

	if need_count > key_count then
		self:ClearAllKeyDown()
		return 0
	end

	if has_ctrl_key and need_count == 2 and mouse_count == 0 and has_y_s_z then
		self:ShowCtrlDrawAnim()
	end

	if buttons == "shift+right" then
		self:ShowShiftDrawAnim()
	end

	if key_count > 0 or mouse_count > 0 then
		self:SetTransparencyImp(1)
	end

	return key_count
end

function TouchMiniKeyboard:ClearAllKeyDown()
	for row = 1, #self.keylayout do
		for _, item in ipairs(self.keylayout[row]) do
			self:ShowMacroCircle(item, false)
		end
	end
end

function TouchMiniKeyboard:ChangeMoveState(x, y)
	x = x - self.left;
	y = y - self.top;
	local state = self:GetDirectionState(x, y)
	if state == self.cur_move_state or state == nil then
		return
	end

	self:StopMoveState()
	
	self.cur_move_state = state
	local key_name_list = TouchMiniKeyboard.DirectionKey[self.cur_move_state]
	self:SetKeyListState(key_name_list, true)
end

function TouchMiniKeyboard:StopMoveState()
	if self.cur_move_state then
		local last_key_name_list = TouchMiniKeyboard.DirectionKey[self.cur_move_state]
		self:SetKeyListState(last_key_name_list, false)
		self.cur_move_state = nil
	end
end

function TouchMiniKeyboard:SetKeyListState(key_name_list, state)
	for k, v in pairs(key_name_list) do
		for row = 1, #self.keylayout do
			for _, item in ipairs(self.keylayout[row]) do
				if v == item.name then
					self:SetKeyState(item, state)
					break
				end
			end
		end
	end
end

function TouchMiniKeyboard:GetDirectionState(x, y)
	local center_item = self:GetCneterItem()
	local param_y = y - (center_item.pos_y + center_item.height/2)
	local param_x = x - (center_item.pos_x + center_item.width/2)
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

-- @param alpha: 0-1 
function TouchMiniKeyboard:SetTransparency(alpha, bAnimate)
	if(self.transparency ~= alpha) then
		if(bAnimate) then
			self.target_transparency = alpha;
			self.timer = self.timer or commonlib.Timer:new({callbackFunc = function(timer)
				
				if( math.abs(self.transparency - self.target_transparency) < self.alphaAnimSpeed ) then
					self:SetTransparencyImp(self.target_transparency);
					timer:Change();
				else
					self:SetTransparencyImp(self.transparency - self.alphaAnimSpeed*math.abs(self.transparency - self.target_transparency)/(self.transparency - self.target_transparency));
				end
			end})
			self.timer:Change(3000, 33);
		else
			if(self.timer) then
				self.timer:Change();
			end
			self:SetTransparencyImp(alpha)
		end
	end
	return self;
end

function TouchMiniKeyboard:SetTransparencyImp(alpha)
	self.transparency = alpha;
	local _parent = self:GetUIControl();
	_guihelper.SetColorMask(_parent, format("255 255 255 %d",math.floor(alpha * 255)))
	_parent:ApplyAnim();

	TouchMiniRightKeyboard.GetSingleton():SetTransparencyImp(alpha)
end

function TouchMiniKeyboard:ChangeCtrlPressState(is_press)
	for row = 1, #self.keylayout do
		for _, item in ipairs(self.keylayout[row]) do
			local keyBtn = item.key_object;
			if (item.ctrl_name) then
				if(is_press) then
					if item.is_change_img then
						keyBtn.background = string.format("Texture/Aries/Creator/keepwork/MiniKey/%s_94X88_32bits.png;0 0 94 88", item.ctrl_name)
					end
					_guihelper.SetUIColor(keyBtn, self.colors[3].normal);
				else
					keyBtn.background = item.img
					_guihelper.SetUIColor(keyBtn, self.colors[item.colorid or 1].normal);
				end
			elseif item.name ~= "Ctrl" then
				if(is_press) then
					_guihelper.SetUIColor(item.mask_object, self.colors[1].pressed)
					_guihelper.SetUIColor(keyBtn, self.colors[1].pressed)
				else
					_guihelper.SetUIColor(item.mask_object, self.colors[1].normal)
					_guihelper.SetUIColor(keyBtn, self.colors[1].normal)
				end
			end
		end
	end
end

function TouchMiniKeyboard:StopCtrlDrawAnim()
	if self.circle_tween_x and self.circle_tween_y then
		self.circle_tween_x:Stop()
		self.circle_tween_y:Stop()

		self.circle_tween_x = nil
		self.circle_tween_y = nil

		self:ChangeCtrlPressState(false)

		if self.anim_circle_object then
			self.anim_circle_object.visible = false
		end
	end

	if self.circle_tween_timer then
		self.circle_tween_timer:Change()
		self.circle_tween_timer = nil
	end

	if self.circle_alpha_timer then
		self.circle_alpha_timer:Change()
		self.circle_alpha_timer = nil
	end
end

function TouchMiniKeyboard:ShowCtrlDrawAnim()
	if self.circle_tween_x then
		return
	end

	if self.circle_tween_timer then
		self.circle_tween_timer:Change()
		self.circle_tween_timer = nil
	end

	if self.circle_tween_timer == nil then
		self.circle_tween_timer = commonlib.Timer:new({callbackFunc = function(timer)
			GameLogic.AddBBS("Macro", L"请根据提示滑动到目标点", 5000, "255 0 0");
			local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")
			Macros.voice("请根据提示滑动到目标点")
		end})
		self.circle_tween_timer:Change(3000);
	end

	
	self:ChangeCtrlPressState(true)

	local start_pos = {}
	local end_pos = {}

	local item_width
	for row = 1, #self.keylayout do
		for _, item in ipairs(self.keylayout[row]) do
			if item.circle_object and item.circle_object.visible then
				if item.name == "Ctrl" then
					start_pos.x = item.pos_x
					start_pos.y = item.pos_y
				else
					end_pos.x = item.pos_x
					end_pos.y = item.pos_y
				end

				if item_width == nil then
					item_width = item.width
				end
			end
		end
	end

	if start_pos.x == nil or start_pos.y == nil then
		return
	end

	if nil == self.anim_circle_object then
		
		local off_size = 10
		local width = item_width - 10
		local height = item_width - 10

		local circle = ParaUI.CreateUIObject("button","anim_circle", "_lt", start_pos.x, start_pos.x, width, height);
		_guihelper.SetUIColor(circle, self.colors[1].normal);
		circle.enabled = false;
		
		circle.background = "Texture/Aries/Common/ThemeTeen/circle_32bits.png"
		self.anim_circle_object = circle
		local _parent = self:GetUIControl()
		_parent:AddChild(circle)
	end

	self.anim_circle_object.visible = true

    self.circle_tween_x=CommonCtrl.Tween:new{
			obj=self.anim_circle_object,
			prop="x",
			begin=start_pos.x,
			change=end_pos.x - start_pos.x,
			duration=1.5}

	self.circle_tween_x.func=CommonCtrl.TweenEquations.easeNone;
	self.circle_tween_x:Start();

    self.circle_tween_y=CommonCtrl.Tween:new{
		obj=self.anim_circle_object,
		prop="y",
		begin=start_pos.y,
		change=end_pos.y - start_pos.y,
		duration=1.5,
		MotionFinish = function()
			self.circle_tween_x:Start()
			self.circle_tween_y:Start()
		end
	}

	self.circle_tween_y.func=CommonCtrl.TweenEquations.easeNone;
	self.circle_tween_y:Start();
end

function TouchMiniKeyboard:ShowShiftDrawAnim()
	if self.circle_tween_x then
		return
	end

	if self.circle_tween_timer then
		self.circle_tween_timer:Change()
		self.circle_tween_timer = nil
	end

	if self.circle_tween_timer == nil then
		self.circle_tween_timer = commonlib.Timer:new({callbackFunc = function(timer)
			local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")
			Macros.voice("请根据提示滑动到目标点,并按住目标点不放")
			GameLogic.AddBBS("Macro", L"请根据提示滑动到目标点,并按住目标点不放", 5000, "255 0 0");
		end})
		self.circle_tween_timer:Change(3000);
	end
	

	local start_pos = {}
	local end_pos = {}

	local end_object = nil
	local item_width
	for row = 1, #self.keylayout do
		for _, item in ipairs(self.keylayout[row]) do
			if item.circle_object and item.circle_object.visible then
				if item.name == "Shift" then
					start_pos.x = item.pos_x
					start_pos.y = item.pos_y
				else
					end_pos.x = item.pos_x
					end_pos.y = item.pos_y

					end_object = item.circle_object
				end

				if item_width == nil then
					item_width = item.width
				end
			end
		end
	end

	if start_pos.x == nil or start_pos.y == nil then
		return
	end

	if nil == self.anim_circle_object then
		
		local off_size = 10
		local width = item_width - 10
		local height = item_width - 10

		local circle = ParaUI.CreateUIObject("button","anim_circle", "_lt", start_pos.x, start_pos.x, width, height);
		_guihelper.SetUIColor(circle, self.colors[1].normal);
		circle.enabled = false;
		
		circle.background = "Texture/Aries/Common/ThemeTeen/circle_32bits.png"
		self.anim_circle_object = circle
		local _parent = self:GetUIControl()
		_parent:AddChild(circle)
	end

	self.anim_circle_object.visible = true

    self.circle_tween_x=CommonCtrl.Tween:new{
			obj=self.anim_circle_object,
			prop="x",
			begin=start_pos.x,
			change=end_pos.x - start_pos.x,
			duration=1.5}

	self.circle_tween_x.func=CommonCtrl.TweenEquations.easeNone;
	self.circle_tween_x:Start();

    self.circle_tween_y=CommonCtrl.Tween:new{
		obj=self.anim_circle_object,
		prop="y",
		begin=start_pos.y,
		change=end_pos.y - start_pos.y,
		duration=1.5,
		MotionFinish = function()
			self.circle_tween_x:Start()
			self.circle_tween_y:Start()
		end
	}

	self.circle_tween_y.func=CommonCtrl.TweenEquations.easeNone;
	self.circle_tween_y:Start();

	if self.circle_alpha_timer then
		self.circle_alpha_timer:Change()
		self.circle_alpha_timer = nil
	end
	if end_object then
		local alpha = 255
		local change_alpha = 15
		self.circle_alpha_timer = commonlib.Timer:new({callbackFunc = function(timer)
			if alpha >= 250 then
				change_alpha = -15
			elseif alpha <= 20 then
				change_alpha = 15
			end
			
			alpha = alpha + change_alpha
			-- print("ioooooooooo", change_alpha, alpha)
			_guihelper.SetColorMask(end_object, format("255 255 255 %d",alpha))
		end})
		self.circle_alpha_timer:Change(0, 33);
	end
end

