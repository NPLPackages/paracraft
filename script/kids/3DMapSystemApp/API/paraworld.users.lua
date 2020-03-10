--[[
Title: user info
Author(s): LiXizhi, WangTian
Date: 2008/1/21
NOTE: change all userid to nid, WangTian, 2009/6/30
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/ParaworldAPI.lua");
-------------------------------------------------------
]]
local LOG = LOG;
-- create class
commonlib.setfield("paraworld.users", {});

--[[
        /// <summary>
        /// 获取一组指定用户的信息
        /// 接收参数：
        ///     "nids" = string //用逗号（,）分隔的多个用户数字ID
        ///   返回值：
        ///       users [list]：
        ///          nid
        ///          nickname  昵称
        ///          pmoney  P币
        ///          emoney  E币（奇豆）
        ///          birthday  生日（首次进入哈奇的时间）
        ///          popularity  人气值
        ///          family  所属家族的名称
        ///          introducer  推荐人的NID
        ///          -------  若该用户没有抱抱龙，则不会有此节点  ----------------
        ///          energy  魔法星能量值
        ///          mlel  魔法星等级
        ///       [ errorCode ]：错误码，发生异常时有此节点
        /// </summary>

	paraworld.users.getInfo({nids="001,002,003"}, "test", function(msg)
		log(commonlib.serialize(msg));
	end);
	paraworld.users.getInfo({uids="813b07e0-7897-4359-aa1f-4b64dc4f20f0"}, "test", function(msg)
		log(commonlib.serialize(msg));
	end);
]] 
-- getinfo with modified preprocessor and postprocessor and local server cache policy
-- @note: if msg.fields is nil, local server is not used, so always specify fields. 
-- @note2: FOR LOCAL SERVER TO WORK PROPERLY, ALWAYS INCLUDE "userid,nid" in msg.fields 
--local getInfo_cache_policy = System.localserver.CachePolicy:new("access plus 1 week");
local getInfo_cache_policy = System.localserver.CachePolicy:new("access plus 1 day");
paraworld.create_wrapper("paraworld.users.getInfo", "%MAIN%/API/Users/GetInfo.ashx",
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not paraworld.use_game_server) then
		msg.sessionkey = Map3DSystem.User.sessionkey;
	end	
	msg.userid = msg.userid or Map3DSystem.User.userid;

	-- this if from paraworld.homeland.petevolved.Get
	if(msg.nid and not msg.nids) then
		msg.nids = msg.nid;
	end
	
	local cache_policy = msg.cache_policy or getInfo_cache_policy;
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end
	msg.cache_policy = nil;
	
	if(paraworld.OfflineMode) then
		cache_policy = System.localserver.CachePolicies["always"];
	end
	
	-- this field is specified for local server to work properly for both versions of API
	msg.fields = "userid,nid,nickname,pmoney,emoney,birthday,popularity,family";
	
	if(cache_policy==nil) then
		return;
	end
	
	local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return 
	end
	
	msg.fields = string.lower(commonlib.Encoding.SortCSVString(msg.fields));
	
	if(msg.uids) then
		local uid;
		local unknown_uids = nil;
		for uid in string.gfind(msg.uids, "([^,]+)") do
			-- if local server has an unexpired result, remove the uid from msg.uid and return the result to callbackFunc
			-- otherwise, continue. 
			local HasResult;
			-- make input msg
			local input_msg = {
				uids = tostring(uid),
				fields = msg.fields,
			};
			-- make url
			local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "uids", uid, "fields", msg.fields, })
			local item = ls:GetItem(url)
			if(item and item.entry and item.payload) then
				if(not cache_policy:IsExpired(item.payload.creation_date)) then
					-- we found an unexpired result for uid, return the result to callbackFunc
					HasResult = true	
					-- make output msg
					local output_msg = commonlib.LoadTableFromString(item.payload.data);
					if(callbackFunc) then
						callbackFunc(output_msg, callbackParams)
					end	
				end
			end
			if(not HasResult) then
				unknown_uids = (unknown_uids or "")..uid..","
			end	
		end
		msg.uids = unknown_uids
	end	
	if(msg.nids) then
		---- NOTE: original implementation that will return once upon each multiple nids request
		--local nid;
		--local unknown_nids = nil;
		--for nid in string.gfind(msg.nids, "([^,]+)") do
			---- if local server has an unexpired result, remove the nid from msg.nid and return the result to callbackFunc
			---- otherwise, continue. 
			--local HasResult;
			---- make input msg
			--local input_msg = {
				--nids = tostring(nid),
				--fields = msg.fields,
			--};
			---- make url
			--local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "nids", nid, "fields", msg.fields, })
			--local item = ls:GetItem(url)
			--if(item and item.entry and item.payload) then
				--if(not cache_policy:IsExpired(item.payload.creation_date)) then
					---- we found an unexpired result for nid, return the result to callbackFunc
					--HasResult = true;
					---- make output msg
					--local output_msg = commonlib.LoadTableFromString(item.payload.data);
					--if(callbackFunc) then
						--callbackFunc(output_msg, callbackParams)
					--end
				--end
			--end
			--if(not HasResult) then
				--unknown_nids = (unknown_nids or "")..nid..",";
			--end	
		--end
		
		
		local nid;
		local unknown_nids = nil;
		local output_msg = {users={}};
		for nid in string.gfind(msg.nids, "([^,]+)") do
			-- make input msg
			local input_msg = {
				nids = tostring(nid),
			};
			-- make url
			local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "nids", nid, })
			local item = ls:GetItem(url)
			if(item and item.entry and item.payload) then
				if(cache_policy:IsExpired(item.payload.creation_date)) then
					-- we found an expired result, break the loop and request with the new nids
					unknown_nids = msg.nids;
					break;
				else
					-- append output msg
					local userinfo_single = commonlib.LoadTableFromString(item.payload.data);
					table.insert(output_msg.users, userinfo_single);
				end
			else
				-- no item found in local server
				unknown_nids = msg.nids;
				break;
			end
		end
		if(unknown_nids == nil) then
			-- no unknown nids
			if(msg.nid and msg.id) then
				-- original pet.get handler
				local out_msg = commonlib.deepcopy(output_msg.users[1]);
				if(callbackFunc) then
					callbackFunc(out_msg, callbackParams);
				end
			else
				-- user.getinfo handler
				if(callbackFunc) then
					callbackFunc(output_msg, callbackParams);
				end
			end
		end
		msg.nids = unknown_nids;
	end	
	
	if(msg.uids==nil and msg.nids==nil) then
		return true;
	end
	
	-- assert the nids field is string
	msg.nids = tostring(msg.nids);

	---- assert the nid and id field is nil
	--msg.nid = nil;
	--msg.id = nil;
