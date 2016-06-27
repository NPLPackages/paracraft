--[[
Title: PacketPlayerLook
Author(s): LiXizhi
Date: 2014/6/30
Desc: movement
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketPlayerLook.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketPlayerLook:new():Init(reason);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketMove.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketPlayerLook = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketMove"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketPlayerLook"));

function PacketPlayerLook:ctor()
end

-- @param moving: boolean whether player is in motion. 
function PacketPlayerLook:Init(yaw, pitch, bOnGround)
	self.yaw, self.pitch = yaw, pitch;
	self.onground = bOnGround;
	self.rotating = (yaw~=nil or pitch~=nil);
	return self;
end



