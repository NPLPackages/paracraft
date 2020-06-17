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
	type = "createNode", 
	message0 = L"创建 %1 %2 %3",
    arg0 = {
        {
			name = "var_name",
			type = "field_variable",
			variable = "object0",
			variableTypes = {""},
			text = "object0",
		},
        {
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        {
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"合并", "true" },
				{ L"不合并", "false" },
			},
		},
	},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	nextStatement = true,
	funcName = "createNode",
	func_description = 'createNode("%s",%s,%s)',
	func_description_js = 'createNode("%s",%s,%s)',
	ToNPL = function(self)
		return string.format('createNode("%s","%s",%s)\n', 
        self:getFieldValue('var_name'), self:getFieldValue('color'), self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
createNode("object1", "#ffc658", true);
cube("union", 1.5, "#ffc658");
sphere("union", 1, "#ff0000");

createNode("object2", "#ffc658", true);
cube("union", 1.5, "#ffc658");
sphere("intersection", 1, "#ff0000");

createNode("object3", "#ffc658", true);
cube("union", 1.5, "#ffc658");
sphere("difference", 1, "#ff0000");
    ]]}},
	
},

{
	type = "pushNode", 
	message0 = L"%1 创建 %2 %3 %4",
	message1 = L"%1",
    arg0 = {
		{
			name = "op",
			type = "input_value",
            shadow = { type = "boolean_op", value = "union",},
			text = "union", 
		},
        {
			name = "var_name",
			type = "field_variable",
			variable = "object0",
			variableTypes = {""},
			text = "object0",
		},
        {
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        {
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"合并", "true" },
				{ L"不合并", "false" },
			},
		},
	},
  arg1 = {
		{
			name = "input",
			type = "input_statement",
		},
	},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
    previousStatement = true,
	nextStatement = true,
	hide_in_codewindow = true,
	funcName = "pushNode",
	func_description = 'pushNode(%s,"%s",%s,%s)\\n%spopNode()',
	func_description_js = 'pushNode(%s,"%s",%s,%s)\\n%spopNode()',
	ToNPL = function(self)
		return string.format('pushNode("%s","%s","%s",%s)\n%spopNode()', 
        self:getFieldValue('op'), self:getFieldValue('var_name'), self:getFieldValue('color'), self:getFieldValue('value'), self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
pushNode("union","object1",'#ffc658',true)
  cube("union",1,'#ffc658');
  cylinder("difference",1,10,'#ffc658');
popNode()
    ]]}},
},

{
	type = "pushNodeByName", 
	message0 = L"%1 创建 %2 %3 %4",
	message1 = L"%1",
    arg0 = {
		{
			name = "op",
			type = "input_value",
            shadow = { type = "boolean_op", value = "union",},
			text = "union", 
		},
        {
			name = "name",
			type = "input_value",
			shadow = { type = "text", value = "",},
			text = "",
		},
        {
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        {
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"合并", "true" },
				{ L"不合并", "false" },
			},
		},
	},
  arg1 = {
		{
			name = "input",
			type = "input_statement",
		},
	},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
    previousStatement = true,
	nextStatement = true,
	funcName = "pushNode",
	func_description = 'pushNode(%s,"%s",%s,%s)\\n%spopNode()',
	func_description_js = 'pushNode(%s,"%s",%s,%s)\\n%spopNode()',
	ToNPL = function(self)
		return string.format('pushNode("%s","%s","%s",%s)\n%spopNode()', 
        self:getFieldValue('op'), self:getFieldValue('name'), self:getFieldValue('color'), self:getFieldValue('value'), self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
pushNode("union","object1",'#ffc658',true)
  cube("union",1,'#ffc658');
  cylinder("difference",1,10,'#ffc658');
popNode()
    ]]}},
},
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
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
         
	},
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "cube",
	func_description = 'cube(%s,%s,%s)',
	func_description_js = 'cube(%s,%s,%s)',
	ToNPL = function(self)
		return string.format('cube("%s",%s,"%s")\n', self:getFieldValue('op'), self:getFieldValue('size'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
cube("union", 1, "#ffc658");
    ]]}},
},

{
	type = "box", 
	message0 = L" %1 长方体 X %2 Y %3 Z %4 %5",
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
            shadow = { type = "math_number", value = 1,},
			text = 2, 
		},
        {
			name = "z",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
			text = 1, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
         
	},
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "box",
	func_description = 'box(%s,%s,%s,%s,%s)',
	func_description_js = 'box(%s,%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('box("%s",%s,%s,%s,"%s")\n', self:getFieldValue('op'), self:getFieldValue('x'), self:getFieldValue('y'), self:getFieldValue('z'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
