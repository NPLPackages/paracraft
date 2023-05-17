--[[
Title: ClientUpdater 
Author(s): LiXizhi
Date: 2018.7.26
Desc: for client update without NPLRuntime and dll
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ClientUpdater.lua");
local ClientUpdater = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdater");
local updater = ClientUpdater:new();
updater:Check(function(bNeedUpdate, latestVersion)
	if(bNeedUpdate) then
		updater:Download(function(bSucceed)
			if(bSucceed) then
				updater:Restart()
			else
				self:next_step({IsUpdaterStarted = true});
			end
		end)
	else
		self:next_step({IsUpdaterStarted = true});
	end
end);
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/DownloadWorld.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldLoginDocker.lua");
local ParaWorldLoginDocker = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLoginDocker")
local DownloadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.DownloadWorld")
local AutoUpdater = NPL.load("AutoUpdater");

local ClientUpdater = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdater"));

ClientUpdater.appname = "paracraftAppVersion";

function ClientUpdater:ctor()
	if(not ClientUpdater) then
		LOG.std(nil, "info", "ClientUpdater", "AutoUpdater not found");
		return;
	end
	local params = {
		_isMainUpdater=true, --是主要逻辑脚本的更新，而不是cef3等其他内容的更新，用于取版本号目录下的更新内容
	}
	local autoUpdater = AutoUpdater:new(params);
	self.autoUpdater = autoUpdater;

	autoUpdater.FilterFile = function(self, filename)
		if System.options.isChannel_430 and System.os.GetPlatform() == "win32" then 
			return false
		end
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
	autoUpdater:onInit(self:GetRedistFolder(), self:GetUpdateConfigFilename(),function(state, param1, param2)
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
				if(ClientUpdater.Download_callbackFunc) then
					ClientUpdater.Download_callbackFunc(false)
				end
            elseif(state == State.PREUPDATE)then
                
            elseif(state == State.UPDATING)then
                DownloadWorld.UpdateProgressText(L"正在安装更新");
            elseif(state == State.UPDATED)then
                DownloadWorld.UpdateProgressText(L"安装完成");
				ParaWorldLoginDocker.SetInstalling(false);
				if(ClientUpdater.Download_callbackFunc) then
					ClientUpdater.Download_callbackFunc(true);
				end
            elseif(state == State.FAIL_TO_UPDATED)then
				ParaWorldLoginDocker.SetInstalling(false);
				local filename, errorCode = param1, param2;
				if(errorCode == AutoUpdater.UpdateFailedReason.MD5) then
					_guihelper.MessageBox(format(L"文件MD5校验失败:%s, 请重新更新", filename or ""));
				elseif(errorCode == AutoUpdater.UpdateFailedReason.Uncompress) then
					_guihelper.MessageBox(format(L"无法解压文件:%s, 请重试", filename or ""));
				elseif(errorCode == AutoUpdater.UpdateFailedReason.Move) then
					_guihelper.MessageBox(format(L"无法应用更新: 无法移动文件到%s.", filename or "")..L"请确保目前只有一个实例在运行");
				else
					_guihelper.MessageBox(L"无法应用更新"..L"请确保目前只有一个实例在运行");
				end
				if(ClientUpdater.Download_callbackFunc) then
					ClientUpdater.Download_callbackFunc(false)
				end
            end    
        end
    end);

	print("System.options.useRealLatestVersion",System.options.useRealLatestVersion)
    if System.options.useRealLatestVersion~=true then --使用灰度,true表示不使用灰度
        autoUpdater:resetVersionUrlWithKeepwork()
    end
end

-- static function:
-- this is the same folder as haqi
function ClientUpdater:GetRedistFolder()
	return ParaWorldLoginDocker.GetAppFolder(self.appname);
end

-- static function:
function ClientUpdater:GetUpdateConfigFilename()
	return ParaWorldLoginDocker.GetAppConfigByName(self.appname)
end

-- copy assets from package at first time
function ClientUpdater:CopyAssetsToWritablePath()
	local version = ParaIO.open(self:GetRedistFolder() .. 'version.txt', "r");
	if (version:IsValid()) then
		self.autoUpdater:loadLocalVersion()
		local root_curVer = self:GetCurrentVersion()
		local redist_curVer = self:getCurVersion()
		if self.autoUpdater:_compareVer(root_curVer,redist_curVer)>0 then --说明通过launcher更新过了，删除更新文件夹的文件，重新覆盖
			ParaIO.DeleteFile(self:GetRedistFolder())
		else
			return
		end
	end

	local fileList = {
		'version.txt',
		'assets_manifest.txt',
		'npl_packages/ParacraftBuildinMod.zip',
		'main.pkg',
		'main_mobile_res.pkg',
		'main150727.pkg',
	}

	for key, item in ipairs(fileList) do
		ParaIO.CopyFile(
			item,
			ParaIO.GetWritablePath() .. 'apps/haqi/' .. item,
			true
		)
	end
end

-- public function:
-- @param callbackFunc: function(bNeedUpdate, latestVersion)
function ClientUpdater:Check(callbackFunc)
	if(not self.autoUpdater) then
		if(callbackFunc) then
			callbackFunc(false);
		end
		return
	end

	self:CopyAssetsToWritablePath()

	self.autoUpdater:check(nil, function(bSucceed)
		if(not callbackFunc) then
			return
		end

		if(bSucceed) then
			local bNeedUpdate = self.autoUpdater:isNeedUpdate()
            local curVersion = self:getCurVersion()
            local latestVersion = self:getLatestVersion()
			if bNeedUpdate then
                local bAllowSkip = self.autoUpdater:isAllowSkip()
                callbackFunc(true, latestVersion,curVersion,bAllowSkip,nil);
            else
                local needAppStoreUpdate = self.autoUpdater:NeedAppStoreUpdate()
                callbackFunc(false, latestVersion,curVersion,nil,needAppStoreUpdate);
            end
		else
			LOG.std(nil, "info", "ClientUpdater", "version error");
			callbackFunc(nil, self.autoUpdater:getLatestVersion());
		end
	end);
end

function ClientUpdater:getComparedResult()
	return self.autoUpdater._comparedVersion
end

function ClientUpdater:getAppStoreUrl()
	return self.autoUpdater:getAppStoreUrl()
end

-- public function:
-- @param callbackFunc: function(bSucceed)
function ClientUpdater:Download(callbackFunc)
	print("hyz update log--------ClientUpdater 132",self.appname)
	ClientUpdater.Download_callbackFunc = callbackFunc
	if(self.autoUpdater:isNeedUpdate())then
		ParaWorldLoginDocker.SetInstalling(true, ParaWorldLoginDocker.GetAppTitle(self.appname));
		DownloadWorld.ShowPage(self.gamename);
		self.autoUpdater:download()
	else
		callbackFunc(true)
	end

end
function ClientUpdater:OnClickUpdate()
	ParaGlobal.ShellExecute("open", L"https://www.paracraft.cn/download", "", "", 1);
end

--原始根目录下的version.txt
function ClientUpdater:GetCurrentVersion()
	NPL.load("(gl)script/apps/Aries/Creator/Game/game_options.lua");
	local options = commonlib.gettable("MyCompany.Aries.Game.GameLogic.options")
	return options.GetClientVersion() or ""
end

--更新路径（self:GetRedistFolder()）下的version.txt
function ClientUpdater:getCurVersion()
	return self.autoUpdater:getCurVersion()
end

function ClientUpdater:getLatestVersion()
	return self.autoUpdater:getLatestVersion()
end

function ClientUpdater:Restart()
	LOG.std(nil, "info", "ClientUpdater", "Restart");

	NPL.load("(gl)script/apps/Aries/Creator/Game/game_options.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/UrlProtocolHandler.lua");

	local UrlProtocolHandler = commonlib.gettable("MyCompany.Aries.Creator.Game.UrlProtocolHandler");

	local urlProtocol = UrlProtocolHandler:GetParacraftProtocol(ParaEngine.GetAppCommandLine() or '');
	local restartCmd = '';

	if (urlProtocol and type(urlProtocol) == 'string') then
		restartCmd = format('%s paraworldapp="%s" nplver="%s"', 'paracraft://' .. urlProtocol, self.appname, self:GetCurrentVersion()) -- ParaEngine.GetVersion()
	else
		restartCmd = format('paraworldapp="%s" nplver="%s"', self.appname, self:GetCurrentVersion()) -- ParaEngine.GetVersion()
	end

	restartCmd = restartCmd .. " default_ui_scaling=\"" .. System.options.default_ui_scaling[1] .. "\"";

	LOG.std(nil, "info", "ClientUpdater", "%s %s %s", self.appname, "restartCmd: ", restartCmd);

	ParaWorldLoginDocker.Restart(self.appname, restartCmd);
end
