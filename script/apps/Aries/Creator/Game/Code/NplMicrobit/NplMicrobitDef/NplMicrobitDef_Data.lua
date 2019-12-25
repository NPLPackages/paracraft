--[[
Title: NplMicrobitDef_Data
Author(s): leio
Date: 2019/12/2
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicrobit/NplMicrobitDef/NplMicrobitDef_Data.lua");
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
	category = "NplMicrobit.Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
	hide_in_codewindow = true,
	ToNPL = function(self)
		return self:getFieldAsString('var');
	end,
	examples = {{desc = "", canRun = true, code = [[
local key = "value"
say(key, 1)
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
	category = "NplMicrobit.Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
    colourSecondary = "#ffffff",
	ToNPL = function(self)
		return self:getFieldAsString('var');
	end,
	examples = {{desc = "", canRun = true, code = [[
local key = "value"
say(key, 1)
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
	category = "NplMicrobit.Data", 
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
text = "hello"
say(text, 1)
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
	category = "NplMicrobit.Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '%s = %s',
	ToNPL = function(self)
		return string.format('%s = %s\n', self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	examples = {{desc = "", canRun = true, code = [[
text = "hello"
say(text, 1)
]]}},
},


{
	type = "set", 
	message0 = L"全局%1赋值为%2",
	arg0 = {
		{
			name = "key",
			type = "input_value",
			shadow = { type = "text", value = L"变量名",},
			text = L"变量名", 
		},
		{
			name = "value",
			type = "input_value",
            shadow = { type = "functionParams", value = "1",},
			text = "1", 
		},
	},
	category = "NplMicrobit.Data", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "set",
	func_description = 'set(%s, %s)',
	ToNPL = function(self)
		return string.format('set("%s", %s)\n', self:getFieldAsString('key'), self:getFieldAsString('value'));
	end,
	examples = {{desc = L"也可以用_G.a", canRun = true, code = [[
_G.a = _G.a or 1
while(true) do
    _G.a = a + 1
    set("a", get("a") + 1)
    say(a)
end
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
	category = "NplMicrobit.Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "local",
	func_description = 'local %s = %s',
	ToPython = function(self)
		return string.format('%s = %s\n', self:getFieldAsString('var'), self:getFieldAsString('value'));
	end,
	ToNPL = function(self)
		return string.format('local %s = %s\n', self:getFieldAsString('var'), self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
local key = "value"
say(key, 1)
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
	category = "NplMicrobit.Data", 
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
				{ L"真", "True" },
				{ L"假", "False" },
				{ L"无效", "None" },
			  }
		},
	},
	output = {type = "field_number",},
	category = "NplMicrobit.Data", 
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
	category = "NplMicrobit.Data", 
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
	category = "NplMicrobit.Data", 
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

})