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
	type = "cube", 
	message0 = L"cube x %1 y %2 z %3 color %4",
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
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
         
	},
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'cube(%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('cube(%s,%s,%s,"%s")\n', self:getFieldValue('x'), self:getFieldValue('y'), self:getFieldValue('z'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "cylinder", 
	message0 = L"cylinder radius %1 height %2 angle %3 color %4",
    arg0 = {
        {
			name = "radius",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "height",
			type = "input_value",
            shadow = { type = "math_number", value = 3,},
			text = 3, 
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
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'cylinder(%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('cylinder(%s,%s,%s,"%s")\n', self:getFieldValue('radius'), self:getFieldValue('height'), self:getFieldValue('angle'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "sphere", 
	message0 = L"sphere radius %1 angle1 %2 angle2 %3 angle3 %4 color %5",
    arg0 = {
        {
			name = "radius",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
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
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'sphere(%s,%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('sphere(%s,%s,%s,%s,"%s")\n', self:getFieldValue('radius'), self:getFieldValue('angle1'), self:getFieldValue('angle2'), self:getFieldValue('angle3'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "cone", 
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
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'cone(%s,%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('cone(%s,%s,%s,%s,"%s")\n', self:getFieldValue('radius1'), self:getFieldValue('radius2'), self:getFieldValue('height'), self:getFieldValue('angle'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "torus", 
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
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'torus(%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('torus(%s,%s,%s,%s,%s,"%s")\n', self:getFieldValue('radius1'), self:getFieldValue('radius2'), self:getFieldValue('angle1'), self:getFieldValue('angle2'), self:getFieldValue('angle3'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "prism", 
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
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'prism(%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('prism(%s,%s,%s,"%s")\n', self:getFieldValue('p'), self:getFieldValue('c'), self:getFieldValue('h'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "wedge", 
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
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'wedge(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
        return string.format('wedge(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,"%s")\n', 
            self:getFieldValue('x1'), self:getFieldValue('y1'), self:getFieldValue('z1'),
            self:getFieldValue('x3'),self:getFieldValue('z3'),self:getFieldValue('x2'), 
            self:getFieldValue('y2'),self:getFieldValue('z2'),self:getFieldValue('x4'), 
            self:getFieldValue('z4'), 
            self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
		
    ]]}},
},

{
	type = "ellipsoid", 
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
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'ellipsoid(%s,%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('ellipsoid(%s,%s,%s,%s,%s,%s,"%s")\n', 
            self:getFieldValue('r1'), self:getFieldValue('r2'), self:getFieldValue('r3'),
            self:getFieldValue('a1'), self:getFieldValue('a2'), self:getFieldValue('a3'),
            self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "point", 
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
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'point(%s,%s,%s,%s)',
	ToNPL = function(self)
        return string.format('point(%s,%s,%s,"%s")\n', 
            self:getFieldValue('x'), self:getFieldValue('y'), self:getFieldValue('z'),
            self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "line", 
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
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'line(%s,%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
     return string.format('line(%s,%s,%s,%s,%s,%s,"%s")\n', 
            self:getFieldValue('x1'), self:getFieldValue('y1'), self:getFieldValue('z1'),
            self:getFieldValue('x2'), self:getFieldValue('y2'), self:getFieldValue('z2'),
            self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "plane", 
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
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'plane(%s,%s,%s)',
	ToNPL = function(self)
    return string.format('plane(%s,%s,"%s")\n', 
            self:getFieldValue('l'), self:getFieldValue('w'), 
            self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "circle", 
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
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'circle(%s,%s,%s,%s)',
	ToNPL = function(self)
        return string.format('circle(%s,%s,%s,"%s")\n', 
                self:getFieldValue('r'), self:getFieldValue('a0'), self:getFieldValue('a1'), 
                self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "ellipse", 
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
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'ellipse(%s,%s,%s,%s,%s)',
	ToNPL = function(self)
        return string.format('ellipse(%s,%s,%s,%s,"%s")\n', 
                self:getFieldValue('r1'), self:getFieldValue('r2'), self:getFieldValue('a0'), self:getFieldValue('a1'), 
                self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "helix", 
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
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'helix(%s,%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
        return string.format('helix(%s,%s,%s,%s,%s,%s,"%s")\n', 
                self:getFieldValue('p'), self:getFieldValue('h'), self:getFieldValue('r'), self:getFieldValue('a'), self:getFieldValue('l'), self:getFieldValue('s'), 
                self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "spiral", 
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
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'spiral(%s,%s,%s,%s)',
	ToNPL = function(self)
        return string.format('spiral(%s,%s,%s,"%s")\n', 
                self:getFieldValue('g'), self:getFieldValue('c'), self:getFieldValue('r'), 
                self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "polygon", 
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
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'polygon(%s,%s,%s)',
	ToNPL = function(self)
        return string.format('polygon(%s,%s,"%s")\n', 
                self:getFieldValue('p'), self:getFieldValue('c'), 
                self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},




}
function BlockCadDef_Shapes.GetCmds()
	return cmds;
end