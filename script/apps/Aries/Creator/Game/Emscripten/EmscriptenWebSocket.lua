--[[
Title: Emscripten
Author(s): wxa
Date: 2023.6.12
Desc: lua 与 js 通信
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/EmscriptenWebSocket.lua");
local EmscriptenWebSocket = commonlib.gettable("MyCompany.Aries.Game.GameLogic.EmscriptenWebSocket")
local socket = EmscriptenWebSocket:new();
socket:Recv(function(data) print(data) end);
socket:Open({}, function()
    socket:Send("hello world");
end);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/Encoding.lua");
local Encoding = commonlib.gettable("commonlib.Encoding");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");

local Emscripten = NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/Emscripten.lua");
local EmscriptenWebSocket = commonlib.inherit(commonlib.gettable("commonlib.EventSystem"), commonlib.gettable("MyCompany.Aries.Game.GameLogic.EmscriptenWebSocket"));

local EmscriptenWebSocketId = 0;
local EmscriptenWebSocketMap = {};

function EmscriptenWebSocket:ctor()
    EmscriptenWebSocketId = EmscriptenWebSocketId + 1;
    self.m_id = tostring(EmscriptenWebSocketId);

    EmscriptenWebSocketMap[self.m_id] = self;
end

function EmscriptenWebSocket:Open(options, onopen, onmessage, onclose)
    options = options or {};
    options.url = options.url or "wss://im.keepwork.com";
    options.token = options.token or KeepWorkItemManager.GetToken();
    options.platform = options.platform or "webparacraft";

    self.m_connected = false;
    self.m_onopen_callback = onopen;
    self.m_onmessage_callback = onmessage;
    self.m_onclose_callback = onclose;

    Emscripten:SendMsg("WebSocket", {
        id = self.m_id,
        action = "open",
        data = options,
    });

    return self;
end

function EmscriptenWebSocket:Connect(url, sid, options)
    options = options or {};
    options.url = url;

    self:Open(options);
end

function EmscriptenWebSocket:GetArgs(name, ...)
    local args = {name}
    local cb

    -- iterate over arguments and extract arguments and callback, if any.
    for i = 1, select("#", ...) do
        local v = select(i, ...)

        if type(v) == "function" then
            assert(not cb, "callback already defined")
            cb = v
        else
            table.insert(args, v)
        end
    end
    return args;
end

function EmscriptenWebSocket:SendPacket(pkg)
    Emscripten:SendMsg("WebSocket", {
        id = self.m_id,
        action = "send",
        data = pkg.body,
    });
end

function EmscriptenWebSocket:Send(name, ...)
    Emscripten:SendMsg("WebSocket", {
        id = self.m_id,
        action = "send",
        data = self:GetArgs(name, ...),
    });
end

function EmscriptenWebSocket:Close(callback)
    self.state = "CLOSE";
    self.m_close_callback = callback;
    Emscripten:SendMsg("WebSocket", {
        id = self.m_id,
        action = "close",
    });
    EmscriptenWebSocketMap[self.m_id] = nil;
end

function EmscriptenWebSocket:OnClose()
    if (type(self.m_onclose_callback) =="function") then self.m_onclose_callback() end
    self:DispatchEvent({type = "OnClose"});
    self.state = "CLOSE";
    self.m_connected = false;
end

function EmscriptenWebSocket:OnMessage(data)
    if (type(self.m_onmessage_callback) == "function") then self.m_onmessage_callback(data) end
    self:DispatchEvent({type = "OnMsg", data = {body = data, eio_pkt_name = "message", sio_pkt_name = "event"}});
end

function EmscriptenWebSocket:OnOpen()
    if (type(self.m_onopen_callback) =="function") then self.m_onopen_callback() end
    self:DispatchEvent({type = "OnOpen" });
    self.state = "OPEN";
    self.m_connected = true;
end

function EmscriptenWebSocket:IsConnected()
    return self.m_connected;
end


-- 调试使用 可删除
-- Emscripten.m_msg_callback["WebSocket"] = nil;

Emscripten:OnMsg("WebSocket", function(msg)
    local id = msg.id;
    local socket = EmscriptenWebSocketMap[id];
    if (not socket) then return end
    local action = msg.action;
    if (action == "open") then
        socket:OnOpen();
    elseif (action == "message") then
        socket:OnMessage(msg.data);
    elseif (action == "close") then
        socket:OnClose();
    else
        print("=================================WebSocket Action Error====================================");
    end
end)

local function Test()
    local socket = EmscriptenWebSocket:new();
    -- socket:Recv(function(data) print(data) end);
    socket:Open({}, function()
        -- socket:Send("hello world");
    end);
end

-- Test();
