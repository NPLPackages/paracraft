--[[
Title: LobbyClient
Author(s): LiXizhi
Date: 2018/12/19
Desc: all LobbyClient
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/LobbyService/LobbyClient.lua");
local LobbyClient = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyClient");
-------------------------------------------------------
]]
local LobbyClient = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Network.LobbyClient"));

LobbyClient:Property({"Connected", false, "IsConnected", "SetConnected", auto=true})

LobbyClient:Signal("server_connected")

local clients = {};

function LobbyClient:ctor()
end

-- @param ip, port: IP address of Lobby server
-- @param room_key: room_key
-- @param username: unique user name
-- @param password: optional password
-- @param callbackFunc: function(bSuccess) end
function LobbyClient:ConnectServer(ip, port, room_key, username, password, callbackFunc)
end

function LobbyClient:Disconnect()
end

-- send message via Lobby server to another Lobby client
-- @param nid: virtual nid of the target sLobby client. usually the user name
-- @param msg: the raw message table {id=packet_id, .. }. 
-- @param neuronfile: should be nil. By default, it is ConnectionBase. 
function LobbyClient:Send(nid, msg, neuronfile)
end

local function activate()
	local msg = msg;
end
NPL.this(activate);