--[[
Title: A Icon Button To toggle virtual keyboard
Author(s): LiXizhi
Date: 2018/3/22
Desc: This is singleton
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchVirtualKeyboardIcon.lua");
local TouchVirtualKeyboardIcon = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchVirtualKeyboardIcon");
TouchVirtualKeyboardIcon.ShowSingleton(true);

TouchVirtualKeyboardIcon.GetSingleton():ShowKeyboard(true)


local btn = TouchVirtualKeyboardIcon:new():Init("TouchVirtualKeyboardIcon")
btn:SetTransparency(0.5);
btn:Show(true);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchSession.lua");
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local TouchSession = commonlib.gettable("MyCompany.Aries.Game.Common.TouchSession")
local Screen = commonlib.gettable("System.Windows.Screen");

local TouchVirtualKeyboardIcon = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.GUI.TouchVirtualKeyboardIcon"));
TouchVirtualKeyboardIcon:Property("Name", "TouchVirtualKeyboardIcon");

function TouchVirtualKeyboardIcon:ctor()
	self.alignment = "_lt";
	self.zorder = 1000;
	self.transparency = 1;
	self.color = {normal="#ffffff"}
	self.text = "KB";
	self.default_transparency = 0.5;
end

local s_instance;
function TouchVirtualKeyboardIcon.GetSingleton()
	if(not s_instance) then
		s_instance = TouchVirtualKeyboardIcon:new():Init("TouchVirtualKeyboardIcon");
		s_instance:SetTransparency(0.5);
	end
	return s_instance;
end

-- static function: this useful for checking if keyboard is loaded or not
function TouchVirtualKeyboardIcon.IsSingletonVisible()
	if(s_instance) then
		return s_instance:isVisible()
	else
		return false;
	end
end

-- try show the singleton
function TouchVirtualKeyboardIcon.ShowSingleton(bSHow)
	NPL.load("(gl)script/ide/timer.lua");
	local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
		if(Screen:GetWidth() > 0) then
			timer:Change();
			TouchVirtualKeyboardIcon.GetSingleton():Show(bSHow);

			Screen:Connect("sizeChanged", function(width, height)
				LOG.std(nil, "info", "TouchVirtualKeyboardIcon", "adjust position %d, %d", width, height);
				local self = TouchVirtualKeyboardIcon.GetSingleton();
				self:SetPosition();
				self:GetKeyBoard():SetPosition(math.floor(self.left+self.width + self.width * 0.2));
			end);
		end
	end})
	mytimer:Change(100,300);
end

-- all input can be nil. 
-- @param name: parent name. it should be a unique name
-- @param left, top: left, top position where to show. default to left, top
-- @param width: if width is not specified, it will use all the screen space left from x. 
function TouchVirtualKeyboardIcon:Init(name, left, top, width)
	self.name = name or self.name;
	self:SetPosition(left, top, width);
	return self;
end

-- @bShow: if nil, it will toggle show and hide. 
function TouchVirtualKeyboardIcon:Show(bShow)
	local _parent = self:GetUIControl();
	if(bShow  == nil) then
		bShow = not _parent.visible;
	end
	self.bIsVisible = bShow;
	_parent.visible = bShow;
end

function TouchVirtualKeyboardIcon:isVisible()
	return self.bIsVisible;
end

function TouchVirtualKeyboardIcon:Destroy()
	TouchVirtualKeyboardIcon._super.Destroy(self);
	ParaUI.Destroy(self.id or self.name);
	self.id = nil;
end

-- @param alpha: 0-1 
function TouchVirtualKeyboardIcon:SetTransparency(alpha)
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
function TouchVirtualKeyboardIcon:SetPosition(left, top, width)
	width = width or math.floor(Screen:GetHeight() / 12)
	self.width = width;
	self.left = math.floor(left or width * 0.2);
	self.top = math.floor(top or width*1.5);
	self.height = width;

	local bLastVisible = self:isVisible();
	self:CreateWindow();
	if(bLastVisible) then
		self:Show(true);
	end
end


function TouchVirtualKeyboardIcon:GetButtonWidth()
	return self.button_width;
end


