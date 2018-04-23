--[[
Title: combat card qualification
Author(s): WangTian
Date: 2009/6/10
Desc: Item_CombatCardQualification type 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_CombatCardQualification.lua");
------------------------------------------------------------
]]

local Item_CombatCardQualification = {};
commonlib.setfield("Map3DSystem.Item.Item_CombatCardQualification", Item_CombatCardQualification)

---------------------------------
-- functions
---------------------------------

function Item_CombatCardQualification:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

-- When item is clicked through pe:slot
function Item_CombatCardQualification:OnClick(mouse_button)
	local ItemManager = Map3DSystem.Item.ItemManager;
	if(mouse_button == "left") then
		
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