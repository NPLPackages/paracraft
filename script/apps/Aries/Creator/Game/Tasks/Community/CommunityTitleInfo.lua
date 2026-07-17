--[[
    author: pbb
    date: 2024-05-23
    description:
        This script is the main page of the community function.
    uselib:
        local CommunityTitleInfo = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityTitleInfo.lua")
        CommunityTitleInfo.ShowPage()
]]
NPL.load('(gl)script/apps/Aries/Creator/Game/Common/Translation.lua')
local FriendManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendManager.lua");
local Translation = commonlib.gettable('MyCompany.Aries.Game.Common.Translation')		
local NotificationManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Notification/NotificationManager.lua")
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local CommunityTitleInfo = NPL.export()
local http_env = HttpWrapper.GetDevVersion()
local page = nil
CommunityTitleInfo.UserData = {}

CommunityTitleInfo.MenuData = {
	{
		icon ="Texture/Aries/Creator/keepwork/community_32bits.png#926 5 14 14",
		text = L"个人中心",
		name = "role_center",
	},
	{
		icon ="Texture/Aries/Creator/keepwork/community_32bits.png#944 5 14 14",
		text = L"在线网盘",
		name = "network_disk",
	},
	{
		icon ="Texture/Aries/Creator/keepwork/community_32bits.png#962 5 14 14",
		text = L"会员中心",
		name = "vip_center",
	},
	{
		icon ="Texture/Aries/Creator/keepwork/community_32bits.png#980 5 14 14",
		text = L"版本",
		name = "version",
	},
	{
		icon ="Texture/Aries/Creator/keepwork/community_32bits.png#998 5 14 14",
		text = L"设置",
		name = "setting",
	},
	{
		icon ="Texture/Aries/Creator/keepwork/community_32bits.png#926 24 14 14",
		text = "语言/Language>",
		name = "language",
	},
	{
		icon ="Texture/Aries/Creator/keepwork/community_32bits.png#944 24 14 14",
		text = L"关于帕拉卡",
		name = "about",
	},
	{
		icon ="Texture/Aries/Creator/keepwork/community_32bits.png#962 24 14 14",
		text = L"退出登录",
		name = "logout",
	}
}

if System.options.isHideVip then
	CommunityTitleInfo.MenuData = commonlib.filter(CommunityTitleInfo.MenuData, function(item)
		return item.name ~= "vip_center"
	end)
end

function CommunityTitleInfo.OnInit()
    page = document:GetPageCtrl()
	page.OnClose = CommunityTitleInfo.OnPageClose
