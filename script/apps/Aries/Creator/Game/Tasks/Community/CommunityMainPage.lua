--[[
    author: pbb
    date: 2014-04-11
    description:
        This script is the main page of the community function.
    uselib:
        local CommunityMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityMainPage.lua")
        CommunityMainPage.Show()
]]

local ProjectMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Project/ProjectMainPage.lua")
local CommunityTitleInfo = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityTitleInfo.lua")
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local TipRoadManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ScreenTipRoad/TipRoadManager.lua");
local CommunityMainPage = NPL.export()

local base_texture_path = "Texture/Aries/Creator/keepwork/community_32bits.png#"
local tabData = {
    {value = L"创作",name ="create",icon=base_texture_path.."634 214 27 27", icon1 = base_texture_path.."598 214 27 27"},
    {value = L"探索",name ="explore",icon=base_texture_path.."626 142 27 27", icon1 = base_texture_path.."590 142 27 27"},
    {value = L"商城",name ="mall",icon=base_texture_path.."630 2 27 27", icon1 = base_texture_path.."602 38 27 27"},
	{value = L"学习",name ="study",icon=base_texture_path.."746 38 27 27", icon1 = base_texture_path.."734 74 27 27"},
    {value = L"会员",name ="vip",icon=base_texture_path.."742 146 27 27", icon1 = base_texture_path.."734 110 27 27"},
}

CommunityMainPage.selectedTab = -1
local page
function CommunityMainPage.OnInit()
    page = document:GetPageCtrl()
	page.OnClose = CommunityMainPage.OnPageClose
	page.OnCreate = CommunityMainPage.OnCreate
end

function CommunityMainPage.GetCategoryIndex(name)
	for i,v in ipairs(tabData) do
		if v.name == name then
			return i
		end
	end
	return -1
end

function CommunityMainPage.CloseHelpPage()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/HelpPage.lua");
	local HelpPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.HelpPage");
	if HelpPage.IsOpen() then
		HelpPage.ClosePage()
	end
end	

function CommunityMainPage.Show(bIsNotInWorld,category)
    if not System.options.isCommunity then
        return
    end
	CommunityMainPage.CloseHelpPage()
	if System.options.isOffline then
		local CommunityOfflinePage =NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Offline/CommunityOfflinePage.lua")
        CommunityOfflinePage.ShowPage(bIsNotInWorld)
		return
	end
	CommunityMainPage.selectedTab = -1
	
	CommunityMainPage.ClearProjectFrameData()
	CommunityMainPage.ClearExploreFrameData()
    local enable_esc_key = false
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/Community/CommunityMainPage.html",
			name = "CommunityMainPage.Show", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = enable_esc_key,
			cancelShowAnimation = true,
			-- app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			DesignResolutionWidth = 1280,
			DesignResolutionHeight = 720,
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	
	_guihelper.CloseMessageBox(true);
	CommunityTitleInfo.ShowPage(bIsNotInWorld)
	-- CommunityTitleInfo.UpdateMsg(function()
	-- 	CommunityTitleInfo.RefreshMsg()
	-- end)
	
	CommunityMainPage.ReportLoginTime()
	local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
	BroadcastHelper.GetSingletonTipsStack():Show(true)
	TipRoadManager:ReCreateRoads()
	CommunityMainPage.mytimer = CommunityMainPage.mytimer or commonlib.Timer:new({callbackFunc = function(timer)
		local x, y = ParaUI.GetMousePosition();
		local temp = ParaUI.GetUIObjectAtPoint(x, y);
		print("xxxxxxxxxxxxxxxx",temp.name,temp.id,temp.uiname,temp.parent.name,temp.parent.id,temp.parent.uiname,x, y)
	end})
	-- CommunityMainPage.mytimer:Change(0, 200);
	if not category or category == "" then
		CommunityMainPage.OnChangeTabview(1)
	else
		local categoryIndex = CommunityMainPage.GetCategoryIndex(category)
		if categoryIndex ~= -1 then
			CommunityMainPage.OnChangeTabview(categoryIndex)
		else
			CommunityMainPage.OnChangeTabview(1)
		end
	end

	System.Windows.Screen:Connect("sizeChanged", CommunityMainPage, CommunityMainPage.OnResize, "UniqueConnection");

	CommunityMainPage.mouse_key_Timer = CommunityMainPage.mouse_key_Timer or commonlib.Timer:new({callbackFunc = function(timer)
		CommunityMainPage.CheckMouseAndKey()
	end})
	CommunityMainPage.mouse_key_Timer:Change(0, 30)

	GameLogic.GetFilters():remove_filter("OnKeepWorkLogin", CommunityMainPage.OnKeepWorkLogin_Callback);
	GameLogic.GetFilters():add_filter("OnKeepWorkLogin", CommunityMainPage.OnKeepWorkLogin_Callback);

	CommunityMainPage.ShowTeamMember()
