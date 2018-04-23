--[[
Title: WorldStripperPage
Author(s): LiXizhi
Date: 2009/7/13
Desc: remove unused files in a world directory. When a world is inherited from another world and modified, 
the game engine will preverse unused old files, especially for terrain mask and height fields files. 
Running WorldStripper will remove those unused files, thus generate a more clean and concise directory for redistribution. 

---++ Requirement Proposal by LiXizhi
take the world: worlds\MyWorlds\0702_test for example, the stripping procedure is stated below
   1. remove all ./config/*.config.txt that are not referenced in ./0702_test.worldconfig.txt, 
   1. for all files removed in previous step, also remove ./config/*.mask, where * is the same * in ./config/*.config.txt
   1. remove all ./elev/*.raw and ./script/*.onload.lua, that are not referenced in remaining ./config/*.config.txt files

About UI:
   1. an editbox to input the world root directory.
   1. a generate remove file list button
   1. an output list box to list all files that will be removed. 
   1. a remove button that will remove all files listed. 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/worlds/WorldStripperPage.lua");
-------------------------------------------------------
]]

-- create class
local WorldStripperPage = {};
commonlib.setfield("Map3DSystem.App.worlds.WorldStripperPage", WorldStripperPage)

function WorldStripperPage.OnInit()
	page = document:GetPageCtrl(); -- singleton
	
	page:SetNodeValue("worldpath", ParaWorld.GetWorldDirectory());
end

-- do the strip. 
function WorldStripperPage.OnClickStrip(name, values)
	-- _guihelper.MessageBox(values);
	local worldpath = values.worldpath;
	worldpath = string.gsub(worldpath, "[/\\]+$", "")
	
	local world = Map3DSystem.World:new();
	world:SetDefaultFileMapping(worldpath);
	local config_file = ParaIO.open(world.sConfigFile, "r");
	if(config_file:IsValid()) then
		-- find all referenced files
		local text = config_file:GetText();
		local files = {};
		local w;
		for w in string.gfind(text, "[^\r\n]+") do
			w = string.match(w, "[^/]+config%.txt$");
			if(w) then
				local config_file_name = worldpath.."/config/"..w;
				files[config_file_name] = true;
	
				local file = ParaIO.open(config_file_name, "r");			
				if(file:IsValid()) then
					local tile_text = file:GetText();
					for w in string.gfind(tile_text, "[^\r\n]+") do
						local content = string.match(w, "[^/]+%.onload%.lua$");
						if(content) then
							files[worldpath.."/script/"..content] = true;
							files[worldpath.."/config/"..string.gsub(content, "onload%.lua$", "mask")] = true;
						end
						local content = string.match(w, "[^/]+%.raw$");
						if(content) then
							files[worldpath.."/elev/"..content] = true;
						end
					end
					file:close();
				else
					commonlib.log("warning: config file %s is not found\n", config_file_name);
				end
			end	
		end
		config_file:close();
		
		-- commonlib.echo(files);
		
		local unused_files = {};
		-- delete unused files. 
		NPL.load("(gl)script/ide/Files.lua");
		local nCount = 0;
		local function RemoveInFolder(folder_name)
			local result = commonlib.Files.Find({}, folder_name, 0, 5000, "*.*")
			local i, file 
			for i,file in pairs(result) do
				local filename = folder_name..file.filename;
				if(not files[filename]) then
					unused_files[filename] = true;
					nCount = nCount +1;
				end
			end
		end	
		RemoveInFolder(worldpath.."/script/");
		RemoveInFolder(worldpath.."/elev/");
		RemoveInFolder(worldpath.."/config/");
		
		-- Output unused_files to log
		commonlib.echo(unused_files);
		
		_guihelper.MessageBox(string.format("there are %d unused files. They have been dumped to log.txt files. Do you want to delete them now? Please make sure files are not read-only.", nCount), function()
			local file, _ 
			for file, _ in pairs(unused_files) do
				ParaIO.DeleteFile(file);
			end
			_guihelper.MessageBox("Files have been successfully deleted\n");
		end)
	else
		commonlib.echo({"file not found", config_file})	
	end
end

-- rename all world related files so that they match the world name
function WorldStripperPage.OnClickNormalize(name, values)
	-- _guihelper.MessageBox(values);
	local worldpath = values.worldpath;
	worldpath = string.gsub(worldpath, "[/\\]+$", "")
	
	local worldname = ParaIO.GetFileName(worldpath);
	
	commonlib.log("begin normalizing: %s\n", worldname);
	
	local world = Map3DSystem.World:new();
	world:SetDefaultFileMapping(worldpath);
	local config_file = ParaIO.open(world.sConfigFile, "r");
	if(config_file:IsValid()) then
		-- find all referenced files
		local text = config_file:GetText();
		local files = {};
		local w;
		for w in string.gfind(text, "[^\r\n]+") do
			w = string.match(w, "[^/]+config%.txt$");
			if(w) then
				files[w] = true;
			end	
		end
		config_file:close();
		
		local main_config_file_changed;
		local config_file_name, _
		for config_file_name, _ in pairs(files)  do
			-- replace tile config file if any
			local namepart,others = string.match(config_file_name, "^(.+)(_%d+_%d+)%.config%.txt$");
			
			commonlib.echo({namepart,others})
			if(namepart and namepart~= worldname) then
				-- Note: namepart should not contain special characters. 
				text = string.gsub(text, namepart, worldname);
				ParaIO.MoveFile(worldpath.."/config/"..config_file_name, worldpath.."/config/"..worldname..others..".config.txt")
				main_config_file_changed = true;
				config_file_name = worldpath.."/config/"..worldname..others..".config.txt";
			else
				config_file_name = worldpath.."/config/"..config_file_name;	
			end

			local file = ParaIO.open(config_file_name, "r");			
			if(file:IsValid()) then
				local tile_text = file:GetText();
				local tile_config_changed;
				local tile_text_old = tile_text;
				local tile_text_lines = {};
				for w in string.gfind(tile_text_old, "[^\r\n]+") do
					local content = string.match(w, "([^/]+)%.onload%.lua$");
					local bLineAdded;
					if(content) then
						local namepart, others = string.match(content, "^(.+)(_%d+_%d+)$");
						if(namepart ~= worldname) then
							ParaIO.MoveFile(worldpath.."/script/"..content..".onload.lua", worldpath.."/script/"..worldname..others..".onload.lua")
							ParaIO.MoveFile(worldpath.."/config/"..content..".mask", worldpath.."/config/"..worldname..others..".mask")
							commonlib.echo({worldpath.."/script/"..content..".onload.lua", worldpath.."/script/"..worldname..others..".onload.lua"})
							commonlib.echo({worldpath.."/config/"..content..".mask", worldpath.."/config/"..worldname..others..".mask"})
							tile_config_changed = true;
							if(not bLineAdded) then
								tile_text_lines[#tile_text_lines+1] = string.gsub(w, namepart, worldname);
								bLineAdded = true;
							end
							--tile_text = string.gsub(tile_text, namepart, worldname);
						end	
					end
					local content = string.match(w, "([^/]+)%.raw$");
					if(content) then
						local namepart, others = string.match(content, "^(.+)(_%d+_%d+.*)$");
						if(namepart and others and namepart ~= worldname) then
							ParaIO.MoveFile(worldpath.."/elev/"..content..".raw", worldpath.."/elev/"..worldname..others..".raw")
							commonlib.echo({worldpath.."/elev/"..content..".raw", worldpath.."/elev/"..worldname..others..".raw"})
							tile_config_changed = true;
							-- tile_text = string.gsub(tile_text, namepart, worldname);
							if(not bLineAdded) then
								tile_text_lines[#tile_text_lines+1] = string.gsub(w, namepart, worldname);
								bLineAdded = true;
							end
						end
					end
					if(not bLineAdded) then
						tile_text_lines[#tile_text_lines+1] = w;
						bLineAdded = true;
					end
				end
				file:close();
				
				if(tile_config_changed) then
					commonlib.log("tile config file: %s updated\n", config_file_name);
					file = ParaIO.open(config_file_name, "w");
					if(file:IsValid()) then
						tile_text = table.concat(tile_text_lines, "\r\n");
						file:WriteString(tile_text);
						file:close();
					end
				end
			else
				commonlib.log("warning: config file %s is not found. we will replace it with flat.txt.\n", config_file_name);
				main_config_file_changed = true;
				local file = "config/"..namepart..others.."%.config%.txt";
				text = string.gsub(text, file, "flat.txt");
			end
		end
		
		-- overwrite main config file
		if(main_config_file_changed) then
			commonlib.log("main config file: %s updated\n", world.sConfigFile);
			config_file = ParaIO.open(world.sConfigFile, "w");
			if(config_file:IsValid()) then
				config_file:WriteString(text);
				config_file:close();
			end
		end	
	else
		commonlib.echo({"file not found", config_file})	
	end
	commonlib.log("end normalizing: %s\n", worldname);
end