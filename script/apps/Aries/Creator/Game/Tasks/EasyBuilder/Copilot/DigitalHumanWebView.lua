--[[
Title: DigitalHumanWebView
Author(s): AI-assisted
Date: 2026/03/20
Desc: Lua controller for DigitalHuman avatar inside Paracraft's WebView.
      Mirrors DigitalHumanFrame.js — loads a DigitalHuman webpage via NPLJS,
      sends commands via RPC, receives events, and bridges AI tool calls
      back to Paracraft's native ToolSandbox via AgentRouter.

Architecture:
  - dh-frame channel: @keepwork_digitalHuman / @webparacraft_digitalHuman
    Used for RPC commands and fire-and-forget messages (Lua ↔ JS).
  - AgentRouter channel: @keepwork_dhAgent / @webparacraft_dhAgent
    Used for tool call delegation (JS→Lua) via AgentRouter protocol.

Usage:
------------------------------------------------------------
local DigitalHumanWebView = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/DigitalHumanWebView.lua");
local dh = DigitalHumanWebView:new();
dh:on("message", function(data) echo(data) end);
dh:on("complete", function() echo("done") end);
dh:Start({
    url = "http://localhost:3001/test/testDigitalHumanWebView.html",
    width = 400, height = 600,
    config = {
        character = { name = "拉拉" },
        system_prompt = "你是拉拉，一个友善的AI角色。",
        llm_model = "keepwork-flash",
        videoActions = {
            ["idle"] = { url = "https://cdn.keepwork.com/digitalhuman/v1/female/femalewaiter/idle_nobg.webp" },
            ["talk"] = { url = "https://cdn.keepwork.com/digitalhuman/v1/female/femalewaiter/talking_nobg.webp" },
        },
    },
}, function()
    -- session ready, can send messages now
    dh:sendMessage("你好！");
end);
------------------------------------------------------------
]]
local NPLJS = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NPLJS.lua");
local AgentRouter = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/AgentRouter.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/ToolSandbox.lua");
local ToolSandbox = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.ToolSandbox");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/ToolRegistry.lua");
local ToolRegistry = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.ToolRegistry");

local DigitalHumanWebView = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

-- ============================================================================
-- Constants
-- ============================================================================

local FRAME_MSG_PREFIX = "dh-frame:";

-- NPLJS channel names
local DH_SEND_EVENT   = "@keepwork_digitalHuman";       -- Lua → JS (commands)
local DH_RECV_EVENT   = "@webparacraft_digitalHuman";   -- JS → Lua (events/responses)
local AR_SEND_EVENT   = "@keepwork_dhAgent";             -- Lua → JS (AgentRouter)
local AR_RECV_EVENT   = "@webparacraft_dhAgent";         -- JS → Lua (AgentRouter)

