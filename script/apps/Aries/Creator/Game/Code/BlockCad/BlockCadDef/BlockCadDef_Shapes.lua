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
	type = "NPL.load", 
	message0 = L"NPL.load(%1)",
    arg0 = {
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"ShapeBuilder", 'local ShapeBuilder = NPL.load("Mod/NplOceScript/Blocks/ShapeBuilder.lua");' },
			},
		},
	},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '%s',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "ShapeBuilder.createShape", 
	message0 = L"ShapeBuilder.createShape(%1)",
    arg0 = {
		{
			name = "node",
			type = "input_value",
		},
        
	},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'ShapeBuilder.createShape(%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "ShapeBuilder.cube", 
	message0 = L"ShapeBuilder.cube(%1)",
    arg0 = {
		{
			name = "c",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffffff",},
			text = "#ffffff", 
		},
        
	},
    output = {type = "null",},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'ShapeBuilder.cube(nil,nil,nil,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "ShapeBuilder.cylinder", 
	message0 = L"ShapeBuilder.cylinder(%1)",
    arg0 = {
		{
			name = "c",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffffff",},
			text = "#ffffff", 
		},
        
	},
    output = {type = "null",},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'ShapeBuilder.cylinder(nil,nil,nil,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "ShapeBuilder.sphere", 
	message0 = L"ShapeBuilder.sphere(%1)",
    arg0 = {
		{
			name = "c",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffffff",},
			text = "#ffffff", 
		},
        
	},
    output = {type = "null",},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'ShapeBuilder.sphere(nil,nil,nil,nil,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "ShapeBuilder.cone", 
	message0 = L"ShapeBuilder.cone(%1)",
    arg0 = {
		{
			name = "c",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffffff",},
			text = "#ffffff", 
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
	message0 = L"ShapeBuilder.torus(%1)",
    arg0 = {
		{
			name = "c",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffffff",},
			text = "#ffffff", 
		},
        
	},
    output = {type = "null",},
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	func_description = 'ShapeBuilder.torus(nil,nil,nil,nil,nil,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "ShapeBuilder.setTranslation", 
	message0 = L"ShapeBuilder.setTranslation(%1,%2,%3,%4)",
    arg0 = {
		{
			name = "node",
			type = "input_value",
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
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'ShapeBuilder.setTranslation(%s,%s,%s,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "ShapeBuilder.beginTranslation", 
	message0 = L"ShapeBuilder.beginTranslation(%1,%2,%3)",
    message1 = L"%1",
	message2 = L"ShapeBuilder.endTranslation()",
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
	category = "Shapes", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'ShapeBuilder.beginTranslation(%s,%s,%s)\\n%sShapeBuilder.endTranslation()',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
}
function BlockCadDef_Shapes.GetCmds()
	return cmds;
end