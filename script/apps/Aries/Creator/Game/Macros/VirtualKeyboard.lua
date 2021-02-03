--[[
Title: Virtual Keyboard
Author(s): LiXizhi
Date: 2021/1/18
Desc: A programmer oriented virtual keyboard 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/VirtualKeyboard.lua");
local VirtualKeyboard = commonlib.gettable("MyCompany.Aries.Game.GUI.VirtualKeyboard");
local kb = VirtualKeyboard:new():Init("MacroVirtualKeyboard");
kb:SetTransparency(0.5)
kb:Show(true);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local Screen = commonlib.gettable("System.Windows.Screen");

local VirtualKeyboard = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.GUI.VirtualKeyboard"));
VirtualKeyboard:Property("Name", "VirtualKeyboard");
VirtualKeyboard.name = "default_MacroVirtualKeyboard";

function VirtualKeyboard:ctor()
	self.alignment = "_lt";
	self.zorder = 1000;
	self.alphaAnimSpeed = 10/256;
	self.keylayout = {
		-- row 1
		{
			{name="Esc", col=1, colorid=2, vKey = DIK_SCANCODE.DIK_ESCAPE},
			{col=1, },
			{name="F1", char="F1",col=1, colorid=2, vKey = DIK_SCANCODE.DIK_F1, },
			{name="F2", char="F2",col=1, colorid=2, vKey = DIK_SCANCODE.DIK_F2, },
			{name="F3", char="F3",col=1, colorid=2, vKey = DIK_SCANCODE.DIK_F3, },
			{name="F4", char="F4",col=1, colorid=2, vKey = DIK_SCANCODE.DIK_F4, },
			{col=0.5, },
			{name="F5", char="F5",col=1, colorid=2, vKey = DIK_SCANCODE.DIK_F5, },
			{name="F6", char="F6",col=1, colorid=2, vKey = DIK_SCANCODE.DIK_F6, },
			{name="F7", char="F7",col=1, colorid=2, vKey = DIK_SCANCODE.DIK_F7, },
			{name="F8", char="F8",col=1, colorid=2, vKey = DIK_SCANCODE.DIK_F8, },
			{col=0.5, },
			{name="F9", char="F9",  col=1, colorid=2, vKey = DIK_SCANCODE.DIK_F9, },
			{name="F10", char="F10",col=1, colorid=2, vKey = DIK_SCANCODE.DIK_F10, },
			{name="F11", char="F11",col=1, colorid=2, vKey = DIK_SCANCODE.DIK_F11, },
			{name="F12", char="F12",col=1, colorid=2, vKey = DIK_SCANCODE.DIK_F12, },
			{name="Ins", col=1, colorid=2, vKey = DIK_SCANCODE.DIK_INSERT},
		},
		{
			{name="`", char="`",col=1, name2 = "~", char2 = "~", vKey = DIK_SCANCODE.DIK_GRAVE},
			{name="1", char="1",col=1, name2 = "!", char2 = "!", vKey = DIK_SCANCODE.DIK_1},
			{name="2", char="2",col=1, name2 = "@", char2 = "@", vKey = DIK_SCANCODE.DIK_2},
			{name="3", char="3",col=1, name2 = "#", char2 = "#", vKey = DIK_SCANCODE.DIK_3},
			{name="4", char="4",col=1, name2 = "$", char2 = "$", vKey = DIK_SCANCODE.DIK_4},
			{name="5", char="5",col=1, name2 = "%", char2 = "%", vKey = DIK_SCANCODE.DIK_5},
			{name="6", char="6",col=1, name2 = "^", char2 = "^", vKey = DIK_SCANCODE.DIK_6},
			{name="7", char="7",col=1, name2 = "&", char2 = "&", vKey = DIK_SCANCODE.DIK_7},
			{name="8", char="8",col=1, name2 = "*", char2 = "*", vKey = DIK_SCANCODE.DIK_8},
			{name="9", char="9",col=1, name2 = "(", char2 = "(", vKey = DIK_SCANCODE.DIK_9},
			{name="0", char="0",col=1, name2 = ")", char2 = ")", vKey = DIK_SCANCODE.DIK_0},
			{name="-", char="-",col=1, name2 = "_", char2 = "_", vKey = DIK_SCANCODE.DIK_MINUS},
			{name="=", char="=",col=1, name2 = "+", char2 = "+", vKey = DIK_SCANCODE.DIK_EQUALS},
			{name="Backspace", col=2, colorid=2, vKey = DIK_SCANCODE.DIK_BACKSPACE},
			{name="Del", col=1, colorid=2, vKey = DIK_SCANCODE.DIK_DELETE},
		},
		{
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
			{name="PgUp", col=1, colorid=2, vKey = DIK_SCANCODE.DIK_PAGE_UP},
		},
		{
			{name="CapsLock", col=2, colorid=2, vKey = DIK_SCANCODE.DIK_CAPITAL},
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
			{name="PgDn", col=1, colorid=2, vKey = DIK_SCANCODE.DIK_PAGE_DOWN},
		},
		{
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
			{name="/", char="/",char2="?",col=1, name2 = "?", vKey = DIK_SCANCODE.DIK_SLASH},
			{col=0.5, },
			{name="Home", col=1, colorid=2, vKey = DIK_SCANCODE.DIK_HOME},
			{name="↑", col=1, colorid=2, vKey = DIK_SCANCODE.DIK_UP},
			{name="End", col=1, colorid=2, vKey = DIK_SCANCODE.DIK_END},
		},
		{
			{name="CTRL", combo=true, col=1.5, colorid=2, vKey = DIK_SCANCODE.DIK_LCONTROL},
			{name="ALT", combo=true, col=1.5, colorid=2, vKey = DIK_SCANCODE.DIK_LMENU},
			{name="Space", char=" ", char2=" ",col=7, vKey = DIK_SCANCODE.DIK_SPACE},
			{name="Alt", combo=true, col=1.5, colorid=2, vKey = DIK_SCANCODE.DIK_RMENU},
			{name="Ctrl", combo=true, col=1.5, colorid=2, vKey = DIK_SCANCODE.DIK_RCONTROL},
			{name="←", col=1, colorid=2, vKey = DIK_SCANCODE.DIK_LEFT},
			{name="↓", col=1, colorid=2, vKey = DIK_SCANCODE.DIK_DOWN},
			{name="→", col=1, colorid=2, vKey = DIK_SCANCODE.DIK_RIGHT},
		},
	};

	-- normalBtn, comboBtn, frequentBtn
	self.colors = { 
		{normal="#ffffff", pressed="#f5c4bd"}, 
		{normal="#cccccc", pressed="#f5c4bd"}, 
		{normal="#8888ff", pressed="#f5c4bd"}
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
function VirtualKeyboard:Init(name, left, top, width)
	self.name = name or self.name;
	self:SetPosition(left, top, width);
	return self;
end

-- @bShow: if nil, it will toggle show and hide. 
function VirtualKeyboard:Show(bShow)
	local _parent = self:GetUIControl();
	if(bShow  == nil) then
		bShow = not _parent.visible;
	end
	self.bIsVisible = bShow;
	_parent.visible = bShow;
end

function VirtualKeyboard:isVisible()
	return self.bIsVisible;
end

function VirtualKeyboard:Destroy()
	VirtualKeyboard._super.Destroy(self);
	ParaUI.Destroy(self.id or self.name);
	self.id = nil;
end

function VirtualKeyboard:SetFocusedMode(bFocused)
	self.focused_mode = bFocused;
--	local obj = self:GetUIControl();
--	if(bFocused) then
--		obj.background = "Texture/whitedot.png";
--	else
--		obj.background = "";
--	end
end

function VirtualKeyboard:IsFocusedMode()
	return self.focused_mode;
end

-- TODO: show the char big in top of the keyboard
function VirtualKeyboard:SetText(text)
	if(text ~= self.text) then
		self.text = text;	
	end
end

-- TODO: show the char big in top of the keyboard
function VirtualKeyboard:GetText()
	return self.text;
end

-- TODO: show the current text in IME focus control
function VirtualKeyboard:UpdateFromInputFocus()
	
end

-- @param alpha: 0-1 
function VirtualKeyboard:SetTransparency(alpha, bAnimate)
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

function VirtualKeyboard:SetTransparencyImp(alpha)
	self.transparency = alpha;
	local _parent = self:GetUIControl();
	_guihelper.SetColorMask(_parent, format("255 255 255 %d",math.floor(alpha * 255)))
	_parent:ApplyAnim();
end

function VirtualKeyboard:GetButtonWidth()
	return self.button_width;
end


-- @param left, top: left, top position where to show. 
-- @param width: if width is not specified, it will use all the screen space left from x. 
function VirtualKeyboard:SetPosition(left, top, width)
	local maxWidth = math.floor(Screen:GetWidth()*16/17);
	width = math.min(maxWidth, width or maxWidth);
	if(not left) then
		left = math.floor((Screen:GetWidth() - width) / 2 + 0.5)
	end
	self.left = left;

	self.width = width;
	self.button_width = math.floor(self.width / 16);
	-- button_height is same as self.button_width, but will not be more than half of the screen height. 
	self.button_height = math.min(math.floor(self.button_width * 1.0), math.floor((Screen:GetHeight() * 0.5 *5/6) / 5));
	self.height = self.button_height * 6;

	self.top = top or self.button_height;

	if((self.top+self.height) > (Screen:GetHeight() - self.button_width)) then
		self.top = math.max(0, Screen:GetHeight() - self.button_width - self.height);
	end

	-- 50% padding between keys
	self.key_margin = math.floor(math.min(self.finger_size, self.button_width*0.15) * 0.5); 

	local bLastVisible = self:isVisible();
	self:CreateWindow();
	if(bLastVisible) then
		self:Show(true);
	end
end

function VirtualKeyboard:IsVisible()
	return self:GetUIControl().visible;
end

-- set top position. this is useful to avoid showing directly on top of the input focus. 
function VirtualKeyboard:SetTop(top)
	self.top = top;
	self:GetUIControl().top = self.top;
end

function VirtualKeyboard:GetUIControl()
	local _parent = ParaUI.GetUIObject(self.id or self.name);
	
	if(not _parent:IsValid()) then
		_parent = ParaUI.CreateUIObject("container",self.name, self.alignment,self.left,self.top,self.width,self.height);
		_parent.background = "Texture/whitedot.png";
		_guihelper.SetUIColor(_parent, "#000000");
		_parent:AttachToRoot();
		_parent.zorder = self.zorder;

		self.id = _parent.id;
	else
		_parent:Reposition(self.alignment,self.left,self.top,self.width,self.height);
	end
	return _parent;
end

function VirtualKeyboard:IsCapital()
	return self.keylayout[4][2].isKeyDown;
end

function VirtualKeyboard:GetChar(btnItem)
	if(btnItem.char) then
		return self:IsCapital() and btnItem.char2 or btnItem.char;
	end
end

function VirtualKeyboard:SetKeyState(btnItem, isDown)
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
end

function VirtualKeyboard:GetItemDisplayText(item, bFnPressed, bShiftPressed)
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
function VirtualKeyboard:GetButtonItem(x, y)
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
function VirtualKeyboard:ClearAllKeyDown()
	for row = 1, #self.keylayout do
		for _, item in ipairs(self.keylayout[row]) do
			if (item.isKeyDown) then
				item.isKeyDown = false;
				self:SetKeyState(item, false)
			end
		end
	end
end

-- private: calculate and create layout.  columns(16) * rows(5)
function VirtualKeyboard:CreateWindow()
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
				keyBtn.background = "Texture/Aries/Quest/keyboard_btn.png:10 10 10 16";
				keyBtn.enabled = false;
				keyBtn.text = self:GetItemDisplayText(item);
				_guihelper.SetButtonFontColor(keyBtn, "#000000");
				_guihelper.SetUIColor(keyBtn, self.colors[item.colorid or 1].normal);
				_guihelper.SetUIFontFormat(keyBtn, 257)
				if(not item.name2) then
					keyBtn:SetField("TextOffsetY", 8)
				end
				_parent:AddChild(keyBtn);
			end
			left_col = left_col + item.col;
		end
	end
end

function VirtualKeyboard:ShowButtons(button)
	if(button) then
		self:ClearAllKeyDown()
		local count = 0
		for text in button:gmatch("([%w_]+)") do
			local item = self:GetButtonByName(text)
			if(item) then
				self:SetKeyState(item, true)
				count = count + 1;
			end
		end
		return count;
	end
end

function VirtualKeyboard:GetButtonByKeyname(keyname)
	if(keyname and keyname~="") then
		for row = 1, #self.keylayout do
			for _, item in ipairs(self.keylayout[row]) do
				if (DIK_SCANCODE[keyname] == item.vKey) then
					return item;
				end
			end
		end
	end
end

function VirtualKeyboard:GetButtonByName(name)
	if(name == "ctrl") then
		name = "DIK_LCONTROL"
	elseif(name == "shift") then
		name = "DIK_LSHIFT"
	elseif(name == "alt") then
		name = "DIK_LMENU"
	end
	return self:GetButtonByKeyname(name)
end