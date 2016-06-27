--[[
Title: PacketPlayerInfo
Author(s): LiXizhi
Date: 2014/6/29
Desc: update player name, or whether connected and ping speed
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketPlayerInfo.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketPlayerInfo:new():Init(reason);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketPlayerInfo = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketPlayerInfo"));

function PacketPlayerInfo:ctor()
end

-- @param isConnected: whether connected or disconnected
-- @param ping: ping value of connection speed. the larger the slower the connection is. 
function PacketPlayerInfo:Init(username, isConnected, ping)
	self.username = username;
	self.isConnected = isConnected;
	self.ping = ping;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketPlayerInfo:ProcessPacket(net_handler)
	if(net_handler.handlePlayerInfo) then
		net_handler:handlePlayerInfo(self);
	end
end


