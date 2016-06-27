--[[
Title: Damage source
Author(s): LiXizhi
Date: 2014/6/18
Desc: what kind of damage source
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Physics/DamageSource.lua");
local DamageSource = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld.DamageSource")
DamageSource:StaticInit();
local ds = DamageSource:CausePlayerDamage(player)
-------------------------------------------------------
]]
local DamageSourceEntity = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld.DamageSourceEntity");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");

local DamageSource = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld.DamageSource"));

function DamageSource:ctor()
end

-- static function
function DamageSource:StaticInit()
	if(self.generic) then
		return;
	end
	self.generic = DamageSource:new():Init("generic");
	self.outOfWorld = DamageSource:new():Init("outOfWorld");
	self.fall = DamageSource:new():Init("fall");
	self.cactus = DamageSource:new():Init("cactus");
	self.inWall = DamageSource:new():Init("inWall");
	self.drown = DamageSource:new():Init("drown");
	self.starve = DamageSource:new():Init("starve");
	self.inFire = DamageSource:new():Init("inFire");
	self.fallingBlock = DamageSource:new():Init("fallingBlock");
	self.anvil = DamageSource:new():Init("anvil");

	NPL.load("(gl)script/apps/Aries/Creator/Game/Physics/DamageSourceEntity.lua");
end

-- returns an DamageSourceEntity of type player
function DamageSource:CausePlayerDamage(playerEntity)
    return DamageSourceEntity:new():Init("player", playerEntity);
end


-- @param damageType
function DamageSource:Init(damageType)
	self.damageType = damageType
	return self;
end

function DamageSource:GetEntity()
    return;
end


