--[[
Title: combat apparel items for CCS customization
Author(s): WangTian
Date: 2010/8/17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_CombatApparel.lua");
local Item_CombatApparel = commonlib.gettable("Map3DSystem.Item.Item_CombatApparel");
Item_CombatApparel.CheckCanEquip(gsid)
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Items/item.addonlevel.lua");
local addonlevel = commonlib.gettable("MyCompany.Aries.Items.addonlevel");

local Item_CombatApparel = commonlib.gettable("Map3DSystem.Item.Item_CombatApparel");
local VIP = commonlib.gettable("MyCompany.Aries.VIP");
local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");
local ProfileManager = commonlib.gettable("System.App.profiles.ProfileManager");
local Combat = commonlib.gettable("MyCompany.Aries.Combat");
local Player = commonlib.gettable("MyCompany.Aries.Player");

local LOG = LOG;

---------------------------------
-- functions
---------------------------------

function Item_CombatApparel:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self);
	self.__index = self;

	o:PrepareSocketedGemsIfNot();

	return o
end

-- check whether we can equip a given item.
-- @param canEquip, canotEquipReason, isVIPItem
function Item_CombatApparel.CheckCanEquip(gsid)
	-- before equip check for school and level
	local isVIPItem = false;
	local canEquip = true;
	local canotEquipReason = "不符合使用条件，不能使用哦！";
	local canEquipVIP = false;
	-- get pet combat level
	local bean = MyCompany.Aries.Pet.GetBean();
	local petLevel = 1;
	if(bean) then
		petLevel = bean.combatlel or 1;
	end
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid);
	if(gsItem) then
		-- stats type ids:
		-- 137 school_requirement(CG) 物品穿着必须系别 1金 2木 3水 4火 5土 6火 7冰 8风暴 9神秘 10生命 11死亡 12平衡 
		-- 138 combatlevel_requirement(CG) 物品穿着必须战斗等级 
		local stats = gsItem.template.stats;

		local school = Combat.GetSchool();
		if(stats[137] == 6 and school ~= "fire") then
			canEquip = false;
			canotEquipReason = "你的系别不符，无法使用哦！";
		elseif(stats[137] == 7 and school ~= "ice") then
			canEquip = false;
			canotEquipReason = "你的系别不符，无法使用哦！";
		elseif(stats[137] == 8 and school ~= "storm") then
			canEquip = false;
			canotEquipReason = "你的系别不符，无法使用哦！";
		--elseif(stats[137] == 9 and school ~= "myth") then
			--canEquip = false;
			--canotEquipReason = "你的系别不符，无法使用哦！";
		elseif(stats[137] == 10 and school ~= "life") then
			canEquip = false;
			canotEquipReason = "你的系别不符，无法使用哦！";
		elseif(stats[137] == 11 and school ~= "death") then
			canEquip = false;
			canotEquipReason = "你的系别不符，无法使用哦！";
		end
		if(stats[138] and stats[138] > petLevel) then
			canEquip = false;
			canotEquipReason = "你的等级不符，无法使用哦！";
		end

		if(stats[180] == 1) then
			isVIPItem = true;
			if(VIP.IsVIPAndActivated()) then
				canEquipVIP = true;
			end
		end

		-- 63 limited_gender(CG) 限定男女购买和使用 (青年版时装第一次出现) 0:只有男性可以购买和使用 1:只有女性可以购买和使用
		if(System.options.version == "teen") then
			local gender = MyCompany.Aries.Player.GetGender();
			if(gender == "female") then
				if(stats[63] == 0) then
					canEquip = false;
					canotEquipReason = "这件装备只能男性穿着，无法使用哦！";
				end
			elseif(gender == "male") then
				if(stats[63] == 1) then
					canEquip = false;
					canotEquipReason = "这件装备只能女性穿着，无法使用哦！";
				end
			end
		end

		if(not Item_CombatApparel.IsRankingValid_from_gsid_nid(gsid)) then
			canEquip = false;
			canotEquipReason = "你的PvP积分不够，无法使用哦！";
		end
	else
		canEquip = false;
	end
	return canEquip, canotEquipReason, isVIPItem;
end

function Item_CombatApparel:CanUse()
	return true;
end

