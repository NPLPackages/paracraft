--[[
Title: PacketPutFile
Author(s): LiXizhi
Date: 2014/6/30
Desc: any kind of named data. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketPutFile.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketPutFile:new():Init(filename, data);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketPutFile = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketPutFile"));

function PacketPutFile:ctor()
end

-- @param filename: relative to current world path
-- @param data: if nil it means the request, if string it means the response. 
function PacketPutFile:Init(filename, data)
	self.filename = filename;
	self.data = data;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketPutFile:ProcessPacket(net_handler)
	if(net_handler.handlePutFile) then
		net_handler:handlePutFile(self);
	end
end



