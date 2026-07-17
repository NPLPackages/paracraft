--[[
Title: Scheduler Chat Tools
Author: Paracraft Assistant
Date: 2025/01/12
Desc: Registers Scheduler tools for AI chat (schedule_task, start_building_task, start_life_task)
      via ToolRegistry pattern.

uselib:
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/SchedulerTools.lua");
    local SchedulerTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.SchedulerTools");
    SchedulerTools:new():RegisterTools(registry);
]]

local SchedulerTools = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.SchedulerTools"));

function SchedulerTools:ctor()
end

function SchedulerTools:RegisterTools(registry)
    if not registry then return; end

    registry:RegisterTool("schedule_task", {
        description = "调度一个任务给 Copilot 执行。可以指定任务类型、参数和优先级。",
        parameters = {
            type = "object",
            properties = {
                taskType = {type = "string", description = "任务类型或类名"},
                params = {type = "object", description = "任务的初始化参数"},
                copilotName = {type = "string", description = "可选：指定执行任务的 Copilot 名称"},
                copilotClass = {type = "string", description = "可选：指定创建 Copilot 的类名"},
                priority = {type = "string", description = "任务优先级：'high', 'normal', 'low'"},
            },
            required = {"taskType"},
        },
    }, function(params, callback, services)
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotManager.lua");
        local CopilotManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotManager");
        CopilotManager.GetInstance():ScheduleTask(
            params.taskType, params.params,
            {copilotName = params.copilotName, priority = params.priority, copilotClass = params.copilotClass},
            function(result)
                if type(result) == "boolean" then
                    callback({success = result, llm_result = result and "Task completed successfully." or "Task failed or stopped."});
                else
                    callback({success = true, llm_result = "Task result: " .. commonlib.serialize_compact(result)});
                end
            end
        );
    end, "scheduler");

    registry:RegisterTool("start_building_task", {
        description = "让抱抱龙(DragonPet)协助建造。可以指定模板或描述。",
        parameters = {
            type = "object",
            properties = {
                template_url = {type = "string", description = "可选：方块模板文件的路径或 URL"},
                description = {type = "string", description = "可选：建造任务的描述"},
            },
        },
    }, function(params, callback, services)
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotManager.lua");
        local CopilotManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotManager");
        local taskType = "MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BuildSomething";
        local taskParams = {welcomeMessage = L("准备开始建造！")};
        if params.template_url and params.template_url ~= "" then
            taskType = "MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BuildBlockTemplate";
            taskParams = {filename = params.template_url};
        elseif params.description then
            taskParams.description = params.description;
        end
        CopilotManager.GetInstance():ScheduleTask(
            taskType, taskParams,
            {copilotClass = "MyCompany.Aries.Game.Tasks.CopilotDragonPet", priority = "high"},
            function(result)
                callback({success = result and true or false, llm_result = result and "Building task completed." or "Building task failed."});
            end
        );
    end, "scheduler");

    registry:RegisterTool("start_life_task", {
        description = "让土地管理员(LandKeeper)协助进行生活技能任务（种植、钓鱼、烹饪）。",
        parameters = {
            type = "object",
            properties = {
                activity = {type = "string", enum = {"planting", "fishing", "cooking"}, description = "活动类型"},
                target_id = {type = "number", description = "可选：目标物品ID"},
            },
            required = {"activity"},
        },
    }, function(params, callback, services)
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotManager.lua");
        local CopilotManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotManager");
        local taskType, taskParams = "", {};
        if params.activity == "planting" then
            taskType = "MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.Planting";
            taskParams.plant_id = params.target_id;
        elseif params.activity == "fishing" then
            taskType = "MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CatchFishing";
            taskParams.fish_id = params.target_id;
        elseif params.activity == "cooking" then
            taskType = "MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.Cooking";
            taskParams.recipe_id = params.target_id;
        else
            callback({success = false, llm_result = "Unknown activity type."});
            return;
        end
        CopilotManager.GetInstance():ScheduleTask(
            taskType, taskParams,
            {copilotClass = "MyCompany.Aries.Game.Tasks.CopilotLandKeeper", priority = "normal"},
            function(result)
                callback({success = result and true or false, llm_result = result and "Life task completed." or "Life task failed."});
            end
        );
    end, "scheduler");
end

return SchedulerTools;
