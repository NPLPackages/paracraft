--[[
Title: World Files
Author(s): LiXizhi
Date: 2014/5/7
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
-- search and cache the relative path
local filepath = Files.GetFilePath("readme.md"); 
local filepath = Files.FindFile("readme.md");

Files:ClearFindFileCache();
local filename = Files.GetWorldFilePath("preview.jpg");

Files:GetFileFromCache(filename)

echo(Files.GetRelativePath(GameLogic.GetWorldDirectory().."1.png"));
echo(Files.GetRelativePath(GameLogic.GetWorldDirectory().."1.png"));
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketGetFile.lua");
NPL.load("(gl)script/ide/math/StringUtil.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");

-- additional world search path
Files.worldSearchPath = nil;

-- currently only one addtional world search path can be added. 
function Files.AddWorldSearchPath(worldPath)
	Files.worldSearchPath = worldPath;
end

-- this is called when world exits
function Files.ClearWorldSearchPaths()
	Files.worldSearchPath = nil;
end

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
		search_folder = search_folder or Files.worldSearchPath
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
				if(GameLogic.isRemote) then
					-- if it is the remote world, we will create an empty file locally, and send a get file request to the server world.
					local filepath = Files:GetFileFromCache(any_filename);
					if(filepath) then
						any_filename = filepath;	
					elseif(filepath == false) then
						any_filename = nil;	
					else
						local ext = commonlib.Files.GetFileExtension(any_filename);
						if(ext == "bmax" or ext == "x"  or ext == "fbx"  or ext == "png"  or ext == "jpg") then
							Files:AddFileToCache(any_filename, filename);
							ParaIO.CreateDirectory(filename);
							local file = ParaIO.open(filename, "w");
							if(file:IsValid()) then
								file:close();
								Files.GetRemoteWorldFile(any_filename);
							end	
							any_filename = filename;
						else
							Files:AddFileToCache(any_filename, false);
							any_filename = nil;		
						end
						
					end
				else
					-- LOG.std(nil, "debug", "Files", "can not file world file %s", filename)
					any_filename = nil;
				end
			end
		end
		return any_filename;
	end
end

-- one can check the result after 1 second
-- @param any_filename: relative to world path. 
function Files.GetRemoteWorldFile(any_filename)
	GameLogic.GetPlayer():AddToSendQueue(Packets.PacketGetFile:new():Init(any_filename));
	LOG.std(nil, "info", "Files", "fetching remote file: %s", any_filename)	
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
	Files.ClearWorldSearchPaths()
end

function Files:UnloadAllUnusedAssets()
	local assetManager = ParaEngine.GetAttributeObject():GetChild("AssetManager");

	local paraXManager = assetManager:GetChild("ParaXManager")
	for i=1, paraXManager:GetChildCount(0) do
		local attr = paraXManager:GetChildAt(i)
		if(attr:GetField("IsInitialized", false) and attr:GetField("RefCount", 1) <= 1) then
			local filename = attr:GetField("name", "");
			if(filename ~= "") then
				local ext = filename:match("%.(%w+)$");
				if(ext) then
					ext = string.lower(ext)
					if(ext == "bmax" or ext == "x" or ext == "fbx") then
						ParaAsset.LoadParaX("", filename):UnloadAsset();
						LOG.std(nil, "info", "Files", "unload unused asset file: %s", filename);
					end
				end	
			end
		end
	end

	local textureManager = assetManager:GetChild("TextureManager")
	for i=1, textureManager:GetChildCount(0) do
		local attr = textureManager:GetChildAt(i)
		if(attr:GetField("IsInitialized", false) and attr:GetField("RefCount", 1) <= 1) then
			local filename = attr:GetField("name", "");
			if(filename ~= "") then
				local ext = filename:match("%.(%w+)$");
				-- also release http textures
				if(not ext and filename:match("^https?://")) then
					local localFilename = attr:GetField("LocalFileName", "")	
					ext = localFilename:match("^temp/webcache/.*%.(%w+)$");
				end
				if(ext) then
					ext = string.lower(ext)
					if(ext == "jpg" or ext == "png" or ext == "dds") then
						ParaAsset.LoadTexture("", filename, 1):UnloadAsset();
						LOG.std(nil, "info", "Files", "unload unused asset file: %s", filename);
					end
				end	
			end
		end
	end
end

-- this function is called before a new world is loaded. It will try to unload assets used in previous world.
-- unload all assets in all world directory, where IsInitialized is true and RefCount is 1. 
function Files:UnloadAllWorldAssets()
	local assetManager = ParaEngine.GetAttributeObject():GetChild("AssetManager");

	local paraXManager = assetManager:GetChild("ParaXManager")
	for i=1, paraXManager:GetChildCount(0) do
		local attr = paraXManager:GetChildAt(i)
		if(attr:GetField("IsInitialized", false) and attr:GetField("RefCount", 1) <= 1) then
			local filename = attr:GetField("name", "");
			if(filename ~= "") then
				local ext = filename:match("worlds/DesignHouse/.*%.(%w+)$") or filename:match("temp/.*%.(%w+)$");
				if(ext) then
					ext = string.lower(ext)
					if(ext == "bmax" or ext == "x" or ext == "fbx") then
						ParaAsset.LoadParaX("", filename):UnloadAsset();
						LOG.std(nil, "info", "Files", "unload world asset file: %s", filename);
					end
				end	
			end
		end
	end

	local textureManager = assetManager:GetChild("TextureManager")
	for i=1, textureManager:GetChildCount(0) do
		local attr = textureManager:GetChildAt(i)
		if(attr:GetField("IsInitialized", false) and attr:GetField("RefCount", 1) <= 1) then
			local filename = attr:GetField("name", "");
			if(filename ~= "") then
				local ext = filename:match("worlds/DesignHouse/.*%.(%w+)$") or filename:match("temp/.*%.(%w+)$");
				-- also release http textures
				if(not ext and filename:match("^https?://")) then
					local localFilename = attr:GetField("LocalFileName", "")	
					ext = localFilename:match("^temp/webcache/.*%.(%w+)$");
				end
				if(ext) then
					ext = string.lower(ext)
					if(ext == "jpg" or ext == "png") then
						ParaAsset.LoadTexture("", filename, 1):UnloadAsset();
						LOG.std(nil, "info", "Files", "unload world asset file: %s", filename);
					end
				end	
			end
		end
	end
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

	local world_root = GameLogic.GetWorldDirectory();
	if(info.isAbsoluteFilepath and commonlib.Files.IsAbsolutePath(world_root)) then
		if(filename:sub(1, #world_root) == world_root) then
			info.relativeToWorldPath = filename:sub(#world_root+1, -1);
			info.isInWorldDirectory = true;
		end
	elseif(info.relativeToRootPath and info.relativeToRootPath:sub(1, #world_root) == world_root) then
		info.relativeToWorldPath = info.relativeToRootPath:sub(#world_root+1, -1);
		info.isInWorldDirectory = true;
	end

	

	info.filename = filename:match("([^/]+)$");
	return info;
end

-- @param filename: must be relative to Root directory instead of world directory 
function Files.NotifyNetworkFileChange(filename)
	if(GameLogic.isRemote) then
		-- uploading file
		local relativeFilename = Files.GetRelativePath(filename);
		if(relativeFilename ~= filename) then
			local file = ParaIO.open(filename, "r")
			if(file:IsValid()) then
				local data = file:GetText(0, -1);
				file:close();
				GameLogic.GetPlayer():AddToSendQueue(Packets.PacketPutFile:new():Init(relativeFilename, data));
				LOG.std(nil, "info", "Files", "upload file: %s", relativeFilename)	
			end
		end
	elseif(GameLogic.isServer) then
		local relativeFilename = Files.GetRelativePath(filename);
		if(relativeFilename ~= filename) then
			local servermanager = GameLogic.GetWorld():GetServerManager();
			if(servermanager) then
				LOG.std(nil, "info", "Files", "notify all clients about changed file: %s", relativeFilename)
				servermanager:SendPacketToAllPlayers(Packets.PacketPutFile:new():Init(relativeFilename));
			end
		end
	end
end