-- When item is clicked through pe:slot
function Item_CombatApparel:OnClick(mouse_button, bSkipMessageBox, bForceUsing, bShowStatsDiff, bSkipBindingTest)
	if(self.nid and self.nid ~= ProfileManager.GetNID()) then
		LOG.std(nil, "error", "Item_CombatApparel", "can't equip other user's items");
		return;
	end
	if(self.from_ui_click and ItemManager.GetEvents():DispatchEvent({type = "Item_CombatApparel_OnClick" , item = self, })) then
		return;
	end
	
	if(System.options.version == "teen") then
		if(not bSkipBindingTest) then
			if(mouse_button == "left") then
				-- item in bag and binding
				if(not(self.bag == 0 and self.position) and not self:GetBinding()) then
					-- binding warning
					local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid);
					if(gsItem) then
						-- 223 装备的绑定方式，1:使用后绑定；2:获得即绑定
						if(gsItem.template.stats[223] == 1) then
							_guihelper.MessageBox(string.format("%s使用后将成为绑定物品，不可交易，你确定使用？", gsItem.template.name), function(result) 
								if(_guihelper.DialogResult.Yes == result) then
									self:OnClick(mouse_button, bSkipMessageBox, bForceUsing, bShowStatsDiff, true);
								elseif(_guihelper.DialogResult.No == result) then
									-- doing nothing if the user cancel the add as friend
								end
							end, _guihelper.MessageBoxButtons.YesNo);
							return;
						end
					end
				end
			end
		end
	end

	if(mouse_button == "left") then
		-- mount or use the item
		if(self.bag == 0 and self.position and not bForceUsing) then
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
		elseif( not (self.bag == 0 and self.position) )then
			-- before equip check for school and level
			local isVIPItem = false;
			local canEquip = true;
			local canotEquipReason = "不符合使用条件，不能使用哦！";
			local canEquipVIP = false;
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
				local stats = gsItem.template.stats;

				local school = Combat.GetSchool();
				if(stats[137] == 6 and school ~= "fire") then
					canEquip = false;
					canotEquipReason = "你的系别不符，无法使用哦！";
				elseif(stats[137] == 7 and school ~= "ice") then
					canEquip = false;
					canotEquipReason = "你的系别不符，无法使用哦！";
				elseif(stats[137] == 8 and school ~= "storm") then
					canEquip = false;
					canotEquipReason = "你的系别不符，无法使用哦！";
				--elseif(stats[137] == 9 and school ~= "myth") then
					--canEquip = false;
					--canotEquipReason = "你的系别不符，无法使用哦！";
				elseif(stats[137] == 10 and school ~= "life") then
					canEquip = false;
					canotEquipReason = "你的系别不符，无法使用哦！";
				elseif(stats[137] == 11 and school ~= "death") then
					canEquip = false;
					canotEquipReason = "你的系别不符，无法使用哦！";
				--elseif(stats[137] == 12 and school ~= "balance") then
					--canEquip = false;
					--canotEquipReason = "你的系别不符，无法使用哦！";
				elseif(stats[521] == 1) then
					local svrdata = self:GetServerData();
					if(svrdata and svrdata.money) then
						if(svrdata.nid == System.User.nid)then
							canEquip = false;
							canotEquipReason = "你不能穿有自己签名的物品， 与你喜欢的人交换后才能穿戴！";
						end
					else
						canEquip = false;
						canotEquipReason = "这个物品需要签名后，与他人交换，才能使用！鼠标左键点击物品，选择签名";
					end
				end
				if(stats[138] and stats[138] > petLevel) then
					canEquip = false;
					canotEquipReason = "你的等级不符，无法使用哦！";
				end

				if(stats[180] == 1) then
					isVIPItem = true;
					if(VIP.IsVIPAndActivated()) then
						canEquipVIP = true;
					end
				end

				-- 63 limited_gender(CG) 限定男女购买和使用 (青年版时装第一次出现) 0:只有男性可以购买和使用 1:只有女性可以购买和使用
				if(System.options.version == "teen") then
					local gender = MyCompany.Aries.Player.GetGender();
					if(gender == "female") then
						if(stats[63] == 0) then
							canEquip = false;
							canotEquipReason = "这件装备只能男性穿着，无法使用哦！";
						end
					elseif(gender == "male") then
						if(stats[63] == 1) then
							canEquip = false;
							canotEquipReason = "这件装备只能女性穿着，无法使用哦！";
						end
					end
				end
				
				if(not self:IsRankingValid()) then
					canEquip = false;
					canotEquipReason = "你的PvP积分不够，无法使用哦！";
				end
			else
				canEquip = false;
			end
			
			if(isVIPItem == true and canEquipVIP == false) then
				LOG.std(nil, "user", "Item_CombatApparel", "can't equip VIP items when magic star out of energy");
				if(not bSkipMessageBox) then
					--_guihelper.MessageBox([[<div style="margin-top:20px;margin-left:10px;width:300px;">你的魔法星能量值为0，失去魔法了，不能再使用带有魔法的物品了。</div>]]);
					if(System.options.version == "kids") then
						-- kids version:
						local s,gsid;
						local hasEnergyStone = ItemManager.IfOwnGSItem(998);
						local hasEnergyStoneShard = ItemManager.IfOwnGSItem(977);
						local hasEnergyStoneShardOneDay = ItemManager.IfOwnGSItem(967);
						if(hasEnergyStone == true) then
							s = "能量石";
							gsid = 998;
						elseif(hasEnergyStoneShard == true) then
							s = "能量石碎片";
							gsid = 977;
						elseif(hasEnergyStoneShardOneDay == true) then
							s = "能量石碎片(1天)";
							gsid = 967;
						end
						if(s) then
							local lastInfo = ProfileManager.GetUserInfoInMemory();
							_guihelper.MessageBox("该装备只有魔法星用户才能使用，发现你的包裹里有"..s..",马上使用，成为魔法星用户，享受多项特权！",function(result)
								if(result == _guihelper.DialogResult.Yes) then
									ItemManager.UseEnergyStoneEx(gsid,function(msg)
										_guihelper.MessageBox("恭喜你成为魔法星用户，现在你可以使用魔法星专属装备了，快去体验吧！");
									end,function() end);									
								end
							end,_guihelper.MessageBoxButtons.YesNo);
						else
							NPL.load("(gl)script/apps/Aries/Desktop/GUIHelper/CustomMessageBox.lua");
							_guihelper.Custom_MessageBox("你的魔法星能量值为0，失去魔法了，不能再使用带有魔法的物品了。",function(result)
								if(result == _guihelper.DialogResult.Yes)then
									--NPL.load("(gl)script/apps/Aries/VIP/PurChaseEnergyStone.lua");
									--local PurchaseEnergyStone = commonlib.gettable("MyCompany.Aries.Inventory.PurChaseEnergyStone");
									--PurchaseEnergyStone.Show();
									local gsid=998;
									Map3DSystem.mcml_controls.pe_item.OnClickGSItem(gsid,true);	
								end
							end,_guihelper.MessageBoxButtons.YesNo,{yes = "Texture/Aries/Common/GotMagicStone_32bits.png; 0 0 153 49", no = "Texture/Aries/Common/Later_32bits.png; 0 0 153 49"});	
						end
					else
						-- teen version: 
						NPL.load("(gl)script/apps/Aries/Desktop/GUIHelper/CustomMessageBox.lua");
						_guihelper.Custom_MessageBox("你的魔法星能量值为0，失去魔法了，不能再使用带有魔法的物品了。",function(result)
							if(result == _guihelper.DialogResult.Yes)then
								--NPL.load("(gl)script/apps/Aries/VIP/PurChaseEnergyStone.lua");
								--local PurchaseEnergyStone = commonlib.gettable("MyCompany.Aries.Inventory.PurChaseEnergyStone");
								--PurchaseEnergyStone.Show();
								local gsid=998;
								Map3DSystem.mcml_controls.pe_item.OnClickGSItem(gsid,true);	
							end
						end,_guihelper.MessageBoxButtons.YesNo,{yes = "Texture/Aries/Common/GotMagicStone_32bits.png; 0 0 153 49", no = "Texture/Aries/Common/Later_32bits.png; 0 0 153 49"});
					end
				end
				return;
			end
			if(canEquip == false) then
				LOG.std(nil, "user", "Item_CombatApparel", "can't equip higher level or items that is not your own school");
				if(not bSkipMessageBox) then
					_guihelper.MessageBox([[<div style="text-align:center">]]..canotEquipReason..[[</div>]]);
				end
				return;
			end
			
			if(bShowStatsDiff) then
				
				NPL.load("(gl)script/ide/TooltipHelper.lua");
				local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
				local Combat = commonlib.gettable("MyCompany.Aries.Combat");
				local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid);
				if(gsItem) then
					-- get last and current follow pet stats
					local stats_current = {};
					local stats = {};
					local new_item_name;
					local item_current = ItemManager.GetItemByBagAndPosition(0, gsItem.template.inventorytype);
					if(item_current and item_current.guid > 0 and item_current.GetCombatStats) then
						stats_current = item_current:GetCombatStats();
					end
					if(self.guid > 0 and self.GetCombatStats) then
						stats = self:GetCombatStats();
						new_item_name = gsItem.template.name;
					end
					-- get stats difference
					local stats_diff = {};
					local stat_type, stat_value;
					for stat_type, stat_value in pairs(stats) do
						stats_diff[stat_type] = stat_value;
					end
					for stat_type, stat_value in pairs(stats_current) do
						stats_diff[stat_type] = (stats_diff[stat_type] or 0) - stat_value;
					end
					-- record tip count to replace last tip if quickly switching
					local tip_count = 0;
					-- clear previous tips
					local i;
					for i = 1, 15 do
						BroadcastHelper.Clear("stats_diff_tip_"..i);
					end
					-- broadcast words
					local broadcast_words = {};
					-- switch pet tip
					if(new_item_name) then
						tip_count = tip_count + 1;
						BroadcastHelper.PushLabel({id = "stats_diff_tip_"..tip_count, label = "装备: "..new_item_name, max_duration=10000, color = "0 255 0", scaling=1, bold=true, shadow=true,});
					end
					-- show each stat diff
					local stat_type, stat_value;
					for stat_type, stat_value in pairs(stats_diff) do
						local each_stat_map = Combat.GetStatMap(stat_type);
						if(each_stat_map) then
							local signed_stat_value;
							if(each_stat_map.scale) then
								stat_value = stat_value * each_stat_map.scale;
							end
							local color;
							if(stat_value and stat_value > 0) then
								signed_stat_value = "+"..stat_value;
								color = "0 255 0";
							elseif(stat_value and stat_value < 0) then
								signed_stat_value = tostring(stat_value);
								color = "255 0 0";
							end
							if(signed_stat_value and color) then
								if(each_stat_map.type == "str_format" and each_stat_map.str_format) then
									local str_format = string.gsub(each_stat_map.str_format, "%+", "");
									str_format = string.gsub(str_format, "%(.+%)", ""); -- remove tip segment like (2%)
									local each_line = string.format(str_format, signed_stat_value);
									each_line = string.gsub(each_line, "%-%+", "-");
									tip_count = tip_count + 1;
									BroadcastHelper.PushLabel({id = "stats_diff_tip_"..tip_count, label = each_line, max_duration=10000, color = color, scaling=1, bold=true, shadow=true,});
								elseif(each_stat_map.type == "va_format" and each_stat_map.str_format) then
									local str_format = string.gsub(each_stat_map.str_format, "%+", "");
									local each_line = string.format("%s%s", str_format, signed_stat_value);
									each_line = string.gsub(each_line, "%-%+", "-");
									tip_count = tip_count + 1;
									BroadcastHelper.PushLabel({id = "stats_diff_tip_"..tip_count, label = each_line, max_duration=10000, color = color, scaling=1, bold=true, shadow=true,});
								end
							end
						end
					end
				end
			end

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

