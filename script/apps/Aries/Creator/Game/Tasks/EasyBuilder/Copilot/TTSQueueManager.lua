--[[
Title: TTSQueueManager
Author(s): LiXizhi, Copilot
Date: 2026/02/19
Desc: Manages TTS (Text-to-Speech) queue and streaming playback for BackgroundAgent.
Extracted from BackgroundAgent.lua to improve modularity.

Features:
- Auto-speak queue with streaming sentence playback
- Text cleaning for TTS (removes emojis, markdown, special chars)
- Sentence buffering and chunking for long text
- Stop keyword detection for user interruption
- Session ID tracking to prevent stale callbacks

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/TTSQueueManager.lua");
local TTSQueueManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.TTSQueueManager");

-- Get singleton instance
local tts = TTSQueueManager:GetInstance();

-- Enable auto-speak
tts:SetAutoSpeakEnabled(true);

-- Queue text for TTS (accumulated in buffer)
tts:QueueTTSSentence("Hello world!");

-- Flush buffer to start playback
tts:FlushTTSBuffer();

-- Direct speak (immediate)
tts:SpeakText("Hello!", nil, true, function(result)
    echo("TTS completed: " .. tostring(result.success));
end);

-- Stop all TTS
tts:StopTTS();

-- Connect to signals
tts:Connect("ttsStarted", function(text) echo("TTS started: " .. text); end);
tts:Connect("ttsCompleted", function() echo("TTS completed"); end);
------------------------------------------------------------
]]

-- Load dependencies
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");

-- TTSQueueManager class definition (inherits from ToolBase for signal support)
local TTSQueueManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), 
    commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.TTSQueueManager"));

-- Define signals
TTSQueueManager:Signal("ttsStarted");      -- Emitted when TTS playback starts (text)
TTSQueueManager:Signal("ttsCompleted");    -- Emitted when TTS playback completes

-- Singleton instance
local s_instance = nil;

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

-- Default configuration values
local CONFIG = {
    -- TTS voice ID (20008 = 晓双, female child voice)
    defaultVoice = 20008,
    
    -- TTS playback channel
    channel = "background_agent_tts",
    
    -- Speech speed (1-10)
    speed = 7,
    
    -- Priority level (1-10)
    priority = 10,
    
    -- Maximum characters per TTS chunk (API limit)
    maxChunkSize = 200,
    
    -- Delay between TTS segments (ms)
    segmentDelay = 100,
    
    -- Keywords that trigger TTS stop
    stopKeywords = {"停", "不用说", "安静", "闭嘴", "别说", "stop", "quiet"},
};

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------

--[[
    Get or create the singleton instance of TTSQueueManager
    @return TTSQueueManager - The global singleton instance
]]
function TTSQueueManager:GetInstance()
    if not s_instance then
        s_instance = self:new();
    end
    return s_instance;
end

