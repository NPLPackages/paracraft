--[[
Title: PacketPlayerLookMove
Author(s): LiXizhi
Date: 2014/6/30
Desc: movement
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketPlayerLookMove.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketPlayerLookMove:new():Init(reason);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketMove.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketPlayerLookMove = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketMove"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketPlayerLookMove"));

function PacketPlayerLookMove:ctor()
end

-- @param stance: the on ground y position
-- @param moving: boolean whether player is in motion. 
function PacketPlayerLookMove:Init(x,y, stance, z, yaw, pitch, bOnGround)
	self.x, self.y, self.z, self.yaw, self.pitch = x,y,z, yaw, pitch;
	self.stance = stance;
	self.onground = bOnGround;
	self.moving = (x~=nil);
	self.rotating = (yaw~=nil or pitch~=nil);
	return self;
end



