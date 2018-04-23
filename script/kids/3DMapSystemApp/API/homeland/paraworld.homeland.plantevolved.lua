--[[
Title: plantevolved info
Author(s): Leio
Date: 2009/4/24
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/homeland/paraworld.homeland.plantevolved.lua");
-------------------------------------------------------
]]

-- create class
commonlib.setfield("paraworld.homeland.plantevolved", {});
----------------------------------------------------------------------------------------------
--[[
    KM_Plant.API.Grow
	/// <summary>
    /// 种植植物
    /// 接收参数：
    ///     sessionKey
    ///     guid 该植物的物品ID
    ///     bag 该植物的物品当前所在的包
    /// 返回值：
    ///     issuccess
    ///     [ errorcode ]
    /// </summary>

--]]
paraworld.create_wrapper("paraworld.homeland.plantevolved.Grow", "%MAIN%/API/Plant/Grow.ashx",
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
							data = commonlib.serialize_compact(output_msg),
						}),
					}
					-- save to database entry
					local res = ls:PutItem(item);
					if(res) then 
						commonlib.log("Source Bag Items of %s updated to local server after plantevolved.Grow\n", tostring(url));
					else	
						commonlib.log("warning: failed updating source bag items of %s to local server after plantevolved.Grow\n", tostring(url))
						commonlib.log(output_msg);
					end
				end
			end
			if(not sourceItem_gsid) then
				log("error: couldn't find source item gsid in local server cache after plantevolved.Grow\n");
				return;
			end
			-- pass 2: append the item in the destination bag
			-- newly created items
			local url_getitemsinbag = paraworld.inventory.GetItemsInBag.GetUrl();
			local url_getitemsinbag = NPL.EncodeURLQuery(url_getitemsinbag, {"format", 1, "bag", msg.bag, "nid", Map3DSystem.User.nid})
			local item = ls:GetItem(url_getitemsinbag)
			if(item and item.entry and item.payload) then
				local output_msg = commonlib.LoadTableFromString(item.payload.data);
				if(output_msg and output_msg.items) then
					-- add item into bag
					local isExist = false;
					local _, item;
					for _, item in ipairs(output_msg.items) do
						if(item.guid == msg.id) then
							isExist = true;
							log("error: find plant item already exist in local server after plantevolved.Grow\n");
							return;
						end
					end
					if(isExist == false) then
						table.insert(output_msg.items, {
							guid = msg.id, 
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
							data = commonlib.serialize_compact(output_msg),
						}),
					}
					-- save to database entry
					local res = ls:PutItem(item);
					if(res) then 
						commonlib.log("Dest Bag Items of %s added to local server after plantevolved.Grow\n", tostring(url_getitemsinbag));
					else	
						commonlib.log("warning: failed adding dest bag items of %s to local server after plantevolved.Grow\n", tostring(url_getitemsinbag))
						commonlib.log(output_msg);
					end
				end
			end
		end -- if(ls) then
	end
end
);

--[[
GetAllDescriptors
    KM_Plant.API.GetByIDs
	/// <summary>
	/// 依据一组植物实例的ID取得相应的实例的数据
	/// 接收参数：
	/// nid：植物所有者的数字ID
	/// ids：植物实例的ID，多个ID之间用英文逗号分隔
	/// 返回值：
	/// items[list]
	/// id：唯一标识
	/// level：当前级别
	//  totallevel:总级别，以下都是
	/// isdroughted：是否处于干旱状态
	/// isbuged：是否处于虫害状态
	/// allowremove：是否允许当前用户铲除该植物
	/// feedscnt：果实数量
	/// grownvalue：当前成长值
	/// update：升级到下一级别所需要的成长值
	/// allowgaincnt:剩余的可收获的次数
	/// </summary> 
--]]
paraworld.create_wrapper("paraworld.homeland.plantevolved.GetAllDescriptors", "%MAIN%/API/Plant/GetByIDs.ashx");

