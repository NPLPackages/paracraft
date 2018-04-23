--[[
Title: follow pet 
Author(s): WangTian
Date: 2009/6/17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_FollowPet.lua");
------------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemItem/Item_FollowPet_Skills.lua");
NPL.load("(gl)script/apps/Aries/Pet/AI/MountPet_Homeland.lua");
NPL.load("(gl)script/apps/Aries/CombatPet/CombatPetHelper.lua");
NPL.load("(gl)script/apps/Aries/Pet/main.lua");
NPL.load("(gl)script/apps/Aries/Desktop/GUIHelper/CustomMessageBox.lua");
local Pet = commonlib.gettable("MyCompany.Aries.Pet");

NPL.load("(gl)script/apps/Aries/VIP/PurChaseEnergyStone.lua");
local PurchaseEnergyStone = commonlib.gettable("MyCompany.Aries.Inventory.PurChaseEnergyStone");

NPL.load("(gl)script/apps/Aries/CombatPet/CombatPetConfig.lua");
local CombatPetConfig = commonlib.gettable("MyCompany.Aries.CombatPet.CombatPetConfig");
local CombatPetHelper = commonlib.gettable("MyCompany.Aries.CombatPet.CombatPetHelper");

NPL.load("(gl)script/apps/Aries/Quest/QuestHelp.lua");
local QuestHelp = commonlib.gettable("MyCompany.Aries.Quest.QuestHelp");

local Item_FollowPet = commonlib.gettable("Map3DSystem.Item.Item_FollowPet")

-- for game server only
local PowerItemManager = commonlib.gettable("Map3DSystem.Item.PowerItemManager");
local ItemManager = Map3DSystem.Item.ItemManager;
local gateway = commonlib.gettable("Map3DSystem.GSL.gateway");
---------------------------------
-- functions
---------------------------------
function Item_FollowPet:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self);
	self.__index = self;
	return o
end
---------------------------------
-- for combat pet
---------------------------------
Item_FollowPet.all_fruits_list = {
		17001,--樱桃
		17002,--菠萝
		17003,--竹子
		17004,--紫藤萝
		17044,--西梅
		--17045,--麻烦树
		17046,--梅花
		17076,--金菊
		17085,--康乃馨
		17089,--蒲公英
		17090,--糖卷卷
		17091,--泡泡糖
		17092,--夹心蛋糕
		17098,--苹果
		17097,--玉米
		17099,--香蕉
	}
Item_FollowPet.date_fruit = {};
function Item_FollowPet:GetRandomFruitGsid()
	NPL.load("(gl)script/kids/3DMapSystemUI/HomeLand/HomeLandGateway.lua");
	local HomeLandGateway = commonlib.gettable("Map3DSystem.App.HomeLand.HomeLandGateway");
	local date = ParaGlobal.GetDateFormat("yyyy-MM-dd");
	local fruits = self.all_fruits_list;
	--宠物id
	local pet_gsid = self.gsid;
	if(fruits and pet_gsid)then
		local key = string.format("%d_%s",pet_gsid,date);
		local gsid = self.date_fruit[key];
		if(gsid)then
			return gsid;
		end
		local len = #fruits;
		local index = math.random(len);
		gsid = fruits[index];
		self.date_fruit[key] = gsid;
		return gsid;
	end
end
function Item_FollowPet:IsTeenVersion()
	local options = commonlib.gettable("System.options");
	if(options.version and options.version == "teen")then
		return true;
	end
end
function Item_FollowPet:GetPrimitiveData_server()
	local date = ParaGlobal.GetDateFormat("yyyy-MM-dd");
	local gsid = self:GetRandomFruitGsid();
	local data = {
		exp = 0,--战斗经验
		cur_feed_num = 0,--喂养次数
		cur_feed_date = date,--喂养时间
		cur_fruit_gsid = gsid,--今天可以吃的水果
	};
	return data;
end
--[[
	local serverdata = {
		exp = 0,--战斗经验
		cur_feed_num = 0,--喂养次数
		cur_feed_date = "2011-02-28",--喂养时间
		cur_fruit_gsid = 17002,--今天可以吃的水果
	}
--]]
--NOTE:server端没有判断 这个宠物是否可以增加经验，目前信任客户端的操作
function Item_FollowPet:OnCombatComplete_server(user_exp)
	if(self:IsTeenVersion())then
		self:OnCombatComplete_server_Teens(user_exp);
	else
		self:OnCombatComplete_server_Kids(user_exp);
	end
end
function Item_FollowPet:OnCombatComplete_server_Kids(user_exp)
	LOG.std("", "info","Item_FollowPet:OnCombatComplete_server",{nid = self.nid,user_exp = user_exp});
	if(self.nid) then
		local provider = CombatPetHelper.GetServerProvider(self:IsTeenVersion());
		if(provider)then
			local p = provider:GetPropertiesByID(self.gsid)
			local level,cur_exp,total_exp,isfull = provider:GetLevelInfo(self.gsid,self:GetExp() or 0);
			LOG.std("", "info","Item_FollowPet:OnCombatComplete_server cur_info",{gsid = self.gsid, guid = self.guid, level = level,cur_exp = cur_exp,total_exp = total_exp,isfull = isfull,});
			--如果没有满级
			if(p and level and level >=0 and not isfull)then
				local odds = 0;
				local odds_default = p.add_exp_percent_default;
				if(odds_default)then
					--用默认值
					odds = odds_default;
				else
					if(p.add_exp_percent_level)then
						odds = p.add_exp_percent_level[level + 1] or 0;
					end
				end
				user_exp = tonumber(user_exp) or 0;
				user_exp = math.ceil(user_exp * odds / 100);

				--每次战斗最多增加的经验值
				local add_exp_max_default = p.add_exp_max_default;
				if(add_exp_max_default)then
					user_exp = math.min(user_exp,add_exp_max_default);
				else
					local add_exp_max_cur_level = 0;
					if(p.add_exp_max_level)then
						--本级升级最大经验值
						add_exp_max_cur_level = p.add_exp_max_level[level + 1];
						if(add_exp_max_cur_level)then
							user_exp = math.min(user_exp,add_exp_max_cur_level);
						end
					end	
				end
				

				user_exp = math.max(user_exp,0);
				local data = self:GetServerData();
				local exp;
				if(data)then
					exp = data.exp or 0;
					exp = exp + user_exp;

					local max_exp = p.max_exp;
					--所有阶段总经验最大值
					exp = math.min(exp,max_exp);
					data.exp = exp;
				else
					--data = {
						--exp = 0,
					--}
					data = self:GetPrimitiveData_server();
				end
				LOG.std("", "info","Item_FollowPet:OnCombatComplete_server save serverdata",data);
				self:SaveServerData(data);

				local gridnode = gateway:GetPrimGridNode(tostring(self.nid));
				if(gridnode) then
					local server_object = gridnode:GetServerObject("sPowerAPI");
					if(server_object) then
						local msg = {
							pet_gsid = self.gsid,
							add_exp = user_exp,
							exp = exp,
						}
						server_object:SendRealtimeMessage(tostring(self.nid), "[Aries][PowerAPI]CombatpetUpdateExp:"..commonlib.serialize_compact(msg));
					end
				end
				return user_exp;
			end
		end
	end
end
function Item_FollowPet:OnCombatComplete_server_Teens(user_exp)
	
end
function Item_FollowPet:OnCombatComplete_server_Teens_backup(user_exp)
	LOG.std("", "info","Item_FollowPet:OnCombatComplete_server",{nid = self.nid,user_exp = user_exp});
	if(self.nid) then
		local pet_config = CombatPetConfig.GetInstance_Server(true);
		
		if(pet_config)then
			local row,row_common = pet_config:GetRow(self.gsid);
			local levels_info = pet_config:GetLevelsInfo(self.gsid,self:GetExp() or 0);
			local level = levels_info.cur_level;
			local cur_exp = levels_info.cur_level_exp;
			local total_exp = levels_info.cur_level_max_exp;
			local max_exp = levels_info.max_exp;
			local isfull = levels_info.isfull;

			LOG.std("", "info","Item_FollowPet:OnCombatComplete_server cur_info",{gsid = self.gsid, guid = self.guid, level = level,cur_exp = cur_exp,total_exp = total_exp,isfull = isfull,});
			--如果没有满级
			if(row and row_common and level and level >=0 and not isfull)then
				local odds = row_common.exp_percent or 5;--默认5%
				user_exp = tonumber(user_exp) or 0;
				user_exp = math.ceil(user_exp * odds / 100);

				--每次战斗最多增加的经验值
				local add_exp_max_default = row_common.get_max_exp or 2048;--默认获取经验最大值
				if(add_exp_max_default)then
					user_exp = math.min(user_exp,add_exp_max_default);
				end
				user_exp = math.max(user_exp,0);
				local data = self:GetServerData();
				local exp;
				if(data)then
					exp = data.exp or 0;
					exp = exp + user_exp;

					--所有阶段总经验最大值
					exp = math.min(exp,max_exp);
					data.exp = exp;
				else
					--data = {
						--exp = 0,
					--}
					data = self:GetPrimitiveData_server();
				end
				LOG.std("", "info","Item_FollowPet:OnCombatComplete_server save serverdata",data);
				self:SaveServerData(data);

				local gridnode = gateway:GetPrimGridNode(tostring(self.nid));
				if(gridnode) then
					local server_object = gridnode:GetServerObject("sPowerAPI");
					if(server_object) then
						local msg = {
							pet_gsid = self.gsid,
							add_exp = user_exp,
							exp = exp,
						}
						server_object:SendRealtimeMessage(tostring(self.nid), "[Aries][PowerAPI]CombatpetUpdateExp:"..commonlib.serialize_compact(msg));
					end
				end
				return user_exp;
			end
		end
	end
end
function Item_FollowPet:SetName_client(name)
	name = tostring(name);
	if(name)then
		local data = self:GetClientData();
		if(data)then
			data.pet_name = name;
			self:SaveClientData(data);
		end
	end
end
--返回宠物的品质 0白 1绿 2蓝 3紫 4橙 默认为0
function Item_FollowPet:GetQualityAndMaxQuality()
	local cur_quality;
	local max_quality;
	if(self:IsTeenVersion())then
		local pet_config = CombatPetConfig.GetInstance_Client();
		local row = pet_config:GetRow(self.gsid);
		if(row)then
			cur_quality = row.quality;
			max_quality = cur_quality;
		end
		return cur_quality or 0,max_quality or 0;
	end
	local provider = CombatPetHelper.GetClientProvider();
	if(provider)then
		cur_quality,max_quality = provider:GetQualityAndMaxQuality(self.gsid,self:GetExp() or 0);
	end
	return cur_quality or 0,max_quality or 0;
end
function Item_FollowPet:GetName_client()
	local pet_name="";
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid);
	if(gsItem) then
		pet_name = gsItem.template.name;
	end
	local data;
	if(self:IsTeenVersion())then
		data = self:GetServerData();--取serverdata
	else
		data = self:GetClientData();
	end
	if(data and data.pet_name)then
		pet_name = data.pet_name or pet_name;
	end
	return pet_name;
