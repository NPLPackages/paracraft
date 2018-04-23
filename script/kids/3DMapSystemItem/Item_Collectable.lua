--[[
Title: collectable items
Author(s): WangTian
Date: 2009/6/10
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_Collectable.lua");
------------------------------------------------------------
]]

local Item_Collectable = commonlib.gettable("Map3DSystem.Item.Item_Collectable", Item_Collectable)

local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");

local Combat = commonlib.gettable("MyCompany.Aries.Combat");  -- for Combat.GetStatWord_OfTypeValue

local MsgHandler = commonlib.gettable("MyCompany.Aries.Combat.MsgHandler");

NPL.load("(gl)script/apps/Aries/DealDefend/DealDefend.lua");
local DealDefend = commonlib.gettable("MyCompany.Aries.DealDefend.DealDefend");

local pills_inventorytypes = {34,35,37,38,39,85,86,87,88,89,};

local magic_bags = {};

if(System.options.version == "kids") then
	magic_bags[17706] = true;
	magic_bags[17707] = true;
	magic_bags[17708] = true;
elseif(System.options.version == "teen") then
	magic_bags[17265] = true;
	magic_bags[17295] = true;
	magic_bags[17296] = true;
	magic_bags[17297] = true;
end

---------------------------------
-- functions
---------------------------------

function Item_Collectable:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

-- clicking on a character transform pill. Click to transform, click again to change back. 
-- @param gsid: class,subclass = 3,20; 
function Item_Collectable:OnClickCharTransform(gsid)
	local gsItem = Map3DSystem.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
	if(gsItem and gsItem.assetfile and gsItem.assetfile:match("^[cC]haracter")) then
		local Player = commonlib.gettable("MyCompany.Aries.Player");
		if(System.options.version=="teen" and Player.IsMounted() and not Player.GetMountAnimation(gsItem.assetfile)) then
			_guihelper.MessageBox(format("骑坐骑时不能使用[%s]", gsItem.template.name or ""));
			return;
		end
		local asset;
		if(Player.asset_gsid ~= gsid) then
			asset = gsItem.assetfile;
		end

		if(asset and asset~="" and asset:match("^[cC]haracter") and ParaIO.DoesAssetFileExist(asset, true)) then
			Player.asset_gsid = gsid;
			Player.base_model_str = asset;
		else
			Player.asset_gsid = nil;
			Player.base_model_str = nil;
		end

		local CCS = commonlib.gettable("Map3DSystem.UI.CCS");
		local Pet = commonlib.gettable("MyCompany.Aries.Pet");
		local equip_string = CCS.GetCCSInfoString();
		local char_player = Player.GetPlayer();
		if(char_player) then
			CCS.ApplyCCSInfoString(char_player, equip_string);
			Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
		end

		if(gsItem.template and gsItem.template.stats[525]) then
			Player.RefreshDensity();
		end
	end
end

-- return can_use, exid
function Item_Collectable:CanUseAll()
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid);

	-- 65 Item_Collectable_OpenWithExid(C) 配置为1的时候 默认为使用exid的打开逻辑
	-- 必须有exid配置在 47 ExtendedCost? _ID_Store(C) 
	local stats_47 = gsItem.template.stats[47];
	local stats_65 = gsItem.template.stats[65];
	if(stats_47 and stats_65) then
		if(gsItem.template.maxcount and gsItem.template.maxcount>1) then
			if(not gsItem.template.cangift and not gsItem.template.canexchange) then
				return true, stats_47;
			end
		end
	end
end

-- use all of them.
function Item_Collectable:UseAll()
	local can_use, exid = self:CanUseAll();
	if(can_use and exid) then
		local __,__,__,copies = ItemManager.IfOwnGSItem(self.gsid);
		copies = copies or 0;
		if(copies <= 0)then
			return
		end
		Map3DSystem.Item.ItemManager.ExtendedCost2(exid, copies, nil, nil, function(msg) 
			if(msg.issuccess == true) then
			end
		end,nil,"purchase");
	end
end

local function isPill(inventorytype)
	for i = 1,#pills_inventorytypes do
		if(pills_inventorytypes[i] == inventorytype) then
			return true;
		end
	end
	return false;
end


function Item_Collectable:CanUse()
	-- TODO exclude some not useful items. 
	return true;
end

