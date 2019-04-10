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
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityLight"));

-- light properties
Entity:Property({"LightType", 1});

Entity:Property({"Diffuse", {0, 0, 0}});
Entity:Property({"Specular", {0, 0, 0}});
Entity:Property({"Ambient", {0, 0, 0}});

Entity:Property({"Position", {0, 0, 0}});
Entity:Property({"Direction", {0, 0, 0}});

Entity:Property({"Yaw", 0});
Entity:Property({"Pitch", 0});
Entity:Property({"Roll", 0});

Entity:Property({"Range", 1});
Entity:Property({"Falloff", 0});

Entity:Property({"Attenuation0", 1});
Entity:Property({"Attenuation1", 1});
Entity:Property({"Attenuation2", 1});

Entity:Property({"Theta", 0});
Entity:Property({"Phi", 0});

-- light model properties
Entity:Property({"modelInitPos", {0,0,0}});
Entity:Property({"modelOffsetPos", {0,0,0}});
Entity:Property({"modelScale", 1});
Entity:Property({"modelYaw", 0});
Entity:Property({"modelPitch", 0});
Entity:Property({"modelRoll", 0});
Entity:Property({"modelFilepath", ""});

-- class name
Entity.class_name = "EntityLight";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;

function Entity:ctor()
	self.modelInitPos = {0, 0, 0};
	self.modelOffsetPos = {0, 0, 0};
	self.modelFilepath = "model/blockworld/BlockModel/block_model_one.x";
end

function Entity:init()
	if(not Entity._super.init(self)) then
		return
	end
	self:CreateInnerObject();
	return self;
end

function Entity:isPointLight()
	local t = self:GetField("LightType");
	return t == 1;
end

function Entity:isSpotLight()
	local t = self:GetField("LightType");
	return t == 2;
end

function Entity:isDirectionalLight()
	local t = self:GetField("LightType");
	return t == 3;
end

function Entity:SetOffsetPos(offset)
	local p = self:GetField("modelInitPos");
	local x, y, z = p[1], p[2], p[3];

	offset[1] = math.min(math.max(-BlockEngine.half_blocksize, offset[1]), BlockEngine.half_blocksize);
	offset[2] = math.min(math.max(0, offset[2]), BlockEngine.blocksize);
	offset[3] = math.min(math.max(-BlockEngine.half_blocksize, offset[3]), BlockEngine.half_blocksize);
	self.modelOffsetPos = offset;

	local lightModel = self.lightModel;
	if(lightModel) then
		lightModel:SetPosition(x + offset[1], y + offset[2], z + offset[3]);
	end
	self:valueChanged();
end

function Entity:Clamp(v, min, max)
	if v < min then
		return min;
	end
	if v > max then
		return max;
	end
	return v;
end

function Entity:GetField(field, default_value)
	-- hand light model properties first
	if field == "modelInitPos" then
		return self.modelInitPos
	end
	if field == "modelOffsetPos" then
		return self.modelOffsetPos
	end
	if field == "modelScale" then
		return self.modelScale or 1
	end
	if field == "modelYaw" then
		return self.modelYaw or 0
	end
	if field == "modelPitch" then
		return self.modelPitch or 0
	end
	if field == "modelRoll" then
		return self.modelRoll or 0
	end
	if field == "modelFilepath" then
		return self.modelFilepath
	end

	-- properties belong to the C++ world's light object
	default_value = 0;
	if field == "Position" or
	   field == "Direction" or
	   field == "Diffuse" or
	   field == "Specular" or
	   field == "Ambient" then
		default_value = {0, 0, 0};
	end

	local lightObject = self:GetInnerObject();

	local value = lightObject:GetField(field, default_value);

	-- radian to degree
	if field == "Yaw"   or 
	   field == "Pitch" or 
	   field == "Roll"  or 
	   field == "Theta" or 
	   field == "Phi"   then
		value = value * 180 / 3.14;
	end

	-- color from float(0.f - 1.f) to int(0 - 255) 
	if field == "Diffuse" or
	   field == "Specular" or
	   field == "Ambient" then
		value = {
				self:Clamp(value[1] * 255, 0, 255),
				self:Clamp(value[2] * 255, 0, 255),
				self:Clamp(value[3] * 255, 0, 255),
				}
	end

	return value;
