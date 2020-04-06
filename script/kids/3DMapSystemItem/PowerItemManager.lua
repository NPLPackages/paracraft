--[[
Title: Power Item Manager
Author(s): WangTian
Date: 2010/8/23
TODO: write some comment
Desc: Each item has an id in the GlobalStore. 
	Item system allows all users to pick, carry, use, sell, buy, wear items. The big picture is a set of worlds which 
	consists of various items and the related application upon them. The original implementation includes models, characters, animations 
	and many others that can be either officially packed or user generated. Currently we only take portion of the original design 
	for Aries item system.
	Global Store holds information on every item that exists in ParaWorld. All items are created from their information stored in this table.
	It works like a template that all item entities are instances of the item template. 
	
developer accessable functions:

SETS:
	PowerItemManager.PurchaseItem
	PowerItemManager.PurchaseItemBatch
	PowerItemManager.DestroyItem
	PowerItemManager.SetServerData
	PowerItemManager.AddExp
	PowerItemManager.AddJoybean
	PowerItemManager.AddExpJoybeanLoots

GETS:
	PowerItemManager.GetGlobalStoreItemInMemory
	PowerItemManager.GetUserAndDragonInfoInMemory
	PowerItemManager.GetItemByGUID
	PowerItemManager.GetItemCountInBag
	PowerItemManager.GetItemByBagAndOrder
	PowerItemManager.GetItemByBagAndPosition
	PowerItemManager.IfOwnGSItem
	PowerItemManager.GetGSItemTotalCopiesInMemory

NOTE: if you want to complete an operation with MORE THAN ONE API, inform andy to create a SINGLE purpose API for you

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/PowerItemManager.lua");
------------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemApp/API/AriesPowerAPI/AriesServerPowerAPI.lua");
NPL.load("(gl)script/apps/Aries/Items/item.addonlevel.lua");
NPL.load("(gl)script/apps/Aries/GoldRankingList/ranking_server.lua");

local LOG = LOG;
local type = type;
local tonumber = tonumber;
local PowerItemManager = commonlib.gettable("Map3DSystem.Item.PowerItemManager");
local addonlevel = commonlib.gettable("MyCompany.Aries.Items.addonlevel");
local Player = commonlib.gettable("MyCompany.Aries.Combat_Server.Player");
local gateway = commonlib.gettable("Map3DSystem.GSL.gateway");
local RankingServer = commonlib.gettable("MyCompany.Aries.GoldRankingList.RankingServer");

-- combat server
local combat_server = commonlib.gettable("MyCompany.Aries.Combat_Server.combat_server");

-- hosting users, if it is not included
-- NOTE: hosting_users[nid] = true
local hosting_users = {};

-- record all user items that the game server is hosting
-- NOTE: items_all[nid][guid] --> items data table
local items_all = {};

-- record all user bag item guids 
-- NOTE: bags_all[nid][bag] --> item guids table
local bags_all = {};

-- record all user and dragon info
-- NOTE: userinfo_all[nid] --> user and dragon info
local userinfo_all = {};

-- internet cafe nids
local internet_cafe_nids = {};

-- global store template table, mapping all gsid and gsitem
local globalstore_templates = {};

-- default powerapi timeout time
local default_powerapi_timeout_time = 10000;

local vip_bonus_exp = {0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1};

local vip_bonus_exp_teen = {0, 0.2, 0.25, 0.3, 0.35, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9};

local Cards_Canot_Be_Destroyed_to_MagicDirt = nil;

-- NOTE: only bag in bags_live_update will keep update with the db server
--		 the cache consumes game server memory, PowerItemManager.SyncUserItems() will be invoked to sync items in these bags 
--		 once a new user agent is created, when user logout of the game server due to timeout or explicit logout, 
--		 user cache will be destroyed immediately
-- bags that need live update with in-memory cache mechanism
local bags_live_update = {
	[0] = true, -- user avatar equipment
	[1] = true, -- user equipment bag
	[25] = true, -- combat card (runes)
	--[46] = true, -- Home Outdoor Parterre
	--[998] = true, -- Quest System Item Bag
	[999] = true, -- Quest System Item Bag
	[10010] = true, -- follow pet bag
	[31001] = true, -- instance related
	[31401] = true, -- christmas business bag
	[14] = true, -- Combat Collectable
	[1003] = true, -- Combat System related Bag
	[10062] = true, -- for ranking points
	--[30011] = true, -- dragon quest template
	[12] = true, -- Collectable NOTE 2012/10/30: for real quest items most of them is in bag 12
};
-- bags that need live update when enter combat
local bags_combat_update = {
	0, -- user avatar equipment
	1, -- user equipment bag
	24, -- CardQualification bag, NOTE: for entercombat card qualification check
	25, -- combat card (runes)
	10010, -- follow pet bag
	14, -- Combat Collectable
	1003, -- Combat System related Bag
	10062, -- for ranking points
};
-- NOTE: if a bag id is 
-- | bags_live_update | bags_client_aware_update | update client |
-- |       true       |           true           |      yes      |
-- |       nil        |           true           |      yes      |
-- |       true       |           nil            |      no       |
-- |       nil        |           nil            |      yes      |
-- bags that need update for client
local bags_client_aware_update = {
	[0] = true, -- user avatar equipment
	[1] = true, -- user equipment bag
	[12] = true, -- collectable bag
	[15] = true, -- achievement bag
	[24] = true, -- combat card (cards)
	[25] = true, -- combat card (runes)
	[10010] = true, -- follow pet bag
	[31001] = true, -- instance related
	[31401] = true, -- christmas business bag
	[14] = true, -- Combat Collectable
	[1003] = true, -- Combat System related Bag
	[10062] = true, -- medals
};

-- cache string that avoid concat the string every time
local bags_live_update_bagstr = "";
local b, _;
for b, _ in pairs(bags_live_update) do
	bags_live_update_bagstr = bags_live_update_bagstr..b..",";
end

-- cache string that avoid concat the string every time
local bags_combat_update_bagstr = "";
local _, b;
for _, b in pairs(bags_combat_update) do
	bags_combat_update_bagstr = bags_combat_update_bagstr..b..",";
end


-- inform the uses to update bags
-- NOTE: most of the bags are updated according to live update which is not sync with the client
--		if any web api in game server modify to that piece of bag region will pend an inform message for client to update by itself
-- inform_update_bags[nid][bag] = true;
local inform_update_bags = {};

-- get inform_update_bags
function PowerItemManager.GetInformUpdateBags()
	return inform_update_bags;
end

-- clear inform_update_bags
function PowerItemManager.ClearInformUpdateBags()
	inform_update_bags = {};
end


-- NOTE: game server already added a seqence number also called seq
--		 in fact this game server seq is rather an ID than a SEQ, it is only used to identify 
--		 which callback function to call and which data to put in the callback params.
--		 the power item server utilize a real seqence to keep items update with the timeline
-- EXAPMLE: a classic bug without the seqence is:
--		 suppose we have a GetItemsInBag and DestroyItem API, first we call the GetItemsInBag to fetch the bag 12 items, 
--		 then we DestroyItem a copy of 17008(with BagFamily 12) item, but the DestroyItem arrives first to update the cache with 
--		 the removed version of bag 12, and the GetItemsInBag arrives last to refresh the bag with the data 
--		 before the DestroyItem is performed, then in-memory function will receive an expired bag items
-- SOLUTION: as the previous example stated, we introduce the sequence to make sure all API invokes and returns in a timely order
--		 each user has an API queue, one API will be put in the queue if there is some API un-returned, or invoke immediately if queue is empty
--		 so there is only API travaling in network at a time for each user. each user has his own queue, since most functions require only
--		 modification to his belongings.
-- NOTE: queues[nid][seq] --> queue
--		 queues[nid].head --> queue head
--		 queues[nid].rear --> queue rear
local queues = {};


--[[
-- call webapi in queue
-- NOTE: this function is called immediately after each webapi, no matter the api is returned successfully or timedout
-- @param nid: user nid
local function CallPowerWebAPIInUserQueue(nid)
	local queue_user = queues[nid];
	if(not queue_user) then
		return;
	end
	if(queue_user and not queue_user.processing_head and queue_user.head < queue_user.rear) then
		-- pop from the user API queue
		local head = queue_user[queue_user.head];
		local API_wrapper = head[1];
		local input_msg = head[2];
		local queuename = head[3];
		local callbackFunc = head[4];
		local timeout_time = head[5];
		local timeout_func = head[6];
		queue_user.processing_head = true;
		-- call the function immediately
		API_wrapper(input_msg, queuename, function(...)
			local queue_user = queues[nid];
			if(not queue_user) then
				return;
			end
			queue_user.processing_head = nil;
			if(queue_user[queue_user.head]) then
				queue_user[queue_user.head] = nil;
				queue_user.head = queue_user.head + 1;
			end
			-- return callback
			callbackFunc(...);
			CallPowerWebAPIInUserQueue(nid);
		end, nil, timeout_time or default_powerapi_timeout_time, function()
			local queue_user = queues[nid];
			if(not queue_user) then
				return;
			end
			queue_user.processing_head = nil;
			if(queue_user[queue_user.head]) then
				queue_user[queue_user.head] = nil;
				queue_user.head = queue_user.head + 1;
			end
			-- timeout callback
			if(timeout_func) then
				timeout_func();
			end
			CallPowerWebAPIInUserQueue(nid);
		end);
	end
end

-- call specific web api for user nid
-- @param nid: user nid
-- @param API_wrapper: wrapper function object
-- @param rest of them: the params needed for api wrapper
local function CallPowerWebAPI(nid, API_wrapper, input_msg, queuename, callbackFunc, timeout_time, timeout_func)
	if(not nid or not API_wrapper or not input_msg or not queuename or not callbackFunc) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.CallPowerWebAPI got invalid input: "..
			commonlib.serialize_compact({nid, API_wrapper, input_msg, queuename}));
		return;
	end
	if(not queues[nid]) then
		-- the user API queue is not created before
		queues[nid] = {
			head = 1,
			rear = 1,
			processing_head = nil,
		};
	end
	local queue_user = queues[nid];
	-- push to the user API queue
	queue_user[queue_user.rear] = {API_wrapper, input_msg, queuename, callbackFunc, timeout_time, timeout_func};
	queue_user.rear = queue_user.rear + 1;
	-- try to call in api queue
	CallPowerWebAPIInUserQueue(nid)
end

]]

-- the new api
local function CallPowerWebAPI(nid, API_wrapper, input_msg, queuename, callbackFunc, timeout_time, timeout_func)
	if(API_wrapper and nid) then
		API_wrapper(input_msg, tostring(nid), callbackFunc, nil, timeout_time or default_powerapi_timeout_time, timeout_func);
	else
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.CallPowerWebAPI got invalid input: "..commonlib.serialize_compact({nid, API_wrapper, input_msg, queuename}));
	end
end

-- proceed user login process, including:
--		global store item init
-- @param callbackFunc: callback function to be invoked after game server login process is completed
function PowerItemManager.Proc_GameServerLogin(callbackFunc)
	-- step 1: sync global store items
	PowerItemManager.SyncGlobalStore(callbackFunc);
	-- validate special list nids if not
	PowerItemManager.ValidateSpecialListIfNot();
	-- validate operational config if not
	PowerItemManager.ValidateOperationalConfigIfNot();
end

local success_msg = {issuccess = true};
local unsuccess_msg = {issuccess = false};
-- proceed user login process, including:
--		sync essential bag items
--		sync user and dragon info
-- @param nid: user nid
-- @param worldpath: user login world path
-- @param callbackFunc: callback function to be invoked after user login process is completed, if success {issuccess = true}, if skipped {isskipped = true}
function PowerItemManager.Proc_UserLogin(nid, worldpath, callbackFunc, timeoutFunc)
	nid = tonumber(nid);
	if(not nid) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.Proc_UserLogin got nil nid");
		return;
	end

	local ip = NPL.GetIP(tostring(nid));

	if(PowerItemManager.IsIPInInternetCafeList(ip)) then
		internet_cafe_nids[nid] = true;
	else
		internet_cafe_nids[nid] = nil;
	end
	
	LOG.std(nil, "info", "PowerItemManager", "user "..tostring(nid).." login with ip: "..tostring(ip));

	-- NOTE 2010/11/29: force update the user information including bag items
	--
	---- NOTE: this function may be called multiple times we make sure the data inside is in consistent cache maintaince
	----		 so we skipped user item sync process and the user info fetch process
	--if(hosting_users[nid] == true) then
		--LOG.std(nil, "info", "PowerItemManager", "PowerItemManager.Proc_UserLogin got already logged in user: %s, process skipped", tostring(nid));
		--callbackFunc({isskipped = true});
		--return;
	--end
	-- marked as hosting client
	hosting_users[nid] = true;
	-- step 1: sync essential bag items
	PowerItemManager.SyncUserItems(nid, nil, function(msg)
		if(msg.issuccess_webapi) then
			-- step 2: sync user and dragon info
			PowerItemManager.GetUserAndDragonInfo(nid, function(msg)
				if(msg and msg.issuccess_webapi) then
					if(callbackFunc) then
						callbackFunc(success_msg);
					end
					-- continue with post user login process
					PowerItemManager.Proc_PostUserLogin(nid, worldpath)
				else
					if(callbackFunc) then
						callbackFunc(unsuccess_msg);
					end
				end
			end, timeoutFunc)
		else
			if(callbackFunc) then
				callbackFunc(unsuccess_msg);
			end
		end
	end, timeoutFunc);
end

-- process post user login, including:
--		remove specific user items
-- @param nid: user nid
function PowerItemManager.Proc_PostUserLogin(nid, worldpath)
	-- parse the original world path, the world path might be "worlds/Instances/HaqiTown_TrialOfChampions_Amateur/?nid=4"
	local worldpath_original = string.match(worldpath, "^[^?]+");
	-- for pvp instance delete the pvp ticket items
	local is_pvp_trialofchampions = false;
	if(worldpath_original == "worlds/Instances/HaqiTown_TrialOfChampions_Amateur/") then
		is_pvp_trialofchampions = true;
	elseif(worldpath_original == "worlds/Instances/HaqiTown_TrialOfChampions_Intermediate/") then
		is_pvp_trialofchampions = true;
	elseif(worldpath_original == "worlds/Instances/HaqiTown_TrialOfChampions_Master/") then
		is_pvp_trialofchampions = true;
	end
	-- for pvp instance delete the pvp ticket items
	local is_pvp_redmushroom = false;
	if(worldpath_original == "worlds/Instances/HaqiTown_RedMushroomArena/") then
		is_pvp_redmushroom = true;
	end

	-- destroy ticket for players enter the trialofchampions instance
	if(is_pvp_trialofchampions == true and System.options.version ~= "teen") then
		-- 12003_FreePvPTicket
		-- 12004_ForSalePvPTicket
		local has_12003, guid_12003 = PowerItemManager.IfOwnGSItem(nid, 12003);
		local has_12004, guid_12004 = PowerItemManager.IfOwnGSItem(nid, 12004);
		if(has_12003) then
			-- destroy free ticket if available
			local items = {[guid_12003] = 1};
			PowerItemManager.DestroyItemBatch(nid, items, function(msg) 
				-- tell the client to update hp
				local gridnode = gateway:GetPrimGridNode(tostring(nid));
				if(gridnode) then
					local server_object = gridnode:GetServerObject("sPowerAPI");
					if(server_object) then
						server_object:SendRealtimeMessage(tostring(nid), "[Aries][PowerAPI]FullHPAfterPvPTickerCost:1");
					end
				end
			end);
		elseif(has_12004) then
			-- destroy on sale ticket if available
			local items = {[guid_12004] = 1};
			PowerItemManager.DestroyItemBatch(nid, items, function(msg) 
				-- tell the client to update hp
				local gridnode = gateway:GetPrimGridNode(tostring(nid));
				if(gridnode) then
					local server_object = gridnode:GetServerObject("sPowerAPI");
					if(server_object) then
						server_object:SendRealtimeMessage(tostring(nid), "[Aries][PowerAPI]FullHPAfterPvPTickerCost:1");
					end
				end
			end);
		end
	end

	-- destroy ticket for players enter the red mushroom instance
	if(is_pvp_redmushroom == true) then
		---- 12005_ArenaFreeTicket
		---- 12006_ForSaleArenaPvPTicket
		--local has_12005, guid_12005 = PowerItemManager.IfOwnGSItem(nid, 12005);
		--local has_12006, guid_12006 = PowerItemManager.IfOwnGSItem(nid, 12006);
		--if(has_12005) then
			---- destroy free ticket if available
			--local items = {[guid_12005] = 1};
			--PowerItemManager.DestroyItemBatch(nid, items, function(msg) 
				---- tell the client to update hp
				--local gridnode = gateway:GetPrimGridNode(tostring(nid));
				--if(gridnode) then
					--local server_object = gridnode:GetServerObject("sPowerAPI");
					--if(server_object) then
						--server_object:SendRealtimeMessage(tostring(nid), "[Aries][PowerAPI]FullHPAfterPvPTickerCost:1");
					--end
				--end
			--end);
		--elseif(has_12006) then
			---- destroy on sale ticket if available
			--local items = {[guid_12006] = 1};
			--PowerItemManager.DestroyItemBatch(nid, items, function(msg) 
				---- tell the client to update hp
				--local gridnode = gateway:GetPrimGridNode(tostring(nid));
				--if(gridnode) then
					--local server_object = gridnode:GetServerObject("sPowerAPI");
					--if(server_object) then
						--server_object:SendRealtimeMessage(tostring(nid), "[Aries][PowerAPI]FullHPAfterPvPTickerCost:1");
					--end
				--end
			--end);
		--end
	end
end

-- process user logout, including:
--		clear user infos
--		clear items
--		clear bags
--		webapi queue
-- @param nid: user nid
function PowerItemManager.Proc_UserLogout(nid)
	nid = tonumber(nid);
	if(not nid) then
		-- LOG.std(nil, "info", "PowerItemManager", "PowerItemManager.Proc_UserLogout got nil nid: "..tostring(nid));
		return;
	end

	if(hosting_users[nid]) then
		LOG.std(nil, "system", "PowerItemService", "we see a user %s left us", nid);
	end
	-- marked as non hosting client
	hosting_users[nid] = nil;
	-- clear all user related memory
	items_all[nid] = nil;
	bags_all[nid] = nil;
	userinfo_all[nid] = nil;
	queues[nid] = nil;
	
	-- clear internet cafe nids
	internet_cafe_nids[nid] = nil;

	-- TODO: clear the player_server object
	-- clear the serverdata parse string mapping table
	if(Player.ClearServerDataParseMapping) then
		Player.ClearServerDataParseMapping(nid);
	end
end

-- is hosting the user items in memory
-- @param nid: user nid
function PowerItemManager.IsHosting(nid)
	if(not nid) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.IsHosting got nil nid: "..tostring(nid));
		return;
	end
	if(hosting_users[nid]) then
		return true;
	end
	return false;
end

---- this is the original batch version of the globalstore items read process
---- sync global store template items for game server
---- @param callbackFunc: callback function to be invoked after all global store template items are fetched successfully
--function PowerItemManager.SyncGlobalStore2(callbackFunc)
	--LOG.std(nil, "info", "PowerItemManager", "PowerItemManager.SyncGlobalStore started");
	--
	---- read gsid region from config file
	--local filename = "config/Aries/GlobalStore.IDRegions.xml";
	--local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	--if(not xmlRoot) then
		--LOG.std(nil, "error", "PowerItemManager", "error: failed loading GlobalStore.IDRegions config file: %s, using default", filename);
		---- use default config file xml root
		--xmlRoot = 
		--{
		  --{
			--{
			  --attr={ from=999, to=999 },
			  --n=1,
			  --name="region" 
			--},
			--n=1,
			--name="gsidregions" 
		  --},
		  --n=1 
		--};
	--end
	--
	--local gsidRegions = {};
	--local node;
	--for node in commonlib.XPath.eachNode(xmlRoot, "/gsidregions/region") do
		--if(node.attr and node.attr.from and node.attr.to) then
			--table.insert(gsidRegions, {tonumber(node.attr.from), tonumber(node.attr.to)});
		--end
	--end
	--
	---- TODO: global store regions are read from the GetServerList file
	---- TODO: we can also specify some of the regions are newly modified, with a cache policy 
	--
	---- direct gsid regions are deprecated and switch to xml config
	----local gsidRegions = {
		----{998, 999}, -- user avatar base ccs info
		----{1001, 1215}, -- avatar apparels and hand-held
		----{9001, 9010}, -- character animation
		----{9501, 9504}, -- throwable
		----{10001, 10001}, -- mount pet dragon
		----{10101, 10131}, -- follow pet
		----{11001, 11012}, -- mount pet apparel and base color
		----{15001, 15002}, -- pet animation
		----{16001, 16050}, -- consumable
		----{17001, 17095}, -- collectable
		----{19001, 19003}, -- reading
		----{20001, 20020}, -- medals
		----{21001, 21006}, -- quest related, acinus
		----{21101, 21104}, -- skill levels
		----{30001, 30134}, -- home land items
		----{39101, 39103}, -- homeland template
		----{50001, 50006}, -- quest tags
		----{50010, 50302}, -- quest tags
	----};
	--
	---- each api is requested in set of 10 global store ids
	--local gsidLists = {};
	--local accum = 0;
	--local gsids = "";
	--local _, pair;
	--for _, pair in ipairs(gsidRegions) do
		--local i;
		--for i = pair[1], pair[2] do
			--accum = accum + 1;
			--gsids = gsids..i..",";
			--if(accum == 10) then
				--gsidLists[gsids] = false;
				--accum = 0;
				--gsids = "";
			--end
		--end
	--end
	--if(gsids ~= "") then
		--gsidLists[gsids] = false;
	--end
	--local i = 0;
	--local gsids, hasReplied;
	--for gsids, hasReplied in pairs(gsidLists) do
		--i = i + 1;
		--local input_msg = {
			--gsids = gsids,
		--};
		---- NOTE: nid = 0 for game server
		--CallPowerWebAPI(0, paraworld.PowerAPI.globalstore.read, input_msg, "PowerItemManager_SyncGlobalStore_Batch_"..i, function(msg)
			---- TODO: we don't care if the globalstore item templates are really replied, response is success
			----		for more unknown item templates please refer to Item_Unknown for late item visualization or manipulation
			---- NOTE: global store item can be directly accessed from memory by ItemManager.GetGlobalStoreItemInMemory(gsid);
			--if(type(msg) ~= "table" or not msg.globalstoreitems) then
				--LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SyncGlobalStore got invalid return msg: "..commonlib.serialize_compact(msg));
				--return;
			--else
				--local _, gsItem;
				--for _, gsItem in pairs(msg.globalstoreitems) do
					--globalstore_templates[gsItem.gsid] = gsItem;
					---- parse stats
					--globalstore_templates[gsItem.gsid].template.stats = {};
					--local i;
					--for i = 1, 10 do
						--local type = gsItem.template["stat_type_"..i]
						--if(type ~= 0) then
							--globalstore_templates[gsItem.gsid].template.stats[type] = gsItem.template["stat_value_"..i];
						--end
					--end
				--end
			--end
			--gsidLists[gsids] = true;
			--local allReplied = true;
			--local _, bReply;
			--for _, bReply in pairs(gsidLists) do
				--if(bReply == false) then
					--allReplied = false;
					--break;
				--end
			--end
			--if(allReplied == true) then
				--callbackFunc();
			--end
		--end, 10000, function(msg)
			--LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SyncGlobalStore timedout");
		--end)
	--end
--end

function PowerItemManager.GetGlobalStoreTemplate()
	return globalstore_templates;
end

-- sync global store template items for game server
-- @param callbackFunc: callback function to be invoked after all global store template items are fetched successfully
function PowerItemManager.SyncGlobalStore(callbackFunc)
	LOG.std(nil, "info", "PowerItemManager", "PowerItemManager.SyncGlobalStore started");

	-- initialize addonlevel
	addonlevel.init();
	
	-- initialize card pack
	PowerItemManager.InitCardPack();
	PowerItemManager.InitGiftPack();

	if(System.options.localGSL) then
		NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.globalstore.lua");
		globalstore_templates = paraworld.globalstore.read_from_cache("*");
		if(globalstore_templates) then
			if(callbackFunc) then
				callbackFunc();
			end
			return;
		end
	end
	local input_msg = {
		gsids = "", -- fetch all global store items
	};
	-- NOTE: nid = 0 for game server
	CallPowerWebAPI(0, paraworld.PowerAPI.globalstore.GetALLGS, input_msg, "PowerItemManager_SyncGlobalStore", function(msg)
		-- TODO: we don't care if the globalstore item templates are really replied, response is success
		--		for more unknown item templates please refer to Item_Unknown for late item visualization or manipulation
		-- NOTE: global store item can be directly accessed from memory by ItemManager.GetGlobalStoreItemInMemory(gsid);
		if(type(msg) ~= "table" or not msg.globalstoreitems) then
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SyncGlobalStore got invalid return msg: "..commonlib.serialize_compact(msg));
			return;
		else
			LOG.std(nil, "info", "PowerItemManager", "PowerItemManager.SyncGlobalStore data fetched from database server");
			for _, gsItem in pairs(msg.globalstoreitems) do
				globalstore_templates[gsItem.gsid] = gsItem;
				-- parse stats
				globalstore_templates[gsItem.gsid].template.stats = {};
				local i;
				for i = 1, 10 do
					local type = gsItem.template["stat_type_"..i]
					if(type ~= 0) then
						globalstore_templates[gsItem.gsid].template.stats[type] = gsItem.template["stat_value_"..i];
					end
				end
				-- parse stats in description
				local json_str, desc = string.match(gsItem.template.description, "^(%[[^%[]*%])(.*)$");
				
				if(desc) then
					gsItem.template.description = desc;
				end
				if(json_str) then
					gsItem.template.description = desc or "";
					local description_stats = {};
					NPL.FromJson(json_str, description_stats);
					local _, _pair;
					for _, _pair in pairs(description_stats) do
						gsItem.template.stats[_pair.k] = _pair.v;
					end
				end
				-- NOTE 2012/1/9: globalstore item with 137 for aution house school filtering
				--				  close this stat on local globalstoreitem
				if(gsItem.template.class == 18) then
					gsItem.template.stats[137] = nil;
				end
			end
			if(callbackFunc) then
				callbackFunc();
			end
		end
	end, 60000, function(msg)
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SyncGlobalStore timedout");
	end)
end

-- Get global store item templates
-- @param gsids: global store id
-- @return: item template, nil if not found in memory
function PowerItemManager.GetGlobalStoreItemInMemory(gsid)
	return globalstore_templates[gsid];
end

-- one time sync with the db server
-- NOTE: the user item data is first created in game server memory via this function
--		 rest of the functions that need item data to be valid, such as questing and combat system, will be delayed 
--		 till the sync process is completed, any error will stop the rest of the process, GSL need to handle the rest
--		 invoke the sync process again or timeout
-- @param nid: user nid
-- @param callbackFunc: callback function that will be called after the sync process
-- @param timeoutFunc: callback function when webapi call timeout
-- @param timeout_time: timeout time
local PowerItemManager_SyncUserItems_timeout_time = 10000;
function PowerItemManager.SyncUserItems(nid, limited_bags, callbackFunc, timeoutFunc, timeout_time)
	nid = tonumber(nid);
	if(not nid) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SyncUserItems got nil nid");
		return;
	end
	if(type(nid) == "string") then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SyncUserItems got string typed nid");
	end

	local sync_bags = bags_live_update_bagstr;
	if(limited_bags) then
		if(type(limited_bags) == "string") then
			sync_bags = limited_bags;
		else
			sync_bags = "";
			local _, bag;
			for _, bag in pairs(limited_bags) do
				if(bags_live_update[bag]) then
					sync_bags = sync_bags..bag..",";
				else
					commonlib.echo(bag)
					LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SyncUserItems got invalid limited_bags: "..commonlib.serialize_compact(limited_bags));
					return;
				end
			end
		end
	end
	-- get items for live update bags
	local input_msg = {
		nid = nid,
		bags = sync_bags,
		simp = 1, -- simplified item without obtaintime
	};
	CallPowerWebAPI(nid, paraworld.PowerAPI.inventory.GetItemsInBags, input_msg, "PowerItemManager_GetItemsInBags_for_"..nid, function(msg) 
		if(not msg or msg.errorcode or not msg.list) then
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SyncUserItems callback function got error msg: "..commonlib.serialize_compact(msg));
			if(callbackFunc) then
				callbackFunc(msg);
			end
			return;
		end
		-- store each bag items in memory
		local _, onebagmsg;
		for _, onebagmsg in ipairs(msg.list) do
			local msg = onebagmsg;
			if(type(msg) == "table" and msg.items and msg.bag) then
				-- put the data in cache
				PowerItemManager.StoreBagItems(nid, msg.bag, msg.items);
			else
				-- invalid bag items data
				LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SyncUserItems callback function got invalid bag data: "..commonlib.serialize_compact(msg));
			end
		end
		msg.issuccess_webapi = true;
		if(callbackFunc) then
			callbackFunc(msg);
		end
	end, timeout_time or PowerItemManager_SyncUserItems_timeout_time, function()
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SyncUserItems timeout");
		if(timeoutFunc) then
			timeoutFunc();
		end
	end);
end

-- one time sync with the db server
-- NOTE: usually when enter combat
-- @param nid: user nid
-- @param callbackFunc: callback function that will be called after the sync process
-- @param timeoutFunc: callback function when webapi call timeout
local PowerItemManager_SyncUserCombatItems_timeout_time = 5000;
function PowerItemManager.SyncUserCombatItems(nid, callbackFunc, timeoutFunc)
	PowerItemManager.SyncUserItems(nid, bags_combat_update_bagstr, callbackFunc, timeoutFunc, PowerItemManager_SyncUserCombatItems_timeout_time);
end

-- store the bag items in the in-memory cache
-- @param nid: user nid
-- @param bag: bag id
-- @param items: bag items
function PowerItemManager.StoreBagItems(nid, bag, items)
	nid = tonumber(nid);
	if(not nid or not bag or not items) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.StoreBagItems got invalid input: "..
			commonlib.serialize_compact({nid, bag, items}));
		return;
	end
	-- store the item data in the ItemManager
	items_all[nid] = items_all[nid] or {};
	local items_user = items_all[nid];
	bags_all[nid] = bags_all[nid] or {};
	local bags_user = bags_all[nid][bag];
	-- delete all items that previously inserted in item table
	if(bags_user) then
		local _, guid;
		for _, guid in ipairs(bags_user) do
			-- bug 2012/7/13: if we have a follow pet in bag 10010 and GetItemsInBag(0,10010)
			--		later the follow pet is switched to bag 0, then GetItemsInBag(0,10010) store bag items 
			--		will first store the item in bag 0 process and then clear the item in bag 10010 because this item guid
			--		is in the previously stored 10010 bag
			-- NOTE: only delete the item with the same bag
			--		always get bag 0 if a bag contains equipable item
			local item = items_user[guid];
			if(item and item.bag == bag) then
				items_user[guid] = nil;
			end
		end
	end
	-- sort the item table in position
	table.sort(items, function(a, b)
		return (a.position > b.position);
	end);
	local i = 0;
	local itemlist = {};
	local _, item;
	for _, item in ipairs(items) do
		if(item.copies > 0 and not (bag == 0 and item.position == 23)) then -- skip the school item
			-- filter only the items with available copies
			i = i + 1;
			table.insert(itemlist, item.guid);
			local item_obj = {
				nid = nid,
				order = i,
				guid = item.guid, 
				gsid = item.gsid,
				obtaintime = item.obtaintime,
				bag = bag,
				position = item.position,
				clientdata = item.clientdata or "",
				serverdata = item.serverdata or "",
				copies = item.copies,
			};
			local gsItem = PowerItemManager.GetGlobalStoreItemInMemory(item.gsid);
			if(gsItem) then
				if(gsItem.template.class == 1) then
					-- apparel item
					local gsItem = PowerItemManager.GetGlobalStoreItemInMemory(item_obj.gsid);
					if(gsItem) then
						if(string.find(string.lower(gsItem.category), "combat")) then
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_CombatApparel.lua");
							item_obj = Map3DSystem.Item.Item_CombatApparel:new(item_obj);
						end
					end
				end
				if(gsItem.template.class == 11 and gsItem.template.subclass == 1) then
					-- follow pet item
					NPL.load("(gl)script/kids/3DMapSystemItem/Item_FollowPet.lua");
					item_obj = Map3DSystem.Item.Item_FollowPet:new(item_obj);
				end
			end
			---- create power item manager item object
			--NPL.load("(gl)script/kids/3DMapSystemItem/Item_Unknown.lua");
			--item_obj = Map3DSystem.Item.Item_Unknown:new(item_obj);
			items_user[item_obj.guid] = item_obj;
		end
	end
	-- record the items in bag
	bags_all[nid][bag] = itemlist;
