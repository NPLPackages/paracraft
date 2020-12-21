--[[
Title: NplMicroRobotDef_Control
Author(s): leio
Date: 2019/7/19
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicroRobot/NplMicroRobotDef/NplMicroRobotDef_Control.lua");
-------------------------------------------------------
]]
local CommonDef = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CommonDefs/CommonDef.lua");

NPL.export({
{
	type = "microbit_pause", 
	message0 = L"等待 %1 毫秒",
	arg0 = {
        {
			name = "text",
            type = "input_value",
            shadow = { type = "math_number", value = 1000,},
			text = 1000, 
		},
	},
    
	category = "NplMicroRobot.Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'microbit_pause(%s)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


    CommonDef.GetCmd("forever", true, "NplMicroRobot.Control"),
    CommonDef.GetCmd("repeat_count", true, "NplMicroRobot.Control"),
    CommonDef.GetCmd("control_if", true, "NplMicroRobot.Control"),
    CommonDef.GetCmd("if_else", true, "NplMicroRobot.Control"),

})
