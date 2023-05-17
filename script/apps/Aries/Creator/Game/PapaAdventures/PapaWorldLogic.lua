--[[
    author:{author}
    time:2023-04-02 16:53:13
    uselib:
       local PapaWorldLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaWorldLogic.lua");
]]
NPL.load('(gl)script/apps/Aries/Creator/Game/Login/RemoteUrl.lua')
NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaAPI.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldLessons.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/DownloadWorld.lua");
local DownloadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.DownloadWorld")
local ParaWorldLessons = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLessons")
local PapaAPI = commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.PapaAPI")
local RemoteUrl = commonlib.gettable('MyCompany.Aries.Creator.Game.Login.RemoteUrl')
local CommonLoadWorld = NPL.load('(gl)Mod/WorldShare/cellar/Common/LoadWorld/CommonLoadWorld.lua')
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')
local KeepworkServiceWorld = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceWorld.lua')
local VipTypeWorld = NPL.load('(gl)Mod/WorldShare/cellar/Common/LoadWorld/VipTypeWorld.lua')
local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local Create = NPL.load('(gl)Mod/WorldShare/cellar/Create/Create.lua')
local ShareTypeWorld = NPL.load('(gl)Mod/WorldShare/cellar/Common/LoadWorld/ShareTypeWorld.lua')
local SyncToLocal = NPL.load('(gl)Mod/WorldShare/service/SyncService/SyncToLocal.lua')
local LoginModal = NPL.load('(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua')
local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')
local KeepworkServicePermission = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Permission.lua')
local PapaWorldLogic = NPL.export()
local self = PapaWorldLogic
PapaWorldLogic.IsStartCheckLoaded = false
PapaWorldLogic.IsWorldLoaded = false
PapaWorldLogic.IsSwfLoadingFinished = false
PapaWorldLogic.CurrentCreateWorldName = ""
function PapaWorldLogic.RegisterEvent()
    GameLogic.GetFilters():add_filter("EnterWorldFailed", PapaWorldLogic.EnterWorldFailed);
    GameLogic.GetFilters():add_filter("enter_world_fail",self.EnterWorldFail)
    GameLogic:Connect("WorldLoaded", self, self.OnWorldLoaded, "UniqueConnection");
    --GameLogic:Disconnect("WorldLoaded", self, self.OnWorldLoaded, "UniqueConnection");
    GameLogic.GetFilters():add_filter("ConnectServerFailed", PapaWorldLogic.ConnectServerFailed);
    GameLogic.GetFilters():add_filter("SyncWorldFinish", PapaWorldLogic.OnSyncWorldFinish);

    GameLogic.GetFilters():add_filter("OnWorldCreate",  function(worldPath)
        self.CurrentCreateWorldName = worldPath
        return worldPath
    end)
    GameLogic.GetFilters():add_filter("apps.aries.creator.game.login.swf_loading_bar.close_page", function()
        self.OnLoadingProgressFinish()
        return true
    end);
end


function PapaWorldLogic.OnLoadingProgressFinish()
    self.IsSwfLoadingFinished = true
    self.SyncWorldFinishBegin()
end

function PapaWorldLogic.OnSyncWorldFinish(...)
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    local projectId = 0
    if currentWorld and  currentWorld.kpProjectId and currentWorld.kpProjectId ~= 0 then
        projectId = currentWorld.kpProjectId
    end
    NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/Lessons/Creation.lua");
    local Creation = commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.Lessons.Creation");
    local params = {projectId =projectId}
    if Creation and Creation.report then
        params.report = commonlib.copy(Creation.report)
        Creation.report = nil 
    end
    params.submitType = Creation.submitType
    PapaAPI:SendEvent("worldSaved",params)
    if System.options.isPapaAdventure then
        if Creation.nameChanged then
            Creation.nameChanged  = false
            local tag = LocalService:GetTag(currentWorld.worldpath)
        
            local name = Creation.worldInfo and Creation.worldInfo.opusName or ""
            if name ~= "" then
                print("change name",name)
                local world_data = GameLogic.GetFilters():apply_filters('store_get', 'world/currentWorld') or {}
                world_data.text = name
                local curr_world = Mod.WorldShare.Store:Get('world/currentEnterWorld') or {}
                curr_world.text = name
                curr_world.name = name
                NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
                local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
                WorldCommon.SetWorldTag("name", name);
                WorldCommon.SaveWorldTag();
                GameLogic.options:ResetWindowTitle()
            end
        end
        if Creation.descChanged then
            Creation.descChanged =false
            local desc = Creation.worldInfo and Creation.worldInfo.opusDesc or ""
            NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
            local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
            local world_data = GameLogic.GetFilters():apply_filters('store_get', 'world/currentWorld')
            if world_data and world_data.kpProjectId and world_data.kpProjectId ~= 0 then
                keepwork.project.update({
                    router_params = {
                        id = world_data.kpProjectId,
                    },
                    description=desc,
                },function(err,msg,data)
                    if err == 200 then
                        WorldCommon.SetWorldTag("desc", desc);
                        WorldCommon.SaveWorldTag()
                    end
                end)
            else
                WorldCommon.SetWorldTag("desc", desc);
                WorldCommon.SaveWorldTag()
            end
        end
    end
