--[[
Title: CollisionSensor
Author(s): LiXizhi
Date: 2014/2/17
Desc: Block CollisionSensor
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockCollisionSensor.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockCollisionSensor")
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.blocks.BlockEntityBase"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockCollisionSensor"));

-- register
block_types.RegisterBlockClass("BlockCollisionSensor", block);

local EnumMobType = {
	everything = 1, mobs = 2, players = 3,
}

function block:ctor()
	-- self.ProvidePower = true;
	self.triggerMobType = EnumMobType.everything;
end

function block:Init()
end

function block:tickRate()
	return 10;
end

function block:IsCollidingWithEntity(x,y,z,entityPlayer, deltaTime)
	local facing = BlockEngine:GetBlockData(x,y,z);
	local px,py,pz = entityPlayer:GetNextPosition(deltaTime);
	--local px,py,pz = entityPlayer:GetPosition();

	local cx, cy, cz = BlockEngine:real(x,y,z);
	local radius = entityPlayer:GetPhysicsRadius();
	local height = entityPlayer:GetPhysicsHeight();
	-- width of the sensor. 
	local sensor_thickness = 0.1;

	if(facing == 0) then
		-- top 
		return (py + height) > (cy + BlockEngine.half_blocksize - sensor_thickness);
	elseif(facing == 1) then
		-- front
		return (pz - radius) < (cz - BlockEngine.half_blocksize + sensor_thickness);
	elseif(facing == 2) then
		-- bottom
		return (py) < (cy - BlockEngine.half_blocksize + sensor_thickness);
	elseif(facing == 3) then
		-- left
		return (px - radius) < (cx - BlockEngine.half_blocksize + sensor_thickness);
	elseif(facing == 4) then
		-- right
		return (px + radius) > (cx + BlockEngine.half_blocksize - sensor_thickness);
	elseif(facing == 5) then
		-- back
		return (pz + radius) > (cz + BlockEngine.half_blocksize - sensor_thickness);
	end
end


-- virtual:
function block:OnEntityCollided(x,y,z, entityPlayer, deltaTime)
	if(not GameLogic.isRemote) then
		local sensor_entity = self:GetBlockEntity(x,y,z);    
		if(sensor_entity) then
			if(not sensor_entity.lastTriggerPlayer or sensor_entity.lastTriggerPlayer ~=entityPlayer) then
				if(self:IsCollidingWithEntity(x,y,z,entityPlayer, deltaTime)) then
					sensor_entity.lastTriggerPlayer = entityPlayer;
					EntityManager.SetLastTriggerEntity(entityPlayer);
					sensor_entity:ExecuteCommand(entityPlayer);
					GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self.id, self:tickRate());
				end
			end
		end
	end
end


-- when ever this block is about to be destroyed and one may call this function to drop as an item first. 
-- @Note: this function should always be called before item is removed. 
function block:DropBlockAsItem(x,y,z)
	local sensor_entity = self:GetBlockEntity(x,y,z);    
	if(sensor_entity and sensor_entity.ExecuteCommand) then
		sensor_entity:ExecuteCommand(nil);
	end
end

-- revert back to unpressed state
function block:updateTick(x,y,z)
	if(not GameLogic.isRemote) then
		local sensor_entity = self:GetBlockEntity(x,y,z);    
		if(sensor_entity and sensor_entity.lastTriggerPlayer) then
			local bFoundPlayer;
			local entities = EntityManager.GetEntitiesInBlock(x,y,z);
			if (entities and next(entities)) then
				for entity, _ in pairs(entities) do
					if (entity == sensor_entity.lastTriggerPlayer) then
						if(self:IsCollidingWithEntity(x,y,z,entity)) then
							bFoundPlayer = true;
						end
						break;
					end
				end
			end
			if(bFoundPlayer) then
				GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self.id, self:tickRate());
			else
				sensor_entity.lastTriggerPlayer = nil;
			end
		end
	end
end