end

--获取clientdata 必须执行这个函数
function Item_FollowPet:GetClientData()
	if(self.clientdata)then
		if(type(self.clientdata) == "string")then
			if(self.clientdata == "")then
				self.clientdata = {};
			else
				self.clientdata = commonlib.LoadTableFromString(self.clientdata) or {};
			end
		end
		return self.clientdata;
	end
end
--保存clientdata必须执行这个函数
function Item_FollowPet:SaveClientData(data)
	if(not data)then return end
	if(type(data) == "table")then
		data = commonlib.serialize_compact(data);
		ItemManager.SetClientData(self.guid, data, function(msg) end);
	end
end
-------------------------------------GetSchool-------------------------------------
--返回宠物系别 6火 7冰 8风暴 9神秘 10生命 11死亡 12平衡
function Item_FollowPet:GetSchool(isServer)
	if(self:IsTeenVersion())then
		return self:GetSchool_Teens(isServer);
	else
		return self:GetSchool_Kids(isServer);
	end
end
function Item_FollowPet:GetSchool_Kids(isServer)
	local provider;
	if(isServer)then
		provider = CombatPetHelper.GetServerProvider(self:IsTeenVersion());
	else
		provider = CombatPetHelper.GetClientProvider();
	end
	if(provider)then
		local p = provider:GetPropertiesByID(self.gsid);
		if(p)then
			return tonumber(p.school_requirement) or 6;
		end
	end
	return 6;
end
function Item_FollowPet:GetSchool_Teens(isServer)
	local pet_config;
	if(isServer)then
		pet_config = CombatPetConfig.GetInstance_Server(true);
	else
		pet_config = CombatPetConfig.GetInstance_Client();
	end
	if(pet_config)then
		local row = pet_config:GetRow(self.gsid);
		if(row)then
			return row.school or 6;
		end
	end
	return 6;
end
-------------------------------------GetLevelsInfo-------------------------------------
--[[
青年版有效
return local node = {
			start_evolve_level = start_evolve_level,--开始进化 
			cur_level = cur_level,--当前级别
			cur_level_exp = cur_level_exp,--当前级别经验值
			cur_level_max_exp = cur_level_max_exp,--当前级别总经验值
			max_level = max_level,--最高级别
			max_exp = max_exp,--满级经验总和
			cur_stat_list = cur_stat_list,--虚体附加属性
			cur_entity_stat_list = cur_entity_stat_list,--实体附加属性
			cur_cards_list = cur_cards_list,--虚体附加卡片
			cur_entity_cards_list = cur_entity_cards_list,--实体附加卡片

			stat_list = stat_list,
			entity_stat_list = entity_stat_list,
			cards_list = cards_list,
			entity_cards_list = entity_cards_list,
			is_full = is_full,--是否已经满级
		}
--]]
function Item_FollowPet:GetLevelsInfo(isServer)
	if(self:IsTeenVersion())then
		local pet_config;
		if(isServer)then
			pet_config = CombatPetConfig.GetInstance_Server(true);
		else
			pet_config = CombatPetConfig.GetInstance_Client();
		end
		if(pet_config)then
			return pet_config:GetLevelsInfo(self.gsid,self:GetExp() or 0);
		end
	else
		return {};
	end
end
--返回实体卡片 cur_entity_cards_list ={ {gsid = gsid, ai_key = ai_key}, {gsid = gsid, ai_key = ai_key}, }
function Item_FollowPet:GetCurLevelAICards(isServer)
	if(self:IsTeenVersion())then
		return self:GetCurLevelAICards_Teens(isServer);
	else
		return {};
	end
