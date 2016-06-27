--[[
Title: UniversalCoords
Author(s): LiXizhi
Date: 2013/8/27
Desc: 
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/UniversalCoords.lua");
local UniversalCoords = commonlib.gettable("MyCompany.Aries.Game.Common.UniversalCoords");
local c1 = UniversalCoords:new():FromWorld(20000, 0, 20000)
c1:FromBlock(16, 16, 1, 2, 3);
c1:FromChunk(16, 16);
c1:FromPackedChunk(0x00ff00ff);
-----------------------------------------------
]]
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/ide/math/bit.lua");

local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

local tostring = tostring;
local format = format;
local type = type;
local UniversalCoords = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.UniversalCoords"))

-- 1*1*1 block index inside a chunk
UniversalCoords.BlockPackedCoords = nil;
-- 16*16*16 section index inside a chunk
UniversalCoords.SectionPackedCoords = nil;
-- 16*16*256 chunk index inside a world. 
UniversalCoords.ChunkPackedCoords = nil;

function UniversalCoords:ctor()
	
end

function UniversalCoords:GetChunkX()
	return rshift(self.WorldX,4);
end

function UniversalCoords:GetChunkZ()
	return rshift(self.WorldZ,4);
end

function UniversalCoords:GetBlockX()
	return band(self.WorldX, 0xF);
end

function UniversalCoords:GetBlockY()
	return self.WorldY;
end

function UniversalCoords:GetBlockZ()
	return band(self.WorldZ, 0xF);
end

function UniversalCoords:GetRegionX()
	return rshift(self.WorldZ,9);
end

function UniversalCoords:GetRegionZ()
	return rshift(self.WorldZ,9);
end

function UniversalCoords:Clone(coord)
	if(coord.WorldX) then
		self:FromWorld(coord.WorldX, coord.WorldY, coord.WorldZ);
	end
	return self;
end

--Initialize from world position
function UniversalCoords:FromWorld(WorldX, WorldY, WorldZ)
	self.WorldX, self.WorldY, self.WorldZ = WorldX, WorldY, WorldZ;
	local chunkX = rshift(WorldX, 4);
	local chunkZ = rshift(WorldZ, 4);

	local packetXZ = bor( lshift(band(WorldZ , 0xF), 4), band(WorldX,0xF));
    self.BlockPackedCoords = bor(lshift(WorldY, 8), packetXZ); 
    self.SectionPackedCoords = bor(lshift(band(WorldY, 0xF), 8), packetXZ); 
    self.ChunkPackedCoords = lshift(chunkX, 12)+chunkZ; 
	return self;
end

function UniversalCoords:FromBlock(chunkX, chunkZ, blockX, blockY, blockZ)
    self.WorldX = lshift(chunkX, 4) + blockX;
    self.WorldY = blockY;
    self.WorldZ = lshift(chunkZ, 4) + blockZ;

	local packetXZ = bor( lshift(blockZ, 4), band(blockX,0xF));
    self.BlockPackedCoords = bor(blockY, packetXZ); 
    self.SectionPackedCoords = bor(lshift(band(blockY, 0xF), 8), packetXZ); 
    self.ChunkPackedCoords = lshift(chunkX, 12)+chunkZ; 
	return self;
end

function UniversalCoords:FromRegion(regionX, regionZ)
	return self:FromChunk(lshift(regionX,5), lshift(regionZ,5));
end

function UniversalCoords:FromChunk(chunkX, chunkZ)
    self.WorldX = lshift(chunkX, 4);
    self.WorldY = 0;
    self.WorldZ = lshift(chunkZ, 4);

    self.BlockPackedCoords = 0;
    self.SectionPackedCoords = 0;
    self.ChunkPackedCoords = lshift(chunkX, 12)+chunkZ; 
	return self;
end

function UniversalCoords:FromPackedChunk(packedChunk)
    self.WorldX = rshift(packedChunk,12)*16;
    self.WorldY = 0;
    self.WorldZ = band(packedChunk, 0xFFF)*16;

    self.BlockPackedCoords = 0;
    self.SectionPackedCoords = 0;
    self.ChunkPackedCoords = packedChunk;
	return self;
end

function UniversalCoords:equals(r)
	return self.WorldX == r.WorldX and self.WorldY == r.WorldY and self.WorldZ == r.WorldZ;
end

function UniversalCoords:DistanceToSquared(coords)
	local diffX = coords.WorldX - self.WorldX;
    local diffY = coords.WorldY - self.WorldY;
    local diffZ = coords.WorldZ - self.WorldZ;

    return diffX * diffX + diffY * diffY + diffZ * diffZ;
end

function UniversalCoords:DistanceTo(coords)
    return math.sqrt(self:DistanceToSquared(coords));
end

-- static function
function UniversalCoords.FromChunkToPackedChunk(chunkX, chunkZ)
   return lshift(chunkX, 12) + chunkZ;
end

function UniversalCoords.FromPackedChunkToX(packedChunk)
	return rshift(packedChunk, 12);
end

function UniversalCoords.FromPackedChunkToZ(packedChunk)
	return band(packedChunk, 0xFFF);
end