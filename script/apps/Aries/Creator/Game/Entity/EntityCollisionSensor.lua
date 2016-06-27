--[[
Title: CollisionSensor Entity
Author(s): LiXizhi
Date: 2014/2/12
Desc: replace the first block with second block in bag. 
try the block below this block if second inventory slot does not exist. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCollisionSensor.lua");
local EntityCollisionSensor = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCollisionSensor")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCommandBlock.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/NeuronManager.lua");
NPL.load("(gl)script/ide/math/ShapeAABB.lua");
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
local NeuronManager = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronManager");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCommandBlock"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCollisionSensor"));

-- class name
Entity.class_name = "EntityCollisionSensor";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;
-- command line text

function Entity:ctor()
	
end

-- @param Entity: the half radius of the object. 
function Entity:init()
	if(not Entity._super.init(self)) then
		return
	end
	-- TODO: 
	return self;
end

function Entity:Refresh()
end

-- return empty collision AABB, since sensor does not have physics. 
function Entity:GetCollisionAABB()
	if(not self.aabb) then
		self.aabb = ShapeAABB:new();
	end
	return self.aabb;
end

function Entity:OnNeighborChanged(x,y,z, from_block_id)
	return Entity._super.OnNeighborChanged(self, x,y,z, from_block_id);
end

-- the title text to display (can be mcml)
function Entity:GetCommandTitle()
	return "命令或物品脚本将在人物碰撞本方块时执行"
end

function Entity:HasCommand()
	return true;
end
