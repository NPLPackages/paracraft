--[[
Title: CodeBlocklyDef_Microbit
Author(s): leio
Date: 2018/9/10
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/CodeBlocklyDef_Microbit.lua");
local CodeBlocklyDef_Microbit = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Microbit");
-------------------------------------------------------
]]
local CodeBlocklyDef_Microbit = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Microbit");
local cmds = {
{
	type = "robotRotateLeftArm", 
	message0 = L"旋转左臂 %1 度",
	arg0 = {
		{
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        
	},
    
	category = "Microbit", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'robotRotateLeftArm(%d)',
	func_description_js = 'SuperBit.Servo2(SuperBit.enServo.S1, %s)',
	ToNPL = function(self)
		return string.format('robotRotateLeftArm(%s)\n', self:getFieldAsString('angle'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "robotRotateRightArm", 
	message0 = L"旋转右臂 %1 度",
	arg0 = {
		{
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        
	},
    
	category = "Microbit", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'robotRotateRightArm(%d)',
	func_description_js = 'SuperBit.Servo2(SuperBit.enServo.S2, %s)',
	ToNPL = function(self)
		return string.format('robotRotateRightArm(%s)\n', self:getFieldAsString('angle'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "robotRotateLeftLeg", 
	message0 = L"旋转左腿 %1 度",
	arg0 = {
		{
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        
	},
    
	category = "Microbit", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'robotRotateLeftLeg(%d)',
	func_description_js = 'SuperBit.Servo2(SuperBit.enServo.S3, %s)',
	ToNPL = function(self)
		return string.format('robotRotateLeftLeg(%s)\n', self:getFieldAsString('angle'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "robotRotateRightLeg", 
	message0 = L"旋转右腿 %1 度",
	arg0 = {
		{
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        
	},
    
	category = "Microbit", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'robotRotateRightLeg(%d)',
	func_description_js = 'SuperBit.Servo2(SuperBit.enServo.S4, %s)',
	ToNPL = function(self)
		return string.format('robotRotateRightLeg(%s)\n', self:getFieldAsString('angle'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "robotRotateBody", 
	message0 = L"旋转身体 %1 度",
	arg0 = {
		{
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        
	},
    
	category = "Microbit", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'robotRotateBody(%d)',
	func_description_js = 'SuperBit.Servo2(SuperBit.enServo.S5, %s)',
	ToNPL = function(self)
		return string.format('robotRotateBody(%s)\n', self:getFieldAsString('angle'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


};
function CodeBlocklyDef_Microbit.GetCmds()
	return cmds;
end
