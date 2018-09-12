--[[
Title: CodeCadDef_Transforms
Author(s): leio
Date: 2018/9/10
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCad/CodeCadDef/CodeCadDef_Transforms.lua");
local CodeCadDef_Transforms = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_Transforms");
-------------------------------------------------------
]]
local CodeCadDef_Transforms = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_Transforms");
local cmds = {
{
	type = "color", 
	message0 = L"color    %1",
	arg0 = {
		{
			name = "c",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffffff",},
			text = "#ffffff", 
		},
        
	},
	category = "Transforms", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'color(%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "scale", 
	message0 = L"scale    x %1 y %2 z %3",
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
	category = "Transforms", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'scale({%d,%d,%d})',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "rotate", 
	message0 = L"rotate    x %1 y %2 z %3",
	arg0 = {
		{
			name = "x",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "y",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "z",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
	},
	category = "Transforms", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'rotate({%d,%d,%d})',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "translate", 
	message0 = L"translate    x %1 y %2 z %3",
	arg0 = {
		{
			name = "x",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "y",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "z",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
	},
	category = "Transforms", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'translate({%d,%d,%d})',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "linear_extrude_rectangle", 
	message0 = L"linear extrude rectangle   offset %1 twistangle %2 twiststeps %3 width %4 height %5",
	arg0 = {
        {
			name = "offest",
			type = "input_value",
            shadow = { type = "math_number", value = 5,},
			text = 5, 
		},
        {
			name = "twistangle",
			type = "input_value",
            shadow = { type = "math_number", value = 360,},
			text = 360, 
		},
        {
			name = "twiststeps",
			type = "input_value",
            shadow = { type = "math_number", value = 100,},
			text = 100, 
		},
        {
			name = "width",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "height",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
			text = 2, 
		},
	},
	category = "Transforms", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'linear_extrude({ offset = {0,0,%d} , twistangle = %d, twiststeps = %d, } , rectangle({ r = {%d,%d}, attach = false, }));',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "linear_extrude_roundedRectangle", 
	message0 = L"linear extrude roundedRectangle   offset %1 twistangle %2 twiststeps %3 width %4 height %5 roundradius %6 resolution %7",
	arg0 = {
        {
			name = "offest",
			type = "input_value",
            shadow = { type = "math_number", value = 5,},
			text = 5, 
		},
        {
			name = "twistangle",
			type = "input_value",
            shadow = { type = "math_number", value = 360,},
			text = 360, 
		},
        {
			name = "twiststeps",
			type = "input_value",
            shadow = { type = "math_number", value = 100,},
			text = 100, 
		},
        {
			name = "width",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "height",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
			text = 2, 
		},
        {
			name = "roundradius",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "resolution",
			type = "input_value",
            shadow = { type = "math_number", value = 32,},
			text = 32, 
		},
	},
	category = "Transforms", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'linear_extrude({ offset = {0,0,%d} , twistangle = %d, twiststeps = %d, } , roundedRectangle({ r = {%d,%d}, attach = false, roundradius = %d,resolution = %d}));',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "linear_extrude_circle", 
	message0 = L"linear extrude circle   offset %1 twistangle %2 twiststeps %3 r %4 ",
	arg0 = {
        {
			name = "offest",
			type = "input_value",
            shadow = { type = "math_number", value = 5,},
			text = 5, 
		},
        {
			name = "twistangle",
			type = "input_value",
            shadow = { type = "math_number", value = 360,},
			text = 360, 
		},
        {
			name = "twiststeps",
			type = "input_value",
            shadow = { type = "math_number", value = 100,},
			text = 100, 
		},
        {
			name = "r",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
	},
	category = "Transforms", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'linear_extrude({ offset = {0,0,%d} , twistangle = %d, twiststeps = %d, } , circle({ r = %d, center = true, attach = false, }));',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "rotate_extrude_rectangle", 
	message0 = L"rotate extrude rectangle   offset %1 fn %2 width %3 height %4",
	arg0 = {
        {
			name = "offest",
			type = "input_value",
            shadow = { type = "math_number", value = 5,},
			text = 5, 
		},
        {
			name = "fn",
			type = "input_value",
            shadow = { type = "math_number", value = 100,},
			text = 100, 
		},
        {
			name = "width",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "height",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
			text = 2, 
		},
	},
	category = "Transforms", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'rotate_extrude({ offset = {%d,0,0} , fn = %d} , rectangle({ r = {%d,%d}, attach = false, }));',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "rotate_extrude_roundedRectangle", 
	message0 = L"rotate extrude roundedRectangle   offset %1 fn %2 width %3 height %4 roundradius %5 resolution %6",
	arg0 = {
        {
			name = "offest",
			type = "input_value",
            shadow = { type = "math_number", value = 5,},
			text = 5, 
		},
        {
			name = "fn",
			type = "input_value",
            shadow = { type = "math_number", value = 100,},
			text = 100, 
		},
        {
			name = "width",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "height",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
			text = 2, 
		},
        {
			name = "roundradius",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "resolution",
			type = "input_value",
            shadow = { type = "math_number", value = 32,},
			text = 32, 
		},
	},
	category = "Transforms", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'rotate_extrude({ offset = {%d,0,0} , fn = %d} , roundedRectangle({ r = {%d,%d}, attach = false, roundradius = %d,resolution = %d}));',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "roate_extrude_circle", 
	message0 = L"rotate extrude circle   offset %1 fn %2 r %3 ",
	arg0 = {
        {
			name = "offest",
			type = "input_value",
            shadow = { type = "math_number", value = 5,},
			text = 5, 
		},
        {
			name = "fn",
			type = "input_value",
            shadow = { type = "math_number", value = 100,},
			text = 100, 
		},
        {
			name = "r",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
	},
	category = "Transforms", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'rotate_extrude({ offset = {%d,0,0} , fn = %d, } , circle({ r = %d, center = true, attach = false, }));',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

};
function CodeCadDef_Transforms.GetCmds()
	return cmds;
end
