--[[
Title: ChunkProviderClient
Author(s): LiXizhi
Date: 2014/7/19
Desc: chunk column provider interface. Custom block generator is used to automatically generate terrain. 
Both standalone client and server uses this class as the default ChunkProvider
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkProviderClient.lua");
local ChunkProviderClient = commonlib.gettable("MyCompany.Aries.Game.World.ChunkProviderClient");
-----------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ChunkLocation.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkCpp.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/Chunk.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkProvider.lua");
local ChunkCpp = commonlib.gettable("MyCompany.Aries.Game.World.ChunkCpp");
local Chunk = commonlib.gettable("MyCompany.Aries.Game.World.Chunk");
local ChunkLocation = commonlib.gettable("MyCompany.Aries.Game.Common.ChunkLocation");
local UniversalCoords = commonlib.gettable("MyCompany.Aries.Game.Common.UniversalCoords");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local ChunkProviderClient = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.World.ChunkProvider"), commonlib.gettable("MyCompany.Aries.Game.World.ChunkProviderClient"))

ChunkProviderClient.class_name = "ChunkProviderClient";

function ChunkProviderClient:ctor()
	-- mapping from packed chunk index to chunk
	self.loadedChunksMap = {};
	self.cpp_chunk = true;
end

function ChunkProviderClient:Init(world)
	self.worldObj = world;
	self.cpp_chunk = world.cpp_chunk;
	self.blankChunk = Chunk:new():Init(self.worldObj, 0, 0);
	return self;
end

-- Checks to see if a chunk column exists at x, z
function ChunkProviderClient:ChunkExists(chunkX, chunkZ)
	return true;
end

--  Will return back a chunk, if it doesn't exist and its not a MP client it will generates all the blocks for the
--  specified chunk from the map seed and chunk seed
function ChunkProviderClient:ProvideChunk(chunkX, chunkZ)
	local chunk = self.loadedChunksMap[ChunkLocation.FromChunkToPackedChunk(chunkX, chunkZ)];
	if(not chunk) then
		return self.blankChunk;
	else
		return chunk;
	end
end


function ChunkProviderClient:GetChunk(chunkX, chunkZ, bCreateIfNotExist)
	local chunk = self.loadedChunksMap[ChunkLocation.FromChunkToPackedChunk(chunkX, chunkZ)];
	if(chunk) then
		return chunk;
	else
		if(bCreateIfNotExist) then
			return self:LoadChunk(chunkX, chunkZ);
		end
	end
end


-- loads or generates the chunk at the chunk location specified
function ChunkProviderClient:LoadChunk(chunkX, chunkZ)
	local chunkIndex = ChunkLocation.FromChunkToPackedChunk(chunkX, chunkZ)
	
	local chunk = self.loadedChunksMap[chunkIndex];
	if(not chunk) then
		chunk = self:LoadChunkImp(chunkX, chunkZ);
		self.loadedChunksMap[chunkIndex] = chunk;
	end
	return chunk;
end

-- used by loadChunk to create and load the actually chunk
function ChunkProviderClient:LoadChunkImp(chunkX, chunkZ)
	local coords = UniversalCoords:new():FromChunk(chunkX, chunkZ);
	local chunk;
	if(self.cpp_chunk) then
		chunk = ChunkCpp:new():Init(self.worldObj, chunkX, chunkZ);
	else
		chunk = Chunk:new():Init(self.worldObj, chunkX, chunkZ);
	end
	self:AutoGenerateChunk(chunk);
	return chunk;
end

-- do nothing for client side chunk.
function ChunkProviderClient:AutoGenerateChunk(chunk)
	chunk:GetTimeStamp();
end

-- Populates chunk with decos, etc etc
function ChunkProviderClient:Populate(chuckProvider, chunkX, chunkZ)
end

-- Two modes of operation: if passed true, save all Chunks in one go.  If passed false, save up to two chunks.
-- Return true if all chunks have been saved.
function ChunkProviderClient:SaveChunks(bIsSync, progressCallback)
end

function ChunkProviderClient:UnloadChunk(chunkX, chunkZ)
	--local chunk = self:ProvideChunk(chunkX, chunkZ)
	--if(chunk and not chunk:IsEmpty()) then
		--chunk:OnChunkUnload();
		--local chunkIndex = ChunkLocation.FromChunkToPackedChunk(chunkX, chunkZ)
		--self.loadedChunksMap[chunkIndex] = nil;	
	--end
	--return chunk;
end

-- Unloads chunks that are marked to be unloaded. This is not guaranteed to unload every such chunk.
function ChunkProviderClient:UnloadQueuedChunks()
end

-- Returns true if supports saving.
function ChunkProviderClient:CanSave()
	return;
end

-- Converts the instance data to a readable string.
function ChunkProviderClient:MakeString()
end

-- Returns a list of creatures of the specified type that can spawn at the given location.
function ChunkProviderClient:GetPossibleCreatures(creatureType, x,y,z)
end

-- Returns the location of the closest structure of the specified type. If not found returns nil.
function ChunkProviderClient:FindClosestStructure(world, name, x,y,z)
end

-- marks all chunks for unload, ignoring those near the spawn
function ChunkProviderClient:UnloadAllChunks()
	for i, chunk in pairs(self.loadedChunksMap) do
	    self:UnloadChunksIfNotNearSpawn(chunk.Coords.WorldX, chunk.Coords.WorldZ);
	end
end

function ChunkProviderClient:OnExit()
	if(self:GetGenerator()) then
		self:GetGenerator():OnExit();
	end
end