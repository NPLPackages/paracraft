--[[
Title: PacketBlockChange
Author(s): LiXizhi
Date: 2014/7/17
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketBlockChange.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketBlockChange:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local PacketBlockChange = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketBlockChange"));

function PacketBlockChange:ctor()
end

function PacketBlockChange:Init(x,y,z, id, world)
	self.x = x;
	self.y = y;
	self.z = z;
	self.blockid = BlockEngine:GetBlockId(x,y,z);
	self.data = BlockEngine:GetBlockData(x,y,z);
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketBlockChange:ProcessPacket(net_handler)
	if(net_handler.handleBlockChange) then
		net_handler:handleBlockChange(self);
	end
end


