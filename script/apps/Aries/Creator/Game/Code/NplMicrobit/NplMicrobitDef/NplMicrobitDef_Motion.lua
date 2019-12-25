--[[
Title: NplMicrobitDef_Motion
Author(s): leio
Date: 2019/11/29
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicrobit/NplMicrobitDef/NplMicrobitDef_Motion.lua");
-------------------------------------------------------
]]
NPL.export({

{
	type = "playRobotAnimation", 
	message0 = L"播放动画%1",
    arg0 = {
        {
			name = "name",
			type = "input_value",
			shadow = { type = "text", value = "",},
			text = "",
		},
    },
	category = "NplMicrobit.Motion", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	func_description = 'playRobotAnimation(%s)',
	ToNPL = function(self)
		return string.format('playRobotAnimation("%s")',self:getFieldAsString('name'))
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "microbit_servo", 
	message0 = L"骨骼%1在%2轴旋转%3 Servo %4 偏移值 %5",
	arg0 = {
        {
			name = "boneName",
			type = "input_value",
            shadow = { type = "text", value = "Root",},
			text = "Root", 
		},
        {
			name = "axis",
			type = "field_dropdown",
			options = {
				{ "X", "x" },
				{ "Y", "y" },
				{ "Z", "z" },
			},
			text = "S1", 
		},
        {
			name = "value",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "name",
			type = "field_dropdown",
			options = {
				{ "S1", "0" },
				{ "S2", "1" },
				{ "S3", "2" },
				{ "S4", "3" },
				{ "S5", "4" },
				{ "S6", "5" },
				{ "S7", "6" },
				{ "S8", "7" },
			},
			text = "S1", 
		},
        {
			name = "offset",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		
	},
	category = "NplMicrobit.Motion", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'microbit_servo(%s, "%s", %s, %s, %s)',
	ToNPL = function(self)
		return string.format('microbit_servo(%s, "%s", %s, %s, %s)\n', self:getFieldAsString('boneName'), self:getFieldAsString('axis'), self:getFieldAsString('value'),  self:getFieldAsString('name'),  self:getFieldAsString('offset'))
	end,
	examples = {{desc = L"", canRun = true, code = [[
]]
}},
},

{
	type = "microbit_sleep", 
	message0 = L"休眠 %1 毫秒",
	arg0 = {
        
        {
			name = "time",
			type = "input_value",
            shadow = { type = "math_number", value = 1000,},
			text = 1000, 
		},
        
	},
    
	category = "NplMicrobit.Motion", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'microbit_sleep(%d)',
	ToNPL = function(self)
		return string.format("microbit_sleep(%s)\n", self:getFieldAsString('time'))
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

})