--[[
Title: Item manager
Author(s): WangTian
Date: 2009/5/23
Desc: Each item has an id in the GlobalStore. 
	Item system allows all users to pick, carry, use, sell, buy, wear items. The big picture is a set of worlds which 
	consists of various items and the related application upon them. The original implementation includes models, characters, animations 
	and many others that can be either officially packed or user generated. Currently we only take portion of the original design 
	for Aries item system.
	Global Store holds information on every item that exists in ParaWorld. All items are created from their information stored in this table.
	It works like a template that all item entities are instances of the item template. 
	
saved web API calls on the following:
		paraworld.inventory.PurchaseItem
		paraworld.inventory.EquipItem
		paraworld.inventory.UnEquipItem
		paraworld.inventory.DestroyItem
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/ItemManager.lua");
local item = Map3DSystem.Item.ItemManager:FindItem(1)

Map3DSystem.Item.ItemManager:ItemManager:AddItem(item);
------------------------------------------------------------
]]
local LOG = LOG;
NPL.load("(gl)script/kids/3DMapSystemApp/profiles/ProfileManager.lua");
local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");
NPL.load("(gl)script/apps/Aries/Desktop/GameMemoryProtector.lua");
local GameMemoryProtector = commonlib.gettable("MyCompany.Aries.Desktop.GameMemoryProtector");

local Combat = commonlib.gettable("MyCompany.Aries.Combat");
local MsgHandler = commonlib.gettable("MyCompany.Aries.Combat.MsgHandler");

local Combat = commonlib.gettable("MyCompany.Aries.Combat");
local Pet = commonlib.gettable("MyCompany.Aries.Pet");
local ProfileManager = commonlib.gettable("Map3DSystem.App.profiles.ProfileManager");
ItemManager.items = {};

ItemManager.bags = {};

ItemManager.items_OPC = {};

ItemManager.bags_OPC = {};

-- pending check expire tag
local pending_checkexpire_tag = false;
local pending_checkexpire_guids = {};

-- whether it is kids version, set at initialization stage. 
local is_kids_version = true;

-- NOTE: teen version ONLY
-- some spell don't require combat school or secondary school match
local SchoolIrrelevant_GSIDs = {
	[22120] = true, -- 22120_Fire_FireGreatShield
	[22157] = true, -- 22157_Ice_IceGreatShield
	[22138] = true, -- 22138_Storm_StormGreatShield
	[22180] = true, -- 22180_Life_LifeGreatShield
	[22199] = true, -- 22199_Death_DeathGreatShield
	[22142] = true, -- 22142_Balance_GlobalShield
};

local GoldCardGSIDForKids = {
	[22367] = true,  --22367_Life_SingleAttack_Level4_gold
	[22368] = true,  --22368_Life_SingleAttack_Level2_gold
	[22369] = true,  --22369_Fire_SingleAttackWithDOT_Level3_gold
	[22370] = true,  --22370_Fire_SingleAttackWithImmolate_Level4_gold
	[22371] = true,  --22371_Death_SingleAttack_Level3_gold
	[22372] = true,  --22372_Death_SingleAttackWithLifeTap_Level4_gold
	[22373] = true,  --22373_Storm_SingleAttack_Level3_gold
	[22374] = true,  --22374_Storm_SingleAttack_Level4_gold
	[22375] = true,  --22375_Ice_AreaAttack_Level2_gold
	[22376] = true,  --22376_Ice_AreaAttack_Level4_gold
	[22399] = true,  --22399_Life_SingleAttack_Level3_gold
}

--local EventListener = {
	--["OnBagsUpdate"] = nil, -- OnBagsUpdate
	--["OnEquipsUpdate"] = nil, -- OnEquipsUpdate
	--["OnLinksUpdate"] = nil, -- OnLinksUpdate
--};
--ItemManager.EventListener = EventListener;

-- check the item version in local server
-- if the local server version is expired, notifiy the user to download or update to the latest
-- NOTE: this is for item_template items only, UGC assets and Executable apps or appcommands can be obtained from API calls
function ItemManager.ValidateGlobalStoreVersion()
	-- TODO:
end

-- one time init the item manager 
-- @param app: the inventory application object, or Map3DSystem.App.Inventory.app
function ItemManager.Init(app)
	-- is_kids_version = System.options.version == "kids";
end

-- one time init the item manager 
-- @param app: the inventory application object, or Map3DSystem.App.Inventory.app
function ItemManager.OnUpdateCheckExpireTimer()
	if(pending_checkexpire_tag == true) then
		pending_checkexpire_tag = false;
		log("info: detected expired items\n");
		if(next(pending_checkexpire_guids) ~= nil) then
			ItemManager.CheckExpire(pending_checkexpire_guids, function(msg)
				log("info: ItemManager.CheckExpire returns\n");
				commonlib.echo(msg);
			end)
		end
		--System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="CheckExpire"});
	end
end


---------------------------------
-- global store functions
---------------------------------

ItemManager.GlobalStoreTemplates = {};

local GetAlternateModelFromID;
local CCS_DB = commonlib.gettable("Map3DSystem.UI.CCS.DB");
if(CCS_DB.GetAlternateModelFromID) then
	GetAlternateModelFromID = CCS_DB.GetAlternateModelFromID;
end

-- get the event dispatcher
function ItemManager.GetEvents()
	if(ItemManager.events) then
		return ItemManager.events;
	else
		NPL.load("(gl)script/ide/EventDispatcher.lua");
		ItemManager.events = commonlib.EventSystem:new();
		return ItemManager.events;
	end
end

function ItemManager.RedirectAllGlobalStoreIconPath()
	if(GetAlternateModelFromID) then
		local gsid, gsTemplate;
		for gsid, gsTemplate in pairs(ItemManager.GlobalStoreTemplates) do
			if(gsid <= 8999) then
				local key = gsTemplate.assetkey;

				local alternate_model = GetAlternateModelFromID(gsid + 30000);
				if(alternate_model) then
					local id = alternate_model.id;
					key = alternate_model.name or "";
					if(id and key) then
						key = string.gsub(key, tostring(id), tostring(id - 30000));
					end
					--local gsItem = ItemManager.GetGlobalStoreItemInMemory(alternate_model - 30000);
					--if(gsItem) then
						--key = gsItem.assetkey;
						----gsTemplate.icon = gsItem.icon;
						----gsTemplate.icon_female = gsItem.icon_female;
					--end
				end
				
				local class = gsTemplate.template.class;
				local subclass = gsTemplate.template.subclass;

				-- model female
				-- 187 is_unisex_teen(C) 装备区分男女 不区分男女写1 
				if(class == 1 and (subclass == 2 or subclass == 5 or subclass == 7 or subclass == 8 or subclass == 10 or subclass == 11 or subclass == 18 or subclass == 19 or subclass == 70 or subclass == 71 or subclass == 72)) then
					-- check if icon exist
					local base_dir = "character/v6/Item/Head/";
					local base_dir = "character/v6/Item/Weapon/";
					local base_dir = "character/v6/Item/ShirtTexture/";
					local base_dir = "character/v6/Item/FootTexture/";
					local base_dir = "character/v6/Item/WingTexture/";
					local base_dir = "character/v6/Item/Back/";
							
					local female_asset;
					-- default unisex
					gsTemplate.template.stats[187] = 1;
					if(subclass == 2) then --  head
						female_asset = "character/v6/Item/Head/4"..key..".anim.x";
					elseif(subclass == 18) then --  fashion head
						female_asset = "character/v6/Item/Head/4"..key..".anim.x";
					elseif(subclass == 5) then --  shirt
						female_asset = "character/v6/Item/ShirtTexture/4"..key.."_CS.dds";
					elseif(subclass == 19) then --  fashion shirt
						female_asset = "character/v6/Item/ShirtTexture/4"..key.."_CS.dds";
					elseif(subclass == 7) then --  boots
						female_asset = "character/v6/Item/FootTexture/4"..key.."_CF.dds";
					elseif(subclass == 71) then --  fashion boots
						female_asset = "character/v6/Item/FootTexture/4"..key.."_CF.dds";
					elseif(subclass == 8) then --  back
						female_asset = "character/v6/Item/WingTexture/4"..key.."_CW.dds";
					elseif(subclass == 70) then --  fashion back
						female_asset = "character/v6/Item/Back/4"..key..".anim.x";
					elseif(subclass == 10) then --  left hand
						female_asset = "character/v6/Item/Weapon/4"..key..".anim.x";
					elseif(subclass == 11) then --  right hand
						female_asset = "character/v6/Item/Weapon/4"..key..".anim.x";
					elseif(subclass == 72) then --  right hand fashion
						female_asset = "character/v6/Item/Weapon/4"..key..".anim.x";
					end

					if(gsid == 1546) then
						log("11111cccc\n")
						commonlib.echo(key)
						commonlib.echo(female_asset)
						commonlib.echo(ParaIO.DoesAssetFileExist(female_asset))
					end

					if(female_asset and ParaIO.DoesAssetFileExist(female_asset)) then
						gsTemplate.template.stats[187] = 0;
					end
				end
			end
		end
	end
end

-- sync global store without calling ItemManager.GetGlobalStoreItem, such as from Paracraft modules. 
function ItemManager.SyncGlobalStore()
	if(not next(ItemManager.GlobalStoreTemplates)) then
		NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.globalstore.lua");
		local globalstoreitems = paraworld.globalstore.read_from_cache("*");
		if(globalstoreitems) then
			for _, item in pairs(globalstoreitems) do
				ItemManager.SyncGlobalStoreItem(item)
			end
			return true;
		end
	end
end

function ItemManager.SyncGlobalStoreItem(globalstoreitem)
	-- NOTE 2012/11/29: if this table is not deepcopy, the modified template will be written into localserver
	local gsTemplate = commonlib.deepcopy(globalstoreitem);
	gsTemplate.template.stats = {};
	local i;
	for i = 1, 10 do
		local type = gsTemplate.template["stat_type_"..i]
		if(type ~= 0) then
			gsTemplate.template.stats[type] = gsTemplate.template["stat_value_"..i];
		end
	end

	-- parse stats in description
	local json_str, desc = string.match(gsTemplate.template.description, "^(%[[^%[]*%])(.*)$");

	if(desc) then
		gsTemplate.template.description = desc;
	end
	if(json_str) then
		gsTemplate.template.description = desc or "";
		local description_stats = {};
		NPL.FromJson(json_str, description_stats);
		local _, _pair;
		for _, _pair in pairs(description_stats) do
			gsTemplate.template.stats[_pair.k] = _pair.v;
		end
	end
				
	-- parse default material
	if(gsTemplate.template.material == 0) then
		local class = gsTemplate.template.class;
		local subclass = gsTemplate.template.subclass;

		if(class == 1 and subclass <= 9) then
			gsTemplate.template.material = 7;
		elseif(class == 1 and (subclass == 10 or subclass == 11)) then
			gsTemplate.template.material = 8;
		elseif(class == 1 and (subclass >= 15 and subclass <= 17)) then
			gsTemplate.template.material = 4;
		elseif(class == 1 and (subclass == 18 or subclass == 19 or subclass == 70 or subclass == 71)) then
			gsTemplate.template.material = 7;
		elseif(class == 2 and (subclass == 2)) then
			gsTemplate.template.material = 3;
		elseif(class == 3 and (subclass == 6 or subclass == 8)) then
			gsTemplate.template.material = 5;
		elseif(class == 3 and (subclass == 7)) then
			gsTemplate.template.material = 10;
		elseif(class == 4) then
			gsTemplate.template.material = 10;
		elseif(class == 8 or class == 9) then
			gsTemplate.template.material = 9;
		elseif(class == 18) then
			gsTemplate.template.material = 10;
		elseif(class == 19) then
			gsTemplate.template.material = 9;
		elseif(class == 20) then
			gsTemplate.template.material = 10;
		end
	end

	-- for teen version apparel: parse the unisex model and icon
	if(System.options.version == "teen") then
		local class = gsTemplate.template.class;
		local subclass = gsTemplate.template.subclass;
		if(class == 1) then
			-- icon female
			local key = gsTemplate.assetkey;

			-- NOTE: use explicit icon as the icon path and set female icon if exists
			local base_dir = gsTemplate.icon;
			local icon_female = string.gsub(base_dir, ".png", "_F.png");
			if(ParaIO.DoesAssetFileExist(icon_female)) then
				gsTemplate.icon_female = icon_female;
			end

			-- NOTE: original implementation check the characters.db item_id reference
			--		 which non-visual items didn't keep a visual item_id
			---- check if icon exist
			--local base_dir = "Texture/Aries/Item_Teen/";
			--local icon_female = base_dir..key.."_F.png";
			--gsTemplate.icon = base_dir..key..".png";
			--if(ParaIO.DoesFileExist(icon_female)) then
				--gsTemplate.icon_female = icon_female;
			--end

			---- redirect alternate icon if characters.db item_id reference is available
			--local alternate_model = GetAlternateModelFromID(gsTemplate.gsid + 30000);
			--if(alternate_model) then
				--local gsItem = ItemManager.GetGlobalStoreItemInMemory(alternate_model - 30000);
				--if(gsItem) then
					--gsTemplate.icon = gsItem.icon;
					--gsTemplate.icon_female = gsItem.icon_female;
				--end
			--end

			-- 221 apparel_quality(CG) 装备的品质 -1未知 0白 1绿 2蓝 3紫 
			if(not gsTemplate.template.stats[221]) then
				-- default unknown
				gsTemplate.template.stats[221] = -1;
			end
		end
	end

	if(gsTemplate.template.class == 18) then
		if(System.options.version == "teen") then
			NPL.load("(gl)script/apps/Aries/Combat/ServerObject/card_server.lua");
			local Card = commonlib.gettable("MyCompany.Aries.Combat_Server.Card");
			local gsid, cardkey = string.match(gsTemplate.assetkey, "^(%d-)_(.+)$");
			if(gsid and cardkey) then
				gsid = tonumber(gsid);
				if(gsTemplate.gsid == gsid) then
					MsgHandler.InitCardTemplateIfNot();
					local cardTemplate = Card.GetCardTemplate(cardkey);
					if(cardTemplate and cardTemplate.params) then
						-- 134 pipcost_card_or_qualification(C) 卡片或卷轴消耗的pips
						if(cardTemplate.pipcost) then
							gsTemplate.template.stats[134] = cardTemplate.pipcost;
							if(cardTemplate.pipcost == -14) then
								gsTemplate.template.stats[134] = 114;
							end
						end
						-- 135 accuracy_card_or_qualification(C) 卡片或卷轴的命中率 儿童版的百分比发招成功率 仅供卡片提示显示用
						if(cardTemplate.accuracy) then
							gsTemplate.template.stats[135] = cardTemplate.accuracy;
							if(System.options.version == "teen") then
								gsTemplate.template.stats[135] = 100;
							end
						end
						-- 136 school_card_or_qualification(C) 卡片或卷轴的属性 6火 7冰 8风暴 9神秘 10生命 11死亡 12平衡
						-- 137 school_requirement(CG) 物品穿着必须系别 1金 2木 3水 4火 5土 6火 7冰 8风暴 9神秘 10生命 11死亡 12平衡 
						if(cardTemplate.spell_school) then
							local spell_school = cardTemplate.spell_school;
							spell_school = string.lower(spell_school);
							if(spell_school == "fire") then
								gsTemplate.template.stats[136] = 6;
							elseif(spell_school == "ice") then
								gsTemplate.template.stats[136] = 7;
							elseif(spell_school == "storm") then
								gsTemplate.template.stats[136] = 8;
							elseif(spell_school == "myth") then
								gsTemplate.template.stats[136] = 9;
							elseif(spell_school == "life") then
								gsTemplate.template.stats[136] = 10;
							elseif(spell_school == "death") then
								gsTemplate.template.stats[136] = 11;
							elseif(spell_school == "balance") then
								gsTemplate.template.stats[136] = 12;
							end
							-- NOTE 2012/1/9: globalstore item with 137 for aution house school filtering
							--				  close this stat on local globalstoreitem
							gsTemplate.template.stats[137] = nil;
						end
						-- 138 combatlevel_requirement(CG) 
						if(cardTemplate.require_level) then
							gsTemplate.template.stats[138] = cardTemplate.require_level;
						else
							gsTemplate.template.stats[138] = nil;
						end
						-- 249 card_can_learn(CG) 用户可以靠系别或者辅修得到的技能 主要是白卡 以及配置是在xml文件中 (青年版) 
						local quality = gsTemplate.template.stats[221];
						if(cardTemplate.can_learn == true and (not quality or quality == 0)) then
							-- 221 apparel_quality(CG) 装备的品质 -1未知 0白 1绿 2蓝 3紫 4橙 
							gsTemplate.template.stats[249] = 1;
						else
							gsTemplate.template.stats[249] = nil;
						end
						-- 186 cooldown_rounds(CG) 卡片技能的cooldown轮数 
						if(cardTemplate.params.cooldown) then
							gsTemplate.template.stats[186] = cardTemplate.params.cooldown;
						end
						if(cardTemplate.params.description) then
							local description = cardTemplate.params.description;
							local fields = {};
							local stat_name;
							for stat_name in string.gmatch(description, "{([^{^}]+)}") do
								if(cardTemplate.params[stat_name]) then
									fields["{"..stat_name.."}"] = tostring(cardTemplate.params[stat_name]);
								else
									fields["{"..stat_name.."}"] = "";
								end
							end
							description = string.gsub(description, "({[^{^}]+})", fields);
							gsTemplate.template.description = description;
						end
						gsTemplate.template.stats[58] = 1;
					end
				end
			end
		end
	end
				
	------ NOTE 2012/11/29: replace all "#" at hosting code, otherwise the localserver version is modified
	---- NOTE 2012/11/18: replace all "#" sign with newline
	--gsTemplate.template.description = string.gsub(gsTemplate.template.description, "#", "<br/>");
				
				
	gsTemplate.template.description = string.gsub(gsTemplate.template.description, "#", "\n");
				

	--NOTE 2012/11/23: CreateGemHole is deprecated in teen version

	--if(System.options.version == "teen") then
		---- 67 Item_CanCreateGemHole_Count(CS) 装备可开槽的数量 只能从0变为一个数值 不能改 (青年版) 当有填写stat36的时候 stat67是1  
		---- 68 Cost_CraftSlotCharm_Count(CS) 装备镶嵌宝石消耗打孔石的数量 只能从0变为一个数值 不能改 (青年版) 当有填写stat36的时候 stat68是1  
		--if(gsTemplate.template.stats[36]) then
			--if(not gsTemplate.template.stats[67]) then
				--gsTemplate.template.stats[67] = 1;
			--end
			--if(not gsTemplate.template.stats[68]) then
				--gsTemplate.template.stats[68] = 1;
			--end
		--end
	--end

	--local skip_check_keys = {
		--["未使用"] = true,
		--["废弃"] = true,
		--["废除"] = true,
		--["未开放"] = true,
	--};
				
	local isdeprecated = false;
	--local skip_key, _;
	--for skip_key, _ in pairs(skip_check_keys) do
		--if(string.find(gsTemplate.template.name, skip_key)) then
			--isdeprecated = true;
			--break;
		--end
	--end

	if(not isdeprecated) then
		-- record in memory for ItemManager.GetGlobalStoreItemInMemory(gsid)
		ItemManager.GlobalStoreTemplates[gsTemplate.gsid] = gsTemplate; -- LXZ: why use deep copy? commonlib.deepcopy(gsTemplate)
	end

	--[[
	gsTemplate.assetfile = string.lower(gsTemplate.assetfile);
	local ext = string.match(gsTemplate.assetfile, "%.(%w+)$");
	if(ParaIO.DoesFileExist(gsTemplate.assetfile, false) == true) then
		if(ext == "zip") then
			-- TODO: check the inner zip file existency
		end
	else
		if(ext == nil) then
			--log("warning: no file extension for global store item:"..tostring(gsTemplate.gsid).." with assetfile:"..tostring(gsTemplate.assetfile).."\n")
			-- TODO: download the file anyway
			-- TODO: or specify the files with the asset file name
		elseif(ext == "zip") then
			-- TODO: directly download the file, and extract the files to specific folder
		else
			-- TODO: directly download the file
		end
	end
	if(string.match(gsTemplate.descfile, "{.+}")) then
		-- TODO: assetfile is a data content
	elseif(string.match(gsTemplate.descfile, "http://.+")) then
		-- TODO: assetfile is a data content
	end
	]]
end
		

