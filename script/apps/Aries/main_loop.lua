--[[
Title: Main game loop
Author(s): WangTian
Company: ParaEnging Co. & Taomee Inc.
Date: 2009/4/6
Desc: Entry point and game loop
command line params
| *name*| *desc* |
| gateway | force the gateway to use, usually for debugging purposes. such as "1100" |
| url  | from which url, this application is started |
| httpdebug | true for npl http debugger|
| isSchool | true to disable games and url protocol install |
| keepworktoken | |
| resolution | |

e.g. 
<verbatim>
	paraworld.exe username="1100@paraengine.com" password="1100@paraengine.com" servermode="true" d3d="false" chatdomain="192.168.0.233" domain="test.pala5.cn"
	paraworld.exe username="LiXizhi1" password="" gateway="1100"
</verbatim>
use the lib:
------------------------------------------------------------
NPL.activate("(gl)script/apps/Aries/main_loop.lua");
set the bootstrapper to point to this file, see config/bootstrapper.xml
Or run application with command line: bootstrapper = "script/apps/Aries/bootstrapper.xml"
------------------------------------------------------------
]]
-- mainstate is just a dummy to set some ReleaseBuild=true
NPL.load("(gl)script/mainstate.lua"); 
NPL.load("(gl)script/ide/commonlib.lua"); 

-- let us see replace im server if command line contains imserver="game"
local imserver = ParaEngine.GetAppCommandLineByParam("imserver", "game");
if(imserver == "game") then
	NPL.load("(gl)script/apps/IMServer/IMserver_client.lua");
	-- this will replace the default(real) jabber client with the one implemented by our own game server based IM server. Make sure this is done before you use it in the app code.
	JabberClientManager = commonlib.gettable("IMServer.JabberClientManager");
end
NPL.load("(gl)script/kids/ParaWorldCore.lua"); -- ParaWorld platform includes
NPL.load("(gl)script/ide/app_ipc.lua");
-- load paracraft packages if any
if(ParaEngine.GetAppCommandLineByParam("isDevEnv", "") == "" and ParaEngine.GetAppCommandLineByParam("src_paraworldapp", "")=="") then
	NPL.load("npl_packages/paracraft/");
end

if(IPCDebugger) then
	IPCDebugger.Start(); -- enable debugging if there is a command line setting. 
end

-- uncomment this line to display our logo page. 
-- main_state="logo";
-- whether it is server mode, such as under linux without graphics rendering. 
System.options.servermode = ParaEngine.GetAppCommandLineByParam("servermode", "false") == "true";
-- check a secret file for whether it is running from AB. If not, disable some log. 
System.options.isAB_SDK = ParaIO.DoesFileExist("character/Animation/script/dance_drum.lua", false)

System.options.is18_SDK = ParaIO.DoesFileExist("18+.txt", false)

-- Note: set disable trading to true to cancel all trading action temporarily on client side, if one found a trading bug. 
System.options.disable_trading = nil;

local commandLine = ParaEngine.GetAppCommandLine();
-- whether it is mc version
System.options.mc = (ParaEngine.GetAppCommandLineByParam("mc","false") == "true");
if(not System.options.mc and commandLine and commandLine:match("mc=true")) then
	-- just in case it is comming from the website url. 
	System.options.mc = true;
end

System.options.isDevEnv = (ParaEngine.GetAppCommandLineByParam("isDevEnv","false") == "true");
System.options.isDevMode = (ParaEngine.GetAppCommandLineByParam("isDevMode", "false") == "true");

System.options.open_resolution = ParaEngine.GetAppCommandLineByParam("resolution",nil);

System.options.cmdline_world = System.options.cmdline_world or ParaEngine.GetAppCommandLineByParam("world","");

System.options.isCodepku = (ParaEngine.GetAppCommandLineByParam("isCodepku", "false") == "true");

System.User = System.User or {};
if(not System.User.keepworktoken) then
	System.User.keepworktoken = ParaEngine.GetAppCommandLineByParam("keepworktoken",nil);
end

commonlib.setfield("System.options.isFromQQHall", ParaEngine.GetAppCommandLineByParam("isFromQQHall", "") == "true");
if(ParaEngine.GetAppCommandLineByParam("isSchool", "") == "true") then
	commonlib.setfield("System.options.isSchool", true);
