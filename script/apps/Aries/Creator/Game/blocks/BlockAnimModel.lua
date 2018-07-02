--[[
Title: Block Anim Model
Author(s): LiXizhi
Date: 2018/7/2
Desc: it will automatically generate ParaX models that are most close to the connected color block. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockAnimModel.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockAnimModel")
-------------------------------------------------------
]]
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.blocks.BlockEntityBase"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockAnimModel"));

-- register
block_types.RegisterBlockClass("BlockAnimModel", block);

function block:ctor()
	self.ProvidePower = true;
end


function block:OnNeighborChanged(x, y, z, from_block_id)
	block._super.OnNeighborChanged(self, x, y, z, from_block_id);
end


function block:OnBlockAdded(x,y,z, block_data, serverdata)
	block._super.OnBlockAdded(self, x, y, z, block_data, serverdata);
end

