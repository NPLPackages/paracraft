--[[
Title: Block rail
Author(s): LiXizhi
Date: 2014/6/9
Desc: for rail blocks
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockRailBase.lua");
local BlockRailBase = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockRailBase")
block.isRailBlock(block_id)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/bit.lua");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockRailBase"));

-- register
block_types.RegisterBlockClass("BlockRailBase", block);

function block:ctor()
	self.canHasPower = nil;
end

function block:Init()
end

-- static function: 
-- @return true if the block at x,y,z is a valid rail block (rail, powered or detector).
function block.isRailBlockAt(x,y,z)
	return block.isRailBlock(BlockEngine:GetBlockId(x,y,z));
end

-- static function: 
-- @return true if the block_id is a valid rail block (rail, powered or detector).
function block.isRailBlock(block_id)
	if(block_id) then
		return block_id == block_types.names.Rails or block_id == block_types.names.RailPowered or 
			block_id == block_types.names.RailDetector or block_id == block_types.names.RailActivator;
	end
end

-- Returns true if the block is power related rail.
function block:CanHasPower()
	return self.canHasPower;
end

-- virtual: 
function block:UpdateDirData(x, y, z, blockData, shapeData, neighbor_block_id)
	self:RefreshTrackShape(x,y,z, false);
end

-- get the best model object according to nearby blocks. 
-- @param side: usually a hint for on which block side this block is created on. 
function block:GetBestModel(blockX, blockY, blockZ, blockData, side, force_condition)
	if(self.models) then
		local best_model;
		blockData = blockData or self:GetMetaDataFromEnv(blockX, blockY, blockZ);
		if(blockData and self.models.id_model_map) then
			best_model = self.models.id_model_map[blockData];
			if(best_model) then
				return best_model;
			end
		end
	end
end

function block:CanConnectWith(blockX, blockY, blockZ)
	return self.isRailBlockAt(blockX, blockY, blockZ) or self.isRailBlockAt(blockX, blockY-1, blockZ) or self.isRailBlockAt(blockX, blockY+1, blockZ);
end


function block:GetMetaDataFromEnv(blockX, blockY, blockZ, side, side_region, camx,camy,camz, lookat_x,lookat_y,lookat_z)
	local bNegZ = self:CanConnectWith(blockX, blockY, blockZ - 1);
    local bPosZ = self:CanConnectWith(blockX, blockY, blockZ + 1);
    local bPosX = self:CanConnectWith(blockX - 1, blockY, blockZ);
    local bNegX = self:CanConnectWith(blockX + 1, blockY, blockZ);
    local shapeData = -1;

    if (bNegZ or bPosZ) then
        shapeData = 2;
    end

    if (bPosX or bNegX) then
        shapeData = 1;
    end

	-- only normal rails can turn 90 degrees
    if (not self:CanHasPower()) then
        if (bPosZ and bNegX and not bNegZ and not bPosX) then
            shapeData = 3;
        end

        if (bPosZ and bPosX and not bNegZ and not bNegX) then
            shapeData = 4;
        end

        if (bNegZ and bPosX and not bPosZ and not bNegX) then
            shapeData = 5;
        end

        if (bNegZ and bNegX and not bPosZ and not bPosX) then
            shapeData = 6;
        end
    end

    if (shapeData == 2) then
        if (self.isRailBlockAt(blockX, blockY + 1, blockZ - 1)) then
            shapeData = 10;
        end

        if (self.isRailBlockAt(blockX, blockY + 1, blockZ + 1)) then
            shapeData = 8;
        end
    end

    if (shapeData == 1) then
        if (self.isRailBlockAt(blockX + 1, blockY + 1, blockZ)) then
            shapeData = 7;
        end

        if (self.isRailBlockAt(blockX - 1, blockY + 1, blockZ)) then
            shapeData = 9;
        end
    end

    if (shapeData < 0) then
        shapeData = 1;
    end

    local blockData = shapeData;

    if (self:CanHasPower()) then
		if(BlockEngine:GetBlockData(blockX, blockY, blockZ) >= 16) then
			blockData = shapeData + 16;
		end
    end
    return blockData;
