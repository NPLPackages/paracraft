--[[
    local ChatManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatManager.lua");
    ChatManager.StaticInit();
]]

local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
local TeamManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/TeamManager.lua");
local UserInfoCtrl = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/UserInfoCtrl.lua");
local OperateMenuPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/OperateMenuPage.lua");
local KpChatChannel = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua");
local PrivateChatManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/PrivateChatManager.lua");
local ChatManager = NPL.export()
ChatManager.blackList = {}
ChatManager.isAddBlackList = {}
local init = false;
function ChatManager.StaticInit()
	if (init) then return end
	init = true;
    TeamManager:InitHttpApi()
	ChatManager.OnKeepWorkLogin_Callback()
	GameLogic.GetFilters():add_filter("OnKeepWorkLogin", ChatManager.OnKeepWorkLogin_Callback);
	GameLogic.GetFilters():add_filter("OnKeepWorkLogout", ChatManager.OnKeepWorkLogout_Callback)
	GameLogic.GetFilters():add_filter("ConnectServer", ChatManager.ConnectWorldServer);
	GameLogic.GetFilters():add_filter("exit_world_server", ChatManager.ExitWorldServer);
	GameLogic.GetFilters():add_filter("ggs", ChatManager.OnRecvGGSMsg)
	GameLogic.GetFilters():remove_filter("OnGGSLogin",  ChatManager.OnGGSLogIn);
    GameLogic.GetFilters():add_filter("OnGGSLogin",  ChatManager.OnGGSLogIn);

	GameLogic.GetFilters():remove_filter("BaseContextMouseReleaseEvent", ChatManager.OnMouseReleaseEvent)
    GameLogic.GetFilters():add_filter("BaseContextMouseReleaseEvent", ChatManager.OnMouseReleaseEvent)

	GameLogic.GetFilters():remove_filter("KeyReleaseEvent", ChatManager.KeyReleaseEvent)
	GameLogic.GetFilters():add_filter("KeyReleaseEvent",ChatManager.KeyReleaseEvent)

end

function ChatManager.OnKeepWorkLogin_Callback()
	LOG.std(nil,"info","ChatManager","OnKeepWorkLogin_Callback==========>")
	if (KpChatChannel.client) then
		LOG.std(nil,"info","ChatManager","OnKeepWorkLogin_Callback==========")
		KpChatChannel.client:AddEventListener("OnOpen",ChatManager.OnOpen,ChatManager);
		KpChatChannel.client:AddEventListener("OnMsg",ChatManager.OnMsg,ChatManager);
		KpChatChannel.client:AddEventListener("OnClose",ChatManager.OnClose,ChatManager);
	end
end

function ChatManager.OnKeepWorkLogout_Callback()
	LOG.std(nil,"info","ChatManager","OnKeepWorkLogout_Callback=========>")
	if (KpChatChannel.client) then
		LOG.std(nil,"info","ChatManager","OnKeepWorkLogout_Callback=========")
		KpChatChannel.client:RemoveEventListener("OnOpen",ChatManager.OnOpen,ChatManager);
		KpChatChannel.client:RemoveEventListener("OnMsg",ChatManager.OnMsg,ChatManager);
		KpChatChannel.client:RemoveEventListener("OnClose",ChatManager.OnClose,ChatManager);
	end
end

function ChatManager.OnMouseReleaseEvent()
	local result = Game.SelectionManager:GetPickingResult();
	if result and not result.entity then -- 点击非实体
		if UserInfoCtrl.IsVisible() then
			UserInfoCtrl.ClosePage()
		end
		OperateMenuPage.HideMenuPanel()
	end
end

function ChatManager.KeyReleaseEvent(callbackVal, event)
	if event.keyname == "DIK_ESCAPE" then
		if UserInfoCtrl.IsVisible() then
			UserInfoCtrl.ClosePage()
			event:accept()
		end
		OperateMenuPage.HideMenuPanel()
	end
	return callbackVal,event
