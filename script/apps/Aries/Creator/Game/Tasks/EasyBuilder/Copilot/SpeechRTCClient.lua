--[[
Title: SpeechRTCClient
Author(s): AI-assisted
Date: 2026/04/01
Desc: VolcEngine bidirectional TTS client for NPL/Paracraft.
      Connects to speechrtc proxy via WebSocket, implements the Volc binary frame
      protocol, manages TTS sessions, and plays back PCM audio via temp WAV files.

      Phase 1: Text-to-speech output only.
      Phase 2 (future): Bidirectional audio input via AttachInput().

NOTE ON SSL:
      NPL's native TcpConnection does NOT support SSL/TLS.
      The speechrtc proxy at wss://speechrtc.keepwork.com/tts terminates SSL via nginx.
      For NPL, the proxy must be accessible on a plain ws:// endpoint.
      In dev: ws://localhost:55002/tts (speechrtc-proxy.mjs default port).
      In prod: expose the proxy backend on ws:// via infrastructure (e.g. internal port).

Usage:
------------------------------------------------------------
local SpeechRTCClient = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/SpeechRTCClient.lua");
local tts = SpeechRTCClient:new();
tts:Init({
    proxyUrl = "ws://localhost:55002/tts",
    voiceType = "zh_female_tianmeiyueyue_moon_bigtts",
});
tts:Connect("playbackCompleted", function() echo("done") end);
tts:Speak("你好，欢迎来到帕拉卡！");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/ide/AudioEngine/AudioEngine.lua");
local AudioEngine = commonlib.gettable("AudioEngine");

-- WebSocket dependencies
-- NPL.load("(gl)...") returns true (boolean) for NPL.export() modules.
-- Only relative-path NPL.load returns the export table (proven by SocketIOClient.lua).
-- From Copilot/ → 7 levels up to script/, then down to ide/System/os/network/WebSocket/*.lua
local WS_REL = "../../../../../../../ide/System/os/network/WebSocket/";
local wstools   = NPL.load(WS_REL .. "tools.lua");
local frame     = NPL.load(WS_REL .. "frame.lua");
local handshake = NPL.load(WS_REL .. "handshake.lua");

NPL.load("(gl)script/ide/System/os/network/TcpConnection.lua");
local TcpConnection = commonlib.gettable("System.os.network.TcpConnection");

-- Bit helpers (used by inline fallbacks below if module loading fails)
NPL.load("(gl)script/ide/math/bit.lua");
local bit = mathlib.bit;
local band, rshift, lshift = bit.band, bit.rshift, bit.lshift;

-- Safety: if relative-path loading still failed, inline the minimal binary helpers
if type(wstools) ~= "table" then
    LOG.std(nil, "warn", "SpeechRTCClient", "wstools relative load failed, using inline helpers");
    wstools = {};
    wstools.write_int32 = function(v)
        return string.char(
            band(rshift(v, 24), 0xFF),
            band(rshift(v, 16), 0xFF),
            band(rshift(v, 8), 0xFF),
            band(v, 0xFF));
    end
    wstools.read_int32 = function(str, pos)
        pos = pos or 1;
        local a, b, c, d = string.byte(str, pos, pos + 3);
        return pos + 4, lshift(a, 24) + lshift(b, 16) + lshift(c, 8) + d;
    end
    local DEFAULT_PORTS = { ws = 80, wss = 443 };
    wstools.parse_url = function(url)
        local protocol, address, uri = url:match('^(%w+)://([^/]+)(.*)$');
        if not protocol then error('Invalid URL:' .. url); end
        protocol = protocol:lower();
        local host, port = address:match("^(.+):(%d+)$");
        if not host then host = address; port = DEFAULT_PORTS[protocol]; end
        if not uri or uri == '' then uri = '/'; end
        return protocol, host, tonumber(port), uri;
    end
    NPL.load("(gl)script/ide/System/Encoding/base64.lua");
    local Encoding = commonlib.gettable("System.Encoding");
    local base64 = Encoding.base64;
    wstools.generate_key = function()
        local r1 = math.random(0, 0xfffffff);
        local r2 = math.random(0, 0xfffffff);
        local r3 = math.random(0, 0xfffffff);
        local r4 = math.random(0, 0xfffffff);
        local key = wstools.write_int32(r1) .. wstools.write_int32(r2) .. wstools.write_int32(r3) .. wstools.write_int32(r4);
        return base64(key);
    end
end

if type(frame) ~= "table" then
    LOG.std(nil, "error", "SpeechRTCClient", "WebSocket frame module not available! frame encode/decode will fail.");
end
if type(handshake) ~= "table" then
    LOG.std(nil, "error", "SpeechRTCClient", "WebSocket handshake module not available! WS upgrade will fail.");
end

local SpeechRTCClient = commonlib.inherit(
    commonlib.gettable("System.Core.ToolBase"), NPL.export());

-- ============================================================================
-- Constants — match JS SpeechRTC.js
-- ============================================================================

local MESSAGE_TYPE = {
    INVALID              = 0x0,
    FULL_CLIENT_REQUEST  = 0x1,
    AUDIO_ONLY_REQUEST   = 0x2,
    FULL_SERVER_RESPONSE = 0x9,
    AUDIO_ONLY_RESPONSE  = 0xB,
    FRONT_END_RESULT     = 0xC,
    ERROR_INFORMATION    = 0xF,
};

local MESSAGE_FLAG = {
    NO_SEQUENCE       = 0x0,
    POSITIVE_SEQUENCE = 0x1,
    LAST_NO_SEQUENCE  = 0x2,
    NEGATIVE_SEQUENCE = 0x3,
    WITH_EVENT        = 0x4,
};

local SERIALIZATION = { RAW = 0x0, JSON = 0x1 };
local COMPRESSION   = { NONE = 0x0 };

local EVENT = {
    NONE                = 0,
    START_CONNECTION    = 1,
    FINISH_CONNECTION   = 2,
    CONNECTION_STARTED  = 50,
    CONNECTION_FAILED   = 51,
    CONNECTION_FINISHED = 52,
    START_SESSION       = 100,
    CANCEL_SESSION      = 101,
    FINISH_SESSION      = 102,
    SESSION_STARTED     = 150,
    SESSION_CANCELED    = 151,
    SESSION_FINISHED    = 152,
    SESSION_FAILED      = 153,
    USAGE_RESPONSE      = 154,
    TASK_REQUEST        = 200,
    UPDATE_CONFIG       = 201,
    AUDIO_MUTED         = 250,
    TTS_SENTENCE_START  = 350,
    TTS_SENTENCE_END    = 351,
    TTS_RESPONSE        = 352,
    TTS_ENDED           = 359,
};

local SESSION_STATE = {
    IDLE        = "idle",
    CONNECTING  = "connecting",
    CONNECTED   = "connected",
    STARTING    = "starting",
    ACTIVE      = "active",
    FINISHING   = "finishing",
    FINISHED    = "finished",
    CANCELED    = "canceled",
    CLOSED      = "closed",
    FAILED      = "failed",
};

-- Connection-level events (no sessionId in the frame)
local CONNECTION_EVENTS = {
    [EVENT.START_CONNECTION]    = true,
    [EVENT.FINISH_CONNECTION]   = true,
    [EVENT.CONNECTION_STARTED]  = true,
    [EVENT.CONNECTION_FAILED]   = true,
    [EVENT.CONNECTION_FINISHED] = true,
};

-- Events where the server includes connectId after eventCode
local CONNECT_ID_EVENTS = {
    [EVENT.CONNECTION_STARTED]  = true,
    [EVENT.CONNECTION_FAILED]   = true,
    [EVENT.CONNECTION_FINISHED] = true,
};

local DEFAULT_PROXY_URL    = "ws://localhost:55002/tts";
local DEFAULT_SPEAKER      = "zh_female_tianmeiyueyue_moon_bigtts";
local DEFAULT_SAMPLE_RATE  = 24000;
local DEFAULT_NAMESPACE    = "BidirectionalTTS";
local TEMP_DIR             = "temp/speechrtc/";
local RPC_TIMEOUT_MS       = 15000;
local SESSION_TIMEOUT_MS   = 20000;
local WS_CONNECT_TIMEOUT   = 8; -- seconds for NPL.activate_with_timeout

-- Re-export constants for external use
SpeechRTCClient.EVENT = EVENT;
SpeechRTCClient.SESSION_STATE = SESSION_STATE;

-- ============================================================================
-- Signals
-- ============================================================================

SpeechRTCClient:Signal("sentenceStart");
SpeechRTCClient:Signal("sentenceEnd");
SpeechRTCClient:Signal("audioChunk");
SpeechRTCClient:Signal("sessionFinished");
SpeechRTCClient:Signal("playbackStarted");
SpeechRTCClient:Signal("playbackCompleted");
SpeechRTCClient:Signal("error");
SpeechRTCClient:Signal("stateChanged");

-- ============================================================================
-- Binary Helpers
-- ============================================================================

local write_int32 = wstools.write_int32;
local read_int32 = wstools.read_int32;

local function randomId(prefix, length)
    length = length or 12;
    local chars = "abcdefghijklmnopqrstuvwxyz0123456789";
    local result = prefix or "";
    for i = 1, length do
        local idx = math.random(1, #chars);
        result = result .. chars:sub(idx, idx);
    end
    return result;
end

local function shouldIncludeSessionId(eventCode)
    return not CONNECTION_EVENTS[eventCode];
end

local function shouldIncludeConnectId(eventCode)
    return CONNECT_ID_EVENTS[eventCode];
end

-- ============================================================================
-- Volc Frame Marshal
-- ============================================================================

--[[
    Encode a Volc client event into a binary string.
    @param eventCode number    EVENT.* constant
    @param payload table       JSON-serializable payload
    @param sessionId string    Session ID (included for non-connection events)
    @return string             Binary frame data
]]
local function marshalClientEvent(eventCode, payload, sessionId)
    local parts = {};

    -- Header byte 0: version=1 (high nibble), headerSize=1 (low nibble, × 4 = 4 bytes)
    -- Header byte 1: type=FULL_CLIENT_REQUEST=0x1 (high), flag=WITH_EVENT=0x4 (low)
    -- Header byte 2: serialization=JSON=0x1 (high), compression=NONE=0x0 (low)
    -- Header byte 3: reserved=0x00
    parts[#parts + 1] = string.char(0x11, 0x14, 0x10, 0x00);

    -- Event code (int32 big-endian)
    parts[#parts + 1] = write_int32(eventCode);

    -- Session ID (sized string) — only for non-connection events
    if shouldIncludeSessionId(eventCode) then
        local sid = sessionId or "";
        parts[#parts + 1] = write_int32(#sid);
        if #sid > 0 then
            parts[#parts + 1] = sid;
        end
    end

    -- Payload (JSON)
    local jsonStr = NPL.ToJson(payload or {});
    parts[#parts + 1] = write_int32(#jsonStr);
    parts[#parts + 1] = jsonStr;

    return table.concat(parts);
end

-- ============================================================================
-- Volc Frame Unmarshal
-- ============================================================================

--[[
    Decode a Volc server frame from binary string.
    @param data string  Raw binary frame data
    @return table       { messageType, flag, serialization, compression,
                          event, sessionId, connectId, payload, payloadRaw }
    @return string      Error message if parsing fails
]]
local function unmarshalServerFrame(data)
    if not data or #data < 4 then
        return nil, "frame too short";
    end

    local b0, b1, b2, b3 = string.byte(data, 1, 4);
    local headerSize = (b0 % 16) * 4;  -- low nibble × 4, in bytes
    local msgType    = math.floor(b1 / 16);
    local msgFlag    = b1 % 16;
    local serial     = math.floor(b2 / 16);
    local compress   = b2 % 16;

    local result = {
        messageType   = msgType,
        flag          = msgFlag,
        serialization = serial,
        compression   = compress,
        event         = nil,
        sessionId     = nil,
        connectId     = nil,
        payload       = nil,
        payloadRaw    = nil,
        errorCode     = nil,
    };

    local offset = headerSize + 1; -- Lua 1-indexed, skip past header

    -- Error frame: error code comes before event/payload
    if msgType == MESSAGE_TYPE.ERROR_INFORMATION then
        if #data < offset + 3 then return nil, "error frame too short"; end
        local newPos, errorCode = read_int32(data, offset);
        result.errorCode = errorCode;
        offset = newPos;

    -- Event frame
    elseif msgFlag == MESSAGE_FLAG.WITH_EVENT then
        if #data < offset + 3 then return nil, "event frame too short"; end
        local newPos, eventCode = read_int32(data, offset);
        result.event = eventCode;
        offset = newPos;

        -- Session ID
        if shouldIncludeSessionId(eventCode) then
            if #data < offset + 3 then return nil, "missing sessionId length"; end
            local newPos2, sidLen = read_int32(data, offset);
            offset = newPos2;
            if sidLen > 0 and #data >= offset + sidLen - 1 then
                result.sessionId = data:sub(offset, offset + sidLen - 1);
                offset = offset + sidLen;
            end
        end

        -- Connect ID (for CONNECTION_STARTED/FAILED/FINISHED)
        if shouldIncludeConnectId(eventCode) then
            if #data >= offset + 3 then
                local newPos3, cidLen = read_int32(data, offset);
                offset = newPos3;
                if cidLen > 0 and #data >= offset + cidLen - 1 then
                    result.connectId = data:sub(offset, offset + cidLen - 1);
                    offset = offset + cidLen;
                end
            end
        end

    -- Sequence frame (positive or negative)
    elseif msgFlag == MESSAGE_FLAG.POSITIVE_SEQUENCE or msgFlag == MESSAGE_FLAG.NEGATIVE_SEQUENCE then
        if #data >= offset + 3 then
            local newPos4, seq = read_int32(data, offset);
            result.sequence = seq;
            offset = newPos4;
        end
    end

    -- Payload
    if #data >= offset + 3 then
        local newPos5, payloadLen = read_int32(data, offset);
        offset = newPos5;
        if payloadLen > 0 and #data >= offset + payloadLen - 1 then
            local raw = data:sub(offset, offset + payloadLen - 1);
            result.payloadRaw = raw;

            if serial == SERIALIZATION.JSON then
                local out = {};
                if NPL.FromJson(raw, out) then
                    result.payload = out;
                else
                    result.payload = raw;
                end
            else
                result.payload = raw;
            end
        end
    end

    return result;
end

-- ============================================================================
-- Constructor
-- ============================================================================

function SpeechRTCClient:ctor()
    -- Config
    self.proxyUrl    = DEFAULT_PROXY_URL;
    self.voiceType   = DEFAULT_SPEAKER;
    self.sampleRate  = DEFAULT_SAMPLE_RATE;
    self.audioFormat = "pcm";
    self.namespace   = DEFAULT_NAMESPACE;
    self.appId       = nil;
    self.accessToken = nil;
    self.resourceId  = nil;
    self.userId      = nil;

    -- Session state
    self.state       = SESSION_STATE.IDLE;
    self.connectId   = "";
    self.sessionId   = "";

    -- WebSocket state
    self._ws         = nil;  -- { nid, serverAddr, state, key }

    -- Shared nid counter (across all instances, via class table)
    -- Each instance gets a unique nid
    SpeechRTCClient._nidCounter = (SpeechRTCClient._nidCounter or 0);

    -- Event waiters: list of { codes, callback, timeoutTimer }
    self._waiters    = {};

    -- Audio player state
    self._sentencePCM     = "";
    self._sentenceText    = "";
    self._playQueue       = {};
    self._isPlaying       = false;
    self._playSessionId   = 0;
    self._tempFileCounter = 0;

    -- Destroyed flag
    self._destroyed = false;

    -- Frame accumulator for fragmented WebSocket frames
    self._frameBuf = nil;
    -- TCP receive buffer for partial WebSocket frames
    self._recvBuf = "";
end

-- ============================================================================
-- Init
-- ============================================================================

function SpeechRTCClient:Init(options)
    options = options or {};
    self.proxyUrl    = options.proxyUrl or DEFAULT_PROXY_URL;
    self.voiceType   = options.voiceType or options.speaker or DEFAULT_SPEAKER;
    self.sampleRate  = options.sampleRate or DEFAULT_SAMPLE_RATE;
    self.audioFormat = options.audioFormat or "pcm";
    self.namespace   = options.namespace or DEFAULT_NAMESPACE;
    self.appId       = options.appId;
    self.accessToken = options.accessToken;
    self.resourceId  = options.resourceId;
    self.userId      = options.userId;

    -- Ensure temp directory exists
    ParaIO.CreateDirectory(ParaIO.GetWritablePath() .. TEMP_DIR);

    return self;
end

-- ============================================================================
-- WebSocket Transport
-- ============================================================================

function SpeechRTCClient:_generateNid()
    SpeechRTCClient._nidCounter = (SpeechRTCClient._nidCounter or 0) + 1;
    return string.format("speechrtc_%d_%d", os.time(), SpeechRTCClient._nidCounter);
end

-- Simple URL-encode for query parameter values (RFC 3986 unreserved chars pass through)
local function urlEncode(str)
    if not str then return ""; end
    return str:gsub("([^%w%-%.%_%~])", function(c)
        return string.format("%%%02X", string.byte(c));
    end);
end

function SpeechRTCClient:_buildProxyUrl()
    local url = self.proxyUrl;
    local sep = url:find("?") and "&" or "?";
    local parts = { url };
    parts[#parts + 1] = sep .. "upstream=" .. urlEncode("wss://openspeech.bytedance.com/api/v3/tts/bidirection");
    parts[#parts + 1] = "&connect_id=" .. urlEncode(self.connectId);
    if self.appId then
        parts[#parts + 1] = "&app_key=" .. urlEncode(self.appId);
    end
    if self.accessToken then
        parts[#parts + 1] = "&access_token=" .. urlEncode(self.accessToken);
    end
    local rid = self.resourceId;
    if not rid then
        rid = (self.voiceType or ""):sub(1, 2) == "S_"
            and "volc.megatts.default"
            or "volc.service_type.10029";
    end
    parts[#parts + 1] = "&resource_id=" .. urlEncode(rid);
    return table.concat(parts);
end

function SpeechRTCClient:_setState(newState)
    local oldState = self.state;
    if oldState == newState then return; end
    self.state = newState;
    LOG.std(nil, "info", "SpeechRTCClient", "State: %s -> %s", oldState, newState);
    self:stateChanged(newState, oldState);
end

function SpeechRTCClient:_wsConnect(callback)
    if self._ws and self._ws.state == "OPEN" then
        if callback then callback(true); end
        return;
    end

    self.connectId = randomId("connect_");
    local fullUrl = self:_buildProxyUrl();
    local protocol, host, port, uri = wstools.parse_url(fullUrl);

    if protocol == "wss" then
        LOG.std(nil, "warn", "SpeechRTCClient",
            "wss:// is NOT supported by NPL TcpConnection. Use ws:// or configure a non-SSL proxy endpoint.");
    end

    local nid = self:_generateNid();
    local serverAddr = nid .. ":tcp";
    local key = wstools.generate_key();

    self._ws = {
        nid = nid,
        serverAddr = serverAddr,
        state = "CONNECTING",
        key = key,
    };

    local self_ = self;

    -- Register TCP message handler for this nid
    TcpConnection.AddConnectionHandler(nid, function(msg)
        self_:_onTcpMessage(msg);
    end);

    NPL.AddNPLRuntimeAddress({ host = host, port = tostring(port), nid = nid });

    -- Send WebSocket upgrade request (no Sec-WebSocket-Protocol — server rejects empty value)
    local req = handshake.upgrade_request({
        key = key,
        host = host,
        port = port,
        protocols = {},
        uri = uri,
    });

    self._wsOpenCallback = callback;

    LOG.std(nil, "info", "SpeechRTCClient", "Connecting to %s:%d%s ...", host, port, uri);

    if NPL.activate_with_timeout(WS_CONNECT_TIMEOUT, serverAddr, req) ~= 0 then
        LOG.std(nil, "error", "SpeechRTCClient", "Failed to connect to %s:%d (activate returned non-zero)", host, port);
        self._ws.state = "CLOSED";
        TcpConnection.AddConnectionHandler(nid, nil);
        self._ws = nil;
        self:_setState(SESSION_STATE.FAILED);
        if callback then callback(false, "connect failed"); end
        return;
    end

    -- Timeout fallback: if no handshake response arrives
    self._wsConnectTimer = commonlib.Timer:new({
        callbackFunc = function()
            if self._ws and self._ws.state == "CONNECTING" then
                LOG.std(nil, "error", "SpeechRTCClient",
                    "WebSocket handshake timeout after %ds. Is the proxy running at %s:%d?",
                    WS_CONNECT_TIMEOUT, host, port);
                self:_onWsClose(string.format("handshake timeout (proxy %s:%d not reachable?)", host, port));
                if self._wsOpenCallback then
                    local cb = self._wsOpenCallback;
                    self._wsOpenCallback = nil;
                    cb(false, "handshake timeout - is the proxy running?");
                end
            end
        end
    });
    self._wsConnectTimer:Change(WS_CONNECT_TIMEOUT * 1000, nil);
end

function SpeechRTCClient:_onTcpMessage(msg)
    if not self._ws then return; end

    if msg and msg.code == 12 then
        -- Connection closed by remote
        self:_onWsClose("remote closed");
        return;
    end

    if self._ws.state == "CONNECTING" then
        -- Handshake response
        local response = msg[1];
        if not response then
            LOG.std(nil, "debug", "SpeechRTCClient", "Handshake: TCP connected, awaiting HTTP response");
            return;
        end
        LOG.std(nil, "debug", "SpeechRTCClient", "Handshake response (%d bytes): %s",
            #response, tostring(response):sub(1, 300));
        local headers, extra = handshake.http_headers(response);

        if not headers or not headers["sec-websocket-accept"] then
            -- Extract HTTP status line for better diagnostics
            local statusLine = (response or ""):match("^([^\r\n]+)");
            LOG.std(nil, "warn", "SpeechRTCClient",
                "Handshake rejected by server: %s", tostring(statusLine));
            self._ws.state = "CLOSED";
            TcpConnection.AddConnectionHandler(self._ws.nid, nil);
            self._ws = nil;
            if self._wsConnectTimer then
                self._wsConnectTimer:Change();
                self._wsConnectTimer = nil;
            end
            if self._wsOpenCallback then
                local cb = self._wsOpenCallback;
                self._wsOpenCallback = nil;
                cb(false, "handshake rejected: " .. tostring(statusLine));
            end
            self:_setState(SESSION_STATE.FAILED);
            return;
        end

        local expected = handshake.sec_websocket_accept(self._ws.key);
        if headers["sec-websocket-accept"] ~= expected then
            LOG.std(nil, "error", "SpeechRTCClient", "WebSocket handshake failed: accept mismatch");
            self._ws.state = "CLOSED";
            TcpConnection.AddConnectionHandler(self._ws.nid, nil);
            self._ws = nil;
            if self._wsConnectTimer then
                self._wsConnectTimer:Change();
                self._wsConnectTimer = nil;
            end
            if self._wsOpenCallback then
                local cb = self._wsOpenCallback;
                self._wsOpenCallback = nil;
                cb(false, "handshake failed");
            end
            return;
        end

        self._ws.state = "OPEN";
        self._recvBuf = "";
        -- Cancel the connect timeout timer
        if self._wsConnectTimer then
            self._wsConnectTimer:Change();
            self._wsConnectTimer = nil;
        end
        LOG.std(nil, "info", "SpeechRTCClient", "WebSocket connected");
        if self._wsOpenCallback then
            local cb = self._wsOpenCallback;
            self._wsOpenCallback = nil;
            cb(true);
        end
    else
        -- Data frame(s): accumulate in receive buffer and decode all complete frames
        local response = msg[1];
        if not response then return; end
        self._recvBuf = self._recvBuf .. response;

        -- Process all complete WebSocket frames in the buffer
        local maxIterations = 100; -- safety guard
        local iterations = 0;
        while #self._recvBuf > 0 and iterations < maxIterations do
            iterations = iterations + 1;
            local decoded, fin_or_needed, opcode, remaining = frame.decode(self._recvBuf);
            if not decoded then
                -- Incomplete frame: fin_or_needed is bytes still needed, wait for more data
                break;
            end
            -- Update buffer to remaining data after this frame
            self._recvBuf = remaining or "";

            if opcode == frame.CLOSE then
                self:_onWsClose("close frame");
                return;
            elseif opcode == frame.PONG then
                -- keepalive pong, ignore
            elseif opcode == frame.BINARY then
                self:_onBinaryFrame(decoded);
            elseif opcode == frame.TEXT then
                LOG.std(nil, "warn", "SpeechRTCClient", "Unexpected text frame: %s",
                    tostring(decoded):sub(1, 200));
            end
        end
    end
end

function SpeechRTCClient:_wsSendBinary(data)
    if not self._ws or self._ws.state ~= "OPEN" then
        LOG.std(nil, "warn", "SpeechRTCClient", "Cannot send: WebSocket not open (state=%s)",
            self._ws and self._ws.state or "nil");
        return false;
    end
    local encoded = frame.encode(data, frame.BINARY, true);
    return NPL.activate(self._ws.serverAddr, encoded) == 0;
end

function SpeechRTCClient:_wsClose()
    if self._wsConnectTimer then
        self._wsConnectTimer:Change();
        self._wsConnectTimer = nil;
    end
    if not self._ws then return; end
    if self._ws.state == "OPEN" then
        pcall(function()
            local closeData = frame.encode_close(1000, "normal");
            local encoded = frame.encode(closeData, frame.CLOSE, true);
            NPL.activate(self._ws.serverAddr, encoded);
        end);
    end
    TcpConnection.AddConnectionHandler(self._ws.nid, nil);
    self._ws.state = "CLOSED";
    self._ws = nil;
    self._recvBuf = "";
end

function SpeechRTCClient:_onWsClose(reason)
    LOG.std(nil, "info", "SpeechRTCClient", "WebSocket closed: %s", tostring(reason));
    if self._ws then
        TcpConnection.AddConnectionHandler(self._ws.nid, nil);
    end
    self._ws = nil;
    self:_resolveAllWaiters("WebSocket closed");
    if self.state ~= SESSION_STATE.CLOSED and self.state ~= SESSION_STATE.IDLE then
        self:_setState(SESSION_STATE.CLOSED);
        self:error("WebSocket closed: " .. tostring(reason));
    end
end

-- ============================================================================
-- Event Waiters
-- ============================================================================

function SpeechRTCClient:_waitForEvent(eventCodes, timeout, callback)
    if type(eventCodes) == "number" then eventCodes = { eventCodes }; end
    timeout = timeout or RPC_TIMEOUT_MS;

    local waiter = { codes = eventCodes, callback = callback };

    waiter.timeoutTimer = commonlib.Timer:new({
        callbackFunc = function()
            self:_removeWaiter(waiter);
            if waiter.callback then
                waiter.callback(nil, "timeout waiting for events");
            end
        end
    });
    waiter.timeoutTimer:Change(timeout, nil);

    for _, code in ipairs(eventCodes) do
        if not self._waiters[code] then self._waiters[code] = {}; end
        self._waiters[code][#self._waiters[code] + 1] = waiter;
    end
end

function SpeechRTCClient:_resolveWaiter(eventCode, volcFrame)
    local list = self._waiters[eventCode];
    if not list or #list == 0 then return; end

    local waiter = table.remove(list, 1);
    if #list == 0 then self._waiters[eventCode] = nil; end

    -- Remove from other event code lists
    self:_removeWaiter(waiter, eventCode);
    if waiter.timeoutTimer then waiter.timeoutTimer:Change(); end
    if waiter.callback then waiter.callback(volcFrame, nil); end
end

function SpeechRTCClient:_removeWaiter(waiter, skipCode)
    for _, code in ipairs(waiter.codes) do
        if code ~= skipCode and self._waiters[code] then
            local list = self._waiters[code];
            for i = #list, 1, -1 do
                if list[i] == waiter then
                    table.remove(list, i);
                    break;
                end
            end
            if #list == 0 then self._waiters[code] = nil; end
        end
    end
end

function SpeechRTCClient:_resolveAllWaiters(errMsg)
    for code, list in pairs(self._waiters) do
        for _, waiter in ipairs(list) do
            if waiter.timeoutTimer then waiter.timeoutTimer:Change(); end
            if waiter.callback then waiter.callback(nil, errMsg); end
        end
    end
    self._waiters = {};
end

-- ============================================================================
-- Frame Dispatch
-- ============================================================================

function SpeechRTCClient:_onBinaryFrame(data)
    local volcFrame, err = unmarshalServerFrame(data);
    if not volcFrame then
        LOG.std(nil, "warn", "SpeechRTCClient", "Failed to unmarshal frame: %s", tostring(err));
        return;
    end

    -- Update IDs from server
    if volcFrame.connectId then self.connectId = volcFrame.connectId; end
    if volcFrame.sessionId then self.sessionId = volcFrame.sessionId; end

    -- Resolve event waiters
    if volcFrame.event then
        self:_resolveWaiter(volcFrame.event, volcFrame);
    end

    -- Handle audio-only frames
    if volcFrame.messageType == MESSAGE_TYPE.AUDIO_ONLY_RESPONSE then
        self:_onAudioData(volcFrame.payloadRaw or "");
        return;
    end

    -- Handle error frames
    if volcFrame.messageType == MESSAGE_TYPE.ERROR_INFORMATION then
        local detail = "";
        if volcFrame.payload and type(volcFrame.payload) == "table" then
            detail = volcFrame.payload.message or tostring(volcFrame.errorCode);
        else
            detail = tostring(volcFrame.errorCode);
        end
        LOG.std(nil, "error", "SpeechRTCClient", "Server error: %s", detail);
        self:_setState(SESSION_STATE.FAILED);
        self:error(detail);
        return;
    end

    -- Handle specific TTS events
    if volcFrame.event == EVENT.TTS_SENTENCE_START then
        local text = "";
        if volcFrame.payload and type(volcFrame.payload) == "table" then
            text = (volcFrame.payload.res_params and volcFrame.payload.res_params.text)
                or volcFrame.payload.text or "";
        end
        self._sentenceText = text;
        self._sentencePCM = "";
        self:sentenceStart(text);

    elseif volcFrame.event == EVENT.TTS_SENTENCE_END then
        local text = "";
        if volcFrame.payload and type(volcFrame.payload) == "table" then
            text = (volcFrame.payload.res_params and volcFrame.payload.res_params.text)
                or volcFrame.payload.text or self._sentenceText;
        else
            text = self._sentenceText;
        end
        self:_flushSentenceAudio(text);
        self:sentenceEnd(text);

    elseif volcFrame.event == EVENT.SESSION_FINISHED then
        self:_setState(SESSION_STATE.FINISHED);
        self:sessionFinished({ status = "finished", sessionId = self.sessionId });

    elseif volcFrame.event == EVENT.SESSION_FAILED then
        self:_setState(SESSION_STATE.FAILED);
        local detail = "session failed";
        if volcFrame.payload and type(volcFrame.payload) == "table" then
            detail = volcFrame.payload.message or detail;
        end
        self:error(detail);

    elseif volcFrame.event == EVENT.SESSION_CANCELED then
        self:_setState(SESSION_STATE.CANCELED);
    end
end

-- ============================================================================
-- Session Lifecycle
-- ============================================================================

function SpeechRTCClient:_sendEvent(eventCode, payload, sessionId)
    local data = marshalClientEvent(eventCode, payload, sessionId or self.sessionId);
    return self:_wsSendBinary(data);
end

--[[
    Begin a TTS session: connect WebSocket, start Volc connection, start session.
    @param callback function(self, err) — called when session is ACTIVE or on failure.
]]
function SpeechRTCClient:BeginSession(callback)
    if self._destroyed then
        if callback then callback(nil, "destroyed"); end
        return;
    end

    self:_setState(SESSION_STATE.CONNECTING);
    self.sessionId = randomId("session_");
    self:_clearPlayQueue();

    local self_ = self;

    -- Step 1: WebSocket connect
    self:_wsConnect(function(ok, err)
        if not ok then
            self_:_setState(SESSION_STATE.FAILED);
            if callback then callback(nil, err or "connect failed"); end
            return;
        end

        -- Step 2: Volc START_CONNECTION
        self_:_sendEvent(EVENT.START_CONNECTION, {});
        self_:_waitForEvent(
            { EVENT.CONNECTION_STARTED, EVENT.CONNECTION_FAILED },
            RPC_TIMEOUT_MS,
            function(volcFrame, waitErr)
                if waitErr or not volcFrame or volcFrame.event == EVENT.CONNECTION_FAILED then
                    self_:_setState(SESSION_STATE.FAILED);
                    if callback then callback(nil, waitErr or "connection rejected"); end
                    return;
                end
                if volcFrame.connectId then self_.connectId = volcFrame.connectId; end
                self_:_setState(SESSION_STATE.CONNECTED);
                LOG.std(nil, "info", "SpeechRTCClient", "Volc connected: %s", self_.connectId);

                -- Step 3: Volc START_SESSION
                self_:_sendStartSession(callback);
            end
        );
    end);
end

function SpeechRTCClient:_sendStartSession(callback)
    local payload = {
        event = EVENT.START_SESSION,
        user = { uid = self.userId or randomId("user_") },
        namespace = self.namespace,
        req_params = {
            speaker = self.voiceType,
            audio_params = {
                format = self.audioFormat,
                sample_rate = self.sampleRate,
                enable_subtitle = true,
            },
        },
    };

    self:_setState(SESSION_STATE.STARTING);
    self:_sendEvent(EVENT.START_SESSION, payload, self.sessionId);
    self:_waitForEvent(
        { EVENT.SESSION_STARTED, EVENT.SESSION_FAILED },
        SESSION_TIMEOUT_MS,
        function(volcFrame, waitErr)
            if waitErr or not volcFrame or volcFrame.event == EVENT.SESSION_FAILED then
                self:_setState(SESSION_STATE.FAILED);
                local detail = "session start failed";
                if volcFrame and volcFrame.payload and type(volcFrame.payload) == "table" then
                    detail = volcFrame.payload.message or detail;
                end
                if waitErr then detail = waitErr; end
                if callback then callback(nil, detail); end
                return;
            end
            if volcFrame.sessionId then self.sessionId = volcFrame.sessionId; end
            self:_setState(SESSION_STATE.ACTIVE);
            LOG.std(nil, "info", "SpeechRTCClient", "Session active: %s", self.sessionId);
            if callback then callback(self, nil); end
        end
    );
end

--[[
    Send text to synthesize.
    @param text string  Text to synthesize into speech.
]]
function SpeechRTCClient:SendText(text)
    if self.state ~= SESSION_STATE.ACTIVE then
        LOG.std(nil, "warn", "SpeechRTCClient", "SendText: session not active (state=%s)", self.state);
        return;
    end
    local payload = {
        event = EVENT.TASK_REQUEST,
        namespace = self.namespace,
        req_params = { text = text },
    };
    self:_sendEvent(EVENT.TASK_REQUEST, payload, self.sessionId);
end

--[[
    Finish the current session (request server to complete TTS and close session).
    @param callback function(frame, err)
]]
function SpeechRTCClient:FinishSession(callback)
    if self.state ~= SESSION_STATE.ACTIVE then
        if callback then callback(nil, "session not active"); end
        return;
    end
    self:_setState(SESSION_STATE.FINISHING);
    self:_sendEvent(EVENT.FINISH_SESSION, { event = EVENT.FINISH_SESSION }, self.sessionId);
    self:_waitForEvent(
        { EVENT.SESSION_FINISHED, EVENT.SESSION_FAILED },
        30000,
        function(volcFrame, waitErr)
            if callback then callback(volcFrame, waitErr); end
        end
    );
end

-- ============================================================================
-- Audio Playback Pipeline
-- ============================================================================

local function createWavHeader(dataLength, sampleRate)
    sampleRate = sampleRate or 24000;
    local bitsPerSample = 16;
    local numChannels = 1;
    local byteRate = sampleRate * numChannels * bitsPerSample / 8;
    local blockAlign = numChannels * bitsPerSample / 8;
    local fileSize = dataLength + 36;

    -- Little-endian writers for WAV format
    local function w16(v)
        return string.char(v % 256, math.floor(v / 256) % 256);
    end
    local function w32(v)
        return string.char(
            v % 256,
            math.floor(v / 256) % 256,
            math.floor(v / 65536) % 256,
            math.floor(v / 16777216) % 256
        );
    end

    return "RIFF" .. w32(fileSize) .. "WAVE"
        .. "fmt " .. w32(16) .. w16(1) .. w16(numChannels)
        .. w32(sampleRate) .. w32(byteRate) .. w16(blockAlign) .. w16(bitsPerSample)
        .. "data" .. w32(dataLength);
end

function SpeechRTCClient:_onAudioData(pcmData)
    if not pcmData or #pcmData == 0 then return; end
    self._sentencePCM = self._sentencePCM .. pcmData;
    self:audioChunk(pcmData);
end

function SpeechRTCClient:_flushSentenceAudio(text)
    if #self._sentencePCM == 0 then return; end

    self._tempFileCounter = self._tempFileCounter + 1;
    -- Use relative path from working directory so AudioEngine can find it
    local relPath = string.format("%ss_%d.wav", TEMP_DIR, self._tempFileCounter);
    local filename = ParaIO.GetWritablePath() .. relPath;

    local wavData = createWavHeader(#self._sentencePCM, self.sampleRate) .. self._sentencePCM;

    local file = ParaIO.open(filename, "w");
    if file then
        file:write(wavData, #wavData);
        file:close();
        self._playQueue[#self._playQueue + 1] = { path = filename, relPath = relPath, text = text };
        LOG.std(nil, "debug", "SpeechRTCClient", "Queued audio: %s (%d bytes PCM)",
            filename, #self._sentencePCM);
    else
        LOG.std(nil, "error", "SpeechRTCClient", "Failed to write WAV: %s", filename);
    end

    self._sentencePCM = "";

    if not self._isPlaying then
        self:_playNext();
    end
end

function SpeechRTCClient:_playNext()
    if #self._playQueue == 0 then
        self._isPlaying = false;
        self:playbackCompleted();
        return;
    end

    self._isPlaying = true;
    self._playSessionId = self._playSessionId + 1;
    local currentId = self._playSessionId;
    local item = table.remove(self._playQueue, 1);

    self:playbackStarted(item.text);

    local self_ = self;
    local soundName = "speechrtc_" .. currentId;

    LOG.std(nil, "debug", "SpeechRTCClient", "Playing audio: %s (file: %s)", soundName, item.path);
    AudioEngine.Init();
    local src = AudioEngine.CreateGet(soundName);
    -- Try absolute path first; fall back to relative if needed
    src.file = item.path;
    src.inmemory = false;
    src:play2d();

    -- Poll for completion (AudioSource doesn't have an end callback for file playback)
    local pollTimer = commonlib.Timer:new({
        callbackFunc = function(timer)
            if self_._playSessionId ~= currentId then
                -- Interrupted: stop
                timer:Change();
                pcall(function() src:stop(); src:release(); end);
                AudioEngine.Delete(soundName);
                return;
            end
            if not src:isPlaying() then
                timer:Change();
                pcall(function() src:stop(); src:release(); end);
                AudioEngine.Delete(soundName);
                self_:_playNext();
            end
        end
    });
    pollTimer:Change(100, 100);
end

function SpeechRTCClient:_clearPlayQueue()
    self._playQueue = {};
    self._isPlaying = false;
    self._playSessionId = self._playSessionId + 1;
    self._sentencePCM = "";
end

-- ============================================================================
-- Public Convenience API
-- ============================================================================

--[[
    One-shot speak: auto BeginSession → SendText → FinishSession.
    @param text string          Text to synthesize
    @param callback function    Called when session finishes (not when playback finishes)
]]
function SpeechRTCClient:Speak(text, callback)
    local self_ = self;
    self:BeginSession(function(session, err)
        if err then
            LOG.std(nil, "error", "SpeechRTCClient", "Speak: session failed: %s", tostring(err));
            if callback then callback(nil, err); end
            return;
        end
        self_:SendText(text);
        self_:FinishSession(callback);
    end);
end

--[[
    Interrupt: stop playback, cancel session if active.
]]
function SpeechRTCClient:Interrupt()
    self:_clearPlayQueue();

    -- Cancel session if active
    if self.state == SESSION_STATE.ACTIVE then
        self:_sendEvent(EVENT.CANCEL_SESSION, { event = EVENT.CANCEL_SESSION }, self.sessionId);
        self:_setState(SESSION_STATE.CANCELED);
    end
end

-- ============================================================================
-- Future: Bidirectional Audio Input (Phase 2)
-- ============================================================================

--[[
    Attach a VoiceContextManager as audio input source.
    When attached, recorded PCM chunks are forwarded as AUDIO_ONLY_REQUEST frames.
    @param voiceContextManager - VoiceContextManager instance
]]
function SpeechRTCClient:AttachInput(voiceContextManager)
    LOG.std(nil, "info", "SpeechRTCClient", "AttachInput: not yet implemented (Phase 2)");
end

--[[
    Detach audio input source.
]]
function SpeechRTCClient:DetachInput()
    LOG.std(nil, "info", "SpeechRTCClient", "DetachInput: not yet implemented (Phase 2)");
end

-- ============================================================================
-- Shutdown / Destroy
-- ============================================================================

--[[
    Graceful shutdown: finish connection, close WebSocket, clear all state.
]]
function SpeechRTCClient:Shutdown()
    self._destroyed = true;
    self:_clearPlayQueue();
    self:_resolveAllWaiters("shutdown");
    if self._ws and self._ws.state == "OPEN" then
        pcall(function()
            self:_sendEvent(EVENT.FINISH_CONNECTION, { event = EVENT.FINISH_CONNECTION });
        end);
    end
    self:_wsClose();
    self:_setState(SESSION_STATE.CLOSED);
end

--[[
    Destroy synonym: shutdown + log.
]]
function SpeechRTCClient:Destroy()
    self:Shutdown();
    LOG.std(nil, "info", "SpeechRTCClient", "Destroyed");
end
