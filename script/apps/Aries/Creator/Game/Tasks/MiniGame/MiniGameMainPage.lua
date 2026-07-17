--[[
Title: MiniGame Main Page
Author(s): ParaCraft Team
Date: 2024/3/21
Desc: 小游戏主界面，用于展示相互入口ui
Use Lib:
-------------------------------------------------------
local MiniGameMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMainPage.lua");
MiniGameMainPage.ShowPage();
-------------------------------------------------------
]]
local TimeLimitPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/TimeLimitPage.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/VirtualBagManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditableWorld.lua");
local EasyHomeBuilder = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyHomeBuilder.lua")
local EasyEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld");
local VirtualBagManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.VirtualBagManager")
local MiniGameMainPage = NPL.export()
MiniGameMainPage.IsMusicPlay = true
MiniGameMainPage.UIMode = "Task" --default Task 任务模式 Story 故事模式

-- 页面实例
local page;
function MiniGameMainPage:OnInit()
    page = document:GetPageCtrl();
    page.OnCreate = MiniGameMainPage.OnCreate
end

function MiniGameMainPage.OnCreate()
    MiniGameMainPage.UpdateUIByGameMode()
    MiniGameMainPage.UpdateEditInfo()
    MiniGameMainPage.UpdateTimeLimit()
end

function MiniGameMainPage.ShowPage()
    MiniGameMainPage.HideDock()
    MiniGameMainPage.InitPageMode()
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMainPage.html",
        name = "MiniGameMainPage",
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        zorder = -4,
        click_through=true,
        directPosition = true,
        cancelShowAnimation = true,
        align = "_fi",
        x = 0,
        y = 0,
        width = 0,
        height = 0,
        DesignResolutionWidth = 1280,
        DesignResolutionHeight = 720,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    commonlib.TimerManager.SetTimeout(function()
        GameLogic.RunCommand("/sendevent hide_task_btn_wnd")
        MiniGameMainPage.RequestHideUI(false)
    end, 500)

    if not MiniGameMainPage.RegisterEvent then
        MiniGameMainPage.RegisterEvent = true
        GameLogic.GetFilters():add_filter("UpdateEmailList", MiniGameMainPage.UpdateEmailRedTip);
        GameLogic.GetFilters():add_filter("friend_chat_msg", MiniGameMainPage.UpdateFriendRedTip);
        GameLogic.GetFilters():add_filter("update_friend_unread_num", MiniGameMainPage.UpdateFriendRedTipNum);
        GameLogic.GetFilters():add_filter("EasyEditableWorldSlotFilenameChanged", MiniGameMainPage.WorldSlotChanged);
        GameLogic.GetFilters():add_filter("EasyEditableWorldStatusChanged", MiniGameMainPage.WorldStatusChanged);
        GameLogic.GetFilters():add_filter("requestHideUI", MiniGameMainPage.RequestHideUI);
        local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
        KeepWorkItemManager.GetFilter():add_filter("LoadItems_Finished", MiniGameMainPage.UpdateItems);
    end
    MiniGameMainPage.UpdateFriendRedTip(nil, false);
end

function MiniGameMainPage.RequestHideUI(bHide)
    if not page then
        return
    end
    local parent = page:GetParentUIObject()
    if not parent or not parent:IsValid() then
        return bHide
    end
    local isShowTaskUI = MiniGameMainPage.UIMode == "Task"
    MiniGameMainPage.hideGameUI = bHide
    parent.visible = not bHide
    local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
    QuickSelectBar.ShowPage(not bHide)
    if bHide then
        QuickSelectBar.ShowPage(false)
        MiniGameMainPage.ShowCustomGameUI(false)
    else

        QuickSelectBar.ShowPage(not isShowTaskUI)
        MiniGameMainPage.ShowCustomGameUI(isShowTaskUI)
    end
    return bHide
end

function MiniGameMainPage.HideDock()
    MiniGameMainPage.gameUI = nil
    GameLogic.MiniGameMgr:RefreshGameDock()
end

function MiniGameMainPage.InitPageMode()
    MiniGameMainPage.currentWorldFilename = nil
    MiniGameMainPage.currentWorldDisplayName = nil
    MiniGameMainPage.UIMode = "Task"
    MiniGameMainPage.hideGameUI = false
    MiniGameMainPage.SetTaskMode()
    MiniGameMainPage.RefreshPage()
end

