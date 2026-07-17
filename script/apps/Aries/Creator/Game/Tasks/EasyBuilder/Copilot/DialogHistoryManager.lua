--[[
Title: Dialog History Manager
Author(s): AI Assistant
Date: 2026/1/29
Desc: Manages dialog history with LLM-based summarization for context compression.
Supports multi-instance usage, keyword density evaluation, and async summarization.

Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/DialogHistoryManager.lua");
local DialogHistoryManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.DialogHistoryManager");
local manager = DialogHistoryManager:new():Init();
manager:SetAISession(aiSession);
manager:AddMessage("user", "Hello");
local context = manager:GetFormattedContext();
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/AIChat.lua");
local AIChat = commonlib.gettable("MyCompany.Aries.Game.Common.AIChat");

local DialogHistoryManager = commonlib.inherit(
    commonlib.gettable("System.Core.ToolBase"),
    commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.DialogHistoryManager")
);

DialogHistoryManager:Property("Name", "DialogHistoryManager");

-- Configuration properties with defaults (balanced token efficiency vs accuracy)
DialogHistoryManager:Property({"MaxHistoryLength", 15, "GetMaxHistoryLength", "SetMaxHistoryLength", auto=true});  -- Reduced from 20 (was 12)
DialogHistoryManager:Property({"KeepRecentCount", 4, "GetKeepRecentCount", "SetKeepRecentCount", auto=true});      -- Reduced from 5 (was 3)
DialogHistoryManager:Property({"MaxSummaryLength", 1000, "GetMaxSummaryLength", "SetMaxSummaryLength", auto=true}); -- Reduced from 1500 (was 800)
DialogHistoryManager:Property({"MinKeywordDensity", 0.15, "GetMinKeywordDensity", "SetMinKeywordDensity", auto=true}); -- Lowered from 0.25 to 0.15
DialogHistoryManager:Property({"Language", "zh", "GetLanguage", "SetLanguage", auto=true}); -- "zh" or "en"

-- Signals
DialogHistoryManager:Signal("summaryCompleted"); -- (summary: string)
DialogHistoryManager:Signal("densityWarning");   -- (density: number, threshold: number)

--[[
    Constructor - Initialize instance state
]]
function DialogHistoryManager:ctor()
    -- Dialog history array: {role, content, timestamp}
    self.dialogHistory = {};
    
    -- Compressed summary of older dialogs
    self.dialogSummary = nil;
    
    -- Pending summary from async LLM call (applied on next GetFormattedContext)
    self.pendingSummary = nil;
    
    -- Flag to prevent recursive summarization
    self.isSummarizing = false;
    
    -- Independent AI session for summarization (created lazily)
    -- Using separate instance to avoid conflicts with main dialog aiSession
    self.summaryAISession = nil;
    
    -- Chinese stop words for keyword filtering
    self.stopWords = {
        "的", "了", "是", "在", "和", "有", "我", "你", "他", "她", "它",
        "这", "那", "就", "也", "都", "很", "着", "过", "吧", "呢", "啊",
        "吗", "把", "被", "与", "及", "等", "到", "从", "对", "为", "以",
        "可", "能", "会", "要", "让", "给", "用", "做", "去", "来", "上",
        "下", "中", "个", "些", "里", "时", "说", "看", "想", "知", "道",
    };
    
    -- Convert to lookup table for O(1) access
    self.stopWordsLookup = {};
    for _, word in ipairs(self.stopWords) do
        self.stopWordsLookup[word] = true;
    end
end

--[[
    Initialize the manager
    @return self for chaining
]]
function DialogHistoryManager:Init()
    LOG.std(nil, "info", "DialogHistoryManager", "Initialized (maxHistory=%d, keepRecent=%d)", 
        self:GetMaxHistoryLength(), self:GetKeepRecentCount());
    return self;
end

--[[
    Get or create the independent AI session for summarization
    @return AIChat instance
]]
function DialogHistoryManager:GetSummaryAISession()
    if not self.summaryAISession then
        self.summaryAISession = AIChat:new();
        self.summaryAISession:SetStream(false);  -- Non-streaming for simplicity
        self.summaryAISession:SetAutoHistory(false);  -- No history tracking needed
        -- No tools - pure text summarization
        LOG.std(nil, "info", "DialogHistoryManager", "Created independent AIChat for summarization");
    end
    return self.summaryAISession;
end

--[[
    Add a message to dialog history
    @param role: string - "user" | "assistant" | "system"
    @param content: string - Message content
]]
function DialogHistoryManager:AddMessage(role, content)
    if not role or not content then
        return;
    end
    
    -- Clean tool call markers from content before storing
    -- Remove <|FunctionCallStart|>, <|FunctionCallEnd|> and similar markers
    content = content:gsub("<|[^|]+|>", "");
    
    -- Remove JSON tool call blocks (pattern: {"name": "tool_name", ...})
    content = content:gsub('{"name":%s*"[^"]+"%s*,%s*"parameters":%s*{.-}}', "");
    
    -- Skip empty content
    local trimmedContent = content:match("^%s*(.-)%s*$") or content;
    if #trimmedContent == 0 then
        return;
    end
    
    -- Deduplication: skip if same as last message (same role and content)
    local lastMsg = self.dialogHistory[#self.dialogHistory];
    if lastMsg and lastMsg.role == role and lastMsg.content == trimmedContent then
        LOG.std(nil, "debug", "DialogHistoryManager", "Skipped duplicate message: %s", 
            string.sub(trimmedContent, 1, 50));
        return;
    end
    
    table.insert(self.dialogHistory, {
        role = role,
        content = trimmedContent,
        timestamp = os.time(),
    });
    
    -- Check if summarization is needed
    if #self.dialogHistory > self:GetMaxHistoryLength() then
        self:SummarizeIfNeeded();
    end
end

--[[
    Get formatted dialog context for LLM prompt
    Applies pending summary before returning
    Adds weight markers to indicate history is for reference only
    @return string - Markdown formatted context
]]
function DialogHistoryManager:GetFormattedContext()
    -- Apply any pending summary first
    self:ApplyPendingSummary();
    
    local context = "";
    local hasContent = false;
    
    -- Add summary of older interactions (with reference marker)
    if self.dialogSummary and #self.dialogSummary > 0 then
        context = context .. "## Previous Session Summary (Reference Only)\n\n";
        context = context .. self.dialogSummary .. "\n\n";
        hasContent = true;
    end
    
    -- Add recent dialog history (with context reference marker)
    if #self.dialogHistory > 0 then
        context = context .. "## Recent Dialog (Context Reference)\n\n";
        for _, msg in ipairs(self.dialogHistory) do
            local roleLabel = msg.role == "user" and "User" or "Assistant";
            context = context .. string.format("**%s:** %s\n\n", roleLabel, msg.content);
        end
        hasContent = true;
    end
    
    -- Add note to prioritize current request
    if hasContent then
        context = context .. "> Note: Above history is for reference only. Prioritize the current user request.\n\n";
    end
    
    return context;
end

--[[
    Clear all history and summary
]]
function DialogHistoryManager:Clear()
    self.dialogHistory = {};
    self.dialogSummary = nil;
    self.pendingSummary = nil;
    self.isSummarizing = false;
    LOG.std(nil, "info", "DialogHistoryManager", "History cleared");
end

--[[
    Get serializable state for persistence
    @return table - State data
]]
function DialogHistoryManager:GetState()
    return {
        dialogHistory = self.dialogHistory,
        dialogSummary = self.dialogSummary,
        language = self:GetLanguage(),
    };
end

--[[
    Restore state from saved data
    @param data: table - Previously saved state
]]
function DialogHistoryManager:SetState(data)
    if not data then return; end
    
    if data.dialogHistory then
        self.dialogHistory = data.dialogHistory;
    end
    
    if data.dialogSummary then
        self.dialogSummary = data.dialogSummary;
    end
    
    if data.language then
        self:SetLanguage(data.language);
    end
    
    LOG.std(nil, "info", "DialogHistoryManager", "State restored (history=%d, hasSummary=%s)", 
        #self.dialogHistory, tostring(self.dialogSummary ~= nil));
end

--[[
    Get current history count
    @return number
]]
function DialogHistoryManager:GetHistoryCount()
    return #self.dialogHistory;
end

--[[
    Check if summarization is in progress
    @return boolean
]]
function DialogHistoryManager:IsSummarizing()
    return self.isSummarizing;
end

--------------------------------------------------------------------------------
-- Internal: Summarization Logic
--------------------------------------------------------------------------------

--[[
    Log messages that will be summarized (for debugging)
    @param messages: table - Array of messages to log
]]
function DialogHistoryManager:LogMessagesToSummarize(messages)
    LOG.std(nil, "info", "DialogHistoryManager", "===== Messages being summarized =====");
    for i, msg in ipairs(messages) do
        -- Truncate long content for log readability
        local content = msg.content or "";
        local preview = content;
        if #content > 200 then
            preview = string.sub(content, 1, 200) .. "...(" .. #content .. " chars total)";
        end
        LOG.std(nil, "info", "DialogHistoryManager", "[%d] %s: %s", i, msg.role or "unknown", preview);
    end
    LOG.std(nil, "info", "DialogHistoryManager", "===== End of messages to summarize =====");
end

--[[
    Check and trigger summarization if needed
    Synchronously trims history, asynchronously generates summary
]]
function DialogHistoryManager:SummarizeIfNeeded()
    local history = self.dialogHistory;
    local keepCount = self:GetKeepRecentCount();
    
    if #history <= keepCount then
        return; -- Nothing to summarize
    end
    
    -- Split into old (to summarize) and recent (to keep)
    local toSummarize = {};
    local toKeep = {};
    
    for i = 1, #history - keepCount do
        table.insert(toSummarize, history[i]);
    end
    
    for i = #history - keepCount + 1, #history do
        table.insert(toKeep, history[i]);
    end
    
    -- Immediately trim history (sync)
    self.dialogHistory = toKeep;
    
    -- Log messages being summarized
    LOG.std(nil, "info", "DialogHistoryManager", "Dialog trimmed: %d messages -> %d kept, %d to summarize",
        #history, #toKeep, #toSummarize);
    self:LogMessagesToSummarize(toSummarize);
    
    -- Trigger async LLM summarization or fallback
    if not self.isSummarizing then
        -- Try to use LLM summarization (will create session if needed)
        self:SummarizeWithLLM(toSummarize);
    else
        -- Use fallback if already summarizing
        local fallbackSummary = self:CreateFallbackSummary(toSummarize);
        self:MergeSummary(fallbackSummary);
        LOG.std(nil, "info", "DialogHistoryManager", "Used fallback summary (already summarizing)");
        LOG.std(nil, "info", "DialogHistoryManager", "Fallback summary result: %s", fallbackSummary or "(empty)");
    end
end

--[[
    Summarize messages using LLM (async)
    @param messages: table - Array of messages to summarize
]]
function DialogHistoryManager:SummarizeWithLLM(messages)
    -- Get or create independent AI session for summarization
    local summarySession = self:GetSummaryAISession();
    if not summarySession then
        LOG.std(nil, "warn", "DialogHistoryManager", "Failed to create summary AI session");
        local fallback = self:CreateFallbackSummary(messages);
        self:MergeSummary(fallback);
        return;
    end
    
    self.isSummarizing = true;
    
    -- Build message text for summarization
    local messageText = "";
    for _, msg in ipairs(messages) do
        messageText = messageText .. string.format("[%s]: %s\n", msg.role, msg.content);
    end
    
    -- Include previous summary for context
    local previousSummary = self.dialogSummary or "";
    
    -- Build prompt based on language
    local prompt;
    if self:GetLanguage() == "zh" then
        prompt = self:BuildChineseSummaryPrompt(messageText, previousSummary);
    else
        prompt = self:BuildEnglishSummaryPrompt(messageText, previousSummary);
    end
    
    LOG.std(nil, "debug", "DialogHistoryManager", "Starting LLM summarization for %d messages", #messages);
    
    -- Store messages for fallback in case of failure
    local messagesForFallback = messages;
    
    -- Make LLM call using independent session
    summarySession:Ask(prompt, function(resultCode, delta, deltaThink, fullResult, fullThink)
        if resultCode then
            self.isSummarizing = false;
            
            if resultCode == 200 and fullResult and #fullResult > 0 then
                -- Success: store as pending summary
                self.pendingSummary = fullResult;
                self:summaryCompleted(fullResult);
                LOG.std(nil, "info", "DialogHistoryManager", "LLM summary completed (%d chars)", #fullResult);
                LOG.std(nil, "info", "DialogHistoryManager", "LLM summary result: %s", fullResult);
            else
                -- Failed: use fallback
                LOG.std(nil, "warn", "DialogHistoryManager", "LLM summarization failed (code=%s), using fallback", 
                    tostring(resultCode));
                local fallback = self:CreateFallbackSummary(messagesForFallback);
                self:MergeSummary(fallback);
            end
        end
    end);
end

--[[
    Build Chinese summary prompt
    @param messageText: string - Messages to summarize
    @param previousSummary: string - Existing summary
    @return string - Prompt for LLM
]]
function DialogHistoryManager:BuildChineseSummaryPrompt(messageText, previousSummary)
    local prompt = [[你是一个对话摘要助手。请将以下对话内容压缩成简洁的摘要。

要求：
1. 只保留与学习任务相关的关键信息：用户的学习请求、学习进度、完成的任务、助手的教学内容
2. 忽略无关的闲聊、背景噪音、与学习任务无关的话题（如金钱、结算、日期等无关内容）
3. 使用简洁的陈述句，避免冗余
4. 摘要长度控制在150字以内
5. 保留学习相关的专有名词、单词、关键概念
6. 不要使用"用户说"、"助手回复"等描述，直接陈述内容
7. 如果对话主要是无关闲聊，只需简单记录"用户进行了闲聊，学习任务暂未推进"

]];
    
    if previousSummary and #previousSummary > 0 then
        prompt = prompt .. "之前的摘要：\n" .. previousSummary .. "\n\n";
        prompt = prompt .. "请将以下新对话内容与之前的摘要合并，生成一个完整的新摘要：\n\n";
    else
        prompt = prompt .. "需要摘要的对话：\n\n";
    end
    
    prompt = prompt .. messageText .. "\n\n请直接输出摘要内容，不要添加任何前缀或解释。";
    
    return prompt;
end

--[[
    Build English summary prompt
    @param messageText: string - Messages to summarize
    @param previousSummary: string - Existing summary
    @return string - Prompt for LLM
]]
function DialogHistoryManager:BuildEnglishSummaryPrompt(messageText, previousSummary)
    local prompt = [[You are a dialog summarization assistant. Compress the following conversation into a concise summary.

Requirements:
1. Only preserve information relevant to the learning task: user's learning requests, progress, completed tasks, teaching content
2. Ignore irrelevant chatter, background noise, off-topic discussions (like money, settlements, unrelated dates)
3. Use concise statements, avoid redundancy
4. Keep summary under 100 words
5. Preserve learning-related proper nouns, vocabulary words, key concepts
6. Don't use "user said", "assistant replied" - state content directly
7. If the dialog is mostly irrelevant chatter, simply note "User engaged in off-topic conversation, learning task not progressed"

]];
    
    if previousSummary and #previousSummary > 0 then
        prompt = prompt .. "Previous summary:\n" .. previousSummary .. "\n\n";
        prompt = prompt .. "Please merge the following new dialog with the previous summary into a complete new summary:\n\n";
    else
        prompt = prompt .. "Dialog to summarize:\n\n";
    end
    
    prompt = prompt .. messageText .. "\n\nOutput the summary directly without any prefix or explanation.";
    
    return prompt;
end

--[[
    Create fallback summary without LLM (simple text extraction)
    @param messages: table - Messages to summarize
    @return string - Simple summary
]]
function DialogHistoryManager:CreateFallbackSummary(messages)
    local keyPoints = {};
    
    for _, msg in ipairs(messages) do
        -- Keep user requests (shorter ones more likely to be commands)
        if msg.role == "user" and #msg.content < 200 then
            table.insert(keyPoints, msg.content);
        end
    end
    
    local summary = "";
    local isEnglish = self:GetLanguage() ~= "zh";
    
    if #keyPoints > 0 then
        -- Limit to 5 most recent key points
        local startIdx = math.max(1, #keyPoints - 4);
        local selectedPoints = {};
        for i = startIdx, #keyPoints do
            table.insert(selectedPoints, keyPoints[i]);
        end
        if isEnglish then
            summary = string.format("[%s] Key interactions: %s", 
                os.date("%H:%M"), 
                table.concat(selectedPoints, "; "));
        else
            summary = string.format("[%s] 关键交互: %s", 
                os.date("%H:%M"), 
                table.concat(selectedPoints, "; "));
        end
    else
        if isEnglish then
            summary = string.format("[%s] %d messages archived", os.date("%H:%M"), #messages);
        else
            summary = string.format("[%s] %d条消息已归档", os.date("%H:%M"), #messages);
        end
    end
    
    return summary;
end

--[[
    Merge new summary with existing (replaces, not appends)
    @param newSummary: string - New summary to merge
]]
function DialogHistoryManager:MergeSummary(newSummary)
    if not newSummary or #newSummary == 0 then
        return;
    end
    
    -- Replace existing summary (not append to avoid infinite growth)
    self.dialogSummary = newSummary;
    
    -- Enforce max length
    local maxLen = self:GetMaxSummaryLength();
    if #self.dialogSummary > maxLen then
        -- Truncate with ellipsis
        self.dialogSummary = string.sub(self.dialogSummary, 1, maxLen - 3) .. "...";
        LOG.std(nil, "debug", "DialogHistoryManager", "Summary truncated to %d chars", maxLen);
    end
end

--------------------------------------------------------------------------------
-- Internal: Keyword Density Evaluation
--------------------------------------------------------------------------------

--[[
    Apply pending summary if available
    Evaluates density and merges into dialogSummary
]]
function DialogHistoryManager:ApplyPendingSummary()
    if not self.pendingSummary then
        return;
    end
    
    local summary = self.pendingSummary;
    self.pendingSummary = nil;
    
    -- Evaluate keyword density
    local evaluation = self:EvaluateSummaryDensity(summary);
    
    if not evaluation.isAcceptable then
        -- Emit warning signal but still use the summary
        self:densityWarning(evaluation.density, self:GetMinKeywordDensity());
        LOG.std(nil, "warn", "DialogHistoryManager", 
            "Summary density below threshold: %.2f < %.2f (keywords: %d)", 
            evaluation.density, self:GetMinKeywordDensity(), #evaluation.keywords);
    end
    
    -- Merge summary (replace existing)
    self:MergeSummary(summary);
    
    LOG.std(nil, "debug", "DialogHistoryManager", "Pending summary applied (density=%.2f, acceptable=%s)", 
        evaluation.density, tostring(evaluation.isAcceptable));
end

--[[
    Extract keywords from text
    @param text: string - Text to analyze
    @return table - Array of extracted keywords
]]
function DialogHistoryManager:ExtractKeywords(text)
    if not text or #text == 0 then
        return {};
    end
    
    local keywords = {};
    local seen = {};
    
    -- Extract Chinese words (2-4 consecutive Chinese characters)
    -- UTF-8 Chinese characters: first byte 0xE4-0xE9 (228-233)
    -- This pattern matches sequences of Chinese characters
    for word in text:gmatch("[\228-\233][\128-\191][\128-\191]+") do
        -- Get unicode length
        local uniLen = 0;
        if ParaMisc and ParaMisc.GetUnicodeCharNum then
            uniLen = ParaMisc.GetUnicodeCharNum(word);
        else
            -- Fallback: estimate by byte length / 3
            uniLen = math.floor(#word / 3);
        end
        
        -- Keep words with 2-6 Chinese characters
        if uniLen >= 2 and uniLen <= 6 then
            -- Check if it's a stop word
            if not self.stopWordsLookup[word] and not seen[word] then
                table.insert(keywords, word);
                seen[word] = true;
            end
        end
    end
    
    -- Extract English words (3+ letters)
    for word in text:gmatch("[a-zA-Z][a-zA-Z][a-zA-Z]+") do
        local lowerWord = word:lower();
        -- Skip common English stop words
        local englishStopWords = {
            ["the"] = true, ["and"] = true, ["for"] = true, ["are"] = true,
            ["but"] = true, ["not"] = true, ["you"] = true, ["all"] = true,
            ["can"] = true, ["her"] = true, ["was"] = true, ["one"] = true,
            ["our"] = true, ["out"] = true, ["has"] = true, ["have"] = true,
            ["this"] = true, ["that"] = true, ["with"] = true, ["they"] = true,
            ["been"] = true, ["from"] = true, ["will"] = true, ["would"] = true,
        };
        if not englishStopWords[lowerWord] and not seen[lowerWord] then
            table.insert(keywords, word);
            seen[lowerWord] = true;
        end
    end
    
    -- Extract numbers (useful for progress, scores, coordinates)
    for num in text:gmatch("%d+") do
        if not seen[num] then
            table.insert(keywords, num);
            seen[num] = true;
        end
    end
    
    return keywords;
end

--[[
    Evaluate summary quality by keyword density
    @param summary: string - Summary to evaluate
    @return table - {density: number, isAcceptable: boolean, keywords: table}
]]
function DialogHistoryManager:EvaluateSummaryDensity(summary)
    if not summary or #summary == 0 then
        return {
            density = 0,
            isAcceptable = false,
            keywords = {},
        };
    end
    
    local keywords = self:ExtractKeywords(summary);
    
    -- Calculate total unicode character count
    local totalChars;
    if ParaMisc and ParaMisc.GetUnicodeCharNum then
        totalChars = ParaMisc.GetUnicodeCharNum(summary);
    else
        -- Fallback: rough estimate
        totalChars = #summary;
    end
    
    -- Calculate keyword character count (sum of keyword lengths)
    local keywordChars = 0;
    for _, kw in ipairs(keywords) do
        if ParaMisc and ParaMisc.GetUnicodeCharNum then
            keywordChars = keywordChars + ParaMisc.GetUnicodeCharNum(kw);
        else
            keywordChars = keywordChars + #kw;
        end
    end
    
    -- Density = keyword chars / total chars
    local density = totalChars > 0 and (keywordChars / totalChars) or 0;
    
    return {
        density = density,
        isAcceptable = density >= self:GetMinKeywordDensity(),
        keywords = keywords,
        totalChars = totalChars,
        keywordChars = keywordChars,
    };
end

--------------------------------------------------------------------------------
-- Debug: Inspection Methods
--------------------------------------------------------------------------------

--[[
    Get debug information about current state
    Useful for inspecting summary process
    @return table Debug info
]]
function DialogHistoryManager:GetDebugInfo()
    return {
        -- Basic state
        historyCount = #self.dialogHistory,
        maxHistoryLength = self:GetMaxHistoryLength(),
        keepRecentCount = self:GetKeepRecentCount(),
        
        -- Summary state
        hasSummary = self.dialogSummary ~= nil,
        summaryLength = self.dialogSummary and #self.dialogSummary or 0,
        summaryPreview = self.dialogSummary and string.sub(self.dialogSummary, 1, 200) .. "..." or nil,
        
        -- Pending summary
        hasPendingSummary = self.pendingSummary ~= nil,
        pendingLength = self.pendingSummary and #self.pendingSummary or 0,
        
        -- Processing state
        isSummarizing = self.isSummarizing,
        
        -- Language
        language = self:GetLanguage(),
        
        -- History preview (last 3 messages)
        recentMessages = self:GetRecentMessagesPreview(3),
    };
end

--[[
    Get preview of recent messages
    @param count number Number of messages to preview
    @return table Array of message previews
]]
function DialogHistoryManager:GetRecentMessagesPreview(count)
    count = count or 3;
    local result = {};
    local startIdx = math.max(1, #self.dialogHistory - count + 1);
    
    for i = startIdx, #self.dialogHistory do
        local msg = self.dialogHistory[i];
        table.insert(result, {
            role = msg.role,
            contentPreview = string.sub(msg.content, 1, 100) .. (string.len(msg.content) > 100 and "..." or ""),
            fullLength = string.len(msg.content),
        });
    end
    
    return result;
end

--[[
    Print debug info to log
    Call this to see current state in log output
]]
function DialogHistoryManager:PrintDebugInfo()
    local info = self:GetDebugInfo();
    
    LOG.std(nil, "info", "DialogHistoryManager", "========== DEBUG INFO ==========");
    LOG.std(nil, "info", "DialogHistoryManager", "History: %d/%d messages", info.historyCount, info.maxHistoryLength);
    LOG.std(nil, "info", "DialogHistoryManager", "Summary: %s (%d chars)", tostring(info.hasSummary), info.summaryLength);
    LOG.std(nil, "info", "DialogHistoryManager", "Pending: %s (%d chars)", tostring(info.hasPendingSummary), info.pendingLength);
    LOG.std(nil, "info", "DialogHistoryManager", "Summarizing: %s", tostring(info.isSummarizing));
    LOG.std(nil, "info", "DialogHistoryManager", "Language: %s", info.language);
    
    if info.summaryPreview then
        LOG.std(nil, "info", "DialogHistoryManager", "Summary preview: %s", info.summaryPreview);
    end
    
    for i, msg in ipairs(info.recentMessages) do
        LOG.std(nil, "info", "DialogHistoryManager", "Recent[%d] %s: %s", i, msg.role, msg.contentPreview);
    end
    
    LOG.std(nil, "info", "DialogHistoryManager", "================================");
    
    return info;
end

--[[
    Force trigger summarization for testing
    @return boolean Whether summarization was triggered
]]
function DialogHistoryManager:ForceSummarize()
    if #self.dialogHistory < 2 then
        LOG.std(nil, "warn", "DialogHistoryManager", "Cannot force summarize: not enough messages");
        return false;
    end
    
    LOG.std(nil, "info", "DialogHistoryManager", "Force triggering summarization...");
    
    -- Temporarily lower threshold
    local originalMax = self.maxHistoryLength;
    self.maxHistoryLength = 1;
    
    self:TrimDialogHistory();
    
    -- Restore threshold
    self.maxHistoryLength = originalMax;
    
    return true;
end

return DialogHistoryManager;