end

function ChatManager.OnOpen(self)

end

function ChatManager.OnClose(self)

end

function ChatManager.OnMsg(self, msg)
    -- print("chat manager OnMsg====================")
    -- echo(msg)
	if (not msg or not msg.data) then
        return
    end

    msg = msg.data;
    local eio_pkt_name = msg.eio_pkt_name;
    local sio_pkt_name = msg.sio_pkt_name;
	-- print("eio_pkt_name:",eio_pkt_name)
	-- print("sio_pkt_name:",sio_pkt_name)
    if (eio_pkt_name == "message" and sio_pkt_name =="event") then
        local body = msg.body or {};
        local key = body[1] or {};
        local info = body[2] or {};
        local payload = info.payload;
        local meta = info.meta;
        local action = info.action;
        local userInfo = info.userInfo;

		-- print("body==============")
		-- echo(body)
		-- print("key================")
		-- echo(key)
		-- print("info===============")
		-- echo(info)
		-- print("payload============")
		-- echo(payload)
		-- print("meta===============")
		-- echo(meta)
		-- print("action============")
		-- echo(action)
		-- print("userInfo==========")
		-- echo(userInfo)
		if key == "leave/ack" then
			ChatManager.OnLeaveTeamResult(info == "OK")
		end
		if key == "join/ack" then
			ChatManager.OnJoinTeamResult(info == "OK")
		end
		if payload and payload.ChannelIndex == ChatChannel.EnumChannels.KpTeam then
			ChatManager.ReceiveTeamMessage(payload)
			return
		end
		if payload and payload.ChannelIndex == ChatChannel.EnumChannels.KpPrivate then
			ChatManager.ReceivePrivateMessage(payload)
			return
		end
	end
end

function ChatManager.HasJoinedTeam()
	return TeamManager:IsJoinedTeam()
end

function ChatManager.GetTeamRoom()
	return TeamManager:GetRoom()
end

function ChatManager.SendMessage(ChannelIndex,words,chatType)
	if not words or words == "" then
		return
	end
	if ChannelIndex == ChatChannel.EnumChannels.KpTeam then
		if ChatManager.HasJoinedTeam() then
			if ChatManager.IsTeamCall(words) then
				local _,nid = ChatManager.GetChatContent(words)
				print("ChatManager.SendMessage==============",words,nid)
				TeamManager:SendCallMessage(nid)
				return true
			end
			TeamManager:ChatWithTeam(words,chatType)
			return true
		end
		GameLogic.AddBBS(nil, L"你还没有加入队伍，无法发送组队消息。", 5000,"255 0 0")
		return false
	end
	if ChannelIndex == ChatChannel.EnumChannels.KpPrivate then
		local content,nid = ChatManager.GetChatContent(words)
		print("ChatManager.SendMessage=================",content,nid)
		if not content or content == "" then
			return false
		end
		if not nid or nid == "" then
			nid = ChatManager.GetLastChatUser()
		end
		if not nid or nid == "" then
			GameLogic.AddBBS(nil, L"你还没有选择对话对象，无法发送消息。", 5000,"255 0 0")
			return false
		end
		print("ChatManager.SendMessage=",content,nid)
		PrivateChatManager:ChatWithUser(nid,content) 
		return true
	end
end

function ChatManager.SendPrivateMessage(userId,words)
	if not words or words == "" then
		return
	end
	if not userId or userId == "" then
		return
	end
	PrivateChatManager:ChatWithUser(userId,words)
end

function ChatManager.GetLastChatUser()
	local lastMsg = PrivateChatManager:GetLastChatMsg() or {}
	return lastMsg.msgUserId
end		

function ChatManager.IsChatCommand(words)
	if not words or words == "" or not System.options.isCommunity then
		return false
	end
	local cmd = ChatManager.GetChatCmd(words)
	if cmd == "/s " or cmd == "/w " or cmd == "/r " or cmd == "/p " or cmd =="/summon " then
		return true
	end
	return false
