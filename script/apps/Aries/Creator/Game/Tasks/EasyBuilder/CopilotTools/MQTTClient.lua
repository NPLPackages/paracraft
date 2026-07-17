--[[
Title: MQTT Tool Manager for EasyAIChat
Author: Paracraft Assistant
Date: 2025/01/12
Desc: Manages MQTT connection and provides tool callbacks for AI Chat
]]
NPL.load("(gl)script/ide/System/os/network/MQTT/mqtt.lua");
local mqtt = commonlib.gettable("System.os.network.mqtt");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");

local MQTTClient = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.MQTTClient"));

MQTTClient.client = nil;
MQTTClient.config = nil;
MQTTClient.status = "disconnected"; -- disconnected, connecting, connected, error
MQTTClient.listeners = {};
MQTTClient.last_messages = {}; -- Cache last message for topics

function MQTTClient:ctor()
end

function MQTTClient.GetInstance()
    if not MQTTClient.s_instance then
        MQTTClient.s_instance = MQTTClient:new();
    end
    return MQTTClient.s_instance;
end

-- Load config from file or default
function MQTTClient:LoadConfig()
    if self.config then return self.config end
    
    local configPath = "temp/mqtt_tool_config.json";
    if ParaIO.DoesFileExist(configPath) then
        local file = ParaIO.open(configPath, "r");
        if file:IsValid() then
            local text = file:GetText();
            file:close();
            self.config = commonlib.Json.Decode(text);
        end
    end
    
    if not self.config then
        self.config = {
            host = "mqtt.keepwork.com",
            port = 18883,
            clientId = "paracraft_" .. ParaGlobal.GenerateUniqueID(),
            username = "",
            password = "",
            topics = {}, -- List of auto-subscribe topics
            keep_alive=30,
        };
    end
    return self.config;
end

function MQTTClient:SaveConfig(config)
    self.config = config;
    local configPath = "temp/mqtt_tool_config.json";
    local file = ParaIO.open(configPath, "w");
    if file:IsValid() then
        file:WriteString(commonlib.Json.Encode(config));
        file:close();
    end
end

-- Connect to MQTT broker
function MQTTClient:Connect(config, callback)
    if config then self:SaveConfig(config) end
    config = config or self:LoadConfig();
    
    if self.client then
        self.client:close_connection();
        self.client = nil;
    end
    
    self.status = "connecting";
    
    -- Map config to NPL MQTT params
    -- Note: NPL MQTT lib handles protocol via uri scheme usually, but let's check implementation
    -- System.os.network.mqtt.client:Init(args) uses args.uri
    local uri = config.host or "mqtt.keepwork.com";
    if config.port then
        uri = uri .. ":" .. config.port
    end
    local params = {
        uri = uri,
        username = config.username,
        password = config.password,
        id = config.clientId,
        keep_alive = 30,
        clean = true,
    }

    self.client = mqtt:new():Init(params)
    self.client:on({
        connect = function(connack)
            if connack.rc ~= 0 then
                self.status = "error";
                LOG.std(nil, "error", "MQTTClient", "Connection failed: %s", connack:reason_string());
                if callback then callback(false, connack:reason_string()) end
                return;
            end
            
            self.status = "connected";
            LOG.std(nil, "info", "MQTTClient", "Connected to %s", uri);
            
            -- Auto subscribe
            if config.topics then
                for _, topic in ipairs(config.topics) do
                    self:Subscribe(topic);
                end
            end
            
            if callback then callback(true) end
        end,
        
        message = function(msg)
            if msg.topic and msg.payload then
                self.last_messages[msg.topic] = msg.payload;
                LOG.std(nil, "debug", "MQTTClient", "Msg on %s: %s", msg.topic, msg.payload);
                -- Trigger listeners
                local listeners = self.listeners[msg.topic];
                if listeners then
                    for _, cb in ipairs(listeners) do
                        cb(msg.payload);
                    end
                end
            end
        end,
        
        error = function(err)
            self.status = "error";
            LOG.std(nil, "error", "MQTTClient", "Error: %s", err);
        end,
        
        close = function()
            self.status = "disconnected";
            LOG.std(nil, "info", "MQTTClient", "Connection closed");
        end
    });
    
    -- Start connection (async)
    self.client:start();
end

function MQTTClient:Publish(topic, payload)
    if not self.client or self.status ~= "connected" then
        return false, "Not connected";
    end
    LOG.std(nil, "debug", "MQTTClient", "Publishing to %s: %s", topic, payload);
    self.client:publish({topic = topic, payload = payload});
    return true;
end

function MQTTClient:Subscribe(topic, callback)
    if not self.client or self.status ~= "connected" then
        return false, "Not connected";
    end
    
    if callback then
        if not self.listeners[topic] then self.listeners[topic] = {} end
        table.insert(self.listeners[topic], callback);
    end
    LOG.std(nil, "debug", "MQTTClient", "Subscribing to %s", topic);
    self.client:subscribe({topic = topic, qos = 1});
    return true;
end

function MQTTClient:Get(topic, timeout_ms, callback)
    -- If we have cached message
    if self.last_messages[topic] then
        callback(self.last_messages[topic]);
        return;
    end
    
    if not self.client or self.status ~= "connected" then
        callback(nil, "Not connected");
        return;
    end
    
    -- Subscribe and wait for message
    local done = false;
    local listener = function(payload)
        if not done then
            done = true;
            callback(payload);
        end
    end
    
    self:Subscribe(topic, listener);
    
    -- Timeout
    commonlib.TimerManager.SetTimeout(function()
        if not done then
            done = true;
            -- Remove listener logic is tricky without ID, but for now we rely on 'done' flag
            callback(nil, "Timeout");
        end
    end, timeout_ms or 5000);
end