--[[
Title: FriendConnection
Author(s): leio
Date: 2020/9/7
Desc:  
Use Lib:
-------------------------------------------------------
local FriendConnection = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendConnection.lua");
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local KpChatChannel = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua");
NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatChannel.lua");
local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");

local FriendConnection = commonlib.inherit(nil,NPL.export());
function FriendConnection:ctor()
    self.userId = nil;
    self.connected = false;
    self.roomId = nil;
    self.per_page_cnt = 1000;
    self.unread_msgs = {};
end
-- name is __chat_lowerid_id__
function FriendConnection:GetStaticRoomName()
    local user_info = KeepWorkItemManager.GetProfile();
    if(not user_info or not self.userId)then
        return
    end
    local id_1 = tonumber(user_info.id);
    local id_2 = tonumber(self.userId);
    if(id_1 == id_2)then
        return
    end
    local id_temp;
    if(id_1 > id_2)then
        id_temp = id_1;
        id_1 = id_2;
        id_2 = id_temp;
    end
    local name = string.format("__chat_%d_%d__",id_1,id_2);
    return name;
end
function FriendConnection:OnInit(userId)
    self.userId = userId;
    KpChatChannel.client:Send("app/join",{ rooms = { self:GetStaticRoomName() }, });
    return self;
end
function FriendConnection:Connect(callback)
    if(self.connected)then
        if(callback)then
            callback();
        end
        return
    end
     keepwork.friends.startChatToUser({
        targetId = self.userId , 
    },function(err, msg, data)

        -- commonlib.echo("==========startChatToUser");
        -- commonlib.echo(err);
        -- commonlib.echo(msg);
        -- commonlib.echo(data,true);
        if(err ~= 200)then
            return
        end
        --[[
            {
              createdAt="2020-09-07T02:51:17.000Z",
              id=1,
              room={
                createdAt="2020-09-07T02:51:17.000Z",
                id=1,
                name="__chat_760_763__",
                updatedAt="2020-09-07T02:51:17.000Z" 
              },
              roomId=1,
              unReadCnt=0,
              updatedAt="2020-09-07T02:51:17.000Z",
              userId=760 
            }
        --]]
        if(data and data.room)then
            local room = data.room;
            self.roomId = data.roomId;

            self:LoadUnReadMsgs(function(unread_msgs)
                self.connected = true;
                self.unread_msgs = unread_msgs;
                if(callback)then
                    callback();
                end    
            end)
            
        end
    end)
end
function FriendConnection:LoadUnReadMsgs(callback)
    if(not self.roomId)then
        return
    end
    keepwork.friends.getUnReadMsgInRoom({
         headers = {
            ["x-per-page"] = self.per_page_cnt,
            ["x-page"] = 1,
        },
        roomId = self.roomId,
    },function(err, msg, data)
        -- commonlib.echo("==========LoadUnReadMsgs");
        -- commonlib.echo(err);
        -- commonlib.echo(msg);
        -- commonlib.echo(data,true);
        --[[
         {
data = {
            count=11,
            rows= {
                      {
                        content="hello world",
                        createdAt="2020-09-07T05:51:54.000Z",
                        id=11,
                        msgKey="a15a301e-4790-4f93-a1fe-e08169ab7a27",
                        roomId=1,
                        senderId=760,
                        updatedAt="2020-09-07T05:51:54.000Z" 
                      },
                      {
                        content="hello world",
                        createdAt="2020-09-07T05:51:16.000Z",
                        id=10,
                        msgKey="2cd85ea2-1820-4606-9d31-7c7ec878d2b3",
                        roomId=1,
                        senderId=760,
                        updatedAt="2020-09-07T05:51:16.000Z" 
                      },
                    }
            }
        --]]
        if(err ~= 200)then
            return
        end
        if(callback)then
            callback(data.data.rows);
        end
    end)
end
-- send a message to user
-- @param {table} msg
-- @param {string} msg.words
function FriendConnection:SendMessage(msg)
    if(not msg)then
        return
    end
    local words = msg.words;
    local ChannelIndex = ChatChannel.EnumChannels.KpFriend;
    local roomName = self:GetStaticRoomName();
    local msgdata = KpChatChannel.CreateMessage(ChannelIndex, self.userId, nil, words, roomName);
    KpChatChannel.SendToServer(msgdata);
end
function FriendConnection:UpdateLastMsgTag(callback)
    local len = #(self.unread_msgs);
    local node = self.unread_msgs[1];
    print("ttttttt", node)
    if node then
        print("xxxs",node.msgKey)
    end
    if(node and node.msgKey)then
        local roomId = self.roomId;
        local msgKey = node.msgKey;
        keepwork.friends.updateLastMsgTagInRoom({
            roomId = roomId,
            msgKey = msgKey,
        },function(err, msg, data)
            -- commonlib.echo("==========FriendConnection:UpdateMsgTag");
            -- commonlib.echo(err);
            -- commonlib.echo(msg);
            -- commonlib.echo(data,true);
            if(callback)then
                callback();
            end
        end)
    end
end