end

function PapaWorldLogic.SyncWorldFinishBegin()
    if self.IsSwfLoadingFinished and self.IsWorldLoaded then
        if self.CurrentCreateWorldName and self.CurrentCreateWorldName ~= "" then
            local ShareWorld = NPL.load('(gl)Mod/WorldShare/cellar/ShareWorld/ShareWorld.lua');
            commonlib.TimerManager.SetTimeout(function()
                GameLogic.AddBBS(nil,"世界创建成功，开始自动保存世界")
               
                self.CurrentCreateWorldName = ""
                self.IsWorldLoaded = false
                self.IsSwfLoadingFinished = false
                if self.isNewCreatedWorld then
                    self.isNewCreatedWorld = false
                    GameLogic.QuickSave();
                    ShareWorld:OnClick(true)
                end
            end,500)
        end
        NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
        local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
        local isHomeWorkWorld = WorldCommon.GetWorldTag("isHomeWorkWorld");
        --start auto save every 2 minite
        --print("isHomeWorkWorld===========",isHomeWorkWorld)
        if isHomeWorkWorld == true or isHomeWorkWorld == "true" then
            GameLogic.CreateGetAutoSaver():SetCheckModified()
            GameLogic.CreateGetAutoSaver():SetSaveMode();
            GameLogic.CreateGetAutoSaver():SetInterval(2);
        end
    end
end

function PapaWorldLogic.OnWorldLoaded(...)
    self.IsStartCheckLoaded = true
    self.IsWorldLoaded = true
    self.SyncWorldFinishBegin()
end

function PapaWorldLogic:StartCheckLoaded(callback)
    if self.loadTimer then
        self.loadTimer:Change()
        self.loadTimer = nil
    end
    self.loadTimer = commonlib.Timer:new({callbackFunc = function(timer)
        if self.IsStartCheckLoaded then
            if callback and type(callback) == "function" then
                callback()
            end
            if self.loadTimer then
                self.loadTimer:Change()
                self.loadTimer = nil
            end
            self.IsStartCheckLoaded = false
        end
    end});
    self.loadTimer:Change(1000,500)
end


