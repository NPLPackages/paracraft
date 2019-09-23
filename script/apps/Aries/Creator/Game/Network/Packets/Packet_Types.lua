--[[
Title: Packet types
Author(s): LiXizhi
Date: 2014/6/25
Desc: all packets. Whenever adding a new packet type, one needs to add it here. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet_Types.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local Packet_Types = commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet_Types");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local Packet = commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");

local Packet_Types = commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet_Types");

-- Maps packet id to packet class
local packetIdToClassMap = {};

-- Maps packet class to packet id
local packetClassToIdMap = {};

-- List of the client's packet IDs.
local clientPacketIdList = {};
local serverPacketIdList = {};
    
function Packet_Types:StaticInit()
	if(self.inited) then
		return;
	end
	self.inited = true;
	LOG.std(nil, "debug", "Packet_Types", "initialized");

	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketPing.lua");
	self:AddIdClassMapping(1, false, true, Packets.PacketPing);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketLogin.lua");
	self:AddIdClassMapping(2, true, true, Packets.PacketLogin);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketKickDisconnect.lua");
	self:AddIdClassMapping(3, true, true, Packets.PacketKickDisconnect);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketEntityPlayerSpawn.lua");
	self:AddIdClassMapping(4, true, true, Packets.PacketEntityPlayerSpawn);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketEntityMobSpawn.lua");
	self:AddIdClassMapping(5, true, true, Packets.PacketEntityMobSpawn);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketPlayerInfo.lua");
	self:AddIdClassMapping(6, true, true, Packets.PacketPlayerInfo);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketAnimation.lua");
	self:AddIdClassMapping(7, true, true, Packets.PacketAnimation);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketSpawnPosition.lua");
	self:AddIdClassMapping(8, true, true, Packets.PacketSpawnPosition);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketPlayerLookMove.lua");
	self:AddIdClassMapping(9, true, true, Packets.PacketPlayerLookMove);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketUpdateTime.lua");
	self:AddIdClassMapping(10, true, true, Packets.PacketUpdateTime);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketCustomPayload.lua");
	self:AddIdClassMapping(11, true, true, Packets.PacketCustomPayload);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketChat.lua");
	self:AddIdClassMapping(12, true, true, Packets.PacketChat);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketMove.lua");
	self:AddIdClassMapping(13, true, true, Packets.PacketMove);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketLevelSound.lua");
	self:AddIdClassMapping(14, true, true, Packets.PacketLevelSound);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketBlockDestroy.lua");
	self:AddIdClassMapping(15, true, true, Packets.PacketBlockDestroy);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketMapChunk.lua");
	self:AddIdClassMapping(16, true, true, Packets.PacketMapChunk);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketMapChunks.lua");
	self:AddIdClassMapping(17, true, true, Packets.PacketMapChunks);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketMapChunkData.lua");
	self:AddIdClassMapping(18, true, true, Packets.PacketMapChunkData);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketRelEntityLook.lua");
	self:AddIdClassMapping(19, true, true, Packets.PacketRelEntityLook);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketEntityVelocity.lua");
	self:AddIdClassMapping(20, true, true, Packets.PacketEntityVelocity);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketRelEntityMove.lua");
	self:AddIdClassMapping(21, true, true, Packets.PacketRelEntityMove);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketRelEntityMoveLook.lua");
	self:AddIdClassMapping(22, true, true, Packets.PacketRelEntityMoveLook);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketEntityTeleport.lua");
	self:AddIdClassMapping(23, true, true, Packets.PacketEntityTeleport);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketSleep.lua");
	self:AddIdClassMapping(24, true, true, Packets.PacketSleep);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketPlayerInventory.lua");
	self:AddIdClassMapping(25, true, true, Packets.PacketPlayerInventory);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketAttachEntity.lua");
	self:AddIdClassMapping(26, true, true, Packets.PacketAttachEntity);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketEntityHeadRotation.lua");
	self:AddIdClassMapping(27, true, true, Packets.PacketEntityHeadRotation);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketEntityEffect.lua");
	self:AddIdClassMapping(28, true, true, Packets.PacketEntityEffect);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketDestroyEntity.lua");
	self:AddIdClassMapping(29, true, true, Packets.PacketDestroyEntity);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketLoginClient.lua");
	self:AddIdClassMapping(30, true, true, Packets.PacketLoginClient);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketPlayerLook.lua");
	self:AddIdClassMapping(31, true, true, Packets.PacketPlayerLook);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketPlayerPosition.lua");
	self:AddIdClassMapping(32, true, true, Packets.PacketPlayerPosition);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketEntityAction.lua");
	self:AddIdClassMapping(33, true, true, Packets.PacketEntityAction);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketRelEntity.lua");
	self:AddIdClassMapping(34, true, true, Packets.PacketRelEntity);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketEntityMetadata.lua");
	self:AddIdClassMapping(35, true, true, Packets.PacketEntityMetadata);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketUpdateAttributes.lua");
	self:AddIdClassMapping(36, true, true, Packets.PacketUpdateAttributes);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketBlockChange.lua");
	self:AddIdClassMapping(37, true, true, Packets.PacketBlockChange);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketBlockMultiChange.lua");
	self:AddIdClassMapping(38, true, true, Packets.PacketBlockMultiChange);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketBlockPieces.lua");
	self:AddIdClassMapping(39, true, true, Packets.PacketBlockPieces);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketClickEntity.lua");
	self:AddIdClassMapping(40, true, true, Packets.PacketClickEntity);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketClickBlock.lua");
	self:AddIdClassMapping(41, true, true, Packets.PacketClickBlock);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketAuthUser.lua");
	self:AddIdClassMapping(42, true, true, Packets.PacketAuthUser);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketUpdateEntitySign.lua");
	self:AddIdClassMapping(43, true, true, Packets.PacketUpdateEntitySign);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketClientCommand.lua");
	self:AddIdClassMapping(44, true, true, Packets.PacketClientCommand);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketEntityMovableSpawn.lua");
	self:AddIdClassMapping(45, true, true, Packets.PacketEntityMovableSpawn);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketUpdateEnv.lua");
	self:AddIdClassMapping(46, true, true, Packets.PacketUpdateEnv);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketEntityFunction.lua");
	self:AddIdClassMapping(47, true, true, Packets.PacketEntityFunction);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketEntityMove.lua");
	self:AddIdClassMapping(48, true, true, Packets.PacketEntityMove);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketUpdateEntityBlock.lua");
	self:AddIdClassMapping(49, true, true, Packets.PacketUpdateEntityBlock);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketGetFile.lua");
	self:AddIdClassMapping(50, true, true, Packets.PacketGetFile);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketPutFile.lua");
	self:AddIdClassMapping(51, true, true, Packets.PacketPutFile);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketMultiple.lua");
	self:AddIdClassMapping(52, true, true, Packets.PacketMultiple);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketCodeBlockEvent.lua");
	self:AddIdClassMapping(53, true, true, Packets.PacketCodeBlockEvent);
	-- TODO: add new packets here
end

-- Adds a two way mapping between the packet ID and packet class. and assign the packet id. 
function Packet_Types:AddIdClassMapping(packet_id, bIsClientPacket, bIsServerPacket, packet_class)
	if(not packet_class) then
		LOG.std(nil, "warn", "Packet_Types", "unknown class for packet id:"..packet_id);
    elseif (packetIdToClassMap[packet_id]) then
		LOG.std(nil, "warn", "Packet_Types", "Duplicate packet id:"..packet_id);
    elseif (packetClassToIdMap[packet_class]) then
        LOG.std(nil, "warn", "Packet_Types", "Duplicate packet class:"..packet_class);
    else
        packetIdToClassMap[packet_id] = packet_class;
        packetClassToIdMap[packet_class] = packet_id;

        if (bIsClientPacket) then
            clientPacketIdList[#clientPacketIdList+1] = packet_id;
        end
        if (bIsServerPacket) then
            serverPacketIdList[#serverPacketIdList+1] = packet_id;
        end
		packet_class.id = packet_id;
    end
end

function Packet_Types:GetPacketId(packet_class)
    return packetClassToIdMap[packet_class];
end

-- Create/Get a new instance of the specified Packet class.
-- it may create a new intance or a singleton is returned depending on packet type. 
function Packet_Types:GetNewPacket(packet_id)
    local packet_class = packetIdToClassMap[packet_id];
	if(packet_class) then
		return packet_class:GetInstance();
    end
end