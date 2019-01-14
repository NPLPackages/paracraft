--[[
Title: LobbyTunnelServer


use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/LobbyTunnelServer.lua");
local LobbyTunnelServer = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyTunnelServer");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/LobbyRoomInfo.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/LobbyTunnelMessageType.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/LobbyClientInfo.lua");

local LobbyRoomInfo = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyRoomInfo");
local LobbyTunnelMessageType = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyTunnelMessageType");
local LobbyClientInfo = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyClientInfo")

local LobbyTunnelServer = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Network.LobbyTunnelServer"));


local callbacks;

local g_instance;
function LobbyTunnelServer.GetSingleton()
	if(g_instance) then
		return g_instance;
	else
		g_instance = LobbyTunnelServer:new();
		return g_instance;
	end
end

function LobbyTunnelServer:ctor()
	-- non full and unlock rooms 
	self._rooms = {};
	-- non full and lock rooms
	self._lock_rooms = {};
	-- full rooms
	self._fullrooms = {};
	--
	self._clients = {};
	--
	self._tcp_nid_to_name = {};
	--
	self._udp_nid_to_name = {};
	
	self.InitCallback()
end


function LobbyTunnelServer:Start()
	self:Log("lobby tunnel server is started")

	local att = NPL.GetAttributeObject()
	self._udp_port = att:GetField("UDPHostPort");
	
	ParaScene.RegisterEvent("_n_paracraft_lobby_tunnel_server", ";_OnLobbyTunnelServerNetworkEvent();");
end

function LobbyTunnelServer:onNetworkEvent(msg)
	if msg.code == NPLReturnCode.NPL_ConnectionDisconnected then
		self:onDisconnected(msg.nid or msg.tid);
	end
end

function _OnLobbyTunnelServerNetworkEvent()
	LobbyTunnelServer.GetSingleton():onNetworkEvent(msg);
end


function LobbyTunnelServer:Log(text, ...)
	LOG.std(nil, "info", "LobbyTunnelServer", text, ...);
end

function LobbyTunnelServer:GetNotFullRoom(room_key)
	return self._rooms[room_key];
end

function LobbyTunnelServer.GetLockRoom(room_key)
	return self._lock_rooms[room_key];
end

function LobbyTunnelServer:GetFullRoom(room_key)
	return self._fullrooms[room_key];
end

function LobbyTunnelServer:SetRoomFull(room_key, bFull)
	if bFull then
		local room = self._rooms[room_key];
		if room then
			self._rooms[room_key] = nil;
			self._fullrooms[room_key] = room;
			return ;
		end
		
		room = self._lock_rooms[room_key];
		if room then
			self._lock_rooms[room_key] = nil;
			self._fullrooms[room_key] = room;
		end
	else
		local room = self._fullrooms[room_key];
		if room then
			self._fullrooms[room_key] = nil;
			if room:hasPassword() then
				self._lock_rooms[room_key] = room;
			else
				self._rooms[room_key] = room;
			end
		end
	end
end

function LobbyTunnelServer:_CreateRoom(room_key, password)
	self:Log("create a new room key = %s, password = %s", tostring(room_key), tostring(password));

	local room = LobbyRoomInfo:new():Init(room_key, password);
	
	room_key = room_key or room:GetRoomKey();
	
	if room:hasPassword() then
		self._lock_rooms[room_key] = room;
	else
		self._rooms[room_key] = room;
	end
	return room;
end

function LobbyTunnelServer.GetClientAddress(nid)
	return format("%s:%s", nid, "script/apps/Aries/Creator/Game/Network/TunnelService/LobbyTunnelClient.lua");
end

function LobbyTunnelServer:onUnknown(msg)
	self:Log("unknown msg type : %s", tostring(msg_type));
	
	local nid = msg.nid or msg.tid;
	
	if msg.isUDP then
		self:RemoveClient(self:getTCPNidByUDPNid(nid));
	else
		NPL.reject(nid);
		self:RemoveClient(nid);
	end
end

function LobbyTunnelServer:getNameByTCPNid(tcp_nid)
	return self._tcp_nid_to_name[tcp_nid];
end

function LobbyTunnelServer:getNameByUDPNid(udp_nid)
	return self._udp_nid_to_name[udp_nid];
end


function LobbyTunnelServer:getClientByTCPNid(tcp_nid)
	local name = self:getNameByTCPNid(tcp_nid);
	if name then
		return self._clients[name];
	else
		return nil;
	end
end


function LobbyTunnelServer:getClientByUDPNid(udp_nid)
	local name = self:getNameByUDPNid(udp_nid);
	if name then
		return self._clients[name];
	else
		return nil;
	end
end


function LobbyTunnelServer:RemoveClient(tcp_nid)
	if not tcp_nid then
		return;
	end

	local client = self:getClientByTCPNid(tcp_nid);
	if client then
		local name = client:getName();
		self._clients[name] = nil;
		self._tcp_nid_to_name[tcp_nid] = nil;
		
		local udp_nid = client:getUDPNid();
		if udp_nid then
			self._udp_nid_to_name[udp_nid] = nil;
		end
		
		local room = client:getRoom();
		room:RemoveClient(name);
		
		local connects = client:getConnects();
		
		local data =
		{
			type = LobbyTunnelMessageType.ClientDisconnect;
			src = name;
		};
		
		local dest_addr;
		for k, connect_client in pairs(connects) do
			connect_client:disconnectClient(client);
			
			dest_addr = self.GetClientAddress(connect_client:getTCPNid());
			NPL.activate(dest_addr, data);
		end
		
		self:SetRoomFull(room:GetRoomKey(), room:isFull());
	end
end

function LobbyTunnelServer:onDisconnected(tcp_nid)
	self:RemoveClient(tcp_nid);
end


function LobbyTunnelServer.AddUDPAddress(ip, port)

	local nid = "~udp" .. ip .. "_" .. port;
	NPL.AddNPLRuntimeAddress({
		host = ip,
		port = port,
		nid = nid,
		isUDP = true,
	});
	
	return nid;
end

function LobbyTunnelServer:onRequestLogin(msg)

	local room_key = msg.room;
	local nid = msg.nid or msg.tid;
	local keepworkUsername = msg.name;
	local password = msg.psw;
	local udpport = msg.udpport;
	local room;
	
	
	if not keepworkUsername then
		NPL.reject(nid);
		return;
	end
	
	if self._clients[keepworkUsername] then
		-- already login
		self:Log("%s already login", keepworkUsername);
		return;
	end
	
	local dest_addr = self.GetClientAddress(nid);
	
	local function jionRoom()
		local client = LobbyClientInfo:new():init(keepworkUsername, nid, room, false)
		room:AddClient(keepworkUsername, client);
		
			
		self._clients[keepworkUsername] = client;
		self._tcp_nid_to_name[nid] = keepworkUsername;
		
		local ip = NPL.GetIP(nid);
		local udp_nid = self.AddUDPAddress(ip, tostring(udpport));
		client:setUDPNid(udp_nid);
		self._udp_nid_to_name[udp_nid] = keepworkUsername;
		
		
		NPL.activate(dest_addr, {
				type = LobbyTunnelMessageType.ResponseLogin;
				success = true;
				room = room_key;
				token = client:getToken();
				udpport = self._udp_port;
			});
				
		if room:isFull() then
			self:SetRoomFull(room_key, true);
		end
	end
	
	local function jionFaild(desc)
		-- 
		NPL.activate(dest_addr, {
				type = LobbyTunnelMessageType.ResponseLogin;
				success = false;
				errDesc = desc;
				});
		NPL.reject(nid);
	end

	if room_key then
		room = self:GetNotFullRoom(room_key);
		
		if room then
			-- jion unlock room
			jionRoom();
		else
			room = self:GetFullRoom(room_key);
			if room then
				-- room is full
				jionFaild("room is full");
			else
				room = self:GetLockRoom(room_key);
				if room then
					-- jion lock room
					if room:canJoin(password) then
						jionRoom();
					else
						-- 
						jionFaild("incorrect password");
					end
				else
					-- create a new room and jion
					room = self:_CreateRoom(room_key, password);
					jionRoom();
				end
			end
		end
	else
		-- join any not full room
		room_key, room = next(self._rooms);
		if room and room_key then
			jionRoom();
		else
			-- create new room and jion
			room = self:_CreateRoom();
			room_key = room:GetRoomKey();
			jionRoom();
		end
	end
end

function LobbyTunnelServer:onBroadcastMessage(msg)
	local nid = msg.nid or msg.tid;
	
	local src_client = self:getClientByTCPNid(nid);
	if not src_client then
		self:Log("onBroadcastMessage: user is not login, nid = %s", tostring(nid));
		return;
	end
	
	local room = src_client:getRoom();
	local clients = room:GetClients();
	
	local data = 
	{
		type = LobbyTunnelMessageType.ResponseMessage;
		src = src_client:getName();
		data = msg.data;
	};
	
	local dest_nid;
	local dest_addr;
	for k, dest_client in pairs(clients) do
		if dest_client ~= src_client then
			dest_nid = dest_client:getTCPNid();
			dest_addr = self.GetClientAddress(dest_nid);
			NPL.activate(dest_addr, data);
		end
	end
	
end

function LobbyTunnelServer:onSendMessage(msg)
	local dest_name = msg.dst;
	local nid = msg.nid or msg.tid;

	local src_client = self:getClientByTCPNid(nid);
	if not src_client then
		self:Log("onSendMessage: user is not login, nid = %s", tostring(nid));
		return;
	end
	
	local room = src_client:getRoom();
	local dest_client = room:GetClient(dest_name);
	
	if not dest_client then
		self:Log("onSendMessage: can not found dest client.  dest_name = %s", tostring(dest_name));
		return;
	end
	
	local dest_nid = dest_client:getTCPNid();
	local dest_addr = self.GetClientAddress(dest_nid);
	
	self:ConnectClients(src_client, dest_client);
	
	NPL.activate(dest_addr, {
			type = LobbyTunnelMessageType.ResponseMessage;
			src = src_client:getName();
			data = msg.data;
		});
end

function LobbyTunnelServer:onSendUDPMessage()
	local dest_name = msg.dst;
	local nid = msg.nid or msg.tid;
	
	local src_client = self:getClientByUDPNid(nid);
	
	if not src_client then
		self:Log("onSendUDPMessage: user is not login, nid = %s", tostring(nid));
		return;
	end
	
	local room = src_client:getRoom();
	local dest_client = room:GetClient(dest_name);
	
	if not dest_client then
		self:Log("onSendUDPMessage: can not found dest client.  dest_name = %s", tostring(dest_name));
		return;
	end
	
	local dest_nid = dest_client:getUDPNid();
	local dest_addr = self.GetClientAddress(dest_nid);
	
	NPL.activate(dest_addr, {
			type = LobbyTunnelMessageType.ResponseUDPMessage;
			src = src_client:getName();
			data = msg.data;
		}, 1, 2, 0);
end

function LobbyTunnelServer:onBroadcastUDPMessage()

	local nid = msg.nid or msg.tid;
	
	local src_client = self:getClientByUDPNid(nid);
	if not src_client then
		self:Log("onBroadcastUDPMessage: user is not login, nid = %s", tostring(nid));
		return;
	end
	
	local room = src_client:getRoom();
	local clients = room:GetClients();
	
	local data = 
	{
		type = LobbyTunnelMessageType.ResponseUDPMessage;
		src = src_client:getName();
		data = msg.data;
	};
	
	local dest_nid;
	local dest_addr;
	for k, dest_client in pairs(clients) do
		if dest_client ~= src_client then
			dest_nid = dest_client:getUDPNid();
			
			dest_addr = self.GetClientAddress(dest_nid);
			NPL.activate(dest_addr, data, 1, 2, 0);
		end
	end
end
 

function LobbyTunnelServer:ConnectClients(client1, client2)
	client1:connectClient(client2);
	client2:connectClient(client1);
end


function LobbyTunnelServer.InitCallback()
	if not callbacks then
		callbacks = {};
		
		callbacks[LobbyTunnelMessageType.RequestLogin] = LobbyTunnelServer.onRequestLogin;
		callbacks[LobbyTunnelMessageType.BroadcastMessage] = LobbyTunnelServer.onBroadcastMessage;
		callbacks[LobbyTunnelMessageType.SendMessage] = LobbyTunnelServer.onSendMessage;
		callbacks[LobbyTunnelMessageType.SendUDPMessage] = LobbyTunnelServer.onSendUDPMessage;
		callbacks[LobbyTunnelMessageType.BroadcastUDPMessage] = LobbyTunnelServer.onBroadcastUDPMessage;
		--callbacks[LobbyTunnelMessageType.RequestUDPLogin] = LobbyTunnelServer.onRequestUDPLogin;
	end
end

function LobbyTunnelServer:handleReceive(msg)
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

local function activate()
	if(g_instance) then
		g_instance:handleReceive(msg)
	end
end
NPL.this(activate);