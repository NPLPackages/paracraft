--[[
Title: NotItemPage
Author(s): yangguiyi
Date: 2021/6/18
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/NotItemPage.lua").Show();
--]]
local NotItemPage = NPL.export();
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
local World2In1 = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local page
function NotItemPage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = NotItemPage.CloseView
end

function NotItemPage.CloseView()
    NotItemPage.WorldListData = nil
end

function NotItemPage.Show()
    NotItemPage.ShowView()
end

function NotItemPage.ShowView()
    if page and page:IsVisible() then
        return
    end
    NotItemPage.HandleData()
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/World2In1/NotItemPage.html",
        name = "NotItemPage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -644/2,
        y = -413/2,
        width = 644,
        height = 413,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function NotItemPage.HandleData()
    -- body
end

function NotItemPage.GetDesc1()
    local world_name = WorldCommon.GetWorldTag("name")
    
    return string.format("请选择你要入驻至《%s》课程世界的迷你地块", world_name)
end

function NotItemPage.OnClickCreate()
    if page then
        page:CloseWindow()
    end
    local world_id = WorldCommon.GetWorldTag("kpProjectId");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/CreateModulPage.lua").Show(nil, world_id);
end