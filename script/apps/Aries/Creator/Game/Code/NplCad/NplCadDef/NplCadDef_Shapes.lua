--[[
Title: NplCadDef_Shapes
Author(s): leio
Date: 2018/12/12
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadDef/NplCadDef_Shapes.lua");
local NplCadDef_Shapes = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Shapes");
-------------------------------------------------------
]]
local NplCadDef_Shapes = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Shapes");
local cmds = {
{
	type = "cube", 
	message0 = L" %1 正方体 %2 %3",
    arg0 = {
        {
			name = "op",
			type = "input_value",
            shadow = { type = "boolean_op", value = "union",},
			text = "union", 
		},
        {
			name = "size",
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
	func_description = 'cube(%s,%s,%s)',
	ToNPL = function(self)
		return string.format('cube("%s",%s,"%s")\n', self:getFieldValue('op'), self:getFieldValue('size'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "box", 
	message0 = L" %1 长方体 长 %2 宽 %3 高 %4 %5",
    arg0 = {
        {
			name = "op",
			type = "input_value",
            shadow = { type = "boolean_op", value = "union",},
			text = "union", 
		},
        {
			name = "x",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "y",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
			text = 2, 
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
	func_description = 'box(%s,%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('box("%s",%s,%s,%s,"%s")\n', self:getFieldValue('op'), self:getFieldValue('x'), self:getFieldValue('y'), self:getFieldValue('z'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "sphere", 
	message0 = L"%1 球体 半径 %2 %3",
    arg0 = {
        {
			name = "op",
			type = "input_value",
            shadow = { type = "boolean_op", value = "union",},
			text = "union", 
		},
        {
			name = "radius",
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
	func_description = 'sphere(%s,%s,%s)',
	ToNPL = function(self)
		return string.format('sphere("%s",%s,"%s")\n', self:getFieldValue('op'), self:getFieldValue('radius'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "cylinder", 
	message0 = L"%1 柱体 半径 %2 高 %3 %4",
    arg0 = {
        {
			name = "op",
			type = "input_value",
            shadow = { type = "boolean_op", value = "union",},
			text = "union", 
		},
        {
			name = "radius",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "height",
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
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'cylinder(%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('cylinder("%s",%s,%s,"%s")\n', self:getFieldValue('op'), self:getFieldValue('radius'), self:getFieldValue('height'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},



{
	type = "cone", 
	message0 = L"%1 圆锥体 顶部半径 %2 底部半径 %3 高 %4 %5",
    arg0 = {
        {
			name = "op",
			type = "input_value",
            shadow = { type = "boolean_op", value = "union",},
			text = "union", 
		},
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
		return string.format('cone("%s",%s,%s,%s,"%s")\n', self:getFieldValue('op'), self:getFieldValue('radius1'), self:getFieldValue('radius2'), self:getFieldValue('height'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "torus", 
	message0 = L"%1 圆环 半径 %2 管道半径 %3 %4",
    arg0 = {
        {
			name = "op",
			type = "input_value",
            shadow = { type = "boolean_op", value = "union",},
			text = "union", 
		},
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
	func_description = 'torus(%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('torus("%s",%s,%s,"%s")\n', self:getFieldValue('op'), self:getFieldValue('radius1'), self:getFieldValue('radius2'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "prism", 
	message0 = L"%1 棱柱 边 %2 半径 %3 高 %4 %5",
    arg0 = {
        {
			name = "op",
			type = "input_value",
            shadow = { type = "boolean_op", value = "union",},
			text = "union", 
		},
        {
			name = "p",
			type = "input_value",
            shadow = { type = "math_number", value = 6,},
			text = 6, 
		},
        {
			name = "c",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
			text = 2, 
		},
        {
			name = "h",
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
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'prism(%s,%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('prism("%s",%s,%s,%s,"%s")\n',self:getFieldValue('op'), self:getFieldValue('p'), self:getFieldValue('c'), self:getFieldValue('h'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},


{
	type = "ellipsoid", 
	message0 = L"%1 椭圆体 高半径 %2 宽半径 %3 长半径 %4 %5",
    arg0 = {
        {
			name = "op",
			type = "input_value",
            shadow = { type = "boolean_op", value = "union",},
			text = "union", 
		},
        {
			name = "r_z",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
			text = 2, 
		},
        {
			name = "r_x",
			type = "input_value",
            shadow = { type = "math_number", value = 4,},
			text = 4, 
		},
        {
			name = "r_y",
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
	func_description = 'ellipsoid(%s,%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('ellipsoid("%s",%s,%s,%s,"%s")\n', 
            self:getFieldValue('op'),
            self:getFieldValue('r_z'), self:getFieldValue('r_x'), self:getFieldValue('r_y'),
            self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "wedge", 
	message0 = L"%1 楔体 长 %2 宽 %3 深度 %4 %5",
    arg0 = {
        {
			name = "op",
			type = "input_value",
            shadow = { type = "boolean_op", value = "union",},
			text = "union", 
		},
        {
			name = "x",
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
			name = "h",
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
	func_description = 'wedge(%s,%s,%s,%s,%s)',
	ToNPL = function(self)
        return string.format('wedge("%s",%s,%s,%s,"%s")\n', 
            self:getFieldValue('op'), 
            self:getFieldValue('x'), self:getFieldValue('z'), self:getFieldValue('h'),
            self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
		
    ]]}},
},
{
	type = "trapezoid", 
	message0 = L"%1 梯形 顶宽 %2 底宽 %3 高 %4 厚 %5 %6",
    arg0 = {
        {
			name = "op",
			type = "input_value",
            shadow = { type = "boolean_op", value = "union",},
			text = "union", 
		},
        {
			name = "top_w",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
			text = 2, 
		},
        {
			name = "bottom_w",
			type = "input_value",
            shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
        {
			name = "hight",
			type = "input_value",
            shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
        {
			name = "depth",
			type = "input_value",
            shadow = { type = "math_number", value = 0.5,},
			text = 0.5, 
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
	func_description = 'trapezoid(%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
        return string.format('trapezoid(("%s",%s,%s,%s,%s,"%s")\n', 
            self:getFieldValue('op'), 
            self:getFieldValue('top_w'), self:getFieldValue('bottom_w'), self:getFieldValue('hight'),self:getFieldValue('depth'), 
            self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
		
    ]]}},
},

{
	type = "wedge_full", 
	message0 = L"%1 楔体X xmin %2 ymin %3 zmin %4 x2min %5 z2min %6 xmax %7 ymax %8 zmax %9 x2max %10 z2max %11 %12",
    arg0 = {
        {
			name = "op",
			type = "input_value",
            shadow = { type = "boolean_op", value = "union",},
			text = "union", 
		},
        {
			name = "xmin",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "ymin",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "zmin",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "x2min",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
			text = 2, 
		},
        {
			name = "z2min",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
			text = 2, 
		},
        {
			name = "xmax",
			type = "input_value",
            shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
        {
			name = "ymax",
			type = "input_value",
            shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
        {
			name = "zmax",
			type = "input_value",
            shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
        {
			name = "x2max",
			type = "input_value",
            shadow = { type = "math_number", value = 8,},
			text = 8, 
		},
        {
			name = "z2max",
			type = "input_value",
            shadow = { type = "math_number", value = 8,},
			text = 8, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
       
	},
	hide_in_toolbox = true,
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'wedge_full(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
        return string.format('wedge_full(("%s",%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,"%s")\n', 
            self:getFieldValue('op'), 
            self:getFieldValue('xmin'), self:getFieldValue('ymin'), self:getFieldValue('zmin'),
            self:getFieldValue('x2min'), self:getFieldValue('z2min'), 
            self:getFieldValue('xmax'), self:getFieldValue('ymax'), self:getFieldValue('zmax'),
            self:getFieldValue('x2max'), self:getFieldValue('z2max'), 
            self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
		
    ]]}},
},

{
	type = "point", 
	message0 = L"point (%1,%2,%3) color %4",
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
	hide_in_toolbox = true,
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
	message0 = L"line from(%1,%2,%3) to(%4,%5,%6) color %7",
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
            shadow = { type = "math_number", value = 10,},
			text = 10, 
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
	hide_in_toolbox = true,
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
            shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
        {
			name = "w",
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
	hide_in_toolbox = true,
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
	message0 = L"circle %1 color %2",
    arg0 = {
        {
			name = "r",
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
	hide_in_toolbox = true,
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'circle(%s,%s)',
	ToNPL = function(self)
        return string.format('circle(%s,"%s")\n', 
                self:getFieldValue('r'), 
                self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "ellipse", 
	message0 = L"ellipse r1 %1 r2 %2 color %3",
    arg0 = {
        {
			name = "r1",
			type = "input_value",
            shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
        {
			name = "r2",
			type = "input_value",
            shadow = { type = "math_number", value = 5,},
			text = 5, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
        
	},
	hide_in_toolbox = true,
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'ellipse(%s,%s,%s)',
	ToNPL = function(self)
        return string.format('ellipse(%s,%s,"%s")\n', 
                self:getFieldValue('r1'), self:getFieldValue('r2'),
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
	hide_in_toolbox = true,
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
	hide_in_toolbox = true,
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
            shadow = { type = "math_number", value = 6,},
            text = 6,
		},
        {
			name = "c",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
            text = 2,
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
        
	},
	hide_in_toolbox = true,
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
function NplCadDef_Shapes.GetCmds()
	return cmds;
end