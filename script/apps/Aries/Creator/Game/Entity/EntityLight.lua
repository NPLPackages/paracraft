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
local vector3d = commonlib.gettable("mathlib.vector3d");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityLight"));

-- light properties
Entity:Property({"LightType", 1});

Entity:Property({"Diffuse", {1, 0, 1}});
Entity:Property({"Specular", {1, 0, 0}});
Entity:Property({"Ambient", {1, 0, 0}});

Entity:Property({"Yaw", 0});
Entity:Property({"Pitch", 0});
Entity:Property({"Roll", 0});
Entity:Property({"Direction", {0, 0, 0}}); -- another read-only presentation of Yaw, Pitch, Roll
Entity:Property({"offsetPos", {0,0.5,0}, "GetOffsetPos", "SetOffsetPos"});

Entity:Property({"Range", 3});
Entity:Property({"Falloff", 1});

Entity:Property({"Attenuation0", 0.3});
Entity:Property({"Attenuation1", 0.1});
Entity:Property({"Attenuation2", 1});

Entity:Property({"Theta", 0.8});
Entity:Property({"Phi", 1});

-- light model properties
Entity:Property({"modelOffsetPos", {0,0,0}});
Entity:Property({"modelScale", 1});
Entity:Property({"modelYaw", 0});
Entity:Property({"modelPitch", 0});
Entity:Property({"modelRoll", 0});
Entity:Property({"modelFilepath", ""}); -- model/blockworld/BlockModel/block_model_one.x

-- class name
Entity.class_name = "EntityLight";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;

function Entity:ctor()
	self.modelOffsetPos = vector3d:new(0,0,0);
	self.Diffuse = {1, 0, 1};
	self.Specular = {1, 0, 0};
	self.Ambient = {1, 0, 0};
	self.offsetPos = vector3d:new(0,0.5,0);
	self.modelFilepath = "model/blockworld/BlockModel/block_model_one.x"
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

function Entity:GetOffsetPos()
	return self.offsetPos;
end

function Entity:SetOffsetPos(v)
	if(not self.offsetPos:equals(v)) then
		local x, y, z = self:GetPosition();
		v[1] = math.min(math.max(-BlockEngine.half_blocksize, v[1]), BlockEngine.half_blocksize);
		v[2] = math.min(math.max(0, v[2]), BlockEngine.blocksize);
		v[3] = math.min(math.max(-BlockEngine.half_blocksize, v[3]), BlockEngine.half_blocksize);
		self.offsetPos:set(v);
		local obj = self:GetInnerObject();
		if(obj) then
			obj:SetPosition(x + v[1], y + v[2], z + v[3]);
			obj:UpdateTileContainer();
		end
		self:valueChanged();
	end
end

function Entity:SetModelOffsetPos(offset)
	if(not self.modelOffsetPos:equals(offset)) then
		local x, y, z = self:GetPosition();

		offset[1] = math.min(math.max(-BlockEngine.half_blocksize, offset[1]), BlockEngine.half_blocksize);
		offset[2] = math.min(math.max(0, offset[2]), BlockEngine.blocksize);
		offset[3] = math.min(math.max(-BlockEngine.half_blocksize, offset[3]), BlockEngine.half_blocksize);
		self.modelOffsetPos:set(offset);

		local lightModel = self.lightModel;
		if(lightModel) then
			lightModel:SetPosition(x + offset[1], y + offset[2], z + offset[3]);
		end
		self:valueChanged();
	end
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
	if field == "position" then
		return self:getPosition();
	end
	if field == "offsetPos" then
		return self:GetOffsetPos();
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
	if field == "Direction" or
		field == "Diffuse" or
	   field == "Specular" or
	   field == "Ambient" then
		default_value = {0, 0, 0};
	end

	local lightObject = self:GetInnerObject();

	local value = lightObject and lightObject:GetField(field, default_value) or default_value;


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
	
	if field == "offsetPos" then
		self:SetOffsetPos(value)
		return;
	end

	-- handle light model properties first
	if field == "modelOffsetPos" then
		self:SetModelOffsetPos(value)
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
	if(not lightObject) then
		return
	end
	if field == "LightType" then
		self.LightType = value;
		lightObject:SetField("LightType", self.LightType);
	end
	if field == "Phi" then
		if value < 0 or value > 179 then
			return;
		end

		local theta = self:GetField("Theta");
		if value < theta then
			self.Theta = value * 3.14 / 180
			lightObject:SetField("Theta", self.Theta);
		end
	end
	if field == "Theta" then
		if value < 0 or value > 179 then
			return;
		end

		local phi = self:GetField("Phi");
		if value > phi then
			self.Phi = value * 3.14 / 180
			lightObject:SetField("Phi", self.Phi);
		end
	end

	-- degree to radian
	if field == "Yaw"   or 
	   field == "Pitch" or 
	   field == "Roll" or 
	   field == "Theta" or 
	   field == "Phi"  then
		value = value * 3.14 / 180;
		self[field] = value;
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
		self[field] = value;
	end
	
	local result = lightObject:SetField(field, value);

	self:valueChanged();

	return result;
