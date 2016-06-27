--[[
Title: Bone
Author(s): LiXizhi
Date: 2015/5/6
Desc: Block Bone
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockBone.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockBone")
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

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.blocks.BlockEntityBase"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockBone"));

-- register
block_types.RegisterBlockClass("BlockBone", block);

function block:ctor()
end

local op_side_to_data = {
	[0] = 0, [1] = 1, [2] = 2, [3] = 3, [4] = 4, [5] = 5,
}							   
							   
-- user data to direction side 
local data_to_side = {		   
	[0] = 0, [1] = 1, [2] = 2, [3] = 3, [4] = 4, [5] = 5,
}

function block:GetMetaDataFromEnv(blockX, blockY, blockZ, side, side_region, camx,camy,camz, lookat_x,lookat_y,lookat_z)
	return op_side_to_data[side or 5] or 1;
end

-- virtual: Checks to see if its valid to put this block at the specified coordinates. Args: world, x, y, z
function block:canPlaceBlockOnSide(x,y,z,side)
	if(side) then
		if(block._super.canPlaceBlockOnSide(self, x,y,z, side)) then
			side = BlockEngine:GetOppositeSide(side);
			local x_, y_, z_ = BlockEngine:GetBlockIndexBySide(x,y,z,side)
			local below_block_id = BlockEngine:GetBlockId(x_, y_, z_);
			if(below_block_id == self.id) then
				return true;
			elseif(below_block_id) then
				local below_block = block_types.get(below_block_id);
				if(below_block and below_block.solid) then
					-- can only be placed on solid block. 
					return true;
				end	
			end
		end
	else
		return true;
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
		if(blockData < 4) then
			local facing = Direction.directionTo3DFacing[blockData];
			blockData = Direction.GetDirectionFromFacing(facing + angle);
		end
	else
		-- TODO: for other axis;
	end
	return blockData;
end

-- mirror the block data along the given axis. This is mosted reimplemented in blocks with orientations stored in block data, such as stairs, bones, etc. 
-- @param blockData: current block data
-- @param axis: "x|y|z", if nil, it should default to "y" axis
-- @return the mirrored block data. 
function block:MirrorBlockData(blockData, axis)
	axis = axis or "y"
	-- mirror along axis
	if(axis == "y") then
		if(blockData == 4 or blockData == 5) then
			blockData = Direction.directionToOpFacing[blockData];
		end
	elseif(axis == "x") then
		if(blockData == 0 or blockData == 1) then
			blockData = Direction.directionToOpFacing[blockData];
		end
	elseif(axis == "z") then
		if(blockData == 2 or blockData == 3) then
			blockData = Direction.directionToOpFacing[blockData];
		end
	end
	return blockData;
end
