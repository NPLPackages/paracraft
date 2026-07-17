--[[
Title: SkillManager - Skill Discovery & Catalog Builder
Author: auto-generated
Date: 2026/03/06
Desc: Lightweight skill discovery module. Scans workspace skill directories
      for SKILL.md files, parses YAML frontmatter (name + description only), and
      builds a Claude-style XML catalog for injection into user messages.
      
      All runtime logic (profile storage, prompt building, phase transitions) lives
      in BackgroundAgent.lua. This module is purely for discovery and catalog generation.
      
      Directory layout (workspace-based):
        workspace/<agent>/skills/<skill-name>/SKILL.md  (agent-specific skills)
        workspace/skills/<skill-name>/SKILL.md          (shared skills)
        temp/skills/<skill-name>/SKILL.md               (overrides, hot-loaded)

      Discovery order (later overrides earlier):
        1. Agent skills  (set via SetAgentSkillDir)
        2. Shared skills (workspace/skills/)
        3. Temp skills   (temp/skills/)

Usage:
    local SkillManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/SkillManager.lua");
    SkillManager.SetAgentSkillDir("script/.../workspace/eduagent/skills/");
    SkillManager.DiscoverAll();
    local catalogXML = SkillManager.BuildCatalogXML();
    local names = SkillManager.GetSkillNames();
]]

NPL.load("(gl)script/ide/Files.lua");

local SkillManager = NPL.export();
local Files = commonlib.Files;

-- Discovered skills: name -> { name, description, filePath, baseDir }
local discovered = {};

-- Ordered list of discovered skill names
local discoveredNames = {};

-- Agent-specific skill directory (set via SetAgentSkillDir, e.g. workspace/eduagent/skills/)
local AGENT_SKILL_DIR = nil;

-- Shared skill directory (workspace-level skills available to all agents)
local SHARED_SKILL_DIR = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/workspace/skills/";

-- Temp directory for user-updated / imported skill modules (hot-load overrides)
local TEMP_SKILL_DIR = "temp/skills/";

-- Legacy alias (kept for backward compatibility with external code)
local SKILL_DIR = SHARED_SKILL_DIR;

--------------------------------------------------------------------------------
-- YAML Frontmatter Parser
--------------------------------------------------------------------------------

--- Parse YAML frontmatter from a SKILL.md file content.
-- Expects the file to start with "---\n" and end the frontmatter with "\n---\n".
-- Extracts: `name`, `description`, and `internal` (boolean).
-- @param content string - Full file content
-- @return table|nil - Parsed frontmatter fields, or nil on failure
function SkillManager.ParseFrontmatter(content)
    if not content or content == "" then return nil; end
    
    -- Match YAML frontmatter block: starts and ends with ---
    local frontmatter = content:match("^%-%-%-\r?\n(.-)\r?\n%-%-%-");
    if not frontmatter then return nil; end
    
    local result = {};
    
    -- Helper: parse a single-line YAML field
    local function parseField(key)
        local val = frontmatter:match(key .. ":%s*(.-)%s*\r?\n");
        if not val or val == "" then
            val = frontmatter:match(key .. ":%s*(.-)%s*$");
        end
        -- Strip surrounding quotes
        if val then
            val = val:match('^["\'](.+)["\']$') or val;
        end
        return (val and val ~= "") and val or nil;
    end
    
    result.name = parseField("name");
    result.description = parseField("description");
    local internalStr = parseField("internal");
    result.internal = (internalStr == "true");
    
    if not result.name then return nil; end
    return result;
end

--------------------------------------------------------------------------------
-- Discovery API
--------------------------------------------------------------------------------

