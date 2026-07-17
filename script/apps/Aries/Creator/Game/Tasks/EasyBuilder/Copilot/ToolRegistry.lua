--[[
Title: ToolRegistry
Author(s): copilot,pbb
Date: 2026/03/18
Desc: Pure tool container with category-based organization.
Stores tool schemas, handlers, and categories. Zero business logic —
does not know about AISession, LLM, TTS, learning state, or NPLJS.

Shared by BackgroundAgent (registers tools) and ToolSandbox (executes tools for external agents).

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/ToolRegistry.lua");
local ToolRegistry = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.ToolRegistry");
local registry = ToolRegistry:new();
registry:RegisterTool("read_file", {description="...", parameters={...}}, handler, "file_io");
registry:ExecuteTool("read_file", {filePath="test.md"}, function(result, err) end);
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
local ToolRegistry = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.ToolRegistry"));

ToolRegistry:Signal("toolRegistered");
ToolRegistry:Signal("toolUnregistered");

function ToolRegistry:ctor()
    -- tools: name → { name, schema, handler, category }
    self.tools = {};
end

--[[
    Register a tool with category tag.
    @param name: string — unique tool identifier
    @param schema: table — { description, parameters }
    @param handler: function(params, callback) — tool implementation
    @param category: string (optional) — category tag, default "default"
]]
function ToolRegistry:RegisterTool(name, schema, handler, category)
    if not name or not schema or not handler then
        LOG.std(nil, "warn", "ToolRegistry", "RegisterTool: name, schema, and handler are required");
        return;
    end
    self.tools[name] = {
        name = name,
        schema = schema,
        handler = handler,
        category = category or "default",
    };
    LOG.std(nil, "debug", "ToolRegistry", "Registered tool: %s (category: %s)", name, category or "default");
    self:toolRegistered(name, schema, category or "default");
end

--[[
    Remove a tool by name.
    @param name: string
]]
function ToolRegistry:UnregisterTool(name)
    if self.tools[name] then
        LOG.std(nil, "debug", "ToolRegistry", "Unregistered tool: %s", name);
        self.tools[name] = nil;
        self:toolUnregistered(name);
    end
end

--[[
    Check if a tool exists.
    @param name: string
    @return boolean
]]
function ToolRegistry:HasTool(name)
    return self.tools[name] ~= nil;
end

--[[
    Execute a tool by name.
    @param name: string
    @param params: table
    @param callback: function(result, errMsg) — result is tool output, errMsg is nil on success
    @param services: ServiceProvider (optional) — injected as 3rd argument to handler
]]
function ToolRegistry:ExecuteTool(name, params, callback, services)
    local tool = self.tools[name];
    if not tool then
        if callback then
            callback(nil, string.format("Tool '%s' not found", name));
        end
        return;
    end
    tool.handler(params or {}, function(result)
        if callback then
            callback(result, nil);
        end
    end, services);
end

--[[
    Get the category of a specific tool.
    @param name: string
    @return string|nil
]]
function ToolRegistry:GetToolCategory(name)
    local tool = self.tools[name];
    return tool and tool.category or nil;
end

--[[
    Get tool names belonging to a category.
    @param category: string
    @return table — array of tool name strings
]]
function ToolRegistry:GetToolsByCategory(category)
    local result = {};
    for name, tool in pairs(self.tools) do
        if tool.category == category then
            table.insert(result, name);
        end
    end
    return result;
end

--[[
    Get all registered category names (deduplicated).
    @return table — array of category strings
]]
function ToolRegistry:GetCategories()
    local seen = {};
    local result = {};
    for _, tool in pairs(self.tools) do
        if not seen[tool.category] then
            seen[tool.category] = true;
            table.insert(result, tool.category);
        end
    end
    return result;
end

--[[
    Get tool definitions in OpenAI function calling format.
    @param categories: string[]|nil — if nil, returns all tools
    @return table — array of { type="function", function={name, description, parameters} }
]]
function ToolRegistry:GetAllToolDefinitions(categories)
    local categorySet = nil;
    if categories and #categories > 0 then
        categorySet = {};
        for _, cat in ipairs(categories) do
            categorySet[cat] = true;
        end
    end

    local definitions = {};
    for name, tool in pairs(self.tools) do
        if not categorySet or categorySet[tool.category] then
            table.insert(definitions, {
                type = "function",
                ["function"] = {
                    name = name,
                    description = tool.schema.description or "",
                    parameters = tool.schema.parameters or {
                        type = "object",
                        properties = {},
                        required = {},
                    },
                },
            });
        end
    end
    return definitions;
end
