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
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

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
				local userData = BlockEngine:GetBlockData(blockX+1, blockY, blockZ);
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
					local userData = BlockEngine:GetBlockData(blockX-1, blockY, blockZ);
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
				local userData = BlockEngine:GetBlockData(blockX, blockY, blockZ+1);
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
					local userData = BlockEngine:GetBlockData(blockX, blockY, blockZ-1);
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
				local userData = BlockEngine:GetBlockData(blockX, blockY, blockZ-1);
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
					local userData = BlockEngine:GetBlockData(blockX, blockY, blockZ+1);
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
				local userData = BlockEngine:GetBlockData(blockX-1, blockY, blockZ);
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
					local userData = BlockEngine:GetBlockData(blockX+1, blockY, blockZ);
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

		--[[ -- old code using condition
		local direction = Direction.GetDirectionFromCamera(camx,camy,camz, lookat_x,lookat_y,lookat_z);
		if(direction) then
			direction = direction*2;
			
			local block_id;
			if(direction == 2) then
				block_id = ParaTerrain.GetBlockTemplateByIdx(blockX+1, blockY, blockZ);
			elseif(direction == 4) then
				block_id = ParaTerrain.GetBlockTemplateByIdx(blockX, blockY, blockZ+1);
			elseif(direction == 6) then
				block_id = ParaTerrain.GetBlockTemplateByIdx(blockX, blockY, blockZ-1);
			elseif(direction == 8) then
				block_id = ParaTerrain.GetBlockTemplateByIdx(blockX-1, blockY, blockZ);
			end
			if(block_id == 0) then
				force_condition = force_condition or {};
				force_condition[direction] = 'solid';
			end
		end

		if(side_region == "upper") then
			force_condition = force_condition or {};
			force_condition[0] = 'solid';
		elseif(side_region == "lower") then
			force_condition = force_condition or {};
			force_condition[5] = 'solid';
		end
		]]
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
	local data = BlockEngine:GetBlockData(x,y,z);
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
	return self:RotateBlockDataUsingModelFacing(blockData, angle, axis);
end

-- mirror the block data along the given axis. This is mosted reimplemented in blocks with orientations stored in block data, such as stairs, bones, etc. 
-- @param blockData: current block data
-- @param axis: "x|y|z", if nil, it should default to "y" axis
-- @return the mirrored block data. 
function block:MirrorBlockData(blockData, axis)
	-- TODO: 
	return blockData;
end