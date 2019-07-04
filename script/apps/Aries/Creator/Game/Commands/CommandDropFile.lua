--[[
Title: dropfile command
Author(s): LiXizhi
Date: 2014/10/10
Desc: dropfile command
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandDropFile.lua");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
Commands.dropfile.handler("dropfile", filename);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

local DragDropHandlers = {};

Commands["dropfile"] = {
	name="dropfile", 
	quick_ref="/dropfile [absolute_filepath]", 
	desc=[[drag and drop an external file to the app. following files are supported:
texture template zip file
world zip file
block template xml file
other files...
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local filename = commonlib.Encoding.Utf8ToDefault(cmd_text);
		local ext = filename:match("%.(%w+)$");
		ext = ext and ext:lower();
		if(ext == "zip") then
			DragDropHandlers.handleZipFile(filename);
		elseif(ext == "mca" or filename:match("%.mc[ra]%.tmp$")) then
			DragDropHandlers.handleMCImporterFile(filename);
		elseif(filename:match("%.blocks%.stream%.xml$")) then
			DragDropHandlers.handleBlockStreamFile(filename)
		elseif(ext == "fbx" or ext == "x" or ext == "bmax" or filename:match("%.blocks%.xml$")) then
			DragDropHandlers.handleModelFile(filename, ext);
		end
	end,
};

-- get zip file type according to zip file by searching for featured file content
-- @param filename: file name of the zip archive file. such as "temp/abc.zip"
-- @return nil | "world" | "blocktexture" | "mod" | "npl_package"
function DragDropHandlers.GetZipFileType(filename)
	if(filename:match("%.zip$") and ParaAsset.OpenArchive(filename, false)) then
		local zipType;
		if(not zipType) then
			local result = commonlib.Files.Find({}, "", 0, 1, "Mod/*/main.lua", filename);
			if(#result > 0) then
				zipType = "mod";
			end
		end
		if(not zipType) then
			local result = commonlib.Files.Find({}, "", 0, 1, "*/Mod/*/main.lua", filename);
			if(#result > 0) then
				zipType = "mod";
			end
		end
		if(not zipType) then
			local result = commonlib.Files.Find({}, "", 0, 1, "worldconfig.txt", filename);
			if(#result > 0) then
				zipType = "world";
			end
		end
		if(not zipType) then
			local result = commonlib.Files.Find({}, "", 0, 1, "*/worldconfig.txt", filename);
			if(#result > 0) then
				zipType = "world";
			end
		end
		if(not zipType) then
			local result = commonlib.Files.Find({}, "", 0, 10, "*/*.png", filename);
			if(#result > 0) then
				for _, item in ipairs(result) do
					if(item.filename:match("/%d+_[^/]+$")) then
						zipType = "blocktexture";
						break;
					end
				end
			end
		end
		ParaAsset.CloseArchive(filename);
		return zipType;
	end
end

function DragDropHandlers.handleZipFile(filename)
	local beWorld;
	local name = filename:match("[/\\]([^/\\]+%.zip)$");
	local file_dir = string.gsub(filename,name,"");
	local temp_dir = ParaIO.GetWritablePath().."temp/dropfiles/";
	local temp_path = temp_dir..name;
	local zipType;
	if(ParaIO.CopyFile(filename, temp_path, true)) then
		zipType = DragDropHandlers.GetZipFileType(temp_path)
		ParaIO.DeleteFile(temp_path);
	end
	LOG.std(nil, "info", "handleZipFile", "%s is of type %s", filename, zipType or "unknown");
	if(zipType == "blocktexture") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/TextureModPage.lua");
		local TextureModPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TextureModPage");
		TextureModPage.InstallTexturePack(filename);
	elseif(zipType == "world") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/EnterGamePage.lua");
		local EnterGamePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EnterGamePage");
		EnterGamePage.OnOpenPkgFile(filename)
	elseif(zipType == "mod") then
		_guihelper.MessageBox(format(L"确定要安装Mod插件: %s?", name), function(res)
			if(res == _guihelper.DialogResult.Yes) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Mod/ModManager.lua");
				local ModManager = commonlib.gettable("Mod.ModManager");
				local pluginloader = ModManager:GetLoader();
				pluginloader:InstallFromZipFile(filename);
			end
		end, _guihelper.MessageBoxButtons.YesNo);
	end
end

function DragDropHandlers.handleBlockStreamFile(filename)
	if(System.options.is_mcworld) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockFileMonitorTask.lua");
		local task = MyCompany.Aries.Game.Tasks.BlockFileMonitor:new({filename=filename})
		task:Run();
	else
		_guihelper.MessageBox(L"请先进入创意空间");
	end
end

function DragDropHandlers.handleMCImporterFile(filename)
	if(filename:match("%.mca$")) then
		local folder = filename:gsub("region[/\\][^/\\]+%.mca$", "");
		if(folder) then
			_guihelper.MessageBox(format(L"你确定要导入世界%s? 可能需要0-1分钟.", folder), function()
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MCImporterTask.lua");
				local task = MyCompany.Aries.Game.Tasks.MCImporter:new({folder=folder, min_y=0, bExportOpaque=false})
				task:Run();	
			end)
		end
	elseif(filename:match("%.mc[ra]%.tmp$")) then
		_guihelper.MessageBox(format(L"你确定要导入世界%s? 可能需要0-1分钟.", filename), function()
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MCImporterTask.lua");
			local task = MyCompany.Aries.Game.Tasks.MCImporter:new({})
			task:cmd_create();
		end)
	end
end

-- @param fileType: "model", "blocktemplate", if nil, default to "model"
function DragDropHandlers.SendFileToSceneContext(filename, fileType)
	local sc = GameLogic.GetSceneContext();
	if(sc and sc.handleDropFile) then
		fileType = fileType or "model";
		sc:handleDropFile(filename, fileType);
	end
end

function DragDropHandlers.handleModelFile(filename, ext)
	if(not System.options.is_mcworld) then
		return;
	end
	local info = Files.ResolveFilePath(filename);
	if(info.isInWorldDirectory) then
		DragDropHandlers.SendFileToSceneContext(info.relativeToWorldPath);
	else
		local targetfile = "blocktemplates/"..info.filename;
		local destfile = Files.WorldPathToFullPath(targetfile);
		
		local function CopyFiles()
			local res = ParaIO.CopyFile(filename, destfile, true);
			if(ext == "fbx") then
				-- also copy the xml file associated with the fbx if any
				local xmlFile = filename:gsub("%.%w%w%w$", ".xml");
				if(Files.FileExists(xmlFile)) then
					local destXmlFile = destfile:gsub("%.%w%w%w$", ".xml");
					res = ParaIO.CopyFile(xmlFile, destXmlFile, true) and res;
				end
			end
			return res;
		end

		if(Files.FileExists(destfile)) then
			_guihelper.MessageBox(string.format(L"当前世界已经存在:%s 是否覆盖?", destfile), function(res)
				if(res and res == _guihelper.DialogResult.Yes) then
					CopyFiles();
				end
				DragDropHandlers.SendFileToSceneContext(targetfile);
			end, _guihelper.MessageBoxButtons.YesNo);
		else
			_guihelper.MessageBox(string.format(L"是否导入外部模型文件:%s?", filename), function(res)
				if(CopyFiles()) then
					DragDropHandlers.SendFileToSceneContext(targetfile);
				else
					GameLogic.AddBBS(nil, format(L"导入失败了 %s", filename));
				end
			end);
		end
	end
end