box("union", 1, 1, 2, "#ffc658");
box("difference", 1, 1, 2, "#ffc658");
    ]]}},
},

{
	type = "box_fillet", 
	message0 = L" %1 圆角 长方体 X %2 Y %3 Z %4 %5 %6 %7",
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
            shadow = { type = "math_number", value = 1,},
			text = 2, 
		},
        {
			name = "z",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
			text = 1, 
		},
        {
			name = "edges",
			type = "field_input",
			text = "{1,2,3,4,5,6,7,8,9,10,11,12}", 
		},
        {
			name = "values",
			type = "field_input",
			text = "{0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,}", 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
         
	},
	hide_in_toolbox = true,
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "box_fillet",
	func_description = 'box_fillet(%s,%s,%s,%s,%s,%s,%s)',
	func_description_js = 'box_fillet(%s,%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('box_fillet("%s",%s,%s,%s,%s,%s,"%s")\n', self:getFieldValue('op'), 
        self:getFieldValue('x'), self:getFieldValue('y'), self:getFieldValue('z'), 
        self:getFieldValue('edges'),
        self:getFieldValue('values'),
        self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "box_chamfer", 
	message0 = L" %1 斜角 长方体 X %2 Y %3 Z %4 %5 %6 %7",
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
            shadow = { type = "math_number", value = 1,},
			text = 2, 
		},
        {
			name = "z",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
			text = 1, 
		},
        {
			name = "edges",
			type = "field_input",
			text = "{1,2,3,4,5,6,7,8,9,10,11,12}", 
		},
        {
			name = "values",
			type = "field_input",
			text = "{0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,}", 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
         
	},
	hide_in_toolbox = true,
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "box_chamfer",
	func_description = 'box_chamfer(%s,%s,%s,%s,%s,%s,%s)',
	func_description_js = 'box_chamfer(%s,%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('box_chamfer("%s",%s,%s,%s,%s,%s,"%s")\n', self:getFieldValue('op'), 
        self:getFieldValue('x'), self:getFieldValue('y'), self:getFieldValue('z'), 
        self:getFieldValue('edges'),
        self:getFieldValue('values'),
        self:getFieldValue('color'));
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
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
	},
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "sphere",
	func_description = 'sphere(%s,%s,%s)',
	func_description_js = 'sphere(%s,%s,%s)',
	ToNPL = function(self)
		return string.format('sphere("%s",%s,"%s")\n', self:getFieldValue('op'), self:getFieldValue('radius'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
sphere("union", 1, #ffc658");
sphere("difference", 0.8, #ffc658");
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
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
        
	},
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "cylinder",
	func_description = 'cylinder(%s,%s,%s,%s)',
	func_description_js = 'cylinder(%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('cylinder("%s",%s,%s,"%s")\n', self:getFieldValue('op'), self:getFieldValue('radius'), self:getFieldValue('height'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
cylinder("union", 0.5, 2, #ffc658");
cylinder("difference", 0.8, 4, #ffc658");
    ]]}},
},

{
	type = "cylinder_fillet", 
	message0 = L"%1 圆角 柱体 半径 %2 高 %3 %4 %5 %6",
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
			name = "edges",
			type = "field_input",
			text = "{1,2}", 
		},
        {
			name = "values",
			type = "field_input",
			text = "{0.2,0.2}", 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
        
	},
	hide_in_toolbox = true,
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "cylinder_fillet",
	func_description = 'cylinder_fillet(%s,%s,%s,%s,%s,%s)',
	func_description_js = 'cylinder_fillet(%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('cylinder_fillet("%s",%s,%s,%s,%s,"%s")\n', self:getFieldValue('op'), 
        self:getFieldValue('radius'), self:getFieldValue('height'), 
        self:getFieldValue('edges'), self:getFieldValue('values'), 
        self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "cylinder_chamfer", 
	message0 = L"%1 斜角 柱体 半径 %2 高 %3 %4 %5 %6",
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
			name = "edges",
			type = "field_input",
			text = "{1,2}", 
		},
        {
			name = "values",
			type = "field_input",
			text = "{0.2,0.2}", 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
        
	},
	hide_in_toolbox = true,
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "cylinder_chamfer",
	func_description = 'cylinder_chamfer(%s,%s,%s,%s,%s,%s)',
	func_description_js = 'cylinder_chamfer(%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('cylinder_chamfer("%s",%s,%s,%s,%s,"%s")\n', self:getFieldValue('op'), 
        self:getFieldValue('radius'), self:getFieldValue('height'), 
        self:getFieldValue('edges'), self:getFieldValue('values'), 
        self:getFieldValue('color'));
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
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
        
	},
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "cone",
	func_description = 'cone(%s,%s,%s,%s,%s)',
	func_description_js = 'cone(%s,%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('cone("%s",%s,%s,%s,"%s")\n', self:getFieldValue('op'), self:getFieldValue('radius1'), self:getFieldValue('radius2'), self:getFieldValue('height'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
