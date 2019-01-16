--[[
Title: LobbyServer
Author(s): LanZhihong, LiXizhi
Date: 2018/12/19
Desc: LobbyServer communicates with each other in peer to peer mode. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua");
local LobbyServer = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyServer");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/event_mapping.lua");
NPL.load("(gl)script/ide/commonlib.lua");
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/LobbyService/LobbyMessageType.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/LobbyService/LobbyUserInfo.lua");
local LobbyUserInfo = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyUserInfo");
local LobbyMessageType = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyMessageType");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local NPLReturnCode = commonlib.gettable("NPLReturnCode");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

local LobbyServer = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Network.LobbyServer"));

-- in milliseconds
LobbyServer:Property({"BroadcastInterval", 5000, "GetBroadcastInterval", "SetBroadcastInterval", auto=true});
-- in seconds
LobbyServer:Property({"ConnectTimeout", 3, "GetConnectTimeout", "SetConnectTimeout", auto=true});
-- default to System.User.keepworkUsername
LobbyServer:Property({"Username", nil, "GetUsername", "SetUsername", auto=true});
LobbyServer:Property({"Nickname", nil, "GetNickname", "SetNickname", auto=true});
LobbyServer:Property({"bIsStarted", false, "IsStarted", "SetStarted", auto=true});
LobbyServer:Signal("handleMessage");
LobbyServer:Signal("started");

local callbacks;

local g_instance;
function LobbyServer.GetSingleton()
	if(g_instance) then
		return g_instance;
	else
		g_instance = LobbyServer:new();
		return g_instance;
	end
end

function LobbyServer:ctor()
	NPL.AddPublicFile("script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua", 301);
	
	self.m_discoveryTimer = nil;
	self._clients = {};
	self._pending = {};
	self._ExternalIPList = nil;
	self:InitCallback()
end

function LobbyServer:InitCallback()
	if(not callbacks) then
		callbacks = {};
		callbacks[LobbyMessageType.REQUEST_ECHO] = LobbyServer.onRequestEcho;
		callbacks[LobbyMessageType.RESPONSE_ECHO] = LobbyServer.onResponseEcho;
		callbacks[LobbyMessageType.REQUEST_CONNECT] = LobbyServer.onRequestConnect;
		callbacks[LobbyMessageType.RESPONSE_CONNECT] = LobbyServer.onResponseConnect;
		callbacks[LobbyMessageType.USER_DATA] = LobbyServer.onUserData;
		callbacks[LobbyMessageType.CUSTOM] = LobbyServer.onCustom;
	end
end

-- @param username: default to System.User.keepworkUsername;
-- @param nickname: default to System.User.NickName
function LobbyServer:Start(username, nickname)
	if self:IsStarted() then
		return
	end

	local att = NPL.GetAttributeObject();
	local ipList = att:GetField("ExternalIPList");
	ipList = commonlib.split(ipList, ",");
	self._ExternalIPList = ipList;
	
	ParaScene.RegisterEvent("_n_paracraft_lobby", ";_OnLobbyServerNetworkEvent();");
	
	self:SetUsername(username or System.User.keepworkUsername)
	self:SetNickname(nickname or System.User.NickName)
	
	self:SetStarted(true);
	self:started();
end

function LobbyServer:StopAll()
	if not self:IsStarted() then
		return;
	end
	LOG.std(nil, "info", "LobbyServer", "stopped");
	self:StopDiscovery();
	
	for nid, stopFunc in pairs(self._pending) do
		stopFunc();
	end
	self._pending = {};
	
	for keepworkUsername, v in pairs(self:GetClients()) do
		NPL.reject(v:GetNid());
	end
	
	self._clients = {};
	
	self:SetStarted(false);
end

function LobbyServer:StopDiscovery()
	if self.m_discoveryTimer then
		self.m_discoveryTimer:Change();
		self.m_discoveryTimer = nil;
	end
end

function LobbyServer:AutoDiscovery(broadcast_address_list)
	self:StopDiscovery();
	local server_addr_list = {};
	
	if not broadcast_address_list then
		table.insert(server_addr_list, "(gl)*8099:script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua");
		
		local att = NPL.GetAttributeObject();
		broadcast_address_list = att:GetField("BroadcastAddressList");
		broadcast_address_list = commonlib.split(broadcast_address_list, ",");
	end
	
	for k, v in pairs(broadcast_address_list) do
		table.insert(server_addr_list, string.format("(gl)\\\\%s 8099:script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua", v));
	end
	
	local data = {type = LobbyMessageType.REQUEST_ECHO
		, name = self:GetUsername()
		, editMode = not GameLogic.IsReadOnly()
		, projectId = WorldCommon.GetWorldTag("kpProjectId")
		, version = GameLogic.options:GetRevision()
		};

	
	local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
		for k, server_addr in pairs(server_addr_list) do
			NPL.activate(server_addr, data, 1, 2, 0);
		end
	end})
	
	mytimer:Change(0, self:GetBroadcastInterval());
	self.m_discoveryTimer = mytimer;

	LOG.std(nil, "info", "LobbyServer", "auto discovery started with %s", table.concat(broadcast_address_list or {}, ","));