end
function Item_FollowPet:GetCurLevelAICards_Teens(isServer)
	local pet_config;
	if(isServer)then
		pet_config = CombatPetConfig.GetInstance_Server(true);
	else
		pet_config = CombatPetConfig.GetInstance_Client();
	end
	if(pet_config)then
		return pet_config:GetCurLevelAICards(self.gsid,self:GetExp() or 0);
	end
	return {};
end
-------------------------------------GetCurLevelCards-------------------------------------
--返回当前级别所带的卡片
--return {} or {20,21,22}
function Item_FollowPet:GetCurLevelCards(isServer)
	if(self:IsTeenVersion())then
		return self:GetCurLevelCards_Teens(isServer);
	else
		return self:GetCurLevelCards_Kids(isServer);
	end
end
function Item_FollowPet:GetCurLevelCards_Kids(isServer)
	local provider;
	if(isServer)then
		provider = CombatPetHelper.GetServerProvider(self:IsTeenVersion());
	else
		provider = CombatPetHelper.GetClientProvider();
	end
	if(provider)then
		--包含普通成长 和 高级成长两种情况
		local value = provider:GetCurLevelCards(self.gsid,self:GetExp() or 0);
		if(value)then
			return value;
		end
	end
	return {};
end
function Item_FollowPet:GetCurLevelCards_Teens(isServer)
	local pet_config;
	if(isServer)then
		pet_config = CombatPetConfig.GetInstance_Server(true);
	else
		pet_config = CombatPetConfig.GetInstance_Client();
	end
	if(pet_config)then
		return pet_config:GetCurLevelCards(self.gsid,self:GetExp() or 0);
	end
	return {};
end
-------------------------------------GetCurLevelProps-------------------------------------
--返回当前级别所带的附加属性
--return {} or { [102]=5, [103]=10,}
function Item_FollowPet:GetCurLevelProps(isServer)
	if(self:IsTeenVersion())then
		return self:GetCurLevelProps_Teens(isServer);
	else
		return self:GetCurLevelProps_Kids(isServer);
	end
end
function Item_FollowPet:GetCurLevelProps_Kids(isServer)
	local provider;
	if(isServer)then
		provider = CombatPetHelper.GetServerProvider(self:IsTeenVersion());
	else
		provider = CombatPetHelper.GetClientProvider();
	end
	if(provider)then
		--包含普通成长 和 高级成长两种情况
		local value = provider:GetCurLevelProps(self.gsid,self:GetExp() or 0);
		if(value)then
			--儿童版有宝石附加属性
			if(not self:IsTeenVersion())then
				local gem_gsid = self:GetAddon_Gem_Gsid();
				if(gem_gsid)then
					 local addon_map = provider:GetAddonProperties(gem_gsid);
					 return provider:AddTwoTable(value,addon_map);
				end
			end
			return value;
		end
	end
	return {};
end
function Item_FollowPet:GetCurLevelProps_Teens(isServer)
	local pet_config;
	if(isServer)then
		pet_config = CombatPetConfig.GetInstance_Server(true);
	else
		pet_config = CombatPetConfig.GetInstance_Client();
	end
	if(pet_config)then
		return pet_config:GetCurLevelProps(self.gsid,self:GetExp() or 0);
	end
	return {};
end
-------------------------------------GetCurLevelAssetID-------------------------------------
--返回当前级别的形象的编号 0(默认) or 1(满级) or 2(进化满级)
function Item_FollowPet:GetCurLevelAssetID(isServer)
	if(self:IsTeenVersion())then
		return self:GetCurLevelAssetID_Teens(isServer);
	else
		return self:GetCurLevelAssetID_Kids(isServer);
	end
end
function Item_FollowPet:GetCurLevelAssetID_Kids(isServer)
	local provider;
	if(isServer)then
		provider = CombatPetHelper.GetServerProvider(self:IsTeenVersion());
	else
		provider = CombatPetHelper.GetClientProvider();
	end
	if(provider)then
		local id = provider:GetCurLevelAssetID(self.gsid,self:GetExp() or 0);
		return id;
	end
end
function Item_FollowPet:GetCurLevelAssetID_Teens(isServer)
	local pet_config;
	if(isServer)then
		pet_config = CombatPetConfig.GetInstance_Server(true);
	else
		pet_config = CombatPetConfig.GetInstance_Client();
	end
	if(pet_config)then
		local assetfile,id = pet_config:GetCurLevelAssetFileAndID(self.gsid,self:GetExp() or 0);
		return id;
	end
end
-------------------------------------GetCurLevelAssetFile-------------------------------------
--返回当前级别的形象
function Item_FollowPet:GetCurLevelAssetFile(isServer)
	if(self:IsTeenVersion())then
		return self:GetCurLevelAssetFile_Teens(isServer);
	else
		return self:GetCurLevelAssetFile_Kids(isServer);
	end
end
function Item_FollowPet:GetCurLevelAssetFile_Kids(isServer)
	local provider;
	if(isServer)then
		provider = CombatPetHelper.GetServerProvider(self:IsTeenVersion());
	else
		provider = CombatPetHelper.GetClientProvider();
	end
	if(provider)then
		local assetfile = provider:GetCurLevelAssetFile(self.gsid,self:GetExp() or 0);
		return assetfile;
	end
end
function Item_FollowPet:GetCurLevelAssetFile_Teens(isServer)
	local pet_config;
	if(isServer)then
		pet_config = CombatPetConfig.GetInstance_Server(true);
	else
		pet_config = CombatPetConfig.GetInstance_Client();
	end
	if(pet_config)then
		local assetfile,id = pet_config:GetCurLevelAssetFileAndID(self.gsid,self:GetExp() or 0);
		return assetfile;
	end
end
--获取serverdata 必须执行这个函数
function Item_FollowPet:GetServerData()
	if(self.serverdata)then
		if(type(self.serverdata) == "string")then
			--转换,|
			if(self.serverdata == "")then
				self.serverdata = {};
			else
				self.serverdata = QuestHelp.DeSerializeTable(self.serverdata) or {};
			end
		end
		return self.serverdata;
	end
end
--保存serverdata必须执行这个函数
function Item_FollowPet:SaveServerData(data,callbackFunc)
	if(not data)then return end
	if(type(data) == "table")then
		--转换,|
		data = QuestHelp.SerializeTable(data);
		PowerItemManager.SetServerData(self.nid, self.guid, data, function(msg) 
			if(callbackFunc)then
				callbackFunc(msg);
			end
		end, {0});
	end
end
--返回宠物的总经验
function Item_FollowPet:GetExp()
	local exp = 0;
	local data = self:GetServerData();
	if(data)then
		exp = data.exp or 0;
	end
	return exp;
end
--返回镶嵌的宝石的gsid
--nil 表示没有镶嵌宝石
function Item_FollowPet:GetAddon_Gem_Gsid()
	local data = self:GetServerData();
	if(data)then
		return data.gem_gsid;
	end