cone("union", 1, 4, 4, "#ffc658");
cone("difference", 1, 4, 4, "#ffc658");
    ]]}},
},

{
	type = "cone_fillet", 
	message0 = L"%1 圆角 圆锥体 顶部半径 %2 底部半径 %3 高 %4 %5 %6 %7",
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
			name = "edges",
			type = "field_input",
			text = "{1,2}", 
		},
        {
			name = "values",
			type = "field_input",
			text = "{0.2,0.2}", 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
        
	},
	hide_in_toolbox = true,
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "cone_fillet",
	func_description = 'cone_fillet(%s,%s,%s,%s,%s,%s,%s)',
	func_description_js = 'cone_fillet(%s,%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('cone_fillet("%s",%s,%s,%s,%s,%s,"%s")\n', self:getFieldValue('op'), 
        self:getFieldValue('radius1'), self:getFieldValue('radius2'), self:getFieldValue('height'), 
        self:getFieldValue('edges'), self:getFieldValue('values'), 
        self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "cone_chamfer", 
	message0 = L"%1 斜角 圆锥体 顶部半径 %2 底部半径 %3 高 %4 %5 %6 %7",
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
			name = "edges",
			type = "field_input",
			text = "{1,2}", 
		},
        {
			name = "values",
			type = "field_input",
			text = "{0.2,0.2}", 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
        
	},
	hide_in_toolbox = true,
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "cone_chamfer",
	func_description = 'cone_chamfer(%s,%s,%s,%s,%s,%s,%s)',
	func_description_js = 'cone_chamfer(%s,%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('cone_chamfer("%s",%s,%s,%s,%s,%s,"%s")\n', self:getFieldValue('op'), 
        self:getFieldValue('radius1'), self:getFieldValue('radius2'), self:getFieldValue('height'), 
        self:getFieldValue('edges'), self:getFieldValue('values'), 
        self:getFieldValue('color'));
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
            shadow = { type = "math_number", value = 0.5,},
			text = 0.5, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
	},
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "torus",
	func_description = 'torus(%s,%s,%s,%s)',
	func_description_js = 'torus(%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('torus("%s",%s,%s,"%s")\n', self:getFieldValue('op'), self:getFieldValue('radius1'), self:getFieldValue('radius2'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
torus("union", 4, 0.5, "#ffc658");
torus("difference", 4, 0.5, "#ffc658");
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
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
        
	},
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "prism",
	func_description = 'prism(%s,%s,%s,%s,%s)',
	func_description_js = 'prism(%s,%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('prism("%s",%s,%s,%s,"%s")\n',self:getFieldValue('op'), self:getFieldValue('p'), self:getFieldValue('c'), self:getFieldValue('h'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
prism("union", 6, 2, 4, "#ffc658");
prism("difference", 6, 2, 4, "#ffc658");
    ]]}},
},


