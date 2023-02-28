--[[
Title: RedSummerCampSchoolMainPage
Author(s): 
Date: 2022/3/23
Desc:  the main 2d page for red summer camp 2021
Use Lib:
-------------------------------------------------------
local RedSummerCampSchoolMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampSchoolMainPage.lua");
RedSummerCampSchoolMainPage.Show();
--]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
NPL.load("(gl)script/ide/Transitions/Tween.lua");
local RedSummerCampSchoolMainPage = NPL.export();
local RedSummerCampCourseScheduling = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseSchedulingV2.lua") 
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
local KpUserTag = NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/KpUserTag.lua");
local FriendManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendManager.lua");
local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
local VipRewardPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/VipRewardPage.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local page
local notice_time = 3000
RedSummerCampSchoolMainPage.UserData = {}

local notice_desc = {
	{desc = [[学3D动画编程，参加全国学生信息素养提升实践活动]], name="zhengcheng"},
	{desc = [[全新世界“圣诞树”等你来体验]], name="ai_school"},
	{desc = [[冬令营课程包全新上线]], name="ai_school"},
}

local notice_text_index = 1

local cur_notice_node_index = 2
function RedSummerCampSchoolMainPage.OnInit()
	page = document:GetPageCtrl();
	page.OnCreate = RedSummerCampSchoolMainPage.OnCreate
	page.OnClose = RedSummerCampSchoolMainPage.OnClose
	
end

function RedSummerCampSchoolMainPage.Show()
	CustomCharItems:Init();

	local Game = commonlib.gettable("MyCompany.Aries.Game")
	if(Game.is_started) then
		Game.Exit()
	end

	if page then
		page:CloseWindow(true)
		RedSummerCampSchoolMainPage.OnClose()
	end
	RedSummerCampSchoolMainPage.ClearTween()
	RedSummerCampSchoolMainPage.InitUserData()
	notice_text_index = 1

	if not RedSummerCampSchoolMainPage.BindFilter then
	end

	local enable_esc_key = false
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampSchoolMainPage.html",
			name = "RedSummerCampSchoolMainPage.Show", 
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

	RedSummerCampPPtPage.OpenLastPPtPage()


	page:SetValue("notic_text1", RedSummerCampSchoolMainPage.GetAutoNoticeText())
	RedSummerCampSchoolMainPage.Timer = commonlib.Timer:new({callbackFunc = function(timer)
		RedSummerCampSchoolMainPage.StartNoticeAnim()
	end})
	RedSummerCampSchoolMainPage.Timer:Change(notice_time, nil);

	if not RedSummerCampSchoolMainPage.BindFilter then
		GameLogic.GetFilters():add_filter("became_vip", RedSummerCampSchoolMainPage.RefreshPage);
		GameLogic.GetFilters():add_filter("update_msgcenter_unread_num", function(num)
			RedSummerCampSchoolMainPage.ChangeRedTipState("email_red_icon", DockPage.HasMsgCenterUnReadMsg())
		end);
		GameLogic.GetFilters():add_filter("role_page_close", function()
			commonlib.TimerManager.SetTimeout(function()  
				RedSummerCampSchoolMainPage.RefreshPage()
			end, 200);
			
		end);

		RedSummerCampSchoolMainPage.BindFilter = true
	end
	
	local isVerified = GameLogic.GetFilters():apply_filters('store_get', 'user/isVerified');
	local hasJoinedSchool = GameLogic.GetFilters():apply_filters('store_get', 'user/hasJoinedSchool');

	if not isVerified or not hasJoinedSchool then
		local username = GameLogic.GetFilters():apply_filters('store_get', 'user/username');
		local session = GameLogic.GetFilters():apply_filters('database.sessions_data.get_session_by_username', username);
	
		if not (session and type(session) == 'table' and session.doNotNoticeVerify) then
			GameLogic.GetFilters():apply_filters('cellar.certificate.show_certificate_notice_page', function()
				KeepWorkItemManager.LoadProfile(false, function()
					RedSummerCampSchoolMainPage.RefreshPage()
				end)
			end)
		end
	end

	RedSummerCampSchoolMainPage.HasClickFriend = false
	RedSummerCampSchoolMainPage.HasClickQuest = false	
	FriendManager.CloseAllFriendPage()
	VipRewardPage.ShowPage()
	QuestAction.ReportLoginTime()

	if(not KeepWorkItemManager.IsLoaded())then
		KeepWorkItemManager.GetFilter():add_filter("loaded_all", function ()
			RedSummerCampSchoolMainPage.RefreshPage()
		end)
	end
end

function RedSummerCampSchoolMainPage.OnClose()
	RedSummerCampSchoolMainPage.ClearTween()
end

function RedSummerCampSchoolMainPage.Close()
	if page then
		page:CloseWindow()
		RedSummerCampSchoolMainPage.OnClose()
		page = nil
	end
end

function RedSummerCampSchoolMainPage.ClearTween()
	if RedSummerCampSchoolMainPage.tween_y_1 then
		RedSummerCampSchoolMainPage.tween_y_1:Stop()
		RedSummerCampSchoolMainPage.tween_y_2:Stop()
		RedSummerCampSchoolMainPage.tween_y_1 = nil
		RedSummerCampSchoolMainPage.tween_y_2 = nil
	end

	if RedSummerCampSchoolMainPage.Timer then
		RedSummerCampSchoolMainPage.Timer:Change()
		RedSummerCampSchoolMainPage.Timer = nil
	end
end

function RedSummerCampSchoolMainPage.OnCreate()
	local module_ctl = page:FindControl("main_user_player")
	local scene = ParaScene.GetMiniSceneGraph(module_ctl.resourceName);
	if scene and scene:IsValid() then
		local obj = scene:GetObject(module_ctl.obj_name);
		obj:SetScale(1)
	end

	RedSummerCampSchoolMainPage.HandleQuestRedTip()
	RedSummerCampSchoolMainPage.HandleFriendsRedTip()
	DockPage.HandMsgCenterMsgData()
	RedSummerCampSchoolMainPage.UpdateRedTip()
end

function RedSummerCampSchoolMainPage.GetAutoNoticeText()
	local data = notice_desc[notice_text_index]
	notice_text_index = notice_text_index + 1

	if notice_text_index > #notice_desc then
		notice_text_index = 1
	end

	return ">>> " .. data.desc
end

function RedSummerCampSchoolMainPage.OpenHelpPage(btnId)
	local btn = page:FindUIControl(btnId);
	if(btn and btn:IsValid()) then
		local x,y,width, height = btn:GetAbsPosition();
		if true then
			local params = {
				url = string.format("script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampHelperMenu.html?x=%s & y=%s",x,y+70),
				name = "RedSummerCampHelperMenu.Show", 
				isShowTitleBar = false,
				DestroyOnClose = true,
				style = CommonCtrl.WindowFrame.ContainerStyle,
				allowDrag = false,
				enable_esc_key = true,
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
			return
		end
		
		local KpQuickWord = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpQuickWord.lua");
		local ctl = CommonCtrl.GetControl("Help_Tree");

		if(ctl == nil)then
			ctl = CommonCtrl.ContextMenu:new{
				name = "Help_Tree",
				width = 160,
				subMenuWidth = 300,
				height = 350, -- add 30(menuitemHeight) for each new line. 
				AutoPositionMode = "_lt",
				--style = CommonCtrl.ContextMenu.DefaultStyleThick,
				{
					borderTop = 4,
					borderBottom = 4,
					borderLeft = 18,
					borderRight = 10,
					
					fillLeft = 0,
					fillTop = -15,
					fillWidth = 0,
					fillHeight = -24,
					
					titlecolor = "#e1ccb6",
					level1itemcolor = "#e1ccb6",
					level2itemcolor = "#ffffff",
					
					-- menu_bg = "Texture/Aries/Chat/newbg1_32bits.png;0 0 128 192:40 41 20 17",
					menu_bg = "Texture/Aries/Chat/newbg2_32bits.png;0 0 195 349:17 41 8 9",
					menu_lvl2_bg = "Texture/Aries/Chat/newbg2_32bits.png;0 0 195 349:17 41 8 9",
					shadow_bg = nil,
					separator_bg = "", -- : 1 1 1 4
					item_bg = "Texture/Aries/Chat/fontbg1_32bits.png;0 0 103 26: 1 1 1 1",
					expand_bg = "Texture/Aries/Chat/arrowup_32bits.png; 0 0 15 16",
					expand_bg_mouseover = "Texture/Aries/Chat/arrowon_32bits.png; 0 0 15 16",
					
					menuitemHeight = 30,
					separatorHeight = 2,
					titleHeight = 26,
					
					titleFont = "System;14;bold";
				},
			};
	
			RedSummerCampSchoolMainPage.OpenTreeNode()
		end
		
		if(not x or not width) then
			x,y,width, height = ParaUI.GetUIObject("BattleChatBtn"):GetAbsPosition();
		end

		ctl:Show(x, y+70);
	end
end

local listOfHelpNode = {
	{
		text = "教学视频",
		cmdName = "help.videotutorials"
	},
	{
		text = "官方文档",
		cmdName = "help.learn"
	},
	{
		text = "推荐课程",
		cmdName = "help.dailycheck"
	},
	{
		text = "提问",
		cmdName = "help.ask"
	},
	{
		type = "Separator"
	},
	{
		text = "提交意见或反馈",
		cmdName = "help.bug"
	},
	{
		text = "关于Paracraft",
		cmdName = "help.about"
	},
}

function RedSummerCampSchoolMainPage.OpenTreeNode()
	local ctl = CommonCtrl.GetControl("Help_Tree");
	if(ctl) then
		local node = ctl.RootNode;
		-- clear all children first
		node:ClearAllChildren();
		-- by categories
		node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "Quickwords", Name = "actions", Type = "Group", NodeHeight = 0 });

		for _, item in ipairs(listOfHelpNode) do
			node:AddChild(CommonCtrl.TreeNode:new({
				Text = item.text, Name = "xx", 
				Type = if_else(item.type, item.type, "Menuitem"),
				NodeHeight = 26,
				onclick = function ()
					if item.cmdName then
						GameLogic.RunCommand("/menu "..item.cmdName);
					end
				end,
			}));
		end
	end