end


-- send message via Lobby server to another Lobby client
-- @param keepworkUsername: keepworkUsername of the target sLobby client. 
-- @param title: msg title
-- @param data: the raw message table {id=packet_id, .. }. 
function LobbyServer:SendTo(keepworkUsername, title, data)
	local client = self:GetClient(keepworkUsername);
	if not client then
		return;
	end
	
	local user_addr = string.format("(gl)%s:script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua",  client:GetNid());
	NPL.activate(user_addr, {type = LobbyMessageType.USER_DATA
		, title = title
		, data = data
		});
end

function LobbyServer:BroadcastMessage(title, data)
	local user_addr;
	local msg = {type = LobbyMessageType.USER_DATA
			, title = title
			, data = data
			};
			
	for k, v in pairs(self:GetClients()) do
		user_addr = string.format("(gl)%s:script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua",  v:GetNid());
		NPL.activate(user_addr, msg);
	end
end

-- send raw UDP unicast or broadcast message.  No connection is required. 
-- @param addr : if is nil, we well broadcast message
function LobbyServer:SendOriginalMessage(addr, msgStr)


	if not msgStr then return; end;
	if addr then
		addr = string.format("(gl)%s:script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua",  addr);
		NPL.activate(addr, "\0" .. msgStr, 1, 2, 0);
	else
		local server_addr_list = {"(gl)*8099:script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua"};
		local att = NPL.GetAttributeObject();
		local broadcast_address_list = att:GetField("BroadcastAddressList");
		broadcast_address_list = commonlib.split(broadcast_address_list, ",");
		
		for k, v in pairs(broadcast_address_list) do
			table.insert(server_addr_list, string.format("(gl)\\\\%s 8099:script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua", v));
		end

		msgStr = "\0" .. msgStr;
		for k, server_addr in pairs(server_addr_list) do
			NPL.activate(server_addr, msgStr, 1, 2, 0);
		end
	end
end

-- @param timeout_seconds: the number of seconds to wait. if 0, it will only try once.
-- @return the last NPL.activate call result and the stop function
function LobbyServer.activate_async_with_timeout(timeout_seconds, filename, msg, callback)
	local res = NPL.activate(filename, msg);

	if(res ~= 0 and timeout_seconds > 0) then
		local stopFunc;
		
		local time_left = timeout_seconds;
		local time_interval = 100;
		
		local timer = commonlib.Timer:new({callbackFunc = function(timer)
			local res = NPL.activate(filename, msg);
			if(res ~= 0) then
				if(time_left > 0) then
					time_left = time_left - time_interval*0.001;
					time_interval = time_interval * 2;
					timer:Change(time_interval, nil);
				else
					if callback then
						callback(false);
					end
				end
			else
				if callback then
					callback(true);
				end
			end
		end})
		timer:Change(time_interval, nil);
		
		stopFunc = function()
			timer:Change();
		end
		
		return res, stopFunc;
	else
		return res, nil;
	end

end

-- direct connect a lobby client
function LobbyServer:ConnectLobbyClient(ip, port)
	local nid = "_LobbyServer_tmp_" .. tostring(ip)..tostring(port);
	
	if self._pending[nid] then
		return;
	end

	local function onEnd(bSuccessed)
		self._pending[nid] = nil;
	end
	
	
	NPL.AddNPLRuntimeAddress({host = ip, port = tostring(port), nid = nid});
	local user_addr = string.format("(gl)%s:script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua",  nid);
	
	local res, stopFunc;
	res, stopFunc = self.activate_async_with_timeout(self:GetConnectTimeout(), user_addr,  {type = LobbyMessageType.REQUEST_CONNECT, name = self:GetUsername(), nickname = self:GetNickname()}, onEnd);
	
	if res ~= 0 then
		self._pending[nid] = stopFunc;
	end
end

function LobbyServer:DisconnectLobbyClient(keepworkUsername)
	if not keepworkUsername then
		return;
	end
	
	local client = self:GetClient(keepworkUsername);
	if client then
		NPL.reject(client:GetNid());
	end
end



function LobbyServer:onMsg(msg)
	if not msg.type then
		if msg.isUDP then
			self:handleMessage("__original", msg);
		end
	else
		local callback = callbacks[msg.type];
		if callback then
			callback(self, msg);
		end	
	end
end

function LobbyServer:Log(text, ...)
	LOG.std(nil, "info", "LobbyServer_"..self:GetUsername(), text, ...);
end

function LobbyServer:onCustom(msg)
	
end

