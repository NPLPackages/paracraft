--[[
    author:{pbb}
    time:2023-11-07 16:08:48
    uselib:
        local ProjectActivationList = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/ProjectActivationList.lua")
        ProjectActivationList.ShowPage()
]]


NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldRevision.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/SaveWorldHandler.lua");
local EducateProject = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/EducateProject.lua")
local KeepworkWorldsApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/KeepworkWorldsApi.lua')
local SaveWorldHandler = commonlib.gettable("MyCompany.Aries.Game.SaveWorldHandler")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision");
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')

local ProjectActivationList = NPL.export()
ProjectActivationList.activationList = {}
ProjectActivationList.localWorldList = {}
local page
function ProjectActivationList.OnInit()
    page = document:GetPageCtrl()
end

function ProjectActivationList.ShowPage()
    ProjectActivationList.localWorldList = ProjectActivationList.GetLocalWorldList()
    ProjectActivationList.activationList = {}
    ProjectActivationList.GetRemoteWorldList(function(worldList)
        if type(worldList) == "table" and #worldList > 0 then
            ProjectActivationList.activationList = worldList
            ProjectActivationList.HandleActivationData()
            if #ProjectActivationList.activationList > 0 then
                ProjectActivationList.ShowView()
            else
                GameLogic.AddBBS("ProjectActivationList",L"暂无需要激活的世界")
            end
        else
            GameLogic.AddBBS("ProjectActivationList",L"暂无需要激活的世界")
        end
    end)
end

function ProjectActivationList.ShowView()
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Educate/Project/ProjectActivationList.html",
        name = "ProjectActivationList.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        zorder = 10,
        directPosition = true,
        cancelShowAnimation = true,
        align = "_fi",
            width = view_width,
            height = view_height,
            x = -view_width/2,
            y = -view_height/2,
    };
    
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ProjectActivationList.ClosePage()
    if page then
        page:CloseWindow(true)
        page = nil
    end
end

function ProjectActivationList.GetLocalWorldList()
    local localWorlds = LocalServiceWorld:BuildLocalWorldList()
    local filterLocalWorlds = {}

    -- not main world filter
    for key, item in ipairs(localWorlds) do
        if KeepworkServiceSession:IsSignedIn() then
            local username = Mod.WorldShare.Store:Get('user/username')

            if item and item.foldername then
                local matchFoldername = string.match(item.foldername, '(.+)_main$')

                if matchFoldername then
                    if matchFoldername == username then
                        filterLocalWorlds[#filterLocalWorlds + 1] = item
                    end
                else
                    filterLocalWorlds[#filterLocalWorlds + 1] = item
                end
            else
                if not item.IsFolder then
                    filterLocalWorlds[#filterLocalWorlds + 1] = item
                end
            end
        else
            if item and item.foldername and not string.match(item.foldername, '_main$') then
                filterLocalWorlds[#filterLocalWorlds + 1] = item
            else
                if not item.IsFolder then
                    filterLocalWorlds[#filterLocalWorlds + 1] = item
                end
            end
        end
    end

    localWorlds = filterLocalWorlds

    local worldList = {}

    for key, value in ipairs(localWorlds) do
        local foldername = ''
        local Title = ''
        local text = ''
        local is_zip
        local revision = 0
        local kpProjectId = 0
        local parentProjectId = 0
        local size = 0
        local name = ''
        local isVipWorld = false
        local instituteVipEnabled = false
        local modifyTime = Mod.WorldShare.Utils:UnifiedTimestampFormat(value.writedate)
        local platform = 'paracraft'

        if value.IsFolder then
            value.worldpath = value.worldpath .. '/'
            is_zip = false
            revision = WorldRevision:new():init(value.worldpath):GetDiskRevision()
            foldername = value.foldername
            Title = value.Title

            local tag = SaveWorldHandler:new():Init(value.worldpath):LoadWorldInfo()
            text = tag.name
            kpProjectId = tag.kpProjectId
            size = tag.size
            name = tag.name
            isVipWorld = tag.isVipWorld
            instituteVipEnabled = tag.instituteVipEnabled
            parentProjectId = tag.parentProjectId
            platform = tag.platform
        else
            local zipFilename = string.match(value.worldpath, '/([^/.]+)%.zip$')
            zipFilename = commonlib.Encoding.DefaultToUtf8(zipFilename)

            foldername = zipFilename
            Title = zipFilename
            text = zipFilename

            is_zip = true
        end

        worldList[#worldList + 1] = LocalServiceWorld:GenerateWorldInstance({
            IsFolder = value.IsFolder,
            is_zip = is_zip,
            kpProjectId = kpProjectId,
            parentProjectId = parentProjectId,
            text = text,
            size = size,
            foldername = foldername,
            modifyTime = modifyTime,
            worldpath = value.worldpath,
            name = name,
            revision = revision,
            isVipWorld = isVipWorld,
            instituteVipEnabled = instituteVipEnabled,
            shared = value.shared or false,
            platform = platform,
        })
    end

    return worldList
end

function ProjectActivationList.GetWorldSize(kpProjectId,size)
    local worldSize = size
    if kpProjectId and tonumber(kpProjectId) > 0 then
        for k,v in pairs(ProjectActivationList.localWorldList) do
            if v.kpProjectId and tonumber(v.kpProjectId) == tonumber(kpProjectId) then
                worldSize = (v.size and tonumber(v.size) > 0) and tonumber(v.size) or size
                break
            end 
        end
    end
    return worldSize
end

function ProjectActivationList.HandleActivationData()
    local listData = ProjectActivationList.activationList
    local tempList = {}
    local username = Mod.WorldShare.Store:Get('user/username')
    for k,v in pairs(listData) do
        if username and username ~= "" and v.user and v.user.username == username then
            if v.extra and v.extra.commitIds then
                v.extra.commitIds = nil
            end
            if v.project and v.project.extra and v.project.extra.commitIds then
                v.project.extra.commitIds = nil
            end
            tempList[#tempList + 1] = v
        end
    end
    ProjectActivationList.activationList = tempList
end

function ProjectActivationList.GetRemoteWorldList(callback)
    KeepworkWorldsApi:GetWorldList(1000, 1, function(data, err)
        if err == 200 then
            local filtersData = {}
            for key, item in ipairs(data) do
                if item and
                    item.project and
                    type(item.project) == 'table' and
                    item.project.platform and
                    not Mod.WorldShare.Utils.IsEducatePlatform(item.project.platform) then
                    filtersData[#filtersData + 1] = item
                end
            end

            callback(filtersData)
        else
            callback()
        end
    end)
end 


function ProjectActivationList.ActivateProject(index)
    if index and tonumber(index) > 0 then
        local world = ProjectActivationList.activationList[tonumber(index)]
        echo(world,true)
        keepwork.project.update({
            router_params = {
                id = world.projectId,
            },
            platform = System.options.appId or "paracraft_431",
            fileSize = ProjectActivationList.GetWorldSize(world.projectId,world.fileSize),
        },function(err,msg,data)
            if err == 200 then
                GameLogic.AddBBS(nil,L"导入项目成功")
                EducateProject.RefreshPage()
                ProjectActivationList.ClosePage()
            end
        end)
    end
end