end

function RedSummerCampSchoolMainPage.IsVisible()
	return page and page:IsVisible()
end

function RedSummerCampSchoolMainPage.StartNoticeAnim()
	-- RedSummerCampSchoolMainPage.ClearTween()
	if RedSummerCampSchoolMainPage.tween_y_1 then
		RedSummerCampSchoolMainPage.tween_y_1:Stop()
		RedSummerCampSchoolMainPage.tween_y_2:Stop()
	end
	if RedSummerCampSchoolMainPage.Timer then
		RedSummerCampSchoolMainPage.Timer:Change()
		RedSummerCampSchoolMainPage.Timer = nil
	end
	
	if not page or not page:IsVisible() then
		if page and not page:IsVisible() then
			page:CloseWindow()
			RedSummerCampSchoolMainPage.OnClose()
			page = nil
		end
		return
	end

	local time = 1
	local default_height = 62
	local notice_container_1 = ParaUI.GetUIObject("notice_container_1");
	if notice_container_1.y > 5 then
		notice_container_1.y = -default_height
		page:SetValue("notic_text1", RedSummerCampSchoolMainPage.GetAutoNoticeText())
	end

	if RedSummerCampSchoolMainPage.tween_y_1 == nil then
		RedSummerCampSchoolMainPage.tween_y_1 =CommonCtrl.Tween:new{
			obj=notice_container_1,
			prop="y",
			begin=notice_container_1.y,
			change=default_height,
			duration=time,
		}
	else
		RedSummerCampSchoolMainPage.tween_y_1.obj=notice_container_1
		RedSummerCampSchoolMainPage.tween_y_1.prop="y"
		RedSummerCampSchoolMainPage.tween_y_1.begin=notice_container_1.y
		RedSummerCampSchoolMainPage.tween_y_1.change=default_height
		RedSummerCampSchoolMainPage.tween_y_1.duration=time
	end


	RedSummerCampSchoolMainPage.tween_y_1.func=CommonCtrl.TweenEquations.easeNone;
	RedSummerCampSchoolMainPage.tween_y_1:Start();

	local notice_container_2 = ParaUI.GetUIObject("notice_container_2");
	if notice_container_2.y > 5 then
		notice_container_2.y = -default_height
		page:SetValue("notic_text2", RedSummerCampSchoolMainPage.GetAutoNoticeText())
	end

	if RedSummerCampSchoolMainPage.tween_y_2 == nil then
		RedSummerCampSchoolMainPage.tween_y_2 =CommonCtrl.Tween:new{
			obj=notice_container_2,
			prop="y",
			begin=notice_container_2.y,
			change=default_height,
			duration=time,
			MotionFinish = function()
				-- RedSummerCampSchoolMainPage.ClearTween()
				RedSummerCampSchoolMainPage.Timer = commonlib.Timer:new({callbackFunc = function(timer)
					RedSummerCampSchoolMainPage.StartNoticeAnim()
				end})
				RedSummerCampSchoolMainPage.Timer:Change(notice_time, nil);
			end
		}
	else
		RedSummerCampSchoolMainPage.tween_y_2.obj=notice_container_2
		RedSummerCampSchoolMainPage.tween_y_2.prop="y"
		RedSummerCampSchoolMainPage.tween_y_2.begin=notice_container_2.y
		RedSummerCampSchoolMainPage.tween_y_2.change=default_height
		RedSummerCampSchoolMainPage.tween_y_2.duration=time
		RedSummerCampSchoolMainPage.tween_y_2.MotionFinish = function()
			-- RedSummerCampSchoolMainPage.ClearTween()
			RedSummerCampSchoolMainPage.Timer = commonlib.Timer:new({callbackFunc = function(timer)
				RedSummerCampSchoolMainPage.StartNoticeAnim()
			end})
			RedSummerCampSchoolMainPage.Timer:Change(notice_time, nil);
		end
	end

	RedSummerCampSchoolMainPage.tween_y_2.func=CommonCtrl.TweenEquations.easeNone;
	RedSummerCampSchoolMainPage.tween_y_2:Start();
