--[[
Title: block rail detector
Author(s): LiXizhi
Date: 2014/6/17
Desc: block rail detector
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockRailDetector.lua");
local BlockRailDetector = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockRailDetector")
block.isRailBlock(block_id)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ContainerView.lua");
local ContainerView = commonlib.gettable("MyCompany.Aries.Game.Items.ContainerView");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local EntityRailcar = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityRailcar")
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.blocks.BlockRailBase"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockRailDetector"));

-- register
block_types.RegisterBlockClass("BlockRailDetector", block);

function block:ctor()
	self.canHasPower = true;
end

function block:canProvidePower()
    return true;
end

function block:tickRate()
	return 20;
end

function block:OnBlockAdded(x, y, z)
	block._super.OnBlockAdded(self, x, y, z);
	if(not GameLogic.isRemote) then
		self:SetStateIfEntityCollided(x,y,z, BlockEngine:GetBlockData(x,y,z));
	end
end

-- Returns true if the block is emitting indirect/weak redstone power on the specified side. If isBlockNormalCube
-- returns true, standard redstone propagation rules will apply instead and this will not be called. Note that the side is reversed
function block:isProvidingWeakPower(x, y, z, direction)
	if(BlockEngine:GetBlockData(x,y,z) >=16) then
		return 15;
	else
		return 0;
	end
end

-- Returns true if the block is emitting direct/strong redstone power on the specified side. 
-- side. 
function block:isProvidingStrongPower(x, y, z, direction)
	if(BlockEngine:GetBlockData(x,y,z) < 16) then
		return 0;
	else
		-- only strongly power the block beneath it
		if(direction == 4) then
			return 1;
		else
			return 0;
		end
	end
end

-- some block like command blocks, may has an internal state number(like its last output result)
-- and some block may use its nearby blocks' state number to generate redstone output or other behaviors.
-- @return nil or a number between [0-15]
function block:GetInternalStateNumber(x,y,z)
	if (BlockEngine:GetBlockData(x,y,z) >= 16) then
        local entities = self:GetCollidedEntities(x,y,z, nil);
		if (entities and #entities > 0) then
			bIsEntityCollided = true;
			local max_value = 0;
			for i = 1, #entities do
				max_value = math.max(max_value, ContainerView.CalcRedstoneFromInventory(entities[i]) or 0);
			end 
		    return max_value;
        end
    end
    return 0;
end

-- Triggered whenever an entity collides with this block (enters into the block).
function block:OnEntityCollided(x,y,z, entity, deltaTime)
	if(not GameLogic.isRemote) then
		local data = BlockEngine:GetBlockData(x,y,z);

		if (data < 16) then
			self:SetStateIfEntityCollided(x,y,z, data);
		end
	end
end

-- @param entity_class: the class
function block:GetCollidedEntities(x,y,z, entity_class)
	local rail_border = 0.125;
	x, y, z = BlockEngine:real(x,y,z);
	local max_border = BlockEngine.blocksize - rail_border;
    local entities = EntityManager.GetEntitiesByAABBOfType(entity_class, ShapeAABB:new_from_pool(x + rail_border, y, z + rail_border, x + max_border, y + max_border, z + max_border));
	return entities;
end

-- Update the detector rail power state if a car enter, stays or leave the block.
function block:SetStateIfEntityCollided(x,y,z, data)
    local hasPower = data>=16;
    local bIsEntityCollided = false;
    
    local entities = self:GetCollidedEntities(x,y,z, EntityRailcar);
    if (entities and #entities > 0) then
        bIsEntityCollided = true;
    end

    if (bIsEntityCollided and not hasPower) then
        BlockEngine:SetBlockData(x, y, z, data + 16, 3);
        BlockEngine:NotifyNeighborBlocksChange(x, y, z, self.id);
        BlockEngine:NotifyNeighborBlocksChange(x, y - 1, z, self.id);
    end

    if (not bIsEntityCollided and hasPower) then
        BlockEngine:SetBlockData(x, y, z, data - 16, 3);
        BlockEngine:NotifyNeighborBlocksChange(x, y, z, self.id);
        BlockEngine:NotifyNeighborBlocksChange(x, y - 1, z, self.id);
    end

    if (bIsEntityCollided) then
        GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self.id, self:tickRate());
    end

    -- BlockEngine:NotifyComparatorAtBlock(x, y, z, self.id);
end


function block:updateTick(x,y,z)
	if(not GameLogic.isRemote) then
		local data = BlockEngine:GetBlockData(x,y,z);
		if (data >= 16) then
			self:SetStateIfEntityCollided(x,y,z, data);
		end
	end
end