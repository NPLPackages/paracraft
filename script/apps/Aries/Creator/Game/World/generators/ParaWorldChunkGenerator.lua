--[[
Title: ParaWorldChunkGenerator
Author(s): LiXizhi
Date: 2013/8/27, refactored 2015.11.17
Desc: A flat grid world, where the center is 256*256, the outer is 128*128 grid.
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/generators/ParaWorldChunkGenerator.lua");
local ParaWorldChunkGenerator = commonlib.gettable("MyCompany.Aries.Game.World.Generators.ParaWorldChunkGenerator");
ChunkGenerators:Register("paraworld", ParaWorldChunkGenerator);
-----------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkGenerator.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names");

local ParaWorldChunkGenerator = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.World.ChunkGenerator"), commonlib.gettable("MyCompany.Aries.Game.World.Generators.ParaWorldChunkGenerator"))

function ParaWorldChunkGenerator:ctor()
end

-- @param world: WorldManager, if nil, it means a local generator. 
-- @param seed: a number
function ParaWorldChunkGenerator:Init(world, seed)
	ParaWorldChunkGenerator._super.Init(self, world, seed);
	return self;
end

function ParaWorldChunkGenerator:OnExit()
	ParaWorldChunkGenerator._super.OnExit(self);
end

function ParaWorldChunkGenerator:OnLoadWorld()
	GameLogic.RunCommand("/speedscale 2");
	GameLogic.options:SetViewBobbing(false, true)
end

-- get params for generating flat terrain
-- one can modify its properties before running custom chunk generator. 
function ParaWorldChunkGenerator:GetFlatLayers()
	if(self.flat_layers == nil) then
		self.flat_layers = {
			{y = 9, block_id = names.Bedrock},
			--{block_id = names.underground_default},
		};
	end
	return self.flat_layers;
end

function ParaWorldChunkGenerator:SetFlatLayers(layers)
	self.flat_layers = layers;
end

-- generate flat terrain
function ParaWorldChunkGenerator:GenerateFlat(c, x, z)
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
	local road_block_id = 71;
	local road_pgc_block_id = 68;
	local ground_block_id = 62;
	local road_edge_id = 180;
	
	local worldCenterX, worldCenterZ  = 19200, 19200;
	local gridOffsetX = (x*16 - worldCenterX) / 128;
	local gridOffsetZ = (z*16 - worldCenterZ) / 128;
	local isPGCArea = false
	if(-1 <= gridOffsetX  and gridOffsetX < 1 and -1 <= gridOffsetZ  and gridOffsetZ < 1) then
		-- PGC region uses a different ground block
		ground_block_id = 59;
		isPGCArea = true
	end
	for bx = 0, 15 do
		local worldX = bx + (x * 16);
		for bz = 0, 15 do
			local worldZ = bz + (z * 16);
			local offsetX, offsetZ = (worldX%128), (worldZ%128)
			if(offsetX < 4 or offsetZ < 4 or offsetX>123 or offsetZ>123) then
				if(isPGCArea) then
					c:SetType(bx, by, bz, road_pgc_block_id, false);
				else
					c:SetType(bx, by, bz, road_block_id, false);

					if( ((offsetX == 3 or offsetX==124) and (offsetZ>=3 and offsetZ<=124)) or 
						((offsetZ == 3 or offsetZ==124) and (offsetX>=3 and offsetX<=124))) then
						c:SetType(bx, by+1, bz, road_edge_id, false);
					end
				end
			else
				c:SetType(bx, by, bz, ground_block_id, false);
			end
		end
	end
	if(isPGCArea) then
		-- road and road edge in PGC area
		for bx = 0, 15 do
			local worldX = bx + (x * 16);
			for bz = 0, 15 do
				local worldZ = bz + (z * 16);
				local offsetX, offsetZ = ((worldX-128)%256), ((worldZ-128)%256)
				if(offsetX < 4 or offsetZ < 4 or offsetX>251 or offsetZ>251) then
					c:SetType(bx, by, bz, road_block_id, false);
					if( ((offsetX == 3 or offsetX==252) and (offsetZ>=3 and offsetZ<=252)) or 
						((offsetZ == 3 or offsetZ==252) and (offsetX>=3 and offsetX<=252))) then
						c:SetType(bx, by+1, bz, road_edge_id, false);
					end
				end
			end
		end
		if(gridOffsetX  == 0 and gridOffsetZ == 0) then
			-- for center chunk, we will create paraworld initial code block. 
			local worldX = (x * 16);
			local worldZ = (z * 16);
			
			-- code block on ground?
			BlockEngine:SetBlock(worldX, by,worldZ, 219, 0, 3, {attr={}, {name="cmd",[[--tip('hello world')]]}})
			BlockEngine:SetBlock(worldX, by-1,worldZ, 157, 0, 3)
		end
	end
end


-- protected virtual funtion:
-- generate chunk for the entire chunk column at x, z
function ParaWorldChunkGenerator:GenerateChunkImp(chunk, x, z, external)
	self:GenerateFlat(chunk, x, z);
end

-- virtual function: this is run in worker thread. It should only use data in the provided chunk.
-- if this function returns false, we will use GenerateChunkImp() instead. 
function ParaWorldChunkGenerator:GenerateChunkAsyncImp(chunk, x, z)
	return false
end

function ParaWorldChunkGenerator:IsSupportAsyncMode()
	return false;
end

-- virtual function: get the class address for sending to worker thread. 
function ParaWorldChunkGenerator:GetClassAddress()
	return {
		filename="script/apps/Aries/Creator/Game/World/generators/ParaWorldChunkGenerator.lua", 
		classpath="MyCompany.Aries.Game.World.Generators.ParaWorldChunkGenerator"
	};
end