--[[
Title: OBSOLETED use InfoWorldAxisWindow instead due to orthogonal/perspective projection issue. 
Author(s): LiXizhi
Date: 2022/5/17
Desc:  display a 3d world axis at the left bottom of the window
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/InfoWorldAxis.lua");
local InfoWorldAxis = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.InfoWorldAxis");
InfoWorldAxis.GetInstance():Show(true);
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
local InfoWorldAxis = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.InfoWorldAxis"));

InfoWorldAxis:Property({"xColor", "#ff0000"});
InfoWorldAxis:Property({"yColor", "#0000ff"});
InfoWorldAxis:Property({"zColor", "#00ff00"});
InfoWorldAxis:Property({"Font", "System;12;norm", auto=true})

local s_singleton;

function InfoWorldAxis:ctor()
	self.name = "__InfoWorldAxis__";
	self.pen = {width=0.02, color="#ffffff"};
	self.quat = mathlib.Quaternion:new();
	self.axis = mathlib.vector3d:new()
	self.matProj = mathlib.Matrix4:new():identity();
end

function InfoWorldAxis.GetInstance()
	if(not s_singleton) then
		s_singleton = InfoWorldAxis:new();
	end
	return s_singleton;
end

function InfoWorldAxis:CreateGetEntity()
	local entity = self:GetEntity()
	if(not entity) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityOverlay.lua");
		local EntityOverlay = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityOverlay")
		entity = EntityManager.EntityOverlay:Create({name = self.name, x=0, y=0, z=0})
		entity:SetPersistent(false);
		-- make it very big at first, so that it always get rendered, and we will update aabb at each render step.
		entity:SetBoundingRadius(100);
		entity.DoPaint = function(entity, painter)
			self:DoRender(painter);
		end
		entity:Attach();
		-- screen is [-500, 500], show at left bottom corner of the screen
		entity.ui_align = "bottom";
		entity:SetScreenPos(-470, 30);
		entity:SetScreenMode(true);
	end
	return entity;
end

function InfoWorldAxis:GetEntity()
	return EntityManager.GetEntity(self.name);
end

function InfoWorldAxis:Show(bShow)
	if(bShow~=false) then
		local entity = self:CreateGetEntity()
		if(entity) then
			entity:SetVisible(true);
		end
	else
		local entity = self:GetEntity()
		if(entity) then
			entity:SetVisible(false);
		end
	end
end


-- private function 
function InfoWorldAxis:DoRender(painter)
	painter:SetPen(self.pen);
	
	-- TODO: we need to switch to orthogonal projection matrix, but is not supported at the moment due to retained mode drawing.

	-- scale 100 times, match 1 pixel to 1 centimeter in the scene. 
	local scaling = 0.01;
	painter:ScaleMatrix(scaling, scaling, scaling);
	painter:SetFont(self:GetFont());

	local att = ParaCamera.GetAttributeObject();
	local pitch, yaw = att:GetField("CameraLiftupAngle", 0), att:GetField("CameraRotY", 0);
	local entity = self:GetEntity()
	if(entity) then
		self.quat:FromEulerAnglesSequence(-yaw - math.pi/2, 0, pitch, "yzx")
		local angle, axis = self.quat:ToAngleAxis(self.axis)
		painter:RotateMatrix(angle, axis[1], axis[2], axis[3])
	end

	local length = 20;
	local textScale = 0.8;
	local textSize = 12;
	painter:SetBrush(self.xColor);
	ShapesDrawer.DrawLine(painter, 0,0,0, length,0,0);
	painter:PushMatrix()
	painter:TranslateMatrix(length,0,0)
	painter:ScaleMatrix(textScale, textScale, textScale);
	painter:LoadBillboardMatrix();
	painter:DrawText(0, -textSize, "X")
	painter:PopMatrix()

	painter:SetBrush(self.yColor);
	ShapesDrawer.DrawLine(painter, 0,0,0, 0,length,0);
	painter:PushMatrix()
	painter:TranslateMatrix(0,length,0)
	painter:ScaleMatrix(textScale, textScale, textScale);
	painter:LoadBillboardMatrix();
	painter:DrawText(0, -textSize, "Y")
	painter:PopMatrix()

	painter:SetBrush(self.zColor);
	ShapesDrawer.DrawLine(painter, 0,0,0, 0,0,length);
	painter:PushMatrix()
	painter:TranslateMatrix(0,0,length)
	painter:ScaleMatrix(textScale, textScale, textScale);
	painter:LoadBillboardMatrix();
	painter:DrawText(0, -textSize, "Z")
	painter:PopMatrix()
end