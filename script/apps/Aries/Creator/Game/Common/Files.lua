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
echo(Files:FindWorldFiles({}, "blocktemplates/", nMaxFileLevels, nMaxFilesNum, filterFunc))
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketGetFile.lua");
NPL.load("(gl)script/ide/math/StringUtil.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenFileDialog.lua");
local OpenFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenFileDialog");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");

-- additional world search path
Files.worldSearchPath = nil;
-- how many assets to unload during each step. 
Files.garbageCollectStep = 20;

-- add default always-in-memory files here, keep this to minimum, these file will survive UnloadAllUnusedAssets when a new world is loaded. 
local alwaysInMemoryFiles = {
-- system 
["Texture/whitedot.png"] = true,
["Texture/dxutcontrols.dds"] = true,
["Texture/kidui/main/cursor.tga"] = true,
["Texture/Aries/Common/AssetLoader_32bits.png"] = true,
["Texture/Aries/Creator/keepwork/worldshare_32bits.png"] = true,   -- world share main UI
["Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png"] = true,   -- paracraft main UI
["Texture/Aries/Creator/Theme/scroll_track_32bits.png"] = true,
["Texture/3DMapSystem/common/ThemeLightBlue/container_bg.png"] = true,
["Texture/3DMapSystem/common/ThemeLightBlue/slider_button_16.png"] = true,
["Texture/Aries/Common/ThemeKid/editbox_32bits.png"] = true,

-- Loading screen
["Texture/Aries/Login/Login/teen/loading_green_32bits.png"] = true,
["Texture/Aries/Login/Login/teen/loading_gray_32bits.png"] = true,
["Texture/Aries/Login/Login/teen/progressbar_green_tile.png"] = true,
["Texture/Aries/Creator/Mobile/blocks_Background.png"] = true,  

-- camera and actors
["character/CC/02human/actor/actor.x"] = true,
["character/CC/02human/CustomGeoset/actor.x"] = true,
["character/CC/05effect/Birthplace/Birthplace.x"] = true,
-- make sure the camera model is preloaded, otherwise the first movie block's camera height will be wrong
["character/CC/02human/Camera/Camera.x"] = true, 

[""] = true,
}

-- currently only one addtional world search path can be added. 
function Files.AddWorldSearchPath(worldPath)
	Files.worldSearchPath = worldPath;
end

function Files.GetAdditionalWorldSearchPath()
	return Files.worldSearchPath;
end

-- this is a temporary folder that is cleared on world load.
function Files.CreateGetAdditionalWorldSearchPath()
	if(not Files.worldSearchPath) then
		Files.worldSearchPath = ParaIO.GetWritablePath().."temp/paraworld/temp/";
	end
	return Files.worldSearchPath;
end


function Files.GetTempPath()
	if(not Files.projectTempPath) then
		Files.projectTempPath = ParaIO.GetWritablePath().."temp/";
	end
	return Files.projectTempPath;
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
Files.loadedAssetFiles = {};

-- call this function when world is loaded. 
function Files:ClearFindFileCache()
	self.reverse_cache = {};
	self.cache = {};
	self.loadedAssetFiles = {};
	Files.ClearWorldSearchPaths()
end

-- this is usually used when user entered or left a complex closed room full of assets.
-- one may expect 2 or 3 seconds stall on graphics
function Files:SafeUnloadAllAssets()
	Files:UnloadAllUnusedAssets(10000)
end

local s_managers = {};
-- @param name: "ParaXManager" or "TextureManager"
function Files:GetAssetManager(name)
	if(s_managers[name]) then
		return s_managers[name];
	else
		local assetManager = ParaEngine.GetAttributeObject():GetChild("AssetManager");
		s_managers[name] = assetManager:GetChild(name)
		return s_managers[name];
	end
end

