--[[
Title: EasyBuilder Character Action Task
Author(s): LiXizhi
Date: 2025/11/11
Desc: Character control system with basic actions

Use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyCharAction.lua");
local EasyCharAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyCharAction");
EasyCharAction:ShowPage(GameLogic.EntityManager.GetPlayer())
EasyCharAction:CloseWindow()
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/SceneContextManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyAIChat.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyAIConfig.lua");
local SceneContextManager = commonlib.gettable("System.Core.SceneContextManager");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EasyAIChat = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyAIChat");
local EasyAIConfig = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyAIConfig");
local EasyCharAction = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyCharAction"));

local page;
-- Cache for copilot tasks
EasyCharAction.cachedTasks = nil
EasyCharAction.lastCacheTime = 0
EasyCharAction.cacheTimeout = 1000  -- Cache for 1 second (in milliseconds)

-- Configuration: available character actions
EasyCharAction.actionConfig = {
    { name = "跟随我", funcName = "OnClickFollowMe", description = "让角色跟随你" },
    { name = "停下来", funcName = "OnClickStop", description = "停止跟随" },
    { name = "等一下", funcName = "OnClickWait", description = "让角色等待" },
    { name = "过来", funcName = "OnClickComeHere", description = "让角色过来" },
}

function EasyCharAction.InitPage(Page)
    page = Page;
end

function EasyCharAction.GetDisplayName()
    if(EasyCharAction.targetEntity and EasyCharAction.targetEntity.GetDisplayName) then
        return EasyCharAction.targetEntity:GetDisplayName() or "";
    end
    return "";
end

function EasyCharAction.HasRunningTasks()
    local tasks = EasyCharAction.GetCopilotTasks()
    for _, task in ipairs(tasks) do
        if task.isRunning and not task.isPaused then
            return true
        end
    end
    return false
end

-- return stanima, maxStamina: current stamina and max stamina of the copilot
function EasyCharAction:GetStamina()
    local targetEntity = EasyCharAction.targetEntity
    if(targetEntity and targetEntity.copilot and targetEntity.copilot.GetStamina) then
        return targetEntity.copilot:GetStamina();
    end
    return 0,0;
end

function EasyCharAction:ShowPage(targetEntity)
    -- Clear cache when entity changes
    if EasyCharAction.targetEntity ~= targetEntity then
        -- disconnect previous copilot listener if any
        if EasyCharAction.targetEntity and EasyCharAction.targetEntity.copilot then
            EasyCharAction.targetEntity.copilot:Disconnect("taskChanged", EasyCharAction, EasyCharAction.OnCopilotTaskChanged);
        end
        -- disconnect previous beforeDestroyed listener if any
        if EasyCharAction.targetEntity then
            EasyCharAction.targetEntity:Disconnect("beforeDestroyed", EasyCharAction, EasyCharAction.OnEntityDestroyed);
        end
        EasyCharAction.cachedTasks = nil
        EasyCharAction.lastCacheTime = 0
    end
    
    EasyCharAction.targetEntity = targetEntity
    local bShow = targetEntity ~= nil
    if(bShow) then
        commonlib.TimerManager.SetTimeout(function()
            SceneContextManager:Connect("mousePressed", EasyCharAction, EasyCharAction.OnSceneClicked, "UniqueConnection");
        end, 100);
    end
    -- connect to copilot taskChanged signal so UI auto-refreshes when tasks change
    if targetEntity and targetEntity.copilot then
        targetEntity.copilot:Connect("taskChanged", EasyCharAction, EasyCharAction.OnCopilotTaskChanged, "UniqueConnection");
    end
    -- connect to beforeDestroyed signal to close page when entity is destroyed
    if targetEntity then
        targetEntity:Connect("beforeDestroyed", EasyCharAction, EasyCharAction.OnEntityDestroyed, "UniqueConnection");
    end
    if(not page) then
        local width, height = 320, 600;
        local params = {
                url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyCharAction.html", 
                name = "EasyCharAction.ShowPage", 
                isShowTitleBar = false,
                DestroyOnClose = true,
                bToggleShowHide=false, 
                style = CommonCtrl.WindowFrame.ContainerStyle,
                enable_esc_key = false,
                allowDrag = false,
                click_through = true, 
                bShow = (bShow ~= false),
                zorder = 1,
                directPosition = true,
                    align = "_rt",
                    x = -width-10,
                    y = 64,
                    width = width,
                    height = height,
            };
        System.App.Commands.Call("File.MCMLWindowFrame", params);
        if(params._page) then
            params._page.OnClose = function()
                -- disconnect copilot listener if any
                local ent = EasyCharAction.targetEntity
                if ent and ent.copilot then
                    ent.copilot:Disconnect("taskChanged", EasyCharAction, EasyCharAction.OnCopilotTaskChanged);
                end
                -- disconnect beforeDestroyed listener if any
                if ent then
                    ent:Disconnect("beforeDestroyed", EasyCharAction, EasyCharAction.OnEntityDestroyed);
                end
                EasyCharAction.targetEntity = nil
                page = nil;
                SceneContextManager:Disconnect("mousePressed", EasyCharAction, EasyCharAction.OnSceneClicked);
            end
        end
    else
        if(bShow == false) then
            page:CloseWindow();
        else
            page:Refresh(0.1);
        end
    end
end

function EasyCharAction:OnSceneClicked(event)
    SceneContextManager:Disconnect("mousePressed", EasyCharAction, EasyCharAction.OnSceneClicked);
    EasyCharAction:CloseWindow()
end

-- Handler for entity beforeDestroyed signal. Closes the window when entity is destroyed.
function EasyCharAction:OnEntityDestroyed()
    EasyCharAction:CloseWindow()
end

function EasyCharAction:CloseWindow()
    if(page) then
        page:CloseWindow();
    end
end

function EasyCharAction:RefreshPage()
    if(page) then
        page:Refresh(0.01);
    end
end

-- Handler for copilot taskChanged signal. Invalidates cache and refreshes UI.
function EasyCharAction:OnCopilotTaskChanged(task, eventType)
    -- Invalidate cache so next UI call will fetch fresh task list
    EasyCharAction.cachedTasks = nil
    EasyCharAction:RefreshPage()
end

-- Get all available actions
function EasyCharAction.GetAllActions()
    local actions_ds = {};
    for i, action in ipairs(EasyCharAction.actionConfig) do
        actions_ds[i] = {
            index = i,
            actionName = action.name,
            funcName = action.funcName or "",
            description = action.description or "",
        };
    end
    return actions_ds;
end

-- Handle action click
function EasyCharAction.OnClickAction(index)
    index = tonumber(index);
    if(not index) then return end
    
    local actions = EasyCharAction.GetAllActions();
    local actionData = actions[index];
    if(not actionData) then return end
    
    if not EasyCharAction.targetEntity then
        GameLogic.AddBBS(nil, L"请先选择一个目标");
        return
    end
    
    if(actionData.funcName and actionData.funcName ~= "") then
        local func = EasyCharAction[actionData.funcName];
        if(type(func) == "function") then
            func(EasyCharAction.targetEntity);
        end
    end
    
    EasyCharAction.OnClickClose()
end

-- Action implementations
function EasyCharAction.OnClickFollowMe()
    local targetEntity = EasyCharAction.targetEntity
    if(targetEntity and targetEntity.SetFollowTarget) then
        local entity = EntityManager.GetFocus()
        if(entity and entity.SetFollowTarget)  then
            targetEntity:SetFollowTarget(entity);
        end
    end
    EasyCharAction.OnClickClose()
end

function EasyCharAction.OnClickStop()
    local targetEntity = EasyCharAction.targetEntity
    if(targetEntity and targetEntity.SetFollowTarget) then
        targetEntity:SetFollowTarget(nil);
    end
    if(targetEntity and targetEntity.copilot and targetEntity.copilot.Stop) then
        targetEntity.copilot:Stop();
    end
    EasyCharAction.OnClickClose()
end

function EasyCharAction.OnClickChat()
    local targetEntity = EasyCharAction.targetEntity
    if(targetEntity) then
        -- Make both entities face each other
        local player = EntityManager.GetFocus()
        if player~=targetEntity and player and player.SetFacing and targetEntity.SetFacing then
            local px, py, pz = player:GetPosition()
            local tx, ty, tz = targetEntity:GetPosition()
            
            -- Calculate angle from player to target
            local dx, dz = tx - px, tz - pz
            local playerFacing = math.atan2(dx, dz)
            player:SetFacing(playerFacing - math.pi/2)
            
            -- Calculate angle from target to player (opposite direction)
            local targetFacing = math.atan2(-dx, -dz)
            targetEntity:SetFacing(targetFacing - math.pi/2)
        end
        EasyAIChat:ShowPage(targetEntity)
    end
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyTaskDialog.lua");
    local EasyTaskDialog = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyTaskDialog");
    EasyTaskDialog:CloseWindow()
    EasyCharAction.OnClickClose()
end

function EasyCharAction.OnClickWait()
    local targetEntity = EasyCharAction.targetEntity
    if(targetEntity) then
        GameLogic.AddBBS(nil, L"让角色等待");
        -- TODO: Implement wait logic
    end
    EasyCharAction.OnClickClose()
end

function EasyCharAction.OnClickComeHere()
    local targetEntity = EasyCharAction.targetEntity
    if(targetEntity) then
        GameLogic.AddBBS(nil, L"让角色过来");
        -- TODO: Implement come here logic
    end
    EasyCharAction.OnClickClose()
end

function EasyCharAction.CanChangeSkin()
    local targetEntity = EasyCharAction.targetEntity
    if(targetEntity and targetEntity.HasCustomGeosets and targetEntity:HasCustomGeosets()) then
        return true;
    end
end

function EasyCharAction.CanEditAIConfig()
    local targetEntity = EasyCharAction.targetEntity
    if(targetEntity and targetEntity.copilot and targetEntity.copilot.canEditAIConfig ~= nil) then
        return targetEntity.copilot.canEditAIConfig;
    end
    return true; -- default to true if not specified
end

function EasyCharAction.OnClickChangeCloth()
    local targetEntity = EasyCharAction.targetEntity
    if(targetEntity) then
        local MiniGameUserBag = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameUserBag.lua");
        MiniGameUserBag.ShowPage("costumes", targetEntity);
    end
    EasyCharAction.OnClickClose()
end

function EasyCharAction.OnClickProperties()
    local targetEntity = EasyCharAction.targetEntity
    if(targetEntity) then
        EasyAIConfig:ShowPage(targetEntity)
    end
    EasyCharAction.OnClickClose()
end

function EasyCharAction.OnClickClose()
    EasyCharAction:CloseWindow()
end

function EasyCharAction.GetCopilotTasks(bForceRefresh)
    local targetEntity = EasyCharAction.targetEntity
    if not (targetEntity and targetEntity.copilot and targetEntity.copilot.GetAllTaskStatus) then
        return {}
    end
    
    -- Check if we should use cached data
    local currentTime = commonlib.TimerManager.GetCurrentTime()
    if not bForceRefresh and EasyCharAction.cachedTasks and 
       (currentTime - EasyCharAction.lastCacheTime) < EasyCharAction.cacheTimeout then
        return EasyCharAction.cachedTasks
    end
    
    -- Fetch fresh data
    local tasks = targetEntity.copilot:GetAllTaskStatus()
    
    -- Transform for UI display
    local tasks_ds = {}
    for i, task in ipairs(tasks) do
        tasks_ds[i] = {
            id = task.id,
            name = task.name or "",
            description = task.description,
            isRunning = task.isRunning,
            isPaused = task.isPaused or false,
            canResume = task.isPaused or false,
            canPause = task.isRunning and not (task.isPaused or false),
            runCount = task.runCount or 0,
            progress = task.progress or 0,
            actionButtons = {},
        }
        local taskItem = targetEntity.copilot:GetTask(task.id)
        if taskItem and taskItem.taskInstance and taskItem.taskInstance.quests then
            local currentQuestInfo = taskItem.taskInstance.quests[taskItem.taskInstance.currentQuestIndex or 1]
            tasks_ds[i].name =currentQuestInfo and currentQuestInfo.title or ""
        end
        -- If task instance provides action buttons (via CopilotTaskBase:GetActionButtons), attach them
        if taskItem.taskInstance and type(taskItem.taskInstance.GetActionButtons) == "function" then
            local btns = taskItem.taskInstance:GetActionButtons()
            if type(btns) == "table" then
                for j, b in ipairs(btns) do
                    -- normalize button fields: text and name, and include task id for easy binding in UI
                    table.insert(tasks_ds[i].actionButtons, {
                        text = b.text or "",
                        name = b.name or "",
                        default = b.default == true,
                        taskId = task.id,
                    })
                end
            end
        end
    end
    
    -- Update cache
    EasyCharAction.cachedTasks = tasks_ds
    EasyCharAction.lastCacheTime = currentTime
    
    return tasks_ds
end

function EasyCharAction.OnClickPauseTask(taskId)
    taskId = tonumber(taskId)
    if not taskId then return end
    
    local targetEntity = EasyCharAction.targetEntity
    if targetEntity and targetEntity.copilot then
        local task = targetEntity.copilot:GetTask(taskId)
        if task and task.taskInstance:IsRunning() then
            targetEntity.copilot:PauseRunningTask()
        end
    end
end

function EasyCharAction.OnClickResumeTask(taskId)
    taskId = tonumber(taskId)
    if not taskId then return end
    
    local targetEntity = EasyCharAction.targetEntity
    if targetEntity and targetEntity.copilot then
        local task = targetEntity.copilot:GetTask(taskId)
        if task then
            local success = targetEntity.copilot:ResumeRunningTask()
            if success then
                GameLogic.AddBBS(nil, L"已恢复任务: " .. (task.name or ""), 2000)
            end
        end
    end
end

function EasyCharAction.OnClickDeleteTask(taskId)
    taskId = tonumber(taskId)
    if not taskId then return end
    
    local targetEntity = EasyCharAction.targetEntity
    if targetEntity and targetEntity.copilot then
        local task = targetEntity.copilot:GetTask(taskId)
        if task then
            local taskName = task.name or ""
            local success = targetEntity.copilot:RemoveTask(taskId)
            if success then
                GameLogic.AddBBS(nil, L"已删除任务: " .. taskName, 2000)
            end
        end
    end
end

-- Generic handler for task action buttons. Calls the underlying task instance OnAction(actionName)
function EasyCharAction.OnClickTaskAction(actionName, mcmlNode)
    actionName = tostring(actionName or "")

    local targetEntity = EasyCharAction.targetEntity
    if not (targetEntity and targetEntity.copilot) then return end

    local taskId = tonumber(mcmlNode:GetAttribute("param1"))
    local task = targetEntity.copilot:GetTask(taskId)
    if task then
        -- prefer calling task.taskInstance:OnAction if available
        if task.taskInstance and type(task.taskInstance.OnClickActionButton) == "function" then
            task.taskInstance:OnClickActionButton(actionName)
        end
    end
end