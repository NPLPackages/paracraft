--[[
Title: Fast random
Author(s): LiXizhi
Date: 2013/11/1
Desc: Random number generator based on the Xorshift generator by George Marsaglia.
It runs very fast in LuaJit, and defaul to C++ internally, if jit is not available. 
C++ version is 100 times slower than LuaJit version due to Lua C API.
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/FastRandom.lua");
local FastRandom = commonlib.gettable("MyCompany.Aries.Game.Common.CustomGenerator.FastRandom");
local r = FastRandom:new({_seed = 1234})
echo(r:randomLong());
echo(r:randomDouble());
echo({r:random(0,1), r:random(0,3), r:random(0,3), r:random(0,3), r:random(0,3)});
echo({r:randomBoolean(), r:randomBoolean(),r:randomBoolean(),r:randomBoolean(), r:randomBoolean(),r:randomBoolean()});
-----------------------------------------------
]]
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/ide/math/bit.lua");
local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;
local bxor = mathlib.bit.bxor;
local random = math.random;

local tostring = tostring;
local format = format;
local type = type;
local FastRandom = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.CustomGenerator.FastRandom"))

local MAX_INT = 2147483648;

function FastRandom:ctor()
	self._seed = self._seed or self.seed or ParaGlobal.timeGetTime()
end

function FastRandom:Init(seed)
	self._seed = seed;
end

if(jit and jit.version) then
	-- luajit is 100 times faster than c++ luabinding.

	-- Pure NPL random: Returns a random value as long. (may be negative)
	-- consider using the C++ version FastRandom.randomLong unless luajit is used
	function FastRandom:randomLong()
		local _seed = self._seed;
		_seed = bxor(_seed, lshift(_seed, 21));
		_seed = bxor(_seed, rshift(_seed, 35));
		_seed = bxor(_seed, rshift(_seed, 4));
		self._seed = _seed;
		return _seed;
	end


	-- Pure NPL random: Returns a random value as double in [0,1] range
	-- consider using the C++ version FastRandom.randomDouble unless luajit is used
	function FastRandom:randomDouble()
		local _seed = self._seed;
		_seed = bxor(_seed, lshift(_seed, 21));
		_seed = bxor(_seed, rshift(_seed, 35));
		_seed = bxor(_seed, rshift(_seed, 4));
		self._seed = _seed;
		return (_seed % MAX_INT) / (MAX_INT-1);
	end

else
	-- Returns a random value as long. (may be negative)
	-- C++ implementation.
	FastRandom.randomLong = ParaMisc.RandomLong;

	-- Returns a random value as double in [0,1] range
	-- C++ implementation.
	FastRandom.randomDouble = ParaMisc.RandomDouble;
end


-- Returns a random value between [0,1](double) or [a,b](integer only)
function FastRandom:random(a, b)
	if(not a) then
		return self:randomDouble();
	else
		return a + (self:randomLong()%(b-a+1));
	end
end

-- Returns a random value as boolean.
function FastRandom:randomBoolean() 
    return self:randomLong() > 0;
end

-- Returns a random character string with a specified length.
-- @param length The length of the generated string
-- @return Random character string
function FastRandom:randomCharacterString(length)
    local s = {};
    for i = 1, length do
		s[#s+1] = 'a' + self:random(0,25);
    end
    return table.concat(s, '');
end

-- Calculates a standardized normal distributed value (using the polar method).
function FastRandom:standNormalDistrDouble() 

    local q = 1;
    local u1 = 0;
    local u2;

    while (q >= 1 or q == 0) do
        u1 = self:random();
        u2 = self:random();

        q = (u1^2) + (u2^2);
    end

    local p = math.sqrt((-2 * (math.log(q))) / q);
    return u1 * p;
end

-- static function 
function FastRandom.randomNoise(x, y, z, seed)
    local u = x * 702395077 + y * 915488749 + z * 1299721 + seed * 1402024253;
    u = bxor(lshift(u , 13), u);
    return (1.0 - band((u * (u * u * 15731 + 789221) + 1376312589),  0x7fffffff) / 1073741824.0);
end