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


})