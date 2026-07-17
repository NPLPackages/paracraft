--[[
Title: TeamManager
Author(s): 
Date: 2020/9/7
Desc:  
Use Lib:
-------------------------------------------------------
--房主开始创建队伍
local TeamManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/TeamManager.lua");
TeamManager:Connect(nil,function()
    TeamManager:InviteUserToTeam(username)
end)
--]]
NPL.load("(gl)script/apps/Aries/Chat/BadWordFilter.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetworkMain.lua");
NPL.load("Mod/GeneralGameServerMod/App/Client/AppGeneralGameClient.lua");
local TeamPlayerPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/TeamPlayerPage.lua");
local AppGeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient");
local NetworkMain = commonlib.gettable("MyCompany.Aries.Game.Network.NetworkMain");
local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local TeamConnect = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/TeamConnect.lua");
local FriendChatPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendChatPage.lua");
local FriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
local BadWordFilter = commonlib.gettable("MyCompany.Aries.Chat.BadWordFilter");
local TipRoadManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ScreenTipRoad/TipRoadManager.lua"); --弹幕显示
local SmileyConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/SmileyConfig.lua");
local TeamManager = NPL.export();

local UserData = {}
TeamManager.connections = {};
TeamManager.unread_msgs = {};
TeamManager.unread_msgs_loaded = false;
TeamManager.lastChatMsg = nil -- 各个好友最后的聊天信息 包括已读的和未读的
TeamManager.tempTeamChatMsgs = {} -- 临时聊天信息
TeamManager.connection = nil
TeamManager.roomId = nil
TeamManager.members = {}
local max_team_member_num = 4
local baseHosts = {
	STAGE = "http://socket-dev.kp-para.cn",
	RELEASE = "http://socket.kp-para.cn",
	ONLINE = "https://socket.keepwork.com"
}
local host = baseHosts[HttpWrapper.GetDevVersion()]

function TeamManager:InitHttpApi()
	--获取一个房间的用户列表
	HttpWrapper.Create("keepwork.chat.roomMembers", host.."/api/v0/app/roomMembers", "GET", true)
end

function TeamManager:Connect(roomId,callback)
    if(not self.connection)then
		local conn,new_roomId = TeamManager:CreateOrGetConnection(roomId);
		self.connection = conn;
    	self.roomId = new_roomId;
    	conn:Connect(callback);
        return
    end
    self.connection:Connect(callback);
end

function TeamManager:IsJoinedTeam()
    if not self.connection or not self.connection.joined then
      return false
    end
    return true
end

function TeamManager:CreateOrGetConnection(roomId)
    if(not roomId or roomId == "")then
        conn = TeamConnect:new():OnInit(roomId);
        roomId = conn:GetRoomName()
        self.connections[roomId] = conn;
        return conn,roomId
    end
    local conn = self.connections[roomId];
    if(not conn)then
        conn = TeamConnect:new():OnInit(roomId);
        self.connections[roomId] = conn;
    end
    return conn,roomId;
end

function TeamManager:GetConnect(roomId)
  return self.connections[roomId]
end

function TeamManager:ClearAllConnections()
  self.connections = {}
  self.connection = nil
  self.members = {}
  self.roomId = nil
end

TEAM_MSG = {
	INVITE_JOIN_TEAM = "jointeam", --邀请加入队伍
	JOIN_TEAM = "joined", --加入队伍
	LEAVE_TEAM = "leave", --离开队伍
	KICK_TEAM = "kick",  --踢人
	TEAM_TEXT_MESSAGE = "text_message", --队伍聊天消息
	TEAM_CALL_MESSAGE = "call_message", --队伍呼叫消息
}

function TeamManager:RefreshTeamMembers(callback)
	if not self.connection then
		if callback and type(callback) == "function" then
			callback(false)
		end
		return
	end
	self.connection:LoadTeamMembers(function(members)
		if not members or type(members) ~= "table" then
			if callback and type(callback) == "function" then
				callback(false)
			end
			return
		end
		if callback and type(callback) == "function" then
			callback(members)
		end
		local pre_member_num = #self.members
		local members_num = #members
		if pre_member_num ~= members_num then
			self.members = members
		end
		self.UpdateMemberInfo(function (isNeedRefresh)
			if isNeedRefresh then
				self.UpdateTeamPage()
			end
		end)
	end)
end

function TeamManager:OnJoinTeamResult()
	if not self.connection then
		return
	end
	self.connection.joined = true
	self:RefreshTeamMembers()
	self:UpdateTeamMembers()
