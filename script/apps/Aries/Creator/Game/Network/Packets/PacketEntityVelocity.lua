--[[
Title: PacketEntityVelocity
Author(s): LiXizhi
Date: 2014/7/4
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketEntityVelocity.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketEntityVelocity:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ChatMessage.lua");
local ChatMessage = commonlib.gettable("MyCompany.Aries.Game.Network.ChatMessage");
local PacketEntityVelocity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketEntityVelocity"));

function PacketEntityVelocity:ctor()
end

function PacketEntityVelocity:Init()
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketEntityVelocity:ProcessPacket(net_handler)
	if(net_handler.handleEntityVelocity) then
		net_handler:handleEntityVelocity(self);
	end
end


