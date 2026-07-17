--[[
Title: OperateMenuPage
Author(s): pbb
Date: 2024/11/16
Desc:  
Use Lib:
-------------------------------------------------------
--用户操作菜单界面
local OperateMenuPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/OperateMenuPage.lua");
OperateMenuPage.ShowPage(type,data)
--]]

NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatChannel.lua");
local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatEdit.lua");
local ChatEdit = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatEdit");

local OperateMenuPage = NPL.export()

--[[
{
    commonVip=1,
    modelUrl="character/CC/02human/CustomGeoset/actor.x",
    nickname="nihao",
    portrait="Texture/Aries/Creator/keepwork/UserInfo/renwu_32bits.png",
    scale=1,
    skin="1#201#301#401#501#801#901#@1:Texture/blocks/CustomGeoset/hair/Avatar_boy_hair_01.png;2:Texture/blocks/CustomGeoset/body/Avatar_boy_body_default.png;3:Texture/blocks/Paperman/eye/eye_boy_fps10_a001.png;4:Texture/blocks/Paperman/mouth/mouth_01.png;5:Texture/blocks/CustomGeoset/leg/Avatar_boy_leg_default.png;6:Texture/blocks/CustomGeoset/main/Avatar_tsj.png",
    userId=1298,
    username="deng123457",
    vip=1 
  } 
]]

local MENU_TYPE = {
    TYPE_CHAT_CHANNEL = 1, -- 聊天频道 （点击频道列表中用户名称）
    TYPE_CHAT_TEAM = 2, -- 队伍 （组队系统中点击队伍角色）
    TYPE_CHAT_USER = 3, -- 其他用户（点击场景中的其他用户
    TYPE_CHAT_TEAM_MAIN = 4, -- 主页面（点击主页面中的队伍）
}

local operate_users = {
    {text=L"查看信息" ,value="view_info"},
    {text=L"添加好友" ,value="add_friend"},
    {text=L"悄悄话"     ,value="private_chat"},
    {text=L"邀请组队" ,value="invite_team"},
    {text=L"复制名字" ,value="copy_name"},
    {text=L"屏蔽" ,value="shield"}
}

local operate_channels = { --大的聊天界面
    {text=L"查看信息" ,value="view_info"},
    {text=L"添加好友" ,value="add_friend"},
    {text=L"悄悄话"     ,value="private_chat"},
    {text=L"邀请组队" ,value="invite_team"},
    {text=L"复制名字" ,value="copy_name"},
    {text=L"屏蔽" ,value="shield"},
    {text=L"举报" ,value="report"},
}

OperateMenuPage.operate_menus = {}

