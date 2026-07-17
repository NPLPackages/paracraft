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
-- With explicit soul/SOP selection:
--agent:SetPrimaryLearningTask("Learn coding in Paracraft", {soul = "coding", sop = "user-profile"});

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
local SkillManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/SkillManager.lua");
local Soul = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/SoulManager.lua");
local GlobalMemory = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/GlobalMemoryManager.lua");
local CopilotSkill = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotSkill.lua");
local AgentRouter = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/AgentRouter.lua");
local ServiceProvider = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/ServiceProvider.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/SceneTools.lua");
local SceneTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.SceneTools");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/LearningTools.lua");
local LearningTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.LearningTools");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/CodeTools.lua");
local CodeTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.CodeTools");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/AgentTools.lua");
local AgentTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.AgentTools");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/WebTools.lua");
local WebTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.WebTools");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/ToolRegistry.lua");
local ToolRegistry = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.ToolRegistry");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/ToolSandbox.lua");
local ToolSandbox = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.ToolSandbox");
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
    get_scene_context = { mode = "sync", impact = "read", category = "context" },
    query_entities = { mode = "sync", impact = "read", category = "scene_query" },
    list_copilots = { mode = "sync", impact = "read", category = "scene_query" },
    
    send_message_to_copilot = { mode = "sync", impact = "write", category = "copilot_control" },
    test_multiple_choice = { mode = "ui_blocking", impact = "write", category = "learning_test", queueable = true },
    test_words_speaking = { mode = "ui_blocking", impact = "write", category = "learning_test", queueable = true },
    test_words_spelling = { mode = "ui_blocking", impact = "write", category = "learning_test", queueable = true },
    show_learning_content = { mode = "ui_blocking", impact = "write", category = "learning_test", queueable = true },
    speak_text = { mode = "async", impact = "read", category = "audio", canInterrupt = true },

    run_paracraft_copilot_code = { mode = "async", impact = "write", category = "run code", timeout = 30000 },
    run_npl_codeblock_code = { mode = "async", impact = "write", category = "run code", timeout = 30000 },
    run_npl_code = { mode = "async", impact = "write", category = "run code", timeout = 30000 },
    -- File tools (sync, file I/O for memory.md etc.)
    read_file = { mode = "sync", impact = "read", category = "file_io" },
    replace_string_in_file = { mode = "sync", impact = "write", category = "file_io" },
    grep_search = { mode = "sync", impact = "read", category = "file_io" },
    create_file = { mode = "sync", impact = "write", category = "file_io" },
    list_files = { mode = "sync", impact = "read", category = "file_io" },
    -- Agent tools (child agent orchestration)
    runAsyncAgentTask = { mode = "sync", impact = "write", category = "agent" },
    getParentAgentContext = { mode = "sync", impact = "read", category = "agent" },
    -- Web tools (webpage fetching)
    fetch_webpage = { mode = "async", impact = "read", category = "web" },
    
};



--------------------------------------------------------------------------------
-- Fixed file names for profile and learning log (no longer per-skill routing)
--------------------------------------------------------------------------------
local DEFAULT_MEMORY_FILE = "user_profile.md";
local DEFAULT_LEARNING_LOG_FILE = "learning_log.md";

--------------------------------------------------------------------------------
-- Agent workspace paths
--------------------------------------------------------------------------------
local WORKSPACE_BASE_DIR = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/workspace/";

--- Parse user profile from JSON file content.
-- Supports JSON format (primary) with legacy markdown fallback.
-- @param content string - Raw file content
-- @return table|nil - Parsed profile table
local function ParseProfileJSON(content)
    if not content or content == "" then return nil; end
    
    -- Try JSON parse first
    local trimmed = content:match("^%s*(.-)%s*$") or "";
    if trimmed:sub(1, 1) == "{" then
        local data = {};
        if NPL.FromJson(trimmed, data) then
            return data;
        end
    end
    
    -- Legacy markdown fallback: parse "- **Field**: value" lines
    local FIELD_MAP = {
        ["Name"] = "name", ["Age"] = "age", ["Grade"] = "grade",
        ["Interests"] = "interests", ["Specialty"] = "specialty",
        ["Learning Goal"] = "learningGoal", ["Preferred Pace"] = "preferredPace",
        ["Personality"] = "personality", ["English Level"] = "englishLevel",
        ["Coding Level"] = "codingLevel", ["Preferred Project"] = "preferredProject",
        ["Updated"] = "updated",
    };
    local profile = {};
    for line in content:gmatch("[^\r\n]+") do
        local field, value = line:match("^%-%s*%*%*(.-)%*%*:%s*(.+)$");
        if field and value then
            field = field:match("^%s*(.-)%s*$");
            value = value:match("^%s*(.-)%s*$");
            local key = FIELD_MAP[field];
            if key then
                if key == "age" then
                    profile[key] = tonumber(value:match("^(%d+)")) or value;
                else
                    profile[key] = value;
                end
            end
        end
    end
    if not next(profile) then return nil; end
    return profile;
end

--- Format profile data as beautified JSON for writing to file.
-- @param data table - Profile data table
-- @return string - Pretty-printed JSON string
local function FormatProfileJSON(data)
    NPL.load("(gl)script/ide/Json.lua");
    return commonlib.Json.Beautify(data, "  ") or "{}";
end

--- Apply parsed profile fields to agent.userProfile.
-- @param agent table - BackgroundAgent instance
-- @param profile table - Parsed profile data
local function ApplyProfileToAgent(agent, profile)
    if not agent or not agent.userProfile or not profile then return; end
    
    -- Direct copy for simple fields
    local simpleFields = {"name", "grade", "learningGoal", "preferredPace",
        "personality", "englishLevel", "codingLevel", "preferredProject", "specialty"};
    for _, key in ipairs(simpleFields) do
        if profile[key] and profile[key] ~= "" then
            agent.userProfile[key] = profile[key];
        end
    end
    
    -- Number field: age
    if profile.age then
        local numAge = tonumber(profile.age);
        if numAge then agent.userProfile.age = numAge; end
    end
    
    -- Array/CSV field: interests
    if profile.interests then
        if type(profile.interests) == "table" then
            agent.userProfile.interests = profile.interests;
        elseif type(profile.interests) == "string" and profile.interests ~= "" then
            local items = {};
            for item in profile.interests:gmatch("[^,，]+") do
                local trimmed = item:match("^%s*(.-)%s*$");
                if trimmed and trimmed ~= "" then
                    table.insert(items, trimmed);
                end
            end
            agent.userProfile.interests = items;
        end
    end
end

--- Sync profile from file to agent.userProfile.
-- Reads the profile file for the given skill and applies it to the agent's in-memory profile.
-- @param agent table - BackgroundAgent instance
-- @param sopName string - Skill name to resolve memory file
local function SyncProfileFromFile(agent, sopName)
    sopName = sopName or (agent.sopState and agent.sopState.activeSOP) or "user-profile";
    local memoryFile = DEFAULT_MEMORY_FILE;
    local readResult = agent.fileTools:ReadFile(memoryFile);
    if readResult.success and readResult.content and readResult.content ~= "" then
        local profile = ParseProfileJSON(readResult.content) or {};
        ApplyProfileToAgent(agent, profile);
        LOG.std(nil, "info", "BackgroundAgent", "SyncProfileFromFile('%s'): applied name=%s, age=%s",
            sopName, tostring(agent.userProfile.name), tostring(agent.userProfile.age));
    end
end

--- Parse the streamlined learning log format used by eduagent skills.
-- Supports the new structured markdown blocks and returns nil when not found.
-- @param content string
-- @return table|nil
local function ParseStructuredLearningLog(content)
    if not content or content == "" then return nil; end

    local function extractSection(name)
        local pattern = "### " .. name .. "\n(.-)\n### "
        local section = content:match(pattern)
        if not section then
            section = content:match("### " .. name .. "\n(.+)$")
        end
        return section
    end

    local function parseKeyValueSection(section)
        local result = {}
        if not section then return result end
        for line in section:gmatch("[^\r\n]+") do
            local key, value = line:match("^%-%s*([%w_]+):%s*(.+)$")
            if key and value then
                result[key] = value:match("^%s*(.-)%s*$")
            end
        end
        return result
    end

    local currentTopic = parseKeyValueSection(extractSection("Current Topic"))
    local latestResult = parseKeyValueSection(extractSection("Latest Result"))
    local nextStep = parseKeyValueSection(extractSection("Next Step"))

    if not next(currentTopic) and not next(latestResult) and not next(nextStep) then
        return nil
    end

    return {
        type = currentTopic.type,
        item = currentTopic.item,
        action = currentTopic.action,
        status = currentTopic.status,
        result = latestResult.result,
        note = latestResult.note,
        next = nextStep.next,
    }
end

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
    
    -- H5 tool session timeout (seconds) — auto-cancel if user never completes
    toolSessionTimeout = 300, -- 5 minutes
};

--[[
    Get the FileTools instance used by this agent.
    External code and tests should use this to share the same workspace.
    @return FileTools - The FileTools instance
]]
function BackgroundAgent:GetFileTools()
    return self.fileTools;
