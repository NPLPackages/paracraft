--[[
Title: LobbyClientInfo

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/LobbyClientInfo.lua");
local LobbyClientInfo = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyClientInfo");
local LobbyClientInfo = LobbyClientInfo:new():init()
-------------------------------------------------------
]]
local LobbyClientInfo = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Network.LobbyClientInfo"));

function LobbyClientInfo:ctor()
	self._bAdmin = nil;
	self._tcp_nid = nil;
	self._udp_nid = nil;
	self._keepworkUsername = nil;
	self._token = nil;
	self._room = nil;
	
	-- connect clients
	self._connects = {};
end


function LobbyClientInfo:GenerateToken()
	self._token = ParaGlobal.GenerateUniqueID()
end

function LobbyClientInfo:init(keepworkUsername, tcp_nid, room, bAdmin)
	self._keepworkUsername = keepworkUsername;
	self._tcp_nid = tcp_nid;
	self._bAdmin = bAdmin;
	self._room = room;
	
	self:GenerateToken();
	
	return self;
end

function LobbyClientInfo:connectClient(other)
	self._connects[other:getName()] = other;
end

function LobbyClientInfo:disconnectClient(other)
	self._connects[other:getName()] = nil;
end

function LobbyClientInfo:getConnects()
	return self._connects;
end

function LobbyClientInfo:getRoom()
	return self._room;
end

function LobbyClientInfo:isAdmin()
	return self._bAdmin;
end

function LobbyClientInfo:getToken()
	return self._token;
end

function LobbyClientInfo:getTCPNid()
	return self._tcp_nid;
end

function LobbyClientInfo:getUDPNid()
	return self._udp_nid;
end

function LobbyClientInfo:setUDPNid(nid)
	self._udp_nid = nid;
end

function LobbyClientInfo:getName()
	return self._keepworkUsername;
end
