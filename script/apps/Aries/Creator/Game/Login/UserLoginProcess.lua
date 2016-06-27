--[[
Title: UserLoginProcess.html code-behind script
Author(s): LiPeng
Date: 2013/10/19
Desc: Create new world based on predefined template and open existing world. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/UserLoginProcess.lua");
local UserLoginProcess = commonlib.gettable("MyCompany.Aries.Game.UserLoginProcess")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/UserLoginProcessHelper.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local Platforms = commonlib.gettable("MyCompany.Aries.Partners.Platforms");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local MainLogin = commonlib.gettable("MyCompany.Aries.Game.MainLogin");
local UserLoginProcess = commonlib.gettable("MyCompany.Aries.Game.UserLoginProcess")

-- external command line. 
function UserLoginProcess.Proc_ExternalUserSignIn()
	local cur_url = System.options.cur_url;
	if(cur_url and cur_url~="") then
		-- TODO: use access token directly
		UserLoginProcess.ExternalUserSignInWithPlatform(Platforms.PLATS.QQ);
	else
		-- UserLoginProcess.Fail("您没有登录 无法进入联网模式, 请在登录页登录");
		UserLoginProcess.ExternalUserSignInWithPlatform(Platforms.PLATS.QQ);
	end
end

function UserLoginProcess.ExternalUserSignInWithPlatform(platform_id)
	System.options.platform_id = platform_id;
	Platforms.SetPlat(System.options.platform_id);

	local function OnProcessResult(result)
		LOG.std(nil, "debug", "platform.login.result", result);
		if(result.errorcode) then
			UserLoginProcess.Fail("认证失败了, 请重新尝试");

		elseif(result.uid and result.token and tonumber(result.plat)) then
			local url_cmdParams = result;
			local _plat = tonumber(url_cmdParams.plat); -- 平台ID，1:Facebook；2:QQ
			-- _guihelper.MessageBox(url_cmdParams.nid);
			local all_user_nids = {};
			local nid_;
			for nid_ in string.gmatch(tostring(url_cmdParams.nid), "([^,]+)") do
				nid_ = tonumber(nid_);
				if(nid_ and nid_~=-1) then
					all_user_nids[#all_user_nids+1] = nid_;
				end
			end
			local _uid = url_cmdParams.uid; -- 平台的用户ID，如QQ的OpenID，Facebook的EMail.....
			local _token = url_cmdParams.token; -- 平台的认证凭证
			local _appid = url_cmdParams.app_id; -- 平台的AppID
				
			MainLogin:user_login_next_step({IsExternalUserSignedIn=true, auth_user = {
				username=_uid, password="placeholder", 
				plat = _plat,  appid = _appid,
				loginplat = 1,
				-- use the first user to login, 
				-- nid2 = all_user_nids[1],
				oid = _uid,
				token = _token,
				rememberpassword=false, rememberusername=true}});
		else
			UserLoginProcess.Fail("认证失败了");
		end
	end

	_guihelper.MessageBoxClass.CheckShow(function() 
		Platforms.show_login_window(OnProcessResult)
	end);
end

-- we will load the default host and port if any, according to last user successful login or preferred port. 
function UserLoginProcess.LoadDefaultGatewayServer()
	if(UserLoginProcess.is_default_gateway_setting_loaded) then
		return;
	end
	UserLoginProcess.is_default_gateway_setting_loaded = true;

	NPL.load("(gl)script/apps/GameServer/rest_client.lua");
	-- we shall load the last game server by default. 
	local last_server = Game.PlayerController:LoadLocalData("LastWorldServer", nil, true);
	if(last_server and last_server.nid) then
		GameServer.rest.client.preferred_nid = last_server.nid;
	end
	
	-- we shall load predefined login port. 
	GameServer.rest.client.preferred_port = Game.PlayerController:LoadLocalData("preferred_port", nil, true);
	local last_port = Game.PlayerController:LoadLocalData("LastPort", nil, true);
	
	if(last_port ~= tostring(GameServer.rest.client.preferred_port)) then
		-- if we have never successfully logged in using the preferred port, we will remove the preferred port. 
		if(GameServer.rest.client.preferred_port~=nil) then
			LOG.std(nil, "info", "UserLoginProcess", "revert preferred port of %s", tostring(GameServer.rest.client.preferred_port));
			MyCompany.Aries.Player.SaveLocalData("preferred_port", nil, true);
		end
	end
	if(GameServer.rest.client.preferred_port) then
		if(GameServer.rest.client.preferred_port == -1) then
			GameServer.rest.client.preferred_port = nil;
		else
			LOG.std(nil, "info", "UserLoginProcess", "we are now replacing remote port with %d", GameServer.rest.client.preferred_port);
			-- MyCompany.Aries.Player.SaveLocalData("preferred_port", nil, true)
		end
	end
end

-- establish the first rest connection with the initial gateway game server. 
function UserLoginProcess.Proc_ConnectRestGateway()
	UserLoginProcess.ShowProgress("正在建立连接...", 0);
	
	UserLoginProcess.LoadDefaultGatewayServer();
	-- max number of login server to retry in sequence. 
	-- set to 0 to disable retry and a dialog is displayed to the user. 
	local max_retry_count = 2;
	local cur_retry_count = 0;
	
	if(paraworld.use_game_server) then
		
		local function StartConnect_()
			LOG.std("", "system", "Login", "try connecting to game server the %d times", cur_retry_count+1);
			-- set redirecting to true to prevent disconnection message box to appear. 
			System.User.IsRedirecting = true;
			local res = GameServer.rest.client:start(System.options.clientconfig_file, 0, function(msg)
				if(msg and msg.connected) then
					MainLogin:user_login_next_step({IsRestGatewayConnected = true});
				else
					MainLogin.state.gateway_server = nil;
					if(cur_retry_count<max_retry_count) then
						cur_retry_count = cur_retry_count + 1;
						UserLoginProcess.ShowProgress(string.format("正在建立连接...(第%d次尝试)", cur_retry_count+1), 0);
						StartConnect_();
					else
						System.User.IsRedirecting = true;
						UserLoginProcess.Fail([[<div style="margin-left:24px;margin-top:32px;">服务器的链接无法建立, 请稍候再试</div>]], {IsRestGatewayConnected = false, IsLoginStarted=false, IsUserSelected= false, IsRegistrationRequested=false, IsLocalUserSelected=false}, function()
							MainLogin:OnSolveNetworkIssue();
						end);
					end	
				end
			end, MainLogin.state.gateway_server)
			if( res ~= 0) then
				UserLoginProcess.Fail("服务器的链接无法建立",{IsRestGatewayConnected = false, IsLoginStarted=false, IsUserSelected= false, IsRegistrationRequested=false, IsLocalUserSelected=false}, function()
					MainLogin:OnSolveNetworkIssue();
				end);
			end
		end
		StartConnect_();
	else
		MainLogin:user_login_next_step({IsRestGatewayConnected = true});
	end
end


-- NOT used. verify the product version.
function UserLoginProcess.Proc_VerifyProductVersion()
	NPL.load("(gl)script/apps/GameServer/GSL_version.lua");
	local GSL_version = commonlib.gettable("Map3DSystem.GSL.GSL_version");
	UserLoginProcess.ShowProgress("正在检查版本号");
	local from_time = ParaGlobal.timeGetTime();
	-- send log information
	paraworld.auth.Ping({ver=GSL_version.ver}, "checkversion", function(msg)
		LOG.std(nil, "system", "login", "check version %s", commonlib.serialize_compact(msg));
		if(msg) then
			if(msg.ver == GSL_version.ver) then
				local svrtime = msg.srvtime;
				local hh,mm,ss=0,0,0;
				if (svrtime) then
					hh,mm,ss=string.match(svrtime,"(%d+):(%d+):(%d+)");
				end
				if (not System.User.login_time) then
					System.User.login_time=hh*3600+mm*60+ss;			
				end
				MainLogin:user_login_next_step({IsProductVersionVerified = true});
				to_time = ParaGlobal.timeGetTime();
				MainLogin.last_ping_interval = to_time-from_time;
				local game_nid = GameServer.rest.client.cur_game_server_nid;
				if(game_nid) then
					System.User.gs_nid = game_nid;
					NPL.load("(gl)script/apps/Aries/Player/main.lua");
					local Player = commonlib.gettable("MyCompany.Aries.Player");
					local network_latency = Player.LoadLocalData("network_latency", {}, true)
					network_latency[game_nid] = MainLogin.last_ping_interval;
					LOG.std(nil, "info", "network_latency", network_latency);
					Player.SaveLocalData("network_latency", network_latency, true, true);
					MainLogin.network_latency = network_latency;
				end
				
			else
				UserLoginProcess.Fail(format("你的游戏版本号是%d, 需要的版本号为%d. 请重新登录并更新游戏，如果仍然不行，请重新安装。", GSL_version.ver or 0, msg.ver or 0));
				paraworld.PostLog({action = "user_verify_version_failed", msg=format("user ver %d, server ver %d", GSL_version.ver or 0, msg.ver or 0)}, "user_login_process_stage_progress_log");
			end
		else
			UserLoginProcess.Fail("版本号验证失败");
		end
	end, "access plus 0 day", 10000, function(msg)
		-- timeout request
		UserLoginProcess.Fail("版本号验证超时", {IsRestGatewayConnected = false, IsLoginStarted=false, IsUserSelected= false, IsRegistrationRequested=false, IsLocalUserSelected=false}, function()
			MainLogin:OnSolveNetworkIssue();
		end);
	end);
end


-- select user nid
function UserLoginProcess.SelectUserNid()
	local values = MainLogin.state.auth_user;
	
	if(values and values.oid and values.token and not values.nid2) then
		UserLoginProcess.ShowProgress("获取角色列表...");
		
		paraworld.users.GetNIDByOtherAccountID({plat = values.plat, oid = values.oid}, "GetNIDByOtherAccountID", function(msg)
			LOG.std(nil, "debug", "GetNIDByOtherAccountID.result", msg);
			if(msg and msg.nid) then
				local all_user_nids = {};
				local nid_;
				for nid_ in string.gmatch(tostring(msg.nid), "([^,]+)") do
					nid_ = tonumber(nid_);
					if(nid_ and nid_~=-1) then
						all_user_nids[#all_user_nids+1] = nid_;
					end
				end
				
				if(#all_user_nids == 0) then
					-- create the first user
					local params = {
						userName = values.username,
						password = values.password,
						plat = values.plat,
						token = values.token,
						key = values.key,
						time = values.time,
						oid = values.oid,
						website = values.website,
						sid = values.sid,
						game = values.game,
					};
					UserLoginProcess.ShowProgress("创建第一个角色...");
					paraworld.users.Registration(params, "Register", function(msg)
						if(msg and msg.nid) then
							-- send log information
							paraworld.PostLog({reg_nid = tostring(msg.nid), action = "regist_success"}, "regist_success_log", function(msg) end);
							values.nid2 = tonumber(msg.nid);
							MainLogin:user_login_next_step({IsUserNidSelected = true});
						else
							LOG.std("", "error","Login", "Registration failed");
							UserLoginProcess.Fail("无法创建角色");
						end
					end, nil, 20000, function(msg)
						-- timeout request
						LOG.std("", "error","Login.Registration.timeout", msg);
						UserLoginProcess.Fail("无法创建角色");
					end)

				else
					-- use the first user to sign in
					UserLoginProcess.HideProgressUI();
					values.nid2 = all_user_nids[1];
					MainLogin:user_login_next_step({IsUserNidSelected = true});
				end
			end
		end, nil, 20000, function(msg)
			-- timeout request
			LOG.std("", "error","Login.GetNIDByOtherAccountID.timeout", msg);
			UserLoginProcess.Fail("无法获取角色列表");					
		end)
	else
		-- no need to select user nid.
		MainLogin:user_login_next_step({IsUserNidSelected = true});
	end
end


function UserLoginProcess.CreateNewAvatar()
	MainLogin:user_login_next_step({IsAvatarCreationRequested = false});
end


function UserLoginProcess.Proc_Registration()
end

-- Authenticate user and proceed to Proc_DownloadProfile(). it will assume the normal login procedures. It starts with authentification and ends with callback function or user profile page. 
function UserLoginProcess.Proc_Authentication()
	local values = MainLogin.state.auth_user;
	local msg = {
		username = values.username,
		password = values.password,
		plat = values.plat,
		loginplat = values.loginplat,
		oid = values.oid,
		nid2 = values.nid2,
		token = values.token,
		from = values.from,
		time = values.time,
		website = values.website,
		sid = values.sid,
		game = values.game,
		valicode = UserLoginProcess.last_veri_code,
		sessionid = System.User.sessionid,
	}
	
	LOG.std("", "debug","Login.begin", msg);
	UserLoginProcess.ShowProgress("验证用户身份");
	LOG.std("", "system","Login", "Start Proc_Authentication");
	-- send log information
	paraworld.PostLog({action = "user_login_process_stage_progress", msg="Proc_Authentication"}, "user_login_process_stage_progress_log", function(msg)
	end);
	
	NPL.load("(gl)script/kids/3DMapSystemUI/Chat/Main.lua");
	-- close jabber if we authenticate again. 
	System.App.Chat.CleanUp();
			
	paraworld.auth.AuthUser(msg, "login", function (msg)

		 --commonlib.echo("============users.Authentication after ==========");
		 --commonlib.echo(msg);

		if(msg==nil) then
			UserLoginProcess.Fail("连接的主机没有反应,连接尝试失败");
			-- send log information
			paraworld.PostLog({action = "user_login_process_stage_fail", msg = "Proc_Authentication_server_no_response"}, 
				"user_login_process_stage_fail_log", function(msg)
			end);
		elseif(msg.issuccess) then
			--System.User.Name = values.username; -- 2010/2/25: fix the tutorial bug
			System.User.Name = tostring(msg.nid);
			System.User.Password = values.password;
			System.User.sessionid = "";
			System.User.LastAuthGameTime = ParaGlobal.timeGetTime();
			System.User.LastAuthServerTime = msg.dt or "2009-11-23 21:18:38"; -- yyyy-MM-dd HH:mm:ss
	
			NPL.load("(gl)script/apps/Aries/Desktop/AriesSettingsPage.lua");
			local stats = MyCompany.Aries.Desktop.AriesSettingsPage.GetPCStats()
			local stats_str = string.format("%s|vs:%d|ps:%d|OS:%s|mem:%d|res:%d*%d|fullscreen:%s|webplayer:%s|", 
				stats.videocard or "", stats.vs or 0, stats.ps or 0, stats.os or "", stats.memory or 0, 
				stats.resolution_x, stats.resolution_y, tostring(stats.IsFullScreenMode), tostring(stats.IsWebBrowser));
			-- send log information
			paraworld.PostLog({action = "graphic_stats", stats = stats_str}, "graphic_stats_log", function(msg)
			end);
			
			-- NOTE by andy 2009/8/18: leave for the CreateNewAvatar process to test if the creation process is completed
			MainLogin:user_login_next_step({IsAuthenticated = true, IsAvatarCreationRequested = true});
			UserLoginProcess.AuthFailCounter = nil;
		else
			UserLoginProcess.AuthFailCounter = UserLoginProcess.AuthFailCounter or 0;
			UserLoginProcess.AuthFailCounter = UserLoginProcess.AuthFailCounter + 1;
			if(UserLoginProcess.AuthFailCounter >= 5) then
				-- shut down app if user input wrong password 5 times in a row
				ParaGlobal.ExitApp();
			end
			if(msg.errorcode == 412) then
				_guihelper.MessageBox(string.format("%s\n\n%s", tostring(msg.info), 
					"账号未激活, 我们需要您通过Email等方式确认您的身份后才能登录\n是否希望重新发送确认信到你注册时提供的邮箱?"), function()
					paraworld.auth.SendConfirmEmail({username = values.username, password = values.password,}, "Login", function(msg)
						if(msg ~= nil) then
							if(msg.issuccess) then
								UserLoginProcess.ShowProgress("发送成功, 请查看你的邮箱");
							else
								-- 497：数据不存在或已被删除 414：账号已是激活状态不必再次激活 
								if(msg.errorcode==497) then
									UserLoginProcess.ShowProgress("数据不存在或已被删除");
								elseif(msg.errorcode==414) then
									UserLoginProcess.ShowProgress("账号已是激活状态不必再次激活");
								else
									UserLoginProcess.ShowProgress("未知服务器错误, 请稍候再试");
								end
							end	
						end
					end)
				end);
			else
				LOG.std("", "error","Login", {"Auth failed because", msg});
				local error_msg;
				if(msg.errorcode == 407) then
					error_msg = "用户名或密码错误";
				elseif(msg.errorcode == 413) then
					error_msg = "你的账号已违反游戏秩序,已给予冻结处理（10分钟或更久），如有疑问请联系客服。";
				elseif(msg.errorcode == 412) then
					error_msg = "很抱歉, 我们的客服正在维护您的账号！一般会在1小时内完成. 如有疑问请联系客服.";
				elseif(msg.errorcode == 419) then
					error_msg = MyCompany.Aries.ExternalUserModule:GetConfig().account_name .. "不存在。"
				elseif(msg.errorcode == 500) then	
					error_msg = string.format("夜深了，%s已经关闭了，大家也早点休息吧！",MyCompany.Aries.ExternalUserModule:GetConfig().product_name or "魔法哈奇");
				elseif(msg.errorcode == 426) then
					error_msg = "密码连续输入错误的次数太多，请15秒后再试"
				elseif(msg.errorcode == 444) then
					error_msg = "验证码输入错误"
				elseif(msg.errorcode == 446) then
					error_msg = "登录失败并且错误次数过多，请输入验证码后再登录";
				elseif(msg.errorcode == 447) then
					error_msg = "同一米米号或同一ip密码错误尝试次数过多，请输入验证码后再登陆";
				elseif(msg.errorcode == 496) then
					error_msg = "用户凭证无效或已过期, 请退出游戏重新登录";
				else	
					error_msg = "服务器繁忙，请稍后重试"
				end

				-- 验证码逻辑
				local ExternalUserModule = commonlib.gettable("MyCompany.Aries.ExternalUserModule");
				if (ExternalUserModule:GetRegionID()==0) then
					if(msg.errorcode ~= 426 and msg.valibmp) then
						UserLoginProcess.SavImg(msg.errorcode,msg.valibmp,msg.sessionid);
						return;
					end
				end

				UserLoginProcess.Fail(error_msg or msg.info);
				-- send log information
				paraworld.PostLog({action = "user_login_process_stage_fail", msg = "Proc_Authentication_errorcode:"..msg.errorcode}, 
					"user_login_process_stage_fail_log", function(msg)
				end);
			end
		end
	end, nil, 20000, function(msg)
		-- timeout request
		LOG.std("", "error","Login", "Proc_Authentication timed out");
		UserLoginProcess.Fail("用户验证超时了, 可能服务器太忙了, 或者您的网络质量不好.");
		-- send log information
		paraworld.PostLog({action = "user_login_process_stage_fail", msg = "Proc_Authentication_timed_out"}, 
			"user_login_process_stage_fail_log", function(msg)
		end);
	end)
end

-- verify nickname and avatar CCS info
-- if no nickname and avatar CCS infomation is filled, remind the user to choose a permernent nickname and avatar
function UserLoginProcess.Proc_VerifyNickName()
	UserLoginProcess.ShowProgress("正在获取人物信息");
	-- send log information
	paraworld.PostLog({action = "user_login_process_stage_progress", msg="Proc_VerifyNickName"}, "user_login_process_stage_progress_log", function(msg)	end);
	
	System.App.profiles.ProfileManager.GetUserInfo(System.User.nid, "Proc_VerifyNickName", function(msg)
		if(msg == nil or not msg.users or not msg.users[1]) then
			LOG.std("", "error","Login", msg);
			UserLoginProcess.Fail("获取人物信息失败，请稍候再试");
			-- send log information
			paraworld.PostLog({action = "user_login_process_stage_fail", msg = "Proc_VerifyNickName_invalid_userinfo"}, 
				"user_login_process_stage_fail_log", function(msg)
			end);
			return;
		end
		
		local nickname = msg.users[1].nickname;
		if(nickname == nil or nickname == "") then
			System.User.NickName = "匿名";
			MainLogin:user_login_next_step({IsNickNameVerified = true});
		else
			System.User.NickName = nickname;
			MainLogin:user_login_next_step({IsNickNameVerified = true});
		end
	end, "access plus 0 day", 5000, function(msg)
		-- timeout request
		UserLoginProcess.Fail("获取人物信息失败，请稍候再试");
		-- send log information
		paraworld.PostLog({action = "user_login_process_stage_fail", msg = "Proc_VerifyNickName_timed_out"}, 
			"user_login_process_stage_fail_log", function(msg)
		end);
	end)
end

function UserLoginProcess.Proc_VerifyFamilyInfo()
	MainLogin:user_login_next_step({IsFamilyInfoVerified = true});
end

function UserLoginProcess.Proc_VerifyServerObjects()
	MainLogin:user_login_next_step({IsServerObjectsVerified = true});
end

function UserLoginProcess.Proc_SyncGlobalStore()
	UserLoginProcess.ShowProgress("正在同步物品描述");
	
	NPL.load("(gl)script/apps/Aries/Items/item.addonlevel.lua");
	local addonlevel = commonlib.gettable("MyCompany.Aries.Items.addonlevel");
	addonlevel.init();

	NPL.load("(gl)script/apps/Aries/Items/item_event.lua");
	local item_event = commonlib.gettable("MyCompany.Aries.Items.item_event");
	item_event.init();

	-- send log information
	paraworld.PostLog({action = "user_login_process_stage_progress", msg="Proc_SyncGlobalStore"}, "user_login_process_stage_progress_log", function(msg)
	end);
	
	-- read gsid region from config file
	local filename = "config/Aries/GlobalStore.IDRegions.xml";

	if(System.options.version == "teen") then
		filename = "config/Aries/GlobalStore.IDRegions.teen.xml";
	end

	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(not xmlRoot) then
		LOG.std("", "error", "Login", "error: failed loading GlobalStore.IDRegions config file: %s, using default", filename);
		-- use default config file xml root
		xmlRoot = 
		{
		  {
			{
			  attr={ from=999, to=999 },
			  n=1,
			  name="region" 
			},
			n=1,
			name="gsidregions" 
		  },
		  n=1 
		};
	end
	
	local gsidRegions = {};
	local node;
	for node in commonlib.XPath.eachNode(xmlRoot, "/gsidregions/region") do
		if(node.attr and node.attr.from and node.attr.to and (not node.attr.version or node.attr.version==System.options.version)) then
			table.insert(gsidRegions, {tonumber(node.attr.from), tonumber(node.attr.to)});
		end
	end
	
	-- TODO: global store regions are read from the GetServerList file
	-- TODO: we can also specify some of the regions are newly modified, with a cache policy 
	
	-- direct gsid regions are deprecated and switch to xml config
	--local gsidRegions = {
		--{998, 999}, -- user avatar base ccs info
		--{1001, 1215}, -- avatar apparels and hand-held
		--{9001, 9010}, -- character animation
		--{9501, 9504}, -- throwable
		--{10001, 10001}, -- mount pet dragon
		--{10101, 10131}, -- follow pet
		--{11001, 11012}, -- mount pet apparel and base color
		--{15001, 15002}, -- pet animation
		--{16001, 16050}, -- consumable
		--{17001, 17095}, -- collectable
		--{19001, 19003}, -- reading
		--{20001, 20020}, -- medals
		--{21001, 21006}, -- quest related, acinus
		--{21101, 21104}, -- skill levels
		--{30001, 30134}, -- home land items
		--{39101, 39103}, -- homeland template
		--{50001, 50006}, -- quest tags
		--{50010, 50302}, -- quest tags
	--};
	
	local gsidLists = {};
	
	local accum = 0;
	local gsids = "";
	local _, pair;
	for _, pair in ipairs(gsidRegions) do
		local i;
		for i = pair[1], pair[2] do
			accum = accum + 1;
			gsids = gsids..i..",";
			if(accum == 10) then
				gsidLists[gsids] = false;
				accum = 0;
				gsids = "";
			end
		end
	end
	if(gsids ~= "") then
		gsidLists[gsids] = false;
	end
	local i = 0;
	local gsids, hasReplied;
	for gsids, hasReplied in pairs(gsidLists) do
		i = i + 1;
		System.Item.ItemManager.GetGlobalStoreItem(gsids, "Proc_SyncGlobalStore_", function(msg)
			-- TODO: we don't care if the globalstore item templates are really replied, response is success
			--		for more unknown item templates please refer to Item_Unknown for late item visualization or manipulation
			-- NOTE: global store item can be directly accessed from memory by ItemManager.GetGlobalStoreItemInMemory(gsid);
			gsidLists[gsids] = true;
			local allReplied = true;
			local _, bReply;
			for _, bReply in pairs(gsidLists) do
				if(bReply == false) then
					allReplied = false;
					break;
				end
			end
			if(allReplied == true) then
				paraworld.globalstore.SaveToFile();
				NPL.load("(gl)script/apps/Aries/Items/item.property.lua");
				local addonproperty = commonlib.gettable("MyCompany.Aries.Items.addonproperty");
				addonproperty.init();

				-- init the card key and gsid mapping
				NPL.load("(gl)script/apps/Aries/Combat/main.lua");
				MyCompany.Aries.Combat.Init_OnGlobalStoreLoaded();

				if(System.options.version == "teen") then
					System.Item.ItemManager.RedirectAllGlobalStoreIconPath();
				end

				System.Item.ItemManager.GetAllGSObtainCntInTimeSpan(function(bSucceed)
					if(bSucceed) then
						MainLogin:user_login_next_step({IsGlobalStoreSynced = true});
					else
						UserLoginProcess.Fail("同步物品获得记数失败了，请稍候再试");
						-- send log information
						paraworld.PostLog({action = "user_login_process_stage_fail", msg = "Proc_SyncGlobalStore_gsobtainintimespan_fail"}, 
							"user_login_process_stage_fail_log", function(msg)
						end);
					end
				end, "access plus 0 day", 25000, function(msg)
					-- timeout request
					UserLoginProcess.Fail("同步物品获得记数失败了，请稍候再试");
					-- send log information
					paraworld.PostLog({action = "user_login_process_stage_fail", msg = "Proc_SyncGlobalStore_gsobtainintimespan_timedout"}, 
						"user_login_process_stage_fail_log", function(msg)
					end);
				end);
			end
		end, "access plus 1 year", 25000, function(msg)
			-- timeout request
			UserLoginProcess.Fail("同步物品描述失败了，请稍候再试");
		end)
	end


	--MainLogin:user_login_next_step({IsGlobalStoreSynced = true});
end

function UserLoginProcess.Proc_SyncExtendedCost()
	UserLoginProcess.ShowProgress("正在同步物品兑换描述");
	
	-- send log information
	paraworld.PostLog({action = "user_login_process_stage_progress", msg="Proc_SyncExtendedCost"}, "user_login_process_stage_progress_log", function(msg)
	end);
	
	-- uncomment to skip this step
	-- MainLogin:user_login_next_step({IsExtendedCostSynced = true});
	-- do return end
	
	-- read extended cost id region from config file
	local filename = "config/Aries/ExtendedCost.IDRegions.xml";
	
	if(System.options.version == "teen") then
		filename = "config/Aries/ExtendedCost.IDRegions.teen.xml";
	end

	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(not xmlRoot) then
		commonlib.log("error: failed loading ExtendedCost.IDRegions config file: %s, using default\n", filename);
		-- use default config file xml root
		xmlRoot = 
		{
		  {
			{
			  attr={ from=1, to=1 },
			  n=1,
			  name="region" 
			},
			n=1,
			name="exidregions" 
		  },
		  n=1 
		};
	end
	
	local exidRegions = {};
	local node;
	for node in commonlib.XPath.eachNode(xmlRoot, "/exidregions/region") do
		if(node.attr and node.attr.from and node.attr.to  and (not node.attr.version or node.attr.version==System.options.version)) then
			table.insert(exidRegions, {tonumber(node.attr.from), tonumber(node.attr.to)});
		end
	end
	
	-- direct extendedcost regions are deprecated and switch to xml config
	--local exidRegions = {
		--{1, 403}, 
	--};
	
	local exidLists = {};
	
	local accum = 0;
	local _, pair;
	for _, pair in ipairs(exidRegions) do
		local i;
		for i = pair[1], pair[2] do
			exidLists[i] = false;
		end
	end
	
	local i = 0;
	local exid, hasReplied;
	for exid, hasReplied in pairs(exidLists) do
		i = i + 1;
		System.Item.ItemManager.GetExtendedCostTemplate(exid, "Proc_SyncExtendedCostTemplate", function(msg)
			-- TODO: we don't care if the ExtendedCost templates are really replied, response is success
			-- NOTE: global store item can be directly accessed from memory by ItemManager.GetExtendedCostTemplateInMemory(gsid);
			exidLists[exid] = true;
			local allReplied = true;
			local _, bReply;
			for _, bReply in pairs(exidLists) do
				if(bReply == false) then
					allReplied = false;
					break;
				end
			end
			if(allReplied == true) then
				paraworld.extendedcost.SaveToFile();
				MainLogin:user_login_next_step({IsExtendedCostSynced = true});
			end
		end, "access plus 1 year", 20000, function(msg)
			-- timeout request
			UserLoginProcess.Fail("正在同步物品兑换描述，请稍候再试");
		end)
	end
	--MainLogin:user_login_next_step({IsExtendedCostSynced = true});
end

function UserLoginProcess.Proc_VerifyInventory()
	UserLoginProcess.ShowProgress("正在获取物品信息");
	
	-- send log information
	paraworld.PostLog({action = "user_login_process_stage_progress", msg="Proc_VerifyInventory"}, "user_login_process_stage_progress_log", function(msg)
	end);
	
	local Start_Percent = UserLoginProcess.percentage;
	
	System.Item.ItemManager.GetItemsInAllBags(nil, function(bSucceed)
		if(bSucceed) then
			-- after downloading current user inventory, verify user avatar
			MainLogin:user_login_next_step({IsInventoryVerified = true});
		else
			-- UserLoginProcess.ShowProgress("无法从服务器获取物品信息, 可能服务器正忙, 请稍候再试.");
			-- NOTE: for offline mode, proceed anyway. Find a better way, since this could be Online mode error as well.
			--log("GetItemsInAllBags: failed. Proceed to offline mode anyway. \n")
			--MainLogin:user_login_next_step({IsInventoryVerified = true});
			UserLoginProcess.Fail("获取物品信息失败，请稍候再试");
			-- send log information
			paraworld.PostLog({action = "user_login_process_stage_fail", msg = "Proc_VerifyInventory_fail"}, 
				"user_login_process_stage_fail_log", function(msg)
			end);
			return;
		end
	end, "access plus 0 day", 30000, function(msg)
		-- timeout request
		UserLoginProcess.Fail("获取物品信息失败，请稍候再试");
		-- send log information
		paraworld.PostLog({action = "user_login_process_stage_fail", msg = "Proc_VerifyInventory_timedout"}, 
			"user_login_process_stage_fail_log", function(msg)
		end);
	end, function(msg)
		if(msg.finished_count and msg.total_count) then
			UserLoginProcess.ShowProgress(string.format("正在获取物品信息: %d/%d", msg.finished_count, msg.total_count), Start_Percent + math.floor(10*msg.finished_count / msg.total_count));
		end
	end); -- added a cache policy that will always get the inventory data
	--MainLogin:user_login_next_step({IsInventoryVerified = true});
end

function UserLoginProcess.Proc_VerifyEssentialItems()
	UserLoginProcess.ShowProgress("正在同步基础物品");
	-- TODO: paracraft related essential items initialization goes here. 

	MainLogin:user_login_next_step({IsEssentialItemsVerified = true});
end

function UserLoginProcess.Proc_VerifyPet()
	MainLogin:user_login_next_step({IsPetVerified = true});
end

function UserLoginProcess.Proc_VerifyVIPItems()
	MainLogin:user_login_next_step({IsVIPItemsVerified = true});
end

function UserLoginProcess.Proc_VerifyFriends()
	MainLogin:user_login_next_step({IsFriendsVerified = true});
end

function UserLoginProcess.Proc_InitJabber()
	MainLogin:user_login_next_step({IsJabberInited = true});
end

function UserLoginProcess.Proc_CleanCache()
	MainLogin:user_login_next_step({IsCleanCached = true});
end

function UserLoginProcess.Proc_SelectWorldServer()
	-- here we just connect to the first server found. 
	System.User.gs_nid = System.User.gs_nid or 1001;
	System.User.ws_id = System.User.ws_id or 1;

	MainLogin:user_login_next_step({IsWorldServerSelected = true});
end
