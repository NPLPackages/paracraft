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
	quick_ref="/loadtemplate [-r] [-nohistory] [-abspos] [-tp] [-a seconds] [x y z] [templatename]", 
	desc=[[load template to the given position
@param -a seconds: animate building progress. the followed number is the number of seconds (duration) of the animation. 
@param -r: remove blocks
@param -abspos: whether load using absolute position. 
@param -tp: whether teleport player to template player's location. 
@param -opaque: replace air block to black color block.
@param x,y,z: absolute or relative position, default to current player position
@param templatename: filename relative to current world or blocktemplates/. If no file extension is specified, [name].blocks.xml is used. 
default name is "default"
/loadtemplate ~0 ~2 ~ test
/loadtemplate -a 3 test
/loadtemplate -r test
/loadtemplate -nohistory test
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
		local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
		
		local option;
		local load_anim_duration;
		local operation = BlockTemplate.Operations.Load;
		local UseAbsolutePos, TeleportPlayer, nohistory;
		local opaque;

		while(cmd_text) do
			option, cmd_text = CmdParser.ParseOption(cmd_text);
			if(option) then
				if (option == "a") then
					load_anim_duration, cmd_text = CmdParser.ParseInt(cmd_text);
					if (load_anim_duration ~= 0) then
						operation = BlockTemplate.Operations.AnimLoad;
					end
				elseif (option == "r") then
					operation = BlockTemplate.Operations.Remove;
				elseif (option == "abspos") then
					UseAbsolutePos = true;
				elseif (option == "nohistory") then
					nohistory = true;
				elseif (option == "tp") then
					TeleportPlayer = true;
				elseif (option == "opaque") then
					opaque = true;
				end
			else
				break;
			end
		end
		load_anim_duration = load_anim_duration or 0;

		local x, y, z, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity);

		if (not x) then
			fromEntity = fromEntity or EntityManager.GetPlayer();
			if (fromEntity) then
				x,y,z = fromEntity:GetBlockPos();
			end
		end

		if (x) then
			local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
			local filename = cmd_text;

			if (filename == "") then
				templatename = "default";
			end

			if(not filename:match("%.xml$") and not filename:match("%.bmax$")) then
				filename = filename .. ".blocks.xml";
			end

			local fullpath = Files.GetWorldFilePath(filename) or (not filename:match("[/\\]") and Files.GetWorldFilePath("blocktemplates/"..filename));
			
			if(fullpath) then
				local task = BlockTemplate:new(
					{
						operation = operation,
						filename = fullpath,
						blockX = x,
						blockY = y,
						blockZ = z,
						bSelect = nil,
						load_anim_duration = load_anim_duration,
						UseAbsolutePos = UseAbsolutePos,
						TeleportPlayer = TeleportPlayer,
						nohistory = nohistory,
						opaque = opaque,
					}
				);
				task:Run();
			else
				LOG.std(nil, "info", "loadtemplate", "file %s not found", filename);
			end
		end
	end,
};


