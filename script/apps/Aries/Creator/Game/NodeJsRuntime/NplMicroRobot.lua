--[[
Title: NplMicroRobot
Author(s): leio
Date: 2019.12.25
Desc: 
use the lib:
------------------------------------------------------------
local NplMicroRobot = NPL.load("(gl)script/apps/Aries/Creator/Game/NodeJsRuntime/NplMicroRobot.lua");
NplMicroRobot.Run("deploy",NplMicroRobot.TestData());
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/ide/timer.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local NodeJsRuntime = NPL.load("(gl)script/apps/Aries/Creator/Game/NodeJsRuntime/NodeJsRuntime.lua");
local NplMicroRobot = NPL.export();

function NplMicroRobot.TestData()
    return [[
    [
    {
        "id": 0, // channel
        "ranges": [
            [0, 4]
        ],
        "times": [0, 2000, 4000, 6000, 8000],
        "data": [0, 45, 90, 135, 180]
    },
    {
        "id": 4, // channel
        "ranges": [
            [0, 3]
        ],
        "times": [0, 2000, 4000, 6000],
        "data": [0, 45, 90, 180]
    }
]
    ]]
end
function NplMicroRobot.WriteAnimationData(data)
    if(not data)then
        return
    end
    local code = string.format([[
let AnimationData  = %s
    ]],data)
    local filename = string.format("%s/%s",NodeJsRuntime.GetRoot(),"projects/NplMicroRobot/AnimationData.ts");
	LOG.std(nil, "error", "NplMicroRobot", "write animation to:%s",filename);
    local file = ParaIO.open(filename,"w");
    if(file:IsValid()) then
		file:WriteString(code);
		file:close();
	end
end
function NplMicroRobot.GetHexFileName()
    local filename = string.format("%s/%s",NodeJsRuntime.GetRoot(),"projects/NplMicroRobot/built/binary.hex");
    return filename;
end
-- @type "build" or "deploy"
function NplMicroRobot.Run(type,animation_data)
    type = type or "build"
    if(not NodeJsRuntime.IsValid())then
	    LOG.std(nil, "error", "NplMicroRobot", "NodeJsRuntime isn't valid()");
        return
    end
    local filename = NplMicroRobot.GetHexFileName();
	LOG.std(nil, "info", "NplMicroRobot", "the hex filename:%s",filename);
	ParaIO.DeleteFile(filename)


    NplMicroRobot.WriteAnimationData(animation_data)
    local cmd;
    if(type == "build")then
        cmd = string.format("%s/%s",NodeJsRuntime.GetRoot(),"projects/NplMicroRobot/build.bat");
    else
        cmd = string.format("%s/%s",NodeJsRuntime.GetRoot(),"projects/NplMicroRobot/deploy.bat");
    end
	ParaGlobal.ShellExecute("open", cmd, "", "", 1); 


    local timer = commonlib.Timer:new({callbackFunc = function(timer)
        if(ParaIO.DoesFileExist(filename))then
            timer:Change()
            
             _guihelper.MessageBox(string.format(L"成功生成:%s,是否打开文件夹？", commonlib.Encoding.DefaultToUtf8(filename)), function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
		            local folder,name,extension = string.match(filename, "(.+)/(.+)%.(%w+)$")
                    commonlib.echo(folder);
					if(folder) then
	                    ParaGlobal.ShellExecute("open", commonlib.Encoding.DefaultToUtf8(folder), "", "", 1); 
					end
				end
			end, _guihelper.MessageBoxButtons.YesNo);
        end
    end})

    timer:Change(0, 1000)
end
