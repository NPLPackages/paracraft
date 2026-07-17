--[[
Title: AI Chat
Author(s): LiXizhi
Date: 2025/11/24
Desc: wrapping of LLM AI Chat class, support history, system prompt, streaming, images, knowledge base, abort, tool calling, etc.

Use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/AIChat.lua");
local AIChat = commonlib.gettable("MyCompany.Aries.Game.Common.AIChat");

-- Example 1: Basic Usage
local ai = AIChat:new();
ai:SetSystemPrompt("You are a helpful assistant.");
ai:Ask("Hello", function(resultCode, delta, deltaThink, fullResult, fullThink, toolCallInfo, extraData)
    if(resultCode) then
        if(resultCode == 200) then
             LOG.std(nil, "info", "AIChat", "finished: %s", fullResult);
        elseif(resultCode == 429) then
             LOG.std(nil, "error", "AIChat", "Quota exceeded");
        else
             LOG.std(nil, "error", "AIChat", "error: %s", fullResult);
        end
    else
        LOG.std(nil, "info", "AIChat", "stream: %s", delta);
    end
end);

-- Example 2: Using Knowledge Base
local ai = AIChat:new();
ai:SetKnowledgeBase("user/knowledge1,user/knowledge2");
ai:SetKnowledgeUsername("user");
ai:Ask("What is in the knowledge base?", function(resultCode, delta, deltaThink, fullResult, fullThink, toolCallInfo, extraData)
    -- handle result
end);

-- Example 3: Using Images
local ai = AIChat:new();
ai:Ask("What is in this image?", function(resultCode, delta, deltaThink, fullResult, fullThink, toolCallInfo, extraData)
    -- handle result
end, {images="http://example.com/image.png"});

-- Example 4: Abort Request
local ai = AIChat:new();
ai:Ask("Long running task", function(...) end);
-- Abort the request
ai:Abort();

-- Example 5: Non-streaming Usage
local ai = AIChat:new();
ai:SetStream(false);
ai:Ask("Hello", function(resultCode, delta, deltaThink, fullResult, fullThink, toolCallInfo, extraData)
    if(resultCode == 200) then
        -- delta is same as fullResult
         LOG.std(nil, "info", "AIChat", "finished: %s", fullResult);
    end
end);

-- Example 6: Tool Calling
local ai = AIChat:new();
-- 1. 定义工具 (OpenAI 格式)
ai:SetTools({
    {
        type = "function",
        ["function"] = {
            name = "set_block",
            description = "在指定坐标放置方块",
            parameters = {
                type = "object",
                properties = {
                    x = {type = "number"},
                    y = {type = "number"},
                    z = {type = "number"},
                    id = {type = "number", description = "方块ID"},
                },
                required = {"x", "y", "z", "id"},
            },
        }
    }
});

-- 2. 注册 Lua 回调
ai:RegisterToolCallback("set_block", function(args)
    -- 执行游戏逻辑
    GameLogic.BlockEngine:SetBlock(args.x, args.y, args.z, args.id);
    return "已成功放置方块";
end);

-- 3. 提问 (AI 会自动决定是否调用工具)
ai:Ask("请在坐标 10, 5, 10 放一个石头(ID 1)", function(resultCode, delta, deltaThink, fullResult, fullThink, toolCallInfo, extraData)
    if resultCode == 200 then
        print("AI 回复:", fullResult) -- "好的，我已经帮你在那里放了石头。"
    end
end);
-- Example 7: Async Tool Calling
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/AIChat.lua");
local AIChat = commonlib.gettable("MyCompany.Aries.Game.Common.AIChat");
local ai = AIChat:new();
ai:SetTools({
    {
        type = "function",
        ["function"] = {
            name = "async_get_project_info",
            description = "获取世界的project信息",
            parameters = {
                type = "object",
                properties = {
                    id = {type = "string", description = "世界id"},
                },
                required = {"id"},
            },
        }
    }
});
ai:RegisterToolCallback("async_get_project_info", function(args, callback)
    local id = args.id
    keepwork.project.get({
        cache_policy = "access plus 10 seconds",
        router_params = {
            id = id,
        }
    },function (err, msg, data)
        if callback and type(callback) == "function" then
            callback(commonlib.serialize_compact(data))
        end
    end)
end);
ai:Ask("获取帕拉卡世界项目数据(id=123123)", function(resultCode, delta, deltaThink, fullResult, fullThink, toolCallInfo, extraData)
    if resultCode == 200 then
        print("AI 最终回复:", fullResult);
    end
end);
-- Example 8: Local Persistence
local ai = AIChat:new();
-- Save chat history to a local file
ai:SaveHistory("temp/chat_history.json");
-- Load chat history from a local file
ai:LoadHistory("temp/chat_history.json");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.ai.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ChatLogUtil.lua");
local AIChat = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.AIChat"));
local ChatLogUtil = commonlib.gettable("MyCompany.Aries.Game.Common.ChatLogUtil");

AIChat.MaxConcurrentRequests = 3;
AIChat.active_requests = {};
-- Global dev log flag for debugging AI chat raw messages
AIChat.bEnableDevLog = false;
-- Maximum length for tool result content (to prevent token overflow)
AIChat.MaxToolResultLength = 4000;
-- Timeout for async tool execution (milliseconds), 0 means no timeout
AIChat.ToolExecutionTimeout = 60000;
-- Enable text compression to save tokens (remove excessive newlines/whitespace)
AIChat.bEnableCompression = true;
-- Fallback model for multimodal (image) requests
AIChat.VisionFallbackModel = "keepwork-flash";
-- Default max iterations for tool-call recursion (prevents runaway loops)
AIChat.DefaultMaxIterations = 10;
-- Tool category registry (class-level, shared across all instances)
-- { [categoryName] = { definitions = {...}, executor = function|nil } }
AIChat.ToolCategories = {};
-- Alias map for enableTools category names (e.g. "MqttTool" -> "mqtt")
AIChat.ToolCategoryAliases = {
    MqttTool = "mqtt",
    PersonalPageTool = "personalPage",
    personal_page = "personalPage",
    ExecuteTool = "execute",
    webFetch = "web",
};

function AIChat:ctor()
    self.history = {};
    self.system_prompt = nil;
    self.model = "keepwork-pro";
    self.reasoning = nil;
    self.auto_history = true;
    self.stream = true;
    self.signal = nil;
    self.knowledgeBaseCodes = nil;
    self.knowledgeUsername = nil;
    self.tools = nil;
    self.tool_callbacks = {};
    self.api_cache_key = nil;
    -- Tool call mode: "auto" (default, AIChat executes tools) or "delegate" (caller handles tool execution)
    self.toolCallMode = "auto";
    -- Pending messages for ContinueWithToolResults (used in delegate mode)
    self.pendingMessages = nil;
    -- Pending options for ContinueWithToolResults
    self.pendingOptions = nil;
    -- maxIterations: max tool-call recursion depth (prevents runaway loops)
    self.maxIterations = AIChat.DefaultMaxIterations;
    self._currentIteration = 0;
    -- enableTools: array of tool category names to auto-merge with self.tools
    self.enableTools = nil;
    -- Remote history persistence fields (aligned with JS ChatSession)
    self.chatId = nil;
    self.modId = nil;
    self.historyId = nil;
    -- Child agent session management
    self.name = nil;
    self.parentSession = nil;
    self._childSessions = {};
    self._pendingChildResults = {};
    self._maxChildSessions = 2;
    self._depth = 0;
    self._maxDepth = 3;
    self._isSending = false;
    self._debounceTimers = {};
    self._lastSendOptions = {};
    -- Callback for child agent streaming events
    self.onChildStream = nil;
end

-- Enable or disable dev log for debugging raw API messages
-- @param bEnabled: boolean
function AIChat.EnableDevLog(bEnabled)
    AIChat.bEnableDevLog = bEnabled;
    ChatLogUtil.SetEnabled(bEnabled);
    LOG.std(nil, "info", "AIChat", "DevLog %s", bEnabled and "enabled" or "disabled");
end

function AIChat.IsDevLogEnabled()
    return AIChat.bEnableDevLog == true;
end

function AIChat.GetRequestModel(model, options)
    local requestModel = (options and options.model) or model;
    if options and options.images and requestModel == "keepwork-pro" then
        LOG.std(nil, "warn", "AIChat", "Model '%s' does not support stable image requests, fallback to '%s'", requestModel, AIChat.VisionFallbackModel);
        requestModel = AIChat.VisionFallbackModel;
    end
    return requestModel;
end

function AIChat.GetRequestReasoning(reasoning, requestModel, options)
    if options and options.reasoning ~= nil then
        return options.reasoning;
    end
    if reasoning ~= nil then
        return reasoning;
    end
    if requestModel == "keepwork-flash" then
        return false;
    end
    return nil;
end

function AIChat.ExtractResponseDebugMetadata(msg, data)
    local targetKeys = {
        "x-gpt-chat-id",
        "x-gpt-model",
        "x-gpt-rest-count",
        "x-gpt-total-count",
        "x-is-downgrade",
    };

    local metadata = {};

    local function setIfValid(key, value)
        if value ~= nil then
            value = tostring(value);
            if value ~= "" then
                metadata[key] = value;
            end
        end
    end

    local function extractFromHeaderString(header)
        if type(header) ~= "string" or header == "" then
            return;
        end
        local lowerHeader = string.lower(header);
        local function escapeLuaPattern(text)
            return (tostring(text):gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"));
        end
        for _, key in ipairs(targetKeys) do
            local keyPattern = escapeLuaPattern(key);
            local value = lowerHeader:match("\n" .. keyPattern .. ":%s*([^\r\n]+)")
                or lowerHeader:match("^" .. keyPattern .. ":%s*([^\r\n]+)");
            setIfValid(key, value);
        end
    end

    local function extractFromHeaderTable(headers)
        if type(headers) ~= "table" then
            return;
        end
        local normalized = {};
        for k, v in pairs(headers) do
            if k then
                normalized[string.lower(tostring(k))] = v;
            end
        end
        for _, key in ipairs(targetKeys) do
            setIfValid(key, normalized[key]);
        end
    end

    local function extractFromDirectTable(tbl)
        if type(tbl) ~= "table" then
            return;
        end
        local normalized = {};
        for k, v in pairs(tbl) do
            if k then
                normalized[string.lower(tostring(k))] = v;
            end
        end
        for _, key in ipairs(targetKeys) do
            setIfValid(key, normalized[key]);
        end
    end

    extractFromHeaderString(type(msg) == "table" and msg.header);
    extractFromHeaderString(type(data) == "table" and data.header);

    extractFromHeaderTable(type(msg) == "table" and msg.headers);
    extractFromHeaderTable(type(data) == "table" and data.headers);

    extractFromDirectTable(msg);
    extractFromDirectTable(data);

    return next(metadata) and metadata or nil;
end

-- Enable or disable text compression for token savings
-- @param bEnabled: boolean
function AIChat.EnableCompression(bEnabled)
    AIChat.bEnableCompression = bEnabled;
    LOG.std(nil, "info", "AIChat", "Text compression %s", bEnabled and "enabled" or "disabled");
end

--[[
    Compress text to save tokens by removing excessive whitespace
    - Replaces multiple consecutive newlines with single newline
    - Replaces multiple spaces with single space
    - Trims leading/trailing whitespace from each line
    - Preserves code blocks (``` ... ```) formatting
    @param text: string - Input text to compress
    @return string - Compressed text
]]
function AIChat.CompressText(text)
    if not text or type(text) ~= "string" or text == "" then
        return text;
    end
    
    -- Extract and preserve code blocks
    local codeBlocks = {};
    local placeholder = "__CODE_BLOCK_%d__";
    local blockIndex = 0;
    
    text = text:gsub("```.-```", function(block)
        blockIndex = blockIndex + 1;
        codeBlocks[blockIndex] = block;
        return string.format(placeholder, blockIndex);
    end);
    
    -- Compress whitespace outside code blocks
    -- 1. Replace multiple newlines (with optional spaces between) with single newline
    text = text:gsub("\n[%s]*\n+", "\n");
    
    -- 2. Replace multiple spaces/tabs with single space
    text = text:gsub("[ \t]+", " ");
    
    -- 3. Remove spaces at start/end of lines
    text = text:gsub("\n ", "\n");
    text = text:gsub(" \n", "\n");
    
    -- 4. Trim overall start/end
    text = text:match("^%s*(.-)%s*$") or text;
    
    -- Restore code blocks
    for i = 1, blockIndex do
        text = text:gsub(string.format(placeholder, i), codeBlocks[i]);
    end
    
    return text;
end

--[[
    Compress all messages in the messages array for LLM request
    @param messages: table - Array of message objects
    @return table - Same array with compressed content
]]
function AIChat.CompressMessages(messages)
    if not AIChat.bEnableCompression or not messages then
        return messages;
    end
    
    for _, msg in ipairs(messages) do
        if msg.content then
            if type(msg.content) == "string" then
                msg.content = AIChat.CompressText(msg.content);
            elseif type(msg.content) == "table" then
                -- Handle multimodal content (text + images)
                for _, part in ipairs(msg.content) do
                    if part.type == "text" and part.text then
                        part.text = AIChat.CompressText(part.text);
                    end
                end
            end
        end
    end
    
    return messages;
end

--[[
    Filter messages to remove non-remote image_url items (aligned with JS _filterMessages).
    Only keeps image_url items with http:// or https:// URLs.
    @param messages: table - Array of message objects
    @return table - Same array with filtered content
]]
function AIChat.FilterMessages(messages)
    if not messages then return messages; end
    
    for _, msg in ipairs(messages) do
        if msg.content and type(msg.content) == "table" then
            local filtered = {};
            for _, item in ipairs(msg.content) do
                if item.type ~= "image_url" then
                    table.insert(filtered, item);
                else
                    local url = item.image_url and (type(item.image_url) == "table" and item.image_url.url or item.image_url);
                    if url and (url:sub(1, 7) == "http://" or url:sub(1, 8) == "https://") then
                        table.insert(filtered, item);
                    end
                end
            end
            msg.content = filtered;
        end
    end
    return messages;
end

-- ─── Tool Category Registry (class-level, aligned with JS CopilotTools) ───

--[[
    Register a named tool category with OpenAI-format definitions.
    @param name: string - Category name (e.g. "mqtt", "fileOps", "web")
    @param definitions: table - Array of OpenAI-format tool definitions
    @param executor: function|nil - Optional executor function(fnName, args, callback)
]]
function AIChat.RegisterToolCategory(name, definitions, executor)
    if not name or not definitions then return; end
    AIChat.ToolCategories[name] = {
        definitions = definitions,
        executor = executor,
    };
    LOG.std(nil, "info", "AIChat", "Registered tool category '%s' with %d tools", name, #definitions);
end

--[[
    Unregister a tool category.
    @param name: string - Category name
]]
function AIChat.UnregisterToolCategory(name)
    AIChat.ToolCategories[name] = nil;
end

--[[
    Resolve category name through aliases.
    @param name: string - Category name or alias
    @return string - Resolved category name
]]
function AIChat.ResolveCategoryName(name)
    return AIChat.ToolCategoryAliases[name] or name;
end

--[[
    Get merged tool definitions from an array of category names.
    @param categoryNames: table - Array of category name strings
    @return table - Merged array of OpenAI-format tool definitions
]]
function AIChat.GetToolDefinitions(categoryNames)
    if not categoryNames then return {}; end
    local result = {};
    local seen = {};
    for _, name in ipairs(categoryNames) do
        local resolved = AIChat.ResolveCategoryName(name);
        if not seen[resolved] then
            seen[resolved] = true;
            local category = AIChat.ToolCategories[resolved];
            if category and category.definitions then
                for _, def in ipairs(category.definitions) do
                    table.insert(result, def);
                end
            end
        end
    end
    return result;
end

-- ─── maxIterations ───

function AIChat:SetMaxIterations(n)
    self.maxIterations = n or AIChat.DefaultMaxIterations;
end

function AIChat:GetMaxIterations()
    return self.maxIterations or AIChat.DefaultMaxIterations;
end

-- ─── enableTools ───

--[[
    Set enabled tool categories. These will be merged with self.tools when sending requests.
    @param categoryNames: table|nil - Array of category name strings, or nil to disable
]]
function AIChat:SetEnabledTools(categoryNames)
    self.enableTools = categoryNames;
end

-- ─── Remote History Persistence (aligned with JS ChatSession) ───

function AIChat:SetChatId(chatId)
    self.chatId = chatId;
end

function AIChat:GetChatId()
    return self.chatId;
end

function AIChat:SetModId(modId)
    self.modId = modId;
end

function AIChat:GetModId()
    return self.modId;
end

--[[
    Upsert chat history to remote server.
    @param payload: table - {chatId, modId, title, messages, ...}
    @param callback: function(err, msg, data)
]]
function AIChat:UpsertChatHistory(payload, callback)
    if not payload then
        if callback then callback(400); end
        return;
    end
    -- Filter messages before saving
    if payload.messages then
        payload.messages = AIChat.FilterMessages(payload.messages);
    end
    keepwork.ai.aiChatHistoryUpsert(payload, function(err, msg, data)
        if err == 200 and data then
            self.historyId = data.id or self.historyId;
        end
        if callback then callback(err, msg, data); end
    end);
end

--[[
    Update existing chat history on remote server.
    @param id: number - History record ID
    @param payload: table - {messages, ...}
    @param callback: function(err, msg, data)
]]
function AIChat:UpdateChatHistory(id, payload, callback)
    if not id or not payload then
        if callback then callback(400); end
        return;
    end
    -- Filter messages before saving
    if payload.messages then
        payload.messages = AIChat.FilterMessages(payload.messages);
    end
    keepwork.ai.aiChatHistoryUpdate({
        router_params = { id = tostring(id) },
        messages = payload.messages,
    }, function(err, msg, data)
        if callback then callback(err, msg, data); end
    end);
end

--[[
    Get chat history from remote server.
    @param modId: string - Module ID
    @param callback: function(err, msg, data)
]]
function AIChat:GetChatHistory(modId, callback)
    if not modId then
        if callback then callback(400); end
        return;
    end
    keepwork.ai.aiChatHistoryGet({
        modId = modId,
    }, function(err, msg, data)
        if callback then callback(err, msg, data); end
    end);
end

--[[
    Convenience method: auto upsert or update remote history based on current state.
    @param callback: function(err, msg, data)|nil
]]
function AIChat:SaveRemoteHistory(callback)
    if not self.chatId or not self.modId then
        if callback then callback(nil); end
        return;
    end
    
    -- Build messages from history
    local messages = {};
    if self.system_prompt then
        table.insert(messages, {role = "system", content = self.system_prompt});
    end
    for _, msg in ipairs(self.history) do
        table.insert(messages, {
            role = msg.role,
            content = msg.content,
            tool_calls = msg.tool_calls,
            tool_call_id = msg.tool_call_id,
        });
    end
    
    if self.historyId then
        self:UpdateChatHistory(self.historyId, { messages = messages }, callback);
    else
        -- Generate title from first user message
        local title = "Chat";
        for _, msg in ipairs(self.history) do
            if msg.role == "user" then
                local content = msg.content;
                if type(content) == "table" then
                    for _, part in ipairs(content) do
                        if part.type == "text" and part.text then
                            content = part.text;
                            break;
                        end
                    end
                end
                if type(content) == "string" then
                    title = content:sub(1, 50);
                end
                break;
            end
        end
        self:UpsertChatHistory({
            chatId = self.chatId,
            modId = self.modId,
            title = title,
            messages = messages,
        }, callback);
    end
end

-- ─── Child Agent Session Management (aligned with JS ChatSession) ───

--[[
    Create a named child session (agent teammate).
    @param name: string - Unique agent name
    @param options: table|nil - {model, systemPrompt, maxIterations, ...}
    @return table - {session=AIChat, queue={}, isRunning=false}
]]
function AIChat:CreateChildSession(name, options)
    if not name then return nil; end
    if self._childSessions[name] then
        return self._childSessions[name];
    end
    
    local childCount = 0;
    for _ in pairs(self._childSessions) do childCount = childCount + 1; end
    if childCount >= self._maxChildSessions then
        LOG.std(nil, "error", "AIChat", "Cannot create child session '%s': max %d reached", name, self._maxChildSessions);
        return nil;
    end
    if self._depth >= self._maxDepth then
        LOG.std(nil, "error", "AIChat", "Cannot create child session '%s': max depth %d reached", name, self._maxDepth);
        return nil;
    end
    
    options = options or {};
    local child = AIChat:new();
    child.name = name;
    child.parentSession = self;
    child.model = options.model or self.model;
    child._depth = self._depth + 1;
    child._maxDepth = self._maxDepth;
    child.onChildStream = function(event)
        self:_BubbleChildStream(event);
    end;
    if options.systemPrompt then
        child:SetSystemPrompt(options.systemPrompt);
    end
    if options.maxIterations then
        child:SetMaxIterations(options.maxIterations);
    end
    
    local entry = { session = child, queue = {}, isRunning = false };
    self._childSessions[name] = entry;
    LOG.std(nil, "info", "AIChat", "Child agent '%s' created (depth %d)", name, child._depth);
    return entry;
end

--[[
    Enqueue a task for a named child agent. Creates the child if needed.
    @param name: string - Child agent name
    @param task: string - Task description/prompt
    @param options: table|nil - {tools, maxIterations, systemPrompt, model, callbackMode, debounceSeconds, description, callback}
    callbackMode: "delay" (default) | "immediate" | "debounce"
]]
function AIChat:EnqueueChildTask(name, task, options)
    options = options or {};
    local entry = self._childSessions[name] or self:CreateChildSession(name, options);
    if not entry then return; end
    
    -- Inherit tools from parent if not provided
    local resolvedTools = options.enableTools or self.enableTools;
    
    -- Queue/merge logic: if busy and queue has pending tasks, merge with last
    if entry.isRunning and #entry.queue > 0 then
        local last = entry.queue[#entry.queue];
        last.task = "Complete these tasks:\n1. " .. last.task .. "\n2. " .. task;
        last.maxIterations = math.max(last.maxIterations or 10, options.maxIterations or 10);
        LOG.std(nil, "info", "AIChat", "Merged task into queue for child '%s'", name);
        return;
    end
    
    local taskObj = {
        id = tostring(math.random(100000, 999999)),
        task = task,
        description = options.description,
        enableTools = resolvedTools,
        maxIterations = options.maxIterations or 10,
        systemPrompt = options.systemPrompt,
        model = options.model,
        callbackMode = options.callbackMode or "delay",
        debounceSeconds = options.debounceSeconds or 5,
        callback = options.callback,
    };
    table.insert(entry.queue, taskObj);
    
    if not entry.isRunning then
        self:_ProcessChildQueue(name);
    end
end

--[[
    Process task queue for a named child agent.
    @param name: string
    @private
]]
function AIChat:_ProcessChildQueue(name)
    local entry = self._childSessions[name];
    if not entry then return; end
    entry.isRunning = true;
    
    local function processNext()
        if #entry.queue == 0 then
            entry.isRunning = false;
            return;
        end
        
        local taskObj = table.remove(entry.queue, 1);
        local child = entry.session;
        
        -- Fresh context per task
        child:ClearHistory();
        
        local sysPrompt = taskObj.systemPrompt or
            string.format("You are agent '%s', a teammate working in parallel with the main agent. Complete the assigned task and return your final answer.", name);
        child:SetSystemPrompt(sysPrompt);
        
        if taskObj.model then
            child:SetModel(taskObj.model);
        end
        if taskObj.maxIterations then
            child:SetMaxIterations(taskObj.maxIterations);
        end
        if taskObj.enableTools then
            child:SetEnabledTools(taskObj.enableTools);
        end
        
        -- Stream child output to parent
        local agentPath = self:_BuildAgentPath(name);
        
        child:Ask(taskObj.task, function(resultCode, delta, deltaThink, fullResult, fullThink, toolCallInfo, extraData)
            if resultCode then
                -- Task completed
                local result = fullResult or "";
                local taskSummary = taskObj.description or (taskObj.task:sub(1, 80) .. (#taskObj.task > 80 and "..." or ""));
                
                table.insert(self._pendingChildResults, {
                    agentName = name,
                    taskId = taskObj.id,
                    taskSummary = taskSummary,
                    result = result,
                });
                LOG.std(nil, "info", "AIChat", "Child '%s' completed task %s", name, taskObj.id);
                
                self:_HandleChildCallback(taskObj.callbackMode, taskObj.debounceSeconds);
                
                if taskObj.callback then
                    taskObj.callback(result);
                end
                
                -- Process next task in queue
                processNext();
            else
                -- Streaming delta — bubble up
                self:_EmitChildStream({
                    agentPath = agentPath,
                    agentName = name,
                    taskId = taskObj.id,
                    type = "message",
                    content = delta,
                    fullResponse = fullResult,
                });
            end
        end);
    end
    
    processNext();
end

--[[
    Build agent path string (e.g. "parent > child > grandchild").
    @param childName: string
    @return string
    @private
]]
function AIChat:_BuildAgentPath(childName)
    local parts = {};
    local s = self;
    while s do
        if s.name then table.insert(parts, 1, s.name); end
        s = s.parentSession;
    end
    table.insert(parts, childName);
    return table.concat(parts, " > ");
end

--[[
    Emit a child stream event.
    @param event: table - {agentPath, agentName, taskId, type, content, fullResponse}
    @private
]]
function AIChat:_EmitChildStream(event)
    if self.onChildStream then
        local ok, err = pcall(self.onChildStream, event);
        if not ok then
            LOG.std(nil, "error", "AIChat", "onChildStream error: %s", tostring(err));
        end
    end
end

--[[
    Bubble a child stream event up from a descendant.
    @param event: table
    @private
]]
function AIChat:_BubbleChildStream(event)
    self:_EmitChildStream(event);
end

--[[
    Consume and clear pending child results.
    @return table - Array of {agentName, taskId, taskSummary, result}
]]
function AIChat:_ConsumePendingChildResults()
    local results = self._pendingChildResults;
    self._pendingChildResults = {};
    return results;
end

--[[
    Handle child task callback based on callbackMode.
    @param mode: string - "immediate" | "delay" | "debounce"
    @param debounceSeconds: number|nil
    @private
]]
function AIChat:_HandleChildCallback(mode, debounceSeconds)
    if mode == "immediate" then
        self:_TriggerImmediateCallback();
    elseif mode == "debounce" then
        self:_TriggerDebounceCallback(debounceSeconds or 5);
    end
    -- "delay" (default): do nothing — results consumed on next Ask()
end

--[[
    Trigger an immediate callback: wait for parent to finish any ongoing send,
    then send a follow-up Ask so the AI processes the child result.
    @private
]]
function AIChat:_TriggerImmediateCallback()
    local self_ = self;
    local function doSend()
        if #self_._pendingChildResults == 0 then return; end
        LOG.std(nil, "info", "AIChat", "Immediate callback: sending child results to parent");
        self_:Ask(nil, function() end, self_._lastSendOptions);
    end
    
    if self._isSending then
        -- Poll until parent finishes current send
        local timer = commonlib.Timer:new({callbackFunc = function(t)
            if not self_._isSending then
                t:Change();
                doSend();
            end
        end});
        timer:Change(200, 200);
    else
        doSend();
    end
end

--[[
    Trigger a debounce callback with timer.
    @param seconds: number
    @private
]]
function AIChat:_TriggerDebounceCallback(seconds)
    seconds = seconds or 5;
    local self_ = self;
    local timer = commonlib.Timer:new({callbackFunc = function(t)
        for i, dt in ipairs(self_._debounceTimers) do
            if dt == t then
                table.remove(self_._debounceTimers, i);
                break;
            end
        end
        self_:_TriggerImmediateCallback();
    end});
    timer:Change(seconds * 1000, nil);
    table.insert(self._debounceTimers, timer);
end

--[[
    Cancel all pending debounce timers.
    @private
]]
function AIChat:_CancelDebounceTimers()
    for _, t in ipairs(self._debounceTimers) do
        t:Change();
    end
    self._debounceTimers = {};
end

--[[
    Get a child session entry by name.
    @param name: string
    @return table|nil - {session, queue, isRunning}
]]
function AIChat:GetChildSession(name)
    return self._childSessions[name];
end

--[[
    Get all child session names.
    @return table - Array of strings
]]
function AIChat:GetChildSessionNames()
    local names = {};
    for name in pairs(self._childSessions) do
        table.insert(names, name);
    end
    return names;
end

--[[
    Get context from parent session (for child agents needing more context).
    @param messageCount: number|nil - Number of recent parent messages (default 10)
    @return table|nil
]]
function AIChat:GetParentContext(messageCount)
    if not self.parentSession then return nil; end
    messageCount = messageCount or 10;
    local parent = self.parentSession;
    local history = parent:GetHistory();
    local recent = {};
    local start = math.max(1, #history - messageCount + 1);
    for i = start, #history do
        table.insert(recent, history[i]);
    end
    return {
        systemPrompt = parent.system_prompt,
        recentMessages = recent,
        model = parent.model,
    };
end

function AIChat:SetKnowledgeBase(codes)
    if(type(codes) == "string") then
        self.knowledgeBaseCodes = commonlib.split(codes, ",");
    else
        self.knowledgeBaseCodes = codes;
    end
end

function AIChat:SetKnowledgeUsername(username)
    self.knowledgeUsername = username;
end

function AIChat:SetSystemPrompt(prompt)
    self.system_prompt = prompt;
end

function AIChat:SetModel(model)
    self.model = model;
end

function AIChat:SetReasoning(reasoning)
    self.reasoning = reasoning;
end

function AIChat:SetAutoHistory(bEnabled)
    self.auto_history = bEnabled;
end

function AIChat:SetStream(bEnabled)
    self.stream = bEnabled;
end

function AIChat:SetTools(tools)
    self.tools = tools;
end

--[[
    Set tool call mode
    @param mode: "auto" (default, AIChat executes tools and continues conversation)
                 "delegate" (return tool calls to caller via callback, caller handles execution)
    In delegate mode, the callback receives an additional 6th parameter:
    callback(resultCode, delta, deltaThink, fullResult, fullThink, toolCallInfo, extraData)
    where toolCallInfo = {toolCalls = [...], messages = [...]} when there are tool calls
    and extraData contains debug fields (response headers metadata, rawMsg/rawData, etc.)
]]
function AIChat:SetToolCallMode(mode)
    if mode ~= "auto" and mode ~= "delegate" then
        LOG.std(nil, "warn", "AIChat", "Invalid tool call mode: %s, using 'auto'", tostring(mode));
        mode = "auto";
    end
    self.toolCallMode = mode;
end

--[[
    Get current tool call mode
    @return string - "auto" or "delegate"
]]
function AIChat:GetToolCallMode()
    return self.toolCallMode or "auto";
end

--[[
    Continue conversation with tool results (used in delegate mode)
    @param toolResults: array of {tool_call_id, content} - results from tool execution
    @param callback: function(resultCode, delta, deltaThink, fullResult, fullThink, toolCallInfo, extraData)
    @param options: optional table (same as Ask options)
]]
function AIChat:ContinueWithToolResults(toolResults, callback, options)
    if not self.pendingMessages then
        LOG.std(nil, "warn", "AIChat", "ContinueWithToolResults called without pending messages");
        if callback then
            callback(400, nil, nil, "Error: No pending conversation to continue", nil, nil, {
                error = "No pending conversation to continue",
            });
        end
        return;
    end
    
    local messages = self.pendingMessages;
    local opts = options or self.pendingOptions;
    
    -- Add tool results to messages in order
    if toolResults and #toolResults > 0 then
        for _, result in ipairs(toolResults) do
            local toolMsg = {
                role = "tool",
                content = result.content or "",
                tool_call_id = result.tool_call_id,
            };
            table.insert(messages, toolMsg);
            -- Add to history if auto_history is enabled
            if self.auto_history then
                self:AddMessage("tool", toolMsg.content, nil, result.tool_call_id);
            end
        end
    end
    
    -- Clear pending state
    self.pendingMessages = nil;
    self.pendingOptions = nil;
    
    -- Continue the conversation
    self:_SendRequest(messages, callback, opts);
end

--[[
    Get pending messages (for debugging or advanced use cases)
    @return table or nil - Current pending messages array
]]
function AIChat:GetPendingMessages()
    return self.pendingMessages;
end

function AIChat:SetAPICacheKey(key)
    self.api_cache_key = key;
end

function AIChat:GetAPICacheKey()
    return self.api_cache_key;
end

function AIChat:RegisterToolCallback(name, callback)
    self.tool_callbacks[name] = callback;
end

--[[
    Register tools from a ToolRegistry onto this AIChat instance.
    Creates a temporary ToolRegistry, populates it via the given registerFunc,
    then merges tool definitions and callbacks into this instance.
    Tool handlers are executed through ToolRegistry:ExecuteTool and the result's
    llm_result field is unwrapped for the AIChat callback.

    @param registerFunc: function(registry) — populates a ToolRegistry with tools
    Example:
        aiChat:RegisterToolsFromRegistry(function(registry)
            MQTTTools:new():RegisterTools(registry);
            PersonalPageTools:new():RegisterTools(registry);
        end);
]]
function AIChat:RegisterToolsFromRegistry(registerFunc)
    if not registerFunc then return; end

    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/ToolRegistry.lua");
    local ToolRegistry = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.ToolRegistry");

    local registry = ToolRegistry:new();
    registerFunc(registry);

    local currentTools = self.tools or {};
    local newDefs = registry:GetAllToolDefinitions();
    for _, toolDef in ipairs(newDefs) do
        local name = toolDef["function"].name;
        local bFound = false;
        for _, existing in ipairs(currentTools) do
            if existing["function"] and existing["function"].name == name then
                bFound = true;
                break;
            end
        end
        if not bFound then
            table.insert(currentTools, toolDef);
        end

        if not self.tool_callbacks[name] then
            self:RegisterToolCallback(name, function(args, asyncCallback)
                registry:ExecuteTool(name, args, function(result)
                    local llmResult;
                    if type(result) == "table" and result.llm_result then
                        llmResult = result.llm_result;
                    elseif result ~= nil then
                        llmResult = tostring(result);
                    else
                        llmResult = "done";
                    end
                    if asyncCallback and type(asyncCallback) == "function" then
                        asyncCallback(llmResult);
                    end
                end);
            end);
        end
    end
    self:SetTools(currentTools);
end

--[[
    Convenience method: register commonly used EasyAIChat tools (mqtt, personal_page, scheduler).
    @param categories: string|table|nil — category filter:
        - nil or "all": registers mqtt + personal_page + scheduler
        - string: single category name (e.g. "mqtt")
        - table: array of category names (e.g. {"mqtt", "personal_page"})
    Example:
        aiChat:RegisterEasyTools();  -- all tools
        aiChat:RegisterEasyTools({"mqtt", "personal_page"});
]]
function AIChat:RegisterEasyTools(categories)
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/MQTTTools.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/PersonalPageTools.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/SchedulerTools.lua");
    local MQTTTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.MQTTTools");
    local PersonalPageTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.PersonalPageTools");
    local SchedulerTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.SchedulerTools");

    if type(categories) == "string" then
        categories = {categories};
    end

    local categorySet;
    if categories then
        categorySet = {};
        for _, c in ipairs(categories) do
            categorySet[c] = true;
        end
    end

    self:RegisterToolsFromRegistry(function(registry)
        if not categorySet or categorySet["mqtt"] then
            MQTTTools:new():RegisterTools(registry);
        end
        if not categorySet or categorySet["personal_page"] then
            PersonalPageTools:new():RegisterTools(registry);
        end
        if not categorySet or categorySet["scheduler"] then
            SchedulerTools:new():RegisterTools(registry);
        end
    end);
end

function AIChat:ClearHistory()
    self.history = {};
end

function AIChat:AddMessage(role, content, tool_calls, tool_call_id)
    table.insert(self.history, {
        role = role, 
        content = content,
        tool_calls = tool_calls,
        tool_call_id = tool_call_id
    });
end

function AIChat:GetHistory()
    return self.history;
end

function AIChat:SetHistory(history)
    self.history = history or {};
end

-- Save history to a local JSON file
-- @param filepath: relative path to the save file (e.g. "worlds/myworld/chat.json")
function AIChat:SaveHistory(filepath)
    if not filepath then return false end
    
    local data = {
        history = self.history,
        system_prompt = self.system_prompt,
        model = self.model,
        reasoning = self.reasoning,
        tools = self.tools,
        timestamp = os.time()
    }
    
    local content = commonlib.Json.Encode(data);
    local file = ParaIO.open(filepath, "w");
    if(file:IsValid()) then
        file:WriteString(content);
        file:close();
        return true;
    else
        LOG.std(nil, "warn", "AIChat", "Failed to save history to %s", filepath);
    end
    return false;
end

-- Load history from a local JSON file
-- @param filepath: relative path to the save file
function AIChat:LoadHistory(filepath)
    if not filepath then return false end
    
    local file = ParaIO.open(filepath, "r");
    if(file:IsValid()) then
        local content = file:GetText();
        file:close();
        
        local data = commonlib.Json.Decode(content);
        if data then
            self.history = data.history or {};
            self.system_prompt = data.system_prompt or self.system_prompt;
            self.model = data.model or self.model;
            if data.reasoning ~= nil then
                self.reasoning = data.reasoning;
            end
            self.tools = data.tools or self.tools;
            return true;
        end
    end
    return false;
end

function AIChat:Abort()
    if(self.signal) then
        self.signal:Abort();
        self.signal = nil;
    end
end

local clean_input = function(input)
    if(type(input) == "string") then
        return input:gsub("^%s+", ""):gsub("%s+$", ""):gsub("\n", ""):gsub("\r", "");
    end
    return input;
end

-- @param input: user input string
-- @param callback: function(resultCode, delta, deltaThink, fullResult, fullThink, toolCallInfo, extraData) end
-- @param options: optional table {images="url1,url2", knowledge="code1,code2", knowledgeUsername="user", reasoning=boolean}
function AIChat:Ask(input, callback, options)
    -- Reset iteration counter for new conversation turn
    self._currentIteration = 0;
    
    -- Cancel debounce timers — pending child results will be consumed in this send cycle
    self:_CancelDebounceTimers();
    self._isSending = true;
    self._lastSendOptions = options or {};
    
    local messages = {};
    if self.system_prompt then
        table.insert(messages, {role = "system", content = (self.system_prompt)});
    end
    
    for _, msg in ipairs(self.history) do
        table.insert(messages, {
            role = msg.role, 
            content = (msg.content),
            tool_calls = msg.tool_calls,
            tool_call_id = msg.tool_call_id
        });
    end
    
    -- Insert pending child agent results as tool messages before the user message
    local childResults = self:_ConsumePendingChildResults();
    if #childResults > 0 then
        local toolCalls = {};
        for _, cr in ipairs(childResults) do
            table.insert(toolCalls, {
                id = cr.taskId,
                type = "function",
                ["function"] = {
                    name = "async_agent_task",
                    arguments = commonlib.Json.Encode({agent = cr.agentName, task = cr.taskSummary}),
                },
            });
        end
        table.insert(messages, {
            role = "assistant",
            content = nil,
            tool_calls = toolCalls,
        });
        for _, cr in ipairs(childResults) do
            local resultStr = type(cr.result) == "string" and cr.result or commonlib.serialize_compact(cr.result);
            table.insert(messages, {
                role = "tool",
                tool_call_id = cr.taskId,
                content = resultStr,
            });
        end
    end
    
    if input and input ~= "" then
        local content = (input);
        if(options and options.images) then
             content = {{ type = "text", text = input }};
             local images = options.images;
             if(type(images) == "string") then
                 local httpCount = 0;
                 for _ in images:gmatch("https?://") do
                     httpCount = httpCount + 1;
                 end
                 if(httpCount > 1) then
                     images = commonlib.split(images, ",");
                 else
                     images = { images };
                 end
             end
             for i = 1, #images do
                table.insert(content, {
                    type = "image_url",
                    image_url = {
                        url = images[i],
                    };
                });
            end
        end
        table.insert(messages, {role = "user", content = content});
        if self.auto_history then
            self:AddMessage("user", content);
        end
    end

    self:_SendRequest(messages, callback, options);
end

function AIChat:_SendRequest(messages, callback, options)
    -- maxIterations guard to prevent runaway tool-call loops
    self._currentIteration = (self._currentIteration or 0) + 1;
    if self._currentIteration > self.maxIterations then
        LOG.std(nil, "warn", "AIChat", "maxIterations (%d) exceeded, stopping tool-call loop", self.maxIterations);
        self._isSending = false;
        -- Return whatever content we have so far
        local lastContent = "";
        for i = #messages, 1, -1 do
            if messages[i].role == "assistant" and messages[i].content then
                lastContent = messages[i].content;
                break;
            end
        end
        if callback then
            callback(200, nil, nil, lastContent, "", nil, {maxIterationsExceeded = true});
        end
        return;
    end
    
    self.signal = System.os.AbortController:new();
    
    -- Generate session ID for chat logging
    local sessionId = string.format("%s_%d", os.date("%H%M%S"), math.random(1000, 9999));
    self._currentSessionId = sessionId;
    
    local request_entry = { signal = self.signal };
    table.insert(AIChat.active_requests, request_entry);
    
    if (#AIChat.active_requests > AIChat.MaxConcurrentRequests) then
        local oldest_entry = table.remove(AIChat.active_requests, 1);
        if(oldest_entry and oldest_entry.signal) then
            oldest_entry.signal:Abort();
        end
    end

    local requestModel = AIChat.GetRequestModel(self.model, options);
    local requestReasoning = AIChat.GetRequestReasoning(self.reasoning, requestModel, options);

    local chat_params = {
        messages = messages,
        model = requestModel,
        stream = self.stream,
        signal = self.signal,
        dataStreaming = self.stream,
        reasoning = requestReasoning,
    }
    print("AIChat: Requesting model===================:", requestModel, "with reasoning:", tostring(requestReasoning));
    
    -- Merge enableTools category definitions with manually set tools
    local allTools = {};
    if self.enableTools and #self.enableTools > 0 then
        local categoryTools = AIChat.GetToolDefinitions(self.enableTools);
        for _, def in ipairs(categoryTools) do
            table.insert(allTools, def);
        end
    end
    if self.tools then
        for _, def in ipairs(self.tools) do
            table.insert(allTools, def);
        end
    end
    if #allTools > 0 then
        chat_params.localTools = allTools;
    end

    if options and options.knowledge then
        chat_params.knowledgeBaseCodes = commonlib.split(options.knowledge, ",");
    elseif self.knowledgeBaseCodes then
        chat_params.knowledgeBaseCodes = self.knowledgeBaseCodes
    end

    if options and options.knowledgeUsername then
        chat_params.knowledgeUsername = options.knowledgeUsername
    elseif self.knowledgeUsername then
        chat_params.knowledgeUsername = self.knowledgeUsername
    end

    if self.api_cache_key then
        chat_params.headers = chat_params.headers or {};
        chat_params.headers["api-cache-key"] = self.api_cache_key;
    end

    if AIChat.bEnableDevLog then
        local logParams = {};
        for k, v in pairs(chat_params) do
            if k ~= "signal" then
                logParams[k] = v;
            end
        end
        LOG.std(nil, "info", "AIChat", "========== [DEV_LOG] REQUEST ==========");
        -- Log any image URLs from multimodal messages
        for _, msg in ipairs(chat_params.messages or {}) do
            if type(msg.content) == "table" then
                for _, part in ipairs(msg.content) do
                    if part.type == "image_url" and part.image_url then
                        local url = type(part.image_url) == "table" and part.image_url.url or part.image_url;
                        LOG.std(nil, "info", "AIChat", "[DEV_LOG] vision image: %s", tostring(url));
                    end
                end
            end
        end
        LOG.std(nil, "info", "AIChat", "========== [DEV_LOG] REQUEST END ==========");
        ChatLogUtil.LogRequest(sessionId, logParams);
    end
    
    AIChat.FilterMessages(messages);
    AIChat.CompressMessages(messages);
    
    local lastData = "";
    local lastCount = 0;
    local fullResult = "";
    local fullThink = "";
    local collectedToolCalls = {};
    local cachedResponseMetadata = {};
    if requestReasoning ~= nil then
        cachedResponseMetadata.reasoning = requestReasoning;
    end
    local metadataExtractedOnce = false;

    local function extractErrorDetail(errMsg, errData)
        local detail = nil;
        if type(errData) == "table" then
            detail = errData.message or errData.error or errData.msg;
            if (not detail or detail == "") and next(errData) ~= nil then
                detail = commonlib.serialize_compact(errData);
            end
        elseif type(errData) == "string" and errData ~= "" then
            detail = errData;
        end

        if (not detail or detail == "") and type(errMsg) == "table" then
            detail = errMsg.message or errMsg.error or errMsg.msg;
            if (not detail or detail == "") and next(errMsg) ~= nil then
                detail = commonlib.serialize_compact(errMsg);
            end
        elseif (not detail or detail == "") and type(errMsg) == "string" and errMsg ~= "" then
            detail = errMsg;
        end

        return detail;
    end

    keepwork.ai.chat(chat_params, function(resultCode, msg, data)
        local delta = "";
        local deltaThink = "";
        if not metadataExtractedOnce then
            local responseMetadata = AIChat.ExtractResponseDebugMetadata(msg, data);
            if type(responseMetadata) == "table" then
                for k, v in pairs(responseMetadata) do
                    cachedResponseMetadata[k] = v;
                end
            end
            metadataExtractedOnce = true;
        end
        local effectiveResponseMetadata = next(cachedResponseMetadata) and cachedResponseMetadata or nil;
        
        local callbackExtraData = {
            responseMetadata = effectiveResponseMetadata,
            rawMsg = msg,
            rawData = data,
            sessionId = sessionId,
        };
        if type(effectiveResponseMetadata) == "table" then
            for k, v in pairs(effectiveResponseMetadata) do
                callbackExtraData[k] = v;
            end
        end
        
        if(self.stream and msg and msg.type=="stream") then
            lastData = lastData..(msg.data or "");
            local datas = commonlib.split(lastData, "\n");
            
            local newCount = lastCount;
            for i = lastCount + 1, #datas do
                local line = datas[i];
                if(line:match("data: {")) then
                    local part = {}
                    if(NPL.FromJson(line:sub(7, -1), part)) then
                        if(part.result) then
                            delta = delta..part.result
                            fullResult = fullResult..part.result
                        end
                        if(part.reasoning_content) then
                            deltaThink = deltaThink..part.reasoning_content
                            fullThink = fullThink..part.reasoning_content
                        end
                        
                        -- Streaming tool call collection: accumulate deltas by index.
                        -- When a chunk carries a NEW id (different from the existing entry at the same index),
                        -- treat it as a separate tool call to prevent merging parallel calls
                        -- that share the same index (common with some LLM API proxies).
                        if(part.tool_calls) then
                            for _, tc in ipairs(part.tool_calls) do
                                local found = false;
                                if not (tc.id and tc.id ~= "") then
                                    -- Delta chunk (no id) — append to matching index
                                    for _, existing in ipairs(collectedToolCalls) do
                                        if existing.index == tc.index then
                                            if tc["function"] and tc["function"].name then 
                                                existing["function"] = existing["function"] or {};
                                                existing["function"].name = (existing["function"].name or "") .. tc["function"].name;
                                            end
                                            if tc["function"] and tc["function"].arguments then 
                                                existing["function"] = existing["function"] or {};
                                                existing["function"].arguments = (existing["function"].arguments or "") .. tc["function"].arguments;
                                            end
                                            found = true;
                                            break;
                                        end
                                    end
                                else
                                    -- Chunk with id — only merge if same id already exists
                                    for _, existing in ipairs(collectedToolCalls) do
                                        if existing.id == tc.id then
                                            if tc["function"] and tc["function"].name then 
                                                existing["function"] = existing["function"] or {};
                                                existing["function"].name = (existing["function"].name or "") .. tc["function"].name;
                                            end
                                            if tc["function"] and tc["function"].arguments then 
                                                existing["function"] = existing["function"] or {};
                                                existing["function"].arguments = (existing["function"].arguments or "") .. tc["function"].arguments;
                                            end
                                            found = true;
                                            break;
                                        end
                                    end
                                end
                                if not found then
                                    table.insert(collectedToolCalls, commonlib.copy(tc));
                                end
                            end
                        end

                        newCount = i;
                    end
                end
            end
            lastCount = newCount;
            
            if callback and (delta ~= "" or deltaThink ~= "") then
                callback(nil, delta, deltaThink, fullResult, fullThink, nil, callbackExtraData);
            end
            
        elseif(data) then
             if not self.stream then
                 fullResult = data.result or fullResult;
                 fullThink = data.reasoning_content or fullThink;
                 collectedToolCalls = data.tool_calls or collectedToolCalls;
                 delta = fullResult;
                 deltaThink = fullThink;
                 if callback then
                          callback(nil, delta, deltaThink, fullResult, fullThink, nil, callbackExtraData);
                 end
             end
        end

        if(resultCode) then
            for i, v in ipairs(AIChat.active_requests) do
                if(v.signal == chat_params.signal) then
                    table.remove(AIChat.active_requests, i);
                    break;
                end
            end

            -- Reconstruct from lastData if fullResult is empty (robustness fallback)
            if (fullResult == "" and lastData ~= "") then
                local datas = commonlib.split(lastData, "\n");
                for i = 1, #datas do
                    local line = datas[i]
                    if(line:match("data: {")) then
                        local part = {}
                        if(NPL.FromJson(line:sub(7, -1), part)) then
                            if(part.result) then fullResult = fullResult..part.result end
                            if(part.reasoning_content) then fullThink = fullThink..part.reasoning_content end
                            -- Note: tool_calls reconstruction from string is hard without proper parser, rely on realtime collection
                        end
                    end
                end
            end

            local errorDetail = nil;
            if resultCode ~= 200 then
                errorDetail = extractErrorDetail(msg, data);
                if (not errorDetail or errorDetail == "") and resultCode == 0 then
                    errorDetail = "Network error: request failed before receiving server response";
                end
                if (fullResult == "" and errorDetail and errorDetail ~= "") then
                    fullResult = errorDetail;
                end
            end

            -- Handle Tool Calls Logic
            if collectedToolCalls and #collectedToolCalls > 0 then
                -- Dev log: log received tool calls
                if AIChat.bEnableDevLog then
                    LOG.std(nil, "debug", "AIChat", "========== [DEV_LOG] RESPONSE (TOOL CALLS) ==========");
                    LOG.std(nil, "debug", "AIChat", "[DEV_LOG] resultCode=%s toolCallCount=%d", tostring(resultCode), #collectedToolCalls);
                    if fullResult ~= "" then
                        LOG.std(nil, "debug", "AIChat", "[DEV_LOG] assistantContent: %s%s", 
                            fullResult:sub(1, 500), #fullResult > 500 and "...[truncated]" or "");
                    end
                    for i, tc in ipairs(collectedToolCalls) do
                        LOG.std(nil, "debug", "AIChat", "[DEV_LOG] toolCall[%d] id=%s name=%s", 
                            i, tc.id or "?", tc["function"] and tc["function"].name or "?");
                        LOG.std(nil, "debug", "AIChat", "[DEV_LOG] toolCall[%d] arguments=%s", 
                            i, tc["function"] and tc["function"].arguments or "");
                    end
                    LOG.std(nil, "debug", "AIChat", "========== [DEV_LOG] RESPONSE END ==========");
                end
                
                -- Log response with tool calls to ChatLogUtil
                if AIChat.bEnableDevLog then
                    LOG.std(nil, "debug", "AIChat", "[DEV_LOG] ChatLogUtil.LogResponse(tool_calls) metadata=%s",
                        type(effectiveResponseMetadata) == "table" and commonlib.serialize_compact(effectiveResponseMetadata) or "nil");
                end
                ChatLogUtil.LogResponse(sessionId, resultCode, fullResult, fullThink, collectedToolCalls, nil, errorDetail, effectiveResponseMetadata);
                
                -- Add assistant message with tool calls
                local assistantMsg = { 
                    role = "assistant", 
                    content = fullResult ~= "" and fullResult or nil, 
                    tool_calls = collectedToolCalls 
                };
                table.insert(messages, assistantMsg);
                if self.auto_history then 
                    self:AddMessage("assistant", assistantMsg.content, assistantMsg.tool_calls);
                end
                
                -- Delegate mode: return tool calls to caller instead of executing them
                if self.toolCallMode == "delegate" then
                    -- Store pending messages and options for ContinueWithToolResults
                    self.pendingMessages = messages;
                    self.pendingOptions = options;
                    
                    -- Return tool calls info to callback
                    local toolCallInfo = {
                        toolCalls = collectedToolCalls,
                        messages = messages,
                    };
                    
                    if callback then
                        callback(resultCode, nil, nil, fullResult, fullThink, toolCallInfo, callbackExtraData);
                    end
                    return;
                end
                
                -- Auto mode: Execute Tools (Async Support with ordered results)
                local pendingTools = 0;
                local hasToolExec = false;
                local toolResults = {}; -- Store results in order: {[callId] = {msg, index}}
                local toolOrder = {};   -- Track original order of tool calls
                local allToolsFinishedCalled = false; -- Guard: prevent double-call when tools finish synchronously
                
                local function checkAllToolsFinished()
                    if allToolsFinishedCalled then return; end
                    if pendingTools == 0 and hasToolExec then
                        allToolsFinishedCalled = true;
                        -- Add tool results in original order (important for LLM context)
                        for i, callId in ipairs(toolOrder) do
                            local resultData = toolResults[callId];
                            if resultData then
                                table.insert(messages, resultData.msg);
                                if self.auto_history then 
                                    self:AddMessage("tool", resultData.msg.content, nil, callId);
                                end
                            end
                        end
                        self:_SendRequest(messages, callback, options);
                    end
                end

                for idx, toolCall in ipairs(collectedToolCalls) do
                    local funcName = toolCall["function"].name;
                    local argsStr = toolCall["function"].arguments;
                    local callId = toolCall.id;
                    
                    -- Track original order
                    table.insert(toolOrder, callId);
                    
                    local callbackFunc = self.tool_callbacks[funcName];
                    
                    if callbackFunc then
                        hasToolExec = true;
                        pendingTools = pendingTools + 1;
                        
                        -- Parse arguments with error handling
                        local args = {};
                        local parseOk = true;
                        if argsStr and argsStr ~= "" then
                            parseOk = NPL.FromJson(argsStr, args);
                            if not parseOk then
                                LOG.std(nil, "warn", "AIChat", "Failed to parse tool arguments: %s", argsStr);
                                args = {}; -- Reset to empty
                            end
                        end
                        
                        -- Dev log: log tool execution
                        if AIChat.bEnableDevLog then
                            LOG.std(nil, "debug", "AIChat", "[DEV_LOG] Executing tool: %s id=%s", funcName, callId or "?");
                            LOG.std(nil, "debug", "AIChat", "[DEV_LOG] Tool args: %s", commonlib.serialize_compact(args));
                        end
                        
                        -- Track if callback was already called (prevent double-call)
                        local callbackCalled = false;
                        
                        -- Define completion callback for this tool
                        local function onToolFinished(result)
                             -- Prevent double callback
                             if callbackCalled then
                                 LOG.std(nil, "warn", "AIChat", "Tool callback called multiple times: %s", funcName);
                                 return;
                             end
                             callbackCalled = true;
                             
                             -- Extract llm_result if available, otherwise serialize the whole result
                             local resultStr;
                             if type(result) == "table" and result.llm_result then
                                 resultStr = tostring(result.llm_result);
                             elseif type(result) == "string" then
                                 resultStr = result;
                             else
                                 resultStr = commonlib.serialize_compact(result);
                             end
                             
                             -- Truncate long results to prevent token overflow
                             local maxLen = AIChat.MaxToolResultLength or 4000;
                             if #resultStr > maxLen then
                                 local truncatedStr = resultStr:sub(1, maxLen);
                                 resultStr = truncatedStr .. "\n...[truncated, total " .. #resultStr .. " chars]";
                                 if AIChat.bEnableDevLog then
                                     LOG.std(nil, "debug", "AIChat", "[DEV_LOG] Tool result truncated from %d to %d chars", #resultStr, maxLen);
                                 end
                             end
                             
                             -- Log tool result to ChatLogUtil
                             ChatLogUtil.LogToolResult(sessionId, funcName, callId, args, resultStr);
                             
                             -- Dev log: log tool result
                             if AIChat.bEnableDevLog then
                                 LOG.std(nil, "debug", "AIChat", "[DEV_LOG] Tool finished: %s id=%s", funcName, callId or "?");
                                 LOG.std(nil, "debug", "AIChat", "[DEV_LOG] Tool result: %s%s", 
                                     resultStr:sub(1, 500), #resultStr > 500 and "...[truncated]" or "");
                             end
                             
                             -- Store Tool Result (will be added in order later)
                             local toolMsg = { role = "tool", content = resultStr, tool_call_id = callId };
                             toolResults[callId] = { msg = toolMsg, index = idx };
                             
                             pendingTools = pendingTools - 1;
                             checkAllToolsFinished();
                        end

                        -- Setup timeout for async tools
                        local timeoutTimer = nil;
                        if AIChat.ToolExecutionTimeout and AIChat.ToolExecutionTimeout > 0 then
                            timeoutTimer = commonlib.Timer:new({callbackFunc = function()
                                if not callbackCalled then
                                    LOG.std(nil, "warn", "AIChat", "Tool execution timeout: %s (id=%s)", funcName, callId or "?");
                                    onToolFinished({llm_result = "Error: Tool execution timeout after " .. (AIChat.ToolExecutionTimeout/1000) .. " seconds"});
                                end
                            end});
                            timeoutTimer:Change(AIChat.ToolExecutionTimeout, nil);
                        end
                        
                        -- Execute with error handling
                        local ok, res = pcall(function() 
                            return callbackFunc(args, onToolFinished);
                        end);

                        if not ok then
                            if timeoutTimer then timeoutTimer:Change(); end -- Cancel timeout
                            onToolFinished("Error executing tool: " .. tostring(res));
                        elseif res ~= nil then
                            -- Synchronous return
                            if timeoutTimer then timeoutTimer:Change(); end -- Cancel timeout
                            onToolFinished(res);
                        end
                        -- else: Asynchronous, wait for callback (timeout will handle stuck cases)
                    else
                         -- Tool not found - store error result in order
                         toolResults[callId] = { 
                             msg = { role = "tool", content = "Error: Tool '" .. funcName .. "' not found", tool_call_id = callId },
                             index = idx 
                         };
                    end
                end
                
                -- Handle case where all tools were not found (no hasToolExec but have results)
                if not hasToolExec and #toolOrder > 0 then
                    -- Add all "not found" results in order
                    for i, callId in ipairs(toolOrder) do
                        local resultData = toolResults[callId];
                        if resultData then
                            table.insert(messages, resultData.msg);
                            if self.auto_history then 
                                self:AddMessage("tool", resultData.msg.content, nil, callId);
                            end
                        end
                    end
                    self:_SendRequest(messages, callback, options);
                    return;
                end
                
                -- If no valid tools were found to execute (pendingTools is 0), but we had tool calls...
                -- This means all tools finished synchronously
                if pendingTools == 0 and hasToolExec then
                     -- checkAllToolsFinished will handle adding results and sending request
                     checkAllToolsFinished();
                     return;
                end
                
                -- If pendingTools > 0, we wait for callbacks.
                return;
            end

            -- Dev log: log normal response (no tool calls)
            if AIChat.bEnableDevLog then
                LOG.std(nil, "debug", "AIChat", "========== [DEV_LOG] RESPONSE (NORMAL) ==========");
                LOG.std(nil, "debug", "AIChat", "[DEV_LOG] resultCode=%s resultLen=%d thinkLen=%d", 
                    tostring(resultCode), #fullResult, #fullThink);
                if fullResult ~= "" then
                    LOG.std(nil, "debug", "AIChat", "[DEV_LOG] response: %s%s", 
                        fullResult:sub(1, 1000), #fullResult > 1000 and "...[truncated]" or "");
                end
                if fullThink ~= "" then
                    LOG.std(nil, "debug", "AIChat", "[DEV_LOG] thinking: %s%s", 
                        fullThink:sub(1, 500), #fullThink > 500 and "...[truncated]" or "");
                end
                -- Write full response to file
                local respLogPath = ParaIO.GetWritablePath() .. "temp/aichat_response.json";
                local respFile = ParaIO.open(respLogPath, "w");
                if respFile:IsValid() then
                    respFile:WriteString(commonlib.Json.Encode({
                        resultCode = resultCode,
                        response = fullResult,
                        thinking = fullThink,
                        error = errorDetail,
                        rawMsg = msg,
                        rawData = data,
                        timestamp = os.time(),
                    }) or "{}");
                    respFile:close();
                    LOG.std(nil, "debug", "AIChat", "[DEV_LOG] Full response written to: %s", respLogPath);
                end
                LOG.std(nil, "debug", "AIChat", "========== [DEV_LOG] RESPONSE END ==========");
            end

            -- Log normal response to ChatLogUtil
            if AIChat.bEnableDevLog then
                LOG.std(nil, "debug", "AIChat", "[DEV_LOG] ChatLogUtil.LogResponse(normal) metadata=%s",
                    type(effectiveResponseMetadata) == "table" and commonlib.serialize_compact(effectiveResponseMetadata) or "nil");
            end
            ChatLogUtil.LogResponse(sessionId, resultCode, fullResult, fullThink, nil, nil, errorDetail, effectiveResponseMetadata);

            -- Finished Normal Chat
            self._isSending = false;
            if self.auto_history and not (resultCode ~= 200) then
                if fullResult ~= "" then
                    self:AddMessage("assistant", fullResult);
                end
            end
            
            if callback then
                -- Pass nil as 6th parameter (toolCallInfo) for consistency with delegate mode
                callback(resultCode, nil, nil, fullResult, fullThink, nil, callbackExtraData);
            end
        end
    end)
end