-- @param MaxRefCount: release all assets whose reference count it smaller than or equal to this value. default to 1. 
function Files:UnloadAllUnusedAssets(MaxRefCount)
	MaxRefCount = MaxRefCount or 1;

	local paraXManager = self:GetAssetManager("ParaXManager")
	for i=1, paraXManager:GetChildCount(0) do
		local attr = paraXManager:GetChildAt(i)
		if(attr:GetField("IsInitialized", false) and attr:GetField("RefCount", 1) <= MaxRefCount) then
			local filename = attr:GetField("name", "");
			if(filename ~= "" and not self:IsFileAlwaysInMemory(filename)) then
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

	local textureManager = self:GetAssetManager("TextureManager")
	for i=1, textureManager:GetChildCount(0) do
		local attr = textureManager:GetChildAt(i)
		
		-- remove following line, for debugging texture reference count
		-- LOG.std(nil, "debug", "Files", "texture file: %s, Inited: %s, Ref:%d", attr:GetField("name", ""), tostring(attr:GetField("IsInitialized", false)), attr:GetField("RefCount", 1));

		if(attr:GetField("IsInitialized", false) and attr:GetField("RefCount", 1) <= MaxRefCount) then
			local filename = attr:GetField("name", "");
			if(filename ~= "" and not self:IsFileAlwaysInMemory(filename)) then
				local ext = filename:match("%.(%w+)$");
				-- also release http textures
				if(not ext and filename:match("^https?://")) then
					ext = "http";
				end
				if(ext) then
					ext = string.lower(ext)
					if(ext == "jpg" or ext == "png" or ext == "dds" or ext == "http") then
						ParaAsset.LoadTexture("", filename, 1):UnloadAsset();
						LOG.std(nil, "info", "Files", "unload unused asset file: %s", filename);
					end
				end	
			end
		end
	end
end

function Files:AddAlwaysInMemoryFile(filename)
	alwaysInMemoryFiles[filename] = true;
end

function Files:IsFileAlwaysInMemory(filename)
	return alwaysInMemoryFiles[filename or ""];
end