-- Get global store item templates
-- @param gsids: commer-separated global store ids, a maximum of 10 gsids in one call
-- @param queueName: request queue name. it can be nil. 
-- @param callbackFunc: the callback function(msg) end
-- @param cache_policy: nil or string or a cache policy object, such as "access plus 1 day", System.localserver.CachePolicies["never"]
function ItemManager.GetGlobalStoreItem(gsids, queuename, callbackFunc, cache_policy, timeout, timeout_callback)
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy)
	end
	local msg = {
		gsids = gsids,
		cache_policy = cache_policy,
	}
	-- local fromTime = ParaGlobal.timeGetTime();
	-- LOG.std(nil, "info", "GetGlobalStoreItem", {"begin sync", gsids})
	paraworld.globalstore.read(msg, queuename or "GetGlobalStoreItem_"..tostring(gsids), function(msg)
		if(msg and msg.globalstoreitems and msg.globalstoreitems[1]) then
			-- log(string.format("%d globalstoreitems read. dt: %d\n", #(msg.globalstoreitems), ParaGlobal.timeGetTime() - fromTime));
			for i = 1, #(msg.globalstoreitems) do
				ItemManager.SyncGlobalStoreItem(msg.globalstoreitems[i])
			end
		end
		callbackFunc(msg);
		-- LOG.std(nil, "info", "GetGlobalStoreItem", "end sync. dt: %d", ParaGlobal.timeGetTime() - fromTime)
	end, nil, timeout, timeout_callback);
end

-- Get global store item templates
-- @param gsids: global store id
-- @return: item template, nil if not found in memory
function ItemManager.GetGlobalStoreItemInMemory(gsid)
	return ItemManager.GlobalStoreTemplates[gsid];
end

-- get the asset file from the global store id and index, the asset file is contained in the global store item descfile
--@param gsid: global store id
--@param index: index into the descfile asset area
--@return: asset file name or nil if not found
function ItemManager.GetAssetFileFromGSIDAndIndex(gsid, index)
	--commonlib.echo("Hi leio, i manually assign the asset file in here, i will put them in the global store");
	if(gsid == 10001) then
		if(is_kids_version) then
			if(index == 1) then
				--return "character/v3/PurpleDragonEgg/PurpleDragonEgg.xml";
				return "character/v3/PurpleDragonMinor/PurpleDragonMinor.xml";
			elseif(index == 2) then
				return "character/v3/PurpleDragonMinor/PurpleDragonMinor.xml";
			elseif(index == 3) then
				return "character/v3/PurpleDragonMajor/Female/PurpleDragonMajorFemale.xml";
			end
		else
			-- the default asset file for mount pet
			--return "character/v6/02animals/MagicBesom/MagicBesom.x";
			return "character/common/teen_default_combat_pose_mount/teen_default_combat_pose_mount.x";
		end
	end
end

-- create item in global store
-- @param id: global store id
-- @param template: item data, including global store data and template data
function ItemManager.CreateGlobalStoreItem(id, template)
	-- TODO: invoke global store APIs
	-- TODO: update local data if succeed
end

-- read item in global store
-- @param id: global store id
function ItemManager.ReadGlobalStoreItem(id)
	-- TODO: invoke global store APIs
	-- TODO: update local data if needed
end

-- update item in global store
-- @param id: global store id
-- @param template: the updated item data, including global store data and template data
function ItemManager.UpdateGlobalStoreItem(id, template)
	-- TODO: invoke global store APIs
	-- TODO: update local data if succeed
end

-- delete item from global store
-- @param id: global store id
function ItemManager.DeleteGlobalStoreItem(id)
	-- TODO: invoke global store APIs
	-- TODO: update local data if succeed
end

ItemManager.GlobalStoreObtainCounts = {};

-- NOTE: usually this funcion is called during the user login process to sync all global store item daily and weekly obtain count in memory
--		all data is kept in memory and don't need local server cache, so the cache policy is always access plus 1 year
--		dialy and weekly count is stored and increased in memory during the current game process
--		
-- Get all global store item obtain count in time span
-- @param callbackFunc: the callback function(msg) end
-- @param cache_policy: nil or always "access plus 0 day"
-- @param timeout: timeout in milliseconds
-- @param timeout_callback: callback function called when request timeout
function ItemManager.GetAllGSObtainCntInTimeSpan(callbackFunc, cache_policy, timeout, timeout_callback)
	-- reset the obtain counts
	ItemManager.GlobalStoreObtainCounts = {};
	
	local gsids_need_fetch = {};
	local id, gsItem;
	for id, gsItem in pairs(ItemManager.GlobalStoreTemplates) do
		if(gsItem.maxdailycount ~= 0 or gsItem.maxweeklycount ~= 0) then
			table.insert(gsids_need_fetch, id);
		end
	end
	
	local msg_gsids_input = "";
	local _, g;
	for _, g in ipairs(gsids_need_fetch) do
		msg_gsids_input = msg_gsids_input..g..",";
	end
	
	local input_msg = {
		nid = Map3DSystem.App.profiles.ProfileManager.GetNID(),
		gsids = msg_gsids_input,
	}
	paraworld.globalstore.GetGSObtainCntInTimeSpans(input_msg, nil, function(msg)
		if(msg and msg.list and not msg.errorcode) then
			local _, gsobtain;
			for _, gsobtain in ipairs(msg.list) do
				if(gsobtain and gsobtain.gsid and gsobtain.inday and gsobtain.inweek) then
					ItemManager.GlobalStoreObtainCounts[gsobtain.gsid] = {
						inday = gsobtain.inday,
						inweek = gsobtain.inweek,
					};
				end
			end
			callbackFunc(true);
		else
			callbackFunc(false);
		end
	end, "access plus 0 day", timeout, timeout_callback);
	
	do return end
	
	---------------- deprecated one time GetGSObtainCntInTimeSpan ----------------
	
	local isSucceeds = {};
	local i, gsid;
	for i, gsid in ipairs(gsids_need_fetch) do
		isSucceeds[gsid] = false;
	end
	local bHasFailed = false;
	
	-- get obtain count in sequence
	local nGSIDIndex = 1;
	local function GetGSObtainCntInTimeSpan(index)
		local gsid = gsids_need_fetch[index];
		if(not gsid) then 
			commonlib.applog("warning: no gsid at index %d", index)
			return
		end
		
		local input_msg = {
			nid = Map3DSystem.App.profiles.ProfileManager.GetNID(),
			gsid = gsid,
		}
		paraworld.globalstore.GetGSObtainCntInTimeSpan(input_msg, "GetGSObtainCntInTimeSpan_"..tostring(gsid), function(msg)
			--- NOTE:
			-- callbackFunc(true) only if all obtain times are retrieved successfully
			-- callbackFunc(false) if any gsid time is failed to retrieve
			if(msg and msg.inday and msg.inweek) then
				isSucceeds[gsid] = true;
				ItemManager.GlobalStoreObtainCounts[gsid] = msg;
			else
				if(bHasFailed == false) then
					callbackFunc(false);
				end
				bHasFailed = true;
			end
			if(bHasFailed == false) then
				LOG.std("", "system","Item", "GetGSObtainCntInTimeSpan of gsid %s succeed", gsid);
				local k, v;
				local bAllSucceed = true;
				for k, v in pairs(isSucceeds) do
					if(v == false) then
						bAllSucceed = false;
						break;
					end
				end
				if(bAllSucceed == true) then
					commonlib.echo(ItemManager.GlobalStoreObtainCounts);
					callbackFunc(true);
				else
					nGSIDIndex = nGSIDIndex + 1;
					GetGSObtainCntInTimeSpan(nGSIDIndex);
				end
			end
		end, "access plus 0 day", timeout, timeout_callback);
	end
	GetGSObtainCntInTimeSpan(nGSIDIndex);
	
	---------------- deprecated one time GetGSObtainCntInTimeSpan ----------------
end

-- Get global store obtain count
-- @param gsids: global store id
-- @return: { inday=..., inweek=... }, nil if not found in memory
function ItemManager.GetGSObtainCntInTimeSpanInMemory(gsid)
	return ItemManager.GlobalStoreObtainCounts[gsid];
end

-- increase the obtain count in memory
-- @param gsid: global store id
-- @param count: obtain count, default 1
function ItemManager.IncreaseGSObtainCntInTimeSpanInMemory(gsid, count)
	local gsObtain = ItemManager.GlobalStoreObtainCounts[gsid];
	if(gsObtain) then
		gsObtain.inday = gsObtain.inday + (count or 1);
		gsObtain.inweek = gsObtain.inweek + (count or 1);
	end
end

---------------------------------
-- extended cost functions
---------------------------------

ItemManager.ExtendedCostTemplates = {};

local transform_mapping_pill_to_marker = {};
local transform_mapping_marker_to_pill = {};

-- Get extended cost template
-- @param exid: extended cost id
-- @param queueName: request queue name. it can be nil. 
-- @param callbackFunc: the callback function(msg) end
-- @param cache_policy: nil or string or a cache policy object, such as "access plus 1 day", System.localserver.CachePolicies["never"]
function ItemManager.GetExtendedCostTemplate(exid, queuename, callbackFunc, cache_policy, timeout, timeout_callback)
	-- tricky: only set when user has logged in
	is_kids_version = System.options.version == "kids";

	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy)
	end
	local msg = {
		exid = exid,
		cache_policy = cache_policy,
	}
	-- queuename or "GetExtendedCostTemplate_"..exid
	paraworld.inventory.GetExtendedCost(msg, queuename or "GetExtendedCostTemplate", function(msg)
		if(msg and not msg.errorcode) then
			-- calculate the extended cost template tos from the optiontos
			msg.tos = msg.tos or {};

			-- NOTE: we only count the items or stats from the items that:
				-- 1. only one branch is included in optiontos
				-- 2. only items that obtains with 100% probability
			if(msg.otos and msg.otos ~= "") then
				local single_branch = string.match(msg.otos, "^%[([^%[%]|].+)%]$")
				if(single_branch) then
					-- only one branch is included in optiontos
					local gsid, cnt, p;
					for gsid, cnt, p in string.gmatch(single_branch, "{\"gsid\":(%d+),\"cnt\":(%d+),\"p\":(%d+)}") do
						gsid = tonumber(gsid);
						cnt = tonumber(cnt);
						p = tonumber(p);
						-- only items that obtains with 100% probability
						if(p == 1000) then
							table.insert(msg.tos, {key = gsid, value = cnt})
						end
					end
				end
			end

			-- check Item_PetTransform transform target gsid
			local from_count = 0;
			local to_count = 0;
			local transform_pill_gsid;
			local transform_target_gsid;
			local i, from;
			for i, from in ipairs(msg.froms) do
				if(from.value == 1) then
					local gsItem = ItemManager.GetGlobalStoreItemInMemory(from.key);
					if(gsItem) then
						if(gsItem.template.class == 2 and gsItem.template.subclass == 6) then
							transform_pill_gsid = from.key;
						end
					end
				end
				from_count = from_count + 1;
			end
			if(transform_pill_gsid and from_count == 1) then
				-- if single transform pill in from
				local i, to;
				for i, to in ipairs(msg.tos) do
					if(to.value == 1) then
						local gsItem = ItemManager.GetGlobalStoreItemInMemory(to.key);
						if(gsItem) then
							-- 33 Transformation Marker
							if(gsItem.template.inventorytype == 33) then
								transform_target_gsid = to.key;
							end
						end
					end
					to_count = to_count + 1;
				end
				if(transform_pill_gsid and transform_target_gsid and from_count == 1 and to_count == 1) then
					transform_mapping_pill_to_marker[transform_pill_gsid] = transform_target_gsid;
					transform_mapping_marker_to_pill[transform_target_gsid] = transform_pill_gsid;

					-- reset the marker to pill icon and name
					local gsItem_pill = ItemManager.GetGlobalStoreItemInMemory(transform_pill_gsid);
					local gsItem_marker = ItemManager.GetGlobalStoreItemInMemory(transform_target_gsid);
					if(gsItem_pill and gsItem_marker) then
						gsItem_marker.icon = gsItem_pill.icon;
						gsItem_marker.template.name = gsItem_pill.template.name;
					end
				end
			end

			ItemManager.ExtendedCostTemplates[exid] = commonlib.deepcopy(msg);
		end
		callbackFunc(msg);
	end, nil, timeout, timeout_callback);
end

-- Get extended cost templates in memory
-- @param exid: extended cost id
-- @return: extended cost template, nil if not found in memory
function ItemManager.GetExtendedCostTemplateInMemory(exid)
	return ItemManager.ExtendedCostTemplates[exid];
end

-- 将 ExtendedCost 的 tos 转换为 table 返回，如果 tos 有多个兑换，返回的table 为多重table
-- @param exid: extended cost id
-- @return: 
function ItemManager.GetExtendedCostTemplateOtosInMemory(exid)	
	local _t={}
	if (ItemManager.ExtendedCostTemplates[exid]) then
		local otos = ItemManager.ExtendedCostTemplates[exid].otos
		local _pos = string.find(otos,"|")
		if (_pos) then			
			local _arr_otos = commonlib.split(otos,"|")
			for _k, _tos in ipairs(_arr_otos) do
				local gsid, cnt, p;
				local _r={}
				for gsid, cnt, p in string.gmatch(_tos, "{\"gsid\":(%d+),\"cnt\":(%d+),\"p\":(%d+)}") do
					gsid = tonumber(gsid);
					cnt = tonumber(cnt);
					p = tonumber(p);
					if(p == 1000) then
						table.insert(_r, {key = gsid, value = cnt})
					end
				end
				table.insert(_t,_r)
			end
		else
			local single_branch = string.match(otos, "^%[([^%[%]|].+)%]$")
			local gsid, cnt, p;
			for gsid, cnt, p in string.gmatch(single_branch, "{\"gsid\":(%d+),\"cnt\":(%d+),\"p\":(%d+)}") do
				gsid = tonumber(gsid);
				cnt = tonumber(cnt);
				p = tonumber(p);
				-- only items that obtains with 100% probability
				if(p == 1000) then
					table.insert(_t, {key = gsid, value = cnt})
				end
			end
		end
	end
	return _t;
end

-- this function is useful for extracting information from extended cost template. 
-- @param exid: extended cost id
-- @param gsid: gsid in froms. if nil, it matches anything. 
-- @return the items count of gsid in froms
function ItemManager.GetExtendedCostTemplateFromItemCount(exid, gsid)
	local exTemplate = ItemManager.GetExtendedCostTemplateInMemory(exid);
	if(exTemplate) then
		local i, from;
		for i, from in ipairs(exTemplate.froms) do
			if(not gsid or from.key == gsid) then 
				return from.value;
            end
        end
    end 
end

-- this function is useful for extracting information from extended cost template. 
-- @param exid: extended cost id
-- @param gsid: gsid in tos. if nil, it matches anything. 
-- @return the items count of gsid in tos
function ItemManager.GetExtendedCostTemplateToItemCount(exid, gsid)
	local exTemplate = ItemManager.GetExtendedCostTemplateInMemory(exid);
	if(exTemplate) then
		local i, to;
		for i, to in ipairs(exTemplate.tos) do
			if(not gsid or to.key == gsid) then 
				return to.value;
            end
        end
    end 
end

-- Get all extended cost templates in memory
-- @return: ItemManager.ExtendedCostTemplates
function ItemManager.GetAllExtendedCostTemplateInMemory()
	return ItemManager.ExtendedCostTemplates;
end

-- load item shortcut gsids on init
function ItemManager.OnLoadItemShortcutGSIDs()
	Map3DSystem.mcml_controls.pe_slot.Load_shortcut_gsids();
end

-- click item shortcut index
function ItemManager.OnClickItemShortcut(index)
	if(index) then
		Map3DSystem.mcml_controls.pe_slot.OnClickItemShortcut(index);
	else
		log("error: invalid index got in ItemManager.OnClickItemShortcut\n")
	end
end

function ItemManager.GetTransformMarker_from_Pill(pill_gsid)
	if(pill_gsid) then
		return transform_mapping_pill_to_marker[pill_gsid];
	end
end

function ItemManager.GetTransformPill_from_Marker(marker_gsid)
	if(marker_gsid) then
		return transform_mapping_marker_to_pill[marker_gsid];
	end
end

-- is in gear score range
function ItemManager.IsInGearScoreRange(stat)
	if(stat == 102) then
		return true;
	elseif(stat >= 111 and stat <= 126) then
		return true;
	elseif(stat >= 151 and stat <= 166) then
		return true;
	elseif(stat >= 226 and stat <= 241) then
		return true;
	end
	return false
end

-- get gear score per each stat point
-- NOTE: the absolute percent stat DON'T count as a unique gear score source, it needs to be multiplied by the absolute stat value
function ItemManager.GetGearScoreFromStat(stat)
	if(stat == 102) then
		-- 102 add_power_pip_percent(CG)
		return 25;
	elseif(stat == 111) then
		-- 111 add_damage_overall_percent(CG)
		return 5 * 5;
	elseif(stat >= 112 and stat <= 118) then
		-- 112 add_damage_fire_percent(CG)
		-- 113 add_damage_ice_percent(CG)
		-- 114 add_damage_storm_percent(CG)
		-- 115 add_damage_myth_percent(CG)
		-- 116 add_damage_life_percent(CG)
		-- 117 add_damage_death_percent(CG)
		-- 118 add_damage_balance_percent(CG)
		return 5;
	elseif(stat == 119) then
		-- 119 add_resist_overall_percent(CG)
		return 5 * 5;
	elseif(stat >= 120 and stat <= 126) then
		-- 120 add_resist_fire_percent(CG)
		-- 121 add_resist_ice_percent(CG)
		-- 122 add_resist_storm_percent(CG)
		-- 123 add_resist_myth_percent(CG)
		-- 124 add_resist_life_percent(CG)
		-- 125 add_resist_death_percent(CG)
		-- 126 add_resist_balance_percent(CG)
		return 5;
	elseif(stat == 151) then
		-- 151 add_damage_overall_absolute(CG)
		return 5 * 5;
	elseif(stat >= 152 and stat <= 158) then
		-- 152 add_damage_fire_absolute(CG)
		-- 153 add_damage_ice_absolute(CG)
		-- 154 add_damage_storm_absolute(CG)
		-- 155 add_damage_myth_absolute(CG)
		-- 156 add_damage_life_absolute(CG)
		-- 157 add_damage_death_absolute(CG)
		-- 158 add_damage_balance_absolute(CG)
		return 5;
	elseif(stat == 159) then
		-- 159 add_resist_overall_absolute(CG)
		return 5 * 5;
	elseif(stat >= 160 and stat <= 166) then
		-- 160 add_resist_fire_absolute(CG)
		-- 161 add_resist_ice_absolute(CG)
		-- 162 add_resist_storm_absolute(CG)
		-- 163 add_resist_myth_absolute(CG)
		-- 164 add_resist_life_absolute(CG)
		-- 165 add_resist_death_absolute(CG)
		-- 166 add_resist_balance_absolute(CG)
		return 5;
	end
	return 0;
end

---------------------------------
-- item instance and inventroy functions
---------------------------------

-- get all items in specific bag
-- @param bag: bag
-- @param queueName: request queue name. it can be nil. 
-- @param callbackFunc: the callback function(msg) end
-- @param cache_policy: nil or string or a cache policy object, such as "access plus 1 day", System.localserver.CachePolicies["never"]
-- @return true if it is fetching data or data is already available.
function ItemManager.GetItemsInBag(bag, queuename, callbackFunc, cache_policy, timeout, timeout_callback)
	if(bag == nil) then
		LOG.std("", "error","Item", "error: nil bag param in ItemManager.GetItemsInBag");
		return;
	end
	
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end
	
	bag = tonumber(bag);
	
	-- bag uses 2byte smallint range: -2^15 (-32,768) to 2^15-1 (32,767)
	--if(bag > 32760) then
		--LOG.std("", "error","Item", "bag:"..bag.." exceeding 32760 in NPCBagManager.GetNPCBag");
		--return;
	--end
	
	-- check if the GetItemsInBag call is the first call in the current login session
	local isfirstinvokeincurrentloginsession = true;
	if(ItemManager.bags[tonumber(bag)]) then
		isfirstinvokeincurrentloginsession = false;
	end
	
	local msg = {
		bag = bag,
		cache_policy = cache_policy,
		isfirstinvokeincurrentloginsession = isfirstinvokeincurrentloginsession,
	};
	
	local unique_id = ParaGlobal.GenerateUniqueID();
	
	paraworld.inventory.GetItemsInBag(msg, "GetItemsInBag" or queuename..unique_id or "GetItemsInBag", function(msg) 
		-- store the item data in the ItemManager
		if(msg and msg.items) then
			-- delete all items that previously inserted in item table
			local guid_t, item_t;
			for guid_t, item_t in pairs(ItemManager.items) do
				if(item_t.bag == bag) then
					ItemManager.items[guid_t] = nil;
				end
			end

			local prepared_items = msg.items;
			
			-- NOTE: 2012/9/30 teen version ONLY
			--		 card qualification is no longer item instance stored in db item_instance
			--		 those items are made up of fake item instances(with negative guid) according to card template config
			--		 one can tell the whole set of cards that a user could use from combat level and school
			if(System.options.version == "teen" and bag == 24) then
				-- make a full copy of the 24 bag
				-- NOTE: if we direct modify msg.items, local server will save the modified msg instead of the original data
				--		 fake items will be saved in the local server, so we use a copy of the msg.items to append the fake cards
				prepared_items = commonlib.deepcopy(msg.items);
				-- pending faked negative guid card items
				local combat_level = Combat.GetMyCombatLevel()
				local school_gsid = Combat.GetSchoolGSID();
				local secondaryschool_gsid = Combat.GetSecondarySchoolGSID();
				local qualified_gsids = {};
				if(school_gsid and combat_level) then
					local gsids = Combat.GetQualifiedCardGSIDsBySchoolAndLevel(school_gsid, combat_level);
					for _, gsid in ipairs(gsids) do
						qualified_gsids[gsid] = true;
					end
				end
				LOG.std(nil, "info", "fake white card", {school_gsid = school_gsid, combat_level = combat_level});

				if(secondaryschool_gsid and combat_level) then
					local school_gsid = Combat.GSID_SecondarySchoolToSchool(secondaryschool_gsid)
					if(school_gsid) then
						local gsids = Combat.GetQualifiedCardGSIDsBySchoolAndLevel(school_gsid, combat_level);
						local _, gsid;
						for _, gsid in ipairs(gsids) do
							qualified_gsids[gsid] = true;
						end
					end
				end
				if(qualified_gsids) then
					local gsid, _;
					for gsid, _ in pairs(SchoolIrrelevant_GSIDs) do
						local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid);
						if(gsItem) then
							local require_level = gsItem.template.stats[138];
							if(not require_level or require_level <= combat_level) then
								qualified_gsids[gsid] = true;
							end
						end
					end

					local gsid, _;
					for gsid, _ in pairs(qualified_gsids) do
						table.insert(prepared_items, {
							guid = -gsid,
							gsid = gsid,
							obtaintime = "1000-10-10 10:10:10",
							bag = 24,
							position = -gsid,
							clientdata = "",
							serverdata = "",
							copies = 4,
						});
					end
				end
			elseif(System.options.version == "kids" and bag == 24) then
				--local qualified_gsids = {};
				--local combat_level = Combat.GetMyCombatLevel()
				--local school_gsid = Combat.GetSchoolGSID();
				--local gsids = Combat.GetQualifiedCardGSIDsBySchoolAndLevel(school_gsid, combat_level);
				--local _, gsid;
				--for _, gsid in ipairs(gsids) do
					--qualified_gsids[gsid] = true;
				--end
				for _, item in ipairs(prepared_items) do
					if(item.gsid > 22000 and item.gsid < 23000 and (not GoldCardGSIDForKids[item.gsid])) then
					--if(item.gsid > 22000 and item.gsid < 23000 and qualified_gsids[item.gsid]) then
						-- kids white card modify copies to 4;
						item.copies = 5;
					end
				end
			end
			-- sort the item table first and make data for pe:slot
			table.sort(prepared_items, function(a, b)
				return (a.position > b.position)
			end);
			local i = 0;
			local itemlist = {};
			local _, item;
			for _, item in ipairs(prepared_items) do
				--if(item.copies > 0 and not (tonumber(bag) == 0 and item.position == 23)) then -- skip the school item
				local remaining_time = ItemManager.ExpireRemainingTime(item);
				local remaining_time_valid = true;
				if(remaining_time and remaining_time < 0) then
					remaining_time_valid = false;
					pending_checkexpire_tag = true;
					pending_checkexpire_guids[item.guid] = true;
				end
				if(item.copies > 0 and remaining_time_valid) then
					-- filter only the items with avaiable copies
					i = i + 1;
					table.insert(itemlist, item.guid);
					local item = {
						order = i,
						guid = item.guid, 
						gsid = item.gsid,
						obtaintime = item.obtaintime,
						bag = tonumber(bag),
						position = item.position,
						clientdata = item.clientdata or "",
						serverdata = item.serverdata or "",
						copies = item.copies,
					};
					local gsItem = ItemManager.GetGlobalStoreItemInMemory(item.gsid);
					if(gsItem) then
						local class = gsItem.template.class;
						local subclass = gsItem.template.subclass;
						-- assign to different item type
						if(class == 1) then
							-- Item_Apparel
							-- NOTE: with category name "combat..." the apparel will be created as an Item_CombatApparel object
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_Apparel.lua");
							item = Map3DSystem.Item.Item_Apparel:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 5 and (subclass == 1 or subclass == 2 or subclass == 3 or subclass == 4 or subclass == 5)) then
							-- Item_PetApparel
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_PetApparel.lua");
							item = Map3DSystem.Item.Item_PetApparel:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 2 and (subclass == 1 or subclass == 2 or subclass == 4)) then
							-- Item_PetFood
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_PetFood.lua");
							item = Map3DSystem.Item.Item_PetFood:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 2 and subclass == 3) then
							-- Item_PetToy
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_PetToy.lua");
							item = Map3DSystem.Item.Item_PetToy:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 2 and subclass == 6) then
							-- Item_PetTransform
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_PetTransform.lua");
							item = Map3DSystem.Item.Item_PetTransform:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 2 and subclass == 7) then
							-- Item_PetTransformColor
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_PetTransformColor.lua");
							item = Map3DSystem.Item.Item_PetTransformColor:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 2 and subclass == 8) then
							-- Item_PetTransformMarker
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_PetTransformMarker.lua");
							item = Map3DSystem.Item.Item_PetTransformMarker:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 10 and subclass == 1) then
							-- Item_MountPet
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_MountPet.lua");
							item = Map3DSystem.Item.Item_MountPet:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 10 and subclass == 2) then
							-- Item_VIPPet
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_VIPPet.lua");
							item = Map3DSystem.Item.Item_VIPPet:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 11 and subclass == 1) then
							-- Item_FollowPet
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_FollowPet.lua");
							item = Map3DSystem.Item.Item_FollowPet:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 8 and subclass == 2) then
							-- Item_HomeOutdoorPlant
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_HomeOutdoorPlant.lua");
							item = Map3DSystem.Item.Item_HomeOutdoorPlant:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 8 and subclass == 1) then
							-- Item_HomeOutdoorHouse
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_HomeOutdoorHouse.lua");
							item = Map3DSystem.Item.Item_HomeOutdoorHouse:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 8 and subclass == 6) then
							-- Item_HomeOutdoorParterre
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_HomeOutdoorParterre.lua");
							item = Map3DSystem.Item.Item_HomeOutdoorParterre:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 8 and subclass == 4) then
							-- Item_HomeOutdoorOther
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_HomeOutdoorOther.lua");
							item = Map3DSystem.Item.Item_HomeOutdoorOther:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 9 and subclass == 2) then
							-- Item_HomeIndoorFurniture
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_HomeIndoorFurniture.lua");
							item = Map3DSystem.Item.Item_HomeIndoorFurniture:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 14 and subclass == 1) then
							-- Item_Quest_Common
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_Quest_Common.lua");
							item = Map3DSystem.Item.Item_Quest_Common:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 14 and subclass == 2) then
							-- Item_QuestTag
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_QuestTag.lua");
							item = Map3DSystem.Item.Item_QuestTag:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 14 and subclass == 3) then
							-- Item_QuestReward
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_QuestReward.lua");
							item = Map3DSystem.Item.Item_QuestReward:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 15 and subclass == 1) then
							-- Item_CharacterAnimation
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_CharacterAnimation.lua");
							item = Map3DSystem.Item.Item_CharacterAnimation:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 15 and subclass == 2) then
							-- Item_MountPetAnimation
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_MountPetAnimation.lua");
							item = Map3DSystem.Item.Item_MountPetAnimation:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 3 or class == 101) then
							-- Item_Quest_Common or activity items
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_Collectable.lua");
							item = Map3DSystem.Item.Item_Collectable:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 4) then
							-- Item_Reading
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_Reading.lua");
							item = Map3DSystem.Item.Item_Reading:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 12 and subclass == 2) then
							-- Item_Char_Medal
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_Char_Medal.lua");
							item = Map3DSystem.Item.Item_Char_Medal:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 12 and subclass == 3) then
							-- Item_MountPet_Medal
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_MountPet_Medal.lua");
							item = Map3DSystem.Item.Item_MountPet_Medal:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 13) then
							-- Item_Throwable
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_Throwable.lua");
							item = Map3DSystem.Item.Item_Throwable:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 16 and subclass == 1) then
							-- Item_HomelandTemplate
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_HomelandTemplate.lua");
							item = Map3DSystem.Item.Item_HomelandTemplate:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 17 and subclass == 1) then
							-- Item_SkillLevel
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_SkillLevel.lua");
							item = Map3DSystem.Item.Item_SkillLevel:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 18 and subclass == 1) then
							-- Item_CombatCard
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_CombatCard.lua");
							item = Map3DSystem.Item.Item_CombatCard:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 18 and subclass == 2) then
							-- Item_CombatCardQualification
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_CombatCardQualification.lua");
							item = Map3DSystem.Item.Item_CombatCardQualification:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 19 and subclass == 1) then
							-- Item_CombatDeck
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_CombatDeck.lua");
							item = Map3DSystem.Item.Item_CombatDeck:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 21) then
							-- Item_CombatTag
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_CombatTag.lua");
							item = Map3DSystem.Item.Item_CombatTag:new(item);
							ItemManager.items[item.guid] = item;
						elseif(class == 100) then
							-- Item_System
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_System.lua");
							item = Map3DSystem.Item.Item_System:new(item);
							ItemManager.items[item.guid] = item;
						else
							-- Item_Unknown
							--log("warning: unknown type item got in GetItemsInBag: \n");
							--commonlib.echo(item);
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_Unknown.lua");
							item = Map3DSystem.Item.Item_Unknown:new(item);
							ItemManager.items[item.guid] = item;
						end
					else
						NPL.load("(gl)script/kids/3DMapSystemItem/Item_Unknown.lua");
						item = Map3DSystem.Item.Item_Unknown:new(item);
						ItemManager.items[item.guid] = item;
					end
				end
			end
			-- record the items and count in bag
			local bag_num = tonumber(bag)
			ItemManager.bags[bag_num] = itemlist;
			if(bag_num == 0) then
				GameMemoryProtector.CheckPoint("System.Item.ItemManager.bags", nil, GameMemoryProtector.hash_func_item_bag, bag_num);
			end

		elseif(msg and msg.errorcode) then
			LOG.std("", "warning","Item", "warning: error fetching items from bag:"..bag..LOG.tostring(msg));
		end
		if(bag == 0) then
			-- update item set info on every bag 0 update
			Combat.PrepareItemSet()
		end
		-- callback function for host application
		callbackFunc(msg);
	end, nil, timeout, timeout_callback);
end


-- get all items in specific bag
-- @param nid: nid of the OPC
-- @param bag: bag
-- @param queueName: request queue name. it can be nil. 
-- @param callbackFunc: the callback function(msg) end
-- @param cache_policy: nil or string or a cache policy object, such as "access plus 1 day", System.localserver.CachePolicies["never"]
-- @return true if it is fetching data or data is already available.
function ItemManager.GetItemsInOPCBag(nid, bag, queuename, callbackFunc, cache_policy)
	if(not nid or nid == System.App.profiles.ProfileManager.GetNID()) then
		LOG.std("", "warning","Item", "warning: not valid nid or myself in ItemManager.GetItemsInOPCBag call ItemManager.GetItemsInBag instead");
		ItemManager.GetItemsInBag(bag, queuename, callbackFunc, cache_policy);
		return;
	end
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end
	
	ItemManager.items_OPC[nid] = ItemManager.items_OPC[nid] or {};
	ItemManager.bags_OPC[nid] = ItemManager.bags_OPC[nid] or {};
	
	local msg = {
		bag = bag,
		nid = nid,
		cache_policy = cache_policy,
	};
	paraworld.inventory.GetItemsInBag(msg, "GetItemsInBag" or queuename or "GetItemsInOPCBag", function(msg) 
		-- store the item data in the ItemManager
		if(msg and msg.items) then
			-- sort the item table first and make data for pe:slot
			table.sort(msg.items, function(a, b)
				return (a.position > b.position)
			end);
			local i = 0;
			local itemlist = {};
			local _, item;
			for _, item in ipairs(msg.items) do
				if(item.copies > 0) then
					-- filter only the items with avaiable copies
					i = i + 1;
					table.insert(itemlist, item.guid);
					local item = {
						nid = nid, -- additional nid provided for OPC items
						order = i,
						guid = item.guid, 
						gsid = item.gsid,
						obtaintime = item.obtaintime,
						bag = tonumber(bag),
						position = item.position,
						clientdata = item.clientdata or "",
						serverdata = item.serverdata or "",
						copies = item.copies,
					};
					ItemManager.SetOPCItemByGUID(nid, item); 
				end
			end
			-- record the items and count in bag
			ItemManager.bags_OPC[nid][tonumber(bag)] = itemlist;
		elseif(msg and msg.errorcode) then
			LOG.std("", "error","Item", "warning: error fetching items from bag:"..bag..LOG.tostring(msg));
		end
		if(bag == 0) then
			-- update item set info on every bag 0 update
			Combat.PrepareItemSet(nid)
		end
		-- callback function for host application
		callbackFunc(msg);
	end);
end

-- get the item count in bag
-- @param bag: bag id
-- @return: item count
function ItemManager.GetItemCountInBag(bag)
	if(ItemManager.bags[bag]) then
		return #(ItemManager.bags[bag]);
	end
	return 0;
end

-- get the item count in OPC bag
-- @param nid: nid of the OPC
-- @param bag: bag id
-- @return: item count
function ItemManager.GetOPCItemCountInBag(nid, bag)
	if(not nid or nid == System.App.profiles.ProfileManager.GetNID()) then
		LOG.std("", "error","Item", "not valid nid or myself in ItemManager.GetOPCItemCountInBag");
		return;
	end
	local bags = ItemManager.bags_OPC[nid] or {};
	if(bags[bag]) then
		return #(bags[bag]);
	end
	return 0;
end

-- get the item description in memory
-- @param guid: item guid in item_instance
-- @return:
--	{	nid = item.nid, (optional, only OPC item such as homeland plan or equips will have nid)
--		guid = item.guid, 
--		gsid = item.gsid,
--		obtaintime = item.obtaintime,
--		bag = bag,
--		position = item.position,
--		clientdata = item.clientdata,
--		serverdata = item.serverdata,
--		copies = item.copies,
--	}, nil if not found
function ItemManager.GetItemByGUID(guid)
	if(guid == nil) then
		return nil;
	end
	return ItemManager.items[guid];
end

-- get the item description in memory
-- @param nid: nid of the OPC
-- @param guid: item guid in item_instance
-- @return:
--	{	guid = item.guid, 
--		gsid = item.gsid,
--		obtaintime = item.obtaintime,
--		bag = bag,
--		position = item.position,
--		clientdata = item.clientdata,
--		serverdata = item.serverdata,
--		copies = item.copies,
--	}
function ItemManager.GetOPCItemByGUID(nid, guid)
	if(not nid or nid == System.App.profiles.ProfileManager.GetNID()) then
		LOG.std("", "error","Item", "not valid nid or myself in ItemManager.GetOPCItemByGUID");
		return;
	end
	local items = ItemManager.items_OPC[nid] or {};
	return items[guid];
end

-- create item from existing item. 
-- the original item is modified and returned. 
function ItemManager.CreateItem(item)
	if(not item) then
		return;
	end
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(item.gsid);
	if(gsItem) then
		local class = gsItem.template.class;
		local subclass = gsItem.template.subclass;
		-- assign to different item type
		if(class == 1) then
			-- Item_Apparel
			-- NOTE: with category name "combat..." the apparel will be created as an Item_CombatApparel object
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_Apparel.lua");
			item = Map3DSystem.Item.Item_Apparel:new(item);
		elseif(class == 5 and (subclass == 1 or subclass == 2 or subclass == 3 or subclass == 4 or subclass == 5)) then
			-- Item_PetApparel
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_PetApparel.lua");
			item = Map3DSystem.Item.Item_PetApparel:new(item);
		elseif(class == 2 and (subclass == 1 or subclass == 2 or subclass == 4)) then
			-- Item_PetFood
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_PetFood.lua");
			item = Map3DSystem.Item.Item_PetFood:new(item);
		elseif(class == 2 and subclass == 3) then
			-- Item_PetToy
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_PetToy.lua");
			item = Map3DSystem.Item.Item_PetToy:new(item);
		elseif(class == 2 and subclass == 6) then
			-- Item_PetTransform
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_PetTransform.lua");
			item = Map3DSystem.Item.Item_PetTransform:new(item);
		elseif(class == 2 and subclass == 7) then
			-- Item_PetTransformColor
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_PetTransformColor.lua");
			item = Map3DSystem.Item.Item_PetTransformColor:new(item);
		elseif(class == 2 and subclass == 8) then
			-- Item_PetTransformMarker
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_PetTransformMarker.lua");
			item = Map3DSystem.Item.Item_PetTransformMarker:new(item);
		elseif(class == 10 and subclass == 1) then
			-- Item_MountPet
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_MountPet.lua");
			item = Map3DSystem.Item.Item_MountPet:new(item);
		elseif(class == 10 and subclass == 2) then
			-- Item_VIPPet
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_VIPPet.lua");
			item = Map3DSystem.Item.Item_VIPPet:new(item);
		elseif(class == 11 and subclass == 1) then
			-- Item_FollowPet
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_FollowPet.lua");
			item = Map3DSystem.Item.Item_FollowPet:new(item);
		elseif(class == 8 and subclass == 2) then
			-- Item_HomeOutdoorPlant
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_HomeOutdoorPlant.lua");
			item = Map3DSystem.Item.Item_HomeOutdoorPlant:new(item);
		elseif(class == 8 and subclass == 1) then
			-- Item_HomeOutdoorHouse
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_HomeOutdoorHouse.lua");
			item = Map3DSystem.Item.Item_HomeOutdoorHouse:new(item);
		elseif(class == 8 and subclass == 6) then
			-- Item_HomeOutdoorParterre
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_HomeOutdoorParterre.lua");
			item = Map3DSystem.Item.Item_HomeOutdoorParterre:new(item);
		elseif(class == 8 and subclass == 4) then
			-- Item_HomeOutdoorOther
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_HomeOutdoorOther.lua");
			item = Map3DSystem.Item.Item_HomeOutdoorOther:new(item);
		elseif(class == 9 and subclass == 2) then
			-- Item_HomeIndoorFurniture
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_HomeIndoorFurniture.lua");
			item = Map3DSystem.Item.Item_HomeIndoorFurniture:new(item);
		elseif(class == 12 and subclass == 2) then
			-- Item_Char_Medal
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_Char_Medal.lua");
			item = Map3DSystem.Item.Item_Char_Medal:new(item);
		elseif(class == 13) then
			-- Item_Throwable
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_Throwable.lua");
			item = Map3DSystem.Item.Item_Throwable:new(item);
		elseif(class == 14 and subclass == 1) then
			-- Item_Quest_Common
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_Quest_Common.lua");
			item = Map3DSystem.Item.Item_Quest_Common:new(item);
		elseif(class == 14 and subclass == 2) then
			-- Item_QuestTag
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_QuestTag.lua");
			item = Map3DSystem.Item.Item_QuestTag:new(item);
		elseif(class == 14 and subclass == 3) then
			-- Item_QuestReward
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_QuestReward.lua");
			item = Map3DSystem.Item.Item_QuestReward:new(item);
		elseif(class == 16 and subclass == 1) then
			-- Item_HomelandTemplate
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_HomelandTemplate.lua");
			item = Map3DSystem.Item.Item_HomelandTemplate:new(item);
		elseif(class == 17 and subclass == 1) then
			-- Item_SkillLevel
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_SkillLevel.lua");
			item = Map3DSystem.Item.Item_SkillLevel:new(item);
		elseif(class == 18 and subclass == 1) then
			-- Item_CombatCard
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_CombatCard.lua");
			item = Map3DSystem.Item.Item_CombatCard:new(item);
		elseif(class == 18 and subclass == 2) then
			-- Item_CombatCardQualification
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_CombatCardQualification.lua");
			item = Map3DSystem.Item.Item_CombatCardQualification:new(item);
		elseif(class == 100) then
			-- Item_System
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_System.lua");
			item = Map3DSystem.Item.Item_System:new(item);
		else
			-- Item_Unknown
			--log("warning: unknown type item got in GetItemsInOPCBag: \n");
			--commonlib.echo(item);
			NPL.load("(gl)script/kids/3DMapSystemItem/Item_Unknown.lua");
			item = Map3DSystem.Item.Item_Unknown:new(item);
		end
	else
		NPL.load("(gl)script/kids/3DMapSystemItem/Item_Unknown.lua");
		item = Map3DSystem.Item.Item_Unknown:new(item);
	end	
	return item;
