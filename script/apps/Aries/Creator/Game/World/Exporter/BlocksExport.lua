--[[
Title: BlocksExport
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/Exporter/BlocksExport.lua");
local BlocksExport = commonlib.gettable("MyCompany.Aries.Creator.Game.Exporter.BlocksExport");

-------------------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua");

local BlocksExport = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Creator.Game.Exporter.BlocksExport"))

BlocksExport.g_regionBlockDimX = 512;
BlocksExport.g_regionBlockDimY = 256;
BlocksExport.g_regionBlockDimZ = 512;
BlocksExport.g_chunkBlockDim = 16;
BlocksExport.g_chunkBlockCount = 16 * 16 * 16;
BlocksExport.g_regionChunkDimX = BlocksExport.g_regionBlockDimX / BlocksExport.g_chunkBlockDim;
BlocksExport.g_regionChunkDimY = BlocksExport.g_regionBlockDimY / BlocksExport.g_chunkBlockDim;
BlocksExport.g_regionChunkDimZ = BlocksExport.g_regionBlockDimZ / BlocksExport.g_chunkBlockDim;
BlocksExport.g_regionChunkCount = BlocksExport.g_regionChunkDimX * BlocksExport.g_regionChunkDimY * BlocksExport.g_regionChunkDimZ;
BlocksExport.g_maxFaceCountPerBatch = 9000;
BlocksExport.g_regionBlockDimZ = 512;
BlocksExport.g_maxValidLightValue = 127;
BlocksExport.g_sunLightValue = 0xf;
BlocksExport.g_maxLightValue = 0xf;
BlocksExport.g_regionSize = 533.3333;
BlocksExport.g_chunkSize = BlocksExport.g_regionSize / BlocksExport.g_regionChunkDimX;
BlocksExport.g_dBlockSize = BlocksExport.g_regionSize / BlocksExport.g_regionBlockDimX;
BlocksExport.g_dBlockSizeInverse = 1.0 / BlocksExport.g_dBlockSize;
BlocksExport.g_blockSize = BlocksExport.g_dBlockSize;
BlocksExport.g_half_blockSize = BlocksExport.g_blockSize*0.5;
BlocksExport.exportIndex = 0;
BlocksExport.exportTotal = 1;

-- options.comand: "selected", "radius", "region", "range"
-- options.radius: {x, y, z}
-- options.region: {x, z}
-- options.from: from, to, for "range" comand, {x, y, z}
-- options.to: from, to, for "range" comand {x, y, z}
-- options.filename: filename of selected blocks
function BlocksExport.Run(options)
	_guihelper.MessageBox(L"正在导出，开始计算导出进度...");
	BlocksExport.exportIndex = 0;
	BlocksExport.exportTotal = 1;

	local main_thread = __rts__:GetName();
	local command = options.command
	local worker = NPL.CreateRuntimeState(command, 0);
	worker:Start();
	NPL.activate(string.format("(%s)script/apps/Aries/Creator/Game/World/Exporter/BlocksExport.lua", command), {
		command = command,
		options = options,
		worlddir = GameLogic.current_worlddir,
		main_thread = main_thread
	});
end

function BlocksExport.ExportSelectedBlocks(blocks_string, filename, worlddir, main_thread)
	ParaEngine.Sleep(1);
	ParaScene.BlocksExportTo_glTF(blocks_string, filename);

	NPL.activate(string.format("(%s)script/apps/Aries/Creator/Game/World/Exporter/BlocksExport.lua", main_thread), {
		command = "callback",
		worlddir = worlddir,
		process = 100
	});
end

function BlocksExport.ExportRegions(regions, worlddir, main_thread)
	ParaEngine.Sleep(1);
	BlocksExport.exportIndex = 0;
	BlocksExport.exportTotal = (#regions) * BlocksExport.g_regionChunkDimX * BlocksExport.g_regionChunkDimY * BlocksExport.g_regionChunkDimZ;
	for i = 1, #regions do
		BlocksExport.ExportRegion(regions[i], worlddir, main_thread);
	end

	NPL.activate(string.format("(%s)script/apps/Aries/Creator/Game/World/Exporter/BlocksExport.lua", main_thread), {
		command = "callback",
		worlddir = worlddir,
		process = 100
	});
end

function BlocksExport.ExportByRadius(x, y, z, worlddir, main_thread)
	ParaEngine.Sleep(1);
	local cx, cy, cz = ParaScene.GetPlayer():GetPosition();
	local region_x = math.floor(cx / BlocksExport.g_regionSize);
	local region_z = math.floor(cz / BlocksExport.g_regionSize);
	local startChunkX = math.floor(cx / BlocksExport.g_chunkSize);
	local startChunkZ = math.floor(cz / BlocksExport.g_chunkSize);
	local rx = math.floor(x / BlocksExport.g_chunkBlockDim);
	local ry = math.floor(y / BlocksExport.g_chunkBlockDim);
	local rz = math.floor(z / BlocksExport.g_chunkBlockDim);
	BlocksExport.exportIndex = 0;
	BlocksExport.exportTotal = (rx*2+1) * (rz*2+1) * (ry+1)

	for y = 0, ry do
		for x = -rx, rx do
			for z = -rz, rz do
				local chunk_x = startChunkX+x;
				local chunk_y = y;
				local chunk_z = startChunkZ+z;
				BlocksExport.ExportChunk(region_x, region_z, chunk_x,chunk_y,chunk_z, worlddir);
				BlocksExport.exportIndex = BlocksExport.exportIndex + 1;

				NPL.activate(string.format("(%s)script/apps/Aries/Creator/Game/World/Exporter/BlocksExport.lua", main_thread), {
					command = "callback",
					worlddir = worlddir,
					process = BlocksExport.exportIndex * 100.0 / BlocksExport.exportTotal
				});
			end
		end
	end
end

function BlocksExport.ExportInRange(from, to, worlddir, main_thread)
	local x1, y1, z1, x2, y2, z2 = from[0], from[1], from[2], to[0], to[1], to[2]
end

function BlocksExport.ExportRegion(region, worlddir, main_thread)
	local region_x, region_z = region[1], region[2];
	local startChunkX, startChunkZ = region_x * 32, region_z * 32;
	for y = 0, BlocksExport.g_regionChunkDimY-1 do
		for x = 0,BlocksExport.g_regionChunkDimX-1 do
			for z = 0,BlocksExport.g_regionChunkDimZ-1 do
				local chunk_x = startChunkX+x;
				local chunk_y = math.floor(((BlocksExport.g_regionChunkDimY-1) / 2 + y) % (BlocksExport.g_regionChunkDimY-1));
				local chunk_z = startChunkZ+z;
				BlocksExport.ExportChunk(region_x, region_z, chunk_x,chunk_y,chunk_z, worlddir);
				BlocksExport.exportIndex = BlocksExport.exportIndex + 1;

				NPL.activate(string.format("(%s)script/apps/Aries/Creator/Game/World/Exporter/BlocksExport.lua", main_thread), {
					command = "callback",
					worlddir = worlddir,
					process = BlocksExport.exportIndex * 100.0 / BlocksExport.exportTotal
				});
			end
		end
	end
end

function BlocksExport.ExportChunk(region_x, region_z, chunk_x, chunk_y, chunk_z, worlddir)
	local blocks = {};
	local results = {};
	
	ParaTerrain.GetBlocksInRegion(chunk_x, chunk_y, chunk_z, chunk_x, chunk_y, chunk_z, 0xffffff, results);
	if(results.count and results.count>0) then
		local results_x, results_y, results_z, results_tempId, results_data = results.x, results.y, results.z, results.tempId, results.data;
		for i = 1, results.count do
			local x,y,z,block_id, block_data = results_x[i], results_y[i], results_z[i], results_tempId[i], results_data[i];
			if(x and block_id) then
				local block = {x, y, z, block_id, block_data or 0};
				table.insert(blocks, block);
			end
		end
	end

	if (#blocks > 0) then
		local blocks_string = commonlib.serialize_compact(blocks, true);
		local relative_path = format("blocktemplates/%d_%d_%d_%d_%d.glb", region_x,region_z,chunk_x,chunk_y,chunk_z);
		local filename = worlddir..relative_path;
		ParaScene.BlocksExportTo_glTF(blocks_string, filename);
	end
end

local function activate()
	local command = msg.command;
	local options = msg.options;
	local main_thread = msg.main_thread;
	if (command == "selected") then
		BlocksExport.ExportSelectedBlocks(options.blocks_string, options.filename, msg.worlddir, main_thread);
	elseif (command == "radius") then
		BlocksExport.ExportByRadius(options.x, options.y, options.z, msg.worlddir, main_thread);
	elseif (command == "region") then
		BlocksExport.ExportRegions(options.regions, msg.worlddir, main_thread);
	elseif (command == "range") then
		BlocksExport.ExportInRange(options.from, options.to, msg.worlddir, main_thread);
	elseif (command == "callback") then
		local process = msg.process
		if (process > 0 and process < 99) then
			_guihelper.MessageBox(string.format(L"正在导出，已完成 %.1f%%", process));
		else
			local worlddir = msg.worlddir;
			local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
			_guihelper.MessageBox(string.format(L"导出成功, 是否打开所在目录"), function(res)
				if(res and res == _guihelper.DialogResult.Yes) then
					local info = Files.ResolveFilePath(worlddir.."blocktemplates/")
					if(info and info.relativeToRootPath) then
						local absPath = ParaIO.GetWritablePath()..info.relativeToRootPath;
						local absPathFolder = absPath:gsub("[^/\\]+$", "")
						ParaGlobal.ShellExecute("open", absPathFolder, "", "", 1);
					end
				end
			end, _guihelper.MessageBoxButtons.YesNo);
		end
	end
end

NPL.this(activate)