function Item_CombatApparel:IsCombatApparel()
	return true;
end

function Item_CombatApparel:GetCombatStats()
	local stats = {};
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid);
	if(gsItem) then
		local stat_type, stat_value;
		for stat_type, stat_value in pairs(gsItem.template.stats) do
			stats[stat_type] = (stats[stat_type] or 0) + stat_value;
		end
	end

	local gems = self:GetSocketedGems();
	if(gems) then
		local _, gsid;
		for _, gsid in pairs(gems) do
			local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid);
			if(gsItem) then
				local stat_type, stat_value;
				for stat_type, stat_value in pairs(gsItem.template.stats) do
					stats[stat_type] = (stats[stat_type] or 0) + stat_value;
				end
			end
		end
	end

	-- 101 add_maximum_hp(CG)
	stats[101] = (stats[101] or 0) + (self:GetAddonHpAbsolute() or 0);
	-- 111 add_damage_overall_percent(CG)
	stats[111] = (stats[111] or 0) + (self:GetAddonAttackPercentage() or 0);
	-- 151 add_damage_overall_absolute(CG)
	stats[151] = (stats[151] or 0) + (self:GetAddonAttackAbsolute() or 0);

	return stats;
end

function Item_CombatApparel:IsRankingValid()
	return Item_CombatApparel.IsRankingValid_from_gsid_nid(self.gsid, self.nid);
