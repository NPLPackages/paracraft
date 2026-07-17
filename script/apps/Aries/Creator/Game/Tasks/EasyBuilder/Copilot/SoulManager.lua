--[[
Title: Soul Manager - Dynamic Agent Identity & Personality Loader
Author: auto-generated
Date: 2026/03/03
Desc: Manages pluggable "soul" definitions for BackgroundAgent.
      A soul defines WHO the agent is: name, identity, personality, language rules,
      behavioral boundaries, and greeting rules.

      Soul definitions are stored as simple markdown files (soul.md) with
      YAML frontmatter for metadata. Each soul lives in its own subdirectory:

        soul/papa/soul.md
        soul/coding/soul.md

      soul.md format:
        ---
        name: papa
        displayName: 帕帕
        displayNameEN: Papa
        role: AI英语学习伙伴
        roleEN: AI English learning companion
        ---
        <markdown body = full prompt content>

      Adding a new soul:
        1. Create a new subdirectory under soul/ (e.g., soul/teacher/)
        2. Add a soul.md file with YAML frontmatter and markdown body
        3. It will be auto-discovered by Soul.LoadAll()

      Conceptual model:
        soul/<name>/soul.md = WHO I am (identity, personality, rules) — switchable per character
        memory.md           = WHAT I know about the user — updated per session
        SOP                 = HOW I collect info — workflow definition
        learning            = HOW I teach — task-specific behavior

Usage:
    local Soul = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/SoulManager.lua");
    Soul.LoadAll();                             -- auto-discover souls from soul/<name>/soul.md
    Soul.SetActive("papa");                     -- switch active soul
    local prompt = Soul.GetFullPrompt()         -- full prompt from active soul's markdown body
    Soul.LoadFromURL("https://example.com/soul.md", function(ok, name) ... end)  -- remote soul
]]

local Soul = NPL.export();

--------------------------------------------------------------------------------
-- Registry
--------------------------------------------------------------------------------

-- Soul registry: name -> soul definition table
-- Each entry: { name, displayName, displayNameEN, role, roleEN, prompt, sourcePath }
local registry = {};

-- Ordered list of registered soul names (preserves discovery order)
local registeredNames = {};

-- Currently active soul name
local activeSoulName = nil;

-- Base directory for local soul files (can be overridden)
local SOUL_BASE_DIR = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/soul/";

-- Temp directory for user-updated / imported soul files (overrides code directory)
local TEMP_SOUL_DIR = "temp/soul/";

--------------------------------------------------------------------------------
-- Frontmatter Parser
--------------------------------------------------------------------------------

--- Parse a markdown file with YAML frontmatter.
-- Extracts key-value pairs from the --- delimited header and the body after it.
-- @param content string - Full file content
-- @return table meta   - Frontmatter key-value pairs (strings only)
-- @return string body  - Markdown body after frontmatter (trimmed)
local function parseFrontmatter(content)
    if not content or content == "" then
        return {}, "";
    end

    -- Normalise line endings to \n
    content = content:gsub("\r\n", "\n"):gsub("\r", "\n");

    -- Check for opening ---
    if not content:match("^%-%-%-\n") then
        -- No frontmatter — entire content is body
        return {}, content;
    end

    -- Find closing ---
    local closingStart, closingEnd = content:find("\n%-%-%-\n", 4);
    if not closingStart then
        -- Malformed: no closing ---, treat all as body
        return {}, content;
    end

    local yamlBlock = content:sub(4, closingStart); -- between opening and closing ---
    local body = content:sub(closingEnd + 1);       -- after closing ---

    -- Trim leading/trailing whitespace from body
    body = body:match("^%s*(.-)%s*$") or "";

    -- Parse simple YAML key: value pairs (no nesting, no arrays)
    local meta = {};
    for line in yamlBlock:gmatch("[^\n]+") do
        local key, value = line:match("^([%w_]+)%s*:%s*(.+)$");
        if key and value then
            -- Trim surrounding quotes if present
            value = value:match("^[\"'](.+)[\"']$") or value;
            -- Trim trailing whitespace
            value = value:match("^(.-)%s*$") or value;
            meta[key] = value;
        end
    end

    -- Post-process: split comma-separated "skills" field into an array
    if meta.skills and meta.skills ~= "" then
        local skillsList = {};
        for item in meta.skills:gmatch("[^,]+") do
            local trimmed = item:match("^%s*(.-)%s*$");
            if trimmed and trimmed ~= "" then
                table.insert(skillsList, trimmed);
            end
        end
        meta.skills = skillsList;
    else
        meta.skills = {};
    end

    return meta, body;
