--[[
Title: petevolved info
Author(s): Leio
Date: 2009/4/24
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/homeland/paraworld.homeland.petevolved.lua");
-------------------------------------------------------
Pet.Update 更新指定的宠物的信息 
Pet.Get 取得指定的宠物的信息 
Pet.Caress 抚摸指定的宠物 
Pet.UseItem 将指定的物品应用到指定的宠物身上
]]

-- create class
commonlib.setfield("paraworld.homeland.petevolved", {});
----------------------------------------------------------------------------------------------
local LOG = LOG;
--[[
Get
	--------------------- old
    /// <summary>
    /// 取得指定的宠物的资料
    /// 接收参数：
    ///     id 指定的宠物的ID
    /// 返回值：
	["friendliness"]=0,	["strong"]=0,	["nextlevelfr"]=0,	["cleanness"]=0,	["petid"]=2,	["health"]=0,	["nickname"]="",	["level"]=-1,	["birthday"]="05/15/2009 11:31:08",	["mood"]=0,
    /// </summary>
    ----------------------
/// <summary>
/// 取得指定的宠物的资料
/// 接收参数：
/// nid 宠物的所有者的数字ID
/// id 指定的宠物的ID
/// 返回值：
/// petid 
/// nickname 昵称
/// birthday 生日
/// level 级别
/// friendliness 亲密度
/// strong 体力值
/// cleanness 清洁值
/// mood 心情值
/// nextlevelfr 长级到下一级所需的亲密度
/// health 健康状态
/// [ errorCode ]
/// </summary> 


--]]
--petevolved_get_cache_policy = "access plus 1 minutes";
--paraworld.create_wrapper("paraworld.homeland.petevolved.Get", "%MAIN%/API/Pet/Get.ashx", 
---- PreProcessor
--function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	--if(not paraworld.use_game_server) then
		--msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	--end	
	--msg.nid = tonumber(msg.nid);
	--msg.id = tonumber(msg.id);
	--
	---- cache policy
	--local cache_policy = msg.cache_policy or petevolved_get_cache_policy;
	--if(type(cache_policy) == "string") then
		--cache_policy = System.localserver.CachePolicy:new(cache_policy);
	--end
	--msg.cache_policy = nil;
	--
	---- always get from local server if offline mode
	--if(paraworld.OfflineMode) then
		--cache_policy = System.localserver.CachePolicies["always"];
	--end
	--
	--local ls = System.localserver.CreateStore(nil, 3);
	--if(not ls) then
		--return;
	--end
	--
	---- if local server has an unexpired result, remove the uid from msg.uid and return the result to callbackFunc otherwise, continue. 
	--local HasResult;
	---- make url
	--local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "nid", msg.nid, "id", msg.id});
	--local item = ls:GetItem(url)
	--if(item and item.entry and item.payload) then
		--if(not cache_policy:IsExpired(item.payload.creation_date)) then
			---- we found an unexpired result for gsid, return the result to callbackFunc
			--HasResult = true;
			---- make output msg
			--local output_msg = commonlib.LoadTableFromString(item.payload.data);
			--
			--LOG.std("", "debug", "API", "unexpired local version for : %s", url)
			--
			--if(callbackFunc) then
				--callbackFunc(output_msg, callbackParams)
			--end	
		--end
	--end
	--if(HasResult) then
		---- don't require web API call
		--return true;
	--end	
	---- commonlib.echo("fetching : "..url)
