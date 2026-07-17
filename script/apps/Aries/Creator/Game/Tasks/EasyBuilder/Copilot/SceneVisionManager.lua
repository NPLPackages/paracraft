--[[
Title: Scene Vision Manager
Author(s): LiXizhi
Date: 2026/1/23
Desc: Manages scene screenshot capture for LLM agents, detecting scene changes
      (block modifications, camera movement) and caching recent screenshots.
Use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/SceneVisionManager.lua");
local SceneVisionManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.SceneVisionManager");
SceneVisionManager:Init();

-- Capture screenshot manually
SceneVisionManager:CaptureScreenshot(function(entry)
    echo(entry.path)
end)

-- Get history
local history = SceneVisionManager:GetScreenshotHistory()

-- Show debug UI
SceneVisionManager:ShowDebugUI(true)
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Scene/Viewports/Viewport.lua");
NPL.load("(gl)script/ide/System/Scene/Cameras/Camera.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
local Viewport = commonlib.gettable("System.Scene.Viewports.Viewport");
local Cameras = commonlib.gettable("System.Scene.Cameras");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local SceneVisionManager = commonlib.inherit(
    commonlib.gettable("System.Core.ToolBase"),
    commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.SceneVisionManager")
);

SceneVisionManager:Property("Name", "SceneVisionManager");
SceneVisionManager:Signal("sceneChanged");        -- Emitted when scene changes detected
SceneVisionManager:Signal("screenshotCaptured");  -- Emitted after capture

-- Configuration
SceneVisionManager.captureWidth = 400;
SceneVisionManager.captureHeight = 300;
SceneVisionManager.maxHistorySize = 10;
SceneVisionManager.debounceCooldown = 500;        -- ms before capture after last change
SceneVisionManager.updateInterval = 100;          -- ms between camera checks
SceneVisionManager.cameraChangeThreshold = 0.05;  -- threshold for camera change detection
SceneVisionManager.fileRetentionHours = 1;        -- hours to keep old files
SceneVisionManager.viewportFarPlane = 80;         -- reduced render distance for viewport
SceneVisionManager.tempFilePath = "temp/scene_vision/"; -- temp directory for screenshots

function SceneVisionManager:ctor()
    self.screenshotHistory = {};        -- Array of {timestamp, path, cameraPos}
    self.lastCameraPos = nil;
    self.blockChangeCount = 0;
    self.viewport = nil;
    self.updateTimer = nil;
    self.debounceTimer = nil;
    self.isDirty = false;
    self.isInitialized = false;
    self.debugPage = nil;
    self.passiveMode = false;           -- If true, only emit sceneChanged, don't auto-capture
    self.hasRenderedOnce = false;       -- Track if viewport has rendered at least once
    self.cleanupTimer = nil;            -- Timer for periodic old file cleanup
    self.isCapturing = false;           -- Guard against concurrent captures
    self.lastCaptureSecond = 0;         -- Throttle: at most one capture per second
end

-- Initialize the singleton manager
function SceneVisionManager:Init()
    if self.isInitialized then
        return self;
    end
    SceneVisionManager:InitSingleton();
    
    -- Ensure temp directory exists
    local tempPath = ParaIO.GetWritablePath() .. self.tempFilePath;
    ParaIO.CreateDirectory(tempPath);
    
    -- Clean up old files on init and schedule periodic cleanup every hour
    self:CleanupOldFiles();
    self:StartCleanupTimer();
    
    self:SetupEventListeners();
    self:CreateViewport();
    self:StartUpdateTimer();
    
    self.isInitialized = true;
    LOG.std(nil, "info", "SceneVisionManager", "Initialized");
    
    -- Capture initial screenshot on startup (skip in passive mode to avoid conflicting
    -- with the first on-demand capture triggered by the caller, e.g. BackgroundAgent:Step())
    if not self.passiveMode then
        self:CaptureScreenshot();
    end
    
    return self;
end

-- Setup event listeners for block changes
function SceneVisionManager:SetupEventListeners()
    local events = GameLogic.GetEvents();
    if events then
        events:AddEventListener("CreateBlockTask", self.OnBlockChange, self, "SceneVisionManager");
        events:AddEventListener("DestroyBlockTask", self.OnBlockChange, self, "SceneVisionManager");
    end
end

-- Remove event listeners
function SceneVisionManager:RemoveEventListeners()
    local events = GameLogic.GetEvents();
    if events then
        events:RemoveEventListener("CreateBlockTask", self.OnBlockChange, self);
        events:RemoveEventListener("DestroyBlockTask", self.OnBlockChange, self);
    end
end

-- Handle block creation/destruction events
function SceneVisionManager:OnBlockChange(event)
    self.blockChangeCount = self.blockChangeCount + 1;
    self:MarkDirty("block", event);
end

-- Create dedicated viewport for scene capture
function SceneVisionManager:CreateViewport()
    if self.viewport then
        return;
    end
    
    local viewport = Viewport:new():init("sceneVision");
    viewport:SetRenderTargetName("_miniscenegraph_sceneVision", self.captureWidth, self.captureHeight);
    viewport:SetFarPlane(self.viewportFarPlane);
    -- Keep viewport disabled by default, only render on demand
    viewport:SetEnabled(false);
    
    self.viewport = viewport;
    
    -- Initialize camera position
    self:SyncViewportCamera();
end

-- Sync viewport camera with main camera
function SceneVisionManager:SyncViewportCamera()
    if not self.viewport then
        return;
    end
    
    local camera = Cameras:GetCurrent();
    if not camera then
        return;
    end
    
    local eye_pos = camera:GetEyePosition();
    local att = ParaCamera.GetAttributeObject();
    local lookat_pos = att:GetField("Lookat position", {0, 0, 0});
    
    self.viewport:SetCameraViewParams(
        lookat_pos,                -- lookAt position
        eye_pos,                   -- eye position
        {0, 1, 0},                 -- camera up
        self.viewportFarPlane      -- far plane
    );
end

-- Get current camera position for comparison
function SceneVisionManager:GetCameraPosition()
    local camera = Cameras:GetCurrent();
    if not camera then
        return nil;
    end
    
    local eye_pos = camera:GetEyePosition();
    local att = ParaCamera.GetAttributeObject();
    local lookat_pos = att:GetField("Lookat position", {0, 0, 0});
    
    return {
        eye_x = eye_pos[1],
        eye_y = eye_pos[2],
        eye_z = eye_pos[3],
        lookat_x = lookat_pos[1],
        lookat_y = lookat_pos[2],
        lookat_z = lookat_pos[3],
    };
end

-- Check if camera has changed significantly
function SceneVisionManager:HasCameraChanged()
    local current = self:GetCameraPosition();
    if not current then
        return false;
    end
    
    if not self.lastCameraPos then
        self.lastCameraPos = current;
        return false;  -- no previous position to compare; just initialize, not a change
    end
    
    local posThreshold = 0.5;  -- blocks
    
    local changed = 
        math.abs(current.eye_x - self.lastCameraPos.eye_x) > posThreshold or
        math.abs(current.eye_y - self.lastCameraPos.eye_y) > posThreshold or
        math.abs(current.eye_z - self.lastCameraPos.eye_z) > posThreshold or
        math.abs(current.lookat_x - self.lastCameraPos.lookat_x) > posThreshold or
        math.abs(current.lookat_y - self.lastCameraPos.lookat_y) > posThreshold or
        math.abs(current.lookat_z - self.lastCameraPos.lookat_z) > posThreshold;
    
    if changed then
        self.lastCameraPos = current;
    end
    
    return changed;
end

-- Start the update timer for camera monitoring
function SceneVisionManager:StartUpdateTimer()
    if self.updateTimer then
        return;
    end
    
    self.updateTimer = commonlib.Timer:new({
        callbackFunc = function(timer)
            self:OnUpdate();
        end
    });
    self.updateTimer:Change(0, self.updateInterval);
end

-- Stop the update timer
function SceneVisionManager:StopUpdateTimer()
    if self.updateTimer then
        self.updateTimer:Change();
        self.updateTimer = nil;
    end
end

-- Periodic update callback
function SceneVisionManager:OnUpdate()
    -- Only check for camera changes, no viewport sync (viewport renders on demand)
    if self:HasCameraChanged() then
        self:MarkDirty("camera");
    end
end

-- Enable viewport temporarily for one frame render
-- @param callback: function called after render frame completes
-- @param waitTime: optional wait time in ms (default 100ms for first render, 50ms otherwise)
function SceneVisionManager:RenderOnce(callback, waitTime)
    if not self.viewport then
        if callback then callback(false); end
        return;
    end
    
    -- Sync camera before enabling
    self:SyncViewportCamera();
    
    -- Ensure 3D rendering is active (may be disabled e.g. by ClickToContinue when app loses focus)
    local engineAttr = ParaEngine.GetAttributeObject();
    local wasRenderingEnabled = engineAttr:GetField("Enable3DRendering", true);
    if not wasRenderingEnabled then
        engineAttr:SetField("Enable3DRendering", true);
    end
    
    -- Enable viewport to trigger render
    self.viewport:SetEnabled(true);
    
    -- Use longer wait time for first render (viewport needs more time to initialize)
    local delay = waitTime or (self.hasRenderedOnce and 10 or 100);
    
    -- Schedule callback after render completes (keep viewport enabled until save is done)
    commonlib.TimerManager.SetTimeout(function()
        self.hasRenderedOnce = true;
        if callback then callback(true); end
    end, delay);
end

-- Mark scene as dirty and start debounce timer (unless in passive mode)
-- @param changeType: "block" or "camera"
-- @param event: optional event data
function SceneVisionManager:MarkDirty(changeType, event)
    self.isDirty = true;
    self:sceneChanged({type = changeType, event = event});
    
    -- In passive mode, only emit signal without auto-capture
    if self.passiveMode then
        return;
    end
    
    -- Reset debounce timer
    if self.debounceTimer then
        self.debounceTimer:Change();
    end
    
    self.debounceTimer = commonlib.Timer:new({
        callbackFunc = function(timer)
            timer:Change();  -- one-shot
            if self.isDirty then
                self:CaptureScreenshot();
            end
        end
    });
    self.debounceTimer:Change(self.debounceCooldown, nil);  -- one-shot after cooldown
end

-- Set passive mode: when enabled, sceneChanged is emitted but screenshots are not auto-captured
-- Caller should connect to sceneChanged signal and call CaptureScreenshot() or ForceCaptureNow() manually
-- @param enabled: boolean - True to enable passive mode
function SceneVisionManager:SetPassiveMode(enabled)
    self.passiveMode = enabled == true;
    LOG.std(nil, "info", "SceneVisionManager", "Passive mode %s", self.passiveMode and "enabled" or "disabled");
end

-- Check if the scene is currently dirty (changed since last capture)
-- @return boolean - True if scene has changed since last screenshot
function SceneVisionManager:IsSceneDirty()
    return self.isDirty;
end

-- Generate filename based on current timestamp
function SceneVisionManager:GenerateFilename()
    local timestamp = os.time();
    local dateStr = os.date("%Y%m%d_%H%M%S", timestamp);
    local filename = string.format("%sscene_%s.jpg", self.tempFilePath, dateStr);
    return filename, timestamp;
end

-- Capture screenshot from viewport (renders on demand)
-- @param callback: optional callback(entry) called after capture
function SceneVisionManager:CaptureScreenshot(callback)
    if self.isCapturing then
        LOG.std(nil, "debug", "SceneVisionManager", "Capture already in progress, skipping");
        if callback then callback(nil); end
        return nil;
    end

    local now = os.time();
    if now == self.lastCaptureSecond then
        LOG.std(nil, "debug", "SceneVisionManager", "Throttled: already captured this second");
        if callback then callback(nil); end
        return nil;
    end
    self.lastCaptureSecond = now;

    if not self.viewport then
        LOG.std(nil, "warn", "SceneVisionManager", "Viewport not initialized");
        if callback then callback(nil); end
        return nil;
    end

    self.isCapturing = true;
    
    local filename, timestamp = self:GenerateFilename();
    local fullPath = ParaIO.GetWritablePath() .. filename;
    local cameraPos = self:GetCameraPosition();
    
    -- Render one frame on demand, then capture
    self:RenderOnce(function(success)
        if not success then
            self.isCapturing = false;
            LOG.std(nil, "warn", "SceneVisionManager", "Render failed");
            if callback then callback(nil); end
            return;
        end
        
        -- Save viewport to file using relative path (engine resolves from working directory)
        -- fullPath (absolute) is used only for post-write existence check
        self.viewport:SaveToFile(filename, self.captureWidth, self.captureHeight);
        
        -- Disable viewport after save is complete
        self.viewport:SetEnabled(false);
        
        if not ParaIO.DoesFileExist(fullPath, false) then
            self.isCapturing = false;
            LOG.std(nil, "warn", "SceneVisionManager", "SaveToFile failed: file not written to disk: %s", fullPath);
            if callback then callback(nil); end
            return;
        end
        
        local entry = {
            timestamp = timestamp,
            path = fullPath,
            relativePath = filename,
            cameraPos = cameraPos,
            blockChangeCount = self.blockChangeCount,
        };
        
        table.insert(self.screenshotHistory, entry);
        
        -- Trim history if exceeds max size (but keep files for 24h)
        while #self.screenshotHistory > self.maxHistorySize do
            table.remove(self.screenshotHistory, 1);
        end
        
        self.isDirty = false;
        self.isCapturing = false;
        self:screenshotCaptured(entry);
        
        LOG.std(nil, "debug", "SceneVisionManager", "Screenshot captured: %s", filename);
        
        -- Refresh debug UI if visible
        self:RefreshDebugUI();
        
        if callback then
            callback(entry);
        end
    end);
    
    -- Note: return nil here as capture is now async
    return nil;
end

-- Get the latest screenshot entry
function SceneVisionManager:GetLatestScreenshot()
    return self.screenshotHistory[#self.screenshotHistory];
end

-- Get all screenshot history
function SceneVisionManager:GetScreenshotHistory()
    return self.screenshotHistory;
end

-- Check if scene has changed since last capture
function SceneVisionManager:IsDirty()
    return self.isDirty;
end

-- Get render target name for live preview
function SceneVisionManager:GetRenderTargetName()
    return "_miniscenegraph_sceneVision";
end

-- Clean up files older than fileRetentionHours
function SceneVisionManager:CleanupOldFiles()
    local fullTempPath = ParaIO.GetWritablePath() .. self.tempFilePath;
    
    local currentTime = os.time();
    local retentionSeconds = self.fileRetentionHours * 3600;
    
    NPL.load("(gl)script/ide/Files.lua");
    local result = commonlib.Files.Find({}, fullTempPath, 0, 3000, function(item)
        local ext = commonlib.Files.GetFileExtension(item.filename);
        return ext == "jpg";
    end);
    
    local deletedCount = 0;
    for _, item in ipairs(result) do
        local filename = item.filename;
        -- Parse timestamp from filename (scene_YYYYMMDD_HHMMSS.jpg)
        local year, month, day, hour, min, sec = filename:match("scene_(%d%d%d%d)(%d%d)(%d%d)_(%d%d)(%d%d)(%d%d)%.jpg");
        if year then
            local fileTime = os.time({
                year = tonumber(year),
                month = tonumber(month),
                day = tonumber(day),
                hour = tonumber(hour),
                min = tonumber(min),
                sec = tonumber(sec)
            });
            
            if currentTime - fileTime > retentionSeconds then
                ParaIO.DeleteFile(fullTempPath .. filename);
                deletedCount = deletedCount + 1;
            end
        end
    end
    
    if deletedCount > 0 then
        LOG.std(nil, "info", "SceneVisionManager", "Cleaned up %d old screenshot files", deletedCount);
    end
end

-- Start a timer to periodically clean up old scene_vision files (every hour)
function SceneVisionManager:StartCleanupTimer()
    if self.cleanupTimer then
        return;
    end
    local oneHourMs = 3600000; -- 1 hour in milliseconds
    self.cleanupTimer = commonlib.Timer:new({
        callbackFunc = function(timer)
            self:CleanupOldFiles();
        end
    });
    self.cleanupTimer:Change(oneHourMs, oneHourMs);
end

-- Stop the periodic cleanup timer
function SceneVisionManager:StopCleanupTimer()
    if self.cleanupTimer then
        self.cleanupTimer:Change();
        self.cleanupTimer = nil;
    end
end

-- Show debug UI with screenshot history
function SceneVisionManager:ShowDebugUI(bShow)
    if bShow then
        if not self.debugPage then
            local width, height = 450, 400;
            local params = {
                url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/test/SceneVisionDebug.html",
                name = "SceneVisionDebug.ShowPage",
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

-- Refresh debug UI if visible
function SceneVisionManager:RefreshDebugUI()
    if self.debugPage then
        self.debugPage:Refresh(0.1);
    end
end

-- Destroy the manager and cleanup
function SceneVisionManager:Destroy()
    self:StopUpdateTimer();
    self:StopCleanupTimer();
    
    if self.debounceTimer then
        self.debounceTimer:Change();
        self.debounceTimer = nil;
    end
    
    self:RemoveEventListeners();
    
    if self.viewport then
        self.viewport:Destroy();
        self.viewport = nil;
    end
    
    self:ShowDebugUI(false);
    
    self.isInitialized = false;
    LOG.std(nil, "info", "SceneVisionManager", "Destroyed");
end

-- Force capture now (for manual triggering)
-- @param callback: function(entry) called after capture completes (async)
function SceneVisionManager:ForceCaptureNow(callback)
    -- Cancel any pending debounce
    if self.debounceTimer then
        self.debounceTimer:Change();
        self.debounceTimer = nil;
    end
    
    self:CaptureScreenshot(callback);
end

-- Get screenshot by index (1-based, newest first)
function SceneVisionManager:GetScreenshotByIndex(index)
    local reversedIndex = #self.screenshotHistory - index + 1;
    return self.screenshotHistory[reversedIndex];
end

-- Get history count
function SceneVisionManager:GetHistoryCount()
    return #self.screenshotHistory;
end