function MiniGameMainPage.UpdateItems()
    MiniGameMainPage.RefreshPage()
end

function MiniGameMainPage.ClosePage()
    if(page) then
        page:CloseWindow()
        page = nil
    end
end

function MiniGameMainPage.OnClickProfile()
    local MiniGameUserProfile = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameUserProfile.lua");
    MiniGameUserProfile.ShowPage();
end

function MiniGameMainPage.OnClickSkin()
    MiniGameMainPage.ShowUserInfo("skin")
end

function MiniGameMainPage.OnClickCreateManual()
    local MiniGamaCreateManual = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGamaCreateManual.lua")
    MiniGamaCreateManual.ShowCreateManual()
end

function MiniGameMainPage.OnClickPlayBook()
    local MiniGamePlayBook = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGamePlayBook.lua")
    MiniGamePlayBook.ShowPlayBook()
end


function MiniGameMainPage.OnClickRecommendGames()
     if MiniGameMainPage.IsTimeLimited() then
        MiniGameMainPage.ShowTimeLimitPage()
        return
    end
    if TimeLimitPage.GetStamina() <= 0 then
        _guihelper.MessageBox("当前体力不足，无法进行游戏")
        return
    end
    local MiniGameDailyRecommend = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameDailyRecommend.lua")
    MiniGameDailyRecommend.ShowRecommend()
end

function MiniGameMainPage.OnClickMap()
    local MiniGameMap = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMap.lua");
    MiniGameMap.ShowPage();
end

function MiniGameMainPage.OnClickMyPlannet()
    MiniGameMainPage.ShowUserInfo("works")
end

function MiniGameMainPage.OnClickVip()
    local MiniGameVip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameVip.lua")
    MiniGameVip.ShowVipPage()
end

function MiniGameMainPage.ShowUserInfo(category)
    local MiniGameUserBag = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameUserBag.lua");
    MiniGameUserBag.ClosePage()
    local UserInfoPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/AIGC/UserInfoPage.lua")
    UserInfoPage.ShowPage("maisiAIMainPage",category)
end

function MiniGameMainPage.ShowBag(category)
    local MiniGameUserBag = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameUserBag.lua");
    MiniGameUserBag.ShowPage(category)
end

function MiniGameMainPage.StartWebGame(gameName, params, not_check_time_limit)
    GameLogic.MiniGameMgr:SetTimeLimitCheck(false)
    local gameName = "start_web_game_"..gameName
    GameLogic.GetCodeGlobal():BroadcastTextEvent(gameName,params)
end

function MiniGameMainPage.RefreshMusicUI(bPlay)
    MiniGameMainPage.IsMusicPlay = bPlay
    local tex = string.format("Texture/Aries/Creator/keepwork/minigame/main/%s_32bits.png",MiniGameMainPage.IsMusicPlay and "pause_music" or "play_music")
    if page then
        page:CallMethod("minigame_music","SetUIBackground",tex)
    end
end

function MiniGameMainPage.GetBeanNumber()
    local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
    local bHas, guid, bagid, copies = KeepWorkItemManager.HasGSItem(998)
    return copies or 0;
end

function MiniGameMainPage.OnUserBagFull()
    if not MiniGameMainPage.UserBagFullImp then
        MiniGameMainPage.UserBagFullImp = commonlib.debounce(function()
            local BagFullTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/BagFullTip.lua")
            BagFullTip.Show()
        end, 500)
    end
    MiniGameMainPage.UserBagFullImp()
end

function MiniGameMainPage.GetTimeLimitContainer()
    if not page then
        return 
    end
    if not MiniGameMainPage.timeLimitContainer or not MiniGameMainPage.timeLimitContainer:IsValid() then
        MiniGameMainPage.timeLimitContainer = ParaUI.GetUIObject("MiniGameMainPage.timeLimit")
    end
    return MiniGameMainPage.timeLimitContainer
end

function MiniGameMainPage.IsTimeLimited()
    return TimeLimitPage.IsTimeLimited()
end

function MiniGameMainPage.UpdateTimeLimit()
    TimeLimitPage.UpdateTimeLimit()
end

function MiniGameMainPage.ShowTimeLimitPage()
    TimeLimitPage.ShowTimeLimit()
end

function MiniGameMainPage.RefreshPage()
    if page then
        page:Refresh(0)
    end
end

