--[[
Title: keepwork channel for chat
Author(s): leio
Date: 2020/5/6
Desc:  
Use Lib:
-------------------------------------------------------
-- test after login keepwork
local KpChatChannel = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua");
KpChatChannel.Connect(nil,nil,function()
    KpChatChannel.JoinWorld(1000);
end);
KpChatChannel.LeaveWorld(0);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatChannel.lua");
local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
local SocketIOClient = NPL.load("(gl)script/ide/System/os/network/SocketIO/SocketIOClient.lua");
local KpChatChannel = NPL.export();

KpChatChannel.worldId = nil;
KpChatChannel.client = nil;
function KpChatChannel.GetUrl()
    local url;
    if(LOG.level == "debug")then
        --url = "http://localhost:3000";
        url = "http://socket-dev.kp-para.cn";
    else
        url = "http://socket-dev.kp-para.cn";
    end
    return url;
end
function KpChatChannel.GetUserId()
    if(Mod and Mod.WorldShare and Mod.WorldShare.Store)then
        local userId = tonumber(Mod.WorldShare.Store:Get("user/userId"))
        return userId;
    end
end
function KpChatChannel.GetToken()
    local User = commonlib.gettable('System.User');
    return System.User.keepworktoken;
end
function KpChatChannel.GetRoom()
    if(KpChatChannel.worldId)then
        local room = string.format("__world_%s__",tostring(KpChatChannel.worldId));
        return room
    end
end
function KpChatChannel.Connect(url,options,onopen_callback)
    if(LOG.level ~= "debug")then
        return
    end
    url  = url or KpChatChannel.GetUrl();
    if(not KpChatChannel.client)then
        KpChatChannel.client = SocketIOClient:new();
        KpChatChannel.client:AddEventListener("OnOpen",KpChatChannel.OnOpen,KpChatChannel);
        KpChatChannel.client:AddEventListener("OnMsg",KpChatChannel.OnMsg,KpChatChannel);
        KpChatChannel.client:AddEventListener("OnClose",KpChatChannel.OnClose,KpChatChannel);
    end
    options = options or {};
    if(KpChatChannel.client.state == "OPEN")then
        KpChatChannel.OnOpen();
        return
    end

    KpChatChannel.onopen_callback = onopen_callback;
    KpChatChannel.client:Connect(url,nil,{ token = KpChatChannel.GetToken(), });
end
function KpChatChannel.OnOpen(self)
    commonlib.echo("=============OnOpen");
    if(KpChatChannel.onopen_callback)then
        KpChatChannel.onopen_callback();
    end
    KpChatChannel.RefreshChatWindow();

    commonlib.echo(KpChatChannel.GetUserId());
    
end
function KpChatChannel.OnClose(self)
    commonlib.echo("=============OnClose");
    KpChatChannel.Clear();
end
function KpChatChannel.OnMsg(self, msg)
    commonlib.echo("=============OnMsg");
    commonlib.echo(msg);
    if(not msg or not msg.data)then
        return
    end
    commonlib.echo("=============data");
    commonlib.echo(msg.data);
    msg = msg.data;

    -- see: script/apps/GameServer/socketio/packet.lua
    local eio_pkt_name = msg.eio_pkt_name;
    local sio_pkt_name = msg.sio_pkt_name;
    if(eio_pkt_name == "message" and sio_pkt_name =="event")then
        local body = msg.body or {};
        local key = body[1] or {};
        local info = body[2] or {};
        local payload = info.payload;
        local meta = info.meta;
        local action = info.action;
        local userInfo = info.userInfo;

        if(action == "msg")then
            if(payload and userInfo)then
                local worldId = payload.worldId;
                local type = payload.type;
                local content = payload.content;

                local userId = userInfo.userId;
                local username = userInfo.username;


--                commonlib.echo("=============body");
--                commonlib.echo(key);
--                commonlib.echo(payload);
--                commonlib.echo(meta);
--                commonlib.echo(action);
--                commonlib.echo(userInfo);
       
                local ChannelIndex;
                if(type == 2)then
                    ChannelIndex = ChatChannel.EnumChannels.KpNearBy;
                elseif(type == 3)then
                    ChannelIndex = ChatChannel.EnumChannels.KpBroadCast;
                end
                local msgdata = { ChannelIndex = ChannelIndex, words = content, kp_from_name = username, kp_from_id = userId, kp_id = KpChatChannel.GetUserId(), is_keepwork = true, }
                ChatChannel.AppendChat( msgdata)
            end
        end
        
    end
    
end
function KpChatChannel.JoinWorld(worldId)
    if(not worldId)then
        return
    end
    if(not KpChatChannel.IsConnected())then
        return
    end
    KpChatChannel.worldId = worldId;
    local room = KpChatChannel.GetRoom();
	LOG.std(nil, "info", "KpChatChannel", "try to join world %s", room);
    KpChatChannel.client:Send("app/join",{ room = room, });
end
function KpChatChannel.LeaveWorld(worldId)
    if(not worldId)then
        return
    end
    local room = KpChatChannel.GetRoom();
	LOG.std(nil, "info", "KpChatChannel", "try to join world %s", room);
    KpChatChannel.client:Send("app/leave",{ room = room, });
    KpChatChannel.Clear();
end
function KpChatChannel.IsConnected()
    return KpChatChannel.client and KpChatChannel.client:IsConnected()
end
function KpChatChannel.IsInWorld()
    if(KpChatChannel.worldId and KpChatChannel.IsConnected())then
        return true;
    end
end
function KpChatChannel.Clear()
    KpChatChannel.worldId = nil
    KpChatChannel.RefreshChatWindow()
end
-- refresh for showing or hiding chat channel
function KpChatChannel.RefreshChatWindow()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatWindow.lua");
    MyCompany.Aries.ChatSystem.ChatWindow.ShowChatLogPage(true);

    NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatEdit.lua");
    local ChatEdit = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatEdit");

    if(KpChatChannel.IsInWorld())then
        ChatEdit.selected_channel = ChatChannel.EnumChannels.KpNearBy;
    else
        ChatEdit.selected_channel = ChatChannel.EnumChannels.NearBy;
    end
    ChatEdit.ShowPage(true);
end
-- create a chat message
-- @param ChannelIndex	频道索引
-- @param to			接受者nid
-- @param toname		接受者名字,可为nil
-- @param words			消息内容
-- http://yapi.kp-para.cn/project/60/interface/api/1952
function KpChatChannel.CreateMessage( ChannelIndex, to, toname, words)
	local msgdata;
    local target = KpChatChannel.GetRoom();
    local worldId = KpChatChannel.worldId;
    if(not worldId)then
		LOG.std(nil, "warn", "KpChatChannel", "world id is required");
        return
    end
    if(ChannelIndex == ChatChannel.EnumChannels.KpNearBy)then
	    msgdata = { ChannelIndex = ChannelIndex, target = target, worldId = worldId, words = words, type = 2, is_keepwork = true, };

    elseif(ChannelIndex == ChatChannel.EnumChannels.KpBroadCast)then
	    msgdata = { ChannelIndex = ChannelIndex, target = target, worldId = worldId, words = words, type = 3, is_keepwork = true, };
    else
		LOG.std(nil, "warn", "KpChatChannel", "[%s] unsupported channel index in KpChatChannel.SendMessage", tostring(ChannelIndex));
    end
	return msgdata;
end


--[[---------------------------------------------------------------------------------------------------
根据消息类型分别发送至服务器
--]]---------------------------------------------------------------------------------------------------
function KpChatChannel.SendToServer(msgdata)
    if(not msgdata)then
        return
    end
    if(type(msgdata) ~= "table")then
        return
    end
    local kp_msg = {
        target = msgdata.target,
        payload = {
            content = msgdata.words,
            worldId = msgdata.worldId,
            type = msgdata.type,
        },
    }
    commonlib.echo("=============kp_msg");
    commonlib.echo(kp_msg);

    KpChatChannel.client:Send("app/msg",kp_msg);
	--ChatChannel.AppendChat(msgdata);
end

