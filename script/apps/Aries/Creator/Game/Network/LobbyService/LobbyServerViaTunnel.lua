--[[
Title: LobbyServer
Author(s): LanZhihong, LiXizhi
Date: 2018/12/19
Desc: LobbyServerViaTunnel communicates with each other in peer to peer mode. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServerViaTunnel.lua");
local LobbyServerViaTunnel = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyServerViaTunnel");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/event_mapping.lua");
NPL.load("(gl)script/ide/commonlib.lua");
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/LobbyService/LobbyMessageType.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/LobbyService/LobbyUserInfo.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua");

local LobbyUserInfo = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyUserInfo");
local LobbyMessageType = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyMessageType");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local NPLReturnCode = commonlib.gettable("NPLReturnCode");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");
local LobbyServer = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyServer");

local LobbyServerViaTunnel = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Network.LobbyServerViaTunnel"));

-- in milliseconds
LobbyServerViaTunnel:Property({"BroadcastInterval", 5000, "GetBroadcastInterval", "SetBroadcastInterval", auto=true});
-- in seconds
LobbyServerViaTunnel:Property({"ConnectTimeout", 3, "GetConnectTimeout", "SetConnectTimeout", auto=true});
-- default to System.User.keepworkUsername
LobbyServerViaTunnel:Property({"Username", nil, "GetUsername", "SetUsername", auto=true});
LobbyServerViaTunnel:Property({"Nickname", nil, "GetNickname", "SetNickname", auto=true});
LobbyServerViaTunnel:Property({"bIsStarted", false, "IsStarted", "SetStarted", auto=true});

LobbyServerViaTunnel:Signal("handleMessage");
LobbyServerViaTunnel:Signal("started");

local callbacks;

local g_instance;
function LobbyServerViaTunnel.GetSingleton()
	if(g_instance) then
		return g_instance;
	else
		g_instance = LobbyServerViaTunnel:new();
		return g_instance;
	end
end

function LobbyServerViaTunnel:ctor()
	NPL.AddPublicFile("script/apps/Aries/Creator/Game/Network/TunnelService/LobbyTunnelServer.lua", 402);
	NPL.AddPublicFile("script/apps/Aries/Creator/Game/Network/TunnelService/LobbyTunnelClient.lua", 403);
	
	self.m_discoveryTimer = nil;
	self._clients = {};
	self._nid_to_name = {};

	self._tunnelclient = nil;
	
	self:InitCallback()
end

function LobbyServerViaTunnel:InitCallback()
	if(not callbacks) then
		callbacks = {};
		callbacks[LobbyMessageType.REQUEST_ECHO] = LobbyServerViaTunnel.onRequestEcho;
		callbacks[LobbyMessageType.RESPONSE_ECHO] = LobbyServerViaTunnel.onResponseEcho;
		callbacks[LobbyMessageType.REQUEST_CONNECT] = LobbyServerViaTunnel.onRequestConnect;
		callbacks[LobbyMessageType.RESPONSE_CONNECT] = LobbyServerViaTunnel.onResponseConnect;
		callbacks[LobbyMessageType.USER_DATA] = LobbyServerViaTunnel.onUserData;
		callbacks[LobbyMessageType.CUSTOM] = LobbyServerViaTunnel.onCustom;
	end
end

-- @param username: default to System.User.keepworkUsername;
-- @param nickname: default to System.User.NickName
function LobbyServerViaTunnel:Start(username, nickname, tunnelclient)
	if self:IsStarted() then
		return
	end

	self:SetUsername(username or System.User.keepworkUsername);
	self:SetNickname(nickname or System.User.NickName);
	
	self._tunnelclient = tunnelclient;
	tunnelclient:Connect("receive_tcp", self, self.onReceiveTCP, "UniqueConnection");
	tunnelclient:Connect("receive_udp", self, self.onReceiveUDP, "UniqueConnection");
	tunnelclient:Connect("client_disconnect", self, self.onClientDisconnect, "UniqueConnection");
	tunnelclient:Connect("tunnel_disconnect", self, self.onTunnelDisconnect, "UniqueConnection");
	
	self:SetStarted(true);
	self:started();