end,

-- Post Processor
function (self, msg, id,callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	
	if(msg == nil and inputMsg and inputMsg.fields) then
		--local ls = System.localserver.CreateStore(nil, 3);
		--if(not ls) then
			--return
		--end
		--local users={};
		---- if results are not found, we will try local server expired version
		--if(inputMsg.uids) then
			--local uid;
			--for uid in string.gfind(inputMsg.uids, "([^,]+)") do
				---- if local server has an result, remove the uid from msg.uid and return the result to callbackFunc
				---- make input msg
				--local input_msg = {
					--uids = tostring(uid),
					--fields = inputMsg.fields,
				--};
				---- make url
				--local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "uids", uid, "fields", inputMsg.fields, })
				--local item = ls:GetItem(url)
				--if(item and item.entry and item.payload) then
					---- make output msg
					--local lsMsg = commonlib.LoadTableFromString(item.payload.data);
					--if(lsMsg and lsMsg.users and lsMsg.users[1]) then
						--LOG.std("", "system","API", "Expired local version is used for "..url);
						--table.insert(users, lsMsg.users[1]);
					--end	
				--end
			--end
		--end
		--if(inputMsg.nids) then
			--local nid;
			--for nid in string.gfind(inputMsg.nids, "([^,]+)") do
				---- if local server has an result, remove the nid from msg.nid and return the result to callbackFunc
				---- make input msg
				--local input_msg = {
					--nids = tostring(nid),
					--fields = inputMsg.fields,
				--};
				---- make url
				--local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "nids", nid, "fields", inputMsg.fields, })
				--local item = ls:GetItem(url)
				--if(item and item.entry and item.payload) then
					---- make output msg
					--local lsMsg  =commonlib.LoadTableFromString(item.payload.data);
					--if(lsMsg and lsMsg.users and lsMsg.users[1]) then
						--LOG.std("", "system","API", "Expired local version is used for "..url);
						--table.insert(users, lsMsg.users[1]);
					--end	
				--end
			--end
		--end
		--if( (#users) > 0 ) then
			--return {users=users};
		--end
	elseif(type(msg) == "table" and msg.users) then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			-- make the url
			local i, user
			for i, user in ipairs(msg.users) do
				--local fields, field;
				--for field in pairs(user) do
					--if(not fields) then
						--fields = field
					--else
						--fields = fields..","..field
					--end
				--end
				--fields = string.lower(commonlib.Encoding.SortCSVString(fields));
				if(user.nid and tostring(user.nid) ~= tostring(System.User.nid)) then
					-- make input msg
					local input_msg = {
						nids = tostring(user.nid),
					};
					-- make output msg
					local output_msg = user;
					-- make url
					local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "nids", input_msg.nids, })
					
					-- make entry
					local item = {
						entry = System.localserver.WebCacheDB.EntryInfo:new({
							url = url,
						}),
						payload = System.localserver.WebCacheDB.PayloadInfo:new({
							status_code = System.localserver.HttpConstants.HTTP_OK,
							data = (output_msg),
						}),
					}
					-- save to database entry
					local res = ls:PutItem(item) 
					if(res) then 
						LOG.std("", "system","API", "User info of %s saved to local server", url);
					else	
						LOG.std("", "warning","API", LOG.tostring("warning: failed saving user info of %s to local server\n", tostring(url))..LOG.tostring(output_msg));
					end
				end
			end

			--if(not originalMsg.nid or not originalMsg.id) then
				---- wrap to none pet.get message reply
				--return {users = {msg}};
			--end
			
			if(originalMsg.nid and originalMsg.id and msg.users[1]) then
				-- wrap to pet.get message reply
				return msg.users[1];
			end
		end
	end
end, nil, nil, 5000, nil, 2000);

-- get the unexpired version of userinfo if not expired in local server cache
-- @param nid: nid of the user
-- @param cache_policy: if nil use default getInfo_cache_policy
function paraworld.users.getInfoIfUnexpiredInLocalServer(nid, cache_policy)
	cache_policy = cache_policy or getInfo_cache_policy;
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end
	
	if(paraworld.OfflineMode) then
		cache_policy = System.localserver.CachePolicies["always"];
	end
	
	---- this field is specified for local server to work properly for both versions of API
	--local fields = "userid,nid,nickname,pmoney,emoney,birthday,popularity,family";
	--fields = string.lower(commonlib.Encoding.SortCSVString(fields));
	
	if(cache_policy == nil) then
		return;
	end
	
	local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return 
	end
	
	-- if local server has an unexpired result, remove the nid from msg.nid and return the result to callbackFunc
	-- otherwise, continue. 
	local HasResult;
	-- make input msg
	local input_msg = {
		nids = tostring(nid),
		fields = fields,
	};
	-- make url
	local url = NPL.EncodeURLQuery(paraworld.users.getInfo.GetUrl(), {"format", 1, "nids", nid, })
	local item = ls:GetItem(url)
	if(item and item.entry and item.payload) then
		if(not cache_policy:IsExpired(item.payload.creation_date)) then
			-- make output msg
			return commonlib.LoadTableFromString(item.payload.data);
		end
	end
end


--[[
	///<summary>
	///登录用户更改自己的个人信息
	///</summary>
	/// <param name="msg">
	/// msg = {
	///     sessionkey 当前登录用户的凭证
    ///     nickname 修改后的昵称
	/// }
	/// <returns>
	/// msg = {
	///		issuccess = boolean
	///		[ errorcode ] = int  错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除
	///		[ info ] = string 将发生异常或特殊情形时会有此节点
	/// }
	/// </returns>
]] 
paraworld.create_wrapper("paraworld.users.setInfo", "%MAIN%/API/Users/SetInfo.ashx", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not paraworld.use_game_server) then
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	end
	if(msg.nickname) then
		msg.nickname = msg.nickname:gsub("[\r\n]", "");
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	if(msg.issuccess == true) then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			--local fields = "userid,nid,nickname,pmoney,emoney,birthday,popularity,family";
			--fields = string.lower(commonlib.Encoding.SortCSVString(fields));
			local url_getinfo = paraworld.users.getInfo.GetUrl();
			url_getinfo = NPL.EncodeURLQuery(url_getinfo, {"format", 1, "nids", Map3DSystem.User.nid})
			local item = ls:GetItem(url_getinfo);
			if(item and item.entry and item.payload) then
				local output_msg = commonlib.LoadTableFromString(item.payload.data);
				if(type(output_msg) == "table") then
					output_msg.nickname = inputMsg.nickname;
					-- make entry
					local item = {
						entry = System.localserver.WebCacheDB.EntryInfo:new({url = url_getinfo,}),
						payload = System.localserver.WebCacheDB.PayloadInfo:new({
							status_code = System.localserver.HttpConstants.HTTP_OK,
							data = (output_msg),
						}),
					};
					-- save to database entry
					local res = ls:PutItem(item);

					if(res) then 
						LOG.std("", "system","API", "user info of %s updated to local server after setinfo with nickname\n", tostring(url_getinfo));
					else	
						LOG.std("", "warning","API", LOG.tostring("warning: failed updating user info of %s to local server after setinfo with nickname\n", tostring(url_getinfo))..LOG.tostring(output_msg));
					end
				end
			end
		end -- if(ls) then
	end
