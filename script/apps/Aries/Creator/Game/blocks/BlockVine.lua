--[[
Title: Vine and half vine
Author(s): LiXizhi
Date: 2015/7/18
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockVine.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockVine");
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockVine"));

-- register
block_types.RegisterBlockClass("BlockVine", block);

local side_to_data = {[0] = 4, [1] = 3, [2] = 5, [3] = 1, [4] = 0, [5] = 2, } 
local data_to_side = {[0] = 4, [1] = 3, [2] = 5, [3] = 1, [4] = 0, [5] = 2, } 

function block:ctor()
end

function block:GetMetaDataFromEnv(blockX, blockY, blockZ, side, side_region, camx,camy,camz, lookat_x,lookat_y,lookat_z)
	local data = 0;
	if(side) then
		data = side_to_data[side];
		if(side == 4) then
			local block_id = ParaTerrain.GetBlockTemplateByIdx(blockX, blockY+1, blockZ);
			if(block_id == self.id) then
				data = ParaTerrain.GetBlockUserDataByIdx(blockX, blockY+1, blockZ);
			end
		elseif(side == 5) then
			local block_id = ParaTerrain.GetBlockTemplateByIdx(blockX, blockY-1, blockZ);
			if(block_id == self.id) then
				data = ParaTerrain.GetBlockUserDataByIdx(blockX, blockY-1, blockZ);
			end
		end
	end
	return data;
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
		local side = data_to_side[blockData or 0];
		if(side < 4) then
			local facing = Direction.directionTo3DFacing[side];
			blockData = side_to_data[Direction.GetDirectionFromFacing(facing + angle)];
		end
	else
		-- TODO: for other axis;
	end
	return blockData;
end
