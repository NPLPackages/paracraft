--[[
Title: PressurePlate
Author(s): LiXizhi
Date: 2013/12/3
Desc: Block PressurePlate
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockPressurePlate.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockPressurePlate")
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockPressurePlate"));

-- register
block_types.RegisterBlockClass("BlockPressurePlate", block);

local EnumMobType = {
	everything = 1, mobs = 2, players = 3,
}

function block:ctor()
	self.ProvidePower = true;
	self.triggerMobType = EnumMobType.everything;
end

function block:Init()
end

function block:tickRate()
	return 20;
end

function block:GetMetaDataFromEnv(blockX, blockY, blockZ, side, side_region, camx,camy,camz, lookat_x,lookat_y,lookat_z)
	return 0;
end

-- if a still water block's neighbor changes, we will turn this water to flow water. 
function block:OnNeighborChanged(x,y,z,neighbor_block_id)
	-- TODO: remove block when no neighbor is solid. 
end

-- @param weight: (0-15). 
-- Return the metadata to be set because of it.
function block:getMetaFromWeight(weight)
    if(weight > 0) then
		return 1;
	else
		return 0;
	end
end

-- get power level from metadata. 
-- @return power level (0-15)
function block:getPowerSupply(data)
    if(data == 1) then
		return 15;
	else
		return 0;
	end
end

-- Returns the current state of the pressure plate. Returns a value between 0 and 15 based on the number of items on it.
-- @return states, the trigger entity
function block:getPlateState(x,y,z)
    local entities;

    if (self.triggerMobType == EnumMobType.everything) then
        entities = EntityManager.GetEntitiesInBlock(x,y,z);
    elseif (self.triggerMobType == EnumMobType.mobs) then
        entities = EntityManager.GetEntitiesInBlock(x,y,z);
    elseif (self.triggerMobType == EnumMobType.players) then
        entities = EntityManager.GetEntitiesInBlock(x,y,z);
    end

    if (entities and next(entities)) then
		for entity, _ in pairs(entities) do
			if (entity:doesEntityTriggerPressurePlate()) then
                return 15, entity;
            end
		end
    end
    return 0;
end

-- Can this block provide power. 
function block:canProvidePower()
    return true;
end

function block:isProvidingWeakPower(x, y, z, direction)
	return self:getPowerSupply(BlockEngine:GetBlockData(x,y,z));
	
end

-- Returns true if the block is emitting direct/strong electric power on the specified side. 
function block:isProvidingStrongPower(x, y, z, direction)
	if(direction == 4) then
		return self:getPowerSupply(BlockEngine:GetBlockData(x,y,z));
	else
		return 0;
	end
end

function block:DoNotifyNeighbors(x,y,z)
	BlockEngine:NotifyNeighborBlocksChange(x,y,z, self.id);
	BlockEngine:NotifyNeighborBlocksChange(x,y-1,z, self.id);
end

function block:OnBlockRemoved(x, y, z, last_id, last_data)
	if(not GameLogic.isRemote) then
		if (self:getPowerSupply(last_data) > 0) then
			self:DoNotifyNeighbors(x,y,z)
		end
	end
end


-- virtual:
function block:OnEntityCollided(x,y,z, entity)
	if (not GameLogic.isRemote) then
		local power = self:getPowerSupply(BlockEngine:GetBlockData(x,y,z));

		if ( power == 0 or not GameLogic.GetSim():isBlockTickScheduled(x,y,z)) then
			self:setStateIfEntityInteractsWithPlate(x,y,z,power);
		end
	end
end

-- Checks if there are entities on the plate. If a entity is on the plate and it is off, it turns it on, and vice versa.
function block:setStateIfEntityInteractsWithPlate(x,y,z,power)
    local cur_power, entity = self:getPlateState(x,y,z);
    
    if (power ~= cur_power) then
		if(entity) then
			EntityManager.SetLastTriggerEntity(entity);
		end
		self:play_toggle_sound();
        BlockEngine:SetBlockData(x,y,z, self:getMetaFromWeight(cur_power));
		
		if(cur_power > 0) then
			-- neuron activation
			block._super.OnActivated(self, x, y, z, entity); 
		end
        self:DoNotifyNeighbors(x,y,z);
    end

    if (cur_power > 0) then
        GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self.id, self:tickRate());
    end
end

-- goto pressed state and then schedule tickUpdate to go off again after some ticks
function block:OnActivated(x, y, z)
end

function block:OnToggle(x, y, z)
end

-- revert back to unpressed state
function block:updateTick(x,y,z)
	if (not GameLogic.isRemote) then
		local power = self:getPowerSupply(BlockEngine:GetBlockData(x,y,z));

		if (power > 0) then
			self:setStateIfEntityInteractsWithPlate(x,y,z,power);
		end
	end
end