function TouchVirtualKeyboardIcon:GetUIControl()
	local _parent = ParaUI.GetUIObject(self.id or self.name);
	
	if(not _parent:IsValid()) then
		_parent = ParaUI.CreateUIObject("container",self.name, self.alignment,self.left,self.top,self.width,self.height);
		_parent.background = "Texture/whitedot.png";
		_guihelper.SetUIColor(_parent, self.color.normal);
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

-- simulate the touch event
function TouchVirtualKeyboardIcon:OnMouseDown()
	local touch = {type="WM_POINTERDOWN", x=mouse_x, y=mouse_y, id=-1, time=0};
	self:OnTouch(touch);
end

-- simulate the touch event
function TouchVirtualKeyboardIcon:OnMouseUp()
	local touch = {type="WM_POINTERUP", x=mouse_x, y=mouse_y, id=-1, time=0};
	self:OnTouch(touch);
end

-- simulate the touch event
function TouchVirtualKeyboardIcon:OnMouseMove()
	local touch = {type="WM_POINTERUPDATE", x=mouse_x, y=mouse_y, id=-1, time=0};
	self:OnTouch(touch);
end

function TouchVirtualKeyboardIcon:ShowKeyboard(bShow)
	local keyboard = self:GetKeyBoard();
	self.isShowing = bShow;
	if(self.isShowing) then
		if(not self:isVisible()) then
			self.hideIconWhenClosed = true;
			self:Show(true);
		end
		keyboard:SetTransparency(1);
		self:SetTransparency(1);
		self:SetText(L"关闭");
		keyboard:Show(true);
		local obj = Keyboard:GetKeyFocus();
		if(obj) then
			local x, y, width, height = obj:GetAbsPosition()
			if( (y + height/2) < Screen:GetHeight()/2) then
				keyboard:SetTop(math.min(y + height + 10, math.floor(Screen:GetHeight()/2)));
			else
				keyboard:SetTop(keyboard.button_height);
			end
			keyboard:SetFocusedMode(true);
		else
			keyboard:SetTop(keyboard.button_height);
			keyboard:SetFocusedMode(false);
		end
	else
		self:SetText(self.text);
		self:SetTransparency(self.default_transparency);
		keyboard:Show(false);

		if(self.hideIconWhenClosed) then
			self:Show(false);
		end
	end
end

function TouchVirtualKeyboardIcon:OnTouch(touch)
	-- handle the touch
	local touch_session = TouchSession.GetTouchSession(touch);
	if(touch.type == "WM_POINTERDOWN") then
		local keyboard = self:GetKeyBoard();
		-- toggle show
		self:ShowKeyboard(not keyboard:IsVisible());

	elseif(touch.type == "WM_POINTERUPDATE") then
		
	elseif(touch.type == "WM_POINTERUP") then
		local keyboard = self:GetKeyBoard();
		if(self.isShowing) then
			if(keyboard:IsFocusedMode()) then
				keyboard:SetTransparency(0.85, true);
			else
				keyboard:SetTransparency(self.default_transparency, true);	
			end
		end
	end
end


function TouchVirtualKeyboardIcon:GetKeyBoard()
	if(not self.keyboard) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchVirtualKeyboard.lua");
		local TouchVirtualKeyboard = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchVirtualKeyboard");
		self.keyboard = TouchVirtualKeyboard:new():Init("TouchVirtualKeyboard", math.floor(self.left+self.width + self.width * 0.2));
		self.keyboard:SetTransparency(self.default_transparency);
		self.keyboard:Connect("hidden", self, function()
			self:SetText(self.text);
			self:SetTransparency(self.default_transparency);
		end)
	end
	return self.keyboard;
end

function TouchVirtualKeyboardIcon:SetText(text)
	local keyBtn = self:GetUIControl():GetChild("text");
	keyBtn.text = text or self.text;
end

-- private: calculate and create layout.  columns(16) * rows(5)
function TouchVirtualKeyboardIcon:CreateWindow()
	local _parent = self:GetUIControl();
	_parent:RemoveAll();
	_parent.visible = false;

	-- text
	local keyBtn = ParaUI.CreateUIObject("button","text", "_lt", 0,0,self.width,self.height);
	keyBtn.background = "";
	keyBtn.text = self.text;
	keyBtn.enabled = false;
	_guihelper.SetButtonFontColor(keyBtn, "#000000");
	_parent:AddChild(keyBtn);
end


