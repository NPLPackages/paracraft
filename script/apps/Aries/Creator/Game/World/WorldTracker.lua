--[[
Title: WorldTracker
Author(s): LiXizhi
Date: 2014/7/2
Desc: base class for tracking major world changes like block and entity changes and send those changes to remote world. 
Each World can has multiple world trackers (in most cases just one). 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldTracker.lua");
local WorldTracker = commonlib.gettable("MyCompany.Aries.Game.World.WorldTracker")
local WorldTracker = WorldTracker:new():Init(world);
-------------------------------------------------------
]]
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

---------------------------
-- create class
---------------------------
local WorldTracker = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.World.WorldTracker"))

function WorldTracker:ctor()
	self.bEnabled = true;
end

function WorldTracker:Init()
	return self;
end

function WorldTracker:EnableTracker(bEnabled)
	self.bEnabled = bEnabled;
end

function WorldTracker:IsEnabled()
	return self.bEnabled;
end

-- Spawns a particle
function WorldTracker:SpawnParticle(...)
end

-- Called on when an entity is created or loaded. On client worlds, starts downloading any
-- necessary textures. On server worlds, adds the entity to the entity tracker.
function WorldTracker:OnEntityCreate(entity)
end

-- Called when an entity is unloaded or destroyed. On client worlds, releases any downloaded
-- textures. On server worlds, removes the entity from the entity tracker.
function WorldTracker:OnEntityDestroy(entity)
end

-- Called when an entity becomes a server entity or vice versa. Only called when property is changed and after entity is attached. 
function WorldTracker:OnSetServerEntity(entity)
end

-- Plays the specified sound.
function WorldTracker:PlaySound(soundName, x, y, z, volume, pitch)
end    

-- Plays sound to all near players except the player reference given
function WorldTracker:PlaySoundToNearExcept(entityPlayer, soundName, x, y, z, volume, pitch)
end

-- On the client, re-renders all blocks in this range, inclusive. On the server, does nothing.
function WorldTracker:MarkBlockRangeForRenderUpdate(min_x, min_y, min_z, max_x, max_y, max_z)
end

-- On the client, re-renders the block. On the server, sends the block to the client (which will re-render it),
-- including the tile entity description packet if applicable. 
function WorldTracker:MarkBlockForUpdate(x, y, z)
end

-- On the client, re-renders this block. On the server, does nothing. 
function WorldTracker:MarkBlockForRenderUpdate(x,y,z)
end

-- on client does nothing, on server broadcase to observing client
function WorldTracker:OnChunkGenerated(chunkX, chunkZ)
end

-- Plays the specified record
function WorldTracker:PlayRecord(name, x,y,z)
end

function WorldTracker:BroadcastSound(id, x, y, z, data)
end

-- virtual: set new damage to a given block
-- @param damage: [1-10), other values will remove it. 
function WorldTracker:DestroyBlockPartially(entityId, x,y,z, damage)
end

