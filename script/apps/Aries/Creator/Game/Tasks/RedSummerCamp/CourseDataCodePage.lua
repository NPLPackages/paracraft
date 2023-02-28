--[[
Title: CourseDataCodePage
Author(s): yangguiyi
Date: 2021/2/2
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/CourseDataCodePage.lua").ShowView();
--]]

local CourseDataCodePage = NPL.export();

local server_time = 0
local page
function CourseDataCodePage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = CourseDataCodePage.CloseView
    page.OnCreate = CourseDataCodePage.OnCreate
end

function CourseDataCodePage.ShowView(url)
    -- url = "https://qiniu-public.keepwork.com/QQ%E5%9B%BE%E7%89%8720220721141928.png"
    if not url then
        return
    end
    if page and page:IsVisible() then
        return
    end

    CourseDataCodePage.CodeImgUrl = url
    -- CourseDataCodePage.InitData(url)
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/CourseDataCodePage.html",
        name = "CourseDataCodePage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        -- app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -570/2,
        y = -390/2,
        width = 570,
        height = 390,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function CourseDataCodePage.InitData(url)
end
function CourseDataCodePage.OnCreate()
end

function CourseDataCodePage.FreshView()
end

function CourseDataCodePage.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    CourseDataCodePage.FreshView()
end

function CourseDataCodePage.CloseView()
    CourseDataCodePage.ClearData()
end

function CourseDataCodePage.ClearData()
end

function CourseDataCodePage.HandleData()
end