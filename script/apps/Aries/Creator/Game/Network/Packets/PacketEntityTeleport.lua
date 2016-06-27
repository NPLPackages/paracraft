--[[
Title: PacketEntityTeleport
Author(s): LiXizhi
Date: 2014/7/4
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketEntityTeleport.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketEntityTeleport:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketEntityTeleport = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketEntityTeleport"));

function PacketEntityTeleport:ctor()
end

function PacketEntityTeleport:Init(entityOrId, scaledX, scaledY, scaledZ, facing, pitch)
	if(type(entityOrId) == "table") then
		return self:Init1(entityOrId);
	else
		return self:Init2(entityOrId, scaledX, scaledY, scaledZ, facing, pitch);
	end
end

function PacketEntityTeleport:Init1(entity)
	self.entityId = entity.entityId;
    self.x = math.floor(entity.x * 32);
    self.y = math.floor(entity.y * 32);
    self.z = math.floor(entity.z * 32);
    self.facing = math.floor(entity.facing * 32);
    self.pitch = math.floor(entity.rotationPitch * 32);
	return self;
end

function PacketEntityTeleport:Init2(entityId, scaledX, scaledY, scaledZ, facing, pitch)
	self.entityId = entityId;
    self.x = scaledX;
    self.y = scaledY;
    self.z = scaledZ;
    self.facing = facing;
    self.pitch = facing;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketEntityTeleport:ProcessPacket(net_handler)
	if(net_handler.handleEntityTeleport) then
		net_handler:handleEntityTeleport(self);
	end
end

function PacketEntityTeleport:ContainsSameEntityIDAs(packet)
    return packet.entityId == self.entityId;
end