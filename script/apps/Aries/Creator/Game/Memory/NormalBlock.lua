--[[
Title: Normal Block
Author(s): LiXizhi
Date: 2023/7/12
Desc: we will normal a single block into a pattern with reference to nearby blocks.
The pattern is an array of normalized values in range [0,1], each value may present some feature of the block.
For example, the first value may indicate the block's opacity; the second value indicate the block id; 
the following values may indicate the block's surrounding blocks' opacity at different radius, etc.  
You can think of surrounding block oppacity as ray tracing in 6 or more directions with a maximum length(radius). 

We can compare two normal blocks by simply dot-product by their normalized values to get a value indicating how similar these two blocks are. 
In some cases, we can multiply an additional weight array to obtain a biased comparision value. 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/NormalBlock.lua");
local NormalBlock = commonlib.gettable("MyCompany.Aries.Game.Memory.NormalBlock");
-------------------------------------------------------
]]
local NormalBlock = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Memory.NormalBlock"));
NormalBlock:Property("Name", "NormalBlock");

function NormalBlock:ctor()
	self[1] = 0;
	self[2] = 0;
end

-- @param bx, by, bz: local block position
-- @param worldBlocks: all world blocks, if nil, the current BlockEngine world is used. 
function NormalBlock:Init(bx, by, bz, worldBlocks)
	return self;
end

-- @param b: dot product with another normal block.
function NormalBlock.__mul(a,b)
	local nSizeB = #b;
	if(b.Name == "NormalBlock") then
		return a:DotProduct(b);
	end
end

function NormalBlock:DotProduct(b)
	local v = 0;
	for i = 1, #a do
		v = v + self[i] * (b[i] or 0);
	end
	return v/(#a);
end
