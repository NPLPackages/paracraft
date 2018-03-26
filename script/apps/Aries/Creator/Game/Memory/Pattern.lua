--[[
Title: Pattern
Author(s): LiXizhi
Date: 2017/12/24
Desc: Pattern is an encoded value representing a feature inside a certain group of time series at time 0.

Any set of time series can be mathematically decomposed into any given number of pattern values. 
If time series A contains all the pattern values of time series B, then it has a very 
good chance that the matching part of A is similar to B and we can go on with a more accurate (time consuming) 
match to verify it. 

Pattern is designed to be accummulative, which means that P1 + P2 = P2 + P1 = where pattern 1 and 2 occurs together. 
Pattern is used for quickly finding a similar small set of time series from a larger set of time series. 

For example, the vision context is a very large set of time series containing thousands of attention objects 
in unlimited possible configurations; a memory clip is a small set of time series containing only dozens of relavent 
actors. We decompose vision context at runtime into many patterns; and we also pre-decompose movie clip into a few patterns.
For each pattern in the vision context, we can use a simple binary search to locate all movie clips containing the pattern.
When all patterns of a movie clip are matched, we go on with a more time consuming object by object match to decide whether
the movie clip is a candidate for activation. The whole thing works like a typical neuron input and output, except that 
we use the Pattern class to mathematically roughly transform the parallel searches into binary searches, because 
the computer is only good at the latter. This will make the pattern matching a real-time algorithm even for a large set of movie clips. 

Each pattern also contains back-tracking information usually a 3d point value for locating the place from where the pattern is generated.

Please note, 
- there is a predefined orientation for any pattern, which is relative to the player entity's facing. So that it can 
differentiate left from right. 
- in patterns, we treat block as dozens of different edges. 
- when we add two patterns, they always occurs close to one another in 3d spaces. 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/Pattern.lua");
local Pattern = commonlib.gettable("MyCompany.Aries.Game.Memory.Pattern");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/FastRandom.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/PatternBlockEdge.lua");
local PatternBlockEdge = commonlib.gettable("MyCompany.Aries.Game.Memory.PatternBlockEdge");
local FastRandom = commonlib.gettable("MyCompany.Aries.Game.Common.CustomGenerator.FastRandom");

local Pattern = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Memory.Pattern"));
Pattern:Property("Name", "Pattern");

Pattern:Property({"value", 0});
-- reference points for backtracing the place where the pattern is generated. default to 0,0,0
Pattern:Property({"x", 0});
Pattern:Property({"y", 0});
Pattern:Property({"z", 0});


local rand_gen = FastRandom:new({_seed = 20160810})

-- for representing component inside a pattern 
local magic_numbers = {};

for key, index in pairs(PatternBlockEdge) do
	if(type(index) == "number") then
		magic_numbers[index] = rand_gen:randomLong();
	end
end

function Pattern:ctor()
end

-- Each pattern contains back-tracking information usually a 3d point value for locating the place 
-- from where the pattern is generated. default to 0,0,0
function Pattern:SetBacktracePos(x,y,z)
	self.x, self.y, self.z = x,y,z;
end

-- add another pattern to this pattern in-place
function Pattern:AddPattern(right)
	self.value = self.value + right.value;
	return self;
end

function Pattern:AddHorizontalPlain(count, block_id)
end

function Pattern:AddVerticalPlain()
end

function Pattern:AddEdge()
end
