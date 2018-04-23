--[[
Title: apparel items for CCS customization
Author(s): WangTian
Date: 2009/5/31
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_Apparel.lua");
------------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemItem/Item_CombatApparel.lua");
local Item_Apparel = commonlib.gettable("Map3DSystem.Item.Item_Apparel");
local Item_CombatApparel = commonlib.gettable("Map3DSystem.Item.Item_CombatApparel");

local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");

local ProfileManager = commonlib.gettable("System.App.profiles.ProfileManager");

---------------------------------
-- functions
---------------------------------

function Item_Apparel:new(o)
	o = o or {}   -- create object if user does not provide one

	local gsItem = ItemManager.GetGlobalStoreItemInMemory(o.gsid);
	if(gsItem) then
		if(string.find(string.lower(gsItem.category), "combat")) then
			o = Map3DSystem.Item.Item_CombatApparel:new(o);
			return o;
		end
	end

	setmetatable(o, self)
	self.__index = self
	return o
end

-- When item is clicked through pe:slot
function Item_Apparel:OnClick(mouse_button)
	if(self.nid and self.nid ~= ProfileManager.GetNID()) then
		LOG.std(nil, "error", "Item_Apparel", "can't equip other user's items");
		return;
	end
	--if( self.from_ui_click and ItemManager.GetEvents():DispatchEvent({type = "Item_Apparel_OnClick" , item = self, })) then
		--return;
	--end

	if(mouse_button == "left") then
		-- mount or use the item
		if(self.bag == 0 and self.position) then
			Map3DSystem.Item.ItemManager.UnEquipItem(self.position, function(msg) 
				-- refresh the avatar, mount pet and follow pet
				Map3DSystem.Item.ItemManager.RefreshMyself();
				-- refresh all <pe:player>
				Map3DSystem.mcml_controls.GetClassByTagName("pe:player").RefreshContainingPageCtrls();
				
				-- call hook for OnEquipItem
				local hook_msg = { aries_type = "OnUnEquipItem", wndName = "main"};
				CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);
				
				--local playerChar = ParaScene.GetPlayer():ToCharacter();
				--local item = Map3DSystem.Item.ItemManager.items[self.guid];
				--if(item) then
					--Map3DSystem.Item.ItemManager.GetGlobalStoreItem(item.gsid, "GetGSAfterMoveItem", function(msg)
						--if(msg and msg.globalstoreitems and msg.globalstoreitems[1]) then
							--local gsItem = msg.globalstoreitems[1];
							--local gsItemInvSlot = gsItem.template.inventorytype;
							--local playerChar = ParaScene.GetPlayer():ToCharacter();
							--if(gsItemInvSlot == 5) then
								--playerChar:SetCharacterSlot(5, 0);
							--elseif(gsItemInvSlot == 6) then
								--playerChar:SetCharacterSlot(6, 0);
							--elseif(gsItemInvSlot == 7) then
								--playerChar:SetCharacterSlot(3, 0);
							--elseif(gsItemInvSlot == 9) then
								--playerChar:SetCharacterSlot(9, 0);
							--end
						--end
						---- refresh all <pe:player>
						--Map3DSystem.mcml_controls.GetClassByTagName("pe:player").RefreshContainingPageCtrls();
					--end);
				--end
			end);
		else
			Map3DSystem.Item.ItemManager.EquipItem(self.guid, function(msg) 
				-- refresh the avatar, mount pet and follow pet
				Map3DSystem.Item.ItemManager.RefreshMyself();
				-- refresh all <pe:player>
				Map3DSystem.mcml_controls.GetClassByTagName("pe:player").RefreshContainingPageCtrls();
				
				-- call hook for OnEquipItem
				local hook_msg = { aries_type = "OnEquipItem", wndName = "main"};
				CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);
				
				--if(msg.issuccess == true) then
					---- mount the item into character slot
					--local playerChar = ParaScene.GetPlayer():ToCharacter();
					--local item = Map3DSystem.Item.ItemManager.items[self.guid];
					--if(item) then
						--if(item.gsid == 1001) then
							--playerChar:SetCharacterSlot(16, 1001);
						--elseif(item.gsid == 1002) then
							--playerChar:SetCharacterSlot(17, 1002);
						--elseif(item.gsid == 1003) then
							--playerChar:SetCharacterSlot(18, 1003);
						--elseif(item.gsid == 1004) then
							--playerChar:SetCharacterSlot(19, 1004);
						--elseif(item.gsid == 1005) then
							--playerChar:SetCharacterSlot(16, 1005);
						--elseif(item.gsid == 1006) then
							--playerChar:SetCharacterSlot(17, 1006);
						--elseif(item.gsid == 1007) then
							--playerChar:SetCharacterSlot(19, 1007);
						--end
					--end
				--end
				---- refresh all <pe:player>
				--Map3DSystem.mcml_controls.GetClassByTagName("pe:player").RefreshContainingPageCtrls();
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

function Item_Apparel:Prepare(mouse_button)
end

function Item_Apparel:GetTooltip()
	local ItemManager = Map3DSystem.Item.ItemManager;
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid)
	local tooltip = "";
	if(gsItem) then
		local inventorytype = gsItem.template.inventorytype;
		if(inventorytype >=1 and inventorytype <=15) then
			tooltip = Item_CombatApparel.GetTooltip(self);
		else
			tooltip = gsItem.template.name;
		end
	end
	return tooltip;
