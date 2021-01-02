--[[
Title: NplMicroRobotDef_Servo
Author(s): leio
Date: 2020/12/15
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicroRobot/NplMicroRobotDef/NplMicroRobotDef_Servo.lua");
-------------------------------------------------------
]]
NPL.export({

{
	type = "ServoPulse", 
	message0 = L"设置舵机 %1 脉宽 %2",
    arg0 = {
        {
			name = "channel",
            type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "value",
            type = "input_value",
            shadow = { type = "math_number", value = 1500,},
			text = 1500, 
		},
	},
    previousStatement = true,
	nextStatement = true,
	category = "NplMicroRobot.Servo", 
	helpUrl = "", 
	canRun = false,
	funcName = "NplMicroRobot.ServoPulse",
	func_description = 'NplMicroRobot.ServoPulse(%s,%s)',
	ToNPL = function(self)
		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "Servo", 
	message0 = L"设置舵机 %1 角度 %2",
    arg0 = {
        {
			name = "channel",
            type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "value",
            type = "input_value",
            shadow = { type = "math_number", value = 90,},
			text = 90, 
		},
	},
    previousStatement = true,
	nextStatement = true,
	category = "NplMicroRobot.Servo", 
	helpUrl = "", 
	canRun = false,
	funcName = "NplMicroRobot.Servo",
	func_description = 'NplMicroRobot.Servo(%s,%s)',
	ToNPL = function(self)
		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},


})