Commands["savetemplate"] = {
	name="savetemplate", 
	quick_ref="/savetemplate [-auto_pivot] [-relative_motion] [-hollow] [-ref] [templatename]", 
	desc=[[save template with current selection
@param templatename: if no name is provided, it will be default
@param auto_pivot: if true, use the bottom center of all blocks as pivot
@param -hollow: if true, model will be hollow
@param -relative_motion: if true, movie block will use relative motion
@param -ref: if true, we will export external referenced files 
/savetemplate test
/savetemplate -hollow test
/savetemplate -auto_pivot test
/savetemplate -relative_motion test
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);

		local templatename = cmd_text:match("(%S*)$");
		if(not templatename or templatename == "") then
			templatename = "default";
		end

		templatename = templatename:gsub("^blocktemplates/", ""):gsub("%.blocks%.xml$", "");
		local filename = format("%sblocktemplates/%s.blocks.xml", GameLogic.current_worlddir, templatename);

		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
		local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
		local task = BlockTemplate:new({operation = BlockTemplate.Operations.Save, 
			filename = filename, 
			auto_pivot = options.auto_pivot,
			relative_motion = options.relative_motion,
			hollow = options.hollow,
			exportReferencedFiles = options.ref,
			bSelect=nil})
		if(task:Run()) then
			BroadcastHelper.PushLabel({id="savetemplate", label = format(L"模板成功保存到:%s", commonlib.Encoding.DefaultToUtf8(filename)), max_duration=4000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
		end
	end,
};

Commands["savemodel"] = {
	name="savemodel", 
	quick_ref="/savemodel [-auto_scale false] [-interactive|i] [modelname]", 
	desc=[[save bmax model with current selection. 
@param -auto_scale: whether or not scale model to one block size. default value is true
@param modelname: if no name is provided, it will be "default"
@param -interactive or -i: we will ask the user if file already exists
@return true, filename
/savemodel test
/savemodel -auto_scale false test
/savemodel -interactive test
/savemodel -interactive "file name"
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local option;
		local auto_scale;
		local options = {};
		while(cmd_text) do
			option, cmd_text = CmdParser.ParseOption(cmd_text);
			if(option) then
				if(option == "auto_scale") then
					auto_scale, cmd_text = CmdParser.ParseBool(cmd_text);
				else
					options[option] = true;
				end
			else
				break;
			end
		end
		local templatename;
		templatename, cmd_text = CmdParser.ParseFilename(cmd_text);

		if(not templatename or templatename == "") then
			templatename = "default";
		end
		templatename = templatename:gsub("^blocktemplates/", ""):gsub("%.bmax$", "");
		templatename = commonlib.Encoding.Utf8ToDefault(templatename);
		local relative_path = format("blocktemplates/%s.bmax", templatename);
		local filename = GameLogic.current_worlddir..relative_path;

		local function saveModel_()
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
			local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
			local task = BlockTemplate:new({operation = BlockTemplate.Operations.Save, 
				filename = filename, auto_scale = auto_scale, bSelect=nil, 
			})
			if(task:Run()) then
				BroadcastHelper.PushLabel({id="savemodel", label = format(L"BMax模型成功保存到:%s", commonlib.Encoding.DefaultToUtf8(relative_path)), max_duration=4000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
				
				if(options.interactive or options.i) then
					GameLogic.GetFilters():apply_filters("file_exported", "bmax", filename);
					GameLogic.GetFilters():apply_filters("user_event_stat", "model", "export.bmax", 10, nil);
				end
				return true, relative_path;
			end
		end

		if(options.interactive or options.i) then
			if(ParaIO.DoesFileExist(filename)) then
				_guihelper.MessageBox(format(L"文件 %s 已经存在, 是否覆盖?", commonlib.Encoding.DefaultToUtf8(filename)), function(res)
					if(res and res == _guihelper.DialogResult.Yes) then
						saveModel_()
					end
				end, _guihelper.MessageBoxButtons.YesNo);
				return
			end
		end

		return saveModel_();
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
			cmd_text = commonlib.Encoding.Utf8ToDefault(cmd_text);
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
		filename = commonlib.Encoding.Utf8ToDefault(filename);
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/GenerateModelTask.lua");
		local task = MyCompany.Aries.Game.Tasks.GenerateModel:new({filename = filename});
		task:Run()
	end,
};

Commands["exportgltf"] = {
	name="exportgltf", 
	quick_ref="/exportgltf [-region] [parax] [output]", 
	desc=[[--export all blocks in the given regions to gltf(glb) files, save to current world dictionary
/export -region 37_37|37_38
-- export all selected blocks to gltf(glb) file, save as the output file in current world dictionary
/export selected1.gltf(glb)
-- export all blocks in the given chunks in (x y z) radius around player
/export 32 32 32
-- export the given parax file to gltf(glb) file
/export given.x output.gltf(glb)
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local function ParaXToGltf(parax, gltf)
			NPL.load("(gl)script/ide/System/Scene/Assets/ParaXModelAttr.lua");
			local ParaXModelAttr = commonlib.gettable("System.Scene.Assets.ParaXModelAttr");
			local attr = ParaXModelAttr:new():initFromAssetFile(parax, function(attr)
				if (attr:SaveToGltf(gltf)) then
					local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
					_guihelper.MessageBox(string.format(L"成功导出:%s, 是否打开所在目录", commonlib.Encoding.DefaultToUtf8(gltf)), function(res)
						if(res and res == _guihelper.DialogResult.Yes) then
							local info = Files.ResolveFilePath(gltf)
							if(info and info.relativeToRootPath) then
								local absPath = ParaIO.GetWritablePath()..info.relativeToRootPath;
								local absPathFolder = absPath:gsub("[^/\\]+$", "")
								ParaGlobal.ShellExecute("open", absPathFolder, "", "", 1);
							end
						end
					end, _guihelper.MessageBoxButtons.YesNo);
				else
					_guihelper.MessageBox(L"parax模型中的纹理加载失败，请稍后重试！");
				end
			end)
		end

		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);
		if (options.region) then
			local data = {};
			CmdParser.ParseStringList(cmd_text, data);
			local regions = {};
			for i = 1, #data do
				local r = {};
				CmdParser.ParseNumberList(data[i], r, "_");
				if (#r > 1) then
					if (i == 1) then
						table.insert(regions, {r[1], r[2]});
					else
						for j = 1, #regions-1 do
							if (r[1] ~= regions[j][1] or r[2] ~= regions[j][2]) then
								table.insert(regions, {r[1], r[2]});
							end
						end
					end
				end
			end
			options = {}
			options.command = "region";
			options.regions = regions;

			if (#regions > 1) then
				local min_x, min_z, max_x, max_z = 255, 255, 0, 0
				for i =1, #regions do
					if (min_x > regions[i][1]) then min_x = regions[i][1] end
					if (min_z > regions[i][2]) then min_z = regions[i][2] end
					if (max_x < regions[i][1]) then max_x = regions[i][1] end
					if (max_z < regions[i][2]) then max_z = regions[i][2] end
				end
				if ((max_x - min_x + 1) * (max_z - min_z + 1) > #regions) then
					_guihelper.MessageBox(L"导出失败，所输入的 regions 不相连");
					return;
				end
			end
		else
			local x1, y1, z1, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity);
			if (x1 and y1 and z1) then
				local x2, y2, z2 = CmdParser.ParsePos(cmd_text, fromEntity);
				if (x2 and y2 and z2) then
					options.command = "range";
					options.from = {x1, y1, z1};
					options.to = {x2, y2, z2};
				else
					options.command = "radius";
					options.x = x1;
					options.y = y1;
					options.z = z1;
				end
			else
				local filename;
				filename, cmd_text = CmdParser.ParseFilename(cmd_text);
				local ext = ParaIO.GetFileExtension(filename);
				if (ext == "x") then
					-- export parax to gltf(glb)
					local gltf = cmd_text;
					if (not gltf) then
						gltf = ParaIO.ChangeFileExtension(filename, "glb");
					end
					if(ParaIO.DoesFileExist(gltf)) then
						_guihelper.MessageBox(format(L"文件 %s 已经存在, 是否覆盖?", commonlib.Encoding.DefaultToUtf8(gltf)), function(res)
							if(res and res == _guihelper.DialogResult.Yes) then
								ParaXToGltf(filename, gltf);
							end
						end, _guihelper.MessageBoxButtons.YesNo);
					else
						ParaXToGltf(filename, gltf);
					end
					return;
				else
					-- export selected blocks to gltf(glb)
					if (not filename) then return end
					local selected_blocks = Game.SelectionManager:GetSelectedBlocks();
					if (selected_blocks) then
						options.blocks_string = commonlib.serialize_compact(selected_blocks, true);
					else
						_guihelper.MessageBox(L"请先选择物体, Ctrl+左键多次点击场景可选择");
						return;
					end

					filename = GameLogic.current_worlddir.."blocktemplates/"..filename
					options.filename = filename;
					options.command = "selected";
				end
			end
		end

		NPL.load("(gl)script/apps/Aries/Creator/Game/World/Exporter/BlocksExport.lua");
		local BlocksExport = commonlib.gettable("MyCompany.Aries.Creator.Game.Exporter.BlocksExport");
		BlocksExport.Run(options);
	end,
};

