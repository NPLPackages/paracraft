--[[
Title: AgentRouter
Author(s): LiXizhi
Date: 2026/03/14
Desc: Lua-side AgentRouter — bidirectional agent routing with auto-adaptive transport.

Each endpoint (BackgroundAgent, DigitalHumanWebView, …) creates its own instance
via AgentRouter:new().

Two transport mechanisms are supported simultaneously:

  NPLJS transport  — Lua ↔ JS WebView page.
                     Must be set up explicitly: router:attachNPLJS(sendEvent, recvEvent).

  NPL bus transport — Lua ↔ Lua, same process, fully automatic.
                     Activated the first time register() or attachNPLJS() is called.
                     Uses a module-level in-process event bus (direct function calls,
                     zero serialization, no NPLJS involved).
                     Routers discover each other through:
                       · Broadcast channel (REGISTER / UNREGISTER / SYNC_REQUEST)
                       · Per-instance direct channels (TASK / TASK_RESULT / STREAM / ACK)

So for Lua-to-Lua routing: just new() + register() — no attachNPL() call needed.
For WebView routing: additionally call attachNPLJS().

Protocol messages carry `is_agent_router = true`.
Message types (mirrors AgentRouter.js MSG constants):
  agent_register        Announce a locally registered agent to remote peers
  agent_register_ack    Acknowledgment (NPLJS transport only)
  agent_register_reject Registration rejected
  agent_unregister      Remove a previously registered agent
  agent_sync_request    Request peers to broadcast their registered agents (NPL bus)
  agent_task            Request to execute a task on a named agent
  agent_task_result     Final result of a task
  agent_stream          Incremental streaming event for an ongoing task

Usage:
------------------------------------------------------------
local AgentRouter = NPL.load("(gl)...AgentRouter.lua");

-- Two routers in the same process discover each other automatically:
local routerA = AgentRouter:new();
routerA:register("agentA", function(taskId, payload, streamCb, doneCb)
    doneCb({ result = "hello from A" });
end);

local routerB = AgentRouter:new();
routerB:register("agentB", handler);
-- routerB now knows about "agentA", routerA knows about "agentB"

routerB:submitTask("agentA", { task = "ping" }, function(result, err)
    print(result.result);  -- "hello from A"
end);

-- For WebView communication, additionally attach NPLJS:
routerA:attachNPLJS("@keepwork_backgroundAgent", "@webparacraft_backgroundAgent");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
local NPLJS = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NPLJS.lua");

local AgentRouter = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

--------------------------------------------------------------------------------
-- Protocol constants
--------------------------------------------------------------------------------

local MSG = {
    REGISTER          = "agent_register",
    REGISTER_ACK      = "agent_register_ack",
    REGISTER_REJECT   = "agent_register_reject",
    UNREGISTER        = "agent_unregister",
    SYNC_REQUEST      = "agent_sync_request",   -- NPL bus: ask peers to re-announce
    SYNC_ACK          = "agent_sync_ack",        -- JS parent/child sync handshake
    WINDOW_DISCONNECT = "agent_window_disconnect", -- remote peer going away
    TASK              = "agent_task",
    TASK_RESULT       = "agent_task_result",
    STREAM            = "agent_stream",
};

local T_NPLJS = "npljs";
local T_NPL   = "npl";

local DEFAULT_TASK_TIMEOUT_MS = 30000;

-- NPL in-process bus: broadcast + per-instance direct channels
local NPL_BC      = "@npl_ar_bc";   -- broadcast (REGISTER / UNREGISTER / SYNC_REQUEST)
local NPL_DIR_PFX = "@npl_ar_";     -- prefix for direct channels  (+ instanceId)

--------------------------------------------------------------------------------
-- Module-level in-process event bus
-- All AgentRouter instances in the same Lua environment share this bus.
-- Calls are synchronous (direct function invocation, no serialization).
--------------------------------------------------------------------------------

local _nplBus = {};  -- eventName → { handler, ... }

local function nplBusFire(eventName, msg)
    local list = _nplBus[eventName];
    if not list then return; end
    for i = 1, #list do
        local ok, err = pcall(list[i], msg);
        if not ok then
            LOG.std(nil, "error", "AgentRouter.nplBus",
                "handler error on '%s': %s", eventName, tostring(err));
        end
    end
end

local function nplBusOn(eventName, handler)
    if not _nplBus[eventName] then _nplBus[eventName] = {}; end
    table.insert(_nplBus[eventName], handler);
end

local function nplBusOff(eventName, handler)
    local list = _nplBus[eventName];
    if not list then return; end
    for i = #list, 1, -1 do
        if list[i] == handler then table.remove(list, i); break; end
    end
end

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------

function AgentRouter:ctor()
    -- Local agents: name → handler function(taskId, payload, streamCb, doneCb)
    self._localAgents = {};

    -- Remote agents: name → { transport="npljs"|"npl", instanceId=string }
    -- instanceId is the peer's AgentRouter._instanceId (needed for NPL direct routing)
    self._remoteAgents = {};

    -- Incoming task origins: taskId → { transport, instanceId }
    -- Tracks where a task came from so replies go back correctly.
    self._incomingTaskOrigins = {};

    -- Pending outgoing tasks: taskId → { callback, onStream, timeoutTimer }
    self._pendingTasks = {};

    -- Unique instance ID (also used as the NPL direct-channel suffix)
    self._instanceId = nil;

    -- Task ID counter
    self._taskCounter = 0;

    -- NPLJS transport (nil when not attached)
    self._npljs = nil;  -- { sendEventName, recvEventName }

    -- NPL bus state (nil until _ensureNPLBus() is called)
    self._nplBus = nil; -- { bcHandler, dirHandler, directEvent }
end

--------------------------------------------------------------------------------
-- Internal helpers
--------------------------------------------------------------------------------

local function generateInstanceId()
    return string.format("lua_%s_%d_%d",
        os.date("%H%M%S"), os.time(), math.random(100000, 999999));
end

local function generateTaskId(self)
    self._taskCounter = self._taskCounter + 1;
    return string.format("lua_task_%d_%d", os.time(), self._taskCounter);
end

-- Ensure instance ID is initialised
local function ensureInstanceId(self)
    if not self._instanceId then
        self._instanceId = generateInstanceId();
    end
end

-- Low-level send helpers -------------------------------------------------------

local function sendNPLJS(self, msg)
    if not self._npljs or not NPLJS then return; end
    msg.is_agent_router = true;
    msg.instanceId = self._instanceId;
    local ok, err = pcall(function()
        NPLJS:SendMsg(self._npljs.sendEventName, msg, nil, nil, nil, nil, true);
    end);
    if not ok then
        LOG.std(nil, "error", "AgentRouter", "sendNPLJS failed: %s msgType=%s",
            tostring(err), tostring(msg.type));
    end
end

-- Broadcast on NPL bus (REGISTER / UNREGISTER / SYNC_REQUEST)
local function sendNPLBroadcast(self, msg)
    if not self._nplBus then return; end
    msg.is_agent_router = true;
    msg.instanceId = self._instanceId;
    nplBusFire(NPL_BC, msg);
end

-- Direct NPL message to a specific peer instance
local function sendNPLDirect(self, msg, targetInstanceId)
    if not targetInstanceId then return; end
    msg.is_agent_router = true;
    msg.instanceId = self._instanceId;
    nplBusFire(NPL_DIR_PFX .. targetInstanceId, msg);
end

-- Generic send: routes to ALL attached transports (broadcast semantics)
-- Used for REGISTER / UNREGISTER when announcing to every connected peer.
local function sendAll(self, msg)
    sendNPLJS(self, msg);
    sendNPLBroadcast(self, msg);
end

--------------------------------------------------------------------------------
-- NPL auto-bus — lazy initialisation
--------------------------------------------------------------------------------

--[[
    Join the in-process NPL bus.
    Called automatically the first time register() or attachNPLJS() is used.
    Sets up:
      · Broadcast listener: receives REGISTER / UNREGISTER / SYNC_REQUEST from peers
      · Direct listener:    receives TASK / TASK_RESULT / STREAM / REGISTER_ACK
    Then broadcasts a SYNC_REQUEST so that already-running peers announce their agents.
]]
function AgentRouter:_ensureNPLBus()
    if self._nplBus then return; end
    ensureInstanceId(self);

    local self_ = self;

    -- Broadcast channel: discovery messages
    local bcHandler = function(msg)
        if type(msg) ~= "table" then return; end
        if not msg.is_agent_router then return; end
        if msg.instanceId == self_._instanceId then return; end  -- skip own echo
        local t = msg.type;
        if t == MSG.REGISTER or t == MSG.UNREGISTER then
            self_:_onMessage(msg, T_NPL);
        elseif t == MSG.SYNC_REQUEST then
            self_:_handleSyncRequest(msg);
        end
    end;
    nplBusOn(NPL_BC, bcHandler);

    -- Direct channel: task / result / ack messages addressed to this instance
    local directEvent = NPL_DIR_PFX .. self._instanceId;
    local dirHandler = function(msg)
        if type(msg) ~= "table" then return; end
        if not msg.is_agent_router then return; end
        self_:_onMessage(msg, T_NPL);
    end;
    nplBusOn(directEvent, dirHandler);

    self._nplBus = { bcHandler = bcHandler, dirHandler = dirHandler, directEvent = directEvent };

    LOG.std(nil, "info", "AgentRouter", "NPL bus joined: direct=%s id=%s",
        directEvent, self._instanceId);

    -- Ask all existing peers to re-announce their agents to us
    local syncMsg = { type = MSG.SYNC_REQUEST, replyTo = self._instanceId,
                      is_agent_router = true, instanceId = self._instanceId };
    nplBusFire(NPL_BC, syncMsg);
end

--[[
    Leave the NPL auto-bus.
    Announces unregister for all local agents, then removes listeners.
]]
function AgentRouter:_leaveNPLBus()
    if not self._nplBus then return; end

    -- Announce our departure
    for agentName, _ in pairs(self._localAgents) do
        sendNPLBroadcast(self, { type = MSG.UNREGISTER, agentName = agentName });
    end

    nplBusOff(NPL_BC, self._nplBus.bcHandler);
    nplBusOff(self._nplBus.directEvent, self._nplBus.dirHandler);

    -- Remove remote agents discovered via NPL
    for name, info in pairs(self._remoteAgents) do
        if info.transport == T_NPL then self._remoteAgents[name] = nil; end
    end

    LOG.std(nil, "info", "AgentRouter", "NPL bus left (was direct=%s)", self._nplBus.directEvent);
    self._nplBus = nil;
end

--[[
    Handle SYNC_REQUEST: a new peer joined and wants to learn about our agents.
    Send a direct REGISTER for each local agent to the requester.
]]
function AgentRouter:_handleSyncRequest(msg)
    local replyTo = msg.replyTo or msg.instanceId;
    if not replyTo or replyTo == self._instanceId then return; end
    for agentName, _ in pairs(self._localAgents) do
        sendNPLDirect(self, { type = MSG.REGISTER, agentName = agentName }, replyTo);
    end
end

--------------------------------------------------------------------------------
-- NPLJS transport — explicit attachment for WebView communication
--------------------------------------------------------------------------------

--[[
    Attach the NPLJS transport for communicating with a WebView JS page.
    Safe to call again with the same args (idempotent).
    Also triggers NPL bus initialisation so this router is discoverable by Lua peers.
    @param sendEventName string  Lua→JS event name (e.g. "@keepwork_dhAgent")
    @param recvEventName string  JS→Lua event name (e.g. "@webparacraft_dhAgent")
    @return self
]]
function AgentRouter:attachNPLJS(sendEventName, recvEventName)
    if self._npljs
        and self._npljs.sendEventName == sendEventName
        and self._npljs.recvEventName == recvEventName then
        return self;
    end

    self:detachNPLJS();
    ensureInstanceId(self);
    self:_ensureNPLBus();

    if not NPLJS then
        LOG.std(nil, "warn", "AgentRouter", "attachNPLJS: NPLJS not available");
        return self;
    end

    self._npljs = { sendEventName = sendEventName, recvEventName = recvEventName };

    local self_ = self;
    NPLJS:OnMsg(recvEventName, function(msgdata, msgid)
        if type(msgdata) ~= "table" then return; end
        if not msgdata.is_agent_router then return; end
        self_:_onMessage(msgdata, T_NPLJS);
    end);

    -- Announce all local agents to the newly loaded WebView page
    for agentName, _ in pairs(self._localAgents) do
        sendNPLJS(self, { type = MSG.REGISTER, agentName = agentName });
    end

    LOG.std(nil, "info", "AgentRouter", "NPLJS attached: send=%s recv=%s id=%s",
        sendEventName, recvEventName, self._instanceId);
    return self;
end

--[[
    Detach the NPLJS transport.
    Announces unregister to the WebView, removes NPLJS listener.
    Remote agents discovered via NPLJS are removed from the routing table.
]]
function AgentRouter:detachNPLJS()
    if not self._npljs then return; end

    for agentName, _ in pairs(self._localAgents) do
        sendNPLJS(self, { type = MSG.UNREGISTER, agentName = agentName });
    end

    if NPLJS then NPLJS:OffMsg(self._npljs.recvEventName); end

    for name, info in pairs(self._remoteAgents) do
        if info.transport == T_NPLJS then self._remoteAgents[name] = nil; end
    end

    LOG.std(nil, "info", "AgentRouter", "NPLJS detached (was send=%s)",
        self._npljs.sendEventName);
    self._npljs = nil;
end

--[[
    Detach ALL transports and cancel all pending outgoing tasks.
    Backward-compatible with the old single-channel detach().
]]
function AgentRouter:detach()
    -- Cancel pending outgoing tasks
    for taskId, record in pairs(self._pendingTasks) do
        if record.timeoutTimer then record.timeoutTimer:Change(); end
        if record.callback then record.callback(nil, "AgentRouter detached"); end
    end
    self._pendingTasks = {};

    self:detachNPLJS();
    self:_leaveNPLBus();

    self._remoteAgents = {};
    LOG.std(nil, "info", "AgentRouter", "All transports detached");
end

--[[
    Backward-compat alias — delegates to attachNPLJS().
]]
function AgentRouter:attach(sendEventName, recvEventName)
    return self:attachNPLJS(sendEventName, recvEventName);
end

--------------------------------------------------------------------------------
-- Public API — agent registration and task submission
--------------------------------------------------------------------------------

--[[
    Register a local agent handler.
    Automatically joins the NPL bus on first call so Lua peers can discover this agent.
    Broadcasts agent_register to all attached transports.
    @param agentName string  Unique agent name
    @param handler   function(taskId, payload, streamCb, doneCb)
    @return boolean  true if registered; false if name already taken locally
]]
function AgentRouter:register(agentName, handler)
    if not agentName or not handler then return false; end

    if self._localAgents[agentName] then
        LOG.std(nil, "warn", "AgentRouter", "Agent '%s' already registered locally", agentName);
        return false;
    end

    ensureInstanceId(self);
    self:_ensureNPLBus();  -- auto-join NPL bus on first registration

    self._localAgents[agentName] = handler;
    LOG.std(nil, "info", "AgentRouter", "Registered local agent '%s'", agentName);

    -- Announce to all transports
    sendAll(self, { type = MSG.REGISTER, agentName = agentName });

    return true;
end

--[[
    Unregister a local agent and broadcast removal to all transports.
    @param agentName string
]]
function AgentRouter:unregister(agentName)
    if not self._localAgents[agentName] then return; end

    self._localAgents[agentName] = nil;
    LOG.std(nil, "info", "AgentRouter", "Unregistered local agent '%s'", agentName);

    sendAll(self, { type = MSG.UNREGISTER, agentName = agentName });
end

--[[
    Check if a named agent exists (local or remote, any transport).
]]
function AgentRouter:hasAgent(agentName)
    return self._localAgents[agentName] ~= nil or self._remoteAgents[agentName] ~= nil;
end

--[[
    Check if a named agent is known as a remote peer (not locally registered).
]]
function AgentRouter:hasRemoteAgent(agentName)
    return self._localAgents[agentName] == nil and self._remoteAgents[agentName] ~= nil;
end

--[[
    Submit a task to a remote agent.
    Transport is chosen automatically based on where the agent was discovered.
    @param agentName string   Target agent name
    @param payload   table    { prompt, systemPrompt, tools, maxIterations, model, ... }
    @param callback  function(result, errMsg)
    @param onStream  function(streamType, content) [optional]
    @return string|nil  taskId or nil if no route found
]]
function AgentRouter:submitTask(agentName, payload, callback, onStream)
    local remoteInfo = self._remoteAgents[agentName];
    if not remoteInfo then
        LOG.std(nil, "warn", "AgentRouter", "submitTask: no remote route to '%s'", agentName);
        if callback then
            callback(nil, string.format("No remote agent '%s' registered", agentName));
        end
        return nil;
    end

    local taskId = generateTaskId(self);

    local self_ = self;
    local timeoutTimer = commonlib.Timer:new({
        callbackFunc = function()
            local record = self_._pendingTasks[taskId];
            if record then
                self_._pendingTasks[taskId] = nil;
                LOG.std(nil, "warn", "AgentRouter", "Task '%s' to '%s' timed out", taskId, agentName);
                if record.callback then
                    record.callback(nil, string.format("Task timed out after %dms", DEFAULT_TASK_TIMEOUT_MS));
                end
            end
        end
    });
    timeoutTimer:Change(DEFAULT_TASK_TIMEOUT_MS, nil);

    self._pendingTasks[taskId] = {
        agentName    = agentName,
        callback     = callback,
        onStream     = onStream,
        timeoutTimer = timeoutTimer,
        createdAt    = os.time(),
    };

    LOG.std(nil, "info", "AgentRouter", "submitTask taskId=%s agent='%s' transport=%s",
        taskId, agentName, remoteInfo.transport);

    local taskMsg = {
        type             = MSG.TASK,
        taskId           = taskId,
        agentName        = agentName,
        payload          = payload,
        sourceInstanceId = self._instanceId,
    };

    if remoteInfo.transport == T_NPLJS then
        sendNPLJS(self, taskMsg);
    elseif remoteInfo.transport == T_NPL then
        sendNPLDirect(self, taskMsg, remoteInfo.instanceId);
    end

    return taskId;
end

--[[
    Re-announce all locally registered agents to a specific or all transports.
    Useful after a WebView page reload resets the JS side.
    @param transport string|nil  "npljs" | "npl" | nil (= all)
]]
function AgentRouter:reannounceLocalAgents(transport)
    for agentName, _ in pairs(self._localAgents) do
        if transport == T_NPLJS or transport == nil then
            sendNPLJS(self, { type = MSG.REGISTER, agentName = agentName });
        end
        if transport == T_NPL or transport == nil then
            sendNPLBroadcast(self, { type = MSG.REGISTER, agentName = agentName });
        end
    end
end

--[[
    Return the list of known remote agent names.
]]
function AgentRouter:getRemoteAgentNames()
    local names = {};
    for name, _ in pairs(self._remoteAgents) do table.insert(names, name); end
    return names;
end

--[[
    Return the list of locally registered agent names.
]]
function AgentRouter:getLocalAgentNames()
    local names = {};
    for name, _ in pairs(self._localAgents) do table.insert(names, name); end
    return names;
end

--------------------------------------------------------------------------------
-- Internal message dispatcher
--------------------------------------------------------------------------------

--[[
    Main incoming message handler.
    @param msg           table   Protocol message
    @param transportName string  "npljs" | "npl"
]]
function AgentRouter:_onMessage(msg, transportName)
    local msgType = msg.type;
    if not msgType then return; end
    LOG.std(nil, "debug", "AgentRouter", "_onMessage type=%s transport=%s",
        tostring(msgType), tostring(transportName));
    if msgType == MSG.REGISTER then
        self:_handleRegister(msg, transportName);
    elseif msgType == MSG.REGISTER_ACK then
        self:_handleRegisterAck(msg);
    elseif msgType == MSG.REGISTER_REJECT then
        self:_handleRegisterReject(msg);
    elseif msgType == MSG.UNREGISTER then
        self:_handleUnregister(msg);
    elseif msgType == MSG.SYNC_ACK then
        self:_handleSyncAck(msg, transportName);
    elseif msgType == MSG.WINDOW_DISCONNECT then
        self:_handleWindowDisconnect(msg, transportName);
    elseif msgType == MSG.TASK then
        self:_handleTask(msg, transportName);
    elseif msgType == MSG.TASK_RESULT then
        self:_handleTaskResult(msg);
    elseif msgType == MSG.STREAM then
        self:_handleStream(msg);
    else
        LOG.std(nil, "warn", "AgentRouter", "Unknown message type: %s", tostring(msgType));
    end
end

--[[
    Handle agent_register.
    Records the remote agent and its transport+instanceId for direct routing.
]]
function AgentRouter:_handleRegister(msg, transportName)
    local agentName = msg.agentName;
    if not agentName then return; end

    if self._localAgents[agentName] then
        -- Name collision — reject
        if transportName == T_NPLJS then
            sendNPLJS(self, { type = MSG.REGISTER_REJECT, agentName = agentName,
                reason = string.format("Agent '%s' already registered locally", agentName) });
        elseif transportName == T_NPL then
            sendNPLDirect(self, { type = MSG.REGISTER_REJECT, agentName = agentName,
                reason = string.format("Agent '%s' already registered locally", agentName) },
                msg.instanceId);
        end
        return;
    end

    self._remoteAgents[agentName] = { transport = transportName, instanceId = msg.instanceId };
    LOG.std(nil, "info", "AgentRouter", "Discovered remote agent '%s' via %s (peer=%s)",
        agentName, transportName, tostring(msg.instanceId));

    -- For NPLJS: ACK + backfill (JS side needs it for reliability)
    if transportName == T_NPLJS and not msg.syncBackfill then
        sendNPLJS(self, { type = MSG.REGISTER_ACK, agentName = agentName });
        for localName, _ in pairs(self._localAgents) do
            sendNPLJS(self, { type = MSG.REGISTER, agentName = localName, syncBackfill = true });
        end
    end

    -- For NPL direct messages (backfill responses from _handleSyncRequest / explicit):
    -- No ACK needed since NPL bus calls are synchronous.
end

function AgentRouter:_handleRegisterAck(msg)
    LOG.std(nil, "info", "AgentRouter", "Registration of '%s' acknowledged", tostring(msg.agentName));
end

function AgentRouter:_handleRegisterReject(msg)
    LOG.std(nil, "warn", "AgentRouter", "Registration of '%s' rejected: %s",
        tostring(msg.agentName), tostring(msg.reason));
end

function AgentRouter:_handleUnregister(msg)
    local agentName = msg.agentName;
    if agentName and self._remoteAgents[agentName] then
        self._remoteAgents[agentName] = nil;
        LOG.std(nil, "info", "AgentRouter", "Remote agent '%s' unregistered", agentName);
    end
end

--[[
    Handle agent_sync_ack — JS parent sends this (request=true) to confirm the
    child received the agent list.  We echo back a confirmation (request=false)
    so the JS side stops its retry loop.
]]
function AgentRouter:_handleSyncAck(msg, transportName)
    if msg.request then
        -- JS parent is asking us to confirm we got the agent list — send ack back
        if transportName == T_NPLJS then
            sendNPLJS(self, { type = MSG.SYNC_ACK, syncId = msg.syncId, request = false });
            LOG.std(nil, "debug", "AgentRouter", "SyncAck confirmed to JS (syncId=%s)", tostring(msg.syncId));
        end
    else
        -- Confirmation from child — nothing to do on the Lua side (JS owns retry logic)
        LOG.std(nil, "debug", "AgentRouter", "SyncAck received from child (syncId=%s)", tostring(msg.syncId));
    end
end

--[[
    Handle agent_window_disconnect — remote JS peer is going away.
    Remove all remote agents that were registered via that peer.
]]
function AgentRouter:_handleWindowDisconnect(msg, transportName)
    LOG.std(nil, "info", "AgentRouter", "Remote peer disconnected (instanceId=%s transport=%s)",
        tostring(msg.instanceId), tostring(transportName));
    -- Remove all remote agents that came from this peer/transport
    local removed = {};
    for agentName, info in pairs(self._remoteAgents) do
        if info.transport == transportName then
            table.insert(removed, agentName);
        end
    end
    for _, agentName in ipairs(removed) do
        self._remoteAgents[agentName] = nil;
        LOG.std(nil, "info", "AgentRouter", "Removed remote agent '%s' after peer disconnect", agentName);
    end
end

--[[
    Handle agent_task.
    Executes locally if we own the agent.
    Records origin so streamCb / doneCb reply via the correct transport.
]]
function AgentRouter:_handleTask(msg, transportName)
    local taskId    = msg.taskId;
    local agentName = msg.agentName;
    local payload   = msg.payload or {};

    if not taskId or not agentName then return; end

    LOG.std(nil, "info", "AgentRouter", "_handleTask taskId=%s agent='%s' transport=%s",
        taskId, agentName, tostring(transportName));

    local handler = self._localAgents[agentName];
    if not handler then
        -- No handler — reply with error
        local errMsg = { type = MSG.TASK_RESULT, taskId = taskId, result = nil,
                         error = string.format("Agent '%s' not found on Lua side", agentName),
                         sourceInstanceId = self._instanceId };
        if transportName == T_NPLJS then
            sendNPLJS(self, errMsg);
        elseif transportName == T_NPL then
            sendNPLDirect(self, errMsg, msg.sourceInstanceId);
        end
        return;
    end

    -- Record task origin so replies are routed correctly
    self._incomingTaskOrigins[taskId] = {
        transport   = transportName,
        instanceId  = msg.sourceInstanceId,  -- originator's instanceId
    };

    local function streamCb(streamType, content)
        local origin = self._incomingTaskOrigins[taskId];
        if not origin then return; end
        local streamMsg = { type = MSG.STREAM, taskId = taskId,
                            streamType = streamType, content = content,
                            sourceInstanceId = self._instanceId };
        if origin.transport == T_NPLJS then
            sendNPLJS(self, streamMsg);
        elseif origin.transport == T_NPL then
            sendNPLDirect(self, streamMsg, origin.instanceId);
        end
    end

    local function doneCb(result, errMsg)
        LOG.std(nil, "info", "AgentRouter", "doneCb taskId=%s resultType=%s err=%s",
            taskId, type(result), tostring(errMsg or "nil"));
        local origin = self._incomingTaskOrigins[taskId];
        self._incomingTaskOrigins[taskId] = nil;
        if not origin then return; end
        local resultMsg = { type = MSG.TASK_RESULT, taskId = taskId,
                            result = result, error = errMsg,
                            sourceInstanceId = self._instanceId };
        if origin.transport == T_NPLJS then
            sendNPLJS(self, resultMsg);
        elseif origin.transport == T_NPL then
            sendNPLDirect(self, resultMsg, origin.instanceId);
        end
    end

    local ok, err = pcall(handler, taskId, payload, streamCb, doneCb);
    if not ok then
        LOG.std(nil, "error", "AgentRouter", "_handleTask handler error: %s", tostring(err));
        doneCb(nil, tostring(err));
    end
end

function AgentRouter:_handleTaskResult(msg)
    local taskId = msg.taskId;
    if not taskId then return; end

    local record = self._pendingTasks[taskId];
    if not record then
        LOG.std(nil, "warn", "AgentRouter", "_handleTaskResult dropped taskId=%s: no record", taskId);
        return;
    end

    if record.timeoutTimer then record.timeoutTimer:Change(); end
    self._pendingTasks[taskId] = nil;

    LOG.std(nil, "info", "AgentRouter", "_handleTaskResult taskId=%s error=%s",
        taskId, tostring(msg.error or "none"));

    if record.callback then
        if msg.error and msg.error ~= "" then
            record.callback(nil, msg.error);
        else
            record.callback(msg.result, nil);
        end
    end
end

function AgentRouter:_handleStream(msg)
    local taskId = msg.taskId;
    if not taskId then return; end

    local record = self._pendingTasks[taskId];
    if not record then
        LOG.std(nil, "debug", "AgentRouter", "_handleStream dropped taskId=%s: no record", taskId);
        return;
    end

    if record.onStream then
        LOG.std(nil, "debug", "AgentRouter", "_handleStream taskId=%s streamType=%s",
            taskId, tostring(msg.streamType));
        record.onStream(msg.streamType, msg.content);
    end
end
