--[[
Title: AutoUpdateLoaderPage
Author(s): leio
Date: 2019.12.26
Desc: 
this is a common page for showing download progress by AssetsManager 
use the lib:
------------------------------------------------------------
local AutoUpdateLoaderPage = NPL.load("(gl)script/apps/Aries/Creator/Game/AutoUpdateLoader/AutoUpdateLoaderPage.lua");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/BuildinMod.lua");
NPL.load("npl_mod/AutoUpdater/AssetsManager.lua");
NPL.load("(gl)script/ide/timer.lua");
local BuildinMod = commonlib.gettable("MyCompany.Aries.Game.MainLogin.BuildinMod");
local AssetsManager = commonlib.gettable("Mod.AutoUpdater.AssetsManager");
local AutoUpdateLoaderPage = commonlib.inherit(nil, NPL.export());

function AutoUpdateLoaderPage:ctor()
end
function AutoUpdateLoaderPage:OnInit(name,mod_name,dest_folder,config_file,main_files,wnd_config)
    self.name = name;
    self.mod_name = mod_name;
    self.dest_folder = dest_folder;
    self.config_file = config_file;
    self.main_files = main_files;
    self.wnd_config = wnd_config or {
        url = "script/apps/Aries/Creator/Game/AutoUpdateLoader/AutoUpdateLoaderPage.html",
        align = "_lt",
		x = 5,
		y = 40,
		width = 400,
		height = 50,
    };
    self.loaded = false;
    self.timer = nil;
    self.try_update_max_times = 3;
    self.try_times = 0;
    self.asset_manager = nil;
    return self;
end
function AutoUpdateLoaderPage:SetPageCtrl(pageCtrl)
    if(not pageCtrl)then
        return
    end
    self.pageCtrl = pageCtrl;
    self.pageCtrl.page_name = self.name;
end

function AutoUpdateLoaderPage:ShowPage()
    local params = {
	    url = self.wnd_config.url, 
	    name = self.name, 
	    isShowTitleBar = false,
	    DestroyOnClose = true, 
	    style = CommonCtrl.WindowFrame.ContainerStyle,
	    zorder = -1,
	    allowDrag = false,
	    isTopLevel = false,
	    directPosition = true,
	    align = self.wnd_config.align,
	    x = self.wnd_config.x,
	    y = self.wnd_config.y,
	    width = self.wnd_config.width,
	    height = self.wnd_config.height,
	    cancelShowAnimation = true,
    }
	System.App.Commands.Call("File.MCMLWindowFrame",params);
    self:SetPageCtrl(params._page);
    -- for get page_name in AutoUpdateLoaderPage.html
    self:Refresh();
end
function AutoUpdateLoaderPage:UpdateProgressText(text)
	if(self.pageCtrl) then
		self.pageCtrl:SetValue("progressText", text)
	end
end
function AutoUpdateLoaderPage:Close()
	if(self.pageCtrl) then
		self.pageCtrl:CloseWindow();
		self.pageCtrl = nil;
	end
end
function AutoUpdateLoaderPage:CreateOrGetAssetsManager(id,redist_root,config_file)
    if(not id)then return end

    local a = self.asset_manager;
    if(not a)then

        a = AssetsManager:new();
        local timer;
        if(redist_root and config_file)then
            a:onInit(redist_root,config_file,function(state)
                if(state)then
                    if(state == AssetsManager.State.PREDOWNLOAD_VERSION)then
                        self:UpdateProgressText(L"准备下载版本号");
                    elseif(state == AssetsManager.State.DOWNLOADING_VERSION)then
                        self:UpdateProgressText(L"下载版本号");
                    elseif(state == AssetsManager.State.VERSION_CHECKED)then
                        self:UpdateProgressText(L"检测版本号");
                    elseif(state == AssetsManager.State.VERSION_ERROR)then
                        self:UpdateProgressText(L"版本号错误");
                    elseif(state == AssetsManager.State.PREDOWNLOAD_MANIFEST)then
                        self:UpdateProgressText(L"准备下载文件列表");
                    elseif(state == AssetsManager.State.DOWNLOADING_MANIFEST)then
                        self:UpdateProgressText(L"下载文件列表");
                    elseif(state == AssetsManager.State.MANIFEST_DOWNLOADED)then
                        self:UpdateProgressText(L"下载文件列表完成");
                    elseif(state == AssetsManager.State.MANIFEST_ERROR)then
                        self:UpdateProgressText(L"下载文件列表错误");
                    elseif(state == AssetsManager.State.PREDOWNLOAD_ASSETS)then
                        self:UpdateProgressText(L"准备下载资源文件");

                        local nowTime = 0
                        local lastTime = 0
                        local interval = 100
                        local lastDownloadedSize = 0
                        timer = commonlib.Timer:new({callbackFunc = function(timer)
                            local p = a:getPercent();
                            p = math.floor(p * 100);
                            self:ShowPercent(p);

                            local totalSize = a:getTotalSize()
                            local downloadedSize = a:getDownloadedSize()

                            nowTime = nowTime + interval

                            if downloadedSize > lastDownloadedSize then
                                local downloadSpeed = (downloadedSize - lastDownloadedSize) / ((nowTime - lastTime) / 1000)
                                lastDownloadedSize = downloadedSize
                                lastTime = nowTime

                                local tips = string.format("%.1f/%.1fMB(%.1fKB/S)", downloadedSize / 1024 / 1024, totalSize / 1024 / 1024, downloadSpeed / 1024)
                                self:UpdateProgressText(tips)
                            end
                        end})
                        timer:Change(0, interval)
                    elseif(state == AssetsManager.State.DOWNLOADING_ASSETS)then
                    elseif(state == AssetsManager.State.ASSETS_DOWNLOADED)then
                        self:UpdateProgressText(L"下载资源文件结束");
                        local p = a:getPercent();
                        p = math.floor(p * 100);
                        self:ShowPercent(p);
                        if(timer)then
                             timer:Change();
                             self.LastDownloadedSize = 0
                        end
                        a:apply();
                    elseif(state == AssetsManager.State.ASSETS_ERROR)then
                        self:UpdateProgressText(L"下载资源文件错误");
                    elseif(state == AssetsManager.State.PREUPDATE)then
                        self:UpdateProgressText(L"准备更新");
                    elseif(state == AssetsManager.State.UPDATING)then
                        self:UpdateProgressText(L"更新中");
                    elseif(state == AssetsManager.State.UPDATED)then
                        LOG.std(nil, "debug", "AppLauncher", "更新完成")
                        self:UpdateProgressText(L"更新完成");

                        local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
                            self:SetChecked(true);
                        end})
                        mytimer:Change(3000, nil)

                    elseif(state == AssetsManager.State.FAIL_TO_UPDATED)then
                        self:UpdateProgressText(L"更新错误");
                        local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
                            self:SetChecked(false);
                        end})
                        mytimer:Change(3000, nil)
                    end

                end
            end, function (dest, cur, total)
                self:OnMovingFileCallback(dest, cur, total)
            end);
        end
        self.asset_manager = a;
    end
    return a;
