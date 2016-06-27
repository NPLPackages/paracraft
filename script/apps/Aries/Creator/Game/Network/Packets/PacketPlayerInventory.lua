--[[
Title: PacketPlayerInventory
Author(s): LiXizhi
Date: 2014/7/4
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketPlayerInventory.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketPlayerInventory:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ChatMessage.lua");
local ChatMessage = commonlib.gettable("MyCompany.Aries.Game.Network.ChatMessage");
local PacketPlayerInventory = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketPlayerInventory"));

function PacketPlayerInventory:ctor()
end

function PacketPlayerInventory:Init(entityId, slot_index, itemStack)
	self.entityId = entityId;
	self.slot_index = slot_index;
	if(itemStack) then
		self.itemStack = {id = itemStack.id, count=itemStack.count};
	end
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketPlayerInventory:ProcessPacket(net_handler)
	if(net_handler.handlePlayerInventory) then
		net_handler:handlePlayerInventory(self);
	end
end


