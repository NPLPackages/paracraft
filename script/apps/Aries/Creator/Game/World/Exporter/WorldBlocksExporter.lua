--[[
Title: WorldBlocksExporter
Author(s): leio,chenjinxian
Date: 2019/10/17
Desc: reads every block in each region,exports it to .x and textures
this class is depend on BMaxToParaXExporter(https://github.com/tatfook/BMaxToParaXExporter)
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/Exporter/WorldBlocksExporter.lua");
local WorldBlocksExporter = commonlib.gettable("MyCompany.Aries.Creator.Game.Exporter.WorldBlocksExporter");
local blocks_exporter = WorldBlocksExporter:new():Init("world_1");
local player = ParaScene.GetPlayer();
local world_x,world_y,world_z = player:GetPosition();
blocks_exporter:ReadRegion(world_x,world_y,world_z);
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/math/bit.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
NPL.load("(gl)Mod.ParaXExporter.BlockConfig");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local BlockConfig = commonlib.gettable("Mod.ParaXExporter.BlockConfig");

local WorldBlocksExporter = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Creator.Game.Exporter.WorldBlocksExporter"))

function WorldBlocksExporter:ctor()

end

function WorldBlocksExporter:Init(name)
    self.name= name;
    return self;
end
function WorldBlocksExporter:Export()
end
function WorldBlocksExporter:ReadRegions()
end

function WorldBlocksExporter:ReadRegion(world_x,world_y,world_z)
    local region_x, region_z = BlockEngine:GetRegionPos(world_x,world_z);
	LOG.std(nil, "info", "WorldBlocksExporter", "get region index %f %f %f -> %d %d", world_x,world_y,world_z, region_x, region_z);
    self:ReadChunks(region_x, region_z);
end
function WorldBlocksExporter:ReadChunks(region_x, region_z)
    -- read from lowest hight
    for y = 0,BlockConfig.g_regionChunkDimY-1 do
        for x = 0,BlockConfig.g_regionChunkDimX-1 do
            for z = 0,BlockConfig.g_regionChunkDimX-1 do
                self:ReadChunk(region_x, region_z, x, y, z);
            end
        end
    end
    _guihelper.MessageBox("done");

end
function WorldBlocksExporter:ReadChunk(region_x, region_z, chunk_x, chunk_y, chunk_z)
	LOG.std(nil, "info", "WorldBlocksExporter", "ReadChunk %d %d %d", chunk_x,chunk_y,chunk_z);
    -- read from lowest hight
--    for y = 0,BlockConfig.g_chunkBlockDim-1 do
--        for x = 0,BlockConfig.g_chunkBlockDim-1 do
--            for z = 0,BlockConfig.g_chunkBlockDim-1 do
--                self:ReadBlock(region_x, region_z, chunk_x, chunk_y, chunk_z, x, y, z);
--            end
--        end
--    end
end
function WorldBlocksExporter:ReadBlock(region_x, region_z, chunk_x, chunk_y, chunk_z, block_x, block_y, block_z)
	LOG.std(nil, "info", "WorldBlocksExporter", "ReadBlock %d %d %d", block_x,block_y,block_z);
end