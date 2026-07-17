--[[
Title: PrivateChatManager
Author(s): 
Date: 2020/9/7
Desc:  
Use Lib:
-------------------------------------------------------
--私聊
local PrivateChatManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/PrivateChatManager.lua");
PrivateChatManager:ChatWithUser("568435","aaaa#89#2234")
--]]
NPL.load("(gl)script/apps/Aries/Chat/BadWordFilter.lua");
local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local TeamConnect = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/TeamConnect.lua");
local FriendChatPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendChatPage.lua");
local FriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
local BadWordFilter = commonlib.gettable("MyCompany.Aries.Chat.BadWordFilter");
local TipRoadManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ScreenTipRoad/TipRoadManager.lua"); --弹幕显示
local PrivateChatConnect = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/PrivateChatConnect.lua");
local SmileyConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/SmileyConfig.lua");
local PrivateChatManager = NPL.export();

local UserData = {}
PrivateChatManager.connections = {};
PrivateChatManager.rooms = {};
PrivateChatManager.lastChatMsg = nil -- 各个好友最后的聊天信息 包括已读的和未读的
PrivateChatManager.tempPrivateChatMsgs = {} -- 临时聊天内容

function PrivateChatManager:OnMsg(payload)
	if not payload or type(payload) ~= "table" or payload.ChannelIndex ~= ChatChannel.EnumChannels.KpPrivate then
		return
	end
	if payload.msgType == "private_chat_msg" then
		local chatContent = (payload.chatContent and payload.chatContent ~= "") and payload.chatContent or ""
		local contentType = (payload.contentType and payload.contentType ~= "") and payload.contentType or "text"
		if contentType == "text" then
			self:AddLastChatMsg(payload)
		end
	end
end

function PrivateChatManager:GetLastChatMsg()
  return self.lastChatMsg
end

function PrivateChatManager:AddLastChatMsg(chat_data)
	if not chat_data or type(chat_data) ~= "table" then
		return
	end
	if chat_data.chatContent and chat_data.chatContent ~= "" then
		chat_data.chatContent = self:BadWordsFilter(chat_data.chatContent) --过滤敏感词
	end
	local my_username = Mod.WorldShare.Store:Get('user/username')
	local is_mine = self:IsMineChatMsg(chat_data)
	if not is_mine then -- 最后的不是自己发送的消息
		self.lastChatMsg = chat_data
	end
	local chat_id = ParaGlobal.GenerateUniqueID();
	self.tempPrivateChatMsgs[chat_id] = chat_data
	chat_data.chat_id = chat_id
	chat_data.is_keepwork = true
	ChatChannel.AppendChat(chat_data)
end

function PrivateChatManager:GetTempPrivateChatMsg(chatId)
	if not chatId or type(chatId) ~= "string" then
		return
	end
	return self.tempPrivateChatMsgs[chatId]
end


function PrivateChatManager:CreateChatWindowMcmlStr(chat_data)
	if not chat_data or type(chat_data) ~= "table" then
		return
	end
	local is_mine = self:IsMineChatMsg(chat_data)
	local chat_content = chat_data.chatContent or ""
	local player_name = is_mine and L"我" or (chat_data.msgNickname or chat_data.msgUsername)
	local to_player_name = (chat_data.toNickname and chat_data.toNickname ~= "") and chat_data.toNickname or chat_data.toUsername
	if is_mine then
		chat_content = [[<div  style="float: left; margin-top: -1px; margin-left: 2px; color: #A641E9;">]]..L"发送给["..to_player_name.. "]：".. chat_content.. [[</div>]]
	else
		chat_content = [[<div  style="float: left; margin-top: -1px; margin-left: 2px; color: #A641E9;" name="]] ..chat_data.msgUsername..(chat_data.chat_id and "_"..chat_data.chat_id or "").. [["  onclick="MyCompany.Aries.Creator.ChatSystem.KpChatHelper.ShowPrivateChatMenu" >]].."["..player_name.. "]：</div>" .. chat_content
	end
	local isFind,_ = SmileyConfig.FindSmileyCode(chat_content)
	if isFind then
		chat_content = SmileyConfig.GenerateNormalHtml(chat_content)
	end
	
	local chat_mcml_str = [[<div>
	<div style="float: left; width: 30px; height: 18px; background: url(Texture/Aries/Creator/keepwork/Community/community_chat_32bits.png#304 218 14 14:6 6 6 6);">
		<div style="margin-left: 2px; font-size: 10px; base-font-size: 10px; color: #ffffff; ">私聊</div>
	</div>
	<div  style="float: left; margin-top: -1px; margin-left: 8px; color: #A641E9;">]]..chat_content.. [[</div></div>]]
	return chat_mcml_str
end

function PrivateChatManager:BadWordsFilter(msgdata)
  local words = ""
	if(msgdata)then
		words = BadWordFilter.FilterString(msgdata);
	end
	return words;
end

function PrivateChatManager:ChatWithUser(userId,content,content_type) --私聊
	self:SendMsgToUser("private_chat_msg",userId,{chatContent=content,contentType=content_type or "text"})
end

function PrivateChatManager:IsMineChatMsg(chat_data) --是否是自己发送的消息
	if not chat_data or type(chat_data) ~= "table" then
		return false
	end
	local my_username = Mod.WorldShare.Store:Get('user/username')
	if my_username and chat_data.msgUsername == my_username then
		return true
	end
	return false
end

function PrivateChatManager:GetUserInfoById(userId,callback)
	NPL.load("(gl)script/ide/System/Encoding/base64.lua");
	local Encoding = commonlib.gettable("System.Encoding");
	local id = "kp" .. Encoding.base64(commonlib.Json.Encode({userId=userId}));
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


function PrivateChatManager:SendMsgToUser(msg_type,to_userId,params)
	if not to_userId or tonumber(to_userId) <= 0 then
		LOG.std(nil,"error","PrivateChatManager","SendMsgToUser to_userId is nil or invalid")
		return
	end
	self:GetUserInfoById(tonumber(to_userId),function(userdata)
		if not userdata or type(userdata) ~= "table" then
			LOG.std(nil,"error","PrivateChatManager","SendMsgToUser userdata is nil or invalid")
			GameLogic.AddBBS(nil,L"发送失败,当前发送对象不存在")
			return
		end
		local to_username = userdata.username
		local to_nickname = userdata.nickname
		local my_username = Mod.WorldShare.Store:Get('user/username')
		local my_nickname = Mod.WorldShare.Store:Get('user/nickname')
		local my_userId = Mod.WorldShare.Store:Get('user/userId')
		local chat_msg ={
			msgType = msg_type,
			msgUsername = my_username,
			msgNickname = my_nickname,
			msgUserId = my_userId,
			ChannelIndex = ChatChannel.EnumChannels.KpPrivate,
			toUserId = to_userId,
			toUsername = to_username,
			toNickname = to_nickname,
		}
		if params and type(params) == "table" then
			for k,v in pairs(params) do
				chat_msg[k] = v
			end
		end
		LOG.std(nil,"info","PrivateChatManager","SendMsgToUser to_userId:================>>"..to_userId)
		keepwork.chat.msg({
			userIds={to_userId}, --发送对象
			msg = chat_msg,
		},function(err,msg,data)
			print("err=============",err)
			echo(data)
			if err == 200 then
				-- GameLogic.AddBBS(nil,"发送成功")
				self:AddLastChatMsg(chat_msg)
			else
				GameLogic.AddBBS(nil,"发送失败")
			end
		end)
	end)
end