function MiniGameMainPage.WorldStatusChanged(status, filename, displayName, stats)
    local statusText = ""
    if(filename == nil or filename == "") then
        status = ""
    elseif(status == "saved") then
        statusText = L"已保存"
    elseif(status == "unsaved") then
        statusText = L"未保存"
    elseif(status == "savedButNotSynced") then
        statusText = L"未同步"
    elseif(status == "Syncing") then
        statusText = L"同步中..."
    elseif(status == "Synced") then
        statusText = L"已同步"
    elseif(status == "SyncFailed") then
        statusText = L"同步失败"
    elseif(status == "loaded") then
        statusText = L""
    elseif(status == "downloading") then
        statusText = L"下载中..."
    elseif(status == "downloaded") then
        statusText = L"下载完成"
    elseif(status == "downloadNothing") then
        statusText = L""
    end
    local statsMsg;
    if(stats) then
        local blockCount = stats and stats.blocks or 0;
        local entityCount = stats and stats.liveEntities or 0;
        local parts = {};
        if blockCount > 0 then
            table.insert(parts, string.format(L"方块:%d", blockCount));
        end
        if entityCount > 0 then
            table.insert(parts, string.format(L"物品:%d", entityCount));
        end
        statsMsg = table.concat(parts, " ")
    end
    if(statusText ~= MiniGameMainPage.currentWorldStatus or statsMsg ~= MiniGameMainPage.currentWorldStatsText) then
        MiniGameMainPage.currentWorldStatus = statusText
        MiniGameMainPage.currentWorldStatsText = statsMsg
        MiniGameMainPage.UpdateEditInfo()
    end
    return status, filename, displayName, stats
end

function MiniGameMainPage.WorldSlotChanged(filename, displayName)
    if filename and filename ~= "" and displayName then
        if MiniGameMainPage.UIMode == "Task" then
            MiniGameMainPage.SetStoryMode()
            MiniGameMainPage.RefreshPage()
        end
    end
    MiniGameMainPage.currentWorldFilename = filename
    MiniGameMainPage.currentWorldDisplayName = displayName
    MiniGameMainPage.UpdateEditInfo()
    return filename, displayName
end

function MiniGameMainPage.UpdateEditInfo()
    if not page then
        return
    end
    local filename = MiniGameMainPage.currentWorldFilename
    local displayName = MiniGameMainPage.currentWorldDisplayName
    if filename and filename ~= "" and displayName then
        page:SetValue("minigame_edit_status", string.format("%s《%s》", MiniGameMainPage.currentWorldStatus or "", tostring(displayName)))
    else
        page:SetValue("minigame_edit_status", "")
    end
    page:SetValue("minigame_edit_statsText", MiniGameMainPage.currentWorldStatsText or "")
end

function MiniGameMainPage.UpdateEmailRedTip()
    -- TODO: show red tip on email button
end

function MiniGameMainPage.UpdateFriendRedTipNum(friendNum)
    if not page or not page:IsVisible() then
        return friendNum
    end
    local unread_friend_msg = ParaUI.GetUIObject("unreaded_friend_msg")
    if unread_friend_msg and unread_friend_msg:IsValid() then
        unread_friend_msg.visible = friendNum and friendNum > 0
    end
    return friendNum
end

function MiniGameMainPage.UpdateFriendRedTip(payload, bForceUpdate)
    if not page or not page:IsVisible() then
        return payload
    end
    
    local FriendManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendManager.lua")
    if payload and type(payload) == 'table' and payload.is_friend_apply then
        FriendManager:SetFriendApply(payload)
    end
    
    FriendManager:LoadAllUnReadMsgs(function()
        -- Update the red dot indicator based on unread messages
        local unread_friend_msg = ParaUI.GetUIObject("unreaded_friend_msg")
        if unread_friend_msg and unread_friend_msg:IsValid() then
            MiniGameMainPage.isShowFriendRedTip = (FriendManager.unread_msgs_num > 0 or (FriendManager.friend_apply and FriendManager.friend_apply.is_friend_apply))
            unread_friend_msg.visible = MiniGameMainPage.isShowFriendRedTip == true;
        end
    end, bForceUpdate~=false)
    return payload
end

function MiniGameMainPage.ClearFriendRedTip()
    if not page or not page:IsVisible() then
        return
    end
    
    local unread_friend_msg = ParaUI.GetUIObject("unreaded_friend_msg")
    if unread_friend_msg and unread_friend_msg:IsValid() then
        unread_friend_msg.visible = false
    end
