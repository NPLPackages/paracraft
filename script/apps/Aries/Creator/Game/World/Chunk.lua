--[[
Title: Chunk column
Author(s): LiXizhi
Date: 2013/8/27
Desc: This is in-memory implementation of Chunk column. 
A chunk column contains 16*16(*256) blocks. 
Each vertical section contains 16^3 blocks. 
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/Chunk.lua");
local Chunk = commonlib.gettable("MyCompany.Aries.Game.World.Chunk");

chunkData = Chunk:new():InitFromChunkData(chunkData);
for worldX, worldY, worldZ, block_id in chunkData:EachBlockW() do
	ParaTerrain.SetBlockTemplateByIdx(worldX, worldY, worldZ, block_id);
end
-----------------------------------------------
]]
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/ide/math/bit.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/Section.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/UniversalCoords.lua");
local UniversalCoords = commonlib.gettable("MyCompany.Aries.Game.Common.UniversalCoords");
local Section = commonlib.gettable("MyCompany.Aries.Game.World.Section");

local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

local tostring = tostring;
local format = format;
local type = type;

-- for performance testing
--ParaTerrain_SetBlockTemplateByIdx = function() end
--ParaTerrain_GetBlockTemplateByIdx = function() return 0 end

local Chunk = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.World.Chunk"))

local HALFSIZE = 16 * 16 * 128;

Chunk.Persistent = true;

-- containing world manager
Chunk.World = nil;
-- universal coords
Chunk.Coords = nil;

function Chunk:ctor()
	self._Sections = {};
	self._BiomesArray = {};
	self.elapsedTime= 0;
end

function Chunk:Init(world, chunkX, chunkZ)
	self.World = world;
	self.Coords = UniversalCoords:new():FromChunk(chunkX, chunkZ);
	self.chunkX = chunkX;
	self.chunkZ = chunkZ;
	self.elapsedTime= 0;
	return self;
end

-- @param data: is actually another chunk without meta tables. 
function Chunk:InitFromChunkData(data)
	self.chunkX = data.chunkX;
	self.chunkZ = data.chunkZ;
	self.elapsedTime = data.elapsedTime;
	self._Sections = data._Sections;
	self._BiomesArray = data._BiomesArray;
	return self;
end

-- @param index: [0, 4096)  16*16*16
local function UnpackBlockIndex(index)
	local cy = rshift(index, 8);
	index = band(index, 0xff);
	local cz = rshift(index, 4);
	local cx = band(index, 0xf);
	return cx, cy, cz;
end

-- iterator (worldX, worldY, worldZ, block_id) of all blocks in the chunk
-- block pos is in world coordinate system
function Chunk:EachBlockW()
	local iSection, section = next(self._Sections, nil)
	local packedIndex, block_id;
	
	local worldXOffset = self.chunkX*16;
	local worldYOffset = (iSection or 0)*16;
	local worldZOffset = self.chunkZ*16;
	return function()
		if(section) then
			packedIndex, block_id = next(section, packedIndex);
			if(not packedIndex) then
				iSection, section = next(self._Sections, iSection);
				if(section) then
					worldYOffset = iSection*16;
					packedIndex, block_id = next(section, packedIndex);
				end
			end
		end
		if(packedIndex) then
			local worldX, worldY, worldZ = UnpackBlockIndex(packedIndex);
			return worldXOffset+worldX, worldYOffset+worldY, worldZOffset+worldZ, block_id;
		end
	end
end

-- @param x,y,z: in world coordinates
-- @param side: 4 upward, 5 downward
-- @return the distance to first block.
function Chunk:FindFirstBlock(x, y, z, side, max_dist)
	x = x - self.chunkX*16;
	z = z - self.chunkZ*16;
	max_dist = max_dist or 256;
	local dist = 0;

	-- skip first block when dist==0
	dist = dist + 1;
	if(side == 4) then
		y = y + 1;
	elseif(side == 5) then
		y = y - 1;
	else
		return -1;
	end

	while(y>=0 and y <= 256 and dist <= max_dist) do
		local section = self._Sections[rshift(y, 4)];
		if (not section) then
			if(side == 4) then
				local new_y = band(y, 0xff0) + 16;
				dist = dist + (new_y - y);
				y = new_y;
			elseif(side == 5) then
				new_y = band(y, 0xff0) - 1;
				dist = dist + (y-new_y);
				y = new_y;
			else
				return -1;
			end
		else
			local block_id = section[bor(lshift(band(y,0xF), 8),  bor(lshift(z, 4), x))] or 0;
			if(block_id == 0) then
				dist = dist + 1;
				if(side == 4) then
					y = y + 1;
				elseif(side == 5) then
					y = y - 1;
				else
					return -1;
				end
			else
				return dist;
			end
		end
	end
	return -1;
end

function Chunk:InitBlockChangesTimer()
end

function Chunk:Dispose()
end

function Chunk:MarkToSave()
	
end

function Chunk:GetBlockId(coords)
	local section = self._Sections[rshift(coords:GetBlockY(), 4)];
	if (not section) then
		return 0; -- empty
	end
	return section[coords.SectionPackedCoords] or 0;
end

-- @param blockX: X or coords. if coords Y,Z should be nil.
function Chunk:GetType(blockX, blockY, blockZ)
	if(not blockY) then
		return self:GetBlockId(blockX)
	else
		return self:GetBlockIdByPos(blockX, blockY, blockZ)
	end
end

function Chunk:SetTimeStamp(time_stamp)
	self.timeStamp = time_stamp or 1;
end

function Chunk:GetTimeStamp()
	-- cache result in self.timeStamp to accelerate for next call. 
	return self.timeStamp or 0;
