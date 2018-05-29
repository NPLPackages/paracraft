--[[
Title: powered block rail
Author(s): LiXizhi
Date: 2014/6/12
Desc: powered rail blocks. No electricity to decelerate. electric powered to accelerate. 
It behaves similar to electric wires. However, it only has on/off states(instead of 16 power level as wires),
hence it will check for neighbor power source for as much as 16 blocks in both directions when neighbor changes. 
(Each powered rail is responsible to propogate on/off state to at most 16 blocks in both directions.)
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockRailPowered.lua");
local BlockRailPowered = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockRailPowered")
block.isRailBlock(block_id)
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.blocks.BlockRailBase"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockRailPowered"));

-- register
block_types.RegisterBlockClass("BlockRailPowered", block);

function block:ctor()
	self.canHasPower = true;
end

function block:Init()
end

-- test if it is getting powered from neighbor block. 
function block:IsRailGettingPowered2(x, y, z, bInverseDir, nStepCount, lastShapeData)
    local block_id = BlockEngine:GetBlockId(x, y, z);

    if (block_id == self.id) then
        local blockData = BlockEngine:GetBlockData(x, y, z);
		local shapeData = blockData;
		if(blockData>=16) then
			shapeData = blockData - 16;
		end

        if (lastShapeData == 1 and (shapeData == 2 or shapeData == 10 or shapeData == 8)) then
            return false;
        end

        if (lastShapeData == 2 and (shapeData == 1 or shapeData == 7 or shapeData == 9)) then
            return false;
        end

        if (blockData >= 16) then
            if (BlockEngine:isBlockIndirectlyGettingPowered(x, y, z)) then
                return true;
            end
            return self:IsRailGettingPowered1(x, y, z, blockData, bInverseDir, nStepCount + 1);
        end
    end
    return false;
end

-- it is much like a electric wire and will at most transmit 8 double blocks
-- @param nStepCount:
function block:IsRailGettingPowered1(x, y, z, blockData, bInverseDir, nStepCount)
	-- check if max rail power transmit distance is reached. 
	if (nStepCount >= 8) then
		-- it is actually 16 blocks, since 1,2,1,2,...: 8*2=16
        return false;
    else
        local shapeData = blockData;
		if(blockData>=16) then
			shapeData = blockData - 16;
		end
		-- whether to test the block below the current block, true to normal rail, false for slope rail.
        local bTestUndergroundBlock = true;

        if(shapeData == 2) then
            if (bInverseDir) then
                z = z + 1;
            else
                z = z - 1;
            end
        elseif(shapeData == 1) then
            if (bInverseDir) then
                x = x-1;
            else
                x = x+1;
            end
        elseif(shapeData == 7) then
            if (bInverseDir) then
                x = x-1;
            else
                x = x + 1;
                y = y + 1;
                bTestUndergroundBlock = false;
            end
            shapeData = 1;
        elseif(shapeData == 9) then
            if (bInverseDir) then
                x = x - 1;
                y = y + 1;
                bTestUndergroundBlock = false;
            else
                x = x+1;
            end
            shapeData = 1;
        elseif(shapeData == 10) then
            if (bInverseDir) then
                z = z+1;
            else
                z = z-1;
                y=y+1;
                bTestUndergroundBlock = false;
            end
            shapeData = 2;
        elseif(shapeData == 8) then
            if (bInverseDir) then
                z = z+1;
                y = y+1;
                bTestUndergroundBlock = false;
            else
                z=z-1;
            end
            shapeData = 2;
        end

        if(self:IsRailGettingPowered2(x, y, z, bInverseDir, nStepCount, shapeData)) then
			return true;
		elseif(bTestUndergroundBlock and self:IsRailGettingPowered2(x, y - 1, z, bInverseDir, nStepCount, shapeData)) then
			return true;
		end
	end    
end

-- virtual: 
function block:UpdateDirData(x, y, z, blockData, shapeData, neighbor_block_id)
	
	local hasAnyPowered = BlockEngine:isBlockIndirectlyGettingPowered(x, y, z);
    hasAnyPowered = hasAnyPowered or self:IsRailGettingPowered1(x, y, z, blockData, true, 0) or self:IsRailGettingPowered1(x, y, z, blockData, false, 0);
    local bPowerStateChanged = false;

    if (hasAnyPowered and (blockData < 16)) then
        BlockEngine:SetBlockData(x, y, z, shapeData + 16, 3);
        bPowerStateChanged = true;
    elseif (not hasAnyPowered and (blockData > 16)) then
        BlockEngine:SetBlockData(x, y, z, shapeData, 3);
        bPowerStateChanged = true;
    end

    if (bPowerStateChanged) then
        BlockEngine:NotifyNeighborBlocksChange(x, y - 1, z, self.id);

		-- for sloped rail
        if (shapeData >=7 and shapeData<=10) then
            BlockEngine:NotifyNeighborBlocksChange(x, y + 1, z, self.id);
        end
    end
end
