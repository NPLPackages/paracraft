--[[
Title: EntityTrackerEntry
Author(s): LiXizhi
Date: 2014/6/29
Desc: tracking entities. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/EntityTrackerEntry.lua");
local EntityTrackerEntry = commonlib.gettable("MyCompany.Aries.Game.Network.EntityTrackerEntry");
-------------------------------------------------------
]]
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local EntityPlayerMP = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPlayerMP")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local EntityTrackerEntry = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Network.EntityTrackerEntry"));

-- how many ticks to sync once
EntityTrackerEntry.updateFrequency= 3;

function EntityTrackerEntry:ctor()
	--	Holds references to all the players that are currently receiving position updates for this entity.
    self.trackingPlayers = commonlib.UnorderedArraySet:new();
	self.ticks = 0;
	self.ticksSinceLastForcedTeleport = 0;
end

function EntityTrackerEntry:Init(entity, viewdistance, updateFrequency, bSendVelocityUpdates)
	self.entity = entity;
    self.viewdistance = viewdistance;
    self.updateFrequency = updateFrequency;
    self.bSendVelocityUpdates = bSendVelocityUpdates;
	self.lastScaledXPosition = math.floor((entity.x or 0)* 32);
    self.lastScaledYPosition = math.floor((entity.y or 0)* 32);
    self.lastScaledZPosition = math.floor((entity.z or 0)* 32);
	self.lastYaw = math.floor((entity.facing or 0)* 32);
	self.lastPitch = math.floor((entity.rotationPitch or 0)* 32);
	self.motionX = entity.motionX;
	self.motionY = entity.motionY;
	self.motionZ = entity.motionZ;
	self.lastHeadYaw = math.floor(self.entity:GetRotationYawHead() * 32);
	self.lastHeadPitch = math.floor((self.entity.rotationHeadPitch or 0) * 32);
	return self;
end

-- ticks and sends position, velocity, rotation, watched data and riding info at given rate.
-- this function is called per tick for each tracker entry with all entityMP on the server. 
-- @param playerEntityList: usually all entityMP list on the server side. 
function EntityTrackerEntry:SendLocationToAllClients(playerEntityList)
    self.playerEntitiesUpdated = false;
	local entity = self.entity;
	if(not entity.x) then
		return;
	end
    if (not self.isDataInitialized or entity:GetDistanceSq(self.x, self.y, self.z) > 16) then
        self.x = entity.x;
        self.y = entity.y;
        self.z = entity.z;
        self.isDataInitialized = true;
        self.playerEntitiesUpdated = true;
        self:SendEventsToPlayers(playerEntityList);
    end
	
	-- update riding state
	if ( self.lastRidingEntity ~= entity.ridingEntity 
		or (entity.ridingEntity ~= nil and (self.ticks % 60) == 0)) then
        self.lastRidingEntity = entity.ridingEntity;
		self:SendPacketToAllAssociatedPlayers(Packets.PacketAttachEntity:new():Init(0, self.entity, self.entity.ridingEntity));
    end

	-- updata location, facing, and watched data(current animation, etc). 
	if ( (self.ticks % self.updateFrequency) == 0 or entity:HasChanges()) then
		self.ticksSinceLastForcedTeleport = self.ticksSinceLastForcedTeleport + 1;
		local scaledX = math.floor(32*entity.x);
		local scaledY = math.floor(32*entity.y);
		local scaledZ = math.floor(32*entity.z);
		local facing = math.floor(32*(entity.rotationYaw or entity.facing or 0));
		local pitch = math.floor(32*(entity.rotationPitch or 0));
		local dx = scaledX - self.lastScaledXPosition;
		local dy = scaledY - self.lastScaledYPosition;
		local dz = scaledZ - self.lastScaledZPosition;
		local bPosHasChanges = math.abs(dx) >= 4 or math.abs(dy) >= 4 or math.abs(dz) >= 4 or self.ticks % 60 == 0;
		local bRotHasChanges = math.abs(facing - self.lastYaw) >= 4 or math.abs(pitch - self.lastPitch) >= 4;

		local packet;
		-- skip the first frame to prevent smooth moving on first creation. 
		if (self.ticks > 0) then
			if (dx >= -128 and dx < 128 and dy >= -128 and dy < 128 and dz >= -128 and dz < 128 
				and self.ticksSinceLastForcedTeleport <= 400) then
				if(entity.ridingEntity) then
					if (bRotHasChanges) then
						packet = Packets.PacketRelEntityLook:new():Init(entity.entityId, facing, pitch);
					end
				else
					if (bPosHasChanges and bRotHasChanges) then
						packet = Packets.PacketRelEntityMoveLook:new():Init(entity.entityId, dx, dy, dz, facing, pitch);
					elseif (bPosHasChanges) then
						packet = Packets.PacketRelEntityMove:new():Init(entity.entityId, dx, dy, dz);
					elseif (bRotHasChanges) then
						packet = Packets.PacketRelEntityLook:new():Init(entity.entityId, facing, pitch);
					end
				end
			else
				self.ticksSinceLastForcedTeleport = 0;
				packet = Packets.PacketEntityMove:new():Init(entity.entityId, scaledX, scaledY, scaledZ, facing, pitch);
			end
		end

		if (self.sendVelocityUpdates and entity.motionX) then
			local dMotionX = entity.motionX - self.motionX;
			local dMotionY = entity.motionY - self.motionY;
			local dMotionZ = entity.motionZ - self.motionZ;
			local minMotionDelta = 0.02;
			local deltaSpeedScaleSq = dMotionX * dMotionX + dMotionY * dMotionY + dMotionZ * dMotionZ;

			if (deltaSpeedScaleSq > minMotionDelta * minMotionDelta or deltaSpeedScaleSq > 0 and entity.motionX == 0 and entity.motionY == 0 and entity.motionZ == 0) then
				self.motionX = entity.motionX;
				self.motionY = entity.motionY;
				self.motionZ = entity.motionZ;
				if (not entity.ridingEntity ) then
					self:SendPacketToAllTrackingPlayers(Packets.PacketEntityVelocity(entity.entityId, self.motionX, self.motionY, self.motionZ));
				end
			end
		end

		if (packet) then
			self:SendPacketToAllTrackingPlayers(packet);
		end

		self:SendWatchedData();
		
		if (packet) then
			if (bPosHasChanges) then
				self.lastScaledXPosition = scaledX;
				self.lastScaledYPosition = scaledY;
				self.lastScaledZPosition = scaledZ;
			end

			if (bRotHasChanges) then
				self.lastYaw = facing;
				self.lastPitch = pitch;
			end
		end
		
		
		local headYaw = math.floor(entity:GetRotationYawHead() * 32);
		local headPitch = math.floor((entity.rotationHeadPitch or 0) * 32);

		if (math.abs(headYaw - self.lastHeadYaw) >= 4 or math.abs(headPitch - self.lastHeadPitch) >= 4) then
			self:SendPacketToAllTrackingPlayers(Packets.PacketEntityHeadRotation:new():Init(entity.entityId, headYaw, headPitch));
			self.lastHeadYaw = headYaw;
			self.lastHeadPitch = headPitch;
		end
	end
    self.ticks = self.ticks + 1;
