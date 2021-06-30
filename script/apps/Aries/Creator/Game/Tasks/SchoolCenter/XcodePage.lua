--[[
Title: XcodePage
Author(s): yangguiyi
Date: 2021/6/2
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SchoolCenter/XcodePage.lua").Show();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local XcodePage = NPL.export();

local server_time = 0
local page

local TypeToImg = {
    ["lesson_progress"] = "Texture/Aries/Creator/keepwork/SchoolCenter/lesson_progress_32bits.jpg#0 0 128 128",
    ["work_progress"] = "Texture/Aries/Creator/keepwork/SchoolCenter/work_progress_32bits.jpg#0 0 128 128",
    ["teach_statistics"] = "Texture/Aries/Creator/keepwork/SchoolCenter/teach_statistics_32bits.jpg#0 0 128 128",
    ["personal_data_statistics"] = "Texture/Aries/Creator/keepwork/SchoolCenter/personal_data_statistics_32bits.jpg#0 0 128 128",
    ["3d_school_management"] = "Texture/Aries/Creator/keepwork/SchoolCenter/3d_school_management_32bits.jpg#0 0 128 128",
}

function XcodePage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = XcodePage.CloseView
end

function XcodePage.Show(type)
    XcodePage.type = type or "lesson_progress"
    XcodePage.ShowView()
end

function XcodePage.ShowView()
    if page and page:IsVisible() then
        return
    end
    XcodePage.HandleData()
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/SchoolCenter/XcodePage.html",
        name = "XcodePage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -452/2,
        y = -280/2,
        width = 452,
        height = 280,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function XcodePage.FreshView()
    local parent  = page:GetParentUIObject()
end

function XcodePage.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    XcodePage.FreshView()
end

function XcodePage.CloseView()
    XcodePage.ClearData()
end

function XcodePage.ClearData()
end

function XcodePage.HandleData()
end

function XcodePage.GetXcodeImg()
    local img = TypeToImg[XcodePage.type]
    return string.format("background:url(%s);", img)
end