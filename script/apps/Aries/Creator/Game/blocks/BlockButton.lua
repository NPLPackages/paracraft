--[[
Title: Button
Author(s): LiXizhi
Date: 2013/12/3
Desc: Block Button
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockButton.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockButton")
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockButton"));

-- register
block_types.RegisterBlockClass("BlockButton", block);

-- Whether this button is sensible to arrows, used by wooden buttons.
block.sensible = false;

function block:ctor()
	self.ProvidePower = true;
end

function block:Init()
	
end

function block:tickRate()
	return 20;
end

local op_side_to_data = {
	[0] = 1,[1] = 3,[2] = 4,[3] = 2,[4] = 6,[5] = 5,
}

-- user data to direction side
local data_to_side = {
	[0] = 0, [1] = 1, [2] = 2,[3] = 0,[4] = 3,[5] = 4,[6] = 5,[7] = 0,
}

function block:GetMetaDataFromEnv(blockX, blockY, blockZ, side, side_region, camx,camy,camz, lookat_x,lookat_y,lookat_z)
	return op_side_to_data[side or 5] or 1;
end

-- virtual: Checks to see if its valid to put this block at the specified coordinates. Args: world, x, y, z
function block:canPlaceBlockOnSide(x,y,z,side)
	if(side) then
		if(block._super.canPlaceBlockOnSide(self, x,y,z, side)) then
			side = BlockEngine:GetOppositeSide(side);
			local x_, y_, z_ = BlockEngine:GetBlockIndexBySide(x,y,z,side)
			local below_block_id = ParaTerrain.GetBlockTemplateByIdx(x_, y_, z_);
			if(below_block_id) then
				local below_block = block_types.get(below_block_id);
				if(below_block and below_block.solid) then
					-- can only be placed on solid block. 
					return true;
				end	
			end
		end
	else
		return true;
	end
end

-- if a still water block's neighbor changes, we will turn this water to flow water. 
function block:OnNeighborChanged(x,y,z,neighbor_block_id)
	-- TODO: remove block when no neighbor is solid. 
end

-- Can this block provide power. 
function block:canProvidePower()
    return true;
end

function block:isProvidingWeakPower(x, y, z, direction)
	if(ParaTerrain.GetBlockUserDataByIdx(x,y,z)>=8) then
		return 15;
	else
		return 0;
	end
end

-- Returns true if the block is emitting direct/strong electric power on the specified side. 
function block:isProvidingStrongPower(x, y, z, direction)
	local data = ParaTerrain.GetBlockUserDataByIdx(x,y,z)
    if (data <= 8) then
        return 0;
    else
        if((data_to_side[data-8]) == direction) then
			return 15;
		else
			return 0;
		end
    end
end

-- virtual function: some signal is received. do not know the source. x,y,z is this block.
function block:NotifyNeighborBlocksByDir(x, y, z, dir)
    BlockEngine:NotifyNeighborBlocksChange(x, y, z, self.id);
	if(dir>=8) then
		dir = dir - 8;
	end
    dir = data_to_side[dir];
    if (dir == 0) then
        BlockEngine:NotifyNeighborBlocksChange(x - 1, y, z, self.id);
    elseif (dir == 1) then
        BlockEngine:NotifyNeighborBlocksChange(x + 1, y, z, self.id);
    elseif (dir == 2) then
        BlockEngine:NotifyNeighborBlocksChange(x, y, z - 1, self.id);
    elseif (dir == 3) then
        BlockEngine:NotifyNeighborBlocksChange(x, y, z + 1, self.id);
    elseif (dir == 4) then
        BlockEngine:NotifyNeighborBlocksChange(x, y - 1, z, self.id);
    else
        BlockEngine:NotifyNeighborBlocksChange(x, y + 1, z, self.id);
	end
    return true;
end

-- goto pressed state and then schedule tickUpdate to go off again after some ticks
function block:OnActivated(x, y, z, entity)
	local data = ParaTerrain.GetBlockUserDataByIdx(x, y, z);
	if(data >=8) then
		return true;
	else
		if(entity) then
			EntityManager.SetLastTriggerEntity(entity);
		end
		BlockEngine:SetBlockData(x,y,z, data+8);
		self:NotifyNeighborBlocksByDir(x, y, z, data);
		GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self.id, self:tickRate());

		-- do neuron activation
		block._super.OnActivated(self, x, y, z, entity);
		return true;
	end
end

function block:OnToggle(x, y, z)
end

-- revert back to unpressed state
function block:updateTick(x,y,z)
	if (not GameLogic.isRemote) then
		local data = ParaTerrain.GetBlockUserDataByIdx(x,y,z);

		if (data > 8) then
			local dir = data - 8;
			if (true or self.sensible) then
				BlockEngine:SetBlockData(x,y,z, dir);
				self:NotifyNeighborBlocksByDir(x, y, z, dir);
			end
		end
	end
end

function block:RotateBlockData(blockData, angle, axis)
	return self:RotateBlockDataUsingModelFacing(blockData, angle, axis);
end