end

function ChatManager.GetChatCmd(words)
	if not words or words == "" then
		return words
	end
	words = string.lower(words):gsub("^%s*(.-)", "%1")
	local cmd = string.match(words, "/[%a]+%s")
	if not cmd or cmd == "" then
		cmd = string.match(words, "/[%a]+")
		if cmd and cmd:find("summon") then
			cmd = cmd .. " "
		end
	end
	return cmd
end

function ChatManager.IsTeamCall(words)
	if not words or words == "" then
		return false
	end
	local cmd = ChatManager.GetChatCmd(words)
	if cmd == "/summon " then
		return true
	end
	return false
end

function ChatManager.GetChatData(chatId,chatType)
	if chatType == "private" then
		return PrivateChatManager:GetTempPrivateChatMsg(chatId)
	end
	if chatType == "team" then
		return TeamManager:GetTempTeamChatMsg(chatId)
	end
end


local allChanels = {21,22,23,26,27}
function ChatManager.GetChatDataByChannel(channelIndex)
	if not channelIndex then
		return ChatChannel.GetChat(allChanels)
	end
	return ChatChannel.GetChat({channelIndex})
end

function ChatManager.GetChatChanel(words)
	if not ChatManager.IsChatCommand(words) then
		return words
	end
	words = string.lower(words):gsub("^%s*(.-)", "%1")
	local cmd = ChatManager.GetChatCmd(words)
	if cmd == "/s " then
		return ChatChannel.EnumChannels.KpNearBy
	end
	if cmd == "/w " then
		local nid = string.match(words, "/w%s*(%d+)")
		if nid then
			return ChatChannel.EnumChannels.KpPrivate, tonumber(nid)
		end
		return ChatChannel.EnumChannels.KpPrivate, -1
	end
	if cmd == "/r " then
		return ChatChannel.EnumChannels.KpPrivate, 0
	end
	if cmd == "/p " or cmd == "/summon " then
		return ChatChannel.EnumChannels.KpTeam
	end
	return nil
end

function ChatManager.GetChatContent(words)
	if not ChatManager.IsChatCommand(words) then
		return words
	end
	words = string.lower(words):gsub("^%s*(.-)", "%1")
	local cmd = ChatManager.GetChatCmd(words)
	if cmd == "/s " or cmd == "/p " or cmd == "/r " then
		return string.sub(words, string.len(cmd) + 1)
	end
	if cmd == "/summon " then
		local nid = string.match(words, "/summon%s*(%d+)")
		if nid then
			return string.sub(words, string.len(cmd) + string.len(nid) + 2),nid
		end
	end
	if cmd == "/w " then
		local nid = string.match(words, "/w%s*(%d+)")
		if nid then
			return string.sub(words, string.len(cmd) + string.len(nid) + 2),nid
		end
		return nil	
	end
end



---------------------------------------
--------------- 队伍逻辑 ---------------
---------------------------------------
function ChatManager.ReceiveTeamMessage(msg)
	echo("ReceiveTeamMessage:================")
	-- echo(msg)
	TeamManager:OnMsg(msg)
end

function ChatManager.ReceivePrivateMessage(msg)
	echo("ReceivePrivateMessage:=")
	-- echo(msg)
	PrivateChatManager:OnMsg(msg)
end

function ChatManager.OnJoinTeamResult(result)
	if result then
		TeamManager:OnJoinTeamResult()
	end
end

function ChatManager.OnLeaveTeamResult(result)
	if result then
		TeamManager:OnLeaveTeamResult()
	end
end
---------------------------------------
--------------- 队伍逻辑 ---------------
---------------------------------------


---------------------------------------
--------------- 其他逻辑 ---------------
---------------------------------------
function ChatManager.ConnectWorldServer(msg)
	TeamManager.UpdateTeamPage()
	return msg
