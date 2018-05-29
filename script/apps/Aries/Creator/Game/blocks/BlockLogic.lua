--[[
Title: Electric Logic Based Block
Author(s): LiXizhi
Date: 2013/1/23
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockLogic.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockLogic")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");


local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockLogic"));


-- register
block_types.RegisterBlockClass("BlockLogic", block);

function block:ctor()
	self.ProvidePower = true;
end

function block:Init()
	
end

-- get direction by user data. this is 
function block:getDirection(data)
	return band(data, 3);
end


-- virtual: Checks to see if its valid to put this block at the specified coordinates. Args: world, x, y, z
function block:canPlaceBlockAt(x,y,z)
	return true;
end

function block:GetMetaDataFromEnv(blockX, blockY, blockZ, side, side_region, camx,camy,camz, lookat_x,lookat_y,lookat_z)
	return Direction.GetDirection2DFromCamera(camx,camy,camz, lookat_x,lookat_y,lookat_z)
end

function block:OnBlockPlacedBy(x,y,z, entity)
	if(not GameLogic.isRemote) then
		local data = BlockEngine:GetBlockData(x,y,z)
		local hasInput = self:isGettingInput(x,y,z, data);	
		if (hasInput) then
			GameLogic.GetSim():ScheduleBlockUpdate(x,y,z, self.id, 1);
		end
	end
end


-- virtual 
function block:getTickRateByData(data)
	return 10;
end

function block:IsLogicDisabled(x,y,z,data)
    return false;
end

function block:isGettingInput(x,y,z,data)
    return self:getInputPowerLevel(x,y,z,data) > 0;
end

-- Returns the signal strength at one input of the block. 
function block:getInputPowerLevel(x,y,z,data)
    local dir_output = self:getDirection(data);
	local dir_input = Direction.directionToOpFacing[dir_output];
    local x1 = x + Direction.offsetX[dir_input];
    local z1 = z + Direction.offsetZ[dir_input];

	local src_block = BlockEngine:GetBlock(x1,y,z1);
	if(src_block) then
		local src_state = src_block:GetInternalStateNumber(x1,y,z1);
		if(src_state) then
			-- source state has priority over weak power
			return src_state;
		else
			local input_power = BlockEngine:getWeakPowerOutputTo(x1, y, z1, dir_output);
			if(input_power >= 15) then
				return input_power;
			else
				-- wire power does not degrade when input to this block. 
				if(BlockEngine:GetBlockId(x1, y, z1) == block_types.names.Wire) then
					return math.max(input_power, BlockEngine:GetBlockData(x1, y, z1))
				else
					return input_power;
				end
			end
		end
	end
	return 0;
end

-- Returns true if the block is emitting direct/strong power to the specified side. 
function block:isProvidingStrongPower(x,y,z,side)
    return self:isProvidingWeakPower(x,y,z,side);
end

function block:IsInPoweredState(data)
    return self.isPoweredOn;
end

function block:GetOutputPowerLevel(x,y,z,data)
    return 15;
end

function block:isProvidingWeakPower(x,y,z,side)
    local data = BlockEngine:GetBlockData(x,y,z);

    if ( not self:IsInPoweredState(data)) then
        return 0;
    else
        local dir = self:getDirection(data);

        if( (dir== 0 and side == 0 ) or 
			(dir== 1 and side == 1 ) or
			(dir== 2 and side == 2 ) or 
			(dir== 3 and side == 3 ) ) then
			return self:GetOutputPowerLevel(x,y,z,data);
		else
			return 0;
		end
    end
end

function block:canBlockProvidePower(block_id)
    local block = block_types.get(block_id);
    return block and block:canProvidePower();
end

function block:canProvidePower()
	return true;
end

function block:getBlockPowerLevelToDirection(x,y,z,side)
    local block_id = BlockEngine:GetBlockId(x, y, z);
	
    if (self:canBlockProvidePower(block_id)) then
		if(block_id == block_types.names.Wire) then
			return BlockEngine:GetBlockData(x, y, z);
		else
			return BlockEngine:isBlockProvidingStrongPowerTo(x, y, z, side);
		end
	else
		return 0;
	end
end


function block:GetMaxPowerInputForDirection(x,y,z,data)
    local dir = self:getDirection(data);

    if(dir == 0 or dir == 1) then
		return math.max(self:getBlockPowerLevelToDirection(x, y, z + 1, 2), self:getBlockPowerLevelToDirection(x, y, z - 1, 3));
	elseif(dir == 2 or dir == 3) then
        return math.max(self:getBlockPowerLevelToDirection(x - 1, y, z, 1), self:getBlockPowerLevelToDirection(x + 1, y, z, 0));
	else
		return 0;
    end
end

function block:DoNotifyNeighborBlocks(x,y,z)
    local dir = self:getDirection(BlockEngine:GetBlockData(x, y, z));

    if (dir == 0) then
        BlockEngine:OnNeighborBlockChange(x - 1, y, z, self.id);
        BlockEngine:NotifyNeighborBlocksChangeNoSide(x - 1, y, z, self.id, 1);
	elseif (dir == 1) then
        BlockEngine:OnNeighborBlockChange(x + 1, y, z, self.id);
        BlockEngine:NotifyNeighborBlocksChangeNoSide(x + 1, y, z, self.id, 0);
    elseif (dir == 3) then
        BlockEngine:OnNeighborBlockChange(x, y, z + 1, self.id);
        BlockEngine:NotifyNeighborBlocksChangeNoSide(x, y, z + 1, self.id, 2);
    elseif (dir == 2) then
        BlockEngine:OnNeighborBlockChange(x, y, z - 1, self.id);
        BlockEngine:NotifyNeighborBlocksChangeNoSide(x, y, z - 1, self.id, 3);
    end
end

function block:OnBlockAdded(x,y,z)
	if(not GameLogic.isRemote) then
		self:DoNotifyNeighborBlocks(x,y,z);
	end
end

-- Lets the block know when one of its neighbor changes. 
function block:OnNeighborChanged(x, y, z, from_block_id)
	if(not GameLogic.isRemote) then
		self:OnLogicBlockNeighborChange(x, y, z, from_block_id);
	end
end

function block:OnLogicBlockNeighborChange(x, y, z, from_block_id)
    local data = BlockEngine:GetBlockData(x, y, z);

    if (not self:IsLogicDisabled(x, y, z, data)) then
        local hasInput = self:isGettingInput(x, y, z, data);

        if ((self.isPoweredOn and not hasInput or not self.isPoweredOn and hasInput) and not GameLogic.GetSim():isBlockTickScheduledThisTick(x, y, z, self.id)) then
            local priority = -1;

			if (self:IsConnectedToLogicBlock(x, y, z, data)) then
                priority = -3;
            elseif (self.isPoweredOn) then
                priority = -2;
            end
            GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self.id, self:getTickRateByData(data), priority);
        end
    end
