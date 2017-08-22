--[[
Title: ChunkProviderServer
Author(s): LiXizhi
Date: 2014/7/19
Desc: chunk column provider interface. Custom block generator is used to automatically generate terrain. 
Both standalone client and server uses this class as the default ChunkProvider
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkProviderServer.lua");
local ChunkProviderServer = commonlib.gettable("MyCompany.Aries.Game.World.ChunkProviderServer");
-----------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ChunkLocation.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkCpp.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/Chunk.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkProvider.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ChunkCpp = commonlib.gettable("MyCompany.Aries.Game.World.ChunkCpp");
local Chunk = commonlib.gettable("MyCompany.Aries.Game.World.Chunk");
local ChunkLocation = commonlib.gettable("MyCompany.Aries.Game.Common.ChunkLocation");
local UniversalCoords = commonlib.gettable("MyCompany.Aries.Game.Common.UniversalCoords");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local ChunkProviderServer = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.World.ChunkProvider"), commonlib.gettable("MyCompany.Aries.Game.World.ChunkProviderServer"))

ChunkProviderServer.class_name = "ChunkProviderServer";

function ChunkProviderServer:ctor()
	-- mapping from packed chunk index to chunk
	self.loadedChunksMap = {};
	self.chunksToUnload = commonlib.UnorderedArraySet:new();
	self.cpp_chunk = true;
end

function ChunkProviderServer:Init(world)
	self.worldObj = world;
	self.cpp_chunk = world.cpp_chunk;
	return self;
end

-- Checks to see if a chunk column exists at x, z
function ChunkProviderServer:ChunkExists(chunkX, chunkZ)
	return self.loadedChunksMap[ChunkLocation.FromChunkToPackedChunk(chunkX, chunkZ)] ~= nil
end

--  Will return back a chunk, if it doesn't exist and its not a MP client it will generates all the blocks for the
--  specified chunk from the map seed and chunk seed
function ChunkProviderServer:ProvideChunk(chunkX, chunkZ)
	local chunk = self.loadedChunksMap[ChunkLocation.FromChunkToPackedChunk(chunkX, chunkZ)];
	if(not chunk) then
		return self:LoadChunk(chunkX, chunkZ)
	else
		return chunk;
	end
end


function ChunkProviderServer:GetChunk(chunkX, chunkZ, bCreateIfNotExist)
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
function ChunkProviderServer:LoadChunk(chunkX, chunkZ)
	local chunkIndex = ChunkLocation.FromChunkToPackedChunk(chunkX, chunkZ)
	self.chunksToUnload:removeByValue(chunkIndex);

	local chunk = self.loadedChunksMap[chunkIndex];
	if(not chunk) then
		chunk = self:LoadChunkImp(chunkX, chunkZ);
		self.loadedChunksMap[chunkIndex] = chunk;
	end
	return chunk;
end

function ChunkProviderServer:GetWorld()
	return self.worldObj;
end

-- used by loadChunk to create and load the actual chunk
function ChunkProviderServer:LoadChunkImp(chunkX, chunkZ)
	local coords = UniversalCoords:new():FromChunk(chunkX, chunkZ);
	local chunk;
	if(self.cpp_chunk) then
		chunk = ChunkCpp:new():Init(self.worldObj, chunkX, chunkZ);
	else
		chunk = Chunk:new():Init(self.worldObj, chunkX, chunkZ);
	end

	local timeStamp = chunk:GetTimeStamp();
	if(timeStamp < 0) then
		-- try loading the region from server if not loaded before. 
		ParaBlockWorld.LoadRegion(GameLogic.GetBlockWorld(), chunk.Coords.WorldX, chunk.Coords.WorldY, chunk.Coords.WorldZ);
	end
	
	return chunk;
end

function ChunkProviderServer:IsForceSyncMode()
	return self.isForceSyncMode;
end

function ChunkProviderServer:SetForceSyncMode(isForceSyncMode)
	self.isForceSyncMode = isForceSyncMode ;
end

function ChunkProviderServer:AutoGenerateChunk(chunk)
	if(chunk and self:GetGenerator()) then
		local timeStamp = chunk:GetTimeStamp();
		if(timeStamp == 0) then
			-- only generate if it has not been generated before. 
			if(self:GetGenerator():GenerateChunk(chunk, chunk.chunkX, chunk.chunkZ, self:IsForceSyncMode())) then
				self:GetWorld():OnChunkGenerated(chunk.chunkX, chunk.chunkZ);
			end
		end
	end
end

-- Populates chunk with decos, etc etc
function ChunkProviderServer:Populate(chuckProvider, chunkX, chunkZ)
end

-- Two modes of operation: if passed true, save all Chunks in one go.  If passed false, save up to two chunks.
-- Return true if all chunks have been saved.
function ChunkProviderServer:SaveChunks(bIsSync, progressCallback)
end

function ChunkProviderServer:UnloadChunk(chunkX, chunkZ)
	local chunk = ChunkProviderServer:ProvideChunk(chunkX, chunkZ)
	if(chunk and not chunk:IsEmpty()) then
		chunk:OnChunkUnload();
		self.loadedChunksMap[chunkIndex] = nil;	
	end
	return chunk;
end

-- Unloads chunks that are marked to be unloaded. This is not guaranteed to unload every such chunk.
function ChunkProviderServer:UnloadQueuedChunks()
end

-- Returns true if supports saving.
function ChunkProviderServer:CanSave()
	return;
end

-- Converts the instance data to a readable string.
function ChunkProviderServer:MakeString()
end

-- Returns a list of creatures of the specified type that can spawn at the given location.
function ChunkProviderServer:GetPossibleCreatures(creatureType, x,y,z)
end

-- Returns the location of the closest structure of the specified type. If not found returns nil.
function ChunkProviderServer:FindClosestStructure(world, name, x,y,z)
end

function ChunkProviderServer:GetLoadedChunkCount()
	return 0;
end

function ChunkProviderServer:RecreateStructures(x,z)
end

-- marks chunk for unload by if there is no spawn point, or if the center of the chunk is
-- outside 128 blocks (x or z) of the spawn
function ChunkProviderServer:UnloadChunksIfNotNearSpawn(chunkX, chunkZ)
    local x, y, z = self.worldObj:GetSpawnPoint();
	if(x) then
		local dx = chunkX * 16 + 8 - x;
		local dz = chunkZ * 16 + 8 - z;
		local radius = 128;
		if (dx < -radius or dx > radius or dz < -radius or dz > radius) then
			-- TODO: 
			-- self.chunksToUnload.add(chunkX, chunkZ);
		end	
	end
end

-- marks all chunks for unload, ignoring those near the spawn
function ChunkProviderServer:UnloadAllChunks()
	for i, chunk in pairs(self.loadedChunksMap) do
	    self:UnloadChunksIfNotNearSpawn(chunk.Coords.WorldX, chunk.Coords.WorldZ);
	end
end

function ChunkProviderServer:OnExit()
	if(self:GetGenerator()) then
		self:GetGenerator():OnExit();
	end
end