end

-- set opc item by guid
-- @param bUpdateOnly: if true, we will copy fields to existing ones, otherwise we will overwrite the old one with new one.  
function ItemManager.SetOPCItemByGUID(nid, item, bUpdateOnly)
	if(not nid or not item or not item.guid) then
		return 
	end
	
	local remaining_time = ItemManager.ExpireRemainingTime(item);
	if(remaining_time and remaining_time < 0) then
		return;
	end

	item = ItemManager.CreateItem(item);
	
	if(not ItemManager.items_OPC[nid]) then
		ItemManager.items_OPC[nid] = {};
	end
	if(bUpdateOnly and ItemManager.items_OPC[nid][item.guid]) then
		commonlib.partialcopy(ItemManager.items_OPC[nid][item.guid], item)
	else
		ItemManager.items_OPC[nid][item.guid] = item;
	end
end


-- get item guids in bag
-- @param bag: bag id
-- @return: item list {guid, guid, guid, ...}, nil if not found
function ItemManager.GetItemsInBagInMemory(bag)
	if(not bag) then
		LOG.std("", "error","ItemManager", "ItemManager.GetItemsInBagInMemory got invalid input: "..
			commonlib.serialize_compact({bag}));
		return;
	end
	if(ItemManager.bags[bag]) then
		return (ItemManager.bags[bag]);
	end
end

-- get opc item guids in bag
-- @param nid: nid of the OPC
-- @param bag: bag id
-- @return: item list {guid, guid, guid, ...}, nil if not found
function ItemManager.GetOPCItemsInBagInMemory(nid, bag)
	if(not nid or not bag) then
		LOG.std("", "error","ItemManager", "ItemManager.GetOPCItemsInBagInMemory got invalid input: "..
			commonlib.serialize_compact({nid, bag}));
		return;
	end
	local items = ItemManager.items_OPC[nid] or {};
	local bags = ItemManager.bags_OPC[nid] or {};
	if(bags[bag]) then
		return bags[bag];
	end
end

-- get the item by bag and order
-- @param bag: item bag in item_instance
-- @param order: the local order of the item in the same bag, starts from 1
-- @return: item data, nil if not found
function ItemManager.GetItemByBagAndOrder(bag, order)
	if(ItemManager.bags[bag]) then
		local guid = ItemManager.bags[bag][order];
		return ItemManager.items[guid];
	end
end

-- get the item by bag and order
-- @param nid: nid of the OPC
-- @param bag: item bag in item_instance
-- @param order: the local order of the item in the same bag, starts from 1
-- @return: item data, nil if not found
function ItemManager.GetOPCItemByBagAndOrder(nid, bag, order)
	if(not nid or nid == System.App.profiles.ProfileManager.GetNID()) then
		LOG.std("", "error","Item", "error: not valid nid or myself in ItemManager.GetOPCItemByBagAndOrder");
		return;
	end
	local items = ItemManager.items_OPC[nid] or {};
	local bags = ItemManager.bags_OPC[nid] or {};
	if(bags[bag]) then
		local guid = bags[bag][order];
		return items[guid];
	end
end

-- this is an sample compare function. it will select the highest required level 
function ItemManager.BetterEquipmentCompareFunc(last_gsItem, gsItem)
	local is_better, new_value
	local needLvl=gsItem.template.stats[138] or 0;  -- level required
	if(last_gsItem) then
		local needLvl2 = last_gsItem.template.stats[138] or 0;  -- level required
		if(needLvl2 < needLvl) then
			return true, needLvl;
		end
	else
		return true, needLvl;
	end
end

-- @note: this function is kind of slow. 
-- @param bag: if nil, it means bag 0 and 1 (which is current equiped and equipments)
-- @param ItemInventoryType: inventory type or nil.  if nil it matches all types. 
-- @param compareFunc: a compare function.  function(last_gsItem, gsItem)  return is_better, new_value;  end
-- @return item, max_value: where item is nil or the item instance containing the guid, gsid field. max_value is nil or the best equipment's required value. 
function ItemManager.GetBestEquipmentByBag(bag, ItemInventoryType, compareFunc)
	compareFunc = compareFunc or ItemManager.BetterEquipmentCompareFunc;
	
	if(bag) then
		local last_item, last_gsItem, max_value;
		if(ItemManager.bags[bag]) then
			local _, guid;
			for _, guid in ipairs(ItemManager.bags[bag]) do
				local item = ItemManager.items[guid];
				if(item and item.gsid) then
					local gsItem = ItemManager.GetGlobalStoreItemInMemory(item.gsid);
					if(gsItem and (not ItemInventoryType or gsItem.template.inventorytype == ItemInventoryType)) then
						local is_better, new_value = compareFunc(last_gsItem, gsItem)
						if(is_better) then
							last_gsItem = gsItem;
							last_item = item;
							max_value = new_value;
						end
					end
				end
			end
		end
		return last_item, max_value;
	else
		local item, max_value = ItemManager.GetBestEquipmentByBag(0, ItemInventoryType, compareFunc);
		local item2, max_value2 = ItemManager.GetBestEquipmentByBag(1, ItemInventoryType, compareFunc);
		if(max_value and max_value2) then
			if(max_value>=max_value2) then 
				return item, max_value;
			else
				return item2, max_value2;
			end
		else
			return item or item2, max_value or max_value2;
		end
	end
end

-- get the item by bag and order
-- @param bag: item bag in item_instance
-- @param position: item position in item_instance
-- @return: item data, {guid = 0} if not found
function ItemManager.GetItemByBagAndPosition(bag, position)
	if(ItemManager.bags[bag]) then
		local _, guid;
		for _, guid in ipairs(ItemManager.bags[bag]) do
			local item = ItemManager.items[guid];
			if(item and item.position == position) then
				return item;
			end
		end
	end
	return {guid = 0};
end

-- get the item by bag and order
-- @param nid: nid of the OPC
-- @param bag: item bag in item_instance
-- @param position: item position in item_instance
-- @return: item data, {guid = 0} if not found
function ItemManager.GetOPCItemByBagAndGsid(nid, bag, gsid)
	if(not nid or nid == System.App.profiles.ProfileManager.GetNID()) then
		LOG.std("", "warning","Item", "not valid nid or myself in ItemManager.GetOPCItemByBagAndPosition");
		return;
	end
	local items = ItemManager.items_OPC[nid] or {};
	local bags = ItemManager.bags_OPC[nid] or {};
	if(bags[bag]) then
		local _, guid;
		for _, guid in ipairs(bags[bag]) do
			local item = items[guid];
			if(item and item.gsid == gsid) then
				return item;
			end
		end
	end
	return {nid = nid, guid = 0};
end

-- get the item by bag and order
-- @param nid: nid of the OPC
-- @param bag: item bag in item_instance
-- @param position: item position in item_instance
-- @return: item data, {guid = 0} if not found
function ItemManager.GetOPCItemByBagAndPosition(nid, bag, position)
	if(not nid or nid == System.App.profiles.ProfileManager.GetNID()) then
		LOG.std("", "warning","Item", "not valid nid or myself in ItemManager.GetOPCItemByBagAndPosition");
		return;
	end
	local items = ItemManager.items_OPC[nid] or {};
	local bags = ItemManager.bags_OPC[nid] or {};
	if(bags[bag]) then
		local _, guid;
		for _, guid in ipairs(bags[bag]) do
			local item = items[guid];
			if(item and item.position == position) then
				return item;
			end
		end
	end
	return {nid = nid, guid = 0};
end

-- mapping from gsid to guid, please note that the guid may not exist, one needs to verify it. 
local gsid_map_cache = {};

-- check if the user has the global store item in inventory
-- @param gsid: global store id. it also support 0(emoney) and -1(pmoney)
-- -1:P币-非绑定的；0:E币-绑定的；-2:亲密度；-3:爱心值；-4:力量值；-5:敏捷值；-6:智慧值；-7:建筑熟练度；-8:抱抱龙等级；-9:体力值；-10:清洁值；-11:心情值；-12:健康状态；-13:战斗经验值；-14:战斗等级；-15:魔法星能量值；-16:魔法星M值；-17:魔法星等级；-18:战斗系别；-19:精力值；-20:体力值2；-101人气值；-103:充值获得的魔豆总数
-- @param bag: only check the bag
-- @param excludebag: 
-- @return bOwn, guid, bag, copies: if own the gs item, and the guid, bag and copies of the item if own
function ItemManager.IfOwnGSItem(gsid, bag, excludebag)
	if(gsid) then
		if(gsid>0) then
			local guid, item;
			guid = gsid_map_cache[gsid];
			if(guid) then
				item = ItemManager.items[guid];
				if(item) then
					if(bag ==nil and item.bag and item.bag>=50000) then
						-- ignore all items whose bag number is bigger than 50000, since it is store bags
						return;
					end
					if(item.gsid == gsid and (bag == nil or item.bag == bag) and (excludebag == nil or item.bag ~= excludebag) and item.bag ~= 20001) then
						return true, item.guid, item.bag, item.copies;
					end 
				else
					gsid_map_cache[gsid] = nil;
				end
			end
			
			for guid, item in pairs(ItemManager.items) do
				if(item.gsid == gsid and (bag == nil or item.bag == bag) and (excludebag == nil or item.bag ~= excludebag) and item.bag ~= 20001) then
					if(bag ==nil and item.bag and item.bag>=50000) then
						-- ignore all items whose bag number is bigger than 50000, since it is store bags
					else
						if( not (item.bag and item.bag>=50000)) then
							gsid_map_cache[gsid] = item.guid;
						end
						return true, item.guid, item.bag, item.copies;
					end
				end
			end
		elseif(gsid == 0) then
			local myInfo = ProfileManager.GetUserInfoInMemory(ProfileManager.GetNID());
			if(myInfo) then
				return true, nil, nil, myInfo.emoney;
			end
		elseif(gsid == -1) then
			local myInfo = ProfileManager.GetUserInfoInMemory(ProfileManager.GetNID());
			if(myInfo) then
				return true, nil, nil, myInfo.pmoney;
			end
		else
			local bean = MyCompany.Aries.Pet.GetBean();
			if(bean) then
				if(gsid == -13) then
					return true, nil, nil, bean.combatexp or 1;
				elseif(gsid == -14) then
					return true, nil, nil, bean.combatlel or 0;
				elseif(gsid == -8) then
					return true, nil, nil, bean.level or 0;
				elseif(gsid == -15) then
					return true, nil, nil, bean.energy or 0;
				elseif(gsid == -16) then
					return true, nil, nil, bean.mlel or 0;
				elseif(gsid == -19) then
					return true, nil, nil, bean.stamina or 100;
				elseif(gsid == -20) then
					return true, nil, nil, bean.stamina2 or 100;
				elseif(gsid == -103) then
					return true, nil, nil, bean.accummodou or 0;
				elseif(gsid == -101) then
					return true, nil, nil, bean.popularity or 0;
				end
			end
		end
	end
	return false;
end

-- check if the user has the global store item in inventory
-- @param nid: nid of the OPC
-- @param gsid: global store id
-- @return bOwn, guid: if own the gs item, and the guid of the item if own
function ItemManager.IfOPCOwnGSItem(nid, gsid)
	if(not nid or nid == System.App.profiles.ProfileManager.GetNID()) then
		LOG.std("", "error","Item", "not valid nid or myself in ItemManager.IfOPCOwnGSItem");
		return;
	end
	local items = ItemManager.items_OPC[nid] or {};
	local guid, item;
	for guid, item in pairs(items) do
		if(item.gsid == gsid) then
			return true, item.guid, item.bag, item.copies;
		end
	end
	return false;
end

-- similar to ItemManager.GetItemsByGUID
function ItemManager.GetOPCItemsByGUID(nid, guid)
	if(not nid) then
		return;
	end
	local items = ItemManager.items_OPC[nid];
	if(items) then
		return items[guid];
	end
end

-- check if the user equiped with the global store item on hand
-- @return bEquip, guid: if equip the gs item, and the guid of the item if equip
function ItemManager.IfEquipGSItem(gsid)
	local count = ItemManager.GetItemCountInBag(0);
	local i;
	for i = 1, count do
		local item = ItemManager.GetItemByBagAndOrder(0, i);
		if(item and item.gsid == gsid) then
			return true, item.guid;
		end
	end
	return false;
end

-- check if the user equiped with the global store item on hand
-- @return bEquip, guid: if equip the gs item, and the guid of the item if equip
function ItemManager.IfOPCEquipGSItem(nid, gsid)
	local count = ItemManager.GetOPCItemCountInBag(nid, 0);
	local i;
	for i = 1, count do
		local item = ItemManager.GetOPCItemByBagAndOrder(nid, 0, i);
		if(item and item.gsid == gsid) then
			return true, item.guid;
		end
	end
	return false;
end

-- return all item count copies sum in memory
-- @param gsid: global store id
-- @return total copies
function ItemManager.GetGSItemTotalCopiesInMemory(gsid)
	local copies = 0;
	local guid, item;
	for guid, item in pairs(ItemManager.items) do
		if(item.gsid == gsid and item.bag ~= 20001) then
			copies = copies + item.copies;
		end
	end
	return copies;
end

-- get the current mount pet item in bag 0
-- @return: item instance, nil if not avaiable
function ItemManager.GetMyCurrentMountPetItemOnEquip()
	local item = ItemManager.GetItemByBagAndPosition(0, 31);
	if(item and item.guid > 0) then
		return item;
	end
end

-- get the current follow pet item in bag 0
-- @return: item instance, nil if not avaiable
function ItemManager.GetMyCurrentFollowPetItemOnEquip()
	local item = ItemManager.GetItemByBagAndPosition(0, 32);
	if(item and item.guid > 0) then
		return item;
	end
end

-- get my mount pet item
-- TODO: hardcoded the 10001 item
-- @return item, nil if not valid or not found
function ItemManager.GetMyMountPetItem()
	local bOwn, guid = ItemManager.IfOwnGSItem(10001);
	if(bOwn == true and guid > 0) then
		local item = ItemManager.GetItemByGUID(guid);
		if(item and item.guid > 0) then
			return item;
		end
	end
end

-- get OPC mount pet item
-- TODO: hardcoded the 10001 item
-- @param nid: nid of the OPC user
-- @return item, nil if not valid or not found
function ItemManager.GetOPCMountPetItem(nid)
	local bOwn, guid = ItemManager.IfOPCOwnGSItem(nid, 10001);
	if(bOwn == true and guid > 0) then
		local item = ItemManager.GetOPCItemByGUID(nid, guid);
		if(item and item.guid > 0) then
			return item;
		end
	end
end

-- TODO: ugly code
-- equip the character with the items in item system inventory 
function ItemManager.RefreshMyself()
	--local slots = {5,6,7,9};
	local Pet = commonlib.gettable("MyCompany.Aries.Pet");
	local player
	if(Pet.GetRealPlayer) then
		player = Pet.GetRealPlayer();
	else
		player = ParaScene.GetPlayer();
	end

	-- force update the max hp if equip change
	if(MsgHandler.HealByWisp) then
		MsgHandler.HealByWisp(0);
	end
	
	NPL.load("(gl)script/apps/Aries/Pet/main.lua");
	local equip_string = System.UI.CCS.GetCCSInfoString();
	System.UI.CCS.ApplyCCSInfoString(player, equip_string);
end

