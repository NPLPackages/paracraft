--[[
    auth: pbb
    desc: 
    date: 2025-11-4
    note: 
    uselib:
        local FriendActionTips = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/FriendActionTips.lua")
        FriendActionTips.ShowPage()
]]
local FriendActionManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/FriendActionManager.lua");
local FriendActionTips = NPL.export()


local countdownTimer = nil;
local page = nil;
FriendActionTips.actionDatas = {};

function FriendActionTips.OnInit()
    page = document:GetPageCtrl();
end

function FriendActionTips.IsVisible()
    return page and page:IsVisible()
end

function FriendActionTips.RefreshPage()
    if page then
        page:Refresh(0)
    end
end

function FriendActionTips.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function FriendActionTips.ShowPage(actionDatas)
    FriendActionTips.actionDatas = actionDatas or {};
    if FriendActionTips.IsVisible() then
        FriendActionTips.RefreshPage()
        return
    end
    local width, height = 1000, 64;
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/FriendActionTips.html",
        name = "FriendActionTips.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        directPosition = true,
        click_through = true,
        align = "_ct",
        x = -width/2,
        y = -(height + 200),
        width = width,
        height = height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    FriendActionTips.StartCountDown()
end

function FriendActionTips.StartCountDown()
    countdownTimer = countdownTimer or commonlib.Timer:new({callbackFunc = function(timer)

    end})
    countdownTimer:Change(1000, 1000)
end

function FriendActionTips.OnClickItem(index)
    local index = tonumber(index)
    if not index or index < 1 or index > #FriendActionTips.actionDatas then
        return
    end
    local actionData = FriendActionTips.actionDatas[index]
    if actionData then
        FriendActionManager.ResolveMsg(actionData)
    end
end
