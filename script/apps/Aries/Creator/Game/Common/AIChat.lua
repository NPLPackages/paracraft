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
    if self.tools and #self.tools > 0 then
        chat_params.localTools = self.tools
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
                        
                        -- Simple tool call collection for streaming (might need more robust parsing for partial JSON)
                        if(part.tool_calls) then
                            for _, tc in ipairs(part.tool_calls) do
                                -- Find existing tool call to append or create new
                                local found = false;
                                for _, existing in ipairs(collectedToolCalls) do
                                    if existing.index == tc.index then
                                        if tc.id then existing.id = tc.id end
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
                
                local function checkAllToolsFinished()
                    if pendingTools == 0 and hasToolExec then
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