local terrain_info = {
    {index = 1,terrain = "empty", show_value = "空", description = "SDK用户可用命令行创建地基"},
	{index = 2,terrain = "superflat",  show_value = "超级平坦", description = "海拔0米,无地下"},
	{index = 3,terrain = "paraworldMini",  show_value = "迷你地块", description = "迷你地块"},
    {index = 4,terrain = "custom", show_value = "随机地形", description = "森林，沙漠，雪地，山洞"},
	{index = 5,terrain = "paraworld",  show_value = "并行世界", description = "3D社区"},
}
function PapaWorldLogic.CreateWorld(world_data_or_name)
    local world_name,world_type
    -------{callbackId=4,world={type="create_world",terrain="2",worldName="你可",}
    if type(world_data_or_name) == "string" and world_data_or_name ~= "" then
        world_name = world_data_or_name
    end
    if type(world_data_or_name) == "table" then
        local worldData = world_data_or_name
        world_name = worldData.worldName
        world_type = terrain_info[tonumber(worldData.terrain)].terrain
    end
    self.CheckCanCreate(world_name,function(bCanCreate,message)
        if not bCanCreate then
            --创建世界失败，返回browser
            PapaAPI:SendEvent("CreateWorld",{callbackId = self.callbackId,result = false,message = message})
            self.callbackId = nil
            return
        end
        PapaAPI:SendEvent("CreateWorld",{callbackId = self.callbackId,result = true})
        self.callbackId = nil
        local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')
        CreateWorld:CreateWorldByName(world_name, world_type or "superflat",true)
        self.isNewCreatedWorld = true
    end)
end

function PapaWorldLogic.CheckCanCreate(world_name,callback)
    local Create = NPL.load('Mod/WorldShare/cellar/Create/Create.lua')
    Create.statusFilter = nil
    Create:GetWorldList(Create.statusFilter,function()
        local foldername = world_name
        local currentWorldList = Mod.WorldShare.Store:Get('world/compareWorldList') or {}
        print("foldername=======",foldername)
        foldername = foldername:gsub('[%s/\\]', '')
        
        for key, item in ipairs(currentWorldList) do
            if item.foldername == foldername then
                -- _guihelper.MessageBox(L'世界名已存在，请列表中进入')
                callback(false,"exist")
                return
            end
        end
    
        local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')
    
        if currentEnterWorld and currentEnterWorld.foldername == foldername then
            -- _guihelper.MessageBox(L'世界名已存在，请列表中进入')
            callback(false,"enter")
            return
        end
    
        -- 客户端处理敏感词
        local temp = MyCompany.Aries.Chat.BadWordFilter.FilterString(foldername);
    
        if temp ~= foldername then 
            -- _guihelper.MessageBox(L"该世界名称不可用，请重新设定")
            callback(false,"rename")
            return
        end
        callback(true)
    end)
end

function PapaWorldLogic.EnterWorldFail(...)
    NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaAdventuresMain.lua");
    local PapaAdventuresMain = commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.Main")
    PapaAdventuresMain:HideBrowser(false)
    GameLogic.GetFilters():remove_filter("enter_world_fail",self.onEnterWorldFail)
    if self.callbackId then
        PapaAPI:SendEvent("createLoadWorld",{callbackId = self.callbackId,result = false,message = "enter world fail"})
        self.callbackId = nil
    end
    return ...
end

function PapaWorldLogic.EnterWorldFailed(msg)
    NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaAdventuresMain.lua");
    local PapaAdventuresMain = commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.Main")
    PapaAdventuresMain:HideBrowser(false)
    local message = msg ~= nil and msg or "enter world fail"
    if self.callbackId then
        PapaAPI:SendEvent("createLoadWorld",{callbackId = self.callbackId,result = false,message = message})
        self.callbackId = nil
    end
end

function PapaWorldLogic.ConnectServerFailed(msg)
    NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaAdventuresMain.lua");
    local PapaAdventuresMain = commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.Main")
    PapaAdventuresMain:HideBrowser(false)
    if self.callbackId then
        PapaAPI:SendEvent("createLoadWorld",{callbackId = self.callbackId,result = false,message = "connect server fail"})
        self.callbackId = nil
    end
    return msg
end

function PapaWorldLogic.GetProjectId(vueStr)
    if (vueStr and tonumber(vueStr)> 0) then
        return tonumber(vueStr)
    end
    
    local pid = string.match(vueStr or '', "^p(%d+)$")

    if not pid then
        pid = string.match(vueStr or '', "/pbl/project/(%d+)")
    end
    if not pid then
        local id = ParaWorldLessons.GetLessonWorld(vueStr)
        if id then
            pid = id
        end
    end

    if not pid then
        local projectId, classId = vueStr:match("^(%d+)(%a+%d+)")
        if projectId and classId then
            System.User.worldclassid = string.lower(classId)
            pid = projectId
        end
    end
    return pid or false
end

function PapaWorldLogic.CheckWorldValidById(worldId,call_back_func)
    local pid = tonumber(worldId or 0)
    if pid and pid > 0 and call_back_func then
        if not KeepworkServiceSession:IsSignedIn() then
            call_back_func(false,"login")
            return 
        end
        KeepworkServiceProject:GetProject(pid,function(data, err)
            if err ~= 200 then
                call_back_func(false,"project") --世界信息没有
            else
                local username = Mod.WorldShare.Store:Get('user/username')
                if not username then
                    call_back_func(false,"exist")
                    return 
                end
                --timeRules
                if data.timeRules and data.timeRules[1] then
                    echo(data.timeRules,true)
                    local result, reason = KeepworkServicePermission:TimesFilter(data.timeRules)
                    if not result and "CHECK_COURSE_ID" ~= reason then
                        call_back_func(false,"time")
                        return
                    end
                    -- holiday times verified
                    KeepworkServicePermission:HolidayTimesFilter(data.timeRules, function(bAllowed, reason)
                        if not bAllowed then
                            call_back_func(false,"time")
                            return
                        end
                    end)
                end
                -- private world verfied
                if data.visibility == 1  then
                    KeepworkServiceProject:GetMembers(pid, function(members, err)
                        if type(members) ~= 'table' then
                            call_back_func(false,"private")
                            return
                        end
                        local isFind = false
                        for key, item in ipairs(members) do
                            if item and item.username and item.username == username then    
                                isFind = true
                                break
                            end
                        end
                        if not isFind then
                            call_back_func(false,"private")
                            return
                        end
                    end)
                end

                -- vip enter
                if data and not data.isSystemGroupMember and data.extra and ((data.extra.vipEnabled and data.extra.vipEnabled == 1) or (data.extra.isVipWorld and data.extra.isVipWorld == 1)) then
                    if data.username and data.username ~= username and not  GameLogic.IsVip("Vip") then
                        call_back_func(false,"vip")
                        return
                    end
                end

                --org vip
                if data and data.extra and data.extra.instituteVipEnabled and data.extra.instituteVipEnabled == 1 then
                    if not GameLogic.IsVip('IsOrgan') then
                        call_back_func(false,"vip organ")
                        return 
                    end
                end
                --system group
                if data and data.isSystemGroupMember  then
                    if not data.level or data.level == 0 then
                        call_back_func(false,"system group")
                        return 
                    end
                end
                -- encrypt world
                if data and data.level and data.level == 2 then
                    -- call_back_func(false,"encrypt")
                    -- return
                end
                -- encode world
                if data and data.extra and data.extra.encode_world == 1 then
                    if (data.username and data.username ~= username) then
                        call_back_func(false,"encode_world")
                        return
                    end
                end
                call_back_func(true)
            end
        end)
    else
        call_back_func(false,"pid is null")
        return
    end
    -- print("call_back_func===========================4")
    -- call_back_func(false)
end

function PapaWorldLogic.EnterWorld(msg)
    if not msg then
        return
    end
    
    local world = msg.world
    if not world or not world.type then
        return
    end
    local callbackId = msg.callbackId
    self.callbackId = callbackId
    if world.type == "create_world" then
        self.CreateWorld(world)
        return
    end
    local projectId
    if world.type == "tuijian" then
        projectId = tonumber(world.projectId or 0)
    end
    if world.type == "main" then
        local worldId = self.GetProjectId(world.projectId)
        if worldId and tonumber(worldId) > 0 then
            projectId = tonumber(worldId)
        end
    end
    if projectId and projectId > 0 then --ID进入世界
        self.CheckWorldValidById(projectId,function(bSucceed,message)
              if bSucceed then
                local commandStr = string.format("/loadworld -s -auto %s", projectId)
                GameLogic.RunCommand(commandStr)    
                self:StartCheckLoaded(function()
                    if self.callbackId then
                        PapaAPI:SendEvent("createLoadWorld",{callbackId = self.callbackId,result = true})
                        self.callbackId = nil
                    end
                end)
              else
                if self.callbackId then
                    PapaAPI:SendEvent("createLoadWorld",{callbackId = self.callbackId,result = bSucceed,message = message})
                    self.callbackId = nil
                end
              end
        end)
        return
    end
    if world.type == "main" then
        --暂时不处理执行命令
        local urlObj = RemoteUrl:new():Init(world.projectId)
        if urlObj and urlObj:IsRemoteServer() then        
            local relativePath = urlObj:GetRelativePath() or ''
            local room_key = relativePath:match('^@(.+)')
            if room_key and room_key ~='' then
                GameLogic.RunCommand(string.format('/connect -tunnel %s %s %s',room_key,urlObj:GetHost(),urlObj:GetPort() or 8099))
            else
                GameLogic.RunCommand(string.format('/connect %s %s',urlObj:GetHost(),urlObj:GetPort() or 8099))
            end
            self:StartCheckLoaded(function()
                if self.callbackId then
                    PapaAPI:SendEvent("createLoadWorld",{callbackId = self.callbackId,result = true})
                    self.callbackId = nil
                end
            end)
        end
        return
    end

    if world.type == "enter_self_world" then
        if world.isCreate == true then --家园世界未创建
            NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua");
            local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
            LocalLoadWorld.CreateGetHomeWorld();

            PapaWorldLogic.SyncHomeWorld()
            return
        end
        local currentdata = self.GenerWordData(world)
        if currentdata then
            self.HandleEnterWorld(currentdata)
        end
    end
end

function PapaWorldLogic.SyncHomeWorld()
    if not KeepworkServiceSession:IsSignedIn() then
        return
    end
    local username = Mod.WorldShare.Store:Get('user/username')
    if not username then
        return
    end

    local foldername = username .. '_main'
    local worldPath = "worlds/DesignHouse/_user/" .. username .. "/" .. foldername
    local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
    SyncWorld:CheckAndUpdatedByFoldername(foldername,function ()
        GameLogic.RunCommand(string.format('/loadworld %s', worldPath))
        local Progress = NPL.load('(gl)Mod/WorldShare/cellar/Sync/Progress/Progress.lua')
        Progress.syncInstance = nil

        self:StartCheckLoaded(function()
            if self.callbackId then
                PapaAPI:SendEvent("createLoadWorld",{callbackId = self.callbackId,result = true})
                self.callbackId = nil
            end
        end)
    end,"papa_adventure")
end

function PapaWorldLogic.GenerWordData(DItem) --判断本地有木有
    local localWorlds = LocalServiceWorld:GetWorldList() or {}
    local userId = Mod.WorldShare.Store:Get('user/userId')
    local username = Mod.WorldShare.Store:Get('user/username')
    local syncBackUpWorld = {}
    -- echo(localWorlds,true)
    local isExist = false
    local text = DItem.worldName or ''
    local worldpath = ''
    local revision = 0
    local commitId = ''
    local remoteWorldUserId = DItem.user and DItem.user.id and tonumber(DItem.user.id) or 0
    local status
    local remoteShared = false
    local isVipWorld
    local instituteVipEnabled
    local name = ''

    if DItem.extra and DItem.extra.worldTagName then
        text = DItem.extra.worldTagName
    end

    if DItem.project and DItem.project.managed == 1 then
        remoteShared = true
    else
        if DItem.project and DItem.project.memberCount and DItem.project.memberCount > 1 then
            remoteShared = true
        end
    end
    for LKey, LItem in ipairs(localWorlds) do
        if DItem.worldName == LItem.foldername and not LItem.is_zip then
            local function Handle()
                if tonumber(LItem.revision or 0) == tonumber(DItem.revision or 0) then
                    status = 3 -- both
                    revision = LItem.revision
                elseif tonumber(LItem.revision or 0) > tonumber(DItem.revision or 0) then
                    status = 4 -- network newest
                    revision = DItem.revision -- use remote revision beacause remote is newest
                elseif tonumber(LItem.revision or 0) < tonumber(DItem.revision or 0) then
                    status = 5 -- local newest
                    revision = LItem.revision or 0
                end

                isExist = true

                worldpath = LItem.worldpath
                isVipWorld = LItem.isVipWorld
                instituteVipEnabled = LItem.instituteVipEnabled
                name = LItem.name

                -- update project for different user
                if tonumber(LItem.kpProjectId) ~= tonumber(DItem.projectId) then
                    if not string.match(LItem.foldername, '_main$') and
                       not remoteShared then
                        Mod.WorldShare.worldpath = nil -- force update world data.
                        local curWorldUsername = Mod.WorldShare:GetWorldData('username', LItem.worldpath)
                        local backUpWorldPath

                        if curWorldUsername then
                            backUpWorldPath =
                                LocalServiceWorld:GetDefaultSaveWorldPath() ..
                                '/_user/' ..
                                curWorldUsername ..
                                '/' ..
                                commonlib.Encoding.Utf8ToDefault(LItem.foldername)
                        else
                            backUpWorldPath =
                                'temp/sync_backup_world/' ..
                                commonlib.Encoding.Utf8ToDefault(LItem.foldername) ..
                                '_' ..
                                ParaMisc.md5(tostring(os.time()))
                        end

                        commonlib.Files.MoveFolder(LItem.worldpath, backUpWorldPath)

                        ParaIO.DeleteFile(LItem.worldpath)

                        status = 2
                        isExist = false
                    end
                end
            end

            if LItem.shared then -- share folder
                if remoteShared == LItem.shared then
                    -- avoid upload same name share world
                    local sharedUsername = Mod.WorldShare:GetWorldData('username', LItem.worldpath)
                    if sharedUsername == DItem.user.username then
                        Handle()
                    end
                end
            else -- personal folder
                if remoteShared then
                    if remoteWorldUserId == tonumber(userId) then
                        Handle()
                    end
                else
                    Handle()
                end
            end
        end
    end

    if not isExist then
        --network only
        status = 2
        revision = DItem.revision
        name = DItem.extra and DItem.extra.worldTagName or ''

        if remoteShared and remoteWorldUserId ~= tonumber(userId) then
            -- shared world path
            worldpath = format(
                '%s/_shared/%s/%s/',
                LocalServiceWorld:GetDefaultSaveWorldPath(),
                DItem.user.username,
                commonlib.Encoding.Utf8ToDefault(DItem.worldName)
            )

        else
            -- mine world path
            worldpath = format(
                '%s/%s/',
                LocalServiceWorld:GetUserFolderPath(),
                commonlib.Encoding.Utf8ToDefault(DItem.worldName)
            )

            local matchStr = '^' .. username .. '_(.+)'

            for SKey, SItem in ipairs(syncBackUpWorld) do
                if SItem.fileattr == 16 then
                    local matchFoldername = string.match(SItem.filename, matchStr)

                    if matchFoldername and
                       type(matchFoldername) == 'string' and
                       matchFoldername == DItem.worldName then
                        commonlib.Files.MoveFolder('temp/sync_backup_world/' .. SItem.filename, worldpath)

                        local curRevision = LocalService:GetRevision(worldpath)

                        if curRevision == tonumber(DItem.revision or 0) then
                            status = 3 -- both
                        elseif curRevision > tonumber(DItem.revision or 0) then
                            status = 4 -- network newest
                        elseif curRevision < tonumber(DItem.revision or 0) then
                            status = 5 -- local newest
                        end

                        break
                    end
                end
            end
        end
    end

    -- shared world text
    if remoteShared and remoteWorldUserId ~= tonumber(userId) then
        if DItem.extra and DItem.extra.worldTagName then
            text = (DItem.user and DItem.user.username or '') .. '/' .. (DItem.extra and DItem.extra.worldTagName or '')
        else
            text = (DItem.user and DItem.user.username or '') .. '/' .. text
        end
    end

    -- recover share remark
    if not remoteShared then
        if DItem.extra and DItem.extra.worldTagName and
           text ~= DItem.extra.worldTagName then
            text = DItem.extra.worldTagName
        end
    end

    if DItem.project then
        if DItem.project.visibility == 0 then
            DItem.project.visibility = 0
        else
            DItem.project.visibility = 1
        end
    end

    local currentWorld = KeepworkServiceWorld:GenerateWorldInstance({
        text = text,
        foldername = DItem.worldName,
        revision = revision,
        size = DItem.fileSize,
        modifyTime = Mod.WorldShare.Utils:UnifiedTimestampFormat(DItem.updatedAt),
        lastCommitId = DItem.commitId, 
        worldpath = worldpath,
        status = status,
        project = DItem.project,
        user = {
            id = DItem.user.userId,
            username = DItem.user.username,
        },
        kpProjectId = DItem.projectId,
        fromProjectId = DItem.fromProjectId,
        parentProjectId = DItem.project and DItem.project.parentProjectId or 0,
        IsFolder = true,
        is_zip = false,
        shared = remoteShared,
        isVipWorld = isVipWorld or false,
        instituteVipEnabled = instituteVipEnabled or false,
        memberCount = DItem.project.memberCount,
        members = {},
        name = name,
        level = DItem.level and DItem.level or 0,
        isSystemGroup = DItem.isSystemGroup or false,
        platform = DItem.platform,
    })

    -- print("gener world================")
    -- echo(currentWorld,true)
    return currentWorld
end

function PapaWorldLogic.StartLoadWorld(path)
    print("path==========",path)
    if path and path ~= "" then
        Game.Start(path)
        self:StartCheckLoaded(function()
            if self.callbackId then
                PapaAPI:SendEvent("createLoadWorld",{callbackId = self.callbackId,result = true})
                self.callbackId = nil
            end
        end)
    end
end

function PapaWorldLogic.IsHomeWorld(data)
    if type(data) == "table" then
        local username = Mod.WorldShare.Store:Get('user/username')
        if not username then
            return false
        end
        local myHomeWorldName = string.format(L"%s的家园", username);
        local myHomeWorldName1 = string.format(L"%s_main", username);  
        if data.foldername ==  myHomeWorldName or data.foldername == myHomeWorldName1 then
            return true
        end
    end
    return false
end

function PapaWorldLogic.CheckEnterWorld(data,call_back_func)
    if not KeepworkServiceSession:IsSignedIn() then
        if call_back_func then
            call_back_func(false,"login")
        end
        return
    end
    if VipTypeWorld:IsVipWorld(data) then
        if not GameLogic.IsVip('Vip') then
            if call_back_func then
                call_back_func(false,"vip")
            end
            return
        end
    end
    if VipTypeWorld:IsInstituteVipWorld(data) then
        if not GameLogic.IsVip('IsOrgan') then
            if call_back_func then
                call_back_func(false,"IsOrgan")
            end
            return
        end
    end
    if data and data.isSystemGroup == true and data.level == 1 then --系统组世界单独处理
        if call_back_func then
            call_back_func(false,"share")
        end
        return
    end
    if ShareTypeWorld:IsSharedWorld(data) then
        local username = Mod.WorldShare.Store:Get('user/username')
        if not data.user then
            if call_back_func then
                call_back_func(false,"share")
            end
            return
        end
        Create:CheckIsProjectMember(data.kpProjectId,function (isMember)
            if not isMember then
                if username ~= data.user.username and not GameLogic.IsVip('LimitUserOpenShareWorld') then
                    if call_back_func then
                        call_back_func(false,"share")
                    end
                end 
                return               
            end
            if data.level ~= 2 and data.level ~= 1 then
                if call_back_func then
                    call_back_func(false,"share")
                end
                return
            end
            if call_back_func then
                call_back_func(true)
            end
        end)
        return
    end
    if call_back_func then
        call_back_func(true)
    end
end

function PapaWorldLogic.EnterWorldImp(currentWorld)
    local function DownloadWorldFunc()
        DownloadWorld.ShowPage(format(L'%s（项目ID：%d）', currentWorld.foldername, currentWorld.kpProjectId))
        SyncToLocal:Init(function(result, option)
            if not result then
                if option and type(option) == 'string' then
                    DownloadWorld.Close()
                    self.EnterWorldFailed("down err")
                    return
                end

                if option and type(option) == 'table' then
                    if option.method == 'UPDATE-PROGRESS-FINISH' then
                        if not LocalServiceWorld:CheckWorldIsCorrect(currentWorld) then
                            local worldConfig = [[
-- Auto generated by ParaEngine 
type = lattice
TileSize = 533.333313
([0-63],[0-63]) = %WORLD%/flat.txt
]]

                            local worldConfigFile = ParaIO.open(currentWorld.worldpath .. '/worldconfig.txt', 'w')

                            worldConfigFile:write(worldConfig, #worldConfig)
                            worldConfigFile:close()
                        end

                        DownloadWorld.Close()
                        self.StartLoadWorld(currentWorld.worldpath)
                    end
                end
            end
        end)
    end


    if currentWorld.status == 2 then
        Mod.WorldShare.MsgBox:Wait()

        DownloadWorldFunc()
    else
        if currentWorld.status == 1 or not currentWorld.status then
            self.StartLoadWorld(currentWorld.worldpath)
            return
        end

        Mod.WorldShare.MsgBox:Wait()
        Compare:Init(currentWorld.worldpath, function(result)
            Mod.WorldShare.MsgBox:Close()

            if ShareTypeWorld:IsSharedWorld(currentWorld) then
                ShareTypeWorld:CompareVersion(result, function(result)
                    if result == 'SYNC' then
                        SyncWorld:BackupWorld()

                        Mod.WorldShare.MsgBox:Wait()

                        SyncWorld:SyncToLocalSingle(function(result, option)
                            Mod.WorldShare.MsgBox:Close()

                            if result == true then
                                self.StartLoadWorld(currentWorld.worldpath)
                            end
                        end)
                    else
                        self.StartLoadWorld(currentWorld.worldpath)
                    end
                end)
            else
                if result == Compare.REMOTEBIGGER then
                    SyncWorld:ShowStartSyncPage(true, function()
                        self:GetWorldList(self.statusFilter)
                    end)
                else
                    self.StartLoadWorld(currentWorld.worldpath)
                end
            end
        end)
    end
end

--TODO:优化一下代码
function PapaWorldLogic.HandleEnterWorld(data)
    if not data or type(data) ~= 'table' then
        return
    end
    if PapaWorldLogic.IsHomeWorld(data) then --家园特殊处理
        PapaWorldLogic.SyncHomeWorld()
        return
    end
    local currentSelectedWorld = data
    -- zip file
    if currentSelectedWorld.is_zip then
        self.StartLoadWorld(currentSelectedWorld.worldpath)
        return
    end

    -- check world
    if currentSelectedWorld.status ~= 2 then
        if not LocalServiceWorld:CheckWorldIsCorrect(currentSelectedWorld) then
            local worldConfig = [[
-- Auto generated by ParaEngine 
type = lattice
TileSize = 533.333313
([0-63],[0-63]) = %WORLD%/flat.txt
            ]]

            local worldConfigFile = ParaIO.open(currentSelectedWorld.worldpath .. '/worldconfig.txt', 'w')

            worldConfigFile:write(worldConfig, #worldConfig)
            worldConfigFile:close()
        end
    end

    
    Mod.WorldShare.Store:Set('world/currentWorld', currentSelectedWorld)
    local currentWorld = currentSelectedWorld

    print("currentWorld.status=========",currentWorld.status,currentWorld.foldername,currentWorld.kpProjectId)
    
    self.CheckEnterWorld(currentWorld,function(bEnter,message)
        if bEnter then
            self.EnterWorldImp(currentWorld)
        else
            if message == "share" and currentWorld.level == 1 and currentWorld.kpProjectId and tonumber(currentWorld.kpProjectId) > 0 then --系统组世界
                self.CheckWorldValidById(currentWorld.kpProjectId,function(bSucceed,message)
                    if bSucceed then
                        local commandStr = string.format("/loadworld -s -auto %s", currentWorld.kpProjectId)
                        GameLogic.RunCommand(commandStr)    
                        self:StartCheckLoaded(function()
                            if self.callbackId then
                                PapaAPI:SendEvent("createLoadWorld",{callbackId = self.callbackId,result = true})
                                self.callbackId = nil
                            end
                        end)
                    else
                        if self.callbackId then
                            PapaAPI:SendEvent("createLoadWorld",{callbackId = self.callbackId,result = bSucceed,message = message})
                            self.callbackId = nil
                        end
                    end
                end)
                return
            end
            if self.callbackId then
                PapaAPI:SendEvent("createLoadWorld",{callbackId = self.callbackId,result = false,message = message})
                self.callbackId = nil
            end
        end
    end)
end

function PapaWorldLogic.DeleteLocal(callback)
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not currentWorld then
        GameLogic.AddBBS(nil, L'删除失败(NO INSTANCE)', 3000, '255 0 0')
        return false
    end

    local function Delete()
        if not currentWorld.worldpath then
            return false
        end

        if currentWorld.is_zip then
            if ParaIO.DeleteFile(currentWorld.worldpath) then
                if callback and type(callback) == 'function' then
                    callback()
                end
            else
                GameLogic.AddBBS(nil, L'无法删除，可能您没有足够的权限', 3000, '255 0 0')
            end
        else
            if GameLogic.RemoveWorldFileWatcher then
                GameLogic.RemoveWorldFileWatcher() -- file watcher may make folder deletion of current world directory not working.
            end

            if commonlib.Files.DeleteFolder(currentWorld.worldpath) then
                if callback and type(callback) == 'function' then
                    callback()
                end
            else
                GameLogic.AddBBS(nil, L'无法删除，可能您没有足够的权限', 3000, '255 0 0')
            end
        end
    end

    if currentWorld.status ~= 2 then
        Delete()
    end
end

function PapaWorldLogic.DeleteRemote(callback)
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    if not currentWorld then
        return
    end
    KeepworkServiceProject:RemoveProjectWithNoPWD(
        currentWorld.kpProjectId,
        function(data, err)
            if err ~= 204 and err ~= 200 then
                if data and type(data) == 'table' and data.message then
                    self.SendDeleteEvent({callbackId = self.callbackId,result = false})
                else
                    self.SendDeleteEvent({callbackId = self.callbackId,result = false})
                end
                self.callbackId = nil
                return
            end

            if currentWorld and currentWorld.worldpath and #currentWorld.worldpath > 0 then
                local tag = LocalService:GetTag(currentWorld.worldpath)

                if tag then
                    tag.kpProjectId = nil
                    LocalService:SetTag(currentWorld.worldpath, tag)
                end
            end

            if callback and type(callback) == 'function' then
                callback()
            end
        end
    )
end

function PapaWorldLogic.DeleteWorld(msg)
    local world = msg.world
    if not world then
        return
    end
    -- echo(world,true)
    self.callbackId = msg.callbackId
    local currentdata = self.GenerWordData(world)
    Mod.WorldShare.Store:Set('world/currentWorld', currentdata)
    echo(currentdata,true)
    if self.IsSharedWorld() then
        self.on_exit_shared_world()
        return
    end
    if currentdata and currentdata.kpProjectId and currentdata.kpProjectId > 0 and not self.IsHomeWorld(currentdata) then
        self.DeleteRemote(function()
            local worldPath = currentdata.worldpath
            if ParaIO.DoesFileExist(worldPath .. '/tag.xml', false) then
                self.DeleteLocal(function()
                    self.SendDeleteEvent({callbackId = self.callbackId,result = true})
                    self.callbackId = nil
                    return
                end)
            else
                self.SendDeleteEvent({callbackId = self.callbackId,result = true})
                self.callbackId = nil
                return
            end
        end)            
    else
        self.DeleteLocal(function()
            self.SendDeleteEvent({callbackId = self.callbackId,result = true})
            self.callbackId = nil
            return
        end)
    end
end

function PapaWorldLogic.SendDeleteEvent(params)
    if not params then
        return 
    end
    PapaAPI:SendEvent("DeleteWorld",params)
end

function PapaWorldLogic.IsHomeWorld(world)
    if not world then
        return false
    end
    local worldname = world.name
    local foldername = world.foldername
    if string.find(worldname,"家园") or string.find(worldname,"_main") 
        or string.find(foldername,"家园") or string.find(foldername,"_main") then
        return true
    end
    return false
end

function PapaWorldLogic.is_multiplayer_world()
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    if (currentWorld.project and currentWorld.project.memberCount or 0) > 1 then
        return true
    else
        return false
    end
end

function PapaWorldLogic.is_mine_world()
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    local username = Mod.WorldShare.Store:Get('user/username') or ''
    local user = currentWorld.user

    if not user or
        type(user) ~= 'table' or
        not user.username then
        return false
    end

    if username == user.username then
        return true
    else
        return false
    end
end

function PapaWorldLogic.IsSharedWorld()
    return self.is_multiplayer_world() and not self.is_mine_world()
end

function PapaWorldLogic.on_exit_shared_world()
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    if not currentWorld then
        return
    end
    KeepworkServiceProject:LeaveMultiProject(currentWorld.kpProjectId, function(data, err)
        if err == 200 then
            if currentWorld.status == 2 then
                self.SendDeleteEvent({callbackId = self.callbackId,result = true})
                self.callbackId = nil
            else
                self.DeleteLocal(function()
                    self.SendDeleteEvent({callbackId = self.callbackId,result = true})
                    self.callbackId = nil
                end)
            end
        end
    end)
end