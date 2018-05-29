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

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockConductor"));

-- register
block_types.RegisterBlockClass("BlockConductor", block);


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
		local is_indirectly_powered = self:isWeaklyPowered(x,y,z);

		if ( (self.torchActive and not is_indirectly_powered) or (not self.torchActive and is_indirectly_powered)) then
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

function block:OnNeighborChanged(x,y,z,neighbor_block_id)
	if(not GameLogic.isRemote) then
		local is_indirectly_powered = self:isWeaklyPowered(x,y,z);

		if ( (self.torchActive and not is_indirectly_powered) or (not self.torchActive and is_indirectly_powered)) then
			GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self.id, self:tickRate());
		end
	end
end

-- Can this block provide power. 
function block:canProvidePower()
    return true;
end

-- this block is a diode, which is only weakly powered by the block that it sits on. 
function block:isWeaklyPowered(x,y,z)
	local y1 = y-1;
	local src_block = BlockEngine:GetBlock(x,y1,z);
	if(src_block) then
		local src_state = src_block:GetInternalStateNumber(x,y1,z);
		if(src_state) then
			-- source state has priority over weak power
			return src_state and src_state>0;
		else
			return BlockEngine:hasWeakPowerOutputTo(x,y1,z);
		end
	else
		return false;
	end
end

-- providing power except for the block that it sits on. 
function block:isProvidingWeakPower(x, y, z, direction)
	if (not self.torchActive) then
        return 0;
    else
        if(direction == 4) then
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
		local is_indirectly_powered = self:isWeaklyPowered(x,y,z);

		if (self.torchActive) then
			if(not is_indirectly_powered) then
				-- turn it off
				BlockEngine:SetBlock(x,y,z,names.Conductor, data, 3);
			end
		else
			if(is_indirectly_powered) then
				-- turn it on
				BlockEngine:SetBlock(x,y,z,names.Conductor_On, data, 3);
			end
		end
	end
end