end

--------------------------------------------------------------------------------
-- Registration & Lookup
--------------------------------------------------------------------------------

--- Register a soul definition.
-- @param soulDef table - Must have at least { name:string, prompt:string }
-- @return boolean - true if registered successfully
function Soul.Register(soulDef)
    if not soulDef or not soulDef.name then
        LOG.std(nil, "warn", "Soul", "Cannot register soul: missing 'name' field");
        return false;
    end
    if not soulDef.prompt or soulDef.prompt == "" then
        LOG.std(nil, "warn", "Soul", "Cannot register soul '%s': empty prompt", soulDef.name);
        return false;
    end

    if registry[soulDef.name] then
        LOG.std(nil, "info", "Soul", "Soul '%s' already registered, updating", soulDef.name);
    else
        table.insert(registeredNames, soulDef.name);
    end

    registry[soulDef.name] = soulDef;
    LOG.std(nil, "info", "Soul", "Registered soul: '%s' (%s)", soulDef.name, soulDef.displayName or soulDef.name);

    -- Auto-activate the first registered soul if none is active
    if not activeSoulName then
        activeSoulName = soulDef.name;
        LOG.std(nil, "info", "Soul", "Auto-activated soul: '%s'", soulDef.name);
    end

    return true;
end

--- Get a soul definition by name.
-- @param name string - Soul identifier
-- @return table|nil - The soul definition, or nil if not found
function Soul.GetSoul(name)
    return registry[name];
end

--- Get the currently active soul definition.
-- @return table|nil
function Soul.GetActiveSoul()
    if activeSoulName then
        return registry[activeSoulName];
    end
    return nil;
end

--- Get the currently active soul name.
-- @return string|nil
function Soul.GetActiveName()
    return activeSoulName;
end

--- Set the active soul by name.
-- @param name string - Soul identifier (must be registered)
-- @return boolean - true if successfully activated
function Soul.SetActive(name)
    if not registry[name] then
        LOG.std(nil, "warn", "Soul", "Cannot activate soul '%s': not registered", tostring(name));
        return false;
    end

    local prev = activeSoulName;
    activeSoulName = name;
    if prev ~= name then
        LOG.std(nil, "info", "Soul", "Active soul changed: '%s' -> '%s'", tostring(prev), name);
    end
    return true;
end

--- Get all registered soul names.
-- @return table - Array of name strings
function Soul.GetRegisteredNames()
    return registeredNames;
end

--- Get the total number of registered souls.
-- @return number
function Soul.GetCount()
    return #registeredNames;
end

--- Check if a soul is registered.
-- @param name string
-- @return boolean
function Soul.IsRegistered(name)
    return registry[name] ~= nil;
end

--------------------------------------------------------------------------------
-- Skill Binding (soul declares which skills it can use)
--------------------------------------------------------------------------------

--- Get the skills declared by a soul.
-- @param name string - Soul identifier
-- @return table - Array of skill name strings (empty if none declared)
function Soul.GetSkills(name)
    local soul = registry[name];
    return soul and soul.skills or {};
end

--- Get the skills declared by the active soul.
-- @return table - Array of skill name strings (empty if none declared)
function Soul.GetActiveSkills()
    if activeSoulName then
        return Soul.GetSkills(activeSoulName);
    end
    return {};
end

