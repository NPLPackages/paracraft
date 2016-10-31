--[[
Title: Chunk keep data both on Lua and C++
Author(s): LiXizhi
Date: 2013/8/27
Desc: 16*16(*256) block columns
Since LuaJit is very fast. we will keep data on lua as well, to eliminate all ParaTerrain.GetBlockTemplateByIdx calls. 
ParaTerrain.SetBlockTemplateByIdx is still the performance bottle neck. 
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkCpp.lua");
local ChunkCpp = commonlib.gettable("MyCompany.Aries.Game.World.ChunkCpp");
-----------------------------------------------
]]
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/ide/math/bit.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/Section.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/UniversalCoords.lua");
local UniversalCoords = commonlib.gettable("MyCompany.Aries.Game.Common.UniversalCoords");
local Section = commonlib.gettable("MyCompany.Aries.Game.World.Section");
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");

local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

local tostring = tostring;
local format = format;
local type = type;

if(not ParaTerrain) then
	return;
end
local ParaTerrain_SetBlockTemplateByIdx = ParaTerrain.SetBlockTemplateByIdx;
local ParaTerrain_GetBlockTemplateByIdx = ParaTerrain.GetBlockTemplateByIdx;
local ParaTerrain_SetBlockUserDataByIdx = ParaTerrain.SetBlockUserDataByIdx;
local ParaTerrain_GetBlockUserDataByIdx = ParaTerrain.GetBlockUserDataByIdx;

-- for performance testing
--ParaTerrain_SetBlockTemplateByIdx = function() end
--ParaTerrain_GetBlockTemplateByIdx = function() return 0 end

local Chunk = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.World.ChunkCpp"))

local HALFSIZE = 16 * 16 * 128;

Chunk.Persistent = true;

-- containing world manager
Chunk.World = nil;
-- universal coords
Chunk.Coords = nil;

function Chunk:ctor()
	self._BiomesArray = {};
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

-- clear up all data during world generation. 
function Chunk:Clear()
	-- self._BiomesArray = {};
end


function Chunk:GetBlockId(coords)
	return ParaTerrain_GetBlockTemplateByIdx(coords.WorldX, coords.WorldY, coords.WorldZ);
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
	ParaTerrain.SetChunkColumnTimeStamp(self.Coords.WorldX, self.Coords.WorldZ, self.timeStamp);
end

function Chunk:GetTimeStamp()
	-- cache result in self.timeStamp to accelerate for next call. 
	if(not self.timeStamp or self.timeStamp<0) then
		self.timeStamp = ParaTerrain.GetChunkColumnTimeStamp(self.Coords.WorldX, self.Coords.WorldZ);
	end
	return self.timeStamp;
end

function Chunk:GetBlockIdByPos(blockX, blockY, blockZ)
	return ParaTerrain_GetBlockTemplateByIdx(self.Coords.WorldX+blockX, self.Coords.WorldY+blockY, self.Coords.WorldZ+blockZ);
end

function Chunk:GetData(coords)
	return ParaTerrain_GetBlockUserDataByIdx(coords.WorldX, coords.WorldY, coords.WorldZ);
end

-- alias: SetData(coords, data)
-- @param blockX: coordinates or int
function Chunk:SetData(blockX, blockY, blockZ, data)
	if(blockZ) then
		ParaTerrain_SetBlockUserDataByIdx(self.Coords.WorldX+blockX, self.Coords.WorldY+blockY, self.Coords.WorldZ+blockZ, data or 0);
	elseif(blockY) then
		local coords = blockX;
		data = blockY;
		ParaTerrain_SetBlockUserDataByIdx(coords.WorldX, coords.WorldY, coords.WorldZ, data or 0);
	end
end

-- @param pos: section_id
function Chunk:AddNewSection(pos)
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
	-- echo({"SetBlock", self.Coords.WorldX+blockX, self.Coords.WorldY+blockY, self.Coords.WorldZ+blockZ, block_id});
	ParaTerrain_SetBlockTemplateByIdx(self.Coords.WorldX+blockX, self.Coords.WorldY+blockY, self.Coords.WorldZ+blockZ, block_id or 0);
end

-- @param needsUpdate: default to true
function Chunk:SetTypeByCoords(coords, block_id, needsUpdate)
	ParaTerrain_SetBlockTemplateByIdx(coords.WorldX, coords.WorldY, coords.WorldZ, block_id or 0);
end

function Chunk:BlockNeedsUpdate(blockX, blockY, blockZ)
	-- LOG.std(nil, "debug", "Chunk", "BlockNeedsUpdate Chunk(%d, %d) %d, %d, %d", self.Coords:GetChunkX(), self.Coords:GetChunkZ(), blockX, blockY, blockZ);
end

