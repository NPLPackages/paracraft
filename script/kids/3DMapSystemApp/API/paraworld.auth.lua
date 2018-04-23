--[[
Title: It is for client and application to authenticate a user and return or verify a session key. 
Author(s): LiXizhi, WangTian
Date: 2008/1/21
NOTE: change all userid to nid, WangTian, 2009/6/30
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/ParaworldAPI.lua");
-------------------------------------------------------
]]

-- create class
commonlib.setfield("paraworld.auth", {});

local ExternalUserModule = commonlib.gettable("MyCompany.Aries.ExternalUserModule");

local LOG = LOG;
local LastUserName, LastPassword, last_login_msg;
-- called when successfully logged in. 
local function SaveUserLoginInfo(msg, inputMsg)
	Map3DSystem.User.IsAuthenticated = true;
	-- this will work like cookies in later calls. see paraworld.prepLoginRequried. 
	Map3DSystem.User.sessionkey = msg.sessionkey;
	Map3DSystem.User.sessionid = msg.sessionid;
	Map3DSystem.User.userid = msg.userid;
	-- NOTE by Andy 2008/12/16: i see a new id called nid, just appended

	local region_id = ExternalUserModule:GetRegionIDFromNid(msg.nid);
	if(region_id ~= ExternalUserModule:GetRegionID()) then
		LOG.std(nil, "info", "RegionID", "region_id changed from %d to %d", ExternalUserModule:GetRegionID(), region_id);
		ExternalUserModule:Init(true,region_id)
	end

	Map3DSystem.User.nid = ExternalUserModule:MakeNid(msg.nid);
	NPL.load("(gl)script/apps/Aries/Desktop/GameMemoryProtector.lua");
	local GameMemoryProtector = commonlib.gettable("MyCompany.Aries.Desktop.GameMemoryProtector");
	GameMemoryProtector.CheckPoint("System.User.nid", Map3DSystem.User.nid);

	Map3DSystem.User.ChatDomain = paraworld.TranslateURL("%CHATDOMAIN%");
	-- NOTE by LiXizhi 2009.7.31: for temporary ejabberd authentication. 
	Map3DSystem.User.ejabberdsession = msg.ejabberdsession;
	-- commonlib.echo(Map3DSystem.User)
	LOG.std("", "system","API", "user info of %s is saved", tostring(Map3DSystem.User.nid));
	if(msg.nid) then
		Map3DSystem.User.jid = msg.nid.."@"..Map3DSystem.User.ChatDomain
	end	
	Map3DSystem.User.Name = LastUserName;
	Map3DSystem.User.username = LastUserName; -- use this if one wants to login again.
	Map3DSystem.User.need_to_check_locked = true;

	if(inputMsg) then
		-- for users from other platforms.
		Map3DSystem.User.token = inputMsg.token;
		Map3DSystem.User.plat = inputMsg.plat;
		Map3DSystem.User.oid = inputMsg.oid;
		Map3DSystem.User.last_login_msg = last_login_msg;
		Map3DSystem.User.last_login_msg.valicode = nil;
		Map3DSystem.User.last_login_msg.sessionid = nil;
	end

	if(paraworld.use_game_server) then
		GameServer.rest.client.user_nid = msg.nid;
	end
end

-- this prevents the login post log to post twice during server switching. 
local is_login_called = false;

