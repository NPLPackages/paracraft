local LobbyTunnelMessageType = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyTunnelMessageType");

--[[
	{
		type = LobbyTunnelMessageType.RequestLogin;
		name = "keepworkUsername";
		pId = projectId;
		room = "room_key" or nil;
		psw = "123456" or nil;
	}
]]
LobbyTunnelMessageType.RequestLogin 			= 1;

--[[
	{
		type = LobbyTunnelMessageType.ResponseLogin;
		success = true/false;
		room = "room_key" or nil;
		errDesc = "room is full" or other or nil;
		token = "token";
		udpport = 8099;
	}
]]

LobbyTunnelMessageType.ResponseLogin			= 2;

--[[
	{
		type = LobbyTunnelMessageType.BroadcastMessage;
		data = {};
	};
]]
LobbyTunnelMessageType.BroadcastMessage			= 3;

--[[
	{
		type = LobbyTunnelMessageType.SendMessage;
		dst = "keepworkUsername";
		data = {};
	};
]]
LobbyTunnelMessageType.SendMessage				= 4;

--[[
	{
		type = LobbyTunnelMessageType.ResponseMessage;
		src = "keepworkUsername";
		data = {};
	};
]]
LobbyTunnelMessageType.ResponseMessage			= 5;


--[[
	{
		type = LobbyTunnelMessageType.RequestUDPLogin;
		name = "keepworkUsername";
		token = "token";
	};
]]
LobbyTunnelMessageType.RequestUDPLogin			= 6;

--[[
	{
		type = LobbyTunnelMessageType.ResponseUDPLogin;
		success = true/false;
	}
]]
LobbyTunnelMessageType.ResponseUDPLogin			= 7;

--[[
	type = LobbyTunnelMessageType.SendUDPMessage;
	dst = "keepworkUsername";
	data = {};
]]
LobbyTunnelMessageType.SendUDPMessage			= 8;

--[[
	{
		type = LobbyTunnelMessageType.BroadcastUDPMessage;
		data = {};
	};
]]
LobbyTunnelMessageType.BroadcastUDPMessage		= 9;

--[[
	{
		type = LobbyTunnelMessageType.ResponseUDPMessage;
		src = "keepworkUsername";
		data = {};
	};
]]
LobbyTunnelMessageType.ResponseUDPMessage		= 10;


--[[
	{
		type = LobbyTunnelMessageType.ClientDisconnect;
		src = "keepworkUsername";
	}
]]
LobbyTunnelMessageType.ClientDisconnect			= 11;

--[[
	{
		type = LobbyTunnelMessageType.RequestUDPLogin;
		name = "keepworkUsername";
		token = "token";
	}
]]
LobbyTunnelMessageType.RequestUDPLogin			= 12;

--[[
	{
		type = LobbyTunnelMessageType.ResponseUDPLogin;
		success = true/false;
	}
]]
LobbyTunnelMessageType.ResponseUDPLogin 		= 13;