end
function CommunityTitleInfo.ShowPage(bNotShowClose)
    CommunityTitleInfo.IsNotShowClose = bNotShowClose
    CommunityTitleInfo.InitUserData()
    if page then
        page:CloseWindow()
        page = nil
    end
	local page_height = System.options.isHideVip and 330 or 425
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Community/CommunityTitleInfo.html", 
        name = "CommunityTitleInfo.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        click_through = true,
        cancelShowAnimation = true,
        directPosition = true,
            align = "_mt",
            x = 0,
            y = 0,
            width = 0,
            height = page_height,
    }

    System.App.Commands.Call("File.MCMLWindowFrame", params);	
	CommunityTitleInfo.UpdateMsg(function()
		CommunityTitleInfo.RefreshPage()
	end)
	GameLogic.GetFilters():remove_filter("became_vip", CommunityTitleInfo.OnBecomeVip);
    GameLogic.GetFilters():add_filter("became_vip", CommunityTitleInfo.OnBecomeVip);

    if(not KeepWorkItemManager.IsLoaded())then
		KeepWorkItemManager.GetFilter():add_filter("loaded_all", function ()
			CommunityTitleInfo.RefreshPage()
		end)
	end

	local isSigned =  GameLogic.GetFilters():apply_filters('is_signed_in')
	if not CommunityTitleInfo.IsVerified() and not CommunityTitleInfo.isFirstLogin and isSigned then
		CommunityTitleInfo.isFirstLogin = true
		local username = GameLogic.GetFilters():apply_filters('store_get', 'user/username');
		local session = GameLogic.GetFilters():apply_filters('database.sessions_data.get_session_by_username', username);
		if not (session and type(session) == 'table' and session.doNotNoticeVerify) then
			GameLogic.GetFilters():apply_filters('cellar.certificate.show_certificate_notice_page', function()
				KeepWorkItemManager.LoadProfile(false, function()
					CommunityTitleInfo.RefreshPage()
				end)
			end)
		end
	end

	GameLogic.GetFilters():remove_filter("UpdateEmailList", CommunityTitleInfo.RefreshPage);
    GameLogic.GetFilters():add_filter("UpdateEmailList", CommunityTitleInfo.RefreshPage);

	GameLogic.GetFilters():remove_filter("user_skin_change", CommunityTitleInfo.UpdateUserSkin);
	GameLogic.GetFilters():add_filter("user_skin_change", CommunityTitleInfo.UpdateUserSkin);

	--recv_friend_chat_msg
	GameLogic.GetFilters():remove_filter("friend_chat_msg", CommunityTitleInfo.HandleFriendsRedTip);
    GameLogic.GetFilters():add_filter("friend_chat_msg", CommunityTitleInfo.HandleFriendsRedTip);

	GameLogic.GetFilters():remove_filter("update_friend_unread_num", CommunityTitleInfo.UpdateFriendRedTipNum);
    GameLogic.GetFilters():add_filter("update_friend_unread_num", CommunityTitleInfo.UpdateFriendRedTipNum);

    commonlib.TimerManager.SetTimeout(function()
        CommunityTitleInfo.RefreshPage()
		CommunityTitleInfo.HandleFriendsRedTip()
		CommunityTitleInfo.UpdateRedStatus()
    end, 1000,"community_title_info_refresh_page_timer")
end

function CommunityTitleInfo.OpenImMessage()
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.title_page.openfriend", {useNoId=true});
	local FriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
	FriendsPage.Show();
	CommunityTitleInfo.UpdateFriendRedTip()
end

function CommunityTitleInfo.UpdateRedStatus()
	if not CommunityTitleInfo.IsVisible() then
		if CommunityTitleInfo.CheckRedTipTimer then
			CommunityTitleInfo.CheckRedTipTimer:Change()
			CommunityTitleInfo.CheckRedTipTimer = nil
		end
		return
	end
	CommunityTitleInfo.CheckRedTipTimer = CommunityTitleInfo.CheckRedTipTimer or commonlib.Timer:new({callbackFunc = function(timer)
		CommunityTitleInfo.UpdateFriendRedTip()
	end})
	CommunityTitleInfo.CheckRedTipTimer:Change(3000, 30000);
end

function CommunityTitleInfo.HandleFriendsRedTip(payload)
	local unread_msg_container = ParaUI.GetUIObject("unreaded_msg")
	if not unread_msg_container or not unread_msg_container:IsValid() then
		return payload
	end
	if payload and payload.msgType == "interactionMsg" then
		local my_userId = Mod.WorldShare.Store:Get('user/userId')
		local is_friend_apply = (payload.applyId and payload.friendId == my_userId)
		payload.is_friend_apply = is_friend_apply
		CommunityTitleInfo.UpdateFriendRedTip(payload)
	else
		CommunityTitleInfo.UpdateFriendRedTip()
	end
	return payload
end

function CommunityTitleInfo.UpdateFriendRedTipNum(friendNum)
	local unread_msg_container = ParaUI.GetUIObject("unreaded_msg")
	if unread_msg_container and unread_msg_container:IsValid() then
		unread_msg_container.visible = (friendNum and friendNum > 0)
	end
	return friendNum
end

