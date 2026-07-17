--[[
Title: Chat Log Utility
Author(s): AI Assistant
Date: 2026/1/29
Desc: Utility for logging AI chat requests and responses to daily Markdown files.
      Features:
      - Daily log files with automatic rotation (.copilotmd format)
      - File size limit (100MB) with index-based rotation
      - 7-day retention with automatic cleanup
      - Human-readable Markdown output format matching VS Code Copilot log style

Output Format Example:
------------------------------------------------------------
## Metadata
~~~
type             : request
timestamp        : 2026-02-05T07:36:13.000Z
epoch            : 1738741573
sessionId        : 123456_1738741573_12345
model            : claude-opus-4.5
stream           : true
~~~
## Request Messages
### System
~~~md
You are an AI assistant...
~~~
### User
~~~md
Hello, how are you?
~~~

---

## Metadata
~~~
type             : response
timestamp        : 2026-02-05T07:36:25.000Z
epoch            : 1738741585
sessionId        : 123456_1738741573_12345
resultCode       : 200
~~~
## Request Messages
### Assistant
~~~md
I'm doing well, thank you!
~~~

---
------------------------------------------------------------

Use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ChatLogUtil.lua");
local ChatLogUtil = commonlib.gettable("MyCompany.Aries.Game.Common.ChatLogUtil");

-- Enable logging (disabled by default)
ChatLogUtil.SetEnabled(true);

-- Log a request
ChatLogUtil.LogRequest(sessionId, logParams);

-- Log a response
ChatLogUtil.LogResponse(sessionId, resultCode, fullResult, fullThink, toolCalls, usage, errorDetail);

-- Log tool execution result
ChatLogUtil.LogToolResult(sessionId, toolName, toolCallId, args, result);
------------------------------------------------------------
]]

local ChatLogUtil = commonlib.gettable("MyCompany.Aries.Game.Common.ChatLogUtil");

-- Configuration
ChatLogUtil.enabled = false;
ChatLogUtil.logDir = "temp/aichat_logs/";
ChatLogUtil.maxFileSize = 100 * 1024 * 1024; -- 100MB
ChatLogUtil.retentionDays = 7;
ChatLogUtil.currentFileIndex = 0;
ChatLogUtil.currentDate = nil;
ChatLogUtil.initialized = false;

-- Request timing tracking (sessionId -> startTime)
ChatLogUtil.requestStartTimes = {};

-- Session header tracking (to write session header only once per session)
ChatLogUtil.writtenSessionHeaders = {};

-- Enable or disable chat logging
-- @param bEnabled: boolean
function ChatLogUtil.SetEnabled(bEnabled)
    ChatLogUtil.enabled = bEnabled;
    if bEnabled and not ChatLogUtil.initialized then
        ChatLogUtil.Init();
    end
    LOG.std(nil, "info", "ChatLogUtil", "Chat logging %s", bEnabled and "enabled" or "disabled");
end

-- Check if logging is enabled
function ChatLogUtil.IsEnabled()
    return ChatLogUtil.enabled;
end

-- Initialize the logger
function ChatLogUtil.Init()
    if ChatLogUtil.initialized then
        return;
    end
    
    -- Ensure log directory exists
    local fullPath = ChatLogUtil.GetLogDir();
    ParaIO.CreateDirectory(fullPath);
    
    -- Clean up old log files
    ChatLogUtil.CleanupOldFiles();
    
    -- Find current file index for today
    ChatLogUtil.currentDate = os.date("%Y-%m-%d");
    ChatLogUtil.currentFileIndex = ChatLogUtil.FindNextFileIndex();
    
    ChatLogUtil.initialized = true;
    LOG.std(nil, "info", "ChatLogUtil", "Initialized. Log dir: %s", fullPath);
end

-- Get today's date string
function ChatLogUtil.GetDateString()
    return os.date("%Y-%m-%d");
end

-- Get current log file path
function ChatLogUtil.GetCurrentFilePath()
    local dateStr = ChatLogUtil.GetDateString();
    
    -- Check if date changed
    if dateStr ~= ChatLogUtil.currentDate then
        ChatLogUtil.currentDate = dateStr;
        ChatLogUtil.currentFileIndex = 0;
    end
    
    local filename;
    if ChatLogUtil.currentFileIndex == 0 then
        filename = string.format("chat_%s.copilotmd", dateStr);
    else
        filename = string.format("chat_%s_%d.copilotmd", dateStr, ChatLogUtil.currentFileIndex);
    end
    
    return ParaIO.GetWritablePath() .. ChatLogUtil.logDir .. filename;
end

-- Find the next available file index for today
function ChatLogUtil.FindNextFileIndex()
    local dateStr = ChatLogUtil.GetDateString();
    local basePath = ChatLogUtil.GetLogDir();
    
    local index = 0;
    while true do
        local filename;
        if index == 0 then
            filename = string.format("chat_%s.copilotmd", dateStr);
        else
            filename = string.format("chat_%s_%d.copilotmd", dateStr, index);
        end
        
        local filepath = basePath .. filename;
        local fileSize = ChatLogUtil.GetFileSize(filepath);
        
        if fileSize < 0 then
            -- File doesn't exist, use this index
            return index;
        elseif fileSize >= ChatLogUtil.maxFileSize then
            -- File is full, try next index
            index = index + 1;
        else
            -- File exists and has room
            return index;
        end
    end
end

-- Get file size, returns -1 if file doesn't exist
function ChatLogUtil.GetFileSize(filepath)
    local file = ParaIO.open(filepath, "r");
    if file:IsValid() then
        local size = file:GetFileSize();
        file:close();
        return size;
    end
    return -1;
