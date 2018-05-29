--[[
Title: Wire Based Block
Author(s): LiXizhi
Date: 2013/1/23
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockWire.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockWire")
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
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names")
local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockWire"));

local band = mathlib.bit.band;

-- register
block_types.RegisterBlockClass("BlockWire", block);

-- intermediary helper data structure
local blocksNeedingUpdate = {};
local wiresProvidePower = true;


function block:ctor()
	self.ProvidePower = true;
	self.isAutoUserData = true;
end

function block:Init()
	
end

-- Can this block provide power. 
function block:canProvidePower()
    return wiresProvidePower;
end

-- virtual: Checks to see if its valid to put this block at the specified coordinates. Args: world, x, y, z
function block:canPlaceBlockAt(x,y,z)
	local below_block_id = ParaTerrain.GetBlockTemplateByIdx(x, y-1, z);
	if(below_block_id) then
		local below_block = block_types.get(below_block_id);
		if(below_block and below_block.solid) then
			-- can only be placed on solid block. 
			return true;
		end	
	end
end

-- Sets the strength of the wire current (0-15) for this block based on neighboring blocks and propagates to
-- neighboring wires
function block:updateAndPropagateCurrentStrength(x,y,z)
    self:calculateCurrentChanges(x,y,z, x,y,z);
	if(#blocksNeedingUpdate > 0) then
		local last_need_updates = blocksNeedingUpdate;
		blocksNeedingUpdate = {};

		for i = 1, #last_need_updates do
			local pos = last_need_updates[i];
			BlockEngine:NotifyNeighborBlocksChange(pos[1], pos[2], pos[3], self.id);
		end
	end
end

-- Returns the current strength at the specified block if it is greater than the passed value, or the passed value
-- otherwise. 
function block:getMaxCurrentStrength(x, y, z, strength)
    if (ParaTerrain.GetBlockTemplateByIdx(x, y, z) ~= self.id) then
        return strength;
    else
        local my_strength = ParaTerrain.GetBlockUserDataByIdx(x,y,z);
		if(my_strength > strength) then
			return my_strength;
		else
			return strength;
		end
    end
end

-- calculate comparing to block (x1, y1, z1). usually same as x,y,z
function block:calculateCurrentChanges(x, y, z, x1, y1, z1)
    local last_wire_strength = ParaTerrain.GetBlockUserDataByIdx(x, y, z);
    local max_wire_strength = self:getMaxCurrentStrength(x1, y1, z1, 0);
    wiresProvidePower = false;
    local indirect_power = BlockEngine:getStrongestIndirectPower(x, y, z);
    wiresProvidePower = true;

    if (indirect_power > 0 and indirect_power > max_wire_strength - 1) then
        max_wire_strength = indirect_power;
    end

    local cur_power = 0;

    for dir = 0 , 3 do
        local x2 = x;
        local z2 = z;

        if (dir == 0) then
            x2 = x - 1;
        elseif (dir == 1) then
            x2 = x2 + 1;
        elseif (dir == 2) then
            z2 = z - 1;
        elseif (dir == 3) then
            z2 = z2 + 1;
        end

        if (x2 ~= x1 or z2 ~= z1) then
            cur_power = self:getMaxCurrentStrength(x2, y, z2, cur_power);
        end

        if (BlockEngine:isBlockNormalCube(x2, y, z2) and not BlockEngine:isBlockNormalCube(x, y + 1, z)) then
            if ((x2 ~= x1 or z2 ~= z1) and y >= y1) then
                cur_power = self:getMaxCurrentStrength(x2, y + 1, z2, cur_power);
            end
        elseif (not BlockEngine:isBlockNormalCube(x2, y, z2) and (x2 ~= x1 or z2 ~= z1) and y <= y1) then
            cur_power = self:getMaxCurrentStrength(x2, y - 1, z2, cur_power);
        end
    end

    if (cur_power > max_wire_strength) then
        max_wire_strength = cur_power - 1;
    elseif (max_wire_strength > 0) then
		max_wire_strength = max_wire_strength - 1;
    else
        max_wire_strength = 0;
    end

    if (indirect_power > max_wire_strength - 1) then
        max_wire_strength = indirect_power;
    end

    if (last_wire_strength ~= max_wire_strength) then
        BlockEngine:SetBlockDataForced(x, y, z, max_wire_strength);
        blocksNeedingUpdate[#blocksNeedingUpdate+1] = {x, y, z};
        blocksNeedingUpdate[#blocksNeedingUpdate+1] = {x - 1, y, z};
        blocksNeedingUpdate[#blocksNeedingUpdate+1] = {x + 1, y, z};
        blocksNeedingUpdate[#blocksNeedingUpdate+1] = {x, y - 1, z};
        blocksNeedingUpdate[#blocksNeedingUpdate+1] = {x, y + 1, z};
        blocksNeedingUpdate[#blocksNeedingUpdate+1] = {x, y, z - 1};
        blocksNeedingUpdate[#blocksNeedingUpdate+1] = {x, y, z + 1};
    end
end

-- Calls World.NotifyNeighborBlocksChange() for all neighboring blocks, but only if the given block is a wire
function block:notifyWireNeighborsOfNeighborChange(x,y,z)
    if (ParaTerrain.GetBlockTemplateByIdx(x, y, z) == self.id) then
        BlockEngine:NotifyNeighborBlocksChange(x, y, z, self.id);
        BlockEngine:NotifyNeighborBlocksChange(x - 1, y, z, self.id);
        BlockEngine:NotifyNeighborBlocksChange(x + 1, y, z, self.id);
        BlockEngine:NotifyNeighborBlocksChange(x, y, z - 1, self.id);
        BlockEngine:NotifyNeighborBlocksChange(x, y, z + 1, self.id);
        BlockEngine:NotifyNeighborBlocksChange(x, y - 1, z, self.id);
        BlockEngine:NotifyNeighborBlocksChange(x, y + 1, z, self.id);
    end
end

function block:OnNeighborChanged(x,y,z,neighbor_block_id)
	if (not GameLogic.isRemote) then
		if (self:canPlaceBlockAt(x,y,z)) then
			self:updateAndPropagateCurrentStrength(x,y,z);
		else
			BlockEngine:SetBlockToAir(x,y,z);
		end
	end
end

function block:OnBlockAdded(x, y, z)
	block._super.OnBlockAdded(self, x, y, z);

	if (not GameLogic.isRemote) then
		self:updateAndPropagateCurrentStrength(x, y, z);
		BlockEngine:NotifyNeighborBlocksChange(x, y + 1, z, self.id);
		BlockEngine:NotifyNeighborBlocksChange(x, y - 1, z, self.id);
		self:notifyWireNeighborsOfNeighborChange(x - 1, y, z);
		self:notifyWireNeighborsOfNeighborChange(x + 1, y, z);
		self:notifyWireNeighborsOfNeighborChange(x, y, z - 1);
		self:notifyWireNeighborsOfNeighborChange(x, y, z + 1);

		if (BlockEngine:isBlockNormalCube(x - 1, y, z)) then
			self:notifyWireNeighborsOfNeighborChange(x - 1, y + 1, z);
		else
			self:notifyWireNeighborsOfNeighborChange(x - 1, y - 1, z);
		end

		if (BlockEngine:isBlockNormalCube(x + 1, y, z)) then
			self:notifyWireNeighborsOfNeighborChange(x + 1, y + 1, z);
		else
			self:notifyWireNeighborsOfNeighborChange(x + 1, y - 1, z);
		end

		if (BlockEngine:isBlockNormalCube(x, y, z - 1)) then
			self:notifyWireNeighborsOfNeighborChange(x, y + 1, z - 1);
		else
			self:notifyWireNeighborsOfNeighborChange(x, y - 1, z - 1);
		end

		if (BlockEngine:isBlockNormalCube(x, y, z + 1)) then
			self:notifyWireNeighborsOfNeighborChange(x, y + 1, z + 1);
		else
			self:notifyWireNeighborsOfNeighborChange(x, y - 1, z + 1);
		end
	end
end

-- Returns true if the block is emitting direct/strong power on the specified side. 
function block:isProvidingStrongPower(x,y,z, side)
	if(not wiresProvidePower) then
		return 0;
	else
		return self:isProvidingWeakPower(x,y,z, side);	
	end
end

-- Returns true if wire can connect to the specified block.
local function isPowerProviderOrWire(x,y,z, side)
    local block_id = ParaTerrain.GetBlockTemplateByIdx(x,y,z);

    if (block_id == names.Wire) then
        return true;
    elseif (block_id == 0) then
        return false;
    elseif(side ~= -1) then
		local block = block_types.get(block_id);
		if(block) then
			if( not block_types.blocks.Repeater:IsAssociatedOnOffBlock(block_id)) then
				return block:canProvidePower();
			else
				-- red stone repeater
				local data = ParaTerrain.GetBlockUserDataByIdx(x,y,z);
				return side == band(data,3) or side == Direction.rotateOpposite[band(data,3)];
			end
		end
	end
end

-- Returns true if the block coordinate passed can provide power, or is a wire, or if its a repeater that is powered.
local function isPoweredOrRepeater(x,y,z, side)
    if (isPowerProviderOrWire(x,y,z, side)) then
        return true;
    else
        --local block_id = ParaTerrain.GetBlockTemplateByIdx(x,y,z);
        --if (block_id and block_id == names.Repeater_On) then
            --local data = ParaTerrain.GetBlockUserDataByIdx(x,y,z);
            --return side == band(data,3);
        --else
            --return false;
        --end
    end
end

-- Returns true if the block is emitting indirect/weak power on the specified side. 
function block:isProvidingWeakPower(x,y,z, side)
    if (not wiresProvidePower) then
        return 0;
    else
        local power_level = ParaTerrain.GetBlockUserDataByIdx(x, y, z);

		-- local side = side_to_special_side[side];

        if (power_level == 0 or side == 5) then
			-- do not power block above
            return 0;
        elseif (side == 4) then
			-- always power the block below. 
            return power_level;
        else
			-- dir0-dir4: whether the wire can connect to the direction. 
            local dir0 = isPoweredOrRepeater(x - 1, y, z, 0) or not BlockEngine:isBlockNormalCube(x - 1, y, z) and isPoweredOrRepeater(x - 1, y - 1, z, -1);
            local dir1 = isPoweredOrRepeater(x + 1, y, z, 1) or not BlockEngine:isBlockNormalCube(x + 1, y, z) and isPoweredOrRepeater(x + 1, y - 1, z, -1);
            local dir2 = isPoweredOrRepeater(x, y, z - 1, 2) or not BlockEngine:isBlockNormalCube(x, y, z - 1) and isPoweredOrRepeater(x, y - 1, z - 1, -1);
            local dir3 = isPoweredOrRepeater(x, y, z + 1, 3) or not BlockEngine:isBlockNormalCube(x, y, z + 1) and isPoweredOrRepeater(x, y - 1, z + 1, -1);

            if (not BlockEngine:isBlockNormalCube(x, y + 1, z)) then
                if (BlockEngine:isBlockNormalCube(x - 1, y, z) and isPoweredOrRepeater(x - 1, y + 1, z, -1)) then
                    dir0 = true;
                end

                if (BlockEngine:isBlockNormalCube(x + 1, y, z) and isPoweredOrRepeater(x + 1, y + 1, z, -1)) then
                    dir1 = true;
                end

                if (BlockEngine:isBlockNormalCube(x, y, z - 1) and isPoweredOrRepeater(x, y + 1, z - 1, -1)) then
                    dir2 = true;
                end

                if (BlockEngine:isBlockNormalCube(x, y, z + 1) and isPoweredOrRepeater(x, y + 1, z + 1, -1)) then
                    dir3 = true;
                end
            end

			if(not dir2 and not dir1 and not dir0 and not dir3) then
				return power_level;
			elseif(side == 3 and dir2 and not dir0 and not dir1) then
				return power_level;
			elseif(side == 2 and dir3 and not dir0 and not dir1) then
				return power_level;
			elseif(side == 1 and dir0 and not dir2 and not dir3) then
				return power_level;
			elseif(side == 0 and dir1 and not dir2 and not dir3) then
				return power_level;
			else
				return 0;
			end
        end
    end
end

function block:OnBlockRemoved(x,y,z, last_id, last_data)
	if (not GameLogic.isRemote) then
		BlockEngine:NotifyNeighborBlocksChange(x, y + 1, z, self.id);
		BlockEngine:NotifyNeighborBlocksChange(x, y - 1, z, self.id);
		BlockEngine:NotifyNeighborBlocksChange(x + 1, y, z, self.id);
		BlockEngine:NotifyNeighborBlocksChange(x - 1, y, z, self.id);
		BlockEngine:NotifyNeighborBlocksChange(x, y, z + 1, self.id);
		BlockEngine:NotifyNeighborBlocksChange(x, y, z - 1, self.id);
		self:updateAndPropagateCurrentStrength(x, y, z);
		self:notifyWireNeighborsOfNeighborChange(x - 1, y, z);
		self:notifyWireNeighborsOfNeighborChange(x + 1, y, z);
		self:notifyWireNeighborsOfNeighborChange(x, y, z - 1);
		self:notifyWireNeighborsOfNeighborChange(x, y, z + 1);

		if (BlockEngine:isBlockNormalCube(x - 1, y, z)) then
			self:notifyWireNeighborsOfNeighborChange(x - 1, y + 1, z);
		else
			self:notifyWireNeighborsOfNeighborChange(x - 1, y - 1, z);
		end

		if (BlockEngine:isBlockNormalCube(x + 1, y, z)) then
			self:notifyWireNeighborsOfNeighborChange(x + 1, y + 1, z);
		else
			self:notifyWireNeighborsOfNeighborChange(x + 1, y - 1, z);
		end

		if (BlockEngine:isBlockNormalCube(x, y, z - 1)) then
			self:notifyWireNeighborsOfNeighborChange(x, y + 1, z - 1);
		else
			self:notifyWireNeighborsOfNeighborChange(x, y - 1, z - 1);
		end

		if (BlockEngine:isBlockNormalCube(x, y, z + 1)) then
			self:notifyWireNeighborsOfNeighborChange(x, y + 1, z + 1);
		else
			self:notifyWireNeighborsOfNeighborChange(x, y - 1, z + 1);
		end
	end
end