end);

--[[
  /// <summary>
    ///  修改当前登录用户的个人信息（青年版）
    ///  接收参数：
    ///     sessionkey 当前登录用户的凭证
    ///     nickname 修改后的昵称
    /// 返回值：
    ///     issuccess
    ///     [ errorcode ]  418:昵称已被其它用户占用
    /// </summary>
]] 
paraworld.create_wrapper("paraworld.users.setInfo2", "%MAIN%/API/Users/SetInfo2.ashx", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not paraworld.use_game_server) then
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	end
	if(msg.nickname) then
		msg.nickname = msg.nickname:gsub("[\r\n]", "");
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	if(msg.issuccess == true) then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			--local fields = "userid,nid,nickname,pmoney,emoney,birthday,popularity,family";
			--fields = string.lower(commonlib.Encoding.SortCSVString(fields));
			local url_getinfo = paraworld.users.getInfo.GetUrl();
			url_getinfo = NPL.EncodeURLQuery(url_getinfo, {"format", 1, "nids", Map3DSystem.User.nid})
			local item = ls:GetItem(url_getinfo);
			if(item and item.entry and item.payload) then
				local output_msg = commonlib.LoadTableFromString(item.payload.data);
				if(type(output_msg) == "table") then
					output_msg.nickname = inputMsg.nickname;
					-- make entry
					local item = {
						entry = System.localserver.WebCacheDB.EntryInfo:new({url = url_getinfo,}),
						payload = System.localserver.WebCacheDB.PayloadInfo:new({
							status_code = System.localserver.HttpConstants.HTTP_OK,
							data = (output_msg),
						}),
					};
					-- save to database entry
					local res = ls:PutItem(item);

					if(res) then 
						LOG.std("", "system","API", "user info of %s updated to local server after setinfo with nickname\n", tostring(url_getinfo));
					else	
						LOG.std("", "warning","API", LOG.tostring("warning: failed updating user info of %s to local server after setinfo with nickname\n", tostring(url_getinfo))..LOG.tostring(output_msg));
					end
				end
			end
		end -- if(ls) then
	elseif(msg.errorcode == 418) then
		LOG.std("", "warn","SetInfo2", "user name of %s already in use, please use a different one", inputMsg.nickname);
	end
end);

--[[
    /// <summary>
    /// 修改昵称（青年版）
    /// 接收参数：
    ///     sessionkey
    ///     nname  新的昵称
    /// 返回值：
    ///     issuccess
    ///     [ consumem ] 修改成功后所消耗的魔豆数量
    ///     [ errorcode ] 418:昵称已被其它用户占用  443:魔豆不足
    /// </summary>
]] 
paraworld.create_wrapper("paraworld.users.ChangeNickname", "%MAIN%/API/Users/ChangeNickname.ashx", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not paraworld.use_game_server) then
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	end
	msg.log2db = 1;
	msg.logremark = "ChangeNickname";
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	if(msg.issuccess == true) then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			--local fields = "userid,nid,nickname,pmoney,emoney,birthday,popularity,family";
			--fields = string.lower(commonlib.Encoding.SortCSVString(fields));
			local url_getinfo = paraworld.users.getInfo.GetUrl();
			url_getinfo = NPL.EncodeURLQuery(url_getinfo, {"format", 1, "nids", Map3DSystem.User.nid})
			local item = ls:GetItem(url_getinfo);
			if(item and item.entry and item.payload) then
				local output_msg = commonlib.LoadTableFromString(item.payload.data);
				if(type(output_msg) == "table") then
					output_msg.nickname = inputMsg.nname;
					-- make entry
					local item = {
						entry = System.localserver.WebCacheDB.EntryInfo:new({url = url_getinfo,}),
						payload = System.localserver.WebCacheDB.PayloadInfo:new({
							status_code = System.localserver.HttpConstants.HTTP_OK,
							data = (output_msg),
						}),
					};
					-- save to database entry
					local res = ls:PutItem(item);

					if(res) then 
						LOG.std("", "system","API", "user info of %s updated to local server after setinfo with nickname\n", tostring(url_getinfo));
					else	
						LOG.std("", "warning","API", LOG.tostring("warning: failed updating user info of %s to local server after setinfo with nickname\n", tostring(url_getinfo))..LOG.tostring(output_msg));
					end
				end
			end
		end -- if(ls) then
	elseif(msg.errorcode == 418) then
		LOG.std("", "warn","Users", "user name of %s already in use, please use a different one", inputMsg.nickname or "");
	elseif(msg.errorcode == 443) then
		LOG.std("", "warn","Users", "not enough money to change nick name");
	end
end);

--[[
    /// <summary>
    /// 检验昵称是否已被占用（青年版）
	/// 也可以用来查找昵称的NID
    /// 接收参数：
    ///     nname 要检验的昵称
    /// 返回值：
    ///     nid  若已被占用，则返回使用该昵称的用户的NID，否则返回-1
    /// </summary>
]] 
paraworld.create_wrapper("paraworld.users.CheckNickName", "%MAIN%/API/Users/CheckNName.ashx", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not paraworld.use_game_server) then
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	end
end);

