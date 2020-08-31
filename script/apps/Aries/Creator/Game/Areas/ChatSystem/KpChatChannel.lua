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

-- api declaration:
http://yapi.kp-para.cn/project/60/interface/api/1952
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatChannel.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatHelper.lua");
local TipRoadManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ScreenTipRoad/TipRoadManager.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
local SocketIOClient = NPL.load("(gl)script/ide/System/os/network/SocketIO/SocketIOClient.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local KpUserTag = NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/KpUserTag.lua");
local KpChatHelper = commonlib.gettable("MyCompany.Aries.Creator.ChatSystem.KpChatHelper");
local KpChatChannel = NPL.export();

KpChatChannel.worldId_pending = nil;
KpChatChannel.worldId = nil;
KpChatChannel.client = nil;
KpChatChannel.configs = {
    ONLINE = "https://socket.keepwork.com",
    STAGE = "http://socket-rls.kp-para.cn",
    RELEASE = "http://socket-rls.kp-para.cn",
    LOCAL = "http://socket-dev.kp-para.cn"
}
function KpChatChannel.StaticInit()
    if(not KeepWorkItemManager.IsEnabled())then
        return
    end
	LOG.std("", "info", "KpChatChannel", "StaticInit");

	GameLogic:Connect("WorldLoaded", KpChatChannel, KpChatChannel.OnWorldLoaded, "UniqueConnection");

    GameLogic.GetFilters():remove_filter("OnKeepWorkLogin", KpChatChannel.OnKeepWorkLogin_Callback);
    GameLogic.GetFilters():remove_filter("OnKeepWorkLogout", KpChatChannel.OnKeepWorkLogout_Callback);
    GameLogic.GetFilters():add_filter("OnKeepWorkLogin", KpChatChannel.OnKeepWorkLogin_Callback);
	GameLogic.GetFilters():add_filter("OnKeepWorkLogout", KpChatChannel.OnKeepWorkLogout_Callback)
end

function KpChatChannel.OnWorldLoaded()
    local id = WorldCommon.GetWorldTag("kpProjectId");
	LOG.std(nil, "info", "KpChatChannel", "OnWorldLoaded: %s",tostring(id));
    TipRoadManager:Clear();
    if(id)then
        id = tonumber(id);
        KpChatChannel.worldId_pending = id;
        -- connect chat channel
        KpChatChannel.OnKeepWorkLogin_Callback();
    else
        KpChatChannel.Clear();
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
	LOG.std("", "info", "KpChatChannel", "OnOpen");
    if(KpChatChannel.onopen_callback)then
        KpChatChannel.onopen_callback();
    end
    KpChatChannel.RefreshChatWindow();

    TipRoadManager:CreateRoads();
    
end
function KpChatChannel.OnClose(self)
	LOG.std("", "info", "KpChatChannel", "OnClose");
    KpChatChannel.Clear();
end
-- erase date if timestamp is in same day
function KpChatChannel.GetTimeStamp(timestamp)
    if(not timestamp)then
        return
    end
    local date,time = string.match(timestamp, "(.+)%s(.+)");
    local local_date = ParaGlobal.GetDateFormat("yyyy-MM-dd");
    if(date and date == local_date)then
        timestamp = time;
    end
    -- erase date if timestamp is in same day
    timestamp = string.gsub(timestamp, date, "");
    return timestamp;
end
-- check if include a name in usernames_str
-- @param usernames_str: "name_1,name_2"
-- @param name: which is be searched
-- @return true if found
function KpChatChannel.HasUserName(usernames_str, name)
    if(not usernames_str or not name)then
        return
    end
    local v;
	for v in string.gmatch(usernames_str, "([^,]+)") do
        if(v == name)then
            return true;
        end
	end
