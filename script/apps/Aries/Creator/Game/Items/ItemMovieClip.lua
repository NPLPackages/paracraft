--[[
Title: ItemMovieClip
Author(s): LiXizhi
Date: 2014/1/20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemMovieClip.lua");
local ItemMovieClip = commonlib.gettable("MyCompany.Aries.Game.Items.ItemMovieClip");
local item_ = ItemMovieClip:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
local Player = commonlib.gettable("MyCompany.Aries.Player");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemMovieClip = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemMovieClip"));

block_types.RegisterItemClass("ItemMovieClip", ItemMovieClip);


-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemMovieClip:ctor()
end

-- not stackable
function ItemMovieClip:GetMaxCount()
	return 1;
end

-- Called whenever this item is equipped and the right mouse button is pressed.
-- @return the new item stack to put in the position.
function ItemMovieClip:OnItemRightClick(itemStack, entityPlayer)
	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditBookPage.lua");
	local EditBookPage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditBookPage");
	EditBookPage.ShowPage(itemStack);
    return itemStack, true;
end