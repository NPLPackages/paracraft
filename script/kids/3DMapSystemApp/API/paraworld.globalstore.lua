--[[
Title: item system global store
Author(s): CYF, WangTian
Date: 2009/5/25
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.globalstore.lua");
-------------------------------------------------------
]]

-- create class
local globalstore = commonlib.gettable("paraworld.globalstore");

local string_gfind = string.gfind;
-- saving cache read from globalstore.db.mem
local globalstore_cache;
local globalstore_db_name;
local function GetGlobalStoreDBName()
	if(not globalstore_db_name) then
		if(System.options.version and System.options.version~="kids") then
			globalstore_db_name = "globalstore."..System.options.version;
		else
			globalstore_db_name = "globalstore"
		end
		LOG.std(nil, "debug", "GlobalStore", "global store db name is %s", globalstore_db_name)
	end
	return globalstore_db_name;
end

paraworld.CreateRESTJsonWrapper("paraworld.globalstore.create", "http://items.test.pala5.cn/create.ashx");

--[[
	/// <summary>
	/// get the global store description and template data according to the global store id
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		[ "gsids" ] = string  // global store ids separated with ","  maximum gsids per request is 10
	/// }
	/// </param>
	/// <returns>
	///		[ "issuccess" ] = boolean   // is success
	///		[ "globalstoreitems" ] = list{
	///			gsid = int
	///			assetfile = string
	///			descfile = string
	///			type = int
	///			category = string
	///			icon = string
	///			pbuyprice = int
	///			ebuyprice = int
	///			psellprice = int
	///			esellprice = int
	///			requirepayment = int
	///			template = {
	///				class = int
	///				subclass = int
	///				name = int
	///				inventorytype = int
	///				// and other template data fields
	///				}
	///			}  // item count depending on the gsids count
	///		[ "errorcode" ] = int   // errorcode if issuccess is false
	///		[ "info" ] = string  // error info if issuccess is false
	/// </returns>
-- TODO: put item description into global store
]] 
-- the local server will cache each result.
local read_globalstore_cache_policy = System.localserver.CachePolicies["always"];
paraworld.create_wrapper("paraworld.globalstore.read", "%MAIN%/API/Items/read.ashx", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	-- make sure gsids is string
	if(type(msg.gsids) == "number") then
		msg.gsids = tostring(msg.gsids);
	end
	
	-- cache policy
	local cache_policy = msg.cache_policy or read_globalstore_cache_policy;
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end
	msg.cache_policy = nil;
	
	-- always get from local server if offline mode
	if(paraworld.OfflineMode) then
		cache_policy = System.localserver.CachePolicies["always"];
	end
	
	local cache_result, unknown_count = paraworld.globalstore.read_from_cache(msg.gsids);
	if(cache_result and unknown_count == 0) then
		if(callbackFunc) then
			callbackFunc({globalstoreitems = cache_result}, callbackParams)
		end
		-- don't require web API call
		return true;
	end

	local ls = System.localserver.CreateStore(nil, 3, GetGlobalStoreDBName());
	if(not ls) then
		return;
	end
	
	msg.gsids = commonlib.Encoding.SortCSVString(msg.gsids);
	
	local globalstoreitems = {};
	local unknown_gsids = nil;
	
	if(msg.gsids) then
		for gsid in string_gfind(msg.gsids, "([^,]+)") do
			-- if local server has an unexpired result, remove the uid from msg.uid and return the result to callbackFunc
			-- otherwise, continue. 
			local HasResult;
			-- make input msg
			local input_msg = {
				gsids = tostring(gsid),
			};
			-- make url
			local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "gsids", tostring(gsid), })
			local item = ls:GetItem(url)
			if(item and item.entry and item.payload) then
				if(not cache_policy:IsExpired(item.payload.creation_date)) then
					-- we found an unexpired result for gsid, return the result to callbackFunc
					HasResult = true;
					-- make output msg
					local output_msg = commonlib.LoadTableFromString(item.payload.data);
					if(output_msg and output_msg.globalstoreitems and output_msg.globalstoreitems[1]) then
						globalstoreitems[#globalstoreitems+1] = output_msg.globalstoreitems[1];
					end
					--if(callbackFunc) then
						--callbackFunc(output_msg, callbackParams)
					--end	
				end
			end
			if(not HasResult) then
				unknown_gsids = (unknown_gsids or "")..gsid..","
			end	
		end -- for gsid in string.gfind(msg.gsids, "([^,]+)") do
	end
	
	if(unknown_gsids == nil) then
		-- NOTE 2009/6/11: get global store item changed from immediate callback on each local server record hit
		--		to batch callback call on all local server record hit
		--		If gsids hit partially, we still call the RPC with the original message. Records on global store server
		--		are cached in memory and only brings more data traffic when returned
		-- NOTE: this also assures the callback function is called only ONCE no matter how many or none 
		--		local server record hit
		if(callbackFunc) then
			callbackFunc({globalstoreitems = globalstoreitems}, callbackParams)
		end
		-- don't require web API call
		return true;
	else
		LOG.std(nil, "debug", "globalstore", {"sync unknown global store items", unknown_gsids});
		-- msg.gsids = unknown_gsids; -- @note: shall we only fetch unknown ones?
		-- NOTE: remind the editor syncing gsid
		if(commonlib.getfield("System.options.isAB_SDK")) then
			_guihelper.MessageBox(string.format("sync unknown global store items, %s", tostring(unknown_gsids)));
		end
	end
end,

-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	-- NOTE 2009/6/11: skip the expired version if not found
	--		usually the local server version is never expired, global store uses an never expire cache policy
	
	--if(msg == nil and inputMsg and inputMsg.gsids) then
		--local ls = System.localserver.CreateStore(nil, 3, GetGlobalStoreDBName());
		--if(not ls) then
			--return
		--end
		--local gsItems = {};
		---- if results are not found, we will try local server expired version
		--if(inputMsg.gsids) then
			--local gsid;
			--for gsid in string.gfind(inputMsg.gsids, "([^,]+)") do
				---- if local server has an result, remove the gsid from msg.uid and return the result to callbackFunc
				---- make input msg
				--local input_msg = {
					--gsids = tostring(gsid),
				--};
				---- make url
				--local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "gsids", tostring(gsid), })
				--local item = ls:GetItem(url)
				--if(item and item.entry and item.payload) then
					---- make output msg
					--local lsMsg = commonlib.LoadTableFromString(item.payload.data);
					--if(lsMsg and lsMsg.globalstoreitems and lsMsg.globalstoreitems[1]) then
						--log("Expired local version is used for "..url.."\n")
						--table.insert(gsItems, lsMsg.globalstoreitems[1]);
					--end	
				--end
			--end
		--end
		--if( (#gsItems) > 0 ) then
			--return {globalstoreitems = gsItems};
		--end
		
	if(type(msg) == "table" and msg.globalstoreitems) then
		local ls = System.localserver.CreateStore(nil, 3, GetGlobalStoreDBName());
		if(ls) then
			-- make the url
			local i, item
			for i, item in ipairs(msg.globalstoreitems) do
				if(item.gsid) then
					-- make input msg
					local input_msg = {
						gsids = tostring(item.gsid),
					};
					-- make output msg
					local output_msg = {
						globalstoreitems = {item},
					};
					-- make url
					local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "gsids", input_msg.gsids, })
					
					-- make entry
					local item = {
						entry = System.localserver.WebCacheDB.EntryInfo:new({
							url = url,
						}),
						payload = System.localserver.WebCacheDB.PayloadInfo:new({
							status_code = System.localserver.HttpConstants.HTTP_OK,
							data = output_msg,
						}),
					}
					-- save to database entry
					local res = ls:PutItem(item);
					if(res) then 
						LOG.std("", "system","GlobalStore", "Global store template info of %s saved to local server", tostring(url));
					else	
						LOG.std("", "warning","GlobalStore", LOG.tostring("warning: failed saving global store template info of %s to local server\n", tostring(url))..LOG.tostring(output_msg));
					end
				end
			end -- for i, item in ipairs(msg.globalstoreitems) do
		end -- if(ls) then
	end