--end,
---- Post Processor
--function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	--if(type(msg) == "table" and not msg.errorcode) then
		--
		------ DEBUG: is adopted
		----msg.isadopted = true;
		--
		--local ls = System.localserver.CreateStore(nil, 3);
		--if(ls) then
			---- make output msg
			--local output_msg = msg;
			---- make url
			--local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "nid", inputMsg.nid, "id", inputMsg.id});
			--
			---- make entry
			--local item = {
				--entry = System.localserver.WebCacheDB.EntryInfo:new({
					--url = url,
				--}),
				--payload = System.localserver.WebCacheDB.PayloadInfo:new({
					--status_code = System.localserver.HttpConstants.HTTP_OK,
					--data = commonlib.serialize_compact(output_msg),
				--}),
			--}
			---- save to database entry
			--local res = ls:PutItem(item);
			--if(res) then 
				--LOG.std("", "debug", "API", "mount pet data of %s saved to local server", tostring(url));
			--else	
				--LOG.warn("failed saving pet data of %s to local server", tostring(url))
				--LOG.warn(output_msg);
			--end
		--end -- if(ls) then
	--elseif(type(msg) == "table" and msg.errorcode) then
		--LOG.std("", "error", "API", "paraworld.homeland.petevolved.Get: errorcode:"..tostring(msg.errorcode));
		--LOG.std("", "error", "API", msg);
	--else
		--LOG.std("", "error", "API", "paraworld.homeland.petevolved.Get: unsupported message format");
		--LOG.std("", "error", "API", msg);
	--end
--end);


paraworld.homeland.petevolved.Get = 
function(msg, queuename, callback, cache_policy, ...)
	
	if(not msg.cache_policy) then
		msg.cache_policy = cache_policy or "access plus 1 minutes";
	end
	if(msg.nid == System.User.nid) then
		paraworld.users.GetUserAndDragonInfo(msg, queuename, callback, cache_policy, ...);
	else
		paraworld.users.getInfo(msg, queuename, callback, cache_policy, ...);
	end
end


-- read the pet info in local server
-- @return: pet info in table or nil if not valid in local server
function paraworld.homeland.petevolved.get_get_inlocalserver(nid, id)
	nid = tonumber(nid);
	id = tonumber(id);
	if(not id) then
		LOG.std("", "error", "API", "nil id got in paraworld.homeland.petevolved.get_get_inlocalserver")
		return;
	end
	local url_get = paraworld.users.getInfo.GetUrl();
	local url_get = NPL.EncodeURLQuery(url_get, {"format", 1, "nids", nid, })
	local ls = System.localserver.CreateStore(nil, 3);
	if(ls) then
		local item = ls:GetItem(url_get);
		if(item and item.entry and item.payload) then
			local output_msg = commonlib.LoadTableFromString(item.payload.data);
			if(output_msg and not output_msg.errorcode) then
				return output_msg;
			end
		end
	end
end

--[[
[host]/API/Pet/Fosterage 
        /// <summary>
        /// 寄养宠物
        /// 接收参数：
        ///     sessionkey  当前登录用户的SessionKey
        /// 返回值：
        ///     issuccess
        ///     [ updates ][list] 输出兑换后叠加在旧数据上的物品
        ///         guid
        ///         bag
        ///         cnt
        ///     [ adds ][list] 输出兑换后新增的数据
        ///         guid
        ///         gsid
        ///         bag
        ///         cnt
        ///         position
        ///     [ stats ][list] 输出兑换后各属性值的变化
        ///         gsid  -1:P币；0:E币；-2:亲密度；-3:爱心值；-4:力量值；-5:敏捷值；-6:智慧值；-7:建筑熟练度；-8:抱抱龙等级；-9:体力值；-10:清洁值；-11:心情值；-12:健康状态
        ///         cnt
        ///     [ errorcode ]
        /// </summary>
]]
paraworld.create_wrapper("paraworld.homeland.petevolved.Fosterage", "%MAIN%/API/Pet/Fosterage.ashx");



