--[[
Title: CodeBlockFileSync
Author(s): LiXizhi
Date: 2024/2/28
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockFileSync.lua");
local CodeBlockFileSync = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockFileSync");
CodeBlockFileSync:DeleteWorldFolder()
CodeBlockFileSync:InitWorldFolder()
CodeBlockFileSync:OpenFolder()

CodeBlockFileSync:DumpAllCodeBlocksToSingleFile("temp/AllCodeBlocksInWorld.lua", true)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local FindBlockTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.FindBlockTask");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local CodeBlockFileSync = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockFileSync"));

-- should begin with . to be excluded from git sync.
CodeBlockFileSync.codeDir = ".codeblock/";

function CodeBlockFileSync:ctor()
	self.isPlatformSupported = System.os.GetPlatform() == "win32";
	if(self.isPlatformSupported) then
		GameLogic:Connect("WorldLoaded", self, self.OnWorldLoaded, "UniqueConnection");
		GameLogic:Connect("WorldUnloaded", self, self.OnWorldUnloaded, "UniqueConnection");
	end
end

function CodeBlockFileSync:OnWorldLoaded()
	CodeBlockWindow:Connect("codeUpdatedToEntity", self, self.TrySyncEntityToFile, "UniqueConnection");
	
	if(self:HasCodeBlockFolder()) then
		self:GetParentDir(true);
		LOG.std(nil, "info", "CodeBlockFileSync", ".codeblock/ folder found in world %s", GameLogic.GetWorldDirectory());
	end
end

