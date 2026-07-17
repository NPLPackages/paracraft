--[[
Title: MQTT Chat Tools
Author: Paracraft Assistant
Date: 2025/01/12
Desc: Registers MQTT tools for AI chat via ToolRegistry pattern.

uselib:
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/MQTTTools.lua");
    local MQTTTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.MQTTTools");
    MQTTTools:new():RegisterTools(registry);
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/MQTTClient.lua");
local MQTTClient = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.MQTTClient")

local MQTTTools = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.MQTTTools"));

function MQTTTools:ctor()
end

function MQTTTools:RegisterTools(registry)
    if not registry then return; end

    registry:RegisterTool("mqtt_publish", {
        description = "通过MQTT协议发送控制指令或数据。",
        parameters = {
            type = "object",
            properties = {
                topic = {type = "string", description = "目标主题"},
                message = {type = "string", description = "消息内容"},
            },
            required = {"topic", "message"},
        },
    }, function(params, callback, services)
        local success, err = MQTTClient.GetInstance():Publish(params.topic, params.message);
        if success then
            callback({success = true, llm_result = "Published to " .. params.topic});
        else
            local msg = (err == "Not connected")
                and "MQTT未连接。请先让用户在数字人配置面板的'工具'页面配置MQTT连接参数，或使用配置界面连接MQTT服务器。"
                or ("Failed: " .. (err or "Unknown error"));
            callback({success = false, llm_result = msg});
        end
    end, "mqtt");

    registry:RegisterTool("mqtt_get", {
        description = "获取MQTT变量的值。",
        parameters = {
            type = "object",
            properties = {
                topic = {type = "string", description = "变量主题"},
                timeout = {type = "number", description = "超时时间(ms)，默认5000"},
            },
            required = {"topic"},
        },
    }, function(params, callback, services)
        MQTTClient.GetInstance():Get(params.topic, params.timeout, function(result, err)
            if result then
                callback({success = true, llm_result = result});
            else
                local msg = (err == "Not connected")
                    and "MQTT未连接。请先让用户在数字人配置面板的'工具'页面配置MQTT连接参数，或使用配置界面连接MQTT服务器。"
                    or ("Failed: " .. (err or "Timeout"));
                callback({success = false, llm_result = msg});
            end
        end);
    end, "mqtt");

    registry:RegisterTool("mqtt_subscribe", {
        description = "订阅MQTT主题。",
        parameters = {
            type = "object",
            properties = {
                topic = {type = "string", description = "主题"},
            },
            required = {"topic"},
        },
    }, function(params, callback, services)
        local success, err = MQTTClient.GetInstance():Subscribe(params.topic);
        if success then
            callback({success = true, llm_result = "Subscribed to " .. params.topic});
        else
            local msg = (err == "Not connected")
                and "MQTT未连接。请先让用户在数字人配置面板的'工具'页面配置MQTT连接参数，或使用配置界面连接MQTT服务器。"
                or ("Failed: " .. (err or "Unknown error"));
            callback({success = false, llm_result = msg});
        end
    end, "mqtt");
end

return MQTTTools;
