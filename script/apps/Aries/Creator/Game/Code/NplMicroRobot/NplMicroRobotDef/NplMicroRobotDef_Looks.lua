--[[
Title: NplMicroRobotDef_Looks
Author(s): leio
Date: 2019/11/29
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicroRobot/NplMicroRobotDef/NplMicroRobotDef_Looks.lua");
-------------------------------------------------------
]]
NPL.export({

{
	type = "microbit_show_leds", 
	message0 = L"显示 %1",
	arg0 = {
        {
			name = "text",
            type = "field_matrix",
		},
	},
	category = "NplMicroRobot.Looks", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'microbit_show_leds("%s")',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "microbit_show_string", 
	message0 = L"显示字符串 %1",
	arg0 = {
        {
			name = "text",
            type = "input_value",
            shadow = { type = "text", value = L"hello",},
			text = L"hello", 
		},
	},
    
	category = "NplMicroRobot.Looks", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'microbit_show_string(%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "microbit_show_number", 
	message0 = L"显示数字 %1",
	arg0 = {
        {
			name = "text",
            type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
	},
    
	category = "NplMicroRobot.Looks", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'microbit_show_number(%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "microbit_clear_screen", 
	message0 = L"清除",
	category = "NplMicroRobot.Looks", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'microbit_clear_screen()',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},



})