--[[
        /// <summary>
        /// 给指定的用户添加P币或E币
        /// 接收参数：
        ///     nid
        ///     pmoney
        ///     emoney
        /// 返回值：
        ///     issuccess
        ///     [ errorcode ]
        /// </summary>
]] 
paraworld.create_wrapper("paraworld.users.AddMoney", "%MAIN%/API/Users/AddMoney.ashx", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not paraworld.use_game_server) then
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	end
	msg.nid = Map3DSystem.User.nid;
	msg.pmoney = 0;
	msg.emoney = msg.emoney or 0;
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	if(msg.issuccess == true) then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			--local fields = "userid,nid,nickname,pmoney,emoney,birthday,popularity,family";
			--fields = string.lower(commonlib.Encoding.SortCSVString(fields));
			local url_getinfo = paraworld.users.getInfo.GetUrl();
			url_getinfo = NPL.EncodeURLQuery(url_getinfo, {"format", 1, "nids", Map3DSystem.User.nid,})
			local item = ls:GetItem(url_getinfo);
			if(item and item.entry and item.payload) then
				local output_msg = commonlib.LoadTableFromString(item.payload.data);
				if(type(output_msg) == "table") then
					output_msg.emoney = output_msg.emoney + inputMsg.emoney;
					-- make entry
					local item = {
						entry = System.localserver.WebCacheDB.EntryInfo:new({url = url_getinfo,}),
						payload = System.localserver.WebCacheDB.PayloadInfo:new({
							status_code = System.localserver.HttpConstants.HTTP_OK,
							data = (output_msg),
						}),
					};
					-- save to database entry
					local res = ls:PutItem(item);
					if(res) then 
						LOG.std("", "system","API", "user info of %s updated to local server after AddMoney with E$:%d\n", tostring(url_getinfo), inputMsg.emoney);
					else	
						LOG.std("", "system","API", LOG.tostring("warning: failed updating user info of %s to local server after AddMoney with E$:%d\n", tostring(url_getinfo), inputMsg.emoney)..LOG.tostring(output_msg));
					end
				end
			end
		end -- if(ls) then
	end
end);


--[[
        /// <summary>
        /// 设置指定用户的战斗系别
        /// 接收参数：
        ///     nid  指定的用户的NID
        ///     school  战斗系别的标识，即旧版本中表示系别的物品的GSID：986,987,988,989,990,991,992
        /// 返回值：
        ///     issuccess
        ///     [ errorcode ]
        /// </summary>
]] 
paraworld.create_wrapper("paraworld.users.SetCombatSchool", "%MAIN%/API/Users/SetCombatSchool.ashx", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not paraworld.use_game_server) then
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	end
	msg.nid = Map3DSystem.User.nid;
	
	if(not msg.school or type(msg.school) ~= "number" or msg.school <= 985 or msg.school >= 993) then
		log("error: invalid school param in paraworld.users.SetCombatSchool\n")
		return false;
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	if(msg.issuccess == true) then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			--local fields = "userid,nid,nickname,pmoney,emoney,birthday,popularity,family";
			--fields = string.lower(commonlib.Encoding.SortCSVString(fields));
			local url_getinfo = paraworld.users.getInfo.GetUrl();
			url_getinfo = NPL.EncodeURLQuery(url_getinfo, {"format", 1, "nids", Map3DSystem.User.nid,})
			local item = ls:GetItem(url_getinfo);
			if(item and item.entry and item.payload) then
				local output_msg = commonlib.LoadTableFromString(item.payload.data);
				if(type(output_msg) == "table") then
					output_msg.combatschool = inputMsg.school;
					-- make entry
					local item = {
						entry = System.localserver.WebCacheDB.EntryInfo:new({url = url_getinfo,}),
						payload = System.localserver.WebCacheDB.PayloadInfo:new({
							status_code = System.localserver.HttpConstants.HTTP_OK,
							data = (output_msg),
						}),
					};
					-- save to database entry
					local res = ls:PutItem(item);
					if(res) then 
						LOG.std("", "system","API", "user info of %s updated to local server after SetCombatSchool with school:%s\n", tostring(url_getinfo), inputMsg.school);
					else	
						LOG.std("", "system","API", LOG.tostring("warning: failed updating user info of %s to local server after SetCombatSchool with school:%s\n", tostring(url_getinfo), inputMsg.school)..LOG.tostring(output_msg));
					end
				end
			end
		end -- if(ls) then
	end
end);

--[[
User . GetUserAndDragonInfo? 　（取当前用户自己的数据时，推荐使用） 
[host]/API/Users/GetUserAndDragonInfo        
/// <summary>
/// 获取指定用户的个人信息及其抱抱龙的信息
/// 接收参数：
///     "nid" 
///   返回值：
///       user：返回的用户信息
///          nid
///          nickname  昵称
///          pmoney  P币
///          emoney  E币（奇豆）
///          birthday  生日（首次进入哈奇的时间）
///          popularity  人气值
///          family  所属家族的名称
///          introducer  推荐人的NID
///          luck 时运。0:大凶；1:凶；2:正常；3:小吉；4:吉
///          accummodou 用户通过充值获得的魔豆的累计
///          [ resetsecdt ] 重置安全密码的时间
///       [ dragon] : 返回的抱抱龙的信息，若该用户没有抱抱龙，则不会有此节点
///          nickname 昵称
///          level 级别
///          friendliness 亲密度
///          strong 体力值
///          cleanness 清洁值
///          mood 心情值
///          nextlevelfr 长级到下一级所需的亲密度
///          health 健康状态
///          kindness 爱心值
///          intelligence 智慧值
///          agility 敏捷值
///          strength 力量值
///          archskillpts  建筑熟练度
///          combatexp  战斗经验值
///          combatlel  战斗等级
///          nextlevelexp  升级到下一个战斗等级所需的战斗经验值
///          energy  魔法星能量值
///          m  魔法星M值
///          mlel  魔法星等级（由M值决定）
///          nextlelm  魔法星升级到下一等级所需的M值，若已是最后一级，则返回99999999
///          combatschool  战斗系别
///          stamina  精力值
///          stamina2 体力值2
///       [ errorCode ]：错误码，发生异常时有此节点
/// </summary>
]]
-- NOTE: massive reconstrunct to pet.get and users.getinfo
-- previously well known API pet.get and users.getinfo is merged into one implementation: users.GetUserAndDragonInfo
-- and multiple user version users.getinfo, the two new api share the same url of userinfo to store both userinfo and petdragon info in one entry
-- related APIs that need local server update are also refactored. 
-- userinfo entry table format of each user is not compatible with previous format, which is included in a users = {} table. the new entry data stores
-- the data table directly
-- users.GetUserAndDragonInfo returns with a separated user and dragon table. the two table is then merged into one table stored in local server
-- nickname of dragon info is renamed petname, preventing a name collision with user nickname
-- original pet.get API(paraworld.homeland.petevolved.Get) is now implemented as an API switch. For loggedinuser call paraworld.users.GetUserAndDragonInfo,
-- for other user call paraworld.users.getInfo. 
-- url with paraworld.homeland.petevolved.Get local server entry is totally deprecated
-- we recommand all in memeory data fetching with userinfo and dragon info with ProfileManager.GetUserInfoInMemory, if not available or not updated, 
-- ProfileManager.GetUserInfo is needed for update with cache_policy
-- WARNING: since two data source share the same local server, but they are not updated in time on each other in each in-memory functions
-- like getbean(), so we recommend ProfileManager.GetUserInfo with a cache policy, and always use ProfileManager.GetUserInfoInMemory
local getuseranddragoninfo_cache_policy = System.localserver.CachePolicy:new("access plus 1 day");
paraworld.create_wrapper("paraworld.users.GetUserAndDragonInfo", "%MAIN%/API/Users/GetUserAndDragonInfo.ashx",
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not paraworld.use_game_server) then
		msg.sessionkey = Map3DSystem.User.sessionkey;
	end	
	--msg.userid = msg.userid or Map3DSystem.User.userid;
	
	local cache_policy = msg.cache_policy or getuseranddragoninfo_cache_policy;
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end
	msg.cache_policy = nil;
	
	--if(paraworld.OfflineMode) then
		--cache_policy = System.localserver.CachePolicies["always"];
	--end
	
	---- this field is specified for local server to work properly for both versions of API
	--msg.fields = "userid,nid,nickname,pmoney,emoney,birthday,popularity,family";
	--msg.nid = "46650264";
	
	if(cache_policy == nil) then
		return;
	end
	
	local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return 
	end

	-- make input msg
	local input_msg = {
		nid = tostring(msg.nid),
	};
	-- make url
	local url = NPL.EncodeURLQuery(paraworld.users.getInfo.GetUrl(), {"format", 1, "nids", msg.nid, })
	local item = ls:GetItem(url)
	if(item and item.entry and item.payload) then
		if(not cache_policy:IsExpired(item.payload.creation_date)) then
			-- make output msg
			if(item.payload.data) then
				local output_msg = commonlib.LoadTableFromString(item.payload.data);
				if(output_msg) then
					if(msg.nid and msg.id) then
						-- original pet.get handler
						if(tostring(output_msg.nid) == tostring(msg.nid)) then
							if(callbackFunc) then
								callbackFunc(output_msg, callbackParams);
							end
						end
					else
						-- user.getinfo handler
						if(callbackFunc) then
							-- tricky return msg combo
							callbackFunc({user = output_msg, dragon = output_msg}, callbackParams);
						end
					end
					LOG.std(nil, "debug", "rest", "unexpired data used for %s", url);
					return true;
				end
			end
		end
	end