--- Check if a skill is declared by a given soul.
-- @param soulName string - Soul identifier
-- @param skillName string - Skill identifier to check
-- @return boolean - true if the soul declares this skill
function Soul.HasSkill(soulName, skillName)
    local skills = Soul.GetSkills(soulName);
    for _, s in ipairs(skills) do
        if s == skillName then return true; end
    end
    return false;
end

--- Generate an "activate_skill" tool definition and handler for the active soul.
-- The tool allows the LLM to dynamically invoke a skill's SOP workflow.
-- Only skills declared in the active soul's frontmatter `skills` field are selectable.
--
-- @param agent table - BackgroundAgent instance (for calling PrepareSOPSession etc.)
-- @return table|nil  - { name, description, parameters, handler, strategy }
--                      or nil if the active soul has no skills
function Soul.GenerateActivateSkillTool(agent)
    local skills = Soul.GetActiveSkills();
    if not skills or #skills == 0 then
        return nil;
    end

    -- Lazy-load SkillManager to build enum descriptions
    local SkillManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/SkillManager.lua");

    -- Build enum list and description from discovered skills
    local enumValues = {};
    local skillDescriptions = {};
    for _, skillName in ipairs(skills) do
        if SkillManager and SkillManager.IsDiscovered(skillName) then
            table.insert(enumValues, skillName);
            local desc = SkillManager.GetSkillDescription(skillName) or skillName;
            table.insert(skillDescriptions, string.format("- %s: %s", skillName, desc));
        else
            LOG.std(nil, "warn", "Soul", "Soul '%s' declares skill '%s' but it is not discovered by SkillManager",
                tostring(activeSoulName), skillName);
        end
    end

    if #enumValues == 0 then
        return nil;
    end

    local toolDescription = string.format(
        "Activate a learning skill to start its data-collection (SOP) workflow. "
        .. "Call this when the user wants to start or switch a learning activity. "
        .. "Available skills:\n%s",
        table.concat(skillDescriptions, "\n")
    );

    return {
        name = "activate_skill",
        description = toolDescription,
        parameters = {
            type = "object",
            properties = {
                skill = {
                    type = "string",
                    description = "The skill to activate",
                    enum = enumValues,
                },
            },
            required = {"skill"},
        },
        handler = function(selfAgent, params, callback)
            local skillName = params and params.skill;
            if not skillName then
                callback({ success = false, error = "Missing required parameter: skill" });
                return;
            end

            -- Validate skill is in the active soul's declared list
            local currentSoul = Soul.GetActiveName();
            if not Soul.HasSkill(currentSoul, skillName) then
                callback({
                    success = false,
                    error = string.format("Soul '%s' does not declare skill '%s'", tostring(currentSoul), skillName),
                });
                return;
            end

            -- Validate skill is discovered
            if not SkillManager.IsDiscovered(skillName) then
                callback({
                    success = false,
                    error = string.format("Skill '%s' is not discovered", skillName),
                });
                return;
            end

            LOG.std(nil, "info", "Soul", "activate_skill: activating '%s' for soul '%s'", skillName, tostring(currentSoul));

            -- Prepare the SOP session (reads existing data, sets agentPhase = "sop")
            selfAgent:PrepareSOPSession(skillName, currentSoul);

            -- The SOP system prompt will be built by BuildLearningSystemPrompt when needed
            -- Just tell the LLM which skill was activated
            callback({
                success = true,
                skill = skillName,
                message = string.format("Skill '%s' activated. You are now in SOP mode. Follow the system prompt instructions to collect user data.", skillName),
            });
        end,
        strategy = { mode = "sync", impact = "write", category = "skill_activation" },
    };
end

--------------------------------------------------------------------------------
-- Loading from local markdown files
--------------------------------------------------------------------------------

