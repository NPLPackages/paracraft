--[[
Title: PlayerManager
Author(s): LiXizhi
Date: 2014/6/4
Desc: all chunk observers on the servers are managed here. It will send update to the server.
And keeps all chunk observers active for each playerMP in their visible chunk radius. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/PlayerManager.lua");
local PlayerManager = commonlib.gettable("MyCompany.Aries.Game.Network.PlayerManager");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/bit.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ChunkObserver.lua");
local ChunkObserver = commonlib.gettable("MyCompany.Aries.Game.Network.ChunkObserver");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

local PlayerManager = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Network.PlayerManager"));

-- x, z direction vectors: east, south, west, north
local xzDirectionsConst = {{1, 0}, {0, 1}, {-1, 0}, {0, -1}};

function PlayerManager:ctor()
	-- Number of chunks the server sends to the client. in range [3,15]
	self.playerChunkViewRadius = self.playerChunkViewRadius or 5;
	-- player list
	self.players = commonlib.UnorderedArraySet:new();
	-- all chunks that is being watched. 
	self.chunkObservers = {};
	-- chunks with players in it. 
	self.chunkObserversWithPlayers = commonlib.UnorderedArraySet:new();
	self.lastSendUpdateTime = 0;
end

function PlayerManager:Init(worldserver, view_distance)
	self.worldserver = worldserver;
	self.view_distance = view_distance;
	return self;
end

function PlayerManager:GetWorldServer()
	return self.worldserver;
end

function PlayerManager:IsPlayerWatchingChunk(entityMP, chunkX, chunkZ)
	return true;
end

function PlayerManager:GetChunkObservers()
    return self.chunkObservers;
end

-- retrun chunk observers that has changes since last tick
function PlayerManager:GetChunkObserversWithPlayers()
    return self.chunkObserversWithPlayers;
end

function PlayerManager:GetOrCreateChunkObserver(chunkX, chunkZ, bCreateIfNotExist)
    local chunkIndex = chunkX * 4096 +  chunkZ;
    local chunkObserver = self.chunkObservers[chunkIndex];

    if (not chunkObserver and bCreateIfNotExist) then
        chunkObserver = ChunkObserver:new():Init(self, chunkX, chunkZ);
        self.chunkObservers[chunkIndex] = chunkObserver;
    end

    return chunkObserver;
end

-- Called by WorldManager:MarkBlockForUpdate; marks a block to be resent to clients.
function PlayerManager:MarkBlockForUpdate(x,y,z)
    local chunkX = rshift(x, 4);
    local chunkZ = rshift(z, 4);
    local chunkObserver = self:GetOrCreateChunkObserver(chunkX, chunkZ, false);

    if (chunkObserver) then
        chunkObserver:FlagChunkForUpdate(band(x, 15), y, band(z,15));
    end
end

-- a chunk is regenerated, we need to send it to all observing clients
function PlayerManager:OnChunkGenerated(chunkX, chunkZ)
	local chunkObserver = self:GetOrCreateChunkObserver(chunkX, chunkZ)
	if (chunkObserver and chunkObserver:GetPlayerCount() > 0) then
		chunkObserver:FlagChunkForUpdate();
	end
end

-- call this function on server tick to send chunk updates to all observing players
function PlayerManager:SendAllChunkUpdates()
    local curTime = self:GetWorldServer():GetWorldInfo():GetWorldTotalTime();
    
    if (curTime - self.lastSendUpdateTime > 8000) then
        self.lastSendUpdateTime = curTime;
        for i, chunkObserver in pairs(self.chunkObservers) do
            chunkObserver:SendChunkUpdate();
            chunkObserver:UpdateChunkTime();
        end
    else
		for _, chunkObserver in ipairs(self.chunkObserversWithPlayers) do
            chunkObserver:SendChunkUpdate();
        end
    end
    self.chunkObserversWithPlayers:clear();

    if (self.players:empty()) then
		-- unload all chunks if no player is in the chunk.
        self:GetWorldServer():GetChunkProvider():UnloadAllChunks();
    end
end

-- Adds an EntityPlayerMP to the PlayerManager.
function PlayerManager:AddPlayer(entityPlayer)
	local x,y,z = entityPlayer:GetBlockPos();
    local chunkX = rshift(x, 4);
    local chunkZ = rshift(z, 4);
    entityPlayer.managedPosBX = entityPlayer.x;
    entityPlayer.managedPosBZ = entityPlayer.z;

    for cx = chunkX - self.playerChunkViewRadius, chunkX + self.playerChunkViewRadius do
        for cz = chunkZ - self.playerChunkViewRadius, chunkZ + self.playerChunkViewRadius do
            self:GetOrCreateChunkObserver(cx, cz, true):AddPlayer(entityPlayer);
        end
    end

    self.players:add(entityPlayer);
    self:FilterChunkLoadQueue(entityPlayer);
end

-- remove EntityPlayerMP when it disconnects
function PlayerManager:RemovePlayer(entityPlayer)
	local chunkX = rshift(entityPlayer.managedPosBX, 4);
    local chunkZ = rshift(entityPlayer.managedPosBZ, 4);
	local chunkViewRadius = self.playerChunkViewRadius;

    for cx = chunkX - chunkViewRadius, chunkX + chunkViewRadius do
		for cz = chunkZ - chunkViewRadius, chunkZ + chunkViewRadius do
            local chunkObserver = self:GetOrCreateChunkObserver(cx, cz, false);
            if (chunkObserver) then
                chunkObserver:RemovePlayer(entityPlayer);
            end
        end
    end
    self.players:removeByValue(entityPlayer);
end

-- Determine if two rectangles centered at the given points overlap for the provided radius. 
function PlayerManager:IsRectOverlap(x1, z1, x2, z2, radius)
    local dx = x1 - x2;
    local dz = z1 - z2;
    return (dx >= -radius and dx <= radius and dz >= -radius and dz <= radius);
end

-- update chunks around a EntityMP player being moved by server logic
-- only update when player has moved enough distance from last update. 
function PlayerManager:UpdateMovingPlayer(entityMP)
	local chunkX = rshift(entityMP.bx, 4);
    local chunkZ = rshift(entityMP.bz, 4);
    local dx = entityMP.managedPosBX - entityMP.bx;
    local dz = entityMP.managedPosBZ - entityMP.bz;
    local distSq = dx * dx + dz * dz;

	-- only update observing chunks when entity has moved 8 blocks since last movement. 
	-- the larger the value, the less mapChunk update packets when player is moving back and force in a region. 
    if (distSq >= 64) then
		local lastChunkX = rshift(entityMP.managedPosBX, 4);
		local lastChunkZ = rshift(entityMP.managedPosBZ, 4);
        local chunkViewRadius = self.playerChunkViewRadius;
        local offsetX = chunkX - lastChunkX;
        local offsetZ = chunkZ - lastChunkZ;

        if (offsetX ~= 0 or offsetZ ~= 0) then
            for cx = chunkX - chunkViewRadius, chunkX + chunkViewRadius do
                for cz = chunkZ - chunkViewRadius, chunkZ + chunkViewRadius do
                    if (not self:IsRectOverlap(cx, cz, lastChunkX, lastChunkZ, chunkViewRadius)) then
						self:GetOrCreateChunkObserver(cx, cz, true):AddPlayer(entityMP);
                    end

                    if (not self:IsRectOverlap(cx - offsetX, cz - offsetZ, chunkX, chunkZ, chunkViewRadius)) then
                        local chunkObserver = self:GetOrCreateChunkObserver(cx - offsetX, cz - offsetZ, false);

                        if (chunkObserver) then
                            chunkObserver:RemovePlayer(entityMP);
                        end
                    end
                end
            end
			self:FilterChunkLoadQueue(entityMP);
            entityMP.managedPosBX = entityMP.bx;
            entityMP.managedPosBZ = entityMP.bz;
        end
    end
end

-- send a packet to all players watching the chunk containing the given position. 
function PlayerManager:SendToObservingPlayers(x,y,z, packet, excludingEntityMP)
	local chunkX = rshift(x, 4);
    local chunkZ = rshift(z, 4);
	local chunkObserver = self:GetOrCreateChunkObserver(chunkX, chunkZ, false);
    if (chunkObserver) then
        chunkObserver:SendPacketToPlayersInChunk(packet, excludingEntityMP);
    end
end

-- Removes all chunks from the given player's chunk load queue that are not in viewing range of the player.
function PlayerManager:FilterChunkLoadQueue(entityMP)
    local lastLoadedChunks = entityMP.loadedChunks:clone();
    
    local chunkViewRadius = self.playerChunkViewRadius;
	local chunkX = rshift(entityMP.bx, 4);
    local chunkZ = rshift(entityMP.bz, 4);

    local packedChunkPos = self:GetOrCreateChunkObserver(chunkX, chunkZ, true):GetChunkLocation():GetPackedChunkPos();

	-- we will remove all loaded chunks, and add only visible ones again. 
    entityMP.loadedChunks:clear();

    if (lastLoadedChunks:contains(packedChunkPos)) then
        entityMP.loadedChunks:add(packedChunkPos);
    end
    
	-- we will add using a spiral rectangle path from the center. 
	local nIndex = 0;
	local dx = 0;
    local dz = 0;
    
    for length = 1, chunkViewRadius * 2 do
        for k = 1, 2 do
			local dir = xzDirectionsConst[(nIndex % 4)+1];
			nIndex = nIndex+1;
            
            for i = 1, length do
                dx = dx + dir[1];
                dz = dz + dir[2];
			    packedChunkPos = self:GetOrCreateChunkObserver(chunkX + dx, chunkZ + dz, true):GetChunkLocation():GetPackedChunkPos();

                if (lastLoadedChunks:contains(packedChunkPos)) then
                    entityMP.loadedChunks:add(packedChunkPos);
                end
            end
        end
    end

    nIndex = (nIndex % 4) + 1;

    for length = 1, chunkViewRadius * 2 do
        dx = dx + xzDirectionsConst[nIndex][1];
        dz = dz + xzDirectionsConst[nIndex][2];
        packedChunkPos = self:GetOrCreateChunkObserver(chunkX + dx, chunkZ + dz, true):GetChunkLocation():GetPackedChunkPos();
        if (lastLoadedChunks:contains(packedChunkPos)) then
            entityMP.loadedChunks:add(packedChunkPos);
        end
    end
end