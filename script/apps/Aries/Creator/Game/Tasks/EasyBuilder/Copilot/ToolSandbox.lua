--[[
Title: ToolSandbox
Author(s): copilot,pbb
Date: 2026/03/18
Desc: AgentRouter agent "paracraft" — exposes ToolRegistry tools to external agents
with category-based access control. Fully decoupled from BackgroundAgent.

Supports two initialization modes:

1. Assembled mode (caller provides all components):
    local sandbox = ToolSandbox:new();
    sandbox:Init(agentRouter, toolRegistry, {"file_io", "run_code"}, serviceProvider);

2. Standalone mode (auto-creates registry and registers all built-in tool modules):
    local sandbox = ToolSandbox:new();
    sandbox:InitStandalone(agentRouter, {
        allowedCategories = {"file_io", "run_code", "copilot_control", "scene_query"},
        workspace = "my_workspace",
    });
    -- Direct tool execution (no AgentRouter needed):
    sandbox:ExecuteTool("run_npl_code", {code = 'echo("hello")'}, function(result, err) end);
    -- Get tool definitions for external LLM agents:
    local defs = sandbox:GetToolDefinitions({"run_code", "file_io"});

External agents call tools via AgentRouter:
  AgentRouter:submitTask("paracraft", { action="executeTool", tool="read_file", args={...}, categories={"file_io"} })

Supported actions:
  executeTool        — Execute a single tool by name (category-checked)
  getToolDefinitions — Get OpenAI-format tool schemas filtered by category
  getCategories      — List all available tool categories

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/ToolSandbox.lua");
local ToolSandbox = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.ToolSandbox");
local sandbox = ToolSandbox:new();
sandbox:InitStandalone(agentRouter);
-- later:
sandbox:Destroy();
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Core/ToolBase.lua");

-- Class: each endpoint creates its own instance via ToolSandbox:new()
local ToolSandbox = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"),
    commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.ToolSandbox"));

-- Agent name registered on AgentRouter
local AGENT_NAME = "paracraft";

function ToolSandbox:ctor()
    self._agentRouter = nil;
    self._registry = nil;
    self._allowedCategories = nil;  -- nil = allow all
    self._serviceProvider = nil;
    self._agentName = AGENT_NAME;   -- registered name on AgentRouter
    self._initialized = false;
end

--[[
    Initialize the sandbox. Registers "paracraft" agent on the given agentRouter.
    @param agentRouter: AgentRouter instance — the per-endpoint router to register on
    @param toolRegistry: ToolRegistry instance
    @param allowedCategories: string[]|nil — server-side allowlist
    @param serviceProvider: ServiceProvider|nil — injected into tool handlers at execution
]]
function ToolSandbox:Init(agentRouter, toolRegistry, allowedCategories, serviceProvider)
    if self._initialized then
        LOG.std(nil, "warn", "ToolSandbox", "Already initialized, call Destroy() first");
        return;
    end
    if not agentRouter then
        LOG.std(nil, "error", "ToolSandbox", "Init requires an AgentRouter instance");
        return;
    end
    if not toolRegistry then
        LOG.std(nil, "error", "ToolSandbox", "Init requires a ToolRegistry instance");
        return;
    end

    self._agentRouter = agentRouter;
    self._registry = toolRegistry;
    self:SetAllowedCategories(allowedCategories);
    self._serviceProvider = serviceProvider;
    self._initialized = true;

    -- Register as AgentRouter agent on the per-endpoint router
    self._agentName = AGENT_NAME;
    local self_ = self;
    agentRouter:register(self._agentName, function(taskId, payload, streamCb, doneCb)
        self_:_HandleTask(taskId, payload, streamCb, doneCb);
    end);

    LOG.std(nil, "info", "ToolSandbox", "Initialized agent '%s' (allowed categories: %s)",
        self._agentName, allowedCategories and table.concat(allowedCategories, ", ") or "all");
end

--[[
    Standalone initialization: auto-creates ToolRegistry, registers all built-in
    tool modules (CodeTools, FileTools, SceneTools, CopilotSkill), and optionally
    registers on an AgentRouter. No BackgroundAgent or ServiceProvider needed.

    Built-in standalone tool modules (self-contained, no ServiceProvider):
      - CodeTools:   run_npl_code, run_npl_codeblock_code, run_paracraft_copilot_code
      - FileTools:   read_file, create_file, replace_string_in_file, grep_search, list_files
      - SceneTools:  query_entities (get_scene_context requires scene_context service)
      - CopilotSkill: list_copilots, send_message_to_copilot

    ServiceProvider-dependent tools (LearningTools, speak_text etc.) are NOT registered
    in standalone mode. Use RegisterToolModule() to add them manually if needed.

    @param agentRouter: AgentRouter instance|nil — if nil, only direct ExecuteTool works
    @param options: table|nil — {
        allowedCategories: string[]|nil,  — category allowlist (nil = allow all)
        workspace: string|nil,            — workspace name for FileTools
        isRemote: boolean|nil,            — FileTools remote mode (default false)
        agentName: string|nil,            — override agent name (default "paracraft")
    }
    @return self for chaining
]]
function ToolSandbox:InitStandalone(agentRouter, options)
    if self._initialized then
        LOG.std(nil, "warn", "ToolSandbox", "Already initialized, call Destroy() first");
        return self;
    end

    options = options or {};

    -- 1. Create ToolRegistry
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/ToolRegistry.lua");
    local ToolRegistry = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.ToolRegistry");
    local registry = ToolRegistry:new();

    -- 2. Register all self-contained tool modules
    -- CodeTools
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/CodeTools.lua");
    local CodeTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.CodeTools");
    self._codeTools = CodeTools:new();
    self._codeTools:RegisterTools(registry);

    -- FileTools
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/FileTools.lua");
    local FileTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.FileTools");
    self._fileTools = FileTools:new();
    if options.workspace then
        self._fileTools:SetWorkSpace(options.workspace, options.isRemote or false);
    end
    self._fileTools:RegisterTools(registry, "file_io");

    -- SceneTools
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/SceneTools.lua");
    local SceneTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.SceneTools");
    self._sceneTools = SceneTools:new();
    self._sceneTools:RegisterTools(registry);

    -- CopilotSkill
    local CopilotSkill = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotSkill.lua");
    self._copilotSkill = CopilotSkill:new():Init(registry);
    self._copilotSkill:RegisterTools();

    -- 3. Store references
    self._registry = registry;
    self._agentRouter = agentRouter;
    self:SetAllowedCategories(options.allowedCategories);
    self._serviceProvider = nil;
    self._initialized = true;

    -- 4. Register on AgentRouter if provided
    self._agentName = options.agentName or AGENT_NAME;
    if agentRouter then
        local self_ = self;
        agentRouter:register(self._agentName, function(taskId, payload, streamCb, doneCb)
            self_:_HandleTask(taskId, payload, streamCb, doneCb);
        end);
    end

    LOG.std(nil, "info", "ToolSandbox", "InitStandalone complete: %d tools registered (categories: %s)",
        self:GetToolCount(), options.allowedCategories and table.concat(options.allowedCategories, ", ") or "all");

    return self;
end

--[[
    Register an additional tool module at runtime.
    The module must implement :RegisterTools(registry, category).
    @param toolModule: table — tool module instance with RegisterTools method
    @param category: string|nil — pass-through category override
]]
function ToolSandbox:RegisterToolModule(toolModule, category)
    if not self._initialized or not self._registry then
        LOG.std(nil, "warn", "ToolSandbox", "RegisterToolModule: not initialized");
        return;
    end
    if not toolModule or not toolModule.RegisterTools then
        LOG.std(nil, "warn", "ToolSandbox", "RegisterToolModule: module must have RegisterTools method");
        return;
    end
    toolModule:RegisterTools(self._registry, category);
end

--[[
    Execute a tool directly (no AgentRouter needed).
    Bypasses category checks — caller is trusted.
    @param toolName: string — tool name
    @param params: table — tool parameters
    @param callback: function(result, errMsg.
]]
function ToolSandbox:ExecuteTool(toolName, params, callback)
    if not self._initialized or not self._registry then
        if callback then callback(nil, "ToolSandbox not initialized"); end
        return;
    end
    self._registry:ExecuteTool(toolName, params or {}, callback, self._serviceProvider);
end

--[[
    Get tool definitions in OpenAI function calling format.
    @param categories: string[]|nil — filter by categories (nil = all allowed)
    @return table — array of tool definitions
]]
function ToolSandbox:GetToolDefinitions(categories)
    if not self._initialized or not self._registry then
        return {};
    end
    -- Apply allowedCategories intersection if caller specified categories
    if categories then
        local allowedSet = self:_IntersectCategories(categories);
        if not allowedSet then return {}; end
        local catArray = {};
        for cat, _ in pairs(allowedSet) do
            table.insert(catArray, cat);
        end
        return self._registry:GetAllToolDefinitions(catArray);
    end
    -- No filter specified: return all allowed
    if self._allowedCategories then
        local catArray = {};
        for cat, _ in pairs(self._allowedCategories) do
            table.insert(catArray, cat);
        end
        return self._registry:GetAllToolDefinitions(catArray);
    end
    return self._registry:GetAllToolDefinitions();
end

--[[
    Get the underlying ToolRegistry.
    @return ToolRegistry|nil
]]
function ToolSandbox:GetRegistry()
    return self._registry;
end

--[[
    Get the FileTools instance (available after InitStandalone).
    @return FileTools|nil
]]
function ToolSandbox:GetFileTools()
    return self._fileTools;
end

--[[
    Get the CodeTools instance (available after InitStandalone).
    @return CodeTools|nil
]]
function ToolSandbox:GetCodeTools()
    return self._codeTools;
end

--[[
    Get total number of registered tools.
    @return number
]]
function ToolSandbox:GetToolCount()
    if not self._registry then return 0; end
    local count = 0;
    for _ in pairs(self._registry.tools) do
        count = count + 1;
    end
    return count;
end

--[[
    Update the server-side category allowlist at runtime.
    @param categories: string[]|nil — nil means allow all
]]
function ToolSandbox:SetAllowedCategories(categories)
    if categories and type(categories) == "table" and #categories > 0 then
        self._allowedCategories = {};
        for _, cat in ipairs(categories) do
            self._allowedCategories[cat] = true;
        end
    else
        self._allowedCategories = nil;
    end
end

--[[
    Update the ServiceProvider at runtime.
    @param serviceProvider: ServiceProvider|nil
]]
function ToolSandbox:SetServiceProvider(serviceProvider)
    self._serviceProvider = serviceProvider;
end

--[[
    Tear down: unregister from AgentRouter.
]]
function ToolSandbox:Destroy()
    if not self._initialized then return; end
    if self._agentRouter then
        self._agentRouter:unregister(self._agentName or AGENT_NAME);
    end
    self._agentRouter = nil;
    self._registry = nil;
    self._allowedCategories = nil;
    self._serviceProvider = nil;
    self._codeTools = nil;
    self._fileTools = nil;
    self._sceneTools = nil;
    self._copilotSkill = nil;
    self._initialized = false;
    LOG.std(nil, "info", "ToolSandbox", "Destroyed agent '%s'", self._agentName or AGENT_NAME);
    self._agentName = AGENT_NAME;
end

--[[
    Intersect request categories with server-side allowlist.
    @param requestCategories: string[] — categories from request payload
    @return table — intersected category set (name → true), or nil if no valid categories
]]
function ToolSandbox:_IntersectCategories(requestCategories)
    if not requestCategories or type(requestCategories) ~= "table" or #requestCategories == 0 then
        return nil;
    end

    local result = {};
    local count = 0;
    for _, cat in ipairs(requestCategories) do
        if not self._allowedCategories or self._allowedCategories[cat] then
            result[cat] = true;
            count = count + 1;
        end
    end

    return count > 0 and result or nil;
end

--[[
    Handle incoming AgentRouter task.
    @param taskId: string
    @param payload: table — { action, tool, args, categories, workspace }
                          or { toolCallOnly, fnName, fnArgs } for direct tool execution
    @param streamCb: function(streamType, content)
    @param doneCb: function(result, errMsg)
]]
function ToolSandbox:_HandleTask(taskId, payload, streamCb, doneCb)
    LOG.std(nil, "info", "ToolSandbox", "_HandleTask taskId=%s payload=%s",
        tostring(taskId), type(payload) == "table" and commonlib.serialize_compact(payload) or tostring(payload));

    if not payload or type(payload) ~= "table" then
        doneCb(nil, "Invalid payload");
        return;
    end

    -- Direct tool execution from SandboxToolEnv toolProxy (JS side sends
    -- { toolCallOnly=true, fnName="...", fnArgs={...} } via AgentRouter).
    if payload.toolCallOnly then
        self:_HandleToolCallOnly(payload, doneCb);
        return;
    end

    local action = payload.action;
    LOG.std(nil, "info", "ToolSandbox", "_HandleTask action=%s", tostring(action));

    if action == "executeTool" then
        self:_HandleExecuteTool(payload, doneCb);
    elseif action == "getToolDefinitions" then
        self:_HandleGetToolDefinitions(payload, doneCb);
    elseif action == "getCategories" then
        self:_HandleGetCategories(doneCb);
    else
        doneCb(nil, string.format("Unknown action: '%s'", tostring(action)));
    end
end

--[[
    Handle executeTool action.
]]
function ToolSandbox:_HandleExecuteTool(payload, doneCb)
    local toolName = payload.tool;
    local args = payload.args or {};
    local categories = payload.categories;

    -- 1. Categories required
    if not categories or type(categories) ~= "table" or #categories == 0 then
        doneCb(nil, "categories required");
        return;
    end

    -- 2. Server-side intersection
    local allowedSet = self:_IntersectCategories(categories);
    if not allowedSet then
        doneCb(nil, "no authorized categories");
        return;
    end

    -- 3. Tool must exist
    if not self._registry:HasTool(toolName) then
        doneCb(nil, string.format("Tool '%s' not found", toolName));
        return;
    end

    -- 4. Tool's category must be in allowed set
    local toolCategory = self._registry:GetToolCategory(toolName);
    if not allowedSet[toolCategory] then
        doneCb(nil, string.format("Tool '%s' (category '%s') not authorized for requested categories",
            toolName, toolCategory));
        return;
    end

    -- 5. Execute (inject ServiceProvider as 4th arg)
    self._registry:ExecuteTool(toolName, args, function(result, err)
        if err then
            doneCb(nil, err);
        else
            doneCb(result, nil);
        end
    end, self._serviceProvider);
end

--[[
    Handle toolCallOnly payload from JS SandboxToolEnv._executeViaProxy.
    Payload format: { toolCallOnly=true, fnName="tool_name", fnArgs={...} }
    Auto-detects the tool's category for authorization check.
]]
function ToolSandbox:_HandleToolCallOnly(payload, doneCb)
    local toolName = payload.fnName;
    local args = payload.fnArgs or {};

    if not toolName or toolName == "" then
        doneCb(nil, "toolCallOnly requires fnName");
        return;
    end

    LOG.std(nil, "info", "ToolSandbox", "_HandleToolCallOnly tool='%s'", toolName);

    -- Tool must exist in the registry
    if not self._registry:HasTool(toolName) then
        doneCb(nil, string.format("Tool '%s' not found", toolName));
        return;
    end

    -- Category authorization: auto-detect from registry and check allowed list
    local toolCategory = self._registry:GetToolCategory(toolName);
    if toolCategory and self._allowedCategories and not self._allowedCategories[toolCategory] then
        doneCb(nil, string.format("Tool '%s' (category '%s') not authorized",
            toolName, toolCategory));
        return;
    end

    -- Execute
    self._registry:ExecuteTool(toolName, args, function(result, err)
        if err then
            doneCb(nil, err);
        else
            doneCb(result, nil);
        end
    end, self._serviceProvider);
end

--[[
    Handle getToolDefinitions action.
]]
function ToolSandbox:_HandleGetToolDefinitions(payload, doneCb)
    local categories = payload.categories;

    if not categories or type(categories) ~= "table" or #categories == 0 then
        doneCb(nil, "categories required");
        return;
    end

    -- Server-side intersection
    local allowedSet = self:_IntersectCategories(categories);
    if not allowedSet then
        doneCb(nil, "no authorized categories");
        return;
    end

    -- Convert set back to array for GetAllToolDefinitions
    local catArray = {};
    for cat, _ in pairs(allowedSet) do
        table.insert(catArray, cat);
    end

    local definitions = self._registry:GetAllToolDefinitions(catArray);
    doneCb(definitions, nil);
end

--[[
    Handle getCategories action.
]]
function ToolSandbox:_HandleGetCategories(doneCb)
    local allCategories = self._registry:GetCategories();

    -- Filter by server-side allowlist if set
    if self._allowedCategories then
        local filtered = {};
        for _, cat in ipairs(allCategories) do
            if self._allowedCategories[cat] then
                table.insert(filtered, cat);
            end
        end
        doneCb(filtered, nil);
    else
        doneCb(allCategories, nil);
    end
end
