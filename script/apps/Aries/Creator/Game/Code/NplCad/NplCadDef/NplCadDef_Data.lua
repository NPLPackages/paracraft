--[[
Title: NplCadDef_Data
Author(s): leio
Date: 2018/9/10
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadDef/NplCadDef_Data.lua");
local NplCadDef_Data = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Data");
-------------------------------------------------------
]]
local NplCadDef_Data = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Data");
local cmds = {

{
	type = "getLocalVariable", 
	message0 = L"获取变量%1",
	arg0 = {
		{
			name = "var",
			type = "field_variable",
			variable = "score",
			variableTypes = {""},
			text = "score",
		},
	},
	output = {type = "null",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
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
	message0 = L"新建本地变量%1为%2",
	arg0 = {
		{
			name = "var",
			type = "field_variable",
			variable = "score",
			variableTypes = {""},
			text = "score",
		},
		{
			name = "value",
			type = "input_value",
			shadow = { type = "text", value = "value",},
			text = "value",
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
			shadow = { type = "getLocalVariable", value = "score",},
			text = "score",
		},
		{
			name = "right",
			type = "input_value",
			shadow = { type = "text", value = "1",},
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
	type = "defineFunction", 
	message0 = L"定义函数%1(%2)",
	message1 = L"%1",
	arg0 = {
		{
			name = "name",
			type = "field_input",
			text = "", 
		},
		{
			name = "param",
			type = "field_input",
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
	previousStatement = true,
	nextStatement = true,
	hide_in_codewindow = true,
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = 'function %s(%s)\\n%send',
    ToPython = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end
		return string.format('def %s(%s):\n    %s\n', self:getFieldAsString('name'), self:getFieldAsString('param'), input);
	end,
	ToNPL = function(self)
		return string.format('function %s(%s)\n    %s\nend\n', self:getFieldAsString('name'), self:getFieldAsString('param'), self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
function thinkText(text)
	say(text.."...")
end
thinkText("Let me think");
]]}},
},
{
	type = "functionParams", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_input",
			text = ""
		},
	},
	hide_in_toolbox = true,
	category = "Data", 
	output = {type = "null",},
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
    colourSecondary = "#ffffff",
	ToNPL = function(self)
		return self:getFieldAsString('value');
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},
{
	type = "callFunction", 
	message0 = L"调用函数%1(%2)",
	arg0 = {
		{
			name = "name",
			type = "field_input",
			text = "log",
		},
		{
			name = "param",
			type = "input_value",
			shadow = { type = "functionParams", value = "param",},
			text = "",
		},
	},
	previousStatement = true,
	nextStatement = true,
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s(%s)',
	ToNPL = function(self)
		return string.format('%s(%s)\n', self:getFieldAsString('name'), self:getFieldAsString('param'));
	end,
	examples = {{desc = "", canRun = true, code = [[
local thinkText = function(text)
	say(text.."...")
end
thinkText("Let me think");
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
	hide_in_toolbox = true,
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '%s',
	func_description_js = '%s',
	ToNPL = function(self)
		return string.format('%s\n', self:getFieldAsString('codes'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
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
	category = "Data", 
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
	examples = {{desc = L"", canRun = true, code = [[
]]}},
},

{
	type = "print3d", 
	message0 = L"打印 %1",
    arg0 = {
        
        {
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"需要", "true" },
				{ L"不需要", "false" },
			},
		},
	},
	hide_in_toolbox = true,
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'print3d(%s)',
	func_description_js = 'print3d(%s)',
	ToNPL = function(self)
        return string.format('print3d(%s)', 
            self:getFieldValue('value')
            );
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "setMaxTrianglesCnt", 
	message0 = L"模型三角形最大数量: %1",
	arg0 = {
		{
			name = "value",
			type = "field_number",
			text = "-1",
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	nextStatement = true,
	func_description = 'setMaxTrianglesCnt(%s)',
	ToNPL = function(self)
		return string.format('setMaxTrianglesCnt(%s)', self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},
};
function NplCadDef_Data.GetCmds()
	return cmds;
end
