--[[
Title: DockPage
Author(s): leio
Date: 2020/8/3
Desc:  
Use Lib:
-------------------------------------------------------
local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
DockPage.Show();
DockPage.Hide();

local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
DockPage.SetUIVisible_RightTop(false)
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local DailyTaskManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DailyTask/DailyTaskManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/PageCtrl.lua");
local FriendManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendManager.lua");
local Notice = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/NoticeV2/Notice.lua");
local MacroCodeCampActIntro = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MacroCodeCamp/MacroCodeCampActIntro.lua");
local ActRedhatExchange = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActRedhat/ActRedhatExchange.lua")
local ActWeek = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActWeek/ActWeek.lua")
local VipToolNew = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipToolNew.lua")
local QuestAllCourse = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAllCourse.lua")
local QuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestPage.lua");
local InviteFriend = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/InviteFriend/InviteFriend.lua")
local EmailManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Email/EmailManager.lua");
local DockPopupControl = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPopupControl.lua")
local RankPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Rank/Rank.lua")
local RacePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Race/RacePage.lua")

local DockPage = NPL.export();
local UserData = nil
DockPage.FriendsFansData = nil
DockPage.RefuseFansList = {}
DockPage.IsShowClassificationPage = false
DockPage.isShowTaskIconEffect = true
DockPage.showPages = {}
DockPage.hide_vip_world_ids = {
    ONLINE = { 18626 },
    RELEASE = { 1236 },
};
DockPage.hide_ui_world_ids = {
    ONLINE = { 70351 },
    RELEASE = { 20669 },
};
DockPage.is_show = true;

DockPage.left_top_line_1 = {
    { label = L"夏令营主ui", id = "summer_camp_main", enabled = true, bg="Texture/Aries/Creator/keepwork/SummerCamp/btn3_summer_camp_32bits.png#0 0 100 80", },  
    { label = L"地图", id = "summer_camp_map", enabled = true, bg="Texture/Aries/Creator/keepwork/dock/SummerCamp/map_32bits.png#0 0 100 80", }, 
    { label = L"课程", id = "summer_camp_kecheng", enabled = true, bg="Texture/Aries/Creator/keepwork/dock/SummerCamp/kecheng_32bits.png#0 0 100 80", },    
    { label = L"成就", id = "summer_camp_chengjiu", enabled = true, bg="Texture/Aries/Creator/keepwork/dock/SummerCamp/chengjiu_32bits.png#0 0 100 80", }, 

	{ label = L"云游", id = "summer_camp_yunyou", enabled = true, bg="Texture/Aries/Creator/keepwork/dock/SummerCamp/yunyou_32bits.png#0 0 100 80", }, 
    { label = L"长征路", id = "summer_camp_changzheng", enabled = true, bg="Texture/Aries/Creator/keepwork/dock/SummerCamp/changzheng_32bits.png#0 0 100 80", },
    { label = L"抗疫", id = "summer_camp_kangyi", enabled = true, bg="Texture/Aries/Creator/keepwork/dock/SummerCamp/kangyi_32bits.png#0 0 100 80", },
    { label = L"任务", id = "summer_camp_renwu", enabled = true, bg="Texture/Aries/Creator/keepwork/dock/SummerCamp/renwu_32bits.png#0 0 100 80", },
}
DockPage.left_top_line_2 = {
    
}

DockPage.top_line_1 = {
    { label = L"", },
    { label = L"荣誉榜", id = "rank", enabled = true, bg="Texture/Aries/Creator/keepwork/rank/btn3_rongyu_32bits.png#0 0 100 80", },  
    { label = L"实名礼包", id = "present", enabled = true, bg="Texture/Aries/Creator/keepwork/dock/btn3_libao_32bits.png#0 0 100 80", }, 
    { label = L"成长任务", id = "user_tip", enabled = true, bg="Texture/Aries/Creator/keepwork/dock/btn3_renwu1_32bits.png#0 0 100 80", },    
    { label = L"消息中心", id = "msg_center", enabled = true, bg="Texture/Aries/Creator/keepwork/Email/btn3_xiaoxi_32bits.png#0 0 100 80", }, 
    { label = L"活动公告", id = "notice", enabled = true, bg ="Texture/Aries/Creator/keepwork/dock/btn3_gonggao_32bits.png#0 0 100 80"},    
}
DockPage.top_line_2 = {
    { label = L"", },
    { label = L"夏令营主ui", id = "summer_camp_main", enabled2 = false, bg="Texture/Aries/Creator/keepwork/SummerCamp/btn3_summer_camp_32bits.png#0 0 100 80", }, 
    { label = L"呼朋唤友", id = "invitefriend", enabled2 = true, bg="Texture/Aries/Creator/keepwork/InviteFriend/btn3_jieban_32bits.png#0 0 100 80", }, 
    { label = L"作业", id = "homework", enabled2 = false, bg="Texture/Aries/Creator/keepwork/dock/btn3_zuoye_32bits.png#0 0 100 80", },
    { label = L"成长日记", id = "checkin", enabled2 = true, bg="Texture/Aries/Creator/keepwork/dock/btn3_riji_32bits.png#0 0 100 80", },
    { label = L"玩学课堂", id = "codewar", enabled2 = true, bg="Texture/Aries/Creator/keepwork/dock/btn3_ketang_32bits.png#0 0 100 80", },
    { label = L"大赛", id = "race", enabled2 = true, bg="Texture/Aries/Creator/keepwork/dock/btn3_dasai_32bits.png#0 0 100 80", },
}

DockPage.show_friend_red_tip = false

function DockPage.IsLessonWorld()
    NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
	local project_id = WorldCommon.GetWorldTag("kpProjectId");
	if project_id == 72966 or project_id == 73104 then
		return true
	end
    return false
end

function DockPage.Show(bCommand)
    local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
    if(not KeepWorkItemManager.GetToken() or DockPage.IsLessonWorld())then
        return
    end
    DockPage.InitTopIconData()
    if(not DockPage._root)then
        DockPage.page = Map3DSystem.mcml.PageCtrl:new({ 
            url = "script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.html" ,
            click_through = true,
        } );
        DockPage._root = DockPage.page:Create("DockPage.Show_instance", nil, "_fi", 0, 0, 0, 0)
        DockPage._root.zorder = -5;
	    DockPage._root:GetAttributeObject():SetField("ClickThrough", true);
    end
    DockPage._root.visible = true;
    DockPage.is_show = true;
    KeepWorkItemManager.GetUserInfo(nil,function(err,msg,data)
        if(err ~= 200)then
            return
        end
        UserData = data
        -- DockPage.HandleFriendsFansLocalData()
        DockPage.HandleFriendsRedTip(true);

        DockPage.HandMsgCenterMsgData();
    end)

    DockPopupControl.StartPopup(bCommand)

    DockPage.isShowTaskIconEffect = true

    DockPage.CheckIsTaskCompelete()

    DockPage.ShowCampIcon()
    
    -- ActWeek.GetServerTime(function()
    --     DockPage.RefreshPage()
    -- end)
    DockPage.ShowSummerCampIcon()

    GameLogic.QuestAction.RequestAiHomeWork(DockPage.FreshHomeWorkIcon)
end

function DockPage.RefreshPage()
    if DockPage.page then
        DockPage.InitTopIconData()
        DockPage.page:Refresh(0)
        DockPage.InitButton()
		DockPage.CheckRedSummerCampUIVisible();
    end    
end

--处理顶部icon数据，顶部数据的最大显示范围是6
function DockPage.RereshTopData()
    for k,v  in pairs(DockPage.top_line_1) do
        if v.id == "present" and GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
            v.enabled = false
        end
    end
end

function DockPage.InitTopIconData()
    DockPage.RereshTopData()
    local maxIndex = 6
    local minIndex = 1
    local temp_top1 = {}
    local temp_top2 = {}
    for k,v in pairs(DockPage.top_line_1) do
        if v.enabled == true then
            temp_top1[minIndex] = v
            minIndex = minIndex + 1
        end        
    end
    local needNum = maxIndex - minIndex + 1
    for i = 1,needNum do
        local temp =  { label = L"", }
        table.insert(temp_top1,1,temp)
    end  
    minIndex = 1
    for k,v in pairs(DockPage.top_line_2) do
        if v.enabled2 == true then
            temp_top2[minIndex] = v
            minIndex = minIndex + 1
        end    
    end
    local needNum = maxIndex - minIndex + 1
    for i = 1,needNum do
        local temp =  { label = L"", }
        table.insert(temp_top2,1,temp)
    end
    DockPage.top_line_1 = temp_top1
    DockPage.top_line_2 = temp_top2
end

function DockPage.InitButton()
    local buttons = {"character","work","explore","home","friends_1","friends_2", "school","vip","study"} -- ,"mall"
    for k,v in pairs(buttons) do
        local button = DockPage.page:GetNode(v);   
        local uiobject = ParaUI.GetUIObject(button.uiobject_id)

        if button and button.uiobject_id and uiobject then
            local width = uiobject.width
            local height = uiobject.height
            local x = uiobject.x
            local y = uiobject.y

            uiobject:SetScript("onmouseenter",function()
                uiobject.width = width * 1.1
                uiobject.height = height *1.1

                uiobject.x = x - (uiobject.width - width) /2
                uiobject.y = y - (uiobject.height - height) /2
            end)    

            uiobject:SetScript("onmouseleave",function()
                uiobject.width = width
                uiobject.height = height

                uiobject.x = x 
                uiobject.y = y
            end)
        end        
    end    
end

function DockPage.Hide()
    DockPage.is_show = false;
    if(DockPage._root)then
        DockPage._root.visible = false;
    end
end
function DockPage.IsShow()
    return DockPage.is_show;
end
function DockPage.CloseLastShowPage(id)
    if(not id)then
        return
    end
    
    for k,v in pairs(DockPage.showPages) do
        if v[1] then
            local page = nil
            if v[1] == "vip" then
                page =VipToolNew.GetPageCtrl()
            elseif v[1] == "explore" then
                GameLogic.GetFilters():apply_filters("cellar.explorer.close")
            elseif v[1] == "study" then
                page = QuestAllCourse.GetPageCtrl()
            elseif v[1] == "notice" then                
                page = Notice.GetPageCtrl()
            elseif v[1] == "invitefriend"then
                page = InviteFriend.GetPageCtrl()
            elseif v[1] == "user_tip" then
                page = QuestPage.GetPageCtrl()
            else
                page = v[2]              
            end
            local visible
            if page then              
                visible = page:IsVisible();
                if visible then
                    page:CloseWindow()
                    page = nil
                    if id == v[1] then
                        v[1] = nil
                        return true
                    end
                end
            end
        end
    end
    DockPage.showPages = {}
end

function DockPage.OnClickTop(id)
    if(DockPage.CloseLastShowPage(id))then
        return
    end
    if(id == "checkin")then
        ParacraftLearningRoomDailyPage.DoCheckin();
        table.insert(DockPage.showPages,{id,ParacraftLearningRoomDailyPage.GetPageCtrl()})
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.checkin");    
    elseif(id == "codewar")then
        local StudyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/StudyPage.lua");
        -- 玩学课堂二级页面
        -- StudyPage.clickArtOfWar();
        local Course = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Course/Course.lua");
        Course.Show();
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.code_war");    
    elseif(id == "user_tip")then        
        QuestPage.Show();
        table.insert(DockPage.showPages,{id,QuestPage.GetPageCtrl()})
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.user_tip");
        DockPage.isShowTaskIconEffect = false
        DockPage.RefreshPage()
    elseif(id == "msg_center")then
        -- local MsgCenter = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MsgCenter/MsgCenter.lua");
        -- MsgCenter.Show();
        local Email = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Email/Email.lua");
        Email.Show();
        table.insert(DockPage.showPages,{id,Email.GetPageCtrl()})
    elseif(id == "notice")then
        -- if (System.User.isVipSchool or System.User.isVip) then
        --     local SummerCampNotice = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampNotice.lua") 
        --     SummerCampNotice.ShowView()
        -- else
        --     Notice.Show(1); 
        --     table.insert(DockPage.showPages,{id,Notice.GetPageCtrl()})
        -- end  
        Notice.Show(1); 
        table.insert(DockPage.showPages,{id,Notice.GetPageCtrl()})
    elseif (id == 'present') then
        if not GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
            GameLogic.GetFilters():apply_filters(
                'show_certificate',
                function(result)
                    if (result) then
                        -- GameLogic.AddBBS(nil, L'领取成功', 5000, '0 255 0');
                        DockPage.RefreshPage()
                        GameLogic.QuestAction.AchieveTask("40006_1", 1, true)
                    end
                end
            );
        end
    -- elseif (id == 'find_hat') then
    --     if ActRedhatExchange then
    --         ActRedhatExchange.ShowView()
    --     end
    -- elseif (id == 'act_week') then
    --     ActWeek.ShowView()
    -- elseif(id == "week_quest")then
    --     local TeachingQuestLinkPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/TeachingQuestLinkPage.lua");
    --     TeachingQuestLinkPage.ShowPage();
    --     GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.week_quest");
    -- elseif(id == "web_keepwork_home")then
    --     ParaGlobal.ShellExecute("open", "explorer.exe", "https://keepwork.com", "", 1); 
    --     GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.web_keepwork_home");
    elseif (id == 'homework') then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestWork.lua").Show();
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.homework");
    elseif (id == 'invitefriend') then
        InviteFriend.ShowView()
        table.insert(DockPage.showPages,{id,InviteFriend.GetPageCtrl()})
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.invitefriend");

    elseif (id == 'summer_camp_main') then
        local SummerCampMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampMainPage.lua") 
        SummerCampMainPage.ShowView()
        table.insert(DockPage.showPages,{id,SummerCampMainPage.GetPageCtrl()})
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.summer_camp_main");
        
    elseif (id == 'rank') then    
        RankPage.Show();
        table.insert(DockPage.showPages,{id,RankPage.GetPageCtrl()})
    elseif id == "race" then
        RacePage.Show()
        table.insert(DockPage.showPages,{id,RacePage.GetPageCtrl()})
    elseif (id == 'dragonboatfestival') then
        local ActDragonBoatFestival = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActDragonBoatFestival/ActDragonBoatFestival.lua");
        ActDragonBoatFestival:Init();
    end
end
function DockPage.OnClick(id)
    if(DockPage.CloseLastShowPage(id))then
        return
    end
    local last_page_ctrl;
    if(id == "character")then
        local page = NPL.load("Mod/GeneralGameServerMod/App/ui/page.lua");
        last_page_ctrl = page.ShowUserInfoPage({username = System.User.keepworkUsername});
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.character");
        table.insert(DockPage.showPages,{id,last_page_ctrl})
    elseif(id == "work")then
		last_page_ctrl = GameLogic.GetFilters():apply_filters('show_create_page');
        table.insert(DockPage.showPages,{id,last_page_ctrl})
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.work");
    elseif(id == "explore")then
        last_page_ctrl = GameLogic.GetFilters():apply_filters('show_offical_worlds_page')
        table.insert(DockPage.showPages,{id,last_page_ctrl})
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.explore");
    elseif(id == "study")then
        QuestAllCourse.Show();
        last_page_ctrl = QuestAllCourse.GetPageCtrl()
        table.insert(DockPage.showPages,{id,last_page_ctrl})
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.study");
    elseif(id == "home")then
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.home");
        local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

        NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua");
        local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
        LocalLoadWorld.CreateGetHomeWorld();

        GameLogic.GetFilters():apply_filters('check_and_updated_before_enter_my_home', function()
            GameLogic.RunCommand("/loadworld home");
        end)
    elseif(id == "friends_1" or id == "friends_2")then
        local FriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
        FriendsPage.show_callback = function()
            last_page_ctrl = FriendsPage.GetPageCtrl();
            DockPage.last_page_ctrl = last_page_ctrl;
            DockPage.last_page_ctrl_id = id;
            table.insert(DockPage.showPages,{id,last_page_ctrl})
        end
        FriendsPage.Show();

        -- DockPage.SaveFriendsFansLocalData()
        DockPage.ChangeFriendRedTipState(false)
        DockPage.is_show_apply_red_tip = false

        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.friends");
        return
    elseif(id == "school")then
        last_page_ctrl = GameLogic.GetFilters():apply_filters('cellar.my_school.after_selected_school', function ()
            
            KeepWorkItemManager.LoadProfile(false, function()
                local profile = KeepWorkItemManager.GetProfile()
                -- 是否选择了学校
                if profile and profile.schoolId and profile.schoolId > 0 then
                    GameLogic.QuestAction.AchieveTask("40003_1", 1, true)
                end
            end)
        end);
        table.insert(DockPage.showPages,{id,last_page_ctrl})
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.school");              
    elseif(id == "vip")then
        -- ParacraftLearningRoomDailyPage.OnVIP("dock");
        -- local VipToolTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipToolTip.lua")
        -- VipToolTip:Init(true)  
		
		      
--        VipToolNew.Show()
--        last_page_ctrl = VipToolNew.GetPageCtrl()        

		local VipPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/VipPage.lua");
		VipPage.ShowPage();
        last_page_ctrl = VipPage.GetPageCtrl()        

        table.insert(DockPage.showPages,{id,last_page_ctrl})
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.vip");
    elseif(id == "mall")then
        local KeepWorkMallPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallPage.lua");
        KeepWorkMallPage.show_callback = function()
            last_page_ctrl = KeepWorkMallPage.GetPageCtrl();
            DockPage.last_page_ctrl = last_page_ctrl;
            DockPage.last_page_ctrl_id = id;
            table.insert(DockPage.showPages,{id,last_page_ctrl})
        end
        KeepWorkMallPage.Show();
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.mall");
        return
    elseif(id == "school_center")then
        local SchoolCenter = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SchoolCenter/SchoolCenter.lua")
        SchoolCenter.OpenPage(function(last_page_ctrl)
            DockPage.last_page_ctrl = last_page_ctrl;
            DockPage.last_page_ctrl_id = id;
            table.insert(DockPage.showPages,{id,last_page_ctrl})
        end)
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.school_center");
        return
    elseif id == "vip_make_up" then
        -- if System.User.isVip then
        --     GameLogic.RunCommand(string.format("/goto  %d %d %d", 19258,16,19134));
        --     local QuestCoursePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestCoursePage.lua");
        --     QuestCoursePage.Show(true)
        -- else
            local VipMakeUp = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipMakeUp.lua")
            VipMakeUp.Show()
        -- end
    else
        --_guihelper.MessageBox(id);
    end
    DockPage.last_page_ctrl = last_page_ctrl;
    DockPage.last_page_ctrl_id = id;
end

function DockPage.FindUIControl(name)
    if(not name or not DockPage.page)then
        return
    end
    return   DockPage.page:FindUIControl(name);
end

function DockPage.OnClickLeftTop(id)
    local SummerCampMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampMainPage.lua") 
	local SummerCampNoticeIntro = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampNoticeIntro.lua") 
	local SummerCampTaskPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampTaskPage.lua") 
	NPL.load("(gl)script/ide/timer.lua");

	if (id == 'summer_camp_main') then
        SummerCampMainPage.ShowView()
	elseif (id == 'summer_camp_map') then
		SummerCampMainPage.ClickMap()
	elseif (id == 'summer_camp_kecheng') then
        SummerCampMainPage.ShowView(2)
	elseif (id == 'summer_camp_chengjiu') then
        SummerCampMainPage.ShowView(4)
	elseif (id == 'summer_camp_yunyou') then
		SummerCampNoticeIntro.ShowView(1)
	elseif (id == 'summer_camp_changzheng') then
		SummerCampNoticeIntro.ShowView(2)
	elseif (id == 'summer_camp_kangyi') then
		GameLogic.GetCodeGlobal():BroadcastTextEvent("openUI", {name = "taskMain"}, function() end)
	elseif (id == 'summer_camp_renwu') then
        SummerCampMainPage.ShowView(3)
	end
	table.insert(DockPage.showPages,{id,SummerCampMainPage.GetPageCtrl()})
    GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.summer_camp_main");
end
function DockPage.RenderButton_LeftTop_1(index)
    local node = DockPage.left_top_line_1[index];
	local tip_str = "";
    local id = node.id;
    local bg = node.bg
	 local s = string.format([[
        <input type="button" name='%s' onclick="OnClickLeftTop" style="width:100px;height:80px;background:url(%s)"/>
        %s
    ]],node.id,bg,tip_str);
    return s;
end
function DockPage.RenderButton_LeftTop_2(index)
    local node = DockPage.left_top_line_2[index];
	local tip_str = "";
    local id = node.id;
    local bg = node.bg
	 local s = string.format([[
        <input type="button" name='%s' onclick="OnClickLeftTop" style="width:100px;height:80px;background:url(%s)"/>
        %s
    ]],node.id,bg,tip_str);
    return s;
end

function DockPage.RenderButton_1(index)
    local node = DockPage.top_line_1[index];
    local tip_str = "";
    local id = node.id;
    local bg = node.bg
    if (id == "msg_center") then
        tip_str = string.format([[
        <script type="text/npl" refresh="false">
            local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
            function HasMsgCenterUnReadMsg()
                return DockPage.HasMsgCenterUnReadMsg();
            end
        </script>
        <kp:redtip style="position:relative;margin-left:66px;margin-top:-66px;" onupdate='<%%= HasMsgCenterUnReadMsg()%%>' ></kp:redtip>
        ]],"");
    elseif (id == "user_tip") then
        -- 任务
        if DockPage.isShowTaskIconEffect then
            -- 判断下是否有未完成的任务
            -- 日常任务
            
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

            local QuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestPage.lua");
            local quest_page_open = QuestPage.IsOpen()
            if not is_all_task_complete and not quest_page_open then
                bg = ""
                tip_str = [[
                    <div style="position:relative;margin-left:0px;margin-top:-80px;width:100px;height:80px;background: Texture/Aries/Creator/keepwork/dock/btn3_renwu_32bits.png#0 0 100 80" ></div>                
                    <div style="position:relative;margin-left:18px;margin-top:-80px;width:64px;height:64px;background:" >
                        <img uiname="checkin_animator" zorder="100" enabled="false" class="animated_task_icon_overlay" width="64" height="64"/>
                    </div>
                    ]]
            end
        end

    elseif (id == "present") then
        if not GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
            return string.format([[                
                <input type="button" name='%s' onclick="OnClickTop" style="width:100px;height:80px;background:url(%s)"/>
            ]],node.id,node.bg);
        else
            return ''
        end
    end

    local s = string.format([[
        <input type="button" name='%s' onclick="OnClickTop" style="width:100px;height:80px;background:url(%s)"/>
        %s
    ]],node.id,bg,tip_str);
    return s;
end

function DockPage.RenderButton_2(index)
    local node = DockPage.top_line_2[index];
    local tip_str = "";
    local id = node.id;   
    if(id == "checkin")then
        tip_str = string.format([[
        <script type="text/npl" refresh="false">
            local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua")
            function HasCheckedToday()
                return (not ParacraftLearningRoomDailyPage.HasCheckedToday());
            end
        </script>
        <kp:redtip style="position:relative;margin-left:66px;margin-top:-66px;" onupdate='<%%= HasCheckedToday()%%>' ></kp:redtip>
        ]],"");
    end
    local s = string.format([[
        <input type="button" name='%s' onclick="OnClickTop" style="width:100px;height:80px;background:url(%s)"/>
        %s
    ]],node.id,node.bg,tip_str);
    return s;
end

function DockPage.HandleFriendsRedTip(is_repeat)
	if not DockPage.is_show then
		return
    end

    local function repeat_cb()
        if is_repeat then
            commonlib.TimerManager.SetTimeout(function()
                if not DockPage.is_show then
                    return
                end            
                DockPage.HandleFriendsRedTip(is_repeat)
            end, 60000)
        end
    end

    local FriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
    if FriendsPage.GetIsOpen() then
        repeat_cb()
    else
        FriendManager:LoadAllUnReadMsgs(function ()
            -- 处理未读消息
            if FriendManager.unread_msgs and FriendManager.unread_msgs.data then
                for k, v in pairs(FriendManager.unread_msgs.data) do
                    if v.unReadCnt and v.unReadCnt > 0 then
                        DockPage.ChangeFriendRedTipState(true)
                        break
                    end
                end
            end

            

            -- if UserData then
            --     DockPage.GetFriendsFansData()
            -- end
    
            repeat_cb()
        end, true);
    end
end

function DockPage.HandleFriendsFansLocalData()
    local id = UserData.id or 0
	local filepath = string.format("chat_content/%s_fans_list.txt", id)
    local file = ParaIO.open(filepath, "r");
    if(file:IsValid()) then
        local text = file:GetText();
        DockPage.FriendsFansData = commonlib.Json.Decode(text)
        file:close();
    end
    if DockPage.FriendsFansData == nil then
        DockPage.FriendsFansData = {}
        keepwork.user.followers({
            username=search_text,
            headers = {
                ["x-per-page"] = 200,
                ["x-page"] = 1,
            },
            userId = UserData.id,
        },function(err, msg, data)
            if err == 200 then
                for k, v in pairs(data.rows) do
                    if not v.isFriend then
                        DockPage.FriendsFansData[v.id] = v
                    end
                end
            end
        end)

        DockPage.SaveFriendsFansLocalData()
    end


	local filepath = string.format("chat_content/%s_refuse_list.txt", id)
    local file = ParaIO.open(filepath, "r");
    if(file:IsValid()) then
        local text = file:GetText();
        DockPage.RefuseFansList = commonlib.Json.Decode(text) or {}
        file:close();
    end
end

function DockPage.GetFriendsFansData()
    keepwork.user.followers({
        username=search_text,
        headers = {
            ["x-per-page"] = 200,
            ["x-page"] = 1,
        },
        userId = UserData.id,
    },function(err, msg, data)
        if err == 200 then
            -- FriendsPage.HandleFriendsFansData(data.rows)
            -- DockPage.FriendsFansData = {}
            DockPage.is_show_apply_red_tip = false
            local fans_list = {}

            for k, v in pairs(data.rows) do
                -- 没有说明是新增的 但也可能是拒绝列表里面的
                if not v.isFriend then
                    if DockPage.FriendsFansData[v.id] == nil and DockPage.FriendsFansData[tostring(v.id)] == nil and DockPage.RefuseFansList[v.id] == nil then
                        DockPage.is_show_apply_red_tip = true
                    end
    
                    fans_list[v.id] = v
                end

            end

            DockPage.FriendsFansData = fans_list

            if DockPage.is_show_apply_red_tip then
                DockPage.ChangeFriendRedTipState(true)
            end
        end
    end)
end

function DockPage.SaveFriendsFansLocalData()
    local id = UserData.id or 0
	local filepath = string.format("chat_content/%s_fans_list.txt", id)
	local conten_str = commonlib.Json.Encode(DockPage.FriendsFansData or {})
    ParaIO.CreateDirectory(filepath);
	local file = ParaIO.open(filepath, "w");
	if(file:IsValid()) then
		file:WriteString(conten_str);
		file:close();
    end
end

function DockPage.ChangeFriendRedTipState(state)
    if state ~= DockPage.show_friend_red_tip then
        DockPage.show_friend_red_tip = state
        DockPage.RefreshPage()
    end
end

function DockPage.HasMsgCenterUnReadMsg()
    return DockPage.GetMsgCenterUnReadNum() > 0 or EmailManager.IsHaveNew()
end

function DockPage.HandMsgCenterMsgData()    
    EmailManager.Init(true, function()
        keepwork.msgcenter.unReadCount({
        },function(err, msg, data)
            if err == 200 then
                local all_count = 0
                for k, v in pairs(data.data) do
                    all_count = all_count + v
                end
                DockPage.SetMsgCenterUnReadNum(all_count)
                GameLogic.GetFilters():apply_filters('update_msgcenter_unread_num', all_count)
                if DockPage.is_show and DockPage.page then
                    DockPage.RefreshPage()
                end 
            end
        end)
    end) --获取邮件
end

function DockPage.SetMsgCenterUnReadNum(num)
    DockPage.MsgCenterUnReadNum = num or 0
end

function DockPage.GetMsgCenterUnReadNum()
    return DockPage.MsgCenterUnReadNum or 0
end

function DockPage.CheckIsTaskCompelete()
    commonlib.TimerManager.SetTimeout(function()
        local profile = KeepWorkItemManager.GetProfile()
        -- 是否实名认证
    --    if GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
    --         GameLogic.QuestAction.SetValue("40002_1",1);
    --    end 
    
        -- 是否新的实名认证任务
       if GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
            GameLogic.QuestAction.SetValue("40006_1",1);
       end
    
       -- 是否选择了学校
       if profile and profile.schoolId and profile.schoolId > 0 then
            GameLogic.QuestAction.SetValue("40003_1",1);
       end
    
       -- 是否已选择了区域
       if profile and profile.region and profile.region.hasChildren == 0 then
            GameLogic.QuestAction.SetValue("40004_1",1);
       end
       DockPage.RefreshPage()

       GameLogic.QuestAction.SetDailyTaskValue("40008_1",1)

       local Act51AskAlert = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Act51Ask/Act51AskAlert.lua")
       Act51AskAlert.CheckGetVipItem()

       GameLogic.QuestAction.CheckSummerGameTask()
    end, 1000)
end

function DockPage.ShowCampIcon()
    -- if not System.options.isDevMode then
    --     return
    -- end

    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
    local world_id = WorldCommon.GetWorldTag("kpProjectId");
    local camp_id_list = {
        ONLINE = 41570,
        RELEASE = 1471,
    }
    local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
    local httpwrapper_version = HttpWrapper.GetDevVersion();
    local camp_id = camp_id_list[httpwrapper_version]
    if tonumber(world_id) == camp_id then
        local DockCampIcon = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockCampIcon.lua");
        DockCampIcon.Show();
    end
end

function DockPage.ShowSummerCampIcon()
    -- if not System.options.isDevMode then
    --     return
    -- end
    if DockPage.page == nil or not DockPage.page:IsVisible() then
        return
    end

    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
    local world_id = WorldCommon.GetWorldTag("kpProjectId");
    local camp_id_list = {
        ONLINE = 70351,
        RELEASE = 20669,
    }
    local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
    local httpwrapper_version = HttpWrapper.GetDevVersion();
    local camp_id = camp_id_list[httpwrapper_version]

    if tonumber(world_id) == camp_id then
        local has_icon = false
        for key, v in pairs(DockPage.top_line_2) do
            if v.id == "summer_camp_main" then
                has_icon = true
                v.enabled2 = true
            end
        end

        if not has_icon then
            table.insert(DockPage.top_line_2, 1, { label = L"夏令营主ui", id = "summer_camp_main", enabled2 = true, bg="Texture/Aries/Creator/keepwork/SummerCamp/btn3_summer_camp_32bits.png#0 0 100 80", })
        end
        
        DockPage.RefreshPage()
    else
        for key, v in pairs(DockPage.top_line_2) do
            if v.id == "summer_camp_main" then
                v.enabled2 = false
            end
        end

        DockPage.RefreshPage()
    end
end

function DockPage.IsInSchoolAndInLearnTime()
    local where = GameLogic.GetFilters():apply_filters('service.session.get_user_where')
    if where == "SCHOOL" then
        if not DockPage.CheckCanIsShowVipTime() then
            return false
        end
    end
    return true
end

--根据时间戳获取星期几
function DockPage.GetWeekNum(time_stamp)
    time_stamp = time_stamp or 0
    local weekNum = os.date("*t",time_stamp).wday  -1
    if weekNum == 0 then
        weekNum = 7
    end
    return weekNum
end

function DockPage.GetMonthAndDay(time_stamp)
    local year = os.date("%Y", time_stamp)	
    local month = os.date("%m", time_stamp)
	local day = os.date("%d", time_stamp)

    return tonumber(year),tonumber(month),tonumber(day)
end

function DockPage.IsWinterAndSummer(server_time)
    local year,month,day = DockPage.GetMonthAndDay(server_time)
    local isHoliday = false
    local time_stamp1 = os.time({year = year, month = 1, day = 15, hour=0, minute=0, second=0})
    local time_stamp2 = os.time({year = year, month = 2, day = 26, hour=0, minute=0, second=0})
    if server_time >= time_stamp1 and server_time <= time_stamp2 then
        isHoliday = true
    end
    time_stamp1 = os.time({year = year, month = 7, day = 1, hour=0, minute=0, second=0})
    time_stamp2 = os.time({year = year, month = 9, day = 2, hour=0, minute=0, second=0})
    if server_time >= time_stamp1 and server_time <= time_stamp2 then
        isHoliday = true
    end
    --寒假
    -- if (month == 1 and day >= 15) or (month == 2 and day <= 25) then
    --     isHoliday = true
    -- end
    
    -- --暑假
    -- if (month == 7 and day >= 1) or month == 8  or  (month == 9 and day ==1) then
    --     isHoliday = true
    -- end
    return isHoliday
end

function DockPage.CheckCanIsShowVipTime()
    local server_time = GameLogic.QuestAction.GetServerTime()
    if DockPage.IsWinterAndSummer(server_time) then
        return true
    end
    local today_weehours = commonlib.timehelp.GetWeeHoursTimeStamp(server_time)
    local week_day = DockPage.GetWeekNum(server_time)
    if week_day ~= 6 and week_day ~= 7  then
        local limit_time_stamp = today_weehours + 16 * 60 * 60 + 30 * 60
        if server_time < limit_time_stamp then
            return false
        end
    end
    return true
end

function DockPage.CanShowCampVip()
    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
    local world_id = WorldCommon.GetWorldTag("kpProjectId");
    local camp_id_list = {
        ONLINE = 41570,
        RELEASE = 1471,
    }
    local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
    local httpwrapper_version = HttpWrapper.GetDevVersion();
    local camp_id = camp_id_list[httpwrapper_version]
    if tonumber(world_id) == camp_id then
        return true
    end

    return false
end

function DockPage.FreshHomeWorkIcon()
    local ai_homework = GameLogic.QuestAction.GetAiHomeWork()
    if #ai_homework > 0 then
        local has_icon = false
        for key, v in pairs(DockPage.top_line_2) do
            if v.id == "homework" then
                has_icon = true
                v.enabled2 = true
            end
        end

        if not has_icon then
            table.insert(DockPage.top_line_2, 1, { label = L"作业", id = "homework", enabled2 = true, bg="Texture/Aries/Creator/keepwork/dock/btn3_zuoye_32bits.png#0 0 100 80", })
        end
        
        DockPage.RefreshPage()
    else
        for key, v in pairs(DockPage.top_line_2) do
            if v.id == "homework" then
                v.enabled2 = false
            end
        end

        DockPage.RefreshPage()
    end
end
function DockPage.SetMcmlNodeVisible(name, v)
	local uiobj = DockPage.GetContainerObj(name);
	if(uiobj and uiobj:IsValid()) then
		uiobj.visible = v;
	end
end
function DockPage.GetContainerObj(name)
	if(DockPage.page)then
		local mcmlNode = DockPage.page:GetNode(name);
		if(mcmlNode and mcmlNode.uiobject_id)then
			local uiobj = ParaUI.GetUIObject(mcmlNode.uiobject_id);
			return uiobj;
		end
	end
end
function DockPage.SetUIVisible_LeftTop(v)
	DockPage.SetMcmlNodeVisible("left_top_container", v)
end
function DockPage.SetUIVisible_CenterBottom(v)
	DockPage.SetMcmlNodeVisible("center_bottom_container", v)
end
function DockPage.SetUIVisible_RightBottom(v)
	DockPage.SetMcmlNodeVisible("right_bottom_container", v)
end
function DockPage.SetUIVisible_RightTop(v)
	DockPage.SetMcmlNodeVisible("right_top_container", v)
	DockPage.SetMcmlNodeVisible("btn_ziyuan_container", v)
	DockPage.SetMcmlNodeVisible("btn_xiaoyuan_container", v)
end
function DockPage.SetUIVisible_Map(v)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMinimapWnd.lua");
	local ParaWorldMinimapWnd = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldMinimapWnd");
	if(v)then
		ParaWorldMinimapWnd:Show();
	else
		ParaWorldMinimapWnd:Close();
	end
end
function DockPage.CheckRedSummerCampUIVisible()
    local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
	local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
	local list = DockPage.hide_ui_world_ids[HttpWrapper.GetDevVersion()];
	local visible = true;
    if(list)then
		local projectId = GameLogic.options:GetProjectId();
        projectId = tonumber(projectId);
        for k,id in ipairs(list) do
            if(id == projectId)then
                visible = false;
            end
        end
    end
	DockPage.SetUIVisible_RightTop(visible)
	DockPage.SetUIVisible_LeftTop(not visible)
end