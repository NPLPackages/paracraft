--[[
Title: FriendManager
Author(s): 
Date: 2020/9/7
Desc:  
Use Lib:
-------------------------------------------------------
local FriendManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendManager.lua");
FriendManager:LoadAllUnReadMsgs();
local userId = 763;
local conn = FriendManager:Connect(userId,function()
    FriendManager:SendMessage(userId,{ words = "hello world" })
end)
--]]
local FriendConnection = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendConnection.lua");
local FriendChatPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendChatPage.lua");
local FriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
NPL.load("(gl)script/apps/Aries/Chat/BadWordFilter.lua");
local BadWordFilter = commonlib.gettable("MyCompany.Aries.Chat.BadWordFilter");
local FriendManager = NPL.export();

local UserData = {}
FriendManager.connections = {};
FriendManager.unread_msgs = {};
FriendManager.unread_msgs_loaded = false;
FriendManager.lastChatMsg = nil -- 各个好友最后的聊天信息 包括已读的和未读的
--[[
{
  data={
    {
      createdAt="2020-09-07T06:03:56.000Z",
      id=15,
      latestMsg={
        content="hello world",
        createdAt="2020-09-07T06:03:59.000Z",
        id=13,
        msgKey="474ca760-4c10-48dc-b13e-21bd9cb619ae",
        roomId=8,
        senderId=776,
        updatedAt="2020-09-07T06:03:59.000Z" 
      },
      latestMsgId=13,
      room={
        createdAt="2020-09-07T06:03:56.000Z",
        id=8,
        name="__chat_763_776__",
        updatedAt="2020-09-07T06:03:56.000Z" 
      },
      roomId=8,
      unReadCnt=2,
      updatedAt="2020-09-07T06:03:59.000Z",
      userId=763 
    },
    {
      createdAt="2020-09-07T02:51:17.000Z",
      id=2,
      latestMsg={
        content="hello world",
        createdAt="2020-09-07T05:51:54.000Z",
        id=11,
        msgKey="a15a301e-4790-4f93-a1fe-e08169ab7a27",
        roomId=1,
        senderId=760,
        updatedAt="2020-09-07T05:51:54.000Z" 
      },
      latestMsgId=11,
      room={
        createdAt="2020-09-07T02:51:17.000Z",
        id=1,
        name="__chat_760_763__",
        updatedAt="2020-09-07T05:56:11.000Z" 
      },
      roomId=1,
      unReadCnt=11,
      updatedAt="2020-09-07T05:56:11.000Z",
      userId=763 
    } 
  },
  message="请求成功" 
}
--]]
function FriendManager:InitUserData(user_data)
  UserData = user_data
end

function FriendManager:LoadAllUnReadMsgs(callback, forced_load)
    if(FriendManager.unread_msgs_loaded and not forced_load)then
        if(callback)then
            callback();
        end
        return
    end
    FriendManager.unread_msgs = {};
    keepwork.friends.getUnReadMsgCnt({
        },function(err, msg, data)
            -- commonlib.echo("==========LoadAllUnReadMsgs");
            -- commonlib.echo(err);
            -- commonlib.echo(msg);
            -- commonlib.echo(data,true);
            if(err ~= 200)then
                return
            end
            FriendManager.unread_msgs = data or {};
            FriendManager.unread_msgs_loaded = true;
            if(callback)then
                callback();
            end
        end)
end
function FriendManager:Connect(userId,callback)
    local conn = FriendManager:CreateOrGetConnection(userId);
    conn:Connect(callback);
end
function FriendManager:CreateOrGetConnection(userId)
    if(not userId)then
        return
    end
    local conn = self.connections[userId];
    if(not conn)then
        conn = FriendConnection:new():OnInit(userId);
        self.connections[userId] = conn;
    end
    return conn;
end

function FriendManager:ClearAllConnections()
  self.connections = {}
end

