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
	func_description = 'beginTranslation(%s,%s,%s)\\n%sendTranslation()',
	ToNPL = function(self)
		return string.format('beginTranslation(%s,%s,%s)\n    %s\nendTranslation()\n', 
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
	func_description = 'beginScale(%s,%s,%s)\\n%sendScale()',
	ToNPL = function(self)
    return string.format('beginScale(%s,%s,%s)\n    %s\nendScale()\n', 
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
	func_description = 'beginRotation(%s,%s,%s,%s)\\n%sendRotation()',
	ToNPL = function(self)
    return string.format('beginRotation(%s,%s,%s,%s)\n    %s\nendRotation()\n', 
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
	func_description = 'beginBoolean("%s","%s")\\n%sendBoolean()',
	ToNPL = function(self)
    return string.format('beginBoolean("%s","%s")\n    %s\nendBoolean()\n', 
            self:getFieldValue('value'), self:getFieldValue('color'), self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

}
function BlockCadDef_ShapeOperators.GetCmds()
	return cmds;
end