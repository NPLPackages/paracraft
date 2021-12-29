--[[
Title: Command Screen Recorder
Author(s): big
CreateDate: 2021.12.14
Desc:
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandScreenRecorder.lua");
-------------------------------------------------------
]]

local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");

Commands["screenrecorder"] = {
    name = "screenrecorder", 
	quick_ref = "/screenrecorder [start|stop]", 
	desc=[[]],
    mode_deny = "",
    handler = function(cmd_name, cmd_text, cmd_params)
        local mode
        mode, cmd_text = CmdParser.ParseWord(cmd_text);

        if mode == "start" then
            ScreenRecorder.start();
        elseif mode == "stop" then
            ScreenRecorder.stop();
        end
    end
}
