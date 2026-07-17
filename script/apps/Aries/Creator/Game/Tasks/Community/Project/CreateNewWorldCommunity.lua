--[[
    author:{pbb}
    time:2024-05-028 17:50:48
    uselib:
        local CreateNewWorldCommunity = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Project/CreateNewWorldCommunity.lua")
        CreateNewWorldCommunity.ShowPage(params)
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/CreateNewWorld.lua");
local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')

local CreateNewWorldCommunity = NPL.export()
local self = CreateNewWorldCommunity
local page = nil
function CreateNewWorldCommunity.OnInit()
    page = document:GetPageCtrl()
    page.OnClose = CreateNewWorldCommunity.OnClose
end

function CreateNewWorldCommunity.ShowPage(params)
    CreateNewWorldCommunity.create_data = params
    
    local view_width, view_height = 0,0
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Community/Project/CreateNewWorldCommunity.html",
        name = "CreateNewWorldCommunity.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        cancelShowAnimation = true,
        directPosition = true,
            align = "_fi",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    CreateNewWorldCommunity.GetFolderName()
    GameLogic.GetEvents():RemoveEventListener("createworld_callback",CreateNewWorldCommunity.CreateWorldCallback, CreateNewWorldCommunity, "CreateNewWorldCommunity")
    GameLogic.GetEvents():AddEventListener("createworld_callback", CreateNewWorldCommunity.CreateWorldCallback, CreateNewWorldCommunity, "CreateNewWorldCommunity");
end

function CreateNewWorldCommunity.CreateWorldCallback(_, event)
    local worldPath = commonlib.Encoding.DefaultToUtf8(event.world_path)
    if not worldPath or worldPath == "" then
        GameLogic.AddBBS(nil, L"创建世界失败，请重试")
        return
    end
    local paths = commonlib.split(worldPath,"/")
    local worldName = paths[#paths]
    if worldName and worldName ~= "" then
        local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
        SyncWorld:CheckAndUpdatedByFoldername(worldName,function ()
            GameLogic.RunCommand(string.format('/loadworld %s', worldPath))
        end)
    end
end

function CreateNewWorldCommunity.OnClose()
    CreateNewWorld.LastWorldName = nil
    CreateNewWorldCommunity.create_data = nil
end

function CreateNewWorldCommunity.IsFroceCreate()
    return CreateNewWorldCommunity.create_data and CreateNewWorldCommunity.create_data.folder_name and CreateNewWorldCommunity.create_data.folder_name ~= ""
end

function CreateNewWorldCommunity.GetFolderName()
    if CreateNewWorldCommunity.IsFroceCreate() then
        return CreateNewWorldCommunity.create_data.folder_name
    end
    CreateNewWorld.page = page
    CreateNewWorld.GetUserName()
    print("CreateNewWorld.LastWorldName================",CreateNewWorld.LastWorldName)
    return CreateNewWorld.LastWorldName
end

function CreateNewWorldCommunity.GetImageUrl()
    if CreateNewWorldCommunity.create_data then
        return CreateNewWorldCommunity.create_data.img_bg or ""
    end
    return ""
end

function CreateNewWorldCommunity.OnBeforeLoadWorld()
    if not CreateNewWorldCommunity.currentWorld then
        return
    end
    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
    if CreateNewWorldCommunity.IsFroceCreate() then
        local kpProjectId = CreateNewWorldCommunity.currentWorld.id or 0
        WorldCommon.SetWorldTag("kpProjectId", kpProjectId);
    end
    if CreateNewWorldCommunity.currentWorld.isDeleted == 1 then
        WorldCommon.SetWorldTag("name", CreateNewWorldCommunity.currentWorld.name);
    end
    WorldCommon.SaveWorldTag()
    GameLogic.GetFilters():remove_filter("OnBeforeLoadWorld",CreateNewWorldCommunity.OnBeforeLoadWorld);
    CreateNewWorldCommunity.currentWorld = nil
end

function CreateNewWorldCommunity.CreateNewWorld()
    local new_world_name = page:GetValue("new_world_name")
    if not new_world_name or new_world_name == "" then
        _guihelper.MessageBox(L"请输入世界名")
        return
    end
    GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.create_new_world.click_create", {useNoId=true},nil,true);
    local foldername = CreateNewWorldCommunity.IsFroceCreate() and CreateNewWorldCommunity.create_data.folder_name or new_world_name
    local currentWorldList = Mod.WorldShare.Store:Get('world/fullWorldList') or {}
    foldername = foldername:gsub('[%s/\\]', '')
    local isFind,currentWorld = false,nil
    for key, item in ipairs(currentWorldList) do
        if item and foldername and (item.name == foldername) then
            -- _guihelper.MessageBox(L'世界名已存在，请列表中进入')
            isFind = true
            currentWorld = item
            break
        end
    end
    if isFind then
        if not CreateNewWorldCommunity.IsFroceCreate() and (not currentWorld.isDeleted or currentWorld.isDeleted == 0) then
            _guihelper.MessageBox(L'已有相同名称的世界，请重新输入世界名')
            return
        end
        if currentWorld.isDeleted == 1 then
            foldername = foldername.."_"..os.time()
        end
        self.currentWorld = currentWorld
        GameLogic.GetFilters():add_filter("OnBeforeLoadWorld", CreateNewWorldCommunity.OnBeforeLoadWorld); 
    end

    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

    if currentEnterWorld and currentEnterWorld.foldername == foldername then
        _guihelper.MessageBox(L'世界名已存在，请列表中进入')
        return
    end

    -- 客户端处理敏感词
    local temp = MyCompany.Aries.Chat.BadWordFilter.FilterString(foldername);

    if temp ~= foldername then 
        _guihelper.MessageBox(L"该世界名称不可用，请重新设定")
        return
    end

    local worldPath = ParaIO.GetWritablePath() .. 'worlds/DesignHouse/' .. foldername

    if ParaIO.DoesFileExist(worldPath, true) == true then
        Mod.WorldShare.worldpath = nil -- force update world data.
        local curWorldUsername = Mod.WorldShare:GetWorldData('username', worldPath)
        local backUpWorldPath

        if curWorldUsername then
            backUpWorldPath =
                LocalServiceWorld:GetDefaultSaveWorldPath() ..
                '/_user/' ..
                curWorldUsername ..
                '/' ..
                commonlib.Encoding.Utf8ToDefault(foldername)

            commonlib.Files.MoveFolder(worldPath, backUpWorldPath)

            ParaIO.DeleteFile(worldPath)
        end
    end

    Mod.WorldShare.Store:Remove('world/currentWorld')
	local projectId = CreateNewWorldCommunity.create_data.id
    if not projectId or projectId == 0 then
        self.CreateWorldByName(foldername)
        return 
    end
	self.ForkWorldByName(foldername,projectId)
end 

function CreateNewWorldCommunity.CreateWorldByName(foldername)
    local terrain = CreateNewWorldCommunity.create_data.project_name and CreateNewWorldCommunity.create_data.project_name ~= "" and CreateNewWorldCommunity.create_data.project_name or "superflat"
    CreateWorld:CreateWorldByName(foldername, terrain,true)
end

function CreateNewWorldCommunity.ForkWorldByName(foldername,projectId)
    print("CreateNewWorldCommunity.ForkWorldByName foldername=",foldername,projectId)
    if not projectId or projectId == 0  or not foldername or foldername == "" then
        return
    end
    local commandStr = string.format('/createworld -name "%s" -parentProjectId %d -update -fork %d -mode admin', foldername,projectId,projectId)
    if System.options.isDevMode then
        print("CreateNewWorldCommunity forkWorldByName command str======",commandStr)
        print("worldName======",foldername,projectId)
    end
    GameLogic.RunCommand(commandStr)
end