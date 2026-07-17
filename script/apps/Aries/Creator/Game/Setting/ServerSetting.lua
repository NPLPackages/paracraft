--[[
Title: Server Setting
Author: pbb copy form serverpage.lua and server.lua
CreateDate: 2023.07.11
Desc: 
use the lib:
------------------------------------------------------------
local ServerSetting = NPL.load('(gl)script/apps/Aries/Creator/Game/Setting/ServerSetting.lua')
ServerSetting.ShowPage()
------------------------------------------------------------
]]

-- libs
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetworkMain.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ServerManager.lua");
local ServerManager = commonlib.gettable("MyCompany.Aries.Game.Network.ServerManager");
local NetworkMain = commonlib.gettable("MyCompany.Aries.Game.Network.NetworkMain");
local SocketService = commonlib.gettable('Mod.WorldShare.service.SocketService')
local LuaCallbackHandler = NPL.load("(gl)script/ide/PlatformBridge/LuaCallbackHandler.lua");
local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand")
--- service
local KeepworkServiceProject = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua")

local page
local ServerSetting = NPL.export()

ServerSetting.server_name = "";
ServerSetting.server_creator = "";
ServerSetting.server_detail = "";
ServerSetting.server_ip = nil;
ServerSetting.server_info = {};
ServerSetting.server_model = ""

ServerSetting.serverRepeat_index = 1;
ServerSetting.select_user_index = 1;
ServerSetting.maxPlayerNonVip = 40;

local udp_server_list = {
    {
        delay="1",
        ip="10.27.1.116",
        password="",
        playerCount=1,
        port=8100,
        serverName="deng001",
        username="deng123458",
        uuid="bddceb4e-3657-4878-bbaa-f8df8d03a7d8" 
    },
    {
        delay="1",
        ip="10.27.1.116",
        password="",
        playerCount=1,
        port=8100,
        serverName="deng001",
        username="deng123458",
        uuid="bddceb4e-3657-4878-bbaa-f8df8d03a7d8" 
    } ,
    {
        delay="1",
        ip="10.27.1.116",
        password="",
        playerCount=1,
        port=8100,
        serverName="deng001",
        username="deng123458",
        uuid="bddceb4e-3657-4878-bbaa-f8df8d03a7d8" 
    } ,
    {
        delay="1",
        ip="10.27.1.116",
        password="",
        playerCount=1,
        port=8100,
        serverName="deng001",
        username="deng123458",
        uuid="bddceb4e-3657-4878-bbaa-f8df8d03a7d8" 
    } ,{
        delay="1",
        ip="10.27.1.116",
        password="",
        playerCount=1,
        port=8100,
        serverName="deng001",
        username="deng123458",
        uuid="bddceb4e-3657-4878-bbaa-f8df8d03a7d8" 
    }  
}

ServerSetting.tabview_ds = {
    {text=L"局域网", name="lan",  enabled=true},
    {text=L"历史记录", name="histroy",  enabled=true},
    {text=L"本机服务", name="local",  enabled=true},
}
ServerSetting.select_tab_index = 1
ServerSetting.local_server_index = 1
ServerSetting.select_server_index = -1
ServerSetting.history_server_list={}

function ServerSetting.SetTestData()
    Mod.WorldShare.Store:Set('user/udpServerList', udp_server_list)
end

function ServerSetting.OnInit()
    page = document:GetPageCtrl()
end

function ServerSetting.ShowPage()
    if GameLogic.GetFilters():apply_filters('is_signed_in') then
        ServerSetting.CheckUserAuth()
        return
    end

    GameLogic.GetFilters():apply_filters('check_signed_in', L"请先登录", function(result)
        if result == true then
            commonlib.TimerManager.SetTimeout(function()
                ServerSetting.CheckUserAuth()
            end, 1000)
        end
    end)
end

