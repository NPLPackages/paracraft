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
    ]]}},
},

{
	type = "createJoint", 
	message0 = L"骨骼 %1 %2 %3 %4",
    message1 = L"%1",
    arg0 = {
        {
			name = "name",
			type = "field_input",
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
	func_description = 'createJoint("%s",%s,%s,%s)\\n%s',
	ToNPL = function(self)
		return string.format('createJoint("%s",%s,%s,%s)\n    %s\n', 
            self:getFieldValue('name'),
            self:getFieldValue('x'),
            self:getFieldValue('y'),
            self:getFieldValue('z'),
            self:getFieldAsString('input')
        );
	end,
	examples = {{desc = "", canRun = true, code = [[
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
    colour = "#1567a9",
	canRun = false,
    previousStatement = true,
	nextStatement = true,
	func_description = 'bindNodeByName(%s)',
	ToNPL = function(self)
        return string.format('bindNodeByName("%s")\n', 
            self:getFieldValue('name'));
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

};
function NplCadDef_Skeleton.GetCmds()
	return cmds;
end