-- find if there is at least one file in the folder
function CodeBlockFileSync:HasCodeBlockFolder()
	local output = Files:FindWorldFiles(nil, CodeBlockFileSync.codeDir, 0, 2);
	if(output and #output > 0) then
		return true;
	end
end

function CodeBlockFileSync:SyncFileToEntity(fullname)
	if(fullname) then
		fullname = fullname:gsub("\\", "/");
		local filename = fullname:match("/%.codeblock/(.*)%.%w%w?%w?$")
		if(filename) then
			local name, x,y,z = filename:match("^(.*)_(%d+)_(%d+)_(%d+)$");
			if(x and y and z) then
				x = tonumber(x);
				y = tonumber(y);
				z = tonumber(z);
				local entity = EntityManager.GetBlockEntity(x, y, z);
				if(entity and entity.IsBlocklyEditMode and not entity:IsBlocklyEditMode() and (name == (entity:GetDisplayName() or ""))) then
					local code  = commonlib.Files.GetFileText(fullname);
					if(code) then
						if(entity:GetNPLCode() ~= code) then
							if(entity.lastToFileSyncTime and (commonlib.TimerManager.GetCurrentTime() - entity.lastToFileSyncTime) < 2000) then
								-- do not update if it is just updated by the same user in paracraft. 
								return;
							end
							entity:BeginEdit()
							entity:SetNPLCode(code);
							entity:EndEdit()
							entity:remotelyUpdated();
						end
					end
				end
			end
		end
	end
end

function CodeBlockFileSync:OnWorldFileChange(msg)
	if(msg.type == "modified") then
		self:SyncFileToEntity(msg.fullname)
	end
end

function CodeBlockFileSync:TrySyncEntityToFile(entity)
	if(self.parentDir) then
		local blockFilename = self:GetParentDir()..self:GetEntityFileName(entity)
		if(ParaIO.DoesFileExist(blockFilename)) then
			self:SyncEntityToFile(entity, true);
		end
	end
end

function CodeBlockFileSync:OnWorldUnloaded()
	self.parentDir = nil;
end

function CodeBlockFileSync:SyncWorldFolder()
end

function CodeBlockFileSync:DeleteWorldFolder()
	local filename = GameLogic.GetWorldDirectory()..CodeBlockFileSync.codeDir
	commonlib.Files.DeleteFolder(filename);
end

local LanguageConfig;
local LuaFmt;

-- copy code entity to .codeblock folder using displayname and blockpos as filename.
-- @param entity: the code block entity
-- @param isAlwaysGenerate: if true, we will always generate file even for empty and unchanged file. 
-- @return bUpdated, filename
function CodeBlockFileSync:SyncEntityToFile(entity, isAlwaysGenerate)
	if(entity and entity.IsBlocklyEditMode) then
		local cmd;
		local isBlockly = entity:IsBlocklyEditMode()
		if(isBlockly) then
			cmd = entity:GetCommand()
		else
			cmd = entity:GetNPLCode()
		end
		if((cmd and cmd ~= "") or isAlwaysGenerate) then
			cmd = cmd or "";
			if(isBlockly) then
				LanguageConfig = LanguageConfig or NPL.load("script/ide/System/UI/Blockly/Blocks/LanguageConfig.lua");
				LuaFmt = LuaFmt or NPL.load("script/ide/System/UI/Blockly/LuaFmt.lua");
				local language = entity and entity.GetLanguageConfigFile and entity:GetLanguageConfigFile();
				if (LanguageConfig:GetLanguageType(language) == "npl") then
					local ok, errinfo = pcall(function()
						cmd = LuaFmt.Pretty(cmd) or cmd;
						--cmd = string.gsub(cmd, "\t", "    ");
					end);
				end
			end
			local blockFilename = self:GetParentDir()..self:GetEntityFileName(entity)
			local bUpdated;
			if(isAlwaysGenerate or commonlib.Files.GetFileText(blockFilename) ~= cmd) then
				-- write cmd to file. 
				ParaIO.CreateDirectory(blockFilename);
				local file = ParaIO.open(blockFilename, "w");
				if (file) then
					file:WriteString(cmd);
					file:close();
					bUpdated = true;
					LOG.std(nil, "debug", "CodeBlockFileSync", "code block %s is synced to file %s", entity:GetDisplayName() or "", blockFilename);
				else
					LOG.std(nil, "warn", "CodeBlockFileSync", "failed to write to file %s", blockFilename);
				end
			end
			entity.lastToFileSyncTime = commonlib.TimerManager.GetCurrentTime();
			return bUpdated, blockFilename;
		end
	end
end

function CodeBlockFileSync:GetParentDir(bRefresh)
	if(not self.parentDir or bRefresh) then
		self.parentDir = GameLogic.GetWorldDirectory()..CodeBlockFileSync.codeDir
		GameLogic:Connect("worldFileChanged", CodeBlockFileSync, CodeBlockFileSync.OnWorldFileChange, "UniqueConnection");
	end
	return self.parentDir;
end

function CodeBlockFileSync:GetEntityFileName(entity)
	if(entity) then
		local blockFilename;
		local displayName = entity:GetDisplayName() or "";
		blockFilename = string.format("%s_%d_%d_%d", displayName, entity:GetBlockPos());
		if(entity:IsBlocklyEditMode()) then
			blockFilename = blockFilename..".blockly";
		end
		local ext = "lua";
		local langConfig = entity.GetLanguageConfig and entity:GetLanguageConfig();
		if(langConfig and langConfig.GetFileExtension) then
			ext = langConfig:GetFileExtension() or ext;
		elseif(entity.GetCodeLanguageType and entity:GetCodeLanguageType() == "python") then
			ext = "py"
		end
		blockFilename = blockFilename.."."..ext;
		return blockFilename;
	end
end

-- create `.codeblock` folder in the world folder
-- @param isAlwaysGenerate: if true, we will always generate file even for empty and unchanged file. 
function CodeBlockFileSync:InitWorldFolder(isAlwaysGenerate)
	if(GameLogic.IsReadOnly()) then
		return
	end
	local filename = self:GetParentDir(true);
	ParaIO.CreateDirectory(filename);
	
	local entities = GameLogic.EntityManager.FindEntities({category="b", type="EntityCode"});
	if(entities) then
		local updatedCount = 0;
		for i, entity in ipairs(entities) do
			if(self:SyncEntityToFile(entity, isAlwaysGenerate)) then
				updatedCount = updatedCount + 1;
			end
		end
		LOG.std(nil, "info", "CodeBlockFileSync", "%d out of %d codeblocks synced in folder %s", updatedCount, #entities, filename);
	end
end

function CodeBlockFileSync:OpenFolder()
	if(self.parentDir) then
		ParaGlobal.ShellExecute("open", self.parentDir, "", "", 1);
	end
end

function CodeBlockFileSync:AutoDumpAllCodeBlocks(isIteractive)
	if(GameLogic.IsReadOnly()) then
		return
	end
	if(self.isPlatformSupported) then
		if(self:HasCodeBlockFolder() and isIteractive) then
			_guihelper.MessageBox(L"是否重新生成.codeblock/代码目录？", function(res)
				if(res and res == _guihelper.DialogResult.Yes) then
					self:DeleteWorldFolder()
					self:InitWorldFolder(true)
				else
					self:InitWorldFolder();
				end
				self:OpenInVsCode()
			end, _guihelper.MessageBoxButtons.YesNo);
		else
			self:InitWorldFolder(true)
			self:OpenInVsCode()
		end
	else
		self:DumpAllCodeBlocksToSingleFile("temp/AllCodeBlocksInWorld.lua", true)
	end
end

-- @param entity: if nil, it will open the world folder in vs code
function CodeBlockFileSync:OpenInVsCode(entity)
	local filename;
	if(entity) then
		filename = self:GetParentDir()..self:GetEntityFileName(entity)
	end
	if(System.os.GetPlatform() == "win32") then
		GameLogic.RunCommand("/clicktocontinue off");
		GameLogic.RunCommand("/start npl");

		-- open in vs code
		if(filename) then
			local cmd = "chcp 65001 >nul\n"..string.format([[@echo off
call code -r "%s"
call code -r "%s"
]], GameLogic.GetWorldDirectory(), filename);
			--	chcp 65001 requires \r\n in windows. 
			cmd = cmd:gsub("\r?\n", "\r\n");
			System.os.run(cmd);
		else
			System.os.run("chcp 65001 >nul\r\n"..string.format([[call code -r "%s"]], GameLogic.GetWorldDirectory()));
		end
	end
end

-- @param filename: if nil, it will be "temp/AllCodeBlocksInWorld.lua"
function CodeBlockFileSync:DumpAllCodeBlocksToSingleFile(filename, bOpen)
	filename = filename or "temp/AllCodeBlocksInWorld.lua"
	local entities = GameLogic.EntityManager.FindEntities({category="b", type="EntityCode"});
	if(entities) then
		local file = ParaIO.open(filename, "w");
		if (file) then
			file:WriteString(format("-- auto generated by `/dump codeblock` command \n"));
			file:WriteString(format("-- world: %s\n", GameLogic.GetWorldDirectory()));
			file:WriteString(format("-- codeblock count: %d\n", #entities));
					
			local LanguageConfig = NPL.load("script/ide/System/UI/Blockly/Blocks/LanguageConfig.lua");
			local LuaFmt = NPL.load("script/ide/System/UI/Blockly/LuaFmt.lua");

			for i, entity in ipairs(entities) do
				local cmd = entity:GetCommand()
				if(cmd and cmd ~= "") then
					if(entity.IsBlocklyEditMode and entity:IsBlocklyEditMode()) then
						local language = entity and entity.GetLanguageConfigFile and entity:GetLanguageConfigFile();
						if (LanguageConfig:GetLanguageType(language) == "npl") then
							local ok, errinfo = pcall(function()
								cmd = LuaFmt.Pretty(cmd) or cmd;
								--cmd = string.gsub(cmd, "\t", "    ");
							end);
						end
					end

					file:WriteString("\n");
					file:WriteString(format("-- codeblock %d: %s -----------------------------\n", i, entity:GetDisplayName() or ""));
					file:WriteString(format("-- /goto %d %d %d\n", entity:GetBlockPos()));
					file:WriteString("\n");
					file:WriteString(cmd);
					file:WriteString("\n");
				end
			end
			file:close();
			if(bOpen) then
				GameLogic.RunCommand("/open npl://editcode?src="..filename)
			end
			return true
		end
	end
end

function CodeBlockFileSync:StripFileComment(text,bCodeFormat)
	if(text and text ~= "") then
		NPL.load("(gl)script/ide/System/Compiler/nplc.lua");
		NPL.load("(gl)script/ide/System/Compiler/nplgen.lua");
		local nplpClass = commonlib.gettable("System.Compiler.nplp")
		local nplgen = commonlib.gettable("System.Compiler.nplgen")
		local nplp = nplpClass:new()
		
		local ok, compiled_src = pcall(function()
			local ast = nplp:src_to_ast_raw(text, filename)
			local gen = nplgen:new()
			gen:SetIgnoreNewLine(true)
			if(bCodeFormat) then
				gen:SetIgnoreIdentation(false)
				gen:SetIdentStepString("\t")
			end
			return gen:run(ast)
		end)

		if(ok) then
			return compiled_src
		else
			return false;
		end
	end
end

local dirList = {
	"script/apps/Aries/Creator/Game/Entity/",
	"script/apps/Aries/Creator/Game/Items/",
	"script/apps/Aries/Creator/Game/blocks/",
}
function CodeBlockFileSync:GetRandomDirectory()
	local index = math.random(1,#dirList)
	return dirList[index]
end

function CodeBlockFileSync:DumpAllCodeBlocks(options)
	local dump_options = options or {}
	local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')
	local world_name = WorldCommon.GetWorldTag("name") or ""
	local filename = dump_options.fileName or "temp/"..world_name.."_codeblocks.txt"
	local fillupDirectory = dump_options.directory or ""
	local stripComments = dump_options.stripComments or true
	local entities = GameLogic.EntityManager.FindEntities({category="b", type="EntityCode"});
	if(entities) then
		local entity_count = #entities
		if fillupDirectory ~= "" and ParaIO.DoesFileExist(fillupDirectory) then 
			if entity_count >= 2 then
				local midIndex = math.floor(entity_count/2) >= 1 and math.floor(entity_count/2) or 1
				local tempEntities = {}
				for i, entity in ipairs(entities) do
					if i <= midIndex then
						tempEntities[#tempEntities+1] = entity
					end
				end
				self:FillUpByCodeBlocks(filename,tempEntities,stripComments)
				self:FillUpByDirectory(filename,fillupDirectory,stripComments)
				tempEntities = {}
				for i, entity in ipairs(entities) do
					if i <= midIndex then
						tempEntities[#tempEntities+1] = entity
					end
				end
				self:FillUpByCodeBlocks(filename,tempEntities,stripComments)
			else
				tempEntities = entities
				self:FillUpByCodeBlocks(filename,tempEntities,stripComments)
				self:FillUpByDirectory(filename,fillupDirectory,stripComments)
			end
			return
		end
		self:FillUpByCodeBlocks(filename,tempEntities,stripComments)
	else
		LOG.std(nil, "warn", "CodeBlockFileSync", "no codeblocks found in the world");
		if fillupDirectory ~= "" and ParaIO.DoesFileExist(fillupDirectory) then 
			self:FillUpByDirectory(filename,fillupDirectory,stripComments)
			return
		end
		LOG.std(nil, "warn", "CodeBlockFileSync", "no directory found to fillup");
	end
end
-- 150kb = 150 * 1024 bytes = 153600 bytes
-- 1 character = 1 byte
local MAX_FILE_SIZE = 153600
function CodeBlockFileSync:FillUpByDirectory(filename,directory,stripComments)
	if not directory then
		return
	end
	local file = ParaIO.open(filename, "a+");
	if (notfile) then
		return
	end
	directory = directory..self:GetRandomDirectory()

	local out_put = {}
	local result = commonlib.Files.Find(out_put, directory, 2, 500, "*.lua");
	if not result or #result == 0 then
		LOG.std(nil, "warn", "CodeBlockFileSync", "no files found in directory %s", directory);
		return
	end
	local randomList = commonlib.GetRandomList(#result,#result)
	local randomNum = #randomList
	for i = 1, randomNum do
		local content = self:GetFileContent(directory.."/"..result[randomList[i]].filename)
		if content and content ~= "" then
			if stripComments then
				content = self:StripFileComment(content,true)
				if content then
					content:gsub("^%s*\n", ""):gsub("\n%s*\n", ""):gsub("\n", "")
					file:WriteString(content)
					file:WriteString("\n")
				end
			else
				content:gsub("^%s*\n", ""):gsub("\n%s*\n", ""):gsub("\n", "")
				file:WriteString(content)
				file:WriteString("\n")
			end
			
			local size = file:GetFileSize();
			if size > MAX_FILE_SIZE then
				file:close();
				break
			end
		end
	end
	file:close();
end

function CodeBlockFileSync:FillUpByCodeBlocks(filename,entities,stripComments)
	local file = ParaIO.open(filename, "a+");
	if (not file) then
		return
	end
	for i, entity in ipairs(entities) do
		local content = entity:GetCommand()
		if content and content ~= "" then
			
			if stripComments then
				content = self:StripFileComment(content,true)
				if content then
					content:gsub("^%s*\n", ""):gsub("\n%s*\n", ""):gsub("\n", "")
					file:WriteString(content)
					file:WriteString("\n")
				end
			else
				content:gsub("^%s*\n", ""):gsub("\n%s*\n", ""):gsub("\n", "")
				file:WriteString(content)
				file:WriteString("\n")
			end
			
			local size = file:GetFileSize();
			if size > MAX_FILE_SIZE + 1024 then
				file:close();
				break
			end
		end
	end
	file:close();
end

function CodeBlockFileSync:GetFileContent(filename)
	if(filename and filename ~= "" and ParaIO.DoesFileExist(filename)) then
		local file = ParaIO.open(filename, "r");
		if (file) then
			local content = file:GetText(0,-1);
			file:close();
			return content;
		end
	end
end

CodeBlockFileSync:InitSingleton();