{
	type = "ellipsoid", 
	message0 = L"%1 椭圆体 X半径 %2 Z半径 %3 Y半径 %4 %5",
    arg0 = {
        {
			name = "op",
			type = "input_value",
            shadow = { type = "boolean_op", value = "union",},
			text = "union", 
		},
        {
			name = "r_x",
			type = "input_value",
            shadow = { type = "math_number", value = 4,},
			text = 2, 
		},
        {
			name = "r_z",
			type = "input_value",
            shadow = { type = "math_number", value = 4,},
			text = 4, 
		},
        {
			name = "r_y",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 0, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
       
	},
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "ellipsoid",
	func_description = 'ellipsoid(%s,%s,%s,%s,%s)',
	func_description_js = 'ellipsoid(%s,%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('ellipsoid("%s",%s,%s,%s,"%s")\n', 
            self:getFieldValue('op'),
            self:getFieldValue('r_x'), self:getFieldValue('r_z'), self:getFieldValue('r_y'),
            self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
ellipsoid("union", 4, 4, 1, "#ffc658");
ellipsoid("difference", 4, 4, 1, "#ffc658");
    ]]}},
},
{
	type = "wedge", 
	message0 = L"%1 楔体 X %2 Z %3 Y %4 %5",
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
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
       
	},
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "wedge",
	func_description = 'wedge(%s,%s,%s,%s,%s)',
	func_description_js = 'wedge(%s,%s,%s,%s,%s)',
	ToNPL = function(self)
        return string.format('wedge("%s",%s,%s,%s,"%s")\n', 
            self:getFieldValue('op'), 
            self:getFieldValue('x'), self:getFieldValue('z'), self:getFieldValue('h'),
            self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
wedge("union", 1, 1, 1, "#ffc658");
wedge("difference", 1, 1, 1, "#ffc658");
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
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
       
	},
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "trapezoid",
	func_description = 'trapezoid(%s,%s,%s,%s,%s,%s)',
	func_description_js = 'trapezoid(%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
        return string.format('trapezoid("%s",%s,%s,%s,%s,"%s")\n', 
            self:getFieldValue('op'), 
            self:getFieldValue('top_w'), self:getFieldValue('bottom_w'), self:getFieldValue('hight'),self:getFieldValue('depth'), 
            self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
trapezoid("union", 2, 4, 5, 1, "#ffc658");
trapezoid("difference", 2, 4, 5, 1, "#ffc658");
    ]]}},
},

{
	type = "importStl", 
	message0 = L"引用Stl %1 %2 %3 YZ互换 %4",
    arg0 = {
        {
			name = "op",
			type = "input_value",
            shadow = { type = "boolean_op", value = "union",},
			text = "union", 
		},
        {
			name = "filename",
			type = "field_dropdown",
			options = {
				{ L"Arm01.stl", "Mod/NplCad2/stl/RobotArm/Arm01.stl" },
				{ L"Arm02.stl", "Mod/NplCad2/stl/RobotArm/Arm02.stl" },
				{ L"Arm03.stl", "Mod/NplCad2/stl/RobotArm/Arm03.stl" },
				{ L"Base.stl", "Mod/NplCad2/stl/RobotArm/Base.stl" },
				{ L"Gripper_Assembly.stl", "Mod/NplCad2/stl/RobotArm/Gripper_Assembly.stl" },
				{ L"Servo_Motor_MG996R.stl", "Mod/NplCad2/stl/RobotArm/Servo_Motor_MG996R.stl" },
				{ L"Servo_Motor_Micro_9g.stl", "Mod/NplCad2/stl/RobotArm/Servo_Motor_Micro_9g.stl" },
				{ L"Waist.stl", "Mod/NplCad2/stl/RobotArm/Waist.stl" },
			},
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        {
			name = "swapYZ",
			type = "field_dropdown",
			options = {
                { L"false", "false" },
				{ L"true", "true" },
			},
		},
        
	},
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "importStl",
	func_description = 'importStl(%s,"%s",%s, %s)',
	ToNPL = function(self)
        return string.format('importStl("%s","%s","%s", %s)\n', 
                self:getFieldValue('op'), 
                self:getFieldValue('filename'), 
                self:getFieldValue('color'),
                self:getFieldValue('swapYZ')
                );
	end,
	examples = {{desc = "", canRun = true, code = [[
importStl("union","Mod/NplCad2/stl/RobotArm/Arm01.stl",'#ffc658', false)
    ]]}},
},

{
	type = "importStl_2", 
	message0 = L"引用Stl %1 %2 %3 YZ互换 %4",
    arg0 = {
        {
			name = "op",
			type = "input_value",
            shadow = { type = "boolean_op", value = "union",},
			text = "union", 
		},
        {
			name = "filename",
			type = "field_input",
			text = "filename",
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        {
			name = "swapYZ",
			type = "field_dropdown",
			options = {
                { L"false", "false" },
				{ L"true", "true" },
			},
		},
        
	},
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "importStl",
	func_description = 'importStl(%s,"%s",%s,%s)',
	ToNPL = function(self)
        return string.format('importStl("%s","%s","%s",%s)\n', 
                self:getFieldValue('op'), 
                self:getFieldValue('filename'), 
                self:getFieldValue('color'),
                self:getFieldValue('swapYZ') 
                );
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
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
       
	},
	hide_in_toolbox = true,
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "wedge_full",
	func_description = 'wedge_full(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)',
	func_description_js = 'wedge_full(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)',
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
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
	},
	hide_in_toolbox = true,
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "point",
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
	message0 = L"%1 线 起点 %2, %3, %4 终点 %5 %6 %7 %8",
    arg0 = {
        {
			name = "op",
			type = "input_value",
            shadow = { type = "boolean_op", value = "union",},
			text = "union", 
		},
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
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
	},
	hide_in_toolbox = true,
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "line",
	func_description = 'line(%s,%s,%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
     return string.format('line("%s",%s,%s,%s,%s,%s,%s,"%s")\n', 
                self:getFieldValue('op'), 
            self:getFieldValue('x1'), self:getFieldValue('y1'), self:getFieldValue('z1'),
            self:getFieldValue('x2'), self:getFieldValue('y2'), self:getFieldValue('z2'),
            self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "plane", 
	message0 = L" %1 平面 长 %2 宽 %3 %4",
    arg0 = {
        {
			name = "op",
			type = "input_value",
            shadow = { type = "boolean_op", value = "union",},
			text = "union", 
		},
        {
			name = "l",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "w",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
	},
	hide_in_toolbox = false,
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "plane",
	func_description = 'plane(%s,%s,%s,%s)',
	ToNPL = function(self)
    return string.format('plane("%s",%s,%s,"%s")\n', 
            self:getFieldValue('op'), self:getFieldValue('l'), self:getFieldValue('w'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
plane("union",1,1,'#ffc658')
    ]]}},
},

