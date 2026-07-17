--[[
Title: EasyPhone
Author(s): LiXizhi
Date: 2025/10/20
Desc: useful social and utility functions in mobile phone interface 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyPhone.lua");
local EasyPhone = commonlib.gettable("MyCompany.Aries.Creator.Game.Tasks.EasyBuilder.EasyPhone");
EasyPhone.ShowPage();
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local MiniGameMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMainPage.lua");
local EasyPhone = commonlib.gettable("MyCompany.Aries.Creator.Game.Tasks.EasyBuilder.EasyPhone");

local page;

local phoneButtons = {
    {name="camera", text=L"相机", icon="Texture/3DMapSystem/AppIcons/VideoRecorder_64.dds", color="#667EEA", tooltip=""},
    {name="personalAbility", text=L"个人能力", icon="Texture/Aries/Dock/MyMount_32bits.png", color="#4ECDC4", tooltip=""},
    {name="myFriends", text=L"我的好友", icon="Texture/3DMapSystem/AppIcons/People_64.dds", color="#26C6DA", tooltip=L"有新消息"},
    {name="clothingStore", text=L"换装商城", icon="Texture/3DMapSystem/CCS/btn_CCS_Inventory_Icon.png", color="#764ba2", tooltip=""},
    {name="creationManual", text=L"成长手册", icon="Texture/3DMapSystem/AppIcons/Intro_64.dds", color="#A8E6CF", tooltip="", textColor="#333333"},
    {name="memberRecharge", text=L"会员充值", icon="Texture/Aries/Creator/keepwork/AiCourse/VIP_48X53_32bits.png#0 0 48 53", color="#FFA726", tooltip=""},
    {name="playBook", text=L"玩学魔法书", icon="Texture/3DMapSystem/AppIcons/Book_64.dds", color="#3bb36dff", tooltip=""},
    --{name="worldBackup", text=L"世界云存档", icon="Texture/3DMapSystem/AppIcons/NewWorld_64.dds", color="#66BB6A", tooltip=""},
    {name="dinosaurTransform", text=L"抱抱龙变身", icon="Texture/Aries/Item/10001_DragonIcon.png", color="#42A5F5", tooltip=""},
    {name="systemMail", text=L"系统邮件", icon="Texture/Aries/Dock/Web/Mail_32bits.png#0 0 51 45", color="#95A5A6", tooltip=L"有新邮件"},
    {name="settings", text=L"设置", icon="Texture/3DMapSystem/AppIcons/Settings_64.dds", color="#BDBDBD", tooltip="", textColor="#333333"},
    -- {name="logs", text=L"日志/ggs公告", icon="Texture/Aries/Dock/Web/Feed_32bits.png# 0 0 48 43", color="#BDBDBD", tooltip="", textColor="#333333"},
    -- {name="myAlbum", text=L"我的相册", icon="Texture/3DMapSystem/AppIcons/assets_64.dds", color="#26C6DA", tooltip=""},
};
local usedPhoneButtons = commonlib.deepcopy(phoneButtons)

-- 初始化页面
function EasyPhone.InitPage(Page)
    page = Page;
    EasyPhone.RefreshPage();
end

-- 显示页面
function EasyPhone.ShowPage()
    local width, height = 480, 640
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyPhone.html",
        name = "EasyPhone.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide = false, 
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        bShow = true,
        click_through = false, 
        zorder = 1000,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
            align = "_rt",
            x = -width - 20,
            y = 90,
            width = width,
            height = height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    EasyPhone.UpdateByFriendApply()
end

-- 刷新页面
function EasyPhone.RefreshPage()
    if(page) then
        page:Refresh(0.01);
    end
end

-- 获取当前日期时间
function EasyPhone.GetCurrentDateTime()
    local date = os.date("*t");
    local weekdays = {
        [1] = L"星期日",
        [2] = L"星期一", 
        [3] = L"星期二",
        [4] = L"星期三",
        [5] = L"星期四",
        [6] = L"星期五",
        [7] = L"星期六",
    };
    
    local hour = date.hour;
    local ampm = "AM";
    if hour >= 12 then
        ampm = "PM";
        if hour > 12 then
            hour = hour - 12;
        end
    end
    if hour == 0 then
        hour = 12;
    end
    
    return string.format("%d/%02d/%02d %s %d:%02d%s", 
        date.year, date.month, date.day, 
        weekdays[date.wday] or "",
        hour, date.min, ampm);
end

-- 关闭按钮
function EasyPhone.OnClose()
    if(page) then
        page:CloseWindow();
    end
end

-- 通用按钮点击事件处理
function EasyPhone.OnClickButton(buttonName)
    local handlers = {
        personalAbility = function() 
            MiniGameMainPage.OnClickProfile()
        end,
        myFriends = function() 
            MiniGameMainPage.OnClickFriends()
        end,
        clothingStore = function() 
            MiniGameMainPage.ShowUserInfo("skin")
        end,
        creationManual = function() 
            MiniGameMainPage.OnClickCreateManual()
        end,
        memberRecharge = function() 
            MiniGameMainPage.StartWebGame("game_activities",{type="vip"}, true)
        end,
        worldBackup = function()
            MiniGameMainPage.OnClickCloud()
        end,
        playBook = function()
            MiniGameMainPage.OnClickPlayBook()
        end,
        dinosaurTransform = function()
            MiniGameMainPage.OnClickPetTransform()
        end,
        settings = function() 
            NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/SystemSettingsPage.lua");
            local SystemSettingsPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.SystemSettingsPage");
            SystemSettingsPage.ShowPage()
        end,
        camera = function()
            MiniGameMainPage.OnClickCamera()
        end,
        systemMail = function() 
            local Email = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Email/Email.lua");
            Email.Show()
        end,
        -- leaveWorld = function() _guihelper.MessageBox(L"确定要离开世界吗？") end,
        -- logs = function() _guihelper.MessageBox(L"日志/ggs公告功能") end,
        --myAlbum = function() _guihelper.MessageBox(L"我的相册功能") end,
    };
    
    local handler = handlers[buttonName];
    if handler then
        handler();
        EasyPhone.OnClose()
    end
end

function EasyPhone.GetPhoneButtons()
    return usedPhoneButtons
end

function EasyPhone.UpdateByFriendApply()
    local FriendManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendManager.lua")
    FriendManager:LoadAllUnReadMsgs(function()
        local isShowFriendRedTip = (FriendManager.unread_msgs_num > 0 or (FriendManager.friend_apply and FriendManager.friend_apply.is_friend_apply))
        usedPhoneButtons = commonlib.deepcopy(phoneButtons)
        for _, button in ipairs(usedPhoneButtons) do
            if button.name == "myFriends" then
                button.is_show_red_point = isShowFriendRedTip
            end
        end
        echo(usedPhoneButtons,true)
        EasyPhone.RefreshPage()
    end, true)
end
