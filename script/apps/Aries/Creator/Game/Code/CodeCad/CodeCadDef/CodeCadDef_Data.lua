--[[
Title: CodeCadDef_Data
Author(s): leio
Date: 2018/9/10
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCad/CodeCadDef/CodeCadDef_Data.lua");
local CodeCadDef_Data = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_Data");
-------------------------------------------------------
]]
local CodeCadDef_Data = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_Data");
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
	ToNPL = function(self)
		return 'key = "value"\n';
	end,
	examples = {{desc = "", canRun = true, code = [[
text = "hello"
say(text, 1)
]]}},
},
{
	type = "set", 
	message0 = L"设置全局变量%1为%2",
	arg0 = {
		{
			name = "key",
			type = "input_value",
			shadow = { type = "text", value = "score",},
			text = "score", 
		},
		{
			name = "value",
			type = "input_value",
            shadow = { type = "text", value = "1",},
			text = "1", 
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'set(%s, %s)',
	ToNPL = function(self)
		return string.format('set("%s", "%s")\n', self:getFieldAsString('key'), self:getFieldAsString('value'));
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
	ToNPL = function(self)
		return string.format('%s', self:getFieldAsString('left'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "getTableValue", 
	message0 = L"获取表%1中的%2",
	arg0 = {
		{
			name = "table",
			type = "field_variable",
			variable = "_G",
			text = "_G",
		},
		{
			name = "key",
			type = "input_value",
			variable = "_G",
			shadow = { type = "text", value = "key",},
			text = "key", 
		},
	},
	output = {type = "field_number",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s[%s]',
	ToNPL = function(self)
		return string.format('%s["%s"]', self:getFieldAsString('table'), self:getFieldAsString('key'));
	end,
	examples = {{desc = "", canRun = true, code = [[
local t = {}
t[1] = "hello"
t["age"] = 10;
log(t)
]]}},
},

{
	type = "newEmptyTable", 
	message0 = L"空的表{}",
	output = {type = "field_number",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '{}',
	ToNPL = function(self)
		return "{}";
	end,
	examples = {{desc = "", canRun = true, code = [[
local t = {}
t[1] = "hello"
t["age"] = 10;
log(t)
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
	output = {type = "null",},
	category = "Data", 
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
};
function CodeCadDef_Data.GetCmds()
	return cmds;
end