function CommunityTitleInfo.UpdateFriendRedTip(payload)
	if payload and type(payload) == 'table' and payload.is_friend_apply then
		FriendManager:SetFriendApply(payload)
	end
	FriendManager:LoadAllUnReadMsgs(function()
		local unread_msg_container = ParaUI.GetUIObject("unreaded_msg")
		if unread_msg_container and unread_msg_container:IsValid() then
			local isVisible = FriendManager.unread_msgs_num > 0 or (FriendManager.friend_apply and FriendManager.friend_apply.is_friend_apply == true)
			unread_msg_container.visible = (isVisible == true)
		end
	end, true);
end

function CommunityTitleInfo.IsVisible() 
	return page and page:IsVisible()
end

function CommunityTitleInfo.CertificateResult(result)
	commonlib.TimerManager.SetTimeout(function()  
		CommunityTitleInfo.RefreshPage()
	end, 200);
end

function CommunityTitleInfo.UpdateUserSkin()
	commonlib.TimerManager.SetTimeout(function()  
		CommunityTitleInfo.RefreshPage()
	end, 200);
end

function CommunityTitleInfo.IsVerified()
	local isVerified = GameLogic.GetFilters():apply_filters('store_get', 'user/isVerified');
	return isVerified
end

function CommunityTitleInfo.OnClickRealname()
	if CommunityTitleInfo.IsVerified() then
		return
	end
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.title_page.click_relealname", {useNoId=true},nil,true);
	local username = GameLogic.GetFilters():apply_filters('store_get', 'user/username');
	local session = GameLogic.GetFilters():apply_filters('database.sessions_data.get_session_by_username', username);
	if not (session and type(session) == 'table' and session.doNotNoticeVerify) then
		GameLogic.GetFilters():apply_filters('cellar.certificate.show_certificate_notice_page', function()
			KeepWorkItemManager.LoadProfile(false, function()
				CommunityTitleInfo.RefreshPage()
			end)
		end)
	end
end

function CommunityTitleInfo.OnPageClose()
	GameLogic.GetFilters():remove_filter("UpdateEmailList", CommunityTitleInfo.RefreshPage);
	GameLogic.GetFilters():remove_filter("became_vip", CommunityTitleInfo.OnBecomeVip);

end

function CommunityTitleInfo.OnBecomeVip()
	CommunityTitleInfo.RefreshPage()
end

function CommunityTitleInfo.RefreshPage()
    CommunityTitleInfo.InitUserData(true)
    if page then
        page:Refresh(0)
		CommunityTitleInfo.RefreshMsg()
    end
end

function CommunityTitleInfo.InitUserData()
	local profile = KeepWorkItemManager.GetProfile()
	if (profile.username == nil or profile.username == "") then
		KeepWorkItemManager.LoadProfile(true, function(err, msg, data)
			if data.username and data.username ~= "" then
				CommunityTitleInfo.RefreshPage()
			end
		end)
		return
	end
	
	local UserData = {}
	UserData.nickname = MyCompany.Aries.Chat.BadWordFilter.FilterString(profile.nickname)
	UserData.username = MyCompany.Aries.Chat.BadWordFilter.FilterString(profile.username or "")

	if UserData.nickname == nil or UserData.nickname == "" then
		UserData.nickname = UserData.username
	end
	-- UserData.nickname = "你好，我有一个帽衫，你喜欢吗？"
	UserData.limit_nickname = commonlib.GetLimitLabelByTextWidth(UserData.nickname,140,"System;14;bold") 

	UserData.limit_username = UserData.username

	UserData.has_school = profile.school ~= nil and profile.school.name ~= nil
	if UserData.has_school then
		UserData.school_name = profile.school and profile.school.name or ""
		UserData.limit_school_name = UserData.school_name
	else
		UserData.limit_school_name = "尚未关联学校"
	end

	UserData.has_real_name = profile.realname ~= nil and profile.realname ~= ""
	
	UserData.is_vip = profile.vip == 1
	CommunityTitleInfo.UserData = UserData
end

