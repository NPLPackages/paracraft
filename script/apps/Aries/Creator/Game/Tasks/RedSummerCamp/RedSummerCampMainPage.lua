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

NPL.load("(gl)script/ide/Transitions/Tween.lua");
local RedSummerCampMainPage = NPL.export();
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
local KpUserTag = NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/KpUserTag.lua");
local page
local notice_time = 3000
RedSummerCampMainPage.UserData = {}
RedSummerCampMainPage.ItemData = {
	{name="创意大赛", is_show_vip=false, is_show_recommend=true, node_name = "shentongbei", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/bg_1_220x220_32bits.png#0 0 220 220"},
	{name="推荐课程", is_show_vip=false, is_show_recommend=false, node_name = "course_page", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/bg_2_220x220_32bits.png#0 0 220 220"},
	{name="《征程》", is_show_vip=true, is_show_recommend=false, node_name = "zhengcheng", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/bg_3_220x220_32bits.png#0 0 220 220"},
	{name="推荐列表", is_show_vip=false, is_show_recommend=false, node_name = "explore", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/bg_4_220x220_32bits.png#0 0 220 220"},
	{name="虚拟校园", is_show_vip=false, is_show_recommend=false, node_name = "ai_school", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/bg_5_220x220_32bits.png#0 0 220 220"},
	{name="家长指南", is_show_vip=false, is_show_recommend=false, node_name = "parent_page", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/bg_6_220x220_32bits.png#0 0 220 220"},
}

local notice_desc = {
	{desc = [[教师节快乐！你想送给老师一件什么礼物？]], name="teacher_day"},
	{desc = [[关于举办"神通杯"第一届全国学校联盟中小学计算机编程大赛的通知]], name="shentongbei"},
	{desc = [[金秋九月，开学课程抢鲜学]], name="course_page"},
	{desc = [[重温红色记忆，重走《征程》之约]], name="zhengcheng"},
	{desc = [[为校争光，我的虚拟校园等你来建设]], name="ai_school"},
}

RedSummerCampMainPage.RightBtData = {
	{node_name = "skin", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/2_63X57_32bits.png#0 0 64 74"},
	{node_name = "certificate", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/1_63X57_32bits.png#0 0 64 74"},
	{node_name = "friend", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/3_63X57_32bits.png#0 0 64 74"},
	{node_name = "email", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/4_63X57_32bits.png#0 0 64 74"},
	{node_name = "task", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/5_63X57_32bits.png#0 0 64 74"},
	{node_name = "rank", img="Texture/Aries/Creator/keepwork/RedSummerCamp/main/6_51X53_32bits.png#0 0 64 74"},
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

	local enable_esc_key = System.options.isDevMode
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

	if RedSummerCampPPtPage.GetIsReturnOpenPage() then
		local RedSummerCampCourseScheduling = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseScheduling.lua") 
		RedSummerCampCourseScheduling.ShowView()

		RedSummerCampPPtPage.Show(course_name, pptIndex)
	end


	page:SetValue("notic_text1", RedSummerCampMainPage.GetAutoNoticeText())
	RedSummerCampMainPage.Timer = commonlib.Timer:new({callbackFunc = function(timer)
		RedSummerCampMainPage.StartNoticeAnim()
	end})
	RedSummerCampMainPage.Timer:Change(notice_time, nil);

	if not RedSummerCampMainPage.BindFilter then
		GameLogic.GetFilters():add_filter("became_vip", RedSummerCampMainPage.RefreshPage);
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
		UserData.limit_school_name = RedSummerCampMainPage.GetLimitLabel(UserData.school_name,18)
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
	for k, v in pairs(notice_desc) do
		if string.find(value, v.desc) then
			RedSummerCampMainPage.OpenPage(v.name)
			break
		end
	end
end

function RedSummerCampMainPage.OpenPage(name)
    if(name == "course_page")then
        local RedSummerCampRecCoursePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampRecCoursePage.lua");
        RedSummerCampRecCoursePage.Show();
    elseif(name == "shentongbei")then
        local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
        Page.ShowShenTongBeiPage();
    elseif(name == "teacher_day")then
		local ActTeacher = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActTeacher/ActTeacher.lua") 
		ActTeacher.ShowView()
    elseif(name == "my_works")then
        local Opus = NPL.load("(gl)Mod/WorldShare/cellar/Opus/Opus.lua")
        Opus:Show()
    elseif(name == "zhengcheng")then
        local RedSummerCampCommonPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCommonPage.lua");
        RedSummerCampCommonPage.Show("zhengcheng");
    elseif(name == "ai_school")then
        local RedSummerCampCommonPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCommonPage.lua");
        RedSummerCampCommonPage.Show("ai_school");
    elseif(name == "parent_page")then
        local RedSummerCampParentsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampParentsPage.lua");
        RedSummerCampParentsPage.Show();
    elseif(name == "summer_camp")then
        local RedSummerCampCommonPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCommonPage.lua");
        RedSummerCampCommonPage.Show("summer_camp");
    elseif(name == "main_world")then
		local RedSummerCampMainWorldPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainWorldPage.lua");
		RedSummerCampMainWorldPage.Show();
    elseif(name == "explore")then
		GameLogic.GetFilters():apply_filters('show_offical_worlds_page')
    end
end

function RedSummerCampMainPage.QuickStart()
	local Opus = NPL.load("(gl)Mod/WorldShare/cellar/Opus/Opus.lua")
	Opus:Show()

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
		local page = NPL.load("Mod/GeneralGameServerMod/App/ui/page.lua");
		last_page_ctrl = page.ShowUserInfoPage({HeaderTabIndex="skin", username = System.User.keepworkUsername});
	elseif name == "certificate" then
		local page = NPL.load("Mod/GeneralGameServerMod/App/ui/page.lua");
		last_page_ctrl = page.ShowUserInfoPage({HeaderTabIndex="honor", username = System.User.keepworkUsername});
	elseif name == "friend" then
        local FriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
        FriendsPage.Show();
	elseif name == "email" then
        local Email = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Email/Email.lua");
        Email.Show();		
	elseif name == "task" then
		local QuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestPage.lua");
		QuestPage.Show();
	elseif name == "rank" then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Rank/Rank.lua").Show();
    end
end