--[[ Authenticate the user. Never use admin account to login, since the message is 
    not well encrypted, maybe I should encode the SOAP message body or SOAP header.
    /// <summary>
    /// User Login
    /// </summary>
    /// <param name="msg">
	///		msg = { 
	///			"username" = string, (*)
	///			"password" = string, (*)
	///			"newSession" = boolean 表示是否需要生成一个新的Session key，如果此值为true，表示用户重新登录并获得一个新的Session Key，如果为false或没有值，当该用户的旧Session key有效时，返回旧的Session Key，当旧的Session Key无效时，生成一个新的Session key，默认值为false
	///		}
    /// </param>
    /// <returns>
	///		msg = 
	///     {
	///         issuccess(boolean) 登录是否成功
	///			sessionkey(string) 登录成功后返回当前登录用户的Session Key
	///			userid(string) 当前登录用户的用户ID
	///			[ errorcode ] (int) 错误码。 //错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  407：用户名或密码错误  412：账号未激活  413：账号被锁定
	///			[ info ] (String)  当发生异常或特殊情形下返回的信息
	///         [ HasOfflineMode ] (boolean): whether offline mode is supported. we can support it if user has at least successfully logged in once. The caller of paraworld.auth.AuthUser can suppress offline mode by simply display the msg.info. Offline mode dialog is shown if the caller does not supress offline mode.
	///     }
    /// </returns>
]]
paraworld.create_wrapper("paraworld.auth.AuthUser", "%MAIN%/API/Auth/AuthUser.ashx",
	-- pre validation function
	function (self, msg)
		if(paraworld.IsAuthenticated) then
			-- TODO: logout first?
		end	
		LastUserName = msg.username;
		LastPassword = msg.password;
		
		if(ExternalUserModule.Init) then
			if(tonumber(msg.username)) then
				msg.username = ExternalUserModule:GetNidLowerBits(msg.username);
			end
			msg.from = msg.from or ExternalUserModule:GetRegionID();
		end
		-- added partner id. 
		msg.partner = msg.partner or System.options.partner;

		msg.token = msg.token or System.User.token;
		msg.loginplat = msg.loginplat or System.User.loginplat;
		msg.plat = msg.plat or System.User.plat;
		msg.oid = msg.oid or System.User.oid;
        --keepwork
        if(msg.plat and msg.plat == 7)then
            msg.loginplat = 1;
		    msg.nid2 = msg.nid2 or System.User.nid2 or System.User.nid;
        end
		-- inject version
		NPL.load("(gl)script/apps/GameServer/GSL_version.lua");
		local GSL_version = commonlib.gettable("Map3DSystem.GSL.GSL_version");
		msg.ver = GSL_version.ver;
		local password_use_md5 = true;
		if(password_use_md5 and msg.from==0) then
			if(not msg.is_md5_password) then
                if(msg.password)then
				    msg.password = ParaMisc.md5(msg.password);
                end
				msg.is_md5_password = true;
			end
		end

		LOG.std(nil, "debug", "paraworld.auth.input", msg);

		last_login_msg = commonlib.clone(msg);
		

		--[[
		if msg.loginplat && msg.loginplat > 0 then
			NPL.load("(gl)script/apps/Aries/Partners/PartnerPlatforms.lua");
			local Platforms = commonlib.gettable("MyCompany.Aries.Partners.Platforms");
			local _oid = Platforms.GetOID();
			if _oid then
				msg.oid = _oid;
				msg.token = Platforms.GetToken();
			end
		end
		]]
	end, 
	-- post process function
	function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
		local function CheckOfflineMode(sReason)
			if(LastUserName) then
				-- HTTP error is met, perhaps server is down or local network is not available. we can check the local server to give the user an offline mode choice. 
				local ls = System.localserver.CreateStore(nil, 3);
				if(ls) then
					local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "username", LastUserName});
					local entry = ls:GetItem(url);
					if(entry) then
						LOG.std("", "system","API", "offline auth mode can be started.");
						
						local newMsg = {data = entry.payload.data, header=entry.payload.headers, code=0, rcode=200};
						if(postMsgTranslator) then
							newMsg = postMsgTranslator(newMsg)
						end
						_guihelper.CloseMessageBox();
						_guihelper.MessageBox(string.format("%s\n是否对用户%s启动离线模式", sReason or "网络无法联通", LastUserName), function(result)
							if(_guihelper.DialogResult.Yes == result) then
								if(callbackFunc) then
									paraworld.EnableOfflineMode(true);
									SaveUserLoginInfo(newMsg, inputMsg);
									callbackFunc(newMsg, callbackParams);
								end
							end	
						end, _guihelper.MessageBoxButtons.YesNo)
						-- this allow for offline mode
						return {rcode=raw_msg.rcode, HasOfflineMode = true, info="网络无法联通"}
					end
				end
			end
		end

		if(msg ~= nil) then
			if(msg.issuccess) then
				-- save user session
				SaveUserLoginInfo(msg, inputMsg);
				
				-- send log information
				if(not is_login_called) then
					paraworld.PostLog({action="user_login"}, "login_log", function(msg)
						is_login_called = true;
					end);
				end

				if(System and System.User) then
					System.User.LastAuthGameTime = ParaGlobal.timeGetTime();
					System.User.LastAuthServerTime = msg.dt or "2009-11-23 21:18:38"; -- yyyy-MM-dd HH:mm:ss
				end
				
				-- save successful login return msg to local server for offline mode in the future. 
				local ls = System.localserver.CreateStore(nil, 3);
				if(ls) then
					local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "username", LastUserName});
					-- new item is successfully fetched.
					local new_item = {
						entry = System.localserver.WebCacheDB.EntryInfo:new({
							url = url,
						}),
						payload = System.localserver.WebCacheDB.PayloadInfo:new({
							status_code = System.localserver.HttpConstants.HTTP_OK,
							cached_filepath = nil,
							data = raw_msg.data,
							headers = raw_msg.headers,
						}),
					};
					ls:PutItem(new_item);
				end	
			else
				-- 500：未知错误 499：提供的数据不完整 498：非法的访问 407：用户名或密码错误 412：账号未激活 413：账号被锁定 
				if(msg.errorcode==407) then
					msg.info = "您输入的用户名或密码错误, 如果您忘记了密码，可以从我们的网站通过Email取回密码"
				elseif(msg.errorcode==412) then
					msg.info = "你的账号数据异常，管理员正在清查你的数据状态，请稍候再尝试登陆。"
				elseif(msg.errorcode==413) then
					msg.info = "账号被锁定"	
				elseif(msg.errorcode==426) then
					msg.info = "密码连续输入错误次数太多，请稍后再试"	
				elseif(msg.errorcode==499) then
					msg.info = "提供的数据不完整"
				elseif(msg.errorcode==498) then
					msg.info = "您的IP地址暂时无法访问我们社区, 我们正在开通更多的地区."
				elseif(msg.errorcode==500) then
					msg.info = "服务器繁忙，请稍后重试"
				elseif(msg.errorcode==447) then
					msg.info = "同一帐号，同一IP登录次数过多";
				elseif(msg.errorcode == 426) then
					msg.info = "使用的帐号未与米米号绑定过";
				elseif(msg.errorcode == 438) then
					msg.info = "未传递必要的用户凭证";
				elseif(msg.errorcode == 419) then
					msg.info = "无法正确验证用户凭证";
				elseif(msg.errorcode == 496) then
					msg.info = "用户凭证无效或已过期";
				else	
					msg.info = "登陆时出现了未知错误, errorcode: "..tostring(msg.errorcode);
					--return CheckOfflineMode(msg.info);
				end
				LOG.std(nil, "error", "AuthUser", "failed with errorcode %s: reason:%s", tostring(msg.errorcode), tostring(msg.info));
				LOG.std(nil, "debug", "AuthUser", "failed with %s input msg: %s ", commonlib.serialize_compact(msg), commonlib.serialize_compact(inputMsg));
			end	
		else
			return CheckOfflineMode();
		end
	end);

