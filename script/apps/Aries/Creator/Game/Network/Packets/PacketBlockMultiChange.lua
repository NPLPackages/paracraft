--[[
Title: PacketBlockMultiChange
Author(s): LiXizhi
Date: 2014/7/17
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketBlockMultiChange.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketBlockMultiChange:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
NPL.load("(gl)script/ide/math/bit.lua");
local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local PacketBlockMultiChange = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketBlockMultiChange"));

function PacketBlockMultiChange:ctor()
end

function PacketBlockMultiChange:Init(chunkX, chunkZ, blockList, count)
	self.chunkX = chunkX;
	self.chunkZ = chunkZ;
	self.blockList = blockList;

	local cx = chunkX * 16;
    local cz = chunkZ * 16;
	local idList = {};
	local dataList = {};
	for i=1, #blockList do
		local packedIndex = blockList[i];
		local x, y, z;
		x = cx + band(rshift(packedIndex, 12), 15);
		y = band(packedIndex, 255);
		z = cz + band(rshift(packedIndex, 8), 15);
		idList[i] = BlockEngine:GetBlockId(x,y,z);
		dataList[i] = BlockEngine:GetBlockData(x,y,z);
	end
	self.idList = idList;
	self.dataList = dataList;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketBlockMultiChange:ProcessPacket(net_handler)
	if(net_handler.handleBlockMultiChange) then
		net_handler:handleBlockMultiChange(self);
	end
end