end

function TeamManager:ShowTeamInVite(payload)
	local roomId = payload.roomId
	local inviteUsername = (payload.msgUsername and payload.msgUsername ~="") and payload.msgUsername or ""
	local inviteNickname = (payload.msgNickname and payload.msgNickname ~="") and payload.msgNickname or ""
	local inviteUserId = (payload.msgUserId and payload.msgUserId ~="") and payload.msgUserId or ""

	_guihelper.MessageBox(
		format(L"【%s】邀请你加入队伍!", (inviteNickname and inviteNickname ~= "") and inviteNickname or inviteUsername),
		function(res)
			if res and res == _guihelper.DialogResult.Yes then
				self:CheckCanEnter(roomId,function(canEnter)
					if canEnter then
						self:Connect(roomId,function()
							self:SendTeamMessage(TEAM_MSG.JOIN_TEAM)
						end)
					else
						GameLogic.AddBBS(nil,L"加入失败，当前队伍成员已满")
					end
				end)
			end
		end,
		_guihelper.MessageBoxButtons.YesNo,nil,nil,nil,nil,{ ok = L"同意", cancel = L"拒绝", title = L"邀请组队", }
	)
end

function TeamManager:OnMsg(payload)
	if not payload or type(payload) ~= "table" or payload.ChannelIndex ~= ChatChannel.EnumChannels.KpTeam then
		return
	end
	
	if payload.msgType == TEAM_MSG.INVITE_JOIN_TEAM then
		local inviteUsername = (payload.msgUsername and payload.msgUsername ~="") and payload.msgUsername or ""
		local inviteNickname = (payload.msgNickname and payload.msgNickname ~="") and payload.msgNickname or ""
		local roomId = payload.roomId
		if self:IsJoinedTeam() then
			self:SendMsgToUser(TEAM_MSG.JOIN_TEAM,inviteUsername,{hasJoined=true,roomId=roomId})
		end
		local inviteUserId = (payload.msgUserId and payload.msgUserId ~="") and payload.msgUserId or ""
		local ChatManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatManager.lua");
		ChatManager.CheckInBlackList(inviteUserId,function(isBlack)
			if isBlack then
				LOG.std(nil,"info","TeamManager","用户名："..(inviteUsername or "")..",已经被加入黑名单")
				return
			end
			TeamManager:ShowTeamInVite(payload)
		end)
	elseif payload.msgType == TEAM_MSG.JOIN_TEAM then
		if payload.hasJoined then
			GameLogic.AddBBS(nil,"【"..(payload.msgNickname or "").."】"..L"已经加入了队伍")
			return
		end
		local msgName = (payload.nickname and payload.nickname ~= "") and payload.nickname or payload.username
		GameLogic.AddBBS(nil,"【"..(msgName or "").."】"..L"加入了队伍")
		commonlib.TimerManager.SetTimeout(function()
			self:RefreshTeamMembers()
		end,200)
	elseif payload.msgType == TEAM_MSG.KICK_TEAM then
		local username = Mod.WorldShare.Store:Get('user/username')
		if username == payload.kickUsername then --如果被踢用户收到了这条消息，说明踢出失败了，得手动退出
			LOG.std(nil,"info","TeamManager","用户名："..(username or "")..",被踢出了队伍")
			self:LeaveTeam()
		end
		commonlib.TimerManager.SetTimeout(function()
			self:RefreshTeamMembers()
			self:UpdateTeamMembers(true)
		end,200)
	elseif payload.msgType == TEAM_MSG.LEAVE_TEAM then
		GameLogic.AddBBS(nil,"【"..(payload.nickname or "").."】"..L"离开了队伍")
		commonlib.TimerManager.SetTimeout(function()
			self:RefreshTeamMembers()
		end,200)
	elseif payload.msgType == TEAM_MSG.TEAM_TEXT_MESSAGE then
		local chatContent = (payload.chatContent and payload.chatContent ~= "") and payload.chatContent or ""
		local contentType = (payload.contentType and payload.contentType ~= "") and payload.contentType or "text"
		local msgName = (payload.nickname and payload.nickname ~= "") and payload.nickname or payload.username
		if contentType == "text" then
			self:AddLastChatMsg(payload)
		end
	elseif payload.msgType == TEAM_MSG.TEAM_CALL_MESSAGE then
		self:OnRecvCallMsg(payload)
	end
end

