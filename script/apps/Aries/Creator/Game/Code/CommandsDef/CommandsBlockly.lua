--[[
Title: CommandsBlockly
Author(s): LiXizhi
Date: 2019/12/9
Desc: language configuration file for CommandsBlockly
use the lib:
-------------------------------------------------------
local langConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/CommandsBlockly.lua");
-------------------------------------------------------
]]
local CommandsBlockly = NPL.export();
commonlib.setfield("MyCompany.Aries.Game.Code.CommandsBlockly", CommandsBlockly);

local all_cmds = {}
local cmdsMap = {};
local default_categories = {
{name = "CommandBlocks", text = L"方块", colour="#0078d7", },
{name = "CommandGlobal", text = L"全局" , colour="#7abb55", },
{name = "CommandRules", text = L"规则", colour="#764bcc", },
{name = "CommandControl", text = L"控制", colour="#459197", },
};

local is_installed = false;
function CommandsBlockly.AppendAll()
	if(is_installed)then
		return
	end
	is_installed = true;
	
	local all_source_cmds = {
		NPL.load("./CommandsDef_blocks.lua"),
		NPL.load("./CommandsDef_control.lua"),
		NPL.load("./CommandsDef_global.lua"),
		NPL.load("./CommandsDef_rules.lua"),
	}
	for k,v in ipairs(all_source_cmds) do
		CommandsBlockly.AppendDefinitions(v);
	end

	CommandsBlockly.AppendMissingCommands();
end

-- all missing commands are added as they are.
-- it will also add missing code examples for all existing commands
function CommandsBlockly.AppendMissingCommands()
	local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
	local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");

	local cmds = SlashCommand.GetSingleton();
	local missingCmds = {}
	for name, _ in pairs(CommandManager:GetCmdHelpDS()) do
		local cmd = cmds:GetSlashCommand(name);
		if(cmd) then
			local typeName = "cmd_"..name
			echo(typeName)
			
			local item = cmdsMap[typeName]
			if(not item) then
				item = {
					type = typeName,
					message0 = string.format("/%s %%1", name),
					arg0 = {
						{
							name = "input",
							type = "field_input",
							text = "", 
						},
					},
					category = "CommandGlobal", 
					helpUrl = "", 
					canRun = false,
					previousStatement = true,
					nextStatement = true,
					--hide_in_toolbox = true,
					funcName = name,
					func_description = string.format("/%s %%s", name),
					ToNPL = function(self)
						return "/"..name;
					end,
				}
				cmdsMap[typeName] = item;
				missingCmds[#missingCmds+1] = item;
			end
			item.examples = item.examples or {};
			table.insert(item.examples, 1, {desc = "", canRun = false, code = cmd.quick_ref})
			table.insert(item.examples, {desc = "", canRun = false, code = cmd.desc})
		end
	end
	table.sort(missingCmds, function(a,b)
		return a.type < b.type;
	end)
	for _, v in ipairs(missingCmds) do
		table.insert(all_cmds, v);
	end
end

function CommandsBlockly.AppendDefinitions(source)
	if(source)then
		for k,v in ipairs(source) do
			cmdsMap[v.type] = v;
			table.insert(all_cmds,v);
		end
	end
end
-- public:
function CommandsBlockly.GetCategoryButtons()
	return default_categories;
end

-- custom toolbar UI's mcml on top of the code block window. return nil for default UI. 
-- return nil or a mcml string. 
function CommandsBlockly.GetCustomToolbarMCML()
	CommandsBlockly.toolBarMcmlText = CommandsBlockly.toolBarMcmlText or string.format([[
    <div style="float:left;margin-left:5px;margin-top:7px;">
		<input type="button" value='<%%="%s"%%>' onclick="MyCompany.Aries.Game.Code.CommandsBlockly.OnClickLearn" style="min-width:80px;color:#ffffff;font-size:12px;height:25px;background:url(Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png#179 89 21 21:8 8 8 8)" />
    </div>
]], L"学习命令");
	return CommandsBlockly.toolBarMcmlText;
end

function CommandsBlockly.OnClickLearn()
	ParaGlobal.ShellExecute("open", L"https://github.com/tatfook/CodeBlockDemos/wiki/learn_commands", "", "", 1);
end

-- public:
function CommandsBlockly.GetAllCmds()
	CommandsBlockly.AppendAll();
	return all_cmds;
end

