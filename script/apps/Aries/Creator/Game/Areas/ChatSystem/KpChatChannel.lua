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

-- test preloading url
KpChatChannel.PreloadSocketIOUrl();


-- api declaration:
http://yapi.kp-para.cn/project/60/interface/api/1952
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatChannel.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatHelper.lua");
NPL.load("(gl)script/ide/timer.lua");
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
KpChatChannel.try_connect_cnt = 0;
KpChatChannel.try_connect_max_cnt = 5;
KpChatChannel.try_connect_waiting_seconds = 0;
KpChatChannel.try_connect_waiting_max_seconds = 15;

function KpChatChannel.GetPreloadSocketIOUrl()
	return KpChatChannel.preload_socketio_url;
end
function KpChatChannel.PreloadSocketIOUrl(callback)
	if(not KpChatChannel.preload_socketio_url)then
		local callback_is_finished = false;
		local function do_callback()
			if(not callback_is_finished)then
				callback_is_finished = true
				if(callback)then
					callback();
				end
			end
		end
		LOG.std(nil, "info", "Before KpChatChannel.PreloadSocketIOUrl");
		keepwork.app.availableHost({},function(err, msg, data)
			
			if(err == 200 and data)then
				LOG.std(nil, "info", "KpChatChannel.PreloadSocketIOUrl succeed");
				KpChatChannel.preload_socketio_url = data;
				do_callback();
				return
			else
				LOG.std(nil, "warn", "KpChatChannel.PreloadSocketIOUrl err code", err);
				LOG.std(nil, "warn", "KpChatChannel.PreloadSocketIOUrl msg", msg);
				LOG.std(nil, "warn", "KpChatChannel.PreloadSocketIOUrl data", data);
			end
			do_callback();
			
		end)

		if(not KpChatChannel.timer_preload_url)then
			KpChatChannel.timer_preload_url = commonlib.Timer:new({callbackFunc = function(timer)
				do_callback();
			end})
		end
		-- waiting max time is 10 seconds
		KpChatChannel.timer_preload_url:Change(10000, nil)
	else
		if(callback)then
			callback();
		end
	end
end
function KpChatChannel.StaticInit()
    if(not KeepWorkItemManager.IsEnabled())then
        return
    end
	LOG.std("", "info", "KpChatChannel", "StaticInit");
    KpChatChannel.try_connect_cnt = 0;

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
        KpChatChannel.TryToConnect();
    else
        KpChatChannel.Clear();
    end
end
function KpChatChannel.OnKeepWorkLogin_Callback()
    KpChatChannel.TryToConnect();
end
function KpChatChannel.OnKeepWorkLogout_Callback()
    KpChatChannel.LeaveWorld(KpChatChannel.worldId_pending);
end
function KpChatChannel.GetUrl()
    local url;
    local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
    local httpwrapper_version = HttpWrapper.GetDevVersion();

    url = KpChatChannel.GetPreloadSocketIOUrl() or GameLogic.GetFilters():apply_filters('get_socket_url');
    if(not url)then
	    LOG.std(nil, "error", "KpChatChannel", "read url failed by httpwrapper_version: %s",httpwrapper_version);
    else
	    LOG.std(nil, "info", "KpChatChannel", "read url %s by httpwrapper_version: %s",url, httpwrapper_version);
    end
    return url;
end
function KpChatChannel.GetUserId()
    return GameLogic.GetFilters():apply_filters('get_user_id') 
end

function KpChatChannel.GetSchoolRoom()
    local school = KeepWorkItemManager.GetSchool();
    local id = school.id;
    if(id)then
        --local room = string.format("__world_school_%s__",tostring(id));
        local room = string.format("__school_%s__",tostring(id));
        return room
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
function KpChatChannel.ClearReconnectAction()
    KpChatChannel.try_connect_waiting_seconds = 0;
    KpChatChannel.try_connect_cnt = 0;
    if(KpChatChannel.reconnect_timer)then
        KpChatChannel.reconnect_timer:Change();
    end
end
function KpChatChannel.TryToConnect()
    if(not KpChatChannel.reconnect_timer)then
        KpChatChannel.reconnect_timer = commonlib.Timer:new({callbackFunc = function(timer)
            if(KpChatChannel.IsConnected())then
                KpChatChannel.ClearReconnectAction();
                return
            end
            KpChatChannel.try_connect_waiting_seconds = KpChatChannel.try_connect_waiting_seconds + 1;
            if(KpChatChannel.try_connect_waiting_seconds > KpChatChannel.try_connect_waiting_max_seconds)then
                if(KpChatChannel.try_connect_cnt > KpChatChannel.try_connect_max_cnt)then
                    KpChatChannel.ClearReconnectAction();
                    return
                end
                KpChatChannel.try_connect_waiting_seconds = 0;
                KpChatChannel.ReConnect();
            end
            if(KpChatChannel.try_connect_cnt > KpChatChannel.try_connect_max_cnt)then
                KpChatChannel.ClearReconnectAction();
                return
            end
            LOG.std("", "info", "KpChatChannel", "waiting: %d/%d, try cnt: %d/%d",KpChatChannel.try_connect_waiting_seconds, KpChatChannel.try_connect_waiting_max_seconds, KpChatChannel.try_connect_cnt, KpChatChannel.try_connect_max_cnt);
        end})
    end
    KpChatChannel.try_connect_waiting_seconds = 0;
    KpChatChannel.try_connect_cnt = 0;
    KpChatChannel.ReConnect();
    KpChatChannel.reconnect_timer:Change(0, 1000);