function CommunityTitleInfo.GetUserData(name)
	return CommunityTitleInfo.UserData[name] or ""
end

function CommunityTitleInfo.IsGameStarted()
    if CommunityTitleInfo.IsNotShowClose then
        return false
    end
    local is_enter_world = GameLogic.GetFilters():apply_filters('store_get', 'world/isEnterWorld');
    return Game.is_started or is_enter_world
end

function CommunityTitleInfo.ExitToLogin()
	local Game = commonlib.gettable("MyCompany.Aries.Game")
	if(Game.is_started) then
		Game.Exit()
		Mod.WorldShare.Store:Remove('world/currentWorld')
		Mod.WorldShare.Store:Remove('world/currentEnterWorld')
		Mod.WorldShare.Store:Remove('world/isEnterWorld')
	end
    local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
    CreateNewWorld.profile = nil
    System.options.cmdline_world = nil
    MyCompany.Aries.Game.MainLogin:set_step({HasInitedTexture = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsPreloadedTextures = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsLoadMainWorldRequested = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsCreateNewWorldRequested = true});
    MyCompany.Aries.Game.MainLogin:next_step({IsLoginModeSelected = false})
    Mod.WorldShare.MsgBox:Close()
end

function CommunityTitleInfo.OnClose(bOnlyCloseSelf)
    if page then
        page:CloseWindow(true)
        page = nil
    end
	local CommunityMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityMainPage.lua")
	CommunityMainPage.OnClose()
    if not bOnlyCloseSelf then
		local CommunityUserInfo = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityUserInfo.lua")
		CommunityUserInfo.CloseInfoPage()
    end
end

function CommunityTitleInfo.ClosePage()
    if page then
		CommunityTitleInfo.OnClose()
        local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepWorkService/KeepworkServiceSession.lua')
        if KeepworkServiceSession:IsSignedIn() then
            KeepworkServiceSession:Logout(nil, function()
                GameLogic.GetFilters():apply_filters("OnKeepWorkLogout", true)
                CommunityTitleInfo.ExitToLogin()
            end)
        else
            CommunityTitleInfo.ExitToLogin()
        end
    end
end

function CommunityTitleInfo.ShowRoleInfoPanel()
	local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepWorkService/KeepworkServiceSession.lua')
	if not KeepworkServiceSession:IsSignedIn() then
		GameLogic.GetFilters():apply_filters('check_signed_in', "请登录", function(result)
			if result == true then
				commonlib.TimerManager.SetTimeout(function()
					CommunityTitleInfo.ShowRoleInfoPanel()
				end, 500)
			end
		end)
		return
	end

	if not page then
		return
	end	
	local roleInfoPanel = ParaUI.GetUIObject("main_role_panel")
	if roleInfoPanel and roleInfoPanel:IsValid() then
		roleInfoPanel.visible = not roleInfoPanel.visible
		if roleInfoPanel.visible == false then
			CommunityTitleInfo.HideLanguagePanel()
		else
			local FriendManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendManager.lua");
			FriendManager.CloseAllFriendPage()
		end
	end
end

function CommunityTitleInfo.HideRoleInfoPanel()
	if not page then
		return
	end
	local roleInfoPanel = ParaUI.GetUIObject("main_role_panel")
	if roleInfoPanel and roleInfoPanel:IsValid() then
		roleInfoPanel.visible = false
	end
end

function CommunityTitleInfo.IsRoleInfoPanelVisible()
	if not page then
		return false
	end
	local roleInfoPanel = ParaUI.GetUIObject("main_role_panel")
	if roleInfoPanel and roleInfoPanel:IsValid() then
		return roleInfoPanel.visible
	end
	return false
end

function CommunityTitleInfo.IsVip()
	local profile = KeepWorkItemManager.GetProfile() or {}
	if profile.vip == 1 or profile.commonVip == 1 then
		return true
	end
	return false
end