end

--System.options.isDevEnv = true;
-- load from config file
local function Aries_load_config(filename)
	-- region id
	local region_id;

	-- language translations
	NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Translation.lua");
	local Translation = commonlib.gettable("MyCompany.Aries.Game.Common.Translation")
	Translation.Init();

	-- where the user from from
	System.options.partner = ParaEngine.GetAppCommandLineByParam("partner", "");
	if(System.options.partner == "") then
		if(System.options.IsWebBrowser) then
			System.options.partner = "web";
		else
			System.options.partner = "desktop";
		end
	end
	System.options.partner = System.options.partner:sub(1,10);

	if(System.options.partner == "qq") then
		-- if partner is qq we will show the qq login page by default. in most cases, it is in window mode. 
		NPL.load("(gl)script/apps/Aries/Partners/PartnerPlatforms.lua");
		local Platforms = commonlib.gettable("MyCompany.Aries.Partners.Platforms");
		System.options.platform_id = Platforms.PLATS.QQ;
		System.options.is_official = true;
	elseif(System.options.partner == "keepwork") then
		NPL.load("(gl)script/apps/Aries/Partners/PartnerPlatforms.lua");
		local Platforms = commonlib.gettable("MyCompany.Aries.Partners.Platforms");
		System.options.platform_id = Platforms.PLATS.KEEPWORK;
	end
	
    
	-- we will enter this world first 
	-- format: "nid@homeland" or "nid@save_slot_id"
	-- example: "1234567@homeland" or "1234567@1"
	System.options.visit_url = ParaEngine.GetAppCommandLineByParam("visit_url", "");
	if(System.options.visit_url == "") then
		System.options.visit_url = nil;
	end
	
	-- current url
	System.options.cur_url = ParaEngine.GetAppCommandLineByParam("cur_url", "");
	LOG.std(nil, "debug", "cur_url", System.options.cur_url);

	-- make rest http 2 worker threads
	System.os.options.SetWorkerThreadsCount(2, 2);

	-- External authentication string. 
	System.options.url = ParaEngine.GetAppCommandLineByParam("url", "");
	if(System.options.url ~="") then
		
		-- such as http://haqi.61.com/webplayer?platid=2144&id=46&time=20130304174349&key=D8D29A48D9CC1B19
		NPL.load("(gl)script/ide/System/localserver/UrlHelper.lua");
		local UrlHelper = commonlib.gettable("System.localserver.UrlHelper");
		local tokens = UrlHelper.url_getparams_table(System.options.url);

		if(tokens) then
			if(not System.options.visit_url and tokens.visit_url) then
				System.options.visit_url = tokens.visit_url;
			end

			-- External authentication string. 
			local has_token;
			if( tokens.id and tokens.key and tokens.time) then
				if(tokens.platid == "2144") then
					tokens.loginplat = 1;
					tokens.plat = 4;
					tokens.from = tokens.plat;
					tokens.token = tokens.key;
					region_id = tokens.plat;
				elseif(tokens.platid == "fungame" or tokens.website == "fungame") then
					tokens.loginplat = 1;
					tokens.plat = 6;
					tokens.from = 6;
					tokens.oid = tokens.id;
					tokens.token = tokens.key;
					tokens.time = tonumber(tokens.time);
					tokens.website = "fungame";
					tokens.game = tokens.game;
					tokens.sid = tokens.sid;
					region_id = 0;
				end
				has_token = true;
			elseif(tokens.platid == "gamagic" or tokens.platid == "thTH" or tokens.platid == "3") then
				has_token = true;
				tokens.loginplat = 1;
				tokens.plat = 3;
				tokens.oid = tokens.userid;
				tokens.token = tokens.token;
				tokens.time = tonumber(tokens.time);
				-- region_id = tokens.plat;
			end
			if(has_token) then
				System.options.login_tokens = tokens;
				System.options.plat = tokens.plat;
				LOG.std(nil, "debug", "login_tokens", System.options.login_tokens)
			end
		end
	end
	if(System.options.isAB_SDK or System.options.isDevEnv)then
		System.options.clientconfig_file = ParaEngine.GetAppCommandLineByParam("config", "");
		if(System.options.clientconfig_file=="") then
			System.options.clientconfig_file = nil;
		else
			LOG.info("using game client config file: %s", System.options.clientconfig_file);
		end
		LOG.SetLogLevel("DEBUG");
	else
		LOG.SetLogLevel("INFO");
	end
	if(System.options.isAB_SDK or System.options.mc)then
		ParaEngine.GetAttributeObject():SetField("IgnoreWindowSizeChange",false);
		LOG.std(nil, "info", "AssetManifest", "use local file first");
		ParaEngine.GetAttributeObject():GetChild("AssetManager"):SetField("UseLocalFileFirst", true);
	end

	if(System.options.mc)then
		-- use paracraft icon file, it can also be any *.ico file on disk
		if (System.options.isCodepku) then			
			ParaEngine.GetAttributeObject():SetField("Icon", "icon.ico");
		else		
			ParaEngine.GetAttributeObject():SetField("Icon", ":IDR_PARAWORLD_ICO");
		end				
	end

	System.options.is_client = true;

	filename = filename or System.options.clientconfig_file or "config/GameClient.config.xml"

	if(not ReleaseBuild) then
		System.options.IsEditorMode = true;
	else
		-- release build: bring window to front. 
		ParaEngine.GetAttributeObject():CallField("BringWindowToTop");
	end

	-- filename = "script/apps/GameServer/test/local.GameClient.config.xml"
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(not xmlRoot) then
		local filename2 = string.lower(filename);
		if(filename2 ~= filename) then
			xmlRoot = ParaXML.LuaXML_ParseFile(filename2);
		end
		if(xmlRoot) then
			LOG.std("", "warning", "aries", "please change %s to %s", filename, filename2);
		else
			LOG.std("", "warning", "aries", "warning: failed loading game client config file %s", filename);
		end
		return;
	end	

	-- we will use the same UI for mobile platform, so always IsMobilePlatform is always false since 2018.3.22  
	-- check if it is running with mobile platform
	-- local IsMobilePlatform = ParaEngine.GetAttributeObject():GetField("IsMobilePlatform", false);
	System.options.IsMobilePlatform = (ParaEngine.GetAppCommandLineByParam("IsMobilePlatform", "false") == "true");
	
	-- check if it is a touch device. we can force it in command line
	local IsTouchDevice = ParaEngine.GetAppCommandLineByParam("IsTouchDevice", "");
	
	if(IsTouchDevice ~= "") then
		-- we can force it in command line
		System.options.IsTouchDevice = IsTouchDevice == "true";
	else
		System.options.IsTouchDevice = ParaEngine.GetAttributeObject():GetField("IsTouchInputting", false);	
	end

	if(System.options.IsTouchDevice) then
		-- NOTE: for now we will disable all system IME and use buildin virtual keyboard where possible. 
		-- System.options.auto_virtual_keyboard = true
	end
	

	-- always use compression. The current compression method is super light-weighted and is mostly for data encrption purposes. 
	-- NPL.SetUseCompression(false, false);
	
	local node;
	local bg_loader_list;
	node = commonlib.XPath.selectNodes(xmlRoot, "/GameClient/config")[1];
	local client_ver_string;
	if(node and node.attr) then
		-- if asset is not found locally, we will look in this place
		if(node.attr.version) then
			client_ver_string = node.attr.version;
		end
		if(node.attr.region) then
			region_id = tonumber(node.attr.region);

            NPL.load("(gl)script/apps/Aries/Partners/PartnerPlatforms.lua");
		    local Platforms = commonlib.gettable("MyCompany.Aries.Partners.Platforms");
            if(Platforms.PLATS and region_id == Platforms.PLATS.KEEPWORK)then
		        System.options.platform_id = region_id;
            end
		end
	end
	local cmdVer = ParaEngine.GetAppCommandLineByParam("version","kids");
	if (not IsMobilePlatform and cmdVer~=client_ver_string and not System.options.isAB_SDK and not System.options.mc) then
		commonlib.echo("==============cmdVer ============== Fail")
		commonlib.echo(cmdVer)
		commonlib.echo(client_ver_string);

		-- try fixing version conflict
		ParaIO.DeleteFile("config/gameclient.config.xml");
		ParaIO.DeleteFile("version.txt");

        _guihelper.MessageBox_Plain("抱歉，您的版本更新有问题！ 我们将尝试为您修复，请点击确定（OK）并重启。 若无法修复，请到官网下载最新客户端重新安装！", function()
            ParaGlobal.ExitApp();
        end, _guihelper.MessageBoxButtons.OK);

		main_state = -1; -- toggle to nil main state
		return;
	end

	-- all platforms.
	System.options.platforms = commonlib.XPath.selectNodes(xmlRoot, "/GameClient/platforms/platform") or {};
	if(not System.options.mc) then
		NPL.load("(gl)script/apps/Aries/Partners/PartnerPlatforms.lua");
		local Platforms = commonlib.gettable("MyCompany.Aries.Partners.Platforms");
		Platforms.Init();
	end

	-- default locale
	System.options.locale = ParaEngine.GetAppCommandLineByParam("locale", "") ;
	if(System.options.locale=="") then
		System.options.locale = "zhCN"
		local localeNode = commonlib.XPath.selectNodes(xmlRoot, "/GameClient/locale") or {};
		if(localeNode[1]) then
			local attr = localeNode[1].attr;
			if(attr) then
				System.options.locale = attr.default;
				-- TODO: call ParaEngine API to set the locale 
			end
		end
	end
	LOG.info("game default locale : %s", System.options.locale);


	-- here we will defaults to kids version. 
	System.options.isKid = ParaEngine.GetAppCommandLineByParam("version", client_ver_string or "kids");
	if(System.options.isKid:match("_mc$")) then
		System.options.isKid = System.options.isKid:gsub("_mc$", "");
		System.options.mc = true;
	end

	-- whether it is the creator version. 
	if(ParaEngine.GetAppCommandLineByParam("mc","false") == "true") then
		System.options.mc = true;
		-- force kids version in mc app.  
		System.options.isKid = "kids"; 
	end

	if(System.options.isKid == "") then
		System.options.isKid = nil;
	else
		System.options.isKid = System.options.isKid == "kids";
	end
	if(System.SystemInfo.GetField("name") == "Taurus") then
		System.options.isKid = true;
	end
	System.options.version = if_else(System.options.isKid, "kids", "teen");

	-- command line region_id will override config region id. 
	if(not System.options.mc) then
		NPL.load("(gl)script/apps/Aries/Login/ExternalUserModule.lua");
		local ExternalUserModule = commonlib.gettable("MyCompany.Aries.ExternalUserModule");
		region_id = tonumber(ParaEngine.GetAppCommandLineByParam("region", tostring(region_id or 0))) or region_id;
		if(ExternalUserModule.Init) then
			ExternalUserModule:Init(nil, region_id);
		end
	end

	local node;
	local bg_loader_list;
	node = commonlib.XPath.selectNodes(xmlRoot, "/GameClient/asset_server_addresses")[1];
	if(node and node.attr) then
		-- if asset is not found locally, we will look in this place
		 bg_loader_list = node.attr.bg_loader_list;
	end
	
	local node;
	node = commonlib.XPath.selectNodes(xmlRoot, "/GameClient/asset_server_addresses/address")[1];
	if(node and node.attr) then
		-- if asset is not found locally, we will look in this place
		ParaAsset.SetAssetServerUrl(node.attr.host);
		LOG.std("", "system", "aries", "Asset server: %s", node.attr.host)
	end
	
	local chat_domain
	node = commonlib.XPath.selectNodes(xmlRoot, "/GameClient/chat_server_addresses")[1];
	if(node and node.attr) then
		chat_domain = node.attr.domain;
		System.User.ChatDomain = chat_domain;
		LOG.std("", "system", "aries", "Chat server domain: %s", System.User.ChatDomain);
	end
	
	System.User.ChatServers = {};
	local node;
	for node in commonlib.XPath.eachNode(xmlRoot, "/GameClient/chat_server_addresses/address") do
		if(node.attr and node.attr.host and node.attr.port) then
			System.User.ChatServers[#(System.User.ChatServers) + 1] = node.attr;
			if(not chat_domain) then
				System.User.ChatDomain = node.attr.host;
				System.User.ChatPort = tonumber(node.attr.port);
			end
		end	
	end
	
	node = commonlib.XPath.selectNodes(xmlRoot, "/GameClient/web_domain")[1];
	if(node and node.attr) then
		System.User.Domain = node.attr.domain;
		LOG.std("", "system", "aries", "Web domain: %s", System.User.Domain)
		local web_node = node;
		node = commonlib.XPath.selectNodes(web_node, "/log_server")[1];
		if(node and node.attr) then
			LOG.std("", "system", "aries", "Log server: %s", node.attr.host);
			paraworld.ChangeDomain({logserver = node.attr.host})
		end
		node = commonlib.XPath.selectNodes(web_node, "/file_server")[1];
		if(node and node.attr) then
			LOG.std("", "system", "aries", "File server: %s", node.attr.host);
			paraworld.ChangeDomain({fileserver = node.attr.host})
		end

		node = commonlib.XPath.selectNodes(web_node, "/login_news_page")[1];
		if(node and node.attr) then
			LOG.std("", "system", "aries", "Login news page: %s", node.attr.host);
			System.SystemInfo.SetField("login_news_page", node.attr.host)
		end
	end
	paraworld.ChangeDomain({domain=System.User.Domain, chatdomain=System.User.ChatDomain, asset_stats = bg_loader_list})

	if(not ParaEngine.GetAttributeObject():GetField("IsFullScreenMode", false)) then
		if(not System.options.IsWebBrowser) then
			LOG.std("", "system", "IME", "use the default IME window when in windowed mode");
			ParaUI.GetUIObject("root"):GetAttributeObject():SetField("EnableIME", false);
		else
			LOG.std("", "system", "IME", "web browser should always use the game engine ime system. ");
			ParaUI.GetUIObject("root"):GetAttributeObject():SetField("EnableIME", true);
		end
	end

	-- force debugger interface at startup
	if(ParaEngine.GetAppCommandLineByParam("httpdebug", "") == "true") then
		LOG.SetLogLevel("DEBUG");
		local host = "127.0.0.1";
		local port = 8099; -- if port is "0", we will not listen for incoming connection
		NPL.load("(gl)script/apps/WebServer/WebServer.lua");
		-- WebServer:Start("script/apps/WebServer/admin", host, port);
		
		local att = NPL.GetAttributeObject();
		if(not att:GetField("IsServerStarted", false)) then
			local function TestOpenNPLPort_()
				System.os.GetUrl(format("http://127.0.0.1:%s/ajax/console?action=getpid", port), function(err, msg, data)
					if(data and data.pid) then
						if(System.os.GetCurrentProcessId() ~= data.pid) then
							-- already started by another application, 
							-- try 
							port = port + 1;
							TestOpenNPLPort_();
							return;
						else
							-- already opened by the same process
						end
					else
						WebServer:Start("script/apps/WebServer/admin", host, port);	
						LOG.std(nil, "debug", "main_loop", "NPL Network Layer is started  %s:%d", host, port);
					end
				end);
			end
			TestOpenNPLPort_();
		end
	elseif (System.options.version == 'kids' or System.options.version == 'teen') then
		
	end

	if (System.options.isAB_SDK) then
		-- listen on port 80 for debugging purpose
		local att = NPL.GetAttributeObject();
		att:SetField("EnableAnsiMode", false);
	else
		-- disable ansi mode NPL message, this will passthrough some special proxy that misinterprete NPL message with HTTP. 
		local att = NPL.GetAttributeObject();
		att:SetField("EnableAnsiMode", false);
	end
	ParaAsset.OpenArchive("main_mobile_res.pkg");
end
-- load from config file
Aries_load_config();
	
-- some init stuffs that are only called once at engine start up, but after System.init()
local bAries_Init;
local function Aries_Init()
	if(bAries_Init) then return end
	bAries_Init = true;
	-- reset all replace files
	ParaIO.LoadReplaceFile("", true);

	if(System.options.mc) then
		-- local server is enabled to support full offline mode. 
	else
		-- default localserver enters memory mode. 
		LOG.std(nil, "info", "LocalServer", "default localserver.db is in memory mode");
		local ls = System.localserver.CreateStore(nil, 3);
		ls:SetMemoryMode(true);
	end

	System.SystemInfo.SetField("name", "Aries")
	
	---- also log client version in post log
	local ClientVersion = "";
	if(ParaIO.DoesFileExist("version.txt")) then
		local file = ParaIO.open("version.txt", "r");
		if(file:IsValid()) then
			local text = file:GetText();
			ClientVersion = string.match(text, "^ver=([%.%d]+)") or "";
			file:close();
		end
	end
	System.options.ClientVersion = ClientVersion;

	---- send log information
	--paraworld.PostLog({
		--action = "user_boot", 
		--clientversion = ClientVersion, 
		--stats = string.format("%s|OS:%s|", ParaEngine.GetStats(0), ParaEngine.GetStats(1))}, 
	--}, "user_boot_log", function(msg)
	--end);
	
	-- load default theme
	if(System.options.mc) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/DefaultTheme.mc.lua");
		System.options.MaxCharTriangles_show = 150000;
		MyCompany.Aries.Creator.Game.Theme.Default:Load();
	else
		if(System.options.version == "kids") then
			NPL.load("(gl)script/apps/Aries/DefaultTheme.lua");
			System.options.MaxCharTriangles_show = 50000;
		else
			NPL.load("(gl)script/apps/Aries/DefaultTheme.teen.lua");
			-- some default settings
			System.options.MaxCharTriangles_show = 50000;
			System.options.MaxCharTriangles_hide = 20000;
		end
		MyCompany.Aries.Theme.Default:Load();
	end
	
	-- limit the number of character triangles to drawn for this edition. 
	ParaScene.GetAttributeObject():SetField("MaxCharTriangles", System.options.MaxCharTriangles_show);
	-- turn off windows menu
	ParaEngine.GetAttributeObject():SetField("ShowMenu", false);
	
	-- install the Aries app, if it is not installed yet.
	if(System.options.mc) then
		System.App.Registration.CheckInstallApps({
			{app={app_key="WebBrowser_GUID"}, IP_file="script/kids/3DMapSystemApp/WebBrowser/IP.xml"},
			{app={app_key="worlds_GUID"}, IP_file="script/kids/3DMapSystemApp/worlds/IP.xml"},
			{app={app_key="Debug_GUID"}, IP_file="script/kids/3DMapSystemApp/DebugApp/IP.xml"},
			{app={app_key="Creator_GUID"}, IP_file="script/kids/3DMapSystemUI/Creator/IP.xml"},
			{app={app_key="Aries_GUID"}, IP_file="script/apps/Aries/IP.xml", bSkipInsertDB = true},
		})
	else
		System.App.Registration.CheckInstallApps({
			{app={app_key="WebBrowser_GUID"}, IP_file="script/kids/3DMapSystemApp/WebBrowser/IP.xml"},
			{app={app_key="ScreenShot_GUID"}, IP_file="script/kids/3DMapSystemUI/ScreenShot/IP.xml"},
			{app={app_key="CCS_GUID"}, IP_file="script/kids/3DMapSystemUI/CCS/IP.xml"},
			{app={app_key="Chat_GUID"}, IP_file="script/kids/3DMapSystemUI/Chat/IP.xml"},
			{app={app_key="profiles_GUID"}, IP_file="script/kids/3DMapSystemApp/profiles/IP.xml"},
			{app={app_key="worlds_GUID"}, IP_file="script/kids/3DMapSystemApp/worlds/IP.xml"},
			{app={app_key="Creator_GUID"}, IP_file="script/kids/3DMapSystemUI/Creator/IP.xml"},
			{app={app_key="Inventory_GUID"}, IP_file="script/kids/3DMapSystemApp/Inventory/IP.xml"},
			{app={app_key="Inventor_GUID"}, IP_file="script/kids/3DMapSystemUI/Inventor/IP.xml"},
			{app={app_key="HomeZone_GUID"}, IP_file="script/kids/3DMapSystemUI/HomeZone/IP.xml"},
			{app={app_key="HomeLand_GUID"}, IP_file="script/kids/3DMapSystemUI/HomeLand/IP.xml"},
			{app={app_key="FireMaster_GUID"}, IP_file="script/kids/3DMapSystemUI/FireMaster/IP.xml"},
			{app={app_key="FreeGrab_GUID"}, IP_file="script/kids/3DMapSystemUI/FreeGrab/IP.xml"},
			{app={app_key="Developers_GUID"}, IP_file="script/kids/3DMapSystemApp/Developers/IP.xml"},
			{app={app_key="Debug_GUID"}, IP_file="script/kids/3DMapSystemApp/DebugApp/IP.xml"},
			{app={app_key="MiniGames_GUID"}, IP_file="script/kids/3DMapSystemUI/MiniGames/IP.xml"},
		
			{app={app_key="Aries_GUID"}, IP_file="script/apps/Aries/IP.xml", bSkipInsertDB = true},
		})
	end
	
	-- change the login machanism to use our own login module
	System.App.Commands.SetDefaultCommand("Login", "Profile.Aries.Login");
	-- change the load world command to use our own module
	System.App.Commands.SetDefaultCommand("LoadWorld", "File.EnterAriesWorld");
	-- change the handler of system command line. 
	System.App.Commands.SetDefaultCommand("SysCommandLine", "Profile.Aries.SysCommandLine");
	-- change the handler of enter to chat. 
	System.App.Commands.SetDefaultCommand("EnterChat", "Profile.Aries.EnterChat");
	-- change the handler of drop files 
	System.App.Commands.SetDefaultCommand("SYS_WM_DROPFILES", "Profile.Aries.SYS_WM_DROPFILES");
	-- change the handler of slate mode settings change
	System.App.Commands.SetDefaultCommand("SYS_WM_SETTINGCHANGE", "Profile.Aries.SYS_WM_SETTINGCHANGE");

	---- on game esc key command
	--System.App.Commands.SetDefaultCommand("OnGameEscKey", "Profile.Aries.GameEscKey");
	
	System.options.ViewProfileCommand = "Profile.Aries.ShowFullProfile";
	
	-- in case back buffer is not big enough, we will use UI scaling. 
	if(System.options.mc) then
		ParaUI.SetMinimumScreenSize(1020,595,true);
	else
		ParaUI.SetMinimumScreenSize(1020,595,true);
	end

	local att = ParaEngine.GetAttributeObject();
	att:SetField("ToggleSoundWhenNotFocused", true);
	att:SetField("AutoLowerFrameRateWhenNotFocused", false);
	
	-- some code driven audio files for backward compatible
	AudioEngine.Init();
	-- set max concurrent sounds
	AudioEngine.SetGarbageCollectThreshold(10)
	-- load wave description resources
	AudioEngine.LoadSoundWaveBank("config/Aries/Audio/AriesRegionBGMusics.bank.xml");
	
	-- commonlib.log("Graphics Stats:\n%s\n", ParaEngine.GetStats(0));
	CommonCtrl.Locale.EnableLocale(false);
	---- include asset replace file
	--ParaIO.LoadReplaceFile("AssetsReplaceFile.txt", false);

	if(System.options.version == "teen") then
		if(System.options.locale == "zhCN") then
			ParaIO.LoadReplaceFile("config/AssetsReplaceFile_HaqiTown_teen_zhCN.xml", false);
		elseif(System.options.locale == "zhTW") then
			ParaIO.LoadReplaceFile("config/AssetsReplaceFile_HaqiTown_teen_zhTW.xml", false);
		elseif(System.options.locale == "enUS") then
			ParaIO.LoadReplaceFile("config/AssetsReplaceFile_HaqiTown_teen_enUS.xml", false);
		elseif(System.options.locale == "jaJP") then
			ParaIO.LoadReplaceFile("config/AssetsReplaceFile_HaqiTown_teen_jaJP.xml", false);
		elseif(System.options.locale == "thTH") then
			ParaIO.LoadReplaceFile("config/AssetsReplaceFile_HaqiTown_teen_thTH.xml", false);
		end
		AudioEngine.CreateGet("Area_HaqiTown_DragonGlory_teen"):play2d();
	end

	NPL.load("(gl)script/apps/Aries/mcml/mcml_aries.lua");
	MyCompany.Aries.mcml_controls.register_all();

	if(not System.options.mc) then
		-- load all worlds configuration file
		NPL.load("(gl)script/apps/Aries/Scene/WorldManager.lua");
		MyCompany.Aries.WorldManager:Init("config/Aries/Scene/AriesGameWorlds.config.xml");
	

		local login_news_page = System.SystemInfo.GetField("login_news_page");
		if(login_news_page) then
			if( not paraworld.GetLoginNewsPage) then
				paraworld.CreateRPCWrapper("paraworld.GetLoginNewsPage", login_news_page);
			end
			paraworld.GetLoginNewsPage(
				-- added forbid_reuse to close the connection immediately after request, since we no longer needs a connection to this server any more. 
				--{forbid_reuse=true},
				{}, 
				"default", function(msg)
				if(msg and msg.code==0 and msg.data and msg.rcode==200) then
					-- msg.data contains the XML code. 
					local xmlRoot = ParaXML.LuaXML_ParseString(msg.data);
					System.SystemInfo.SetField("login_news_page_data", xmlRoot);
					NPL.load("(gl)script/apps/Aries/Login/LocalUserSelectPage.lua");
					MyCompany.Aries.LocalUserSelectPage:LoadNews();
				end
			end)
		end
	end

	-------------------------------------------------------
	--[[加载已有命令的快捷键列表
	--local list = {
						{Text = commandName, ShortcutKey = key, params = params,},
						{Text = commandName, ShortcutKey = key params = params,},
				}
		--]]
	-------------------------------------------------------
	NPL.load("(gl)script/kids/3DMapSystemApp/DebugApp/app_main.lua");
	Map3DSystem.App.Debug.DoLoadConfigFile();
