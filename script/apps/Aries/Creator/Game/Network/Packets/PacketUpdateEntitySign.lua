--[[
Title: PacketUpdateEntitySign
Author(s): LiXizhi
Date: 2014/7/26
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketUpdateEntitySign.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketUpdateEntitySign:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local PacketUpdateEntitySign = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketUpdateEntitySign"));

function PacketUpdateEntitySign:ctor()
end

function PacketUpdateEntitySign:Init(x, y, z, text, data)
	self.x = x;
	self.y = y;
	self.z = z;
	self.text = text;
	self.data = data;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketUpdateEntitySign:ProcessPacket(net_handler)
	if(net_handler.handleUpdateEntitySign) then
		net_handler:handleUpdateEntitySign(self);
	end
end