function Chunk:GetMapChunkData(bIncludeInit, verticalSectionFilter)
	return ParaTerrain.GetMapChunkData(self.Coords:GetChunkX(), self.Coords:GetChunkZ(), bIncludeInit, verticalSectionFilter);
end

-- @param index: [0, 4096)  16*16*16
local function UnpackBlockIndex(index)
	local cy = rshift(index, 8);
	index = band(index, 0xff);
	local cz = rshift(index, 4);
	local cx = band(index, 0xf);
	return cx, cy, cz;
end

function Chunk:ApplyMapChunkData(chunkData, verticalSectionFilter)
	local modified_blocks = {};
	
	ParaTerrain.ApplyMapChunkData(self.chunkX, self.chunkZ, verticalSectionFilter, chunkData, modified_blocks);
	-- echo({"Chunk:ApplyMapChunkData", modified_blocks, self.chunkX, self.chunkZ,})

	local removeList = modified_blocks["remove"];
	local addList = modified_blocks["add"];
	local addDataList = modified_blocks["addData"];
	local modDataList = modified_blocks["modData"];

	local worldX = self.Coords.WorldX;
	local worldZ = self.Coords.WorldZ;
	
	-- a block is deleted or replaced
	if(removeList) then
		local packedIndex, block_id;
		packedIndex, block_id = next(removeList, packedIndex)
		while(packedIndex) do
			local chunkY = band(packedIndex, 0xf);
			local x, y, z = UnpackBlockIndex(rshift(packedIndex,4));
			x = worldX+x;
			y = chunkY*16+y;
			z = worldZ+z;
			local block_template = block_types.get(block_id);
			if(block_template) then
				if(not block_template.cubeMode and block_template.customModel) then
					block_template:DeleteModel(x,y,z);
				end
				block_template:OnBlockRemoved(x,y,z,block_id, 0);
			end

			packedIndex, block_id = next(removeList, packedIndex)
		end
	end

	-- new block is added
	if(addList) then
		local packedIndex, block_id;
		packedIndex, block_id = next(addList, packedIndex);
		while(packedIndex) do
			local chunkY = band(packedIndex, 0xf);
			local x, y, z = UnpackBlockIndex(rshift(packedIndex,4));
			x = worldX+x;
			y = chunkY*16+y;
			z = worldZ+z;
			local block_template = block_types.get(block_id);
			if(block_template) then
				local block_data = addDataList[packedIndex] or 0;
				if(not block_template.cubeMode and block_template.customModel) then
					block_template:UpdateModel(x,y,z, block_data)
				end
				block_template:OnBlockAdded(x,y,z, block_data);
			end

			packedIndex, block_id = next(addList, packedIndex)
		end
	end
	-- only data field is changed, block id is not changed
	if(modDataList) then
		local packedIndex, block_data;
		packedIndex, block_data = next(modDataList, packedIndex);
		while(packedIndex) do
			local chunkY = band(packedIndex, 0xf);
			local x, y, z = UnpackBlockIndex(rshift(packedIndex,4));
			x = worldX+x;
			y = chunkY*16+y;
			z = worldZ+z;
			local block_template = block_types.get(block_id);
			if(block_template) then
				if(not block_template.cubeMode and block_template.customModel) then
					block_template:UpdateModel(x,y,z, block_data)
				end
			end
			packedIndex, block_data = next(modDataList, packedIndex);
		end
	end

	local timeStamp = self:GetTimeStamp();
	if(timeStamp <= 0) then
		self:SetTimeStamp(1);
		-- LOG.std(nil, "debug", "Chunk", "chunk %d %d loaded from ApplyMapChunkData. last time stamp: %d", self.chunkX, self.chunkZ, timeStamp);
	end
end


function Chunk:FillChunk(chunkData, verticalSectionFilter, hasAdditionalData)
	self:ApplyMapChunkData(chunkData, verticalSectionFilter)
	local results = {};
	-- tricky negative chunkY is actually verticalSectionFilter.
	ParaTerrain.GetBlocksInRegion(self.chunkX, -verticalSectionFilter, self.chunkZ, self.chunkX, -verticalSectionFilter, self.chunkZ, block.attributes.onload, results);
	if(results.count and results.count>0) then
		local results_x, results_y, results_z, results_tempId, results_data = results.x, results.y, results.z, results.tempId, results.data;
		for i = 1, results.count do
			local x,y,z,block_id, block_data = results_x[i], results_y[i], results_z[i], results_tempId[i], results_data[i];
			if(x and block_id) then
				local block_template = block_types.get(block_id);
				-- exclude cubeModel
				if(block_template) then
					block_template:OnBlockLoaded(x,y,z, block_data);
				end
			end
		end
	end
end

function Chunk:ResetRelightChecks()
end

function Chunk:IsEmpty()
	return false;
end

function Chunk:OnChunkUnload()
	-- TODO:
end