function ServerSetting.CheckUserAuth(call_back_func)
    if false then
        GameLogic.IsVip("MultiPlayerNetwork", false, function(result)
            if (not result) then
                GameLogic.AddBBS("vip", L"不可使用联网服务", 16000, "255 0 0")
            else
                if call_back_func and type(call_back_func) == "function" then
                    call_back_func()
                    return
                end
                ServerSetting.ShowView()
            end
        end)
    else
        if call_back_func and type(call_back_func) == "function" then
            call_back_func()
            return
        end
        ServerSetting.ShowView()
    end
end

--获得自己开的服务器的信息，发送给其他的客户端
function ServerSetting.GetServerStatus()
    local stats = ServerManager.GetSingleton():GetStats(true);
    return stats
end

function ServerSetting.GetServerPlayerCount()
    return ServerManager.GetSingleton():GetPlayerCount()
end

function ServerSetting.GetServerPassword()
    return ServerManager.GetSingleton():GetUniversalPassword()
end

function ServerSetting.OnChangeRoomPassword()
    local serverManager = ServerManager.GetSingleton();
	if(serverManager and page) then
        local room_password = page:GetValue("text_server_password")
		serverManager:SetUniversalPassword(room_password or "");
	end
end

function ServerSetting.ShowView()
    ServerSetting.select_tab_index = 1
    ServerSetting.local_server_index = ServerSetting.IsServer() and 2 or 1
    ServerSetting.select_server_index = -1
    ServerSetting.LoadServerHistory()
    local view_width = 510
    local view_height = 390
    local params = {
        url = "script/apps/Aries/Creator/Game/Setting/ServerSetting.html",
        name = "ServerSetting.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        directPosition = true,
        cancelShowAnimation = true,
        align = "_ct",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    params = GameLogic.GetFilters():apply_filters('GetUIPageHtmlParam', params, "ServerSetting");
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    ServerSetting.StartUDPServer()
    ServerSetting.GetOnlineList()
    if not ServerSetting.register then
        GameLogic.GetFilters():add_filter("ConnectServer", ServerSetting.ConnectServer);
        GameLogic.GetFilters():add_filter("exit_world_server", ServerSetting.ExitWorldServer);
        -- GameLogic.GetFilters():add_filter("OnKeepWorkLogin", ServerSetting.OnKeepWorkLogin_Callback);
	    GameLogic.GetFilters():add_filter("OnKeepWorkLogout", ServerSetting.OnKeepWorkLogout_Callback)
        ServerSetting.register = true
    end
end

function ServerSetting.ShowUserLoginPage(netClientHandler,info)
	ServerSetting.netClientHandler = netClientHandler;
	ServerSetting.server_BasicAuthMethod = info.BasicAuthMethod;
	local params = {
			url = "script/apps/Aries/Creator/Game/Setting/ServerLogin.html", 
			name = "ServerSetting.ServerLogin", 
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

function ServerSetting.UserLogin(username, password)
    if ServerSetting.netClientHandler then
	    ServerSetting.netClientHandler:SendLoginPacket(username, password);
    end
end

function ServerSetting.OnKeepWorkLogout_Callback()
    ServerSetting.ResetClientInfo()
end

function ServerSetting.ExitWorldServer()
    ServerSetting.ResetClientInfo()
end

function ServerSetting.ConnectServer(msg)
    return msg
end

function ServerSetting.OnChangeTabview(index)
    ServerSetting.select_tab_index = tonumber(index);
    ServerSetting.select_server_index = -1
    ServerSetting.RefreshPage()
    ServerSetting.GetOnlineList()
end

function ServerSetting.RefreshPage(delay)
    if page then
        page:Refresh(delay or 0)
    end
end

function ServerSetting.GetNetDelay(ipStr,port,callback)
    if System.os.GetPlatform() == "win32" then
        local ipString = ipStr or "127.0.0.1"
        local cmdStr = "ping "..ipString.." -n 1"
        ParaGlobal.ShellExecute  ("popen",cmdStr,"isAsync",LuaCallbackHandler.createHandler(function(msg)
            local ret = ParaMisc.EncodingConvert("gb2312", "utf-8", msg.ret)
            local delay = string.match(ret,"(%d+)ms") --匹配第一个ms字段
            if callback then
                callback(delay)
            end
        end))
        return 
    end
    if not ipStr or ipStr == "" or not port or port == "" then
        if callback then
            callback(-1)
        end
        return 
    end
    if NPL.Ping(ipStr, tostring(port or 8100), 2000, true) ~= -1 then
        if callback then
            callback(10)
        end
    else
        if callback then
            callback(3000)
        end
    end
end

function ServerSetting.GetSaveKey()
    if ServerSetting.historyKey == nil then
        local userId = GameLogic.GetFilters():apply_filters('store_get', 'user/userId') or "";
        ServerSetting.historyKey = "server_history_"..userId
    end
    return ServerSetting.historyKey
end

function ServerSetting.SaveServerHistory()
    GameLogic.GetPlayerController():SaveRemoteData(ServerSetting.GetSaveKey(),ServerSetting.history_server_list,true);
end

function ServerSetting.LoadServerHistory()
    ServerSetting.history_server_list = GameLogic.GetPlayerController():LoadRemoteData(ServerSetting.GetSaveKey(),{})
end

function ServerSetting.UpdateServerHistory(params)

end

function ServerSetting.OnWorldLoad()

end

function ServerSetting.StartUDPServer()
    if not ServerSetting.mStartServer then
        SocketService:StartUDPService();
        ServerSetting.mStartServer = true
    end
end


function ServerSetting.GetOnlineList()
    if ServerSetting.select_tab_index ~= 1 then
        return
    end
    ServerSetting.seachFinished = false
    ServerSetting.RefreshPage()

    SocketService:SendUDPWhoOnlineMsg()

    Mod.WorldShare.Utils.SetTimeOut(function()
        local udpServerList = Mod.WorldShare.Store:Get('user/udpServerList') or {}
        ServerSetting.UpdateServerDelay(udpServerList,function()
            page:GetNode('udp_server_list'):SetAttribute('DataSource', udpServerList)
            ServerSetting.seachFinished = true
            ServerSetting.RefreshPage()            
        end)
    end, 3000)
end

function ServerSetting.UpdateServerDelay(serverList,callback)
    if serverList and #serverList > 0 then

        local startIndex = 1
        func = function(index)
            if index >#serverList then
                if callback then
                    callback()
                end
                return 
            end
            local ipStr = serverList[index].ip
            local port = serverList[index].port
            ServerSetting.GetNetDelay(ipStr,port,function(delay)
                serverList[index].delay = delay
                startIndex = startIndex + 1
                func(startIndex)
            end)
        end
        func(startIndex)
    else
        if callback then
            callback()
        end
    end
end

function ServerSetting.IsSeachFinished()
    return ServerSetting.seachFinished == true
end

function ServerSetting.Connect(...)
    NetworkMain:Connect(...)
end

function ServerSetting.GetName()
    if not ServerSetting.server_name or ServerSetting.server_name == "" then
        local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
        ServerSetting.server_name = WorldCommon.GetWorldTag("name") or "";
        if not Game.is_started then
            ServerSetting.server_name = "default"
        end
    end
    return ServerSetting.server_name or "default"
end

function ServerSetting.GetCreator()
    ServerSetting.server_creator =(System.User.username and System.User.username ~= "") and System.User.username or "admin"
    return ServerSetting.server_creator
end

function ServerSetting.GetServerModel()
    return ServerSetting.server_model
end

function ServerSetting.GetBasicAuthMethod()
    local serverManager = ServerManager.GetSingleton();
    return serverManager:GetBasicAuthMethod();
end

function ServerSetting.CreateServer()
    local key = "Lan40PeopleOnline"
    if System.options.isEducatePlatform then
        key = "MultiPlayerNetwork"
    end
    if System.options.isCommunity then
        key = "Lan50PeopleOnline"
    end
    local maxPlayerCount = 2
    if not Game.is_started then
        _guihelper.MessageBox(L"请进入世界以后创建联网服务");
        return
    end

    if ServerSetting.IsClient() then
        _guihelper.MessageBox(L"请使用自己的世界创建联网服务");
        return
    end

    if GameLogic.IsReadOnly() then
        _guihelper.MessageBox(L"只读世界不可创建联网服务");
        return 
    end

    GameLogic.IsVip(key, false, function(result)
        local playerCount = 2
        if result then
            playerCount = System.options.isCommunity and 50 or 40
        end
        ServerSetting.CreateServerImpl(playerCount)
    end)
end

function ServerSetting.CreateServerImpl(playerCount)
    local serverManager = ServerManager.GetSingleton();
    ServerSetting.server_name = page:GetValue("text_server_name_create","") --ServerSetting.GetName()
    if(ServerSetting.server_name == "") then
        _guihelper.MessageBox(L"服务器名称不能为空");
        return;
    end

    ServerSetting.server_creator = ServerSetting.GetCreator()
    if(ServerSetting.server_creator == "") then
        _guihelper.MessageBox(L"服务器创建者不能为空");
        return;
    end
    ServerSetting.server_detail = ""
    local tunnelServerAddress = page:GetValue("TunnelServerAddress", "");
    local netWorkMode = page:GetValue("NetWorkMode", "Lan");	
    serverManager:SetMaxPlayerCount(playerCount or 2);
    if page:GetValue("BasicAuthMethod") ~= "Anonymous" then
        serverManager:SetUniversalPassword(page:GetValue("room_password") or "");
    end
    serverManager:SetBasicAuthMethod(page:GetValue("BasicAuthMethod") or "Anonymous");
    
    ServerSetting.SetServerUrl(nil)
    if(netWorkMode == "Lan") then
        NetworkMain:StartServer(host, port);

    elseif(netWorkMode == "TunnelServer") then
        local tunnelHost, tunnelPort = tunnelServerAddress:match("([^:%s]+)[:%s]?(%d*)");
        if(tunnelHost~="" and tunnelHost) then
            if(tunnelPort == "") then
                tunnelPort = nil;
            end
            local room_key = ServerSetting.server_creator or "none";
            
            NetworkMain:StartServerViaTunnel(tunnelHost, tunnelPort, room_key);
            local serverUrl = ServerSetting.AutoSetServerUrl(tunnelHost, tunnelPort, room_key) or ""
            LOG.std(nil, "info", "ServerSetting", "start via tunnel %s", serverUrl);
            _guihelper.MessageBox(L"服务器地址".."<br/>"..ServerSetting.GetServerUrlTip());
            ServerSetting.CopyIPToClipboard(serverUrl)
        end
    end
    ServerSetting.server_model = netWorkMode
    local windowTitle = ParaEngine.GetWindowText();
    ServerSetting.GetAllIPAddress();
    windowTitle = windowTitle .. " 服务器地址: " .. (ServerSetting.serverUrl or ServerSetting.ips[1].text);
    ParaEngine.SetWindowText(windowTitle);
    -- GameLogic.IsVip("OnlineTeaching", false, function(result)
    --     if result then
    --         GameLogic.RunCommand("/menu online.teacher_panel");
    --     end
    -- end);
    ServerSetting.local_server_index = 2
    ServerSetting.RefreshPage(1)
end

function ServerSetting.CopyIPToClipboard(ip)
    ParaMisc.CopyTextToClipboard(ip);
    NPL.load("(gl)script/ide/TooltipHelper.lua");
    local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
    BroadcastHelper.PushLabel({id="treasuretip", label = format(L"IP地址 %s 复制到剪切板", ip), max_duration=5000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
end

function ServerSetting.OnClickNewServer()
    if ServerSetting.select_tab_index ~= 3 then
        ServerSetting.select_tab_index = 3
        ServerSetting.RefreshPage()
    else
        ServerSetting.CreateServer()
    end
end

function ServerSetting.OnClickConnect()
    if ServerSetting.select_server_index == -1 then
        GameLogic.AddBBS(nil,L"请选中需要连接的服务器")
        return
    end
    local serverdata
    if ServerSetting.select_tab_index == 1 then
        local udpServerList = Mod.WorldShare.Store:Get('user/udpServerList') or {}
        serverdata = udpServerList[ServerSetting.select_server_index]
    end
    if ServerSetting.select_tab_index == 2 then
        serverdata = ServerSetting.history_server_list[ServerSetting.select_server_index]
    end
    if serverdata then
        local host = serverdata.ip or "0.0.0.0"
        if serverdata.port and serverdata.port ~= "" then
            host = host..":"..serverdata.port
        end
        ServerSetting.OnClickGotoUrl(host)
    end
end

function ServerSetting.OnClickRefresh()
    if ServerSetting.select_tab_index == 1 then
        ServerSetting.GetOnlineList()
        return
    end
    if ServerSetting.select_tab_index == 2 then
        ServerSetting.RefreshPage()
        return
    end
end

function ServerSetting.OnClickCloseServer()
    ServerSetting.ExitServer()
    ServerSetting.local_server_index = 1
    ServerSetting.RefreshPage()
end

function ServerSetting.ExitServer()
    ServerManager.GetSingleton():Shutdown();
	ParaTerrain.GetBlockAttributeObject():SetField("IsServerWorld", false);
    NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetworkMain.lua");
    NetworkMain:GetServerManager():Shutdown()
    ServerSetting.ResetClientInfo()
    -- local player = GameLogic.EntityManager.GetPlayer()
    -- if(player) then
    --     player:SetHeadOnDisplay(nil)
    -- end
    -- GameLogic.EntityManager.ClearPlayer()
    -- GameLogic.EntityManager.InitPlayers()
    --GameLogic.GetPlayerController():SetMainPlayer(nil)

    GameLogic.options:ResetWindowTitle()
end

function ServerSetting.GetMaxPlayerCount()
    local serverManager = ServerManager.GetSingleton();
    if serverManager then
        local maxPlayerCount = serverManager:GetMaxPlayerCount() or 2;
        return maxPlayerCount
    end
    return  2
end

function ServerSetting.IsServer()
	if(NetworkMain:IsServerStarted()) then
		return true;
	else
		return false;
	end
end

function ServerSetting.IsClient()
	if(NetworkMain.isClient) then
		return true;
	else
		return false;
	end
end

function ServerSetting.IsOpenServer()
    return ServerSetting.IsServer() or ServerSetting.IsClient()
end

function ServerSetting.ResetClientInfo()
	ServerSetting.server_name = "";
	ServerSetting.server_creator = "";
	ServerSetting.server_detail = "";
	ServerSetting.server_ip = nil;
	ServerSetting.server_info = {};
end

function ServerSetting.GetServerInfo()
	local serverInfo = {
        name = ServerSetting.server_name, 
        creator = ServerSetting.server_creator, 
        ip = ServerSetting.server_ip, 
        detail = ServerSetting.server_detail,
        password = ServerSetting.GetServerPassword(),
        playerCount = ServerSetting.GetServerPlayerCount()
    };
	return serverInfo;
end

function ServerSetting.GetInternetIP()
	if(System.User.internet_ip) then
		return;
	end
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

function ServerSetting.GetAllIPAddress()
	local self = ServerSetting;
	if(not self.ips) then
		local port = NPL.GetAttributeObject():GetField("HostPort", "");
		local ips = {};
		self.ips = ips;
		local function addIP_(ip)
			if(ip and ip~="" and ip~="127.0.0.1"  and ip~="localhost") then
				ips[#ips+1] = {text= port == "8099" and ip or format("%s:%s", ip, port)};	
			end
		end
        if System.os.GetPlatform() == "android" then
            local ip = ParaEngine.GetAttributeObject():GetField("MaxIPAddress","")
            if ip and ip~="" then
                addIP_(ip)
            else
                addIP_(NPL.GetExternalIP())
            end
        else
            addIP_(NPL.GetExternalIP())
        end
		
		addIP_(NPL.GetAttributeObject():GetField("HostIP", ""))
	end
    ServerSetting.server_ip = (self.ips or self.ips[1]) and self.ips[1].text or ""
	return self.ips;
end

function ServerSetting.GetServerIp()
    local ip = ""
    if System.os.GetPlatform() == "android" then
        local ip0 = ParaEngine.GetAttributeObject():GetField("MaxIPAddress","")
        if ip0 and ip0~="" then
            ip = ip0
        else
            ip = NPL.GetExternalIP()
        end
    else
        ip = NPL.GetExternalIP()
    end
    if not ip or ip == "" then
        ip = NPL.GetAttributeObject():GetField("HostIP", "")
    end
    return ip
end

function ServerSetting.GetServerUrlTip()
	local url = ServerSetting.GetServerUrl()
	if(url and url~="") then
		local shortUrl = url:gsub("^t1.tunnel.keepwork.com:8099", "");
		if(shortUrl ~= url) then
			url = format(L"%s 或 %s", shortUrl, url);
		end
	end
	return url;
end

function ServerSetting.GetServerUrl()
	return ServerSetting.serverUrl;
end

-- such as "t1.tunnel.keepwork.com:8099@test"
function ServerSetting.AutoSetServerUrl(tunnelHost, tunnelPort, room_key)
	local serverUrl
	if(room_key and room_key~="") then
		serverUrl = string.format("%s:%s@%s", tunnelHost, tunnelPort, room_key);
	else
		serverUrl = string.format("%s:%s", tunnelHost, tunnelPort);
	end
	ServerSetting.SetServerUrl(serverUrl);
	return serverUrl
end


function ServerSetting.SetServerUrl(url)
	ServerSetting.serverUrl =  url;
end

function ServerSetting.onClickGetPublicIP()
	ParaGlobal.ShellExecute("open", L"https://keepwork.com/official/docs/tutorials/server_with_public_ip", "", "", 1)
end

function ServerSetting.OnClickGotoUrl(url)
    if url and url ~= "" then
        local CommonLoadWorld = NPL.load('(gl)Mod/WorldShare/cellar/Common/LoadWorld/CommonLoadWorld.lua')
        CommonLoadWorld.GotoUrl(url)
        ServerSetting.AddConnectHistory(url)
    end
end

function ServerSetting.IsConnectSelf(url)
    local isServer = ServerSetting.IsServer()
    local host, port, relativePath = url:match("^([^:%s]+)[:%s]?(%d*)(.*)");
    if host and host ~= "" and ServerSetting.server_ip == host then
        return true
    end
    return false
end

function ServerSetting.AddConnectHistory(connectUrl)
    if not connectUrl or connectUrl == "" then
        return
    end
    local udpServerList = Mod.WorldShare.Store:Get('user/udpServerList') or {}
    local host, port, relativePath = connectUrl:match("^([^:%s]+)[:%s]?(%d*)(.*)");
    if host and host ~= "" then
        for k,v in pairs(udpServerList) do
            if v.ip == host then
                ServerSetting.AddHistory(v)
            end
        end
    end
    ServerSetting.SaveServerHistory()
end

function ServerSetting.ClearHistory()
    ServerSetting.history_server_list = {}
    ServerSetting.SaveServerHistory()
end

function ServerSetting.AddHistory(data)
    if not data then
        return 
    end
    local isNew = true
    local host = data.ip
    for k,v in pairs(ServerSetting.history_server_list) do
        if v.ip == host then
            ServerSetting.history_server_list[k] = data
            isNew = false
            break
        end
    end

    if isNew then
        local histroy_num = #ServerSetting.history_server_list
        if histroy_num >= 10 then
            for i = histroy_num,2,-1 do
                ServerSetting.history_server_list[i] = ServerSetting.history_server_list[i - 1]
            end
            ServerSetting.history_server_list[1] = data
        else
            -- ServerSetting.history_server_list[#ServerSetting.history_server_list + 1] = data
            table.insert(ServerSetting.history_server_list,1,data)
        end
    end
end

function ServerSetting.IsInServerHistory(host)
    if not host then
        return 
    end
    for k,v in pairs(ServerSetting.history_server_list) do
        if v.ip == host then
            return true
        end
    end
    return false
end