end

function Chunk:GetBlockIdByPos(blockX, blockY, blockZ)
	local section = self._Sections[rshift(blockY, 4)];
	if (not section) then
		return 0; -- empty
	end
	return section[bor(lshift(band(blockY,0xF), 8),  bor(lshift(blockZ, 4), blockX))] or 0;
end

function Chunk:GetData(coords)
	-- TODO:
	return 0;
end

-- alias: SetData(coords, data)
-- @param blockX: coordinates or int
function Chunk:SetData(blockX, blockY, blockZ, data)
	-- TODO:
end

-- @param pos: section_id
function Chunk:AddNewSection(pos)
	-- local section = Section.Load(self, pos);
	local section = {};
	self._Sections[pos] = section;
	return section;
end

function Chunk:SetBiomeColumn(x, z, biomeId)
    self._BiomesArray[z*16 + x] = biomeId;
end

function Chunk:OnSetType(blockX, blockY, blockZ, block_id)
end

function Chunk:OnSetTypeByCoords(coords, block_id)
end

function Chunk:SetType(blockX, blockY, blockZ, block_id, needsUpdate)
	
	local sectionId = rshift(blockY, 4);
	local section = self._Sections[sectionId];

	if (not section ) then
		if (block_id ~= 0) then
			section = self:AddNewSection(sectionId);
		else
			return;
		end
	end
	section[bor(lshift(band(blockY, 0xF), 8), bor(lshift(blockZ, 4),  blockX)) ] = block_id;
	self:OnSetType(blockX, blockY, blockZ, block_id);
	if (needsUpdate~=false) then
		self:BlockNeedsUpdate(blockX, blockY, blockZ);
	end
end

-- @param needsUpdate: default to true
function Chunk:SetTypeByCoords(coords, block_id, needsUpdate)
	local sectionId = rshift(coords.WorldY, 4);
	local section = self._Sections[sectionId];

	if (not section ) then
		if (block_id ~= 0) then
			section = self:AddNewSection(sectionId);
		else
			return;
		end
	end
	section[coords.SectionPackedCoords] = block_id;
	self:OnSetTypeByCoords(coords, block_id);

	if (needsUpdate~=false) then
		self:BlockNeedsUpdate(coords:GetBlockX(), coords:GetBlockY(), coords:GetBlockZ());
	end
end

function Chunk:BlockNeedsUpdate(blockX, blockY, blockZ)
	-- LOG.std(nil, "debug", "Chunk", "BlockNeedsUpdate Chunk(%d, %d) %d, %d, %d", self.Coords:GetChunkX(), self.Coords:GetChunkZ(), blockX, blockY, blockZ);
end


-- this function matches exactly with the C++ implementation of same function. 
function Chunk:GetMapChunkData(bIncludeInit, verticalSectionFilter)
	verticalSectionFilter = verticalSectionFilter or 0xffff;
	NPL.load("(gl)script/apps/Aries/Creator/Game/Common/BlockDataCodec.lua");
	local SameIntegerEncoder = commonlib.gettable("MyCompany.Aries.Game.Common.SameIntegerEncoder");
	local outputStream = ParaIO.open("<memory>", "w");

	-- append version format
	outputStream:WriteString("chunkV1");
	local nChunkSize = 0;
	local nChunkSizeLocation = outputStream:GetFileSize();
	outputStream:WriteInt(nChunkSize);
		
	local blockIdEncoder = SameIntegerEncoder:new():init(outputStream);
	local blockDataEncoder = SameIntegerEncoder:new():init(outputStream);

	for y = 0, 15 do
		if ( band(verticalSectionFilter, lshift(1,y)) ~= 0) then
			outputStream:WriteInt(y);
			local nBlockCount = 0;
			local nBlockCountIndex = outputStream:GetFileSize();
			outputStream:WriteInt(nBlockCount);
			local pChunk = self._Sections[y];
			if (pChunk and next(pChunk)) then
				blockIdEncoder:Reset();
				local nCount = 4096;
				for i = 0, nCount-1 do
					local blockId = pChunk[i];
					if (blockId) then
						blockIdEncoder:Append(blockId);
						nBlockCount = nBlockCount + 1;
					else
						blockIdEncoder:Append(0);
					end
				end
				blockIdEncoder:Finalize();
				-- TODO: data not supported at the moment. 
				blockDataEncoder:Reset();
				blockDataEncoder:Append(0, 4096);
				blockDataEncoder:Finalize();
			else
				blockIdEncoder:Reset();
				blockIdEncoder:Append(0, 4096);
				blockIdEncoder:Finalize();
				blockDataEncoder:Reset();
				blockDataEncoder:Append(0, 4096);
				blockDataEncoder:Finalize();
			end
			outputStream:seek(nBlockCountIndex);
			outputStream:WriteInt(nBlockCount);
			outputStream:SetFilePointer(0, 2); -- 2 is relative to end of file
		end
	end
	outputStream:seek(nChunkSizeLocation);
	outputStream:WriteInt(outputStream:GetFileSize() - nChunkSizeLocation - 4);
	outputStream:SetFilePointer(0, 2); -- 2 is relative to end of file
	local data = outputStream:GetText(0, -1);
	outputStream:close();
	return data;
end

function Chunk:ApplyMapChunkData(chunkData, verticalSectionFilter)
end

function Chunk:FillChunk(chunkData, verticalSectionFilter, hasAdditionalData)
end

function Chunk:ResetRelightChecks()
end

function Chunk:IsEmpty()
	return true;
end

function Chunk:OnChunkUnload()
end
