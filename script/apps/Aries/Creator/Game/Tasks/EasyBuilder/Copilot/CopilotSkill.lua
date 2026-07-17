--[[
Title: CopilotSkill - Copilot Auto-Discovery, Prompt Generation & Lifecycle
Author: auto-generated
Date: 2026/03/11
Desc: Encapsulates copilot discovery and orchestration logic:
      - Discovery of available copilots via CopilotManager
      - Extraction of copilot capabilities (tools, tasks, quick replies)
      - Dynamic system prompt section generation
      - Runtime copilot registration/unregistration

Tool definitions and execution are handled by CopilotTools.lua.

Usage:
    local CopilotSkill = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotSkill.lua");
    local skill = CopilotSkill:new():Init(registry);
    skill:DiscoverCopilots();
    local promptSection = skill:GetPromptSection();
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotManager.lua");
local CopilotManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotManager");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/CopilotTools.lua");
local CopilotTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.CopilotTools");

local CopilotSkill = commonlib.inherit(nil, NPL.export());

function CopilotSkill:ctor()
    self.discoveredCopilots = {};
    self.registry = nil;
    self.copilotTools = nil;
end

--[[
    Initialize with a ToolRegistry reference
    @param registry: ToolRegistry instance
    @return self for chaining
]]
function CopilotSkill:Init(registry)
    self.registry = registry;
    self.copilotTools = CopilotTools:new():Init(self);
    return self;
end

--------------------------------------------------------------------------------
-- Tool Registration
--------------------------------------------------------------------------------

--[[
    Register all copilot-related tools with the ToolRegistry.
    Delegates to CopilotTools for tool definitions and handlers.
]]
function CopilotSkill:RegisterTools()
    if self.copilotTools and self.registry then
        self.copilotTools:RegisterTools(self.registry);
    end
end

--------------------------------------------------------------------------------
-- Copilot Auto-Discovery
--------------------------------------------------------------------------------

--[[
    Discover all available copilots and their capabilities
    @return table - Array of discovered copilot info
]]
function CopilotSkill:DiscoverCopilots()
    self.discoveredCopilots = {};

    -- Try to load CopilotManager
    if not CopilotManager or not CopilotManager.GetInstance then
        return self.discoveredCopilots;
    end

    local manager = CopilotManager.GetInstance();
    if not manager or not manager.copilots then
        return self.discoveredCopilots;
    end

    -- Iterate all registered copilots
    for _, copilot in ipairs(manager.copilots) do
        local copilotInfo = self:ExtractCopilotCapabilities(copilot);
        if copilotInfo then
            table.insert(self.discoveredCopilots, copilotInfo);

            -- Register copilot's own tools with the agent
            self:RegisterCopilotTools(copilotInfo);
        end
    end

    LOG.std(nil, "info", "CopilotSkill", "Discovered %d copilots", #self.discoveredCopilots);

    return self.discoveredCopilots;
end

--[[
    Extract capabilities from a copilot instance
    @param copilot: CopilotBase instance
    @return table|nil - Copilot info with capabilities
]]
function CopilotSkill:ExtractCopilotCapabilities(copilot)
    if not copilot then
        return nil;
    end

    local info = {
        instance = copilot,
        name = "Unknown",
        description = "",
        tools = {},
        tasks = {},
        quickReplies = {},
    };

    -- Extract from GetAICharConfig if available
    if copilot.GetAICharConfig then
        local config = copilot:GetAICharConfig();
        if config then
            if config.character then
                info.name = copilot:GetName() or info.name;
                info.displayName = config.character.name or info.name;
                info.description = config.character.description or "";
                info.role = config.character.role;
            end
            if config.objective then
                info.objective = config.objective.description;
            end
            if config.quick_replies then
                for _, reply in ipairs(config.quick_replies) do
                    table.insert(info.quickReplies, {
                        text = reply.text,
                        action = reply.uiname,
                    });
                end
            end
            if config.tools then
                for _, tool in ipairs(config.tools) do
                    local func = tool["function"]
                    if func and type(func) == "table" then
                        table.insert(info.tools, {
                            name = func.name or "Unknown",
                            description = func.description or "",
                            copilotName = info.name,
                            action = func.name,
                            parameters = func.parameters or {},
                        });
                    end
                end
            end
        end
    end

    -- Extract tasks
    if copilot.GetAllTasks then
        local tasks = copilot:GetAllTasks();
        if tasks then
            for _, task in ipairs(tasks) do
                local taskInfo = {
                    name = task.name or task.class_name or "Unknown",
                    state = task.state,
                    description = task.description,
                };

                -- Get action buttons as available operations
                if task.GetActionButtons then
                    taskInfo.actions = task:GetActionButtons({});
                end

                table.insert(info.tasks, taskInfo);
            end
        end
    end

    -- Build tools from quick replies
    for _, reply in ipairs(info.quickReplies) do
        local tool = {
            name = string.format("%s_%s", info.name, reply.action or "action"),
            description = string.format("Ask %s to: %s", info.name, reply.text),
            action = reply.action,
            parameters = {
                type = "object",
                properties = {},
                required = {},
            },
        };
        table.insert(info.tools, tool);
    end

    return info;
end

--[[
    Register tools from a discovered copilot with the ToolRegistry.
    Delegates to CopilotTools for handler registration.
    @param copilotInfo: table - Copilot info from ExtractCopilotCapabilities
]]
function CopilotSkill:RegisterCopilotTools(copilotInfo)
    if self.copilotTools and self.registry then
        self.copilotTools:RegisterCopilotInstanceTools(self.registry, copilotInfo);
    end
end

--------------------------------------------------------------------------------
-- Copilot Prompt Generation
--------------------------------------------------------------------------------

--[[
    Get copilot-specific prompt based on registered copilots.
    Dynamically generates prompt text based on available copilots.
    @return string - Copilot-specific prompt section
]]
function CopilotSkill:GetPromptSection()
    local copilots = self.discoveredCopilots or {};
    if #copilots == 0 then
        return [[You have no copilot characters available.
Use other tools to interact with the scene directly.]];
    end

    local promptParts = {};
    table.insert(promptParts, "You can control the following copilot characters:\n");

    for _, copilot in ipairs(copilots) do
        local name = copilot.name or "Unknown";
        local displayName = copilot.displayName or name;
        local description = copilot.description or "";

        table.insert(promptParts, string.format("- **%s** (id: `%s`): %s\n", name, displayName, description));

        -- Add copilot-specific capabilities
        if copilot.tools and #copilot.tools > 0 then
            table.insert(promptParts, "  Capabilities: ");
            local toolNames = {};
            for _, tool in ipairs(copilot.tools) do
                table.insert(toolNames, tool.name);
            end
            table.insert(promptParts, table.concat(toolNames, ", ") .. "\n");
        end
    end

    table.insert(promptParts, "\nTo control a copilot, use `run_paracraft_copilot_code` with:\n");
    table.insert(promptParts, "- copilotName: The copilot's id (e.g., `__my_pet_copilot__`)\n");
    table.insert(promptParts, "- code: Lua code with functions: Say(text, duration), WalkTo(x,y,z), WalkForward(distance), Wait(seconds), PlayAnimation(name)\n");
    table.insert(promptParts, "- Use GetPlayerBlockPos() to get player position, GetPosition() to get copilot position\n");
    table.insert(promptParts, "- Position functions return value [x,y,z]. Check if valid with pos[1], pos[2], pos[3]\n");

    return table.concat(promptParts);
end

--[[
    Check if any copilots are registered
    @return boolean
]]
function CopilotSkill:HasCopilots()
    return self.discoveredCopilots and #self.discoveredCopilots > 0;
end

--[[
    Get the list of discovered copilots
    @return table - Array of copilot info tables
]]
function CopilotSkill:GetDiscoveredCopilots()
    return self.discoveredCopilots or {};
end

--------------------------------------------------------------------------------
-- Runtime Copilot Registration / Unregistration
--------------------------------------------------------------------------------

--[[
    Dynamically register tools for a newly added copilot.
    Call this when a copilot is registered at runtime.
    @param copilot: CopilotBase instance
]]
function CopilotSkill:OnCopilotRegistered(copilot)
    if not copilot then return; end

    -- Extract capabilities and register tools
    local copilotInfo = self:ExtractCopilotCapabilities(copilot);
    if copilotInfo then
        -- Check if already discovered
        for i, existing in ipairs(self.discoveredCopilots) do
            if existing.name and
                existing.name ~= "" and
                existing.name == copilotInfo.name then
                -- Update existing entry
                self.discoveredCopilots[i] = copilotInfo;
                LOG.std(nil, "info", "CopilotSkill", "Updated copilot: %s", copilotInfo.name);
                return;
            end
        end

        -- Add new copilot
        table.insert(self.discoveredCopilots, copilotInfo);
        self:RegisterCopilotTools(copilotInfo);

        LOG.std(nil, "info", "CopilotSkill", "Dynamically registered copilot: %s", copilotInfo.name);
    end
end

--[[
    Remove a copilot when it's unregistered.
    @param name: string - The copilot's id to remove
]]
function CopilotSkill:OnCopilotUnregistered(name)
    if not name then return; end

    for i, copilotInfo in ipairs(self.discoveredCopilots) do
        if copilotInfo.name == name then
            -- Unregister tools for this copilot
            if self.registry then
                for _, tool in ipairs(copilotInfo.tools or {}) do
                    self.registry:UnregisterTool(tool.name);
                end
            end

            table.remove(self.discoveredCopilots, i);
            LOG.std(nil, "info", "CopilotSkill", "Unregistered copilot: %s", copilotInfo.name);
            return;
        end
    end
end

--[[
    Reset state (call on agent Stop)
]]
function CopilotSkill:Reset()
    self.discoveredCopilots = {};
end
