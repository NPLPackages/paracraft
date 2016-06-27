--[[
Title: PacketUpdateAttributes
Author(s): LiXizhi
Date: 2014/7/15
Desc: for server side entity attributes
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketUpdateAttributes.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketUpdateAttributes:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ChatMessage.lua");
local ChatMessage = commonlib.gettable("MyCompany.Aries.Game.Network.ChatMessage");
local PacketUpdateAttributes = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketUpdateAttributes"));

function PacketUpdateAttributes:ctor()
end

function PacketUpdateAttributes:Init(entityId, dataWatcher)
	self.entityId = entityId;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketUpdateAttributes:ProcessPacket(net_handler)
	if(net_handler.handleUpdateAttributes) then
		net_handler:handleUpdateAttributes(self);
	end
end


