--[[
author:yangguiyi
date:
Desc:
use lib:

local CodeDifficultView = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/CodeLessonTip/CodeDifficultView.lua") 
CodeDifficultView.ShowView()
]]

-- selection group index used to show the frame
local CodeDifficultView = NPL.export()
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");

local page
function CodeDifficultView.OnInit()
    page = document:GetPageCtrl();
    page.OnCreate = CodeDifficultView.OnCreate
    page.OnClose = CodeDifficultView.OnClose
end

function CodeDifficultView.OnCreate()
    CodeDifficultView.RefreshSize()
end

function CodeDifficultView.OnClose()
end

function CodeDifficultView.ShowView(show_content, ok_cb, is_detail_answer)
    CodeDifficultView.show_content = show_content
    CodeDifficultView.ok_cb = ok_cb
    CodeDifficultView.is_detail_answer = is_detail_answer
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/World2In1/CodeLessonTip/CodeDifficultView.html",
        name = "CodeDifficultView.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        click_through = true,
        enable_esc_key = true,
        zorder = -13,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
        directPosition = true,
        align = "_fi",
            x = 0,
            y = 0,
            width = 0,
            height = 0,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    if not CodeDifficultView.Bind then
        CodeDifficultView.Bind = true
        local viewport = ViewportManager:GetSceneViewport();
        viewport:Connect("sizeChanged", CodeDifficultView, CodeDifficultView.RefreshSize, "UniqueConnection");
    end

    GameLogic.GetEvents():AddEventListener("CodeBlockWindowShow", CodeDifficultView.RefreshSize, CodeDifficultView, "CodeDifficultView");
end

function CodeDifficultView.GetContent()
    return CodeDifficultView.show_content
end

function CodeDifficultView.ClickCancel()
    CodeDifficultView.CloseWindow()
end

function CodeDifficultView.ClickOk()
    if CodeDifficultView.ok_cb then
        CodeDifficultView.CloseWindow()
        CodeDifficultView.ok_cb()
    end
end

function CodeDifficultView.RefreshSize()
    if not page or not page:IsVisible() then
        return
    end

    -- local bShow = event.bShow
    local viewport = ViewportManager:GetSceneViewport();
    local view_x,view_y,view_width,view_height = viewport:GetUIRect()
    local root = ParaUI.GetUIObject("CodeLessonDiffRoot");
    root.width = view_width
    root.height = view_height
end

function CodeDifficultView.CloseWindow()
    if page then
        page:CloseWindow()
    end
end