end
function KpChatChannel.ReConnect()
    KpChatChannel.try_connect_cnt = KpChatChannel.try_connect_cnt + 1;
    if(KpChatChannel.try_connect_cnt > KpChatChannel.try_connect_max_cnt)then
        return
    end
    local id = WorldCommon.GetWorldTag("kpProjectId") or 0;
    if(id)then
        id = tonumber(id);
        KpChatChannel.worldId_pending = id;
        LOG.std("", "info", "KpChatChannel", "try to connect: %d/%d",KpChatChannel.try_connect_cnt, KpChatChannel.try_connect_max_cnt);
        if(KpChatChannel.worldId_pending)then
            KpChatChannel.Connect(nil,nil,function()
                KpChatChannel.ClearReconnectAction();
                KpChatChannel.JoinWorld(KpChatChannel.worldId_pending);
            end);
        end     
    end
	
end
function KpChatChannel.OnOpen(self)
	local userId = KpChatChannel.GetUserId();
	LOG.std("", "info", "KpChatChannel", "OnOpen userId:%s", tostring(userId));
    if(KpChatChannel.onopen_callback)then
        KpChatChannel.onopen_callback();
    end
    KpChatChannel.RefreshChatWindow();

    TipRoadManager:CreateRoads();
    
end
function KpChatChannel.OnClose(self, msg)
    msg = msg or {};
	LOG.std("", "info", "KpChatChannel", "Connection is closed, from = %s", msg.from);
    if(msg.from == "ping")then
        KpChatChannel.TryToConnect();
        return
    end
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


                local ChannelIndex = payload.ChannelIndex;
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

                -- check if it is in the same world
                if(ChannelIndex == ChatChannel.EnumChannels.KpNearBy)then
                    if(meta.target ~= KpChatChannel.GetRoom())then
                        return
                    end    
                end

                -- check if it is in the same school
                if(ChannelIndex == ChatChannel.EnumChannels.KpSchool)then
                    if(meta.target ~= KpChatChannel.GetSchoolRoom())then
                        return
                    end    
                end
                if(ChannelIndex == ChatChannel.EnumChannels.KpFriend)then
                    local FriendManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendManager.lua");
                    FriendManager:OnMsg(payload, msg);
                    return
                end
                local timestamp = KpChatChannel.GetTimeStamp(meta.timestamp);
       

                local channelname = ChatChannel.channels[ChannelIndex];
                if(not channelname)then
                    return
                end
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
            if(payload and payload.chargeType == 1) then
                local product = payload.product
                KeepWorkItemManager.LoadProfile(true, function()  --刷新用户信息                  
                    GameLogic.GetFilters():apply_filters('login_with_token')
                    GameLogic.GetFilters():apply_filters('cellar.vip_notice.close')
                    GameLogic.GetFilters():apply_filters('became_vip')
                    _guihelper.MessageBox("恭喜您"..product.description)
               end)
                return
            end
            if(payload and payload.muteType == 1)then
                KeepWorkItemManager.LoadMutingInfo(true);
                return
            end
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

            -- 消息中心
            if payload and (payload.msgType =="interactionMsg" 
                or payload.msgType =="orgMsg" 
                or payload.msgType =="sysMsg"
                or payload.msgType =="emailMsg") then
                local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
                if DockPage then
                    DockPage.HandMsgCenterMsgData(payload.msgType)
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
    local world_id = words:match("ID:(%d+)")
    if world_id then
        local str = string.format('<input type="button" value="%s" name="%s" onclick="MyCompany.Aries.Creator.ChatSystem.KpChatHelper.ToWorld" style="float:left;color:#fced4b;background:url()" />', world_id, world_id)
        words = string.gsub(words, world_id, str)
    end

    local temp_id = KpChatChannel.SetTempChatContent(chatdata)

    local channel_tag = string.format([[<div style="float:left">[%s]</div>]],chatdata.channelname);
    local name_tag_start = [[<div style="float:left">[</div>]]

    local user_tag = KpUserTag.GetMcml(chatdata);
    local name_tag_end = [[<div style="float:left">]:</div>]]

    local timestamp_tag = string.format([[<input type="button" value="%s" style="float:left;margin-left:10px;color:#8b8b8b;background:url();" />]],tostring(timestamp));
    if(chatdata.ChannelIndex == ChatChannel.EnumChannels.KpSystem)then
        mcmlStr = string.format([[<div style="color:#%s">%s%s%s%s%s%s%s%s</div>]],color,channel_tag,"","","","",":",words,timestamp_tag);
    else
        local id = string.format("%s_%s",kp_username,temp_id);
        kp_from_name = string.format([[<input type="button" name="%s" value="%s" zorder="1000" onclick="MyCompany.Aries.Creator.ChatSystem.KpChatHelper.ShowMenu" style="float:left;color:#%s;background:url()" />]], id, kp_from_name, color);
        mcmlStr = string.format([[<div style="color:#%s">%s%s%s%s%s%s%s</div>]],color,channel_tag,name_tag_start,user_tag,kp_from_name,name_tag_end,words,timestamp_tag);
    end
    return mcmlStr;
