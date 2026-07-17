--[[
Title: Global Memory Manager
Author: auto-generated
Date: 2026/03/04
Desc: Manages a cross-Skill shared knowledge file (global_memory.md) inspired by OpenClaw's MEMORY.md.
      Global Memory stores teaching experience, domain knowledge, and patterns discovered
      across all Skills. It is injected into every System Prompt (after Soul, before Skill SOP)
      and can be updated by the LLM via file tools (append_to_file / create_file).

      File location: FileTools sandbox / global_memory.md  (per-user-per-world, LLM-writable)

Usage:
    local GlobalMemory = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/GlobalMemoryManager.lua");
    GlobalMemory.Init();
    local content = GlobalMemory.GetContent();
    GlobalMemory.AppendEntry("学生普遍对动物词汇接受度高，对颜色类词汇容易混淆");
]]
local GlobalMemory = NPL.export();
--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

-- Filename within the FileTools sandbox (LLM can read/write via file tools)
local MEMORY_FILENAME = "global_memory.md";

-- Maximum file size in bytes before we recommend the LLM to consolidate
local MAX_FILE_SIZE = 8000;

-- Default initial content when creating a new global_memory.md
local DEFAULT_CONTENT = [[# Global Memory

> 跨 Skill 共享的教学经验和领域知识。LLM 可通过 file tools (append_to_file / create_file) 更新。
> 高频核心知识永驻 System Prompt，供所有 Skill 共享参考。

]];

--------------------------------------------------------------------------------
-- Internal state
--------------------------------------------------------------------------------

local initialized = false;

-- Shared FileTools instance (set via SetFileTools)
local fileToolsInstance = nil;

-- Cached content to avoid repeated file I/O on every prompt assembly
local cachedContent = nil;
local cacheTimestamp = 0;
local CACHE_TTL = 10; -- seconds before cache expires

--- Set the shared FileTools instance for this manager.
-- Should be called once during BackgroundAgent initialization.
-- @param ft FileTools - FileTools instance with workspace configured
function GlobalMemory.SetFileTools(ft)
    fileToolsInstance = ft;
end

--- Get the active FileTools instance (lazy-fallback to new local instance).
-- @return FileTools - The FileTools instance
local function getFileTools()
    if fileToolsInstance then
        return fileToolsInstance;
    end
    -- Fallback: create a local instance using GetBaseDir
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/FileTools.lua");
    local FileTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.FileTools");
    fileToolsInstance = FileTools:new();
    fileToolsInstance:SetWorkSpace(nil, false);
    return fileToolsInstance;
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Initialize the Global Memory Manager.
-- Creates the default global_memory.md if it doesn't exist.
function GlobalMemory.Init()
    if initialized then return; end
    initialized = true;
    
    -- Create default file if it doesn't exist
    local ft = getFileTools();
    local readResult = ft:ReadFile(MEMORY_FILENAME);
    if not readResult.success or not readResult.content or readResult.content == "" then
        ft:CreateFile(MEMORY_FILENAME, DEFAULT_CONTENT);
        LOG.std(nil, "info", "GlobalMemory", "Created default global_memory.md");
    end
    
    LOG.std(nil, "info", "GlobalMemory", "Initialized (file: %s)", MEMORY_FILENAME);
end

--- Get the full content of global_memory.md.
-- Uses a short-lived cache to avoid repeated file reads during prompt assembly.
-- @return string - File content, or empty string if not found
function GlobalMemory.GetContent()
    local now = os.time();
    if cachedContent and (now - cacheTimestamp) < CACHE_TTL then
        return cachedContent;
    end
    
    local ft = getFileTools();
    local readResult = ft:ReadFile(MEMORY_FILENAME);
    if not readResult.success or not readResult.content or readResult.content == "" then
        cachedContent = "";
        cacheTimestamp = now;
        return "";
    end
    
    cachedContent = readResult.content;
    cacheTimestamp = now;
    return cachedContent;
end

--- Save (overwrite) the entire content of global_memory.md.
-- Used by LLM when it wants to consolidate/reorganize the memory.
-- @param content string - New full content
-- @return boolean - true if saved successfully
function GlobalMemory.SaveContent(content)
    if not content then return false; end
    
    local ft = getFileTools();
    local result = ft:CreateFile(MEMORY_FILENAME, content);
    if result.success then
        -- Invalidate cache
        cachedContent = content;
        cacheTimestamp = os.time();
        LOG.std(nil, "info", "GlobalMemory", "Content replaced (%d bytes)", #content);
    end
    return result.success;
end

--- Append a timestamped entry to global_memory.md.
-- Each entry is formatted as: ### YYYY-MM-DD HH:MM\n<entry>\n
-- @param entry string - The insight/knowledge to append
-- @return boolean - true if saved successfully
-- @return string|nil - Warning message if file is getting large
function GlobalMemory.AppendEntry(entry)
    if not entry or entry == "" then return false; end
    
    local ft = getFileTools();
    local readResult = ft:ReadFile(MEMORY_FILENAME);
    local existing = (readResult.success and readResult.content and readResult.content ~= "") and readResult.content or DEFAULT_CONTENT;
    
    -- Format entry with timestamp
    local timestamp = os.date("%Y-%m-%d %H:%M");
    local formatted = string.format("\n### %s\n%s\n", timestamp, entry);
    
    local newContent = existing .. formatted;
    local result = ft:CreateFile(MEMORY_FILENAME, newContent);
    
    if result.success then
        -- Invalidate cache
        cachedContent = newContent;
        cacheTimestamp = os.time();
        LOG.std(nil, "info", "GlobalMemory", "Appended entry (%d bytes, total %d bytes)", 
            #entry, #newContent);
    end
    
    -- Warn if file is getting large
    local warning = nil;
    if #newContent > MAX_FILE_SIZE then
        warning = string.format(
            "Global memory file is large (%d bytes / %d max). Consider using action='replace' to consolidate entries.",
            #newContent, MAX_FILE_SIZE);
    end
    
    return result.success, warning;
end

--- Get the memory filename.
-- @return string
function GlobalMemory.GetFilePath()
    return MEMORY_FILENAME;
end

--- Get formatted content for prompt injection.
-- Returns the content wrapped in a markdown section header, or empty string if no content.
-- @return string - Formatted for System Prompt injection
function GlobalMemory.GetPromptSection()
    local content = GlobalMemory.GetContent();
    if not content or content == "" then
        return "";
    end
    
    -- Strip the header line "# Global Memory" if present (we add our own section header)
    local body = content:gsub("^#%s*Global Memory[^\n]*\n", "");
    body = body:match("^%s*(.-)%s*$") or body; -- trim
    
    if body == "" then
        return "";
    end
    
    return "\n\n## Global Memory (跨技能共享知识)\n\n" .. body .. "\n";
end

--- Invalidate the cache, forcing next GetContent() to re-read from disk.
function GlobalMemory.InvalidateCache()
    cachedContent = nil;
    cacheTimestamp = 0;
end

--- Get estimated token count of the global memory content.
-- @return number - Estimated tokens
function GlobalMemory.GetEstimatedTokens()
    local content = GlobalMemory.GetContent();
    if not content or content == "" then return 0; end
    
    -- Simple estimation: CJK chars ~1.5 tokens, ASCII ~0.25 tokens
    local tokens = 0;
    for i = 1, #content do
        local byte = string.byte(content, i);
        if byte > 127 then
            tokens = tokens + 1.5;
        else
            tokens = tokens + 0.25;
        end
    end
    return math.floor(tokens);
end

return GlobalMemory;