end


function LobbyServerViaTunnel:onTunnelDisconnect()
	self:StopAll();
end

-- @param nid is virtual nid
function LobbyServerViaTunnel:onClientDisconnect(nid)
	self:onDisconnected(nid);
end

-- @param nid is virtual nid
function LobbyServerViaTunnel:onReceiveTCP(nid, msg)
	local callback = callbacks[msg.type];
	if callback then
		msg.nid = nid;
		callback(self, msg);
	end	
end

-- @param nid is virtual nid
function LobbyServerViaTunnel:onReceiveUDP(nid, msg)
	if type(msg) == "string" or not msg.type then
		self:handleMessage("__original", {data = msg, isUDP = true, nid = nid});
	else
		local callback = callbacks[msg.type];
		if callback then
			msg.nid = nid;
			callback(self, msg);
		end	
	end
end

function LobbyServerViaTunnel:StopAll()
	if not self:IsStarted() then
		return;
	end
	self:Log("stopped");
	self:StopDiscovery();

	self._tunnelclient:Disconnect();
	
	self._clients = {};
	self._nid_to_name = {};
	
	self:SetStarted(false);
end

function LobbyServerViaTunnel:StopDiscovery()
	if self.m_discoveryTimer then
		self.m_discoveryTimer:Change();
		self.m_discoveryTimer = nil;
	end
end

function LobbyServerViaTunnel:AutoDiscovery()
	self:StopDiscovery();
	
	local data = {type = LobbyMessageType.REQUEST_ECHO
		, name = self:GetUsername()
		, editMode = not GameLogic.IsReadOnly()
		, projectId = WorldCommon.GetWorldTag("kpProjectId")
		, version = GameLogic.options:GetRevision()
		};
	local tunnelclient = self._tunnelclient;
	
	local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
		tunnelclient:BroadcastUDPMessage(data);
	end})
	
	mytimer:Change(0, self:GetBroadcastInterval());
	self.m_discoveryTimer = mytimer;

	self:Log("auto discovery started");
end


-- send message via Lobby server to another Lobby client
-- @param keepworkUsername: keepworkUsername of the target sLobby client. 
-- @param title: msg title
-- @param data: the raw message table {id=packet_id, .. }. 
function LobbyServerViaTunnel:SendTo(keepworkUsername, title, data)

	local client = self:GetClient(keepworkUsername);
	if not client then
		return;
	end
	
	self._tunnelclient:SendTCPMessage(client:GetNid(), {type = LobbyMessageType.USER_DATA
				, title = title
				, data = data
			});
end

function LobbyServerViaTunnel:BroadcastMessage(title, data)

	local user_addr;
	local tunnelclient = self._tunnelclient;
	local msg = {type = LobbyMessageType.USER_DATA
			, title = title
			, data = data
			};
			
	for k, v in pairs(self:GetClients()) do
		user_addr = v:GetNid();
		tunnelclient:SendTCPMessage(user_addr, msg);
	end

end

-- send raw UDP unicast or broadcast message.  No connection is required. 
-- @param addr : if is nil, we well broadcast message
function LobbyServerViaTunnel:SendOriginalMessage(addr, msgStr)
	if addr then
		self._tunnelclient:SendUDPMessage(addr, msgStr);
	else
		self._tunnelclient:BroadcastUDPMessage(msgStr);
	end
end

-- direct connect a lobby client
-- @param username is a virtual nid
function LobbyServerViaTunnel:ConnectLobbyClient(username)
	local data =
	{
		type = LobbyMessageType.REQUEST_CONNECT,
		name = self:GetUsername(),
		nickname = self:GetNickname(),
	};
	
	self._tunnelclient:SendTCPMessage(username, data);
end

-- direct disconnet a lobby client
-- @param keepworkUsername is not a virtual nid
function LobbyServerViaTunnel:DisconnectLobbyClient(keepworkUsername)

	if not keepworkUsername then
		return;
	end
	
	
	
	local client = self:GetClient(keepworkUsername);
	if client then
		self:onDisconnected(client:GetNid());
	end
end

