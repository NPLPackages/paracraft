--[[
Title: ScreenRectSelector
Author(s): LiXizhi
Date: 2014/7/6
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/ScreenRectSelector.lua");
local ScreenRectSelector = commonlib.gettable("MyCompany.Aries.Game.GUI.Selectors.ScreenRectSelector");
ScreenRectSelector:new():Init(5,5,"left"):BeginSelect(function(mode, left, top, width, height)
	if(mode == "selected") then
		
	end
end)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/BaseSelector.lua");
local BaseSelector = commonlib.gettable("MyCompany.Aries.Game.GUI.BaseSelector");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local ScreenRectSelector = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.GUI.Selectors.BaseSelector"), commonlib.gettable("MyCompany.Aries.Game.GUI.Selectors.ScreenRectSelector"));

local page;

-- it will not select any rect if the mouse is not moving at least this distance. 
ScreenRectSelector.min_width = 5;
ScreenRectSelector.min_height = 5;
-- default to "left" to finish select when left button is released. 
ScreenRectSelector.check_mouse_button = "left";
ScreenRectSelector.ui_name = "_ScreenRectSelector_";

function ScreenRectSelector:ctor()
end

-- @param min_width, min_height: it will not select any rect if the mouse is not moving at least this distance. 
-- @param mouse_button: default to "left" to finish select when left button is released. 
function ScreenRectSelector:Init(min_width, min_height, mouse_button)
	self.min_width = min_width or self.min_width;
	self.min_height = min_height or self.min_height;
	self.check_mouse_button = mouse_button or self.check_mouse_button;
	return self;
end

-- @param callbackFunc: function(mode, left, top, width, height) end, 
-- where mode can be nil which means nothing is selected. or "canceled" or "selected"
function ScreenRectSelector:BeginSelect(callbackFunc)
	self.begin_x, self.begin_y = ParaUI.GetMousePosition();
	self.callbackFunc = callbackFunc;
	self.mytimer = self.mytimer or commonlib.Timer:new({callbackFunc = function(timer)
		self:OnUpdate(timer);
	end})
	self.mytimer:Change(30, 30)
end

-- return the mode: "selected" "none" nil
function ScreenRectSelector:OnUpdate()
	if(self.mode) then
		return self.mode;
	end
	if(self.check_mouse_button == "left" or self.check_mouse_button == 0) then
		if(not ParaUI.IsMousePressed(0)) then
			self:OnFinished();
			return self.mode;
		end
	elseif(self.check_mouse_button == "right" or self.check_mouse_button == 1) then
		if(not ParaUI.IsMousePressed(1)) then
			self:OnFinished();
			return self.mode;
		end
	end
	self.end_x, self.end_y = ParaUI.GetMousePosition();
	self.left = math.min(self.end_x, self.begin_x);
	self.top = math.min(self.end_y, self.begin_y); 
	self.width = math.abs(self.end_x - self.begin_x);
	self.height = math.abs(self.end_y - self.begin_y); 

	if(self.hasShownRect or self.width > self.min_width or self.height >self.min_height) then
		self.hasShownRect = true;
		self:DrawRect(self.left, self.top, self.width, self.height);
	end
	return self.mode;
end

function ScreenRectSelector:DrawRect(left, top, width, height)
	local _this = ParaUI.GetUIObject(self.ui_name);
	if(not _this:IsValid()) then
		_this = ParaUI.CreateUIObject("button", self.ui_name, "_lt", left, top, width, height);
		_this.background= "Texture/Aries/Creator/border_bg_32bits.png:2 2 2 2";
		_this.enabled = false;
		_guihelper.SetUIColor(_this, "#ffffff80");
		_this:AttachToRoot();
	else
		
		_this:Reposition("_lt", left, top, math.max(2, width), math.max(2, height));
	end
end

function ScreenRectSelector:DestroyRect()
	ParaUI.Destroy(self.ui_name);
end

function ScreenRectSelector:OnFinished()
	self:DestroyRect();
	if(self.mytimer) then
		self.mytimer:Change();
	end
	if(self.hasShownRect and (self.width > self.min_width or self.height >self.min_height))then
		self.mode = "selected"
	else
		self.mode = "none"
	end
	if(self.callbackFunc) then
		self.callbackFunc(self.mode, self.left, self.top, self.width, self.height);
	end
end

