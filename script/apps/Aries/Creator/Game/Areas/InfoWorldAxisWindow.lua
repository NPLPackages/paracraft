--[[
Title: display a 3d world axis at the left bottom of the window
Author(s): LiXizhi
Date: 2022/5/18
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/InfoWorldAxisWindow.lua");
local InfoWorldAxisWindow = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.InfoWorldAxisWindow");
InfoWorldAxisWindow.GetInstance():Show(true);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Overlays/ShapesDrawer.lua");
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
local Screen = commonlib.gettable("System.Windows.Screen");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local InfoWorldAxisWindow = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.InfoWorldAxisWindow"));

InfoWorldAxisWindow:Property({"xColor", "#ff0000"});
InfoWorldAxisWindow:Property({"yColor", "#0000ff"});
InfoWorldAxisWindow:Property({"zColor", "#00ff00"});
InfoWorldAxisWindow:Property({"Font", "System;12;norm", auto=true})

local s_singleton;

function InfoWorldAxisWindow:ctor()
	self.name = "__InfoWorldAxisWindow__";
	self.pen = {width=2, color="#ffffff"};
	self.quat = mathlib.Quaternion:new();
	self.axis = mathlib.vector3d:new()
	self.matProj = mathlib.Matrix4:new():identity();
end

function InfoWorldAxisWindow:GetWindow(bCreateIfNotExist)
	if(not self.window and bCreateIfNotExist) then
		local Window = commonlib.gettable("System.Windows.Window")
		local window = Window:new();
		window:SetInputMethodEnabled(false);
		window:SetCanHaveFocus(false);
		window:SetZOrder(-1000)
		window.Render = function(window, painterContext)
			self:DoRender(painterContext);
		end
		self.window = window;
		GameLogic:Connect("WorldUnloaded", self, self.Hide, "UniqueConnection");
	end
	return self.window;
end

function InfoWorldAxisWindow.GetInstance()
	if(not s_singleton) then
		s_singleton = InfoWorldAxisWindow:new();
	end
	return s_singleton;
end

function InfoWorldAxisWindow:Hide()
	self:Show(false)
end

function InfoWorldAxisWindow:Show(bShow)
	if(bShow~=false) then
		local width = 64;
		local window = self:GetWindow(true)
		window:Show(self.name, nil, "_lb", 10, -width-10, width, width)
		window:SetEnabled(false);
	else
		local window = self:GetWindow()
		if(window) then
			window:hide()
		end
	end
end

-- private function 
function InfoWorldAxisWindow:DoRender(painter)
	painter:SetPen(self.pen);
	painter:SetFont(self:GetFont());
	painter:Translate(32, 32)

	local length = 24; -- axis length in pixels
	local textSize = 12;
	local att = ParaCamera.GetAttributeObject();
	local pitch, yaw = att:GetField("CameraLiftupAngle", 0), att:GetField("CameraRotY", 0);
	self.quat:FromEulerAnglesSequence(-yaw - math.pi/2, 0, pitch, "yzx")
	
	local x, y, z = self.quat:RotateVector3(0, length, 0)
	painter:SetBrush(self.yColor);
	painter:DrawLine(0, 0, x, -y)
	painter:DrawText(x+1, -y-textSize, "Y")

	local x, y, z = self.quat:RotateVector3(0, 0, length)
	painter:SetBrush(self.zColor);
	painter:DrawLine(0, 0, x, y)
	painter:DrawText(x+1, y-textSize, "Z")

	local x, y, z = self.quat:RotateVector3(length, 0, 0)
	painter:SetBrush(self.xColor);
	painter:DrawLine(0, 0, x, y)
	painter:DrawText(x+1, y-textSize, "X")
end