--[[
[host]/API/Pet/RetrieveAdoptedDragon 
        /// <summary>
        /// 将寄养的宠物接回
        /// 接收参数：
        ///     sessionkey  当前登录用户的SessionKey
        ///     petid  宠物的ID
        /// 返回值：
        ///     issuccess
        ///     [ updates ][list] 输出兑换后叠加在旧数据上的物品
        ///         guid
        ///         bag
        ///         cnt
        ///     [ adds ][list] 输出兑换后新增的数据
        ///         guid
        ///         gsid
        ///         bag
        ///         cnt
        ///         position
        ///     [ stats ][list] 输出兑换后各属性值的变化
        ///         gsid  -1:P币；0:E币；-2:亲密度；-3:爱心值；-4:力量值；-5:敏捷值；-6:智慧值；-7:建筑熟练度；-8:抱抱龙等级；-9:体力值；-10:清洁值；-11:心情值；-12:健康状态
        ///         cnt
        ///     [ errorcode ]
        /// </summary>
]]
paraworld.create_wrapper("paraworld.homeland.petevolved.RetrieveAdoptedDragon", "%MAIN%/API/Pet/RetrieveAdoptedDragon.ashx");

--[[
Update
    /// <summary>
    /// 修改指定的宠物的资料
    /// 接收参数：
    ///     sessionkey
    ///     id
    ///     nickname
    /// 返回值：
    ///     issuccess
    ///     [ errorcode ]
    /// </summary>
--]]
paraworld.create_wrapper("paraworld.homeland.petevolved.Update", "%MAIN%/API/Pet/Update.ashx",
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not paraworld.use_game_server) then
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	if(msg.issuccess == true) then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			local url_petevolved_get = paraworld.users.getInfo.GetUrl();
			url_petevolved_get = NPL.EncodeURLQuery(url_petevolved_get, {"format", 1, "nids", Map3DSystem.User.nid,});
			local item = ls:GetItem(url_petevolved_get)
			if(item and item.entry and item.payload) then
				local output_msg_ls = commonlib.LoadTableFromString(item.payload.data);
				if(output_msg_ls) then
					-- TODO: currently the message contains all pet information
					-- TODO: message is cached in local server, remove the rest of the message from web traffic
					-- make pet get data
					output_msg_ls.petname = inputMsg.nickname;
					
					-- update the data in return message with the local server version
					-- fill non-returned fields, if difference use the return message version
					local field, data;
					for field, data in pairs(output_msg_ls) do
						if(msg[field] == nil) then
							msg[field] = data;
						end
					end
					
					-- make entry
					local item = {
						entry = System.localserver.WebCacheDB.EntryInfo:new({url = url_petevolved_get,}),
						payload = System.localserver.WebCacheDB.PayloadInfo:new({
							status_code = System.localserver.HttpConstants.HTTP_OK,
							data = commonlib.serialize_compact(output_msg_ls),
						}),
					}
					-- save to database entry
					local res = ls:PutItem(item);
					if(res) then
						LOG.std("", "debug", "API", "Pet info of %s updated to local server after petevolved.Update", tostring(url_petevolved_get));
					else
						LOG.warn("failed updating pet info of %s to local server after petevolved.Update", tostring(url_petevolved_get));
						LOG.warn(output_msg_ls);
					end
				end
			end
		end -- if(ls) then
	end
end
);

--[[
Caress
    /// <summary>
    /// 抚摸指定的宠物
    /// 接收参数：
    ///     sessionkey
    ///     petid
    /// 返回值：
    ///     issuccess
    ///     [ errorcode ]
    /// </summary>

--]]
--
-- *** DEPRECATED *** 
--
paraworld.create_wrapper("paraworld.homeland.petevolved.Caress", "%MAIN%/API/Pet/Caress",paraworld.prepLoginRequried);