-- Message types matching DigitalHumanFrame.js MSG constants
local MSG = {
    -- Lua → JS (commands)
    INIT_AVATAR       = FRAME_MSG_PREFIX .. "init-avatar",
    INIT_FROM_CONFIG  = FRAME_MSG_PREFIX .. "init-from-config",
    CREATE_SESSION    = FRAME_MSG_PREFIX .. "create-session",
    SEND              = FRAME_MSG_PREFIX .. "send",
    SEND_MESSAGE      = FRAME_MSG_PREFIX .. "send-message",
    PLAY_ACTION       = FRAME_MSG_PREFIX .. "play-action",
    SWITCH_VIDEO      = FRAME_MSG_PREFIX .. "switch-video",
    SWITCH_TO_IDLE    = FRAME_MSG_PREFIX .. "switch-to-idle",
    SWITCH_TO_TALKING = FRAME_MSG_PREFIX .. "switch-to-talking",
    SET_MOUTH_OPEN    = FRAME_MSG_PREFIX .. "set-mouth-open",
    PLAY_MOTION       = FRAME_MSG_PREFIX .. "play-motion",
    GET_ACTIONS       = FRAME_MSG_PREFIX .. "get-actions",
    GET_AVATAR_STATUS = FRAME_MSG_PREFIX .. "get-avatar-status",
    DESTROY           = FRAME_MSG_PREFIX .. "destroy",
    GET_SESSION       = FRAME_MSG_PREFIX .. "get-session",
    START_VOICE_CHAT  = FRAME_MSG_PREFIX .. "start-voice-chat",
    STOP_VOICE_CHAT   = FRAME_MSG_PREFIX .. "stop-voice-chat",
    SEND_VOICE_TEXT   = FRAME_MSG_PREFIX .. "send-voice-text",
    MUTE_MICROPHONE   = FRAME_MSG_PREFIX .. "mute-microphone",
    UPDATE_VOICE_CHAT = FRAME_MSG_PREFIX .. "update-voice-chat",
    SEND_BOOT_MESSAGE = FRAME_MSG_PREFIX .. "send-boot-message",
    SEND_CONTEXT      = FRAME_MSG_PREFIX .. "send-context",
    SEND_TTS          = FRAME_MSG_PREFIX .. "send-tts",
    RESTART_VOICE_CHAT = FRAME_MSG_PREFIX .. "restart-voice-chat",
    EXPAND_INLINE_SYSTEM_PROMPT = FRAME_MSG_PREFIX .. "expand-inline-system-prompt",
    LOAD_SUMMARIZE_AGENT_CONFIG = FRAME_MSG_PREFIX .. "load-summarize-agent-config",
    SUMMARIZE         = FRAME_MSG_PREFIX .. "summarize",

    -- JS → Lua (events/responses)
    EVENT             = FRAME_MSG_PREFIX .. "event",
    READY             = FRAME_MSG_PREFIX .. "ready",
    RESPONSE          = FRAME_MSG_PREFIX .. "response",
};

-- RPC timeout in milliseconds
local RPC_TIMEOUT_MS = 30000;

-- ============================================================================
-- Signals
-- ============================================================================

DigitalHumanWebView:Signal("OnReady");
DigitalHumanWebView:Signal("OnDestroy");

-- ============================================================================
-- Constructor
-- ============================================================================

function DigitalHumanWebView:ctor()
    -- WebView URL
    self.url = nil;
    -- WebView position and size
    self.x = 0;
    self.y = 0;
    self.width = 0;
    self.height = 0;
    -- Workspace for tool proxy scope
    self.workspace = nil;
    -- Which tool categories to proxy (nil = all)
    self.proxyCategories = nil;
    -- External ToolRegistry to expose via ToolSandbox (optional; set via Init options)
    self.toolRegistry = nil;

    -- Per-instance AgentRouter and ToolSandbox (created in _setupAgentBridge)
    self._agentRouter = nil;
    self._toolSandbox = nil;

    -- WebView state
    self._ready = false;
    self._sessionReady = false;
    self._destroyed = false;
    self._openCallback = nil;
    self._pendingMessages = {};

    -- RPC tracking: callId → { callback, timeoutTimer }
    self._rpcCallbacks = {};
    self._callIdCounter = 0;

    -- Event listeners: event → { callback → callback }
    self._eventListeners = {};

    -- Character metadata (cached from initFromConfig)
    self.characterConfig = nil;
    self.characterInfo = nil;
    self.initialMessage = "";
    self.quickReplies = {};
    self.objective = nil;
    self.completionMessages = nil;
    self.voiceChatConfig = {};
    self.avatarOnlyMode = false;

    -- Summarize queue: only one summarization runs at a time
    self._summarizing = false;
    self._pendingSummarize = nil;
end

-- ============================================================================
-- Init — entry point
-- ============================================================================

--[[
    Initialize the DigitalHumanWebView with options.
    @param options table {
        url: string            - URL of the WebView HTML page
        x: number              - WebView x position (default 0)
        y: number              - WebView y position (default 0)
        width: number          - WebView width (default 400)
        height: number         - WebView height (default 600)
        workspace: string      - Workspace name for tool proxy scope
        proxyCategories: table - Array of tool category names to proxy
        toolRegistry: ToolRegistry - Optional; when provided, a ToolSandbox is created
                                     to expose its tools to the JS side via AgentRouter.
    }
    @return self for chaining
]]
function DigitalHumanWebView:Init(options)
    options = options or {};
    self.url = options.url;
    self.x = options.x or 0;
    self.y = options.y or 0;
    self.width = options.width or 400;
    self.height = options.height or 600;
    self.workspace = options.workspace;
    self.proxyCategories = options.proxyCategories;
    self.toolRegistry = options.toolRegistry;
    return self;
