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
function LessonFinish.OnInit()
    page = document:GetPageCtrl();
end

function LessonFinish.ShowView(strTitle)
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
end

function LessonFinish.IsVisible()
    if page then
        return page:IsVisible()
    end
    return false
end

