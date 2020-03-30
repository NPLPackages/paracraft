--[[
Title: PacketEntityMove
Author(s): LiXizhi
Date: 2016/8/4
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketEntityMove.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketEntityMove:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketEntityMove = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketEntityMove"));

function PacketEntityMove:ctor()
end

function PacketEntityMove:Init(entityOrId, scaledX, scaledY, scaledZ, facing, pitch)
	if(type(entityOrId) == "table") then
		return self:Init1(entityOrId);
	else
		return self:Init2(entityOrId, scaledX, scaledY, scaledZ, facing, pitch);
	end
end

function PacketEntityMove:Init1(entity)
	self.entityId = entity.entityId;
    self.x = math.floor(entity.x * 32);
    self.y = math.floor(entity.y * 32);
    self.z = math.floor(entity.z * 32);
    self.facing = math.floor((entity.facing or 0)* 32);
    self.pitch = math.floor((entity.rotationPitch or 0)* 32);
	return self;
end

function PacketEntityMove:Init2(entityId, scaledX, scaledY, scaledZ, facing, pitch)
	self.entityId = entityId;
    self.x = scaledX;
    self.y = scaledY;
    self.z = scaledZ;
    self.facing = facing;
    self.pitch = pitch;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketEntityMove:ProcessPacket(net_handler)
	if(net_handler.handleEntityMove) then
		net_handler:handleEntityMove(self);
	end
end

function PacketEntityMove:ContainsSameEntityIDAs(packet)
    return packet.entityId == self.entityId;
end