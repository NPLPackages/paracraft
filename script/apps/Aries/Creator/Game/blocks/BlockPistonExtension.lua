--[[
Title: PistonExtension
Author(s): LiXizhi
Date: 2013/12/3
Desc: Block PistonExtension
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockPistonExtension.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockPistonExtension")
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

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockPistonExtension"));
local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

-- register
block_types.RegisterBlockClass("BlockPistonExtension", block);


-- [0-5), 7 means middle state
local function getOrientation(data)
    return band(data, 7);
end

function block:ctor()
	self.ProvidePower = true;
end

function block:Init()
end

function block:OnNeighborChanged(x,y,z,neighbor_block_id)
	local dir = getOrientation(BlockEngine:GetBlockData(x,y,z));
	if(dir<=5) then
		local base_id = BlockEngine:GetBlockId(x - Direction.offsetX[dir], y - Direction.offsetY[dir], z - Direction.offsetZ[dir]);

		if (base_id ~= block_types.names.Piston and base_id ~= block_types.names.StickyPiston) then
			BlockEngine:SetBlockToAir(x,y,z);
		else
			block_types.get(base_id):OnNeighborChanged(x - Direction.offsetX[dir], y - Direction.offsetY[dir], z - Direction.offsetZ[dir], neighbor_block_id);
		end
	else
		BlockEngine:SetBlockToAir(x,y,z);
	end
end

function block:OnBlockRemoved(x, y, z, last_id, last_data)
	if(not GameLogic.isRemote) then
		local op_dir = Direction.directionToOpFacing[getOrientation(last_data)];
		x = x + Direction.offsetX[op_dir];
		y = y + Direction.offsetY[op_dir];
		z = z + Direction.offsetZ[op_dir];
		local block_id = BlockEngine:GetBlockId(x,y,z);

		if (block_id == block_types.names.Piston or block_id == block_types.names.StickyPiston) then
			local data = BlockEngine:GetBlockData(x,y,z);

			if (block_types.blocks.Piston.isExtended(data)) then
				block_types.blocks.Piston:DropBlockAsItem(x,y,z);
				BlockEngine:SetBlockToAir(x,y,z);
			end
		end
	end
end


-- goto pressed state and then schedule tickUpdate to go off again after some ticks
function block:OnActivated(x, y, z)
end

function block:OnToggle(x, y, z)
end

-- revert back to unpressed state
function block:updateTick(x,y,z)

end



