--[[
Title: ItemMinimap
Author(s): LiXizhi
Date: 2015/5/5
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemMinimap.lua");
local ItemMinimap = commonlib.gettable("MyCompany.Aries.Game.Items.ItemMinimap");
local item = ItemMinimap:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
local Player = commonlib.gettable("MyCompany.Aries.Player");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemMinimap = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemMinimap"));

block_types.RegisterItemClass("ItemMinimap", ItemMinimap);

local default_inhand_offset = {0.15, 0.3, 0}

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemMinimap:ctor()
end

-- item offset when hold in hand. 
-- @return nil or {x,y,z}
function ItemMinimap:GetItemModelInHandOffset()
	return self.inhandOffset or default_inhand_offset;
end

-- Called whenever this item is equipped and the right mouse button is pressed.
-- @return the new item stack to put in the position.
function ItemMinimap:OnItemRightClick(itemStack, entityPlayer)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/Minimap/MinimapWnd.lua");
	local MinimapWnd = commonlib.gettable("MyCompany.Aries.Game.Items.ItemMinimap.MinimapWnd");
	MinimapWnd:Show();

    return itemStack, true;
end