-- get all items in inventory bags, this is usually called in login process stage 5
-- ItemManager.GetItemsInBag() can be called afterward in callback function to retrieve the item data
-- @param queueName: request queue name. it can be nil. 
-- @param callbackFunc: the callback function(bSucceed) end, NOTE: only return true if all bag items are downloaded successfully
-- @param cache_policy: nil or string or a cache policy object, such as "access plus 1 day", System.localserver.CachePolicies["never"]
-- @param OnProgress: a callback function of function(msg) end, where is msg.finished_count is the finished bag count, msg.total_count is the total number of bags.
-- @return true if it is fetching data or data is already available.
function ItemManager.GetItemsInAllBags(queuename, callbackFunc, cache_policy, timeout, timeout_callback, OnProgress)
	
	--paraworld.inventory.GetMyBags({}, "GetItemsInAllBags", function(msg)
		--if(msg and msg.bagids) then
			
			-- NOTE: remove paraworld.inventory.GetMyBags call
			-- user fixed bag implementation
			local bagids = "0,1,12,13,14,21,22,23,24,25,26,40,41,42,43,44,46,52,62,63,72,91,999,1001,1002,1003,1004,10010,10062,10063,10064,30000,30001,30006,30010,30011,30042,30081,30123,30127,30132,30141,30160,30171,30172,30181,30200,30202,30203,30208,30211,30251,30271,30272,30337,30341,30371,31001,31401,50201";
			
			local bags = {"0", "1", "11", "12", "13", "14", "15", "21", "22", "23", "24", "25", "26", "40", "41", "42", "43", "44", "45", "46", "51", "52", "53", "54", "62", "63", 
				"1002", "1003", "1004", "10062", "10063", "10064", "72", "81", "91", "10010"};
			local bag;
			for bag in string.gfind(bagids, "([^,]+)") do
				if(bag ~= "0" and bag ~= "1" and bag ~= "11" and bag ~= "12" and bag ~= "13" and bag ~= "14" and bag ~= "15" 
					and bag ~= "21" and bag ~= "22" and bag ~= "23" and bag ~= "24" and bag ~= "25" and bag ~= "26" 
					and bag ~= "40" and bag ~= "41" and bag ~= "42" and bag ~= "43" and bag ~= "44" and bag ~= "45" and bag ~= "46" 
					and bag ~= "51" and bag ~= "52" and bag ~= "53" and bag ~= "54" 
					and bag ~= "62" and bag ~= "63" 
					and bag ~= "1002" and bag ~= "1003" and bag ~= "1004" 
					and bag ~= "10062" and bag ~= "10063" and bag ~= "10064" 
					and bag ~= "72" and bag ~= "81" and bag ~= "91" and bag ~= "10010") then
					if(tonumber(bag) >= 10001 and tonumber(bag) <= 10009) then
						-- we will skip the bags of applications, such as homeland and other
					else
						table.insert(bags, bag);
					end
				end
			end
			
			-- append quest NPC tag bags
			local i;
			local ItemManager = System.Item.ItemManager;
			for i = 50000, 59999 do
				local gsItem = ItemManager.GetGlobalStoreItemInMemory(i);
				if(gsItem) then
					local ii;
					local bExist = false;
					for ii = 1, #bags do
						if(tonumber(bags[ii]) == tonumber(gsItem.template.bagfamily)) then
							bExist = true;
							break;
						end
					end
					if(bExist ~= true) then
						table.insert(bags, tostring(gsItem.template.bagfamily));
					end
				end
			end
			
			-- sync the 10001 homeland bag
			-- NOTE: the 10001 bag is not included in the GetItemsInBags api call, but called seperately with additional GetItemsInBag
			--table.insert(bags, "10001");
			
			-- modified 2010.1.19 by LXZ: we now get by some in one batch, but batches are fetched in sequence.
			local isSucceeds = {};
			
			-- send the progress 
			local function InformProgress_()
				if(OnProgress) then
					local finished_count = 0;
					local _;
					for _, _ in pairs(isSucceeds) do
						finished_count = finished_count + 1;
					end
					-- ParaEngine.Sleep(1)
					-- commonlib.echo({"111111111111111111", finished_count = finished_count, total_count = #bags, });
					OnProgress({finished_count = finished_count, total_count = #bags, })
				end
			end
			
			InformProgress_();
			
			-- check if all bags have been fetched and invoke the callback. 
			-- return true if all done
			local function CheckCompletion()
				local bAllSucceed = true;
				local _, bag;
				for _, bag in ipairs(bags) do
					bag = tonumber(bag);
					if(not isSucceeds[bag]) then
						bAllSucceed = false;
						break;
					end	
				end
				if(bAllSucceed) then
					-- callbackFunc
					callbackFunc(true);
					return true;				
				end
			end	
			
			-- return some unfetched bag ids in an array
			-- @NOTE: modify this to adjust rule of batch loading. 
			local function select_some_bag()
				-- how many bags to return at most
				local max_bag_count = 15;
				local some_bags = {};
				local _, bag;
				for _, bag in ipairs(bags) do
					bag = tonumber(bag);
					if(not isSucceeds[bag]) then
						if(#some_bags >= max_bag_count) then
							break;
						elseif(bag == 10001 and #some_bags > 0) then
							-- bag 10001 must be fetched individually.
						else
							some_bags[#some_bags + 1] = bag;
						end
					end
				end
				return some_bags;
			end
			
			-- get some bags in one batch
			local function GetItemsInBags_some()
				local some_bags = select_some_bag();
				
				if(#some_bags == 0) then
					CheckCompletion()
					return;
				end
				
				local msg_bags_input = "";
				local _, b;
				for _, b in ipairs(some_bags) do
					msg_bags_input = msg_bags_input..b..",";
				end
				LOG.std("", "system","Item","ItemManager: GetItemsInBags_some: %s", msg_bags_input);
				
				paraworld.inventory.GetItemsInBags({bags = msg_bags_input,}, "GetItemsInBags", function(msg) 
					if(not msg or msg.errorcode) then
						callbackFunc(false);
						return;
					end
					InformProgress_();
					
					local _, bag
					for _,bag in ipairs(some_bags) do
						ItemManager.GetItemsInBag(bag, "GetBag"..tostring(bag).."AfterGetItemsInAllBags", function(msg)
							if(msg and msg.items) then
								isSucceeds[bag] = true;
							else
								-- callbackFunc(false) if any bag items are failed to retrieve
								callbackFunc(false);
								return;
							end
							local some_all_fetched = true;
							local _, bag
							for _,bag in ipairs(some_bags) do
								if(not isSucceeds[bag]) then
									some_all_fetched = false
									break;
								end
							end
							if(some_all_fetched) then
								-- if some bags are all fetched, we will check completion or fetch some later on. 
								if(not CheckCompletion()) then
									GetItemsInBags_some();
								end
							end
						end, "access plus 1 minutes", timeout, timeout_callback);
					end	
				end, nil, timeout, timeout_callback);
			end
			
			-- fetch some bags in a batch and then fetch some of the rest, until all bags are fetched. 
			GetItemsInBags_some();
		--else
			--LOG.std("", "error","Item", "error GetItemsInAllBags"..LOG.tostring(msg));
		    --callbackFunc(false);
		--end
	--end, nil, timeout, timeout_callback);
end

-- verify the essential items, those items are always needed and always free of charge
-- @param callbackFunc: callbackFunc(bSucceed)
-- @param timeout
-- @param timeout_callback
function ItemManager.VerifyEssentialItems(callbackFunc, timeout, timeout_callback)
	local hasGSItem = ItemManager.IfOwnGSItem;
	-- item gsid that need update
	local gsids = {
		980, -- 980_HeroInstanceCooldownTag
		985, -- 985_QuestProgressTag
		994, -- 994_AntiIndulgenceTag
		995, -- 995_CombatBagDesc
		996, -- 996_CombatHPTag
		--9011, -- 9011_SitDown
		--9012, -- 9012_LayDown
		9504, -- Snowball
		10000, -- 10000_MagicStar NOTE: every account is instanced, only valid for VIP users and use as pet equip and unequip
		24001, -- 24001_CombatDeck_Level1 NOTE: in case of init deck absence
		39101, -- 39101_SnowHomelandTemplate
		39102, -- 39102_NewYearHomelandTemplate
		39103, -- 39103_CandyHomelandTemplate
		39104, -- 39104_EnvironmentalHomelandTemplate
		50313, -- 50313_DailyMobFarmingQuest
		50315, -- 50315_DailyWishQuest
		50042, -- 50042_DoneMouseTutorial NOTE: original instance is purchased in the Papa tutorial here we manually assure the tag
		50334, -- 50334_MountPetTransform
		50335, -- 50335_NewYearGiftObtain_Tag
		20901, -- Record the world info online： url，name，uploaddate；
	};
	if(System.options.version == "teen") then
		gsids = {
			985, -- 985_QuestProgressTag
			993, -- 993_CombatPetAutoFightTag
			994, -- 994_AntiIndulgenceTag
			995, -- 995_CombatBagDesc
			996, -- 996_CombatHPTag
			--9011, -- 9011_SitDown
			--9012, -- 9012_LayDown
			9504, -- Snowball
			10000, -- 10000_MagicStar NOTE: every account is instanced, only valid for VIP users and use as pet equip and unequip
			24001, -- 24001_CombatDeck_Level1 NOTE: in case of init deck absence
			39101, -- 39101_SnowHomelandTemplate
			39102, -- 39102_NewYearHomelandTemplate
			39103, -- 39103_CandyHomelandTemplate
			39104, -- 39104_EnvironmentalHomelandTemplate
			50313, -- 50313_DailyMobFarmingQuest
			50315, -- 50315_DailyWishQuest
			50042, -- 50042_DoneMouseTutorial NOTE: original instance is purchased in the Papa tutorial here we manually assure the tag
			50334, -- 50334_MountPetTransform
			50335, -- 50335_NewYearGiftObtain_Tag
			20901, -- Record the world info online： url，name，uploaddate；
		};
	end
	local gsids_needpurchase = {};
	local index = 1;
	while(true) do
		if(not gsids[index]) then
			break;
		end
		if(not hasGSItem(gsids[index])) then
			table.insert(gsids_needpurchase, gsids[index]);
		end
		index = index + 1;
	end

	-- 40004_RedMushroomArenaCombatCountRemaining
	local function ContinueWithKillExpiredArenaCombatCount()
		do
			-- never used 40004
			callbackFunc(true); 
			return;
		end

		local maxdailycount = 10;
		local gsItem = ItemManager.GetGlobalStoreItemInMemory(40004);
		if(gsItem) then
			maxdailycount = gsItem.maxdailycount;
		end
		local gsObtain = ItemManager.GetGSObtainCntInTimeSpanInMemory(40004);
		if(gsObtain and gsObtain.inday == 0) then
			local hasGSItem = ItemManager.IfOwnGSItem;
			local bHas, guid, bag, copies = hasGSItem(40004);
			if(bHas) then
				-- destroy existing combat count(expired)
				ItemManager.DestroyItem(guid, copies, function(msg)
					LOG.std("", "system","Item", "+++++++ VerifyEssentialItem DestroyItem 40004 guid copies: "..guid.." "..copies.." return: +++++++"..LOG.tostring(msg));
					if(msg.issuccess == true) then
						ItemManager.PurchaseItem(40004, maxdailycount, function(msg) 
							LOG.std("", "system","Item", "+++++++ Verify 40004_RedMushroomArenaCombatCountRemaining 111 return: +++++++"..LOG.tostring(msg));
							if(msg.issuccess == true) then
								callbackFunc(true);
							else
								callbackFunc(false);
							end
						end, function(msg) end, nil, "none", nil, nil, timeout, timeout_callback);
					else
						callbackFunc(false);
					end
				end);
			else
				-- none remaining combat count
				ItemManager.PurchaseItem(40004, maxdailycount, function(msg) 
					LOG.std("", "system","Item", "+++++++ Verify 40004_RedMushroomArenaCombatCountRemaining 222 return: +++++++"..LOG.tostring(msg));
					if(msg.issuccess == true) then
						callbackFunc(true);
					else
						callbackFunc(false);
					end
				end, function(msg) end, nil, "none", nil, nil, timeout, timeout_callback);
			end
		elseif(gsObtain and gsObtain.inday == maxdailycount) then
			callbackFunc(true);
		elseif(gsObtain and gsObtain.inday and gsObtain.inday < maxdailycount) then
			-- NOTE: purchase additional counts if and only if maxdaily count is changed
			ItemManager.PurchaseItem(40004, maxdailycount - gsObtain.inday, function(msg) 
				LOG.std("", "system","Item", "+++++++ Verify 40004_RedMushroomArenaCombatCountRemaining 333 return: +++++++"..LOG.tostring(msg));
				if(msg.issuccess == true) then
					callbackFunc(true);
				else
					callbackFunc(false);
				end
			end, function(msg) end, nil, "none", nil, nil, timeout, timeout_callback);
		else
			-- NOTE: continue with next process if and only if maxdaily count is changed
			callbackFunc(true);
			--callbackFunc(false);
		end
	end

	-- 12005_ArenaFreeTicket
	local function ContinueWithKillExpiredArenaFreePKTicket()
		local maxdailycount = 5;
		local gsItem = ItemManager.GetGlobalStoreItemInMemory(12005);
		if(gsItem) then
			maxdailycount = gsItem.maxdailycount;
		end
		local gsObtain = ItemManager.GetGSObtainCntInTimeSpanInMemory(12005);
		if(gsObtain and gsObtain.inday == 0) then
			local hasGSItem = ItemManager.IfOwnGSItem;
			local bHas, guid, bag, copies = hasGSItem(12005);
			if(bHas) then
				-- destroy existing tickets(expired)
				ItemManager.DestroyItem(guid, copies, function(msg)
					LOG.std("", "system","Item", "+++++++ VerifyEssentialItem DestroyItem 12005 guid copies: "..guid.." "..copies.." return: +++++++"..LOG.tostring(msg));
					if(msg.issuccess == true) then
						ContinueWithKillExpiredArenaCombatCount();
					else
						callbackFunc(false);
					end
				end);
			else
				ContinueWithKillExpiredArenaCombatCount();
			end
		elseif(gsObtain and gsObtain.inday == maxdailycount) then
			ContinueWithKillExpiredArenaCombatCount();
		else
			-- NOTE: continue with next process if and only if maxdaily count is changed
			ContinueWithKillExpiredArenaCombatCount();
			--callbackFunc(false);
		end
	end

	-- 12003_FreePvPTicket
	local function ContinueWithKillExpiredFreePKTicket()
		local maxdailycount = 15;
		local gsItem = ItemManager.GetGlobalStoreItemInMemory(12003);
		if(gsItem) then
			maxdailycount = gsItem.maxdailycount;
		end
		local gsObtain = ItemManager.GetGSObtainCntInTimeSpanInMemory(12003);
		if(gsObtain and gsObtain.inday == 0) then
			local hasGSItem = ItemManager.IfOwnGSItem;
			local bHas, guid, bag, copies = hasGSItem(12003);
			if(bHas) then
				-- destroy existing tickets(expired)
				ItemManager.DestroyItem(guid, copies, function(msg)
					LOG.std("", "system","Item", "+++++++ VerifyEssentialItem DestroyItem 12003 guid copies: "..guid.." "..copies.." return: +++++++"..LOG.tostring(msg));
					if(msg.issuccess == true) then
						ContinueWithKillExpiredArenaFreePKTicket();
					else
						callbackFunc(false);
					end
				end);
			else
				ContinueWithKillExpiredArenaFreePKTicket();
			end
		elseif(gsObtain and gsObtain.inday == maxdailycount) then
			ContinueWithKillExpiredArenaFreePKTicket();
		else
			--callbackFunc(false);
			ContinueWithKillExpiredArenaFreePKTicket();
		end
	end
	
	if(#gsids_needpurchase > 0) then
		local function VerifyOneItem()
			-- pick the last one
			local gsid = gsids_needpurchase[#gsids_needpurchase];
			gsids_needpurchase[#gsids_needpurchase] = nil;
			ItemManager.PurchaseItem(gsid, 1, function(msg) 
				LOG.std("", "system","Item", "+++++++ VerifyEssentialItem "..gsid.." return: +++++++"..LOG.tostring(msg));
				if(msg.issuccess == true) then
					if(#gsids_needpurchase == 0) then
						ContinueWithKillExpiredFreePKTicket();
						ItemManager.ContinueWithKillDailyItems();
					else
						-- continue with the last gsid
						VerifyOneItem();
					end
				else
					callbackFunc(false);
				end
			end, function(msg) end, nil, "none", nil, nil, timeout, timeout_callback);
		end
		-- start from the last gsid
		VerifyOneItem();
	else
		ContinueWithKillExpiredFreePKTicket();
		ItemManager.ContinueWithKillDailyItems();
	end
end

function ItemManager.ContinueWithKillDailyItems()
	local KillDailyItems_gsid = {
		17321, -- 17321_CopperCoin
	};
	if(System.options.version == "teen") then
		KillDailyItems_gsid = {
		};
	end
	local _, gsid;
	for _, gsid in pairs(KillDailyItems_gsid) do
		local gsObtain = ItemManager.GetGSObtainCntInTimeSpanInMemory(gsid);
		if(gsObtain and gsObtain.inday == 0) then
			local hasGSItem = ItemManager.IfOwnGSItem;
			local bHas, guid, bag, copies = hasGSItem(gsid);
			if(bHas) then
				-- destroy existing tickets(expired)
				ItemManager.DestroyItem(guid, copies, function(msg)
					LOG.std("", "system","Item", "+++++++ ContinueWithKillDailyItems DestroyItem "..gsid.." guid copies: "..guid.." "..copies.." return: +++++++"..LOG.tostring(msg));
				end);
			end
		end
	end
end

function ItemManager.VerifyCombatItems()
	-- 1266_CommonNewbieWand
	local item = ItemManager.GetItemByBagAndPosition(0, 11);
	if(item and item.guid > 0) then
		-- 1266_CommonNewbieWand enchanged to 5 newbie wands by school
		if(item.gsid == 1807 or item.gsid == 1808 or item.gsid == 1809 or item.gsid == 1810 or item.gsid == 1811) then
			local combat_level = Combat.GetMyCombatLevel();
			if(combat_level and combat_level >= 8) then
				-- traverse through all bag 1 items
				local tobe_equip_guid = nil;
				local tobe_equip_weight = 0;
				local i;
				for i = 1, ItemManager.GetItemCountInBag(1) do
					local item = ItemManager.GetItemByBagAndOrder(1, i);
					if(item and item.guid > 0) then
						local gsItem = ItemManager.GetGlobalStoreItemInMemory(item.gsid);
						if(gsItem and gsItem.template.inventorytype == 11) then
							-- 137 school_requirement(CG) 物品穿着必须系别
							-- 180 vip_items(C)VIP专属物品 
							-- 138 combatlevel_requirement(CG) 物品穿着必须战斗等级 
							local required_level = gsItem.template.stats[138]
							if(required_level and required_level <= combat_level and not gsItem.template.stats[137] and not gsItem.template.stats[180]) then
								if(required_level > tobe_equip_weight) then
									tobe_equip_guid = item.guid;
									tobe_equip_weight = required_level;
								end
							end
						end
					end
				end
				-- auto replace the newbie wand
				if(tobe_equip_guid) then
					ItemManager.EquipItem(tobe_equip_guid, function(msg) end);
				end
			end
		end
	end
end

-- verify the vip items, mainly check the vip qualification and unmount vip equips
-- @param callbackFunc: callbackFunc(bSucceed)
-- @param timeout
-- @param timeout_callback
function ItemManager.VerifyVIPItems(callbackFunc, timeout, timeout_callback)
	local VIP = commonlib.gettable("MyCompany.Aries.VIP");
	if(VIP.IsVIPAndActivated()) then
		callbackFunc(true);
		return;
	end
	local items = ItemManager.GetItemsInBagInMemory(0)
	if(items) then
		local _, guid;
		for _, guid in pairs(items) do
			local item = ItemManager.GetItemByGUID(guid);
			if(item and item.guid > 0) then
				local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(item.gsid);
				if(gsItem) then
					-- 180 vip_items(C)
					if(gsItem.template.stats[180] == 1) then
						-- unequip the vip items
						item:OnClick("left", true); -- true for bSkipMessageBox
					end
				end
			end
		end
	end
	-- unequip magic star if not vip user
	if(VIP.IsMagicStarEquipped()) then
		VIP.UnequipMagicStar()
	end
	-- TODO: dirty code
	-- callback func after the api process
	callbackFunc(true);
end

-- purchase item
-- @param gsid: global store id
-- @param count: purchase count
-- @param callbackFunc: the callback function(msg) end immediately after purchase
-- @param callbackFunc2: the callback function(msg) end that will be called again after update bag
-- @param (optional)clientdata: clientdata string set to the newly purchased item
-- @param (optional)tiptypeonerror: "pick"|"purchase"|"none" default to purchase
-- @param (optional)bRefreshBagFamily: if refresh the bagfamily of the newly purchased item, default to true
--								NOTE: since the refresh is not performed, callbackFunc2 will not be invoked
--									  and hook OnPurchaseItemAfterGetItemsInBag
-- @param (optional)ForceShowOrHideNotificationOnObtain: force the notification of item obtain, mainly for quest related items which gsid exceeds 50000
function ItemManager.PurchaseItem(gsid, count, callbackFunc, callbackFunc2, clientdata, tiptypeonerror, bRefreshBagFamily, ForceShowOrHideNotificationOnObtain, timeout, timeout_callback)
	-- double check the available emoney
	local mymoney = 0;
	local ProfileManager = System.App.profiles.ProfileManager;
	local myInfo = ProfileManager.GetUserInfoInMemory(ProfileManager.GetNID());
	if(myInfo) then
		mymoney = myInfo.emoney;
		if(mymoney < 0) then
			LOG.std("", "error","Item", "negative emoney when purchase item");
			return;
		end
	end
	
	-- input purchase item message
	local msg = {
		gsid = gsid,
		count = count,
		clientdata = clientdata,
	};
	paraworld.inventory.PurchaseItem(msg, "PurchaseItem_"..tostring(gsid), function(msg) 
		if(bRefreshBagFamily ~= false) then
			local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
			if(gsItem) then
				ItemManager.GetItemsInBag(gsItem.template.bagfamily, "UpdateBagAfterPurchase_"..tostring(gsid), function(msg3)
					-- update all page controls containing the pe:slot tag
					-- TODO: update only the PageCtrl with the same bag
					Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
					if(msg.issuccess == true) then
						-- call hook for OnPurchaseItemAfterGetItemsInBag
						local hook_msg = { aries_type = "OnPurchaseItemAfterGetItemsInBag", 
							gsid = gsid, count = count, 
							tiptypeonerror = tiptypeonerror, 
							ForceShowOrHideNotificationOnObtain = ForceShowOrHideNotificationOnObtain, 
							wndName = "main"};
						CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);
						
						-- call hook for OnObtainItemAfterGetItemsInBag
						local hook_msg = { aries_type = "OnObtainItemAfterGetItemsInBag", 
							gsid = gsid, count = count, 
							tiptypeonerror = tiptypeonerror, 
							ForceShowOrHideNotificationOnObtain = ForceShowOrHideNotificationOnObtain,
							wndName = "main"};
						CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);

						local hook_msg = { aries_type = "onObtainItemAfterGetItemsInBag_MPG", 
							gsid = gsid, count = count, 
							tiptypeonerror = tiptypeonerror, 
							ForceShowOrHideNotificationOnObtain = ForceShowOrHideNotificationOnObtain,
							wndName = "main"};
						CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);
					end
					if(callbackFunc2) then
						callbackFunc2(msg);
					end
				end, "access plus 1 minute");
				-- refresh bag 0 if item is purhcased with magic bean
				if(gsItem.count and gsItem.count > 0 and gsItem.template.bagfamily ~= 0) then
					ItemManager.GetItemsInBag(0, "UpdateBagAfterPurchase_bag0_"..tostring(gsid), function(msg3)
					end, "access plus 1 minute");
				end
			end
		end
		
		if(msg.issuccess == true) then
			-- call hook for OnPurchaseItem
			local hook_msg = { aries_type = "OnPurchaseItem", gsid = gsid, count = count, wndName = "main"};
			CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);

			local hook_msg = { aries_type = "onPurchaseItem_MPD", gsid = gsid, count = count, wndName = "main"};
			CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);

			
			-- call hook for OnObtainItem
			local hook_msg = { aries_type = "OnObtainItem", gsid = gsid, count = count, wndName = "items"};
			CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);
			
			-- increase the count that obtained in both daily and weekly in memory
			local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
			if(gsItem) then
				if(gsItem.maxdailycount ~= 0 or gsItem.maxweeklycount ~= 0) then
					ItemManager.IncreaseGSObtainCntInTimeSpanInMemory(gsid, count);
				end
			end
			
			if(not (gsid >= 1050 and gsid <= 1064)) then
				-- update the user info in memory, mainly emoney
				System.App.profiles.ProfileManager.GetUserInfo(nil, "UpdateUserInfoInMemoryAfterPurchase", function(msg) end);
			end
			
			local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(gsid)
			local name = "";
			if(gsItem) then
				local class = gsItem.template.class;
				local subclass = gsItem.template.subclass;
				local joybeancount = gsItem.ebuyprice * count;
				
				if(class == 1 and joybeancount > 0) then
					-- send log information
					paraworld.PostLog({action = "joybean_spend_on_apparel", gsid = gsid, count = count, joybeancount = joybeancount}, 
						"joybean_spend_on_apparel_log", function(msg)
					end);
				elseif((class == 8 or class == 9) and joybeancount > 0) then
					-- send log information
					paraworld.PostLog({action = "joybean_spend_on_homelanditem", gsid = gsid, count = count, joybeancount = joybeancount}, 
						"joybean_spend_on_homelanditem_log", function(msg)
					end);
				elseif(class == 2 and joybeancount > 0) then
					-- send log information
					paraworld.PostLog({action = "joybean_spend_on_dragonitem", gsid = gsid, count = count, joybeancount = joybeancount}, 
						"joybean_spend_on_dragonitem_log", function(msg)
					end);
				elseif(class == 11) then
					-- send log information
					paraworld.PostLog({action = "followpet_adopt", gsid = gsid}, 
						"followpet_adopt_log", function(msg)
					end);
				elseif(joybeancount > 0) then
					-- send log information
					paraworld.PostLog({action = "joybean_spend_on_other", gsid = gsid, count = count, joybeancount = joybeancount}, 
						"joybean_spend_on_other_log", function(msg)
					end);
				end
			end
		end
		
		if(tiptypeonerror == "none") then
			callbackFunc(msg);
			return;
		end
		if(msg.issuccess == false and msg.errorcode == 424) then
			local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(gsid)
			local name = "";
			if(gsItem) then
				name = gsItem.template.name;
				--NOTE: there are two conditions that will trigger such event, through purshace or free item pick
				if(tiptypeonerror == nil or tiptypeonerror == "purchase") then
					if(gsItem.maxcount == 1) then
						_guihelper.MessageBox("你已经有"..name.."了，看看别的宝贝吧。")
					else
						_guihelper.MessageBox("你不能拥有过多的"..name.."。");
					end
					--_guihelper.MessageBox("你已经有"..name.."了，不需要再购买了哦，去看看别的吧！\n");
				elseif(tiptypeonerror == "pick") then
					_guihelper.MessageBox("你已经有这件宝贝了！\n");
				end
			end
			-- 411 奇豆不足
			-- 443 魔豆不足
			-- 419 用户不存在或不可用
			-- 497 数据不存在或已被删除
			-- 496 未登录或没有权限
			-- 424 购买数量超过限制
			-- 428 超过单日购买限制
			-- 429 超过周购买限制
			-- 436 超过小时总购买数
			-- 437 超过当天总购买数
		elseif(msg.issuccess == false and msg.errorcode == 411) then
			if(System.options.version=="kids") then
				_guihelper.MessageBox("很抱歉，你的奇豆数量不足！")
			else
				_guihelper.MessageBox("很抱歉，你的银币数量不足！")
			end
		elseif(msg.issuccess == false and msg.errorcode == 428) then
			if(tiptypeonerror == "purchase") then
				_guihelper.MessageBox("购买失败了! 超过每日购买的最大限制");
			end
		elseif(msg.issuccess == false and msg.errorcode == 429) then
			if(tiptypeonerror == "purchase") then
				_guihelper.MessageBox("购买失败了! 超过每周购买的最大限制");
			end

		elseif(msg.issuccess == false and msg.errorcode == 443) then
			
			NPL.load("(gl)script/apps/Aries/Desktop/GUIHelper/CustomMessageBox.lua");
			local s;
			if(System.options.version=="kids") then
				s = "很抱歉，你的魔豆数量不足，先多兑换点魔豆再来买吧！";
			else
				s = "很抱歉，你的金币数量不足，先多兑换点金币再来买吧！";
			end
			_guihelper.Custom_MessageBox(s,function(result)
				if(result == _guihelper.DialogResult.Yes)then
					if(System.options.version=="kids") then
						NPL.load("(gl)script/apps/Aries/VIP/PurChaseMagicBean.lua");
					else
						NPL.load("(gl)script/apps/Aries/VIP/PurChaseMagicBean.teen.lua");
					end
					MyCompany.Aries.Inventory.PurChaseMagicBean.Show();
				end
			end,_guihelper.MessageBoxButtons.YesNo,{yes = "Texture/Aries/Common/PurchaseMagicBean_32bits.png; 0 0 153 49", no = "Texture/Aries/Common/Later_32bits.png; 0 0 153 49"});

		elseif(msg.issuccess == false and msg.errorcode == 419) then
			_guihelper.MessageBox("用户不存在或不可用\n");
		elseif(msg.issuccess == false and msg.errorcode == 496) then
			_guihelper.MessageBox("买东西要登陆\n");
		elseif(msg.issuccess == false and msg.errorcode == 497) then
			_guihelper.MessageBox("物品出了点小小的差错，谁能不出错呢，对吧？ 我们马上改，很快改好！\n");
		elseif(msg.issuccess == false and msg.errorcode == 436) then
			local name = "这件东西";
			local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
			if(gsItem) then
				name = gsItem.template.name;
			end
			_guihelper.MessageBox(string.format([[<div style="margin-left:20px;margin-top:16px;">%s非常畅销，已经卖完啦，你下个小时再来吧！</div>]], name));
		elseif(msg.issuccess == false and msg.errorcode == 437) then
			local name = "这件东西";
			local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(gsid);
			if(gsItem) then
				name = gsItem.template.name;
			end
			_guihelper.MessageBox(string.format([[<div style="margin-left:20px;margin-top:16px;">%s非常畅销，已经卖完啦，你明天再来吧！</div>]], name));
		end
		if(callbackFunc) then
			callbackFunc(msg);
		end
	end, nil, timeout, timeout_callback);
end

-- extended cost
-- @param exid: extended cost id
-- @param times: executed times
-- @param (optional)froms: if nil, it will be achieved from the items in memory
-- @param (optional)bags: if nil, it will be achieved from the items in memory
-- @param callbackFunc: the callback function(msg) end immediately after extended cost
-- @param callbackFunc2: the callback function(msg) end that will be called again after update bag
-- @param (optional)tiptypeonerror: "pick"|"purchase"|"none" default to none
-- @param (optional)bRefreshBagFamily: if refresh the bagfamily of the newly exchanged item, default to true
--								NOTE: since the refresh is not performed, callbackFunc2 will not be invoked
--									  and hook OnExtendedCostAfterGetItemsInBag 
-- @param (optional)limitedbag: only items in this bag will be extendedcost, if froms and bags are not specified
function ItemManager.ExtendedCost2(exid, times, froms, bags, callbackFunc, callbackFunc2, tiptypeonerror, bRefreshBagFamily, limitedbag, timeout, timeout_callback)
	if(not times) then
		LOG.std("", "error", "Item", "ExtendedCost2 got nil times");
		return;
	end
	ItemManager.ExtendedCost(exid, froms, bags, callbackFunc, callbackFunc2, tiptypeonerror, bRefreshBagFamily, limitedbag, timeout, timeout_callback, times)
end

-- for debugging only, it will by pass any test and assume the user already has enough items.
function ItemManager.ExtendedCostDebug(exid, times, callbackFunc)
	local froms, bags, froms;
	local exTemplate = ItemManager.GetExtendedCostTemplateInMemory(exid);
	if(exTemplate) then
		froms = "";
		for i, from in ipairs(exTemplate.froms) do
			if(from.key ~= 0 and from.key ~= -1 and from.key ~= -19 and from.key ~= -20) then -- $p and $e cash and stamina2
				local bHas, guid, bag, copies = ItemManager.IfOwnGSItem(from.key, limitedbag);
				if(guid) then
					froms = froms or "";
					froms = froms..guid..","..(from.value * (times or 1)).."|";
					-- update bag if no bags are specified
					if(bags == nil) then
						bags = bags or {};
						bags[i] = bag;
					else
						bags[i] = bag;
					end
				else
					LOG.std(nil, "error", "ItemManager", "you need to at least have one %s", tostring(from.key));
				end
			elseif(from.key == 0) then
				-- $E
				froms = froms or "";
				froms = froms.."0,"..(from.value * (times or 1)).."|";
				-- update bag if no bags are specified
				if(bags == nil) then
					bags = bags or {};
					bags[i] = 0;
				else
					bags[i] = 0;
				end
			elseif(from.key == -19) then
				-- stamina2
				froms = froms or "";
				froms = froms.."-19,"..(from.value * (times or 1)).."|";
				-- update bag if no bags are specified
				if(bags == nil) then
					bags = bags or {};
					bags[i] = 0;
				else
					bags[i] = 0;
				end
			elseif(from.key == -20) then
				-- stamina2
				froms = froms or "";
				froms = froms.."-20,"..(from.value * (times or 1)).."|";
				-- update bag if no bags are specified
				if(bags == nil) then
					bags = bags or {};
					bags[i] = 0;
				else
					bags[i] = 0;
				end
			elseif(from.key == -1) then
				-- TODO: $P not supported
			end
		end
	else
		LOG.std(nil, "error", "ItemManager", "error: nil froms and nil exTemplate for ItemManager.ExtendedCost(), exid:%s", tostring(exid));
		return false;
	end

	if(froms == "") then
		bags = {};
	end
	local mymountpetguid = nil;
	local item = ItemManager.GetMyMountPetItem();
	if(item and item.guid > 0) then
		mymountpetguid = item.guid;
	end
	local input_msg = {
		exid = exid,
		froms = froms,
		frombags = bags, -- for local server optimization
		mymountpetguid = mymountpetguid, -- for local server optimization
	};
	local extendedcost_api = paraworld.inventory.ExtendedCost;
	if(times) then
		input_msg.times = times;
		extendedcost_api = paraworld.inventory.ExtendedCost2;
	end

	LOG.std(nil, "info", "ExtendedCostDebug", "paraworld.inventory.ExtendedCost2(%s, nil, echo);", commonlib.serialize_compact(input_msg));
	extendedcost_api(input_msg, "ExtendedCost_"..ParaGlobal.GenerateUniqueID(), function(msg) 
		if(callbackFunc) then
			callbackFunc(msg);
		else
			echo(msg);
		end
	end);
end

-- extended cost
-- @param exid: extended cost id
-- @param (optional)froms: if nil, it will be achieved from the items in memory
-- @param (optional)bags: if nil, it will be achieved from the items in memory
-- @param callbackFunc: the callback function(msg) end immediately after extended cost
-- @param callbackFunc2: the callback function(msg) end that will be called again after update bag
-- @param (optional)tiptypeonerror: "pick"|"purchase"|"none" default to none
-- @param (optional)bRefreshBagFamily: if refresh the bagfamily of the newly exchanged item, default to true
--								NOTE: since the refresh is not performed, callbackFunc2 will not be invoked
--									  and hook OnExtendedCostAfterGetItemsInBag 
-- @param (optional)limitedbag: only items in this bag will be extendedcost, if froms and bags are not specified
function ItemManager.ExtendedCost(exid, froms, bags, callbackFunc, callbackFunc2, tiptypeonerror, bRefreshBagFamily, limitedbag, timeout, timeout_callback, times)
	if(not exid) then
		LOG.std("", "warn","ItemManager", "Nil ExtendedCost id found");
		echo(commonlib.debugstack(2, 5, 1));
		return
	end
	LOG.std("", "system","Item", "ExtendedCost start-------------------");
	if(froms == nil and bags == nil) then
		local exTemplate = ItemManager.GetExtendedCostTemplateInMemory(exid);
		if(exTemplate) then
			froms = "";
			local i, from;
			for i, from in ipairs(exTemplate.froms) do
				if(from.key ~= 0 and from.key ~= -1 and from.key ~= -19 and from.key ~= -20) then -- $p and $e cash and stamina2
					local bHas, guid, bag, copies = ItemManager.IfOwnGSItem(from.key, limitedbag);
					if(bHas == true and from.value * (times or 1) <= copies) then
						froms = froms or "";
						froms = froms..guid..","..(from.value * (times or 1)).."|";
						-- update bag if no bags are specified
						if(bags == nil) then
							bags = bags or {};
							bags[i] = bag;
						else
							bags[i] = bag;
						--elseif(bags[i] and bags[i] ~= bag) then
							--log("warning: bag of item in memory and bag in param are not the same. maybe due to search order.\n");
						end
					else
						LOG.std(nil, "error", "ItemManager", "error: nil froms and nil exTemplate for ItemManager.ExtendedCost(), exid:%s, gsid:%s", tostring(exid), tostring(from.key));
						return false;
					end
				elseif(from.key == 0) then
					-- $E
					froms = froms or "";
					froms = froms.."0,"..(from.value * (times or 1)).."|";
					-- update bag if no bags are specified
					if(bags == nil) then
						bags = bags or {};
						bags[i] = 0;
					else
						bags[i] = 0;
					--elseif(bags[i] and bags[i] ~= bag) then
						--log("warning: bag of item in memory and bag in param are not the same. maybe due to search order.\n");
					end
				elseif(from.key == -19) then
					-- stamina2
					froms = froms or "";
					froms = froms.."-19,"..(from.value * (times or 1)).."|";
					-- update bag if no bags are specified
					if(bags == nil) then
						bags = bags or {};
						bags[i] = 0;
					else
						bags[i] = 0;
					--elseif(bags[i] and bags[i] ~= bag) then
						--log("warning: bag of item in memory and bag in param are not the same. maybe due to search order.\n");
					end
				elseif(from.key == -20) then
					-- stamina2
					froms = froms or "";
					froms = froms.."-20,"..(from.value * (times or 1)).."|";
					-- update bag if no bags are specified
					if(bags == nil) then
						bags = bags or {};
						bags[i] = 0;
					else
						bags[i] = 0;
					--elseif(bags[i] and bags[i] ~= bag) then
						--log("warning: bag of item in memory and bag in param are not the same. maybe due to search order.\n");
					end
				elseif(from.key == -1) then
					-- TODO: $P not supported
				end
			end
		else
			LOG.std(nil, "error", "ItemManager", "error: nil froms and nil exTemplate for ItemManager.ExtendedCost(), exid:%s", tostring(exid));
			return false;
		end
	end
	if(froms == "") then
		bags = {};
	end
	local mymountpetguid = nil;
	local item = ItemManager.GetMyMountPetItem();
	if(item and item.guid > 0) then
		mymountpetguid = item.guid;
	end
	local input_msg = {
		exid = exid,
		froms = froms,
		frombags = bags, -- for local server optimization
		mymountpetguid = mymountpetguid, -- for local server optimization
	};
	local extendedcost_api = paraworld.inventory.ExtendedCost;
	if(times) then
		input_msg.times = times;
		extendedcost_api = paraworld.inventory.ExtendedCost2;
	end
	extendedcost_api(input_msg, "ExtendedCost_"..ParaGlobal.GenerateUniqueID(), function(msg) 
		if(msg.issuccess == true) then
			if(bRefreshBagFamily ~= false) then
				local bagsNeedUpdate = {};
				local _, frombag;
				for _, frombag in ipairs(bags) do
					table.insert(bagsNeedUpdate, {bag = frombag, bRefreshed = false});
				end
				local _, update;
				for _, update in ipairs(msg.updates) do
					table.insert(bagsNeedUpdate, {bag = update.bag, bRefreshed = false});
				end
				local _, add;
				for _, add in ipairs(msg.adds) do
					table.insert(bagsNeedUpdate, {bag = add.bag, bRefreshed = false});
				end
				local function TryAfterGetItemsInBag()
					-- if any bag is not refreshed, return
					local _, bagRefresh;
					for _, bagRefresh in ipairs(bagsNeedUpdate) do
						if(bagRefresh.bRefreshed == false) then
							return;
						end
					end
					-- update all page controls containing the pe:slot tag
					-- TODO: update only the PageCtrl with the same bag
					Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
					if(msg.issuccess == true) then
						-- call hook for OnPurchaseItem
						local hook_msg = { aries_type = "OnExtendedCostAfterGetItemsInBag", input_msg = input_msg, output_msg = msg, wndName = "main"};
						CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);
						
						local _, add;
						for _, add in pairs(msg.adds) do
							-- call hook for OnObtainItem
							local hook_msg = { aries_type = "OnObtainItem", gsid = add.gsid, count = add.cnt, wndName = "items"};
							CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);

							local hook_msg = { aries_type = "onObtainItemAfterGetItemsInBag_MPG", gsid = add.gsid, count = add.cnt, wndName = "main"};
							CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);
						end
						local _, update;
						for _, update in pairs(msg.updates) do
							-- call hook for OnObtainItem

							local hook_msg = { aries_type = "OnObtainItem", gsid = update.gsid_fromlocalserver, count = update.cnt, wndName = "items"};
							CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);

							local hook_msg = { aries_type = "onObtainItemAfterGetItemsInBag_MPG", gsid = update.gsid_fromlocalserver, count = update.cnt, wndName = "main"};
							CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);
							
						end
					end
					if(callbackFunc2) then
						callbackFunc2(msg);
					end
				end
				local _, bagRefresh;
				for _, bagRefresh in ipairs(bagsNeedUpdate) do
					ItemManager.GetItemsInBag(bagRefresh.bag, "UpdateBag_"..bagRefresh.bag.."_AfterExtendedCost_RemovePass_"..tostring(exid), function(msg3)
						bagsNeedUpdate[_].bRefreshed = true;
						TryAfterGetItemsInBag();
					end, "access plus 1 minute");
				end
			end
			-- call hook for OnPurchaseItem
			local hook_msg = { aries_type = "OnExtendedCost", input_msg = input_msg, output_msg = msg, tiptypeonerror = tiptypeonerror, wndName = "main"};
			CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);
			
			local _, add;
			for _, add in pairs(msg.adds) do
				-- call hook for OnObtainItem
				local hook_msg = { aries_type = "OnObtainItem", gsid = add.gsid, count = add.cnt, wndName = "items"};
				CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);
				
				-- increase the count that obtained in both daily and weekly in memory
				local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(add.gsid);
				if(gsItem) then
					if(gsItem.maxdailycount ~= 0 or gsItem.maxweeklycount ~= 0) then
						ItemManager.IncreaseGSObtainCntInTimeSpanInMemory(add.gsid, add.cnt);
					end
				end
			end
			local _, update;
			for _, update in pairs(msg.updates) do
				-- call hook for OnObtainItem
				local hook_msg = { aries_type = "OnObtainItem", gsid = update.gsid_fromlocalserver, count = update.cnt, wndName = "items"};
				CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);
				
				-- increase the count that obtained in both daily and weekly in memory
				local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(update.gsid_fromlocalserver);
				if(gsItem) then
					if(gsItem.maxdailycount ~= 0 or gsItem.maxweeklycount ~= 0) then
						ItemManager.IncreaseGSObtainCntInTimeSpanInMemory(update.gsid_fromlocalserver, update.cnt);
					end
				end
			end
			
			-- update the user info in memory, mainly emoney
			System.App.profiles.ProfileManager.GetUserInfo(nil, "UpdateUserInfoInMemoryAfterExtendedCost", function(msg) end);
			
			-- refresh my pet.get info
			Pet.GetRemoteValue(nil, function() end, "access plus 1 minute");
			
			if(msg.obtains and msg.obtains[-13]) then
				-- force update game server combat level and exp
				System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="ForceUpdateUserAndDragonInfo"});
			end
		end
		
		if(tiptypeonerror == nil or tiptypeonerror == "none") then
			callbackFunc(msg);
			return;
		end
		if(msg.issuccess == false and msg.errorcode == 424) then
			--NOTE: there are two conditions that will trigger such event, through purshace or free item pick
			if(tiptypeonerror == "purchase") then
				if(System.options.version == "teen") then
					_guihelper.MessageBox("超出物品拥有上限，不能再获得。");
				else
					_guihelper.MessageBox("你已经有这件宝贝了，不需要再购买了哦，去看看别的吧！\n");
				end

			elseif(tiptypeonerror == "pick") then
				_guihelper.MessageBox("你已经有这件宝贝了！\n");
			end
			-- 411 奇豆不足
			-- 443 魔豆不足
			-- 419 用户不存在或不可用
			-- 497 数据不存在或已被删除
			-- 496 未登录或没有权限
			-- 424 购买数量超过限制
			-- 428 超过单日购买限制
			-- 429 超过周购买限制
		elseif(msg.issuccess == false and msg.errorcode == 411) then
			if(System.options.version=="kids") then
				_guihelper.MessageBox("很抱歉，你的奇豆数量不足！")
			else
				_guihelper.MessageBox("很抱歉，你的银币数量不足！")
			end
		elseif(msg.issuccess == false and msg.errorcode == 427) then
			_guihelper.MessageBox(format("你的条件不符， 暂时无法使用这个物品<br/>%s", ItemManager.GetErrorMsgFromExidPres(exid) or "" ))
		elseif(msg.issuccess == false and msg.errorcode == 429) then
			if(tiptypeonerror == "purchase") then
				_guihelper.MessageBox("购买失败了! 超过每周购买的最大限制");
			end
		elseif(msg.issuccess == false and msg.errorcode == 428) then
			if(tiptypeonerror == "purchase") then
				_guihelper.MessageBox("物品超过单日最大获得上限");
			end

		elseif(msg.issuccess == false and msg.errorcode == 443) then
			NPL.load("(gl)script/apps/Aries/Desktop/GUIHelper/CustomMessageBox.lua");
			local s;
			if(System.options.version=="kids") then
				s = "很抱歉，你的魔豆数量不足，先多兑换点魔豆再来买吧！";
			else
				s = "很抱歉，你的金币数量不足，先多兑换点金币再来买吧！";
			end
			_guihelper.Custom_MessageBox(s,function(result)
				if(result == _guihelper.DialogResult.Yes)then
					if(System.options.version=="kids") then
						NPL.load("(gl)script/apps/Aries/VIP/PurChaseMagicBean.lua");
					else
						NPL.load("(gl)script/apps/Aries/VIP/PurChaseMagicBean.teen.lua");
					end
					MyCompany.Aries.Inventory.PurChaseMagicBean.Show();
				end
			end,_guihelper.MessageBoxButtons.YesNo,{yes = "Texture/Aries/Common/PurchaseMagicBean_32bits.png; 0 0 153 49", no = "Texture/Aries/Common/Later_32bits.png; 0 0 153 49"});

		elseif(msg.issuccess == false and msg.errorcode == 419) then
			_guihelper.MessageBox("用户不存在或不可用\n");
		elseif(msg.issuccess == false and msg.errorcode == 496) then
			_guihelper.MessageBox("买东西要登陆\n");
		elseif(msg.issuccess == false and msg.errorcode == 497) then
			_guihelper.MessageBox("物品出了点小小的差错，谁能不出错呢，对吧？ 我们马上改，很快改好！\n");
		end
		callbackFunc(msg);
	end, nil, timeout, timeout_callback);
