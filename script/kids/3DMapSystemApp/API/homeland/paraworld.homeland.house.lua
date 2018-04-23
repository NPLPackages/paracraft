--[[
Title: house info 房屋入口
Author(s): Leio
Date: 2009/7/15
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/homeland/paraworld.homeland.house.lua");
local msg = { guids="16", nid=16344 }
paraworld.homeland.house.GetHouseInfo(msg,"house",function(msg)	
		commonlib.echo(msg);
end);
-------------------------------------------------------
]]

-- create class
commonlib.setfield("paraworld.homeland.house", {});
--[[
GetHouseInfo
  /// <summary>
        /// 取得指定用户的指定房屋的数据
        /// 接收参数：
        ///     nid
        ///     guids
        /// 返回值：
			    houses[list]
        ///     [ guid ] 放置到家园后新的GUID
		///     [ level ] 当前级别
		///     [ grownvalue ] 当前成长值
		///     [ update ] 升级到下一级所需的成长值
		///     [ lastclean ] 最后一次清洁时间
		///     [ errorcode ]
        /// </summary>
--]]
paraworld.create_wrapper("paraworld.homeland.house.GetHouseInfo", "%MAIN%/API/House/Get");
--[[
Depurate
         /// <summary>
        /// 对房屋进行清洁
        /// 接收参数：
        ///     nid 被清洁的房屋的所有者的数字ID
        ///     guid 被清洁的房屋在物品中GUID
        /// 返回值：
        ///     issuccess
        ///     [ errorcode ]
        /// </summary>
--]]
paraworld.create_wrapper("paraworld.homeland.house.Depurate", "%MAIN%/API/House/Depurate");
--[[
Grow
 /// <summary>
    /// 将房屋放置到家园中
    /// 接收参数：
    ///     sessionKey
    ///     guid
    ///     bag
    /// 返回值：
    ///     isSuccess
    ///     [ guid ] 放置到家园后新的GUID
    ///     [ level ] 当前级别
    ///     [ grownvalue ] 当前成长值
    ///     [ update ] 升级到下一级所需的成长值
    ///     [ lastclean ] 最后一次清洁时间
    ///     [ errorcode ]
    /// </summary>

--]]
paraworld.create_wrapper("paraworld.homeland.house.Grow", "%MAIN%/API/House/Grow",
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
			-- parse items into guid and count pairs
			local guid = inputMsg.guid;
			local count = 1;
			guid = tonumber(guid);
			count = tonumber(count);
			local sourceItem_gsid;
			-- pass 1: remove the item in the source bag
			local url_getitemsinbag = paraworld.inventory.GetItemsInBag.GetUrl();
			local url = NPL.EncodeURLQuery(url_getitemsinbag, {"format", 1, "bag", inputMsg.bag, "nid", Map3DSystem.User.nid});
			local item = ls:GetItem(url);
			if(item and item.entry and item.payload) then
				local output_msg = commonlib.LoadTableFromString(item.payload.data);
				if(output_msg and output_msg.items) then
					local _, item;
					for _, item in ipairs(output_msg.items) do
						if(item.guid == guid) then
							item.copies = item.copies - count;
							sourceItem_gsid = item.gsid;
							break;
						end
					end
					-- make entry
					local item = {
						entry = System.localserver.WebCacheDB.EntryInfo:new({url = url,}),
						payload = System.localserver.WebCacheDB.PayloadInfo:new({
							status_code = System.localserver.HttpConstants.HTTP_OK,
							data = (output_msg),
						}),
					}
					-- save to database entry
					local res = ls:PutItem(item);
					if(res) then 
						commonlib.log("Source Bag Items of %s updated to local server after house.Grow\n", tostring(url));
					else	
						commonlib.log("warning: failed updating source bag items of %s to local server after house.Grow\n", tostring(url))
						commonlib.log(output_msg);
					end
				end
			end
			if(not sourceItem_gsid) then
				log("error: couldn't find source item gsid in local server cache after house.Grow\n");
				return;
			end
			-- pass 2: append the item in the destination bag
			-- newly created items
			local url_getitemsinbag = paraworld.inventory.GetItemsInBag.GetUrl();
			local url_getitemsinbag = NPL.EncodeURLQuery(url_getitemsinbag, {"format", 1, "bag", 10001, "nid", Map3DSystem.User.nid})
			local item = ls:GetItem(url_getitemsinbag)
			if(item and item.entry and item.payload) then
				local output_msg = commonlib.LoadTableFromString(item.payload.data);
				if(output_msg and output_msg.items) then
					-- add item into bag
					local isExist = false;
					local _, item;
					for _, item in ipairs(output_msg.items) do
						if(item.guid == msg.guid) then
							isExist = true;
							log("error: find plant item already exist in local server after house.Grow\n");
							return;
						end
					end
					if(isExist == false) then
						table.insert(output_msg.items, {
							guid = msg.guid, 
							gsid = sourceItem_gsid,
							obtaintime = ParaGlobal.GetDateFormat("yyyy-MM-dd").." "..ParaGlobal.GetTimeFormat("HH:mm:ss"),
							-- use the local time as the temporary obtain time, "8/3/2009 7:06:43 PM"
							position = msg.position,
							clientdata = inputMsg.clientdata or "",
							serverdata = "",
							copies = count, -- count == 1
						});
					end
					-- make entry
					local item = {
						entry = System.localserver.WebCacheDB.EntryInfo:new({url = url_getitemsinbag,}),
						payload = System.localserver.WebCacheDB.PayloadInfo:new({
							status_code = System.localserver.HttpConstants.HTTP_OK,
							data = (output_msg),
						}),
					}
					-- save to database entry
					local res = ls:PutItem(item);
					if(res) then 
						commonlib.log("Dest Bag Items of %s added to local server after house.Grow\n", tostring(url_getitemsinbag));
					else	
						commonlib.log("warning: failed adding dest bag items of %s to local server after house.Grow\n", tostring(url_getitemsinbag))
						commonlib.log(output_msg);
					end
				end
			end
		end -- if(ls) then
	end
end
);