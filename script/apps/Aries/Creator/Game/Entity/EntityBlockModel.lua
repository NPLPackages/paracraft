--[[
Title: Block Model
Author(s): LiXizhi
Date: 2015/5/25
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockModel.lua");
local EntityBlockModel = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockModel")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockBase.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockModel"));

-- class name
Entity.class_name = "EntityBlockModel";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;
-- if model is invalid, use this model file. 
Entity.default_file = "character/common/headquest/headquest.x";

function Entity:ctor()
end

function Entity:init()
	if(not Entity._super.init(self)) then
		return
	end
	self:CreateInnerObject(self.filename, self.scale);
	self:Refresh();
	return self;
end

-- this is helper function that derived class can use to create an inner mesh or character object. 
function Entity:CreateInnerObject(filename, scale)
	filename = Files.WorldPathToFullPath(filename, true) or self.default_file;
	local x, y, z = self:GetPosition();

	if(filename == self.default_file) then
		LOG.std(nil, "warn", "EntityBlockModel", "filename: %s not found at %d %d %d", self.filename or "", self.bx or 0, self.by or 0, self.bz or 0);
	end

	local model = ParaScene.CreateObject("BMaxObject", "", x,y,z);
	model:SetField("assetfile", filename);
	if(self.scale) then
		model:SetScaling(self.scale);
	end
	if(self.facing) then
		model:SetFacing(self.facing);
	end
	-- OBJ_SKIP_PICKING = 0x1<<15:
	-- MESH_USE_LIGHT = 0x1<<7: use block ambient and diffuse lighting for this model. 
	model:SetAttribute(0x8080, true);
	model:SetField("RenderDistance", 100);
	self:SetInnerObject(model);
	ParaScene.Attach(model);
	return model;
end

function Entity:Destroy()
	self:DestroyInnerObject();
	Entity._super.Destroy(self);
end

function Entity:Refresh()
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	local attr = node.attr;
	if(attr) then
		if(attr.filename) then
			self:SetModelFile(attr.filename);
		end
	end
end

function Entity:SetModelFile(filename)
	self.filename = filename;
end

function Entity:GetModelFile()
	return self.filename;
end

function Entity:SaveToXMLNode(node)
	node = Entity._super.SaveToXMLNode(self, node);
	node.attr.filename = self:GetModelFile();
	return node;
end

-- right click to show item
function Entity:OnClick(x, y, z, mouse_button)
	return true;
end

function Entity:OnBlockAdded(x,y,z)
	if(not self.facing) then
		--self.facing = Direction.GetFacingFromCamera();
		self.facing = Direction.directionTo3DFacing[Direction.GetDirection2DFromCamera()];
		local obj = self:GetInnerObject();
		if(obj) then
			obj:SetFacing(self.facing);
		end
	end
end

-- called every frame
function Entity:FrameMove(deltaTime)
end