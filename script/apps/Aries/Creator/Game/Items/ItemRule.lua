--[[
Title: ItemRule
Author(s): LiXizhi
Date: 2014/2/13
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemRule.lua");
local ItemRule = commonlib.gettable("MyCompany.Aries.Game.Items.ItemRule");
local item_ = ItemRule:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
local Player = commonlib.gettable("MyCompany.Aries.Player");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemRule = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemRule"));

block_types.RegisterItemClass("ItemRule", ItemRule);


-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemRule:ctor()
end

-- not stackable
function ItemRule:GetMaxCount()
	return 1;
end

-- Called whenever this item is equipped and the right mouse button is pressed.
-- @return the new item stack to put in the position.
function ItemRule:OnItemRightClick(itemStack, entityPlayer)
	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditRule.lua");
	local EditRule = commonlib.gettable("MyCompany.Aries.Game.GUI.EditRule");
	EditRule.ShowPage(itemStack, entityPlayer);
end