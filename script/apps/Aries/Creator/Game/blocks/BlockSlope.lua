--[[
Title: Slope Based Block
Author(s): devilwalk@taomee
Date: 2016/6/28
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockSlope.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockSlope")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/ide/math/bit.lua");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local band = mathlib.bit.band;

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockSlope"));

-- register
block_types.RegisterBlockClass("BlockSlope", block);

function block:ctor()
	local models = {
		{id_data=0, assetfile="L", facing=0, },
		{id_data=7, assetfile="L", facing=1.57, },
		{id_data=1, assetfile="L", facing=3.14, },
		{id_data=6, assetfile="L", facing=4.71, },

		{id_data=9, assetfile="T", facing=0, },
		{id_data=12, assetfile="T", facing=4.71, },
		{id_data=8, assetfile="T", facing=3.14, },
		{id_data=13, assetfile="T", facing=1.57, },

		{id_data=4, assetfile="/", facing=0, },
		{id_data=3, assetfile="/", facing=4.71, },
		{id_data=5, assetfile="/", facing=3.14, },
		{id_data=2, assetfile="/", facing=1.57, },

		{id_data=14, assetfile="7", facing=0, },
		{id_data=11, assetfile="7", facing=4.71, },
		{id_data=15, assetfile="7", facing=3.14, },
		{id_data=10, assetfile="7", facing=1.57, },
	}
	models.id_model_map = {};
	for i, model in ipairs(models) do
		models.id_model_map[model.id_data] = model
	end
	-- only used by block rotation
	self.models2 = models;
end

function block:Init()
end

local lCubeIndex = 16;
local function _isMatch(blockIndex, blockX, blockY, blockZ)
	local block_pos_x = BlockEngine:GetBlock(blockX + 1, blockY, blockZ);
	local block_neg_x = BlockEngine:GetBlock(blockX-1, blockY, blockZ);
	local block_pos_y = BlockEngine:GetBlock(blockX, blockY + 1, blockZ);
	local block_neg_y = BlockEngine:GetBlock(blockX, blockY-1, blockZ);
	local block_pos_z = BlockEngine:GetBlock(blockX, blockY, blockZ + 1);
	local block_neg_z = BlockEngine:GetBlock(blockX, blockY, blockZ-1);
	local block_index_pos_x = nil;
	local block_index_neg_x = nil;
	local block_index_pos_y = nil;
	local block_index_neg_y = nil;
	local block_index_pos_z = nil;
	local block_index_neg_z = nil;
	if block_pos_x and block_pos_x.modelName == "slope" then
		block_index_pos_x = band(BlockEngine:GetBlockData(blockX + 1, blockY, blockZ), 0xff);
	end
	if block_neg_x and block_neg_x.modelName == "slope" then
		block_index_neg_x = band(BlockEngine:GetBlockData(blockX-1, blockY, blockZ), 0xff);
	end
	if block_pos_y and block_pos_y.modelName == "slope" then
		block_index_pos_y = band(BlockEngine:GetBlockData(blockX, blockY + 1, blockZ), 0xff);
	end
	if block_neg_y and block_neg_y.modelName == "slope" then
		block_index_neg_y = band(BlockEngine:GetBlockData(blockX, blockY-1, blockZ), 0xff);
	end
	if block_pos_z and block_pos_z.modelName == "slope" then
		block_index_pos_z = band(BlockEngine:GetBlockData(blockX, blockY, blockZ + 1), 0xff);
	end
	if block_neg_z and block_neg_z.modelName == "slope" then
		block_index_neg_z = band(BlockEngine:GetBlockData(blockX, blockY, blockZ-1), 0xff);
	end
	if 0==blockIndex then
		if block_index_pos_x
		or block_index_neg_x 
		or block_index_pos_y 
		or(block_index_neg_y and block_index_neg_y~=3)
		or(not block_index_pos_z and not block_index_neg_z and not block_index_neg_y)
		or(block_index_pos_z and block_index_pos_z~=12 and block_index_pos_z~=blockIndex) 
		or(block_index_neg_z and block_index_neg_z~=8 and block_index_neg_z~=blockIndex) then
			return false;
		end
	elseif 1==blockIndex then
		if block_index_neg_x
		or block_index_pos_x 
		or block_index_pos_y 
		or(block_index_neg_y and block_index_neg_y~=2)
		or(not block_index_pos_z and not block_index_neg_z and not block_index_neg_y)
		or(block_index_pos_z and block_index_pos_z~=9 and block_index_pos_z~=blockIndex) 
		or(block_index_neg_z and block_index_neg_z~=13 and block_index_neg_z~=blockIndex) then
			return false;
		end
	elseif 2==blockIndex then
		if block_index_neg_x
		or block_index_pos_x
		or(block_index_pos_y and block_index_pos_y~=1)
		or block_index_neg_y
		or(not block_index_pos_z and not block_index_neg_z and not block_index_pos_y)
		or(block_index_pos_z and block_index_pos_z~=14 and block_index_pos_z~=blockIndex) 
		or(block_index_neg_z and block_index_neg_z~=10 and block_index_neg_z~=blockIndex) then
			return false;
		end
	elseif 3==blockIndex then
		if block_index_pos_x
		or block_index_neg_x
		or(block_index_pos_y and block_index_pos_y~=0)
		or block_index_neg_y
		or(not block_index_pos_z and not block_index_neg_z and not block_index_pos_y)
		or(block_index_pos_z and block_index_pos_z~=11 and block_index_pos_z~=blockIndex) 
		or(block_index_neg_z and block_index_neg_z~=15 and block_index_neg_z~=blockIndex) then
			return false;
		end
	elseif 4==blockIndex then
		if block_index_pos_z
		or block_index_neg_z
		or(block_index_pos_y and block_index_pos_y~=7)
		or block_index_neg_y
		or(not block_index_pos_x and not block_index_neg_x and not block_index_pos_y)
		or(block_index_pos_x and block_index_pos_x~=14 and block_index_pos_x~=blockIndex) 
		or(block_index_neg_x and block_index_neg_x~=11 and block_index_neg_x~=blockIndex) then
			return false;
		end
	elseif 5==blockIndex then
		if block_index_pos_z
		or block_index_neg_z
		or(block_index_pos_y and block_index_pos_y~=6)
		or block_index_neg_y
		or(not block_index_pos_x and not block_index_neg_x and not block_index_pos_y)
		or(block_index_pos_x and block_index_pos_x~=10 and block_index_pos_x~=blockIndex) 
		or(block_index_neg_x and block_index_neg_x~=15 and block_index_neg_x~=blockIndex) then
			return false;
		end
	elseif 6==blockIndex then
		if block_index_pos_z
		or block_index_neg_z 
		or block_index_pos_y 
		or(block_index_neg_y and block_index_neg_y~=5)
		or(not block_index_pos_x and not block_index_neg_x and not block_index_neg_y)
		or(block_index_pos_x and block_index_pos_x~=13 and block_index_pos_x~=blockIndex) 
		or(block_index_neg_x and block_index_neg_x~=8 and block_index_neg_x~=blockIndex) then
			return false;
		end
	elseif 7==blockIndex then
		if block_index_neg_z
		or block_index_pos_z 
		or block_index_pos_y 
		or(block_index_neg_y and block_index_neg_y~=4)
		or(not block_index_pos_x and not block_index_neg_x and not block_index_neg_y)
		or(block_index_pos_x and block_index_pos_x~=9 and block_index_pos_x~=blockIndex) 
		or(block_index_neg_x and block_index_neg_x~=12 and block_index_neg_x~=blockIndex) then
			return false;
		end
	elseif 8==blockIndex then
		if block_index_pos_x~=6 or block_index_pos_z ~=0 then
			return false;
		end
	elseif 9==blockIndex then
		if block_index_neg_x~=7 or block_index_neg_z~=1 then
			return false;
		end
	elseif 10==blockIndex then
		if block_index_neg_x~=5 or block_index_pos_z~=2 then
			return false;
		end
	elseif 11==blockIndex then
		if block_index_pos_x~=4 or block_index_neg_z~=3 then
			return false;
		end
	elseif 12==blockIndex then
		if block_index_pos_x~=7 or block_index_neg_z~=0 then
			return false;
		end
	elseif 13==blockIndex then
		if block_index_neg_x~=6 or block_index_pos_z~=1 then
			return false;
		end
	elseif 14==blockIndex then
		if block_index_neg_x~=4 or block_index_neg_z~=2 then
			return false;
		end
	elseif 15==blockIndex then
		if block_index_pos_x~=5 or block_index_pos_z~=3 then
			return false;
		end
	elseif 16==blockIndex then
		if block_index_pos_x~=6 or block_index_neg_z~=1 then
			return false;
		end
	elseif 17==blockIndex then
		if block_index_pos_x~=5 or block_index_neg_z~=2 then
			return false;
		end
	elseif 18==blockIndex then
		if block_index_neg_x~=6 or block_index_neg_z~=0 then
			return false;
		end
	elseif 19==blockIndex then
		if block_index_neg_x~=5 or block_index_neg_z~=3 then
			return false;
		end
	elseif 20==blockIndex then
		if block_index_neg_x~=7 or block_index_pos_z~=0 then
			return false;
		end
	elseif 21==blockIndex then
		if block_index_neg_x~=4 or block_index_pos_z~=3 then
			return false;
		end
	elseif 22==blockIndex then
		if block_index_pos_x~=7 or block_index_pos_z~=1 then
			return false;
		end
	elseif 23==blockIndex then
		if block_index_pos_x~=4 or block_index_pos_z~=2 then
			return false;
		end
	else
		return false;
	end
	return true;
end

local dir_side_to_data = {
 [0] = {[0] = -24, [1] = -24, [2] = 3, [3] = 0, [4] = -22, [5] = -24},
 [1] = {[0] = -23, [1] = -23, [2] = 2, [3] = 1, [4] = -22, [5] = -23},
 [2] = {[0] = 3, [1] = 2, [2] = -18, [3] = -18, [4] = -19, [5] = -18},
 [3] = {[0] = 0, [1] = 1, [2] = -17, [3] = -17, [4] = -20, [5] = -17},
};

function block:GetMetaDataFromEnv(blockX, blockY, blockZ, side, side_region, camx, camy, camz, lookat_x, lookat_y, lookat_z)
	local data = nil;
	for i = 0, 23 do
		if _isMatch(i, blockX, blockY, blockZ) then
			data = i;
			break;
		end
	end

	if (not data and side < 4) then
		local dir = Direction.GetDirection3DFromCamera(camx,camy,camz, lookat_x,lookat_y,lookat_z);
		data = 24 + dir_side_to_data[side][dir];
	end

	if not data then
		NPL.load("(gl)script/ide/math/math3d.lua");
		local math3d = commonlib.gettable("mathlib.math3d");
		local dx, dy, dz = math3d.CameraToWorldSpace(0, 0, 1, camx, camy, camz, lookat_x, lookat_y, lookat_z);
		if math.abs(dx)>=math.abs(dz) and dx>=0 and dy<=0 then
			data = 0;
		elseif math.abs(dx)>=math.abs(dz) and dx<=0 and dy<=0 then
			data = 1;
		elseif math.abs(dx)>=math.abs(dz) and dx<=0 and dy>=0 then
			data = 2;
		elseif math.abs(dx)>=math.abs(dz) and dx>=0 and dy>=0 then
			data = 3;
		elseif math.abs(dz)>=math.abs(dx) and dy>=0 and dz<=0 then
			data = 4;
		elseif math.abs(dz)>=math.abs(dx) and dy>=0 and dz>=0 then
			data = 5;
		elseif math.abs(dz)>=math.abs(dx) and dy<=0 and dz>=0 then
			data = 6;
		elseif math.abs(dz)>=math.abs(dx) and dy<=0 and dz<=0 then
			data = 7;
		end
	end
	return data;
end

local minX_data = {[1] = 0.5,[5] = 0.5,[8] = 0.5, }
local maxX_data = {[2] = 0.5,[6] = 0.5,[7] = 0.5, }

local minZ_data = {[3] = 0.5,[5] = 0.5,[6] = 0.5, }
local maxZ_data = {[4] = 0.5,[7] = 0.5,[8] = 0.5, }

-- Adds all intersecting collision boxes representing this block to a list.
-- @param list: in|out array list to hold the output
-- @param aabb: only add if collide with this aabb. 
-- @param entity: 
function block:AddCollisionBoxesToList(x, y, z, aabb, list, entity)
	local data = BlockEngine:GetBlockData(x, y, z);
	data = band(data, 0xff);
	if(data <= 8) then
	    -- lower half
		self:SetBlockBounds(0.0, 0.0, 0.0, 1.0, 0.5, 1.0);
		block._super.AddCollisionBoxesToList(self, x, y, z, aabb, list, entity);
		-- top half
		local minX, minY, minZ = minX_data[data] or 0, 0.5, minZ_data[data] or 0;
		local maxX, maxY, maxZ = maxX_data[data] or 1, 1.0, maxZ_data[data] or 1;
		self:SetBlockBounds(minX, minY, minZ, maxX, maxY, maxZ);
		block._super.AddCollisionBoxesToList(self, x, y, z, aabb, list, entity);
	else
		-- everything else is standard cube
		self:SetBlockBounds(0.0, 0.0, 0.0, 1.0, 1.0, 1.0);
		block._super.AddCollisionBoxesToList(self, x, y, z, aabb, list, entity);
	end
end

-- rotate the block data by the given angle and axis. This is mosted reimplemented in blocks with orientations stored in block data, such as slope, bones, etc. 
-- @param blockData: current block data
-- @param angle: usually 1.57, -1.57, 3.14, -3.14, 0. 
-- @param axis: "x|y|z", if nil, it should default to "y" axis
-- @return the rotated block data. 
function block:RotateBlockData(blockData, angle, axis)
	local highColorData = band(blockData, 0xff00)
	blockData = band(blockData, 0xff);
	return self:RotateBlockDataUsingModelFacing(blockData, angle, axis) + highColorData;
end

-- mirror the block data along the given axis. This is mosted reimplemented in blocks with orientations stored in block data, such as slope, bones, etc. 
-- @param blockData: current block data
-- @param axis: "x|y|z", if nil, it should default to "y" axis
-- @return the mirrored block data. 
function block:MirrorBlockData(blockData, axis)
	function block:MirrorBlockData(blockData, axis)
	local highColorData = band(blockData, 0xff00)
	blockData = band(blockData, 0xff);
	if(axis == "x") then
		if(blockData == 1) then
			blockData = 0;
		elseif(blockData == 0) then
			blockData = 1;
		elseif(blockData == 9) then
			blockData = 12;
		elseif(blockData == 12) then
			blockData = 9;
		elseif(blockData == 13) then
			blockData = 8;
		elseif(blockData == 8) then
			blockData = 13;
		elseif(blockData == 2) then
			blockData = 3;
		elseif(blockData == 3) then
			blockData = 2;
		elseif(blockData == 14) then
			blockData = 11;
		elseif(blockData == 11) then
			blockData = 14;
		elseif(blockData == 15) then
			blockData = 10
		elseif(blockData == 10) then
			blockData = 15;
		end
	elseif(axis == "z") then
		if(blockData == 7) then
			blockData = 6;
		elseif(blockData == 6) then
			blockData = 7;
		elseif(blockData == 9) then
			blockData = 13;
		elseif(blockData == 13) then
			blockData = 9;
		elseif(blockData == 12) then
			blockData = 8;
		elseif(blockData == 8) then
			blockData = 12;
		elseif(blockData == 11) then
			blockData = 15;
		elseif(blockData == 15) then
			blockData = 11;
		elseif(blockData == 14) then
			blockData = 10;
		elseif(blockData == 10) then
			blockData = 14;
		elseif(blockData == 4) then
			blockData = 5;
		elseif(blockData == 5) then
			blockData = 4;
		end
	else -- "y"
		if(blockData == 7) then
			blockData = 4;
		elseif(blockData == 4) then
			blockData = 7;
		elseif(blockData == 12) then
			blockData = 11;
		elseif(blockData == 11) then
			blockData = 12;
		elseif(blockData == 0) then
			blockData = 3;
		elseif(blockData == 3) then
			blockData = 0;
		elseif(blockData == 15) then
			blockData = 8;
		elseif(blockData == 8) then
			blockData = 15;
		elseif(blockData == 6) then
			blockData = 5;
		elseif(blockData == 5) then
			blockData = 6;
		elseif(blockData == 13) then
			blockData = 10;
		elseif(blockData == 10) then
			blockData = 13;
		elseif(blockData == 2) then
			blockData = 1;
		elseif(blockData == 1) then
			blockData = 2;
		elseif(blockData == 14) then
			blockData = 9;
		elseif(blockData == 9) then
			blockData = 14;
		end
	end
	return blockData + highColorData;
end
end

function block:GetModelByBlockData2(blockData)
	if(self.models2 and blockData and self.models2.id_model_map) then
		return self.models2.id_model_map[blockData];
	end
end

-- helper function: can be used by RotateBlockData() to automatically calculate rotated block facing. 
-- please note, it will cache last search result to accelerate subsequent calls.
function block:RotateBlockDataUsingModelFacing(blockData, angle, axis)
	if(not axis or axis == "y") then
		local lastModel = self:GetModelByBlockData2(blockData)
		if(lastModel) then
			local lastFacing = lastModel.facing;
			if(lastFacing) then
				facing = lastFacing + angle;
				if(facing < 0) then
					facing = facing + 6.28;
				end
				facing = (math.floor(facing/1.57+0.5) % 4) * 1.57;

				if(not lastModel.facings) then
					lastModel.facings = {};
					for _, model in ipairs(self.models2) do
						if(model.assetfile == lastModel.assetfile and model.facing and model.transform==lastModel.transform) then
							lastModel.facings[model.facing] = model.id_data;
						end
					end
					if(not lastModel.facings[3.14] and lastModel.facings[0]) then
						lastModel.facings[3.14] = lastModel.facings[0];
					end
					if(not lastModel.facings[4.71] and lastModel.facings[1.57]) then
						lastModel.facings[4.71] = lastModel.facings[1.57];
					end
				end
				blockData = lastModel.facings[facing] or blockData;
			end
		end
	else
		-- TODO: other axis
	end
	return blockData;
end