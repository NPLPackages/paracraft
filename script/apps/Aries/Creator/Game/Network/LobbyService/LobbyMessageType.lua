--[[
Title: LobbyServer
Author(s): LanZhihong
Date: 2018/12/19
Desc: all LobbyServer
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/LobbyService/LobbyMessageType.lua");
local LobbyMessageType = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyMessageType");
-------------------------------------------------------
]]
local LobbyMessageType = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyMessageType");

--[[
	udp 
	{name = keepworkUsername, projectId = 900, version = 1001, editMode = true/false}
--]]
LobbyMessageType.REQUEST_ECHO			= 1;  

--[[
	udp
	{port = 8099, name = keepworkUsername}
]]
LobbyMessageType.RESPONSE_ECHO			= 2;

--[[
	tcp
	{name = keepworkUsername, nickname = nickname}
]]
LobbyMessageType.REQUEST_CONNECT		= 3;
--[[
	tcp
	{name = keepworkUsername, nickname = nickname}
]]
LobbyMessageType.RESPONSE_CONNECT		= 4;

--[[
	tcp
	{title = "custom title", data = anytype}
]]
LobbyMessageType.USER_DATA				= 5;
--[[
	udp
]]
LobbyMessageType.CUSTOM					= 6;

