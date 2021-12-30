--[[
author:yangguiyi
date:
Desc:
use lib:

local CodeResultView = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/CodeLessonTip/CodeResultView.lua") 
CodeResultView.ShowView()
]]

-- selection group index used to show the frame
local CodeResultView = NPL.export()
local CodeLessonTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/CodeLessonTip/CodeLessonTip.lua") 
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local page
function CodeResultView.OnInit()
    page = document:GetPageCtrl();
    page.OnCreate = CodeResultView.OnCreate
    page.OnClose = CodeResultView.OnClose
end

function CodeResultView.OnCreate()
    CodeResultView.RefreshSize()
end

function CodeResultView.OnClose()
    page = nil
end

-- cur_diff_index 当前看的是第几个难点 0 的话表示看完的是思路提示
function CodeResultView.ShowView(is_success, content, left_bt_cb, right_bt_cb)
    CodeResultView.is_success = is_success
    CodeResultView.content = content
    CodeResultView.left_bt_cb = left_bt_cb
    CodeResultView.right_bt_cb = right_bt_cb
    CodeResultView.is_last_lesson = is_last_lesson

    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/World2In1/CodeLessonTip/CodeResultView.html",
        name = "CodeResultView.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        click_through = false,
        enable_esc_key = false,
        zorder = -1,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
        directPosition = true,
        align = "_fi",
            x = 0,
            y = 0,
            width = 0,
            height = 0,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    if not CodeResultView.Bind then
        CodeResultView.Bind = true
        local viewport = ViewportManager:GetSceneViewport();
        viewport:Connect("sizeChanged", CodeResultView, CodeResultView.RefreshSize, "UniqueConnection");
    end

    GameLogic.GetEvents():AddEventListener("CodeBlockWindowShow", CodeResultView.RefreshSize, CodeResultView, "CodeResultView");
end

function CodeResultView.RefreshSize()
    if not page or not page:IsVisible() then
        return
    end

    -- local bShow = event.bShow
    local viewport = ViewportManager:GetSceneViewport();
    local view_x,view_y,view_width,view_height = viewport:GetUIRect()
    local root = ParaUI.GetUIObject("CodeLessonGoodRoot");
    root.width = view_width
    root.height = view_height
end

function CodeResultView.GetContent()
    return CodeResultView.content
end

function CodeResultView.ClickLeftBt()
    if CodeResultView.left_bt_cb then
        CodeResultView.left_bt_cb()
    end
end

function CodeResultView.ClickRightBt()
    if CodeResultView.right_bt_cb then
        CodeResultView.right_bt_cb()
    end
end

function CodeResultView.CloseWindow()
    if page then
        page:CloseWindow()
    end
end

function CodeResultView.GetTitle()
    local title = CodeResultView.is_success and "太棒了！" or "失败"
    return title
end