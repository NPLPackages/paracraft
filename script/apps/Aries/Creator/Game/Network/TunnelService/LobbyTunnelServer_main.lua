--[[
Title: LobbyTunnelServerMain shell loop file
Author(s): LiXizhi
Date: 2016/3/4
Desc: use this to start a stand alone tunnel server.
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/LobbyTunnelServer_main.lua");
local LobbyTunnelServerMain = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyTunnelServerMain");
LobbyTunnelServerMain:Init();

-- or start locally
LobbyTunnelServerMain:StartServer();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/System.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/LobbyTunnelServer.lua");
NPL.load("(gl)script/apps/WebServer/WebServer.lua");
	

local LobbyTunnelServerMain = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyTunnelServerMain");
local LobbyTunnelServer = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyTunnelServer");

function LobbyTunnelServerMain:Init()
	NPL.AddPublicFile("script/apps/Aries/Creator/Game/Network/TunnelService/LobbyTunnelServer.lua", 402);
	NPL.AddPublicFile("script/apps/Aries/Creator/Game/Network/TunnelService/LobbyTunnelClient.lua", 403);

	self.LoadNetworkSettings();
	-- REMOVE this: start a test server. 
	self:StartServer();
end

function LobbyTunnelServerMain:StartServer()
	-- TODO: start listen on ip and port
	--NPL.StartNetServer("0.0.0.0", "8099");
	WebServer:Start("script/apps/Aries/Creator/Game/Network/TunnelService/Website", "0.0.0.0", 8099);

	local att = NPL.GetAttributeObject();
	att:SetField("EnableUDPServer", 8099);
	
	LobbyTunnelServer.GetSingleton():Start();
end

-- static function
function LobbyTunnelServerMain.LoadNetworkSettings()

	local att = NPL.GetAttributeObject();
	att:SetField("TCPKeepAlive", true);
	att:SetField("KeepAlive", false);
	att:SetField("IdleTimeout", false);
	att:SetField("IdleTimeoutPeriod", 1200000);
	NPL.SetUseCompression(true, true);
	att:SetField("CompressionLevel", -1);
	att:SetField("CompressionThreshold", 1024*16);
	-- npl message queue size is set to really large
	__rts__:SetMsgQueueSize(5000);
end

local main_state;
local function activate()
	if(not main_state) then
		main_state = "inited";
		LobbyTunnelServerMain:Init();
	else
		-- main loop here
	end
end
NPL.this(activate);