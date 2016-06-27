--[[
Title: PacketAttachEntity
Author(s): LiXizhi
Date: 2014/7/4
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketAttachEntity.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketAttachEntity:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ChatMessage.lua");
local ChatMessage = commonlib.gettable("MyCompany.Aries.Game.Network.ChatMessage");
local PacketAttachEntity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketAttachEntity"));

function PacketAttachEntity:ctor()
end

-- @param vehicleEntity: nil means unmount
function PacketAttachEntity:Init(type, fromEntity, vehicleEntity)
	self.type = type;
	self.entityId = fromEntity.entityId;
	if(vehicleEntity) then
		self.vehicleEntityId = vehicleEntity.entityId;
	else
		self.vehicleEntityId = -1;
	end
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketAttachEntity:ProcessPacket(net_handler)
	if(net_handler.handleAttachEntity) then
		net_handler:handleAttachEntity(self);
	end
end


