--[[
Title: CopilotTools
Author(s): LiXizhi
Date: 2026/04/02
Desc: Copilot control tools — tool definitions and execution logic for copilot subagents.
Registers tools for listing, messaging, and executing actions on copilots.
Tool execution methods can also be called directly.

Registered tools:
  - list_copilots: List all available copilot subagents and their capabilities
  - send_message_to_copilot: Send a message or command to a specific copilot
  - (per-copilot dynamic tools are registered via RegisterCopilotInstanceTools)

Category: "copilot_control"

Usage:
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/CopilotTools.lua");
    local CopilotTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.CopilotTools");
    local tools = CopilotTools:new();
    tools:Init(copilotSkill);
    tools:RegisterTools(registry);
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotManager.lua");
local CopilotManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotManager");

local CopilotTools = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.CopilotTools"));

function CopilotTools:ctor()
    -- Reference to CopilotSkill for accessing discoveredCopilots
    self.copilotSkill = nil;
end

--[[
    Initialize with a CopilotSkill reference.
    @param copilotSkill: CopilotSkill instance (provides discoveredCopilots)
    @return self for chaining
]]
function CopilotTools:Init(copilotSkill)
    self.copilotSkill = copilotSkill;
    return self;
end

--[[
    Get the discovered copilots list from CopilotSkill.
    @return table - Array of copilot info
]]
function CopilotTools:GetDiscoveredCopilots()
    return self.copilotSkill and self.copilotSkill.discoveredCopilots or {};
end

--------------------------------------------------------------------------------
-- Tool Registration
--------------------------------------------------------------------------------

--[[
    Register static copilot control tools on a ToolRegistry.
    @param registry: ToolRegistry instance
]]
function CopilotTools:RegisterTools(registry)
    if not registry then return; end
    local self_ = self;

    -- Tool: List available copilots
    registry:RegisterTool("list_copilots", {
        description = "List all available copilot subagents and their capabilities",
        parameters = {
            type = "object",
            properties = {},
            required = {},
        },
    }, function(params, callback, services)
        local copilotList = {};
        for _, copilot in ipairs(self_:GetDiscoveredCopilots()) do
            table.insert(copilotList, {
                name = copilot.name,
                description = copilot.description,
                role = copilot.role,
                objective = copilot.objective,
                taskCount = #copilot.tasks,
                toolCount = #copilot.tools,
            });
        end
        callback({
            success = true,
            llm_result = string.format("Found %d copilots: %s", #copilotList, commonlib.serialize_compact(copilotList) or "[]"),
        });
    end, "copilot_control");

    -- Tool: Send message to copilot
    registry:RegisterTool("send_message_to_copilot", {
        description = "Send a message or command to a specific copilot subagent",
        parameters = {
            type = "object",
            properties = {
                copilot_name = {type = "string", description = "Name of the target copilot"},
                message = {type = "string", description = "Message or command to send"},
            },
            required = {"copilot_name", "message"},
        },
    }, function(params, callback, services)
        self_:ExecuteMessageToCopilot(params.copilot_name, params.message, callback);
    end, "copilot_control");
end

--[[
    Register per-copilot dynamic tools (from discovered capabilities) on a ToolRegistry.
    Called by CopilotSkill when a copilot is discovered or registered at runtime.
    @param registry: ToolRegistry instance
    @param copilotInfo: table - Copilot info from ExtractCopilotCapabilities
]]
function CopilotTools:RegisterCopilotInstanceTools(registry, copilotInfo)
    if not copilotInfo or not copilotInfo.tools or not registry then
        return;
    end
    local self_ = self;
    for _, tool in ipairs(copilotInfo.tools) do
        registry:RegisterTool(tool.name, {
            description = tool.description,
            parameters = tool.parameters,
        }, function(params, callback, services)
            self_:ExecuteCopilotTool(copilotInfo, tool, params, callback);
        end, "copilot_control");
    end
end

--------------------------------------------------------------------------------
-- Execution Methods
--------------------------------------------------------------------------------

--[[
    Execute a tool on a copilot.
    @param copilotInfo: table - The copilot info
    @param tool: table - The tool definition
    @param params: table - Tool parameters
    @param callback: function(result)
]]
function CopilotTools:ExecuteCopilotTool(copilotInfo, tool, params, callback)
    local copilot = copilotInfo.instance;
    if not copilot then
        if callback then
            callback({ success = false, llm_result = "Copilot instance not found" });
        end
        return;
    end

    local llm_result = string.format("Dispatched action '%s' to %s", tool.action or "unknown", copilotInfo.name);
    if copilot.HandleCommand then
        local cmdResult = copilot:HandleCommand(tool.action, params);
        if cmdResult then
            llm_result = llm_result .. ", result: " .. tostring(cmdResult);
        end
    end

    if callback then
        callback({ success = true, llm_result = llm_result });
    end
end

--[[
    Send a message to a specific copilot.
    @param copilotName: string - Name of the target copilot
    @param message: string - Message to send
    @param callback: function(result)
]]
function CopilotTools:ExecuteMessageToCopilot(copilotName, message, callback)
    local targetCopilot = nil;
    for _, copilot in ipairs(self:GetDiscoveredCopilots()) do
        if copilot.name == copilotName then
            targetCopilot = copilot;
            break;
        end
    end

    if not targetCopilot then
        if callback then
            callback({ success = false, llm_result = string.format("Copilot '%s' not found", copilotName) });
        end
        return;
    end

    local instance = targetCopilot.instance;
    if instance and instance.OnReceiveMessage then
        local result = instance:OnReceiveMessage(message, nil);
        if callback then
            callback({ success = true, llm_result = string.format("Message sent to %s, response: %s", copilotName, tostring(result)) });
        end
    elseif instance and instance.HandleCommand then
        local result = instance:HandleCommand("message", {text = message});
        if callback then
            callback({ success = true, llm_result = string.format("Command sent to %s, response: %s", copilotName, tostring(result)) });
        end
    else
        if callback then
            callback({ success = true, llm_result = string.format("Message delivered to %s (no response handler)", copilotName) });
        end
    end
end

--[[
    Execute Lua code to control a copilot subagent.
    @param copilotName: string - Name of the target copilot
    @param code: string - Lua code to execute
    @param callback: function(result)
]]
function CopilotTools:ExecuteCopilotCode(copilotName, code, callback)
    local manager = CopilotManager.GetInstance and CopilotManager.GetInstance();
    if not manager then
        if callback then
            callback({success = false, llm_result = "CopilotManager not found"});
        end
        LOG.std(nil, "warn", "CopilotTools", "CopilotManager not found");
        return;
    end
    manager:RunCodeForCopilot(copilotName, code, callback);
end
