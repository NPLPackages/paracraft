--[[
Title: PacketEntityFunction
Author(s): LiXizhi
Date: 2016/5/25
Desc: one time function for a given entity, such as Entity:Say
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketEntityFunction.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketEntityFunction:new():Init(entity, name, param);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ChatMessage.lua");
local ChatMessage = commonlib.gettable("MyCompany.Aries.Game.Network.ChatMessage");
local PacketEntityFunction = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketEntityFunction"));

function PacketEntityFunction:ctor()
end

-- @param state: 0 is play action animation. 
-- 1 is mount on the given entity. 
function PacketEntityFunction:Init(entity, name, param)
	if(entity) then
		self.entityId = entity.entityId;
	else
		self.entityId = -1;
	end
	self.name = name;
	self.param = param;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketEntityFunction:ProcessPacket(net_handler)
	if(net_handler.handleEntityFunction) then
		net_handler:handleEntityFunction(self);
	end
end


