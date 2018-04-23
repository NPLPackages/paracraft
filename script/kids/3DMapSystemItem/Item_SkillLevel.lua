--[[
Title: SkillLevel items
Author(s): WangTian
Date: 2010/1/23
Desc: quest related common
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_SkillLevel.lua");
------------------------------------------------------------
]]

local Item_SkillLevel = {};
commonlib.setfield("Map3DSystem.Item.Item_SkillLevel", Item_SkillLevel)

---------------------------------
-- functions
---------------------------------

function Item_SkillLevel:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

-- When item is clicked through pe:slot
function Item_SkillLevel:OnClick(mouse_button)
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