end

function CommunityMainPage.OnKeepWorkLogin_Callback(res)
	CommunityMainPage.ClearProjectFrameData()
	CommunityMainPage.RefreshPage()
	return res
end

function CommunityMainPage.CheckMouseAndKey()
	if ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_ESCAPE) then
		CommunityMainPage.OnEscKeyPressed()
	end
	if ParaUI.IsMousePressed(0) or ParaUI.IsMousePressed(1) or ParaUI.IsMousePressed(2) then
		local mouseX, mouseY = ParaUI.GetMousePosition();
		if not mouseX or not mouseY then
			return
		end
		if mouseX > 180 or mouseY > 430 then
			if CommunityTitleInfo.IsRoleInfoPanelVisible() then
				CommunityTitleInfo.HideRoleInfoPanel()
			end
		end
	end
end

function CommunityMainPage.OnEscKeyPressed()
	if not CommunityMainPage.OnEscKeyPressedImp then
		CommunityMainPage.OnEscKeyPressedImp = commonlib.debounce(function()
			CommunityTitleInfo.ShowRoleInfoPanel()
		end,200)
	end
	CommunityMainPage.OnEscKeyPressedImp()
end

function CommunityMainPage.OnPageClose()
	CommunityMainPage.mytimer = nil
	local ctl = CommunityMainPage.contextMenuCtrl;
	if ctl then
		ctl:Hide();
	end
	if CommunityMainPage.mouse_key_Timer then
		CommunityMainPage.mouse_key_Timer:Change()
		CommunityMainPage.mouse_key_Timer = nil
	end
end

function CommunityMainPage.OnCreate()
	local teamButton = ParaUI.GetUIObject("team_button");
	if teamButton and teamButton:IsValid() then
		teamButton:SetScript("onmouseenter",function()
			_guihelper.SetUIColor(teamButton, "#181818")
			_guihelper.SetButtonTextColor(teamButton, "#ffffff")			
		end)  
		teamButton:SetScript("onmouseleave",function()
			_guihelper.SetUIColor(teamButton, "#353536")
			_guihelper.SetButtonTextColor(teamButton, "#d3d3d3")		
		end)
	end
end

function CommunityMainPage.OnResize()
	CommunityMainPage.RefreshPage()
	CommunityMainPage.ShowTeamMember()
end

function CommunityMainPage.OnClose()
	if page then
		page:CloseWindow();
        page = nil
	end
	CommunityMainPage.ShowTeamMember()
end

function CommunityMainPage.GetCategoryDSIndex()
	return CommunityMainPage.selectedTab
end

function CommunityMainPage.GetMenuData()
	return tabData
end

function CommunityMainPage.OnChangeTabview(index)
	local tabId = tonumber(index)
	if tabId and tabId > 0 and tabId <= #tabData then
		CommunityMainPage.ChangeTab(tabId)
	end
end

function CommunityMainPage.OpenVipPage()
	local VipPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/VipPage.lua");
	local key = "community_main"
	local desc = L"社区首页"
	VipPage.ShowPage(key,desc);
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.main_page.open_vip_page", {useNoId=true},nil,true);
end

