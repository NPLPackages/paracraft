--[[
Title: A lilypad 
Author(s): LiXizhi, leio
Date: 2015/7/17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockLilypad.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockLilypad");
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockLilypad"));

-- register
block_types.RegisterBlockClass("BlockLilypad", block);

local side_to_data = {[0] = 4, [1] = 3, [2] = 5, [3] = 1, [4] = 0, [5] = 2, } 
local data_to_side = {[0] = 4, [1] = 3, [2] = 5, [3] = 1, [4] = 0, [5] = 2, } 

function block:ctor()
end

-- virtual: Checks to see if its valid to put this block at the specified coordinates. Args: world, x, y, z
function block:canPlaceBlockOnSide(x,y,z,side)
	if(side) then
		side = Direction.directionToOpFacing[side];
		
		local dx = Direction.offsetX[side];
		local dy = Direction.offsetY[side];
		local dz = Direction.offsetZ[side];

		local neighbor_block = BlockEngine:GetBlock(x+dx, y+dy, z+dz);
		if(not neighbor_block) then
			return false
		elseif(neighbor_block.id == self.id) then
			local neighbor_blockdata = BlockEngine:GetBlockData(x+dx, y+dy, z+dz);
			local neightbor_side = data_to_side[neighbor_blockdata];
			if(neightbor_side==side or neightbor_side == Direction.directionToOpFacing[side]) then
				return false;
			end
		end
	end
	return true;
end

function block:GetMetaDataFromEnv(blockX, blockY, blockZ, side, side_region, camx,camy,camz, lookat_x,lookat_y,lookat_z)
	local data = 0;
	if(side) then
		data = side_to_data[side];
	end
	return data or 0;
end