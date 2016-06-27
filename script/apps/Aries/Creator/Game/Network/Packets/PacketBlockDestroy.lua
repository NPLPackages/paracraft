--[[
Title: PacketBlockDestroy
Author(s): LiXizhi
Date: 2014/7/2
Desc: background music sound
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketBlockDestroy.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketBlockDestroy:new():Init(x,y,z);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketBlockDestroy = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketBlockDestroy"));

function PacketBlockDestroy:ctor()
end

function PacketBlockDestroy:Init(entityId, x,y,z,destroyedStage)
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketBlockDestroy:ProcessPacket(net_handler)
	
end