{
	type = "circle", 
	message0 = L" %1 圆 半径 %2 角度1 %3 角度2 %4 %5",
    arg0 = {
        {
			name = "op",
			type = "input_value",
            shadow = { type = "boolean_op", value = "union",},
			text = "union", 
		},
        {
			name = "r",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
			text = 2, 
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
            shadow = { type = "math_number", value = 360,},
			text = 360, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
	},
	hide_in_toolbox = false,
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "circle",
	func_description = 'circle(%s,%s,%s,%s,%s)',
	ToNPL = function(self)
        return string.format('circle("%s",%s,%s,%s,"%s")\n', 
                self:getFieldValue('op'), 
                self:getFieldValue('r'),
                self:getFieldValue('a1'),
                self:getFieldValue('a2'),
                self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
circle("union",2,0,360,'#ffc658')
    ]]}},
},

{
	type = "ellipse", 
	message0 = L" %1 椭圆 主半径 %2 次半径 %3 角度1 %4 角度2 %5 %6",
    arg0 = {
        {
			name = "op",
			type = "input_value",
            shadow = { type = "boolean_op", value = "union",},
			text = "union", 
		},
        {
			name = "r1",
			type = "input_value",
            shadow = { type = "math_number", value = 4,},
			text = 4, 
		},
        {
			name = "r2",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
			text = 2, 
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
            shadow = { type = "math_number", value = 360,},
			text = 360, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
	},
	hide_in_toolbox = false,
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "ellipse",
	func_description = 'ellipse(%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
        return string.format('ellipse("%s",%s,%s,%s,%s,"%s")\n', 
                self:getFieldValue('op'), 
                self:getFieldValue('r1'), self:getFieldValue('r2'),
                self:getFieldValue('a1'), self:getFieldValue('a2'),
                self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
ellipse("union",4,2,0,360,'#ffc658')
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
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
	},
	hide_in_toolbox = true,
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "helix",
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
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
	},
	hide_in_toolbox = true,
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "spiral",
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
	type = "regularPolygon", 
	message0 = L" %1 正多边形 边数 %2 外接圆半径 %3 %4",
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
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
	},
	hide_in_toolbox = false,
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "regularPolygon",
	func_description = 'regularPolygon(%s,%s,%s,%s)',
	ToNPL = function(self)
        return string.format('regularPolygon("%s",%s,%s,"%s")\n', 
                self:getFieldValue('op'), 
                self:getFieldValue('p'), self:getFieldValue('c'), 
                self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
regularPolygon("union",6,2,'#ffc658')
    ]]}},
},

