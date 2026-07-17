--[[
Title: BackgroundAgent
Author(s): LiXizhi
Date: 2026/01/19
Desc: A background agent that uses the 3D scene as image context to control subagent copilots.
Supports singleton instance, timer-based background execution, auto-discovery of copilots and their tools,
and markdown+JSON response format for LLM tool results.

The agent supports primary learning tasks that persist until explicitly changed. Once a learning task is set,
the agent focuses on practicing that task until completion or until a new task is assigned.

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/BackgroundAgent.lua");
local BackgroundAgent = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BackgroundAgent");
local agent = BackgroundAgent:GetInstance();

-- Configure user profile for a 9-year-old Chinese student learning English
agent:SetUserProfile({
    age = 9,
    primaryLanguage = "Chinese",
    secondaryLanguage = "English",
    name = "小明",
});

-- Set the primary learning task as plain text
-- Once set, this task persists until completion or until explicitly changed
-- Completion criteria is evaluated by LLM based on chat history
agent:SetPrimaryLearningTask("Practice spelling common English words through interactive games. Words to Learn：apple, banana, cat, dog, elephant, fish, green, house, ");
--agent:SetPrimaryLearningTask("观察3D场景和用户的行为，在玩的过程中教孩子学一些小学阶段的英文单词和短句子。你不需要询问用户需要学习什么内容，你只需要根据用户的行为和场景来教他英文单词和短句子。");

-- Start/Resume the agent with 1-second update interval (continuous mode)
agent:SetUpdateInterval(1000);
agent:Play();


-- The agent now continuously practices the spelling task
-- It will use H5 minigames, voice recognition, and other tools to engage the student

-- For debugging: Step() automatically pauses and makes a single LLM call
agent:Step();   -- Auto-pauses, captures context snapshot, makes one LLM call


-- Check progress at any time
local progress = agent:GetLearningProgress();
echo("Items practiced: " .. #progress.itemsLearned);
echo("Accuracy: " .. (progress.totalCorrect / math.max(1, progress.totalAttempts) * 100) .. "%");


-- The task can be changed at any time if desired
agent:SetPrimaryLearningTask(" Learn 'ou' Sound Words Practice words with the 'ou' sound: house, mouse, cloud, loud");

-- When done with all learning activities
agent:Stop();
------------------------------------------------------------
]]

-- Load dependencies
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/AIChat.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotManager.lua");
local CopilotManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotManager");
local AIChat = commonlib.gettable("MyCompany.Aries.Game.Common.AIChat");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/FileTools.lua");
local FileTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.FileTools");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/SceneVisionManager.lua");
local SceneVisionManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.SceneVisionManager");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/VoiceContextManager.lua");
local VoiceContextManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.VoiceContextManager");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/LearningToolUI.lua");
local LearningToolUI = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.LearningToolUI");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/LearningGiftBoxManager.lua");
local LearningGiftBoxManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/LearningGiftBoxManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/DialogHistoryManager.lua");
local DialogHistoryManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.DialogHistoryManager");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ChatLogUtil.lua");
local ChatLogUtil = commonlib.gettable("MyCompany.Aries.Game.Common.ChatLogUtil");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/TTSQueueManager.lua");
local TTSQueueManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.TTSQueueManager");
local NPLJS = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NPLJS.lua");
-- BackgroundAgent class definition (inherits from ToolBase for signal support)
local BackgroundAgent = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"),commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BackgroundAgent"));

--------------------------------------------------------------------------------
-- NPLJS Communication (bidirectional JS ↔ Lua)
-- Message event names follow MiniGameMgr convention:
--   JS→Lua: "@webparacraft_backgroundAgent"
--   Lua→JS: "@keepwork_backgroundAgent"
--------------------------------------------------------------------------------
local npljs_recv_event = "@webparacraft_backgroundAgent";
local npljs_send_event = "@keepwork_backgroundAgent";

-- Define signals for event handling
BackgroundAgent:Signal("chatContentUpdate")
BackgroundAgent:Signal("sceneContextCaptured");
BackgroundAgent:Signal("toolExecuted");
BackgroundAgent:Signal("llmResponseReceived");
BackgroundAgent:Signal("copilotDiscovered");
BackgroundAgent:Signal("played");     -- Emitted when Play() is called
BackgroundAgent:Signal("paused");     -- Emitted when Pause() is called
BackgroundAgent:Signal("stepped");    -- Emitted when Step() completes (with context snapshot)
BackgroundAgent:Signal("stopped");    -- Emitted when Stop() is called
BackgroundAgent:Signal("primaryTaskChanged");
BackgroundAgent:Signal("typewriterText");  -- Emitted for typewriter effect (text delta)
BackgroundAgent:Signal("progressUpdate");   -- Emitted for progress markers (separate from dialog)
BackgroundAgent:Signal("ttsStarted");      -- Emitted when TTS playback starts
BackgroundAgent:Signal("ttsCompleted");    -- Emitted when TTS playback completes

-- Singleton instance
local s_instance = nil;

-- Scene-related keywords for detecting if user request involves 3D scene operations
-- When matched, full scene context is included; otherwise brief mode is used
local SCENE_KEYWORDS = {
    -- Chinese keywords
    "建造", "放置", "移动", "删除", "方块", "旋转", "复制", "选择", "撤销",
    "创建", "搭建", "摆放", "拆除", "移除", "转动", "粘贴", "选中", "取消",
    "建筑", "模型", "场景", "地形", "位置", "坐标", "实体", "物体", "角色",
    "前进", "后退", "左转", "右转", "跳跃", "飞行", "传送",
    -- English keywords
    "build", "place", "move", "delete", "block", "rotate", "copy", "select", "undo",
    "create", "construct", "remove", "destroy", "paste", "cancel",
    "model", "scene", "terrain", "position", "coordinate", "entity", "object", "character",
    "forward", "backward", "turn", "jump", "fly", "teleport",
};

-- Tool execution strategies configuration
-- Defines how different tools should be executed and their context handled
-- Modes: "sync" (immediate return), "async" (wait for callback), "ui_blocking" (needs user interaction)
-- Impact: "read" (only reads state), "write" (modifies state)
local TOOL_STRATEGIES = {
    -- Default strategy for unknown tools
    default = {
        mode = "sync",
        impact = "read",
        category = "unknown",
        priority = "normal",
    },
    
    -- Scene query tools (sync, read-only)
    get_scene_info = { mode = "sync", impact = "read", category = "scene_query" },
    query_entities = { mode = "sync", impact = "read", category = "scene_query" },
    list_copilots = { mode = "sync", impact = "read", category = "scene_query" },
    
    -- Scene modification tools (sync, write)
    move_to_location = { mode = "sync", impact = "write", category = "scene_modify" },
    place_block = { mode = "sync", impact = "write", category = "scene_modify" },
    remove_block = { mode = "sync", impact = "write", category = "scene_modify" },
    send_message_to_copilot = { mode = "sync", impact = "write", category = "copilot_control" },
    
    -- Learning data tools (sync)
    get_learning_progress = { mode = "sync", impact = "read", category = "learning_data" },
    set_learning_progress = { mode = "sync", impact = "write", category = "learning_data" },
    record_observation = { mode = "sync", impact = "write", category = "learning_data" },
    
    -- Learning UI tools (ui_blocking, needs user interaction via H5 minigames)
    test_multiple_choice = { mode = "ui_blocking", impact = "write", category = "learning_test", queueable = true },
    test_words_speaking = { mode = "ui_blocking", impact = "write", category = "learning_test", queueable = true },
    test_words_spelling = { mode = "ui_blocking", impact = "write", category = "learning_test", queueable = true },
    show_learning_content = { mode = "ui_blocking", impact = "write", category = "learning_test", queueable = true },
    
    -- Audio tools (async)
    speak_text = { mode = "async", impact = "read", category = "audio", canInterrupt = true },
    
    -- Copilot control tools (async)
    run_copilot_code = { mode = "async", impact = "write", category = "copilot_control", timeout = 30000 },
    run_terminal_code = { mode = "async", impact = "write", category = "copilot_control", timeout = 30000 },
    
    -- Agent task tools (mixed)
    get_copilot_tasks = { mode = "sync", impact = "read", category = "agent_task" },
    control_task = { mode = "sync", impact = "write", category = "agent_task" },
    copilot_say = { mode = "sync", impact = "write", category = "agent_task" },
    copilot_move = { mode = "async", impact = "write", category = "agent_task" },
    schedule_task = { mode = "async", impact = "write", category = "agent_task" },
    start_building = { mode = "async", impact = "write", category = "agent_task" },
    start_life_task = { mode = "async", impact = "write", category = "agent_task" },
};

--------------------------------------------------------------------------------
-- BackgroundAgent Configuration
-- Consolidates magic numbers and tunable parameters
--------------------------------------------------------------------------------
local CONFIG = {
    -- Update timer interval (ms)
    updateInterval = 1000,
    
    -- Scene context cache timeout (ms) - how long cached screenshots are valid
    contextCacheTimeout = 500,
    
    -- Maximum image dimension for screenshots
    maxImageSize = 1080,
    
    -- Voice LLM throttling - minimum interval between voice-triggered LLM calls (ms)
    voiceThrottleInterval = 3000,
    
    -- Scene change debounce delay (ms) - wait before capturing after rapid changes
    sceneChangeDebounceDelay = 500,
    
    -- Observation mode settings
    observation = {
        sceneChangeThreshold = 3,    -- Number of scene changes before triggering observation
        observationInterval = 15000, -- Minimum interval between observations (ms)
        idlePromptInterval = 30000,  -- Idle prompt interval (ms)
    },
    
    -- LLM retry settings
    llmRetry = {
        maxRetries = 2,      -- Maximum retry attempts for server errors
        retryDelay = 5000,   -- Delay before retry (ms)
    },
    
    -- Dialog history settings
    maxChatHistorySize = 50,       -- Maximum chat messages to keep
    maxSceneVisionHistorySize = 20, -- Maximum scene vision entries
    maxVoiceHistorySize = 50,      -- Maximum voice entries
    maxLLMHistorySize = 20,        -- Maximum LLM call history entries
    
    -- Session state settings
    checkpointInterval = 300,      -- Auto-save interval (seconds)
    
    -- Tool call throttling
    toolCallMinInterval = 2000,    -- Minimum interval between same tool calls (ms)
    
    -- Structured learning idle threshold (ms)
    structuredLearningIdleThreshold = 180000, -- 3 minutes
};

--[[
    Check if user request is related to scene operations
    @param userQuery: string - The user's input query
    @return boolean - True if the query contains scene-related keywords
]]
function BackgroundAgent:IsSceneRelatedRequest(userQuery)
    if not userQuery or userQuery == "" then
        return false;
    end
    
    local lowerQuery = string.lower(userQuery);
    for _, keyword in ipairs(SCENE_KEYWORDS) do
        if string.find(lowerQuery, string.lower(keyword), 1, true) then
            return true;
        end
    end
    return false;
end

--[[
    Get or create the singleton instance of BackgroundAgent
    @return BackgroundAgent - The global singleton instance
]]
function BackgroundAgent:GetInstance()
    if not s_instance then
        s_instance = self:new();
    end
    return s_instance;
end

