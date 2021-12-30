--[[
author:yangguiyi
date:
Desc:
use lib:

local CodeLessonGoodView = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/CodeLessonTip/CodeLessonGoodView.lua") 
CodeLessonGoodView.ShowView(1,1)
]]

-- selection group index used to show the frame
local CodeLessonGoodView = NPL.export()
local CodeLessonTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/CodeLessonTip/CodeLessonTip.lua") 
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local page
function CodeLessonGoodView.OnInit()
    page = document:GetPageCtrl();
    page.OnCreate = CodeLessonGoodView.OnCreate
    page.OnClose = CodeLessonGoodView.OnClose
end

function CodeLessonGoodView.OnCreate()
    CodeLessonGoodView.RefreshSize()
end

function CodeLessonGoodView.OnClose()
    page = nil
end

-- cur_diff_index 当前看的是第几个难点 0 的话表示看完的是思路提示
function CodeLessonGoodView.ShowView(cur_diff_index, max_diff_index, next_cb, pass_cb)
    CodeLessonGoodView.cur_diff_index = cur_diff_index or 0
    CodeLessonGoodView.is_end_diff = cur_diff_index >= max_diff_index
    CodeLessonGoodView.next_cb = next_cb
    CodeLessonGoodView.pass_cb = pass_cb

    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/World2In1/CodeLessonTip/CodeLessonGoodView.html",
        name = "CodeLessonGoodView.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        click_through = true,
        enable_esc_key = false,
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

    if not CodeLessonGoodView.Bind then
        CodeLessonGoodView.Bind = true
        local viewport = ViewportManager:GetSceneViewport();
        viewport:Connect("sizeChanged", CodeLessonGoodView, CodeLessonGoodView.RefreshSize, "UniqueConnection");
    end

    GameLogic.GetEvents():AddEventListener("CodeBlockWindowShow", CodeLessonGoodView.RefreshSize, CodeLessonGoodView, "CodeLessonGoodView");
end

function CodeLessonGoodView.RefreshSize()
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

function CodeLessonGoodView.GetContent()
    if CodeLessonGoodView.cur_diff_index == 100 then
        return "你已完成“完整解答”, 开始通关吧！"
    end

    if CodeLessonGoodView.is_end_diff then
        return "你已完成“难点讲解”, 开始通关吧！"
    end

    local text1 = "思路提示"
    if CodeLessonGoodView.cur_diff_index > 0 then
        text1 = string.format("难点讲解%s", CodeLessonGoodView.cur_diff_index)
    end

    local text2 = string.format("难点讲解%s", CodeLessonGoodView.cur_diff_index + 1)

    return string.format("你已看完了“%s”，是否继续“%s”？", text1, text2)
end

function CodeLessonGoodView.ClickNext()
    if CodeLessonGoodView.next_cb then
        CodeLessonGoodView.next_cb()
    end
end

function CodeLessonGoodView.ClickPass()
    if CodeLessonGoodView.pass_cb then
        CodeLessonGoodView.pass_cb()
    end
end

function CodeLessonGoodView.CloseWindow()
    if page then
        page:CloseWindow()
    end
end