--[[
UseItem
    /// <summary>
    /// 将指定的物品应用到指定的宠物身上
    /// 接收参数：
    ///     sessionKey 当前登录用户的sessionKey
    ///     nid 宠物所有者的数字ID
    ///     petID
    ///     itemGUID 使用的物品的GUID
    ///     bag 使用的物品所在的包
    /// 返回值：
    ///     isSuccess
    ///     level 级别
    ///     friendliness 亲密度
    ///     strong 体力值
    ///     nextlevelfr 长级到下一级所需的亲密度
    ///     health 健康状态
    ///     [ errorCode ]
    /// </summary>
--]]
paraworld.create_wrapper("paraworld.homeland.petevolved.UseItem", "%MAIN%/API/Pet/UseItem.ashx",
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not paraworld.use_game_server) then
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	end
	msg.gsid_c = msg.gsid;
	msg.gsid = nil;
	msg.add_strong = nil; -- strong
	msg.add_cleanness = nil; -- cleanness
	msg.add_mood = nil; -- mood
	msg.add_friendliness = nil; -- friendliness
	msg.add_kindness = nil; -- kindness
	msg.add_intelligence = nil; -- intelligence
	msg.add_agility = nil; -- agility
	msg.add_strength = nil; -- strength
	msg.add_archskillpts = nil; -- archskillpts
	msg.heal_pet = nil;
	msg.revive_pet = nil;
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(msg.issuccess == true) then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			-- update the petevolved.get infomation
			local url_petevolved_get = paraworld.users.getInfo.GetUrl();
			url_petevolved_get = NPL.EncodeURLQuery(url_petevolved_get, {"format", 1, "nids", inputMsg.nid,});
			local item = ls:GetItem(url_petevolved_get)
			if(item and item.entry and item.payload) then
				local output_msg_ls = commonlib.LoadTableFromString(item.payload.data);
				if(output_msg_ls and output_msg_ls.health) then
					local health_ls = output_msg_ls.health;
					if(health_ls == 2) then -- death
						-- no item will take effect unless the item with the revive_pet value on
						if(originalMsg.revive_pet == 1) then
							output_msg_ls.strong = 300;
							output_msg_ls.cleanness = 300;
							output_msg_ls.mood = 300;
							output_msg_ls.health = 0;
						end
					elseif(health_ls == 0 or health_ls == 1) then -- normal or sick
						-- add stats according to global store stats_values
						if(originalMsg.heal_pet == 1) then
							output_msg_ls.health = 0;
						end
						if(originalMsg.add_strong) then
							output_msg_ls.strong = output_msg_ls.strong + originalMsg.add_strong;
							if(output_msg_ls.strong > 500) then
								output_msg_ls.strong = 500;
							elseif(output_msg_ls.strong < 0) then
								output_msg_ls.strong = 0;
							end
						end
						if(originalMsg.add_cleanness) then
							output_msg_ls.cleanness = output_msg_ls.cleanness + originalMsg.add_cleanness;
							if(output_msg_ls.cleanness > 500) then
								output_msg_ls.cleanness = 500;
							elseif(output_msg_ls.cleanness < 0) then
								output_msg_ls.cleanness = 0;
							end
						end
						if(originalMsg.add_mood) then
							output_msg_ls.mood = output_msg_ls.mood + originalMsg.add_mood;
							if(output_msg_ls.mood > 500) then
								output_msg_ls.mood = 500;
							elseif(output_msg_ls.mood < 0) then
								output_msg_ls.mood = 0;
							end
						end
						if(originalMsg.add_friendliness) then
							output_msg_ls.friendliness = output_msg_ls.friendliness + originalMsg.add_friendliness;
							if(output_msg_ls.friendliness >= output_msg_ls.nextlevelfr) then
								output_msg_ls.friendliness = output_msg_ls.friendliness - output_msg_ls.nextlevelfr;
								output_msg_ls.level = output_msg_ls.level + 1;
							end
						end
						if(originalMsg.add_kindness) then
							output_msg_ls.kindness = output_msg_ls.kindness + originalMsg.add_kindness;
						end
						if(originalMsg.add_intelligence) then
							output_msg_ls.intelligence = output_msg_ls.intelligence + originalMsg.add_intelligence;
						end
						if(originalMsg.add_agility) then
							output_msg_ls.agility = output_msg_ls.agility + originalMsg.add_agility;
						end
						if(originalMsg.add_strength) then
							output_msg_ls.strength = output_msg_ls.strength + originalMsg.add_strength;
						end
						if(originalMsg.add_archskillpts) then
							output_msg_ls.archskillpts = output_msg_ls.archskillpts + originalMsg.add_archskillpts;
						end
					end
					
					
					LOG.std("", "debug", "API", "lazy message:")
					LOG.std("", "debug", "API", output_msg_ls);
					LOG.std("", "debug", "API", "good message:")
					LOG.std("", "debug", "API", msg);
					
					-- update the data in return message with the local server version
					-- fill non-returned fields, if difference use the return message version
					local field, data;
					for field, data in pairs(output_msg_ls) do
						if(msg[field] == nil) then
							msg[field] = data;
						end
					end
					
					-- make entry
					local item = {
						entry = System.localserver.WebCacheDB.EntryInfo:new({url = url_petevolved_get,}),
						payload = System.localserver.WebCacheDB.PayloadInfo:new({
							status_code = System.localserver.HttpConstants.HTTP_OK,
							data = commonlib.serialize_compact(msg),
						}),
					}
					-- save to database entry
					local res = ls:PutItem(item);
					if(res) then
						LOG.std("", "debug", "API", "Pet info of %s updated to local server after petevolved.UseItem", tostring(url_petevolved_get));
					else
						LOG.warn("failed updating pet info of %s to local server after petevolved.UseItem", tostring(url_petevolved_get));
						LOG.warn(output_msg_ls);
					end
				end
			end
			
			local gsItem = paraworld.globalstore.gettemplateinlocalserver(originalMsg.gsid);
			if(gsItem) then
				local class = gsItem.template.class;
				local subclass = gsItem.template.subclass;
				if(class == 2 and subclass == 3) then
					-- skip delete the item if it is a toy object
					LOG.std("", "debug", "API", "skip delete the toy item in paraworld.homeland.petevolved.UseItem")
					return;
				end
			end
			
			---- NOTE: the bag item will be updated in the updates and adds section, we don't need to consume the item here
			--
			---- update the paraworld.inventory.GetItemsInBag infomation
			---- remove the item from the bag
			--local url_getitemsinbag = paraworld.inventory.GetItemsInBag.GetUrl();
			--local url = NPL.EncodeURLQuery(url_getitemsinbag, {"format", 1, "bag", inputMsg.bag, "nid", Map3DSystem.User.nid})
			--local item = ls:GetItem(url)
			--if(item and item.entry and item.payload) then
				--local output_msg = commonlib.LoadTableFromString(item.payload.data);
				--if(output_msg and output_msg.items) then
					--local _, item;
					--for _, item in ipairs(output_msg.items) do
						--if(item.guid == inputMsg.itemguid) then
							--item.copies = item.copies - 1;
							--break;
						--end
					--end
					---- make entry
					--local item = {
						--entry = System.localserver.WebCacheDB.EntryInfo:new({url = url,}),
						--payload = System.localserver.WebCacheDB.PayloadInfo:new({
							--status_code = System.localserver.HttpConstants.HTTP_OK,
							--data = commonlib.serialize_compact(output_msg),
						--}),
					--}
					---- save to database entry
					--local res = ls:PutItem(item);
					--if(res) then 
						--LOG.std("", "debug", "API", "Bag Items of %s updated to local server after petevolved.UseItem", tostring(url));
					--else	
						--LOG.warn("failed updating bag items of %s to local server after petevolved.UseItem", tostring(url))
						--LOG.warn(output_msg);
					--end
				--end
			--end
			
			-- pass 2: update the items in bag
			if(msg.updates) then
				local _, update;
				for _, update in ipairs(msg.updates) do
					-- stack to existing items
					local url_getitemsinbag = paraworld.inventory.GetItemsInBag.GetUrl();
					local url_getitemsinbag = NPL.EncodeURLQuery(url_getitemsinbag, {"format", 1, "bag", update.bag, "nid", inputMsg.nid})
					local item = ls:GetItem(url_getitemsinbag)
					if(item and item.entry and item.payload) then
						local output_msg = commonlib.LoadTableFromString(item.payload.data);
						if(output_msg and output_msg.items) then
							-- update the copies
							local _, item;
							for _, item in ipairs(output_msg.items) do
								if(item.guid == update.guid) then
									output_msg.items[_].copies = output_msg.items[_].copies + update.cnt;
									update.gsid_fromlocalserver = item.gsid;
									break;
								end
							end
							-- make entry
							local item = {
								entry = System.localserver.WebCacheDB.EntryInfo:new({url = url_getitemsinbag,}),
								payload = System.localserver.WebCacheDB.PayloadInfo:new({
									status_code = System.localserver.HttpConstants.HTTP_OK,
									data = commonlib.serialize_compact(output_msg),
								}),
							}
							-- save to database entry
							local res = ls:PutItem(item);
							if(res) then 
								LOG.std("", "debug", "API", "Bag Items of %s updated to local server after petevolved.UseItem", tostring(url_getitemsinbag));
							else	
								LOG.warn("failed updating bag items of %s to local server after petevolved.UseItem", tostring(url_getitemsinbag))
								LOG.warn(output_msg);
							end
						end
					end
				end
			end
			-- pass 3: add the items in bag
			if(msg.adds) then
				local _, add;
				for _, add in ipairs(msg.adds) do
					-- newly created items
					local url_getitemsinbag = paraworld.inventory.GetItemsInBag.GetUrl();
					local url_getitemsinbag = NPL.EncodeURLQuery(url_getitemsinbag, {"format", 1, "bag", add.bag, "nid", inputMsg.nid})
					local item = ls:GetItem(url_getitemsinbag);
					if(item and item.entry and item.payload) then
						local output_msg = commonlib.LoadTableFromString(item.payload.data);
						if(output_msg and output_msg.items) then
							-- find the largest position in the bag
							local _, item_t;
							local max_position = 0;
							for _, item_t in pairs(output_msg.items) do
								if(item_t.position > max_position) then
									max_position = item_t.position;
								end
							end
							-- add item into bag
							local isExist = false;
							local _, item;
							for _, item in ipairs(output_msg.items) do
								if(item.guid == msg.guid) then
									output_msg.items[_].copies = output_msg.items[_].copies + add.cnt;
									-- item already exist in bag with the same guid
									LOG.std("", "error", "API", "item already exist in bag with the same guid:"..tostring(add.guid).." Count appended.");
									isExist = true;
									break;
								end
							end
							if(isExist == false) then
								local position = max_position + 1;
								local bagfamily;
								local inventorytype;
								local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(add.gsid);
								if(gsItem) then
									bagfamily = gsItem.template.bagfamily;
									inventorytype = gsItem.template.inventorytype;
								end
								if(inventorytype ~= 0 and bagfamily == 0) then
									-- inventorytype specifies the position of the item if bagfamily is 0
									position = inventorytype;
								elseif(inventorytype == 0 and bagfamily == 0) then
									LOG.std("", "error", "API", "inventorytype and bagfamily are both 0 for gsid:"..add.gsid..", check global store item template");
									return;
								end
								table.insert(output_msg.items, {
									guid = add.guid, 
									gsid = add.gsid,
									obtaintime = ParaGlobal.GetDateFormat("yyyy-MM-dd").." "..ParaGlobal.GetTimeFormat("HH:mm:ss"),
									-- use the local time as the temporary obtain time, "8/3/2009 7:06:43 PM"
									position = position,
									clientdata = "",
									serverdata = "",
									copies = add.cnt,
								});
							end
							-- make entry
							local item = {
								entry = System.localserver.WebCacheDB.EntryInfo:new({url = url_getitemsinbag,}),
								payload = System.localserver.WebCacheDB.PayloadInfo:new({
									status_code = System.localserver.HttpConstants.HTTP_OK,
									data = commonlib.serialize_compact(output_msg),
								}),
							}
							-- save to database entry
							local res = ls:PutItem(item);
							if(res) then 
								LOG.std("", "debug", "API", "Bag Items of %s added to local server after petevolved.UseItem", tostring(url_getitemsinbag));
							else	
								LOG.warn("failed adding bag items of %s to local server after petevolved.UseItem", tostring(url_getitemsinbag))
								LOG.warn(output_msg);
							end
						end
					end
				end
			end
		end -- if(ls) then
	end
