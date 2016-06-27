--[[
Title: Camera Controller
Author(s): LiXizhi
Date: 2012/11/30
Desc: First person/Third person/View Bobbing, etc. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/StereoVisionController.lua");
local StereoVisionController = commonlib.gettable("MyCompany.Aries.Game.StereoVisionController")
StereoVisionController:InitSingleton();
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/CameraController.lua");
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
local vector3d = commonlib.gettable("mathlib.vector3d");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

---------------------------
-- create class
---------------------------
local StereoVisionController = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.StereoVisionController"))
StereoVisionController:Property("Name", "StereoVisionController");

function StereoVisionController:ctor()
	self.pitch = 0;
	self.roll = 0;
end

function StereoVisionController:reset()
end

function StereoVisionController:SetEnabled(bEnable)
	self.bEnabled = bEnable;
	if(bEnable) then
		ParaScene.RegisterEvent("_a_paracraft_accelerometer", ";MyCompany.Aries.Game.StereoVisionController:OnAccelerator();");
	else
		ParaScene.UnregisterEvent("_a_paracraft_accelerometer");
		self.pitch = 0;
		self.roll = 0;
		CameraController:SetAdditionalCameraRotate(0, 0, 0);
	end
end

function StereoVisionController:IsEnabled()
	return self.bEnabled;
end

function StereoVisionController:OnAccelerator()
	if(not self:IsEnabled()) then
		return;
	end
	local acc = msg;

	local bLandScapeMode = true;
	local dir;
	if(bLandScapeMode) then
		dir = vector3d:new(acc.y, acc.x, acc.z);
	else
		dir = vector3d:new(acc.x, acc.y, acc.z);
	end
	dir:normalize();
	local x, y, z = dir[1], dir[2], dir[3];

	self.pitchLast = self.pitch;
	self.rollLast = self.roll;

	self.pitch = -math.atan (x / math.sqrt(y^2 + z^2)) - 1.57;
	self.roll = math.atan (y / math.sqrt(x^2 + z^2));
	self.pitch = self.pitchLast*0.9 + self.pitch * 0.1;
	self.roll = self.rollLast*0.9 + self.roll * 0.1;
	
	CameraController:SetAdditionalCameraRotate(0 , self.pitch, self.roll);

	-- LOG.std(nil, "info", "StereoVisionController", "%f %f %f (pitch:%f, roll:%f)", acc.x, acc.y, acc.z, self.pitch, self.roll);
end