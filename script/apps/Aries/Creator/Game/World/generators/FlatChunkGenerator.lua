--[[
Title: FlatChunkGenerator
Author(s): LiXizhi
Date: 2013/8/27, refactored 2015.11.17
Desc: A flat world generator with multiple layers at custom level.
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/generators/FlatChunkGenerator.lua");
local FlatChunkGenerator = commonlib.gettable("MyCompany.Aries.Game.World.Generators.FlatChunkGenerator");
ChunkGenerators:Register("flat", FlatChunkGenerator);
-----------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkGenerator.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names");

local FlatChunkGenerator = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.World.ChunkGenerator"), commonlib.gettable("MyCompany.Aries.Game.World.Generators.FlatChunkGenerator"))

function FlatChunkGenerator:ctor()
end

-- @param world: WorldManager, if nil, it means a local generator. 
-- @param seed: a number
function FlatChunkGenerator:Init(world, seed)
	FlatChunkGenerator._super.Init(self, world, seed);
	return self;
end

function FlatChunkGenerator:OnExit()
	FlatChunkGenerator._super.OnExit(self);
end

-- get params for generating flat terrain
-- one can modify its properties before running custom chunk generator. 
function FlatChunkGenerator:GetFlatLayers()
	if(self.flat_layers == nil) then
		self.flat_layers = {
			{y = 0, block_id = names.Bedrock},
			{block_id = names.underground_default},
			{block_id = names.underground_default},
			{block_id = names.underground_shell},
		};
	end
	return self.flat_layers;
end

function FlatChunkGenerator:SetFlatLayers(layers)
	self.flat_layers = layers;
end

-- generate flat terrain
function FlatChunkGenerator:GenerateFlat(c, x, z)
	local layers = self:GetFlatLayers();
			
	local by = layers[1].y;
	for i = 1, #layers do
		by = by+1;
		local block_id = layers[i].block_id;

		for bx = 0, 15 do
			for bz = 0, 15 do
				c:SetType(bx, by, bz, block_id, false);
			end
		end
	end
end


-- protected virtual funtion:
-- generate chunk for the entire chunk column at x, z
function FlatChunkGenerator:GenerateChunkImp(chunk, x, z, external)
	self:GenerateFlat(chunk, x, z);
end


