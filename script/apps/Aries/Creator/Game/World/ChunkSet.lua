--[[
Title: ChunkSet
Author(s): LiXizhi
Date: 2013/8/27
Desc: 16*16(*256) block columns
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkSet.lua");
local ChunkSet = commonlib.gettable("MyCompany.Aries.Game.World.ChunkSet");
local chunks = ChunkSet:new();
-----------------------------------------------
]]
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/UniversalCoords.lua");
local UniversalCoords = commonlib.gettable("MyCompany.Aries.Game.Common.UniversalCoords");

local tostring = tostring;
local format = format;
local type = type;
local ChunkSet = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.World.ChunkSet"))

local HALFSIZE = 16 * 16 * 128;

ChunkSet.IsReadOnly = false;

function ChunkSet:ctor()
	self.Chunks = {};
	self.Changes = 0;
	self.Count = 0;
end

--@param coords: UniversalCoords
function ChunkSet:Get(coords)
	if(coords) then
		return self.Chunks[coords.ChunkPackedCoords];
	end
end

--@param coords: UniversalCoords
function ChunkSet:Set(coords, chunk)
	if(coords) then
		self.Chunks[coords.ChunkPackedCoords] = chunk;
	end
end

function ChunkSet:GetByPos(chunkX, chunkZ)
	local packedCoords = UniversalCoords.FromChunkToPackedChunk(chunkX, chunkZ);
	return self.Chunks[packedCoords];
end

function ChunkSet:SetByPos(chunkX, chunkZ, chunk)
	local packedCoords = UniversalCoords.FromChunkToPackedChunk(chunkX, chunkZ);
	self.Chunks[packedCoords] = chunk;
end

function ChunkSet:Add(chunk)
	self:Set(chunk.Coords, chunk);
	chunk:InitBlockChangesTimer();
    self.Changes = self.Changes + 1;
end

--@param coords: UniversalCoords
function ChunkSet:RemoveByCoords(coords)
	self.Changes = self.Changes + 1;

	local chunk = self.Chunks[coords.ChunkPackedCoords];

    if(chunk) then
        chunk:Dispose();
		return true;
	end
end

function ChunkSet:Remove(chunk)
	chunk.Deleted = true;
	self:RemoveByCoords(coords);
end