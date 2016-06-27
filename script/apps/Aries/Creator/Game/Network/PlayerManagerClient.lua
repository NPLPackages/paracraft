--[[
Title: Player Manager Client
Author(s): LiXizhi
Date: 2014/7/18
Desc: Similar to Player Manager, except that it works on client side to manage only the main player
all chunk observers on the client are managed here. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/PlayerManagerClient.lua");
local PlayerManagerClient = commonlib.gettable("MyCompany.Aries.Game.Network.PlayerManagerClient");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/bit.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ChunkObserverClient.lua");
local ChunkObserverClient = commonlib.gettable("MyCompany.Aries.Game.Network.ChunkObserverClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

local PlayerManagerClient = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Network.PlayerManagerClient"));

-- x, z direction vectors: east, south, west, north
local xzDirectionsConst = {{1, 0}, {0, 1}, {-1, 0}, {0, -1}};

function PlayerManagerClient:ctor()
	-- all chunks that has modifications 
	self.chunkObservers = {};
	self.lastSendUpdateTime = 0;
end

function PlayerManagerClient:Init(worldclient)
	self.worldclient = worldclient;
	return self;
end

function PlayerManagerClient:GetWorldClient()
	return self.worldclient;
end

function PlayerManagerClient:GetChunkObservers()
    return self.chunkObservers;
end

function PlayerManagerClient:GetOrCreateChunkObserver(chunkX, chunkZ, bCreateIfNotExist)
    local chunkIndex = chunkX * 4096 +  chunkZ;
    local chunkObserver = self.chunkObservers[chunkIndex];

    if (not chunkObserver and bCreateIfNotExist) then
        chunkObserver = ChunkObserverClient:new():Init(self, chunkX, chunkZ);
        self.chunkObservers[chunkIndex] = chunkObserver;
    end

    return chunkObserver;
end

-- Called by WorldManager:MarkBlockForUpdate; marks a block to be resent to clients.
function PlayerManagerClient:MarkBlockForUpdate(x,y,z)
    local chunkX = rshift(x, 4);
    local chunkZ = rshift(z, 4);
    local chunkObserver = self:GetOrCreateChunkObserver(chunkX, chunkZ, true);

    if (chunkObserver) then
        chunkObserver:FlagChunkForUpdate(band(x, 15), y, band(z,15));
    end
end

function PlayerManagerClient:AreChunksDirty()
	for chunkIndex, chunkObserver in pairs(self.chunkObservers) do
		if(not chunkObserver:IsEmpty()) then
			return true;
		end
    end
end

-- call this function on client tick to send all chunks updates to server
-- @param bForceSend: if true chunk update is sent, otherwise only send at fixed interval.
function PlayerManagerClient:SendAllChunkUpdates(bForceSend)
    local curTime = self:GetWorldClient():GetWorldInfo():GetWorldTotalTime();
    
    if (bForceSend or curTime - self.lastSendUpdateTime > 3) then
        self.lastSendUpdateTime = curTime;
		local remove_chunks;
        for chunkIndex, chunkObserver in pairs(self.chunkObservers) do
			chunkObserver:SendChunkUpdate();
            chunkObserver:UpdateChunkTime();
			if(chunkObserver:IsEmpty() and math.abs(curTime-chunkObserver:GetLastSendTime()) > 8000 ) then
				remove_chunks = remove_chunks or {};
				remove_chunks[#remove_chunks+1] = chunkIndex;
			end
        end
		if(remove_chunks) then
			for i, chunkIndex in ipairs(remove_chunks) do
				self.chunkObservers[chunkIndex] = nil;
			end
		end
    end
end