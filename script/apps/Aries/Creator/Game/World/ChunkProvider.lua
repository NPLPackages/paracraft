--[[
Title: ChunkProvider
Author(s): LiXizhi
Date: 2014/7/3
Desc: chunk provider interface. 
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkProvider.lua");
local ChunkProvider = commonlib.gettable("MyCompany.Aries.Game.World.ChunkProvider");
-----------------------------------------------
]]
local ChunkProvider = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.World.ChunkProvider"))

function ChunkProvider:ctor()
end

function ChunkProvider:Init()
end

-- Checks to see if a chunk exists at x, y
function ChunkProvider:ChunkExists(chunkX, chunkZ)
	return false;
end

--  Will return back a chunk, if it doesn't exist and its not a MP client it will generates all the blocks for the
--  specified chunk from the map seed and chunk seed
function ChunkProvider:ProvideChunk(chunkX, chunkZ)
	-- return chunk
	return nil;
end

-- loads or generates the chunk at the chunk location specified
-- load the chunk specified
function ChunkProvider:LoadChunk(chunkX, chunkZ)
end

-- Populates chunk with decos, etc etc
function ChunkProvider:Populate(chuckProvider, chunkX, chunkZ)
end

-- Two modes of operation: if passed true, save all Chunks in one go.  If passed false, save up to two chunks.
-- Return true if all chunks have been saved.
function ChunkProvider:SaveChunks(bIsSync, progressCallback)
end

-- Unloads chunks that are marked to be unloaded. This is not guaranteed to unload every such chunk.
function ChunkProvider:UnloadQueuedChunks()
end

-- Returns true if supports saving.
function ChunkProvider:CanSave()
	return;
end

-- Converts the instance data to a readable string.
function ChunkProvider:MakeString()
end

-- Returns a list of creatures of the specified type that can spawn at the given location.
function ChunkProvider:GetPossibleCreatures(creatureType, x,y,z)
end

-- Returns the location of the closest structure of the specified type. If not found returns nil.
function ChunkProvider:FindClosestStructure(world, name, x,y,z)
end

function ChunkProvider:GetLoadedChunkCount()
	return 0;
end

function ChunkProvider:RecreateStructures(x,z)
end

function ChunkProvider:OnExit()
end

function ChunkProvider:CreateGenerator(gen_class_name)
	NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkGenerators.lua");
	local ChunkGenerators = commonlib.gettable("MyCompany.Aries.Game.World.ChunkGenerators");
	local gen_class = ChunkGenerators:GetGeneratorClass(gen_class_name);
	return gen_class:new():Init(self.worldObj, self.worldObj:GetSeed());
end

function ChunkProvider:SetGenerator(gen)
	self.chunkGenerator = gen;
end

-- get chunk generator
function ChunkProvider:GetGenerator()
	if(not self.chunkGenerator) then
		self:SetGenerator(self:CreateGenerator());
	end
	return self.chunkGenerator;
end

--virtual function: called to generate a new chunk.
function ChunkProvider:AutoGenerateChunk(chunk)
	chunk:GetTimeStamp();
end
