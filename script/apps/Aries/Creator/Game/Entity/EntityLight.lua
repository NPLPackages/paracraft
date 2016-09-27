--[[
Title: EntityLight
Author(s): LiXizhi
Date: 2016/9/21
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityLight.lua");
local EntityLight = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityLight")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockBase.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityLight"));

Entity:Property({"yaw", 0, "getYaw", "setYaw"});

-- class name
Entity.class_name = "EntityLight";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;

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

function Entity:SetLightType(lightType)
end

function Entity:GetLightType()
end

-- this is helper function that derived class can use to create an inner mesh or character object. 
function Entity:CreateInnerObject(filename, scale)
	local x, y, z = self:GetPosition();

	local model = ParaScene.CreateObject("CLightObject", self:GetBlockEntityName(), x,y,z);

	-- TODO: Model?
	--filename = "blocktemplates/111.bmax";
	--filename = Files.WorldPathToFullPath(filename, true);
	--model:SetField("assetfile", filename);

	-- OBJ_SKIP_PICKING = 0x1<<15:
	model:SetAttribute(0x8000, true);
	model:SetField("RenderDistance", 100);
	model:SetField("IsDeferredLightOnly", true);
	self:SetInnerObject(model);
	ParaScene.Attach(model);
	return model;
end

function Entity:getYaw()
end

function Entity:setYaw(yaw)
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
	end
end

function Entity:SaveToXMLNode(node)
	node = Entity._super.SaveToXMLNode(self, node);
	-- node.attr.filename = self:GetModelFile();
	return node;
end