end

function RedSummerCampSchoolMainPage.InitUserData()
	local profile = KeepWorkItemManager.GetProfile()
	if (profile.username == nil or profile.username == "") then
		KeepWorkItemManager.LoadProfile(true, function(err, msg, data)
			if data.username and data.username ~= "" then
				RedSummerCampSchoolMainPage.RefreshPage()
			end
		end)
		return
	end
	
	local UserData = {}
	UserData.nickname = MyCompany.Aries.Chat.BadWordFilter.FilterString(profile.nickname)
	UserData.username = MyCompany.Aries.Chat.BadWordFilter.FilterString(profile.username or "")

	if UserData.nickname == nil or UserData.nickname == "" then
		UserData.nickname = UserData.username
		UserData.limit_nickname = UserData.username
	else
		UserData.limit_nickname = RedSummerCampSchoolMainPage.GetLimitLabel(UserData.nickname, 26)
	end
	-- UserData.nickname  = "广东省汕头市超级宇宙无敌欧力给国际联盟二十一世纪新新社会大学"

	UserData.limit_username = UserData.username

	-- profile.school = {}
	-- profile.school.name = "广东省汕头市超级宇宙无敌欧力给国际联盟二十一世纪新新社会大学"
	UserData.has_school = profile.school ~= nil and profile.school.name ~= nil
	if UserData.has_school then
		UserData.school_name = profile.school and profile.school.name or ""
		-- UserData.limit_school_name = RedSummerCampSchoolMainPage.GetLimitLabel(UserData.school_name,18)
		UserData.limit_school_name = UserData.school_name
	else
		UserData.limit_school_name = "尚未关联学校"
	end

	UserData.has_real_name = profile.realname ~= nil and profile.realname ~= ""
	
	UserData.is_vip = profile.vip == 1
	RedSummerCampSchoolMainPage.UserData = UserData
