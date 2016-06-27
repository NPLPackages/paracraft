--[[
Title: PacketMapChunks
Author(s): LiXizhi
Date: 2014/7/3
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketMapChunks.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketMapChunks:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local PacketMapChunks = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketMapChunks"));

function PacketMapChunks:ctor()
end

function PacketMapChunks:Init(chunkList)
	local nCount = chunkList:size();
    self.chunkPosX = commonlib.vector:new();
    self.chunkPosZ = commonlib.vector:new();
    self.chunkExistFlag = commonlib.vector:new();
    self.chunkHasAddSectionFlag = commonlib.vector:new();
    self.chunkData = commonlib.vector:new();
    
    for i = 1, nCount do
        local chunk = chunkList[i];
        local packet_ChunkData = Packets.PacketMapChunk:GetMapChunkData(chunk, true, 65535);
        self.chunkPosX[i] = chunk.chunkX;
        self.chunkPosZ[i] = chunk.chunkZ;
        self.chunkExistFlag[i] = packet_ChunkData.chunkExistFlag;
        self.chunkHasAddSectionFlag[i] = packet_ChunkData.chunkHasAddSectionFlag;
        self.chunkData[i] = packet_ChunkData.chunkData;
    end

	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketMapChunks:ProcessPacket(net_handler)
	if(net_handler.handleMapChunks) then
		net_handler:handleMapChunks(self);
	end
end

function PacketMapChunks:GetNumberOfChunks()
	if(self.chunkPosX) then
		return #(self.chunkPosX);
	else
		return 0;
	end
end

function PacketMapChunks:GetChunkPosX(nIndex)
    return self.chunkPosX[nIndex];
end

function PacketMapChunks:GetChunkPosZ(nIndex)
    return self.chunkPosZ[nIndex];
end

function PacketMapChunks:GetCompressedChunkData(nIndex)
    return self.chunkData[nIndex];
end

