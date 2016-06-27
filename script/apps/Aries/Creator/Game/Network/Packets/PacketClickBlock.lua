--[[
Title: PacketClickBlock
Author(s): LiXizhi
Date: 2014/7/19
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketClickBlock.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketClickBlock:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local PacketClickBlock = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketClickBlock"));

function PacketClickBlock:ctor()
end

function PacketClickBlock:Init(block_id, x, y, z, mouse_button, entity, side)
	self.block_id = block_id;
	self.x = x;
	self.y = y;
	self.z = z;
	if(entity) then
		self.entityId = entity.entityId;
	end
	self.mouse_button = mouse_button;
	self.side = side;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketClickBlock:ProcessPacket(net_handler)
	if(net_handler.handleClickBlock) then
		net_handler:handleClickBlock(self);
	end
end