end

--[[
    One-step start: Open + initFromConfig + createSession.
    Combines Init, Open, initFromConfig, createSession into a single call.
    @param options table {
        url, x, y, width, height, workspace, proxyCategories, toolRegistry — same as Init
        config: table — the characterAI config (character, system_prompt, videoActions, etc.)
    }
    @param callback function() Called when session is ready and messages can be sent.
]]
function DigitalHumanWebView:Start(options, callback)
    options = options or {};
    self:Init(options);
    self._sessionReady = false;
    self._pendingMessages = {};

    local config = options.config or {};
    if options.workspace and not config.workspace then
        config.workspace = options.workspace;
    end

    self:Open(function()
        self:initFromConfig(config, function(result, err)
            if err then
                LOG.std(nil, "error", "DigitalHumanWebView", "Start initFromConfig failed: %s", tostring(err));
                self:emit("error", { message = err });
                return;
            end
            self:createSession(config, function(result2, err2)
                if err2 then
                    LOG.std(nil, "error", "DigitalHumanWebView", "Start createSession failed: %s", tostring(err2));
                    self:emit("error", { message = err2 });
                    return;
                end
                self._sessionReady = true;
                LOG.std(nil, "info", "DigitalHumanWebView", "Session ready");
                -- Flush queued messages
                self:_flushPendingMessages();
                if callback then callback(); end
            end);
        end);
    end);
end

-- ============================================================================
-- Open / Close — NPLJS lifecycle
-- ============================================================================

--[[
    Open the WebView and load the DigitalHuman page.
    @param callback function() Called when the WebView's DigitalHuman is ready.
]]
function DigitalHumanWebView:Open(callback)
    if not self.url then
        LOG.std(nil, "error", "DigitalHumanWebView", "Open: url is required");
        return;
    end
    if self._destroyed then
        LOG.std(nil, "error", "DigitalHumanWebView", "Open: instance has been destroyed");
        return;
    end

    self._ready = false;
    self._sessionReady = false;
    self._pendingMessages = {};
    self._openCallback = callback;

    LOG.std(nil, "info", "DigitalHumanWebView", "Opening WebView: %s (%dx%d)", self.url, self.width, self.height);

    NPLJS:Open(self.url, function()
        LOG.std(nil, "info", "DigitalHumanWebView", "NPLJS:Open callback — WebView loaded");

        -- Set up listeners AFTER Open callback, because NPLJS:Open() calls
        -- Reset() which clears all m_msg_callback. Registering before Open
        -- would get wiped.
        self:_setupMessageListeners();

        -- Set up AgentRouter bridge for tool proxy
        self:_setupAgentBridge();

        -- The page will send MSG.READY when DigitalHuman is initialized.
        -- The actual "ready" is handled in _onDHMessage.
    end, self.x, self.y, self.width, self.height, true);
end

-- ============================================================================
-- Message Listeners — dh-frame channel
-- ============================================================================

function DigitalHumanWebView:_setupMessageListeners()
    -- Listen on the dh-frame receive channel
    local self_ = self;
    self._dhMsgHandler = function(msgdata, msgid)
        if type(msgdata) ~= "table" then return; end
        self_:_onDHMessage(msgdata);
    end;
    NPLJS:OnMsg(DH_RECV_EVENT, self._dhMsgHandler);
end

