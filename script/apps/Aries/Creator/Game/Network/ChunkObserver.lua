--[[
Title: Chunk observer
Author(s): LiXizhi
Date: 2014/6/4
Desc: it keeps all server side changes in this chunk as well as a list of all interested players observing this chunk. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ChunkObserver.lua");
local ChunkObserver = commonlib.gettable("MyCompany.Aries.Game.Network.ChunkObserver");
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

-- max number of uncompressed blocks to be sent in a single packet.  default is 64 
local max_uncompressed_blocks = 64;

local ChunkObserver = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Network.ChunkObserver"));

function ChunkObserver:ctor()
	self.playersInChunk = commonlib.UnorderedArraySet:new();
	self.locationOfBlockChange = {};
	self.numBlocksToUpdate = 0;
	self.chunkVerticalChangeBitfield= 0;
	self.blocksToUpdate = commonlib.UnorderedArray:new();
end

function ChunkObserver:Init(playerManager, chunkX, chunkZ)
	self.thePlayerManager = playerManager;
	self.chunkLocation = ChunkLocation:FromChunkPos(chunkX, chunkZ);
	-- TODO: prepare the real chunk
	-- playerManager:GetWorldServer():GetChunkProvider():LoadChunk(chunkX, chunkZ)
	return self;
end

function ChunkObserver:GetChunkLocation()
	return self.chunkLocation;
end

function ChunkObserver:GetPlayerCount()
	return self.playersInChunk:size();
end

-- @param x, y, z: relative to chunk x,z in [0,max_uncompressed_blocks). if nil, the entire chunk is flagged to be updated, rather than individual chunk. 
function ChunkObserver:FlagChunkForUpdate(x, y, z)
	if (self.numBlocksToUpdate == 0) then
		self.thePlayerManager:GetChunkObserversWithPlayers():add(self);
    end

	if(not x) then
		-- update entire chunk.
		self.chunkVerticalChangeBitfield = 0xff;
		self.numBlocksToUpdate = max_uncompressed_blocks;
	else
		-- update only specified block
		self.chunkVerticalChangeBitfield = bor(self.chunkVerticalChangeBitfield, lshift(1, rshift(y,4)));

		if (self.numBlocksToUpdate < max_uncompressed_blocks) then
			local localChunkPackedPos = (lshift(x,12) + lshift(z,8) + y);
			if(not self.blocksToUpdate:contains(localChunkPackedPos)) then
				self.blocksToUpdate:add(localChunkPackedPos);
				self.numBlocksToUpdate = #(self.blocksToUpdate);
			end
		end	
	end
end

function ChunkObserver:AddPlayer(playerMP)
	if (self.playersInChunk:contains(playerMP)) then
		-- player already in chunk
        return;
    else
        if (#(self.playersInChunk) == 0) then
            self.lastUpdateTime = commonlib.TimerManager.GetCurrentTime();
			EntityManager.SetChunkActive(self.chunkLocation:GetPackedChunkPos(), nil, true);
        end
		self.playersInChunk:add(playerMP);
        playerMP.loadedChunks:add(self.chunkLocation:GetPackedChunkPos());
    end
end

-- get the associated chunk object
function ChunkObserver:GetMyChunk()
	return self.thePlayerManager:GetWorldServer():GetChunkFromChunkCoords(self.chunkLocation.chunkX, self.chunkLocation.chunkZ)
end

function ChunkObserver:UpdateChunkTime(chunk)
	chunk = chunk or self:GetMyChunk();
	if(chunk) then
		local curTime = self.thePlayerManager:GetWorldServer():GetWorldInfo():GetWorldTotalTime();
		chunk.elapsedTime = chunk.elapsedTime + curTime - (self.lastUpdateTime or curTime);
		self.lastUpdateTime = curTime;
	end
end

function ChunkObserver:RemovePlayer(playerMP)
    if (self.playersInChunk:contains(playerMP)) then
        local chunk = self:GetMyChunk();
		if(chunk) then
			playerMP:SendPacketToPlayer(Packets.PacketMapChunk:new():Init(chunk, true, 0));
		end
        self.playersInChunk:removeByValue(playerMP);
		playerMP.loadedChunks:removeByValue(self.chunkLocation:GetPackedChunkPos());
		
        if (self.playersInChunk:empty()) then

            local chunkPackedPos = self.chunkLocation:GetPackedChunkPos();
			if(chunk) then
				self:UpdateChunkTime(chunk);
			end
            self.thePlayerManager:GetChunkObservers()[chunkPackedPos] = nil;
            
            if (self.numBlocksToUpdate > 0) then
                self.thePlayerManager:GetChunkObserversWithPlayers():removeByValue(self);
            end
			EntityManager.SetChunkActive(chunkPackedPos, nil, false);
            self.thePlayerManager:GetWorldServer():GetChunkProvider():UnloadChunksIfNotNearSpawn(self.chunkLocation.chunkX, self.chunkLocation.chunkZ);
        end
    end
end

-- sends the packet to all players in the current instance
-- @param excludingEntityMP: excluding the given player, can be nil. 
function ChunkObserver:SendPacketToPlayersInChunk(packet, excludingEntityMP)
	local curChunkPos = self.chunkLocation:GetPackedChunkPos()
	for i=1, #(self.playersInChunk) do
        local entityMP = self.playersInChunk[i];
		
	    if (not entityMP.loadedChunks:contains(curChunkPos) and entityMP~=excludingEntityMP) then
			entityMP:SendPacketToPlayer(packet);
        end
    end
end

function ChunkObserver:BeginUpdateBlockEntity()
	self.isBeginUpdateBlockEntity = true;
	self.packets = nil;
end

function ChunkObserver:EndUpdateBlockEntity()
	if(self.isBeginUpdateBlockEntity) then
		self.isBeginUpdateBlockEntity = false;
		if(self.packets) then
			if(#(self.packets) > 1) then
				self:SendPacketToPlayersInChunk(Packets.PacketMultiple:new():Init(self.packets));
				--LOG.std(nil, "debug", "ChunkObserver", "batch sent %d update block messages", #(self.packets));
			else
				self:SendPacketToPlayersInChunk(self.packets[1]);
				--LOG.std(nil, "debug", "ChunkObserver", "sent %d update block messages", #(self.packets));
			end
			self.packets = nil;
		end
	end
end

-- send block entities
function ChunkObserver:UpdateBlockEntity(blockEntity)
	if (blockEntity and blockEntity:IsBlockEntity()) then
		local packet = blockEntity:GetDescriptionPacket();
		if (packet) then
			if(self.isBeginUpdateBlockEntity) then
				self.packets = self.packets or {};
				self.packets[#self.packets + 1] = packet;
			else
				self:SendPacketToPlayersInChunk(packet);
			end
		end
    end
end

-- called by periodically
function ChunkObserver:SendChunkUpdate()
    if (self.numBlocksToUpdate ~= 0) then
		local chunkLocation = self.chunkLocation;
        if (self.numBlocksToUpdate == 1) then
			local packedIndex = self.blocksToUpdate[1];
            x = chunkLocation.chunkX * 16 + band(rshift(packedIndex, 12), 15);
            y = band(packedIndex, 255);
            z = chunkLocation.chunkZ * 16 + band(rshift(packedIndex, 8), 15);

            self:SendPacketToPlayersInChunk(Packets.PacketBlockChange:new():Init(x, y, z));

			local blockEntity = BlockEngine:GetBlockEntity(x,y,z);
            if (blockEntity) then
                self:UpdateBlockEntity(blockEntity);
            end
        else
            if (self.numBlocksToUpdate >= max_uncompressed_blocks) then
				x = chunkLocation.chunkX * 16;
                z = chunkLocation.chunkZ * 16;
                self:SendPacketToPlayersInChunk(Packets.PacketMapChunk:new():Init(self:GetMyChunk(), false, self.chunkVerticalChangeBitfield));

				self:BeginUpdateBlockEntity();
                for y = 0, 15 do
                    if (band(self.chunkVerticalChangeBitfield,  lshift(1,y)) ~= 0) then
                        local min_y = lshift(y, 4);
                        local entityList = self.thePlayerManager:GetWorldServer():GetEntityListInChunk(chunkLocation.chunkX, chunkLocation.chunkZ);
						if(entityList) then
							for i=1, #entityList do
                        		local blockEntity = entityList[i];
								self:UpdateBlockEntity(blockEntity);
							end
						end
                    end
                end
				self:EndUpdateBlockEntity();
            else
                self:SendPacketToPlayersInChunk(Packets.PacketBlockMultiChange:new():Init(chunkLocation.chunkX, chunkLocation.chunkZ, self.blocksToUpdate, self.numBlocksToUpdate));

				self:BeginUpdateBlockEntity();
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
				self:EndUpdateBlockEntity();
            end
        end
        self.numBlocksToUpdate = 0;
		self.blocksToUpdate:clear();
        self.chunkVerticalChangeBitfield = 0;
    end
end