end

function Entity:CreateInnerObject()
	local x, y, z = self:GetPosition();

	local lightObject = ParaScene.CreateObject("CLightObject", self:GetBlockEntityName(), x+self.offsetPos[1],y+self.offsetPos[2],z+self.offsetPos[3]);

	lightObject:SetAttribute(0x8000, true);
	lightObject:SetField("RenderDistance", 100);
	lightObject:SetField("IsDeferredLightOnly", true);

	lightObject:SetField("LightType", self.LightType);
	lightObject:SetField("Diffuse", self.Diffuse);
	lightObject:SetField("Specular", self.Specular);
	lightObject:SetField("Ambient", self.Ambient);
	lightObject:SetField("Theta", self.Theta);
	lightObject:SetField("Phi", self.Phi);
	lightObject:SetField("Roll", self.Roll);
	lightObject:SetField("Yaw", self.Yaw);
	lightObject:SetField("Pitch", self.Pitch);

	self:SetInnerObject(lightObject);
	ParaScene.Attach(lightObject);


	local lightModel = ParaScene.CreateObject("BMaxObject", self:GetBlockEntityName(), x + self.modelOffsetPos[1], y + self.modelOffsetPos[2], z + self.modelOffsetPos[3]);

	lightModel:SetField("assetfile", self.modelFilepath);
	lightModel:SetAttribute(0x8080, true);
	lightModel:SetField("RenderDistance", 100);
	lightModel:SetField("roll", self.modelRoll);
	lightModel:SetField("yaw", self.modelYaw);
	lightModel:SetField("pitch", self.modelPitch);
	lightModel:SetScale(self.modelScale);
	

	self.lightModel = lightModel;
	ParaScene.Attach(lightModel);

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
		-- static model properties
		if(attr.modelFilepath) then
			self.modelFilepath = attr.modelFilepath;
		end
		if(attr.modelOffsetPos) then
			self.modelOffsetPos:set(NPL.LoadTableFromString(attr.modelOffsetPos));
		end
		if(attr.modelScale) then
			self.modelScale = tonumber(attr.modelScale);
		end
		if(attr.modelYaw) then
			self.modelYaw = tonumber(attr.modelYaw);
		end
		if(attr.modelPitch) then
			self.modelPitch = tonumber(attr.modelPitch);
		end
		if(attr.modelRoll) then
			self.modelRoll = tonumber(attr.modelRoll);
		end
		-- light properties
		if(attr.LightType) then
			self.LightType = tonumber(attr.LightType);
		end
		if(attr.offsetPos) then
			self.offsetPos:set(NPL.LoadTableFromString(attr.offsetPos));
		end
		if(attr.Yaw) then
			self.Yaw = tonumber(attr.Yaw);
		end
		if(attr.Roll) then
			self.Roll = tonumber(attr.Roll);
		end
		if(attr.Pitch) then
			self.Pitch = tonumber(attr.Pitch);
		end
		if(attr.Phi) then
			self.Phi = tonumber(attr.Phi);
		end
		if(attr.Theta) then
			self.Theta = tonumber(attr.Theta);
		end
		if(attr.Attenuation0) then
			self.Attenuation0 = tonumber(attr.Attenuation0);
		end
		if(attr.Attenuation1) then
			self.Attenuation1 = tonumber(attr.Attenuation1);
		end
		if(attr.Attenuation2) then
			self.Attenuation2 = tonumber(attr.Attenuation2);
		end
		if(attr.Range) then
			self.Range = tonumber(attr.Range);
		end
		if(attr.Falloff) then
			self.Falloff = tonumber(attr.Falloff);
		end
		if(attr.Diffuse) then
			self.Diffuse = NPL.LoadTableFromString(attr.Diffuse);
		end
		if(attr.Specular) then
			self.Specular = NPL.LoadTableFromString(attr.Specular);
		end
		if(attr.Ambient) then
			self.Ambient = NPL.LoadTableFromString(attr.Ambient);
		end
	end
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	local attr = node.attr;
	-- model property
	attr.modelFilepath = self.modelFilepath;
	attr.modelOffsetPos = commonlib.serialize_compact(self.modelOffsetPos);
	attr.modelScale = self.modelScale;
	attr.modelYaw = self.modelYaw;
	attr.modelPitch = self.modelPitch;
	attr.modelRoll = self.modelRoll;
	-- light properties
	attr.LightType = self.LightType;
	attr.offsetPos = commonlib.serialize_compact(self.offsetPos);
	attr.Phi = self.Phi;
	attr.Theta = self.Theta;
	attr.Roll = self.Roll;
	attr.Yaw = self.Yaw;
	attr.Pitch = self.Pitch;
	attr.Attenuation0 = self.Attenuation0;
	attr.Attenuation1 = self.Attenuation1;
	attr.Attenuation2 = self.Attenuation2;
	attr.Range = self.Range;
	attr.Falloff = self.Falloff;
	attr.Diffuse = commonlib.serialize_compact(self.Diffuse);
	attr.Specular = commonlib.serialize_compact(self.Specular);
	attr.Ambient = commonlib.serialize_compact(self.Ambient);
	return node;