function DigitalHumanWebView:_onDHMessage(msg)
    local msgType = msg.type;
    if not msgType or type(msgType) ~= "string" then return; end

    -- Only process messages with our prefix
    if string.find(msgType, FRAME_MSG_PREFIX, 1, true) ~= 1 then return; end

    if msgType == MSG.READY then
        local wasReady = self._ready;
        self._ready = true;
        LOG.std(nil, "info", "DigitalHumanWebView", "WebView DigitalHuman is READY (wasReady=%s)", tostring(wasReady));
        self:OnReady();
        if self._openCallback then
            local cb = self._openCallback;
            self._openCallback = nil;
            cb();
        elseif wasReady and self.characterConfig then
            -- Page was refreshed — re-send cached config so the new JS DigitalHuman
            -- gets its avatar and session back without the Lua caller having to redo init.
            LOG.std(nil, "info", "DigitalHumanWebView", "Page refresh detected, re-sending initFromConfig");
            self:_rpc(MSG.INIT_FROM_CONFIG, { config = self.characterConfig }, function(result, err)
                if err then
                    LOG.std(nil, "warn", "DigitalHumanWebView", "Re-init after refresh failed: %s", tostring(err));
                else
                    LOG.std(nil, "info", "DigitalHumanWebView", "Re-init after refresh succeeded");
                end
            end);
        end

    elseif msgType == MSG.RESPONSE then
        -- RPC response: resolve pending callback
        local callId = msg.callId;
        if callId and self._rpcCallbacks[callId] then
            local record = self._rpcCallbacks[callId];
            self._rpcCallbacks[callId] = nil;
            if record.timeoutTimer then
                record.timeoutTimer:Change();
            end
            local result = msg.result;
            if result and result.ok == false and result.error then
                record.callback(nil, result.error);
            else
                record.callback(result, nil);
            end
        end

    elseif msgType == MSG.EVENT then
        -- Relay event to Lua listeners
        local event = msg.event;
        local data = msg.data;
        if event then
            -- Drain summarize queue on completion
            if event == "summarized" then
                self:_onSummarizeComplete();
            end
            self:emit(event, data);
        end
    end
end

-- ============================================================================
-- AgentRouter Bridge — tool proxy channel
-- ============================================================================

function DigitalHumanWebView:_setupAgentBridge()
    -- Create a per-instance AgentRouter; each WebView endpoint gets its own router.
    self._agentRouter = AgentRouter:new();
    self._agentRouter:attach(AR_SEND_EVENT, AR_RECV_EVENT);
    LOG.std(nil, "info", "DigitalHumanWebView", "AgentRouter attached: send=%s recv=%s", AR_SEND_EVENT, AR_RECV_EVENT);

    -- If a ToolRegistry was provided, expose its tools to the JS side via ToolSandbox.
    -- This registers the "paracraft" agent on our router so JS tool proxy calls work.
    if self.toolRegistry then
        self._toolSandbox = ToolSandbox:new();
        self._toolSandbox:Init(self._agentRouter, self.toolRegistry,
            self.proxyCategories or nil,   -- nil = allow all categories
            nil);                          -- no serviceProvider by default
        LOG.std(nil, "info", "DigitalHumanWebView", "ToolSandbox initialized with toolRegistry");
    end
end

-- ============================================================================
-- RPC — request/response over NPLJS
-- ============================================================================

--[[
    Send a command to the WebView and wait for a response via callback.
    @param msgType string     Message type constant from MSG
    @param payload table      Additional payload fields (merged into message)
    @param callback function(result, errMsg)  Called with result or error
]]
function DigitalHumanWebView:_rpc(msgType, payload, callback)
    if self._destroyed then
        if callback then callback(nil, "DigitalHumanWebView destroyed"); end
        return;
    end

    self._callIdCounter = self._callIdCounter + 1;
    local callId = "dh_lua_" .. tostring(self._callIdCounter) .. "_" .. tostring(os.time());

    -- Build a new message table (don't mutate the caller's payload)
    local msg = { type = msgType, callId = callId };
    if payload then
        for k, v in pairs(payload) do
            msg[k] = v;
        end
    end

    -- Set up callback and timeout
    local timeoutTimer = commonlib.Timer:new({
        callbackFunc = function()
            local record = self._rpcCallbacks[callId];
            if record then
                self._rpcCallbacks[callId] = nil;
                LOG.std(nil, "warn", "DigitalHumanWebView", "RPC timeout: %s callId=%s", msgType, callId);
                if record.callback then
                    record.callback(nil, string.format("RPC timeout: %s", msgType));
                end
            end
        end
    });
    timeoutTimer:Change(RPC_TIMEOUT_MS, nil);

    self._rpcCallbacks[callId] = {
        callback = callback or function() end,
        timeoutTimer = timeoutTimer,
    };

    NPLJS:SendMsg(DH_SEND_EVENT, msg);