end

-- it gives a more detail msg code usually from errorcode 427. it check the preconditions locally. 
function ItemManager.GetErrorMsgFromExidPres(exid)
	local error_msg;
	local exTemplate = ItemManager.GetExtendedCostTemplateInMemory(exid);
	if(exTemplate)then
		if(exTemplate.pres) then
			local _, v;
			for _, v in ipairs(exTemplate.pres) do
				local key_num = tonumber(v.key) or 0;
				if (key_num==-104) then
					if(exid == 2161) then
						error_msg = "时光眼罩只有2012年以前注册的小哈奇才能领取哦"
						return error_msg;
					end
					local value = tonumber(v.value);
					error_msg = format("注册%d天后可用", value);
					local userinfo = Map3DSystem.App.profiles.ProfileManager.GetUserInfoInMemory();
					if(userinfo and userinfo.birthday) then
						local can_use_time = commonlib.timehelp.get_next_date_str(userinfo.birthday, value, "%04d-%02d-%02d")
						error_msg = format("%s 请在%s之后使用.", error_msg, can_use_time);
					end
				elseif (key_num<=-201 and key_num>=-299) then
					local obtain_to_use_day = -(key_num+200);
					local gsid = tonumber(v.value);
					local bHas, guid = ItemManager.IfOwnGSItem(gsid);
					error_msg = format("物品获得%d天后才能使用.", obtain_to_use_day);

					if(bHas) then
						local item = ItemManager.GetItemByGUID(guid);
						if(item and item.obtaintime) then
							local can_use_time = commonlib.timehelp.get_next_date_str(item.obtaintime, obtain_to_use_day, "%04d-%02d-%02d")
							error_msg = format("%s 请在%s之后使用.", error_msg, can_use_time);
						end
					end
				end
			end
		end
	end
	return error_msg;
end

-- move one item from source bag to destination bag
-- @param guids: item instance id table, e.x.{12, 43, 26}
-- @param counts: item instance count table, e.x.{1, 10, 1}
-- @param dstbag: destination bag
-- @param callbackFunc: the callback function(msg) end
function ItemManager.MoveItem(guids, counts, dstbag, callbackFunc)
	-- check if the items are in the same bag
	local srcbag;
	local i, guid;
	for i, guid in ipairs(guids) do
		local item = ItemManager.GetItemByGUID(guid)
		if(item and item.bag) then
			if(srcbag ~= nil and srcbag ~= item.bag) then
				LOG.std("", "error","Item", "guids are not belong to the same bag in ItemManager.MoveItem()");
				return;
			end
			srcbag = item.bag;
		end
	end
	if(#(guids) ~= #(counts)) then
		LOG.std("", "error","Item", "guids and counts number doesn't match in ItemManager.MoveItem()");
		return;
	end
	local items = "";
	local i;
	for i = 1, #(counts) do
		if(i == #(counts)) then
			items = items..guids[i]..","..counts[i];
		else
			items = items..guids[i]..","..counts[i].."|";
		end
	end
	if(items and srcbag and dstbag) then
		local msg = {
			items = items,
			srcbag = srcbag,
			dstbag = dstbag,
		};
		paraworld.inventory.MoveItems(msg, "MoveItem", function(msg)
			-- update all page controls containing the pe:slot tag
			-- TODO: update only the PageCtrl with the same bag
			Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
			callbackFunc(msg);
		end);
	else
		LOG.std("", "error","Item", "nil items or srcbag or dstbag in MoveItem");
		return;
	end
end


-- get currently equipped item instance with the same inventory type of guid. 
-- currently, we only support equipment check for bag 0. in future, we may support magic bag, pet, cards, etc. 
-- we usually call this function to get the gsid of the 
-- @param gsidOrItem: the gsid or gsItem object itself.
-- @return equipped_item, isEquipped: equipped_item is nil, if there is no corresponding equipped item. isEquipped is true if the current player is already equipped with the input gsid item. 
function ItemManager.GetEquippedItem(gsidOrItem)
	local gsItem;
	if(type(gsidOrItem) == "table") then
		gsItem = gsidOrItem;
	else
		gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(gsidOrItem);
	end
	if(not gsItem) then 
		return 
	end
	local inventorytype = gsItem.template.inventorytype;
	if((inventorytype >=1 and inventorytype <=19) or inventorytype == 24 or inventorytype == 70 or inventorytype == 71) then
		-- this is an object that can be equiped on the bag 0(character)
		local equipped_item = ItemManager.GetItemByBagAndPosition(0, inventorytype);
		if(equipped_item and equipped_item.gsid and equipped_item.guid>0) then
			return equipped_item, (equipped_item.gsid == gsItem.gsid)
		end
	end
end

-- equip the item on the character slot bag 0
-- @param guid: item instance id
-- @param callbackFunc: the callback function(msg) end
-- @param (optional)explicitBag: explicitly specify the bag id
-- @param (optional)explicitGSID: explicitly item gsid
-- @param (optional)bRefreshBagFamily: if refresh the bagfamily of the newly equip item, default to true
function ItemManager.EquipItem(guid, callbackFunc, explicitBag, explicitGSID, bRefreshBagFamily)
	-- TODO: lock the equiped character slot, incase of multiple invoke
	local item = ItemManager.GetItemByGUID(guid)
	
	local bag = explicitBag;
	local inventorytype;
	if(not bag and item and item.gsid and item.guid > 0) then
		bag = item.bag;
	end
	if(item and item.gsid and item.guid > 0) then
		local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(item.gsid);
		if(gsItem) then
			inventorytype = gsItem.template.inventorytype;
		end
	else
		local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(explicitGSID);
		if(gsItem) then
			inventorytype = gsItem.template.inventorytype;
		end
	end
	
	if(bag and inventorytype) then
		if(bag == 0) then
			LOG.std("", "error","Item", "already equip the item(guid:"..tostring(guid)..")in bag 0");
			return;
		end
		local fromposition;
		if(item) then
			fromposition = item.position;
		end
		local msg = {
			guid = guid,
			bag = bag,
			position = inventorytype, -- for local server optimization
			fromposition = fromposition, -- for local server optimization, if nil skip local server write
		};
		paraworld.inventory.EquipItem(msg, "EquipItem_"..tostring(guid), function(msg)
			if(msg.issuccess == true) then
				-- on item equiped
				NPL.load("(gl)script/kids/3DMapSystemItem/Item_Apparel.lua");
				Map3DSystem.Item.Item_CombatApparel.OnItemEquiped(guid);
				-- update the bag family and bag 1
				local bBagReply = false;
				local bEquipReply = false;
				if(bRefreshBagFamily ~= false) then
					ItemManager.GetItemsInBag(bag, "UpdateBagAfterEquip_"..tostring(guid), function(msg2)
						bBagReply = true;
						if(bBagReply == true and bEquipReply == true) then
							-- update all page controls containing the pe:slot tag
							-- TODO: update only the PageCtrl with the same bag
							Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
							local item = ItemManager.GetItemByBagAndPosition(0, inventorytype);
							if(item and item.guid > 0 and type(item.OnMount) == "function") then
								item:OnMount();
							end
							callbackFunc(msg);
						end
					end, "access plus 1 minute");
				else
					bBagReply = true;
				end
				ItemManager.GetItemsInBag(0, "UpdateAvatarAfterEquip_"..tostring(guid), function(msg3)
					bEquipReply = true;
					if(bBagReply == true and bEquipReply == true) then
						-- update all page controls containing the pe:slot tag
						-- TODO: update only the PageCtrl with the same bag
						Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
						local item = ItemManager.GetItemByBagAndPosition(0, inventorytype);
						if(item and item.guid > 0 and type(item.OnMount) == "function") then
							item:OnMount();
						end
						callbackFunc(msg);
					end
				end, "access plus 1 minute");
			else
				callbackFunc(msg);
			end
		end);
	else
		LOG.std("", "warning","Item", "warning: bag id not found in local item cache, EquipItem abouted");
	end
end

-- unequip the item on the character slot position in bag 0
-- @param position: position in character slot bag 0
-- @param callbackFunc: the callback function(msg) end
function ItemManager.UnEquipItem(position, callbackFunc)
	-- TODO: lock the unequiped character slot, incase of multiple invoke
	
	local item = ItemManager.GetItemByBagAndPosition(0, position);
	if(item and item.gsid and item.guid > 0) then
		if(item.bag ~= 0) then
			LOG.std("", "error","Item", "try to unequip the item(guid:"..tostring(item.guid)..")in non-zero bag");
			return;
		end
	end
	
	local msg = {
		position = position,
	};
	paraworld.inventory.UnEquipItem(msg, "UnEquipItem_"..tostring(position), function(msg)
		if(msg.issuccess == true) then
			local item = ItemManager.GetItemByBagAndPosition(0, position);
			if(item and item.gsid and item.guid > 0) then
				-- call onunmount event of item first
				if(type(item.OnUnMount) == "function") then
					item:OnUnMount();
				end
				local gsItem = ItemManager.GetGlobalStoreItemInMemory(item.gsid);
				if(gsItem) then
					local bagfamily = gsItem.template.bagfamily;
					local bBagReply = false;
					local bEquipReply = false;
					ItemManager.GetItemsInBag(gsItem.template.bagfamily, "UpdateBagAfterPurchase", function(msg)
						bBagReply = true;
						if(bBagReply == true and bEquipReply == true) then
							-- update all page controls containing the pe:slot tag
							-- TODO: update only the PageCtrl with the same bag
							Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
							callbackFunc(msg);
						end
					end, "access plus 1 minute");
					ItemManager.GetItemsInBag(0, "UpdateAvatarAfterUnEquip", function(msg)
						bEquipReply = true;
						if(bBagReply == true and bEquipReply == true) then
							-- update all page controls containing the pe:slot tag
							-- TODO: update only the PageCtrl with the same bag
							Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
							callbackFunc(msg);
						end
					end, "access plus 1 minute");
				else
					callbackFunc(msg);
				end
			else
				callbackFunc(msg);
			end
		end
	end);
end

-- destroy item
-- @param guid: item instance id
-- @param count: purchase count
-- @param callbackFunc: the callback function(msg) end
function ItemManager.DestroyItem(guid, count, callbackFunc, callbackFunc2)
	local bag;
	if(ItemManager.items[guid]) then
		bag = ItemManager.items[guid].bag;
	end
	local msg = {
		guid = guid,
		count = count,
		bag = bag,
	};
	paraworld.inventory.DestroyItem(msg, "DestroyItem"..guid, function(msg)
		ItemManager.GetItemsInBag(bag, "UpdateBagAfterDestroy"..guid, function(msg2)
			-- update all page controls containing the pe:slot tag
			-- TODO: update only the PageCtrl with the same bag
			Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
			if(bag == 0) then
				-- refresh the items if the bag is 0, that is directly destroy the item on avatar
				ItemManager.RefreshMyself();
			end
			if(callbackFunc2) then
				callbackFunc2(msg);
			end
		end, "access plus 1 minute");
		if(callbackFunc)then
			callbackFunc(msg);
		end
	end);
end

-- sell item
-- @param guid: item instance id
-- @param count: purchase count
-- @param callbackFunc: the callback function(msg) end
function ItemManager.SellItem(guid, count, callbackFunc, callbackFunc2)
	local bag;
	if(ItemManager.items[guid]) then
		bag = ItemManager.items[guid].bag;
	end
	local canot_sell_gsids = {
		[999] = true, -- 999_ccsinfo_user
	};
	if(ItemManager.items[guid]) then
		local gsid = ItemManager.items[guid].gsid;
		if(gsid and canot_sell_gsids[gsid]) then
			-- can't sell item
			return;
		end
	end
	local msg = {
		guid = guid,
		cnt = count,
		bag = bag,
	};
	paraworld.inventory.SellItem(msg, "SellItem_"..guid, function(msg)
		ItemManager.GetItemsInBag(bag, "UpdateBagAfterSellItem_"..guid, function(msg2)
			if(msg.issuccess == true) then
				-- update the user info in memory, mainly emoney
				System.App.profiles.ProfileManager.GetUserInfo(nil, "UpdateUserInfoInMemoryAfterSellItem", function(msg) end);
			end
			-- update all page controls containing the pe:slot tag
			-- TODO: update only the PageCtrl with the same bag
			Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
			if(bag == 0) then
				-- refresh the items if the bag is 0, that is directly destroy the item on avatar
				ItemManager.RefreshMyself();
			end
			-- call hook for OnObtainItem
			local hook_msg = { aries_type = "OnSellItem", deltaemoney = msg.deltaemoney, wndName = "main"};
			CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);
			if(callbackFunc2) then
				callbackFunc2(msg);
			end
		end, "access plus 1 minute");
		callbackFunc(msg);
	end);
end

-- reset durability
-- @param guids: item instance id list
-- @param callbackFunc: the callback function(msg) end
function ItemManager.ResetDurability(guids, callbackFunc, callbackFunc2)
	local guid_str = "";
	local i, guid;
	for i, guid in pairs(guids) do
		guid_str = guid_str..guid..",";
	end
	if(guid_str == "") then
		log("error: ItemManager.ResetDurability got invalid guids\n");
		return;
	end
	local msg = {
		guids = guid_str,
	};
	paraworld.inventory.ResetDurability(msg, "ResetDurability_"..guid_str, function(msg)
		if(msg.issuccess == true) then
			-- update the user info in memory, mainly emoney
			System.App.profiles.ProfileManager.GetUserInfo(nil, "UpdateUserInfoInMemoryAfterResetDurability", function(msg) end);
		end
		local updated_bags = {};
		if(msg.issuccess == true and msg.updates) then
			local _, update;
			for _, update in pairs(msg.updates) do
				updated_bags[update.bag] = true;
			end
		end
		--refresh related bags
		local each_bag, _;
		for each_bag, _ in pairs(updated_bags) do
			ItemManager.GetItemsInBag(each_bag, "UpdateBagAfterResetDurability_"..each_bag, function(msg2)
				updated_bags[each_bag] = nil;
				if(not next(updated_bags)) then -- updated_bags is empty
					-- update all page controls containing the pe:slot tag
					-- TODO: update only the PageCtrl with the same bag
					Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
					if(callbackFunc2) then
						callbackFunc2(msg);
					end
				end
			end, "access plus 1 minute");
		end
		callbackFunc(msg);
	end);
end


-- check expire
-- @param guids: item instance id list
-- @param callbackFunc: the callback function(msg) end
function ItemManager.CheckExpire(guids, callbackFunc)
	local guid_str = "";
	local guid, _;
	for guid, _ in pairs(guids) do
		guid_str = guid_str..guid..",";
	end
	if(guid_str == "") then
		log("error: ItemManager.CheckExpire got invalid guids\n");
		return;
	end
	local msg = {
		guids = guid_str,
	};
	paraworld.inventory.CheckExpire(msg, "CheckExpire_"..guid_str, function(msg)
		callbackFunc(msg);
	end);
end

-- buy item with rmb
-- @param tonid: receiver nid
-- @param gsid: item gsid
-- @param cnt: buy count
-- @param pass: payment password
-- @param callbackFunc: the callback function(msg) end
function ItemManager.BuyWithRMB(tonid, gsid, cnt, pass, callbackFunc, timeoutTime, timeout_callback)
	if(not gsid or not cnt or not pass) then
		LOG.std("", "error", "Item", "ItemManager.BuyWithRMB got invalid input:"..commonlib.serialize({tonid, gsid, cnt, pass}));
		return;
	end
	local msg = {
		tonid = tonid or System.App.profiles.ProfileManager.GetNID(),
		gsid = gsid,
		cnt = cnt,
		pass = pass,
	};
	local refresh_bag = nil;
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid)
	if(gsItem) then
		refresh_bag = gsItem.template.bagfamily;
	end
	paraworld.inventory.BuyWithRMB(msg, "BuyWithRMB_"..tostring(gsid), function(msg)
		if(refresh_bag) then
			ItemManager.GetItemsInBag(refresh_bag, "UpdateBagAfterBuyWithRMB_"..tostring(gsid), function(msg2)
				LOG.std("", "info", "Item", "Bag:"..refresh_bag.." refreshed after ItemManager.BuyWithRMB");
				if(msg.issuccess == true) then
					-- call hook for OnPurchaseItemAfterGetItemsInBag
					local hook_msg = { aries_type = "OnPurchaseItemAfterGetItemsInBag", 
						gsid = gsid, count = cnt, 
						wndName = "main"};
					CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);
					-- update the user info in memory, mainly pmoney
					System.App.profiles.ProfileManager.GetUserInfo(nil, "UpdateUserInfoInMemoryAfterSellItem", function(msg) end, "access plus 0 day");
				end
				-- update all page controls containing the pe:slot tag
				-- TODO: update only the PageCtrl with the same bag
				Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
				if(refresh_bag == 0) then
					-- refresh the items if the bag is 0, that is directly destroy the item on avatar
					ItemManager.RefreshMyself();
				end
			end, "access plus 0 day");
		end
		callbackFunc(msg);
	end, nil, timeoutTime, timeout_callback);
end

function ItemManager.UseEnergyStoneEx(gsid, callbackFunc, callbackFunc2)
	local hasGSItem = ItemManager.IfOwnGSItem;
	local bHas, guid = hasGSItem(gsid or 998);
	if(not bHas) then
		LOG.std(nil, "error", "UseEnergyStoneEx", "no energy stone gsid %s exist in ItemManager.UseEnergyStone", tostring(gsid));
		return;
	end
	local pet_item = ItemManager.GetMyMountPetItem();
	if(not pet_item or pet_item.guid <= 0) then
		LOG.std(nil, "error", "UseEnergyStoneEx", "invalid pet item got in ItemManager.UseEnergyStone");
		return;
	end
	local bag;
	if(ItemManager.items[guid]) then
		bag = ItemManager.items[guid].bag;
	end
	local msg = {
		curnid = System.App.profiles.ProfileManager.GetNID(),
		nid = System.App.profiles.ProfileManager.GetNID(),
		petid = pet_item.guid,
		itemguid = guid,
		bag = 0,
	};
	paraworld.VIP.UseItemVIP(msg, "UseEnergyStone_"..guid, function(msg)
		-- force update the user info due to energy update
		log("info: force update user and dragon info after UseEnergyStone_\n")
		System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="ForceUpdateUserAndDragonInfo"});
		-- direct callback
		if(callbackFunc) then
			callbackFunc(msg);
		end
		-- force update pet info
		MyCompany.Aries.Pet.GetRemoteValue(nil, function() 
			-- bags need update;
			local bags_need_update = {};
			if(msg.updates) then
				local _, update;
				for _, update in pairs(msg.updates) do
					bags_need_update[update.bag] = true;
				end
			end
			if(msg.adds) then
				local _, add;
				for _, add in pairs(msg.adds) do
					bags_need_update[add.bag] = true;
				end
			end
			-- refresh all bag items need update
			local bag, _;
			for bag, _ in pairs(bags_need_update) do
				ItemManager.GetItemsInBag(bag, "UpdateBag_"..tostring(bag).."_AfterUseEnergyStone", function(msg)
					log("info: UpdateBag_"..tostring(bag).."_AfterUseEnergyStone returns:")
					commonlib.echo(msg);
					-- update all page controls containing the pe:slot tag
					-- TODO: update only the PageCtrl with the same bag
					Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
				end, "access plus 1 minutes");
			end
			-- force update user info
			ProfileManager.GetUserInfo(nil, "UpdateUserInfoInMemoryAfterUseEnergyStone", function(msg) 
				-- callback for ui update
				if(callbackFunc2) then
					callbackFunc2()
				end
			end, "access plus 1 minutes");
			-- refresh the avatar for magic star
			ItemManager.RefreshMyself();

		end, "access plus 0 day");
	end);
end

-- 998_EnergyStone
-- only applied to energy stone
-- @param callbackFunc: the callback function(msg) end
-- @param callbackFunc2: callback function that will invoke after every refresh is complete, refresh the UI here
function ItemManager.UseEnergyStone(callbackFunc, callbackFunc2)
	return ItemManager.UseEnergyStoneEx(998, callbackFunc, callbackFunc2)
end

-- 977_EnergyStoneShard
-- only applied to energy stone shard
-- @param callbackFunc: the callback function(msg) end
-- @param callbackFunc2: callback function that will invoke after every refresh is complete, refresh the UI here
function ItemManager.UseEnergyStoneShard(callbackFunc, callbackFunc2)
	return ItemManager.UseEnergyStoneEx(977, callbackFunc, callbackFunc2)
end

-- 967_EnergyStoneShard_1Day
-- only applied to energy stone shard
-- @param callbackFunc: the callback function(msg) end
-- @param callbackFunc2: callback function that will invoke after every refresh is complete, refresh the UI here
function ItemManager.UseEnergyStoneShard2(callbackFunc, callbackFunc2)
	return ItemManager.UseEnergyStoneEx(967, callbackFunc, callbackFunc2)
end

-- incremental id recording the MountGemInSocket api call sequence
local MountGemInSocket_seq = 1;

-- MountGemInSocket api invoke pool
local MountGemInSocket_pool = {};

-- MountGemInSocket time out time
local MountGemInSocket_timeout_time = 10000;

-- mount gem in socket callback function from power api
function ItemManager.MountGemInSocket_callback_from_powerapi(seq, msg)
	local input_msg = MountGemInSocket_pool[seq];
	local callbackFunc_after_bagrefresh;
	if(input_msg) then
		input_msg.callbackFunc(msg);
		callbackFunc_after_bagrefresh = input_msg.callbackFunc_after_bagrefresh;
		MountGemInSocket_pool[seq] = nil;
	end
	-- force update the bags
	local bags_need_refresh = {0,1,12};
	local bags = "";
	local i;
	for i = 1, #bags_need_refresh do
		bags = bags..bags_need_refresh[i]..",";
	end
	local refreshbag_return_count = 0;
	local msg = {
		bags = bags,
	};
	paraworld.inventory.GetItemsInBags(msg, nil, function(msg) 
		-- refresh the bag in local server cache
		local i;
		for i = 1, #bags_need_refresh do
			ItemManager.GetItemsInBag(bags_need_refresh[i], "RefreshBag_After_MountGemInSocket_callback_from_powerapi", function(msg)
				refreshbag_return_count = refreshbag_return_count + 1;
				if(refreshbag_return_count == #bags_need_refresh) then
					-- call bag refresh api return
					if(callbackFunc_after_bagrefresh) then
						callbackFunc_after_bagrefresh(msg);
					end
				end
			end, "access plus 1 minute");
		end
	end, "access plus 0 day", MountGemInSocket_timeout_time, function()
		MountGemInSocket_pool[seq] = nil;
	end); -- infact the cache policy is not applied in GetItemsInBags

	-- update the user info in memory, mainly emoney
	System.App.profiles.ProfileManager.GetUserInfo(nil, "UpdateUserInfoInMemoryAfterMountGemInSocket", function(msg) end, "access plus 0 day");
end

-- mount the gem into the item socket
-- @param gem_guid: gem guid
-- @param item_guid: item guid with socket
-- @param rune_guids: rune item instance id table, e.x.{[1001] = 3, [1002] = 1}, if no rune is provided use empty table {}
-- @param callbackFunc: the callback function(msg) end
-- @param callbackFunc_after_bagrefresh: callback function after the bag refresh
-- @param timeout_callback: time out callback function
function ItemManager.MountGemInSocket(gem_guid, item_guid, rune_guids, callbackFunc, callbackFunc_after_bagrefresh, timeout_callback)
	if(not gem_guid or not item_guid or not rune_guids or not callbackFunc) then
		LOG.std("", "error", "Item", "ItemManager.MountGemInSocket got invalid input:"..commonlib.serialize({gem_guid, item_guid, rune_guids, callbackFunc}));
		return;
	end
	
	MountGemInSocket_seq = MountGemInSocket_seq + 1;
	
	local msg = {
		seq = MountGemInSocket_seq,
		gem_guid = gem_guid,
		item_guid = item_guid,
		rune_guids = rune_guids,
	};
	
	System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="MountGemInSocket", params = msg});
	
	-- keep reference of the callback function and push to invoke pool
	msg.callbackFunc = callbackFunc;
	msg.callbackFunc_after_bagrefresh = callbackFunc_after_bagrefresh;
	MountGemInSocket_pool[MountGemInSocket_seq] = msg;

	-- start a timer for each api, if not returned in limited time call the timeout callback
	if(timeout_callback) then
		UIAnimManager.PlayCustomAnimation(MountGemInSocket_timeout_time, function(elapsedTime)
			if(elapsedTime == MountGemInSocket_timeout_time) then
				if(MountGemInSocket_pool[MountGemInSocket_seq]) then
					MountGemInSocket_pool[MountGemInSocket_seq] = nil;
				end
				timeout_callback();
			end
		end);
	end
end

-- incremental id recording the UnEquipGemFromSocket api call sequence
local UnEquipGemFromSocket_seq = 1;

-- UnEquipGemFromSocket api invoke pool
local UnEquipGemFromSocket_pool = {};

-- UnEquipGemFromSocket time out time
local UnEquipGemFromSocket_timeout_time = 10000;

