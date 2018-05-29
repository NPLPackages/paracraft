--[[
Title: NatureV1ChunkGenerator
Author(s): LiXizhi, some algoritm is from the open source mc server. 
Date: 2013/8/27
Desc: A natural world generator with seed. It generate terrains, rivers, trees, grass, for several biome types. 
This used to be the default random generator.

Chunk generation runs at 50FPS on one thread on my i7 2.8GHZ CPU. This is due to FFI and luajit2, without these optimization it only runs at 4FPS. 
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/generators/NatureV1ChunkGenerator.lua");
local NatureV1ChunkGenerator = commonlib.gettable("MyCompany.Aries.Game.World.Generators.NatureV1ChunkGenerator");
ChunkGenerators:Register("default", NatureV1ChunkGenerator);
-----------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Noises.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/FastRandom.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkGenerator.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local FastRandom = commonlib.gettable("MyCompany.Aries.Game.Common.CustomGenerator.FastRandom");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names");
local PerlinNoise = commonlib.gettable("MyCompany.Aries.Game.Common.CustomGenerator.PerlinNoise");
local tostring = tostring;
local format = format;
local type = type;
local math_floor = math.floor;

local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

local NatureV1ChunkGenerator = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.World.ChunkGenerator"), commonlib.gettable("MyCompany.Aries.Game.World.Generators.NatureV1ChunkGenerator"))

local BIOME_TYPE = {
    PLAINS = 1, DESERT = 2, MOUNTAINS = 3, SNOW = 12,
}
NatureV1ChunkGenerator.BIOME_TYPE = BIOME_TYPE;

-- whether it is flat generator
NatureV1ChunkGenerator.is_flat_generator = nil;
-- whether generate underground resources
NatureV1ChunkGenerator.gen_resource = nil;
-- whether generate caves
NatureV1ChunkGenerator.gen_caves = false;

function NatureV1ChunkGenerator:ctor()
	self.biomes = {}
end

-- @param world: WorldManager, if nil, it means a local generator. 
-- @param seed: a number
function NatureV1ChunkGenerator:Init(world, seed)
	NatureV1ChunkGenerator._super.Init(self, world, seed);
	return self;
end

function NatureV1ChunkGenerator:OnExit()
	NatureV1ChunkGenerator._super.OnExit(self);
end

function NatureV1ChunkGenerator:InitGen()
	if(self.GenInit) then
		return;
	end
	self.GenInit = true;
	local _Seed = self._Seed;
	LOG.std(nil, "debug", "NatureV1ChunkGenerator", "initialized with seed %d", _Seed);

	self._Gen1 = PerlinNoise:new({seed = _Seed});
    self._Gen2 = PerlinNoise:new({seed = _Seed + 1});
    self._Gen3 = PerlinNoise:new({seed = _Seed + 2});
    self._Gen4 = PerlinNoise:new({seed = _Seed + 3});
    self._Gen5 = PerlinNoise:new({seed = _Seed + 4});
    self._Gen6 = PerlinNoise:new({seed = _Seed + 5});
	self._FastRandom = FastRandom:new({_seed = _Seed});
end

function NatureV1ChunkGenerator:CalcTemperature(x, z)
    local result = 0.0;
    result = result + self._Gen4:fBm(x * 0.0008, 0, 0.0008 * z, 7, 2.1836171, 0.7631);
    result = 32.0 + (result) * 64.0;
    return result;
end

function NatureV1ChunkGenerator:CalcBiomeType(x, z)
	local type = self.biomes[x*100000+z];
	if(type)  then
		return type;
	else
		local temp = self:CalcTemperature(x, z);

		if (temp >= 60) then
			type = BIOME_TYPE.DESERT;
		elseif (temp >= 32) then
			type = BIOME_TYPE.MOUNTAINS;
		elseif (temp < 8)then
			type = BIOME_TYPE.SNOW;
		else
			type = BIOME_TYPE.PLAINS;
		end
		self.biomes[x*100000+z] = type;
		return type;
	end
end

function NatureV1ChunkGenerator:CalcBaseTerrain(x, z)
    local result = 0.0;
    result = result + self._Gen2:fBm(0.0009 * x, 0, 0.0009 * z, 3, 2.2341, 0.94321) + 0.4;
    return result;
end

local freq = { 1.232, 8.4281, 16.371, 32, 64 };
local freq_count = #freq;
local amp = { 1.0, 1.4, 1.6, 1.8, 2.0 };

function NatureV1ChunkGenerator:CalcMountainDensity(x, y, z)
    local result = 0.0;

    local x1, y1, z1;

    x1 = x * 0.0006;
    y1 = y * 0.0008;
    z1 = z * 0.0006;

    local  ampSum = 0.0;
	local i;
    for i = 1, freq_count do
        result = result + self._Gen5:noise(x1 * freq[i], y1 * freq[i], z1 * freq[i]) * amp[i];
        ampSum = ampSum + amp[i];
	end

    return result / ampSum;
end

function NatureV1ChunkGenerator:CalcDensity(x, y, z, type)
    local height = self:CalcBaseTerrain(x, z);
    local density = self:CalcMountainDensity(x, y, z);
    local divHeight = (y - 55) * 1.5;

    if (y > 100) then
        divHeight = divHeight * 2.0;
	end

    if (type == BIOME_TYPE.DESERT) then
        divHeight = divHeight * 2.5;
    elseif (type == BIOME_TYPE.PLAINS) then
        divHeight = divHeight * 1.6;
    elseif (type == BIOME_TYPE.MOUNTAINS) then
        divHeight = divHeight * 1.1;
    elseif (type == BIOME_TYPE.SNOW) then
        divHeight = divHeight * 1.2;
    end
    return (height + density) / divHeight;
end

local function lerp(t, q00, q01)
	--if(t and q00 and q01) then
		return q00 + t * (q01 - q00);
	--else
	--	echo(commonlib.debugstack(2, 5, 1))
	--	assert(false);
	--end
end

local function triLerp(x, y, z, q000, q001, q010, q011, q100, q101, q110, q111, x1, x2, y1, y2, z1, z2)
    local distanceX = x2 - x1;
    local distanceY = y2 - y1;
    local distanceZ = z2 - z1;

    local tX = (x - x1) / distanceX;

    local tY = (y - y1) / distanceY;

    local x00 = lerp(tX, q000, q100);
    local x10 = lerp(tX, q010, q110);
    local x01 = lerp(tX, q001, q101);
    local x11 = lerp(tX, q011, q111);
    local r0 = lerp(tY, x00, x01);
    local r1 = lerp(tY, x10, x11);
    return lerp((z - z1) / distanceZ, r0, r1);
end

function NatureV1ChunkGenerator:CalcLakeIntensity(x, z)
    local result = 0.0;
    result = result+ self._Gen3:fBm(x * 0.0085, 0, 0.0085 * z, 2, 1.98755, 0.98);
    return math.sqrt(math.abs(result));
end

function NatureV1ChunkGenerator:CalcCaveDensity(x, y, z)
    local result = 0.0;
    result = result+ self._Gen6:fBm(x * 0.04, y * 0.04, z * 0.04, 2, 2.0, 0.98);
    return result;
end

function NatureV1ChunkGenerator:GenerateInnerLayer(x, y, z, type, c)
    c:SetType(x, y, z, names.Stone, false);
end

-- when to use luajit FFI to accelerate generation algorithm. 
NatureV1ChunkGenerator.enable_ffi = true;

if(jit and jit.version and NatureV1ChunkGenerator.enable_ffi) then
	local ffi = require("ffi")

	-- this is the most time consuming function
	function NatureV1ChunkGenerator:CreateDensityMap(x, z)
		local density = ffi.new("double[17][129][17]");

		-- Build the density map with lower resolution, 4*4*16 instead of 16*16*128
		local bx, bz, by;
		for bx = 0, 16, 4 do
			local worldX = bx + (x * 16);
			for bz = 0, 16, 4 do
				local worldZ = bz + (z * 16);
				for by = 0, 128, 8 do
					local type = self:CalcBiomeType(worldX, worldZ);
					density[bx][by][bz] = self:CalcDensity(worldX, by, worldZ, type);
				end
			end
		end
		self:triLerpDensityMap(density);
		return density;
	end

	function NatureV1ChunkGenerator:triLerpDensityMap(densityMap)
		local x,y,z;
		for x = 0, 15 do
			local offsetX = math_floor(x/4)*4;
			for y = 0, 127 do
				local offsetY = math_floor(y/8)*8;
				for z = 0, 15 do
					if ( not ((x%4) == 0 and (y%8) == 0 and (z%4) == 0)) then
						local offsetZ = math_floor(z/4)*4;
						densityMap[x][y][z] = triLerp(x, y, z, densityMap[offsetX][offsetY][offsetZ],
														densityMap[offsetX][offsetY + 8][offsetZ],
														densityMap[offsetX][offsetY][offsetZ + 4],
														densityMap[offsetX][offsetY + 8][offsetZ + 4],
														densityMap[4 + offsetX][offsetY][offsetZ],
														densityMap[4 + offsetX][offsetY + 8][offsetZ],
														densityMap[4 + offsetX][offsetY][offsetZ + 4],
														densityMap[4 + offsetX][offsetY + 8][offsetZ + 4], offsetX,
														4 + offsetX, offsetY, 8 + offsetY, offsetZ, offsetZ + 4);
					end
				end
			end
		end
	end

	function NatureV1ChunkGenerator:GetDensity(densityMap, x,y,z)
		return densityMap[x][y][z];
	end
else
	-- density = {}; -- 17,129,17
	local function d_idx(x,y,z)
		return x*17+y*289+z;
	end

	function NatureV1ChunkGenerator:CreateDensityMap(x, z)
		local density = {};
		table.resize(density, 17*129*17, 0); -- initialize the table to hint fast array for luajit. 
		
		-- Build the density map with lower resolution, 4*4*16 instead of 16*16*128
		local bx, bz, by;
		for bx = 0, 16, 4 do
			local worldX = bx + (x * 16);
			for bz = 0, 16, 4 do
				local worldZ = bz + (z * 16);
				for by = 0, 128, 8 do
					local type = self:CalcBiomeType(worldX, worldZ);
					density[d_idx(bx,by,bz)] = self:CalcDensity(worldX, by, worldZ, type);
				end
			end
		end
		self:triLerpDensityMap(density);
		return density;
	end

	function NatureV1ChunkGenerator:triLerpDensityMap(densityMap)
		local x,y,z;
		for x = 0, 15 do
			local offsetX = math_floor(x/4)*4;
			for y = 0, 127 do
				local offsetY = math_floor(y/8)*8;
				for z = 0, 15 do
					if ( not ((x%4) == 0 and (y%8) == 0 and (z%4) == 0)) then
						local offsetZ = math_floor(z/4)*4;
						densityMap[d_idx(x,y,z)] = triLerp(x, y, z, densityMap[d_idx(offsetX, offsetY, offsetZ)],
														densityMap[d_idx(offsetX, offsetY + 8, offsetZ)],
														densityMap[d_idx(offsetX, offsetY, offsetZ + 4)],
														densityMap[d_idx(offsetX, offsetY + 8, offsetZ + 4)],
														densityMap[d_idx(4 + offsetX, offsetY, offsetZ)],
														densityMap[d_idx(4 + offsetX, offsetY + 8, offsetZ)],
														densityMap[d_idx(4 + offsetX, offsetY, offsetZ + 4)],
														densityMap[d_idx(4 + offsetX, offsetY + 8, offsetZ + 4)], offsetX,
														4 + offsetX, offsetY, 8 + offsetY, offsetZ, offsetZ + 4);
					end
				end
			end
		end
	end

	function NatureV1ChunkGenerator:GetDensity(densityMap, x,y,z)
		return densityMap[d_idx(x,y,z)];
	end
end

-- @param c: chunk
-- @param x, z: chunk pos
function NatureV1ChunkGenerator:GenerateTerrain(c, x, z)
	local densityMap = self:CreateDensityMap(x, z);

	for bx = 0, 15 do
        local worldX = bx + (x * 16);
        for bz = 0, 15 do
            local worldZ = bz + (z * 16);
            local firstBlockHeight = -1;

            local type = self:CalcBiomeType(worldX, worldZ);
            for by = 127, 0, -1 do
			--for by = 80, 55, -1 do
                if (by == 0) then --  First bedrock Layer
                    c:SetType(bx, by, bz, names.Bedrock, false);
                elseif (by > 0 and by < 5 and self._FastRandom:random() > 0.3) then  -- Randomly put blocks of the remaining 4 layers of bedrock
                    c:SetType(bx, by, bz, names.Bedrock, false);
                elseif (by <= 55) then
                    c:SetType(bx, by, bz, names.Stone, false);
                else
                    if (by > 55 and by < 64) then
                        c:SetType(bx, by, bz, names.Still_Water, false);
                        if (by == 63 and type == BIOME_TYPE.SNOW) then
                            c:SetBiomeColumn(bx, bz, BIOME_TYPE.SNOW);
                            c:SetType(bx, by, bz, names.Ice, false);
                        end
                    end

                    local dens = self:GetDensity(densityMap, bx, by, bz);

                    if (dens >= 0.009 and dens <= 0.02) then
                        -- Some block was set...
                        if (firstBlockHeight == -1) then
                            firstBlockHeight = by;
						end

                        self:GenerateOuterLayer(bx, by, bz, firstBlockHeight, type, c);
                    elseif (dens > 0.02) then
                        -- Some block was set...
                        if (firstBlockHeight == -1) then
                            firstBlockHeight = by;
						end

                        if (NatureV1ChunkGenerator.gen_caves) then
							if(self:CalcCaveDensity(worldX, by, worldZ) > -0.6) then
								self:GenerateInnerLayer(bx, by, bz, type, c);
							end
						else
							self:GenerateOuterLayer(bx, by, bz, firstBlockHeight, type, c);
						end
                    else
                        firstBlockHeight = -1;
					end
                end

				if(self.gen_resource) then
					if (c:GetType(bx, by, bz) == names.Stone) then
						self:GenerateResource(bx, by, bz, c);
					end
				end
            end
        end
    end
end

function NatureV1ChunkGenerator:GenerateRiver(c, x, y, z, heightPercentage, type)
    -- Rivers under water? Nope.
    if (y <= 63 or y>64) then
        return;
	end

    local lakeIntens = self:CalcLakeIntensity(x + c.Coords:GetChunkX()* 16, z + c.Coords:GetChunkZ() * 16);
    local currentIndex = (lshift(x,11) + lshift(z, 7) + y);

    if (lakeIntens < 0.2) then
        if (heightPercentage < 0.001) then
            c:SetType(x, y, z, names.Air, false);
        elseif (heightPercentage < 0.02) then
            if (type == BIOME_TYPE.SNOW) then
                -- To be sure that there's no snow above us
                c:SetType(x, y + 1, z, names.Air, false);
                c:SetType(x, y, z, names.Ice, false);
            else
                c:SetType(x, y, z, names.Still_Water, false);
			end
		end
    end
end

function NatureV1ChunkGenerator:CalcLakeIntensity(x, z)
    local result = 0.0;
    result = result + self._Gen3:fBm(x * 0.0085, 0, 0.0085 * z, 2, 1.98755, 0.98);
    return math.sqrt(math.abs(result));
end

function NatureV1ChunkGenerator:GenerateResource(x, y, z, c)
	if(y<1) then
		-- do nothing if bottom of the world
    elseif (self._FastRandom:random(1, 100 * y) == 0) then
        c:SetType(x, y, z, names.Diamond_Ore, false);
    elseif (self._FastRandom:random(1, 100 * y) == 0) then
        c:SetType(x, y, z, names.Lapis_Lazuli_Ore, false);
    elseif (self._FastRandom:random(1, 40 * y) == 0) then
        c:SetType(x, y, z, names.Gold_Ore, false);
    elseif (self._FastRandom:random(1, 10 * y) == 0) then
        c:SetType(x, y, z, names.Ore, false);
    elseif (self._FastRandom:random(1, 4 * y) == 0) then
        c:SetType(x, y, z, names.Iron_Ore, false);
    elseif (self._FastRandom:random(1, 2 * y) == 0) then
        c:SetType(x, y, z, names.Coal_Ore, false);
	end           
end

function NatureV1ChunkGenerator:GenerateOuterLayer(x, y, z, firstBlockHeight, type, c)
    local heightPercentage = (firstBlockHeight - y) / 128.0;

    if(type == BIOME_TYPE.PLAINS or type == BIOME_TYPE.MOUNTAINS) then
        -- Beach
        if (y >= 60 and y <= 66) then
            c:SetBiomeColumn(x, z, BIOME_TYPE.MOUNTAINS);
            c:SetType(x, y, z, names.Sand, false);
            return;
        end

        c:SetBiomeColumn(x, z, BIOME_TYPE.MOUNTAINS);
        if (heightPercentage == 0.0 and y > 66) then
            -- Grass on top
            c:SetType(x, y, z, names.Grass, false);
        elseif (heightPercentage > 0.2) then
            -- Stone
            c:SetType(x, y, z, names.Stone, false);
        else
            -- Dirt
            c:SetType(x, y, z, names.Dirt, false);
        end

        self:GenerateRiver(c, x, y, z, heightPercentage, type);
	elseif(type == BIOME_TYPE.SNOW) then

        c:SetBiomeColumn(x, z, BIOME_TYPE.SNOW);
        if (heightPercentage == 0.0 and y > 65) then
            -- Snow on top
            c:SetType(x, y, z, names.Snow, false);
            -- Grass under the snow
            c:SetType(x, y - 1, z, names.Grass, false);
        elseif (heightPercentage > 0.2) then
            -- Stone
            c:SetType(x, y, z, names.Stone, false);
        else
            -- Dirt
            c:SetType(x, y, z, names.Dirt, false);
		end
		self:GenerateRiver(c, x, y, z, heightPercentage, type);
        
	elseif(type == BIOME_TYPE.DESERT) then
        c:SetBiomeColumn(x, z, BIOME_TYPE.DESERT);
        
        if (y < 80) then
            c:SetType(x, y, z, names.Sand, false);
		end
	end
end

function NatureV1ChunkGenerator:CalcGrassDensity(x, z)
    local result = 0.0;
    result = result + self._Gen3:fBm(0.05 * x, 0, 0.05 * z, 4, 2.37152, 0.8571);
    return result;
end

function NatureV1ChunkGenerator:CalcForestDensity(x, z)
    local result = 0.0;
    result = result + self._Gen1:fBm(0.03 * x, 0, 0.03 * z, 7, 2.3614521, 0.85431);
    return result;
end

function NatureV1ChunkGenerator:GenerateFlora(c, x, z)
	local bx, by, bz;
    for bx = 0, 15 do
        local worldX = bx + x * 16;
        for bz = 0, 15 do 
            local worldZ = bz + z * 16;

			-- search downward from 127 to 64
			local by = self:FindFirstBlock(worldX, 127, worldZ, 5, 63, c);
			
            if(by and c:GetType(bx, by, bz) == names.Grass) then
				local worldY = by;
            
				local grassDens = self:CalcGrassDensity(worldX, worldZ);
				if (grassDens > 0.0) then
					-- Generate high grass.
					local rand = self._FastRandom:standNormalDistrDouble();
					if (rand > -0.2 and rand < 0.2) then
						c:SetType(bx, by + 1, bz, names.TallGrass, false);
						-- c:SetData(bx, by + 1, bz, 1, false);
					end

					-- Generate flowers.
					if (self._FastRandom:standNormalDistrDouble() < -2) then
						if (self._FastRandom:randomBoolean()) then
							c:SetType(bx, by + 1, bz, names.Rose, false);
						else
							c:SetType(bx, by + 1, bz, names.Yellow_Flower, false);
						end
					end
				end
				
				
                if (by < 110 and ((bx % 4) == 0) and ((bz % 4) == 0)) then 
                    local forestDens = self:CalcForestDensity(worldX, worldZ);

                    if (forestDens > 0.005) then 
                        local randX = bx + (self._FastRandom:random(0,11)) + 4;
                        local randZ = bz + (self._FastRandom:random(0,11)) + 4;

                        if (randX < 3) then
                            randX = 3;
                        elseif (randX > 12) then
                            randX = 12;
						end

                        if (randZ < 3) then
                            randZ = 3;
                        elseif (randZ > 15) then
                            randZ = 12;
						end

						local biome = self:CalcBiomeType(worldX, worldZ);
	
                        if (c:GetType(randX, by, randZ) == names.Grass) then
                            self:GenerateTree(c, randX, by, randZ);
						elseif (biome == BIOME_TYPE.DESERT and c:GetType(randX, by, randZ) == names.Sand) then
                            self:GenerateCactus(c, randX, by, randZ);
						end
                    end
                end
            end
        end
    end
end

function NatureV1ChunkGenerator:GenerateCactus(c, x, y, z)
    local height = self._FastRandom:random(1,3);

    if (not self:CanSeeTheSky(x, y + 1, z, c)) then
        return;
	end

	local by;
    for by = height, y + height -1 do
        c:SetType(x, y, z, names.Cactus, false);
	end
end

function NatureV1ChunkGenerator:GenerateTree(c, x, y, z)
    -- Trees should only be placed in direct sunlight
    if (not self:CanSeeTheSky(x, y + 1, z, c)) then
        return;
	end

    local r2 = self._FastRandom:standNormalDistrDouble();
    -- Standard tree
	local bx,by,bz;
    for by = y + 4,  y + 5 do
        for bx = x - 2,  x + 2 do
            for bz = z - 2, z + 2 do
                c:SetType(bx, by, bz, names.Leaves, false);
                c:SetData(bx, by, bz, 0, false);
            end
		end
	end

    for bx = x - 1, x + 1 do
        for bz = z - 1, z + 1 do
            c:SetType(bx, y + 6, bz, names.Leaves, false);
            c:SetData(bx, y + 6, bz, 0, false);
        end
	end

    for by = y + 1, y + 6 do
        c:SetType(x, by, z, names.Wood, false);
        c:SetData(x, by, z, 0, false);
    end
    -- TODO: other tree types
end

-- protected virtual funtion:
-- generate chunk for the entire chunk column at x, z
function NatureV1ChunkGenerator:GenerateChunkImp(chunk, x, z, external)
	self:InitGen();
	
	self:GenerateTerrain(chunk, x, z);
	self:GenerateFlora(chunk, x, z);
end

-- virtual function: get the class address for sending to worker thread. 
function NatureV1ChunkGenerator:GetClassAddress()
	return {
		filename="script/apps/Aries/Creator/Game/World/generators/NatureV1ChunkGenerator.lua", 
		classpath="MyCompany.Aries.Game.World.Generators.NatureV1ChunkGenerator"
	};
end

function NatureV1ChunkGenerator:IsSupportAsyncMode()
	return true;
end