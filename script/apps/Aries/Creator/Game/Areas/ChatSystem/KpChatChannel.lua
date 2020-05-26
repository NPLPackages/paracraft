--[[
Title: keepwork channel for chat
Author(s): leio
Date: 2020/5/6
Desc:  
Use Lib:
-------------------------------------------------------
using  KeepWorkItemManager.IsEnabled() to debug kp chat:

-- test after login keepwork
local KpChatChannel = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua");
KpChatChannel.StaticInit();

local KpChatChannel = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua");
local id = 618;
KpChatChannel.Connect(nil,nil,function()
    KpChatChannel.JoinWorld(id);
end);
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatChannel.lua");
local TipRoadManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ScreenTipRoad/TipRoadManager.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
local SocketIOClient = NPL.load("(gl)script/ide/System/os/network/SocketIO/SocketIOClient.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local KpChatChannel = NPL.export();

KpChatChannel.worldId_pending = nil;
KpChatChannel.worldId = nil;
KpChatChannel.client = nil;
KpChatChannel.configs = {
    ONLINE = "https://keepwork.com",
    STAGE = "http://socket-dev.kp-para.cn",
    RELEASE = "http://socket-dev.kp-para.cn",
    LOCAL = "http://socket-dev.kp-para.cn"
}
function KpChatChannel.StaticInit()
    if(not KeepWorkItemManager.IsEnabled())then
        return
    end
    echo("====================KpChatChannel.StaticInit()");

	GameLogic:Connect("WorldLoaded", KpChatChannel, KpChatChannel.OnWorldLoaded, "UniqueConnection");

    GameLogic.GetFilters():remove_filter("OnKeepWorkLogin", KpChatChannel.OnKeepWorkLogin_Callback);
    GameLogic.GetFilters():remove_filter("OnKeepWorkLogout", KpChatChannel.OnKeepWorkLogout_Callback);
    GameLogic.GetFilters():add_filter("OnKeepWorkLogin", KpChatChannel.OnKeepWorkLogin_Callback);
	GameLogic.GetFilters():add_filter("OnKeepWorkLogout", KpChatChannel.OnKeepWorkLogout_Callback)
end

function KpChatChannel.OnWorldLoaded()
    local id = WorldCommon.GetWorldTag("kpProjectId");
	LOG.std(nil, "info", "KpChatChannel", "OnWorldLoaded: %s",tostring(id));
    if(id)then
        id = tonumber(id);
        KpChatChannel.worldId_pending = id;
        -- connect chat channel
        KpChatChannel.OnKeepWorkLogin_Callback();
    end
end
function KpChatChannel.OnKeepWorkLogin_Callback()
    if(KpChatChannel.worldId_pending)then
        KpChatChannel.Connect(nil,nil,function()
            KpChatChannel.JoinWorld(KpChatChannel.worldId_pending);
        end);
    end        
end
function KpChatChannel.OnKeepWorkLogout_Callback()
    KpChatChannel.LeaveWorld(KpChatChannel.worldId_pending);
end
function KpChatChannel.GetUrl()
    local url;
    local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
    local httpwrapper_version = HttpWrapper.GetDevVersion();

    local Config = NPL.load("(gl)Mod/WorldShare/config/Config.lua")
    url  = KpChatChannel.configs[httpwrapper_version];
    if(not url)then
	    LOG.std(nil, "error", "KpChatChannel", "read url failed by httpwrapper_version: %s",httpwrapper_version);
    else
	    LOG.std(nil, "info", "KpChatChannel", "read url %s by httpwrapper_version: %s",url, httpwrapper_version);
    end
    return url;
end
function KpChatChannel.GetUserId()
    if(Mod and Mod.WorldShare and Mod.WorldShare.Store)then
        local userId = tonumber(Mod.WorldShare.Store:Get("user/userId"))
        return userId;
    end
end
function KpChatChannel.GetRoom()
    if(KpChatChannel.worldId)then
        local room = string.format("__world_%s__",tostring(KpChatChannel.worldId));
        return room
    end
end
function KpChatChannel.Connect(url,options,onopen_callback)
    
    if(not KeepWorkItemManager.GetToken())then
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
    KpChatChannel.onopen_callback = onopen_callback;
    if(KpChatChannel.client.state == "OPEN")then
        KpChatChannel.OnOpen();
        return
    end
    KpChatChannel.client:Connect(url,nil,{ token = KeepWorkItemManager.GetToken(), });
end
function KpChatChannel.OnOpen(self)
    commonlib.echo("=============OnOpen");
    if(KpChatChannel.onopen_callback)then
        KpChatChannel.onopen_callback();
    end
    KpChatChannel.RefreshChatWindow();

    commonlib.echo(KpChatChannel.GetUserId());
    TipRoadManager:CreateRoads();
    
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

                 
                if(KpChatChannel.BulletScreenIsOpened())then
                    local color = "ffffff";
                    local channel_config = ChatChannel.channels[ChannelIndex];
                    if(channel_config)then
                        color = channel_config.color or color;
                    end
                    content = string.format(L"%s说:%s",username, content);
                    TipRoadManager:PushNode(content,"#".. color);
                end
            end
        end
        
    end
    
end
function KpChatChannel.SetBulletScreen(v)
    if(GameLogic)then
        local key = string.format("is_opened_bullet_screen_%s",tostring(KpChatChannel.GetUserId()));
	    GameLogic.GetPlayerController():SaveLocalData(key, v, true);
        TipRoadManager:OnShow(v)
    end
end
function KpChatChannel.BulletScreenIsOpened()
    if(GameLogic)then
        local key = string.format("is_opened_bullet_screen_%s",tostring(KpChatChannel.GetUserId()));
	    return GameLogic.GetPlayerController():LoadLocalData(key,true,true);
    end
    return true;
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
    KpChatChannel.client:Send("app/join",{ rooms = { room }, });
end
function KpChatChannel.LeaveWorld(worldId)
    if(not worldId)then
        return
    end
    local room = KpChatChannel.GetRoom();
	LOG.std(nil, "info", "KpChatChannel", "try to join world %s", room);
    KpChatChannel.client:Send("app/leave",{ rooms = { room }, });
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
	    msgdata = { ChannelIndex = ChannelIndex, target = "paracraftGlobal", worldId = worldId, words = words, type = 3, is_keepwork = true, };
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

    local ChannelIndex =  msgdata.ChannelIndex;
    if(ChannelIndex == ChatChannel.EnumChannels.KpBroadCast)then
        KeepWorkItemManager.LoadItems(true);
    end
   
end

