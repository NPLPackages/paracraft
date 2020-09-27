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
	type = "BecomeGeneralNPC", 
	message0 = "创建通用NPC config %1 类型 %2",
	arg0 = {
		{
			name = "configName",
			type = "field_input",
			text = "GeneralNPC",
		},
		{
			name = "npcType",
			type = "field_dropdown",
			options = {
				{ "大富抽奖", "tatfook_lucky" },
				{ "李老师", "tatfook_vip" },
			},
			text = "大富抽奖",
		},
	},
	category = "npc", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'BecomeGeneralNPC("%s", "%s")',
	ToNPL = function(self)
		return string.format('BecomeGeneralNPC("%s", "%s")\n', self:getFieldValue('configName'), self:getFieldAsString('npcType'));
	end,
	examples = {{desc = "创建通用NPC", canRun = false, code = [[
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
	hide_in_codewindow = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'SetTeacherNPCTasks(%s)',
	ToNPL = function(self)
		return string.format('SetTeacherNPCTasks(%s)\n', self:getFieldValue('tasks'));
	end,
	examples = {{desc = "设置学习任务", canRun = false, code = [[
]]}},
},

{
	type = "anim", 
	message0 = L"播放动作编号 %1",
	arg0 = {
		{
			name = "animId",
			type = "input_value",
			shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
	},
	category = "npc", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "anim",
	func_description = 'anim(%d)',
	ToNPL = function(self)
		return string.format('anim(%d)\n', self:getFieldValue('animId'));
	end,
	examples = {{desc = "", canRun = true, code = [[
anim(4)
move(-2,0,0,1)
anim(0)
]]},
{desc = L"常用动作编号", canRun = true, code = [[
-- 0: standing
-- 4: walking 
-- 5: running
-- check movie block for more ids
]]}
},
},

});