end
);



--[[
    /// <summary>
    /// 增加指定宠物的战斗经验值
    /// 接收参数：
    ///     nid  宠物主人的NID
    ///     petid  宠物ID
    ///     addexp  增加的经验值
    /// 返回值：
    ///     issuccess
    ///     combatlel  新的战斗级别
    ///     [ updates ][list] 输出叠加在旧数据上的物品
    ///         guid
    ///         bag
    ///         cnt
    ///     [ adds ][list] 输出新增的数据
    ///         guid
    ///         gsid
    ///         bag
    ///         cnt
    ///         position
    ///     [ errorcode ]
    /// </summary>
--]]
paraworld.create_wrapper("paraworld.homeland.petevolved.AddCombatExp", "%MAIN%/API/Pet/AddCombatExp.ashx",
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not paraworld.use_game_server) then
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(msg.issuccess == true) then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			-- pass 1: update the petevolved.get infomation
			local url_petevolved_get = paraworld.users.getInfo.GetUrl();
			url_petevolved_get = NPL.EncodeURLQuery(url_petevolved_get, {"format", 1, "nids", inputMsg.nid,});
			local item = ls:GetItem(url_petevolved_get)
			if(item and item.entry and item.payload) then
				local output_msg_ls = commonlib.LoadTableFromString(item.payload.data);
				if(output_msg_ls) then
					-- combat related data update
					output_msg_ls.combatexp = msg.combatexp;
					output_msg_ls.combatlel = msg.combatlel;
					output_msg_ls.nextlevelexp = msg.nextlevelexp;
					
					-- make entry
					local item = {
						entry = System.localserver.WebCacheDB.EntryInfo:new({url = url_petevolved_get,}),
						payload = System.localserver.WebCacheDB.PayloadInfo:new({
							status_code = System.localserver.HttpConstants.HTTP_OK,
							data = commonlib.serialize_compact(output_msg_ls),
						}),
					}
					-- save to database entry
					local res = ls:PutItem(item);
					if(res) then
						LOG.std("", "debug", "API", "Pet info of %s updated to local server after petevolved.AddCombatExp", tostring(url_petevolved_get));
					else
						LOG.warn("failed updating pet info of %s to local server after petevolved.AddCombatExp", tostring(url_petevolved_get));
						LOG.warn(output_msg_ls);
					end
				end
			end
			
			-- pass 2: update the items in bag
			if(msg.updates) then
				local _, update;
				for _, update in ipairs(msg.updates) do
					-- stack to existing items
					local url_getitemsinbag = paraworld.inventory.GetItemsInBag.GetUrl();
					local url_getitemsinbag = NPL.EncodeURLQuery(url_getitemsinbag, {"format", 1, "bag", update.bag, "nid", inputMsg.nid})
					local item = ls:GetItem(url_getitemsinbag)
					if(item and item.entry and item.payload) then
						local output_msg = commonlib.LoadTableFromString(item.payload.data);
						if(output_msg and output_msg.items) then
							-- update the copies
							local _, item;
							for _, item in ipairs(output_msg.items) do
								if(item.guid == update.guid) then
									output_msg.items[_].copies = output_msg.items[_].copies + update.cnt;
									update.gsid_fromlocalserver = item.gsid;
									break;
								end
							end
							-- make entry
							local item = {
								entry = System.localserver.WebCacheDB.EntryInfo:new({url = url_getitemsinbag,}),
								payload = System.localserver.WebCacheDB.PayloadInfo:new({
									status_code = System.localserver.HttpConstants.HTTP_OK,
									data = commonlib.serialize_compact(output_msg),
								}),
							}
							-- save to database entry
							local res = ls:PutItem(item);
							if(res) then 
								LOG.std("", "debug", "API", "Bag Items of %s updated to local server after petevolved.AddCombatExp", tostring(url_getitemsinbag));
							else	
								LOG.warn("failed updating bag items of %s to local server after petevolved.AddCombatExp", tostring(url_getitemsinbag))
								LOG.warn(output_msg);
							end
						end
					end
				end
			end
			
			-- pass 3: add the items in bag
			if(msg.adds) then
				local _, add;
				for _, add in ipairs(msg.adds) do
					-- newly created items
					local url_getitemsinbag = paraworld.inventory.GetItemsInBag.GetUrl();
					local url_getitemsinbag = NPL.EncodeURLQuery(url_getitemsinbag, {"format", 1, "bag", add.bag, "nid", inputMsg.nid})
					local item = ls:GetItem(url_getitemsinbag);
					if(item and item.entry and item.payload) then
						local output_msg = commonlib.LoadTableFromString(item.payload.data);
						if(output_msg and output_msg.items) then
							-- find the largest position in the bag
							local _, item_t;
							local max_position = 0;
							for _, item_t in pairs(output_msg.items) do
								if(item_t.position > max_position) then
									max_position = item_t.position;
								end
							end
							-- add item into bag
							local isExist = false;
							local _, item;
							for _, item in ipairs(output_msg.items) do
								if(item.guid == msg.guid) then
									output_msg.items[_].copies = output_msg.items[_].copies + add.cnt;
									-- item already exist in bag with the same guid
									LOG.std("", "error", "API", "item already exist in bag with the same guid:"..tostring(add.guid).." Count appended.");
									isExist = true;
									break;
								end
							end
							if(isExist == false) then
								local position = max_position + 1;
								local bagfamily;
								local inventorytype;
								local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(add.gsid);
								if(gsItem) then
									bagfamily = gsItem.template.bagfamily;
									inventorytype = gsItem.template.inventorytype;
								end
								if(inventorytype ~= 0 and bagfamily == 0) then
									-- inventorytype specifies the position of the item if bagfamily is 0
									position = inventorytype;
								elseif(inventorytype == 0 and bagfamily == 0) then
									LOG.std("", "error", "API", "inventorytype and bagfamily are both 0 for gsid:"..add.gsid..", check global store item template");
									return;
								end
								table.insert(output_msg.items, {
									guid = add.guid, 
									gsid = add.gsid,
									obtaintime = ParaGlobal.GetDateFormat("yyyy-MM-dd").." "..ParaGlobal.GetTimeFormat("HH:mm:ss"),
									-- use the local time as the temporary obtain time, "8/3/2009 7:06:43 PM"
									position = position,
									clientdata = "",
									serverdata = "",
									copies = add.cnt,
								});
							end
							-- make entry
							local item = {
								entry = System.localserver.WebCacheDB.EntryInfo:new({url = url_getitemsinbag,}),
								payload = System.localserver.WebCacheDB.PayloadInfo:new({
									status_code = System.localserver.HttpConstants.HTTP_OK,
									data = commonlib.serialize_compact(output_msg),
								}),
							}
							-- save to database entry
							local res = ls:PutItem(item);
							if(res) then 
								LOG.std("", "debug", "API", "Bag Items of %s added to local server after petevolved.AddCombatExp", tostring(url_getitemsinbag));
							else	
								LOG.warn("failed adding bag items of %s to local server after petevolved.AddCombatExp", tostring(url_getitemsinbag))
								LOG.warn(output_msg);
							end
						end
					end
				end
			end
			
		end -- if(ls) then
	end
end
);