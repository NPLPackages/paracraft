--[[
Title: EmptyChunkGenerator
Author(s): LiXizhi
Date: 2013/8/27, refactored 2015.11.17
Desc: A flat world generator with multiple layers at custom level.
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/generators/EmptyChunkGenerator.lua");
local EmptyChunkGenerator = commonlib.gettable("MyCompany.Aries.Game.World.Generators.EmptyChunkGenerator");
ChunkGenerators:Register("empty", EmptyChunkGenerator);
-----------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkGenerator.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names");

local EmptyChunkGenerator = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.World.ChunkGenerator"), commonlib.gettable("MyCompany.Aries.Game.World.Generators.EmptyChunkGenerator"))

function EmptyChunkGenerator:ctor()
	self.is_empty_generator = true;
end

-- @param world: WorldManager, if nil, it means a local generator. 
-- @param seed: a number
function EmptyChunkGenerator:Init(world, seed)
	EmptyChunkGenerator._super.Init(self, world, seed);
	return self;
end

function EmptyChunkGenerator:OnExit()
	EmptyChunkGenerator._super.OnExit(self);
end

-- protected virtual funtion:
-- generate chunk for the entire chunk column at x, z
function EmptyChunkGenerator:GenerateChunkImp(chunk, x, z, external)
	
end


