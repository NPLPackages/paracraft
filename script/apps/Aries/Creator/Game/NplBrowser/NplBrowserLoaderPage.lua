--[[
Title: NplBrowserLoaderPage
Author(s): leio
Date: 2019.3.26
Desc: 
This is a background loader to download the resources of cefclient.exe automatically.
Deployed on cdn server, the resources are download by AssetsManager which is configured by configs/nplbrowser.xml.

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
NplBrowserLoaderPage.CheckOnce()
NplBrowserLoaderPage.Check(callback)
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/BuildinMod.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua");
NPL.load("(gl)script/ide/timer.lua");
local BuildinMod = commonlib.gettable("MyCompany.Aries.Game.MainLogin.BuildinMod");
local AssetsManager = NPL.load("AutoUpdater");
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");
local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
NPL.load("(gl)script/Github/GitReleaseUpdater.lua");
NplBrowserLoaderPage.cef_main_files = {
    "cefclient.exe",
    "NplCefPlugin.dll",
    "libcef.dll",
    "cef.pak",
}
NplBrowserLoaderPage.loaded = false;
NplBrowserLoaderPage.timer = nil;

NplBrowserLoaderPage.try_update_max_times = 3;
NplBrowserLoaderPage.try_times = 0;
NplBrowserLoaderPage.callback_maps = {};

local cef3_install_folder = "cef3";

-- version number for new cef3
NplBrowserLoaderPage.minCef3Ver = {0, 0, 22};
NplBrowserLoaderPage.cef3ModInstallUrl = "https://cdn.keepwork.com/paracraft/cef/cef3.zip";

-- OBSOLETED, use cef3ModInstallUrl to install
local config_file = "script/apps/Aries/Creator/Game/NplBrowser/configs/nplbrowser.xml";
local version_txt = "version.txt"

local page;
-- init function. page script fresh is set to false.
function NplBrowserLoaderPage.OnInit()
	page = document:GetPageCtrl();
end

-- call this as a one time check and background installer on startup, if you do no need a callback. otherwise use Check instead. 
function NplBrowserLoaderPage.CheckOnce()
	if(not NplBrowserLoaderPage.isCheckOnce) then
		NplBrowserLoaderPage.Check()
	end
end

function NplBrowserLoaderPage.CheckCef3(callback,bForceReinstall)
    if(not NplBrowserLoaderPage.CheckCef3FileIntegrity(cef3_install_folder))then
        NplBrowserLoaderPage.loaded = false;
    end

    if not NplBrowserLoaderPage.loaded then
        NplBrowserLoaderPage.isOnlyInstallCef3 = bForceReinstall == true
        NplBrowserLoaderPage.ShowInstallPage(callback)
        return
    end
    if callback then
        callback(true)
    end
end

-- call this function to check if required npl browser is installed, if not it will begin install on most conditions. 
-- @param callback: function(bChecked) end, bChecked is true if successfully downloaded
-- return true if we are downloading
function NplBrowserLoaderPage.Check(callback)
	NplBrowserLoaderPage.isCheckOnce = true;
	
	-- mobile device depends on app store to update. 
    local IsTouchDevice = ParaEngine.GetAppCommandLineByParam('IsTouchDevice', nil)
    if (IsTouchDevice == "true" and not System.os.IsEmscripten()) then
        return;
    end

	if(not NplBrowserPlugin.OsSupported())then
	    LOG.std(nil, "info", "NplBrowserLoaderPage", "npl browser isn't supported on %s",System.os.GetPlatform());
        return
    end

    if (System.os.GetPlatform() == "mac" or System.os.GetPlatform() == 'ios' or System.os.GetPlatform() == "android"  or 
		System.os.IsEmscripten() or NplBrowserPlugin.IsWindowWebView2Found())then
        NplBrowserLoaderPage.loaded = true;
        if (type(callback) == "function") then
            callback(true);
        end
        return not NplBrowserLoaderPage.IsLoaded();
    end

	-- School 430 and 431 does not need webview, we will skip checking, but using what is installed as it is. 
	if not System.options.isChannel_430 and not System.options.isEducatePlatform then
		if (System.os.GetPlatform() == "win32") then
			-- win32 always use latest webview or latest cef3
			NplBrowserLoaderPage.CheckWebview(callback)
			return
		end
	end

    if(not NplBrowserLoaderPage.CheckCef3FileIntegrity(cef3_install_folder))then
        NplBrowserLoaderPage.loaded = false;
    end
    if(NplBrowserLoaderPage.try_times >= NplBrowserLoaderPage.try_update_max_times)then
	    LOG.std(nil, "warn", "NplBrowserLoaderPage", "try update times is full:%d/%d",NplBrowserLoaderPage.try_times,NplBrowserLoaderPage.try_update_max_times);
        return
    end
    if(NplBrowserLoaderPage.loaded)then
        if(callback)then
            callback(true);
        end
        return
    end
    if(callback)then
        NplBrowserLoaderPage.callback_maps[callback] = true;
    end
    if(NplBrowserLoaderPage.is_opened)then
        return not NplBrowserLoaderPage.IsLoaded();
    end

    local mod = BuildinMod.GetModByName("NplBrowser") or {};
    local version = mod.version;

    NplBrowserLoaderPage.is_opened = true;
    NplBrowserLoaderPage.buildin_version = version;
    
    NplBrowserLoaderPage.CheckCef3Old("browser_asset_manager",cef3_install_folder,config_file)
	return not NplBrowserLoaderPage.IsLoaded();
end

-- return true if we have at least one webview to use. 
function NplBrowserLoaderPage.IsLoaded()
    if (System.os.GetPlatform() == 'mac' or
        System.os.GetPlatform() == 'android' or
        System.os.GetPlatform() == 'ios' or
        System.os.IsEmscripten() or
        NplBrowserPlugin.IsWindowWebView2Found()) then
        return true;
    end
    return NplBrowserLoaderPage.loaded;
end

function NplBrowserLoaderPage.UpdateProgressText(text)
	if(page) then
		page:SetValue("progressText", text)
	end
end

--@param callback: function(bSucceed) end
function NplBrowserLoaderPage.ShowInstallPage(callback)
	local NplBrowserDialog = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserDialog.lua")
    NplBrowserDialog.ShowPage(callback)
end

-- check if webview or compatible cef3 plugin exist, if not, we will show install page
function NplBrowserLoaderPage.CheckWebview(callback)
    if(not NplBrowserPlugin.OsSupported())then
        LOG.std(nil, "info", "NplBrowserLoaderPage", "npl browser isn't supported on %s",System.os.GetPlatform());
		return
    end
    if (System.os.GetPlatform() == "mac" or System.os.GetPlatform() == 'ios' or System.os.GetPlatform() == "android"  or
		System.os.IsEmscripten() or NplBrowserPlugin.IsWindowWebView2Found())then
        NplBrowserLoaderPage.loaded = true;
        if (type(callback) == "function") then
            callback(true);
        end
    end
	if(NplBrowserLoaderPage.CheckLocalCef3Version() and NplBrowserLoaderPage.CheckCef3FileIntegrity(cef3_install_folder)) then
		NplBrowserLoaderPage.loaded = true;
		if (type(callback) == "function") then
            callback(true);
        end
		return true;
	else
		NplBrowserLoaderPage.ShowInstallPage(callback)
	end
end

-- @param dest_cef3_path: such as "cef3/"
-- @return true if cef3 files are removed, this could fail if some of the files are still in use. 
function NplBrowserLoaderPage.RemoveOldCef3(dest_cef3_path)
    ParaIO.DeleteFile(dest_cef3_path)
    for k, name in ipairs (NplBrowserLoaderPage.cef_main_files) do
        local filename = string.format("%s%s", dest_cef3_path, name);
        if(ParaIO.DoesFileExist(filename))then
            LOG.std(nil,"info","NplBrowserLoaderPage","remove old file=====%s",filename)
            return false
        end
    end
    return true;
end

-- install new cef3 that is API-compatible with webview2, just in case win7 does not support. 
-- @param callbackFunc: function(bSucceed, errMsg) end
-- @param progressCallbackFunc: function(state, progressText) end
function NplBrowserLoaderPage.InstallNewCef3(callbackFunc, progressCallbackFunc)
    local dest_cef3_path = cef3_install_folder
	if(not dest_cef3_path:match("/$")) then
		dest_cef3_path = dest_cef3_path.. "/"
	end
	if(not NplBrowserLoaderPage.RemoveOldCef3(dest_cef3_path)) then
        if(callbackFunc) then
            callbackFunc(false, L"无法彻底删除cef3目录，请重启电脑，再重新打开客户端。");
        end
        return 
    end

	GameLogic.GetFilters():add_filter("downloadFile_notify", NplBrowserLoaderPage.OnDownloadFileNotify);
	NPL.load("(gl)script/apps/Aries/Creator/Game/API/FileDownloader.lua");
	local FileDownloader = commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader");
	local tmpFilename = "temp/cef3.zip"
	ParaIO.DeleteFile(tmpFilename);
	FileDownloader:new():Init("cef3_for_webview2", NplBrowserLoaderPage.cef3ModInstallUrl, tmpFilename, function(bSucceed, filename) 
		if (bSucceed) then
			if(progressCallbackFunc) then
				progressCallbackFunc(1, L"下载完成，正在解压和安装，请稍后...")
			end
			commonlib.TimerManager.SetTimeout(function()  
				-- unzip zip file to disk
				NPL.load("(gl)script/ide/System/Util/ZipFile.lua");
				local ZipFile = commonlib.gettable("System.Util.ZipFile");
				local zipFile = ZipFile:new();
				if(zipFile:open(tmpFilename)) then
					-- TODO: move from ./temp/cef3 to ./cef3 folder, move version.txt last. 
					zipFile:unzip(dest_cef3_path);
					zipFile:close();
					ParaIO.DeleteFile(tmpFilename);

					NplBrowserLoaderPage.SetChecked(true)
					if(callbackFunc) then
						callbackFunc(true)
					end
				else
					if(callbackFunc) then
						callbackFunc(false, format(L"无法解压 %s.", tmpFilename))
					end
				end
			end, 30)
        else
			if(callbackFunc) then
				callbackFunc(false, format(L"无法下载插件: %s.", NplBrowserLoaderPage.cef3ModInstallUrl))
			end
        end
    end, nil, nil, nil, progressCallbackFunc);
end

function NplBrowserLoaderPage.OnDownloadFileNotify(state, text, currentFileSize, totalFileSize)
	echo({state, text, currentFileSize, totalFileSize})
	NplBrowserLoaderPage.UpdateProgressText(text)
end

-- @return true if we have CEF3 mini version installed
function NplBrowserLoaderPage.CheckLocalCef3Version()
    local versionDir = cef3_install_folder.."/"..version_txt
    if(ParaIO.DoesFileExist(versionDir))then
        local file = ParaIO.open(versionDir,"r");
        if(file:IsValid())then
			-- NOTE: version smaller than this are not allowed to run. one must upgrade the CEF3
            local content = file:GetText(0,-1);
            if content then
				local minVer = NplBrowserLoaderPage.minCef3Ver; 
				local v1, v2, v3 = content:match("(%d+)%D(%d+)%D(%d+)");
				if (v3) then
					v1,v2,v3 = tonumber(v1),tonumber(v2), tonumber(v3)
					if ( not (v1 < minVer[1] or
						 (v1 == minVer[1] and v2 < minVer[2]) or
						 (v1 == minVer[1] and v2 == minVer[2] and v3 < minVer[3]) ) ) then
						return true
					end
				end
            end
        end
    end
    return false
end

-- obsoleted: only used by old cef3 installer, use NplBrowserLoaderPage.ShowInstallPage instead.
function NplBrowserLoaderPage.ShowPage()
	local width, height=400, 50;
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url = "script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.html", 
		name = "NplBrowserLoaderPage.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true, 
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 2000,
		allowDrag = false,
		isTopLevel = true,
		directPosition = true,
			align = "_lt",
			x = 5,
			y = 40,
			width = width,
			height = height,
		cancelShowAnimation = true,
	});
