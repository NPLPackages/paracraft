--[[
Title: PacketMove
Author(s): LiXizhi
Date: 2014/6/30
Desc: movement
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketMove.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketMove:new():Init(reason);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketMove = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketMove"));

function PacketMove:ctor()
end

function PacketMove:Init(bOnGround)
	self.onground = bOnGround;
	return self;
end

function PacketMove:ReadPacket(msg)
	PacketMove._super.ReadPacket(self, msg);
	--self.moving = (self.x~=nil);
	--self.rotating = (yaw~=nil or pitch~=nil);
end

-- Passes this Packet on to the NetHandler for processing.
function PacketMove:ProcessPacket(net_handler)
	if(net_handler.handleMove) then
		net_handler:handleMove(self);
	end
end


