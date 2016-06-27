--[[
Title: PacketMapChunk
Author(s): LiXizhi
Date: 2014/7/3
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketMapChunk.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketMapChunk:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local PacketMapChunk = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketMapChunk"));

function PacketMapChunk:ctor()
end

-- @param chatmsg: must be a ChatMessage object. 
function PacketMapChunk:Init(chunk, bIncludeInit, filter)
	self.x = chunk.chunkX;
	self.z = chunk.chunkZ;
	self.bIncludeInit = bIncludeInit;

	local packetChunkData = PacketMapChunk:GetMapChunkData(chunk, bIncludeInit, filter);
	self.chunkExistFlag = packetChunkData.chunkExistFlag;
	self.chunkData = packetChunkData.chunkData;
	self.chunkHasAddSectionFlag = packetChunkData.chunkHasAddSectionFlag;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketMapChunk:ProcessPacket(net_handler)
	if(net_handler.handleMapChunk) then
		net_handler:handleMapChunk(self);
	end
end

-- static function. 
function PacketMapChunk:GetMapChunkData(chunk, bIncludeInit, filter)
	local chunkData = Packets.PacketMapChunkData:new();
	chunkData.chunkData = chunk:GetMapChunkData(true, filter);
	-- chunk column bitwise fields
	chunkData.chunkExistFlag = filter;
	chunkData.chunkHasAddSectionFlag = nil;
	return chunkData;
end
   
function PacketMapChunk:GetCompressedChunkData()
    return self.chunkData;
end

