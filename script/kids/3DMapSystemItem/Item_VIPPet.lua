--[[
Title: VIP pet
Author(s): WangTian
Date: 2010/10/19
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_VIPPet.lua");
------------------------------------------------------------
]]

local Item_VIPPet = {};
commonlib.setfield("Map3DSystem.Item.Item_VIPPet", Item_VIPPet);

local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");

local ProfileManager = commonlib.gettable("System.App.profiles.ProfileManager");

---------------------------------
-- functions
---------------------------------

function Item_VIPPet:new(o)
	o = o or {}   -- create object if user does not provide one

	setmetatable(o, self)
	self.__index = self
	return o
end

-- When item is clicked through pe:slot
function Item_VIPPet:OnClick(mouse_button)
	if(self.nid and self.nid ~= ProfileManager.GetNID()) then
		LOG.std(nil, "error", "Item_VIPPet", "can't equip other user's items");
		return;
	end
	if(mouse_button == "left") then
		-- mount or use the item
		if(self.bag == 0 and self.position) then
			Map3DSystem.Item.ItemManager.UnEquipItem(self.position, function(msg) 
				-- refresh the avatar, mount pet and follow pet
				Map3DSystem.Item.ItemManager.RefreshMyself();
				---- refresh all <pe:player>
				--Map3DSystem.mcml_controls.GetClassByTagName("pe:player").RefreshContainingPageCtrls();
				
				-- call hook for OnEquipItem
				local hook_msg = { aries_type = "OnUnEquipItem", wndName = "main"};
				CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);
				
			end);
		else
			Map3DSystem.Item.ItemManager.EquipItem(self.guid, function(msg) 
				-- refresh the avatar, mount pet and follow pet
				Map3DSystem.Item.ItemManager.RefreshMyself();
				---- refresh all <pe:player>
				--Map3DSystem.mcml_controls.GetClassByTagName("pe:player").RefreshContainingPageCtrls();
				
				-- call hook for OnEquipItem
				local hook_msg = { aries_type = "OnEquipItem", wndName = "main"};
				CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);
				
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

function Item_VIPPet:Prepare(mouse_button)
end