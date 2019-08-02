--[[
Title: PacketEntityMobSpawn
Author(s): LiXizhi
Date: 2014/6/29
Desc: mob spawn and update
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketEntityMobSpawn.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketEntityMobSpawn:new():Init(reason);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DataWatcher.lua");
local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local PacketEntityMobSpawn = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketEntityMobSpawn"));

function PacketEntityMobSpawn:ctor()
end

-- @param entity: in case of client to server packet, it is a pure table containing {x,y,z,item_id, }. 
-- in case of server to client, it is the real server entity. 
function PacketEntityMobSpawn:Init(entity, entity_type)
	self.type = entity_type;
	if(entity.GetItemId) then
		self.entityId = entity.entityId;
		self.x = math.floor(entity.x * 32);
		self.y = math.floor(entity.y * 32);
		self.z = math.floor(entity.z * 32);
		self.pitch = math.floor((entity.rotationPitch or 0) * 32);
		self.yaw = math.floor((entity.rotationYaw or entity.facing or 0) * 32);
		self.item_id = entity:GetItemId();

		-- for watched data fields
		local dataWatcher  = entity:GetDataWatcher();
		if(dataWatcher) then
			self.metadata = dataWatcher:GetAllObjectList();
		end
	else
		self.x = math.floor(entity.x * 32);
		self.y = math.floor(entity.y * 32);
		self.z = math.floor(entity.z * 32);
		self.pitch = math.floor((entity.rotationPitch or 0) * 32);
		self.yaw = math.floor((entity.rotationYaw or entity.facing or 0) * 32);
		self.item_id = entity.item_id;
		self.metadata = entity.metadata;
	end
	return self;
end


-- virtual: read packet from network msg data
function PacketEntityMobSpawn:ReadPacket(msg)
	if(msg.data) then
		self.metadata = DataWatcher.ReadWatchebleObjects(msg.data);
		msg.data = nil;
	end
	PacketEntityMobSpawn._super.ReadPacket(self, msg);
end

-- the list of watcheble objects
function PacketEntityMobSpawn:GetMetadata()
    return self.metadata;
end

-- virtual: By default, the packet itself is used as the raw message. 
-- @return a packet to be send. 
function PacketEntityMobSpawn:WritePacket()
	if(self.metadata) then
		self.data = DataWatcher.WriteObjectsInListToData(self.metadata, nil);
		self.metadata = nil;
	end
	return PacketEntityMobSpawn._super.WritePacket(self);
end

-- Passes this Packet on to the NetHandler for processing.
function PacketEntityMobSpawn:ProcessPacket(net_handler)
	if(net_handler.handleMobSpawn) then
		net_handler:handleMobSpawn(self);
	end
end


