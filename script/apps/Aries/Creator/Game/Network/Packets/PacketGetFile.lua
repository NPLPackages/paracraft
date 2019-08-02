--[[
Title: PacketGetFile
Author(s): LiXizhi
Date: 2014/6/30
Desc: any kind of named data. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketGetFile.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketGetFile:new():Init(filename, data);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketGetFile = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketGetFile"));

function PacketGetFile:ctor()
end

-- @param filename: relative to current world path
-- @param data: if nil it means the request, if string it means the response. 
function PacketGetFile:Init(filename, data)
	self.filename = filename;
	self.data = data;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketGetFile:ProcessPacket(net_handler)
	if(net_handler.handleGetFile) then
		net_handler:handleGetFile(self);
	end
end



