--[[
Title: EasyAIChat Tools Registration (Facade)
Author: Paracraft Assistant
Date: 2025/01/12
Desc: Facade that delegates to MQTTTools, PersonalPageTools, and SchedulerTools.
      All tools use the ToolRegistry pattern internally.

Usage:
  -- ToolRegistry pattern (preferred):
  EasyAIChatTools:new():RegisterTools(registry)

  -- AIChat instance pattern (backward compat, uses ToolRegistry internally):
  EasyAIChatTools.RegisterMQTTTools(aiChatInstance)
  EasyAIChatTools.RegisterPersonalPageTools(aiChatInstance)
  EasyAIChatTools.RegisterSchedulerTools(aiChatInstance)

uselib:
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/EasyAIChatTools.lua");
    local EasyAIChatTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.EasyAIChatTools");
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/MQTTTools.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/PersonalPageTools.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/SchedulerTools.lua");
local MQTTTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.MQTTTools");
local PersonalPageTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.PersonalPageTools");
local SchedulerTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.SchedulerTools");

local EasyAIChatTools = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.EasyAIChatTools"));

function EasyAIChatTools:ctor()
end

--------------------------------------------------------------------------------
-- ToolRegistry-based registration (delegates to all three tool classes)
--------------------------------------------------------------------------------

function EasyAIChatTools:RegisterTools(registry)
    if not registry then return; end
    MQTTTools:new():RegisterTools(registry);
    PersonalPageTools:new():RegisterTools(registry);
    SchedulerTools:new():RegisterTools(registry);
end

--------------------------------------------------------------------------------
-- Helper: bridge ToolRegistry tools to an AIChat instance.
-- Creates a temporary ToolRegistry, registers specified tools, then syncs
-- definitions and callbacks to the AIChat instance (same pattern as
-- BackgroundAgent:OnToolRegistered).
-- @param aiChatInstance: AIChat — target AIChat object
-- @param registerFunc: function(registry) — called to populate the registry
--------------------------------------------------------------------------------
local function ApplyToolsToAIChat(aiChatInstance, registerFunc)
    if not aiChatInstance then return; end

    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/ToolRegistry.lua");
    local ToolRegistry = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.ToolRegistry");

    local registry = ToolRegistry:new();
    registerFunc(registry);

    -- Merge tool definitions into AIChat
    local currentTools = aiChatInstance.tools or {};
    local newDefs = registry:GetAllToolDefinitions();
    for _, toolDef in ipairs(newDefs) do
        local name = toolDef["function"].name;
        local bFound = false;
        for _, existing in ipairs(currentTools) do
            if existing["function"] and existing["function"].name == name then
                bFound = true;
                break;
            end
        end
        if not bFound then
            table.insert(currentTools, toolDef);
        end

        -- Register callback: delegates to ToolRegistry:ExecuteTool and unwraps llm_result
        if not aiChatInstance.tool_callbacks[name] then
            aiChatInstance:RegisterToolCallback(name, function(args, asyncCallback)
                registry:ExecuteTool(name, args, function(result)
                    local llmResult;
                    if type(result) == "table" and result.llm_result then
                        llmResult = result.llm_result;
                    elseif result ~= nil then
                        llmResult = tostring(result);
                    else
                        llmResult = "done";
                    end
                    if asyncCallback and type(asyncCallback) == "function" then
                        asyncCallback(llmResult);
                    end
                end);
            end);
        end
    end
    aiChatInstance:SetTools(currentTools);
end

--------------------------------------------------------------------------------
-- AIChat instance-based registration (backward compat via ToolRegistry)
--------------------------------------------------------------------------------

function EasyAIChatTools.RegisterMQTTTools(aiChatInstance)
    ApplyToolsToAIChat(aiChatInstance, function(registry)
        MQTTTools:new():RegisterTools(registry);
    end);
end

function EasyAIChatTools.RegisterPersonalPageTools(aiChatInstance)
    ApplyToolsToAIChat(aiChatInstance, function(registry)
        PersonalPageTools:new():RegisterTools(registry);
    end);
end

function EasyAIChatTools.RegisterSchedulerTools(aiChatInstance)
    ApplyToolsToAIChat(aiChatInstance, function(registry)
        SchedulerTools:new():RegisterTools(registry);
    end);
end

--------------------------------------------------------------------------------
-- Convenience helpers (backward compat)
--------------------------------------------------------------------------------

function EasyAIChatTools.GetPersonalStore()
    return PersonalPageTools.GetPersonalStore();
end


return EasyAIChatTools;