-- When item is clicked through pe:slot
-- @param mouse_button: if nil, it is "left"
-- @param callbackFunc: nil or function(msg) end. only a few special items have callback function. 
function Item_Collectable:OnClick(mouse_button, callbackFunc)
	local hasGSItem = ItemManager.IfOwnGSItem;
	local self_gsid = self.gsid;
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(self_gsid);
	if(mouse_button == "left") then
		local class, subclass;
		if(gsItem) then
			class = gsItem.template.class;
			subclass = gsItem.template.subclass;
		end
		
		if(self_gsid == 17430 and System.options.version == "kids") then
			if(not hasGSItem(17412)) then
				-- 17412_ThassosGlaze
				NPL.load("(gl)script/ide/TooltipHelper.lua");
				local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
				BroadcastHelper.PushLabel({
						label = "需要一颗赤晶石才能打开该宝箱",
						color = "255 0 0",
						shadow = true,
						bold = true,
						font_size = 14,
						scaling = 1.2,
						});
				return;
			end
		end
		if(self_gsid == 17518 and System.options.version == "kids") then
			NPL.load("(gl)script/apps/Aries/Desktop/Functions/FateCard.lua");
			local FateCard = commonlib.gettable("MyCompany.Aries.Desktop.FateCard");
			FateCard.BeFateCardMaker(self_gsid);
			return;
		end

		if(gsItem and gsItem.click_url) then
			-- if there is click url. 
			ParaGlobal.ShellExecute("open", gsItem.click_url, "", "", 1);
		elseif(class == 3 and subclass == 20) then
			self:OnClickCharTransform(self_gsid);
			
		elseif(self_gsid == 17394 and System.options.version == "kids") then
			return;

		elseif(self_gsid == 17268 and System.options.version == "kids") then
			NPL.load("(gl)script/apps/Aries/HaqiShop/NPCShopPage.lua");
			local NPCShopPage = commonlib.gettable("MyCompany.Aries.NPCShopPage");
			NPCShopPage.ShowPage(30431,"menu1","superpat");
			
		elseif(self_gsid == 17404 and System.options.version == "kids") then
			-- unlock crazy tower
			local locking_arena_world_name = {
				["CrazyTower_36_to_40"] = true,
				["CrazyTower_41_to_45"] = true,
				["CrazyTower_46_to_50"] = true,
				["CrazyTower_51_to_55"] = true,
				["CrazyTower_56_to_60"] = true,
				["CrazyTower_61_to_65"] = true,
				["CrazyTower_66_to_70"] = true,
				["CrazyTower_71_to_75"] = true,
				["CrazyTower_76_to_80"] = true,
				["CrazyTower_81_to_85"] = true,
				["CrazyTower_86_to_90"] = true,
				["CrazyTower_91_to_95"] = true,
				["CrazyTower_96_to_100"] = true,
			};
			
			NPL.load("(gl)script/apps/Aries/Scene/WorldManager.lua");
			local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
			local world_info = WorldManager:GetCurrentWorld();
			if(world_info) then
				if(locking_arena_world_name[world_info.name]) then
					local arena_data_map = MsgHandler.Get_arena_data_map();
					local arena_id_max = 0;
					local arena_id, data;
					for arena_id, data in pairs(arena_data_map) do
						if(arena_id > arena_id_max) then
							arena_id_max = arena_id;
						end
					end
					if(arena_id_max and arena_id_max > 0) then
						MsgHandler.SendMessageToServer("UnlockArena:"..arena_id_max);
					end  
				end
			end
			
		elseif(self_gsid == 12001 or self_gsid == 12002 or (System.options.version == "teen" and self_gsid == 12046) ) then
			NPL.load("(gl)script/apps/Aries/Desktop/GUIHelper/CustomMessageBox.lua");
			NPL.load("(gl)script/apps/Aries/Quest/QuestClientLogics.lua");
			local QuestClientLogics = commonlib.gettable("MyCompany.Aries.Quest.QuestClientLogics");

			local gsid;
			if(self_gsid == 12001) then
				gsid = 40001;
			elseif(self_gsid == 12002) then
				gsid = 40003;
			elseif(self_gsid == 12046) then
				gsid = 40006;
			end
			
			-- 12002_ExpPowerPotion_Holiday
			if(self_gsid == 12002 and System.options.version == "teen") then
				NPL.load("(gl)script/apps/Aries/Desktop/AntiIndulgenceArea.lua");
				local AntiIndulgenceArea = commonlib.gettable("MyCompany.Aries.Desktop.AntiIndulgenceArea");
				local isHoliday = AntiIndulgenceArea.IsInHoliday();
				if(not isHoliday) then
					local gsItem = ItemManager.GetGlobalStoreItemInMemory(12002);
					if(gsItem) then
						_guihelper.MessageBox(string.format("今天不是节假日，不能使用%s。", gsItem.template.name));
					end
					return;
				end
			end

			local __,__,__,copies = hasGSItem(gsid);
			copies = copies or 0;
			if(copies >= 20)then
				_guihelper.Custom_MessageBox("你目前经验加成次数已满，不需要再次使用！",function(result)
					if(result == _guihelper.DialogResult.OK)then
					end
				end,_guihelper.MessageBoxButtons.OK,{ok = "Texture/Aries/Common/IKnow_32bits.png; 0 0 153 49"});
				return
			end
			if(copies > 0)then
				_guihelper.Custom_MessageBox("注意：你目前仍然有经验加成次数，再次使用将替代之前的加成次数！",function(result)
					if(result == _guihelper.DialogResult.Yes)then
						QuestClientLogics.DoUseItem_AddExpPercent(self_gsid);
					else
					end
				end,_guihelper.MessageBoxButtons.YesNo,{yes = "Texture/Aries/Common/continue_32bits.png; 0 0 153 49", no = "Texture/Aries/Common/Cancel_32bits.png; 0 0 153 49"});
			else
				QuestClientLogics.DoUseItem_AddExpPercent(self_gsid);
			end
			return
		end

		-- 65 Item_Collectable_OpenWithExid(C) 配置为1的时候 默认为使用exid的打开逻辑或者Extendedcost.Special的打开逻辑
		local stats_65 = gsItem.template.stats[65];
		--529 Extendedcost.Special启动模式，Count=配置中的ID，ID一般写GSID（儿童版首次使用） 
		local stats_529 = gsItem.template.stats[529];
		if(stats_529 and stats_65) then
			local conflicat_list = {
				[17441] = {2129,2132},
				[17413] = {2134,2131},
				[17578] = {2410},
				[17599] = {17598,10195},
				[17605] = {2414},
				[17606] = {2415},
			};
			if(conflicat_list[self_gsid]) then
				local item_list = conflicat_list[self_gsid];
				for i = 1,#item_list do
					local itme_gsid = item_list[i];
					local bHas = ItemManager.IfOwnGSItem(itme_gsid);
					if(bHas) then
						local s = format("你已经有<pe:item gsid='%d' style='width:24px;height:24px;' isclickable='false'/>了，不能使用<pe:item gsid='%d' style='width:24px;height:24px;' isclickable='false'/>，请先整理你的包裹吧。",itme_gsid,self_gsid);
						_guihelper.MessageBox(s);
						return;
					end
				end
			end

			if(self_gsid == 17413 or self_gsid == 17441) then
				local s = string.format("打开<pe:item gsid='%d' style='width:24px;height:24px;' isclickable='false'/>, 可以获得下列物品之一:<br/>", self_gsid);
				local item_str="";
				local item_list = conflicat_list[self_gsid];
				--for _, item in pairs(exTemplate.tos) do
				for i = 1,#item_list do
					local item_gsid = item_list[i];
					if(item_gsid < 50000 and item_gsid > 0) then
						item_str = item_str..format("<pe:item gsid='%d' style='width:24px;height:24px;' isclickable='false'/>, ", item_gsid);
					end
				end			
				s = s .. item_str .. "确定使用么？";
				_guihelper.MessageBox(s, function()
					System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="PowerExtendedCost", params={exid = tostring(stats_529)}});
				end);
				return;
			else
				System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="PowerExtendedCost", params={exid = tostring(stats_529)}});
				return;
			end

			
		end

		
		-- 必须有exid配置在 47 ExtendedCost? _ID_Store(C) 
		local stats_47 = gsItem.template.stats[47];
		
		if(stats_47 and stats_65) then
			local exid = stats_47;
			if(exid) then

				local function DoExtenderCost_()
					Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, function(msg)
						if(exid == 1548)then
							--增加任务进度 获取一个宠物
							NPL.load("(gl)script/apps/Aries/CombatPet/CombatPetPane.lua");
							local CombatPetPane = commonlib.gettable("MyCompany.Aries.CombatPet.CombatPetPane");
							local list,map = CombatPetPane.GetMyPetList_Memory();
							if(list and (#list > 0))then
								MyCompany.Aries.event:DispatchEvent({type = "custom_goal_client"},79013);
							end
						end
					end, function(msg) end,"pick");
				end
				

				local exTemplate = ItemManager.GetExtendedCostTemplateInMemory(exid);
				if(exTemplate) then
					local gsidListForKids = {[17413] = true,[17441] = true,[17443] = true,[17444] = true,[17446] = true,[17447] = true,[17474] = true,[17475] = true,};
					if(System.options.version == "kids" and gsidListForKids[gsItem.gsid]) then
						local _, item;
						for _, item in pairs(exTemplate.tos) do
							if(item.key and tonumber(item.key) > 0 and tonumber(item.key) < 50000) then
								local itemGsItem = ItemManager.GetGlobalStoreItemInMemory(item.key);
								if(itemGsItem) then
									local bHas, guid, bag, copies = ItemManager.IfOwnGSItem(item.key);
									local maxCount = tonumber(itemGsItem.template.maxcount);
									if(bHas and maxCount == 1) then
										local s = format("你已经有<pe:item gsid='%d' style='width:24px;height:24px;' isclickable='false'/>了，不能使用<pe:item gsid='%d' style='width:24px;height:24px;' isclickable='false'/>，请先整理你的包裹吧。",item.key,gsItem.gsid);
										_guihelper.MessageBox(s);
										return;
									elseif(bHas and (copies + item.value) > maxCount) then
										local s = format("你已经有太多的<pe:item gsid='%d' style='width:24px;height:24px;' isclickable='false'/>了，不能使用<pe:item gsid='%d' style='width:24px;height:24px;' isclickable='false'/>，请先整理你的包裹吧。",item.key,gsItem.gsid);
										_guihelper.MessageBox(s);
										return;
									end

									local maxDailyCount = tonumber(itemGsItem.maxdailycount);
									local maxWeeklyCount = tonumber(itemGsItem.maxweeklycount);
									if(maxDailyCount > 0 and maxWeeklyCount > 0) then
										local counts = ItemManager.GetGSObtainCntInTimeSpanInMemory(item.key);
										local countInDay = counts.inday;
										local countInWeek = counts.inweek;
										if((countInWeek + item.value) > maxWeeklyCount) then
											local s = format("你已经达到<pe:item gsid='%d' style='width:24px;height:24px;' isclickable='false'/>的每周获得上限了，不能使用<pe:item gsid='%d' style='width:24px;height:24px;' isclickable='false'/>，下周再使用吧。",item.key,gsItem.gsid);
											_guihelper.MessageBox(s);
											return;
										elseif((countInDay + item.value) > maxDailyCount) then
											local s = format("你已经达到<pe:item gsid='%d' style='width:24px;height:24px;' isclickable='false'/>的每日获得上限了，不能使用<pe:item gsid='%d' style='width:24px;height:24px;' isclickable='false'/>，明天再使用吧。",item.key,gsItem.gsid);
											_guihelper.MessageBox(s);
											return;
										end
									end
									
								end
							end
						end
						if(gsItem.gsid == 17413 or gsItem.gsid == 17441) then
							local s = string.format("打开<pe:item gsid='%d' style='width:24px;height:24px;' isclickable='false'/>, 可以获得下列物品之一:<br/>", gsItem.gsid);
							local item_str="";
							local _, item;
							for _, item in pairs(exTemplate.tos) do
								if(tonumber(item.key) < 50000 and tonumber(item.key) > 0) then
									item_str = item_str..format("<pe:item gsid='%d' style='width:24px;height:24px;' isclickable='false'/>, ", item.key);
								end
							end			
							s = s .. item_str .. "确定使用么？";
							_guihelper.MessageBox(s, function()
								Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, function(msg) end, function(msg) end,"pick");
							end);
							return;
						end
					end
				end
				DoExtenderCost_()
			end
			return;
		end
		
		-- 70 龙族图腾建造等级(C) 儿童版第一次使用 仅供客户端显示和提示用
		-- 71 增加龙族图腾信仰的经验值(CG) 儿童版第一次使用 
		local stats_70 = gsItem.template.stats[70];
		local stats_71 = gsItem.template.stats[71];
		if(stats_70 and stats_71) then
			local bHas, _, _, copies = ItemManager.IfOwnGSItem(if_else(System.options.version=="teen",50389,50359));
			local _, total_level, cur_level, cur_level_exp, cur_level_total_exp = MyCompany.Aries.Combat.GetStatsFromDragonTotemProfessionAndExp(if_else(System.options.version=="teen",50377,50351), if_else(System.options.version=="teen",50389,50359), copies or 0);
			local item_exp = stats_71;
			local item_level = stats_70;
			local diff = math.floor(math.abs(item_level*3 - (cur_level or 1)) / 3);
			local diff_percent = (1-0.3*diff);
			if(diff_percent > 0) then
				item_exp = math.floor(item_exp * diff_percent);
			else
				item_exp = 0;
			end

			NPL.load("(gl)script/apps/Aries/Desktop/CombatCharacterFrame/TotemPage.lua");
			local TotemPage = commonlib.gettable("MyCompany.Aries.Desktop.TotemPage");
			if(TotemPage.HasLearned()) then
				if(item_exp > 0) then
					if(cur_level >= MyCompany.Aries.Combat.GetMaxLevelFromDragonTotemProfession(if_else(System.options.version=="teen",50382,50352))  ) then -- and (cur_level_exp+item_exp)>cur_level_total_exp
						_guihelper.MessageBox(if_else(System.options.version=="teen","你的强化属性值已经满了","你的信仰值已经满了"))
					else
						if(System.options.version == "teen") then
							-- skip dialog
							System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="PowerExtendedCost", params={exid="add_dragon_belief", gsid=gsItem.gsid}});
						else
							_guihelper.MessageBox(format("你确定要使用1个<pe:item isclickable='false' gsid='%d' />增加%d点%s么？", gsItem.gsid, item_exp, if_else(System.options.version=="teen","强化属性值","信仰值")), function(res)
								if(res and res == _guihelper.DialogResult.Yes) then
									System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="PowerExtendedCost", params={exid="add_dragon_belief", gsid=gsItem.gsid}});
								end
							end, _guihelper.MessageBoxButtons.YesNo);
						end
					end
				else
					local s = format(if_else(System.options.version=="teen",
						"你当前强化属性是%d阶，该符印是%d阶，使用不能获得强化属性，请使用和你强化属性阶段对应的符印",
						"你当前信仰是%d阶信仰，该魂印是%d阶，使用不能获得信仰值，请使用和你信仰阶段对应的魂印"), 
						math.floor(cur_level/3)+1, item_level );
					_guihelper.MessageBox(s);
				end
			else
				_guihelper.MessageBox(
					if_else(System.options.version=="teen",
					"你还没有选择强化属性, 不能使用这个物, 是否现在学习？",
					"你还没有选择信仰, 不能使用这个物, 是否现在学习？"),
					function(res)
						if(res and res == _guihelper.DialogResult.Yes) then
							--local CombatCharacterFrame = commonlib.gettable("MyCompany.Aries.Desktop.CombatCharacterFrame");
							--if (CombatCharacterFrame) then
								--CombatCharacterFrame.ShowMainWnd(6);
							--end
							NPL.load("(gl)script/apps/Aries/Desktop/CombatCharacterFrame/TotemPage.lua");
							local TotemPage = commonlib.gettable("MyCompany.Aries.Desktop.TotemPage");
							TotemPage.ShowLearnPage("tolearn");
						end
					end, _guihelper.MessageBoxButtons.YesNo);
			end
		end

		if(magic_bags[self_gsid]) then
			-- 17265_MagicBag
			-- 17297_MagicBagLv1
			-- 17295_MagicBagLv2
			-- 17296_MagicBagLv3
			local gsItem = ItemManager.GetGlobalStoreItemInMemory(self_gsid);
			if(gsItem) then
				--NPL.load("(gl)script/apps/Aries/Inventory/Cards/CardsUnpackPage.lua");
				--local CardsUnpackPage = commonlib.gettable("MyCompany.Aries.Inventory.Cards.CardsUnpackPage");
				--CardsUnpackPage.ShowPage(self_gsid);
