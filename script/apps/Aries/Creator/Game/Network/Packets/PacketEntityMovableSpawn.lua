--[[
Title: PacketEntityMovableSpawn
Author(s): LiXizhi
Date: 2015/6/2
Desc: spawn packet for entity that is movable (with position and speed), such as EntityRailcar, etc.
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketEntityMovableSpawn.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketEntityMovableSpawn:new():Init(reason);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketEntityMovableSpawn = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketEntityMovableSpawn"));

function PacketEntityMovableSpawn:ctor()
end

function PacketEntityMovableSpawn:Init(entity, entity_type)
	self.entityId = entity.entityId;
	self.x = math.floor(entity.x * 32);
    self.y = math.floor(entity.y * 32);
    self.z = math.floor(entity.z * 32);
	self.pitch = math.floor((entity.rotationPitch or 0) * 32);
	self.yaw = math.floor((entity.rotationYaw or entity.facing or 0)* 32);
	self.type = entity_type;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketEntityMovableSpawn:ProcessPacket(net_handler)
	if(net_handler.handleMovableSpawn) then
		net_handler:handleMovableSpawn(self);
	end
end


