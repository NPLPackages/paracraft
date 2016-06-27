--[[
Title: Torch
Author(s): LiXizhi
Date: 2015/9/24
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockTorch.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockTorch");
-------------------------------------------------------
]]
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockTorch"));
-- register
block_types.RegisterBlockClass("BlockTorch", block);

function block:ctor()
end


function block:RotateBlockData(blockData, angle, axis)
	return self:RotateBlockDataUsingModelFacing(blockData, angle, axis);
end