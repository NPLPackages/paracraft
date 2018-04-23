--[[
Title: querying and managing friends. 
Author(s): LiXizhi, CYF, WangTian
Date: 2008/1/21
NOTE: change all userid to nid, WangTian, 2009/6/30
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/ParaworldAPI.lua");
-------------------------------------------------------
]]

-- create class
commonlib.setfield("paraworld.friends", {});


----[[
--]] 
--paraworld.CreateRPCWrapper("paraworld.friends.areFriends", "http://friends.paraengine.com/areFriends.asmx");




--[[
	/// <summary>
	/// 取得指定用户的所有好友
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		"nid" = string (*)
	///		["pageindex"] = int  显示第几页的数据（以0开始的索引，每页显示20条记录）
	///		["onlyonline"] = int 是否是只获取在线的好友。（0：获取全部好友　1：只获取在线好友，默认值为0）
	///		[order] = int 排序方式。（1：注册时间　2：加入好友时间　3：用户名）
	///		[isinverse] = int 是否是以倒序排序。（0：不是　1：是　默认值为　默认值为0）
	/// }
	/// </param>
	/// <returns>
	/// msg = {
	///		pagecnt = int //共有多少页数据
	///		nids = string //以逗号","分隔的好友用户数字ID集合
	///		errorcode = int  错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除  495：索引走出界限
	///		[ "info" ] = string 发生时有此节点
	/// }
	/// </returns>
	-- LXZ Done: we allow a person to have thousands of friends. In that case the input should have a page number or max result returned, and the return 
	-- value should return whether there are more records to be retrieved. 
]] 
-- the local server will cache each result.
local friends_get_cache_policy = System.localserver.CachePolicy:new("access plus 1 day");
local friends_get_online_cache_policy = System.localserver.CachePolicy:new("access plus 10 minutes");
paraworld.create_wrapper("paraworld.friends.get", "%MAIN%/API/Friends/Get.ashx",
function(self, msg, id, callbackFunc, callbackParams, postMsgTranslator) 
	if(not paraworld.use_game_server) then
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	end	
	msg.nid = msg.nid or Map3DSystem.User.nid;
	
	local cache_policy;
	if(msg.onlyonline == 1) then
		cache_policy = msg.cache_policy or friends_get_online_cache_policy;
	else	
		cache_policy = msg.cache_policy or friends_get_cache_policy;
	end
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy)
	end
	msg.cache_policy = nil;
	
	local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return;
	end
	
	-- if local server has an unexpired result, remove the uid from msg.uid and return the result to callbackFunc otherwise, continue. 
	local HasResult;
	-- make url
	local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "nid", msg.nid, "pageindex", msg.pageindex, "onlyonline", msg.onlyonline, "order", msg.order, "isinverse", msg.isinverse})
	local item = ls:GetItem(url);
	if(item and item.entry and item.payload) then
		if(not cache_policy:IsExpired(item.payload.creation_date)) then
			-- we found an unexpired result for gsid, return the result to callbackFunc
			HasResult = true;
			LOG.std("", "debug", "API", "unexpired local version for : %s", url)
			-- make output msg
			local output_msg = commonlib.LoadTableFromString(item.payload.data);
			
			if(callbackFunc) then
				callbackFunc(output_msg, callbackParams)
			end	
		end
	end
	if(HasResult) then
		-- don't require web API call
		return true;
	end	
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	if(type(msg) == "table" and msg.nids) then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			-- make output msg
			local output_msg = msg;
			-- make url
			local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "nid", inputMsg.nid, "pageindex", inputMsg.pageindex, "onlyonline", inputMsg.onlyonline, "order", inputMsg.order, "isinverse", inputMsg.isinverse})
			
			-- make entry
			local item = {
				entry = System.localserver.WebCacheDB.EntryInfo:new({
					url = url,
				}),
				payload = System.localserver.WebCacheDB.PayloadInfo:new({
					status_code = System.localserver.HttpConstants.HTTP_OK,
					data = commonlib.serialize_compact(output_msg),
				}),
			}
			-- save to database entry
			local res = ls:PutItem(item);
			if(res) then 
				LOG.std("", "debug", "API", {url, inputMsg, msg, })
			else	
				LOG.std("", "warn", "API", "failed saving friends to local server: url %s", tostring(url))
			end
		end
	end
end);


