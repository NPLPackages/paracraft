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
			DragDropHandlers.handleModelFile(filename);
		end
	end,
};


function DragDropHandlers.handleZipFile(filename)
	local beWorld;
	local name = filename:match("[/\\]([^/\\]+%.zip)$");
	local file_dir = string.gsub(filename,name,"");
	local temp_dir = "temp/dropfiles/";
	local temp_path = temp_dir..name;
	if(ParaIO.CopyFile(filename, temp_path, true)) then
		ParaAsset.OpenArchive(temp_path, true);	
		local out = commonlib.Files.Find({}, temp_dir, 0, 200, "*.", "*.zip");
		local zip_name = string.match(out[1]["filename"],"([^/]*)");
		local zip_dir = temp_dir..zip_name;
		local result = commonlib.Files.Find({}, zip_dir, 0, 2000, "*.*", "*.zip");
		local item;
		for _, item in ipairs(result) do
			if(item.filename == "worldconfig.txt") then
				beWorld = true;
				break;
			end
		end
		ParaAsset.CloseArchive(temp_path);
		ParaIO.DeleteFile(temp_path);
	else
		if(filename:match("[/\\]blocktexture[^/\\]+%.zip$")) then
			beWorld = false;
		else
			beWorld = true;
		end
	end
	if(not beWorld) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/TextureModPage.lua");
		local TextureModPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TextureModPage");
		TextureModPage.InstallTexturePack(filename);
	else
		NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/EnterGamePage.lua");
		local EnterGamePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EnterGamePage");
		EnterGamePage.OnOpenPkgFile(filename)
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

function DragDropHandlers.handleModelFile(filename)
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