end

local ClickToContinue;

-- this script is activated every 0.5 sec. it uses a finite state machine (main_state). 
-- State nil is the inital game state. state 0 is idle.
local function activate()
	if(main_state==0) then
		-- this is the main game loop
		--if(ClickToContinue and ClickToContinue.FrameMove) then
			--ClickToContinue.FrameMove();
		--else
			--NPL.load("(gl)script/apps/Aries/Desktop/GUIHelper/ClickToContinue.lua");
			--ClickToContinue = commonlib.gettable("MyCompany.Aries.Desktop.GUIHelper.ClickToContinue");
		--end
		
	elseif(main_state==nil) then
		-- initialization 
		main_state = System.init();
		System.SystemInfo.SetField("name", "Aries")
		if(main_state~=nil) then
			if(System.options.mc) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Login/MainLogin.lua");
				MyCompany.Aries.Game.MainLogin:start(Aries_Init);
			else
				NPL.load("(gl)script/apps/Aries/Login/MainLogin.lua");
				MyCompany.Aries.MainLogin:start(Aries_Init);
			end
		end
	elseif(main_state == "logo") then
		if(not IsServerMode) then
			NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/LogoPage.lua");
			System.UI.Desktop.LogoPage.Show(79, {
				{name = "LogoPage_PE_bg", bg="Texture/whitedot.png", alignment = "_fi", left=0, top=0, width=0, height=0, color="255 255 255 255", anim="script/kids/3DMapSystemUI/Desktop/Motion/Bg_motion.xml"},
				{name = "LogoPage_PE_logoTxt", bg="Texture/3DMapSystem/brand/ParaEngineLogoText.png", alignment = "_rb", left=-320-20, top=-20-5, width=320, height=20, color="255 255 255 255", anim="script/kids/3DMapSystemUI/Desktop/Motion/Bg_motion.xml"},
				{name = "LogoPage_PE_logo", bg="Texture/Aries/FrontPage_32bits.png;0 111 512 290", alignment = "_ct", left=-512/2, top=-290/2, width=512, height=290, color="255 255 255 0", anim="script/apps/Aries/Desktop/Motion/Logo_motion.xml"},
			})
		else
			main_state = nil;
		end
	end	
end
NPL.this(activate);