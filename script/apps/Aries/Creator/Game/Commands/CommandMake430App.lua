--[[
Title: sendevent command
Author(s): hyz
Date: 2022/3/17
Desc: sendevent can be used to connect items in the world.
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandMake430App.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/Event.lua");
local Event = commonlib.gettable("System.Core.Event");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local SessionsData = NPL.load('(gl)Mod/WorldShare/database/SessionsData.lua')

local _checkDownloadWorldById,_getAll430World,_downloadAll430World
local _CopyParacraftFiles,_CreateBat,_GetOutDir,_CreateConfigTxt,_MakeZipInstaller

local _isRunning=  false

Commands["make430app"] = {
	name="make430app", 
	quick_ref="", 
	desc=[[ predownload all 430 course world
]], 
	category="logic",
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
        if not System.options.isDevMode then
            GameLogic.AddBBS(nil,L"您没有该命令使用权限")
            return
        end
		if not _isRunning then
            _isRunning = true
            local bak_sessions = SessionsData:GetSessions()
            for key, item in ipairs(bak_sessions.allUsers) do
                SessionsData:RemoveSession(item.value)
            end
            local out = _GetOutDir()
            ParaIO.DeleteFile(out)
            ParaIO.CreateDirectory(out)

			_downloadAll430World(function()
                _CopyParacraftFiles(function()
                    _CreateConfigTxt()
                    -- _CreateBat()
                    for key, item in ipairs(bak_sessions.allUsers) do
                        SessionsData:SaveSession(item.session)
                    end
                    _MakeZipInstaller(function()
                        GameLogic.AddBBS(nil,L"恭喜，打包430完成！",5000)
                        System.App.Commands.Call("File.WinExplorer", _GetOutDir());
                        _isRunning = false
                    end)
                end)
            end)
		end
	end,
};

--拷贝的CommonLoadWorld:EnterWorldById的逻辑，去掉各种权限检查，直接下载
_checkDownloadWorldById = function (pid, refreshMode, failed,callback)
	local CommonLoadWorld = NPL.load('(gl)Mod/WorldShare/cellar/Common/LoadWorld/CommonLoadWorld.lua')
	local Game = commonlib.gettable('MyCompany.Aries.Game')
	local DownloadWorld = commonlib.gettable('MyCompany.Aries.Game.MainLogin.DownloadWorld')
	local RemoteWorld = commonlib.gettable('MyCompany.Aries.Creator.Game.Login.RemoteWorld')

	-- service
	local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
	local GitService = NPL.load('(gl)Mod/WorldShare/service/GitService.lua')
	local GitKeepworkService = NPL.load('(gl)Mod/WorldShare/service/GitService/GitKeepworkService.lua')
    local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')
	local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')
	local LocalServiceHistory = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceHistory.lua')

	-- bottles
	local Create = NPL.load('(gl)Mod/WorldShare/cellar/Create/Create.lua')

	-- databse
	local CacheProjectId = NPL.load('(gl)Mod/WorldShare/database/CacheProjectId.lua')


	local self_encryptWorldMode = nil
    local self_encryptWorldVerified = false

    if not pid then
        return
    end

    pid = tonumber(pid)

    local world
    local overtimeEnter = false
    local fetchSuccess = false
    local tryTimes = 0

    local function HandleLoadWorld(worldInfo, offlineMode)
        if overtimeEnter then
            -- stop here when overtime enter
            return
        end
        
        GameLogic.GetFilters():apply_filters("enter_world_by_id");
        LocalServiceHistory:LoadWorld({
            name = worldInfo.worldName,
            kpProjectId = worldInfo.projectId,
        })

        local localWorldFile = nil
        local encryptWorldFile = nil

        local encryptWorldFileExist = false
        local worldFileExist = false

        local cacheWorldInfo = CacheProjectId:GetProjectIdInfo(pid)

        if cacheWorldInfo then
            local qiniuZipArchiveUrl = GitKeepworkService:GetQiNiuArchiveUrl(
                                        worldInfo.worldName,
                                        worldInfo.username,
                                        cacheWorldInfo.worldInfo.commitId)
            local cdnArchiveUrl = GitKeepworkService:GetCdnArchiveUrl(
                                    worldInfo.worldName,
                                    worldInfo.username,
                                    cacheWorldInfo.worldInfo.commitId,
                                    worldInfo.projectId)

            local qiniuWorld = RemoteWorld.LoadFromHref(qiniuZipArchiveUrl, 'self')
            qiniuWorld:SetProjectId(pid)
            qiniuWorld:SetRevision(cacheWorldInfo.worldInfo.revision)
            qiniuWorld:SetSpecifyFilename(cacheWorldInfo.worldInfo.commitId)

            local cdnArchiveWorld = RemoteWorld.LoadFromHref(cdnArchiveUrl, 'self')
            cdnArchiveWorld:SetProjectId(pid)
            cdnArchiveWorld:SetRevision(cacheWorldInfo.worldInfo.revision)
            cdnArchiveWorld:SetSpecifyFilename(cacheWorldInfo.worldInfo.commitId)

            local qiniuWorldFile = qiniuWorld:GetLocalFileName() or ''
            local cdnArchiveWorldFile = cdnArchiveWorld:GetLocalFileName() or ''
    
            local encryptQiniuWorldFile = string.match(qiniuWorldFile, '(.+)%.zip$') .. '.pkg'
            local encryptCdnArchiveWorldFile = string.match(cdnArchiveWorldFile, '(.+)%.zip$') .. '.pkg'
    
            if ParaIO.DoesFileExist(encryptQiniuWorldFile) then
                encryptWorldFileExist = true
                self_encryptWorldMode = true
                localWorldFile = qiniuWorldFile
                encryptWorldFile = encryptQiniuWorldFile
            elseif ParaIO.DoesFileExist(encryptCdnArchiveWorldFile) then
                encryptWorldFileExist = true
                self_encryptWorldMode = true
                localWorldFile = cdnArchiveWorldFile
                encryptWorldFile = encryptCdnArchiveWorldFile
            elseif ParaIO.DoesFileExist(qiniuWorldFile) then
                worldFileExist = true
                self_encryptWorldMode = nil
                localWorldFile = qiniuWorldFile
                encryptWorldFile = encryptQiniuWorldFile
            elseif ParaIO.DoesFileExist(cdnArchiveWorldFile) then
                worldFileExist = true
                self_encryptWorldMode = nil
                localWorldFile = cdnArchiveWorldFile
                encryptWorldFile = encryptCdnArchiveWorldFile
            end
        end

        local function LoadWorld(refreshMode) -- refreshMode(force or never)
            local newQiniuZipArchiveUrl = GitKeepworkService:GetQiNiuArchiveUrl(
                                    worldInfo.worldName,
                                    worldInfo.username,
                                    worldInfo.commitId)
            local newCdnArchiveUrl = GitKeepworkService:GetCdnArchiveUrl(
                                        worldInfo.worldName,
                                        worldInfo.username,
                                        worldInfo.commitId,
                                        worldInfo.projectId)

            local newQiniuWorld = RemoteWorld.LoadFromHref(newQiniuZipArchiveUrl, 'self')
            newQiniuWorld:SetProjectId(pid)
            newQiniuWorld:SetRevision(worldInfo.revision)
            newQiniuWorld:SetSpecifyFilename(worldInfo.commitId)

            local newCdnArchiveWorld = RemoteWorld.LoadFromHref(newCdnArchiveUrl, 'self')
            newCdnArchiveWorld:SetProjectId(pid)
            newCdnArchiveWorld:SetRevision(worldInfo.revision)
            newCdnArchiveWorld:SetSpecifyFilename(worldInfo.commitId)

            local newQiniuWorldFile = newQiniuWorld:GetLocalFileName() or ''
            local newCdnArchiveWorldFile = newCdnArchiveWorld:GetLocalFileName() or ''
    
            local newEncryptQiniuWorldFile = string.match(newQiniuWorldFile, '(.+)%.zip$') .. '.pkg'
            local newEncryptCdnArchiveWorldFile = string.match(newCdnArchiveWorldFile, '(.+)%.zip$') .. '.pkg'

            -- encrypt mode load world
            if self_encryptWorldMode then
                if refreshMode == 'never' then
                    if not LocalService:IsFileExistInZip(encryptWorldFile, ':worldconfig.txt') then
                        -- broken world
                        refreshMode = 'force'
                    end
                end

                if encryptWorldFileExist and refreshMode ~= 'force' then
                    if callback then callback(encryptWorldFile) end
                    return
                end

                if not encryptWorldFileExist or
                   refreshMode == 'force' then
                    if ParaIO.DoesFileExist(encryptWorldFile) then
                        ParaIO.DeleteFile(encryptWorldFile)
                    end

                    if ParaIO.DoesFileExist(localWorldFile) then
                        ParaIO.DeleteFile(localWorldFile)
                    end

                    local function DownloadEncrytWorld(url)
                        local world = nil
                        local downloadNewLocalWorldFile = nil
                        local downloadNewEncryptWorldFile = nil
    
                        if url == newQiniuZipArchiveUrl then
                            world = newQiniuWorld
                            downloadNewLocalWorldFile = newQiniuWorldFile
                            downloadNewEncryptWorldFile = newEncryptQiniuWorldFile
                        elseif url == newCdnArchiveUrl then
                            world = newCdnArchiveWorld
                            downloadNewLocalWorldFile = newCdnArchiveWorldFile
                            downloadNewEncryptWorldFile = newEncryptCdnArchiveWorldFile
                        end

                        local token = Mod.WorldShare.Store:Get('user/token')

                        if token then
                            world:SetHttpHeaders({Authorization = format('Bearer %s', token)})
                        end

                        CommonLoadWorld:InjectShowCustomDownloadWorldFilter(worldInfo, world)
                        DownloadWorld.ShowPage(url)

                        world:DownloadRemoteFile(function(bSucceed, msg)
                            if world.breakDownload then
                                return
                            end

                            DownloadWorld.Close()

                            if bSucceed then
                                if not ParaIO.DoesFileExist(downloadNewLocalWorldFile) then
                                    _guihelper.MessageBox(format(L'下载世界失败，请重新尝试几次（项目ID：%d）', pid))
    
                                    LOG.std(nil, 'warn', 'CommandLoadWorld', 'Invalid downloaded file not exist: %s', localWorldFile)
                                    return
                                end
    
                                ParaAsset.OpenArchive(downloadNewLocalWorldFile, true)
                                
                                local output = {}
    
                                commonlib.Files.Find(output, '', 0, 500, ':worldconfig.txt', downloadNewLocalWorldFile)
    
                                if #output == 0 then
                                    _guihelper.MessageBox(format(L'worldconfig.txt不存在，请联系作者检查世界目录（项目ID：%d）', pid))
    
                                    LOG.std(nil, 'warn', 'CommandLoadWorld', 'Invalid downloaded file will be deleted: %s', downloadNewLocalWorldFile)
    
                                    ParaAsset.CloseArchive(downloadNewLocalWorldFile)
                                    ParaIO.DeleteFile(downloadNewLocalWorldFile)
                                    return
                                end
    
                                ParaAsset.CloseArchive(downloadNewLocalWorldFile)
    
                                LocalServiceWorld:EncryptWorld(downloadNewLocalWorldFile, downloadNewEncryptWorldFile)
                                if not ParaEngine.GetAppCommandLineByParam('save_origin_zip', nil) then
                                    ParaIO.DeleteFile(downloadNewLocalWorldFile)
                                end
    
                                if ParaIO.DoesFileExist(downloadNewEncryptWorldFile) then
                                    Mod.WorldShare.Store:Set('world/currentRemoteFile', url)

                                    worldInfo.encryptWorldMode = self_encryptWorldMode
                                    CacheProjectId:SetProjectIdInfo(pid, worldInfo)

                                    if callback then callback(downloadNewEncryptWorldFile) end
                                end
                            else
                                Mod.WorldShare.MsgBox:Wait()

                                Mod.WorldShare.Utils.SetTimeOut(function()
                                    Mod.WorldShare.MsgBox:Close()

                                    if tryTimes > 0 then
                                        Create:Show()
                                        return
                                    end

                                    DownloadEncrytWorld(newCdnArchiveUrl)
                                    tryTimes = tryTimes + 1
                                end, 3000)
                            end
                        end)
                    end

                    DownloadEncrytWorld(newQiniuZipArchiveUrl)
                end
            else
                -- zip mode load world
                if refreshMode == 'never' then
                    -- broken world
                    if not LocalService:IsFileExistInZip(localWorldFile, ':worldconfig.txt') then
                        refreshMode = 'force'
                    end
                end
    
                if worldFileExist and refreshMode ~= 'force' then
                    if callback then callback(localWorldFile) end
                    return
                end

                if not worldFileExist or
                   refreshMode == 'force' then
                    if ParaIO.DoesFileExist(localWorldFile) then
                        ParaIO.DeleteFile(localWorldFile)
                    end

                    local function DownloadLocalWorld(url)
                        local world = nil
                        local downloadNewLocalWorldFile = nil

                        if url == newQiniuZipArchiveUrl then
                            world = newQiniuWorld
                            downloadNewLocalWorldFile = newQiniuWorldFile
                        elseif url == newCdnArchiveUrl then
                            world = newCdnArchiveWorld
                            downloadNewLocalWorldFile = newCdnArchiveWorldFile
                        end

                        if token then
                            world:SetHttpHeaders({Authorization = format('Bearer %s', token)})
                        end

                        CommonLoadWorld:InjectShowCustomDownloadWorldFilter(worldInfo, world)
                        DownloadWorld.ShowPage(url)

                        world:DownloadRemoteFile(function(bSucceed, msg)
                            if world.breakDownload then
                                return
                            end
                            
                            DownloadWorld.Close()
                            if bSucceed then
                                if not ParaIO.DoesFileExist(downloadNewLocalWorldFile) then
                                    _guihelper.MessageBox(format(L'下载世界失败，请重新尝试几次（项目ID：%d）', pid))

                                    LOG.std(nil, 'warn', 'CommandLoadWorld', 'Invalid downloaded file not exist: %s', downloadNewLocalWorldFile)
                                    return
                                end
								
                                ParaAsset.OpenArchive(downloadNewLocalWorldFile, true)
                                
                                local output = {}

                                commonlib.Files.Find(output, '', 0, 500, ':worldconfig.txt', downloadNewLocalWorldFile)
                                if #output == 0 then
                                    _guihelper.MessageBox(format(L'下载的世界已损坏，请重新尝试几次（项目ID：%d）', pid))

                                    LOG.std(nil, 'warn', 'CommandLoadWorld', 'Invalid downloaded file will be deleted: %s', downloadNewLocalWorldFile)

                                    ParaAsset.CloseArchive(downloadNewLocalWorldFile)
                                    ParaIO.DeleteFile(downloadNewLocalWorldFile)
                                    return
                                end

                                ParaAsset.CloseArchive(downloadNewLocalWorldFile)
                                Mod.WorldShare.Store:Set('world/currentRemoteFile', url)

                                worldInfo.encryptWorldMode = self_encryptWorldMode
                                CacheProjectId:SetProjectIdInfo(pid, worldInfo)
                                if callback then callback(downloadNewLocalWorldFile) end
                            else
                                Mod.WorldShare.MsgBox:Wait()

                                Mod.WorldShare.Utils.SetTimeOut(function()
                                    Mod.WorldShare.MsgBox:Close()

                                    if tryTimes > 0 then
                                        Create:Show()
                                        return
                                    end

                                    DownloadLocalWorld(newCdnArchiveUrl)
                                    tryTimes = tryTimes + 1
                                end, 3000)
                            end
                        end)
                    end

                    DownloadLocalWorld(newQiniuZipArchiveUrl)
                end
            end
        end

        -- check encrypt file
        if not encryptWorldFileExist and not worldFileExist then
            LoadWorld('force')
            return
        end

        if offlineMode then
            LoadWorld('never')
            return
        end

        if refreshMode == 'never' or
           refreshMode == 'force' then
            if refreshMode == 'never' then
                LoadWorld('never')
            elseif refreshMode == 'force' then
                LoadWorld('force')
            end
        elseif not refreshMode or
               refreshMode == 'auto' or
               refreshMode == 'check' then
            Mod.WorldShare.MsgBox:Wait()

            GitService:GetWorldRevision(pid, false, function(data, err)
                local localRevision = 0

                if self_encryptWorldMode then
                    localRevision = tonumber(LocalService:GetZipRevision(encryptWorldFile))
                else
                    localRevision = tonumber(LocalService:GetZipRevision(localWorldFile))
                end

                local remoteRevision = tonumber(data) or 0

                Mod.WorldShare.MsgBox:Close()

                -- LoadWorld('force')    
				if refreshMode == 'auto' then
                    if localRevision == 0 then
                        LoadWorld('force')
                        return
                    end

                    if localRevision < remoteRevision then
                        LoadWorld('force')
                    else
                        LoadWorld('never')
                    end
                elseif not refreshMode or refreshMode == 'check' then
                    if not refreshMode and refreshMode ~= 'check' then
                        if localRevision == 0 then
                            LoadWorld('force')
                            return
                        end
    
                        if localRevision == remoteRevision then
                            LoadWorld('never')
                            return
                        end
                    end

                    LoadWorld('force')    
                end            
            end)
        end
	end

    -- offline mode
    local cacheWorldInfo = CacheProjectId:GetProjectIdInfo(pid)

    if ((System.options.loginmode == 'local') and
       not GameLogic.GetFilters():apply_filters('is_signed_in') and
       cacheWorldInfo) then
        self_encryptWorldMode = cacheWorldInfo.worldInfo.encryptWorldMode
        HandleLoadWorld(cacheWorldInfo.worldInfo, true)
        return
    end

    -- show view over 10 seconds
    Mod.WorldShare.Utils.SetTimeOut(function()
        if fetchSuccess then
            return
        end

        local CreatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

        if not CreatePage then
            Create:Show()
        end

        Mod.WorldShare.MsgBox:Close()
    end, 10000)

    Mod.WorldShare.MsgBox:Wait(20000)

    KeepworkServiceProject:GetProject(
        pid,
        function(data, err)
            Mod.WorldShare.MsgBox:Close()
            fetchSuccess = true

            if err == 0 then
                local cacheWorldInfo = CacheProjectId:GetProjectIdInfo(pid)

                if not cacheWorldInfo or not cacheWorldInfo.worldInfo then
                    GameLogic.AddBBS(nil, format(L'网络环境差，或离线中，请联网后再试（%d）', err), 3000, '255 0 0')
                    return
                end

                HandleLoadWorld(cacheWorldInfo.worldInfo, true)
                return
            end

            if err == 404 or
               not data or
               not data.world or
               not data.world.archiveUrl or
               #data.world.archiveUrl == 0 then
                local archiveUrlLength = 0

                if data and data.world and data.world.archiveUrl then
                    archiveUrlLength = #data.world.archiveUrl
                end

                GameLogic.AddBBS(
                    nil,
                    format(L'未找到对应项目信息（项目ID：%d）（URL长度：%d）（ERR：%d）', pid, archiveUrlLength, err),
                    10000,
                    '255 0 0'
                )

                local CreatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

                if not CreatePage then
                    Create:Show() -- use local mode instead of enter world
                end
                return
            end

            if err ~= 200 then
                GameLogic.AddBBS(nil, format(L'服务器维护中（%d）', err), 3000, '255 0 0')
                return
            end

            -- update world info
            data.world.username = data.username

            -- encrypt world
            if data and
                data.level and
                data.level ~= 2 then
                self_encryptWorldMode = true
            end

            HandleLoadWorld(data.world)
        end
    )
end

_getAll430World = function (callback)
    local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
    print("-----_getAll430World: req")
    GameLogic.AddBBS(nil,L"正在获取课程信息...")
    keepwork.courses.query({},function(err, msg, data) --查詢所有課程
        local all_lessonCnf = {}
        print("-----_getAll430World: rsp",err, msg)
        echo(data,true)
        if err == 200 then
            all_lessonCnf = data.rows
            
            local pattern_arr = {
                'projectid%s*=%s*[\"\']?(%d+)[\"\']?',
                'to_world_id%s*=%s*[\"\']?(%d+)[\"\']?',
            }
            local world_list = {}
            local function _isArrContain(arr,projectid)
                for _,v in ipairs(arr) do
                    if v.projectid==projectid then 
                        return true 
                    end
                end
                return false
            end
            GameLogic.AddBBS(nil,L"正在解析课程列表...")
            for k,v in pairs(all_lessonCnf) do
                keepwork.courses.course_info({
                    router_params = {
                        id = v.id,
                    }
                },function(err, msg, data)
                    if err == 200 then
                        if data.xml then
                            -- print("-----------k",k)
                            -- echo(data.xml)
                            for _,pattern in pairs(pattern_arr) do
                                for projectid in string.gmatch(data.xml,pattern) do
                                    
                                    projectid = tonumber(projectid)
                                    if not _isArrContain(world_list,projectid) then
                                        table.insert(world_list,{projectid=projectid,name=v.name,course_name=course_name,idx=k2})
                                    end
                                end 
                            end
                        end
                    end
                    if k==#all_lessonCnf then 
                        print("-------all world_list:",#world_list)
                        echo(world_list,true)
                        if callback then
                            callback(world_list)
                        end
                    end
                end)
            end
            
        end
    end)
end

--根目录下文件,"/"结尾表示是文件夹
local bin_files = {
    "cef3/",
    "plugins/",
    "worlds/BlockTextures/",
    
    "temp/cache/",

    "config/bootstrapper.xml",
    "config/GameClient.config.xml",
    "config/commands.xml",
    "config/config.txt",
    "config/channel_option_dft.ini",
    "database/",

    System.options.launcherExeName or "ParaCraft.exe",
    (System.options.launcherExeName or "ParaCraft.exe"):gsub(".exe",".mem.exe"),
    "paraengineclient.exe",
    "paraengine.sig",

    "paraengineclient.dll",
    "physicsbt.dll",
    "lua.dll",
    "freeimage.dll",
    "libcurl.dll",
    "sqlite.dll",
    "caudioengine.dll",
    "config.txt",
    "d3dx9_43.dll",
    "openal32.dll",
    "wrap_oal.dll",
    "pedetectactivex.dll",
    "f_in_box.dll",
    "autoupdater.dll",

    "copyright.txt",

    "npl_packages/",
    "Mod/",
    'version.txt',
    "assets_manifest.txt",
    "main.pkg",
    "main_mobile_res.pkg",
    "main150727.pkg",

}

--如果更新目录更高，则使用更新目录的
local hot_map = {
    ['version.txt'] = true,
    ['assets_manifest.txt'] = true,
    ['npl_packages/'] = true,
    ['Mod/'] = true,
    ['main.pkg'] = true,
    ['main_mobile_res.pkg'] = true,
    ['main150727.pkg'] = true,
}

_downloadAll430World = function(onFinish)
	_getAll430World(function(world_list)
        local len = #world_list
        -- len = 10
        local _download;
        _download = function (idx)
            if idx>len then 
                GameLogic.AddBBS(nil,L"所有课程预下载完成")
                
                Mod.WorldShare.Utils.SetTimeOut(function()
                    if onFinish then onFinish() end
                end, 1000)
                return
            else
                GameLogic.AddBBS(nil,string.format(L"正在下载课程包 %s/%s",idx,len))
            end
            local obj = world_list[idx]
            _checkDownloadWorldById(obj.projectid,nil,nil,function(worldPath)
                worldPath = string.gsub(worldPath,ParaIO.GetWritablePath(),"")
                print("-----xxxx worldPath",worldPath)
                table.insert(bin_files,worldPath)
                _download(idx+1)
            end)
        end
        
        _download(1)
    end)
end

--复制引擎文件，如果有脚本更新，优先使用更新文件夹的文件
_CopyParacraftFiles = function (onComelete)
    NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ClientUpdater.lua");
	
    Mod.WorldShare.MsgBox:Show(L'正在拷贝引擎,请稍候...')
    
    Mod.WorldShare.Utils.SetTimeOut(function()
        local ClientUpdater = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdater");

        local updater = ClientUpdater:new();
        local _isUseHot = false
        local version = ParaIO.open(updater:GetRedistFolder() .. 'version.txt', "r");
        if (version:IsValid()) then
            updater.autoUpdater:loadLocalVersion()
            local root_curVer = updater:GetCurrentVersion()
            local hot_curVer = updater:getCurVersion()
            if updater.autoUpdater:_compareVer(root_curVer,hot_curVer)<0 then --根目录下版本小于于更新目录版本
                _isUseHot = true
            end
        end

        local out_dir = _GetOutDir();
        local bin_dir = out_dir.."bin/";
        local root_dir = ParaIO.GetCurDirectory(0);
        local hot_dir = updater:GetRedistFolder()
        ParaIO.DeleteFile(bin_dir)

        for _,_filename in pairs(bin_files) do
            ParaIO.CreateDirectory(root_dir.._filename);
            local srcPath 
            if hot_map[_filename] and _isUseHot and ParaIO.DoesFileExist(hot_dir.._filename) then
                srcPath = hot_dir.._filename
            else
                srcPath = root_dir.._filename
            end
            if string.sub(_filename,#_filename)=="/" then --文件夹
                ParaIO.CreateDirectory(bin_dir.._filename);
                local parentDir = srcPath
                local filesOut = {};
                commonlib.Files.Find(filesOut, parentDir, 10, 10000, "*");
                for i = 1,#filesOut do
                    local item = filesOut[i];
                    local _fname = item.filename
                    if(item.filesize > 0) then
                        local source_path = parentDir.._fname;
                        local dest_path = bin_dir.._filename.._fname;
                        local re = ParaIO.CopyFile(source_path, dest_path, true);
                        LOG.std(nil, "info", "111 Copy430engine", "copy(%s) %s -> %s",tostring(re),source_path,dest_path);
                    else
                        -- this is a folder
                        ParaIO.CreateDirectory(bin_dir.._filename.._fname.."/");
                    end
                end
            else
                local re = ParaIO.CopyFile(srcPath, bin_dir.._filename, true)
                LOG.std(nil, "info", "222 Copy430engine", "copy(%s) %s -> %s",tostring(re),srcPath,bin_dir.._filename);
            end
            
        end
        Mod.WorldShare.MsgBox:Close()
        if onComelete then onComelete() end
    end, 1000)
    return;
end

--修改config.txt，添加启动参数
_CreateConfigTxt = function ()
    local out_dir = _GetOutDir();
    local bin_dir = out_dir.."bin/";
    local filename = bin_dir.."config.txt"

    local file = ParaIO.open(filename, "w")
    if(file:IsValid()) then
        local str = string.format([[cmdline=noupdate="true" debug="main" mc="true" bootstrapper="script/apps/Aries/main_loop.lua" channelId="430"]])
        file:WriteString(str);
        file:close();
    end

    local config_dir = bin_dir.."config/"
    filename = config_dir..string.format("channel_option_%s.ini",430)
    local file = ParaIO.open(filename, "w")
    if(file:IsValid()) then
        local str = string.format([[
-- channel options for 430.

world_enter_cmds = /shader 1;/renderdist 96; /lod on; /property -scene MaxCharTriangles 99999
enable_npl_brower = false
is_resolution_locked = true
-- IgnoreWindowSizeChange = true
-- LockWindowSize = true
FPS = 60
        ]])
        file:WriteString(str);
        file:close();
    end
end

_CreateBat = function ()
    local out_dir = _GetOutDir();
    local filename = out_dir.. "start" .. ".bat"
    local file = ParaIO.open(filename, "w")
    if(file:IsValid()) then
        file:WriteString("@echo off\n");
        file:WriteString("cd bin\n");
        file:WriteString("start paraengineclient.exe");
        file:close();
        return true;
    end
end

_GetOutDir = function ()
    local output_folder = ParaIO.GetWritablePath() .. "_430app/";
    return output_folder
end

_MakeZipInstaller = function (callback)
    local out_dir = _GetOutDir();
    local bin_dir = out_dir.."bin/";

    local zipfile = out_dir.."paracraft430_green.zip"
    ParaIO.DeleteFile(zipfile)

    local result = commonlib.Files.Find({}, bin_dir, 10, 5000, "*")
    
    Mod.WorldShare.MsgBox:Show(L'正在进行压缩,请稍候...')
    Mod.WorldShare.Utils.SetTimeOut(function()
        local writer = ParaIO.CreateZip(zipfile,"");
        local appFolder = "";
        for i, item in ipairs(result) do
            local filename = item.filename;
            if(filename) then
                -- add all files
                local destFolder = (appFolder..filename):gsub("[/\\][^/\\]+$", "");
                if destFolder==filename then 
					if item.filesize>0 then
					    writer:ZipAdd(destFolder, bin_dir..filename);
					else
						writer:AddDirectory(destFolder, bin_dir..filename, 0);
                    end
				else
					writer:AddDirectory(destFolder, bin_dir..filename, 0);
				end
            end
        end
        writer:close();
        LOG.std(nil, "info", "MakeZipInstaller", "successfully generated package to %s", commonlib.Encoding.DefaultToUtf8(zipfile))
        Mod.WorldShare.MsgBox:Close()
        if callback then callback() end
    end,1000)
    
    return true;
end