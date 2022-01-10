--[[
author:yangguiyi
date:
Desc:
use lib:

local CodeLessonTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/CodeLessonTip/CodeLessonTip.lua") 
CodeLessonTip.ShowView()
]]

-- selection group index used to show the frame
local groupindex_hint_auto = 6;
local groupindex_wrong = 3;
local groupindex_hint = 5; -- when placeable but not matching hand block

local target_desc_list = {
    [1] = "教会用户如何放置代码方块，如何打开代码方块，以及如何使用【前进】【说话】代码块",
    [2] = "教会用户如何配合使用【前进】和【位移】来躲避陷阱。",
    [3] = "教会用户如何配合使用【前进】和【转向】避开陷阱，并且正确使用【说话】",
    [4] = "教会用户如何直接转到需要的角度，并说话",
    [5] = "教会用户使用做动作",
    [6] = "教会用户使用【如果】与【是否碰到方块】代码块来确定是否应该【转向】",
    [7] = "教会用户使用多个【如果】与【是否碰到方块】代码块来确定是否应该【转向",
    [8] = "教会用户使用【如果-否则】与【是否碰到方块】代码块来确定往哪个方向【转向】",
    [9] = "教会用户使用for循环来向前移动并转向",
    [10] = "教会用户使用for循环来向前移动并转向，并且每次循环使用【if-end】来判断是否应该转向",
}

local CodeLessonTip = NPL.export()

local CodeDifficultView = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/CodeLessonTip/CodeDifficultView.lua") 
local CodeResultView = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/CodeLessonTip/CodeResultView.lua") 
local CodeLessonGoodView = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/CodeLessonTip/CodeLessonGoodView.lua") 

NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");

local page
function CodeLessonTip.OnInit()
    page = document:GetPageCtrl();
    page.OnCreate = CodeLessonTip.OnCreate
    page.OnClose = CodeLessonTip.OnClose
end

function CodeLessonTip.OnCreate()
    CodeLessonTip.RefreshSize()
    CodeLessonTip.RefreshNodeVisible()

    local node = page:FindControl("bottom_node")
    local bg_node = page:FindControl("bottom_node_bg")
    if node and node:IsValid() then
        node.width = bg_node.width
    end

end

function CodeLessonTip.OnClose()
    GameLogic.GetEvents():RemoveEventListener("CodeBlockWindowShow", CodeLessonTip.CodeWinChangeVisible, CodeLessonTip);
end

--lesson_config 课程配置
--lesson_index 第几节课
function CodeLessonTip.ShowView(lesson_config, lesson_index)
    if not lesson_config or not lesson_index then
        return
    end
    CodeLessonTip.lesson_config = lesson_config
    CodeLessonTip.lesson_index = lesson_index
    CodeLessonTip.IsShowCodeWin = CodeLessonTip.IsEditorOpen()

    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/World2In1/CodeLessonTip/CodeLessonTip.html",
        name = "CodeLessonTip.ShowView", 
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
    -- if System.options.isDevMode then
    --     if CodeLessonTip.window then
    --         CodeLessonTip.window:destroy()
    --         CodeLessonTip.window = nil
    --     end
    -- end

	-- if(not CodeLessonTip.WindowNodeLT) then
	-- 	CodeLessonTip.WindowNodeLT = CodeLessonTip.CreateWindow();
	-- end
	-- CodeLessonTip.WindowNodeLT:Show({
	-- 	name="CodeLessonTip.ShowView", 
	-- 	url="script/apps/Aries/Creator/Game/Tasks/World2In1/CodeLessonTip/CodeLessonTipLT.html",
    --     enable_esc_key = true,
	-- 	alignment="_lt", left=0, top=0, width = 600, height = 500, zorder = 0,
	-- });
    if not CodeLessonTip.Bind then
        CodeLessonTip.Bind = true
        local viewport = ViewportManager:GetSceneViewport();
        viewport:Connect("sizeChanged", CodeLessonTip, CodeLessonTip.RefreshSize, "UniqueConnection");
    end

    CodeLessonTip.defaul_dist = GameLogic.options:GetCameraObjectDistance();
	CodeLessonTip.defaul_pitch = ParaCamera.GetAttributeObject():GetField("CameraLiftupAngle");
	CodeLessonTip.defaul_facing = ParaCamera.GetAttributeObject():GetField("CameraRotY");

    GameLogic.GetEvents():AddEventListener("CodeBlockWindowShow", CodeLessonTip.CodeWinChangeVisible, CodeLessonTip, "CodeLessonTip");

    CodeLessonTip.ShowVisible(true)
    
