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
local DockPage = NPL.export();
local UserData = nil
DockPage.FriendsFansData = nil
DockPage.RefuseFansList = {}

DockPage.hide_vip_world_ids = {
    ONLINE = { 18626 },
    RELEASE = { 1236 },
};
DockPage.is_show = true;
DockPage.top_line_1 = {
    { label = L"", },
    { label = L"", },
    { label = L"", },
    { label = L"成长任务", id = "user_tip", enabled = true, bg="Texture/Aries/Creator/keepwork/dock/btn2_chengzhangrenwu_32bits.png#0 0 85 75", },
    { label = L"用户社区", id = "web_keepwork_home", enabled = true, bg="Texture/Aries/Creator/keepwork/dock/btn2_yonghushequ_32bits.png#0 0 85 75", },
    { label = L"大赛", id = "competition", enabled = true, bg="Texture/Aries/Creator/keepwork/dock/btn2_dasai_32bits.png#0 0 85 75", },
}
DockPage.top_line_2 = {
    { label = L"", },
    { label = L"", },
    { label = L"", },
    { label = L"成长日记", id = "checkin", enabled2 = true, bg="Texture/Aries/Creator/keepwork/dock/btn2_chengzhangriji_32bits.png#0 0 85 75", },
    { label = L"实战提升", id = "week_quest", enabled2 = true, bg="Texture/Aries/Creator/keepwork/dock/btn2_shizhan_32bits.png#0 0 85 75", },
    { label = L"玩学课堂", id = "codewar", enabled2 = true, bg="Texture/Aries/Creator/keepwork/dock/btn2_ketang_32bits.png#0 0 85 75", },
}

DockPage.show_friend_red_tip = false

function DockPage.Show()
    local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
    if(not KeepWorkItemManager.GetToken())then
        return
    end
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

    
    DockPage.LoadActivityList();

    KeepWorkItemManager.GetUserInfo(nil,function(err,msg,data)
        if(err ~= 200)then
            return
        end
        UserData = data
        -- DockPage.HandleFriendsFansLocalData()
        DockPage.HandleFriendsRedTip(true);
    end)

    -- 每日首次登陆自动打开任务面板
    DailyTaskManager.OpenDailyTaskView()
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
    if(id == "competition")then
        DockPage.OnActivity();
    elseif(id == "checkin")then
        ParacraftLearningRoomDailyPage.DoCheckin();
    elseif(id == "week_quest")then
        local TeachingQuestLinkPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/TeachingQuestLinkPage.lua");
        TeachingQuestLinkPage.ShowPage();
    elseif(id == "codewar")then
        local StudyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/StudyPage.lua");
        StudyPage.clickArtOfWar();
    elseif(id == "web_keepwork_home")then
	    ParaGlobal.ShellExecute("open", "explorer.exe", "https://keepwork.com", "", 1); 
    elseif(id == "user_tip")then
        local DailyTask = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DailyTask/DailyTask.lua");
        DailyTask.Show();
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
    elseif(id == "bag")then
        local UserBagPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserBagPage.lua");
        UserBagPage.ShowPage();
        last_page_ctrl = UserBagPage.GetPageCtrl();
    elseif(id == "work")then
        --GameLogic.RunCommand("/menu file.loadworld");
            
		if(mouse_button == "right") then
            -- the new version
            local UserConsoleCreate = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Create/Create.lua")
            UserConsoleCreate:Show();
            last_page_ctrl = Mod.WorldShare.Store:Get('page/Mod.WorldShare.UserConsole')
        else
            local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
            UserConsole:ShowPage();
            last_page_ctrl = Mod.WorldShare.Store:Get('page/Mod.WorldShare.UserConsole')
		end
    elseif(id == "explore")then
        local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
        UserConsole.OnClickOfficialWorlds();
        last_page_ctrl = Mod.WorldShare.Store:Get("page/MainPage")
    elseif(id == "study")then
        local StudyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/StudyPage.lua");
        StudyPage.ShowPage();
        last_page_ctrl = StudyPage.GetPageCtrl();
    elseif(id == "home")then
        GameLogic.RunCommand("/loadworld home");
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
        return
    elseif(id == "school")then
        local MySchool = NPL.load("(gl)Mod/WorldShare/cellar/MySchool/MySchool.lua")
        MySchool:Show();
        last_page_ctrl = Mod.WorldShare.Store:Get('page/Mod.WorldShare.MySchool')
    elseif(id == "system")then
        DockPage.OnClick_system_menu();
    elseif(id == "vip")then
        ParacraftLearningRoomDailyPage.OnVIP();
    elseif(id == "mall")then
        local KeepWorkMallPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallPage.lua");
        KeepWorkMallPage.show_callback = function()
            last_page_ctrl = KeepWorkMallPage.GetPageCtrl();
            DockPage.last_page_ctrl = last_page_ctrl;
            DockPage.last_page_ctrl_id = id;
        end
        KeepWorkMallPage.Show();
        return
    else
        --_guihelper.MessageBox(id);
    end
    DockPage.last_page_ctrl = last_page_ctrl;
    DockPage.last_page_ctrl_id = id;

end

