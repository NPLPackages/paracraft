--[[
Title: ChunkLocation
Author(s): LiXizhi
Date: 2014/7/3
Desc: each chunk is 16*16*N(256) columns. Chunk location is the location in of chunk pos in the world.
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ChunkLocation.lua");
local ChunkLocation = commonlib.gettable("MyCompany.Aries.Game.Common.ChunkLocation");
local chunkLoc = ChunkLocation:new():Init(chunkX, chunkZ)
local chunkLoc = ChunkLocation:FromWorldPos(worldX, worldZ);
chunkLoc:GetIndex();
-----------------------------------------------
]]
NPL.load("(gl)script/ide/math/bit.lua");

local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

local ChunkLocation = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.ChunkLocation"))

function ChunkLocation:ctor()
end

function ChunkLocation:Init(chunkX, chunkZ)
	self.chunkX, self.chunkZ = chunkX, chunkZ;
	self.chunkPackedPos = lshift(chunkX, 12) + chunkZ;
	return self;
end

function ChunkLocation:GetPackedChunkPos()
	return self.chunkPackedPos;
end

-- static function: 
function ChunkLocation:GetChunkPosFromWorldPos(WorldX, WorldZ)
	return rshift(WorldX, 4), rshift(WorldZ, 4);
end

-- static function: create a new pos from world block position. 
function ChunkLocation:FromWorldPos(WorldX, WorldZ)
	local chunkX = rshift(WorldX, 4);
	local chunkZ = rshift(WorldZ, 4);
	return ChunkLocation:new():Init(chunkX, chunkZ);
end

-- static function:
function ChunkLocation:FromChunkPos(chunkX, chunkZ)
    return ChunkLocation:new():Init(chunkX, chunkZ);
end

-- static function:
function ChunkLocation:FromPackedChunkPos(chunkPackedPos)
	local chunkX = rshift(chunkPackedPos,12);
	local chunkZ = band(chunkPackedPos, 0xFFF);
    return ChunkLocation:new():Init(chunkX, chunkZ);
end

function ChunkLocation:equals(r)
	return self.chunkPackedPos == r.chunkPackedPos;
end

function ChunkLocation:DistanceToSquared(coords)
	local diffX = coords.chunkX - self.chunkX;
    local diffZ = coords.chunkZ - self.chunkZ;
    return diffX * diffX + diffZ * diffZ;
end

function ChunkLocation:DistanceTo(coords)
    return math.sqrt(self:DistanceToSquared(coords));
end

-- static function
function ChunkLocation.FromChunkToPackedChunk(chunkX, chunkZ)
   return lshift(chunkX, 12) + chunkZ;
end