function TeamManager:OnRecvCallMsg(payload)
	print("TeamManager:OnRecvCallMsg=================")
	echo(payload,true)
	if payload.msgType == TEAM_MSG.TEAM_CALL_MESSAGE then
		local kpProjectId = payload.kpProjectId
		local userIds = payload.userIds
		local pos = payload.pos
		local my_userId = Mod.WorldShare.Store:Get('user/userId')
		local isCallMe = false
		if not userIds or type(userIds) ~= "table" then
			return
		end
		for k,v in pairs(userIds) do
			if v == my_userId then
				isCallMe = true
				break
			end
		end
		if isCallMe then
			self:ShowCallDialog(payload)
		end
	end
end

function TeamManager:ShowCallDialog(payload)
	local nickname = payload.nickname
	local username = payload.username
	local userId = payload.userId or 0
	local kpProjectId = payload.kpProjectId
	local pos = payload.pos
	local callStr = format(L"【%s】对你发起了召唤，是否传送过去", (((nickname and nickname ~= "") and nickname or username).."("..userId..")"))
	_guihelper.MessageBox(
		callStr,
		function(res)
			if res and res == _guihelper.DialogResult.Yes then
				local curProjectId = GameLogic.options:GetProjectId()
				if curProjectId == kpProjectId then
					if pos and pos.x then
						GameLogic.RunCommand("/lookat "..pos.x.." "..pos.y.." "..pos.z)
					end
					return
				end
				GameLogic.RunCommand(string.format("/loadworld -s -auto %d", curProjectId));  
			end
		end,
		_guihelper.MessageBoxButtons.YesNo,nil,nil,nil,nil,{ ok = L"同意", cancel = L"拒绝", title = L"召唤", }
	)
end

function TeamManager:GetLastChatMsg()
  return self.lastChatMsg
end

function TeamManager:AddLastChatMsg(chat_data)
	if not chat_data or type(chat_data) ~= "table" then
		return
	end
	if chat_data.chatContent and chat_data.chatContent ~= "" then
		chat_data.chatContent = self:BadWordsFilter(chat_data.chatContent)
	end
	local my_username = Mod.WorldShare.Store:Get('user/username')
	local is_mine = self:IsMineChatMsg(chat_data)
	self.lastChatMsg = chat_data
	local chat_id = ParaGlobal.GenerateUniqueID();
	chat_data.chatId = chat_id
	self.tempTeamChatMsgs[chat_id] = chat_data
	chat_data.is_keepwork = true
	ChatChannel.AppendChat(chat_data)
	-- self:AddToTipRoad(chat_data)	
end

function TeamManager:AddToTipRoad(chat_data)
	if not chat_data or type(chat_data) ~= "table" then
		return
	end
	local KpChatChannel = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua");
	local TipRoadManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ScreenTipRoad/TipRoadManager.lua");
	if (KpChatChannel.BulletScreenIsOpened() and KpChatChannel.IsInWorld()) then
		local mcmlStr = KpChatChannel.CreateMcmlStrToTipRoad(chat_data);
		TipRoadManager:PushNode(mcmlStr);
	end
end

function TeamManager:GetTempTeamChatMsg(chatId)
	if not chatId or chatId == "" then
		return
	end
	return self.tempTeamChatMsgs[chatId]
end

