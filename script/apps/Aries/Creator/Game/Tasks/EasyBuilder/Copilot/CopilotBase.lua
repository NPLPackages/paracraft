--[[
Title: Copilot base class
Author(s): LiXizhi
Date: 2025/11/7
Desc: A controller class for EntityLiveModel that enables autonomous task execution.
1. CopilotTask-based task management system for structured, pausable tasks

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotBase.lua");
local CopilotBase = commonlib.gettable("MyCompany.Aries.Game.Tasks.Copilot.CopilotBase");
local copilot = CopilotBase.GetInstance()

-- Method 1: Direct coroutine control with RunSimpleTask
copilot:RunSimpleTask(function(copilot)
	local answer, btnIndex, allTextResults = copilot:Ask("shall we build now?", {{"Yes", default=true}, "No"});
	if(btnIndex == 1) then  -- or if(answer == "yes") then
	    local x, y, z = copilot:GetBlockPos();
        copilot:CreateBlock(x+5, y, z, 10, 3840);
        copilot:Say("now delete block", 2);
        copilot:DeleteBlock(x+5, y, z)
        copilot:WalkTo(x,y,z);
        copilot:Wait(2);
        copilot:Say();
	end
end)

-- Method 2: Task-based system with CopilotTask
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/BuildBlockTemplate.task.lua");
local BuildBlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BuildBlockTemplate");

-- Create and add a task
local task = BuildBlockTemplate:new():Init(copilot, {
    -- filename = "blocktemplates/chair.bmax",
    -- filename = "blocktemplates/house1.blocks.xml",
    filename = "blocktemplates/test.bmax",
	buildSpeed = 5,
});

copilot:AddTask(task, {
    name = "Build a chair",
    description = "Build a chair from template",
    enabled = true,
    autoStart = true,
});


-- Query status
local allTasks = copilot:GetAllTaskStatus();
local runningTask = copilot:GetRunningTask();

-- Method 3: Call LLM
copilot:RunSimpleTask(function(copilot)
    -- non-streaming
    local result = copilot:CallLLM("Tell me a story in 10 words", {stream=false});
    copilot:Say(result);
    
    -- streaming
    copilot:CallLLM("Tell me a story in 20 words", {stream=true});
    while true do
        local chunk, fullResult = copilot:GetStreamedLLMResult();
        if chunk == false then break end
        if chunk and chunk ~= "" then
            copilot:Say(fullResult);
        end
    end
end)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditableWorld.lua");
NPL.load("(gl)script/ide/System/Util/Iterators.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/BlockInEntityHand.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotTaskBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityLiveModel.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/AIChat.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/EasyAIChatTools.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/PersonalPageStore.lua");

local EntityLiveModel = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityLiveModel");
local CopilotTaskBase = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotTaskBase");
local BlockInEntityHand = commonlib.gettable("MyCompany.Aries.Game.EntityManager.BlockInEntityHand");
local Iterators = commonlib.gettable("System.Util.Iterators");
local EasyEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
local AIChat = commonlib.gettable("MyCompany.Aries.Game.Common.AIChat");
local EasyAIChatTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.EasyAIChatTools");
local PersonalPageStore = commonlib.gettable("MyCompany.Aries.Creator.Game.KeepWork.PersonalPageStore");

local CopilotBase = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tasks.Copilot.CopilotBase"));

-- Constants
CopilotBase.MaxTaskCount = 5; -- Maximum number of tasks in queue

-- Signals for task lifecycle events
CopilotBase:Signal("taskStarted");
CopilotBase:Signal("taskProgress");
CopilotBase:Signal("taskCompleted");
CopilotBase:Signal("taskFailed");
-- Fired when tasks list or any task state changes. params: (task, eventType)
CopilotBase:Signal("taskChanged");

function CopilotBase:ctor()
	self.entity = nil;              -- The EntityLiveModel this copilot controls
	self.isEnabled = true;          -- Whether the copilot is active
	self.lastUpdateTime = 0;        -- Last frame move time
	self.updateInterval = 0.2;      -- Update interval in seconds
	self.coroutineTimers = {};      -- Timers for coroutine operations
	
	-- Task management system
	self.tasks = {};                -- Array of all tasks (both enabled and disabled)
	self.runningTask = nil;         -- Reference to the currently running task (0 or 1)
	self.taskIdCounter = 1;         -- Auto-increment ID for tasks
	
	-- Stamina system
	self.stamina = 100;             -- Current stamina points
	self.maxStamina = 100;          -- Maximum stamina
	self.staminaRecoveryRate = 0.3;   -- Stamina points recovered per second
	self.lastStaminaUpdateTime = nil; -- Last time stamina was updated
	self.forceAddToEditable = true;    -- force enable EasyEditableWorld on resume
	
	-- Text-to-speech settings
	self.defaultVoiceType = 20011;  -- Default voice narrator (20011 is default female voice)
	
	-- Memory storage for key-value pairs
	self.memory = {};               -- Table to store arbitrary key-value data
	
	-- AI configuration
	self.canEditAIConfig = true;    -- Whether the user can edit AI configuration (default true)
	self.tool_handlers = {};
end

-- Initialize the copilot with an entity
-- @param entity: EntityLiveModel instance to control
-- @return self for chaining
function CopilotBase:Init(entity)
	self:SetEntity(entity);
	return self;
end

-- virtual function to create the controlled entity if not set before
function CopilotBase:CreateEntity()
    if(self.entity and self.entity:IsValid()) then
        return self.entity;
    end
    
    -- try to find existing entity by name
    local entity = EntityManager.GetEntity("Copilot");
    if(entity) then
        self:SetEntity(entity);
        return entity;
    end

    -- create a new one
    local player = EntityManager.GetPlayer();
    if(player) then
        local x, y, z = player:GetBlockPos();
        -- find a position near player
        local bx, by, bz = x, y, z;
        if(self.GetFreeBlockPos) then
             bx, by, bz = self:GetFreeBlockPos(x, y, z, true);
             if(not bx) then bx, by, bz = x, y, z end
        end
        
        local entity = EntityLiveModel:Create({bx=bx, by=by, bz=bz});
        entity:SetModelFile("character/CC/02human/paperman/boy01.x"); 
        entity:SetDisplayName(L"Copilot");
		entity:SetPersistent(false);
		entity:SetStaticTag("actionname", L"互动");
		entity:SetOnClickEvent("API.CharInteract");
		entity:SetActionRadius(1.5);
		entity:SetCanDrag(true)
        entity:Attach();
        self:SetEntity(entity);
        return entity;
    end
    return self.entity;
end

function CopilotBase:CreateGetEntity()
    if(self.entity and self.entity:IsValid()) then
        return self.entity;
    end
    local entity = self:CreateEntity()
	
	if(entity) then
		entity:Disconnect("clicked");
		entity:Connect("clicked", self, self.OnClick, "UniqueConnection");
	end
    return entity;
end

function CopilotBase:OnWorldUnload()
    self:ClearAllTasks();
	GameLogic:Disconnect("WorldUnloaded", self, self.OnWorldUnload, "UniqueConnection");
end

function CopilotBase.GetInstance()
    if(not CopilotBase.instance) then
        CopilotBase.instance = CopilotBase:new();
    end
    return CopilotBase.instance;
end


-- Set the controlled entity
-- @param entity: EntityLiveModel instance
function CopilotBase:SetEntity(entity)
	self.entity = entity;
	entity.copilot = self;
end

-- Get the controlled entity
-- @return EntityLiveModel instance
function CopilotBase:GetEntity()
	return self.entity;
end

-- Get the copilot name
function CopilotBase:GetName()
	local entity = self:GetEntity();
	if(entity) then
		return entity:GetName();
	end
	return "Copilot";
end

-- Sets the walk speed for the copilot entity. If speed is nil, resets to default.
function CopilotBase:SetWalkSpeed(speed)
	local entity = self:GetEntity()
	if entity then
		entity:SetWalkSpeed(speed)
	end
end

-- Gets the walk speed for the copilot entity. If speed is nil, returns the entity's default walk speed.
function CopilotBase:GetWalkSpeed()
	local entity = self:GetEntity()
	if entity then
		return entity:GetWalkSpeed()
	end
	return 4
end

-- Enable or disable the copilot
-- @param enabled: boolean
function CopilotBase:SetEnabled(enabled)
	if(enabled) then
		self:ResumeRunningTask()
	else
		self:PauseRunningTask()
	end
	self.isEnabled = enabled;
	self:CheckLoadFrameMoveTimer()
end

-- virtual function: get AI character configuration for large language model
-- @return nil or a table with character configuration fields
function CopilotBase:GetAICharConfig()
	local entity = self:GetEntity()
	if(entity and entity.aiCharConfig) then
		return entity.aiCharConfig
	end
	return nil
end

function CopilotBase:CheckLoadFrameMoveTimer()
    if not self.isEnabled then
        -- Stop frame move timer
        if self.frameMoveTimer then
            self.frameMoveTimer:Change();
            self.frameMoveTimer = nil;
        end
    else
        -- Restart frame move timer if we have an entity
		self.frameMoveTimer = self.frameMoveTimer or commonlib.Timer:new({
			callbackFunc = function(timer)
				self:FrameMove(0.2);
			end
		});
		self.frameMoveTimer:Change(200, 200);
    end
end

-- Check if copilot is enabled
-- @return boolean
function CopilotBase:IsEnabled()
	return self.isEnabled;
end

-- virtual function to auto-generate tasks when idle
function CopilotBase:GenerateTaskWhenIdle()
end

-- FrameMove update (called by timer)
-- @param deltaTime: time since last update in seconds
function CopilotBase:FrameMove(deltaTime)
	if not self.isEnabled or not self.entity then
		return;
	end
	
	-- Update running task
	self:UpdateRunningTask();

	-- Auto-generate tasks when idle
	if self:IsTaskStopped() then
		local currentTime = commonlib.TimerManager.GetCurrentTime();
		if not self.lastGenerateTime or (currentTime - self.lastGenerateTime) >= 1000 then
			self.lastGenerateTime = currentTime;
			self:GenerateTaskWhenIdle();
		end
	else
		self.lastGenerateTime = nil;
	end
end

function CopilotBase:Stop()
	if self.runningTask then
		local task = self.runningTask;
		if task.taskInstance then
			-- Get available action buttons to determine what actions are allowed
			local buttons = task.taskInstance:GetActionButtons();
			
			-- Check for pause or stop buttons and trigger their actions
			local hasPause = false;
			local hasStop = false;
			
			for _, button in ipairs(buttons) do
				if button.name == "pause" then
					hasPause = true;
				elseif button.name == "stop" then
					hasStop = true;
				end
			end
			
			-- Click pause button if available, otherwise click stop button
			if hasPause then
				task.taskInstance:OnClickActionButton("pause");
			elseif hasStop then
				task.taskInstance:OnClickActionButton("stop");
			end
		end
	end
end

-------------------------------------------------------
-- Task Management System
-------------------------------------------------------

-- Add a task to the copilot
-- @param taskInstance: Task instance (must have Start, Stop, Pause, Resume, GetStatus methods)
-- @param params: Optional parameters table {name, description, enabled, autoStart}
-- @return taskId: unique ID for the task
function CopilotBase:AddTask(taskInstance, params)
	local entity = self:CreateGetEntity();
	if not taskInstance then
		LOG.std(nil, "error", "CopilotBase", "Cannot add nil task");
		return nil;
	end
	
	params = params or {};
	if(params.allowUserPause ~= nil) then
		taskInstance.allowUserPause = params.allowUserPause;
	end
	if(params.allowUserStop ~= nil) then
		taskInstance.allowUserStop = params.allowUserStop;
	end
	if(params.autoRemoveWhenStopped ~= nil) then
		taskInstance.autoRemoveWhenStopped = params.autoRemoveWhenStopped;
	end
	local taskId = self.taskIdCounter;
	self.taskIdCounter = self.taskIdCounter + 1;
	
	local task = {
		id = taskId,
		name = params.name or ("Task_" .. taskId),
		description = params.description or "",
		enabled = params.enabled ~= false, -- default true
		autoStart = params.autoStart or false, -- default false
		allowUserPause = taskInstance.allowUserPause,
		allowUserStop = taskInstance.allowUserStop,
		taskInstance = taskInstance,
		addedTime = commonlib.TimerManager.GetCurrentTime() / 1000,
		lastRunTime = nil,
		runCount = 0,
	};
	
	-- Check if we need to remove old tasks to maintain MaxTaskCount limit
	if #self.tasks >= CopilotBase.MaxTaskCount then
		-- Find the oldest non-running task to remove
		local removedCount = 0;
		local targetRemoveCount = #self.tasks - CopilotBase.MaxTaskCount + 1;
		
		-- Iterate from the beginning (oldest tasks) to remove old tasks
		local i = 1;
		while i <= #self.tasks and removedCount < targetRemoveCount do
			local oldTask = self.tasks[i];
			-- Only remove if it's not the currently running task
			if not self.runningTask or self.runningTask.id ~= oldTask.id then
				LOG.std(nil, "info", "CopilotBase", "Removing old task to maintain queue limit: %s (ID: %d)", oldTask.name, oldTask.id);
				-- Call OnRemove() before removing
				if oldTask.taskInstance and oldTask.taskInstance.OnRemove then
					oldTask.taskInstance:OnRemove();
				end
				table.remove(self.tasks, i);
				removedCount = removedCount + 1;
				-- Don't increment i since we removed an element
			else
				i = i + 1;
			end
		end
	end
	
	table.insert(self.tasks, task);
	-- Let the task instance know its copilot and assigned task id so it can request removal itself
	if taskInstance then
		taskInstance.copilot = taskInstance.copilot or self;
		taskInstance.copilotTaskId = taskId;
	end
	LOG.std(nil, "info", "CopilotBase", "Added task: %s (ID: %d), queue size: %d/%d", task.name, taskId, #self.tasks, CopilotBase.MaxTaskCount);
	
	GameLogic:Connect("WorldUnloaded", self, self.OnWorldUnload, "UniqueConnection");

	-- notify listeners that a task was added
	self:taskChanged(task, "added");

	-- Auto-start if requested and no task is running
	if params.autoStart and not self.runningTask then
		self:StartTask(taskId);
	end

	self:CheckLoadFrameMoveTimer()
	return taskId;
end

-- Remove a task by ID
-- @param taskId: ID of the task to remove
-- @param bSkipStop: if true, don't call Stop() on the task instance (to avoid recursion)
-- @return boolean: true if removed successfully
function CopilotBase:RemoveTask(taskId, bSkipStop)
	for i, task in ipairs(self.tasks) do
		if task.id == taskId then
			-- Stop if it's currently running (but don't call StopRunningTask to avoid setting runningTask to nil)
			if self.runningTask and self.runningTask.id == taskId then
				-- Just stop the task instance and kill timers, don't clear runningTask yet
				-- This allows UpdateRunningTask to handle cleanup properly
				if not bSkipStop and task.taskInstance then
					-- Pass bSkipStop=true to prevent the Stop method from calling RemoveTask again
					task.taskInstance:Stop();
					-- Check if the task was already removed by Stop() to prevent double notification
					local taskStillExists = false;
					for _, t in ipairs(self.tasks) do
						if t.id == taskId then
							taskStillExists = true;
							break;
						end
					end
					if not taskStillExists then
						return true;
					end
				end
				self:KillAllTimers();
				self.runningTask = nil;
			end
			
			-- Call OnRemove() before removing from queue
			if task.taskInstance and task.taskInstance.OnRemove then
				task.taskInstance:OnRemove();
			end
			
			table.remove(self.tasks, i);
			LOG.std(nil, "info", "CopilotBase", "Removed task: %s (ID: %d)", task.name, taskId);
			-- notify listeners that a task was removed
			self:taskChanged(task, "removed");
			return true;
		end
	end
	
	LOG.std(nil, "warn", "CopilotBase", "Task not found: ID %d", taskId);
	return false;
end

-- Get a task by ID
-- @param taskId: ID of the task
-- @return task table or nil
function CopilotBase:GetTask(taskId)
	for _, task in ipairs(self.tasks) do
		if task.id == taskId then
			return task;
		end
	end
	return nil;
end

-- Get all tasks
-- @return array of task tables
function CopilotBase:GetAllTasks()
	return self.tasks;
end

-- Enable a task
-- @param taskId: ID of the task to enable
-- @return boolean: true if successful
function CopilotBase:EnableTask(taskId)
	local task = self:GetTask(taskId);
	if task then
		task.enabled = true;
		LOG.std(nil, "info", "CopilotBase", "Enabled task: %s (ID: %d)", task.name, taskId);
		self:taskChanged(task, "enabled");
		return true;
	end
	return false;
end

-- Disable a task (will stop it if running)
-- @param taskId: ID of the task to disable
-- @return boolean: true if successful
function CopilotBase:DisableTask(taskId)
	local task = self:GetTask(taskId);
	if task then
		task.enabled = false;
		
		-- Stop if it's currently running
		if self.runningTask and self.runningTask.id == taskId then
			self:StopRunningTask();
		end
		
		LOG.std(nil, "info", "CopilotBase", "Disabled task: %s (ID: %d)", task.name, taskId);
		self:taskChanged(task, "disabled");
		return true;
	end
	return false;
end

-- Start a task by ID (only if no task is currently running and task is enabled)
-- @param taskId: ID of the task to start
-- @return boolean: true if started successfully
function CopilotBase:StartTask(taskId)
	local task = self:GetTask(taskId);
	
	if not task then
		LOG.std(nil, "error", "CopilotBase", "Cannot start task: not found (ID: %d)", taskId);
		return false;
	end
	
	if not task.enabled then
		LOG.std(nil, "error", "CopilotBase", "Cannot start task: disabled (ID: %d, name: %s)", taskId, task.name);
		return false;
	end
	
	-- Check if another task is running
	if self.runningTask then
		local taskState = self.runningTask.taskInstance.state
		if taskState == CopilotTaskBase.STATE_PREPARING and self.runningTask.id == taskId then
			self.runningTask.taskInstance:FinishPreparation();
		else
			LOG.std(nil, "error", "CopilotBase", "Cannot start task: another task is running (ID: %d, name: %s)", self.runningTask.id, self.runningTask.name);
			return false;
		end
	end
	
	-- Move the task to the top of the task array (only the first task can be running)
	for i, t in ipairs(self.tasks) do
		if t.id == taskId then
			if i ~= 1 then
				-- Remove from current position
				table.remove(self.tasks, i);
				-- Insert at the beginning
				table.insert(self.tasks, 1, task);
				LOG.std(nil, "info", "CopilotBase", "Moved task to top of queue: %s (ID: %d)", task.name, taskId);
			end
			break;
		end
	end
	
	-- Set as running task BEFORE starting 
	self.runningTask = task;
	task.lastRunTime = commonlib.TimerManager.GetCurrentTime() / 1000;
	task.runCount = task.runCount + 1;
	
	-- Start the task
	local success, err = task.taskInstance:Start();
	
	if success == false then
		LOG.std(nil, "error", "CopilotBase", "Failed to start task: %s (ID: %d) - %s", 
			task.name, taskId, tostring(err));
		
		return false;
	end
	
	LOG.std(nil, "info", "CopilotBase", "Started task: %s (ID: %d)", task.name, taskId);
	self:taskChanged(task, "started");
	return true;
end

-- Stop the currently running task
-- @return boolean: true if stopped successfully
function CopilotBase:StopRunningTask()
	if not self.runningTask then
		return false;
	end
	
	self:OnStopByUser();
	
	local task = self.runningTask;
	local taskId = task.id;
	
	-- Call Stop() on the task instance first
	-- Note: This might trigger RemoveTask internally, so we need to check if task still exists after
	if task.taskInstance and task.taskInstance.Stop then
		task.taskInstance:Stop();
	end
	
	-- Check if the task was already removed during Stop() call
	local taskStillExists = self:GetTask(taskId) ~= nil;
	if not taskStillExists then
		-- Task was already removed by Stop(), just clean up
		self:KillAllTimers();
		self.runningTask = nil;
		return true;
	end

	-- Determine whether to remove the task from the queue on stop
	local shouldRemove = true;
	if task.taskInstance and task.taskInstance.autoRemoveWhenStopped ~= nil then
		shouldRemove = task.taskInstance.autoRemoveWhenStopped;
	end

	if shouldRemove then
		-- Use RemoveTask so removal logic is centralized (skip Stop since we already called it)
		local ok = self:RemoveTask(taskId, true);
		if not ok then
			-- Fallback: ensure timers are killed and runningTask cleared
			self:KillAllTimers();
			self.runningTask = nil;
		end
		return ok;
	else
		-- Keep task in queue but stop it and clear running state
		self:KillAllTimers();
		LOG.std(nil, "info", "CopilotBase", "Stopped running task (kept in queue): %s (ID: %d)", task.name, taskId);
		self.runningTask = nil;
		self:taskChanged(task, "stopped");
		return true;
	end
end

-- Pause the currently running task
-- @return boolean: true if paused successfully
function CopilotBase:PauseRunningTask()
	if not self.runningTask then
		return false;
	end
	
	local task = self.runningTask;
	
	if task.taskInstance and task.taskInstance.Pause then
		task.taskInstance:Pause();
		self:OnPauseByUser()
		LOG.std(nil, "info", "CopilotBase", "Paused running task: %s (ID: %d)", task.name, task.id);
		return true;
	end
	
	return false;
end

-- Resume the currently running task (if paused)
-- @return boolean: true if resumed successfully
function CopilotBase:ResumeRunningTask()
	if not self.runningTask then
		return false;
	end
	
	local task = self.runningTask;
	
	if task.taskInstance and task.taskInstance.Resume then
		local success = task.taskInstance:Resume();
		if success then
			self:OnResumeByUser()
			LOG.std(nil, "info", "CopilotBase", "Resumed running task: %s (ID: %d)", task.name, task.id);
		end
		return success;
	end
	
	return false;
end

-- Get the currently running task
-- @return task table or nil
function CopilotBase:GetRunningTask()
	return self.runningTask;
end

-- Update the running task (called from FrameMove)
function CopilotBase:UpdateRunningTask()
	-- Check all tasks in the queue for completion and running state
	local hasRunningTask = false;
	
	for i = #self.tasks, 1, -1 do
		local task = self.tasks[i];
		if task.taskInstance then
			-- Check if task is actually running (or preparing)
			if task.taskInstance.state == CopilotTaskBase.STATE_RUNNING or task.taskInstance.state == CopilotTaskBase.STATE_PREPARING then
				hasRunningTask = true;
				-- Sync self.runningTask if it's out of sync
				if not self.runningTask or self.runningTask.id ~= task.id then
					self.runningTask = task;
				end
			end
			
			-- Check if task is finished (completed or failed)
			if task.taskInstance:IsFinished() then
				local wasRunningTask = (self.runningTask and self.runningTask.id == task.id);
				
				-- Determine whether we should remove the task from the queue.
				-- Respect the task instance's `autoRemoveWhenStopped` flag (default true).
				local shouldRemove = true;
				if task.taskInstance.autoRemoveWhenStopped ~= nil then
					shouldRemove = task.taskInstance.autoRemoveWhenStopped;
				end

				if shouldRemove then
					-- Remove task (RemoveTask will stop the instance/timers and clear runningTask if needed)
					self:RemoveTask(task.id);
				else
					-- Keep the task in the list but clear running state and timers if it was the running task
					if wasRunningTask then
						-- Call OnRemove() since the task is being stopped
						if task.taskInstance and task.taskInstance.OnRemove then
							task.taskInstance:OnRemove();
						end
						self:KillAllTimers();
						self.runningTask = nil;
					end
					LOG.std(nil, "info", "CopilotBase", "Keeping completed task in queue: %s (ID: %d)", task.name, task.id);
				end
			end
		end
	end
	
	-- If no running task found, clear self.runningTask and try to start next auto-start task
	if not hasRunningTask then
		self:StartNextAutoStartTask();
	end
end

-- Start the next task with autoStart=true (called after a task completes or fails)
-- @return taskId of started task, or nil if no autostart task found
function CopilotBase:StartNextAutoStartTask()
	if self.runningTask then
		return nil;
	end
	
	-- Find first enabled task with autoStart=true
	for idx, task in ipairs(self.tasks) do
		-- Skip paused tasks when looking for next autostart task
		if idx == 1 and task.taskInstance and task.taskInstance.state == CopilotTaskBase.STATE_PAUSED then
			-- Don't start next autostart task if first task is paused
			break;
		end
		if task.enabled and task.autoStart then
			LOG.std(nil, "info", "CopilotBase", "Auto-starting next task: %s (ID: %d)", task.name, task.id);
			if self:StartTask(task.id) then
				return task.id;
			end
		end
	end
	return nil;
end

-- Get status of all tasks
-- @return array of status tables {id, name, enabled, isRunning, status}
function CopilotBase:GetAllTaskStatus()
	local statusList = {};
	
	for _, task in ipairs(self.tasks) do
		local taskStatus = {
			id = task.id,
			name = task.name,
			description = task.description,
			enabled = task.enabled,
			isRunning = false,
			runCount = task.runCount,
			lastRunTime = task.lastRunTime,
		};
		
		if task.taskInstance and task.taskInstance.GetStatus then
			local instanceStatus = task.taskInstance:GetStatus();
			taskStatus.state = instanceStatus.state;
			taskStatus.progress = instanceStatus.progress;
			taskStatus.isPaused = instanceStatus.isPaused;
			taskStatus.isRunning = instanceStatus.isRunning;
		end
		
		table.insert(statusList, taskStatus);
	end
	
	return statusList;
end

-- Clear all tasks (stops running task if any)
function CopilotBase:ClearAllTasks()
	self:StopRunningTask();
	
	-- Close the ask dialog if it's currently shown
	if self.isAskDialogShown then
		local entity = self:GetEntity();
		if entity then
			entity:ShowHeadOnDialog(nil);
		end
		self.isAskDialogShown = false;
	end
	
	-- Call OnRemove() for all remaining tasks before clearing
	for _, task in ipairs(self.tasks) do
		if task.taskInstance and task.taskInstance.OnRemove then
			task.taskInstance:OnRemove();
		end
	end
	
	self.tasks = {};
	self.taskIdCounter = 1;
	LOG.std(nil, "info", "CopilotBase", "Cleared all tasks");
	-- notify listeners that all tasks were cleared
	self:taskChanged(nil, "cleared");
end

-- Generate daily tasks (placeholder for future AI-based task generation)
-- This method will be used in the future to autonomously generate tasks
-- @param count: number of tasks to generate (default 3)
-- @return array of generated task IDs
function CopilotBase:GenerateDailyTasks(count)
	count = count or 3;
	
	LOG.std(nil, "info", "CopilotBase", "Generating %d daily tasks...", count);
	
	local generatedTaskIds = {};
	
	-- Placeholder: In the future, this would use AI/LLM to generate contextual tasks
	-- based on the world state, player activity, time of day, etc.
	-- For now, just log that this feature is planned
	
	-- Example structure for future implementation:
	-- 1. Analyze world state (what's built, what's missing, player preferences)
	-- 2. Generate task descriptions via AI
	-- 3. Create appropriate task instances
	-- 4. Add tasks with smart scheduling
	
	LOG.std(nil, "info", "CopilotBase", 
		"Daily task generation is a placeholder - will be implemented with AI in the future");
	
	return generatedTaskIds;
end

-- Select and start the next suitable task from available tasks
-- This will be used for autonomous task execution in the future
-- @param criteria: optional table of selection criteria {priority, type, etc.}
-- @return taskId of started task, or nil if none suitable
function CopilotBase:SelectAndStartNextTask(criteria)
	if self.runningTask then
		LOG.std(nil, "warn", "CopilotBase", "Cannot select next task: a task is already running");
		return nil;
	end
	
	criteria = criteria or {};
	
	-- Find enabled tasks that haven't run yet or ran least recently
	local candidates = {};
	for _, task in ipairs(self.tasks) do
		if task.enabled then
			table.insert(candidates, task);
		end
	end
	
	if #candidates == 0 then
		LOG.std(nil, "info", "CopilotBase", "No enabled tasks available to start");
		return nil;
	end
	
	-- Sort by priority (in future, use more sophisticated selection)
	-- For now, prefer tasks that haven't run, then least recently run
	table.sort(candidates, function(a, b)
		if not a.lastRunTime and not b.lastRunTime then
			return a.id < b.id; -- Stable sort by ID
		elseif not a.lastRunTime then
			return true; -- Never run takes priority
		elseif not b.lastRunTime then
			return false;
		else
			return a.lastRunTime < b.lastRunTime; -- Least recently run
		end
	end);
	
	-- Start the first candidate
	local selectedTask = candidates[1];
	LOG.std(nil, "info", "CopilotBase", "Auto-selecting task: %s (ID: %d)", 
		selectedTask.name, selectedTask.id);
	
	if self:StartTask(selectedTask.id) then
		return selectedTask.id;
	end
	
	return nil;
end

--[[Run a simple task using a function
-- This creates a CopilotTaskBase instance and adds it to the task queue.
-- The task will be automatically started.
-- @param funcMain: function to run in coroutine. e.g. 
function(copilot)
	copilot:WalkTo(10, 20);
	copilot:CreateBlock(10, 5, 20, block_types.names.Wood);
end
-- @param bStopPrevious: whether to stop previous task, if nil, we will wait for previous task to finish and run this one. 
-- @return taskId: ID of the created task, or nil if failed
]]
function CopilotBase:RunSimpleTask(funcMain, bStopPrevious, callback)
	if not funcMain or type(funcMain) ~= "function" then
		LOG.std(nil, "error", "CopilotBase", "RunSimpleTask: funcMain must be a function");
		return nil;
	end
	
	-- Stop previous task if requested
	if bStopPrevious and self.runningTask then
		self:StopRunningTask();
	end
	
	-- Create a simple task using CopilotTaskBase
	local task = CopilotTaskBase:new():Init(self, funcMain);
	task:Connect("taskCompleted", function()
		if callback and type(callback) == "function" then
			callback({success = true, result = {isFinished = true}});
		end
	end)
	-- Add task to the queue with auto-start
	local taskId = self:AddTask(task, {
		name = L"自动任务",
		description = L"简单任务",
		enabled = true,
		autoStart = true
	});
	
	return taskId;
end

function CopilotBase:AddSimpleTask(funcMain, params)
	if not funcMain or type(funcMain) ~= "function" then
		LOG.std(nil, "error", "CopilotBase", "AddSimpleTask: funcMain must be a function");
		return nil;
	end
	-- Create a simple task using CopilotTaskBase
	local task = CopilotTaskBase:new():Init(self, funcMain);
	params = params or {};
	params.name = params.name or L"自动任务";
	params.description = params.description or L"简单任务";
	self:AddTask(task, params);
	return task;
end
-------------------------------------------------------
-- Helper Functions
-------------------------------------------------------

-- Show status message
-- @param message: string message to display
function CopilotBase:ShowStatus(message)
	if GameLogic and GameLogic.AddBBS then
		GameLogic.AddBBS(nil, message, 3000, "255 255 0");
	end
end

-- Save a value to memory with a key
-- @param key: string key to identify the value
-- @param value: any value to store (can be nil to remove)
function CopilotBase:SaveMemoryValue(key, value)
	if not key then
		LOG.std(nil, "warn", "CopilotBase", "SaveMemoryValue: key cannot be nil");
		return;
	end
	self.memory = self.memory or {};
	self.memory[key] = value;
end

-- Load a value from memory by key
-- @param key: string key to retrieve the value
-- @return stored value or nil if not found
function CopilotBase:LoadMemoryValue(key)
	if not key then
		return nil;
	end
	self.memory = self.memory or {};
	return self.memory[key];
end

-- Clear all memory values
function CopilotBase:ClearMemory()
	self.memory = {};
end

-- Get current stamina and max stamina
-- Automatically recovers stamina based on time elapsed since last call
-- @return currentStamina, maxStamina
function CopilotBase:GetStamina()
	-- Quick return if stamina is already full
	if self.stamina >= self.maxStamina then
		self.lastStaminaUpdateTime = nil;
		return self.stamina, self.maxStamina;
	end
	
	local currentTime = commonlib.TimerManager.GetCurrentTime();
	
	self.lastStaminaUpdateTime = self.lastStaminaUpdateTime or currentTime;
	
	-- Calculate time elapsed since last update
	local deltaTime = (currentTime - self.lastStaminaUpdateTime) / 1000; -- Convert to seconds
	
	-- Recover stamina based on elapsed time
	if deltaTime > 0 and self.stamina < self.maxStamina then
		local recoveredStamina = deltaTime * self.staminaRecoveryRate;
		self.stamina = math.min(self.maxStamina, self.stamina + recoveredStamina);
	end
	
	-- Update last update time, or set to nil if stamina is full
	if self.stamina >= self.maxStamina then
		self.lastStaminaUpdateTime = nil;
	else
		self.lastStaminaUpdateTime = currentTime;
	end
	
	return self.stamina, self.maxStamina;
end

-- Consume stamina points
-- @param amount: amount of stamina to consume
-- @return true if stamina was consumed successfully, false if insufficient
function CopilotBase:ConsumeStamina(amount)
	-- Update stamina with recovery before consuming
	local stamina, maxStamina = self:GetStamina();
	
	-- Check if enough stamina is available
	if self.stamina >= amount then
		self.stamina = self.stamina - amount;
		-- Update lastStaminaUpdateTime since stamina was consumed
		self.lastStaminaUpdateTime = commonlib.TimerManager.GetCurrentTime();
		if self.stamina < self.maxStamina - 5 then
			self:ShowStamina(5)
		end
		return true;
	end
	return false;
end

-- Check if enough stamina is available
-- @param amount: amount of stamina needed
-- @return true if enough stamina available
function CopilotBase:HasStamina(amount)
	local current, max = self:GetStamina();
	return current >= amount;
end

-- Show stamina bar for a duration
-- @param duration: duration in seconds to show stamina bar, default to 2 seconds
function CopilotBase:ShowStamina(duration)
	local current, max = self:GetStamina();
	if(self.lastShownStamina ~= current) then
		
		local entity = self:GetEntity();
		if(entity) then
			if(not self.lastShownStamina) then
				self.lastShownStamina = current;
				local mcmlCode = [[<pe:mcml><div style="background-color:#4CAF50;width:50px;height:5px;margin-left:-25px;margin-top:0px;">
	<pe:progressbar style="width:50px;height:5px" Minimum="0" Maximum="<%=getMax()%>" value='<%=getCurrent()%>' getter="value" />
	</div></pe:mcml>]];
				entity:SetHeadOnDisplay({
					url = ParaXML.LuaXML_ParseString(mcmlCode),
					pageGlobalTable = {
						getMax = function()
							return max;
						end,
						getCurrent = function()
							local stamina = self:GetStamina();
							return math.floor(stamina);
						end,
					},
					bReuseWindow = true, 
					bAbove3D = true,
				},2);
			else
				self.lastShownStamina = current;
			end
			-- hide stamina after duration, and set lastShownStamina to nil and hide the headon display
			self.stanimaTimer = self.stanimaTimer or commonlib.Timer:new({
				callbackFunc = function(timer)
					self.lastShownStamina = nil;
					local entity = self:GetEntity();
					if(entity) then
						entity:SetHeadOnDisplay(nil, 2);
					end
				end
			});
			self.stanimaTimer:Change((duration or 2) * 1000);
		end
	end
	
end

function CopilotBase:ComeHere()
    local entity = self:CreateGetEntity();
    if not entity then return end
    local x, y, z = GameLogic.GetPlayer():GetPosition();
    entity:SetPosition(x+1.5, y+0.2, z)
    entity:SetFacing(GameLogic.GetPlayer():GetFacing())
    entity:SetVisible(true);
    entity:FallDown()
end

function CopilotBase:Show()
    local entity = self:CreateGetEntity();
    if not entity then return end
    entity:SetVisible(true);
	entity:SetWalkSpeed(4);
	if self.isAskDialogShown then
		entity:SetHeadOnDialogVisible(true);
	end
end

function CopilotBase:OnPauseByUser()
	if self.isAskDialogShown and self.entity then
		self.entity:SetHeadOnDialogVisible(false);
	end
end

function CopilotBase:OnResumeByUser()
	if self.isAskDialogShown and self.entity then
		self.entity:SetHeadOnDialogVisible(true);
	end
end

function CopilotBase:OnStopByUser()
	local entity = self:GetEntity();
	if entity then
		if self.isAskDialogShown then
			entity:ShowHeadOnDialog(nil);
			self.isAskDialogShown = false;
		end
		entity:Say(nil);
	end
end

function CopilotBase:Hide()
    local entity = self:GetEntity();
    if not entity then return end
    entity:SetVisible(false);
	self:HideHeadOnBlock();
	if self.isAskDialogShown then
		entity:SetHeadOnDialogVisible(false);
	end
end

function CopilotBase:TeleportTo(x, y, z)
    local entity = self:CreateGetEntity();
    if not entity then return end
    entity:SetPosition(x, y+0.1, z)
    entity:SetVisible(true);
    entity:FallDown()
end 

function CopilotBase:GetPosition()
	local entity = self:CreateGetEntity();
	if not entity then return end
	return entity:GetPosition();
end

-- virtual functions to be overridden by subclasses
-- @return true if handled
function CopilotBase:OnDragEnd()
end

-- virtual functions to be overridden by subclasses
function CopilotBase:OnClick()
	local entity = self:CreateGetEntity();
	if not entity then return end

	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyCharAction.lua");
	local EasyCharAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyCharAction");
	EasyCharAction:ShowPage(entity)

	-- Call OnClick of the currently active task
	if self.runningTask and self.runningTask.taskInstance and self.runningTask.taskInstance.OnClick then
		self.runningTask.taskInstance:OnClick(self);
	end
end

-- Called when user sends a message via EasyAIChat
-- This function can process known messages and return true with a reply text
-- If it returns true, EasyAIChat will append the reply text if any, close its window, and let the copilot take over
-- @param text: string message sent by the user
-- @return handled: boolean, true if the message was handled
-- @return replyText: string, optional reply text to append to chat history
function CopilotBase:OnChatMessage(text)
	if not text or text == "" then
		return false, nil;
	end
	
	-- First, check if any running or enabled tasks can handle the message
	for _, task in ipairs(self.tasks) do
		if task.taskInstance and task.taskInstance.OnChatMessage and task.enabled then
			local handled, replyText = task.taskInstance:OnChatMessage(text);
			if handled then
				return true, replyText;
			end
		end
	end
	
	-- Copilot-level message processing (can be overridden in subclasses)
	-- Add custom message handling logic here if needed
	
	return false, nil;
end

function CopilotBase:RegisterToolHandler(name, handler)
	if not name or name == "" then
		return
	end
	self.tool_handlers = self.tool_handlers or {}
	self.tool_handlers[name] = handler
end

function CopilotBase:HandleToolCall(tool_name, args, callback)
	local handlers = self.tool_handlers
	if handlers then
		local handler = handlers[tool_name]
		if handler then
			local ok, res = pcall(function()
				return handler(args, callback)
			end)
			if not ok then
				local err = "Error executing tool: " .. tostring(res)
				if callback then
					callback(err)
					return
				end
				return err
			end
			if callback then
				if res ~= nil then
					callback(res)
				end
				return
			end
			return res
		end
	end
	if callback then
		callback("Tool not found")
		return
	end
	return "Tool not found"
end

function CopilotBase:GetGroundLevel(bx, by, bz, maxHeightDiff, aboveHeightDiff, bIgnoreEntities)
	maxHeightDiff = maxHeightDiff or 4
	aboveHeightDiff = aboveHeightDiff or maxHeightDiff

	-- Search downward from by to find the first solid block
	for dy = aboveHeightDiff, -maxHeightDiff, -1 do
		local testY = by + dy;
		local block = BlockEngine:GetBlock(bx, testY, bz);
		if block and block.obstruction then
			-- Check if block above is editable
			if BlockEngine:GetBlockId(bx, testY + 1, bz) == 0 then
				-- Check for persistent entities at ground level
				if not bIgnoreEntities then
					local entities = EntityManager.GetEntitiesInBlock(bx, testY + 1, bz);
					if entities then
						for entity, _ in pairs(entities) do
							if entity:IsPersistent() and entity:IsVisible() then
								return nil; -- Entity blocking
							end
						end
					end
				end
				return testY + 1; -- Return ground level (y above solid block)
			end
		end
	end
	return nil;
end

function CopilotBase:GetBlockPos()
	local entity = self:CreateGetEntity();
	if not entity then return end
	local x, y, z = entity:GetBlockPos();
	return x, y, z;
end

-- find a empty square area of radius, around the pet's current position. 
-- we will search for area within maxSearchDistance from the pet's current position, default to 2 times of radius.
-- the block below should be solid blocks,and the blocks above should be editable.
-- @param maxHeightDiff: maximum height difference allowed within the square area, default to 4.
-- return centerX, centerY, centerZ of an empty square area around the pet
function CopilotBase:FindEmptySquareGround(radius, maxSearchDistance, maxHeightDiff)
	radius = radius or 5
	maxSearchDistance = maxSearchDistance or (radius * 2)
	maxHeightDiff = maxHeightDiff or 4

	local entity = self:CreateGetEntity();
    if not entity then return end
	local x, y, z = entity:GetBlockPos();

	local editableWorld = GameLogic.CreateGetEditableWorld();
	if not editableWorld then return end

	local function isEditableBlock(x, y, z)
		if(editableWorld:IsEditableBlockForced(x,y,z) or BlockEngine:GetBlockId(x, y, z) == 0) then
			return true;
		end
	end

	local heightMap = {};

	-- Build a heightmap of ground levels in the search area， the ground below is a normal block, 
	-- and the blocks above is editable and contains no persistent entities or other blocks.
	-- we will cache the heightMap to avoid repeated calls to GetBlock
	-- @return -1 if no ground found
	local function getGroundLevel(bx, bz)
		local key = bx * 100000 + bz;
		if heightMap[key] ~= nil then
			return heightMap[key];
		end
		
		-- Search for ground level by scanning downward
		local groundY = nil;

		for dy = maxHeightDiff, -maxHeightDiff, -1 do
			local testY = y + dy;
			local block = BlockEngine:GetBlock(bx, testY, bz);
			if block then
				if(dy == maxHeightDiff) then
					groundY = nil; -- top block must be empty
				else
					local hasBlockingEntity = false;
					-- there should be no persistent entities in the block above the ground for at least 4 blocks
					local entities = EntityManager.GetEntitiesByMinMax(bx, testY - 1, bz, bx, testY + 4, bz);
					if entities then
						for _, entity in ipairs(entities) do
							if entity:IsPersistent() and entity:IsVisible() then
								hasBlockingEntity = true;
								break;
							end
						end
					end
					if not hasBlockingEntity then
						groundY = block.obstruction and (testY + 1) or nil;
					else
						groundY = nil;
					end
				end
				break;
			end
		end
		groundY = groundY or -1;
		heightMap[key] = groundY;
		return groundY;
	end

	-- Search in a spiral pattern from pet position
	for dx, dz in Iterators.SpiralCircle(maxSearchDistance) do
		local centerX = x + dx;
		local centerZ = z + dz;
		local centerY = getGroundLevel(centerX, centerZ);
		
		if centerY and centerY > 0 then
			-- Check if this forms a valid square area
			local isValid = true;
			local refY = centerY;
			
			-- Check all positions in the radius using spiral square iterator
			for rx, rz in Iterators.SpiralSquare(radius) do
				if getGroundLevel(centerX + rx, centerZ + rz) ~= refY then
					isValid = false;
					break;
				end
			end
			if isValid then
				return centerX, centerY, centerZ;
			end
		end
	end
	return nil;
end

-- only search in a 5x5 area around the given position
-- @param bForceNoEntities: if true, we will ensure no persistent entities are present at the position
-- return x, y, z of a free block position, or nil if not found
function CopilotBase:GetFreeBlockPos(x, y, z, bExcludeCenter, bForceNoEntities)
	-- find in spiral square pattern
	for dx, dz in Iterators.SpiralSquare(5) do
		if not bExcludeCenter or dx ~= 0 or dz ~= 0 then
			local testX = x + dx;
			local testZ = z + dz;
			local blockId = BlockEngine:GetBlockId(testX, y, testZ);
			if blockId == 0 then
				local canUsePosition = true;
				if(bForceNoEntities) then
					-- check for persistent entities
					local entities = EntityManager.GetEntitiesInBlock(testX, y, testZ);
					if(entities) then
						for entity,_ in pairs(entities) do
							if(entity:IsPersistent() and entity:IsVisible()) then
								canUsePosition = false;
								break;
							end
						end
					end
				end
				if canUsePosition then
					return testX, y, testZ
				end
			end
		end
	end
	return nil;
end


-------------------------------------------------------
-- Coroutine Helper Functions
-------------------------------------------------------

-- Kill all timers associated with coroutines
function CopilotBase:KillAllTimers()
	self:AbortLLM();
	self:HideHeadOnBlock();
	if self.coroutineTimers then
		for timer, _ in pairs(self.coroutineTimers) do
			if timer then
				timer:Change(); -- Kill timer
			end
		end
		self.coroutineTimers = nil;
	end
end

-- Add a timer to the managed timer list
function CopilotBase:AddTimer(timer)
	if timer then
		self.coroutineTimers = self.coroutineTimers or {};
		self.coroutineTimers[timer] = true;
	end
	return timer;
end

-- Remove a timer from the managed timer list
function CopilotBase:RemoveTimer(timer)
	if self.coroutineTimers then
		self.coroutineTimers[timer] = nil;
	end
end

-- Get a free timer that can be reused
function CopilotBase:GetFreeTimer()
	-- only check one timer, in most cases, coroutine has just one wait timer. 
	local timer = self.coroutineTimers and next(self.coroutineTimers);
	if timer and timer.isFreeTimer then
		return timer;
	end
end

-- Create a timer that calls a function after duration (with timer reuse)
function CopilotBase:SetTimeout(duration_ms, callbackFunc)
	local timer = self:GetFreeTimer();
	if timer then
		-- Reuse existing free timer
		timer.timeoutCallbackFunc = callbackFunc;
		timer.isFreeTimer = false;
		timer:Change(duration_ms);
	else
		-- Create new timer
		timer = commonlib.Timer:new({
			callbackFunc = function(timer)
				if timer.isFreeTimer then
					-- Timer is marked as free, clean up
					timer.isFreeTimer = false;
					timer.timeoutCallbackFunc = nil;
					timer:Change(); -- Kill timer
					self:RemoveTimer(timer);
				else
					-- Mark as free for future reuse
					timer.isFreeTimer = true;
					
					-- Wait at least 1000ms to see if this timer will be reused
					timer:Change(1000);
					
					local callback = timer.timeoutCallbackFunc;
					if callback and self.runningTask then
						timer.timeoutCallbackFunc = nil;
						callback();
					end
				end
			end
		});
		timer.timeoutCallbackFunc = callbackFunc;
		timer.isFreeTimer = false;
		timer:Change(duration_ms);
		self:AddTimer(timer);
	end
	return timer;
end

-- Resume the coroutine
function CopilotBase:Resume()
	if self.runningTask then
		-- If task is paused, check again after a short delay
		if self.runningTask.taskInstance.state == CopilotTaskBase.STATE_PAUSED then
			--[[ Reschedule resume check for later (when potentially unpaused)
			self:SetTimeout(300, function()
				self:Resume();
			end);
			]]
			return false;
		end
		local ok = self.runningTask.taskInstance:Resume();
		return ok;
	end
end

-- Yield the coroutine
function CopilotBase:Yield()
	return coroutine.yield();
end

-- Check if the running task is stopped
-- @return boolean: true if no task is running or task is stopped
function CopilotBase:IsTaskStopped()
	return not self.runningTask or 
	       not self.runningTask.taskInstance or 
	       self.runningTask.taskInstance.stopRequested or
	       self.runningTask.taskInstance.state == CopilotTaskBase.STATE_FAILED or
	       self.runningTask.taskInstance.state == CopilotTaskBase.STATE_IDLE;
end

-- Check if we need to yield to prevent blocking (auto-yield in loops)
local checkyield_count = 0;
local checkyield_tick = 0;
function CopilotBase:CheckYield()
	local cur_tick = commonlib.TimerManager.GetCurrentTime();
	if checkyield_tick == cur_tick then
		checkyield_count = checkyield_count + 1;
	else
		checkyield_tick = cur_tick;
		checkyield_count = 0;
	end
	
	-- If we've looped 1000 times in the same tick, yield
	if checkyield_count > 1000 then
		self:Wait(0.01);
	end
end

------------------------------------------
-- all functions below are async functions that must be called in coroutines
------------------------------------------

-- Wait for a specified duration (must be called from within coroutine)
-- @param seconds: duration in seconds, default is 0.03 (one frame at 30fps)
function CopilotBase:Wait(seconds)
	seconds = seconds or 0.03;
	if self.runningTask then
		self:SetTimeout(math.floor(seconds * 1000), function()
			self:Resume();
		end);
		self:Yield();
	else
		-- if no running task, just yield to prevent infinite loop in zombie tasks
		self:Yield();
	end
end

-- Wait until the entity can move (not being dragged, no follow target)
function CopilotBase:WaitUntilCanMove()
	local entity = self:CreateGetEntity();
	if not entity then return end
	
	-- Do not move when the entity is being dragged
	while entity.IsDragging and entity:IsDragging() do
		self:Wait(0.2);
	end
	
	if(entity.SetFollowTarget) then
		entity:SetFollowTarget(nil); 
	end
end

-- Move entity to a free position if current position has blocking entities or blocks，
-- only moves horizontally to the nearest free position at the same y level.
-- Returns immediately if already in a free position
-- @param bx, by, bz: block coordinates to check and move from if blocked. if nil, use current entity position.
function CopilotBase:MoveToFreePosition(bx, by, bz)
	local entity = self:CreateGetEntity();
	if not entity then return end
	if not bx then
		bx, by, bz = entity:GetBlockPos();
	end
	local freeX, freeY, freeZ = self:GetFreeBlockPos(bx, by, bz, false, true);
	if freeX and (freeX ~= bx or freeZ ~= bz) then
		-- Move horizontally to free position at same y level
		local _, currentY, _ = entity:GetPosition();
		local freeRealX, freeRealY, freeRealZ = BlockEngine:real_bottom(freeX, freeY, freeZ);
		entity:SetPosition(freeRealX, currentY, freeRealZ);
		return;
	end
end

-- Walk to a target position (must be called from within coroutine) at 20FPS.
-- it will turn to the target position at some speed while smoothly move to the target position at buildin walk speed.
-- if the target position is blocked, it will find a non block in its vicinity of 2 blocks.
-- if there is no ground at target position, it will play the fly animation instead of walk animation. 
-- we use linear interpolation to move the entity to the target position. if there is no ground at current position we will fly anim, otherwise play walk anim. 
-- @param x, y, z: target position in block coordinates. if z is nil, x,y is x,z.
-- @param y: optional y coordinate, if nil, will find ground level
function CopilotBase:WalkTo(x, y, z, walkSpeed)
	local entity = self:CreateGetEntity();
	if not entity then return end
	
	self:WaitUntilCanMove();
	
	local bx, by, bz = entity:GetBlockPos();
	if not z then
		z = y;
		y = nil;
	end
	-- Find ground level at target position if y not specified
	if not y then
		y = self:GetGroundLevel(x, by, z);
		if not y then
			-- No ground found within range, try to find a non-blocked position nearby
			local foundPos = false;
			for dx = -2, 2 do
				for dz = -2, 2 do
					y = self:GetGroundLevel(x + dx, by, z + dz);
					if y then
						x = x + dx;
						z = z + dz;
						foundPos = true;
						break;
					end
				end
				if foundPos then break end
			end
			
			if not y then
				-- Still no ground, will fly to position at current y level
				y = by;
			end
		end
	else
		-- If y is specified, check if target position is blocked
		local blockId = BlockEngine:GetBlockId(x, y, z);
		if blockId ~= 0 then
			-- Target position is blocked, try to find a free position nearby
			local freeX, freeY, freeZ = self:GetFreeBlockPos(x, y, z);
			if not freeX then
				-- No free position found, cannot walk there
				return;
			end
			x, y, z = freeX, freeY, freeZ;
		end
	end
	
	-- Convert block to real coordinates for target
	local targetX, targetY, targetZ = BlockEngine:real_bottom(x, y, z);
	
	-- Get current position
	local startX, startY, startZ = entity:GetPosition();
	
	-- Calculate movement parameters
	local dx = targetX - startX;
	local dy = targetY - startY;
	local dz = targetZ - startZ;
	local distance = math.sqrt(dx*dx + dz*dz);
	
	if distance < 0.1 then
		-- Already at target
		return;
	end
	
	-- Calculate movement at 30 FPS
	local walkSpeed = walkSpeed or self:GetWalkSpeed();
	local frameTime = 0.03;
	local totalFrames = math.ceil(distance / (walkSpeed * frameTime));
	
	-- Determine initial animation based on ground at start position
	local startGroundY = self:GetGroundLevel(bx, by, bz);
	local hasGroundAtStart = (startGroundY and math.abs(startY - BlockEngine:real_bottom(bx, startGroundY, bz)) < 0.5);
	
	entity:EnableAnimation(true);
	entity:SetDummy(false);
	
	-- Interpolate movement
	for frame = 1, totalFrames do
		if self:IsTaskStopped() then break end
		
		local t = frame / totalFrames;
		local currentX = startX + dx * t;
		local currentY = startY + dy * t;
		local currentZ = startZ + dz * t;
		
		-- Check if there's ground at current position
		local cbx, cby, cbz = BlockEngine:block(currentX, currentY+0.1, currentZ);
		local currentGroundY = BlockEngine:GetTerrainHeight(cbx, cby+2, cbz);
		local hasGround = (currentGroundY and (currentY - currentGroundY) < 0.5);
		
		-- Set appropriate animation
		if hasGround then
			entity:SetAnimation(5); -- Walk animation
		else
			entity:SetAnimation(38); -- Fly animation
		end
		
		
		-- Update position
		entity:SetPosition(currentX, currentY > (currentGroundY + 0.5) and currentY or currentGroundY, currentZ);
		
		-- Turn towards target
		local targetFacing = math.atan2(targetX - currentX, targetZ - currentZ) - math.pi/2;
		local currentFacing = entity:GetFacing();
		local facingDiff = targetFacing - currentFacing;
		
		-- Normalize angle difference to [-pi, pi]
		while facingDiff > math.pi do facingDiff = facingDiff - 2*math.pi end
		while facingDiff < -math.pi do facingDiff = facingDiff + 2*math.pi end
		
		-- Turn at a reasonable speed (e.g., 180 degrees per second = pi radians per second)
		local maxTurnPerFrame = math.pi * frameTime;
		if math.abs(facingDiff) > maxTurnPerFrame then
			facingDiff = facingDiff > 0 and maxTurnPerFrame or -maxTurnPerFrame;
		end
		
		entity:SetFacing(currentFacing + facingDiff);
		
		self:Wait(frameTime);
	end
	
	-- Ensure we're exactly at target position
	entity:SetPosition(targetX, targetY, targetZ);
	entity:SetAnimation(0); -- Idle animation
end

function CopilotBase:WalkForward(distance, walkSpeed)
	local entity = self:CreateGetEntity();
	if not entity then return end
	
	local facing = entity:GetFacing();
	local dx = math.sin(facing) * distance;
	local dz = (math.cos(facing) * distance) * -1;
	
	local bx, by, bz = entity:GetBlockPos();
	local targetBx = bx + dx;
	local targetBy = by;
	local targetBz = bz + dz;
	self:WalkTo(targetBx, targetBy, targetBz, walkSpeed);
end

-- Make the entity fall down to the ground 
-- Similar to WalkTo but moves downward using setPosition instead of entity's builtin FallDown
function CopilotBase:FallDown()
	local entity = self:CreateGetEntity();
	if not entity then return end
	
	-- If not in a task context, use the entity's built-in FallDown method
	if not self.runningTask then
		if entity.FallDown then
			entity:FallDown();
		end
		return;
	end
	
	self:WaitUntilCanMove();
	
	-- Get current position
	local startX, startY, startZ = entity:GetPosition();
	local bx, by, bz = entity:GetBlockPos();
	
	-- Find ground level below current position using terrain height
	local targetRealY = BlockEngine:GetTerrainHeight(bx, by+1, bz);
	
	if not targetRealY then
		-- No ground found within range
		return
	end
	
	-- Calculate vertical distance (negative when falling down)
	local dy = startY - targetRealY;
	
	-- Return immediately if already on ground or within 0.1 meters above ground
	if dy <= 0.1 then
		-- Check if current position has blocking entities, if so, move out
		self:MoveToFreePosition();
		return;
	end
	
	-- Calculate movement at 30 FPS
	local fallSpeed = 8.0; -- Falling is faster than walking
	local frameTime = 0.03;
	local distance = math.abs(dy);
	local totalFrames = math.ceil(distance / (fallSpeed * frameTime));
	
	entity:EnableAnimation(true);
	entity:SetDummy(false);
	
	-- Play fly/fall animation
	entity:SetAnimation(38); -- Fly animation
	
	-- Interpolate downward movement
	for frame = 1, totalFrames do
		if self:IsTaskStopped() then break end
		
		local t = frame / totalFrames;
		local currentY = startY - dy * t;
		
		-- Check if we've reached ground during fall
		if currentY <= targetRealY then
			break
		end
		
		-- Update position (only Y changes during fall)
		entity:SetPosition(startX, currentY, startZ);
		
		self:Wait(frameTime);
	end
	
	-- Ensure we're exactly at target position
	entity:SetPosition(startX, targetRealY, startZ);
	entity:SetAnimation(0); -- Idle animation
end

-- Move by offset (teleport, ignores physics)
-- @param dx, dy, dz: offset in real coordinates, if dz is nil, dx, dy is dx, dz.
function CopilotBase:Move(dx, dy, dz)
	local entity = self:CreateGetEntity();
	if not entity then return end
	
	local bx, by, bz = entity:GetBlockPos();
	if not dz then
		dz = dy;
		dy = 0;
	end
	self:WalkTo(bx + dx, by + dy, bz + dz);
end

-- Set entity facing
-- @param facing: facing angle in radians
function CopilotBase:SetFacing(facing)
	local entity = self:CreateGetEntity();
	if not entity then return end
	
	local currentFacing = entity:GetFacing();
	local targetFacing = facing;
	
	-- Calculate the shortest rotation direction
	local facingDiff = targetFacing - currentFacing;
	while facingDiff > math.pi do facingDiff = facingDiff - 2*math.pi end
	while facingDiff < -math.pi do facingDiff = facingDiff + 2*math.pi end
	
	-- If already at target, no animation needed
	if math.abs(facingDiff) < 0.01 then
		entity:SetFacing(targetFacing);
		self:Wait(0.03);
		return;
	end
	
	-- Animate rotation at fixed speed
	local turnSpeed = math.pi; -- 180 degrees per second
	local frameTime = 0.03;
	local maxTurnPerFrame = turnSpeed * frameTime;
	local totalFrames = math.ceil(math.abs(facingDiff) / maxTurnPerFrame);
	
	for frame = 1, totalFrames do
		if self:IsTaskStopped() then break end
		
		local turnAmount = math.abs(facingDiff) > maxTurnPerFrame and maxTurnPerFrame or math.abs(facingDiff);
		turnAmount = facingDiff > 0 and turnAmount or -turnAmount;
		
		currentFacing = currentFacing + turnAmount;
		entity:SetFacing(currentFacing);
		
		facingDiff = facingDiff - turnAmount;
		
		self:Wait(frameTime);
	end
	
	-- Ensure exact final facing
	entity:SetFacing(targetFacing);
end

-- Turn by angle
-- @param angle: angle in degrees (positive = counter-clockwise)
function CopilotBase:Turn(angle)
	local entity = self:CreateGetEntity();
	if not entity then return end
	
	local facing = entity:GetFacing();
	self:SetFacing(facing + math.rad(angle));
end

-- @param x, y, z: target position in real coordinates
function CopilotBase:TurnTo(x,y,z)
	local entity = self:CreateGetEntity();
	if not entity then return end
	if(not x) then
		local player = EntityManager.GetFocus();
		if player then
			x, y, z = player:GetPosition();
		else
			return;
		end
	end
	
	local ex, ey, ez = entity:GetPosition();
	local targetFacing = math.atan2(x - ex, z - ez) - math.pi/2;
	self:SetFacing(targetFacing);
end

-- Play an animation
-- @param animId: animation ID (0-255)
-- @param duration: duration in seconds, if nil, plays once
function CopilotBase:PlayAnim(animId, duration)
	local entity = self:CreateGetEntity();
	if not entity then return end
	
	if entity.SetAnimation then
		entity:SetAnimation(animId);
		if duration then
			self:Wait(duration);
			entity:SetAnimation(0); -- Reset to idle
		else
			self:Wait(0.03); -- Wait one frame
		end
	end
end

local customChatConfig = {background="Texture/Aries/HeadOn/head_speak_bg_32bits.png;0 0 128 64:24 20 64 41",min_width=88,min_height=64, text_color="#333333",
    padding = 14,
	padding_bottom = 36,
    max_width = 230,
    fontSize = 16,
}

-- Make entity say something, this function can be called outside coroutines.
-- this function returns immediately after setting the text.
-- @param text: text to say
-- @param duration: duration in seconds, if nil, says forever until cleared
function CopilotBase:Say(text, duration)
	local entity = self:CreateGetEntity();
	if not entity then 
		GameLogic.AddBBS(nil, text, (duration or 3) * 1000);
		return;
	end
	
	if self.isAskDialogShown then
		entity:ShowHeadOnDialog(nil);
		self.isAskDialogShown = false;
	end

	if entity.Say then
		if text ~= nil then
			text = tostring(text);
			-- Escape HTML characters
			if text:find("<") and not text:match("</%w+>") then
				text = text:gsub("<", "&lt;");
				text = text:gsub(">", "&gt;");
			end
		end
		
		entity:Say(text, duration and (duration * 1000) or -1, true, customChatConfig);
		
		if duration then
			local lastText = text;
			commonlib.TimerManager.SetTimeout(function()
				-- Only clear if the text hasn't changed
				if entity and entity:GetLastSayText() == lastText then
					entity:Say(nil);
				end
			end, math.floor(duration * 1000));
		end
	end
end

-- Play text-to-speech for the given text using the copilot's default voice
-- @param text: string text to speak
-- @param voiceType: optional voice narrator type, defaults to self.defaultVoiceType (20011)
function CopilotBase:PlayText(text, voiceType)
	if not text or text == "" then
		return;
	end
	
	voiceType = voiceType or self.defaultVoiceType;
	SoundManager:PlayText(text, voiceType);
end

-- @param mcmlText: "<pe:mcml>hello world</pe:mcml>" string
function CopilotBase:ShowHeadonDisplay(mcmlText, index)
	local entity = self:CreateGetEntity();
	if not entity then return end
	
	-- Parse MCML
	local xmlNode = ParaXML.LuaXML_ParseString(mcmlText);
	if not xmlNode then
		return nil;
	end
	
	-- Display MCML on top of entity
	entity:SetHeadOnDisplay({
		url = xmlNode,
		is3D = false,
		offset= {x = 0, y = entity:GetHeight() + 0.1, z = 0}, facing=-1.57, 
	}, index or 0);
end

-- Ask user a question with optional buttons and wait for response (must be called from within coroutine)
-- @param text: string text to display (supports basic HTML)
-- @param buttons: nil or {"button1", "button2"}
-- {{text = "OK", default = true}, "button2"} format is also supported
-- {{text = "输入文字", type="text"}, "确定"} type of text is also supported
-- {{text = "确定", name="ok"}, "no"} if name property is provided, we will return name instead of button text 
-- @return: textResult, btnIndex, allTextResults
--   textResult: string text input if any button is of type="text", otherwise it is button text
--   btnIndex: number index of button clicked (1-based)
--   allTextResults: table of all text input values by button index
function CopilotBase:Ask(text, buttons)
	local entity = self:CreateGetEntity();
	if not entity then return nil end
	
	entity:Say(nil); -- Clear any existing speech
	-- If no text provided, just return last answer
	if not text and not buttons then
		return self.lastAnswer;
	end
	
	-- Reset answer
	self.lastAnswer = nil;
	self.lastButtonIndex = nil;
	self.allTextResults = nil;
	
	-- Show the dialog and wait for result
	self.isAskDialogShown = true;
	entity:ShowHeadOnDialog(text, buttons, function(textResult, btnIndex, allTextResults)
		self.isAskDialogShown = false;
		if(buttons and btnIndex and type(buttons[btnIndex]) == "table" and buttons[btnIndex].name) then
			local btn = buttons[btnIndex];
			if(not btn.type or btn.type~="text") then
				textResult = btn.name;
			end
		end
		self.lastAnswer = textResult;
		self.lastButtonIndex = btnIndex;
		self.allTextResults = allTextResults;
		-- Resume the coroutine
		self:Resume();
	end);
	
	-- Yield and wait for callback to resume
	self:Yield();
	
	return self.lastAnswer, self.lastButtonIndex, self.allTextResults;
end

-- Show a block model above the pet's head with animation (must be called from within coroutine)
-- @param blockId: block ID or block name to display
-- @param blockData: optional block data value, may contain color data
function CopilotBase:ShowHeadOnBlock(blockId, blockData)
	local entity = self:CreateGetEntity();
	if not entity then return end
	
	-- Validate block ID
	if type(blockId) == "string" then
		blockId = block_types.get(blockId);
	end
	
	if not blockId then return end
	
	-- Check if block ID has changed - if not, don't update
	if self.headOnBlockId == blockId and self.headOnBlockData == blockData and self.headOnBlock and not self.headOnBlock.isDead then
		return;
	end
	
	-- Clean up any existing head-on block first
	self:HideHeadOnBlock();
	
	-- Store the current block ID
	self.headOnBlockId = blockId;
	self.headOnBlockData = blockData;

	if(not blockId) then return end
	
	-- Get entity position
	local ex, ey, ez = entity:GetPosition();
	local entityHeight = entity:GetHeight() or 2.0;
	local yOffset = entityHeight + 0.5; -- Position above pet's head
	
	-- Create live model entity for block display
	local headOnBlock = EntityManager.EntityLiveModel:Create({
		x = ex, y = ey + yOffset, z = ez,
		item_id = block_types.names.LiveModel,
	});
	
	if not headOnBlock then return end
	
	headOnBlock:SetPersistent(false);
	headOnBlock:SetDummy(true); -- Disable physics
	headOnBlock:Attach();
	headOnBlock.nohistory = true;
	
	-- Transform entity to block item using BlockInEntityHand
	BlockInEntityHand.TransformEntityToBlockItem(headOnBlock, blockId);
	
	-- Apply color if this is a color block and blockData contains color information
	if blockData then
		local block_template = block_types.get(blockId);
		if block_template then
			local item = block_template:GetItem();
			if item and item:HasColorData() then
				-- Calculate color from data
				local color = item:DataToColor(blockData);
				if color then
					headOnBlock:SetColor(color);
				end
			end
		end
	end
	
	-- Store reference for later cleanup
	self.headOnBlock = headOnBlock;
	
	-- Animation parameters (matching EasyLiveModel pattern)
	local animationDuration = 0.6; -- 0.6 seconds
	local animationStartScale = 0.1;
	local animationPeakScale = 1.2;
	local targetScale = 1.0;
	local frameTime = 0.03; -- 30 FPS
	local totalFrames = math.ceil(animationDuration / frameTime);
	
	local initialRotation = 0;
	local targetRotation = math.pi; -- Full 180 degree rotation
	
	-- Set initial state
	local currentScale = headOnBlock:GetScaling() or 1.0;
	headOnBlock:SetScaling(currentScale * animationStartScale);
	headOnBlock:SetFacing(initialRotation);
	
	-- Animate over frames
	for frame = 1, totalFrames do
		if self:IsTaskStopped() or not headOnBlock or headOnBlock.isDead then
			break;
		end
		
		local progress = frame / totalFrames;
		
		-- Animate scale with bounce effect
		local scale;
		if progress < 0.5 then
			-- First half: scale from startScale to peakScale
			scale = animationStartScale + (progress * 2) * (animationPeakScale - animationStartScale);
		else
			-- Second half: scale from peakScale to targetScale
			scale = animationPeakScale - ((progress - 0.5) * 2) * (animationPeakScale - targetScale);
		end
		headOnBlock:SetScaling(currentScale * scale);
		
		-- Animate rotation: smooth interpolation
		local currentRotation = initialRotation + (targetRotation - initialRotation) * progress;
		headOnBlock:SetFacing(currentRotation);
		
		-- Update position to follow pet
		local px, py, pz = entity:GetPosition();
		headOnBlock:SetPosition(px, py + yOffset, pz);
		
		self:Wait(frameTime);
	end
	
	-- Ensure final state
	if headOnBlock and not headOnBlock.isDead then
		headOnBlock:SetScaling(currentScale * targetScale);
		headOnBlock:SetFacing(targetRotation);
	end
end

-- Hide and clean up the head-on block
function CopilotBase:HideHeadOnBlock()
	-- Destroy block entity
	if self.headOnBlock then
		self.headOnBlock:SetDead();
		self.headOnBlock:Destroy();
		self.headOnBlock = nil;
	end
	-- Clear the tracked block ID
	self.headOnBlockId = nil;
	self.headOnBlockData = nil;
end

-- Walk to and create a block at the position, we will play sound and animation. (must be called from within coroutine)
-- if there is already a block at the position, the function will return true immediately
-- @param x, y, z: block position in block coordinates
-- @param blockId: block ID or block name
-- @param data: optional block data value
-- @param buildSpeed: optional build speed multiplier (0.5 to 10, default 1.0)
-- @return true if successful
function CopilotBase:CreateBlock(x, y, z, blockId, data, buildSpeed)
	data = data or 0;
	buildSpeed = buildSpeed or 1.0;
	-- Clamp build speed to reasonable range
	buildSpeed = math.max(0.5, math.min(10.0, buildSpeed));
	
	if type(blockId) == "number" then
		-- Check if block already exists at target position
		local existingBlockId = BlockEngine:GetBlockId(x, y, z);
		if existingBlockId and existingBlockId ~= 0 then
			return true;
		end

		local entity = self:CreateGetEntity();

		local px, py, pz = self:GetFreeBlockPos(x, y, z, true);
		if(px) then
			-- Check current position
			local cx, cy, cz = self:GetBlockPos();
			local isAtTarget = (cx == px and cy == py and cz == pz);
			local distanceSquared = (cx - x) * (cx - x) + (cz - z) * (cz - z) + (cy - y) * (cy - y);
			local isWithinRange = distanceSquared <= 25; -- 5 blocks squared
			
			-- Only walk if not at target and either outside range or need to move
			if not isAtTarget and not isWithinRange then
				self:WalkTo(px, py, pz);
			end
			
			-- Face the target block
			if px ~= x or pz ~= z then
				local ex, ey, ez = entity:GetPosition();
				local tx, ty, tz = BlockEngine:real_bottom(x, y, z);
				local facing = math.atan2(tx - ex, tz - ez) - math.pi/2;
				self:SetFacing(facing);
			end
		end
		self:ShowHeadOnBlock(blockId, data);
		entity:SetAnimation({71, 0})
		
		-- Adjust animation wait time based on build speed
		-- Normal speed: 1.5s, Speed 2: 0.75s, Speed 10: 0.15s
		local animTime = 1.5 / buildSpeed;
		self:Wait(animTime);
		
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateBlockTask.lua");
		local CreateBlock = commonlib.gettable("MyCompany.Aries.Game.Tasks.CreateBlock");
		
		local itemStack = ItemStack:new():Init(blockId, 1);
		itemStack:SetPreferredBlockData(data);

		local task = CreateBlock:new({
			blockX = x,
			blockY = y,
			blockZ = z,
			block_id = blockId,
			itemStack = itemStack,
			data = data,
			isSilent = true,
			--add_to_history = true,
			nohistory = true,
		})
		task:Run();
		if(self.forceAddToEditable) then
			GameLogic.CreateGetEditableWorld():AddEditablePos(x, y, z, true)
		end
		self:HideHeadOnBlock();
		
		-- Adjust post-creation wait time based on build speed
		local postWaitTime = 0.3 / buildSpeed;
		self:Wait(postWaitTime);
		
		-- self:WalkTo(x, z); 
		return true;
	end
	return false;
end

-- Set a block at position without animation (fast build mode)
-- Same as CreateBlock but without animation or movement
-- @param x, y, z: block position in block coordinates
-- @param blockId: block ID or block name
-- @param data: optional block data value
-- @return true if successful
function CopilotBase:SetBlock(x, y, z, blockId, data)
	-- Check if block already exists at target position
	local existingBlockId = BlockEngine:GetBlockId(x, y, z);
	if existingBlockId and existingBlockId ~= 0 then
		return true;
	end
	local entity = self:CreateGetEntity();
	if(entity) then
		local ex, ey, ez = entity:GetBlockPos();
		if(ex == x and ey == y and ez == z) then
			local px, py, pz = self:GetFreeBlockPos(x, y, z, true);
			if(px) then
				self:WalkTo(px, py, pz);
			end
		end
	end
	
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateBlockTask.lua");
	local CreateBlock = commonlib.gettable("MyCompany.Aries.Game.Tasks.CreateBlock");
	local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
	
	local itemStack = ItemStack:new():Init(blockId, 1);
	itemStack:SetPreferredBlockData(data);

	local task = CreateBlock:new({
		blockX = x,
		blockY = y,
		blockZ = z,
		block_id = blockId,
		itemStack = itemStack,
		data = data,
		isSilent = true,
		--add_to_history = true,
		nohistory = true,
	})
	task:Run();

	if(self.forceAddToEditable) then
		GameLogic.CreateGetEditableWorld():AddEditablePos(x, y, z, true)
	end
	
	return true;
end

-- Delete a block at position
-- @param x, y, z: block position in block coordinates
-- @return true if successful
function CopilotBase:DeleteBlock(x, y, z)
	local entity = self:CreateGetEntity();
	local px, py, pz = self:GetFreeBlockPos(x, y, z, true);
	if(px) then
		self:WalkTo(px, py, pz); 
		-- If position changed, face the target block
		if px ~= x or pz ~= z then
			local entity = self:CreateGetEntity();
			local ex, ey, ez = entity:GetPosition();
			local tx, ty, tz = BlockEngine:real_bottom(x, y, z);
			local facing = math.atan2(tx - ex, tz - ez) - math.pi/2;
			self:SetFacing(facing);
		end
	end
	entity:SetAnimation({71, 0})
	self:Wait(1.5);
	
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DestroyBlockTask.lua");
	local DestroyBlock = commonlib.gettable("MyCompany.Aries.Game.Tasks.DestroyBlock");

	local task = DestroyBlock:new({
		blockX = x,
		blockY = y,
		blockZ = z,
		entityPlayer = entity,
		--add_to_history = true,
		nohistory = true,
		donot_drop_item = true
	})
	task:Run();
	self:Wait(0.3);
	return true;
end

-- Create a live entity from XML data with smooth animation
-- @param entityData: entity XML node data (format from BlockTemplate liveEntities)
-- @param targetX, targetY, targetZ: final position in world coordinates, if nil, it will use the position in entityData
-- @param buildSpeed: optional speed multiplier for animation (default 1.0)
-- @return created entity or nil if failed
function CopilotBase:CreateLiveModel(entityData, targetX, targetY, targetZ, buildSpeed)
	if not entityData then
		return nil;
	end
	targetX = targetX or entityData.attr.x;
	targetY = targetY or entityData.attr.y;
	targetZ = targetZ or entityData.attr.z;
	if(not targetX or not targetY or not targetZ) then
		return nil;
	end
	
	buildSpeed = buildSpeed or 1.0;
	
	local entity = self:GetEntity();
	if not entity then
		return nil;
	end
	
	-- Walk towards target if too far
	local copilotX, copilotY, copilotZ = entity:GetPosition();
	local distance = math.sqrt((targetX - copilotX)^2 + (targetY - copilotY)^2 + (targetZ - copilotZ)^2);
	
	if distance > 6.0 then
		-- Calculate walk position (3 meters away from target)
		local dx = targetX - copilotX;
		local dy = targetY - copilotY;
		local dz = targetZ - copilotZ;
		local length = math.sqrt(dx*dx + dy*dy + dz*dz);
		
		if length > 0 then
			local walkDistance = distance - 3.0;
			local walkX = copilotX + (dx / length) * walkDistance;
			local walkY = targetY;
			local walkZ = copilotZ + (dz / length) * walkDistance;
			
			local walkBX, walkBY, walkBZ = BlockEngine:block(walkX, walkY + 0.1, walkZ);
			self:WalkTo(walkBX, walkBY, walkBZ);
			copilotX, copilotY, copilotZ = entity:GetPosition();
		end
	end
	
	-- Face the target
	entity:SetFacing(math.atan2(targetX - copilotX, targetZ - copilotZ) - math.pi/2);
	
	-- Create entity at copilot position
	local showHeight = entity:GetHeight() + 0.2;
	local tempEntityData = commonlib.copy(entityData);
	tempEntityData.attr.x = copilotX;
	tempEntityData.attr.y = copilotY + showHeight;
	tempEntityData.attr.z = copilotZ;
	
	local createdEntity = EntityManager.CreateEntityFromXMLNode(tempEntityData);
	if not createdEntity then
		return nil;
	end
	
	-- Setup initial state
	local initialScale = 0.1;
	local targetScale = entityData.attr.scale or 1.0;
	createdEntity:SetScaling(initialScale);
	createdEntity:SetPersistent(false);
	createdEntity:SetDummy(true);
	
	if entity then
		createdEntity:SetFacing(entity:GetFacing());
	end
	
	createdEntity:Attach();
	
	-- Animate scale and rotation
	local baseAnimationDuration = 4.0;
	local animationDuration = baseAnimationDuration / buildSpeed;
	local frameTime = 0.03;
	local totalFrames = math.ceil(animationDuration / frameTime);
	
	local targetFacing = entityData.attr.facing or 0;
	local currentFacing = createdEntity:GetFacing();
	
	for frame = 1, totalFrames do
		if self:IsTaskStopped() or createdEntity.isDead then
			break;
		end
		
		local progress = frame / totalFrames;
		local easeProgress = 1 - math.pow(1 - progress, 3);
		
		-- Animate scale
		local currentScale = initialScale + (targetScale - initialScale) * easeProgress;
		createdEntity:SetScaling(currentScale);
		
		-- Animate rotation
		local newFacing = currentFacing + (targetFacing - currentFacing) * easeProgress;
		createdEntity:SetFacing(newFacing);
		
		self:Wait(frameTime);
	end
	
	-- Set final scale and facing
	createdEntity:SetScaling(targetScale);
	createdEntity:SetFacing(targetFacing);
	
	-- Animate movement to target position
	local baseMoveDuration = 1.0;
	local moveDuration = baseMoveDuration / buildSpeed;
	local moveFrames = math.ceil(moveDuration / frameTime);
	
	local startX, startY, startZ = createdEntity:GetPosition();
	
	for frame = 1, moveFrames do
		if self:IsTaskStopped() or createdEntity.isDead then
			break;
		end
		
		local progress = frame / moveFrames;
		local easeProgress = progress < 0.5 
			and 2 * progress * progress 
			or 1 - math.pow(-2 * progress + 2, 2) / 2;
		
		local currentX = startX + (targetX - startX) * easeProgress;
		local currentY = startY + (targetY - startY) * easeProgress;
		local currentZ = startZ + (targetZ - startZ) * easeProgress;
		
		createdEntity:SetPosition(currentX, currentY, currentZ);
		
		self:Wait(frameTime);
	end
	
	-- Set final position
	createdEntity:SetPosition(targetX, targetY, targetZ);
	createdEntity:SetPersistent(true);
	createdEntity:SetDummy(false);

	if(self.forceAddToEditable) then
		GameLogic.CreateGetEditableWorld():AddLiveEntity(createdEntity)
	end

	self:Wait(0.2 / buildSpeed);
	
	return createdEntity;
end

function CopilotBase:AbortLLM()
	if(self.ai_chat) then
		self.ai_chat:Abort();
		self.llm_finished = true;
		self.llm_queue = nil;
		-- if we are waiting in GetStreamedLLMResult, we should resume it so it can return false
		if(self.llm_wait_coroutine) then
			local co = self.llm_wait_coroutine;
			self.llm_wait_coroutine = nil;
			self:Resume();
		end
	end
end

-- @param options: {stream=boolean, images=string, knowledge=string}
function CopilotBase:CallLLM(input, options)
	options = options or {};
	self.ai_chat = self.ai_chat or AIChat:new();
	self.ai_chat:Abort(); -- abort previous
	if options and options.needOfficialTools then
		EasyAIChatTools.RegisterMQTTTools(self.ai_chat);
		EasyAIChatTools.RegisterPersonalPageTools(self.ai_chat);
		EasyAIChatTools.RegisterSchedulerTools(self.ai_chat);
	end
	
	self.llm_queue = {
		items = {},
		push = function(q, item) table.insert(q.items, item) end,
		pop = function(q) return table.remove(q.items, 1) end,
		empty = function(q) return #q.items == 0 end
	};
	self.llm_finished = false;
	self.llm_wait_coroutine = nil;
	self.llm_line_buffer = "";
	self.llm_last_full_result = "";
	
	local is_streaming = options.stream;
	if(is_streaming == nil) then is_streaming = false end
	
	self.ai_chat:SetStream(is_streaming);
	
	local co = coroutine.running();
	
	if(not is_streaming) then
		-- Non-streaming: wait for result
		local final_result = nil;
		self.llm_wait_coroutine = co;
		
		self.ai_chat:Ask(input, function(resultCode, delta, deltaThink, fullResult, fullThink)
			if(resultCode) then
				final_result = fullResult;
				self.llm_finished = true;
				if(self.llm_wait_coroutine == co) then
					self.llm_wait_coroutine = nil;
					self:Resume();
				end
			end
		end, options);
		
		self:Yield();
		return final_result;
	else
		-- Streaming: return immediately
		self.ai_chat:Ask(input, function(resultCode, delta, deltaThink, fullResult, fullThink)
			if(delta and delta~="") then
				if(self.llm_queue) then
					self.llm_queue:push({delta=delta, fullResult=fullResult});
					if(self.llm_wait_coroutine) then
						local wait_co = self.llm_wait_coroutine;
						self.llm_wait_coroutine = nil;
						self:Resume();
					end
				end
			end
			
			if(resultCode) then
				self.llm_finished = true;
				if(self.llm_wait_coroutine) then
					local wait_co = self.llm_wait_coroutine;
					self.llm_wait_coroutine = nil;
					self:Resume();
				end
			end
		end, options);
		return;
	end
end

-- @param bLineByLine: if true, returns delta one line at a time. delta is the full line content without \r?\n.
-- @return: delta, fullResult; or false if finished
function CopilotBase:GetStreamedLLMResult(bLineByLine)
	if(not self.llm_queue) then return false end
	
	if(bLineByLine) then
		self.llm_line_buffer = self.llm_line_buffer or "";
		while true do
			-- Check if we have a full line in buffer
			local line, rest = self.llm_line_buffer:match("^(.-)\r?\n(.*)$")
			if line then
				self.llm_line_buffer = rest
				return line, self.llm_last_full_result or ""
			end

			-- If queue is empty
			if self.llm_queue:empty() then
				if self.llm_finished then
					if self.llm_line_buffer ~= "" then
						local line = self.llm_line_buffer
						self.llm_line_buffer = ""
						return line, self.llm_last_full_result or ""
					else
						return false
					end
				else
					-- Wait for more data
					self.llm_wait_coroutine = coroutine.running();
					self:Yield();
					if(not self.llm_queue) then return false end -- aborted
				end
			else
				-- Consume queue
				local item = self.llm_queue:pop();
				self.llm_line_buffer = self.llm_line_buffer .. (item.delta or "")
				self.llm_last_full_result = item.fullResult
			end
		end
	else
		if(not self.llm_queue:empty()) then
			local item = self.llm_queue:pop();
			return item.delta, item.fullResult;
		end
		
		if(self.llm_finished) then
			return false;
		end
		
		-- Wait for more data
		self.llm_wait_coroutine = coroutine.running();
		self:Yield();
		
		-- Resumed
		if(not self.llm_queue or self.llm_queue:empty()) then
				if(self.llm_finished) then return false end
				return "", ""; 
		end
		
		local item = self.llm_queue:pop();
		return item.delta, item.fullResult;
	end
end

-- Load page data from PersonalPageStore
function CopilotBase:LoadPageData(pagename, key)
	if not pagename or not key then
		LOG.std(nil, "warn", "CopilotBase", "LoadPageData: pagename and key cannot be nil");
		return nil;
	end
	
	local result = nil;
	local isDone = false;
	
	if PersonalPageStore then
		PersonalPageStore:LoadPageData(pagename, key, function(data)
			result = data;
			isDone = true;
			
			if self.runningTask and self.runningTask.taskInstance then
				local task = self.runningTask.taskInstance
				if task.co and coroutine.status(task.co) == "suspended" then
					self:Resume();
				end
			end
		end);
	else
		isDone = true;
	end
	
	if not isDone then
		self:Yield();
	end
	return result;
end

-- Save page data to PersonalPageStore
function CopilotBase:SavePageData(pagename, key, value, bFlush)
	if not pagename or not key then
		LOG.std(nil, "warn", "CopilotBase", "SavePageData: pagename and key cannot be nil");
		return;
	end
	PersonalPageStore:SavePageData(pagename, key, value, bFlush);
end

-- add a commond function to receive data to runningTask
function CopilotBase:ReceiveDataToRunningTask(data)
	if not self.runningTask then return end
	if self.runningTask.taskInstance and self.runningTask.taskInstance.ReceiveData then
		self.runningTask.taskInstance:ReceiveData(data)
	end
end