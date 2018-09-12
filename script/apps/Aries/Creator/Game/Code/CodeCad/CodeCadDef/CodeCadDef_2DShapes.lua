--[[
Title: CodeCadDef_2DShapes
Author(s): leio
Date: 2018/9/10
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCad/CodeCadDef/CodeCadDef_2DShapes.lua");
local CodeCadDef_2DShapes = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_2DShapes");
-------------------------------------------------------
]]
local CodeCadDef_2DShapes = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_2DShapes");
local cmds = {
{
	type = "circle", 
	message0 = L"circle    r %1",
	arg0 = {
		{
			name = "r",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
         
	},
	category = "2DShapes", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'circle({r=%d, center=true})',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "ellipse", 
	message0 = L"ellipse    r1 %1 r2 %2",
	arg0 = {
		{
			name = "r1",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "r2",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
			text = 2, 
		},
        
	},
	category = "2DShapes", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'ellipse({r={%d,%d}})',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "rectangle", 
	message0 = L"rectangle    width %1 height %2",
	arg0 = {
		{
			name = "width",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "height",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
			text = 2, 
		},
        
	},
	category = "2DShapes", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'rectangle({r={%d,%d}})',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "roundedRectangle", 
	message0 = L"roundedRectangle    width %1 height %2 roundradius %3 resolution %4",
	arg0 = {
		{
			name = "width",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "height",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
			text = 2, 
		},
        {
			name = "roundradius",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "resolution",
			type = "input_value",
            shadow = { type = "math_number", value = 32,},
			text = 32, 
		},
	},
	category = "2DShapes", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'roundedRectangle({r={%d,%d}, roundradius=%d, resolution=%d})',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

};
function CodeCadDef_2DShapes.GetCmds()
	return cmds;
end
