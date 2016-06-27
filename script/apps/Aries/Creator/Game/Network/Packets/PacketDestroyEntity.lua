--[[
Title: PacketDestroyEntity
Author(s): LiXizhi
Date: 2014/7/8
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketDestroyEntity.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketDestroyEntity:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ChatMessage.lua");
local ChatMessage = commonlib.gettable("MyCompany.Aries.Game.Network.ChatMessage");
local PacketDestroyEntity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketDestroyEntity"));

function PacketDestroyEntity:ctor()
end

function PacketDestroyEntity:Init(entity_ids)
	self.entity_ids = entity_ids;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketDestroyEntity:ProcessPacket(net_handler)
	if(net_handler.handleDestroyEntity) then
		net_handler:handleDestroyEntity(self);
	end
end


