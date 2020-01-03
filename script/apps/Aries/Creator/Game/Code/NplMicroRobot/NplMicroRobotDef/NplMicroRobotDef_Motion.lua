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
	type = "createMicrobitRobot", 
	message0 = L"创建机器人",
	category = "NplMicroRobot.Motion", 
	helpUrl = "", 
	canRun = false,
	funcName = "createMicrobitRobot",
	func_description = 'createMicrobitRobot()',
	ToNPL = function(self)
		return string.format('createMicrobitRobot()\n');
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

})