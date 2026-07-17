--[[
Title: BackgroundAgent WebSocket Server
Author: LiXizhi
Date: 2026/2/20
Desc: Pushes BackgroundAgent state changes to all connected browser clients.
  Browser connects via: ws://<host>/ajax/raw?file=script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/bg_agent.page&action=handshake
  Browser sends commands as: {filename: "...bg_agent_ws_server.lua", action: "<cmd>", ...params}
  Server pushes typed events: {type: "init|status|chat|llm|vision|voice|progress|...", data: {...}}

  All clients with nid prefix "ws_bgagent_" are managed here.
  Signal connections to BackgroundAgent are established lazily after the first client connects.
]]

NPL.load("(gl)script/ide/System/os/network/WebSocket/WebSocketServer.lua");
local WebSocketServer = commonlib.gettable("System.os.network.WebSocketServer");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/BackgroundAgent.lua");
local BackgroundAgent = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BackgroundAgent");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/SceneVisionManager.lua");
local SceneVisionManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.SceneVisionManager");

local BgAgentWS = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

-- Prefix used to identify bg_agent WebSocket clients inside WebSocketServer.clients
BgAgentWS.WS_PREFIX = "ws_bgagent_";

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function GetAgent()
    return BackgroundAgent:GetInstance();
end

local function BuildStatus()
    local agent = GetAgent();
    if not agent then return {error = "no agent"} end
    local ttsStatus = agent:GetTTSQueueStatus();
    local status = {
        playbackState     = agent:GetPlaybackState(),
        debugEnabled      = agent:IsDebugEnabled(),
        stepInProgress    = agent:IsStepInProgress(),
        isEnabled         = agent:IsEnabled(),
        isObservationMode = agent:IsObservationMode(),
        autoSpeakEnabled  = agent:IsAutoSpeakEnabled(),
        isTTSPlaying      = ttsStatus and ttsStatus.isPlaying or false,
        hasTask           = agent:GetPrimaryLearningTask() ~= nil,
        chatCount         = agent:GetChatMessageCount(),
        llmCount          = agent:GetLLMHistoryCount(),
        voicePending      = agent:GetPendingVoiceCount(),
        tts               = ttsStatus,
        uiToolQueue       = agent:GetUIToolQueueStatus(),
    };
    status.sceneVisionPassiveMode = SceneVisionManager.passiveMode or false;
    local task = agent:GetPrimaryLearningTask();
    if task then
        status.taskId   = task.id;
        status.taskText = task.text;
    end
    local progress = agent:GetLearningProgress();
    if progress then
        status.learningPercentage = progress.learningPercentage;
        status.totalAttempts      = progress.totalAttempts;
        status.totalCorrect       = progress.totalCorrect;
    end
    return status;
end