function CommunityTitleInfo.GetVipIcon()
	local profile = KeepWorkItemManager.GetProfile() or {}
	if profile.vip == 1 then
		return "Texture/Aries/Creator/keepwork/community_32bits.png#70 238 48 16"
	end
	if profile.commonVip == 1 then
		return "Texture/Aries/Creator/keepwork/community_32bits.png#138 238 48 16"
	end
end

function CommunityTitleInfo.GetVipDeadLine()
	local profile = KeepWorkItemManager.GetProfile() or {}
	if profile.vip == 1 then
        if not profile.vipDeadline then
            return L"永久超级会员"
        end
		local deadline = commonlib.timehelp.GetTimeStampByDateTime(profile.vipDeadline)
		return os.date("%Y年%m月%d日", deadline)
	end
	if profile.commonVip == 1 then
        if not profile.commonVipDeadline then
            return L"永久会员"
        end
		local deadline = commonlib.timehelp.GetTimeStampByDateTime(profile.commonVipDeadline)
		return os.date("%Y年%m月%d日", deadline)
	end
	return Mod.WorldShare.Utils.IsEnglish() and "For inactive Vip,click to go" or L"暂未激活会员，点击前往"
end

function CommunityTitleInfo.OnClickLogOut()
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.title_page.click_logout", {useNoId=true},nil,true);
	CommunityTitleInfo.HideRoleInfoPanel()
	CommunityTitleInfo.ClosePage()
end

function CommunityTitleInfo.OnClickVip()
	CommunityTitleInfo.HideRoleInfoPanel()
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.title_page.click_vip", {useNoId=true},nil,true);
    local CommunityMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityMainPage.lua")
	CommunityMainPage.OnChangeTabview(5)
end

function CommunityTitleInfo.OpenUserInfo()
	CommunityTitleInfo.HideRoleInfoPanel()
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.title_page.click_userinfo", {useNoId=true},nil,true);
	local CommunityUserInfo = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityUserInfo.lua")
    CommunityUserInfo.ShowPage()
end

function CommunityTitleInfo.OnClickWebDisk()
	CommunityTitleInfo.HideRoleInfoPanel()
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.title_page.click_webdisk", {useNoId=true},nil,true);
	GameLogic.RunCommand("/menu file.webdisk")
end		

function CommunityTitleInfo.OpenMessage()
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.title_page.click_notification", {useNoId=true},nil,true);
	local CommunityNotification = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Notification/CommunityNotification.lua")
	CommunityNotification.ShowPage()
end

function CommunityTitleInfo.IsVisible()
    local isVisible = page and page:IsVisible()
    return isVisible == true
end

function CommunityTitleInfo.UpdateMsg(callback)
    NotificationManager.Init(true, function()
        if callback and type(callback) == 'function' then
            callback()
        end
    end) --获取邮件
end

function CommunityTitleInfo.RefreshMsg()
	if not page then
		return
	end
	local unread_msg_container = ParaUI.GetUIObject("unreaded_notice")
	if not unread_msg_container or not unread_msg_container:IsValid() then
		return
	end
	if NotificationManager.IsHaveNew() then
		unread_msg_container.visible = true
	else
		unread_msg_container.visible = false
	end
end

