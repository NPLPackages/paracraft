--[[
Title: ClientUpdater430 
Author(s): hyz
Date: 2022.3.28
Desc: windows430下载更新,启动launcher应用更新；静默更新；局域网更新作为服务器时获取下载清单
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ClientUpdater430.lua");
local ClientUpdater430 = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdater430");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/DownloadWorld.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldLoginDocker.lua");
local ParaWorldLoginDocker = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLoginDocker")
local DownloadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.DownloadWorld")
local AutoUpdater = NPL.load("AutoUpdater");
local Broadcast = NPL.load("Mod/GeneralGameServerMod/CommonLib/Broadcast.lua");
local ClientUpdater430 = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdater430"));

function ClientUpdater430:ctor()
    self._isAutoInstall = true
	if(not ClientUpdater430) then
		LOG.std(nil, "info", "ClientUpdater430", "AutoUpdater not found");
		return;
	end
    local params = {
        _needApplyByLauncher=true, --使用Launcher辅助进行更新，只有windows且非xp走这里
        _isMainUpdater=true, --是主要逻辑脚本的更新，而不是cef3等其他内容的更新，用于取版本号目录下的更新内容
    }
	local autoUpdater = AutoUpdater:new(params);
	self.autoUpdater = autoUpdater;

    local timer;
	autoUpdater:onInit(ParaIO.GetWritablePath(), ParaWorldLoginDocker.GetAppConfigByName("paracraftAppVersion"), function(state,param1, param2)
        if(state)then
			local State = AutoUpdater.State;
            if(state == State.PREDOWNLOAD_VERSION)then
                self:UpdateProgressText(L"预下载版本号");
            elseif(state == State.DOWNLOADING_VERSION)then
                self:UpdateProgressText(L"正在下载版本信息");
            elseif(state == State.VERSION_CHECKED)then
                self:UpdateProgressText(L"版本验证完毕");
            elseif(state == State.VERSION_ERROR)then
				_guihelper.MessageBox(L"无法获取版本信息");

            elseif(state == State.PREDOWNLOAD_MANIFEST)then
                self:UpdateProgressText(L"资源列表预下载");
            elseif(state == State.DOWNLOADING_MANIFEST)then
                self:UpdateProgressText(L"资源列表下载中");
            elseif(state == State.MANIFEST_DOWNLOADED)then
				self:UpdateProgressText(L"已经获取资源列表");
            elseif(state == State.MANIFEST_ERROR)then
				_guihelper.MessageBox(L"无法获取资源列表");
				-- if(self.callback) then
				-- 	self.callback(false)
				-- end
            elseif(state == State.PREDOWNLOAD_ASSETS)then
				self:UpdateProgressText(L"准备下载资源文件");
				local nowTime = 0
                local lastTime = 0
                local interval = 100
                local lastDownloadedSize = 0
                timer = commonlib.Timer:new({callbackFunc = function()
					local totalSize = autoUpdater:getTotalSize()
                    local downloadedSize = autoUpdater:getDownloadedSize()
					nowTime = nowTime + interval;

					if downloadedSize > lastDownloadedSize then
                        local downloadSpeed = (downloadedSize - lastDownloadedSize) / ((nowTime - lastTime) / 1000)
                        lastDownloadedSize = downloadedSize
                        lastTime = nowTime
                        local tips = string.format("%.1f/%.1fMB(%.1fKB/S)", downloadedSize / 1024 / 1024, totalSize / 1024 / 1024, downloadSpeed / 1024)
						self:UpdateProgressText(tips);
                    end
					
                end})
                timer:Change(0, 100)
            elseif(state == State.DOWNLOADING_ASSETS)then
                -- self:UpdateProgressText(L"正在下载资源");
            elseif(state == State.ASSETS_DOWNLOADED)then
                print("-------资源下载完成")
                self:UpdateProgressText(L"全部资源下载完成");
				if(timer) then
					timer:Change();
                    timer = nil
				end
                if self._isAutoInstall then
                    autoUpdater:apply();
                else
                    autoUpdater:prepare430apply()
                    self:ShowSlientlyPage()
                end
            elseif(state == State.ASSETS_ERROR)then
				_guihelper.MessageBox(L"无法获取资源");
				if(timer) then
					timer:Change();
                    timer = nil
				end
            elseif(state == State.PREUPDATE)then
                
            elseif(state == State.UPDATING)then
                
            elseif(state == State.UPDATED)then
                
            elseif(state == State.FAIL_TO_UPDATED)then
				
            end    
        end
	end)
    local ok, errinfo = pcall(function()
        self.WriteConfigForLauncher()
    end)
        
    print("System.options.useRealLatestVersion",System.options.useRealLatestVersion)
    if System.options.useRealLatestVersion~=true then --使用灰度,true表示不使用灰度
        autoUpdater:resetVersionUrlWithKeepwork()
    end
    
    -- if System.options.isChannel_430 then
        -- autoUpdater:resetVersionUrlWithKeepwork()
    -- else 
    --     --TODO
    --     --[[
    --         因为非430版需要用到launcher，而launcher还没发布,所以还用旧的请求版本信息链接:(http://tmlog.paraengine.com/version.php);
    --         家庭版的launcher发布以后，这个条件判断要去掉
    --     ]]
    -- end
end

--获取要下载文件列表（作为局域网更新服务器时使用）
--callbakc(download_list,delete_list)
function ClientUpdater430:downloadManifest(callback)
    local function download_deletefile_list(srcUrl,file_name,file_md5,cb)
        System.os.GetUrl(srcUrl, function(err, msg, data)
            local delete_list = {}
            if(err == 200 and data)then
                local tempFile = ParaIO.GetWritablePath().."temp_"..file_name;
                local CommonLib = NPL.load("(gl)script/ide/System/Util/CommonLib.lua");
                CommonLib.WriteFile(tempFile,data)
                local md5 = CommonLib.GetFileMD5(tempFile)
                if md5==file_md5 then
                    local storagePath = tempFile;
                    local indexOfLastSeparator = string.find(storagePath, ".[^.]*$");
                    local destFileName = string.sub(storagePath,0,indexOfLastSeparator-1);
                    local ret = self.autoUpdater:decompress(storagePath,destFileName)
                    if ret then
                        local file = ParaIO.open(destFileName,"r");
                        if(file:IsValid())then
                            local content = file:GetText();
                            local name;
                            for name in string.gfind(content, "[^,]+") do
                                name = string.gsub(name,"%s","");
                                table.insert(delete_list,name)
                            end
                            file:close();
                        else
                            cb(delete_list)
                            LOG.std(nil, "info", "AssetsManager", "can't open file:%s",delete_file_path);
                        end
                        cb(delete_list)
                    end
                else
                    cb(delete_list)
                end
            else
                cb(delete_list)
            end
        end)
    end
    local _func;
    _func = function(hostServerIndex)
        local _updater = self.autoUpdater

        local len = #_updater.configs.hosts;
        if (hostServerIndex > len)then
            if callback then
                callback({})
            end
            return;
        end
        local updatePackUrl = _updater:getPatchListUrl(true, hostServerIndex); --直接拿全量更新清单
    
        local hostServer = _updater.configs.hosts[hostServerIndex];
        LOG.std(nil, "info", "ClientUpdater430", "checking host server: %s",hostServer);
        LOG.std(nil, "info", "ClientUpdater430", "updatePackUrl is : %s",updatePackUrl);
    
        System.os.GetUrl(updatePackUrl, function(err, msg, data)
            if(err == 200 and data)then
                local list = self:parseManifest(data,_updater.configs.hosts[hostServerIndex]);

                local len = #list
                if len==0 then
                    _func( hostServerIndex + 1);
                    return
                end
                for i=1,len do
                    list[i] = list[i].file_name
                end
                
                if callback then
                    callback(list,{})
                end
            else
                local len = #_updater.configs.hosts;
                _func( hostServerIndex + 1);
            end
        end)
    end
    _func(1)
end

--（作为局域网更新服务器时使用）
function ClientUpdater430:parseManifest(data,hostServer)
    local function split(str)
        local result = {};
        local s;
        for s in string.gfind(str, "[^,]+") do
            table.insert(result,s);
		end
        return result;
    end
    local _downloadUnits = {}
    -- check duplicated urls
    local duplicated_urls = {};
    local line;
    for line in string.gmatch(data,"([^\r\n]*)\r?\n?") do
        if(line and line ~= "")then
            local arr = split(line);
            if(#arr > 2)then
                local file_name = arr[1];
				if(true) then
					local file_md5 = arr[2];
					local size = arr[3];
					local file_size = tonumber(size) or 0;
					local download_path = string.format("%s,%s,%s.p", file_name, file_md5, size);
					local download_unit = {
						srcUrl = string.format("%scoredownload/update/%s", hostServer, download_path),
						file_name = file_name,
						file_size = file_size,
						file_md5 = file_md5,
					}
					
                    local srcUrl = download_unit.srcUrl;
                    if(not duplicated_urls[srcUrl])then
					    table.insert(_downloadUnits,download_unit);
                        duplicated_urls[srcUrl] = true;
                    else
						LOG.std(nil, "debug", "ClientUpdater430", "found duplicated url: %s",srcUrl);
                    end
				end
            end
        end
    end
    local len = #_downloadUnits;
	LOG.std(nil, "info", "ClientUpdater430", "the length of downloadUnits:%d",len);
    return _downloadUnits
end

function ClientUpdater430:UpdateProgressText(text)
    local ret = GameLogic.GetFilters():apply_filters('check_is_downloading_from_lan',{
    })
    if ret and ret._hasStartDownloaded then ---已经在局域网开始更新了,停止下载任务
        return
    end
    DownloadWorld.UpdateProgressText(text);
end

-- public function:
-- @param callbackFunc: function(bNeedUpdate, latestVersion,curVersion)
function ClientUpdater430:Check(callbackFunc)

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
			LOG.std(nil, "info", "ClientUpdater430", "version error");
			callbackFunc(nil);
		end
	end);
end

function ClientUpdater430:Download()
    self._isAutoInstall = true
    
    DownloadWorld.ShowPage(self.gamename,10001);
    self.autoUpdater:download()
end

function ClientUpdater430:DownloadSliently()
    self._isAutoInstall = false
    self.autoUpdater:download()
end

--更新路径（self:GetRedistFolder()）下的version.txt
function ClientUpdater430:getCurVersion()
	return self.autoUpdater:getCurVersion()
end

function ClientUpdater430:getLatestVersion()
	return self.autoUpdater:getLatestVersion()
end

--是否能跳过本次更新
function ClientUpdater430:canAutoSkip()
	return self.autoUpdater:isAllowSkip()
end

--检查是否需要静默下载,一个机房只需要一个静默下载的就够了，
--因为只要有一个更新好了，其他的就走UpdateSyncer自动从局域网更新了
function ClientUpdater430:checkNeedSlientDownload()
    -- if not System.options.isDevMode then --目前只在调试模式生效，上线前要删掉
    --     return
    -- end
    -- if System.options.channelId~="430" then --本逻辑是基于局域网的
    --     return
    -- end
    if not self:canAutoSkip() then --保证已经请求过版本更新信息
        return
    end
    
    self._allPC = {} --一段时间内能检测到的局域网内的pc
    local _onBroadcast,_onBroadcast2,_onBroadcast3;
    _onBroadcast = function(msg) --收集所有发出广播的电脑，用时间戳排序，用以取一个最早的
        local data = msg.__data__.msg
        local timeStramp = data.timeStramp

        self._allPC[#self._allPC+1] = {
            timeStramp = data.timeStramp,
            ip = msg.ip,
            ver = data.ver --发广播的那台电脑，版本号
        }
    end
    Broadcast:RegisterBroadcaseEvent("430_slientownload_precheck",_onBroadcast)

    _onBroadcast2 = function(msg) --是否有人已经开始下载了
        print("-------some one has started download",msg.ip,os.clock())
        Broadcast:RemoveBroadcaseEvent("430_slientownload_precheck",_onBroadcast)
        Broadcast:RemoveBroadcaseEvent("430_slientownloading",_onBroadcast2)
        Broadcast:RemoveBroadcaseEvent("this_is_lan_update_server",_onBroadcast3)
        self._hasOtherUpdate = true
    end
    Broadcast:RegisterBroadcaseEvent("430_slientownloading",_onBroadcast2)

    _onBroadcast3 = function(msg) --是否有人已经是最新版了
        print("-------someone has been newest version",msg.ip,os.clock())
        Broadcast:RemoveBroadcaseEvent("430_slientownload_precheck",_onBroadcast)
        Broadcast:RemoveBroadcaseEvent("430_slientownloading",_onBroadcast2)
        Broadcast:RemoveBroadcaseEvent("this_is_lan_update_server",_onBroadcast3)
        self._hasOtherUpdate = true
    end
    Broadcast:RegisterBroadcaseEvent("this_is_lan_update_server",_onBroadcast3)

    local obj = {
        ip = NPL.GetExternalIP(),
        ver = self:getCurVersion(),
        timeStramp = os.time(),
    }
    Broadcast:SendBroadcaseMsg("430_slientownload_precheck",obj)
    self._allPC[1] = obj

    commonlib.TimerManager.SetTimeout(function()
        if self._hasOtherUpdate then --30秒钟内，如果收到已经有人开始下载了，剩下的就不看了
            print("-------not need download 1",os.clock())
            return
        end
        table.sort(self._allPC,function(a,b)
            if a.ver==b.ver then
                return a.timeStramp<b.timeStramp
            else
                return CommonLib.CompareVer(a.ver,b.ver)>0
            end
        end)
        if self._allPC[1].ip==obj.ip then --然后就看看自己排第一的，是的话，自己开始下载
            self:_startDownloadFromCdnSliently()
        else
            print("-------not need download 2",os.clock(),"self.ip",obj.ip)
            echo(self._allPC)
        end
    end,1000*30)
    print("-------start check",os.clock())
end

function ClientUpdater430:_startDownloadFromCdnSliently()
    print("--------开始下载",os.clock())
    self:DownloadSliently()
    
    self.broadcastTimer = commonlib.Timer:new({callbackFunc = function(timer)
        local obj = {
            ver = self:getCurVersion(),
            timeStramp = os.time(),
        }
        Broadcast:SendBroadcaseMsg("430_slientownloading",obj)
        print("-----发送广播 430_slientownloading",os.clock())
    end})
    self.broadcastTimer:Change(0,10*1000)
end

--=================================================UI部分 start=================================================
local sliently_page;
-- init function. sliently_page script fresh is set to false.
function ClientUpdater430.OnInit()
	sliently_page = document:GetPageCtrl();
end

function ClientUpdater430:ShowSlientlyPage()
    if sliently_page then
        return sliently_page
    end
	local width, height=400, 50;
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url = "script/apps/Aries/Creator/Game/Login/ClientUpdater430ApplyPage.html", 
		name = "ClientUpdater430.ShowSlientlyPage", 
		isShowTitleBar = false,
		DestroyOnClose = true, 
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 1000,
		allowDrag = false,
		isTopLevel = false,
		directPosition = true,
			align = "_lb",
			x = 5,
			y = -35,
			width = width,
			height = height,
		cancelShowAnimation = true,
	});
    ClientUpdater430._applyFunc = function()
        self.autoUpdater:apply()
    end