end,

-- Post Processor
function (self, msg, id,callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	
	if(type(msg) == "table" and msg.user and msg.dragon) then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			-- make url
			local url = NPL.EncodeURLQuery(paraworld.users.getInfo.GetUrl(), {"format", 1, "nids", inputMsg.nid, })
			
			local userinfo = {};
			local k, v;
			for k, v in pairs(msg.user) do
				userinfo[k] = v;
			end
			for k, v in pairs(msg.dragon) do
				if(k == "nickname") then
					k = "petname";
				end
				userinfo[k] = v;
			end
			msg.user = userinfo;
			msg.dragon = userinfo;

			-- make entry
			local item = {
				entry = System.localserver.WebCacheDB.EntryInfo:new({
					url = url,
				}),
				payload = System.localserver.WebCacheDB.PayloadInfo:new({
					status_code = System.localserver.HttpConstants.HTTP_OK,
					data = (userinfo),
				}),
			}
			-- save to database entry
			local res = ls:PutItem(item);
			if(res) then 
				LOG.std("", "system","API", "User and Dragon info of %s saved to local server", url);
			else	
				LOG.std("", "warning","API", LOG.tostring("warning: failed saving user and Dragon info of %s to local server\n", tostring(url))..LOG.tostring(msg));
			end

			local ProfileManager = commonlib.gettable("Map3DSystem.App.profiles.ProfileManager");
			ProfileManager.OnUpdateUserInfo(userinfo);

			if(originalMsg.nid and originalMsg.id) then
				-- wrap to pet.get message reply
				return userinfo;
			end
		end
	end
end, nil, nil, 5000, nil, 2000);

--[[
    /// <summary>
    /// 关注度投票，使获得投票的人的人气值+1
    /// 接收参数：
    ///     nid  当前登录用户的NID
    ///     tonid  受关注的人的NID
    /// 返回值：
    ///     issuccess
    ///     [ errorcode ]  错误码。其中，430:超过单日最大投票次数  431:重复投票
    /// </summary>
]] 
paraworld.create_wrapper("paraworld.users.VotePopularity", "%MAIN%/API/Users/VotePopularity.ashx");

----[[
	--///<summary>
	--/// add money directly to the user account
	--///</summary>
	--/// <param name="msg">
	--/// msg = {
	--///     nid
	--///     pmoney
	--///     emoney
	--/// }
	--/// <returns>
	--/// msg = {
	--///		issuccess = boolean
	--/// }
	--/// </returns>
--]] 
--paraworld.create_wrapper("paraworld.users.AddMoney", "%MAIN%/API/Users/AddMoney.ashx");


------------------------------------------------------------------------------------------------
--
-- NOTE: rest of the APIs are NOT imported to new APIs, WangTian, 2009/6/30
--
------------------------------------------------------------------------------------------------




--[[
]] 
paraworld.CreateRESTJsonWrapper("paraworld.users.isAppAdded", "http://users.paraengine.com/isAppAdded.ashx");



--[[
	/// <summary>
	/// 依据输入的Email查找已在PE注册的用户，并将注册用户的ID返回，多个用户ID之间用英文逗号分隔
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		email(string) (*) 要查找的Email地址，多个Email之间用英文逗号“,”隔开
	/// }
	/// </param>
	/// <returns>
	/// msg = {
	///		uids (string)  以英文逗号分隔的符合条件的用户ID集合
	///		[ errorcode ] (int)  若发生异常，则返回错误码。错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除
	/// }
	/// </returns>
]]
paraworld.CreateRESTJsonWrapper("paraworld.users.Find", "%MAIN%/Users/Find.ashx");



