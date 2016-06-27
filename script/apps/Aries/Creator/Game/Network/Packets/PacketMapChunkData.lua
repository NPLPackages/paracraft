--[[
Title: PacketMapChunkData
Author(s): LiXizhi
Date: 2014/7/3
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketMapChunkData.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketMapChunkData:new():Init(username, password);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketMapChunkData = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketMapChunkData"));

function PacketMapChunkData:ctor()
	-- self.data;
	-- self.chunkExistFlag;
end


function PacketMapChunkData:GetCompressedChunkData()
	return self.data;
end
