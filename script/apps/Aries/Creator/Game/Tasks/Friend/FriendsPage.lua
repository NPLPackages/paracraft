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
FriendsPage.index = 1;

local IsOpen = false

local page;
local DateTool = os.date
local TopBtListType = {
	RecentContact = 1,
	Friend = 2,
	Following = 3,
	Followers = 4,
}

function FriendsPage.OnInit()
	page = document:GetPageCtrl();
	page.OnClose = FriendsPage.CloseView

	TypeToCb[TopBtListType.RecentContact] = FriendsPage.GetRecentContactLlist
	TypeToCb[TopBtListType.Friend] = FriendsPage.GetFriendsLlist
	TypeToCb[TopBtListType.Following] = FriendsPage.GetFollowingLlist
	TypeToCb[TopBtListType.Followers] = FriendsPage.GetFollowersLlist
end

function FriendsPage.Show()
	KeepWorkItemManager.GetUserInfo(nil,function(err,msg,data)
        if(err ~= 200)then
            return
		end
		UserData = data
		FriendManager:InitUserData(data)
		FriendManager:LoadAllUnReadMsgs(function ()
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
				zorder = -1,
				app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
				directPosition = true,
					align = "_lt",
					x = 10,
					y = 10/2,
					width = 330,
					height = 583,
			};
			System.App.Commands.Call("File.MCMLWindowFrame", params);
			FriendsPage.OnChange(1);
	
			IsOpen = true

			FriendsPage.UpdataUnAllLoadMsg()

            if(FriendsPage.show_callback)then
                FriendsPage.show_callback();
            end
		end);
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
			local id = tostring(v.id)
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
	search_text = search_text or ""
	keepwork.user.friends({
		username=search_text,
        headers = {
            ["x-per-page"] = 200,
            ["x-page"] = 1,
        }
	},function(err, msg, data)
		-- commonlib.echo(data)
		if err == 200 then
			FriendList = data.rows
			local list = FriendsPage.GetRecentFromFriendsList()
			FriendsPage.SetListDataAndFlushGridView(list)
		end
		
	end)
end

