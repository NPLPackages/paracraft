--[[
Title: Home outdoor plant items for CCS customization
Author(s): WangTian
Date: 2009/6/10
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_HomeOutdoorHouse.lua");
------------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemUI/HomeLand/HomeLandGateway.lua");
local Item_HomeOutdoorHouse = {};
commonlib.setfield("Map3DSystem.Item.Item_HomeOutdoorHouse", Item_HomeOutdoorHouse)

---------------------------------
-- functions
---------------------------------

function Item_HomeOutdoorHouse:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end
function Item_HomeOutdoorHouse:OnClick(mouse_button)
	local ItemManager = Map3DSystem.Item.ItemManager;
	if(mouse_button == "left") then
		if(ItemManager.IsHomeLandEditing()) then
			local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid)
			if(gsItem) then
				Map3DSystem.App.HomeLand.HomeLandGateway.BuildNodeFromItem("OutdoorHouse",gsItem,self.guid);
			end
		else
			log("error: must use the homeland items in editing mode\n")
		end
	elseif(mouse_button == "right") then
		---- destroy the item
		--_guihelper.MessageBox("你确定要销毁 #"..tostring(self.guid).." 物品么？", function(result) 
			--if(_guihelper.DialogResult.Yes == result) then
				--Map3DSystem.Item.ItemManager.DestroyItem(self.guid, 1, function(msg)
					--if(msg) then
						--log("+++++++Destroy item return: #"..tostring(self.guid).." +++++++\n")
						--commonlib.echo(msg);
					--end
				--end);
			--elseif(_guihelper.DialogResult.No == result) then
				---- doing nothing if the user cancel the add as friend
			--end
		--end, _guihelper.MessageBoxButtons.YesNo);
	end
end
function Item_HomeOutdoorHouse:OnModify(itemdata)
	local ItemManager = Map3DSystem.Item.ItemManager;
	if(ItemManager.IsHomeLandEditing()) then
		ItemManager.ModifyHomeLandItem(self.guid, itemdata);
	else
		log("error: must modify the homeland items in editing mode\n")
	end
end

-- remove the item from homeland to user inventory
function Item_HomeOutdoorHouse:OnRemove()
	local ItemManager = Map3DSystem.Item.ItemManager;
	if(ItemManager.IsHomeLandEditing()) then
		ItemManager.RemoveHomeLandItem(self.guid);
	else
		log("error: must remove the homeland items in editing mode\n")
	end
end

function Item_HomeOutdoorHouse:Prepare(mouse_button)
end