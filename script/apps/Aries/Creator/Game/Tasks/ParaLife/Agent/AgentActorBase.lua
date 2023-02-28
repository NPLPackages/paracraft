--[[
Title: Base class for an agent actor
Author(s): LiXizhi
Date: 2022/6/2
Desc: Agent actor is usually an AI controller of an entity. It is is created from an agent item in the entity, when we call entity:GetAgent(name). 
This class can be used as a base class for your own agent when entity:GetAgent(name) is called. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/Agent/AgentActorBase.lua");
local Actor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Agents.AgentActorBase"), nil);
Actor:Property("Name", "MyAgent");

function Actor:ctor()
end
------------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")

local Actor = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Agents.AgentActorBase"));

function Actor:ctor()
end

function Actor:Init(entity, itemStack)
	if(entity) then
		self.entity = entity
		self.itemStack = itemStack;
		return self;
	end
end

function Actor:Destroy()
	local entity = self:GetEntity()
	if(entity) then
		entity:Destroy();
	end
end

function Actor:GetEntity()
	return self.entity;
end

-- user is using WASD key to control this actor now. 
function Actor:IsUserControlled()
	local entity = self:GetEntity();
	return entity:HasFocus() and not entity:IsControlledExternally();
end

function Actor:SetControllable(bIsControllable)
end

function Actor:SetFocus()
	local entity = self:GetEntity()
	if(entity) then
		entity:SetFocus();
	end
end

function Actor:HasFocus()
	local entity = self:GetEntity()
	if(entity) then
		return entity:HasFocus();
	end
end

-- whether its persistent. 
function Actor:IsPersistent()
	return self:GetEntity():IsPersistent();
end

-- whether the entity should be serialized to disk. 
function Actor:SetPersistent(bIsPersistent)
	self:GetEntity():SetPersistent(bIsPersistent);
end

-- @return the entity position if any
function Actor:GetRollPitchYaw()
	local obj = self.entity:GetInnerObject();
	if(obj) then
		return obj:GetField("roll", 0), obj:GetField("pitch", 0), obj:GetField("yaw", 0);
	end
	return 0,0,0;
end

function Actor:GetItemStack()
	return self.itemStack;
end

-- return the inner biped object
function Actor:GetInnerObject()
	local entity = self:GetEntity();
	if(entity) then
		return entity:GetInnerObject();
	end
end

-- return the animation instance. 
function Actor:GetAnimInstance()
	local entity = self:GetEntity();
	if(entity) then
		local obj = entity:GetInnerObject();
		if(obj) then
			local animInstance = obj:GetAttributeObject():GetChildAt(1,1);
			if(animInstance and animInstance:IsValid()) then
				return animInstance;
			end
		end
	end
end

function Actor:SetName(name)
	self.entity:SetName(name);
end

function Actor:GetName()
	return self.entity:GetName();
end

function Actor:SetVisible(bVisible)
	local entity = self:GetEntity();
	if(entity) then
		entity:SetVisible(bVisible);
	end
end

function Actor:SetHighlight(bHighlight)
	local entity = self:GetEntity();
	if(entity) then
		entity:SetHighlight(bHighlight);
	end
end

function Actor:SetBlockPos(bx, by, bz)
	local entity = self:GetEntity();
	if(entity) then	
		-- we will move using real position which fixed a bug that moveTo() does not work 
		-- when we are already inside the target block
		bx, by, bz = BlockEngine:real_min(bx+0.5, by, bz+0.5);
		entity:SetBlockPos(bx, by, bz);
	end
end

function Actor:SetPosition(targetX,targetY,targetZ)
	local entity = self:GetEntity();
	if(entity) then	
		entity:SetPosition(targetX,targetY,targetZ);
	end
end

-- @return the entity position if any
function Actor:GetPosition()
	return self.entity:GetPosition();
end

function Actor:SetFacing(facing)
	local entity = self:GetEntity();
	if(entity) then	
		entity:SetFacing(facing);
	end
end

function Actor:GetFacing()
	local entity = self:GetEntity()
	if(entity) then
		return entity:GetFacing();
	end
end

function Actor:GetAssetFile()
	local entity = self:GetEntity();
	return entity and entity:GetMainAssetPath();
end

function Actor:SetAssetFile(filename)
	local entity = self:GetEntity();
	if(entity) then	
		filename = PlayerAssetFile:GetFilenameByName(filename)
		if(entity.SetModelFile) then
			entity:SetModelFile(filename);
		else
			entity:SetMainAssetPath(filename);
		end
	end
end