--[[
Title: MQTT Tool Manager for EasyAIChat
Author: Paracraft Assistant
Date: 2025/01/12
Desc: Manages MQTT connection and provides tool callbacks for AI Chat
]]
NPL.load("(gl)script/ide/System/os/network/MQTT/mqtt.lua");
local mqtt = commonlib.gettable("System.os.network.mqtt");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");

local MQTTTools = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.MQTTTools"));

MQTTTools.client = nil;
MQTTTools.config = nil;
MQTTTools.status = "disconnected"; -- disconnected, connecting, connected, error
MQTTTools.listeners = {};
MQTTTools.last_messages = {}; -- Cache last message for topics

function MQTTTools:ctor()
end

function MQTTTools.GetInstance()
    if not MQTTTools.s_instance then
        MQTTTools.s_instance = MQTTTools:new();
    end
    return MQTTTools.s_instance;
end

-- Load config from file or default
function MQTTTools:LoadConfig()
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

function MQTTTools:SaveConfig(config)
    self.config = config;
    local configPath = "temp/mqtt_tool_config.json";
    local file = ParaIO.open(configPath, "w");
    if file:IsValid() then
        file:WriteString(commonlib.Json.Encode(config));
        file:close();
    end
end

-- Connect to MQTT broker
function MQTTTools:Connect(config, callback)
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
                LOG.std(nil, "error", "MQTTTools", "Connection failed: %s", connack:reason_string());
                if callback then callback(false, connack:reason_string()) end
                return;
            end
            
            self.status = "connected";
            LOG.std(nil, "info", "MQTTTools", "Connected to %s", uri);
            
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
                LOG.std(nil, "debug", "MQTTTools", "Msg on %s: %s", msg.topic, msg.payload);
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
            LOG.std(nil, "error", "MQTTTools", "Error: %s", err);
        end,
        
        close = function()
            self.status = "disconnected";
            LOG.std(nil, "info", "MQTTTools", "Connection closed");
        end
    });
    
    -- Start connection (async)
    self.client:start();
end

function MQTTTools:Publish(topic, payload)
    if not self.client or self.status ~= "connected" then
        return false, "Not connected";
    end
    LOG.std(nil, "debug", "MQTTTools", "Publishing to %s: %s", topic, payload);
    self.client:publish({topic = topic, payload = payload});
    return true;
end

function MQTTTools:Subscribe(topic, callback)
    if not self.client or self.status ~= "connected" then
        return false, "Not connected";
    end
    
    if callback then
        if not self.listeners[topic] then self.listeners[topic] = {} end
        table.insert(self.listeners[topic], callback);
    end
    LOG.std(nil, "debug", "MQTTTools", "Subscribing to %s", topic);
    self.client:subscribe({topic = topic, qos = 1});
    return true;
end

function MQTTTools:Get(topic, timeout_ms, callback)
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

-- Show Configuration Page
function MQTTTools:ShowMqttView(callback)
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/MQTTConfigPage.html", 
        name = "MQTTTools.ShowConfigPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide = true, 
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        bShow = true,
        click_through = false, 
        zorder = 10,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
            align = "_ct",
            x = -200,
            y = -150,
            width = 400,
            height = 350,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    if params and params._page then
        params._page.OnClose = function()
            local isConnected = self.client and (self.status == "connected" or self.status == "connecting")
            if callback and type(callback) == "function" then callback(isConnected) end
        end
    end
end

function MQTTTools:ShowConfigPage(callback)
    local isConnected = self.client and (self.status == "connected" or self.status == "connecting")
    if isConnected then
        _guihelper.MessageBox(L"当前mqtt服务已启动，是否重新配置", function(result)
            if result == _guihelper.DialogResult.Yes then
                self:ShowMqttView(callback)
            else
                if callback and type(callback) == "function" then callback(isConnected) end
            end
        end, _guihelper.MessageBoxButtons.YesNo)
    else
        self:ShowMqttView(callback)
    end
end
