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
local DockPage = NPL.export();
local UserData = nil
DockPage.FriendsFansData = nil
DockPage.RefuseFansList = {}
DockPage.IsShowClassificationPage = false
DockPage.isShowTaskIconEffect = true
DockPage.hide_vip_world_ids = {
    ONLINE = { 18626 },
    RELEASE = { 1236 },
};
DockPage.is_show = true;
DockPage.top_line_1 = {
    { label = L"", },
    { label = L"", },    
    { label = L"实名礼包", id = "present", enabled = true, bg="Texture/Aries/Creator/keepwork/dock/btn3_libao_32bits.png#0 0 100 80", }, 
    { label = L"成长任务", id = "user_tip", enabled = true, bg="Texture/Aries/Creator/keepwork/dock/btn3_renwu1_32bits.png#0 0 100 80", },    
    { label = L"消息中心", id = "msg_center", enabled = true, bg="Texture/Aries/Creator/keepwork/dock/btn3_xiaoxi_32bits.png#0 0 100 80", }, 
    { label = L"活动公告", id = "notice", enabled = true, bg ="Texture/Aries/Creator/keepwork/dock/btn3_gonggao_32bits.png#0 0 100 80"},    
}
DockPage.top_line_2 = {
    { label = L"", },
    { label = L"", },
    { label = L"", },
    { label = L"", },    
    { label = L"成长日记", id = "checkin", enabled2 = true, bg="Texture/Aries/Creator/keepwork/dock/btn3_riji_32bits.png#0 0 100 80", },
    { label = L"玩学课堂", id = "codewar", enabled2 = true, bg="Texture/Aries/Creator/keepwork/dock/btn3_ketang_32bits.png#0 0 100 80", },
}

DockPage.show_friend_red_tip = false

function DockPage.Show(bCommand)
    local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
    if(not KeepWorkItemManager.GetToken())then
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

    -- 每次登陆判断是否弹出活动框
    if Notice and Notice.CheckCanShow() and not MacroCodeCampActIntro.CheckIsInWinCamp() and not bCommand then
        Notice.Show(0)
    end
    --冬令营弹框判断 活动下线
    if MacroCodeCampActIntro.CheckCanShow() and not bCommand then
        MacroCodeCampActIntro.ShowView()
    end

    DockPage.isShowTaskIconEffect = true

    DockPage.CheckIsTaskCompelete()

    DockPage.ShowCampIcon()
    -- ActWeek.GetServerTime(function()
    --     DockPage.RefreshPage(0.01)
    -- end)
end

function DockPage.RefreshPage(time)
    local time = time or 0.01
    if DockPage.page then
        DockPage.InitTopIconData()
        DockPage.page:Refresh(time)
        commonlib.TimerManager.SetTimeout(function()  
            DockPage.InitButton()
        end, 500);
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

    -- print("222222222222222222222222222222222222233333333333333")
    -- echo(temp_top1,true)
    -- echo(temp_top2,true)
end

function DockPage.InitButton()
    local buttons = {"character","work","explore","home","friends","school","vip","study"} -- ,"mall"
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
    local visible;
    if(DockPage.last_page_ctrl)then
        if(id == "character" or DockPage.last_page_ctrl_id == "character")then
            visible = (DockPage.last_page_ctrl.window ~= nil);
        else
            visible = DockPage.last_page_ctrl:IsVisible();
        end
        if(visible)then
            DockPage.last_page_ctrl:CloseWindow();
            DockPage.last_page_ctrl = nil;
            if(DockPage.last_page_ctrl_id)then
                if(DockPage.last_page_ctrl_id == id)then
                    DockPage.last_page_ctrl_id = nil;
                    return true
                end
            end
        end
    else
        DockPage.last_page_ctrl_id = nil;
    end
end

