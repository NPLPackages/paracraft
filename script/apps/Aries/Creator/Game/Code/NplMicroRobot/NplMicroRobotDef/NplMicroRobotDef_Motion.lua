--[[
Title: NplMicroRobotDef_Motion
Author(s): leio
Date: 2019/12/19
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicroRobot/NplMicroRobotDef/NplMicroRobotDef_Motion.lua");
-------------------------------------------------------
]]
NPL.export({
{
	type = "createAnimationClip_NplMicroRobot", 
	message0 = L"创建动画片段 %1",
    arg0 = {
        {
			name = "name",
            type = "input_value",
            shadow = { type = "text", value = L"anim",},
			text = L"anim", 
		},
	},
	nextStatement = true,
	category = "NplMicroRobot.Motion", 
	helpUrl = "", 
	canRun = false,
	funcName = "createAnimationClip_NplMicroRobot",
	func_description = 'createAnimationClip_NplMicroRobot(%s)',
	ToNPL = function(self)
		return string.format('createAnimationClip_NplMicroRobot("%s")\n',
                self:getFieldValue('name') 
        );
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "createTimeLine_NplMicroRobot", 
	message0 = L"时间轴 开始:%1 结束:%2 次数:%3 速度:%4",
    arg0 = {
        {
			name = "from",
            type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
        {
			name = "to",
            type = "input_value",
            shadow = { type = "math_number", value = -1,},
			text = -1, 
		},
        {
			name = "loopTimes",
            type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
        {
			name = "speed",
            type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
	},
    previousStatement = true,
	nextStatement = true,
	category = "NplMicroRobot.Motion", 
	helpUrl = "", 
	canRun = false,
	funcName = "createTimeLine_NplMicroRobot",
	func_description = 'createTimeLine_NplMicroRobot(%s,%s,%s,%s)',
	ToNPL = function(self)
		return string.format('createTimeLine_NplMicroRobot(%s,%s,%s,%s)\n',
                self:getFieldValue('from'),
                self:getFieldValue('to'),
                self:getFieldValue('loopTimes'),
                self:getFieldValue('speed')
        );
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},


{
	type = "playAnimationClip_NplMicroRobot", 
	message0 = L"播放动画 %1",
    arg0 = {
        {
			name = "name",
            type = "input_value",
            shadow = { type = "text", value = L"anim",},
			text = L"anim", 
		},
	},
    previousStatement = true,
	nextStatement = true,
	category = "NplMicroRobot.Motion", 
	helpUrl = "", 
	canRun = false,
	funcName = "playAnimationClip_NplMicroRobot",
	func_description = 'playAnimationClip_NplMicroRobot(%s)',
	ToNPL = function(self)
		return string.format('playAnimationClip_NplMicroRobot("%s")\n',
                self:getFieldValue('name')
        );
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "stopAnimationClip_NplMicroRobot", 
	message0 = L"停止动画",
    previousStatement = true,
	nextStatement = true,
	category = "NplMicroRobot.Motion", 
	helpUrl = "", 
	canRun = false,
	funcName = "stopAnimationClip_NplMicroRobot",
	func_description = 'stopAnimationClip_NplMicroRobot()',
	func_description_js = 'stopAnimationClip_NplMicroRobot()',
	ToNPL = function(self)
		return string.format('stopAnimationClip_NplMicroRobot()\n');
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},




})