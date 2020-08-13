--[[
Title: ParaWorldMiniChunkGenerator
Author(s): LiXizhi
Date: 2020.8.12
Desc: A mini 128*128 world 
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/generators/ParaWorldMiniChunkGenerator.lua");
local ParaWorldMiniChunkGenerator = commonlib.gettable("MyCompany.Aries.Game.World.Generators.ParaWorldMiniChunkGenerator");
ChunkGenerators:Register("paraworldMini", ParaWorldMiniChunkGenerator);
-----------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkGenerator.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names");

local ParaWorldMiniChunkGenerator = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.World.ChunkGenerator"), commonlib.gettable("MyCompany.Aries.Game.World.Generators.ParaWorldMiniChunkGenerator"))

function ParaWorldMiniChunkGenerator:ctor()
end

-- @param world: WorldManager, if nil, it means a local generator. 
-- @param seed: a number
function ParaWorldMiniChunkGenerator:Init(world, seed)
	ParaWorldMiniChunkGenerator._super.Init(self, world, seed);
	return self;
end

function ParaWorldMiniChunkGenerator:OnExit()
	ParaWorldMiniChunkGenerator._super.OnExit(self);
end

-- get params for generating flat terrain
-- one can modify its properties before running custom chunk generator. 
function ParaWorldMiniChunkGenerator:GetFlatLayers()
	if(self.flat_layers == nil) then
		self.flat_layers = {
			{y = 9, block_id = names.Bedrock},
			--{block_id = names.underground_default},
		};
	end
	return self.flat_layers;
end

function ParaWorldMiniChunkGenerator:SetFlatLayers(layers)
	self.flat_layers = layers;
end

-- generate flat terrain
function ParaWorldMiniChunkGenerator:GenerateFlat(c, x, z)
	local road_block_id = 71;
	local ground_block_id = 62;
	local road_edge_id = 180;
	
	local worldCenterX, worldCenterZ  = 19200, 19200;
	local gridOffsetX = (x*16 - worldCenterX) / 64;
	local gridOffsetZ = (z*16 - worldCenterZ) / 64;
	if(not (-1 <= gridOffsetX  and gridOffsetX < 1 and -1 <= gridOffsetZ  and gridOffsetZ < 1)) then
		-- do not generate anything outside the center
		return
	end

	local layers = self:GetFlatLayers();
			
	local by = layers[1].y;
	for i = 1, #layers do
		by = by + 1;
		local block_id = layers[i].block_id;

		for bx = 0, 15 do
			for bz = 0, 15 do
				c:SetType(bx, by, bz, block_id, false);
			end
		end
	end
	-- Top layer with road
	by = by + 1;

	for bx = 0, 15 do
		local worldX = bx + (x * 16);
		for bz = 0, 15 do
			local worldZ = bz + (z * 16);
			local offsetX, offsetZ = ((worldX+64)%128), ((worldZ+64)%128)
			if(offsetX < 4 or offsetZ < 4 or offsetX>123 or offsetZ>123) then
				c:SetType(bx, by, bz, road_block_id, false);

				if( ((offsetX == 3 or offsetX==124) and (offsetZ>=3 and offsetZ<=124)) or 
					((offsetZ == 3 or offsetZ==124) and (offsetX>=3 and offsetX<=124))) then
					c:SetType(bx, by+1, bz, road_edge_id, false);
				end
			else
				c:SetType(bx, by, bz, ground_block_id, false);
			end
		end
	end
end


-- protected virtual funtion:
-- generate chunk for the entire chunk column at x, z
function ParaWorldMiniChunkGenerator:GenerateChunkImp(chunk, x, z, external)
	self:GenerateFlat(chunk, x, z);
end

-- virtual function: this is run in worker thread. It should only use data in the provided chunk.
-- if this function returns false, we will use GenerateChunkImp() instead. 
function ParaWorldMiniChunkGenerator:GenerateChunkAsyncImp(chunk, x, z)
	return false
end

function ParaWorldMiniChunkGenerator:IsSupportAsyncMode()
	return false;
end

-- virtual function: get the class address for sending to worker thread. 
function ParaWorldMiniChunkGenerator:GetClassAddress()
	return {
		filename="script/apps/Aries/Creator/Game/World/generators/ParaWorldMiniChunkGenerator.lua", 
		classpath="MyCompany.Aries.Game.World.Generators.ParaWorldMiniChunkGenerator"
	};
end