{
	type = "polygon", 
	message0 = L" %1 多边形 %2 %3",
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
			shadow = { type = "functionParams", value = "{0,0,0, 1,0,0, 1,1,0}",},
			text = "{0,0,0, 1,0,0, 1,1,0}",
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
	},
	hide_in_toolbox = false,
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "polygon",
	func_description = 'polygon(%s,%s,%s)',
	ToNPL = function(self)
        return string.format('polygon("%s",%s,"%s")\n', 
                self:getFieldValue('op'), 
                self:getFieldValue('p'),
                self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
polygon("union",{0,0,0, 1,0,0, 1,1,0},'#ffc658')
-- examples 2
function star(num, radii)
    local points = {}
    for i = 0, num-1 do
        local a = i * 2 * math.pi / num
        local r = radii[(i % #radii) + 1]
        table.insert(points, r * math.cos(a))
        table.insert(points, r * math.sin(a))
        table.insert(points, 0)
    end
    polygon("union",points,"#ff0000")
end


createNode("object0","#ffff00",false)
star(10, {1, 2.6})
star(40, {2,3,3,2})
move(6, 0, 0)
extrude(1)
star(30, {1.5,2,2.5,3,2.5,2})
move(12, 0, 0)
    ]]}},
},

{
	type = "createFromBrep_test", 
	message0 = L" %1 test %2",
    arg0 = {
        {
			name = "op",
			type = "input_value",
            shadow = { type = "boolean_op", value = "union",},
			text = "union", 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
         
	},
	hide_in_toolbox = true,
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "createFromBrep_test",
	func_description = 'createFromBrep_test(%s,%s)',
	func_description_js = 'createFromBrep_test(%s,%s)',
	ToNPL = function(self)
		return string.format('createFromBrep_test("%s","%s")\n', self:getFieldValue('op'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "text3d", 
	message0 = L" %1 文字 %2 字体 %3 大小 %4 厚度 %5 %6",
    arg0 = {
        {
			name = "op",
			type = "input_value",
            shadow = { type = "boolean_op", value = "union",},
			text = "union", 
		},
        {
			name = "text",
			type = "field_input",
			text = "Paracraft",
		},
        {
			name = "fontname",
			type = "input_value",
			shadow = { type = "font", value = "微软雅黑",},
			text = "'微软雅黑'", 
		},
        {
			name = "size",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "height",
			type = "input_value",
            shadow = { type = "math_number", value = 0.1,},
			text = 0.1, 
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffc658",},
			text = "#ffc658", 
		},
        
	},
    previousStatement = true,
	nextStatement = true,
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	funcName = "text3d",
	func_description = 'text3d(%s,"%s",%s, %s, %s, %s)',
	func_description_js = 'text3d(%s,"%s",%s, %s, %s)',
	ToNPL = function(self)
        return string.format('text3d("%s","%s",%s, %s, %s,"%s")\n', 
			self:getFieldValue('op'), self:getFieldValue('text'), self:getFieldValue('fontname'),
			self:getFieldValue('size'), self:getFieldValue('height'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
-- example1
createNode("object4",'#ff0000',true)
box("union",3,3,1.5,'#ffc658')
move(0,0,0.75)
text3d("difference","M","C:/WINDOWS/FONTS/MSYH.TTC", 2, 2, '#ffc658')
move((-1.2),(-1),0)

--example2
createNode("object4",'#ff0000',false)
text3d("union","Paracraft","C:/WINDOWS/FONTS/MSYH.TTC", 1, 0.1, '#0008ff')
move(0,1,0)
text3d("union","帕拉卡","C:/WINDOWS/FONTS/MSYH.TTC", 0.6, 0.1, '#ffffff')
move(6,1,0)
text3d("union","3D动画编程教育开创者","C:/WINDOWS/FONTS/MSYH.TTC", 0.8, 0.2, '#fd0000')
move((-1.2),0,0)
    ]]}},
},

{
	type = "font", 
	message0 = L"%1",
	arg0 = {
		
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"微软雅黑", "'MSYH'" },
				{ L"宋体", "'SIMSUN'" },
				{ L"仿宋", "'SIMFANG'" },
				{ L"楷体", "'SIMKAI'" },
			},
		},
	},
	hide_in_toolbox = true,
	output = {type = "null",},
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
	func_description_js = '%s',
	ToNPL = function(self)
		return string.format('%s', self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
	]]}},
},

}
function NplCadDef_Shapes.GetCmds()
	return cmds;
end