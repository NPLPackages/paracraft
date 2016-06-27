--[[
Title: Offset world 
Author(s): LiXizhi
Date: 2014/7/26
Desc: Just in case, we wants to offset the world vertically to make room for very low or high blocks. 
This is a very time comsuming job and should be used with care. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/OffsetWorldTask.lua");
local task = MyCompany.Aries.Game.Tasks.OffsetWorldTask:new():Init(2)
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldFileProvider.lua");
local WorldFileProvider = commonlib.gettable("MyCompany.Aries.Game.World.WorldFileProvider");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")

local OffsetWorldTask = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.OffsetWorldTask"));

-- default to 1
OffsetWorldTask.offsetY = 1;

function OffsetWorldTask:ctor()
	
end

function OffsetWorldTask:Init(offsetY)
	self.offsetY = offsetY;
	return self;
end

function OffsetWorldTask:Run()
	self.finished = true;
	local fileprovider = WorldFileProvider:new():Init();
	local offsetY = self.offsetY or 1;
	
	self:BeginProcess();
	local coords = fileprovider:GetAllRegionCoords();

	-- load all regions and entities
	self:LoadAllRegions(coords);

	local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
		-- offset block and entities
		self:OffsetInRegions(coords, offsetY);
		self:EndProcess();
	end})
	mytimer:Change(1000, nil);
end

function OffsetWorldTask:BeginProcess()
	ParaTerrain.GetBlockAttributeObject():CallField("SuspendLightUpdate");
	ParaTerrain.GetBlockAttributeObject():SetField("IsServerWorld", true);
end

function OffsetWorldTask:EndProcess()
	LOG.std(nil, "info", "OffsetBlockInRegion", "finished OffsetWorldTask");
	ParaTerrain.GetBlockAttributeObject():CallField("SuspendLightUpdate");
	-- never resume light update: since it will make the CPU really busy. 
	-- ParaTerrain.GetBlockAttributeObject():CallField("ResumeLightUpdate");
	_guihelper.MessageBox("OffsetWorld finished. Lighting is disabled. Now save the world or discard")
end

function OffsetWorldTask:LoadAllRegions(coords)
	for _, coord in ipairs(coords) do
		ParaBlockWorld.LoadRegion(GameLogic.GetBlockWorld(), coord.WorldX, coord.WorldY, coord.WorldZ);
		EntityManager.GetRegionContainer(coord.WorldX,coord.WorldZ);
	end
end

function OffsetWorldTask:OffsetInRegions(coords, offsetY)
	for _, coord in ipairs(coords) do
		LOG.std(nil, "info", "OffsetBlockInRegion", {coord:GetRegionX(), coord:GetRegionZ()});
		ParaTerrain.GetBlockAttributeObject():CallField("SuspendLightUpdate");
		local chunkX, chunkZ = coord:GetChunkX(), coord:GetChunkZ();
		for cx = 0, 31 do
			for cz = 0, 31 do
				self:OffsetBlockInChunk(chunkX+cx, chunkZ+cz, offsetY);
			end
		end
	end
end

local results = {};
-- static function to ofset block in chunk.
function OffsetWorldTask:OffsetBlockInChunk(chunkX, chunkZ, offsetY)
	ParaTerrain.GetBlocksInRegion(chunkX, 0, chunkZ, chunkX, 15, chunkZ, 0xffff, results);
	if(results.count>0) then
		LOG.std(nil, "info", "OffsetBlockInChunk", {chunkX, chunkZ, results.count});
		local results_x, results_y, results_z, results_tempId, results_data = results.x, results.y, results.z, results.tempId, results.data;
		-- please note that the result is already arranged from low to high
		if(offsetY<0) then
			for i = 1, results.count do
				local x,y,z,block_id, block_data = results_x[i], results_y[i], results_z[i], results_tempId[i], results_data[i];
				if(x and block_id) then
					local block_id, block_data, entity_data = BlockEngine:GetBlockFull(x,y,z);
					if( (y+offsetY) >=0) then
						BlockEngine:SetBlock(x,y+offsetY,z,block_id, block_data, nil, entity_data);
					end
					BlockEngine:SetBlockToAir(x,y,z);
				end
			end
		elseif(offsetY>0) then
			for i = results.count, 1, -1 do
				local x,y,z,block_id, block_data = results_x[i], results_y[i], results_z[i], results_tempId[i], results_data[i];
				if(x and block_id) then
					local block_id, block_data, entity_data = BlockEngine:GetBlockFull(x,y,z);
					if( (y+offsetY) < 256) then
						BlockEngine:SetBlock(x,y+offsetY,z,block_id, block_data, nil, entity_data);
					end
					BlockEngine:SetBlockToAir(x,y,z);
				end
			end
		end
	end
end
