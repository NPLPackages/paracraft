--[[
Title: Chunk
Author(s): LiXizhi
Date: 2013/8/27
Desc: 16*16(*256) block columns
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/Chunk.lua");
local Chunk = commonlib.gettable("MyCompany.Aries.Game.World.Chunk");
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
	local section = Section.Load(self, pos);
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


function Chunk:GetMapChunkData(bIncludeInit, verticalSectionFilter)
	return;
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
