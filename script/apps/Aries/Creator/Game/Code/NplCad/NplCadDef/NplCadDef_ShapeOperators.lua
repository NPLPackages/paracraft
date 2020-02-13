--[[
Title: NplCadDef_ShapeOperators
Author(s): leio
Date: 2018/12/13
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadDef/NplCadDef_ShapeOperators.lua");
local NplCadDef_ShapeOperators = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_ShapeOperators");
-------------------------------------------------------
]]
local NplCadDef_ShapeOperators = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_ShapeOperators");
local cmds = {

{
	type = "move", 
	message0 = L"移动 %1 %2 %3",
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
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "move",
	func_description = 'move(%s,%s,%s)',
	func_description_js = 'move(%s,%s,%s)',
	ToNPL = function(self)
        return string.format('move(%s,%s,%s)\n', 
            self:getFieldValue('x'),self:getFieldValue('y'),self:getFieldValue('z'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "scale", 
	message0 = L"缩放 %1 %2 %3",
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
	hide_in_toolbox = true,
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "scale",
	func_description = 'scale(%s,%s,%s)',
	func_description_js = 'scale(%s,%s,%s)',
	ToNPL = function(self)
        return string.format('scale(%s,%,%s)\n', 
            self:getFieldValue('x'),self:getFieldValue('y'),self:getFieldValue('z')
            );
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "rotate", 
	message0 = L"旋转 %1 %2 度",
    arg0 = {
        {
			name = "axis",
			type = "input_value",
            shadow = { type = "axis", value = "x",},
			text = "'x'", 
		},
        {
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
	},
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "rotate",
	func_description = 'rotate(%s,%s)',
	func_description_js = 'rotate(%s,%s)',
	ToNPL = function(self)
        return string.format('rotate(%s,%s)\n', 
            self:getFieldValue('axis'),self:getFieldValue('angle'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},



{
	type = "rotateFromPivot", 
	message0 = L"旋转 %1 %2 度 中心点 %3 %4 %5",
    arg0 = {
        {
			name = "axis",
			type = "input_value",
            shadow = { type = "axis", value = "x",},
			text = "'x'", 
		},
        {
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "tx",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "ty",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "tz",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        
	},
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "rotateFromPivot",
	func_description = 'rotateFromPivot(%s,%s,%s,%s,%s)',
	func_description_js = 'rotateFromPivot(%s,%s,%s,%s,%s)',
	ToNPL = function(self)
        return string.format('rotateFromPivot(%s,%s,%s,%s,%s)\n', 
            self:getFieldValue('axis'),self:getFieldValue('angle'),
            self:getFieldValue('tx'),self:getFieldValue('ty'),self:getFieldValue('tz')
            );
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "moveNode", 
	message0 = L"移动对象 %1 %2 %3 %4",
    arg0 = {
        {
			name = "name",
			type = "input_value",
			text = "", 
		},
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
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "moveNode",
	func_description = 'moveNode(%s,%s,%s,%s)',
	func_description_js = 'moveNode(%s,%s,%s,%s)',
	ToNPL = function(self)
        return string.format('moveNode("%s",%s,%s,%s)\n', 
            self:getFieldValue('name'),
            self:getFieldValue('x'),self:getFieldValue('y'),self:getFieldValue('z'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "scaleNode", 
	message0 = L"缩放对象 %1 %2 %3 %4",
    arg0 = {
        {
			name = "name",
			type = "input_value",
			text = "", 
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
			text = 1, 
		},
        {
			name = "z",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        
	},
	hide_in_toolbox = true,
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "scaleNode",
	func_description = 'scaleNode(%s,%s,%s,%s)',
	func_description_js = 'scaleNode(%s,%s,%s,%s)',
	ToNPL = function(self)
        return string.format('scaleNode("%s",%s,%s,%s)\n', 
            self:getFieldValue('name'),
            self:getFieldValue('x'),self:getFieldValue('y'),self:getFieldValue('z'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "rotateNode", 
	message0 = L"旋转对象 %1 %2 %3 度",
    arg0 = {
        {
			name = "name",
			type = "input_value",
			text = "", 
		},
        {
			name = "axis",
			type = "input_value",
            shadow = { type = "axis", value = "x",},
			text = "'x'", 
		},
        {
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
	},
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "rotateNode",
	func_description = 'rotateNode(%s,%s,%s)',
	func_description_js = 'rotateNode(%s,%s,%s)',
	ToNPL = function(self)
        return string.format('rotateNode("%s",%s,%s)\n', 
            self:getFieldValue('name'),
            self:getFieldValue('axis'),self:getFieldValue('angle'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "rotateNodeFromPivot", 
	message0 = L"旋转对象 %1 %2 %3 度 中心点 %4 %5 %6",
    arg0 = {
        {
			name = "name",
			type = "input_value",
			text = "", 
		},
        {
			name = "axis",
			type = "input_value",
            shadow = { type = "axis", value = "x",},
			text = "'x'", 
		},
        {
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "tx",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "ty",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "tz",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        
	},
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "rotateNodeFromPivot",
	func_description = 'rotateNodeFromPivot(%s,%s,%s,%s,%s,%s)',
	func_description_js = 'rotateNodeFromPivot(%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
        return string.format('rotateNodeFromPivot("%s",%s,%s,%s,%s,%s)\n', 
            self:getFieldValue('name'),
            self:getFieldValue('axis'),self:getFieldValue('angle'),
            self:getFieldValue('tx'),self:getFieldValue('ty'),self:getFieldValue('tz')
            );
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "cloneNodeByName", 
	message0 = L"%1 复制 %2 %3",
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
			text = "", 
		},
         {
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
        
	},
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
    previousStatement = true,
	nextStatement = true,
	funcName = "cloneNodeByName",
	func_description = 'cloneNodeByName(%s,%s,%s)',
	func_description_js = 'cloneNodeByName(%s,%s,%s)',
	ToNPL = function(self)
        return string.format('cloneNodeByName("%s","%s","%s")\n', 
            self:getFieldValue('op'), self:getFieldValue('name'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "cloneNode", 
	message0 = L"%1 复制 %2",
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
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
        
	},
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
    previousStatement = true,
	nextStatement = true,
	funcName = "cloneNode",
	func_description = 'cloneNode(%s,%s)',
	func_description_js = 'cloneNode(%s,%s)',
	ToNPL = function(self)
        return string.format('cloneNode("%s","%s")\n', 
            self:getFieldValue('op'), self:getFieldValue('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "deleteNode", 
	message0 = L"删除 %1",
    arg0 = {
       {
			name = "name",
			type = "input_value",
			text = "", 
		},
	},
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
    previousStatement = true,
	nextStatement = true,
	funcName = "deleteNode",
	func_description = 'deleteNode(%s)',
	func_description_js = 'deleteNode(%s)',
	ToNPL = function(self)
        return string.format('deleteNode("%s")\n', 
            self:getFieldValue('name'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "mirror", 
	message0 = L"镜像 %1 中心点 %2 %3 %4",
    arg0 = {
        {
			name = "axis_plane",
			type = "input_value",
            shadow = { type = "axis_plane", value = "xy",},
			text = "'xy'", 
		},
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
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "mirror",
	func_description = 'mirror(%s,%s,%s,%s)',
	func_description_js = 'mirror(%s,%s,%s,%s)',
	ToNPL = function(self)
        return string.format('mirror(%s,%s,%s,%s)\n', 
            self:getFieldValue('axis_plane'),
            self:getFieldValue('x'),self:getFieldValue('y'),self:getFieldValue('z')
            );
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "mirrorNode", 
	message0 = L"镜像对象 %1 %2 中心点 %3 %4 %5",
    arg0 = {
        {
			name = "name",
			type = "input_value",
			text = "", 
		},
        {
			name = "axis_plane",
			type = "input_value",
            shadow = { type = "axis_plane", value = "xy",},
			text = "'xy'", 
		},
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
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "mirrorNode",
	func_description = 'mirrorNode(%s,%s,%s,%s,%s)',
	func_description_js = 'mirrorNode(%s,%s,%s,%s,%s)',
	ToNPL = function(self)
        return string.format('mirrorNode("%s",%s,%s,%s,%s)\n', 
            self:getFieldValue('name'),
            self:getFieldValue('axis_plane'),
            self:getFieldValue('x'),self:getFieldValue('y'),self:getFieldValue('z')
            );
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "setLocalPivotOffset", 
	message0 = L"骨骼绑定中心点偏移 %1 %2 %3",
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
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "setLocalPivotOffset",
	func_description = 'setLocalPivotOffset(%s,%s,%s)',
	func_description_js = 'setLocalPivotOffset(%s,%s,%s)',
	ToNPL = function(self)
        return string.format('setLocalPivotOffset(%s,%s,%s)\n', 
            self:getFieldValue('x'),self:getFieldValue('y'),self:getFieldValue('z'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "setLocalPivotOffset_Node", 
	message0 = L"骨骼绑定中心点偏移 %1 %2 %3 %4",
    arg0 = {
		{
			name = "name",
			type = "input_value",
			text = "", 
		},
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
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "setLocalPivotOffset_Node",
	func_description = 'setLocalPivotOffset_Node(%s,%s,%s,%s)',
	func_description_js = 'setLocalPivotOffset_Node(%s,%s,%s,%s)',
	ToNPL = function(self)
        return string.format('setLocalPivotOffset_Node("%s",%s,%s,%s)\n', 
            self:getFieldValue('name'),self:getFieldValue('x'),self:getFieldValue('y'),self:getFieldValue('z'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "boolean_op", 
	message0 = L"%1",
    arg0 = {
        
        {
			name = "value",
			type = "field_dropdown",
			options = {
                { L"+", "union" },
				{ L"-", "difference" },
				{ L"x", "intersection" },
			},
		},
	},
	hide_in_toolbox = true,
    output = {type = "null",},
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
	func_description = '"%s"',
	func_description_js = '"%s"',
	ToNPL = function(self)
        return string.format('"%s"', 
            self:getFieldValue('value')
            );
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "axis", 
	message0 = L"%1",
    arg0 = {
        
        {
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"x轴", "'x'" },
				{ L"y轴", "'y'" },
				{ L"z轴", "'z'" },
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
{
	type = "axis_plane", 
	message0 = L"%1",
    arg0 = {
        
        {
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"xy平面", "'xy'" },
				{ L"xz平面", "'xz'" },
				{ L"yz平面", "'yz'" },
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
function NplCadDef_ShapeOperators.GetCmds()
	return cmds;
end