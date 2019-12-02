--[[
Title: PacketUpdateEntityBlock
Author(s): LiXizhi
Date: 2016/10/28
Desc: for custom block entity data
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketUpdateEntityBlock.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketUpdateEntityBlock:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local PacketUpdateEntityBlock = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketUpdateEntityBlock"));

function PacketUpdateEntityBlock:ctor()
end

-- @param data1: any data
function PacketUpdateEntityBlock:Init(x, y, z, data1, data2, data3, data4)
	self.x = x;
	self.y = y;
	self.z = z;
	self.data1 = data1;
	self.data2 = data2;
	self.data3 = data3;
	self.data4 = data4;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketUpdateEntityBlock:ProcessPacket(net_handler)
	if(net_handler.handleUpdateEntityBlock) then
		net_handler:handleUpdateEntityBlock(self);
	end
end


