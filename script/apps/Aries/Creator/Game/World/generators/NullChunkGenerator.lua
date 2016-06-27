--[[
Title: NullChunkGenerator
Author(s): LiXizhi
Date: 2013/8/27, refactored 2015.11.17
Desc: A flat world generator with multiple layers at custom level.
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/generators/NullChunkGenerator.lua");
local NullChunkGenerator = commonlib.gettable("MyCompany.Aries.Game.World.Generators.NullChunkGenerator");
ChunkGenerators:Register("null", NullChunkGenerator);
-----------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkGenerator.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names");

local NullChunkGenerator = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.World.ChunkGenerator"), commonlib.gettable("MyCompany.Aries.Game.World.Generators.NullChunkGenerator"))

function NullChunkGenerator:ctor()
end

-- @param world: WorldManager, if nil, it means a local generator. 
-- @param seed: a number
function NullChunkGenerator:Init(world, seed)
	NullChunkGenerator._super.Init(self, world, seed);
	return self;
end

function NullChunkGenerator:OnExit()
	NullChunkGenerator._super.OnExit(self);
end

function NullChunkGenerator:AddPendingChunk(region_x, region_y, cx, cz)
end

function NullChunkGenerator:GenerateChunk(chunk, x, z, external)
end

function NullChunkGenerator:TryProcessChunk(cx,cz, dist_from_player)
end

-- protected virtual funtion:
-- generate chunk for the entire chunk column at x, z
function NullChunkGenerator:GenerateChunkImp(chunk, x, z, external)
end


