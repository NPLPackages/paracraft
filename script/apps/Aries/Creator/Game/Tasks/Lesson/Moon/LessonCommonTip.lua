--[[
    author:{pbb}
    time:2021-09-23 18:48:23
    local LessonCommonTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Lesson/Moon/LessonCommonTip.lua") 
    LessonCommonTip.ShowView()
]]
local LessonCommonTip = NPL.export()
LessonCommonTip.showStr = ""
local page = nil
function LessonCommonTip.OnInit()
    page = document:GetPageCtrl();
end
LessonCommonTip.nType = -1
function LessonCommonTip.ShowView(type)
    LessonCommonTip.nType = type or 1
    local view_width = 470
    local view_height = 350
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Lesson/Moon/LessonCommonTip.html",
        name = "LessonCommonTip.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 4,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
        directPosition = true,
        align = "_ct",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function  LessonCommonTip.GetDesc()
    if LessonCommonTip.nType == 0 then
        return "你将使用一个令牌，进行爬塔答题"
    end
    return "你还没有令牌哦，请先去学习一章课程获取令牌后，再来挑战吧"
end

function LessonCommonTip.OnClick()
    if page then
        page:CloseWindow()
        page = nil
    end
end