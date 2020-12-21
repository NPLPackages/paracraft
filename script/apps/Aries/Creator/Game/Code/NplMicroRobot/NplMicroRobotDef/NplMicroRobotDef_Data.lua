--[[
Title: NplMicroRobotDef_Data
Author(s): leio
Date: 2019/12/2
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicroRobot/NplMicroRobotDef/NplMicroRobotDef_Data.lua");
-------------------------------------------------------
]]
local CommonDef = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CommonDefs/CommonDef.lua");

NPL.export({
    CommonDef.GetCmd("getLocalVariable", true, "NplMicroRobot.Data"),
    CommonDef.GetCmd("createLocalVariable", true, "NplMicroRobot.Data"),
    CommonDef.GetCmd("assign", true, "NplMicroRobot.Data"),
    CommonDef.GetCmd("getString", true, "NplMicroRobot.Data"),
    CommonDef.GetCmd("getBoolean", true, "NplMicroRobot.Data"),
    CommonDef.GetCmd("getNumber", true, "NplMicroRobot.Data"),
    CommonDef.GetCmd("code_block", true, "NplMicroRobot.Data"),
    CommonDef.GetCmd("code_comment", true, "NplMicroRobot.Data"),
    CommonDef.GetCmd("code_comment_full", true, "NplMicroRobot.Data"),
    CommonDef.GetCmd("data_variable", true, "NplMicroRobot.Data"),
})