end

function RedSummerCampSchoolMainPage.GetHeadUrl()

	if profile.portrait and profile.portrait ~= "" then
		return profile.portrait
	end
	return ""
end

function RedSummerCampSchoolMainPage.GetUserData(name)
	return RedSummerCampSchoolMainPage.UserData[name] or ""
end

function RedSummerCampSchoolMainPage.GetLearnHistroy()
	return RedSummerCampCourseScheduling.GetTodayHistroy()
end

function RedSummerCampSchoolMainPage.GetLearnContent()
	local histroy = RedSummerCampSchoolMainPage.GetLearnHistroy()
	local function strings_split(str, sep) 
		local list = {}
		local str = str .. sep
		for word in string.gmatch(str, '([^' .. sep .. ']*)' .. sep) do
			list[#list+1] = word
		end
		return list
	end
	if histroy then
		local content= histroy.content or ""
		local lines = strings_split(content,"<br/>")
		if lines and type(lines) == "table" then
			return lines[1]
		end
	end
end

function RedSummerCampSchoolMainPage.OnClickLearn()
	local dataHistroy = RedSummerCampSchoolMainPage.GetLearnHistroy()
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.main_world_learn", {useNoId=true});
	if dataHistroy then
		RedSummerCampCourseScheduling.ShowPPTPage(dataHistroy.key,dataHistroy.pptIndex)
	else
    	RedSummerCampCourseScheduling.ShowView()
	end
end

function RedSummerCampSchoolMainPage.OpenPage(name)
    if(name == "course_page")then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.course_page", {useNoId=true});
        local RedSummerCampRecCoursePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampRecCoursePage.lua");
        RedSummerCampRecCoursePage.Show();
    elseif(name == "main_world")then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.main_world", {useNoId=true});
		-- local RedSummerCampMainWorldPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainWorldPage.lua");
		-- RedSummerCampMainWorldPage.Show();
		RedSummerCampCourseScheduling.ShowView()
    elseif(name == "explore")then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.explore", {useNoId=true});
		GameLogic.GetFilters():apply_filters('show_offical_worlds_page')
    end
end

function RedSummerCampSchoolMainPage.GetLimitLabel(text, maxCharCount)
    maxCharCount = maxCharCount or 13;
    local len = ParaMisc.GetUnicodeCharNum(text);
    if(len >= maxCharCount)then
	    text = ParaMisc.UniSubString(text, 1, maxCharCount-2) or "";
        return text .. "...";
    else
        return text;
    end
end


function RedSummerCampSchoolMainPage.ClickRealName()
	GameLogic.GetFilters():apply_filters(
		'show_certificate',
		function(result)
			if (result) then
				KeepWorkItemManager.LoadProfile(false, function()
					RedSummerCampSchoolMainPage.RefreshPage()
				end)
			end
		end
	);
end

function RedSummerCampSchoolMainPage.ClickSchool()
	GameLogic.GetFilters():apply_filters('cellar.my_school.after_selected_school', function ()
		KeepWorkItemManager.LoadProfile(false, function()
			RedSummerCampSchoolMainPage.RefreshPage()
		end)
	end);
end

function RedSummerCampSchoolMainPage.GetVipIcon()
	local profile = KeepWorkItemManager.GetProfile()
	local user_tag = KpUserTag.GetMcml(profile);
	return user_tag
end

function RedSummerCampSchoolMainPage.OnClickNotice(index)
	local notic_text = "notic_text" .. index
	local value = page:GetValue(notic_text)
	-- for k, v in pairs(notice_desc) do
	-- 	if string.find(value, v.desc) then
	-- 		RedSummerCampSchoolMainPage.OpenPage(v.name)
	-- 		break
	-- 	end
	-- end
end

function RedSummerCampSchoolMainPage.QuickStart()
	local Opus = NPL.load("(gl)Mod/WorldShare/cellar/Opus/Opus.lua")
	Opus:Show()
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.openopus", {useNoId=true});
	-- local last_world_id = GameLogic.GetPlayerController():LoadRemoteData("summer_camp_last_worldid", 0);
	-- if last_world_id and last_world_id > 0 then
	-- 	GameLogic.RunCommand(format('/loadworld -s -force %d', last_world_id))
	-- else
	-- 	local id_list = {
	-- 		ONLINE = 70351,
	-- 		RELEASE = 20669,
	-- 	}
	-- 	local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
	-- 	local httpwrapper_version = HttpWrapper.GetDevVersion();
	-- 	local world_id = id_list[httpwrapper_version]
	-- 	GameLogic.RunCommand(format('/loadworld -s -force %d', world_id))
	-- end
end

function RedSummerCampSchoolMainPage.IsFinishVideo()
	local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
	return ParacraftLearningRoomDailyPage.HasCheckedToday()
end

function RedSummerCampSchoolMainPage.UpdateVideoRedTip()
	local uiObj = ParaUI.GetUIObject("red_tip")
	if uiObj and uiObj:IsValid() then
		uiObj.visible = not RedSummerCampSchoolMainPage.IsFinishVideo()
	end
end

function RedSummerCampSchoolMainPage.RefreshPage()
	if page then
		RedSummerCampSchoolMainPage.InitUserData()
		page:Refresh(0)
		RedSummerCampSchoolMainPage.StartNoticeAnim()
	end
end


function RedSummerCampSchoolMainPage.ClickSchoolName()
	-- if RedSummerCampSchoolMainPage.UserData and not RedSummerCampSchoolMainPage.UserData.has_school then

	-- end
	GameLogic.GetFilters():apply_filters('cellar.my_school.after_selected_school', function ()
		KeepWorkItemManager.LoadProfile(false, function()
			local profile = KeepWorkItemManager.GetProfile()
			-- 是否选择了学校
			if profile and profile.schoolId and profile.schoolId > 0 then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
				local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
				QuestAction.AchieveTask("40003_1", 1, true)
			end

			commonlib.TimerManager.SetTimeout(function()
				RedSummerCampSchoolMainPage.RefreshPage()
			end, 500)
		end)
	end);
end

function RedSummerCampSchoolMainPage.HandleQuestRedTip()
	local is_all_task_complete = true
	local QuestProvider = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestProvider");
	if QuestProvider:GetInstance().questItemContainer_map then
		local quest_datas = QuestProvider:GetInstance():GetQuestItems() or {}
		for i, v in ipairs(quest_datas) do
			-- 有可以领取任务的时候

			if not v.questItemContainer:IsFinished() then
				is_all_task_complete = false
				break
			end
		end
	end
	RedSummerCampSchoolMainPage.ChangeRedTipState("task_red_icon", not is_all_task_complete and not RedSummerCampSchoolMainPage.HasClickQuest)
end

function RedSummerCampSchoolMainPage.HandleFriendsRedTip()
	if not RedSummerCampSchoolMainPage.IsVisible() then
		if RedSummerCampSchoolMainPage.CheckRedTipTimer then
			RedSummerCampSchoolMainPage.CheckRedTipTimer:Change()
			RedSummerCampSchoolMainPage.CheckRedTipTimer = nil
		end
		return
	end

	if nil == RedSummerCampSchoolMainPage.CheckRedTipTimer then
		RedSummerCampSchoolMainPage.CheckRedTipTimer = commonlib.Timer:new({callbackFunc = function(timer)
			RedSummerCampSchoolMainPage.HandleFriendsRedTip()
		end})

		RedSummerCampSchoolMainPage.CheckRedTipTimer:Change(60000, 60000);
	end

	FriendManager:LoadAllUnReadMsgs(function ()
		-- 处理未读消息
		if FriendManager.unread_msgs and FriendManager.unread_msgs.data then
			for k, v in pairs(FriendManager.unread_msgs.data) do
				if v.unReadCnt and v.unReadCnt > 0 then
					RedSummerCampSchoolMainPage.ChangeRedTipState("friend_red_icon", true)
					break
				end
			end
		end
	end, true);
end

function RedSummerCampSchoolMainPage.UpdateRedTip()
	if not RedSummerCampSchoolMainPage.IsVisible() then
		if RedSummerCampSchoolMainPage.UpdateRedTipTimer then
			RedSummerCampSchoolMainPage.UpdateRedTipTimer:Change()
			RedSummerCampSchoolMainPage.UpdateRedTipTimer = nil
		end
		return
	end

	if nil == RedSummerCampSchoolMainPage.UpdateRedTipTimer then
		RedSummerCampSchoolMainPage.UpdateRedTipTimer = commonlib.Timer:new({callbackFunc = function(timer)
			RedSummerCampSchoolMainPage.UpdateRedTip()
		end})

		RedSummerCampSchoolMainPage.UpdateRedTipTimer:Change(0, 1000);
	end

	RedSummerCampSchoolMainPage.ChangeRedTipState("email_red_icon", DockPage.HasMsgCenterUnReadMsg())
	RedSummerCampSchoolMainPage.HandleQuestRedTip()
	RedSummerCampSchoolMainPage.UpdateVideoRedTip()
end

function RedSummerCampSchoolMainPage.ChangeRedTipState(ui_name, state)
	if not RedSummerCampSchoolMainPage.IsVisible() then
		return
	end

	local friend_red_icon = ParaUI.GetUIObject(ui_name)
	
	if friend_red_icon:IsValid() then
		friend_red_icon.visible = state
	end
end

function RedSummerCampSchoolMainPage.OpenOlypic()
	-- local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
    -- RedSummerCampPPtPage.Show("winterOlympic");
	GameLogic.RunCommand(string.format("/loadworld -s -auto %s", 132939))
end

function RedSummerCampSchoolMainPage.GetVipBtnDiv(styleStr)
	if System.options.isHideVip then
		return nil
	end
	if _G._main_on_vipbtn_click==nil then
		_G._main_on_vipbtn_click = function()
			GameLogic.RunCommand("/vip show");
		end
	end
	local str =  [[
		<input type="button" value='' onclick="_main_on_vipbtn_click" class="red_summer_camp_open_vip_btn" style="%s" />
	]]
	styleStr = styleStr or "margin-right:20px;margin-top:5px;";
	str = string.format(str,styleStr)
	return str
end

function RedSummerCampSchoolMainPage.GetVipTimeIconDiv(margin_top,click_func_name)
    local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
    local profile = KeepWorkItemManager.GetProfile()
	if not profile.vipDeadline or profile.vipDeadline == "" then
		return ""
	end
	if System.options.isHideVip then
		return ""
	end

    local time_stamp = commonlib.timehelp.GetTimeStampByDateTime(profile.vipDeadline)
	--time_stamp = RedSummerCampSchoolMainPage.TimeVip or time_stamp
    local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
    local cur_time_stamp = QuestAction.GetServerTime()

    --test
    -- time_stamp = test_time1 or time_stamp
    -- cur_time_stamp = test2 or cur_time_stamp

    local left_time = time_stamp - cur_time_stamp
	if left_time < 0 then
		return ""
	end

    local min = math.floor(left_time/60)
    local hour = math.floor(min/60) 
    local day = math.floor(hour/24)

	
    if day > 30 then
        return ""
    end

    local show_value = day >= 1 and day or hour
    local unit_icon = day >= 1 and "Texture/Aries/Creator/keepwork/vip/vip_time/tian_10x9_32bits.png#0 0 10 9" or "Texture/Aries/Creator/keepwork/vip/vip_time/xiaoshi_9x8_32bits.png#0 0 9 8"

    local show_value_desc = "0" .. show_value
    local num_margin_left = -8
    local unit_margin_left = -10

    if show_value == 21 then
        num_margin_left = -13
        unit_margin_left = 0
    elseif show_value == 1 then
        num_margin_left = -2
        unit_margin_left = -20 
    elseif show_value == 11 then
        num_margin_left = -5
        unit_margin_left = -15
    elseif show_value >= 20 then
        num_margin_left = -16
        unit_margin_left = 3
    elseif show_value >= 10 then
        num_margin_left = -13
        unit_margin_left = -3 
    end

	margin_top = margin_top or 16
	click_func_name = click_func_name or "OpenVip"
    local div = [[
    <pe:container name="VipLimitTimeIcon" style="float: left;margin-right:15px;margin-top:%s; width: 66px;height: 67px; background: url()">
        <input zorder = "-1" type="button" value='' onclick="%s" is_tool_tip_click_enabled="true" is_lock_position="true" enable_tooltip_hover="true"
            tooltip='page_static://script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/VipTimeToolTip.html'
            style="position:relative;margin-left:0px;margin-top:0px;width:66px;height:70px;background: url(Texture/Aries/Creator/keepwork/vip/vip_time/dipan_66x70_32bits.png#0 0 66 70)" />
        <div style="margin-top: 18px;">
            <pe:textsprite ClickThrough="true" name="VipLimitTimeNum" fontName="VipLimitTime" value = '%s' style="float: left;width: 63px; margin-left:%s;margin-top:2px;font-size:20pt;" />
            <div style="float: left;margin-left: %s;margin-top: 13px; width: 10px;height: 9px; background: url(%s)"></div>
        </div>
    </pe:container>
    ]]

    div = string.format(div, margin_top, click_func_name, show_value_desc, num_margin_left, unit_margin_left, unit_icon)
    return div
end