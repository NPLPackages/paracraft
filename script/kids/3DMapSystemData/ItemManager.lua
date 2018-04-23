--[[
Title: Item manager
Author(s): LiXizhi
Date: 2009/2/3
Desc: Each item has an id in the GlobalStore. 
this is a singleton class. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemData/ItemManager.lua");
local item = Map3DSystem.Item.ItemManager:FindItem(1)

Map3DSystem.Item.ItemManager:ItemManager:AddItem(item);
------------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemData/ItemBase.lua");
NPL.load("(gl)script/kids/3DMapSystemData/Item_Unknown.lua");
NPL.load("(gl)script/kids/3DMapSystemData/Item_App.lua");
NPL.load("(gl)script/kids/3DMapSystemData/Item_AppCommand.lua");
NPL.load("(gl)script/kids/3DMapSystemData/Item_LocalFunc.lua");

local ItemManager = {
	-- which type of item to handle. 
	type=nil,
	-- mapping from id to item struct
	items = {},
};
commonlib.setfield("Map3DSystem.Item.ItemManager", ItemManager)


---------------------------------
-- functions
---------------------------------
-- find item. 
function ItemManager:FindItem(id)
	return self.items[id];
end

-- add a new item. 
-- @param item:
function ItemManager:AddItem(item)
	if(item and item.id) then
		self.items[item.id] = self.items[item.id] or item
		return item.id;
	end	
end

function ItemManager:CreateItem(id)
	-- TODO:
end