function TeamManager:CreateChatWindowMcmlStr(chat_data , isTipRoad)
	if not chat_data or type(chat_data) ~= "table" then
		return
	end
	local is_mine = self:IsMineChatMsg(chat_data)
	local chat_content = chat_data.chatContent or ""
	local player_name = is_mine and L"我" or (chat_data.nickname or chat_data.username)
	if isTipRoad then
		player_name = (chat_data.nickname or chat_data.username)
		chat_content = [[<div  style="float: left; margin-top: -1px; margin-left: 2px; color: #067AFE;" name="]] ..chat_data.username..(chat_data.chatId and "_"..chat_data.chatId or "").. [["  onclick="MyCompany.Aries.Creator.ChatSystem.KpChatHelper.ShowTeamChatMenu" >]].."["..player_name.. "]：</div>" .. chat_content
	else
		if is_mine then
			chat_content = [[<div  style="float: left; margin-top: -1px; margin-left: 2px; color: #067AFE;">]].."["..player_name.. "]：".. chat_content.. [[</div>]]
		else
			chat_content = [[<div  style="float: left; margin-top: -1px; margin-left: 2px; color: #067AFE;" name="]] ..chat_data.username..(chat_data.chatId and "_"..chat_data.chatId or "").. [["  onclick="MyCompany.Aries.Creator.ChatSystem.KpChatHelper.ShowTeamChatMenu" >]].."["..player_name.. "]：</div>" .. chat_content
		end
	end
	local isFind,_ = SmileyConfig.FindSmileyCode(chat_content)
	if isFind then
		chat_content = SmileyConfig.GenerateNormalHtml(chat_content)
	end
	
	local chat_mcml_str = [[<div>
		<div style="float: left; width: 30px; height: 18px; background: url(Texture/Aries/Creator/keepwork/Community/community_chat_32bits.png#286 236 14 14:6 6 6 6);">
			<div style="margin-left: 2px; font-size: 10px; base-font-size: 10px; color: #ffffff; ">队伍</div>
		</div>
		<div  style="float: left; margin-top: -1px; margin-left: 8px; color: #067AFE;">]]..chat_content.. [[</div>
	</div>]]
	if isTipRoad then
		chat_mcml_str = [[<div><div  style="float: left; margin-top: -1px; margin-left: 8px; color: #067AFE;">]]..chat_content.. [[</div></div>]]
	end
	return chat_mcml_str
end

function TeamManager:IsMineChatMsg(chat_data) --是否是自己发送的消息
	if not chat_data or type(chat_data) ~= "table" then
		return false
	end
	local my_username = Mod.WorldShare.Store:Get('user/username')
	if my_username and chat_data.username == my_username then
		return true
	end
	return false
end


function TeamManager:BadWordsFilter(msgdata)
  local words = ""
	if(msgdata)then
		words = BadWordFilter.FilterString(msgdata);
	end
	return words;
end

function TeamManager:ChatWithTeam(content,content_type) --队伍聊天
	self:SendTeamMessage(TEAM_MSG.TEAM_TEXT_MESSAGE,{chatContent=content,contentType=content_type or "text"})
end

function TeamManager:SendTeamMessage(msg_type,params) --发送队伍消息
	if not self.connection then
		GameLogic.AddBBS(nil,L"队伍频道已断开")
		return
	end
	local kp_msg = self:CreateMessage(msg_type)
	if not kp_msg then
		return
	end
	if params and type(params) == "table" then
		for k,v in pairs(params) do
			local payload = kp_msg.payload.payload
			payload[k] = v
		end
	end
	if msg_type == TEAM_MSG.TEAM_TEXT_MESSAGE then --队伍聊天消息，自己发送的消息
		if kp_msg.payload and kp_msg.payload.payload and type(kp_msg.payload.payload) == "table" then
			self:AddLastChatMsg(kp_msg.payload.payload)
		end
	end
	self.connection:SendBoadcastMessage(kp_msg)
end

--构建聊天消息
function TeamManager:CreateMessage(msg_type)
	if not msg_type then
		return
	end
	local ChannelIndex = ChatChannel.EnumChannels.KpTeam
	local userId = Mod.WorldShare.Store:Get('user/userId')
	local username = Mod.WorldShare.Store:Get('user/username')
	local nickname = Mod.WorldShare.Store:Get('user/nickname')
	local params = {
		msgType = msg_type,
		userId = userId,
		username = username,
		nickname = nickname,
		ChannelIndex = ChannelIndex,
	}
	if msg_type == TEAM_MSG.JOIN_TEAM then --用户回复加入队伍邀请
		params.action = "user_join_team"
		local msg = {
			eventName = "broadcast",
			room = self.roomId,
			payload = {
				payload = params
			}
		}
		return msg
	end
	if msg_type == TEAM_MSG.LEAVE_TEAM then --用户离开队伍
		params.action = "user_leave_team"
		local msg = {
			eventName = "broadcast",
			room = self.roomId,
			payload = {
				payload = params
			}
		}
		return msg
	end
	if msg_type == TEAM_MSG.KICK_TEAM then --踢人
		params.action = "user_kick_team"
		local msg = {
			eventName = "broadcast",
			room = self.roomId,
			payload = {
				payload = params
			}
		}
		return msg
	end
	if msg_type == TEAM_MSG.TEAM_TEXT_MESSAGE then
		params.action = "team_text_message"
		local msg = {
			eventName = "broadcast",
			room = self.roomId,
			payload = {
				payload = params
			}
		}
		return msg
	end
	if msg_type == TEAM_MSG.TEAM_CALL_MESSAGE then
		params.action = "team_call_message"
		local msg = {
			eventName = "broadcast",
			room = self.roomId,
			payload = {
				payload = params
			}
		}
		return msg
	end