-- call this function to retrieve the game server version. 
-- the client usually needs to call this function 
-- @return msg = {ver=number, ip=string, }
paraworld.create_wrapper("paraworld.auth.Ping", "%MAIN%/API/Auth/Ping.ashx");

--[[
	/// <summary>
	/// User logout 
	/// </summary>
	/// <param name="msg">
	///		msg = {
	///			"sessionkey" = string (*)
	///		}
	/// </param>
	/// <returns>
	///		msg = {
	///			issuccess(boolean)　登出是否成功
	///			[ errorcode ] int 错误码。 //错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问
	///			[ info ] string  结果说明信息，若发生异常或特殊情形下则会有些节点
	///		}
	/// </returns>
]]
paraworld.create_wrapper("paraworld.auth.Logout", "%MAIN%/API/Auth/Logout.ashx", 
function(self, msg, id, callbackFunc, callbackParams, postMsgTranslator) 
	is_login_called = false;
end);

--[[fetch ip address
]]
paraworld.CreateRPCWrapper("paraworld.whereipfrom", "%LOG%/cgi-bin/whereipfrom", 
function (self, msg, id, callback_func, callbackParams, postMsgTranslator)
end,
-- post process function
function (self, html_node)
	LOG.std("", "system","paraworld.whereipfrom", html_node);
end, 
nil, paraworld.HTMLTranslator
);


