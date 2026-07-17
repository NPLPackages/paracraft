--[[
Title: CopilotTaskBase
Author(s): LiXizhi
Date: 2025/11/14
Desc: Base class for EasyPetCopilot tasks. Provides shared functionality for task lifecycle,
state management, coroutine execution, and progress tracking.

All copilot tasks should inherit from this base class and implement the ExecuteTask() method.

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotTaskBase.lua");
local CopilotTaskBase = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotTaskBase");

-- use simple copilot directly.
local task = CopilotTaskBase:new():Init(copilot, function(copilot)

end);

-- Create a custom task by inheriting from CopilotTaskBase
local MyTask = commonlib.inherit(CopilotTaskBase, commonlib.gettable("MyCompany.MyTask"));

-- ExecuteTask receives the copilot instance if it was provided during Init
function MyTask:ExecuteTask(copilot)
    -- Implement your task logic here
    for i = 1, 10 do
        if self:CheckStopRequested() then
            return;
        end
        
        self:CheckPaused();
        
        -- Do work here
        -- Access copilot if needed: copilot:ComeHere(), copilot:CreateBlock(...), etc.
        
        self:UpdateProgress(i, 10);
    end
end

-- Usage example:
local copilot = EasyPetCopilot.GetInstance();
local task = MyTask:new():Init(copilot, {param1 = "value1"});
copilot:AddTask(task, {name = "My Task", enabled = true, allowUserPause=true, allowUserStop=true});
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local CopilotTaskBase = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotTaskBase"));

CopilotTaskBase:Signal("taskStopped")
CopilotTaskBase:Signal("taskCompleted")

-- Task state constants
CopilotTaskBase.STATE_IDLE = "idle";
CopilotTaskBase.STATE_PREPARING = "preparing";
CopilotTaskBase.STATE_RUNNING = "running";
CopilotTaskBase.STATE_PAUSED = "paused";
CopilotTaskBase.STATE_COMPLETED = "completed";
CopilotTaskBase.STATE_FAILED = "failed";

-- Default values
CopilotTaskBase.state = CopilotTaskBase.STATE_IDLE;
CopilotTaskBase.progress = 0;
CopilotTaskBase.copilotTaskId = nil; -- assigned when added to copilot
-- Constructor
function CopilotTaskBase:ctor()
	self.copilot = nil;
	self.copilotFunc = nil;
	self.state = self.STATE_IDLE;
	self.isAccepted = false;
	self.inGuide = false;
	self.progress = 0;
	self.co = nil;
	self.stopRequested = false;
	self.needPrepare = false;
	-- Whether the copilot should automatically remove this task from the copilot's queue
	-- when the task is stopped (completed/failed/canceled). Default true for backwards compatibility.
	self.autoRemoveWhenStopped = true;
	self.allowUserStop = true;
	self.allowUserPause = true;
	self.taskResult = nil;
end

-- Initialize the task with parameters
-- @param copilot: reference to the EasyPetCopilot
-- @param copilotFunc: function or params
-- @return self for chaining
function CopilotTaskBase:Init(copilot, copilotFunc)
    self.copilot = copilot;
	if(type(copilotFunc) == "function") then
		self.copilotFunc = copilotFunc;
	else
		self.params = copilotFunc;
	end	
	self.state = self.STATE_IDLE;
	self.progress = 0;
	self.co = nil;
	self.stopRequested = false;
	return self;
end

-- Virtual function called when the task is removed from the copilot's queue
function CopilotTaskBase:OnRemove()
end

-- Virtual function called when user sends a message via EasyAIChat
-- Tasks can override this to process specific messages and take control
-- @param text: string message sent by the user
-- @return handled: boolean, true if the message was handled
-- @return replyText: string, optional reply text to append to chat history
function CopilotTaskBase:OnChatMessage(text)
	return false, nil;
end

-- Start or resume the task
-- @return success: boolean, true if task started/resumed successfully
-- @return err: string, error message if failed
function CopilotTaskBase:Start()

	if self.state == self.STATE_IDLE then
		-- Create new coroutine for task execution
        self.co = coroutine.create(function()
            -- Run ExecuteTask with error handling
            local ok, err = xpcall(function()
				if self.needPrepare then
					self.state = self.STATE_PREPARING
					LOG.std(nil, "info", "CopilotTask", "Task preparing: %s", self:GetTaskName());
					local prepOk = self:DoPrepare(self.copilot)
					if not prepOk then
						-- Preparation failed or stopped
						if self.state ~= self.STATE_FAILED and self.state ~= self.STATE_CANCELED then
							self.state = self.STATE_FAILED
						end
						return
					end
				end

				self.state = self.STATE_RUNNING
				LOG.std(nil, "info", "CopilotTask", "Task executing: %s", self:GetTaskName());

                self:ExecuteTask(self.copilot);
				if(self.state ~= self.STATE_FAILED and self.state ~= self.STATE_CANCELED) then
					self.state = self.STATE_COMPLETED;
					self:taskCompleted();
				end
            end, function(msg)
                -- Safe error handler that won't fail
                local err_msg = tostring(msg or "unknown error");
                local stack_trace = "";
                
                -- Safely get stack trace
                local success, trace = pcall(debug.traceback);
                if success and trace then
                    stack_trace = "\n" .. tostring(trace);
                end
                
                return err_msg .. stack_trace;
            end);
            
            if not ok then
                local err_str = tostring(err or "unknown error");
                LOG.std(nil, "error", "CopilotTask", "Task execution error: %s - %s", 
                    self:GetTaskName(), err_str);
                
                -- Mark task as failed
                self.state = self.STATE_FAILED;
                
                -- Print full stack info to log
                LOG.std(nil, "error", "CopilotTask", "Full stack trace:\n%s", err_str);
            end
		end);
		self.state = self.STATE_RUNNING;
		LOG.std(nil, "info", "CopilotTask", "Task started: %s", self:GetTaskName());
	end
	
	return self:Resume();
end

-- Pause the task execution
function CopilotTaskBase:Pause()
	if self.state == self.STATE_RUNNING or self.state == self.STATE_PREPARING then
		self.prePauseState = self.state;
		self.state = self.STATE_PAUSED;
		if self.copilot then
			self.copilot:taskChanged(self, "paused");
		end
		LOG.std(nil, "info", "CopilotTask", "Task paused: %s", self:GetTaskName());
	end
end

-- Resume the task execution (internal method, called by Start)
-- @return success: boolean, true if resumed successfully
-- @return err: string, error message if failed
function CopilotTaskBase:Resume()
	if not self.co then
		return false, "No coroutine to resume";
	end
	
	-- Allow resuming from both PAUSED and RUNNING states (and PREPARING)
	if self.state ~= self.STATE_RUNNING and self.state ~= self.STATE_PAUSED and self.state ~= self.STATE_PREPARING then
		return false, "Task is not in running or paused state";
	end
	
	-- Change state from PAUSED to RUNNING before resuming
	if self.state == self.STATE_PAUSED then
		self.state = self.prePauseState or self.STATE_RUNNING;
		LOG.std(nil, "info", "CopilotTask", "Task resumed from pause: %s", self:GetTaskName());
		if self.copilot then
			self.copilot:taskChanged(self, "resumed");
		end
	end
	
	local success, err = coroutine.resume(self.co);
	
	if not success then
		self.state = self.STATE_FAILED;
		LOG.std(nil, "error", "CopilotTaskBase", "Task failed: %s - %s", self:GetTaskName(), tostring(err));
		return false, err;
	end
	return true;
end

-- Stop the task execution
function CopilotTaskBase:Stop()
	self.stopRequested = true;
	self.state = self.STATE_IDLE;
	self.inGuide = false;
	
	self.co = nil;
	self.progress = 0;
	
	LOG.std(nil, "info", "CopilotTaskBase", "Task stopped: %s", self:GetTaskName());
	
	-- Fire the taskStopped signal
	self:taskStopped();
	
	-- If requested, ask the copilot to remove this task from its queue.
	-- Use a guard to avoid recursion if RemoveTask calls Stop() again.
	if not self._removing and self.autoRemoveWhenStopped and self.copilot and type(self.copilot.RemoveTask) == "function" and self.copilotTaskId then
		self._removing = true;
		-- Attempt to remove from copilot's queue. RemoveTask is safe to call even if the task is running.
		self.copilot:RemoveTask(self.copilotTaskId, true);
		self._removing = false;
	end
end

-- Virtual function for task preparation
-- Returns true if preparation is done and task can proceed
-- Returns false if preparation failed
function CopilotTaskBase:DoPrepare(copilot)
	return true;
end

function CopilotTaskBase:FinishPreparation()
end

-- Main task execution logic (must be implemented by subclasses)
-- This method runs in a coroutine and should:
-- 1. Check self.stopRequested periodically
-- 2. Check for self.state == STATE_PAUSED and yield while paused
-- 3. Update self.progress (0.0 to 1.0)
-- 4. Call coroutine.yield() to prevent blocking
-- 5. Set self.state to STATE_COMPLETED or STATE_FAILED when done
function CopilotTaskBase:ExecuteTask(copilot)
	-- If copilotFunc is provided (for simple tasks), execute it
	if type(self.copilotFunc) == "function" then
		self.copilotFunc(copilot);
		self.state = self.STATE_COMPLETED;
		return;
	end
	
	-- Otherwise, this should be overridden by subclasses
	LOG.std(nil, "warn", "CopilotTaskBase", 
		"ExecuteTask() not implemented in subclass: %s", self:GetTaskName());
	self.state = self.STATE_FAILED;
end

-- virtual functions to be overridden by subclasses
-- this function is called when the entity is clicked when current task is running
-- the function should return immediately
function CopilotTaskBase:OnClick(copilot)
end


-- Get the task name (can be overridden by subclasses)
-- @return string: task name for logging
function CopilotTaskBase:GetTaskName()
	return self.name or "CopilotTask";
end

-- Get current task status
-- @return table: status information {state, progress, isRunning, isPaused, isCompleted, isFailed}
function CopilotTaskBase:GetStatus()
	return {
		state = self.state,
		progress = self.progress,
		isRunning = self.state == self.STATE_RUNNING,
		isPaused = self.state == self.STATE_PAUSED,
		isCompleted = self.state == self.STATE_COMPLETED,
		isFailed = self.state == self.STATE_FAILED,
		isAccepted = self.isAccepted,
	};
end

-- Virtual function to get action buttons based on current task state.
-- Each button is a table with at least {text = string, name = string}.
-- Example returned value: { {text="建造快一点", name="buildQuicker"}, ... }
-- These buttons allow UI or callers to present interactive actions to the user
-- before or during task execution.
-- @param buttons: optional existing button list to append to
function CopilotTaskBase:GetActionButtons(buttons)
	buttons = buttons or {};

	if self.state == self.STATE_IDLE then
		table.insert(buttons, {text = L"开始任务", name = "start"});
	elseif self.state == self.STATE_RUNNING then
		if self.allowUserPause then
			table.insert(buttons, {text = L"暂停", name = "pause"});
		end
		if self.allowUserStop then
			table.insert(buttons, {text = L"停止", name = "stop"});
		end
	elseif self.state == self.STATE_PAUSED then
		table.insert(buttons, {text = L"继续", name = "resume", default = true});
		if self.allowUserStop then
			table.insert(buttons, {text = L"停止", name = "stop"});
		end
	end
	return buttons;
end

-- virtual function to handle action button clicks
function CopilotTaskBase:OnClickActionButton(name)
	if(name == "start") then
		return self:Start();
	elseif(name == "resume") then
		self:OnResumeByUser()
		self.copilot:OnResumeByUser()
		return self:Resume();
	elseif(name == "pause") then
		self:OnPauseByUser()
		self.copilot:OnPauseByUser()
		return self:Pause();
	elseif(name == "stop") then
		self:OnStopByUser()
		self.copilot:OnStopByUser()
		return self:Stop();
	end
end

-- virtual function called when user requests resume
function CopilotTaskBase:OnResumeByUser()
end

-- virtual function called when user requests pause
function CopilotTaskBase:OnPauseByUser()
end

-- virtual function called when user requests stop
function CopilotTaskBase:OnStopByUser()
end

-- Check if task can be resumed
-- @return boolean: true if task is in a resumable state
function CopilotTaskBase:CanResume()
	return self.state == self.STATE_PAUSED or self.state == self.STATE_RUNNING;
end

-- Check if task is finished (completed or failed)
-- @return boolean: true if task is finished
function CopilotTaskBase:IsFinished()
	return self.state == self.STATE_COMPLETED or self.state == self.STATE_FAILED;
end

function CopilotTaskBase:IsFailed()
    return self.state == self.STATE_FAILED;
end

-- Check if task is active (running or paused or preparing)
-- @return boolean: true if task is active
function CopilotTaskBase:IsActive()
	return self.state == self.STATE_RUNNING or self.state == self.STATE_PAUSED or self.state == self.STATE_PREPARING;
end
function CopilotTaskBase:IsRunning()
	return self.state == self.STATE_RUNNING or self.state == self.STATE_PREPARING;
end

-- Get the task result
-- @return any: the result of the task execution
function CopilotTaskBase:GetTaskResult()
    return self.taskResult;
end

function CopilotTaskBase:SetTaskResult(result)
    self.taskResult = result;
end

-- Reset the task to initial state
function CopilotTaskBase:Reset()
	self.state = self.STATE_IDLE;
	self.progress = 0;
	self.co = nil;
	self.stopRequested = false;
	LOG.std(nil, "info", "CopilotTaskBase", "Task reset: %s", self:GetTaskName());
end

-- Helper: Check if stop was requested and handle it
-- Subclasses can call this in their ExecuteTask() implementation
-- @return boolean: true if stop was requested
function CopilotTaskBase:CheckStopRequested()
	if self.stopRequested then
		LOG.std(nil, "info", "CopilotTaskBase", "Task stopped by request: %s", self:GetTaskName());
		self.state = self.STATE_FAILED;
		return true;
	end
	return false;
end

-- Helper: Check if paused and yield while paused
-- Subclasses can call this in their ExecuteTask() implementation
function CopilotTaskBase:CheckPaused()
	while self.state == self.STATE_PAUSED do
		coroutine.yield();
	end
end

-- Helper: Update progress and yield
-- Subclasses can call this in their ExecuteTask() implementation
-- @param current: current step number
-- @param total: total steps
function CopilotTaskBase:UpdateProgress(current, total)
	self.progress = current / total;
end


-- Helper: Start and wait for a subtask to complete (This function is called in co-routine)
-- This will start a subtask, wait for it to complete, and when that task. 
-- the sub task will share the same coroutine context as the parent task. When the subtask
-- is stopped or finished, return control back to the parent task.
-- @param subTask: the subtask instance to run (should be a CopilotTaskBase or derived class)
-- @return success: boolean, true if subtask completed successfully
function CopilotTaskBase:StartSubTask(subTask)
	if not subTask then
		LOG.std(nil, "warn", "CopilotTaskBase", "StartSubTask called with nil subtask");
		return false;
	end
	
	-- inherit context
	subTask.parentTask = self;
	subTask.co = self.co;
	subTask.copilot = self.copilot;
	subTask.state = self.STATE_RUNNING;
	
	local ok, err = xpcall(function()
		subTask:ExecuteTask(self.copilot);
	end, debug.traceback);
	
	-- clear coroutine reference when subtask is finished
	subTask.co = nil;
	
	if not ok then
		subTask.state = self.STATE_FAILED;
		LOG.std(nil, "error", "CopilotTask", "SubTask execution error: %s", tostring(err));
		return false;
	else
		if subTask.state ~= self.STATE_FAILED and subTask.state ~= self.STATE_CANCELED then
			subTask.state = self.STATE_COMPLETED;
		end
		return subTask.state == self.STATE_COMPLETED;
	end
end


function CopilotTaskBase:ReceiveData(data)
	self.receivedData = data;
end

function CopilotTaskBase:WalkTo(x, y, z, walkSpeed, needFreePos)
	if needFreePos then
		local px, py, pz = self.copilot:GetFreeBlockPos(x, y, z, true);
		if px and py and pz then
			x, y, z = px, py, pz;
		else
			LOG.std(nil, "warn", "CopilotTaskBase", "WalkTo failed: no free position found");
		end
	end
    self.copilot:WalkTo(x, y, z, walkSpeed);
end

function CopilotTaskBase:Say(text, duration)
    self.copilot:Say(text, duration);
end