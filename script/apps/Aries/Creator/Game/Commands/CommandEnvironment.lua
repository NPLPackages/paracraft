--[[
Title: 世界的环境参数变量
Author(s): hyz
Date: 2020/5/11
Desc: detect command 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandEnvironment.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ObjectPath.lua");
local ObjectPath = commonlib.gettable("System.Core.ObjectPath")
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

Commands["worldenv"] = {
	name="worldenv", 
	quick_ref="/worldenv [-weather=cloudy] [-time=0.5] [-lightcolor=r,g,b] [-shader=1|2|3|4]", 
	desc=[[Set environment parameters within the world
@param weather: sun,cloudy,rain,snow
@param time:[-1,1]
@param lightcolor: r,g,b
@param shader: [1,2,3,4]
@param cloudThickness: [0,1]
@param eyeBrightness: [0,1]
@param renderdist: number
@param superrenderdist: number
Examples: 
/worldenv -weather=rain
/worldenv -time=0.5
/worldenv -lightcolor=255,255,255
/worldenv -shader=1 -cloudThickness=0.5 -eyeBrightness=0.5 -renderdist=90 -superrenderdist=500
]], 
    handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
        local options;
        local options = CmdParser.ParseOptionsNameValue(cmd_text);
        if options.weather then
            GameLogic.options:SetWeather(options.weather)
        end
        
        if options.isFreezetime then
            GameLogic.options:SetTimesAutoGo(options.isFreezetime~="false")
        end
        
        if options.lightcolor then
            local block_light_scale = options.block_light_scale or 172;
            local arr = commonlib.split(options.lightcolor,",")
            if #arr==3 then
                local r,g,b = tonumber(arr[1]),tonumber(arr[2]),tonumber(arr[3])
                GameLogic.options:SetLightColor(r,g,b,block_light_scale)
            end
        end
        if tonumber(options.shader) then
            GameLogic.options:SetRenderMethod(tonumber(options.shader))
        end
        if tonumber(options.cloudThickness) then
            GameLogic.options:SetCloudThickness(tonumber(options.cloudThickness))
        end
        if tonumber(options.eyeBrightness) then
            GameLogic.options:SetEyeBrightness(tonumber(options.eyeBrightness))
        end
        if tonumber(options.renderdist) then
            GameLogic.options:SetRenderDist(tonumber(options.renderdist))
        end
        if tonumber(options.superrenderdist) then
            GameLogic.options:SetSuperRenderDist(tonumber(options.superrenderdist))
        end
	end,
};