end,
nil,nil, nil,nil, 100000);

-- read the global store template in local server
-- @return: item template in table or nil if not valid in local server
function paraworld.globalstore.gettemplateinlocalserver(gsid)
	local url_read = paraworld.globalstore.read.GetUrl();
	local url_read = NPL.EncodeURLQuery(url_read, {"format", 1, "gsids", gsid, })
	local ls = System.localserver.CreateStore(nil, 3, GetGlobalStoreDBName());
	if(ls) then
		local item = ls:GetItem(url_read)
		if(item and item.entry and item.payload) then
			local output_msg = commonlib.LoadTableFromString(item.payload.data);
			if(output_msg and output_msg.globalstoreitems and output_msg.globalstoreitems[1]) then
				return output_msg.globalstoreitems[1];
			end
		end
	end
end


-- NOTE: for Taurus ONLY
-- NOTE: Since we don't know the exact abbr of each API in Taurus application, we manually hard code the item_read url
-- read the global store template in local server
-- @return: item template in table or nil if not valid in local server
function paraworld.globalstore.gettemplateinlocalserver_fortaurus(gsid)
	-- NOTE: Since we don't know the exact abbr of each API in Taurus application, we manually hard code the item_read url
	local url_read = "Items.read";
	local url_read = NPL.EncodeURLQuery(url_read, {"format", 1, "gsids", gsid, })
	local ls = System.localserver.CreateStore(nil, 3, GetGlobalStoreDBName());
	if(ls) then
		local item = ls:GetItem(url_read)
		if(item and item.entry and item.payload) then
			local output_msg = commonlib.LoadTableFromString(item.payload.data);
			if(output_msg and output_msg.globalstoreitems and output_msg.globalstoreitems[1]) then
				return output_msg.globalstoreitems[1];
			end
		end
	end
