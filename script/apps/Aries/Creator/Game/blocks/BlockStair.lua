--[[
Title: Stair Based Block
Author(s): LiXizhi
Date: 2013/12/15
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockStair.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockStair")
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
local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockStair"));

-- register
block_types.RegisterBlockClass("BlockStair", block);

function block:ctor()
end


function block:Init()
	
end

local to_upper_data = {
	12, 10, 11, 13
}
function block:GetMetaDataFromEnv(blockX, blockY, blockZ, side, side_region, camx,camy,camz, lookat_x,lookat_y,lookat_z)
	local data;
	local force_condition;

	if(side) then
		local direction = Direction.GetDirectionFromCamera(camx,camy,camz, lookat_x,lookat_y,lookat_z);
		if(direction == 1) then
			data = 1;
			local blockBack = BlockEngine:GetBlock(blockX+1, blockY, blockZ);
			if(blockBack and blockBack.modelName == "stairs") then
				local userData = band(BlockEngine:GetBlockData(blockX+1, blockY, blockZ), 0xff);
				if(userData == 3) then
					data = 5;	
				elseif(userData == 4) then
					data = 8;	
				elseif(to_upper_data[3] == userData) then
					data = 14;
				elseif(to_upper_data[4] == userData) then
					data = 17;
				end
			end
			if(data == 1) then
				local blockBack = BlockEngine:GetBlock(blockX-1, blockY, blockZ);
				if(blockBack and blockBack.modelName == "stairs") then
					local userData = band(BlockEngine:GetBlockData(blockX-1, blockY, blockZ), 0xff);
					if(userData == 3) then
						data = 18;	
					elseif(userData == 4) then
						data = 21;
					elseif(to_upper_data[3] == userData) then
						data = 22;
					elseif(to_upper_data[4] == userData) then
						data = 25;
					end
				end
			end
		elseif(direction == 2) then
			data = 3;
			local blockBack = BlockEngine:GetBlock(blockX, blockY, blockZ+1);
			if(blockBack and blockBack.modelName == "stairs") then
				local userData = band(BlockEngine:GetBlockData(blockX, blockY, blockZ+1), 0xff);
				if(userData == 1) then
					data = 5;	
				elseif(userData == 2) then
					data = 6;	
				elseif(to_upper_data[1] == userData) then
					data = 14;
				elseif(to_upper_data[2] == userData) then
					data = 15;
				end
			end
			if(data == 3) then
				local blockBack = BlockEngine:GetBlock(blockX, blockY, blockZ-1);
				if(blockBack and blockBack.modelName == "stairs") then
					local userData = band(BlockEngine:GetBlockData(blockX, blockY, blockZ-1), 0xff);
					if(userData == 1) then
						data = 18;	
					elseif(userData == 2) then
						data = 19;	
					elseif(to_upper_data[1] == userData) then
						data = 22;
					elseif(to_upper_data[2] == userData) then
						data = 23;
					end
				end
			end
		elseif(direction == 3) then
			data = 4;
			local blockBack = BlockEngine:GetBlock(blockX, blockY, blockZ-1);
			if(blockBack and blockBack.modelName == "stairs") then
				local userData = band(BlockEngine:GetBlockData(blockX, blockY, blockZ-1), 0xff);
				if(userData == 1) then
					data = 8;	
				elseif(userData == 2) then
					data = 7;	
				elseif(to_upper_data[1] == userData) then
					data = 17;
				elseif(to_upper_data[2] == userData) then
					data = 16;
				end
			end
			if(data == 4) then
				local blockBack = BlockEngine:GetBlock(blockX, blockY, blockZ+1);
				if(blockBack and blockBack.modelName == "stairs") then
					local userData = band(BlockEngine:GetBlockData(blockX, blockY, blockZ+1), 0xff);
					if(userData == 1) then
						data = 21;	
					elseif(userData == 2) then
						data = 20;	
					elseif(to_upper_data[1] == userData) then
						data = 25;
					elseif(to_upper_data[2] == userData) then
						data = 24;
					end
				end
			end
		else
			data = 2;
			local blockBack = BlockEngine:GetBlock(blockX-1, blockY, blockZ);
			if(blockBack and blockBack.modelName == "stairs") then
				local userData = band(BlockEngine:GetBlockData(blockX-1, blockY, blockZ), 0xff);
				if(userData == 3) then
					data = 6;	
				elseif(userData == 4) then
					data = 7;
				elseif(to_upper_data[3] == userData) then
					data = 15;
				elseif(to_upper_data[4] == userData) then
					data = 16;
				end
			end
			if(data == 2) then
				local blockBack = BlockEngine:GetBlock(blockX+1, blockY, blockZ);
				if(blockBack and blockBack.modelName == "stairs") then
					local userData = band(BlockEngine:GetBlockData(blockX+1, blockY, blockZ), 0xff);
					if(userData == 3) then
						data = 19;	
					elseif(userData == 4) then
						data = 20;
					elseif(to_upper_data[3] == userData) then
						data = 23;
					elseif(to_upper_data[4] == userData) then
						data = 24;
					end
				end
			end
		end
		if(side_region == "upper") then
			data = to_upper_data[data] or data;
		end
	end
	if(self.customModel) then
		local best_model = self:GetBestModel(blockX, blockY, blockZ, data, side, force_condition);
		if(best_model) then
			data = best_model.id_data or data;
		end
	end
	return data or 0;
end

local minX_data = {[1] = 0.5, [5]=0.5, [8] = 0.5, }
local maxX_data = {[2] = 0.5, [6]=0.5, [7] = 0.5, }

local minZ_data = {[3] = 0.5, [5]=0.5, [6] = 0.5, }
local maxZ_data = {[4] = 0.5, [7]=0.5, [8] = 0.5, }

-- Adds all intersecting collision boxes representing this block to a list.
-- @param list: in|out array list to hold the output
-- @param aabb: only add if collide with this aabb. 
-- @param entity: 
function block:AddCollisionBoxesToList(x,y,z, aabb, list, entity)
	local data = band(BlockEngine:GetBlockData(x,y,z), 0xff);
	if (data <= 8) then
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

-- rotate the block data by the given angle and axis. This is mosted reimplemented in blocks with orientations stored in block data, such as stairs, bones, etc. 
-- @param blockData: current block data
-- @param angle: usually 1.57, -1.57, 3.14, -3.14, 0. 
-- @param axis: "x|y|z", if nil, it should default to "y" axis
-- @return the rotated block data. 
function block:RotateBlockData(blockData, angle, axis)
	local highColorData = band(blockData, 0xff00)
	blockData = band(blockData, 0xff);
	return self:RotateBlockDataUsingModelFacing(blockData, angle, axis) + highColorData;
end

-- mirror the block data along the given axis. This is mosted reimplemented in blocks with orientations stored in block data, such as stairs, bones, etc. 
-- @param blockData: current block data
-- @param axis: "x|y|z", if nil, it should default to "y" axis
-- @return the mirrored block data. 
function block:MirrorBlockData(blockData, axis)
	local highColorData = band(blockData, 0xff00)
	blockData = band(blockData, 0xff);
	if(axis == "x") then
		if(blockData == 10) then
			blockData = 12;
		elseif(blockData == 2) then
			blockData = 1;
		elseif(blockData == 12) then
			blockData = 10;
		elseif(blockData == 1) then
			blockData = 2;
		elseif(blockData == 7) then
			blockData = 8;
		elseif(blockData == 8) then
			blockData = 7;
		elseif(blockData == 6) then
			blockData = 5;
		elseif(blockData == 5) then
			blockData = 6;
		elseif(blockData == 16) then
			blockData = 17;
		elseif(blockData == 17) then
			blockData = 16;
		elseif(blockData == 15) then
			blockData = 14
		elseif(blockData == 14) then
			blockData = 15;
		end
	elseif(axis == "z") then
		if(blockData == 11) then
			blockData = 13;
		elseif(blockData == 3) then
			blockData = 4;
		elseif(blockData == 13) then
			blockData = 11;
		elseif(blockData == 4) then
			blockData = 3;
		elseif(blockData == 6) then
			blockData = 7;
		elseif(blockData == 7) then
			blockData = 6;
		elseif(blockData == 5) then
			blockData = 8;
		elseif(blockData == 8) then
			blockData = 5;
		elseif(blockData == 15) then
			blockData = 16;
		elseif(blockData == 16) then
			blockData = 15;
		elseif(blockData == 14) then
			blockData = 17;
		elseif(blockData == 17) then
			blockData = 14;
		end
	else -- "y"
		if(blockData == 12) then
			blockData = 1;
		elseif(blockData == 1) then
			blockData = 12;
		elseif(blockData == 3) then
			blockData = 11;
		elseif(blockData == 11) then
			blockData = 3;
		elseif(blockData == 2) then
			blockData = 10;
		elseif(blockData == 10) then
			blockData = 2;
		elseif(blockData == 13) then
			blockData = 4;
		elseif(blockData == 4) then
			blockData = 13;
		elseif(blockData == 7) then
			blockData = 16;
		elseif(blockData == 16) then
			blockData = 7;
		elseif(blockData == 8) then
			blockData = 17;
		elseif(blockData == 17) then
			blockData = 8;
		elseif(blockData == 14) then
			blockData = 5;
		elseif(blockData == 5) then
			blockData = 14;
		elseif(blockData == 6) then
			blockData = 15;
		elseif(blockData == 15) then
			blockData = 6;
		end
	end
	return blockData + highColorData;
end