end

-- get user and dragon info
-- @param nid: user nid
-- @param callbackFunc: call back function of get userinfo
-- @param timeoutFunc: callback function when webapi call timeout
function PowerItemManager.GetUserAndDragonInfo(nid, callbackFunc, timeoutFunc)
	nid = tonumber(nid);
	if(not nid) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.GetUserAndDragonInfo got invalid input: "..
			commonlib.serialize_compact({nid}));
		return;
	end
	-- 2014.7.21: this fix an error of negative nid, Xizhi: find out where?
	if(nid<0) then
		nid = -nid;
	end
	-- get user and dragon ingo
	local input_msg = {
		nid = nid, 
	};
	CallPowerWebAPI(nid, paraworld.PowerAPI.users.GetUserAndDragonInfo, input_msg, "PowerItemManager_GetUserAndDragonInfo_for_"..nid, function(msg) 
		if(not msg or msg.errorcode or not msg.user) then
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.GetUserAndDragonInfo callback function got error msg: "..commonlib.serialize_compact(msg));
			if(callbackFunc) then
				callbackFunc(msg);
			end
			return;
		end

		if(msg and msg.user) then
			-- make sure all accessable fields are not nil
			local userinfo_this = msg.user;
			userinfo_this.pmoney = userinfo_this.pmoney or 0;
			userinfo_this.emoney = userinfo_this.emoney or 0;
			local dragoninfo_this = msg.dragon;
			if(dragoninfo_this) then
				dragoninfo_this.kindness = dragoninfo_this.kindness or 0;
				dragoninfo_this.strength = dragoninfo_this.strength or 0;
				dragoninfo_this.agility = dragoninfo_this.agility or 0;
				dragoninfo_this.intelligence = dragoninfo_this.intelligence or 0;
				dragoninfo_this.archskillpts = dragoninfo_this.archskillpts or 0;
				dragoninfo_this.combatexp = dragoninfo_this.combatexp or 0;
				dragoninfo_this.combatlel = dragoninfo_this.combatlel or 0;
				dragoninfo_this.nextlevelexp = dragoninfo_this.nextlevelexp or 0;
			end

			-- keep user and dragon info reference
			userinfo_all[nid] = {user = userinfo_this, dragon = dragoninfo_this};

			msg.issuccess_webapi = true;
			if(callbackFunc) then
				callbackFunc(msg);
			end
		else
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.GetUserAndDragonInfo callback function got error msg: "..commonlib.serialize_compact(msg));
		end
	end, nil, function()
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.GetUserAndDragonInfo timeout");
		if(timeoutFunc) then
			timeoutFunc();
		end
	end);
end

-- get user and dragon info in memory
-- @param nid: user nid
function PowerItemManager.GetUserAndDragonInfoInMemory(nid)
	if(not nid) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.GetUserAndDragonInfoInMemory got invalid nid: "..tostring(nid));
		return;
	end
	return userinfo_all[nid];
end

-- check date from combat_server, if changed date, update the user obtain count for client
local last_date = nil;
function PowerItemManager.OnCheckDate(combat_server_uid)
	local date = ParaGlobal.GetDateFormat("yyyy-M-d");
	if(not last_date) then
		last_date = date;
	else
		if(last_date ~= date) then
			last_date = date;
			-- TODO: refresh the user data on game server
			-- broadcast hosting clients to refresh obtain time
			combat_server.AppendRealTimeMessage(combat_server_uid, "NewDay:1");
		end
	end
end

local special_list = nil;
-- is in special id list
function PowerItemManager.IsInSpecialList(nid)
	if(nid and special_list and special_list[nid]) then
		return true;
	end
	return false;
