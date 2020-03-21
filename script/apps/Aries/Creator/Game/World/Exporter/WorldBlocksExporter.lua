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

local player = ParaScene.GetPlayer();
local world_x,world_y,world_z = player:GetPosition();

local blocks_exporter = WorldBlocksExporter:new():Init("world_1",{json = true, json_slice = false, x = false, zip = true, interval = 2000, });
blocks_exporter:SetWorldOptions({
	x = world_x,
	y = world_y,
	z = world_z,
});
blocks_exporter:ExportRegionsByRadius(37,37,1,function()
		_guihelper.MessageBox("done");
end);

l
blocks_exporter:ExportRegionsFrom(world_x,world_z,1,function()
		_guihelper.MessageBox("done");
end);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/ide/math/bit.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
NPL.load("(gl)Mod.ParaXExporter.BlockConfig");
NPL.load("(gl)script/ide/System/Util/ZipFile.lua");
NPL.load("(gl)script/ide/math/bit.lua");

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

function WorldBlocksExporter.ExportRegionTo_glTF(output_dir, radius)
	local blocks_exporter = WorldBlocksExporter:new():Init(output_dir, {x = true, xfolder = false, zip = false, interval = 2000, });
	local cx, cy, cz = ParaScene.GetPlayer():GetPosition();
	blocks_exporter:SetWorldOptions({x = cx, y = cy, z = cz});
	-- region size is 512 * 512
	-- if radius <= 512, only one region, radius will be 0, so divide radius by (region_width + 1)
	local region_width = 512;
	radius = math.floor(radius / (region_width + 1));
	blocks_exporter:ExportRegionsFrom(cx,cz,radius,function()
		_guihelper.MessageBox("done");
		local last_char = string.sub(output_dir, #output_dir);
		if (last_char ~= "/") then
			output_dir = output_dir.."/";
		end
		local results = commonlib.Files.Find({}, output_dir, 1, 10000, "*.x")
		for _, result in ipairs(results) do
			local parax_file = output_dir..result.filename;
			filename = parax_file:gsub("%.%w+$", "")
			local glb_file = filename..".glb";
			ParaScene.ParaXFileExportTo_glTF_File(parax_file, glb_file, nil, true, false);
		end
		ParaIO.DeleteFile(output_dir.."*.x");
	end);
end

function WorldBlocksExporter:ctor()

end
-- @param output_worldname: the worldname
-- @param options: extra options table
-- @param options.root: the name of root folder for exporting, default is "BlocksExport"
-- @param options.interval: the interval of timer for loading a region, default is 2000 milliseconds
-- @param options.json: true to export .json file
-- @param options.json_slice: true to slice json file
-- @param options.x: true to export .x file
-- @param options.zip: true to make .zip file
function WorldBlocksExporter:Init(output_worldname,options)
	self.output_worldname = output_worldname;
	self.options = options or {};
	self.options.root = self.options.root or "BlocksExport";
	self.options.interval = self.options.interval or 2000;
	-- create options.root folder if xfolder is true
	if (self.options.xfolder == nil) then
		self.options.xfolder = true;
	end


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
function WorldBlocksExporter:ExportRegionsFrom(world_x, world_z, radius_region_num, callback)
	LOG.std(nil,"info","WorldBlocksExporter.ExportRegionsFrom", {world_x, world_z});
	local region_x, region_z = BlockEngine:GetRegionPos(world_x,world_z);
	self:ExportRegionsByRadius(region_x, region_z, radius_region_num, callback)
end
function WorldBlocksExporter:ExportRegionsByRadius(region_x, region_z, radius_region_num, callback)
	LOG.std(nil,"info","WorldBlocksExporter.ExportRegionsByRadius", {region_x, region_z, radius_region_num});
	local out_world_dir = self:GetOutputDir();
	LOG.std(nil, "info", "WorldBlocksExporter", "create out folder:%s", out_world_dir);
	ParaIO.DeleteFile(out_world_dir .. "/")
	ParaIO.CreateDirectory(out_world_dir .. "/");
	
	local world_options_filename = out_world_dir .. "/world_options.json";
	self:WriteData(world_options_filename, commonlib.Json.Encode(self.world_options, true))

	local region_min_x = region_x - radius_region_num;
	region_min_x = math.max(region_min_x,0);
	local region_max_x = region_x + radius_region_num;

	local region_min_z = region_z - radius_region_num;
	region_min_z = math.max(region_min_z,0);
	local region_max_z = region_z + radius_region_num;

	local regions = {};
	for x = region_min_x,region_max_x do
		for z = region_min_z,region_max_z do
			table.insert(regions,{
					x = x, 
					z = z,
					region_min_x = region_min_x, 
					region_min_z = region_min_z,
					region_max_x = region_max_x, 
					region_max_z = region_max_z,
			});
		end
	end
	self:ReadChunks_next(regions, 1, function()
		if(self.options.zip)then
			self:WriteToZip();
		end
		if(callback)then
			callback();
		end
	end)
end
function WorldBlocksExporter:ReadChunks_next(regions, index, callback)
	local region = regions[index];
	if(not region)then
		if(callback)then
			callback();
		end
		return
	end
	local region_x = region.x;
	local region_z = region.z;
	
	local world_x,world_y,world_z = ParaScene.GetPlayer():GetPosition();
	local p_region_x, p_region_z = BlockEngine:GetRegionPos(world_x,world_z);


--	local world = GameLogic.GetBlockWorld();
--	if(world)then
--		local attr = ParaBlockWorld.GetBlockAttributeObject(world);
--		attr:SetField("UseAsyncLoadWorld", false);
--		ParaBlockWorld.LoadRegion(world, world_x,world_y,world_z);
--	end
	
	if(region_x ~= p_region_x and region_z ~= p_region_z)then
		local pos_x = (region_x + 0.5) * BlockEngine.region_width;
		local pos_z = (region_z + 0.5) * BlockEngine.region_width;
		local _,pos_y,_ = BlockEngine:real(region_x,10,region_z);
		ParaScene.GetPlayer():SetPosition(pos_x,pos_y,pos_z);
	end
	_guihelper.MessageBox(string.format("exporing region:<br/>x %d->%d<br/>z %d->%d<br/>%d_%d",
			region.region_min_x,region.region_max_x,
			region.region_min_z,region.region_max_z,
			region_x, region_z));
	local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
		self:ExportRegion(region_x, region_z, function(x,z)
			self:ReadChunks_next(regions, index+1, callback)
		end)
	end})
	mytimer:Change(self.options.interval, nil)
