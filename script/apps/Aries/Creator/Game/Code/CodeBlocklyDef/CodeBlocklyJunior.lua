
local ParacraftCodeBlockly = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/ParacraftCodeBlockly.lua");
local CodeBlocklyJunior = commonlib.inherit(ParacraftCodeBlockly, NPL.export());

CodeBlocklyJunior.class_name = "CodeBlocklyJunior";

local all_cmd_types = {
    "moveForward",
    "turn",
    "turnTo",
    "turnToTarget",
    "walkForward",
    "getX",
    "getY",
    "getZ",
    
    "sayAndWait",
    "tip",
    "anim",
    "play",
    "playLoop",
    "stop",
    "scale",
    "scaleTo",
    "focus",
    "camera",
    "playMovie",
    "window",

    "registerClickEvent",
    "registerKeyPressedEvent",
    "registerBlockClickEvent",
    "registerBroadcastEvent",
    "broadcast",
    "cmd",

    "wait",
    "repeat",
    "forever",
    "repeat_count_step",
    "if_else",
    "becomeAgent",

    "playNote",
    "playSound",
    "playText",

    "isTouching",
    "askAndWait",
    "answer",
    "isKeyPressed",
    "getBlock",
    "setBlock",

    "math_op",
    "math_op_compare_number",
    "random",
    "math_compared",
    "math_oneop",

    "getLocalVariable",
    "set",
    "registerCloneEvent",
    "clone",
    "setActorValue",
    "getString",
    "getBoolean",
    "getNumber",
    "getColor",
    "showVariable",
}

local all_cmds = {};
function CodeBlocklyJunior.GetAllCmds()
    if (not next(all_cmds)) then
        ParacraftCodeBlockly.GetAllCmds();
        for _, cmd_type in ipairs(all_cmd_types) do
            table.insert(all_cmds, ParacraftCodeBlockly.GetItemByType(cmd_type));
        end
    end
    return all_cmds;
end

function CodeBlocklyJunior.GetCustomCodeUIUrl()
    local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
    if IsMobileUIEnabled then
        return "script/apps/Aries/Creator/Game/Mobile/CodeBlockWindow/CodeBlockJuniorWindow.mobile.html"
    end
	return "script/apps/Aries/Creator/Game/Code/CodeBlockJuniorWindow.html";
end