function LobbyServer:onUserData(msg)
	local nid = msg.nid;
	local keepworkUsername = string.match(nid, "LobbyServer_(%w+)");
	if not keepworkUsername then
		return;
	end
	
	local client = self:GetClient(keepworkUsername);
	if not client then
		return;
	end
	
	local data = msg.data;
	data.userinfo = client;
	
	self:handleMessage(msg.title or "unname", data);	
end


function LobbyServer:GetClients()
	return self._clients;
end

function LobbyServer:GetClient(keepworkUserName)
	return self._clients[keepworkUserName];
end

function LobbyServer:AddClient(client)
	self._clients[client:GetUserName()] = client;
end

function LobbyServer:RemoveClient(keepworkUsername)
	self._clients[keepworkUsername] = nil;
end

function LobbyServer:onRequestConnect(msg)
	local keepworkUsername = msg.name;
	
	if not keepworkUsername then
		return;
	end
	
	if self:GetClient(keepworkUsername) then
		-- already connect
		return;
	end

	local client = LobbyUserInfo:new():Init(keepworkUsername, msg.nickname);
	self:AddClient(client);
	self:Log("new user connect request: %s nid:%s", client:GetUserName(), client:GetNid());
	NPL.accept(msg.tid, client:GetNid());
	
	local user_addr = string.format("(gl)%s:script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua",  client:GetNid());
	
	NPL.activate(user_addr, {type = LobbyMessageType.RESPONSE_CONNECT
		, name = self:GetUsername()
		, nickname = self:GetNickname()
		});
	
	self:handleMessage("connect", {userinfo = client});	
end

function LobbyServer:onResponseConnect(msg)
	local keepworkUsername = msg.name;
	
	if not keepworkUsername then
		return;
	end
	
	if self:GetClient(keepworkUsername) then
		-- already connected
		return;
	end
	local client = LobbyUserInfo:new():Init(keepworkUsername, msg.nickname)
	self:AddClient(client);
	NPL.accept(msg.nid or msg.tid, client:GetNid());
	self:Log("new user connect reponse: %s nid:%s", client:GetUserName(), client:GetNid());
	self:handleMessage("connect", {userinfo = client});
end

function LobbyServer:onResponseEcho(msg)
	local keepworkUsername = msg.name;
	if not keepworkUsername then
		return;
	end
	
	if self:GetClient(keepworkUsername) then
		-- already connected
		return;
	end
	
	local user_id = msg.tid or msg.nid;
	local ip, _ = string.match(user_id, "~udp(%d+.%d+.%d+.%d+)_(%d+)");
	local port = msg.port;
	
	--[[
	local nid = "_LobbyServer_tmp_" .. ip;
	NPL.AddNPLRuntimeAddress({host = ip, port = tostring(port), nid = nid});
	local user_addr = string.format("(gl)%s:script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua",  nid);
	
	NPL.activate(user_addr, {type = LobbyMessageType.REQUEST_CONNECT, name = self:GetUsername(), nickname = self:GetNickname()});
	]]
	self:ConnectLobbyClient(ip, port);
end

-- Both worlds should be signed in with different users and same project id and world revision. 
-- please note, we allow joining if both worlds are in edit mode even if their revisions are different. 
function LobbyServer:CanJoin(username, projectId, worldRevision, isEditMode)
	if (username and username ~= self:GetUsername())  
		and (projectId and projectId == WorldCommon.GetWorldTag("kpProjectId")) 
		and ((worldRevision == GameLogic.options:GetRevision()) or (isEditMode and not GameLogic.IsReadOnly()))then
		return true;
	end
end

function LobbyServer:onRequestEcho(msg)
	if(not self:CanJoin(msg.name, msg.projectId, msg.version, msg.editMode)) then
		return;
	end

	if self:GetClient(msg.name) then
		return 
	end

	local att = NPL.GetAttributeObject();
	local port = tonumber(att:GetField("HostPort"));
	local user_id = msg.tid or msg.nid;
	local user_addr = string.format("(gl)%s:script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua",  user_id);
	
	NPL.activate(user_addr, {type = LobbyMessageType.RESPONSE_ECHO, port = port, name = self:GetUsername()}, 1, 2, 0);
end

function LobbyServer:onDisconnected(nid)
	if not nid then
		return;
	end
	
	local keepworkUsername = string.match(nid, "LobbyServer_(%w+)");
	
	if not keepworkUsername then
		return;
	end
	
	local client = self:GetClient(keepworkUsername);
	if client then
		self:handleMessage("disconnect", {userinfo = client});
		self:RemoveClient(keepworkUsername)
	end
end

function LobbyServer:onNetworkEvent(msg)
	if msg.code == NPLReturnCode.NPL_ConnectionDisconnected then
		self:onDisconnected(msg.nid)
	end
end

function _OnLobbyServerNetworkEvent()
	LobbyServer.GetSingleton():onNetworkEvent(msg);
end

local function activate()
	if g_instance and g_instance:IsStarted() then
		g_instance:onMsg(msg);
	end
end
NPL.this(activate);