end

function block:isElectricLogicBlockID(block_id)
    return block_types.blocks.Repeater:IsAssociatedOnOffBlock(block_id); 
end

function block:IsAssociatedOnOffBlock(block_id)
    return block_id == self:GetOnBlockID() or block_id == self:GetOffBlockID();
end

function block:IsConnectedToLogicBlock(x,y,z,data)
    local dir = self:getDirection(data);

    if (self:isElectricLogicBlockID(BlockEngine:GetBlockId(x + Direction.offsetX[dir], y, z + Direction.offsetZ[dir]))) then
        local data1 = BlockEngine:GetBlockData(x + Direction.offsetX[dir], y, z + Direction.offsetZ[dir]);
		local dir1 = self:getDirection(data1);
        return  dir1 ~= dir;
    else
        return false;
    end
end

-- Ticks the block if it's been scheduled
function block:updateTick(x,y,z)
	if(not GameLogic.isRemote) then
		local data = ParaTerrain.GetBlockUserDataByIdx(x, y, z);

		if (not self:IsLogicDisabled(x, y, z, data)) then
			local hasInput = self:isGettingInput(x, y, z, data);

			if (self.isPoweredOn and not hasInput) then
				BlockEngine:SetBlock(x, y, z, self:GetOffBlockID(), data);
			elseif (not self.isPoweredOn) then
				BlockEngine:SetBlock(x, y, z, self:GetOnBlockID(), data);

				if (not hasInput) then
					GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self:GetOnBlockID(), self:getTickRateByData(data), -1);
				end
			end
		end
	end
end