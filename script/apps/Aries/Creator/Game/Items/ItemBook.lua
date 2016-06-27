--[[
Title: ItemBook
Author(s): LiXizhi
Date: 2014/1/20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemBook.lua");
local ItemBook = commonlib.gettable("MyCompany.Aries.Game.Items.ItemBook");
local item_ = ItemBook:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
local Player = commonlib.gettable("MyCompany.Aries.Player");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemBook = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemBook"));

block_types.RegisterItemClass("ItemBook", ItemBook);


-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemBook:ctor()
end

-- not stackable
function ItemBook:GetMaxCount()
	return 64;
end

-- append file name
function ItemBook:GetTooltipFromItemStack(itemStack)
	local tooltip = self:GetTooltip();
	if(tooltip) then
		local data = itemStack:GetData();
		if(type(data) == "string") then
			data = data:match("^[^#]+");
			if(data) then
				tooltip = tooltip.."\n"..data;
			end
		end
	end
	return tooltip;
end


-- Called whenever this item is equipped and the right mouse button is pressed.
-- @return the new item stack to put in the position.
function ItemBook:OnItemRightClick(itemStack, entityPlayer)
	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditBookPage.lua");
	local EditBookPage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditBookPage");
	EditBookPage.ShowPage(itemStack);
    return itemStack, true;
end