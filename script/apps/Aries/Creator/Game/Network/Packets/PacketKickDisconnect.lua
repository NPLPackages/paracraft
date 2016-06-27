--[[
Title: PacketKickDisconnect
Author(s): LiXizhi
Date: 2014/6/25
Desc: base class for all packets
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketKickDisconnect.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketKickDisconnect:new():Init(reason);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketKickDisconnect = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketKickDisconnect"));

function PacketKickDisconnect:ctor()
end

function PacketKickDisconnect:Init(reason)
	self.reason = reason;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketKickDisconnect:ProcessPacket(net_handler)
	if(net_handler.handleKickDisconnect) then
		net_handler:handleKickDisconnect(self);
	end
end


