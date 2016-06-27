--[[
Title: PacketRelEntityMove
Author(s): LiXizhi
Date: 2014/7/4
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketRelEntityMove.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketRelEntityMove:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketRelEntity.lua");
local PacketRelEntityMove = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketRelEntity"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketRelEntityMove"));

function PacketRelEntityMove:ctor()
end

-- @param x,y,z: scaled by 32 integer position. 
function PacketRelEntityMove:Init(entityId, x, y, z)
	PacketRelEntityMove._super.Init(self, entityId);
	self.x = x;
	self.y = y;
	self.z = z;
	return self;
end