end

function CodeLessonTip.CodeWinChangeVisible(event)
    CodeLessonTip.IsShowCodeWin = CodeLessonTip.IsEditorOpen()
    CodeLessonTip.RefreshSize()
    CodeLessonTip.RefreshNodeVisible()
end

function CodeLessonTip.RefreshNodeVisible()
    if not page then
        return
    end

    local node = page:FindControl("bt_return")
    if node and node:IsValid() then
        node.visible = not CodeLessonTip.IsShowCodeWin
    end
    
    node = page:FindControl("bottom_node")
    if node and node:IsValid() then
        node.visible = CodeLessonTip.IsShowCodeWin == true
    end
end

function CodeLessonTip.RefreshSize()
    if not page or not page:IsVisible() then
        return
    end

    -- local bShow = event.bShow
    local viewport = ViewportManager:GetSceneViewport();
    local view_x,view_y,view_width,view_height = viewport:GetUIRect()
    local root = ParaUI.GetUIObject("CodeLessonTipRoot");
    root.width = view_width
    root.height = view_height
end

function CodeLessonTip.GetTargetDesc()
    return target_desc_list[CodeLessonTip.lesson_index] or ""
end

function CodeLessonTip.ClickTargetIntroduce()
    GameLogic.GetCodeGlobal():BroadcastTextEvent("playCodeTargetMovice");
end

function CodeLessonTip.ClickRefresh()
    GameLogic.options:SetCameraObjectDistance(CodeLessonTip.defaul_dist)
    local att = ParaCamera.GetAttributeObject();
    att:SetField("CameraLiftupAngle", CodeLessonTip.defaul_pitch);
    att:SetField("CameraRotY", CodeLessonTip.defaul_facing);
end

function CodeLessonTip.ClickAdd()
    local dist = GameLogic.options:GetCameraObjectDistance();
    GameLogic.options:SetCameraObjectDistance(dist - 1)
end

function CodeLessonTip.ClickSub()
    local dist = GameLogic.options:GetCameraObjectDistance();
    GameLogic.options:SetCameraObjectDistance(dist + 1)
end

-- 点击退出
function CodeLessonTip.ClickExit()
    if page then
        page:CloseWindow();
    end
    CodeLessonTip.CloseCodeGoodView()
    CodeLessonTip.CloseCodeDiffView()

    GameLogic.GetCodeGlobal():BroadcastTextEvent("clickCodeExit");
end

-- 点击返回
function CodeLessonTip.ClickReturn()
    GameLogic.GetCodeGlobal():BroadcastTextEvent("clickCodeReturn");
end

-- 点击思路提示
function CodeLessonTip.ClickSolutionTip()
    CodeLessonTip.cur_diff_index = 0
    CodeLessonTip.ShowVisible(false)
    GameLogic.GetCodeGlobal():BroadcastTextEvent("clickSimPass");
end

-- 点击难点讲解
function CodeLessonTip.ClickDifficult(index)
    CodeLessonTip.ShowCodeDiffView(tonumber(index))
end

-- 点击完整解答
function CodeLessonTip.ClickAnswer()
    CodeLessonTip.ShowCodeAnswerView()
end

-- 代码编辑器是否打开
function CodeLessonTip.IsEditorOpen()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
	local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
    return CodeBlockWindow.IsVisible();
end

-- 获取难点讲解数据
function CodeLessonTip.GetButtonData()
    local difficultyExplain = CodeLessonTip.lesson_config.difficultyExplain    
    return difficultyExplain or {}
end