--- Read and parse a SKILL.md file from a given path.
-- Only extracts frontmatter (name, description, internal) for the catalog.
-- Full skill content is read on demand by the LLM via read_file tool.
-- @param skillName string - Directory name of the skill
-- @param baseDir string - Base directory (SKILL_DIR or TEMP_SKILL_DIR)
-- @return table|nil - { name, description, internal, filePath, baseDir } or nil
local function discoverSkillAt(skillName, baseDir)
    local path = baseDir .. skillName .. "/SKILL.md";
    local file = ParaIO.open(path, "r");
    if not file:IsValid() then
        file:close();
        return nil;
    end
    
    local content = file:GetText(0, -1);
    file:close();
    
    if not content or content == "" then return nil; end
    
    local meta = SkillManager.ParseFrontmatter(content);
    if not meta then
        LOG.std(nil, "warn", "SkillManager", "SKILL.md at '%s' has no valid frontmatter", path);
        return nil;
    end
    
    return {
        name = meta.name,
        description = meta.description or "",
        internal = meta.internal or false,
        filePath = path,
        baseDir = baseDir,
    };
end

local function findSkillFiles(rootPath, nMaxFilesNum)
    local aResult = {}
    local results = commonlib.Files.Find(aResult, rootPath, 0, nMaxFilesNum or 50, function(item) 
        if(item.filename:match("%.md$")) then
            return true;
        end
    end, "*.zip") or {};
    if #results == 0 then
        results = commonlib.Files.Find(aResult, rootPath, 2, nMaxFilesNum or 50, function(item)
            if(item.filename:match("%.md$")) then
                return true;
            end
        end) or {};
    end
    return results;
end

--- Set the agent-specific skill directory.
-- Called by BackgroundAgent:SetAgent() to point to the active agent's skills folder.
-- @param dir string|nil - Directory path ending with / (e.g. "workspace/eduagent/skills/"), or nil to clear
function SkillManager.SetAgentSkillDir(dir)
    if dir and dir ~= "" then
        if dir:sub(-1) ~= "/" then dir = dir .. "/"; end
        AGENT_SKILL_DIR = dir;
        LOG.std(nil, "info", "SkillManager", "Agent skill dir set: %s", dir);
    else
        AGENT_SKILL_DIR = nil;
        LOG.std(nil, "info", "SkillManager", "Agent skill dir cleared");
    end
end

--- Get the agent-specific skill directory.
-- @return string|nil
function SkillManager.GetAgentSkillDir()
    return AGENT_SKILL_DIR;
end

--- Helper: scan a directory and register discovered skills.
-- @param baseDir string - Directory to scan
-- @param label string - Label for logging ("agent", "shared", "temp")
local function discoverSkillsFromDir(baseDir, label)
    if not baseDir or baseDir == "" then return 0; end
    local count = 0;
    local searchResult = findSkillFiles(baseDir, 50);
    for _, item in ipairs(searchResult) do
        local relPath = item.filename or "";
        local skillName = relPath:match("^([^/]+)/SKILL%.md$");
        if skillName and skillName ~= "" then
            local info = discoverSkillAt(skillName, baseDir);
            if info then
                if info.internal then
                    LOG.std(nil, "info", "SkillManager", "Skipped internal %s skill: '%s'", label, info.name);
                else
                    if not discovered[info.name] then
                        table.insert(discoveredNames, info.name);
                    end
                    discovered[info.name] = info;
                    count = count + 1;
                    LOG.std(nil, "info", "SkillManager", "Discovered %s skill: '%s'", label, info.name);
                end
            end
        end
    end
    return count;
end

