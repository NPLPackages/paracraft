--[[
Title: PacketAnimation
Author(s): LiXizhi
Date: 2014/6/29
Desc: mob spawn and update
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketAnimation.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketAnimation:new():Init(reason);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketAnimation = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketAnimation"));

function PacketAnimation:ctor()
end

function PacketAnimation:Init(entity, anim_id)
	self.entityId = entity.entityId;
	self.anim_id= anim_id;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketAnimation:ProcessPacket(net_handler)
	
end