end


--[[
        /// <summary>
        /// 取得指定的用户在当天、本周内共获得指定物品的数量
        /// 接收参数：
        ///     nid
        ///     gsid
        /// 返回值：
        ///     inday
        ///     inweek
        ///     [ errorcode ]
        /// </summary>
]]
paraworld.create_wrapper("paraworld.globalstore.GetGSObtainCntInTimeSpan", "%MAIN%/API/Items/GetGSObtainCntInTimeSpan.ashx");

--[[
        /// <summary>
        /// 取得指定用户在当天、本周内共获得指定的一组物品的数量
        /// 接收参数：
        ///     nid
        ///     gsids  多个GSID之间用英文逗号分隔
        /// 返回值：
        ///     list [list]
        ///         gsid
        ///         inday
        ///         inweek
        ///     [ errorcode ]
        /// </summary>
]]
paraworld.create_wrapper("paraworld.globalstore.GetGSObtainCntInTimeSpans", "%MAIN%/API/Items/GetGSObtainCntInTimeSpans.ashx");


paraworld.create_wrapper("paraworld.FlushLocalCache", "%MAIN%/API/FlushLocalCache.ashx");


paraworld.CreateRESTJsonWrapper("paraworld.globalstore.update", "http://items.test.pala5.cn/update.ashx");

paraworld.CreateRESTJsonWrapper("paraworld.globalstore.delete", "http://items.test.pala5.cn/delete.ashx");

paraworld.CreateRESTJsonWrapper("paraworld.globalstore.approve", "http://items.test.pala5.cn/approve.ashx");