--[[
	/// <summary>
	/// 注册一个新用户
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		"appkey" = string (*)
	///		"username" = string (*) //注册的用户名
	///		"password" = string (*) //注册的密码
	///		"email" = "string" (*) //注册的邮箱
	///		"passquestion" = string (*) //安全问题
	///		"passanswer" = string (*) //安全问题的答案
	///		[ ip ] = string //当用户是从网站注册（或其它第三方应用程序调用）时，应该提供用户的IP地址，以便获得用户的所在地。
	/// }
	/// </param>
	/// <returns>
	/// msg = {
	///		issuccess = boolean //注册是否成功
	///		newuserid = string //新注册用户的ID值
	///		[ info ] = string //发生异常或特殊情形下会有此节点，记录导演信息
	/// }
	/// </returns>
]] 
paraworld.create_wrapper("paraworld.users.Registration", "%MAIN%/API/Users/Registration",
	-- pre validation function
	function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
		local password_use_md5 = true;
		if(password_use_md5) then
            if(msg.password)then
			    msg.password = ParaMisc.md5(msg.password);
            end
		end
		LOG.std("", "debug","Registration.begin", msg);
	end, 
	-- post process function
	function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
		LOG.std("", "debug","Registration.end", msg);
		if(msg ~= nil) then
			if(msg.issuccess) then
			else
				-- 500：未知错误 499：提供的数据不完整 498：非法的访问 407：用户名或密码错误 412：账号未激活 413：账号被锁定 
				if(msg.errorcode==401) then
					msg.info = "您输入的Email地址已存在"
				elseif(msg.errorcode==402) then
					msg.info = "用户名已存在"
				elseif(msg.errorcode==404) then
					msg.info = "Email 格式不正确"	
				elseif(msg.errorcode==405) then
					msg.info = "密码格式不正确"	
				elseif(msg.errorcode==499) then
					msg.info = "提供的数据不完整"
				elseif(msg.errorcode==498) then
					msg.info = "您的IP地址暂时无法访问我们社区, 我们正在开通更多的地区."
				elseif(msg.errorcode==500) then
					msg.info = "服务器繁忙，请稍后重试"
				else	
					msg.info = "登陆时出现了未知错误, errorcode: "..tostring(msg.errorcode);
				end
			end	
		end
	end
	);

--[[
/// <summary>
/// 检验CDKey是否可用
/// 接收参数：
///     keycode
/// 返回值：
///     result 0:不可用 1:可用
/// </summary>
]]
paraworld.create_wrapper("paraworld.users.CheckCDKey", "%MAIN%/API/CDKeys/CheckCDKey");

--[[
/// <summary>
/// 使用CDKey
/// 接收参数：
///     nid
///     keycode
/// 返回值：
///     result 0:成功 1:CDKEY不存在 2:CDKEY已被使用
/// </summary>
]]
paraworld.create_wrapper("paraworld.users.UseCDKey", "%MAIN%/API/CDKeys/UseCDKey");



--[[
	/// <summary>
	/// 依据传入的MCQL语句查找用户
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		mcql(string) (*) 规范的MCQL语句 （不支持多表联合查询，不支持聚合函数，不支持Top语句；   支持where、order by 、group by语句；  可用字段：uid,uname,createDate,lastactivitydate,email）
	///							（MCQL关键字：pagesize: 用在where语句中，以分页的形式返回数据，该值指定每页的最大数据量，必须与pageindex一起使用才起作用，否则忽略，若指定了pageindex，却没有提供pagesize，则默认的每页最大数据量为10
	///										  pageindex:用在where语句中，以分页的形式返回数据，该值指定返回的页码。
	///											示例：select * from users where pageindex = 0 and pagesize = 20 //每页最多20条数据，返回第一页的数据）
	/// }
	/// </param>
	/// <returns>
	/// msg = {
	///		users[list]{ //所有字段都是可选的
	///			uid: string
	///			uname: string
	///			createDate: string
	///			lastactivitydate: string
	///			email: string
	///		}
	///		errorcode //错误码。发生异常时会有此节点 错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除  494：语法错误
	/// }
	/// </returns>
]] 
paraworld.CreateRESTJsonWrapper("paraworld.users.Search", "%MAIN%/Users/Search.ashx");



--[[
	/// <summary>
	/// 邀请好友加入
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		"sessionkey" = string (*) 当前登录用户的用户凭证
	///		"from" = string (*) 发送邀请者的名称，发送者自行填写，将显示在邮件中
	///		"to" = string(*) 以英文逗号（,）分隔的被邀请用户的Email集合
	///		"message" = string (*) 邀请信函中包含的消息
	///		"language" = int 邀请信使用的语言。1：中文，2：英文。默认值为1
	/// }
	/// </param>
	/// <returns>
	/// msg = {
	///		"issuccess" = boolean 操作是否成功
	///		[ errorcode ] = int  错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除
	/// }
	/// </returns>
]] 
paraworld.CreateRESTJsonWrapper("paraworld.users.Invite", "%MAIN%/Users/Invite.ashx", paraworld.prepLoginRequried);

--[[
	/// <summary>
    /// 当前登录用户给指定用户加一个红枫叶
    /// 接收参数：
    ///     sessionkey  当前登录用户的SessionKey
    ///     tonid  获得红枫叶用户的NID
    /// 返回值：
    ///     issuccess
    ///     [ errorcode ]
    /// </summary>

]] 
paraworld.create_wrapper("paraworld.users.ChallengeHomelandFlag", "%MAIN%/API/Users/ChallengeHomelandFlag.ashx");