-- mount gem in socket callback function from power api
function ItemManager.UnEquipGemFromSocket_callback_from_powerapi(seq, msg)
	local input_msg = UnEquipGemFromSocket_pool[seq];
	local callbackFunc_after_bagrefresh;
	if(input_msg) then
		input_msg.callbackFunc(msg);
		callbackFunc_after_bagrefresh = input_msg.callbackFunc_after_bagrefresh;
		UnEquipGemFromSocket_pool[seq] = nil;
	end
	-- force update the bags
	local bags_need_refresh = {0,1,12};
	local bags = "";
	local i;
	for i = 1, #bags_need_refresh do
		bags = bags..bags_need_refresh[i]..",";
	end
	local refreshbag_return_count = 0;
	local msg = {
		bags = bags,
	};
	paraworld.inventory.GetItemsInBags(msg, nil, function(msg) 
		-- refresh the bag in local server cache
		local i;
		for i = 1, #bags_need_refresh do
			ItemManager.GetItemsInBag(bags_need_refresh[i], "RefreshBag_After_UnEquipGemFromSocket_callback_from_powerapi", function(msg)
				refreshbag_return_count = refreshbag_return_count + 1;
				if(refreshbag_return_count == #bags_need_refresh) then
					-- call bag refresh api return
					if(callbackFunc_after_bagrefresh) then
						callbackFunc_after_bagrefresh(msg);
					end
				end
			end, "access plus 1 minute");
		end
	end, "access plus 0 day", UnEquipGemFromSocket_timeout_time, function()
		UnEquipGemFromSocket_pool[seq] = nil;
	end); -- infact the cache policy is not applied in GetItemsInBags

	-- update the user info in memory, mainly emoney
	System.App.profiles.ProfileManager.GetUserInfo(nil, "UpdateUserInfoInMemoryAfterUnEquipGemFromSocket", function(msg) end, "access plus 0 day");
end

-- unequip gem from item socket
-- @param gem_guid: gem guid
-- @param item_guid: item guid with socket
-- @param rune_guids: rune item instance id table, e.x.{[1001] = 3, [1002] = 1}, if no rune is provided use empty table {}
-- @param callbackFunc: the callback function(msg) end
-- @param callbackFunc_after_bagrefresh: callback function after the bag refresh
-- @param timeout_callback: time out callback function
function ItemManager.UnEquipGemFromSocket(gem_gsids, item_guid, callbackFunc, callbackFunc_after_bagrefresh, timeout_callback)
	if(not gem_gsids or not item_guid or not callbackFunc) then
		LOG.std("", "error", "Item", "ItemManager.UnEquipGemFromSocket got invalid input:"..commonlib.serialize({gem_gsids, item_guid, callbackFunc}));
		return;
	end
	
	UnEquipGemFromSocket_seq = UnEquipGemFromSocket_seq + 1;
	
	local msg = {
		seq = UnEquipGemFromSocket_seq,
		gem_gsids = gem_gsids,
		item_guid = item_guid,
	};
	
	System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="UnEquipGemFromSocket", params = msg});
	
	-- keep reference of the callback function and push to invoke pool
	msg.callbackFunc = callbackFunc;
	msg.callbackFunc_after_bagrefresh = callbackFunc_after_bagrefresh;
	UnEquipGemFromSocket_pool[UnEquipGemFromSocket_seq] = msg;

	-- start a timer for each api, if not returned in limited time call the timeout callback
	if(timeout_callback) then
		UIAnimManager.PlayCustomAnimation(UnEquipGemFromSocket_timeout_time, function(elapsedTime)
			if(elapsedTime == UnEquipGemFromSocket_timeout_time) then
				if(UnEquipGemFromSocket_pool[UnEquipGemFromSocket_seq]) then
					UnEquipGemFromSocket_pool[UnEquipGemFromSocket_seq] = nil;
				end
				timeout_callback();
			end
		end);
	end
end


-- incremental id recording the MountGemInSocket2 api call sequence for teen version
local MountGemInSocket2_seq = 1;

-- MountGemInSocket2 api invoke pool
local MountGemInSocket2_pool = {};

-- MountGemInSocket2 time out time
local MountGemInSocket2_timeout_time = 10000;

-- mount gem in socket callback function from power api
function ItemManager.MountGemInSocket2_callback_from_powerapi(seq, msg)
	local input_msg = MountGemInSocket2_pool[seq];
	local callbackFunc_after_bagrefresh;
	if(input_msg) then
		callbackFunc_after_bagrefresh = input_msg.callbackFunc_after_bagrefresh;
		MountGemInSocket2_pool[seq] = nil;
	end

	LOG.std(nil, "info", "MountGemInSocket2_callback_from_powerapi", msg);

	MountGemInSocket2_pool[seq] = nil;
	ItemManager.UpdateBagItems(msg.updates, msg.adds, msg.stats);

	if(input_msg and input_msg.callbackFunc) then
		input_msg.callbackFunc(msg);
	end
	if(callbackFunc_after_bagrefresh) then
		callbackFunc_after_bagrefresh(msg);
	end
end

-- mount the gem into the item socket for teen version
-- @param gem_guid: gem guid
-- @param item_guid: item guid with socket
-- @param rune_guids: rune item instance id table, e.x.{[1001] = 3, [1002] = 1}, if no rune is provided use empty table {}
-- @param callbackFunc: the callback function(msg) end
-- @param callbackFunc_after_bagrefresh: callback function after the bag refresh
-- @param timeout_callback: time out callback function
function ItemManager.MountGemInSocket2(gem_guid, item_guid, rune_guids, callbackFunc, callbackFunc_after_bagrefresh, timeout_callback)
	if(not gem_guid or not item_guid or not rune_guids) then
		LOG.std("", "error", "Item", "ItemManager.MountGemInSocket2 got invalid input:"..commonlib.serialize({gem_guid, item_guid, rune_guids, callbackFunc}));
		return;
	end
	
	MountGemInSocket2_seq = MountGemInSocket2_seq + 1;
	
	local msg = {
		seq = MountGemInSocket2_seq,
		gem_guid = gem_guid,
		item_guid = item_guid,
		rune_guids = rune_guids,
	};
	
	System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="MountGemInSocket2", params = msg});
	
	-- keep reference of the callback function and push to invoke pool
	msg.callbackFunc = callbackFunc;
	msg.callbackFunc_after_bagrefresh = callbackFunc_after_bagrefresh;
	MountGemInSocket2_pool[MountGemInSocket2_seq] = msg;

	-- start a timer for each api, if not returned in limited time call the timeout callback
	if(timeout_callback) then
		UIAnimManager.PlayCustomAnimation(MountGemInSocket2_timeout_time, function(elapsedTime)
			if(elapsedTime == MountGemInSocket2_timeout_time) then
				if(MountGemInSocket2_pool[MountGemInSocket2_seq]) then
					MountGemInSocket2_pool[MountGemInSocket2_seq] = nil;
				end
				timeout_callback();
			end
		end);
	end
end

-- incremental id recording the UnEquipGemFromSocket2 api call sequence for teen version
local UnEquipGemFromSocket2_seq = 1;

-- UnEquipGemFromSocket2 api invoke pool
local UnEquipGemFromSocket2_pool = {};

-- UnEquipGemFromSocket2 time out time
local UnEquipGemFromSocket2_timeout_time = 10000;

-- mount gem in socket callback function from power api
function ItemManager.UnEquipGemFromSocket2_callback_from_powerapi(seq, msg)
	local input_msg = UnEquipGemFromSocket2_pool[seq];
	local callbackFunc_after_bagrefresh;
	if(input_msg) then
		callbackFunc_after_bagrefresh = input_msg.callbackFunc_after_bagrefresh;
		UnEquipGemFromSocket2_pool[seq] = nil;
	end
	LOG.std(nil, "info", "UnEquipGemFromSocket2_callback_from_powerapi", msg);
	
	if(msg.issuccess) then
		ItemManager.UpdateBagItems(msg.updates, msg.adds, msg.stats);
	end

	if(input_msg and input_msg.callbackFunc) then
		input_msg.callbackFunc(msg);
	end
	if(callbackFunc_after_bagrefresh) then
		callbackFunc_after_bagrefresh(msg);
	end
end

-- unequip gem from item socket for teen version
-- @param gem_guid: gem guid
-- @param item_guid: item guid with socket
-- @param rune_guids: rune item instance id table, e.x.{[1001] = 3, [1002] = 1}, if no rune is provided use empty table {}
-- @param callbackFunc: the callback function(msg) end
-- @param callbackFunc_after_bagrefresh: callback function after the bag refresh
-- @param timeout_callback: time out callback function
function ItemManager.UnEquipGemFromSocket2(gem_gsids, item_guid, callbackFunc, callbackFunc_after_bagrefresh, timeout_callback)
	if(not gem_gsids or not item_guid) then
		LOG.std("", "error", "Item", "ItemManager.UnEquipGemFromSocket2 got invalid input:"..commonlib.serialize({gem_gsids, item_guid, callbackFunc}));
		return;
	end
	
	UnEquipGemFromSocket2_seq = UnEquipGemFromSocket2_seq + 1;
	
	local msg = {
		seq = UnEquipGemFromSocket2_seq,
		gem_gsids = gem_gsids,
		item_guid = item_guid,
	};
	
	System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="UnEquipGemFromSocket2", params = msg});
	
	-- keep reference of the callback function and push to invoke pool
	msg.callbackFunc = callbackFunc;
	msg.callbackFunc_after_bagrefresh = callbackFunc_after_bagrefresh;
	UnEquipGemFromSocket2_pool[UnEquipGemFromSocket2_seq] = msg;

	-- start a timer for each api, if not returned in limited time call the timeout callback
	if(timeout_callback) then
		UIAnimManager.PlayCustomAnimation(UnEquipGemFromSocket2_timeout_time, function(elapsedTime)
			if(elapsedTime == UnEquipGemFromSocket2_timeout_time) then
				if(UnEquipGemFromSocket2_pool[UnEquipGemFromSocket2_seq]) then
					UnEquipGemFromSocket2_pool[UnEquipGemFromSocket2_seq] = nil;
				end
				timeout_callback();
			end
		end);
	end
end

-- incremental id recording the DestroyCardToMagicDirt api call sequence for teen version
local DestroyCardToMagicDirt_seq = 1;

-- DestroyCardToMagicDirt api invoke pool
local DestroyCardToMagicDirt_pool = {};

-- DestroyCardToMagicDirt time out time
local DestroyCardToMagicDirt_timeout_time = 10000;

-- mount gem in socket callback function from power api
function ItemManager.DestroyCardToMagicDirt_callback_from_powerapi(seq, msg)
	local input_msg = DestroyCardToMagicDirt_pool[seq];
	local callbackFunc_after_bagrefresh;
	if(input_msg) then
		callbackFunc_after_bagrefresh = input_msg.callbackFunc_after_bagrefresh;
		DestroyCardToMagicDirt_pool[seq] = nil;
	end
	LOG.std(nil, "info", "DestroyCardToMagicDirt_callback_from_powerapi", msg);
	
	if(msg.issuccess) then
		ItemManager.UpdateBagItems(msg.updates, msg.adds, msg.stats);
	end

	if(input_msg and input_msg.callbackFunc) then
		input_msg.callbackFunc(msg);
	end
	if(callbackFunc_after_bagrefresh) then
		callbackFunc_after_bagrefresh(msg);
	end
end

-- destroy rune to MagicDirt
-- @param rune_guid: rune guid
-- @param rune_gsid: rune gsid
-- @param callbackFunc: the callback function(msg) end
-- @param callbackFunc_after_bagrefresh: callback function after the bag refresh
-- @param timeout_callback: time out callback function
function ItemManager.DestroyCardToMagicDirt(card_guid, card_gsid, card_count, callbackFunc, callbackFunc_after_bagrefresh, timeout_callback)
	if(not card_gsid or not card_guid or not card_count) then
		LOG.std("", "error", "Item", "ItemManager.DestroyCardToMagicDirt got invalid input:"..commonlib.serialize({card_gsid, card_guid, card_count, callbackFunc}));
		return;
	end
	
	DestroyCardToMagicDirt_seq = DestroyCardToMagicDirt_seq + 1;
	
	local msg = {
		seq = DestroyCardToMagicDirt_seq,
		card_guid = card_guid,
		card_gsid = card_gsid,
		card_count = card_count,
	};
	
	System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="DestroyCardToMagicDirt", params = msg});
	
	-- keep reference of the callback function and push to invoke pool
	msg.callbackFunc = callbackFunc;
	msg.callbackFunc_after_bagrefresh = callbackFunc_after_bagrefresh;
	DestroyCardToMagicDirt_pool[DestroyCardToMagicDirt_seq] = msg;

	-- start a timer for each api, if not returned in limited time call the timeout callback
	if(timeout_callback) then
		UIAnimManager.PlayCustomAnimation(DestroyCardToMagicDirt_timeout_time, function(elapsedTime)
			if(elapsedTime == DestroyCardToMagicDirt_timeout_time) then
				if(DestroyCardToMagicDirt_pool[DestroyCardToMagicDirt_seq]) then
					DestroyCardToMagicDirt_pool[DestroyCardToMagicDirt_seq] = nil;
				end
				timeout_callback();
			end
		end);
	end
end

-- incremental id recording the DirectlyOpenCardPack api call sequence for teen version
local DirectlyOpenCardPack_seq = 1;

-- DirectlyOpenCardPack api invoke pool
local DirectlyOpenCardPack_pool = {};

-- DirectlyOpenCardPack time out time
local DirectlyOpenCardPack_timeout_time = 10000;

-- mount gem in socket callback function from power api
function ItemManager.DirectlyOpenCardPack_callback_from_powerapi(seq, msg)
	local input_msg = DirectlyOpenCardPack_pool[seq];
	local callbackFunc_after_bagrefresh;
	if(input_msg) then
		callbackFunc_after_bagrefresh = input_msg.callbackFunc_after_bagrefresh;
		DirectlyOpenCardPack_pool[seq] = nil;
	end
	LOG.std(nil, "info", "DirectlyOpenCardPack_callback_from_powerapi", msg);
	
	if(msg.issuccess) then
		local items_to_add = ItemManager.UpdateBagItems(msg.updates, msg.adds, msg.stats, "DirectlyOpenCardPack_callback_from_powerapi");
		--NPL.load("(gl)script/apps/Aries/Inventory/Cards/CardsUnpackPage.lua");
		--local CardsUnpackPage = commonlib.gettable("MyCompany.Aries.Inventory.Cards.CardsUnpackPage");
		--CardsUnpackPage.DoRoll_Handle(items_to_add);
		NPL.load("(gl)script/apps/Aries/Inventory/Cards/MagicCardShopPage.lua");
		local MagicCardShopPage = commonlib.gettable("MyCompany.Aries.Inventory.Cards.MagicCardShopPage");
		MagicCardShopPage.OpenCardpack_Handle(items_to_add);
	end

	if(input_msg and input_msg.callbackFunc) then
		input_msg.callbackFunc(msg);
	end
	if(callbackFunc_after_bagrefresh) then
		callbackFunc_after_bagrefresh(msg);
	end
end

-- directly open card pack
-- @param cardpack_gsid: card pack gsid
-- @param callbackFunc: the callback function(msg) end
-- @param callbackFunc_after_bagrefresh: callback function after the bag refresh
-- @param timeout_callback: time out callback function
function ItemManager.DirectlyOpenCardPack(cardpack_gsid, callbackFunc, callbackFunc_after_bagrefresh, timeout_callback)
	if(not cardpack_gsid) then
		LOG.std("", "error", "Item", "ItemManager.DirectlyOpenCardPack got invalid input:"..commonlib.serialize({cardpack_gsid, callbackFunc}));
		return;
	end
	
	DirectlyOpenCardPack_seq = DirectlyOpenCardPack_seq + 1;
	
	local msg = {
		seq = DirectlyOpenCardPack_seq,
		gsid = cardpack_gsid,
	};
	
	System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="DirectlyOpenCardPack", params = msg});
	
	-- keep reference of the callback function and push to invoke pool
	msg.callbackFunc = callbackFunc;
	msg.callbackFunc_after_bagrefresh = callbackFunc_after_bagrefresh;
	DirectlyOpenCardPack_pool[DirectlyOpenCardPack_seq] = msg;

	-- start a timer for each api, if not returned in limited time call the timeout callback
	if(timeout_callback) then
		UIAnimManager.PlayCustomAnimation(DirectlyOpenCardPack_timeout_time, function(elapsedTime)
			if(elapsedTime == DirectlyOpenCardPack_timeout_time) then
				if(DirectlyOpenCardPack_pool[DirectlyOpenCardPack_seq]) then
					DirectlyOpenCardPack_pool[DirectlyOpenCardPack_seq] = nil;
				end
				timeout_callback();
			end
		end);
	end
end