end

-- ============================================================================
-- Fire-and-forget — one-way command over NPLJS
-- ============================================================================

--[[
    Send a fire-and-forget command to the WebView.
    @param msgType string   Message type constant from MSG
    @param payload table    Additional payload fields
]]
function DigitalHumanWebView:_post(msgType, payload)
    if self._destroyed then return; end

    -- Build a new message table (don't mutate the caller's payload)
    local msg = { type = msgType };
    if payload then
        for k, v in pairs(payload) do
            msg[k] = v;
        end
    end

    NPLJS:SendMsg(DH_SEND_EVENT, msg);
end

-- ============================================================================
-- Event Emitter — on/off/emit
-- ============================================================================

--[[
    Register an event listener.
    @param event string    Event name (e.g. "message", "complete", "error")
    @param callback function(data)
    @return self for chaining
]]
function DigitalHumanWebView:on(event, callback)
    if not self._eventListeners[event] then
        self._eventListeners[event] = {};
    end
    self._eventListeners[event][callback] = callback;
    return self;
end

--[[
    Remove an event listener.
    @param event string
    @param callback function
    @return self for chaining
]]
function DigitalHumanWebView:off(event, callback)
    if self._eventListeners[event] then
        self._eventListeners[event][callback] = nil;
    end
    return self;
end

--[[
    Emit an event to all registered listeners.
    @param event string
    @param data any
]]
function DigitalHumanWebView:emit(event, data)
    local listeners = self._eventListeners[event];
    if not listeners then return; end
    for _, cb in pairs(listeners) do
        local ok, err = pcall(cb, data);
        if not ok then
            LOG.std(nil, "warn", "DigitalHumanWebView", "Event '%s' listener error: %s", event, tostring(err));
        end
    end
end

-- ============================================================================
-- NPL Tool Definition Injection
-- ============================================================================

--[[
    Inject NPL tool definitions from the ToolRegistry into a config table
    before sending it to the JS side. The JS layer reads these to register
    them as custom CopilotTools categories and proxy execution back to Lua.

    Adds two fields to config:
      config.nplToolDefinitions = { categoryName = { ...OpenAI defs... }, ... }
      config.nplProxyCategories = { "category1", "category2", ... }

    @param config table — the config being sent to JS (mutated in place)
]]
function DigitalHumanWebView:_injectNPLToolDefinitions(config)
    if not self.toolRegistry then return; end

    -- Determine which categories to expose
    local categories;
    if self.proxyCategories and #self.proxyCategories > 0 then
        categories = self.proxyCategories;
    else
        categories = self.toolRegistry:GetCategories();
    end

    if not categories or #categories == 0 then return; end

    -- Get definitions grouped by category
    local nplToolDefs = {};
    local hasAny = false;
    for _, cat in ipairs(categories) do
        local defs = self.toolRegistry:GetAllToolDefinitions({ cat });
        if defs and #defs > 0 then
            nplToolDefs[cat] = defs;
            hasAny = true;
        end
    end

    if hasAny then
        config.nplToolDefinitions = nplToolDefs;
        config.nplProxyCategories = categories;
        LOG.std(nil, "info", "DigitalHumanWebView", "Injected NPL tool definitions: %s",
            table.concat(categories, ", "));
    end
end

-- ============================================================================
-- Public API — mirrors DigitalHumanFrame.js
-- ============================================================================

--[[
    Initialize avatar rendering.
    @param videoActions table  { "idle|待机": { url = "..." }, "talk|说话": { url = "..." } }
    @param options table       { avatarOnlyMode = bool }
    @param callback function(result, err)
]]
function DigitalHumanWebView:initAvatar(videoActions, options, callback)
    if options and options.avatarOnlyMode ~= nil then
        self.avatarOnlyMode = options.avatarOnlyMode;
    end
    self:_rpc(MSG.INIT_AVATAR, { videoActions = videoActions, options = options or {} }, callback);
