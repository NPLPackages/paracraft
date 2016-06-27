--[[
Title: PacketAuthUser
Author(s): LiXizhi
Date: 2014/7/24
Desc: base class for all packets
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketAuthUser.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketAuthUser:new():Init(reason);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketAuthUser = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketAuthUser"));

function PacketAuthUser:ctor()
end

function PacketAuthUser:Init(username, password, result, serverInfo)
	self.username = username;
	self.password = password;
	self.result = result;
	self.info = serverInfo;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketAuthUser:ProcessPacket(net_handler)
	if(net_handler.handleAuthUser) then
		net_handler:handleAuthUser(self);
	end
end


