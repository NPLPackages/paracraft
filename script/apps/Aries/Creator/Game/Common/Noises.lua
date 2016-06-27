--[[
Title: Perlin Noises
Author(s): LiXizhi
Date: 2013/11/1
Desc: Improved Perlin noise based on the reference implementation by Ken Perlin.
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Noises.lua");
local PerlinNoise = commonlib.gettable("MyCompany.Aries.Game.Common.CustomGenerator.PerlinNoise");
local _Gen1 = PerlinNoise:new({seed = 1234});
-----------------------------------------------
]]
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/ide/math/bit.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/FastRandom.lua");
local FastRandom = commonlib.gettable("MyCompany.Aries.Game.Common.CustomGenerator.FastRandom");
local band = mathlib.bit.band;

local tostring = tostring;
local format = format;
local type = type;
local math_floor = math.floor;
local math_abs = math.abs;

local PerlinNoise = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.CustomGenerator.PerlinNoise"))

function PerlinNoise.fade(t)
    return t * t * t * (t * (t * 6 - 15) + 10);
end
local fade = PerlinNoise.fade;

function PerlinNoise.lerp(t, a, b)
    return a + t * (b - a);
end
local lerp = PerlinNoise.lerp;

-- this function takes 21% of all CPU when gen terrain. 
function PerlinNoise.grad(hash, x, y, z)
    local h = band(hash, 15);
    local u;
	if(h < 8) then
		u = x;
	else
		u = y;
	end
	local v;
	if(h < 4) then
		v = y
	else
		if(h == 12 or h == 1) then
			v = x;
		else
			v = z;
		end
	end
	if((h % 2) ~= 0) then
		u = -u;
	end
	if(band(h, 2) ~= 0) then
		v = -v;
	end
    return u + v;
end

local grad = PerlinNoise.grad;

function PerlinNoise:ctor()
	self._noisePermutations = {};
	table.resize(self._noisePermutations, 512, 0);
	self._noiseTable = {};
	table.resize(self._noiseTable, 256, 0);
	
	if(self.seed) then
		self:Init(self.seed);
	end
end

-- @param seed: a number
function PerlinNoise:Init(seed)
	self.seed = seed;
	
	local rand = FastRandom:new({_seed = seed});

	local _noisePermutations = {};
	local _noiseTable = {};
	local i;
    for i = 0, 255 do
        _noiseTable[i] = i;
	end

    for i = 0, 255 do
        local j = rand:random(0, 255);
        local swap = _noiseTable[i];
        _noiseTable[i] = _noiseTable[j];
        _noiseTable[j] = swap;
    end

    for i = 0, 255 do
        _noisePermutations[i + 256] = _noiseTable[i];
		_noisePermutations[i] = _noiseTable[i];
	end

	self._noisePermutations = _noisePermutations;
	self._noiseTable = _noiseTable;
end

-- this function takes 12.9% of all CPU when gen terrain. 
function PerlinNoise:noise(x, y, z)
	local X,Y,Z = band(math_floor(x), 255), band(math_floor(y), 255), band(math_floor(z), 255);

    x = x - math_floor(x);
    y = y - math_floor(y);
    z = z - math_floor(z);

    local u,v,w = fade(x), fade(y), fade(z);

	local _noisePermutations = self._noisePermutations;
	local _noiseTable = self._noiseTable;

    local A = _noisePermutations[X] + Y;
	local AA = _noisePermutations[A] + Z;
	local AB = _noisePermutations[(A + 1)] + Z;
	local B = _noisePermutations[(X + 1)] + Y;
	local BA = _noisePermutations[B] + Z;
	local BB = _noisePermutations[(B + 1)] + Z;

    return lerp(w, lerp(v, lerp(u, grad(_noisePermutations[AA], x, y, z),
            grad(_noisePermutations[BA], x - 1, y, z)),
            lerp(u, grad(_noisePermutations[AB], x, y - 1, z),
                    grad(_noisePermutations[BB], x - 1, y - 1, z))),
            lerp(v, lerp(u, grad(_noisePermutations[(AA + 1)], x, y, z - 1),
                    grad(_noisePermutations[(BA + 1)], x - 1, y, z - 1)),
                    lerp(u, grad(_noisePermutations[(AB + 1)], x, y - 1, z - 1),
                            grad(_noisePermutations[(BB + 1)], x - 1, y - 1, z - 1))));
end

function PerlinNoise:ridgedMultiFractalNoise(x, y, z, octaves, lacunarity, gain, offset)
    local frequency = f;
    local signal;

    -- Fetch the first noise octave.
    signal = ridge(noise(x, y, z), offset);
    local result = signal;
    local weight;

    for i = 1,  octaves do
        x = x * lacunarity;
        y = y * lacunarity;
        z = z * lacunarity;

        weight = gain * signal;

        if (weight > 1.0) then
            weight = 1.0;
        elseif (weight < 0.0) then
            weight = 0.0;
        end

        signal = ridge(noise(x, y, z), offset);

        signal = signal * weight;
        result = result + signal * math.pow(frequency, -0.96461);
        frequency = frequency * lacunarity;
    end
    return result;
end

function PerlinNoise:ridge(n, offset)
    n = math_abs(n);
    n = offset - n;
    n = n * n;
    return n;
end

function PerlinNoise:fBm(x, y, z, octaves, lacunarity, h)
    local result = 0.0;

	local i;
    for i = 0, octaves-1 do 
        result = result + self:noise(x, y, z) * math.pow(lacunarity, -h * i);
        x = x * lacunarity;
        y = y * lacunarity;
        z = z * lacunarity;
	end
    return result;
end