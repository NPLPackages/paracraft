--[[
Title: PacketSleep
Author(s): LiXizhi
Date: 2014/7/4
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketSleep.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketSleep:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ChatMessage.lua");
local ChatMessage = commonlib.gettable("MyCompany.Aries.Game.Network.ChatMessage");
local PacketSleep = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketSleep"));

function PacketSleep:ctor()
end

function PacketSleep:Init()
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketSleep:ProcessPacket(net_handler)
	if(net_handler.handleSleep) then
		net_handler:handleSleep(self);
	end
end


