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
NPL.load("(gl)script/ide/System/Util/ZipFile.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local BlockConfig = commonlib.gettable("Mod.ParaXExporter.BlockConfig");
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local ZipFile = commonlib.gettable("System.Util.ZipFile");

local WorldBlocksExporter = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Creator.Game.Exporter.WorldBlocksExporter"))

function WorldBlocksExporter.save_to_file(asset_file_name,output_root_folder)
	local content;
	local file = ParaIO.OpenAssetFile(asset_file_name);
	if(file:IsValid()) then	
		content = file:GetText(0, -1);
		file:close();
	end
	local filename = string.format("%s/%s",output_root_folder,asset_file_name);
	if(content)then
		ParaIO.CreateDirectory(filename);
		local file = ParaIO.open(filename, "w");
		if(file:IsValid()) then	
			file:WriteString(content,#content);
			file:close();
		end
	end
	return filename;
end

function WorldBlocksExporter.copyFiles(input_files,output_root_folder)
	if(not input_files)then
		return
	end
	local result = {};
	for k,v in ipairs(input_files) do
		local filename = WorldBlocksExporter.save_to_file(v,output_root_folder)
		table.insert(result,filename);
	end
	return result;
end

function WorldBlocksExporter.loadAssetFile(asset_file_name,callback)
	LOG.std(nil,"info","WorldBlocksExporter.loadAssetFile", asset_file_name);
	NPL.load("(gl)script/ide/AssetPreloader.lua");
	local loader = commonlib.AssetPreloader:new({
		callbackFunc = function(nItemsLeft, loader)
			if(nItemsLeft <= 0) then
				if(callback)then
					callback();
				end
			end
		end
	});
	loader:AddAssets(asset_file_name);
	loader:Start();
end

function WorldBlocksExporter:ctor()

end

function WorldBlocksExporter:Init(output_file_name)
	self.output_file_name = output_file_name;
	self.mapTextures = {};
	self.textures = {};
	return self;
end

function WorldBlocksExporter:ExportTo_glTF(zip_file_name, output_dir)
	if (not output_dir) then
		output_dir = ParaIO.GetParentDirectoryFromPath(zip_file_name);
	end
	local last_char = string.sub(output_dir, #output_dir);
	if (last_char ~= "/") then
		output_dir = output_dir.."/";
	end

	local zipFile = ZipFile:new();
	if(zipFile:open(zip_file_name)) then
		zipFile:unzip(output_dir);
		zipFile:close();

		local filename = ParaIO.GetFileName(zip_file_name);
		filename = filename:gsub("%.%w+$", "")
		output_dir = output_dir .. filename .. "/";
		local results = commonlib.Files.Find({}, output_dir, 1, 10000, "*.x")
		for _, result in ipairs(results) do
			local parax_file = output_dir..result.filename;
			filename = parax_file:gsub("%.%w+$", "")
			local glb_file = filename..".glb";
			ParaScene.ParaXFileExportTo_glTF_File(parax_file, glb_file, nil, true, false);
		end

		ParaIO.DeleteFile(output_dir.."*.x");
		ParaIO.DeleteFile(output_dir.."*.xml");
	end
end

function WorldBlocksExporter:ReadRegion(world_x,world_y,world_z)
	local region_x, region_z = BlockEngine:GetRegionPos(world_x,world_z);
	LOG.std(nil, "info", "WorldBlocksExporter", "get region index %f %f %f -> %d %d", world_x,world_y,world_z, region_x, region_z);
	self:ReadChunks(region_x, region_z);
end

function WorldBlocksExporter:ReadChunks(region_x, region_z)
	local root_dir = ParaIO.GetParentDirectoryFromPath(self.output_file_name, 0);
	local file_name = ParaIO.GetFileName(self.output_file_name);
	file_name = string.match(file_name,"(.+)%.(%w+)$");
	local zip_root_dir = string.format("%s%s/*.*", root_dir, file_name);
	local zip_root_name = string.format("%s%s/%s_", root_dir, file_name, file_name);
	local zip_file_name = string.format("%s%s.zip", root_dir, file_name);

	local startChunkX, startChunkZ = region_x * 32, region_z * 32;
	-- read from lowest hight
	for y = 0,BlockConfig.g_regionChunkDimY-1 do
		for x = 0,BlockConfig.g_regionChunkDimX-1 do
			for z = 0,BlockConfig.g_regionChunkDimX-1 do
				self:ReadBlock(zip_root_name, startChunkX+x, y, startChunkZ+z);
			end
		end
	end

	ParaAsset.SetAssetServerUrl("http://cdn.keepwork.com/update61/assetdownload/update/");
	WorldBlocksExporter.loadAssetFile(self.textures, function()
		local output_root_folder = ParaIO.GetParentDirectoryFromPath(zip_root_name, 0);
		WorldBlocksExporter.copyFiles(self.textures, output_root_folder);
	end);

	local file = ParaIO.CreateZip(zip_file_name, "");
	if (file:IsValid()) then
		local dir_name = ParaIO.GetFileName(zip_file_name);
		dir_name = string.match(dir_name,"(.+)%.(%w+)$");
		file:AddDirectory(dir_name, zip_root_dir, 3);
		file:close();
	end
	_guihelper.MessageBox("done");
end

function WorldBlocksExporter:ReadBlock(zip_root_name, chunk_x, chunk_y, chunk_z)
	--LOG.std(nil, "info", "WorldBlocksExporter", "ReadBlock %d %d %d", block_x,block_y,block_z);

	local blocks = {};
	local results = {};
	ParaTerrain.GetBlocksInRegion(chunk_x, chunk_y, chunk_z, chunk_x, chunk_y, chunk_z, block.attributes.cubeMode, results);
	if(results.count and results.count>0) then
		local results_x, results_y, results_z, results_tempId, results_data = results.x, results.y, results.z, results.tempId, results.data;
		for i = 1, results.count do
			local x,y,z,block_id, block_data = results_x[i], results_y[i], results_z[i], results_tempId[i], results_data[i];
			if(x and block_id) then
				local block = {x, y, z, block_id, block_data or 0};
				table.insert(blocks, block);
				local blocktemplate = block_types.get(block_id);
				if(blocktemplate ~= nil and self.mapTextures[block_id] == nil) then
					self.mapTextures[block_id] = blocktemplate.texture;
					table.insert(self.textures, blocktemplate.texture);
				end
			end
		end
	end

	if (#blocks > 0) then
		NPL.load("(gl)Mod/ParaXExporter/main.lua");
		local ParaXExporter = commonlib.gettable("Mod.ParaXExporter");
		local parax_name = zip_root_name..chunk_x.."_"..chunk_y.."_"..chunk_z..".x";
		ParaXExporter:ConvertBlocksToParaX(blocks, parax_name, true);
		local json_data = commonlib.Json.Encode(blocks, true);
		if (json_data) then
			local json_file_name = zip_root_name..chunk_x.."_"..chunk_y.."_"..chunk_z..".json";
			--[[
			local writer = ParaIO.CreateZip(json_file_name, "");
			if (writer:IsValid()) then
				writer:ZipAddData(ParaIO.GetFileName(json_file_name), json_data);
				writer:close();
			end
			]]
			local file = ParaIO.open(json_file_name, "w");
			if(file:IsValid()) then
				file:WriteString(json_data);
				file:close();
			end
		end
	end
end
