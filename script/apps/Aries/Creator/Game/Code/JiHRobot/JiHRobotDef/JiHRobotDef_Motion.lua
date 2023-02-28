--[[
Title: JiHRobotDef_Motion
Author(s): leio
Date: 2022/8/23
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/JiHRobot/JiHRobotDef/JiHRobotDef_Motion.lua");
local JiHRobotDef_Motion = commonlib.gettable("MyCompany.Aries.Game.Code.JiHRobot.JiHRobotDef_Motion");
-------------------------------------------------------
]]
local JiHRobotDef_Motion = commonlib.gettable("MyCompany.Aries.Game.Code.JiHRobot.JiHRobotDef_Motion");
local cmds = {
{
	type = "forward", 
	message0 = L"前进",
	category = "Motion", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "forward",
	func_description = 'forward()',
	func_description_js = 'forward()',
	ToNPL = function(self)
		return string.format('forward()\n')
	end,
	examples = {{desc = "", canRun = true, code = [[ 
forward()
    ]]}},
},

{
	type = "backward", 
	message0 = L"后退",
	category = "Motion", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "backward",
	func_description = 'backward()',
	func_description_js = 'backward()',
	ToNPL = function(self)
		return string.format('backward()\n')
	end,
	examples = {{desc = "", canRun = true, code = [[
backward()
    ]]}},
},

{
	type = "trunLeft", 
	message0 = L"左转",
	category = "Motion", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "trunLeft",
	func_description = 'trunLeft()',
	func_description_js = 'trunLeft()',
	ToNPL = function(self)
		return string.format('trunLeft()\n')
	end,
	examples = {{desc = "", canRun = true, code = [[
trunLeft()
    ]]}},
},

{
	type = "trunRight", 
	message0 = L"右转",
	category = "Motion", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "trunRight",
	func_description = 'trunRight()',
	func_description_js = 'trunRight()',
	ToNPL = function(self)
		return string.format('trunRight()\n')
	end,
	examples = {{desc = "", canRun = true, code = [[
trunRight()
    ]]}},
},

};
function JiHRobotDef_Motion.GetCmds()
	return cmds;
end