end
function Item_FollowPet:GetMouseOverName()
	local provider = CombatPetHelper.GetClientProvider();
	if(provider)then
		local p = provider:GetPropertiesByID(self.gsid)
		description = commonlib.serialize_compact(p)
		local iscombat_pet = provider:IsCombatPet(self.gsid);
		if(iscombat_pet)then
			self.test_index = self.test_index or 1;
			self.test_index = self.test_index + 1;
			local pet_name = self:GetName_client();
			local cards = commonlib.serialize_compact(self:GetCurLevelCards());
			local props = commonlib.serialize_compact(self:GetCurLevelProps());
			local level,cur_exp,total_exp,isfull = provider:GetLevelInfo(self.gsid,self:GetExp() or 0);
			local s1 = "";
			local s2 = "";
			if(level == -1)then
			elseif(isfull)then
				s1 = pet_name;
				s2 = string.format("级别:%d",level);
			else
				s1 = pet_name;
				s2 = string.format("级别:%d,经验:%d/%d",level,cur_exp or 0,total_exp or 0);
			end
			return s1,s2;
		end
	end
end

-- When item is clicked through pe:slot
function Item_FollowPet:OnClick(mouse_button, bSkipMessageBox, bForceUsing, bShowStatsDiff, EquipItemCallback)
	if(self.nid and self.nid ~= System.App.profiles.ProfileManager.GetNID()) then
		log("error: can't follow other OPC's pet in Item_FollowPet:OnClick(mouse_button)\n");
		return;
	end
	
	NPL.load("(gl)script/ide/TooltipHelper.lua");
	local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
	local Combat = commonlib.gettable("MyCompany.Aries.Combat");

	if(mouse_button == "left") then
		
		-- mount or use the item
		if(self.bag == 0 and self.position and not bForceUsing) then
			self:GoHome()
		elseif(not (self.bag == 0 and self.position)) then
			local stats_labels = {};
			if(bShowStatsDiff) then
				-- get last and current follow pet stats
				local stats_current = {};
				local stats = {};
				local new_pet_name;
				local item_current = ItemManager.GetItemByBagAndPosition(0, 32);
				if(item_current and item_current.guid > 0 and item_current.GetCurLevelProps) then
					stats_current = item_current:GetCurLevelProps();
				end
				if(self.guid > 0 and self.GetCurLevelProps) then
					stats = self:GetCurLevelProps();
					local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid);
					if(gsItem) then
						new_pet_name = gsItem.template.name;
					end
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
				if(new_pet_name) then
					tip_count = tip_count + 1;
					--BroadcastHelper.PushLabel({id = "stats_diff_tip_"..tip_count, label = new_pet_name.."上场", max_duration=10000, color = "0 255 0", scaling=1, bold=true, shadow=true,});
					table.insert(stats_labels, {
						line = new_pet_name.."上场",
						color = "0 255 0",
					});
				end
				-- show each stat diff
				local stat_type, stat_value;
				for stat_type, stat_value in pairs(stats_diff) do
					local each_stat_map = Combat.GetStatMap(stat_type);
					if(each_stat_map) then
						local signed_stat_value;
						local color;
						-- 188 add_dodge_overall_percent(CG) 增加用户所有系魔法的闪避百分比 1:10配置 写1的意思是0.1% 
						-- 243 add_hitchance_overall_percent(CG) 增加用户所有系魔法的命中百分比 此命中非儿童版的命中概念，不再是判断是否施放技能成败，而是判断是否偏斜；命中造成100%伤害，偏斜造成50%伤害 1:10配置 写1的意思是0.1%
						if(stat_type == 188 or stat_type == 243) then
							stat_value = stat_value / 10;
						end
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
								local each_line = string.format(str_format, signed_stat_value);
								tip_count = tip_count + 1;
								--BroadcastHelper.PushLabel({id = "stats_diff_tip_"..tip_count, label = each_line, max_duration=10000, color = color, scaling=1, bold=true, shadow=true,});
								table.insert(stats_labels, {
									line = each_line,
									color = color,
								});
							elseif(each_stat_map.type == "va_format" and each_stat_map.str_format) then
								local str_format = string.gsub(each_stat_map.str_format, "%+", "");
								local each_line = string.format("%s%s", str_format, signed_stat_value);
								tip_count = tip_count + 1;
								--BroadcastHelper.PushLabel({id = "stats_diff_tip_"..tip_count, label = each_line, max_duration=10000, color = color, scaling=1, bold=true, shadow=true,});
								table.insert(stats_labels, {
									line = each_line,
									color = color,
								});
							end
						end
					end
				end
			end
			local function ShowStatsDiff()
				-- clear previous tips
				local i;
				for i = 1, 15 do
					BroadcastHelper.Clear("stats_diff_tip_"..i);
				end
				local _, each_line;
				for _, each_line in ipairs(stats_labels) do
					BroadcastHelper.PushLabel({id = "stats_diff_tip_"..tostring(_), label = each_line.line, max_duration=10000, color = each_line.color, scaling=1, bold=true, shadow=true,});
				end
			end
			-- equip the follow pet
			self:FollowMe(nil, function(msg)
				if(msg and msg.issuccess) then
					ShowStatsDiff();
				end
				if(EquipItemCallback) then
					EquipItemCallback();
				end
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

function Item_FollowPet:Prepare(mouse_button)
end

-- @param PreemptiveCallback: this callback function will be invoked directly in the equipitem api callback, the default handler is SKIPPED
function Item_FollowPet:FollowMe(PreemptiveCallback, EquipItemCallback)
	if(self.nid and self.nid ~= System.App.profiles.ProfileManager.GetNID()) then
		log("error: can't follow other OPC's pet in Item_FollowPet:FollowMe()\n");
		return;
	end
	if(self:IsTeenVersion())then
		NPL.load("(gl)script/apps/Aries/CombatPet/CombatPetConfig.lua");
		local CombatPetConfig = commonlib.gettable("MyCompany.Aries.CombatPet.CombatPetConfig");
		local pet_config = CombatPetConfig.GetInstance_Client();
		local row = pet_config:GetRow(self.gsid);
		if(row and row.req_magic_level and row.req_magic_level > 0)then
			local req_magic_level =  row.req_magic_level;
			local bean = Pet.GetBean();
			if(bean)then
				local mlel = bean.mlel or 0;
				if( mlel < req_magic_level)then
					local pet_name = self:GetName_client();
					local s = string.format("[%s]需要魔法星%d级才能召唤，先给你的魔法星补充能量再来召唤它吧！",pet_name or "",req_magic_level or 0);
					_guihelper.Custom_MessageBox(s,function(result)
						if(result == _guihelper.DialogResult.Yes)then
						else
							-- PurchaseEnergyStone.Show();
							local gsid=998;
							Map3DSystem.mcml_controls.pe_item.OnClickGSItem(gsid,true);	
						end
					end,_guihelper.MessageBoxButtons.YesNo,{yes = "Texture/Aries/Common/IKnow_32bits.png; 0 0 153 49", no = "Texture/Aries/Common/GotMagicStone_32bits.png; 0 0 153 49"});
					return;
				end
			end
		end
	else
		local provider = CombatPetHelper.GetClientProvider();
		if(provider)then
			local p = provider:GetPropertiesByID(self.gsid);
			if(p and p.req_magic_level > -1)then
				local req_magic_level = p.req_magic_level;
				local bean = Pet.GetBean();
				if(bean)then
					local energy = bean.energy or 0;
					local m = bean.m or 0;
					local mlel = bean.mlel or 0;
					if( (req_magic_level == 0 and m == 0 and mlel == 0) or mlel < req_magic_level)then
						local pet_name = self:GetName_client();

						local s;
						if(req_magic_level == 0) then
							s = string.format("[%s]需要激活魔法星才能召唤，先给你的魔法星补充能量再来召唤它吧！",pet_name or "");
						else
							s = string.format("[%s]需要魔法星%d级才能召唤，先给你的魔法星补充能量再来召唤它吧！",pet_name or "",req_magic_level or 0);
						end
						_guihelper.Custom_MessageBox(s,function(result)
							if(result == _guihelper.DialogResult.Yes)then
							else
								-- PurchaseEnergyStone.Show();
								local gsid=998;
								Map3DSystem.mcml_controls.pe_item.OnClickGSItem(gsid,true);	
							end
						end,_guihelper.MessageBoxButtons.YesNo,{yes = "Texture/Aries/Common/IKnow_32bits.png; 0 0 153 49", no = "Texture/Aries/Common/GotMagicStone_32bits.png; 0 0 153 49"});
						return;
					end
				end
			end
		end
	end
	if(self.bag ~= 0 and self.guid > 0) then
		Map3DSystem.Item.ItemManager.EquipItem(self.guid, function(msg) 
			if(PreemptiveCallback) then
				PreemptiveCallback(msg);
			else
				-- refresh the avatar, mount pet and follow pet
				Map3DSystem.Item.ItemManager.RefreshMyself();
				-- refresh all <pe:player>
				Map3DSystem.mcml_controls.GetClassByTagName("pe:player").RefreshContainingPageCtrls();

				if(EquipItemCallback) then
					EquipItemCallback(msg);
				end
			
				if(msg.issuccess == true) then
				end
				NPL.load("(gl)script/kids/3DMapSystemUI/HomeLand/HomeLandGateway.lua");
				if(Map3DSystem.App.HomeLand.HomeLandGateway.IsInMyHomeland()) then
					 -- refresh the pets in homeland
					MyCompany.Aries.Pet.RefreshMyPetsFromMemoryInHomeland();
				end
			end
		end);
	end
end

-- send the mount pet to homeland
function Item_FollowPet:GoHome()
	if(self.bag == 0 and self.position) then
		Map3DSystem.Item.ItemManager.UnEquipItem(self.position, function(msg) 
			NPL.load("(gl)script/kids/3DMapSystemUI/HomeLand/HomeLandGateway.lua");
			if(Map3DSystem.App.HomeLand.HomeLandGateway.IsInMyHomeland()) then
				 -- refresh the pets in homeland
				MyCompany.Aries.Pet.RefreshMyPetsFromMemoryInHomeland();
			end
					
			-- refresh the avatar, mount pet and follow pet
			Map3DSystem.Item.ItemManager.RefreshMyself();
			-- refresh all <pe:player>
			Map3DSystem.mcml_controls.GetClassByTagName("pe:player").RefreshContainingPageCtrls();
		end);
	end
end

-- get pet place status, 
-- return "home", "follow", "unknown"
function Item_FollowPet:WhereAmI()
	if(self.bag == 0) then
		return "follow"
	elseif(self.bag == 10010) then
		return "home";
	end
	return "unknown";
end

-- get pet name in homeland
-- return scene object name
function Item_FollowPet:GetSceneObjectNameInHomeland()
	if(self:WhereAmI() ~= "home") then
		log("error: followpet not at home. nid:"..(self.nid or "myself").." guid:"..self.guid.."\n")
		return;
	end
	if(self.nid == nil or self.nid == System.App.profiles.ProfileManager.GetNID()) then
		return "MyFollowPet:"..self.guid;
	else
		return self.nid.."FollowPet:"..self.guid;
	end
end

-- get scene object in homeland
-- the item could be my follow pet or other player follow pet
-- return scene object
function Item_FollowPet:GetSceneObjectInHomeland()
	local _pet = ParaScene.GetCharacter(self:GetSceneObjectNameInHomeland());
	if(_pet and _pet:IsValid() == true) then
		return _pet;
	end
end

-- create the scene object in homeland
function Item_FollowPet:CreateSceneObjectInHomeland()
	local ItemManager = Map3DSystem.Item.ItemManager;
	local name = self:GetSceneObjectNameInHomeland();
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid);
	local Pet = MyCompany.Aries.Pet;
	local player = Pet.GetUserCharacterObj();
	if(name and gsItem and player and player:IsValid() == true) then
		-- spawn position
		local x, y, z = player:GetPosition();
		-- 10 meter in front of the player's position
		x = x + 25 * math.cos(player:GetFacing());
		z = z - 25 * math.sin(player:GetFacing());
		-- for 0821_homeland use hard coded position
		x = 19960.26953125;
		z = 20306.703125;
		
		-- create pet in homeland scene
		local assetfile = gsItem.assetfile;
		local _pet = ParaScene.GetCharacter(name);
		if(_pet and _pet:IsValid() == true) then
		else
			local obj_params = {};
			obj_params.name = name;
			obj_params.x = x + math.random(-3, 3);
			obj_params.y = y;
			obj_params.z = z + math.random(-3, 3);
			obj_params.AssetFile = assetfile;
			obj_params.IsCharacter = true;
			-- skip saving to history for recording or undo.
			System.SendMessage_obj({
				type = System.msg.OBJ_CreateObject, 
				obj_params = obj_params, 
				SkipHistory = true,
				silentmode = true,
			});
			_pet = ParaScene.GetCharacter(name);
		end
		
		-- hide display name of the pet when selected
		_pet:SetDynamicField("name", "");

		-- NOTE: 2010/7/8: solve the problem that after saving homeland outdoor, the follow pets are disappear
		local _, p_y, __ = _pet:GetPosition();
		if(p_y < -9000) then
			_pet:SetPosition(_, p_y + 10000, __);
		end
	
		-- NOTE: special scaling for Aries project to scale the avatar to 1.6105, including avatars, dragons, follow pets, NPCs, GameObjects
		_pet:SetScale(Pet.GetFollowPetScaling());
		-- set physics
		_pet:SetPhysicsRadius(0.8); -- follow pet
		_pet:SetPhysicsHeight(1.8);
		
		-- NOTE by Andy 2009/6/18: Group special for Aries project
		local SentientGroupIDs = MyCompany.Aries.SentientGroupIDs;
		_pet:SetGroupID(SentientGroupIDs["FollowPet"]);
		_pet:SetSentientField(SentientGroupIDs["Player"], true);
		_pet:SetSentientField(SentientGroupIDs["OPC"], true);
		_pet:SetPerceptiveRadius(1000);
		_pet:SetAlwaysSentient(true);
		local att = _pet:GetAttributeObject();
		att:SetField("Sentient Radius", 1000);
		
		-- set the follow pet AI template in homeland
		local playerChar = _pet:ToCharacter();
		playerChar:Stop();
		local att = _pet:GetAttributeObject();
		--_pet:SnapToTerrainSurface(0);
		att:SetField("AlwaysSentient", true);
		att:SetField("Sentient", true);
		att:SetField("OnLoadScript", "");
		att:SetField("On_Perception", ";MyCompany.Aries.Pet.On_Perception();");
		att:SetField("FrameMoveInterval", 500); -- only every 0.5 seconds
		att:SetField("On_EnterSentientArea", "");
		att:SetField("On_LeaveSentientArea", "");
		
		-- apply the default idle AI template
		self:ApplyIdle_AITemplate();
		-- apply the ai template in memory
		local ai_inmemory = Item_FollowPet.pet_ai_mapping[tostring(self.nid or System.App.profiles.ProfileManager.GetNID())..":"..tostring(self.guid)];
		if(ai_inmemory == "follow") then
			self:ApplyFollow_AITemplate();
		end
		--att:SetField("On_FrameMove", [[;NPL.load("(gl)script/apps/Aries/Pet/AI/MountPet_Homeland.lua");_AI_templates.MountPet_HomelandAI.On_FrameMove();]]);
	end
