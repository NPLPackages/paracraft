--[[
Title: ParaWorldLoginDocker
Author(s): LiXizhi
Date: 2018/9/1
Desc: Login Docker is a docker UI that is used in all ParaWorld applications. 
Usually displayed on top when application is first loaded. 
This is a standalone file that is shared among multiple applications to download and switch to other applications.
To add more applications, simply add to `app_install_details` table and modify GetSourceAppName and IsLoadedApp method.

## QQ Hall Command Line
platform_token="1132076926" user_id="100000566" version="kids" partner="keepwork" isFromQQHall="true" mc="false" httpdebug="true" bootstrapper="script/apps/Aries/main_loop.lua"  loadpackage=""

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldLoginDocker.lua");
local ParaWorldLoginDocker = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLoginDocker")
ParaWorldLoginDocker.InitParaWorldClient()
ParaWorldLoginDocker.Show()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/DownloadWorld.lua");
NPL.load("(gl)script/ide/Files.lua");
local DownloadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.DownloadWorld")
local AutoUpdater = NPL.load("AutoUpdater");
local ParaWorldLoginDocker = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLoginDocker")

ParaWorldLoginDocker.page = nil;

-- disable http(s) with non-local access
function ParaWorldLoginDocker.IsExternalUrlAllowed(url)
	if(url and url~="") then
		local protocolName = url:match("^(%w+)://");
		if(protocolName == "http" or protocolName == "https") then
			if(url:match("^https?://127.0.0.1") or url:match("^https?://localhost")) then
				return true;
			else
				return false;
			end		
		end
	end
	return true;
end

function ParaWorldLoginDocker.DisableExternalUrlLinks()
	local old_shell_execute_ = ParaGlobal.ShellExecute;
	ParaGlobal.ShellExecute = function(cmd, url1, url2, p1, p2)
		if(ParaWorldLoginDocker.IsExternalUrlAllowed(url1) and ParaWorldLoginDocker.IsExternalUrlAllowed(url2)) then
			old_shell_execute_(cmd, url1, url2, p1, p2)
		else
			LOG.std(nil, "info", "ParaGlobal.ShellExecute", "external link %s is disabled", url1 or "");
			_guihelper.MessageBox(L"外部连接被禁用了");
		end
	end
end

-- get the application name on the working directory. 
function ParaWorldLoginDocker.GetSourceAppName()
	local name = ParaEngine.GetAppCommandLineByParam("src_paraworldapp", "");
	if(name=="" and commonlib.Files.GetDevDirectory()=="") then
		if(System.options.mc) then
			name = "paracraft";
		elseif(System.options.version == "kids") then
			name = "haqi";
		elseif(System.options.version == "teen") then
			name = "haqi2";
		end
	end
	return name or "";
end

function ParaWorldLoginDocker.GetCurrentAppName()
	if(System.options.mc) then
		name = "paracraft";
	elseif(System.options.version == "kids") then
		name = "haqi";
	elseif(System.options.version == "teen") then
		name = "haqi2";
	end
	return name or "paracraft";
end


commonlib.setfield("System.options.paraworldapp", ParaEngine.GetAppCommandLineByParam("paraworldapp", ""));

-- @param title: additional text to show to the user in the login box
-- @param callbackFunc: optional callback function(bSucceed) end when user actually signed in
function ParaWorldLoginDocker.SignIn(title, callbackFunc)
	local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua");
	if(KeepworkService and KeepworkService:IsSignedIn()) then
		if(callbackFunc) then
			callbackFunc(true)
		end
	else
		local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
		local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
		Store:Set("user/loginText", title or L"请先登录")

		LoginModal:Init(function(bSucceed)
			if(callbackFunc) then
				callbackFunc(bSucceed~=false)
			end
		end);
	end
end
			


-- call this once
function ParaWorldLoginDocker.InitParaWorldClient()
	if(ParaWorldLoginDocker.isInited) then
		return true;
	end
	ParaWorldLoginDocker.isInited = true;

	-- start paraworld analytics
	ParaWorldAnalytics = NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldAnalytics.lua");
	ParaWorldAnalytics:Send("start."..(ParaWorldLoginDocker.GetCurrentAppName() or ""), ParaWorldAnalytics:AppendDateToTag("user"), 0, nil);
	
	
	NPL.load("npl_packages/ParacraftBuildinMod/");

	if(System.options.isFromQQHall) then
		ParaWorldLoginDocker.DisableExternalUrlLinks();

		if(not System.options.clientconfig_file and System.options.paraworldapp == "haqi") then
			System.options.clientconfig_file = "config/GameClient.config.QQ.xml";
		end

		commonlib.TimerManager.SetTimeout(function()
			local ParaWorldClient = NPL.load("ParaWorldClient")
			ParaWorldClient:Init();
		end, 0)
		
		local user_id = ParaEngine.GetAppCommandLineByParam("user_id", "")
		local platform_token = ParaEngine.GetAppCommandLineByParam("platform_token", "")

		if(not System.User or not System.User.keepworktoken) then
			commonlib.setfield("System.User.keepworktoken", "waiting");

			local retryCount = 1;
			local function GetKeepworkToken_()
				System.os.GetUrl({url = "https://api.keepwork.com/core/v0/users/platform_login", 
					json = true, form = {uid = user_id, token = platform_token, platform="qqHall" } }, 
					function(err, msg, data)
						-- echo({err, msg, data})
						if(err == 200) then
							if(data and data.kp and data.kp.token) then
								_guihelper.MessageBox(nil);
								if(data.kp.user and data.kp.user.nickname) then
									System.User.nickname = data.kp.user.nickname;
								end
								commonlib.setfield("System.User.keepworktoken", data.kp.token);
								LOG.std(nil, "info", "paraworldclient", "successfully logged in with QQ account %s  nickname: %s", user_id, System.User.nickname or "");
								return
							else
								_guihelper.MessageBox(L"登陆信息过期了，请重新启动", function()
									ParaGlobal.Exit(0);
								end, _guihelper.MessageBoxButtons.OK)
							end
						elseif(msg and msg.code == 28) then
							-- timeout, we will try again
							retryCount = retryCount + 1
							_guihelper.MessageBox(format("访问超时, 第%d次尝试", retryCount), function()
							end)
							if(retryCount < 3) then
								GetKeepworkToken_()
							end
							return
						end
						System.User.keepworktoken = "error"
						_guihelper.MessageBox(L"暂时无法登陆，请稍后再试.", function()
							ParaGlobal.Exit(0);
						end, _guihelper.MessageBoxButtons.OK)
				end);
			end
			GetKeepworkToken_();
		end
	end
end
ParaWorldLoginDocker.InitParaWorldClient();

-- @param hasParacraft: whether it contains the latest version of paracraft inside the app.
local app_install_details = {
	["paracraft"] = {
		title=L"paracraft帕拉卡", hasParacraft = true, 
		cmdLine = 'mc="true" bootstrapper="script/apps/Aries/main_loop.lua" noupdate="true"',
		redistFolder="haqi/", updaterConfigPath = "config/autoupdater/paracraft_win32.xml",
		allowQQHall = true,
	},
	-- only used by ClientUpdater, this will force using the latest version in apps folder
	["paracraftAppVersion"] = {
		title=L"paracraft帕拉卡", hasParacraft = true, 
		cmdLine = 'mc="true" bootstrapper="script/apps/Aries/main_loop.lua" noupdate="true"',
		redistFolder="haqi/", updaterConfigPath = "config/autoupdater/paracraft_win32.xml",
		allowQQHall = true,
	},
	["haqi"] = {
		title=L"魔法哈奇", hasParacraft = true, 
		cmdLine = 'mc="false" bootstrapper="script/apps/Aries/main_loop.lua" noupdate="true" version="kids" partner="keepwork" config="config/GameClient.config.xml"',
		redistFolder="haqi/", updaterConfigPath = "config/autoupdater/paracraft_win32.xml",
		allowQQHall = true,
		isGame = true,
	},
	["haqi2"] = {
		title=L"魔法哈奇-青年版", hasParacraft = false, 
		allowQQHall = true,
		isGame = true,
		mergeHaqiPKGFiles = true, -- we will always apply the latest version of haqi pkg on top of this one. 
		cmdLine = 'mc="false" bootstrapper="script/apps/Aries/main_loop.lua" noupdate="true" version="teen" partner="keepwork" config="config/GameClient.config.xml"',
		-- cmdLine = 'mc="false" bootstrapper="script/apps/Aries/main_loop.lua" noupdate="true" version="teen" config="config/GameClient.config.xml"',
		redistFolder="haqi2/", updaterConfigPath = "config/autoupdater/haqi2_win32.xml"
	},
	["truckstar"] = {
		title=L"创意大厅", hasParacraft = false, 
		cmdLine = 'noupdate="true" mc="true" bootstrapper="script/apps/Aries/main_loop.lua" mod="Truck" isDevEnv="true" disable-parent-package-lookup="true"',
		redistFolder="truck/", updaterConfigPath = "config/autoupdater/truckstar_win32.xml",
		additional_manifest = "assets_manifest_truckload.txt",
		allowQQHall = true,
	},
}

-- whether the given application is already loaded. 
function ParaWorldLoginDocker.IsLoadedApp(name)
	if(name == "exit_paraworld") then
		return true;
	end
	if(System.options.mc) then
		if(System.options.paraworldapp == name or name == "paracraft" or name == "user_worlds" or name == "tutorial_worlds") then
			return true;
		end
	elseif(System.options.version == "kids") then
		if(name == "haqi") then
			return true;
		end
	elseif(System.options.version == "teen") then
		if(name == "haqi2") then
			return true;
		end
	elseif(System.options.version == "paraworld") then
		-- TODO: our social platform
	end
end

function ParaWorldLoginDocker.StaticInit()
	if(ParaWorldLoginDocker.inited) then
		return;
	end
	ParaWorldLoginDocker.inited = true;

	-- always skip updating the current source app
	local appName = ParaWorldLoginDocker.GetSourceAppName()
	local app = ParaWorldLoginDocker.GetAppInstallDetails(appName);
	if(app) then
		app.noUpdate = true;
		app.redistFolder = nil;

		-- also skip paracraft if the working directory also contains paracraft files, like haqi. 
		if(app.hasParacraft) then
			local app = ParaWorldLoginDocker.GetAppInstallDetails("paracraft");
			if(app) then
				app.noUpdate = true;
				app.redistFolder = nil;
			end	
		end
	end
end

-- init function. page script fresh is set to false.
function ParaWorldLoginDocker.OnInit()
	ParaWorldLoginDocker.StaticInit();
	ParaWorldLoginDocker.page = document:GetPageCtrl();

	if(System.options.paraworldapp == "user_worlds" or System.options.paraworldapp == "tutorial_worlds" or System.options.paraworldapp == "haqi2") then
		ParaWorldLoginDocker.OnClickApp(System.options.paraworldapp);
	end
end

-- show page
function ParaWorldLoginDocker.ShowPage()
	local params;
	params = {
		url = "script/apps/Aries/Creator/Game/Login/ParaWorldLoginDocker.html", 
		name = "ParaWorldLoginDocker.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		bShow = true,
		zorder = 5,
		click_through = true, 
		directPosition = true,
			align = "_mt",
			x = 0,
			y = 0,
			width = 512,
			height = 64,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end


function ParaWorldLoginDocker.FilterApps(appButtons)
	if(System.options) then
		while(true) do
			local allPassed = true
			for i, app in ipairs(appButtons) do
				local info = ParaWorldLoginDocker.GetAppInstallDetails(app.name)
				if(info and ((not info.allowQQHall and System.options.isFromQQHall) or (info.isGame and System.options.isSchool))) then
					table.remove(appButtons, i);
					allPassed = false;
					break;
				end
			end
			if(allPassed) then
				break;
			end
		end
	end	
	return appButtons;
end

function ParaWorldLoginDocker.AutoMarkLoadedApp(appButtons)
	for i, app in pairs(appButtons) do
		app.isLoaded = ParaWorldLoginDocker.IsLoadedApp(app.name);
	end
	appButtons = ParaWorldLoginDocker.FilterApps(appButtons);
	return appButtons;
end


function ParaWorldLoginDocker.OnClickApp(name)
	GameLogic.GetFilters():apply_filters("user_event_stat", "paraworld", "DockerClick:"..tostring(name), 5, nil);

	if(name == "paracraft" or name == "user_worlds" or name == "tutorial_worlds") then
		if(not ParaWorldLoginDocker.IsLoadedApp(name))then
			ParaWorldLoginDocker.InstallApp("paracraft", function(bInstalled)
				if(bInstalled) then
					ParaWorldLoginDocker.Restart("paracraft", format('paraworldapp="%s"', name))
				end
			end)
		else
			if(name == "user_worlds") then
				System.options.showUserWorldsOnce = true
			elseif(name == "tutorial_worlds") then
				--ParaGlobal.ShellExecute("open", "https://keepwork.com/official/paracraft/animation-tutorials", "", "", 1)
				NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldLessons.lua");
				local ParaWorldLessons = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLessons")
				ParaWorldLessons.ShowPage()
				return
			end

			if(ParaWorldLoginDocker.page) then
				ParaWorldLoginDocker.page:CloseWindow()
				System.options.loginmode = "local";
				local MainLogin = commonlib.gettable("MyCompany.Aries.Game.MainLogin");
				MainLogin:next_step({IsLoginModeSelected = true});
			end
		end
	elseif(name == "haqi" or name=="haqi2" or name == "truckstar") then
		if(not ParaWorldLoginDocker.IsLoadedApp(name))then
			ParaWorldLoginDocker.InstallApp(name, function(bInstalled)
				if(bInstalled) then
					ParaWorldLoginDocker.Restart(name, format('paraworldapp="%s"', name))
				end
			end)
		end
	elseif(name == "exit_paraworld") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
		local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
		if(GameLogic.GetFilters():apply_filters("exit_paraworld", true)) then
			ParaEngine.GetAttributeObject():SetField("IsWindowClosingAllowed", true);
			ParaGlobal.ExitApp();
		end
	end
end

function ParaWorldLoginDocker.GetCurrentRedistFolder()
	local dev = commonlib.Files.GetDevDirectory()
	if(dev == "") then
		dev = ParaIO.GetWritablePath();
	end
	return dev;
end

function ParaWorldLoginDocker.LoadAllMainPackagesInFolder(redistFolder)
	local result = commonlib.Files.Find({}, redistFolder, 0, 500, "main*.pkg")
	table.sort(result, function(a, b)
		return a.filename > b.filename
	end)
	for i, item in ipairs(result) do
		filename = redistFolder..item.filename;
		ParaAsset.OpenArchive(filename)
		LOG.std(nil, "info", "ParaWorldLoginDocker", "load archive: %s", filename);
	end
end

function ParaWorldLoginDocker.RestoreDefaultGUITemplate()
	local _this;

	_this=ParaUI.GetDefaultObject("button");
	_guihelper.SetButtonFontColor(_this, "#000000");

	_this=ParaUI.GetDefaultObject("listbox");
	_guihelper.SetFontColor(_this, "#000000");

	_this=ParaUI.GetDefaultObject("editbox");
	_this:GetAttributeObject():SetField("CaretColor", _guihelper.ColorStr_TO_DWORD("#ff808080"));
	_guihelper.SetFontColor(_this, "#000000");

	_this=ParaUI.GetDefaultObject("imeeditbox");
	_guihelper.SetFontColor(_this, "#000000");

	_this=ParaUI.GetDefaultObject("tooltip");
	_guihelper.SetFontColor(_this, "#000000");
end
	
function ParaWorldLoginDocker.GetRedirectableCmdLineParams()
	local cmds = "";
	if(ParaEngine.GetAppCommandLineByParam("httpdebug", "") == "true") then
		cmds = cmds.." httpdebug=\"true\"";
	end
	-- keepwork token forward here
	if(System.User and System.User.keepworktoken) then
		cmds = cmds..format(" keepworktoken=\"%s\"", System.User.keepworktoken);
	end
	if(System.options and System.options.isFromQQHall) then
		cmds = cmds.." isFromQQHall=\"true\"";
	end
	return cmds;
end

-- Load additional manifest file list for the game to be launched
-- @param appName: app name to be launched
function ParaWorldLoginDocker.loadAdditionalManifestList(appName)
	local app = ParaWorldLoginDocker.GetAppInstallDetails(appName)
	if(app and app.additional_manifest) then
		local app_folder = ParaWorldLoginDocker.GetAppFolder(appName);
		local manifest_path = app_folder..app.additional_manifest;
		if ParaIO.DoesFileExist(manifest_path) then
			local asset_manager = ParaEngine.GetAttributeObject():GetChild("AssetManager");
			local asset_manifest = asset_manager:GetChild("CAssetManifest");
			asset_manifest:SetField("LoadManifestFile", manifest_path);
			LOG.std(nil, "info", "ParaWorldLoginDocker", "additional manifest file for current app loaded: %s", manifest_path);
		else
			LOG.std(nil, "info", "ParaWorldLoginDocker", "additional manifest file for current app cannot be found: %s", manifest_path);
		end
	else
		LOG.std(nil, "info", "ParaWorldLoginDocker", "current app does not have an additional manifest list");
	end
end

-- Restart the entire NPLRuntime to a different application. e.g.
-- Desktop.Restart("haqi")
-- Desktop.Restart("paracraft")
-- @param appName: nil default to application at working directory. 
function ParaWorldLoginDocker.Restart(appName, additional_commandline_params, additional_restart_code)
	if(not appName) then
		appName = ParaWorldLoginDocker.GetSourceAppName()
		if(not additional_commandline_params) then
			additional_commandline_params = format('paraworldapp="%s"', appName)
		end
	end
	
	local oldCmdLine = ParaEngine.GetAppCommandLine();
	local newCmdLine = oldCmdLine;
	local app = ParaWorldLoginDocker.GetAppInstallDetails(appName)
	if(app and app.cmdLine) then
		newCmdLine = app.cmdLine;
	end

	local srcAppName = ParaWorldLoginDocker.GetSourceAppName()
	newCmdLine = format("%s src_paraworldapp=\"%s\"", newCmdLine, srcAppName);
	newCmdLine = newCmdLine.." "..(ParaWorldLoginDocker.GetRedirectableCmdLineParams() or "");

	local app = ParaWorldLoginDocker.GetAppInstallDetails(appName);
	if(app and not ParaWorldLoginDocker.IsLoadedApp(appName)) then
		local redistFolder = ParaWorldLoginDocker.GetAppFolder(appName);
		redistFolder = redistFolder:gsub("\\", "/");

		if(ParaWorldLoginDocker.GetCurrentRedistFolder() ~= redistFolder) then
			additional_commandline_params = format("dev=\"%s\" %s", redistFolder, additional_commandline_params or "");
			LOG.std(nil, "info", "ParaWorldLoginDocker", "dev folder changed to %s", redistFolder);

			-- unload all pkg files
			local fileManager = ParaEngine.GetAttributeObject():GetChild("AssetManager"):GetChild("CFileManager");
			local loadedPkgFiles = {};
			for i=0, fileManager:GetChildCount(0) -1 do
				local archiveAttr = fileManager:GetChildAt(i, 0);
				loadedPkgFiles[#loadedPkgFiles+1] = archiveAttr:GetField("name", "");
			end
			for _, name in ipairs(loadedPkgFiles) do
				ParaAsset.CloseArchive(name);
				LOG.std(nil, "info", "ParaWorldLoginDocker", "unload archive: %s", name);
			end
			-- prepend all haqi pkg files
			if(app.mergeHaqiPKGFiles) then
				local app_src = ParaWorldLoginDocker.GetAppInstallDetails("haqi")
				local folder = ParaWorldLoginDocker.GetAppFolder("haqi")
				if(redistFolder~=folder) then
					ParaWorldLoginDocker.LoadAllMainPackagesInFolder(folder);
				end
			end
			-- load all pkg files in redist folder
			ParaWorldLoginDocker.LoadAllMainPackagesInFolder(redistFolder);
		end
		local asset_manifest = ParaEngine.GetAttributeObject():GetChild("AssetManager"):GetChild("CAssetManifest");
		asset_manifest:CallField("Clear")
		asset_manifest:SetField("LoadManifestFile", redistFolder.."assets_manifest.txt")
	end

	if(additional_commandline_params) then
		newCmdLine = newCmdLine.." "..additional_commandline_params;
	end

	ParaEngine.SetAppCommandLine(newCmdLine);
	System.reset();
	-- flush all local server 
	if(System.localserver) then
		System.localserver.FlushAll();
	end	
	ParaScene.UnregisterAllEvent();
	-- reset to default value
	ParaTerrain.LeaveBlockWorld();
	ParaTerrain.GetAttributeObject():SetField("RenderTerrain", true);
	ParaWorldLoginDocker.RestoreDefaultGUITemplate()
	NPL.ClearPublicFiles();
	NPL.StopNetServer();

	ParaWorldLoginDocker.loadAdditionalManifestList(appName);

	-- NOT WORKING: 
	-- NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
	-- local ViewportManager = commonlib.gettable("System.Scene.V  iewports.ViewportManager");
	-- ViewportManager:GetGUIViewport():SetPosition("_fi", 0,0,0,0);
	-- ViewportManager:GetGUIViewport():Apply();
	-- ViewportManager:GetSceneViewport():SetPosition("_fi", 0,0,0,0);
	-- ViewportManager:GetSceneViewport():Apply();

	local restart_code = [[
	ParaUI.ResetUI();
	ParaScene.Reset();
	NPL.load("(gl)script/apps/Aries/main_loop.lua");
	System.options.cmdline_world="";
	NPL.activate("(gl)script/apps/Aries/main_loop.lua");
]];
	if(additional_restart_code) then
		restart_code = restart_code .. additional_restart_code;
	end

	-- TODO: close world archives, packages and search paths

	-- clear pending messages before reset
	while(true) do
		local nSize = __rts__:GetCurrentQueueSize();
		if(nSize>0) then
			__rts__:PopMessageAt(0, {process = true});
		else
			break;
		end
	end
	__rts__:Reset(restart_code);
end

ParaWorldLoginDocker.appsRootFolder = ParaIO.GetWritablePath().."apps/";

function ParaWorldLoginDocker.GetAppFolder(appName)
	local app = ParaWorldLoginDocker.GetAppInstallDetails(appName)
	if(app and app.redistFolder) then
		return ParaWorldLoginDocker.appsRootFolder..app.redistFolder;
	else
		return ParaIO.GetWritablePath();
	end
end

function ParaWorldLoginDocker.IsInstalling()
	return ParaWorldLoginDocker.isInstalling;
end

function ParaWorldLoginDocker.SetInstalling(bInstalling, appName)
	ParaWorldLoginDocker.isInstalling = bInstalling;
	if(bInstalling) then
		DownloadWorld.ShowPage(appName);
	else
		DownloadWorld.Close();
	end
end

function ParaWorldLoginDocker.GetAppConfigByName(appName)
	local app = ParaWorldLoginDocker.GetAppInstallDetails(appName)
	if(app and app.updaterConfigPath) then
		return app.updaterConfigPath;
	end
end

function ParaWorldLoginDocker.GetAppTitle(appName)
	local app = ParaWorldLoginDocker.GetAppInstallDetails(appName)
	return app and app.title or L"官方应用";
end

local appsVersions = {};
function ParaWorldLoginDocker.AddAppVersionInfo(appName, needUpdate, curVersion, latestVersion)
	appsVersions[appName] = appsVersions[appName] or {};
	local app = appsVersions[appName];
	app.needUpdate = needUpdate;
	app.curVersion = curVersion;
	app.latestVersion = latestVersion;
	return app;
end

function ParaWorldLoginDocker.GetAppVersionInfo(appName)
	return appsVersions[appName];
end

-- @param callbackFunc: function(bNeedUpdate, curVersion, latestVersion) end
function ParaWorldLoginDocker.CheckInstalledAppVersion(appName, callbackFunc)
	ParaWorldLoginDocker.StaticInit();

	local app = ParaWorldLoginDocker.GetAppVersionInfo(appName);
	if(app) then
		if(callbackFunc) then
			callbackFunc(app.needUpdate, app.curVersion, app.latestVersion);
		end
		return
	end

	local redist_root = ParaWorldLoginDocker.GetAppFolder(appName);
	ParaIO.CreateDirectory(redist_root);
	local autoUpdater = AutoUpdater:new();
	autoUpdater:onInit(redist_root, ParaWorldLoginDocker.GetAppConfigByName(appName),function(state)
	end);
	autoUpdater:check(nil,function()
        local cur_version = autoUpdater:getCurVersion();
        local latest_version = autoUpdater:getLatestVersion();
		local bNeedUpdate = autoUpdater:isNeedUpdate();
        LOG.std(nil, "info", "ParaWorldLoginDocker", "check version for %s", appName);
		echo({name=appName, cur_version = cur_version, latest_version = latest_version});
		ParaWorldLoginDocker.AddAppVersionInfo(appName, bNeedUpdate, cur_version, latest_version)
		if(callbackFunc) then
			callbackFunc(bNeedUpdate, cur_version, latest_version);
		end
    end);
end

-- apps that must be installed with latest version. 
-- @param appName: default to source app Name
function ParaWorldLoginDocker.GetAppInstallDetails(appName)
	return app_install_details[appName or ParaWorldLoginDocker.GetSourceAppName()];
end

function ParaWorldLoginDocker.ForceExitApp()
	ParaEngine.GetAttributeObject():SetField("IsWindowClosingAllowed", true);
	ParaGlobal.ExitApp();
end

-- @param callbackFunc: function(bInstalled) end
function ParaWorldLoginDocker.InstallApp(appName, callbackFunc)
	if(System.options.isFromQQHall) then
		if(appName=="haqi2") then
			-- tricky: QQ hall always has haqi installed, so skip it and proceed to haqi2
			ParaWorldLoginDocker.haqiInstalled = true;
		elseif(appName=="paracraft_games") then
			ParaWorldLoginDocker.ForceExitApp()
		else
			if(callbackFunc) then
				callbackFunc(true);
			end
			return;
		end
	end

	local app = ParaWorldLoginDocker.GetAppInstallDetails(appName)
	if(not app or app.noUpdate) then
		if(callbackFunc) then
			callbackFunc(true);
		end
		return
	end

	if(ParaWorldLoginDocker.IsInstalling()) then
		_guihelper.MessageBox(L"应用在安装中, 请等待");
		if(callbackFunc) then
			callbackFunc(false)
		end
		return true;
	end
	local appVersion = ParaWorldLoginDocker.GetAppVersionInfo(appName);
	if(appVersion) then
		if(not appVersion.needUpdate) then
			if(callbackFunc) then
				callbackFunc(true);
			end
			return
		end
	end

	-- install haqi first, before installing the current app
	if(app.mergeHaqiPKGFiles and ParaWorldLoginDocker.haqiInstalled == nil) then
		ParaWorldLoginDocker.haqiInstalled = false;
		ParaWorldLoginDocker.InstallApp("haqi", function(bSucceed)
			if(bSucceed) then
				app.installingParacraft = true;
				ParaWorldLoginDocker.InstallApp(appName, callbackFunc);
			else
				if(callbackFunc) then
					callbackFunc(false);
				end
			end
		end)
		return
	end

	local redist_root = ParaWorldLoginDocker.GetAppFolder(appName);
	ParaIO.CreateDirectory(redist_root);

	local autoUpdater = AutoUpdater:new();

	-- let us skip all dll and exe files
	autoUpdater.FilterFile = function(self, filename)
		if(filename:match("%.exe") or filename:match("%.dll")) then
			return true;
		end
	end

	local storageFilters = {
		["database/globalstore.db.mem.p"] = "Database/globalstore.db.mem.p",
		["database/globalstore.teen.db.mem.p"] = "Database/globalstore.teen.db.mem.p",
		["database/characters.db.p"] = "Database/characters.db.p",
		["database/extendedcost.db.mem.p"] = "Database/extendedcost.db.mem.p",
		["database/extendedcost.teen.db.mem.p"] = "Database/extendedcost.teen.db.mem.p",
		["npl_packages/paracraftbuildinmod.zip.p"] = "npl_packages/ParacraftBuildinMod.zip.p",
		["config/gameclient.config.xml.p"] = "config/GameClient.config.xml.p",
		
	}
	-- fix lower case issues on linux system
	autoUpdater.FilterStoragePath = function(self, filename)
		return storageFilters[filename] or filename
	end

	local timer;
	autoUpdater:onInit(redist_root, ParaWorldLoginDocker.GetAppConfigByName(appName),function(state)
        if(state)then
			local State = AutoUpdater.State;
            if(state == State.PREDOWNLOAD_VERSION)then
                DownloadWorld.UpdateProgressText(L"预下载版本号");
            elseif(state == State.DOWNLOADING_VERSION)then
                DownloadWorld.UpdateProgressText(L"正在下载版本信息");
            elseif(state == State.VERSION_CHECKED)then
                DownloadWorld.UpdateProgressText(L"版本验证完毕");
            elseif(state == State.VERSION_ERROR)then
                ParaWorldLoginDocker.SetInstalling(false);
				_guihelper.MessageBox(L"无法获取版本信息");
				if(callbackFunc) then
					callbackFunc(false)
				end
            elseif(state == State.PREDOWNLOAD_MANIFEST)then
                DownloadWorld.UpdateProgressText(L"资源列表预下载");
            elseif(state == State.DOWNLOADING_MANIFEST)then
                DownloadWorld.UpdateProgressText(L"资源列表下载中");
            elseif(state == State.MANIFEST_DOWNLOADED)then
				DownloadWorld.UpdateProgressText(L"已经获取资源列表");
            elseif(state == State.MANIFEST_ERROR)then
                ParaWorldLoginDocker.SetInstalling(false);
				_guihelper.MessageBox(L"无法获取资源列表");
				if(callbackFunc) then
					callbackFunc(false)
				end
            elseif(state == State.PREDOWNLOAD_ASSETS)then
				DownloadWorld.UpdateProgressText(L"准备下载资源文件");
				local nowTime = 0
                local lastTime = 0
                local interval = 100
                local lastDownloadedSize = 0
                timer = commonlib.Timer:new({callbackFunc = function(timer)
					local totalSize = autoUpdater:getTotalSize()
                    local downloadedSize = autoUpdater:getDownloadedSize()
					nowTime = nowTime + interval;

					if downloadedSize > lastDownloadedSize then
                        local downloadSpeed = (downloadedSize - lastDownloadedSize) / ((nowTime - lastTime) / 1000)
                        lastDownloadedSize = downloadedSize
                        lastTime = nowTime
                        local tips = string.format("%.1f/%.1fMB(%.1fKB/S)", downloadedSize / 1024 / 1024, totalSize / 1024 / 1024, downloadSpeed / 1024)
						DownloadWorld.UpdateProgressText(tips);
                    end
					
					if(not ParaWorldLoginDocker.IsInstalling()) then
						timer:Change();
					end
                end})
                timer:Change(0, 100)
            elseif(state == State.DOWNLOADING_ASSETS)then
                -- DownloadWorld.UpdateProgressText(L"正在下载资源");
            elseif(state == State.ASSETS_DOWNLOADED)then
                DownloadWorld.UpdateProgressText(L"全部资源下载完成");
				if(timer) then
					timer:Change();
				end
                autoUpdater:apply();
            elseif(state == State.ASSETS_ERROR)then
                ParaWorldLoginDocker.SetInstalling(false);
				_guihelper.MessageBox(L"无法获取资源");
				if(callbackFunc) then
					callbackFunc(false)
				end
            elseif(state == State.PREUPDATE)then
                
            elseif(state == State.UPDATING)then
                DownloadWorld.UpdateProgressText(L"正在安装更新");
            elseif(state == State.UPDATED)then
                DownloadWorld.UpdateProgressText(L"安装完成");
				ParaWorldLoginDocker.SetInstalling(false);
				if(callbackFunc) then
					callbackFunc(true);
				end
            elseif(state == State.FAIL_TO_UPDATED)then
				ParaWorldLoginDocker.SetInstalling(false);
				_guihelper.MessageBox(L"无法应用更新"..L"请确保目前只有一个实例在运行");
				if(callbackFunc) then
					callbackFunc(false)
				end
            end    
        end
    end);

	ParaWorldLoginDocker.SetInstalling(true, ParaWorldLoginDocker.GetAppTitle(appName));

    autoUpdater:check(nil,function()
        local cur_version = autoUpdater:getCurVersion();
        local latest_version = autoUpdater:getLatestVersion();
        LOG.std(nil, "info", "ParaWorldLoginDocker.InstallApp", "check version for %s", appName);
		echo({name=appName, cur_version = cur_version, latest_version = latest_version});
        if(autoUpdater:isNeedUpdate())then
            autoUpdater:download();
        else
            LOG.std(nil, "info", "ParaWorldLoginDocker.InstallApp", "%s is already at latest version", appName);
			ParaWorldLoginDocker.SetInstalling(false);
			if(callbackFunc) then
				callbackFunc(true);
			end
        end
    end);
end

