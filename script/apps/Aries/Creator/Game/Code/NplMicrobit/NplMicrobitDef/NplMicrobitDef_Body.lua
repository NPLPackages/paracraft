--[[
Title: NplMicrobitDef_Body
Author(s): leio
Date: 2018/9/10
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicrobit/NplMicrobitDef/NplMicrobitDef_Body.lua");
local NplMicrobitDef_Body = commonlib.gettable("MyCompany.Aries.Game.Code.NplMicrobit.NplMicrobitDef_Body");
-------------------------------------------------------
]]
local NplMicrobitDef_Body = commonlib.gettable("MyCompany.Aries.Game.Code.NplMicrobit.NplMicrobitDef_Body");
local cmds = {
{
	type = "rotate_left_arm", 
	message0 = L"旋转左臂 %1 度",
	arg0 = {
		{
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        
	},
    
	category = "Body", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'SuperBit.Servo2(SuperBit.enServo.S1, %s)',
	ToNPL = function(self)
        
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "rotate_right_arm", 
	message0 = L"旋转右臂 %1 度",
	arg0 = {
		{
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        
	},
    
	category = "Body", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'SuperBit.Servo2(SuperBit.enServo.S2, %s)',
	ToNPL = function(self)
        
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "rotate_left_leg", 
	message0 = L"旋转左腿 %1 度",
	arg0 = {
		{
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        
	},
    
	category = "Body", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'SuperBit.Servo2(SuperBit.enServo.S3, %s)',
	ToNPL = function(self)
        
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "rotate_right_leg", 
	message0 = L"旋转右腿 %1 度",
	arg0 = {
		{
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        
	},
    
	category = "Body", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'SuperBit.Servo2(SuperBit.enServo.S4, %s)',
	ToNPL = function(self)
        
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "rotate_body", 
	message0 = L"旋转身体 %1 度",
	arg0 = {
		{
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        
	},
    
	category = "Body", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'SuperBit.Servo2(SuperBit.enServo.S5, %s)',
	ToNPL = function(self)
        
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


};
function NplMicrobitDef_Body.GetCmds()
	return cmds;
end
