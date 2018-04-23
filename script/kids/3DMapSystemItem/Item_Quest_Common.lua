--[[
Title: unknown items
Author(s): WangTian
Date: 2009/6/10
Desc: quest related common
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_Quest_Common.lua");
------------------------------------------------------------
]]

local Item_Quest_Common = {};
commonlib.setfield("Map3DSystem.Item.Item_Quest_Common", Item_Quest_Common)

---------------------------------
-- functions
---------------------------------

function Item_Quest_Common:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

-- When item is clicked through pe:slot
function Item_Quest_Common:OnClick(mouse_button)
	local ItemManager = Map3DSystem.Item.ItemManager;
	if(mouse_button == "left") then
		local gsid = self.gsid;
		local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid)
		if(gsItem) then
			local inventorytype = gsItem.template.inventorytype;
			if(inventorytype == 0) then
				return;
			end
		end
		-- mount or use the item
		if(self.bag == 0 and self.position) then
			Map3DSystem.Item.ItemManager.UnEquipItem(self.position, function(msg) 
				-- refresh the avatar, mount pet and follow pet
				Map3DSystem.Item.ItemManager.RefreshMyself();
				-- refresh all <pe:player>
				Map3DSystem.mcml_controls.GetClassByTagName("pe:player").RefreshContainingPageCtrls();
			end);
		else
			Map3DSystem.Item.ItemManager.EquipItem(self.guid, function(msg) 
				-- refresh the avatar, mount pet and follow pet
				Map3DSystem.Item.ItemManager.RefreshMyself();
				-- refresh all <pe:player>
				Map3DSystem.mcml_controls.GetClassByTagName("pe:player").RefreshContainingPageCtrls();
			end);
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