--- Discover all skills from agent, shared, and temp directories.
-- Later directories override earlier ones with the same skill name.
-- Call this once during initialization (after SetAgentSkillDir if needed).
function SkillManager.DiscoverAll()
    discovered = {};
    discoveredNames = {};
    
    -- Phase 1: Agent-specific skills (highest priority base, overridden only by temp)
    local agentCount = 0;
    if AGENT_SKILL_DIR then
        agentCount = discoverSkillsFromDir(AGENT_SKILL_DIR, "agent");
    end
    
    -- Phase 2: Shared workspace skills (available to all agents)
    local sharedCount = discoverSkillsFromDir(SHARED_SKILL_DIR, "shared");
    
    -- Phase 3: Temp skills (highest priority — hot-loaded overrides)
    local tempCount = discoverSkillsFromDir(TEMP_SKILL_DIR, "temp");
    
    LOG.std(nil, "info", "SkillManager", "DiscoverAll complete: %d skills (agent=%d, shared=%d, temp=%d)",
        #discoveredNames, agentCount, sharedCount, tempCount);
end

--- Get all discovered skill names.
-- @return table - Array of name strings
function SkillManager.GetSkillNames()
    return discoveredNames;
end

--- Get the number of discovered skills.
-- @return number
function SkillManager.GetCount()
    return #discoveredNames;
end

--- Check if a skill has been discovered.
-- @param name string
-- @return boolean
function SkillManager.IsDiscovered(name)
    return discovered[name] ~= nil;
end

--- Get the SKILL.md file path for a discovered skill.
-- @param name string - Skill name
-- @return string|nil - File path, or nil if not discovered
function SkillManager.GetSkillFilePath(name)
    local info = discovered[name];
    return info and info.filePath or nil;
end

--- Get the base directory for a discovered skill.
-- @param name string - Skill name
-- @return string|nil - Base directory path, or nil if not discovered
function SkillManager.GetSkillBaseDir(name)
    local info = discovered[name];
    return info and info.baseDir or nil;
end

--- Get basic info for a discovered skill.
-- @param name string - Skill name
-- @return table|nil - { name, description, filePath, baseDir }
function SkillManager.GetSkillInfo(name)
    return discovered[name];
end

--- Get the description for a discovered skill.
-- @param name string - Skill name
-- @return string|nil - Description string, or nil if not discovered
function SkillManager.GetSkillDescription(name)
    local info = discovered[name];
    return info and info.description or nil;
end

--- Get the temp skill directory path.
-- @return string
function SkillManager.GetTempSkillDir()
    return TEMP_SKILL_DIR;
end

--- Get the shared skill directory path.
-- @return string
function SkillManager.GetSkillDir()
    return SHARED_SKILL_DIR;
end

--------------------------------------------------------------------------------
-- Catalog XML Builder  (Claude-style skill discovery prompt)
--------------------------------------------------------------------------------

--- Build an XML catalog of all discovered skills for injection into user messages.
-- @return string - XML catalog string, or "" if no skills discovered
function SkillManager.BuildCatalogXML()
    if #discoveredNames == 0 then
        return "";
    end
    
    local parts = {};
    table.insert(parts, "<instructions>");
    table.insert(parts, "<skills>");
    table.insert(parts, "Here is a list of skills that contain domain specific knowledge on a variety of topics.");
    table.insert(parts, "Each skill comes with a description of the topic and a file path that contains the detailed instructions.");
    table.insert(parts, "When a user asks you to perform a task that falls within the domain of a skill, use the 'read_file' tool to acquire the full instructions from the file path.");
    
    for _, name in ipairs(discoveredNames) do
        local info = discovered[name];
        if info and not info.internal then
            table.insert(parts, "<skill>");
            table.insert(parts, string.format("<name>%s</name>", info.name));
            table.insert(parts, string.format("<description>%s</description>", info.description or ""));
            table.insert(parts, string.format("<file>%s</file>", info.filePath or ""));
            table.insert(parts, "</skill>");
        end
    end
    
    table.insert(parts, "</skills>");
    table.insert(parts, "</instructions>");
    
    return table.concat(parts, "\n");
end

--- Legacy compatibility aliases (used by external code that expects old API names).
-- Maps old names to new discovery-based equivalents.
SkillManager.GetRegisteredNames = SkillManager.GetSkillNames;
SkillManager.IsRegistered = SkillManager.IsDiscovered;
