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
	message0 = L"骨骼根节点",
	category = "Skeleton", 
	helpUrl = "", 
	canRun = false,
	nextStatement = true,
	func_description = 'createJointRoot()',
	ToNPL = function(self)
		return string.format('createJointRoot()\n'
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
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'createJoint(%s,%s,%s,%s)\\n%sendJoint()',
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
	func_description = 'bindNodeByName(%s)',
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
	ToNPL = function(self)
		return string.format('%s', 
            self:getFieldAsString('name')
            );
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

};
function NplCadDef_Skeleton.GetCmds()
	return cmds;
end
