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
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/PageCtrl.lua");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local FriendManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendManager.lua");
local InviteFriend = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/InviteFriend/InviteFriend.lua")
local EmailManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Email/EmailManager.lua");

local DockPage = NPL.export();
local UserData = nil
DockPage.FriendsFansData = nil
DockPage.RefuseFansList = {}
DockPage.hide_vip_world_ids = {
    ONLINE = { 18626 },
    RELEASE = { 1236 },
};
DockPage.hide_ui_world_ids = {
    ONLINE = { 70351 },
    RELEASE = { 20669 },
};
DockPage.is_show = false;
DockPage.pageCfg = {    
    {name = "esc", enabled = true,  align="_rt",  width=100,height=90, bg="Texture/Aries/Creator/keepwork/dock/xitongESC_98x94_32bits.png#0 0 100 90", },
    {name = "present",  enabled = true,  align="_rt", width=100,height=90, bg="Texture/Aries/Creator/keepwork/dock/btn3_libao_32bits.png#0 0 100 90", }, 
    {name = "mall", enabled = true,  align="_rt", width=100,height=90, bg="Texture/Aries/Creator/keepwork/dock/ziyuan_101x93_32bits.png#0 0 100 90"},
    {name = "invitefriend",  enabled = true,  align="_rt", width=100,height=90, bg="Texture/Aries/Creator/keepwork/dock/btn3_jieban_32bits.png#0 0 100 90", }, 
    {name = "school_center", enabled = true,  align="_rt", width=100,height=90, bg="Texture/Aries/Creator/keepwork/dock/xiaoyuan_98x94_32bits.png#0 0 100 90"},
    
    {name = "work", enabled = true,  align="_ctb", width=137,height=132, bg="Texture/Aries/Creator/keepwork/dock/btn_chuangzao_32bits.png#0 0 137 132"},
    {name = "explore", enabled = true,  align="_ctb", width=137,height=132, bg="Texture/Aries/Creator/keepwork/dock/btn_tansuo_32bits.png#0 0 137 132"},
    {name = "study", enabled = true,  align="_ctb", width=137,height=132, bg="Texture/Aries/Creator/keepwork/dock/btn_zhishi_32bits.png#0 0 137 132"},

    {name = "vip", enabled = true,  align="_rb", width = 85,height = 80, bg="Texture/Aries/Creator/keepwork/dock/btn2_huiyuan_32bits.png#0 0 85 80"},
    {name = "friends_1", enabled = true,  align="_rb", width = 85,height = 80, bg="Texture/Aries/Creator/keepwork/dock/btn2_haoyou_32bits.png#0 0 85 80"},
    {name = "school", enabled = true,  align="_rb", width = 85,height = 80, bg="Texture/Aries/Creator/keepwork/dock/btn2_xuexiao_32bits.png#0 0 85 80"},
    {name = "home", enabled = true,  align="_rb", width = 85,height = 80, bg="Texture/Aries/Creator/keepwork/dock/btn2_home_32bits.png#0 0 85 80"},
    {name = "character", enabled = true,  align="_rb", width = 85,height = 80, bg="Texture/Aries/Creator/keepwork/dock/btn2_renwu_32bits.png#0 0 85 80"},
}

DockPage.animalPageCfg = {
    {name = "winter_camp",  enabled = true,  align="_lt", width=100,height=90, bg="Texture/Aries/Creator/keepwork/WinterGames/dongao_101x93_32bits.png#0 0 101 93", },  
    {name = "papa",  enabled = true,  align="_lt", width=100,height=90, bg="Texture/Aries/Creator/keepwork/WinterGames/papa_101x93_32bits.png#0 0 101 93", }, 
    {name = "lala",  enabled = true,  align="_lt", width=100,height=90, bg="Texture/Aries/Creator/keepwork/WinterGames/lala_101x93_32bits.png#0 0 101 93", },    
    {name = "kaka",  enabled = true,  align="_lt", width=100,height=90, bg="Texture/Aries/Creator/keepwork/WinterGames/kaka_101x93_32bits.png#0 0 101 93", }, 
    {name = "huanbao",  enabled = true,  align="_lt", width=100,height=90, bg ="Texture/Aries/Creator/keepwork/WinterGames/huanbao_101x93_32bits.png#0 0 101 93"},
}

DockPage.show_data = {}


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
    if DockPage.IsShow() then
        GameLogic.DockManager:SetAllDockVisible(true) 
        return 
    end
    DockPage.InitIconData()
    DockPage.ShowDock()
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

end

function DockPage.ClosePage()
    DockPage.is_show = false; 
    GameLogic.DockManager:RemoveAllDock()   
end

--处理顶部icon数据，顶部数据的最大显示范围是6
function DockPage.RereshTopData()
    for k,v  in pairs(DockPage.pageCfg) do
        if v.name == "present" and GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
            v.enabled = false
        end
        if v.name == "vip" and not DockPage.CanShowVip() then
            v.enabled = false
        end
    end
end

