--[[
Title: Command Manager
Author(s): LiXizhi
Date: 2013/2/9
Desc: slash command manager
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
CommandManager:Init()
CommandManager:RunCommand(cmd_name, cmd_text)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL.lua");
NPL.load("(gl)script/apps/Aries/SlashCommand/SlashCommand.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");	
local EnterGamePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EnterGamePage");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

-- call this when command
function CommandManager:Init()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandBlocks.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandShapes.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandGlobals.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandWorlds.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandInstall.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandPlayer.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandMovie.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandRules.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandProgram.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandItem.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandTime.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandTemplate.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandCamera.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandAudio.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandActivate.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandBlockType.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandTexture.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandSet.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandOpen.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandBlockTransform.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandEntity.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandPublishSourceScript.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandActor.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandRecord.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandConvert.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandNetwork.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandEffect.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandSelect.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandCreate.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandCCS.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandShow.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandDropFile.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandMenu.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandSystem.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandDump.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandSky.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandTeleport.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandWalk.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandSay.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandDoc.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandEvent.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandSpawn.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandProperty.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandLanguage.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandMount.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandQuest.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandWiki.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandDiff.lua");

	GameLogic.GetFilters():apply_filters("register_command", Commands, SlashCommand.GetSingleton());

	self:Register(SlashCommand.GetSingleton());
end

-- run one text command
-- @param cmd_name: this can be command name or full command text that begin with "/" or nothing. 
function CommandManager:RunCommand(cmd_name, cmd_text, ...)
	if(not cmd_text or cmd_text == "") then
		cmd_name, cmd_text = cmd_name:match("^/*(%w+)%s*(.*)$");
	end

	local cmd_class = SlashCommand.GetSingleton():GetSlashCommand(cmd_name);
	if(cmd_class) then
		if(GameLogic.isRemote and not cmd_class:IsLocal()) then
			GameLogic.GetPlayer():AddToSendQueue(GameLogic.Packets.PacketClientCommand:new():Init(format("/%s %s", cmd_name, cmd_text)));
		elseif(not GameLogic.isRemote or cmd_class:IsLocal()) then
			cmd_text = self:RunInlineCommand(cmd_text, ...);
			return SlashCommand.GetSingleton():RunCommand(cmd_name, cmd_text, ...);
		end
	end
end

function CommandManager:GetCommandName(cmd_text)
	return cmd_text:match("^%s*/*(%w+)");
end

-- run text with may contain one or several commands. 
-- it will treat ; or \r\n as a new line of command 
-- @param ...: ususally fromEntity, 
function CommandManager:RunText(text, ...)
	if(text) then
		for cmd in text:gmatch("(/*[^\r\n;]+)") do
			self:RunCommand(cmd, nil, ...);
		end
	end
end


-- like linux bash shell, text inside $() is regarded as inline command, whose returned value is used in current command. 
-- brackets can be nested
-- @return the new cmd_text after inline command is executed. 
function CommandManager:RunInlineCommand(cmd_text, ...)
	while(cmd_text) do
		local from, to;
		from, to, end_bracket = cmd_text:find("%$%(/?[^%$%(%)]+([%)%(])");
		while(to and end_bracket == "(") do
			local from1;
			from1, to, end_bracket = cmd_text:find("%)[^%(%)]*([%)%(])", to+1);
		end
		if(end_bracket == ")") then
			local inline_cmd = cmd_text:sub(from+2, to - 1);
			if(inline_cmd) then
				local result = self:RunCommand(inline_cmd, nil, ...) or "";
				cmd_text = cmd_text:sub(1, from - 1)..tostring(result)..cmd_text:sub(to+1, -1);
			end
		else
			break;
		end
	end
	return cmd_text;
end

-- run commands
-- @return p1, p2: if p1 is false, then p2 is the label name where to goto. If p2 is nil, it means end of all lines. 
-- if p1 is not false, such as nil or any other value, the next command will be invoked normally. 
function CommandManager:Run(cmd, ... )
	return self:RunWithVariables(nil, cmd, ...);
end

-- @return cmd_class, cmd_name, cmd_text;
function CommandManager:GetCmdByString(cmd)
	if(cmd) then
		local cmd_name, cmd_text = cmd:match("^/*(%w+)%s*(.*)$");
		if(cmd_name) then
			local cmd_class = SlashCommand.GetSingleton():GetSlashCommand(cmd_name);
			if(cmd_class) then
				return cmd_class, cmd_name, cmd_text;
			end
		end
	end
end

-- @param variables: nil or a must be an object containning Compile() function. 
-- @return p1, p2: if p1 is false, then p2 is the label name where to goto. If p2 is nil, it means end of all lines. 
-- if p1 is not false, such as nil or any other value, the next command will be invoked normally. 
function CommandManager:RunWithVariables(variables, cmd, ...)
	local cmd_class, cmd_name, cmd_text = self:GetCmdByString(cmd);
	if(cmd_class) then
		cmd_text = self:RunInlineCommand(cmd_text, ...);
		if(variables) then
			cmd_class:SetCompiler(variables);
			local p1, p2 = cmd_class:Run(cmd_name, cmd_text, ...);
			cmd_class:SetCompiler(nil);
			return p1, p2;
		else
			return cmd_class:Run(cmd_name, cmd_text, ...);
		end
	end
end

-- run command from console for the current player
-- @param player: fromEntity, if nil, this is current player. last trigger entity is also set to this player. 
-- after command is run, it will set back to previous value. 
function CommandManager:RunFromConsole(cmd, player)
	local cmd_class, cmd_name, cmd_text = self:GetCmdByString(cmd);

	GameLogic.GetFilters():apply_filters("user_event_stat", "cmd", "execute:"..tostring(cmd_name), 2, nil);

	if(cmd_class) then
		if(GameLogic.isRemote and not cmd_class:IsLocal()) then
			GameLogic.GetPlayer():AddToSendQueue(GameLogic.Packets.PacketClientCommand:new():Init(cmd));
		elseif(not GameLogic.isRemote or cmd_class:IsLocal()) then
			local variables;
			if(not player) then
				if(EntityManager.GetPlayer) then
					player = EntityManager.GetPlayer();
				end
			end
			if(player) then
				variables = player:GetVariables();	
			end
			if(cmd_class:CheckGameMode(GameLogic.GameMode:GetMode())) then
				local last_trigger_entity = false;
				if(player and EntityManager.SetLastTriggerEntity) then
					last_trigger_entity = EntityManager.GetLastTriggerEntity();
					EntityManager.SetLastTriggerEntity(player);
				end
				local res, res2 = self:RunWithVariables(variables, cmd, player);
				if(last_trigger_entity~=false) then
					EntityManager.SetLastTriggerEntity(last_trigger_entity);
				end
				return res, res2;
			else
				BroadcastHelper.PushLabel({id="cmderror", label = format("当前模式下不可执行命令%s", cmd_name), max_duration=3000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
				return;
			end
		end
	end
end

-- destroy the command manager
function CommandManager:Destroy()
	if(self.slash_command) then
		local slash_command = self.slash_command;
		local name, value
		for name, value in pairs(Commands) do
			slash_command:RemoveSlashCommand(name);
		end
		self.is_registered = false;
	end
end

-- call this function to register the slash command and init
function CommandManager:Register(slash_command)
	if(self.is_registered) then
		return;
	end
	self.is_registered = true;
	self.slash_command = slash_command;

	-- register all predefined system commands
	for name, cmd in pairs(Commands) do
		slash_command:RegisterSlashCommand(cmd);
	end
end

-- get command list
-- @param line_reg_exp: default to "([%-]*)%s*(/?[^\r\n]+)", change this if one uses different line endings. 
function CommandManager:GetCmdList(cmds_str, line_reg_exp)
	if(cmds_str) then
		line_reg_exp = line_reg_exp or "([%-]*)%s*(/?[^\r\n]+)";
		local out = {};
		for comment, cmd in string.gmatch(cmds_str, line_reg_exp) do
			if(comment == "") then
				out[#out+1] = cmd
			--else
				--out[#out+1] = "";
			end
		end
		return out;
	end
end

-- @param cmd_list: array of command text. if nil, the current command list is used. 
-- @param func_name: function name, 
-- function [name]  
-- -- cmd here will be called. 
-- functionend
-- return true, function_return_value:  if function is found and called. otherwise return nil;
function CommandManager:CallFunction(cmd_list, func_name, variables, fromEntity)
	cmd_list = cmd_list or self:GetCurrentCmdList();
	if(cmd_list and func_name) then
		local line_index = 1;
		local func_name_reg = "^/?function "..func_name;
		local line_count = #cmd_list;
		local insideFunc;
		local fromLine, toLine;
		while line_index <= line_count do
			local cmd = cmd_list[line_index];
			if(cmd~="") then
				if(not insideFunc) then
					if(cmd:match(func_name_reg)) then
						insideFunc = true;
						fromLine = line_index + 1;
					end
				else
					if(cmd:match("^/?functionend")) then
						toLine = line_index - 1;
						break;
					end
				end
			end
			line_index = line_index + 1;
		end
		if(insideFunc) then
			-- execute function between 
			local res = self:RunCmdSegment(cmd_list, fromLine, toLine, variables, fromEntity);
			return true, res;
		end
	end
end

-- get the current command list if any that is being executed;
function CommandManager:GetCurrentCmdList()
	return self.cmd_list;
end

-- run command from fromLine to toLine
-- @param cmd_list: array of cmd strings
-- @param fromLine: default to 1
-- @param toLine: default to #cmd_list
function CommandManager:RunCmdSegment(cmd_list, fromLine, toLine, variables, fromEntity)
	local last_result, goto_label;
	local line_index = fromLine or 1;
	local line_count = toLine or #cmd_list;
	self.cmd_list = cmd_list;
	local macros;
	while line_index <= line_count do
		local cmd = cmd_list[line_index];
		if(cmd~="" and cmd:match("^[%w_%.]+%(.*%)$")) then
			-- macro command
			macros = macros or {}
			macros[#macros+1] = cmd;
			line_index = line_index + 1;
		elseif(cmd~="") then
			-- ordinary command
			last_result, goto_label = self:RunWithVariables(variables, cmd, fromEntity);
			if( last_result == false) then
				if(goto_label) then
					if(type(goto_label) == "number") then
						local goto_line = line_index + goto_label;
						line_index = goto_line;
					else
						if(goto_label == "end") then
							break;
						elseif(goto_label == "begin") then
							line_index = 1;
						elseif(goto_label == "if_end") then
							-- goto if's "end" command 
							line_index = line_index + 1;
							-- support nested if, else
							local nested_count = 0;
							while line_index <= line_count do
								local cmd = cmd_list[line_index];
								if(cmd~="") then
									local cmd_name = self:GetCommandName(cmd);
									if(cmd_name == "fi") then
										if(nested_count > 0) then
											nested_count = nested_count - 1;
										else
											line_index = line_index + 1;
											break;
										end
									elseif(cmd_name == "if") then
										if(cmd:match("%s+then%s*$")) then
											nested_count = nested_count + 1;
										end
									end
								end
								line_index = line_index + 1;
							end
						elseif(goto_label == "else") then
							-- continue to "else", "elseif", "fi", command 
							line_index = line_index + 1;
							-- support nested if, else
							local nested_count = 0;
							while line_index <= line_count do
								local cmd = cmd_list[line_index];
								if(cmd~="") then
									local cmd_name = self:GetCommandName(cmd);
									if(cmd_name == "else") then
										if(nested_count == 0) then
											line_index = line_index + 1;
											break;
										end
									elseif(cmd_name == "fi") then
										if(nested_count > 0) then
											nested_count = nested_count - 1;
										else
											line_index = line_index + 1;
											break;
										end
									elseif(cmd_name == "if") then
										if(cmd:match("%s+then%s*$")) then
											nested_count = nested_count + 1;
										end
									elseif(cmd_name == "elseif" or cmd_name == "elif") then
										if(nested_count == 0) then
											cmd = cmd:gsub("^[%s/]*els?e?if", "if");
											last_result, goto_label = self:RunWithVariables(variables, cmd, fromEntity);
											if(goto_label ~= "else") then
												line_index = line_index + 1;
												break;
											end
										end
									end
								end
								line_index = line_index + 1;
							end
						elseif(goto_label == "functionend") then
							line_index = line_index + 1;
							while line_index <= line_count do
								local cmd = cmd_list[line_index];
								if(cmd~="") then
									local cmd_name = self:GetCommandName(cmd);
									if(cmd_name == "functionend") then
										line_index = line_index + 1;
										break;
									end
								end
								line_index = line_index + 1;
							end
						else
							-- TODO: jump to a labeled line that starts with ":"
							break;
						end
					end
				else
					break;
				end
			else
				line_index = line_index + 1;
			end
		else
			line_index = line_index + 1;
		end
	end
	if(macros) then
		local text = table.concat(macros, "\n");
		GameLogic.Macros:Play(text);
	end
	return last_result;
end

-- run command list and return the result. 
function CommandManager:RunCmdList(cmd_list, variables, fromEntity)
	return self:RunCmdSegment(cmd_list, nil, nil, variables, fromEntity);
end


function CommandManager:LoadCmdHelpFile()
	NPL.load("(gl)script/ide/Encoding.lua");
	local Encoding = commonlib.gettable("commonlib.Encoding");

	CommandManager.cmd_helps = CommandManager.cmd_helps or {};
	CommandManager.cmd_types = CommandManager.cmd_types or {};
	local cmd_helps = CommandManager.cmd_helps;
	local dir = L"config/Aries/creator/Commands.xml";
	local xmlRoot = ParaXML.LuaXML_ParseFile(dir);
	if(xmlRoot) then
		LOG.std(nil, "info", "CommandManager", "cmd help loaded from %s", dir);
		local cmds = SlashCommand.GetSingleton();
		
		for type_node in commonlib.XPath.eachNode(xmlRoot, "/Commands/Type") do
			
			if(type_node.attr and type_node.attr.name) then
				local type_name = type_node.attr.name;
				local cmd_type = CommandManager.cmd_types[type_name] or {};
				
				for cmd_node in commonlib.XPath.eachNode(type_node, "/Command") do
					local attr = cmd_node.attr;
					local cmd_class = cmds:GetSlashCommand(attr.name);
					if(not cmd_class) then
						LOG.std(nil, "warn", "CommandManager", "unknown command tip of %s in file %s", attr.name, dir);
					else
						local cmd = {};
						cmd.name = attr.name;

						-- @note Xizhi: show both source file and xml file version if they differ and desc begins with a Chinese letter. 
						if(cmd_class.desc~=attr.desc and cmd_class.desc) then
							-- prepend source version
							local src_desc = Encoding.EncodeHTMLInnerText(cmd_class.desc);
							
							if(attr.desc and (string.byte(attr.desc, 1) or 0) > 128) then
								cmd.desc = (src_desc or "").."\n"..attr.desc;
							else
								cmd.desc = src_desc;
							end
						else
							cmd.desc = attr.desc;
						end

						if(cmd_class.quick_ref~=attr.quick_ref and cmd_class.quick_ref) then
							-- append xml quick ref version
							cmd.desc = (attr.quick_ref or "").."\n"..cmd.desc;
							cmd.quick_ref = Encoding.EncodeHTMLInnerText(cmd_class.quick_ref);
						else
							cmd.quick_ref = attr.quick_ref;
						end

						local params = {};
						local param_node;
						for param_node in commonlib.XPath.eachNode(cmd_node,"/Param") do
							if(param_node.attr) then
								params[#params + 1] = {name = param_node.attr.name,desc = param_node.attr.desc};
							end
						end
						cmd.params = params;

						local instances = {};
						local instance_node;
						for instance_node in commonlib.XPath.eachNode(cmd_node,"/Instance") do
							if(instance_node.attr) then
								instances[#instances + 1] = {content = instance_node.attr.content,desc = instance_node.attr.desc};
							end
						end
						cmd.instances = instances;

						if(not cmd_helps[cmd.name]) then
							cmd_helps[cmd.name] = cmd;
						end

						if(not cmd_type) then
							cmd_type = {};
						end

						if(not cmd_type[cmd.name]) then
							cmd_type[#cmd_type + 1] = cmd;
						end
					end
				end
		
				if(not CommandManager.cmd_types[type_name]) then
					table.sort(cmd_type,function(a,b)
						return (a.name) < (b.name);
					end);
					CommandManager.cmd_types[type_name] = cmd_type;
				end
			end
		end
	else
		LOG.std(nil, "warn", "CommandManager", "can not find file %s", dir);
	end

	-- add any missing command names to help.
	local cmd_type = CommandManager.cmd_types[L"命令列表"];
	if(not cmd_type) then
		cmd_type = {};
		CommandManager.cmd_types[L"命令列表"] = cmd_type;
	end
	for name, cmd in pairs(SlashCommand.slash_command_maps) do
		if(not cmd_helps[name]) then
			cmd_helps[name] = {name = name, quick_ref = Encoding.EncodeHTMLInnerText(cmd.quick_ref), desc = Encoding.EncodeHTMLInnerText(cmd.desc or ""), params = {}, instances = {}, }
			cmd_type[#cmd_type + 1] = cmd_helps[name];
		end
	end
end

-- lazy load all command help
function CommandManager:GetCmdHelpDS()
	if(not CommandManager.cmd_helps) then
		self:LoadCmdHelpFile();
	end
	return CommandManager.cmd_helps;
end

function CommandManager:GetCmdTypeDS()
	if(not CommandManager.cmd_types) then
		self:LoadCmdHelpFile();
	end
	return CommandManager.cmd_types;
end
