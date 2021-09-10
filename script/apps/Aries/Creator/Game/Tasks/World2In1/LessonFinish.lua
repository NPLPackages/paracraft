--[[
    author:{pbb}
    time:2021-09-02 16:00:18
    use lib:
    local LessonFinish = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/LessonFinish.lua") 
    LessonFinish.ShowView()
]]
local LessonFinish = NPL.export()
LessonFinish.strTitle = ""
local page = nil
local close_timer
function LessonFinish.OnInit()
    page = document:GetPageCtrl();
end
local max_time = 6
function LessonFinish.ShowView(strTitle)
    max_time = 6
    LessonFinish.strTitle = strTitle or "第一课乐园大扫除"
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/World2In1/LessonFinish.html",
        name = "LessonFinish.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        zorder = 4,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
        directPosition = true,
        align = "_fi",
            x = 0,
            y = 0,
            width = 0,
            height = 0,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    LessonFinish.StartCloseTimer()
end

function LessonFinish.IsVisible()
    if page then
        return page:IsVisible()
    end
    return false
end

function LessonFinish.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
        close_timer:Change()
        close_timer = nil
    end
end

function LessonFinish.StartCloseTimer()
    close_timer = close_timer or commonlib.Timer:new({callbackFunc = function ()
        LessonFinish.UpdateCutDownUI()
        max_time = max_time - 1
        if max_time < 0 then
            LessonFinish.ClosePage()
            max_time = 6
        end
    end})
    close_timer:Change(0,1000)
end

function LessonFinish.UpdateCutDownUI()
    if LessonFinish.IsVisible() then
        page:SetValue("close_cutdown", ""..max_time);
    end
end