end

-- Completely recalculates the track shape based on neighboring tracks
function block:RefreshTrackShape(x,y,z, bForceUpdate)
	if(not GameLogic.isRemote) then
		-- TODO: use more accurate version.
		local data = self:GetMetaDataFromEnv(x,y,z);
		local shapeData = data;
		if(data>16) then
			shapeData = data - 16;
		end
		local new_data = shapeData;

		local last_data = BlockEngine:GetBlockData(x,y,z);
		if (self:CanHasPower()) then
			if(last_data>=16 or (self.id == block_types.names.BlockRailPowered and BlockEngine:isBlockIndirectlyGettingPowered(x, y, z))) then
				new_data = shapeData + 16;
			end
		end
	
		if(new_data ~= last_data) then
			BlockEngine:SetBlockData(x,y,z, new_data, 3);
		end 
	end
end

function block:OnBlockAdded(x, y, z)
	if(not GameLogic.isRemote) then
		self:RefreshTrackShape(x,y,z);

		if (self:CanHasPower()) then
			local last_data = BlockEngine:GetBlockData(x,y,z);
			if(last_data>=16) then
				local shapeData = last_data - 16;
				-- slopes
				if (shapeData >= 7 and shapeData <= 10) then
					BlockEngine:NotifyNeighborBlocksChange(x, y + 1, z, self.id);
					BlockEngine:NotifyNeighborBlocksChange(x, y - 1, z, self.id);
				end
				BlockEngine:NotifyNeighborBlocksChange(x, y, z, self.id);
			end
			-- refresh power on state
			self:OnNeighborChanged(x, y, z, self.id);
		end
	end
end

function block:OnBlockRemoved(x,y,z, last_id, last_data)
	if(not GameLogic.isRemote) then
		local shapeData = last_data;

		if (self:CanHasPower()) then
			if(last_data>=16) then
				shapeData = last_data - 16;
			end
		end

		block._super:OnBlockRemoved(self, x,y,z, last_id, last_data);

		-- slopes
		if (shapeData >= 7 and shapeData <= 10) then
			BlockEngine:NotifyNeighborBlocksChange(x, y + 1, z, last_id);
		end

		if (self:CanHasPower()) then
			BlockEngine:NotifyNeighborBlocksChange(x, y, z , last_id);
			BlockEngine:NotifyNeighborBlocksChange(x, y - 1, z, last_id);
		end
	end
end

function block:OnNeighborChanged(x,y,z,neighbor_block_id)
	if(not GameLogic.isRemote) then
		local blockData = BlockEngine:GetBlockData(x, y, z);
		local shapeData = blockData;

		if (self:CanHasPower()) then
			if(blockData >= 16) then
				shapeData = blockData - 16;
			end
		end

		local bDestroy = false;

		--[[
		-- uncomment if one do not allow rail to be placed on air. 
		if (not BlockEngine:DoesBlockHaveSolidTopSurface(x, y - 1, z)) then
			bDestroy = true;
		end

		if (shapeData == 7 and not BlockEngine:DoesBlockHaveSolidTopSurface(x + 1, y, z)) then
			bDestroy = true;
		end

		if (shapeData == 9 and not BlockEngine:DoesBlockHaveSolidTopSurface(x - 1, y, z)) then
			bDestroy = true;
		end

		if (shapeData == 10 and not BlockEngine:DoesBlockHaveSolidTopSurface(x, y, z - 1)) then
			bDestroy = true;
		end

		if (shapeData == 8 and not BlockEngine:DoesBlockHaveSolidTopSurface(x, y, z + 1)) then
			bDestroy = true;
		end
		]]

		if (bDestroy) then
			self:DropBlockAsItem(x, y, z);
			BlockEngine:SetBlockToAir(x, y, z);
		else
			self:UpdateDirData(x, y, z, blockData, shapeData, block_id);
		end
	end
end