--
				--NPL.load("(gl)script/apps/Aries/Desktop/CombatCharacterFrame/CharacterBagPage.lua");
				--local CharacterBagPage = commonlib.gettable("MyCompany.Aries.Inventory.CharacterBagPage");
				--CharacterBagPage.ClosePage();
				ItemManager.DirectlyOpenCardPack(self_gsid);
				--_guihelper.MessageBox("你确定要撕开"..gsItem.template.name.."么?", function(res)
					--if(res==nil or res == _guihelper.DialogResult.Yes) then
						--ItemManager.DirectlyOpenCardPack(self_gsid);
					--end	
				--end, _guihelper.MessageBoxButtons.YesNo);
			end
			return;
		end


		if(self_gsid == 17351 and System.options.version == "teen") then
			-- 17351_giftpack
			local gsItem = ItemManager.GetGlobalStoreItemInMemory(self_gsid);
			if(gsItem) then
				ItemManager.DirectlyOpenGiftPack(self_gsid);
			end
			return;
		end
		
		if( (self_gsid == 17355 or self_gsid == 17356 or self_gsid == 17357 or self_gsid == 17358 or self_gsid == 17359 or self_gsid == 17360 or self_gsid == 17361) and System.options.version == "teen") then
			-- 17355_Case
			-- 17356_Case
			-- 17357_Case
			-- 17358_Case
			-- 17359_Case
			-- 17360_Case
			-- 17361_Case
			local gsItem = ItemManager.GetGlobalStoreItemInMemory(self_gsid);
			if(gsItem) then
				ItemManager.DirectlyOpenGiftPack(self_gsid);
			end
			return;
		end

		if(self_gsid == 17365 and System.options.version == "teen") then
			-- 17365_SuperSignInGiftBag
			local gsItem = ItemManager.GetGlobalStoreItemInMemory(self_gsid);
			if(gsItem) then
				ItemManager.DirectlyOpenGiftPack(self_gsid);
			end
			return;
		end

		if(self_gsid == 17149) then
			if(System.options.version == "kids") then
				-- 658 NewResidenceGiftPack_Fire 
				-- 659 NewResidenceGiftPack_Ice
				-- 661 NewResidenceGiftPack_Storm
				-- 662 NewResidenceGiftPack_Life
				-- 663 NewResidenceGiftPack_Death
				local exid_map = {
					["fire"] = 658,
					["ice"] = 659,
					["storm"] = 661,
					["life"] = 662,
					["death"] = 663,
				};
				local school = Combat.GetSchool();
				local exid = exid_map[school];
				if(exid) then
					Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, function(msg)end, function(msg) end);
				end
			else
				LOG.std(nil, "error", "items", "17149 should never be obtained by teen version. ")
			end
			return;
		end
		if(self_gsid >= 17160 and self_gsid <= 17162) then
			-- gsid
			-- 17160_GemCraftingGiftPack
			-- 17161_CombatEssentialGiftPack
			-- 17162_DragonGloryGiftPack
			-- exid
			-- 673 Open_17160_GemCraftingGiftPack 
			-- 674 Open_17161_CombatEssentialGiftPack 
			-- 675 Open_17162_DragonGloryGiftPack 
			local exid_map = {
				[17160] = 673,
				[17161] = 674,
				[17162] = 675,
			};
			local exid = exid_map[self_gsid];
			if(exid) then
				Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, function(msg)end, function(msg) end);
			end
			return;
		end
		if(self_gsid >= 17167 and self_gsid <= 17167) then
			-- gsid
			-- 17167_PopularityPill
			-- exid
			-- 707 Feed_17167_PopularityPill 
			local exid = 707;
			if(exid) then
				Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, function(msg)end, function(msg) end);
			end
			return;
		end
		if(self_gsid == 17236 and System.options.version == "kids") then
			-- gsid
			-- 17236_ShopNLSuperGoldBeanInsurance
			-- exid
			-- 1807 Get_17236_ShopNLSuperGoldBeanInsurance 
			local exid = 1807;
			if(exid) then
				Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, function(msg)end, function(msg) end, "purchase");
			end
			return;
		end
		if(self_gsid == 17263 and System.options.version == "kids") then
			-- gsid
			-- 17263_ShopNLBigBeanInsurance
			-- exid
			-- 1809 Get_17263_ShopNLBigBeanInsurance 
			local exid = 1809;
			if(exid) then
				Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, function(msg)end, function(msg) end, "purchase");
			end
			return;
		end
		
		if(self_gsid >= 17270 and self_gsid <= 17276 and System.options.version == "kids") then
			-- 17270_ShopNLMagicBean
			-- 17271_ShopNLBreadStick
			-- 17272_ShopNLMountPet
			-- 17273_ShopNLAutomaticCombatPills
			-- 17274_ShopNLPetExpPill
			-- 17275_OldUserShareForGift
			-- 17276_OldUserShareForGift_WeaponPackage

			-- 1470: Get_17270_ShopNLMagicBean
			-- 1471: Get_17271_ShopNLBreadStick
			-- 1472: Get_17272_ShopNLMountPet
			-- 1473: Get_17273_ShopAutomaticCombatPills
			-- 1474: Get_17274_ShopNLPetExpPill
			-- 1812 ExchangeShareForGift_03_OldUser 
			-- 1813 greedy_ExchangeShareForGift_WeaponPackage_OldUser 

			local exid;
			if(self_gsid == 17270) then
				exid = 1470;
			elseif(self_gsid == 17271) then
				exid = 1471;
			elseif(self_gsid == 17272) then
				exid = 1472;
			elseif(self_gsid == 17273) then
				exid = 1473;
			elseif(self_gsid == 17274) then
				exid = 1474;
			elseif(self_gsid == 17275) then
				exid = 1812;
			elseif(self_gsid == 17276) then
				exid = 1813;
			end
			if(exid) then
				Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, function(msg)end, function(msg) end, "purchase");
			end
			return;

		elseif(self_gsid >= 17279 and self_gsid <= 17282 and System.options.version == "kids") then
			-- 17279_ShopNLBigBeanInsurance
			-- 17280_ShopNLMagicBean
			-- 17281_ShopNLBreadStick
			-- 17282_BigGodBaenPackage

			-- 1490: Get_17279_ShopNLBigBeanInsurance
			-- 1491: Get_17280_ShopNLMagicBean
			-- 1492: Get_17281_ShopNLBreadStick
			-- 1493: Get_17282_GodBaenPackage

			local exid;
			if(self_gsid == 17279) then
				exid = 1490;
			elseif(self_gsid == 17280) then
				exid = 1491;
			elseif(self_gsid == 17281) then
				exid = 1492;
			elseif(self_gsid == 17282) then
				exid = 1493;
			end
			if(exid) then
				Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, function(msg)end, function(msg) end, "purchase");
			end
			return;

		elseif(self_gsid >= 17284 and self_gsid <= 17284 and System.options.version == "kids") then
			-- 17284_BubbleMachinePack
			
			-- 1495 Get_17284_BubbleMachinePack

			local exid;
			if(self_gsid == 17284) then
				exid = 1495;
			end
			if(exid) then
				Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, function(msg)end, function(msg) end, "purchase");
			end
			return;
		end
		
		if(self_gsid >= 17169 and self_gsid <= 17169) then
			-- gsid
			-- 17169_DragonGloryGiftPack_Advanced
			-- exid
			-- 728 Open_17169_DragonGloryGiftPack_Advanced
			local exid = 728;
			if(exid) then
				Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, function(msg)end, function(msg) end);
			end
			return;
		end
		if(self_gsid == 17150) then
			--632 RewardLevel3_GoldenGiftPack
			--633 RewardLevel5_GoldenGiftPack 
			--634 RewardLevel10_GoldenGiftPack
			--635 RewardLevel15_GoldenGiftPack
			--636 RewardLevel20_GoldenGiftPack
			--637 RewardLevel25_GoldenGiftPack
			--638 RewardLevel30_GoldenGiftPack
			local exid_map = {
				[10] = 632,
				[9] = 633,
				[8] = 634,
				[7] = 635,
				[6] = 636,
				[5] = 637,
				[4] = 638,
			};
			local level_map = {
				[10] = 3,
				[9] = 5,
				[8] = 10,
				[7] = 15,
				[6] = 20,
				[5] = 25,
				[4] = 30,
			};
			if(System.options.version == "teen") then
				exid_map = {
					[10] = 632,
					[9] = 633,
					[8] = 634,
					[7] = 635,
					[6] = 636,
					[5] = 637,
					[4] = 638,
					[3] = 30076,
					[2] = 30077,
				};
				level_map = {
					[10] = 2,
					[9] = 5,
					[8] = 10,
					[7] = 15,
					[6] = 20,
					[5] = 25,
					[4] = 30,
					[3] = 35,
					[2] = 40,
				};
			end
			local hasGSItem = Map3DSystem.Item.ItemManager.IfOwnGSItem;
			local bHas, guid, bag, copies = hasGSItem(50320);
			local level = 3;
			if(bHas and copies) then
				local exid = exid_map[copies];
				level = level_map[copies];
				if(exid and level) then
					local mylevel = Combat.GetMyCombatLevel();
					if(level <= mylevel) then
						Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, function(msg)end, function(msg) end);
						return;
					end
				end
			end
			_guihelper.MessageBox(string.format([[<div style="margin-top:20px;margin-left:10px;width:240px;">你的等级还不够哦，等你到%d级时记得在背包里开礼包哦！<div>]], level));
			return;
		elseif(self_gsid == 17212) then
			-- 17212_NewYearGifts
			-- exid
			-- 910 Get_NewYearGifts 
			local exid = 910;
			if(exid) then
				Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, function(msg)end, function(msg) end);
			end
			return;
		elseif(self_gsid >= 17216 and self_gsid <= 17220 and System.options.version == "kids") then
			-- 17216_MonthlyPackagePVP
			-- 17217_WeekendPackagePVE
			-- 17218_WeekendPackagePVP
			-- 17219_WeeklyPackagePVE
			-- 17220_WeeklyPackagePVP
			-- exid
			local exid = 1009;
			if(self_gsid == 17216) then
				exid = 1009;
			elseif(self_gsid == 17217) then
				exid = 1010;
			elseif(self_gsid == 17218) then
				exid = 1011;
			elseif(self_gsid == 17219) then
				exid = 1012;
			elseif(self_gsid == 17220) then
				exid = 1013;
			end
			if(exid) then
				Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, function(msg)end, function(msg) end);
			end
			return;
		elseif(self_gsid == 17221 and System.options.version == "kids") then
			-- 17221_GodBaenPackage
			local exid = 21116;
			Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, function(msg) 
				if(msg.issuccess == true) then
					log("info: 17221_GodBaenPackage collectable item: "..self_gsid.."\n")
					commonlib.echo(msg)
				end
			end);
			return;
		elseif(self_gsid == 17222 and System.options.version == "kids") then
			
			-- 10187_Pet_Bonfire_Boss
			if(gsItem and hasGSItem(10187)) then
				_guihelper.MessageBox(string.format([[<div style="margin-top:20px;margin-left:10px;width:240px;">你已经拥有火魔了，不需要再次使用%s！<div>]], gsItem.template.name));
				return;
			end

			-- 17222_Pet_Bonfire_BossStone
			local exid = 21117;
			Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, function(msg) 
				if(msg.issuccess == true) then
					log("info: 17222_Pet_Bonfire_BossStone collectable item: "..self_gsid.."\n")
					commonlib.echo(msg)
				end
			end);
			return;
		elseif(self_gsid == 17532 and System.options.version == "kids") then
			
			-- 10190_Pet_MagmaFireBon
			if(gsItem and hasGSItem(10190)) then
				_guihelper.MessageBox(string.format([[<div style="margin-top:20px;margin-left:10px;width:240px;">你已经拥有冰魔了，不需要再次使用%s！<div>]], gsItem.template.name));
				return;
			end

			-- 17532_Pet_MagmaFireBon_BossStone
			-- 21152: Get_10190_Pet_MagmaFireBon
			local exid = 21152;
			Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, function(msg) 
				if(msg.issuccess == true) then
					log("info: 17532_Pet_MagmaFireBon_BossStone collectable item: "..self_gsid.."\n")
					commonlib.echo(msg)
				end
			end);
			return;
		elseif(self_gsid == 17214) then
			-- 17214_FamilyPopularityPill
			local familyid = MyCompany.Aries.Friends.GetMyFamilyID();
			if(familyid) then
				local msg = {
					familyid = familyid,
				};
				paraworld.Family.UseContributeCard(msg, "Aries_UseFamilyPopularityPill", function(msg)
					if(msg and msg.issuccess) then
						-- success tip
						NPL.load("(gl)script/ide/TooltipHelper.lua");
						local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
						BroadcastHelper.PushLabel({
								label = "你为本家族增加了一点活跃度",
								color = "255 0 0",
								shadow = true,
								bold = true,
								font_size = 14,
								scaling = 1.2,
								});
						-- force update the collectable bag
						ItemManager.GetItemsInBag(12, "Aries_UseFamilyPopularityPill_ForceUpdateBag", function()
							-- update the UIs
							Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
						end, "access plus 0 day");
						NPL.load("(gl)script/apps/Aries/NPCs/TownSquare/30341_HaqiGroupManage.lua");
						MyCompany.Aries.Quest.NPCs.HaqiGroupManage.SetValue_IsDirty(true);
					elseif(msg and msg.errorcode)then
						if(msg.errorcode == 434) then
							_guihelper.MessageBox([[<div style="margin-top:30px;margin-left:40px;width:240px;">你不是这个家族的成员<div>]]);
						elseif(msg.errorcode == 497) then
							_guihelper.MessageBox([[<div style="margin-top:30px;margin-left:40px;width:240px;">家族不存在<div>]]);
						elseif(msg.errorcode == 427) then
							_guihelper.MessageBox([[<div style="margin-top:30px;margin-left:40px;width:240px;">你的家族人气帖已经消耗完了<div>]]);
							--你还没有加入家族
							-- 497: 家庭不存在 493:参数不正确 434:非家族成员 419:用户不存在 427:无家族人气帖 500:异常了
						end
					end
				end);
				return;
			else
				_guihelper.MessageBox([[<div style="margin-top:30px;margin-left:40px;width:240px;">你还没有加入任何家族<div>]]);
				return;
			end
		end
		if(System.options.version == "teen") then
			if(gsItem) then
				if(gsItem.category == "CombatPillByBattle" or gsItem.category == "CombatFoodByBattle") then
					local exid = gsItem.template.stats[51];
					if(exid) then
						local exTemplate = ItemManager.GetExtendedCostTemplateInMemory(exid)
						if(exTemplate) then
							local i, to;
							for i, to in ipairs(exTemplate.tos) do
								-- to.key is the marker id
								local gsItem_marker = ItemManager.GetGlobalStoreItemInMemory(to.key);
								if(gsItem_marker) then
									local position = gsItem_marker.template.inventorytype;
									local item_exist = ItemManager.GetItemByBagAndPosition(0, position);
									if(item_exist and item_exist.guid > 0) then
										-- same effect already exist
										_guihelper.Custom_MessageBox("目前你已经有一个战斗药剂效果，是否覆盖？",function(result)
											if(result == _guihelper.DialogResult.Yes) then
												ItemManager.DestroyItem(item_exist.guid, item_exist.copies, function(msg)
													if(msg) then
														log("+++++++Destroy "..tostring(item_exist.gsid).." return: #"..tostring(item_exist.guid).." +++++++\n")
														if(msg.issuccess == true) then
															-- use pill or food
															ItemManager.ExtendedCost(exid, nil, nil, function(msg)end, function(msg) 
																local EXPBuffArea = commonlib.gettable("MyCompany.Aries.Desktop.EXPBuffArea");
																EXPBuffArea.ShowBuff_damage_boost_pill_buff()
															end);
														end
													end
												end);
											end
										end,_guihelper.MessageBoxButtons.YesNo);
									else
										-- use pill or food
										ItemManager.ExtendedCost(exid, nil, nil, function(msg)end, function(msg) 
											local EXPBuffArea = commonlib.gettable("MyCompany.Aries.Desktop.EXPBuffArea");
											EXPBuffArea.ShowBuff_damage_boost_pill_buff()
										end);
									end
								end
								return;
							end -- for i, to in ipairs(exTemplate.tos) do
						end
					end
				elseif(gsItem.category == "CollectableSpellScroll") then
					local exid = gsItem.template.stats[51];
					if(exid) then
						local exTemplate = ItemManager.GetExtendedCostTemplateInMemory(exid)
						if(exTemplate) then
							local i, to;
							for i, to in ipairs(exTemplate.tos) do
								-- to.key is the spell gsid
								local spell = ItemManager.GetGlobalStoreItemInMemory(to.key);
								if(spell) then
									if(hasGSItem(to.key)) then
										_guihelper.MessageBox(string.format([[<div style="margin-top:20px;margin-left:10px;width:240px;">你已经学会%s了<div>]], spell.template.name));
										return;
									end
								end
							end
							local i, pre;
							for i, pre in ipairs(exTemplate.pres) do
								if(pre.key == -18) then
									local school_gsid = Combat.GetSchoolGSID();
									local school_name = Combat.GetSchoolNameByGSID(school_gsid);
									if(school_gsid ~= pre.value) then
										_guihelper.MessageBox(string.format([[<div style="margin-top:20px;margin-left:10px;width:240px;">%s系不能使用%s<div>]], school_name, gsItem.template.name));
										return;
									end
								elseif(pre.key == -14) then
									if(Combat.GetMyCombatLevel() < pre.value) then
										_guihelper.MessageBox(string.format([[<div style="margin-top:20px;margin-left:10px;width:240px;">使用%s需要等级达到%s级<div>]], gsItem.template.name, tostring(pre.value)));
										return;
									end
								end
							end
							-- use spell scroll
							ItemManager.ExtendedCost(exid, nil, nil, function(msg) end, function(msg) end);
						end
						return;
					end
				end
			end
		end

		if(System.options.version == "kids") then
			local gsid_marker = gsItem.template.stats[57];
			if(gsid_marker) then
				local gsItem_marker = ItemManager.GetGlobalStoreItemInMemory(gsid_marker);
				local marker_inventory = gsItem_marker.template.inventorytype;
				local bePill = isPill(marker_inventory);
				if(bePill) then
					local can_pass = DealDefend.CanPass();
					if(not can_pass)then
						return
					end
					local exid = gsItem.template.stats[51];
					if(exid) then
						local itme_in_inventory = ItemManager.GetItemByBagAndPosition(0, marker_inventory);
						if(itme_in_inventory and itme_in_inventory.guid ~= 0) then
							local use_pill_words = "";
							local cur_gsid_in_inventory = itme_in_inventory.gsid;
							local cur_guid_in_inventory = itme_in_inventory.guid;
							if(cur_gsid_in_inventory == gsid_marker) then
								use_pill_words = "你已经有同样的药丸了，不需要再吃，是否强制使用新药丸？";
							else
								use_pill_words = "你有同类的药丸，使用新的药丸会覆盖以前的效果，是否强制使用新药丸？";
							end

							_guihelper.MessageBox(use_pill_words, function(msg)
								if(msg and msg == _guihelper.DialogResult.Yes) then
									ItemManager.SellItem(cur_guid_in_inventory,1,function(msg) 
										if(msg.issuccess) then
											ItemManager.ExtendedCost(exid, nil, nil, 
												function(msg)
													if(msg.issuccess) then
														_guihelper.MessageBox("恭喜你获得了新的药丸效果");
													end
												end,
												function(msg) 
													local EXPBuffArea = commonlib.gettable("MyCompany.Aries.Desktop.EXPBuffArea");
													EXPBuffArea.ShowBuff_damage_boost_pill_buff();
												end
											);
										end
									end);
								elseif(msg and msg == _guihelper.DialogResult.No) then
									return;
								end
							end, _guihelper.MessageBoxButtons.YesNo)
						else
							_guihelper.MessageBox(format("是否要使用[%s]?", gsItem.template.name), function()
								Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, 
									function(msg) 
										if(msg.issuccess) then
											_guihelper.MessageBox("恭喜你获得了新的药丸效果");
										end
									end, 
									function(msg) 
										local EXPBuffArea = commonlib.gettable("MyCompany.Aries.Desktop.EXPBuffArea");
										EXPBuffArea.ShowBuff_damage_boost_pill_buff();
									end
								);	
							end);
						end
					end
					
				end
			end
			
			
		end

		if(self_gsid == 17213 and System.options.version == "teen") then
			local exid = 1163;
			Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, function(msg) 
				if(msg.issuccess == true) then
					log("info: AddJoybean from collectable item: "..self_gsid.."\n")
					commonlib.echo(msg)
				end
			end);
			return;
		elseif(self_gsid == 17253 and System.options.version == "teen") then
			local exid = 1269;
			Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, function(msg) 
				if(msg.issuccess == true) then
					log("info: AddJoybean from collectable item: "..self_gsid.."\n")
					commonlib.echo(msg)
				end
			end);
			return;

		elseif(self_gsid == 12017 and System.options.version == "teen") then
			
			if(Item_Collectable.current_playing_id) then
				return;
			end

			local school = Combat.GetSchool();
			local spell_file = "config/Aries/Spells/ItemCasting_"..school..".xml";
			local ProfileManager = commonlib.gettable("System.App.profiles.ProfileManager");
			NPL.load("(gl)script/apps/Aries/Combat/SpellCast.lua");
			local SpellCast = commonlib.gettable("MyCompany.Aries.Combat.SpellCast");

			Item_Collectable.current_playing_id = ParaGlobal.GenerateUniqueID();

			local x, y, z = ParaScene.GetPlayer():GetPosition();
			Item_Collectable.current_playing_player_position = {x, y, z};
			Item_Collectable.current_playing_world = ParaWorld.GetWorldDirectory();

			-- play user avatar animation
			local user_char = ParaScene.GetPlayer();
			if(user_char and user_char:IsValid()) then
				local driver_assetkey = user_char:GetPrimaryAsset():GetKeyName();
				if(driver_assetkey == "character/v3/TeenElf/Female/TeenElfFemale.xml") then
					System.Animation.PlayAnimationFile("character/Animation/v6/teen_Delivery_female.x", user_char);
				elseif(driver_assetkey == "character/v3/TeenElf/Male/TeenElfMale.xml") then
					System.Animation.PlayAnimationFile("character/Animation/v6/teen_Delivery_male.x", user_char);
				end
			end

			-- spell entity
			SpellCast.EntitySpellCast(0, ParaScene.GetPlayer(), 1, ParaScene.GetPlayer(), 1, spell_file, nil, nil, nil, nil, nil, function()
				-- make the animation nonloop
				---- return to standing pose
				--ParaScene.GetPlayer():ToCharacter():PlayAnimation(0);
			end, nil, true, Item_Collectable.current_playing_id, true);
			-- spell duration to check all status change
			SpellCast.PlaySpellDuration(spell_file, function()
				if(Item_Collectable.current_playing_id) then
					Item_Collectable.current_playing_id = nil;
					-- process teleport
					-- 12017_ScrollBackToCity
					if(not hasGSItem(12017)) then
						_guihelper.MessageBox([[<div style="margin-top:20px;margin-left:90px;width:240px;">你还没有传送卷轴！<div>]]);
						return;
					end
					-- gsid
					-- 12017_ScrollBackToCity
					local bHas, guid = hasGSItem(12017);
					if(bHas and guid) then
						Map3DSystem.Item.ItemManager.DestroyItem(guid, 1, function(msg)
							if(msg) then
								log("+++++++Destroy 12017_ScrollBackToCity return: #"..tostring(guid).." +++++++\n")
								if(msg.issuccess == true) then
									-- teleport to main town born position
									NPL.load("(gl)script/apps/Aries/Scene/WorldManager.lua");
									local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
									local current_world = WorldManager:GetCurrentWorld();
									local return_world = WorldManager:GetReturnWorld();
									local name;
									if(current_world and current_world.born_pos and current_world.can_save_location) then
										name = current_world.name;
									elseif(return_world and return_world.born_pos and return_world.can_save_location) then
										name = return_world.name;
									end
									WorldManager:TeleportByWorldAddress(WorldManager:GetMainTownBornAddress(name));
									--NPL.load("(gl)script/apps/Aries/NPCs/Combat/39000_BasicArena.lua");
									--local BasicArena = commonlib.gettable("MyCompany.Aries.Quest.NPCs.BasicArena");
									--BasicArena.TeleportToSafeZone();
								end
							end
						end);
					end
				end
			end, function(elapsedTime)
				-- check every timer frame if valid
				local bValid = true;
				-- check position
				if(Item_Collectable.current_playing_player_position) then
					local x, y, z = ParaScene.GetPlayer():GetPosition();
					if(Item_Collectable.current_playing_player_position[1] ~= x or 
						Item_Collectable.current_playing_player_position[2] ~= y or 
						Item_Collectable.current_playing_player_position[3] ~= z) then
						bValid = false;
					end
				end
				-- check world
				if(Item_Collectable.current_playing_world) then
					if(Item_Collectable.current_playing_world ~= ParaWorld.GetWorldDirectory()) then
						bValid = false;
					end
				end
				if(not bValid and Item_Collectable.current_playing_id) then
					SpellCast.StopSpellCasting(Item_Collectable.current_playing_id);
					Item_Collectable.current_playing_id = nil;
				end
			end)

			return;
		end
		local ItemManager = Map3DSystem.Item.ItemManager;
		if(gsItem) then
			local class = gsItem.template.class;
			local subclass = gsItem.template.subclass;
			if(class == 3 and subclass == 5) then
				if(self_gsid >= 17250 and self_gsid <= 17251 and System.options.version == "teen") then
					local exid = 1263;
					if(self_gsid == 17250) then
						exid = 1263;
					else
						exid = 1264;
					end
					local cur_stamina, max_value = MyCompany.Aries.Player.GetStamina()
					if(cur_stamina < max_value) then
						Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, function(msg) 
							MyCompany.Aries.Desktop.HPMyPlayerArea.UpdateUI();
							if(callbackFunc) then
								callbackFunc(msg);
							end
						end);
					elseif(cur_stamina >= max_value) then
						_guihelper.MessageBox([[<div style="margin-top:20px;margin-left:20px;width:240px;">精力值满，现在不需要使用精力药剂补充<div>]]);
					end
				elseif(self_gsid == 17157 and System.options.version == "teen") then
					local exid = 1416;
					local cur_stamina2, max_value = MyCompany.Aries.Player.GetStamina2()
					if(cur_stamina2 < max_value) then
						Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, function(msg) 
							MyCompany.Aries.Desktop.HPMyPlayerArea.UpdateUI();
							if(callbackFunc) then
								callbackFunc(msg);
							end
						end);
					elseif(cur_stamina2 >= max_value) then
						_guihelper.MessageBox([[<div style="margin-top:20px;margin-left:20px;width:240px;">体力值满，现在不需要使用体力药剂补充<div>]]);
					end
				elseif((self_gsid >= 17155 and self_gsid <= 17156 and System.options.version == "teen") or 
						(System.options.version == "kids" and ((self_gsid >= 17155 and self_gsid <= 17159) or (self_gsid == 17266 or self_gsid == 17267 or self_gsid == 17277 or self_gsid == 17610)))) then
					-- hp potion
					local canUseHPPotion = MsgHandler.GetCanUseHPPotion()
					canUseHPPotion = true; -- always can user hp potion
					if(canUseHPPotion == nil) then
						_guihelper.MessageBox([[<div style="margin-top:20px;margin-left:20px;width:240px;">你今天还没参加战斗呢，还不能食用红枣哦！<div>]]);
					elseif(canUseHPPotion == false) then
						_guihelper.Custom_MessageBox([[<div style="margin-top:15px;margin-left:20px;width:260px;">此次战斗结束后你已经吃过一颗红枣了，现在不能再吃了！食用5级红枣恢复100%HP哦 ！<div>]],function(result)
							if(result == _guihelper.DialogResult.No)then
								NPL.load("(gl)script/apps/Aries/HaqiShop/HaqiShop.lua");
								MyCompany.Aries.HaqiShop.ShowMainWnd("tabTuijian");
							end
						end,_guihelper.MessageBoxButtons.YesNo,{yes = "Texture/Aries/Common/IKnow_32bits.png; 0 0 153 49",no="Texture/Aries/Common/PurchaseImmediately_32bits.png; 0 0 153 49"});
					elseif(canUseHPPotion == true and MsgHandler.IsFullHealth()) then
						-- _guihelper.MessageBox([[<div style="margin-top:20px;margin-left:20px;width:240px;">你的HP已经是最满的啦，不用再食用啦！<div>]]);

					elseif(canUseHPPotion == true and not MsgHandler.IsFullHealth()) then
						local max_hp = MsgHandler.GetMaxHP();
						-- 44 HP_potion_pts(C) 补血药丸恢复的绝对血量
						local potion_absolute = gsItem.template.stats[44];
						-- 45 HP_potion_pts_percent(C) 补血药丸恢复的血量百分比 
						local potion_percent = gsItem.template.stats[45];
						MsgHandler.PostUseHPPotion();
							
						Map3DSystem.Item.ItemManager.DestroyItem(self.guid, 1, function(msg)
							if(msg) then
								log("+++++++Destroy collectable reward item return: #"..tostring(self.guid).." +++++++\n")
								if(msg.issuccess == true) then
									-- hard code the HealByWisp here, move to the game server in the next release candidate
									if(potion_percent and potion_percent > 0) then
										log("info: HealByPotion from collectable reward "..potion_percent.."%%\n")
										MsgHandler.HealByWisp(potion_percent / 100, true); -- true for bForceProportion
									end
									if(potion_absolute and potion_absolute > 0) then
										log("info: HealByPotion from collectable reward HP:"..potion_absolute.."\n")
										MsgHandler.HealByWisp(potion_absolute);
									end
									-- play use hp potion effect
									if(System.options.version == "teen") then
										NPL.load("(gl)script/apps/Aries/Combat/SpellCast.lua");
										local SpellCast = commonlib.gettable("MyCompany.Aries.Combat.SpellCast");
										local spell_file = "config/Aries/Spells/Action_UseHPPotion.xml";
										local current_playing_id = ParaGlobal.GenerateUniqueID();
										SpellCast.EntitySpellCast(0, ParaScene.GetPlayer(), 1, ParaScene.GetPlayer(), 1, spell_file, nil, nil, nil, nil, nil, function()
										end, nil, true, current_playing_id, true);
									end
								end
							end
						end);
					end
				elseif(self_gsid >= 17131 and self_gsid <= 17140) then
					-- exp bag
					-- 695 Feed_17131_ExpBagLevel1 
					-- 696 Feed_17132_ExpBagLevel2 
					-- 697 Feed_17133_ExpBagLevel3 
					-- 698 Feed_17134_ExpBagLevel4 
					-- 699 Feed_17135_ExpBagLevel5 
					-- 700 Feed_17136_ExpBagLevel6 
					-- 701 Feed_17137_ExpBagLevel7 
					-- 702 Feed_17138_ExpBagLevel8 
					-- 703 Feed_17139_ExpBagLevel9 
					-- 704 Feed_17140_ExpBagLevel10 

					local mylevel = Combat.GetMyCombatLevel();
					if(System.options.version == "kids" and mylevel >= System.options.max_user_level) then
						_guihelper.MessageBox([[<div style="margin-top:20px;margin-left:10px;width:300px;">你已经达到经验上限了，不能再吃面包了。<div>]]);
						return;
					end
					if(System.options.version == "teen" and mylevel >= System.options.max_user_level) then
						_guihelper.MessageBox([[<div style="margin-top:20px;margin-left:10px;width:300px;">你已经达到经验上限了，不能再吃面包了。<div>]]);
						return;
					end

					local exid_mapping = {
						[17131] = 695,
						[17132] = 696,
						[17133] = 697,
						[17134] = 698,
						[17135] = 699,
						[17136] = 700,
						[17137] = 701,
						[17138] = 702,
						[17139] = 703,
						[17140] = 704,
					};
					local exid = exid_mapping[self_gsid];
					Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, function(msg) 
						if(msg.issuccess == true) then
							local exp = tonumber((msg.obtains or {})[-13]) or 0;
							paraworld.PostLog({action = "user_gain_exp", exp_pt = exp, reason = "ExpPackage"}, "user_gain_exp_log", function(msg)
							end);
							log("info: AddExp from collectable reward "..exp.."\n")
							commonlib.echo(msg)
							
							-- play exp bag spell
							if(System.options.version == "teen") then
								NPL.load("(gl)script/apps/Aries/Combat/SpellCast.lua");
								local SpellCast = commonlib.gettable("MyCompany.Aries.Combat.SpellCast");
								local spell_file = "config/Aries/Spells/Action_UseExpBag.xml";
								local current_playing_id = ParaGlobal.GenerateUniqueID();
								SpellCast.EntitySpellCast(0, ParaScene.GetPlayer(), 1, ParaScene.GetPlayer(), 1, spell_file, nil, nil, nil, nil, nil, function()
								end, nil, true, current_playing_id, true);
							end
						end
					end);
					
				elseif((self_gsid == 17227 or self_gsid == 17344 or self_gsid == 17345 or self_gsid == 17393) and System.options.version == "kids") then
					local exid = gsItem.template.stats[51];
					local cur_stamina, max_value = MyCompany.Aries.Player.GetStamina();
					if(exid and cur_stamina < max_value) then
						_guihelper.MessageBox(format("你目前的精力值是%d/%d, 确定要使用精力药剂补充么？", cur_stamina, max_value), function(res)
								if(res and res == _guihelper.DialogResult.Yes) then
									Map3DSystem.Item.ItemManager.ExtendedCost(exid, nil, nil, function(msg) 
											MyCompany.Aries.Desktop.HPMyPlayerArea.UpdateUI();
											if(callbackFunc) then
												callbackFunc(msg);
											end
										end);
								end
							end, _guihelper.MessageBoxButtons.YesNo);
					elseif(cur_stamina >= max_value) then
						_guihelper.MessageBox([[<div style="margin-top:20px;margin-left:20px;width:240px;">精力值满，现在不需要使用精力药剂补充<div>]]);
					end
				else
					-- normal reward
					local joybean = gsItem.template.stats[33];
					--local exp = gsItem.template.stats[34];
					if(joybean and joybean > 0) then
						Map3DSystem.Item.ItemManager.DestroyItem(self.guid, 1, function(msg)
							if(msg) then
								log("+++++++Destroy collectable reward item return: #"..tostring(self.guid).." +++++++\n")
								if(msg.issuccess == true) then
									-- hard code the AddMoney here, move to the game server in the next release candidate
									if(joybean and joybean > 0) then
										log("info: AddMoney from collectable reward "..joybean.."\n")
										MyCompany.Aries.Player.AddMoney(joybean, function(msg) end);
									end
									--if(exp and exp > 0) then
										--log("info: AddExp from collectable reward "..exp.."\n")
										--MyCompany.Aries.Player.AddExp(exp, function() end);
										--paraworld.PostLog({action = "user_gain_exp", exp_pt = exp, reason = "ExpPackage"}, "user_gain_exp_log", function(msg)
										--end);
									--end
								end
							end
						end);
					end
				end
			end
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

