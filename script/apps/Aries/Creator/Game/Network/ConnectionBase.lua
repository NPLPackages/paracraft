--[[
Title: ConnectionBase
Author(s): LiXizhi
Date: 2014/6/25
Desc: base connection
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ConnectionBase.lua");
local ConnectionBase = commonlib.gettable("MyCompany.Aries.Game.Network.ConnectionBase");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ServerListener.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Connections.lua");
local Connections = commonlib.gettable("MyCompany.Aries.Game.Network.Connections");
local Packet_Types = commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet_Types");
local ServerListener = commonlib.gettable("MyCompany.Aries.Game.Network.ServerListener");

local ConnectionBase = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Network.ConnectionBase"));

ConnectionBase.default_neuron_file = "script/apps/Aries/Creator/Game/Network/ConnectionBase.lua";

function ConnectionBase:ctor()
	self.id = Connections:GetNextConnectionId();
end

-- Sets the NetHandler. Server-only.
function ConnectionBase:SetNetHandler(net_handler)
	self.net_handler = net_handler;
end

-- called when connection is lost
function ConnectionBase:OnConnectionLost(reason)
	self.connectionClosed = true;
	Connections:RemoveConnection(self.nid);
end

-- get ip address. return nil or ip address
function ConnectionBase:GetIPAddress()
	if(not self.ip and self.nid) then
		self.ip = NPL.GetIP(self.nid);
	end
	return self.ip;
end

-- send message immediately to c++ queue
-- @param msg: the raw message table {id=packet_id, .. }. 
-- @param neuronfile: should be nil. By default, it is this file. 
function ConnectionBase:Send(msg, neuronfile)
	local address = self:GetRemoteAddress(neuronfile);
	if(address and not self.connectionClosed) then
		if(NPL.activate(address, msg) ~= 0) then
			LOG.std(nil, "warn", "Connection", "unable to send to %s.", self:GetNid());
			self:OnConnectionLost();
		end
		self.LastSendTime = ParaGlobal.timeGetTime();
	end	
	return true;
end

-- Adds msg to the correct send queue according to data types (chunk data packets go to a separate queue).
function ConnectionBase:AddRawMsgToSendQueue(msg, neuronfile)
	return self:Send(msg, neuronfile);
end

-- send a packet to send queue
function ConnectionBase:AddPacketToSendQueue(packet)
	return packet:Send(self);
end

local ping_msg = {url = "ping",};

-- this function is only called for a client to establish a connection with remote server.
-- on the server side, accepted connections never need to call this function. 
-- @param timeout: the number of seconds to timeout. if 0, it will just ping once. 
-- @param callback_func: a function(bSuccess) end.  If this function is provided, this function is asynchronous. 
function ConnectionBase:Connect(timeout, callback_func)
	if(self.is_connecting) then
		return;
	end
	self.is_connecting = true;
	local address = self:GetRemoteAddress();
	if(not callback_func) then
		-- if no call back function is provided, this function will be synchronous. 
		if( NPL.activate_with_timeout(timeout or 1, address, ping_msg) ~=0 ) then
			self.is_connecting = nil;
			LOG.std("", "warn", "Connection", "failed to connect to server %s", self:GetNid());
		else
			self.is_connecting = nil;
			LOG.std("", "warn", "Connection", "connection with %s is established", self:GetNid());	
			return 0;
		end
	else
		-- if call back function is provided, we will do asynchronous connect. 
		local intervals = {100, 300,500, 1000, 1000, 1000, 1000}; -- intervals to try
		local try_count = 0;
		local callback_func = callback_func;
		
		local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			try_count = try_count + 1;
			if(NPL.activate(address, ping_msg) ~=0) then
				if(intervals[try_count]) then
					timer:Change(intervals[try_count], nil);
				else
					-- timed out. 
					self.is_connecting = nil;
					callback_func(false);
					self:OnError("ConnectionNotEstablished");
				end	
			else
				-- connected 
				self.is_connecting = nil;
				callback_func(true)
			end
		end})
		mytimer:Change(10, nil);
		return 0;
	end
end

-- Checks timeouts and processes all pending read packets.
function ConnectionBase:ProcessReadPackets()
end

-- get the virtual nid(address) of the remote endpoint
function ConnectionBase:GetNid()
	return self.nid;
end

-- this function is called, whenever nid, or default neuron file is changed. 
function ConnectionBase:UpdateCache()
	self.npl_addr_prefix = string.format("(%s)%s:", self.thread or "gl", self.nid or "");
	self.default_address = self.npl_addr_prefix..(self.default_neuron_file or "");
end

-- set nid of the remote endpoint. 
function ConnectionBase:SetNid(nid)
	if(self.nid) then
		Connections:RemoveConnection(self.nid);
	end
	self.nid = nid;
	Connections:AddConnection(nid, self);
	self:UpdateCache();
end

-- default file to which all messages will be sent. 
function ConnectionBase:SetDefaultNeuronFile(filename)
	self.default_neuron_file = filename;
	self:UpdateCache();
end

-- get remote address to which we will send message
-- @param neuronfile: if nil, a default one will be used. 
function ConnectionBase:GetRemoteAddress(neuronfile)
	if(not neuronfile) then
		return self.default_address;
	else
		return self.npl_addr_prefix..neuronfile;
	end
end

function ConnectionBase:SetRemoteAddress()
	
end

-- Shuts down the connection on the server side. 
function ConnectionBase:ServerShutdown()
	self:CloseConnection();
end

-- Shuts down the network with the specified reason. 
function ConnectionBase:NetworkShutdown(reason)
	self:CloseConnection();
end

function ConnectionBase:CloseConnection()
	if(self.nid) then
		NPL.reject(self.nid);
		self.connectionClosed = true;
	end
end

-- inform the netServerHandler about an error.
-- @param text: this is usually "OnConnectionLost" from ServerListener. or "ConnectionNotEstablished" from client
function ConnectionBase:OnError(text)
	if(self.net_handler and self.net_handler.handleErrorMessage) then
		self.net_handler:handleErrorMessage(text);
	end
end

function ConnectionBase:OnNetReceive(msg)
	local packet = Packet_Types:GetNewPacket(msg.id);
	if(packet) then
		packet:ReadPacket(msg);
		packet:ProcessPacket(self.net_handler);
	else
		self.net_handler:handleMsg(msg);
	end
end

local function activate()
	local msg = msg;
	local id = msg.nid or msg.tid;

	if(id) then
		local connection = Connections:GetConnection(id);
		if(connection) then
			connection:OnNetReceive(msg);
		elseif(msg.tid) then
			-- this is an incoming connection. let the server listener to handle it. 
			ServerListener:OnAcceptIncomingConnection(msg);
		end
	end
end
NPL.this(activate);