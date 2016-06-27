--[[
Title: PacketUpdateTime
Author(s): LiXizhi
Date: 2014/6/29
Desc: spawn position changed. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketUpdateTime.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketUpdateTime:new():Init(x,y,z);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketUpdateTime = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketUpdateTime"));

function PacketUpdateTime:ctor()
end

function PacketUpdateTime:Init(totalTime, curTime)
	self.totalTime, self.curTime = totalTime, curTime;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketUpdateTime:ProcessPacket(net_handler)
	
end


