--[[
    auth: pbb
    desc: 确认进入存档点
    date: 2025-10-14
    note: 确认进入存档点，确认后会倒计时 3秒后加载存档点或者打开存档点页面
    uselib:
        local EnterConfirm = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EnterConfirm.lua")
        EnterConfirm.ShowPage(entity)
]]
local EasyCheckPoint = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyCheckPoint.lua");
local EnterConfirm = NPL.export()

EnterConfirm.countdownSecondsDefault = 3;

-- 倒计时相关变量
local countdownTimer = nil;
local countdownSeconds;
local currentPage = nil;
local currentEntity = nil;
local currentSubtag = nil;

function EnterConfirm.OnInit()
    currentPage = document:GetPageCtrl();
end

function EnterConfirm.ShowPage(subtag, entity, isEnterWorldPoint)
    if not entity or not subtag then
        return
    end
    if isEnterWorldPoint then
        EasyCheckPoint.ShowPage(subtag, entity)
        return
    end
    currentEntity = entity;
    currentSubtag = subtag;
    
    local width, height = 512, 128;
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EnterConfirm.html",
        name = "EnterConfirm.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        directPosition = true,
        click_through = true,
        align = "_ctt",
        x = 0,
        y = 200,
        width = width,
        height = height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    
    EnterConfirm.StartCountDown()
end

function EnterConfirm.StartCountDown()
    countdownSeconds = EnterConfirm.countdownSecondsDefault;
    EnterConfirm.UpdateCountdownDisplay();
    countdownTimer = countdownTimer or commonlib.Timer:new({callbackFunc = function(timer)
        countdownSeconds = countdownSeconds - 1;
        if countdownSeconds > 0 then
            EnterConfirm.UpdateCountdownDisplay();
        else
            EnterConfirm.OnConfirmEnter();
        end
    end})
    countdownTimer:Change(1000, 1000)
end

function EnterConfirm.UpdateCountdownDisplay()
    if currentPage then
        currentPage:SetValue("lblCountdown", string.format(L"%d秒后自动打开存档点", countdownSeconds));
    end
end

function EnterConfirm.OnConfirmEnter()
    if countdownTimer then
        countdownTimer:Change();
        countdownTimer = nil;
    end
    
    EnterConfirm.OnClose();
      
    if currentSubtag and currentEntity then
        EasyCheckPoint.ShowPage(currentSubtag, currentEntity)
    end
end

function EnterConfirm.OnCancel()
    EnterConfirm.OnClose();
end

function EnterConfirm.OnClose()
    if countdownTimer then
        countdownTimer:Change();
        countdownTimer = nil;
    end
    if currentPage then
        currentPage:CloseWindow();
        currentPage = nil;
    end
end
