--[[
Title: ClassSelectPage
Author(s): yangguiyi
Date: 2023/2/10
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/ClassSelectPage.lua").ShowView();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local QuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/QuestPage.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local ClassSelectPage = NPL.export();

local server_time = 0
local page
function ClassSelectPage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = ClassSelectPage.OnClose
end

function ClassSelectPage.ShowView(data)
    if page and page:IsVisible() then
        return
    end

    -- data = 
    -- {
    --     count=10,
    --     rows={
    --         {id=10086,lessonPackage={name="课包名"},orgClass={name="班级信息名"},org={name="哈佛大学"},lesson={id=1,name="第一课aaa",coverUrl=""},
    --         sectionContents={                
    --                 {
    --                     -- contentType 类型: 1.视频, 2.交互视频, 3.pdf, 4.图片, 5.长图文(html), 6.作品赏析, 7.创作模板
    --                     contentType=6,
    --                     --name 素材名称
    --                     name="素材名称1",
    --                     forkProjectId=1142833,
    --                     materialProjectId=1162666,
    --                 },
    --                 {
    --                     -- contentType 类型: 1.视频, 2.交互视频, 3.pdf, 4.图片, 5.长图文(html), 6.作品赏析, 7.创作模板
    --                     contentType=7,
    --                     --name 素材名称
    --                     name="素材名称2",
    --                     forkProjectId=1142833,
    --                     materialProjectId=1162666,
    --                 },
    --             }
    --         },
    --         {id=10087,lessonPackage={name="课包名2"},orgClass={name="班级信息名2"},org={name="哈佛小学"},lesson={id=1,name="第一课aaa",coverUrl=""},
    --         sectionContents={                
    --                 {
    --                     -- contentType 类型: 1.视频, 2.交互视频, 3.pdf, 4.图片, 5.长图文(html), 6.作品赏析, 7.创作模板
    --                     contentType=6,
    --                     --name 素材名称
    --                     name="素材名称21",
    --                     forkProjectId=1142833,
    --                     materialProjectId=1162666,
    --                 },
    --                 {
    --                     -- contentType 类型: 1.视频, 2.交互视频, 3.pdf, 4.图片, 5.长图文(html), 6.作品赏析, 7.创作模板
    --                     contentType=7,
    --                     --name 素材名称
    --                     name="素材名称22",
    --                     forkProjectId=1142833,
    --                     materialProjectId=1162666,
    --                 },
    --             }
    --         },
    --     }
    -- }
    if not data then
        return
    end
    ClassSelectPage.ServerData = data.rows
    if #data.rows == 1 then
        ClassSelectPage.OnOpen(1)
        return
    end

    ClassSelectPage.HandleData()

    local params = {
        url = "script/apps/Aries/Creator/Game/Educate/Project/ClassSelectPage.html",
        name = "ClassSelectPage.Show", 
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
end

function ClassSelectPage.FreshView()
    local parent  = page:GetParentUIObject()
end

function ClassSelectPage.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    ClassSelectPage.FreshView()
end

function ClassSelectPage.CloseView()
    if page then
        page:CloseWindow()
    end
end

function ClassSelectPage.OnClose()
    ClassSelectPage.ClearData()
end

function ClassSelectPage.ClearData()
end

function ClassSelectPage.HandleData()
    -- ClassSelectPage.ClassesData = {{name="男孩和1"}, {name="男孩和2"}, {name="男孩和3"}}
    ClassSelectPage.ClassesData={}
    for index = 1, #ClassSelectPage.ServerData do
        local class_data = ClassSelectPage.ServerData[index]
        ClassSelectPage.ClassesData[#ClassSelectPage.ClassesData + 1] = {
            org_name=class_data.org.name, 
            class_name=class_data.orgClass.name,
            package_name=class_data.lessonPackage.name,
            lesson_name=class_data.lesson.name,
        }
    end
end

function ClassSelectPage.OnOpen(index)
    index = index and tonumber(index)
    if ClassSelectPage.ServerData and ClassSelectPage.ServerData[index] then
        ClassSelectPage.CloseView()
        local select_data = ClassSelectPage.ServerData[index]
        NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/CurClassPage.lua").ShowView(select_data);
    end
end