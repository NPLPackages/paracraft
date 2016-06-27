--[[
Title: Packet
Author(s): LiXizhi
Date: 2014/6/25
Desc: base class for all packets
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local Packet = commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet");
-------------------------------------------------------
]]
local Packet_Types = commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet_Types");
local Packet = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"));

Packet.isChunkDataPacket = nil;

function Packet:ctor()
end

-- initialize packet
function Packet:Init(msg)
	commonlib.partialcopy(self, msg);
	return;
end

-- static function: create a new instance, just in case it is a singleton. it may return self. 
function Packet:GetInstance()
	return self:new();
end

-- Returns the ID of this packet. A faster way is to access the self.id. 
function Packet:GetPacketId()
    return Packet_Types:GetPacketId(self:class());
end

-- virtual: read packet from network msg data
function Packet:ReadPacket(msg)
	commonlib.partialcopy(self, msg);
end

-- virtual: By default, the packet itself is used as the raw message. 
-- @return a packet to be send. 
function Packet:WritePacket()
	return self;
end

-- virtual: Passes this Packet on to the NetHandler for processing.
function Packet:ProcessPacket(net_handler)
end

-- virtual: send packet immediately to c++ queue
-- sometimes, we do data compression here and then send the raw messages out. 
-- By default, the packet itself is used as the raw message. 
function Packet:Send(connection)
	local msg = self:WritePacket();
	msg.id = self.id;
	return connection:Send(msg);
end