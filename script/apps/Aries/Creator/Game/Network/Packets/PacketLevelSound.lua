--[[
Title: PacketLevelSound
Author(s): LiXizhi
Date: 2014/7/2
Desc: background music sound
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketLevelSound.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketLevelSound:new():Init(x,y,z);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketLevelSound = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketLevelSound"));

function PacketLevelSound:ctor()
end

function PacketLevelSound:Init(soundName, x, y, z, volume, pitch)
	self.soundName = soundName;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketLevelSound:ProcessPacket(net_handler)
	
end