end

function MiniGameMainPage.OnClickChangeUIMode()
    GameLogic.MiniGameMgr:RefreshGameDock()
    if MiniGameMainPage.UIMode == "Task" then
        MiniGameMainPage.SetStoryMode()
    else
        MiniGameMainPage.SetTaskMode()
    end
    MiniGameMainPage.RefreshPage()
end

function MiniGameMainPage.IsStoryMode()
    return MiniGameMainPage.UIMode == "Story"
end

function MiniGameMainPage.IsTaskMode()
    return MiniGameMainPage.UIMode == "Task"
end

function MiniGameMainPage.ChangeUIMode(mode)
    if mode == "Story" and not MiniGameMainPage.IsStoryMode() then
        MiniGameMainPage.SetStoryMode()
        GameLogic.MiniGameMgr:RefreshGameDock()
        MiniGameMainPage.RefreshPage()
    elseif mode == "Task" and not MiniGameMainPage.IsTaskMode() then
        MiniGameMainPage.SetTaskMode()
        GameLogic.MiniGameMgr:RefreshGameDock()
        MiniGameMainPage.RefreshPage()
    end
end

function MiniGameMainPage.SetStoryMode()
    MiniGameMainPage.UIMode = "Story"
    -- TODO: only do this once per world init.
    GameLogic.RunCommand("/movieclip -stop")
    GameLogic.RunCommand('/show actionbutton')
    GameLogic.RunCommand('/take EasyBuilder -replace -pin -bag 1 {toolname="map"}')
    GameLogic.RunCommand('/take 0 -replace -bag 2')
    GameLogic.RunCommand('/take EasyBuilder -select -replace -pin -bag 3 {toolname="play"}') 
    GameLogic.RunCommand('/take EasyBuilder -replace -pin -bag 4 {toolname="livemodel"}') 
    GameLogic.RunCommand('/take EasyBuilder -replace -pin -bag 5 {toolname="model"}') 
    GameLogic.RunCommand('/take EasyBuilder -replace -pin -bag 6 {toolname="char"}')
    GameLogic.RunCommand('/take EasyBuilder -replace -pin -bag 7 {toolname="action"}')
    GameLogic.RunCommand('/take EasyBuilder -replace -pin -bag 8 {toolname="env"}')
    GameLogic.RunCommand('/take EasyBuilder -replace -pin -bag 9 {toolname="bag"}')
    local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
    if(QuickSelectBar.ShowRightButtons) then
        QuickSelectBar.ShowRightButtons(false, false)
    end
    
    if(not EasyEditableWorld.HasLoadedAnyWorld()) then
        if(GameLogic.IsSignedIn()) then
            EasyHomeBuilder.CheckMyHomeExist(function(bExist, numberOfHomes)
                if bExist or numberOfHomes == 0 then
                    EasyEditableWorld:new({operation="ForceLoadIfNot", worldName = nil, onFinishCallback = function()
                        GameLogic.RunCommand('/take -select -bag 3')
                    end}):Run();
                end
            end, true)
        end
    end
    
    -- story mode should hide the main pet and show pet copilot
    GameLogic.MiniGameMgr:UnMountPets()
    local pet = GameLogic.MiniGameMgr:GetMainPet()
    local entity = pet and pet:GetEntity()
    if entity then
        GameLogic.MiniGameMgr:ShowMainPet(false)
    end
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotDragonPet.lua");
    local CopilotDragonPet = commonlib.gettable("MyCompany.Aries.Game.Tasks.CopilotDragonPet");
    local copilot = CopilotDragonPet.GetInstance()
    copilot:Show() 
    copilot:SetEnabled(true)
    
    GameLogic.OnToggleLockMouseWheel(false)
    GameLogic.options:SetCanJump(true)
    GameLogic.options:SetCanJumpInAir(true)
end

function MiniGameMainPage.SetTaskMode()
    MiniGameMainPage.UIMode = "Task"
    GameLogic.RunCommand("/movieclip -stop")
    GameLogic.RunCommand('/show actionbutton')
    GameLogic.RunCommand("/clearbag")
    local player = GameLogic.GetPlayer()
    if player then
        player:SetFocus();
        player:SetControlledExternally(false);
    end
    GameLogic.OnToggleLockMouseWheel(false)
    GameLogic.MiniGameMgr:RegisterCustomChat()
    EasyEditableWorld.CheckQuickSave(true);
    --GameLogic.options:SetCanJump(false)
    --GameLogic.options:SetCanJumpInAir(false)

    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotDragonPet.lua");
    local CopilotDragonPet = commonlib.gettable("MyCompany.Aries.Game.Tasks.CopilotDragonPet");
    local copilot = CopilotDragonPet.GetInstance()
    copilot:Hide()
    copilot:SetEnabled(false)