end

-- if this is a MP entity player, then it is not informed
function EntityTrackerEntry:SendPacketToAllTrackingPlayers(Packet)
	for i = 1, #self.trackingPlayers do
		self.trackingPlayers[i]:SendPacketToPlayer(Packet);	
	end
end

-- if this is a MP entity player, then it receives the message too
function EntityTrackerEntry:SendPacketToAllAssociatedPlayers(Packet)
    self:SendPacketToAllTrackingPlayers(Packet);

    if (self.entity:isa(EntityManager.EntityPlayerMP)) then
        self.entity:SendPacketToPlayer(Packet);
    end
end

function EntityTrackerEntry:InformAllAssociatedPlayersOfItemDestruction()
	for i = 1, #self.trackingPlayers do
		local entityMP = self.trackingPlayers[i];
		entityMP.destroyedItemsNetCache:add(self.entity.entityId);
	end
end

-- Responsible for handle enter/leave visible range packet for player. 
-- Send the entity's spawn event to player just ONCE if player is in range. 
-- if the player is more than the view distance (typically 64) then the player is removed instead.
-- Subsequent location updates (if entity moves) are sent via SendLocationToAllClients. 
function EntityTrackerEntry:TrySendEventToPlayer(entityMP)
	if (entityMP ~= self.entity and self.entity.x) then
        --local dx = entityMP.x - (self.lastScaledXPosition / 32);
        --local dz = entityMP.z - (self.lastScaledZPosition / 32);
		-- fixing a bug for remote teleport. 
		local dx = entityMP.x - self.entity.x;
        local dz = entityMP.z - self.entity.z;

        if (dx >= (-self.viewdistance) and dx <= self.viewdistance and dz >= (-self.viewdistance) and dz <= self.viewdistance) then
			-- send all player event, if in view distance
			
			if (not self.trackingPlayers:contains(entityMP) and (self:IsPlayerWatchingThisChunk(entityMP) or self.entity.bIsGloballyTracked)) then
                self.trackingPlayers:add(entityMP);
                local packet = self:GetPacketForThisEntity();
				
                entityMP:SendPacketToPlayer(packet);
				-- TODO: send watched data and special entity data here?
                
                self.motionX = self.entity.motionX;
                self.motionY = self.entity.motionY;
                self.motionZ = self.entity.motionZ;

                if (self.sendVelocityUpdates and not packet:isa(Packets.PacketEntityMobSpawn)) then
                    entityMP:SendPacketToPlayer(Packets.PacketEntityVelocity:new():Init(self.entity.entityId, self.entity.motionX, self.entity.motionY, self.entity.motionZ));
                end

                if (self.entity.ridingEntity) then
                    entityMP:SendPacketToPlayer(Packets.PacketAttachEntity:new():Init(0, self.entity, self.entity.ridingEntity));
                end


                if (self.entity.GetCurrentItemOrArmor) then
					-- send the wearable item stack: first 5 slots.
                    for i = 1, 5 do
                        local itemStack = self.entity:GetCurrentItemOrArmor(i);
                        if (itemStack) then
                            entityMP:SendPacketToPlayer(Packets.PacketPlayerInventory:new():Init(self.entity.entityId, i, itemStack));
                        end
                    end
                end

                if (self.entity:isa(EntityManager.EntityPlayer)) then
                    local player = self.entity;

                    if (player:IsPlayerSleeping()) then
                        entityMP:SendPacketToPlayer(Packets.PacketSleep:new():Init(self.entity, 0, math.floor(self.entity.x), math.floor(self.entity.y), math.floor(self.entity.z)));
                    end
                end
			end
        else
			self:RemovePlayerFromTracker(entityMP);
        end
    end
