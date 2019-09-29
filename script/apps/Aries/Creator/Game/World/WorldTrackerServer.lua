--[[
Title: WorldTrackerServer
Author(s): LiXizhi
Date: 2014/7/2
Desc: tracking major world changes like block and entity changes and send those changes to clients. 
Each World can has multiple world trackers (in most cases just one). 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldTrackerServer.lua");
local WorldTrackerServer = commonlib.gettable("MyCompany.Aries.Game.World.WorldTrackerServer")
local WorldTrackerServer = WorldTrackerServer:new():Init(world);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldTracker.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

---------------------------
-- create class
---------------------------
local WorldTrackerServer = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.World.WorldTracker"), commonlib.gettable("MyCompany.Aries.Game.World.WorldTrackerServer"))

function WorldTrackerServer:ctor()
end

function WorldTrackerServer:Init(worldserver)
	self.theWorldServer = worldserver;
	return self;
end

-- Spawns a particle
function WorldTrackerServer:SpawnParticle(...)
end

function WorldTrackerServer:TrackAllExistingEntities()
	local entityTracker = self.theWorldServer:GetEntityTracker();
	if(entityTracker) then
		local entities = EntityManager.GetAllEntities();
		for id, entity in pairs(entities) do
			if(entity.isServerEntity) then
				entityTracker:AddEntityToTracker(entity);
			end
		end
	end
end



-- Called on when an entity is created or loaded. On client worlds, starts downloading any
-- necessary textures. On server worlds, adds the entity to the entity tracker.
function WorldTrackerServer:OnEntityCreate(entity)
	if(entity.isServerEntity) then
	    self.theWorldServer:GetEntityTracker():AddEntityToTracker(entity);
	end
end

-- Called when an entity is unloaded or destroyed. On client worlds, releases any downloaded
-- textures. On server worlds, removes the entity from the entity tracker.
function WorldTrackerServer:OnEntityDestroy(entity)
	if(entity.isServerEntity) then
		self.theWorldServer:GetEntityTracker():RemoveEntityFromAllTrackingPlayers(entity);
	end
end

-- Called when an entity becomes a server entity or vice versa
function WorldTrackerServer:OnSetServerEntity(entity)
	if(entity.isServerEntity) then
		self.theWorldServer:GetEntityTracker():AddEntityToTracker(entity);
	else
		self.theWorldServer:GetEntityTracker():RemoveEntityFromAllTrackingPlayers(entity);
	end
end


-- Plays the specified sound. 
function WorldTrackerServer:PlaySound(soundName, x, y, z, volume, pitch)
    self.theWorldServer:GetServerManager():SendToAllNear(x,y,z, if_else(volume > 1, 16*volume, 16), 
		self.theWorldServer.dimensionId, Packets.PacketLevelSound:new():Init(soundName, x, y, z, volume, pitch));
end

-- Plays sound to all near players except the player reference given
function WorldTrackerServer:PlaySoundToNearExcept(entityPlayer, soundName, x, y, z, volume, pitch)
    self.theWorldServer:GetServerManager():SendToAllNearExcept(entityPlayer, x,y,z, 
		if_else(volume > 1, 16*volume, 16), self.theWorldServer.dimensionId, Packets.PacketLevelSound:new():Init(soundName, x, y, z, volume, pitch));
end

-- On the client, re-renders the block. On the server, sends the block to the client (which will re-render it),
-- including the tile entity description packet if applicable. 
function WorldTrackerServer:MarkBlockForUpdate(x, y, z)
    self.theWorldServer:GetPlayerManager():MarkBlockForUpdate(x,y,z);
end

-- on client does nothing, on server broadcase to observing client
function WorldTrackerServer:OnChunkGenerated(chunkX, chunkZ)
	self.theWorldServer:GetPlayerManager():OnChunkGenerated(chunkX, chunkZ);
end

-- Plays the specified record
function WorldTrackerServer:PlayRecord(name, x,y,z)
end

function WorldTrackerServer:BroadcastSound(id, x, y, z, data)
    self.theWorldServer:GetServerManager():SendPacketToAllPlayers(Packets.PacketDoorChange:new():Init(id, x, y, z, data, true));
end

-- Starts (or continues) destroying a block with given ID at the given coordinates for the given partially destroyed value
function WorldTrackerServer:DestroyBlockPartially(entityId, x,y,z, destroyedStage)
    local playerList = self.theWorldServer:GetEntityTracker().playerEntityList;

    for i = 1, #(playerList) do
        local player = playerList[i];
        if (player and player.worldObj == self.theWorldServer and player.entityId ~= entityId) then
            local dx = x - player.bx;
            local dy = y - player.by;
            local dz = z - player.bz;

            if ((dx * dx + dy * dy + dz * dz) < 1024) then
                player:SendPacketToPlayer(Packets.PacketBlockDestroy(entityId, x,y,z, destroyedStage));
            end
        end
    end
end