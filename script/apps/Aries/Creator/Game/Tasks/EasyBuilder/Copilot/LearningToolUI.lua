--[[
Title: Learning Tool UI Manager
Author(s): Copilot
Date: 2026/1/28
Desc: MCML-based UI for learning tools (multiple choice, spelling, speaking, flashcard).
      Manages audio state (TTS/recording), waveform display, and visual feedback.

Features:
- MCML dialog-based learning tool UIs
- Audio state management (idle/speaking/recording)
- Real-time waveform display using Canvas 2D
- TTS/recording mutual exclusion via VoiceContextManager signals
- Visual feedback animations for correct/incorrect answers

Use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/LearningToolUI.lua");
local LearningToolUI = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.LearningToolUI");

-- Show a learning tool UI
LearningToolUI.Show("test_multiple_choice", {
    question = "What does 'apple' mean?",
    options = {"苹果", "香蕉", "橙子", "葡萄"},
    correctIndex = 1,
}, sessionId, function(result)
    echo(result);
end);

-- Close current UI
LearningToolUI.Close();
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/Window.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
local LearningToolPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/LearningToolPage.lua");

local Window = commonlib.gettable("System.Windows.Window");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");

local LearningToolUI = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.LearningToolUI");

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------
LearningToolUI.waveformRefreshMs = 66;          -- ~15 FPS for waveform update
LearningToolUI.maxWaveformSamples = 300;        -- Max sample points for waveform
LearningToolUI.recordingTimeoutMs = 10000;      -- 10 seconds max recording
LearningToolUI.feedbackDelayMs = 1500;          -- Delay before closing after feedback
LearningToolUI.defaultVoice = 20008;            -- Child female voice (晓双)
LearningToolUI.useWebView = true;               -- Use WebView (HTML5) instead of MCML

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------
LearningToolUI.currentPage = nil;               -- Current MCML page reference
LearningToolUI.currentToolName = nil;           -- Current tool type
LearningToolUI.currentParams = nil;             -- Current tool parameters
LearningToolUI.currentSessionId = nil;          -- Current session ID
LearningToolUI.currentCallback = nil;           -- Result callback

LearningToolUI.audioState = "idle";             -- "idle" | "speaking" | "recording"
LearningToolUI.waveformWindow = nil;            -- Window for waveform canvas
LearningToolUI.waveformTimer = nil;             -- Timer for waveform refresh
LearningToolUI.recordingTimer = nil;            -- Timer for recording timeout
LearningToolUI.feedbackTimer = nil;             -- Timer for feedback delay before close
LearningToolUI.audioSamples = {};               -- Audio samples for waveform display
LearningToolUI.recordingStartTime = nil;        -- Recording start timestamp
LearningToolUI.recordedPCMData = nil;           -- Accumulated PCM data

LearningToolUI.isConnectedToVoiceManager = false;

--------------------------------------------------------------------------------
-- Tool URL Mapping
--------------------------------------------------------------------------------
local ToolDialogUrls = {
    test_multiple_choice = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/LearningQuizDialog.html",
    test_words_spelling = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/LearningSpellingDialog.html",
    test_words_speaking = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/LearningSpeakingDialog.html",
    show_learning_content = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/LearningFlashcard.html",
};

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--[[
    Set whether to use WebView (HTML5) or MCML for learning tools
    @param enabled: boolean - True to use WebView, false for MCML
]]
function LearningToolUI.SetUseWebView(enabled)
    LearningToolUI.useWebView = enabled;
    LOG.std(nil, "info", "LearningToolUI", "WebView mode %s", enabled and "enabled" or "disabled");
end

--[[
    Check if WebView mode is enabled
    @return boolean
]]
function LearningToolUI.IsUseWebView()
    return LearningToolUI.useWebView;
end

--[[
    Show a learning tool UI
    @param toolName: string - Tool name (test_multiple_choice, test_words_spelling, etc.)
    @param params: table - Tool parameters
    @param sessionId: string - Session ID for callback
    @param callback: function - Called with result when user completes the tool
]]
function LearningToolUI.Show(toolName, params, sessionId, callback)
    -- Close any existing UI first
    LearningToolUI.Close();
    
    -- Use WebView if enabled
    if LearningToolUI.useWebView and LearningToolPage then
        LOG.std(nil, "info", "LearningToolUI", "Using WebView for %s (session: %s)", toolName, sessionId or "none");
        LearningToolPage.ShowPage(toolName, params, sessionId, function(result)
            -- Call the original callback directly
            if callback then
                LOG.std(nil, "info", "LearningToolUI", "WebView callback for session: %s, correct=%s", 
                    sessionId or "none", tostring(result.correct));
                callback(result);
            end
            -- Also report result to BackgroundAgent
            LearningToolUI.ReportResult(sessionId, result);
        end);
        return;
    end
    
    -- Fallback to MCML
    local url = ToolDialogUrls[toolName];
    if not url then
        LOG.std(nil, "warn", "LearningToolUI", "Unknown tool: %s", toolName);
        if callback then
            callback({success = false, error = "Unknown tool: " .. tostring(toolName)});
        end
        return;
    end
    
    -- Store state
    LearningToolUI.currentToolName = toolName;
    LearningToolUI.currentParams = params or {};
    LearningToolUI.currentSessionId = sessionId;
    LearningToolUI.currentCallback = callback;
    LearningToolUI.audioState = "idle";
    LearningToolUI.audioSamples = {};
    LearningToolUI.recordedPCMData = nil;
    
    -- Connect to VoiceContextManager signals for TTS state sync
    LearningToolUI.ConnectToVoiceManager();
    
    -- Calculate dialog size based on tool type
    local width, height = LearningToolUI.GetDialogSize(toolName);
    
    -- Open MCML dialog
    local windowParams = {
        url = url,
        name = "LearningToolUI_" .. toolName,
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide = false,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        bShow = true,
        click_through = false,
        zorder = 100,
        directPosition = true,
        align = "_ct",
        x = -width / 2,
        y = -height / 2,
        width = width,
        height = height,
    };
    
    System.App.Commands.Call("File.MCMLWindowFrame", windowParams);
    LearningToolUI.currentPage = windowParams._page;
    
    if LearningToolUI.currentPage then
        LearningToolUI.currentPage.OnClose = function()
            LearningToolUI.OnDialogClosed();
        end
    end
    
    LOG.std(nil, "info", "LearningToolUI", "Opened %s MCML dialog (session: %s)", toolName, sessionId or "none");
end

--[[
    Internal cleanup method - shared by Close() and OnDialogClosed()
    @param skipPageClose: boolean - If true, don't close the page (already closing)
]]
function LearningToolUI.CleanupInternal(skipPageClose)
    -- Stop any ongoing audio
    LearningToolUI.StopAllAudio();
    
    -- Stop timers
    if LearningToolUI.waveformTimer then
        LearningToolUI.waveformTimer:Change();
        LearningToolUI.waveformTimer = nil;
    end
    if LearningToolUI.recordingTimer then
        LearningToolUI.recordingTimer:Change();
        LearningToolUI.recordingTimer = nil;
    end
    if LearningToolUI.feedbackTimer then
        LearningToolUI.feedbackTimer:Change();
        LearningToolUI.feedbackTimer = nil;
    end
    
    -- Destroy waveform window
    if LearningToolUI.waveformWindow then
        LearningToolUI.waveformWindow:CloseWindow();
        LearningToolUI.waveformWindow = nil;
    end
    
    -- Close dialog (unless already closing)
    if not skipPageClose and LearningToolUI.currentPage then
        LearningToolUI.currentPage:CloseWindow();
    end
    LearningToolUI.currentPage = nil;
    
    -- Disconnect from VoiceContextManager
    LearningToolUI.DisconnectFromVoiceManager();
    
    -- Clear feedback state
    LearningToolUI.feedbackResult = nil;
    LearningToolUI.audioState = "idle";
    LearningToolUI.audioSamples = {};
    LearningToolUI.recordedPCMData = nil;
end

--[[
    Called when user closes dialog via ESC or close button
]]
function LearningToolUI.OnDialogClosed()
    LOG.std(nil, "info", "LearningToolUI", "Dialog closed by user (tool: %s)", 
        LearningToolUI.currentToolName or "unknown");
    
    -- Save state before cleanup
    local sessionId = LearningToolUI.currentSessionId;
    local toolName = LearningToolUI.currentToolName;
    local savedCallback = LearningToolUI.currentCallback;
    local hasCallback = savedCallback ~= nil;
    
    -- Clear state before callback to prevent re-entry issues
    LearningToolUI.currentCallback = nil;
    LearningToolUI.currentSessionId = nil;
    LearningToolUI.currentToolName = nil;
    LearningToolUI.currentParams = nil;
    
    -- Cleanup (skip page close since it's already closing)
    LearningToolUI.CleanupInternal(true);
    
    -- Report cancelled result if we had a callback
    if hasCallback then
        local result = {
            success = true,
            cancelled = true,
            skipped = true,
            toolName = toolName,
            reason = "User closed dialog",
        };
        
        -- Call stored callback directly
        LOG.std(nil, "info", "LearningToolUI", "Calling callback for cancelled session: %s", 
            sessionId or "none");
        savedCallback(result);
        
        -- Also report to BackgroundAgent
        LearningToolUI.ReportResult(sessionId, result);
    end
end

--[[
    Close the current learning tool UI
    @param result: table (optional) - Result to pass to callback
]]
function LearningToolUI.Close(result)
    -- Close WebView if using WebView mode
    if LearningToolUI.useWebView and LearningToolPage then
        LearningToolPage.ClosePage();
    end
    
    -- Save state before cleanup
    local sessionId = LearningToolUI.currentSessionId;
    local savedCallback = LearningToolUI.currentCallback;
    local hasCallback = result and savedCallback;
    
    -- Clear state before callback to prevent re-entry issues
    LearningToolUI.currentCallback = nil;
    LearningToolUI.currentSessionId = nil;
    LearningToolUI.currentToolName = nil;
    LearningToolUI.currentParams = nil;
    
    -- Cleanup (close page)
    LearningToolUI.CleanupInternal(false);
    
    -- Call the stored callback directly if provided
    if hasCallback then
        LOG.std(nil, "info", "LearningToolUI", "Calling callback for session: %s, correct=%s", 
            sessionId or "none", tostring(result.correct));
        savedCallback(result);
    end
    
    -- Also report result to BackgroundAgent for backwards compatibility
    if result and sessionId then
        LearningToolUI.ReportResult(sessionId, result);
    end
end

--[[
    Get current tool parameters (for MCML page to access)
    @return table
]]
function LearningToolUI.GetParams()
    return LearningToolUI.currentParams or {};
end

--[[
    Get current audio state
    @return string - "idle", "speaking", or "recording"
]]
function LearningToolUI.GetAudioState()
    return LearningToolUI.audioState;
end

--[[
    Check if TTS is currently playing (recording button should be disabled)
    @return boolean
]]
function LearningToolUI.IsSpeaking()
    return LearningToolUI.audioState == "speaking";
end

--[[
    Check if recording is in progress
    @return boolean
]]
function LearningToolUI.IsRecording()
    return LearningToolUI.audioState == "recording";
end

--[[
    Get the status text for recording button
    @return string
]]
function LearningToolUI.GetRecordButtonText()
    if LearningToolUI.audioState == "speaking" then
        return "播放中...";
    elseif LearningToolUI.audioState == "recording" then
        return "录音中...";
    else
        return "开始录音";
    end
end

--[[
    Check if recording button should be enabled
    @return boolean
]]
function LearningToolUI.IsRecordButtonEnabled()
    return LearningToolUI.audioState == "idle";
end

--------------------------------------------------------------------------------
-- Audio Control
--------------------------------------------------------------------------------

--[[
    Play demo/prompt audio using TTS
    @param text: string - Text to speak
    @param voice: number (optional) - Voice ID
    @param onComplete: function (optional) - Called when playback completes
    @return boolean - True if started successfully
]]
function LearningToolUI.PlayDemoAudio(text, voice, onComplete)
    if LearningToolUI.audioState ~= "idle" then
        LOG.std(nil, "debug", "LearningToolUI", "Cannot play audio: state=%s", LearningToolUI.audioState);
        return false;
    end
    
    if not text or text == "" then
        if onComplete then onComplete({success = false, error = "No text"}); end
        return false;
    end
    
    LearningToolUI.audioState = "speaking";
    LearningToolUI.RefreshUI();
    
    voice = voice or LearningToolUI.defaultVoice;
    
    SoundManager:Init();
    SoundManager:PlayText(text, voice, 10, "learning_tool_tts",
        function() -- play_start_cb
            LOG.std(nil, "debug", "LearningToolUI", "TTS started: %s", text);
        end,
        function() -- play_end_cb
            LOG.std(nil, "debug", "LearningToolUI", "TTS completed");
            LearningToolUI.audioState = "idle";
            LearningToolUI.RefreshUI();
            if onComplete then
                onComplete({success = true, completed = true});
            end
        end,
        function(success) -- prepare_cb
            if not success then
                LOG.std(nil, "warn", "LearningToolUI", "TTS prepare failed");
                LearningToolUI.audioState = "idle";
                LearningToolUI.RefreshUI();
                if onComplete then
                    onComplete({success = false, error = "TTS prepare failed"});
                end
            end
        end
    );
    
    return true;
end

--[[
    Stop TTS playback
]]
function LearningToolUI.StopTTS()
    SoundManager:Init();
    SoundManager:StopPlayText();
    if LearningToolUI.audioState == "speaking" then
        LearningToolUI.audioState = "idle";
        LearningToolUI.RefreshUI();
    end
end

--[[
    Start recording user voice
    @param onComplete: function - Called when recording completes with {success, pcmData, transcript}
    @return boolean - True if started successfully
]]
function LearningToolUI.StartRecording(onComplete)
    if LearningToolUI.audioState ~= "idle" then
        LOG.std(nil, "debug", "LearningToolUI", "Cannot start recording: state=%s", LearningToolUI.audioState);
        return false;
    end
    
    -- Check if TTS is playing via VoiceContextManager
    local VoiceContextManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.VoiceContextManager");
    if VoiceContextManager and VoiceContextManager:IsPausedForTTS() then
        LOG.std(nil, "debug", "LearningToolUI", "Cannot start recording: TTS is playing");
        return false;
    end
    
    LearningToolUI.audioState = "recording";
    LearningToolUI.recordingStartTime = commonlib.TimerManager.GetCurrentTime();
    LearningToolUI.recordedPCMData = "";
    LearningToolUI.audioSamples = {};
    LearningToolUI.recordingCallback = onComplete;
    LearningToolUI.RefreshUI();
    
    -- Start AudioEngine recording with callback
    AudioEngine.StartRecording(function(data)
        LearningToolUI.OnRecordingData(data);
    end);
    
    -- Start waveform refresh timer
    LearningToolUI.StartWaveformTimer();
    
    -- Start recording timeout timer
    LearningToolUI.recordingTimer = commonlib.TimerManager.SetTimeout(function()
        LearningToolUI.StopRecording();
    end, LearningToolUI.recordingTimeoutMs);
    
    LOG.std(nil, "info", "LearningToolUI", "Recording started");
    return true;
end

--[[
    Stop recording and process the audio
]]
function LearningToolUI.StopRecording()
    if LearningToolUI.audioState ~= "recording" then
        return;
    end
    
    -- Stop recording
    AudioEngine.StopRecording();
    
    -- Stop timers
    if LearningToolUI.waveformTimer then
        LearningToolUI.waveformTimer:Change();
        LearningToolUI.waveformTimer = nil;
    end
    if LearningToolUI.recordingTimer then
        LearningToolUI.recordingTimer:Change();
        LearningToolUI.recordingTimer = nil;
    end
    
    LearningToolUI.audioState = "idle";
    LearningToolUI.RefreshUI();
    
    local pcmData = LearningToolUI.recordedPCMData;
    local callback = LearningToolUI.recordingCallback;
    LearningToolUI.recordedPCMData = nil;
    LearningToolUI.recordingCallback = nil;
    
    LOG.std(nil, "info", "LearningToolUI", "Recording stopped, bytes: %d", pcmData and #pcmData or 0);
    
    -- Transcribe the audio if we have enough data
    if pcmData and #pcmData > 8000 then -- ~180ms minimum
        LearningToolUI.TranscribeAudio(pcmData, callback);
    else
        if callback then
            callback({success = false, error = "Recording too short"});
        end
    end
end

--[[
    Stop all audio (TTS and recording)
]]
function LearningToolUI.StopAllAudio()
    LearningToolUI.StopTTS();
    if LearningToolUI.audioState == "recording" then
        AudioEngine.StopRecording();
        LearningToolUI.audioState = "idle";
    end
    if LearningToolUI.waveformTimer then
        LearningToolUI.waveformTimer:Change();
        LearningToolUI.waveformTimer = nil;
    end
    if LearningToolUI.recordingTimer then
        LearningToolUI.recordingTimer:Change();
        LearningToolUI.recordingTimer = nil;
    end
end

--[[
    Handle incoming recording audio data
    @param data: string - Raw 16-bit PCM audio data
]]
function LearningToolUI.OnRecordingData(data)
    if LearningToolUI.audioState ~= "recording" or not data then
        return;
    end
    
    -- Accumulate PCM data
    LearningToolUI.recordedPCMData = (LearningToolUI.recordedPCMData or "") .. data;
    
    -- Convert to samples for waveform display
    local samples = LearningToolUI.ConvertPCMToSamples(data);
    for _, sample in ipairs(samples) do
        table.insert(LearningToolUI.audioSamples, sample);
    end
    
    -- Limit sample buffer size
    while #LearningToolUI.audioSamples > LearningToolUI.maxWaveformSamples do
        table.remove(LearningToolUI.audioSamples, 1);
    end
end

--[[
    Convert PCM data to normalized samples for waveform display
    @param pcmData: string - Raw 16-bit PCM audio data
    @return table - Array of normalized samples [-1, 1]
]]
function LearningToolUI.ConvertPCMToSamples(pcmData)
    local samples = {};
    local step = math.max(1, math.floor(#pcmData / 100)); -- Downsample to ~50 points per chunk
    
    local i = 1;
    while i <= #pcmData - 1 do
        local lowByte = string.byte(pcmData, i);
        local highByte = string.byte(pcmData, i + 1);
        
        -- Convert from two bytes to int16 with sign
        local value;
        if highByte > 127 then
            highByte = 255 - highByte;
            lowByte = 255 - lowByte;
            value = -(lowByte + highByte * 256);
        else
            value = lowByte + highByte * 256;
        end
        
        -- Normalize to [-1, 1]
        table.insert(samples, value / 32768);
        
        i = i + step;
    end
    
    return samples;
end

--[[
    Transcribe recorded audio using keepwork.ai API
    @param pcmData: string - Raw PCM audio data
    @param callback: function - Called with {success, transcript}
]]
function LearningToolUI.TranscribeAudio(pcmData, callback)
    NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.ai.lua");
    
    -- Create WAV header
    local wavHeader = LearningToolUI.CreateWavHeader(#pcmData);
    local wavData = wavHeader .. pcmData;
    
    -- Call API
    keepwork.ai.audioEncode2Text({
        format = "wav",
        dev_pid = "LLM", -- LLM-based transcription for all languages
        speech = commonlib.Encoding.base64(wavData),
    }, function(err, msg, data)
        if err ~= 200 then
            LOG.std(nil, "warn", "LearningToolUI", "Transcription failed: %d", err);
            if callback then
                callback({success = false, error = "Transcription failed"});
            end
            return;
        end
        
        local transcript = data and data.data;
        LOG.std(nil, "info", "LearningToolUI", "Transcribed: %s", transcript or "");
        
        if callback then
            callback({
                success = true,
                transcript = transcript or "",
                pcmData = pcmData,
            });
        end
    end);
end

--[[
    Create WAV header for raw PCM data
    @param dataLength: number - Length of PCM data in bytes
    @return string - WAV header (44 bytes)
]]
function LearningToolUI.CreateWavHeader(dataLength)
    local sampleRate = 22050;
    local bitsPerSample = 16;
    local numChannels = 1;
    
    local byteRate = sampleRate * numChannels * bitsPerSample / 8;
    local blockAlign = numChannels * bitsPerSample / 8;
    local fileSize = dataLength + 36;
    
    local function writeInt16(value)
        return string.char(value % 256, math.floor(value / 256) % 256);
    end
    
    local function writeInt32(value)
        return string.char(
            value % 256,
            math.floor(value / 256) % 256,
            math.floor(value / 65536) % 256,
            math.floor(value / 16777216) % 256
        );
    end
    
    return "RIFF" .. writeInt32(fileSize) .. "WAVE" ..
           "fmt " .. writeInt32(16) .. writeInt16(1) .. writeInt16(numChannels) ..
           writeInt32(sampleRate) .. writeInt32(byteRate) ..
           writeInt16(blockAlign) .. writeInt16(bitsPerSample) ..
           "data" .. writeInt32(dataLength);
end

--------------------------------------------------------------------------------
-- Waveform Display
--------------------------------------------------------------------------------

--[[
    Start waveform refresh timer
]]
function LearningToolUI.StartWaveformTimer()
    if LearningToolUI.waveformTimer then
        LearningToolUI.waveformTimer:Change();
    end
    
    LearningToolUI.waveformTimer = commonlib.Timer:new({
        callbackFunc = function()
            LearningToolUI.DrawWaveform();
        end
    });
    LearningToolUI.waveformTimer:Change(0, LearningToolUI.waveformRefreshMs);
end

--[[
    Draw audio waveform on canvas
    Uses Canvas 2D API similar to MiniGameUserProfile.DrawRadarChart
]]
function LearningToolUI.DrawWaveform()
    local container = ParaUI.GetUIObject("learning_waveform_container");
    if not container or not container:IsValid() then
        return;
    end
    
    -- Create or get window
    if not LearningToolUI.waveformWindow then
        LearningToolUI.waveformWindow = Window:new();
    end
    
    local wnd = LearningToolUI.waveformWindow;
    local rx, ry, rw, rh = container:GetAbsPosition();
    wnd:Show("LearningWaveform", container, "lt", 0, 0, rw, rh, 1);
    
    local ctx = wnd:getContext();
    local width = ctx:getWidth();
    local height = ctx:getHeight();
    local centerY = height / 2;
    
    -- Clear background
    ctx:clearRect(0, 0, width, height);
    
    -- Draw center line
    ctx.strokeStyle = "#666666";
    ctx.lineWidth = 1;
    ctx:beginPath();
    ctx:moveTo(0, centerY);
    ctx:lineTo(width, centerY);
    ctx:stroke();
    
    -- Draw waveform
    local samples = LearningToolUI.audioSamples;
    if #samples < 2 then
        return;
    end
    
    ctx.strokeStyle = "#4CAF50"; -- Green
    ctx.lineWidth = 2;
    ctx:beginPath();
    
    local step = width / math.max(#samples - 1, 1);
    for i, sample in ipairs(samples) do
        local x = (i - 1) * step;
        local y = centerY - sample * (height / 2 - 4);
        
        if i == 1 then
            ctx:moveTo(x, y);
        else
            ctx:lineTo(x, y);
        end
    end
    
    ctx:stroke();
end

--------------------------------------------------------------------------------
-- VoiceContextManager Integration
--------------------------------------------------------------------------------

--[[
    Connect to VoiceContextManager signals for TTS state sync
]]
function LearningToolUI.ConnectToVoiceManager()
    if LearningToolUI.isConnectedToVoiceManager then
        return;
    end
    
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/VoiceContextManager.lua");
    local VoiceContextManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.VoiceContextManager");
    
    if VoiceContextManager and VoiceContextManager.Init then
        VoiceContextManager:Init();
        
        -- Connect to stateChanged signal
        VoiceContextManager:Connect("stateChanged", LearningToolUI, LearningToolUI.OnVoiceStateChanged, "UniqueConnection");
        LearningToolUI.isConnectedToVoiceManager = true;
        
        LOG.std(nil, "debug", "LearningToolUI", "Connected to VoiceContextManager");
    end
end

--[[
    Disconnect from VoiceContextManager signals
]]
function LearningToolUI.DisconnectFromVoiceManager()
    if not LearningToolUI.isConnectedToVoiceManager then
        return;
    end
    
    local VoiceContextManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.VoiceContextManager");
    if VoiceContextManager then
        VoiceContextManager:Disconnect("stateChanged", LearningToolUI, LearningToolUI.OnVoiceStateChanged);
    end
    
    LearningToolUI.isConnectedToVoiceManager = false;
end

--[[
    Handle VoiceContextManager state change (for TTS playback detection)
    @param newState: string - New state
]]
function LearningToolUI.OnVoiceStateChanged(newState)
    local VoiceContextManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.VoiceContextManager");
    
    if VoiceContextManager and VoiceContextManager:IsPausedForTTS() then
        -- TTS is playing externally, update our state for UI
        if LearningToolUI.audioState == "idle" then
            LearningToolUI.audioState = "speaking";
            LearningToolUI.RefreshUI();
        end
    else
        -- TTS stopped
        if LearningToolUI.audioState == "speaking" then
            LearningToolUI.audioState = "idle";
            LearningToolUI.RefreshUI();
        end
    end
end

--------------------------------------------------------------------------------
-- Result Handling
--------------------------------------------------------------------------------

--[[
    Submit user answer and show feedback
    @param isCorrect: boolean - Whether the answer is correct
    @param userAnswer: any - The user's answer
    @param additionalData: table (optional) - Additional result data
]]
function LearningToolUI.SubmitAnswer(isCorrect, userAnswer, additionalData)
    local result = {
        success = true,
        correct = isCorrect,
        userAnswer = userAnswer,
        toolName = LearningToolUI.currentToolName,
        params = LearningToolUI.currentParams,
    };
    
    if additionalData then
        for k, v in pairs(additionalData) do
            result[k] = v;
        end
    end
    
    -- Show visual feedback
    LearningToolUI.ShowFeedback(isCorrect, function()
        -- Close dialog and report result after feedback
        LearningToolUI.Close(result);
    end);
end

--[[
    Show visual feedback animation for correct/incorrect answer
    @param isCorrect: boolean
    @param onComplete: function - Called when feedback animation completes
]]
function LearningToolUI.ShowFeedback(isCorrect, onComplete)
    -- Update feedback UI element
    if LearningToolUI.currentPage then
        local feedbackText = isCorrect and "正确! ✓" or "再试一次 ✗";
        local feedbackColor = isCorrect and "#4CAF50" or "#F44336";
        
        -- Try to update feedback element via page refresh
        LearningToolUI.feedbackResult = {
            show = true,
            text = feedbackText,
            color = feedbackColor,
            isCorrect = isCorrect,
        };
        LearningToolUI.currentPage:Refresh(0.01);
    end
    
    -- Cancel any existing feedback timer
    if LearningToolUI.feedbackTimer then
        LearningToolUI.feedbackTimer:Change();
        LearningToolUI.feedbackTimer = nil;
    end
    
    -- Capture current session to verify validity when timer fires
    local sessionWhenStarted = LearningToolUI.currentSessionId;
    
    -- Wait before completing
    LearningToolUI.feedbackTimer = commonlib.TimerManager.SetTimeout(function()
        -- Only proceed if we're still on the same session
        -- This prevents closing a newly opened window
        if LearningToolUI.currentSessionId ~= sessionWhenStarted then
            LOG.std(nil, "debug", "LearningToolUI", "Feedback timer ignored: session changed (was %s, now %s)",
                sessionWhenStarted or "nil", LearningToolUI.currentSessionId or "nil");
            return;
        end
        
        LearningToolUI.feedbackTimer = nil;
        LearningToolUI.feedbackResult = nil;
        if onComplete then
            onComplete();
        end
    end, LearningToolUI.feedbackDelayMs);
end

--[[
    Get feedback result for MCML page
    @return table or nil
]]
function LearningToolUI.GetFeedbackResult()
    return LearningToolUI.feedbackResult;
end

--[[
    Report result to BackgroundAgent
    @param sessionId: string - Session ID
    @param result: table - Result data
]]
function LearningToolUI.ReportResult(sessionId, result)
    if not sessionId then
        return;
    end
    
    -- Get BackgroundAgent and call OnLearningToolResult
    local BackgroundAgent = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BackgroundAgent");
    if BackgroundAgent and BackgroundAgent.GetInstance then
        local agent = BackgroundAgent:GetInstance();
        if agent and agent.OnLearningToolResult then
            agent:OnLearningToolResult(sessionId, result);
            LOG.std(nil, "info", "LearningToolUI", "Reported result to BackgroundAgent: session=%s, correct=%s", 
                sessionId, tostring(result.correct));
        end
    end
end

--------------------------------------------------------------------------------
-- Answer Comparison Utilities
--------------------------------------------------------------------------------

--[[
    Compare two strings for spelling test (case/space/punctuation insensitive)
    @param expected: string
    @param actual: string
    @return boolean
]]
function LearningToolUI.CompareSpelling(expected, actual)
    if not expected or not actual then
        return false;
    end
    
    -- Normalize: lowercase, remove spaces and punctuation
    local function normalize(s)
        s = string.lower(s);
        s = string.gsub(s, "%s+", ""); -- Remove spaces
        s = string.gsub(s, "[%p]", ""); -- Remove punctuation
        return s;
    end
    
    return normalize(expected) == normalize(actual);
end

--[[
    Compare spoken text with expected (more lenient for pronunciation)
    @param expected: string
    @param transcript: string
    @return boolean, number - Match result and similarity score
]]
function LearningToolUI.CompareSpeaking(expected, transcript)
    if not expected or not transcript then
        return false, 0;
    end
    
    -- Normalize both strings
    local function normalize(s)
        s = string.lower(s);
        s = string.gsub(s, "%s+", " "); -- Normalize spaces
        s = string.gsub(s, "^%s+", ""); -- Trim leading
        s = string.gsub(s, "%s+$", ""); -- Trim trailing
        s = string.gsub(s, "[%p]", ""); -- Remove punctuation
        return s;
    end
    
    local normExpected = normalize(expected);
    local normTranscript = normalize(transcript);
    
    -- Exact match
    if normExpected == normTranscript then
        return true, 1.0;
    end
    
    -- Check if expected is contained in transcript (for simple words)
    if string.find(normTranscript, normExpected, 1, true) then
        return true, 0.9;
    end
    
    -- Simple similarity based on common prefix/suffix
    local minLen = math.min(#normExpected, #normTranscript);
    local matches = 0;
    for i = 1, minLen do
        if string.sub(normExpected, i, i) == string.sub(normTranscript, i, i) then
            matches = matches + 1;
        end
    end
    
    local similarity = matches / math.max(#normExpected, 1);
    return similarity >= 0.7, similarity;
end

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------

--[[
    Get dialog size based on tool type
    @param toolName: string
    @return number, number - width, height
]]
function LearningToolUI.GetDialogSize(toolName)
    local sizes = {
        test_multiple_choice = {400, 380},
        test_words_spelling = {400, 300},
        test_words_speaking = {450, 380},
        show_learning_content = {450, 400},
    };
    
    local size = sizes[toolName] or {400, 350};
    return size[1], size[2];
end

--[[
    Refresh the current MCML page
]]
function LearningToolUI.RefreshUI()
    if LearningToolUI.currentPage then
        LearningToolUI.currentPage:Refresh(0.01);
    end
end

--[[
    Initialize the UI for MCML page (called from HTML)
]]
function LearningToolUI.OnInit()
    -- Called when MCML page initializes
end

return LearningToolUI;
