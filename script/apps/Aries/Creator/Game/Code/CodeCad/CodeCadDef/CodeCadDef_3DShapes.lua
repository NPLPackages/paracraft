--[[
Title: CodeCadDef_3DShapes
Author(s): leio
Date: 2018/9/10
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCad/CodeCadDef/CodeCadDef_3DShapes.lua");
local CodeCadDef_3DShapes = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_3DShapes");
-------------------------------------------------------
]]
local CodeCadDef_3DShapes = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_3DShapes");
local cmds = {

{
	type = "cube", 
	message0 = L"cube    size %1",
	arg0 = {
		{
			name = "size",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
	},
	category = "3DShapes", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'cube(%d)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "cube_2", 
	message0 = L"cube    x %1 y %2 z %3",
	arg0 = {
		{
			name = "x",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "y",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "z",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
	},
	category = "3DShapes", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'cube({ size = {%d,%d,%d} })',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "cube_3", 
	message0 = L"cube    x %1 y %2 z %3 center %4 round %5",
	arg0 = {
		{
			name = "x",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "y",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "z",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "center",
			type = "field_dropdown",
			options = {
				{ "true", "true" },
				{ "false", "false" },
			},
		},
        {
			name = "round",
			type = "field_dropdown",
			options = {
				{ "true", "true" },
				{ "false", "false" },
			},
		},
	},
	category = "3DShapes", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'cube({ size = {%d,%d,%d}, center = %s, round = %s})',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "cube_4", 
	message0 = L"cube    x %1 y %2 z %3 center %4 round %5 radius %6 fn %7",
	arg0 = {
		{
			name = "x",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "y",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "z",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "center",
			type = "field_dropdown",
			options = {
				{ "true", "true" },
				{ "false", "false" },
			},
		},
        {
			name = "round",
			type = "field_dropdown",
			options = {
				{ "true", "true" },
			},
		},
        {
			name = "radius",
			type = "input_value",
            shadow = { type = "math_number", value = 0.2,},
			text = 0.2, 
		},
        {
			name = "fn",
			type = "input_value",
            shadow = { type = "math_number", value = 32,},
			text = 32, 
		},
	},
	category = "3DShapes", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'cube({ size = {%d,%d,%d}, center = %s, round = %s, radius = %s, fn = %s })',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "sphere", 
	message0 = L"sphere    r %1",
	arg0 = {
		{
			name = "r",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        
	},
	category = "3DShapes", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'sphere({ r = %d })',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "sphere_2", 
	message0 = L"sphere    r %1 center %2 fn %3",
	arg0 = {
		{
			name = "r",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "center",
			type = "field_dropdown",
			options = {
				{ "true", "true" },
				{ "false", "false" },
			},
		},
        {
			name = "fn",
			type = "input_value",
            shadow = { type = "math_number", value = 100,},
			text = 100, 
		},
	},
	category = "3DShapes", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'sphere({ r = %d, center = %s, fn = %s })',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "cylinder", 
	message0 = L"cylinder    r %1 h %2",
	arg0 = {
		{
			name = "r",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "h",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
	},
	category = "3DShapes", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'cylinder({ r = %d, h = %d })',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "cylinder_2", 
	message0 = L"cylinder    r1 %1 r2 %2 h %3 center %4",
	arg0 = {
		{
			name = "r1",
			type = "input_value",
            shadow = { type = "math_number", value = 3,},
			text = 3, 
		},
        {
			name = "r2",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "h",
			type = "input_value",
            shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
        {
			name = "center",
			type = "field_dropdown",
			options = {
				{ "true", "true" },
				{ "false", "false" },
			},
		},
	},
	category = "3DShapes", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'cylinder({ r1 = %d, r2 = %d, h = %d, center = %s })',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "cylinder_3", 
	message0 = L"cylinder    r %1 h %2 center %3 round %4 fn %5",
	arg0 = {
		{
			name = "r",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "h",
			type = "input_value",
            shadow = { type = "math_number", value = 5,},
			text = 5, 
		},
        {
			name = "center",
			type = "field_dropdown",
			options = {
				{ "true", "true" },
				{ "false", "false" },
			},
		},
        {
			name = "round",
			type = "field_dropdown",
			options = {
				{ "true", "true" },
			},
		},
        {
			name = "fn",
			type = "input_value",
            shadow = { type = "math_number", value = 16,},
			text = 16, 
		},
	},
	category = "3DShapes", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'cylinder({ r = %d, h = %d, center = %s, round = %s, fn = %s })',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "torus", 
	message0 = L"torus    ri %1 ro %2",
	arg0 = {
		{
			name = "ri",
			type = "input_value",
            shadow = { type = "math_number", value = 1.5,},
			text = 1.5, 
		},
        {
			name = "ro",
			type = "input_value",
            shadow = { type = "math_number", value = 3,},
			text = 3, 
		},
	},
	category = "3DShapes", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'torus({ ri = %s, ro = %s })',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "torus_2", 
	message0 = L"torus    ri %1 ro %2 fni %3 fno %4 roti %5",
	arg0 = {
        {
			name = "ri",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "ro",
			type = "input_value",
            shadow = { type = "math_number", value = 4,},
			text = 4, 
		},
		{
			name = "fni",
			type = "input_value",
            shadow = { type = "math_number", value = 4,},
			text = 4, 
		},
        {
			name = "fno",
			type = "input_value",
            shadow = { type = "math_number", value = 5,},
			text = 5, 
		},
        {
			name = "roti",
			type = "input_value",
            shadow = { type = "math_number", value = 45,},
			text = 45, 
		},
	},
	category = "3DShapes", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'torus({ ri = %s, ro = %s, fni = %s, fno = %s, roti = %s })',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},


};
function CodeCadDef_3DShapes.GetCmds()
	return cmds;
end
