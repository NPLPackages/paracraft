--[[
Title: PacketEntityMetadata
Author(s): LiXizhi
Date: 2014/7/11
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketEntityMetadata.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketEntityMetadata:new():Init(entityPlayer, animId);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DataWatcher.lua");
local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local PacketEntityMetadata = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketEntityMetadata"));

function PacketEntityMetadata:ctor()
end

-- @param bAllObject: if true, we will send all objects regardless of changes, which is the case when an entity is first tracked. 
-- if false, we will only send changed data and set all data to be unmodified, which is the case for normal update tick updates. 
function PacketEntityMetadata:Init(entityId, dataWatcher, bAllObject)
	self.entityId = entityId;
	if (bAllObject) then
        self.metadata = dataWatcher:GetAllObjectList();
    else
        self.metadata = dataWatcher:UnwatchAndReturnAllWatched();
    end
	return self;
end

-- virtual: read packet from network msg data
function PacketEntityMetadata:ReadPacket(msg)
	self.entityId = msg.entityId;
	self.metadata = DataWatcher.ReadWatchebleObjects(msg.data);
end

-- the list of watcheble objects
function PacketEntityMetadata:GetMetadata()
    return self.metadata;
end

-- virtual: By default, the packet itself is used as the raw message. 
-- @return a packet to be send. 
function PacketEntityMetadata:WritePacket()
	if(self.metadata) then
		self.data = DataWatcher.WriteObjectsInListToData(self.metadata, nil);
		self.metadata = nil;
	end
	return PacketEntityMetadata._super.WritePacket(self);
end

-- Passes this Packet on to the NetHandler for processing.
function PacketEntityMetadata:ProcessPacket(net_handler)
	if(net_handler.handleEntityMetadata) then
		net_handler:handleEntityMetadata(self);
	end
end


