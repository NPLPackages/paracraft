--[[
Title: TunnelServerMain shell loop file
Author(s): LiXizhi
Date: 2016/3/4
Desc: use this to start a stand alone tunnel server.
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/TunnelServer_main.lua");
local TunnelServerMain = commonlib.gettable("MyCompany.Aries.Game.Network.TunnelServerMain");
TunnelServerMain:Init();

-- or start locally
TunnelServerMain:StartServer();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/System.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/TunnelServer.lua");
local TunnelServer = commonlib.gettable("MyCompany.Aries.Game.Network.TunnelServer");

local TunnelServerMain = commonlib.gettable("MyCompany.Aries.Game.Network.TunnelServerMain");

-- this is the one time init function. 
-- @param configFile: table of {host, port} or filename, default to TunnelServer.config.xml
function TunnelServerMain:Init(configFile)
	local params;
	if(type(configFile) == "table") then
		params = configFile;
	else
		configFile = configFile or "TunnelServer.config.xml"
		-- TODO: load params from file
	end

	self:LoadNetworkSettings();

	-- TODO: start tunner server in multiple threads as defined in xml file. 
	-- TODO: start listen on ip and port
	NPL.StartNetServer("0.0.0.0", "8099");

	-- REMOVE this: start a test server. 
	self:StartServer();
end

-- static function
function TunnelServerMain:LoadNetworkSettings()
	NPL.AddPublicFile("script/apps/Aries/Creator/Game/Network/TunnelService/TunnelClient.lua", 202);
	NPL.AddPublicFile("script/apps/Aries/Creator/Game/Network/TunnelService/TunnelServer.lua", 203);
	

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


-- start a tunnel server in the current thread
function TunnelServerMain:StartServer()

	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/RoomInfo.lua");
	local RoomInfo = commonlib.gettable("MyCompany.Aries.Game.Network.RoomInfo");
	self.tunnelServer = TunnelServer:new();
	-- TODO REMOVE this: add a test room
	self.tunnelServer:updateInsertRoom(RoomInfo:new():Init("room_test"));
end

local main_state;
local function activate()
	if(not main_state) then
		main_state = "inited";
		TunnelServerMain:Init();
	else
		-- main loop here
	end
end
NPL.this(activate);