end
-- read special ids from list
function PowerItemManager.ValidateSpecialListIfNot()
	if(not special_list) then
		special_list = {};
		local list_file = "config/Aries/Others/specialids_teen_zhCN.xml";
		if(System.options.locale == "zhCN") then
			list_file = "config/Aries/Others/specialids_teen_zhCN.xml";
		end
		local xmlRoot = ParaXML.LuaXML_ParseFile(list_file);
		if(xmlRoot) then
			local locale = tostring(System.options.locale);
			LOG.std(nil, "info", "PowerItemManager", "PowerItemManager.ValidateSpecialListIfNot loaded locale "..locale.." file: "..list_file);
			local each_item;
			for each_item in commonlib.XPath.eachNode(xmlRoot, "/items/item") do
				local nid = tonumber(each_item.attr.id);
				if(nid) then
					special_list[nid] = true;
				end
			end
		end
	end
end

local internet_cafe_list = nil;
-- is IP in internet cafe list
function PowerItemManager.IsIPInInternetCafeList(ip)
	if(ip and internet_cafe_list and internet_cafe_list[ip]) then
		return true;
	end
	return false;
end
-- is user in internet cafe
function PowerItemManager.IsUserInInternetCafe(nid)
	if(nid and internet_cafe_nids[nid]) then
		return true;
	end
	return false;
end
-- validate operational config if not
function PowerItemManager.ValidateOperationalConfigIfNot()
	if(not internet_cafe_list) then
		internet_cafe_list = {};
		local list_file;
		if(System.options.locale == "zhCN") then
			list_file = "config/Aries/Op_Teen/InternetCafeIPs.zhTW.xml";
		elseif(System.options.locale == "zhTW") then
			list_file = "config/Aries/Op_Teen/InternetCafeIPs.zhTW.xml";
		end
		local xmlRoot = ParaXML.LuaXML_ParseFile(list_file);
		if(xmlRoot) then
			local locale = tostring(System.options.locale);
			LOG.std(nil, "info", "PowerItemManager", "PowerItemManager.ValidateOperationalConfigIfNot loaded locale "..locale.." file: "..list_file);
			local each_item;
			for each_item in commonlib.XPath.eachNode(xmlRoot, "/IPs/item") do
				local ip = each_item.attr.ip;
				if(ip) then
					local section_1_2_3, from, to = string.match(ip, "^(.+)%.(%d+)~(%d+)$");
					if(section_1_2_3 and from and to) then
						from = tonumber(from);
						to = tonumber(to);
						local _ = 0;
						for _ = from, to do
							internet_cafe_list[section_1_2_3..".".._] = true;
						end
					else
						internet_cafe_list[ip] = true;
					end
				end
			end
		end
	end
end

-- if user is vip in current session
-- @param nid: user nid
function PowerItemManager.IsVIP(nid)
	local useranddragon = PowerItemManager.GetUserAndDragonInfoInMemory(nid)
	if(useranddragon) then
		local dragoninfo = useranddragon.dragon;
		if(dragoninfo and dragoninfo.energy and dragoninfo.energy > 0) then
			return true;
		end
		-- teen version energy will not reduce
		if(System.options.version == "teen") then
			if(dragoninfo and dragoninfo.mlel and dragoninfo.mlel > 0) then
				return true;
			end
		end
	end
	return false;
end

local bActivated = nil;
-- is vip is activated
function PowerItemManager.IsActivated()
	--if(bActivated == nil) then
		--if(ParaIO.DoesFileExist("config/VIP.txt", false)) then
			--bActivated = true;
		--else
			--log("error: vip component is not activated\n")
			--bActivated = false;
		--end
	--end
	--return bActivated;
	return true;
end

-- is vip and activated
function PowerItemManager.IsVIPAndActivated(nid)
	return (PowerItemManager.IsVIP(nid) and PowerItemManager.IsActivated());
end

-- get magic star level
function PowerItemManager.GetMagicStarLevel(nid)
	local useranddragon = PowerItemManager.GetUserAndDragonInfoInMemory(nid)
	if(useranddragon) then
		local dragoninfo = useranddragon.dragon;
		if(dragoninfo) then
			return dragoninfo.mlel;
		end
	end
	return 0;
end

-- cost durability
-- @param nid: user nid
-- @param guids: item guid list
-- @param isdead: is player dead
-- @param callbackFunc: call back function of get userinfo
-- @param timeoutFunc: callback function when webapi call timeout
function PowerItemManager.CostDurablity(nid, guids, isdead, callbackFunc, timeoutFunc)
	nid = tonumber(nid);
	if(not nid or not guids) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.CostDurablity got invalid input: "..
			commonlib.serialize_compact({nid, guids}));
		return;
	end
	local guids_str = "";
	local _, guid;
	for _, guid in ipairs(guids) do
		guids_str = guids_str..guid.."|";
	end
	-- end combat cost durability
	local input_msg = {
		nid = nid, 
		items = guids_str,
		isdead = if_else(isdead, 1, 0),
	};
	CallPowerWebAPI(nid, paraworld.PowerAPI.users.EndFight, input_msg, "PowerItemManager_CostDurablity_for_"..nid, function(msg) 
		if(not msg or msg.errorcode) then
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.CostDurablity callback function got error msg: "..commonlib.serialize_compact(msg));
			if(callbackFunc) then
				callbackFunc(msg);
			end
			return;
		end

		if(callbackFunc) then
			callbackFunc(msg);
		end
		
		-- sync user equipable items
		PowerItemManager.SyncUserItems(tonumber(nid), {0,1,}, function(msg) end, function() end);
	end, nil, function()
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.CostDurablity timeout");
		if(timeoutFunc) then
			timeoutFunc();
		end
	end);
end

local double_exp_time = {
	["2011-03-18"] = {from = 14 * 60 + 0, to = 21 * 60 + 0},
	["2011-03-19"] = {from = 14 * 60 + 0, to = 21 * 60 + 0},
	["2011-03-20"] = {from = 14 * 60 + 0, to = 21 * 60 + 0},
	["2011-03-25"] = {from = 14 * 60 + 0, to = 21 * 60 + 0},
	["2011-03-26"] = {from = 14 * 60 + 0, to = 21 * 60 + 0},
	["2011-03-27"] = {from = 14 * 60 + 0, to = 21 * 60 + 0},

	-- test
	["2011-03-17"] = {from = 14 * 60 + 0, to = 21 * 60 + 0},

	--["2010-12-25"] = {from = 14 * 60 + 0, to = 16 * 60 + 0},
	--["2010-12-26"] = {from = 14 * 60 + 0, to = 16 * 60 + 0},
	--["2011-01-01"] = {from = 14 * 60 + 0, to = 16 * 60 + 0},
	--["2011-01-02"] = {from = 14 * 60 + 0, to = 16 * 60 + 0},
	--["2011-01-03"] = {from = 14 * 60 + 0, to = 16 * 60 + 0},
	--
	--["2010-12-24"] = {from = 19 * 60 + 30, to = 20 * 60 + 30},
	--["2010-12-27"] = {from = 19 * 60 + 30, to = 20 * 60 + 30},
	--["2010-12-28"] = {from = 19 * 60 + 30, to = 20 * 60 + 30},
	--["2010-12-29"] = {from = 19 * 60 + 30, to = 20 * 60 + 30},
	--["2010-12-30"] = {from = 19 * 60 + 30, to = 20 * 60 + 30},
	--["2010-12-31"] = {from = 19 * 60 + 30, to = 20 * 60 + 30},
	--
	---- test
	--["2010-12-22"] = {from = 10 * 60 + 30, to = 15 * 60 + 30},
	--["2010-12-23"] = {from = 10 * 60 + 30, to = 15 * 60 + 30},
};

local today_date_string = nil;

local today_double_exp_time = nil;

local today_date_is_holiday = nil;

function PowerItemManager.GetGlobalExpScaleAcc()
	
	if(today_date_is_holiday == nil) then
		NPL.load("(gl)script/ide/TooltipHelper.lua");
		local HolidayHelper = commonlib.gettable("CommonCtrl.HolidayHelper");
		if(System.options.version == "teen") then
			today_date_is_holiday = HolidayHelper.IsHoliday(date, true);
		else
			today_date_is_holiday = HolidayHelper.IsHoliday(date);
		end
	end
	
	local global_bonus = 1;
	if(System.options.version == "teen") then
		global_bonus = 0;
	end
	
	if(today_date_string == nil) then
		today_date_string = ParaGlobal.GetDateFormat("yyyy-MM-dd");
	end

	local time = ParaGlobal.GetTimeFormat("HH:mm");
	local hour, minute = string.match(time, "^(.-):(.-)$");
	if(hour and minute) then
		hour = tonumber(hour);
		minute = tonumber(minute);
		local current_time_mins = hour * 60 + minute;
		--if(today_double_exp_time.from and today_double_exp_time.from <= current_time_mins) then
			--if(today_double_exp_time.to and today_double_exp_time.to >= current_time_mins) then
				--global_bonus = 1;
			--end
		--end
		if(today_date_is_holiday) then
			if(System.options.version == "teen") then
				if((current_time_mins >= (19 * 60)) and (current_time_mins <= (23 * 60))) then
					global_bonus = 1;
				end
			else
				if((current_time_mins >= (19 * 60)) and (current_time_mins <= (24 * 60))) then
					global_bonus = 2;
				end
			end
		end
	end

	return global_bonus;
end

-- get exp pts scale
-- @param nid: user nid
function PowerItemManager.GetExpScaleAcc(nid)
	if(not nid) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.GetExpScale got invalid nid: "..tostring(nid));
		return;
	end
	
	local global_bonus = PowerItemManager.GetGlobalExpScaleAcc();

	if(PowerItemManager.IsUserInInternetCafe(nid)) then
		-- double base exp for specific internet cafe users
		global_bonus = global_bonus + 1;
	end

	if(PowerItemManager.IsVIPAndActivated(nid)) then
		local m_level = PowerItemManager.GetMagicStarLevel(nid);
		if(m_level) then
			-- NOTE: vip_bonus_exp config starts from index 1 which is m_level 0
			if(System.options.version == "teen") then
				return global_bonus + (vip_bonus_exp_teen[m_level + 1] or 0);
			else
				return global_bonus + (vip_bonus_exp[m_level + 1] or 0);
			end
		end
	end

	return global_bonus;
end

local days = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }
-- http://lua-users.org/wiki/DayOfWeekAndDaysInMonthExample
-- returns the day of week integer and the name of the week
-- Compatible with Lua 5.0 and 5.1.
-- from sam_lie 
local function get_day_of_week(dd, mm, yy) 
	local mmx = mm

	if (mm == 1) then  mmx = 13; yy = yy-1  end
	if (mm == 2) then  mmx = 14; yy = yy-1  end

	local val8 = dd + (mmx*2) +  math.floor(((mmx+1)*3)/5)   + yy + math.floor(yy/4)  - math.floor(yy/100)  + math.floor(yy/400) + 2
	local val9 = math.floor(val8/7)
	local dw = val8-(val9*7) 

	if (dw == 0) then
		dw = 7
	end

	return dw, days[dw];
end

function PowerItemManager.GetDayOfWeek(dd, mm, yy)
	if(dd and mm and yy) then
		return get_day_of_week(dd, mm, yy);
	end
end

-- get exp scale buff
-- @param nid: user nid
function PowerItemManager.GetExpScaleAcc_buff(nid)
	local exp_scale_acc_buff = 0;
	if(not nid) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.GetExpScale_buff got invalid nid: "..tostring(nid));
		return;
	end
	
	if(today_date_is_holiday == nil) then
		NPL.load("(gl)script/ide/TooltipHelper.lua");
		local HolidayHelper = commonlib.gettable("CommonCtrl.HolidayHelper");
		today_date_is_holiday = HolidayHelper.IsHoliday(date)
	end

	-- 40001_ExpPowerPotion_BuffCount
	-- 40003_ExpPowerPotion_BuffCount_Holiday
	-- 40006_ExpPowerPotionAdd10Times_BuffCount
	local has_40001, guid_40001 = PowerItemManager.IfOwnGSItem(nid, 40001);
	local has_40003, guid_40003;
	local has_40006, guid_40006;
	if(today_date_is_holiday == true) then
		-- skip buff test if not holiday
		has_40003, guid_40003 = PowerItemManager.IfOwnGSItem(nid, 40003);
	end
	if(System.options.version == "teen") then
		-- skip buff test if not teen version
		has_40006, guid_40006 = PowerItemManager.IfOwnGSItem(nid, 40006);
	end
	if((has_40001 and guid_40001) or (has_40003 and guid_40003) or (has_40006 and guid_40006)) then
		local guids = {};
		if(has_40001 and guid_40001) then
			exp_scale_acc_buff = exp_scale_acc_buff + 1;
			guids[guid_40001] = 1;
		end
		if(has_40003 and guid_40003) then
			exp_scale_acc_buff = exp_scale_acc_buff + 0.5;
			guids[guid_40003] = 1;
		end
		if(has_40006 and guid_40006) then
			exp_scale_acc_buff = exp_scale_acc_buff + 9;
			guids[guid_40006] = 1;
		end
		return exp_scale_acc_buff, guids;
	end
	return exp_scale_acc_buff;
end

