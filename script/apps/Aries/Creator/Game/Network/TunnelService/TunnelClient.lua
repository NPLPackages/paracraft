--[[
Title: TunnelClient
Author(s): LiXizhi
Date: 2016/3/4
Desc: all TunnelClient
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/TunnelClient.lua");
local TunnelClient = commonlib.gettable("MyCompany.Aries.Game.Network.TunnelClient");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ConnectionBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/RoomInfo.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ServerListener.lua");
local ConnectionBase = commonlib.gettable("MyCompany.Aries.Game.Network.ConnectionBase");
local ServerListener = commonlib.gettable("MyCompany.Aries.Game.Network.ServerListener");
local RoomInfo = commonlib.gettable("MyCompany.Aries.Game.Network.RoomInfo");

local TunnelClient = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Network.TunnelClient"));

TunnelClient:Property({"Connected", false, "IsConnected", "SetConnected", auto=true})
TunnelClient:Property({"bAuthenticated", false, "IsAuthenticated", "SetAuthenticated", auto=true})

TunnelClient:Signal("server_connected")

local clients = {};

function TunnelClient:ctor()
	self.virtualConns = {};
end

-- @param ip, port: IP address of tunnel server
-- @param room_key: room_key
-- @param username: unique user name
-- @param password: optional password
-- @param callbackFunc: function(bSuccess) end
function TunnelClient:ConnectServer(ip, port, room_key, username, password, callbackFunc)
	clients[room_key] = self;
	
	LOG.std(nil, "info", "TunnelClient", {"connecting to", ip, port, room_key});
	self.room_key = room_key;
	self.username = username;
	self.password = password;
	-- TODO: reuse connection to the same server
	local conn = ConnectionBase:new();
	local params = {host = tostring(ip or "127.0.0.1"), port = tostring(port or 8099), nid = room_key};
	NPL.AddNPLRuntimeAddress(params);
	conn:SetDefaultNeuronFile("script/apps/Aries/Creator/Game/Network/TunnelService/TunnelServer.lua");
	conn:SetNid(room_key);
	self.conn = conn;

	conn:Connect(5, function(bSuccess)
		self:SetConnected(bSuccess);
		if(bSuccess) then
			LOG.std(nil, "info", "TunnelClient", "successfully connected to tunnel server");
		else
			LOG.std(nil, "info", "TunnelClient", "failed to connect to tunnel server: %s :%s (room_key: %s)", params.host, params.port, room_key or "");
		end
		if(callbackFunc) then
			callbackFunc(bSuccess);
		end
	end)
	
end

-- get virtual nid: use username directly as nid. it must be unique within the same room.
function TunnelClient:GetVirtualNid(username)
	return username or "admin";
end

function TunnelClient:Disconnect()
	-- TODO:
end

-- manage virtual connections
function TunnelClient:AddVirtualConnection(nid, tcpConnection)
	self.virtualConns[nid] = tcpConnection;
end


-- send message via tunnel server to another tunnel client
-- @param nid: virtual nid of the target stunnel client. usually the user name
-- @param msg: the raw message table {id=packet_id, .. }. 
-- @param neuronfile: should be nil. By default, it is ConnectionBase. 
function TunnelClient:Send(nid, msg, neuronfile)
	-- TODO; check msg, and route via tunnel server
	if(self.conn) then
		self.conn:Send({room_key=self.room_key, dest=nid, msg=msg}, nil)
	end
end

-- login with current user name
function TunnelClient:LoginTunnel(callbackFunc)
	-- send a tunnel login message
	if(self.conn) then
		self.conn:Send({type="tunnel_login", room_key=self.room_key, username=self.username, }, nil)
		self.login_callback = callbackFunc;
	end
end


function TunnelClient:handleRelayMsg(msg)
	-- forward message
	if(msg) then
		local conn = self.virtualConns[msg.nid];
		if(not conn) then
			-- accept connections if any
			msg.tid = msg.nid;
			ServerListener:OnAcceptIncomingConnection(msg, self);
			conn = self.virtualConns[msg.nid];
		end

		if(conn) then
			conn:OnNetReceive(msg);
		end
	end
end

function TunnelClient:handleCmdMsg(msg)
	if(msg.type == "tunnel_login") then
		self:SetAuthenticated(msg.result == true);
		LOG.std(nil, "info", "TunnelClient", "tunnel client `%s` is authenticated by the room_key: %s", self.username or "", self.room_key or "");
		if(self.login_callback) then
			self.login_callback(self:IsAuthenticated());
		end
	else
		-- other commands
	end
end
	

-- msg = {room_key, from=username, msg=orignal raw message}
local function activate()
	-- echo({"TunnelClient:receive--------->", msg})
	local msg = msg;
	local room_key = msg.room_key or msg.nid;
	if(room_key) then
		tunnelClient = clients[room_key];
		if(tunnelClient) then
			if(msg.type) then
				tunnelClient:handleCmdMsg(msg);
			else
				msg.msg.nid = msg.from;
				tunnelClient:handleRelayMsg(msg.msg);
			end
		end
	end
end
NPL.this(activate);