end

function ChatManager.ExitWorldServer(msg)
	TeamManager.UpdateTeamPage()
end

function ChatManager.OnGGSLogIn(packet)
	if packet then
		TeamManager.UpdateTeamPage()
	end
	return packet
end

function ChatManager.OnRecvGGSMsg(msg)
	local isRecv = false;
	if msg and (msg.action == "LoadWorld" or msg.action == "ExitWorld") then
		TeamManager.UpdateTeamPage()
		isRecv = true;
	end
	msg.isRecv = isRecv;
	return msg
end

function ChatManager.CreateMcmlStrToChatWindow(chatdata)
    if(not chatdata)then
        return ""
    end
    local mcmlStr = ""
	if chatdata.ChannelIndex == ChatChannel.EnumChannels.KpTeam then
		mcmlStr = TeamManager:CreateChatWindowMcmlStr(chatdata)
	elseif chatdata.ChannelIndex == ChatChannel.EnumChannels.KpPrivate then
		mcmlStr = PrivateChatManager:CreateChatWindowMcmlStr(chatdata)
	elseif chatdata.ChannelIndex == ChatChannel.EnumChannels.KpNearBy then
		mcmlStr = ChatManager.CreateLocalChatWindowMcmlStr(chatdata)
	end
	return mcmlStr
end

function ChatManager.CreateMcmlStrToTipRoad(chatdata)
	if(not chatdata)then
        return ""
    end
    local mcmlStr = ""
	if chatdata.ChannelIndex == ChatChannel.EnumChannels.KpTeam then
		mcmlStr = TeamManager:CreateChatWindowMcmlStr(chatdata,true)
	elseif chatdata.ChannelIndex == ChatChannel.EnumChannels.KpNearBy then
		mcmlStr = ChatManager.CreateLocalChatWindowMcmlStr(chatdata,true)
	end
	return mcmlStr
end

function ChatManager.CreateLocalChatWindowMcmlStr(chatdata, isTipRoad)
	if not chatdata or not chatdata.words or chatdata.words == "" then
		return ""
	end
	local SmileyConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/SmileyConfig.lua")
	local my_userId = Mod.WorldShare.Store:Get("user/userId") or -1
	local is_mine = my_userId == chatdata.kp_from_id
	local player_name = is_mine and L"我" or (chatdata.kp_from_name or chatdata.kp_username)
	local chat_content = chatdata.words or ""
	if isTipRoad then
		player_name = (chatdata.kp_from_name or chatdata.kp_username)
		chat_content = [[<div  style="float: left; margin-top: -1px; margin-left: 2px; color: #FF5E11;" name="]] ..chatdata.kp_username..(chatdata.kp_from_id and "_"..chatdata.kp_from_id or "").. [["  onclick="MyCompany.Aries.Creator.ChatSystem.KpChatHelper.ShowPrivateChatMenu" >]].."["..player_name.. "]：</div>" .. chat_content
	else
		if is_mine then
			chat_content = [[<div  style="float: left; margin-top: -1px; margin-left: 2px; color: #FF5E11;">]].."["..player_name.. "]：</div>" .. chat_content
		else
			chat_content = [[<div  style="float: left; margin-top: -1px; margin-left: 2px; color: #FF5E11;" name="]] ..chatdata.kp_username..(chatdata.kp_from_id and "_"..chatdata.kp_from_id or "").. [["  onclick="MyCompany.Aries.Creator.ChatSystem.KpChatHelper.ShowPrivateChatMenu" >]].."["..player_name.. "]：</div>" .. chat_content
		end
	end
	local isFind,_ = SmileyConfig.FindSmileyCode(chat_content)
	if isFind then
		chat_content = SmileyConfig.GenerateNormalHtml(chat_content)
	end
	
	local chat_mcml_str = [[<div>
	<div style="float: left; width: 30px; height: 18px; background: url(Texture/Aries/Creator/keepwork/Community/community_chat_32bits.png#268 218 14 14:6 6 6 6);">
		<div style="margin-left: 2px; font-size: 10px; base-font-size: 10px; color: #ffffff; ">本地</div>
	</div>
	<div  style="float: left; margin-top: -1px; margin-left: 8px; color: #ffffff;">]]..chat_content.. [[</div></div>]]

	if isTipRoad then
		chat_mcml_str = [[<div><div  style="float: left; margin-top: -1px; margin-left: 8px; color: #ffffff;">]]..chat_content.. [[</div></div>]]
	end
	return chat_mcml_str