end

function Item_CombatApparel.IsRankingValid_from_gsid_nid(gsid, nid)
	local stats = {};
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid);
	if(gsItem) then
		stats = gsItem.template.stats;
	end
	
	local require_1v1_ranking = stats[251];
	local require_2v2_ranking = stats[252];
	local require_any_ranking = stats[253];
	-- 251 1v1_ranking_requirement(CG) 物品穿着必须1v1积分 青年版第一次使用
	-- 252 2v2_ranking_requirement(CG) 物品穿着必须2v2积分 青年版第一次使用
	-- 253 any_ranking_requirement(CG) 物品穿着必须任意pvp积分 1v1 2v2 有一个达到即可 青年版第一次使用 
	if(require_1v1_ranking) then
		local ranking = Combat.GetMyPvPRanking("1v1");
		if(nid) then
			ranking = Combat.GetOtherUserPvPRanking(nid, "1v1");
		end
		if(not ranking or ranking < require_1v1_ranking) then
			return false;
		end
	end
	if(require_2v2_ranking) then
		local ranking = Combat.GetMyPvPRanking("2v2");
		if(nid) then
			ranking = Combat.GetOtherUserPvPRanking(nid, "2v2");
		end
		if(not ranking or ranking < require_2v2_ranking) then
			return false;
		end
	end
	if(require_any_ranking) then
		local ranking = Combat.GetMyPvPRanking("1v1");
		if(nid) then
			ranking = Combat.GetOtherUserPvPRanking(nid, "1v1");
		end
		if(ranking and ranking >= require_any_ranking) then
			return true;
		end
		local ranking = Combat.GetMyPvPRanking("2v2");
		if(nid) then
			ranking = Combat.GetOtherUserPvPRanking(nid, "2v2");
		end
		if(ranking and ranking >= require_any_ranking) then
			return true;
		end
		return false;
	end
	return true;
