--[[
Title: PacketEntityHeadRotation
Author(s): LiXizhi
Date: 2014/7/4
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketEntityHeadRotation.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketEntityHeadRotation:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ChatMessage.lua");
local ChatMessage = commonlib.gettable("MyCompany.Aries.Game.Network.ChatMessage");
local PacketEntityHeadRotation = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketEntityHeadRotation"));

function PacketEntityHeadRotation:ctor()
end

function PacketEntityHeadRotation:Init(entityId, rot, pitch)
	self.entityId = entityId;
	self.rot = rot;
	self.pitch = pitch;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketEntityHeadRotation:ProcessPacket(net_handler)
	if(net_handler.handleEntityHeadRotation) then
		net_handler:handleEntityHeadRotation(self);
	end
end