end

function ChatManager.CreateMcmlStrByText(text,default_font_size)
	if not text or text == "" then
		return ""
	end
	local SmileyConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/SmileyConfig.lua")
	return SmileyConfig.GenerateChatPageHtml(text,default_font_size)
end

function ChatManager.ApplyFriend(userId,callback)
	keepwork.friend.friendsList({
        headers = {
            ["x-per-page"] = 200,
            ["x-page"] = 1,
        }
	},function(err, msg, data)
		-- commonlib.echo(data, true)
		if err == 200 then
			local FriendList = {}
			for k, v in pairs(data) do
				if v.status == 1 or v.status == 3 then --当status不为1时，表示该好友已删除
					if v.friend and type(v.friend) == "table" then
						v.username = v.friend.username
						v.nickname = v.friend.nickname
						v.portrait = v.friend.portrait
					end
                    FriendList[v.friendId] = v
                end
			end
			if FriendList[userId] then
				GameLogic.AddBBS(nil, L"已经是好友了")
				return
			end
			keepwork.friend.applyFriend({
				friendId = userId,
				remark = "申请添加好友"
			},function(err, msg, data)
				if err == 200 then
					GameLogic.AddBBS("statusBar", L"已向对方发出好友请求，请耐心等待回复。", 5000, "0 255 0");
					if callback and type(callback) == "function" then
						callback()
					end
				else
					GameLogic.AddBBS(nil, L"申请添加好友失败,请重试~")
				end
			end)
		else
			GameLogic.AddBBS(nil, L"获取好友列表失败,请重试~")
		end
	end)
end

function ChatManager.CheckInBlackList(userId,callback)
	if not userId or not tonumber(userId) or tonumber(userId) <= 0 then
		if callback and type(callback) == "function" then
			callback(false)
		else
			GameLogic.AddBBS(nil, L"参数错误")
		end
		return
	end
	if not ChatManager.isAddBlackList then
		ChatManager.isAddBlackList = {}
	end
	if ChatManager.isAddBlackList[userId] == nil then
		keepwork.friend.getBlacklist({},function(err, msg, data)
			if err ~= 200 then
				if callback and type(callback) == "function" then
					callback(false)
				end
				return
			end
			for _, item in ipairs(data) do
				if item and item.friendId then
					ChatManager.isAddBlackList[item.friendId] = true
				end
			end
			if callback and type(callback) == "function" then
				callback(ChatManager.IsBlackList(userId))
			end
		end)
		return
	end
	if callback and type(callback) == "function" then
		callback(ChatManager.IsBlackList(userId))
	end
end

function ChatManager.RemoveBlackList(data,callback)
    if data and type(data) == "table" then
		-- echo(data,true)
        local friendId = tonumber(data.userId)
		if ChatManager.isAddBlackList then
        	ChatManager.isAddBlackList[friendId] = nil
		else
			ChatManager.isAddBlackList = {}
		end
    end
end

function ChatManager.IsBlackList(userId)
    if not userId then
        return false
    end
    return ChatManager.isAddBlackList and ChatManager.isAddBlackList[userId]
end

function ChatManager.CloseSmileyPage()
	local NewSmileyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/NewSmileyPage.lua");
	NewSmileyPage.ClosePage()
end