-- update items with webapi return values
-- @param nid: user nid number. internally number is used. 
-- @param adds: added items
-- @param updates: update items
-- @param stats: changed stats
-- @param ignore_client_update: true to disable client bag auto update. 
function PowerItemManager.UpdateItemsWithAddsUpdatesStats(nid, adds, updates, stats, ignore_client_update)
	nid = tonumber(nid);
	if(not nid or not (adds or updates or stats)) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.UpdateItemsWithAddsUpdatesStats got invalid input: "..
			commonlib.serialize_compact({nid, adds, updates, stats}));
		return;
	end
	items_all[nid] = items_all[nid] or {};
	local items_user = items_all[nid];
	bags_all[nid] = bags_all[nid] or {};
	local bags_all_user = bags_all[nid];
	
	-- need force update inform bags
	local bNeedUpdateInformBags = false;

	-- update part of the process
	if(updates) then
		local _, update;
		for _, update in pairs(updates) do
			if( (update.guid and update.guid<=0) or (update.gsid and update.gsid<=0) ) then
				local useranddragoninfo_this = userinfo_all[nid];
				if(stats and useranddragoninfo_this and update.copies) then
					local userinfo_this = useranddragoninfo_this.user;
					local dragoninfo_this = useranddragoninfo_this.dragon;
					local gsid = update.gsid or update.guid;
					if(gsid == -1) then
						userinfo_this.pmoney = update.copies;
					elseif(gsid == 0) then
						userinfo_this.emoney = update.copies;
					elseif(gsid == -19) then
						dragoninfo_this.stamina = update.copies;
					elseif(gsid == -20) then
						dragoninfo_this.stamina2 = update.copies;
					elseif(gsid == -13) then
						dragoninfo_this.combatexp = update.copies;
					end
					if(not ignore_client_update) then
						-- inform the client to update the bag
						inform_update_bags[nid] = inform_update_bags[nid] or {};
						inform_update_bags[nid][-1] = true; -- bag -1 stands for user and dragon info update
						bNeedUpdateInformBags = true;
						LOG.std(nil, "info", "PowerItemManager", "PowerItemManager.UpdateItemsWithAddsUpdatesStats pending client update user and dragon info for nid: %d", nid);
					end
				end
			elseif(update.guid == -1) then
				
			else
				local item = items_user[update.guid];
				if(not item) then
					LOG.std(nil, "warn", "PowerItemManager", "PowerItemManager.UpdateItemsWithAddsUpdatesStats got invalid guid: %d", update.guid);
				else
					if(not update.bag) then
						update.bag = item.bag;
					end
					local bags_user = bags_all[nid][update.bag];
					-- we only update the bags that is live update
					if(bags_user and bags_live_update[update.bag]) then
						if(item.bag ~= update.bag) then
							LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.UpdateItemsWithAddsUpdatesStats got inequal bag between returned value and memory: "..
								commonlib.serialize_compact({item.bag, update.bag}));
						else
							-- NOTE: removed items could be with a cnt == -1, meaning items will be destroyed in memory
							--		 we don't make the memory sharp order swapping the bag itemlist to the latest order
							--		 instead we only update the item guids in the bag itemlist
							if(not item.copies) then
								item.copies = 1; 
							end
							item.copies = update.copies or (item.copies + update.cnt);
							if(update.serverdata) then
								item.serverdata = update.serverdata;
							end
							if(item.copies <= 0) then
								-- destroy the item in memory
								items_user[update.guid] = nil;
								-- update item guid in bag list
								-- NOTE: we don't keep the bag item as position ordered
								local _, guid_t;
								local index_t;
								for _, guid_t in ipairs(bags_user) do
									if(guid_t == update.guid) then
										index_t = _;
										break;
									end
								end
								if(index_t) then
									table.remove(bags_user, index_t);
								else
									LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.UpdateItemsWithAddsUpdatesStats removed item is not found in bag item list, bag: "..
										commonlib.serialize_compact({update.bag, item, bags_user}));
								end
							end
						end
					else
						LOG.std(nil, "warn", "PowerItemManager", "PowerItemManager.UpdateItemsWithAddsUpdatesStats update a non-live update bag: "..
							commonlib.serialize_compact({update}));
					end
				end
				local bag = update.bag;
				if(not ignore_client_update and bag) then
					-- NOTE: included in client aware or non of live and client aware bag is included
					if(bags_client_aware_update[bag] or (not bags_live_update[bag] and not bags_client_aware_update[bag])) then
						-- inform the client to update the bag
						inform_update_bags[nid] = inform_update_bags[nid] or {};
						inform_update_bags[nid][bag] = true;
						bNeedUpdateInformBags = true;
						LOG.std(nil, "info", "PowerItemManager", "PowerItemManager.UpdateItemsWithAddsUpdatesStats pending client update bag: %d for nid: %d", bag, nid);
					end
				end
			end
		end
	end
	
	-- add part of the process
	if(adds) then
		local _, add;
		for _, add in pairs(adds) do
			if(add.guid == -1) then
			else
				local bags_user = bags_all[nid][add.bag];
				-- we only add to the bags that is live update
				if(bags_user and bags_live_update[add.bag]) then
					local item = items_user[add.guid];
					local item_obj = {
						nid = nid,
						order = #bags_user + 1,
						guid = add.guid, 
						gsid = add.gsid,
						obtaintime = add.obtaintime,
						bag = add.bag,
						position = add.position,
						clientdata = add.clientdata or "",
						serverdata = add.serverdata or "",
						copies = add.cnt,
					};
					local gsItem = PowerItemManager.GetGlobalStoreItemInMemory(add.gsid);
					if(gsItem) then
						if(gsItem.template.class == 1) then
							-- apparel item
							local gsItem = PowerItemManager.GetGlobalStoreItemInMemory(add.gsid);
							if(gsItem) then
								if(string.find(string.lower(gsItem.category), "combat")) then
									NPL.load("(gl)script/kids/3DMapSystemItem/Item_CombatApparel.lua");
									item_obj = Map3DSystem.Item.Item_CombatApparel:new(item_obj);
								end
							end
						elseif(gsItem.template.class == 11 and gsItem.template.subclass == 1) then
							-- follow pet item
							NPL.load("(gl)script/kids/3DMapSystemItem/Item_FollowPet.lua");
							item_obj = Map3DSystem.Item.Item_FollowPet:new(item_obj);
						end
					end
					---- create power item manager item object
					--NPL.load("(gl)script/kids/3DMapSystemItem/Item_Unknown.lua");
					--item_obj = Map3DSystem.Item.Item_Unknown:new(item_obj);
					items_user[add.guid] = item_obj;
					table.insert(bags_user, add.guid);
				else
					LOG.std(nil, "warn", "PowerItemManager", "PowerItemManager.UpdateItemsWithAddsUpdatesStats add a non-live update bag: "..
						commonlib.serialize_compact({add}));
				end
				if(not ignore_client_update) then
					-- NOTE: included in client aware or non of live and client aware bag is included
					if(bags_client_aware_update[add.bag] or (not bags_live_update[add.bag] and not bags_client_aware_update[add.bag])) then
						-- inform the client to update the bag
						inform_update_bags[nid] = inform_update_bags[nid] or {};
						inform_update_bags[nid][add.bag] = true;
						bNeedUpdateInformBags = true;
						LOG.std(nil, "info", "PowerItemManager", "PowerItemManager.UpdateItemsWithAddsUpdatesStats pending client update bag: %d for nid: %d", add.bag, nid);
					end
				end
			end
		end
	end
	
	-- stats part of the process
	local useranddragoninfo_this = userinfo_all[nid];
	if(stats and useranddragoninfo_this) then
		local _, stat;
		for _, stat in pairs(stats) do
			local userinfo_this = useranddragoninfo_this.user;
			local dragoninfo_this = useranddragoninfo_this.dragon;
			-- update the user or dragon stats according to stats gsid and cnt
			-- NOTE: CYF web api comments:
			-- -1:P币；0:E币；-2:亲密度；-3:爱心值；-4:力量值；-5:敏捷值；-6:智慧值；-7:建筑熟练度；-8:抱抱龙等级；
			-- -9:体力值；-10:清洁值；-11:心情值；-12:健康状态；-13:战斗经验值；-14:战斗等级；
			-- -1000:抱抱龙升级到下一级所需的亲密度
			-- -1001:抱抱龙升级到下一级所需的战斗等级
			if(stat.gsid == -1) then
				userinfo_this.pmoney = userinfo_this.pmoney + stat.cnt;
			elseif(stat.gsid == 0) then
				userinfo_this.emoney = userinfo_this.emoney + stat.cnt;
			elseif(not dragoninfo_this and stat.gsid < -1) then
				LOG.std(nil, "warning", "PowerItemManager", "PowerItemManager.UpdateItemsWithAddsUpdatesStats got nil info for dragon stats update: "..
					commonlib.serialize_compact({dragoninfo_this, stat}));
			elseif(stat.gsid == -3) then
				dragoninfo_this.kindness = dragoninfo_this.kindness + stat.cnt;
			elseif(stat.gsid == -4) then
				dragoninfo_this.strength = dragoninfo_this.strength + stat.cnt;
			elseif(stat.gsid == -5) then
				dragoninfo_this.agility = dragoninfo_this.agility + stat.cnt;
			elseif(stat.gsid == -6) then
				dragoninfo_this.intelligence = dragoninfo_this.intelligence + stat.cnt;
			elseif(stat.gsid == -7) then
				dragoninfo_this.archskillpts = dragoninfo_this.archskillpts + stat.cnt;
			elseif(stat.gsid == -13) then
				dragoninfo_this.combatexp = dragoninfo_this.combatexp + stat.cnt;
			elseif(stat.gsid == -14) then
				dragoninfo_this.combatlel = stat.cnt;
			elseif(stat.gsid == -19) then
				dragoninfo_this.stamina = dragoninfo_this.stamina + stat.cnt;
			elseif(stat.gsid == -20) then
				dragoninfo_this.stamina2 = dragoninfo_this.stamina2 + stat.cnt;
			elseif(stat.gsid == -1001) then
				dragoninfo_this.nextlevelexp = stat.cnt;
			else
				-- NOTE 2010/8/30: friendliness, strong, cleanness, mood, health are all depracated
				LOG.std(nil, "warning", "PowerItemManager", "PowerItemManager.UpdateItemsWithAddsUpdatesStats got a unknown stat update: "..
					commonlib.serialize_compact({stat}));
			end
			if(not ignore_client_update) then
				-- inform the client to update the bag
				inform_update_bags[nid] = inform_update_bags[nid] or {};
				inform_update_bags[nid][-1] = true; -- bag -1 stands for user and dragon info update
				bNeedUpdateInformBags = true;
				LOG.std(nil, "info", "PowerItemManager", "PowerItemManager.UpdateItemsWithAddsUpdatesStats pending client update user and dragon info for nid: %d", nid);
			end
		end
	end

	-- force update inform bags
	if(bNeedUpdateInformBags) then
		Map3DSystem.GSL.PowerAPI_server.CheckInformBags();
	end
end

-- extended cost
-- @param exid: extended cost id
-- @param times: executed times
-- @param (optional)froms: if nil, it will be achieved from the items in memory
-- @param (optional)bags: if nil, it will be achieved from the items in memory
function PowerItemManager.ExtendedCost(nid, exid, times, froms, bags, callbackFunc, isgreedy, logevent)
	if(not exid) then
		return
	end

	if(froms == nil and bags == nil) then
	end

	local input_msg = {
		exid = exid,
		froms = froms,
		frombags = bags, -- for local server optimization
	};
	if(isgreedy) then
		input_msg.isgreedy = 1;
	end
	local extendedcost_api = paraworld.PowerAPI.inventory.ExtendedCost;
	if(times) then
		input_msg.times = times;
		extendedcost_api = paraworld.PowerAPI.inventory.ExtendedCost2;
	end
	CallPowerWebAPI(nid, extendedcost_api, input_msg, "PowerItemManager_ExtendedCost_for_"..nid, function(msg) 
		if(not msg or msg.errorcode) then
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.ExtendedCost callback function got error msg: "..commonlib.serialize_compact(msg));
			if(callbackFunc) then
				callbackFunc(msg);
			end
			return;
		end

		if(msg.issuccess) then
			
			-- update data in memory
			PowerItemManager.UpdateItemsWithAddsUpdatesStats(nid, msg.adds, msg.updates, msg.stats)
			if(callbackFunc) then
				callbackFunc(msg);
			end
			
		else
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.ChangeItem callback function got error msg: "..commonlib.serialize_compact(msg));
		end
	end, nil, function()
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.ChangeItem timeout: "..commonlib.serialize_compact({nid, adds, updates}));
	end);
end

-- change item for user
-- @param nid: user nid
-- @param adds: ChangeItem API required param
-- @param updates: ChangeItem API required param
-- @param callbackFunc: callback function
-- @param isgreedy: if greedy we don't rollback if any item change attempt fails
-- @param pres: ChangeItem API required param
-- @param sets: ChangeItem API required param
-- @param logevent：bool whether to write server user event 
function PowerItemManager.ChangeItem(nid_, adds, updates, callbackFunc, isgreedy, pres, logevent, sets)
	local nid = tonumber(nid_);
	
	if(not nid or not (adds or updates or sets)) then
		if(nid_ == "localuser") then
			return
		else
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.ChangeItem got invalid input: "..
				commonlib.serialize_compact({nid, adds, updates, sets}));
			return;
		end
	end
	local _logevent = nil;
	local _log2db = nil;
	if(logevent == true) then
		_logevent = 1;
		_log2db = 1;
	end
	-- change user items
	local input_msg = {
		nid = nid,
		pres = pres,
		sets = sets,
		adds = adds,
		updates = updates,
		logevent = _logevent, 
		log2db = _log2db,
	};
	if(isgreedy) then
		input_msg.isgreedy = 1;
	end
	CallPowerWebAPI(nid, paraworld.PowerAPI.inventory.ChangeItem, input_msg, "PowerItemManager_ChangeItem_for_"..nid, function(msg) 
		if(not msg or msg.errorcode) then
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.ChangeItem callback function got msg%s from input %s ", commonlib.serialize_compact(msg), commonlib.serialize_compact(input_msg));
			if(callbackFunc) then
				callbackFunc(msg);
			end
			return;
		end

		if(msg.issuccess) then
			
			-- update data in memory
			PowerItemManager.UpdateItemsWithAddsUpdatesStats(nid, msg.adds, msg.updates, msg.stats)
			if(callbackFunc) then
				callbackFunc(msg);
			end
			
		else
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.ChangeItem callback function got error msg: "..commonlib.serialize_compact(msg));
		end
	end, nil, function()
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.ChangeItem timeout: "..commonlib.serialize_compact({nid, adds, updates}));
	end);
end

-- mount gem into item socket
function PowerItemManager.MountGemInSocket(nid, client_msg)
	nid = tonumber(nid);
	-- make the rune guid string
	local rune_guids_str = "";
	local rune_guid, rune_cnt;
	for rune_guid, rune_cnt in pairs(client_msg.rune_guids) do
		rune_guids_str = rune_guids_str..rune_guid..","..rune_cnt.."|";
	end

	-- mount socket gem input message
	local input_msg = {
		nid = nid,
		containerguid = client_msg.item_guid,
		gemguid = client_msg.gem_guid,
		cards = rune_guids_str,
	};
	local seq = client_msg.seq;

	CallPowerWebAPI(nid, paraworld.PowerAPI.inventory.EquipGem, input_msg, "PowerItemManager_MountGemInSocket_for_"..nid, function(msg) 

		if(msg.issuccess) then
			---- TODO: update the gear with new serverdata
		else
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.MountGemInSocket callback function got error msg: "..commonlib.serialize_compact(msg));
		end
		---- tell the client of the mount gem process
		local gridnode = gateway:GetPrimGridNode(tostring(nid));
		if(gridnode) then
			local server_object = gridnode:GetServerObject("sPowerAPI");
			if(server_object) then
				-- tell the user of the mount gem return message
				msg.seq = seq;
				server_object:SendRealtimeMessage(tostring(nid), "[Aries][PowerAPI]MountGemReply:"..commonlib.serialize_compact(msg));
			end
		end

	end, nil, function()
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.MountGemInSocket timeout: "..commonlib.serialize_compact({msg}));
	end);
end

-- unequip gem from item socket
function PowerItemManager.UnEquipGemFromSocket(nid, client_msg)
	nid = tonumber(nid);
	-- make the rune guid string
	local gem_gsids_str = "";
	local _, gem_gsid;
	for _, gem_gsid in pairs(client_msg.gem_gsids) do
		gem_gsids_str = gem_gsids_str..gem_gsid..",";
	end

	-- mount socket gem input message
	local input_msg = {
		nid = nid,
		containerguid = client_msg.item_guid,
		gemgsids = gem_gsids_str,
	};
	local seq = client_msg.seq;

	CallPowerWebAPI(nid, paraworld.PowerAPI.inventory.UnEquipGem, input_msg, "PowerItemManager_UnEquipGemFromSocket_for_"..nid, function(msg) 

		if(msg.issuccess) then
			---- TODO: update the gear with new serverdata
		else
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.UnEquipGemFromSocket callback function got error msg: "..commonlib.serialize_compact(msg));
		end
		---- tell the client of the mount gem process
		local gridnode = gateway:GetPrimGridNode(tostring(nid));
		if(gridnode) then
			local server_object = gridnode:GetServerObject("sPowerAPI");
			if(server_object) then
				-- tell the user of the mount gem return message
				msg.seq = seq;
				server_object:SendRealtimeMessage(tostring(nid), "[Aries][PowerAPI]UnEquipGemReply:"..commonlib.serialize_compact(msg));
			end
		end

	end, nil, function()
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.UnEquipGemFromSocket timeout: "..commonlib.serialize_compact({msg}));
	end);
end

-- mount gem into item socket for teen version
function PowerItemManager.MountGemInSocket2(nid, client_msg)
	nid = tonumber(nid);
	-- make the rune guid string
	local rune_guids_str = "";
	local rune_guid, rune_cnt;
	for rune_guid, rune_cnt in pairs(client_msg.rune_guids) do
		rune_guids_str = rune_guids_str..rune_guid..","..rune_cnt.."|";
	end

	-- mount socket gem input message
	local input_msg = {
		nid = nid,
		containerguid = client_msg.item_guid,
		gemguid = client_msg.gem_guid,
		cards = rune_guids_str,
	};
	local seq = client_msg.seq;

	CallPowerWebAPI(nid, paraworld.PowerAPI.inventory.EquipGem2, input_msg, "PowerItemManager_MountGemInSocket2_for_"..nid, function(msg) 

		if(msg.issuccess) then
			---- TODO: update the gear with new serverdata
		else
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.MountGemInSocket2 callback function got error msg: "..commonlib.serialize_compact(msg));
		end
		---- tell the client of the mount gem process
		local gridnode = gateway:GetPrimGridNode(tostring(nid));
		if(gridnode) then
			local server_object = gridnode:GetServerObject("sPowerAPI");
			if(server_object) then
				-- tell the user of the mount gem return message
				msg.seq = seq;
				server_object:SendRealtimeMessage(tostring(nid), "[Aries][PowerAPI]MountGemReply2:"..commonlib.serialize_compact(msg));
			end
		end

	end, nil, function()
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.MountGemInSocket2 timeout: "..commonlib.serialize_compact({msg}));
	end);
end

-- unequip gem from item socket
function PowerItemManager.UnEquipGemFromSocket2(nid, client_msg)
	nid = tonumber(nid);
	-- make the rune guid string
	local gem_gsids_str = "";
	local _, gem_gsid;
	for _, gem_gsid in pairs(client_msg.gem_gsids) do
		gem_gsids_str = gem_gsids_str..gem_gsid..",";
	end

	-- mount socket gem input message
	local input_msg = {
		nid = nid,
		containerguid = client_msg.item_guid,
		gemgsids = gem_gsids_str,
	};
	local seq = client_msg.seq;

	CallPowerWebAPI(nid, paraworld.PowerAPI.inventory.UnEquipGem2, input_msg, "PowerItemManager_UnEquipGemFromSocket2_for_"..nid, function(msg) 

		if(msg.issuccess) then
			---- TODO: update the gear with new serverdata
		else
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.UnEquipGemFromSocket callback function got error msg: "..commonlib.serialize_compact(msg));
		end
		---- tell the client of the mount gem process
		local gridnode = gateway:GetPrimGridNode(tostring(nid));
		if(gridnode) then
			local server_object = gridnode:GetServerObject("sPowerAPI");
			if(server_object) then
				-- tell the user of the mount gem return message
				msg.seq = seq;
				server_object:SendRealtimeMessage(tostring(nid), "[Aries][PowerAPI]UnEquipGemReply2:"..commonlib.serialize_compact(msg));
			end
		end

	end, nil, function()
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.UnEquipGemFromSocket2 timeout: "..commonlib.serialize_compact({msg}));
	end);
end

-- 李宇(Liyu) 16:52:06
--		1魔尘	2魔尘	3魔尘	1魔晶
-- 绿卡	40	15	5	40
-- 兰卡	50	20	10	20
-- 紫卡	50	20	10	20


-- kids:
-- 17702 次级魔尘 
-- 17704 魔尘 
-- 17705 强效魔尘 

-- 17700 次级魔晶 
-- 17701 魔晶 
-- 17703 强效魔晶 
local function GetDestroySingleGreenCardMagicDirtKids()
	local r = math.random(0, 1000);
	if(r <= 400) then
		return 17702, 1;
	elseif(r <= (400 + 150)) then
		return 17702, 2;
	elseif(r <= (400 + 150 + 50)) then
		return 17702, 3;
	else
		return 17700, 1;
	end
end
local function GetDestroySingleBlueCardMagicDirtKids()
	local r = math.random(0, 1000);
	if(r <= 500) then
		return 17704, 1;
	elseif(r <= (500 + 200)) then
		return 17704, 2;
	elseif(r <= (500 + 200 + 100)) then
		return 17704, 3;
	else
		return 17701, 1;
	end
end
local function GetDestroySinglePurpleCardMagicDirtKids()
	local r = math.random(0, 1000);
	if(r <= 500) then
		return 17705, 1;
	elseif(r <= (500 + 200)) then
		return 17705, 2;
	elseif(r <= (500 + 200 + 100)) then
		return 17705, 3;
	else
		return 17703, 1;
	end
end

-- teen:
-- 17264 次级魔尘 
-- 17290 魔尘 
-- 17291 强效魔尘 

-- 17292 次级魔晶 
-- 17293 魔晶 
-- 17294 强效魔晶 
local function GetDestroySingleGreenCardMagicDirt()
	if(System.options.version == "kids") then
		local gsid,num = GetDestroySingleGreenCardMagicDirtKids();
		return gsid,num;
	end
	local r = math.random(0, 1000);
	if(r <= 400) then
		return 17264, 1;
	elseif(r <= (400 + 150)) then
		return 17264, 2;
	elseif(r <= (400 + 150 + 50)) then
		return 17264, 3;
	else
		return 17292, 1;
	end
end
local function GetDestroySingleBlueCardMagicDirt()
	if(System.options.version == "kids") then
		local gsid,num = GetDestroySingleBlueCardMagicDirtKids();
		return gsid,num;
	end
	local r = math.random(0, 1000);
	if(r <= 500) then
		return 17290, 1;
	elseif(r <= (500 + 200)) then
		return 17290, 2;
	elseif(r <= (500 + 200 + 100)) then
		return 17290, 3;
	else
		return 17293, 1;
	end