--[[ enable post log here 
]]
local bEnablePostLog = true;
local nFailCountDown = 3;
paraworld.CreateRESTJsonWrapper("paraworld.PostLog", "%LOG%/APIs/PostLog", 
function (self, msg, id, callback_func, callbackParams, postMsgTranslator)
	if(bEnablePostLog) then
		msg.nid = System.User.nid;
		msg.format = nil;

		-- insert region_id if it is not zero.
		if(ExternalUserModule.GetRegionIDFromNid) then
			local region_id = ExternalUserModule:GetRegionIDFromNid(msg.nid);
			if(region_id~=0) then
				msg.region_id = region_id;
			end
		end

		local plainstr = commonlib.serialize_compact2(msg) or "";
		LOG.std("", "system","PostLog", plainstr);
		plainstr = string.sub(plainstr, 2, -2);
		
		local keys = {};
		local k, v;
		for k, v in pairs(msg) do
			table.insert(keys, k);
		end
		local _, key;
		for _, key in pairs(keys) do
			msg[key] = nil;
		end
		msg.msg = plainstr;
	else
		local plainstr = commonlib.serialize_compact2(msg) or "";
		LOG.std("", "system","PostLog", "[local]: %s\n", plainstr);
		if(callbackFunc) then
			callbackFunc(nil, callbackParams)
		end	
		return true;
	end
end,
-- post process function
function (self, msg)
	if(not msg) then
		if(nFailCountDown <=0) then
			LOG.std("", "warning","PostLog", "post log failed. paraworld.PostLog is disabled. you will only see paraworld.PostLog [local]. but message is not sent to server.");
			bEnablePostLog = false;
		else
			LOG.std("", "warning","PostLog", "post log failed. we may retry %d times\n", nFailCountDown);
			nFailCountDown = nFailCountDown - 1;
		end
	else
		nFailCountDown = 3;
	end
end
);


--[[ enable post message here 
]]
local bEnablePostMsg = true;
local nFailPostMsgCountDown = 3;
paraworld.CreateRESTJsonWrapper("paraworld.PostMsg", "%LOG%/APIs/PostMsg.ashx", 
function (self, msg, id, callback_func, callbackParams, postMsgTranslator)
	if(bEnablePostMsg) then
		msg.nid = System.User.nid;
		msg.format = nil;

		-- insert region_id if it is not zero.
		if(ExternalUserModule.GetRegionIDFromNid) then
			local region_id = ExternalUserModule:GetRegionIDFromNid(msg.nid);
			if(region_id~=0) then
				msg.region_id = region_id;
			end
		end

		local plainstr = commonlib.serialize_compact2(msg) or "";
		LOG.std("", "system","PostMsg", plainstr);
		plainstr = string.sub(plainstr, 2, -2);
		
		local keys = {};
		local k, v;
		for k, v in pairs(msg) do
			table.insert(keys, k);
		end
		local _, key;
		for _, key in pairs(keys) do
			msg[key] = nil;
		end
		msg.msg = plainstr;
	else
		local plainstr = commonlib.serialize_compact2(msg) or "";
		LOG.std("", "system","PostMsg", "[local]: %s\n", plainstr);
		if(callbackFunc) then
			callbackFunc(nil, callbackParams)
		end	
		return true;
	end
end,
-- post process function
function (self, msg)
	if(not msg) then
		if(nFailCountDown <=0) then
			LOG.std("", "warning","PostMsg", "post msg failed. paraworld.PostMsg is disabled. you will only see paraworld.PostMsg [local]. but message is not sent to server.");
			bEnablePostMsg = false;
		else
			LOG.std("", "warning","PostMsg", "post msg failed. we may retry %d times\n", nFailPostMsgCountDown);
			nFailPostMsgCountDown = nFailPostMsgCountDown - 1;
		end
	else
		nFailPostMsgCountDown = 3;
	end
end
);