end

function WorldBlocksExporter:GetOutputDir()
	local root_dir = string.format("%s%s",ParaIO.GetCurDirectory(0),self.options.root);
	local out_world_dir = string.format("%s/%s",root_dir, self.output_worldname);
	if (not self.options.xfolder) then
		out_world_dir = self.output_worldname;
	end
	return out_world_dir;
end
function WorldBlocksExporter:ExportRegion(region_x, region_z, callback)
	LOG.std(nil, "info", "WorldBlocksExporter", "export region %d %d", region_x, region_z);
	local out_world_dir = self:GetOutputDir();

	local out_dir_blocks_data_json
	if(self.options.json)then
		out_dir_blocks_data_json = string.format("%s/BlocksData/json",out_world_dir);
		ParaIO.CreateDirectory(out_dir_blocks_data_json .. "/");
	end
	
	local out_dir_blocks_data_x = out_world_dir;
	if(self.options.x and self.options.xfolder)then
		out_dir_blocks_data_x = string.format("%s/BlocksData/x",out_world_dir);
		ParaIO.CreateDirectory(out_dir_blocks_data_x.. "/");
	end

	local blocks_map = {};
	local startChunkX, startChunkZ = region_x * 32, region_z * 32;
	-- read from lowest hight
	for y = 0,BlockConfig.g_regionChunkDimY-1 do
		for x = 0,BlockConfig.g_regionChunkDimX-1 do
			for z = 0,BlockConfig.g_regionChunkDimX-1 do
				local chunk_x = startChunkX+x;
				local chunk_y = y;
				local chunk_z = startChunkZ+z;
				local blocks = self:ReadBlock(region_x, region_z, chunk_x,chunk_y,chunk_z);
				local len = #blocks;
				if(len > 0)then
					-- export json
					if(self.options.json)then
						if(self.options.json_slice)then
							local filename = string.format("%s/%d_%d_%d_%d_%d.json",out_dir_blocks_data_json,region_x,region_z,chunk_x,chunk_y,chunk_z);
							WorldBlocksExporter:WriteToJson(filename, blocks)
						else
							local key = string.format("%d_%d_%d",chunk_x,chunk_y,chunk_z);
							blocks_map[key] = blocks;
						end
					end
					-- export x
					if(self.options.x)then
						local filename = string.format("%s/%d_%d_%d_%d_%d.x",out_dir_blocks_data_x,region_x,region_z,chunk_x,chunk_y,chunk_z);
						WorldBlocksExporter:WriteToX(filename, blocks)
					end
				end
			end
		end
	end
	-- export json by region
	if(self.options.json and not self.options.json_slice)then
		local filename = string.format("%s/%d_%d.json",out_dir_blocks_data_json,region_x,region_z);
		WorldBlocksExporter:WriteToJson(filename, blocks_map)
	end
	--[[
	if(self.options.x)then
		ParaIO.DeleteFile(out_dir_blocks_data_x.."/*.xml");
		ParaIO.DeleteFile(out_dir_blocks_data_x.."/*.bmax");
	end
	]]
	-- export textures
	ParaAsset.SetAssetServerUrl("http://cdn.keepwork.com/update61/assetdownload/update/");
	WorldBlocksExporter.loadAssetFile(self.textures, function()
		WorldBlocksExporter.copyFiles(self.textures, out_world_dir);
		if(callback)then
			callback(region_x, region_z);
		end
	end);
