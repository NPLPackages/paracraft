--[[
Title: NplCadDef_Animation
Author(s): leio
Date: 2019/8/2
Desc: a set of commands to animate joints
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadDef/NplCadDef_Animation.lua");
local NplCadDef_Animation = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Animation");
-------------------------------------------------------
]]
local NplCadDef_Animation = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Animation");
local cmds = {
{
	type = "createAnimation", 
	message0 = L"骨骼动画 %1 %2",
    arg0 = {
        {
			name = "name",
			type = "input_value",
			shadow = { type = "text", value = "anim",},
			text = "",
		},
         {
			name = "is_enabled",
			type = "field_dropdown",
			options = {
				{ L"有效", "true" },
				{ L"无效", "false" },
			},
		},
    },
	category = "Animation", 
	helpUrl = "", 
	canRun = false,
	nextStatement = true,
	funcName = "createAnimation",
	func_description = 'createAnimation(%s,%s)',
	func_description_js = 'createAnimation(%s,%s)',
	ToNPL = function(self)
		return string.format('createAnimation("%s",%s)\n',  self:getFieldValue('name'),  self:getFieldValue('is_enabled'))
	end,
	examples = {{desc = "", canRun = true, code = [[
createAnimation("anim")
    ]]}},
},

{
	type = "addChannel", 
	message0 = L"动画通道 %1 %2",
    message1 = L"%1",
    arg0 = {
        {
			name = "name",
			type = "input_value",
			shadow = { type = "text", value = "",},
			text = "",
		},
        {
			name = "type",
			type = "field_dropdown",
			options = {
				{ L"线性", "'linear'" }, 
				{ L"步", "'step'" },
			},
	    },
	},
    arg1 = {
		{
			name = "input",
			type = "input_statement",
		},
	},
	category = "Animation", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "addChannel",
	func_description = 'addChannel(%s,%s)\\n%sendChannel()',
	func_description_js = 'addChannel(%s,%s)\\n%sendChannel()',
	ToNPL = function(self)
		return ""
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "setAnimationTimeValue_Translate", 
	message0 = L"时间 %1 移动 %2 %3 %4",
    arg0 = {
        {
			name = "time",
			type = "input_value",
			shadow = { type = "math_number", value = 0,},
			text = 0,
		},
        {
			name = "x",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "y",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "z",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        
	},
	category = "Animation", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "setAnimationTimeValue_Translate",
	func_description = 'setAnimationTimeValue_Translate(%s,%s,%s,%s)',
	func_description_js = 'setAnimationTimeValue_Translate(%s,%s,%s,%s)',
	ToNPL = function(self)
        return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "setAnimationTimeValue_Scale", 
	message0 = L"时间 %1 缩放 %2 %3 %4",
    arg0 = {
        {
			name = "time",
			type = "input_value",
			shadow = { type = "math_number", value = 0,},
			text = 0,
		},
        {
			name = "x",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "y",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "z",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        
	},
	category = "Animation", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "setAnimationTimeValue_Scale",
	func_description = 'setAnimationTimeValue_Scale(%s,%s,%s,%s)',
	func_description_js = 'setAnimationTimeValue_Scale(%s,%s,%s,%s)',
	ToNPL = function(self)
        return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "setAnimationTimeValue_Rotate", 
	message0 = L"时间 %1 旋转 %2 %3 度",
    arg0 = {
        {
			name = "time",
			type = "input_value",
			shadow = { type = "math_number", value = "0",},
			text = "0",
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
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        
	},
	category = "Animation", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "setAnimationTimeValue_Rotate",
	func_description = 'setAnimationTimeValue_Rotate(%s,%s,%s)',
	func_description_js = 'setAnimationTimeValue_Rotate(%s,%s,%s)',
	ToNPL = function(self)
        return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "setAnimationTimeValue_rotateFromPivot", 
	message0 = L"时间 %1 旋转 %2 %3 度 中心点 %4 %5 %6",
    arg0 = {
        {
			name = "time",
			type = "input_value",
			shadow = { type = "math_number", value = 0,},
			text = 0,
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
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "tx",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "ty",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "tz",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        
	},
	hide_in_toolbox = true,
	category = "Animation", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "setAnimationTimeValue_rotateFromPivot",
	func_description = 'setAnimationTimeValue_rotateFromPivot(%s,%s,%s,%s,%s,%s)',
	func_description_js = 'setAnimationTimeValue_rotateFromPivot(%s,%s,%s,%s,%s,%s)',
	ToNPL = function(self)
        return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},
{
	type = "animationiNames", 
	message0 = L"%1",
	arg0 = {
        {
			name = "name",
			type = "field_dropdown",
			options = {
				{ L"待机", "'ParaAnimation_0'" },
				{ L"倒下", "'ParaAnimation_1'" },
				{ L"走路", "'ParaAnimation_4'" },
				{ L"跑步", "'ParaAnimation_5'" },
			},
		},
	},
    
	category = "Animation", 
	helpUrl = "", 
	canRun = false,
    output = {type = "null",},
	func_description = '%s',
	func_description_js = '%s',
	ToNPL = function(self)
		return string.format('%s', 
            self:getFieldAsString('name')
            );
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},
};
function NplCadDef_Animation.GetCmds()
	return cmds;
end