function FriendsPage.GetFriendsLlist(search_text)
	search_text = search_text or ""
	keepwork.user.friends({
		username=search_text,
        headers = {
            ["x-per-page"] = 200,
            ["x-page"] = 1,
        }
	},function(err, msg, data)
		-- commonlib.echo(data, true)
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
	local gvw_name = "item_gridview";
	local node = page:GetNode(gvw_name);
	pe_gridview.DataBind(node, gvw_name, false);
end

function FriendsPage.HandleListData(rows)
	FriendsPage.Current_Item_DS = {}

	local last_chat_msg = FriendManager:GetLastChatMsg() or {}
	for key, value in pairs(rows) do
		if value.portrait == nil or value.portrait == "" then
			value.portrait = "Texture/Aries/Creator/keepwork/UserInfo/renwu_32bits.png"
		end
		local id = tostring(value.id)
		if last_chat_msg[id] then
			value.last_msg_time_stamp = last_chat_msg[id].time_stamp
		end
		if value.id ~= UserData.id then
			FriendsPage.Current_Item_DS[#FriendsPage.Current_Item_DS + 1] = value
		end
	end
end

function FriendsPage.OnChange(index)
	index = tonumber(index)
	FriendsPage.index = index;
	
	if TypeToCb[index] then
		TypeToCb[index]()
	end

    -- FriendsPage.Current_Item_DS = FriendsPage.data_sources[index] or {}
    FriendsPage.OnRefresh()
end


function FriendsPage.OnRefresh()
    if(page)then
        page:Refresh(0.2);
    end
end
function FriendsPage.ClickItem(data)
    if mouse_button == "left" then
		-- local user_page = NPL.load("(gl)Mod/GeneralGameServerMod/App/ui/page.lua");
		-- user_page.ShowUserInfoPage({username=data.username});
		FriendsPage.PrivateLetter(data);
    elseif mouse_button == "right" then
        FriendsPage.OpenFriendMenu(data)
    end
    
end

function FriendsPage.OpenFriendMenu(data)
    -- commonlib.echo(data, true)
    local ctl = CommonCtrl.GetControl("FriendsPage.FriendMenu");
	NPL.load("(gl)script/ide/ContextMenu.lua");
	ctl = CommonCtrl.ContextMenu:new{
		name = "FriendsPage.FriendMenu",
		width = if_else(System.options.version=="kids", 120, 120),
		height = 160,
		DefaultNodeHeight = 24,
		style = if_else(System.options.version=="teen", nil, {
			borderTop = 4,
			borderBottom = 4,
			borderLeft = 4,
			borderRight = 4,
			
			fillLeft = 0,
			fillTop = 0,
			fillWidth = 0,
			fillHeight = 0,
			
			titlecolor = "#6e6e6e",
			level1itemcolor = "#6e6e6e",
			level2itemcolor = "#3e7320",
			
			iconsize_x = 24,
			iconsize_y = 21,
			
			menu_bg = "Texture/Aries/Creator/keepwork/friends/tipbj_32bits.png:8 8 8 8",

			shadow_bg = nil,
			separator_bg = "Texture/Aries/Dock/menu_separator_32bits.png", -- : 1 1 1 4
			item_bg = "",
			expand_bg = "Texture/Aries/Dock/menu_expand_32bits.png; 0 0 34 34",
			expand_bg_mouseover = "",
			
			menuitemHeight = 24,
			separatorHeight = 2,
			titleHeight = 24,
			
			titleFont = "System;12;bold";
		}),
	};
	local node = ctl.RootNode;
	node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "pe:name", Name = "pe:name", Type = "Group", NodeHeight = 0 });
	-- if(System.options.version =="teen")then
	-- 	node:AddChild(CommonCtrl.TreeNode:new({Text = "邀请加入家族", Name = "InviteToFamily", Type = "Menuitem", onclick = function()
	-- 			local manager = FamilyManager.CreateOrGetManager();
	-- 			if(manager and ctl.nid)then
	-- 				manager:DoInvite(ctl.nid);
	-- 			end
	-- 		end, Icon = nil,}));
	-- end
	-- if(System.options.version=="kids") then
	-- 	node:AddChild(CommonCtrl.TreeNode:new({Text = "  投人气", Name = "onvote", Type = "Menuitem", onclick = function()
	-- 			-- NewProfileMain.OnVotePolularity(ctl.nid,true);
	-- 		end, Icon = "Texture/Aries/NewProfile/onvote_32bits.png;0 1 24 23"}));	
	-- 	node:AddChild(CommonCtrl.TreeNode:new({Text = "  加为好友", Name = "addasfriend",Type = "Menuitem", onclick = function()
	-- 			-- NewProfileMain.OnAddAsFriend(ctl.nid);
	-- 		end,  Icon = "Texture/Aries/NewProfile/addasfriend_32bits.png;0 0 24 21"}));	
	-- end
	if FriendsPage.index == TopBtListType.RecentContact or FriendsPage.index == TopBtListType.Friend or data.isFriend then
		node:AddChild(CommonCtrl.TreeNode:new({Text="私信", Name = "chat", Type = "Menuitem", Icon="Texture/Aries/Creator/keepwork/friends/zi_sixin1_34X16_32bits.png#0 0 34 16", onclick = function()
			FriendsPage.PrivateLetter(data);
		end, Icon = nil,}));
	end

	-- node:AddChild(CommonCtrl.TreeNode:new({Text = "申请加入项目", Name = "addasfriend",Type = "Menuitem", onclick = function()
	-- 	-- NewProfileMain.OnAddAsFriend(ctl.nid);
	-- 	local FriendsProjectPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsProjectPage.lua");
	-- 	FriendsProjectPage.Show(UserData, data.id);
	-- end, }));	
	node:AddChild(CommonCtrl.TreeNode:new({Text = "查看资料", Name = "viewprofile", Type = "Menuitem", onclick = function()
		-- NewProfileMain.ShowPage(ctl.nid);
		local user_page = NPL.load("(gl)Mod/GeneralGameServerMod/App/ui/page.lua");
		user_page.ShowUserInfoPage({username=data.username});
	end, }));


	if FriendsPage.index == TopBtListType.RecentContact or 
		FriendsPage.index == TopBtListType.Friend or 
		FriendsPage.index == TopBtListType.Following or
		data.isFriend then
		node:AddChild(CommonCtrl.TreeNode:new({Text = "取消关注", Name = "removefriend", Type = "Menuitem", onclick = function()
			-- NewProfileMain.OnRemoveFriend(ctl.nid);
			FriendsPage.OnCancelFollow(data)
		end, }));	
	end	

	if(ctl.RootNode) then	
		local node = ctl.RootNode:GetChildByName("pe:name");
		if(node) then
			-- local is_friend_ = NewProfileMain.IsMyFriend(nid);
			local is_myself = (nid == Map3DSystem.User.nid);
			local tmp = node:GetChildByName("addasfriend");
			if(tmp) then
				tmp.Invisible = is_friend_ or is_myself;
			end
		end
	end
	ctl.nid = nid;
	ctl:Show(pos_x, pos_y);
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
	-- page:CloseWindow()
	-- FriendsPage.CloseView()
	FriendChatPage.Show(UserData, chat_user_data);