function OperateMenuPage.InitOperateData()
    local self = OperateMenuPage;
    if self.menu_type == MENU_TYPE.TYPE_CHAT_CHANNEL then
        self.operate_menus = operate_channels;
    elseif self.menu_type == MENU_TYPE.TYPE_CHAT_USER then
        self.operate_menus = commonlib.copy(operate_users);
        if self.chatData and type(self.chatData) == "table" then
            self.operate_menus[#self.operate_menus+1] = {text=L"举报" ,value="report"};
        end
    elseif self.menu_type == MENU_TYPE.TYPE_CHAT_TEAM or self.menu_type == MENU_TYPE.TYPE_CHAT_TEAM_MAIN then
        local myUserId = Mod.WorldShare.Store:Get("user/userId");
        if myUserId == self.menu_data.userId then -- 自己
            self.operate_menus = {
                -- {text=L"复制名字" ,value="copy_name"},
                {text=L"离开队伍" ,value="leave_team"},
            }
        else
            if self.isLeader then
                self.operate_menus = {
                    {text=L"悄悄话"     ,value="private_chat"},
                    {text=L"添加好友" ,value="add_friend"},
                    {text=L"查看信息" ,value="view_info"},
                    --{text=L"复制名字" ,value="copy_name"},
                    {text=L"踢出队伍" ,value="kick_out_team"},
                    ---- {text=L"设为队长" ,value="set_leader_team"}, --暂时做不了
                }
            else
                self.operate_menus = {
                    {text=L"悄悄话"     ,value="private_chat"},
                    {text=L"添加好友" ,value="add_friend"},
                    {text=L"查看信息" ,value="view_info"},
                    --{text=L"复制名字" ,value="copy_name"},
                }
            end
            if self.menu_type == MENU_TYPE.TYPE_CHAT_TEAM_MAIN then
                table.remove(self.operate_menus, 1) -- 主页面不显示悄悄话
            end
        end
    end
end

function OperateMenuPage.OnInit()
	local self = OperateMenuPage;
	self.page = document:GetPageCtrl();
end

function OperateMenuPage.ClosePage()
	if(OperateMenuPage.page)then
		OperateMenuPage.page:CloseWindow();
		OperateMenuPage.page = nil;
	end
end

function OperateMenuPage.ShowPage(menu_type,data,isLeader,chatData, x, y)
    if not System.options.isCommunity then
        return
    end
    if not menu_type or not data then
        return;
    end
    local self = OperateMenuPage;
	if self.page then
		self.ClosePage()
		return
	end
    self.menu_type = menu_type;
    self.menu_data = data;
    self.isLeader = isLeader
	self.last_caret = ChatEdit.GetCurCaretPosition();
    self.chatData = chatData
    self.InitOperateData();
    OperateMenuPage.ShowMenuPanel(self.operate_menus, x, y)
end


function OperateMenuPage.ShowMenuPanel(options, x, y)
    if not options or next(options) == nil then
        return
    end
    local num = #options;
    if num == 0 then
        return
    end
	local menuStyle = commonlib.copy(CommonCtrl.ContextMenu.DefaultStyle)
	menuStyle.menuitemHeight = 46
	menuStyle.item_bg = "Texture/Aries/Creator/keepwork/community_32bits.png;344 7 32 32:14 14 14 14"
	menuStyle.menu_bg = "Texture/Aries/Creator/keepwork/community_32bits.png;307 8 32 32:14 14 14 14"
	menuStyle.level1itemcolor = "#A8A7B0FF"
	menuStyle.mouseover_textcolor = "#ffffff"
	menuStyle.textFont = "System;16;bold"
	local ctl = OperateMenuPage.contextMenuCtrl;
	if(not ctl)then
		ctl = CommonCtrl.ContextMenu:new{
			name = "OperateMenuPage.contextMenuCtrl",
			width = 100,
			height = num * menuStyle.menuitemHeight, 
			onclick = OperateMenuPage.OnClickContextMenuItem,
			style = menuStyle,
		};
		OperateMenuPage.contextMenuCtrl = ctl;
		ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "root_node", Type = "Group", NodeHeight = 0 });
	end
	local node = ctl.RootNode:GetChild(1);
	if node then
		node:ClearAllChildren();
        for k, v in pairs(options) do
            local text = v.text or ""
            local value = v.value or ""
            local tree_node = CommonCtrl.TreeNode:new{Text = text, Name = value, Type = "Menuitem", onclick = nil, };
            node:AddChild(tree_node);
        end
	end
    if(not x) then
        x, y = ParaUI.GetMousePosition();
    end
	ctl:Show(x + 60, y);
end

function OperateMenuPage.HideMenuPanel()
	local ctl = OperateMenuPage.contextMenuCtrl;
	if(ctl)then
		ctl:Hide();
	end
end

function OperateMenuPage.OnClickContextMenuItem(node)
	local name = node.Name
    if not name  or name == '' then
        return
    end
	
	if name == "invite_team" then
        OperateMenuPage.InviteTeam()
    elseif name == "private_chat" then
        OperateMenuPage.PrivateChat()
    elseif name == "add_friend" then
        OperateMenuPage.AddFriend()
    elseif name == "view_info" then
        OperateMenuPage.ShowUserInfo()
    elseif name == "copy_name" then
        OperateMenuPage.CopyName()
    elseif name == "leave_team" then
        OperateMenuPage.LeaveTeam()
    elseif name == "kick_out_team" then
        OperateMenuPage.KickOutTeam()
    elseif name == "report" then --举报
        OperateMenuPage.ReportUser()
    elseif name == "shield" then --加入黑名单
        OperateMenuPage.AddToBlackList()
    end
	OperateMenuPage.HideMenuPanel();
end

function OperateMenuPage.ShowUserInfo()
    local self = OperateMenuPage;
    local user_info = self.menu_data;
    if not user_info then
        return;
    end
    local user_name = user_info.username or "";
    GameLogic.ShowUserInfoPage(user_name)
end

