--[[
Title: PacketClickEntity
Author(s): LiXizhi
Date: 2014/7/19
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketClickEntity.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketClickEntity:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local PacketClickEntity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketClickEntity"));

function PacketClickEntity:ctor()
end

function PacketClickEntity:Init(playerEntity, targetEntity, mouse_button, x, y, z)
	if(playerEntity) then
		self.playerEntityId = playerEntity.entityId;
	end
	if(targetEntity) then
		self.targetEntityId = targetEntity.entityId;
	end
	self.mouse_button = mouse_button;
	self.x = x;
	self.y = y;
	self.z = z;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketClickEntity:ProcessPacket(net_handler)
	if(net_handler.handleClickEntity) then
		net_handler:handleClickEntity(self);
	end
end


