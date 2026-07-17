--[[
Title: CurClassPage
Author(s): yangguiyi
Date: 2023/2/10
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/CurClassPage.lua").ShowView();
--]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/EducateClassManager.lua");
local EducateClassManager = commonlib.gettable("MyCompany.Aries.Game.Educate.Class.Manager");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local CurClassPage = NPL.export();

local server_time = 0
local page
function CurClassPage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = CurClassPage.OnClose
end

function CurClassPage.ShowView(data)
    if page and page:IsVisible() then
        return
    end
    local view_width = 0
    local view_height = 0
    CurClassPage.ServerData = data
    CurClassPage.HandleData()
    EducateClassManager.SetClassData(data)
    EducateClassManager.JoinClassRoom()
    local params = {
        url = "script/apps/Aries/Creator/Game/Educate/Project/CurClassPage.html",
        name = "CurClassPage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        zorder = 1,
        directPosition = true,
        --withBgMask=true,
        align = "_fi",
        x = -view_width/2,
        y = -view_height/2,
        width = view_width,
        height = view_height,
        isTopLevel = true,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function CurClassPage.FreshView()
    local parent  = page:GetParentUIObject()
end

function CurClassPage.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    CurClassPage.FreshView()
end

function CurClassPage.CloseView()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function CurClassPage.OnClose()
    CurClassPage.ClearData()
end

function CurClassPage.ClearData()

end

function CurClassPage.HandleData()
    if not CurClassPage.ServerData or not CurClassPage.ServerData.sectionContents then
        return
    end
    -- echo(CurClassPage.ServerData,true)
    for index = 1, #CurClassPage.ServerData.sectionContents do
        local lesson_data = CurClassPage.ServerData.sectionContents[index]
        lesson_data.index = index
        -- CurClassPage.LessonsData[#CurClassPage.LessonsData + 1] = {org_name=class_data.org.name, class_name=class_data.class.name}
    end
    CurClassPage.LessonsData=CurClassPage.ServerData.sectionContents
end

function CurClassPage.OnOpen(index)
    index = index and tonumber(index)
    if CurClassPage.LessonsData and CurClassPage.LessonsData[index] then
        local select_data = CurClassPage.LessonsData[index]
        -- echo(select_data,true)
        
        if select_data.contentType == 6 then
            CurClassPage.LoadWorld(select_data)
            CurClassPage.CloseView()
            return
        end
        local classData = {
            classAt = CurClassPage.ServerData.startAt,
            classroomId = CurClassPage.ServerData.id,
            lessonName=CurClassPage.ServerData.lesson and CurClassPage.ServerData.lesson.name or "",
            lessonPackageName=CurClassPage.ServerData.lessonPackage and CurClassPage.ServerData.lessonPackage.name or "",
            materialName=select_data.name,
            sectionContentId=select_data.id, 
        }
        if select_data.contentType == 7 and select_data.content then
            classData.forkProjectId = select_data.forkProjectId
            classData.projectName = select_data.content.homeworkName
            classData.isVisibility = select_data.content.isVisibility
            local ClassContentPage =  NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/ClassContentPage.lua")
            ClassContentPage.ShowView(classData)
        end
    end
end

function CurClassPage.LoadWorld(data)
    local projectEvent = data.projectEvent
    local projectid = data.materialProjectId
    local commandStr = string.format("/loadworld -s -auto -lesson %s ", projectid)
    if projectEvent ~= nil and projectEvent ~= "" then
        local hasSlash = projectEvent:find("^/")
        local hasEventName = projectEvent:match("^([%w%d]+%s+)")
        if hasSlash then
            commandStr = string.format("/loadworld -s -auto -lesson -inplace %s | %s", projectid,projectEvent)
        elseif hasEventName then
            commandStr = string.format("/loadworld -s -auto -lesson -inplace %s | /sendevent %s", projectid,projectEvent)
        else
            commandStr = string.format("/loadworld -s -auto -lesson -inplace %s | /sendevent globalStartLesson %s", projectid,projectEvent)
        end
    end
    GameLogic.RunCommand(commandStr)
end

function CurClassPage.ForkWorld(data)
    local sectionContentId = data.id
    local createTime = CurClassPage.ServerData.startAt
    local year, month, day, hour, min, sec = createTime:match("^(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)") 
    local worldName = year..string.format("%.2d",month)..string.format("%.2d",day).."_"..string.format("%.2d",hour)..string.format("%.2d",min).."_"..string.format("%.2d",sectionContentId)
    local username = Mod.WorldShare.Store:Get("user/username");
    local worldPath = "worlds/DesignHouse/".. worldName
    if username and username ~= "" then
        worldPath = "worlds/DesignHouse/_user/" .. username .. "/" .. worldName
    end

    local function tryFunc(callback)
        local tryTime = 0;
        local timer;
        timer = commonlib.Timer:new({
            callbackFunc = function()
                if (tryTime >= 120) then
                    timer:Change(nil, nil);
                    GameLogic.AddBBS("CurClassPage","加载世界超时...")
                    return;
                end
    
                if (ParaIO.DoesFileExist(worldPath)) then
                    timer:Change(nil, nil);
                    if callback then
                        callback()
                    end
                end
                
                tryTime = tryTime + 1;
            end
        }, 500);
        timer:Change(0, 500);
    end
    print("worldName========",worldName,worldPath)
    if (not ParaIO.DoesFileExist(worldPath)) then
        local fork_project_id = data.forkProjectId
        if fork_project_id and tonumber(fork_project_id) > 0 then
            local cmd = format(
                "/createworld -name \"%s\" -parentProjectId %d -update -fork %d -mode admin",
                worldName,
                fork_project_id,
                fork_project_id
            );
            print("cmd=========",cmd)
            GameLogic.RunCommand(cmd);
        else
            local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')
            CreateWorld:CreateWorldByName(worldName, "superflat",false)
        end
    end
    tryFunc(function()
        local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
        SyncWorld:CheckAndUpdatedByFoldername(worldName,function ()
            CurClassPage.CloseView()
            GameLogic.RunCommand(string.format('/loadworld %s', worldPath))
            local Progress = NPL.load('(gl)Mod/WorldShare/cellar/Sync/Progress/Progress.lua')
            Progress.syncInstance = nil
        end)
    end)
    
end

function CurClassPage.GetClassPackageName()
    return CurClassPage.ServerData.lessonPackage.name
end

function CurClassPage.GetLessonName()
    return CurClassPage.ServerData.lesson.name
end

function CurClassPage.OpenClassWeb()
    EducateClassManager.OpenClassWeb()
end