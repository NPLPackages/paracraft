--[[
Title: Powered Block
Author(s): LiXizhi
Date: 2013/12/8
Desc: constantly providing weak power to nearby blocks.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockPowered.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockPowered")
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockPowered"));

-- register
block_types.RegisterBlockClass("BlockPowered", block);

function block:ctor()
	self.ProvidePower = true;
end

function block:Init()
end

-- Can this block provide power. 
function block:canProvidePower()
    return true;
end

function block:isProvidingWeakPower(x, y, z, direction)
	return 15;
end