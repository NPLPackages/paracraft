--[[
    author:{pbb}
    time:2023-02-14 19:42:52
    uselib:
        local EducateOfflinePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Offline/EducateOfflinePage.lua")
        EducateOfflinePage.ShowPage()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
NPL.load("(gl)script/apps/Aries/Chat/BadWordFilter.lua");
local BadWordFilter = commonlib.gettable("MyCompany.Aries.Chat.BadWordFilter");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
local EducateProject = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Offline/Project/EducateProject.lua")
local TipRoadManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ScreenTipRoad/TipRoadManager.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
local EducateOfflinePage = NPL.export()
local page

function EducateOfflinePage.OnInit()
    page = document:GetPageCtrl()
    page.OnCreate = EducateOfflinePage.OnCreate
    GameLogic.GetFilters():add_filter("click_create_new_world",EducateOfflinePage.SetShowCreateWorld)
    GameLogic.GetFilters():add_filter("OnWorldCreate",  EducateOfflinePage.OnWorldCreated)
    GameLogic.GetFilters():add_filter("show_my_works",EducateOfflinePage.ChangeTabIndex)
end

function EducateOfflinePage.ClearFilters()
    GameLogic.GetFilters():remove_filter("click_create_new_world",EducateOfflinePage.SetShowCreateWorld)
    GameLogic.GetFilters():remove_filter("OnWorldCreate",  EducateOfflinePage.OnWorldCreated)
    GameLogic.GetFilters():remove_filter("show_my_works",EducateOfflinePage.ChangeTabIndex)
end

function EducateOfflinePage.OnCreate()

end

function EducateOfflinePage.ChangeTabIndex(name)
    EducateOfflinePage.isShowCreateWorld = false
    EducateOfflinePage.RefreshPage()
end

function EducateOfflinePage.OnWorldCreated(worldPath)
    if worldPath and worldPath ~= "" then
        EducateOfflinePage.isShowCreateWorld = false
    end
    return worldPath
end

function EducateOfflinePage.SetWindowText()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Login/MainLogin.lua");
    local MainLogin = commonlib.gettable("MyCompany.Aries.Game.MainLogin");
    if MainLogin then
        MainLogin:SetWindowTitle()
    end
end

function EducateOfflinePage.ShowPage()
    EducateOfflinePage.ShowView()
    EducateOfflinePage.SetWindowText()
end

function EducateOfflinePage.ShowView()
    CustomCharItems:Init();
	local Game = commonlib.gettable("MyCompany.Aries.Game")
	if(Game.is_started) then
		Game.Exit()
        Mod.WorldShare.Store:Set('world/isShowExitPage', true)
        Mod.WorldShare.Store:Remove('world/currentWorld')
        Mod.WorldShare.Store:Remove('world/currentEnterWorld')
        Mod.WorldShare.Store:Remove('world/isEnterWorld')
	end

    GameLogic.GetFilters():apply_filters("OnKeepWorkLogout", true)

    local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
    CreateNewWorld.profile = nil
    ParaUI.GetUIObject('root'):RemoveAll()
    NPL.load("(gl)script/ide/TooltipHelper.lua");
    local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
    if(type(BroadcastHelper.Reset) == "function") then
        BroadcastHelper.Reset();
    end
    TipRoadManager:ReCreateRoads()
    EducateOfflinePage.isShowCreateWorld = false
    AudioEngine.Init()
    EducateOfflinePage.ClosePage()
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Educate/Offline/EducateOfflinePage.html",
        name = "EducateOfflinePage.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        zorder = -10,
        directPosition = true,
        cancelShowAnimation = true,
        DesignResolutionWidth = 1280,
		DesignResolutionHeight = 720,
        align = "_fi",
            x = view_width,
            y = view_height,
            width = -view_width/2,
            height = -view_height/2,
    };
    EducateProject.ShowCreate()
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    if(params._page ) then
        EducateOfflinePage.page = params._page
		params._page.OnClose = function(bDestroy)
            EducateOfflinePage.ClearFilters()
			EducateProject.CloseCreate()
		end
	end

end

function EducateOfflinePage.SetShowCreateWorld()
    EducateOfflinePage.isShowCreateWorld = true
    EducateOfflinePage.RefreshPage(true)
end

function EducateOfflinePage.RefreshPage(bCloseWorldList)
    if page then
        page:Refresh(0)
    end
    if bCloseWorldList then
        EducateProject.CloseCreate()
    end
end

function EducateOfflinePage.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function EducateOfflinePage.GetUserName()
    return ""
end

function EducateOfflinePage.ExitClient()
    EducateOfflinePage.ClosePage()
    System.options.cmdline_world = nil
    local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
    CreateNewWorld.profile = nil
    MyCompany.Aries.Game.MainLogin:set_step({HasInitedTexture = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsPreloadedTextures = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsLoadMainWorldRequested = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsCreateNewWorldRequested = true});
    MyCompany.Aries.Game.MainLogin:next_step({IsLoginModeSelected = false})

    --Map3DSystem.App.Commands.Call("Profile.Aries.Restart", {method="soft"});
    local OfflineAccountManager = NPL.load('(gl)Mod/WorldShare/cellar/OfflineAccount/OfflineAccountManager.lua')
    OfflineAccountManager.ResetOfflineStatus()

    EducateOfflinePage.SetWindowText()
end

function EducateOfflinePage.OnClickExitBtn()
    if GameLogic.GetFilters():apply_filters('is_signed_in') then
        local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepWorkService/KeepworkServiceSession.lua')
        KeepworkServiceSession:Logout(nil, function()
            Mod.WorldShare.MsgBox:Close()
            EducateOfflinePage.ExitClient()
        end)
        return
    end
    EducateOfflinePage.ExitClient()
end