function DockPage.OnClick_system_menu()
	local ctl = CommonCtrl.GetControl("OnClick_system_menu");
	if(ctl == nil)then
		ctl = CommonCtrl.ContextMenu:new{
			name = "OnClick_system_menu",
			width = 160,
			height = 160, -- add menuitemHeight(30) with each new item
            AutoPositionMode = "_lt",
			style = CommonCtrl.ContextMenu.DefaultStyle,
		};
		local node = ctl.RootNode;
		local subNode;
		node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "name", Type="Title", NodeHeight = 0 });
		node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "titleseparator", Type="separator", NodeHeight = 0 });
		node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "Quickwords", Name = "actions", Type = "Group", NodeHeight = 0 });
			-- node:AddChild(CommonCtrl.TreeNode:new({Text = L"创建服务器", Name = "ExitGame", Type = "Menuitem", onclick = DockPage.OnClick_Menuitem_server, }));
			node:AddChild(CommonCtrl.TreeNode:new({Text = L"加入服务器", Name = "ExitGame", Type = "Menuitem", onclick = DockPage.OnClick_Menuitem_server_join, }));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "插件管理", Name = "ExitGame", Type = "Menuitem", onclick = DockPage.OnClick_Menuitem_plugin, }));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "联系客服", Name = "ExitGame", Type = "Menuitem", onclick = DockPage.OnClick_Menuitem_service, }));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "系统设置", Name = "ExitGame", Type = "Menuitem", onclick = DockPage.OnClick_Menuitem_system, }));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "退出", Name = "ExitGame", Type = "Menuitem", onclick = DockPage.OnClick_Menuitem_exit, }));
	end
	
	local x,y,width, height = _guihelper.GetLastUIObjectPos();
	ctl:Show(x - 0, y - 140);
end
function DockPage.OnClick_Menuitem_server()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ServerPage.lua");
    local ServerPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.ServerPage");
    ServerPage.ShowPage();
end
function DockPage.OnClick_Menuitem_server_join()
    local Server = NPL.load("(gl)Mod/WorldShare/cellar/Server/Server.lua")
    Server:ShowPage()

    --local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
    --UserConsole:ShowHistoryManager()

end
function DockPage.OnClick_Menuitem_plugin()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Login/SelectModulePage.lua");
    local SelectModulePage = commonlib.gettable("MyCompany.Aries.Game.MainLogin.SelectModulePage")
    SelectModulePage.ShowPage()
end
function DockPage.OnClick_Menuitem_service()
	ParaGlobal.ShellExecute("open", "explorer.exe", "https://keepwork.com/official/docs/FAQ/questions", "", 1); 
end
function DockPage.OnClick_Menuitem_system()
    GameLogic.RunCommand("/menu file.settings");
end
function DockPage.OnClick_Menuitem_exit()
    GameLogic.RunCommand("/menu file.exit");
end
function DockPage.FindUIControl(name)
    if(not name or not DockPage.page)then
        return
    end
    return   DockPage.page:FindUIControl(name);
end
function DockPage.OnActivity()
	ParaGlobal.ShellExecute("open", "explorer.exe", "https://keepwork.com/cp/home", "", 1); 
    if(DockPage.RedTip_Activity_Len and DockPage.RedTip_Activity_Len > 0)then
	    local profile = KeepWorkItemManager.GetProfile();
        local userId = profile.id;
        local key = string.format("RedTip_Activity_%s_%d", userId, DockPage.RedTip_Activity_Len);
        GameLogic.GetPlayerController():SaveLocalData(key, true, true);
    end
    DockPage.page:Refresh(0);
end
function DockPage.RedTip_Activity_Checked()
    local checked = true;
    if(DockPage.RedTip_Activity_Len and DockPage.RedTip_Activity_Len > 0)then
        local profile = KeepWorkItemManager.GetProfile();
        local userId = profile.id;
        local key = string.format("RedTip_Activity_%s_%d", userId, DockPage.RedTip_Activity_Len);
        checked = GameLogic.GetPlayerController():LoadLocalData(key,false,true);
    end
    return checked;
end
function DockPage.RenderButton_1(index)
    local node = DockPage.top_line_1[index];
    local tip_str = "";
    local id = node.id;
    if(id == "competition")then
        tip_str = string.format([[
        <script type="text/npl" refresh="false">
            local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
            function RedTip_Activity_Checked()
                return (not DockPage.RedTip_Activity_Checked());
            end
        </script>
        <kp:redtip style="position:relative;margin-left:53px;margin-top:-74px;" onupdate='<%%= RedTip_Activity_Checked()%%>' ></kp:redtip>
        ]],"");
    end
    local s = string.format([[
        <input type="button" name='%s' onclick="OnClickTop" style="width:85px;height:75px;background:url(%s)"/>
        %s
    ]],node.id,node.bg,tip_str);
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
        <kp:redtip style="position:relative;margin-left:53px;margin-top:-74px;" onupdate='<%%= HasCheckedToday()%%>' ></kp:redtip>
        ]],"");
	elseif (id == "week_quest") then
        tip_str = string.format([[
        <script type="text/npl" refresh="false">
            local TeachingQuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestPage.lua");
            function HasTaskInProgress()
				return TeachingQuestPage.HasTaskInProgress();
            end
        </script>
        <kp:redtip style="position:relative;margin-left:53px;margin-top:-74px;" onupdate='<%%= HasTaskInProgress()%%>' ></kp:redtip>
        ]],"");
    end
    local s = string.format([[
        <input type="button" name='%s' onclick="OnClickTop" style="width:85px;height:75px;background:url(%s)"/>
        %s
    ]],node.id,node.bg,tip_str);
    return s;
end


function DockPage.LoadActivityList(callback)
    keepwork.user.activity_list({},function(err, msg, data)
        if(err ~= 200)then
            return
        end
        if(data and data.data)then
            data = data.data;
            local len = #data;
            DockPage.RedTip_Activity_Len = len;
            DockPage.page:Refresh(0);
        end
    end)
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
        DockPage.page:Refresh(0);
    end
end