--[[
Water
    KM_Plant.API.Water 
	/// <summary>
	/// 给指定的植物浇水
	/// 接收参数：
	/// nid：植物所有者的数字ID
	/// id：指定的植物的ID
	/// 返回值：
	/// issuccess
	/// [ id ]：标识
	/// [ level ]：当前级别
	/// [ isdroughted ]：是否处于干旱状态
	/// [ isbuged ]：是否处于虫害状态
	/// [ allowremove ]：是否允许当前用户铲除该植物
	/// [ feedscnt ]：果实数量
	/// [ grownvalue ]：当前成长值
	/// [ update ]：升级到下一级别所需要的成长值
	/// allowgaincnt:剩余的可收获的次数
	/// [ errorCode ]
	/// </summary> 


--]]
paraworld.create_wrapper("paraworld.homeland.plantevolved.Water", "%MAIN%/API/Plant/Water.ashx");

--[[
Debug
   KM_Plant.API.Debug
    /// <summary>
        /// 给指定的植物除虫
        /// 接收参数：
        ///     nid：植物的所有者的用户数字ID
        ///     [ id ]：指定的植物的ID
        ///     [ ids ]：被除虫植物的ID，多个ID之间用英文逗号分隔，若存在ids参数，则忽略id参数
        /// 返回值：
        ///     若不存在ids参数，存在id参数
        ///         issuccess
        ///         [ id ]：唯一标识
        ///         [ level ]：当前级别
        ///         [ isdroughted ]：是否处于干旱状态
        ///         [ isbuged ]：是否处于虫害状态
        ///         [ allowremove ]：是否允许当前用户铲除该植物
        ///         [ feedscnt ]：果实数量
        ///         [ grownvalue ]：当前成长值
        ///         [ update ]：升级到下一级别所需要的成长值
        ///         [ allowgaincnt ]：剩余的可收获次数
        ///         [ totallevel ] 总共有多少级
        ///         [ updatetime ] 距升级到下一级还需的分钟数
        ///         [ gaintime ] 距收获还需的分钟数
        ///         [ errorcode ]
        ///     若存在ids参数
        ///         issuccess
        ///         [ list ][list]
        ///             id：唯一标识
        ///             level：当前级别
        ///             isdroughted：是否处于干旱状态
        ///             isbuged：是否处于虫害状态
        ///             allowremove：是否允许当前用户铲除该植物
        ///             feedscnt：果实数量
        ///             grownvalue：当前成长值
        ///             update：升级到下一级别所需要的成长值
        ///             allowgaincnt：剩余的可收获次数
        ///             totallevel： 总共有多少级
        ///             updatetime： 距升级到下一级还需的分钟数
        ///             gaintime： 距收获还需的分钟数
        ///         [ errorcode ]
        /// </summary>

--]]
paraworld.create_wrapper("paraworld.homeland.plantevolved.Debug", "%MAIN%/API/Plant/Debug");

--[[
GainFeeds
    KM_Plant.API.GainFeeds
/// <summary>
        /// 采摘指定植物的果实
        /// 接收参数：
        ///     sessionkey：当前采摘用户的sessionKey
        ///     [ id ]：被采摘植物的ID
        ///     [ ids ]：被采摘植物的ID，多个ID之间用英文逗号分隔，若存在ids参数，则忽略id参数
        /// 返回值：
        ///     若不存在ids参数，存在id参数
        ///         issuccess
        ///         [ id ]：唯一标识
        ///         [ level ]：当前级别
        ///         [ isdroughted ]：是否处于干旱状态
        ///         [ isbuged ]：是否处于虫害状态
        ///         [ allowremove ]：是否允许当前用户铲除该植物
        ///         [ feedscnt ]：果实数量
        ///         [ grownvalue ]：当前成长值
        ///         [ update ]：升级到下一级别所需要的成长值
        ///         [ allowgaincnt ]：剩余的可收获次数
        ///         [ totallevel ] 总共有多少级
        ///         [ updatetime ] 距升级到下一级还需的分钟数
        ///         [ gaintime ] 距收获还需的分钟数
        ///         [ errorcode ]
        ///     若存在ids参数
        ///         issuccess
        ///         [ list ][list]
        ///             id：唯一标识
        ///             level：当前级别
        ///             isdroughted：是否处于干旱状态
        ///             isbuged：是否处于虫害状态
        ///             allowremove：是否允许当前用户铲除该植物
        ///             feedscnt：果实数量
        ///             grownvalue：当前成长值
        ///             update：升级到下一级别所需要的成长值
        ///             allowgaincnt：剩余的可收获次数
        ///             totallevel： 总共有多少级
        ///             updatetime： 距升级到下一级还需的分钟数
        ///             gaintime： 距收获还需的分钟数
        ///         [ errorcode ]
        /// </summary>

    
--]]
paraworld.create_wrapper("paraworld.homeland.plantevolved.GainFruits", "%MAIN%/API/Plant/GainFeeds",paraworld.prepLoginRequried);

