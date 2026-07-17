--[[
Title: Emscripten
Author(s): wxa
Date: 2023.6.12
Desc: lua 与 js 通信
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/EmscriptenMQTT.lua");
local EmscriptenMQTT = commonlib.gettable("MyCompany.Aries.Game.GameLogic.EmscriptenMQTT")
local mqtt = EmscriptenMQTT:new();
mqtt:Connect({url = "ws://broker.emqx.io:8083/mqtt"}, function()
    mqtt:Subscribe("testtopic", function(data) print(data) end)
    mqtt:Publish("testtopic", "hello world");
end, function(msg)
    print(msg.topic, msg.payload);
end, function()
    print("mqtt close")
end);
------------------------------------------------------------
]]

local Emscripten = NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/Emscripten.lua");
local EmscriptenMQTT = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.GameLogic.EmscriptenMQTT"));

local EmscriptenMQTTId = 0;
local EmscriptenMQTTMap = {};

function EmscriptenMQTT:ctor()
    EmscriptenMQTTId = EmscriptenMQTTId + 1;
    self.m_id = tostring(EmscriptenMQTTId);
    self.m_subscribe_callbacks = {};
    self.m_connected = false;

end

function EmscriptenMQTT:Connect(options, onconnect, onmessage, onclose)
    self.m_onconnect_callback = onconnect;
    self.m_onmessage_callback = onmessage;
    self.m_onclose_callback = onclose;

    self.m_id = tostring(options.clientId) .. "_" .. tostring(options.username) .. "_" .. tostring(options.password);
    EmscriptenMQTTMap[self.m_id] = self;

    Emscripten:SendMsg("MQTT", {
        id = self.m_id,
        action = "connect",
        data = options,
    });

    return self;
end

function EmscriptenMQTT:Subscribe(data, callback)
    local topic = data.topic or "";
    self.m_subscribe_callbacks[topic] = callback;

    Emscripten:SendMsg("MQTT", {
        id = self.m_id,
        action = "subscribe",
        data = data
    });
end

function EmscriptenMQTT:Unsubscribe(data)
    local topic = data.topic or "";
    self.m_subscribe_callbacks[topic] = nil;

    Emscripten:SendMsg("MQTT", {
        id = self.m_id,
        action = "unsubscribe",
        data = data
    });
end

function EmscriptenMQTT:Publish(data, payload)
    Emscripten:SendMsg("MQTT", {
        id = self.m_id,
        action = "publish",
        data = data
    });
end

function EmscriptenMQTT:Close()
    EmscriptenMQTTMap[self.m_id] = nil;
    Emscripten:SendMsg("MQTT", {
        id = self.m_id,
        action = "close",
    });
    print("===================EmscriptenMQTT:Close()=========================");
end

function EmscriptenMQTT:OnConnect()
    self.m_connected = true;
    if (type(self.m_onconnect_callback) == "function") then self.m_onconnect_callback() end
end

function EmscriptenMQTT:OnClose(msg)
    self.m_connected = false;
    if (type(self.m_onclose_callback) == "function") then self.m_onclose_callback() end
end

function EmscriptenMQTT:OnMessage(msg)
    local topic = msg.topic;
    local data = msg.data;

    local callback = self.m_subscribe_callbacks[topic];
    if (callback) then callback(data) end

    if (self.m_onmessage_callback) then
        msg.payload = data;
        self.m_onmessage_callback(msg);
    end
end

-- 调试使用 可删除
-- Emscripten.m_msg_callback["MQTT"] = nil;

Emscripten:OnMsg("MQTT", function(msg)
    local id = msg.id;
    local mqtt = EmscriptenMQTTMap[id];
    if (not mqtt) then return end
    local action = msg.action;
    if (action == "connect") then
        mqtt:OnConnect();
    elseif (action == "message") then
        mqtt:OnMessage(msg);
    elseif (action == "close") then
        mqtt:OnClose();
    else
        print("=================================Webmqtt Action Error====================================");
    end
end)

local function Test()
    local mqtt = EmscriptenMQTT:new();
    mqtt:Connect({
        url = "ws://mqtt.keepwork.com:8083/mqtt",
        username = 'deng123457/czejrjd0os',
        password = 'p3g58z6icn',
        clientId = "deng123457/p315wqt0pv",
    }, function()
        print("===================================mqtt connect====================================")
        mqtt:Subscribe("deng123457/snbegwsvye", function(data) print(data) end)
        mqtt:Publish("deng123457/snbegwsvye", "hello world");
    end, function(msg)
        print(msg.topic, msg.payload);
    end, function()
        print("mqtt close")
    end);
end

-- Test();