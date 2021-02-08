--[[
Title: Touch Virtual Keyboard
Author(s): LiXizhi
Date: 2018/3/20
Desc: A programmer oriented virtual keyboard for use on touch device like pad or phone. 
The operating system IME is disabled when this virtual keyboard is shown. 
- drag commbo key: drag from first key to second key to perform a combo key like `Shift+S`, `Fn+1`

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchVirtualKeyboard.lua");
local TouchVirtualKeyboard = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchVirtualKeyboard");
local kb = TouchVirtualKeyboard:new():Init("TouchVirtualKeyboard");
kb:SetTransparency(0.5)
kb:Show(true);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchSession.lua");
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local TouchSession = commonlib.gettable("MyCompany.Aries.Game.Common.TouchSession")
local Screen = commonlib.gettable("System.Windows.Screen");

local TouchVirtualKeyboard = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.GUI.TouchVirtualKeyboard"));
TouchVirtualKeyboard:Property("Name", "TouchVirtualKeyboard");

TouchVirtualKeyboard.name = "default_TouchVirtualKeyboard";
TouchVirtualKeyboard:Signal("hidden")

function TouchVirtualKeyboard:ctor()
	self.alignment = "_lt";
	self.zorder = 1000;
	self.alphaAnimSpeed = 10/256;
	self.keylayout = {
		-- row 1
		{
			{name="Esc", col=1, colorid=2, click_to_close=true, vKey = DIK_SCANCODE.DIK_ESCAPE},
			{name="`", char="`",col=1, name2 = "~", char2 = "~", vKey = DIK_SCANCODE.DIK_GRAVE},
			{name="1", char="1",col=1, name2 = "!", char2 = "!", vKey = DIK_SCANCODE.DIK_1, fn={name="F1", vKey = DIK_SCANCODE.DIK_F1, click_to_close = true}},
			{name="2", char="2",col=1, name2 = "@", char2 = "@", vKey = DIK_SCANCODE.DIK_2, fn={name="F2", vKey = DIK_SCANCODE.DIK_F2}},
			{name="3", char="3",col=1, name2 = "#", char2 = "#", vKey = DIK_SCANCODE.DIK_3, fn={name="F3", vKey = DIK_SCANCODE.DIK_F3, click_to_close = true}},
			{name="4", char="4",col=1, name2 = "$", char2 = "$", vKey = DIK_SCANCODE.DIK_4, fn={name="F4", vKey = DIK_SCANCODE.DIK_F4, click_to_close = true}},
			{name="5", char="5",col=1, name2 = "%", char2 = "%", vKey = DIK_SCANCODE.DIK_5, fn={name="F5", vKey = DIK_SCANCODE.DIK_F5}},
			{name="6", char="6",col=1, name2 = "^", char2 = "^", vKey = DIK_SCANCODE.DIK_6, fn={name="F6", vKey = DIK_SCANCODE.DIK_F6}},
			{name="7", char="7",col=1, name2 = "&", char2 = "&", vKey = DIK_SCANCODE.DIK_7, fn={name="F7", vKey = DIK_SCANCODE.DIK_F7}},
			{name="8", char="8",col=1, name2 = "*", char2 = "*", vKey = DIK_SCANCODE.DIK_8, fn={name="F8", vKey = DIK_SCANCODE.DIK_F8}},
			{name="9", char="9",col=1, name2 = "(", char2 = "(", vKey = DIK_SCANCODE.DIK_9, fn={name="F9", vKey = DIK_SCANCODE.DIK_F9, click_to_close = true}},
			{name="0", char="0",col=1, name2 = ")", char2 = ")", vKey = DIK_SCANCODE.DIK_0, fn={name="F10", vKey = DIK_SCANCODE.DIK_F10}},
			{name="-", char="-",col=1, name2 = "_", char2 = "_", vKey = DIK_SCANCODE.DIK_MINUS, fn={name="F11", vKey = DIK_SCANCODE.DIK_F11, click_to_close = true}},
			{name="=", char="=",col=1, name2 = "+", char2 = "+", vKey = DIK_SCANCODE.DIK_EQUALS, fn={name="F12", vKey = DIK_SCANCODE.DIK_F12, click_to_close = true}},
			{name="Backspace", col=2, colorid=2, vKey = DIK_SCANCODE.DIK_BACKSPACE},
		},
		{
			{col=1, },
			{name="Tab", col=1.5, colorid=2, vKey = DIK_SCANCODE.DIK_TAB},
			{name="Q", char="q",char2="Q",col=1, vKey = DIK_SCANCODE.DIK_Q},
			{name="W", char="w",char2="W",col=1, vKey = DIK_SCANCODE.DIK_W},
			{name="E", char="e",char2="E",col=1, vKey = DIK_SCANCODE.DIK_E},
			{name="R", char="r",char2="R",col=1, vKey = DIK_SCANCODE.DIK_R},
			{name="T", char="t",char2="T",col=1, vKey = DIK_SCANCODE.DIK_T},
			{name="Y", char="y",char2="Y",col=1, vKey = DIK_SCANCODE.DIK_Y},
			{name="U", char="u",char2="U",col=1, vKey = DIK_SCANCODE.DIK_U},
			{name="I", char="i",char2="I",col=1, vKey = DIK_SCANCODE.DIK_I},
			{name="O", char="o",char2="O",col=1, vKey = DIK_SCANCODE.DIK_O},
			{name="P", char="p",char2="P",col=1, vKey = DIK_SCANCODE.DIK_P},
			{name="[", char="[",char2="{",col=1, name2 = "{", vKey = DIK_SCANCODE.DIK_LBRACKET},
			{name="]", char="]",char2="}",col=1, name2 = "}", vKey = DIK_SCANCODE.DIK_RBRACKET},
			{name="\\",char="\\", col=1.5, name2 = "|", vKey = DIK_SCANCODE.DIK_BACKSLASH},
		},
		{
			{col=1, },
			{name="CapsLock", col=2, colorid=2, vKey = DIK_SCANCODE.DIK_CAPSLOCK},
			{name="A", char="a",char2="A",col=1, vKey = DIK_SCANCODE.DIK_A},
			{name="S", char="s",char2="S",col=1, vKey = DIK_SCANCODE.DIK_S},
			{name="D", char="d",char2="D",col=1, vKey = DIK_SCANCODE.DIK_D},
			{name="F", char="f",char2="F",col=1, vKey = DIK_SCANCODE.DIK_F},
			{name="G", char="g",char2="G",col=1, vKey = DIK_SCANCODE.DIK_G},
			{name="H", char="h",char2="H",col=1, vKey = DIK_SCANCODE.DIK_H},
			{name="J", char="j",char2="J",col=1, vKey = DIK_SCANCODE.DIK_J},
			{name="K", char="k",char2="K",col=1, vKey = DIK_SCANCODE.DIK_K},
			{name="L", char="l",char2="L",col=1, vKey = DIK_SCANCODE.DIK_L},
			{name=";", char=";",char2=":",col=1, name2 = ":", vKey = DIK_SCANCODE.DIK_SEMICOLON},
			{name="'", char="'",char2="\"",col=1, name2 = "\"", vKey = DIK_SCANCODE.DIK_APOSTROPHE},
			{name="Enter", char="\r",char2="\r", col=2, colorid=2, vKey = DIK_SCANCODE.DIK_RETURN},
		},
		{
			{col=1, },
			{name="Shift", combo=true, dragcombo=true, col=2.5, colorid=2, vKey = DIK_SCANCODE.DIK_LSHIFT},
			{name="Z", char="z",char2="Z",col=1, vKey = DIK_SCANCODE.DIK_Z},
			{name="X", char="x",char2="X",col=1, vKey = DIK_SCANCODE.DIK_X},
			{name="C", char="c",char2="C",col=1, vKey = DIK_SCANCODE.DIK_C},
			{name="V", char="v",char2="V",col=1, vKey = DIK_SCANCODE.DIK_V},
			{name="B", char="b",char2="B",col=1, vKey = DIK_SCANCODE.DIK_B},
			{name="N", char="n",char2="N",col=1, vKey = DIK_SCANCODE.DIK_N},
			{name="M", char="m",char2="M",col=1, vKey = DIK_SCANCODE.DIK_M},
			{name=",", char=",",char2="<",col=1, name2 = "<", vKey = DIK_SCANCODE.DIK_COMMA},
			{name=".", char=".",char2=">",col=1, name2 = ">", vKey = DIK_SCANCODE.DIK_PERIOD},
			{name="/", char="/",char2="?",col=1, name2 = "?", colorid=3, vKey = DIK_SCANCODE.DIK_SLASH},
			{col=0.5},
			{name="Up", col=1, colorid=2, vKey = DIK_SCANCODE.DIK_UP},
			{name="End", col=1, colorid=2, vKey = DIK_SCANCODE.DIK_END},
		},
		{
			{name="Fn", combo=true, dragcombo=true, col=1, colorid=3},
			{name="Ctrl", combo=true, col=1.5, colorid=2, vKey = DIK_SCANCODE.DIK_LCONTROL},
			{name="Alt", combo=true, col=1.5, colorid=2, vKey = DIK_SCANCODE.DIK_LMENU},
			{name="Space", char=" ", char2=" ",col=9, vKey = DIK_SCANCODE.DIK_SPACE},
			{name="Left", col=1, colorid=2, vKey = DIK_SCANCODE.DIK_LEFT},
			{name="Down", col=1, colorid=2, vKey = DIK_SCANCODE.DIK_DOWN},
			{name="Right", col=1, colorid=2, vKey = DIK_SCANCODE.DIK_RIGHT},
		},
	};

	-- normalBtn, comboBtn, frequentBtn
	self.colors = { 
		{normal="#ffffff", pressed="#888888"}, 
		{normal="#cccccc", pressed="#333333"}, 
		{normal="#8888ff", pressed="#3333cc"}
	};
	self.finger_size = 10;
	self.transparency = 1;
	-- when key is up
	self.defaultTransparency = 0.7;
	-- when key is down
	self.touchTransparency = 0.9;
end

-- all input can be nil. 
-- @param name: parent name. it should be a unique name
-- @param left: default to one button width
-- @param top: left, top position where to show. 
-- @param width: if width is not specified, it will use all the screen space left from x. 
function TouchVirtualKeyboard:Init(name, left, top, width)
	self.name = name or self.name;
	self:SetPosition(left, top, width);
	return self;
end

-- @bShow: if nil, it will toggle show and hide. 
function TouchVirtualKeyboard:Show(bShow)
	local _parent = self:GetUIControl();
	if(bShow  == nil) then
		bShow = not _parent.visible;
	end
	self.bIsVisible = bShow;
	_parent.visible = bShow;
	
	if(bShow) then
		Keyboard:EnableIME(false)
	else
		Keyboard:EnableIME(true)
		self:hidden(); -- signal
		self:ClearAllKeyDown();
	end
end

function TouchVirtualKeyboard:isVisible()
	return self.bIsVisible;
end

function TouchVirtualKeyboard:Destroy()
	TouchVirtualKeyboard._super.Destroy(self);
	ParaUI.Destroy(self.id or self.name);
	self.id = nil;
end

function TouchVirtualKeyboard:SetFocusedMode(bFocused)
	self.focused_mode = bFocused;
--	local obj = self:GetUIControl();
--	if(bFocused) then
--		obj.background = "Texture/whitedot.png";
--	else
--		obj.background = "";
--	end
end

function TouchVirtualKeyboard:IsFocusedMode()
	return self.focused_mode;
end

-- TODO: show the char big in top of the keyboard
function TouchVirtualKeyboard:SetText(text)
	if(text ~= self.text) then
		self.text = text;	
	end
end

-- TODO: show the char big in top of the keyboard
function TouchVirtualKeyboard:GetText()
	return self.text;
end

-- TODO: show the current text in IME focus control
function TouchVirtualKeyboard:UpdateFromInputFocus()
	
end

-- @param alpha: 0-1 
function TouchVirtualKeyboard:SetTransparency(alpha, bAnimate)
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
			self.timer:Change(0, 33);
		else
			if(self.timer) then
				self.timer:Change();
			end
			self:SetTransparencyImp(alpha)
		end
	end
	return self;
end

function TouchVirtualKeyboard:SetTransparencyImp(alpha)
	self.transparency = alpha;
	local _parent = self:GetUIControl();
	_guihelper.SetColorMask(_parent, format("255 255 255 %d",math.floor(alpha * 255)))
	_parent:ApplyAnim();
end

function TouchVirtualKeyboard:GetButtonWidth()
	return self.button_width;
end


-- @param left, top: left, top position where to show. 
-- @param width: if width is not specified, it will use all the screen space left from x. 
function TouchVirtualKeyboard:SetPosition(left, top, width)
	self.left = left or math.floor(Screen:GetWidth()/18);
	width = width or math.floor((Screen:GetWidth() - self.left)*16/17);
	self.width = width;
	self.button_width = math.floor(self.width / 16);
	-- button_height is same as self.button_width, but will not be more than half of the screen height. 
	self.button_height = math.min(math.floor(self.button_width * 1.0), math.floor((Screen:GetHeight() * 0.5 *5/6) / 5));
	self.height = self.button_height * 5;

	self.top = top or self.button_height;

	-- 50% padding between keys
	self.key_margin = math.floor(math.min(self.finger_size, self.button_width*0.15) * 0.5); 

	local bLastVisible = self:isVisible();
	self:CreateWindow();
	if(bLastVisible) then
		self:Show(true);
	end
end

function TouchVirtualKeyboard:IsVisible()
	return self:GetUIControl().visible;
end

-- set top position. this is useful to avoid showing directly on top of the input focus. 
function TouchVirtualKeyboard:SetTop(top)
	self.top = top;
	self:GetUIControl().top = self.top;
end

function TouchVirtualKeyboard:GetUIControl()
	local _parent = ParaUI.GetUIObject(self.id or self.name);
	
	if(not _parent:IsValid()) then
		_parent = ParaUI.CreateUIObject("container",self.name, self.alignment,self.left,self.top,self.width,self.height);
		_parent.background = "Texture/whitedot.png";
		_guihelper.SetUIColor(_parent, "#000000");
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
function TouchVirtualKeyboard:OnMouseDown()
	local touch = {type="WM_POINTERDOWN", x=mouse_x, y=mouse_y, id=-1, time=0};
	self:OnTouch(touch);
end

-- simulate the touch event
function TouchVirtualKeyboard:OnMouseUp()
	local touch = {type="WM_POINTERUP", x=mouse_x, y=mouse_y, id=-1, time=0};
	self:OnTouch(touch);
end

-- simulate the touch event
function TouchVirtualKeyboard:OnMouseMove()
	local touch = {type="WM_POINTERUPDATE", x=mouse_x, y=mouse_y, id=-1, time=0};
	self:OnTouch(touch);
end

-- handleTouchEvent
function TouchVirtualKeyboard:OnTouch(touch)
	-- handle the touch
	local touch_session = TouchSession.GetTouchSession(touch);

	-- let us track it with an item. 
	
	local btnItem = self:GetButtonItem(touch.x, touch.y);
	if(touch.type == "WM_POINTERDOWN") then
		if(btnItem) then
			touch_session:SetField("keydownBtn", btnItem);
			
			self:SetKeyState(btnItem, true);
		end
	elseif(touch.type == "WM_POINTERUP") then
		local keydownBtn = touch_session:GetField("keydownBtn");
		if(keydownBtn) then
			if(btnItem and btnItem~=keydownBtn and keydownBtn.dragcombo) then
				self:SetKeyState(btnItem, true);
				self:SetKeyState(btnItem, false);
			end
			self:SetKeyState(keydownBtn, false);
		end
	end
end

function TouchVirtualKeyboard:IsCapital()
	return self.keylayout[4][2].isKeyDown;
end

function TouchVirtualKeyboard:GetChar(btnItem)
	if(btnItem.char) then
		return self:IsCapital() and btnItem.char2 or btnItem.char;
	end
end

function TouchVirtualKeyboard:SetKeyState(btnItem, isDown)
	if(isDown and self:GetChar(btnItem) and Keyboard:HasKeyFocus()) then
		-- it is very important that SendInputMethodEvent is called before key down event is sent. otherwise ctrl.text is not updated. 
		local ch = self:GetChar(btnItem);
		if(ch) then
			Keyboard:SendInputMethodEvent(ch);
		end	
	end

	local parent = self:GetUIControl();
	local keyBtn = parent:GetChild(btnItem.name);
	btnItem.isKeyDown = isDown;
	if(isDown) then
		-- key down event
		_guihelper.SetUIColor(keyBtn, self.colors[btnItem.colorid or 1].pressed);
	else
		-- key up event
		_guihelper.SetUIColor(keyBtn, self.colors[btnItem.colorid or 1].normal);
	end

	if(btnItem.name == "Fn") then
		for row = 1, #self.keylayout do
			for _, item in ipairs(self.keylayout[row]) do
				if (item.fn) then
					local keyBtn = parent:GetChild(item.name);
					if(isDown) then
						keyBtn.text = self:GetItemDisplayText(item.fn);
						_guihelper.SetUIColor(keyBtn, self.colors[item.fn.colorid or btnItem.colorid or 2].normal);
					else
						keyBtn.text = self:GetItemDisplayText(item);
						_guihelper.SetUIColor(keyBtn, self.colors[item.colorid or 1].normal);
					end
				end
			end
		end
	end

	-- TODO: anim each letter to make it offset -self.button_height in y axis;
	if(btnItem.combo or true) then
		if(isDown) then
			self:SetTransparency(self.touchTransparency);
		else
			self:SetTransparency(self.defaultTransparency, true);
		end
	end

	if(btnItem.fn) then
		-- it would be a different key if Fn is pressed, like F1-F12
		if(self:IsFnKeyPressed()) then
			btnItem = btnItem.fn;
		end
	end

	self:SendRawKeyEvent(btnItem, isDown);

	if(btnItem.click_to_close and not isDown) then
		self:Show(false);
	end
end

function TouchVirtualKeyboard:IsFnKeyPressed()
	return self.keylayout[5][1].isKeyDown;
end

function TouchVirtualKeyboard:SendRawKeyEvent(btnItem, isDown)
	if(btnItem.vKey) then
		Keyboard:SendKeyEvent(isDown and "keyDownEvent" or "keyUpEvent", btnItem.vKey);
	end
end

function TouchVirtualKeyboard:GetItemDisplayText(item, bFnPressed, bShiftPressed)
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
function TouchVirtualKeyboard:GetButtonItem(x, y)
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

-- clear all key down on exit
function TouchVirtualKeyboard:ClearAllKeyDown()
	for row = 1, #self.keylayout do
		for _, item in ipairs(self.keylayout[row]) do
			if (item.isKeyDown) then
				item.isKeyDown = false;
			end
		end
	end
end

-- private: calculate and create layout.  columns(16) * rows(5)
function TouchVirtualKeyboard:CreateWindow()
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
				item.right = item.left+ item.col*self.button_width;
				item.bottom = item.top + self.button_height;

				local keyBtn = ParaUI.CreateUIObject("button",item.name, "_lt", left_col*self.button_width + btn_margin, (row-1)*self.button_height+btn_margin, item.col*self.button_width-btn_margin*2, self.button_height-btn_margin*2);
				keyBtn.background = "Texture/whitedot.png";
				keyBtn.enabled = false;
				keyBtn.text = self:GetItemDisplayText(item);
				_guihelper.SetButtonFontColor(keyBtn, "#000000");
				_guihelper.SetUIColor(keyBtn, self.colors[item.colorid or 1].normal);
				_parent:AddChild(keyBtn);
			end
			left_col = left_col + item.col;
		end
	end
end


