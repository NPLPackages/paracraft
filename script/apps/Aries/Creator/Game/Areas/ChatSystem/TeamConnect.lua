--[[
Title: TeamConnect
Author(s): pbb
Date: 2024/10/22
Desc:  
Use Lib:
-------------------------------------------------------
local TeamConnect = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/TeamConnect.lua");
--]]
NPL.load("(gl)script/ide/System/os/network/TcpConnection.lua");
local TcpConnection = commonlib.gettable("System.os.network.TcpConnection");
local KpChatChannel = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua");
NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatChannel.lua");
local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");

local TeamConnect = commonlib.inherit(nil,NPL.export());
function TeamConnect:ctor()
    self.userId = nil;
    self.connected = false;
    self.roomId = nil;
    self.per_page_cnt = 1000;
    self.unread_msgs = {};
end
-- name is __chat_lowerid_id__
function TeamConnect:GetStaticRoomName()
    if not self.roomId then
        self.roomId = string.format("__team_chat_%s__",System.Encoding.guid.uuid());
    end
    return self.roomId
end

function TeamConnect:OnInit(roomId)
    self.roomId = roomId or self:GetStaticRoomName();
    if self:IsValidConnection() then
        KpChatChannel.client:Send("app/join",{ rooms = { self.roomId }, });
    else
        KpChatChannel.TryToConnect()
        commonlib.TimerManager.SetTimeout(function()
            KpChatChannel.client:Send("app/join",{ rooms = { self.roomId }, });
        end,5*1000)
    end
    return self;
end

function TeamConnect:IsValidConnection()
    return KpChatChannel.IsConnected()
end

function TeamConnect:GetRoomName()
    return self.roomId;
end

function TeamConnect:Connect(callback)
    if self:IsValidConnection() then
        commonlib.TimerManager.SetTimeout(function()
            if(self.connected)then
                if(callback)then
                    callback();
                end
                return
            end
    
            self.connected = true;
            if (callback) then
                callback();
            end

        end,100)
        return
    end
    KpChatChannel.TryToConnect()
    commonlib.TimerManager.SetTimeout(function()
        self.connected = true;
        if (callback) then
            callback();
        end
    end,5*1000)
end

function TeamConnect:SendBoadcastMessage(msgdata) --组队管理消息，使用app/broadcast
    if (not msgdata or type(msgdata) ~= "table") then
        return
    end
    if not KpChatChannel.client or not KpChatChannel.IsConnected() then
        LOG.std(nil,"info","TeamConnect","发送消息失败,聊天频道网络链接失败，房间名称是"..(self.roomId or ""))
        KpChatChannel.TryToConnect()
        commonlib.TimerManager.SetTimeout(function()
            KpChatChannel.client:Send("app/broadcast", msgdata);
        end,5*1000)
        return
    end
    KpChatChannel.client:Send("app/broadcast", msgdata);
end

function TeamConnect:LoadTeamMembers(callback)
    local roomName = self.roomId;
    keepwork.chat.roomMembers({
       room = roomName, 
    },function(err,msg,data)
        print("roomMembers=========",err)
        if(err ~= 200 or not data)then
            LOG.std(nil,"info","TeamConnect","加载成员失败,房间名称是"..(roomName or "")..",错误码是"..(err or ""))
            -- echo(data)
            return
        end
        -- echo(data,true)
        print("加载成员成功")
        self.members = data;
        if(callback and type(callback) == "function")then
            callback(data)
        end
    end)
end

function TeamConnect:GetMemberData(username) --获取成员信息
    if(not username or username == "")then
        return
    end
    if not self.members then
        return
    end
    for i,v in ipairs(self.members)do
        if(v.username == username)then
            return v
        end
    end
end

function TeamConnect:KickUserFromTeam(username,callback) --踢人
    if(not username or username == "")then
        return
    end
    local memberData = self:GetMemberData(username)
    if(not memberData)then
        return
    end
    local msgdata = {
        room = self.roomId,
        socketId = memberData.socketId,
    }
    if not KpChatChannel.client or not KpChatChannel.IsConnected() then
        LOG.std(nil,"info","TeamConnect","踢人失败,房间名称是"..(self.roomId or "")..",被踢者是"..(username or ""))
        KpChatChannel.TryToConnect()
        commonlib.TimerManager.SetTimeout(function()
            KpChatChannel.client:Send("app/kickRoom", msgdata);
        end,5*1000)
        return
    end
    KpChatChannel.client:Send("app/kickRoom", msgdata);
end

function TeamConnect:LeaveTeam()
    local msgdata = {rooms={self.roomId}}
    if not KpChatChannel.client or not KpChatChannel.IsConnected() then
        LOG.std(nil,"info","TeamConnect","退出房间失败,房间名称是"..(self.roomId or ""))
        KpChatChannel.TryToConnect()
        commonlib.TimerManager.SetTimeout(function()
            KpChatChannel.client:Send("app/leave", msgdata);
        end,5*1000)
        return
    end
    KpChatChannel.client:Send("app/leave", msgdata);
end