function DockPage.OnClickTop(id)
    if(id == "checkin")then
        ParacraftLearningRoomDailyPage.DoCheckin();
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.checkin");
    elseif(id == "week_quest")then
        local TeachingQuestLinkPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/TeachingQuestLinkPage.lua");
        TeachingQuestLinkPage.ShowPage();
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.week_quest");
    elseif(id == "codewar")then
        local StudyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/StudyPage.lua");
        StudyPage.clickArtOfWar();
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.code_war");
    elseif(id == "web_keepwork_home")then
	    ParaGlobal.ShellExecute("open", "explorer.exe", "https://keepwork.com", "", 1); 
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.web_keepwork_home");
    elseif(id == "user_tip")then
        local QuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestPage.lua");
        QuestPage.Show();
        
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.user_tip");
        DockPage.isShowTaskIconEffect = false
        DockPage.RefreshPage(0.01)
    elseif(id == "msg_center")then
        local MsgCenter = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MsgCenter/MsgCenter.lua");
        MsgCenter.Show();
    elseif(id == "notice")then
        if Notice then
            Notice.Show(1);
        end
    elseif (id == 'present') then
        if not GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
            GameLogic.GetFilters():apply_filters(
                'show_certificate',
                function(result)
                    if (result) then
                        -- GameLogic.AddBBS(nil, L'领取成功', 5000, '0 255 0');
                        DockPage.RefreshPage(0.01)
                        GameLogic.QuestAction.AchieveTask("40006_1", 1, true)
                    end
                end
            );
        end
    elseif (id == 'find_hat') then
        if ActRedhatExchange then
            ActRedhatExchange.ShowView()
        end
    elseif (id == 'act_week') then
        ActWeek.ShowView()
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
    elseif(id == "bag")then
        local UserBagPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserBagPage.lua");
        UserBagPage.ShowPage();
        last_page_ctrl = UserBagPage.GetPageCtrl();
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.bag");
    elseif(id == "work")then
		if(mouse_button == "right") then
            -- the new version            
            last_page_ctrl = GameLogic.GetFilters():apply_filters('show_console_page')
        else
            last_page_ctrl = GameLogic.GetFilters():apply_filters('show_create_page')
        end
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.work");
    elseif(id == "explore")then
        last_page_ctrl = GameLogic.GetFilters():apply_filters('show_offical_worlds_page')
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.explore");
    elseif(id == "study")then
        local QuestAllCourse = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAllCourse.lua")
        QuestAllCourse.Show();
        last_page_ctrl = QuestAllCourse.GetPageCtrl()
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
    elseif(id == "friends")then
        local FriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
        FriendsPage.show_callback = function()
            last_page_ctrl = FriendsPage.GetPageCtrl();
            DockPage.last_page_ctrl = last_page_ctrl;
            DockPage.last_page_ctrl_id = id;
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
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.school");              
    elseif(id == "vip")then
        -- ParacraftLearningRoomDailyPage.OnVIP("dock");
        local VipToolTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipToolTip.lua")
        VipToolTip:Init(true)
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.vip");
    elseif(id == "mall")then
        local KeepWorkMallPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallPage.lua");
        KeepWorkMallPage.show_callback = function()
            last_page_ctrl = KeepWorkMallPage.GetPageCtrl();
            DockPage.last_page_ctrl = last_page_ctrl;
            DockPage.last_page_ctrl_id = id;
        end
        KeepWorkMallPage.Show();
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.mall");
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
        DockPage.RefreshPage(0.01)
    end
end

function DockPage.HasMsgCenterUnReadMsg()
    return DockPage.GetMsgCenterUnReadNum() > 0
end

function DockPage.HandMsgCenterMsgData(is_need_repeat)
    if not DockPage.is_show then
        return
    end  

    keepwork.msgcenter.unReadCount({
    },function(err, msg, data)
        if err == 200 then
            local all_count = 0
            for k, v in pairs(data.data) do
                all_count = all_count + v
            end
            DockPage.SetMsgCenterUnReadNum(all_count)
            if DockPage.is_show and DockPage.page then
                DockPage.RefreshPage(0.01)
            end 
        end
    end)

    -- if is_need_repeat then
    --     commonlib.TimerManager.SetTimeout(function()          
    --         DockPage.HandMsgCenterMsgData(true)
    --     end, 60000)
    -- end

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
       DockPage.RefreshPage(0.01)

       GameLogic.QuestAction.SetDailyTaskValue("40008_1",1)
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