function LobbyServerViaTunnel:Log(text, ...)
	LOG.std(nil, "info", "LobbyServerViaTunnel_"..self:GetUsername(), text, ...);
end

function LobbyServer:onCustom(msg)
	
end

function LobbyServerViaTunnel:onUserData(msg)
	local nid = msg.nid;
	local keepworkUsername = self._nid_to_name[nid]
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


function LobbyServerViaTunnel:GetClients()
	return self._clients;
end

function LobbyServerViaTunnel:GetClient(keepworkUserName)
	return self._clients[keepworkUserName];
end

function LobbyServerViaTunnel:AddClient(client)
	self._nid_to_name[client:GetNid()] = client:GetUserName();
	self._clients[client:GetUserName()] = client;
end

function LobbyServerViaTunnel:RemoveClient(keepworkUsername)
	local client = self._clients[keepworkUsername];
	if client then
		self._nid_to_name[client:GetNid()] = nil;
		self._clients[keepworkUsername] = nil;
	end
end

function LobbyServerViaTunnel:onRequestConnect(msg)
	
	local keepworkUsername = msg.name;
	
	if not keepworkUsername then
		return;
	end
	
	if self:GetClient(keepworkUsername) then
		-- already connect
		return;
	end
	
	local client = LobbyUserInfo:new():Init(keepworkUsername, msg.nickname, msg.nid);
	self:AddClient(client);
	self:Log("new user connect request: %s nid:%s", client:GetUserName(), client:GetNid());
	
	self._tunnelclient:SendTCPMessage(msg.nid, {
				type = LobbyMessageType.RESPONSE_CONNECT
				, name = self:GetUsername()
				, nickname = self:GetNickname()
			});
			
	self:handleMessage("connect", {userinfo = client});	
end

function LobbyServerViaTunnel:onResponseConnect(msg)
	local keepworkUsername = msg.name;
	
	if not keepworkUsername then
		return;
	end
	
	if self:GetClient(keepworkUsername) then
		-- already connected
		return;
	end
	local client = LobbyUserInfo:new():Init(keepworkUsername, msg.nickname, msg.nid)
	self:AddClient(client);
	self:Log("new user connect reponse: %s nid:%s", client:GetUserName(), client:GetNid());
	self:handleMessage("connect", {userinfo = client});
end

function LobbyServerViaTunnel:onResponseEcho(msg)

	local keepworkUsername = msg.name;
	if not keepworkUsername then
		return;
	end
	
	if self:GetClient(keepworkUsername) then
		-- already connected
		return;
	end
	
	local user_id = msg.nid;
	self:ConnectLobbyClient(user_id);
end

-- Both worlds should be signed in with different users and same project id and world revision. 
-- please note, we allow joining if both worlds are in edit mode even if their revisions are different. 
function LobbyServerViaTunnel:CanJoin(username, projectId, worldRevision, isEditMode)
	if (username and username ~= self:GetUsername())  
		and (projectId and projectId == WorldCommon.GetWorldTag("kpProjectId")) 
		and ((worldRevision == GameLogic.options:GetRevision()) or (isEditMode and not GameLogic.IsReadOnly()))then
		return true;
	end
end

function LobbyServerViaTunnel:onRequestEcho(msg)

	if(not self:CanJoin(msg.name, msg.projectId, msg.version, msg.editMode)) then
		return;
	end

	if self:GetClient(msg.name) then
		return 
	end
	
	local user_id = msg.nid;
	local data = 
	{
		type = LobbyMessageType.RESPONSE_ECHO,
		-- tunnel client do not need port
		port = 0, 
		name = self:GetUsername()
	};
	
	self._tunnelclient:SendUDPMessage(user_id, data);
end

function LobbyServerViaTunnel:onDisconnected(nid)
	
	if not nid then return; end;
	
	local keepworkUsername = self._nid_to_name[nid];
	
	
	if not keepworkUsername then
		return;
	end
	
	self:Log("one user has disconnected : %s", keepworkUsername);
	
	local client = self:GetClient(keepworkUsername);
	if client then
		self:handleMessage("disconnect", {userinfo = client});
		self:RemoveClient(keepworkUsername)
	end
end