function DockPage.InitIconData()
    DockPage.RereshTopData()
    
    local isAnimal = not DockPage.IsShowCenterUI()
    if isAnimal then
        DockPage.show_data = commonlib.copy(DockPage.animalPageCfg)
    else
        for k,v in pairs (DockPage.pageCfg) do
            if v.enabled then
                DockPage.show_data[#DockPage.show_data + 1] = v
            end
        end
    end

    
end

function DockPage.ShowDock()
    for k,v in pairs(DockPage.show_data) do
        local name = v.name
        local dock = GameLogic.DockManager:AddNewDock(v)
        dock:Connect("onclickEvent",function()
            if(name) then
                DockPage.OnClickDock(name)
            end
        end)
        dock:Connect("onMouseEnter",function()
            if(name) then
                DockPage.OnMouseEnter(name,dock)
            end
        end)
        dock:Connect("onMouseLeave",function()
            if(name) then
                DockPage.OnMouseLeave(name,dock)
            end
        end)
    end
    print("dockpage================")
    echo(DockPage.show_data,true)
end

function DockPage.Hide()
    if DockPage.IsShow() then
        GameLogic.DockManager:SetAllDockVisible(false) 
    end
end


function DockPage.IsShow()
    return DockPage.is_show;
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
        -- DockPage.RefreshPage()
        if DockPage.show_friend_red_tip == true then
            local redParams = {
                width = 12,
                height = 12,
                x_offset = 74,
                y_offset = 2,
            }
            GameLogic.DockManager:AddRedTip("friends_1",redParams)
        else
            GameLogic.DockManager:RemoveRedTip("friends_1")
        end
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

function DockPage.SetUIVisible_LeftTop(v)
    GameLogic.DockManager:SetDockItemsVisivleByAlign("_lt",v)
end
function DockPage.SetUIVisible_CenterBottom(v)
	GameLogic.DockManager:SetDockItemsVisivleByAlign("_ctb",v)
end
function DockPage.SetUIVisible_RightBottom(v)
	GameLogic.DockManager:SetDockItemsVisivleByAlign("_rb",v)
end
function DockPage.SetUIVisible_RightTop(v)
	GameLogic.DockManager:SetDockItemsVisivleByAlign("_rt",v)
end
function DockPage.SetUIVisible_Map(v)
    GameLogic.DockManager:SetDockVisible("mini_map",v)
end

function DockPage.CanShowVip()
    if not DockPage.IsInSchoolAndInLearnTime() then
        return false
    end
    local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
    local list = DockPage.hide_vip_world_ids[HttpWrapper.GetDevVersion()];
    if(list)then
        local projectId = GameLogic.options:GetProjectId();
        projectId = tonumber(projectId);
        for k,id in ipairs(list) do
            if(id == projectId)then
                return false;
            end
        end
    end
    return true;
end

function DockPage.IsShowCenterUI()
    local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
	local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
    local hide_ui_world_ids = {
        ONLINE = { 119551,114607,91056,128252,128291,132939},
        RELEASE = {},
    };
    local worlds = hide_ui_world_ids[HttpWrapper.GetDevVersion()]
	local visible = true;
    if(worlds)then
		local projectId = GameLogic.options:GetProjectId();
        projectId = tonumber(projectId);
        for k,id in ipairs(worlds) do
            if(id == projectId)then
                visible = false;
            end
        end
    end
    return visible
end

function DockPage.OnClickDock(id)
    if(id == "character")then
        local page = NPL.load("Mod/GeneralGameServerMod/App/ui/page.lua");
        page.ShowUserInfoPage({username = System.User.keepworkUsername});
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.character");
    elseif(id == "work")then
		GameLogic.GetFilters():apply_filters('show_create_page');
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.work");
    elseif(id == "explore")then
        GameLogic.GetFilters():apply_filters('show_offical_worlds_page')
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.explore");
    elseif(id == "study")then
        -- QuestAllCourse.Show();
        -- last_page_ctrl = QuestAllCourse.GetPageCtrl()
        -- table.insert(DockPage.showPages,{id,last_page_ctrl})
        local RedSummerCampCourseScheduling = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseSchedulingV2.lua") 
        RedSummerCampCourseScheduling.ShowView()
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
        FriendsPage.Show();

        -- DockPage.SaveFriendsFansLocalData()
        DockPage.ChangeFriendRedTipState(false)
        DockPage.is_show_apply_red_tip = false

        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.friends");
        return
    elseif(id == "school")then
        GameLogic.GetFilters():apply_filters('cellar.my_school.after_selected_school', function ()
            
            KeepWorkItemManager.LoadProfile(false, function()
                local profile = KeepWorkItemManager.GetProfile()
                -- 是否选择了学校
                if profile and profile.schoolId and profile.schoolId > 0 then
                    GameLogic.QuestAction.AchieveTask("40003_1", 1, true)
                end
            end)
        end);
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.school");              
    elseif(id == "vip")then 
		local VipPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/VipPage.lua");
		VipPage.ShowPage("dock");
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.vip");
    
    elseif id == "esc" then
        GameLogic.ToggleDesktop("esc");    
    elseif (id == 'invitefriend') then
        InviteFriend.ShowView()
        -- table.insert(DockPage.showPages,{id,InviteFriend.GetPageCtrl()})
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.invitefriend");
    elseif(id == "mall")then
        local KeepWorkMallPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallPage.lua");
        KeepWorkMallPage.Show();
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.mall");
        return
    elseif(id == "school_center")then
        local SchoolCenter = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SchoolCenter/SchoolCenter.lua")
        SchoolCenter.OpenPage()
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.school_center");
        return
    elseif (id == 'present') then
        if not GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
            GameLogic.GetFilters():apply_filters(
                'show_certificate',
                function(result)
                    if (result) then
                        
                        GameLogic.QuestAction.AchieveTask("40006_1", 1, true)
                    end
                end
            );
        end
    else
        --_guihelper.MessageBox(id);
    end
end

function DockPage.OnMouseEnter(name,dockItem)
    if dockItem then
        dockItem:SetScaling(1.1,1.1)
    end
end

function DockPage.OnMouseLeave(name,dockItem)
    if dockItem then
        dockItem:SetScaling(1,1)
    end
end

function DockPage.RefreshPage(delay_time)

end