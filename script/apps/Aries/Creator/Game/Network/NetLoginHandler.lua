--[[
Title: NetLoginHandler
Author(s): LiXizhi
Date: 2014/6/25
Desc: used by the server to handle client login or any anonymous query before login.
When logged in, the user will transfer ownership of the connection to NetServerHandler. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetLoginHandler.lua");
local NetLoginHandler = commonlib.gettable("MyCompany.Aries.Game.Network.NetLoginHandler");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ConnectionTCP.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetHandler.lua");
local NetworkMain = commonlib.gettable("MyCompany.Aries.Game.Network.NetworkMain");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local ConnectionTCP = commonlib.gettable("MyCompany.Aries.Game.Network.ConnectionTCP");

local NetLoginHandler = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.NetHandler"), commonlib.gettable("MyCompany.Aries.Game.Network.NetLoginHandler"));

function NetLoginHandler:ctor()
	self.isAuthenticated = nil;
end

-- @param tid: this is temporary identifier of the socket connnection
function NetLoginHandler:Init(tid, tunnelClient)
	self.playerConnection = ConnectionTCP:new():Init(tid, nil, self, tunnelClient);
	return self;
end

-- called periodically by ServerListener:ProcessPendingConnections()
function NetLoginHandler:Tick()
	self.loginTimer = (self.loginTimer or 0) + 1;
	if (self.loginTimer >= 600) then
       self:KickUser("take too long to log in");
	end
end

function NetLoginHandler:SendPacketToPlayer(packet)
	return self.playerConnection:AddPacketToSendQueue(packet);
end

-- either succeed or error. 
function NetLoginHandler:IsFinishedProcessing()
	return self.finishedProcessing;
end

function NetLoginHandler:GetServerManager()
	return NetworkMain:GetServerManager();
end

-- transfer connection to NetServerHandler
function NetLoginHandler:InitializePlayerConnection()
	local errorMsg = self:GetServerManager():IsUserAllowedToConnect(self.playerConnection:GetIPAddress(), self.clientUsername);

    if (errorMsg) then
        self:KickUser(errorMsg);
    else
        local playerEntity = self:GetServerManager():CreatePlayerForUser(self.clientUsername);
        if (playerEntity) then
            self:GetServerManager():InitializeConnectionToPlayer(self.playerConnection, playerEntity);
        end
    end
	self.finishedProcessing = true;
end

--  Disconnects the user with the given reason.
function NetLoginHandler:KickUser(reason)
    LOG.std(nil, "info", "NetLoginHandler", "Disconnecting %s, reason: %s", self:GetUsernameAndAddress(), tostring(reason));
    self.playerConnection:AddPacketToSendQueue(Packets.PacketKickDisconnect:new():Init(reason));
    self.playerConnection:ServerShutdown();
    self.finishedProcessing = true;
end

function NetLoginHandler:GetUsernameAndAddress()
	if(self.clientUsername) then
		return format("%s (%s)", self.clientUsername, tostring(self.playerConnection:GetRemoteAddress()));
	else
		return tostring(self.playerConnection:GetRemoteAddress());
	end
end

function NetLoginHandler:SetAuthenticated()
	self.isAuthenticated = true;
end

function NetLoginHandler:IsAuthenticated()
	return self.isAuthenticated;
end

function NetLoginHandler:handleAuthUser(packet_AuthUser)
	self.clientUsername = packet_AuthUser.username;
	self.clientPassword = packet_AuthUser.password;

	NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ServerPage.lua");
	local ServerPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.ServerPage");
	local info = ServerPage.GetServerInfo();

	if(self:GetServerManager():VerifyUserNamePassword(self.clientUsername, self.clientPassword)) then
		-- TODO: do authentication. 
		self:SetAuthenticated();
		if(self:IsAuthenticated()) then
			self:SendPacketToPlayer(Packets.PacketAuthUser:new():Init(self.clientUsername, nil, "ok", info));
		end
	else
		self:SendPacketToPlayer(Packets.PacketAuthUser:new():Init(self.clientUsername, nil, "failed", info));
	end
end

function NetLoginHandler:handleLoginClient(packet_loginclient)
	if(self:IsAuthenticated()) then
		self:InitializePlayerConnection();
		self:InitializeEnvironment();
	end
end

-- one time sync for texture pack, weather condition, etc. 
function NetLoginHandler:InitializeEnvironment()
	local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");
	local texturePack = { 
		type = WorldCommon.GetWorldInfo().texture_pack_type,
		path = WorldCommon.GetWorldInfo().texture_pack_path,
		url = WorldCommon.GetWorldInfo().texture_pack_url,
		text = WorldCommon.GetWorldInfo().texture_pack_text, -- for fuzzy search
	};
	self:SendPacketToPlayer(Packets.PacketUpdateEnv:new():Init(texturePack, nil));
end