end

-- Check if current file needs rotation
function ChatLogUtil.CheckRotation()
    local filepath = ChatLogUtil.GetCurrentFilePath();
    local fileSize = ChatLogUtil.GetFileSize(filepath);
    
    if fileSize >= ChatLogUtil.maxFileSize then
        ChatLogUtil.currentFileIndex = ChatLogUtil.currentFileIndex + 1;
        LOG.std(nil, "info", "ChatLogUtil", "Rotating to new file index: %d", ChatLogUtil.currentFileIndex);
    end
end

-- Format a metadata line with aligned key:value (17 chars for key)
-- @param key: string key name
-- @param value: any value (will be converted to string or JSON)
-- @return formatted line string
function ChatLogUtil.FormatMetadataLine(key, value)
    local valueStr;
    if type(value) == "table" then
        local jsonStr = commonlib.Json.Beautify(value);
        -- Ensure we got a string, fallback to serialize if Beautify fails
        if type(jsonStr) == "string" then
            valueStr = jsonStr;
        else
            valueStr = commonlib.serialize_compact(value) or "{}";
        end
        valueStr = valueStr:gsub("\\r", "");
        valueStr = valueStr:gsub("\\n", "\n");
    elseif type(value) == "boolean" then
        valueStr = value and "true" or "false";
    elseif value == nil then
        valueStr = "undefined";
    else
        valueStr = tostring(value);
    end
    -- Pad key to 17 characters for alignment
    local paddedKey = key .. string.rep(" ", math.max(0, 17 - #key));
    return paddedKey .. ": " .. valueStr;
end

-- Format a message block with role header and content
-- @param role: message role (System, User, Assistant, Tool, Tool Calls)
-- @param content: message content (string or table for multi-modal messages)
-- @param toolCallsContent: optional beautified JSON string of tool_calls (for Assistant messages)
-- @param toolMeta: optional table {tool_call_id, name} for Tool role messages (GitHub Copilot style)
-- @return formatted message block string
function ChatLogUtil.FormatMessageBlock(role, content, toolCallsContent, toolMeta)
    local lines = {};
    -- For Tool role, show tool_call_id inline: ### Tool (call_xxx, tool_name)
    if role == "Tool" and toolMeta then
        local parts = {};
        if toolMeta.tool_call_id then
            table.insert(parts, toolMeta.tool_call_id);
        end
        if toolMeta.name then
            table.insert(parts, toolMeta.name);
        end
        if #parts > 0 then
            table.insert(lines, string.format("### %s (%s)", role, table.concat(parts, ", ")));
        else
            table.insert(lines, "### " .. role);
        end
    else
        table.insert(lines, "### " .. role);
    end
    
    local hasContent = (content ~= nil and content ~= "");
    local hasToolCalls = (toolCallsContent ~= nil and toolCallsContent ~= "");
    
    -- Add text/content block if present
    if hasContent then
        table.insert(lines, "~~~md");
        
        -- Handle multi-modal content (array of {type, text/image_url})
        local contentStr;
        if type(content) == "table" then
            local parts = {};
            for _, part in ipairs(content) do
                if type(part) == "table" then
                    if part.type == "text" and part.text then
                        table.insert(parts, part.text);
                    elseif part.type == "image_url" and part.image_url then
                        local url = type(part.image_url) == "table" and part.image_url.url or part.image_url;
                        table.insert(parts, string.format("[Image: %s]", url or "unknown"));
                    end
                elseif type(part) == "string" then
                    table.insert(parts, part);
                end
            end
            contentStr = table.concat(parts, "\n\n");
        else
            contentStr = content or "";
        end
        
        table.insert(lines, contentStr);
        table.insert(lines, "~~~");
    end
    
    -- Add tool calls block merged under the same heading (GitHub Copilot style)
    if hasToolCalls then
        table.insert(lines, "~~~json (tool_calls)");
        table.insert(lines, toolCallsContent);
        table.insert(lines, "~~~");
    end
    
    -- If neither content nor tool calls, add an empty md block
    if not hasContent and not hasToolCalls then
        table.insert(lines, "~~~md");
        table.insert(lines, "");
        table.insert(lines, "~~~");
    end
    
    return table.concat(lines, "\n");
end

-- Get ISO 8601 timestamp
function ChatLogUtil.GetISOTimestamp()
    return os.date("!%Y-%m-%dT%H:%M:%S") .. ".000Z";
end

-- Clean up log files older than retention period
function ChatLogUtil.CleanupOldFiles()
    local basePath = ChatLogUtil.GetLogDir();
    local cutoffTime = os.time() - (ChatLogUtil.retentionDays * 24 * 60 * 60);
    local deletedCount = 0;
    
    local search_result = ParaIO.SearchFiles(basePath, "chat_*.copilotmd", "", 0, 1000, 0);
    local nCount = search_result:GetNumOfResult();
    
    for i = 0, nCount - 1 do
        local filename = search_result:GetItem(i);
        local filepath = basePath .. filename;
        
        -- Extract date from filename (chat_YYYY-MM-DD.json or chat_YYYY-MM-DD_N.json)
        local year, month, day = filename:match("chat_(%d+)-(%d+)-(%d+)");
        if year and month and day then
            local fileDate = os.time({year = tonumber(year), month = tonumber(month), day = tonumber(day)});
            if fileDate < cutoffTime then
                ParaIO.DeleteFile(filepath);
                deletedCount = deletedCount + 1;
            end
        end
    end
    
    if deletedCount > 0 then
        LOG.std(nil, "info", "ChatLogUtil", "Cleaned up %d old log files", deletedCount);
    end
end

-- Write a session header to the log file (VS Code Copilot style)
-- Called automatically when a new session is first logged
-- @param sessionId: unique session identifier
-- @param filepath: path to the log file
function ChatLogUtil.WriteSessionHeader(sessionId, filepath)
    if not sessionId or ChatLogUtil.writtenSessionHeaders[sessionId] then
        return;
    end
    
    -- Mark session as having header written
    ChatLogUtil.writtenSessionHeaders[sessionId] = true;
    
    -- Create session header similar to VS Code format: # agentType - sessionId
    local shortId = sessionId:match("_(%d+)$") or sessionId:sub(-8);
    local header = string.format("# Session - %s\n\n", shortId);
    
    local file = ParaIO.open(filepath, "a");
    if file:IsValid() then
        file:WriteString(header);
        file:close();
    end
end

-- Append raw text directly to the current log file.
-- Used by the JS side (BackgroundAgent.js) to write pre-formatted log entries
-- via the appendChatLog NPL message without any additional formatting.
-- @param text: string to append as-is to the current log file
function ChatLogUtil.AppendToFile(text)
    if not ChatLogUtil.enabled then
        return;
    end

    if not ChatLogUtil.initialized then
        ChatLogUtil.Init();
    end

    ChatLogUtil.CheckRotation();

    local filepath = ChatLogUtil.GetCurrentFilePath();
    if not filepath then
        LOG.std(nil, "warn", "ChatLogUtil", "AppendToFile: no valid log file path available");
        return;
    end

    if not ParaIO.DoesFileExist(filepath) then
        ParaIO.CreateDirectory(filepath);
    end

    local file = ParaIO.open(filepath, "a");
    if file:IsValid() then
        file:WriteString(text);
        file:close();
    else
        LOG.std(nil, "warn", "ChatLogUtil", "AppendToFile: failed to open log file: %s", filepath);
    end
end

-- Write a Markdown entry to the log file
-- @param entryType: type of entry ("request", "response", "tool_result", "summary")
-- @param metadata: table of metadata key-value pairs
-- @param messages: optional array of {role, content} for request messages
function ChatLogUtil.WriteMarkdownEntry(entryType, metadata, messages)
    if not ChatLogUtil.enabled then
        return;
    end
    
    if not ChatLogUtil.initialized then
        ChatLogUtil.Init();
    end
    
    -- Check if rotation is needed
    ChatLogUtil.CheckRotation();
    
    local filepath = ChatLogUtil.GetCurrentFilePath();
    if not filepath then
        LOG.std(nil, "warn", "ChatLogUtil", "No valid log file path available");
        return;
    end
    print("Logging to file: " .. filepath);
    if not ParaIO.DoesFileExist(filepath) then
        -- Create new file
        print("Creating new log file: " .. filepath);
        ParaIO.CreateDirectory(filepath);
    end
    
    -- Write session header if this is a new session (VS Code Copilot style)
    local sessionId = metadata and metadata.sessionId;
    if sessionId and entryType == "request" then
        ChatLogUtil.WriteSessionHeader(sessionId, filepath);
    end
    
    -- Build markdown content
    local lines = {};
    
    -- Metadata section
    table.insert(lines, "## Metadata");
    table.insert(lines, "~~~");
    
    -- Add type and timestamp
    table.insert(lines, ChatLogUtil.FormatMetadataLine("type", entryType));
    table.insert(lines, ChatLogUtil.FormatMetadataLine("timestamp", ChatLogUtil.GetISOTimestamp()));
    table.insert(lines, ChatLogUtil.FormatMetadataLine("epoch", os.time()));
    
    -- Add custom metadata (exclude special _collapsible_* keys, add tools last)
    local collapsibleTools = nil;
    if metadata then
        for key, value in pairs(metadata) do
            if key == "_collapsible_tools" then
                collapsibleTools = value;
            else
                table.insert(lines, ChatLogUtil.FormatMetadataLine(key, value));
            end
        end
    end
    
    table.insert(lines, "~~~");
    
    -- Add collapsible tools section AFTER metadata block (renders as HTML in Markdown)
    if collapsibleTools and #collapsibleTools > 0 then
        local beautified = commonlib.Json.Beautify(collapsibleTools) or "[]";
        beautified = beautified:gsub("\\r", "");
        table.insert(lines, string.format("<details>\n<summary>tools (%d)</summary>\n\n```json\n%s\n```\n</details>", 
            #collapsibleTools, beautified));
    end
    
    -- Messages section
    if messages and #messages > 0 then
        -- Use appropriate section title based on entry type (GitHub Copilot style)
        local sectionTitle = (entryType == "response") and "## Response" or "## Request Messages";
        table.insert(lines, sectionTitle);
        for _, msg in ipairs(messages) do
            if msg and msg.role then
                local formattedContent = ChatLogUtil.FormatMessageBlock(msg.role, msg.content, msg.toolCallsContent, msg.toolMeta)
                if formattedContent and formattedContent ~= "" then
                    table.insert(lines, formattedContent);
                end
            end
        end
    end
    
    -- Join all lines
    local content = table.concat(lines, "\n");
    
    -- Append to file with separator
    local file = ParaIO.open(filepath, "a");
    if file:IsValid() then
        file:WriteString(content .. "\n\n---\n\n");
        file:close();
    else
        LOG.std(nil, "warn", "ChatLogUtil", "Failed to write to log file: %s", filepath);
    end
end

-- Legacy function for backward compatibility (redirects to WriteMarkdownEntry)
-- @param entry: table to be written as JSON
function ChatLogUtil.WriteJsonEntry(entry)
    local entryType = entry.type or "unknown";
    local metadata = {};
    for k, v in pairs(entry) do
        if k ~= "type" then
            metadata[k] = v;
        end
    end
    ChatLogUtil.WriteMarkdownEntry(entryType, metadata, nil);
end

-- Log an AI chat request
-- @param sessionId: unique session identifier
-- @param logParams: table containing messages, model, tools, etc.
function ChatLogUtil.LogRequest(sessionId, logParams)
    if not ChatLogUtil.enabled then
        return;
    end
    
    -- Track start time for this request (VS Code style timing)
    local startTime = os.time();
    local startTimeMs = ParaGlobal.timeGetTime();
    ChatLogUtil.requestStartTimes[sessionId] = {
        time = startTime,
        timeMs = startTimeMs,
        isoTime = ChatLogUtil.GetISOTimestamp(),
    };
    
    local messages = logParams.messages or {};
    local tools = logParams.localTools or {};
    
    -- Build metadata (VS Code Copilot style ordering)
    local metadata = {
        sessionId = sessionId or "unknown",
        model = logParams.model or "unknown",
        stream = logParams.stream or false,
        dataStreaming = logParams.dataStreaming or false,
    };

    if logParams.reasoning ~= nil then
        metadata.reasoning = logParams.reasoning;
    end
    
    -- Add tool information (VS Code style: tools in collapsible, toolNames separate)
    if tools and #tools > 0 then
        local toolNames = {};
        for _, tool in ipairs(tools) do
            if tool.function_info and tool.function_info.name then
                table.insert(toolNames, tool.function_info.name);
            elseif tool["function"] and tool["function"].name then
                table.insert(toolNames, tool["function"].name);
            end
        end
        metadata.toolCount = #tools;
        metadata.toolNames = toolNames;
        -- Mark tools for collapsible rendering
        metadata._collapsible_tools = tools;
    end
    
    -- Add optional fields if present
    if logParams.knowledgeUsername and logParams.knowledgeUsername ~= "" then
        metadata.knowledgeUsername = logParams.knowledgeUsername;
    end
    if logParams.knowledgeBaseCodes and #logParams.knowledgeBaseCodes > 0 then
        metadata.knowledgeBaseCodes = logParams.knowledgeBaseCodes;
    end
    
    -- Build tool_call_id -> tool_name lookup from assistant messages
    local toolCallIdToName = {};
    for _, msg in ipairs(messages) do
        if msg.role == "assistant" and msg.tool_calls then
            for _, tc in ipairs(msg.tool_calls) do
                if tc.id and tc["function"] and tc["function"].name then
                    toolCallIdToName[tc.id] = tc["function"].name;
                end
            end
        end
    end
    
    -- Build message array with proper role names
    local formattedMessages = {};
    for i, msg in ipairs(messages) do
        local role = msg.role or "unknown";
        -- Capitalize first letter for display
        role = role:sub(1,1):upper() .. role:sub(2);
        
        local hasToolCalls = msg.role == "assistant" and msg.tool_calls and #msg.tool_calls > 0;
        local hasContent = msg.content and msg.content ~= "";
        
        -- Merge tool_calls into Assistant block (GitHub Copilot style)
        local toolCallsContentStr = nil;
        if hasToolCalls then
            local toolCallsJson = commonlib.Json.Encode(msg.tool_calls) or "[]";
            toolCallsContentStr = commonlib.Json.Beautify(toolCallsJson) or toolCallsJson;
        end
        
        -- For tool role messages, include tool_call_id and resolved name (GitHub Copilot style)
        local toolMeta = nil;
        if msg.role == "tool" and msg.tool_call_id then
            toolMeta = {
                tool_call_id = msg.tool_call_id,
                name = toolCallIdToName[msg.tool_call_id],
            };
        end
        
        table.insert(formattedMessages, {
            role = role,
            content = hasContent and msg.content or nil,
            toolCallsContent = toolCallsContentStr,
            toolMeta = toolMeta,
        });
    end
    
    ChatLogUtil.WriteMarkdownEntry("request", metadata, formattedMessages);
end

-- Log an AI chat response
-- @param sessionId: unique session identifier
-- @param resultCode: HTTP result code
-- @param fullResult: full response text
-- @param fullThink: full thinking/reasoning text
-- @param toolCalls: optional tool calls array
-- @param usage: optional usage statistics {prompt_tokens, completion_tokens, total_tokens}
-- @param errorDetail: optional transport/server error detail string
-- @param extraMetadata: optional metadata table to merge into response metadata
function ChatLogUtil.LogResponse(sessionId, resultCode, fullResult, fullThink, toolCalls, usage, errorDetail, extraMetadata)
    if not ChatLogUtil.enabled then
        return;
    end
    
    -- Calculate duration from stored start time (VS Code style timing)
    local duration = nil;
    local startTime = ChatLogUtil.requestStartTimes[sessionId];
    if startTime then
        local endTimeMs = ParaGlobal.timeGetTime();
        duration = endTimeMs - startTime.timeMs;
        -- Clean up stored start time
        ChatLogUtil.requestStartTimes[sessionId] = nil;
    end
    
    -- Build metadata (VS Code Copilot style)
    local metadata = {
        sessionId = sessionId or "unknown",
        resultCode = resultCode,
        thinkingLength = fullThink and #fullThink or 0,
        responseLength = fullResult and #fullResult or 0,
    };

    if errorDetail and errorDetail ~= "" then
        metadata.errorDetail = errorDetail;
    end
    
    -- Add timing info (VS Code style: duration in ms)
    if duration then
        metadata.duration = string.format("%dms", duration);
    end
    
    -- Add usage/token statistics if available (VS Code style)
    if usage then
        metadata.usage = usage;
    end

    if type(extraMetadata) == "table" then
        for key, value in pairs(extraMetadata) do
            if value ~= nil and value ~= "" then
                metadata[key] = value;
            end
        end
    end
    
    if toolCalls and #toolCalls > 0 then
        metadata.toolCallCount = #toolCalls;
        -- Store tool call IDs for reference
        local toolCallIds = {};
        for _, tc in ipairs(toolCalls) do
            if tc.id then
                table.insert(toolCallIds, tc.id);
            end
        end
        metadata.toolCallIds = toolCallIds;
    end
    
    -- Build response messages
    local messages = {};
    
    -- Add thinking block if present
    if fullThink and fullThink ~= "" then
        table.insert(messages, {
            role = "Assistant (Thinking)",
            content = fullThink,
        });
    end
    
    -- Prepare tool calls content if present
    local toolCallsContentStr = nil;
    if toolCalls and #toolCalls > 0 then
        local toolCallsJson = commonlib.Json.Encode(toolCalls) or "[]";
        toolCallsContentStr = commonlib.Json.Beautify(toolCallsJson) or toolCallsJson;
    end
    
    -- Add response block (merge tool calls into Assistant block, GitHub Copilot style)
    if fullResult and fullResult ~= "" then
        table.insert(messages, {
            role = "Assistant",
            content = fullResult,
            toolCallsContent = toolCallsContentStr,
        });
        toolCallsContentStr = nil; -- consumed
    elseif resultCode and resultCode ~= 200 then
        table.insert(messages, {
            role = "Assistant (Error)",
            content = errorDetail or string.format("LLM request failed with code %s", tostring(resultCode)),
        });
    end
    
    -- If tool calls weren't consumed (no text content + no error), create Assistant block with only tool calls
    if toolCallsContentStr then
        table.insert(messages, {
            role = "Assistant",
            toolCallsContent = toolCallsContentStr,
        });
    end
    
    ChatLogUtil.WriteMarkdownEntry("response", metadata, messages);
end

-- Log a tool execution result (formatted as Tool Call block with Request and Response sections)
-- @param sessionId: unique session identifier
-- @param toolName: name of the tool
-- @param toolCallId: tool call ID
-- @param args: arguments passed to the tool
-- @param result: result returned by the tool
function ChatLogUtil.LogToolResult(sessionId, toolName, toolCallId, args, result)
    if not ChatLogUtil.enabled then
        return;
    end
    
    if not ChatLogUtil.initialized then
        ChatLogUtil.Init();
    end
    
    -- Check if rotation is needed
    ChatLogUtil.CheckRotation();
    
    local filepath = ChatLogUtil.GetCurrentFilePath();
    if not filepath then
        LOG.std(nil, "warn", "ChatLogUtil", "No valid log file path available");
        return;
    end
    
    -- Format args as beautified JSON string (VS Code Copilot style)
    local argsStr;
    if type(args) == "table" then
        local jsonStr = commonlib.Json.Encode(args) or "{}";
        argsStr = commonlib.Json.Beautify(jsonStr) or jsonStr;
    else
        argsStr = tostring(args or "{}");
    end
    
    -- Format result as string (beautify if JSON-like)
    local resultStr;
    if type(result) == "table" then
        local jsonStr = commonlib.Json.Encode(result) or "{}";
        resultStr = commonlib.Json.Beautify(jsonStr) or commonlib.serialize_compact(result) or "{}";
    elseif type(result) == "string" then
        -- Try to beautify if it looks like JSON
        if result:match("^%s*{.*}%s*$") or result:match("^%s*%[.*%]%s*$") then
            local beautified = commonlib.Json.Beautify(result);
            resultStr = beautified or result;
        else
            resultStr = result;
        end
    else
        resultStr = tostring(result or "");
    end
    
    -- Build Tool Call block content (VS Code Copilot style)
    local lines = {};
    table.insert(lines, string.format("# Tool Call - %s", toolCallId or toolName));
    table.insert(lines, "");
    table.insert(lines, "## Request");
    table.insert(lines, "~~~");
    table.insert(lines, string.format("id   : %s", toolCallId or "unknown"));
    table.insert(lines, string.format("name : %s", toolName or "unknown"));
    table.insert(lines, "~~~");
    table.insert(lines, "### Arguments");
    table.insert(lines, "~~~json");
    table.insert(lines, argsStr);
    table.insert(lines, "~~~");
    table.insert(lines, "");
    table.insert(lines, "## Response");
    table.insert(lines, "~~~");
    table.insert(lines, resultStr);
    table.insert(lines, "~~~");
    
    local content = table.concat(lines, "\n");
    
    -- Append to file with separator
    local file = ParaIO.open(filepath, "a");
    if file:IsValid() then
        file:WriteString(content .. "\n\n---\n\n");
        file:close();
    else
        LOG.std(nil, "warn", "ChatLogUtil", "Failed to write to log file: %s", filepath);
    end
end

-- Track pending tool calls for GitHub Copilot style logging
-- {[sessionId] = {[toolName] = {startTime, callId, args}}}
ChatLogUtil.pendingToolCalls = {};

--[[
    Log the start of a tool call (GitHub Copilot style)
    Shows: ⏳ Calling tool_name...
    @param sessionId: unique session identifier
    @param toolName: name of the tool being called
    @param argsStr: JSON string of arguments (optional)
]]
function ChatLogUtil.LogToolCallStart(sessionId, toolName, argsStr)
    if not ChatLogUtil.enabled then
        return;
    end
    
    -- Track pending tool call
    ChatLogUtil.pendingToolCalls[sessionId] = ChatLogUtil.pendingToolCalls[sessionId] or {};
    ChatLogUtil.pendingToolCalls[sessionId][toolName] = {
        startTime = ParaGlobal.timeGetTime(),
        argsStr = argsStr,
    };
    
    if not ChatLogUtil.initialized then
        ChatLogUtil.Init();
    end
    
    ChatLogUtil.CheckRotation();
    local filepath = ChatLogUtil.GetCurrentFilePath();
    if not filepath then return; end
    
    -- Format: ⏳ Calling tool_name...
    local lines = {};
    table.insert(lines, string.format("⏳ **Calling** `%s`...", toolName or "unknown"));
    
    -- Add arguments in collapsible block if present
    if argsStr and argsStr ~= "" and argsStr ~= "{}" then
        local beautified = argsStr;
        if type(argsStr) == "string" then
            local parsed = {};
            if NPL.FromJson(argsStr, parsed) then
                beautified = commonlib.Json.Beautify(argsStr) or argsStr;
            end
        end
        table.insert(lines, "<details>");
        table.insert(lines, "<summary>Arguments</summary>");
        table.insert(lines, "");
        table.insert(lines, "```json");
        table.insert(lines, beautified);
        table.insert(lines, "```");
        table.insert(lines, "</details>");
    end
    
    local content = table.concat(lines, "\n");
    
    local file = ParaIO.open(filepath, "a");
    if file:IsValid() then
        file:WriteString(content .. "\n\n");
        file:close();
    end
end

--[[
    Log the completion of a tool call (GitHub Copilot style)
    Shows: ✓ tool_name (123ms) or ✗ tool_name (error)
    @param sessionId: unique session identifier
    @param toolName: name of the tool
    @param callId: tool call ID
    @param status: "success" or "error"
    @param result: result content string
    @param duration: execution duration in milliseconds (optional, auto-calculated if not provided)
]]
function ChatLogUtil.LogToolCallEnd(sessionId, toolName, callId, status, result, duration)
    if not ChatLogUtil.enabled then
        return;
    end
    
    -- Get tracked start time if duration not provided
    if not duration then
        local pending = ChatLogUtil.pendingToolCalls[sessionId] and ChatLogUtil.pendingToolCalls[sessionId][toolName];
        if pending and pending.startTime then
            duration = ParaGlobal.timeGetTime() - pending.startTime;
        end
    end
    
    -- Clean up pending tracking
    if ChatLogUtil.pendingToolCalls[sessionId] then
        ChatLogUtil.pendingToolCalls[sessionId][toolName] = nil;
        if not next(ChatLogUtil.pendingToolCalls[sessionId]) then
            ChatLogUtil.pendingToolCalls[sessionId] = nil;
        end
    end
    
    if not ChatLogUtil.initialized then
        ChatLogUtil.Init();
    end
    
    ChatLogUtil.CheckRotation();
    local filepath = ChatLogUtil.GetCurrentFilePath();
    if not filepath then return; end
    
    -- Status icon and format
    local icon = status == "error" and "✗" or "✓";
    local durationStr = duration and string.format(" (%dms)", duration) or "";
    
    local lines = {};
    
    -- Header line: ✓ tool_name (123ms) or ✗ tool_name (error)
    if status == "error" then
        table.insert(lines, string.format("%s **%s** (error)%s", icon, toolName or "unknown", durationStr));
    else
        table.insert(lines, string.format("%s **%s**%s", icon, toolName or "unknown", durationStr));
    end
    
    -- Result in collapsible block
    if result and result ~= "" then
        -- Try to detect if result is JSON-like for syntax highlighting
        local isJson = result:match("^%s*{") or result:match("^%s*%[");
        local syntaxType = isJson and "json" or "";
        
        -- Truncate very long results for display
        local displayResult = result;
        local wasTruncated = false;
        if #displayResult > 2000 then
            displayResult = displayResult:sub(1, 2000);
            wasTruncated = true;
        end
        
        table.insert(lines, "<details>");
        table.insert(lines, string.format("<summary>Result (%d chars%s)</summary>", #result, wasTruncated and ", truncated" or ""));
        table.insert(lines, "");
        table.insert(lines, string.format("```%s", syntaxType));
        table.insert(lines, displayResult);
        if wasTruncated then
            table.insert(lines, "... [truncated]");
        end
        table.insert(lines, "```");
        table.insert(lines, "</details>");
    end
    
    local content = table.concat(lines, "\n");
    
    local file = ParaIO.open(filepath, "a");
    if file:IsValid() then
        file:WriteString(content .. "\n\n---\n\n");
        file:close();
    end
end

-- Log dialog summary (from DialogHistoryManager)
-- @param sessionId: unique session identifier
-- @param originalMessages: array of messages that were summarized
-- @param summaryResult: the generated summary text
-- @param summaryType: "llm" or "fallback"
-- @param density: optional keyword density value
function ChatLogUtil.LogSummary(sessionId, originalMessages, summaryResult, summaryType, density)
    if not ChatLogUtil.enabled then
        return;
    end
    
    -- Build metadata
    local metadata = {
        sessionId = sessionId or "unknown",
        summaryType = summaryType or "unknown",
        originalMessageCount = originalMessages and #originalMessages or 0,
        summaryLength = summaryResult and #summaryResult or 0,
    };
    
    if density then
        metadata.density = density;
    end
    
    -- Include preview info of original messages
    if originalMessages and #originalMessages > 0 then
        local previews = {};
        for i = 1, math.min(3, #originalMessages) do
            local msg = originalMessages[i];
            table.insert(previews, {
                role = msg.role,
                contentLength = msg.content and #msg.content or 0,
            });
        end
        metadata.originalMessagePreviews = previews;
    end
    
    -- Build summary message
    local messages = {
        {
            role = "Summary",
            content = summaryResult or "",
        }
    };
    
    ChatLogUtil.WriteMarkdownEntry("summary", metadata, messages);
end

-- Generate a unique session ID
function ChatLogUtil.GenerateSessionId()
    return string.format("%s_%d_%d", os.date("%H%M%S"), os.time(), math.random(10000, 99999));
end

-- Get log directory path
function ChatLogUtil.GetLogDir()
    return ParaIO.GetWritablePath() .. ChatLogUtil.logDir;
end

-- Get list of all log files
function ChatLogUtil.GetLogFiles()
    local basePath = ChatLogUtil.GetLogDir();
    local files = {};
    
    local search_result = ParaIO.SearchFiles(basePath, "chat_*.copilotmd", "", 0, 1000, 0);
    local nCount = search_result:GetNumOfResult();
    
    for i = 0, nCount - 1 do
        local filename = search_result:GetItem(i);
        table.insert(files, {
            name = filename,
            path = basePath .. filename,
            size = ChatLogUtil.GetFileSize(basePath .. filename),
        });
    end
    
    -- Sort by name (which includes date)
    table.sort(files, function(a, b) return a.name > b.name end);
    
    return files;
end

-- Get list of available log dates (for UI display)
-- @return array of {date="YYYY-MM-DD", fileCount=N, totalSize=N}
function ChatLogUtil.GetAvailableDates()
    local basePath = ChatLogUtil.GetLogDir();
    local dateMap = {};
    
    local search_result = ParaIO.SearchFiles(basePath, "chat_*.copilotmd", "", 0, 1000, 0);
    local nCount = search_result:GetNumOfResult();
    
    for i = 0, nCount - 1 do
        local filename = search_result:GetItem(i);
        local year, month, day = filename:match("chat_(%d+)-(%d+)-(%d+)");
        if year and month and day then
            local dateStr = string.format("%s-%s-%s", year, month, day);
            if not dateMap[dateStr] then
                dateMap[dateStr] = {date = dateStr, fileCount = 0, totalSize = 0};
            end
            dateMap[dateStr].fileCount = dateMap[dateStr].fileCount + 1;
            dateMap[dateStr].totalSize = dateMap[dateStr].totalSize + ChatLogUtil.GetFileSize(basePath .. filename);
        end
    end
    
    -- Convert to array and sort by date descending
    local result = {};
    for _, info in pairs(dateMap) do
        table.insert(result, info);
    end
    table.sort(result, function(a, b) return a.date > b.date end);
    
    return result;
end

-- Parse a single Markdown entry block into a structured table
-- @param block: string containing one log entry (between --- separators)
-- @return entry table or nil if parsing failed
function ChatLogUtil.ParseMarkdownEntry(block)
    if not block or block == "" then
        return nil;
    end
    
    local entry = {
        messages = {},
    };
    
    -- Parse metadata section (between first ~~~ pair after ## Metadata)
    local metadataContent = block:match("## Metadata%s*\n~~~%s*\n(.-)~~~");
    if metadataContent then
        -- Parse each line as key: value
        for line in metadataContent:gmatch("[^\n]+") do
            local key, value = line:match("^(%S+)%s*:%s*(.+)$");
            if key and value then
                key = key:gsub("%s+$", ""); -- trim trailing spaces from key
                value = value:gsub("^%s+", ""):gsub("%s+$", ""); -- trim value
                
                -- Try to parse as JSON first (for arrays/objects)
                if value:match("^%[") or value:match("^{") then
                    local parsed = {};
                    if NPL.FromJson(value, parsed) then
                        entry[key] = parsed;
                    else
                        entry[key] = value;
                    end
                -- Try to parse as number
                elseif tonumber(value) then
                    entry[key] = tonumber(value);
                -- Parse boolean
                elseif value == "true" then
                    entry[key] = true;
                elseif value == "false" then
                    entry[key] = false;
                elseif value == "undefined" or value == "nil" then
                    entry[key] = nil;
                else
                    entry[key] = value;
                end
            end
        end
    end
    
    -- Parse message sections (### Role followed by ~~~md ... ~~~)
    for role, content in block:gmatch("### ([^\n]+)\n~~~md\n(.-)~~~") do
        table.insert(entry.messages, {
            role = role,
            content = content,
        });
    end
    
    return entry;
end

-- Read log entries for a specific date
-- @param dateStr: date string in "YYYY-MM-DD" format, nil for today
-- @param options: optional table {limit=N, offset=N, type="request|response|tool_result"}
-- @return {entries=array, totalCount=N, hasMore=bool}
function ChatLogUtil.ReadLogsByDate(dateStr, options)
    dateStr = dateStr or ChatLogUtil.GetDateString();
    options = options or {};
    local limit = options.limit or 100;
    local offset = options.offset or 0;
    local filterType = options.type;
    
    local basePath = ChatLogUtil.GetLogDir();
    local allEntries = {};
    
    -- Find all files for this date
    local search_result = ParaIO.SearchFiles(basePath, "chat_" .. dateStr .. "*.copilotmd", "", 0, 100, 0);
    local nCount = search_result:GetNumOfResult();
    
    -- Collect all file paths for this date
    local filePaths = {};
    for i = 0, nCount - 1 do
        local filename = search_result:GetItem(i);
        table.insert(filePaths, basePath .. filename);
    end
    
    -- Sort files by name to ensure correct order
    table.sort(filePaths);
    
    -- Read and parse each file
    for _, filepath in ipairs(filePaths) do
        local file = ParaIO.open(filepath, "r");
        if file:IsValid() then
            local content = file:GetText();
            file:close();
            
            if content and content ~= "" then
                -- Split by separator (--- with optional surrounding whitespace/newlines)
                local parts = {};
                for part in content:gmatch("(.-)%s*%-%-%-") do
                    if part and part:match("%S") then
                        table.insert(parts, part);
                    end
                end
                
                -- Parse each Markdown entry
                for _, mdBlock in ipairs(parts) do
                    local entry = ChatLogUtil.ParseMarkdownEntry(mdBlock);
                    if entry and entry.type then
                        -- Apply type filter if specified
                        if not filterType or entry.type == filterType then
                            table.insert(allEntries, entry);
                        end
                    end
                end
            end
        end
    end
    
    -- Sort by epoch timestamp (newest first)
    table.sort(allEntries, function(a, b) 
        return (a.epoch or 0) > (b.epoch or 0);
    end);
    
    local totalCount = #allEntries;
    local hasMore = (offset + limit) < totalCount;
    
    -- Apply pagination
    local pagedEntries = {};
    for i = offset + 1, math.min(offset + limit, totalCount) do
        table.insert(pagedEntries, allEntries[i]);
    end
    
    return {
        entries = pagedEntries,
        totalCount = totalCount,
        hasMore = hasMore,
        date = dateStr,
        offset = offset,
        limit = limit,
    };
end

-- Read a single session's complete log (request + response + tool results)
-- @param sessionId: session identifier to search for
-- @param dateStr: optional date string, searches today if nil
-- @return array of entries for this session in chronological order
function ChatLogUtil.ReadSessionLog(sessionId, dateStr)
    if not sessionId then
        return {};
    end
    
    local result = ChatLogUtil.ReadLogsByDate(dateStr, {limit = 10000});
    local sessionEntries = {};
    
    for _, entry in ipairs(result.entries) do
        if entry.sessionId == sessionId then
            table.insert(sessionEntries, entry);
        end
    end
    
    -- Sort chronologically (oldest first for session view)
    table.sort(sessionEntries, function(a, b)
        return (a.epoch or 0) < (b.epoch or 0);
    end);
    
    return sessionEntries;
end

-- Get statistics for a specific date
-- @param dateStr: date string in "YYYY-MM-DD" format, nil for today
-- @param entries: optional pre-loaded entries array (to avoid re-reading files)
-- @return {requestCount, responseCount, toolResultCount, totalEntries, uniqueSessions, successRate}
function ChatLogUtil.GetDateStats(dateStr, entries)
    local totalCount;
    if entries then
        totalCount = #entries;
    else
        local result = ChatLogUtil.ReadLogsByDate(dateStr, {limit = 100000});
        entries = result.entries;
        totalCount = result.totalCount;
    end
    
    local stats = {
        date = dateStr or ChatLogUtil.GetDateString(),
        requestCount = 0,
        responseCount = 0,
        toolResultCount = 0,
        totalEntries = totalCount,
        uniqueSessions = 0,
        successCount = 0,
        errorCount = 0,
    };
    
    local sessionSet = {};
    
    for _, entry in ipairs(entries) do
        if entry.type == "request" then
            stats.requestCount = stats.requestCount + 1;
        elseif entry.type == "response" then
            stats.responseCount = stats.responseCount + 1;
            if entry.resultCode == 200 then
                stats.successCount = stats.successCount + 1;
            else
                stats.errorCount = stats.errorCount + 1;
            end
        elseif entry.type == "tool_result" then
            stats.toolResultCount = stats.toolResultCount + 1;
        end
        
        if entry.sessionId then
            sessionSet[entry.sessionId] = true;
        end
    end
    
    -- Count unique sessions
    for _ in pairs(sessionSet) do
        stats.uniqueSessions = stats.uniqueSessions + 1;
    end
    
    -- Calculate success rate
    if stats.responseCount > 0 then
        stats.successRate = math.floor(stats.successCount / stats.responseCount * 100);
    else
        stats.successRate = 0;
    end
    
    return stats;
end

-- Export logs for a date to a single beautified JSON file
-- @param dateStr: date string, nil for today
-- @param outputPath: optional output file path
-- @return output file path or nil on failure
function ChatLogUtil.ExportToFile(dateStr, outputPath)
    dateStr = dateStr or ChatLogUtil.GetDateString();
    outputPath = outputPath or (ParaIO.GetWritablePath() .. "temp/chat_export_" .. dateStr .. ".json");
    
    local result = ChatLogUtil.ReadLogsByDate(dateStr, {limit = 100000});
    
    local exportData = {
        exportDate = os.date("%Y-%m-%d %H:%M:%S"),
        logDate = dateStr,
        stats = ChatLogUtil.GetDateStats(dateStr, result.entries),
        entries = result.entries,
    };
    
    local jsonStr = commonlib.Json.Encode(exportData);
    if jsonStr then
        jsonStr = commonlib.Json.Beautify(jsonStr) or jsonStr;
    else
        return nil;
    end
    
    local file = ParaIO.open(outputPath, "w");
    if file:IsValid() then
        file:WriteString(jsonStr);
        file:close();
        LOG.std(nil, "info", "ChatLogUtil", "Exported %d entries to: %s", #result.entries, outputPath);
        return outputPath;
    end
    
    return nil;
end

return ChatLogUtil;
