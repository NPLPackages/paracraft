--[[
Title: PacketEntityEffect
Author(s): LiXizhi
Date: 2014/7/4
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketEntityEffect.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketEntityEffect:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ChatMessage.lua");
local ChatMessage = commonlib.gettable("MyCompany.Aries.Game.Network.ChatMessage");
local PacketEntityEffect = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketEntityEffect"));

function PacketEntityEffect:ctor()
end

function PacketEntityEffect:Init()
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketEntityEffect:ProcessPacket(net_handler)
	if(net_handler.handleEntityEffect) then
		net_handler:handleEntityEffect(self);
	end
end


