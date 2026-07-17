--[[
Title: Emscripten
Author(s): wxa
Date: 2023.6.12
Desc: lua 与 js 通信
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/EmscriptenRawWebSocket.lua");
local EmscriptenRawWebSocket = commonlib.gettable("MyCompany.Aries.Game.GameLogic.EmscriptenRawWebSocket")
local socket = EmscriptenRawWebSocket:new();
socket:Recv(function(data) print(data) end);
socket:Open({}, function()
    socket:Send("hello world");
end);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/Encoding.lua");
local Encoding = commonlib.gettable("commonlib.Encoding");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");

local NPLJS = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NPLJS.lua");
local Emscripten = NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/Emscripten.lua");
local EmscriptenRawWebSocket = commonlib.inherit(commonlib.gettable("commonlib.EventSystem"), commonlib.gettable("MyCompany.Aries.Game.GameLogic.EmscriptenRawWebSocket"));

local EmscriptenRawWebSocketId = 0;
local EmscriptenRawWebSocketMap = {};
local EmscriptenMsgName = "RawWebSocket";

-- window调试emscripen GGS使用
-- local Win32DebugEmscripten = true;

function EmscriptenRawWebSocket:ctor()
    EmscriptenRawWebSocketId = EmscriptenRawWebSocketId + 1;
    self.m_id = tostring(EmscriptenRawWebSocketId);
    EmscriptenRawWebSocketMap[self.m_id] = self;
end

function EmscriptenRawWebSocket:Connect(url, onconnect, onmessage, onclose)
    self.m_connected = false;
    self.m_onconnect_callback = onconnect;
    self.m_onmessage_callback = onmessage;
    self.m_onclose_callback = onclose;

    -- if (Win32DebugEmscripten) then
    --     NPLJS:Open("http://127.0.0.1:8088/html/websocket/index.html", function()
    --         NPLJS:OnMsg(EmscriptenMsgName, function(msg)
    --             _G.OnEmscriptenRawWebSocketMessage(msg);
    --         end)

    --         NPLJS:SendMsg(EmscriptenMsgName, {
    --             id = self.m_id,
    --             action = "connect",
    --             url = url,
    --         });
    --     end, 10, 10, 100, 100);
    -- end

    Emscripten:SendMsg(EmscriptenMsgName, {
        id = self.m_id,
        action = "connect",
        url = url,
    });
    return self;
end

function EmscriptenRawWebSocket:Send(data)
    -- if (Win32DebugEmscripten) then
    --     NPLJS:SendMsg(EmscriptenMsgName, {
    --         id = self.m_id,
    --         action = "send",
    --         data = data,
    --     });
    -- end
    Emscripten:SendMsg(EmscriptenMsgName, {
        id = self.m_id,
        action = "send",
        data = data,
    });
end

function EmscriptenRawWebSocket:Close(callback)
    self.m_close_callback = callback or self.m_close_callback;
    EmscriptenRawWebSocketMap[self.m_id] = nil;
    -- if (Win32DebugEmscripten) then
    --     NPLJS:SendMsg(EmscriptenMsgName, {
    --         id = self.m_id,
    --         action = "close",
    --     });
    -- end
    Emscripten:SendMsg(EmscriptenMsgName, {
        id = self.m_id,
        action = "close",
    });
end

function EmscriptenRawWebSocket:OnClose()
    if (type(self.m_onclose_callback) =="function") then self.m_onclose_callback() end
    self.m_connected = false;
end

function EmscriptenRawWebSocket:OnMessage(data)
    local msg = commonlib.Json.Decode(data);
    if (type(self.m_onmessage_callback) == "function") then self.m_onmessage_callback(msg or data) end
end

function EmscriptenRawWebSocket:OnConnect()
    if (type(self.m_onconnect_callback) =="function") then self.m_onconnect_callback() end
    self.m_connected = true;
end

function EmscriptenRawWebSocket:IsConnected()
    return self.m_connected;
end

function OnEmscriptenRawWebSocketMessage(msg)
    local id = msg.id;
    local socket = EmscriptenRawWebSocketMap[id];
    if (not socket) then return end
    local action = msg.action;
    if (action == "connect") then
        socket:OnConnect();
    elseif (action == "message") then
        socket:OnMessage(msg.data);
    elseif (action == "close") then
        socket:OnClose();
    else
        print("=================================RawWebSocket Action Error====================================");
    end
end

-- if (Win32DebugEmscripten) then
--     _G.OnEmscriptenRawWebSocketMessage = OnEmscriptenRawWebSocketMessage;
-- end

Emscripten:OnMsg(EmscriptenMsgName, OnEmscriptenRawWebSocketMessage);