end

function NplBrowserLoaderPage.Close()
	if(page) then
		page:CloseWindow();
		page = nil;
	end
end

-- obsoleted: old version checking using config_file file
function NplBrowserLoaderPage.CheckCef3Old(id,folder,config_file)
    if(not id or not folder or not config_file)then return end
    local redist_root = folder .. "/"
	ParaIO.CreateDirectory(redist_root);
    local a = NplBrowserLoaderPage.CreateOrGetAssetsManager(id,redist_root,config_file);
    if(not a)then return end

    if(NplBrowserLoaderPage.buildin_version)then
        a:loadLocalVersion()
		local cur_version = a:getCurVersion();
        local buildin_version = NplBrowserLoaderPage.buildin_version;
        local cur_version_value = AssetsManager.getVersionNumberValue(cur_version);
        local buildin_version_value = AssetsManager.getVersionNumberValue(buildin_version);
        if(cur_version_value >= buildin_version_value)then
            NplBrowserLoaderPage.SetChecked(true);
	        LOG.std(nil, "info", "NplBrowserLoaderPage", "local version is:%s, buildin version is %s, because of %s >= %s ,remote version check skipped",cur_version,buildin_version,cur_version,buildin_version);
            return
        end
    end
    NplBrowserLoaderPage.ShowPage();
    NplBrowserLoaderPage.ShowPercent(0);
    NplBrowserLoaderPage.try_times = NplBrowserLoaderPage.try_times + 1;
	LOG.std(nil, "warn", "NplBrowserLoaderPage", "try update times:%d",NplBrowserLoaderPage.try_times);

    a:check(nil,function()
        local cur_version = a:getCurVersion();
        local latest_version = a:getLatestVersion();
        if(a:isNeedUpdate())then
            NplBrowserLoaderPage.UpdateProgressText(string.format(L"当前版本(%s)        最新版本(%s)",cur_version, latest_version));

            local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
                a:download();
            end})
            mytimer:Change(3000, nil)
        else
            NplBrowserLoaderPage.SetChecked(true);
        end
    end);
