--[[
Title: LobbyTunnelClient

Desc: all LobbyTunnelClient
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/LobbyTunnelClient.lua");
local LobbyTunnelClient = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyTunnelClient");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/LobbyRoomInfo.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/LobbyTunnelMessageType.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/LobbyClientInfo.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua");


local LobbyRoomInfo = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyRoomInfo");
local LobbyTunnelMessageType = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyTunnelMessageType");
local LobbyClientInfo = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyClientInfo");
local LobbyServer = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyServer");

local LobbyTunnelClient = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Network.LobbyTunnelClient"));

-- in seconds
LobbyTunnelClient:Property({"ConnectTimeout", 5, "GetConnectTimeout", "SetConnectTimeout", auto=true});
LobbyTunnelClient:Property({"Connected", false, "IsConnected", "SetConnected", auto=true});
LobbyTunnelClient:Property({"UDPLogin", false, "IsUDPLogin", "SetUDPLogin", auto=true});
--

LobbyTunnelClient:Signal("receive_tcp");
LobbyTunnelClient:Signal("receive_udp");
LobbyTunnelClient:Signal("client_disconnect");
LobbyTunnelClient:Signal("tunnel_disconnect");

LobbyTunnelClient.ServerNid = "__LobbyTunnelServer";
LobbyTunnelClient.ServerAddress = "__LobbyTunnelServer:script/apps/Aries/Creator/Game/Network/TunnelService/LobbyTunnelServer.lua";

local callbacks;

local g_instance;
function LobbyTunnelClient.GetSingleton()
	if(g_instance) then
		return g_instance;
	else
		g_instance = LobbyTunnelClient:new();
		return g_instance;
	end
end

function LobbyTunnelClient:ctor()
	-- 
	self._pending_connect = nil;
	--
	self._isStart = false;
	--
	self._token = nil;
	--
	self._room_key = nil;
	--
	self._user_name = nil;
	-- 
	self._pending_udp_login = nil;

	self.InitCallback()
end

function LobbyTunnelClient:isStart()
	return self._isStart;
end

function LobbyTunnelClient.InitCallback()
	if not callbacks then
		callbacks = {};
		
		callbacks[LobbyTunnelMessageType.ResponseLogin] = LobbyTunnelClient.onResponseLogin;
		callbacks[LobbyTunnelMessageType.ResponseMessage] = LobbyTunnelClient.onResponseMessage;
		callbacks[LobbyTunnelMessageType.ClientDisconnect] = LobbyTunnelClient.onClientDisconnect;
		callbacks[LobbyTunnelMessageType.ResponseUDPMessage] = LobbyTunnelClient.onResponseUDPMessage;
		callbacks[LobbyTunnelMessageType.ResponseUDPLogin] = LobbyTunnelClient.onResponseUDPLogin;
	end
end

function LobbyTunnelClient:Log(text, ...)
	LOG.std(nil, "info", "LobbyTunnelClient", text, ...);
end

function LobbyTunnelClient.AddServerUDPAddress(ip, port)
	NPL.AddNPLRuntimeAddress({
		host = ip,
		port = port,
		nid = LobbyTunnelClient.ServerNid,
		isUDP = true,
	});
end

function LobbyTunnelClient:StopUDPLogin()
	if self._pending_udp_login then
		self._pending_udp_login:Change();
		self._pending_udp_login = nil;
		
		self:Log("StopUDPLogin");
	end
end

function LobbyTunnelClient:StartUDPLogin()
	if not self._user_name or not self._token then
		return;
	end
	
	self:Log("StartUDPLogin");

	local data =
	{
		type = LobbyTunnelMessageType.RequestUDPLogin;
		name = self._user_name;
		token = self._token;
	}

	local timer = commonlib.Timer:new({callbackFunc = function(timer)
				NPL.activate(self.ServerAddress, data, 1, 2, 0);
			end});
	timer:Change(0, 500);
	
	self._pending_udp_login = timer;
end

function LobbyTunnelClient:onResponseUDPLogin(msg)
	self:StopUDPLogin();
	if msg.success then
		self:SetUDPLogin(true);
		self:Log("udp login success");
	end
end

function LobbyTunnelClient:onResponseLogin(msg)
	if not msg.success then
		self:Log("tcp login faild, desc = %s", msg.errDesc);
	else
		self._token = msg.token;
		self._room_key = msg.room;
		local nid = msg.nid or tid;
		local port = msg.udpport;
		
		local ip = NPL.GetIP(nid);

		self.AddServerUDPAddress(ip, tostring(port));
		self:StartUDPLogin();
		
		self:SetConnected(true);

		self:Log("tcp login successed");
	end
end


function LobbyTunnelClient:onResponseMessage(msg)
	self:receive_tcp(msg.src, msg.data);
end

function LobbyTunnelClient:onResponseUDPMessage(msg)
	self:receive_udp(msg.src, msg.data);
end

function LobbyTunnelClient:onClientDisconnect(msg)
	self:client_disconnect(msg.src);
end

-- @param ip, port: IP address of tunnel server
-- @param username: unique user name
-- @param room_key: room_key
-- @param password: optional password
-- @param callbackFunc: function(bSuccess) end
function LobbyTunnelClient:ConnectServer(ip, port, username, projectId, room_key, password, callbackFunc)
	local function onSendEnd(bSuccess)
		if not bSuccess then
			-- connect faild
			if callbackFunc then
				callbackFunc(false);
			end
			return;
		end
		
		local time_left = 5;
		local time_interval = 100;
		
		local timer = commonlib.Timer:new({callbackFunc = function(timer)
				if self:IsConnected() then
					if callbackFunc then
						callbackFunc(true);
					end
				else
					if time_left > 0 then
						time_left = time_left - time_interval * 0.001;
						time_interval = time_interval * 2;
						timer:Change(time_interval, nil);
					else
						if callbackFunc then
							callbackFunc(false);
						end
					end
				end
		
			end});
		timer:Change(time_interval, nil);
	end

	self:__ConnectServer(ip, port, username, projectId, room_key, password, onSendEnd);
end


-- @param ip, port: IP address of tunnel server
-- @param username: unique user name
-- @param room_key: room_key
-- @param password: optional password
-- @param callbackFunc: function(bSuccess) end
function LobbyTunnelClient:__ConnectServer(ip, port, username, projectId, room_key, password, callbackFunc)
	if self._isStart then
		self:Log("server has connected");
		if callbackFunc then
			callbackFunc(false);
		end
		return;
	end

	self:Log({"connecting to", ip, port, room_key});
	
	ParaScene.RegisterEvent("_n_paracraft_lobby_tunnel_client", ";_OnLobbyTunnelClientNetworkEvent();");
	
	self._isStart = true;
	
	local params = {host = tostring(ip), port = tostring(port), nid = self.ServerNid};
	NPL.AddNPLRuntimeAddress(params);
	
	self._user_name = username;
	
	local msg =
	{
		type = LobbyTunnelMessageType.RequestLogin;
		name = username;
		pId = projectId;
		room = room_key;
		psw = password;
	};

	local function onEnd(bSuccessed)
		self._pending_connect = nil;
		
		if bSuccessed then
			self:Log("send login msg successed");
		else
			self:Log("send login msg faild");
		end
				
		if callbackFunc then
			callbackFunc(bSuccessed);
		end
	end
	
	local res, stopFunc;
	res, stopFunc = LobbyServer.activate_async_with_timeout(self:GetConnectTimeout()
			, self.ServerAddress
			, msg
			, onEnd);
			
	if res ~= 0 then 
		self._pending_connect = function() stopFunc(); if callbackFunc then callbackFunc(false); end; end;
	else
		onEnd(true);
	end
end

function LobbyTunnelClient:onDisconnected(nid)
	if self._pending_connect then
		self._pending_connect();
		self._pending_connect = nil;
	end
	
	self._isStart = false;
	--
	self._token = nil;
	--
	self._room_key = nil;
	--
	self._user_name = nil;
	
	self:SetConnected(false);
	
	
	self:tunnel_disconnect();
end

function LobbyTunnelClient:Disconnect()
	if self._isStart then
		if self._pending_connect then
			self._pending_connect();
			self._pending_connect = nil;
		end
		
		self:StopUDPLogin();
		self:SetUDPLogin(false);
		
		NPL.reject(self.ServerNid);
	end
end

function LobbyTunnelClient:GetRoomKey()
	return self._room_key;
end

-- send message via tunnel server to another tunnel client
-- @param username: unique user name of the target stunnel client. usually the keepworkUsername
-- @param msg: the raw message table {id=packet_id, .. }. 
function LobbyTunnelClient:SendTCPMessage(username, msg)
	local msg =
	{
		type = LobbyTunnelMessageType.SendMessage;
		dst = username;
		data = msg;
	};
	
	NPL.activate(self.ServerAddress, msg);
end

-- broadcast message via tunnel server to another tunnel client
-- @param msg: the raw message table {id=packet_id, .. }. 
function LobbyTunnelClient:BroadcastTCPMessage(msg)
	local msg =
	{
		type = LobbyTunnelMessageType.BroadcastMessage;
		data = msg;
	};
	
	NPL.activate(self.ServerAddress, msg);
end

-- send message via tunnel server to another tunnel client
-- @param username: unique user name of the target stunnel client. usually the keepworkUsername
-- @param msg: the raw message table {id=packet_id, .. }. 
function LobbyTunnelClient:SendUDPMessage(username, msg)
	if not self:IsUDPLogin() then
		return;
	end
	
	local msg =
	{
		type = LobbyTunnelMessageType.SendUDPMessage;
		dst = username;
		data = msg;
	};
	
	NPL.activate(self.ServerAddress, msg, 1, 2, 0);
end

-- broadcast message via tunnel server to another tunnel client
-- @param msg: the raw message table {id=packet_id, .. }. 
function LobbyTunnelClient:BroadcastUDPMessage(msg)
	if not self:IsUDPLogin() then
		return;
	end

	local msg =
	{
		type = LobbyTunnelMessageType.BroadcastUDPMessage;
		data = msg;
	};
	
	NPL.activate(self.ServerAddress, msg, 1, 2, 0);
end


function LobbyTunnelClient:onUnknown(msg)
end

function LobbyTunnelClient:handleReceive(msg)
	local msg_type 	= msg.type;
	
	if msg_type then
		local cb = callbacks[msg_type];
		if cb then
			cb(self, msg);
		else
			self:onUnknown(msg);
		end
	else
		self:onUnknown(msg);
	end
end

function LobbyTunnelClient:onNetworkEvent(msg)
	if msg.code == NPLReturnCode.NPL_ConnectionDisconnected 
		and msg.nid == self.ServerNid then
		self:onDisconnected(msg.nid);
	end
end

function _OnLobbyTunnelClientNetworkEvent()
	LobbyTunnelClient.GetSingleton():onNetworkEvent(msg);
end


local function activate()
	if(g_instance and g_instance:isStart()) then
		g_instance:handleReceive(msg)
	end
end

NPL.this(activate);