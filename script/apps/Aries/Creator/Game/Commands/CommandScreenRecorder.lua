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
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local ScreenRecorderHandler = commonlib.gettable("MyCompany.Aries.Game.Mobile.ScreenRecorderHandler");

ScreenRecorderHandler.savedCallbackFunc = function() end;
ScreenRecorderHandler.recordFinishedCallbackFunc = function() end;
ScreenRecorderHandler.startedCallbackFunc = function() end;
ScreenRecorderHandler.savedPath = "";

function ScreenRecorderHandler.SetStartedCallbackFunc(callback)
    ScreenRecorderHandler.startedCallbackFunc = function()
        if (callback and type(callback) == "function") then
            callback();
        end

        -- reset
        ScreenRecorderHandler.startedCallbackFunc = function() end;
    end
end

function ScreenRecorderHandler.SetSavedCallbackFunc(callback)
    ScreenRecorderHandler.savedCallbackFunc = function(savedPath)
        if (callback and type(callback) == "function") then
            callback(savedPath);
        end

        -- reset
        ScreenRecorderHandler.savedCallbackFunc = function() end;
    end;
end

function ScreenRecorderHandler.SetRecordFinishedCallbackFunc(callback)
    ScreenRecorderHandler.recordFinishedCallbackFunc = function(savedPath)
        if (callback and type(callback) == "function") then
            callback(savedPath);
        end

        -- reset
        ScreenRecorderHandler.recordFinishedCallbackFunc = function() end;
    end;
end

Commands["screenrecorder"] = {
    name = "screenrecorder", 
	quick_ref = "/screenrecorder [start|stop]", 
	desc=[[]],
    mode_deny = "",
    handler = function(cmd_name, cmd_text, cmd_params)
        local platform = System.os.GetPlatform();

        if (platform ~= "ios" and platform ~= "android") then
            _guihelper.MessageBox(L"此功能暂不支持该操作系统");
            return;
        end

        local mode
        mode, cmd_text = CmdParser.ParseWord(cmd_text);

        if (not ScreenRecorder) then
            -- only for mobile platform
            return;
        end

        if mode == "start" then
            if(ScreenRecorder.start) then
                ScreenRecorder.start();
            end
        elseif mode == "stop" then
            if(ScreenRecorder.stop) then
                ScreenRecorder.stop();
            end
        elseif mode == "play" then
            if(ScreenRecorder.play) then
                ScreenRecorder.play();
            end
        elseif mode == "save" then
            if(ScreenRecorder.save) then
                ScreenRecorderHandler.savedPath = ScreenRecorder.save();
            end
        elseif mode == "delete" then
            if(ScreenRecorder.removeVideo) then
                ScreenRecorder.removeVideo();
            end
        end
    end
}
