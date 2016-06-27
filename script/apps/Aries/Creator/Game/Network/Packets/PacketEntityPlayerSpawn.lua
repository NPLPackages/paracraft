--[[
Title: PacketEntityPlayerSpawn
Author(s): LiXizhi
Date: 2014/6/29
Desc: entity player MP update and spawn. Handle this on client to spawn a client MP.
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketEntityPlayerSpawn.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketEntityPlayerSpawn:new():Init(reason);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DataWatcher.lua");
local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local PacketEntityPlayerSpawn = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketEntityPlayerSpawn"));

function PacketEntityPlayerSpawn:ctor()
end

function PacketEntityPlayerSpawn:Init(entity)
	self.entityId = entity.entityId;
    self.name = entity:GetUserName();
    self.x = math.floor(entity.x * 32);
    self.y = math.floor(entity.y * 32);
    self.z = math.floor(entity.z * 32);
    self.facing = math.floor((entity.rotationYaw or entity.facing or 0) * 32);
    self.pitch = math.floor(entity.rotationPitch * 32);
    
	-- for watched data fields
	local dataWatcher  = entity:GetDataWatcher();
	if(dataWatcher) then
		self.metadata = dataWatcher:GetAllObjectList();
	end
	return self;
end


-- virtual: read packet from network msg data
function PacketEntityPlayerSpawn:ReadPacket(msg)
	if(msg.data) then
		self.metadata = DataWatcher.ReadWatchebleObjects(msg.data);
		msg.data = nil;
	end
	PacketEntityPlayerSpawn._super.ReadPacket(self, msg);
end

-- the list of watcheble objects
function PacketEntityPlayerSpawn:GetMetadata()
    return self.metadata;
end


-- virtual: By default, the packet itself is used as the raw message. 
-- @return a packet to be send. 
function PacketEntityPlayerSpawn:WritePacket()
	if(self.metadata) then
		self.data = DataWatcher.WriteObjectsInListToData(self.metadata, nil);
		self.metadata = nil;
	end
	return PacketEntityPlayerSpawn._super.WritePacket(self);
end

-- Passes this Packet on to the NetHandler for processing.
function PacketEntityPlayerSpawn:ProcessPacket(net_handler)
	if(net_handler.handleEntityPlayerSpawn) then
		net_handler:handleEntityPlayerSpawn(self);
	end
end


