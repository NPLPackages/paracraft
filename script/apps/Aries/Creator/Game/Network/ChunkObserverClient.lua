--[[
Title: Chunk observer client
Author(s): LiXizhi
Date: 2014/7/18
Desc: only works on client side for the default player. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ChunkObserverClient.lua");
local ChunkObserverClient = commonlib.gettable("MyCompany.Aries.Game.Network.ChunkObserverClient");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ChunkLocation.lua");
NPL.load("(gl)script/ide/math/bit.lua");
local ChunkLocation = commonlib.gettable("MyCompany.Aries.Game.Common.ChunkLocation");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");

local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

local ChunkObserverClient = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Network.ChunkObserverClient"));

function ChunkObserverClient:ctor()
	self.locationOfBlockChange = {};
	self.numBlocksToUpdate = 0;
	self.blocksToUpdate = commonlib.UnorderedArray:new();
	self.lastSendTime = 0;
end

function ChunkObserverClient:Init(playerManager, chunkX, chunkZ)
	self.thePlayerManager = playerManager;
	self.chunkLocation = ChunkLocation:FromChunkPos(chunkX, chunkZ);
	return self;
end

function ChunkObserverClient:GetChunkLocation()
	return self.chunkLocation;
end

-- @param x, y, z: relative to chunk x,z in [0,64)
function ChunkObserverClient:FlagChunkForUpdate(x, y, z)
	local localChunkPackedPos = (lshift(x,12) + lshift(z,8) + y);
	if(not self.blocksToUpdate:contains(localChunkPackedPos)) then
		self.blocksToUpdate:add(localChunkPackedPos);
		self.numBlocksToUpdate = #(self.blocksToUpdate);
	end
end

-- get the associated chunk object
function ChunkObserverClient:GetMyChunk()
	return self.thePlayerManager:GetWorldClient():GetChunkFromChunkCoords(self.chunkLocation.chunkX, self.chunkLocation.chunkZ)
end

function ChunkObserverClient:UpdateChunkTime(chunk)
	chunk = chunk or self:GetMyChunk();
	if(chunk) then
		local curTime = self.thePlayerManager:GetWorldClient():GetWorldInfo():GetWorldTotalTime();
		chunk.elapsedTime = chunk.elapsedTime + curTime - (self.lastUpdateTime or curTime);
		self.lastUpdateTime = curTime;
	end
end

-- sends the packet to all players in the current instance
function ChunkObserverClient:SendPacketToServer(packet)
	self.thePlayerManager:GetWorldClient():GetPlayer():AddToSendQueue(packet);
end

-- send block entities
function ChunkObserverClient:UpdateBlockEntity(blockEntity)
	if (blockEntity) then
        local packet = blockEntity:GetDescriptionPacket();
        if (packet) then
            self:SendPacketToServer(packet);
        end
    end
end

function ChunkObserverClient:IsEmpty()
	return (self.numBlocksToUpdate == 0)
end

function ChunkObserverClient:GetLastSendTime()
	return self.lastSendTime;
end

-- called by periodically
function ChunkObserverClient:SendChunkUpdate()
	if (self.numBlocksToUpdate ~= 0) then
		local chunkLocation = self.chunkLocation;
        if (self.numBlocksToUpdate == 1) then
			local packedIndex = self.blocksToUpdate[1];
            x = chunkLocation.chunkX * 16 + band(rshift(packedIndex, 12), 15);
            y = band(packedIndex, 255);
            z = chunkLocation.chunkZ * 16 + band(rshift(packedIndex, 8), 15);

            self:SendPacketToServer(Packets.PacketBlockChange:new():Init(x, y, z));

			local blockEntity = BlockEngine:GetBlockEntity(x,y,z);
            if (blockEntity) then
                self:UpdateBlockEntity(blockEntity);
            end
        else
            self:SendPacketToServer(Packets.PacketBlockMultiChange:new():Init(chunkLocation.chunkX, chunkLocation.chunkZ, self.blocksToUpdate, self.numBlocksToUpdate));
            for i = 1, #(self.blocksToUpdate) do 
				local packedIndex = self.blocksToUpdate[i];
				x = chunkLocation.chunkX * 16 + band(rshift(packedIndex, 12), 15);
				y = band(packedIndex, 255);
				z = chunkLocation.chunkZ * 16 + band(rshift(packedIndex, 8), 15);

				local blockEntity = BlockEngine:GetBlockEntity(x,y,z);
				if (blockEntity) then
					self:UpdateBlockEntity(blockEntity);
				end
            end
        end
        self.numBlocksToUpdate = 0;
		self.blocksToUpdate:clear();
		self.lastSendTime = self.lastUpdateTime or 0;
    end
end