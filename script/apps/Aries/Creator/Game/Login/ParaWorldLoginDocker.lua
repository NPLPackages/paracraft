--[[
Title: ParaWorldLoginDocker
Author(s): LiXizhi
Date: 2018/9/1
Desc: Login Docker is a docker UI that is used in all ParaWorld applications. 
Usually displayed on top when application is first loaded. 
This is a standalone file that is shared among multiple applications to download and switch to other applications.
To add more applications, simply add to `app_install_details` table and modify GetSourceAppName and IsLoadedApp method.

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldLoginDocker.lua");
local ParaWorldLoginDocker = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLoginDocker")
ParaWorldLoginDocker.Show()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/DownloadWorld.lua");
NPL.load("(gl)script/ide/Files.lua");
local DownloadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.DownloadWorld")
local AutoUpdater = NPL.load("AutoUpdater");
local ParaWorldLoginDocker = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLoginDocker")

ParaWorldLoginDocker.page = nil;

System.options.paraworldapp = ParaEngine.GetAppCommandLineByParam("paraworldapp", "");

-- @param hasParacraft: whether it contains the latest version of paracraft inside the app.
local app_install_details = {
	["paracraft"] = {
		title=L"paracraft创意空间", hasParacraft = true, 
		cmdLine = 'mc="true" bootstrapper="script/apps/Aries/main_loop.lua" noupdate="true"',
		redistFolder="haqi/", updaterConfigPath = "config/autoupdater/paracraft_win32.xml"
	},
	["haqi"] = {
		title=L"魔法哈奇", hasParacraft = true, 
		cmdLine = 'mc="false" bootstrapper="script/apps/Aries/main_loop.lua" noupdate="true" version="kids" partner="keepwork" config="config/GameClient.config.xml"',
		redistFolder="haqi/", updaterConfigPath = "config/autoupdater/paracraft_win32.xml"
	},
	["haqi2"] = {
		title=L"魔法哈奇-青年版", hasParacraft = false, 
		mergeParacraftPKGFiles = true, -- we will always apply the latest version of paracraft pkg on top of this one. 
		cmdLine = 'mc="false" bootstrapper="script/apps/Aries/main_loop.lua" noupdate="true" version="teen" partner="keepwork" config="config/GameClient.config.xml"',
		-- cmdLine = 'mc="false" bootstrapper="script/apps/Aries/main_loop.lua" noupdate="true" version="teen" config="config/GameClient.config.xml"',
		redistFolder="haqi2/", updaterConfigPath = "config/autoupdater/haqi2_win32.xml"
	},
}

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

-- whether the given application is already loaded. 
function ParaWorldLoginDocker.IsLoadedApp(name)
	if(name == "exit_paraworld") then
		return true;
	end
	if(System.options.mc) then
		if(name == "paracraft" or name == "user_worlds" or name == "tutorial_worlds") then
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
	
	if(System.options.paraworldapp == "user_worlds") then
		ParaWorldLoginDocker.OnClickApp("user_worlds");
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

function ParaWorldLoginDocker.AutoMarkLoadedApp(appButtons)
	for i, app in pairs(appButtons) do
		app.isLoaded = ParaWorldLoginDocker.IsLoadedApp(app.name);
	end
	return appButtons;
end


function ParaWorldLoginDocker.OnClickApp(name)
	if(name == "paracraft" or name == "user_worlds" or name == "tutorial_worlds") then
		if(not ParaWorldLoginDocker.IsLoadedApp(name))then
			if(not ParaWorldLoginDocker.IsLoadedApp(name))then
				ParaWorldLoginDocker.InstallApp("paracraft", function(bInstalled)
					if(bInstalled) then
						ParaWorldLoginDocker.Restart("paracraft", format('paraworldapp="%s"', name))
					end
				end)
			end
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
	elseif(name == "haqi" or name=="haqi2") then
		if(not ParaWorldLoginDocker.IsLoadedApp(name))then
			ParaWorldLoginDocker.InstallApp(name, function(bInstalled)
				if(bInstalled) then
					ParaWorldLoginDocker.Restart(name, format('paraworldapp="%s"', name))
				end
			end)
		end
	elseif(name == "paracraft_games") then
		-- TODO: for Effie, community edition

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
	return cmds;
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
	if(app) then
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
			-- prepend all paracraft pkg files
			if(app.mergeParacraftPKGFiles) then
				local app_src = ParaWorldLoginDocker.GetAppInstallDetails(srcAppName)
				if(app_src.hasParacraft) then
					local folder = ParaWorldLoginDocker.GetAppFolder(srcAppName)
					if(redistFolder~=folder) then
						ParaWorldLoginDocker.LoadAllMainPackagesInFolder(folder);
					end
				end
			end
			-- load all pkg files in redist folder
			ParaWorldLoginDocker.LoadAllMainPackagesInFolder(redistFolder);
		end
		--local assetManifest = System.Core.DOM.GetDOM("AssetManager"):GetChild("CAssetManifest")
		--assetManifest:CallField("Clear")
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
	
	-- NOT WORKING: 
	-- NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
	-- local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
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

-- @param callbackFunc: function(bInstalled) end
function ParaWorldLoginDocker.InstallApp(appName, callbackFunc)
	local app = ParaWorldLoginDocker.GetAppInstallDetails(appName)
	if(not app or app.noUpdate) then
		if(callbackFunc) then
			callbackFunc(true);
		end
		return
	end

	if(ParaWorldLoginDocker.IsInstalling()) then
		_guihelper.MessageBox(L"应用在安装中, 请等待");
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

	local redist_root = ParaWorldLoginDocker.GetAppFolder(appName);
	ParaIO.CreateDirectory(redist_root);

	local autoUpdater = AutoUpdater:new();

	-- let us skip all dll and exe files
	autoUpdater.FilterFile = function(self, filename)
		if(filename:match("%.exe") or filename:match("%.dll")) then
			return true;
		end
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
            elseif(state == State.PREDOWNLOAD_MANIFEST)then
                DownloadWorld.UpdateProgressText(L"资源列表预下载");
            elseif(state == State.DOWNLOADING_MANIFEST)then
                DownloadWorld.UpdateProgressText(L"资源列表下载中");
            elseif(state == State.MANIFEST_DOWNLOADED)then
				DownloadWorld.UpdateProgressText(L"已经获取资源列表");
            elseif(state == State.MANIFEST_ERROR)then
                ParaWorldLoginDocker.SetInstalling(false);
				_guihelper.MessageBox(L"无法获取资源列表");
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
				_guihelper.MessageBox(L"无法应用更新");
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