end



			--CS_HEAD =0,
			--CS_NECK = 1,
			--CS_SHOULDER = 2,
			--CS_BOOTS = 3,
			--CS_BELT = 4,
			--CS_SHIRT = 5,
			--CS_PANTS = 6,
			--CS_CHEST = 7,
			--CS_BRACERS = 8,
			--CS_GLOVES = 9,
			--CS_HAND_RIGHT = 10,
			--CS_HAND_LEFT = 11,
			--CS_CAPE = 12,
			--CS_TABARD = 13,
			--CS_FACE_ADDON = 14, // newly added by andy -- 2009.5.10, Item type: IT_MASK 26
			--CS_WINGS = 15, // newly added by andy -- 2009.5.11, Item type: IT_WINGS 27
			--CS_ARIES_CHAR_SHIRT = 16, // newly added by andy -- 2009.6.16, Item type: IT_WINGS 28
			--CS_ARIES_CHAR_PANT = 17,
			--CS_ARIES_CHAR_HAND = 18,
			--CS_ARIES_CHAR_FOOT = 19,
			--CS_ARIES_CHAR_GLASS = 20,
			--CS_ARIES_CHAR_WING = 21,
			--CS_ARIES_PET_HEAD = 22,
			--CS_ARIES_PET_BODY = 23,
			--CS_ARIES_PET_TAIL = 24,
			--CS_ARIES_PET_WING = 25,
			--CS_BACK = 26, -- newly added in 2009/12/14 for aries
			
			
			
			
	--enum ItemTypes {
		--IT_ALL = 0,
		--IT_HEAD = 1,
		--IT_NECK,
		--IT_SHOULDER,
		--IT_SHIRT,
		--IT_CHEST,
		--IT_BELT,
		--IT_PANTS,
		--IT_BOOTS,
		--IT_BRACERS,
		--IT_GLOVES,
		--IT_RINGS,
		--IT_OFFHAND,
		--IT_DAGGER,
		--IT_SHIELD,
		--IT_BOW,
		--IT_CAPE,
		--IT_2HANDED,
		--IT_QUIVER,
		--IT_TABARD,
		--IT_ROBE,
		--IT_1HANDED,
		--IT_CLAW,
		--IT_ACCESSORY,
		--IT_THROWN,
		--IT_GUN,
		--IT_MASK, // CS_FACE_ADDON
		--IT_WINGS, // CS_WINGS
--
		--IT_ARIES_CHAR_SHIRT,
		--IT_ARIES_CHAR_PANT,
		--IT_ARIES_CHAR_HAND,
		--IT_ARIES_CHAR_FOOT,
		--IT_ARIES_CHAR_GLASS,
		--IT_ARIES_CHAR_WING,
		--IT_ARIES_PET_HEAD,
		--IT_ARIES_PET_BODY,
		--IT_ARIES_PET_TAIL,
		--IT_ARIES_PET_WING,
--
		--NUM_ITEM_TYPES
	--};