end

function Entity:SetField(field, value)
	local oldValue = self:GetField(field);

	-- ATTENTION: skip approximate values, because the multiple manips update values to plugs asynchronously
	if(type(oldValue) == "table") then
		if(commonlib.partialcompare(oldValue, value, 0.01)) then
			return;
		end
	elseif(type(oldValue) == "number") then
		if(math.abs(oldValue - value) < 0.01) then
			return;
		end
	end
	
	-- handle light model properties first
	if field == "modelOffsetPos" then
		self:SetOffsetPos(value)
		return;
	end
	if field == "modelScale" then
		self.modelScale = value

		local lightModel = self.lightModel;
		if(lightModel) then
			lightModel:SetScale(value);
		end
		self:valueChanged();

		return;
	end
	if field == "modelYaw" then
		self.modelYaw = value

		local lightModel = self.lightModel;
		if(lightModel) then
			lightModel:SetField("yaw", value);
		end
		self:valueChanged();

		return;
	end
	if field == "modelPitch" then
		self.modelPitch = value

		local lightModel = self.lightModel;
		if(lightModel) then
			lightModel:SetField("pitch", value);
		end
		self:valueChanged();

		return;
	end
	if field == "modelRoll" then
		self.modelRoll = value

		local lightModel = self.lightModel;
		if(lightModel) then
			lightModel:SetField("roll", value);
		end
		self:valueChanged();

		return;
	end
	if field == "modelFilepath" then
		self.modelFilepath = value

		local lightModel = self.lightModel;
		if(lightModel) then
			lightModel:SetField("assetfile", value);
		end
		self:valueChanged();

		return;
	end


	-- handle properties of C++ world's light object
	local lightObject = self:GetInnerObject();

	if field == "Phi" then
		if value < 0 or value > 179 then
			return;
		end

		local theta = self:GetField("Theta");
		if value < theta then
			lightObject:SetField("Theta", value * 3.14 / 180);
		end
	end
	if field == "Theta" then
		if value < 0 or value > 179 then
			return;
		end

		local phi = self:GetField("Phi");
		if value > phi then
			lightObject:SetField("Phi", value * 3.14 / 180);
		end
	end

	-- degree to radian
	if field == "Yaw"   or 
	   field == "Pitch" or 
	   field == "Roll" or 
	   field == "Theta" or 
	   field == "Phi"  then
		value = value * 3.14 / 180;
	end

	-- color from int(0 - 255) to float(0.f - 1.f)
	if field == "Diffuse" or
	   field == "Specular" or
	   field == "Ambient" then
		value = {
				self:Clamp(value[1] / 255, 0, 1),
				self:Clamp(value[2] / 255, 0, 1),
				self:Clamp(value[3] / 255, 0, 1),
				}
	end

	local result = lightObject:SetField(field, value);

	self:valueChanged();

	return result;
end

function Entity:CreateInnerObject()
	local x, y, z = self:GetPosition();

	local lightObject = ParaScene.CreateObject("CLightObject", self:GetBlockEntityName(), x,y,z);

	lightObject:SetAttribute(0x8000, true);
	lightObject:SetField("RenderDistance", 100);
	lightObject:SetField("IsDeferredLightOnly", true);

	self:SetInnerObject(lightObject);
	ParaScene.Attach(lightObject);


	local lightModel = ParaScene.CreateObject("BMaxObject", self:GetBlockEntityName(), x,y,z);

	lightModel:SetField("assetfile", self.modelFilepath);
	lightModel:SetAttribute(0x8080, true);
	lightModel:SetField("RenderDistance", 100);

	self.lightModel = lightModel;
	ParaScene.Attach(lightModel);

	self.modelInitPos = {x,y,z};

	return lightObject;
end

function Entity:Destroy()
	ParaScene.Delete(self.lightModel);

	self:DestroyInnerObject();
	Entity._super.Destroy(self);
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	local attr = node.attr;
	if(attr) then
	end
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	return node;
end