end

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
    
    -- Per-instance AgentRouter and ToolSandbox (created in RegisterNPLJSHandlers)
    self._agentRouter = nil;
    self._toolSandbox = nil;

    -- Tool registry: shared ToolRegistry instance (decoupled from BackgroundAgent)
    self.toolRegistry = ToolRegistry:new();
    self.tools = self.toolRegistry.tools;  -- backward compat: same table reference
    
    -- Connect ToolRegistry signals to BackgroundAgent for AISession sync
    self.toolRegistry:Connect("toolRegistered", self, self.OnToolRegistered);
    self.toolRegistry:Connect("toolUnregistered", self, self.OnToolUnregistered);
    
    -- Copilot skill module (discovery, tools, prompt generation)
    self.copilotSkill = CopilotSkill:new():Init(self.toolRegistry);
    self.discoveredCopilots = self.copilotSkill.discoveredCopilots;
    
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
        grade = nil,                    -- School grade (e.g., "三年级")
        englishLevel = "beginner",      -- English proficiency: "beginner"/"elementary"/"conversational"
        interests = {},                 -- Array of interest strings (e.g., {"恐龙", "Minecraft"})
        specialty = nil,               -- User's special talent
        learningGoal = nil,            -- Learning objective (e.g., "日常对话"/"考试提分")
        preferredPace = "moderate",    -- Learning pace: "fast"/"moderate"/"slow"
        personality = nil,             -- Observed personality (e.g., "活泼好奇"/"害羞安静")
    };
    
    --------------------------------------------------------------------------------
    -- Agent Phase (simplified: idle / active)
    -- The LLM decides whether to collect profile or teach based on skill definitions
    -- and data completeness. No hardcoded SOP→learning state machine.
    --------------------------------------------------------------------------------
    
    -- Agent phase: "idle" (no task) / "active" (has task, LLM decides behavior)
    self.agentPhase = "idle";
    
    -- Skill state tracking (which skill module is active)
    self.sopState = {
        existingProfile = nil,  -- Parsed data from memory file (nil if first time)
        isActive = false,       -- Whether a session is currently running
        activeSOP = nil,        -- Name of the active skill module (e.g., "user-profile")
    };
    

    
    -- Whether the agent is waiting for user reply (blocks idle-driven prompts)
    self.waitingForUserReply = false;
    self.waitingForUserReplyStartTime = nil; -- timestamp when wait started (for nudge timeout)
    self.isInitialLearningSession = false; -- true during the very first learning message after activation
    
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
    -- Each entry is {query=string, callback=function|nil, options=table|nil}
    self.pendingUserRequests = {};
    
    -- Whether LLM is currently processing a request
    self.isLLMProcessing = false;
    
    -- Watchdog timer: auto-reset isLLMProcessing if LLM callback never fires
    self.llmProcessingWatchdog = nil;
    self.llmProcessingWatchdogTimeout = 90000; -- 90 seconds
    
    -- Tool call detection state for TTS hint
    self.isToolCallInProgress = false;  -- Whether tool call content detected in stream
    self.toolCallHintSpoken = false;    -- Whether "正在查找可用的方法" hint has been spoken
    
    -- Learning session state
    self.isLearningInProgress = false;  -- Whether a learning LLM call is in progress
    
    -- LLM call history for debugging
    self.llmHistory = {};
    self.maxLLMHistorySize = CONFIG.maxLLMHistorySize;
    
    -- Max tool-call chain depth for delegate mode (aligned with AIChat.maxIterations)
    self.maxToolChainDepth = 5;
    
    -- Child agent sessions managed via AIChat child session framework
    -- (orchestrated through self.aiSession's CreateChildSession/EnqueueChildTask)
    
    -- System prompt cache for token optimization
    self.cachedSystemPrompt = nil;
    self.systemPromptCacheKey = nil; -- Hash of task + copilots for cache invalidation

    -- Initialize tool modules (needed by RegisterServices)
    self.fileTools = FileTools:new();
    self.sceneTools = SceneTools:new();
    self.learningTools = LearningTools:new();
    self.codeTools = CodeTools:new();
    self.agentTools = AgentTools:new();
    self.webTools = WebTools:new();
    
    -- Register services for tool handler dependency injection
    self:RegisterServices();
    
    -- Register all tool modules with ToolRegistry
    self.sceneTools:RegisterTools(self.toolRegistry);
    self.copilotSkill:RegisterTools();
    self.learningTools:RegisterTools(self.toolRegistry);
    self.codeTools:RegisterTools(self.toolRegistry);
    self.fileTools:RegisterTools(self.toolRegistry, "file_io");
    self.agentTools:RegisterTools(self.toolRegistry);
    self.webTools:RegisterTools(self.toolRegistry);
    
    -- Share FileTools instance with GlobalMemoryManager
    GlobalMemory.SetFileTools(self.fileTools);
    
    -- Load all SOP modules and register their tools
    self:LoadAndRegisterSOPs();
    
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
    
    -- Initialize voice context manager
    VoiceContextManager:Init();
    
    -- Connect to typewriter signal to update chat history
    self:Connect("typewriterText", self, self.OnTypewriterText);
    
    -- Connect context manager signals
    self:ConnectContextSignals();
    
    -- Register NPLJS handlers for JS ↔ Lua communication
    self:RegisterNPLJSHandlers();

    -- Create a per-instance AgentRouter (one per NPLJS endpoint)
    self._agentRouter = AgentRouter:new();

    -- Update the service provider with the now-available AgentRouter
    if self.serviceProvider then
        self.serviceProvider:Register("agent_router", self._agentRouter);
    end

    -- Attach AgentRouter to the same NPLJS channel so JS-side AgentRouter
    -- can discover and call Lua agents (and vice versa).
    self._agentRouter:attach(npljs_send_event, npljs_recv_event);

    -- Register this BackgroundAgent instance as a named agent.
    -- JS can submit tasks to "backgroundAgent" via agentRouter.submitTask(...).
    local self_ = self;
    self._agentRouter:register("backgroundAgent", function(taskId, payload, streamCb, doneCb)
        local inst = BackgroundAgent:GetInstance();
        if not inst then
            doneCb(nil, "BackgroundAgent instance not available");
            return;
        end
        local query = payload.task or payload.prompt or payload.query or "";
        local options = payload.options or {};
        options.skipChatHistory = options.skipChatHistory;
        inst:ProcessWithLLM(query, function(result)
            doneCb({ result = result and result.response or "" });
        end, options);
    end);

    -- Create a per-instance ToolSandbox and register "paracraft" agent on our router
    self._toolSandbox = ToolSandbox:new();
    self._toolSandbox:Init(self._agentRouter, self.toolRegistry,
        {"scene_query", "file_io", "copilot_control", "audio", "run_code", "learning_test", "agent", "web"},
        self.serviceProvider);
end

--[[
    Connect signals from context managers (SceneVision, Voice, TTS).
    Safe to call multiple times; uses a guard flag to prevent duplicate connections.
]]
function BackgroundAgent:ConnectContextSignals()
    if self._contextSignalsConnected then return; end
    self._contextSignalsConnected = true;
    
    SceneVisionManager:Connect("sceneChanged", self, function(_, changeInfo)
        self:OnSceneChanged(changeInfo);
    end);
    
    SceneVisionManager:Connect("screenshotCaptured", self, function(_, entry)
        self:OnScreenshotCaptured(entry);
    end);
    
    VoiceContextManager:Connect("voiceTranscribed", self, function(_, entry)
        self:OnVoiceTranscribed(entry);
    end);
    
    -- Connect TTSQueueManager signals to BackgroundAgent signals
    -- This maintains backward compatibility for external signal consumers
    self.ttsManager:Connect("ttsStarted", self, function(_, text)
        self:ttsStarted(text);
    end);
    self.ttsManager:Connect("ttsCompleted", self, function()
        self:ttsCompleted();
    end);
    
    LOG.std(nil, "info", "BackgroundAgent", "Context signals connected");
end

--[[
    Disconnect signals from context managers.
    Prevents stale callbacks after Stop() and avoids signal connection leaks.
]]
function BackgroundAgent:DisconnectContextSignals()
    if not self._contextSignalsConnected then return; end
    self._contextSignalsConnected = false;
    
    SceneVisionManager:Disconnect("sceneChanged", self);
    SceneVisionManager:Disconnect("screenshotCaptured", self);
    VoiceContextManager:Disconnect("voiceTranscribed", self);
    self.ttsManager:Disconnect("ttsStarted", self);
    self.ttsManager:Disconnect("ttsCompleted", self);
    
    LOG.std(nil, "info", "BackgroundAgent", "Context signals disconnected");
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
    @param config: table - {age, primaryLanguage, secondaryLanguage, name, grade, englishLevel, interests, specialty, learningGoal, preferredPace, personality}
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
    if config.grade then
        self.userProfile.grade = config.grade;
    end
    if config.englishLevel then
        self.userProfile.englishLevel = config.englishLevel;
    end
    if config.interests then
        if type(config.interests) == "table" then
            self.userProfile.interests = config.interests;
        elseif type(config.interests) == "string" then
            -- Split comma-separated string into array
            self.userProfile.interests = {};
            for item in string.gmatch(config.interests, "[^,]+") do
                local trimmed = string.match(item, "^%s*(.-)%s*$");
                if trimmed and trimmed ~= "" then
                    table.insert(self.userProfile.interests, trimmed);
                end
            end
        end
    end
    if config.specialty then
        self.userProfile.specialty = config.specialty;
    end
    if config.learningGoal then
        self.userProfile.learningGoal = config.learningGoal;
    end
    if config.preferredPace then
        self.userProfile.preferredPace = config.preferredPace;
    end
    if config.personality then
        self.userProfile.personality = config.personality;
    end
    
    LOG.std(nil, "info", "BackgroundAgent", "User profile set: age=%d, primary=%s, secondary=%s, name=%s",
        self.userProfile.age, self.userProfile.primaryLanguage, self.userProfile.secondaryLanguage,
        tostring(self.userProfile.name));
    
    return self;
end

--[[
    Get current user profile
    @return table - User profile
]]
function BackgroundAgent:GetUserProfile()
    return self.userProfile;
end

--------------------------------------------------------------------------------
-- SOP (Standard Operating Procedure) - Dynamic SOP Management
-- Skill modules are discovered from skills/ folder and managed via SkillManager.
-- The active skill name is stored in self.sopState.activeSOP (default: "user-profile").
--------------------------------------------------------------------------------

--[[
    Load all skill modules from the skills/ folder and register their tools.
    Called once during ctor initialization.
]]
function BackgroundAgent:LoadAndRegisterSOPs()
    -- Load agent workspace (config.md, agent.md, soul.md, skills)
    self:SetAgent(self.agentName or "eduagent");
    
    -- Initialize Global Memory Manager (creates temp/global_memory.md if absent)
    GlobalMemory.Init();
    
    local sopNames = SkillManager.GetSkillNames();
    LOG.std(nil, "info", "BackgroundAgent", "Discovered %d skills", #sopNames);
end

--[[
    Set the active agent by name. Loads config.md, agent.md, soul.md, and skills
    from workspace/<agentName>/.
    @param agentName: string - Agent directory name (e.g. "eduagent")
]]
function BackgroundAgent:SetAgent(agentName)
    if not agentName or agentName == "" then
        agentName = "eduagent";
    end
    self.agentName = agentName;
    local agentDir = WORKSPACE_BASE_DIR .. agentName .. "/";
    
    -- 1. Load config.md (YAML frontmatter → self.agentConfig)
    self:LoadAgentConfig(agentDir .. "config.md");
    
    -- 2. Load agent.md (pure system prompt content → self.agentPrompt)
    self:LoadAgentPrompt(agentDir .. "agent.md");
    
    -- 3. Load agent's soul.md
    Soul.LoadFromFile(agentDir .. "soul.md");
    
    -- 4. Load all other souls from built-in and temp directories
    -- (Soul.LoadAll scans soul/ and temp/soul/ — agent soul already registered above
    --  will be preserved since LoadAll resets registry; re-load agent soul after)
    Soul.LoadAll();
    Soul.LoadFromFile(agentDir .. "soul.md");
    
    -- 5. Configure SkillManager to scan agent-specific skills directory
    SkillManager.SetAgentSkillDir(agentDir .. "skills/");
    
    -- 6. Discover all skills (agent → shared → temp)
    SkillManager.DiscoverAll();
    
    -- 7. Activate default soul from config
    local defaultSoul = self.agentConfig and self.agentConfig.defaultSoul;
    if defaultSoul and Soul.IsRegistered(defaultSoul) then
        Soul.SetActive(defaultSoul);
    end
    
    -- 8. Configure workspace from config
    local wsName = self.agentConfig and self.agentConfig.workspace;
    if wsName and wsName ~= "" then
        self:SetWorkspace(wsName, false, agentDir);
    end
    
    -- 9. Invalidate system prompt cache
    self:InvalidateSystemPromptCache();
    
    LOG.std(nil, "info", "BackgroundAgent", "SetAgent('%s'): config=%s, prompt=%d bytes, soul=%s, skills=%d",
        agentName,
        tostring(self.agentConfig and self.agentConfig.name),
        self.agentPrompt and #self.agentPrompt or 0,
        tostring(Soul.GetActiveName()),
        SkillManager.GetCount());
end

--[[
    Load agent configuration from a config.md file (YAML frontmatter).
    Parses: name, defaultSoul, defaultSkill, fallbackSkill.
    @param path: string - File path to config.md
]]
function BackgroundAgent:LoadAgentConfig(path)
    self.agentConfig = nil;
    
    local file = ParaIO.open(path, "r");
    if not file:IsValid() then
        file:close();
        LOG.std(nil, "warn", "BackgroundAgent", "LoadAgentConfig: file not found: %s", path);
        return;
    end
    
    local content = file:GetText(0, -1);
    file:close();
    
    if not content or content == "" then
        LOG.std(nil, "warn", "BackgroundAgent", "LoadAgentConfig: empty file: %s", path);
        return;
    end
    
    -- Parse YAML frontmatter (reuse SkillManager's parser for consistency)
    local frontmatter = content:match("^%-%-%-\r?\n(.-)\r?\n%-%-%-");
    if not frontmatter then
        LOG.std(nil, "warn", "BackgroundAgent", "LoadAgentConfig: no YAML frontmatter in %s", path);
        return;
    end
    
    local config = {};
    local function parseField(key)
        local val = frontmatter:match(key .. ":%s*(.-)%s*\r?\n");
        if not val or val == "" then
            val = frontmatter:match(key .. ":%s*(.-)%s*$");
        end
        if val then val = val:match('^["\'](.+)["\']$') or val; end
        return (val and val ~= "") and val or nil;
    end
    
    config.name = parseField("name");
    config.defaultSoul = parseField("defaultSoul");
    config.defaultSkill = parseField("defaultSkill");
    config.fallbackSkill = parseField("fallbackSkill");
    config.workspace = parseField("workspace");
    
    self.agentConfig = config;
    LOG.std(nil, "info", "BackgroundAgent", "LoadAgentConfig: loaded '%s' (soul=%s, skill=%s)",
        tostring(config.name), tostring(config.defaultSoul), tostring(config.defaultSkill));
end

--[[
    Load agent system prompt content from agent.md.
    The file content is stored as-is and injected verbatim into the LLM system prompt.
    @param path: string - File path to agent.md
]]
function BackgroundAgent:LoadAgentPrompt(path)
    self.agentPrompt = nil;
    
    local file = ParaIO.open(path, "r");
    if not file:IsValid() then
        file:close();
        LOG.std(nil, "warn", "BackgroundAgent", "LoadAgentPrompt: file not found: %s", path);
        return;
    end
    
    local content = file:GetText(0, -1);
    file:close();
    
    if content and content ~= "" then
        -- Trim leading/trailing whitespace
        content = content:match("^%s*(.-)%s*$") or content;
        self.agentPrompt = content;
        LOG.std(nil, "info", "BackgroundAgent", "LoadAgentPrompt: loaded %d bytes from %s", #content, path);
    else
        LOG.std(nil, "warn", "BackgroundAgent", "LoadAgentPrompt: empty file: %s", path);
    end
end

--[[
    Set workspace name for all related components at once.
    This configures FileTools (local and remote), invalidates GlobalMemory cache,
    and notifies the JS side.
    @param wsName: string - Workspace name (e.g. "papa"). If a path is passed, the last segment is used.
    @param isRemote: boolean (optional) - If true, also configure remote mode. Default false (local only).
    @return self for chaining
]]
function BackgroundAgent:SetWorkspace(wsName, isRemote, sourceDir)
    if not wsName or wsName == "" then
        LOG.std(nil, "warn", "BackgroundAgent", "SetWorkspace: empty workspace name, ignored");
        return self;
    end
    
    local name = FileTools.ExtractWorkspaceName(wsName);
    if name == "" then
        LOG.std(nil, "warn", "BackgroundAgent", "SetWorkspace: could not extract name from '%s'", tostring(wsName));
        return self;
    end
    
    -- Store the workspace name on the agent instance
    self.workspaceName = name;
    
    -- 1. Configure FileTools (local mode) with optional sourceDir for overlay
    if self.fileTools then
        self.fileTools:SetWorkSpace(name, isRemote and true or false, sourceDir);
    end
    
    -- 1b. Remote mode with sourceDir: mount local folder on PersonalPageStore
    if isRemote and sourceDir and sourceDir ~= "" then
        NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/PersonalPageStore.lua");
        local PersonalPageStore = commonlib.gettable("MyCompany.Aries.Creator.Game.KeepWork.PersonalPageStore");
        PersonalPageStore:MountLocalFolder(sourceDir);
    end
    
    -- 2. Invalidate GlobalMemory cache (it shares our FileTools by reference,
    --    but cached content may point to old workspace files)
    GlobalMemory.InvalidateCache();
    
    -- 3. Notify JS side so PersonalPageStore/ChatSession can sync workspace
    self:SendToJS("workspaceChanged", {
        workspace = name,
        isRemote = isRemote and true or false,
    });
    
    LOG.std(nil, "info", "BackgroundAgent", "SetWorkspace('%s', remote=%s, source=%s)", name, tostring(isRemote or false), tostring(sourceDir or "none"));
    
    return self;
end

--[[
    Get the current workspace name.
    @return string|nil - Workspace name or nil if not set
]]
function BackgroundAgent:GetWorkspace()
    return self.workspaceName;
end

--[[
    Get the agent name.
    @return string - Current agent name (e.g. "eduagent")
]]
function BackgroundAgent:GetAgentName()
    return self.agentName or "eduagent";
end

--[[
    Get the agent config table.
    @return table|nil - { name, defaultSoul, defaultSkill, fallbackSkill }
]]
function BackgroundAgent:GetAgentConfig()
    return self.agentConfig;
end

--[[
    Hot-load a newly imported skill into a running agent.
    Registers the skill's tools and syncs them to the active AIChat session.
    If the LLM is currently processing, defers the operation and retries after 1 second.
    
    @param skillName: string - Name of the skill (must already be registered in SkillManager)
    @param callback: function(result) - Optional callback: {success=boolean, error=string|nil}
]]
function BackgroundAgent:HotLoadSkill(skillName, callback)
    if not skillName or not SkillManager.IsDiscovered(skillName) then
        LOG.std(nil, "warn", "BackgroundAgent", "HotLoadSkill: skill '%s' not discovered", tostring(skillName));
        if callback then callback({success = false, error = "Skill not discovered: " .. tostring(skillName)}); end
        return;
    end

    -- Defer if LLM is currently processing to avoid tool list mutation mid-request
    if self.isLLMProcessing then
        LOG.std(nil, "info", "BackgroundAgent", "HotLoadSkill: LLM busy, deferring '%s' by 1s", skillName);
        local self_ = self;
        commonlib.TimerManager.SetTimeout(function()
            self_:HotLoadSkill(skillName, callback);
        end, 1000);
        return;
    end

    -- Push updated tool definitions to the active AIChat session
    self:SyncToolsToAISession();

    LOG.std(nil, "info", "BackgroundAgent", "HotLoadSkill: '%s' tools synced", skillName);
    if callback then callback({success = true}); end
end

--[[
    Prepare the session by reading existing data from the skill's memory file.
    Called when SetPrimaryLearningTask is invoked.
    Sets agentPhase to "active". The LLM decides whether to collect profile or teach
    based on the skill definitions and data completeness injected in the system prompt.
    @param sopName: string (optional) - Which skill to activate, defaults to "user-profile"
    @param soulName: string (optional) - Which soul to activate. If nil, uses the skill's defaultSoul.
]]
function BackgroundAgent:PrepareSOPSession(sopName, soulName)
    sopName = sopName or "user-profile";
    
    -- Validate skill exists
    if not SkillManager.IsDiscovered(sopName) then
        LOG.std(nil, "warn", "BackgroundAgent", "Skill '%s' not discovered, entering active phase anyway", sopName);
    end
    
    -- Detect skill switch: clear dialog history and learning progress to prevent cross-skill contamination
    local oldSOP = self.sopState and self.sopState.activeSOP;
    if oldSOP and oldSOP ~= sopName then
        LOG.std(nil, "info", "BackgroundAgent", "Skill switching from '%s' to '%s': clearing dialog history and progress", oldSOP, sopName);
        -- Save old skill's data before clearing (if there's meaningful data)
        if self.primaryTask and self.learningProgress then
            self:SaveLearningDataToMemory();
        end
        -- Clear dialog history to prevent identity confusion
        if self.dialogHistoryManager then
            self.dialogHistoryManager:Clear();
        end
        -- Reset learning progress
        self:ResetLearningProgress();
    end
    
    -- Resolve and activate the appropriate soul
    -- Priority: explicit soulName > agent config defaultSoul > keep current
    local targetSoul = soulName or (self.agentConfig and self.agentConfig.defaultSoul);
    if targetSoul then
        if targetSoul and Soul.IsRegistered(targetSoul) then
            Soul.SetActive(targetSoul);
            LOG.std(nil, "info", "BackgroundAgent", "Skill[%s]: Activated soul '%s'", sopName, targetSoul);
        else
            LOG.std(nil, "warn", "BackgroundAgent", "Skill[%s]: Soul '%s' not registered, keeping current", sopName, targetSoul);
        end
    end
    
    -- Enter active phase — LLM will decide behavior based on data completeness
    self.agentPhase = "active";
    self.waitingForUserReply = false;
    self.sopState.isActive = false;
    self.sopState.existingProfile = nil;
    self.sopState.activeSOP = sopName;
    
    -- Try to read existing data from the skill's memory file and apply to agent
    SyncProfileFromFile(self, sopName);
    
    -- Cache existing profile for system prompt injection
    local memoryFile = DEFAULT_MEMORY_FILE;
    local result = self.fileTools:ReadFile(memoryFile);
    if result.success and result.content and result.content ~= "" then
        local data = ParseProfileJSON(result.content);
        if data and data.name then
            self.sopState.existingProfile = data;
            LOG.std(nil, "info", "BackgroundAgent", "Skill[%s]: Found existing profile for '%s'", sopName, tostring(data.name));
        else
            LOG.std(nil, "info", "BackgroundAgent", "Skill[%s]: %s exists but no valid data found", sopName, memoryFile);
        end
    else
        LOG.std(nil, "info", "BackgroundAgent", "Skill[%s]: No existing %s, LLM will decide to collect profile", sopName, memoryFile);
    end
    
    -- Invalidate system prompt cache
    self:InvalidateSystemPromptCache();
    
    -- Sync all tools (no phase-based filtering)
    self:SyncToolsToAISession();
    
    LOG.std(nil, "info", "BackgroundAgent", "Skill[%s] session prepared (existing=%s)", 
        sopName, tostring(self.sopState.existingProfile ~= nil));
end

--[[
    Set the primary learning task as markdown text.
    Once set, the agent will keep practicing this task until it is explicitly changed
    or completed. The task can be changed at any time by calling this method again.
    
    Completion criteria is evaluated by LLM based on chat history, not structured thresholds.
    
    @param text: string - Markdown text describing the learning task, or nil to clear
    @param options: table (optional) - Configuration for soul/SOP selection:
        options.soul : string  - Soul name to activate (e.g. "papa", "coding")
        options.sop  : string  - SOP name to use (e.g. "user-profile")
        If options.soul is omitted, the SOP's defaultSoul is used (if defined).
        If options.sop is omitted, defaults to "user-profile".
    @return self for chaining
    
    Note: Calling this method will reset learning progress.
    The primary task persists until this method is called again with a new task or nil.
    
    Usage:
        agent:SetPrimaryLearningTask("Learn English words")  -- defaults: sop="user-profile", soul from SOP
        agent:SetPrimaryLearningTask("Learn coding", {soul = "coding"})
        agent:SetPrimaryLearningTask("Learn English", {soul = "papa"})  -- sop defaults to "user-profile"
]]
function BackgroundAgent:SetPrimaryLearningTask(text, options)
    if not text or text == "" then
        local oldTask = self.primaryTask;
        self.primaryTask = nil;
        self.agentPhase = "idle";
        self.waitingForUserReply = false;
        if oldTask then
            LOG.std(nil, "info", "BackgroundAgent", "Primary learning task cleared");
            self:InvalidateSystemPromptCache();
            self:primaryTaskChanged(nil, oldTask);
        end
        return self;
    end
    
    options = options or {};
    local sopName = options.sop or "user-profile";
    local soulName = options.soul; -- may be nil, will be resolved in PrepareSOPSession
    
    -- Generate unique task ID based on content hash
    local taskId = string.format("task_%d_%d", os.time(), #text);
    
    local oldTask = self.primaryTask;
    -- SOP-aware same-task check: same text AND same SOP to prevent cross-SOP data leakage
    local isSameTask = oldTask and oldTask.text == text and oldTask.sopName == sopName;
    
    self.primaryTask = {
        id = taskId,
        text = text,
        createdAt = os.time(),
        sopName = sopName,       -- Track which SOP this task belongs to (for storage routing)
        soulName = soulName,     -- Track which soul was requested (may be nil = use SOP default)
    };
    
    -- Reset progress if this is a different task or different SOP
    if not isSameTask then
        self:ResetLearningProgress();
    end
    
    -- Always enter SOP phase when a learning task is set
    -- Prepare session: resolve soul, read profile, set agentPhase to "active"
    self:PrepareSOPSession(sopName, soulName);
    
    -- Auto-detect if this is an open-ended observation task
    -- Keywords indicating observation-based learning (no explicit item list)
    local isObservationTask = self:IsObservationBasedTask(text);
    self:SetObservationMode(isObservationTask);
    
    LOG.std(nil, "info", "BackgroundAgent", "Primary learning task set (length: %d chars, observation: %s, sop: %s, soul: %s)", 
        #text, tostring(isObservationTask), sopName, tostring(soulName));
    
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
    
    local observationKeywords = {
        "观察", "场景", "行为", "玩的过程", "互动", "探索",
        "observe", "scene", "behavior", "while playing", "interact", "explore",
        "不需要询问", "根据.*行为", "根据.*场景",
    };
    local structuredKeywords = {
        "words to learn", "要学习的单词", "词汇表", "word list",
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

--------------------------------------------------------------------------------
-- Orchestration Prompt System (generic defaults)
-- Domain-specific orchestration is defined in each skill's SKILL.md.
-- The LLM reads skill files on demand via read_file tool.
--------------------------------------------------------------------------------
local DEFAULT_ORCHESTRATION = {
    session_start = [[按当前协议开始一个最小教学步。若领域 level 未知，先补 level；否则按“最近错误项 > 待复习项 > 新内容”选择学习项。直接输出，跳过推理。]],
    step_continue = [[继续当前学习流程。优先处理最近错误项，其次待复习项，最后才引入新内容。一次只推进一个最小教学步。直接回复，跳过推理过程。]],
    result_feedback = [[根据学生刚才的结果做单轮反馈。正确则巩固或进入下一项；错误则留在当前项；跳过则降低难度。直接回复，跳过推理过程。]],
    scene_focus = "objects/characters visible, environment type",
};

local LEGACY_ORCHESTRATION_ALIASES = {
    initial_session_observation = "session_start",
    initial_session_structured = "session_start",
    proactive_observation = "step_continue",
    step_observation = "step_continue",
    step_structured = "step_continue",
    idle_reengagement_observation = "step_continue",
    idle_reengagement_structured = "step_continue",
    gift_box_correct = "result_feedback",
    gift_box_incorrect = "result_feedback",
    gift_box_skipped = "result_feedback",
    gift_box_completed = "result_feedback",
};

--[[
    Normalize an orchestration key to its canonical key.
    @param key: string
    @return string - canonical key, or original key when no alias exists
]]
function BackgroundAgent:GetCanonicalOrchestrationKey(key)
    return LEGACY_ORCHESTRATION_ALIASES[key] or key;
end

--[[
    Get an orchestration prompt by key.
    Returns from DEFAULT_ORCHESTRATION, resolving legacy aliases to canonical keys.
    @param key: string - Prompt key (e.g. "session_start")
    @return string - Prompt text (never nil)
]]
function BackgroundAgent:GetOrchestrationPrompt(key)
    local canonicalKey = self:GetCanonicalOrchestrationKey(key);
    return DEFAULT_ORCHESTRATION[canonicalKey] or "";
end

--[[
    Wrap a student's reply with result-feedback guidance when the agent is
    currently waiting for an answer in active learning mode.
    @param userQuery: string
    @return string
]]
function BackgroundAgent:BuildLearnerReplyPrompt(userQuery)
    if not userQuery or userQuery == "" then
        return userQuery;
    end

    if self.agentPhase == "active" and self.primaryTask and self.waitingForUserReply then
        local guidance = self:GetOrchestrationPrompt("result_feedback");
        if guidance and guidance ~= "" then
            return guidance .. "\n\n[Student Reply]\n" .. userQuery;
        end
    end

    return userQuery;
end

--[[
    Get the scene focus description.
    @return string - Scene focus text
]]
function BackgroundAgent:GetSceneFocus()
    return DEFAULT_ORCHESTRATION.scene_focus or "";
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
    
    -- Use the unified continuation prompt and add scene-aware guidance inline.
    local orchestrationPrompt = self:GetOrchestrationPrompt("step_continue");
    local prompt = string.format(
        "User is active in 3D scene. Recent activity: %s\nUse what you observe in the scene to continue the current topic with one minimal step. If there is no pending mistake or review item, you may introduce one small scene-related next item.\n%s",
        recentChanges,
        orchestrationPrompt
    );
    
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
    
    -- Basic session metrics (detailed progress is in learning_log.md, managed by LLM)
    local sessionMinutes = progress.sessionStartTime and math.floor((os.time() - progress.sessionStartTime) / 60) or 0;
    local accuracy = progress.totalAttempts > 0 and math.floor(progress.totalCorrect / progress.totalAttempts * 100) or 0;
    
    local md = string.format([[## Learning Progress (Session)
- **Session Duration:** %d minutes
- **Test Attempts:** %d (%d%% accuracy)
- **Progress:** %d%%

> Detailed word-level progress is tracked in `learning_log.md`. Use `read_file` to check it.
]], sessionMinutes, progress.totalAttempts, accuracy, progress.learningPercentage or 0);
    
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
    
    -- Task completeness is now evaluated by LLM via learning_log.md
    -- This heuristic serves as a fallback only
    
    -- Fallback heuristic if tracker has no items (e.g., legacy path)
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

-- ─── Child Agent Orchestration (wraps AIChat child session framework) ───

--[[
    Set the max tool-call chain depth for delegate mode.
    @param depth: number
]]
function BackgroundAgent:SetMaxToolChainDepth(depth)
    self.maxToolChainDepth = depth or 5;
    -- Also sync to AIChat's maxIterations for auto mode consistency
    if self.aiSession then
        self.aiSession:SetMaxIterations(depth);
    end
end

--[[
    Create a named child agent session.
    @param name: string - Unique agent name
    @param options: table|nil - {model, systemPrompt, maxIterations, ...}
    @return table|nil - {session=AIChat, queue={}, isRunning=false}
]]
function BackgroundAgent:CreateChildAgent(name, options)
    self:InitAISession();
    local entry = self.aiSession:CreateChildSession(name, options);
    if entry then
        -- Wire child streaming events to BackgroundAgent's notification system
        entry.session.onChildStream = function(event)
            self:_OnChildAgentStream(event);
        end;
    end
    return entry;
end

--[[
    Enqueue a task for a named child agent.
    @param name: string - Child agent name
    @param task: string - Task description/prompt
    @param options: table|nil - {enableTools, maxIterations, systemPrompt, model, callbackMode, debounceSeconds, description, callback}
]]
function BackgroundAgent:EnqueueChildAgentTask(name, task, options)
    self:InitAISession();
    options = options or {};
    
    -- Wrap callback to also notify UI
    local originalCallback = options.callback;
    options.callback = function(result)
        LOG.std(nil, "info", "BackgroundAgent", "Child agent '%s' task completed", name);
        -- Notify JS side about child agent result
        self:SendToJS("childAgentResult", {
            agentName = name,
            result = type(result) == "string" and result:sub(1, 500) or tostring(result),
        });
        if originalCallback then
            originalCallback(result);
        end
    end;
    
    self.aiSession:EnqueueChildTask(name, task, options);
end

--[[
    Handle child agent streaming events (forward to JS UI).
    @param event: table - {agentPath, agentName, taskId, type, content, fullResponse}
    @private
]]
function BackgroundAgent:_OnChildAgentStream(event)
    if not event then return; end
    -- Forward streaming events to JS side for UI display
    self:SendToJS("childAgentStream", {
        agentPath = event.agentPath,
        agentName = event.agentName,
        taskId = event.taskId,
        type = event.type,
        content = type(event.content) == "string" and event.content:sub(1, 1000) or nil,
    });
end

-- ─── Remote History Integration ───

--[[
    Save current conversation to remote history.
    Uses the AIChat's modId/chatId for persistence.
    @param callback: function(err, msg, data)|nil
]]
function BackgroundAgent:SaveRemoteHistory(callback)
    if self.aiSession then
        self.aiSession:SaveRemoteHistory(callback);
    end
end

--[[
    Set remote history identifiers on the AI session.
    @param chatId: string
    @param modId: string
]]
function BackgroundAgent:SetRemoteHistoryIds(chatId, modId)
    self:InitAISession();
    self.aiSession:SetChatId(chatId);
    self.aiSession:SetModId(modId);
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
    
    -- Re-register NPLJS handlers (may have been unregistered by Stop())
    self:RegisterNPLJSHandlers();
    
    -- Re-connect context signals (may have been disconnected by Stop())
    self:ConnectContextSignals();
    
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
        
        -- Auto-start: LLM will decide whether to collect profile or teach
        if self.primaryTask and not self.isLearningInProgress then
            -- Schedule the initial prompt after a short delay to ensure everything is initialized
            commonlib.TimerManager.SetTimeout(function()
                if self.playbackState ~= "playing" or not self.primaryTask or self.isLearningInProgress then
                    return;
                end
                if self.agentPhase == "active" then
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
    Generate a session summary via a lightweight LLM call.
    Called during Stop() to persist episodic memory (session notes).
    Uses an independent AIChat instance to avoid conflicting with the main session.
    @param sopName: string - The active skill name
    @param callback: function(note:string|nil) - Called with the summary note, or nil on failure
]]
function BackgroundAgent:GenerateSessionSummary(sopName, callback)
    -- Preconditions
    if not self.dialogHistoryManager or self.dialogHistoryManager:GetHistoryCount() < 3 then
        LOG.std(nil, "info", "BackgroundAgent", "Session too short for summary (%d messages)", 
            self.dialogHistoryManager and self.dialogHistoryManager:GetHistoryCount() or 0);
        callback(nil);
        return;
    end
    
    -- Collect dialog context
    local dialogContext = self.dialogHistoryManager:GetFormattedContext();
    if not dialogContext or dialogContext == "" then
        callback(nil);
        return;
    end
    
    -- Build progress snapshot
    local progressInfo = "";
    if self.learningProgress then
        local p = self.learningProgress;
        progressInfo = string.format(
            "Progress: %d%%, Attempts: %d, Correct: %d",
            p.learningPercentage or 0, p.totalAttempts or 0, p.totalCorrect or 0
        );
    end
    
    -- Create independent AIChat for summary (non-streaming, no tools)
    local summaryChat = AIChat:new();
    summaryChat:SetStream(false);
    summaryChat:SetAutoHistory(false);
    summaryChat:SetModel("keepwork-flash");
    summaryChat:SetSystemPrompt(
        "You are a teaching session summarizer. "
        .. "Summarize key observations, what worked, what didn't, and action items in 1-3 concise sentences. "
        .. "Focus on teaching insights, student reactions, and areas for improvement. "
        .. "Write in the same language as the dialog. Do NOT include timestamps."
    );
    
    local userMsg = string.format(
        "Summarize this teaching session:\n\n%s\n\n%s",
        dialogContext, progressInfo
    );
    
    -- Timeout protection: if LLM doesn't respond in 5 seconds, give up
    local completed = false;
    local timeoutTimer = commonlib.Timer:new({callbackFunc = function()
        if not completed then
            completed = true;
            LOG.std(nil, "warn", "BackgroundAgent", "Session summary LLM timed out");
            callback(nil);
        end
    end});
    timeoutTimer:Change(5000); -- 5 second timeout
    
    summaryChat:Ask(userMsg, function(response)
        if completed then return; end
        completed = true;
        timeoutTimer:Change(); -- cancel timeout
        
        if response and response ~= "" then
            -- Clean up the response (remove any markdown wrapping)
            local note = response:match("^%s*(.-)%s*$") or response;
            LOG.std(nil, "info", "BackgroundAgent", "Session summary generated (%d bytes)", #note);
            callback(note);
        else
            LOG.std(nil, "warn", "BackgroundAgent", "Session summary LLM returned empty");
            callback(nil);
        end
    end);
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

    -- Cancel scene-change debounce capture timer
    if self.sceneChangeCaptureTimer then
        self.sceneChangeCaptureTimer:Change();
        self.sceneChangeCaptureTimer = nil;
    end
    
    -- Abort any pending AI requests
    if self.aiSession then
        self.aiSession:Abort();
    end
    
    -- Cancel LLM watchdog timer
    self:_CancelLLMWatchdog();
    
    -- Reset gate flags to prevent stuck state on next Play()
    self.isLLMProcessing = false;
    self.isLearningInProgress = false;
    
    -- Save learning data BEFORE clearing sopState so that the correct memory file
    -- (e.g. user_profile.md) is resolved from sopState.activeSOP.
    if self.primaryTask and self.learningProgress then
        self:SaveLearningDataToMemory();
    end
    
    -- Episodic Memory: generate session summary and persist as session note.
    -- Must capture sopName BEFORE sopState is cleared. The summary is async (LLM call)
    -- but we fire-and-forget — Stop() does not wait for it. The 5s timeout in
    -- GenerateSessionSummary ensures the LLM call won't leak.
    local sopNameForSummary = (self.sopState and self.sopState.activeSOP)
        or (self.primaryTask and self.primaryTask.sopName);
    if sopNameForSummary and self.dialogHistoryManager 
            and self.dialogHistoryManager:GetHistoryCount() >= 3 then
        self:GenerateSessionSummary(sopNameForSummary, function(note)
            if note and note ~= "" then
                -- Append session note to learning log file via FileTools
                local logFile = DEFAULT_LEARNING_LOG_FILE;
                local timestamp = os.date("%Y-%m-%d %H:%M");
                local formattedNote = string.format("\n### Session Note [%s]\n%s\n", timestamp, note);
                self.fileTools:AppendToFile(logFile, formattedNote);
            end
        end);
    end
    
    -- Reset SOP / interaction state
    self.agentPhase = "idle";
    self.waitingForUserReply = false;
    if self.sopState then
        self.sopState.isActive = false;
        self.sopState.existingProfile = nil;
        self.sopState.activeSOP = nil;
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
    
    -- Disconnect signals from context managers to prevent leaks
    self:DisconnectContextSignals();
    
    -- Unregister NPLJS handlers
    self:UnregisterNPLJSHandlers();

    -- Destroy ToolSandbox agent (unregisters "paracraft" from our router)
    if self._toolSandbox then
        self._toolSandbox:Destroy();
        self._toolSandbox = nil;
    end

    -- Detach AgentRouter (announces disconnect to JS, cancels pending tasks)
    if self._agentRouter then
        self._agentRouter:detach();
        self._agentRouter = nil;
    end

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
            prompt = self:GetOrchestrationPrompt("step_continue");
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
    
    -- If waiting for user reply (after a question/test), skip idle driving
    -- BUT allow a re-engagement nudge if the student has been silent beyond the idle threshold
    if self.waitingForUserReply then
        if self.agentPhase == "active" and self.waitingForUserReplyStartTime then
            local now = commonlib.TimerManager.GetCurrentTime();
            local waitTime = now - self.waitingForUserReplyStartTime;
            local nudgeThreshold;
            -- P2: age-based threshold (same formula as DriveLearningSessionIfNeeded)
            local userAge = tonumber(self.userProfile and self.userProfile.age) or 8;
            local ageFactor = (userAge <= 6) and 0.5 or (userAge <= 8) and 0.7 or 1.0;
            if self.observationMode.enabled then
                nudgeThreshold = self.observationMode.idlePromptInterval * ageFactor;
            else
                nudgeThreshold = CONFIG.structuredLearningIdleThreshold * ageFactor;
            end
            if waitTime >= nudgeThreshold then
                -- Student hasn't replied for a long time — allow a gentle nudge
                LOG.std(nil, "info", "BackgroundAgent", 
                    "[OnUpdate] Student silent for %ds (threshold %ds), allowing re-engagement nudge",
                    math.floor(waitTime / 1000), math.floor(nudgeThreshold / 1000));
                self.waitingForUserReply = false;
                self.waitingForUserReplyStartTime = nil;
                -- Fall through to DriveLearningSessionIfNeeded below
            else
                return;
            end
        else
            return;
        end
    end
    
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
    
    -- Sweep timed-out H5 tool sessions (P1: timeout protection)
    self:CleanupTimedOutTools();
    
    -- In observation mode, also check for time-based observation trigger
    if self.observationMode.enabled and not self.isLearningInProgress then
        self:CheckTimedObservationTrigger();
    end
end

--[[
    Sweep pendingToolResults for timed-out H5 sessions.
    If a session has been pending longer than CONFIG.toolSessionTimeout,
    auto-cancel it and return a timeout result to the LLM.
]]
function BackgroundAgent:CleanupTimedOutTools()
    local now = os.time();
    local timeout = CONFIG.toolSessionTimeout;
    local timedOut = {};
    
    for sessionId, pending in pairs(self.pendingToolResults) do
        if pending.timestamp and (now - pending.timestamp) >= timeout then
            table.insert(timedOut, sessionId);
        end
    end
    
    for _, sessionId in ipairs(timedOut) do
        local pending = self.pendingToolResults[sessionId];
        LOG.std(nil, "warn", "BackgroundAgent", "H5 tool session timed out after %ds: %s (session: %s)",
            timeout, pending.toolName, sessionId);
        
        -- Remove from pending
        self.pendingToolResults[sessionId] = nil;
        
        -- Clear current UI session if this was the active one
        if self.currentUISession == sessionId then
            LearningToolUI.Close(nil);
            self.currentUISession = nil;
        end
        
        -- Remove from queue if still queued
        for i = #self.uiToolQueue, 1, -1 do
            if self.uiToolQueue[i].sessionId == sessionId then
                table.remove(self.uiToolQueue, i);
            end
        end
        
        -- Return timeout result to LLM callback
        if pending.callback then
            pending.callback({
                success = false,
                llm_result = string.format(
                    "Tool '%s' timed out after %d seconds (user did not complete). Move on to another activity.",
                    pending.toolName, timeout),
            });
        end
    end
    
    -- Process next queued UI if we freed the current session
    if #timedOut > 0 and not self.currentUISession then
        self:ProcessNextUIToolInQueue();
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
    
    -- P2: Use different idle thresholds based on mode + user age
    local idleThreshold;
    local userAge = tonumber(self.userProfile and self.userProfile.age) or 8;
    -- Young children (≤8) get shorter thresholds; older students keep defaults
    local ageFactor = (userAge <= 6) and 0.5 or (userAge <= 8) and 0.7 or 1.0;
    if self.observationMode.enabled then
        idleThreshold = self.observationMode.idlePromptInterval * ageFactor;
    else
        idleThreshold = CONFIG.structuredLearningIdleThreshold * ageFactor;
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
    
    -- Use a single continuation prompt and inline the re-engagement constraint.
    local prompt = self:GetOrchestrationPrompt("step_continue")
        .. " 学生刚刚长时间没有回应。请用1-2句轻量方式重新接上当前学习流程，优先回到最近错误项或待复习项，不开启全新话题。";
    
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
    
    -- Mark as initial session so ProcessWithLLM callback skips waitingForUserReply
    -- This allows the first teaching batch to flow without needing student confirmation
    self.isInitialLearningSession = true;
    
    -- Use a single session-start prompt. Observation mode still affects image/context,
    -- but not the protocol key used to start the session.
    local prompt = self:GetOrchestrationPrompt("session_start");
    
    -- Use pcall-wrapped callback to ensure isLearningInProgress is always reset
    local self_ = self;
    self:ProcessWithLLM(prompt, function(result)
        -- Always reset the flag, even if something goes wrong
        self_.isLearningInProgress = false;
        self_.isInitialLearningSession = false; -- Clear initial session flag
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
        local sceneFocus = self:GetSceneFocus();
        md = md .. string.format([[### Visual Scene
*Screenshot attached.* Focus on: %s
]], sceneFocus);
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
    
    return md;
end

--------------------------------------------------------------------------------
-- Copilot Auto-Discovery (delegated to CopilotSkill)
--------------------------------------------------------------------------------

--[[
    Discover all available copilots and their capabilities.
    Delegates to CopilotSkill module.
    @return table - Discovered copilots with their tools
]]
function BackgroundAgent:DiscoverCopilots()
    local result = self.copilotSkill:DiscoverCopilots();
    self.discoveredCopilots = self.copilotSkill.discoveredCopilots;
    return result;
end

--------------------------------------------------------------------------------
-- Tool Registration and Execution
--------------------------------------------------------------------------------

--[[
    Register a tool with schema and handler
    @param name: string - Tool name (unique identifier)
    @param schema: table - Tool schema {description, parameters}
    @param handler: function(params, callback) - Tool handler
    @param category: string (optional) - Tool category for sandbox ACL (default: "default")
]]
function BackgroundAgent:RegisterTool(name, schema, handler, category)
    self.toolRegistry:RegisterTool(name, schema, handler, category);
    -- AISession sync is now handled by OnToolRegistered signal
end

--[[
    Unregister a tool
    @param name: string - Tool name to remove
]]
function BackgroundAgent:UnregisterTool(name)
    self.toolRegistry:UnregisterTool(name);
    -- AISession sync is now handled by OnToolUnregistered signal
end

--[[
    Get all tool definitions in OpenAI function calling format
    @return table - Array of tool definitions
]]
function BackgroundAgent:GetAllToolDefinitions()
    return self.toolRegistry:GetAllToolDefinitions();
end

--[[
    Execute a tool call by name
    @param toolName: string - The tool to execute
    @param params: table - Parameters for the tool
    @param callback: function(result) - Called with execution result
]]
function BackgroundAgent:ExecuteToolCall(toolName, params, callback)
    self.toolRegistry:ExecuteTool(toolName, params or {}, function(result, err)
        if err then
            result = { success = false, error = err };
        end
        result = result or { success = true };
        if callback then
            callback(result);
        end
        self:toolExecuted(toolName, params, result);
    end, self.serviceProvider);
end

--------------------------------------------------------------------------------
-- Service Provider & Tool-AISession Sync
--------------------------------------------------------------------------------

--[[
    Register all agent-owned services into the ServiceProvider.
    Called once during ctor initialization, before tools are registered.
]]
function BackgroundAgent:RegisterServices()
    self.serviceProvider = ServiceProvider:new();
    local sp = self.serviceProvider;
    sp:Register("tts", self.ttsManager);

    -- Facade: expose only LaunchLearningTool, decoupled from BackgroundAgent internals
    local agent = self;
    sp:Register("learning_ui", {
        LaunchLearningTool = function(_, toolName, params, callback)
            return agent:LaunchLearningTool(toolName, params, callback);
        end,
    });

    -- Facade: expose only child-agent and parent-context APIs
    sp:Register("code_executor", {
        EnqueueChildAgentTask = function(_, name, task, options)
            return agent:EnqueueChildAgentTask(name, task, options);
        end,
        GetParentContext = function(_, count)
            if not agent.aiSession then return nil; end
            return agent.aiSession:GetParentContext(count);
        end,
    });

    -- Facade: expose only scene-context query methods
    sp:Register("scene_context", {
        GetSceneTextContext = function(_)
            return agent:GetSceneTextContext();
        end,
        FormatSceneContextAsMarkdown = function(_, context, hasImage, isFullMode)
            return agent:FormatSceneContextAsMarkdown(context, hasImage, isFullMode);
        end,
        GetContextHistorySummary = function(_)
            return agent:GetContextHistorySummary();
        end,
    });

    sp:Register("agent_router", self._agentRouter); -- AgentRouter for remote agent routing (nil until InitContext)
    sp:Register("file_tools", self.fileTools);
    sp:Register("copilot_manager", CopilotManager);
    sp:Register("dialog_history", self.dialogHistoryManager);
end

--[[
    Signal handler: called when a tool is registered in ToolRegistry.
    Syncs the tool definition to AISession if available.
    @param name: string - Tool name
    @param schema: table - Tool schema
    @param category: string - Tool category
]]
function BackgroundAgent:OnToolRegistered(name, schema, category)
    if not self.aiSession then return; end

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

    local tools = self.aiSession.tools or {};
    for i = #tools, 1, -1 do
        if tools[i]["function"] and tools[i]["function"].name == name then
            table.remove(tools, i);
        end
    end
    table.insert(tools, toolDef);
    self.aiSession:SetTools(tools);

    -- Register callback if not in delegate mode
    local mode = self.aiSession:GetToolCallMode();
    if mode ~= "delegate" then
        self.aiSession:RegisterToolCallback(name, function(args, asyncCallback)
            self:ExecuteToolCall(name, args, function(result)
                if asyncCallback and type(asyncCallback) == "function" then
                    asyncCallback(result and result.llm_result or "done");
                end
            end);
        end);
    end
end

--[[
    Signal handler: called when a tool is unregistered from ToolRegistry.
    Removes the tool definition from AISession if available.
    @param name: string - Tool name
]]
function BackgroundAgent:OnToolUnregistered(name)
    if not self.aiSession then return; end

    if self.aiSession.tool_callbacks then
        self.aiSession.tool_callbacks[name] = nil;
    end
    local tools = self.aiSession.tools or {};
    for i = #tools, 1, -1 do
        if tools[i]["function"] and tools[i]["function"].name == name then
            table.remove(tools, i);
        end
    end
    self.aiSession:SetTools(tools);
end

--[[
    Sync all currently registered tools to AISession.
    Call this once after AISession is created to catch tools registered before the session existed.
]]
function BackgroundAgent:SyncAllToolsToAISession()
    if not self.aiSession then return; end
    local definitions = self.toolRegistry:GetAllToolDefinitions();
    self.aiSession:SetTools(definitions);
    LOG.std(nil, "info", "BackgroundAgent", "Synced %d tool definitions to AISession", #definitions);
end

--------------------------------------------------------------------------------
-- Dynamic Copilot Tools (delegated to CopilotSkill)
--------------------------------------------------------------------------------

--[[
    Get copilot-specific prompt based on registered copilots.
    Delegates to CopilotSkill module.
    @return string - Copilot-specific prompt section
]]
function BackgroundAgent:GetCopilotPromptSection()
    return self.copilotSkill:GetPromptSection();
end

--[[
    Check if any copilots are registered
    @return boolean
]]
function BackgroundAgent:HasCopilots()
    return self.copilotSkill:HasCopilots();
end

--[[
    Dynamically register tools for a newly added copilot.
    Delegates to CopilotSkill module.
    @param copilot: CopilotBase instance
]]
function BackgroundAgent:OnCopilotRegistered(copilot)
    self.copilotSkill:OnCopilotRegistered(copilot);
    self.discoveredCopilots = self.copilotSkill.discoveredCopilots;
end

--[[
    Remove a copilot when it's unregistered.
    Delegates to CopilotSkill module.
    @param name: string - The copilot's id to remove
]]
function BackgroundAgent:OnCopilotUnregistered(name)
    self.copilotSkill:OnCopilotUnregistered(name);
    self.discoveredCopilots = self.copilotSkill.discoveredCopilots;
end

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
    
    -- Normalize subject key
    local subject = pending.params.subject or pending.params.word;
    if subject then
        subject = string.lower(tostring(subject));
    end
    
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
    Called by LearningGiftBoxManager when a gift box learning task completes.
    This bridges the gap between gift box completion and AI continuation:
    the gift box flow uses nil callback (returns immediately to LLM), so when
    the user finishes the minigame, the AI has no pending callback to resume.
    This method explicitly triggers the AI to continue the learning session.
    
    @param toolName: string - Which learning tool was completed
    @param result: table - {success, correct, score, userAnswer, cancelled, skipped}
]]
function BackgroundAgent:OnGiftBoxLearningComplete(toolName, result)
    result = result or {};
    
    LOG.std(nil, "info", "BackgroundAgent", "Gift box learning complete: tool=%s, correct=%s, cancelled=%s",
        tostring(toolName), tostring(result.correct), tostring(result.cancelled or result.skipped));
    
    -- Guard: only continue if agent is playing and in active phase
    if self.playbackState ~= "playing" or self.agentPhase ~= "active" then
        LOG.std(nil, "debug", "BackgroundAgent", "Skipping gift box continuation: state=%s, phase=%s",
            self.playbackState, self.agentPhase);
        return;
    end
    
    -- Guard: don't overlap with active LLM calls
    if self.isLLMProcessing then
        LOG.std(nil, "debug", "BackgroundAgent", "LLM busy, queuing gift box result as user context");
        -- Queue it as a pending context so next LLM call sees it
        local msg = self:_FormatGiftBoxResultMessage(toolName, result);
        table.insert(self.pendingUserRequests, msg);
        return;
    end
    
    -- Reset lastActivityTime to prevent DriveLearningSessionIfNeeded from racing
    self.learningProgress.lastActivityTime = commonlib.TimerManager.GetCurrentTime();
    
    -- Build a continuation prompt based on the result
    local prompt = self:_FormatGiftBoxResultMessage(toolName, result);
    
    -- Short delay so animations/coins finish before AI speaks
    commonlib.TimerManager.SetTimeout(function()
        if self.playbackState ~= "playing" then return; end
        
        self.isLearningInProgress = true;
        self:ProcessWithLLM(prompt, function(llmResult)
            self.isLearningInProgress = false;
            if llmResult and llmResult.success then
                self.learningProgress.lastActivityTime = commonlib.TimerManager.GetCurrentTime();
            end
        end, {includeImage = false, skipChatHistory = false});
    end, 2000); -- 2 second delay for animation/coin effects to finish
end

--[[
    Internal helper: format a gift box result into a prompt message for the LLM.
    @param toolName: string
    @param result: table
    @return string
]]
function BackgroundAgent:_FormatGiftBoxResultMessage(toolName, result)
    local parts = {};
    local feedbackGuidance = self:GetOrchestrationPrompt("result_feedback");

    if feedbackGuidance and feedbackGuidance ~= "" then
        table.insert(parts, feedbackGuidance);
    end
    
    if result.cancelled or result.skipped then
        table.insert(parts, string.format(
            "[System Event] The student closed/skipped the learning activity '%s' without completing it.",
            toolName));
        table.insert(parts, "Acknowledge the skip, reduce difficulty if needed, and continue the same topic with one smaller follow-up step.");
    elseif result.correct == true then
        table.insert(parts, string.format(
            "[System Event] The student completed '%s' correctly!",
            toolName));
        if result.score then
            table.insert(parts, string.format("Score: %d", result.score));
        end
        if result.userAnswer then
            table.insert(parts, string.format("Their answer: %s", tostring(result.userAnswer)));
        end
        table.insert(parts, "Give brief praise, then either reinforce the same item once or move to the next item in the same topic. Do not introduce multiple new items.");
    elseif result.correct == false then
        table.insert(parts, string.format(
            "[System Event] The student attempted '%s' but got it wrong.",
            toolName));
        if result.userAnswer then
            table.insert(parts, string.format("Their answer was: %s", tostring(result.userAnswer)));
        end
        table.insert(parts, "Give one correction or hint, then continue the same item or topic in the next minimal step. Do not switch to new content yet.");
    else
        table.insert(parts, string.format(
            "[System Event] The student completed the learning activity '%s'.",
            toolName));
        table.insert(parts, "Check the current learning log and choose the next minimal step using the priority order: recent mistakes, review items, then new content.");
    end
    
    return table.concat(parts, " ");
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
    self.codeTools:ExecuteCopilotCode(copilotName, code, callback);
end

--[[
    Execute terminal code on the main thread
    @param code: string - Npl blockly code to execute
]]
function BackgroundAgent:ExecuteTerminalCode(code,callback)
    self.codeTools:ExecuteTerminalCode(code, callback);
end

function BackgroundAgent:ExecuteGlobalCode(codeStr, callback)
    self.codeTools:ExecuteGlobalCode(codeStr, callback);
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
    -- Build cache key from task id, agent phase, skill, soul, and profile identity
    local taskId = self.primaryTask and self.primaryTask.id or "none";
    local sopName = (self.sopState and self.sopState.activeSOP) or "none";
    local soulName = (Soul and Soul.GetActiveName and Soul.GetActiveName()) or "none";
    -- Include profile name+age so cache invalidates if profile changes mid-session
    local profileHash = string.format("%s_%s",
        tostring(self.userProfile.name or ""), tostring(self.userProfile.age or ""));
    local agentName = self.agentName or "none";
    local cacheKey = string.format("%s_%s_%s_%s_%s_%s",
        agentName, taskId, self.agentPhase or "idle", sopName, soulName, profileHash);
    
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
    Build a lightweight skill catalog prompt for idle mode.
    Lists all registered skills for the LLM context.
    @return string - Markdown-formatted skill list, or "" if no skills
]]
function BackgroundAgent:BuildSkillCatalogPrompt()
    -- Delegate to SkillManager's XML catalog builder
    return SkillManager.BuildCatalogXML();
end

--[[
    Build L1 session layer: recent session notes for cross-session continuity.
    @param sopName: string - The active skill name
    @return string - Formatted session insights, or "" if none
]]
function BackgroundAgent:BuildL1SessionLayer(sopName)
    if not sopName then return ""; end
    
    -- Read learning log file directly
    local logFile = DEFAULT_LEARNING_LOG_FILE;
    local readResult = self.fileTools:ReadFile(logFile);
    if not readResult.success or not readResult.content or readResult.content == "" then
        return "";
    end
    
    -- Extract the last N session note blocks (### Session Note sections)
    -- Uses string.find loop instead of gmatch to avoid boundary consumption
    -- (gmatch with \n### at both ends skips every other block)
    local notes = {};
    local content = readResult.content;
    local pos = 1;
    while true do
        local hStart, hEnd = content:find("### Session Note[^\n]*\n", pos);
        if not hStart then break; end
        local bodyStart = hEnd + 1;
        local nextH3 = content:find("\n###", bodyStart);
        local bodyEnd = nextH3 or #content;
        local block = content:sub(bodyStart, bodyEnd):match("^(.-)%s*$") or "";
        if block ~= "" then
            table.insert(notes, block);
        end
        pos = nextH3 and (nextH3 + 1) or (#content + 1);
    end
    
    -- Take only the 3 most recent
    local recent = {};
    local startIdx = math.max(1, #notes - 2);
    for i = startIdx, #notes do
        table.insert(recent, notes[i]);
    end
    
    if #recent == 0 then return ""; end
    
    return "\n\n## Recent Session Insights (L1)\n"
        .. "_Cross-session teaching notes, auto-extracted from previous sessions._\n\n"
        .. table.concat(recent, "\n\n---\n\n") .. "\n";
end

--[[
    Build the learning-aware system prompt
    @return string - System prompt with learning context
]]
function BackgroundAgent:BuildLearningSystemPrompt()
    local profile = self.userProfile;
    local task = self.primaryTask;
    local prompt = "";
    
    -- Check if we have a learning task (covers both profile-collection and learning phases)
    if task then
        -- Build learning prompt: Soul → Agent → Profile → Task → Skills → Session
        local sopName = (self.sopState and self.sopState.activeSOP) or "user-profile";
        
        -- [1] Soul identity prompt
        prompt = Soul.GetFullPrompt() or "";
        
        -- [2] Agent prompt (red lines, routing — injected verbatim from agent.md)
        if self.agentPrompt and self.agentPrompt ~= "" then
            prompt = prompt .. "\n\n" .. self.agentPrompt;
        end
        
        -- [3] Student profile summary
        local profileSummary = "";
        if profile then
            local parts = {};
            if profile.name then table.insert(parts, "- **Name**: " .. tostring(profile.name)); end
            if profile.age then table.insert(parts, "- **Age**: " .. tostring(profile.age)); end
            if profile.grade then table.insert(parts, "- **Grade**: " .. tostring(profile.grade)); end
            if profile.interests then
                local val = type(profile.interests) == "table" and table.concat(profile.interests, ", ") or tostring(profile.interests);
                table.insert(parts, "- **Interests**: " .. val);
            end
            if profile.learningGoal then table.insert(parts, "- **Learning Goal**: " .. tostring(profile.learningGoal)); end
            if profile.englishLevel then table.insert(parts, "- **English Level**: " .. tostring(profile.englishLevel)); end
            if profile.codingLevel then table.insert(parts, "- **Coding Level**: " .. tostring(profile.codingLevel)); end
            if #parts > 0 then
                profileSummary = "\n\n## Student Profile\n" .. table.concat(parts, "\n") .. "\n";
            end
        end
        if profileSummary ~= "" then
            prompt = prompt .. profileSummary;
        end
        
        -- [4] Existing profile data (JSON from file, so LLM can check completeness)
        local existingProfileData = self.sopState and self.sopState.existingProfile;
        if type(existingProfileData) == "table" and existingProfileData.name then
            local profileJson = FormatProfileJSON(existingProfileData);
            prompt = prompt .. "\n\n## 当前用户档案数据\n\n";
            prompt = prompt .. "```json\n" .. profileJson .. "\n```\n";
        else
            prompt = prompt .. "\n\n## 当前用户档案数据\n\n当前没有用户档案。\n";
        end
        
        -- [5] Profile/teaching decision policy
        prompt = prompt .. "\n## 📋 档案与教学决策\n\n";
        prompt = prompt .. "请根据上方用户档案数据和技能说明自主判断：\n";
        prompt = prompt .. "- 如果核心字段（name, age）缺失，先通过对话收集用户信息\n";
        prompt = prompt .. "- 如果进入英语或编程教学前缺少对应领域 level，本轮只能补 level，不能开始正式教学\n";
        prompt = prompt .. "- 只有在核心字段和对应领域 level 已知后，才进入正式教学\n";
        prompt = prompt .. "- 教学项选择优先级为：最近错误项 > 待复习项 > 新内容\n";
        prompt = prompt .. "收集到用户信息后，用 `read_file` 读取当前 `user_profile.md`，修改 JSON 后用 `create_file` 写回完整 JSON。\n";
        
        -- [6] Skill catalog (LLM discovers and reads SKILL.md on demand)
        local skillCatalog = self:BuildSkillCatalogPrompt();
        if skillCatalog and skillCatalog ~= "" then
            prompt = prompt .. "\n\n" .. skillCatalog;
        end
        
        -- [7] Current task
        prompt = prompt .. string.format("\n\n## Current Task: Learning\n- **Topic**: %s\n", task.text or "General");
        
        -- [8] Session history (unified metrics + L1 session notes)
        local sessionHistory = self:GetUnifiedSessionHistory(sopName);
        if sessionHistory and sessionHistory ~= "" then
            prompt = prompt .. sessionHistory;
        end
    else
        -- Idle mode: Soul → Agent → Skills → Idle instructions
        prompt = Soul.GetFullPrompt() or "";
        
        -- Inject agent prompt in idle mode too (red lines always apply)
        if self.agentPrompt and self.agentPrompt ~= "" then
            prompt = prompt .. "\n\n" .. self.agentPrompt;
        end
        
        -- Build skill catalog so LLM knows what skills are available to activate
        local skillCatalog = self:BuildSkillCatalogPrompt();
        if skillCatalog and skillCatalog ~= "" then
            prompt = prompt .. "\n\n" .. skillCatalog;
        end
        
        prompt = prompt .. [[

## Current Mode: Idle (待机模式)
You are a helpful assistant in a 3D creative world (Paracraft).
You can chat with the user, help with building/exploring, and activate learning skills when needed.

When idle, keep responses brief (1-2 sentences). 直接回复，跳过推理过程。
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
    
    -- Request queue: if LLM is busy, queue text only and discard the callback.
    -- Reset any caller-side state flags so they don't stay stuck permanently.
    if self.isLLMProcessing then
        table.insert(self.pendingUserRequests, userQuery);
        LOG.std(nil, "debug", "BackgroundAgent", "LLM busy, queued request: %s (queue size: %d)", 
            string.sub(userQuery or "", 1, 50), #self.pendingUserRequests);
        -- Callback is discarded — proactively reset states the caller set before this call
        self.isLearningInProgress = false;
        self.isInitialLearningSession = false;
        self.voiceLLMThrottle.isProcessing = false;
        return;
    end
    
    -- Merge any pending requests (FIFO order); callbacks were already discarded at queue time
    if #self.pendingUserRequests > 0 then
        local parts = {};
        for _, entry in ipairs(self.pendingUserRequests) do
            table.insert(parts, entry);
        end
        table.insert(parts, userQuery);
        userQuery = table.concat(parts, "\n\n");
        self.pendingUserRequests = {};  -- Clear queue
        LOG.std(nil, "debug", "BackgroundAgent", "Merged %d pending requests into current query", #parts - 1);
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
    -- P2-4: L2 Real-time Context Priority Grading
    -- Observation mode always gets full scene context (teacher needs to see what student does)
    local isObservationActive = self.observationMode and self.observationMode.isActive;
    local needsFullScene = isSceneRelated or isObservationActive;
    
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
    
    -- P2-4: Context priority grading
    -- ALWAYS: user_request + dialog_history (included above)
    -- ALWAYS: voice context (part of contextSummary)
    -- CONDITIONAL: scene context + screenshots (only when scene-related or observation mode)
    -- ON-DEMAND: full context history via get_scene_context tool

    -- Add context history summary (recent voice transcriptions — always included)
    -- Scene screenshots in context summary are trimmed for non-scene requests
    local contextSummary = self:GetContextHistorySummary();
    if contextSummary and contextSummary ~= "" then
        fullPrompt = fullPrompt .. contextSummary .. "\n";
    end
    
    -- Add scene context: full mode when scene-related or observation, brief otherwise
    local sceneContext = self:GetSceneTextContext();
    fullPrompt = fullPrompt .. self:FormatSceneContextAsMarkdown(sceneContext, includeImage and needsFullScene, needsFullScene);
    
    -- P2-4: Only inject screenshot images for scene-related or observation requests.
    -- Non-scene requests skip image payload entirely to save tokens.
    local shouldIncludeImage = includeImage and needsFullScene;
    
    -- Learning progress is now in system prompt (BuildLearningSystemPrompt),
    -- no longer duplicated here in user message.
    
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
    
    -- Prepare image data if requested and context is scene-related (P2-4)
    local askOptions = {};
    if shouldIncludeImage then
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
    -- Start watchdog timer to auto-recover if LLM callback never fires
    self:_StartLLMWatchdog();
    
    self:SendToLLM(prompt, options, function(result)
        LOG.std(nil, "debug", "BackgroundAgent", "SendToLLMWithHistoryTracking callback fired: success=%s phase=%s responseLen=%s",
            tostring(result.success), tostring(self.agentPhase), tostring(result.response and #result.response or 0));
        -- Cancel watchdog — callback fired normally
        self:_CancelLLMWatchdog();
        
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
                -- Keep isLLMProcessing = true during retry to prevent race conditions
                self.isLLMProcessing = true;
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
            
            -- E: Tool-call omission detection
            -- If LLM text mentions learning activities but made no tool calls,
            -- log a warning. The next idle cycle will naturally re-engage.
            if self.agentPhase == "active" and not self.isToolCallInProgress then
                local resp = string.lower(result.response or "");
                -- Dynamically check against registered tool names instead of hardcoded strings
                local mentionedTool = false;
                if self.tools then
                    for toolName, _ in pairs(self.tools) do
                        if resp:find(string.lower(toolName), 1, true) then
                            mentionedTool = true;
                            break;
                        end
                    end
                end
                if mentionedTool then
                    LOG.std(nil, "warn", "BackgroundAgent",
                        "[ToolOmission] LLM mentioned a learning tool but made no tool_call. "
                        .. "Response snippet: %s", string.sub(result.response, 1, 120));
                end
            end
            
            -- Active phase: manage dialogue flow
            -- After LLM file tool calls (create_file on user_profile.md), sync profile from file to keep in-memory state fresh
            SyncProfileFromFile(self);
            
            if self.agentPhase == "active" then
                if self.isInitialLearningSession then
                    -- First response: let it flow without blocking for reply
                    LOG.std(nil, "debug", "BackgroundAgent", "Active phase: initial session, NOT blocking for reply");
                else
                    -- Interactive dialogue mode: wait for student reply after every LLM response
                    -- The idle timer (DriveLearningSessionIfNeeded) will gently nudge if student is silent too long
                    self.waitingForUserReply = true;
                    self.waitingForUserReplyStartTime = commonlib.TimerManager.GetCurrentTime();
                    LOG.std(nil, "debug", "BackgroundAgent", "Active phase: dialogue mode, waiting for student reply");
                end
            end
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
    -- Note: isLLMProcessing is kept true by the caller to prevent race conditions
    self.llmRetry.pendingRetry = commonlib.Timer:new({
        callbackFunc = function(timer)
            LOG.std(nil, "info", "BackgroundAgent", "Executing LLM retry attempt");
            self.llmRetry.pendingRetry = nil;
            
            -- Re-send the request (isLLMProcessing is already true)
            self:SendToLLMWithHistoryTracking(prompt, options, callback);
        end
    });
    self.llmRetry.pendingRetry:Change(delay, nil); -- One-shot timer
end

--[[
    Start a watchdog timer for isLLMProcessing.
    If the LLM callback never fires (network timeout, crash, etc.),
    the watchdog resets isLLMProcessing after the configured timeout
    to prevent the agent from being permanently stuck.
]]
function BackgroundAgent:_StartLLMWatchdog()
    self:_CancelLLMWatchdog();
    self.llmProcessingWatchdog = commonlib.Timer:new({
        callbackFunc = function(timer)
            if self.isLLMProcessing then
                LOG.std(nil, "error", "BackgroundAgent", 
                    "LLM processing watchdog triggered after %dms — force resetting isLLMProcessing",
                    self.llmProcessingWatchdogTimeout);
                self.isLLMProcessing = false;
                self.isLearningInProgress = false;
                self.llmProcessingWatchdog = nil;
            end
        end
    });
    self.llmProcessingWatchdog:Change(self.llmProcessingWatchdogTimeout, nil);
end

--[[
    Cancel the LLM processing watchdog timer.
]]
function BackgroundAgent:_CancelLLMWatchdog()
    if self.llmProcessingWatchdog then
        self.llmProcessingWatchdog:Change();
        self.llmProcessingWatchdog = nil;
    end
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
                
                -- Save first-turn text BEFORE entering tool chain.
                -- When LLM outputs tool calls + text in the same turn,
                -- the continuation response may NOT contain the text. We preserve it here.
                llmEntry._firstTurnText = fullResult;
                
                -- Update LLM history entry with tool calls
                llmEntry.toolCalls = toolCallInfo.toolCalls;
                llmEntry.status = "tool_calling";
                
                -- Handle tool calls through recursive chain (supports up to maxToolChainDepth levels)
                local maxToolChainDepth = self.maxToolChainDepth or 5;
                local function continueToolChain(tcInfo, depth)
                    self:HandleToolCallsFromLLM(tcInfo, function(toolResults)
                        if depth == 1 then
                            llmEntry.toolResults = toolResults;
                        end
                        
                        self.aiSession:ContinueWithToolResults(toolResults, function(contResultCode, contDelta, contDeltaThink, contFullResult, contFullThink, contToolCallInfo)
                            if contResultCode then
                                if contToolCallInfo and contToolCallInfo.toolCalls and #contToolCallInfo.toolCalls > 0 then
                                    if depth >= maxToolChainDepth then
                                        LOG.std(nil, "warn", "BackgroundAgent", "Tool call chain exceeded %d levels, force-completing", maxToolChainDepth);
                                        self:_CompleteLLMResponse(llmEntry, startTime, contResultCode, contFullResult, contFullThink, callback);
                                    else
                                        LOG.std(nil, "debug", "BackgroundAgent", "Follow-up tool calls detected (depth %d/%d), continuing chain", depth, maxToolChainDepth);
                                        continueToolChain(contToolCallInfo, depth + 1);
                                    end
                                else
                                    self:_CompleteLLMResponse(llmEntry, startTime, contResultCode, contFullResult, contFullThink, callback);
                                end
                            else
                                local streamOk, streamErr = pcall(function()
                                    self:_HandleLLMStreamingDelta(contDelta, contDeltaThink);
                                end);
                                if not streamOk then
                                    LOG.std(nil, "error", "BackgroundAgent", "Continuation streaming error at depth %d (non-fatal): %s", depth, tostring(streamErr));
                                end
                            end
                        end, options);
                    end);
                end
                continueToolChain(toolCallInfo, 1);
                return;
            end
            
            -- Use shared _CompleteLLMResponse for both direct and tool-chain paths
            self:_CompleteLLMResponse(llmEntry, startTime, resultCode, fullResult, fullThink, callback);
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
            
            -- Try to auto-fix concatenated tool calls (e.g., "tool1tool2tool3" -> ["tool1", "tool2", "tool3"])
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
                
                -- If we found 2+ tools that make up the concatenated name
                if #selectedTools >= 2 then
                    local toolNameList = {};
                    for _, t in ipairs(selectedTools) do table.insert(toolNameList, t.name); end
                    LOG.std(nil, "info", "BackgroundAgent", "Auto-splitting concatenated tool call (%d tools): %s -> [%s]", 
                        #selectedTools, funcName, table.concat(toolNameList, ", "));
                    
                    -- Split concatenated JSON arguments "{...}{...}{...}" into N parts
                    -- Strategy: find all top-level JSON objects by tracking brace depth
                    local splitArgs = {};
                    if argsStr and argsStr ~= "" then
                        local depth = 0;
                        local objStart = nil;
                        for i = 1, #argsStr do
                            local ch = argsStr:sub(i, i);
                            if ch == "{" then
                                if depth == 0 then
                                    objStart = i;
                                end
                                depth = depth + 1;
                            elseif ch == "}" then
                                depth = depth - 1;
                                if depth == 0 and objStart then
                                    table.insert(splitArgs, argsStr:sub(objStart, i));
                                    objStart = nil;
                                end
                            end
                        end
                    end
                    
                    -- Pad or trim splitArgs to match selectedTools count
                    while #splitArgs < #selectedTools do
                        table.insert(splitArgs, "{}");
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
                    
                    -- Expand the concatenated call into N proper tool calls:
                    -- 1. Replace original toolCalls[idx] with the synthetic calls
                    -- 2. Update AIChat history so assistant message has N tool_calls
                    -- 3. Return N individual tool results for ContinueWithToolResults
                    
                    -- Update AIChat pending messages: replace the single concatenated
                    -- tool_call in the assistant message with the N synthetic calls
                    if self.aiSession and self.aiSession.pendingMessages then
                        for _, msg in ipairs(self.aiSession.pendingMessages) do
                            if msg.role == "assistant" and msg.tool_calls then
                                for j, tc in ipairs(msg.tool_calls) do
                                    if tc.id == callId then
                                        -- Remove the concatenated entry and insert synthetics
                                        table.remove(msg.tool_calls, j);
                                        for k = #syntheticCalls, 1, -1 do
                                            table.insert(msg.tool_calls, j, syntheticCalls[k]);
                                        end
                                        break;
                                    end
                                end
                            end
                        end
                    end
                    -- Also update AIChat.history
                    if self.aiSession and self.aiSession.history then
                        for _, msg in ipairs(self.aiSession.history) do
                            if msg.role == "assistant" and msg.tool_calls then
                                for j, tc in ipairs(msg.tool_calls) do
                                    if tc.id == callId then
                                        table.remove(msg.tool_calls, j);
                                        for k = #syntheticCalls, 1, -1 do
                                            table.insert(msg.tool_calls, j, syntheticCalls[k]);
                                        end
                                        break;
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Execute the split tool calls and return N individual results
                    self:ExecuteToolsByStrategy(syntheticCalls, function(splitResults)
                        -- Register each split result individually (not combined)
                        for _, result in ipairs(splitResults) do
                            toolResults[result.tool_call_id] = result;
                            table.insert(toolOrder, result.tool_call_id);
                        end
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
            
            local toolCompleted = false;  -- Guard against double completion
            local function onToolComplete(result)
                if toolCompleted then
                    LOG.std(nil, "warn", "BackgroundAgent", "Tool %s (call %s) completed more than once, ignoring duplicate", funcName, callId);
                    return;
                end
                toolCompleted = true;
                completedCount = completedCount + 1;
                
                -- Cancel timeout timer if set
                if toolTimeoutTimers and toolTimeoutTimers[callId] then
                    toolTimeoutTimers[callId]:Change(nil, nil);
                    toolTimeoutTimers[callId] = nil;
                end
                
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
            
            -- Set up timeout enforcement if strategy defines a timeout
            local timeoutMs = strategy.timeout;
            if not timeoutMs then
                -- Default timeouts by mode
                if strategy.mode == "ui_blocking" then
                    timeoutMs = 300000;  -- 5 minutes for UI blocking tools
                elseif strategy.mode == "async" then
                    timeoutMs = 60000;   -- 60 seconds for async tools
                end
            end
            if timeoutMs and timeoutMs > 0 then
                local toolTimeoutTimers = self._toolTimeoutTimers;
                if not toolTimeoutTimers then
                    toolTimeoutTimers = {};
                    self._toolTimeoutTimers = toolTimeoutTimers;
                end
                toolTimeoutTimers[callId] = commonlib.Timer:new({
                    callbackFunc = function(timer)
                        timer:Change(nil, nil);
                        if not toolCompleted then
                            LOG.std(nil, "error", "BackgroundAgent", "Tool %s (call %s) timed out after %dms", funcName, callId, timeoutMs);
                            onToolComplete({success = false, error = string.format("Tool execution timed out after %dms", timeoutMs)});
                        end
                    end
                });
                toolTimeoutTimers[callId]:Change(timeoutMs, nil);  -- One-shot timer
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
                    local callbackInvoked = false;
                    local returned = tool.handler(args, function(result)
                        callbackInvoked = true;
                        onToolComplete(result);
                    end);
                    -- If handler returned a value AND callback was not yet invoked, use returned value
                    if returned ~= nil and not callbackInvoked then
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
                        -- Sync tool did not call callback synchronously - complete with error
                        LOG.std(nil, "error", "BackgroundAgent", "Sync tool %s did not call callback synchronously, completing with error", funcName);
                        onToolComplete({success = false, error = string.format("Sync tool '%s' did not return a result synchronously", funcName)});
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
    LOG.std(nil, "debug", "BackgroundAgent", "_CompleteLLMResponse: code=%s responseLen=%s", 
        tostring(resultCode), tostring(fullResult and #fullResult or 0));
    
    -- Wrap pre-callback work in pcall to ensure callback always fires
    local prepOk, prepErr = pcall(function()
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
    end);
    if not prepOk then
        LOG.std(nil, "error", "BackgroundAgent", "_CompleteLLMResponse: pre-callback error: %s", tostring(prepErr));
    end
    
    -- Build result (always, even if prep failed)
    local result = {
        success = resultCode == 200,
        code = resultCode,
        response = fullResult,
        thinking = fullThink,
        markdown = fullResult,
    };
    
    -- Update LLM history entry (safe)
    pcall(function()
        llmEntry.output = {
            response = fullResult,
            thinking = fullThink,
            code = resultCode,
        };
        llmEntry.status = resultCode == 200 and "success" or "error";
        self:DebugLog("LLM_OUTPUT", "code=%s response=%s", tostring(resultCode), fullResult or "");
    end);
    
    -- Call callback (wrapped in pcall so llmResponseReceived always fires)
    if callback then
        local cbOk, cbErr = pcall(callback, result);
        if not cbOk then
            LOG.std(nil, "error", "BackgroundAgent", "_CompleteLLMResponse: callback error: %s", tostring(cbErr));
        end
    end
    
    -- Sync profile from file after each LLM response (in case LLM updated user_profile.md via file tools)
    if result.success then
        SyncProfileFromFile(self);
    end
    
    pcall(function() self:llmResponseReceived(result); end);
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
    Fix A helper: Read previous learning history from file and build a concise summary
    for injection into the system prompt (hot-start).
    This ensures the LLM knows what was taught in prior sessions WITHOUT calling
    read_file("learning_log.md") first, eliminating the "cold start" problem.
    
    Only called during system prompt build, so it runs once and is cached.
    
    @param sopName string - The active SOP name
    @return string - Markdown summary of previous sessions, or "" if no history
]]
function BackgroundAgent:GetPreviousSessionSummary(sopName)
    local learningLogFile = DEFAULT_LEARNING_LOG_FILE;
    local readResult = self.fileTools:ReadFile(learningLogFile);
    if not readResult.success or not readResult.content or readResult.content == "" then
        return "";
    end
    
    local content = readResult.content;
    
    -- Extract key metrics from the file for a concise summary
    -- (The full file may be large; we only inject critical info into the system prompt)
    local summary = "\n## Previous Session History (Auto-loaded)\n";
    summary = summary .. "_Full details available via `read_file(\"" .. learningLogFile .. "\")` tool._\n\n";
    
    -- Extract mastered items (lines with ✅)
    local masteredItems = {};
    for line in content:gmatch("[^\n]+") do
        if line:find("✅") then
            -- Parse word from table row: | word | ... | ✅ Mastered | ... |
            local word = line:match("^|%s*([^|]+)%s*|");
            if word then
                word = word:match("^%s*(.-)%s*$");  -- trim
                if word and word ~= "" and word ~= "Word" then
                    table.insert(masteredItems, word);
                end
            end
        end
    end
    
    -- Extract concepts taught
    local conceptsSection = content:match("### Concepts Taught\n(.-)\n###");
    if not conceptsSection then
        conceptsSection = content:match("### Concepts Taught\n(.+)$");
    end
    local concepts = {};
    if conceptsSection then
        for concept in conceptsSection:gmatch("%- ([^\n]+)") do
            table.insert(concepts, concept);
        end
    end
    
    -- Extract last session date
    local lastUpdated = content:match("Last Updated[^:]*:%s*([^\n]+)");
    
    -- Extract accuracy
    local accuracy = content:match("Accuracy[^:]*:%s*([^\n]+)");
    
    -- Build concise summary
    if lastUpdated then
        summary = summary .. string.format("- **Last Session**: %s\n", lastUpdated);
    end
    if accuracy then
        summary = summary .. string.format("- **Previous Accuracy**: %s\n", accuracy);
    end
    if #masteredItems > 0 then
        summary = summary .. string.format("- **Mastered Items** (%d): %s\n", 
            #masteredItems, table.concat(masteredItems, ", "));
        summary = summary .. "  > **Do NOT re-teach these.** Move to new content.\n";
    end
    if #concepts > 0 then
        -- Show up to 15 concepts to keep prompt concise
        local displayConcepts = {};
        local maxDisplay = math.min(#concepts, 15);
        for i = 1, maxDisplay do
            table.insert(displayConcepts, concepts[i]);
        end
        summary = summary .. string.format("- **Concepts Previously Taught** (%d): %s\n",
            #concepts, table.concat(displayConcepts, ", "));
        if #concepts > maxDisplay then
            summary = summary .. string.format("  > ...and %d more. Use `read_file(\"%s\")` for full list.\n",
                #concepts - maxDisplay, learningLogFile);
        end
    end
    
    -- If nothing meaningful was extracted, return empty
    if #masteredItems == 0 and #concepts == 0 and not lastUpdated then
        return "";
    end
    
    summary = summary .. "\n**CRITICAL**: Do NOT re-teach mastered items. Start with NEW content or review items that need practice.\n";
    
    return summary;
end

--[[
    Build a summary of the current (in-memory) session's learning progress.
    Now also auto-saved to learning_log.md via LLM file tools,
    so read_file("learning_log.md") always has up-to-date data.
    
    @return string - Markdown section for current session, or "" if no data
]]
function BackgroundAgent:GetCurrentSessionSummaryForTool()
    local progress = self.learningProgress;
    if not progress then return ""; end
    
    -- Check if there's any meaningful current session data
    local hasItems = false;
    for _ in pairs(progress.itemsLearned or {}) do hasItems = true; break; end
    local hasConcepts = false;
    if progress.observationStats and progress.observationStats.conceptsTaught then
        for _ in pairs(progress.observationStats.conceptsTaught) do hasConcepts = true; break; end
    end
    if not hasItems and not hasConcepts and (progress.totalAttempts or 0) == 0 then
        return "";
    end
    
    local md = "---\n## Current Session (Live, Not Yet Saved to File)\n";
    md = md .. string.format("- **Progress**: %d%%\n", progress.learningPercentage or 0);
    md = md .. string.format("- **Attempts**: %d\n", progress.totalAttempts or 0);
    if (progress.totalAttempts or 0) > 0 then
        local acc = math.floor((progress.totalCorrect or 0) / progress.totalAttempts * 100);
        md = md .. string.format("- **Accuracy**: %d%%\n", acc);
    end
    
    -- Current session items
    if hasItems then
        md = md .. "\n### Items This Session\n";
        for itemKey, itemData in pairs(progress.itemsLearned) do
            local attempts = itemData.attempts or 0;
            local correct = itemData.correct or 0;
            local status = (attempts >= 2 and correct / attempts >= 0.8) and "✅" or "🔄";
            md = md .. string.format("- %s %s (%d/%d correct)\n", status, itemKey, correct, attempts);
        end
    end
    
    -- Current session concepts (observation mode)
    if hasConcepts then
        md = md .. "\n### Concepts This Session\n";
        for concept, data in pairs(progress.observationStats.conceptsTaught) do
            md = md .. string.format("- %s (x%d)\n", concept, data.count or 1);
        end
    end
    
    return md;
end

--[[
    Unified session history: merges L1 session notes, previous session metrics,
    and current session progress from a single read of learning_log.md.
    Replaces the separate BuildL1SessionLayer + GetPreviousSessionSummary + GetLearningProgressSummary calls.
    @param sopName: string - The active skill name
    @return string - Formatted session history section, or ""
]]
function BackgroundAgent:GetUnifiedSessionHistory(sopName)
    if not sopName then return ""; end

    -- Read learning log file once (instead of twice in the old separate functions)
    local logFile = DEFAULT_LEARNING_LOG_FILE;
    local readResult = self.fileTools:ReadFile(logFile);

    local sections = {};
    local hasMasteredItems = false;

    -- Section header
    table.insert(sections, "\n## Session History");
    table.insert(sections, string.format("_Full details: `read_file(\"%s\")`_\n", logFile));

    -- Part 1: Current session metrics (from in-memory learningProgress)
    if self.primaryTask then
        local progress = self.learningProgress;
        local sessionMinutes = progress.sessionStartTime and math.floor((os.time() - progress.sessionStartTime) / 60) or 0;
        local accuracy = progress.totalAttempts > 0 and math.floor(progress.totalCorrect / progress.totalAttempts * 100) or 0;
        table.insert(sections, string.format("- **Current Session**: %d min, %d attempts (%d%% accuracy), %d%% progress",
            sessionMinutes, progress.totalAttempts, accuracy, progress.learningPercentage or 0));
    end

    -- Parts 2 & 3 require file content
    if readResult.success and readResult.content and readResult.content ~= "" then
        local content = readResult.content;
        local structuredLog = ParseStructuredLearningLog(content);

        if structuredLog then
            if structuredLog.item then
                table.insert(sections, string.format("- **Current Item**: %s", structuredLog.item));
            end
            if structuredLog.action or structuredLog.status then
                table.insert(sections, string.format("- **Current State**: action=%s, status=%s",
                    tostring(structuredLog.action or "unknown"), tostring(structuredLog.status or "unknown")));
            end
            if structuredLog.result then
                table.insert(sections, string.format("- **Latest Result**: %s", structuredLog.result));
            end
            if structuredLog.next then
                table.insert(sections, string.format("- **Suggested Next Step**: %s", structuredLog.next));
            end

            if structuredLog.status == "mastered" then
                hasMasteredItems = true;
                if structuredLog.item then
                    table.insert(sections, string.format("- **Mastered Item**: %s", structuredLog.item));
                end
            elseif structuredLog.result == "incorrect" or structuredLog.status == "practicing" then
                table.insert(sections, "- **Priority Guidance**: Continue the current item before introducing new content.");
            end
        end

        -- Part 2: Previous session metrics (parsed from file)
        local lastUpdated = content:match("Last Updated[^:]*:%s*([^\n]+)");
        if lastUpdated then
            table.insert(sections, string.format("- **Last Session**: %s", lastUpdated));
        end
        local fileAccuracy = content:match("Accuracy[^:]*:%s*([^\n]+)");
        if fileAccuracy then
            table.insert(sections, string.format("- **Previous Accuracy**: %s", fileAccuracy));
        end

        -- Mastered items
        local masteredItems = {};
        for line in content:gmatch("[^\n]+") do
            if line:find("\xe2\x9c\x85") then
                local word = line:match("^|%s*([^|]+)%s*|");
                if word then
                    word = word:match("^%s*(.-)%s*$");
                    if word and word ~= "" and word ~= "Word" then
                        table.insert(masteredItems, word);
                    end
                end
            end
        end
        if #masteredItems > 0 then
            hasMasteredItems = true;
            table.insert(sections, string.format("- **Mastered** (%d): %s",
                #masteredItems, table.concat(masteredItems, ", ")));
            table.insert(sections, "  > **Do NOT re-teach these.** Move to new content.");
        end

        -- Concepts taught
        local conceptsSection = content:match("### Concepts Taught\n(.-)\n###");
        if not conceptsSection then
            conceptsSection = content:match("### Concepts Taught\n(.+)$");
        end
        if conceptsSection then
            local concepts = {};
            for concept in conceptsSection:gmatch("%- ([^\n]+)") do
                table.insert(concepts, concept);
            end
            if #concepts > 0 then
                local maxDisplay = math.min(#concepts, 15);
                local displayConcepts = {};
                for i = 1, maxDisplay do table.insert(displayConcepts, concepts[i]); end
                table.insert(sections, string.format("- **Previously Taught** (%d): %s",
                    #concepts, table.concat(displayConcepts, ", ")));
            end
        end

        -- Part 3: Recent session notes (L1 layer)
        -- Uses string.find loop to avoid gmatch boundary consumption bug
        local notes = {};
        local notePos = 1;
        while true do
            local hStart, hEnd = content:find("### Session Note[^\n]*\n", notePos);
            if not hStart then break; end
            local bodyStart = hEnd + 1;
            local nextH3 = content:find("\n###", bodyStart);
            local bodyEnd = nextH3 or #content;
            local block = content:sub(bodyStart, bodyEnd):match("^(.-)%s*$") or "";
            if block ~= "" then
                table.insert(notes, block);
            end
            notePos = nextH3 and (nextH3 + 1) or (#content + 1);
        end
        if #notes > 0 then
            local recent = {};
            local startIdx = math.max(1, #notes - 2);
            for i = startIdx, #notes do table.insert(recent, notes[i]); end
            table.insert(sections, "\n### Recent Teaching Notes");
            table.insert(sections, table.concat(recent, "\n---\n"));
        end
    end

    -- If only header with no meaningful content, return empty
    if #sections <= 2 and not self.primaryTask then
        return "";
    end

    if hasMasteredItems then
        table.insert(sections, "\n**CRITICAL**: Do NOT re-teach mastered items. Start with NEW content or review items that need practice.");
    end

    return table.concat(sections, "\n");
end

--[[
    Get the storage key for learning data
    @return string - Unique key for this agent's learning data
]]
function BackgroundAgent:GetLearningStorageKey()
    local taskId = self.primaryTask and self.primaryTask.id or "default";
    -- Namespace by SOP to prevent cross-SOP storage key collisions
    -- (e.g. same task text used for both English and Coding SOPs)
    local sopName = self.primaryTask and self.primaryTask.sopName
        or (self.sopState and self.sopState.activeSOP)
        or "user-profile";
    return string.format("BackgroundAgent_Learning_%s_%s", sopName, taskId);
end

--[[
    Save learning data (progress, words, stats) to a dedicated learning log file.
    Profile data lives in its own separate file (managed by SOP onComplete handler).
    Split-file architecture eliminates fragile "preserve profile section" logic.
    
    File format (learning log only):
      ## Learning History   (items learned, accuracy, mastery)
      ### Words Learned     (structured mode table)
      ### Concepts Taught   (observation mode list)
      ### Topics Discussed
      ### Summary
]]
function BackgroundAgent:SaveLearningDataToMemory()
    local progress = self.learningProgress;
    if not progress then return; end
    
    -- Only save if there's meaningful data
    if (progress.totalAttempts or 0) == 0 then
        return; -- nothing to save
    end
    
    -- Guard: do not write if agent is stopped and SOP context is cleared
    if self.playbackState == "stopped" and (not self.sopState or not self.sopState.activeSOP) then
        if not (self.primaryTask and self.primaryTask.sopName) then
            LOG.std(nil, "warn", "BackgroundAgent", "SaveLearningDataToMemory: skipped (agent stopped, no SOP context)");
            return;
        end
    end
    
    -- Resolve SOP name
    local sopName = (self.sopState and self.sopState.activeSOP)
        or (self.primaryTask and self.primaryTask.sopName)
        or "user-profile";
    
    local learningLogFile = DEFAULT_LEARNING_LOG_FILE;
    
    -- LLM now manages learning_log.md directly via file tools.
    -- Lua side only writes if the file doesn't exist yet (bootstrap) or
    -- appends a session checkpoint section at the end.
    local existingContent = self.fileTools:ReadFile(learningLogFile);
    
    if existingContent.success and existingContent.content and existingContent.content ~= "" then
        -- File exists — LLM is managing it. Only log a checkpoint marker.
        LOG.std(nil, "info", "BackgroundAgent", "learning_log.md exists, skipping Lua-side overwrite (LLM manages it)");
    else
        -- File doesn't exist yet — create a minimal template aligned with the new skill protocol
        local topicType = (sopName == "coding-teaching") and "coding" or ((sopName == "english-teaching") and "english" or "unknown");
        local md = string.format([[## Session: %s

### Current Topic
- type: %s
- item: 
- action: teach
- status: new

### Latest Result
- result: 
- note: 

### Next Step
- next: 
]], os.date("%Y-%m-%d"), topicType);
        
        local writeResult = self.fileTools:CreateFile(learningLogFile, md);
        if writeResult.success then
            LOG.std(nil, "info", "BackgroundAgent", "Bootstrap learning_log.md template created: %s", learningLogFile);
        else
            LOG.std(nil, "error", "BackgroundAgent", "Failed to create learning_log.md: %s", tostring(writeResult.error));
        end
    end
end

--[[
    Save learning state to persistent storage (cross-session)
    Saves: primaryTask, learningProgress, dialogHistoryManager state
]]
function BackgroundAgent:SaveLearningState()
    local data = {
        version = 4,
        savedAt = os.time(),
        userProfile = self.userProfile,
        primaryTask = self.primaryTask,
        activeSOP = self.sopState and self.sopState.activeSOP or nil,
        learningProgress = self.learningProgress,
        dialogHistoryState = self.dialogHistoryManager and self.dialogHistoryManager:GetState() or nil,
    };
    
    local key = self:GetLearningStorageKey();
    
    GameLogic.GetPlayerController():SaveLocalUserWorldData(key, data, false, false);
    LOG.std(nil, "info", "BackgroundAgent", "Learning state saved: %s (mastered: %d)", key, self.learningProgress.masteredCount or 0);
    self.sessionState.lastCheckpoint = os.time();
    
    -- Also persist learning data to memory.md for LLM memory
    self:SaveLearningDataToMemory();
end

--[[
    Load learning state from persistent storage
    @param taskId: string (optional) - Specific task ID to load, or uses current task
    @return boolean - True if state was loaded
]]
function BackgroundAgent:LoadLearningState(taskId)
    local key;
    if taskId then
        -- When loading by explicit taskId, include SOP namespace
        local sopName = (self.sopState and self.sopState.activeSOP)
            or (self.primaryTask and self.primaryTask.sopName)
            or "user-profile";
        key = string.format("BackgroundAgent_Learning_%s_%s", sopName, taskId);
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

    -- Restore active SOP and fully re-activate its soul, prompt, and tools
    if self.sopState then
        local loadedSOP = data.activeSOP;
        if loadedSOP and SkillManager.IsDiscovered(loadedSOP) then
            self.sopState.activeSOP = loadedSOP;
            -- Re-activate the paired soul (if one is currently active)
            -- Soul resolution no longer depends on skill config
            self:InvalidateSystemPromptCache();
            -- Tools are now registered centrally, no per-skill RegisterTools needed
        elseif loadedSOP then
            LOG.std(nil, "warn", "BackgroundAgent", "Saved activeSOP '%s' is not discovered, ignoring", tostring(loadedSOP));
        end
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
        -- Use SOP namespace for consistent key format
        local sopName = self.primaryTask and self.primaryTask.sopName
            or (self.sopState and self.sopState.activeSOP)
            or "user-profile";
        key = string.format("BackgroundAgent_Learning_%s_%s", sopName, taskId);
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
    
    -- User spoke: reset waiting flag so agent can respond
    self.waitingForUserReply = false;
    
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
    local userQuery = self:BuildLearnerReplyPrompt(mergedEntry.transcript);
    
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

--[[
    Show the Skill Export/Import dialog.
    Convenience wrapper so the UI can be launched from agent instance.
]]
function BackgroundAgent:ShowSkillExportImport()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/SkillExportImport.lua");
    local SkillExportImport = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.SkillExportImport");
    SkillExportImport:ShowPage();
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
        local wasWaitingForUserReply = self.waitingForUserReply;
        -- User sent a message: reset waiting flag
        self.waitingForUserReply = false;
        -- JS requests LLM processing
        local rawUserQuery = msgdata.query or "";
        local userQuery;
        if wasWaitingForUserReply then
            self.waitingForUserReply = true;
            userQuery = self:BuildLearnerReplyPrompt(rawUserQuery);
            self.waitingForUserReply = false;
        else
            userQuery = rawUserQuery;
        end
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
        local options = {};
        if msgdata.soul then options.soul = msgdata.soul; end
        if msgdata.sop then options.sop = msgdata.sop; end
        self:SetPrimaryLearningTask(text, options);
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

    elseif action == "setWorkspace" then
        local wsName = msgdata.workspace;
        local isRemote = msgdata.isRemote;
        self:SetWorkspace(wsName, isRemote);
        -- Handle remote mount from JS side
        if msgdata.mountFolder and msgdata.mountFolder ~= "" then
            NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/PersonalPageStore.lua");
            local PersonalPageStore = commonlib.gettable("MyCompany.Aries.Creator.Game.KeepWork.PersonalPageStore");
            PersonalPageStore:MountRemoteFolder(msgdata.mountFolder);
        end
        local ws = self.fileTools and self.fileTools:GetWorkSpace() or {};
        self:SendToJS("setWorkspace_response", {
            requestId = msgdata.requestId,
            success = true,
            workspace = self.workspaceName,
            resolvedPath = ws.workspace,
            isRemote = ws.isRemote,
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

    elseif msgdata.is_agent_router then
        -- AgentRouter protocol message from NPLJS WebView side
        if self._agentRouter then
            self._agentRouter:_onMessage(msgdata, "npljs");
        end

    else
        LOG.std(nil, "warn", "BackgroundAgent", "Unknown JS message type: %s", tostring(action));
        self:SendToJS("error", {
            requestId = msgdata.requestId,
            error = "Unknown action: " .. tostring(action),
        });
    end
end