end
function KpChatChannel.OnMsg(self, msg)
	--LOG.std("", "debug", "KpChatChannel OnMsg", msg);
    if(not msg or not msg.data)then
        return
    end
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

        if(key == "app/msg" or key == "paracraftGlobal" )then
            if(payload and userInfo)then


                local worldId = payload.worldId;
                local type = payload.type;
                local content = payload.content;

                local userId = payload.id;
                local username = payload.username;
                local nickname = payload.nickname;
                local kp_from_name = nickname;
                if(not kp_from_name or kp_from_name == "")then
                    kp_from_name = username;
                end
                local vip = payload.vip;
                local student = payload.student;
                local orgAdmin = payload.orgAdmin;
                local tLevel = payload.tLevel;

                if(not KpChatChannel.IsInWorld())then
                    return
                end
                if(KpChatChannel.worldId ~= worldId and key == "app/msg" )then
                    return
                end
                
				if (key == "app/msg" and meta.target ~= KpChatChannel.GetRoom()) then
					return
				end

                local timestamp = KpChatChannel.GetTimeStamp(meta.timestamp);
       
                local ChannelIndex;
                if(type == 2)then
                    ChannelIndex = ChatChannel.EnumChannels.KpNearBy;
                elseif(type == 3)then
                    ChannelIndex = ChatChannel.EnumChannels.KpBroadCast;
                end
                local channelname = ChatChannel.channels[ChannelIndex];
                local msgdata = { ChannelIndex = ChannelIndex, words = content, channelname = channelname, 
                vip = vip, student = student, orgAdmin = orgAdmin, tLevel = tLevel, 
                timestamp = timestamp, kp_from_name = kp_from_name, kp_from_id = userId, kp_username = username,  kp_id = KpChatChannel.GetUserId(), is_keepwork = true, }
                ChatChannel.AppendChat( msgdata)

                
                if(KpChatChannel.BulletScreenIsOpened() and KpChatChannel.IsInWorld())then
                    local mcmlStr = KpChatChannel.CreateMcmlStrToTipRoad(msgdata);
                    TipRoadManager:PushNode(mcmlStr);
                end

                local profile = KeepWorkItemManager.GetProfile()
                -- 消耗喇叭，在这里同步数据
                if(userId == profile.id and ChannelIndex == ChatChannel.EnumChannels.KpBroadCast)then
                    KeepWorkItemManager.ReLoadItems({10002,10001});
                end
            end
        elseif(key == "broadcast")then
            -- system broadcast
            if(info.data and info.data.msg)then
                local content = info.data.msg.text;
                content = string.gsub(content, "<p>","");
                content = string.gsub(content, "</p>","");
                local username = L"管理员";
                local ChannelIndex = ChatChannel.EnumChannels.KpSystem;
                local channelname = ChatChannel.channels[ChannelIndex];
                local msgdata = { ChannelIndex = ChannelIndex, words = content, channelname = channelname, kp_from_name = username, is_keepwork = true, }
                ChatChannel.AppendChat( msgdata)

                 if(KpChatChannel.BulletScreenIsOpened() and KpChatChannel.IsInWorld())then
                    local mcmlStr = KpChatChannel.CreateMcmlStrToTipRoad(msgdata);
                    TipRoadManager:PushNode(mcmlStr);
                end
            end
        elseif(key == "msg")then
            -- system broadcast to user

            --[[
            {
                  meta={ timestamp="2020-06-11 16:56" },
                  payload={
                    all=0,
                    createdAt="2020-06-11T08:56:11.211Z",
                    extra={  },
                    id=969,
                    msg={ text="<p>666</p>", type=0 },
                    operator="kevinxft",
                    organizationId=0,
                    receivers="zhangleio,zhangleio2",
                    roleId=0,
                    sendSms=0,
                    sender=0,
                    type=0,
                    updatedAt="2020-06-11T08:56:11.211Z" 
                  } 
                }
            ]]
            if(payload and payload.receivers and payload.msg)then
                local receivers = payload.receivers;
                local user_info = KeepWorkItemManager.GetProfile();
                if(not KpChatChannel.HasUserName(receivers, user_info.username))then
                    return
                end
                local timestamp = KpChatChannel.GetTimeStamp(meta.timestamp);
                local content = payload.msg.text;
                content = string.gsub(content, "<p>","");
                content = string.gsub(content, "</p>","");
                local ChannelIndex = ChatChannel.EnumChannels.KpSystem;
                local channelname = ChatChannel.channels[ChannelIndex];
                local msgdata = { ChannelIndex = ChannelIndex, words = content, channelname = channelname, is_keepwork = true, }
                ChatChannel.AppendChat( msgdata)

                if(KpChatChannel.BulletScreenIsOpened() and KpChatChannel.IsInWorld())then
                    local mcmlStr = KpChatChannel.CreateMcmlStrToTipRoad(msgdata);
                    TipRoadManager:PushNode(mcmlStr);
                end
            end
        end
        
    end
    
end
function KpChatChannel.CreateMcmlStrToTipRoad(chatdata)
    if(not chatdata)then
        return
    end
    local mcmlStr = "";
    local words = chatdata.words or "";
    local color = chatdata.color or "ffffff";
    local kp_from_name = chatdata.kp_from_name or "";
    
    local vip = chatdata.vip;
    local student = chatdata.student;
    local orgAdmin = chatdata.orgAdmin;
    local tLevel = chatdata.tLevel;
    local timestamp = chatdata.timestamp or "";

    local channel_tag = "";
    local name_tag_start = [[<div style="float:left">[</div>]]
    local user_tag = KpUserTag.GetMcml(chatdata);
    local name_tag_end = [[<div style="float:left">]:</div>]]

    local timestamp_tag = "";

    if(chatdata.ChannelIndex == ChatChannel.EnumChannels.KpSystem)then
        channel_tag = string.format([[<div style="float:left">[%s]</div>]],chatdata.channelname);
        mcmlStr = string.format([[<div style="color:#%s;font-size:15px;base-font-size:15;font-weight:bold;shadow-quality:8;shadow-color:#8000468e;text-shadow:true;">
%s%s%s%s%s%s%s%s</div>
        ]],color,channel_tag,"","","","",":",words,timestamp_tag);
    else
        kp_from_name = string.format([[<div style="float:left">%s</div>]],kp_from_name);
        mcmlStr = string.format([[<div style="color:#%s;font-size:15px;base-font-size:15;font-weight:bold;shadow-quality:8;shadow-color:#8000468e;text-shadow:true;">
%s%s%s%s%s%s%s</div>
        ]],color,channel_tag,name_tag_start,user_tag,kp_from_name,name_tag_end,words,timestamp_tag);
    end
    return mcmlStr;
