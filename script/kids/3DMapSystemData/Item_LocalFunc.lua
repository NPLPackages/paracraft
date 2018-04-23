--[[
Title: item that invoke local function
Author(s): LiXizhi
Date: 2009/2/3
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemData/Item_LocalFunc.lua");
local dummyItem = Map3DSystem.Item.Item_LocalFunc:new();
Map3DSystem.Item.ItemManager:AddItem(dummyItem);
------------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemData/ItemBase.lua");

local Item_LocalFunc = commonlib.inherit(Map3DSystem.Item.ItemBase, {type=Map3DSystem.Item.Types.LocalFunc});
commonlib.setfield("Map3DSystem.Item.Item_LocalFunc", Item_LocalFunc)

---------------------------------
-- functions
---------------------------------
