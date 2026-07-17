--[[
Title: JiHRobotDef_Data
Author(s): leio
Date: 2022/8/23
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/JiHRobot/JiHRobotDef/JiHRobotDef_Data.lua");
local JiHRobotDef_Data = commonlib.gettable("MyCompany.Aries.Game.Code.JiHRobot.JiHRobotDef_Data");
-------------------------------------------------------
]]
local JiHRobotDef_Data = commonlib.gettable("MyCompany.Aries.Game.Code.JiHRobot.JiHRobotDef_Data");
local cmds = {

{
	type = "getLocalVariable", 
	message0 = L"%1",
	arg0 = {
		{
			name = "var",
			type = "field_input",
			text = L"变量名",
		},
	},
	output = {type = "null",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
    colourSecondary = "#ffffff",
	func_description = '%s',
	func_description_js = '%s',
	ToNPL = function(self)
		return self:getFieldAsString('var');
	end,
	examples = {{desc = "", canRun = true, code = [[
local key = "value"
say(key, 1)
]]}},
},

{
	type = "createLocalVariable", 
	message0 = L"新建本地%1为%2",
	arg0 = {
		{
			name = "var",
			type = "field_input",
			text = L"变量名",
		},
		{
			name = "value",
			type = "input_value",
			shadow = { type = "functionParams", value = "0",},
			text = "0",
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'local %s = %s',
	func_description_js = 'var %s = %s',
	ToNPL = function(self)
		return 'local key = "value"\n';
	end,
	examples = {{desc = "", canRun = true, code = [[
local key = "value"
say(key, 1)
]]}},
},

{
	type = "assign", 
	message0 = L"%1赋值为%2",
	arg0 = {
		{
			name = "left",
			type = "input_value",
			shadow = { type = "getLocalVariable", value = L"变量名",},
			text = L"变量名",
		},
		{
			name = "right",
			type = "input_value",
			shadow = { type = "functionParams", value = "1",},
			text = "1",
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '%s = %s',
	func_description_js = '%s = %s',
	ToNPL = function(self)
		return 'key = "value"\n';
	end,
	examples = {{desc = "", canRun = true, code = [[
text = "hello"
say(text, 1)
]]}},
},

{
	type = "getString", 
	message0 = "\"%1\"",
	arg0 = {
		{
			name = "left",
			type = "field_input",
			text = "string",
		},
	},
	output = {type = "null",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '"%s"',
	func_description_js = '"%s"',
	ToNPL = function(self)
		return string.format('"%s"', self:getFieldAsString('left'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},
{
	type = "getBoolean", 
	message0 = L"%1",
	arg0 = {
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ "true", "true" },
				{ "false", "false" },
				{ "nil", "nil" },
			  }
		},
	},
	output = {type = "field_number",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
	func_description_js = '%s',
	ToNPL = function(self)
		return self:getFieldAsString("value");
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},
{
	type = "getNumber", 
	message0 = L"%1",
	arg0 = {
		{
			name = "left",
			type = "field_number",
			text = "0",
		},
	},
	output = {type = "field_number",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
	func_description_js = '%s',
	ToNPL = function(self)
		return string.format('%s', self:getFieldAsString('left'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "code_comment", 
	message0 = L"-- %1",
	arg0 = {
		{
			name = "value",
			type = "field_input",
			text = "",
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '-- %s',
	func_description_js = '// %s',
	ToNPL = function(self)
		return string.format('-- %s', self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "code_comment_full", 
	message0 = L"注释全部 %1",
	message1 = "%1",
	message2 = "%1",
    arg0 = {
		{
			name = "label_dummy",
			type = "input_dummy",
			text = "",
		},
	},
	arg1 = {
		{
			name = "input",
			type = "input_statement",
			text = "", 
		},
	},
    arg2 = {
		{
			name = "label_dummy",
			type = "input_dummy",
			text = "",
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	hide_in_toolbox = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '--[[\\n%s\\n]]',
	func_description_js = '/**\\n%s\\n*/',
    ToPython = function(self)
		return string.format('"""\n%s\n"""', self:getFieldAsString('input'));
	end,
	ToNPL = function(self)
		return string.format('--[[\n%s\n]]', self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "data_variable", 
	message0 = L"%1",
    lastDummyAlign0 = "CENTRE",
	arg0 = {
		{
			name = "VARIABLE",
			type = "field_variable_getter",
			text = "i",
            variableType = "",
		},
	},
    colour = "#ff8c1a",
	hide_in_toolbox = true,
    checkboxInFlyout = false,
	output = {type = "null",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '"%s"',
	func_description_js = '"%s"',
	ToNPL = function(self)
		return string.format('"%s"', self:getFieldAsString('VARIABLE'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

};
function JiHRobotDef_Data.GetCmds()
	return cmds;
end