end

-- @param callback: function(bChecked) end
function AutoUpdateLoaderPage:Check(callback)
    if(not self:MainFilesExisted(self.dest_folder))then
        self.loaded = false;
    end
    if(self.try_times >= self.try_update_max_times)then
	    LOG.std(nil, "warn", "AutoUpdateLoaderPage.OnCheck", "[%s] try update times is full:%d/%d",self.name, self.try_times,self.try_update_max_times);
        return
    end
    if(self.loaded)then
        if(callback)then
            callback(true);
        end
        return
    end
    if(self.is_opened)then
        return
    end

    
    local mod = BuildinMod.GetModByName(self.mod_name);
    if(mod)then
        self.buildin_version = mod.version;
    end

    self.is_opened = true;
    self.callback = callback;
    local asset_manager_name = self.name .. "_asset_manager";
    self:OnCheck(asset_manager_name,self.dest_folder,self.config_file)
end

function AutoUpdateLoaderPage:OnCheck(id,folder,config_file)

    if(not id or not folder or not config_file)then return end
    local redist_root = folder .. "/"
	ParaIO.CreateDirectory(redist_root);
    local a = self:CreateOrGetAssetsManager(id,redist_root,config_file);
    if(not a)then return end

    if(self.buildin_version)then
        a:loadLocalVersion()
		local cur_version = a:getCurVersion();
        local buildin_version = self.buildin_version;
        local cur_version_value = AssetsManager.getVersionNumberValue(cur_version);
        local buildin_version_value = AssetsManager.getVersionNumberValue(buildin_version);
        if(cur_version_value >= buildin_version_value)then
            self:SetChecked(true);
	        LOG.std(nil, "info", "AutoUpdateLoaderPage.OnCheck", "[%s] local version is:%s, buildin version is %s, because of %s >= %s ,remote version check skipped",self.name, cur_version,buildin_version,cur_version,buildin_version);
            return
        end
    end
    self:ShowPage();
    self:ShowPercent(0);
    self.try_times = self.try_times + 1;
	LOG.std(nil, "warn", "AutoUpdateLoaderPage.OnCheck", "[%s] try update times:%d",self.name, self.try_times);

    a:check(nil,function()
        local cur_version = a:getCurVersion();
        local latest_version = a:getLatestVersion();
        if(a:isNeedUpdate())then
            self:UpdateProgressText(string.format(L"当前版本(%s)        最新版本(%s)",cur_version, latest_version));

            local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
                a:download();
            end})
            mytimer:Change(3000, nil)
        else
            self:SetChecked(true);
        end
    end);
end
function AutoUpdateLoaderPage:ShowPercent()

end
function AutoUpdateLoaderPage:OnMovingFileCallback(dest, cur, total)
    local tips = string.format(L"更新%s (%d/%d)", dest, cur, total)
    self:UpdateProgressText(tips)

    local percent = 100 * cur / total
    self:ShowPercent(percent)
end
function AutoUpdateLoaderPage:SetChecked(v)
    self.loaded = v;
    if(self.callback)then
        self.callback(v,self.asset_manager._downloadUnits);

        self.callback = nil;
    end
    self:Close();
    self.is_opened = false;
    self.asset_manager = nil;
end
function AutoUpdateLoaderPage:IsLoaded()
    return self.loaded;
end
-- check if main files are existed, if found anyone isn't exited, the version file will be deleted for running auto update again
function AutoUpdateLoaderPage:MainFilesExisted(redist_root)
    for k,name in ipairs (self.main_files) do
        local filename = string.format("%s/%s",redist_root, name);
        if(not ParaIO.DoesFileExist(filename))then
	        LOG.std(nil, "error", "AutoUpdateLoaderPage.MainFilesExisted", "[%s] the file isn't existed:%s",self.name, filename);
            local version_filename = string.format("%s/%s",redist_root, AssetsManager.defaultVersionFilename);
            ParaIO.DeleteFile(version_filename);
	        LOG.std(nil, "warn", "AutoUpdateLoaderPage.MainFilesExisted", "[%s] delete the version file for running auto update again:%s",self.name, version_filename);
            return false;
        end
    end
    return true;
end
function AutoUpdateLoaderPage:Refresh()
    if(self.pageCtrl)then
        self.pageCtrl:Refresh(0);
    end
end