--[[
Delete
   KM_Plant.API.Remove
    /// <summary>
    /// 铲除指定的植物
    /// 接收参数：
    ///     sessionkey：当前登录用户的用户凭证
    ///     id：被铲除的植物的ID
    /// 返回值：
    ///     issuccess
    ///     [ errorcode ]
    /// </summary>
--]]  
paraworld.create_wrapper("paraworld.homeland.plantevolved.Remove", "%MAIN%/API/Plant/Remove.ashx",
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not paraworld.use_game_server) then
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	end
	msg.bag = nil; -- remove local server optimization field
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(msg.issuccess == true) then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			-- parse items into guid and count pairs
			local guid = inputMsg.id;
			local count = 1;
			guid = tonumber(guid);
			count = tonumber(count);
			-- pass 1: remove the item in the source bag
			local url_getitemsinbag = paraworld.inventory.GetItemsInBag.GetUrl();
			local url = NPL.EncodeURLQuery(url_getitemsinbag, {"format", 1, "bag", originalMsg.bag, "nid", Map3DSystem.User.nid});
			local item = ls:GetItem(url);
			if(item and item.entry and item.payload) then
				local output_msg = commonlib.LoadTableFromString(item.payload.data);
				if(output_msg and output_msg.items) then
					local _, item;
					for _, item in ipairs(output_msg.items) do
						if(item.guid == guid) then
							item.copies = item.copies - count;
							break;
						end
					end
					-- make entry
					local item = {
						entry = System.localserver.WebCacheDB.EntryInfo:new({url = url,}),
						payload = System.localserver.WebCacheDB.PayloadInfo:new({
							status_code = System.localserver.HttpConstants.HTTP_OK,
							data = commonlib.serialize_compact(output_msg),
						}),
					}
					-- save to database entry
					local res = ls:PutItem(item);
					if(res) then 
						commonlib.log("Bag Items of %s updated to local server after plantevolved.Remove\n", tostring(url));
					else	
						commonlib.log("warning: failed updating bag items of %s to local server after plantevolved.Remove\n", tostring(url))
						commonlib.log(output_msg);
					end
				end
			end
		end -- if(ls) then
	end
end
);
--[[
  [host]/API/Plant/WaterPlants         /// <summary>
    /// 给指定的一组植物浇水
    /// 接收参数：
    ///     nid  植物所有者的NID
    ///     ids  指定的一组植物的ID，多个ID之间用英文逗号分隔
    /// 返回值：
    ///     issuccess
    ///     list [list]
    ///         [ id ]：唯一标识
    ///         [ level ]：当前级别
    ///         [ isDroughted ]：是否处于干旱状态
    ///         [ isBuged ]：是否处于虫害状态
    ///         [ feedsCnt ]：果实数量
    ///         [ grownValue ]：当前成长值
    ///         [ update ]：升级到下一级别所需要的成长值
    ///         [ allowgaincnt ]：剩余的可收获次数
    ///         [ totallevel ] 总共有多少级
    ///         [ updatetime ] 距升级到下一级还需的分钟数
    ///         [ gaintime ] 距收获还需的分钟数
    ///     [ errorcode ]
    /// </summary>
--]]
paraworld.create_wrapper("paraworld.homeland.plantevolved.WaterPlants", "%MAIN%/API/Plant/WaterPlants.ashx")

--测试加速成长
--[[
    KM_Plant.API.GoGoGo
	/// <summary>
    /// 加速成长
    /// 接收参数：
    ///     nid
    ///     plantInstanceID 
    ///     h 
    /// 返回值：
    ///     issuccess
    ///     [ errorcode ]
    /// </summary>

--]]
paraworld.create_wrapper("paraworld.homeland.plantevolved.GoGoGo", "%MAIN%/API/Plant/GoGoGo.ashx")


