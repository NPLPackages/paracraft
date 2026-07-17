--[[
Title: FriendsPage
Author(s): yangguiyi
Date: 2020/7/3
Desc:  
Use Lib:
-------------------------------------------------------
local FriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
FriendsPage.Show();
--]]
NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatChannel.lua");
local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
local FriendsPage = NPL.export();
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local Encoding = commonlib.gettable("System.Encoding");
local FriendManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendManager.lua");
local FriendChatPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendChatPage.lua");
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");

local UserData = {}
FriendsPage.UnreadMsg = {}
local FriendList = nil -- 好友列表
local TypeToCb = {}

FriendsPage.Current_Item_DS = {};
FriendsPage.index = 2;

local IsOpen = false

local page;
local DateTool = os.date
local TopBtListType = {
	RecentContact = 1,
	Friend = 2,
	FriendApply = 3,

	-- 下面的类型暂时不用
	ClassMate = 4,
	Following = 5,
	Followers = 6,
}

function FriendsPage.OnInit()
	page = document:GetPageCtrl();

	TypeToCb[TopBtListType.RecentContact] = FriendsPage.GetRecentContactLlist
	TypeToCb[TopBtListType.Friend] = FriendsPage.GetFriendsLlist
	TypeToCb[TopBtListType.FriendApply] = FriendsPage.GetFriendApplyLlist

	-- 下面的类型暂时不用
	TypeToCb[TopBtListType.ClassMate] = FriendsPage.GetClassMateLlist
	TypeToCb[TopBtListType.Following] = FriendsPage.GetFollowingLlist
	TypeToCb[TopBtListType.Followers] = FriendsPage.GetFollowersLlist
end

function FriendsPage.GetSafeLeft()
	local safeArea = System.Windows.Screen:GetSafeAreaLeft()
	if safeArea > 0 then
		return safeArea + 10
	end
	return 0
end

function FriendsPage.Show(index, msg_content)
	FriendsPage.msg_content = msg_content
	FriendsPage.index = index or 2
	KeepWorkItemManager.GetUserInfo(nil,function(err,msg,data)
        if(err ~= 200)then
            return
		end
		UserData = data
		FriendManager:InitUserData(data)
		FriendManager:LoadAllUnReadMsgs(function()
			-- 处理未读消息
			FriendsPage.UnreadMsg = {}
			if FriendManager.unread_msgs and FriendManager.unread_msgs.data then
				for k, v in pairs(FriendManager.unread_msgs.data) do
					local data = commonlib.clone(v)
					FriendsPage.UnreadMsg[v.latestMsg.senderId] = data
					FriendManager:AddLastChatMsg(v.latestMsg.senderId, data)
				end
			end


			local params = {
				url = "script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.html",
				name = "FriendsPage.Show", 
				isShowTitleBar = false,
				DestroyOnClose = true,
				style = CommonCtrl.WindowFrame.ContainerStyle,
				allowDrag = true,
				enable_esc_key = true,
				zorder = 1,
				isTopLevel = true,
				directPosition = true,
					align = "_ctl",
					x = 10 + FriendsPage.GetSafeLeft(),
					y = 10/2,
					width = 330,
					height = 583,
			};
			System.App.Commands.Call("File.MCMLWindowFrame", params);
			FriendsPage.OnChange(FriendsPage.index);
	
			IsOpen = true

			FriendsPage.UpdataUnAllLoadMsg()

            if(FriendsPage.show_callback)then
                FriendsPage.show_callback();
            end
		end,true);
	end)
end
function FriendsPage.GetPageCtrl()
    return page;