--[[
        /// <summary>
        /// 获取排行数据
        /// 接收参数：
        ///     rankid: name or id of the ranking list to retrieve. 
        ///                [popularity, combat_hero, magicstar_level, dragon_level, dragon_strength, dragon_wisdom, drgaon_agility, drgaon_kindness] 
        /// 返回值：下列参数的array
        ///    nid        number 米米号
        ///    name    string     用户昵称
        ///    familyname   string   家族名称
        ///    mlvl      number  魔法星等级，非VIP 用户 -1
        ///    field1    number 排行字段1
        ///    field2    number 排行字段2
        ///     如果查的是 magicstar_level 榜，返回的 field1 就是魔法星等级，field2 是能量值
        ///    如果查的是 combat_hero榜，返回的 field1 就是战斗等级，field2 是本级经验值
        ///    如果查的是 dragon_level榜，返回的 field1 就是抱抱龙等级，field2 是本级亲密度      
        ///     [ errorcode ]
        /// </summary>
]] 
paraworld.create_wrapper("paraworld.users.GetRanking", "%MAIN%/API/Users/GetRanking.ashx",
-- pre processor
function(self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	local cache_policy = msg.cache_policy or "access plus 1 day";
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end
	msg.cache_policy = nil;
	
	local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return;
	end
	msg.rankid = msg.rankid or 0;
	local url = self.GetUrl().. "_" .. msg.rankid;
	
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
			local url = self.GetUrl() .. "_" .. (inputMsg.rankid or "0");
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


--[[
        /// <summary>
        /// 获取PK排行数据
        /// 接收参数：
		///		date  int 年月，yyyyMM
        ///     listname: name of the ranking list to retrieve. 
        ///                [pk_1v1_all, pk_2v2_all, pk_1v1_storm, pk_1v1_fire, pk_1v1_ice, pk_1v1_life, pk_1v1_death] 
        /// 返回值：下列参数的array
        ///    nid        number 米米号
        ///    name    string     用户昵称
        ///    familyname   string   家族名称
        ///    mlvl      number  魔法星等级，非VIP 用户 -1
        ///    field1    number 排行字段1
        ///    field2    number 排行字段2
        ///     [ errorcode ]
        /// </summary>
]] 
paraworld.create_wrapper("paraworld.users.GetPKRanking", "%MAIN%/API/Users/GetPKRanking.ashx",
-- pre processor
function(self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	local cache_policy = msg.cache_policy or "access plus 1 day";
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end
	msg.cache_policy = nil;
	
	local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return;
	end
	msg.listname = msg.listname or "";
	local url = self.GetUrl().. "_" .. msg.listname.."_"..msg.date;
	
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
			local url = self.GetUrl() .. "_" .. (inputMsg.listname or "").."_"..inputMsg.date;
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

--[[
        /// <summary>
        /// 取得指定家族排行榜
        /// 接收参数：
        ///     date：　int 排行榜年月,yyyyMM
        ///     listname: 排行榜名称
        /// 返回值：
        ///     list [ list ]
        ///         familyid
       ///         familyname
       ///         level
       ///         field1
       ///         field2
       ///         nid1
       ///         mlvl1
        ///         name1
       ///         nid2
       ///         mlvl2
        ///         name2
       ///         nid3
       ///         mlvl3
        ///         name3
        /// </summary>
]] 
paraworld.create_wrapper("paraworld.users.GetFamilyRank", "%MAIN%/API/Users/GetFamilyRank.ashx",
-- pre processor
function(self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	local cache_policy = msg.cache_policy or "access plus 1 day";
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end
	msg.cache_policy = nil;
	
	local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return;
	end

	local url = self.GetUrl().. "_" .. msg.listname;
	
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
			local url = self.GetUrl() .. "_" .. (inputMsg.rankid or "0");
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

--[[
        /// <summary>
        /// 更改时运
        /// 接收参数：
        ///     sessionkey 当前登录用户
        /// 返回值：
        ///     [ luck ] 新的进运
        ///     [ updates ][list]
        ///         guid
        ///         bag
        ///         cnt
        ///     [ errorcode ] 错误码。419:用户不存在；427:道具不足；
        /// </summary>
]] 
paraworld.create_wrapper("paraworld.users.ChangeLuck", "%MAIN%/API/Users/ChangeLuck.ashx");


--[[
	/// <summary>
    /// 注册之前取得验证码和Session
    /// 接收参数：
    ///     无
    /// 返回值：
    ///     session
    ///     valibmp  验证码图片的Base64表示形式
    /// </summary>
]]
paraworld.create_wrapper("paraworld.users.GetRegVeriCode", "%MAIN%/API/Users/GetRegVeriCode.ashx");

--[[
        /// <summary>
        /// 抽奖
        /// 接收参数：
        ///     sessionkey
        /// 返回值：
        ///     gsid 抽中的商品的GSID
        ///     cnt 抽中的商品的数量
        ///     items [list] 奖池中的商品列表
        ///         gsid
        ///         cnt
        ///     [ updates ] [list]
        ///         guid
        ///         bag
        ///         cnt
        ///     [ adds ] [list]
        ///         guid
        ///         gsid
        ///         bag
        ///         cnt
        ///         position
        ///     [ stats ] [list]
        ///         gsid
        ///         bag
        ///     [ errorcode ] 416:未配置抽奖数据；419:用户不存在；431:今天抽奖次数已达上限；497:抽中的物品不存在；424:物品太多了；
        /// </summary>
]]
paraworld.create_wrapper("paraworld.users.Lottery", "%MAIN%/API/Users/Lottery.ashx", -- pre processor
function(self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	LOG.std(nil, "system", "Lottery", "begin Lottery");
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)

	if(type(msg) == "table") then
		LOG.std(nil, "system", "Lottery", "end lottery");
		LOG.std(nil, "debug", "Lottery", msg);
		
		if(msg.gsid) then
			Map3DSystem.Item.ItemManager.UpdateBagItems(msg.updates, msg.adds, msg.stats);
		end
	end
end);

--[[
        /// <summary>
        /// 用户签到领取奖励、或查看当前可领取什么奖励
        /// 接收参数：
        ///     sessionkey
        ///     type 0:签到领取奖励；1:查看可领取什么奖励
        /// 返回值：
        ///     if type == 0
        ///         issuccess
        ///         [ updates ] [list]
        ///             guid
        ///             bag
        ///             cnt
        ///         [ adds ] [list]
        ///             guid
        ///             gsid
        ///             bag
        ///             cnt
        ///             position
        ///         [ stats ] [list]
        ///             gsid
        ///             bag
        ///         [ errorcode ] 416:未设置签到奖励；419:用户不存在；431:已经领取过奖励了；497:奖励物品不存在；424:物品太多了；
        ///     if type == 1
        ///         sign 当前登录用户当天是否已经签到过。
        ///         logintimes 当前登录用户连续登录的天数
        ///         list [list] 奖励配置列表
        ///             day 连续登录的天数
        ///             items [list] 奖励列表
        ///                 gsid
        ///                 cnt
        /// </summary>
]]
paraworld.create_wrapper("paraworld.Users.Checkin", "%MAIN%/API/Users/SignIn.ashx",
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not paraworld.use_game_server) then
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	end	
	LOG.std("", "debug","Users.Checkin", msg);
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	LOG.std("", "debug","Users.Checkin", msg);
	if(not msg) then
		return;
	end
	if(inputMsg.type == 0) then
		if(msg.issuccess) then
			Map3DSystem.Item.ItemManager.UpdateBagItems(msg.updates, msg.adds, msg.stats);
		end
		Map3DSystem.User.has_daily_checkedin = true;
	else
		if(msg.sign == true) then
			Map3DSystem.User.has_daily_checkedin = true;
		elseif(msg.sign == false) then
			Map3DSystem.User.has_daily_checkedin = false;
		end
		if(msg.logintimes) then
			Map3DSystem.User.daily_checkedin_times = msg.logintimes;
		end
		if(msg.list) then
			Map3DSystem.User.daily_checkin_awards = msg.list;
		end
	end
end
);

--[[
/// <summary>
        /// 用户签到领取奖励、或查看当前可领取什么奖励 （青年版）
        /// 接收参数：
        ///     sessionkey
        ///     type 0:签到领取奖励；1:查看可领取什么奖励
        /// 返回值：
        ///     if type == 0
        ///         issuccess
        ///         [ updates ] [list]
        ///             guid
        ///             bag
        ///             cnt
        ///         [ adds ] [list]
        ///             guid
        ///             gsid
        ///             bag
        ///             cnt
        ///             position
        ///         [ stats ] [list]
        ///             gsid
        ///             bag
        ///         [ errorcode ] 416:未设置签到奖励；419:用户不存在；431:已经领取过奖励了；497:奖励物品不存在；424:物品太多了；
        ///     if type == 1
        ///         sign 当前登录用户当天是否已经签到过。
        ///         logintimes 当前登录用户连续登录的天数
        ///         list [list] 奖励配置列表
        ///             day 连续登录的天数
        ///             items [list] 奖励列表
        ///                 gsid
        ///                 cnt
        /// </summary>
]]
paraworld.create_wrapper("paraworld.Users.CheckinTeen", "%MAIN%/API/Users/SignIn2.ashx",
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not paraworld.use_game_server) then
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	end	
	LOG.std("", "debug","Users.CheckinTeen", msg);
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	LOG.std("", "debug","Users.CheckinTeen", msg);
	if(not msg) then
		return;
	end
	if(inputMsg.type == 0) then
		if(msg.issuccess) then
			Map3DSystem.Item.ItemManager.UpdateBagItems(msg.updates, msg.adds, msg.stats);
		end
		Map3DSystem.User.has_daily_checkedin = true;
	else
		if(msg.sign == true) then
			Map3DSystem.User.has_daily_checkedin = true;
		elseif(msg.sign == false) then
			Map3DSystem.User.has_daily_checkedin = false;
		end
		if(msg.logintimes) then
			Map3DSystem.User.daily_checkedin_times = msg.logintimes;
		end
		if(msg.list) then
			Map3DSystem.User.daily_checkin_awards = msg.list;
		end
	end
end
);

paraworld.create_wrapper("paraworld.users.NIDRelationOtherAccount", "%MAIN%/API/Users/NIDRelationOtherAccount",
	function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
		LOG.std(nil, "debug", "NIDRelationOtherAccount", "begin binding");
	end,
	function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
		LOG.std(nil, "debug", "NIDRelationOtherAccount", "end binding");
	end
);

--[[
/// <summary>
/// 取得与指定平台的帐户所相关联的NID
/// 接收参数：
///     plat 平台ID，1:FB；2:QQ
///     oid 平台帐户
/// 返回值：
///     nid 多个NID之间用英文逗号分隔，若返回-1，表示该平台帐户未与任何NID关联
/// </summary>
]]
paraworld.create_wrapper("paraworld.users.GetNIDByOtherAccountID", "%MAIN%/API/Users/GetNIDByOtherAccountID",
	function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
		LOG.std(nil, "debug", "GetNIDByOtherAccountID.begin", msg);
	end,
	function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
		LOG.std(nil, "debug", "GetNIDByOtherAccountID.end", msg);
	end
);

--[[
/// <summary>
/// 用户兑换指定的排行榜的奖励
///        排行榜ID为以下格式：yyyyMMdd***，后面三位为排行榜的代号，不足三位左边以0补齐，yyyyMMdd为排行榜统计结束的时间。
///        　　　　如1v1排行榜的代号为1，其2012年10月的排行榜ID则为 20121031001 。
///        若排行榜可领取奖励，则其可领取的奖励在（http://192.168.0.51:84/Admin/WorldServers/ServerObjects.aspx）这里配置。
///        　　　　KEY的格式为：“rank_” 后面加排行榜的代号。如1v1排行榜的代号为1，则配置为 rank_1。
///        　　　　VALUE为该排行榜不同排名可领取的奖励的物品，格式为：排名 : GSID , CNT ; GSID, CNT | 排名 : GSID , CNT ; GSID, CNT .....
///        　　　　　　　　示例：10:17213,5|20:17213,10;17214,10 的意思是：1--10名可领取GSID为17212的物品5个，11--20名可领取GSID为17213的物品10个及GSID为17214的物品10个
/// 接收参数：
///     sessionkey
///     rid  排行榜ID
/// 返回值：
///     issuccess
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
///     [ stats ][list] 输出兑换后各属性值的变化，其中-12表示当前的健康状态（0：健康；1：生病；2：死亡），-1000表示抱抱龙升级到下一级所需的亲密度
///         gsid  -1:P币；0:E币；-2:亲密度；-3:爱心值；-4:力量值；-5:敏捷值；-6:智慧值；-7:建筑熟练度；-8:抱抱龙等级；-9:体力值；-10:清洁值；-11:心情值；-12:健康状态；-13:战斗经验值；-14:战斗等级；
///         cnt
///     [ errorcode ] 427:不在可获得奖励的名次范围内；417:已经兑换过奖品了；416:不存在此排行榜的奖励定义；415:排行榜统计还未结束
/// </summary>
]]
paraworld.create_wrapper("paraworld.Items.ExchangeRank", "%MAIN%/API/Items/ExchangeRank",
	function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
		LOG.std(nil, "system", "ExchangeRank.begin", msg);
	end,
	function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
		LOG.std(nil, "system", "ExchangeRank.end", msg);
		if(msg) then
			if(msg.issuccess) then
				Map3DSystem.Item.ItemManager.UpdateBagItems(msg.updates, msg.adds, msg.stats);
			end
		end
	end
);
--[[
 /// <summary>
        /// 取得展示给当前用户的所有活动
        /// 参数：
        ///     sessionkey
        /// 返回值：
        ///     [list]
        ///         id
        ///         froms
        ///         condi
        ///         act_type
        ///         desc
        ///         sum_rewards
        /// </summary>
--]]
paraworld.create_wrapper("paraworld.users.GetOperations", "%MAIN%/API/Users/GetOperations",
	function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
		LOG.std(nil, "debug", "GetOperations", "begin binding");
	end,
	function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
		LOG.std(nil, "debug", "GetOperations", "end binding");
	end
);
--[[
  /// <summary>
        /// 执行指定的运营活动
        /// 接收参数：
        ///     sessionkey
        ///     id 运营活动的ID
        /// 返回值：
        ///     issuccess
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
        ///     [ stats ][list] 输出兑换后各属性值的变化，其中-12表示当前的健康状态（0：健康；1：生病；2：死亡），-1000表示抱抱龙升级到下一级所需的亲密度
        ///         gsid  -1:P币；0:E币；-2:亲密度；-3:爱心值；-4:力量值；-5:敏捷值；-6:智慧值；-7:建筑熟练度；-8:抱抱龙等级；-9:体力值；-10:清洁值；-11:心情值；-12:健康状态；-13:战斗经验值；-14:战斗等级；
        ///         cnt
        ///     [ errorcode ]
        /// </summary>
--]]
paraworld.create_wrapper("paraworld.users.ExecOperation", "%MAIN%/API/Users/ExecOperation",
	function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
		LOG.std(nil, "debug", "ExecOperation", "begin binding");
	end,
	function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
		LOG.std(nil, "debug", "ExecOperation", "end binding");
		if(msg) then
			if(msg.issuccess) then
				Map3DSystem.Item.ItemManager.UpdateBagItems(msg.updates, msg.adds, msg.stats);
			end
		end
	end
);