end

function WorldBlocksExporter:GotoChunk(region_x, region_z, chunk_x, chunk_y, chunk_z)
	local blockSize = 533.3333 / 512;
	local pos_x = (chunk_x + 0.5) * 16 * blockSize;
	local pos_y = (chunk_y - 8) * 16 * blockSize;
	local pos_z = (chunk_z + 0.5) * 16 * blockSize;
	ParaScene.GetPlayer():SetPosition(pos_x,pos_y,pos_z);
	
end
function WorldBlocksExporter:ReadBlock(region_x, region_z, chunk_x, chunk_y, chunk_z)
	local blocks = {};
	local results = {};
	
	--self:GotoChunk(region_x, region_z, chunk_x, chunk_y, chunk_z)
	ParaTerrain.GetBlocksInRegion(chunk_x, chunk_y, chunk_z, chunk_x, chunk_y, chunk_z, 0xffffff, results);
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
	return blocks;
end
function WorldBlocksExporter:WriteToX(file_name, blocks)
	NPL.load("(gl)Mod/ParaXExporter/main.lua");
	local ParaXExporter = commonlib.gettable("Mod.ParaXExporter");
	ParaXExporter:ConvertBlocksToParaX(blocks, file_name, true);
	
end
function WorldBlocksExporter:WriteToJson(json_file_name, blocks)
	local json_data = commonlib.Json.Encode(blocks, true);
	if (json_data) then
		self:WriteData(json_file_name,json_data);
	end
end
function WorldBlocksExporter:WriteToZip()
	local root_dir = string.format("%s%s",ParaIO.GetCurDirectory(0),self.options.root);
	local out_world_dir = string.format("%s/%s",root_dir, self.output_worldname);

	local zip_file_name = string.format("%s/%s.zip", root_dir, self.output_worldname);
	local file = ParaIO.CreateZip(zip_file_name, "");
	if (file:IsValid()) then
		file:AddDirectory(self.output_worldname, out_world_dir .. "/*.*", 10);
		file:close();
	end
end
function WorldBlocksExporter:SetWorldOptions(options)
	self.world_options = options;
end
function WorldBlocksExporter:WriteData(file_name, data)
	local file = ParaIO.open(file_name, "w");
	if(file:IsValid()) then
		file:WriteString(data);
		file:close();
	end
end