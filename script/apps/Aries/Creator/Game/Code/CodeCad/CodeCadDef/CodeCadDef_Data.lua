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
	type = "log", 
	message0 = "log   \"%1\"",
	arg0 = {
		{
			name = "left",
			type = "field_input",
			text = "string",
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'log("%s")',
	ToNPL = function(self)
		
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

};
function CodeCadDef_Data.GetCmds()
	return cmds;
end
