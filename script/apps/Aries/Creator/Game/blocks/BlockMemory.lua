--[[
Title: Memory Block
Author(s): LiXizhi
Date: 2017/5/19
Desc: Memory block is a stateful block, which will trigger memories(time series) stored in connected 
movie blocks according to similarity between the current virtual world and intial state of time series in movie clips. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockMemory.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockMemory")
-------------------------------------------------------
]]
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.blocks.BlockEntityBase"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockMemory"));

-- register
block_types.RegisterBlockClass("BlockMemory", block);

function block:ctor()
	self.ProvidePower = true;
end

function block:updateTick(x,y,z)
	if(not GameLogic.isRemote) then
		local entity = self:GetBlockEntity(x,y,z)
		if(entity and entity.OnBlockTick) then
			entity:OnBlockTick();
		end
	end
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