end

-- follow pet and ai template name mapping
Item_FollowPet.pet_ai_mapping = {};

-- get ai template name
-- @return: "idle" | "follow"
function Item_FollowPet:GetAITemplateName()
	local name = Item_FollowPet.pet_ai_mapping[tostring(self.nid or System.App.profiles.ProfileManager.GetNID())..":"..tostring(self.guid)];
	return name or "idle";
end

-- apply idle ai template
function Item_FollowPet:ApplyIdle_AITemplate()
	Item_FollowPet.pet_ai_mapping[tostring(self.nid or System.App.profiles.ProfileManager.GetNID())..":"..tostring(self.guid)] = nil;
	local name = self:GetSceneObjectNameInHomeland();
	if(name) then
		local _pet = ParaScene.GetCharacter(name);
		if(_pet and _pet:IsValid() == true) then
			local att = _pet:GetAttributeObject();
			att:SetField("On_FrameMove", [[;_AI_templates.MountPet_HomelandAI.On_FrameMove_Idle();]]);
		end
	end
end

-- apply follow ai template
function Item_FollowPet:ApplyFollow_AITemplate()
	Item_FollowPet.pet_ai_mapping[tostring(self.nid or System.App.profiles.ProfileManager.GetNID())..":"..tostring(self.guid)] = "follow";
	local name = self:GetSceneObjectNameInHomeland();
	if(name) then
		local _pet = ParaScene.GetCharacter(name);
		if(_pet and _pet:IsValid() == true) then
			local att = _pet:GetAttributeObject();
			att:SetField("On_FrameMove", [[;_AI_templates.MountPet_HomelandAI.On_FrameMove_Follow();]]);
		end
	end
