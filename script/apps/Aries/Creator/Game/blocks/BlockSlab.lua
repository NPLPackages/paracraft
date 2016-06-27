--[[
Title: Slab Based Block
Author(s): LiXizhi
Date: 2013/1/23
Desc: Such as a character or mob that can walk and attack. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockSlab.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockSlab")
-------------------------------------------------------
]]
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockSlab"));

-- register
block_types.RegisterBlockClass("BlockSlab", block);

function block:ctor()
end

function block:Init()
end

-- set the block bounds and collision AABB. 
function block:UpdateBlockBounds()
	if(not self.collisionAABBs) then
		self.collisionAABBs = {}
		-- lower
		self.collisionAABBs[0] = ShapeAABB:new():SetMinMaxValues(0,0,0,BlockEngine.blocksize, BlockEngine.half_blocksize, BlockEngine.blocksize);
		-- upper
		self.collisionAABBs[1] = ShapeAABB:new():SetMinMaxValues(0,BlockEngine.half_blocksize,0,BlockEngine.blocksize, BlockEngine.blocksize, BlockEngine.blocksize);
	end
end

-- Returns a bounding box from the pool of bounding boxes.
-- this box can change after the pool has been cleared to be reused
function block:GetCollisionBoundingBoxFromPool(x,y,z)
	local aabb = self.collisionAABBs[BlockEngine:GetBlockData(x,y,z)];
	if( aabb ) then
		return aabb:clone_from_pool():Offset(BlockEngine:real_min(x,y,z));
	end
end

function block:GetMetaDataFromEnv(blockX, blockY, blockZ, side, side_region, camx,camy,camz, lookat_x,lookat_y,lookat_z)
	local data;
	if(side_region == "upper") then
		data = 1
	elseif(side_region == "lower") then
		data = 0;
	end
	return data or 0;
end