--[[
	/// <summary>
	/// 登录用户新增一条好友记录
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		"sessionkey" = string (*) 当前登录用户的用户凭证
	///		"friendnid" = string () 好友的用户数字ID
	/// }
	/// </param>
	/// <returns>
	/// msg = {
	///		"issuccess" = boolean 操作是否成功
	///		"state" = int 状态。 1：双方已成为好友。 2：已向对方发送了好友请求。 3：对方已是您的好友，不必重复请求
	///		[ errorcode ] = int  错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除
	///		[ "info" ] = string 发生错误或非法访问时有此节点
	/// }
	/// </returns>
]] 
paraworld.create_wrapper("paraworld.friends.add", "%MAIN%/API/Friends/Add.ashx", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not paraworld.use_game_server) then
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	if(msg.issuccess == true and (msg.state == 1 or msg.state == 3)) then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			-- the following is a standard input for Aries friends get:
			--pageindex = -1,
			--onlyonline = 0,
			--order = 3,
			--isinverse = 0,
			-- NOTE: pageindex = -1, will fetch all friends
			local url_friends_get = paraworld.friends.get.GetUrl();
			url_friends_get = NPL.EncodeURLQuery(url_friends_get, {"format", 1, "nid", Map3DSystem.User.nid, "pageindex", -1, "onlyonline", 0, "order", 3, "isinverse", 0});
			
			local item = ls:GetItem(url_friends_get)
			if(item and item.entry and item.payload) then
				local output_msg_ls = commonlib.LoadTableFromString(item.payload.data);
				if(output_msg_ls and output_msg_ls.nids) then
					-- check if the friend nid exists in the local server
					local bExist = false;
					local nid;
					for nid in string.gfind(output_msg_ls.nids, "([^,]+)") do 
						if(tostring(inputMsg.friendnid) == nid) then
							bExist = true;
							break;
						end
					end
					-- make the new nids
					if(bExist == false) then
						output_msg_ls.nids = inputMsg.friendnid..","..output_msg_ls.nids;
					end
					-- make entry
					local item = {
						entry = System.localserver.WebCacheDB.EntryInfo:new({url = url_friends_get,}),
						payload = System.localserver.WebCacheDB.PayloadInfo:new({
							status_code = System.localserver.HttpConstants.HTTP_OK,
							data = commonlib.serialize_compact(output_msg_ls),
						}),
					}
					-- save to database entry
					local res = ls:PutItem(item);
					if(res) then
						LOG.std("", "debug", "API", "Friend list of %s updated to local server after friends.add", tostring(url_friends_get));
					else
						LOG.std("", "debug", "API", "warning: failed updating friend list of %s to local server after friends.add", tostring(url_friends_get));
						LOG.std("", "debug", "API", output_msg_ls);
					end
				end
			end
		end -- if(ls) then
	end
end
);

--[[
	/// <summary>
	/// 当前登录用户将一个好友移除，同时也会在被移除的好友列表中将当前登录用户移除
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		"sessionkey" = string (*) 用户凭证
	///		"friendnid" = string () 好友的数字ID
	/// }
	/// </param>
	/// <returns>
	/// msg = {
	///		"issuccess" = boolean 操作是否成功
	///		[ errorcode ] = int  错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除
	///		[ "info" ] = string 发生错误或非法访问时有此节点
	/// }
]] 
paraworld.create_wrapper("paraworld.friends.remove", "%MAIN%/API/Friends/Remove.ashx", 
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
			-- the following is a standard input for Aries friends get:
			--pageindex = -1,
			--onlyonline = 0,
			--order = 3,
			--isinverse = 0,
			-- NOTE: pageindex = -1, will fetch all friends
			local url_friends_get = paraworld.friends.get.GetUrl();
			url_friends_get = NPL.EncodeURLQuery(url_friends_get, {"format", 1, "nid", Map3DSystem.User.nid, "pageindex", -1, "onlyonline", 0, "order", 3, "isinverse", 0});
			
			local item = ls:GetItem(url_friends_get)
			if(item and item.entry and item.payload) then
				local output_msg_ls = commonlib.LoadTableFromString(item.payload.data);
				if(output_msg_ls and output_msg_ls.nids) then
					-- check if the friend nid exists in the local server
					local bExist = false;
					local nid;
					local new_nids = "";
					for nid in string.gfind(output_msg_ls.nids, "([^,]+)") do 
						if(tostring(inputMsg.friendnid) == nid) then
							bExist = true;
						else
							new_nids = new_nids..nid..","; -- append the nids
						end
					end
					-- make the new nids
					output_msg_ls.nids = new_nids;
					-- make entry
					local item = {
						entry = System.localserver.WebCacheDB.EntryInfo:new({url = url_friends_get,}),
						payload = System.localserver.WebCacheDB.PayloadInfo:new({
							status_code = System.localserver.HttpConstants.HTTP_OK,
							data = commonlib.serialize_compact(output_msg_ls),
						}),
					}
					-- save to database entry
					local res = ls:PutItem(item);
					if(res) then
						LOG.std("", "debug", "API", "Friend list of %s updated to local server after friends.remove", tostring(url_friends_get));
					else
						LOG.std("", "debug", "API", "warning: failed updating friend list of %s to local server after friends.remove", tostring(url_friends_get));
						LOG.std("", "debug", "API", output_msg_ls);
					end
				end
			end
		end -- if(ls) then
	end
end
);

