--[[
Title: BlockCadDef_Shapes
Author(s): leio
Date: 2018/12/12
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/BlockCad/BlockCadDef/BlockCadDef_Shapes.lua");
local BlockCadDef_Shapes = commonlib.gettable("MyCompany.Aries.Game.Code.BlockCad.BlockCadDef_Shapes");
-------------------------------------------------------
]]
local BlockCadDef_Shapes = commonlib.gettable("MyCompany.Aries.Game.Code.BlockCad.BlockCadDef_Shapes");
local cmds = {

{
	type = "ShapeBuilder.cube", 
	message0 = L"cube x %1 y %2 z %3 color %4",
    arg0 = {
        {
			name = "x",
			type = "input_value",
            shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
        {
			name = "y",
			type = "input_value",
            shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
        {
			name = "z",
			type = "input_value",
            shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
         
	},
    output = {type = "null",},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'ShapeBuilder.cube(%s,%s,%s,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "ShapeBuilder.cylinder", 
	message0 = L"cylinder radius %1 height %2 angle %3 color %4",
    arg0 = {
        {
			name = "radius",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
			text = 2, 
		},
        {
			name = "height",
			type = "input_value",
            shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
        {
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 360,},
			text = 360, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
        
	},
    output = {type = "null",},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'ShapeBuilder.cylinder(%s,%s,%s,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "ShapeBuilder.sphere", 
	message0 = L"sphere radius %1 angle1 %2 angle2 %3 angle3 %4 color %5",
    arg0 = {
        {
			name = "radius",
			type = "input_value",
            shadow = { type = "math_number", value = 5,},
			text = 5, 
		},
        {
			name = "angle1",
			type = "input_value",
            shadow = { type = "math_number", value = -90,},
			text = -90, 
		},
        {
			name = "angle2",
			type = "input_value",
            shadow = { type = "math_number", value = 90,},
			text = 90, 
		},
        {
			name = "angle3",
			type = "input_value",
            shadow = { type = "math_number", value = 360,},
			text = 360, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
        
	},
    output = {type = "null",},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'ShapeBuilder.sphere(%s,%s,%s,%s,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "ShapeBuilder.cone", 
	message0 = L"cone radius1 %1 radius2 %2 height %3 angle %4 color %5",
    arg0 = {
        {
			name = "radius1",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
			text = 2, 
		},
        {
			name = "radius2",
			type = "input_value",
            shadow = { type = "math_number", value = 4,},
			text = 4, 
		},
        {
			name = "height",
			type = "input_value",
            shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
        {
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 360,},
			text = 360, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
        
	},
    output = {type = "null",},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'ShapeBuilder.cone(nil,nil,nil,nil,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "ShapeBuilder.torus", 
	message0 = L"torus radius1 %1 radius2 %2 angle1 %3 angle2 %4 angle3 %5 color %6 ",
    arg0 = {
        {
			name = "radius1",
			type = "input_value",
            shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
        {
			name = "radius2",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
			text = 2, 
		},
        {
			name = "angle1",
			type = "input_value",
            shadow = { type = "math_number", value = -180,},
			text = -180, 
		},
        {
			name = "angle2",
			type = "input_value",
            shadow = { type = "math_number", value = 180,},
			text = 180, 
		},
        {
			name = "angle3",
			type = "input_value",
            shadow = { type = "math_number", value = 360,},
			text = 360, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
        
	},
    output = {type = "null",},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'ShapeBuilder.torus(%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "ShapeBuilder.point", 
	message0 = L"point x %1 y %2 z %3 color %4",
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
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
        
	},
    output = {type = "null",},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'ShapeBuilder.point(%s,%s,%s,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "ShapeBuilder.line", 
	message0 = L"line x1 %1 y1 %2 z1 %3 x2 %4 y2 %5 z2 %6 color %7",
    arg0 = {
        {
			name = "x1",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "y1",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "z1",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "x2",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "y2",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "z2",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
        
	},
    output = {type = "null",},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'ShapeBuilder.line(%s,%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "ShapeBuilder.plane", 
	message0 = L"plane l %1 w %2 color %3",
    arg0 = {
        {
			name = "l",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "w",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
        
	},
    output = {type = "null",},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'ShapeBuilder.plane(%s,%s,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "ShapeBuilder.circle", 
	message0 = L"circle r %1 a0 %2 a1 %3 color %4",
    arg0 = {
        {
			name = "r",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "a0",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "a1",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
        
	},
    output = {type = "null",},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'ShapeBuilder.circle(%s,%s,%s,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "ShapeBuilder.ellipse", 
	message0 = L"ellipse r1 %1 r2 %2 a0 %3 a1 %4 color %5",
    arg0 = {
        {
			name = "r1",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "r2",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "a0",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "a1",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
        
	},
    output = {type = "null",},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'ShapeBuilder.ellipse(%s,%s,%s,%s,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "ShapeBuilder.helix", 
	message0 = L"helix p %1 h %2 r %3 a %4 l %5 s %6 color %7",
    arg0 = {
        {
			name = "p",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "h",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "r",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "a",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "l",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "s",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
        
	},
    output = {type = "null",},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'ShapeBuilder.helix(%s,%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "ShapeBuilder.spiral", 
	message0 = L"spiral g %1 c %2 r %3 color %4",
    arg0 = {
        {
			name = "g",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "c",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "r",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
        
	},
    output = {type = "null",},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'ShapeBuilder.spiral(%s,%s,%s,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "ShapeBuilder.polygon", 
	message0 = L"polygon p %1 c %2 color %3",
    arg0 = {
        {
			name = "p",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "c",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
        
	},
    output = {type = "null",},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'ShapeBuilder.polygon(%s,%s,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},


{
	type = "ShapeBuilder.prism", 
	message0 = L"prism p %1 c %2 h %3 color %4",
    arg0 = {
        {
			name = "p",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "c",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "h",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
        
	},
    output = {type = "null",},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'ShapeBuilder.prism(%s,%s,%s,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "ShapeBuilder.wedge", 
	message0 = L"wedge x1 %1 y1 %2 z1 %3 x3 %4 z3 %5 x2 %6 y2 %7 z2 %8 x4 %9 z4 %10 color %11",
    arg0 = {
        {
			name = "x1",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "y1",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "z1",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "x3",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "z3",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "x2",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "y2",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "z2",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "x4",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "z4",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
        
	},
    output = {type = "null",},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'ShapeBuilder.wedge(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "ShapeBuilder.ellipsoid", 
	message0 = L"ellipsoid r1 %1 r2 %2 r3 %3 a1 %4 a2 %5 a3 %6 color %7",
    arg0 = {
        {
			name = "r1",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "r2",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "r3",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "a1",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "a2",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "a3",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
        
	},
    output = {type = "null",},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'ShapeBuilder.ellipsoid(%s,%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

}
function BlockCadDef_Shapes.GetCmds()
	return cmds;
end