--[[
Title: EntityLightChar
Author(s): LiXizhi
Date: 2020/5/14
Desc: This is a movable entity that can move around the scene. Used by movie block ActorLight.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityLightChar.lua");
local EntityLightChar = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityLightChar")
-------------------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Color = commonlib.gettable("System.Core.Color");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.Entity"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityLightChar"));

-- light properties
Entity:Property({"LightType", 1, auto=true});

Entity:Property({"Diffuse", {1, 0, 1}, auto=true});
Entity:Property({"Specular", {1, 0, 0}, auto=true});
Entity:Property({"Ambient", {1, 0, 0}, auto=true});

Entity:Property({"Range", 3, auto=true});
Entity:Property({"Falloff", 1, auto=true});

Entity:Property({"Attenuation0", 0.3, auto=true});
Entity:Property({"Attenuation1", 0.1, auto=true});
Entity:Property({"Attenuation2", 1, auto=true});

Entity:Property({"Theta", 0.8, auto=true});
Entity:Property({"Phi", 1, auto=true});

-- class name
Entity.class_name = "EntityLightChar";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;

function Entity:ctor()
	self.Diffuse = {1, 0, 1}
	self.Specular = {1, 0, 0}
	self.Ambient = {1, 0, 0}
end

function Entity:init()
	if(not Entity._super.init(self)) then
		return
	end
	self:CreateInnerObject();
	return self;
end

function Entity:SetLightType(value)
	if(self.LightType == value) then
		return
	end
	self.LightType = value
	local lightObject = self:GetInnerObject();
	if(lightObject) then
		lightObject:SetField("LightType", self.LightType);
	end
	self:valueChanged();
end

function Entity:SetDiffuse(value)
	if(commonlib.partialcompare(self.Diffuse, value, 0.001)) then
		return
	end
	self.Diffuse[1] = value[1]
	self.Diffuse[2] = value[2]
	self.Diffuse[3] = value[3]
	local lightObject = self:GetInnerObject();
	if(lightObject) then
		lightObject:SetField("Diffuse", self.Diffuse);
	end
	self:valueChanged();
end

function Entity:SetSpecular(value)
	if(commonlib.partialcompare(self.Specular, value, 0.001)) then
		return
	end
	self.Specular[1] = value[1]
	self.Specular[2] = value[2]
	self.Specular[3] = value[3]
	local lightObject = self:GetInnerObject();
	if(lightObject) then
		lightObject:SetField("Specular", self.Specular);
	end
	self:valueChanged();
end

function Entity:SetAmbient(value)
	if(commonlib.partialcompare(self.Ambient, value, 0.001)) then
		return
	end
	self.Ambient[1] = value[1]
	self.Ambient[2] = value[2]
	self.Ambient[3] = value[3]
	local lightObject = self:GetInnerObject();
	if(lightObject) then
		lightObject:SetField("Ambient", self.Ambient);
	end
	self:valueChanged();
end

-- @param color: 0xff0000 or "#ff00ff"
function Entity:SetColor(color)
	local r, g, b = Color.ColorStr_TO_RGBAfloat(tostring(color));
	if(r and g and b) then
		local value = {r,g,b}
		self:SetDiffuse(value)
		self:SetSpecular(value)
		self:SetAmbient(value)
	end
end

function Entity:GetColor()
	local value = self:GetSpecular()
	if(value) then
		return Color.RGBAfloat_TO_ColorStr(value[1],value[2],value[3])
	end
end


function Entity:isPointLight()
	return self:GetLightType() == 1;
end

function Entity:isSpotLight()
	return self:GetLightType() == 2;
end

function Entity:isDirectionalLight()
	return self:GetLightType() == 3;
end

function Entity:SetRange(value)
	if(commonlib.partialcompare(self.Range, value, 0.001)) then
		return
	end
	self.Range = value
	local lightObject = self:GetInnerObject();
	if(lightObject) then
		lightObject:SetField("Range", self.Range);
	end
	self:valueChanged();
end

function Entity:SetFalloff(value)
	if(commonlib.partialcompare(self.Falloff, value, 0.001)) then
		return
	end
	self.Falloff = value
	local lightObject = self:GetInnerObject();
	if(lightObject) then
		lightObject:SetField("Falloff", self.Falloff);
	end
	self:valueChanged();
end

function Entity:SetAttenuation0(value)
	if(commonlib.partialcompare(self.Attenuation0, value, 0.001)) then
		return
	end
	self.Attenuation0 = value
	local lightObject = self:GetInnerObject();
	if(lightObject) then
		lightObject:SetField("Attenuation0", self.Attenuation0);
	end
	self:valueChanged();
end

function Entity:SetAttenuation1(value)
	if(commonlib.partialcompare(self.SetAttenuation1, value, 0.001)) then
		return
	end
	self.SetAttenuation1 = value
	local lightObject = self:GetInnerObject();
	if(lightObject) then
		lightObject:SetField("SetAttenuation1", self.SetAttenuation1);
	end
	self:valueChanged();
end

function Entity:SetAttenuation2(value)
	if(commonlib.partialcompare(self.SetAttenuation2, value, 0.001)) then
		return
	end
	self.SetAttenuation2 = value
	local lightObject = self:GetInnerObject();
	if(lightObject) then
		lightObject:SetField("SetAttenuation2", self.SetAttenuation2);
	end
	self:valueChanged();
end


function Entity:SetTheta(value)
	if(commonlib.partialcompare(self.Theta, value, 0.001)) then
		return
	end
	self.Theta = value
	local lightObject = self:GetInnerObject();
	if(lightObject) then
		lightObject:SetField("Theta", self.Theta);
	end
	self:valueChanged();
end

function Entity:SetPhi(value)
	if(commonlib.partialcompare(self.Phi, value, 0.001)) then
		return
	end
	self.Phi = value
	local lightObject = self:GetInnerObject();
	if(lightObject) then
		lightObject:SetField("Phi", self.Phi);
	end
	self:valueChanged();
end

function Entity:CreateInnerObject()
	local x, y, z = self:GetPosition();

	local lightObject = ParaScene.CreateObject("CLightObject", "EntityLightChar", x,y,z);

	lightObject:SetAttribute(0x8000, true);
	lightObject:SetField("RenderDistance", 100);
	lightObject:SetField("IsDeferredLightOnly", true);

	-- update values from C++ object
	self.Diffuse = lightObject:GetField("Specular", self.Diffuse);
	self.Specular = lightObject:GetField("Specular", self.Specular);
	self.Ambient = lightObject:GetField("Ambient", self.Ambient);

	self.Range = lightObject:GetField("Range", self.Range);
	self.Falloff = lightObject:GetField("Falloff", self.Range);

	self.Attenuation0 = lightObject:GetField("Attenuation0", self.Attenuation0);
	self.Attenuation1 = lightObject:GetField("Attenuation1", self.Attenuation1);
	self.Attenuation2 = lightObject:GetField("Attenuation2", self.Attenuation2);

	self.Theta = lightObject:GetField("Theta", self.Theta);
	self.Phi = lightObject:GetField("Phi", self.Phi);
	
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