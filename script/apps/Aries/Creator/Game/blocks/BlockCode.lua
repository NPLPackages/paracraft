--[[
Title: Code Block
Author(s): LiXizhi
Date: 2018/5/19
Desc: Code block uses code to control actors in the nearby connected movie block.  
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockCode.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockCode")
-------------------------------------------------------
]]
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.blocks.BlockEntityBase"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockCode"));

-- register
block_types.RegisterBlockClass("BlockCode", block);

function block:ctor()
	self.ProvidePower = true;
end

-- Do not emit weak power to nearby movie blocks, otherwise it behaves same as normal cube block.
-- Returns 0 if the block is emitting indirect/weak electric power on the specified side. 
function block:isProvidingWeakPower(x,y,z, side)
	local blockId = BlockEngine:GetBlockId(BlockEngine:GetBlockIndexBySide(x,y,z,side));
	if(blockId == names.MovieClip) then
		return 0;
	end
	return BlockEngine:getBlockStrongPowerInput(x,y,z);	
end
