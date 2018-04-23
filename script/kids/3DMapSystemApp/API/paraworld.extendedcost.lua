--[[
Title: item system inventory
Author(s): WangTian
Date: 2009/5/25
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.extendedcost.lua");
-------------------------------------------------------
]]

-- create class
local inventory = commonlib.gettable("paraworld.inventory");
local extendedcost = commonlib.gettable("paraworld.extendedcost");
-- saving cache read from extendedcost.db.mem
local extendedcost_cache;

local extendedcost_db_name;
local function GetExtendedCostDBName()
	if(not extendedcost_db_name) then
		if(System.options.version and System.options.version~="kids") then
			extendedcost_db_name = "extendedcost."..System.options.version;
		else
			extendedcost_db_name = "extendedcost"
		end
		LOG.std(nil, "debug", "item", "extended cost db name is %s", extendedcost_db_name)
	end
	return extendedcost_db_name;
end

--[[
    /// <summary>
    /// 取得指定的物品兑换规则
    /// 接收参数：
    ///     exID 兑换规则的ID
    /// 返回值：
    ///     exname
    ///     froms[list]
    ///         key
    ///         value
    ///     tos[list]
    ///         key
    ///         value
    ///     pres[list] 先决条件
    ///         key
    ///         value
    ///     [ errorcode ]
    /// </summary>
sample return
paraworld.inventory.Test_GetExtendedCost return:
echo:return {
  exname="test_17008_HoneyCrystal_to_17009_BeehiveWorm",
  froms={ { key=17008, value=1 } },
  pres={ { key=17010, value=1 } },
  tos={ { key=17009, value=1 } } 
}
]]
local get_extendedcost_cache_policy = System.localserver.CachePolicies["always"];
paraworld.create_wrapper("paraworld.inventory.GetExtendedCost", "%MAIN%/API/Items/GetExtendedCost.ashx",
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not paraworld.use_game_server) then
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	end	
	-- make sure exid is number
	if(type(msg.exid) == "string") then
		msg.exid = tonumber(msg.exid);
	end
	
	-- cache policy
	local cache_policy = msg.cache_policy or get_extendedcost_cache_policy;
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end
	msg.cache_policy = nil;
	
	-- always get from local server if offline mode
	if(paraworld.OfflineMode) then
		cache_policy = System.localserver.CachePolicies["always"];
	end
	
	local cache_result, unknown_count = paraworld.extendedcost.read_from_cache(msg.exid);
	if(cache_result) then
		if(callbackFunc) then
			callbackFunc(cache_result, callbackParams);
		end
		-- don't require web API call
		return true;
	end

	local HasResult = false;
	local ls = System.localserver.CreateStore(nil, 3, GetExtendedCostDBName());
	if(ls) then
		-- make url
		local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "exid", msg.exid, })
		local item = ls:GetItem(url)
		if(item and item.entry and item.payload) then
			if(not cache_policy:IsExpired(item.payload.creation_date)) then
				-- we found an unexpired result for exid, return the result to callbackFunc
				HasResult = true;
				-- make output msg
				local output_msg = commonlib.LoadTableFromString(item.payload.data);
				-- LOG.std("", "debug","Inventory", "unexpired extended cost template for url:"..url.."");
				--commonlib.echo(output_msg);
				if(output_msg and not output_msg.errorcode) then
					if(callbackFunc) then
						callbackFunc(output_msg, callbackParams);
					end
				end
			end
		end
	end
	if(HasResult == true) then
		-- don't require web API call
		return true;
	else
		LOG.std(nil, "debug", "extendedcost", {"sync unknown extendedcost template", msg.exid});
		
		-- NOTE: remind the editor syncing extendedcost template
		if(commonlib.getfield("System.options.isAB_SDK")) then
			_guihelper.MessageBox(string.format("sync unknown extendedcost template, %s", tostring(msg.exid)));
		end
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	if(type(msg) == "table" and not msg.errorcode) then
		local ls = System.localserver.CreateStore(nil, 3, GetExtendedCostDBName());
		if(ls) then
			-- make output msg
			local output_msg = msg;
			-- make url
			local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "exid", inputMsg.exid, })
			
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
				LOG.std("", "debug","Inventory", "extended cost template info of %s saved to local server", tostring(url));
			else	
				LOG.std("", "warning","Inventory", "failed saving extended cost template info of %s to local server", tostring(url))
				LOG.std("", "warning","Inventory", output_msg);
			end
		end -- if(ls) then
	end
end,
nil,nil, nil,nil, 100000);

-- read the extended cost template in local server
-- @return: extended cost template in table or nil if not valid in local server
function paraworld.inventory.getextendedcostinlocalserver(exid)
	exid = tonumber(exid);
	local url_get = paraworld.inventory.GetExtendedCost.GetUrl();
	local url_get = NPL.EncodeURLQuery(url_get, {"format", 1, "exid", exid, })

	local cache_result = paraworld.extendedcost.read_from_cache(exid);
	if(cache_result) then
		return cache_result;
	end

	local ls = System.localserver.CreateStore(nil, 3, GetExtendedCostDBName());
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

local function GetExtendedCostCacheFile()
	return "Database/"..GetExtendedCostDBName()..".db.mem";
end

function paraworld.extendedcost.read_from_cache(exid)
	if(extendedcost_cache == false) then
		return;
	elseif(extendedcost_cache == nil) then
		local cache = paraworld.extendedcost.LoadFromFile()
		if(cache) then
			extendedcost_cache = cache;
		else
			extendedcost_cache = false;
		end
	end
	if(extendedcost_cache and exid) then
		exid = tonumber(exid);
		return extendedcost_cache[exid];
	end
end

-- @return table of gsid to data map. or false if not found
function paraworld.extendedcost.LoadFromFile(filename)
	filename = filename or GetExtendedCostCacheFile();
	local extendedcost_cache = false;
	local file = ParaIO.open(filename, "r");
	if(file:IsValid()) then
		local count = 0;
		local all_data = NPL.LoadTableFromString(ParaMisc.SimpleDecode(file:GetText()));
		if(all_data) then
			extendedcost_cache = {};
			for i, o in ipairs(all_data) do
				local exid = o[1];
				if(exid) then
					count = count + 1;
					extendedcost_cache[exid] = o;
				else
					LOG.std(nil, "error", "extendedcost", "failed to parse");
				end
			end
		else
			LOG.std(nil, "error", "extendedcost", "failed to parse file %s", filename);
		end
		LOG.std(nil, "info", "extendedcost", "%d items read from %s", count, filename);
		file:close();
	end
	return extendedcost_cache;
end

function paraworld.extendedcost.SaveToFile(filename, templates)
	if(extendedcost_cache) then
		-- no need to save since we have already loaded from cache file
		return;
	end
	filename = filename or GetExtendedCostCacheFile();
	templates = templates or System.Item.ItemManager.ExtendedCostTemplates;
	if(not templates) then
		return;
	end
	local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		local function save_template(exid, template)
			template[1] = tonumber(exid);
			file:WriteString(commonlib.serialize_compact(template));
			file:WriteString(",\r\n");
		end
		local count = 0;
		--save all template
		file:WriteString("{ -- auto generated by paraworld.extendedcost.SaveToFile() \r\n");
		for exid, _ in pairs(templates) do
			paraworld.inventory.GetExtendedCost({exid=tostring(exid)}, "saving",function(msg)
				if(msg) then
					count = count + 1;
					save_template(exid, msg);
				end
			end)
		end
		file:WriteString("}");
		LOG.std(nil, "info", "extendedcost", "%d items saved to %s", count, filename);
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