function OperateMenuPage.PrivateChat()
    local self = OperateMenuPage;
    local user_info = self.menu_data;
    if not user_info then
        return;
    end
    local user_id = user_info.userId or "";
    local symbol = string.format("/w %d ", user_id)
    if(GameLogic.GameMode:CanChat() and GameLogic.options:IsShowChatWnd()) then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatWindow.lua");
        MyCompany.Aries.ChatSystem.ChatWindow.ShowAllPage(true);
        ChatEdit.InsertSymbol(symbol,self.last_caret);
    end
end

function OperateMenuPage.AddFriend()
    local self = OperateMenuPage;
    local user_info = self.menu_data;
    if not user_info then
        return;
    end
    local FriendList = {}
    local user_id = user_info.userId or "";
    keepwork.friend.friendsList({
        headers = {
            ["x-per-page"] = 200,
            ["x-page"] = 1,
        }
	},function(err, msg, data)
		if err == 200 then
			FriendList = data
			for i,v in ipairs(FriendList) do
                if v.friendId == user_id and v.status ~= 2 then
                    GameLogic.AddBBS(nil,L"添加好友失败，你们已经是好友了。")
                    return
                end
            end
            keepwork.friend.applyFriend({
                friendId = user_id,
                remark = "希望成为您的好友",
            },function(err, msg, data)
                if err == 200 then
                    GameLogic.AddBBS("statusBar", L"已向对方发出好友请求，请耐心等待回复。", 5000, "0 255 0");
                end
            end)
		end
	end)
end

function OperateMenuPage.AddFriendByUserName(user_id)
    keepwork.friend.applyFriend({
        friendId = user_id,
        remark = "希望成为您的好友",
    },function(err, msg, data)
        if err == 200 then
            GameLogic.AddBBS("statusBar", L"已向对方发出好友请求，请耐心等待回复。", 5000, "0 255 0");
        end
    end)
end

function OperateMenuPage.InviteTeam()
    local self = OperateMenuPage;
    local user_info = self.menu_data;
    if not user_info then
        return;
    end
    local username = user_info.username or "";
    local TeamManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/TeamManager.lua");
    TeamManager:Connect(nil,function()
        TeamManager:InviteUserToTeam(username)
    end)
end

function OperateMenuPage.LeaveTeam()
    local TeamManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/TeamManager.lua");
    TeamManager:LeaveTeam()
end

function OperateMenuPage.KickOutTeam()
    local self = OperateMenuPage;
    local user_info = self.menu_data;
    if not user_info then
        return;
    end
    local user_name = user_info.username or "";
    local TeamManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/TeamManager.lua");
    TeamManager:KickUserFromTeam(user_name)
end

function OperateMenuPage.SetTeamLeader()
    local self = OperateMenuPage;
    local user_info = self.menu_data;
    if not user_info then
        return;
    end
    
end

function OperateMenuPage.ReportUser()
    local self = OperateMenuPage;
    local user_info = self.menu_data;
    local chatData = self.chatData;
    if not user_info or not chatData then
        return;
    end
    local user_name = user_info.username or "";
    local user_id = user_info.userId or "";
    local reportData = chatData or {};
    -- 频道、发送人、接收人、内容、时间，人工审核后决定后续处理。
    keepwork.chat.reportChatRecord({
        reportUserId = user_id,
        content = reportData,
    },function(err, msg, data)
        if err == 200 then
            GameLogic.AddBBS("statusBar", L"举报成功，我们会尽快处理。", 5000, "0 255 0");
        end
    end)
end

function OperateMenuPage.CopyName()
    local self = OperateMenuPage;
    local user_info = self.menu_data;
    if not user_info then
        return;
    end
    local user_name = user_info.username or "";
    local user_id = user_info.userId or "";
    local text = string.format("%s(%d)", user_name, user_id)
    ParaMisc.CopyTextToClipboard(text)
    GameLogic.AddBBS("statusBar", L"名字已复制到剪贴板", 5000, "0 255 0");
end

function OperateMenuPage.AddToBlackList()
    local self = OperateMenuPage;
    local user_info = self.menu_data;
    if not user_info then
        return;
    end
    local user_id = user_info.userId or "";
    keepwork.friend.addBlacklist({
        friendId = user_id
    },function(err, msg, data)
        if err == 200 then
            GameLogic.AddBBS("statusBar", L"已将对方加入黑名单", 5000, "0 255 0");
        end
    end)
end