-- Constructor
function TTSQueueManager:ctor()
    -- Auto-speak feature enabled (default on)
    self.autoSpeakEnabled = true;
    
    -- TTS sentence queue for streaming playback
    self.ttsQueue = {};           -- Queue of sentences to speak
    self.isTTSPlaying = false;    -- Whether TTS is currently playing
    
    -- TTS text buffer for accumulating complete response before calling TTS API
    self.ttsTextBuffer = "";      -- Accumulated clean text for TTS
    
    -- Sentence buffer for extracting complete sentences from streaming delta
    self.sentenceBuffer = "";
    
    -- Session ID to prevent stale callbacks
    self.ttsSessionId = 0;
    
    -- Custom stop keywords (can be overridden)
    self.stopKeywords = CONFIG.stopKeywords;
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--[[
    Speak text using TTS (Text-to-Speech)
    @param text: string - Text to speak
    @param voice: number (optional) - Voice narrator ID (default: 20008 child female)
    @param waitForComplete: boolean (optional) - Wait for speech to complete (default: true)
    @param callback: function - Called when speech completes or starts
]]
function TTSQueueManager:SpeakText(text, voice, waitForComplete, callback)
    if not text or text == "" then
        if callback then
            callback({success = false, llm_result = "No text provided"});
        end
        return;
    end
    
    -- Use default voice
    voice = voice or CONFIG.defaultVoice;
    
    -- Default to waiting for completion
    if waitForComplete == nil then
        waitForComplete = true;
    end
    
    -- Initialize SoundManager if needed
    SoundManager:Init();
    
    LOG.std(nil, "info", "TTSQueueManager", "TTS speaking: %s (voice=%d)", text, voice);
    
    if waitForComplete then
        -- Wait for speech to complete before callback
        SoundManager:PlayText(text, voice, CONFIG.priority, CONFIG.channel,
            function() -- play_start_cb
                LOG.std(nil, "debug", "TTSQueueManager", "TTS started");
            end,
            function() -- play_end_cb
                LOG.std(nil, "debug", "TTSQueueManager", "TTS completed");
                if callback then
                    callback({
                        success = true,
                        llm_result = string.format("Speech completed: %s", text),
                    });
                end
            end,
            function(success) -- prepare_cb
                if not success then
                    LOG.std(nil, "warn", "TTSQueueManager", "TTS prepare failed");
                    if callback then
                        callback({success = false, llm_result = "TTS prepare failed"});
                    end
                end
            end,
            nil,
            CONFIG.speed
        );
    else
        -- Return immediately after starting
        SoundManager:PlayText(text, voice, CONFIG.priority, CONFIG.channel,
            function() -- play_start_cb
                if callback then
                    callback({
                        success = true,
                        llm_result = string.format("Speech started: %s", text),
                    });
                end
            end,
            nil, -- play_end_cb
            function(success) -- prepare_cb
                if not success and callback then
                    callback({success = false, llm_result = "TTS prepare failed"});
                end
            end,
            nil,
            CONFIG.speed
        );
    end
end

--[[
    Stop any currently playing TTS
]]
function TTSQueueManager:StopTTS()
    SoundManager:Init();
    SoundManager:StopPlayText();
end

--[[
    Check if TTS is currently playing
    @return boolean
]]
function TTSQueueManager:IsTTSPlaying()
    SoundManager:Init();
    return SoundManager:IsPlayTextSoundPlaying() or self.isTTSPlaying;
end

--------------------------------------------------------------------------------
-- Auto-Speak Queue Management
--------------------------------------------------------------------------------

--[[
    Enable or disable auto-speak feature
    @param enabled: boolean - Whether to enable auto-speak
]]
function TTSQueueManager:SetAutoSpeakEnabled(enabled)
    self.autoSpeakEnabled = enabled;
    if not enabled then
        self:ClearTTSQueue();
    end
    LOG.std(nil, "info", "TTSQueueManager", "Auto-speak %s", enabled and "enabled" or "disabled");
end

--[[
    Check if auto-speak is enabled
    @return boolean
]]
function TTSQueueManager:IsAutoSpeakEnabled()
    return self.autoSpeakEnabled;
end

