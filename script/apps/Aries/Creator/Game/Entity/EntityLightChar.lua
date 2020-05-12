--[[
Title: EntityLightChar
Author(s): LiXizhi
Date: 2016/9/21
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityLightChar.lua");
local EntityLightChar = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityLightChar")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockBase.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.Entity"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityLightChar"));

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

-- class name
Entity.class_name = "EntityLightChar";
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
	-- properties belong to the C++ world's light object
	default_value = 0;
	if(field == "position") then
		return Entity._super.GetField(self, field, default_value)
	end

	if field == "Position" or
	   field == "Direction" or
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
	if(field == "position") then
		return Entity._super.SetField(self, field, value)
	end

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
	
	-- handle properties of C++ world's light object
	local lightObject = self:GetInnerObject();
	if(not lightObject) then
		return
	end
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

	local lightObject = ParaScene.CreateObject("CLightObject", "EntityLightChar", x,y,z);

	lightObject:SetAttribute(0x8000, true);
	lightObject:SetField("RenderDistance", 100);
	lightObject:SetField("IsDeferredLightOnly", true);

	self:SetInnerObject(lightObject);
	ParaScene.Attach(lightObject);

	return lightObject;
end

function Entity:Destroy()
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

-- @param actor: the parent ActorNPC
function Entity:SetActor(actor)
	self.m_actor = actor;
end

-- @param actor: the parent ActorNPC
function Entity:GetActor()
	return self.m_actor;
end