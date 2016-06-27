--[[
Title: CommandTemplate
Author(s): LiXizhi
Date: 2014/2/23
Desc: template related command
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandTime.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/EnterGamePage.lua");
NPL.load("(gl)script/apps/Aries/Scene/WorldManager.lua");
NPL.load("(gl)script/apps/Aries/SlashCommand/SlashCommand.lua");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");


Commands["loadtemplate"] = {
	name="loadtemplate", 
	quick_ref="/loadtemplate [-r] [-abspos] [-tp] [-a seconds] [x y z] [templatename]", 
	desc=[[load template to the given position
@param -a seconds: animate building progress. the followed number is the number of seconds (duration) of the animation. 
@param -r: remove blocks
@param -abspos: whether load using absolute position. 
@param -tp: whether teleport player to template player's location. 
@param x,y,z: position or current player position
@param templatename: relative to current world. the file is at blocktemplates/[templatename].blocks.xml
default name is "default"
/loadtemplate ~0 ~2 ~ test
/loadtemplate -a 3 test
/loadtemplate -r test
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
		local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
		
		local option;
		local load_anim_duration;
		local operation = BlockTemplate.Operations.Load;
		local UseAbsolutePos, TeleportPlayer;
		while(cmd_text) do
			option, cmd_text = CmdParser.ParseOption(cmd_text);
			if(option) then
				if(option == "a") then
					load_anim_duration, cmd_text = CmdParser.ParseInt(cmd_text);
					if(load_anim_duration ~= 0) then
						operation = BlockTemplate.Operations.AnimLoad;
					end
				elseif(option == "r") then
					operation = BlockTemplate.Operations.Remove;
				elseif(option == "abspos") then
					UseAbsolutePos = true;
				elseif(option == "tp") then
					TeleportPlayer = true;
				end
			else
				break;
			end
		end
		load_anim_duration = load_anim_duration or 0;

		local x, y, z, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity);
		if(not x) then
			fromEntity = fromEntity or EntityManager.GetPlayer();
			if(fromEntity) then
				x,y,z = fromEntity:GetBlockPos();
			end
		end
		if(x) then
			local templatename = cmd_text:gsub("^blocktemplates/", ""):gsub("%.blocks%.xml$", "");
			if(templatename == "") then
				templatename = "default";
			end
			local filename = format("%sblocktemplates/%s.blocks.xml", GameLogic.current_worlddir, templatename);

			local task = BlockTemplate:new({operation = operation, filename = filename,
				blockX = x,blockY = y, blockZ = z, bSelect=nil, load_anim_duration=load_anim_duration,
				UseAbsolutePos = UseAbsolutePos,TeleportPlayer=TeleportPlayer,
				})
			task:Run();
		end
	end,
};


Commands["savetemplate"] = {
	name="savetemplate", 
	quick_ref="/savetemplate [templatename]", 
	desc=[[save template with current selection
@param templatename: if no name is provided, it will be default
/savetemplate test
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local templatename = cmd_text:match("(%S*)$");
		if(not templatename or templatename == "") then
			templatename = "default";
		end
		templatename = templatename:gsub("^blocktemplates/", ""):gsub("%.blocks%.xml$", "");
		local filename = format("%sblocktemplates/%s.blocks.xml", GameLogic.current_worlddir, templatename);

		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
		local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
		local task = BlockTemplate:new({operation = BlockTemplate.Operations.Save, filename = filename, bSelect=nil})
		if(task:Run()) then
			BroadcastHelper.PushLabel({id="savetemplate", label = format(L"模板成功保存到:%s", commonlib.Encoding.DefaultToUtf8(filename)), max_duration=4000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
		end
	end,
};

Commands["savemodel"] = {
	name="savemodel", 
	quick_ref="/savemodel [-auto_scale] [modelname]", 
	desc=[[save bmax model with current selection. 
@param -auto_scale: whether or not scale model to one block size. default value is true
@param modelname: if no name is provided, it will be "default"
@return true, filename
/savemodel test
/savemodel -auto_scale false test
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local option;
		local auto_scale;
		while(cmd_text) do
			option, cmd_text = CmdParser.ParseOption(cmd_text);
			if(option) then
				if(option == "auto_scale") then
					auto_scale, cmd_text = CmdParser.ParseBool(cmd_text);
				end
			else
				break;
			end
		end
		local templatename = cmd_text:match("(%S*)$");

		if(not templatename or templatename == "") then
			templatename = "default";
		end
		templatename = templatename:gsub("^blocktemplates/", ""):gsub("%.bmax$", "");
		local relative_path = format("blocktemplates/%s.bmax", templatename);
		local filename = GameLogic.current_worlddir..relative_path;

		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
		local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
		local task = BlockTemplate:new({operation = BlockTemplate.Operations.Save, filename = filename, auto_scale = auto_scale, bSelect=nil})
		if(task:Run()) then
			BroadcastHelper.PushLabel({id="savemodel", label = format(L"BMax模型成功保存到:%s", relative_path), max_duration=4000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
			return true, relative_path;
		end
	end,
};

Commands["export"] = {
	name="export", 
	quick_ref="/export [-silent] [filename]", 
	desc=[[export current selection as certain file
@param silent: true to suppress any UI popups
@param filename: file name to save as.
Example:
/export   :show the GUI to export selection to a given file type.
/export -silent  :close any exporter gui
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ExportTask.lua");
		local Export = commonlib.gettable("MyCompany.Aries.Game.Tasks.Export");
		local task = MyCompany.Aries.Game.Tasks.Export:new({})

		local bSilentMode;

		local option = true;
		while(cmd_text and option) do
			option, cmd_text = CmdParser.ParseOption(cmd_text);
			if(option == "silent") then
				bSilentMode = true;
			end
		end
		if(cmd_text and cmd_text~="") then
			task:SetFileName(cmd_text);
		end
		task:SetSilentMode(bSilentMode);

		task:Run();
	end,
};

Commands["generatemodel"] = {
	name="generatemodel", 
	quick_ref="/generatemodel [modelpath]", 
	desc=[[generate x model with current selection
/generatemodel test
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local modelname = cmd_text:match("(%S*)$");
		if(not modelname or modelname == "") then
			modelname = "model/default.x";
		end
		--modelname = templatename:gsub("^blocktemplates/", ""):gsub("%.blocks%.xml$", "");
		local filename = modelname;

		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/GenerateModelTask.lua");
		local task = MyCompany.Aries.Game.Tasks.GenerateModel:new({filename = filename});
		task:Run()
	end,
};

