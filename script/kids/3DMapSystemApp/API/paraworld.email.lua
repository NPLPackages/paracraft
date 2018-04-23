--[[
Title: sending game emails
Author(s): LiXizhi
Date: 2009/1/23
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/ParaworldAPI.lua");
-------------------------------------------------------
]]
-- create class
commonlib.setfield("paraworld.email", {});

--[[
/// <summary>
/// 发送邮件（非传统意义上Email，指游戏内部的邮件）
/// 接收参数：
///     sessionkey
///     tonid 接收人的NID
///     title 标题
///     content 内容
///     attaches 附件。guid,cnt|guid,cnt|guid,cnt|.....。guid==0:E币；guid==-1:P币
/// 返回值：
///     issuccess
///     [ errorcode ] 493:参数不正确 419:用户不存在 427:物品不足 426:太频繁 433:邮箱已满
/// </summary>
]]
paraworld.create_wrapper("paraworld.email.send", "%MAIN%/API/Email/Send",
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not paraworld.use_game_server) then
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	end	
	if(msg.title and #(msg.title) > 128) then
		msg.title = string.sub(msg.title, 1, 128)
	end
	if(msg.content and #(msg.content) > 512) then
		msg.content = string.sub(msg.content, 1, 512)
	end
	if(msg.attaches and #(msg.attaches) > 0) then
		msg.log2db = 1;
		-- TODO: translate to gsid,cnt|
		msg.logremark = msg.attaches;
	end
	LOG.std("", "debug","email", "send");
	LOG.std("", "debug","email", msg);
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	LOG.std("", "debug","email", "send reply");
	LOG.std("", "debug","email", msg);
	if(msg and msg.issuccess)then
		local ups = msg.ups or msg.updates; 
		-- tricky:if there is no updates in msg, we will emulate one. 
		if(not ups and inputMsg.attaches and inputMsg.attaches~="") then
			local guid, count
			for guid, count in inputMsg.attaches:gmatch("(%d+),(%d+)|") do
				count = tonumber(count);
				guid = tonumber(guid);
				local item = Map3DSystem.Item.ItemManager.GetItemByGUID(guid);
				if(item.copies and item.copies >= count) then
					ups = ups or {};
					ups[#ups+1] = {
						gsid = item.gsid,
						guid = guid,
						copies = item.copies - count,
					}
				end
			end
		end
		if(ups) then
			Map3DSystem.Item.ItemManager.UpdateBagItems(ups);
		end
	end
end
);

--[[
/// <summary>
/// 读取指定的邮件
/// 接收参数：
///     sessionkey
///     eid 邮件编号
/// 返回值：
///     from 发件人的NID
///     title 标题
///     content 正文
///     isread 是否已读，0：未读；1：已读
///     isgetattach 是否已提取附件。0:否；1:是
///     attaches [ list ] 附件列表
///         gsid 物品GSID
///         cnt 数量
///         c clientdata数据
///         s serverdata数据
///     cdate  收到邮件的时间。yyyy-MM-dd HH:mm:ss
///     [ errorcode ] 497:邮件不存在
/// </summary>
]]
paraworld.create_wrapper("paraworld.email.read", "%MAIN%/API/Email/Read",
-- pre validation function and use default inputs
function(self, msg, id, callbackFunc, callbackParams, postMsgTranslator) 
	if(not paraworld.use_game_server) then
		msg.sessionkey = Map3DSystem.User.sessionkey;
	end	
	local cache_policy = msg.cache_policy or "access plus 1 day";
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end
	msg.cache_policy = nil;

	if(cache_policy == nil) then
		return;
	end
	
	local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return 
	end

	-- make url
	local url = NPL.EncodeURLQuery(self.GetUrl(), {"eid", msg.eid, })
	local item = ls:GetItem(url)
	if(item and item.entry and item.payload) then
		if(not cache_policy:IsExpired(item.payload.creation_date)) then
			-- make output msg
			if(item.payload.data) then
				local output_msg = commonlib.LoadTableFromString(item.payload.data);
				if(output_msg) then
					if(callbackFunc) then
						callbackFunc(output_msg, callbackParams);
					end
					LOG.std(nil, "debug", "email", "unexpired data used for %s", url);
					return true;
				end
			end
		end
	end
end,
-- Post Processor
function (self, msg, id,callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	if(type(msg) == "table") then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			-- make input msg
			local url = NPL.EncodeURLQuery(self.GetUrl(), {"eid", inputMsg.eid })
			-- make entry
			local item = {
				entry = System.localserver.WebCacheDB.EntryInfo:new({
					url = url,
				}),
				payload = System.localserver.WebCacheDB.PayloadInfo:new({
					status_code = System.localserver.HttpConstants.HTTP_OK,
					data = msg,
				}),
			}
			-- save to database entry
			local res = ls:PutItem(item) 
			if(res) then 
				LOG.std(nil, "debug", "email", "data saved to ls for %s", url);
			else	
				LOG.std(nil, "error", "email", "data failed to save to ls for %s", url);
			end
		end
	end
end);

--[[
/// <summary>
/// 收取指定邮件中的附件
/// 接收参数：
///     sessionkey
///     eid 邮件编号
/// 返回值：
///     issuccess
///     [ adds ]
///         guid
///         gsid
///         cnt
///         bag
///         pos
///         clientdata
///         serverdata
///     [ ups ]
///         guid
///         cnt
///     [ errorcode ] 419:用户不存在 497:邮件不存在 417:附件已被提取过 423:没有附件 433:物品数量太多了 494:解析附件数据时异常
/// </summary>
]]
paraworld.create_wrapper("paraworld.email.getattach", "%MAIN%/API/Email/GetAttach",
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not paraworld.use_game_server) then
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	end	
	LOG.std("", "debug","email", "getattach");
	LOG.std("", "debug","email", msg);
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	LOG.std("", "debug","email", "getattach reply");
	LOG.std("", "debug","email", msg);
	if(msg and msg.issuccess) then
		
		-- tricky:code, replace .cnt with .copies, since it means the actual copies, not the increment count.  
		if(msg.ups) then
			local _, update 
			for _, update in ipairs(msg.ups) do
				if(update.cnt) then
					update.copies = update.cnt;
					update.cnt = nil;
				end
			end
		end
		Map3DSystem.Item.ItemManager.UpdateBagItems(msg.ups, msg.adds);
	end
end
);

--[[
	/// <summary>
	/// 删除指定的邮件
	/// 接收参数：
	///     sessionkey
	///     eid 邮件编号
	/// 返回值：
	///     issuccess
	/// </summary>
]]
paraworld.create_wrapper("paraworld.email.delete", "%MAIN%/API/Email/Delete",
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not paraworld.use_game_server) then
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	end	
	LOG.std("", "debug","email", "delete");
	LOG.std("", "debug","email", msg);
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	LOG.std("", "debug","email", "delete reply");
	LOG.std("", "debug","email", msg);
end
);


--[[
    /// <summary>
    /// 取得指定用户的邮件列表，分页
    /// 接收参数：
    ///     nid
    ///     pindex 页码，从0开始
    ///     psize  每页的数据量
    /// 返回值：
    ///     pcnt 共有多少页
    ///     list [ list ]
    ///         eid  邮件编号
    ///         from  发件人的NID
    ///         title  标题
    ///         isread 是否已读，0：未读；1：已读
    ///         isgetattach 是否已提取附件。0:否；1:是
    ///         cdate  收到邮件的时间。yyyy-MM-dd HH:mm:ss
    /// </summary>
]]
paraworld.create_wrapper("paraworld.email.getofpage", "%MAIN%/API/Email/GetOfPage",
-- pre validation function and use default inputs
function(self, msg, id, callbackFunc, callbackParams, postMsgTranslator) 
	if(not paraworld.use_game_server) then
		msg.sessionkey = Map3DSystem.User.sessionkey;
	end	
	local cache_policy = msg.cache_policy or "access plus 1 minute";
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end
	msg.cache_policy = nil;

	if(cache_policy == nil) then
		return;
	end
	
	local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return 
	end

	-- make url
	local url = NPL.EncodeURLQuery(self.GetUrl(), {"nid", msg.nid, "pindex", msg.pindex, "psize", msg.psize})
	local item = ls:GetItem(url)
	if(item and item.entry and item.payload) then
		if(not cache_policy:IsExpired(item.payload.creation_date)) then
			-- make output msg
			if(item.payload.data) then
				local output_msg = commonlib.LoadTableFromString(item.payload.data);
				if(output_msg) then
					if(callbackFunc) then
						callbackFunc(output_msg, callbackParams);
					end
					LOG.std(nil, "debug", "email", "unexpired data used for %s", url);
					return true;
				end
			end
		end
	end
	LOG.std(nil, "debug", "email", "checking email for %s", url);
end,
-- Post Processor
function (self, msg, id,callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	if(type(msg) == "table") then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			-- make input msg
			local url = NPL.EncodeURLQuery(self.GetUrl(), {"nid", inputMsg.nid, "pindex", inputMsg.pindex, "psize", inputMsg.psize})
			-- make entry
			local item = {
				entry = System.localserver.WebCacheDB.EntryInfo:new({
					url = url,
				}),
				payload = System.localserver.WebCacheDB.PayloadInfo:new({
					status_code = System.localserver.HttpConstants.HTTP_OK,
					data = msg,
				}),
			}
			-- save to database entry
			local res = ls:PutItem(item) 
			if(res) then 
				LOG.std(nil, "debug", "email", "data saved to ls for %s", url);
			else	
				LOG.std(nil, "error", "email", "data failed to save to ls for %s", url);
			end
		end
	end
end);