--[[
Title: vip related api
Author(s): andy
Date: 2010.3.9
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.VIP.lua");
-------------------------------------------------------
]]
-- create class
commonlib.setfield("paraworld.VIP", {});

local isLogVIPTraffic = true;

--[[
UseItem
        /// <summary>
        /// 将指定的物品应用到指定的宠物身上 （VIP应用）
        /// 接收参数：
        ///     curNID 当前登录用户的数字ID
        ///     nid 宠物所有者的数字ID
        ///     petID 宠物GUID
        ///     itemGUID 使用的物品的GUID
        ///     bag
        /// 返回值：
        ///     issuccess
        ///     level 级别
        ///     friendliness 亲密度
        ///     nextlevelfr 长级到下一级所需的亲密度
        ///     health 健康状态
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
paraworld.create_wrapper("paraworld.VIP.UseItemVIP", "%MAIN%/API/Pet/UseItemVIP.ashx", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not paraworld.use_game_server) then
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	end	
	if(isLogVIPTraffic) then
		LOG.std("", "debug","VIP", "paraworld.VIP.UseItemVIP msg_in:");
		LOG.std("", "debug","VIP", msg);
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	if(msg.issuccess == true) then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			-- pass 1: update the items in bag
			if(msg.updates) then
				local _, update;
				for _, update in ipairs(msg.updates) do
					-- stack to existing items
					local url_getitemsinbag = paraworld.inventory.GetItemsInBag.GetUrl();
					local url_getitemsinbag = NPL.EncodeURLQuery(url_getitemsinbag, {"format", 1, "bag", update.bag, "nid", Map3DSystem.User.nid})
					local item = ls:GetItem(url_getitemsinbag)
					if(item and item.entry and item.payload) then
						local output_msg = commonlib.LoadTableFromString(item.payload.data);
						if(output_msg and output_msg.items) then
							-- update the copies
							local _, item;
							for _, item in ipairs(output_msg.items) do
								if(item.guid == update.guid) then
									output_msg.items[_].copies = output_msg.items[_].copies + update.cnt;
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
								LOG.std("", "debug","VIP", "Bag Items of %s updated to local server after UseItemVIP", tostring(url_getitemsinbag));
							else	
								LOG.std("", "warning","VIP", "failed updating bag items of %s to local server after UseItemVIP", tostring(url_getitemsinbag))
								LOG.std("", "warning","VIP", output_msg);
							end
						end
					end
				end
			end
			-- TODO: adds part is not testes in the current implementation
			if(msg.adds) then
				local _, add;
				for _, add in ipairs(msg.adds) do
					-- newly created items
					local url_getitemsinbag = paraworld.inventory.GetItemsInBag.GetUrl();
					local url_getitemsinbag = NPL.EncodeURLQuery(url_getitemsinbag, {"format", 1, "bag", add.bag, "nid", Map3DSystem.User.nid})
					local item = ls:GetItem(url_getitemsinbag)
					if(item and item.entry and item.payload) then
						local output_msg = commonlib.LoadTableFromString(item.payload.data);
						if(output_msg and output_msg.items) then
							table.insert(output_msg.items, {
								guid = add.guid, 
								gsid = add.gsid,
								obtaintime = ParaGlobal.GetDateFormat("yyyy-MM-dd").." "..ParaGlobal.GetTimeFormat("HH:mm:ss"),
								-- use the local time as the temporary obtain time, "8/3/2009 7:06:43 PM"
								position = add.position,
								clientdata = "",
								serverdata = "",
								copies = add.cnt,
							});
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
								LOG.std("", "debug","VIP", "Bag Items of %s added to local server after UseItemVIP", tostring(url_getitemsinbag));
							else	
								LOG.std("", "warning","VIP", "failed adding bag items of %s to local server after UseItemVIP", tostring(url_getitemsinbag))
								LOG.std("", "warning","VIP", output_msg);
							end
						end
					end
				end
			end
		end -- if(ls) then
	end
	
	if(isLogVIPTraffic) then
		LOG.std("", "debug","VIP", "paraworld.VIP.UseItemVIP msg_out:");
		LOG.std("", "debug","VIP", msg);
	end
end
);