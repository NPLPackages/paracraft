--[[
Title: CommonDef
Author(s): leio
Date: 2020/12/14
Desc: 
use the lib:
-------------------------------------------------------
local CommonDef = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CommonDefs/CommonDef.lua");
local cmd = CommonDef.GetCmd("control_if", true, "Control")
-------------------------------------------------------
]]
local CommonDef = NPL.export();
local cmds = {
        NPL.load("./CommonDef_Logic.lua");
        NPL.load("./CommonDef_Loops.lua");
        NPL.load("./CommonDef_Math.lua");
        NPL.load("./CommonDef_Variables.lua");
}
function CommonDef.GetCmd(type, bClone, category)
    for k, v in ipairs(cmds) do
        for kk,cmd in ipairs(v) do
            if(cmd.type == type)then
                if(bClone)then
                    cmd = commonlib.copy(cmd)
                    cmd.category = category;
                end
                return cmd;
            end
        end
    end
    return {
        category = category,
        error_cmd_type = type, 
    };
end