end

-- obsoleted: only used by old cef3 installer
function NplBrowserLoaderPage.CreateOrGetAssetsManager(id,redist_root,config_file)
    if(not id)then return end

    local a = NplBrowserLoaderPage.asset_manager;
    if(not a)then

        a = AssetsManager:new();
        local timer;
        if(redist_root and config_file)then
            a:onInit(redist_root,config_file,function(state)
                if(state)then
                    if(state == AssetsManager.State.PREDOWNLOAD_VERSION)then
                        NplBrowserLoaderPage.UpdateProgressText(L"准备下载版本号");
                    elseif(state == AssetsManager.State.DOWNLOADING_VERSION)then
                        NplBrowserLoaderPage.UpdateProgressText(L"下载版本号");
                    elseif(state == AssetsManager.State.VERSION_CHECKED)then
                        NplBrowserLoaderPage.UpdateProgressText(L"检测版本号");
                    elseif(state == AssetsManager.State.VERSION_ERROR)then
                        NplBrowserLoaderPage.UpdateProgressText(L"版本号错误");
                    elseif(state == AssetsManager.State.PREDOWNLOAD_MANIFEST)then
                        NplBrowserLoaderPage.UpdateProgressText(L"准备下载文件列表");
                    elseif(state == AssetsManager.State.DOWNLOADING_MANIFEST)then
                        NplBrowserLoaderPage.UpdateProgressText(L"下载文件列表");
                    elseif(state == AssetsManager.State.MANIFEST_DOWNLOADED)then
                        NplBrowserLoaderPage.UpdateProgressText(L"下载文件列表完成");
                    elseif(state == AssetsManager.State.MANIFEST_ERROR)then
                        NplBrowserLoaderPage.UpdateProgressText(L"下载文件列表错误");
                    elseif(state == AssetsManager.State.PREDOWNLOAD_ASSETS)then
                        NplBrowserLoaderPage.UpdateProgressText(L"准备下载资源文件");

                        local nowTime = 0
                        local lastTime = 0
                        local interval = 100
                        local lastDownloadedSize = 0
                        timer = commonlib.Timer:new({callbackFunc = function(timer)
                            local p = a:getPercent();
                            p = math.floor(p * 100);
                            NplBrowserLoaderPage.ShowPercent(p);

                            local totalSize = a:getTotalSize()
                            local downloadedSize = a:getDownloadedSize()

                            nowTime = nowTime + interval

                            if downloadedSize > lastDownloadedSize then
                                local downloadSpeed = (downloadedSize - lastDownloadedSize) / ((nowTime - lastTime) / 1000)
                                lastDownloadedSize = downloadedSize
                                lastTime = nowTime

                                local tips = string.format("%.1f/%.1fMB(%.1fKB/S)", downloadedSize / 1024 / 1024, totalSize / 1024 / 1024, downloadSpeed / 1024)
                                NplBrowserLoaderPage.UpdateProgressText(tips)
                            end
                        end})
                        timer:Change(0, interval)
                    elseif(state == AssetsManager.State.DOWNLOADING_ASSETS)then
                    elseif(state == AssetsManager.State.ASSETS_DOWNLOADED)then
                        NplBrowserLoaderPage.UpdateProgressText(L"下载资源文件结束");
                        local p = a:getPercent();
                        p = math.floor(p * 100);
                        NplBrowserLoaderPage.ShowPercent(p);
                        if(timer)then
                             timer:Change();
                             NplBrowserLoaderPage.LastDownloadedSize = 0
                        end
                        a:apply();
                    elseif(state == AssetsManager.State.ASSETS_ERROR)then
                        NplBrowserLoaderPage.UpdateProgressText(L"下载资源文件错误");
                    elseif(state == AssetsManager.State.PREUPDATE)then
                        NplBrowserLoaderPage.UpdateProgressText(L"准备更新");
                    elseif(state == AssetsManager.State.UPDATING)then
                        NplBrowserLoaderPage.UpdateProgressText(L"更新中");
                    elseif(state == AssetsManager.State.UPDATED)then
                        if(not NplBrowserLoaderPage.CheckCef3FileIntegrity(redist_root))then
                            NplBrowserLoaderPage.UpdateProgressText(L"更新错误");
                            local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
                                NplBrowserLoaderPage.SetChecked(false);
                            end})
                            mytimer:Change(3000, nil)
                        else
                            LOG.std(nil, "debug", "AppLauncher", "更新完成")
                            NplBrowserLoaderPage.UpdateProgressText(L"更新完成");

                            NplBrowserLoaderPage.SetChecked(true);
                        end
                        

                    elseif(state == AssetsManager.State.FAIL_TO_UPDATED)then
                        NplBrowserLoaderPage.UpdateProgressText(L"更新错误");
                        local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
                            NplBrowserLoaderPage.SetChecked(false);
                        end})
                        mytimer:Change(3000, nil)
                    end

                end
            end, function (dest, cur, total)
                NplBrowserLoaderPage.OnMovingFileCallback(dest, cur, total)
            end);
        end
        NplBrowserLoaderPage.asset_manager = a;
    end
    return a;
