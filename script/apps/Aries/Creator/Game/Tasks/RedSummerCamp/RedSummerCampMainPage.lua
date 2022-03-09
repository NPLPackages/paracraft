--[[
Title: RedSummerCampMainPage
Author(s): 
Date: 2021/7/6
Desc:  the main 2d page for red summer camp 2021
Use Lib:
-------------------------------------------------------
local RedSummerCampMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainPage.lua");
RedSummerCampMainPage.Show();
--]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
NPL.load("(gl)script/ide/Transitions/Tween.lua");
local RedSummerCampMainPage = NPL.export();
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
local KpUserTag = NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/KpUserTag.lua");
local FriendManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendManager.lua");
local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
local Notice = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/NoticeV2/Notice.lua");
local VipRewardPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/VipRewardPage.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local page
local notice_time = 3000
RedSummerCampMainPage.UserData = {}
RedSummerCampMainPage.ItemData = {
	{name="大赛", is_show_vip=false, is_show_recommend=true, node_name = "shentongbei", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/bg_1_220x220_32bits.png#0 0 220 220"},
	{name="新手入门", is_show_vip=false, is_show_recommend=false, node_name = "course_page", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/bg_2_220x220_32bits.png#0 0 220 220"},
	{name="乐园设计师", is_show_vip=false, is_show_recommend=false, node_name = "leyuan", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/8_219X202_32bits.png#0 0 220 220"},
	{name="推荐列表", is_show_vip=false, is_show_recommend=false, node_name = "explore", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/bg_4_220x220_32bits.png#0 0 220 220"},
	{name="虚拟校园", is_show_vip=false, is_show_recommend=false, node_name = "ai_school", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/bg_5_220x220_32bits.png#0 0 220 220"},
	{name="家长指南", is_show_vip=false, is_show_recommend=false, node_name = "parent_page", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/bg_6_220x220_32bits.png#0 0 220 220"},
}

local notice_desc = {
	-- {desc = [[教师节活动奖励新鲜出炉！！！]], name="teacher_day"},
	-- {desc = [[国庆学习有豪礼，学习进步在坚持！]], name="nationak_day"},
	-- {desc = [[关于举办"神通杯"第一届全国学校联盟中小学计算机编程大赛的通知]], name="shentongbei"},
	-- {desc = [[金秋九月，开学课程抢鲜学]], name="course_page"},
	{desc = [[学3D动画编程，参加全国学生信息素养提升实践活动]], name="zhengcheng"},
	{desc = [[全新世界“圣诞树”等你来体验]], name="ai_school"},
	{desc = [[冬令营课程包全新上线]], name="ai_school"},
}

RedSummerCampMainPage.RightBtData = {
	{node_name = "skin", red_icon_name="skin_red_icon", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/2_63X57_32bits.png#0 0 64 74"},
	{node_name = "certificate", red_icon_name="certificate_red_icon", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/1_63X57_32bits.png#0 0 64 74"},
	{node_name = "friend", red_icon_name="friend_red_icon", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/3_63X57_32bits.png#0 0 64 74"},
	{node_name = "email", red_icon_name="email_red_icon", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/4_63X57_32bits.png#0 0 64 74"},
	{node_name = "task", red_icon_name="task_red_icon", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/5_63X57_32bits.png#0 0 64 74"},
	{node_name = "rank", red_icon_name="rank_red_icon", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/6_51X53_32bits.png#0 0 64 74"},
}
local notice_text_index = 1

local cur_notice_node_index = 2
function RedSummerCampMainPage.OnInit()
	page = document:GetPageCtrl();
	page.OnCreate = RedSummerCampMainPage.OnCreate
	page.OnClose = RedSummerCampMainPage.OnClose
	
end

function RedSummerCampMainPage.Show()
	CustomCharItems:Init();

	local Game = commonlib.gettable("MyCompany.Aries.Game")
	if(Game.is_started) then
		Game.Exit()
	end

	if page then
		page:CloseWindow(true)
		RedSummerCampMainPage.OnClose()
	end
	RedSummerCampMainPage.ClearTween()
	RedSummerCampMainPage.InitUserData()
	notice_text_index = 1

	if not RedSummerCampMainPage.BindFilter then
		GameLogic.GetFilters():add_filter("get_vip_time_icon_div", RedSummerCampMainPage.GetVipTimeIconDiv);
	end

	local enable_esc_key = false
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainPage.html",
			name = "RedSummerCampMainPage.Show", 
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


	page:SetValue("notic_text1", RedSummerCampMainPage.GetAutoNoticeText())
	RedSummerCampMainPage.Timer = commonlib.Timer:new({callbackFunc = function(timer)
		RedSummerCampMainPage.StartNoticeAnim()
	end})
	RedSummerCampMainPage.Timer:Change(notice_time, nil);

	if not RedSummerCampMainPage.BindFilter then
		GameLogic.GetFilters():add_filter("became_vip", RedSummerCampMainPage.RefreshPage);
		GameLogic.GetFilters():add_filter("update_msgcenter_unread_num", function(num)
			RedSummerCampMainPage.ChangeRedTipState("email_red_icon", DockPage.HasMsgCenterUnReadMsg())
		end);
		GameLogic.GetFilters():add_filter("role_page_close", function()
			commonlib.TimerManager.SetTimeout(function()  
				RedSummerCampMainPage.RefreshPage()
			end, 200);
			
		end);

		RedSummerCampMainPage.BindFilter = true
	end
	
	local isVerified = GameLogic.GetFilters():apply_filters('store_get', 'user/isVerified');
	local hasJoinedSchool = GameLogic.GetFilters():apply_filters('store_get', 'user/hasJoinedSchool');

	if not isVerified or not hasJoinedSchool then
		local username = GameLogic.GetFilters():apply_filters('store_get', 'user/username');
		local session = GameLogic.GetFilters():apply_filters('database.sessions_data.get_session_by_username', username);
	
		if session and type(session) == 'table' and session.doNotNoticeVerify then
			return
		end

		GameLogic.GetFilters():apply_filters('cellar.certificate.show_certificate_notice_page', function()
			KeepWorkItemManager.LoadProfile(false, function()
				RedSummerCampMainPage.RefreshPage()
			end)
		end)
	end

	RedSummerCampMainPage.HasClickFriend = false
	RedSummerCampMainPage.HasClickQuest = false

	if Notice.CheckCanShow() and not RedSummerCampMainPage.isShowNotice then
        Notice.Show(0 ,100)
		RedSummerCampMainPage.isShowNotice = true
    end  

	VipRewardPage.ShowPage()
end

function RedSummerCampMainPage.OnClose()
	RedSummerCampMainPage.ClearTween()
end

function RedSummerCampMainPage.Close()
	if page then
		page:CloseWindow()
		RedSummerCampMainPage.OnClose()
		page = nil
	end
end

function RedSummerCampMainPage.ClearTween()
	if RedSummerCampMainPage.tween_y_1 then
		RedSummerCampMainPage.tween_y_1:Stop()
		RedSummerCampMainPage.tween_y_2:Stop()
		RedSummerCampMainPage.tween_y_1 = nil
		RedSummerCampMainPage.tween_y_2 = nil
	end

	if RedSummerCampMainPage.Timer then
		RedSummerCampMainPage.Timer:Change()
		RedSummerCampMainPage.Timer = nil
	end
end

function RedSummerCampMainPage.OnCreate()
	local module_ctl = page:FindControl("main_user_player")
	local scene = ParaScene.GetMiniSceneGraph(module_ctl.resourceName);
	if scene and scene:IsValid() then
		local obj = scene:GetObject(module_ctl.obj_name);
		obj:SetScale(1)
	end

	RedSummerCampMainPage.HandleQuestRedTip()
	RedSummerCampMainPage.HandleFriendsRedTip()
	DockPage.HandMsgCenterMsgData()
	RedSummerCampMainPage.UpdateRedTip()
end

function RedSummerCampMainPage.GetAutoNoticeText()
	local data = notice_desc[notice_text_index]
	notice_text_index = notice_text_index + 1

	if notice_text_index > #notice_desc then
		notice_text_index = 1
	end

	return ">>> " .. data.desc
end

function RedSummerCampMainPage.OpenHelpPage(btnId)
	local btn = page:FindUIControl(btnId);
	if(btn and btn:IsValid()) then
		local x,y,width, height = btn:GetAbsPosition();
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
	
			RedSummerCampMainPage.OpenTreeNode()
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

function RedSummerCampMainPage.OpenTreeNode()
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

function RedSummerCampMainPage.IsVisible()
	return page and page:IsVisible()
end

function RedSummerCampMainPage.StartNoticeAnim()
	-- RedSummerCampMainPage.ClearTween()
	if RedSummerCampMainPage.tween_y_1 then
		RedSummerCampMainPage.tween_y_1:Stop()
		RedSummerCampMainPage.tween_y_2:Stop()
	end
	if RedSummerCampMainPage.Timer then
		RedSummerCampMainPage.Timer:Change()
		RedSummerCampMainPage.Timer = nil
	end
	
	if not page or not page:IsVisible() then
		if page and not page:IsVisible() then
			page:CloseWindow()
			RedSummerCampMainPage.OnClose()
			page = nil
		end
		return
	end

	local time = 1
	local default_height = 62
	local notice_container_1 = ParaUI.GetUIObject("notice_container_1");
	if notice_container_1.y > 5 then
		notice_container_1.y = -default_height
		page:SetValue("notic_text1", RedSummerCampMainPage.GetAutoNoticeText())
	end

	if RedSummerCampMainPage.tween_y_1 == nil then
		RedSummerCampMainPage.tween_y_1 =CommonCtrl.Tween:new{
			obj=notice_container_1,
			prop="y",
			begin=notice_container_1.y,
			change=default_height,
			duration=time,
		}
	else
		RedSummerCampMainPage.tween_y_1.obj=notice_container_1
		RedSummerCampMainPage.tween_y_1.prop="y"
		RedSummerCampMainPage.tween_y_1.begin=notice_container_1.y
		RedSummerCampMainPage.tween_y_1.change=default_height
		RedSummerCampMainPage.tween_y_1.duration=time
	end


	RedSummerCampMainPage.tween_y_1.func=CommonCtrl.TweenEquations.easeNone;
	RedSummerCampMainPage.tween_y_1:Start();

	local notice_container_2 = ParaUI.GetUIObject("notice_container_2");
	if notice_container_2.y > 5 then
		notice_container_2.y = -default_height
		page:SetValue("notic_text2", RedSummerCampMainPage.GetAutoNoticeText())
	end

	if RedSummerCampMainPage.tween_y_2 == nil then
		RedSummerCampMainPage.tween_y_2 =CommonCtrl.Tween:new{
			obj=notice_container_2,
			prop="y",
			begin=notice_container_2.y,
			change=default_height,
			duration=time,
			MotionFinish = function()
				-- RedSummerCampMainPage.ClearTween()
				RedSummerCampMainPage.Timer = commonlib.Timer:new({callbackFunc = function(timer)
					RedSummerCampMainPage.StartNoticeAnim()
				end})
				RedSummerCampMainPage.Timer:Change(notice_time, nil);
			end
		}
	else
		RedSummerCampMainPage.tween_y_2.obj=notice_container_2
		RedSummerCampMainPage.tween_y_2.prop="y"
		RedSummerCampMainPage.tween_y_2.begin=notice_container_2.y
		RedSummerCampMainPage.tween_y_2.change=default_height
		RedSummerCampMainPage.tween_y_2.duration=time
		RedSummerCampMainPage.tween_y_2.MotionFinish = function()
			-- RedSummerCampMainPage.ClearTween()
			RedSummerCampMainPage.Timer = commonlib.Timer:new({callbackFunc = function(timer)
				RedSummerCampMainPage.StartNoticeAnim()
			end})
			RedSummerCampMainPage.Timer:Change(notice_time, nil);
		end
	end

	RedSummerCampMainPage.tween_y_2.func=CommonCtrl.TweenEquations.easeNone;
	RedSummerCampMainPage.tween_y_2:Start();
end

function RedSummerCampMainPage.InitUserData()
	local profile = KeepWorkItemManager.GetProfile()
	if (profile.username == nil or profile.username == "") then
		KeepWorkItemManager.LoadProfile(true, function(err, msg, data)
			if data.username and data.username ~= "" then
				RedSummerCampMainPage.RefreshPage()
			end
		end)
		return
	end
	
	local UserData = {}
	UserData.nickname = profile.nickname
	UserData.username = profile.username or ""

	if UserData.nickname == nil or UserData.nickname == "" then
		UserData.nickname = UserData.username
		UserData.limit_nickname = UserData.username
	else
		UserData.limit_nickname = RedSummerCampMainPage.GetLimitLabel(UserData.nickname, 26)
	end
	-- UserData.nickname  = "广东省汕头市超级宇宙无敌欧力给国际联盟二十一世纪新新社会大学"

	UserData.limit_username = UserData.username

	-- profile.school = {}
	-- profile.school.name = "广东省汕头市超级宇宙无敌欧力给国际联盟二十一世纪新新社会大学"
	UserData.has_school = profile.school ~= nil and profile.school.name ~= nil
	if UserData.has_school then
		UserData.school_name = profile.school and profile.school.name or ""
		-- UserData.limit_school_name = RedSummerCampMainPage.GetLimitLabel(UserData.school_name,18)
		UserData.limit_school_name = UserData.school_name
	else
		UserData.limit_school_name = "尚未关联学校"
	end

	UserData.has_real_name = profile.realname ~= nil and profile.realname ~= ""
	
	UserData.is_vip = profile.vip == 1
	RedSummerCampMainPage.UserData = UserData
end

function RedSummerCampMainPage.GetHeadUrl()

	if profile.portrait and profile.portrait ~= "" then
		return profile.portrait
	end
	return ""
end

function RedSummerCampMainPage.GetUserData(name)
	return RedSummerCampMainPage.UserData[name] or ""
end

function RedSummerCampMainPage.GetLimitLabel(text, maxCharCount)
    maxCharCount = maxCharCount or 13;
    local len = ParaMisc.GetUnicodeCharNum(text);
    if(len >= maxCharCount)then
	    text = ParaMisc.UniSubString(text, 1, maxCharCount-2) or "";
        return text .. "...";
    else
        return text;
    end
end


function RedSummerCampMainPage.ClickRealName()
	GameLogic.GetFilters():apply_filters(
		'show_certificate',
		function(result)
			if (result) then
				KeepWorkItemManager.LoadProfile(false, function()
					RedSummerCampMainPage.RefreshPage()
				end)
			end
		end
	);
end

function RedSummerCampMainPage.ClickSchool()
	GameLogic.GetFilters():apply_filters('cellar.my_school.after_selected_school', function ()
		KeepWorkItemManager.LoadProfile(false, function()
			RedSummerCampMainPage.RefreshPage()
		end)
	end);
end

function RedSummerCampMainPage.GetVipIcon()
	local profile = KeepWorkItemManager.GetProfile()
	local user_tag = KpUserTag.GetMcml(profile);
	return user_tag
end

function RedSummerCampMainPage.OnClickNotice(index)
	local notic_text = "notic_text" .. index
	local value = page:GetValue(notic_text)
	-- for k, v in pairs(notice_desc) do
	-- 	if string.find(value, v.desc) then
	-- 		RedSummerCampMainPage.OpenPage(v.name)
	-- 		break
	-- 	end
	-- end
	Notice.Show(1 ,100)
end

function RedSummerCampMainPage.OpenPage(name)
    if(name == "course_page")then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.course_page");
        local RedSummerCampRecCoursePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampRecCoursePage.lua");
        RedSummerCampRecCoursePage.Show();
    elseif(name == "shentongbei")then
        -- local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
        -- Page.ShowShenTongBeiPage();
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.match");
		local RacePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Race/RacePage.lua");
        RacePage.Show();
    elseif(name == "teacher_day")then
		local ActTeacher = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActTeacher/ActTeacher.lua") 
		ActTeacher.ShowView()
    elseif(name == "nationak_day")then
		local ActNationalDay = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Activity/ActNationalDay/ActNationalDay.lua") 
		ActNationalDay.ShowPage()
    elseif(name == "my_works")then
        local Opus = NPL.load("(gl)Mod/WorldShare/cellar/Opus/Opus.lua")
        Opus:Show()
    elseif(name == "zhengcheng")then
        local RedSummerCampCommonPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCommonPage.lua");
        RedSummerCampCommonPage.Show("zhengcheng");
    elseif(name == "ai_school")then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.ai_school");
        local RedSummerCampCommonPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCommonPage.lua");
        RedSummerCampCommonPage.Show("ai_school");
    elseif(name == "parent_page")then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.parent_page");
        local RedSummerCampParentsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampParentsPage.lua");
        RedSummerCampParentsPage.Show();
    elseif(name == "summer_camp")then
        local RedSummerCampCommonPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCommonPage.lua");
        RedSummerCampCommonPage.Show("summer_camp");
    elseif(name == "main_world")then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.main_world");
		local RedSummerCampMainWorldPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainWorldPage.lua");
		RedSummerCampMainWorldPage.Show();
	elseif(name == "leyuan")then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.leyuan");
		local RedSummerCampCommonPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCommonPage.lua");
        RedSummerCampCommonPage.Show("leyuan");
    elseif(name == "explore")then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.explore");
		GameLogic.GetFilters():apply_filters('show_offical_worlds_page')
	elseif(name == "superAnimal") then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.super_pet");
		local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
        RedSummerCampPPtPage.Show("superAnimal");
    end
end

function RedSummerCampMainPage.QuickStart()
	local Opus = NPL.load("(gl)Mod/WorldShare/cellar/Opus/Opus.lua")
	Opus:Show()
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.openopus");
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

function RedSummerCampMainPage.RefreshPage()
	if page then
		RedSummerCampMainPage.InitUserData()
		page:Refresh(0)
		RedSummerCampMainPage.StartNoticeAnim()
	end
end
function RedSummerCampMainPage.OnClickRightBt(name)
	if not GameLogic.GetFilters():apply_filters('is_signed_in') then
		GameLogic.GetFilters():apply_filters('check_signed_in', "请先登录", function(result)
			if result == true then
				commonlib.TimerManager.SetTimeout(function()
					if page == nil then
						return
					end
					RedSummerCampMainPage.RefreshPage()
					RedSummerCampMainPage.OnClickRightBt(name)
				end, 500)
			end
		end)

		return
	end


    if name == "skin" then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.openuserskin");
		local page = NPL.load("Mod/GeneralGameServerMod/App/ui/page.lua");
		last_page_ctrl = page.ShowUserInfoPage({HeaderTabIndex="skin", username = System.User.keepworkUsername});
	elseif name == "certificate" then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.openuserhonor");
		local page = NPL.load("Mod/GeneralGameServerMod/App/ui/page.lua");
		last_page_ctrl = page.ShowUserInfoPage({HeaderTabIndex="honor", username = System.User.keepworkUsername});
	elseif name == "friend" then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.openfriend");
        local FriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
        FriendsPage.Show();
		RedSummerCampMainPage.ChangeRedTipState("friend_red_icon", false)
	elseif name == "email" then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.openemail");
        local Email = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Email/Email.lua");
        Email.Show();		
	elseif name == "task" then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.opentask");
		local QuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestPage.lua");
		QuestPage.Show();
		RedSummerCampMainPage.HasClickQuest = true
		RedSummerCampMainPage.ChangeRedTipState("task_red_icon", false)
	elseif name == "rank" then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.login_main_page.openrank");
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Rank/Rank.lua").Show();
    end
end

function RedSummerCampMainPage.ClickSchoolName()
	-- if RedSummerCampMainPage.UserData and not RedSummerCampMainPage.UserData.has_school then

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
				RedSummerCampMainPage.RefreshPage()
			end, 500)
		end)
	end);
end

function RedSummerCampMainPage.HandleQuestRedTip()
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
	RedSummerCampMainPage.ChangeRedTipState("task_red_icon", not is_all_task_complete and not RedSummerCampMainPage.HasClickQuest)
end

function RedSummerCampMainPage.HandleFriendsRedTip()
	if not RedSummerCampMainPage.IsVisible() then
		if RedSummerCampMainPage.CheckRedTipTimer then
			RedSummerCampMainPage.CheckRedTipTimer:Change()
			RedSummerCampMainPage.CheckRedTipTimer = nil
		end
		return
	end

	if nil == RedSummerCampMainPage.CheckRedTipTimer then
		RedSummerCampMainPage.CheckRedTipTimer = commonlib.Timer:new({callbackFunc = function(timer)
			RedSummerCampMainPage.HandleFriendsRedTip()
		end})

		RedSummerCampMainPage.CheckRedTipTimer:Change(60000, 60000);
	end

	FriendManager:LoadAllUnReadMsgs(function ()
		-- 处理未读消息
		if FriendManager.unread_msgs and FriendManager.unread_msgs.data then
			for k, v in pairs(FriendManager.unread_msgs.data) do
				if v.unReadCnt and v.unReadCnt > 0 then
					RedSummerCampMainPage.ChangeRedTipState("friend_red_icon", true)
					break
				end
			end
		end
	end, true);
end

function RedSummerCampMainPage.UpdateRedTip()
	if not RedSummerCampMainPage.IsVisible() then
		if RedSummerCampMainPage.UpdateRedTipTimer then
			RedSummerCampMainPage.UpdateRedTipTimer:Change()
			RedSummerCampMainPage.UpdateRedTipTimer = nil
		end
		return
	end

	if nil == RedSummerCampMainPage.UpdateRedTipTimer then
		RedSummerCampMainPage.UpdateRedTipTimer = commonlib.Timer:new({callbackFunc = function(timer)
			RedSummerCampMainPage.UpdateRedTip()
		end})

		RedSummerCampMainPage.UpdateRedTipTimer:Change(0, 1000);
	end

	RedSummerCampMainPage.ChangeRedTipState("email_red_icon", DockPage.HasMsgCenterUnReadMsg())
	RedSummerCampMainPage.HandleQuestRedTip()
end

function RedSummerCampMainPage.ChangeRedTipState(ui_name, state)
	if not RedSummerCampMainPage.IsVisible() then
		return
	end

	local friend_red_icon = ParaUI.GetUIObject(ui_name)
	
	if friend_red_icon:IsValid() then
		friend_red_icon.visible = state
	end
end

function RedSummerCampMainPage.OpenOlypic()
	-- local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
    -- RedSummerCampPPtPage.Show("winterOlympic");
	GameLogic.RunCommand(string.format("/loadworld -s -auto %s", 132939))
end

function RedSummerCampMainPage.GetVipTimeIconDiv(margin_top,click_func_name)
    local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
    local profile = KeepWorkItemManager.GetProfile()
	if not profile.vipDeadline or profile.vipDeadline == "" then
		return ""
	end

    local time_stamp = commonlib.timehelp.GetTimeStampByDateTime(profile.vipDeadline)
	--time_stamp = RedSummerCampMainPage.TimeVip or time_stamp
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