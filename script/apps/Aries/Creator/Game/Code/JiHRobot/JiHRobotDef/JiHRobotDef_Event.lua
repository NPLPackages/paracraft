--[[
Title: JiHRobotDef_Event
Author(s): leio
Date: 2022/8/23
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/JiHRobot/JiHRobotDef/JiHRobotDef_Event.lua");
local JiHRobotDef_Event = commonlib.gettable("MyCompany.Aries.Game.Code.JiHRobot.JiHRobotDef_Event");
-------------------------------------------------------
]]
local JiHRobotDef_Event = commonlib.gettable("MyCompany.Aries.Game.Code.JiHRobot.JiHRobotDef_Event");
local cmds = {
{
	type = "onPlay", 
	message0 = L"当点击运行",
	category = "Event", 
	helpUrl = "", 
	canRun = false,
	nextStatement = true,
	funcName = "onPlay",
	func_description = 'onPlay()',
	
},



};
function JiHRobotDef_Event.GetCmds()
	return cmds;
end
