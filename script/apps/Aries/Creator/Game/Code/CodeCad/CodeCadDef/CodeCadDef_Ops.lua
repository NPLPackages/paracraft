--[[
Title: CodeCadDef_Ops
Author(s): leio
Date: 2018/9/10
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCad/CodeCadDef/CodeCadDef_Ops.lua");
local CodeCadDef_Ops = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_Ops");
-------------------------------------------------------
]]
local CodeCadDef_Ops = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_Ops");
local cmds = {
{
	type = "union", 
	message0 = L"union",
	arg0 = {
		
	},
	category = "Ops", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'union()',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "intersection", 
	message0 = L"intersection",
	arg0 = {
		
	},
	category = "Ops", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'intersection()',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "difference", 
	message0 = L"difference",
	arg0 = {
		
	},
	category = "Ops", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'difference()',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "push", 
	message0 = L"push",
	arg0 = {
		
	},
	category = "Ops", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'push()',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "pop", 
	message0 = L"pop",
	arg0 = {
		
	},
	category = "Ops", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'pop()',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "cad_push_pop", 
	message0 = L"push%1",
    message1 = L"%1",
    message2 = L"pop%1",
	arg0 = {
		{
			name = "push_dummy",
			type = "input_dummy",
		},
	},
	arg1 = {
		{
			name = "input",
			type = "input_statement",
		},
	},
	arg2 = {
		{
			name = "push_dummy",
			type = "input_dummy",
		},
	},
	category = "Ops", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'push()\\n%spop()',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
};
function CodeCadDef_Ops.GetCmds()
	return cmds;
end