end
local function GetDestroySinglePurpleCardMagicDirt()
	if(System.options.version == "kids") then
		local gsid,num = GetDestroySinglePurpleCardMagicDirtKids();
		return gsid,num;
	end
	local r = math.random(0, 1000);
	if(r <= 500) then
		return 17291, 1;
	elseif(r <= (500 + 200)) then
		return 17291, 2;
	elseif(r <= (500 + 200 + 100)) then
		return 17291, 3;
	else
		return 17294, 1;
	end
end

-- destroy rune to MagicDirt
-- 17264_MagicDirt
function PowerItemManager.DestroyCardToMagicDirt(nid, client_msg)
	if(not Cards_Canot_Be_Destroyed_to_MagicDirt) then
		if(System.options.version == "kids") then
			Cards_Canot_Be_Destroyed_to_MagicDirt = {};
		elseif(System.options.version == "teen") then
			Cards_Canot_Be_Destroyed_to_MagicDirt = {
				[41418] = true,
				[42418] = true,
				[43418] = true,
				[44418] = true,
			};
		end
	end
	nid = tonumber(nid);
	if(type(client_msg) ~= "table") then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.DestroyCardToMagicDirt got invalid input: "..
			commonlib.serialize_compact({nid, client_msg}));
		return;
	end
	local card_gsid = client_msg.card_gsid;
	local card_guid = client_msg.card_guid;
	local card_count = client_msg.card_count;
	local item_gsid;
	local seq = client_msg.seq;
	if(type(card_guid) ~= "number" or type(card_gsid) ~= "number" or type(card_count) ~= "number") then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.DestroyCardToMagicDirt got invalid card input: "..
			commonlib.serialize_compact({card_guid, card_gsid, card_count}));
		return;
	end
	if(Cards_Canot_Be_Destroyed_to_MagicDirt[card_gsid]) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.DestroyCardToMagicDirt got Cards_Canot_Be_Destroyed_to_MagicDirt gsid : "..
			commonlib.serialize_compact({card_guid, card_gsid, card_count}));
		return;
	end
	local item = PowerItemManager.GetItemByGUID(nid, card_guid);
	if(item) then
		item_gsid = item.gsid;
		if(item_gsid ~= card_gsid) then
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.DestroyCardToMagicDirt got invalid gsid: "..
				commonlib.serialize_compact({card_gsid, card_guid})..", real gsid is: "..tostring(item.gsid));
			return;
		end
	end
	if(card_gsid < 41000 or card_gsid > 44999) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.DestroyCardToMagicDirt got invalid gsid guid: "..
			commonlib.serialize_compact({card_gsid, card_guid}));
		return;
	end
	if(item_gsid and (item_gsid < 41000 or item_gsid > 44999)) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.DestroyCardToMagicDirt got malicious gsid guid: "..
			item_gsid.."(real gsid) "..commonlib.serialize_compact({card_gsid, card_guid}));
		return;
	end

	-- 17264_MagicDirt
	local AllMagicdirts = {};
	local gsItem = PowerItemManager.GetGlobalStoreItemInMemory(card_gsid);
	if(gsItem) then
		local quality = gsItem.template.stats[221];
		local i;
		for i = 1, card_count do
			local gsid, count;
			if(quality == 1) then
				gsid, count = GetDestroySingleGreenCardMagicDirt();
			elseif(quality == 2) then
				gsid, count = GetDestroySingleBlueCardMagicDirt();
			elseif(quality == 3) then
				gsid, count = GetDestroySinglePurpleCardMagicDirt();
			end
			if(gsid and count) then
				if(AllMagicdirts[gsid]) then
					AllMagicdirts[gsid] = AllMagicdirts[gsid] + count;
				else
					AllMagicdirts[gsid] = count;
				end
			end
		end
	end
	
	local adds_str = "";
	local dirt_gsid, dirt_count;
	for dirt_gsid, dirt_count in pairs(AllMagicdirts) do
		adds_str = adds_str..string.format("%d~%d~%s~%s|", dirt_gsid, dirt_count, "NULL", "NULL");
	end
	local updates_str = string.format("%d~-%d~%s~%s|", card_guid, card_count, "NULL", "NULL");
	local pres_str = string.format("%d~%d|", card_gsid, card_count);

	if(adds_str and updates_str and pres_str and adds_str ~= "") then
		PowerItemManager.ChangeItem(nid, adds_str, updates_str, function(msg)
			if(msg.issuccess) then
				---- TODO: update the gear with new serverdata
			else
				LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.DestroyCardToMagicDirt callback function got error msg: "..commonlib.serialize_compact(msg));
			end
			---- tell the client of the mount gem process
			local gridnode = gateway:GetPrimGridNode(tostring(nid));
			if(gridnode) then
				local server_object = gridnode:GetServerObject("sPowerAPI");
				if(server_object) then
					-- tell the user of the mount gem return message
					msg.seq = seq;
					server_object:SendRealtimeMessage(tostring(nid), "[Aries][PowerAPI]DestroyCardToMagicDirtReply:"..commonlib.serialize_compact(msg));
				end
			end
		end, false, pres_str); -- false for non-greedy
	end
end

local CardPack_cardsets = {};
local CardPack_eachpack = {};
function PowerItemManager.InitCardPack()
	if(next(CardPack_cardsets) == nil) then
		-- CardPack_cardsets is empty
		local filename = "config/Aries/CardPack.teen.xml";
		if(System.options.version == "kids") then
			filename = "config/Aries/CardPack.xml";
		end
		local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
		if(xmlRoot) then
			local cardset_node;
			for cardset_node in commonlib.XPath.eachNode(xmlRoot, "/cardpacks/cardsets/set") do
				if(cardset_node.attr and cardset_node.attr.name and cardset_node.attr.gsids) then
					local name = cardset_node.attr.name;
					local gsids = cardset_node.attr.gsids;
					local card_series = {count = 0};
					-- parse card gsid and weight
					local card_gsid_weight_pair;
					for card_gsid_weight_pair in string.gmatch(gsids, "([^%(^%)]+)") do
						local card_gsid, weight = string.match(card_gsid_weight_pair, "^(%d-),(%d-)$");
						if(card_gsid and weight) then
							card_gsid = tonumber(card_gsid);
							weight = tonumber(weight);
							-- append to card series and inc card count
							card_series.count = card_series.count + weight * 10;
							table.insert(card_series, {card_gsid, weight * 10});
						end
					end
					CardPack_cardsets[name] = card_series;
				end
			end
			local pack_node;
			for pack_node in commonlib.XPath.eachNode(xmlRoot, "/cardpacks/pack") do
				if(pack_node.attr and pack_node.attr.gsid and pack_node.attr.magicdirt_count) then
					local gsid = pack_node.attr.gsid;
					local magicdirt_count = pack_node.attr.magicdirt_count;
					gsid = tonumber(gsid);
					magicdirt_count = tonumber(magicdirt_count);
					local rules = {magicdirt_count = magicdirt_count};
					local rule_node;
					for rule_node in commonlib.XPath.eachNode(pack_node, "/rule") do
						if(rule_node.attr and rule_node.attr.fromset and rule_node.attr.multiplier) then
							local fromset = rule_node.attr.fromset;
							local multiplier = tonumber(rule_node.attr.multiplier);
							table.insert(rules, {
								fromset = fromset,
								multiplier = multiplier,
							});
						end
					end
					CardPack_eachpack[gsid] = rules;
				end
			end
		end
	end
end

-- get cards from card pack
-- @param gsid: card pack gsid
-- @return: {[42101]=3,[41101]=10,}
function PowerItemManager.GetCardsFromCardPack(gsid)
	local gsid_list = {};
	local nMagicdirt = nil;
	local rules = CardPack_eachpack[gsid];
	if(rules) then
		nMagicdirt = rules.magicdirt_count;
		local _, each_rule;
		for _, each_rule in ipairs(rules) do
			local fromset = each_rule.fromset;
			local multiplier = each_rule.multiplier;
			if(fromset and multiplier) then
				local card_series = CardPack_cardsets[fromset];
				local r = math.random(0, card_series.count);
				local _, each_pair;
				for _, each_pair in ipairs(card_series) do
					r = r - each_pair[2];
					if(r <= 0) then
						local gsid = each_pair[1];
						if(gsid ~= 0) then
							gsid_list[gsid] = (gsid_list[gsid] or 0) + multiplier;
						end
						break;
					end
				end
			end
		end
	end
	return gsid_list, nMagicdirt;
end

-- exchange and open card pack
-- 17264_MagicDirt
-- 17265_MagicBag
-- @param nid: user nid
-- @param gsid: card pack gsid
function PowerItemManager.ExchangeAndOpenCardPack(nid, gsid)
	nid = tonumber(nid);
	if(not nid or not gsid) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.ExchangeAndOpenCardPack got invalid input: "..
			commonlib.serialize_compact({nid, gsid}));
		return;
	end
	local cards, nMagicdirt = PowerItemManager.GetCardsFromCardPack(gsid);
	if(nMagicdirt and nMagicdirt > 0 and next(cards) ~= nil and System.options.version == "teen") then
		local adds_str = string.format("%d~%s~%s~%s|", 17264, tostring(-nMagicdirt), "NULL", "NULL");
		local card_gsid, card_count;
		for card_gsid, card_count in pairs(cards) do
			adds_str = adds_str..string.format("%d~%s~%s~%s|", card_gsid, tostring(card_count), "NULL", "NULL");

		end
		local pres_str = string.format("%d~%d|", 17264, nMagicdirt);
		PowerItemManager.ChangeItem(nid, adds_str, updates_str, function(msg)
			if(msg.issuccess) then
				---- TODO: update the gear with new serverdata
				
			else
				LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.ExchangeAndOpenCardPack callback function got error msg: "..commonlib.serialize_compact(msg));
			end
			-- some handler
		end, false, pres_str); -- false for non-greedy
	end
end

-- directly open card pack
-- 17265_MagicBag
-- @param nid: user nid
-- @param gsid: card pack gsid
function PowerItemManager.DirectlyOpenCardPack(nid, params)
	nid = tonumber(nid);
	if(not nid or not params or not params.gsid) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.DirectlyOpenCardPack got invalid input: "..
			commonlib.serialize_compact({nid, params}));
		return;
	end
	local gsid = params.gsid;
	local cards, nMagicdirt = PowerItemManager.GetCardsFromCardPack(gsid);
	if(next(cards) ~= nil) then
		local adds_str = string.format("%d~%s~%s~%s|", gsid, tostring(-1), "NULL", "NULL");
		local card_gsid, card_count;
		for card_gsid, card_count in pairs(cards) do
			adds_str = adds_str..string.format("%d~%s~%s~%s|", card_gsid, tostring(card_count), "NULL", "NULL");
		end
		local pres_str = string.format("%d~%d|", gsid, 1);
		PowerItemManager.ChangeItem(nid, adds_str, updates_str, function(msg)
			if(msg.issuccess) then
				---- TODO: update the gear with new serverdata

				-- inform the all clients if there are precious cards 
				local cards_high = "";
				local cards_low = "";
				local card_gsid, card_count;
				for card_gsid, card_count in pairs(cards) do
					local gsItem = PowerItemManager.GetGlobalStoreItemInMemory(card_gsid);
					if(gsItem and gsItem.template.class == 18) then
						local quality = gsItem.template.stats[221];
						if(quality) then
							if(quality >= 3) then
								cards_high = cards_high..tostring(card_gsid)..",";
							elseif(quality >= 2) then
								cards_low = cards_low..tostring(card_gsid)..",";
							end
						end
					end
				end

				if(cards_high~="") then
					local user_info = PowerItemManager.GetUserAndDragonInfoInMemory(nid)
					local user_name;
					if(user_info and user_info.user) then
						user_name = user_info.user.nickname;
					end
					Map3DSystem.GSL.system:SendChat(nil, format("/opencards %s %s %d %s", tostring(nid), cards_high..cards_low, gsid, user_name or ""), true);
				elseif(cards_low~="") then
					local user_info = PowerItemManager.GetUserAndDragonInfoInMemory(nid)
					local user_name;
					if(user_info and user_info.user) then
						user_name = user_info.user.nickname;
					end
					Map3DSystem.GSL.system:SendChat(nil, format("/opencards %s %s %d %s", tostring(nid), cards_low, gsid, user_name or ""), false);
				end
			else
				LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.DirectlyOpenCardPack callback function got error msg: "..commonlib.serialize_compact(msg));
			end
			---- tell the client of the process
			local gridnode = gateway:GetPrimGridNode(tostring(nid));
			if(gridnode) then
				local server_object = gridnode:GetServerObject("sPowerAPI");
				if(server_object) then
					-- tell the user of the return message
					msg.seq = seq;
					msg.cards = cards;
					server_object:SendRealtimeMessage(tostring(nid), "[Aries][PowerAPI]DirectlyOpenCardPackReply:"..commonlib.serialize_compact(msg));
				end
			end
			-- some handler
		end, false, pres_str); -- false for non-greedy
	end
end

-- exchange the item set items
function PowerItemManager.ItemSetExtendedCost(nid, client_msg)
	---- make the rune guid string
	--local rune_guids_str = "";
	--local rune_guid, rune_cnt;
	--local isFirst = true;
	--for rune_guid, rune_cnt in pairs(client_msg.rune_guids) do
		--if(isFirst == true) then
			--rune_guids_str = rune_guid..","..rune_cnt;
		--else
			--rune_guids_str = rune_guids_str.."|"..rune_guid..","..rune_cnt;
		--end
		--isFirst = false;
	--end

	-- mount socket gem input message
	local input_msg = {
		nid = nid,
		gsid = client_msg.gsid,
	};
	local seq = client_msg.seq;

	CallPowerWebAPI(nid, paraworld.PowerAPI.inventory.ItemSetExtendedCost, input_msg, "PowerItemManager_ItemSetExtendedCost_for_"..nid, function(msg) 

		if(msg.issuccess) then
			---- update the gear with new serverdata
		else
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.ItemSetExtendedCost callback function got error msg: "..commonlib.serialize_compact(msg));
		end
		---- tell the client of the mount gem process
		local gridnode = gateway:GetPrimGridNode(tostring(nid));
		if(gridnode) then
			local server_object = gridnode:GetServerObject("sPowerAPI");
			if(server_object) then
				-- tell the user of the mount gem return message
				msg.seq = seq;
				server_object:SendRealtimeMessage(tostring(nid), "[Aries][PowerAPI]ItemSetExtendedCostReply:"..commonlib.serialize_compact(msg));
			end
		end

	end, nil, function()
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.ItemSetExtendedCost timeout: "..commonlib.serialize_compact({msg}));
	end);
end


--------------------------------------------------------------------------------------------------------
--------							Developer Accessable Functions								--------
--------------------------------------------------------------------------------------------------------

-- purchase item
-- @param nid: user nid
-- @param gsid: item gsid
-- @param count: purchase count
-- @param serverdata: server data string
-- @param clientdata: client data string
-- @param callbackFunc: callback function
function PowerItemManager.PurchaseItem(nid, gsid, count, serverdata, clientdata, callbackFunc)
	nid = tonumber(nid);
	if(not nid or not gsid or not count) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.PurchaseItem got invalid input: "..
			commonlib.serialize_compact({nid, gsid, count}));
		return;
	end
	local adds_str = string.format("%d~%d~%s~%s|", gsid, count, (serverdata or "NULL"), (clientdata or "NULL"));
	PowerItemManager.ChangeItem(nid, adds_str, nil, callbackFunc);
end

-- purchase item batch
-- @param nid: user nid
-- @param gsids: {[gsid] = cnt, [gsid] = cnt}
-- @param callbackFunc: callback function
function PowerItemManager.PurchaseItemBatch(nid, gsids, callbackFunc)
	nid = tonumber(nid);
	if(not nid or not gsids) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.PurchaseItemBatch got invalid input: "..
			commonlib.serialize_compact({nid, gsids}));
		return;
	end
	local adds_str = "";
	local gsid, count;
	for gsid, count in pairs(gsids) do
		adds_str = adds_str..string.format("%d~%d~%s~%s|", gsid, count, "NULL", "NULL");
	end
	
	-- append all gsids
	PowerItemManager.ChangeItem(nid, adds_str, nil, callbackFunc);
end

-- destroy item
-- @param nid: user nid
-- @param guid: item guid
-- @param count: purchase count
-- @param callbackFunc: callback function
function PowerItemManager.DestroyItem(nid, guid, count, callbackFunc)
	nid = tonumber(nid);
	if(not nid or not guid or not count) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.DestroyItem got invalid input: "..
			commonlib.serialize_compact({nid, guid, count}));
		return;
	end
	if( guid and guid>0) then
		local updates_str = string.format("%d~-%d~%s~%s|", guid, count, "NULL", "NULL");
		PowerItemManager.ChangeItem(nid, nil, updates_str, callbackFunc);
	elseif( guid and guid<0) then
		-- this is actually gsid. 
		local gsid = -guid;
		local adds_str = string.format("%d~%d~%s~%s|", gsid, -count, "NULL", "NULL");
		PowerItemManager.ChangeItem(nid, adds_str, nil, callbackFunc, true);
	end
end

-- destroy item batch
-- @param nid: user nid
-- @param guids: {[guid] = cnt, [guid] = cnt}
-- @param callbackFunc: callback function
function PowerItemManager.DestroyItemBatch(nid, guids, callbackFunc)
	nid = tonumber(nid);
	if(not nid or not guids) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.DestroyItemBatch got invalid input: "..
			commonlib.serialize_compact({nid, guids}));
		return;
	end
	local updates_str = "";
	local guid, count;
	for guid, count in pairs(guids) do
		updates_str = updates_str..string.format("%d~-%d~%s~%s|", guid, count, "NULL", "NULL");
	end
	PowerItemManager.ChangeItem(nid, nil, updates_str, callbackFunc);
end

-- set item count
-- @param nid: user nid
-- @param gsid: gsid
-- @param count: count
-- @param callbackFunc: callback function
function PowerItemManager.SetItemCount(nid, gsid, count, callbackFunc)
	nid = tonumber(nid);
	if(not nid or not gsid or not count or type(count) ~= "number" or count < 0) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SetItemCount got invalid input: "..
			commonlib.serialize_compact({nid, gsid, count}));
		return;
	end
	local sets_str = string.format("%d~%d|", gsid, count);
	PowerItemManager.ChangeItem(nid, nil, nil, function(msg)
		if(callbackFunc) then
			callbackFunc(msg);
		end
	end, nil, nil, nil, sets_str);
