--[[
Title: NplMicrobitDef_Animation
Author(s): leio
Date: 2019/12/6
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicrobit/NplMicrobitDef/NplMicrobitDef_Animation.lua");
-------------------------------------------------------
]]
NPL.export({

{
	type = "createRobotAnimation", 
	message0 = L"创建动画%1",
    arg0 = {
        {
			name = "name",
			type = "input_value",
			shadow = { type = "text", value = "",},
			text = "",
		},
    },
	category = "NplMicrobit.Animation", 
	helpUrl = "", 
	canRun = false,
	nextStatement = true,
	func_description = 'createRobotAnimation(%s)',
	ToNPL = function(self)
		return string.format('createRobotAnimation("%s")',self:getFieldAsString('name'))
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},



{
	type = "addRobotAnimationChannel", 
	message0 = L"骨骼动画%1在%2servo%3",
    arg0 = {
        {
			name = "boneName",
			type = "input_value",
			shadow = { type = "text", value = "",},
			text = "",
		},
        {
			name = "axis",
			type = "field_dropdown",
			options = {
				{ L"x轴", "'x'" },
				{ L"y轴", "'y'" },
				{ L"z轴", "'z'" },
			},
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
	},
	category = "NplMicrobit.Animation", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'addRobotAnimationChannel(%s,%s,%s)',
	ToNPL = function(self)
		return string.format('addRobotAnimationChannel("%s",%s)\n',
             self:getFieldAsString('boneName'), 
             self:getFieldAsString('axis'), 
             self:getFieldAsString('name'), 
             self:getFieldAsString('input')
         )
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "addAnimationTimeValue_Rotation", 
	message0 = L"时间 %1 旋转 %2 度",
    arg0 = {
        {
			name = "time",
			type = "input_value",
			shadow = { type = "math_number", value = "0",},
			text = "0",
		},
        
        {
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        
	},
	category = "NplMicrobit.Animation", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "addAnimationTimeValue_Rotation",
	func_description = 'addAnimationTimeValue_Rotation(%s,%s)',
	ToNPL = function(self)
        return string.format('addAnimationTimeValue_Rotation(%s,%s)\n',
             self:getFieldAsString('time'), 
             self:getFieldAsString('angle')
         )
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
				{ L"头Head", "'Head'" },
				{ L"脖子Neck", "'Neck'" },
				{ L"左大臂L_UpperArm", "'L_UpperArm'" },
				{ L"右大臂R_UpperArm", "'R_UpperArm'" },
				{ L"左前臂L_Forearm", "'L_Forearm'" },
				{ L"右前臂R_Forearm", "'R_Forearm'" },
				{ L"左手L_Hand", "'L_Hand'" },
				{ L"右手R_Hand", "'R_Hand'" },
				{ L"脊柱Spine", "'Spine'" },
				{ L"骨盆Pelvis", "'Pelvis'" },
				{ L"左大腿L_Thigh", "'L_Thigh'" },
				{ L"右大腿R_Thigh", "'R_Thigh'" },
				{ L"左小腿L_Calf", "'L_Calf'" },
				{ L"右小腿R_Calf", "'R_Calf'" },
                { L"左脚L_Foot", "'L_Foot'" },
				{ L"右脚R_Foot", "'R_Foot'" },
			},
		},
	},
    
	category = "NplMicrobit.Animation", 
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

})