end

-- return the special ability button background of the given gsid
function Item_FollowPet.GetSpecialAbilityBtnBackground(gsid)
	if(gsid == 10112) then
		-- 10112_FollowPet_IronSnail
		return "Texture/Aries/Profile/DebugHouse_32bits.png;0 0 153 49";
	elseif(gsid == 10113) then
		-- 10113_FollowPet_Feifei
		return "Texture/Aries/Profile/RecycleHome_32bits.png;0 0 153 49";
	elseif(gsid == 10114) then
		-- 10114_FollowPet_Panda
		return "Texture/Aries/Profile/PandaCombing_32bits.png;0 0 153 49";
	elseif(gsid == 10115) then
		-- 10115_FollowPet_Squirrel
		return "Texture/Aries/Profile/WaterPlantsAll_32bits.png;0 0 153 49";
	elseif(gsid >= 10117 and gsid <= 10128) then
		-- zodiac animals
		return "Texture/Aries/Profile/ProducePill_32bits.png;0 0 153 49";
	elseif(gsid == 10131) then
		-- 10131_Ostrich
		return "Texture/Aries/Profile/ProducePill_32bits.png;0 0 153 49";
	elseif(gsid == 10129) then
		-- 10129_YuanXiaoBaby
		return "Texture/Aries/Profile/HarvestAllPlants_32bits.png;0 0 153 49";
	elseif(gsid == 10130) then
		return "Texture/Aries/Profile/DebugAllPlants_32bits.png;0 0 153 49";
	elseif(gsid == 10105) then
		return "Texture/Aries/Profile/DigSeeds_32bits.png;0 0 153 49";
	elseif(gsid == 10132) then
		return "Texture/Aries/Profile/MagicStuff_32bits.png;0 0 153 49";
	end
end
function Item_FollowPet.GetSpecialAbilityBtnString(gsid)
	if(gsid == 10112) then
		-- 10112_FollowPet_IronSnail
		return "吃泥巴";
	elseif(gsid == 10113) then
		-- 10113_FollowPet_Feifei
		return "拆迁";
	elseif(gsid == 10114) then
		-- 10114_FollowPet_Panda
		return "梳理毛发";
	elseif(gsid == 10115) then
		-- 10115_FollowPet_Squirrel
		return "浇水";
	elseif(gsid >= 10117 and gsid <= 10128) then
		-- zodiac animals
		return "生产药丸";
	elseif(gsid == 10131) then
		-- 10131_Ostrich
		return "生产药丸";
	elseif(gsid == 10129) then
		-- 10129_YuanXiaoBaby
		return "收割植物";
	elseif(gsid == 10130) then
		return "除虫";
	elseif(gsid == 10105) then
		return "寻找种子";
	elseif(gsid == 10132) then
		return "变材料";
	end