end

-- set item count if the item does not exist or have more copies
-- @param nid: user nid
-- @param gsid: gsid
-- @param count: count
-- @param callbackFunc: callback function
function PowerItemManager.SetItemCountIfEmptyOrMore(nid, gsid, count, callbackFunc)
	if(not nid or not gsid or not count or type(count) ~= "number" or count <= 0) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SetItemCountIfEmptyOrMore got invalid input: "..
			commonlib.serialize_compact({nid, gsid, count}));
		return;
	end
	local gsItem = PowerItemManager.GetGlobalStoreItemInMemory(gsid);
	if(gsItem) then
		local maxcount = gsItem.template.maxcount;
		local maxcopiesinstack = gsItem.template.maxcopiesinstack;
		if(not maxcount or maxcount ~= maxcopiesinstack) then
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SetItemCountIfEmptyOrMore got gsid with different maxcount and maxcopiesinstack: "..tostring(gsid));
			return;
		end
		if(maxcount and maxcount > 0 and maxcount < count) then
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SetItemCountIfEmptyOrMore got count: "..tostring(count).." exceeds maxcount with gsid: "..tostring(gsid));
			return;
		end
	else
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SetItemCountIfEmptyOrMore got invalid gsid: "..
			commonlib.serialize_compact({gsid}));
		return;
	end
	local pres_str;
	local sets_str;
	if(count == 1) then
		pres_str = string.format("%d~%d|", gsid, -1);
		sets_str = string.format("%d~%d|", gsid, 1);
		PowerItemManager.ChangeItem(nid, nil, nil, function(msg)
			if(callbackFunc) then
				callbackFunc(msg);
			end
		end, nil, pres_str, nil, sets_str);
	else
		-- count is at least 2
		pres_str = string.format("%d~%d|", gsid, -1);
		sets_str = string.format("%d~%d|", gsid, count);
		PowerItemManager.ChangeItem(nid, nil, nil, function(msg_first)
			if(msg_first and msg_first.issuccess == true) then
				-- empty item
				if(callbackFunc) then
					callbackFunc(msg_first);
				end
			elseif(msg_first and msg_first.errorcode == 427) then
				-- more than 1 copies
				-- 427 条件不符
				pres_str = string.format("%d~%d|", gsid, count);
				sets_str = string.format("%d~%d|", gsid, count);
				PowerItemManager.ChangeItem(nid, nil, nil, function(msg_second)
					if(callbackFunc) then
						callbackFunc(msg_second);
					end
				end, nil, pres_str, nil, sets_str);
			end
		end, nil, pres_str, nil, sets_str);
	end
end

-- set item count if the item does not exist or have less copies
-- @param nid: user nid
-- @param gsid: gsid
-- @param count: count
-- @param callbackFunc: callback function
function PowerItemManager.SetItemCountIfEmptyOrLess(nid, gsid, count, callbackFunc)
	if(not nid or not gsid or not count or type(count) ~= "number" or count <= 0) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SetItemCountIfEmptyOrLess got invalid input: "..
			commonlib.serialize_compact({nid, gsid, count}));
		return;
	end
	local gsItem = PowerItemManager.GetGlobalStoreItemInMemory(gsid);
	local bag;
	if(gsItem) then
		bag = gsItem.template.bagfamily;
		local maxcount = gsItem.template.maxcount;
		local maxcopiesinstack = gsItem.template.maxcopiesinstack;
		if(not maxcount or maxcount ~= maxcopiesinstack) then
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SetItemCountIfEmptyOrLess got gsid with different maxcount and maxcopiesinstack: "..tostring(gsid));
			return;
		end
		if(maxcount and maxcount > 0 and maxcount < count) then
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SetItemCountIfEmptyOrLess got count: "..tostring(count).." exceeds maxcount with gsid: "..tostring(gsid));
			return;
		end
	else
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SetItemCountIfEmptyOrLess got invalid gsid: "..
			commonlib.serialize_compact({gsid}));
		return;
	end
	local pres_str;
	local sets_str;
	pres_str = string.format("%d~%d|", gsid, -count);
	sets_str = string.format("%d~%d|", gsid, count);
	local beHas, _, _, copies = PowerItemManager.IfOwnGSItem(nid, gsid, bag);
	if(not copies) then
		copies = 0;
	end
	if((not count) or count <= copies) then
		return;
	end

	PowerItemManager.ChangeItem(nid, nil, nil, function(msg_first)
		if(msg_first and msg_first.issuccess == true) then
			-- empty item
			if(callbackFunc) then
				callbackFunc(msg_first);
			end
		end
	end, nil, pres_str, nil, sets_str);
end

-- set client data for item
-- @param nid: user nid
-- @param guid: item guid
-- @param clientdata: client data string, according to CYF requirement no "~" or "|" character is included in clientdata
--					  if included an error will be reported
-- @param callbackFunc: callback function
-- @param forceupdatebags: force update client bags e.x.{0,10010}
function PowerItemManager.SetClientdata(nid, guid, clientdata, callbackFunc, force_client_update_bags)
	nid = tonumber(nid);
	if(not nid or not guid or not clientdata) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SetClientdata got invalid input: "..
			commonlib.serialize_compact({nid, guid, clientdata}));
		return;
	end

	local items_user = items_all[nid];
	if(not items_user) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SetClientdata got unloggedin user : "..tostring(nid));
		return;
	end
	if(not items_user[guid]) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SetClientdata got invalid item for nid and guid: "..
			commonlib.serialize_compact({nid, guid, clientdata}));
		return;
	end
	if(string.find(clientdata, "~") or string.find(clientdata, "|")) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SetClientdata got client data including ~ or | character for input: "..
			commonlib.serialize_compact({nid, guid, clientdata}));
		return;
	end
	
	items_user[guid].clientdata = clientdata;

	PowerItemManager.ChangeItem(nid, nil, guid.."~0~NULL~"..clientdata.."|", function(msg)
		-- host callback 
		if(callbackFunc) then
			callbackFunc(msg);
		end
		-- force update client bags
		if(force_client_update_bags) then
			local _, bag;
			for _, bag in pairs(force_client_update_bags) do
				-- inform the client to force update the bag
				inform_update_bags[nid] = inform_update_bags[nid] or {};
				inform_update_bags[nid][bag] = true;
			end
		end
	end);
end

-- set server data for item
-- @param nid: user nid
-- @param guid: item guid
-- @param serverdata: server data string, according to CYF requirement no "," or "|" character is included in serverdata
--					  if included an error will be reported
-- @param callbackFunc: callback function
-- @param forceupdatebags: force update client bags e.x.{0,10010}
function PowerItemManager.SetServerData(nid, guid, serverdata, callbackFunc, force_client_update_bags)
	nid = tonumber(nid);
	if(not nid or not guid or not serverdata) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SetServerData got invalid input: "..
			commonlib.serialize_compact({nid, guid, serverdata}));
		return;
	end

	local items_user = items_all[nid];
	if(not items_user) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SetServerData got unloggedin user : "..tostring(nid));
		return;
	end
	if(not items_user[guid]) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SetServerData got invalid item for nid and guid: "..
			commonlib.serialize_compact({nid, guid, serverdata}));
		return;
	end
	if(string.find(serverdata, "~") or string.find(serverdata, "|")) then 
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SetServerData got server data including ~ or | character for input: "..
			commonlib.serialize_compact({nid, guid, serverdata}));
		return;
	end
	
	items_user[guid].serverdata = serverdata;

	PowerItemManager.ChangeItem(nid, nil, guid.."~0~"..serverdata.."~NULL|", function(msg)
		-- host callback 
		if(callbackFunc) then
			callbackFunc(msg);
		end
		-- force update client bags
		if(force_client_update_bags) then
			local _, bag;
			for _, bag in pairs(force_client_update_bags) do
				-- inform the client to force update the bag
				inform_update_bags[nid] = inform_update_bags[nid] or {};
				inform_update_bags[nid][bag] = true;
			end
		end
	end);
end

-- add experience for user
-- @param nid: user nid
-- @param exp_pts: experience point
-- @param callbackFunc: callback function
function PowerItemManager.AddExp(nid, exp_pts, callbackFunc)
	if(not nid or not exp_pts) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.AddExp got invalid input: "..
			commonlib.serialize_compact({nid, exp_pts}));
		return;
	end
	-- gsid -13: for experience
	local adds_str = string.format("%d~%d~%s~%s|", -13, exp_pts, "NULL", "NULL");
	PowerItemManager.ChangeItem(nid, adds_str, nil, callbackFunc);
end

-- add joybean for user
-- @param nid: user nid
-- @param joybean: joybean count
-- @param callbackFunc: callback function
function PowerItemManager.AddJoybean(nid, joybean, callbackFunc)
	if(not nid or not joybean) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.AddJoybean got invalid input: "..
			commonlib.serialize_compact({nid, joybean}));
		return;
	end
	-- gsid 0: for joybean
	local adds_str = string.format("%d~%d~%s~%s|", 0, joybean, "NULL", "NULL");
	PowerItemManager.ChangeItem(nid, adds_str, nil, callbackFunc);
	-- joybean post log
	combat_server.AppendPostLog( {
		action = "user_gain_joybean", 
		joybean = joybean,
		nid = nid,
		reason = "AddJoybean",
	});
end

-- add experiencem joybean and loots for user
-- @param nid: user nid
-- @param exp_pts: experience point
-- @param joybean: joybean count
-- @param loots: {[gsid] = cnt, [gsid] = cnt}, where cnt can be number or {count=number, serverdata="string", }
-- @param callbackFunc: callback function
-- @param pres: {[gsid] = cnt, [gsid] = cnt}
-- @param logevent: true for log event
function PowerItemManager.AddExpJoybeanLoots(nid, exp_pts, joybean, loots, callbackFunc, pres, reason_for_postlog, logevent)
	if(not nid or not (exp_pts or joybean or loots)) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.AddExpJoybeanLoots got invalid input: "..
			commonlib.serialize_compact({nid, exp_pts, joybean, loots}));
		return;
	end
	local adds_str = "";
	local pres_str = "";

	local is_with_984_update = false;
	
	if(exp_pts) then
		adds_str = adds_str..string.format("%d~%d~%s~%s|", -13, exp_pts, "NULL", "NULL");
	end
	if(joybean) then
		adds_str = adds_str..string.format("%d~%d~%s~%s|", 0, joybean, "NULL", "NULL");
	end
	if(loots) then
		local gsid, count;
		for gsid, count in pairs(loots) do
			if(gsid == 984) then
				is_with_984_update = true;
			end
			if(type(count) == "number") then
				adds_str = adds_str..string.format("%d~%d~%s~%s|", gsid, count, "NULL", "NULL");
			elseif(type(count) == "table") then
				local params = count;
				adds_str = adds_str..string.format("%d~%d~%s~%s|", gsid, params.count or 0, params.serverdata or "NULL", "NULL");
			end
		end
	end
	if(pres) then
		local gsid, count;
		for gsid, count in pairs(pres) do
			pres_str = pres_str..string.format("%d~%d|", gsid, count);
		end
	end

	if(logevent == nil and is_with_984_update == true) then
		logevent = true;
	end
	
	---- append all stats change and items
	--PowerItemManager.ChangeItem(nid, adds_str, nil, function(msg)
		---- NOTE: 2010/10/2: force update the user and dragon info to solve the client issue daily mob farming quest
		---- force update user and dragon info
		--PowerItemManager.GetUserAndDragonInfo(nid, function(msg) end, function() end);
		---- callback function
		--callbackFunc(msg);
	--end, true); -- true for isgreedy
	
	-- append all stats change and items
	PowerItemManager.ChangeItem(nid, adds_str, nil, callbackFunc, true, pres_str, logevent); -- true for isgreedy
	-- joybean post log
	if(joybean and joybean>0 or reason_for_postlog) then
		combat_server.AppendPostLog( {
			action = "user_gain_joybean", 
			joybean = joybean,
			nid = nid,
			reason = tostring(reason_for_postlog or "AddExpJoybeanLoots"),
		});
	end
end

-- add skill point for user
-- @param nid: user nid
-- @param skill_gsid: skill gsid, e.x. 21109
-- @param skill_pts: skill point
-- @param callbackFunc: callback function
function PowerItemManager.AddSkillPoint(nid, skill_gsid, skill_pts, callbackFunc)
	if(not nid or not skill_gsid or not skill_pts) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.AddSkillPoint got invalid input: "..
			commonlib.serialize_compact({nid, skill_gsid, skill_pts}));
		return;
	end
	-- check skill gsid validation
	if(PowerItemManager.IfOwnGSItem(nid, skill_gsid, 0)) then
		-- gsid: for skill point
		local adds_str = string.format("%d~%d~%s~%s|", skill_gsid, skill_pts, "NULL", "NULL");
		PowerItemManager.ChangeItem(nid, adds_str, nil, callbackFunc);
	else
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.AddSkillPoint, skill gsid not exist for input: "..
			commonlib.serialize_compact({nid, skill_gsid, skill_pts}));
		return;
	end
end

-- cost stamina points for user
-- @param nid: user nid
-- @param stamina_pts: stamina point
-- @param callbackFunc: callback function
function PowerItemManager.CostStamina(nid, stamina_pts, callbackFunc)
	if(not nid or not stamina_pts) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.CostStamina got invalid input: "..
			commonlib.serialize_compact({nid, stamina_pts}));
		return;
	end
	-- gsid -19: for stamina
	local adds_str = string.format("%d~%d~%s~%s|", -19, -stamina_pts, "NULL", "NULL");
	PowerItemManager.ChangeItem(nid, adds_str, nil, callbackFunc);
end

-- cost stamina2 points for user
-- @param nid: user nid
-- @param stamina2_pts: stamina2 point
-- @param callbackFunc: callback function
function PowerItemManager.CostStamina2(nid, stamina2_pts, callbackFunc)
	if(not nid or not stamina2_pts) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.CostStamina2 got invalid input: "..
			commonlib.serialize_compact({nid, stamina2_pts}));
		return;
	end
	-- gsid -20: for stamina2
	local adds_str = string.format("%d~%d~%s~%s|", -20, -stamina2_pts, "NULL", "NULL");
	PowerItemManager.ChangeItem(nid, adds_str, nil, callbackFunc);
end

-- get the item description in memory
-- @param nid: user nid
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
function PowerItemManager.GetItemByGUID(nid_, guid)
	local nid = tonumber(nid_);
	if(not nid or not guid) then
		if(nid_ == "localuser") then
			return nil;
		else
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.GetItemByNIDGUID got invalid input: "..
				commonlib.serialize_compact({nid, guid}));
			return;
		end
	end
	local items_user = items_all[nid];
	if(items_user) then
		return items_user[guid];
	end
end

-- get the item count in bag
-- @param nid: user nid
-- @param bag: bag id
-- @return: item count or nil for error
function PowerItemManager.GetItemCountInBag(nid_, bag)
	local nid = tonumber(nid_);
	if(not nid or not bag) then
		if(nid_ == "localuser") then
			return 0;
		else
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.GetItemCountInBag got invalid input: "..
				commonlib.serialize_compact({nid, bag}));
			return;
		end
	end
	local bags_user = bags_all[nid];
	if(bags_user) then
		if(bags_user[bag]) then
			return #(bags_user[bag]);
		end
	end
end

-- get the items in bag in memory
-- @param nid: user nid
-- @param bag: item bag in item_instance
-- @return: item guid list {guid, guid, guid, ...}, nil if not found
function PowerItemManager.GetItemsInBagInMemory(nid_, bag)
	local nid = tonumber(nid_);
	if(not nid or not bag) then
		if(nid_ == "localuser") then
			return nil;
		else
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.GetItemsInBagInMemory got invalid input: "..
				commonlib.serialize_compact({nid, bag}));
			return;
		end
	end
	local bags_user = bags_all[nid];
	if(bags_user) then
		if(bags_user[bag]) then
			return bags_user[bag];
		end
	end
end

-- get the item by bag and order
-- @param nid: user nid
-- @param bag: item bag in item_instance
-- @param order: the local order of the item in the same bag, starts from 1
-- @return: item data, nil if not found
function PowerItemManager.GetItemByBagAndOrder(nid, bag, order)
	nid = tonumber(nid);
	if(not nid or not bag or not order) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.GetItemByBagAndOrder got invalid input: "..
			commonlib.serialize_compact({nid, bag, order}));
		return;
	end
	local bags_user = bags_all[nid];
	if(bags_user) then
		if(bags_user[bag]) then
			local guid = bags_user[bag][order];
			if(guid) then
				return PowerItemManager.GetItemByGUID(nid, guid);
			end
		end
	end
end

-- get the item by bag and order
-- @param nid: user nid
-- @param bag: item bag in item_instance
-- @param position: item position in item_instance
-- @return: item data, nil if not found
function PowerItemManager.GetItemByBagAndPosition(nid, bag, position)
	nid = tonumber(nid);
	if(not nid or not bag or not position) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.GetItemByBagAndPosition got invalid input: "..
			commonlib.serialize_compact({nid, bag, position}));
		return;
	end
	local bags_user = bags_all[nid];
	if(bags_user) then
		if(bags_user[bag]) then
			local _, guid;
			for _, guid in ipairs(bags_user[bag]) do
				local item = PowerItemManager.GetItemByGUID(nid, guid);
				if(item and item.position == position) then
					return item;
				end
			end
		end
	end
end

