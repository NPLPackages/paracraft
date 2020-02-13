--[[
Title: NplCadDef_Skeleton
Author(s): leio
Date: 2019/5/24
Desc: a set of commands to bind joints and meshes
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadDef/NplCadDef_Skeleton.lua");
local NplCadDef_Skeleton = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Skeleton");
-------------------------------------------------------
]]
local NplCadDef_Skeleton = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Skeleton");
local cmds = {
{
	type = "createJointRoot", 
	message0 = L"骨骼根节点 %1",
    arg0 = {
        {
			name = "is_enabled",
			type = "field_dropdown",
			options = {
				{ L"有效", "true" },
				{ L"无效", "false" },
			},
		},
	},
	category = "Skeleton", 
	helpUrl = "", 
	canRun = false,
	nextStatement = true,
	funcName = "createJointRoot",
	func_description = 'createJointRoot(nil,%s)',
	func_description_js = 'createJointRoot(null,%s)',
	ToNPL = function(self)
		return string.format('createJointRoot(nil,%s)\n',  self:getFieldValue('is_enabled')
        );
	end,
	examples = {{desc = "", canRun = true, code = [[
createJointRoot()
    ]]}},
},

{
	type = "createJoint", 
	message0 = L"骨骼 %1 %2 %3 %4",
    message1 = L"%1",
    arg0 = {
        {
			name = "name",
			type = "input_value",
			shadow = { type = "text", value = "",},
			text = "",
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
    arg1 = {
		{
			name = "input",
			type = "input_statement",
		},
	},
	category = "Skeleton", 
    colour = "#4d4d4d",
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "createJoint",
	func_description = 'createJoint(%s,%s,%s,%s)\\n%sendJoint()',
	func_description_js = 'createJoint(%s,%s,%s,%s)\\n%sendJoint()',
	ToNPL = function(self)
		return string.format('createJoint("%s",%s,%s,%s)\n    %s\nendJoint()\n', 
            self:getFieldValue('name'),
            self:getFieldValue('x'),
            self:getFieldValue('y'),
            self:getFieldValue('z'),
            self:getFieldAsString('input')
        );
	end,
	examples = {{desc = "", canRun = true, code = [[
createJoint("body",0,0,0)
  bindNodeByName("object1")
endJoint()
    ]]}},
},

{
	type = "bindNodeByName", 
	message0 = L"绑定对象 %1",
    arg0 = {
       {
			name = "name",
			type = "input_value",
			text = "", 
		},
	},
	category = "Skeleton", 
	helpUrl = "", 
	canRun = false,
    previousStatement = true,
	nextStatement = true,
	funcName = "bindNodeByName",
	func_description = 'bindNodeByName(%s)',
	func_description_js = 'bindNodeByName(%s)',
	ToNPL = function(self)
        return string.format('bindNodeByName("%s")\n', 
            self:getFieldValue('name'));
	end,
	examples = {{desc = "", canRun = true, code = [[
bindNodeByName("object1")
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
    
	category = "Skeleton", 
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

{
	type = "rotateJoint", 
	message0 = L"旋转 %1 %2 度",
    arg0 = {
        {
			name = "axis",
			type = "input_value",
            shadow = { type = "axis", value = "x",},
			text = "'x'", 
		},
        {
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
	},
	category = "Skeleton", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "rotateJoint",
	func_description = 'rotateJoint(%s,%s)',
	func_description_js = 'rotateJoint(%s,%s)',
	ToNPL = function(self)
        return string.format('rotateJoint(%s,%s)\n', 
            self:getFieldValue('axis'),self:getFieldValue('angle'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},


{
	type = "startBoneNameConstraint", 
	message0 = L"约束骨骼属性",
    message1 = L"%1",
    arg1 = {
		{
			name = "input",
			type = "input_statement",
		},
	},
	category = "Skeleton", 
	helpUrl = "", 
	canRun = false,
	nextStatement = true,
	funcName = "startBoneNameConstraint",
	func_description = 'startBoneNameConstraint()\\n%sendBoneNameConstraint()',
	ToNPL = function(self)
		return string.format('startBoneNameConstraint()\n    %s\nendBoneNameConstraint()\n', 
            self:getFieldAsString('input')
        );
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "setBoneConstraint_Name", 
	message0 = L"骨骼名称 %1",
	arg0 = {
		 {
			name = "name",
			type = "input_value",
			shadow = { type = "text", value = "",},
			text = "",
		},
	},
	category = "Skeleton", 
    colour = "#4d4d4d",
	helpUrl = "", 
	canRun = false,
    previousStatement = true,
	nextStatement = true,
	func_description = 'setBoneConstraint_Name(%s)',
	ToNPL = function(self)
		return string.format('setBoneConstraint_Name("%s")', self:getFieldAsString('name'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "setBoneConstraint_min", 
	message0 = L"%1%2",
	arg0 = {
		{
			name = "name",
			type = "field_dropdown",
			options = {
				{ L"最小角度", "min" },
			},
		},
		{
			name = "value",
			type = "input_value",
            shadow = { type = "math_number", value = -90,},
			text = -90,
		},
	},
	category = "Skeleton", 
    colour = "#4d4d4d",
	helpUrl = "", 
	canRun = false,
    previousStatement = true,
	nextStatement = true,
	func_description = 'setBoneConstraint("%s",%s)',
	ToNPL = function(self)
		return string.format('setBoneConstraint("%s",%s)', self:getFieldAsString('name'), self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "setBoneConstraint_max", 
	message0 = L"%1%2",
	arg0 = {
		{
			name = "name",
			type = "field_dropdown",
			options = {
				{ L"最大角度", "max" },
			},
		},
		{
			name = "value",
			type = "input_value",
            shadow = { type = "math_number", value = 90,},
			text = 90,
		},
	},
	category = "Skeleton", 
    colour = "#4d4d4d",
	helpUrl = "", 
	canRun = false,
    previousStatement = true,
	nextStatement = true,
	func_description = 'setBoneConstraint("%s",%s)',
	ToNPL = function(self)
		return string.format('setBoneConstraint("%s",%s)', self:getFieldAsString('name'), self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "setBoneConstraint_offset", 
	message0 = L"%1%2",
	arg0 = {
		{
			name = "name",
			type = "field_dropdown",
			options = {
				{ L"偏移角度", "servoOffset" },
			},
		},
		{
			name = "value",
			type = "input_value",
            shadow = { type = "math_number", value = 90,},
			text = 90,
		},
	},
	category = "Skeleton", 
    colour = "#4d4d4d",
	helpUrl = "", 
	canRun = false,
    previousStatement = true,
	nextStatement = true,
	func_description = 'setBoneConstraint("%s",%s)',
	ToNPL = function(self)
		return string.format('setBoneConstraint("%s",%s)', self:getFieldAsString('name'), self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},
{
	type = "setBoneConstraint_2", 
	message0 = L"%1%2",
	arg0 = {
		{
			name = "name",
			type = "field_dropdown",
			options = {
				{ L"舵机通道", "servoId" },
			},
		},
		{
			name = "value",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0,
		},
	},
	category = "Skeleton", 
    colour = "#4d4d4d",
	helpUrl = "", 
	canRun = false,
    previousStatement = true,
	nextStatement = true,
	func_description = 'setBoneConstraint("%s",%s)',
	ToNPL = function(self)
		return string.format('setBoneConstraint("%s",%s)', self:getFieldAsString('name'), self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "setBoneConstraint_3", 
	message0 = L"%1%2",
	arg0 = {
		{
			name = "name",
			type = "field_dropdown",
			options = {
				{ L"舵机缩放值", "servoScale" },
			},
		},
		{
			name = "value",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1,
		},
	},
	category = "Skeleton", 
    colour = "#4d4d4d",
	helpUrl = "", 
	canRun = false,
    previousStatement = true,
	nextStatement = true,
	func_description = 'setBoneConstraint("%s",%s)',
	ToNPL = function(self)
		return string.format('setBoneConstraint("%s",%s)', self:getFieldAsString('name'), self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "setBoneConstraint_4", 
	message0 = L"%1%2",
	arg0 = {
		{
			name = "name",
			type = "field_dropdown",
			options = {
				{ L"旋转轴", "rotAxis" },
			},
		},
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"x", "x" },
				{ L"y", "y" },
				{ L"z", "z" },
			},
		},
	},
	category = "Skeleton", 
    colour = "#4d4d4d",
	helpUrl = "", 
	canRun = false,
    previousStatement = true,
	nextStatement = true,
	func_description = 'setBoneConstraint("%s","%s")',
	ToNPL = function(self)
		return string.format('setBoneConstraint("%s","%s")', self:getFieldAsString('name'), self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "setBoneConstraint_5", 
	message0 = L"%1%2",
	arg0 = {
		{
			name = "name",
			type = "field_dropdown",
			options = {
				{ L"隐藏骨骼", "hidden" },
			},
		},
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"false", "false" },
				{ L"true", "true" },
			},
		},
	},
	category = "Skeleton", 
    colour = "#4d4d4d",
	helpUrl = "", 
	canRun = false,
    previousStatement = true,
	nextStatement = true,
	func_description = 'setBoneConstraint("%s",%s)',
	ToNPL = function(self)
		return string.format('setBoneConstraint("%s",%s)', self:getFieldAsString('name'), self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "setBoneConstraint_6", 
	message0 = L"%1%2",
	arg0 = {
		{
			name = "name",
			type = "field_dropdown",
			options = {
				{ L"IK", "IK" },
			},
		},
		{
			name = "value",
			type = "input_value",
            shadow = { type = "math_number", value = 2,},
			text = 2,
		},
	},
	category = "Skeleton", 
    colour = "#4d4d4d",
	helpUrl = "", 
	canRun = false,
    previousStatement = true,
	nextStatement = true,
	func_description = 'setBoneConstraint("%s",%s)',
	ToNPL = function(self)
		return string.format('setBoneConstraint("%s",%s)', self:getFieldAsString('name'), self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

};
function NplCadDef_Skeleton.GetCmds()
	return cmds;
end