local GetAllCates_cache_policy = "access plus 1 day";
paraworld.create_wrapper("paraworld.globalstore.GetAllCates", "%MAIN%/API/Items/GetAllCates.ashx",
-- pre processor
function(self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	local cache_policy = msg.cache_policy or GetAllCates_cache_policy;
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end
	msg.cache_policy = nil;
	
	local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return;
	end
	local url = self.GetUrl();
	
	local item = ls:GetItem(url)
	if(item and item.entry and item.payload) then
		if(not cache_policy:IsExpired(item.payload.creation_date)) then
			-- make output msg
			local output_msg = item.payload.data;
			if(output_msg) then
				if(callbackFunc) then
					callbackFunc(output_msg, callbackParams)
				end
				LOG.std(nil, "debug", "rest", "unexpired data used for %s", url);
				return true;
			end
		end
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	if(type(msg) == "table") then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			-- make entry
			local url = self.GetUrl();
			local output_msg = msg;
			local item = {
				entry = System.localserver.WebCacheDB.EntryInfo:new({
					url = url,
				}),
				payload = System.localserver.WebCacheDB.PayloadInfo:new({
					status_code = System.localserver.HttpConstants.HTTP_OK,
					data = output_msg,
				}),
			}
			-- save to database entry
			local res = ls:PutItem(item);
			if(res) then 
				LOG.std(nil, "debug", "rest", "data saved to ls for %s", url);
			else	
				LOG.std(nil, "error", "rest", "data failed to save to ls for %s", url);
			end
		end
	end
end
);



local GetByCate_cache_policy = "access plus 1 day";
paraworld.create_wrapper("paraworld.globalstore.GetByCate", "%MAIN%/API/Items/GetByCate.ashx",
-- pre processor
function(self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	local cache_policy = msg.cache_policy or GetByCate_cache_policy;
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end
	msg.cache_policy = nil;
	
	local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return;
	end
	msg.cateid = msg.cateid or 0;
	local url = self.GetUrl().. "_" .. msg.cateid;
	
	local item = ls:GetItem(url)
	if(item and item.entry and item.payload) then
		if(not cache_policy:IsExpired(item.payload.creation_date)) then
			-- make output msg
			local output_msg = item.payload.data;
			if(output_msg) then
				if(callbackFunc) then
					callbackFunc(output_msg, callbackParams)
				end
				LOG.std(nil, "debug", "rest", "unexpired data used for %s", url);
				return true;
			end
		end
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	if(type(msg) == "table") then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			-- make entry
			local url = self.GetUrl() .. "_" .. (inputMsg.cateid or "0");
			local output_msg = msg;
			local item = {
				entry = System.localserver.WebCacheDB.EntryInfo:new({
					url = url,
				}),
				payload = System.localserver.WebCacheDB.PayloadInfo:new({
					status_code = System.localserver.HttpConstants.HTTP_OK,
					data = output_msg,
				}),
			}
			-- save to database entry
			local res = ls:PutItem(item);
			if(res) then 
				LOG.std(nil, "debug", "rest", "data saved to ls for %s", url);
			else	
				LOG.std(nil, "error", "rest", "data failed to save to ls for %s", url);
			end
		end
	end
end);

local function GetGlobalStoreCacheFile()
	return "Database/"..GetGlobalStoreDBName()..".db.mem";
end

-- @param gsids: if "*" it will return all
function paraworld.globalstore.read_from_cache(gsids)
	if(globalstore_cache == false) then
		return;
	elseif(globalstore_cache == nil) then
		local cache = paraworld.globalstore.LoadFromFile()
		if(cache) then
			globalstore_cache = cache;
		else
			globalstore_cache = false;
		end
	end
	if(globalstore_cache and gsids) then
		if(gsids == "*") then
			return globalstore_cache;
		else
			local unknown_count = 0;
			local o = {};
			for gsid in string_gfind(gsids, "([^,]+)") do
				gsid = tonumber(gsid);
				local template = globalstore_cache[gsid];
				if(template) then
					o[#o+1] = template;
				else
					unknown_count = unknown_count + 1;
				end
			end
			return o, unknown_count;
		end
	end
end

-- @return table of gsid to data map. or false if not found
function paraworld.globalstore.LoadFromFile(filename)
	filename = filename or GetGlobalStoreCacheFile();
	local globalstore_cache = false;
	local file = ParaIO.open(filename, "r");
	if(file:IsValid()) then
		local count = 0;
		local all_data = NPL.LoadTableFromString(ParaMisc.SimpleDecode(file:GetText()));
		if(all_data) then
			globalstore_cache = {};
			for i, o in ipairs(all_data) do
				if(o and type(o[19]) == "table") then
					local t = o[19];
					local item = {
						gsid=o[1],
						type=o[2],
						count=o[3],
						icon=o[4],
						category=o[5],
						maxdailycount=o[6],
						esellprice=o[7],
						ebuyprice=o[8],
						psellprice=o[9],
						pbuyprice=o[10],
						requirepayment=o[11],
						esellrandombonus=o[12],
						assetkey=o[13],
						assetfile=o[14],
						hourlylimitedpurchase=o[15],
						dailylimitedpurchase=o[16],
						maxweeklycount=o[17],
						descfile=o[18],
						template = {
							name=t[1],
							description=t[2],
							stat_type_1=t[3],
							stat_value_1=t[4],
							stat_type_2=t[5],
							stat_value_2=t[6],
							stat_type_3=t[7],
							stat_value_3=t[8],
							stat_type_4=t[9],
							stat_value_4=t[10],
							stat_type_5=t[11],
							stat_value_5=t[12],
							stat_type_6=t[13],
							stat_value_6=t[14],
							stat_type_7=t[15],
							stat_value_7=t[16],
							stat_type_8=t[17],
							stat_value_8=t[18],
							stat_type_9=t[19],
							stat_value_9=t[20],
							stat_type_10=t[21],
							stat_value_10=t[22],
							inventorytype=t[23],
							class=t[24],
							subclass=t[25],
							bagfamily=t[26],
							expiretime=t[27],
							expiredate=t[28],
							statscount=t[29],
							expiretype=t[30],
							itemsetid=t[31],
							maxcount=t[32],
							material=t[33],
							canexchange=t[34],
							destroyafteruse=t[35],
							canusedirectly=t[36],
							rechargeable=t[37],
							maxcopiesinstack=t[38],
							destroyafterexpire=t[39],
							cangift=t[40],
							cansell=t[41],
						}
					};
					count = count + 1;
					globalstore_cache[item.gsid] = item;
				else
					LOG.std(nil, "error", "globalstore", "failed to parse");
				end
			end
		else
			LOG.std(nil, "error", "globalstore", "failed to parse file %s", filename);
		end
		LOG.std(nil, "info", "globalstore", "%d items read from %s", count, filename);
		file:close();
	end
	return globalstore_cache;
end

function paraworld.globalstore.SaveToFile(filename, templates)
	if(globalstore_cache) then
		-- no need to save since we have already loaded from cache file
		return;
	end
	filename = filename or GetGlobalStoreCacheFile();
	templates = templates or System.Item.ItemManager.GlobalStoreTemplates;
	if(not templates) then
		return;
	end
	local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		local function save_template(template)
			local t = template.template;
			local o = {
				template["gsid"],
				template["type"],
				template["count"],
				template["icon"],
				template["category"],
				template["maxdailycount"],
				template["esellprice"],
				template["ebuyprice"],
				template["psellprice"],
				template["pbuyprice"],
				template["requirepayment"],
				template["esellrandombonus"],
				template["assetkey"],
				template["assetfile"],
				template["hourlylimitedpurchase"],
				template["dailylimitedpurchase"],
				template["maxweeklycount"],
				template["descfile"],
				{
					t["name"],
					t["description"],
					t["stat_type_1"],
					t["stat_value_1"],
					t["stat_type_2"],
					t["stat_value_2"],
					t["stat_type_3"],
					t["stat_value_3"],
					t["stat_type_4"],
					t["stat_value_4"],
					t["stat_type_5"],
					t["stat_value_5"],
					t["stat_type_6"],
					t["stat_value_6"],
					t["stat_type_7"],
					t["stat_value_7"],
					t["stat_type_8"],
					t["stat_value_8"],
					t["stat_type_9"],
					t["stat_value_9"],
					t["stat_type_10"],
					t["stat_value_10"],
					t["inventorytype"],
					t["class"],
					t["subclass"],
					t["bagfamily"],
					t["expiretime"],
					t["expiredate"],
					t["statscount"],
					t["expiretype"],
					t["itemsetid"],
					t["maxcount"],
					t["material"],
					t["canexchange"],
					t["destroyafteruse"],
					t["canusedirectly"],
					t["rechargeable"],
					t["maxcopiesinstack"],
					t["destroyafterexpire"],
					t["cangift"],
					t["cansell"],
				}
			};
			file:WriteString(commonlib.serialize_compact(o));
			file:WriteString(",\r\n");
		end
		local count = 0;
		--save all template
		file:WriteString("{ -- auto generated by paraworld.globalstore.SaveToFile() \r\n");
		for gsid, _ in pairs(templates) do
			paraworld.globalstore.read({gsids=tostring(gsid)}, "saving",function(msg)
				if(msg and msg.globalstoreitems and msg.globalstoreitems[1]) then
					count = count + 1;
					save_template(msg.globalstoreitems[1]);
				end
			end)
		end
		file:WriteString("}");
		LOG.std(nil, "info", "globalstore", "%d items saved to %s", count, filename);
		file:close();

		-- encode file
		file = ParaIO.open(filename, "r");
		if(file:IsValid()) then
			local text = file:GetText();
			local encoded_text = ParaMisc.SimpleEncode(text);
			ParaMisc.SimpleEncode("1"); -- shrink buffer
			file:close();
			file = ParaIO.open(filename, "w");
			if(file:IsValid()) then
				file:WriteString(encoded_text);
				file:close();
			end
		end
	end
end