function Item_Collectable:GetTooltip()
	local ItemManager = Map3DSystem.Item.ItemManager;
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid)
	if(gsItem) then
		local name = gsItem.template.name;
		-- stats
		--33 Collectable_Reward_Joybean(C) 钱袋包  
		--34 Collectable_Reward_Exp(C) 经验包  
		local tooltip = name;
		local joybean = gsItem.template.stats[33];
		if(joybean) then
			tooltip = tooltip.."\n"..joybean.."奇豆\n点击使用";
		end
		local exp = gsItem.template.stats[34];
		if(exp) then
			tooltip = tooltip.."\n"..(exp * 100).."经验\n点击使用";
		end
		if(gsItem.template.class == 3 and gsItem.template.subclass == 6) then
			-- SocketableGem
			local stat_word = "";
			local _t, value;
			for _t, value in pairs(gsItem.template.stats) do
				local word = Combat.GetStatWord_OfTypeValue(_t, value);
				if(word) then
					stat_word = stat_word..word.."\n";
				end
			end
			if(System.options.version =="kids")then
				tooltip = tooltip.."\n镶嵌后 "..stat_word.."找达尔莫德（购物街）可镶嵌或合成宝石";
			else
				tooltip = tooltip.."\n镶嵌后 "..stat_word.."找黎明城商业区的达尔莫德镶嵌或合成宝石";
			end
		elseif(gsItem.template.class == 3 and gsItem.template.subclass == 7) then
			-- SocketingRune
			-- 35 Socketing_Rune_Success_Ratio(CS) 镶嵌符的影响成功率的数值 例如10 代表10%
			tooltip = tooltip.."\n提高镶嵌成功率 "..(gsItem.template.stats[35] or 0).."%";
			
		elseif(self.gsid >= 17144 and self.gsid <= 17148) then
			tooltip = tooltip.."\n可用于套装兑换-购物街找苏苏";
			
		elseif(self.gsid == 17143) then
			tooltip = tooltip.."\n可找全齐齐换面包-火焰山洞内";
		end

		if(self.gsid == 17149) then
			tooltip = "新居民礼盒\n鼠标点击使用\n内含： 宝石、变色药丸、绝版装扮";
		end
		
		--for original tooltip style
		if(System.options.version =="kids")then
			if(self.gsid == 17150) then
				return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..self.gsid;
			end
		
			if(self.gsid == 17151) then
				return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..self.gsid;
			end
		
			if(self.gsid >= 17155 and self.gsid <= 17159) then
				return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..self.gsid;
			end
		
			if(self.gsid == 17152) then
				tooltip = name.."\n试炼之塔开启第8层";
			elseif(self.gsid == 17153) then
				tooltip = name.."\n试炼之塔开启第26层";
			elseif(self.gsid == 17154) then
				tooltip = name.."\n试炼之塔开启第61层";
			end
			
			if(self.gsid == 17214) then
				tooltip = name.."\n使用增加家族活跃度";
			end
			
		
			if(self.gsid >= 17160 and self.gsid <= 17162) then
				return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..self.gsid;
			end
		
			if(self.gsid == 17167) then
				return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..self.gsid;
			end
		
			if(self.gsid == 17169) then
				return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..self.gsid;
			end
		
			if(self.gsid == 17172 or self.gsid == 17185 or self.gsid == 17211) then
				return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..self.gsid;
			end

			if(self.gsid == 12001 or self.gsid == 12002 or self.gsid == 12003 or self.gsid == 12005 or self.gsid == 12006 or self.gsid == 12007) then
				return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..self.gsid;
			end
		
			if(self.gsid == 12012 or self.gsid == 12013 or self.gsid == 12014 or self.gsid == 12017 or self.gsid == 12018) then
				return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..self.gsid.."&guid="..self.guid;
			end
		
			if(self.gsid == 12010) then
				return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..self.gsid;
			end
		
			if(self.gsid == 17176) then
				return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..self.gsid;
			end
		
			if(self.gsid == 17178) then
				return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..self.gsid;
			end
		
			if(self.gsid == 17179) then
				return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..self.gsid;
			end
			
			if(self.gsid == 12015) then
				return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..self.gsid;
			end
			if(self.gsid == 12006) then
				return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..self.gsid;
			end
			if(self.gsid == 17213) then
				return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..self.gsid;
			end
			if(self.gsid == 17215) then
				return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..self.gsid;
			end
		
			if(self.gsid == 17212) then
				return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..self.gsid.."&guid="..self.guid;
			end
			
			if(self.gsid >= 17216 and self.gsid <= 17220) then
				return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..self.gsid.."&guid="..self.guid;
			end
		else	
			if(self.gsid == 17152) then
				tooltip = name.."\n试炼之塔开启第8层";
			elseif(self.gsid == 17153) then
				tooltip = name.."\n试炼之塔开启第26层";
			elseif(self.gsid == 17154) then
				tooltip = name.."\n试炼之塔开启第61层";
			else
				return "page://script/apps/Aries/Desktop/GenericTooltip_InOne.html?gsid="..(self.gsid or 0);
			end
		
		end
		
		return tooltip;
	end
end