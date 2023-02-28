--[[
Title: CurClassPage
Author(s): yangguiyi
Date: 2023/2/10
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/CurClassPage.lua").ShowView();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local QuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/QuestPage.lua");
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
    CurClassPage.ServerData = data
    CurClassPage.HandleData()
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Educate/Project/CurClassPage.html",
        name = "CurClassPage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 1,
        directPosition = true,
        withBgMask=true,
        align = "_ct",
        x = -640/2,
        y = -393/2,
        width = 640,
        height = 393,
        isTopLevel = true,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    GameLogic.GetEvents():AddEventListener("createworld_callback", CurClassPage.CreateWorldCallback, CurClassPage, "CurClassPage");
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
    end
end

function CurClassPage.OnClose()
    CurClassPage.ClearData()
end

function CurClassPage.ClearData()
    GameLogic.GetEvents():RemoveEventListener("createworld_callback",CurClassPage.CreateWorldCallback,CurClassPage)
end

function CurClassPage.CreateWorldCallback(_, event)
    CurClassPage.CloseView()
    GameLogic.RunCommand(string.format('/loadworld %s', commonlib.Encoding.DefaultToUtf8(event.world_path)))
end

function CurClassPage.HandleData()
    if not CurClassPage.ServerData or not CurClassPage.ServerData.sectionContents then
        return
    end

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
        -- contentType 类型: 1.视频, 2.交互视频, 3.pdf, 4.图片, 5.长图文(html), 6.作品赏析, 7.创作模板
        if select_data.contentType == 6 then
            local projectid = select_data.materialProjectId
            local commandStr = string.format("/loadworld -s -auto %s", projectid)
            GameLogic.RunCommand(commandStr)
            CurClassPage.CloseView()
        elseif select_data.contentType == 7 then
            local project_name = select_data.name
            local fork_project_id = select_data.forkProjectId
            GameLogic.RunCommand(string.format([[/createworld -name "%s" -update -fork %d]], project_name, fork_project_id))	
        end
    end
end

function CurClassPage.GetClassPackageName()
    return CurClassPage.ServerData.lessonPackage.name
end

function CurClassPage.GetLessonName()
    return CurClassPage.ServerData.lesson.name
end