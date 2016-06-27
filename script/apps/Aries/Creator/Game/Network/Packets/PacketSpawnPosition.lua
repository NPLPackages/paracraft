--[[
Title: PacketSpawnPosition
Author(s): LiXizhi
Date: 2014/6/29
Desc: spawn position changed. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketSpawnPosition.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketSpawnPosition:new():Init(x,y,z);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketSpawnPosition = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketSpawnPosition"));

function PacketSpawnPosition:ctor()
end

function PacketSpawnPosition:Init(x,y,z)
	self.x, self.y, self.z = x,y,z;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketSpawnPosition:ProcessPacket(net_handler)
	if(net_handler.handleSpawnPosition) then
		net_handler:handleSpawnPosition(self);
	end
end


