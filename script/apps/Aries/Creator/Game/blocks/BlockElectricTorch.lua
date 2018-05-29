--[[
Title: Electric Torch
Author(s): LiXizhi
Date: 2013/12/3
Desc: Block Electric Torch
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockElectricTorch.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockElectricTorch")
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockElectricTorch"));
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names")

-- register
block_types.RegisterBlockClass("BlockElectricTorch", block);


function block:ctor()
	-- whether it emit light. 
	self.torchActive = self.light;
	self.ProvidePower = true;
end

function block:Init()
	
end

-- tick immediately. 
function block:tickRate()
	return 2;
end

-- user data to direction side
local data_to_side = {
	[1] = 1, [2] = 2,[3] = 0,[4] = 3,[5] = 4,[6] = 5,
}

local data_to_side_op = {
	[1] = 0, [2] = 3,[3] = 1,[4] = 2,[5] = 5,[6] = 4,
}

-- virtual: Checks to see if its valid to put this block at the specified coordinates.
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

function block:OnToggle(bx, by, bz)
end

function block:OnBlockAdded(x, y, z)
	if(not GameLogic.isRemote) then
		local is_indirectly_powered = self:isWeaklyPowered(x,y,z);

		if ( (self.torchActive and is_indirectly_powered) or (not self.torchActive and not is_indirectly_powered)) then
			GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self.id, self:tickRate());
		else
			if (self.torchActive) then
				BlockEngine:NotifyNeighborBlocksChange(x, y - 1, z, self.id);
				BlockEngine:NotifyNeighborBlocksChange(x, y + 1, z, self.id);
				BlockEngine:NotifyNeighborBlocksChange(x - 1, y, z, self.id);
				BlockEngine:NotifyNeighborBlocksChange(x + 1, y, z, self.id);
				BlockEngine:NotifyNeighborBlocksChange(x, y, z - 1, self.id);
				BlockEngine:NotifyNeighborBlocksChange(x, y, z + 1, self.id);
			end
		end
	end
end

function block:OnBlockRemoved(x,y,z, last_id, last_data)
	if(not GameLogic.isRemote) then
		if (self.torchActive) then
			BlockEngine:NotifyNeighborBlocksChange(x, y - 1, z, self.id);
			BlockEngine:NotifyNeighborBlocksChange(x, y + 1, z, self.id);
			BlockEngine:NotifyNeighborBlocksChange(x - 1, y, z, self.id);
			BlockEngine:NotifyNeighborBlocksChange(x + 1, y, z, self.id);
			BlockEngine:NotifyNeighborBlocksChange(x, y, z - 1, self.id);
			BlockEngine:NotifyNeighborBlocksChange(x, y, z + 1, self.id);
		end
	end
end

-- if a still water block's neighbor changes, we will turn this water to flow water. 
function block:OnNeighborChanged(x,y,z,neighbor_block_id)
	if(not GameLogic.isRemote) then
		-- TODO: remove block when no neighbor is solid. 
		local is_indirectly_powered = self:isWeaklyPowered(x,y,z);

		if ( (self.torchActive and is_indirectly_powered) or (not self.torchActive and not is_indirectly_powered)) then
			GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self.id, self:tickRate());
		end
	end
end

-- Can this block provide power. 
function block:canProvidePower()
    return true;
end

-- torch block is a diode, which is only weakly powered by the block that it sits on. 
function block:isWeaklyPowered(x,y,z)
    local data = ParaTerrain.GetBlockUserDataByIdx(x,y,z);
	local dir = data_to_side[data];

	-- Ingore top block: dir== 5 and BlockEngine:hasWeakPowerOutputTo(x,y+1,z,5)
	if( dir== 4 and BlockEngine:hasWeakPowerOutputTo(x,y-1,z,5) or
		dir== 0 and BlockEngine:hasWeakPowerOutputTo(x-1,y,z,1) or
		dir== 1 and BlockEngine:hasWeakPowerOutputTo(x+1,y,z,0) or
		dir== 2 and BlockEngine:hasWeakPowerOutputTo(x,y,z-1,3) or
		dir== 3 and BlockEngine:hasWeakPowerOutputTo(x,y,z+1,2) ) then
		return true;
	end
	return false;
end

-- providing power except for the block that it sits on. 
function block:isProvidingWeakPower(x, y, z, direction)
	if (not self.torchActive) then
        return 0;
    else
        local data = ParaTerrain.GetBlockUserDataByIdx(x,y,z);
		if(data_to_side[data] == direction) then
			return 0;
		else
			return 15;
		end
    end
end

-- only provide strong power to the top block
function block:isProvidingStrongPower(x, y, z, direction)
	if(direction == 5) then
		return self:isProvidingWeakPower(x, y, z, direction);
	else
		return 0;
	end
end

-- revert back to unpressed state
function block:updateTick(x,y,z)
	if(not GameLogic.isRemote) then
		local data = ParaTerrain.GetBlockUserDataByIdx(x,y,z);

		local is_indirectly_powered = self:isWeaklyPowered(x,y,z);

		if (self.torchActive) then
			if(is_indirectly_powered) then
				-- turn it off
				BlockEngine:SetBlock(x,y,z,names.Electric_Torch, data, 3);
			end
		else
			if(not is_indirectly_powered) then
				-- turn it on
				BlockEngine:SetBlock(x,y,z,names.Electric_Torch_On, data, 3);
			end
		end
	end
end

function block:RotateBlockData(blockData, angle, axis)
	return self:RotateBlockDataUsingModelFacing(blockData, angle, axis);
end
