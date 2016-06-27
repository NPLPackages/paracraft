--[[
Title: Damage source from Entity
Author(s): LiXizhi
Date: 2014/6/18
Desc: what kind of damage source
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Physics/DamageSourceEntity.lua");
local DamageSourceEntity = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld.DamageSourceEntity");
NPL.load("(gl)script/apps/Aries/Creator/Game/Physics/DamageSource.lua");
local DamageSource = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld.DamageSource")
-------------------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");

local DamageSourceEntity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld.DamageSource"), commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld.DamageSourceEntity"));

function DamageSourceEntity:ctor()
end

-- @param damageType
function DamageSourceEntity:Init(damageType, fromEntity)
	self.damageType = damageType;
	self.damageSourceEntity = fromEntity;
	return self;
end

function DamageSourceEntity:GetEntity()
    return self.damageSourceEntity;
end