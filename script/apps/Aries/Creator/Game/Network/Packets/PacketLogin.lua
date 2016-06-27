--[[
Title: PacketLogin
Author(s): LiXizhi
Date: 2014/6/25
Desc: a login packet from server to client, the client can then create the local player according to id
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketLogin.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketLogin:new():Init(username, password);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketLogin = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketLogin"));

function PacketLogin:ctor()
end

function PacketLogin:Init(clientEntityId, gameType, maxPlayers)
	self.clientEntityId = clientEntityId;
	self.gameType =	gameType;
	self.maxPlayers = maxPlayers;
	return self;
end

function PacketLogin:ReadPacket(msg)
	self.clientEntityId = msg.clientEntityId;
	self.gameType =	msg.gameType;
	self.maxPlayers = msg.maxPlayers;
end

function PacketLogin:Send(connection)
	self.id = self.id;
	return connection:Send(self);
end

-- Passes this Packet on to the NetHandler for processing.
function PacketLogin:ProcessPacket(net_handler)
	if(net_handler.handleLogin) then
		net_handler:handleLogin(self);
	end
end