-- craft gem
-- @param froms: gem item instance id table, e.x.{[1001] = 3, [1002] = 1}, if no rune is provided use empty table {}
-- @param to_gsid: to gem gsid
-- @param callbackFunc: the callback function(msg) end
-- @param callbackFunc_after_bagrefresh: callback function after the bag refresh, is process is not successful this callback will not be invoked
-- @param timeout_callback: time out callback function
function ItemManager.CraftGem(froms, to_gsid, callbackFunc, callbackFunc_after_bagrefresh, timeout_callback)
	if(not froms or not to_gsid) then
		LOG.std("", "error", "Item", "ItemManager.CraftGem got invalid input:"..commonlib.serialize({froms, to_gsid}));
		return;
	end
	-- make the rune guid string
	local froms_guids_str = "";
	local from_guid, from_cnt;
	local isFirst = true;
	for from_guid, from_cnt in pairs(froms) do
		if(isFirst == true) then
			froms_guids_str = from_guid..","..from_cnt;
		else
			froms_guids_str = froms_guids_str.."|"..from_guid..","..from_cnt;
		end
		isFirst = false;
	end
	
	local msg = {
		froms = froms_guids_str,
		togsid = to_gsid,
	};
	
	paraworld.inventory.MergeGem(msg, "CraftGem_"..to_gsid, function(msg)
		callbackFunc(msg);
		if(msg.issuccess) then
			-- force update the bags
			local bags_need_refresh = {12};
			local bags = "";
			local i;
			for i = 1, #bags_need_refresh do
				bags = bags..bags_need_refresh[i]..",";
			end
			local refreshbag_return_count = 0;
			local msg = {
				bags = bags,
			};
			paraworld.inventory.GetItemsInBags(msg, "CraftGem_callback_from_powerapi", function(msg) 
				-- refresh the bag in local server cache
				local i;
				for i = 1, #bags_need_refresh do
					ItemManager.GetItemsInBag(bags_need_refresh[i], "RefreshBag_After_MergeGem", function(msg)
						refreshbag_return_count = refreshbag_return_count + 1;
						if(refreshbag_return_count == #bags_need_refresh) then
							-- call bag refresh api return
							callbackFunc_after_bagrefresh(msg);
						end
					end, "access plus 0 day");
				end
			end, "access plus 0 day"); -- infact the cache policy is not applied in GetItemsInBags

			-- update the user info in memory, mainly emoney
			System.App.profiles.ProfileManager.GetUserInfo(nil, "UpdateUserInfoInMemoryAfterCraftGem", function(msg) end, "access plus 0 day");
		end
	end, nil, timeout, timeout_callback);
end

-- craft gem2 for teen version
-- @param froms: gem item instance id table, e.x.{[1001] = 3, [1002] = 1}, if no rune is provided use empty table {}
-- @param to_gsid: to gem gsid
-- @param callbackFunc: the callback function(msg) end
-- @param callbackFunc_after_bagrefresh: callback function after the bag refresh, is process is not successful this callback will not be invoked
-- @param timeout_callback: time out callback function
function ItemManager.CraftGem2(froms, to_gsid, callbackFunc, callbackFunc_after_bagrefresh, timeout_callback)
	if(not froms or not to_gsid) then
		LOG.std("", "error", "Item", "ItemManager.CraftGem got invalid input:"..commonlib.serialize({froms, to_gsid}));
		return;
	end
	-- make the rune guid string
	local froms_guids_str = "";
	local from_guid, from_cnt;
	local isFirst = true;
	for from_guid, from_cnt in pairs(froms) do
		if(isFirst == true) then
			froms_guids_str = from_guid..","..from_cnt;
		else
			froms_guids_str = froms_guids_str.."|"..from_guid..","..from_cnt;
		end
		isFirst = false;
	end
	
	local msg = {
		froms = froms_guids_str,
		togsid = to_gsid,
	};
	
	paraworld.inventory.MergeGem2(msg, "CraftGem_"..to_gsid, function(msg)
		callbackFunc(msg);
		if(msg.issuccess) then
			-- force update the bags
			local bags_need_refresh = {12};
			local bags = "";
			local i;
			for i = 1, #bags_need_refresh do
				bags = bags..bags_need_refresh[i]..",";
			end
			local refreshbag_return_count = 0;
			local msg_bags = {
				bags = bags,
			};
			paraworld.inventory.GetItemsInBags(msg_bags, "CraftGem_callback_from_powerapi", function(msg2) 
				-- refresh the bag in local server cache
				local i;
				for i = 1, #bags_need_refresh do
					ItemManager.GetItemsInBag(bags_need_refresh[i], "RefreshBag_After_MergeGem2", function(msg3)
						refreshbag_return_count = refreshbag_return_count + 1;
						if(refreshbag_return_count == #bags_need_refresh) then
							-- call bag refresh api return
							callbackFunc_after_bagrefresh(msg);
						end
					end, "access plus 0 day");
				end
			end, "access plus 0 day"); -- infact the cache policy is not applied in GetItemsInBags

			-- update the user info in memory, mainly emoney
			System.App.profiles.ProfileManager.GetUserInfo(nil, "UpdateUserInfoInMemoryAfterCraftGem", function(msg) end, "access plus 0 day");
		end
	end, nil, timeout, timeout_callback);
end

-- CreateGemHole for teen version
-- @param guid: item guid
-- @param callbackFunc: the callback function(msg) end
-- @param callbackFunc_after_bagrefresh: callback function after the bag refresh, is process is not successful this callback will not be invoked
-- @param timeout_callback: time out callback function
function ItemManager.CreateGemHole(guid, callbackFunc, callbackFunc_after_bagrefresh, timeout_callback)
	
	do return end

	if(not guid) then
		LOG.std("", "error", "Item", "ItemManager.CreateGemHole got invalid input:"..commonlib.serialize(guid));
		return;
	end
	
	local msg = {
		guid = guid,
	};
	
	paraworld.inventory.CreateGemHole(msg, "CreateGemHole_"..guid, function(msg)
		callbackFunc(msg);
		if(msg.issuccess) then
			-- force update the bags
			local bags_need_refresh = {0,1,12}; -- 12 for 17177_CraftSlotCharm
			local bags = "";
			local i;
			for i = 1, #bags_need_refresh do
				bags = bags..bags_need_refresh[i]..",";
			end
			local refreshbag_return_count = 0;
			local msg = {
				bags = bags,
			};
			paraworld.inventory.GetItemsInBags(msg, "CreateGemHole_callback_from_powerapi", function(msg) 
				-- refresh the bag in local server cache
				local i;
				for i = 1, #bags_need_refresh do
					ItemManager.GetItemsInBag(bags_need_refresh[i], "RefreshBag_After_CreateGemHole", function(msg)
						refreshbag_return_count = refreshbag_return_count + 1;
						if(refreshbag_return_count == #bags_need_refresh) then
							-- call bag refresh api return
							callbackFunc_after_bagrefresh(msg);
						end
					end, "access plus 1 minute");
				end
			end, "access plus 0 day"); -- infact the cache policy is not applied in GetItemsInBags

			-- update the user info in memory, mainly emoney
			System.App.profiles.ProfileManager.GetUserInfo(nil, "UpdateUserInfoInMemoryAfterCreateGemHole", function(msg) end, "access plus 0 day");
		end
	end, nil, timeout, timeout_callback);
end

-- CreateGemHole for teen version
-- @param guid: item guid
-- @param callbackFunc: the callback function(msg) end
-- @param callbackFunc_after_bagrefresh: callback function after the bag refresh, is process is not successful this callback will not be invoked
-- @param timeout_callback: time out callback function
function ItemManager.ChangeLuck(callbackFunc, callbackFunc_after_bagrefresh, timeout_callback)
	
	local msg = {
	};
	
	paraworld.users.ChangeLuck(msg, nil, function(msg)
		callbackFunc(msg);
		if(msg.luck) then
			-- force update the bags
			local bags_need_refresh = {12}; -- 12 for 17028_GoodLuckGem
			local bags = "";
			local i;
			for i = 1, #bags_need_refresh do
				bags = bags..bags_need_refresh[i]..",";
			end
			local refreshbag_return_count = 0;
			local msg = {
				bags = bags,
			};
			paraworld.inventory.GetItemsInBags(msg, "ChangeLuck_callback_from_powerapi", function(msg) 
				-- refresh the bag in local server cache
				local i;
				for i = 1, #bags_need_refresh do
					ItemManager.GetItemsInBag(bags_need_refresh[i], "RefreshBag_After_ChangeLuck", function(msg)
						refreshbag_return_count = refreshbag_return_count + 1;
						if(refreshbag_return_count == #bags_need_refresh) then
							-- call bag refresh api return
							if(callbackFunc_after_bagrefresh) then
								callbackFunc_after_bagrefresh(msg);
							end
						end
					end, "access plus 1 minute");
				end
			end, "access plus 0 day"); -- infact the cache policy is not applied in GetItemsInBags

			-- update the user info in memory, mainly emoney
			System.App.profiles.ProfileManager.GetUserInfo(nil, "UpdateUserInfoInMemoryAfterChangeLuck", function(msg) end, "access plus 0 day");
		end
	end, nil, timeout, timeout_callback);
end

-- incremental id recording the ItemSetExtendedCost api call sequence
local ItemSetExtendedCost_seq = 1;

-- ItemSetExtendedCost api invoke pool
local ItemSetExtendedCost_pool = {};

-- ItemSetExtendedCost time out time
local ItemSetExtendedCost_timeout_time = 10000;

-- mount gem in socket callback function from power api
function ItemManager.ItemSetExtendedCost_callback_from_powerapi(seq, msg)
	local input_msg = ItemSetExtendedCost_pool[seq];
	local callbackFunc_after_bagrefresh;
	if(input_msg) then
		input_msg.callbackFunc(msg);
		callbackFunc_after_bagrefresh = input_msg.callbackFunc_after_bagrefresh
		ItemSetExtendedCost_pool[seq] = nil;
	end
	-- force update the bags
	local bags_need_refresh = {0,1,12};
	local bags = "";
	local i;
	for i = 1, #bags_need_refresh do
		bags = bags..bags_need_refresh[i]..",";
	end
	local refreshbag_return_count = 0;
	local msg = {
		bags = bags,
	};
	paraworld.inventory.GetItemsInBags(msg, "ItemSetExtendedCost_callback_from_powerapi", function(msg) 
		-- refresh the bag in local server cache
		local i;
		for i = 1, #bags_need_refresh do
			ItemManager.GetItemsInBag(bags_need_refresh[i], "RefreshBag_After_ItemSetExtendedCost_callback_from_powerapi", function(msg)
				refreshbag_return_count = refreshbag_return_count + 1;
				if(refreshbag_return_count == #bags_need_refresh) then
					-- call bag refresh api return
					if(callbackFunc_after_bagrefresh) then
						callbackFunc_after_bagrefresh(msg);
					end
				end
			end, "access plus 0 day");
		end
	end, "access plus 0 day", ItemSetExtendedCost_timeout_time, function()
		ItemSetExtendedCost_pool[seq] = nil;
	end); -- infact the cache policy is not applied in GetItemsInBags
	
	-- update the user info in memory, mainly emoney
	System.App.profiles.ProfileManager.GetUserInfo(nil, "UpdateUserInfoInMemoryAfterItemSetExtendedCost",  function(msg) end, "access plus 0 day");
end

-- exchange the item set items
-- @param item_gsid: item gsid
-- @param callbackFunc: the callback function(msg) end
-- @param callbackFunc_after_bagrefresh: callback function after the bag refresh
-- @param timeout_callback: time out callback function
function ItemManager.ItemSetExtendedCost(item_gsid, callbackFunc, callbackFunc_after_bagrefresh, timeout_callback)
	if(not item_gsid or not callbackFunc) then
		LOG.std("", "error", "Item", "ItemManager.ItemSetExtendedCost got invalid input:"..commonlib.serialize({item_gsid, callbackFunc}));
		return;
	end
	
	ItemSetExtendedCost_seq = ItemSetExtendedCost_seq + 1;
	
	local msg = {
		seq = ItemSetExtendedCost_seq,
		gsid = item_gsid,
	};
	
	System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="ItemSetExtendedCost", params = msg});
	
	-- keep reference of the callback function and push to invoke pool
	msg.callbackFunc = callbackFunc;
	msg.callbackFunc_after_bagrefresh = callbackFunc_after_bagrefresh;
	ItemSetExtendedCost_pool[ItemSetExtendedCost_seq] = msg;

	-- start a timer for each api, if not returned in limited time call the timeout callback
	if(timeout_callback) then
		UIAnimManager.PlayCustomAnimation(ItemSetExtendedCost_timeout_time, function(elapsedTime)
			if(elapsedTime == ItemSetExtendedCost_timeout_time) then
				if(ItemSetExtendedCost_pool[ItemSetExtendedCost_seq]) then
					ItemSetExtendedCost_pool[ItemSetExtendedCost_seq] = nil;
				end
				timeout_callback();
			end
		end);
	end
end

-- get the equiped items of a given user
-- @param nid: user nid
-- @param callbackFunc: the callback function(msg) end
-- @cache_policy: cache policy
function ItemManager.GetEquips(nid, callbackFunc, cache_policy)
	local msg = {
		nids = tostring(nid)..",",
	};
	-- TODO: add cache policy to GetEquips
	paraworld.inventory.GetEquips(msg, "GetEquips" or ("GetEquips"..nid), function(msg)
		LOG.std("", "system","Item", "paraworld.inventory.GetEquips:"..LOG.tostring(msg));
		callbackFunc(msg);
	end);
end

-- get expire remaining time in seconds
-- @param item: any item object
-- @return: total_minutes, days, hours, minutes (days + hours + minutes is total time)
function ItemManager.ExpireRemainingTime(item)
	if(not item or not item.gsid or not item.guid or not item.obtaintime) then
		return;
	end
    
    local expiredays;
    local expirehours = 0;
	local bIgnore_obtainday_elapsed_minutes = false;
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(item.gsid);
    if(gsItem)then
		if(gsItem.template.expiretype == 1 and gsItem.template.expiretime) then
			expiredays = gsItem.template.expiretime;
		end
		if(gsItem.template.expiretype == 2 and gsItem.template.expiretime) then
			expiredays = 0;
			expirehours = gsItem.template.expiretime;
		end
		if(gsItem.template.expiretype == 3 and gsItem.template.expiretime) then
			expiredays = gsItem.template.expiretime;
			bIgnore_obtainday_elapsed_minutes = true;
		end
		if(gsItem.template.expiretype == 5) then
			if(item.obtaintime) then
				local obtain_year, obtain_month, obtain_day, obtain_hour, obtain_mins = string.match(item.obtaintime, "^(%d-)%-(%d-)%-(%d-)%D(%d+)%D(%d+)");
				obtain_year = tonumber(obtain_year);
				obtain_month = tonumber(obtain_month);
				local days_number = commonlib.timehelp.get_days_number_in_month(obtain_year,obtain_month);
				if(days_number) then
					local serverdate = MyCompany.Aries.Scene.GetServerDate() or ParaGlobal.GetDateFormat("yyyy-MM-dd");
					local cur_year, cur_month, cur_day = string.match(serverdate, "^(%d+)%-(%d+)%-(%d+)$");
					cur_day = tonumber(cur_day);
					expiredays = days_number - cur_day + 1;
				end
				bIgnore_obtainday_elapsed_minutes = true;
			end
			
		end
    end

    if(item.obtaintime and expiredays) then
        local year, month, day, hour, mins = string.match(item.obtaintime, "^(%d-)%-(%d-)%-(%d-)%D(%d+)%D(%d+)");
		if(year and month and day and hour and mins) then
			year = tonumber(year)
			month = tonumber(month)
			day = tonumber(day)
			hour = tonumber(hour)
			mins = tonumber(mins)
            if(year and month and day and hour and mins) then
                local daysfrom_1900_1_1 = commonlib.GetDaysFrom_1900_1_1(year, month, day);
                local serverdate = MyCompany.Aries.Scene.GetServerDate() or ParaGlobal.GetDateFormat("yyyy-MM-dd");
				local obtainday_elapsed_minutes = hour * 60 + mins;
                local year, month, day = string.match(serverdate, "^(%d+)%-(%d+)%-(%d+)$");
		        if(year and month and day) then
			        year = tonumber(year)
			        month = tonumber(month)
			        day = tonumber(day)
                    if(year and month and day) then
                        local daysfrom_1900_1_1_today = commonlib.GetDaysFrom_1900_1_1(year, month, day);
                        if(daysfrom_1900_1_1_today and daysfrom_1900_1_1) then
							
							local days_left = daysfrom_1900_1_1 + expiredays - daysfrom_1900_1_1_today;
							if(gsItem.template.expiretype == 5) then
								days_left = expiredays - 1;
							end
							hour = tonumber(hour);
							mins = tonumber(mins);

							local now_server_seconds = MyCompany.Aries.Scene.GetElapsedSecondsSince0000();
							if(now_server_seconds) then
								local now_server_mins = math.floor(now_server_seconds / 60);

								if(bIgnore_obtainday_elapsed_minutes) then
									obtainday_elapsed_minutes = 0;
								end

								local total_minutes;
								total_minutes = days_left * 24 * 60 + expirehours * 60 + obtainday_elapsed_minutes - now_server_mins;
								if(gsItem.template.expiretype == 5) then
									total_minutes = days_left * 24 * 60 + 24 * 60 - now_server_mins;
								end
								if(total_minutes) then
									local all_times = total_minutes;
									local remaining_days = math.floor(all_times / (24 * 60));
									all_times = all_times - remaining_days * 24 * 60;
									local remaining_hours = math.floor(all_times / (60));
									all_times = all_times - remaining_hours * 60;
									local remaining_mins = all_times;
									return total_minutes, remaining_days, remaining_hours, remaining_mins;
								end
							end
                        end
                    end
                end
            end
        end
    end
end

-- set clientdata for a given item
-- @param guid: item instance id
-- @param clientdata: client data
-- @param callbackFunc: the callback function(msg) end
-- @param (optional)bag: if the bag is not specified, user the item in memory
-- @param timeout: timeout time
-- @param timeout_callback: timeout callback
-- @param bMemoryDBOnly: skip the network setclientdata invoke, the fact is if it is skipped, it is then reset in the next paraworld.inventory.GetItemsInBag
--
-- NOTE: clientdata setting is immediately valid, the remote calls won't effect the data in memory, 
--		once failed setting the data, it will automatically set again according to the current clientdata in memory
--		Auto re-set logic are implemented in paraworld.inventory.GetItemsInBag and paraworld.inventory.SetClientData
--		pre function and post function
function ItemManager.SetClientData(guid, clientdata, callbackFunc, bag, timeout, timeout_callback, bMemoryDBOnly, bForceNILQuenename)
	--if(string.find(clientdata, "%$")) then
		--log("ERROR: the clientdata should not contains any $ character\n")
		----NOTE: leio homeland clientdata contains some $ character
		--return;
	--end
	
	if(bag == nil) then
		local item = ItemManager.GetItemByGUID(guid);
		if(item and item.guid > 0 and item.bag) then
			bag = item.bag;
		end
	end
	if(bag) then
		local msg = {
			guid = guid,
			bag = bag,
			clientdata = clientdata,
			bMemoryDBOnly = bMemoryDBOnly,
		};
		local item = ItemManager.GetItemByGUID(guid);
		if(item and item.guid > 0) then
			item.clientdata = clientdata;
		end
		local id = ParaGlobal.GenerateUniqueID();
		paraworld.inventory.SetClientData(msg, if_else(bForceNILQuenename, nil, "SetClientData"), function(msg)
			LOG.std("", "system","Item", "+++++++ SetClientData with "..tostring(clientdata).." for guid:"..guid.." returns +++++++"..LOG.tostring(msg));
			callbackFunc(msg);
		end, nil, timeout, timeout_callback);
	end
end

----------------------------------------
-- Homeland related functions
----------------------------------------

ItemManager.homeland_bag = 10001;

-- visit and manage homeland process:
-- 1 load all the items in the homeland bag 10001    ItemManager.GetItemsInBag(10001)
-- 2 visualize the items to the homeland with client data    for item.clientdata in items
-- 3 update the item status to the homeland with server data    for item.serverdata in items
-- 4 load the item status from homeland app server    for item in items get server data
-- 5 

-- get HomeLand items
-- NOTE: this function is called immedately after the SaveHomeLandItems process, so be sure this reload will not affect any teleport
-- @param nid: nid of the homeland owner
-- @param bag: homeland bag, it could be number or "outdoor" or "indoor"
-- @param callbackFunc: callback function that will be called after the loading process
-- @param cache_policy: cache_policy of the outdoor load, default "access plus 0 day"
function ItemManager.LoadHomeLandItems(nid, callbackFunc, cache_policy)
	cache_policy = cache_policy or "access plus 0 day";
	--if(type(bag) == "string") then
		--if(string.lower(bag) == "outdoor") then
			--bag = 10001;
		--elseif(string.lower(bag) == "indoor") then
			--bag = 10002;
		--else
			--bag = tonumber(bag);
		--end
	--end
	--if(not bag) then
		--log("error: not valid bag got in ItemManager.LoadHomeLandItems\n");
		--return;
	--end
	local bag = ItemManager.homeland_bag;
	if(nid == nil or nid == System.App.profiles.ProfileManager.GetNID()) then
		ItemManager.GetItemsInBag(bag, "LoadMyHomeLandOutdoorItems", function(msg)
			callbackFunc(msg);
		end, cache_policy);
	else
		ItemManager.GetItemsInOPCBag(nid, bag, "LoadOPCHomeLandOutdoorItems", function(msg)
			callbackFunc(msg);
		end, cache_policy);
	end
end

-- save homeland items, all modifications will be posted to the item system
-- we strongly recommend to modify the items between the BeginHomeLandEditing() and EndHomeLandEditing() pair
-- and call this function immediately after EndHomeLandEditing()
-- @param callbackFunc: callback function that will be called after the saving process
--		if callbackFunc(true), all items are saved properly
--		if callbackFunc(false), saving has failed at least once
-- NOTE: there is a trick that before the next BeginHomeLandEditing() call, 
--		ItemManager.PendingHomeLandModification contains all the issuccess reply of each modified items.
--		One can manually check which item is failed to set the clientdata.
function ItemManager.SaveHomeLandItems(callbackFunc)
	local isReplieds = {};
	local guids = {};
	local guid, _;
	for guid, _ in pairs(ItemManager.PendingHomeLandModification) do
		isReplieds[guid] = false;
		table.insert(guids, guid);
	end
	
	if(#guids == 0) then
		-- nothing changed
		callbackFunc(true);
		return;
	end
	local bHasFailed = false;
	
	local callbackFunc_invoked = false;
	
	-- set client data by sequence, instead in parallel
	local nGUIDIndex = 1;
	local function SetOneItemClientData(index)
		local guid = guids[index];
		if(not guid) then 
			LOG.std("", "warning","Item", "warning: no guid at index %d", index);
			return
		end
		
		-- items in homeland are always with bag 10001 or 10002~10009
		ItemManager.SetClientData(guid, ItemManager.PendingHomeLandModification[guid], function(msg)
			if(msg.issuccess == false) then
				LOG.std("", "error","Item", "failed modify item of homeland guid:"..tostring(guid));
				if(not callbackFunc_invoked) then
					callbackFunc_invoked = true;
					callbackFunc(false);
				end
			else
				--ItemManager.PendingHomeLandModification[guid] = msg.issuccess;
				isReplieds[guid] = true;
				local k, v;
				local bAllReplied = true;
				for k, v in pairs(isReplieds) do
					if(v == false) then
						bAllReplied = false;
						break;
					end
				end
				if(bAllReplied == true) then
					if(not callbackFunc_invoked) then
						callbackFunc_invoked = true;
						callbackFunc(true);
					end
				else
					nGUIDIndex = nGUIDIndex + 1;
					SetOneItemClientData(nGUIDIndex);
				end
			end
		end, nil, 5000, function() -- nil is NOT cache_policy
			LOG.std("", "error","Item", "modify item of homeland timeout guid:"..tostring(guid));
		
			-- NOTE 2009/12/6: change of set clientdata of homeland item strategy:
			--					fail the whole save process if ANY set clientdata call timed out or failed
			if(not callbackFunc_invoked) then
				callbackFunc_invoked = true;
				callbackFunc(false);
			end
			
			--isReplieds[guid] = true;
			--local k, v;
			--local bAllReplied = true;
			--for k, v in pairs(isReplieds) do
				--if(v == false) then
					--bAllReplied = false;
					--break;
				--end
			--end
			--if(bAllReplied == true) then
				--callbackFunc(true);
			--else
				--nGUIDIndex = nGUIDIndex + 1;
				--SetOneItemClientData(nGUIDIndex);
			--end
		end);
	end
	SetOneItemClientData(nGUIDIndex);
end

-- get outdoor item count in homeland
-- @param nid: nil for myself
-- @return: item count
function ItemManager.GetHomelandItemCount(nid)
	local bag = ItemManager.homeland_bag;
	if(nid == nil or nid == System.App.profiles.ProfileManager.GetNID()) then
		return ItemManager.GetItemCountInBag(bag);
	else
		return ItemManager.GetOPCItemCountInBag(nid, bag);
	end
end

-- get homeland outdoor item by bag and order
-- @param nid: nil for myself
-- @param order: the local order of the item in homeland, starts from 1
-- @return: item data, nil if not found
function ItemManager.GetHomelandItemByOrder(nid, order)
	local bag = ItemManager.homeland_bag;
	if(nid == nil or nid == System.App.profiles.ProfileManager.GetNID()) then
		return ItemManager.GetItemByBagAndOrder(bag, order);
	else
		return ItemManager.GetOPCItemByBagAndOrder(nid, bag, order);
	end
end

----------------------------------------------------------------------------------------------------
-- The following editing-related functions relies on the fact that: 
--		guid of an item will never change if not recycled
--		and during the editing process no items can be recycled
----------------------------------------------------------------------------------------------------

-- if in homeland editing mode
function ItemManager.IsHomeLandEditing()
	return ItemManager.bEditing;
end

-- begin homeland editing, call ItemManager.EndHomeLandEditing() when finished
function ItemManager.BeginHomeLandEditing()
	ItemManager.bEditing = true;
	ItemManager.PendingHomeLandModification = {};
	--local pending modification
end

-- end homeland editing, call ItemManager.BeginHomeLandEditing() when started
function ItemManager.EndHomeLandEditing()
	ItemManager.bEditing = false;
end

-- set clientdata to an item of homeland
-- NOTE: remember to set the clientdata immediately after the append process
-- @param guid: item instance guid
-- @param clientdata: client data to be set to the item instance
function ItemManager.ModifyHomeLandItem(guid, clientdata)
	if(guid == nil or clientdata == nil) then
		return;
	end
	if(ItemManager.IsHomeLandEditing()) then
		ItemManager.PendingHomeLandModification[guid] = clientdata;
	end
end

-- get the item description in memory and plus the editing information, the item returned in this NOT the data on server
-- if the item client data is modified, the clientdata will be changed
-- @param guid: item guid in item_instance
-- @return:
--	{	guid = item.guid, 
--		gsid = item.gsid,
--		obtaintime = item.obtaintime,
--		bag = bag,
--		position = item.position,
--		clientdata = item.clientdata,
--		serverdata = item.serverdata,
--		copies = item.copies,
--	}
function ItemManager.GetItemByGUIDEditing(guid)
	-- item for return, make sure any modification will not affect ItemManager.items
	local item = commonlib.deepcopy(ItemManager.GetItemByGUID(guid));
	if(item and ItemManager.IsHomeLandEditing()) then
		item.clientdata = ItemManager.PendingHomeLandModification[guid];
	end
	return item;
end

-- append an item to homeland
-- @param guid: item instance guid
-- @param callbackFunc: callback function that will be called after the source and home bag is refetched, but with the MoveItem message
--			the msg will also contains a special field called appended_guid containing the newly appended item guid
-- @param timeout: timeout time
-- @param timeout_callback: timeout callback
--	NOTE: the timeout callback could be invoked from MoveItem or GetItemsInBag(source) or GetItemsInBag(homeland)
-- @return: true if succeed, false if the homeland is full
function ItemManager.AppendHomeLandItem(guid, clientdata, callbackFunc, timeout, timeout_callback)

	local homeland_bag = ItemManager.homeland_bag;
	
	if(guid == nil) then
		return;
	end
	if(not homeland_bag or homeland_bag < 10001 or homeland_bag > 10009) then
		LOG.std("", "error","Item", "error: ItemManager.AppendHomeLandItem with homeland_bag id exceed the homeland bag region");
		return;
	end
	local item = ItemManager.GetItemByGUID(guid);
	if(item and item.bag) then
		local msg = {
			items = guid..",1",
			srcbag = item.bag,
			dstbag = 10001,
			clientdata = clientdata,
		};
		
		paraworld.inventory.MoveItems(msg, "AppendHomelandItem_"..guid, function(msg)
			if(msg.issuccess == false) then
				LOG.std("", "error","Item", "error: failed moving item:"..guid.." to homeland:"..homeland_bag);
				callbackFunc(msg);
				return;
			end
			if(msg.adds and msg.adds[1] and msg.adds[1].guid) then
				msg.appended_guid = msg.adds[1].guid;
				--msg.adds[1].clientdata = msg.adds[1].clientdata or clientdata;
				--local bHas, guid, _, copies = ItemManager.IfOwnGSItem(gsid, 10001);
				--if(bHas) then
					--ItemManager.UpdateBagItems(msg.adds);
				--else
					--ItemManager.UpdateBagItems(nil, msg.adds);
				--end
				--ItemManager.UpdateBagItems({{guid=item.guid, cnt=-1, gsid=item.gsid}});

				--callbackFunc(msg);
				--return;
			else
				LOG.std("", "error","Item", "error: no appended item found in callback message in paraworld.inventory.MoveItems");
				msg.issuccess = false;
				callbackFunc(msg);
				return;
			end
			
			local bSrcBagReplied = false;
			local bDstBagReplied = false;
			-- automatically update the items in the source bag
			ItemManager.GetItemsInBag(item.bag, "UpdateSrcBagAfterAppendHomelandItem_"..guid, function(msg2)
				-- update all page controls containing the pe:slot tag
				-- TODO: update only the PageCtrl with the same bag
				Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
				bSrcBagReplied = true;
				if(bSrcBagReplied == true and bDstBagReplied == true) then
					callbackFunc(msg)
				end
			end, "access plus 10 minutes", timeout, timeout_callback);
			-- automatically update the items in the homeland bag
			ItemManager.GetItemsInBag(homeland_bag, "UpdateHomeBagAfterAppendHomelandItem_"..guid, function(msg3)
				-- update all page controls containing the pe:slot tag
				-- TODO: update only the PageCtrl with the same bag
				Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
				bDstBagReplied = true;
				if(bSrcBagReplied == true and bDstBagReplied == true) then
					callbackFunc(msg)
				end
			end, "access plus 10 minutes", timeout, timeout_callback);
		end, nil, timeout, timeout_callback);
	else
		-- invalid item
		log("error: invalid item:"..tostring(guid).." in ItemManager.AppendHomeLandItem()\n")
		return;
	end
end

-- grow a homeland plant to homeland outdoor
-- @param guid: item instance guid
-- @param clientdata: clientdata that is first set to the newly appended item
-- @param callbackFunc: callback function that will be called after the source and home bag is refetched, but with the MoveItem message
--			the msg will also contains a special field called appended_guid containing the newly appended item guid
-- @param timeout: timeout time
-- @param timeout_callback: timeout callback
--	NOTE: the timeout callback could be invoked from plantevolved.Grow or GetItemsInBag(source) or GetItemsInBag(homeland)
-- @return: true if succeed, false if the homeland is full
function ItemManager.GrowHomeLandPlant(guid, clientdata, callbackFunc, timeout, timeout_callback)
	if(guid == nil) then
		return;
	end
	-- homeland bag
	local homeland_bag = ItemManager.homeland_bag;
	-- usually the clientdata initially set the newly appended homeland item
	clientdata = clientdata or "";
	
	local item = ItemManager.GetItemByGUID(guid);
	if(item and item.bag) then
		local msg = {
			--sessionkey = Map3DSystem.User.sessionkey,
			guid = item.guid,
			bag = item.bag,
			clientdata = clientdata,
		};
		LOG.std("", "system","Item", {"请求参数---种植植物：",msg});
		paraworld.homeland.plantevolved.Grow(msg, "GrowHomeLandPlant_"..guid, function(msg)
			LOG.std("", "system","Item", {"种植植物后返回的信息：",msg});
			if(msg.issuccess == false) then
				LOG.std("", "error","Item", "error: failed moving item:"..guid.." to homeland:"..homeland_bag);
				callbackFunc(msg);
				return;
			end
			
			msg.appended_guid = msg.id;
			
			local bSrcBagReplied = false;
			local bDstBagReplied = false;
			-- automatically update the items in the source bag
			ItemManager.GetItemsInBag(item.bag, "UpdateSrcBagAfterGrowHomeLandPlant_"..guid, function(msg2)
				-- update all page controls containing the pe:slot tag
				-- TODO: update only the PageCtrl with the same bag
				Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
				bSrcBagReplied = true;
				if(bSrcBagReplied == true and bDstBagReplied == true) then
					callbackFunc(msg);
				end
			end, "access plus 1 minute", nil, timeout, timeout_callback);
			-- automatically update the items in the homeland bag
			ItemManager.GetItemsInBag(homeland_bag, "UpdateHomeBagAfterGrowHomeLandPlant_"..guid, function(msg3)
				-- update all page controls containing the pe:slot tag
				-- TODO: update only the PageCtrl with the same bag
				Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
				bDstBagReplied = true;
				if(bSrcBagReplied == true and bDstBagReplied == true) then
					callbackFunc(msg);
				end
			end, "access plus 1 minute", nil, timeout, timeout_callback);
		end, nil, timeout, timeout_callback);
	else
		-- invalid item
		LOG.std("", "error","Item", "error: invalid item:"..tostring(guid).." in ItemManager.GrowHomeLandPlant()");
		return;
	end
end

-- grow a homeland house to homeland outdoor
-- @param guid: item instance guid
-- @param clientdata: clientdata that is first set to the newly appended item
-- @param callbackFunc: callback function that will be called after the source and home bag is refetched, but with the MoveItem message
--			the msg will also contains a special field called appended_guid containing the newly appended item guid
-- @param timeout: timeout time
-- @param timeout_callback: timeout callback
--	NOTE: the timeout callback could be invoked from house.Grow or GetItemsInBag(source) or GetItemsInBag(homeland)
-- @return: true if succeed, false if the homeland is full
function ItemManager.GrowHomeLandHouse(guid, clientdata, callbackFunc, timeout, timeout_callback)
	if(guid == nil) then
		return;
	end
	-- homeland outdoor
	local homeland_bag = ItemManager.homeland_bag;
	-- usually the clientdata initially set the newly appended homeland item
	clientdata = clientdata or "";
	
	local item = ItemManager.GetItemByGUID(guid);
	if(item and item.bag) then
		local msg = {
			guid = item.guid,
			bag = item.bag,
			clientdata = clientdata,
		};
		
		paraworld.homeland.house.Grow(msg, "GrowHomeLandHouse_"..guid, function(msg)
			LOG.std("", "system","Item", "======= paraworld.homeland.house.Grow returns ======="..LOG.tostring(msg));
			if(msg.issuccess == false) then
				LOG.std("", "error","Item", "failed moving house item:"..guid.." to homeland:"..homeland_bag);
				callbackFunc(msg);
				return;
			end
			
			msg.appended_guid = msg.guid;
			
			local bSrcBagReplied = false;
			local bDstBagReplied = false;
			-- automatically update the items in the source bag
			ItemManager.GetItemsInBag(item.bag, "UpdateSrcBagAfterGrowHomeLandHouse_"..guid, function(msg2)
				-- update all page controls containing the pe:slot tag
				-- TODO: update only the PageCtrl with the same bag
				Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
				bSrcBagReplied = true;
				if(bSrcBagReplied == true and bDstBagReplied == true) then
					callbackFunc(msg);
				end
			end, "access plus 1 minute", nil, timeout, timeout_callback);
			-- automatically update the items in the homeland bag
			ItemManager.GetItemsInBag(homeland_bag, "UpdateHomeBagAfterGrowHomeLandHouse_"..guid, function(msg3)
				-- update all page controls containing the pe:slot tag
				-- TODO: update only the PageCtrl with the same bag
				Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
				bDstBagReplied = true;
				if(bSrcBagReplied == true and bDstBagReplied == true) then
					callbackFunc(msg);
				end
			end, "access plus 1 minute", nil, timeout, timeout_callback);
		end, nil, timeout, timeout_callback);
	else
		-- invalid item
		LOG.std("", "error","Item", "invalid item:"..tostring(guid).." in ItemManager.GrowHomeLandHouse()");
		return;
	end
end

-- delete an item from homeland
-- @param guid: item instance guid
-- @param callbackFunc: callback function that will be called after the source and home bag is refetched, but with the MoveItem message
-- @param timeout: timeout time
-- @param timeout_callback: timeout callback
--	NOTE: the timeout callback could be invoked from MoveItem or GetItemsInBag(source) or GetItemsInBag(homeland)
-- @return: true if succeed
function ItemManager.RemoveHomeLandItem(guid, callbackFunc, timeout, timeout_callback)
	if(guid == nil) then
		return;
	end
	local item = ItemManager.GetItemByGUID(guid);
	if(item and item.gsid and item.bag and item.bag >= 10001 and item.bag <= 10009) then
		local gsItem = ItemManager.GetGlobalStoreItemInMemory(item.gsid)
		if(gsItem) then
			local msg = {
				items = guid..",1",
				srcbag = item.bag,
				dstbag = gsItem.template.bagfamily,
			};
			paraworld.inventory.MoveItems(msg, "RemoveHomeLandItem_"..guid, function(msg)
				if(msg.issuccess == false) then
					LOG.std("", "error","Item", "error: failed moving item:"..guid.." from homeland");
				elseif(msg.issuccess == true) then
					-- clear the modification in the modification list, since the removed item guid is no longer avaiable
					ItemManager.PendingHomeLandModification[guid] = nil;
				end
				local bSrcBagReplied = false;
				local bDstBagReplied = false;
				-- automatically update the items in the source bag
				ItemManager.GetItemsInBag(item.bag, "UpdateSrcBagAfterRemoveHomeLandItem_"..guid, function(msg2)
					-- update all page controls containing the pe:slot tag
					-- TODO: update only the PageCtrl with the same bag
					Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
					bSrcBagReplied = true;
					if(bSrcBagReplied == true and bDstBagReplied == true) then
						callbackFunc(msg);
					end
				end, "access plus 0 day", timeout, timeout_callback);
				-- automatically update the items in the homeland bag
				ItemManager.GetItemsInBag(gsItem.template.bagfamily, "UpdateHomeBagAfterRemoveHomeLandItem_"..guid, function(msg3)
					-- update all page controls containing the pe:slot tag
					-- TODO: update only the PageCtrl with the same bag
					Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
					bDstBagReplied = true;
					if(bSrcBagReplied == true and bDstBagReplied == true) then
						callbackFunc(msg);
					end
				end, "access plus 0 day", timeout, timeout_callback);
			end, nil, timeout, timeout_callback);
		end
	else
		-- invalid item
		LOG.std("", "error","Item", "error: invalid item or bag:"..tostring(guid).." in ItemManager.RemoveHomeLandItem()");
		return;
	end
end

-- delete a plant from homeland
-- @param guid: item instance guid
-- @param callbackFunc: callback function that will be called after the source and home bag is refetched, but with the MoveItem message
-- @param timeout: timeout time
-- @param timeout_callback: timeout callback
-- @return: true if succeed
function ItemManager.RemoveHomeLandPlant(guid, callbackFunc, timeout, timeout_callback)
	if(guid == nil) then
		return;
	end
	local item = ItemManager.GetItemByGUID(guid);
	if(item and item.gsid and item.bag and item.bag >= 10001 and item.bag <= 10009) then
		local gsItem = ItemManager.GetGlobalStoreItemInMemory(item.gsid)
		if(gsItem) then
			local msg = {
				id = guid,
				bag = item.bag, -- for local server optimization
			};
			paraworld.homeland.plantevolved.Remove(msg, "RemoveHomeLandPlant_"..guid, function(msg)
				if(msg.issuccess == false) then
					LOG.std("", "error","Item", "error: failed moving item:"..guid.." from homeland");
				elseif(msg.issuccess == true) then
					-- clear the modification in the modification list, since the removed item guid is no longer avaiable
					if(ItemManager.PendingHomeLandModification)then
						ItemManager.PendingHomeLandModification[guid] = nil;
					end
				end
				local bSrcBagReplied = false;
				local bDstBagReplied = false;
				-- automatically update the items in the source bag
				ItemManager.GetItemsInBag(item.bag, "UpdateSrcBagAfterRemoveHomeLandPlant_"..guid, function(msg2)
					-- update all page controls containing the pe:slot tag
					-- TODO: update only the PageCtrl with the same bag
					Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
					bSrcBagReplied = true;
					if(bSrcBagReplied == true and bDstBagReplied == true) then
						callbackFunc(msg);
					end
				end, "access plus 1 minute", timeout, timeout_callback);
				-- automatically update the items in the homeland bag
				ItemManager.GetItemsInBag(gsItem.template.bagfamily, "UpdateHomeBagAfterRemoveHomeLandPlant_"..guid, function(msg3)
					-- update all page controls containing the pe:slot tag
					-- TODO: update only the PageCtrl with the same bag
					Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
					bDstBagReplied = true;
					if(bSrcBagReplied == true and bDstBagReplied == true) then
						callbackFunc(msg);
					end
				end, "access plus 1 minute", timeout, timeout_callback);
			end, nil, timeout, timeout_callback);
		end
	else
		-- invalid item
		LOG.std("", "error","Item", "error: invalid item or bag:"..tostring(guid).." in ItemManager.RemoveHomeLandPlant()");
		return;
	end
end

-- gain fruits of given plant
-- @param plant_guid: plant item instance guid
-- @param callbackFunc: callback function that will be called after gain fruits
function ItemManager.GainFruits(plant_guid, callbackFunc)
	if(not plant_guid or not callbackFunc) then
		LOG.std("", "error","Item", "error: nil plant_guid or callbackFunc got in ItemManager.GainFruits");
		return;
	end
	local msg = {
		id = plant_guid,
	};
	paraworld.homeland.plantevolved.GainFruits(msg, "GainFruitsFrom_"..plant_guid, function(msg)
		if(msg.issuccess == false) then
			callbackFunc(msg);
			return;
		end
		-- automatically update the items in the homeland bag
		ItemManager.GetItemsInBag(gsItem.template.bagfamily, "UpdateHomeBagAfterGainFruitsFrom_"..plant_guid, function(msg3)
			-- update all page controls containing the pe:slot tag
			-- TODO: update only the PageCtrl with the same bag
			Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
			callbackFunc(msg);
		end, "access plus 0 day");
	end);
end

-- get user's pets in HomeLand, it will also grab the user's bag 0 items
-- @param nid: nid of user, nil for myself
-- @param callbackFunc: callback function that will be called after the loading process
-- @param cache_policy: cache_policy of the outdoor load, default "access plus 0 day"
function ItemManager.LoadPetsInHomeland(nid, callbackFunc, cache_policy)
	cache_policy = cache_policy or "access plus 0 day";
	if(nid == nil or nid == System.App.profiles.ProfileManager.GetNID()) then
		ItemManager.GetItemsInBag(10010, "LoadMyPets", function(msg)
			callbackFunc(msg);
		end, cache_policy);
	else
		local bReturn_bag0 = false;
		local bReturn_bag10010 = false;
		local bag10010_ReturnMSG;
		ItemManager.GetItemsInOPCBag(nid, 10010, "LoadOPCPets_"..nid, function(msg)
			bReturn_bag10010 = true;
			bag10010_ReturnMSG = msg;
			if(bReturn_bag0 == true and bReturn_bag10010 == true) then
				callbackFunc(bag10010_ReturnMSG);
			end
		end, cache_policy);
		ItemManager.GetItemsInOPCBag(nid, 0, "LoadOPCPetsInBag0_"..nid, function(msg)
			bReturn_bag0 = true;
			if(bReturn_bag0 == true and bReturn_bag10010 == true) then
				callbackFunc(bag10010_ReturnMSG);
			end
		end, cache_policy);
	end
end

-- get my pet count in homeland
-- @param nid: nid of the OPC
-- @return: item count
function ItemManager.GetPetCountInHomeland(nid)
	if(nid == nil or nid == System.App.profiles.ProfileManager.GetNID()) then
		local count = ItemManager.GetItemCountInBag(10010);
		local item = ItemManager.GetMyMountPetItem();
		if(item and item.guid > 0 and item.bag ~= 10010 and item.clientdata == "home") then
			count = count + 1;
		end
		return count;
	else
		local count = ItemManager.GetOPCItemCountInBag(nid, 10010);
		local item = ItemManager.GetOPCMountPetItem(nid);
		if(item and item.guid > 0 and item.bag ~= 10010 and item.clientdata == "home") then
			count = count + 1;
		end
		return count;
	end
end


-- get by pet by order
-- @param nid: nid of the OPC
-- @param order: the local order of the pet in homeland, starts from 1
-- @return: item data, nil if not found
function ItemManager.GetPetByOrder(nid, order)
	if(nid == nil or nid == System.App.profiles.ProfileManager.GetNID()) then
		local item = ItemManager.GetItemByBagAndOrder(10010, order);
		if(item and item.guid > 0) then
			return item;
		else
			if(order == ItemManager.GetItemCountInBag(10010) + 1) then
				local item = ItemManager.GetMyMountPetItem();
				if(item and item.guid > 0 and item.bag ~= 10010 and item.clientdata == "home") then
					return item;
				end
			end
		end
	else
		local item = ItemManager.GetOPCItemByBagAndOrder(nid, 10010, order);
		if(item and item.guid > 0) then
			return item;
		else
			if(order == ItemManager.GetOPCItemCountInBag(nid, 10010) + 1) then
				local item = ItemManager.GetOPCMountPetItem(nid);
				if(item and item.guid > 0 and item.bag ~= 10010 and item.clientdata == "home") then
					return item;
				end
			end
		end
	end
end


-- get follow pet count
-- NOTE: call ItemManager.LoadPetsInHomeland first before all items are valid
-- @param nid: nid of the user
-- @return: item data, nil if not found
function ItemManager.GetFollowPetCount(nid)
	if(nid == nil or nid == System.App.profiles.ProfileManager.GetNID()) then
		local count = ItemManager.GetItemCountInBag(10010);
		local item = ItemManager.GetItemByBagAndPosition(0, 32);
		if(item and item.guid > 0) then
			return count + 1;
		else
			return count;
		end
	else
		local count = ItemManager.GetOPCItemCountInBag(nid, 10010);
		local item = ItemManager.GetOPCItemByBagAndPosition(nid, 0, 32);
		if(item and item.guid > 0) then
			return count + 1;
		else
			return count;
		end
	end
end

-- get follow pet item by order
-- NOTE: call ItemManager.LoadPetsInHomeland first before all items are valid
-- @param nid: nid of the user
-- @param order: 
-- @return: item data, nil if not found
function ItemManager.GetFollowPetByOrder(nid, order)
	if(nid == nil or nid == System.App.profiles.ProfileManager.GetNID()) then
		local item = ItemManager.GetItemByBagAndOrder(10010, order);
		if(item and item.guid > 0) then
			return item;
		else
			if(order == ItemManager.GetItemCountInBag(10010) + 1) then
				local item = ItemManager.GetItemByBagAndPosition(0, 32);
				if(item and item.guid > 0) then
					return item;
				end
			end
		end
	else
		local item = ItemManager.GetOPCItemByBagAndOrder(nid, 10010, order);
		if(item and item.guid > 0) then
			return item;
		else
			if(order == ItemManager.GetOPCItemCountInBag(nid, 10010) + 1) then
				local item = ItemManager.GetOPCItemByBagAndPosition(nid, 0, 32);
				if(item and item.guid > 0) then
					return item;
				end
			end
		end
	end
end

-- use item for pet
-- @param item_guid: feed item instance guid
-- @param pet_owner_nid: pet owner nid
-- @param pet_guid: pet item instance guid
-- @param callbackFunc: callback function that will be called after use item
function ItemManager.PetUseItem(item_guid, pet_owner_nid, pet_guid, callbackFunc)
	if(not item_guid or not pet_guid or not callbackFunc) then
		LOG.std("", "error","Item", "nil item_guid or pet_guid or callbackFunc got in ItemManager.PetUseItem()");
		return;
	end
	local item = ItemManager.GetItemByGUID(item_guid);
	if(item and item.guid > 0) then
		local item_gsid = item.gsid;
		local msg = {
			nid = pet_owner_nid,
			itemgsid = item_guid,
			petid = pet_guid,
			bag = item.bag,
		};
		paraworld.homeland.petevolved.UseItem(msg, "PetUseItem_"..item_guid, function(msg)
			if(msg.issuccess == false) then
				callbackFunc(msg);
				return;
			end
			-- update the item bag
			local gsItem = ItemManager.GetGlobalStoreItemInMemory(item_gsid);
			if(gsItem) then
				-- automatically update the items in the homeland bag
				ItemManager.GetItemsInBag(gsItem.template.bagfamily, "UpdateHomeBagAfterPetUseItem_"..item_guid, function(msg3)
					-- update all page controls containing the pe:slot tag
					-- TODO: update only the PageCtrl with the same bag
					Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
					callbackFunc(msg);
				end, "access plus 3 minutes");
			end
		end);
	end
end

-- get all cangift items
-- @return: table with GUID list
function ItemManager.GetAllCanGiftItemGUIDs()
	local ret = {};
	local guid, item;
	for guid, item in pairs(ItemManager.items) do
		local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(item.gsid);
		if(gsItem) then
			local disable_trading;
			if(item.GetSocketedGems)then
				local gems = item:GetSocketedGems() or {};
				local len = #gems;
				if(len > 0)then
					disable_trading = true;
				end
			end
			-- if there is addon level, disable trading. 
			if(item.GetAddonLevel and item:GetAddonLevel()>0)then
				disable_trading = true;
			end
			if(not disable_trading) then
				local bag = item.bag;
				if(bag and bag >=1 and bag <= 9999) then
					if(gsItem.template.cangift == true) then
						table.insert(ret, guid);
					end
				elseif(bag and item.gsid == 998 and bag == 0) then -- check 998_EnergyStone
					if(gsItem.template.cangift == true) then
						table.insert(ret, guid);
					end
				end
			end
		end
	end
	return ret;
end

-- ResetTrainingPoint
-- @param callbackFunc: the callback function(msg) end immediately after purchase
-- @param callbackFunc2: the callback function(msg) end that will be called again after update bag
function ItemManager.ResetTrainingPoint(callbackFunc, callbackFunc2, timeout, timeout_callback)
	local hasGSItem = System.Item.ItemManager.IfOwnGSItem;
	paraworld.inventory.ResetTrainingPoint(nil,"ResetTrainingPoint", function(msg) 		
		if(msg.issuccess == true) then
			local msg = {
				bags = "0,1,24,", -- 0 for magicbean, 1 for deck, 24 for card bag
			};
			paraworld.inventory.GetItemsInBags(msg, nil, function(msg) 
				-- refresh the bag in local server cache
				ItemManager.GetItemsInBag(0, "RefreshBag0_After_ResetTrainingPoint", function(msg)
					local clientdata = "";
					local deck = System.Item.ItemManager.GetItemByBagAndPosition(0, 24);
					if(deck.guid) then
						System.Item.ItemManager.SetClientData(deck.guid, clientdata, function(msg_setclientdata)
				--			if(callbackFunc and type(callbackFunc) == "function")then
				--				callbackFunc(msg);
				--			end
						end);
						commonlib.echo("============ResetTrainpoint clear combatbags0:"..tostring(deck.gsid).."|"..deck.guid);
					end
				end, "access plus 1 minute");
				ItemManager.GetItemsInBag(24, "RefreshBag24_After_ResetTrainingPoint", function(msg)
				end, "access plus 1 minute");
				ItemManager.GetItemsInBag(1, "RefreshBag1_After_ResetTrainingPoint", function(msg)
					if(msg and msg.items)then
						local i;
						local bag = 1;
						local item, gsItem;
						local count = System.Item.ItemManager.GetItemCountInBag(bag);
						for i = 1, count do
							local item = System.Item.ItemManager.GetItemByBagAndOrder(bag, i);
							if(item and item.guid > 0 )then
								gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(tonumber(item.gsid));
								if(gsItem)then
									local class = tonumber(gsItem.template.class);
									local subclass = tonumber(gsItem.template.subclass);
									if(class == 19 and subclass == 1) then
										System.Item.ItemManager.SetClientData(item.guid, "", function(msg_setclientdata) end);							
										commonlib.echo("============ResetTrainpoint clear combatbags1:"..tostring(item.gsid).."|"..item.guid);
									end
								end
							end	
						end -- for i=1,
					end
				end, "access plus 1 minute");
			end, "access plus 0 day"); -- paraworld.inventory.GetItemsInBags(msg
		end -- if(msg.issuccess == true)
		
		if (msg.issuccess == false and msg.errorcode == 443) then
			NPL.load("(gl)script/apps/Aries/Desktop/GUIHelper/CustomMessageBox.lua");
			local s;
			if(System.options.version=="kids") then
				s = "很抱歉，你的魔豆数量不足，先多兑换点魔豆再来买吧！";
			else
				s = "很抱歉，你的金币数量不足，先多兑换点金币再来买吧！";
			end
			_guihelper.Custom_MessageBox(s,function(result)
				if(result == _guihelper.DialogResult.Yes)then
					if(System.options.version=="kids") then
						NPL.load("(gl)script/apps/Aries/VIP/PurChaseMagicBean.lua");
					else
						NPL.load("(gl)script/apps/Aries/VIP/PurChaseMagicBean.teen.lua");
					end
					MyCompany.Aries.Inventory.PurChaseMagicBean.Show();
				end
			end,_guihelper.MessageBoxButtons.YesNo,{yes = "Texture/Aries/Common/PurchaseMagicBean_32bits.png; 0 0 153 49", no ="Texture/Aries/Common/Later_32bits.png; 0 0 153 49"});

		elseif(msg.issuccess == false and msg.errorcode == 419) then
			_guihelper.MessageBox("用户不存在或不可用\n");
		elseif(msg.issuccess == false and msg.errorcode == 497) then
			_guihelper.MessageBox("你现在不需要洗点！\n");
		elseif(msg.issuccess == false and msg.errorcode == 493) then
			_guihelper.MessageBox("参数错误\n");
		elseif(msg.issuccess == false and msg.errorcode == 500) then
			_guihelper.MessageBox("失败了！天知道发生了什么！\n");
		end

		callbackFunc(msg);
	end, nil, timeout, timeout_callback);
end

-- This function is usually called to secretly update local store bag items after some API(such as Item.Transaction)
-- @param updates: an array of table of {copies=number, cnt=number, guid=number, }
-- @param adds: an array of table of {copies|cnt=number, guid=number, gsid=number, [svrdata], [clientdata], [pos]}
-- @param action_type:更新标记
-- @return items_to_add: return a table containing the positive delta of items added, which can be used to display UI. 
function ItemManager.UpdateBagItems(updates, adds, stats, action_type)
	-- determine which bags to update. 
	local bags_to_updates;
	local bags_to_refresh;
	local items_to_add;
	if(stats) then
		local has_unknown_stats;
		local _, stat;
		for _, stat in ipairs(stats) do
			local myInfo = ProfileManager.GetUserInfoInMemory(ProfileManager.GetNID());
			if(myInfo) then
				local gsid = stat.gsid or stat.guid;
				if(gsid == -1) then
					if(stat.copies) then
						myInfo.pmoney  = stat.copies;
					elseif(stat.cnt) then
						myInfo.pmoney  = myInfo.pmoney + stat.cnt;
					end
				elseif(gsid == 0) then
					if(stat.copies) then
						myInfo.emoney  = stat.copies;
					elseif(stat.cnt) then
						myInfo.emoney  = myInfo.emoney + stat.cnt;
					end
				elseif(gsid == -19) then
					if(stat.copies) then
						myInfo.stamina = stat.copies;
					elseif(stat.cnt) then
						myInfo.stamina = myInfo.stamina + stat.cnt;
					end
				elseif(gsid == -20) then
					if(stat.copies) then
						myInfo.stamina2 = stat.copies;
					elseif(stat.cnt) then
						myInfo.stamina2 = myInfo.stamina2 + stat.cnt;
					end
				else
					has_unknown_stats = true;
				end
			end
		end
		if(has_unknown_stats) then
			-- update the user info in memory, mainly pmoney
			System.App.profiles.ProfileManager.GetUserInfo(nil, "UpdateUserInfoInMemoryAfterSellItem", function(msg) end, "access plus 0 day");
		end
	end
	if(updates) then
		-- update items in bag
		local _, update;
		for _, update in ipairs(updates) do
			if( (update.guid and update.guid<=0) or (update.gsid and update.gsid<=0) ) then
				local myInfo = ProfileManager.GetUserInfoInMemory(ProfileManager.GetNID());
				if(myInfo and update.copies) then
					local gsid = update.gsid or update.guid;
					if(gsid == -1) then
						myInfo.pmoney  = update.copies;
					elseif(gsid == 0) then
						myInfo.emoney  = update.copies;
					elseif(gsid == -19) then
						myInfo.stamina = update.copies; -- not tested
					elseif(gsid == -20) then
						myInfo.stamina2 = update.copies; -- not tested
					elseif(gsid == -13) then
						myInfo.combatexp = update.copies; -- not tested
					end
				else
					-- update the user info in memory, mainly pmoney
					System.App.profiles.ProfileManager.GetUserInfo(nil, "UpdateUserInfoInMemoryAfterSellItem", function(msg) end, "access plus 0 day");
				end
			else
				local item = ItemManager.GetItemByGUID(update.guid);
				if(item and item.guid == update.guid) then
					bags_to_refresh = bags_to_refresh or {};
					bags_to_refresh[item.bag] = true;
					-- update local store

					local old_copies = item.copies or 0;
					if(update.copies) then
						item.copies = update.copies;
						paraworld.inventory.UpdateItemsInBag(item.bag, update);
					elseif(update.cnt) then
						item.copies = old_copies + update.cnt;
						paraworld.inventory.UpdateItemsInBag(item.bag, update, true);
					else
						item.copies = old_copies;
					end
					item.serverdata = update.serverdata or item.serverdata;
					if(old_copies < item.copies) then
						items_to_add = items_to_add or {}
						items_to_add[#items_to_add + 1] = {gsid=item.gsid, cnt = item.copies - old_copies}
					end
				end
			end
		end
	end
	if(adds) then
		-- update adds in bag
		local _, add;
		for _, add in ipairs(adds) do
			if(add.guid == -1) then
				-- P money:
				-- update the user info in memory, mainly pmoney
				System.App.profiles.ProfileManager.GetUserInfo(nil, "UpdateUserInfoInMemoryAfterSellItem", function(msg) end, "access plus 0 day");
			else
				bags_to_updates = bags_to_updates or {};
				if(not add.guid) then
					bags_to_updates[add.bag] = true;
				end
				bags_to_refresh = bags_to_refresh or {};
				bags_to_refresh[add.bag] = true;

				-- update local store
				paraworld.inventory.AddItemsInBag(add.bag, add);

				items_to_add = items_to_add or {}
				items_to_add[#items_to_add + 1] = {gsid=add.gsid, cnt = add.copies or add.cnt}
			end
		end
	end
	
	if(bags_to_refresh) then
		-- Force updating all bags locally
		local bag, _;
		for bag, _ in pairs(bags_to_refresh) do
			ItemManager.GetItemsInBag(bag, nil, function(msg)
			end, "access plus 1 year"); 
		end
	end
	if(bags_to_updates) then
		-- Force updating all bags by refetching them from server
		local bag, _;
		for bag, _ in pairs(bags_to_updates) do
			ItemManager.GetItemsInBag(bag, nil, function(msg)
			end, "access plus 1 minute"); 
		end
	end

	if(items_to_add) then
		local _, item;
		for _, item in ipairs(items_to_add) do
			-- increase the count that obtained in both daily and weekly in memory
			local gsItem = ItemManager.GetGlobalStoreItemInMemory(item.gsid);
			if(gsItem) then
				if(gsItem.maxdailycount and (gsItem.maxdailycount ~= 0 or gsItem.maxweeklycount ~= 0)) then
					ItemManager.IncreaseGSObtainCntInTimeSpanInMemory(item.gsid, item.cnt);
				end
			end

			-- call hook for OnObtainItem
			local hook_msg = { aries_type = "OnObtainItem", gsid = item.gsid, count = item.cnt, wndName = "items"};
			CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);
		end

		local hook_msg = { aries_type = "OnNortifyItems", items = {adds = items_to_add, action_type = action_type, }, wndName = "items"};
		CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);
	end
	if(updates or adds or stats) then
		Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
	end
									
	return items_to_add;
end

-- UseVoucherCode
-- @param code: activity code 
-- @param exid: if code is useable, do the exid's extendedcost
-- @param callbackFunc: the callback function(msg) end immediately after purchase
-- @param callbackFunc2: the callback function(msg) end that will be called again after update bag
function ItemManager.UseVoucherCode(code,exid,callbackFunc, callbackFunc2, timeout, timeout_callback)
	if (code and exid) then
		paraworld.inventory.UseVoucherCode({code = code, exid = exid,},"UseVoucherCode",callbackFunc, nil, timeout, timeout_callback);
	end
end

-- Issue a power extendedcost from the client. 
-- e.g. 
-- Map3DSystem.Item.ItemManager.PowerExtendedCost("test", {from="2067", rate_gsid_count=1})
function ItemManager.PowerExtendedCost(exid, params, callbackFunck)
	System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="PowerExtendedCost", params={exid = exid, params = params}});
end

function ItemManager.UseOrBuyStaminaPill(callbackFunc, callbackFunc2)
	return ItemManager.UseOrBuyStaminaPillEx(nil, callbackFunc, callbackFunc2)
end

-- if there is StaminaPill in bag then use it.otherwise,show the buying view;
function ItemManager.UseOrBuyStaminaPillEx(gsid,callbackFunc, callbackFunc2)
	if(System.options.version == "kids") then
		local s = "";
		local staminaList;
		if(gsid) then
			staminaList  = {gsid};
		else
			staminaList  = {17393,17344,17345};
		end
		local hasStaminaPill = false;
		local k,v;
		local gsid,exid,gsItem,exItem,addStamina,pillGSID;
		NPL.load("(gl)script/kids/3DMapSystemApp/profiles/ProfileManager.lua");
		local cur_stamina, max_value = MyCompany.Aries.Player.GetStamina();
		for k,v in pairs(staminaList) do
			gsid = tonumber(v);
			gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid);
			exid = gsItem.template.stats[51];
			exItem = ItemManager.GetExtendedCostTemplate(exid);
			local kk,vv;
			for kk,vv in pairs(exItem.tos) do
				if(vv.key == -19) then
					addStamina = vv.value;
					if(cur_stamina + addStamina >= max_value) then
                        addStamina = max_value - cur_stamina;
                    end
				end
			end
			hasStaminaPill = ItemManager.IfOwnGSItem(gsid,12,nil);	
			if(hasStaminaPill == true) then
				if(gsid == 17393) then
					if(MyCompany.Aries.VIP.IsVIP()) then
						pillGSID = gsid;
						break;
					end
				else
					pillGSID = gsid;
					break;
				end
			end
		end
		local str;
		if(callbackFunc) then
			str = callbackFunc(msg) or "";
		end
		if(pillGSID) then
			local _,guid = ItemManager.IfOwnGSItem(pillGSID); -- 精力药剂
			if(guid) then
				local item  = ItemManager.GetItemByGUID(guid)
				if(item and item.OnClick) then
					s = format("发现你的包裹有<pe:item gsid='%d' style='width:24px;height:24px;' isclickable='false'/>,马上使用补充精力值！<br/>(魔法星可以提升精力值上限, 精力值明天会自动补满",pillGSID);
					s = str..s;
					if(s ~= "") then
						_guihelper.MessageBox(s,function(result) 
							if(result == _guihelper.DialogResult.Yes) then
								local _,guid = ItemManager.IfOwnGSItem(gsid); -- 精力药剂
								if(guid) then
									local item  = ItemManager.GetItemByGUID(guid)
									if(item and item.OnClick) then
										if(callbackFunc2) then
											item:OnClick("left",callbackFunc2);
										else
											item:OnClick("left",function(msg)
												System.App.profiles.ProfileManager.GetUserInfo(System.User.nid, "UpdateUserInfo", function(msg)
													local _s="";
													local _str = "";
													
													_str = string.format("你使用了一个<pe:item gsid='%d' style='width:24px;height:24px;' isclickable='false'/>恢复了<font color='#ff0000'>%d点</font>精力值。",pillGSID, addStamina);
													_guihelper.MessageBox(_str);	
													_s=string.format("你使用了一个%s,恢复了%d点精力值",pillGSID, addStamina);

													local Combat = commonlib.gettable("MyCompany.Aries.Combat");
													local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
													ChatChannel.AppendChat({
																ChannelIndex = ChatChannel.EnumChannels.ItemObtain, 
																fromname = "", 
																fromschool = Combat.GetSchool(), 
																fromisvip = false, 
																words = _s,
																is_direct_mcml = true,
																bHideSubject = true,
																bHideTooltip = true,
																bHideColon = true,
															});                                          
												end, "access plus 0 day");                                            
											end);
										end
									end
								end
							end
						end,_guihelper.MessageBoxButtons.YesNo);
					end
					return true;
				end
			end
		else
			s = format("立即购买<pe:item gsid='%d' style='width:24px;height:24px;' isclickable='false'/>，补充精力值！<br/>(魔法星可以提升精力值上限, 精力值明天会自动补满",17344);
			s = str..s;
			_guihelper.MessageBox(s , function(result)
				if(result == _guihelper.DialogResult.Yes)then
					local command = System.App.Commands.GetCommand("Profile.Aries.PurchaseItemWnd");
					if(command) then
						command:Call({gsid = 17344});-- 精力药剂
					end
				end
			end, _guihelper.MessageBoxButtons.YesNo);	
		end
	end
end

function ItemManager.UseOrBuy_EnergyStone(gsid,callbackFunc,callbackFunc2)
	if(System.options.version == "kids") then
		local s = "";
		local list;
		if(gsid) then
			list = {gsid};
		else
			list = {967,977,998};
		end
		local hasItem = false;
		local k,v;
		local itemGSID,addE,addM;
		local gsid;
		for k,v in pairs(list) do
			gsid = tonumber(v);
			gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid);
			hasItem = ItemManager.IfOwnGSItem(gsid);	
			if(hasItem == true) then
				itemGSID = gsid;
				addE = gsItem.template.stats[178];
				addM = gsItem.template.stats[179];
				break;
			end
		end
		local last_bean = System.App.profiles.ProfileManager.GetUserInfoInMemory();
		--msg.last_bean = last_bean;
		if(callbackFunc) then
			s = callbackFunc(msg) or s;
		end
		
		if(itemGSID) then
			local str = format("发现你的包裹有<pe:item gsid='%d' style='width:24px;height:24px;' isclickable='false'/>,马上使用，成为<pe:item gsid='%d' style='width:24px;height:24px;' isclickable='false'/>，享受多项特权！",itemGSID,50400);
			s = s..str;
			if(s ~= "") then
				_guihelper.MessageBox(s,function(result) 
					if(result == _guihelper.DialogResult.Yes) then
						if(callbackFunc2) then
							ItemManager.UseEnergyStoneEx(itemGSID, callbackFunc2);
						else
							ItemManager.UseEnergyStoneEx(itemGSID, function(msg)
		                        System.App.profiles.ProfileManager.GetUserInfo(System.User.nid, "UpdateUserInfo", function(msg)

									--last_bean = record.last_bean;
									local lastmlel;
									if (last_bean) then 
										lastmlel=tonumber(last_bean.mlel);
									else
										lastmlel=0;
									end
									local bean = msg.users[1];
									local _s="";
									local _str = "";
									if( lastmlel < tonumber(bean.mlel) )then
										_str = string.format("哇，真是好棒啊，使用<pe:item gsid='%d' style='width:24px;height:24px;' isclickable='false'/>让你的魔法星增加了<font color='#ff0000'>能量值：%d点   M值：%d点</font>你的魔法星升到<font color='#ff0000'> %d </font>级啦！",itemGSID, addE, addM, bean.mlel);
										_guihelper.MessageBox(_str);
										_s = string.format("你的魔法星增加了: %d点能量值,%d点M值，升到%d级",addE, addM, bean.mlel);
									else
										_str = string.format("太棒了，你使用了<pe:item gsid='%d' style='width:24px;height:24px;' isclickable='false'/>为你的魔法星增加了<font color='#ff0000'>能量值：%d点   M值：%d点</div>",itemGSID, addE, addM);
										_guihelper.MessageBox(_str);	
										_s=string.format("你的魔法星增加了：%d点能量值,%d点M值",addE, addM);
									end

									local Combat = commonlib.gettable("MyCompany.Aries.Combat");
									local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
									ChatChannel.AppendChat({
												ChannelIndex = ChatChannel.EnumChannels.ItemObtain, 
												fromname = "", 
												fromschool = Combat.GetSchool(), 
												fromisvip = false, 
												words = _s,
												is_direct_mcml = true,
												bHideSubject = true,
												bHideTooltip = true,
												bHideColon = true,
											});                                          
								end, "access plus 0 day");                                            
	                        end, function()  end);
						end
					end
				end,_guihelper.MessageBoxButtons.YesNo);
			end
			return true;
		else
			local str = format("使用<pe:item gsid='%d' style='width:24px;height:24px;' isclickable='false'/>即可成为<pe:item gsid='%d' style='width:24px;height:24px;' isclickable='false'/>，享受多项游戏特权！你现在就要购买吗?",998,50400);
			s = s..str;
			_guihelper.MessageBox(s , function(result)
				if(result == _guihelper.DialogResult.Yes)then
					local command = System.App.Commands.GetCommand("Profile.Aries.PurchaseItemWnd");
					if(command) then
						command:Call({gsid = 998});-- 能量石
					end
				end
			end, _guihelper.MessageBoxButtons.YesNo);	
		end
	end
end

-- incremental id recording the DirectlyOpenGiftPack api call sequence for teen version
local DirectlyOpenGiftPack_seq = 1;
-- DirectlyOpenGiftPack api invoke pool
local DirectlyOpenGiftPack_pool = {};
-- DirectlyOpenGiftPack time out time
local DirectlyOpenGiftPack_timeout_time = 10000;

function ItemManager.DirectlyOpenGiftPack_callback_from_powerapi(seq, msg)
	local input_msg = DirectlyOpenGiftPack_pool[seq];
	local callbackFunc_after_bagrefresh;
	if(input_msg) then
		callbackFunc_after_bagrefresh = input_msg.callbackFunc_after_bagrefresh;
		DirectlyOpenGiftPack_pool[seq] = nil;
	end
	LOG.std(nil, "info", "DirectlyOpenGiftPack_callback_from_powerapi", msg);
	
	if(msg.issuccess) then
		ItemManager.UpdateBagItems(msg.updates, msg.adds, msg.stats, "DirectlyOpenGiftPack_callback_from_powerapi");
	end

	if(input_msg and input_msg.callbackFunc) then
		input_msg.callbackFunc(msg);
	end
	if(callbackFunc_after_bagrefresh) then
		callbackFunc_after_bagrefresh(msg);
	end
end

-- directly open gift pack
-- @param giftpack_gsid: gift pack gsid
-- @param callbackFunc: the callback function(msg) end
-- @param callbackFunc_after_bagrefresh: callback function after the bag refresh
-- @param timeout_callback: time out callback function
function ItemManager.DirectlyOpenGiftPack(giftpack_gsid, callbackFunc, callbackFunc_after_bagrefresh, timeout_callback)
	if(not giftpack_gsid) then
		LOG.std("", "error", "Item", "ItemManager.DirectlyOpenGiftPack got invalid input:"..commonlib.serialize({giftpack_gsid, callbackFunc}));
		return;
	end
	
	DirectlyOpenGiftPack_seq = DirectlyOpenGiftPack_seq + 1;
	
	local msg = {
		seq = DirectlyOpenGiftPack_seq,
		gsid = giftpack_gsid,
	};

	System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="DirectlyOpenGiftPack", params = msg});
	
	-- keep reference of the callback function and push to invoke pool
	msg.callbackFunc = callbackFunc;
	msg.callbackFunc_after_bagrefresh = callbackFunc_after_bagrefresh;
	DirectlyOpenGiftPack_pool[DirectlyOpenGiftPack_seq] = msg;

	-- start a timer for each api, if not returned in limited time call the timeout callback
	if(timeout_callback) then
		UIAnimManager.PlayCustomAnimation(DirectlyOpenGiftPack_timeout_time, function(elapsedTime)
			if(elapsedTime == DirectlyOpenGiftPack_timeout_time) then
				if(DirectlyOpenGiftPack_pool[DirectlyOpenGiftPack_seq]) then
					DirectlyOpenGiftPack_pool[DirectlyOpenGiftPack_seq] = nil;
				end
				timeout_callback();
			end
		end);
	end
end