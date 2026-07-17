--[[
Title: AgentTools
Author(s): copilot
Date: 2026/04/02
Desc: Agent orchestration tools — fully self-contained, decoupled from BackgroundAgent.
Registers tools for child agent delegation and parent context retrieval:
  - runAsyncAgentTask: Delegate a task to a named child agent (local or remote)
  - getParentAgentContext: Get shared context from the parent agent session

The tool handlers use ServiceProvider to access:
  - "agent_router": AgentRouter instance for remote agent routing
  - "code_executor": object with EnqueueChildAgentTask and aiSession for local child agents

Category: "agent"

Usage:
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/AgentTools.lua");
    local AgentTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.AgentTools");
    local tools = AgentTools:new();
    tools:RegisterTools(registry);
]]

local AgentTools = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.AgentTools"));

function AgentTools:ctor()
end

--[[
    Register all agent tools on a ToolRegistry.
    @param registry: ToolRegistry instance
]]
function AgentTools:RegisterTools(registry)
    if not registry then return; end

    -- Tool: runAsyncAgentTask
    registry:RegisterTool("runAsyncAgentTask", {
        description = "Delegate a task to a named child agent that runs in parallel. "
            .. "The child agent is an independent AI session with its own conversation and tool access. "
            .. "The task runs asynchronously — this tool returns immediately after submission. "
            .. "When the child finishes, its result will be delivered back as a message in your conversation. "
            .. "At most 2 child agents can exist. Multiple tasks sent to the same agent will be queued or merged automatically.",
        parameters = {
            type = "object",
            properties = {
                prompt = {
                    type = "string",
                    description = "A detailed description of the task for the agent to perform.",
                },
                description = {
                    type = "string",
                    description = "A short (3-5 word) description of the task.",
                },
                agentName = {
                    type = "string",
                    description = "Optional name of a specific agent to invoke. If not provided, uses a default name.",
                },
                tools = {
                    type = "array",
                    items = { type = "string" },
                    description = "Tool category names available to the child agent (e.g. ['web', 'fileOps', 'execute']). If omitted, inherits all tools from the parent agent.",
                },
                maxIterations = {
                    type = "number",
                    description = "Maximum number of tool-call iterations for the child agent. Default is 10.",
                },
                systemPrompt = {
                    type = "string",
                    description = "Optional custom system prompt for the child agent. If omitted, a default prompt is used.",
                },
                model = {
                    type = "string",
                    description = "Override the model for the sub-agent (e.g. 'keepwork-pro', 'keepwork-flash'). If omitted, inherits from the parent session.",
                },
                callbackMode = {
                    type = "string",
                    enum = {"immediate", "delay", "debounce"},
                    description = "How to deliver the child agent's result back to the parent. "
                        .. "'immediate': send result to parent as a message immediately when finished. "
                        .. "'delay' (default): silently queue result, delivered as a message on the parent's next request. "
                        .. "'debounce': wait debounceSeconds before sending; if parent sends within that time, behaves as delay.",
                },
                debounceSeconds = {
                    type = "number",
                    description = "Seconds to wait in debounce mode before sending result to parent. Default is 5. Only used when callbackMode is 'debounce'.",
                },
            },
            required = {"prompt", "description"},
        },
    }, function(params, callback, services)
        AgentTools.ExecuteRunAsyncAgentTask(params, callback, services);
    end, "agent");

    -- Tool: getParentAgentContext
    registry:RegisterTool("getParentAgentContext", {
        description = "Get shared context from the parent agent session. "
            .. "Use this when you are a child agent and need more context about the parent's conversation, system prompt, or workspace.",
        parameters = {
            type = "object",
            properties = {
                messageCount = {
                    type = "number",
                    description = "Number of recent parent messages to include. Default is 10.",
                },
            },
        },
    }, function(params, callback, services)
        AgentTools.ExecuteGetParentAgentContext(params, callback, services);
    end, "agent");
end

--------------------------------------------------------------------------------
-- Execution Methods
--------------------------------------------------------------------------------

--[[
    Execute runAsyncAgentTask: delegate task to a child agent (remote or local).
    @param params: table - Tool parameters
    @param callback: function(result)
    @param services: ServiceProvider
]]
function AgentTools.ExecuteRunAsyncAgentTask(params, callback, services)
    local prompt = params.prompt;
    if not prompt or prompt == "" then
        callback({ success = false, error = "'prompt' is a required parameter." });
        return;
    end
    local agentName = params.agentName or "child_agent";

    -- Check if target agent is remote via AgentRouter
    local router = services and services:Get("agent_router");
    if router and router.hasRemoteAgent and router:hasRemoteAgent(agentName) then
        LOG.std(nil, "info", "AgentTools", "runAsyncAgentTask routing '%s' via AgentRouter (remote)", agentName);
        router:submitTask(agentName, {
            prompt = prompt,
            description = params.description,
            tools = params.tools,
            maxIterations = params.maxIterations or 10,
            systemPrompt = params.systemPrompt,
            model = params.model,
        }, function(result, err)
            if err then
                callback({ success = false, error = string.format("Remote agent '%s' error: %s", agentName, tostring(err)) });
            else
                callback({
                    success = true,
                    llm_result = tostring(result),
                });
            end
        end, function(streamType, content)
            LOG.std(nil, "info", "AgentTools", "runAsyncAgentTask remote stream from '%s': %s: %s",
                agentName, tostring(streamType), tostring(content):sub(1, 100));
        end);
        return;
    end

    -- Local child agent: delegate to code_executor's EnqueueChildAgentTask
    local executor = services and services:Get("code_executor");
    if not executor then
        callback({ success = false, error = "Code executor service unavailable" });
        return;
    end
    executor:EnqueueChildAgentTask(agentName, prompt, {
        description = params.description,
        enableTools = params.tools,
        maxIterations = params.maxIterations or 10,
        systemPrompt = params.systemPrompt,
        model = params.model,
        callbackMode = params.callbackMode or "delay",
        debounceSeconds = params.debounceSeconds or 5,
    });
    callback({
        success = true,
        llm_result = string.format("Task submitted to agent '%s'. The agent is working on it in the background. Results will be delivered as a message when complete.", agentName),
    });
end

--[[
    Execute getParentAgentContext: retrieve parent agent session context.
    @param params: table - Tool parameters
    @param callback: function(result)
    @param services: ServiceProvider
]]
function AgentTools.ExecuteGetParentAgentContext(params, callback, services)
    local executor = services and services:Get("code_executor");
    if not executor then
        callback({ success = false, error = "No AI session available." });
        return;
    end
    local context = executor:GetParentContext(params.messageCount or 10);
    if not context then
        callback({
            success = true,
            llm_result = "No parent session found. This agent is the root session.",
        });
        return;
    end
    local contextStr = commonlib.Json.Encode(context) or "{}";
    callback({
        success = true,
        llm_result = contextStr,
    });
end