-- check if the user has the global store item in inventory
-- @param nid: user nid
-- @param gsid: global store id
-- @param bag: only check the bag
-- @param excludebag: 
-- @return bOwn, guid, bag, copies: if own the gs item, and the guid, bag and copies of the item if own
-- NOTE: return false if nid and bag are all specified, the item is NOT exist in user nid's bag
function PowerItemManager.IfOwnGSItem(nid_, gsid, bag, excludebag)
	local nid = tonumber(nid_);
	if(not nid or not gsid) then
		if(nid_ == "localuser") then
			nid = "localuser";
			return true, 0, 0, 10;
		else
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.IfOwnGSItem got invalid input: "..
				commonlib.serialize_compact({nid, gsid}));
			return;
		end
	end

	if(gsid == 0) then
		local useranddragon = PowerItemManager.GetUserAndDragonInfoInMemory(nid);
		if(useranddragon and useranddragon.user) then
			return true, nil, nil, useranddragon.user.emoney;
		end
	elseif(gsid == -1) then
		local useranddragon = PowerItemManager.GetUserAndDragonInfoInMemory(nid);
		if(useranddragon and useranddragon.user) then
			return true, nil, nil, useranddragon.user.pmoney;
		end
	end

	local items_user = items_all[nid];
	if(items_user) then
		local guid, item;
		for guid, item in pairs(items_user) do
			if(item.gsid == gsid and (bag == nil or item.bag == bag) and (excludebag == nil or item.bag ~= excludebag) and item.bag ~= 20001) then
				return true, item.guid, item.bag, item.copies;
			end
		end
	end
	if(nid and bag) then
		if(bags_all[nid] and bags_all[nid][bag]) then
			return false;
		end
	end
	return nil;
end

---- check if the user equiped with the global store item on hand
---- @return bEquip, guid: if equip the gs item, and the guid of the item if equip
--function PowerItemManager.IfEquipGSItem(gsid)
	--local count = PowerItemManager.GetItemCountInBag(0);
	--local i;
	--for i = 1, count do
		--local item = PowerItemManager.GetItemByBagAndOrder(0, i);
		--if(item.gsid == gsid) then
			--return true, item.guid;
		--end
	--end
	--return false;
--end

-- return all item count copies sum in memory
-- @param nid: user nid
-- @param gsid: global store id
-- @return total copies
function PowerItemManager.GetGSItemTotalCopiesInMemory(nid, gsid)
	nid = tonumber(nid);
	if(not nid or not gsid) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.GetGSItemTotalCopiesInMemory got invalid input: "..
			commonlib.serialize_compact({nid, gsid}));
		return;
	end
	local copies = 0;
	local items_user = items_all[nid];
	if(items_user) then
		local guid, item;
		for guid, item in pairs(items_user) do
			if(item.gsid == gsid and item.bag ~= 20001) then
				copies = copies + item.copies;
			end
		end
	end
	return copies;
end

-- 986_CombatSchool_Fire
-- 987_CombatSchool_Ice
-- 988_CombatSchool_Storm
-- 989_CombatSchool_Myth
-- 990_CombatSchool_Life
-- 991_CombatSchool_Death
-- 992_CombatSchool_Balance
-- get user combat school
-- NOTE: if user haven't chosen the school or some error occur "storm" is returned
-- @return: lower case school name: fire, ice, storm, ...
function PowerItemManager.GetUserSchool(nid)
	if(not nid) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.GetUserSchool got invalid input: "..tostring(nid));
		return;
	end
	local school = "storm";
	
	local useranddragon = PowerItemManager.GetUserAndDragonInfoInMemory(nid);
	if(useranddragon and useranddragon.dragon) then
		local dragoninfo = useranddragon.dragon;
		if(dragoninfo.combatschool == 986) then
			school = "fire";
		elseif(dragoninfo.combatschool == 987) then
			school = "ice";
		elseif(dragoninfo.combatschool == 988) then
			school = "storm";
		elseif(dragoninfo.combatschool == 989) then
			school = "myth";
		elseif(dragoninfo.combatschool == 990) then
			school = "life";
		elseif(dragoninfo.combatschool == 991) then
			school = "death";
		--elseif(dragoninfo.combatschool == 992) then
			--school = "balance";
		end
	end
	return school;
end

--	969_CombatSecondarySchool_Fire
--	970_CombatSecondarySchool_Ice
--	971_CombatSecondarySchool_Storm
--	972_CombatSecondarySchool_Myth
--	973_CombatSecondarySchool_Life
--	974_CombatSecondarySchool_Death
--	975_CombatSecondarySchool_Balance
-- get user secondary school
-- NOTE: if user haven't chosen the school or some error occur nil is returned
-- @return: lower case school name: fire, ice, storm, ...
function PowerItemManager.GetUserSecondarySchool(nid)
	if(not nid) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.GetUserSecondarySchool got invalid input: "..tostring(nid));
		return;
	end
	local school;
	-- -- 26 Combat SecondarySchool? 辅修职业 青年版 
	local item = PowerItemManager.GetItemByBagAndPosition(nid, 0, 26)
	if(item and item.guid > 0) then
		local gsid = item.gsid;
		if(gsid == 969) then
			school = "fire";
		elseif(gsid == 970) then
			school = "ice";
		elseif(gsid == 971) then
			school = "storm";
		elseif(gsid == 972) then
			school = "myth";
		elseif(gsid == 973) then
			school = "life";
		elseif(gsid == 974) then
			school = "death";
		--elseif(gsid == 975) then
			--school = "balance";
		end
	end
	return school;
end

-- get the combat level of a given nid. return nil if user not found. 
function PowerItemManager.GetUserCombatLevel(nid)
	local useranddragon = PowerItemManager.GetUserAndDragonInfoInMemory(nid);
	if(useranddragon and useranddragon.dragon) then
		return useranddragon.dragon.combatlel;
	end
end

-- private: make item string guid,count,gsid|guid,count,gsid|...
local function make_transaction_items_string(money, items)
	-- make item string
	local items_str = "";
	if(money and money~=0) then
		if(System.options.version == "teen") then
			-- -1 is P money, tradable money
			items_str = "-1,"..money..",-1|";
		else
			-- TODO: not supported yet, 984 is magic bean, this is tradable money in kids version. 
			--items_str = "-984,"..money..",984|";
		end
	end

	if(items) then
		local _,item;
		for  _,item in ipairs(items) do
			if(item[1]) then
				local itemstr = format("%s,%s,%s|", tostring(item[1]), tostring(item[2] or 1), tostring(item[3]));
				items_str = items_str..itemstr;
			end
		end
	end
	
	if(items_str == "") then
		return
	end
	return items_str;
end

-- delete a given user
function PowerItemManager.DeleteUser(nid)
	CallPowerWebAPI(nid, paraworld.PowerAPI.users.delete, {nid = nid});
end

-- Do transaction between two players. 
-- @param trans: a table instance of GSL.Trade.trade_transaction. It does not have to be object, but pure data is also valid input. 
-- @param callback_func: function(bSucceed) end, bSucceed is false if failed or timed out. 
function PowerItemManager.DoTransaction(trans, callback_func)
	local nid1, nid2, items1, items2;
	if(trans and trans.trad_cont1 and trans.trad_cont2) then
		
		nid1 = trans.trad_cont1.nid;
		nid2 = trans.trad_cont2.nid;
		items1 = make_transaction_items_string(trans.trad_cont1.money, trans.trad_cont1.items)
		items2 = make_transaction_items_string(trans.trad_cont2.money, trans.trad_cont2.items)

		if(not trans:verify_items()) then
			LOG.std(nil, "error", "PowerItemManager_verify_error", {nid1=nid1, nid2=nid2, items1=items1, items2=items2});
			if(callback_func) then
				callback_func({issuccess=false});
			end
			return;
		end
	else
		return;
	end
	
	if( nid1 and nid2 and (items1 or items2) ) then
		-- items manager
		local input_msg = {
			nid = nid1,
			nid0 = tonumber(nid1),
			nid1 = tonumber(nid2),
			items0 = items1 or "",
			items1 = items2 or "",
		};

		-- use nid0's db server
		CallPowerWebAPI(nid1, paraworld.PowerAPI.inventory.Transaction, input_msg, "PowerItemManager.Transaction", function(msg) 
			if(msg.issuccess) then
				msg.nid0 = nid1;
				msg.nid1 = nid2;
				-- the both users's server data. 
				PowerItemManager.UpdateItemsWithAddsUpdatesStats(tonumber(msg.nid0), msg.adds0, msg.ups0, nil, true);
				PowerItemManager.UpdateItemsWithAddsUpdatesStats(tonumber(msg.nid1), msg.adds1, msg.ups1, nil, true);
				LOG.std(nil, "info", "PowerItemManager", "PowerItemManager.Transaction succeed: %s", commonlib.serialize_compact(input_msg));
			else
				LOG.std(nil, "warn", "PowerItemManager", "PowerItemManager.Transaction failed with errorcode: %d; input msg: %s", msg.errorcode or 0, commonlib.serialize_compact(input_msg));
			end
			if(callback_func) then
				callback_func(msg);
			end
		end, nil, function()
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.Transaction timeout: "..commonlib.serialize_compact(input_msg));
			if(callback_func) then
				callback_func({issuccess=false});
			end
		end);
	else
		-- empty transaction.
		LOG.std(nil, "debug", "PowerItemManager", "PowerItemManager.Transaction empty transacion found");
		if(callback_func) then
			callback_func({issuccess=true});
		end
	end
end

--[[update item level by consuming specified concurrency.  e.g.
local _, guid = Map3DSystem.Item.ItemManager.IfOwnGSItem(1807);
if(guid) then
	System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="SetItemAddonLevel", params={guid=guid}});
end
]]
function PowerItemManager.SetItemAddonLevel(from_nid, params, callback_func)
	if(params.guid and from_nid) then
		local item = PowerItemManager.GetItemByGUID(from_nid, params.guid);
		if(not item) then
			PowerItemManager.SyncUserItems(tonumber(from_nid), {0,1,}, function(msg) 
				local item = PowerItemManager.GetItemByGUID(from_nid, params.guid);
				if(item) then
					PowerItemManager.SetItemAddonLevel(from_nid, params, callback_func)
				end
			end, function() end);
			return
		end

		if(item and item.GetAddonLevel) then
			local from_level = item:GetAddonLevel() or 0;
			local to_level = from_level+1;
			if(params.to_level and params.to_level<=to_level) then
				-- ignore it
				return
			end
			local require_gsid, require_count = addonlevel.get_levelup_req(item.gsid, from_level);
			if(require_gsid) then
				local input_msg = {
					nid = from_nid,
					guid = params.guid, 
					addlel = to_level,
					reqgsid = require_gsid,
					reqcnt = require_count,
					-- log for all addon with to_levell >2
					logevent = if_else(to_level and to_level>2, true, nil),
				};
				CallPowerWebAPI(from_nid, paraworld.PowerAPI.inventory.SetItemAddonLevel, input_msg, "PowerItemManager.SetItemAddonLevel", function(msg) 
					if(msg.issuccess) then
						-- the both users's server data. 
						PowerItemManager.UpdateItemsWithAddsUpdatesStats(tonumber(from_nid), nil, msg.ups, nil, true);
						-- item:UpdateAddonLevel(to_level);
						LOG.std(nil, "info", "PowerItemManager", "PowerItemManager.SetItemAddonLevel succeed: %s", commonlib.serialize_compact(input_msg));

						local user_info = PowerItemManager.GetUserAndDragonInfoInMemory(from_nid)
						local user_name;
						if(user_info and user_info.user) then
							user_name = user_info.user.nickname;
						end

						if(System.options.version == "teen") then
							if(to_level >= 5) then
								-- Map3DSystem.GSL.system:SendChat(nil, format("/addon %s %d %d %s", tostring(from_nid), item.gsid, to_level, user_name or ""), true);
							elseif(to_level >= 3) then
								
							end
						else
							if(to_level >= 12) then
								Map3DSystem.GSL.system:SendChat(nil, format("/addon %s %d %d %s", tostring(from_nid), item.gsid, to_level, user_name or ""), true);
							elseif(to_level >= 9) then
								Map3DSystem.GSL.system:SendChat(nil, format("/addon %s %d %d %s", tostring(from_nid), item.gsid, to_level, user_name or ""), false);
							end
						end
					else
						LOG.std(nil, "warn", "PowerItemManager", "PowerItemManager.SetItemAddonLevel failed with errorcode: %d; input msg: %s", msg.errorcode or 0, commonlib.serialize_compact(input_msg));
					end
					local gridnode = gateway:GetPrimGridNode(tostring(from_nid));
					if(gridnode) then
						local server_object = gridnode:GetServerObject("sPowerAPI");
						if(server_object) then
							server_object:SendRealtimeMessage(tostring(from_nid), {type="reply", name="SetItemAddonLevel", input_msg=input_msg, msg=msg});
						end
					end
					if(callback_func) then
						callback_func(msg);
					end
				end, nil, function()
					LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.SetItemAddonLevel timeout: "..commonlib.serialize_compact(input_msg));
					callback_func({issuccess=false});
				end);
			end
		end
	end
end

-- reset addon level to a given level
function PowerItemManager.ResetAddonLevel(from_nid, item_guid, to_level, callback_func)
	local item = PowerItemManager.GetItemByGUID(from_nid, item_guid);
	if(not item) then
		PowerItemManager.SyncUserItems(tonumber(from_nid), {0,1,}, function(msg) 
			local item = PowerItemManager.GetItemByGUID(from_nid, item_guid);
			if(item) then
				PowerItemManager.ResetAddonLevel(from_nid, item_guid, to_level, callback_func)
			end
		end, function() end);
		return
	end

	if(item and item.GetServerData and to_level) then
		local params = item:GetServerData();
		if(params and params.addlel and params.addlel > to_level) then
			local old_level = params.addlel;
			params.addlel = to_level;
			local serverdata = commonlib.Json.Encode(params);
			local updates = item.guid.."~0~"..serverdata.."~NULL|";
			
			--calculate total xiandou count
			local xiandou_count = 0;
			for level = to_level, old_level-1 do
				local require_gsid, require_count = addonlevel.get_levelup_req(item.gsid, level);
				if(require_gsid == 17213) then
					xiandou_count = xiandou_count + require_count;
				end
			end
			local adds;
			if(xiandou_count>0) then
				-- add a mark for xiandou
				adds = format("52201~%d~NULL~NULL|", xiandou_count);
			end

			PowerItemManager.ChangeItem(from_nid, adds, updates, function(msg)
				if(msg and msg.issuccess)then
					-- items_user[item.guid].serverdata = serverdata;
					LOG.std(nil, "info", "PowerItemManager", "PowerItemManager.ResetAddonLevel nid %s succeeded with %s", tostring(from_nid), commonlib.serialize_compact(params));
				end
				if(callback_func) then
					callback_func(msg);
				end
			end, nil, nil, 
				-- log user event
			true); 
		end
	end
end


--[[update item level by consuming specified concurrency.  e.g.
System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="SetItemAddonLevel", params={xiandou=100, password="paraengine"}});
]]
function PowerItemManager.AdvancedAddonLevel(from_nid, params, callback_func)
	if(from_nid and params and params.password=="paraengine") then
		PowerItemManager.SyncUserItems(tonumber(from_nid), {0,1,}, function(msg) 
			if(params.to_level and params.item_guid) then
				PowerItemManager.ResetAddonLevel(from_nid, params.item_guid, params.to_level, callback_func)
			elseif(params.xiandou) then
				PowerItemManager.RemoveXiandou(from_nid, params.xiandou, callback_func)
			end
		end, function() end);
	end
end

-- remove xiandou(17213), by first remove addonlevel
function PowerItemManager.RemoveXiandou(from_nid, xiandou, callback_func)
	PowerItemManager.SyncUserItems(tonumber(from_nid), {0,1,12,1003}, function(msg) 
		PowerItemManager.RemoveXiandou_(tonumber(from_nid), xiandou, callback_func);
	end, function() end);
end

