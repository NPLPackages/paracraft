--[[
Title: PacketRelEntity
Author(s): LiXizhi
Date: 2014/7/14
Desc: relative movement
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketRelEntity.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketRelEntity:new():Init(reason);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketRelEntity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketRelEntity"));

function PacketRelEntity:ctor()
end

-- x,y,z, facing, pitch, ...
function PacketRelEntity:Init(entityId)
	self.entityId = entityId;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketRelEntity:ProcessPacket(net_handler)
	if(net_handler.handleRelEntity) then
		net_handler:handleRelEntity(self);
	end
end

function PacketRelEntity:ContainsSameEntityIDAs(packet)
    return packet.entityId == self.entityId;
end