end

function EntityTrackerEntry:IsPlayerWatchingThisChunk(entityMP)
    return entityMP:GetWorldServer():GetPlayerManager():IsPlayerWatchingChunk(entityMP, self.entity.chunkCoordX, self.entity.chunkCoordZ);
end

function EntityTrackerEntry:SendEventsToPlayers(playerList)
    for i = 1, #playerList do
        self:TrySendEventToPlayer(playerList[i]);
    end
end

function EntityTrackerEntry:RemovePlayerFromTracker(entityMP)
    if (self.trackingPlayers:contains(entityMP)) then
        self.trackingPlayers:removeByValue(entityMP);
        entityMP.destroyedItemsNetCache:add(self.entity.entityId);
    end
end

function EntityTrackerEntry:SendWatchedData()
    local data = self.entity:GetDataWatcher();
	
    if (data and data:HasChanges()) then
        self:SendPacketToAllAssociatedPlayers(Packets.PacketEntityMetadata:new():Init(self.entity.entityId, data, false));
    end

	-- TODO: for additional attribute fields. 
    if (self.entity.GetServerAttrMap) then
        local attrMap = self.entity:GetServerAttrMap();
        local changedAttr = attrMap:GetChangedAttributes();

        if (not changedAttr:empty()) then
            self:SendPacketToAllAssociatedPlayers(Packets.PacketUpdateAttributes:new():Init(self.entity.entityId, changedAttr));
        end
        changedAttr:clear();
    end
end

-- if this is a player, then it recieves the message also
function EntityTrackerEntry:SendPacketToAllAssociatedPlayers(packet)
    self:SendPacketToAllTrackingPlayers(packet);

    if (self.entity:isa(EntityManager.EntityPlayerMP)) then
        self.entity:SendPacketToPlayer(packet);
    end
end


-- private: add any packet here. 
function EntityTrackerEntry:GetPacketForThisEntity()
    if (self.entity:IsDead()) then
		return;
    end

    if (self.entity:isa(EntityPlayerMP)) then
        return Packets.PacketEntityPlayerSpawn:new():Init(self.entity);
    elseif (self.entity:isa(EntityManager.EntityRailcar)) then
		return Packets.PacketEntityMovableSpawn:new():Init(self.entity, 10);
	elseif (self.entity:isa(EntityManager.EntityNPC)) then
		return Packets.PacketEntityMobSpawn:new():Init(self.entity, 12);
	elseif (self.entity:isa(EntityManager.EntityMob)) then
		return Packets.PacketEntityMobSpawn:new():Init(self.entity, 11);
	elseif (self.entity:isa(EntityManager.EntityItem)) then
		return Packets.PacketEntityMobSpawn:new():Init(self.entity, 13);
	elseif (self.entity:isa(EntityManager.EntityCollectable)) then
		return Packets.PacketEntityMobSpawn:new():Init(self.entity, 14);
    else
		-- default to mob packet for all other entity types
        return Packets.PacketEntityMobSpawn:new():Init(self.entity);
    end
end