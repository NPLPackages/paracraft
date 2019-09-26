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
-- whether to log all batch messages to log.txt
TunnelClient:Property({"logBatchMsg", false, "IsLogBatchMsg", "SetLogBatchMsg", auto=true})


TunnelClient:Signal("server_connected")

local clients = {};

function TunnelClient:ctor()
	self.virtualConns = {};
	self.lastMsgNids = commonlib.Array:new();
	self.timer = self.timer or commonlib.Timer:new({callbackFunc = function(timer)
		self:OnTimer(timer);
	end})
	
	NPL.RegisterEvent(0, "_n_TunnelClient_network", ";MyCompany.Aries.Game.Network.TunnelClient.OnNetworkEvent();");
end

-- c++ callback function. 
function TunnelClient.OnNetworkEvent()
	local self = s_singletonServer;
	local msg = msg;
	local code = msg.code;
	local msg_msg = msg.msg;
	if(code == NPLReturnCode.NPL_ConnectionDisconnected) then
		local tunnelClient = clients[msg.tid or msg.nid];
		if(tunnelClient) then
			LOG.std(nil, "info", "TunnelClient", "lost connection");
			-- TODO: find a way to inform the user
			tunnelClient:Disconnect();
		end
	end
end

-- @param ip, port: IP address of tunnel server
-- @param room_key: room_key
-- @param username: unique user name
-- @param password: optional password
-- @param callbackFunc: function(bSuccess) end
function TunnelClient:ConnectServer(ip, port, room_key, username, password, callbackFunc)
	LOG.std(nil, "info", "TunnelClient", {"connecting to", ip, port, room_key});
	self.room_key = room_key;
	self.username = username;
	self.password = password;
	-- TODO: reuse connection to the same server
	local conn = ConnectionBase:new();
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetHandler.lua");
	local NetHandler = commonlib.gettable("MyCompany.Aries.Game.Network.NetHandler");
	local nid = NetHandler:CheckGetNidFromIPAddress(ip, port)
	conn:SetDefaultNeuronFile("script/apps/Aries/Creator/Game/Network/TunnelService/TunnelServer.lua");
	conn:SetNid(nid);
	self.conn = conn;
	self.timer:Change(200, 200); 
	clients[nid] = self;

	conn:Connect(5, function(bSuccess, errorMsg)
		self:SetConnected(bSuccess);
		if(bSuccess) then
			LOG.std(nil, "info", "TunnelClient", "successfully connected to tunnel server");
		else
			LOG.std(nil, "info", "TunnelClient", "failed to connect to tunnel server: %s :%s (room_key: %s)", tostring(ip), tostring(port), room_key or "");
		end
		if(callbackFunc) then
			callbackFunc(bSuccess, errorMsg);
		end
	end)
	
end

-- get virtual nid: use username directly as nid. it must be unique within the same room.
function TunnelClient:GetVirtualNid(username)
	return username or "admin";
end

function TunnelClient:Disconnect()
	for nid, connection in pairs(self.virtualConns) do
		connection:OnConnectionLost();
		connection:OnError("OnConnectionLost with reason = server actively disconnect");
	end
	self.virtualConns = {};
	self.timer:Change(); 
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
	-- check msg, and route via tunnel server
	if(self.conn) then
		-- merge the identical messages to several users into one message, send only once. 
		if(self.lastMsg ~= msg) then
			self:SendLastBatchMessages();

			self.lastMsg = msg;
			self.lastMsgNids:push_back(nid);
		elseif(msg) then
			self.lastMsgNids:push_back(nid);
		else
			self.conn:Send({room_key=self.room_key, dest=nid, msg=msg}, nil)
		end

		-- self.conn:Send({room_key=self.room_key, dest=nid, msg=msg}, nil)
	end
end

function TunnelClient:SendLastBatchMessages()
	if(self.lastMsg) then
		-- batch send identical messages to self.lastMsgNids
		local nBatchMsgSize = self.lastMsgNids:size();
		if(nBatchMsgSize == 1) then
			self.conn:Send({room_key=self.room_key, dest=self.lastMsgNids[1], msg=self.lastMsg}, nil)
		elseif(nBatchMsgSize > 1) then
			-- for i = 1, nBatchMsgSize do
			--	  self.conn:Send({room_key=self.room_key, dest=self.lastMsgNids[i], msg=self.lastMsg}, nil)
			-- end

			-- send one batch message to all destinations
			self.conn:Send({room_key=self.room_key, dests = self.lastMsgNids, msg=self.lastMsg}, nil)

			if(self.logBatchMsg) then
				local msgText = commonlib.serialize_compact(self.lastMsg)
				LOG.std(nil, "debug", "TunnelClient", "%s batch sent %d bytes to %d end points", self.username, #(msgText), self.lastMsgNids:size());
				echo(msgText)
			end
		else
			LOG.std(nil, "error", "TunnelClient", "no batch messages to send");
		end
		
		self.lastMsg = nil;
		self.lastMsgNids:clear();
	end
end

function TunnelClient:OnTimer(timer)
	self:SendLastBatchMessages();
end

-- login with current user name
-- @param callbackFunc: function(bAuthenticated, errorMsg) end
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
		if(msg.result == true) then
			LOG.std(nil, "info", "TunnelClient", "tunnel client `%s` is authenticated by the room_key: %s", self.username or "", self.room_key or "");
		else
			LOG.std(nil, "info", "TunnelClient", "tunnel client `%s` login failed because %s", self.username or "", msg.error or "");
			self.conn:OnConnectionLost();
			self.conn:OnError("tunnel login failed with reason = "..msg.error or "");
			self:Disconnect();
		end
		if(self.login_callback) then
			self.login_callback(self:IsAuthenticated(), msg.error);
		end
	elseif(msg.type == "tunnel_user_disconnect") then
		local connection = self.virtualConns[msg.username or ""];
		if(connection) then
			connection:OnConnectionLost();
			-- inform the netServerHandler about it.
			local reason = msg.reason or "unknown";
			connection:OnError("OnConnectionLost with reason = "..reason);
			self.virtualConns[msg.username] = nil
			LOG.std(nil, "info", "TunnelClient", "user `%s` is disconnected from room: %s", msg.username or "", self.room_key or "");
		end
	else
		-- other commands
	end
end
	

-- msg = {room_key, from=username, msg=orignal raw message}
local function activate()
	-- echo({"TunnelClient:receive--------->", msg})
	local msg = msg;
	local tunnelClient = clients[msg.nid or msg.tid];
	if(tunnelClient) then
		if(msg.type) then
			tunnelClient:handleCmdMsg(msg);
		else
			msg.msg.nid = msg.from;
			tunnelClient:handleRelayMsg(msg.msg);
		end
	end
end
NPL.this(activate);