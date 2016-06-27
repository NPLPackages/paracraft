--[[
Title: Base class for World
Author(s): LiXizhi
Date: 2013/8/27
Desc: for accessing blocks, chunks, etc.
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldBlockAccess.lua");
local UniversalCoords = commonlib.gettable("MyCompany.Aries.Game.Common.UniversalCoords");
local WorldBlockAccess = commonlib.gettable("MyCompany.Aries.Game.World.WorldBlockAccess");
local world = WorldBlockAccess:new({gridnode = nil, seed=1, cpp_chunk=nil});
world:GetChunk(UniversalCoords:new():FromWorld(20000, 0, 20000), true, true);
-----------------------------------------------
]]
NPL.load("(gl)script/ide/math/bit.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/BlockBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/UniversalCoords.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local UniversalCoords = commonlib.gettable("MyCompany.Aries.Game.Common.UniversalCoords");
local BlockBase = commonlib.gettable("MyCompany.Aries.Game.World.BlockBase")
local StructBlock = commonlib.gettable("MyCompany.Aries.Game.World.StructBlock")
local CustomChunkGenerator = commonlib.gettable("MyCompany.Aries.Game.World.CustomChunkGenerator");

local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

local tostring = tostring;
local format = format;
local type = type;
local WorldBlockAccess = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.World.WorldBlockAccess"))

-- whether to use c++ as the data layer
WorldBlockAccess.cpp_chunk = nil;

function WorldBlockAccess:ctor()
	block_types.init();

	self:InitSeed();
	
	self.time = 1;
	self.AgeOfWorld = 1;
	
	-- gridnode server
	-- self.gridnode = nil;
end

function WorldBlockAccess:InitSeed()
	if(type(self.seed) == "string") then
		self.strSeed = self.seed;
		local seed = 0;
		for i=1, #(self.seed) do
			local byte = string.byte(self.seed, i);
			seed = lshift(seed, 8) + seed + byte;
		end
		self.seed = seed;
	elseif(type(self.seed)=="number") then
		self.strSeed = tostring(self.seed);
	else
		self.seed = 0;
		self.strSeed = "";
	end
end

-- get seed, usually used for random world generation. 
function WorldBlockAccess:GetSeed()
	return self.seed;
end

function WorldBlockAccess:GetSeedString()
	return self.strSeed or tostring(self.seed);
end

function WorldBlockAccess:SetSeed(seed)
	self.seed = seed;
	self:InitSeed();
end

function WorldBlockAccess:Init(server_manager)
	self.server_manager = server_manager;
end

function WorldBlockAccess:GetChunk(chunkX, chunkZ, bCreateIfNotExist)
	return self:GetChunkProvider():GetChunk(chunkX, chunkZ, bCreateIfNotExist);
end

function WorldBlockAccess:GetChunkFromWorld(worldX, worldZ, bCreateIfNotExist)
    return self:GetChunk(rshift(worldX, 4), rshift(worldZ, 4), bCreateIfNotExist);
end

function WorldBlockAccess:GetBlockByPos(worldX, worldY, worldZ)
    local chunk = self:GetChunkFromWorld(worldX, worldZ);

    if (not chunk) then
        return StructBlock.Empty;
	end

    local blockId = chunk:GetBlockIdByPos(band(worldX,0xF), worldY, band(worldZ, 0xF));
    -- local blockData = chunk:GetData(band(worldX,0xF), worldY, band(worldZ, 0xF));

    return StructBlock.FromPos(worldX, worldY, worldZ, blockId, self);
end
                                                            
function WorldBlockAccess:GetBlockId(coords)
    local chunk = self:GetChunkFromWorld(coords.WorldX, coords.WorldZ);
    if (chunk) then
        return chunk:GetBlockId(coords);
	end
end

-- @param needsUpdate: default to true;
function WorldBlockAccess:SetBlock(coords, block_id, needsUpdate)
    local chunk = self:GetChunk(coords:GetChunkX(), coords:GetChunkZ());
    if(chunk) then
       chunk:SetTypeByCoords(coords, block_id, needsUpdate);
	end
end

-- @param needsUpdate: default to true;
function WorldBlockAccess:SetBlockFromWorld(worldX, worldY, worldZ, block_id, needsUpdate)
    local chunk = self:GetChunkFromWorld(worldX, worldZ);
    if(chunk) then
		chunk:SetType(band(worldX,0xF), worldY, band(worldZ, 0xF), block_id, needsUpdate);
	end
end