--[[
	/// <summary>
	/// 在AppDomain验证指定的用户（Session Key）是否是在线状态
	/// </summary>
	/// <param name="msg">
	///     msg = {
	///         "sessionkey" = string (*),用户凭证
	///    }
	/// </param>
	/// <returns>
	///     msg = 
	///     {
	///         result(boolean) 指定用户是否是在线状态
	///			sessionkey(string) 即主键
	///			userid(string) 用户ID
	///			expireDate(string) 凭证过期时间
	///			[ errorcode ] int 错误码。 //错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问
	///			[ info ] (string) 当发生异常时会有此节点
	///     }
	/// </returns>
]]
paraworld.create_wrapper("paraworld.auth.VerifyUser", "%MAIN%/API/Auth/VerifySession.ashx", paraworld.prepLoginRequried);


--[[Get server list and client server version. this should be the first RPC to call when the game engine start.
Output msg is currently defined as below. 
{
  ClientVersion=1,
  MinClientVersion=1,
  ServerVersion=1,
  DownloadPage="http://www.pala5.com/download.html",
  domain="test.pala5.cn",
  ChatDomain="pala5.cn" 
}
paraworld.auth.GetServerList(nil, "test", function(msg)  
	commonlib.echo(msg)
end)
paraworld.auth.GetServerList({cache_policy="access plus 1 second"}, "test", function(msg)  
	commonlib.echo(msg)
end)
]]
paraworld.CreateRESTJsonWrapper("paraworld.auth.GetServerList", "%MAIN%/API/Auth/GetServerList.txt", 
-- pre validation function and use default inputs
function(self, msg, id, callbackFunc, callbackParams, postMsgTranslator) 
	-- msg.cache_policy is removed from web service input. 
	local cache_policy;
	if(msg) then
		cache_policy = msg.cache_policy;
		msg.cache_policy = nil;
	end	
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy)
	end
	if(not cache_policy) then
		cache_policy = System.localserver.CachePolicy:new("access plus 1 day");
	end
	
	local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return;
	end
	
	-- if local server has an unexpired result, return the GetServerList in local store
	-- otherwise, continue. 
	local HasResult;
	-- make input msg
	local input_msg = msg;
	-- make url
	local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, })
	local item = ls:GetItem(url)
	if(item and item.entry and item.payload) then
		if(not cache_policy:IsExpired(item.payload.creation_date)) then
			-- we found an unexpired result for GetServerList, return the result to callbackFunc
			LOG.std("", "system","API", "unexpired version used for GetServerList");
			HasResult = true;
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
	if(type(msg) == "table") then
		-- put in local server
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			-- make input msg
			local input_msg = inputMsg;
			-- make output msg
			local output_msg = msg;
			-- make url
			local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, })
			
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
				LOG.std("", "system","API", "GetServerList saved to local server");
			else	
				LOG.std("", "warning","API", LOG.tostring("warning: failed saving GetServerList of %s to local server\n", tostring(url))..LOG.tostring(output_msg));
			end
		end -- if(ls) then
	end
end);


