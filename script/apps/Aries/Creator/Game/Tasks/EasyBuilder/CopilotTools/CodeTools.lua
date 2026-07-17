--[[
Title: CodeTools
Author(s): copilot
Date: 2026/04/02
Desc: Code execution tools — fully self-contained, decoupled from BackgroundAgent.
Registers tools and provides direct execution methods for running code in various environments:
  - run_paracraft_copilot_code: Execute Lua code to control a copilot subagent
  - run_npl_codeblock_code: Execute NPL blockly code in code block environment
  - run_npl_code: Execute NPL code in global environment

All execution methods can be called directly without ServiceProvider:
    local codeTools = CodeTools:new();
    codeTools:ExecuteGlobalCode(code, callback);
    codeTools:ExecuteTerminalCode(code, callback);
    codeTools:ExecuteCopilotCode(copilotName, code, callback);

Category: "run_code" (and "copilot_control" for copilot code)

Usage:
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/CodeTools.lua");
    local CodeTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.CodeTools");
    local tools = CodeTools:new();
    tools:RegisterTools(registry);
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotManager.lua");
local CopilotManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");

local CodeTools = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.CodeTools"));

function CodeTools:ctor()
end

--------------------------------------------------------------------------------
-- Execution Methods (can be called directly without ServiceProvider)
--------------------------------------------------------------------------------

--[[
    Execute NPL code in global environment.
    @param codeStr: string - NPL code to execute
    @param callback: function(result) - Called with {success, llm_result}
]]
function CodeTools:ExecuteGlobalCode(codeStr, callback)
    local codeFunc, errmsg = loadstring(codeStr, "code_tools_global");
    if codeFunc then
        setfenv(codeFunc, _G);
        local ok, result = pcall(codeFunc);
        if not ok then
            if callback then
                callback({success = false, llm_result = tostring(result)});
            end
            LOG.std(nil, "error", "CodeTools", "failed to run code: %s", tostring(result));
        else
            if callback then
                callback({success = true, llm_result = result or "Code executed successfully"});
            end
        end
    else
        LOG.std(nil, "error", "CodeTools", "failed to load code: %s", errmsg);
        if callback then
            callback({success = false, llm_result = errmsg});
        end
    end
end

--[[
    Execute NPL blockly code in code block environment (via GameLogic CodeGlobal).
    @param code: string - NPL blockly code to execute
    @param callback: function(result) - Called with {success, llm_result}
]]
function CodeTools:ExecuteTerminalCode(code, callback)
    local codeGlobal = GameLogic and GameLogic.GetCodeGlobal and GameLogic.GetCodeGlobal();
    if not codeGlobal then
        if callback then
            callback({success = false, llm_result = "CodeGlobal not available"});
        end
        return;
    end
    codeGlobal:RunAsCodeBlock(code, nil, nil, function(result, r2, r3, r4)
        if callback then
            callback({success = true, llm_result = tostring(result or "Code executed")});
        end
    end);
end

--[[
    Execute Lua code to control a copilot subagent.
    The code runs in a coroutine context with access to copilot methods.
    @param copilotName: string - Name of the target copilot
    @param code: string - Lua code to execute
    @param callback: function(result) - Called with {success, llm_result}
]]
function CodeTools:ExecuteCopilotCode(copilotName, code, callback)
    local manager = CopilotManager.GetInstance and CopilotManager.GetInstance();
    if not manager then
        if callback then
            callback({success = false, llm_result = "CopilotManager not found"});
        end
        LOG.std(nil, "warn", "CodeTools", "CopilotManager not found");
        return;
    end
    manager:RunCodeForCopilot(copilotName, code, callback);
end

--------------------------------------------------------------------------------
-- Tool Registration
--------------------------------------------------------------------------------

--[[
    Register all code execution tools on a ToolRegistry.
    @param registry: ToolRegistry instance
    @param category: string (optional) - Override default category for run_code tools
]]
function CodeTools:RegisterTools(registry, category)
    if not registry then return; end
    local self_ = self;

    -- Tool: Run copilot code (control subagent actions)
    registry:RegisterTool("run_paracraft_copilot_code", {
        description = "Execute Lua code to control a copilot subagent. The code runs in a coroutine context with access to copilot methods like Say(), WalkTo(), Wait(), etc.",
        parameters = {
            type = "object",
            properties = {
                copilotName = {
                    type = "string",
                    description = "Name of the target copilot to control",
                },
                code = {
                    type = "string",
                    description = "Lua code to execute. Available functions: Say(text, duration), WalkTo(x,y,z), Wait(seconds), PlayAnimation(name)",
                },
            },
            required = {"copilotName", "code"},
        },
    }, function(params, callback)
        self_:ExecuteCopilotCode(params.copilotName, params.code, callback);
    end, "copilot_control");

    -- Tool: Execute NPL blockly code in code block environment
    registry:RegisterTool("run_npl_codeblock_code", {
        description = "Excute npl blockly code in code block environment.",
        parameters = {
            type = "object",
            properties = {
                code = {
                    type = "string",
                    description = "Npl blockly code to execute.",
                },
            },
            required = {"code"},
        },
    }, function(params, callback)
        self_:ExecuteTerminalCode(params.code, callback);
    end, category or "run_code");

    -- Tool: Execute NPL code in global environment
    registry:RegisterTool("run_npl_code", {
        description = "Excute npl code in global environment.",
        parameters = {
            type = "object",
            properties = {
                code = {
                    type = "string",
                    description = "Npl code to execute.",
                },
            },
            required = {"code"},
        },
    }, function(params, callback)
        self_:ExecuteGlobalCode(params.code, callback);
    end, category or "run_code");
end

return CodeTools;
