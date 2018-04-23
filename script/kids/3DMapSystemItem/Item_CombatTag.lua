--[[
Title: combat tag items 40001 ~ 49999
Author(s): WangTian
Date: 2010/3/28
Desc: Item_CombatTag type of item is a special item type for combat system only, it will not be directly visualized to the scene or ui
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_CombatTag.lua");
------------------------------------------------------------
]]

local Item_CombatTag = {};
commonlib.setfield("Map3DSystem.Item.Item_CombatTag", Item_CombatTag)

---------------------------------
-- functions
---------------------------------

function Item_CombatTag:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self);
	self.__index = self;

	if(o.gsid == 40001 or o.gsid == 40003 or (System.options.version == "teen" and self_gsid == 12046) ) then
		-- refresh the exp buff area after 500 msec
		UIAnimManager.PlayCustomAnimation(500, function(elapsedTime)
			if(elapsedTime == 500) then
				-- update the exp buff area
				NPL.load("(gl)script/apps/Aries/Desktop/EXPBuffArea.lua");
				local EXPBuffArea = commonlib.gettable("MyCompany.Aries.Desktop.EXPBuffArea");
				EXPBuffArea.UpdateBuff();
			end
		end);
	end
	return o
end

-- When item is clicked through pe:slot
function Item_CombatTag:OnClick(mouse_button)
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