end

--[[
    Initialize from a config object (character, tools, session, voice, etc.).
    @param config table
    @param callback function(result, err)
]]
function DigitalHumanWebView:initFromConfig(config, callback)
    config = config or {};

    -- Cache character metadata
    self.characterConfig = config;
    self.characterInfo = config.character or {};
    self.initialMessage = (config.initial and config.initial.message) or "";
    self.quickReplies = config.quick_replies or {};
    self.objective = config.objective;
    self.completionMessages = config.completion_messages;
    self.voiceChatConfig = config.voiceChat or {};
    if config.avatar_only then self.avatarOnlyMode = true; end
    if config.workspace then self.workspace = config.workspace; end

    -- Inject NPL tool definitions so the JS AI can discover and call them
    self:_injectNPLToolDefinitions(config);

    self:_rpc(MSG.INIT_FROM_CONFIG, { config = config }, callback);
end

--[[
    Create an AI session.
    @param config table
    @param callback function(result, err)
]]
function DigitalHumanWebView:createSession(config, callback)
    config = config or {};
    if config.workspace then self.workspace = config.workspace; end

    -- Inject NPL tool definitions so the JS AI can discover and call them
    self:_injectNPLToolDefinitions(config);

    self:_rpc(MSG.CREATE_SESSION, { config = config }, callback);
end

