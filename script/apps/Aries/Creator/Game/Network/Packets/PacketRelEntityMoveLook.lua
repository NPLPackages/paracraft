--[[
Title: PacketRelEntityMoveLook
Author(s): LiXizhi
Date: 2014/7/4
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketRelEntityMoveLook.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketRelEntityMoveLook:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketRelEntity.lua");
local PacketRelEntityMoveLook = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketRelEntity"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketRelEntityMoveLook"));

function PacketRelEntityMoveLook:ctor()
end

-- @param x,y,z: scaled by 32 integer position. 
function PacketRelEntityMoveLook:Init(entityId, x, y, z, facing, pitch)
	PacketRelEntityMoveLook._super.Init(self, entityId);
	self.x = x;
	self.y = y;
	self.z = z;
	self.facing = facing;
	self.pitch = pitch;
	self.rotating = true;
	return self;
end