function CommunityMainPage.ChangeTab(tabId)
	if tabId == #tabData then
		CommunityMainPage.OpenVipPage()
		return
	end
	if CommunityMainPage.selectedTab ~= tabId then
		if tabId ~= 1 then
			CommunityMainPage.ClearProjectFrameData()
		end
		if tabId ~= 2 then
			CommunityMainPage.ClearExploreFrameData()
		end
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.main_page.open_main_tab", {tabIndex=tabId,useNoId=true},nil,true);
		CommunityMainPage.selectedTab = tabId
		CommunityMainPage.RefreshPage()
		CommunityMainPage.ShowTeamMember()
	end
end

function CommunityMainPage.OpenLearnPage()
	if CommunityMainPage.selectedTab == 4 then
		GameLogic.AddBBS(nil,L"正在前往学习页面，请去浏览器查看文档。")
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.main_page.open_learn_url", {useNoId=true},nil,true);
		if System.os.GetPlatform() == "win32" or System.os.IsEmscripten() then
			GameLogic.RunCommand("/open https://keepwork.com/official/docs/index");
			return
		end
		GameLogic.RunCommand("/open -e https://keepwork.com/official/docs/index")
	end
end

function CommunityMainPage.ClearExploreFrameData()
	local ExploreMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Explore/ExploreMainPage.lua")
	ExploreMainPage.ClearData()
end

function CommunityMainPage.ClearProjectFrameData()
	Mod.WorldShare.Store:Remove('world/searchText')
	ProjectMainPage.ClearFrameData()
end

function CommunityMainPage.GetMenuFrame()
	local frameUrl = ""
	if CommunityMainPage.selectedTab > 0 and CommunityMainPage.selectedTab <= #tabData then
		if CommunityMainPage.selectedTab == 1 then
			frameUrl = "script/apps/Aries/Creator/Game/Tasks/Community/Project/ProjectMainPage.html"
		elseif CommunityMainPage.selectedTab == 2 then
			frameUrl = "script/apps/Aries/Creator/Game/Tasks/Community/Explore/ExploreMainPage.html"
		elseif CommunityMainPage.selectedTab == 3 then
			frameUrl = "script/apps/Aries/Creator/Game/Tasks/Community/CommunityMallPage.html"
		elseif CommunityMainPage.selectedTab == 4 then
		end
	end
	return frameUrl
end	

function CommunityMainPage.ReportLoginTime()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
	local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
	QuestAction.ReportLoginTime()
end

function CommunityMainPage.RefreshPage()
    if page then
        page:Refresh(0)
    end
	local ctl = CommunityMainPage.contextMenuCtrl;
	if ctl then
		ctl:Hide();
	end
end

function CommunityMainPage.OnClickAbout()
	GameLogic.RunCommand("/menu help.about");
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.main_page.click_about", {useNoId=true},nil,true);
end

function CommunityMainPage.OnClickFeedback()
	GameLogic.RunCommand("/menu help.bug");
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.main_page.click_feedback", {useNoId=true},nil,true);
end

function CommunityMainPage.OpenSetting()
	local CommunitySetting = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Setting/CommunitySetting.lua")
	CommunitySetting.ShowPage()
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.main_page.click_setting", {useNoId=true},nil,true);
end

function CommunityMainPage.OpenVersion()
	if System.os.GetPlatform() ~= 'win32' then
		_guihelper.MessageBox(L'当前不支持在此平台查看版本信息。')
		print('当前不支持在此平台查看版本信息。')
		return
	end
	MyCompany.Aries.Game.MainLogin:ShowUpdatePage(true)
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.main_page.click_version", {useNoId=true},nil,true);
end

function CommunityMainPage.OpenChatPage()
	local ChatChannelPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatChannelPage.lua");
	ChatChannelPage.ShowPage()
end

function CommunityMainPage.IsVisible()
	return page and page:IsVisible()
end

function CommunityMainPage.GetTeamButtonInfo()
	local teamButton = ParaUI.GetUIObject("team_button");
	if teamButton and teamButton:IsValid() then
		return teamButton:GetAbsPosition()
	end
end

function CommunityMainPage.ShowTeamMember()
	if not CommunityMainPage.ShowFunc then
		CommunityMainPage.ShowFunc = commonlib.debounce(function()
			local TeamUserCtrl = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/TeamUserCtrl.lua");
			TeamUserCtrl.CheckShow()
		end, 100)
	end
	CommunityMainPage.ShowFunc()
end