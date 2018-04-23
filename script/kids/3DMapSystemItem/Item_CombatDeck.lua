--[[
Title: combat decks
Author(s): WangTian
Date: 2010/8/17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_CombatDeck.lua");
------------------------------------------------------------
]]

local Item_CombatDeck = commonlib.gettable("Map3DSystem.Item.Item_CombatDeck")
local Item_CombatApparel = commonlib.gettable("Map3DSystem.Item.Item_CombatApparel");

local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");

local Combat = commonlib.gettable("MyCompany.Aries.Combat");
local LOG = LOG;

---------------------------------
-- functions
---------------------------------

function Item_CombatDeck:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

-- When item is clicked through pe:slot
function Item_CombatDeck:OnClick(mouse_button, callbackFunc)
	if(self.nid and self.nid ~= ProfileManager.GetNID()) then
		LOG.std(nil, "error", "Item_CombatDeck", "can't equip other user's items");
		return;
	end
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
				
				if(callbackFunc and type(callbackFunc) == "function") then
					callbackFunc(msg);
				end

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
			-- before equip check for school and level
			local canEquip = true;
			local canotEquipReason = "不符合使用条件，不能使用哦！";
			-- get pet combat level
			local bean = MyCompany.Aries.Pet.GetBean();
			local petLevel = 1;
			if(bean) then
				petLevel = bean.combatlel or 1;
			end
			local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid);
			if(gsItem) then
				-- stats type ids:
				-- 137 school_requirement(CG) 物品穿着必须系别 1金 2木 3水 4火 5土 6火 7冰 8风暴 9神秘 10生命 11死亡 12平衡 
				-- 138 combatlevel_requirement(CG) 物品穿着必须战斗等级 

				--168 combatdeck_required_level(CG) 战斗deck的使用等级  
				--169 combatdeck_card_school(CG) 战斗deck的属性(只有这个系别的可以使用, 不指定或者为0则视为都可以使用) 6火 7冰 8风暴 9神秘 10生命 11死亡 12平衡  

				local stats = gsItem.template.stats;

				local school = Combat.GetSchool();
				if(stats[169] == 6 and school ~= "fire") then
					canEquip = false;
					canotEquipReason = "你的系别不符，无法使用哦！";
				elseif(stats[169] == 7 and school ~= "ice") then
					canEquip = false;
					canotEquipReason = "你的系别不符，无法使用哦！";
				elseif(stats[169] == 8 and school ~= "storm") then
					canEquip = false;
					canotEquipReason = "你的系别不符，无法使用哦！";
				--elseif(stats[169] == 9 and school ~= "myth") then
					--canEquip = false;
					--canotEquipReason = "你的系别不符，无法使用哦！";
				elseif(stats[169] == 10 and school ~= "life") then
					canEquip = false;
					canotEquipReason = "你的系别不符，无法使用哦！";
				elseif(stats[169] == 11 and school ~= "death") then
					canEquip = false;
					canotEquipReason = "你的系别不符，无法使用哦！";
				--elseif(stats[169] == 12 and school ~= "balance") then
					--canEquip = false;
					--canotEquipReason = "你的系别不符，无法使用哦！";
				end
				if(stats[168] and stats[168] > petLevel) then
					canEquip = false;
					canotEquipReason = "你的等级不符，无法使用哦！";
				end
			else
				canEquip = false;
			end

			if(canEquip == false) then
				LOG.std(nil, "user", "Item_CombatDeck", "can't equip higher level or items that is not your own school");
				if(not bSkipMessageBox) then
					_guihelper.MessageBox([[<div style="margin-top:30px;margin-left:30px;width:300px;">]]..canotEquipReason..[[</div>]]);
				end
				return;
			end

			Map3DSystem.Item.ItemManager.EquipItem(self.guid, function(msg) 
				-- refresh the avatar, mount pet and follow pet
				Map3DSystem.Item.ItemManager.RefreshMyself();
				-- refresh all <pe:player>
				Map3DSystem.mcml_controls.GetClassByTagName("pe:player").RefreshContainingPageCtrls();
				
				-- call hook for OnEquipItem
				local hook_msg = { aries_type = "OnEquipItem", wndName = "main"};
				CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);
				
				if(callbackFunc and type(callbackFunc) == "function") then
					callbackFunc(msg);
				end

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

function Item_CombatDeck:Prepare(mouse_button)
end

function Item_CombatDeck:GetTooltip()
	-- return "page://script/apps/Aries/Desktop/DeckTooltip.html?gsid="..self.gsid;
	return Item_CombatApparel.GetTooltip(self);
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