end
function KpChatChannel.GetTempChatContent(id)
    if(id and KpChatChannel.temp_chat_content)then
        return KpChatChannel.temp_chat_content[id];
    end
end
function KpChatChannel.SetTempChatContent(chatdata)
    if(not chatdata or not chatdata.words or not chatdata.kp_from_id)then
        return
    end
    KpChatChannel.temp_chat_content = KpChatChannel.temp_chat_content or {};
    local words = chatdata.words or "";
    local kp_username = chatdata.kp_username or "";
    local kp_from_id = chatdata.kp_from_id;
    local timestamp = chatdata.timestamp;
    local msg = {
        kp_from_id = kp_from_id,
        kp_username  = kp_username ,
        words = words,
        timestamp = timestamp,
    }
    local id = ParaGlobal.GenerateUniqueID();
    KpChatChannel.temp_chat_content[id] = msg;
    return id;
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

    local room_school = KpChatChannel.GetSchoolRoom();
    if(room_school)then
        LOG.std(nil, "info", "KpChatChannel", "try to join school room %s", room_school);
        KpChatChannel.client:Send("app/join",{ rooms = { room_school }, });
    end
end
function KpChatChannel.LeaveWorld(worldId)
    if(not worldId)then
        return
    end
    local room = KpChatChannel.GetRoom();
	LOG.std(nil, "info", "KpChatChannel", "try to leave world %s", room);
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

    if(not MyCompany.Aries.ChatSystem.ChatWindow.ggs_mode)then
        MyCompany.Aries.ChatSystem.ChatWindow.HideAll();
    end
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
-- @param toid			接受者nid
-- @param toname		接受者名字,可为nil
-- @param words			消息内容
-- @param roomName		房间ID
-- http://yapi.kp-para.cn/project/60/interface/api/1952
function KpChatChannel.CreateMessage( ChannelIndex, toid, toname, words, roomName)
	local msgdata;
    if ChannelIndex == ChatChannel.EnumChannels.KpFriend then
        if not KpChatChannel.worldId then
            KpChatChannel.worldId = 0
        end
    end

    local worldId = KpChatChannel.worldId;
    if(not worldId)then
		LOG.std(nil, "warn", "KpChatChannel", "world id is required");
        return
    end
    if(ChannelIndex == ChatChannel.EnumChannels.KpNearBy)then
	    msgdata = { ChannelIndex = ChannelIndex, target = KpChatChannel.GetRoom(), worldId = worldId, words = words, type = 2, is_keepwork = true, };

    elseif(ChannelIndex == ChatChannel.EnumChannels.KpSchool)then
	    msgdata = { ChannelIndex = ChannelIndex, target = KpChatChannel.GetSchoolRoom(), worldId = worldId, words = words, type = 2, is_keepwork = true, };

    elseif(ChannelIndex == ChatChannel.EnumChannels.KpBroadCast)then
	    msgdata = { ChannelIndex = ChannelIndex, target = "paracraftGlobal", worldId = worldId, words = words, type = 3, is_keepwork = true, };

    elseif(ChannelIndex == ChatChannel.EnumChannels.KpFriend)then
	    msgdata = { ChannelIndex = ChannelIndex, target = roomName, worldId = worldId, words = words, type = 4, is_keepwork = true, toid = toid, };
    else
		LOG.std(nil, "warn", "KpChatChannel", "[%s] unsupported channel index in KpChatChannel.SendMessage", tostring(ChannelIndex));
    end
	return msgdata;
end

function KpChatChannel.IsBlockedChannel(ChannelIndex)
    local channels = {
        ChatChannel.EnumChannels.KpNearBy,
        ChatChannel.EnumChannels.KpBroadCast,
    }
    for k,v in ipairs(channels) do
        if(v == ChannelIndex)then
            return true;
        end
    end
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
    local muting_info = KeepWorkItemManager.GetMutingInfo();
    if(muting_info and muting_info.isMuted)then
        _guihelper.MessageBox(L"很抱歉，你被禁言了！");
        return
    end
    local kp_msg = {
        target = msgdata.target,
        payload = {
            ChannelIndex = msgdata.ChannelIndex,
            content = msgdata.words,
            contentType = msgdata.msg_type or 1,
            worldId = msgdata.worldId,
            type = msgdata.type,
            
            toid = msgdata.toid,

            id = user_info.id,
            username = user_info.username,
            nickname = user_info.nickname,
            vip = user_info.vip,
            student = user_info.student,
            orgAdmin = user_info.orgAdmin,
            tLevel = user_info.tLevel,
            tLevel = user_info.tLevel,
        },
    }

    KpChatChannel.client:Send("app/msg",kp_msg);
   
end