end

-- parse the server data into socketed gem gsid
function Item_CombatApparel:PrepareSocketedGemsIfNot()
	self:GetServerData();
end

-- whether the item has been used before. if there is server data we will assume that it is used. 
function Item_CombatApparel:IsUsed()
	if(type(self.serverdata) == "string" and #(self.serverdata) > 2) then
		return true;
	end
end

-- @param bForceCreate: if true, an empty table is returned instead of nil if no server data is there
-- return nil or table 
function Item_CombatApparel:GetServerData(bForceCreate)
 	if(type(self.serverdata)=="string" and self.serverdata ~= "" and self.prepared_serverdata ~= self.serverdata) then
		local parsed_serverdata = {};
		NPL.FromJson(self.serverdata, parsed_serverdata);
		self.parsed_serverdata = parsed_serverdata;
		self.prepared_serverdata = self.serverdata;
	end
	if(bForceCreate and not self.parsed_serverdata) then
		self.parsed_serverdata = {};
	end
	return self.parsed_serverdata;
end

-- parse the server data into socketed gem gsid
function Item_CombatApparel:GetSocketedGems()
	if(self.parsed_serverdata and self.parsed_serverdata.gem and self.parsed_serverdata.gem.ins) then
		return self.parsed_serverdata.gem.ins;
	end
end

-- get holecnt
function Item_CombatApparel:GetHoleCount()
	if(self.parsed_serverdata and self.parsed_serverdata.gem and self.parsed_serverdata.gem.holecnt) then
		return self.parsed_serverdata.gem.holecnt;
	end
	return 0;
end

-- get the current addon level of the item. 
-- it may return 0 if no addon level. 
function Item_CombatApparel:GetAddonLevel()
	local server_data = self:GetServerData()
	if(server_data and server_data.addlel) then
		return server_data.addlel;
	end
	return 0;
end

-- only do this locally in memory. 
function Item_CombatApparel:UpdateAddonLevel(level)
	local server_data = self:GetServerData(true)
	if(server_data) then
		server_data.addlel = level;
	end
end

-- if there is addon property for the item. 
function Item_CombatApparel:CanHaveAddonProperty()
	return addonlevel.can_have_addon_property(self.gsid);
end

-- get max level
function Item_CombatApparel:GetMaxAddonLevel()
	return addonlevel.get_max_addon_level(self.gsid);
end

-- get attack percentage
-- @return nil if it can not contain any attack percentage. 
-- it may return 0 if it can contain attack percentage but not yet leveled up. 
function Item_CombatApparel:GetAddonAttackPercentage()
	if(addonlevel.can_have_addon_property(self.gsid)) then
		return addonlevel.get_attack_percentage(self.gsid, self:GetAddonLevel());
	end
end

-- get attack absolute
-- @return nil if it can not contain any attack absolute value. 
-- it may return 0 if it can contain attack absolute but not yet leveled up. 
function Item_CombatApparel:GetAddonAttackAbsolute()
	if(addonlevel.can_have_addon_property(self.gsid)) then
		return addonlevel.get_attack_absolute(self.gsid, self:GetAddonLevel());
	end
end

-- get resist absolute
-- @return nil if it can not contain any resist absolute value. 
-- it may return 0 if it can contain resist absolute but not yet leveled up. 
function Item_CombatApparel:GetAddonResistAbsolute()
	if(addonlevel.can_have_addon_property(self.gsid)) then
		return addonlevel.get_resist_absolute(self.gsid, self:GetAddonLevel());
	end
end

-- get hp absolute
-- @return nil if it can not contain any hp absolute value. 
-- it may return 0 if it can contain hpabsolute but not yet leveled up. 
function Item_CombatApparel:GetAddonHpAbsolute()
	if(addonlevel.can_have_addon_property(self.gsid)) then
		return addonlevel.get_hp_absolute(self.gsid, self:GetAddonLevel());
	end
end

-- get criticalstrike percent
-- @return nil if it can not contain any hp absolute value. 
-- it may return 0 if it can contain hpabsolute but not yet leveled up. 
function Item_CombatApparel:GetCriticalStrikePercent()
	if(addonlevel.can_have_addon_property(self.gsid)) then
		return addonlevel.get_critical_strike_percent(self.gsid, self:GetAddonLevel());
	end
end
-- get resilience percent
-- @return nil if it can not contain any hp absolute value. 
-- it may return 0 if it can contain hpabsolute but not yet leveled up. 
function Item_CombatApparel:GetResiliencePercent()
	if(addonlevel.can_have_addon_property(self.gsid)) then
		return addonlevel.get_resilience_percentage(self.gsid, self:GetAddonLevel());
	end
end

local cached_equiped_unbinding_item_guids = {};

function Item_CombatApparel.OnItemEquiped(guid)
	cached_equiped_unbinding_item_guids[guid] = true;

end

function Item_CombatApparel:OnMount()
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid);
	if(gsItem) then
		if(gsItem.template.stats[525]) then
			-- we need to increase the density by stat 525;
			Player.RefreshDensity();
		end
	end
