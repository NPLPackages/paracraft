--[[
Title: PacketBlockPieces
Author(s): LiXizhi
Date: 2014/7/18
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketBlockPieces.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketBlockPieces:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local PacketBlockPieces = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketBlockPieces"));

function PacketBlockPieces:ctor()
end

function PacketBlockPieces:Init(blockid, x,y,z, granularity)
	self.blockid = blockid;
	self.x = x;
	self.y = y;
	self.z = z;
	self.granularity = granularity;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketBlockPieces:ProcessPacket(net_handler)
	if(net_handler.handleBlockPieces) then
		net_handler:handleBlockPieces(self);
	end
end