function CommunityTitleInfo.OnClickMenu(name,mcmlNode)
	if name and name ~= "language" then
		CommunityTitleInfo.HideRoleInfoPanel()
	end
	if name == "role_center" then
		CommunityTitleInfo.OpenUserInfo()
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.title_page.click_role_center", {useNoId=true},nil,true);
		return
	end
	if name == "network_disk" then
		CommunityTitleInfo.OnClickWebDisk()
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.title_page.click_network_disk", {useNoId=true},nil,true);
		return
	end
	if name == "vip_center" then
		CommunityTitleInfo.OnClickVip()
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.title_page.click_vip_center", {useNoId=true},nil,true);
		return 
	end
	if name == "version" then
		if System.os.GetPlatform() ~= 'win32' then
			_guihelper.MessageBox(L'当前不支持在此平台查看版本信息。')
			print('当前不支持在此平台查看版本信息。')
			return
		end
		MyCompany.Aries.Game.MainLogin:ShowUpdatePage(true)
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.title_page.click_version", {useNoId=true},nil,true);
		return
	end
	if name == "setting" then
		local CommunitySetting = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Setting/CommunitySetting.lua")
		CommunitySetting.ShowPage()
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.title_page.click_setting", {useNoId=true},nil,true);
		return
	end
	if name == "language" then
		CommunityTitleInfo.ShowLanguagePanel()
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.title_page.click_language", {useNoId=true},nil,true);
		return
	end
	if name == "about" then
		GameLogic.RunCommand("/menu help.about");
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.title_page.click_about", {useNoId=true},nil,true);
		return
	end
	if name == "logout" then
		CommunityTitleInfo.OnClickLogOut()
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.title_page.click_logout", {useNoId=true},nil,true);
		return
	end
end

function CommunityTitleInfo.ShowLanguagePanel()
	local menuStyle = commonlib.copy(CommonCtrl.ContextMenu.DefaultStyle)
	menuStyle.menuitemHeight = 36
	menuStyle.item_bg = "Texture/Aries/Creator/keepwork/community_32bits.png;344 7 32 32:14 14 14 14"
	menuStyle.menu_bg = "Texture/Aries/Creator/keepwork/community_32bits.png;307 8 32 32:14 14 14 14"
	menuStyle.level1itemcolor = "#A8A7B0FF"
	menuStyle.mouseover_textcolor = "#ffffff"
	menuStyle.textFont = "System;14;bold"
	local ctl = CommunityTitleInfo.contextMenuCtrl;
	if(not ctl)then
		ctl = CommonCtrl.ContextMenu:new{
			name = "CommunityTitleInfo.contextMenuCtrl",
			width = 114,
			height = 124, 
			onclick = CommunityTitleInfo.OnClickContextMenuItem,
			style = menuStyle,
		};
		CommunityTitleInfo.contextMenuCtrl = ctl;
		ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "root_node", Type = "Group", NodeHeight = 0 });
	end
	local curLanguage = Translation.GetCurrentLanguage()
	local node = ctl.RootNode:GetChild(1);
	if node then
		node:ClearAllChildren();
		node:AddChild(CommonCtrl.TreeNode:new({Text = L"简体中文" .. (curLanguage == "zhCN" and "  √" or ""), Name = "zhCN", Type = "Menuitem", onclick = nil, }))
		node:AddChild(CommonCtrl.TreeNode:new({Text = L"English" .. (curLanguage == "enUS" and "  √" or ""), Name = "enUS", Type = "Menuitem", onclick = nil, }))
		node:AddChild(CommonCtrl.TreeNode:new({Text = L"繁体中文" .. (curLanguage == "zhTW" and "  √" or ""), Name = "zhTW", Type = "Menuitem", onclick = nil, }))
	end
	local showY = System.options.isHideVip and 214 or 304
	ctl:Show(186, showY);
end

function CommunityTitleInfo.HideLanguagePanel()
	local ctl = CommunityTitleInfo.contextMenuCtrl;
	if(ctl)then
		ctl:Hide();
	end
end

function CommunityTitleInfo.OnClickContextMenuItem(node)
	local name = node.Name
    if not name  or name == '' then
        return
    end
	local curLanguage = Translation.GetCurrentLanguage()
	if name == curLanguage then
		return
	end
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.title_page.click_language", {language=name,useNoId=true},nil,true);
	Mod.WorldShare.Store:Set('user/isSettingLanguage', true)
    Translation.SetCustomLanguage(name, true)
    if(curLanguage ~= Translation.GetCurrentLanguage()) then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldLoginDocker.lua");
        local ParaWorldLoginDocker = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLoginDocker")
        ParaWorldLoginDocker.Restart("paracraft")
    end
end