--[[
Title: BlockLight
Author(s): LiXizhi
Date: 2016/9/21
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockLight.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockLight")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.blocks.BlockEntityBase"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockLight"));

-- register
block_types.RegisterBlockClass("BlockLight", block);

function block:ctor()
end

function block:Init()
end



