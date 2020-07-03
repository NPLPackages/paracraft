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
NplBrowserLoaderPage.Check()
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

local dest_folder = "cef3";
local config_file = "script/apps/Aries/Creator/Game/NplBrowser/configs/nplbrowser.xml";
local page;
-- init function. page script fresh is set to false.
function NplBrowserLoaderPage.OnInit()
	page = document:GetPageCtrl();
end
function NplBrowserLoaderPage.ShowPage()
	local width, height=400, 50;
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url = "script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.html", 
		name = "NplBrowserLoaderPage.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true, 
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 10,
		allowDrag = false,
		isTopLevel = false,
		directPosition = true,
			align = "_lt",
			x = 5,
			y = 40,
			width = width,
			height = height,
		cancelShowAnimation = true,
	});
end
function NplBrowserLoaderPage.UpdateProgressText(text)
	if(page) then
		page:SetValue("progressText", text)
	end
end
function NplBrowserLoaderPage.Close()
	if(page) then
		page:CloseWindow();
		page = nil;
	end
end
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
                        if(not NplBrowserLoaderPage.MainFilesExisted(redist_root))then
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


-- @param callback: function(bChecked) end, bChecked is true if successfully downloaded
-- return true if we are downloading
function NplBrowserLoaderPage.Check(callback)
    if(not NplBrowserPlugin.OsSupported())then
	    LOG.std(nil, "info", "NplBrowserLoaderPage.OnCheck", "npl browser isn't supported on %s",System.os.GetPlatform());
        return
    end
    if(System.os.GetPlatform() == "mac")then
        NplBrowserLoaderPage.loaded = true;
        if (type(callback) == "function") then
            callback(true);
        end
        return
    end
    if(not NplBrowserLoaderPage.MainFilesExisted(dest_folder))then
        NplBrowserLoaderPage.loaded = false;
    end
    if(NplBrowserLoaderPage.try_times >= NplBrowserLoaderPage.try_update_max_times)then
	    LOG.std(nil, "warn", "NplBrowserLoaderPage.OnCheck", "try update times is full:%d/%d",NplBrowserLoaderPage.try_times,NplBrowserLoaderPage.try_update_max_times);
        return
    end
    if(NplBrowserLoaderPage.loaded)then
        if(callback)then
            callback(true);
        end
        return
    end
    if(NplBrowserLoaderPage.is_opened)then
        return not NplBrowserLoaderPage.IsLoaded();
    end

    local mod = BuildinMod.GetModByName("NplBrowser") or {};
    local version = mod.version;

    NplBrowserLoaderPage.is_opened = true;
    NplBrowserLoaderPage.buildin_version = version;
    NplBrowserLoaderPage.callback = callback;
    NplBrowserLoaderPage.OnCheck("browser_asset_manager",dest_folder,config_file)
	return not NplBrowserLoaderPage.IsLoaded();
end
function NplBrowserLoaderPage.OnCheck(id,folder,config_file)

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
	        LOG.std(nil, "info", "NplBrowserLoaderPage.OnCheck", "local version is:%s, buildin version is %s, because of %s >= %s ,remote version check skipped",cur_version,buildin_version,cur_version,buildin_version);
            return
        end
    end
    NplBrowserLoaderPage.ShowPage();
    NplBrowserLoaderPage.ShowPercent(0);
    NplBrowserLoaderPage.try_times = NplBrowserLoaderPage.try_times + 1;
	LOG.std(nil, "warn", "NplBrowserLoaderPage.OnCheck", "try update times:%d",NplBrowserLoaderPage.try_times);

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
function NplBrowserLoaderPage.ShowPercent()

end

function NplBrowserLoaderPage.OnMovingFileCallback(dest, cur, total)
    local tips = string.format(L"更新%s (%d/%d)", dest, cur, total)
    NplBrowserLoaderPage.UpdateProgressText(tips)

    local percent = 100 * cur / total
    NplBrowserLoaderPage.ShowPercent(percent)
end
function NplBrowserLoaderPage.SetChecked(v)
    NplBrowserLoaderPage.loaded = v;
    if(v)then
        local NplBrowserManager = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserManager.lua");
        NplBrowserManager:PreShowAll();
    end
    if(NplBrowserLoaderPage.callback)then
        NplBrowserLoaderPage.callback(v);

        NplBrowserLoaderPage.callback = nil;
    end
    NplBrowserLoaderPage.Close();
    NplBrowserLoaderPage.is_opened = false;
    NplBrowserLoaderPage.asset_manager = nil;
end
function NplBrowserLoaderPage.IsLoaded()
    return NplBrowserLoaderPage.loaded;
end
-- check if main files are existed, if found anyone isn't exited, the version file will be deleted for running auto update again
function NplBrowserLoaderPage.MainFilesExisted(redist_root)
    for k,name in ipairs (NplBrowserLoaderPage.cef_main_files) do
        local filename = string.format("%s/%s",redist_root, name);
        if(not ParaIO.DoesFileExist(filename))then
	        LOG.std(nil, "error", "NplBrowserLoaderPage.MainFilesExisted", "the file isn't existed:%s",filename);
            local version_filename = string.format("%s/%s",redist_root, AssetsManager.defaultVersionFilename);
            ParaIO.DeleteFile(version_filename);
	        LOG.std(nil, "warn", "NplBrowserLoaderPage.MainFilesExisted", "delete the version file for running auto update again:%s",version_filename);
            return false;
        end
    end
    return true;
end