--[[
    Queue a sentence for TTS playback
    Text is accumulated in buffer and will be sent to TTS when FlushTTSBuffer is called.
    @param text: string - The sentence to speak
]]
function TTSQueueManager:QueueTTSSentence(text)
    if not text or text == "" then return; end
    
    -- Trim whitespace
    text = text:match("^%s*(.-)%s*$");
    if text == "" then return; end
    
    -- Clean text for TTS (remove special characters)
    local cleanText = self:CleanTextForTTS(text);
    if cleanText == "" then
        LOG.std(nil, "debug", "TTSQueueManager", "TTS skipped (no speakable content): %s", text);
        return;
    end
    
    -- Accumulate clean text to buffer (will be sent to TTS API when flushed)
    if self.ttsTextBuffer == "" then
        self.ttsTextBuffer = cleanText;
    else
        self.ttsTextBuffer = self.ttsTextBuffer .. cleanText;
    end
    
    LOG.std(nil, "debug", "TTSQueueManager", "TTS buffered: %s (buffer len: %d)", cleanText, #self.ttsTextBuffer);
end

--[[
    Process the next sentence in TTS queue
]]
function TTSQueueManager:ProcessNextTTSInQueue()
    if #self.ttsQueue == 0 then
        self.isTTSPlaying = false;
        -- Emit TTS completed signal when all chunks are done
        self:ttsCompleted();
        LOG.std(nil, "debug", "TTSQueueManager", "TTS playback completed (all chunks done)");
        return;
    end
    
    local text = table.remove(self.ttsQueue, 1);
    self.isTTSPlaying = true;
    
    -- Generate unique session ID to prevent race conditions
    self.ttsSessionId = self.ttsSessionId + 1;
    local currentSessionId = self.ttsSessionId;
    
    LOG.std(nil, "debug", "TTSQueueManager", "TTS playing: %s (remaining: %d, session: %d)", text, #self.ttsQueue, currentSessionId);
    
    -- Use default voice
    SoundManager:Init();
    SoundManager:PlayText(text, CONFIG.defaultVoice, CONFIG.priority, CONFIG.channel,
        function() -- play_start_cb
            LOG.std(nil, "debug", "TTSQueueManager", "TTS auto-speak started (session: %d)", currentSessionId);
        end,
        function() -- play_end_cb
            LOG.std(nil, "debug", "TTSQueueManager", "TTS auto-speak completed (session: %d)", currentSessionId);
            -- Only process next if this is still the current session (prevent stale callbacks)
            if self.ttsSessionId == currentSessionId then
                -- Add small delay to ensure audio system is ready for next playback
                commonlib.TimerManager.SetTimeout(function()
                    -- Double check session is still valid after delay
                    if self.ttsSessionId == currentSessionId then
                        self:ProcessNextTTSInQueue();
                    end
                end, CONFIG.segmentDelay);
            else
                LOG.std(nil, "debug", "TTSQueueManager", "TTS callback ignored (stale session: %d, current: %d)", currentSessionId, self.ttsSessionId);
            end
        end,
        function(success) -- prepare_cb
            if not success then
                LOG.std(nil, "warn", "TTSQueueManager", "TTS auto-speak prepare failed (session: %d)", currentSessionId);
                -- Only try next if this is still the current session
                if self.ttsSessionId == currentSessionId then
                    commonlib.TimerManager.SetTimeout(function()
                        if self.ttsSessionId == currentSessionId then
                            self:ProcessNextTTSInQueue();
                        end
                    end, CONFIG.segmentDelay);
                end
            end
        end
    );
end

--[[
    Clear TTS queue and stop current playback
]]
function TTSQueueManager:ClearTTSQueue()
    self.ttsQueue = {};
    self.isTTSPlaying = false;
    self.sentenceBuffer = "";
    self.ttsTextBuffer = "";  -- Clear accumulated TTS text
    -- Increment session ID to invalidate any pending callbacks
    self.ttsSessionId = self.ttsSessionId + 1;
    self:StopTTS();
    LOG.std(nil, "info", "TTSQueueManager", "TTS queue cleared (new session: %d)", self.ttsSessionId);
end

--[[
    Flush TTS text buffer - send accumulated text to TTS API
    Called when LLM response is complete to play the full response
]]
function TTSQueueManager:FlushTTSBuffer()
    if not self.ttsTextBuffer or self.ttsTextBuffer == "" then
        LOG.std(nil, "debug", "TTSQueueManager", "TTS buffer empty, nothing to flush");
        return;
    end
    
    local textToSpeak = self.ttsTextBuffer;
    self.ttsTextBuffer = "";  -- Clear buffer
    
    -- Split long text into chunks if needed (TTS API may have length limits)
    local chunks = {};
    
    if #textToSpeak <= CONFIG.maxChunkSize then
        table.insert(chunks, textToSpeak);
    else
        -- Split by sentence-ending punctuation, keeping chunks under limit
        local currentChunk = "";
        local sentences = self:_SplitIntoSentences(textToSpeak);
        
        for _, sentence in ipairs(sentences) do
            if #currentChunk + #sentence <= CONFIG.maxChunkSize then
                currentChunk = currentChunk .. sentence;
            else
                if currentChunk ~= "" then
                    table.insert(chunks, currentChunk);
                end
                -- If single sentence is too long, add it anyway
                if #sentence > CONFIG.maxChunkSize then
                    table.insert(chunks, sentence);
                    currentChunk = "";
                else
                    currentChunk = sentence;
                end
            end
        end
        if currentChunk ~= "" then
            table.insert(chunks, currentChunk);
        end
    end
    
    -- Queue all chunks
    for _, chunk in ipairs(chunks) do
        table.insert(self.ttsQueue, chunk);
    end
    
    LOG.std(nil, "info", "TTSQueueManager", "TTS buffer flushed: %d chars in %d chunks", #textToSpeak, #chunks);
    
    -- Emit TTS started signal
    self:ttsStarted(textToSpeak);
    
    -- Start playing if not already
    if not self.isTTSPlaying and #self.ttsQueue > 0 then
        self:ProcessNextTTSInQueue();
    end
end

--------------------------------------------------------------------------------
-- Text Processing
--------------------------------------------------------------------------------

--[[
    Clean text for TTS playback - remove special characters, emojis, markdown, etc.
    Only keeps Chinese, English, numbers, and basic punctuation.
    @param text: string - Raw text to clean
    @return string - Cleaned text suitable for TTS
]]
function TTSQueueManager:CleanTextForTTS(text)
    if not text or text == "" then return ""; end
    
    local result = {};
    local i = 1;
    local len = #text;
    
    while i <= len do
        local byte = string.byte(text, i);
        local charLen = 1;
        local keepChar = false;
        
        -- Determine UTF-8 character length
        if byte >= 0xF0 then
            charLen = 4;  -- 4-byte UTF-8 (emojis, etc.) - skip these
        elseif byte >= 0xE0 then
            charLen = 3;  -- 3-byte UTF-8 (Chinese characters, Chinese punctuation)
            -- Check if it's a Chinese character (CJK Unified Ideographs: U+4E00 - U+9FFF)
            -- or Chinese punctuation
            if i + 2 <= len then
                local b1, b2, b3 = string.byte(text, i, i + 2);
                -- Chinese characters range: E4 B8 80 to E9 BF BF (U+4E00 to U+9FFF)
                if b1 == 0xE4 and b2 >= 0xB8 then keepChar = true;
                elseif b1 >= 0xE5 and b1 <= 0xE8 then keepChar = true;
                elseif b1 == 0xE9 and b2 <= 0xBF then keepChar = true;
                -- Chinese punctuation (U+3000 - U+303F): E3 80 80 to E3 80 BF
                elseif b1 == 0xE3 and b2 == 0x80 then keepChar = true;
                -- Full-width punctuation (U+FF00 - U+FFEF): EF BC 80 to EF BF AF
                elseif b1 == 0xEF and (b2 == 0xBC or b2 == 0xBD) then keepChar = true;
                end
            end
        elseif byte >= 0xC0 then
            charLen = 2;  -- 2-byte UTF-8 - skip (rare for Chinese/English)
        else
            -- Single byte ASCII
            charLen = 1;
            -- Keep: letters, digits, spaces, basic punctuation
            if (byte >= 0x41 and byte <= 0x5A) or  -- A-Z
               (byte >= 0x61 and byte <= 0x7A) or  -- a-z
               (byte >= 0x30 and byte <= 0x39) or  -- 0-9
               byte == 0x20 or                      -- space
               byte == 0x2C or                      -- ,
               byte == 0x2E or                      -- .
               byte == 0x21 or                      -- !
               byte == 0x3F or                      -- ?
               byte == 0x27 or                      -- '
               byte == 0x2D then                    -- -
                keepChar = true;
            end
        end
        
        -- Ensure we don't read past the buffer
        if i + charLen - 1 > len then
            break;
        end
        
        if keepChar then
            table.insert(result, string.sub(text, i, i + charLen - 1));
        end
        
        i = i + charLen;
    end
    
    local cleaned = table.concat(result);
    -- Collapse multiple spaces into one
    cleaned = cleaned:gsub("%s+", " ");
    -- Trim
    cleaned = cleaned:match("^%s*(.-)%s*$") or "";
    
    return cleaned;
end

--[[
    Filter out progress markers from text for TTS
    Progress markers: [xxx], [进度: x/y], [调用工具: xxx], etc.
    @param text: string - Input text
    @return string - Text with progress markers removed
]]
function TTSQueueManager:FilterProgressMarkers(text)
    if not text or text == "" then return text; end
    
    -- Remove all [...] patterns
    local filtered = text:gsub("%b[]", "");
    
    -- Trim whitespace
    filtered = filtered:match("^%s*(.-)%s*$") or filtered;
    
    return filtered;
end

--[[
    Extract progress markers from text
    @param text: string - Input text
    @return table - Array of progress markers
]]
function TTSQueueManager:ExtractProgressMarkers(text)
    if not text or text == "" then return {}; end
    
    local markers = {};
    for marker in text:gmatch("%b[]") do
        table.insert(markers, marker);
    end
    
    return markers;
end

--[[
    Split text into sentences (helper for FlushTTSBuffer)
    @param text: string - Text to split
    @return table - Array of sentences
]]
function TTSQueueManager:_SplitIntoSentences(text)
    local sentences = {};
    local current = "";
    local i = 1;
    local len = #text;
    
    local punctuationSet = {
        ["。"] = true, ["！"] = true, ["？"] = true,
        ["，"] = true, ["."] = true, ["!"] = true, ["?"] = true, [","] = true,
    };
    
    while i <= len do
        local byte = string.byte(text, i);
        local charLen = 1;
        if byte >= 0xF0 then charLen = 4;
        elseif byte >= 0xE0 then charLen = 3;
        elseif byte >= 0xC0 then charLen = 2;
        end
        
        if i + charLen - 1 > len then break; end
        
        local char = string.sub(text, i, i + charLen - 1);
        current = current .. char;
        
        if punctuationSet[char] then
            table.insert(sentences, current);
            current = "";
        end
        
        i = i + charLen;
    end
    
    if current ~= "" then
        table.insert(sentences, current);
    end
    
    return sentences;
end

--[[
    Check if transcript contains TTS stop keywords
    @param transcript: string - Voice transcript to check
    @return boolean - True if stop keyword found
]]
function TTSQueueManager:CheckStopKeyword(transcript)
    if not transcript then return false; end
    
    local lowerTranscript = string.lower(transcript);
    for _, keyword in ipairs(self.stopKeywords) do
        if string.find(lowerTranscript, string.lower(keyword), 1, true) then
            return true;
        end
    end
    return false;
end

--[[
    Set custom stop keywords
    @param keywords: table - Array of stop keywords
]]
function TTSQueueManager:SetStopKeywords(keywords)
    if type(keywords) == "table" then
        self.stopKeywords = keywords;
    end
end

--------------------------------------------------------------------------------
-- Debug/Status
--------------------------------------------------------------------------------

--[[
    Get TTS text buffer content (for debugging)
    @return string - Current buffer content
]]
function TTSQueueManager:GetTTSBufferContent()
    return self.ttsTextBuffer or "";
end

--[[
    Get TTS queue status (for debugging)
    @return table - {queueLength, isPlaying, autoSpeakEnabled, ttsBufferLength, sentenceBufferLength}
]]
function TTSQueueManager:GetTTSQueueStatus()
    return {
        queueLength = #self.ttsQueue,
        isPlaying = self.isTTSPlaying,
        autoSpeakEnabled = self.autoSpeakEnabled,
        sentenceBufferLength = #(self.sentenceBuffer or ""),
        ttsBufferLength = #(self.ttsTextBuffer or ""),
        ttsBufferContent = self.ttsTextBuffer or "",
    };
end

--[[
    Get configuration
    @return table - Configuration table (read-only copy)
]]
function TTSQueueManager:GetConfig()
    -- Return a copy to prevent modification
    local copy = {};
    for k, v in pairs(CONFIG) do
        copy[k] = v;
    end
    return copy;
end

--[[
    Set configuration value
    @param key: string - Configuration key
    @param value: any - Configuration value
]]
function TTSQueueManager:SetConfig(key, value)
    if CONFIG[key] ~= nil then
        CONFIG[key] = value;
        LOG.std(nil, "info", "TTSQueueManager", "Config %s set to: %s", key, tostring(value));
    else
        LOG.std(nil, "warn", "TTSQueueManager", "Unknown config key: %s", key);
    end
end
