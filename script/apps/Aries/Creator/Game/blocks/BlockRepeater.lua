--[[
Title: Repeater Based Block
Author(s): LiXizhi
Date: 2013/1/23
Desc: recharge and forward red stone energy in fixed direction only if the input end block is powered. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockRepeater.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockRepeater")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockLogic.lua");
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

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.blocks.BlockLogic"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockRepeater"));

-- register
block_types.RegisterBlockClass("BlockRepeater", block);

-- The states in which the repeater blocks can be. 
local repeaterState = {[0]=1, 2, 3, 4};

function block:ctor()
end

function block:Init()
	-- event id is on state. 
	self.isPoweredOn = ((self.id%2) ==0);
end

-- virtual: Checks to see if its valid to put this block at the specified coordinates. Args: world, x, y, z
function block:canPlaceBlockAt(x,y,z)
	return true;
end

-- @param userdata: 1,2,3,4;
function block:getTickRateByData(data)
    return repeaterState[rshift(band(data,12),2)] * 2;
end

function block:GetOnBlockID()
	return block_types.names.Repeater_On;
end

function block:GetOffBlockID()
    return block_types.names.Repeater;
end

function block:OnBlockRemoved(x,y,z, last_id, last_data)
	block._super.OnBlockRemoved(self, x,y,z, last_id, last_data);
	if(not GameLogic.isRemote) then
		self:DoNotifyNeighborBlocks(x,y,z);
	end
end

-- toggle 4 states
function block:OnActivated(x, y, z)
	if(not GameLogic.isRemote) then
		local data = ParaTerrain.GetBlockUserDataByIdx(x, y, z);

		local state = rshift(band(data,12), 2);
		state = band(lshift(state+1, 2), 12);

		BlockEngine:SetBlockData(x, y, z, bor(state, band(data,3)));
		BlockEngine:NotifyNeighborBlocksChange(x, y, z, self.id)
		return true;
	end
end

function block:OnToggle(x, y, z)
	-- self:OnActivated(x, y, z);
end

-- logic is disabled(locked) if there is input on either side of the repeater. 
function block:IsLogicDisabled(x,y,z, data)
    return self:GetMaxPowerInputForDirection(x,y,z, data) > 0;
end

function block:getBlockPowerLevelToDirection(x,y,z,side)
    local block_id = BlockEngine:GetBlockId(x, y, z);
	
    if (self:canBlockProvidePower(block_id)) then
		if(block_id == block_types.names.Wire) then
			-- return BlockEngine:GetBlockData(x, y, z);
			return 0; -- disable wire for repeater
		else
			return BlockEngine:isBlockProvidingStrongPowerTo(x, y, z, side);
		end
	else
		return 0;
	end
end

function block:RotateBlockData(blockData, angle, axis)
	return self:RotateBlockDataUsingModelFacing(blockData, angle, axis);
end