--- Load a soul definition from a soul.md markdown file.
-- The file must have YAML frontmatter with at least a `name` field.
-- The markdown body becomes the full prompt.
-- @param filepath string - Path to the soul.md file (relative to working dir)
-- @return boolean - true if loaded and registered
function Soul.LoadFromFile(filepath)
    local file = ParaIO.open(filepath, "r");
    if not file:IsValid() then
        file:close();
        LOG.std(nil, "warn", "Soul", "Failed to open soul file: %s", filepath);
        return false;
    end

    local content = file:GetText(0, -1);
    file:close();

    if not content or content == "" then
        LOG.std(nil, "warn", "Soul", "Empty soul file: %s", filepath);
        return false;
    end

    return Soul.LoadFromString(content, filepath);
end

--- Load a soul definition from a markdown string.
-- Parses frontmatter + body and registers the soul.
-- @param content string    - Full markdown content with frontmatter
-- @param sourcePath string - Optional source path for logging
-- @return boolean          - true if registered successfully
function Soul.LoadFromString(content, sourcePath)
    local meta, body = parseFrontmatter(content);

    if not meta.name or meta.name == "" then
        LOG.std(nil, "warn", "Soul", "Soul file has no 'name' in frontmatter: %s", tostring(sourcePath));
        return false;
    end

    if not body or body == "" then
        LOG.std(nil, "warn", "Soul", "Soul file has empty body (no prompt): %s", tostring(sourcePath));
        return false;
    end

    local isTemp = sourcePath and sourcePath:find("temp/") == 1;

    local soulDef = {
        name           = meta.name,
        displayName    = meta.displayName or meta.name,
        displayNameEN  = meta.displayNameEN or "",
        role           = meta.role or "",
        roleEN         = meta.roleEN or "",
        skills         = meta.skills or {},  -- Array of skill names this soul can activate
        prompt         = body,
        sourcePath     = sourcePath or "string",
        isTemp         = isTemp or false,     -- true if loaded from temp directory
    };

    return Soul.Register(soulDef);
end

--- Scan a directory for soul.md files and load them.
-- @param baseDir string - Directory to scan (e.g., SOUL_BASE_DIR or TEMP_SOUL_DIR)
-- @param label string   - Label for logging (e.g., "code" or "temp")
-- @return number        - Number of souls loaded from this directory
local function loadSoulsFromDir(baseDir, label)
    local count = 0;

    local searchResult = ParaIO.SearchFiles("", baseDir .. "*/soul.md", "", 0, 50, 0);
    local nFiles = searchResult:GetNumOfResult();

    if nFiles == 0 and label == "code" then
        -- Fallback: try known soul names if SearchFiles doesn't match
        LOG.std(nil, "info", "Soul", "SearchFiles returned 0 results for %s dir, trying known soul paths", label);
        local knownSouls = {"papa", "coding"};
        for _, soulName in ipairs(knownSouls) do
            local path = baseDir .. soulName .. "/soul.md";
            if Soul.LoadFromFile(path) then
                count = count + 1;
            end
        end
    else
        for i = 0, nFiles - 1 do
            local relPath = searchResult:GetItem(i);
            local fullPath = baseDir .. relPath;
            if Soul.LoadFromFile(fullPath) then
                count = count + 1;
            end
        end
    end

    return count;
end

