--[[
Title: PacketPlayerPosition
Author(s): LiXizhi
Date: 2014/7/9
Desc: movement
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketPlayerPosition.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketPlayerPosition:new():Init(reason);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketMove.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketPlayerPosition = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketMove"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketPlayerPosition"));

function PacketPlayerPosition:ctor()
end

-- @param moving: boolean whether player is in motion. 
function PacketPlayerPosition:Init(x,y, stance, z, bOnGround)
	self.x, self.y, self.z = x,y,z;
	self.stance = stance;
	self.onground = bOnGround;
	self.moving = true;
	return self;
end