end
function FriendsPage.GetRecentFromFriendsList()
	if nil == FriendList then
		return {}
	end
	-- 有最后一条消息的说明才是最近联系的
	local last_chat_msg = FriendManager:GetLastChatMsg()
	-- commonlib.echo(last_chat_msg, true)
	-- commonlib.echo(FriendList, true)
	local list = {}
	if last_chat_msg then
		for key, v in pairs(FriendList) do
			local id = tostring(v.friendId)
			if last_chat_msg[id] then
				v.last_msg_time_stamp = last_chat_msg[id].time_stamp
				list[#list + 1] = v
			end
		end
	end

	table.sort(list, function(a, b)
		return (a.last_msg_time_stamp > b.last_msg_time_stamp )
	end)

	return list
end

-- 最近联系
function FriendsPage.GetRecentContactLlist(search_text)
	keepwork.friend.friendsList({
        headers = {
            ["x-per-page"] = 200,
            ["x-page"] = 1,
        }
	},function(err, msg, data)
		if err == 200 then
			FriendList = data
			local list = FriendsPage.GetRecentFromFriendsList()
			FriendsPage.UpdateDataByFriendAction(list)
		end
	end)
end

function FriendsPage.GetFriendsLlist()
	keepwork.friend.friendsList({
        headers = {
            ["x-per-page"] = 200,
            ["x-page"] = 1,
        }
	},function(err, msg, data)
		if err == 200 then
			FriendsPage.UpdateDataByFriendAction(data)
		end
	end)
end

local getLastTimeStr = function(lastUpdateTime)
    if not lastUpdateTime or lastUpdateTime == "" then
        return ""
    end
    local y,m,d = string.match(lastUpdateTime, "(%d+)_(%d+)_(%d+)")
    if not y or not m or not d then
        return ""
    end
    local year = tonumber(y)
    local month = tonumber(m)
    local day = tonumber(d)
    local last_ts = os.time({year = year, month = month, day = day, hour = 0, min = 0, sec = 0})
    local now_ts = os.time()
    if last_ts and now_ts then
        local diff_days = math.floor((now_ts - last_ts) / (24 * 60 * 60))
        if diff_days <= 30 then
            if diff_days <= 0 then
                return "今天已完成互动"
            else
                return string.format("上次互动%d天前", diff_days)
            end
        else
            return string.format("%d/%d/%d互动过", year, month, day)
        end
    end
    return string.format("%d/%d/%d互动过", year, month, day)
end

function FriendsPage.UpdateDataByFriendAction(data)
	local FriendActionManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/FriendActionManager.lua");
    FriendActionManager.LoadFriendLevelConfig(function()
		local friendLevelList = FriendActionManager.friendLevelConfig or {}
		local friendList = data or {}
		for index,fData in ipairs(friendList) do
			local friend = fData.friend or {}
			local fName = friend.username or ""
			local fLevelData = friendLevelList[fName] or {}
			fData.level = FriendActionManager.GetFriendLevelBySignDay((fLevelData.level or 0))
			fData.lastActionTimeStr = getLastTimeStr(fLevelData.lastUpdateTime)
		end
		table.sort(friendList, function(a, b)
			return (a.level > b.level)
		end)
		FriendsPage.SetListDataAndFlushGridView(friendList)
	end)
end

function FriendsPage.CheckIsFriend(friendId,callback)
	keepwork.friend.friendsList({
        headers = {
            ["x-per-page"] = 300,
            ["x-page"] = 1,
        }
	},function(err, msg, data)
		if err == 200 then
			data = data or {}
			for k,v in pairs(data) do
				if v.friendId == friendId then
					callback(true)
					return
				end
			end
			callback(false)
		end
	end)
end

function FriendsPage.GetFriendApplyLlist()
	keepwork.friend.getFriendApplys({
		headers = {
            ["x-per-page"] = 300,
            ["x-page"] = 1,
        }
	},function(err, msg, data)
		if err == 200 then
			-- print("获取好友申请列表", err)
			-- echo(dakta, true)
			local friend_applys = data.rows
			table.sort(friend_applys, function(a, b)
				return (commonlib.timehelp.GetTimeStampByDateTime(a.createdAt) > commonlib.timehelp.GetTimeStampByDateTime(b.createdAt))
			end)
			FriendManager:SetFriendApply()
			FriendsPage.SetListDataAndFlushGridView(friend_applys)
			GameLogic.GetFilters():apply_filters('friend_chat_msg')
		end
	end)
end

function FriendsPage.GetClassMateLlist(search_text)
	search_text = search_text or ""
	keepwork.user.classmates({
		username=search_text,
        headers = {
            ["x-per-page"] = 200,
            ["x-page"] = 1,
        }
	},function(err, msg, data)
		--print("xxxxxxxxxxxxx", err)
		--commonlib.echo(data, true)
		if err == 200 then
			FriendsPage.SetListDataAndFlushGridView(data.rows)
		end
	end)
end

function FriendsPage.GetFollowingLlist(search_text)
	search_text = search_text or ""
	keepwork.user.following({
		username=search_text,
        headers = {
            ["x-per-page"] = 200,
            ["x-page"] = 1,
		},
		userId = UserData.id,
	},function(err, msg, data)
		
	-- print("获取关注列表cccccccccccccccccccccccccc", UserData.id)
		-- commonlib.echo(data, true)
		if err == 200 then
			FriendsPage.SetListDataAndFlushGridView(data.rows)
		end
	end)
end

function FriendsPage.GetFollowersLlist(search_text)
	search_text = search_text or ""
	keepwork.user.followers({
		username=search_text,
        headers = {
            ["x-per-page"] = 200,
            ["x-page"] = 1,
		},
		userId = UserData.id,
	},function(err, msg, data)
		-- commonlib.echo(data, true)
		if err == 200 then
			FriendsPage.SetListDataAndFlushGridView(data.rows)
		end
	end)
end

function FriendsPage.SetListDataAndFlushGridView(rows)
	FriendsPage.HandleListData(rows)
	if page then
		local gvw_name = "item_gridview";
		local node = page:GetNode(gvw_name);
		pe_gridview.DataBind(node, gvw_name, false);
	end
end

function FriendsPage.HandleListData(rows)
	FriendsPage.Current_Item_DS = {}

	local last_chat_msg = FriendManager:GetLastChatMsg() or {}
	for key, value in pairs(rows) do
		local user = FriendsPage.index == TopBtListType.FriendApply and value.user or value.friend
		local portrait = value.portrait
		if user then
			local portrait = user.portrait or  ""
			value.username = user.username
			value.nickname = user.nickname
		end
		if portrait == nil or portrait == "" then
			value.portrait = "Texture/Aries/Creator/keepwork/UserInfo/renwu_32bits.png"
		else
			value.portrait = portrait
		end
		local id = tostring(value.userId)
		if last_chat_msg[id] then
			value.last_msg_time_stamp = last_chat_msg[id].time_stamp
		end

		if FriendsPage.index == TopBtListType.Friend then
			value.isFriend = true
		end

		if FriendsPage.index == TopBtListType.FriendApply and value.userId ~= UserData.id then
			FriendsPage.Current_Item_DS[#FriendsPage.Current_Item_DS + 1] = value
		else
			FriendsPage.Current_Item_DS[#FriendsPage.Current_Item_DS + 1] = value
		end
	end
end

function FriendsPage.IsHaveHistoryChat()
	local last_chat_msg = FriendManager:GetLastChatMsg()
	return type(last_chat_msg) == "table" and next(last_chat_msg) ~= nil
end	

function FriendsPage.IsHaveNewChat()
	return FriendManager.unread_msgs_num and FriendManager.unread_msgs_num > 0
end

function FriendsPage.IsHaveNewFriendApply()
	return type(FriendManager.friend_apply) == "table" 
end

function FriendsPage.OnChange(index)
	index = tonumber(index)
	FriendsPage.index = index;
	if TypeToCb[index] then
		TypeToCb[index]()
	end
    FriendsPage.OnRefresh()
end


function FriendsPage.OnRefresh()
    if(page)then
        page:Refresh(0.2);
    end
end
function FriendsPage.ClickItem(data)
    if mouse_button == "left" then
		FriendsPage.PrivateLetter(data);
    elseif mouse_button == "right" then
        FriendsPage.OpenFriendMenu(data)
    end
    
end

function FriendsPage.OpenFriendMenu(data)
	NPL.load("(gl)script/ide/ContextMenu.lua");
    local ctl = CommonCtrl.GetControl("FriendsPage.FriendMenu");
	local menuStyle = commonlib.copy(CommonCtrl.ContextMenu.DefaultStyle)
	menuStyle.menuitemHeight = 36
	menuStyle.item_bg = "Texture/Aries/Creator/keepwork/community_32bits.png;344 7 32 32:14 14 14 14"
	menuStyle.menu_bg = "Texture/Aries/Creator/keepwork/community_32bits.png;307 8 32 32:14 14 14 14"
	menuStyle.level1itemcolor = "#A8A7B0FF"
	menuStyle.mouseover_textcolor = "#ffffff"
	menuStyle.textFont = "System;14;bold"
	if(not ctl)then
		ctl = CommonCtrl.ContextMenu:new{
			name = "FriendsPage.FriendMenu",
			width = 120,
			height = 160, 
			style = menuStyle,
		};
		ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "root_node", Type = "Group", NodeHeight = 0 });
	end
	local node = ctl.RootNode:GetChild(1);
	if node then
		node:ClearAllChildren();
		if FriendsPage.index == TopBtListType.RecentContact or FriendsPage.index == TopBtListType.Friend or data.isFriend then
			node:AddChild(CommonCtrl.TreeNode:new({Text="私信", Name = "chat", Type = "Menuitem", Icon="Texture/Aries/Creator/keepwork/friends/zi_sixin1_34X16_32bits.png#0 0 34 16", onclick = function()
				FriendsPage.PrivateLetter(data);
			end, Icon = nil,}));
		end
		node:AddChild(CommonCtrl.TreeNode:new({Text = "查看资料", Name = "viewprofile", Type = "Menuitem", onclick = function()
			GameLogic.ShowUserInfoPage({username=data.username});
			FriendsPage.CloseView()
		end, }));

		if FriendsPage.index == TopBtListType.RecentContact or 
			FriendsPage.index == TopBtListType.Friend or data.isFriend then
			node:AddChild(CommonCtrl.TreeNode:new({Text = "删除好友", Name = "removefriend", Type = "Menuitem", onclick = function()
				FriendsPage.OnDeleteFriend(data)
			end, }));	

			node:AddChild(CommonCtrl.TreeNode:new({Text = "邀请组队", Name = "invitegroup", Type = "Menuitem", onclick = function()
				local username = data.username or "";
				local TeamManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/TeamManager.lua");
				TeamManager:Connect(nil,function()
					TeamManager:InviteUserToTeam(username)
				end)
			end, }));
		end	
	end
	local x, y = ParaUI.GetMousePosition();
	ctl:Show(x + 30, y);
end

-- 时间显示
-- 规则：
-- 今日：   时：分
-- 昨天：   昨天
-- 今年：  月-日
-- 往年：  年-月-日
function FriendsPage.GetTimeDesc(time)
	if time == nil or time == "" then
		return ""
	end
	time = tonumber(time)
	-- 先获取当前时间
	local cur_time_t = FriendsPage.FormatUnixTime2Date(os.time())
	local target_time_t = FriendsPage.FormatUnixTime2Date(time)

	-- 往年
	if target_time_t.year < cur_time_t.year then
		return DateTool("%Y-%m-%d", time)
	-- 往月
	elseif target_time_t.month < cur_time_t.month then
		return DateTool("%m-%d", time)
	-- 今日
	elseif target_time_t.day == cur_time_t.day then
		return DateTool("%H:%M", time)
	else
		-- 获取当天0点的时间戳
		local temp_time = os.time({day = cur_time_t.day, month = cur_time_t.month, year = cur_time_t.year, hour=0, minute=0, second=0})
		-- 在当天0点的时间戳之前的24小时以内的时间都是昨天
		local limit_sceond = 24 * 60 * 60

		-- 判断是否昨天
		if temp_time - time < limit_sceond then
			return "昨天"
		else
			return DateTool("%m-%d", time)
		end
	end

end

function FriendsPage.FormatUnixTime2Date(unixTime)
    if unixTime and unixTime >= 0 then
        local tb = {}
        tb.year = tonumber(DateTool("%Y",unixTime))
        tb.month =tonumber(DateTool("%m",unixTime))
        tb.day = tonumber(DateTool("%d",unixTime))
        tb.hour = tonumber(DateTool("%H",unixTime))
        tb.minute = tonumber(DateTool("%M",unixTime))
        tb.second = tonumber(DateTool("%S",unixTime))
        return tb
    end
end

function FriendsPage.PrivateLetter(chat_user_data)
	if not chat_user_data then
		LOG.std(nil,"info","FriendsPage","PrivateLetter chat_user_data is nil")
		return
	end
	-- 要先判断是否好友
	if chat_user_data and chat_user_data.isFriend or FriendsPage.index == TopBtListType.RecentContact or FriendsPage.index == TopBtListType.Friend then
		local friend_status = chat_user_data.status or 0
		if friend_status == 2 then
			GameLogic.AddBBS("statusBar", L"对方已经删除了您，暂时无法发送私聊消息", 5000, "0 255 0");
			return
		end
		if friend_status == 3 then
			GameLogic.AddBBS("statusBar", L"对方已经屏蔽了您，暂时无法发送私聊消息", 5000, "0 255 0");
			return
		end
		if friend_status == 1 then
			if FriendsPage.msg_content then
				FriendChatPage.Show(UserData, chat_user_data, FriendsPage.msg_content);
				FriendsPage.msg_content = nil
			else
				print("msg_content is nil===========")
				-- echo(UserData, true)
				-- echo(chat_user_data, true)
				FriendChatPage.Show(UserData, chat_user_data);
			end
		end
	end
end

function FriendsPage.DeleteFriend(userId)
	-- userId = 176382
	keepwork.friend.deleteFriend({
		router_params = {
            friendId = userId,
        }
	},function(err, msg, data)
		-- commonlib.echo(data, true)
		if err == 200 then
			GameLogic.AddBBS("statusBar", L"删除好友成功", 5000, "0 255 0");
			FriendsPage.FlushCurDataAndView()

			if FriendChatPage.IsOpen then
				FriendChatPage.FlushCurDataAndView()
			end
		end
	end)
end

function FriendsPage.SearchFriend()
	local AddFriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/AddFriendsPage.lua");
	AddFriendsPage.Show(UserData);
end

function FriendsPage.AddFriend()
	FriendsPage.SearchFriend()
end

function FriendsPage.FlushCurDataAndView(search_text)
	if TypeToCb[FriendsPage.index] then
		TypeToCb[FriendsPage.index](search_text)
	end
end

function FriendsPage.ClosePage()
	if page then
		page:CloseWindow()
	end
end

function FriendsPage.CloseView()
	IsOpen = false
	local ctl = CommonCtrl.GetControl("FriendsPage.FriendMenu");
	if ctl then
		ctl:Hide()
	end
	
	FriendsPage.ClearData()
	if page then
		page:CloseWindow()
		page = nil
	end
end

function FriendsPage.ClearData()
	FriendsPage.Current_Item_DS = {};
	FriendsPage.index = 2;
	UserData = {}
	FriendsPage.UnreadMsg = {}
	TypeToCb = {}
	FriendList = nil
	FriendManager.unread_msgs_loaded = false;
end

function FriendsPage.GetIsOpen()
	return IsOpen
end

function FriendsPage.OnDeleteFriend(data)
	local chat_user_data = FriendChatPage.GetCurChatUesrData()
	if data.friendId == chat_user_data.friendId then
		GameLogic.AddBBS("statusBar", L"您与对方正在聊天中，请先关闭聊天窗口", 5000, "0 255 0");
		return
	end
	local show_text = ""
	if FriendsPage.index == TopBtListType.RecentContact or FriendsPage.index == TopBtListType.Friend or data.isFriend then
		show_text = "你确定要删除好友吗？\n删除好友后对方将不在好友列表中，且以后不再接收此人的会话消息。"
	else
		show_text = "你确定要删除好友吗？"
	end

	_guihelper.MessageBox(show_text, function()
		FriendsPage.DeleteFriend(data.friendId)
	end)
end

function FriendsPage.OpenApply()
	local FriendsApplyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsApplyPage.lua");
	FriendsApplyPage.Show(UserData);
end

function FriendsPage.ResolveFriendApply(data,resolve_type)
	local resolve_status
	if resolve_type == "confirm" then
		resolve_status = 2
	elseif resolve_type == "cancel" then
		resolve_status = 3
	end
	keepwork.friend.updateFriendApplys({
		router_params = {
            applyId = data.id,
		},
		status = resolve_status,
	},function(err, msg, data)
		if err == 200 then
			FriendsPage.FlushCurDataAndView()
			FriendsPage.OnRefresh()
		end
	end)
end

------------------------------------------------------处理未读消息------------------------------------------------------
function FriendsPage.IsShowRedPoint(userId)
	if FriendsPage.UnreadMsg[userId] and FriendsPage.UnreadMsg[userId].unReadCnt and FriendsPage.UnreadMsg[userId].unReadCnt > 0 then
		return true
	end

	return false
end

function FriendsPage.GetUnReadMsgNum(userId)
	if FriendsPage.UnreadMsg[userId] and FriendsPage.UnreadMsg[userId].unReadCnt then
		return FriendsPage.UnreadMsg[userId].unReadCnt
	end

	return 0
end

function FriendsPage.GetAllUnReadMsgNum()
	if not FriendsPage.UnreadMsg then
		return 0
	end
	
	if FriendChatPage.IsOpen then
		return 0
	end

	local all_num = 0
	for key, v in pairs(FriendsPage.UnreadMsg) do
		if v.unReadCnt then
			all_num = all_num + v.unReadCnt
		end
	end

	return all_num
end

function FriendsPage.AddUnReadMsg(userId, num, msg)
	num = num or 1
	msg = msg or ""
	if FriendsPage.UnreadMsg[userId] == nil then
		FriendsPage.UnreadMsg[userId] = {}
		FriendsPage.UnreadMsg[userId].unReadCnt = 0
		FriendsPage.UnreadMsg[userId].latestMsg = {}
	end

	FriendsPage.UnreadMsg[userId].latestMsg.content = msg
	
	FriendsPage.UnreadMsg[userId].unReadCnt = FriendsPage.UnreadMsg[userId].unReadCnt + num
	
	GameLogic.GetFilters():apply_filters("update_friend_unread_num", FriendsPage.GetAllUnReadMsgNum());
end

function FriendsPage.OnMsg(payload, full_msg)

	-- 目前这个接口主要是为了处理小红点 所以在聊天界面打开的情况下 如果有收到消息 但发来消息的人刚好是正在聊天的人 则不加小红点
	if FriendChatPage.IsOpen then
		local chat_user_data = FriendChatPage.GetCurChatUesrData()
		if payload.id ~= UserData.id and chat_user_data and chat_user_data.id == payload.id then

			-- 收到消息 最近联系列表得刷新一下
			if FriendsPage.index == TopBtListType.RecentContact then
				local list = FriendsPage.GetRecentFromFriendsList()
				FriendsPage.SetListDataAndFlushGridView(list)
			end

			return
		end
	end

	-- 收到消息 最近联系列表得刷新一下
	if FriendsPage.index == TopBtListType.RecentContact then
		FriendsPage.AddUnReadMsg(payload.id, 1, payload.content)
		local list = FriendsPage.GetRecentFromFriendsList()
		FriendsPage.SetListDataAndFlushGridView(list)
	else
		FriendsPage.AddUnReadMsg(payload.id, 1, payload.content)
		FriendsPage.OnRefresh()
	end
end

function FriendsPage.ClearUnReadMsg(userId)
	if FriendsPage.UnreadMsg[userId] and FriendsPage.UnreadMsg[userId].unReadCnt then
		FriendsPage.UnreadMsg[userId].unReadCnt = 0
	end
	
	GameLogic.GetFilters():apply_filters("update_friend_unread_num", FriendsPage.GetAllUnReadMsgNum());
	FriendsPage.OnRefresh()
end

------------------------------------------------------处理未读消息/end------------------------------------------------------
-- 定时刷新全部未读消息
function FriendsPage.UpdataUnAllLoadMsg()
	if not IsOpen then
		return
	end

	commonlib.TimerManager.SetTimeout(function()
		if not IsOpen then
			return
		end

		FriendManager:LoadAllUnReadMsgs(function ()
			-- 处理未读消息
			if FriendManager.unread_msgs and FriendManager.unread_msgs.data then
				for k, v in pairs(FriendManager.unread_msgs.data) do
					local data = commonlib.clone(v)
					FriendsPage.UnreadMsg[v.latestMsg.senderId] = data
					FriendManager:AddLastChatMsg(v.latestMsg.senderId, data)
				end
			end
	
			FriendsPage.FlushCurDataAndView()
			FriendsPage.UpdataUnAllLoadMsg()
		end, true);
	end, 30000,"update_all_unread_msg")

end

function FriendsPage.IsShowJoinSchool()
	local profile = KeepWorkItemManager.GetProfile()
	local has_join_school = profile.schoolId and profile.schoolId > 0
	return FriendsPage.index == TopBtListType.ClassMate and not has_join_school
end

function FriendsPage.JionSchool()
	GameLogic.GetFilters():apply_filters('cellar.my_school.after_selected_school', function ()
		KeepWorkItemManager.LoadProfile(false, function()
			FriendsPage.FlushCurDataAndView()
			FriendsPage.OnRefresh()
		end)
	end);
end

function FriendsPage.TeleportToFriend(data)
	if not FriendsPage.TeleportToFriendFuncImp then
		FriendsPage.TeleportToFriendFuncImp = commonlib.debounce(function(data)
			FriendsPage.TeleportToFriendImp(data)
		end,1000)
	end
	FriendsPage.ClosePage()
	GameLogic.AddBBS(nil,"开始查找好友位置")
	FriendsPage.TeleportToFriendFuncImp(data)
end

function FriendsPage.TeleportToFriendImp(teleportData)
	local userId = teleportData and teleportData.friendId
	if not userId then
		return
	end
	local username = Mod.WorldShare.Store:Get('user/username')
	local my_userId = Mod.WorldShare.Store:Get('user/userId')
	local sendMsg = {
		contentType = 3,
		msgType = "request",
		msgUserId = my_userId,
		msgUsername = username,
		ChannelIndex = ChatChannel.EnumChannels.KpFriend,
		toUserId = userId,
		toUsername = teleportData.friend and teleportData.friend.username,
		content = "where are you"
	}
	FriendsPage.SendCustomMsg(sendMsg, true)
end

function FriendsPage.SendCustomMsg(customMsg, isShowBBS)
	if not customMsg or not customMsg.msgUserId then
		return
	end
	local params = {
		userIds={customMsg.toUserId}, --发送对象
		msg = customMsg,
	}
	keepwork.chat.msg(params,function(err,msg,data)
		local tipMsg = err == 200 and "正在查找好友位置，如果好友不在线，可能会查找失败" or "发送失败"
		if isShowBBS then
			GameLogic.AddBBS(nil,tipMsg)
		end
	end)
end

function FriendsPage.OnRecvTeleportMsg(msg)
	if not msg or not msg.msgUserId then
		return
	end
	local userId = Mod.WorldShare.Store:Get('user/userId')
	if not userId or userId == 0 or msg.toUserId ~= userId then
		return
	end
	FriendsPage.CheckIsFriend(msg.msgUserId,function(isFriend)
		if isFriend then
			FriendsPage.ResponsTeleportMsg(msg)
		end
	end)
end

function FriendsPage.GetUserEntity(username)
    local userEntity = GameLogic.EntityManager.GetPlayer(username)
    if not userEntity then
        userEntity = GameLogic.GetPlayer()
    end
    NPL.load("Mod/GeneralGameServerMod/App/Client/AppGeneralGameClient.lua");
    local AppGeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient");
    if AppGeneralGameClient:IsLogin() then
        local world = AppGeneralGameClient:GetWorld()
        if not world then
             return userEntity
        end
        local playerManager = world:GetPlayerManager()
        if not playerManager then
            return userEntity
        end
        local ggsEntity = playerManager:GetEntityByUser(username)
        if ggsEntity then
            return ggsEntity
        end
    end
    
    return userEntity
end

function FriendsPage.GetServerInfo(callback)
	NPL.load("Mod/GeneralGameServerMod/App/Client/AppGeneralGameClient.lua");
	local AppGeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient");
	local Packets = NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets.lua");
	local world = AppGeneralGameClient:GetWorld()
	if AppGeneralGameClient:IsLogin() and world then
		local netHandler = world:GetNetHandler();
		if netHandler then
			netHandler:AddToSendQueue(Packets.PacketGeneral:new():Init({action = "Debug", data = { cmd = "WorldInfo"}}));
			netHandler.debug_serverlist_callback = function(debugInfo)
				if callback and type(callback) == "function" then
					callback(debugInfo)
				end
				netHandler.debug_serverlist_callback = nil
			end
		end
	else
		if callback and type(callback) == "function" then
			callback(nil)
		end
	end
end

function FriendsPage.ResponsTeleportMsg(msg)
	if not msg or not msg.msgUserId then
		return
	end
	NPL.load("Mod/GeneralGameServerMod/App/Client/AppGeneralGameClient.lua");
	local AppGeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient");
	if msg.msgType == "request" then
		local projectId = GameLogic.options:GetProjectId();
		if not projectId or projectId == 0 then
			return
		end
		local sendMsg = {
			contentType = 3,
			msgType = "response",
			msgUserId = msg.toUserId,
			msgUsername = msg.toUsername,
			ChannelIndex = ChatChannel.EnumChannels.KpFriend,
			toUserId = msg.msgUserId,
			toUsername = msg.msgUsername,
			content = "I am here",
			projectId = projectId,
		}
		
		FriendsPage.GetServerInfo(function(debugInfo)
			if debugInfo and debugInfo.worldKey then
				sendMsg.worldInfo = debugInfo
			end
			FriendsPage.SendCustomMsg(sendMsg)
		end)
	elseif msg.msgType == "response" then
		FriendsPage.responseMsg = msg
		local projectId = GameLogic.options:GetProjectId();
		if projectId and projectId == msg.projectId and Game.is_started then
			if AppGeneralGameClient:IsLogin() then
				FriendsPage.GetServerInfo(function(debugInfo)
					local worldKey = debugInfo and debugInfo.worldKey
					local isSameWorld = worldKey and msg.worldInfo and worldKey == msg.worldInfo.worldKey
					if isSameWorld then
						FriendsPage.responseMsg = nil
						local userEntity = FriendsPage.GetUserEntity(msg.msgUsername)
						local player = GameLogic.GetPlayer()
						local bx,by,bz,ux,uy,uz
						if player then bx,by,bz = player:GetBlockPos() end
						if userEntity then ux,uy,uz = userEntity:GetBlockPos() end
						if ux and uy and uz and bx and by and bz then
							local dis = math.floor(math.sqrt((ux-bx)^2 + (uz-bz)^2))
							if dis < 20 then
								GameLogic.AddBBS(nil,"你的好友在你附近")
								GameLogic.RunCommand(string.format("/lookat %s %s %s", ux, uy, uz))
								return
							end
							FriendsPage.TeloportToPos({x=ux,y=uy,z=uz})
						end
					else
						GameLogic.AddBBS(nil,"正在前往好友的世界")
						AppGeneralGameClient:SwitchServer(msg.worldInfo)
						GameLogic.GetFilters():remove_filter("OnGGSLogin",  FriendsPage.OnGGSLogIn);
						GameLogic.GetFilters():add_filter("OnGGSLogin",  FriendsPage.OnGGSLogIn);
					end
				end)
			else
				local worldInfo = msg.worldInfo
				local worldKey = worldInfo and worldInfo.worldKey
				local worldName = worldInfo and worldInfo.worldName
				local worldId = worldInfo and worldInfo.worldId
				local cmdStr = string.format([[/ggs connect -worldKey=%s -worldName=%s -worldId=%s]], worldKey, worldName, worldId)
				GameLogic.RunCommand(cmdStr)
				GameLogic.GetFilters():remove_filter("OnGGSLogin",  FriendsPage.OnGGSLogIn);
				GameLogic.GetFilters():add_filter("OnGGSLogin",  FriendsPage.OnGGSLogIn);
			end
		else
			GameLogic.AddBBS(nil,"正在前往好友的世界")
			local cmdStr = string.format("/loadworld -s -auto %s", tostring(msg.projectId))
			GameLogic.RunCommand(cmdStr)
			GameLogic:Disconnect("WorldLoaded", FriendsPage, FriendsPage.OnWorldLoaded, "UniqueConnection");
			GameLogic:Connect("WorldLoaded", FriendsPage, FriendsPage.OnWorldLoaded, "UniqueConnection");
		end
	end
end

function FriendsPage.OnWorldLoaded()
	if FriendsPage.responseMsg and FriendsPage.responseMsg.worldInfo then
		local worldInfo = FriendsPage.responseMsg.worldInfo
		local worldKey = worldInfo and worldInfo.worldKey
		local worldName = worldInfo and worldInfo.worldName
		local worldId = worldInfo and worldInfo.worldId
		local cmdStr = string.format([[/ggs connect -worldKey=%s -worldName=%s -worldId=%s]], worldKey, worldName, worldId)
		GameLogic.RunCommand(cmdStr)
		GameLogic.GetFilters():remove_filter("OnGGSLogin",  FriendsPage.OnGGSLogIn);
		GameLogic.GetFilters():add_filter("OnGGSLogin",  FriendsPage.OnGGSLogIn);
	else
		FriendsPage.loadedWorlsTips = L"用户在正处于当前世界，但是处于单机模式"
		GameLogic.GetFilters():remove_filter("apps.aries.creator.game.login.swf_loading_bar.close_page",  FriendsPage.OnSwfLoadingCloesed);
    	GameLogic.GetFilters():add_filter("apps.aries.creator.game.login.swf_loading_bar.close_page",  FriendsPage.OnSwfLoadingCloesed);
	end
	GameLogic:Disconnect("WorldLoaded", FriendsPage, FriendsPage.OnWorldLoaded, "UniqueConnection");
end

function FriendsPage.OnSwfLoadingCloesed()
	if FriendsPage.loadedWorlsTips and FriendsPage.loadedWorlsTips ~= "" then
		GameLogic.AddBBS(nil, FriendsPage.loadedWorlsTips)
	end
	FriendsPage.loadedWorlsTips = ""
	GameLogic.GetFilters():remove_filter("apps.aries.creator.game.login.swf_loading_bar.close_page",  FriendsPage.OnSwfLoadingCloesed);
end

function FriendsPage.OnGGSLogIn(packetPlayerInfo)
	if FriendsPage.responseMsg then
		local msg = commonlib.deepcopy(FriendsPage.responseMsg)
		FriendsPage.responseMsg = nil
		local userEntity = FriendsPage.GetUserEntity(msg.msgUsername)
		local player = GameLogic.GetPlayer()
		if player and userEntity then
			local bx,by,bz,ux,uy,uz
			bx,by,bz = player:GetBlockPos()
			ux,uy,uz = userEntity:GetBlockPos()
			if ux and uy and uz and bx and by and bz then
				local dis = math.floor(math.sqrt((ux-bx)^2 + (uz-bz)^2))
				if dis < 20 then
					GameLogic.AddBBS(nil,"你的好友在你附近")
					GameLogic.RunCommand(string.format("/lookat %s %s %s", ux, uy, uz))
					return
				end
				FriendsPage.TeloportToPos({x=ux,y=uy,z=uz})
			end
		end
	end
	GameLogic.GetFilters():remove_filter("OnGGSLogin",  FriendsPage.OnGGSLogIn);
	return packetPlayerInfo
end

function FriendsPage.TeloportToPos(pos)
	local MiniGameMap = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMap.lua");
	local safePos = MiniGameMap.RandomSafeTeleportNear(pos, 3, 3)
	MiniGameMap:TeleportToPos(safePos, pos)
end