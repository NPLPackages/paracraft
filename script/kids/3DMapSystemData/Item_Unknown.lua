--[[
Title: an unknown item
Author(s): LiXizhi
Date: 2009/2/3
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemData/Item_Unknown.lua");
local dummyItem = Map3DSystem.Item.Item_Unknown:new();
Map3DSystem.Item.ItemManager:AddItem(dummyItem);
------------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemData/ItemBase.lua");

local Item_Unknown = commonlib.inherit(Map3DSystem.Item.ItemBase, {type=nil});
commonlib.setfield("Map3DSystem.Item.Item_Unknown", Item_Unknown)

---------------------------------
-- functions
---------------------------------