end

-- obsoleted: only used by old cef3 installer
function NplBrowserLoaderPage.ShowPercent()
end

-- obsoleted: only used by old cef3 installer
function NplBrowserLoaderPage.OnMovingFileCallback(dest, cur, total)
    local tips = string.format(L"更新%s (%d/%d)", dest, cur, total)
    NplBrowserLoaderPage.UpdateProgressText(tips)

    local percent = 100 * cur / total
    NplBrowserLoaderPage.ShowPercent(percent)
end

-- call this function when cef3 and webview is ready to use. 
function NplBrowserLoaderPage.SetChecked(v)
    NplBrowserLoaderPage.loaded = v;
    for callback,v in pairs(NplBrowserLoaderPage.callback_maps) do
        callback(v)
    end
    NplBrowserLoaderPage.callback_maps = {};
    NplBrowserLoaderPage.Close();
    NplBrowserLoaderPage.is_opened = false;
    NplBrowserLoaderPage.asset_manager = nil;

    GameLogic.GetFilters():apply_filters('nplbrowser_checked', v)
end

-- check if main cef3 files exist, if not , the version file will be deleted for running auto update again
function NplBrowserLoaderPage.CheckCef3FileIntegrity(redist_root)
    for k,name in ipairs (NplBrowserLoaderPage.cef_main_files) do
        local filename = string.format("%s/%s",redist_root, name);
        if(not ParaIO.DoesFileExist(filename))then
	        LOG.std(nil, "error", "NplBrowserLoaderPage", "file does not exist:%s",filename);
            local version_filename = string.format("%s/%s",redist_root, AssetsManager.defaultVersionFilename);
            ParaIO.DeleteFile(version_filename);
	        LOG.std(nil, "warn", "NplBrowserLoaderPage", "delete the version file for running auto update again:%s",version_filename);
            return false;
        end
    end
    return true;
end