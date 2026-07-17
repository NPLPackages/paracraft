--[[
Title: EasyAIChat Tools Registration
Author: Paracraft Assistant
Date: 2025/01/12
Desc: Registers tools for EasyAIChat
uselib:
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/EasyAIChatTools.lua");
    local EasyAIChatTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.EasyAIChatTools");
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/MQTTTools.lua");
local MQTTTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.MQTTTools")

local EasyAIChatTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.EasyAIChatTools");

-- MQTT Tool Definitions
local mqtt_tools = {
    {
        type = "function",
        ["function"] = {
            name = "mqtt_publish",
            description = "通过MQTT协议发送控制指令或数据。",
            parameters = {
                type = "object",
                properties = {
                    topic = {type = "string", description = "目标主题"},
                    message = {type = "string", description = "消息内容"},
                },
                required = {"topic", "message"},
            },
        }
    },
    {
        type = "function",
        ["function"] = {
            name = "mqtt_get",
            description = "获取MQTT变量的值。",
            parameters = {
                type = "object",
                properties = {
                    topic = {type = "string", description = "变量主题"},
                    timeout = {type = "number", description = "超时时间(ms)，默认5000"},
                },
                required = {"topic"},
            },
        }
    },
    {
        type = "function",
        ["function"] = {
            name = "mqtt_subscribe",
            description = "订阅MQTT主题。",
            parameters = {
                type = "object",
                properties = {
                    topic = {type = "string", description = "主题"},
                },
                required = {"topic"},
            },
        }
    },
};

-- Register Tools to an AIChat instance
function EasyAIChatTools.RegisterMQTTTools(aiChatInstance)
    if not aiChatInstance then return end
    
    local currentTools = aiChatInstance.tools or {};
    for _, tool in ipairs(mqtt_tools) do
        local bFound = false;
        for _, existing in ipairs(currentTools) do
            if(existing["function"] and existing["function"].name == tool["function"].name) then
                bFound = true;
                break;
            end
        end
        if(not bFound) then
            table.insert(currentTools, tool);
        end
    end
    aiChatInstance:SetTools(currentTools);
    -- Register Callbacks
    if(not aiChatInstance.tool_callbacks["mqtt_publish"]) then
        aiChatInstance:RegisterToolCallback("mqtt_publish", function(args)
            local success, err = MQTTTools.GetInstance():Publish(args.topic, args.message);
            if success then
                return "Published to " .. args.topic;
            else
                if err == "Not connected" then
                    return "MQTT未连接。请先让用户在数字人配置面板的'工具'页面配置MQTT连接参数，或使用配置界面连接MQTT服务器。";
                end
                return "Failed: " .. (err or "Unknown error");
            end
        end);
    end
    
    if(not aiChatInstance.tool_callbacks["mqtt_subscribe"]) then
        aiChatInstance:RegisterToolCallback("mqtt_subscribe", function(args)
            local success, err = MQTTTools.GetInstance():Subscribe(args.topic);
            if success then
                return "Subscribed to " .. args.topic;
            else
                if err == "Not connected" then
                    return "MQTT未连接。请先让用户在数字人配置面板的'工具'页面配置MQTT连接参数，或使用配置界面连接MQTT服务器。";
                end
                return "Failed: " .. (err or "Unknown error");
            end
        end);
    end
    
    -- Async Get
    if(not aiChatInstance.tool_callbacks["mqtt_get"]) then
        aiChatInstance:RegisterToolCallback("mqtt_get", function(args, callback)
            MQTTTools.GetInstance():Get(args.topic, args.timeout, function(result, err)
                if result then
                    callback(result);
                else
                    if err == "Not connected" then
                        callback("MQTT未连接。请先让用户在数字人配置面板的'工具'页面配置MQTT连接参数，或使用配置界面连接MQTT服务器。");
                    else
                        callback("Failed: " .. (err or "Timeout"));
                    end
                end
            end);
        end);
    end
end

function EasyAIChatTools.ConfigMqtt(callback)
    MQTTTools.GetInstance():ShowConfigPage(callback);
end


local personal_page_tools = {
    {
        type = "function",
        ["function"] = {
            name = "personal_page_load",
            description = "加载个人页面数据。用于获取用户的持久化数据。当用户询问“是什么”、“有没有”、“查一下”某项信息时使用。",
            parameters = {
                type = "object",
                properties = {
                    pageName = {
                        type = "string",
                        description = "数据的逻辑分类名称（Category），用于区分不同模块的数据，例如 'farm_config', 'user_status'。如果不确定分类，可以不传，将检索所有数据。然后根据key来筛选数据。"
                    },
                    key = {
                        type = "string",
                        description = "分类下的具体属性名（Property）。例如 'level', 'money'。如果不传，则获取Root结构下的所有数据，从所有数据中筛选出和用户描述相关的数据。"
                    }
                },
                required = {}
            }
        }
    },
    {
        type = "function",
        ["function"] = {
            name = "personal_page_save",
            description = "保存个人页面数据。用于“记住”、“设置”或“更新”用户信息（持久化存储）。\n" ..
                         "**数据结构**：`[Root] -> [Category (pageName)] -> [Property (key)]`。\n" ..
                         "**使用说明**：\n" ..
                         "1. **逻辑分类（必须）**：必须使用 `pageName` 对数据进行分类（如 `farm_config`）。\n" ..
                         "   - *注意*：`pageName` 是逻辑分类名，不是文件名。\n" ..
                         "2. **保存模式**：\n" ..
                         "   - **单属性模式**：传入 `key` 和 `data`（设置单个属性）。\n" ..
                         "     例：`pageName='farm_config', key='name', data='MyFarm'`\n" ..
                         "   - **全分类模式**：不传 `key`，`data` 为包含多个属性的对象（初始化/更新整个分类）。\n" ..
                         "     例：`pageName='quest_log', data={task1: 'done', task2: 'doing'}`\n" ..
                         "3. **先查后改**：如果不确定当前数据状态，建议先调用 load 工具查询。\n" ..
                         "**命名规范**：`pageName` 和 `key` 请使用 snake_case（如 `user_status`）。",
            parameters = {
                type = "object",
                properties = {
                    pageName = {
                        type = "string",
                        description = "数据的逻辑分类名称（Category），例如 'farm_config', 'user_status'。"
                    },
                    key = {
                        type = "string",
                        description = "分类下的具体属性名（Property）。例如 'level', 'money'。如果保存的是整个分类的数据对象（data包含多个属性），则不要传 key。"
                    },
                    data = {
                        type = "object",
                        description = "要保存的具体内容（可以是数字、字符串或 JSON 对象）。"
                    },
                    bForceFlush = {
                        type = "boolean",
                        description = "是否强制写入磁盘。默认为 true。"
                    }
                },
                required = {"pageName", "data"}
            }
        }
    }
};

function EasyAIChatTools.GetPersonalStore()
    if not EasyAIChatTools.personalStore then
        NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/PersonalPageStore.lua");
        local PersonalPageStore = commonlib.gettable("MyCompany.Aries.Creator.Game.KeepWork.PersonalPageStore");
        EasyAIChatTools.personalStore = PersonalPageStore
    end
    return EasyAIChatTools.personalStore
end

function EasyAIChatTools.RegisterPersonalPageTools(aiChatInstance)
    if not aiChatInstance then return end
    
    local currentTools = aiChatInstance.tools or {};
    for _, tool in ipairs(personal_page_tools) do
        local bFound = false;
        for _, existing in ipairs(currentTools) do
            if(existing["function"] and existing["function"].name == tool["function"].name) then
                bFound = true;
                break;
            end
        end
        if(not bFound) then
            table.insert(currentTools, tool);
        end
    end
    aiChatInstance:SetTools(currentTools);

    -- Register Callbacks
    if(not aiChatInstance.tool_callbacks["personal_page_load"]) then
        aiChatInstance:RegisterToolCallback("personal_page_load", function(args, callback)
            local pageName = args.pageName
            local key = args.key
            
            EasyAIChatTools.GetPersonalStore():LoadPageData(pageName, key, function(data)
                if callback then
                    callback(commonlib.Json.Encode(data))
                end
            end)
        end);
    end

    if(not aiChatInstance.tool_callbacks["personal_page_save"]) then
        aiChatInstance:RegisterToolCallback("personal_page_save", function(args, callback)
            local pageName = args.pageName
            local key = args.key
            local data = args.data
            local bForceFlush = args.bForceFlush
            if bForceFlush == nil then bForceFlush = true end
            
            EasyAIChatTools.GetPersonalStore():SavePageData(pageName, key, data, bForceFlush)
            
            if callback then
                callback("Data saved successfully.")
            else
                return "Data saved successfully."
            end
        end);
    end
end

local scheduler_tools = {
    {
        type = "function",
        ["function"] = {
            name = "schedule_task",
            description = "调度一个任务给 Copilot 执行。可以指定任务类型、参数和优先级。",
            parameters = {
                type = "object",
                properties = {
                    taskType = {
                        type = "string",
                        description = "任务类型或类名，例如 'PersonalPageTutorial', 'BuildBlockTemplate'。"
                    },
                    params = {
                        type = "object",
                        description = "任务的初始化参数。"
                    },
                    copilotName = {
                        type = "string",
                        description = "可选：指定执行任务的 Copilot 名称。"
                    },
                    copilotClass = {
                        type = "string",
                        description = "可选：指定创建 Copilot 的类名。"
                    },
                    priority = {
                        type = "string",
                        description = "任务优先级，例如 'high', 'normal', 'low'。高优先级可能会触发强制准备逻辑。"
                    }
                },
                required = {"taskType"}
            }
        }
    },
    {
        type = "function",
        ["function"] = {
            name = "start_building_task",
            description = "让抱抱龙(DragonPet)协助建造。可以指定模板或描述。",
            parameters = {
                type = "object",
                properties = {
                    template_url = {
                        type = "string",
                        description = "可选：方块模板文件的路径或 URL。"
                    },
                    description = {
                        type = "string",
                        description = "可选：建造任务的描述，如果没有模板，将尝试根据描述生成或寻找。"
                    }
                }
            }
        }
    },
    {
        type = "function",
        ["function"] = {
            name = "start_life_task",
            description = "让土地管理员(LandKeeper)协助进行生活技能任务（种植、钓鱼、烹饪）。",
            parameters = {
                type = "object",
                properties = {
                    activity = {
                        type = "string",
                        enum = {"planting", "fishing", "cooking"},
                        description = "活动类型：planting(种植), fishing(钓鱼), cooking(烹饪)。"
                    },
                    target_id = {
                        type = "number",
                        description = "可选：目标物品ID（如种子ID、鱼ID、食谱ID）。"
                    }
                },
                required = {"activity"}
            }
        }
    }
};

function EasyAIChatTools.RegisterSchedulerTools(aiChatInstance)
    if not aiChatInstance then return end
    
    local currentTools = aiChatInstance.tools or {};
    for _, tool in ipairs(scheduler_tools) do
        local bFound = false;
        for _, existing in ipairs(currentTools) do
            if(existing["function"] and existing["function"].name == tool["function"].name) then
                bFound = true;
                break;
            end
        end
        if(not bFound) then
            table.insert(currentTools, tool);
        end
    end
    aiChatInstance:SetTools(currentTools);

    -- Register schedule_task
    if(not aiChatInstance.tool_callbacks["schedule_task"]) then
        aiChatInstance:RegisterToolCallback("schedule_task", function(args, callback)
            NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotManager.lua");
            local CopilotManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotManager");
            
            CopilotManager.GetInstance():ScheduleTask(
                args.taskType, 
                args.params, 
                { copilotName = args.copilotName, priority = args.priority, copilotClass = args.copilotClass },
                function(result)
                     if callback then
                        if type(result) == "boolean" then
                            callback(result and "Task completed successfully." or "Task failed or stopped.");
                        else
                            callback("Task result: " .. commonlib.serialize_compact(result));
                        end
                     end
                end
            );
            
            if not callback then
                return "Task scheduled (async) success.";
            end
        end);
    end

    -- Register start_building_task
    if(not aiChatInstance.tool_callbacks["start_building_task"]) then
        aiChatInstance:RegisterToolCallback("start_building_task", function(args, callback)
            NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotManager.lua");
            local CopilotManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotManager");
            
            local taskType = "MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BuildSomething";
            local params = { welcomeMessage = L("准备开始建造！") };
            
            if args.template_url and args.template_url ~= "" then
                taskType = "MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BuildBlockTemplate";
                params = { filename = args.template_url };
            elseif args.description then
                params.description = args.description;
            end
            
            CopilotManager.GetInstance():ScheduleTask(
                taskType, 
                params, 
                { copilotClass = "MyCompany.Aries.Game.Tasks.CopilotDragonPet", priority = "high" }, -- Always use DragonPet
                function(result)
                     if callback then
                        callback(result and "Building task completed." or "Building task failed.");
                     end
                end
            );
            
            if not callback then return "Building task scheduled."; end
        end);
    end

    -- Register start_life_task
    if(not aiChatInstance.tool_callbacks["start_life_task"]) then
        aiChatInstance:RegisterToolCallback("start_life_task", function(args, callback)
            NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotManager.lua");
            local CopilotManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotManager");
            
            local taskType = "";
            local params = {};
            
            if args.activity == "planting" then
                taskType = "MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.Planting";
                params.plant_id = args.target_id;
            elseif args.activity == "fishing" then
                taskType = "MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CatchFishing";
                params.fish_id = args.target_id;
            elseif args.activity == "cooking" then
                taskType = "MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.Cooking";
                params.recipe_id = args.target_id;
            else
                if callback then callback("Unknown activity type."); end
                return;
            end
            
            CopilotManager.GetInstance():ScheduleTask(
                taskType, 
                params, 
                { copilotClass = "MyCompany.Aries.Game.Tasks.CopilotLandKeeper", priority = "normal" }, -- Always use LandKeeper
                function(result)
                     if callback then
                        callback(result and "Life task completed." or "Life task failed.");
                     end
                end
            );
            
            if not callback then return "Life task scheduled."; end
        end);
    end
end

return EasyAIChatTools;