--[[
    Send a message — unified send that routes through voice or text on JS side.
    @param userMessage string
    @param options table
    @param callback function(result, err)
]]
function DigitalHumanWebView:send(userMessage, options, callback)
    if not self._sessionReady then
        self._pendingMessages[#self._pendingMessages + 1] = { userMessage = userMessage, options = options, callback = callback };
        return;
    end
    self:_rpc(MSG.SEND, { userMessage = userMessage, options = options or {} }, callback);
end

--[[
    Send a message to the text AI session (bypasses voice even if active).
    @param userMessage string
    @param options table
    @param callback function(result, err)
]]
function DigitalHumanWebView:sendMessage(userMessage, options, callback)
    -- Queue if session not ready yet
    if not self._sessionReady then
        self._pendingMessages[#self._pendingMessages + 1] = { userMessage = userMessage, options = options, callback = callback };
        return;
    end
    self:_rpc(MSG.SEND_MESSAGE, { userMessage = userMessage, options = options or {} }, callback);
end

function DigitalHumanWebView:_flushPendingMessages()
    local pending = self._pendingMessages;
    self._pendingMessages = {};
    for _, item in ipairs(pending) do
        if item.msgType == "boot" then
            self:sendBootMessage(item.bootMessage, item.options, item.callback);
        else
            self:sendMessage(item.userMessage, item.options, item.callback);
        end
    end
end

-- Fire-and-forget avatar control

function DigitalHumanWebView:playAction(actionKey, duration)
    self:_post(MSG.PLAY_ACTION, { actionKey = actionKey, duration = duration or 3 });
end

function DigitalHumanWebView:switchVideo(videoType)
    self:_post(MSG.SWITCH_VIDEO, { videoType = videoType });
end

function DigitalHumanWebView:switchToIdle()
    self:_post(MSG.SWITCH_TO_IDLE);
end

function DigitalHumanWebView:switchToTalking()
    self:_post(MSG.SWITCH_TO_TALKING);
end

function DigitalHumanWebView:setMouthOpen(value)
    self:_post(MSG.SET_MOUTH_OPEN, { value = value });
end

function DigitalHumanWebView:playMotion(preferredGroups, priority)
    self:_post(MSG.PLAY_MOTION, { preferredGroups = preferredGroups, priority = priority });
end

-- RPC queries

function DigitalHumanWebView:getActions(callback)
    self:_rpc(MSG.GET_ACTIONS, {}, function(result, err)
        if callback then
            if err then callback(nil, err); return; end
            callback(result and result.actions or {}, nil);
        end
    end);
end

function DigitalHumanWebView:getAvatarStatus(callback)
    self:_rpc(MSG.GET_AVATAR_STATUS, {}, function(result, err)
        if callback then
            if err then callback(nil, err); return; end
            callback(result and result.status or nil, nil);
        end
    end);
end

function DigitalHumanWebView:getSessionData(callback)
    self:_rpc(MSG.GET_SESSION, {}, function(result, err)
        if callback then
            if err then callback(nil, err); return; end
            callback(result and result.session or nil, nil);
        end
    end);
end

-- Voice chat

function DigitalHumanWebView:startVoiceChat(preset, callback)
    self:_rpc(MSG.START_VOICE_CHAT, { preset = preset or {} }, callback);
end

function DigitalHumanWebView:stopVoiceChat(callback)
    self:_rpc(MSG.STOP_VOICE_CHAT, {}, callback);
end

function DigitalHumanWebView:sendVoiceText(text)
    self:_post(MSG.SEND_VOICE_TEXT, { text = text });
end

function DigitalHumanWebView:muteMicrophone(muted)
    self:_post(MSG.MUTE_MICROPHONE, { muted = muted });
end

--[[
    Update an active voice chat session.
    @param command string     e.g. "ExternalTextToSpeech", "UpdateParameters", "interrupt"
    @param options table      Additional fields (Message, InterruptMode, Parameters, etc.)
    @param callback function(result, err)
]]
function DigitalHumanWebView:updateVoiceChat(command, options, callback)
    self:_rpc(MSG.UPDATE_VOICE_CHAT, {
        command = command,
        options = options or {},
    }, callback);
end

--[[
    Send the configured boot message explicitly after restoring prior history.
    @param bootMessage string  The boot/welcome message text
    @param options table       Additional options
    @param callback function(result, err)
]]
function DigitalHumanWebView:sendBootMessage(bootMessage, options, callback)
    if not self._sessionReady then
        self._pendingMessages[#self._pendingMessages + 1] = {
            msgType = "boot",
            bootMessage = bootMessage,
            options = options,
            callback = callback,
        };
        return;
    end
    self:_rpc(MSG.SEND_BOOT_MESSAGE, {
        bootMessage = bootMessage,
        options = options or {},
    }, callback);
end

--[[
    Send background context to the voice chat LLM.
    Does not trigger a reply — injected as context for the next response.
    @param text string  Context text
]]
function DigitalHumanWebView:sendContext(text)
    self:_post(MSG.SEND_CONTEXT, { text = text });
end

--[[
    Send text to the agent's TTS (text-to-speech) via the WebView voice chat session.
    @param text string
    @param options table  { useREST = bool, interruptMode = number }
]]
function DigitalHumanWebView:sendTTS(text, options)
    self:_post(MSG.SEND_TTS, { text = text, options = options or {} });
end

--[[
    Restart voice chat with optional config overrides (deep-merged into the last preset).
    @param configOverrides table  Partial preset overrides
    @param callback function(result, err)
]]
function DigitalHumanWebView:restartVoiceChat(configOverrides, callback)
    self:_rpc(MSG.RESTART_VOICE_CHAT, { config = configOverrides or {} }, callback);
end

--[[
    Expand an inline system prompt inside the WebView's DigitalHuman session.
    Resolves ${...} template variables against the remote sandbox.
    @param text string
    @param callback function(result, err)  result.text contains the expanded string
]]
function DigitalHumanWebView:expandInlineSystemPrompt(text, callback)
    local rawText = tostring(text or "");
    if rawText == "" then
        if callback then callback({ text = "" }, nil); end
        return;
    end
    self:_rpc(MSG.EXPAND_INLINE_SYSTEM_PROMPT, { text = rawText }, function(result, err)
        if callback then
            if err then callback(nil, err); return; end
            callback({ text = (result and result.text) or rawText }, nil);
        end
    end);
end

--[[
    Load a dedicated summarize agent config into the JS-side DigitalHuman.
    @param config table       The summarize agent configuration object
    @param callback function(result, err)
]]
function DigitalHumanWebView:loadSummarizeAgentConfig(config, callback)
    self:_rpc(MSG.LOAD_SUMMARIZE_AGENT_CONFIG, { config = config }, callback);
end

--[[
    Trigger conversation summarization in the WebView DigitalHuman.
    Only one summarization runs at a time; subsequent calls are queued and merged.
    Listen for the 'summarized' event to receive the result.
    @param options table  { keepRecentRounds = number, mode = "replace"|"append" }
]]
function DigitalHumanWebView:summarize(options)
    if self._summarizing then
        -- Merge: later call's options override earlier ones
        if not self._pendingSummarize then
            self._pendingSummarize = {};
        end
        if options then
            for k, v in pairs(options) do
                self._pendingSummarize[k] = v;
            end
        end
        return;
    end
    self._summarizing = true;
    self._pendingSummarize = nil;
    self:_post(MSG.SUMMARIZE, { options = options or {} });
end

--[[
    Called when the 'summarized' event arrives to drain the queue.
]]
function DigitalHumanWebView:_onSummarizeComplete()
    self._summarizing = false;
    if self._pendingSummarize then
        local next = self._pendingSummarize;
        self._pendingSummarize = nil;
        self:summarize(next);
    end
end

--[[
    Retrieve the current session info from the WebView DigitalHuman.
    @param callback function(session, err)
]]
function DigitalHumanWebView:getSession(callback)
    self:_rpc(MSG.GET_SESSION, {}, function(result, err)
        if callback then
            if err then callback(nil, err); return; end
            callback(result and result.session or nil, nil);
        end
    end);
end

-- ============================================================================
-- Utility
-- ============================================================================

--[[
    Check if the WebView DigitalHuman is ready.
    @return boolean
]]
function DigitalHumanWebView:IsReady()
    return self._ready;
end

--[[
    Resize the WebView.
    @param x number
    @param y number
    @param width number
    @param height number
]]
function DigitalHumanWebView:SetSize(x, y, width, height)
    self.x = x or self.x;
    self.y = y or self.y;
    self.width = width or self.width;
    self.height = height or self.height;
    NPLJS:SetSize(self.x, self.y, self.width, self.height);
end

function DigitalHumanWebView:Hide()
    NPLJS:Hide();
end

function DigitalHumanWebView:Show()
    NPLJS:Show();
end

-- ============================================================================
-- Destroy — cleanup
-- ============================================================================

--[[
    Destroy the DigitalHumanWebView. Sends destroy command, detaches AgentRouter,
    closes NPLJS, and cancels all pending RPCs.
]]
function DigitalHumanWebView:Destroy()
    if self._destroyed then return; end
    self._destroyed = true;

    LOG.std(nil, "info", "DigitalHumanWebView", "Destroying...");

    -- Send destroy to WebView (fire-and-forget, page may already be closing)
    if self._ready then
        pcall(function()
            self:_post(MSG.DESTROY);
        end);
    end

    -- Destroy ToolSandbox (unregisters "paracraft" agent) then detach AgentRouter
    if self._toolSandbox then
        self._toolSandbox:Destroy();
        self._toolSandbox = nil;
    end
    if self._agentRouter then
        self._agentRouter:detach();
        self._agentRouter = nil;
    end

    -- Remove dh-frame message listener
    if self._dhMsgHandler then
        NPLJS:OffMsg(DH_RECV_EVENT, self._dhMsgHandler);
        self._dhMsgHandler = nil;
    end

    -- Close NPLJS WebView
    NPLJS:Close();

    -- Cancel all pending RPCs
    for callId, record in pairs(self._rpcCallbacks) do
        if record.timeoutTimer then
            record.timeoutTimer:Change();
        end
        if record.callback then
            record.callback(nil, "DigitalHumanWebView destroyed");
        end
    end
    self._rpcCallbacks = {};

    -- Clear event listeners
    self._eventListeners = {};

    -- Clear state
    self._ready = false;
    self._sessionReady = false;
    self._openCallback = nil;
    self._pendingMessages = {};

    self:OnDestroy();
    LOG.std(nil, "info", "DigitalHumanWebView", "Destroyed");
end
