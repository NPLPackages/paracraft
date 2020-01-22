--[[
Title: NplMicroRobotDef_Data
Author(s): leio
Date: 2019/12/2
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicroRobot/NplMicroRobotDef/NplMicroRobotDef_Data.lua");
-------------------------------------------------------
]]
NPL.export({

{
	type = "getLocalVariable1", 
	message0 = L"%1",
	arg0 = {
		{
			name = "var",
			type = "field_variable",
			variable = L"变量名",
			variableTypes = {""},
			text = L"变量名",
		},
	},
	output = {type = "null",},
	category = "NplMicroRobot.Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
	ToNPL = function(self)
		return self:getFieldAsString('var');
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

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
	category = "NplMicroRobot.Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
    colourSecondary = "#ffffff",
	ToNPL = function(self)
		return self:getFieldAsString('var');
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},
{
	type = "assign1", 
	message0 = L"%1赋值为%2",
	arg0 = {
		{
			name = "left",
			type = "input_value",
			shadow = { type = "getLocalVariable1", value = L"变量名",},
			text = L"变量名",
		},
		{
			name = "right",
			type = "input_value",
			shadow = { type = "functionParams", value = "1",},
			text = "1",
		},
	},
	category = "NplMicroRobot.Data", 
	helpUrl = "", 
	canRun = false,
	hide_in_codewindow = true,
	previousStatement = true,
	nextStatement = true,
	func_description = '%s = %s',
	ToNPL = function(self)
		return string.format('%s = %s\n', self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
	category = "NplMicroRobot.Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '%s = %s',
	ToNPL = function(self)
		return string.format('%s = %s\n', self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
	category = "NplMicroRobot.Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "local",
	func_description = 'local %s = %s',
	func_description_js = 'let %s = %s',
	ToNPL = function(self)
		return string.format('local %s = %s\n', self:getFieldAsString('var'), self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
	category = "NplMicroRobot.Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '"%s"',
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
				{ L"真", "true" },
				{ L"假", "false" },
			  }
		},
	},
	output = {type = "field_number",},
	category = "NplMicroRobot.Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
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
	category = "NplMicroRobot.Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
	ToNPL = function(self)
		return string.format('%s', self:getFieldAsString('left'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "code_block", 
	message0 = L"代码%1",
	message1 = L"%1",
    arg0 = {
		{
			name = "label_dummy",
			type = "input_dummy",
			text = "",
		},
	},
	arg1 = {
		{
			name = "codes",
			type = "field_input",
			text = "",
		},
	},
	category = "NplMicroRobot.Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '%s',
	ToNPL = function(self)
		return string.format('%s\n', self:getFieldAsString('codes'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
]]}},
},
{
	type = "code_comment", 
	message0 = L"注释 %1",
	arg0 = {
		{
			name = "value",
			type = "field_input",
			text = "",
		},
	},
	category = "NplMicroRobot.Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '-- %s',
	func_description_js = '// %s',
	ToNPL = function(self)
		return string.format('-- %s', self:getFieldAsString('value'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
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
	category = "NplMicroRobot.Data", 
	helpUrl = "", 
	canRun = false,
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
	examples = {{desc = L"", canRun = true, code = [[
]]}},
},


})