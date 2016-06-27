--[[
Title: PacketPing
Author(s): LiXizhi
Date: 2014/6/25
Desc: base class for all packets
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketPing.lua");
local PacketPing = commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketPing");
-------------------------------------------------------
]]
local PacketPing = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketPing"));

function PacketPing:ctor()
end

