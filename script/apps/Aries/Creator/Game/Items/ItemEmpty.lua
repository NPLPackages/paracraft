--[[
Title: ItemEmpty
Author(s): LiXizhi
Date: 2015/6/25
Desc: the item returned when there is nothing in the hand of the player. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemEmpty.lua");
local ItemEmpty = commonlib.gettable("MyCompany.Aries.Game.Items.ItemEmpty");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
local Player = commonlib.gettable("MyCompany.Aries.Player");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemEmpty = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemEmpty"));

block_types.RegisterItemClass("ItemEmpty", ItemEmpty);

local block_id_map;


function ItemEmpty:ctor()
end

