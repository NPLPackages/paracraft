--[[
Title: NplMicroRobotDef_Operators
Author(s): leio
Date: 2019/11/29
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicroRobot/NplMicroRobotDef/NplMicroRobotDef_Operators.lua");
-------------------------------------------------------
]]
local CommonDef = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CommonDefs/CommonDef.lua");

NPL.export({
    CommonDef.GetCmd("math_op", true, "NplMicroRobot.Operators"),
    CommonDef.GetCmd("math_op_compare_number", true, "NplMicroRobot.Operators"),
    CommonDef.GetCmd("math_op_compare", true, "NplMicroRobot.Operators"),
    CommonDef.GetCmd("random", true, "NplMicroRobot.Operators"),
    CommonDef.GetCmd("math_min_max", true, "NplMicroRobot.Operators"),
    CommonDef.GetCmd("math_compared", true, "NplMicroRobot.Operators"),
    CommonDef.GetCmd("not", true, "NplMicroRobot.Operators"),
    CommonDef.GetCmd("join", true, "NplMicroRobot.Operators"),
    CommonDef.GetCmd("lengthOf", true, "NplMicroRobot.Operators"),
    CommonDef.GetCmd("mod", true, "NplMicroRobot.Operators"),
    CommonDef.GetCmd("round", true, "NplMicroRobot.Operators"),
    CommonDef.GetCmd("math_oneop", true, "NplMicroRobot.Operators"),

})