-- for debugging only
function Files:PrintAllAssets()
	local managers = {"TextureManager", "ParaXManager"}
	local initedList = {};
	local uninitedList = {};
	for _, managerName in ipairs(managers) do
		local manager = self:GetAssetManager(managerName)
		for i=1, manager:GetChildCount(0) do
			local attr = manager:GetChildAt(i)
			local item = {managerName, attr:GetField("name", ""), attr:GetField("IsInitialized", false), attr:GetField("RefCount", 1)}
			if(item[3]) then
				initedList[#initedList + 1] = item
			else
				uninitedList[#uninitedList + 1] = item
			end
		end
	end
	LOG.std(nil, "info", "Files", "%d files are initied", #initedList);
	for _, item in ipairs(initedList) do
		LOG.std(nil, "info", "Files", "%s file: %s, Inited, Ref:%d", item[1], item[2], item[4]);
	end
	LOG.std(nil, "info", "Files", "%d files are UnInited", #uninitedList);
	for _, item in ipairs(uninitedList) do
		LOG.std(nil, "info", "Files", "%s file: %s, UnInited, Ref:%d", item[1], item[2], item[4]);
	end
end

function Files:IsAssetFileLoaded(filename)
	if(self.loadedAssetFiles[filename]) then
		return true;
	else
		if(ParaAsset.LoadParaX("", filename):GetAttributeObject():GetField("IsLoaded", false)) then
			self.loadedAssetFiles[filename] = true;
			return true;
		else
			return false;
		end
	end
end

-- this is usually used when user entered or left a complex closed room full of assets.
-- one may expect 1 or 2 seconds stall on graphics
function Files:SafeUnloadAllWorldAssets()
	Files:UnloadAllWorldAssets(10000)
end

-- this function is called before a new world is loaded. It will try to unload assets used in previous world.
-- unload all assets in all world directory, where IsInitialized is true and RefCount is 1. 
-- @param MaxRefCount: release all assets whose reference count it smaller than or equal to this value. default to 1. 
function Files:UnloadAllWorldAssets(MaxRefCount)
	MaxRefCount = MaxRefCount or 1;

	local paraXManager = self:GetAssetManager("ParaXManager")
	for i=1, paraXManager:GetChildCount(0) do
		local attr = paraXManager:GetChildAt(i)
		if(attr:GetField("IsInitialized", false) and attr:GetField("RefCount", 1) <= MaxRefCount) then
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

	local textureManager = self:GetAssetManager("TextureManager")
	for i=1, textureManager:GetChildCount(0) do
		local attr = textureManager:GetChildAt(i)
		
		if(attr:GetField("IsInitialized", false) and attr:GetField("RefCount", 1) <= MaxRefCount) then
			local filename = attr:GetField("name", "");
			if(filename ~= "") then
				local ext = filename:match("worlds/DesignHouse/.*%.(%w+)$") or filename:match("temp/.*%.(%w+)$");
				-- also release http textures
				if(not ext and filename:match("^https?://")) then
					ext = "http";
				end
				if(ext) then
					ext = string.lower(ext)
					if(ext == "jpg" or ext == "png"  or ext == "dds" or ext == "http") then
						ParaAsset.LoadTexture("", filename, 1):UnloadAsset();
						LOG.std(nil, "info", "Files", "unload world asset file: %s", filename);
					end
				end	
			end
		end
	end
end

-- how many assets to unload during each step. 
-- @param nStep: default to 20.
function Files:SetGarbageColectStep(nStep)
	Files.garbageCollectStep = nStep or 20;
end

function Files:GetGarbageColectStep()
	return Files.garbageCollectStep;
end

local nXfileGCIndex = 0;
local nTexfileGCIndex = 0;

-- call this function regularly to release unreferenced assets 
-- @param bModel: if not false, we will garbage collect model files
-- @param bTexture: if not false, we will garbage collect texture files
-- @see also:  SetGarbageColectStep()
function Files:GarbageCollect(bModel, bTexture)
	local nStep = self:GetGarbageColectStep()

	if(bModel~=false) then
		local count = 0;

		local paraXManager = self:GetAssetManager("ParaXManager")
		local nTotalCount = paraXManager:GetChildCount(0)
		for i=1, math.min(nStep*10, nTotalCount) do
			nXfileGCIndex = nXfileGCIndex + 1;
			local attr = paraXManager:GetChildAt(((i+nXfileGCIndex)%nTotalCount)+1)
			if(attr:GetField("IsInitialized", false) and attr:GetField("RefCount", 1) <= 1) then
				local filename = attr:GetField("name", "");
				if(filename ~= "" and not self:IsFileAlwaysInMemory(filename)) then
					local ext = filename:match("%.(%w+)$");
					if(ext) then
						ext = string.lower(ext)
						if(ext == "bmax" or ext == "x" or ext == "fbx") then
							ParaAsset.LoadParaX("", filename):UnloadAsset();
							count = count + 1;
							LOG.std(nil, "debug", "Files", "GarbageCollect unused asset file: %s", filename);
							if(count >= nStep) then
								break;
							end
						end
					end	
				end
			end
		end
		if(count > 0) then
			LOG.std(nil, "debug", "Files", "GarbageCollect %d/%d x files in this step", count, nTotalCount);
		end
	end

	if(bTexture~=false) then
		local count = 0;
		local textureManager = self:GetAssetManager("TextureManager")
		local nTotalCount = textureManager:GetChildCount(0)
		for i=1, math.min(nStep*10, nTotalCount) do
			nXfileGCIndex = nXfileGCIndex + 1;
			local attr = textureManager:GetChildAt(((i+nXfileGCIndex)%nTotalCount)+1)
			if(attr:GetField("IsInitialized", false) and attr:GetField("RefCount", 1) <= 1) then
				local filename = attr:GetField("name", "");
				if(filename ~= "" and not self:IsFileAlwaysInMemory(filename)) then
					local ext = filename:match("%.(%w+)$");
					-- also release http textures
					if(not ext and filename:match("^https?://")) then
						ext = "http";
					end
					if(ext) then
						ext = string.lower(ext)
						if(ext == "jpg" or ext == "png" or ext == "dds" or ext == "http") then
							ParaAsset.LoadTexture("", filename, 1):UnloadAsset();
							count = count + 1;
							LOG.std(nil, "debug", "Files", "GarbageCollect unused asset file: %s", filename);
							if(count >= nStep) then
								break;
							end
						end
					end	
				end
			end
		end
		if(count > 0) then
			LOG.std(nil, "debug", "Files", "GarbageCollect %d/%d texture files in this step", count, nTotalCount);
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
-- so that the next time the same file is requried, we will return fast for both exist or non-exist ones. 
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

function Files:UnloadFoldAssets(foldpath)
	local assetManager = ParaEngine.GetAttributeObject():GetChild("AssetManager");
	local textureManager = assetManager:GetChild("TextureManager")	
	
	for i=1, textureManager:GetChildCount(0) do
		local attr = textureManager:GetChildAt(i)
		if(attr:GetField("IsInitialized", false) and attr:GetField("RefCount", 1) <= 1) then
			local filename = attr:GetField("name", "");
			
			if filename ~= "" and string.find(filename, foldpath) then
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

-- find all files in the given world directory. 
-- @param output: output files, default to a new empty table
-- @param folder: relative to world folder. default to "", which is root of world. values like "blocktemplates/"
-- @param nMaxFileLevels: default to 2
-- @param nMaxFilesNum: default to 500
-- @param filter: a function({filename, filesize, writedate}) return true or false end. if nil, all files are returned. 
--  it can also be string like, "model", "bmax", "audio", "texture", "xml", "script"
-- @return output: a table array containing relative to folder file name, such as below:
-- {{filename,filesize,createdate,fileattr,accessdate,writedate,},}
function Files:FindWorldFiles(output, folder, nMaxFileLevels, nMaxFilesNum, filterFunc)
	local rootPath = GameLogic.GetWorldDirectory()
	folder = folder or ""
	rootPath = rootPath..folder;
	local searchLevel = nMaxFileLevels or 2
	local nMaxFilesNum = nMaxFilesNum or 500
	local files = output or {};
	local duplicates
	filterFunc = OpenFileDialog.GetFilterFunction(filterFunc) or filterFunc;
	local result = commonlib.Files.Find(files, rootPath, searchLevel, nMaxFilesNum, filterFunc or "*");
	
	if(System.World.worldzipfile) then
		local filemap = {};
		for i = 1, #result do
			filemap[result[i].filename] = true;
		end
		local zip_archive = ParaEngine.GetAttributeObject():GetChild("AssetManager"):GetChild("CFileManager"):GetChild(System.World.worldzipfile);
		local zipParentDir = zip_archive:GetField("RootDirectory", "");
		if(zipParentDir~="") then
			if(rootPath:sub(1, #zipParentDir) == zipParentDir) then
				rootPath = rootPath:sub(#zipParentDir+1, -1)
				local result = commonlib.Files.Find({}, rootPath, searchLevel, nMaxFilesNum, ":.", System.World.worldzipfile);
				for i = 1, #result do
					-- skip duplicated names
					if(not filemap[result[i].filename]) then
						if(filterFunc and filterFunc(result[i])) then
							files[#files+1] = result[i];
						end
					end
				end
			end
		end
	end
	return files;
end

-- find all files in folder relative to the root directory. both disk and zip files are searched. 
-- @param output: output files, default to a new empty table
-- @param folder: relative to world folder. default to "", which is root of world. values like "blocktemplates/"
-- @param nMaxFileLevels: default to 2
-- @param nMaxFilesNum: default to 500
-- @param filter: a function({filename, filesize, writedate}) return true or false end. if nil, all files are returned. 
--  it can also be string like, "model", "bmax", "audio", "texture", "xml", "script"
-- @return output: a table array containing relative to folder file name, such as below:
-- {{filename,filesize,createdate,fileattr,accessdate,writedate,},}
function Files:FindSystemFiles(output, folder, nMaxFileLevels, nMaxFilesNum, filterFunc)
	local rootPath = folder or ""
	local searchLevel = nMaxFileLevels or 2
	local nMaxFilesNum = nMaxFilesNum or 500
	local files = output or {};
	local duplicates
	filterFunc = OpenFileDialog.GetFilterFunction(filterFunc) or filterFunc;
	local result = commonlib.Files.Find(files, rootPath, searchLevel, nMaxFilesNum, filterFunc or "*");
	
	local filemap = {};
	for i = 1, #result do
		filemap[result[i].filename] = true;
	end
	local result = commonlib.Files.Find({}, rootPath, searchLevel, nMaxFilesNum, ":.", "*.zip");
	for i = 1, #result do
		-- skip duplicated names
		if(not filemap[result[i].filename]) then
			if(filterFunc and filterFunc(result[i])) then
				files[#files+1] = result[i];
			end
		end
	end
	return files;
end