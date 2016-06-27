--[[
Title: PacketEntityAction
Author(s): LiXizhi
Date: 2014/7/11
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketEntityAction.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketEntityAction:new():Init(state, entity, param1);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ChatMessage.lua");
local ChatMessage = commonlib.gettable("MyCompany.Aries.Game.Network.ChatMessage");
local PacketEntityAction = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketEntityAction"));

function PacketEntityAction:ctor()
end

-- @param state: 0 is play action animation. 
-- 1 is mount on the given entity. 
function PacketEntityAction:Init(state, entity, param1)
	if(entity) then
		self.entityId = entity.entityId;
	else
		self.entityId = -1;
	end
	self.state = state;
	self.param1 = param1;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketEntityAction:ProcessPacket(net_handler)
	if(net_handler.handleEntityAction) then
		net_handler:handleEntityAction(self);
	end
end


