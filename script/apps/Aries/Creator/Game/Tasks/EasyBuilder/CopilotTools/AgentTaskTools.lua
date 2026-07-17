--[[
Title: Agent Task Tools for BackgroundAgent
Author: Paracraft Assistant
Date: 2026/02/04
Desc: Extends BackgroundAgent with task management and copilot control tools.
      Building/Life skill task tools are already in EasyAIChatTools, this module adds:
      1. Task status query and control (pause/resume/stop)
      2. Direct copilot actions (say, walk)
      
UseLib:
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/AgentTaskTools.lua");
    local AgentTaskTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.AgentTaskTools");
    AgentTaskTools.RegisterToBackgroundAgent(agent);
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotManager.lua");
local CopilotManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");

local AgentTaskTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.AgentTaskTools");

-- Copilot class constants
AgentTaskTools.COPILOT_CLASSES = {
    dragon_pet = "MyCompany.Aries.Game.Tasks.CopilotDragonPet",
    land_keeper = "MyCompany.Aries.Game.Tasks.CopilotLandKeeper",
};

-- Tool definitions (task management & copilot control only)
local agentTaskTools = {
    ---------------------------
    -- Task Query & Control
    ---------------------------
    {
        name = "get_copilot_tasks",
        schema = {
            description = "Get status of all tasks for copilots. Returns task list with state and progress.",
            parameters = {
                type = "object",
                properties = {
                    copilot_name = {type = "string", description = "Optional: specific copilot name"}
                },
            }
        },
        handler = function(params, callback)
            local manager = CopilotManager.GetInstance();
            local results = {};
            
            for _, copilot in ipairs(manager.copilots or {}) do
                local entity = copilot:GetEntity();
                local copilotName = entity and entity:GetName() or "unknown";
                
                if not params.copilot_name or params.copilot_name == copilotName then
                    local tasks = copilot:GetAllTasks and copilot:GetAllTasks() or {};
                    local taskList = {};
                    
                    for _, task in ipairs(tasks) do
                        local inst = task.taskInstance;
                        table.insert(taskList, {
                            id = task.id,
                            name = task.name or (inst and inst:GetTaskName()) or "unknown",
                            state = inst and inst.state or "unknown",
                            progress = inst and inst.progress or 0,
                            enabled = task.enabled,
                        });
                    end
                    
                    local runningTask = copilot:GetRunningTask and copilot:GetRunningTask();
                    table.insert(results, {
                        copilotName = copilotName,
                        tasks = taskList,
                        runningTaskId = runningTask and runningTask.id,
                    });
                end
            end
            callback({success = true, llm_result = string.format("Found %d copilots with tasks: %s", #results, commonlib.serialize_compact(results) or "[]")});
        end
    },
    
    {
        name = "control_task",
        schema = {
            description = "Control a copilot task: pause, resume, or stop.",
            parameters = {
                type = "object",
                properties = {
                    action = {type = "string", enum = {"pause", "resume", "stop"}, description = "Action to perform"},
                    copilot_name = {type = "string", description = "Optional: copilot name"},
                    task_id = {type = "number", description = "Optional: task ID (uses running task if omitted)"}
                },
                required = {"action"}
            }
        },
        handler = function(params, callback)
            local copilot = CopilotManager.GetInstance():GetCopilot(params.copilot_name);
            if not copilot then callback({success = false, llm_result = "Copilot not found"}); return; end
            
            local task = params.task_id and copilot:GetTask(params.task_id) or copilot:GetRunningTask();
            local inst = task and task.taskInstance;
            if not inst then callback({success = false, llm_result = "Task not found"}); return; end
            
            if params.action == "pause" then inst:Pause();
            elseif params.action == "resume" then inst:Resume();
            elseif params.action == "stop" then inst:Stop(); end
            
            callback({success = true, llm_result = string.format("Task %s: %s, state=%s", params.action, task.id, inst.state)});
        end
    },
    
    ---------------------------
    -- Direct Copilot Actions
    ---------------------------
    {
        name = "copilot_say",
        schema = {
            description = "Make a copilot display text message.",
            parameters = {
                type = "object",
                properties = {
                    text = {type = "string", description = "Text to display"},
                    duration = {type = "number", description = "Duration in seconds (default 3)"},
                    copilot_name = {type = "string", description = "Optional: copilot name"}
                },
                required = {"text"}
            }
        },
        handler = function(params, callback)
            local manager = CopilotManager.GetInstance();
            local copilot = manager:GetCopilot(params.copilot_name) or 
                            manager:CreateCopilot(nil, AgentTaskTools.COPILOT_CLASSES.dragon_pet);
            
            if copilot and copilot.Say then
                copilot:Say(params.text, params.duration or 3);
                callback({success = true, llm_result = "Copilot said: " .. params.text});
            else
                callback({success = false, llm_result = "No copilot available"});
            end
        end
    },
    
    {
        name = "copilot_move",
        schema = {
            description = "Move copilot to a location or to the player.",
            parameters = {
                type = "object",
                properties = {
                    target = {type = "string", enum = {"player", "position"}, description = "'player' or 'position'"},
                    x = {type = "number"}, y = {type = "number"}, z = {type = "number"},
                    copilot_name = {type = "string"}
                },
                required = {"target"}
            }
        },
        handler = function(params, callback)
            local copilot = CopilotManager.GetInstance():GetCopilot(params.copilot_name);
            if not copilot then callback({success = false, llm_result = "Copilot not found"}); return; end
            
            local x, y, z;
            if params.target == "player" then
                local player = GameLogic.EntityManager.GetFocus();
                if player then x, y, z = player:GetBlockPos(); end
            else
                x, y, z = params.x, params.y, params.z;
            end
            
            if x and copilot.RunSimpleTask then
                copilot:RunSimpleTask(function(cop) cop:WalkTo(x, y, z); end, false, function()
                    callback({success = true, llm_result = string.format("Copilot moved to (%d,%d,%d)", x, y, z)});
                end);
            else
                callback({success = false, llm_result = "Invalid target"});
            end
        end
    },
};

-- Register tools to BackgroundAgent
function AgentTaskTools.RegisterToBackgroundAgent(agent)
    if not agent then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/BackgroundAgent.lua");
        agent = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BackgroundAgent"):GetInstance();
    end
    
    -- Register task management tools
    for _, toolDef in ipairs(agentTaskTools) do
        agent:RegisterTool(toolDef.name, toolDef.schema, toolDef.handler);
    end
    
    -- Register scheduler tools (building, life skills)
    AgentTaskTools.RegisterSchedulerToolsToAgent(agent);
    
    LOG.std(nil, "info", "AgentTaskTools", "Registered agent task tools");
end

-- Register EasyAIChatTools-style scheduler tools to BackgroundAgent
function AgentTaskTools.RegisterSchedulerToolsToAgent(agent)
    local manager = CopilotManager.GetInstance();
    local COPILOT = AgentTaskTools.COPILOT_CLASSES;
    
    -- Generic task scheduler
    agent:RegisterTool("schedule_task", {
        description = "Schedule any copilot task by class name.",
        parameters = {
            type = "object",
            properties = {
                taskType = {type = "string", description = "Task class (e.g., 'BuildBlockTemplate', 'Planting')"},
                params = {type = "object", description = "Task parameters"},
                copilotClass = {type = "string"},
                priority = {type = "string", enum = {"high", "normal", "low"}}
            },
            required = {"taskType"}
        }
    }, function(params, callback)
        local taskType = params.taskType;
        if not string.find(taskType, "MyCompany") then
            taskType = "MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot." .. taskType;
        end
        manager:ScheduleTask(taskType, params.params or {}, {
            copilotClass = params.copilotClass, priority = params.priority or "normal"
        }, function(result) callback({success = result ~= false, llm_result = "Task scheduled: " .. (params.taskType or "unknown")}); end);
    end);
    
    -- Building task shortcut
    agent:RegisterTool("start_building", {
        description = "Start building task with DragonPet. Provide template or description.",
        parameters = {
            type = "object",
            properties = {
                template = {type = "string", description = "Template file path"},
                description = {type = "string", description = "What to build (if no template)"},
                buildSpeed = {type = "number"}, buildMode = {type = "string", enum = {"standalone", "guide"}}
            }
        }
    }, function(params, callback)
        local taskType = params.template and params.template ~= "" 
            and "MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BuildBlockTemplate"
            or "MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BuildSomething";
        local taskParams = params.template and {filename = params.template, buildSpeed = params.buildSpeed, buildMode = params.buildMode}
            or {description = params.description, buildMode = params.buildMode};
        
        manager:ScheduleTask(taskType, taskParams, {copilotClass = COPILOT.dragon_pet, priority = "high"}, 
            function(result) callback({success = result ~= false, llm_result = "Building task started"}); end);
    end);
    
    -- Life skill task shortcut
    agent:RegisterTool("start_life_task", {
        description = "Start life skill task (planting, fishing, cooking) with LandKeeper.",
        parameters = {
            type = "object",
            properties = {
                activity = {type = "string", enum = {"planting", "fishing", "cooking"}},
                target_id = {type = "number", description = "Optional: seed/fish/recipe ID"}
            },
            required = {"activity"}
        }
    }, function(params, callback)
        local map = {
            planting = {class = "Planting", param = "plant_id"},
            fishing = {class = "CatchFishing", param = "fish_id"},
            cooking = {class = "Cooking", param = "recipe_id"},
        };
        local info = map[params.activity];
        if not info then callback({success = false, llm_result = "Unknown activity: " .. tostring(params.activity)}); return; end
        
        local taskParams = params.target_id and {[info.param] = params.target_id} or {};
        manager:ScheduleTask("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot." .. info.class, taskParams,
            {copilotClass = COPILOT.land_keeper, priority = "normal"},
            function(result) callback({success = result ~= false, llm_result = "Life task started: " .. params.activity}); end);
    end);
end

return AgentTaskTools;
