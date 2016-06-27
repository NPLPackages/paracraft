--[[
Title: A carpet plate
Author(s): LiXizhi
Date: 2014/5/4
Desc: block carpet
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockCarpet.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockCarpet");
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockCarpet"));

-- register
block_types.RegisterBlockClass("BlockCarpet", block);

local side_to_data = {[0] = 4, [1] = 3, [2] = 5, [3] = 1, [4] = 2, [5] = 0, } 
local data_to_side = {[0] = 5, [1] = 3, [2] = 4, [3] = 1, [4] = 0, [5] = 2, } 
local side_to_second_data = { [0]=1, [1]=0, [2]=3, [3]=2};
local second_data_to_side = side_to_second_data;

function block:ctor()
end

function block:Init()
	
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
		elseif(neighbor_block.transparent) then
			return false;
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

function block:GetSideByBlockData(blockData)
	if(blockData<6) then
		return data_to_side[blockData];
	else
		return second_data_to_side[(blockData - 6) % 4];
	end
end

-- rotate the block data by the given angle and axis. This is mosted reimplemented in blocks with orientations stored in block data, such as stairs, bones, etc. 
-- @param blockData: current block data
-- @param angle: usually 1.57, -1.57, 3.14, -3.14, 0. if 0 it means mirror along the given axis.
-- @param axis: "x|y|z", if nil, it should default to "y" axis
-- @return the rotated block data. 
function block:RotateBlockData(blockData, angle, axis)
	axis = axis or "y"
	-- rotation around axis
	if(axis == "y") then
		local side = self:GetSideByBlockData(blockData or 0);
		if(side < 4) then
			local facing = Direction.directionTo3DFacing[side];
			local new_side = Direction.GetDirectionFromFacing(facing + angle);
			if(blockData<6) then
				blockData = side_to_data[new_side];
			else
				blockData = 6 + math.floor((blockData-6)/4)*4 + side_to_second_data[new_side];
			end
		end
	else
		-- TODO: for other axis;
	end
	return blockData;
end