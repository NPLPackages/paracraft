--[[
Title: World Files
Author(s): LiXizhi
Date: 2014/5/7
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local filepath = Files.FindFile("readme.md");

Files:ClearFindFileCache();
local filename = Files.GetWorldFilePath("preview.jpg");

Files:GetFileFromCache(filename)

echo(Files.GetRelativePath(GameLogic.GetWorldDirectory().."1.png"));
echo(Files.GetRelativePath(GameLogic.GetWorldDirectory().."1.png"));
-------------------------------------------------------
]]
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");

-- @param filename: the filename maybe relative to the current world or the SDK root. 
-- in case it is relative to the world, we will return a path relative to SDK root. 
-- @param search_folder: if nil, it is current world directory, otherwise, one can specify an additional search folder in addition to current world directory. 
--  such as "Texture/blocks/human/"
-- @return return file relative to SDK root. or nil, if no file is found. 
function Files.GetWorldFilePath(any_filename, search_folder, bCache)
	if(any_filename) then
		-- this fix a error that some user frequently appending / to file name. 
		if(any_filename:match("^/\\")) then
			any_filename = any_filename:gsub("^/\\+", "");
		end
		if(not ParaIO.DoesAssetFileExist(any_filename, true)) then
			local filename = GameLogic.GetWorldDirectory()..any_filename;
			if(ParaIO.DoesAssetFileExist(filename, true)) then
				any_filename = filename;
			elseif(search_folder) then
				local filename = search_folder..any_filename;
				if(ParaIO.DoesAssetFileExist(filename, true)) then
					any_filename = filename;
				else
					any_filename = nil;
				end
			else
				-- LOG.std(nil, "debug", "Files", "can not file world file %s", filename)
				any_filename = nil;
			end
		end
		return any_filename;
	end
end

-- check if file exists. 
-- @param filename: can be relative to current world or sdk root. 
function Files.FileExists(filename)
	return Files.GetWorldFilePath(filename) ~= nil;
end

-- this function is mostly used to locate a local file resource. 
-- @param filename: must be relative to world. 
-- @param bCheckExist: if true, we will only return non-nil filename if the file exist on disk.
function Files.WorldPathToFullPath(filename, bCheckExist)
	if(filename) then
		if(not bCheckExist) then
			return GameLogic.GetWorldDirectory()..filename;
		else
			filename = GameLogic.GetWorldDirectory()..filename;
			if(ParaIO.DoesFileExist(filename, true)) then
				return filename;
			end
		end
	end
end

-- map from short path to long path
Files.cache = {};
-- map from long path to the shortest path
Files.reverse_cache = {};

-- call this function when world is loaded. 
function Files:ClearFindFileCache()
	self.reverse_cache = {};
	self.cache = {};
end

function Files:GetFileCache()
	return self.cache;
end

-- cache all existing filename
function Files:AddFileToCache(filename, filepath)
	self.cache[filename] = filepath;
	if(filepath) then
		local old_shortname = self.reverse_cache[filepath];
		if(not old_shortname or #old_shortname > #filename) then
			self.reverse_cache[filepath] = filename;
		end
	end
end

-- get the full filename from cache of existing files.
function Files:GetFileFromCache(filename)
	return self.cache[filename];
end

-- get short filename from cache of existing files to their long file path. 
function Files:GetShortFileFromLongFile(filename)
	return self.reverse_cache[filename];
end

-- get file path that is relative to current world directory. if not, it will return as it is. 
-- in most cases, we will store filenames using relative file path. But we have to pass to game engine the real path. 
function Files.GetRelativePath(filename)
	local world_dir = GameLogic.GetWorldDirectory()
	local file_dir = filename:sub(1, #world_dir);
	if(world_dir == file_dir) then
		return filename:sub(#world_dir+1) or "";
	else
		return filename;
	end
end	

-- we will try to find a file in world directory or global directory at all cost and save the result to cache 
-- so that the next time the same file is requeried, we will return fast for both exist or non-exist ones. 
-- see also Files.FindFile() it differs with it for non-exist files, this function will also cache non-exist files. 
-- Files.FindFile does not cache non-exist files. 
-- @return it will return the file path or false if not found
function Files.GetFilePath(filename)
	if(not filename) then
		return;
	end
	local filepath = Files:GetFileFromCache(filename);
	if(filepath or filepath == false) then
		return filepath;
	else
		return Files.FindFile(filename);
	end
end


-- find a given file by its file path. 
-- see also: Files.GetCachedFilePath()
-- it will search filename, [worldpath]/filename,  replace [worlds/DesignHouse/last] with current one. 
-- internally it will use a cache which only last for the current world, to accelerate for repeated calls. 
-- @param searchpaths: nil or additional search path seperated by ";". such as such as "Texture/blocks/human/"
-- @return the real file or nil if not exist 
function Files.FindFile(filename, searchpaths)
	if(not filename) then
		return;
	end
	local filepath = Files:GetFileFromCache(filename);
	if(not filepath) then
		filepath = Files.GetWorldFilePath(filename, searchpaths);
		if(filepath) then
			Files:AddFileToCache(filename, filepath);
		else
			local old_worldpath, relative_path = filename:match("^(worlds/DesignHouse/[^/]+/)(.*)$");
			if(relative_path and old_worldpath ~= GameLogic.GetWorldDirectory()) then
				local new_filename = GameLogic.GetWorldDirectory()..relative_path;
				filepath = Files.GetWorldFilePath(new_filename);
				if(filepath) then
					Files:AddFileToCache(filename, filepath);
				end
			end
		end
	end
	if(filepath) then
		return filepath;
	else
		-- cache non-exist
		Files:AddFileToCache(filename, false);
	end
end

-- resolve filename and return some information. 
-- @param filename: any file path such as an absolute path during a drag & drop event. 
-- @return {
--	isExternalFile,  -- boolean: if file is external to SDK
--	isInWorldDirectory, -- boolean: if file is inside the current world directory. 
--	relativeToWorldPath, 
--	relativeToRootPath, -- only valid if isExternalFile is nil.  
--	isAbsoluteFilepath, -- boolean relativeToRootPath, 
--	filename, -- no directory 
-- }
function Files.ResolveFilePath(filename)
	if(not filename) then
		return;
	end
	local info = {};
	if(filename:match("^/") or filename:match(":")) then
		info.isAbsoluteFilepath = true;
	end

	-- check external file and compute relativeToRootPath
	filename = filename:gsub("\\", "/");
	if(info.isAbsoluteFilepath) then
		local sdk_root = ParaIO.GetCurDirectory(0);
		if(filename:sub(1, #sdk_root) == sdk_root) then
			info.relativeToRootPath = filename:sub(#sdk_root+1, -1);
		else
			info.isExternalFile = true;
		end
	else
		info.relativeToRootPath = filename;
	end

	if(info.relativeToRootPath) then
		local world_root = GameLogic.GetWorldDirectory()
		if(info.relativeToRootPath:sub(1, #world_root) == world_root) then
			info.relativeToWorldPath = info.relativeToRootPath:sub(#world_root+1, -1);
			info.isInWorldDirectory = true;
		end
	end
	info.filename = filename:match("([^/]+)$");
	return info;
end