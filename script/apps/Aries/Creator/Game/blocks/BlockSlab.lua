--[[
Title: Slab Based Block
Author(s): LiXizhi
Date: 2013/1/23
Desc: 
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
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

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
    if(self.collisionAABBs)then
		local data = BlockEngine:GetBlockData(x,y,z)
	    local aabb = self.collisionAABBs[mathlib.bit.band(data, 0xf)];
	    if( aabb ) then
		    return aabb:clone_from_pool():Offset(BlockEngine:real_min(x,y,z));
	    end
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

local mirrorDataMap
local function GetMirrorMap()
	if(mirrorDataMap) then
		return mirrorDataMap;
	else
		mirrorDataMap = {
			["x"] = {
				[4] = 5,
			},
			["y"] = {
				[0] = 1,
			},
			["z"] = {
				[2] = 3,
			},
		}
		-- add reverse mapping to data pair
		for axis, dataMap in pairs(mirrorDataMap) do
			local dataMap1 = {}
			for k, v in pairs(dataMap) do
				dataMap1[v] = k;
			end
			for k, v in pairs(dataMap1) do
				dataMap[k] = v;
			end
		end
		return mirrorDataMap;
	end
end

-- mirror the block data along the given axis. This is mosted reimplemented in blocks with orientations stored in block data, such as slope, bones, etc. 
-- @param blockData: current block data
-- @param axis: "x|y|z", if nil, it should default to "y" axis
-- @return the mirrored block data. 
function block:MirrorBlockData(blockData, axis)
	local highColorData = band(blockData, 0xff00)
	blockData = band(blockData, 0xff);
	blockData = GetMirrorMap()[axis or "y"][blockData] or blockData
	return blockData + highColorData;
end

local rotateDataMap
local function GetRotateMap()
	if(rotateDataMap) then
		return rotateDataMap;
	else
		rotateDataMap = {
			["x"] = {
				[2] = {1.57, facingIds = {3,0,1}},
				[3] = {4.71, facingIds = {2,0,1}},
				[0] = {0, facingIds = {3,2,1}},
				[1] = {3.14, facingIds = {3,2,0}},
			},
			["y"] = {
				[2] = {0, facingIds = {3,4,5} },
				[3] = {3.14, facingIds = {2,4,5} },
				[4] = {1.57, facingIds = {2,3,5} },
				[5] = {4.71, facingIds = {2,3,4} },
			},
			["z"] = {
				[4] = {4.71, facingIds = {5,0,1}},
				[5] = {1.57, facingIds = {4,0,1}},
				[0] = {0, facingIds = {4,5,1}},
				[1] = {3.14, facingIds = {4,5,0}},
			},
		}
		-- add reverse angle mapping
		for axis, dataMap in pairs(rotateDataMap) do
			for k, v in pairs(dataMap) do
				local angleToId = {}
				for i, id in ipairs(v.facingIds) do
					local item = dataMap[id]
					if(item) then
						angleToId[item[1]] = id;
					end
				end
				v.angleToId = angleToId;
			end
		end
		return rotateDataMap;
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
	local rotConfig = GetRotateMap()[axis or "y"][blockData]
	if(rotConfig) then
		local facing = rotConfig[1] + (angle or 0)
		if(facing < 0) then
			facing = facing + 6.28;
		end
		facing = (math.floor(facing/1.57+0.5) % 4) * 1.57;
		blockData = rotConfig.angleToId[facing] or blockData;
	end
	return blockData + highColorData;
end
