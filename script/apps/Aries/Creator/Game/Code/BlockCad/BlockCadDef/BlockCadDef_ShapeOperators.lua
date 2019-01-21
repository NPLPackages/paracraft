--[[
Title: BlockCadDef_ShapeOperators
Author(s): leio
Date: 2018/12/13
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/BlockCad/BlockCadDef/BlockCadDef_ShapeOperators.lua");
local BlockCadDef_ShapeOperators = commonlib.gettable("MyCompany.Aries.Game.Code.BlockCad.BlockCadDef_ShapeOperators");
-------------------------------------------------------
]]
local BlockCadDef_ShapeOperators = commonlib.gettable("MyCompany.Aries.Game.Code.BlockCad.BlockCadDef_ShapeOperators");
local cmds = {


{
	type = "_ShapeBuilder.beginTranslation", 
	message0 = L"beginTranslation( x %1 y %2 z %3)",
    message1 = L"%1",
	message2 = L"endTranslation()",
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
    arg1 = {
		{
			name = "input",
			type = "input_statement",
		},
	},
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'ShapeBuilder.beginTranslation(%s,%s,%s)\\n%sShapeBuilder.endTranslation()',
	ToNPL = function(self)
		return string.format('ShapeBuilder.beginTranslation(%s,%s,%s)\n    %s\nShapeBuilder.endTranslation()\n', 
            self:getFieldValue('x'), self:getFieldValue('y'), self:getFieldValue('z'), self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},


{
	type = "_ShapeBuilder.beginScale", 
	message0 = L"beginScale( x %1 y %2 z %3)",
    message1 = L"%1",
	message2 = L"endScale()",
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
    arg1 = {
		{
			name = "input",
			type = "input_statement",
		},
	},
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'ShapeBuilder.beginScale(%s,%s,%s)\\n%sShapeBuilder.endScale()',
	ToNPL = function(self)
    return string.format('ShapeBuilder.beginScale(%s,%s,%s)\n    %s\nShapeBuilder.endScale()\n', 
            self:getFieldValue('x'), self:getFieldValue('y'), self:getFieldValue('z'), self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "_ShapeBuilder.beginRotation", 
	message0 = L"beginRotation( x %1 y %2 z %3 angle %4)",
    message1 = L"%1",
	message2 = L"endRotation()",
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
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
	},
    arg1 = {
		{
			name = "input",
			type = "input_statement",
		},
	},
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'ShapeBuilder.beginRotation(%s,%s,%s,%s)\\n%sShapeBuilder.endRotation()',
	ToNPL = function(self)
    return string.format('ShapeBuilder.beginRotation(%s,%s,%s,%s)\n    %s\nShapeBuilder.endRotation()\n', 
            self:getFieldValue('x'), self:getFieldValue('y'), self:getFieldValue('z'), self:getFieldValue('angle'), self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "_ShapeBuilder.beginBoolean", 
	message0 = L"beginBoolean %1 %2",
    message1 = L"%1",
	message2 = L"endBoolean()",
    arg0 = {
        
        {
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"union", "union" },
				{ L"difference", "difference" },
				{ L"intersection", "intersection" },
			},
		},
        {
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
	},
    arg1 = {
		{
			name = "input",
			type = "input_statement",
		},
	},
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
    previousStatement = true,
	nextStatement = true,
	func_description = 'ShapeBuilder.beginBoolean("%s","%s")\\n%sShapeBuilder.endBoolean()',
	ToNPL = function(self)
    return string.format('ShapeBuilder.beginBoolean("%s","%s")\n    %s\nShapeBuilder.endBoolean()\n', 
            self:getFieldValue('value'), self:getFieldValue('color'), self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

}
function BlockCadDef_ShapeOperators.GetCmds()
	return cmds;
end