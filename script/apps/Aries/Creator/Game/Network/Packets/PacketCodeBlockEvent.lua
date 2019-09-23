--[[
Title: PacketCodeBlockEvent
Author(s): LiXizhi
Date: 2019/9/22
Desc: custom user event in code block
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketCodeBlockEvent.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketCodeBlockEvent:new():Init(name, data);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketCodeBlockEvent = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketCodeBlockEvent"));

function PacketCodeBlockEvent:ctor()
end

function PacketCodeBlockEvent:Init(name, data)
	self.target = target;
	self.name, self.data = name, data;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketCodeBlockEvent:ProcessPacket(net_handler)
	if(net_handler.handleCodeBlockEvent) then
		net_handler:handleCodeBlockEvent(self);
	end
end


