--[[
Title: ServerManager
Author(s): LiXizhi
Date: 2014/6/25
Desc: all server-side player connections are managed here. It also manages all WorldServers, and player access control. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ServerManager.lua");
local ServerManager = commonlib.gettable("MyCompany.Aries.Game.Network.ServerManager");
ServerManager.GetSingleton():Tick();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ServerListener.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Config/BanList.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetServerHandler.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/WorldServer.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/GameMode.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ChatMessage.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local ChatMessage = commonlib.gettable("MyCompany.Aries.Game.Network.ChatMessage");
local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");
local WorldServer = commonlib.gettable("MyCompany.Aries.Game.Network.WorldServer");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local NetServerHandler = commonlib.gettable("MyCompany.Aries.Game.Network.NetServerHandler");
local BanList = commonlib.gettable("MyCompany.Aries.Game.Network.BanList");
local ServerListener = commonlib.gettable("MyCompany.Aries.Game.Network.ServerListener");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local ServerManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Network.ServerManager"));

-- The maximum number of players that can be connected at a time.
ServerManager:Property({"max_players", 40, "GetMaxPlayerCount", "SetMaxPlayerCount", auto=true})
ServerManager:Property({"view_distance", 200, "GetViewDistance", "SetViewDistance", auto=true})
-- coult be "Anonymous", "UniversalPassword", "WhiteList"
ServerManager:Property({"BasicAuthMethod", "Anonymous", "GetBasicAuthMethod", "SetBasicAuthMethod", auto=true})
ServerManager:Property({"UniversalPassword", "", "GetUniversalPassword", "SetUniversalPassword", auto=true})
-- True if all players are allowed to use commands (cheats).
ServerManager:Property({"commandsAllowedForAll", false, "IsCommandsAllowedForAll", "SetCommandsAllowedForAll", auto=true})
-- run at 20 fps
ServerManager:Property({"tick_rate", 1000/20, "GetTickRate", "SetTickRate", auto=true})

function ServerManager:ctor()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Config/PasswordList.lua");
	local PasswordList = commonlib.gettable("MyCompany.Aries.Game.Network.PasswordList");
	self.passwordList = PasswordList:new():Init();
	self.bannedPlayers = BanList:new():Init("banned-players.txt");
    self.bannedIPs = BanList:new():Init("banned-ips.txt");
	-- A list of player entities that exist on this server.
	self.playerEntityList = commonlib.UnorderedArraySet:new();
	-- mapping from name to white listed players
	self.whiteListedPlayers = {};
	self.whiteListEnforced = false;
	-- mapping from lowered cased administrator names to true. 
	self.administrators = {};
	-- current game mode
	self.game_mode = GameMode:new();
	-- index into playerEntities of player to ping, updated every tick;
	self.playerPingIndex = 1;
	self.curHost = '';
	self.curPort = 8099;
end

local g_instance;
function ServerManager.GetSingleton()
	if(g_instance) then
		return g_instance;
	else
		g_instance = ServerManager:new();
		return g_instance;
	end
end

-- get the gamemode object
function ServerManager:GameMode()
	return self.game_mode;	
end

function ServerManager:CreateWorldServer(worldpath)
	worldpath = worldpath or "worlds/multiplayer";
	self.worlds = self.worlds or {};
	local worldserver = WorldServer:new():Init(host, worldpath, self, WorldCommon.GetSaveWorldHandler());
	GameLogic.ReplaceWorld(worldserver);
	self.worlds[1] = worldserver;
	self.playerSaveHandler = worldserver:GetSaveHandler():GetPlayerSaveHandler();

	worldserver:CreateAdminPlayer();
end

function ServerManager:Init(host, port, username, tunnelClient)

	self:CreateWorldServer();

    if(not tunnelClient) then
		port = port or 8099;
	    host = tostring(host or "0.0.0.0");
		
		self:LoadNetworkSettings();
		local att = NPL.GetAttributeObject();
		
		local i = 0;
		while NPL.Ping("127.0.0.1", tostring(port + i), 1000, true) ~= -1 and i <= 20 do
			i = i + 1;
		end

        NPL.StartNetServer(host, tostring(port + i));
		self.curHost = host;
		self.curPort = port + i;
		LOG.std(nil, "Network", "ServerManager", "TCP listening on %s:%s", att:GetField("HostIP"), att:GetField("HostPort"));
    end
	local Connections = commonlib.gettable("MyCompany.Aries.Game.Network.Connections");
	Connections:Init();

	self.servertimer = self.servertimer or commonlib.Timer:new({callbackFunc = function(timer)
		self:Tick();
	end})
	self.servertimer:Change(ServerManager.tick_rate, ServerManager.tick_rate);
	self.isStarted = true;

	local event = System.Core.Event:new():init("ps_server_started")
  	event.msg = {username = "admin", entityId = EntityManager.GetPlayer().entityId, displayname=EntityManager.GetPlayer():GetDisplayName(), isServer = true};
  	GameLogic:event(event);
	return self;
end

function ServerManager:LoadNetworkSettings()
	local att = NPL.GetAttributeObject();
	att:SetField("TCPKeepAlive", true);
	att:SetField("KeepAlive", false);
	att:SetField("IdleTimeout", false);
	att:SetField("IdleTimeoutPeriod", 1200000);
	NPL.SetUseCompression(true, true);
	att:SetField("CompressionLevel", -1);
	att:SetField("CompressionThreshold", 1024*16);
	
	att:SetField("UDPIdleTimeoutPeriod", 1200000);
	att:SetField("UDPCompressionLevel", -1);
	att:SetField("UDPCompressionThreshold", 1024*16);
	-- npl message queue size is set to really large
	__rts__:SetMsgQueueSize(5000);
end

function ServerManager:IsStarted()
	return self.isStarted;
end

-- @param nIndex: default to 1
function ServerManager:GetWorldServerForDimension(nIndex)
	return self.worlds[nIndex or 1];
end

function ServerManager:Cleanup()
	self.playerEntityList:clear();
	self.worlds = {};
	if(self.servertimer) then
		self.servertimer:Change();
	end
end

function ServerManager:Shutdown()
	local listPlayer = self.playerEntityList:clone()
	for i, entityPlayer in ipairs(listPlayer) do
		local netHandler = entityPlayer:GetServerHandler();
		if(netHandler) then
			netHandler:KickPlayerFromServer("server shutdown");
		end
    end
	self.playerEntityList:clear();
	self:Cleanup();
	self.isStarted = nil;

	local event = System.Core.Event:new():init("ps_server_shutdown")
  	event.msg = {username = "host", isServer = true};
  	GameLogic:event(event);
end

function ServerManager:TickServerWorlds()
	local removed_worlds;
	for name, world in pairs(self.worlds) do
		if(world:IsRemoved()) then
			removed_worlds = removed_worlds or {}
			removed_worlds[name] = world;
		else
			world:Tick();
		end
	end

	if(removed_worlds) then
		for name, world in pairs(removed_worlds) do
			world:Destroy();
		end
	end

	-- send all other player's info to the new player
	for i = 1, #(self.playerEntityList) do
		local entityPlayer = self.playerEntityList[i];
		if(entityPlayer) then
			local netHandler = entityPlayer:GetServerHandler();
			if(netHandler) then
				netHandler:NetworkTick();
			end
		end
    end
end

-- this function is called periodically. 
function ServerManager:Tick()
	ServerListener:ProcessPendingConnections();
	self:TickServerWorlds();
end

function ServerManager:GetBannedIPs()
    return self.bannedIPs;
end

-- This adds a username to the admin list, then saves the op list
function ServerManager:AddAdmin(username)
    self.administrators[string.lower(username)] = true;
end

-- This removes a username from the admin list, then saves the op list
function ServerManager:RemoveAdmin(username)
    self.administrators[string.lower(username)] = nil;
end

-- Determine if the player is allowed to connect based on current server settings.
function ServerManager:IsAllowedToLogin(name)
	name = string.lower(name);
	return not self.whiteListEnforced or self.administrators[name] or self.whiteListedPlayers[par1Str];
end

-- checks ban-lists, then white-lists, then space for the server. 
-- Returns nil on success, or an error message
function ServerManager:IsUserAllowedToConnect(ip, username)
	if (self.bannedPlayers:isBanned(username)) then
		return "You are banned from this server!";
	elseif(not self:IsAllowedToLogin(username)) then
		return "You are not white-listed on this server!";
	else
		if (self.bannedIPs:isBanned(ip)) then
			return "Your IP address is banned from this server"
		else
			if(#(self.playerEntityList) >= self.max_players) then
				return "The server is full!"
			end
		end
	end
end

-- called during player login. reads the player information from disk.
function ServerManager:ReadPlayerDataFromFile(entityMP)
	
	local world_info = self:GetWorldServerForDimension(1):GetWorldInfo();
	local player_node = self:GetWorldServerForDimension(1):GetWorldInfo():GetPlayerXmlNode();
    local data_node;

    if (entityMP:GetUserName() == world_info:GetOwnerNid() and player_node) then
        entityMP:LoadFromXMLNode(player_node);
        data_node = player_node;
        LOG.std(nil, "info", "ServerManager", "the owner player %s is logged in", world_info:GetOwnerNid());
    else
        data_node = self.playerSaveHandler:ReadPlayerData(entityMP);
    end

	return data_node;
end

-- also checks for multiple logins
-- @return server side player entity
function ServerManager:CreatePlayerForUser(username)
	local duplicated_users;
	local username_lower_cased = string.lower(username);
	for i=1, #(self.playerEntityList) do
		local entity = self.playerEntityList[i];
		if (string.lower(entity:GetUserName() or "") == username_lower_cased) then
			duplicated_users = duplicated_users or {};
			duplicated_users[#duplicated_users+1] = entity;
		end
    end

	if(duplicated_users) then
		for i=1, #(duplicated_users) do
			local entity = duplicated_users[i];
			entity:KickPlayerFromServer("You logged in from another location");
		end
	end
    
	local world = self:GetWorldServerForDimension(1);
	if(world) then
		local player = EntityManager.EntityPlayerMP:new():init(username, world);
		if(player) then
			self.playerEntityList:add(player);
			return player;
		end
	end
end

-- initialize connection and handler for the given player. 
function ServerManager:InitializeConnectionToPlayer(playerConnection, entityMP)
	
	-- TODO: send messages to client for login.
	local worldserver = self:GetWorldServerForDimension(entityMP.dimension);

	local player_data = self:ReadPlayerDataFromFile(entityMP);
    entityMP:SetWorld(worldserver);
    local ip_address = playerConnection:GetIPAddress();
	LOG.std(nil, "info", "ServerManager", "%s [%s] logged in with entity id %d at (%d, %d, %d)", entityMP:GetUserName(), ip_address, entityMP.entityId, entityMP.x, entityMP.y, entityMP.z);
    
    local born_x, born_y, born_z = worldserver:GetSpawnPoint();
    local net_handler = NetServerHandler:new():Init(playerConnection, entityMP, self);

	net_handler:SendPacketToPlayer(Packets.PacketSpawnPosition:new():Init(born_x, born_y, born_z));
    net_handler:SendPacketToPlayer(Packets.PacketLogin:new():Init(entityMP.entityId, worldserver:GetWorldInfo():GetTerrainType(), self:GetMaxPlayers()));
    self:SendChatMsg(ChatMessage:new():Init("multiplayer.player.joined", {entityMP:GetDisplayName()}));
    self:PlayerLoggedIn(entityMP);
    net_handler:SetPlayerLocation(entityMP.x, entityMP.y, entityMP.z, entityMP.facing, entityMP.rotationPitch);
    net_handler:SendPacketToPlayer(Packets.PacketUpdateTime:new():Init(worldserver:GetTotalWorldTime(), worldserver:GetWorldTime()));

    if (worldserver:GetWorldInfo():GetTexturePack() ~= "") then
        entityMP:RequestTexturePackLoad(worldserver:GetWorldInfo():GetTexturePack());
    end

    if (player_data and player_data.attr and player_data.attr.isRiding) then
        -- TODO: create and mount on the entity. 
    end
end

function ServerManager:GetEntityViewDistance()
	return 100;
end

-- Sends the given string to every player as chat message.
-- @param chatmsg: ChatMessage or string. 
function ServerManager:SendChatMsg(chatmsg, chatdata)
	if(type(chatmsg) ~= "table") then
		chatmsg = ChatMessage:new():SetText(tostring(chatmsg), chatdata);
	end

	if(chatmsg:isa(ChatMessage)) then
		-- TODO: send message
		self:SendPacketToAllPlayers(Packets.PacketChat:new():Init(chatmsg));
	end
end

function ServerManager:GetViewDistance()
	return self.view_distance;
end

-- Writes player data to disk
function ServerManager:WritePlayerData(entityMP)
	-- TODO:
end

function ServerManager:GetMaxPlayers()
	return self.max_players;
end

-- sends a packet to all players
function ServerManager:SendPacketToAllPlayers(packet)
	for i =1, #(self.playerEntityList) do
		local entityPlayer = self.playerEntityList[i];
        entityPlayer:SendPacketToPlayer(packet);
    end
end

-- sends a packet to all players except the given one
function ServerManager:SendPacketToAllPlayersExcept(packet, excludedPlayer)
	for i =1, #(self.playerEntityList) do
		local entityPlayer = self.playerEntityList[i];
		if(entityPlayer ~= excludedPlayer) then
			entityPlayer:SendPacketToPlayer(packet);
		end
    end
end

-- @param bUpdate: true to update
function ServerManager:GetStats(bUpdate)
	self.stats = self.stats or {};
	local stats = self.stats;
	if(bUpdate) then
		stats[1] = {totalPlayers = #(self.playerEntityList)};
		local names = {};
		for i =1, #(self.playerEntityList) do
			local entityPlayer = self.playerEntityList[i];
			if(entityPlayer.GetUserName) then
				names[#names+1] = entityPlayer:GetUserName() or "noname";
			end
		end
		stats[2] = {playerNames = names};
	end
	return self.stats;
end

-- Called when a player successfully logs in. Reads player data from disk and inserts the player into the world.
function ServerManager:PlayerLoggedIn(entityMP)
	-- send new player info to all other players
    self:SendPacketToAllPlayers(Packets.PacketPlayerInfo:new():Init(entityMP:GetUserName(), true, 1000));
    self.playerEntityList:add(entityMP);
    local worldserver = self:GetWorldServerForDimension(entityMP.dimension);
    worldserver:SpawnEntityInWorld(entityMP);
    
	-- send all other player's info to the new player
	for i =1, #(self.playerEntityList) do
		local entityPlayer = self.playerEntityList[i];
        entityMP:SendPacketToPlayer(Packets.PacketPlayerInfo:new():Init(entityPlayer:GetUserName(), true, entityPlayer.ping));
    end

	local event = System.Core.Event:new():init("ps_user_joined")
  	event.msg = {username = entityMP:GetUserName(), entityId=entityMP.entityId, displayname=entityMP:GetDisplayName(), isServer = true};
  	GameLogic:event(event);
end

-- Called when a player disconnects from the game. Writes player data to disk and removes them from the world.
function ServerManager:PlayerLoggedOut(entityMP)
	local event = System.Core.Event:new():init("ps_user_left")
  	event.msg = {username = entityMP:GetUserName(), entityId=entityMP.entityId, isServer = true};
  	GameLogic:event(event);

    self:WritePlayerData(entityMP);
    local worldserver = entityMP:GetWorldServer();

    if (entityMP.ridingEntity) then
        -- worldserver:RemovePlayerEntityDangerously(entityMP.ridingEntity);
		entityMP:MountEntity(nil);
    end

    worldserver:RemoveEntity(entityMP);
    worldserver:GetPlayerManager():RemovePlayer(entityMP);
    self.playerEntityList:removeByValue(entityMP);
    self:SendPacketToAllPlayers(Packets.PacketPlayerInfo:new():Init(entityMP:GetUserName(), false, 9999));
end

function ServerManager:VerifyUserNamePassword(username, password)
	local method = self:GetBasicAuthMethod();
	if(method == "Anonymous") then
		return true;
	elseif(method == "UniversalPassword") then
		return password == self:GetUniversalPassword();
	elseif(method == "WhiteList") then
		if(self.passwordList:IsEmpty()) then
			return true;
		else
			return self.passwordList:CheckUser(username, password);
		end
	end
end