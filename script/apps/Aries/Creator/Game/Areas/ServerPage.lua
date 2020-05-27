--[[
Title: ServerPage
Author(s): LiPeng
Date: 2014/8/26
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ServerPage.lua");
local ServerPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.ServerPage");
ServerPage.ShowPage()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetworkMain.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ServerManager.lua");
local ServerManager = commonlib.gettable("MyCompany.Aries.Game.Network.ServerManager");
local NetworkMain = commonlib.gettable("MyCompany.Aries.Game.Network.NetworkMain");

local ServerPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.ServerPage");

local page;

ServerPage.server_name = "";
ServerPage.server_creator = "";
ServerPage.server_detail = "";
ServerPage.server_ip = nil;
ServerPage.server_info = {};
--ServerPage.server_mode = 1;

ServerPage.serverRepeat_ds = {
    {text=L"创建服务器", name="create", tooltip=""},
	{text=L"加入服务器", name="joinin", tooltip=L"快捷键: Esc键"},
    --{text="设置", name="settings", tooltip=""},
}

ServerPage.serverRepeat_index = 1;
ServerPage.select_user_index = 1;
ServerPage.maxPlayerNonVip = 3;

local needRefreshUserDS = true;
local passwordList;
local netClientHandler;
local user_ds = {};

function ServerPage.OnInit()
	page = document:GetPageCtrl();
	if(ServerPage.HasCreateServer()) then
		local serverManager = NetworkMain:GetServerManager();
		passwordList = serverManager.passwordList;
		needRefreshUserDS = true;
	end
	local serverManager = ServerManager.GetSingleton();
	if(serverManager) then
		page:SetValue("MaxPlayers", serverManager:GetMaxPlayerCount())
		page:SetValue("BasicAuthMethod", serverManager:GetBasicAuthMethod())
		page:SetValue("room_password", serverManager:GetUniversalPassword() or "")
	end
end

-- @param bRefreshPage: false to stop refreshing the page
function ServerPage.OnChangeCategory(index, bRefreshPage)
    index = index or EscFramePage.category_index;
	
	local category = EscFramePage.category_ds[index];
	if(category) then
		if(category.name == "resume") then
			page:CloseWindow();
			return;
		end
	end
	EscFramePage.category_index = index;
    
	if(bRefreshPage~=false and page) then
		page:Refresh(0.01);
	end
end

function ServerPage.ShowPage()
	GameLogic.CheckSignedIn(
		L"此功能需要登陆后才能使用",
		function(result)
			if (result) then
				local params = {
						url = "script/apps/Aries/Creator/Game/Areas/ServerPage.html", 
						name = "ServerPage.ShowPage", 
						isShowTitleBar = false,
						DestroyOnClose = true,
						bToggleShowHide=true, 
						style = CommonCtrl.WindowFrame.ContainerStyle,
						allowDrag = true,
						enable_esc_key = true,
						--bShow = bShow,
						click_through = false, 
						zorder = -1,
						app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
						directPosition = true,
							align = "_ct",
							x = -600/2,
							y = -400/2,
							width = 600,
							height = 400,
					};
				System.App.Commands.Call("File.MCMLWindowFrame", params);
			end
		end
	)
end

function ServerPage.ShowAddUserPage()
	local params = {
			url = "script/apps/Aries/Creator/Game/Areas/AddServerNewUser.html", 
			name = "ServerPage.AddServerNewUser", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=true, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			--bShow = bShow,
			click_through = false, 
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -270/2,
				y = -160/2,
				width = 270,
				height = 160,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ServerPage.ShowUserLoginPage(netClientHandler,info)
	ServerPage.netClientHandler = netClientHandler;
	ServerPage.server_info = info;
	ServerPage.server_name = info.name;
	ServerPage.server_creator = info.creator;
	ServerPage.server_detail = info.detail;
	ServerPage.server_ip = info.ip;
	ServerPage.server_BasicAuthMethod = info.BasicAuthMethod;
	local params = {
			url = "script/apps/Aries/Creator/Game/Areas/ServerLogin.html", 
			name = "ServerPage.ServerLogin", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=true, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			--bShow = bShow,
			click_through = false, 
			zorder = 1999,
			--app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -400/2,
				y = -300/2,
				width = 400,
				height = 300,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ServerPage.HasCreateServer()
	return NetworkMain:IsServerStarted();
end

function ServerPage.CreateServer(host,port)
	ServerPage.server_name = page:GetValue("text_server_name_create", "");
	if(ServerPage.server_name == "") then
		_guihelper.MessageBox(L"服务器名称不能为空");
		return;
	end
	ServerPage.server_creator = page:GetValue("text_server_creator_create", "");
	if(ServerPage.server_creator == "") then
		_guihelper.MessageBox(L"服务器创建者不能为空");
		return;
	end
	ServerPage.server_detail = ""
	local tunnelServerAddress = page:GetValue("TunnelServerAddress", "");
	local maxPlayers = tonumber(page:GetValue("MaxPlayers")) or 3;
	local netWorkMode = page:GetValue("NetWorkMode", "Lan");

	if(maxPlayers > ServerPage.maxPlayerNonVip) then
		GameLogic.IsVip("Lan40PeopleOnline", false, function(result)
			if (not result) then
				maxPlayers = ServerPage.maxPlayerNonVip;
				local serverManager = ServerManager.GetSingleton();
				if(serverManager) then
					serverManager:SetMaxPlayerCount(maxPlayers)
					if(page) then
						page:SetValue("MaxPlayers", maxPlayers);
					end
				end
				GameLogic.AddBBS("vip", L"非VIP用户, 人数上限为"..ServerPage.maxPlayerNonVip, 16000, "255 0 0")
			end
		end)
	end

	if(not System.User.internet_ip) then
		--ServerPage.GetInternetIP();	
	end
	
	ServerPage.SetServerUrl(nil)
	if(netWorkMode == "Lan") then
		NetworkMain:StartServer(host, port);
	elseif(netWorkMode == "TunnelServer") then
		local tunnelHost, tunnelPort = tunnelServerAddress:match("([^:%s]+)[:%s]?(%d*)");
		if(tunnelHost~="" and tunnelHost) then
			if(tunnelPort == "") then
				tunnelPort = nil;
			end
			local room_key = ServerPage.server_creator or "none";
			
			NetworkMain:StartServerViaTunnel(tunnelHost, tunnelPort, room_key);
			local serverUrl = ServerPage.AutoSetServerUrl(tunnelHost, tunnelPort, room_key) or ""
			LOG.std(nil, "info", "ServerPage", "start via tunnel %s", serverUrl);
			_guihelper.MessageBox(L"服务器地址".."<br/>"..ServerPage.GetServerUrlTip());
			ServerPage.CopyIPToClipboard(serverUrl)
		end
	else
		-- TODO: unknown mode
	end

	page:Refresh(1);

	GameLogic.IsVip("OnlineTeaching", false, function(result)
		if result then
			GameLogic.RunCommand("/menu online.teacher_panel");
		end
	end);
end

function ServerPage.GetServerUrl()
	return ServerPage.serverUrl;
end

-- such as "t1.tunnel.keepwork.com:8099@test"
function ServerPage.AutoSetServerUrl(tunnelHost, tunnelPort, room_key)
	local serverUrl
	if(room_key and room_key~="") then
		serverUrl = string.format("%s:%s@%s", tunnelHost, tunnelPort, room_key);
	else
		serverUrl = string.format("%s:%s", tunnelHost, tunnelPort);
	end
	ServerPage.SetServerUrl(serverUrl);
	return serverUrl
end


function ServerPage.SetServerUrl(url)
	ServerPage.serverUrl =  url;
end

function ServerPage.CopyIPToClipboard(ip)
    ParaMisc.CopyTextToClipboard(ip);
    NPL.load("(gl)script/ide/TooltipHelper.lua");
    local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
    BroadcastHelper.PushLabel({id="treasuretip", label = format(L"IP地址 %s 复制到剪切板", ip), max_duration=5000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
end

function ServerPage.GetInternetIP()
	if(System.User.internet_ip) then
		return;
	end
	if(System.options.mc) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Login/MainLogin.lua");
		local MainLogin = commonlib.gettable("MyCompany.Aries.Game.MainLogin");
		MainLogin.connect_server = true;
		MainLogin:connect_server_next_step(state_update);
	else
		NPL.load("(gl)script/apps/GameServer/GSL_version.lua");
		local GSL_version = commonlib.gettable("Map3DSystem.GSL.GSL_version");
		local from_time = ParaGlobal.timeGetTime();
		-- send log information
		paraworld.auth.Ping({ver=GSL_version.ver}, "checkversion", function(msg)
			LOG.std(nil, "system", "login", "check version %s", commonlib.serialize_compact(msg));
			if(msg) then
				if(msg.ver == GSL_version.ver) then
					local ip = msg.ip;
					if(ip) then
						System.User.internet_ip = ip;
					end
				end
			end
		end, "access plus 0 day", 10000, function(msg) end);
	end
end

function ServerPage.GetAllIPAddress()
	local self = ServerPage;
	if(not self.ips) then
		local port = NPL.GetAttributeObject():GetField("HostPort", "");
		local ips = {};
		self.ips = ips;
		local function addIP_(ip)
			if(ip and ip~="" and ip~="127.0.0.1"  and ip~="localhost") then
				ips[#ips+1] = {text=format("%s:%s", ip, port)};	
			end
		end
		addIP_(NPL.GetExternalIP())
		addIP_(NPL.GetAttributeObject():GetField("HostIP", ""))
	end
	return self.ips;
end

function ServerPage.GetIP()
	NPL.load("(gl)script/ide/System/localserver/URLResourceStore.lua");
	local get_ip_urls = {"http://pv.sohu.com/cityjson","http://20140507.ip138.com/ic.asp"};

	
	local function get_ip_by_visit_url(urls,url_index)
		local index = url_index or 1;
		local url = urls[index];

		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			ls:GetURL(System.localserver.CachePolicy:new("access plus 10 minutes"), url,
				function(msg)
					if(type(msg) == "table" and msg.rcode == 200) then
						ServerPage.server_ip = string.match(msg.data,"%d+.%d+.%d+.%d+");
					end
					if(not ServerPage.server_ip and index < #urls) then
						get_ip_by_visit_url(urls,index + 1);
					end
					if(ServerPage.server_ip) then
						page:Refresh(0.01);
					end
				end);
		end
		
	end

	if(not ServerPage.server_ip) then
		get_ip_by_visit_url(get_ip_urls);
	end
	return ServerPage.server_ip;
	--if(not ServerPage.server_ip) then
		--ServerPage.server_ip = System.User.internet_ip;
	--end
	--if(ServerPage.server_ip == nil) then
		--return nil;
	--elseif(type(ServerPage.server_ip) == "string") then
		--return ServerPage.server_ip;
	--else
		--return nil;
	--end
	--return if_else(type(ServerPage.server_ip) == "string",System.User.internet_ip,nil);
end

function ServerPage.RefreshUserDS()
	user_ds = {};
	local serverManager = ServerManager.GetSingleton();
	if(serverManager) then
		passwordList = serverManager.passwordList;
		local password_map = passwordList.password_map
	
		--echo(password_map);
		if(password_map) then
			local username,password;	
			for username,password in pairs(password_map) do
				user_ds[#user_ds + 1] = {username = username, password = password, beAddUser = false};
			end
			needRefreshUserDS = false;
		end
	end
end

function ServerPage.GetUserDS()
--echo(user_ds);
	if(not next(user_ds) or needRefreshUserDS) then
		ServerPage.RefreshUserDS();
	end
	--echo(user_ds);
	if((not next(user_ds)) or (not user_ds[#user_ds]["beAddUser"])) then
		user_ds[#user_ds + 1] = {beAddUser = true};
	end
	return user_ds;
end

function ServerPage.AddUser(username,password)
	table.insert(user_ds,#user_ds,{username = username, password = password, beAddUser = false});
	--user_ds[#user_ds - 1] = {username = username, password = password, beEmptyUser = false, beAddUser = false}
	--echo(user_ds);
	--table.insert(user_ds,#user_ds,{beEmptyUser = true, beAddUser = false});
	passwordList:AddUser(username, password);
	page:Refresh(0.01);
end

function ServerPage.RemoveUser()
	local username = user_ds[ServerPage.select_user_index]["username"];
	local text = string.format(L"确定删除用户：【%s】吗<br/>删除后不能在使用该用户登录服务器。",username);
	_guihelper.MessageBox(text,function (result)
		if(result == _guihelper.DialogResult.Yes) then
			table.remove(user_ds,ServerPage.select_user_index);
			passwordList:RemoveUser(username);
			page:Refresh(0.01);		
		else
			return;
		end
	end,_guihelper.MessageBoxButtons.YesNo);
end

function ServerPage.IsServer()
	if(NetworkMain:IsServerStarted()) then
		return true;
	else
		return false;
	end
end

function ServerPage.IsClient()
	if(NetworkMain.isClient) then
		return true;
	else
		return false;
	end
end

function ServerPage.ResetClientInfo()
	ServerPage.server_name = "";
	ServerPage.server_creator = "";
	ServerPage.server_detail = "";
	ServerPage.server_ip = nil;
	ServerPage.server_info = {};
end

function ServerPage.UserLogin(username, password)
	ServerPage.netClientHandler:SendLoginPacket(username, password);
end

--ServerPage.server_name = "";
--ServerPage.server_creator = "";
--ServerPage.server_detail = "";
function ServerPage.GetServerInfo()
	local serverInfo = {name = ServerPage.server_name, creator = ServerPage.server_creator, ip = ServerPage.server_ip, detail = ServerPage.server_detail};
	return serverInfo;
end

function ServerPage.OnChangeMaxPlayers(name, value)
	value = tonumber(value)
	local serverManager = ServerManager.GetSingleton();

	if(serverManager and value) then
		GameLogic.IsVip("Lan40PeopleOnline", false, function(result)
			if (not result) then
				if(value > ServerPage.maxPlayerNonVip) then
					value = ServerPage.maxPlayerNonVip;
					if(page) then
						page:SetValue("MaxPlayers", value);
					end
					GameLogic.AddBBS("vip", L"非VIP用户, 人数上限为"..ServerPage.maxPlayerNonVip, 16000, "255 0 0")
				end
		
				LOG.std(nil, "info", "ServerPage", "max player set to %d", value);	
				serverManager:SetMaxPlayerCount(value);
			else
				LOG.std(nil, "info", "ServerPage", "max player set to %d", value);	
				serverManager:SetMaxPlayerCount(value);
			end
		end)
	end
end

function ServerPage.OnClickBasicAuthMethod(value)
	local serverManager = ServerManager.GetSingleton();
	if(serverManager and value) then
		LOG.std(nil, "info", "ServerPage", "BasicAuthMethod to %s", value);	
		serverManager:SetBasicAuthMethod(value);
	end
end

function ServerPage.OnChangeRoomPassword()
	local serverManager = ServerManager.GetSingleton();
	if(serverManager and page) then
		serverManager:SetUniversalPassword(page:GetValue("room_password") or "");
	end
end

function ServerPage.GetServerUrlTip()
	local url = ServerPage.GetServerUrl()
	if(url and url~="") then
		local shortUrl = url:gsub("^t1.tunnel.keepwork.com:8099", "");
		if(shortUrl ~= url) then
			url = format(L"%s 或 %s", shortUrl, url);
		end
	end
	return url;
end


function ServerPage.onClickGetPublicIP()
	ParaGlobal.ShellExecute("open", L"https://keepwork.com/official/docs/tutorials/server_with_public_ip", "", "", 1)
end