--[[
Title: Copilot Manager
Author(s): wyx
Date: 2025/1/7
Desc: Manages Copilot instances and their autonomous behaviors
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotManager.lua");
local CopilotManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotManager");
CopilotManager.GetInstance():Register(copilot);
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/GameLogic.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/BlockEngine.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/GameRules.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local GameRules = commonlib.gettable("MyCompany.Aries.Game.GameRules");
local CopilotManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotManager");

CopilotManager.copilots = {};
CopilotManager.isMonitoring = false;
CopilotManager.GUIDE_COOLDOWN = 30; -- Seconds
CopilotManager.SWITCH_COOLDOWN = 10; -- Seconds to wait before same copilot can active again

function CopilotManager.GetInstance()
    if(not CopilotManager.instance) then
        CopilotManager.instance = CopilotManager:new();
    end
    return CopilotManager.instance;
end

function CopilotManager:new()
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    o.copilots = {};
    o.currentCheckIndex = 1;
    o.taskQueue = {};
    o.isDND = false;
    return o;
end

function CopilotManager:SetDND(isDND)
    self.isDND = isDND and true or false;
end

function CopilotManager:IsDND()
    return self.isDND == true;
end

function CopilotManager:Register(copilot)
    if(not copilot) then return end
    for _, c in ipairs(self.copilots) do
        if(c == copilot) then return end
    end
    table.insert(self.copilots, copilot);
    copilot.lastGuideTime = 0;
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/BackgroundAgent.lua");
    local BackgroundAgent = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BackgroundAgent");
    local agent = BackgroundAgent:GetInstance();
    agent:OnCopilotRegistered(copilot);
end

function CopilotManager:RequestPreparePermission(copilot)
    local currentTime = commonlib.TimerManager.GetCurrentTime() / 1000;
    
    local activeCopilot = nil;
    for _, c in ipairs(self.copilots) do
        local runningTask = c:GetRunningTask();
        if runningTask and runningTask.taskInstance and runningTask.taskInstance.isPreparingActive then
             activeCopilot = c;
             break;
        end
    end
    
    if activeCopilot then
        if activeCopilot ~= copilot then
             return false;
        else
             return true;
        end
    end
    
    -- Check rotation/cooldown for same copilot
    if self.lastActiveCopilot == copilot then
        if self.lastActiveEndTime and (currentTime - self.lastActiveEndTime < self.SWITCH_COOLDOWN) then
            return false;
        end
    end
    
    -- Grant permission
    self.lastActiveCopilot = copilot;
    self.lastGlobalGuideTime = currentTime;
    return true;
end

function CopilotManager:ReleasePreparePermission(copilot)
    if self.lastActiveCopilot == copilot or self.lastActiveCopilot == nil then
         self.lastActiveCopilot = copilot;
         self.lastActiveEndTime = commonlib.TimerManager.GetCurrentTime() / 1000;
    end
end

function CopilotManager:ScheduleTask(taskClassPath, params, options, callback)
    options = options or {};
    table.insert(self.taskQueue, {
        classPath = taskClassPath,
        params = params or {},
        options = options,
        addTime = os.time(),
        callback = callback
    });
    self:ProcessQueue();
end

function CopilotManager:CreateCopilot(name, classPath)
    -- Default to generic CopilotBase if no classPath provided
    local CopilotClass;
    if not classPath or classPath == "" then
        classPath = "MyCompany.Aries.Game.Tasks.Copilot.CopilotBase";
    end
    CopilotClass = commonlib.gettable(classPath);
    if not CopilotClass then
        if type(classPath) == "string" and classPath:find("MyCompany", 1, true) then
            local className = classPath:match("([%w_]+)$");
            if className and className ~= "" then
                NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/" .. className .. ".lua");
            end
        else
            NPL.load(classPath);
        end
        CopilotClass = commonlib.gettable(classPath);
    end
    
    if not CopilotClass then
        LOG.std(nil, "error", "CopilotManager", "Failed to load copilot class: %s", tostring(classPath));
         return nil
    end
    
    if CopilotClass then
        local copilot = CopilotClass.GetInstance()
        local entity = copilot:CreateEntity();
        if entity and name then
            entity:SetDisplayName(name);
            entity:SetName(name);
        end
        self:Register(copilot);
        LOG.std(nil, "info", "CopilotManager", "Created new copilot: %s", name or "unnamed");
        return copilot;
    end
end

function CopilotManager:ProcessQueue()
    if #self.taskQueue == 0 then return end
    
    local remainingQueue = {}
    
    for _, taskItem in ipairs(self.taskQueue) do
        local assigned = false
        local targetName = taskItem.options.copilotName
        
        -- 1. Try to find suitable existing copilot
        for _, copilot in ipairs(self.copilots) do
            local entity = copilot:GetEntity()
            local copilotName = entity and entity:GetName() or ""
            
            if (not targetName) or (targetName == copilotName) then
                -- Check if copilot can accept task (check queue capacity)
                -- CopilotBase.MaxTaskCount defaults to 5
                local maxTasks = copilot.MaxTaskCount or 5;
                local currentTaskCount = copilot.tasks and #copilot.tasks or 0;
                
                if currentTaskCount < maxTasks then
                    self:AssignTaskToCopilot(copilot, taskItem)
                    assigned = true
                    break
                end
            end
        end
        
        -- 2. If not assigned, check if we should create a new one
        if not assigned then
            -- If specific name requested but not found, OR no suitable copilot found (all queues full)
            -- We create a new one to handle the task
            
            local shouldCreate = false;
            if targetName then
                shouldCreate = true; -- Specific name not found
            else
                 -- No specific name, and all existing generic copilots are full
                 shouldCreate = true;
            end
            
            if shouldCreate then
                local newCopilot = self:CreateCopilot(targetName, taskItem.options.copilotClass);
                if newCopilot then
                    self:AssignTaskToCopilot(newCopilot, taskItem);
                    assigned = true;
                end
            end
        end
        
        if not assigned then
            table.insert(remainingQueue, taskItem)
        end
    end
    
    self.taskQueue = remainingQueue
end

function CopilotManager:AssignTaskToCopilot(copilot, taskItem)
    local taskClassPath = taskItem.classPath;
    -- Try full path or relative path
    local TaskClass = commonlib.gettable(taskClassPath)
    if not TaskClass then
         NPL.load(taskClassPath);
         TaskClass = commonlib.gettable(taskClassPath);
    end
    
    if not TaskClass and not string.find(taskClassPath, "MyCompany") then
        local fullPath = "MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot." .. taskClassPath;
        TaskClass = commonlib.gettable(fullPath);
        if not TaskClass then
            NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/" .. taskClassPath .. ".task.lua");
            TaskClass = commonlib.gettable(fullPath);
        end
    end
    
    if TaskClass then
        local task = TaskClass:new():Init(copilot, taskItem.params);
        
        -- Dynamic needPrepare logic based on distance/priority/DND
        local player = GameLogic.EntityManager.GetFocus();
        local needPrepare = false;
        if not self:IsDND() then
            if player and copilot:GetEntity() then
                local px,py,pz = player:GetBlockPos()
                local disSq = copilot:GetEntity():DistanceSqTo(px,py,pz);
                if disSq > 25 then
                    needPrepare = true;
                end
            end
            
            if taskItem.options.priority and taskItem.options.priority == "high" then
                needPrepare = true;
            end
        end
        
        task.needPrepare = needPrepare;
        
        local taskId = copilot:AddTask(task, {
            name = taskItem.params.name or taskItem.classPath,
            autoStart = true
        });
        
        -- Handle callback
        if taskItem.callback and taskId then
            local function onTaskChanged(changedTask, event)
                if changedTask.id == taskId then
                    if event == "completed" or event == "failed" then
                        -- Task finished
                        local result = changedTask.taskInstance:GetTaskResult();                        
                        if taskItem.callback then
                            taskItem.callback(result or (event == "completed"));
                            taskItem.callback = nil; -- Ensure called only once
                        end
                    end
                end
            end
            
            copilot:Connect("taskChanged", nil, onTaskChanged);
            task.OnFinish = function(t)
                 if taskItem.callback then
                    taskItem.callback(t:GetTaskResult() or (t.state == "completed"));
                    taskItem.callback = nil;
                 end
            end
            
            task:Connect("taskCompleted", nil, function()
                 if taskItem.callback then
                    taskItem.callback(task:GetTaskResult() or true);
                    taskItem.callback = nil;
                 end
            end);
             task:Connect("taskStopped", nil, function()
                 if taskItem.callback then
                    taskItem.callback(task:GetTaskResult() or false);
                    taskItem.callback = nil;
                 end
            end);
        end

        LOG.std(nil, "info", "CopilotManager", "Assigned task %s to copilot (needPrepare=%s)", taskItem.classPath, tostring(needPrepare));
    else
        LOG.std(nil, "error", "CopilotManager", "Failed to load task class: %s", taskItem.classPath);
        if taskItem.callback then
            taskItem.callback(false);
        end
    end
end

function CopilotManager:GetCopilot(targetName)
    if not targetName or targetName == "" then
        return self.copilots[1];
    end
    for _, copilot in ipairs(self.copilots) do
        local entity = copilot:GetEntity()
        local copilotName = entity and entity:GetName() or ""
        if (targetName and targetName == copilotName) then
            return copilot
        end
    end
end

function CopilotManager:GetCopilotCodeEnv()
    return {
        GetPlayerBlockPos = function()
            local player = GameLogic.EntityManager.GetFocus();
            if player then
                local x,y,z = player:GetBlockPos();
                return {x, y, z};
            end
            return nil;
        end,
        GetPosition = function()
            if copilot.GetEntity then
                local entity = copilot:GetEntity();
                if entity then
                    local x,y,z = entity:GetBlockPos();
                    return {x, y, z};
                end
            end
            return nil;
        end,
        Say = function(text, duration)
            if copilot.Say then
                copilot:Say(text, duration or 3);
            end
        end,
        WalkTo = function(x, y, z)
            if copilot.WalkTo then
                copilot:WalkTo(x, y, z);
            end
        end,
        WalkForward = function(distance)
            if copilot.WalkForward then
                copilot:WalkForward(distance);
            end
        end,
        Wait = function(seconds)
            if copilot.Wait then
                copilot:Wait(seconds);
            end
        end,
        PlayAnimation = function(name)
            if copilot.PlayAnimation then
                copilot:PlayAnimation(name);
            end
        end,
        -- Add more sandboxed functions as needed
        print = function(...) LOG.std(nil, "info", "CopilotCode", ...); end,
    }
end

function CopilotManager:RunCodeForCopilot(targetName, code, callback)
    local copilot = self:GetCopilot(targetName);
    if not copilot then
        LOG.std(nil, "warn", "CopilotManager", "Failed to find copilot %s", targetName);
        if callback then
            callback({success = false, llm_result = "Copilot not found: " .. tostring(targetName)});
        end
        return false;
    end
    if type(code) == "table" then
        code = table.concat(code, "\n");
    end
    if type(code) ~= "string" or code == "" then
        if callback then
            callback({success = false, llm_result = "Invalid code"});
        end
        return false;
    end

    copilot:RunSimpleTask(function(copilot)
        local codeFunc, errmsg = loadstring(code, "copilotCode");
        if(codeFunc) then
            local codeEnv = self:GetCopilotCodeEnv();
            codeEnv.copilot = copilot;
            setmetatable(codeEnv, {__index = _G})
            setfenv(codeFunc, codeEnv)
            local ok, result = pcall(codeFunc)
            if not ok then
                LOG.std(nil, "error", "CopilotManager", "failed to run copilot code %s: %s", "copilotCode", tostring(result))
            end
        else
            LOG.std(nil, "error", "CopilotManager", "failed to load copilot code for %s: %s", "copilotCode", errmsg);
        end
    end,true,callback)
end

function CopilotManager:RunTerminalCode(code,callback)
    local status = GameLogic.GetCodeGlobal():RunAsCodeBlock(code, nil, nil, function(result,r2,r3,r4)
        if callback then
            callback({success = true, llm_result = tostring(result or "Code executed")});
        end
    end);
    return status;
end
