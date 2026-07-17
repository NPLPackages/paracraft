--[[
    author:{pbb}
    time:2024-05-028 17:50:48
    uselib:
        local CreateNewWorldAIGC = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/AIGC/CreateNewWorldAIGC.lua")
        CreateNewWorldAIGC.ShowPage(params)
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/CreateNewWorld.lua");
local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')

local all_projects_data = {
    {type="大型平坦世界", tagId=2001, name="大型平坦世界", project_name = "superflat", id = 0, img_bg="Texture/Aries/Creator/keepwork/Community/pingtan_200x150_32bits.png#0 0 200 150", vipType=0},
    {type="大型随机世界", tagId=2001, name="大型随机世界", project_name = "custom", id = 0, img_bg="Texture/Aries/Creator/keepwork/Community/suiji_200x150_32bits.png#0 0 200 150", vipType=0},
}
if System.os.IsEmscripten() then
    all_projects_data = {
        {type="大型平坦世界", tagId=2001, name="大型平坦世界", project_name = "superflat", id = 0, img_bg="Texture/Aries/Creator/keepwork/Community/pingtan_200x150_32bits.png#0 0 200 150", vipType=0},
    }
end

local CreateNewWorldAIGC = NPL.export()
CreateNewWorldAIGC.project_datas = all_projects_data
local self = CreateNewWorldAIGC
local page = nil
function CreateNewWorldAIGC.OnInit()
    page = document:GetPageCtrl()
    page.OnClose = CreateNewWorldAIGC.OnClose
end

function CreateNewWorldAIGC.ShowPage(params)
    CreateNewWorldAIGC.create_data = params
    CreateNewWorldAIGC.typeData = CreateNewWorldAIGC.project_datas[1]
    local view_width, view_height = 0,0
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Community/AIGC/CreateNewWorldAIGC.html",
        name = "CreateNewWorldAIGC.ShowPage", 
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
    CreateNewWorldAIGC.GetFolderName()
    GameLogic.GetEvents():RemoveEventListener("createworld_callback",CreateNewWorldAIGC.CreateWorldCallback, CreateNewWorldAIGC, "CreateNewWorldAIGC")
    GameLogic.GetEvents():AddEventListener("createworld_callback", CreateNewWorldAIGC.CreateWorldCallback, CreateNewWorldAIGC, "CreateNewWorldAIGC");
end

function CreateNewWorldAIGC.CreateWorldCallback(_, event)
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

function CreateNewWorldAIGC.OnClose()
    CreateNewWorld.LastWorldName = nil
    CreateNewWorldAIGC.create_data = nil
end

function CreateNewWorldAIGC.IsFroceCreate()
    return CreateNewWorldAIGC.create_data and CreateNewWorldAIGC.create_data.folder_name and CreateNewWorldAIGC.create_data.folder_name ~= ""
end

function CreateNewWorldAIGC.GetFolderName()
    if CreateNewWorldAIGC.IsFroceCreate() then
        return CreateNewWorldAIGC.create_data.folder_name
    end
    CreateNewWorld.page = page
    CreateNewWorld.GetUserName()
    return CreateNewWorld.LastWorldName
end

function CreateNewWorldAIGC.OnBeforeLoadWorld()
    if not CreateNewWorldAIGC.currentWorld then
        return
    end
    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
    if CreateNewWorldAIGC.IsFroceCreate() then
        local kpProjectId = CreateNewWorldAIGC.currentWorld.id or 0
        WorldCommon.SetWorldTag("kpProjectId", kpProjectId);
    end
    if CreateNewWorldAIGC.currentWorld.isDeleted == 1 then
        WorldCommon.SetWorldTag("name", CreateNewWorldAIGC.currentWorld.name);
    end
    WorldCommon.SaveWorldTag()
    GameLogic.GetFilters():remove_filter("OnBeforeLoadWorld",CreateNewWorldAIGC.OnBeforeLoadWorld);
    CreateNewWorldAIGC.currentWorld = nil
end

function CreateNewWorldAIGC.CreateNewWorld()
    local new_world_name = page:GetValue("new_world_name")
    if not new_world_name or new_world_name == "" then
        _guihelper.MessageBox(L"请输入世界名")
        return
    end
    local foldername = CreateNewWorldAIGC.IsFroceCreate() and CreateNewWorldAIGC.create_data.folder_name or new_world_name
    local currentWorldList = Mod.WorldShare.Store:Get('world/fullWorldList') or {}
    foldername = foldername:gsub('[%s/\\]', '')
    local isFind,currentWorld = false,nil
    for key, item in ipairs(currentWorldList) do
        if item and foldername and (item.name == foldername) then
            isFind = true
            currentWorld = item
            break
        end
    end
    if isFind then
        if not CreateNewWorldAIGC.IsFroceCreate() and (not currentWorld.isDeleted or currentWorld.isDeleted == 0) then
            _guihelper.MessageBox(L'已有相同名称的世界，请重新输入世界名')
            return
        end
        if currentWorld.isDeleted == 1 then
            foldername = foldername.."_"..os.time()
        end
        self.currentWorld = currentWorld
        GameLogic.GetFilters():add_filter("OnBeforeLoadWorld", CreateNewWorldAIGC.OnBeforeLoadWorld); 
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
	local projectId = CreateNewWorldAIGC.create_data.id
    if not projectId or projectId == 0 then
        self.CreateWorldByName(foldername)
        return 
    end
	self.ForkWorldByName(foldername,projectId)
end 

function CreateNewWorldAIGC.CreateWorldByName(foldername)
    local terrain = CreateNewWorldAIGC.typeData.project_name and CreateNewWorldAIGC.typeData.project_name ~= "" and CreateNewWorldAIGC.typeData.project_name or "superflat"
    CreateWorld:CreateWorldByName(foldername, terrain,true)
end

function CreateNewWorldAIGC.ForkWorldByName(foldername,projectId)
    print("CreateNewWorldAIGC.ForkWorldByName foldername=",foldername,projectId)
    if not projectId or projectId == 0  or not foldername or foldername == "" then
        return
    end
    local commandStr = string.format('/createworld -name "%s" -parentProjectId %d -update -fork %d -mode admin', foldername,projectId,projectId)
    GameLogic.RunCommand(commandStr)
end

function CreateNewWorldAIGC.GetWorldType()
    if CreateNewWorldAIGC.typeData then
        return CreateNewWorldAIGC.typeData.name
    end
    return "大型平坦世界"    
end

function CreateNewWorldAIGC.OnClickWorldType(data)
    CreateNewWorldAIGC.typeData = data
    if page then
        page:Refresh(0.01)
    end
end