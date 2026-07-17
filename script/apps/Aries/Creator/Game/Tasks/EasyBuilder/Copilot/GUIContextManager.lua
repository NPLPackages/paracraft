--[[
Title: GUI Context Manager
Author(s): LiXizhi, Copilot
Date: 2026/1/23
Desc: Reads all visible GUI elements on screen with their 2D positions for LLM/MCP agent context.
      Traverses raw ParaUI GUIObjects from root container and extracts text elements with bounding boxes.
      Output is sorted by screen position (top-to-bottom, left-to-right) for natural reading order.

Features:
- Traverses raw GUIObject hierarchy from root
- Extracts text content, element type, and 2D bounding box
- Filters to visible elements only
- Sorts by Y position then X position for natural reading order
- Provides structured output for LLM context
- Coroutine-based traversal that supports both sync and async modes
- Frame-distributed async traversal to avoid frame jerking

Use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/GUIContextManager.lua");
local GUIContextManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.GUIContextManager");
GUIContextManager:Init();

-- Async formatted context for LLM
GUIContextManager:GetGUIContextForLLMAsync({format="markdown"}, function(context)
    echo(context);
end);

-- Async traversal (distributed across frames, no stutter)
GUIContextManager:GetVisibleGUIElementsAsync(function(elements)
    for _, elem in ipairs(elements) do
        echo(string.format("%s at (%d,%d)", elem.text, elem.x, elem.y));
    end
end);

-- Synchronous (may cause frame stutter for complex GUIs)
local elements = GUIContextManager:GetVisibleGUIElements();
local context = GUIContextManager:GetGUIContextForLLM();

-- Configure frame distribution (default: 50 nodes/frame, 16ms interval)
GUIContextManager:SetFrameDistribution(100, 16);

-- Get screen dimensions
local width, height = GUIContextManager:GetScreenSize();

-- Check if async traversal is in progress
if GUIContextManager:IsTraversing() then
    -- wait or stop
    GUIContextManager:StopAsyncTraversal();
end

-- Show/hide debug UI for testing
GUIContextManager:ShowDebugUI(true);
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Core/ToolBase.lua");

local GUIContextManager = commonlib.inherit(
    commonlib.gettable("System.Core.ToolBase"),
    commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.GUIContextManager")
);

GUIContextManager:Property("Name", "GUIContextManager");
GUIContextManager:Signal("contextUpdated");  -- Emitted when GUI context is refreshed

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------
GUIContextManager.minTextLength = 1;           -- Minimum text length to include
GUIContextManager.maxTextLength = 500;         -- Maximum text length per element (truncate longer)
GUIContextManager.includeEmptyText = false;    -- Include elements with empty/whitespace text
GUIContextManager.includeHiddenElements = false; -- Include elements that are not visible
GUIContextManager.maxDepth = 50;               -- Maximum recursion depth for GUI tree
GUIContextManager.maxElements = 500;           -- Maximum elements to collect (performance limit)

-- Element type filters (set to false to exclude)
GUIContextManager.includeButtons = true;
GUIContextManager.includeText = true;
GUIContextManager.includeEditBox = true;
GUIContextManager.includeContainer = false;    -- Containers usually don't have meaningful text
GUIContextManager.includeSlider = false;
GUIContextManager.includeScrollBar = false;

-- Frame distribution settings (to avoid frame jerking)
GUIContextManager.maxNodesPerFrame = 50;       -- Maximum GUI nodes to process per frame
GUIContextManager.frameIntervalMs = 16;        -- ~60fps interval between frames

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function GUIContextManager:ctor()
    self.isInitialized = false;
    self.cachedElements = nil;
    self.cacheTime = 0;
    self.cacheDurationMs = 100;  -- Cache validity duration
    
    -- Coroutine-based traversal state
    self.traversalCoroutine = nil;       -- The traversal coroutine
    self.traversalElements = {};         -- Accumulated elements during traversal
    self.traversalCallback = nil;        -- Callback when async traversal completes
    self.traversalTimer = nil;           -- Timer for frame distribution
    self.traversalStartTime = 0;         -- When traversal started (for timeout)
    self.traversalMaxTimeMs = 5000;      -- Maximum time for full traversal (timeout)
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

--[[
    Initialize the singleton manager
    @return self
]]
function GUIContextManager:Init()
    if self.isInitialized then
        return self;
    end
    GUIContextManager:InitSingleton();
    
    self.isInitialized = true;
    LOG.std(nil, "info", "GUIContextManager", "Initialized");
    
    return self;
end

--------------------------------------------------------------------------------
-- Screen Information
--------------------------------------------------------------------------------

--[[
    Get screen dimensions
    @return width, height - Screen size in pixels
]]
function GUIContextManager:GetScreenSize()
    local root = ParaUI.GetUIObject("root");
    if root and root:IsValid() then
        return root.width, root.height;
    end
    -- Fallback to viewport size
    local att = ParaEngine.GetAttributeObject();
    local width = att:GetField("ScreenWidth", 1920);
    local height = att:GetField("ScreenHeight", 1080);
    return width, height;
end

--------------------------------------------------------------------------------
-- GUI Element Type Detection
--------------------------------------------------------------------------------

-- GUI type constants (from ParaEngine)
local GUI_TYPE_UNKNOWN = 0;
local GUI_TYPE_BUTTON = "CGUIButton";
local GUI_TYPE_CONTAINER = "CGUIContainer";
local GUI_TYPE_SCROLLBAR = "CGUIScrollBar";
local GUI_TYPE_EDITBOX = "CGUIEditBox";
local GUI_TYPE_IMEEDITBOX = "CGUIIMEEditBox";
local GUI_TYPE_SLIDER = "CGUISlider";
local GUI_TYPE_TEXT = "CGUIText";
local GUI_TYPE_LISTBOX = "CGUIListBox";
local GUI_TYPE_CANVAS = "CGUICanvas";
local GUI_TYPE_WEBROWSER = "CGUIWebBrowser";

-- Cached screen dimensions for bounds checking
local cachedScreenWidth = 1920;
local cachedScreenHeight = 1080;

--[[
    Check if element bounds are within screen bounds (not completely off-screen).
    @param x: number - Element absolute X position
    @param y: number - Element absolute Y position
    @param width: number - Element width
    @param height: number - Element height
    @return boolean - True if element is at least partially on screen
]]
function GUIContextManager:IsOnScreen(x, y, width, height)
    -- Element is off-screen if:
    -- - Its right edge is left of the screen (x + width < 0)
    -- - Its bottom edge is above the screen (y + height < 0)
    -- - Its left edge is right of the screen (x > screenWidth)
    -- - Its top edge is below the screen (y > screenHeight)
    if x + width < 0 then return false; end
    if y + height < 0 then return false; end
    if x > cachedScreenWidth then return false; end
    if y > cachedScreenHeight then return false; end
    return true;
end

--[[
    Update cached screen dimensions (call before traversal)
]]
function GUIContextManager:UpdateCachedScreenSize()
    cachedScreenWidth, cachedScreenHeight = self:GetScreenSize();
end

local typeNames = {
    [GUI_TYPE_UNKNOWN] = "unknown",
    [GUI_TYPE_BUTTON] = "button",
    [GUI_TYPE_CONTAINER] = "container",
    [GUI_TYPE_SCROLLBAR] = "scrollbar",
    [GUI_TYPE_EDITBOX] = "editbox",
    [GUI_TYPE_IMEEDITBOX] = "imeeditbox",
    [GUI_TYPE_SLIDER] = "slider",
    [GUI_TYPE_TEXT] = "text",
    [GUI_TYPE_LISTBOX] = "listbox",
    [GUI_TYPE_CANVAS] = "canvas",
    [GUI_TYPE_WEBROWSER] = "webbrowser",
};
--[[
    Get human-readable type name from GUI class name
    @param className: string - GUI class name (e.g., "CGUIButton")
    @return string - Type name
]]
function GUIContextManager:GetTypeName(className)
    return typeNames[className] or "unknown";
end

--[[
    Check if element type should be included based on filter settings
    @param className: string - GUI class name (e.g., "CGUIButton")
    @return boolean
]]
function GUIContextManager:ShouldIncludeType(className)
    if className == GUI_TYPE_BUTTON then
        return self.includeButtons;
    elseif className == GUI_TYPE_TEXT then
        return self.includeText;
    elseif className == GUI_TYPE_EDITBOX or className == GUI_TYPE_IMEEDITBOX then
        return self.includeEditBox;
    elseif className == GUI_TYPE_CONTAINER then
        return self.includeContainer;
    elseif className == GUI_TYPE_SLIDER then
        return self.includeSlider;
    elseif className == GUI_TYPE_SCROLLBAR then
        return self.includeScrollBar;
    end
    return true; -- Include unknown types by default
end

--------------------------------------------------------------------------------
-- Raw GUI Traversal via Attribute System
--------------------------------------------------------------------------------

--[[
    Check if a GUI attribute object is valid and visible.
    @param attr: AttributeObject - GUI attribute object
    @return boolean, table - isValid, {visible, x, y, width, height} or nil
]]
function GUIContextManager:ValidateGUIAttribute(attr)
    if not attr or not attr:IsValid() then
        return false, nil;
    end
    
    local visible = attr:GetField("visible", true);
    if not visible and not self.includeHiddenElements then
        return false, nil;
    end
    
    return true, {
        visible = visible,
        x = attr:GetField("x", 0),
        y = attr:GetField("y", 0),
        width = attr:GetField("width", 0),
        height = attr:GetField("height", 0),
    };
end

--[[
    Process a single GUI node and return info about its children.
    @param attr: AttributeObject - GUI attribute object
    @param depth: number - Current depth in tree
    @param parentX: number - Parent's absolute X position
    @param parentY: number - Parent's absolute Y position
    @param parentVisible: boolean - Parent's visibility state
    @param elements: table - Array to append elements to
    @return table - Array of child nodes to process: {{attr, depth, parentX, parentY, parentVisible}, ...}
]]
function GUIContextManager:ProcessGUINode(attr, depth, parentX, parentY, parentVisible, elements)
    if depth > self.maxDepth or #elements >= self.maxElements then
        return {};
    end
    
    if not attr or not attr:IsValid() then
        return {};
    end
    
    -- Get element properties via attribute fields
    local name = attr:GetField("name", "");
    local text = attr:GetField("text", "");
    local x = attr:GetField("x", 0);
    local y = attr:GetField("y", 0);
    local width = attr:GetField("Width", 0);
    local height = attr:GetField("Height", 0);
    local visible = attr:GetField("Visible", true);
    local enabled = attr:GetField("Enable", true);
    local className = attr:GetField("ClassName", GUI_TYPE_UNKNOWN);
    local id = attr:GetField("id", -1);
    
    -- Calculate absolute position (relative to parent)
    local absX = parentX + x;
    local absY = parentY + y;
    
    -- Determine effective visibility
    local isVisible = visible and parentVisible;
    
    -- Early exit: Skip invisible elements and their children (unless configured to include)
    if not isVisible and not self.includeHiddenElements then
        return {};
    end
    
    -- Early exit: Skip disabled elements and their children
    if not enabled then
        return {};
    end
    
    -- Early exit: Skip elements that are completely off-screen (and their children)
    if not self:IsOnScreen(absX, absY, width, height) then
        return {};
    end
    
    -- Collect children for processing
    local children = {};
    local colCount = attr:GetColumnCount();
    for col = 0, colCount - 1 do
        local childCount = attr:GetChildCount(col);
        for row = 0, childCount - 1 do
            local childAttr = attr:GetChildAt(row, col);
            if childAttr and childAttr:IsValid() then
                table.insert(children, {
                    attr = childAttr,
                    depth = depth + 1,
                    parentX = absX,
                    parentY = absY,
                    parentVisible = isVisible,
                });
            end
        end
    end
    
    -- Check if we should include this element
    local shouldInclude = false;
    if self:ShouldIncludeType(className) then
        -- Check text content
        if text and text ~= "" then
            local trimmedText = text:match("^%s*(.-)%s*$") or "";
            if #trimmedText >= self.minTextLength or self.includeEmptyText then
                shouldInclude = true;
            end
        end
    end
    
    -- Add element to results
    if shouldInclude then
        local trimmedText = text:match("^%s*(.-)%s*$") or text;
        if #trimmedText > self.maxTextLength then
            trimmedText = trimmedText:sub(1, self.maxTextLength) .. "...";
        end
        
        local element = {
            id = id,
            name = name,
            text = trimmedText,
            type = self:GetTypeName(className),
            className = className,
            x = absX,
            y = absY,
            width = width,
            height = height,
            visible = isVisible,
            enabled = enabled,
            depth = depth,
        };
        
        table.insert(elements, element);
    end
    
    return children;
end

--[[
    Coroutine-based GUI tree traversal.
    Yields periodically to allow frame distribution when run asynchronously.
    @param asyncMode: boolean - If true, yields every maxNodesPerFrame nodes
    @return table - Array of GUI element info tables
]]
function GUIContextManager:TraverseGUICoroutine(asyncMode)
    local elements = {};
    local nodeCount = 0;
    
    -- Update cached screen size for bounds checking
    self:UpdateCachedScreenSize();
    
    -- Get GUI DOM via attribute system
    local engineAttr = ParaEngine.GetAttributeObject();
    if not engineAttr or not engineAttr:IsValid() then
        LOG.std(nil, "warn", "GUIContextManager", "Failed to get ParaEngine attribute object");
        return elements;
    end
    
    local guiAttr = engineAttr:GetChild("GUI");
    if not guiAttr or not guiAttr:IsValid() then
        LOG.std(nil, "warn", "GUIContextManager", "Failed to get GUI attribute child");
        return elements;
    end
    
    -- Initialize queue with root children
    local queue = {};
    local colCount = guiAttr:GetColumnCount();
    for col = 0, colCount - 1 do
        local childCount = guiAttr:GetChildCount(col);
        for row = 0, childCount - 1 do
            local childAttr = guiAttr:GetChildAt(row, col);
            if childAttr and childAttr:IsValid() then
                table.insert(queue, {
                    attr = childAttr,
                    depth = 0,
                    parentX = 0,
                    parentY = 0,
                    parentVisible = true,
                });
            end
        end
    end
    
    -- Process queue (breadth-first traversal)
    while #queue > 0 do
        -- Check element limit
        if #elements >= self.maxElements then
            LOG.std(nil, "debug", "GUIContextManager", "Reached max elements limit (%d)", self.maxElements);
            break;
        end
        
        local item = table.remove(queue, 1);
        
        -- Re-validate element (it may have been destroyed/hidden since queued)
        local isValid = self:ValidateGUIAttribute(item.attr);
        if isValid then
            -- Process node and get its children
            local children = self:ProcessGUINode(
                item.attr, item.depth, item.parentX, item.parentY, item.parentVisible, elements
            );
            
            -- Add children to queue
            for _, child in ipairs(children) do
                table.insert(queue, child);
            end
            
            nodeCount = nodeCount + 1;
            
            -- Yield periodically in async mode
            if asyncMode and nodeCount % self.maxNodesPerFrame == 0 then
                coroutine.yield("continue", nodeCount);
            end
        end
    end
    
    LOG.std(nil, "debug", "GUIContextManager", "Traversed GUI tree, found %d elements in %d nodes", #elements, nodeCount);
    
    return elements;
end

--[[
    Start asynchronous GUI traversal using coroutine distributed across frames.
    @param callback: function(elements) - Called when traversal completes
    @param forceRestart: boolean - Force restart even if traversal is in progress
]]
function GUIContextManager:StartAsyncTraversal(callback, forceRestart)
    -- If already traversing and not forcing restart, chain callback
    if self:IsTraversing() and not forceRestart then
        LOG.std(nil, "debug", "GUIContextManager", "Traversal already in progress, chaining callback...");
        local oldCallback = self.traversalCallback;
        self.traversalCallback = function(elements)
            if oldCallback then oldCallback(elements); end
            if callback then callback(elements); end
        end
        return;
    end
    
    -- Stop any existing traversal
    if self:IsTraversing() then
        self:StopAsyncTraversal();
    end
    
    -- Initialize traversal state
    self.traversalElements = {};
    self.traversalCallback = callback;
    self.traversalStartTime = commonlib.TimerManager.GetCurrentTime();
    
    -- Create traversal coroutine
    self.traversalCoroutine = coroutine.create(function()
        return self:TraverseGUICoroutine(true); -- async mode = true
    end);
    
    LOG.std(nil, "debug", "GUIContextManager", "Started async traversal with coroutine");
    
    -- Start frame timer
    self:ScheduleNextFrame();
end

--[[
    Schedule processing for next frame
]]
function GUIContextManager:ScheduleNextFrame()
    if self.traversalTimer then
        self.traversalTimer:Change();
    end
    
    self.traversalTimer = commonlib.TimerManager.SetTimeout(function()
        self:ProcessTraversalFrame();
    end, self.frameIntervalMs);
end

--[[
    Process one frame's worth of GUI nodes by resuming the coroutine
]]
function GUIContextManager:ProcessTraversalFrame()
    if not self:IsTraversing() then
        return;
    end
    
    local currentTime = commonlib.TimerManager.GetCurrentTime();
    
    -- Check for timeout
    if (currentTime - self.traversalStartTime) > self.traversalMaxTimeMs then
        LOG.std(nil, "warn", "GUIContextManager", "Traversal timeout after %dms", 
            currentTime - self.traversalStartTime);
        self:FinishAsyncTraversal({});
        return;
    end
    
    -- Resume coroutine
    local ok, result, nodeCount = coroutine.resume(self.traversalCoroutine);
    
    if not ok then
        -- Coroutine error
        LOG.std(nil, "error", "GUIContextManager", "Traversal coroutine error: %s", tostring(result));
        self:FinishAsyncTraversal({});
        return;
    end
    
    local status = coroutine.status(self.traversalCoroutine);
    
    if status == "dead" then
        -- Coroutine finished, result contains the elements
        LOG.std(nil, "debug", "GUIContextManager", "Traversal complete in %dms", 
            currentTime - self.traversalStartTime);
        self:FinishAsyncTraversal(result or {});
    elseif result == "continue" then
        -- Coroutine yielded, schedule next frame
        self:ScheduleNextFrame();
    else
        -- Unknown yield value, continue anyway
        self:ScheduleNextFrame();
    end
end

--[[
    Finish async traversal and call callback
    @param elements: table - The collected elements
]]
function GUIContextManager:FinishAsyncTraversal(elements)
    -- Clean up coroutine state
    self.traversalCoroutine = nil;
    
    if self.traversalTimer then
        self.traversalTimer:Change();
        self.traversalTimer = nil;
    end
    
    -- Sort elements by position
    table.sort(elements, function(a, b)
        local yTolerance = 10;
        local yDiff = a.y - b.y;
        if math.abs(yDiff) > yTolerance then
            return yDiff < 0;
        end
        return a.x < b.x;
    end);
    
    -- Update cache
    self.cachedElements = elements;
    self.cacheTime = commonlib.TimerManager.GetCurrentTime();
    
    -- Call callback
    local callback = self.traversalCallback;
    self.traversalCallback = nil;
    self.traversalElements = {};
    
    self:contextUpdated(elements);
    
    if callback then
        callback(elements);
    end
end

--[[
    Stop async traversal if in progress
]]
function GUIContextManager:StopAsyncTraversal()
    if not self:IsTraversing() then
        return;
    end
    
    self.traversalCoroutine = nil;
    
    if self.traversalTimer then
        self.traversalTimer:Change();
        self.traversalTimer = nil;
    end
    
    self.traversalElements = {};
    self.traversalCallback = nil;
    
    LOG.std(nil, "debug", "GUIContextManager", "Async traversal stopped");
end

--[[
    Check if async traversal is in progress
    @return boolean
]]
function GUIContextManager:IsTraversing()
    return self.traversalCoroutine ~= nil and coroutine.status(self.traversalCoroutine) ~= "dead";
end

--[[
    Traverse GUI tree synchronously (runs coroutine to completion without yielding).
    @return table - Array of GUI element info tables
]]
function GUIContextManager:TraverseRawGUI()
    return self:TraverseGUICoroutine(false); -- async mode = false, no yielding
end

--[[
    Alternative traversal using ParaUI.GetUIObject("root") for direct GUI access.
    This method uses the ParaUIObject interface directly.
    @return table - Array of GUI element info tables
]]
function GUIContextManager:TraverseParaUI()
    local elements = {};
    local elementCount = 0;
    
    -- Update cached screen size for bounds checking
    self:UpdateCachedScreenSize();
    
    local root = ParaUI.GetUIObject("root");
    if not root or not root:IsValid() then
        LOG.std(nil, "warn", "GUIContextManager", "Failed to get ParaUI root object");
        return elements;
    end
    
    -- Recursive function to traverse UI tree
    local function traverseUIObject(uiObj, depth, parentX, parentY, parentVisible)
        if depth > self.maxDepth or elementCount >= self.maxElements then
            return;
        end
        
        if not uiObj or not uiObj:IsValid() then
            return;
        end
        
        -- Get element properties
        local name = uiObj.name or "";
        local text = uiObj.text or "";
        local x = uiObj.x or 0;
        local y = uiObj.y or 0;
        local width = uiObj.width or 0;
        local height = uiObj.height or 0;
        local visible = uiObj.visible;
        local enabled = uiObj.enabled;
        local id = uiObj.id or -1;
        
        -- Calculate absolute position
        local absX = parentX + x;
        local absY = parentY + y;
        
        -- Determine effective visibility
        local isVisible = visible and parentVisible;
        
        -- Early exit: Skip invisible elements and their children (unless configured to include)
        if not isVisible and not self.includeHiddenElements then
            return;
        end
        
        -- Early exit: Skip disabled elements and their children
        if not enabled then
            return;
        end
        
        -- Early exit: Skip elements that are completely off-screen (and their children)
        if not self:IsOnScreen(absX, absY, width, height) then
            return;
        end
        
        -- Check if we should include this element
        local shouldInclude = false;
        -- Check text content
        if text and text ~= "" then
            local trimmedText = text:match("^%s*(.-)%s*$") or "";
            if #trimmedText >= self.minTextLength or self.includeEmptyText then
                shouldInclude = true;
            end
        end
        
        -- Add element to results
        if shouldInclude then
            local trimmedText = text:match("^%s*(.-)%s*$") or text;
            if #trimmedText > self.maxTextLength then
                trimmedText = trimmedText:sub(1, self.maxTextLength) .. "...";
            end
            
            -- Determine type from UI object (ParaUIObject doesn't expose type directly,
            -- so we infer from behavior or use generic "ui")
            local typeName = "ui";
            
            local element = {
                id = id,
                name = name,
                text = trimmedText,
                type = typeName,
                x = absX,
                y = absY,
                width = width,
                height = height,
                visible = isVisible,
                enabled = enabled,
                depth = depth,
            };
            
            table.insert(elements, element);
            elementCount = elementCount + 1;
        end
        
        -- Traverse children using GetChild
        local childIndex = 0;
        while true do
            local child = uiObj:GetChildAt(childIndex);
            if not child or not child:IsValid() then
                break;
            end
            traverseUIObject(child, depth + 1, absX, absY, isVisible);
            childIndex = childIndex + 1;
        end
    end
    
    -- Start traversal from root
    traverseUIObject(root, 0, 0, 0, true);
    
    LOG.std(nil, "debug", "GUIContextManager", "Traversed ParaUI tree, found %d text elements", #elements);
    
    return elements;
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--[[
    Get all visible GUI elements with text content (asynchronous, frame-distributed).
    Returns elements sorted by position (top-to-bottom, left-to-right).
    @param callback: function(elements) - Called when traversal completes
    @param forceRefresh: boolean (optional) - Force refresh even if cache is valid
]]
function GUIContextManager:GetVisibleGUIElementsAsync(callback, forceRefresh)
    local currentTime = commonlib.TimerManager.GetCurrentTime();
    
    -- Return cached result if still valid
    if not forceRefresh and self.cachedElements and 
       (currentTime - self.cacheTime) < self.cacheDurationMs then
        if callback then
            callback(self.cachedElements);
        end
        return;
    end
    
    -- Start async traversal
    self:StartAsyncTraversal(callback, forceRefresh);
end

--[[
    Get all visible GUI elements with text content (synchronous).
    Returns elements sorted by position (top-to-bottom, left-to-right).
    WARNING: May cause frame stutter for complex GUIs. Use GetVisibleGUIElementsAsync for better performance.
    @param forceRefresh: boolean (optional) - Force refresh even if cache is valid
    @return table - Array of element info: {id, name, text, type, x, y, width, height, visible, enabled}
]]
function GUIContextManager:GetVisibleGUIElements(forceRefresh)
    local currentTime = commonlib.TimerManager.GetCurrentTime();
    
    -- Return cached result if still valid
    if not forceRefresh and self.cachedElements and 
       (currentTime - self.cacheTime) < self.cacheDurationMs then
        return self.cachedElements;
    end
    
    -- Try attribute-based traversal first (more comprehensive)
    local elements = self:TraverseRawGUI();
    
    -- If attribute traversal returned nothing, try ParaUI traversal
    if #elements == 0 then
        elements = self:TraverseParaUI();
    end
    
    -- Sort by position: Y first (top to bottom), then X (left to right)
    table.sort(elements, function(a, b)
        -- Primary sort by Y (with small tolerance for elements on same "line")
        local yTolerance = 10; -- pixels
        local yDiff = a.y - b.y;
        if math.abs(yDiff) > yTolerance then
            return yDiff < 0;
        end
        -- Secondary sort by X
        return a.x < b.x;
    end);
    
    -- Update cache
    self.cachedElements = elements;
    self.cacheTime = currentTime;
    
    self:contextUpdated(elements);
    
    return elements;
end

--[[
    Get GUI context formatted for LLM consumption (asynchronous version).
    Returns a structured text representation of visible GUI elements.
    @param options: table (optional) - Formatting options
        - format: string - "markdown", "json", or "plain" (default: "markdown")
        - includePositions: boolean - Include x,y,width,height (default: true)
        - includeTypes: boolean - Include element types (default: true)
        - maxElements: number - Maximum elements to include (default: all)
    @param callback: function(contextString) - Called when ready
]]
function GUIContextManager:GetGUIContextForLLMAsync(options, callback)
    options = options or {};
    
    self:GetVisibleGUIElementsAsync(function(elements)
        local format = options.format or "markdown";
        local includePositions = options.includePositions ~= false;
        local includeTypes = options.includeTypes ~= false;
        local maxElements = options.maxElements;
        
        if maxElements and #elements > maxElements then
            local trimmed = {};
            for i = 1, maxElements do
                trimmed[i] = elements[i];
            end
            elements = trimmed;
        end
        
        if #elements == 0 then
            if callback then callback(""); end
            return;
        end
        
        local screenWidth, screenHeight = self:GetScreenSize();
        local result;
        
        if format == "json" then
            result = self:FormatAsJSON(elements, screenWidth, screenHeight, includePositions, includeTypes);
        elseif format == "plain" then
            result = self:FormatAsPlain(elements, includePositions, includeTypes);
        else
            result = self:FormatAsMarkdown(elements, screenWidth, screenHeight, includePositions, includeTypes);
        end
        
        if callback then callback(result); end
    end, options.forceRefresh);
end

--[[
    Get GUI context formatted for LLM consumption (synchronous version).
    Returns a structured text representation of visible GUI elements.
    @param options: table (optional) - Formatting options
        - format: string - "markdown", "json", or "plain" (default: "markdown")
        - includePositions: boolean - Include x,y,width,height (default: true)
        - includeTypes: boolean - Include element types (default: true)
        - maxElements: number - Maximum elements to include (default: all)
    @return string - Formatted GUI context
]]
function GUIContextManager:GetGUIContextForLLM(options)
    options = options or {};
    local format = options.format or "markdown";
    local includePositions = options.includePositions ~= false;
    local includeTypes = options.includeTypes ~= false;
    local maxElements = options.maxElements;
    
    local elements = self:GetVisibleGUIElements();
    
    if maxElements and #elements > maxElements then
        local trimmed = {};
        for i = 1, maxElements do
            trimmed[i] = elements[i];
        end
        elements = trimmed;
    end
    
    if #elements == 0 then
        return "";
    end
    
    local screenWidth, screenHeight = self:GetScreenSize();
    
    if format == "json" then
        return self:FormatAsJSON(elements, screenWidth, screenHeight, includePositions, includeTypes);
    elseif format == "plain" then
        return self:FormatAsPlain(elements, includePositions, includeTypes);
    else
        return self:FormatAsMarkdown(elements, screenWidth, screenHeight, includePositions, includeTypes);
    end
end

--[[
    Format elements as Markdown
]]
function GUIContextManager:FormatAsMarkdown(elements, screenWidth, screenHeight, includePositions, includeTypes)
    local lines = {};
    table.insert(lines, "## Visible GUI Elements");
    table.insert(lines, string.format("Screen: %dx%d pixels\n", screenWidth, screenHeight));
    
    for i, elem in ipairs(elements) do
        local line = string.format("- **%s**", elem.text);
        
        local details = {};
        if includeTypes and elem.type then
            table.insert(details, elem.type);
        end
        if includePositions then
            table.insert(details, string.format("pos:(%d,%d)", elem.x, elem.y));
            if elem.width > 0 and elem.height > 0 then
                table.insert(details, string.format("size:%dx%d", elem.width, elem.height));
            end
        end
        if elem.name and elem.name ~= "" then
            table.insert(details, string.format("name:%s", elem.name));
        end
        
        if #details > 0 then
            line = line .. " [" .. table.concat(details, ", ") .. "]";
        end
        
        table.insert(lines, line);
    end
    
    return table.concat(lines, "\n");
end

--[[
    Format elements as JSON
]]
function GUIContextManager:FormatAsJSON(elements, screenWidth, screenHeight, includePositions, includeTypes)
    local result = {
        screen = {
            width = screenWidth,
            height = screenHeight,
        },
        elements = {},
    };
    
    for i, elem in ipairs(elements) do
        local item = {
            text = elem.text,
        };
        if includeTypes then
            item.type = elem.type;
        end
        if includePositions then
            item.x = elem.x;
            item.y = elem.y;
            item.width = elem.width;
            item.height = elem.height;
        end
        if elem.name and elem.name ~= "" then
            item.name = elem.name;
        end
        table.insert(result.elements, item);
    end
    
    return commonlib.serialize_compact(result);
end

--[[
    Format elements as plain text
]]
function GUIContextManager:FormatAsPlain(elements, includePositions, includeTypes)
    local lines = {};
    
    for i, elem in ipairs(elements) do
        local line = elem.text;
        
        if includeTypes and elem.type then
            line = string.format("[%s] %s", elem.type, line);
        end
        if includePositions then
            line = string.format("%s (%d,%d)", line, elem.x, elem.y);
        end
        
        table.insert(lines, line);
    end
    
    return table.concat(lines, "\n");
end

--[[
    Get a summary of GUI context (shorter, for context-limited LLMs)
    @param maxChars: number (optional) - Maximum characters in summary (default: 1000)
    @return string - Abbreviated GUI context
]]
function GUIContextManager:GetGUIContextSummary(maxChars)
    maxChars = maxChars or 1000;
    
    local elements = self:GetVisibleGUIElements();
    
    if #elements == 0 then
        return "";
    end
    
    local lines = {"GUI:"};
    local totalChars = 4; -- "GUI:"
    
    for i, elem in ipairs(elements) do
        local line = string.format("- %s (%d,%d)", elem.text, elem.x, elem.y);
        if totalChars + #line + 1 > maxChars then
            table.insert(lines, string.format("... and %d more elements", #elements - i + 1));
            break;
        end
        table.insert(lines, line);
        totalChars = totalChars + #line + 1;
    end
    
    return table.concat(lines, "\n");
end

--[[
    Find GUI elements by text content (partial match)
    @param searchText: string - Text to search for (case-insensitive)
    @return table - Array of matching elements
]]
function GUIContextManager:FindElementsByText(searchText)
    if not searchText or searchText == "" then
        return {};
    end
    
    local elements = self:GetVisibleGUIElements();
    local matches = {};
    local searchLower = searchText:lower();
    
    for _, elem in ipairs(elements) do
        if elem.text and elem.text:lower():find(searchLower, 1, true) then
            table.insert(matches, elem);
        end
    end
    
    return matches;
end

--[[
    Find GUI elements by position (elements containing the point)
    @param x: number - X coordinate
    @param y: number - Y coordinate
    @return table - Array of elements at that position
]]
function GUIContextManager:FindElementsAtPosition(x, y)
    local elements = self:GetVisibleGUIElements();
    local matches = {};
    
    for _, elem in ipairs(elements) do
        if x >= elem.x and x <= elem.x + elem.width and
           y >= elem.y and y <= elem.y + elem.height then
            table.insert(matches, elem);
        end
    end
    
    return matches;
end

--[[
    Clear cached elements (force next call to refresh)
]]
function GUIContextManager:ClearCache()
    self.cachedElements = nil;
    self.cacheTime = 0;
end

--[[
    Set frame distribution parameters
    @param maxNodesPerFrame: number - Maximum nodes to process per frame
    @param frameIntervalMs: number - Interval between frames in ms
    @return self
]]
function GUIContextManager:SetFrameDistribution(maxNodesPerFrame, frameIntervalMs)
    if maxNodesPerFrame then
        self.maxNodesPerFrame = math.max(1, maxNodesPerFrame);
    end
    if frameIntervalMs then
        self.frameIntervalMs = math.max(1, frameIntervalMs);
    end
    return self;
end

--[[
    Get statistics about current GUI state
    @return table - {totalElements, byType, screenWidth, screenHeight}
]]
function GUIContextManager:GetGUIStats()
    local elements = self:GetVisibleGUIElements();
    local screenWidth, screenHeight = self:GetScreenSize();
    
    local byType = {};
    for _, elem in ipairs(elements) do
        local t = elem.type or "unknown";
        byType[t] = (byType[t] or 0) + 1;
    end
    
    return {
        totalElements = #elements,
        byType = byType,
        screenWidth = screenWidth,
        screenHeight = screenHeight,
    };
end

--------------------------------------------------------------------------------
-- Debug / Testing
--------------------------------------------------------------------------------

--[[
    Print GUI context to log for debugging
]]
function GUIContextManager:DebugPrint()
    local context = self:GetGUIContextForLLM({format = "markdown"});
    LOG.std(nil, "info", "GUIContextManager", "\n%s", context);
    echo(context);
end

--[[
    Show or hide debug UI for testing
    @param bShow: boolean - True to show, false to hide
]]
function GUIContextManager:ShowDebugUI(bShow)
    if bShow then
        if not self.debugPage then
            local width, height = 500, 700;
            local params = {
                url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/GUIContextManagerDebug.html",
                name = "GUIContextManagerDebug.ShowPage",
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
                align = "_lt",
                x = 20,
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
function GUIContextManager:RefreshDebugUI()
    if self.debugPage then
        self.debugPage:Refresh(0.1);
    end
end

--[[
    Destroy the manager and cleanup
]]
function GUIContextManager:Destroy()
    self:StopAsyncTraversal();
    self:ShowDebugUI(false);
    self:ClearCache();
    self.isInitialized = false;
    LOG.std(nil, "info", "GUIContextManager", "Destroyed");
end

return GUIContextManager;