-- Constructor
function BackgroundAgent:ctor()
    -- Playback state: "stopped", "playing", "paused"
    self.playbackState = "stopped";
    
    -- Timer for background updates
    self.updateTimer = nil;
    self.updateInterval = CONFIG.updateInterval;
    
    -- Step debugging state
    self.lastStepContext = nil;   -- Last captured context from Step()
    self.lastStepResult = nil;    -- Last LLM result from Step()
    self.isStepInProgress = false; -- True while Step() is executing
    
    -- Discovered copilots and their capabilities
    self.discoveredCopilots = {};
    
    -- Tool registry: {name = {schema, handler}}
    self.tools = {};
    
    -- AI session for LLM communication
    self.aiSession = nil;
    
    -- Current session ID for logging (set when LLM request starts)
    self._currentSessionId = nil;
    
    -- Scene context cache
    self.cachedSceneImage = nil;
    self.cachedSceneText = nil;
    self.lastContextCaptureTime = 0;
    self.contextCacheTimeout = CONFIG.contextCacheTimeout;
    
    -- Screenshot settings
    self.maxImageSize = CONFIG.maxImageSize;
    
    -- Pending tasks queue
    self.pendingTasks = {};
    
    -- Debug mode for logging LLM IO
    self.debugEnabled = true;
    
    --------------------------------------------------------------------------------
    -- Learning State Management (for educational background agent)
    --------------------------------------------------------------------------------
    
    -- User profile for personalized learning
    self.userProfile = {
        age = 9,                        -- Default age
        primaryLanguage = "Chinese",    -- Native language
        secondaryLanguage = "English",  -- Language to learn
        name = nil,                     -- Optional user name
    };
    
    -- Primary learning task configuration (markdown text)
    self.primaryTask = nil;  -- Will be set via SetPrimaryLearningTask(text)
    --[[
        primaryTask structure:
        {
            id = "unique_task_id",
            text = "markdown content describing the learning task",
            createdAt = os.time(),
        }
        
        Completion criteria is evaluated by LLM based on chat history,
        not by structured thresholds.
    ]]
    
    -- Learning progress tracking
    -- learningPercentage is the main field (0-100), other fields assist LLM in deciding it
    self.learningProgress = {
        learningPercentage = 0, -- Main progress indicator [0-100], set by LLM based on assistant fields
        itemsLearned = {},      -- Assistant field: {word = {attempts = N, correct = N, lastAttempt = time}}
        totalAttempts = 0,      -- Assistant field: total test attempts
        totalCorrect = 0,       -- Assistant field: total correct answers
        -- Observation mode stats (for open-ended tasks)
        observationStats = {
            conceptsTaught = {},    -- {concept = {count = N, lastTime = timestamp}}
            interactionCount = 0,   -- Total interactions with user
            observationCount = 0,   -- Total proactive observations triggered
            topicsDiscussed = {},   -- Array of topic strings discussed
        },
        sessionStartTime = nil,
        lastActivityTime = nil,
    };
    
    -- Session state for context management (checkpoint tracking only)
    self.sessionState = {
        lastCheckpoint = nil,       -- Last saved checkpoint time
        checkpointInterval = CONFIG.checkpointInterval,
    };
    
    --------------------------------------------------------------------------------
    -- Observation Mode (for open-ended tasks without explicit goals)
    --------------------------------------------------------------------------------
    
    -- Observation mode configuration
    self.observationMode = {
        enabled = false,            -- Whether observation mode is active
        sceneChangeThreshold = CONFIG.observation.sceneChangeThreshold,
        sceneChangeCount = 0,       -- Current scene change counter
        lastObservationTime = 0,    -- Last observation timestamp (ms)
        observationInterval = CONFIG.observation.observationInterval,
        idlePromptInterval = CONFIG.observation.idlePromptInterval,
    };
    
    -- LLM error recovery configuration
    self.llmRetry = {
        maxRetries = CONFIG.llmRetry.maxRetries,
        retryDelay = CONFIG.llmRetry.retryDelay,
        currentRetryCount = 0,      -- Current retry counter
        pendingRetry = nil,         -- Pending retry timer
        lastErrorTime = 0,          -- Last error timestamp for backoff
    };
    
    -- Scene change accumulator for observation mode
    self.pendingSceneChanges = {};  -- Array of recent scene changes for context
    
    -- Dialog history manager (handles summarization and context compression)
    self.dialogHistoryManager = DialogHistoryManager:new():Init();
    self.dialogHistoryManager:SetLanguage("zh"); -- Default to Chinese
    
    -- Pending tool results (for async H5 minigame callbacks)
    self.pendingToolResults = {};   -- {sessionId = {toolName, params, callback, timestamp}}
    self.toolCallThrottle = {minInterval = CONFIG.toolCallMinInterval, lastCalled = {}};
    
    -- UI tool queue (prevent multiple UI popups at same time)
    self.uiToolQueue = {};          -- Queue of pending UI tool calls
    self.currentUISession = nil;    -- Currently displayed UI session ID
    
    --------------------------------------------------------------------------------
    -- Context History Management (for scene vision and voice recognition)
    --------------------------------------------------------------------------------
    
    -- Scene vision history (screenshots sent to LLM)
    self.sceneVisionHistory = {};
    
    self.maxSceneVisionHistorySize = CONFIG.maxSceneVisionHistorySize;
    self.lastSceneVisionEntry = nil;  -- 最新的截图条目
    
    -- Voice recognition history
    self.voiceHistory = {};
    
    self.maxVoiceHistorySize = CONFIG.maxVoiceHistorySize;
    self.pendingVoiceEntries = {};  -- 待发送给LLM的语音条目
    
    -- Voice LLM call throttling
    self.voiceLLMThrottle = {
        minInterval = CONFIG.voiceThrottleInterval,
        lastCallTime = 0,    -- Last LLM call timestamp (ms)
        isProcessing = false, -- Whether an LLM call is in progress
    };
    
    --------------------------------------------------------------------------------
    -- TTS Auto-Speak Queue (delegated to TTSQueueManager)
    --------------------------------------------------------------------------------
    
    -- TTSQueueManager handles all TTS state and queue management
    self.ttsManager = TTSQueueManager:GetInstance();
    
    -- Sentence buffer for extracting complete sentences from streaming delta
    -- (kept in BackgroundAgent as it's tightly coupled with LLM streaming logic)
    self.sentenceBuffer = "";
    
    -- Typewriter effect callback (called for each delta to show real-time text)
    self.typewriterCallback = nil;
    
    --------------------------------------------------------------------------------
    -- Chat Message History (for UI display)
    --------------------------------------------------------------------------------
    
    -- Chat message history for debug UI display
    self.chatMessageHistory = {};  -- Array of {role, content, timestamp, isComplete}
    self.maxChatHistorySize = CONFIG.maxChatHistorySize;
    self.currentChatMessage = nil; -- Current message being streamed (typewriter effect)
    
    --------------------------------------------------------------------------------
    -- Request Queue (for merging concurrent requests)
    --------------------------------------------------------------------------------
    
    -- Pending user requests queue (FIFO order, merged on next LLM call)
    self.pendingUserRequests = {};
    
    -- Whether LLM is currently processing a request
    self.isLLMProcessing = false;
    
    -- Tool call detection state for TTS hint
    self.isToolCallInProgress = false;  -- Whether tool call content detected in stream
    self.toolCallHintSpoken = false;    -- Whether "正在查找可用的方法" hint has been spoken
    
    -- Learning session state
    self.isLearningInProgress = false;  -- Whether a learning LLM call is in progress
    
    -- LLM call history for debugging
    self.llmHistory = {};
    self.maxLLMHistorySize = CONFIG.maxLLMHistorySize;
    
    -- System prompt for the agent
    self.systemPrompt = [[You are a BackgroundAgent controlling a 3D scene in Paracraft.
You name is "papa" and chinese name is "帕帕".
You have access to the scene graph and can see a screenshot of the current view.
You control multiple subagent copilots to accomplish tasks.
Response rules:
- Use the provided tools when appropriate to accomplish tasks.
- Only call tools that are available to you. Never invent tools.
- Use prose to explain what you're doing.
- Reference entities and locations clearly.
- Respond in a helpful and friendly manner.]];

    -- System prompt cache for token optimization
    self.cachedSystemPrompt = nil;
    self.systemPromptCacheKey = nil; -- Hash of task + copilots for cache invalidation

    -- Initialize built-in tools
    self:RegisterBuiltinTools();
    
    -- Initialize learning tools
    self:RegisterLearningTools();
    
    -- Initialize agent task tools (building, planting, fishing, cooking)
    -- self:RegisterAgentTaskTools();
    
    -- Initialize context managers
    self:InitContext();
end

function BackgroundAgent:InitContext()
    -- Initialize scene vision manager in passive mode
    -- BackgroundAgent controls when screenshots are captured (before LLM requests)
    -- IMPORTANT: Set passive mode BEFORE Init() so that Init()'s auto-capture is skipped.
    -- Otherwise the auto-capture and Step()'s ForceCaptureNow run concurrently; the auto-capture
    -- disables the viewport just as Step()'s SaveToFile runs, producing an empty/missing file.
    SceneVisionManager:SetPassiveMode(true);
    SceneVisionManager:Init();
    
    -- Track scene dirty state - assume dirty on startup to ensure first LLM request has a screenshot
    self.sceneDirty = true;
    
    SceneVisionManager:Connect("sceneChanged", function(changeInfo)
        self:OnSceneChanged(changeInfo);
    end);
    
    SceneVisionManager:Connect("screenshotCaptured", function(entry)
        self:OnScreenshotCaptured(entry);
    end);
    
    -- Initialize voice context manager
    VoiceContextManager:Init();
    VoiceContextManager:Connect("voiceTranscribed", function(entry)
        self:OnVoiceTranscribed(entry);
    end);
    
    -- Connect TTSQueueManager signals to BackgroundAgent signals
    -- This maintains backward compatibility for external signal consumers
    self.ttsManager:Connect("ttsStarted", function(text)
        self:ttsStarted(text);
    end);
    self.ttsManager:Connect("ttsCompleted", function()
        self:ttsCompleted();
    end);
    
    -- Connect to typewriter signal to update chat history
    self:Connect("typewriterText", self, self.OnTypewriterText);
    
    -- Register NPLJS handlers for JS ↔ Lua communication
    self:RegisterNPLJSHandlers();
end

--[[
    Called when SceneVisionManager detects a scene change (passive mode)
    Triggers debounced screenshot capture and accumulates changes for observation mode
    @param changeInfo: table - {type = "block"|"camera", event = optional event data}
]]
function BackgroundAgent:OnSceneChanged(changeInfo)
    self.sceneDirty = true;
    
    -- Debounced screenshot capture - wait 500ms after last change before capturing
    -- This prevents excessive captures during rapid camera movement
    if self.sceneChangeCaptureTimer then
        self.sceneChangeCaptureTimer:Change();  -- Cancel previous timer
    end
    
    self.sceneChangeCaptureTimer = commonlib.Timer:new({
        callbackFunc = function(timer)
            timer:Change();  -- One-shot
            self.sceneChangeCaptureTimer = nil;
            if self.sceneDirty and self.playbackState == "playing" then
                LOG.std(nil, "debug", "BackgroundAgent", "Debounced screenshot capture triggered");
                SceneVisionManager:ForceCaptureNow();  -- Capture without callback, signal will handle it
            end
        end
    });
    self.sceneChangeCaptureTimer:Change(500, nil);  -- 500ms debounce
    
    -- In observation mode, accumulate scene changes and potentially trigger observation
    if self.observationMode.enabled and self.playbackState == "playing" then
        -- Record the change
        table.insert(self.pendingSceneChanges, {
            type = changeInfo and changeInfo.type or "unknown",
            timestamp = commonlib.TimerManager.GetCurrentTime(),
        });
        
        -- Trim old changes (keep last 20)
        while #self.pendingSceneChanges > 20 do
            table.remove(self.pendingSceneChanges, 1);
        end
        
        -- Increment change counter
        self.observationMode.sceneChangeCount = self.observationMode.sceneChangeCount + 1;
        
        LOG.std(nil, "debug", "BackgroundAgent", "Scene changed: %s (count: %d/%d)", 
            changeInfo and changeInfo.type or "unknown",
            self.observationMode.sceneChangeCount,
            self.observationMode.sceneChangeThreshold);
        
        -- Check if we should trigger an observation
        self:CheckObservationTrigger();
    else
        LOG.std(nil, "debug", "BackgroundAgent", "Scene changed: %s (obs_mode=%s, playing=%s)", 
            changeInfo and changeInfo.type or "unknown",
            tostring(self.observationMode.enabled),
            tostring(self.playbackState == "playing"));
    end
end

--------------------------------------------------------------------------------
-- Learning State Management
--------------------------------------------------------------------------------

--[[
    Set user profile for personalized learning
    @param config: table - {age, primaryLanguage, secondaryLanguage, name}
]]
function BackgroundAgent:SetUserProfile(config)
    if not config then return self; end
    
    if config.age then
        self.userProfile.age = config.age;
    end
    if config.primaryLanguage then
        self.userProfile.primaryLanguage = config.primaryLanguage;
        -- Sync language to dialog history manager
        if self.dialogHistoryManager then
            local lang = (config.primaryLanguage == "Chinese" or config.primaryLanguage == "zh") and "zh" or "en";
            self.dialogHistoryManager:SetLanguage(lang);
        end
    end
    if config.secondaryLanguage then
        self.userProfile.secondaryLanguage = config.secondaryLanguage;
    end
    if config.name then
        self.userProfile.name = config.name;
    end
    
    LOG.std(nil, "info", "BackgroundAgent", "User profile set: age=%d, primary=%s, secondary=%s",
        self.userProfile.age, self.userProfile.primaryLanguage, self.userProfile.secondaryLanguage);
    
    return self;
end

--[[
    Get current user profile
    @return table - User profile
]]
function BackgroundAgent:GetUserProfile()
    return self.userProfile;
end

--[[
    Set the primary learning task as markdown text.
    Once set, the agent will keep practicing this task until it is explicitly changed
    or completed. The task can be changed at any time by calling this method again.
    
    Completion criteria is evaluated by LLM based on chat history, not structured thresholds.
    
    @param text: string - Markdown text describing the learning task, or nil to clear
    @return self for chaining
    
    Note: Calling this method will reset learning progress.
    The primary task persists until this method is called again with a new task or nil.
]]
function BackgroundAgent:SetPrimaryLearningTask(text)
    if not text or text == "" then
        local oldTask = self.primaryTask;
        self.primaryTask = nil;
        if oldTask then
            LOG.std(nil, "info", "BackgroundAgent", "Primary learning task cleared");
            self:InvalidateSystemPromptCache();
            self:primaryTaskChanged(nil, oldTask);
        end
        return self;
    end
    
    -- Generate unique task ID based on content hash
    local taskId = string.format("task_%d_%d", os.time(), #text);
    
    local oldTask = self.primaryTask;
    local isSameTask = oldTask and oldTask.text == text;
    
    self.primaryTask = {
        id = taskId,
        text = text,
        createdAt = os.time(),
    };
    
    -- Reset progress if this is a different task
    if not isSameTask then
        self:ResetLearningProgress();
    end
    
    -- Auto-detect if this is an open-ended observation task
    -- Keywords indicating observation-based learning (no explicit item list)
    local isObservationTask = self:IsObservationBasedTask(text);
    self:SetObservationMode(isObservationTask);
    
    LOG.std(nil, "info", "BackgroundAgent", "Primary learning task set (length: %d chars, observation: %s)", 
        #text, tostring(isObservationTask));
    
    -- Invalidate system prompt cache when task changes
    self:InvalidateSystemPromptCache();
    
    -- Emit signal for task change
    self:primaryTaskChanged(self.primaryTask, oldTask);
    
    return self;
end

--[[
    Get current primary learning task
    @return table - Primary task or nil
]]
function BackgroundAgent:GetPrimaryLearningTask()
    return self.primaryTask;
end

--[[
    Reset learning progress (typically when starting a new task)
]]
function BackgroundAgent:ResetLearningProgress()
    self.learningProgress = {
        learningPercentage = 0, -- Main progress indicator [0-100]
        itemsLearned = {},
        totalAttempts = 0,
        totalCorrect = 0,
        -- Observation mode stats (for open-ended tasks)
        observationStats = {
            conceptsTaught = {},    -- {concept = {count = N, lastTime = timestamp}}
            interactionCount = 0,   -- Total interactions with user
            observationCount = 0,   -- Total proactive observations triggered
            topicsDiscussed = {},   -- Array of topic strings discussed
        },
        sessionStartTime = os.time(),
        lastActivityTime = commonlib.TimerManager.GetCurrentTime(),  -- milliseconds
    };
    
    -- Also reset observation mode state
    if self.observationMode then
        self.observationMode.sceneChangeCount = 0;
        self.observationMode.lastObservationTime = 0;
    end
    self.pendingSceneChanges = {};
end

--------------------------------------------------------------------------------
-- Observation Mode (for open-ended tasks)
--------------------------------------------------------------------------------

--[[
    Check if a task is observation-based (no explicit learning items)
    @param taskText: string - The task description
    @return boolean - True if task appears to be observation-based
]]
function BackgroundAgent:IsObservationBasedTask(taskText)
    if not taskText then return false; end
    
    local lowerText = string.lower(taskText);
    
    -- Keywords indicating observation-based learning
    local observationKeywords = {
        "观察", "场景", "行为", "玩的过程", "互动", "探索",
        "observe", "scene", "behavior", "while playing", "interact", "explore",
        "不需要询问", "根据.*行为", "根据.*场景",
    };
    
    -- Keywords indicating structured learning (with explicit items)
    local structuredKeywords = {
        "words to learn", "要学习的单词", "词汇表", "word list",
        "apple", "banana", -- specific word examples often indicate structured task
    };
    
    -- Check for observation keywords
    local hasObservationKeyword = false;
    for _, keyword in ipairs(observationKeywords) do
        if string.find(lowerText, keyword) then
            hasObservationKeyword = true;
            break;
        end
    end
    
    -- Check for structured keywords
    local hasStructuredKeyword = false;
    for _, keyword in ipairs(structuredKeywords) do
        if string.find(lowerText, keyword) then
            hasStructuredKeyword = true;
            break;
        end
    end
    
    -- Observation mode if has observation keywords but no structured keywords
    return hasObservationKeyword and not hasStructuredKeyword;
end

--[[
    Enable or disable observation mode
    @param enabled: boolean - Whether to enable observation mode
    @param config: table (optional) - Configuration overrides
]]
function BackgroundAgent:SetObservationMode(enabled, config)
    self.observationMode.enabled = enabled;
    
    if config then
        if config.sceneChangeThreshold then
            self.observationMode.sceneChangeThreshold = config.sceneChangeThreshold;
        end
        if config.observationInterval then
            self.observationMode.observationInterval = config.observationInterval;
        end
        if config.idlePromptInterval then
            self.observationMode.idlePromptInterval = config.idlePromptInterval;
        end
    end
    
    -- Reset counters when mode changes
    self.observationMode.sceneChangeCount = 0;
    self.observationMode.lastObservationTime = 0;
    self.pendingSceneChanges = {};
    
    LOG.std(nil, "info", "BackgroundAgent", "Observation mode %s (threshold: %d, interval: %dms)",
        enabled and "enabled" or "disabled",
        self.observationMode.sceneChangeThreshold,
        self.observationMode.observationInterval);
    
    return self;
end

--[[
    Check if observation mode is enabled
    @return boolean
]]
function BackgroundAgent:IsObservationMode()
    return self.observationMode and self.observationMode.enabled;
end

--[[
    Check if we should trigger a proactive observation based on scene changes
    Called from OnSceneChanged when in observation mode
]]
function BackgroundAgent:CheckObservationTrigger()
    if not self.observationMode.enabled then 
        LOG.std(nil, "debug", "BackgroundAgent", "[ObsTrigger] Skipped: observation mode disabled");
        return; 
    end
    if self.playbackState ~= "playing" then 
        LOG.std(nil, "debug", "BackgroundAgent", "[ObsTrigger] Skipped: not playing (state=%s)", self.playbackState);
        return; 
    end
    
    local now = commonlib.TimerManager.GetCurrentTime();
    local timeSinceLastObservation = now - (self.observationMode.lastObservationTime or 0);
    
    -- Check minimum interval
    if timeSinceLastObservation < self.observationMode.observationInterval then
        LOG.std(nil, "debug", "BackgroundAgent", "[ObsTrigger] Skipped: interval not met (%ds < %ds)",
            math.floor(timeSinceLastObservation / 1000), math.floor(self.observationMode.observationInterval / 1000));
        return;
    end
    
    -- Check if enough scene changes have accumulated
    if self.observationMode.sceneChangeCount < self.observationMode.sceneChangeThreshold then
        LOG.std(nil, "debug", "BackgroundAgent", "[ObsTrigger] Skipped: not enough changes (%d < %d)",
            self.observationMode.sceneChangeCount, self.observationMode.sceneChangeThreshold);
        return;
    end
    
    -- Don't overlap with existing LLM calls
    if self.voiceLLMThrottle.isProcessing or self.isLLMProcessing then
        LOG.std(nil, "debug", "BackgroundAgent", "[ObsTrigger] Skipped: LLM busy (voice=%s, llm=%s)",
            tostring(self.voiceLLMThrottle.isProcessing), tostring(self.isLLMProcessing));
        return;
    end
    
    -- Don't interrupt if user is in the middle of a learning tool UI
    if self.currentUISession then
        LOG.std(nil, "debug", "BackgroundAgent", "[ObsTrigger] Skipped: UI session active");
        return;
    end
    
    -- Trigger observation
    LOG.std(nil, "info", "BackgroundAgent", "Observation triggered: %d scene changes, %d seconds since last",
        self.observationMode.sceneChangeCount, math.floor(timeSinceLastObservation / 1000));
    
    self:TriggerProactiveObservation();
end

--[[
    Trigger a proactive observation and teaching moment
    Called when enough scene changes have accumulated or on timer
    Uses cached screenshot from SceneVisionManager (screenshot capture is decoupled)
]]
function BackgroundAgent:TriggerProactiveObservation()
    if not self.primaryTask then 
        LOG.std(nil, "debug", "BackgroundAgent", "[ProactiveObs] Skipped: no primaryTask");
        return; 
    end
    
    -- Mark as in progress
    self.isLearningInProgress = true;
    self.observationMode.lastObservationTime = commonlib.TimerManager.GetCurrentTime();
    self.observationMode.sceneChangeCount = 0;  -- Reset counter
    
    -- Use cached screenshot (screenshot capture is handled by OnSceneChanged debounce)
    local latestVision = self:GetLatestSceneVision();
    local imageUrl = latestVision and latestVision.imageUrl or nil;
    
    LOG.std(nil, "info", "BackgroundAgent", "[ProactiveObs] Starting observation with cached image: %s", imageUrl or "nil");
    
    self:_ExecuteProactiveObservation(imageUrl);
end

--[[
    Internal: Execute the proactive observation LLM call
    @param imageUrl: string - Screenshot URL to use
]]
function BackgroundAgent:_ExecuteProactiveObservation(imageUrl)
    -- Build observation prompt based on recent activity
    local recentChanges = self:GetRecentSceneChangesSummary();
    
    -- Count concepts already taught to guide tool selection
    local conceptsTaughtCount = 0;
    if self.learningProgress.observationStats and self.learningProgress.observationStats.conceptsTaught then
        for _ in pairs(self.learningProgress.observationStats.conceptsTaught) do
            conceptsTaughtCount = conceptsTaughtCount + 1;
        end
    end
    
    local prompt;
    if conceptsTaughtCount >= 2 then
        -- Time to test what was taught
        prompt = string.format([[The user has been actively interacting with the 3D scene.
Recent activity: %s

You have already introduced %d concepts/words. Now it's time to TEST the user on what they've learned!

IMPORTANT: Choose ONE test tool:
- `test_multiple_choice` - Create a fun quiz about words you taught
- `test_words_speaking` - Have them practice pronunciation
- `test_words_spelling` - Test their spelling

Make the test feel like a game, not an exam. Be encouraging!
After the test, call `record_observation` to track the concepts tested.]], recentChanges, conceptsTaughtCount);
    else
        -- Continue teaching new concepts
        prompt = string.format([[The user has been actively interacting with the 3D scene.
Recent activity: %s

Based on what you observe in the screenshot and the user's recent actions:
1. Find something interesting in the scene to talk about
2. Use `show_learning_content` to introduce a relevant English word with translation
3. Keep your spoken comment brief (1-2 sentences)
4. IMPORTANT: After teaching, call `record_observation` with the word you taught

Remember: You are observing and teaching naturally, connecting English words to what the user sees.]], recentChanges);
    end
    
    local self_ = self;
    local askOptions = {includeImage = true, skipChatHistory = false};
    if imageUrl and imageUrl ~= "" then
        askOptions.imageUrl = imageUrl;
    end
    
    self:ProcessWithLLM(prompt, function(result)
        -- Always reset the flag
        self_.isLearningInProgress = false;
        -- Only update lastActivityTime on success to allow faster retry on errors
        if result and result.success then
            self_.learningProgress.lastActivityTime = commonlib.TimerManager.GetCurrentTime();
            -- Update observation stats
            self_.learningProgress.observationStats.observationCount = 
                (self_.learningProgress.observationStats.observationCount or 0) + 1;
            self_.learningProgress.observationStats.interactionCount = 
                (self_.learningProgress.observationStats.interactionCount or 0) + 1;
            LOG.std(nil, "info", "BackgroundAgent", "[ProactiveObs] Completed successfully (obs#%d)",
                self_.learningProgress.observationStats.observationCount);
        else
            LOG.std(nil, "debug", "BackgroundAgent", "[ProactiveObs] LLM call failed, allowing faster retry");
        end
    end, askOptions);
end

--[[
    Get a summary of recent scene changes for context
    @return string - Description of recent changes
]]
function BackgroundAgent:GetRecentSceneChangesSummary()
    if #self.pendingSceneChanges == 0 then
        return "User is exploring the scene";
    end
    
    local blockChanges = 0;
    local cameraChanges = 0;
    
    for _, change in ipairs(self.pendingSceneChanges) do
        if change.type == "block" then
            blockChanges = blockChanges + 1;
        elseif change.type == "camera" then
            cameraChanges = cameraChanges + 1;
        end
    end
    
    local parts = {};
    if blockChanges > 0 then
        table.insert(parts, string.format("%d block changes (building/placing)", blockChanges));
    end
    if cameraChanges > 0 then
        table.insert(parts, string.format("%d camera movements (exploring/looking)", cameraChanges));
    end
    
    -- Clear processed changes
    self.pendingSceneChanges = {};
    
    return #parts > 0 and table.concat(parts, ", ") or "User is exploring the scene";
end

--[[
    Get current learning progress
    @return table - Learning progress
]]
function BackgroundAgent:GetLearningProgress()
    return self.learningProgress;
end

--[[
    Set the learning percentage (0-100)
    Called by LLM to update progress based on assistant fields
    @param percentage: number - Progress percentage in [0-100] range
    @return self for chaining
]]
function BackgroundAgent:SetLearningPercentage(percentage)
    if type(percentage) == "number" then
        self.learningProgress.learningPercentage = math.max(0, math.min(100, percentage));
        LOG.std(nil, "info", "BackgroundAgent", "Learning percentage set to: %d%%", self.learningProgress.learningPercentage);
    end
    return self;
end

--[[
    Update learning progress after a test result
    @param itemKey: string - The item being tested (e.g., word, phoneme)
    @param isCorrect: boolean - Whether the answer was correct
    @param metadata: table (optional) - Additional data {score, attempts, etc.}
]]
function BackgroundAgent:UpdateLearningProgress(itemKey, isCorrect, metadata)
    metadata = metadata or {};
    local progress = self.learningProgress;
    
    -- Initialize item record if new
    if not progress.itemsLearned[itemKey] then
        progress.itemsLearned[itemKey] = {
            attempts = 0,
            correct = 0,
            lastAttempt = nil,
            history = {},
        };
    end
    
    local item = progress.itemsLearned[itemKey];
    item.attempts = item.attempts + 1;
    item.lastAttempt = os.time();
    
    if isCorrect then
        item.correct = item.correct + 1;
        progress.totalCorrect = progress.totalCorrect + 1;
    end
    
    progress.totalAttempts = progress.totalAttempts + 1;
    progress.lastActivityTime = commonlib.TimerManager.GetCurrentTime();  -- Use milliseconds
    
    -- Record history
    table.insert(item.history, {
        time = os.time(),
        correct = isCorrect,
        score = metadata.score,
    });
    
    -- Auto-checkpoint if interval passed
    self:CheckAutoSave();
    
    return item;
end

--[[
    Get learning progress summary for LLM context
    @return string - Markdown formatted progress summary
]]
function BackgroundAgent:GetLearningProgressSummary()
    if not self.primaryTask then
        return "";
    end
    
    local progress = self.learningProgress;
    local isObservationMode = self.observationMode and self.observationMode.enabled;
    
    -- Count items practiced
    local itemCount = 0;
    for _ in pairs(progress.itemsLearned) do
        itemCount = itemCount + 1;
    end
    
    -- Count concepts taught (observation mode)
    local conceptCount = 0;
    local conceptList = {};
    if progress.observationStats and progress.observationStats.conceptsTaught then
        for concept, data in pairs(progress.observationStats.conceptsTaught) do
            conceptCount = conceptCount + 1;
            table.insert(conceptList, string.format("%s (x%d)", concept, data.count or 1));
        end
    end
    
    local md;
    
    if isObservationMode then
        -- Observation mode progress summary
        local obsStats = progress.observationStats or {};
        md = string.format([[## Learning Progress (Observation Mode)
- **Current Progress:** %d%%
- **Observations:** %d
- **Interactions:** %d
- **Concepts Taught:** %d
- **Session Duration:** %d minutes
]], 
            progress.learningPercentage or 0,
            obsStats.observationCount or 0,
            obsStats.interactionCount or 0,
            conceptCount,
            progress.sessionStartTime and math.floor((os.time() - progress.sessionStartTime) / 60) or 0
        );
        
        -- Show concepts taught
        if #conceptList > 0 then
            md = md .. "\n### Concepts Introduced\n";
            for _, conceptInfo in ipairs(conceptList) do
                md = md .. "- " .. conceptInfo .. "\n";
            end
        end
        
        -- Show topics discussed
        if obsStats.topicsDiscussed and #obsStats.topicsDiscussed > 0 then
            md = md .. "\n### Topics Discussed\n";
            -- Show last 5 topics
            local startIdx = math.max(1, #obsStats.topicsDiscussed - 4);
            for i = startIdx, #obsStats.topicsDiscussed do
                md = md .. "- " .. obsStats.topicsDiscussed[i] .. "\n";
            end
        end
    else
        -- Structured learning mode progress summary
        -- Build practiced items list with status
        local practicedItems = {};
        local masteredItems = {};
        local needsPracticeItems = {};
        
        for itemKey, itemData in pairs(progress.itemsLearned) do
            if itemData.attempts > 0 then
                local accuracy = itemData.correct / itemData.attempts * 100;
                local itemInfo = string.format("%s (%.0f%%, %d attempts)", itemKey, accuracy, itemData.attempts);
                table.insert(practicedItems, itemInfo);
                
                -- Categorize by mastery
                if accuracy >= 80 and itemData.attempts >= 2 then
                    table.insert(masteredItems, itemKey);
                else
                    table.insert(needsPracticeItems, itemKey);
                end
            end
        end
        
        md = string.format([[## Learning Progress
- **Current Progress:** %d%%
- **Items Practiced:** %d
- **Total Attempts:** %d (%.0f%% accuracy)
- **Session Duration:** %d minutes
]], 
            progress.learningPercentage or 0,
            itemCount,
            progress.totalAttempts,
            progress.totalAttempts > 0 and (progress.totalCorrect / progress.totalAttempts * 100) or 0,
            progress.sessionStartTime and math.floor((os.time() - progress.sessionStartTime) / 60) or 0
        );
        
        -- Show practiced items details
        if #practicedItems > 0 then
            md = md .. "\n### Practiced Items\n";
            for _, itemInfo in ipairs(practicedItems) do
                md = md .. "- " .. itemInfo .. "\n";
            end
        end
        
        -- Show mastery summary
        if #masteredItems > 0 then
            md = md .. "\n**Mastered:** " .. table.concat(masteredItems, ", ") .. "\n";
        end
        if #needsPracticeItems > 0 then
            md = md .. "**Needs Practice:** " .. table.concat(needsPracticeItems, ", ") .. "\n";
        end
    end
    
    return md;
end

--[[
    Check if primary learning task is complete.
    This is a hint based on progress; actual completion should be evaluated by LLM
    based on chat history and task requirements.
    @return boolean - true if significant progress has been made
]]
function BackgroundAgent:IsLearningTaskComplete()
    if not self.primaryTask then
        return false;
    end
    
    -- Basic heuristic: consider complete if high accuracy over many attempts
    local progress = self.learningProgress;
    if progress.totalAttempts >= 10 then
        local accuracy = progress.totalCorrect / progress.totalAttempts;
        return accuracy >= 0.8;
    end
    
    return false;
end

--[[
    Initialize the AI session for LLM communication
]]
function BackgroundAgent:InitAISession()
    if not self.aiSession then
        self.aiSession = AIChat:new();
        self.aiSession:SetSystemPrompt(self.systemPrompt);
        self.aiSession:SetStream(true);
        self.aiSession:SetModel("keepwork-flash");
        -- Disable AIChat's auto_history since BackgroundAgent manages its own history
        self.aiSession:SetAutoHistory(false);
        -- Use delegate mode: BackgroundAgent handles tool execution instead of AIChat
        self.aiSession:SetToolCallMode("delegate");
        -- Register tool definitions with AIChat (but not callbacks since we're in delegate mode)
        self:SyncToolsToAISession();
        -- Note: DialogHistoryManager now creates its own independent AIChat for summarization
        -- to avoid conflicts with main dialog session
    end
    return self.aiSession;
end

--[[
    Sync registered tools to AIChat's native tool system
    Call this after registering new tools or when aiSession is created
    In delegate mode, only tool definitions are synced (not callbacks)
]]
function BackgroundAgent:SyncToolsToAISession()
    if not self.aiSession then return; end
    
    -- Convert tools to OpenAI format and set on AIChat
    local toolDefinitions = self:GetAllToolDefinitions();
    self.aiSession:SetTools(toolDefinitions);
    
    -- In delegate mode, BackgroundAgent handles tool execution via HandleToolCallsFromLLM
    -- No need to register callbacks with AIChat
    local mode = self.aiSession:GetToolCallMode();
    if mode == "delegate" then
        LOG.std(nil, "debug", "BackgroundAgent", "Synced %d tools to AIChat (delegate mode, no callbacks)", #toolDefinitions);
        return;
    end
    
    -- Auto mode: Register all tool callbacks with AIChat (legacy behavior)
    for name, tool in pairs(self.tools) do
        local handler = tool.handler;
        self.aiSession:RegisterToolCallback(name, function(args, asyncCallback)
            -- Wrap the tool handler to support both sync and async patterns
            local result = nil;
            local callbackCalled = false;
            
            handler(args or {}, function(handlerResult)
                callbackCalled = true;
                result = handlerResult;
                -- Emit toolExecuted signal
                self:toolExecuted(name, args, handlerResult);
                -- Call async callback if provided (for async tools)
                if asyncCallback and type(asyncCallback) == "function" then
                    asyncCallback(handlerResult);
                end
            end);
            
            -- If callback was called synchronously, return the result
            -- If not, the handler is async and will call asyncCallback later
            if callbackCalled then
                return result;
            end
            -- Return nil to indicate async handling
            return nil;
        end);
    end
    
    LOG.std(nil, "debug", "BackgroundAgent", "Synced %d tools to AIChat (auto mode)", #toolDefinitions);
end

--[[
    Set custom system prompt
    @param prompt: string - The system prompt for the agent
]]
function BackgroundAgent:SetSystemPrompt(prompt)
    self.systemPrompt = prompt;
    if self.aiSession then
        self.aiSession:SetSystemPrompt(prompt);
    end
end

--[[
    Enable or disable debug mode for logging LLM IO
    @param enabled: boolean - Whether to enable debug logging
]]
function BackgroundAgent:SetDebugEnabled(enabled)
    self.debugEnabled = enabled;
    -- Also enable AIChat dev log for full raw message inspection
    ChatLogUtil.SetEnabled(enabled);
    AIChat.EnableDevLog(enabled);
    LOG.std(nil, "info", "BackgroundAgent", "Debug mode %s", enabled and "enabled" or "disabled");
end

--[[
    Check if debug mode is enabled
    @return boolean
]]
function BackgroundAgent:IsDebugEnabled()
    return self.debugEnabled;
end

--[[
    Log debug information to file
    @param category: string - Log category (e.g., "LLM_INPUT", "LLM_OUTPUT")
    @param fmt: string - Format string
    @param ...: varargs - Format arguments
]]
function BackgroundAgent:DebugLog(category, fmt, ...)
    if not self.debugEnabled then
        return;
    end
    LOG.std(nil, "debug", "BackgroundAgent", "[%s] " .. fmt, category, ...);
end

--[[
    Set the update interval for background processing
    @param interval: number - Interval in milliseconds
]]
function BackgroundAgent:SetUpdateInterval(interval)
    self.updateInterval = interval or 1000;
    -- If already playing, restart timer with new interval
    if self.playbackState == "playing" and self.updateTimer then
        self.updateTimer:Change(self.updateInterval, self.updateInterval);
    end
    return self;
end

--[[
    Start continuous background agent processing (Play mode)
    The agent will continuously capture context and make LLM calls at the update interval.
]]
function BackgroundAgent:Play()
    if self.playbackState == "playing" then
        return self;
    end
    ChatLogUtil.SetEnabled(true);
    AIChat.EnableDevLog(true);
    -- Switch scene vision to active mode so it continuously captures on scene changes
    SceneVisionManager:SetPassiveMode(false);
    
    local wasPlaying = self.playbackState == "paused";
    self.playbackState = "playing";
    
    -- Create or restart update timer
    if not self.updateTimer then
        self.updateTimer = commonlib.Timer:new({
            callbackFunc = function(timer)
                self:OnUpdate();
            end
        });
    end
    self.updateTimer:Change(0, self.updateInterval);
    
    -- Discover available copilots (only on first play)
    if not wasPlaying then
        self:DiscoverCopilots();
        
        -- Auto-start learning session if we have a primary task
        if self.primaryTask and not self.isLearningInProgress then
            -- Schedule the initial learning prompt after a short delay to ensure everything is initialized
            commonlib.TimerManager.SetTimeout(function()
                if self.playbackState == "playing" and self.primaryTask and not self.isLearningInProgress then
                    self:StartInitialLearningSession();
                end
            end, 500); -- 500ms delay for initialization
        end
    end
    
    -- Emit signals
    self:played();
    
    LOG.std(nil, "info", "BackgroundAgent", "Agent playing with %dms update interval", self.updateInterval);
    return self;
end

--[[
    Enable background agent processing (deprecated, use Play() instead)
]]
function BackgroundAgent:Enable()
    return self:Play();
end

--[[
    Pause background agent processing (keeps state, can resume with Play())
]]
function BackgroundAgent:Pause()
    if self.playbackState ~= "playing" then
        return self;
    end
    
    self.playbackState = "paused";
    
    -- Stop timer but keep it for resume
    if self.updateTimer then
        self.updateTimer:Change(); -- nil stops the timer
    end
    
    -- Emit paused signal
    self:paused();
    
    LOG.std(nil, "info", "BackgroundAgent", "Agent paused");
    return self;
end

--[[
    Stop background agent processing completely (clears state)
]]
function BackgroundAgent:Stop()
    if self.playbackState == "stopped" then
        return self;
    end
    
    self.playbackState = "stopped";
    
    -- Stop and destroy timer
    if self.updateTimer then
        self.updateTimer:Change(); -- nil stops the timer
        self.updateTimer = nil;
    end

    if self.voiceLLMThrottle.pendingTimer then
        self.voiceLLMThrottle.pendingTimer:Change(); -- nil stops the timer
        self.voiceLLMThrottle.pendingTimer = nil;
    end
    
    -- Abort any pending AI requests
    if self.aiSession then
        self.aiSession:Abort();
    end
    
    -- Clear caches
    self.cachedSceneImage = nil;
    self.cachedSceneText = nil;
    self.lastStepContext = nil;
    self.lastStepResult = nil;
    
    -- Clear TTS queue
    self:ClearTTSQueue();
    
    -- Clear UI tool queue and close any open UI
    self:ClearUIToolQueue();
    
    -- Unregister NPLJS handlers
    self:UnregisterNPLJSHandlers();
    
    -- Emit signals
    self:stopped();
    
    LOG.std(nil, "info", "BackgroundAgent", "Agent stopped");
    return self;
end

--[[
    Disable background agent processing (deprecated, use Stop() instead)
]]
function BackgroundAgent:Disable()
    return self:Stop();
end

--[[
    Execute a single step: runs one iteration of the Play/OnUpdate loop.
    This is useful for debugging the agent's behavior.
    
    Calling Step() will automatically pause the agent if it's currently playing.
    The step reuses the same logic as Play()+OnUpdate() — it initialises the
    AI session and copilots if needed, temporarily sets the playback state to
    "playing" so that OnUpdate() executes normally, then always leaves the
    agent in the "paused" state.  Any async LLM work kicked off by OnUpdate
    continues in the background; isStepInProgress is reset synchronously once
    the update has been dispatched.
    
    @param callback: function(result) - Optional callback invoked after the
        update iteration has been dispatched.
        result = {
            success = boolean,
            timestamp = number,
        }
    @return self for chaining
]]
function BackgroundAgent:Step(callback)
    if self.isStepInProgress then
        LOG.std(nil, "warn", "BackgroundAgent", "Step already in progress, ignoring");
        return self;
    end
    
    -- Automatically pause if currently playing
    if self.playbackState == "playing" then
        self:Pause();
    end
    
    -- Enable debug mode when stepping (also enables ChatLogUtil and AIChat dev log)
    self:SetDebugEnabled(true);
    
    self.isStepInProgress = true;
    LOG.std(nil, "info", "BackgroundAgent", "Step: running single update iteration...");
    
    -- Initialize AI session if needed
    self:InitAISession();
    
    -- Discover copilots if not done
    if #self.discoveredCopilots == 0 then
        self:DiscoverCopilots();
    end
    
    -- Step() is a debug tool: always make exactly one LLM call, bypassing all
    -- the guards (idle threshold, isLearningInProgress, isLLMProcessing, etc.)
    -- that are designed for the continuous Play/OnUpdate loop.
    
    -- Clear blocking flags so ProcessWithLLM proceeds unconditionally
    self.isLearningInProgress = false;
    self.isLLMProcessing = false;
    
    -- Build an appropriate prompt
    local prompt;
    local includeImage = true;
    if self.primaryTask then
        if self.observationMode.enabled then
            prompt = [[Look at the current scene in the screenshot and:
1. Comment on something interesting you see
2. Use `show_learning_content` to introduce a related English word
3. Keep it brief and engaging (1-2 sentences)
4. IMPORTANT: Call `record_observation` with the word you taught]];
        else
            prompt = "Continue the learning session. Review the student's progress and present the next activity. Use tools to engage the student.";
        end
    else
        prompt = "Observe the current scene and describe what you see. If the user needs help, offer assistance.";
    end
    
    LOG.std(nil, "info", "BackgroundAgent", "Step: sending LLM request (primaryTask=%s, observationMode=%s)",
        tostring(self.primaryTask ~= nil), tostring(self.observationMode.enabled));
    
    local self_ = self;
    self:ProcessWithLLM(prompt, function(result)
        self_.isLearningInProgress = false;
        if result and result.success then
            self_.learningProgress.lastActivityTime = commonlib.TimerManager.GetCurrentTime();
            LOG.std(nil, "info", "BackgroundAgent", "Step: LLM call completed successfully");
        else
            LOG.std(nil, "warn", "BackgroundAgent", "Step: LLM call failed");
        end
        
        local stepResult = {
            success = result and result.success or false,
            timestamp = os.time(),
        };
        self_.lastStepResult = result;
        
        -- Emit stepped signal
        self_:stepped(stepResult);
        
        if callback then
            callback(stepResult);
        end
    end, {includeImage = includeImage, skipChatHistory = false});
    
    -- Always end in paused state
    self.playbackState = "paused";
    self.isStepInProgress = false;
    
    LOG.std(nil, "info", "BackgroundAgent", "Step: LLM request dispatched");
    
    return self;
end

--[[
    Get markdown list of available tools
    @return string - Markdown formatted tools list
]]
function BackgroundAgent:GetToolsListMarkdown()
    local md = {};
    for name, tool in pairs(self.tools) do
        local desc = tool.schema and tool.schema.description or "No description";
        table.insert(md, string.format("- **%s**: %s", name, desc));
    end
    return table.concat(md, "\n");
end

--[[
    Get the last step context (for debugging)
    @return table - Last captured context from Step()
]]
function BackgroundAgent:GetLastStepContext()
    return self.lastStepContext;
end

--[[
    Get the last step result (for debugging)
    @return table - Last LLM result from Step()
]]
function BackgroundAgent:GetLastStepResult()
    return self.lastStepResult;
end

--[[
    Check if a step is currently in progress
    @return boolean
]]
function BackgroundAgent:IsStepInProgress()
    return self.isStepInProgress;
end

--[[
    Get current playback state
    @return string - "stopped", "playing", or "paused"
]]
function BackgroundAgent:GetPlaybackState()
    return self.playbackState;
end

--[[
    Check if agent is playing (continuous mode)
    @return boolean
]]
function BackgroundAgent:IsPlaying()
    return self.playbackState == "playing";
end

--[[
    Check if agent is paused
    @return boolean
]]
function BackgroundAgent:IsPaused()
    return self.playbackState == "paused";
end

--[[
    Check if agent is stopped
    @return boolean
]]
function BackgroundAgent:IsStopped()
    return self.playbackState == "stopped";
end

--[[
    Background update callback - called periodically by timer
]]
function BackgroundAgent:OnUpdate()
    if self.playbackState ~= "playing" then
        return;
    end
    
    -- Process pending tasks
    self:ProcessPendingTasks();
    
    -- If we have a primary learning task and no recent voice input, 
    -- proactively drive the learning session
    if self.primaryTask and not self.isLearningInProgress then
        self:DriveLearningSessionIfNeeded();
    elseif self.primaryTask and self.isLearningInProgress then
        -- Periodically log if we're stuck in learning progress
        local now = commonlib.TimerManager.GetCurrentTime();
        if not self.lastStuckLogTime or (now - self.lastStuckLogTime) > 30000 then
            LOG.std(nil, "debug", "BackgroundAgent", "[OnUpdate] Skipping drive: isLearningInProgress=true");
            self.lastStuckLogTime = now;
        end
    end
    
    -- In observation mode, also check for time-based observation trigger
    if self.observationMode.enabled and not self.isLearningInProgress then
        self:CheckTimedObservationTrigger();
    end
end

--[[
    Check if we should trigger a timed observation (even without scene changes)
    Called periodically in observation mode to maintain engagement
]]
function BackgroundAgent:CheckTimedObservationTrigger()
    if not self.observationMode.enabled then return; end
    
    local now = commonlib.TimerManager.GetCurrentTime();
    local timeSinceLastObservation = now - (self.observationMode.lastObservationTime or 0);
    local lastActivity = self.learningProgress.lastActivityTime or 0;
    local timeSinceLastActivity = now - lastActivity;
    
    -- Use longer interval for timed observations (2x the scene-change interval)
    local timedObservationInterval = self.observationMode.observationInterval * 2;
    
    -- Only trigger if: 1) enough time since last observation, 2) user hasn't been active recently
    if timeSinceLastObservation < timedObservationInterval then
        return;
    end
    
    -- If user was recently active (within idle prompt interval), wait for scene changes instead
    if timeSinceLastActivity < self.observationMode.idlePromptInterval then
        return;
    end
    
    -- Don't overlap with existing LLM calls
    if self.voiceLLMThrottle.isProcessing or self.isLLMProcessing then
        return;
    end
    
    -- Don't interrupt if user is in the middle of a learning tool UI
    if self.currentUISession then
        return;
    end
    
    LOG.std(nil, "info", "BackgroundAgent", "Timed observation triggered: %d seconds since last observation",
        math.floor(timeSinceLastObservation / 1000));
    
    self:TriggerProactiveObservation();
end

--[[
    Proactively drive the learning session if needed
    Called periodically to keep the learning task moving forward
]]
function BackgroundAgent:DriveLearningSessionIfNeeded()
    -- Check if we should initiate a learning interaction
    local now = commonlib.TimerManager.GetCurrentTime();  -- milliseconds
    local lastActivity = self.learningProgress.lastActivityTime or 0;  -- milliseconds
    
    -- Use different idle thresholds based on mode
    local idleThreshold;
    if self.observationMode.enabled then
        -- In observation mode, use the configured idle prompt interval (default 30 seconds)
        idleThreshold = self.observationMode.idlePromptInterval;
    else
        -- In structured learning mode, use longer threshold (3 minutes)
        idleThreshold = CONFIG.structuredLearningIdleThreshold;
    end
    
    local idleTime = now - lastActivity;
    
    -- Don't prompt too frequently
    if idleTime < idleThreshold then
        -- Only log occasionally to avoid spam
        if self.lastIdleLogTime == nil or (now - self.lastIdleLogTime) > 10000 then
            LOG.std(nil, "debug", "BackgroundAgent", "[DriveSession] Waiting: idle %ds < threshold %ds (mode=%s)",
                math.floor(idleTime / 1000), math.floor(idleThreshold / 1000),
                self.observationMode.enabled and "observation" or "structured");
            self.lastIdleLogTime = now;
        end
        return;
    end
    
    -- Don't overlap with existing LLM calls
    if self.voiceLLMThrottle.isProcessing or self.isLLMProcessing then
        LOG.std(nil, "debug", "BackgroundAgent", "[DriveSession] Skipped: LLM busy (voice=%s, llm=%s)",
            tostring(self.voiceLLMThrottle.isProcessing), tostring(self.isLLMProcessing));
        return;
    end
    
    -- Don't interrupt if user is in the middle of a learning tool UI
    if self.currentUISession then
        LOG.std(nil, "debug", "BackgroundAgent", "[DriveSession] Skipped: UI session active");
        return;
    end
    
    -- Mark as in progress to prevent overlapping calls
    self.isLearningInProgress = true;
    
    LOG.std(nil, "info", "BackgroundAgent", "Proactive learning prompt triggered after %d seconds idle (mode: %s)", 
        (now - lastActivity) / 1000, self.observationMode.enabled and "observation" or "structured");
    
    -- Build a prompt based on mode
    local prompt;
    if self.observationMode.enabled then
        -- Count concepts already taught to guide tool selection
        local conceptsTaughtCount = 0;
        if self.learningProgress.observationStats and self.learningProgress.observationStats.conceptsTaught then
            for _ in pairs(self.learningProgress.observationStats.conceptsTaught) do
                conceptsTaughtCount = conceptsTaughtCount + 1;
            end
        end
        
        if conceptsTaughtCount >= 2 then
            -- Time to test
            prompt = string.format([[The user has been idle. You've taught %d concepts already.

Now let's do a quick fun quiz! Use ONE of these test tools:
- `test_multiple_choice` - A quick vocabulary quiz
- `test_words_speaking` - Practice saying a word
- `test_words_spelling` - Spell a word you taught

Make it feel like a game! After the test, call `record_observation` to track progress.]], conceptsTaughtCount);
        else
            -- Observation mode: look at the scene and teach something
            prompt = [[The user has been idle for a while. Look at the current scene in the screenshot and:
1. Comment on something interesting you see
2. Use `show_learning_content` to introduce a related English word
3. Keep it brief and engaging (1-2 sentences)
4. IMPORTANT: Call `record_observation` with the word you taught]];
        end
    else
        -- Structured mode: prompt to continue the task
        prompt = "Idle for a while. Prompt the user to continue or suggest a follow-up practice based on progress. Keep it concise and friendly.";
    end
    
    self:ProcessWithLLM(prompt, function(result)
        self.isLearningInProgress = false;
        -- Only update lastActivityTime on success to allow faster retry on errors
        if result and result.success then
            self.learningProgress.lastActivityTime = commonlib.TimerManager.GetCurrentTime();
        else
            -- On error, set a shorter idle time to allow quicker recovery
            LOG.std(nil, "debug", "BackgroundAgent", "LLM call failed, allowing faster retry");
        end
    end, {includeImage = self.observationMode.enabled, skipChatHistory = false});
end

--[[
    Start the initial learning session when Play() is called with a task
    This provides a greeting and begins teaching immediately without waiting for user input
]]
function BackgroundAgent:StartInitialLearningSession()
    if not self.primaryTask then 
        LOG.std(nil, "debug", "BackgroundAgent", "[InitialSession] Skipped: no primaryTask");
        return; 
    end
    if self.isLearningInProgress then 
        LOG.std(nil, "debug", "BackgroundAgent", "[InitialSession] Skipped: already in progress");
        return; 
    end
    if self.isLLMProcessing then 
        LOG.std(nil, "debug", "BackgroundAgent", "[InitialSession] Skipped: LLM processing");
        return; 
    end
    
    LOG.std(nil, "info", "BackgroundAgent", "Starting initial learning session (observationMode=%s)", 
        tostring(self.observationMode.enabled));
    
    -- Mark as in progress
    self.isLearningInProgress = true;
    
    -- Build initial prompt based on mode
    local prompt;
    if self.observationMode.enabled then
        -- Observation mode: greet and look at scene, use tools
        prompt = [[This is the start of a new learning session. The user just entered the scene.
1. Greet the user warmly (this is your first message, so greeting is appropriate)
2. Look at the current scene in the screenshot
3. Comment on something interesting you see
4. Use `show_learning_content` to introduce a relevant English word with translation and example
5. IMPORTANT: After teaching, call `record_observation` with the word you introduced
6. Keep your spoken response brief and engaging]];
    else
        -- Structured mode: greet and introduce the learning task, use tools
        prompt = [[This is the start of a new learning session. The user just entered the scene.
1. Greet the user warmly (this is your first message, so greeting is appropriate)
2. Briefly introduce what you'll be learning together
3. Use `show_learning_content` to show the first word/content
4. IMPORTANT: After teaching, call `set_learning_progress` to record the word you introduced]];
    end
    
    -- Use pcall-wrapped callback to ensure isLearningInProgress is always reset
    local self_ = self;
    self:ProcessWithLLM(prompt, function(result)
        -- Always reset the flag, even if something goes wrong
        self_.isLearningInProgress = false;
        if result and result.success then
            self_.learningProgress.lastActivityTime = commonlib.TimerManager.GetCurrentTime();
            LOG.std(nil, "info", "BackgroundAgent", "Initial learning session started successfully");
        else
            LOG.std(nil, "warn", "BackgroundAgent", "Initial learning session failed, will retry via idle trigger");
        end
    end, {includeImage = true, skipChatHistory = false});
end

--[[
    Process any pending tasks in the queue
]]
function BackgroundAgent:ProcessPendingTasks()
    if #self.pendingTasks == 0 then
        return;
    end
    
    local task = table.remove(self.pendingTasks, 1);
    if task and task.callback then
        task.callback();
    end
end

--[[
    Add a task to the pending queue
    @param taskFunc: function - The task function to execute
]]
function BackgroundAgent:QueueTask(taskFunc)
    table.insert(self.pendingTasks, {callback = taskFunc});
end

--------------------------------------------------------------------------------
-- Scene Context Capture
--------------------------------------------------------------------------------

--[[
    Capture the current scene as an image URL
    Uses SceneVisionManager for scene capture - in passive mode, only captures if scene is dirty
    @param callback: function(imageUrl) - Called with the image URL
    @param width: number (optional) - Screenshot width (ignored, uses SceneVisionManager settings)
    @param height: number (optional) - Screenshot height (ignored, uses SceneVisionManager settings)
]]
function BackgroundAgent:CaptureSceneAsImage(callback, width, height)
    -- Check if scene is dirty (changed since last capture)
    -- If dirty, force capture a new screenshot before returning
    if self.sceneDirty then
        LOG.std(nil, "debug", "BackgroundAgent", "Scene dirty, capturing fresh screenshot before LLM request");
        SceneVisionManager:ForceCaptureNow(function(entry)
            -- Clear dirty flag after capture
            self.sceneDirty = false;
            
            if entry and entry.path then
                FileTools.UpLoadVisionFile(entry.path, function(url)
                    self.lastContextCaptureTime = commonlib.TimerManager.GetCurrentTime();
                    
                    -- Update history entry with URL
                    if self.lastSceneVisionEntry then
                        self.lastSceneVisionEntry.imageUrl = url;
                    end
                    
                    self:sceneContextCaptured(url);
                    if callback and type(callback) == "function" then
                        callback(url);
                    end
                end);
            else
                -- Fallback: capture failed, try cached
                local latestVision = self:GetLatestSceneVision();
                if callback and type(callback) == "function" then
                    callback(latestVision and latestVision.imageUrl or nil);
                end
            end
        end);
        return;
    end
    
    -- Scene is not dirty - use cached screenshot if available
    local latestVision = self:GetLatestSceneVision();
    if latestVision and latestVision.imageUrl then
        -- Return cached image URL
        self.lastContextCaptureTime = commonlib.TimerManager.GetCurrentTime();
        if callback and type(callback) == "function" then
            callback(latestVision.imageUrl);
        end
        return;
    end
    
    -- No cached screenshot available, force capture
    SceneVisionManager:ForceCaptureNow(function(entry)
        self.sceneDirty = false;
        
        if entry and entry.path then
            FileTools.UpLoadVisionFile(entry.path, function(url)
                self.lastContextCaptureTime = commonlib.TimerManager.GetCurrentTime();
                
                -- Update history entry with URL
                if self.lastSceneVisionEntry then
                    self.lastSceneVisionEntry.imageUrl = url;
                end
                
                self:sceneContextCaptured(url);
                if callback and type(callback) == "function" then
                    callback(url);
                end
            end);
        else
            -- Fallback: capture failed
            if callback and type(callback) == "function" then
                callback(nil);
            end
        end
    end);
end

--[[
    Get text description of the current scene
    @return table - Scene context with entities, blocks, player info
]]
function BackgroundAgent:GetSceneTextContext()
    local context = {
        timestamp = os.time(),
        player = nil,
        entities = {},
        nearbyBlocks = {},
        cameraPosition = nil,
    };
    
    -- Get player information
    local player = EntityManager.GetPlayer();
    if player then
        local x, y, z = player:GetBlockPos();
        context.player = {
            name = player:GetDisplayName() or "Player",
            position = {x, y, z},
            facing = player:GetFacing(),
        };
    end
    
    -- Get camera position
    local att = ParaCamera.GetAttributeObject();
    if att then
        context.cameraPosition = {
            x = att:GetField("CameraObjectDistance", 0),
            yaw = att:GetField("CameraLiftupAngle", 0),
            pitch = att:GetField("CameraRotY", 0),
        };
    end
    
    -- Enumerate nearby entities
    if player then
        local px, py, pz = player:GetBlockPos();
        local radius = 10; -- blocks
        
        local entities = EntityManager.GetEntitiesByMinMax(
            px - radius, py, pz - radius,
            px + radius, py + radius, pz + radius
        );
        
        if entities then
            for _, entity in ipairs(entities) do
                if entity ~= player then
                    local ex, ey, ez = entity:GetBlockPos();
                    local entityInfo = {
                        name = entity:GetDisplayName() or nil,
                        position = {ex, ey, ez},
                    };
                    if entity.GetModelFile then
                        entityInfo.model = entity:GetModelFile();
                    end
                    
                    table.insert(context.entities, entityInfo);
                end
            end
        end
    end
    
    -- Cache the result
    self.cachedSceneText = context;
    
    return context;
end

--[[
    Get combined scene context (image + text)
    @param callback: function(context) - Called with {image, text, markdown}
]]
function BackgroundAgent:GetFullSceneContext(callback)
    local textContext = self:GetSceneTextContext();
    
    self:CaptureSceneAsImage(function(imageUrl)
        local hasImage = imageUrl and imageUrl ~= "";
        local fullContext = {
            image = imageUrl,
            text = textContext,
            markdown = self:FormatSceneContextAsMarkdown(textContext, hasImage),
        };
        
        if callback then
            callback(fullContext);
        end
    end);
end

--[[
    Format scene context as markdown for LLM consumption
    @param context: table - Scene context from GetSceneTextContext
    @param hasImage: boolean (optional) - Whether an image is included with this context
    @param isFullMode: boolean (optional) - Whether to include full scene details (default: true)
           When false, returns brief version with only position and direction
    @return string - Markdown formatted description
]]
function BackgroundAgent:FormatSceneContextAsMarkdown(context, hasImage, isFullMode)
    -- Default to full mode if not specified
    if isFullMode == nil then
        isFullMode = true;
    end
    
    -- Brief mode: only essential position info
    if not isFullMode then
        local md = "## Scene Brief\n\n";
        if context.player then
            local p = context.player;
            local pos = p.position or {};
            md = md .. string.format("- **Position:** Block(%d, %d, %d)\n",
                pos[1] or 0, pos[2] or 0, pos[3] or 0
            );
            md = md .. string.format("- **Facing:** %.2f radians\n", p.facing or 0);
        end
        -- Include selected block if available
        if context.selectedBlock then
            md = md .. string.format("- **Selected Block:** %s\n", context.selectedBlock.name or "Unknown");
        end
        md = md .. "\n";
        return md;
    end
    
    -- Full mode: complete scene context
    local md = "## Current Scene Context\n\n";
    
    -- Add concise image guidance if image is provided (balanced token vs accuracy)
    if hasImage then
        md = md .. [[### Visual Scene
*Screenshot attached.* Focus on: objects/characters visible, environment type, any learning-related content (text, signs, items).
]];
    end
    
    -- Player info
    if context.player then
        local p = context.player;
        local pos = p.position or {};
        md = md .. string.format("### Player\n- **Name:** %s\n- **Position:** Block(%d, %d, %d)\n- **Facing:** %.2f radians\n\n",
            p.name or "Unknown",
            pos[1] or 0, pos[2] or 0, pos[3] or 0,
            p.facing or 0
        );
    end
    
    -- Camera info
    if context.cameraPosition then
        local cam = context.cameraPosition;
        md = md .. string.format("### Camera\n- **Distance:** %.1f\n- **Yaw:** %.2f\n- **Pitch:** %.2f\n\n",
            cam.x or 0, cam.yaw or 0, cam.pitch or 0
        );
    end
    
    -- Removed verbose analysis instructions to save tokens
    -- LLM already knows how to analyze images
    
    return md;
end

--------------------------------------------------------------------------------
-- Copilot Auto-Discovery
--------------------------------------------------------------------------------

--[[
    Discover all available copilots and their capabilities
    @return table - Discovered copilots with their tools
]]
function BackgroundAgent:DiscoverCopilots()
    self.discoveredCopilots = {};
    
    -- Try to load CopilotManager
    if not CopilotManager or not CopilotManager.GetInstance then
        return self.discoveredCopilots;
    end
    
    local manager = CopilotManager.GetInstance();
    if not manager or not manager.copilots then
        return self.discoveredCopilots;
    end
    
    -- Iterate all registered copilots
    for _, copilot in ipairs(manager.copilots) do
        local copilotInfo = self:ExtractCopilotCapabilities(copilot);
        if copilotInfo then
            table.insert(self.discoveredCopilots, copilotInfo);
            
            -- Register copilot's tools
            self:RegisterCopilotTools(copilotInfo);
            
            -- Emit discovery signal
            self:copilotDiscovered(copilotInfo);
        end
    end
    
    LOG.std(nil, "info", "BackgroundAgent", "Discovered %d copilots", #self.discoveredCopilots);
    
    return self.discoveredCopilots;
end

--[[
    Extract capabilities from a copilot instance
    @param copilot: CopilotBase instance
    @return table - Copilot info with capabilities
]]
function BackgroundAgent:ExtractCopilotCapabilities(copilot)
    if not copilot then
        return nil;
    end
    
    local info = {
        instance = copilot,
        name = "Unknown",
        description = "",
        tools = {},
        tasks = {},
        quickReplies = {},
    };
    
    -- Extract from GetAICharConfig if available
    if copilot.GetAICharConfig then
        local config = copilot:GetAICharConfig();
        if config then
            if config.character then
                info.name = copilot:GetName() or info.name;
                info.displayName = config.character.name or info.name;
                info.description = config.character.description or "";
                info.role = config.character.role;
            end
            if config.objective then
                info.objective = config.objective.description;
            end
            if config.quick_replies then
                for _, reply in ipairs(config.quick_replies) do
                    table.insert(info.quickReplies, {
                        text = reply.text,
                        action = reply.uiname,
                    });
                end
            end
            if config.tools then
                for _, tool in ipairs(config.tools) do
                    local func = tool["function"]
                    if func and type(func) == "table" then
                        table.insert(info.tools, {
                            name = func.name or "Unknown",
                            description = func.description or "",
                            copilotName = info.name,
                            action = func.name,
                            parameters = func.parameters or {},
                        });
                    end
                end
            end
        end
    end
    
    -- Extract tasks
    if copilot.GetAllTasks then
        local tasks = copilot:GetAllTasks();
        if tasks then
            for _, task in ipairs(tasks) do
                local taskInfo = {
                    name = task.name or task.class_name or "Unknown",
                    state = task.state,
                    description = task.description,
                };
                
                -- Get action buttons as available operations
                if task.GetActionButtons then
                    taskInfo.actions = task:GetActionButtons({});
                end
                
                table.insert(info.tasks, taskInfo);
            end
        end
    end
    
    -- Build tools from quick replies
    for _, reply in ipairs(info.quickReplies) do
        local tool = {
            name = string.format("%s_%s", info.name, reply.action or "action"),
            description = string.format("Ask %s to: %s", info.name, reply.text),
            action = reply.action,
            parameters = {
                type = "object",
                properties = {},
                required = {},
            },
        };
        table.insert(info.tools, tool);
    end
    
    return info;
end

--[[
    Register tools from a discovered copilot
    @param copilotInfo: table - Copilot info from ExtractCopilotCapabilities
]]
function BackgroundAgent:RegisterCopilotTools(copilotInfo)
    if not copilotInfo or not copilotInfo.tools then
        return;
    end
    
    for _, tool in ipairs(copilotInfo.tools) do
        self:RegisterTool(tool.name, {
            description = tool.description,
            parameters = tool.parameters,
        }, function(params, callback)
            self:ExecuteCopilotTool(copilotInfo, tool, params, callback);
        end);
    end
end

--[[
    Execute a tool on a copilot
    @param copilotInfo: table - The copilot info
    @param tool: table - The tool definition
    @param params: table - Tool parameters
    @param callback: function(result) - Called with result
]]
function BackgroundAgent:ExecuteCopilotTool(copilotInfo, tool, params, callback)
    local copilot = copilotInfo.instance;
    
    if not copilot then
        if callback then
            callback({
                success = false,
                llm_result = "Copilot instance not found",
            });
        end
        return;
    end
    
    -- Try to execute via the copilot's interface
    local llm_result = string.format("Dispatched action '%s' to %s", tool.action or "unknown", copilotInfo.name);
    
    -- If copilot has a HandleCommand method, use it
    if copilot.HandleCommand then
        local cmdResult = copilot:HandleCommand(tool.action, params);
        if cmdResult then
            llm_result = llm_result .. ", result: " .. tostring(cmdResult);
        end
    end
    
    if callback then
        callback({
            success = true,
            llm_result = llm_result,
        });
    end
end

--------------------------------------------------------------------------------
-- Tool Registration and Execution
--------------------------------------------------------------------------------

--[[
    Register a tool with schema and handler
    @param name: string - Tool name (unique identifier)
    @param schema: table - Tool schema {description, parameters}
    @param handler: function(params, callback) - Tool handler
]]
function BackgroundAgent:RegisterTool(name, schema, handler)
    self.tools[name] = {
        name = name,
        schema = schema,
        handler = handler,
    };
    
    LOG.std(nil, "debug", "BackgroundAgent", "Registered tool: %s", name);
    
    -- If AISession exists, register the tool callback immediately
    if self.aiSession then
        local toolDef = {
            type = "function",
            ["function"] = {
                name = name,
                description = schema.description or "",
                parameters = schema.parameters or {
                    type = "object",
                    properties = {},
                    required = {},
                },
            },
        };
        -- Update tools array and re-register callback
        local tools = self.aiSession.tools or {};
        -- Remove existing tool with same name
        for i = #tools, 1, -1 do
            if tools[i]["function"] and tools[i]["function"].name == name then
                table.remove(tools, i);
            end
        end
        table.insert(tools, toolDef);
        self.aiSession:SetTools(tools);
        
        -- Register callback
        self.aiSession:RegisterToolCallback(name, function(args, asyncCallback)
            local result = nil;
            local callbackCalled = false;
            
            handler(args or {}, function(handlerResult)
                callbackCalled = true;
                result = handlerResult;
                self:toolExecuted(name, args, handlerResult);
                if asyncCallback and type(asyncCallback) == "function" then
                    asyncCallback(handlerResult);
                end
            end);
            
            if callbackCalled then
                return result;
            end
            return nil;
        end);
    end
end

--[[
    Unregister a tool
    @param name: string - Tool name to remove
]]
function BackgroundAgent:UnregisterTool(name)
    self.tools[name] = nil;
    
    -- Also remove from AISession if exists
    if self.aiSession then
        self.aiSession.tool_callbacks[name] = nil;
        local tools = self.aiSession.tools or {};
        for i = #tools, 1, -1 do
            if tools[i]["function"] and tools[i]["function"].name == name then
                table.remove(tools, i);
            end
        end
        self.aiSession:SetTools(tools);
    end
end

--[[
    Get all tool definitions in OpenAI function calling format
    @return table - Array of tool definitions
]]
function BackgroundAgent:GetAllToolDefinitions()
    local definitions = {};
    
    for name, tool in pairs(self.tools) do
        local def = {
            type = "function",
            ["function"] = {
                name = name,
                description = tool.schema.description or "",
                parameters = tool.schema.parameters or {
                    type = "object",
                    properties = {},
                    required = {},
                },
            },
        };
        table.insert(definitions, def);
    end
    
    return definitions;
end

--[[
    Execute a tool call by name
    @param toolName: string - The tool to execute
    @param params: table - Parameters for the tool
    @param callback: function(result) - Called with execution result
]]
function BackgroundAgent:ExecuteToolCall(toolName, params, callback)
    local tool = self.tools[toolName];
    
    if not tool then
        local result = {
            success = false,
            error = string.format("Tool '%s' not found", toolName),
        };
        if callback then
            callback(result);
        end
        self:toolExecuted(toolName, params, result);
        return;
    end
    
    -- Execute the handler
    tool.handler(params or {}, function(result)
        result = result or {success = true};
        
        if callback then
            callback(result);
        end
        
        self:toolExecuted(toolName, params, result);
    end);
end

--[[
    Register built-in tools for scene manipulation
]]
function BackgroundAgent:RegisterBuiltinTools()
    -- Tool: Get scene information
    self:RegisterTool("get_scene_info", {
        description = "Get information about the current 3D scene including player position and nearby entities",
        parameters = {
            type = "object",
            properties = {
                include_entities = {
                    type = "boolean",
                    description = "Whether to include nearby entities",
                },
            },
            required = {},
        },
    }, function(params, callback)
        local context = self:GetSceneTextContext();
        callback({
            success = true,
            llm_result = self:FormatSceneContextAsMarkdown(context),
        });
    end);
    
    -- Tool: Move player to location
    self:RegisterTool("move_to_location", {
        description = "Move the player to a specific block location",
        parameters = {
            type = "object",
            properties = {
                x = {type = "number", description = "X block coordinate"},
                y = {type = "number", description = "Y block coordinate"},
                z = {type = "number", description = "Z block coordinate"},
            },
            required = {"x", "y", "z"},
        },
    }, function(params, callback)
        local player = EntityManager.GetPlayer();
        if player then
            local rx, ry, rz = BlockEngine:real(params.x, params.y, params.z);
            player:SetPosition(rx, ry, rz);
            callback({
                success = true,
                llm_result = string.format("Moved player to block (%d, %d, %d)", params.x, params.y, params.z),
            });
        else
            callback({success = false, llm_result = "No player found"});
        end
    end);
    
    -- Tool: Place block
    self:RegisterTool("place_block", {
        description = "Place a block at a specific location",
        parameters = {
            type = "object",
            properties = {
                x = {type = "number", description = "X block coordinate"},
                y = {type = "number", description = "Y block coordinate"},
                z = {type = "number", description = "Z block coordinate"},
                block_id = {type = "number", description = "Block type ID to place"},
            },
            required = {"x", "y", "z", "block_id"},
        },
    }, function(params, callback)
        local x, y, z = params.x, params.y, params.z;
        local blockId = params.block_id;
        
        BlockEngine:SetBlock(x, y, z, blockId);
        
        callback({
            success = true,
            llm_result = string.format("Placed block %d at (%d, %d, %d)", blockId, x, y, z),
        });
    end);
    
    -- Tool: Remove block
    self:RegisterTool("remove_block", {
        description = "Remove a block at a specific location",
        parameters = {
            type = "object",
            properties = {
                x = {type = "number", description = "X block coordinate"},
                y = {type = "number", description = "Y block coordinate"},
                z = {type = "number", description = "Z block coordinate"},
            },
            required = {"x", "y", "z"},
        },
    }, function(params, callback)
        local x, y, z = params.x, params.y, params.z;
        if not x or not y or not z then
            callback({success = false, llm_result = "Missing required coordinates"});
            return;
        end
        BlockEngine:SetBlock(x, y, z, 0);
        
        callback({
            success = true,
            llm_result = string.format("Removed block at (%d, %d, %d)", x, y, z),
        });
    end);
    
    -- Tool: Query entities
    self:RegisterTool("query_entities", {
        description = "Query entities in a specific area",
        parameters = {
            type = "object",
            properties = {
                center_x = {type = "number", description = "Center X coordinate"},
                center_y = {type = "number", description = "Center Y coordinate"},
                center_z = {type = "number", description = "Center Z coordinate"},
                radius = {type = "number", description = "Search radius in blocks"},
            },
            required = {"center_x", "center_y", "center_z"},
        },
    }, function(params, callback)
        local cx, cy, cz = params.center_x, params.center_y, params.center_z;
        local radius = params.radius or 20;
        local entities = EntityManager.GetEntitiesByMinMax(
            cx - radius, cy, cz - radius,
            cx + radius, cy + radius, cz + radius
        );
        
        local results = {};
        if entities then
            for _, entity in ipairs(entities) do
                local ex, ey, ez = entity:GetBlockPos();
                table.insert(results, {
                    type = entity.class_name or "Unknown",
                    name = entity:GetDisplayName() or nil,
                    position = {x = ex, y = ey, z = ez},
                });
            end
        end
        
        callback({
            success = true,
            llm_result = string.format("Found %d entities: %s", #results, commonlib.serialize_compact(results) or "[]"),
        });
    end);
    
    -- Tool: List available copilots
    self:RegisterTool("list_copilots", {
        description = "List all available copilot subagents and their capabilities",
        parameters = {
            type = "object",
            properties = {},
            required = {},
        },
    }, function(params, callback)
        local copilotList = {};
        for _, copilot in ipairs(self.discoveredCopilots) do
            table.insert(copilotList, {
                name = copilot.name,
                description = copilot.description,
                role = copilot.role,
                objective = copilot.objective,
                taskCount = #copilot.tasks,
                toolCount = #copilot.tools,
            });
        end
        
        callback({
            success = true,
            llm_result = string.format("Found %d copilots: %s", #copilotList, commonlib.serialize_compact(copilotList) or "[]"),
        });
    end);
    
    -- Tool: Send message to copilot
    self:RegisterTool("send_message_to_copilot", {
        description = "Send a message or command to a specific copilot subagent",
        parameters = {
            type = "object",
            properties = {
                copilot_name = {type = "string", description = "Name of the target copilot"},
                message = {type = "string", description = "Message or command to send"},
            },
            required = {"copilot_name", "message"},
        },
    }, function(params, callback)
        local targetName = params.copilot_name;
        local message = params.message;
        
        -- Find the copilot
        local targetCopilot = nil;
        for _, copilot in ipairs(self.discoveredCopilots) do
            if copilot.name == targetName then
                targetCopilot = copilot;
                break;
            end
        end
        
        if not targetCopilot then
            callback({
                success = false,
                llm_result = string.format("Copilot '%s' not found", targetName),
            });
            return;
        end
        
        -- Try to send message via copilot's interface
        local instance = targetCopilot.instance;
        if instance and instance.OnReceiveMessage then
            local result = instance:OnReceiveMessage(message, self);
            callback({
                success = true,
                llm_result = string.format("Message sent to %s, response: %s", targetName, tostring(result)),
            });
        elseif instance and instance.HandleCommand then
            local result = instance:HandleCommand("message", {text = message});
            callback({
                success = true,
                llm_result = string.format("Command sent to %s, response: %s", targetName, tostring(result)),
            });
        else
            callback({
                success = true,
                llm_result = string.format("Message delivered to %s (no response handler)", targetName),
            });
        end
    end);
end

--------------------------------------------------------------------------------
-- Agent Task Tools Registration (Building, Planting, Fishing, Cooking)
--------------------------------------------------------------------------------

--[[
    Register agent task tools for dynamic control of building and life skill tasks.
    These tools provide a higher-level interface for the agent to control copilots.
]]
function BackgroundAgent:RegisterAgentTaskTools()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/AgentTaskTools.lua");
    local AgentTaskTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.AgentTaskTools");
    AgentTaskTools.RegisterToBackgroundAgent(self);
    LOG.std(nil, "info", "BackgroundAgent", "Agent task tools registered (building, planting, fishing, cooking)");
end

--------------------------------------------------------------------------------
-- Dynamic Copilot Tools Registration
--------------------------------------------------------------------------------

--[[
    Get copilot-specific prompt based on registered copilots
    Dynamically generates prompt text based on available copilots
    @return string - Copilot-specific prompt section
]]
function BackgroundAgent:GetCopilotPromptSection()
    local copilots = self.discoveredCopilots or {};
    if #copilots == 0 then
        return [[You have no copilot characters available.
Use other tools to interact with the scene directly.]];
    end
    
    local promptParts = {};
    table.insert(promptParts, "You can control the following copilot characters:\n");
    
    for _, copilot in ipairs(copilots) do
        local name = copilot.name or "Unknown";
        local displayName = copilot.displayName or name;
        local description = copilot.description or "";
        local role = copilot.role or "assistant";
        
        table.insert(promptParts, string.format("- **%s** (id: `%s`): %s\n", name, displayName, description));
        
        -- Add copilot-specific capabilities
        if copilot.tools and #copilot.tools > 0 then
            table.insert(promptParts, "  Capabilities: ");
            local toolNames = {};
            for _, tool in ipairs(copilot.tools) do
                table.insert(toolNames, tool.name);
            end
            table.insert(promptParts, table.concat(toolNames, ", ") .. "\n");
        end
    end
    
    table.insert(promptParts, "\nTo control a copilot, use `run_copilot_code` with:\n");
    table.insert(promptParts, "- copilotName: The copilot's id (e.g., `__my_pet_copilot__`)\n");
    table.insert(promptParts, "- code: Lua code with functions: Say(text, duration), WalkTo(x,y,z), WalkForward(distance), Wait(seconds), PlayAnimation(name)\n");
    table.insert(promptParts, "- Use GetPlayerBlockPos() to get player position, GetPosition() to get copilot position\n");
    table.insert(promptParts, "- Position functions return value [x,y,z]. Check if valid with pos[1], pos[2], pos[3]\n");
    
    return table.concat(promptParts);
end

--[[
    Check if any copilots are registered
    @return boolean
]]
function BackgroundAgent:HasCopilots()
    return self.discoveredCopilots and #self.discoveredCopilots > 0;
end

--[[
    Dynamically register tools for a newly added copilot
    Call this when a copilot is registered at runtime
    @param copilot: CopilotBase instance
]]
function BackgroundAgent:OnCopilotRegistered(copilot)
    if not copilot then return; end
    
    -- Extract capabilities and register tools
    local copilotInfo = self:ExtractCopilotCapabilities(copilot);
    if copilotInfo then
        -- Check if already discovered
        for i, existing in ipairs(self.discoveredCopilots) do
            if existing.name and 
                existing.name ~= "" and 
                existing.name == copilotInfo.name then
                -- Update existing entry
                self.discoveredCopilots[i] = copilotInfo;
                LOG.std(nil, "info", "BackgroundAgent", "Updated copilot: %s", copilotInfo.name);
                return;
            end
        end
        
        -- Add new copilot
        table.insert(self.discoveredCopilots, copilotInfo);
        self:RegisterCopilotTools(copilotInfo);
        self:copilotDiscovered(copilotInfo);
        self:InvalidateSystemPromptCache(); -- Copilot added, rebuild system prompt
        
        LOG.std(nil, "info", "BackgroundAgent", "Dynamically registered copilot: %s", copilotInfo.name);
    end
end

--[[
    Remove a copilot when it's unregistered
    @param name: string - The copilot's id to remove
]]
function BackgroundAgent:OnCopilotUnregistered(name)
    if not name then return; end
    
    for i, copilotInfo in ipairs(self.discoveredCopilots) do
        if copilotInfo.name == name then
            -- Unregister tools for this copilot
            for _, tool in ipairs(copilotInfo.tools or {}) do
                self:UnregisterTool(tool.name);
            end
            
            table.remove(self.discoveredCopilots, i);
            self:InvalidateSystemPromptCache(); -- Copilot removed, rebuild system prompt
            LOG.std(nil, "info", "BackgroundAgent", "Unregistered copilot: %s", copilotInfo.name);
            return;
        end
    end
end

--------------------------------------------------------------------------------
-- Learning Tools Registration (H5 Minigame Integration)
--------------------------------------------------------------------------------

--[[
    Register learning-related tools for H5 minigame integration
    These tools define schemas only - actual implementation is in H5 minigames
]]
function BackgroundAgent:RegisterLearningTools()
    -- Tool: Multiple choice test
    self:RegisterTool("test_multiple_choice", {
        description = "Present a multiple choice question to test the learner's knowledge. Returns when user selects an answer.",
        parameters = {
            type = "object",
            properties = {
                question = {
                    type = "string", 
                    description = "The question text to display",
                },
                options = {
                    type = "array",
                    items = {type = "string"},
                    description = "Array of answer options (2-4 choices)",
                },
                correctIndex = {
                    type = "number",
                    description = "Zero-based index of the correct answer",
                },
                hint = {
                    type = "string",
                    description = "Optional hint to show if user gets it wrong",
                },
                subject = {
                    type = "string",
                    description = "The subject/item being tested (e.g., the word being learned)",
                },
            },
            required = {"question", "options", "correctIndex"},
        },
    }, function(params, callback)
        self:LaunchLearningTool("test_multiple_choice", params, callback);
    end);
    
    -- Tool: Word speaking test (pronunciation)
    self:RegisterTool("test_words_speaking", {
        description = "Test the learner's pronunciation by having them speak a word. Shows the word and optional phonetic, plays audio, then listens for speech.",
        parameters = {
            type = "object",
            properties = {
                word = {
                    type = "string",
                    description = "The word to speak",
                },
                phonetic = {
                    type = "string",
                    description = "Phonetic transcription (IPA or simple)",
                },
                audioUrl = {
                    type = "string",
                    description = "URL to pronunciation audio file",
                },
                maxAttempts = {
                    type = "number",
                    description = "Maximum attempts allowed (default: 3)",
                },
                showHint = {
                    type = "boolean",
                    description = "Whether to show phonetic hint",
                },
            },
            required = {"word"},
        },
    }, function(params, callback)
        self:LaunchLearningTool("test_words_speaking", params, callback);
    end);
    
    -- Tool: Word spelling test
    self:RegisterTool("test_words_spelling", {
        description = "Test the learner's spelling by having them type a word. Can show hints like letter count or first letter.",
        parameters = {
            type = "object",
            properties = {
                word = {
                    type = "string",
                    description = "The correct spelling of the word",
                },
                hint = {
                    type = "string",
                    description = "Hint or definition to help identify the word",
                },
                showLetterCount = {
                    type = "boolean",
                    description = "Show number of letters as hint",
                },
                showFirstLetter = {
                    type = "boolean",
                    description = "Show first letter as hint",
                },
                audioUrl = {
                    type = "string",
                    description = "URL to pronunciation audio to play",
                },
                maxAttempts = {
                    type = "number",
                    description = "Maximum attempts allowed (default: 3)",
                },
                imageUrl = {
                    type = "string",
                    description = "Optional image hint URL",
                },
            },
            required = {"word"},
        },
    }, function(params, callback)
        self:LaunchLearningTool("test_words_spelling", params, callback);
    end);
    
    -- Tool: Run copilot code (control subagent actions)
    self:RegisterTool("run_copilot_code", {
        description = "Execute Lua code to control a copilot subagent. The code runs in a coroutine context with access to copilot methods like Say(), WalkTo(), Wait(), etc.",
        parameters = {
            type = "object",
            properties = {
                copilotName = {
                    type = "string",
                    description = "Name of the target copilot to control",
                },
                code = {
                    type = "string",
                    description = "Lua code to execute. Available functions: Say(text, duration), WalkTo(x,y,z), Wait(seconds), PlayAnimation(name)",
                },
            },
            required = {"copilotName", "code"},
        },
    }, function(params, callback)
        self:ExecuteCopilotCode(params.copilotName, params.code, callback);
    end);

    self:RegisterTool("run_terminal_code", {
        description = "Excute npl blockly code in code block environment.",
        parameters = {
            type = "object",
            properties = {
                code = {
                    type = "string",
                    description = "Npl blockly code to execute.",
                },
            },
            required = {"code"},
        },
    }, function(params, callback)
        self:ExecuteTerminalCode(params.code, callback);
    end);
    
    -- Tool: Show learning content (flashcard-style)
    self:RegisterTool("show_learning_content", {
        description = "Display learning content like a flashcard with word, translation, image, and pronunciation.",
        parameters = {
            type = "object",
            properties = {
                word = {
                    type = "string",
                    description = "The word or phrase to learn",
                },
                translation = {
                    type = "string",
                    description = "Translation in learner's primary language",
                },
                phonetic = {
                    type = "string",
                    description = "Phonetic transcription",
                },
                imageUrl = {
                    type = "string",
                    description = "Illustration image URL",
                },
                audioUrl = {
                    type = "string",
                    description = "Pronunciation audio URL",
                },
                exampleSentence = {
                    type = "string",
                    description = "Example sentence using the word",
                },
                duration = {
                    type = "number",
                    description = "How long to display (seconds, default: 5)",
                },
            },
            required = {"word"},
        },
    }, function(params, callback)
        self:LaunchLearningTool("show_learning_content", params, callback);
    end);
    
    -- Tool: Text-to-Speech (TTS) for speaking to the learner
    self:RegisterTool("speak_text", {
        description = "Speak text aloud using TTS (text-to-speech). Use this to talk to the learner, read words, give instructions, or provide feedback.",
        parameters = {
            type = "object",
            properties = {
                text = {
                    type = "string",
                    description = "The text to speak aloud",
                },
                voice = {
                    type = "number",
                    description = "Voice narrator ID. 20008=Child female (晓双), 20011=Adult female (晓晓), 20009=Adult male (云希). Default: 20008 for child-friendly voice.",
                },
                waitForComplete = {
                    type = "boolean",
                    description = "Whether to wait for speech to complete before returning (default: true)",
                },
            },
            required = {"text"},
        },
    }, function(params, callback)
        -- Clear auto-speak queue first (tool call takes priority)
        self:ClearTTSQueue();
        
        -- Delay 1 second to ensure TTS engine is fully stopped, then speak
        commonlib.TimerManager.SetTimeout(function()
            self:SpeakText(params.text, params.voice, params.waitForComplete, callback);
        end, 1000);
    end);
    
    -- Tool: Get learning progress (for LLM to query)
    self:RegisterTool("get_learning_progress", {
        description = "Get the current learning progress for the primary task.",
        parameters = {
            type = "object",
            properties = {},
            required = {},
        },
    }, function(params, callback)
        local now = commonlib.TimerManager.GetCurrentTime();
        local throttle = self.toolCallThrottle or {};
        local lastCalled = throttle.lastCalled or {};
        local last = lastCalled.get_learning_progress or 0;
        local minInterval = throttle.minInterval or 2000;
        if now - last < minInterval then
            callback({
                success = true,
                llm_result = string.format("Throttled, retry after %dms", minInterval),
            });
            return;
        end
        lastCalled.get_learning_progress = now;
        throttle.lastCalled = lastCalled;
        self.toolCallThrottle = throttle;
        local summary = self:GetLearningProgressSummary();
        local isComplete = self:IsLearningTaskComplete();
        callback({
            success = true,
            llm_result = string.format("Progress: %s, Complete: %s", summary, tostring(isComplete)),
        });
    end);
    
    -- Tool: Set learning progress (for LLM to record items practiced)
    self:RegisterTool("set_learning_progress", {
        description = "Record learning progress after a learning interaction. Call this when user completes a task (word learned, question answered, etc.) to track what they've practiced.",
        parameters = {
            type = "object",
            properties = {
                itemsPracticed = {
                    type = "array",
                    items = {
                        type = "object",
                        properties = {
                            item = {type = "string", description = "The item text (e.g., word, phrase) that was practiced"},
                            correct = {type = "boolean", description = "Whether the learner got it correct (true for learned/mastered, false for needs practice)"},
                        },
                    },
                    description = "Array of items practiced in this interaction. Each item has 'item' (text) and 'correct' (boolean).",
                },
            },
            required = {"itemsPracticed"},
        },
    }, function(params, callback)
        local itemsPracticed = params.itemsPracticed;
        if not itemsPracticed or type(itemsPracticed) ~= "table" then
            callback({success = false, llm_result = "itemsPracticed must be an array"});
            return;
        end
        
        -- Record items practiced
        local recordedCount = 0;
        for _, itemData in ipairs(itemsPracticed) do
            if itemData.item then
                self:UpdateLearningProgress(itemData.item, itemData.correct == true);
                recordedCount = recordedCount + 1;
            end
        end
        
        -- Get current progress summary
        local progress = self.learningProgress;
        local itemCount = 0;
        for _ in pairs(progress.itemsLearned) do
            itemCount = itemCount + 1;
        end
        
        local accuracy = progress.totalAttempts > 0 and math.floor(progress.totalCorrect / progress.totalAttempts * 100) or 0;
        callback({
            success = true,
            llm_result = string.format("Recorded %d items. Total practiced: %d items, %d attempts, %d%% accuracy", 
                recordedCount, itemCount, progress.totalAttempts, accuracy),
        });
    end);
    
    -- Tool: Record observation progress (for observation mode - record concepts taught and topics discussed)
    self:RegisterTool("record_observation", {
        description = "Record teaching progress in observation mode. Use this to track concepts/words you've introduced and topics you've discussed with the user. This helps track progress in open-ended learning tasks.",
        parameters = {
            type = "object",
            properties = {
                conceptsTaught = {
                    type = "array",
                    items = {type = "string"},
                    description = "Array of concepts, words, or phrases you taught in this interaction (e.g., ['apple', 'red color', 'tree'])",
                },
                topic = {
                    type = "string",
                    description = "Brief description of the topic discussed (e.g., 'fruits in the garden', 'building a house')",
                },
                progressEstimate = {
                    type = "number",
                    description = "Estimated overall learning progress percentage (0-100) based on how much of the task has been covered",
                },
            },
            required = {},
        },
    }, function(params, callback)
        local progress = self.learningProgress;
        local obsStats = progress.observationStats;
        
        -- Record concepts taught
        local conceptsRecorded = 0;
        if params.conceptsTaught and type(params.conceptsTaught) == "table" then
            for _, concept in ipairs(params.conceptsTaught) do
                if concept and concept ~= "" then
                    if not obsStats.conceptsTaught[concept] then
                        obsStats.conceptsTaught[concept] = {count = 0, lastTime = nil};
                    end
                    obsStats.conceptsTaught[concept].count = obsStats.conceptsTaught[concept].count + 1;
                    obsStats.conceptsTaught[concept].lastTime = os.time();
                    conceptsRecorded = conceptsRecorded + 1;
                end
            end
        end
        
        -- Record topic discussed
        if params.topic and params.topic ~= "" then
            table.insert(obsStats.topicsDiscussed, params.topic);
            -- Keep only last 20 topics
            while #obsStats.topicsDiscussed > 20 do
                table.remove(obsStats.topicsDiscussed, 1);
            end
        end
        
        -- Update progress estimate if provided
        if params.progressEstimate and type(params.progressEstimate) == "number" then
            progress.learningPercentage = math.max(0, math.min(100, params.progressEstimate));
        end
        
        -- Count total concepts
        local conceptCount = 0;
        for _ in pairs(obsStats.conceptsTaught) do
            conceptCount = conceptCount + 1;
        end
        
        callback({
            success = true,
            llm_result = string.format("Recorded %d concepts. Total concepts taught: %d, Topics: %d, Progress: %d%%", 
                conceptsRecorded, conceptCount, #obsStats.topicsDiscussed, progress.learningPercentage),
        });
    end);
end

--[[
    Launch a learning tool (MCML-based UI)
    Creates a pending session and shows the learning tool dialog
    Now routes through LearningGiftBoxManager to create interactive gift boxes first.
    Returns immediately after creating gift box (non-blocking mode).
    @param toolName: string - The tool name
    @param params: table - Tool parameters
    @param callback: function - Called immediately after gift box created or on error
]]
function BackgroundAgent:LaunchLearningTool(toolName, params, callback)
    -- Route through LearningGiftBoxManager to create a gift box first
    -- The gift box will handle click confirmation and then launch the actual UI
    local giftBoxMgr = LearningGiftBoxManager.GetSingleton();
    local activeCount = giftBoxMgr:GetActiveCount();
    
    -- Check if at max capacity before creating
    if giftBoxMgr:IsAtMaxCapacity() then
        LOG.std(nil, "info", "BackgroundAgent", "Gift box at max capacity (%d), rejecting %s", 
            activeCount, toolName);
        if callback then
            callback({
                success = false,
                llm_result = string.format(
                    "学习任务礼盒已满(%d个)，无法创建新任务。请提醒玩家点击场景中的礼盒完成学习后获得知识币奖励。",
                    activeCount
                ),
            });
        end
        return;
    end
    
    -- Create gift box (pass nil callback - we'll return immediately)
    local success, sessionId = giftBoxMgr:CreateGiftBox(toolName, params, nil);
    
    if success then
        LOG.std(nil, "info", "BackgroundAgent", "Created gift box for learning tool: %s (session: %s, total: %d)", 
            toolName, sessionId, activeCount + 1);
        -- Return immediately with success - don't wait for user to complete
        if callback then
            callback({
                success = true,
                llm_result = string.format(
                    "学习任务礼盒已创建(当前%d个)。玩家点击礼盒可开始学习，完成后获得知识币奖励。",
                    activeCount + 1
                ),
            });
        end
    else
        -- Gift box creation failed for other reason
        LOG.std(nil, "info", "BackgroundAgent", "Gift box creation failed for %s", toolName);
        if callback then
            callback({
                success = false,
                llm_result = "创建学习任务礼盒失败，请稍后重试。",
            });
        end
    end
end

--[[
    Launch a learning tool directly without gift box (internal use)
    Used when the gift box is clicked and user confirms to start learning
    @param toolName: string - The tool name
    @param params: table - Tool parameters
    @param callback: function - Called when user completes the tool
]]
function BackgroundAgent:LaunchLearningToolDirect(toolName, params, callback)
    local sessionId = string.format("%s_%d_%d", toolName, os.time(), math.random(10000));
    
    -- Store pending session
    self.pendingToolResults[sessionId] = {
        toolName = toolName,
        params = params,
        callback = callback,
        timestamp = os.time(),
    };
    
    -- IMPORTANT: Do NOT call callback here!
    -- AIChat will wait for async callback, preventing immediate LLM re-request.
    -- The callback will be called later via OnLearningToolResult when user completes the UI.
    
    -- Check if another UI is currently displayed
    if self.currentUISession then
        -- Add to queue instead of showing immediately
        table.insert(self.uiToolQueue, {
            sessionId = sessionId,
            toolName = toolName,
            params = params,
        });
        LOG.std(nil, "info", "BackgroundAgent", "Queued learning tool: %s (session: %s), current UI: %s", 
            toolName, sessionId, self.currentUISession);
        return;  -- Return nil to keep AIChat waiting
    end
    
    -- No UI currently displayed, show immediately
    self:ShowLearningToolUI(sessionId, toolName, params);
    -- Return nil - AIChat will wait for async callback
end

--[[
    Internal: Show a learning tool UI
    @param sessionId: string - Session ID
    @param toolName: string - Tool name
    @param params: table - Tool parameters
]]
function BackgroundAgent:ShowLearningToolUI(sessionId, toolName, params)
    self.currentUISession = sessionId;
    
    LearningToolUI.Show(toolName, params, sessionId, function(result)
        -- Result will be reported via OnLearningToolResult
    end);
    
    LOG.std(nil, "info", "BackgroundAgent", "Launched learning tool: %s (session: %s)", toolName, sessionId);
end

--[[
    Internal: Process next item in UI tool queue
]]
function BackgroundAgent:ProcessNextUIToolInQueue()
    if #self.uiToolQueue == 0 then
        return;
    end
    
    local nextTool = table.remove(self.uiToolQueue, 1);
    LOG.std(nil, "info", "BackgroundAgent", "Dequeuing learning tool: %s (session: %s), remaining: %d", 
        nextTool.toolName, nextTool.sessionId, #self.uiToolQueue);
    
    self:ShowLearningToolUI(nextTool.sessionId, nextTool.toolName, nextTool.params);
end

--[[
    Clear the UI tool queue and close any open UI
    Called when agent is stopped
]]
function BackgroundAgent:ClearUIToolQueue()
    -- Close current UI if open
    if self.currentUISession then
        LearningToolUI.Close(nil); -- Close without result
        self.currentUISession = nil;
    end
    
    -- Clear pending results for queued items
    for _, item in ipairs(self.uiToolQueue) do
        self.pendingToolResults[item.sessionId] = nil;
    end
    
    -- Clear queue
    self.uiToolQueue = {};
    
    LOG.std(nil, "info", "BackgroundAgent", "UI tool queue cleared");
end

--[[
    Get UI tool queue status (for debugging)
    @return table - {currentSession, queueLength, queuedTools}
]]
function BackgroundAgent:GetUIToolQueueStatus()
    local queuedTools = {};
    for _, item in ipairs(self.uiToolQueue) do
        table.insert(queuedTools, item.toolName);
    end
    
    return {
        currentSession = self.currentUISession,
        queueLength = #self.uiToolQueue,
        queuedTools = queuedTools,
    };
end

--[[
    Callback for H5 minigame results
    @param sessionId: string - The session ID from LaunchLearningTool
    @param result: table - Result from H5 {success, correct, score, data, ...}
]]
function BackgroundAgent:OnLearningToolResult(sessionId, result)
    local pending = self.pendingToolResults[sessionId];
    if not pending then
        LOG.std(nil, "warn", "BackgroundAgent", "Unknown learning tool session: %s", sessionId);
        return;
    end
    
    -- Remove from pending
    self.pendingToolResults[sessionId] = nil;
    
    -- Clear current UI session if this was the active one
    if self.currentUISession == sessionId then
        self.currentUISession = nil;
    end
    
    -- Update learning progress if applicable
    local subject = pending.params.subject or pending.params.word;
    if subject and result.correct ~= nil then
        self:UpdateLearningProgress(subject, result.correct, {
            score = result.score,
            toolName = pending.toolName,
        });
    end
    
    -- Call original callback with full result (convert to llm_result format)
    if pending.callback then
        -- Build llm_result string from result data
        local llm_result;
        if result.correct ~= nil then
            llm_result = string.format("Tool: %s, correct=%s", pending.toolName, tostring(result.correct));
            if result.score then
                llm_result = llm_result .. string.format(", score=%d", result.score);
            end
            if result.userAnswer then
                llm_result = llm_result .. string.format(", userAnswer=%s", tostring(result.userAnswer));
            end
        else
            llm_result = string.format("Tool: %s completed", pending.toolName);
        end
        
        pending.callback({
            success = result.success ~= false,
            llm_result = llm_result,
        });
    end
    
    LOG.std(nil, "info", "BackgroundAgent", "Learning tool result: %s correct=%s", 
        pending.toolName, tostring(result.correct));
    
    -- Process next queued UI tool (with small delay for smooth transition)
    if #self.uiToolQueue > 0 then
        commonlib.TimerManager.SetTimeout(function()
            self:ProcessNextUIToolInQueue();
        end, 300); -- 300ms delay for smooth transition
    end
end

--[[
    Speak text using TTS (Text-to-Speech)
    @param text: string - Text to speak
    @param voice: number (optional) - Voice narrator ID (default: 20008 child female)
    @param waitForComplete: boolean (optional) - Wait for speech to complete (default: true)
    @param callback: function - Called when speech completes or starts
]]
function BackgroundAgent:SpeakText(text, voice, waitForComplete, callback)
    -- Delegate to TTSQueueManager
    self.ttsManager:SpeakText(text, voice, waitForComplete, callback);
end

--[[
    Stop any currently playing TTS
]]
function BackgroundAgent:StopTTS()
    self.ttsManager:StopTTS();
end

--[[
    Check if TTS is currently playing
    @return boolean
]]
function BackgroundAgent:IsTTSPlaying()
    return self.ttsManager:IsTTSPlaying();
end

--------------------------------------------------------------------------------
-- TTS Auto-Speak Queue Management (delegated to TTSQueueManager)
--------------------------------------------------------------------------------

--[[
    Enable or disable auto-speak feature
    @param enabled: boolean - Whether to enable auto-speak
]]
function BackgroundAgent:SetAutoSpeakEnabled(enabled)
    self.ttsManager:SetAutoSpeakEnabled(enabled);
end

--[[
    Check if auto-speak is enabled
    @return boolean
]]
function BackgroundAgent:IsAutoSpeakEnabled()
    return self.ttsManager:IsAutoSpeakEnabled();
end

--[[
    Queue a sentence for TTS playback
    @param text: string - The sentence to speak
]]
function BackgroundAgent:QueueTTSSentence(text)
    self.ttsManager:QueueTTSSentence(text);
end

--[[
    Process the next sentence in TTS queue (delegated to TTSQueueManager)
]]
function BackgroundAgent:ProcessNextTTSInQueue()
    self.ttsManager:ProcessNextTTSInQueue();
end

--[[
    Clear TTS queue and stop current playback
]]
function BackgroundAgent:ClearTTSQueue()
    self.ttsManager:ClearTTSQueue();
    LOG.std(nil, "info", "BackgroundAgent", "TTS queue cleared");
end

--[[
    Clean text for TTS playback (delegated to TTSQueueManager)
    @param text: string - Raw text to clean
    @return string - Cleaned text suitable for TTS
]]
function BackgroundAgent:CleanTextForTTS(text)
    return self.ttsManager:CleanTextForTTS(text);
end

--[[
    Flush TTS text buffer (delegated to TTSQueueManager)
]]
function BackgroundAgent:FlushTTSBuffer()
    self.ttsManager:FlushTTSBuffer();
end

--[[
    Filter out progress markers from text for TTS (delegated to TTSQueueManager)
    @param text: string - Input text
    @return string - Text with progress markers removed
]]
function BackgroundAgent:_FilterProgressMarkers(text)
    return self.ttsManager:FilterProgressMarkers(text);
end

--[[
    Extract progress markers from text (delegated to TTSQueueManager)
    @param text: string - Input text
    @return table - Array of progress markers
]]
function BackgroundAgent:_ExtractProgressMarkers(text)
    return self.ttsManager:ExtractProgressMarkers(text);
end

--[[
    Split text into sentences (delegated to TTSQueueManager)
    @param text: string - Text to split
    @return table - Array of sentences
]]
function BackgroundAgent:_SplitIntoSentences(text)
    return self.ttsManager:_SplitIntoSentences(text);
end

--[[
    Set callback for typewriter effect
    @param callback: function(text) - Called with each text segment for display
]]
function BackgroundAgent:SetTypewriterCallback(callback)
    self.typewriterCallback = callback;
end

--[[
    Get TTS text buffer content (for debugging)
    @return string - Current buffer content
]]
function BackgroundAgent:GetTTSBufferContent()
    return self.ttsManager:GetTTSBufferContent();
end

--[[
    Get TTS queue status (for debugging)
    @return table - {queueLength, isPlaying, autoSpeakEnabled, ttsBufferLength, sentenceBufferLength}
]]
function BackgroundAgent:GetTTSQueueStatus()
    return self.ttsManager:GetTTSQueueStatus();
end

--------------------------------------------------------------------------------
-- Chat Message History (for Debug UI display)
--------------------------------------------------------------------------------

--[[
    Called when typewriter signal is emitted
    Accumulates text for current message or creates new message
    @param text: string - Text segment from typewriter
]]
function BackgroundAgent:OnTypewriterText(text)
    if not text or text == "" then return; end
    
    -- Debug logging
    LOG.std(nil, "debug", "BackgroundAgent", "[TYPEWRITER] OnTypewriterText called with: %s (length: %d)", 
        string.sub(text, 1, 50), #text);
    
    -- Extract progress markers for separate handling
    local progressMarkers = self:_ExtractProgressMarkers(text);
    if #progressMarkers > 0 then
        LOG.std(nil, "debug", "BackgroundAgent", "[PROGRESS] Extracted markers: %s", 
            table.concat(progressMarkers, ", "));
        -- Emit progress markers separately (UI can display them differently, no TTS)
        for _, marker in ipairs(progressMarkers) do
            self:progressUpdate(marker);
        end
    end
    
    -- If no current message, create a new one for assistant
    if not self.currentChatMessage then
        self.currentChatMessage = {
            role = "assistant",
            content = text,
            timestamp = os.time(),
            isComplete = false,
        };
        LOG.std(nil, "debug", "BackgroundAgent", "[TYPEWRITER] Created new message, content length: %d", #text);
    else
        -- Append to current message
        self.currentChatMessage.content = self.currentChatMessage.content .. text;
        LOG.std(nil, "debug", "BackgroundAgent", "[TYPEWRITER] Accumulated content, total length: %d", 
            #self.currentChatMessage.content);
    end
    
    -- Emit a separate signal for immediate UI update (bypasses 100ms timer)
    self:chatContentUpdate(self.currentChatMessage.content);
    
    -- Note: Don't call RefreshDebugUI here as it would cause input box to lose focus
    -- Instead, the debug UI uses SetValue with a timer to update the streaming content
end

--[[
    Add a user message to chat history
    @param content: string - User message content
]]
function BackgroundAgent:AddChatUserMessage(content)
    if not content or content == "" then return; end
    
    local message = {
        role = "user",
        content = content,
        timestamp = os.time(),
        isComplete = true,
    };
    
    table.insert(self.chatMessageHistory, message);
    self:TrimChatHistory();
end

--[[
    Complete current assistant message and add to history
    Called when LLM response is complete
]]
function BackgroundAgent:CompleteChatMessage()
    if self.currentChatMessage then
        self.currentChatMessage.isComplete = true;
        table.insert(self.chatMessageHistory, self.currentChatMessage);
        self.currentChatMessage = nil;
        self:TrimChatHistory();
    end
end

--[[
    Trim chat history to max size
]]
function BackgroundAgent:TrimChatHistory()
    while #self.chatMessageHistory > self.maxChatHistorySize do
        table.remove(self.chatMessageHistory, 1);
    end
end

--[[
    Get chat message history
    @return table - Array of chat messages
]]
function BackgroundAgent:GetChatMessageHistory()
    return self.chatMessageHistory;
end

--[[
    Get a chat message by index (1-based, newest first)
    @param index: number - 1-based index (1 = most recent)
    @return table - Chat message or nil
]]
function BackgroundAgent:GetChatMessage(index)
    local reversedIndex = #self.chatMessageHistory - index + 1;
    return self.chatMessageHistory[reversedIndex];
end

--[[
    Get current streaming message (incomplete)
    @return table - Current message being streamed or nil
]]
function BackgroundAgent:GetCurrentChatMessage()
    return self.currentChatMessage;
end

--[[
    Clear chat message history
]]
function BackgroundAgent:ClearChatHistory()
    self.chatMessageHistory = {};
    self.currentChatMessage = nil;
    LOG.std(nil, "info", "BackgroundAgent", "Chat history cleared");
end

--[[
    Get chat message count (complete + current streaming)
    @return number
]]
function BackgroundAgent:GetChatMessageCount()
    local count = #self.chatMessageHistory;
    if self.currentChatMessage then
        count = count + 1;
    end
    return count;
end

--[[
    Extract complete sentences from buffer based on punctuation
    Uses character-by-character iteration to properly handle UTF-8 Chinese text.
    @param buffer: string - Text buffer to extract from
    @return table - {sentences = array of strings, remaining = leftover text}
]]
function BackgroundAgent:_ExtractCompleteSentences(buffer)
    local sentences = {};
    local remaining = "";
    
    if not buffer or buffer == "" then
        return {sentences = {}, remaining = ""};
    end
    
    -- Sentence-ending punctuation marks (Chinese and English)
    local punctuationSet = {
        ["。"] = true, ["！"] = true, ["？"] = true,
        ["，"] = true, [","] = true,
        ["."] = true, ["!"] = true, ["?"] = true,
    };
    
    local currentSentence = "";
    local i = 1;
    local len = #buffer;
    
    while i <= len do
        -- Determine UTF-8 character byte length
        local byte = string.byte(buffer, i);
        local charLen = 1;
        if byte >= 0xF0 then
            charLen = 4;  -- 4-byte UTF-8 (rare, like emoji)
        elseif byte >= 0xE0 then
            charLen = 3;  -- 3-byte UTF-8 (Chinese characters, Chinese punctuation)
        elseif byte >= 0xC0 then
            charLen = 2;  -- 2-byte UTF-8
        end
        
        -- Ensure we don't read past the buffer
        if i + charLen - 1 > len then
            -- Incomplete UTF-8 character at end, keep in remaining
            remaining = string.sub(buffer, i);
            break;
        end
        
        -- Extract the current character
        local char = string.sub(buffer, i, i + charLen - 1);
        currentSentence = currentSentence .. char;
        
        -- Check if this character is a sentence-ending punctuation
        if punctuationSet[char] then
            -- Complete sentence found
            local trimmed = currentSentence:match("^%s*(.-)%s*$");
            if trimmed and trimmed ~= "" then
                table.insert(sentences, trimmed);
            end
            currentSentence = "";
        end
        
        i = i + charLen;
    end
    
    -- Any remaining text without punctuation
    if currentSentence ~= "" then
        remaining = currentSentence;
    end
    
    return {
        sentences = sentences,
        remaining = remaining,
    };
end

--[[
    Check if transcript contains TTS stop keywords (delegated to TTSQueueManager)
    @param transcript: string - Voice transcript to check
    @return boolean - True if stop keyword found
]]
function BackgroundAgent:_CheckTTSStopKeyword(transcript)
    return self.ttsManager:CheckStopKeyword(transcript);
end

--[[
    Execute Lua code on a copilot subagent
    @param copilotName: string - Target copilot name
    @param code: string - Lua code to execute
    @param async: boolean - Whether to run async
    @param callback: function - Called with result
]]
function BackgroundAgent:ExecuteCopilotCode(copilotName, code, callback)
    local manager = CopilotManager.GetInstance();
    if not manager then
        if callback then
            callback({success = false, llm_result = "CopilotManager not found"});
        end
        LOG.std(nil, "warn", "BackgroundAgent", "CopilotManager not found");
        return;
    end
    manager:RunCodeForCopilot(copilotName, code, callback);
end

--[[
    Execute terminal code on the main thread
    @param code: string - Npl blockly code to execute
]]
function BackgroundAgent:ExecuteTerminalCode(code,callback)
    -- Compile and execute the code
    local manager = CopilotManager.GetInstance();
    if not manager then
        if callback then
            callback({success = false, llm_result = "CopilotManager not found"});
        end
        return;
    end
    manager:RunTerminalCode(code, callback);
end



--------------------------------------------------------------------------------
-- LLM Integration
--------------------------------------------------------------------------------

--[[
    Add a message to dialog history and trigger summarization if needed
    @param role: string - "user" | "assistant" | "system"
    @param content: string - Message content
]]
function BackgroundAgent:AddToDialogHistory(role, content)
    if self.dialogHistoryManager then
        self.dialogHistoryManager:AddMessage(role, content);
    end
end

-- Note: SummarizeDialogHistory is now handled by DialogHistoryManager
-- The manager uses LLM-based async summarization with keyword density evaluation

--[[
    Get formatted dialog context for LLM prompt
    Includes summary + recent history + learning progress restatement
    @return string - Formatted dialog context
]]
function BackgroundAgent:GetDialogContext()
    if self.dialogHistoryManager then
        return self.dialogHistoryManager:GetFormattedContext();
    end
    return "";
end

--[[
    Get debug info about dialog history manager
    Useful for inspecting summary state and process
    @return table|nil Debug info or nil if manager not initialized
]]
function BackgroundAgent:GetDialogDebugInfo()
    if self.dialogHistoryManager then
        return self.dialogHistoryManager:GetDebugInfo();
    end
    return nil;
end

--[[
    Print dialog history debug info to log
    Call this to see current summary state
]]
function BackgroundAgent:PrintDialogDebugInfo()
    if self.dialogHistoryManager then
        return self.dialogHistoryManager:PrintDebugInfo();
    end
    LOG.std(nil, "warn", "BackgroundAgent", "DialogHistoryManager not initialized");
    return nil;
end

--[[
    Get cached system prompt or build new one if cache invalid
    Cache is invalidated when primaryTask or copilots change
    @return string - System prompt
]]
function BackgroundAgent:GetCachedSystemPrompt()
    -- Build cache key from task id and copilot count
    local taskId = self.primaryTask and self.primaryTask.id or "none";
    local copilotCount = self.discoveredCopilots and #self.discoveredCopilots or 0;
    local cacheKey = string.format("%s_%d", taskId, copilotCount);
    
    -- Return cached if valid
    if self.cachedSystemPrompt and self.systemPromptCacheKey == cacheKey then
        return self.cachedSystemPrompt;
    end
    
    -- Rebuild and cache
    self.cachedSystemPrompt = self:BuildLearningSystemPrompt();
    self.systemPromptCacheKey = cacheKey;
    LOG.std(nil, "debug", "BackgroundAgent", "System prompt cache rebuilt (key: %s)", cacheKey);
    
    return self.cachedSystemPrompt;
end

--[[
    Invalidate system prompt cache (call when task or copilots change)
]]
function BackgroundAgent:InvalidateSystemPromptCache()
    self.cachedSystemPrompt = nil;
    self.systemPromptCacheKey = nil;
end

--[[
    Build the learning-aware system prompt
    @return string - System prompt with learning context
]]
function BackgroundAgent:BuildLearningSystemPrompt()
    local profile = self.userProfile;
    local task = self.primaryTask;
    local prompt = "";
    
    -- Get dynamic copilot section based on registered copilots
    local copilotSection = self:GetCopilotPromptSection();
    local hasCopilots = self:HasCopilots();
    
    -- Check if we have a learning task
    if task then
        -- Learning mode prompt
        prompt = string.format([[You are a friendly learning companion in Paracraft, a 3D creative game.
Your name is 帕帕 (papa). When asked about your name, ALWAYS say "帕帕".
You are helping a %d-year-old %s speaker learn %s.

## Response Language (CRITICAL)
- ALWAYS respond in %s (the learner's native language)
- Only use %s for the learning content itself (words, phrases, example sentences)
- All explanations, instructions, encouragement, and conversation MUST be in %s
- Example: "我们来学一个新单词：**apple**（苹果）- I like to eat apples."

Your personality:
- Playful, encouraging, and patient
- Use age-appropriate language and explanations
- Celebrate successes enthusiastically
- Provide gentle hints when the learner struggles

## Teaching Style (CRITICAL)
- NEVER ask "要不要学？", "想学吗？", "要不要现在学一学？" or similar questions
- DO NOT wait for user's permission to teach - just START teaching directly
- After teaching one word, immediately move to the next word or test
- Keep the momentum going - learning should feel like a natural flow, not a conversation
- Example: Instead of "要不要学 rabbit？" say "接下来我们学 rabbit（兔子）！"

## Greeting Rule
- ONLY greet the user (e.g., "你好！欢迎来到Paracraft！") on the FIRST interaction when chat history is empty.
- For ALL subsequent interactions, DO NOT repeat greetings or welcome messages.
- Jump directly into teaching, commenting on the scene, or responding to the user.

## Primary Learning Task

%s

IMPORTANT: While you can help with other activities the user wants to do (building, playing, exploring),
always look for natural opportunities to weave in learning moments related to the primary task.
Don't force learning, but gently guide back to the task when appropriate.

Evaluate task completion based on the chat history and learning progress.
When you believe the task goals have been met, inform the user of their achievement.

## Tool Usage Guidelines

### CRITICAL: Multiple Tool Calls
When you need to call multiple tools (e.g., show_learning_content AND record_observation):
- Return them as SEPARATE tool_calls in the same response array
- Each tool call must have its own name, arguments, and id
- NEVER concatenate tool names like "tool1tool2" - this is WRONG
- Correct format example:
  ```json
  [
    {"type": "function", "function": {"name": "show_learning_content", "arguments": "{...}"}, "id": "call_1"},
    {"type": "function", "function": {"name": "record_observation", "arguments": "{...}"}, "id": "call_2"}
  ]
  ```

### Learning Cycle (IMPORTANT)
Follow a "Teach → Test → Review" cycle:
1. **Teach 2-3 new words** using `show_learning_content`
2. **Test the user** on those words using test tools
3. **Review and reinforce** based on results

### Tool Selection:
- `show_learning_content` - Introduce NEW words (flashcard style)
- `test_multiple_choice` - Test vocabulary understanding (good for beginners)
- `test_words_speaking` - Test pronunciation (after user has seen the word)
- `test_words_spelling` - Test spelling (harder, use after some practice)

### Progress Tracking (CRITICAL)
**Observation Mode:** After EACH interaction where you teach or discuss something:
- Call `record_observation` with `conceptsTaught` (words/phrases you introduced)
- Include `topic` (what scene element you discussed)
- Estimate `progressEstimate` based on variety of concepts covered

**Structured Mode:** After EACH test:
- Call `set_learning_progress` with `itemsPracticed` to record results

### Checking Before Teaching
Always check the "Concepts Introduced" section in Learning Progress to:
- Avoid teaching the same words repeatedly
- Test words that have been taught but not yet tested
- If 2+ concepts were taught without testing, prioritize using a test tool

IMPORTANT: Learning progress is already provided in context below. Do NOT call `get_learning_progress` tool unless user explicitly asks for progress details.

]], profile.age, profile.primaryLanguage, profile.secondaryLanguage, 
    profile.primaryLanguage, profile.secondaryLanguage, profile.primaryLanguage,
    task.text);
        
        -- Add copilot section if copilots are available
        if hasCopilots then
            prompt = prompt .. "\n## Available Copilot Characters\n\n" .. copilotSection .. "\n";
        end
        
        prompt = prompt .. [[

Always end your responses by briefly restating the current learning goal and progress if relevant.
]];
    else
        -- General assistant mode prompt (no learning task)
        prompt = [[You are a helpful assistant in Paracraft, a 3D creative game.

Your capabilities:
- Understand user's voice commands and convert them to actions
- Help with building, exploring, and managing the game world
- Use the provided tools when appropriate to accomplish tasks
]];
        
        -- Add copilot section if copilots are available
        if hasCopilots then
            prompt = prompt .. "\n## Available Copilot Characters\n\n" .. copilotSection .. "\n";
        else
            prompt = prompt .. "\nCurrently no copilot characters are available.\n";
        end
        
        prompt = prompt .. [[

Respond in Chinese. Keep responses brief (1-2 sentences).
]];
    end

    return prompt;
end

--[[
    Process a user query with full scene context through LLM
    @param userQuery: string - The user's query or instruction
    @param callback: function(result) - Called with LLM response
    @param options: table (optional) - {includeImage = true, tools = true}
]]
function BackgroundAgent:ProcessWithLLM(userQuery, callback, options)
    options = options or {};
    local includeImage = options.includeImage ~= false;
    
    -- Request queue: if LLM is busy, queue this request and return
    if self.isLLMProcessing then
        table.insert(self.pendingUserRequests, userQuery);
        LOG.std(nil, "debug", "BackgroundAgent", "LLM busy, queued request: %s (queue size: %d)", 
            string.sub(userQuery, 1, 50), #self.pendingUserRequests);
        return;  -- Callback is discarded, merged request will handle response
    end
    
    -- Merge any pending requests (FIFO order)
    if #self.pendingUserRequests > 0 then
        local mergedQuery = table.concat(self.pendingUserRequests, "\n\n") .. "\n\n" .. userQuery;
        userQuery = mergedQuery;
        self.pendingUserRequests = {};  -- Clear queue
        LOG.std(nil, "debug", "BackgroundAgent", "Merged pending requests into current query");
    end
    
    -- Mark LLM as processing and reset tool call hint state
    self.isLLMProcessing = true;
    self.isToolCallInProgress = false;
    self.toolCallHintSpoken = false;
    
    -- Initialize AI session if needed
    self:InitAISession();
    
    -- Update system prompt with learning context (use cached if available)
    local systemPrompt = self:GetCachedSystemPrompt();
    self.aiSession:SetSystemPrompt(systemPrompt);
    
    -- Detect if user request is scene-related (determines full vs brief scene context)
    local isSceneRelated = self:IsSceneRelatedRequest(userQuery);
    
    -- Build the prompt with optimized order:
    -- 1. User Request (first for LLM attention priority)
    -- 2. Background Context separator
    -- 3. Dialog history (with reference markers)
    -- 4. Context history (screenshots/voice)
    -- 5. Scene context (full or brief based on request type)
    -- 6. Learning progress
    
    -- Start with user request (highest priority - LLM sees this first after system prompt)
    local fullPrompt = "## User Request\n\n" .. userQuery .. "\n";
    
    -- Add separator to distinguish user-perceivable content from system context
    fullPrompt = fullPrompt .. "\n---\n## Background Context\n\n";
    
    -- Add dialog history context (summary + recent, with reference markers)
    fullPrompt = fullPrompt .. self:GetDialogContext();
    
    -- Add context history summary (recent screenshots and voice)
    local contextSummary = self:GetContextHistorySummary();
    if contextSummary and contextSummary ~= "" then
        fullPrompt = fullPrompt .. contextSummary .. "\n";
    end
    
    -- Add scene context (full mode for scene-related requests, brief mode otherwise)
    local sceneContext = self:GetSceneTextContext();
    fullPrompt = fullPrompt .. self:FormatSceneContextAsMarkdown(sceneContext, includeImage, isSceneRelated);
    
    -- Add learning progress
    if self.primaryTask then
        fullPrompt = fullPrompt .. "\n" .. self:GetLearningProgressSummary() .. "\n";
    end
    
    -- Note: Tools are now registered via AIChat's native tool calling system
    -- No need to include them in the prompt text
    
    -- Record user message in dialog history
    self:AddToDialogHistory("user", userQuery);
    
    -- Add user message to chat history for UI display (skip if requested)
    local skipChatHistory = options and options.skipChatHistory;
    if not skipChatHistory then
        self:AddChatUserMessage(userQuery);
    end
    
    -- Update last activity time when user sends a message
    if self.learningProgress then
        self.learningProgress.lastActivityTime = commonlib.TimerManager.GetCurrentTime();
    end
    
    -- Prepare image data if requested
    local askOptions = {};
    if includeImage then
        local imageUrl = nil;
        
        -- First, check if imageUrl was passed directly in options (from voice processing)
        if options.imageUrl and options.imageUrl ~= "" then
            imageUrl = options.imageUrl;
            LOG.std(nil, "debug", "BackgroundAgent", "Using provided image URL for LLM: %s", imageUrl);
        end
        
        -- Fallback to cached screenshot from SceneVisionManager
        if not imageUrl then
            local latestVision = self:GetLatestSceneVision();
            if latestVision and latestVision.imageUrl and latestVision.imageUrl ~= "" then
                imageUrl = latestVision.imageUrl;
                -- Mark as sent to LLM
                latestVision.sentToLLM = true;
                LOG.std(nil, "debug", "BackgroundAgent", "Using cached screenshot for LLM: %s", imageUrl);
            end
        end
        
        -- Only add images if we have a valid URL (never send empty string)
        if imageUrl and imageUrl ~= "" then
            askOptions.images = {imageUrl};
        else
            LOG.std(nil, "warn", "BackgroundAgent", "No valid image available for LLM request");
        end
    end
    
    -- Send to LLM
    self:SendToLLMWithHistoryTracking(fullPrompt, askOptions, callback);
end

--[[
    Send prompt to LLM and track response in dialog history
    @param prompt: string - The full prompt
    @param options: table - Options for AI request
    @param callback: function(result) - Called with response
]]
function BackgroundAgent:SendToLLMWithHistoryTracking(prompt, options, callback)
    self:SendToLLM(prompt, options, function(result)
        -- Mark LLM as no longer processing
        self.isLLMProcessing = false;
        
        -- Handle server errors (500) with retry logic
        if not result.success and result.code == 500 then
            LOG.std(nil, "warn", "BackgroundAgent", "LLM server error (500), attempting recovery");
            self.llmRetry.lastErrorTime = commonlib.TimerManager.GetCurrentTime();
            
            -- Schedule a retry if under max retries
            if self.llmRetry.currentRetryCount < self.llmRetry.maxRetries then
                self.llmRetry.currentRetryCount = self.llmRetry.currentRetryCount + 1;
                LOG.std(nil, "info", "BackgroundAgent", "Scheduling LLM retry %d/%d in %dms",
                    self.llmRetry.currentRetryCount, self.llmRetry.maxRetries, self.llmRetry.retryDelay);
                
                -- Schedule retry with exponential backoff
                local retryDelay = self.llmRetry.retryDelay * self.llmRetry.currentRetryCount;
                self:ScheduleLLMRetry(prompt, options, callback, retryDelay);
                return; -- Don't call callback yet, will be called after retry
            else
                LOG.std(nil, "warn", "BackgroundAgent", "Max LLM retries reached, giving up");
                self.llmRetry.currentRetryCount = 0; -- Reset for next request
            end
        else
            -- Reset retry counter on success or non-500 errors
            self.llmRetry.currentRetryCount = 0;
        end
        
        -- Record assistant response in dialog history
        if result.success and result.response then
            self:AddToDialogHistory("assistant", result.response);
        end
        
        if callback then
            callback(result);
        end
    end);
end

--[[
    Schedule a retry for failed LLM request
    @param prompt: string - The original prompt
    @param options: table - The original options
    @param callback: function - The original callback
    @param delay: number - Delay in milliseconds before retry
]]
function BackgroundAgent:ScheduleLLMRetry(prompt, options, callback, delay)
    -- Cancel any existing retry timer
    if self.llmRetry.pendingRetry then
        self.llmRetry.pendingRetry:Change();
        self.llmRetry.pendingRetry = nil;
    end
    
    -- Create new retry timer
    self.llmRetry.pendingRetry = commonlib.Timer:new({
        callbackFunc = function(timer)
            LOG.std(nil, "info", "BackgroundAgent", "Executing LLM retry attempt");
            self.llmRetry.pendingRetry = nil;
            
            -- Re-send the request
            self.isLLMProcessing = true;
            self:SendToLLMWithHistoryTracking(prompt, options, callback);
        end
    });
    self.llmRetry.pendingRetry:Change(delay, nil); -- One-shot timer
end

--[[
    Send prompt to LLM and handle response
    @param prompt: string - The full prompt
    @param options: table - Options for AI request
    @param callback: function(result) - Called with response
]]
function BackgroundAgent:SendToLLM(prompt, options, callback)
    -- Generate session ID for this LLM request (for logging tool calls)
    self._currentSessionId = string.format("%s_%d_%d", os.date("%H%M%S"), os.time(), math.random(10000, 99999));
    
    -- Create LLM history entry
    local llmEntry = {
        timestamp = os.time(),
        timestampMs = commonlib.TimerManager.GetCurrentTime(),
        sessionId = self._currentSessionId,
        input = {
            prompt = prompt,
            systemPrompt = self.aiSession and self.aiSession.system_prompt or nil,
            hasImage = options and options.images and #options.images > 0,
            imageUrl = options and options.images and options.images[1] or nil,
        },
        output = nil,
        status = "pending",
        toolCalls = nil,
        toolResults = nil,
        duration = nil,
    };
    
    -- Add to history
    table.insert(self.llmHistory, llmEntry);
    
    -- Trim history if exceeds max size
    while #self.llmHistory > self.maxLLMHistorySize do
        table.remove(self.llmHistory, 1);
    end
    
    -- Debug log LLM input - full raw message when debug enabled
    if self.debugEnabled then
        local imageInfo = "none";
        if options and options.images then
            imageInfo = string.format("img url=%s", #(options.images or ""));
        end
        LOG.std(nil, "debug", "BackgroundAgent", "[LLM_RAW_INPUT] image=%s", imageInfo);
        LOG.std(nil, "debug", "BackgroundAgent", "[LLM_RAW_INPUT] systemPrompt=%s", self.aiSession and self.aiSession.system_prompt or "nil");
        LOG.std(nil, "debug", "BackgroundAgent", "[LLM_RAW_INPUT] prompt=%s", prompt or "nil");
        LOG.std(nil, "debug", "BackgroundAgent", "[LLM_RAW_INPUT] historyCount=%d", self.aiSession and #self.aiSession.history or 0);
    end
    
    local startTime = commonlib.TimerManager.GetCurrentTime();
    
    -- Reset sentence buffer for new LLM request
    self.sentenceBuffer = "";
    
    -- Use AIChat's native tool calling - in delegate mode, we handle tool execution ourselves
    self.aiSession:Ask(prompt, function(resultCode, delta, deltaThink, fullResult, fullThink, toolCallInfo)
        if resultCode then
            -- Final result
            -- Calculate duration
            llmEntry.duration = commonlib.TimerManager.GetCurrentTime() - startTime;
            
            -- Check if this is a tool call response in delegate mode
            if toolCallInfo and toolCallInfo.toolCalls and #toolCallInfo.toolCalls > 0 then
                -- Tool calls received from LLM in delegate mode
                LOG.std(nil, "debug", "BackgroundAgent", "Received %d tool calls from LLM (delegate mode)", #toolCallInfo.toolCalls);
                
                -- Update LLM history entry with tool calls
                llmEntry.toolCalls = toolCallInfo.toolCalls;
                llmEntry.status = "tool_calling";
                self:RefreshDebugUI();
                
                -- Handle tool calls through the strategy executor
                self:HandleToolCallsFromLLM(toolCallInfo, function(toolResults)
                    -- Tool execution complete, store results
                    llmEntry.toolResults = toolResults;
                    
                    -- Continue conversation with tool results
                    self.aiSession:ContinueWithToolResults(toolResults, function(contResultCode, contDelta, contDeltaThink, contFullResult, contFullThink, contToolCallInfo)
                        -- Recursive handling for potential follow-up tool calls
                        if contResultCode then
                            if contToolCallInfo and contToolCallInfo.toolCalls and #contToolCallInfo.toolCalls > 0 then
                                -- More tool calls - recurse (this can create a chain)
                                LOG.std(nil, "debug", "BackgroundAgent", "Follow-up tool calls detected, continuing chain");
                                -- Re-invoke the callback with new tool info (this is a simplified recursive approach)
                                -- In practice, the ContinueWithToolResults callback is the same as Ask callback
                                self:HandleToolCallsFromLLM(contToolCallInfo, function(moreResults)
                                    self.aiSession:ContinueWithToolResults(moreResults, function(finalCode, _delta, _deltaThink, finalResult, finalThink)
                                        -- Complete the final result
                                        self:_CompleteLLMResponse(llmEntry, startTime, finalCode, finalResult, finalThink, callback);
                                    end, options);
                                end);
                            else
                                -- Final response after tool calls
                                self:_CompleteLLMResponse(llmEntry, startTime, contResultCode, contFullResult, contFullThink, callback);
                            end
                        else
                            -- Streaming during continuation (after tool calls)
                            self:_HandleLLMStreamingDelta(contDelta, contDeltaThink);
                        end
                    end, options);
                end);
                return;
            end
            
            -- Process any remaining text in sentence buffer for auto-speak
            if self:IsAutoSpeakEnabled() and self.sentenceBuffer and self.sentenceBuffer ~= "" then
                local trimmed = self.sentenceBuffer:match("^%s*(.-)%s*$");
                if trimmed and trimmed ~= "" then
                    self:QueueTTSSentence(trimmed);
                end
                self.sentenceBuffer = "";
            end
            
            -- Flush TTS buffer to actually play accumulated text
            if self:IsAutoSpeakEnabled() then
                self:FlushTTSBuffer();
            end
            
            -- Complete current chat message and add to history
            self:CompleteChatMessage();
            
            -- Final result (AIChat has already handled any tool calls automatically in auto mode)
            local result = {
                success = resultCode == 200,
                code = resultCode,
                response = fullResult,
                thinking = fullThink,
                markdown = fullResult,
            };
            
            -- Update LLM history entry
            llmEntry.output = {
                response = fullResult,
                thinking = fullThink,
                code = resultCode,
            };
            llmEntry.status = resultCode == 200 and "success" or "error";
            
            -- Refresh debug UI
            self:RefreshDebugUI();
            
            self:DebugLog("LLM_OUTPUT", "code=%s response=%s", tostring(resultCode), fullResult or "");
            
            if callback then
                callback(result);
            end
            
            self:llmResponseReceived(result);
        else
            -- Streaming delta (resultCode is nil)
            -- Process delta for auto-speak if enabled
            -- Detect tool call content in delta (JSON function call or special markers)
            local isToolCallContent = delta and (delta:find('{"name":') 
                or delta:find('<|FunctionCall')
                or delta:find('|>%s*$')
                or (self.sentenceBuffer and (self.sentenceBuffer:find('{"name":')
                    or self.sentenceBuffer:find('<|FunctionCall'))));
            
            if isToolCallContent then
                -- Tool call detected: set flag to skip display and TTS
                if not self.isToolCallInProgress then
                    self.isToolCallInProgress = true;
                    self.toolCallHintSpoken = true;
                    self.sentenceBuffer = "";  -- Clear buffer (don't speak tool call)
                    LOG.std(nil, "debug", "BackgroundAgent", "Tool call detected, skipping display and TTS");
                end
                -- Skip both TTS and typewriter display for tool call content
            else
                -- Normal text content: process TTS and typewriter
                if self:IsAutoSpeakEnabled() and delta and delta ~= "" then
                    -- Accumulate delta to sentence buffer
                    self.sentenceBuffer = (self.sentenceBuffer or "") .. delta;
                    
                    -- Normal text content: extract and speak sentences
                    -- But skip if we're in the middle of tool call processing
                    if not self.isToolCallInProgress then
                        local extracted = self:_ExtractCompleteSentences(self.sentenceBuffer);
                        
                        -- Queue extracted sentences for TTS (filter out progress markers)
                        for _, sentence in ipairs(extracted.sentences) do
                            -- Filter progress markers before TTS to avoid speaking [xxx] content
                            local filtered = self:_FilterProgressMarkers(sentence);
                            if filtered and filtered ~= "" then
                                self:QueueTTSSentence(filtered);
                            end
                        end
                        
                        -- Flush TTS buffer immediately when we have complete sentences
                        -- This ensures sentences are spoken as soon as they're complete
                        if #extracted.sentences > 0 then
                            self:FlushTTSBuffer();
                        end
                        
                        -- Keep remaining text in buffer
                        self.sentenceBuffer = extracted.remaining;
                    end
                end
                
                -- IMPORTANT: Show typewriter effect for normal text only (not tool calls)
                -- This is separate from TTS which requires complete sentences
                if delta and delta ~= "" and not self.isToolCallInProgress then
                    -- Debug log to track delta flow
                    LOG.std(nil, "debug", "BackgroundAgent", "[TYPEWRITER] Received delta: %s (length: %d)", 
                        string.sub(delta, 1, 50), #delta);
                    
                    -- Trigger typewriter callback with raw delta (for real-time display)
                    if self.typewriterCallback then
                        self.typewriterCallback(delta);
                    end
                    
                    -- Emit typewriter signal for UI listeners (raw delta for real-time effect)
                    self:typewriterText(delta);
                end
            end
        end
    end, options);
end

--------------------------------------------------------------------------------
-- Tool Call Handling (Delegate Mode)
--------------------------------------------------------------------------------

--[[
    Get the strategy configuration for a tool
    @param toolName: string - Tool name
    @return table - Strategy configuration
]]
function BackgroundAgent:GetToolStrategy(toolName)
    return TOOL_STRATEGIES[toolName] or TOOL_STRATEGIES.default;
end

--[[
    Handle tool calls received from LLM in delegate mode
    Entry point for tool execution - routes to strategy-based executor
    @param toolCallInfo: table - {toolCalls = [...], messages = [...]} from AIChat
    @param callback: function(toolResults) - Called with array of {tool_call_id, content}
]]
function BackgroundAgent:HandleToolCallsFromLLM(toolCallInfo, callback)
    if not toolCallInfo or not toolCallInfo.toolCalls or #toolCallInfo.toolCalls == 0 then
        if callback then callback({}); end
        return;
    end
    
    local toolCalls = toolCallInfo.toolCalls;
    LOG.std(nil, "info", "BackgroundAgent", "HandleToolCallsFromLLM: processing %d tool calls", #toolCalls);
    
    -- Log tool calls start
    for _, tc in ipairs(toolCalls) do
        local funcName = tc["function"] and tc["function"].name or "unknown";
        ChatLogUtil.LogToolCallStart(self._currentSessionId, funcName, tc["function"] and tc["function"].arguments);
    end
    
    -- Execute tools based on their strategies
    self:ExecuteToolsByStrategy(toolCalls, callback);
end

--[[
    Execute tools based on their configured strategies
    Groups tools by mode and executes accordingly:
    - sync: Execute immediately, collect results
    - async: Wait for all callbacks
    - ui_blocking: Queue for user interaction
    @param toolCalls: array - Tool calls from LLM
    @param callback: function(toolResults) - Called when all tools complete
]]
function BackgroundAgent:ExecuteToolsByStrategy(toolCalls, callback)
    local toolResults = {};  -- {[callId] = {tool_call_id, content}}
    local toolOrder = {};    -- Track original order
    local pendingCount = 0;
    local completedCount = 0;
    
    -- Track start times for each tool
    local toolStartTimes = {};
    
    local function checkAllComplete()
        if completedCount >= #toolCalls then
            -- Build results array in original order
            local orderedResults = {};
            for _, callId in ipairs(toolOrder) do
                if toolResults[callId] then
                    table.insert(orderedResults, toolResults[callId]);
                end
            end
            
            LOG.std(nil, "info", "BackgroundAgent", "All %d tools complete, invoking callback", #orderedResults);
            
            if callback then
                callback(orderedResults);
            end
        end
    end
    
    for idx, toolCall in ipairs(toolCalls) do
        local funcName = toolCall["function"] and toolCall["function"].name or "unknown";
        local argsStr = toolCall["function"] and toolCall["function"].arguments or "{}";
        local callId = toolCall.id or string.format("call_%d", idx);
        
        -- Track original order
        table.insert(toolOrder, callId);
        toolStartTimes[callId] = ParaGlobal.timeGetTime();
        
        -- Get strategy for this tool
        local strategy = self:GetToolStrategy(funcName);
        
        -- Parse arguments
        local args = {};
        if argsStr and argsStr ~= "" then
            if not NPL.FromJson(argsStr, args) then
                LOG.std(nil, "warn", "BackgroundAgent", "Failed to parse tool arguments: %s", argsStr);
                args = {};
            end
        end
        
        -- Get tool handler
        local tool = self.tools[funcName];
        
        if not tool then
            -- Tool not found - check if it's a concatenation of multiple tool names
            local matchedTools = {};
            for registeredName, _ in pairs(self.tools) do
                local startPos = funcName:find(registeredName, 1, true);
                if startPos then
                    table.insert(matchedTools, {name = registeredName, pos = startPos, len = #registeredName});
                end
            end
            
            -- Sort by position then by length (prefer longer matches at same position)
            table.sort(matchedTools, function(a, b)
                if a.pos == b.pos then return a.len > b.len end
                return a.pos < b.pos;
            end);
            
            -- Try to auto-fix concatenated tool calls (e.g., "tool1tool2" -> ["tool1", "tool2"])
            if #matchedTools >= 2 then
                -- Find non-overlapping tools that cover the concatenated name
                local selectedTools = {};
                local coveredEnd = 0;
                for _, toolInfo in ipairs(matchedTools) do
                    if toolInfo.pos > coveredEnd then
                        table.insert(selectedTools, toolInfo);
                        coveredEnd = toolInfo.pos + toolInfo.len - 1;
                    end
                end
                
                -- If we found exactly 2 tools that make up the concatenated name
                if #selectedTools == 2 then
                    LOG.std(nil, "info", "BackgroundAgent", "Auto-splitting concatenated tool call: %s -> %s, %s", 
                        funcName, selectedTools[1].name, selectedTools[2].name);
                    
                    -- Try to split the arguments by finding }{ pattern
                    local splitArgs = {};
                    local firstJson, secondJson = argsStr:match("^({.-})({.+})$");
                    if firstJson and secondJson then
                        splitArgs[1] = firstJson;
                        splitArgs[2] = secondJson;
                    else
                        -- Fallback: try splitting by }{
                        local splitPos = argsStr:find("}{", 1, true);
                        if splitPos then
                            splitArgs[1] = argsStr:sub(1, splitPos);
                            splitArgs[2] = argsStr:sub(splitPos + 1);
                        else
                            splitArgs[1] = argsStr;
                            splitArgs[2] = "{}";
                        end
                    end
                    
                    -- Create synthetic tool calls for each split tool
                    local syntheticCalls = {};
                    for i, toolInfo in ipairs(selectedTools) do
                        table.insert(syntheticCalls, {
                            ["function"] = {
                                name = toolInfo.name,
                                arguments = splitArgs[i] or "{}"
                            },
                            id = string.format("%s_split_%d", callId, i)
                        });
                    end
                    
                    -- Execute the split tool calls recursively
                    self:ExecuteToolsByStrategy(syntheticCalls, function(splitResults)
                        -- Combine results
                        local combinedContent = "Auto-split tool execution:\n";
                        for _, result in ipairs(splitResults) do
                            combinedContent = combinedContent .. result.content .. "\n";
                        end
                        toolResults[callId] = { tool_call_id = callId, content = combinedContent };
                        completedCount = completedCount + 1;
                        checkAllComplete();
                    end);
                    
                    -- Skip normal processing for this tool call
                    goto continue_next_tool;
                end
            end
            
            -- No auto-fix possible - return error
            local errorMsg = "Tool not found: " .. funcName;
            if #matchedTools > 0 then
                local toolNames = {};
                for _, t in ipairs(matchedTools) do table.insert(toolNames, t.name); end
                errorMsg = string.format(
                    "Invalid tool call: '%s' appears to be concatenated tool names. " ..
                    "Each tool must be called SEPARATELY. Detected tools: %s.",
                    funcName, table.concat(toolNames, ", ")
                );
            end
            
            local errorContent = self:BuildToolResultContext(funcName, nil, errorMsg);
            toolResults[callId] = { tool_call_id = callId, content = errorContent };
            completedCount = completedCount + 1;
            
            -- Log error
            local duration = ParaGlobal.timeGetTime() - toolStartTimes[callId];
            ChatLogUtil.LogToolCallEnd(self._currentSessionId, funcName, callId, "error", errorContent, duration);
            
            checkAllComplete();
        else
            -- Execute based on strategy mode
            pendingCount = pendingCount + 1;
            
            local function onToolComplete(result)
                completedCount = completedCount + 1;
                
                -- Calculate duration
                local duration = ParaGlobal.timeGetTime() - toolStartTimes[callId];
                
                -- Build context and store result
                local content = self:BuildToolResultContext(funcName, result, nil);
                toolResults[callId] = { tool_call_id = callId, content = content };
                
                -- Log completion
                local status = (type(result) == "table" and result.error) and "error" or "success";
                ChatLogUtil.LogToolCallEnd(self._currentSessionId, funcName, callId, status, content, duration);
                
                -- Emit signal
                self:toolExecuted(funcName, args, result);
                
                checkAllComplete();
            end
            
            -- Execute tool with error handling
            local ok, err = pcall(function()
                if strategy.mode == "ui_blocking" then
                    -- UI blocking tools use LaunchLearningTool mechanism
                    LOG.std(nil, "debug", "BackgroundAgent", "Executing UI blocking tool: %s", funcName);
                    tool.handler(args, function(result)
                        -- UI tools call back when user completes interaction
                        onToolComplete(result);
                    end);
                elseif strategy.mode == "async" then
                    -- Async tools wait for callback
                    LOG.std(nil, "debug", "BackgroundAgent", "Executing async tool: %s", funcName);
                    local returned = tool.handler(args, function(result)
                        onToolComplete(result);
                    end);
                    -- If handler returns synchronously, use that result
                    if returned ~= nil then
                        onToolComplete(returned);
                    end
                else
                    -- Sync tools (default) - execute and collect result immediately
                    LOG.std(nil, "debug", "BackgroundAgent", "Executing sync tool: %s", funcName);
                    local result = nil;
                    local callbackCalled = false;
                    
                    tool.handler(args, function(handlerResult)
                        callbackCalled = true;
                        result = handlerResult;
                    end);
                    
                    if callbackCalled then
                        onToolComplete(result);
                    else
                        -- Shouldn't happen for sync tools, but handle it
                        LOG.std(nil, "warn", "BackgroundAgent", "Sync tool %s did not call callback synchronously", funcName);
                        -- Will complete when callback is eventually called
                    end
                end
            end);
            
            if not ok then
                -- Error during tool execution
                LOG.std(nil, "error", "BackgroundAgent", "Error executing tool %s: %s", funcName, tostring(err));
                local errorContent = self:BuildToolResultContext(funcName, nil, "Execution error: " .. tostring(err));
                toolResults[callId] = { tool_call_id = callId, content = errorContent };
                completedCount = completedCount + 1;
                
                local duration = ParaGlobal.timeGetTime() - toolStartTimes[callId];
                ChatLogUtil.LogToolCallEnd(self._currentSessionId, funcName, callId, "error", errorContent, duration);
                
                checkAllComplete();
            end
        end
        
        ::continue_next_tool::
    end
    
    -- If no tools to execute, complete immediately
    if #toolCalls == 0 then
        if callback then callback({}); end
    end
end

--[[
    Build context string from tool result for LLM consumption
    @param toolName: string - Tool name
    @param result: any - Tool result (table, string, or nil)
    @param error: string or nil - Error message if failed
    @return string - Formatted context for LLM
]]
function BackgroundAgent:BuildToolResultContext(toolName, result, error)
    if error then
        return string.format("Error: %s", tostring(error));
    end
    
    -- Extract llm_result if available
    local resultStr;
    if type(result) == "table" and result.llm_result then
        resultStr = tostring(result.llm_result);
    elseif type(result) == "string" then
        resultStr = result;
    elseif result == nil then
        resultStr = "Tool executed successfully (no output)";
    else
        resultStr = commonlib.serialize_compact(result);
    end
    
    -- Truncate if too long (prevent token overflow)
    local maxLen = AIChat.MaxToolResultLength or 4000;
    if #resultStr > maxLen then
        resultStr = resultStr:sub(1, maxLen) .. "\n...[truncated, total " .. #resultStr .. " chars]";
    end
    
    return resultStr;
end

--[[
    Complete LLM response after tool calls (helper method for callback chain)
    @param llmEntry: table - LLM history entry to update
    @param startTime: number - Request start time
    @param resultCode: number - HTTP result code
    @param fullResult: string - Final response text
    @param fullThink: string - Final thinking text
    @param callback: function - Original callback
]]
function BackgroundAgent:_CompleteLLMResponse(llmEntry, startTime, resultCode, fullResult, fullThink, callback)
    -- Calculate duration
    llmEntry.duration = commonlib.TimerManager.GetCurrentTime() - startTime;
    
    -- Process any remaining text in sentence buffer for auto-speak
    if self:IsAutoSpeakEnabled() and self.sentenceBuffer and self.sentenceBuffer ~= "" then
        local trimmed = self.sentenceBuffer:match("^%s*(.-)%s*$");
        if trimmed and trimmed ~= "" then
            self:QueueTTSSentence(trimmed);
        end
        self.sentenceBuffer = "";
    end
    
    -- Flush TTS buffer
    if self:IsAutoSpeakEnabled() then
        self:FlushTTSBuffer();
    end
    
    -- Complete current chat message
    self:CompleteChatMessage();
    
    -- Build result
    local result = {
        success = resultCode == 200,
        code = resultCode,
        response = fullResult,
        thinking = fullThink,
        markdown = fullResult,
    };
    
    -- Update LLM history entry
    llmEntry.output = {
        response = fullResult,
        thinking = fullThink,
        code = resultCode,
    };
    llmEntry.status = resultCode == 200 and "success" or "error";
    
    -- Refresh debug UI
    self:RefreshDebugUI();
    
    self:DebugLog("LLM_OUTPUT", "code=%s response=%s", tostring(resultCode), fullResult or "");
    
    if callback then
        callback(result);
    end
    
    self:llmResponseReceived(result);
end

--[[
    Handle streaming delta during LLM response (helper for delegate mode continuation)
    @param delta: string - Streaming text delta
    @param deltaThink: string - Streaming thinking delta
]]
function BackgroundAgent:_HandleLLMStreamingDelta(delta, deltaThink)
    -- Detect tool call content in delta
    local isToolCallContent = delta and (delta:find('{"name":') 
        or delta:find('<|FunctionCall')
        or delta:find('|>%s*$'));
    
    if isToolCallContent then
        -- Skip tool call content
        if not self.isToolCallInProgress then
            self.isToolCallInProgress = true;
            self.sentenceBuffer = "";
        end
    else
        -- Normal content
        if self:IsAutoSpeakEnabled() and delta and delta ~= "" then
            self.sentenceBuffer = (self.sentenceBuffer or "") .. delta;
            
            if not self.isToolCallInProgress then
                local extracted = self:_ExtractCompleteSentences(self.sentenceBuffer);
                for _, sentence in ipairs(extracted.sentences) do
                    local filtered = self:_FilterProgressMarkers(sentence);
                    if filtered and filtered ~= "" then
                        self:QueueTTSSentence(filtered);
                    end
                end
                if #extracted.sentences > 0 then
                    self:FlushTTSBuffer();
                end
                self.sentenceBuffer = extracted.remaining;
            end
        end
        
        -- Typewriter effect
        if delta and delta ~= "" and not self.isToolCallInProgress then
            if self.typewriterCallback then
                self.typewriterCallback(delta);
            end
            self:typewriterText(delta);
        end
    end
end

--------------------------------------------------------------------------------
-- Utility Methods
--------------------------------------------------------------------------------

--[[
    Get all discovered copilots
    @return table - Array of copilot info
]]
function BackgroundAgent:GetDiscoveredCopilots()
    return self.discoveredCopilots;
end

--[[
    Get a specific copilot by name
    @param name: string - Copilot name
    @return table - Copilot info or nil
]]
function BackgroundAgent:GetCopilotByName(name)
    for _, copilot in ipairs(self.discoveredCopilots) do
        if copilot.name == name then
            return copilot;
        end
    end
    return nil;
end

--[[
    Check if the agent is currently enabled (deprecated, use GetPlaybackState())
    @return boolean - True if playing or paused (not stopped)
]]
function BackgroundAgent:IsEnabled()
    return self.playbackState ~= "stopped";
end

--[[
    Refresh copilot discovery
]]
function BackgroundAgent:RefreshCopilots()
    self:DiscoverCopilots();
end

--------------------------------------------------------------------------------
-- Persistence (Cross-Session Learning State)
--------------------------------------------------------------------------------
--[[
    Get the storage key for learning data
    @return string - Unique key for this agent's learning data
]]
function BackgroundAgent:GetLearningStorageKey()
    local taskId = self.primaryTask and self.primaryTask.id or "default";
    return string.format("BackgroundAgent_Learning_%s", taskId);
end

--[[
    Save learning state to persistent storage (cross-session)
    Saves: primaryTask, learningProgress, dialogHistoryManager state
]]
function BackgroundAgent:SaveLearningState()
    local data = {
        version = 2,
        savedAt = os.time(),
        userProfile = self.userProfile,
        primaryTask = self.primaryTask,
        learningProgress = self.learningProgress,
        dialogHistoryState = self.dialogHistoryManager and self.dialogHistoryManager:GetState() or nil,
    };
    
    local key = self:GetLearningStorageKey();
    
    GameLogic.GetPlayerController():SaveLocalUserWorldData(key, data, false, false);
    LOG.std(nil, "info", "BackgroundAgent", "Learning state saved: %s (mastered: %d)", key, self.learningProgress.masteredCount or 0);
    self.sessionState.lastCheckpoint = os.time();
end

--[[
    Load learning state from persistent storage
    @param taskId: string (optional) - Specific task ID to load, or uses current task
    @return boolean - True if state was loaded
]]
function BackgroundAgent:LoadLearningState(taskId)
    local key;
    if taskId then
        key = string.format("BackgroundAgent_Learning_%s", taskId);
    else
        key = self:GetLearningStorageKey();
    end
    
    local data = GameLogic.GetPlayerController():LoadLocalUserWorldData(key, nil, false);
    
    if not data then
        LOG.std(nil, "info", "BackgroundAgent", "No saved learning state found: %s", key);
        return false;
    end
    
    -- Restore state
    if data.userProfile then
        self.userProfile = data.userProfile;
    end
    
    if data.primaryTask then
        self.primaryTask = data.primaryTask;
    end
    
    if data.learningProgress then
        self.learningProgress = data.learningProgress;
        -- Update session start time to now
        self.learningProgress.sessionStartTime = os.time();
    end
    
    -- Restore dialog history manager state (v2+ format)
    if data.dialogHistoryState and self.dialogHistoryManager then
        self.dialogHistoryManager:SetState(data.dialogHistoryState);
    elseif data.dialogSummary then
        -- Legacy v1 format: restore summary only
        if self.dialogHistoryManager then
            self.dialogHistoryManager:SetState({dialogSummary = data.dialogSummary});
        end
    end
    
    -- Sync language to dialog history manager based on restored userProfile
    if self.dialogHistoryManager and self.userProfile then
        local lang = (self.userProfile.primaryLanguage == "Chinese" or self.userProfile.primaryLanguage == "zh") and "zh" or "en";
        self.dialogHistoryManager:SetLanguage(lang);
    end
    
    LOG.std(nil, "info", "BackgroundAgent", "Learning state loaded: %s (mastered: %d/%d)", 
        key, 
        self.learningProgress.masteredCount or 0,
        self.primaryTask and self.primaryTask.completionCriteria and self.primaryTask.completionCriteria.totalItemsRequired or 0);
    
    return true;
end

--[[
    Check and perform auto-save if checkpoint interval has passed
]]
function BackgroundAgent:CheckAutoSave()
    local now = os.time();
    local lastCheckpoint = self.sessionState.lastCheckpoint or 0;
    local interval = self.sessionState.checkpointInterval;
    
    if now - lastCheckpoint >= interval then
        self:SaveLearningState();
    end
end

--[[
    Clear saved learning state
    @param taskId: string (optional) - Specific task ID to clear
]]
function BackgroundAgent:ClearLearningState(taskId)
    local key;
    if taskId then
        key = string.format("BackgroundAgent_Learning_%s", taskId);
    else
        key = self:GetLearningStorageKey();
    end
    
    GameLogic.GetPlayerController():SaveLocalUserWorldData(key, nil, false, false);
    LOG.std(nil, "info", "BackgroundAgent", "Learning state cleared: %s", key);
end

--[[
    List all saved learning tasks
    @return table - Array of {taskId, title, savedAt, masteredCount}
]]
function BackgroundAgent:ListSavedLearningTasks()
    -- This would require scanning storage keys, which isn't directly supported
    -- For now, return empty array - could be implemented with a task index
    return {};
end
--------------------------------------------------------------------------------
-- Scene Vision & Voice Context Integration
--------------------------------------------------------------------------------

--[[
    Called when SceneVisionManager captures a new screenshot
    Saves to history; in Play mode, triggers LLM request with the image
    @param entry: table - Screenshot entry from SceneVisionManager
        {timestamp, path, relativePath, cameraPos, blockChangeCount}
]]
function BackgroundAgent:OnScreenshotCaptured(entry)
    if not entry then return; end
    print("BackgroundAgent:OnScreenshotCaptured", entry.path);
    -- Create history entry
    local historyEntry = {
        timestamp = entry.timestamp or os.time(),
        imagePath = entry.path,
        imageUrl = nil,  -- Will be set after upload
        description = nil,  -- Will be set after LLM describes it
        sentToLLM = false,
        cameraPos = entry.cameraPos,
    };
    
    -- Upload the image to get URL
    FileTools.UpLoadVisionFile(entry.path, function(url)
        historyEntry.imageUrl = url;
        self.lastSceneVisionEntry = historyEntry;
        
        -- Clear sceneDirty since we now have an up-to-date screenshot
        self.sceneDirty = false;
        
        -- Add to history
        table.insert(self.sceneVisionHistory, historyEntry);
        
        -- Trim history if exceeds max size
        while #self.sceneVisionHistory > self.maxSceneVisionHistorySize do
            table.remove(self.sceneVisionHistory, 1);
        end
        
        LOG.std(nil, "debug", "BackgroundAgent", "Screenshot captured and uploaded: %s (history: %d)", url or "nil", #self.sceneVisionHistory);
        
        -- Refresh debug UI if visible
        self:RefreshDebugUI();
    end);
end

--[[
    Called when VoiceContextManager transcribes a voice segment
    Saves to history; in Play mode, sends to LLM immediately
    @param entry: table - Voice entry from VoiceContextManager
        {id, startTime, endTime, duration, transcript, confidence}
]]
function BackgroundAgent:OnVoiceTranscribed(entry)
    if not entry or not entry.transcript then return; end
    
    -- Check for TTS stop keywords (user wants to interrupt)
    if self:_CheckTTSStopKeyword(entry.transcript) then
        LOG.std(nil, "info", "BackgroundAgent", "TTS stop keyword detected: %s", entry.transcript);
        self:ClearTTSQueue();
    end
    
    -- Create history entry
    local historyEntry = {
        timestamp = entry.startTime or os.time(),
        transcript = entry.transcript,
        duration = entry.duration,
        confidence = entry.confidence,
        sentToLLM = false,
        llmResponse = nil,
    };
    
    -- Add to history
    table.insert(self.voiceHistory, historyEntry);
    
    -- Trim history if exceeds max size
    while #self.voiceHistory > self.maxVoiceHistorySize do
        table.remove(self.voiceHistory, 1);
    end
    
    LOG.std(nil, "info", "BackgroundAgent", "Voice transcribed: %s", entry.transcript);
    
    -- In Play mode, send to LLM immediately
    if self.playbackState == "playing" then
        -- Add to pending queue for processing
        table.insert(self.pendingVoiceEntries, historyEntry);
        -- Process pending voice entries
        self:ProcessPendingVoiceEntries();
    end
    
    -- Refresh debug UI if visible
    self:RefreshDebugUI();
end

--[[
    Process pending voice entries - send to LLM
    Only processes in Play mode with 5 second minimum interval
    During cooldown, new voice entries are merged and deduplicated
]]
function BackgroundAgent:ProcessPendingVoiceEntries()
    if self.playbackState ~= "playing" then
        return;
    end
    
    if #self.pendingVoiceEntries == 0 then
        return;
    end
    
    -- Check if already processing
    if self.voiceLLMThrottle.isProcessing then
        LOG.std(nil, "debug", "BackgroundAgent", "Voice LLM call skipped: already processing");
        return;
    end
    
    -- Check 5 second throttle
    local currentTime = commonlib.TimerManager.GetCurrentTime();
    local timeSinceLastCall = currentTime - self.voiceLLMThrottle.lastCallTime;
    if timeSinceLastCall < self.voiceLLMThrottle.minInterval then
        local waitTime = self.voiceLLMThrottle.minInterval - timeSinceLastCall;
        LOG.std(nil, "debug", "BackgroundAgent", "Voice LLM call throttled, waiting %dms, pending=%d", waitTime, #self.pendingVoiceEntries);
        -- Schedule retry after the remaining wait time (entries will be merged when timer fires)
        if not self.voiceLLMThrottle.pendingTimer then
            self.voiceLLMThrottle.pendingTimer = commonlib.TimerManager.SetTimeout(function()
                self.voiceLLMThrottle.pendingTimer = nil;
                self:ProcessPendingVoiceEntries();
            end, waitTime + 100);
        end
        return;
    end
    
    -- Merge all pending entries into one, deduplicating transcripts
    local mergedTranscripts = {};
    local seenTranscripts = {};
    local mergedEntry = nil;
    
    while #self.pendingVoiceEntries > 0 do
        local entry = table.remove(self.pendingVoiceEntries, 1);
        if entry and not entry.sentToLLM and entry.transcript then
            -- Deduplicate: skip if we've seen this exact transcript
            local trimmedTranscript = entry.transcript:match("^%s*(.-)%s*$") or entry.transcript;
            if not seenTranscripts[trimmedTranscript] then
                seenTranscripts[trimmedTranscript] = true;
                table.insert(mergedTranscripts, trimmedTranscript);
                
                -- Use first entry as base for merged entry
                if not mergedEntry then
                    mergedEntry = entry;
                end
            end
        end
    end
    
    if not mergedEntry or #mergedTranscripts == 0 then
        return;
    end
    
    -- Combine all unique transcripts
    local combinedTranscript = table.concat(mergedTranscripts, " ");
    mergedEntry.transcript = combinedTranscript;
    mergedEntry.sentToLLM = true;
    
    LOG.std(nil, "info", "BackgroundAgent", "Merged %d voice entries: %s", #mergedTranscripts, combinedTranscript);
    
    -- Mark as being processed
    self.voiceLLMThrottle.isProcessing = true;
    self.voiceLLMThrottle.lastCallTime = currentTime;
    
    -- Build prompt with voice input and scene context
    local userQuery = mergedEntry.transcript;
    
    -- Use cached screenshot (screenshot capture is handled by OnSceneChanged debounce)
    local latestVision = self:GetLatestSceneVision();
    local imageUrl = latestVision and latestVision.imageUrl or nil;
    
    -- Prepare options with image
    local askOptions = {
        includeImage = true,
        tools = true,
    };
    
    -- Pass the cached image URL
    if imageUrl and imageUrl ~= "" then
        askOptions.imageUrl = imageUrl;
        LOG.std(nil, "debug", "BackgroundAgent", "Voice using cached image: %s", imageUrl);
    else
        LOG.std(nil, "warn", "BackgroundAgent", "No cached image available for voice processing");
    end
    
    -- Send to LLM with current scene context
    local self_ = self;
    self:ProcessWithLLM(userQuery, function(result)
        -- Mark processing complete
        self_.voiceLLMThrottle.isProcessing = false;
        
        -- Store LLM response in the entry
        mergedEntry.llmResponse = result and result.response or nil;
        
        LOG.std(nil, "info", "BackgroundAgent", "Voice processed by LLM: %s -> %s", 
            mergedEntry.transcript, 
            mergedEntry.llmResponse and string.sub(mergedEntry.llmResponse, 1, 50) or "nil");
        
        -- Refresh debug UI
        self_:RefreshDebugUI();
        
        -- Process next pending entry if any (with throttle delay)
        if #self_.pendingVoiceEntries > 0 then
            commonlib.TimerManager.SetTimeout(function()
                self_:ProcessPendingVoiceEntries();
            end, self_.voiceLLMThrottle.minInterval);
        end
    end, askOptions);
end

--[[
    Get the latest scene vision entry (last captured screenshot)
    @return table - Scene vision entry or nil
]]
function BackgroundAgent:GetLatestSceneVision()
    return self.lastSceneVisionEntry or self.sceneVisionHistory[#self.sceneVisionHistory];
end

--[[
    Get scene vision history
    @return table - Array of scene vision entries
]]
function BackgroundAgent:GetSceneVisionHistory()
    return self.sceneVisionHistory;
end

--[[
    Get voice recognition history
    @return table - Array of voice history entries
]]
function BackgroundAgent:GetVoiceHistory()
    return self.voiceHistory;
end

--[[
    Get pending voice entries count
    @return number
]]
function BackgroundAgent:GetPendingVoiceCount()
    return #self.pendingVoiceEntries;
end

--[[
    Clear scene vision history
]]
function BackgroundAgent:ClearSceneVisionHistory()
    self.sceneVisionHistory = {};
    self.lastSceneVisionEntry = nil;
    LOG.std(nil, "info", "BackgroundAgent", "Scene vision history cleared");
end

--[[
    Clear voice history
]]
function BackgroundAgent:ClearVoiceHistory()
    self.voiceHistory = {};
    self.pendingVoiceEntries = {};
    LOG.std(nil, "info", "BackgroundAgent", "Voice history cleared");
end

--[[
    Get LLM call history
    @return table - Array of LLM history entries
]]
function BackgroundAgent:GetLLMHistory()
    return self.llmHistory or {};
end

--[[
    Get a specific LLM history entry by index (1-based, newest first)
    @param index: number - 1-based index (1 = most recent)
    @return table - LLM history entry or nil
]]
function BackgroundAgent:GetLLMHistoryEntry(index)
    local history = self.llmHistory or {};
    local reversedIndex = #history - index + 1;
    return history[reversedIndex];
end

--[[
    Get LLM history count
    @return number
]]
function BackgroundAgent:GetLLMHistoryCount()
    return #(self.llmHistory or {});
end

--[[
    Clear LLM history
]]
function BackgroundAgent:ClearLLMHistory()
    self.llmHistory = {};
    LOG.std(nil, "info", "BackgroundAgent", "LLM history cleared");
end

--[[
    Get formatted LLM history entry for display
    @param index: number - 1-based index (1 = most recent)
    @return table - Formatted entry with display-friendly fields
]]
function BackgroundAgent:GetFormattedLLMEntry(index)
    local entry = self:GetLLMHistoryEntry(index);
    if not entry then return nil; end
    
    local formatted = {
        timestamp = entry.timestamp,
        timeStr = os.date("%H:%M:%S", entry.timestamp),
        status = entry.status,
        duration = entry.duration,
        durationStr = entry.duration and string.format("%.1fs", entry.duration / 1000) or "",
        hasImage = entry.input and entry.input.hasImage or false,
        inputPrompt = entry.input and entry.input.prompt or "",
        inputPromptShort = "",
        response = entry.output and entry.output.response or "",
        responseShort = "",
        toolCalls = entry.toolCalls or {},
        toolResults = entry.toolResults or {},
        toolCallCount = entry.toolCalls and #entry.toolCalls or 0,
    };
    
    -- Create short versions for display
    if formatted.inputPrompt and commonlib.utf8.len(formatted.inputPrompt) > 50 then
        formatted.inputPromptShort = commonlib.utf8.sub(formatted.inputPrompt, 1, 47) .. "...";
    else
        formatted.inputPromptShort = formatted.inputPrompt or "";
    end
    
    if formatted.response and commonlib.utf8.len(formatted.response) > 100 then
        formatted.responseShort = commonlib.utf8.sub(formatted.response, 1, 97) .. "...";
    else
        formatted.responseShort = formatted.response or "";
    end
    
    return formatted;
end

--[[
    Get formatted context history for display
    Combines scene vision and voice history in chronological order
    @param maxEntries: number - Maximum entries to return (default 20)
    @return table - Array of formatted entries
]]
function BackgroundAgent:GetFormattedContextHistory(maxEntries)
    maxEntries = maxEntries or 20;
    local combined = {};
    
    -- Add scene vision entries
    for _, entry in ipairs(self.sceneVisionHistory) do
        table.insert(combined, {
            type = "screenshot",
            timestamp = entry.timestamp,
            content = entry.description or "截图",
            imageUrl = entry.imageUrl,
            imagePath = entry.imagePath,
            sentToLLM = entry.sentToLLM,
        });
    end
    
    -- Add voice entries
    for _, entry in ipairs(self.voiceHistory) do
        table.insert(combined, {
            type = "voice",
            timestamp = entry.timestamp,
            content = entry.transcript,
            duration = entry.duration,
            sentToLLM = entry.sentToLLM,
            llmResponse = entry.llmResponse,
        });
    end
    
    -- Sort by timestamp (newest first)
    table.sort(combined, function(a, b)
        return (a.timestamp or 0) > (b.timestamp or 0);
    end);
    
    -- Limit to maxEntries
    local result = {};
    for i = 1, math.min(maxEntries, #combined) do
        table.insert(result, combined[i]);
    end
    
    return result;
end

--[[
    Get context history summary for LLM prompt
    @return string - Markdown formatted history summary
]]
function BackgroundAgent:GetContextHistorySummary()
    local md = "";
    
    -- Only include latest screenshot description (reduced from 3 to 1 for token savings)
    if #self.sceneVisionHistory > 0 then
        local entry = self.sceneVisionHistory[#self.sceneVisionHistory];
        if entry and entry.description then
            md = md .. string.format("- 场景: %s\n", entry.description);
        end
    end
    
    -- Recent voice inputs (reduced from 5 to 2 for token savings)
    local voiceCount = 0;
    for i = #self.voiceHistory, math.max(1, #self.voiceHistory - 1), -1 do
        local entry = self.voiceHistory[i];
        if entry and entry.transcript then
            voiceCount = voiceCount + 1;
            md = md .. string.format("- 语音: %s\n", entry.transcript);
        end
    end
    
    if md ~= "" then
        md = "## Recent Context\n" .. md;
    end
    
    return md;
end

--------------------------------------------------------------------------------
-- Debug UI
--------------------------------------------------------------------------------

--[[
    Show debug UI for BackgroundAgent
    @param bShow: boolean - Whether to show or hide
]]
function BackgroundAgent:ShowDebugUI(bShow)
    if bShow then
        if not self.debugPage then
            self:SetDebugEnabled(true)
            local width, height = 1100, 600;
            local params = {
                url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/BackgroundAgentDebug.html",
                name = "BackgroundAgentDebug.ShowPage",
                isShowTitleBar = false,
                DestroyOnClose = true,
                bToggleShowHide = false,
                style = CommonCtrl.WindowFrame.ContainerStyle,
                allowDrag = true,
                enable_esc_key = true,
                bShow = true,
                click_through = false,
                zorder = 10,
                directPosition = true,
                align = "_ct",
                x = -width / 2,
                y = -height / 2,
                width = width,
                height = height,
            };
            System.App.Commands.Call("File.MCMLWindowFrame", params);
            if params._page then
                self.debugPage = params._page;
                self.debugPage.OnClose = function()
                    self.debugPage = nil;
                end
            end
        end
    else
        if self.debugPage then
            self.debugPage:CloseWindow();
            self.debugPage = nil;
        end
    end
end

--[[
    Refresh debug UI if visible
]]
function BackgroundAgent:RefreshDebugUI()
    if self.debugPage then
        self.debugPage:Refresh(0.1);
    end
end

--------------------------------------------------------------------------------
-- Compact UI (less intrusive, top-right panel)
--------------------------------------------------------------------------------

--[[
    Show compact UI for BackgroundAgent (top-right corner)
    @param bShow: boolean - Whether to show or hide
]]
function BackgroundAgent:ShowUI(bShow)
    if bShow then
        if not self.uiPage then
            local width, height = 280, 180;
            local params = {
                url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/BackgroundAgentUI.html",
                name = "BackgroundAgentUI.ShowPage",
                isShowTitleBar = false,
                DestroyOnClose = true,
                bToggleShowHide = false,
                style = CommonCtrl.WindowFrame.ContainerStyle,
                allowDrag = true,
                enable_esc_key = false,
                bShow = true,
                click_through = false,
                zorder = 10,
                directPosition = true,
                align = "_rt",  -- Top-right alignment
                x = -width - 10,
                y = 10,
                width = width,
                height = height,
            };
            System.App.Commands.Call("File.MCMLWindowFrame", params);
            if params._page then
                self.uiPage = params._page;
                self.uiPage.OnClose = function()
                    self.uiPage = nil;
                end
            end
        end
    else
        if self.uiPage then
            self.uiPage:CloseWindow();
            self.uiPage = nil;
        end
    end
end

--[[
    Refresh compact UI if visible
]]
function BackgroundAgent:RefreshUI()
    if self.uiPage then
        self.uiPage:Refresh(0.1);
    end
end

--------------------------------------------------------------------------------
-- NPLJS Communication (JS ↔ Lua bidirectional messaging)
-- Follows MiniGameMgr / miniGameProxy communication pattern.
-- JS→Lua messages arrive on "@webparacraft_backgroundAgent"
-- Lua→JS messages are sent on "@keepwork_backgroundAgent"
--------------------------------------------------------------------------------

--[[
    Send a message to the JS BackgroundAgent via NPLJS.
    @param msgType: string - Message type (e.g. "typewriterText", "llmResponseReceived")
    @param data: table - Payload data
]]
function BackgroundAgent:SendToJS(msgType, data)
    if not NPLJS then return end
    local msg = data or {};
    msg.type = msgType;
    NPLJS:SendMsg(npljs_send_event, msg);
end

--[[
    Register NPLJS message handlers to receive and dispatch messages from JS.
    Should be called once during initialization (from InitContext or Play).
    Follows the MiniGameMgr:LoadWebviewFinished() / NPLJS:OnMsg() pattern.
]]
function BackgroundAgent:RegisterNPLJSHandlers()
    if self._npljsRegistered then return end
    self._npljsRegistered = true;

    if not NPLJS then
        LOG.std(nil, "warn", "BackgroundAgent", "NPLJS not available, JS communication disabled");
        return;
    end

    LOG.std(nil, "info", "BackgroundAgent", "Registering NPLJS handlers for JS communication");

    NPLJS:OnMsg(npljs_recv_event, function(msgdata, msgid)
        if type(msgdata) ~= "table" then return end
        local action = msgdata.type;
        if not action then return end

        LOG.std(nil, "debug", "BackgroundAgent", "NPLJS received: type=%s", action);

        local agent = BackgroundAgent:GetInstance();
        agent:HandleJSMessage(msgdata, msgid);
    end);

    -- Connect internal signals to broadcast events to JS
    self:ConnectSignalsToJS();
end

--[[
    Unregister NPLJS message handlers (called from Stop()).
]]
function BackgroundAgent:UnregisterNPLJSHandlers()
    if not self._npljsRegistered then return end
    self._npljsRegistered = false;

    if NPLJS then
        NPLJS:OffMsg(npljs_recv_event);
        LOG.std(nil, "info", "BackgroundAgent", "Unregistered NPLJS handlers");
    end
end

--[[
    Connect BackgroundAgent signals to automatically broadcast events to JS.
    This keeps JS side in sync with Lua-side state changes.
]]
function BackgroundAgent:ConnectSignalsToJS()
    -- Typewriter text streaming (LLM response deltas)
    self:Connect("typewriterText", function(delta)
        self:SendToJS("typewriterText", {delta = delta});
    end);

    -- Scene context captured
    self:Connect("sceneContextCaptured", function(imageUrl)
        self:SendToJS("screenshotCaptured", {imageUrl = imageUrl});
    end);

    -- Tool executed
    self:Connect("toolExecuted", function(toolName, result)
        self:SendToJS("toolExecuted", {toolName = toolName, result = result});
    end);

    -- LLM response received
    self:Connect("llmResponseReceived", function(result)
        self:SendToJS("llmResponseReceived", {
            success = result.success,
            code = result.code,
            response = result.response,
            thinking = result.thinking,
        });
    end);

    -- Playback state changes
    self:Connect("played", function()
        self:SendToJS("playbackStateChanged", {state = "playing"});
    end);
    self:Connect("paused", function()
        self:SendToJS("playbackStateChanged", {state = "paused"});
    end);
    self:Connect("stopped", function()
        self:SendToJS("playbackStateChanged", {state = "stopped"});
    end);

    -- Primary task changed
    self:Connect("primaryTaskChanged", function(task)
        self:SendToJS("primaryTaskChanged", {task = task});
    end);

    -- Progress update
    self:Connect("progressUpdate", function(progress)
        self:SendToJS("progressUpdate", {progress = progress});
    end);

    -- TTS events
    self:Connect("ttsStarted", function(text)
        self:SendToJS("ttsStarted", {text = text});
    end);
    self:Connect("ttsCompleted", function()
        self:SendToJS("ttsCompleted", {});
    end);

    -- Chat content update
    self:Connect("chatContentUpdate", function(content)
        self:SendToJS("chatContentUpdate", {content = content});
    end);
end

--[[
    Dispatch incoming JS messages to appropriate handler methods.
    Message format: { type = "actionName", ... (action-specific params) }
    Response format: Sends reply via SendToJS with type = "actionName_response"
    @param msgdata: table - The incoming message
    @param msgid: string - NPLJS message ID (for request/reply correlation)
]]
function BackgroundAgent:HandleJSMessage(msgdata, msgid)
    local action = msgdata.type;

    if action == "processWithLLM" then
        -- JS requests LLM processing
        local userQuery = msgdata.query or "";
        local options = msgdata.options or {};
        self:ProcessWithLLM(userQuery, function(result)
            self:SendToJS("processWithLLM_response", {
                requestId = msgdata.requestId,
                success = result.success,
                code = result.code,
                response = result.response,
                thinking = result.thinking,
            });
        end, options);

    elseif action == "captureSceneAsImage" then
        -- JS requests scene screenshot
        self:CaptureSceneAsImage(function(imageUrl)
            self:SendToJS("captureSceneAsImage_response", {
                requestId = msgdata.requestId,
                imageUrl = imageUrl,
            });
        end);

    elseif action == "getSceneContext" then
        -- JS requests scene text context
        local context = self:GetSceneTextContext();
        self:SendToJS("getSceneContext_response", {
            requestId = msgdata.requestId,
            context = context,
        });

    elseif action == "executeToolCall" then
        -- JS requests tool execution on Lua side
        local toolName = msgdata.toolName;
        local params = msgdata.params or {};
        self:ExecuteToolCall(toolName, params, function(result)
            self:SendToJS("executeToolCall_response", {
                requestId = msgdata.requestId,
                toolName = toolName,
                result = result,
            });
        end);

    elseif action == "registerTool" then
        -- JS registers a tool definition (tool execution stays on JS side)
        -- The tool handler will forward execution back to JS
        local toolName = msgdata.toolName;
        local schema = msgdata.schema;
        if toolName and schema then
            self:RegisterTool(toolName, schema, function(params, callback)
                -- Forward tool execution request to JS
                local jsRequestId = tostring(os.time()) .. "_" .. tostring(math.random(10000, 99999));
                -- Store callback for when JS responds
                self._pendingJSToolCallbacks = self._pendingJSToolCallbacks or {};
                self._pendingJSToolCallbacks[jsRequestId] = callback;
                self:SendToJS("executeToolOnJS", {
                    requestId = jsRequestId,
                    toolName = toolName,
                    params = params,
                });
            end);
            self:SendToJS("registerTool_response", {
                requestId = msgdata.requestId,
                success = true,
                toolName = toolName,
            });
        end

    elseif action == "executeToolOnJS_response" then
        -- JS responds with tool execution result
        local reqId = msgdata.requestId;
        if self._pendingJSToolCallbacks and self._pendingJSToolCallbacks[reqId] then
            local callback = self._pendingJSToolCallbacks[reqId];
            self._pendingJSToolCallbacks[reqId] = nil;
            if callback then
                callback(msgdata.result or {
                    success = false,
                    llm_result = "Tool execution failed on JS side",
                });
            end
        end

    elseif action == "unregisterTool" then
        -- JS unregisters a tool
        local toolName = msgdata.toolName;
        if toolName then
            self:UnregisterTool(toolName);
            self:SendToJS("unregisterTool_response", {
                requestId = msgdata.requestId,
                success = true,
                toolName = toolName,
            });
        end

    elseif action == "play" then
        self:Play();
        self:SendToJS("play_response", {
            requestId = msgdata.requestId,
            state = self:GetPlaybackState(),
        });

    elseif action == "pause" then
        self:Pause();
        self:SendToJS("pause_response", {
            requestId = msgdata.requestId,
            state = self:GetPlaybackState(),
        });

    elseif action == "stop" then
        self:Stop();
        self:SendToJS("stop_response", {
            requestId = msgdata.requestId,
            state = self:GetPlaybackState(),
        });

    elseif action == "step" then
        self:Step(function(result)
            self:SendToJS("step_response", {
                requestId = msgdata.requestId,
                result = result,
            });
        end);

    elseif action == "setUserProfile" then
        local config = msgdata.config or {};
        self:SetUserProfile(config);
        self:SendToJS("setUserProfile_response", {
            requestId = msgdata.requestId,
            success = true,
        });

    elseif action == "getUserProfile" then
        self:SendToJS("getUserProfile_response", {
            requestId = msgdata.requestId,
            profile = self:GetUserProfile(),
        });

    elseif action == "setPrimaryLearningTask" then
        local text = msgdata.text;
        self:SetPrimaryLearningTask(text);
        self:SendToJS("setPrimaryLearningTask_response", {
            requestId = msgdata.requestId,
            success = true,
        });

    elseif action == "getPrimaryLearningTask" then
        self:SendToJS("getPrimaryLearningTask_response", {
            requestId = msgdata.requestId,
            task = self:GetPrimaryLearningTask(),
        });

    elseif action == "getLearningProgress" then
        self:SendToJS("getLearningProgress_response", {
            requestId = msgdata.requestId,
            progress = self:GetLearningProgress(),
        });

    elseif action == "getPlaybackState" then
        self:SendToJS("getPlaybackState_response", {
            requestId = msgdata.requestId,
            state = self:GetPlaybackState(),
        });

    elseif action == "setSystemPrompt" then
        local prompt = msgdata.prompt;
        if prompt then
            self:SetSystemPrompt(prompt);
        end
        self:SendToJS("setSystemPrompt_response", {
            requestId = msgdata.requestId,
            success = true,
        });

    elseif action == "setUpdateInterval" then
        local interval = msgdata.interval;
        if interval then
            self:SetUpdateInterval(interval);
        end
        self:SendToJS("setUpdateInterval_response", {
            requestId = msgdata.requestId,
            success = true,
        });

    elseif action == "setDebugEnabled" then
        local enabled = msgdata.enabled;
        self:SetDebugEnabled(enabled == true);
        self:SendToJS("setDebugEnabled_response", {
            requestId = msgdata.requestId,
            success = true,
        });

    elseif action == "getChatHistory" then
        self:SendToJS("getChatHistory_response", {
            requestId = msgdata.requestId,
            history = self:GetChatMessageHistory(),
        });

    elseif action == "clearChatHistory" then
        self:ClearChatHistory();
        self:SendToJS("clearChatHistory_response", {
            requestId = msgdata.requestId,
            success = true,
        });

    elseif action == "getRegisteredToolNames" then
        local toolNames = {};
        for name, _ in pairs(self.tools) do
            table.insert(toolNames, name);
        end
        self:SendToJS("getRegisteredToolNames_response", {
            requestId = msgdata.requestId,
            toolNames = toolNames,
        });

    elseif action == "abort" then
        -- Abort current LLM request if applicable
        self.isLLMProcessing = false;
        self:SendToJS("abort_response", {
            requestId = msgdata.requestId,
            success = true,
        });

    elseif action == "appendChatLog" then
        -- JS sends chat log entry to be written to Lua file system
        local text = msgdata.text;
        if text and ChatLogUtil then
            ChatLogUtil.AppendToFile(text);
        end

    else
        LOG.std(nil, "warn", "BackgroundAgent", "Unknown JS message type: %s", tostring(action));
        self:SendToJS("error", {
            requestId = msgdata.requestId,
            error = "Unknown action: " .. tostring(action),
        });
    end
end
