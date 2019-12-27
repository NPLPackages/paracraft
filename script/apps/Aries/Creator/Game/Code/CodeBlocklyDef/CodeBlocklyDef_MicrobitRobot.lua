--[[
Title: CodeBlocklyDef_MicrobitRobot
Author(s): leio
Date: 2019/12/19
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/CodeBlocklyDef_MicrobitRobot.lua");
-------------------------------------------------------
]]
NPL.export({

{
	type = "createMicrobitRobot", 
	message0 = L"创建机器人",
    arg0 = {
	},
	category = "MicrobitRobot", 
	helpUrl = "", 
	canRun = false,
	nextStatement = true,
	funcName = "createMicrobitRobot",
	func_description = 'createMicrobitRobot()',
	ToNPL = function(self)
		return string.format('createMicrobitRobot()\n');
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

})