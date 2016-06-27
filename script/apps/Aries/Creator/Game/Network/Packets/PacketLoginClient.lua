--[[
Title: PacketLoginClient
Author(s): LiXizhi
Date: 2014/6/25
Desc: base class for all packets
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketLoginClient.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketLoginClient:new():Init(username, password);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketLoginClient = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketLoginClient"));

function PacketLoginClient:ctor()
end

function PacketLoginClient:Init(username, password)
	self.username = username;
	self.password =	password;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketLoginClient:ProcessPacket(net_handler)
	if(net_handler.handleLoginClient) then
		net_handler:handleLoginClient(self);
	end
end


