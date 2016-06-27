--[[
Title: PacketRelEntityLook
Author(s): LiXizhi
Date: 2014/7/4
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketRelEntityLook.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketRelEntityLook:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketRelEntity.lua");
local PacketRelEntityLook = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketRelEntity"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketRelEntityLook"));

function PacketRelEntityLook:ctor()
end

function PacketRelEntityLook:Init(entityId, facing, pitch)
	PacketRelEntityLook._super.Init(self, entityId);
	self.facing = facing;
	self.pitch = pitch;
	self.rotating = true;
	return self;
end