function PowerItemManager.RemoveXiandou_(from_nid, count, callback_func)
	local items_user = items_all[from_nid];
	if(items_user and count and count > 0) then
		local removed_count = 0;
		
		local adds = "";
		local updates = "";
		local items = {};
		-- min addon level 
		local min_level = 8;
		if(count>0) then
			-- precheck: check 仙豆扣除
			for guid, item in pairs(items_user) do
				if(item.gsid == 52201) then
					-- gsid:52201 仙豆扣除_标记
					if(item.copies) then
						count = count - item.copies;
						echo({"RemoveXiandou 52201", item.copies, count})
					end
				elseif(item.GetServerData) then
					local params = item:GetServerData();
					if(params and params.addlel and params.addlel >= min_level) then
						items[#items+1] = item;
						echo({"RemoveXiandou", params.addlel})
					end
				end
			end
			table.sort(items, function(a,b)
				return a:GetServerData().addlel > b:GetServerData().addlel;
			end);
		end
		if(count>0) then
			-- pass one: remove 17213 directly
			for guid, item in pairs(items_user) do
				if(item.gsid == 17213) then
					if(item.copies < count) then
						--updates = updates..format("%d~-%d~NULL~NULL|", item.guid, item.copies-1);
						adds = adds..format("17213~-%d~NULL~NULL|", item.copies-1);
						count = count - item.copies;
						removed_count = removed_count + item.copies;
					else
						--updates = updates..format("%d~-%d~NULL~NULL|", item.guid, count);
						adds = adds..format("17213~-%d~NULL~NULL|", count);
						removed_count = removed_count + count;
						count = 0;
					end
				end
			end
			
		end
		
		if(count > 0) then
			-- pass two: remove from addon level.
			for i, item in ipairs(items) do
				local params = item:GetServerData();
				
				--calculate total xiandou count
				local new_level;
				for level = params.addlel-1, min_level, -1 do
					local require_gsid, require_count = addonlevel.get_levelup_req(item.gsid, level);
					if(require_gsid == 17213) then
						count = count - require_count;
						removed_count = removed_count + require_count;
						new_level = level;
						echo({"RemoveXiandou addonlevel", count, level, require_count})
						if(count < 0) then
							break;
						end
					end
				end
				if(new_level) then
					params.addlel = new_level;
					local serverdata = commonlib.Json.Encode(params);
					updates = updates..(item.guid.."~0~"..serverdata.."~NULL|");
				end
				if(count<0) then
					break;
				end
			end
		end

		if(removed_count>0) then
			-- add a mark for xiandou
			adds = adds..format("52201~%d~NULL~NULL|", removed_count);

			echo({"RemoveXiandou", adds, updates})
			PowerItemManager.ChangeItem(from_nid, adds, updates, function(msg)
				if(msg and msg.issuccess)then
					-- items_user[item.guid].serverdata = serverdata;
					LOG.std(nil, "info", "PowerItemManager", "PowerItemManager.RemoveXiandou nid %s succeeded with %d", tostring(from_nid), removed_count);
				end
				if(callback_func) then
					callback_func(msg);
				end
			end, nil, nil, 
				-- log user event
			true); 
		else
			LOG.std(nil, "info", "PowerItemManager", "PowerItemManager.RemoveXiandou nid %s nothing need to be removed", tostring(from_nid));
		end
	end	
end


--[[
@param params: {money=money to add 100 per gem, sign_text=new sign text}
]]
function PowerItemManager.SignItem(from_nid, params, callback_func)
	if(params.guid and from_nid) then
		local item = PowerItemManager.GetItemByGUID(from_nid, params.guid);
		if(not item) then
			PowerItemManager.SyncUserItems(tonumber(from_nid), {0,1,}, function(msg) 
				local item = PowerItemManager.GetItemByGUID(from_nid, params.guid);
				if(item) then
					PowerItemManager.SignItem(from_nid, params, callback_func)
				end
			end, function() end);
			return
		end

		if(item and item.gsid) then
			-- LOG.std(nil, "info", "PowerItemManager", "PowerItemManager.SignItem "..commonlib.serialize_compact(params));

			local gsItem = PowerItemManager.GetGlobalStoreItemInMemory(item.gsid);
			if(gsItem and gsItem.template.class == 1 and gsItem.template.stats[521] == 1) then
				local money = tonumber(params.money) or 0;
				if (money >= 100) then
					if(params.sign_text and #(params.sign_text) > 50) then
						params.sign_text = string.sub(params.sign_text, 1, 50);
					end

					local money_to_pay = money;
					if(item.GetServerData) then
						local old_params = item:GetServerData();
						if(old_params and old_params.money and old_params.money>0) then
							params.money = math.max(money, old_params.money+money);
						end
					end
					
					local serverdata = commonlib.Json.Encode({nid=from_nid,money=tonumber(params.money), sign_text=commonlib.Encoding.EncodeServerDataString(params.sign_text)}); -- commonlib.Encoding.EncodeServerData
					local updates = item.guid.."~0~"..serverdata.."~NULL|";
					local adds = format("984~-%d~NULL~NULL|", money_to_pay);

					PowerItemManager.ChangeItem(from_nid, adds, updates, function(msg)
						if(msg and msg.issuccess)then
							-- force sync server data 
							PowerItemManager.SyncUserItems(tonumber(from_nid), {0,1,}, function(msg) end, function() end);
							-- items_user[item.guid].serverdata = serverdata;
							LOG.std(nil, "info", "PowerItemManager", "PowerItemManager.SignItem nid %s succeeded with %s", tostring(from_nid), commonlib.serialize_compact(params));
						end
						local gridnode = gateway:GetPrimGridNode(tostring(from_nid));
						if(gridnode) then
							local server_object = gridnode:GetServerObject("sPowerAPI");
							if(server_object) then
								server_object:SendRealtimeMessage(tostring(from_nid), {type="reply", name="SignItem", input_msg=params, msg=msg});
							end
						end
						if(callback_func) then
							callback_func(msg);
						end
					end, nil, nil, 
					-- log user event
					true); 
				end
			else
				LOG.std(nil, "warn", "PowerItemManager", "PowerItemManager.SignItem wrong item type. stat[521] should be 1 and class should be 1");
			end
		end
	end
end

-- @param params: {rank_id, begin_date, gsid, guid, score, score_new, tag, m, energy, popularity, onlymax }
function PowerItemManager.AddUserRanking(from_nid, params, callback_func)
	-- get user and dragon ingo
	local input_msg = {
		nid = tonumber(from_nid), 
		rid = tonumber(params.rank_id),
		begindt = tonumber(params.begin_date),
		gsid = params.gsid,
		guid = params.guid, 
		score = params.score,
		score2 = params.score_new,
		onlymax = params.onlymax, -- TODO: for CYF not working
		tag = params.tag,
		m = params.m,
		energy = params.energy,
		popularity = params.popularity,
	};
	-- LOG.std(nil, "debug", "PowerItemManager.AddUserRanking", input_msg);
	CallPowerWebAPI(from_nid, paraworld.PowerAPI.users.AddRank, input_msg, "AddUserRanking", function(msg) 
		if(msg and msg.issuccess) then
			if(errorcode == 493) then
				local item = PowerItemManager.GetItemByGUID(from_nid, params.guid);
				if(item) then
					item.copies = 0;
				end
			end
		end
		if(callback_func) then
			callback_func(msg);
		end
	end, nil, function()
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.AddUserRanking timeout");
	end);
end

-- check user item expire
-- destroy the user items
function PowerItemManager.CheckExpire(nid, callback_func)
	if(not nid) then
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.CheckExpire got invalid nid");
		return;
	end
	local input_msg = {
		nid = nid,
	};
	CallPowerWebAPI(nid, paraworld.PowerAPI.inventory.CheckExpire, input_msg, "PowerItemManager.CheckExpire", function(msg) 
		if(callback_func) then
			callback_func(msg);
		end
		
		log("info: CheckExpire got returned msg:\n");
		commonlib.echo(nid);
		commonlib.echo(msg);

		-- NOTE: assume msg is list of guids
		local bags = {};
		local bInvolveBag0 = false;
		local _, gsid;
		for _, gsid in pairs(msg) do
			local gsItem = PowerItemManager.GetGlobalStoreItemInMemory(gsid);
			if(gsItem) then
				local bagfamily = gsItem.template.bagfamily;
				bags[bagfamily] = true;
				if(gsItem.template.inventorytype ~= 0) then
					bInvolveBag0 = true;
				end
			end
		end
		
		if(next(bags) ~= nil) then
			if(bInvolveBag0) then
				-- some item can be equiped on bag 0
				bags[0] = true;
			end
			local limited_bags = {};
			local bag, _;
			for bag, _ in pairs(bags) do
				table.insert(limited_bags, bag);
				-- inform the client to force sync involed bags
				inform_update_bags[nid] = inform_update_bags[nid] or {};
				inform_update_bags[nid][bag] = true;
			end
			log("info: CheckExpire sync user bag items:\n");
			commonlib.echo(nid);
			commonlib.echo(limited_bags);
			-- resync user bag items
			PowerItemManager.SyncUserItems(nid, limited_bags, function() end);
		end
		

		---- NOTE: assume msg is list of guids
		---- nid items
		--items_all[nid] = items_all[nid] or {};
		--local items_user = items_all[nid];
		--local _, guid;
		--for _, guid in pairs(msg) do
			--if(type(guid) == "number") then
				--local item = items_user[guid];
				--if(item) then
					---- clear item
					--items_user[guid] = nil;
					---- nid bag
					--local bag = item.bag;
					--if(bag) then
						--bags_all[nid] = bags_all[nid] or {};
						--local bags_user = bags_all[nid][bag];
						--local bags_user_temp = {};
						--if(bags_user) then
							--local _, guid_in_bag;
							--for _, guid_in_bag in ipairs(bags_user) do
								--if(guid_in_bag ~= guid) then
									--table.insert(bags_user_temp, guid_in_bag);
								--end
							--end
							--bags_all[nid][bag] = bags_user_temp;
							---- inform the client to force update the bag
							--inform_update_bags[nid] = inform_update_bags[nid] or {};
							--inform_update_bags[nid][bag] = true;
						--end
					--end
				--end
			--end
		--end
	end, nil, function()
		LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.CheckExpire timeout: "..commonlib.serialize_compact(input_msg));
		if(callback_func) then
			callback_func({issuccess=false});
		end
	end);
end
--------------------------------------------------------------------------------------------------------
--------									Some Testing										--------
--------------------------------------------------------------------------------------------------------


-- debug dump
function PowerItemManager.DebugDump()
	log("----------- PowerItemManager.DebugDump()\n");
	commonlib.echo(items_all);
	commonlib.echo(bags_all);
	commonlib.echo(userinfo_all);
end

function PowerItemManager.Test1()
	
	PowerItemManager.Proc_GameServerLogin(function()
			log("return value1\n")
			local gsItem = PowerItemManager.GetGlobalStoreItemInMemory(50064)
			commonlib.echo(gsItem);
			Map3DSystem.Item.PowerItemManager.DebugDump();
	end)
end

function PowerItemManager.Test2(nid)
	
	PowerItemManager.Proc_UserLogin(nid, function()
			log("return value2\n")
			local user = PowerItemManager.GetUserAndDragonInfoInMemory(nid)
			commonlib.echo(user);
			--PowerItemManager.AddExp(46650264, 10, function(msg)
				--log("return value22 ====================\n")
				--local user = PowerItemManager.GetUserAndDragonInfoInMemory(nid)
				--commonlib.echo(user);
				--commonlib.echo(msg);
				--Map3DSystem.Item.PowerItemManager.DebugDump();
			--end);
			PowerItemManager.AddJoybean(46650264, 10, function(msg)
				log("return value22 ====================\n")
				local user = PowerItemManager.GetUserAndDragonInfoInMemory(nid)
				commonlib.echo(user);
				commonlib.echo(msg);
				Map3DSystem.Item.PowerItemManager.DebugDump();
			end);
	end, function()
			log("PowerItemManager.Proc_UserLogin time out\n")
	end)

	--CallPowerWebAPI(46650264, paraworld.PowerAPI.inventory.GetItemsInBag, {
			--nid = "14861822",
			--bag = 91,
		--}, "test2", function(msg)
			--log("return value2\n")
			--commonlib.echo(msg);
			--Map3DSystem.Item.PowerItemManager.DebugDump();
		--end);
end

function PowerItemManager.Test3()
	
	PowerItemManager.SetServerData(46650264, 1, "1", function(msg)
		log("return value3 ====================\n")
		commonlib.echo(msg);
		commonlib.echo(PowerItemManager.GetItemByGUID(46650264, 1));
		Map3DSystem.Item.PowerItemManager.DebugDump();
	end);
	commonlib.echo(PowerItemManager.GetItemByGUID(46650264, 1));

	--PowerItemManager.SyncUserItems(46650264, function()
		--log("--------------------------- items after SyncUserItems\n")
		--Map3DSystem.Item.PowerItemManager.DebugDump();
		----PowerItemManager.ChangeItem(46650264, "17001,1,NULL,NULL", nil, function(msg)
			----log("return value3 ====================\n")
			----commonlib.echo(msg);
			----Map3DSystem.Item.PowerItemManager.DebugDump();
		----end);
		----PowerItemManager.SetServerData(46650264, 1, "123", function(msg)
			----log("return value3 ====================\n")
			----commonlib.echo(msg);
			----Map3DSystem.Item.PowerItemManager.DebugDump();
		----end);
	--end, function()
		--log("ddddddddddddd time out\n")
	--end)
end

function PowerItemManager.Test4(nid)
	log("PowerItemManager.Test4\n")
	local gsItem = PowerItemManager.GetGlobalStoreItemInMemory(50064)
	commonlib.echo(gsItem);
	local user = PowerItemManager.GetUserAndDragonInfoInMemory(nid)
	commonlib.echo(user);
	
	local nid = 46650264;
	local bag = 46;
	local guid = 1;
	local gsid = 30012;

	commonlib.echo(bags_all[nid]);

	log("00000000000001111111111\n");
	commonlib.echo({PowerItemManager.IfOwnGSItem(nid, 60001)});

	PowerItemManager.PurchaseItem(nid, 60001, 1, "me", nil, function()
		log("sasssssssssssssssssssssssssss\n");
	commonlib.echo(bags_all[nid]);
		commonlib.echo({PowerItemManager.IfOwnGSItem(nid, 60001)});
	end)
	
	
	--commonlib.echo(PowerItemManager.GetItemByGUID(nid, guid));
	--commonlib.echo(PowerItemManager.GetItemCountInBag(nid, bag));
	--commonlib.echo(PowerItemManager.GetItemByBagAndOrder(nid, bag, 2));
	--commonlib.echo(PowerItemManager.GetItemByBagAndPosition(nid, bag, 1));
	--commonlib.echo({PowerItemManager.IfOwnGSItem(nid, gsid, bag, excludebag)});
	--commonlib.echo(PowerItemManager.GetGSItemTotalCopiesInMemory(nid, gsid));
end

local GiftPack_giftsets = {};
local GiftPack_eachpack = {};
function PowerItemManager.InitGiftPack()
	if(next(GiftPack_giftsets) == nil) then
		-- CardPack_cardsets is empty
		local filename = "config/Aries/Case.teen.xml";
		local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
		if(xmlRoot) then
			local cardset_node;
			for cardset_node in commonlib.XPath.eachNode(xmlRoot, "/cardpacks/cardsets/set") do
				if(cardset_node.attr and cardset_node.attr.name and cardset_node.attr.gsids) then
					local name = cardset_node.attr.name;
					local gsids = cardset_node.attr.gsids;
					local card_series = {count = 0};
					-- parse card gsid and weight
					local card_gsid_weight_pair;
					for card_gsid_weight_pair in string.gmatch(gsids, "([^%(^%)]+)") do
						local card_gsid, weight = string.match(card_gsid_weight_pair, "^(%d-),(%d-)$");
						if(card_gsid and weight) then
							card_gsid = tonumber(card_gsid);
							weight = tonumber(weight);
							-- append to card series and inc card count
							card_series.count = card_series.count + weight * 10;
							table.insert(card_series, {card_gsid, weight * 10});
						end
					end
					GiftPack_giftsets[name] = card_series;
				end
			end
			local pack_node;
			for pack_node in commonlib.XPath.eachNode(xmlRoot, "/cardpacks/pack") do
				if(pack_node.attr and pack_node.attr.gsid and pack_node.attr.magicdirt_count) then
					local gsid = pack_node.attr.gsid;
					local magicdirt_count = pack_node.attr.magicdirt_count;
					gsid = tonumber(gsid);
					magicdirt_count = tonumber(magicdirt_count);
					local rules = {magicdirt_count = magicdirt_count};
					local rule_node;
					for rule_node in commonlib.XPath.eachNode(pack_node, "/rule") do
						if(rule_node.attr and rule_node.attr.fromset and rule_node.attr.multiplier) then
							local fromset = rule_node.attr.fromset;
							local multiplier = tonumber(rule_node.attr.multiplier);
							table.insert(rules, {
								fromset = fromset,
								multiplier = multiplier,
							});
						end
					end
					GiftPack_eachpack[gsid] = rules;
				end
			end
		end
	end
end

-- get gifts from gift pack
-- @param gsid: card pack gsid
-- @return: {[42101]=3,[41101]=10,}
function PowerItemManager.GetGiftsFromGiftPack(gsid)
	local gsid_list = {};
	local nMagicdirt = nil;
	local rules = GiftPack_eachpack[gsid];
	if(rules) then
		nMagicdirt = rules.magicdirt_count;
		local _, each_rule;
		for _, each_rule in ipairs(rules) do
			local fromset = each_rule.fromset;
			local multiplier = each_rule.multiplier;
			if(fromset and multiplier) then
				local card_series = GiftPack_giftsets[fromset];
				local r = math.random(0, card_series.count);
				local _, each_pair;
				for _, each_pair in ipairs(card_series) do
					r = r - each_pair[2];
					if(r <= 0) then
						local gsid = each_pair[1];
						if(gsid ~= 0) then
							gsid_list[gsid] = (gsid_list[gsid] or 0) + multiplier;
						end
						break;
					end
				end
			end
		end
	end
	return gsid_list, nMagicdirt;
end

-- directly open gift pack
-- 17351_GiftPack
-- @param nid: user nid
-- @param gsid: card pack gsid
function PowerItemManager.DirectlyOpenGiftPack(nid, params)
	nid = tonumber(nid);
	if(not nid or not params or not params.gsid) then
			LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.DirectlyOpenGiftPack got invalid input: "..
			commonlib.serialize_compact({nid, params}));
		return;
	end
	local gsid = params.gsid;
	local cards, nMagicdirt = PowerItemManager.GetGiftsFromGiftPack(gsid);
	if(next(cards) ~= nil and System.options.version == "teen") then
		local adds_str = string.format("%d~%s~%s~%s|", gsid, tostring(-1), "NULL", "NULL");
		local card_gsid, card_count;
		for card_gsid, card_count in pairs(cards) do
			adds_str = adds_str..string.format("%d~%s~%s~%s|", card_gsid, tostring(card_count), "NULL", "NULL");
		end
		local pres_str = string.format("%d~%d|", gsid, 1);
		PowerItemManager.ChangeItem(nid, adds_str, updates_str, function(msg)
			if(msg.issuccess) then
				---- TODO: update the gear with new serverdata

				-- inform the all clients if there are precious cards 
				local cards_high = "";
				local cards_low = "";
				local card_gsid, card_count;
				for card_gsid, card_count in pairs(cards) do
					local gsItem = PowerItemManager.GetGlobalStoreItemInMemory(card_gsid);
					if(gsItem and gsItem.template.class == 18) then
						local quality = gsItem.template.stats[221];
						if(quality) then
							if(quality >= 3) then
								cards_high = cards_high..tostring(card_gsid)..",";
							elseif(quality >= 2) then
								cards_low = cards_low..tostring(card_gsid)..",";
							end
						end
					end
				end

				if(cards_high~="") then
					local user_info = PowerItemManager.GetUserAndDragonInfoInMemory(nid)
					local user_name;
					if(user_info and user_info.user) then
						user_name = user_info.user.nickname;
					end
					Map3DSystem.GSL.system:SendChat(nil, format("/opengifts %s %s %d %s", tostring(nid), cards_high..cards_low, gsid, user_name or ""), true);
				elseif(cards_low~="") then
					local user_info = PowerItemManager.GetUserAndDragonInfoInMemory(nid)
					local user_name;
					if(user_info and user_info.user) then
						user_name = user_info.user.nickname;
					end
					Map3DSystem.GSL.system:SendChat(nil, format("/opengifts %s %s %d %s", tostring(nid), cards_low, gsid, user_name or ""), false);
				end
			else
				LOG.std(nil, "error", "PowerItemManager", "PowerItemManager.DirectlyOpenGiftPack callback function got error msg: "..commonlib.serialize_compact(msg));
			end
			---- tell the client of the process
			local gridnode = gateway:GetPrimGridNode(tostring(nid));
			if(gridnode) then
				local server_object = gridnode:GetServerObject("sPowerAPI");
				if(server_object) then
					-- tell the user of the return message
					msg.seq = seq;
					msg.cards = cards;
					server_object:SendRealtimeMessage(tostring(nid), "[Aries][PowerAPI]DirectlyOpenGiftPackReply:"..commonlib.serialize_compact(msg));
				end
			end
			-- some handler
		end, false, pres_str); -- false for non-greedy
	end
end