end

function FriendsPage.ToFollow(userId)
	-- userId = 176382
	keepwork.user.follow({
		objectType = 0,
		objectId = userId,
	},function(err, msg, data)
		-- print("关注xxxxxx", err, userId)
		-- commonlib.echo(data, true)
		if err == 200 then
			GameLogic.AddBBS("statusBar", L"关注成功", 5000, "0 255 0");
			FriendsPage.FlushCurDataAndView()
		end
	end)
end

function FriendsPage.UnFollow(userId)
	-- userId = 176382
	keepwork.user.unfollow({
		objectType = 0,
		objectId = userId,
	},function(err, msg, data)
		-- commonlib.echo(data, true)
		if err == 200 then
			GameLogic.AddBBS("statusBar", L"取消关注成功", 5000, "0 255 0");
			FriendsPage.FlushCurDataAndView()

			if FriendChatPage.IsOpen then
				FriendChatPage.FlushCurDataAndView()
			end
		end
	end)
end

function FriendsPage.IsFollow(userId)
	-- userId = 176382
	keepwork.user.isfollow({
		objectType = 0,
		objectId = userId,
	},function(err, msg, data)
		-- commonlib.echo(data, true)
	end)
end

function FriendsPage.HttpRequest(params, callback, options)
    local baseUrl = "http://api-rls.kp-para.cn"
    local index = string.find(params.url, "^http[s]?://");
    if (not index) then params.url = baseUrl .. params.url; end
    if (params.json == nil) then params.json = true; end
    params.headers = params.headers or {};
    params.headers["Authorization"] = string.format("Bearer %s", System.User.keepworktoken);
    return System.os.GetUrl(params, callback, options);
end

-- https://api.keepwork.com/core/v0/users/:id/detail
function FriendsPage.GetUserDetail(username, callback)
    local id = "kp" .. Encoding.base64(commonlib.Json.Encode({username=username}));
    local url = "http://api-rls.kp-para.cn" .. "/core/v0/users/" .. id .. "/detail";
    return FriendsPage.HttpRequest({
        url = url,
        method = "GET",
    }, callback);
end

function FriendsPage.SearchFriend()
	-- keepwork.user.search({
	-- 	username = {["$like"]="%qq342949687%"},
	-- },function(err, msg, data)
	-- 	commonlib.echo(data, true)
	-- end)

	local AddFriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/AddFriendsPage.lua");
	AddFriendsPage.Show(UserData);
end

function FriendsPage.AddFriend()
	-- FriendsPage.ToFollow()
	FriendsPage.SearchFriend()
end

function FriendsPage.FlushCurDataAndView(search_text)
	if TypeToCb[FriendsPage.index] then
		TypeToCb[FriendsPage.index](search_text)
	end
end

function FriendsPage.CloseView()
	IsOpen = false

	local ctl = CommonCtrl.GetControl("FriendsPage.FriendMenu");
	if ctl then
		ctl:Hide()
	end
	
	FriendsPage.ClearData()
end

function FriendsPage.ClearData()
	FriendsPage.Current_Item_DS = {};
	FriendsPage.index = 1;
	UserData = {}
	FriendsPage.UnreadMsg = {}
	TypeToCb = {}
	FriendList = nil
	FriendManager.unread_msgs_loaded = false;
end

function FriendsPage.GetIsOpen()
	return IsOpen
end

function FriendsPage.OnCancelFollow(data)
	local chat_user_data = FriendChatPage.GetCurChatUesrData()
	if data.id == chat_user_data.id then
		GameLogic.AddBBS("statusBar", L"您与对方正在聊天中，请先关闭聊天窗口", 5000, "0 255 0");
		return
	end
	local show_text = ""
	if FriendsPage.index == TopBtListType.RecentContact or FriendsPage.index == TopBtListType.Friend or data.isFriend then
		show_text = "你确定要取消关注吗？\n取消关注后对方将不在好友列表中，且以后不再接收此人的会话消息。"
	else
		show_text = "你确定要取消关注吗？"
	end

	_guihelper.MessageBox(show_text, function()
		FriendsPage.UnFollow(data.id)
	end)
end

function FriendsPage.OpenApply()
	local FriendsApplyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsApplyPage.lua");
	FriendsApplyPage.Show(UserData);
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
		print("...收到消息 最近联系列表得刷新一下")
		FriendsPage.AddUnReadMsg(payload.id, 1, payload.content)
		commonlib.echo(FriendsPage.UnreadMsg, true)
		local list = FriendsPage.GetRecentFromFriendsList()
		commonlib.echo(list, true)
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
	end, 30000)

end