end
function KpChatChannel.CreateMcmlStrToChatWindow(chatdata)
    if(not chatdata)then
        return
    end
    local mcmlStr = "";
    local words = chatdata.words or "";
    local color = chatdata.color or "ffffff";
    local kp_from_name = chatdata.kp_from_name or "";
    local kp_from_id = chatdata.kp_from_id;
    local kp_username = chatdata.kp_username or "";

    local vip = chatdata.vip;
    local student = chatdata.student;
    local orgAdmin = chatdata.orgAdmin;
    local tLevel = chatdata.tLevel;
    local timestamp = chatdata.timestamp or "";

    local channel_tag = string.format([[<div style="float:left">[%s]</div>]],chatdata.channelname);
    local name_tag_start = [[<div style="float:left">[</div>]]

    local user_tag = KpUserTag.GetMcml(chatdata);
    local name_tag_end = [[<div style="float:left">]:</div>]]

    local timestamp_tag = string.format([[<input type="button" value="%s" style="float:left;margin-left:10px;color:#8b8b8b;background:url();" />]],tostring(timestamp));
    if(chatdata.ChannelIndex == ChatChannel.EnumChannels.KpSystem)then
        mcmlStr = string.format([[<div style="color:#%s">%s%s%s%s%s%s%s%s</div>]],color,channel_tag,"","","","",":",words,timestamp_tag);
    else
        kp_from_name = string.format([[<input type="button" name="%s" value="%s" zorder="1000" onclick="MyCompany.Aries.Creator.ChatSystem.KpChatHelper.ShowUserInfo" style="float:left;color:#%s;background:url()" />]],kp_username, kp_from_name, color);
        mcmlStr = string.format([[<div style="color:#%s">%s%s%s%s%s%s%s</div>]],color,channel_tag,name_tag_start,user_tag,kp_from_name,name_tag_end,words,timestamp_tag);
    end
    return mcmlStr;
end
function KpChatChannel.SetBulletScreen(v)
    if(GameLogic)then
        local key = string.format("is_opened_bullet_screen_%s",tostring(KpChatChannel.GetUserId()));
	    GameLogic.GetPlayerController():SaveLocalData(key, v, true);
        TipRoadManager:OnShow(v)
    end
    NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatEdit.lua");
    local ChatEdit = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatEdit");
    if(ChatEdit.page)then
        ChatEdit.page:Refresh(0);
    end
end
function KpChatChannel.BulletScreenIsOpened()
    if(GameLogic)then
		local userId = KpChatChannel.GetUserId();
		if (userId) then
			local key = string.format("is_opened_bullet_screen_%s",tostring(userId));
			return GameLogic.GetPlayerController():LoadLocalData(key,true,true);
		end
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
    if(not System.options.mc) then
	    return
    end
    NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatWindow.lua");
    -- for refresh
    MyCompany.Aries.ChatSystem.ChatWindow.ShowChatLogPage(true);
    NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatEdit.lua");
    local ChatEdit = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatEdit");

    if(KpChatChannel.IsInWorld())then
        ChatEdit.selected_channel = ChatChannel.EnumChannels.KpNearBy;
    else
        ChatEdit.selected_channel = ChatChannel.EnumChannels.NearBy;
    end
    MyCompany.Aries.ChatSystem.ChatWindow.HideAll();


    -- refresh the state of TipRoadManager
    if(KpChatChannel.IsInWorld())then
        TipRoadManager:OnShow(true);
    else
        TipRoadManager:OnShow(false);
    end
    if(ChatEdit.page)then
        -- refresh the state of shortcut button
        ChatEdit.page:Refresh(0);
    end
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
    local user_info = KeepWorkItemManager.GetProfile();

    local kp_msg = {
        target = msgdata.target,
        payload = {
            content = msgdata.words,
            worldId = msgdata.worldId,
            type = msgdata.type,

            id = user_info.id,
            username = user_info.username,
            nickname = user_info.nickname,
            vip = user_info.vip,
            student = user_info.student,
            orgAdmin = user_info.orgAdmin,
            tLevel = user_info.tLevel,
        },
    }

    KpChatChannel.client:Send("app/msg",kp_msg);
   
end

