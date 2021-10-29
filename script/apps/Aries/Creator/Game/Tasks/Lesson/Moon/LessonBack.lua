--[[
    author:{pbb}
    time:2021-09-23 18:48:23
    local LessonBack = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Lesson/Moon/LessonBack.lua") 
    LessonBack.ShowView()
]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local LessonBack = NPL.export()
local page = nil
local key_gsid = 90009  --钥匙
local key_exid = 30041
function LessonBack.OnInit()
    page = document:GetPageCtrl();
end
function LessonBack.ShowView()
    local view_width = 560
    local view_height = 420
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Lesson/Moon/LessonBack.html",
        name = "LessonBack.ShowView", 
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

function  LessonBack.IsEnough()
    local bOwn, guid, bag, copies, item = KeepWorkItemManager.HasGSItem(key_gsid)
    if bOwn and copies >= 8 then
        return true
    end
    return false
end

function LessonBack.GetItemNum()
    local bOwn, guid, bag, copies, item = KeepWorkItemManager.HasGSItem(key_gsid)
    if bOwn and copies >= 0 then
        return copies
    end
    return 0
end

function LessonBack.OnClick()
    if LessonBack.IsEnough() then
        GameLogic.RunCommand("/loadworld back")
    end
end