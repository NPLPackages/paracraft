--[[
Title: Learning Tool Page (WebView-based)
Author(s): Copilot
Date: 2026/1/30
Desc: WebView-based learning tool page loader for BackgroundAgent.
      Loads HTML learning tools via MiniGamePage and handles communication via MiniGameMgr.

Use Lib:
------------------------------------------------------------
local LearningToolPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/LearningToolPage.lua")
LearningToolPage.ShowPage("test_multiple_choice", params, sessionId, callback)
LearningToolPage.ClosePage()
------------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMgr.lua")
NPL.load("(gl)script/ide/Json.lua")
local MiniGameMgr = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.MiniGameMgr")
local MiniGamePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGamePage.lua")
local BackgroundAgent = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/BackgroundAgent.lua")

local LearningToolPage = NPL.export()

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

-- Environment detection
local env
if (type(System.os.IsEmscripten) == 'function' and System.os.IsEmscripten()) then
    env = 'asIframeInWebParacraft'
else
    env = 'asWebviewInParacraftClient'
end

-- Base URL template for learning tools
local base_url_template = "https://keepwork.com/public/resource/miniGameProxy.html?projectPath=maisi/maisi/webgames/learning_tools&gameName=%s&%s=true"

-- Tool name to HTML file mapping
local ToolHtmlFiles = {
    test_multiple_choice = "learning_multiple_choice.html",
    test_words_speaking = "learning_speaking.html",
    test_words_spelling = "learning_spelling.html",
    show_learning_content = "learning_flashcard.html",
}

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

LearningToolPage.currentToolName = nil
LearningToolPage.currentParams = nil
LearningToolPage.currentSessionId = nil
LearningToolPage.currentCallback = nil
LearningToolPage.isOpen = false
LearningToolPage.wasAgentPlaying = false  -- Track if agent was playing before pause

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--[[
    Show a learning tool page
    @param toolName: string - Tool name (test_multiple_choice, etc.)
    @param params: table - Tool parameters
    @param sessionId: string - Session ID for callback
    @param callback: function - Called with result when user completes the tool
]]
function LearningToolPage.ShowPage(toolName, params, sessionId, callback)
    -- Get HTML file for the tool
    local htmlFile = ToolHtmlFiles[toolName]
    if not htmlFile then
        LOG.std(nil, "warn", "LearningToolPage", "Unknown tool: %s", toolName)
        if callback then
            callback({success = false, error = "Unknown tool: " .. tostring(toolName)})
        end
        return
    end
    
    -- Close any existing page first
    if LearningToolPage.isOpen then
        LearningToolPage.ClosePage()
    end
    
    -- Store state
    LearningToolPage.currentToolName = toolName
    LearningToolPage.currentParams = params or {}
    LearningToolPage.currentSessionId = sessionId
    LearningToolPage.currentCallback = callback
    LearningToolPage.isOpen = true
    
    -- Build URL
    local url = string.format(base_url_template, htmlFile, env)
    -- Add session ID for callback matching
    if sessionId then
        url = url .. "&sessionId=" .. sessionId
    end
    
    LOG.std(nil, "info", "LearningToolPage", "Opening tool: %s (session: %s)", toolName, sessionId or "none")
    
    -- Pause BackgroundAgent while learning tool is open
    LearningToolPage.PauseAgent()
    
    -- Open browser via MiniGamePage
    MiniGamePage.OpenBrowser(url, function()
        -- Browser closed callback
        LearningToolPage.OnPageClosed()
    end)
    
    -- Send config after a short delay to ensure page is ready
    commonlib.TimerManager.SetTimeout(function()
        LearningToolPage.SendConfig()
    end, 500)
end

--[[
    Send configuration to HTML page via MiniGameMgr
    Note: params are base64-encoded to handle Chinese characters properly
]]
function LearningToolPage.SendConfig()
    if not LearningToolPage.isOpen then return end
    
    -- Serialize params to JSON and encode to base64 to handle Chinese characters
    local paramsJson = commonlib.Json.Encode(LearningToolPage.currentParams or {})
    local paramsBase64 = commonlib.Encoding.base64(paramsJson)
    
    local config = {
        type="setGameConfig",
        data={
            sessionId = LearningToolPage.currentSessionId,
            toolName = LearningToolPage.currentToolName,
            params = LearningToolPage.currentParams,  -- Keep original for backward compatibility
            paramsBase64 = paramsBase64,  -- Base64-encoded params for Chinese support
        }
    }
    
    LOG.std(nil, "debug", "LearningToolPage", "Sending config with base64 params (length: %d)", #paramsBase64)
    
    -- Send via MiniGameMgr message channel
    if GameLogic.MiniGameMgr then
        GameLogic.MiniGameMgr:SendMessage("learningTool", config)
    end
end

--[[
    Handle messages from MiniGameMgr (called by MiniGameMgr:HandleGameMessage)
    This is the entry point for messages from HTML learning tools
    @param msgdata: table - Message data
]]
function LearningToolPage.OnRecvMessage(msgdata)
    if not msgdata then return end
    if not LearningToolPage.isOpen then return end
    
    local msgType = msgdata.type
    
    if msgType == "learningToolResult" then
        -- User completed the tool
        local sessionId = msgdata.sessionId
        local data = msgdata.data or {}
        
        LOG.std(nil, "info", "LearningToolPage", "Received result for session: %s", tostring(sessionId) or "unknown")
        
        -- Verify session ID matches
        if sessionId == LearningToolPage.currentSessionId then
            LearningToolPage.ReportResult(data)
        end
    elseif msgType == "learningToolLoaded" then
        -- HTML page is ready, send config again
        LOG.std(nil, "debug", "LearningToolPage", "HTML page ready, sending config")
        LearningToolPage.SendConfig()
    end
end

--[[
    Called when MiniGamePage is closed
]]
function LearningToolPage.OnPageClosed()
    if not LearningToolPage.isOpen then return end
    
    LOG.std(nil, "info", "LearningToolPage", "Page closed (tool: %s)", LearningToolPage.currentToolName or "unknown")
    
    local callback = LearningToolPage.currentCallback
    local sessionId = LearningToolPage.currentSessionId
    
    -- Clear state
    LearningToolPage.isOpen = false
    LearningToolPage.currentToolName = nil
    LearningToolPage.currentParams = nil
    LearningToolPage.currentSessionId = nil
    LearningToolPage.currentCallback = nil
    
    -- Resume BackgroundAgent
    LearningToolPage.ResumeAgent()
    
    -- Report cancelled if no result was received
    if callback then
        callback({
            success = true,
            cancelled = true,
            skipped = true,
            sessionId = sessionId,
            reason = "Page closed"
        })
    end
end

--[[
    Report result to callback and close page
    @param result: table - Result data
]]
function LearningToolPage.ReportResult(result)
    local callback = LearningToolPage.currentCallback
    local sessionId = LearningToolPage.currentSessionId
    local toolName = LearningToolPage.currentToolName
    
    -- Clear callback first to prevent duplicate calls
    LearningToolPage.currentCallback = nil
    
    -- Close the page
    LearningToolPage.ClosePage()
    
    -- Call callback with result
    if callback then
        result = result or {}
        result.sessionId = sessionId
        result.toolName = toolName
        callback(result)
    end
end

--[[
    Close the current learning tool page
]]
function LearningToolPage.ClosePage()
    LOG.std(nil, "info", "LearningToolPage", "Closing page")
    -- Clear state
    LearningToolPage.isOpen = false
    LearningToolPage.currentToolName = nil
    LearningToolPage.currentParams = nil
    LearningToolPage.currentSessionId = nil
    LearningToolPage.currentCallback = nil
    
    -- Resume BackgroundAgent
    LearningToolPage.ResumeAgent()
    
    -- Close via MiniGamePage
    MiniGamePage.ClosePage()
end

--[[
    Check if a page is currently open
    @return boolean
]]
function LearningToolPage.IsOpen()
    return LearningToolPage.isOpen
end

--[[
    Get current session ID
    @return string or nil
]]
function LearningToolPage.GetCurrentSessionId()
    return LearningToolPage.currentSessionId
end

--------------------------------------------------------------------------------
-- URL Configuration
--------------------------------------------------------------------------------

--[[
    Set HTML file for a tool
    @param toolName: string - Tool name
    @param htmlFile: string - HTML file name
]]
function LearningToolPage.SetToolHtmlFile(toolName, htmlFile)
    ToolHtmlFiles[toolName] = htmlFile
    LOG.std(nil, "info", "LearningToolPage", "Set HTML file for %s: %s", toolName, htmlFile)
end

--[[
    Get HTML file for a tool
    @param toolName: string - Tool name
    @return string or nil - HTML file name
]]
function LearningToolPage.GetToolHtmlFile(toolName)
    return ToolHtmlFiles[toolName]
end

--------------------------------------------------------------------------------
-- BackgroundAgent Control
--------------------------------------------------------------------------------

--[[
    Pause BackgroundAgent while learning tool is open
]]
function LearningToolPage.PauseAgent()
    local agent = BackgroundAgent.GetInstance and BackgroundAgent.GetInstance()
    if agent then
        -- Check if agent is currently playing
        LearningToolPage.wasAgentPlaying = (agent.playbackState == "playing")
        if LearningToolPage.wasAgentPlaying then
            agent:Pause()
            LOG.std(nil, "info", "LearningToolPage", "BackgroundAgent paused")
        end
    end
end

--[[
    Resume BackgroundAgent after learning tool is closed
]]
function LearningToolPage.ResumeAgent()
    if LearningToolPage.wasAgentPlaying then
        local agent = BackgroundAgent.GetInstance and BackgroundAgent.GetInstance()
        if agent then
            agent:Play()
            LOG.std(nil, "info", "LearningToolPage", "BackgroundAgent resumed")
        end
        LearningToolPage.wasAgentPlaying = false
    end
end

return LearningToolPage
