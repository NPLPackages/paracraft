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
	type = "ShapeBuilder.createShape", 
	message0 = L"createShape %1",
    arg0 = {
		{
			name = "node",
			type = "input_value",
		},
        
	},
	category = "ShapeOperators", 
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
	type = "ShapeBuilder.setTranslation", 
	message0 = L"setTranslation(%1,%2,%3,%4)",
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
	category = "ShapeOperators", 
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
	type = "ShapeBuilder.translate", 
	message0 = L"translate(%1,%2,%3,%4)",
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
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'ShapeBuilder.translate(%s,%s,%s,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "ShapeBuilder.scale", 
	message0 = L"scale(%1,%2,%3,%4)",
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
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'ShapeBuilder.scale(%s,%s,%s,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "ShapeBuilder.beginTranslation", 
	message0 = L"beginTranslation(%1,%2,%3)",
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
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},


{
	type = "ShapeBuilder.beginScale", 
	message0 = L"beginScale(%1,%2,%3)",
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
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "ShapeBuilder.setColor", 
	message0 = L"color %1 %2",
    arg0 = {
        {
			name = "node",
			type = "input_value",
		},
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffffff",},
			text = "#ffffff", 
		},
        
	},
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
    previousStatement = true,
	nextStatement = true,
	func_description = 'ShapeBuilder.setColor(%s,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "ShapeBuilder.boolean", 
	message0 = L"boolean %1 %2 %3 %4",
    arg0 = {
        {
			name = "node_1",
			type = "input_value",
		},
        {
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"union", "union" },
				{ L"difference", "difference" },
				{ L"intersection", "intersection" },
				--{ L"section", "section" }, -- runtime error
			},
		},
        {
			name = "node_2",
			type = "input_value",
		},
        
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ffffff",},
			text = "#ffffff", 
		},
        
	},
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
    previousStatement = true,
	nextStatement = true,
	func_description = 'ShapeBuilder.boolean(%s,"%s",%s,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "ShapeBuilder.mirror", 
	message0 = L"mirror shape %1 x %2 y %3 z %4 dir_x %5 dir_y %6 dir_z %7 color %8",
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
        {
			name = "dir_x",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "dir_y",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "dir_z",
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
	category = "ShapeOperators", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'ShapeBuilder.mirror(%s,%s,%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},


}
function BlockCadDef_ShapeOperators.GetCmds()
	return cmds;
end