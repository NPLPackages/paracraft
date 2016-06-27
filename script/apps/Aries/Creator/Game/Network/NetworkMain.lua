--[[
Title: NetworkMain
Author(s): LiXizhi
Date: 2014/6/4
Desc: A singleton server main class
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetworkMain.lua");
local NetworkMain = commonlib.gettable("MyCompany.Aries.Game.Network.NetworkMain");
NetworkMain:StartServer(host, port);
NetworkMain:Connect(ip, port, username, password);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/WorldClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ServerManager.lua");
local ServerManager = commonlib.gettable("MyCompany.Aries.Game.Network.ServerManager");
local WorldClient = commonlib.gettable("MyCompany.Aries.Game.Network.WorldClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local NetworkMain = commonlib.gettable("MyCompany.Aries.Game.Network.NetworkMain");

local clients = {};

-- restart the server on ip:port for the currently loaded world
-- @param host: default to "0.0.0.0" which is listening all local ips
-- @param port: default to "8099". if port is "0", we will not listen for incoming connection
function NetworkMain:StartServer(host, port)
	if(self:IsServerStarted()) then
		return;
	end
	LOG.std(nil, "info", "NetworkMain", "private server (%s:%s) is starting...", host or "", port or "")
	self:InitCommon();
	-- init server manager
	if(self.server_manager) then
		self.server_manager:Shutdown();
	end
	self.server_manager = ServerManager.GetSingleton():Init(host, port);
	return true;
end

-- start server using tunnel service
function NetworkMain:StartServerViaTunnel(host, port, room_key, username, password)
    if(self:IsServerStarted()) then
		return;
	end
	
	LOG.std(nil, "info", "NetworkMain", "private server (%s:%s) is starting via tunnel...", host or "", port or "")
	self:InitCommon();
    
	-- init server manager
	if(self.server_manager) then
		self.server_manager:Shutdown();
	end
	
    
    NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/TunnelClient.lua");
	local TunnelClient = commonlib.gettable("MyCompany.Aries.Game.Network.TunnelClient");

	-- reuse the same connection if possible
	if(not self.tunnelClient) then
		self.tunnelClient = TunnelClient:new();
	end
	-- TODO: "_admin" means the first user in the room
	username = username or "_admin";
	username = self:SanitizeUsername(username);

	-- prepare address
	-- this is a pure client, so do not listen on any port. Just start the network interface. 
	NPL.StartNetServer("127.0.0.1", "0");

	self.tunnelClient:ConnectServer(ip, port, room_key, username, password, function(result)
		if(result) then
			self.tunnelClient:LoginTunnel(function(result)
				if(result) then
					-- start server with the given tunnel client
					self.server_manager = ServerManager.GetSingleton():Init(host, port, username, self.tunnelClient);
				end
			end);
        end
	end)
end

function NetworkMain:GetServerManager()
	return self.server_manager;
end

function NetworkMain:IsServerStarted()
	if(self.server_manager) then
		return self.server_manager:IsStarted();
	end
end

function NetworkMain:InitCommon()
	if(self.inited) then
		return;
	end
	self.inited = true;
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet_Types.lua");
	local Packet_Types = commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet_Types");
	Packet_Types:StaticInit();

	-- NPL.AddPublicFile("script/apps/WebServer/npl_http.lua", -10);
	NPL.AddPublicFile("script/apps/Aries/Creator/Game/Network/ConnectionBase.lua", 201);
	NPL.AddPublicFile("script/apps/Aries/Creator/Game/Network/TunnelService/TunnelClient.lua", 202);
	NPL.AddPublicFile("script/apps/Aries/Creator/Game/Network/TunnelService/TunnelServer.lua", 203);
end

-- start listening on ip and port. 
-- @param filename: config file name, default to "config/private_server.config.xml"
function NetworkMain:StartServerFromConfigFile(filename)
	filename = filename or "config/private_server.config.xml";
	-- TODO: read from config file
	local host = "0.0.0.0";
	local port = "8099"; 
	return self:StartServer(host, port);
end

-- create get the client interface by name address. 
-- @param name: if nil, it is default. 
function NetworkMain:GetClient(name)
	name = name or "default";
	local client = clients[name];
	if(client) then
		return client;
	end
end

function NetworkMain:AddClient(client)
	if(client) then
		clients[client:GetName() or "default"] = client;
	end
end


function NetworkMain:CheckLoadClient()
	if(self:IsServerStarted()) then
		_guihelper.MessageBox(L"你不能同时为客户端和服务器");
		return;
	end
	self:InitCommon();

	-- prepare address
	-- this is a pure client, so do not listen on any port. Just start the network interface. 
	NPL.StartNetServer("127.0.0.1", "0");
	return true;
end

function NetworkMain:SanitizeUsername(username)
	username = username or tostring(ParaGlobal.timeGetTime());
	return username;
end

-- call this function to establish a connection to a given server via tunnel server
function NetworkMain:ConnectViaTunnel(ip, port, room_key, username, password)
	if(not self:CheckLoadClient()) then
		return;
	end

	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/TunnelClient.lua");
	local TunnelClient = commonlib.gettable("MyCompany.Aries.Game.Network.TunnelClient");

	-- reuse the same connection if possible
	if(not self.tunnelClient) then
		self.tunnelClient = TunnelClient:new();
	end
	username = self:SanitizeUsername(username);

	self.tunnelClient:ConnectServer(ip, port, room_key, username, password, function(result)
		if(result) then
			-- connect with the given tunnel client
			self:Connect(ip, port, username, password, self.tunnelClient);
		end
	end)
end

-- call this function to establish a connection to a given server
function NetworkMain:Connect(ip, port, username, password, tunnelClient)
	if(not self:CheckLoadClient()) then
		return;
	end
	username = self:SanitizeUsername(username);

	local client = WorldClient:new():Init("default");
	if(client) then
		client:Login({ip=ip, port=port, username=username, password=password, 
			tunnelClient = tunnelClient});
	end
end

function NetworkMain:Disconnect()
	local client = self:GetClient("default");
	if(client) then
		client:Disconnect();
	end
end

-- stop all servers.
function NetworkMain:Stop()
	self:RunCommand("stop");
end

-- add a world
function NetworkMain:AddWorld(world)
	self.worlds[world.name] = world;
end

-- run a command on all servers. 
function NetworkMain:RunCommand(cmd)
	for name, world in pairs(self.worlds) do
		world:RunCommand(cmd);
	end	
end

function NetworkMain:TickServer()
	if(self.server_manager) then
		self.server_manager:Tick();
	end
end
