--[[
    author:{pbb}
    time:2021-09-08 09:39:53
    Desc:
    use lib:
    local ActTeacher = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActTeacher/ActTeacher.lua") 
    ActTeacher.ShowView()
]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local ActTeacher = NPL.export()
local gsId = 20029
local exid = 40034
local page = nil
function ActTeacher.OnInit()
    page = document:GetPageCtrl();
end
--30048 
function ActTeacher.ShowView()
    local bOwn, guid, bag, copies, item = KeepWorkItemManager.HasGSItem(gsId)
    if bOwn and copies > 0 then
        ActTeacher.ShowPage()
    else
        local username = GameLogic.GetFilters():apply_filters('store_get', 'user/username');
        local activity_id = ActTeacher.GetActivityId()
        keepwork.quiz.registrate({
            name = username,
            activityId = activity_id
        },function (err, msg, data)
            if err == 200 then
                ActTeacher.ShowPage()
                KeepWorkItemManager.LoadItems(nil)
            else
                _guihelper.MessageBox(L"报名教师节活动失败，请联系客服解决");
            end
        end)
    end
end

function ActTeacher.ShowPage()
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/ActTeacher/ActTeacher.html",
        name = "ActTeacher.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        zorder = 0,
        -- app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
        directPosition = true,
        align = "_fi",
                x = 0,
                y = 0,
                width = 0,
                height = 0,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ActTeacher.GetSubmitWorldId()
    local httpwrapper_version = HttpWrapper.GetDevVersion();
    if httpwrapper_version == "ONLINE" then
        return 81489
    end
    return 20732
end

function ActTeacher.GetActivityId()
    local httpwrapper_version = HttpWrapper.GetDevVersion();
    if httpwrapper_version == "ONLINE" then
        return 36
    end
    return 27
end