------------------------------------------------------------------------------------------------
--
-- NOTE: rest of the APIs are NOT imported to new APIs, WangTian, 2009/6/30
--
------------------------------------------------------------------------------------------------

	
--[[
	/// <summary>
	/// 发送激活账号的Email，用在注册用户没有收到激活邮件时请求再次发送激活邮件。
	/// </summary>
	/// <param name="msg">
	///		msg = { 
	///			username = string (*) 被激活账号的用户名
	///			password = string (*) 被激活账号的密码
	///			language = int 激活Email所使用的语言，1：简体中文；2：英文。默认值为1
	///		}
	/// </param>
	/// <returns>
	///		msg = 
	///     {
	///         issuccess = boolean， 操作是否成功
	///			[ errorcode ] (int) 错误码。 //错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  414：账号已是激活状态，不必再次激活
	///     }
	/// </returns>
]]
paraworld.CreateRESTJsonWrapper("paraworld.auth.SendConfirmEmail", "%MAIN%/Auth/SendConfirmEmail.ashx");

--[[ OBSOLETED: use GetServerList instead.
	/// <summary>
    /// Check whether a given client version is supported by ParaEngine server. It also returns the latest 
    /// client and server version that the website support. 
    /// </summary>
    /// <param name="msg">
    /// msg={
    ///     "op" = ["check"]|[""],
    ///     "ClientVersion" = A string returned by the ParaEngine client using ParaEngine.GetVersion()
    ///     "ServerVersion" = string.
    /// }</param>
    /// <returns>
    /// if op == "check" msg = {
    ///     ClientVersion=string, --The latest client version that the server support
    ///     ServerVersion=string, --The latest server version that the server support
    ///     UpdateURL=string, -- The url for manual update 
    ///     ClientMustUpdate=bool, -- Whether the client must update in order to use the server
    /// }
    /// else nil
    /// </returns>
]]
-- Note: if this function wants to use game server, replace  ls:GetURL with pure local server. 
paraworld.CreateRESTJsonWrapper("paraworld.auth.CheckVersion", "%MAIN%/Auth/CheckVersion.ashx",
	-- pre validation function and use default inputs
	function(self, msg, id, callbackFunc, callbackParams, postMsgTranslator) 
		msg.op = "check";
		msg.ClientVersion = msg.ClientVersion or ParaEngine.GetVersion();
		msg.ServerVersion = msg.ServerVersion or "1.0";
		-- msg.cache_policy is removed from web service input. 
		local cache_policy = msg.cache_policy;
		msg.cache_policy = nil;
		if(cache_policy==nil or cache_policy:IsCacheEnabled()) then
			-- DEMO of local server: it will retrieve from local server if we already checked version within 1 day time. 
			local ls = System.localserver.CreateStore(nil, 3);
			if(ls) then
				-- callbackFunc need to parse msg.data to json table. 
				ls:GetURL(System.localserver.CachePolicy:new("access plus 1 week"),
					self:GetUrl(), callbackFunc, callbackParams, postMsgTranslator
				);
			else
				LOG.std("", "error","API", "user info of %s is saved", "error: unable to open default local server store");
			end	
			-- since we process via local server, there is no need to call RPC. 
			return true;
		end	
	end);

--[[ 
       /// <summary>
        /// 根据 nid 取得用户资料
        /// 接收参数：
        ///     nid
        /// 返回值：
        ///   realname   (真实姓名)   如果realname ="000000000000000000000000000000" 就是无实名，否则为实名用户
        ///   sex     (性别)
        ///   birthday
        ///   idno (身份证)
        ///      
        /// </summary>
]]
paraworld.create_wrapper("paraworld.auth.GetUserInfo", "%MAIN%/API/Auth/GetUserInfo.ashx");

--[[
快玩登录
]]
paraworld.CreateRESTJsonWrapper("paraworld.auth.qvod", "http://login.api.kuaiwan.com/s2s/game/login/",
function (self, msg, id, callback_func, callbackParams)	
end,
-- post process function
function (self, msg)
	LOG.std("", "debug","paraworld.auth.qvod", msg);
end,
nil,paraworld.JsonTranslator
);