end

function Item_CombatApparel:OnUnMount()
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid);
	if(gsItem) then
		if(gsItem.template.stats[525]) then
			-- we need to decrease the density by stat 525;
			Player.RefreshDensity();
		end
	end
end


-- get binding
-- return 1 if bound
function Item_CombatApparel:GetBinding()
	if(self.parsed_serverdata and self.parsed_serverdata.bound) then
		return self.parsed_serverdata.bound;
	end
	-- read from cached equiped items
	if(cached_equiped_unbinding_item_guids[self.guid]) then
		local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid);
		if(gsItem) then
			-- 223 装备的绑定方式，1:使用后绑定；2:获得即绑定 
			if(gsItem.template.stats[223]) then
				-- return only on bindable items
				return 1;
			end
		end
	end
end

-- is item with durability config
function Item_CombatApparel:IsDurable()
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid);
	if(gsItem) then
		-- 222 装备耐久度
		if(gsItem.template.stats[222] and gsItem.template.stats[222] > 0) then
			return true;
		end
	end
	return false;
end

-- get durability
function Item_CombatApparel:GetDurability()
	if(self.parsed_serverdata and self.parsed_serverdata.dur) then
		return self.parsed_serverdata.dur;
	end
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid);
	if(gsItem) then
		-- 222 装备耐久度
		if(gsItem.template.stats[222]) then
			-- invalid dur means full durability
			return gsItem.template.stats[222];
		end
	end
	return 0;
end

function Item_CombatApparel:Prepare(mouse_button)
end

function Item_CombatApparel:GetTooltip()
	if(self.nid and self.nid ~= ProfileManager.GetNID()) then
		if(System.options.version == "teen")then
			return "page://script/apps/Aries/Desktop/GenericTooltip_InOne.html?gsid="..self.gsid.."&guid="..self.guid.."&nid="..self.nid;
		else
			return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..self.gsid.."&guid="..self.guid.."&nid="..self.nid;
		end
	else
		if(System.options.version == "teen")then
			return "page://script/apps/Aries/Desktop/GenericTooltip_InOne.html?gsid="..self.gsid.."&guid="..self.guid;
		else
			return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..self.gsid.."&guid="..self.guid;
		end
	end
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