end
-- do special ability of the given follow pet item
function Item_FollowPet:DoSpecialAbility(gsid)
	if(self.gsid == 10112) then
		-- 10112_FollowPet_IronSnail
		-- NOTE for leio: do some thing if the item is an icon snail
		
		NPL.load("(gl)script/kids/3DMapSystemUI/HomeLand/HomeLandGateway.lua");
		NPL.load("(gl)script/kids/3DMapSystemApp/API/homeland/paraworld.homeland.home.lua");
		local homeinfo = Map3DSystem.App.HomeLand.HomeLandGateway.GetHomeInfo();
		if(homeinfo)then
			local pug = homeinfo.pugcnt;
			if(not pug or pug <=0)then
				_guihelper.MessageBox("你的家园很漂亮或很冷清，一点泥巴都没有，金刚蜗牛今天可以放假啦！");
				return;
			end
			
			local msg = {
				nid = Map3DSystem.User.nid,
			}
			commonlib.echo("before clear pug:");
			commonlib.echo(msg);
			paraworld.homeland.home.ClearPug(msg,"home",function(msg)	
				commonlib.echo("after clear pug:");
				commonlib.echo(msg);
				if(msg and msg.issuccess) then
					local clear_pug = 5
					if(pug < 5)then
						clear_pug = pug;
					end
					local s = string.format("金刚蜗牛成功吃掉了你们家%d点泥巴！",clear_pug);
					_guihelper.MessageBox(s);
					Map3DSystem.App.HomeLand.HomeLandGateway.ClearPug()
				elseif(msg and msg.errorcode == 428) then
					_guihelper.MessageBox("金刚蜗牛食量有限，每天只能吃1次泥巴，今天已经吃过了哦！");
				end
			end);
		end
	elseif(self.gsid == 10113) then
		-- 10113_FollowPet_Feifei
		local ItemManager = Map3DSystem.Item.ItemManager;
		local function RecycleHomeland()
			-- 50236_HasRecycledHomelandToday
			local gsObtain = ItemManager.GetGSObtainCntInTimeSpanInMemory(50236);
			if(gsObtain and (1 - gsObtain.inday) > 0) then
				_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">拆迁会把家园里所有的物品都放会仓库，植物要连根拔起哦，你确认要让飞飞帮你拆迁吗？</div>]], function(res)
					if(res and res == _guihelper.DialogResult.Yes) then
						log("============== paraworld.inventory.RecycleHomelandItems called ==============\n")
						paraworld.inventory.RecycleHomelandItems({}, "RecycleHomelandItems", function(msg)
							log("============== paraworld.inventory.RecycleHomelandItems returns ==============\n")
							commonlib.echo(msg);
							if(msg and msg.issuccess) then
								-- delay 1 second for memory cache valid
								UIAnimManager.PlayCustomAnimation(1000, function(elapsedTime)
									if(elapsedTime == 1000) then
										-- after recycle succeed, force the warehouse and homeland bag refreshed
										local warehouse_bags = {10001,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,};
										local bags = "";
										local i;
										for i = 1, #warehouse_bags do
											bags = bags..warehouse_bags[i]..",";
										end
										local msg = {
											bags = bags,
										};
										paraworld.inventory.GetItemsInBags(msg, "GetItemsInBags_AfterRecycle", function(msg) 
											if(not msg or msg.errorcode) then
												_guihelper.MessageBox([[<div style="margin-left:100px;margin-top:30px;">拆迁失败</div>]]);
												return;
											end
											-- refresh the bag in local server cache
											local i;
											for i = 1, #warehouse_bags do
												ItemManager.GetItemsInBag(warehouse_bags[i], "RefreshBag_AfterRecycle", function(msg)
												end, "access plus 1 minutes");
											end
											ItemManager.GetItemsInBag(10001, "RefreshBag_AfterRecycle", function(msg)
												-- after homeland bag refreshed
												-- TODO: refresh the homeland object
												Map3DSystem.App.HomeLand.HomeLandGateway.ClearVisualNodes();
											end, "access plus 1 minutes");
										end, nil, 10000, function() 
											_guihelper.MessageBox([[<div style="margin-left:100px;margin-top:30px;">拆迁失败</div>]]);
										end);
									end
								end);
								-- 50236_HasRecycledHomelandToday
								ItemManager.PurchaseItem(50236, 1, function(msg)
									if(msg) then
										log("+++++++Purchase item 50236_HasRecycledHomelandToday return: +++++++\n")
										commonlib.echo(msg);
									end
								end);
							end
						end);
					end	
				end, _guihelper.MessageBoxButtons.YesNo);
			else
				_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">拆迁需要好的力气的，飞飞今天都拆过一次了，明天再让它工作吧！</div>]]);
			end
		end
		
		-- check for homeland bag with non expired cache policy in case of recycle call outside my homeland
		Map3DSystem.Item.ItemManager.GetItemsInBag(10001, "Feifei_Check_Homeland", function(msg)
			local count = ItemManager.GetItemCountInBag(10001)
			if(count and count > 0) then
				RecycleHomeland();
			else
				_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">你家什么都没有，没啥可以拆哦，你的飞飞可清闲了！</div>]]);
			end
		end, "access plus 1 year");
	elseif(self.gsid == 10114) then
		-- 17042_Panda_Fur
		local ItemManager = Map3DSystem.Item.ItemManager;
		local gsObtain = ItemManager.GetGSObtainCntInTimeSpanInMemory(17042);
		if(gsObtain and gsObtain.inday > 0) then
			-- already obtain the panda fur today
			_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">熊猫的毛发今天已经梳理的油光滑亮了，明天再给它梳理吧！</div>]]);
		else
			-- comb the panda fur
			-- exid 196: Get_17042_Panda_Fur
			ItemManager.ExtendedCost(196, nil, nil, function(msg)end, function(msg)
				log("+++++++ExtendedCost 196: Get_17042_Panda_Fur return: +++++++\n")
				commonlib.echo(msg);
				if(msg.issuccess == true) then
					_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">熊猫的毛发梳理好啦，掉落了一个绒毛，快快收起来吧！</div>]]);
				elseif(msg.issuccess == false and msg.errorcode == 428) then
					_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">熊猫的毛发今天已经梳理的油光滑亮了，明天再给它梳理吧！</div>]]);
				end
			end);
		end
	elseif(self.gsid == 10115) then
		NPL.load("(gl)script/kids/3DMapSystemUI/HomeLand/HomeLandGateway.lua");
		local need_water,need_debug = Map3DSystem.App.HomeLand.HomeLandGateway.GetPlantsAllInfo();
		local len = 0;
		if(need_water)then
			len = #need_water;
		end
		if(len == 0)then
			_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">你们家没有需要浇水的植物哦，小松鼠可以放假啦！</div>]]);
			return;
		end
		if(len > 0)then
			--判断今天是否浇过水
			local ItemManager = Map3DSystem.Item.ItemManager;
			local hasGSItem = ItemManager.IfOwnGSItem;
			--50256_HasWaterAllPlantsToday
			local gsObtain = ItemManager.GetGSObtainCntInTimeSpanInMemory(50256);
			local hasItem,guid,bag,copies = hasGSItem(50256);
			if(gsObtain and gsObtain.inday > 0) then
				_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">小松鼠虽然很勤快，但也别让它太辛苦；今天它已经给所有旱渴植物浇过水了，明天再让它工作吧！</div>]]);
				return;
			end
			copies = copies or 0
			if(guid and copies == 1 and gsObtain and gsObtain.inday == 0)then
				--销毁昨天的心愿记录
				ItemManager.DestroyItem(guid,1,function(msg) end,function(msg)
					commonlib.echo("=====destroy 50256_HasWaterAllPlantsToday");
					commonlib.echo(msg);
				end)
			end
			Map3DSystem.App.HomeLand.HomeLandGateway.WaterAllPlants(function()
				
				ItemManager.PurchaseItem(50256, 1, function(msg) end, function(msg) 
					log("+++++++Purchase item #50247_WishLampTag return: +++++++\n")
					commonlib.echo(msg);
					if(msg and msg.issuccess)then
						_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">小松鼠好能干，一下子帮所有旱渴的植物都浇完水啦！</div>]]);
					end
				end)
			end);
		end
	elseif((self.gsid >= 10117 and self.gsid <= 10128) or self.gsid == 10131) then
		local ItemManager = Map3DSystem.Item.ItemManager;
		local pet_guid = self.guid;
		local petname = "";
		local pillname = "";
		local pill_gsid = nil;
		local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid);
		if(gsItem) then
			petname = gsItem.template.name;
			pill_gsid = tonumber(gsItem.template.stats[30]);
			local gsItem = ItemManager.GetGlobalStoreItemInMemory(pill_gsid);
			if(gsItem) then
				pillname = gsItem.template.name;
			end
		end
		local serverdate = MyCompany.Aries.Scene.GetServerDate() or ParaGlobal.GetDateFormat("yyyy-MM-dd");
		--clientdata
		local data = self:GetClientData();

		if(data and data.date == serverdate) then
			_guihelper.MessageBox(string.format([[<div style="margin-left:20px;margin-top:24px;">今天%s已经给过你药丸啦，不要太贪心哦！明天再来找它吧！</div>]], petname));
		else
			-- related pill gsid and purchase
			ItemManager.PurchaseItem(pill_gsid, 1, function(msg)
				if(msg) then
					log("+++++++Purchase item 50236_HasRecycledHomelandToday return: +++++++\n")
					commonlib.echo(msg);
					if(msg.issuccess == true) then
						_guihelper.MessageBox(string.format([[<div style="margin-left:20px;margin-top:24px;">%s生产出了一个%s，放在抱抱龙的背包里了哦！</div>]], petname, pillname));
						-- set the client data to mark the pill is successfully generated
						if(data)then
							data.date = serverdate;
						end
						self:SaveClientData(data);
					end
				end
			end);
		end
	elseif(self.gsid == 10129) then
		-- 10129_YuanXiaoBaby
		-- 收割植物
		NPL.load("(gl)script/kids/3DMapSystemUI/HomeLand/HomeLandGateway.lua");
		local need_water,need_debug,can_gain = Map3DSystem.App.HomeLand.HomeLandGateway.GetPlantsAllInfo();
		local len = 0;
		if(can_gain)then
			len = #can_gain;
		end
		if(len == 0)then
			_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">家里都没有要收割的植物，你赶紧多种点吧！</div>]]);
			return;
		end
		local canGetAllFruits = Map3DSystem.App.HomeLand.HomeLandGateway.CanGetAllFruits();
		if(not canGetAllFruits)then
			_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">你仓库里的果实已经装得太满了，先把仓库清理下再让元宵宝宝来收割吧！</div>]]);
			return;
		end
		if(len > 0)then
			--判断今天是否收割过
			local ItemManager = Map3DSystem.Item.ItemManager;
			local hasGSItem = ItemManager.IfOwnGSItem;
			--50256_HasWaterAllPlantsToday
			local gsObtain = ItemManager.GetGSObtainCntInTimeSpanInMemory(50278);
			local hasItem,guid,bag,copies = hasGSItem(50278);
			if(gsObtain and gsObtain.inday > 0) then
				_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">元宵宝宝今天已经帮你收割过一次了，剩下的明天再让它来弄吧，也别让它太累了！</div>]]);
				return;
			end
			copies = copies or 0
			if(guid and copies == 1 and gsObtain and gsObtain.inday == 0)then
				--销毁昨天的记录
				ItemManager.DestroyItem(guid,1,function(msg) end,function(msg)
					commonlib.echo("=====destroy 50278_HasHarvestAllPlantsToday");
					commonlib.echo(msg);
				end)
			end
			Map3DSystem.App.HomeLand.HomeLandGateway.GetAllFruits(function()
				ItemManager.PurchaseItem(50278, 1, function(msg) end, function(msg) 
					log("+++++++Purchase item #50278_HasHarvestAllPlantsToday return: +++++++\n")
					commonlib.echo(msg);
					if(msg and msg.issuccess)then
						_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">元宵宝宝帮你把所有的成熟的植物都收割好啦，都放在你背包里了哦！</div>]]);
						Map3DSystem.Item.ItemManager.GetItemsInBag(72, "plantevolved", function(msg) 
						end, "access plus 0 day");
					end
				end)
			end);
		end
	elseif(self.gsid == 10130) then
		NPL.load("(gl)script/kids/3DMapSystemUI/HomeLand/HomeLandGateway.lua");
		local need_water,need_debug = Map3DSystem.App.HomeLand.HomeLandGateway.GetPlantsAllInfo();
		local len = 0;
		if(need_debug)then
			len = #need_debug;
		end
		if(len == 0)then
			_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">你家园里没有需要除虫的植物哦，小燕子今天可以放假啦！</div>]]);
			return;
		end
		if(len > 0)then
			--判断今天是否已经除虫
			local ItemManager = Map3DSystem.Item.ItemManager;
			local hasGSItem = ItemManager.IfOwnGSItem;
			--50292_HasDebugAllPlantsToday
			local gsObtain = ItemManager.GetGSObtainCntInTimeSpanInMemory(50292);
			local hasItem,guid,bag,copies = hasGSItem(50292);
			if(gsObtain and gsObtain.inday > 0) then
				_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">小燕子虽然很勤快，但也别让它太辛苦；今天它已经给所有长虫植物除过虫了，明天再让它工作吧！</div>]]);
				return;
			end
			copies = copies or 0
			if(guid and copies == 1 and gsObtain and gsObtain.inday == 0)then
				--销毁昨天的心愿记录
				ItemManager.DestroyItem(guid,1,function(msg) end,function(msg)
					commonlib.echo("=====destroy 50292_HasDebugAllPlantsToday");
					commonlib.echo(msg);
				end)
			end
			Map3DSystem.App.HomeLand.HomeLandGateway.DebugAllPlants(function()
				
				ItemManager.PurchaseItem(50292, 1, function(msg) end, function(msg) 
					log("+++++++Purchase item #50292_HasDebugAllPlantsToday return: +++++++\n")
					commonlib.echo(msg);
					if(msg and msg.issuccess)then
						_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">小燕子好能干，一下子帮所有长虫的植物都除完虫啦！</div>]]);
					end
				end)
			end);
		end
	elseif(self.gsid == 10105) then
		--判断今天是否已经寻找过种子
		local ItemManager = Map3DSystem.Item.ItemManager;
		local hasGSItem = ItemManager.IfOwnGSItem;
		--50295_HasDiggedSeedToday
		local gsObtain = ItemManager.GetGSObtainCntInTimeSpanInMemory(50295);
		local hasItem,guid,bag,copies = hasGSItem(50295);
		if(gsObtain and gsObtain.inday > 0) then
			_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">你以为隐藏在大地下的种子是那么容易找到的吗？今天西瓜仔都已经找过了1次了，你可不能太贪心哦！</div>]]);
			return;
		end
		copies = copies or 0
		if(guid and copies == 1 and gsObtain and gsObtain.inday == 0)then
			--销毁昨天的心愿记录
			ItemManager.DestroyItem(guid,1,function(msg) end,function(msg)
				commonlib.echo("=====destroy 50295_HasDiggedSeedToday");
				commonlib.echo(msg);
			end)
		end
		
		function getSeed()
			local seed_map = {
				{label = "菠萝种子", gsid = 30009, num = 2, },
				{label = "樱桃种子", gsid = 30008, num = 2, },
				{label = "紫藤萝种子", gsid = 30011, num = 2, },
				{label = "竹子种子", gsid = 30010, num = 2, },
				
				{label = "康乃馨种子", gsid = 30117, num = 2, },
				{label = "蒲公英种子", gsid = 30126, num = 3, },
			}
			local n = math.random(100);
			local index = 1;
			if(n <= 10)then
				index = 1;
			elseif(n > 10 and n <= 20)then
				index = 2;
			elseif(n > 20 and n <= 30)then
				index = 3;
			elseif(n > 30 and n <= 40)then
				index = 4;
			elseif(n > 40 and n <= 65)then
				index = 5;
			elseif(n > 65)then
				index = 6;
			end
			return seed_map[index];
		end
		local seed_info = getSeed();
		if(seed_info)then
			local label = seed_info.label;
			local gsid = seed_info.gsid;
			local num = seed_info.num;
			local s = string.format([[<div style="margin-left:20px;margin-top:20px;">西瓜仔寻找种子的能力真是和它的脸皮一样厉害呢，它找回了%d个%s，快快收好吧！</div>]],num,label);
			_guihelper.MessageBox(s,function(res)
				if(res and res == _guihelper.DialogResult.OK) then
					-- pressed OK
					ItemManager.PurchaseItem(gsid, num, function(msg) end, function(msg) 
						log("+++++++Purchase item By WaterMelon Pet  return: +++++++\n")
						commonlib.echo(msg);
						if(msg and msg.issuccess)then
							ItemManager.PurchaseItem(50295, 1, function(msg) end, function(msg) 
								log("+++++++Purchase item #50295_HasDiggedSeedToday return: +++++++\n")
								commonlib.echo(msg);
								if(msg and msg.issuccess)then
								end
							end)
				
						end
					end)
				end
			end, _guihelper.MessageBoxButtons.OK);
		end
	elseif(self.gsid == 10132) then
		Map3DSystem.Item.Item_FollowPet_Skills.CrystalBunny_Action()
	end
end