end


local task_names = {"MiniGameMainPage.task_ct","MiniGameMainPage.task_lt"}
local story_name = {"MiniGameMainPage.story_lt"}
function MiniGameMainPage.UpdateUIByGameMode()
    local isShowTaskUI = MiniGameMainPage.UIMode == "Task"
    for _,name in ipairs(task_names) do
        local task = ParaUI.GetUIObject(name)
        if task and task:IsValid() then
            task.visible = isShowTaskUI
        end
    end
    for _,name in ipairs(story_name) do
        local story = ParaUI.GetUIObject(name)
        if story and story:IsValid() then
            story.visible = not isShowTaskUI
        end
    end
    local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
    QuickSelectBar.ShowPage(not isShowTaskUI)
    MiniGameMainPage.ShowCustomGameUI(isShowTaskUI)
end

function MiniGameMainPage.RegisterGameUI(msg)
    if msg.name and msg.name ~= "" then
        MiniGameMainPage.gameUI = MiniGameMainPage.gameUI or {}
        MiniGameMainPage.gameUI[msg.name] = msg

        local isShowTaskUI = MiniGameMainPage.UIMode == "Task"
        local isShow = not MiniGameMainPage.hideGameUI
        MiniGameMainPage.UpdateCustomUI(msg.name,isShowTaskUI and isShow)
    end
end

function MiniGameMainPage.ShowCustomGameUI(bShow)
    local customGameUIs ={}
    MiniGameMainPage.gameUI = MiniGameMainPage.gameUI or {}
    for _,v in pairs(MiniGameMainPage.gameUI) do
        table.insert(customGameUIs,v.name)
    end
    GameLogic.GetCodeGlobal():BroadcastTextEvent("update_custom_ui",{show=bShow,gameUIs=customGameUIs})
end

function MiniGameMainPage.UpdateCustomUI(name,bShow)
    local customGameUIs ={}
    table.insert(customGameUIs,name)
    GameLogic.GetCodeGlobal():BroadcastTextEvent("update_custom_ui",{show=bShow,gameUIs=customGameUIs})
end

function MiniGameMainPage.OnClickCloud()
    local MiniGameEditableWorld = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameEditableWorld.lua")
    MiniGameEditableWorld.ShowEditableWebPage()
end

function MiniGameMainPage.OnClickSave()
    EasyEditableWorld:new({operation="Save", worldName = nil, slotIndex = nil}):Run();
end

function MiniGameMainPage.OnClickCamera()
    local MiniGameCamera = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameCamera.lua")
    MiniGameCamera.ShowPage()
end

function MiniGameMainPage.OnClickPetTransform()
    local MiniGameUserBag = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameUserBag.lua");
    MiniGameUserBag.ShowPage("candy");
end

function MiniGameMainPage.OnClickFriends()
    local FriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
    FriendsPage.Show();
    MiniGameMainPage.ClearFriendRedTip();
end

function MiniGameMainPage.OnClickPhone()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyPhone.lua");
    local EasyPhone = commonlib.gettable("MyCompany.Aries.Creator.Game.Tasks.EasyBuilder.EasyPhone");
    EasyPhone.ShowPage();
end

function MiniGameMainPage.OnClickBean()
    local MiniGameBeanHelp = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameBeanHelp.lua")
    MiniGameBeanHelp.ShowBeanHelp()
end

function MiniGameMainPage.OnClickUserItem()
    MiniGameMainPage.ShowBag("userItems");
end

function MiniGameMainPage.SetStamina(stamina,staminaText)
    if not page then
        return
    end
    local curStamina = TimeLimitPage.GetStamina()
    if stamina and stamina >= 0 then
        curStamina = stamina
    end
    page:SetValue("progressbar_stamina",curStamina)
    if staminaText and staminaText ~= "" then
        page:SetValue("minigame_timeLimit",staminaText)
    else
        page:SetValue("minigame_timeLimit",L""..TimeLimitPage.GetStamina())
    end
end

