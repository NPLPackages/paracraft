--[[
Title: PacketCustomPayload
Author(s): LiXizhi
Date: 2014/6/30
Desc: any kind of named data. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketCustomPayload.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketCustomPayload:new():Init(name, data);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketCustomPayload = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketCustomPayload"));

function PacketCustomPayload:ctor()
end

function PacketCustomPayload:Init(name, data)
	self.name, self.data = name, data;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketCustomPayload:ProcessPacket(net_handler)
	
end


