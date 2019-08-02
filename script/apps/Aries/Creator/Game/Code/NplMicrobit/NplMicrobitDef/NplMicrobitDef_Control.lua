--[[
Title: NplMicrobitDef_Control
Author(s): leio
Date: 2019/7/19
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicrobit/NplMicrobitDef/NplMicrobitDef_Control.lua");
local NplMicrobitDef_Control = commonlib.gettable("MyCompany.Aries.Game.Code.NplMicrobit.NplMicrobitDef_Control");
-------------------------------------------------------
]]
local NplMicrobitDef_Control = commonlib.gettable("MyCompany.Aries.Game.Code.NplMicrobit.NplMicrobitDef_Control");
local cmds = {
{
	type = "rotateBone", 
	message0 = L"舵机 %1 %2 旋转骨骼 %3 %4 %5",
	arg0 = {
        {
			name = "channel",
			type = "field_dropdown",
			options = {
				{ L"S1", "0" },
				{ L"S2", "1" },
				{ L"S3", "2" },
				{ L"S4", "3" },
				{ L"S5", "4" },
				{ L"S6", "5" },
				{ L"S7", "6" },
				{ L"S8", "7" },
			},
		},
        {
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 150,},
			text = 150, 
		},
		{
			name = "name",
			type = "input_value",
            shadow = { type = "text", value = "L_UpperArm",},
			text = "L_UpperArm", 
		},
        
        {
			name = "axis",
			type = "field_dropdown",
			options = {
				{ "x", "'x'" },
				{ "y", "'y'" },
				{ "z", "'z'" },
			},
		},
         {
			name = "duration",
			type = "input_value",
            shadow = { type = "math_number", value = 1000,},
			text = 1000, 
		},
	},
    
	category = "NplMicrobit.Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description_py = 'pwm.set_pwm(%d, 0, %d)',
	ToNPL = function(self)
		return string.format('rotateBone("%s",%s,"%s",%s)\n', 
            self:getFieldAsString('name'), 
            self:getFieldAsString('angle'),
            self:getFieldAsString('axis'), 
            self:getFieldAsString('duration')
            );
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "boneNames", 
	message0 = L"%1",
	arg0 = {
        {
			name = "name",
			type = "field_dropdown",
			options = {
				{ L"头", "'Head'" },
				{ L"脖子", "'Neck'" },
				{ L"左大臂", "'L_UpperArm'" },
				{ L"右大臂", "'R_UpperArm'" },
				{ L"左前臂", "'L_Forearm'" },
				{ L"右前臂", "'R_Forearm'" },
				{ L"左手", "'L_Hand'" },
				{ L"右手", "'R_Hand'" },
				{ L"脊柱", "'Spine'" },
				{ L"骨盆", "'Pelvis'" },
				{ L"左大腿", "'L_Thigh'" },
				{ L"右大腿", "'R_Thigh'" },
				{ L"左小腿", "'L_Calf'" },
				{ L"右小腿", "'R_Calf'" },
                { L"左脚", "'L_Foot'" },
				{ L"右脚", "'R_Foot'" },
			},
		},
	},
    
	category = "NplMicrobit.Control", 
	helpUrl = "", 
	canRun = false,
    output = {type = "null",},
	func_description = '%s',
	ToNPL = function(self)
		return string.format('%s', 
            self:getFieldAsString('name')
            );
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "rotateServo", 
	message0 = L"旋转舵机 %1 %2",
	arg0 = {
        {
			name = "channel",
			type = "field_dropdown",
			options = {
				{ L"S1", "0" },
				{ L"S2", "1" },
				{ L"S3", "2" },
				{ L"S4", "3" },
				{ L"S5", "4" },
				{ L"S6", "5" },
				{ L"S7", "6" },
				{ L"S8", "7" },
			},
		},
        {
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 150,},
			text = 150, 
		},
        
	},
    
	category = "NplMicrobit.Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description_py = 'pwm.set_pwm(%d, 0, %d)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "microbit.sleep", 
	message0 = L"休眠 %1 毫秒",
	arg0 = {
        
        {
			name = "time",
			type = "input_value",
            shadow = { type = "math_number", value = 1000,},
			text = 1000, 
		},
        
	},
    
	category = "NplMicrobit.Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description_py = 'sleep(%d)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "microbit.display.show", 
	message0 = L"显示 %1 %2",
	arg0 = {
        {
			name = "text",
            type = "input_value",
            shadow = { type = "text", value = L"hello!",},
			text = L"hello!", 
		},
         {
			name = "time",
			type = "input_value",
            shadow = { type = "math_number", value = 400,},
			text = 400, 
		},
	},
    
	category = "NplMicrobit.Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description_py = 'display.show(%s,%d)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "microbit.display.scroll", 
	message0 = L"滚动显示 %1 %2",
	arg0 = {
        {
			name = "text",
            type = "input_value",
            shadow = { type = "text", value = L"hello!",},
			text = L"hello!", 
		},
        {
			name = "time",
			type = "input_value",
            shadow = { type = "math_number", value = 400,},
			text = 400, 
		},
	},
    
	category = "NplMicrobit.Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description_py = 'display.scroll(%s,%d)',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "microbit.display.clear", 
	message0 = L"清除显示",
	arg0 = {
	},
    
	category = "NplMicrobit.Control", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description_py = 'display.clear()',
	ToNPL = function(self)
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

};
function NplMicrobitDef_Control.GetCmds()
	return cmds;
end
