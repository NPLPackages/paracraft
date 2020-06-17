--[[
Title: Teacher Block 
Author(s): chenjinxian
Date: 2020/6/1
Desc: 
use the lib:
-------------------------------------------------------
-------------------------------------------------------
]]
NPL.export({
-----------------------
{
	type = "BecomeTeacherNPC", 
	message0 = "创建教师NPC %1",
	arg0 = {
		{
			name = "npcType",
			type = "field_dropdown",
			options = {
				{ "编程", "program" },
				{ "动画", "animation" },
				{ "CAD", "CAD" },
				{ "机器人", "robot" },
			},
			text = "编程",
		},
	},
	category = "npc", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'BecomeTeacherNPC("%s")',
	ToNPL = function(self)
		return string.format('BecomeTeacherNPC("%s")\n', self:getFieldValue('npcType'));
	end,
	examples = {{desc = "创建指定类型的教师NPC", canRun = false, code = [[
]]}},
},

{
	type = "SetTeacherNPCTasks", 
	message0 = "设置学习任务 %1",
	arg0 = {
		{
			name = "tasks",
			type = "field_input",
			text = "",
		},
	},
	category = "npc", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'SetTeacherNPCTasks(%s)',
	ToNPL = function(self)
		return string.format('SetTeacherNPCTasks(%s)\n', self:getFieldValue('tasks'));
	end,
	examples = {{desc = "设置学习任务", canRun = false, code = [[
]]}},
},

});