local function BuildChat()
    local agent = GetAgent();
    if not agent then return {} end
    local msgs = agent:GetChatMessageHistory() or {};
    local out = {};
    for _, m in ipairs(msgs) do
        out[#out+1] = {role = m.role, content = m.content, timestamp = m.timestamp, isComplete = m.isComplete};
    end
    return out;
end

local function BuildLLM(max)
    local agent = GetAgent();
    if not agent then return {} end
    max = max or 30;
    local count  = agent:GetLLMHistoryCount();
    local entries = {};
    local startIdx = math.max(1, count - max + 1);
    for i = startIdx, count do
        local e = agent:GetFormattedLLMEntry(i);
        if e then entries[#entries+1] = e; end
    end
    return entries;
end

local function BuildVision(max)
    local agent = GetAgent();
    if not agent then return {} end
    max = max or 30;
    local history = agent:GetSceneVisionHistory() or {};
    local out = {};
    local startIdx = math.max(1, #history - max + 1);
    for i = startIdx, #history do
        local e = history[i];
        if e then out[#out+1] = {timestamp = e.timestamp, imageUrl = e.imageUrl, description = e.description, imagePath = e.imagePath}; end
    end
    return out;
end

local function BuildVoice(max)
    local agent = GetAgent();
    if not agent then return {} end
    max = max or 30;
    local history = agent:GetVoiceHistory() or {};
    local out = {};
    local startIdx = math.max(1, #history - max + 1);
    for i = startIdx, #history do
        local e = history[i];
        if e then out[#out+1] = {timestamp = e.timestamp, transcript = e.transcript, confidence = e.confidence}; end
    end
    return out;
end

-- Push a message to all connected bg_agent clients
local function Push(data)
    WebSocketServer:Broadcast(data, nil, BgAgentWS.WS_PREFIX);
end

-- ─── Signal subscriptions ─────────────────────────────────────────────────────

BgAgentWS.signalsConnected = false;

function BgAgentWS:ConnectSignals()
    if self.signalsConnected then return; end
    local agent = GetAgent();
    if not agent then return; end
    self.signalsConnected = true;

    local function pushStatus()
        Push({type = "status", data = BuildStatus()});
    end

    -- Playback state changes
    agent:Connect("played",             self, pushStatus);
    agent:Connect("paused",             self, pushStatus);
    agent:Connect("stopped",            self, pushStatus);
    agent:Connect("stepped",            self, pushStatus);
    agent:Connect("primaryTaskChanged", self, pushStatus);
    agent:Connect("toolExecuted",       self, pushStatus);
    agent:Connect("ttsStarted",         self, pushStatus);
    agent:Connect("ttsCompleted",       self, pushStatus);

    -- Chat content update (also refreshes status for counts)
    agent:Connect("chatContentUpdate", self, function()
        Push({type = "chat", data = {messages = BuildChat()}});
        pushStatus();
    end);

    -- LLM response received: refresh chat + LLM list + status
    agent:Connect("llmResponseReceived", self, function()
        Push({type = "llm",  data = {entries  = BuildLLM()}});
        Push({type = "chat", data = {messages = BuildChat()}});
        pushStatus();
    end);

    -- Learning progress update
    agent:Connect("progressUpdate", self, function()
        local a = GetAgent();
        if a then
            Push({type = "progress", data = {summary = a:GetLearningProgressSummary()}});
        end
        pushStatus();
    end);

    -- Scene context / screenshot captured
    agent:Connect("sceneContextCaptured", self, function()
        Push({type = "vision", data = {entries = BuildVision()}});
    end);

    LOG.std(nil, "info", "BgAgentWS", "Connected to BackgroundAgent signals");
end

-- ─── Initial snapshot sent on connect ────────────────────────────────────────

local function SendInitSnapshot(nid)
    local agent = GetAgent();
    if not agent then
        WebSocketServer:Send(nid, {type = "error", msg = "BackgroundAgent not running"});
        return;
    end
    local copilots = agent:GetDiscoveredCopilots() or {};
    local copilotsOut = {};
    for _, c in ipairs(copilots) do
        copilotsOut[#copilotsOut+1] = {name = c.name, displayName = c.displayName, toolCount = c.tools and #c.tools or 0};
    end
    WebSocketServer:Send(nid, {
        type     = "init",
        status   = BuildStatus(),
        chat     = BuildChat(),
        llm      = BuildLLM(),
        vision   = BuildVision(),
        voice    = BuildVoice(),
        tools    = agent:GetAllToolDefinitions() or {},
        copilots = copilotsOut,
        progress = {summary = agent:GetLearningProgressSummary()},
    });
end

-- ─── Incoming command handler ─────────────────────────────────────────────────

function BgAgentWS:OnActivate(msg)
    if not msg or not msg.nid then return; end
    local nid    = msg.nid;
    local action = msg.action;

    -- Disconnection: empty payload is handled by WebSocketServer itself before reaching here,
    -- but handle nil action gracefully.
    if not action then return; end

    local agent = GetAgent();
    if not agent then
        WebSocketServer:Send(nid, {type = "error", msg = "no agent"});
        return;
    end

    -- Lazily connect signals once an agent is available
    self:ConnectSignals();

    -- ── Playback controls ──────────────────────────────────────────────────────
    if action == "play" then
        agent:Play();
        WebSocketServer:Send(nid, {type = "status", data = BuildStatus()});

    elseif action == "pause" then
        agent:Pause();
        WebSocketServer:Send(nid, {type = "status", data = BuildStatus()});

    elseif action == "stop" then
        agent:Stop();
        WebSocketServer:Send(nid, {type = "status", data = BuildStatus()});

    elseif action == "step" then
        agent:Step();
        WebSocketServer:Send(nid, {type = "ack", action = "step"});

    -- ── Chat ──────────────────────────────────────────────────────────────────
    elseif action == "send_message" then
        local text = msg.text;
        if text and text ~= "" then
            agent.waitingForUserReply = false;
            agent.waitingForUserReplyStartTime = nil;
            agent:ProcessWithLLM(text, function() end);
        end
        WebSocketServer:Send(nid, {type = "ack", action = "send_message"});

    elseif action == "clear_chat" then
        agent:ClearChatHistory();
        Push({type = "chat", data = {messages = {}}});

    -- ── LLM history ───────────────────────────────────────────────────────────
    elseif action == "clear_llm_history" then
        agent:ClearLLMHistory();
        Push({type = "llm", data = {entries = {}}});

    -- ── Task ──────────────────────────────────────────────────────────────────
    elseif action == "set_task" then
        local options = {};
        if msg.soul then options.soul = msg.soul; end
        if msg.sop then options.sop = msg.sop; end
        agent:SetPrimaryLearningTask(msg.text or "", options);
        WebSocketServer:Send(nid, {type = "status", data = BuildStatus()});

    -- ── Toggle flags ──────────────────────────────────────────────────────────
    elseif action == "set_debug_enabled" then
        agent:SetDebugEnabled(msg.enabled == true or msg.enabled == "1" or msg.enabled == "true");
        WebSocketServer:Send(nid, {type = "status", data = BuildStatus()});

    elseif action == "set_observation_mode" then
        agent:SetObservationMode(msg.enabled == true or msg.enabled == "1" or msg.enabled == "true");
        WebSocketServer:Send(nid, {type = "status", data = BuildStatus()});

    elseif action == "set_auto_speak" then
        agent:SetAutoSpeakEnabled(msg.enabled == true or msg.enabled == "1" or msg.enabled == "true");
        WebSocketServer:Send(nid, {type = "status", data = BuildStatus()});

    elseif action == "set_scene_vision_passive" then
        local enabled = msg.enabled == true or msg.enabled == "1" or msg.enabled == "true";
        local svm = SceneVisionManager:GetInstance();
        if svm then svm:SetPassiveMode(enabled); end
        WebSocketServer:Send(nid, {type = "status", data = BuildStatus()});

    -- ── Observation ───────────────────────────────────────────────────────────
    elseif action == "trigger_observation" then
        agent:TriggerProactiveObservation();
        WebSocketServer:Send(nid, {type = "ack", action = "trigger_observation"});

    -- ── TTS ───────────────────────────────────────────────────────────────────
    elseif action == "tts_stop" then
        agent:StopTTS();
        WebSocketServer:Send(nid, {type = "status", data = BuildStatus()});

    elseif action == "tts_clear_queue" then
        agent:ClearTTSQueue();
        WebSocketServer:Send(nid, {type = "status", data = BuildStatus()});

    -- ── UI tool queue ─────────────────────────────────────────────────────────
    elseif action == "clear_uitool_queue" then
        agent:ClearUIToolQueue();
        WebSocketServer:Send(nid, {type = "status", data = BuildStatus()});

    -- ── Scene / voice history clear ───────────────────────────────────────────
    elseif action == "clear_scene_vision" then
        agent:ClearSceneVisionHistory();
        Push({type = "vision", data = {entries = {}}});

    elseif action == "clear_voice_history" then
        agent:ClearVoiceHistory();
        Push({type = "voice", data = {entries = {}}});

    -- ── Copilots ──────────────────────────────────────────────────────────────
    elseif action == "refresh_copilots" then
        agent:RefreshCopilots();
        local copilots = agent:GetDiscoveredCopilots() or {};
        local out = {};
        for _, c in ipairs(copilots) do
            out[#out+1] = {name = c.name, displayName = c.displayName, toolCount = c.tools and #c.tools or 0};
        end
        WebSocketServer:Send(nid, {type = "copilots", data = {copilots = out}});

    elseif action == "get_copilots" then
        local copilots = agent:GetDiscoveredCopilots() or {};
        local out = {};
        for _, c in ipairs(copilots) do
            out[#out+1] = {name = c.name, displayName = c.displayName, toolCount = c.tools and #c.tools or 0};
        end
        WebSocketServer:Send(nid, {type = "copilots", data = {copilots = out}});

    -- ── Tools ─────────────────────────────────────────────────────────────────
    elseif action == "get_tools" then
        WebSocketServer:Send(nid, {type = "tools", data = {tools = agent:GetAllToolDefinitions() or {}}});

    -- ── Learning progress ─────────────────────────────────────────────────────
    elseif action == "reset_learning_progress" then
        agent:ResetLearningProgress();
        WebSocketServer:Send(nid, {type = "progress", data = {summary = agent:GetLearningProgressSummary()}});

    elseif action == "save_learning_state" then
        agent:SaveLearningState();
        WebSocketServer:Send(nid, {type = "ack", action = "save_learning_state", success = true});

    elseif action == "load_learning_state" then
        local ok = agent:LoadLearningState(msg.taskId ~= "" and msg.taskId or nil);
        WebSocketServer:Send(nid, {type = "progress", data = {summary = agent:GetLearningProgressSummary()}, loadOk = ok});
        WebSocketServer:Send(nid, {type = "status", data = BuildStatus()});

    elseif action == "clear_learning_state" then
        agent:ClearLearningState(msg.taskId ~= "" and msg.taskId or nil);
        WebSocketServer:Send(nid, {type = "ack", action = "clear_learning_state"});

    elseif action == "get_learning_progress" then
        WebSocketServer:Send(nid, {type = "progress", data = {summary = agent:GetLearningProgressSummary(), progress = agent:GetLearningProgress()}});

    -- ── System prompt ─────────────────────────────────────────────────────────
    elseif action == "get_system_prompt" then
        WebSocketServer:Send(nid, {type = "system_prompt", data = {prompt = agent:GetCachedSystemPrompt() or ""}});

    elseif action == "set_system_prompt" then
        if msg.prompt then agent:SetSystemPrompt(msg.prompt); end
        WebSocketServer:Send(nid, {type = "ack", action = "set_system_prompt", success = true});

    elseif action == "invalidate_system_prompt" then
        agent:InvalidateSystemPromptCache();
        WebSocketServer:Send(nid, {type = "ack", action = "invalidate_system_prompt"});

    -- ── Update interval ───────────────────────────────────────────────────────
    elseif action == "set_update_interval" then
        local interval = tonumber(msg.interval);
        if interval and interval >= 100 then
            agent:SetUpdateInterval(interval);
            WebSocketServer:Send(nid, {type = "ack", action = "set_update_interval", interval = interval});
        else
            WebSocketServer:Send(nid, {type = "error", msg = "invalid interval (min 100ms)"});
        end

    -- ── Last step inspection ──────────────────────────────────────────────────
    elseif action == "get_last_step" then
        WebSocketServer:Send(nid, {type = "last_step", data = {context = agent:GetLastStepContext(), result = agent:GetLastStepResult()}});

    -- ── Voice history ─────────────────────────────────────────────────────────
    elseif action == "get_voice_history" then
        WebSocketServer:Send(nid, {type = "voice", data = {entries = BuildVoice()}});

    -- ── Scene vision history ──────────────────────────────────────────────────
    elseif action == "get_scene_vision_history" then
        WebSocketServer:Send(nid, {type = "vision", data = {entries = BuildVision()}});

    -- ── Full refresh (re-send init snapshot) ──────────────────────────────────
    elseif action == "refresh" then
        SendInitSnapshot(nid);

    else
        LOG.std(nil, "warn", "BgAgentWS", "Unknown action: %s", tostring(action));
        WebSocketServer:Send(nid, {type = "error", msg = "unknown action: " .. tostring(action)});
    end
end

-- Entry point called by WebSocketServer for messages arriving on this file.
-- Also called directly from bg_agent.page when a new client connects (action == "connected").
function BgAgentWS:HandleConnect(nid)
    -- Try to connect signals now that we have at least one client
    self:ConnectSignals();
    SendInitSnapshot(nid);
end
