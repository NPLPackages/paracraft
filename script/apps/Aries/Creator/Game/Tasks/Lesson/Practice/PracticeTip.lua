--[[
    author:{pbb}
    time:2022-04-26 16:10:13
    uselib：
        local PracticeTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Lesson/Practice/PracticeTip.lua")
        PracticeTip.ShowView({})
]]
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local PracticeTip = NPL.export()
PracticeTip.viewParams = nil
local page = nil
function PracticeTip.OnInit()
    page = document:GetPageCtrl();
end

function PracticeTip.ShowView(viewParams)
    PracticeTip.viewParams = viewParams
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Lesson/Practice/PracticeTip.html",
        name = "PracticeTip.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        zorder = -5,
        click_through = true,
        cancelShowAnimation = true,
        directPosition = true,
        align = "_fi",
        x = 0,
        y = 0,
        width = 0,
        height = 0,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    PracticeTip.RegisterEvent()
    PracticeTip.RefreshSize()
    GameLogic.GetFilters():apply_filters("update_dock",true);
    commonlib.TimerManager.SetTimeout(function ()
        PracticeTip.InitTeacherPlayer()
        PracticeTip.SetRoleName()
        PracticeTip.SetLessonContent()
        PracticeTip.SetLessonTitle()
    end, 100);
end

function PracticeTip.InitTeacherPlayer()
    if page and page:IsVisible() then
        local module_ctl = page:FindControl("teacher_practice")
        local scene = ParaScene.GetMiniSceneGraph(module_ctl.resourceName);
        if scene and scene:IsValid() then
            local player = scene:GetObject(module_ctl.obj_name);
            if player then
                player:SetScale(1)
                player:SetFacing(1.57);
                player:SetField("HeadUpdownAngle", 0);
                player:SetField("HeadTurningAngle", 0);
                local file = "character/CC/02human/keepwork/avatar/kk.x"
                if PracticeTip.viewParams and PracticeTip.viewParams.teacher_key then
                    if PracticeTip.viewParams.teacher_key == "papa" then
                        file = "character/CC/02human/keepwork/avatar/pp.x"
                    end
                    if PracticeTip.viewParams.teacher_key == "lala" then
                        file = "character/CC/02human/keepwork/avatar/lala.x"
                    end
                end
                player:SetField("assetfile",file)
            end
        end
    end
end

function PracticeTip.RegisterEvent()
    if not PracticeTip.register then
        local viewport = ViewportManager:GetSceneViewport();
        viewport:Connect("sizeChanged", PracticeTip, PracticeTip.RefreshSize, "UniqueConnection");
        GameLogic:Connect("WorldUnloaded", PracticeTip, PracticeTip.OnWorldUnload, "UniqueConnection");
        PracticeTip.register = true
    end
end

function PracticeTip.SetRoleName()
     local name = "帕帕"
     if PracticeTip.viewParams and PracticeTip.viewParams.teacher_name then
         name = PracticeTip.viewParams.teacher_name
     end
     if page then
        local strTip = name
        page:SetValue("practice_name", strTip);
        
    end
end

function PracticeTip.SetLessonContent()
    local content = L"请根据演示的样例，在右侧实现相同的效果。"
    if page then
        local strTip = content
        page:SetValue("practice_tip", strTip);
        
    end
end

function PracticeTip.SetLessonTitle()
    local lessontitle = "课程1-练习1"
    if PracticeTip.viewParams and PracticeTip.viewParams.practice_title then
        lessontitle = PracticeTip.viewParams.practice_title
    end
    if page then
        local strTip = lessontitle
        page:SetValue("lesson_title", strTip);
    end
end

function PracticeTip.OnWorldUnload()
    PracticeTip.viewParams = nil
end

function PracticeTip.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
    GameLogic.GetFilters():apply_filters("update_dock",false);
    GameLogic.GetCodeGlobal():BroadcastTextEvent("onExitPractice")
end

function PracticeTip.RefreshSize()
    local pageRoot = ParaUI.GetUIObject("practice_root")
    if pageRoot and pageRoot:IsValid() then
        local viewport = ViewportManager:GetSceneViewport();
        local view_x,view_y,view_width,view_height = viewport:GetUIRect()
        pageRoot:Reposition("_lt", 0, 0, view_width, 130);
    end
end

function PracticeTip.RestartScene()
    if PracticeTip.viewParams then
        local func = function ()
            local platform = PracticeTip.viewParams.platform
            local template = PracticeTip.viewParams.practice_template
            local template_pos = PracticeTip.viewParams.practice_template_pos
            if platform then
                local cx,cy,cz,radius = unpack(PracticeTip.viewParams.platform)
                local maxHeight = 10
                local size = radius*2; 
                GameLogic.RunCommand(string.format("/select %d %d %d (%d %d %d)", cx-radius, cy+1, cz-radius, size, maxHeight, size))
                GameLogic.RunCommand("/del")
                GameLogic.RunCommand("/select -clear") 
            end
            commonlib.TimerManager.SetTimeout(function ()
                if template and template_pos then
                    GameLogic.RunCommand(string.format("/loadtemplate %d,%d,%d %s",template_pos[1],template_pos[2] + 1,template_pos[3],template))
                end
            end, 200);
        end
        local strTip = "是否需要复原整个练习场景"
        local temp = "script/apps/Aries/Creator/Game/GUI/DefaultMessageBox.lesson.html"
        local buttons = _guihelper.MessageBoxButtons.OKCancel
        _guihelper.MessageBox(strTip,function ()
            func()
            GameLogic.GetCodeGlobal():BroadcastTextEvent("resetWorkScene")
        end,buttons,nil,temp)
    end
end

function PracticeTip.ReplayMacro()
    local strTip = "是否重新跟着老师学一遍"
    local temp = "script/apps/Aries/Creator/Game/GUI/DefaultMessageBox.lesson.html"
    local buttons = _guihelper.MessageBoxButtons.OKCancel
    _guihelper.MessageBox(strTip,function ()
        PracticeTip.ClosePage()
        GameLogic.GetCodeGlobal():BroadcastTextEvent("playWorkMacro")
    end,buttons,nil,temp)
end

function PracticeTip.StartCheck()
    if PracticeTip.viewParams then

        GameLogic.GetCodeGlobal():BroadcastTextEvent("startCheck")
    end
end
