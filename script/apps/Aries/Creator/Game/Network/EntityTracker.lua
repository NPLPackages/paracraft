--[[
Title: EntityTracker
Author(s): LiXizhi
Date: 2014/6/29
Desc: this is a manager class for all tracking entities(entries). A singleton of this object is owned by WorldServer
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/EntityTracker.lua");
local EntityTracker = commonlib.gettable("MyCompany.Aries.Game.Network.EntityTracker");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/EntityTrackerEntry.lua");
local EntityPlayerMP = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPlayerMP")
local EntityTrackerEntry = commonlib.gettable("MyCompany.Aries.Game.Network.EntityTrackerEntry");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local EntityTracker = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Network.EntityTracker"));

function EntityTracker:ctor()
	-- set of tracked entities, used for iteration operations on tracked entities. mapping from entity id to entity
    self.trackedEntities = {};
end

function EntityTracker:Init(worldserver)
	self.theWorld = worldserver;
	self.entityViewDistance = worldserver:GetServerManager():GetEntityViewDistance();
	return self;
end

-- add an entity that should be synchronized among all players. 
function EntityTracker:AddEntityToTracker(entity, viewdistance, updateRate, bSendVelocityUpdate)
	if(not viewdistance) then
		return self:AutoAddEntityToTracker(entity);
	end

    if (viewdistance > self.entityViewDistance) then
        viewdistance = self.entityViewDistance;
    end

    if (not self.trackedEntities[entity.entityId]) then
        local tracker_entry = EntityTrackerEntry:new():Init(entity, viewdistance, updateRate, bSendVelocityUpdate);
        self.trackedEntities[entity.entityId] = tracker_entry;
        tracker_entry:SendEventsToPlayers(self.theWorld:GetPlayerEntities());
    end
end

function EntityTracker:RemoveEntityFromAllTrackingPlayers(entity)
    if (entity:isa(EntityPlayerMP)) then
		local entity_id, entity_tracker_entry = next(self.trackedEntities, nil);
        while (entity_tracker_entry) do
            entity_tracker_entry:RemovePlayerFromTracker(entity);
			entity_id, entity_tracker_entry = next(self.trackedEntities, entity_id);
        end
    end

	local the_entity = self.trackedEntities[entity.entityId];
	if (the_entity) then
		self.trackedEntities[entity.entityId] = nil;
        the_entity:InformAllAssociatedPlayersOfItemDestruction();
    end
end

-- send all entity locations, and all tracked events of tracked MP players. 
-- This function is called per tick in WorldServer. 
function EntityTracker:UpdateTrackedEntities()
    local playerMpList = {};
    local entity_id, entity_tracker_entry = next(self.trackedEntities, nil);
    while (entity_tracker_entry) do
        entity_tracker_entry:SendLocationToAllClients(self.theWorld:GetPlayerEntities());

        if (entity_tracker_entry.playerEntitiesUpdated and entity_tracker_entry.entity:isa(EntityPlayerMP)) then
            playerMpList[#playerMpList+1] = entity_tracker_entry.entity;
        end
		entity_id, entity_tracker_entry = next(self.trackedEntities, entity_id);
    end

    for i=1, #playerMpList do
        local entityPlayer = playerMpList[i];
		local entity_id, entity_tracker_entry = next(self.trackedEntities, nil);
		while (entity_tracker_entry) do
            if (entity_tracker_entry.entity ~= entityPlayer) then
                entity_tracker_entry:TrySendEventToPlayer(entityPlayer);
            end
			entity_id, entity_tracker_entry = next(self.trackedEntities, entity_id);
        end
    end
end

-- send the packet to all players tracking the entity, excluding the entity player itself, if the entity is a player.
function EntityTracker:SendPacketToAllPlayersTrackingEntity(entity, packet)
    entity = self.trackedEntities[entity.entityId];
    if (entity) then
        entity:SendPacketToAllTrackingPlayers(packet);
    end
end

--  sends to the entity if the entity is a player
function EntityTracker:SendPacketToAllAssociatedPlayers(entity, packet)
	entity = self.trackedEntities[entity.entityId];
    if (entity) then
        entity:SendPacketToAllAssociatedPlayers(packet);
    end
end

function EntityTracker:RemovePlayerFromTrackers(entityPlayerMP)
	local entity_id, entity_tracker_entry = next(self.trackedEntities, nil);
	while (entity_tracker_entry) do
        entity_tracker_entry:RemovePlayerFromTracker(entityPlayerMP);
		entity_id, entity_tracker_entry = next(self.trackedEntities, entity_id);
    end
end

-- send all tracked entity events in the given chunk to player, automatically remove the player in tracked entities if out of view distance. 
function EntityTracker:TrySendEventInChunkToPlayer(entityPlayerMP, chunkX, chunkZ)
	local entity_id, entity_tracker_entry = next(self.trackedEntities, nil);
	while (entity_tracker_entry) do
        if (entity_tracker_entry.entity ~= entityPlayerMP and entity_tracker_entry.entity.chunkCoordX == chunkX and entity_tracker_entry.entity.chunkCoordZ == chunkZ) then
            entity_tracker_entry:TrySendEventToPlayer(entityPlayerMP);
        end
		entity_id, entity_tracker_entry = next(self.trackedEntities, entity_id);
    end
end

-- add an entity that should be synchronized among all players. 
-- if entity is a remote player, we send all tracked events to the player, otherwise, adds with a visibility and update rate based on the class type
-- @paran entity: please note entity.isServerEntity must be true in order to be automatically tracked here.
function EntityTracker:AutoAddEntityToTracker(entity)
    if (entity:isa(EntityPlayerMP)) then
		-- if entity is a remote player
        self:AddEntityToTracker(entity, 512, 2);
        local entity_id, entity_tracker_entry = next(self.trackedEntities, nil);

        while (entity_tracker_entry) do
            if (entity_tracker_entry.entity ~= entity) then
                entity_tracker_entry:TrySendEventToPlayer(entity);
            end
			entity_id, entity_tracker_entry = next(self.trackedEntities, entity_id);
        end
    elseif (entity:isa(EntityManager.EntityItem)) then
        self:AddEntityToTracker(entity, 64, 20, true);
	elseif (entity:isa(EntityManager.EntityRailcar)) then
		self:AddEntityToTracker(entity, 80, 3, true);
	elseif (entity:isa(EntityManager.EntityMob)) then
		self:AddEntityToTracker(entity, 80, 3, true);
	elseif (entity:isa(EntityManager.EntityNPC)) then
		self:AddEntityToTracker(entity, 80, 3, true);
	elseif (entity:isa(EntityManager.EntityCollectable)) then
		self:AddEntityToTracker(entity, 64, 20, true);
	else
        -- TODO: other types
    end
end