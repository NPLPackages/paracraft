--[[
Title: Task Manager
Author(s): LiXizhi
Date: 2013/1/19
Desc: Task is a special command which is instanced for each invocation and optionally provide undo/redo function. 
Task can be used just like normal command, however, unlike normal command, 
task usually take some time to execute and may require user inputs in order to execuate. 

TaskManager is a special SceneContext that manages a stack of task commands, 
as well as user events passed to current active task. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TaskManager.lua");
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
TaskManager.FrameMove();

TaskManager.AddTask(task)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL.lua");
NPL.load("(gl)script/apps/Aries/SlashCommand/Command.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local Task = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Command"), commonlib.gettable("MyCompany.Aries.Game.Task"));

local task_list = commonlib.List:new();
local exclusive_task_list = commonlib.List:new();
local top_level_task = nil;

-- called in the framemove. 
function TaskManager.FrameMove()
	-- top level task
	if(top_level_task) then
		if(not top_level_task.finished) then
			top_level_task:FrameMove();
		end
		if(top_level_task.finished) then
			if(top_level_task.OnExit) then
				top_level_task:OnExit();
			end
			top_level_task = nil;
		end
		return;
	end

	-- for exclusive tasks
	local task = exclusive_task_list:first();
	while (task) do
		task:FrameMove();
		if(task.finished) then
			task = exclusive_task_list:remove(task);
		else
			task = exclusive_task_list:next(task)
		end
	end

	-- normal tasks are only executed after exclusive ones. 
	if(exclusive_task_list:size() == 0) then
		local task = task_list:first();
		while (task) do
			task:FrameMove();

			if(task.finished) then
				task = task_list:remove(task);
			else
				task = task_list:next(task)
			end
		end
	end
end

function TaskManager.RemoveTask(task)
	if(task == top_level_task) then
		if(top_level_task.OnExit) then
			top_level_task:OnExit();
		end
		top_level_task = nil;
	else
		-- TODO:
	end
end

function TaskManager.Clear()
	task_list:clear();
	exclusive_task_list:clear();

	if(top_level_task) then
		if(top_level_task.OnExit) then
			top_level_task:OnExit();
		end
		top_level_task = nil;
	end
end

-- @param task: if task.is_exclusive == true, all other non-exclusive task must hold until all exclusive tasks are finished. 
-- if task.is_top_level is true, it will a top level task, all other tasks are suspended. 
-- @return true if successfully added. please note that top level task may fail if there is already an top level task. 
function TaskManager.AddTask(task)
	if(not task.ctor) then
		task = Task:new(task);
	end
	if(task.is_top_level) then
		if(not top_level_task) then
			top_level_task = task;
			return true;
		end
	elseif(task.is_exclusive) then
		exclusive_task_list:add(task);
		return true;
	else
		task_list:add(task);
		return true;
	end
end

function TaskManager.GetTopLevelTask()
	return top_level_task;
end

---------------------------------
-- base task class
---------------------------------
-- @param id: uint16 type. need to be larger than 1024 if not system type. 
function Task:ctor()
end

function Task:FrameMove()
	self.finished = true;
end

function Task:Run()
	TaskManager.AddTask(self);
end


