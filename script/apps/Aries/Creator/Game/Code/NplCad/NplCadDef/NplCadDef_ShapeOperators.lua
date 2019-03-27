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
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
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
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
	nextStatement = true,
	func_description = 'createNode("%s",%s,%s)',
	ToNPL = function(self)
		return string.format('createNode("%s","%s",%s)\n', 
        self:getFieldValue('var_name'), self:getFieldValue('color'), self:getFieldValue('value'));
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
	func_description = 'cloneNodeByName(%s,%s,%s)',
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
	func_description = 'cloneNode(%s,%s)',
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
	func_description = 'deleteNode(%s)',
	ToNPL = function(self)
        return string.format('deleteNode("%s")\n', 
            self:getFieldValue('name'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
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
	func_description = 'move(%s,%s,%s)',
	ToNPL = function(self)
        return string.format('move(%s,%s,%s)\n', 
            self:getFieldValue('x'),self:getFieldValue('y'),self:getFieldValue('z'));
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
	func_description = 'rotate(%s,%s)',
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
	func_description = 'rotateFromPivot(%s,%s,%s,%s,%s)',
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