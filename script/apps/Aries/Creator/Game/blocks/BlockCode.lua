--[[
Title: Code Block
Author(s): LiXizhi
Date: 2018/5/19
Desc: Code block uses code to control actors in the nearby connected movie block.  
When code block is powered by current, it will also power nearby 15 code blocks with a special code power.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockCode.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockCode")
-------------------------------------------------------
]]
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.blocks.BlockEntityBase"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockCode"));

-- register
block_types.RegisterBlockClass("BlockCode", block);

-- intermediary helper data structure
local blocksNeedingUpdate = {};

function block:ctor()
	self.ProvidePower = true;
end

-- Do not emit weak power to nearby movie blocks, otherwise it behaves same as normal cube block.
-- Returns 0 if the block is emitting indirect/weak electric power on the specified side. 
function block:isProvidingWeakPower(x,y,z, side)
	return 0;
end

function block:isProvidingStrongPower(x,y,z, side)
	return 0;
end

function block:OnNeighborChanged(x, y, z, from_block_id)
	block._super.OnNeighborChanged(self, x, y, z, from_block_id);
	if (not GameLogic.isRemote) then
		self:updateAndPropagateCurrentStrength(x,y,z);
	end
end

function block:OnBlockRemoved(x, y, z, from_block_id)
	block._super.OnBlockRemoved(self, x, y, z, from_block_id);
	if (not GameLogic.isRemote) then
		self:updateAndPropagateCurrentStrength(x, y, z);
		self:notifyCodeNeighborsOfNeighborChange(x - 1, y, z);
		self:notifyCodeNeighborsOfNeighborChange(x + 1, y, z);
		self:notifyCodeNeighborsOfNeighborChange(x, y, z - 1);
		self:notifyCodeNeighborsOfNeighborChange(x, y, z + 1);
	end
end


function block:OnBlockAdded(x,y,z, block_data, serverdata)
	block._super.OnBlockAdded(self, x, y, z, block_data, serverdata);
	if (not GameLogic.isRemote) then
		self:updateAndPropagateCurrentStrength(x, y, z);
		self:notifyCodeNeighborsOfNeighborChange(x - 1, y, z);
		self:notifyCodeNeighborsOfNeighborChange(x + 1, y, z);
		self:notifyCodeNeighborsOfNeighborChange(x, y, z - 1);
		self:notifyCodeNeighborsOfNeighborChange(x, y, z + 1);
	end
end

function block:notifyCodeNeighborsOfNeighborChange(x,y,z)
    if (ParaTerrain.GetBlockTemplateByIdx(x, y, z) == self.id) then
        BlockEngine:NotifyNeighborBlocksChange(x, y, z, self.id);
        BlockEngine:NotifyNeighborBlocksChange(x - 1, y, z, self.id);
        BlockEngine:NotifyNeighborBlocksChange(x + 1, y, z, self.id);
        BlockEngine:NotifyNeighborBlocksChange(x, y, z - 1, self.id);
        BlockEngine:NotifyNeighborBlocksChange(x, y, z + 1, self.id);
    end
end

-- Sets the strength of the wire current (0-15) for this block based on neighboring blocks and propagates to
-- neighboring wires
function block:updateAndPropagateCurrentStrength(x,y,z)
    self:calculateCurrentChanges(x,y,z);
	if(#blocksNeedingUpdate > 0) then
		local last_need_updates = blocksNeedingUpdate;
		blocksNeedingUpdate = {};

		for i = 1, #last_need_updates do
			local pos = last_need_updates[i];
			BlockEngine:NotifyNeighborBlocksChange(pos[1], pos[2], pos[3], self.id);
		end
	end
end

function block:getCodePower(x, y, z)
	return self:getMaxCodeStrength(x, y, z, 0);
end

-- get strongest code power from the neighboring 4 blocks. 
-- Code block will transmit code power to its neighbor in xz plain, similar to wires
function block:getStrongestCodePower(x, y, z)
    local max_power = 0;

    for dir = 0, 3 do
		local x1,y1,z1 = BlockEngine:GetBlockIndexBySide(x,y,z,dir)
        local power = self:getCodePower(x1,y1,z1);
        if (power >= 15) then
            return 15;
        elseif (power > max_power) then
            max_power = power;
        end
    end

    return max_power;
end

-- calculate comparing to block (x1, y1, z1). usually same as x,y,z
function block:calculateCurrentChanges(x, y, z)
	local last_data = ParaTerrain.GetBlockUserDataByIdx(x, y, z)
	-- remove color8 data in high bits
    local last_code_power = mathlib.bit.band(last_data, 0xff);
    local max_code_power = last_code_power;
	if(BlockEngine:isBlockIndirectlyGettingPowered(x,y,z)) then
		if (ParaTerrain.GetBlockTemplateByIdx(x, y, z) == self.id) then
			max_code_power = 15;
		else
			max_code_power = 0;
		end
	else
		local cur_power = self:getStrongestCodePower(x, y, z);
    
		if (cur_power > max_code_power) then
			max_code_power = cur_power - 1;
		elseif (max_code_power > 0) then
			max_code_power = max_code_power - 1;
		else
			max_code_power = 0;
		end
	end
    if (last_code_power ~= max_code_power) then
		if(last_data > 0xff) then
			max_code_power = last_data - last_code_power + max_code_power;
		end
        BlockEngine:SetBlockDataForced(x, y, z, max_code_power);
        blocksNeedingUpdate[#blocksNeedingUpdate+1] = {x, y, z};
        blocksNeedingUpdate[#blocksNeedingUpdate+1] = {x - 1, y, z};
        blocksNeedingUpdate[#blocksNeedingUpdate+1] = {x + 1, y, z};
        blocksNeedingUpdate[#blocksNeedingUpdate+1] = {x, y, z - 1};
        blocksNeedingUpdate[#blocksNeedingUpdate+1] = {x, y, z + 1};
    end
end

-- Returns the current strength at the specified block if it is greater than the passed value, or the passed value
-- otherwise. 
function block:getMaxCodeStrength(x, y, z, strength)
    if (ParaTerrain.GetBlockTemplateByIdx(x, y, z) ~= self.id) then
        return strength;
    else
		local my_strength = ParaTerrain.GetBlockUserDataByIdx(x,y,z);
		-- remove color8 data in high bits
		my_strength = mathlib.bit.band(my_strength, 0xff);
		if(my_strength > strength) then
			return my_strength;
		else
			return strength;
		end
    end
end

-- some block like command blocks, may has an internal state number(like its last output result)
-- and some block may use its nearby blocks' state number to generate electric output or other behaviors.
-- @return nil or a number between [0-15]
function block:GetInternalStateNumber(x,y,z)
	local entity = self:GetBlockEntity(x,y,z)
	if(entity and entity.GetLastOutput) then
		return entity:GetLastOutput() or 0;
	else
		return 0;
	end
end