end

function TeamManager:GetUserInfoByName(username,callback)
	if not username or username == "" then
		if callback and type(callback) == "function" then
			callback()
		end
		return 
	end
	NPL.load("(gl)script/ide/System/Encoding/base64.lua");
	local Encoding = commonlib.gettable("System.Encoding");
	local id = "kp" .. Encoding.base64(commonlib.Json.Encode({username=username}));
	keepwork.user.getinfo({
		cache_policy = "access plus 0",
        router_params = {
            id = id,
        }
    },function (err, msg, data)
		if err == 200 then
			if callback and type(callback) == "function" then
				callback(data)
			end
			return
		end
		if callback and type(callback) == "function" then
			callback()
		end
	end)
end

function TeamManager:SendMsgToUser(msg_type,username,params)
	if not self.connection then
		GameLogic.AddBBS(nil,L"创建队伍连接失败")
		return
	end
	self:GetUserInfoByName(username,function(userinfo)
		if not userinfo then
			return
		end
		local username = Mod.WorldShare.Store:Get('user/username')
		local nickname = Mod.WorldShare.Store:Get('user/nickname')
		local userId = Mod.WorldShare.Store:Get('user/userId')
		local msg ={
			msgType = msg_type,
			roomId = self.roomId,
			msgUsername = username,
			msgNickname = nickname,
			msgUserId = userId,
			ChannelIndex = ChatChannel.EnumChannels.KpTeam,
		}
		if params and type(params) == "table" then
			for k,v in pairs(params) do
				msg[k] = v
			end
		end
		keepwork.chat.msg({
			userIds={userinfo.id}, --发送对象
			msg = msg,
		},function(err,msg,data)
			if err == 200 then
				GameLogic.AddBBS(nil,"发送成功")
			else
				GameLogic.AddBBS(nil,"发送失败")
			end
		end)
	end)
end

function TeamManager:IsMaxMember()
	if not self.members or type(self.members) ~= "table" or #self.members >= max_team_member_num then
		return true
	end
	return false
end

function TeamManager:CheckCanEnter(roomId,callback)
	if not roomId or roomId == "" then
		if callback and type(callback) == "function" then
			callback(false)
		end
		return
	end
	keepwork.chat.roomMembers({
		room = roomId, 
	 },function(err,msg,data)
		 print("CheckCanEnter=========",err)
		 if(err ~= 200 or not data or type(data) ~= "table")then
			 LOG.std(nil,"info","TeamManager","加载成员失败,房间名称是"..(roomId or "")..",错误码是"..(err or ""))
			 if callback and type(callback) == "function" then
				callback(false)
			 end
			 return
		 end
		 local memberNum = #data
		 if(callback and type(callback) == "function")then
			 callback(memberNum < max_team_member_num)
		 end
	 end)
end

function TeamManager:InviteUserToTeam(username)
	--print("InviteUserToTeam===========",username)
	--echo(self.members)
	if self:IsJoinedTeam() and not self:IsTeamLeader() then
		GameLogic.AddBBS(nil,L"您不是当前小队的队长，无法邀请其他人")
		return 
	end
	if self:IsMaxMember() then
		GameLogic.AddBBS(nil,L"邀请失败，队伍成员已满")
		return
	end
	self:SendMsgToUser(TEAM_MSG.INVITE_JOIN_TEAM,username)
end

function TeamManager:LeaveTeam()
	if not self.is_send_leave_team_msg then
		self:SendTeamMessage(TEAM_MSG.LEAVE_TEAM) 
		if self.connection then
			self.connection:LeaveTeam()
		end
		self.is_send_leave_team_msg = true
	end
end

function TeamManager:OnLeaveTeamResult()
	if self.connection and self.is_send_leave_team_msg then
		self.is_send_leave_team_msg = false
		self:RefreshTeamMembers()
		self:UpdateTeamMembers(true)
	end
end

function TeamManager:KickUserFromTeam(username)
	self:SendTeamMessage(TEAM_MSG.KICK_TEAM,{kickUsername=username})
	if self.connection then
		self.connection:KickUserFromTeam(username)
	end
end

