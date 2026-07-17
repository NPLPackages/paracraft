--[[
Title: Voice Context Manager
Author(s): LiXizhi, Copilot
Date: 2026/1/23
Desc: Continuously monitors audio input for user voice, automatically segments voice
      by silence detection, and converts segments to text via LLM API. Transcribed text
      is stored with timestamps for BackgroundAgent's continuous dialog system.

Features:
- Continuous voice monitoring with configurable silence threshold
- Automatic voice segmentation based on silence detection
- Speech-to-text transcription via keepwork.ai API
- Immediate transcription with debounce (no batching)
- Auto-cleanup of audio files after transcription
- Integration with BackgroundAgent dialog history

Use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/VoiceContextManager.lua");
local VoiceContextManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.VoiceContextManager");
VoiceContextManager:Init();

-- Start continuous voice monitoring
VoiceContextManager:Start();

-- Get recent voice transcripts
local history = VoiceContextManager:GetVoiceHistory();

-- Connect to transcription events
VoiceContextManager:Connect("voiceTranscribed", function(entry)
    echo("User said: " .. entry.transcript);
end);

-- Stop monitoring
VoiceContextManager:Stop();

-- Pause/Resume
VoiceContextManager:Pause();
VoiceContextManager:Resume();

-- Show debug UI for testing
VoiceContextManager:ShowDebugUI(true);
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.ai.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");

local VoiceContextManager = commonlib.inherit(
    commonlib.gettable("System.Core.ToolBase"),
    commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.VoiceContextManager")
);

VoiceContextManager:Property("Name", "VoiceContextManager");
VoiceContextManager:Signal("voiceTranscribed");     -- Emitted when voice segment is transcribed
VoiceContextManager:Signal("voiceRecordingStarted"); -- Emitted when recording starts
VoiceContextManager:Signal("voiceRecordingStopped"); -- Emitted when recording stops (before transcription)
VoiceContextManager:Signal("transcriptionFailed");   -- Emitted when transcription fails
VoiceContextManager:Signal("stateChanged");          -- Emitted when monitoring state changes

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------
VoiceContextManager.silenceThreshold = 0.1;         -- Normalized energy threshold for voice detection (0.0-1.0)
VoiceContextManager.silenceDurationMs = 400;        -- ms of silence to trigger segment end (reduced for phone-call-like response)
VoiceContextManager.minSegmentDurationMs = 300;     -- Minimum voice segment duration to process
VoiceContextManager.minSegmentBytes = 16000;        -- Minimum audio data bytes (~350ms at 22KHz) - reduced for faster response
VoiceContextManager.maxSegmentBytes = 880000;       -- Maximum audio data bytes (~20 seconds)
VoiceContextManager.maxSegmentDurationMs = 30000;   -- Maximum segment duration before forced split
VoiceContextManager.debounceCooldownMs = 200;       -- ms cooldown between transcription requests
VoiceContextManager.maxHistorySize = 50;            -- Max stored voice history entries
VoiceContextManager.recordSoundQuality = 0.3;       -- Audio quality [0.1-1.0]
VoiceContextManager.language = "LLM";               -- Default language: "LLM" (all languages), "zh", or "en"
VoiceContextManager.tempFilePath = "temp/voice_context/"; -- Temp directory for audio files

-- Audio energy detection settings (optimized for low-latency phone-call-like response)
VoiceContextManager.sensitivity = 1000;             -- Energy sensitivity [1000-32767], higher = less sensitive
VoiceContextManager.energyIntegration = 0.7;        -- Energy smoothing factor (reduced for faster response)
VoiceContextManager.minEnergyIntegration = 0.95;    -- Min energy tracking smoothing (faster ambient tracking)
VoiceContextManager.energyOffset = 0.05;            -- Base threshold offset above min energy
VoiceContextManager.voiceHold = 10;                 -- Frames to hold voice state after energy drops (~300ms)

-- Auto-calibration settings
VoiceContextManager.calibrationFrames = 15;         -- Frames to collect for initial calibration (~450ms)
VoiceContextManager.calibrationPercentile = 0.2;    -- Use 20th percentile of samples as baseline
VoiceContextManager.adaptiveThresholdMin = 0.3;     -- Min multiplier for adaptive threshold
VoiceContextManager.adaptiveThresholdMax = 1.5;     -- Max multiplier for adaptive threshold
VoiceContextManager.snrMultiplier = 0.15;           -- SNR-based threshold multiplier
VoiceContextManager.hysteresisRatio = 0.6;          -- Exit threshold = enter threshold * ratio
VoiceContextManager.silenceRecalibrationMs = 3000;  -- Recalibrate after this much silence
VoiceContextManager.preRollFrames = 3;              -- Keep N frames of audio before voice detection

-- TTS loopback prevention settings
VoiceContextManager.ttsResumeDelayMs = 200;         -- ms delay after TTS stops before resuming recording to avoid echo/reverb capture

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function VoiceContextManager:ctor()
    self.voiceHistory = {};             -- Array of {id, startTime, endTime, duration, transcript, confidence}
    self.isInitialized = false;
    self.monitoringState = "stopped";   -- "stopped", "monitoring", "paused", "recording"
    
    -- Timer references
    self.debounceTimer = nil;
    
    -- Recording state
    self.isRecording = false;
    self.recordingStartTime = nil;
    self.currentSegmentId = 0;
    self.pendingTranscription = false;
    
    -- Audio data accumulation
    self.recordData = nil;              -- Accumulated audio data during voice detection
    self.preRollBuffer = {};            -- Circular buffer for pre-roll audio frames
    
    -- Audio energy tracking for voice activity detection
    self.energy = 0;
    self.minEnergy = math.huge;
    self.maxEnergy = 0;                 -- Track max energy for dynamic range
    self.isSpeaking = false;
    self.voiceCounter = 0;
    self.silenceStartTime = nil;        -- Track silence duration
    self.lastSpeakingTime = 0;          -- For recalibration timing
    
    -- Auto-calibration state
    self.isCalibrating = false;
    self.calibrationSamples = {};       -- Energy samples during calibration
    self.calibrationFrameCount = 0;
    self.isCalibrated = false;
    
    -- Adaptive threshold state
    self.currentThreshold = 0;
    self.exitThreshold = 0;             -- Hysteresis: lower threshold to exit speaking state
    
    -- Debounce state
    self.lastTranscriptionTime = 0;
    
    -- Callback queue for async operations
    self.pendingCallbacks = {};
    
    -- Transcription queue for rate limiting
    self.transcriptionQueue = {};
    self.isTranscribing = false;
    
    -- TTS loopback prevention state
    self.ttsPlayingCount = 0;           -- Counter for nested TTS calls
    self.isPausedForTTS = false;        -- Whether paused due to TTS playback
    self.ttsResumeTimer = nil;          -- Timer for delayed resume after TTS
    self.stateBeforeTTS = nil;          -- State before TTS pause (to restore)
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

--[[
    Initialize the singleton manager
    @return self
]]
function VoiceContextManager:Init()
    if self.isInitialized then
        return self;
    end
    VoiceContextManager:InitSingleton();
    
    -- Ensure temp directory exists
    local tempPath = ParaIO.GetWritablePath() .. self.tempFilePath;
    ParaIO.CreateDirectory(tempPath);
    
    -- Request audio permission on Android
    if System.os.GetPlatform() == "android" then
        if RequestAndroidPermission and RequestAndroidPermission.RequestRecordAudioPermission then
            RequestAndroidPermission.RequestRecordAudioPermission();
        end
    end
    
    -- Connect to SoundManager TTS signals for loopback prevention
    self:ConnectToSoundManagerTTS();
    
    self.isInitialized = true;
    LOG.std(nil, "info", "VoiceContextManager", "Initialized");
    
    return self;
end

--[[
    Connect to SoundManager TTS signals to pause/resume voice recording during TTS playback.
    This prevents recording loopback audio from the system speaker.
]]
function VoiceContextManager:ConnectToSoundManagerTTS()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
    local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
    SoundManager:Init();
    
    -- Connect to ttsStarted signal
    SoundManager:Connect("ttsStarted", self, self.OnTTSStarted, "UniqueConnection");
    
    -- Connect to ttsStopped signal
    SoundManager:Connect("ttsStopped", self, self.OnTTSStopped, "UniqueConnection");
    
    LOG.std(nil, "debug", "VoiceContextManager", "Connected to SoundManager TTS signals");
end

--[[
    Handle TTS playback started - pause voice recording to prevent loopback
]]
function VoiceContextManager:OnTTSStarted()
    self.ttsPlayingCount = (self.ttsPlayingCount or 0) + 1;
    
    -- Cancel any pending resume timer
    if self.ttsResumeTimer then
        self.ttsResumeTimer:Change();
        self.ttsResumeTimer = nil;
    end
    
    -- Pause recording if currently active
    if self:IsActive() and not self.isPausedForTTS then
        self.stateBeforeTTS = self.monitoringState;
        self.isPausedForTTS = true;
        
        -- Discard any audio captured (may contain TTS start)
        self.recordData = nil;
        
        -- Stop audio recording
        self:StopAudioRecording();
        
        LOG.std(nil, "debug", "VoiceContextManager", "Paused for TTS playback (count: %d)", self.ttsPlayingCount);
    end
end

--[[
    Handle TTS playback stopped - resume voice recording after delay
]]
function VoiceContextManager:OnTTSStopped()
    self.ttsPlayingCount = math.max(0, (self.ttsPlayingCount or 1) - 1);
    
    -- Only resume when all TTS playback has stopped
    if self.ttsPlayingCount > 0 then
        LOG.std(nil, "debug", "VoiceContextManager", "TTS stopped but still playing (count: %d)", self.ttsPlayingCount);
        return;
    end
    
    -- Resume after delay if we were paused for TTS
    if self.isPausedForTTS then
        -- Cancel any existing resume timer
        if self.ttsResumeTimer then
            self.ttsResumeTimer:Change();
        end
        
        -- Start delayed resume
        self.ttsResumeTimer = commonlib.TimerManager.SetTimeout(function()
            self:ResumeFromTTS();
        end, self.ttsResumeDelayMs);
        
        LOG.std(nil, "debug", "VoiceContextManager", "TTS stopped, will resume in %dms", self.ttsResumeDelayMs);
    end
end

--[[
    Resume voice recording after TTS playback has stopped
]]
function VoiceContextManager:ResumeFromTTS()
    self.ttsResumeTimer = nil;
    
    if not self.isPausedForTTS then
        return;
    end
    
    -- Check if TTS started again while we were waiting
    if self.ttsPlayingCount > 0 then
        LOG.std(nil, "debug", "VoiceContextManager", "TTS started again, not resuming");
        return;
    end
    
    self.isPausedForTTS = false;
    
    -- Resume recording if we were active before TTS
    if self.stateBeforeTTS == "monitoring" or self.stateBeforeTTS == "recording" then
        self.monitoringState = "monitoring";
        self:StartAudioRecording();
        self:stateChanged("monitoring");
        LOG.std(nil, "debug", "VoiceContextManager", "Resumed voice recording after TTS");
    end
    
    self.stateBeforeTTS = nil;
end

--[[
    Check if currently paused due to TTS playback
    @return boolean
]]
function VoiceContextManager:IsPausedForTTS()
    return self.isPausedForTTS == true;
end

--------------------------------------------------------------------------------
-- Lifecycle Control
--------------------------------------------------------------------------------

--[[
    Start continuous voice monitoring
    @return self
]]
function VoiceContextManager:Start()
    if not self.isInitialized then
        self:Init();
    end
    
    if self.monitoringState == "monitoring" or self.monitoringState == "recording" then
        LOG.std(nil, "warn", "VoiceContextManager", "Already monitoring");
        return self;
    end
    
    self.monitoringState = "monitoring";
    self:StartAudioRecording();
    self:stateChanged("monitoring");
    
    LOG.std(nil, "info", "VoiceContextManager", "Voice monitoring started");
    return self;
end

--[[
    Stop voice monitoring completely
    @return self
]]
function VoiceContextManager:Stop()
    if self.monitoringState == "stopped" then
        return self;
    end
    
    -- Stop audio recording
    self:StopAudioRecording();
    
    -- Process any remaining recorded data
    if self.recordData and #self.recordData > self.minSegmentBytes then
        self:ProcessRecordedData();
    end
    self.recordData = nil;
    
    self.monitoringState = "stopped";
    self:stateChanged("stopped");
    
    LOG.std(nil, "info", "VoiceContextManager", "Voice monitoring stopped");
    return self;
end

--[[
    Pause voice monitoring (keeps state, can resume)
    @return self
]]
function VoiceContextManager:Pause()
    if self.monitoringState ~= "monitoring" and self.monitoringState ~= "recording" then
        return self;
    end
    
    -- Stop audio recording
    self:StopAudioRecording();
    
    -- Process any accumulated data
    if self.recordData and #self.recordData > self.minSegmentBytes then
        self:ProcessRecordedData();
    end
    self.recordData = nil;
    
    self.monitoringState = "paused";
    self:stateChanged("paused");
    
    LOG.std(nil, "info", "VoiceContextManager", "Voice monitoring paused");
    return self;
end

--[[
    Resume paused voice monitoring
    @return self
]]
function VoiceContextManager:Resume()
    if self.monitoringState ~= "paused" then
        return self;
    end
    
    self.monitoringState = "monitoring";
    self:StartAudioRecording();
    self:stateChanged("monitoring");
    
    LOG.std(nil, "info", "VoiceContextManager", "Voice monitoring resumed");
    return self;
end

--[[
    Get current monitoring state
    @return string - "stopped", "monitoring", "paused", "paused_tts", or "recording"
]]
function VoiceContextManager:GetState()
    -- Return special state when paused for TTS playback
    if self.isPausedForTTS then
        return "paused_tts";
    end
    return self.monitoringState;
end

--[[
    Check if currently monitoring or recording
    @return boolean
]]
function VoiceContextManager:IsActive()
    return self.monitoringState == "monitoring" or self.monitoringState == "recording";
end

--------------------------------------------------------------------------------
-- Audio Recording with Real-time Data Callback
--------------------------------------------------------------------------------

--[[
    Start audio recording with real-time data callback
]]
function VoiceContextManager:StartAudioRecording()
    if self.isRecording then
        return;
    end
    
    self.isRecording = true;
    self.recordingStartTime = commonlib.TimerManager.GetCurrentTime();
    self.recordData = nil;
    self.preRollBuffer = {};
    self.energy = 0;
    self.minEnergy = math.huge;
    self.maxEnergy = 0;
    self.isSpeaking = false;
    self.voiceCounter = 0;
    self.silenceStartTime = nil;
    self.lastSpeakingTime = 0;
    
    -- Start auto-calibration period
    self.isCalibrating = true;
    self.calibrationSamples = {};
    self.calibrationFrameCount = 0;
    self.isCalibrated = false;
    self.currentThreshold = 0.1;  -- Initial safe threshold
    self.exitThreshold = 0.05;
    
    -- Start recording with callback that receives audio data chunks
    local self_ = self;
    AudioEngine.StartRecording(function(data)
        self_:OnAudioData(data);
    end);
    
    self:voiceRecordingStarted();
    LOG.std(nil, "debug", "VoiceContextManager", "Audio recording started (calibrating...)");
end

--[[
    Stop audio recording
]]
function VoiceContextManager:StopAudioRecording()
    if not self.isRecording then
        return;
    end
    
    self.isRecording = false;
    
    -- Stop recording
    AudioEngine.StopRecording();
    
    self:voiceRecordingStopped();
    LOG.std(nil, "debug", "VoiceContextManager", "Audio recording stopped");
end

--[[
    Handle incoming audio data chunk
    @param data: string - Raw audio data (16-bit PCM)
]]
function VoiceContextManager:OnAudioData(data)
    if not data or self.monitoringState == "stopped" or self.monitoringState == "paused" then
        return;
    end
    
    local currentTime = commonlib.TimerManager.GetCurrentTime();
    
    -- Calculate energy from audio data
    local energy = self:CalculateEnergy(data);
    
    -- Update energy with smoothing
    if self.energy == 0 then
        self.energy = energy;
    end
    self.energy = self.energyIntegration * self.energy + (1 - self.energyIntegration) * energy;
    
    -- Manage pre-roll buffer (circular buffer of recent frames)
    table.insert(self.preRollBuffer, data);
    while #self.preRollBuffer > self.preRollFrames do
        table.remove(self.preRollBuffer, 1);
    end
    
    -- Auto-calibration phase: collect ambient noise samples
    if self.isCalibrating then
        table.insert(self.calibrationSamples, energy);
        self.calibrationFrameCount = self.calibrationFrameCount + 1;
        
        if self.calibrationFrameCount >= self.calibrationFrames then
            -- Sort samples and take percentile as baseline
            table.sort(self.calibrationSamples);
            local percentileIndex = math.max(1, math.floor(#self.calibrationSamples * self.calibrationPercentile));
            self.minEnergy = self.calibrationSamples[percentileIndex];
            self.maxEnergy = self.calibrationSamples[#self.calibrationSamples];
            
            -- Calculate initial adaptive threshold
            self:UpdateAdaptiveThreshold();
            
            self.isCalibrating = false;
            self.isCalibrated = true;
            self.calibrationSamples = {}; -- Free memory
            
            LOG.std(nil, "info", "VoiceContextManager", "Calibration complete: minEnergy=%.4f, threshold=%.4f", 
                self.minEnergy, self.currentThreshold);
        end
        return; -- Don't process speech during calibration
    end
    
    -- Track minimum and maximum energy when not speaking (for dynamic threshold)
    if not self.isSpeaking then
        self.minEnergy = math.min(
            self.minEnergyIntegration * self.minEnergy + (1 - self.minEnergyIntegration) * self.energy,
            self.energy
        );
        
        -- Recalibrate if silent for extended period
        if self.lastSpeakingTime > 0 and (currentTime - self.lastSpeakingTime) > self.silenceRecalibrationMs then
            self:UpdateAdaptiveThreshold();
            self.lastSpeakingTime = 0; -- Reset to avoid repeated recalibration
        end
    else
        -- Track max energy during speech for SNR calculation
        self.maxEnergy = math.max(
            0.95 * self.maxEnergy + 0.05 * self.energy,
            self.energy
        );
    end
    
    -- Update adaptive threshold periodically
    self:UpdateAdaptiveThreshold();
    
    -- Voice activity detection with hysteresis
    local wasSpeaking = self.isSpeaking;
    if not self.isSpeaking then
        -- Use higher threshold to START speaking (enter threshold)
        if self.energy > self.currentThreshold then
            self.isSpeaking = true;
            self.voiceCounter = self.voiceHold;
            self.silenceStartTime = nil;
            self.lastSpeakingTime = currentTime;
            
            -- Include pre-roll buffer when starting speech
            if not self.recordData then
                self.recordData = table.concat(self.preRollBuffer);
            end
        end
    else
        -- Use lower threshold to STOP speaking (exit threshold with hysteresis)
        if self.energy > self.exitThreshold then
            self.voiceCounter = self.voiceHold;
            self.silenceStartTime = nil;
        else
            if self.voiceCounter > 0 then
                self.voiceCounter = self.voiceCounter - 1;
            else
                -- Voice hold expired, start silence timer
                if not self.silenceStartTime then
                    self.silenceStartTime = currentTime;
                end
                
                -- Check if silence duration exceeded
                if (currentTime - self.silenceStartTime) >= self.silenceDurationMs then
                    self.isSpeaking = false;
                    self.silenceStartTime = nil;
                end
            end
        end
    end
    
    -- Accumulate data when speaking
    if self.isSpeaking then
        self.recordData = (self.recordData or "") .. data;
        self.monitoringState = "recording";
    else
        -- Not speaking - check if we have enough data to process
        if self.recordData then
            if #self.recordData > self.minSegmentBytes then
                -- Process data even if max size exceeded (don't discard)
                if #self.recordData > self.maxSegmentBytes then
                    LOG.std(nil, "warn", "VoiceContextManager", "Record data at max size, processing: %d bytes", #self.recordData);
                end
                
                LOG.std(nil, "debug", "VoiceContextManager", "Voice segment ended, bytes: %d", #self.recordData);
                self:ProcessRecordedData();
            else
                LOG.std(nil, "debug", "VoiceContextManager", "Voice segment too short, discarding: %d bytes", #self.recordData);
            end
            self.recordData = nil;
        end
        self.monitoringState = "monitoring";
    end
    
    -- Force process if data gets too large (but don't discard)
    if self.recordData and #self.recordData > self.maxSegmentBytes then
        LOG.std(nil, "debug", "VoiceContextManager", "Max segment size reached, processing");
        self:ProcessRecordedData();
        self.recordData = nil;
    end
end

--[[
    Update adaptive threshold based on current noise floor and signal-to-noise ratio
]]
function VoiceContextManager:UpdateAdaptiveThreshold()
    -- Calculate SNR-based adaptive offset
    local snr = self.maxEnergy / math.max(self.minEnergy, 0.001);
    local adaptiveMultiplier = math.max(
        self.adaptiveThresholdMin,
        math.min(self.adaptiveThresholdMax, snr * self.snrMultiplier)
    );
    
    local adaptiveOffset = self.minEnergy * adaptiveMultiplier + self.energyOffset;
    
    -- Enter threshold (to start speaking)
    self.currentThreshold = self.minEnergy + adaptiveOffset;
    
    -- Exit threshold with hysteresis (lower, to stop speaking)
    self.exitThreshold = self.minEnergy + adaptiveOffset * self.hysteresisRatio;
end

--[[
    Force recalibration of ambient noise level
    Call this when environment changes significantly
]]
function VoiceContextManager:ForceRecalibrate()
    self.isCalibrating = true;
    self.calibrationSamples = {};
    self.calibrationFrameCount = 0;
    self.isCalibrated = false;
    LOG.std(nil, "info", "VoiceContextManager", "Forcing recalibration...");
end

--[[
    Calculate energy level from raw audio data
    @param data: string - Raw 16-bit PCM audio data
    @return number - Normalized energy level
]]
function VoiceContextManager:CalculateEnergy(data)
    local i = 1;
    local posSum, posCount = 0, 0;
    local negSum, negCount = 0, 0;
    
    while i <= #data - 1 do
        local lowByte = string.byte(data, i);
        local highByte = string.byte(data, i + 1);
        
        -- Convert from two bytes to int16 with sign
        local value;
        if highByte > 127 then
            highByte = 255 - highByte;
            lowByte = 255 - lowByte;
            value = -(lowByte + highByte * 256);
        else
            value = lowByte + highByte * 256;
        end
        
        i = i + 2;
        
        if value >= 0 then
            posSum = posSum + value;
            posCount = posCount + 1;
        else
            negSum = negSum + value;
            negCount = negCount + 1;
        end
    end
    
    posSum = posCount > 0 and posSum / posCount / self.sensitivity or 0;
    negSum = negCount > 0 and negSum / negCount / self.sensitivity or 0;
    
    return math.max(posSum, -negSum);
end

--[[
    Process accumulated recorded data - transcribe directly without writing to disk
]]
function VoiceContextManager:ProcessRecordedData()
    if not self.recordData or #self.recordData == 0 then
        return;
    end
    
    -- Debounce check to prevent rapid-fire API calls
    local currentTime = commonlib.TimerManager.GetCurrentTime();
    if currentTime - self.lastTranscriptionTime < self.debounceCooldownMs then
        LOG.std(nil, "debug", "VoiceContextManager", "Debounce: skipping transcription (too soon)");
        return;
    end
    self.lastTranscriptionTime = currentTime;
    
    self.currentSegmentId = self.currentSegmentId + 1;
    local segmentId = self.currentSegmentId;
    local dataToProcess = self.recordData;
    
    LOG.std(nil, "info", "VoiceContextManager", "Processing voice segment %d (%d bytes)", segmentId, #dataToProcess);
    
    -- Create history entry
    local entry = {
        id = string.format("voice_%d_%d", os.time(), segmentId),
        startTime = os.time(),
        endTime = os.time(),
        duration = #dataToProcess / 44, -- approximate ms (22KHz * 2 bytes)
        transcript = nil,
        confidence = nil,
        isProcessing = true,
    };
    
    -- Queue for transcription (handles rate limiting)
    self:QueueTranscription(dataToProcess, entry);
end

--[[
    Queue a transcription request to handle rate limiting
    @param pcmData: string - Raw PCM audio data
    @param entry: table - Voice history entry
]]
function VoiceContextManager:QueueTranscription(pcmData, entry)
    table.insert(self.transcriptionQueue, { pcmData = pcmData, entry = entry });
    self:ProcessTranscriptionQueue();
end

--[[
    Process the transcription queue (one at a time)
]]
function VoiceContextManager:ProcessTranscriptionQueue()
    if self.isTranscribing or #self.transcriptionQueue == 0 then
        return;
    end
    
    self.isTranscribing = true;
    local item = table.remove(self.transcriptionQueue, 1);
    self:TranscribeAudioData(item.pcmData, item.entry);
end

--------------------------------------------------------------------------------
-- Speech-to-Text Transcription
--------------------------------------------------------------------------------

--[[
    Create WAV header for raw PCM data
    @param dataLength: number - Length of PCM data in bytes
    @param sampleRate: number - Sample rate (default 22050)
    @param bitsPerSample: number - Bits per sample (default 16)
    @param numChannels: number - Number of channels (default 1)
    @return string - WAV header (44 bytes)
]]
function VoiceContextManager:CreateWavHeader(dataLength, sampleRate, bitsPerSample, numChannels)
    sampleRate = sampleRate or 22050;
    bitsPerSample = bitsPerSample or 16;
    numChannels = numChannels or 1;
    
    local byteRate = sampleRate * numChannels * bitsPerSample / 8;
    local blockAlign = numChannels * bitsPerSample / 8;
    local fileSize = dataLength + 36; -- 44 - 8 for RIFF header
    
    -- Helper to write little-endian integers
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
    
    -- Build WAV header
    local header = "RIFF"                      -- ChunkID
        .. writeInt32(fileSize)                 -- ChunkSize
        .. "WAVE"                               -- Format
        .. "fmt "                               -- Subchunk1ID
        .. writeInt32(16)                       -- Subchunk1Size (16 for PCM)
        .. writeInt16(1)                        -- AudioFormat (1 = PCM)
        .. writeInt16(numChannels)              -- NumChannels
        .. writeInt32(sampleRate)               -- SampleRate
        .. writeInt32(byteRate)                 -- ByteRate
        .. writeInt16(blockAlign)               -- BlockAlign
        .. writeInt16(bitsPerSample)            -- BitsPerSample
        .. "data"                               -- Subchunk2ID
        .. writeInt32(dataLength);              -- Subchunk2Size
    
    return header;
end

--[[
    Transcribe raw PCM audio data using keepwork.ai API (no disk I/O)
    @param pcmData: string - Raw 16-bit PCM audio data
    @param entry: table - Voice history entry to update
]]
function VoiceContextManager:TranscribeAudioData(pcmData, entry)
    if not pcmData or #pcmData == 0 then
        LOG.std(nil, "warn", "VoiceContextManager", "No audio data to transcribe");
        self:OnTranscriptionFailed(entry, "no_data");
        return;
    end
    
    -- Create WAV header and combine with PCM data
    local wavHeader = self:CreateWavHeader(#pcmData);
    local wavData = wavHeader .. pcmData;
    
    -- Determine language for this transcription
    local langForTranscription = self.language;
    
    -- Determine language ID for API
    -- "LLM" uses LLM-based transcription supporting almost all languages
    local langId = nil; -- Default Chinese
    if langForTranscription == "LLM" then
        langId = "LLM"; -- LLM-based transcription (all languages)
    elseif langForTranscription == "en" or langForTranscription == "enUS" or langForTranscription == "English" then
        langId = "1737"; -- English
    end
    
    -- Call API with in-memory WAV data
    keepwork.ai.audioEncode2Text({
        format = "wav",
        dev_pid = langId,
        speech = commonlib.Encoding.base64(wavData),
    }, function(err, msg, data)
        self:OnTranscriptionResponse(err, msg, data, entry);
    end);
    
    LOG.std(nil, "debug", "VoiceContextManager", "Sent audio for transcription (%d bytes, lang=%s)", #wavData, langForTranscription or "zh");
end

--[[
    Transcribe audio file using keepwork.ai API (legacy method for manual recording)
    @param audioFile: string - Path to audio file
    @param entry: table - Voice history entry to update
]]
function VoiceContextManager:TranscribeAudioFile(audioFile, entry)
    -- Read audio file content
    local content = commonlib.Files.GetFileText(audioFile);
    if not content or #content == 0 then
        LOG.std(nil, "warn", "VoiceContextManager", "Failed to read audio file: %s", audioFile);
        self:OnTranscriptionFailed(entry, "read_failed");
        return;
    end
    
    -- Determine language ID
    -- "LLM" uses LLM-based transcription supporting almost all languages
    local langId = nil; -- Default Chinese
    if self.language == "LLM" then
        langId = "LLM"; -- LLM-based transcription (all languages)
    elseif self.language == "en" or self.language == "enUS" or self.language == "English" then
        langId = "1737"; -- English
    end
    
    -- Call API
    keepwork.ai.audioEncode2Text({
        format = "wav",
        dev_pid = langId,
        speech = commonlib.Encoding.base64(content),
    }, function(err, msg, data)
        self:OnTranscriptionResponse(err, msg, data, entry, audioFile);
    end);
    
    LOG.std(nil, "debug", "VoiceContextManager", "Sent audio for transcription: %s", audioFile);
end

--[[
    Handle transcription API response
    @param err: number - HTTP status code
    @param msg: table - Response message
    @param data: table - Response data
    @param entry: table - Voice history entry
    @param audioFile: string (optional) - Audio file path (for cleanup, only used by legacy file-based method)
]]
function VoiceContextManager:OnTranscriptionResponse(err, msg, data, entry, audioFile)
    -- Delete audio file if provided (only for legacy file-based method)
    if audioFile then
        self:DeleteAudioFile(audioFile);
    end
    
    entry.isProcessing = false;
    
    if err ~= 200 then
        local errorMsg = "unknown";
        if err == 429 then
            errorMsg = "rate_limited";
        elseif err == 500 then
            errorMsg = "server_error";
        elseif err == 400 and data and data.message then
            errorMsg = data.message;
        end
        
        LOG.std(nil, "warn", "VoiceContextManager", "Transcription failed: %s (code: %d)", errorMsg, err);
        self:OnTranscriptionFailed(entry, errorMsg);
        return;
    end
    
    -- Extract transcript from response
    local transcript = data and data.data;
    if not transcript or transcript == "" then
        LOG.std(nil, "debug", "VoiceContextManager", "Empty transcription result");
        self:OnTranscriptionFailed(entry, "empty_result");
        return;
    end
    
    -- Update entry with transcript
    entry.transcript = transcript;
    entry.confidence = data.confidence or 1.0;
    
    -- Add to history
    self:AddToHistory(entry);
    
    -- Emit signal
    self:voiceTranscribed(entry);
    
    -- Notify BackgroundAgent if available
    self:NotifyBackgroundAgent(entry);
    
    LOG.std(nil, "info", "VoiceContextManager", "Transcribed: '%s'", transcript);
    
    -- Mark transcription as complete and process next in queue
    self.isTranscribing = false;
    self:ProcessTranscriptionQueue();
end

--[[
    Handle transcription failure
    @param entry: table - Voice history entry
    @param errorMsg: string - Error message
]]
function VoiceContextManager:OnTranscriptionFailed(entry, errorMsg)
    entry.transcript = nil;
    entry.error = errorMsg;
    self:transcriptionFailed(entry);
    
    -- Mark transcription as complete and process next in queue
    self.isTranscribing = false;
    self:ProcessTranscriptionQueue();
end

--[[
    Delete audio file immediately after transcription
    @param audioFile: string - Path to audio file
]]
function VoiceContextManager:DeleteAudioFile(audioFile)
    if audioFile and ParaIO.DoesFileExist(audioFile, true) then
        ParaIO.DeleteFile(audioFile);
        LOG.std(nil, "debug", "VoiceContextManager", "Deleted audio file: %s", audioFile);
    end
end

--------------------------------------------------------------------------------
-- Voice History Management
--------------------------------------------------------------------------------

--[[
    Add transcription entry to history
    @param entry: table - Voice history entry
]]
function VoiceContextManager:AddToHistory(entry)
    table.insert(self.voiceHistory, entry);
    
    -- Trim history if exceeded max size
    while #self.voiceHistory > self.maxHistorySize do
        table.remove(self.voiceHistory, 1);
    end
end

--[[
    Get voice history
    @param count: number (optional) - Number of recent entries to return
    @return table - Array of voice history entries
]]
function VoiceContextManager:GetVoiceHistory(count)
    if not count then
        return self.voiceHistory;
    end
    
    local result = {};
    local startIdx = math.max(1, #self.voiceHistory - count + 1);
    for i = startIdx, #self.voiceHistory do
        table.insert(result, self.voiceHistory[i]);
    end
    return result;
end

--[[
    Get recent transcripts as plain text
    @param count: number (optional) - Number of recent entries
    @param separator: string (optional) - Separator between entries (default: "\n")
    @return string - Concatenated transcripts
]]
function VoiceContextManager:GetRecentTranscripts(count, separator)
    count = count or 5;
    separator = separator or "\n";
    
    local texts = {};
    local history = self:GetVoiceHistory(count);
    for _, entry in ipairs(history) do
        if entry.transcript then
            table.insert(texts, entry.transcript);
        end
    end
    return table.concat(texts, separator);
end

--[[
    Clear voice history
]]
function VoiceContextManager:ClearHistory()
    self.voiceHistory = {};
    LOG.std(nil, "info", "VoiceContextManager", "Voice history cleared");
end

--------------------------------------------------------------------------------
-- BackgroundAgent Integration
--------------------------------------------------------------------------------

--[[
    Notify BackgroundAgent of new voice transcript
    @param entry: table - Voice history entry
]]
function VoiceContextManager:NotifyBackgroundAgent(entry)
    -- Try to get BackgroundAgent instance
    local BackgroundAgent = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BackgroundAgent");
    if BackgroundAgent and BackgroundAgent.GetInstance then
        local agent = BackgroundAgent:GetInstance();
        if agent and agent.AddToDialogHistory then
            agent:AddToDialogHistory("user", entry.transcript);
        end
    end
end

--[[
    Get voice context summary for LLM
    @param maxEntries: number (optional) - Max entries to include
    @return string - Markdown formatted voice context
]]
function VoiceContextManager:GetVoiceContextSummary(maxEntries)
    maxEntries = maxEntries or 10;
    local history = self:GetVoiceHistory(maxEntries);
    
    if #history == 0 then
        return "";
    end
    
    local md = "## Recent Voice Input\n";
    for i, entry in ipairs(history) do
        if entry.transcript then
            local timeStr = os.date("%H:%M:%S", entry.startTime);
            md = md .. string.format("- [%s] %s\n", timeStr, entry.transcript);
        end
    end
    
    return md;
end

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

--[[
    Set language for transcription
    @param lang: string - "LLM" (all languages), "zh" (Chinese), or "en" (English)
    @return self
]]
function VoiceContextManager:SetLanguage(lang)
    self.language = lang or "LLM";
    LOG.std(nil, "info", "VoiceContextManager", "Language set to: %s", self.language);
    return self;
end

--[[
    Set silence detection threshold
    @param threshold: number - Energy offset threshold (0.0 - 1.0)
    @return self
]]
function VoiceContextManager:SetSilenceThreshold(threshold)
    self.energyOffset = math.max(0, math.min(1, threshold));
    return self;
end

--[[
    Set sensitivity for voice detection
    @param sensitivity: number - Sensitivity value [1000-32767], higher = less sensitive
    @return self
]]
function VoiceContextManager:SetSensitivity(sensitivity)
    self.sensitivity = math.max(1000, math.min(32767, sensitivity));
    return self;
end

--[[
    Set silence duration for segment detection
    @param durationMs: number - Milliseconds of silence to trigger segment end
    @return self
]]
function VoiceContextManager:SetSilenceDuration(durationMs)
    self.silenceDurationMs = math.max(100, durationMs);
    return self;
end

--[[
    Set maximum segment duration
    @param durationMs: number - Maximum recording duration in milliseconds
    @return self
]]
function VoiceContextManager:SetMaxSegmentDuration(durationMs)
    self.maxSegmentDurationMs = math.max(1000, durationMs);
    return self;
end

--------------------------------------------------------------------------------
-- Manual Recording API
--------------------------------------------------------------------------------

--[[
    Manually trigger a recording session (ignores silence detection)
    Records for the specified duration and then transcribes.
    @param maxDurationMs: number (optional) - Max duration, default 10000ms
    @param callback: function (optional) - Called with transcript when done
]]
function VoiceContextManager:RecordManual(maxDurationMs, callback)
    maxDurationMs = maxDurationMs or 10000;
    
    -- Use the capture text command for manual recording
    NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/SoundRecorder.lua");
    local SoundRecorder = commonlib.gettable("MyCompany.Aries.Game.Movie.SoundRecorder");
    
    self.currentSegmentId = self.currentSegmentId + 1;
    local segmentId = self.currentSegmentId;
    
    local tempPath = ParaIO.GetWritablePath() .. self.tempFilePath;
    local filename = string.format("%svoice_manual_%d_%d.wav", tempPath, os.time(), segmentId);
    
    SoundRecorder.CaptureSound(filename, function(savedFile)
        if savedFile then
            LOG.std(nil, "info", "VoiceContextManager", "Manual recording saved: %s", savedFile);
            
            local entry = {
                id = string.format("voice_manual_%d_%d", os.time(), segmentId),
                startTime = os.time(),
                endTime = os.time(),
                duration = maxDurationMs,
                audioFile = savedFile,
                transcript = nil,
                confidence = nil,
                isProcessing = true,
            };
            
            -- Store callback for this segment
            if callback then
                self.pendingCallbacks[segmentId] = callback;
            end
            
            self:TranscribeAudioFile(savedFile, entry);
        else
            LOG.std(nil, "warn", "VoiceContextManager", "Manual recording failed");
            if callback then
                callback(nil, false);
            end
        end
    end, maxDurationMs / 1000, true); -- silent mode
end

--------------------------------------------------------------------------------
-- Debug UI
--------------------------------------------------------------------------------

--[[
    Show or hide debug UI for testing
    @param bShow: boolean - True to show, false to hide
]]
function VoiceContextManager:ShowDebugUI(bShow)
    if bShow then
        if not self.debugPage then
            local width, height = 450, 580;
            local params = {
                url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/VoiceContextManagerDebug.html",
                name = "VoiceContextManagerDebug.ShowPage",
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
                align = "_rt",
                x = -width - 20,
                y = 20,
                width = width,
                height = height,
            };
            System.App.Commands.Call("File.MCMLWindowFrame", params);
            self.debugPage = params._page;
            if self.debugPage then
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
function VoiceContextManager:RefreshDebugUI()
    if self.debugPage then
        self.debugPage:Refresh(0.1);
    end
end

--[[
    Destroy the manager and cleanup
]]
function VoiceContextManager:Destroy()
    self:Stop();
    
    if self.debounceTimer then
        self.debounceTimer:Change();
        self.debounceTimer = nil;
    end
    
    self:ShowDebugUI(false);
    
    self.voiceHistory = {};
    self.isInitialized = false;
    
    LOG.std(nil, "info", "VoiceContextManager", "Destroyed");
end

return VoiceContextManager;