--[[
----------------------payload

 {
  ChannelIndex=25,
  content="hello world",
  id=776,
  msgKey="2b051a59-a4b1-47da-95c2-5bb57688eb07",
  nickname="zhangleio5",
  orgAdmin=0,
  student=0,
  tLevel=0,
  toid=763,
  type=4,
  username="zhangleio5",
  vip=0,
  worldId=1192 
}

----------------------full_msg
 {
  body={
    "app/msg",
    {
      action="msg",
      meta={
        client="ZogAvQYR0eRYM7ScAAA3",
        target="__chat_760_763__",
        timestamp="2020-09-07 13:51" 
      },
      payload={
        ChannelIndex=25,
        content="hello world",
        id=760,
        msgKey="a15a301e-4790-4f93-a1fe-e08169ab7a27",
        nickname="zhangleio2",
        orgAdmin=0,
        student=0,
        tLevel=0,
        toid=763,
        type=4,
        username="zhangleio2",
        vip=1,
        worldId=1192 
      },
      userInfo={
        iat=1599457901,
        machineCode="712f8436-5320-4e87-931f-f0a6ae09cf8e-4C4C4544-0036-3910-8051-C6C04F384D32",
        platform="PC",
        userId=760,
        username="zhangleio2" 
      } 
    } 
  },
  eio_pkt_name="message",
  path="/",
  raw_body="[\"app/msg\",{\"meta\":{\"timestamp\":\"2020-09-07 13:51\",\"target\":\"__chat_760_763__\",\"client\":\"ZogAvQYR0eRYM7ScAAA3\"},\"action\":\"msg\",\"payload\":{\"orgAdmin\":0,\"nickname\":\"zhangleio2\",\"worldId\":1192,\"student\":0,\"tLevel\":0,\"content\":\"hello world\",\"vip\":1,\"id\":760,\"type\":4,\"username\":\"zhangleio2\",\"toid\":763,\"ChannelIndex\":25,\"msgKey\":\"a15a301e-4790-4f93-a1fe-e08169ab7a27\"},\"userInfo\":{\"userId\":760,\"username\":\"zhangleio2\",\"platform\":\"PC\",\"machineCode\":\"712f8436-5320-4e87-931f-f0a6ae09cf8e-4C4C4544-0036-3910-8051-C6C04F384D32\",\"iat\":1599457901}}]",
  sio_pkt_name="event" 
}
--]]
function FriendManager:OnMsg(payload, full_msg)
    -- commonlib.echo("=============FriendManager:OnMsg payload");
    -- commonlib.echo(payload,true);
    -- commonlib.echo("=============FriendManager:OnMsg full_msg");
    -- commonlib.echo(full_msg,true);
    if UserData == nil then
      UserData = {}
      KeepWorkItemManager.GetUserInfo(nil,function(err,msg,data)
        if(err ~= 200)then
            return
        end
        UserData = data
      end)
    end

    local last_msg_data = {}
    last_msg_data.unReadCnt = 0
    last_msg_data.latestMsg = {}
    last_msg_data.latestMsg.content = payload.content
    last_msg_data.latestMsg.senderId = payload.id
    last_msg_data.time_stamp = os.time()
    local save_id = payload.id == UserData.id and payload.toid or payload.id
    self:AddLastChatMsg(save_id, last_msg_data)

    -- 聊天界面 有收到消息就把消息加上去
    if FriendChatPage.IsOpen then
      FriendChatPage.OnMsg(payload, full_msg)
    end

    -- 好友列表界面 如果当前聊天的对象不是收到消息的对象 要给小红点
    if FriendsPage.GetIsOpen() then
      FriendsPage.OnMsg(payload, full_msg)
    end

    -- if DockPage.is_show and not FriendsPage.GetIsOpen() then
    --   DockPage.LoadFriendsMess()
    -- end
end
-- send a message to user
-- @param {number} userId
-- @param {table} msg
-- @param {string} msg.words
function FriendManager:SendMessage(userId,msg)
    msg.words = self:BadWordsFilter(msg.words)
    local conn = FriendManager:CreateOrGetConnection(userId)
    conn:SendMessage(msg);
end

function FriendManager:SaveLastChatMsg()
  if self.lastChatMsg == nil then
    return
  end

  -- 剔除有未读消息的
  local msg_list = {}
  for k, v in pairs(self.lastChatMsg) do
    if v.unReadCnt == nil or v.unReadCnt == 0 then
      msg_list[k] = v
    end
  end
  local id = UserData.id or 0
	local filepath = string.format("chat_content/%s_last_chat.txt", id)
	local conten_str = commonlib.Json.Encode(msg_list)
    ParaIO.CreateDirectory(filepath);
	local file = ParaIO.open(filepath, "w");
	if(file:IsValid()) then
		file:WriteString(conten_str);
		file:close();
	end
end

function FriendManager:GetLastChatMsg()
  if self.lastChatMsg then
    return self.lastChatMsg
  end

  local id = UserData.id or 0
	local filepath = string.format("chat_content/%s_last_chat.txt", id)
  local file = ParaIO.open(filepath, "r");

  if(file:IsValid()) then
    local text = file:GetText();
    local msg_list = commonlib.Json.Decode(text)
    file:close();

    self.lastChatMsg = msg_list
    return self.lastChatMsg
  end
end

function FriendManager:AddLastChatMsg(user_id, chat_data)
  -- print("bbbbbbbbbbb", user_id, chat_data.latestMsg.content)
  -- commonlib.echo(chat_data, true)
  if self.lastChatMsg == nil then
    self.lastChatMsg = self:GetLastChatMsg() or {}
  end


    -- 这里将时间转成时间戳
    if chat_data.latestMsg and chat_data.latestMsg.createdAt then
      local at_time = chat_data.latestMsg.createdAt
      -- at_time = "2020-09-09T06:52:43.000Z"
      local year, month, day, hour, min, sec = at_time:match("^(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)") 
      local time_stamp = os.time({day=tonumber(day), month=tonumber(month), year=tonumber(year), hour=tonumber(hour) + 8}) -- 这个时间是带时区的 要加8小时
      time_stamp = time_stamp + min * 60 + sec

      chat_data.time_stamp = time_stamp
    end

    self.lastChatMsg[tostring(user_id)] = chat_data
end

function FriendManager:BadWordsFilter(msgdata)
  local words = ""
	if(msgdata)then
		words = BadWordFilter.FilterString(msgdata);
	end
	return words;
end