end

-- @param actor: the parent ActorNPC
function Entity:SetActor(actor)
	self.m_actor = actor;
end

-- @param actor: the parent ActorNPC
function Entity:GetActor()
	return self.m_actor;
end

-- Overriden in a sign to provide the text.
function Entity:GetDescriptionPacket()
	local x,y,z = self:GetBlockPos();
	local attr = {}
	local function setNumberField(name)
		attr[name] = self:GetField(name);
	end
	attr.modelFilepath = self:GetField("modelFilepath");
	setNumberField("modelOffsetPos")
	setNumberField("modelScale")
	setNumberField("modelYaw")
	setNumberField("modelPitch")
	setNumberField("modelRoll")
	setNumberField("LightType")
	setNumberField("offsetPos")
	setNumberField("Yaw")
	setNumberField("Pitch")
	setNumberField("Roll")
	setNumberField("Diffuse")
	setNumberField("Specular")
	setNumberField("Ambient")
	setNumberField("Attenuation0")
	setNumberField("Attenuation1")
	setNumberField("Attenuation2")
	setNumberField("Theta")
	setNumberField("Phi")
	setNumberField("Range")
	setNumberField("Falloff")
	return Packets.PacketUpdateEntityBlock:new():Init(x,y,z, attr);
end

-- update from packet. 
function Entity:OnUpdateFromPacket(packet_UpdateEntityBlock)
	if(packet_UpdateEntityBlock:isa(Packets.PacketUpdateEntityBlock)) then
		local attr = packet_UpdateEntityBlock.data1;
		if(type(attr) == "table") then
			local function setNumbersField(name, value)
				local t = type(value)
				if(t == "table") then
					self:SetField(name, value)	
				else
					value = tonumber(value)
					if(value) then
						self:SetField(name, value)	
					end
				end
			end

			if(attr.modelFilepath) then
				self:SetField("modelFilepath", attr.modelFilepath)
			end
			setNumbersField("modelOffsetPos", attr.modelOffsetPos)
			setNumbersField("modelScale", attr.modelScale)
			setNumbersField("modelRoll", attr.modelRoll)
			setNumbersField("modelYaw", attr.modelYaw)
			setNumbersField("modelPitch", attr.modelPitch)

			setNumbersField("LightType", attr.LightType)
			setNumbersField("offsetPos", attr.offsetPos)
			setNumbersField("Yaw", attr.Yaw)
			setNumbersField("Pitch", attr.Pitch)
			setNumbersField("Roll", attr.Roll)
			setNumbersField("Diffuse", attr.Diffuse)
			setNumbersField("Specular", attr.Specular)
			setNumbersField("Ambient", attr.Ambient)
			setNumbersField("Theta", attr.Theta)
			setNumbersField("Phi", attr.Phi)
			setNumbersField("Range", attr.Range)
			setNumbersField("Falloff", attr.Falloff)
			setNumbersField("Attenuation0", attr.Attenuation0)
			setNumbersField("Attenuation1", attr.Attenuation1)
			setNumbersField("Attenuation2", attr.Attenuation2)
		end
	end
end