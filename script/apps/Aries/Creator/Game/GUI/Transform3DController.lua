--[[
Title: world cooridnate 3d marker
Author(s): LiXizhi
Date: 2014/3/11
Desc: rendering the 3d coordinate in the 3d world in a mini-scenegraph. 
code is from TransformationBox.lua in year 2008.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/Transform3DController.lua");
local Transform3DController = commonlib.gettable("MyCompany.Aries.Game.GUI.Transform3DController");
Transform3DController.GetSingleton():SetBlockPos(x,y,z);
Transform3DController.GetSingleton():Hide();

local ctler = Transform3DController:new():Init("myCord", x,y,z)
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/Display3D/SceneCanvas.lua");
NPL.load("(gl)script/ide/Display3D/SceneManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local Transform3DController = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.GUI.Transform3DController"));


local singleton;
function Transform3DController.GetSingleton()
	singleton =  singleton or Transform3DController:new():Init();
	return singleton;
end


Transform3DController.assets = {
	transplane_x = "model/common/editor/x.x",
	transplane_y = "model/common/editor/y.x",
	transplane_z = "model/common/editor/z.x",
	rotation = "model/common/editor/rotation.x",
	transplane = "model/common/editor/transplane.x",
	scalebox = "model/common/editor/scalebox.x",
	cordinate = "model/blockworld/Coordinate/Coordinate.x",
};

Transform3DController.position = {255,1,255};
Transform3DController.scale = 0.5;

function Transform3DController:ctor()
end

function Transform3DController:Init(name, x,y,z)
	self.name = name or "Transform3DController";
	
	local scaleBoxes ={}
	scaleBoxes[1] = {-1,1,1};
	scaleBoxes[2] = {1,1,1};
	scaleBoxes[3] = {1,-1,1};
	scaleBoxes[4] = {-1,-1,1};
	scaleBoxes[5] = {-1,1,-1};
	scaleBoxes[6] = {1,1,-1};
	scaleBoxes[7] = {1,-1,-1};
	scaleBoxes[8] = {-1,-1,-1};
	self.scaleBoxes = scaleBoxes;
	
	self.rotation_y = {0,2.5,0};
	self.transplane_x = {0,0,0};
	self.transplane_y = {0,0,0};
	self.transplane_z = {0,0,0};
	self.transplane = {0,0,0};
	self.pivot = {0,0,0};

	if(x) then
		self:SetBlockPos(x,y,z);
	end
	return self;
end

function Transform3DController:UpdateScaleBox(objGraph)
	local obj;
	-- scale box
	for k = 1,8 do
		local _assetName = self.assets["scalebox"];
		local _asset = ParaAsset.LoadStaticMesh("", _assetName);
		obj = ParaScene.CreateMeshPhysicsObject("scalebox"..k, _asset, 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
		if(obj:IsValid()) then
			local pos = self.scaleBoxes[k];
			local x = pos[1]*self.scale + self.position[1];
			local y = pos[2]*self.scale + self.position[2];
			local z = pos[3]*self.scale + self.position[3];
			obj:SetPosition(x,y,z);
			obj:SetField("progress", 1);
			objGraph:AddChild(obj);
		end
	end
	-- transplane
	local _assetName = self.assets["transplane"];
	local _asset = ParaAsset.LoadStaticMesh("", _assetName);
	obj = ParaScene.CreateMeshPhysicsObject("transplane", _asset, 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
	if(obj:IsValid()) then
		local pos = self.transplane;
		local x = pos[1]*self.scale + self.position[1];
		local y = pos[2]*self.scale + self.position[2];
		local z = pos[3]*self.scale + self.position[3];
		obj:SetPosition(x,y,z);
		obj:SetField("progress", 1);
		objGraph:AddChild(obj);
	end
end

function Transform3DController:UpdateTranslationAxis(objGraph)
	-- transplane_x
	local obj;
	local _assetName = self.assets["transplane_x"];
	local _asset = ParaAsset.LoadStaticMesh("", _assetName);
	obj = ParaScene.CreateMeshPhysicsObject("transplane_x", _asset, 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
	if(obj:IsValid()) then
		local pos = self.transplane_x;
		local x = pos[1]*self.scale + self.position[1];
		local y = pos[2]*self.scale + self.position[2];
		local z = pos[3]*self.scale + self.position[3];
		obj:SetPosition(x,y,z);
		obj:SetField("progress", 1);
		objGraph:AddChild(obj);
	end
	-- transplane_y
	local _assetName = self.assets["transplane_y"];
	local _asset = ParaAsset.LoadStaticMesh("", _assetName);
	obj = ParaScene.CreateMeshPhysicsObject("transplane_y", _asset, 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
	if(obj:IsValid()) then
		local pos = self.transplane_y;
		local x = pos[1]*self.scale + self.position[1];
		local y = pos[2]*self.scale + self.position[2];
		local z = pos[3]*self.scale + self.position[3];
		obj:SetPosition(x,y,z);
		obj:SetField("progress", 1);
		objGraph:AddChild(obj);
	end
	-- transplane_z
	local _assetName = self.assets["transplane_z"];
	local _asset = ParaAsset.LoadStaticMesh("", _assetName);
	obj = ParaScene.CreateMeshPhysicsObject("transplane_z", _asset, 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
	if(obj:IsValid()) then
		local pos = self.transplane_z;
		local x = pos[1]*self.scale + self.position[1];
		local y = pos[2]*self.scale + self.position[2];
		local z = pos[3]*self.scale + self.position[3];
		obj:SetPosition(x,y,z);
		obj:SetField("progress", 1);
		objGraph:AddChild(obj);
	end
end

function Transform3DController:UpdateTranslationXYZ(objGraph)
	local obj;
	local _assetName = self.assets["cordinate"];
	local _asset = ParaAsset.LoadStaticMesh("", _assetName);
	obj = ParaScene.CreateMeshPhysicsObject("cordinate", _asset, 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
	if(obj:IsValid()) then
		local pos = self.pivot;
		local x = pos[1]*self.scale + self.position[1];
		local y = pos[2]*self.scale + self.position[2];
		local z = pos[3]*self.scale + self.position[3];
		obj:SetPosition(x,y,z);
		obj:SetField("progress", 1);
		objGraph:AddChild(obj);
	end
end

-- update rotation. 
function Transform3DController:UpdateRotation(objGraph)
	local obj;
	-- rotation_y
	local _assetName = self.assets["rotation"];
	local _asset = ParaAsset.LoadStaticMesh("", _assetName);
	obj = ParaScene.CreateMeshPhysicsObject("rotation_y", _asset, 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
	if(obj:IsValid()) then
		local pos = self.rotation_y;
		local x = pos[1]*self.scale + self.position[1];
		local y = pos[2]*self.scale + self.position[2];
		local z = pos[3]*self.scale + self.position[3];
		obj:SetPosition(x,y,z);
		obj:SetField("progress", 1);
		objGraph:AddChild(obj);
	end	
end

function Transform3DController:UpdateAll()
	self:Clear();
	local objGraph = ParaScene.GetMiniSceneGraph(self.name);	

	-- self:UpdateScaleBox(objGraph)
	-- self:UpdateTranslationAxis(objGraph);
	self:UpdateTranslationXYZ(objGraph)
	-- self:UpdateRotation(objGraph)
end

function Transform3DController:Hide()
	local objGraph = ParaScene.GetMiniSceneGraph(self.name);
	objGraph:Reset();
end

function Transform3DController:Clear()
	local objGraph = ParaScene.GetMiniSceneGraph(self.name);
	objGraph:Reset();
end

-- @param x, y,z: use the current player position if not exist. 
function Transform3DController:SetBlockPos(x,y,z)
	if(not x) then
		x,y,z = EntityManager.GetPlayer():GetBlockPos();
	end
	self.bx, self.by, self.bz = x,y,z
	x,y,z = BlockEngine:real(x,y,z)
	self.position = {x,y,z};
	self:UpdateAll();
end

function Transform3DController:GetBlockPos()
	return self.bx, self.by, self.bz;
end