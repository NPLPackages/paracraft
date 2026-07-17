--[[
Title: BlockConductor
Author(s): LiXizhi
Date: 2014/2/18
Desc: this is the inverse of electric torch. and it has only one direction. 
conductor is suitable for conducting current upward. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockConductor.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockConductor")
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names")
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockConductor"));

-- register
block_types.RegisterBlockClass("BlockConductor", block);
-- intermediary helper data structure
local blocksNeedingUpdate = {};

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

function block:OnToggle(bx, by, bz)
end

function block:OnBlockAdded(x, y, z)
	if(not GameLogic.isRemote) then
		self:calculatePower(x, y, z, true)
	end
end

function block:OnBlockRemoved(x,y,z, last_id, last_data)
	if(not GameLogic.isRemote) then
	end
end

function block:OnNeighborChanged(x,y,z,neighbor_block_id)
	if(not GameLogic.isRemote) then
		self:calculatePower(x, y, z)
	end
end

-- Can this block provide power. 
function block:canProvidePower()
    return true;
end

function block:calculatePower(x, y, z, forceUpdate)
    local last_wire_strength = ParaTerrain.GetBlockUserDataByIdx(x, y, z);
    local cur_wire_strength = BlockEngine:getStrongestIndirectPower(x, y, z)
	if(cur_wire_strength >= 1) then
		cur_wire_strength = cur_wire_strength - 1;
	end
    if (last_wire_strength ~= cur_wire_strength or forceUpdate) then
		BlockEngine:SetBlockDataForced(x, y, z, cur_wire_strength);
		BlockEngine:NotifyNeighborBlocksChange(x, y, z, self.id)
    end
end

-- providing power to all directions
function block:isProvidingWeakPower(x, y, z, direction)
	local power_level = ParaTerrain.GetBlockUserDataByIdx(x, y, z);
	if (power_level) then
		return power_level;
	else
		return 0;
	end
end

function block:isProvidingStrongPower(x, y, z, direction)
	return self:isProvidingWeakPower(x, y, z, direction);
end

-- revert back to unpressed state
function block:updateTick(x,y,z)
	if(not GameLogic.isRemote) then
	end
end