-- 打开“太棒了”界面 代码方块中调用
function CodeLessonTip.ShowCodeGoodView()
    if not CodeLessonTip.cur_diff_index then
        return
    end
    local cur_diff_index = CodeLessonTip.cur_diff_index
    CodeLessonTip.cur_diff_index = nil
    local next_cb = function()
        CodeLessonTip.CloseCodeGoodView()
        CodeLessonTip.ShowVisible(true)
        CodeLessonTip.ShowCodeDiffView(cur_diff_index + 1)
    end

    local pass_cb = function()
        CodeLessonTip.CloseCodeGoodView()
        GameLogic.GetCodeGlobal():BroadcastTextEvent("lessonNormalStart");
        CodeLessonTip.ShowVisible(true)
    end

    CodeLessonGoodView.ShowView(cur_diff_index, #CodeLessonTip.lesson_config.difficultyExplain, next_cb, pass_cb)
end

-- 关闭“太棒了”界面
function CodeLessonTip.CloseCodeGoodView()
    CodeLessonGoodView.CloseWindow()
end

-- 打开“难点讲解”确定界面
function CodeLessonTip.ShowCodeDiffView(index)
    CodeLessonTip.cur_diff_index = tonumber(index)
    
    local knowledge_config = CodeLessonTip.lesson_config.knowledge_config
    local knowledge = knowledge_config.knowledge
    local config = knowledge[CodeLessonTip.cur_diff_index] or {}
    local content = config.content
    content = string.format("是否开始讲解难点“%s”", content)

    CodeDifficultView.ShowView(content,function()
        GameLogic.GetCodeGlobal():BroadcastTextEvent("clickDifficult", {diff_index=tonumber(CodeLessonTip.cur_diff_index)});
        CodeLessonTip.ShowVisible(false)
    end, root)
end

-- 关闭“难点讲解”or"完整解答"确定界面
function CodeLessonTip.CloseCodeDiffView()
    CodeDifficultView.CloseWindow()
end

-- 打开“难点讲解”确定界面
function CodeLessonTip.ShowCodeAnswerView()
    CodeLessonTip.cur_diff_index = 100
    local content = "是否开始本课的手把手教学"

    
    CodeDifficultView.ShowView(content,function()
        GameLogic.GetCodeGlobal():BroadcastTextEvent("clickDetailAnswer");
        CodeLessonTip.ShowVisible(false)
    end, true)
end

-- 通关成功or失败界面
-- 打开“难点讲解”确定界面
function CodeLessonTip.ShowResultView(is_success)
    local content = "你没通关成功，请再接再厉！"
    if is_success then
        content = string.format("你已完成了第%s课(%s)", commonlib.NumberToString(CodeLessonTip.lesson_index), CodeLessonTip.lesson_config.lesson_name)
    end

    local left_bt_cb = function()
        --CodeLessonTip.ClickExit()
        CodeResultView.CloseWindow()
        
        --GameLogic.GetCodeGlobal():BroadcastTextEvent("startCodeLesson",{lesson_index = start_index});
        if is_success then
            if page then
                page:CloseWindow();
            end

            GameLogic.GetCodeGlobal():BroadcastTextEvent("startCodeLesson",{lesson_index = CodeLessonTip.lesson_index + 1});
        else
            GameLogic.GetCodeGlobal():BroadcastTextEvent("lessonNormalStart");
        end
    end

    local right_bt_cb = function()
        CodeLessonTip.ClickExit()
        CodeResultView.CloseWindow()
    end

    local is_last_lesson = CodeLessonTip.lesson_config.is_last_lesson
    CodeResultView.ShowView(is_success, content, left_bt_cb, right_bt_cb, is_last_lesson)

    if is_success then
        GameLogic.QuestAction.SetDongaoLessonState("code", CodeLessonTip.lesson_index, true)
        GameLogic.GetCodeGlobal():BroadcastTextEvent("refreshCodeNpcSay");
    end
end


-- 显示or隐藏
function CodeLessonTip.ShowVisible(visible)
    if not page then
        return
    end

    local parent = page:GetParentUIObject()
    if parent then
        parent.visible = visible
        CodeLessonTip.RefreshSize()
    end
end