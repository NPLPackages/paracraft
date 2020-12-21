--[[
Title: NplMicroRobotDef_Sensing
Author(s): leio
Date: 2019/12/2
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicroRobot/NplMicroRobotDef/NplMicroRobotDef_Sensing.lua");
-------------------------------------------------------
]]
NPL.export({

{
	type = "microbit_is_pressed", 
	message0 = L"%1键按下",
	arg0 = {
		{
			name = "input",
			type = "field_dropdown",
			options = {
				{ L"A", "A" },
				{ L"B", "B" },
				{ L"AB", "AB" },
			},
			text = "A", 
		},
	},
	output = {type = "null",},
	category = "NplMicroRobot.Sensing", 
	helpUrl = "", 
	canRun = false,
	func_description = 'microbit_is_pressed("%s")',
	ToNPL = function(self)
		return string.format('microbit_is_pressed("%s")\n', self:getFieldAsString('input'))
	end,
	examples = {{desc = "", canRun = true, code = [[

]]}},
},

{
	type = "CrocoKit_Sensor_GetRGBValue", 
	message0 = L"颜色传感器返回%1",
	arg0 = {
		{
			name = "input",
			type = "field_dropdown",
			options = {
				{ L"R值", "GetValueR" },
				{ L"G值", "GetValueG" },
				{ L"B值", "GetValueB" },
			},
			text = "R值", 
		},
	},
	output = {type = "null",},
	category = "NplMicroRobot.Sensing", 
	helpUrl = "", 
	canRun = false,
	func_description = 'CrocoKit_Sensor.GetRGBValue(CrocoKit_Sensor.enGetRGB.%s)',
	ToNPL = function(self)
		return ""
	end,
	examples = {{desc = "", canRun = true, code = [[

]]}},
},


})