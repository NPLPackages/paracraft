--[[
Title: ServerConfigManager
Author(s):  ygy
CreateDate: 2022.02.14
ModifyDate: 2022.02.14
Desc: 
use the lib:
------------------------------------------------------------
local ServerConfigManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/ServerConfigManager.lua");
------------------------------------------------------------
]]

local ServerConfigManager = NPL.export();
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");

ServerConfigManager.Config = {}
function ServerConfigManager.RequestConfig()
    keepwork.config.all({},function(err, msg, data)
        if err == 200 then
            local configs = data.configs;
            -- print("xxxxxxxxxzz")
            -- echo(configs, true)
            for key, v in pairs(configs) do
                ServerConfigManager.Config[v.name] = v;
            end
        end
    end)
end

function ServerConfigManager.GetConfigData(callback)
    if (not callback or type(callback) ~= 'function') then
        return;
    end

    keepwork.config.all({},function(err, msg, data)
        if err == 200 then
            local configs = data.configs;
            if configs then
                for key, v in pairs(configs) do
                    ServerConfigManager.Config[v.name] = v;
                end
            end

            callback(ServerConfigManager.Config);
        end
    end)
end

-- scrollbar 滚动公告
-- yunnanVipPage 云南id
function ServerConfigManager.GetConfigByName(config_name)
    return ServerConfigManager.Config[config_name];
end