--- Load all soul definitions from code and temp directories.
-- Scans both the code directory (soul/<name>/soul.md) and the temp directory
-- (temp/soul/<name>/soul.md). Temp souls override code souls with the same name.
function Soul.LoadAll()
    -- Reset registry for clean reload
    registry = {};
    registeredNames = {};
    activeSoulName = nil;

    -- Phase 1: Load souls from code directory (built-in)
    local codeCount = loadSoulsFromDir(SOUL_BASE_DIR, "code");

    -- Phase 2: Load souls from temp directory (user-updated / imported)
    -- These override code-directory souls with the same name.
    local tempCount = loadSoulsFromDir(TEMP_SOUL_DIR, "temp");

    LOG.std(nil, "info", "Soul", "LoadAll complete: %d souls registered (code=%d, temp=%d), active: '%s'",
        #registeredNames, codeCount, tempCount, tostring(activeSoulName));
end

--- Get the temp soul directory path.
-- @return string
function Soul.GetTempDir()
    return TEMP_SOUL_DIR;
end

--------------------------------------------------------------------------------
-- Soul Self-Update (P2-1)
-- Allows the LLM to read, modify, and hot-reload soul definitions at runtime.
-- Writes go to temp/soul/<name>/soul.md so code-directory originals are untouched.
--------------------------------------------------------------------------------

--- Read the raw content of a soul's .md file.
-- Returns the full file content (frontmatter + body) as a string.
-- @param name string - Soul name (defaults to active soul if nil)
-- @return string|nil - Raw file content, or nil if not found
function Soul.ReadRawContent(name)
    name = name or activeSoulName;
    if not name then return nil; end

    local soul = registry[name];
    if not soul then
        LOG.std(nil, "warn", "Soul", "ReadRawContent: soul '%s' not found in registry", name);
        return nil;
    end

    -- Try temp path first, then sourcePath from registry
    local paths = {
        TEMP_SOUL_DIR .. name .. "/soul.md",
        soul.sourcePath,
    };

    for _, path in ipairs(paths) do
        if path and path ~= "" then
            local file = ParaIO.open(path, "r");
            if file:IsValid() then
                local content = file:GetText(0, -1);
                file:close();
                if content and content ~= "" then
                    LOG.std(nil, "debug", "Soul", "ReadRawContent: read '%s' from %s (%d bytes)", name, path, #content);
                    return content;
                end
            else
                file:close();
            end
        end
    end

    LOG.std(nil, "warn", "Soul", "ReadRawContent: no readable file for soul '%s'", name);
    return nil;
end

--- Save a soul definition to a temp file.
-- Writes the full content (frontmatter + body) to temp/soul/<name>/soul.md.
-- The code-directory original is never modified.
-- @param name string - Soul name
-- @param content string - Full soul.md content (must include --- frontmatter ---)
-- @return boolean - true if saved successfully
-- @return string|nil - Error message on failure
function Soul.SaveToTempFile(name, content)
    if not name or name == "" then
        return false, "Soul name is required";
    end
    if not content or content == "" then
        return false, "Content is required";
    end

    -- Validate frontmatter presence
    if not string.find(content, "^%-%-%-") then
        return false, "Content must start with '---' frontmatter delimiter";
    end

    -- Validate frontmatter has closing delimiter
    local _, frontEnd = string.find(content, "\n%-%-%-", 4);
    if not frontEnd then
        return false, "Content must have closing '---' frontmatter delimiter";
    end

    local dir = TEMP_SOUL_DIR .. name .. "/";
    ParaIO.CreateDirectory(dir);

    local path = dir .. "soul.md";
    local file = ParaIO.open(path, "w");
    if not file:IsValid() then
        file:close();
        LOG.std(nil, "warn", "Soul", "SaveToTempFile: failed to write '%s': %s", name, path);
        return false, "Failed to open file for writing: " .. path;
    end

    file:WriteString(content);
    file:close();

    LOG.std(nil, "info", "Soul", "SaveToTempFile: saved '%s' (%d bytes) to %s", name, #content, path);
    return true;
end

--- Hot-reload a soul definition from its temp file.
-- Re-reads the temp/soul/<name>/soul.md file, parses frontmatter + body,
-- and re-registers the soul in the registry. The next system prompt assembly
-- will pick up the updated content.
-- @param name string - Soul name to reload
-- @return boolean - true if reloaded successfully
-- @return string|nil - Error message on failure
function Soul.HotReload(name)
    if not name or name == "" then
        return false, "Soul name is required";
    end

    local path = TEMP_SOUL_DIR .. name .. "/soul.md";
    local file = ParaIO.open(path, "r");
    if not file:IsValid() then
        file:close();
        LOG.std(nil, "warn", "Soul", "HotReload: temp file not found for '%s': %s", name, path);
        return false, "Temp file not found: " .. path;
    end

    local content = file:GetText(0, -1);
    file:close();

    if not content or content == "" then
        return false, "Temp file is empty: " .. path;
    end

    -- Parse and register (LoadFromString handles frontmatter + body + Register)
    local ok = Soul.LoadFromString(content, path);
    if ok then
        LOG.std(nil, "info", "Soul", "HotReload: successfully reloaded '%s' from %s", name, path);
        return true;
    else
        return false, string.format("Failed to parse soul from %s", path);
    end
end

--------------------------------------------------------------------------------
-- Loading from remote URL
--------------------------------------------------------------------------------

--- Load a soul definition from a remote URL (async).
-- Downloads a soul.md markdown file and registers the soul on success.
-- @param url string               - URL to a soul.md file
-- @param callback function(ok, nameOrError) - Called with (true, soulName) on success
--                                             or (false, errorMessage) on failure
function Soul.LoadFromURL(url, callback)
    if not url or url == "" then
        if callback then callback(false, "URL is empty"); end
        return;
    end

    LOG.std(nil, "info", "Soul", "Loading remote soul from: %s", url);

    System.os.GetUrl(url, function(err, msg, data)
        if err ~= 200 then
            local errMsg = string.format("HTTP %s fetching soul from %s", tostring(err), url);
            LOG.std(nil, "warn", "Soul", errMsg);
            if callback then callback(false, errMsg); end
            return;
        end

        -- Extract string content from response
        local content = data;
        if type(msg) == "table" and msg.data then
            content = msg.data;
        elseif type(data) == "table" and data.data then
            content = data.data;
        end

        if type(content) ~= "string" or content == "" then
            local errMsg = "Empty response from " .. url;
            LOG.std(nil, "warn", "Soul", errMsg);
            if callback then callback(false, errMsg); end
            return;
        end

        local ok = Soul.LoadFromString(content, url);
        if ok then
            -- Find the name that was just registered (from frontmatter)
            local meta = parseFrontmatter(content);
            LOG.std(nil, "info", "Soul", "Remote soul loaded: '%s' from %s", meta.name, url);
            if callback then callback(true, meta.name); end
        else
            if callback then callback(false, "Failed to parse soul from " .. url); end
        end
    end);
end

--- Set the base directory for soul files.
-- Useful for Mods that store souls in a custom location.
-- @param dir string - Directory path ending with /
function Soul.SetBaseDir(dir)
    if dir and dir ~= "" then
        -- Ensure trailing slash
        if dir:sub(-1) ~= "/" then
            dir = dir .. "/";
        end
        SOUL_BASE_DIR = dir;
        LOG.std(nil, "info", "Soul", "Base directory changed to: %s", dir);
    end
end

--- Get the current base directory for soul files.
-- @return string
function Soul.GetBaseDir()
    return SOUL_BASE_DIR;
end

--------------------------------------------------------------------------------
-- Prompt Accessors (delegate to active soul)
--------------------------------------------------------------------------------

--- Get the full prompt from the active soul (markdown body of soul.md).
-- This is the complete "soul layer" to prepend to any phase prompt.
-- @return string
function Soul.GetFullPrompt()
    local soul = Soul.GetActiveSoul();
    return soul and soul.prompt or "";
end

--- Get the full prompt for a specific soul by name.
-- @param name string - Soul identifier
-- @return string
function Soul.GetFullPromptByName(name)
    local soul = registry[name];
    return soul and soul.prompt or "";
end

--- Get the display name of the active soul.
-- @return string
function Soul.GetDisplayName()
    local soul = Soul.GetActiveSoul();
    return soul and soul.displayName or "";
end

--- Get the display name (English) of the active soul.
-- @return string
function Soul.GetDisplayNameEN()
    local soul = Soul.GetActiveSoul();
    return soul and soul.displayNameEN or "";
end

--------------------------------------------------------------------------------
-- Backward Compatibility
--------------------------------------------------------------------------------

--- Get identity (backward compat — returns full prompt).
-- @return string
function Soul.GetIdentity()
    return Soul.GetFullPrompt();
end

--- Get response rules (backward compat — returns full prompt).
-- @return string
function Soul.GetResponseRules()
    return Soul.GetFullPrompt();
end