end

function ClientUpdater430.ClosePage()
	if(sliently_page) then
		sliently_page:CloseWindow();
		sliently_page = nil;
	end
end

--点击应用更新
function ClientUpdater430.onBtnApplySlientlyDownload()
    if ClientUpdater430._applyFunc then
        ClientUpdater430._applyFunc()
        ClientUpdater430._applyFunc = nil
    end
end

function ClientUpdater430.RefreshSlientlyPage()
    if(sliently_page) then
		sliently_page:Refresh(0);
	end
end
--=================================================UI部分 end=================================================

--写入文件，用于下次给launcher读取
function ClientUpdater430.WriteConfigForLauncher()
    local path = ParaIO.GetWritablePath().."config/launch_config.txt"
    local txtStr = commonlib.Files.GetFileText(path)
    local lineList = {}
    local _set = {}
    if txtStr then
        local line;
        for line in string.gmatch(txtStr,"([^\r\n]*)\r?\n?") do
            if line then
                line = line:gsub("^[\"\'%s]+", ""):gsub("[\"\'%s]+$", "")
                if( line ~= "")then
                    table.insert(lineList,line)
                    if string.find(line,"%s-%-%-")~=1 then
                        local arr = commonlib.split(line,"--")
                        if arr then
                            line = arr[1]
                            echo(arr)
                        end
                        arr = commonlib.split(line,"=");
                        
                        if(arr and #arr == 2)then
                            local k = arr[1]:gsub("^[\"\'%s]+", ""):gsub("[\"\'%s]+$", "")
                            local v = arr[2]:gsub("^[\"\'%s]+", ""):gsub("[\"\'%s]+$", "")
                        
                            if k=="runtimeVersion" or k=="appId" or k=="machineCode" then
                                table.remove(lineList,#lineList)
                            else
                                _set[k] = v
                                if k=="launcherVer" then
                                    System.options.launcherVer = v
                                elseif k=="useRealLatestVersion" then
                                    System.options.useRealLatestVersion = v=="true"
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    table.insert(lineList,string.format("machineCode=%s",ParaEngine.GetAttributeObject():GetField('MachineID', '')))
    table.insert(lineList,string.format("runtimeVersion=%s",System.os.GetParaEngineVersion()))
    table.insert(lineList,string.format("appId=%s",System.options.appId))
    commonlib.Files.WriteFile(path,table.concat(lineList,"\r\n"))
    if System.options.launcherVer==nil then
        local launcherVer = ParaEngine.GetAppCommandLineByParam("launcherVer","0")
        System.options.launcherVer = launcherVer:gsub("^[\"\'%s]+", ""):gsub("[\"\'%s]+$", "")--去掉字符串首尾的空格、引号
    end
    System.options.launcherVer = tonumber(System.options.launcherVer)
    if System.options.isDevMode then
        print("System.options.launcherVer",System.options.launcherVer)
        echo(lineList,true)
    end
    if System.options.launcherExeName==nil then 
        System.options.launcherExeName = "ParaCraft.exe"
    end
end