function TeamManager:IsTeamLeader()
	if not self.members or type(self.members) ~= "table" or #self.members == 0 then
		return true
	end
	local my_userId = Mod.WorldShare.Store:Get('user/userId')
	local leader = self.members[1]
	if not leader or type(leader) ~= "table" then
		return true
	end
	if leader.userId == my_userId then
		return true
	end
	return false
end

function TeamManager:IsShowTeamMember()
	local isJoinedTeam = self:IsJoinedTeam()
	local members = self.members
	if not isJoinedTeam or not members or type(members) ~= "table" or #members == 0 then
		return false
	end
	local isInMember = false
	for k,v in pairs(members) do
		if v.username == Mod.WorldShare.Store:Get('user/username') then
			isInMember = true
			break
		end
	end
	if not isInMember then
		return false
	end
	return true
end

function TeamManager:GetAllTeamInfo()
	return self.members
end

function TeamManager:GetRoom()
	return self.roomId
end

function TeamManager.UpdateMemberInfo(call_back_func)
	if not TeamManager:IsShowTeamMember() then
		TeamManager:ClearAllConnections()
		TeamManager.UpdateTeamPage()
		return
	end
	
	local getMemberInfo
	local isUpateMemberInfo = false
	getMemberInfo = function(index)
		if index > #TeamManager.members then
			if call_back_func and type(call_back_func) == "function" then
				call_back_func(isUpateMemberInfo)
			end
			return
		end
		local member = TeamManager.members[index]
		if not member or type(member) ~= "table" then
			getMemberInfo(index+1)
			return
		end
		if member.userinfo and type(member.userinfo) == "table" then
			getMemberInfo(index+1)
			return
		end
		local username = member.username
		if not username or username == "" then
			getMemberInfo(index+1)
			return
		end
		isUpateMemberInfo = true
		TeamManager:GetUserInfoByName(username,function(userinfo)
			if not userinfo then
				getMemberInfo(index+1)
				return
			end
			local member = TeamManager.members[index]
			if not member or type(member) ~= "table" then
				getMemberInfo(index+1)
				return
			end
			TeamManager.members[index].userinfo = userinfo
			getMemberInfo(index+1)
		end)
	end
	getMemberInfo(1)	
end

function TeamManager.IsShowRoleInfo() --是否显示自己头像信息
	-- return AppGeneralGameClient:IsLogin() or NetworkMain:IsServerStarted()
end

function TeamManager.UpdateTeamPage()
	TeamPlayerPage.ShowPage()
	print("UpdateTeamPage======================")
	local TeamUserCtrl = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/TeamUserCtrl.lua");
	TeamUserCtrl.CheckShow()
end

function TeamManager:SendCallMessage(userId)
	local isJoinedTeam = self:IsJoinedTeam()
	if not isJoinedTeam then
		GameLogic.AddBBS(nil,L"您还没有加入队伍")
		return
	end
	local team_member_num = #self.members
	if team_member_num <=1 then
		GameLogic.AddBBS(nil,L"当前队伍人数不足，无法发起呼叫")
		return
	end
	if not self:IsTeamLeader() then
		GameLogic.AddBBS(nil,L"您不是当前小队的队长，无法召唤队员")
		return
	end
	local my_userId = Mod.WorldShare.Store:Get('user/userId')
	if userId and my_userId == tonumber(userId) then
		GameLogic.AddBBS(nil,L"您不能呼叫自己")
		return
	end
	local player = GameLogic.EntityManager.GetPlayer()
	local bx,by,bz = player and player:GetBlockPos()
	if not bx or not by or not bz then
		bx,by,bz = 19200,5,19200
	end
	local callMsg = {
		kpProjectId = GameLogic.options:GetProjectId(),
		pos = {x=bx,y=by,z=bz},
	}
	if not userId or tonumber(userId) <= 0 then
		callMsg.userIds = {}
		for k,v in pairs(self.members) do
			if v.userId ~= my_userId then
				table.insert(callMsg.userIds,v.userId)
			end
		end
	else
		callMsg.userIds = {userId}
	end
	self:SendTeamMessage(TEAM_MSG.TEAM_CALL_MESSAGE,callMsg)
end

function TeamManager:UpdateTeamMembers(bStop)
	if bStop then
		if self.update_members_timer then
			self.update_members_timer:Change()
			self.update_members_timer = nil
		end
		return
	end
	self.update_members_timer = self.update_members_timer or commonlib.Timer:new({callbackFunc = function(timer)
		self:RefreshTeamMembers()
	end})
	self.update_members_timer:Change(500,20*1000) --500ms后开始更新，每20秒更新一次
end
