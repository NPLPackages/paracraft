--[[
Title: Task Base Class
Author(s): LiXizhi
Date: 2013/1/19
Desc: Task is a special command which is instanced for each invocation and optionally provide undo/redo function. 
Task can be used just like normal command, however, unlike normal command, 
task usually take some time to execute and may require user inputs in order to execute. 
Task can has its own SceneContext and UI for user input. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Task.lua");
-- define a new task class
local MyTask = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.MyTask"));

-- Example1: invoke task
local task = MyTask:new();
task:Run();

-- Example2: handling key/mouse event
-- one must turn this on to use scene context or call LoadSceneContext() manually
MyTask:Property({"bUseSceneContext", true, "IsUseSceneContext", "SetUseSceneContext", auto=true});

-- see: RedirectContext.lua for all key/mouse overridable events
function MyTask:keyPressEvent(event)
	if(event:isAccepted()) then
		return
	end
	event:accept(); -- this line disables all events
end

local task = MyTask:new();
task:Run();
task:GetSceneContext():EnableAutoCamera(false); -- disable WASD keys
-- task:SetFinished(); -- call this to quit task
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TaskManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Command.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local Task = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Command"), commonlib.gettable("MyCompany.Aries.Game.Task"));
Task:Property({"bUseSceneContext", false, "IsUseSceneContext", "SetUseSceneContext", auto=true});

-- @param id: uint16 type. need to be larger than 1024 if not system type. 
function Task:ctor()
end

-- virtual function
function Task:FrameMove()
	self:SetFinished();
end

-- a task call this function once finished. OnExit will be automatically called by task manager. 
function Task:SetFinished()
	self.finished = true;
end

-- virtual function: this is the main body of the task command
function Task:Run()
	-- call this to use current object as scene context. 
	if(self:IsUseSceneContext()) then
		self:LoadSceneContext();
	end
	
	TaskManager.AddTask(self);
end

-- virtual function: this function is only called, if one calls self:LoadSceneContext() in self:Run()
function Task:UpdateManipulators()
	self:DeleteManipulators();
	-- TODO: add one or more manipulators here 
end

function Task:DeleteManipulators()
	if(self.sceneContext) then
		self.sceneContext:DeleteManipulators();
	end
end

function Task:AddManipulator(manipContainer)
	if(manipContainer) then
		self.sceneContext:AddManipulator(manipContainer);
	end
end

-- virtual: automatically called by task manager when task is marked as finished. 
function Task:OnExit()
	self:UnloadSceneContext();
	self:CloseWindow();
end

-- Redirect this object as a scene context, so that it will receive all key/mouse events from the scene. 
-- as if this task object is a scene context derived class. One can then overwrite
-- `UpdateManipulators` function to add any manipulators. 
function Task:LoadSceneContext()
	self.sceneContext = self.sceneContext or Game.SceneContext.RedirectContext:new():RedirectInput(self);
	self.sceneContext:activate();
	self.sceneContext:UpdateManipulators();
end

function Task:UnloadSceneContext()
	if(self.sceneContext) then
		self.sceneContext:close();
		self.sceneContext = nil;
	end
end

function Task:GetSceneContext()
	return self.sceneContext;
end

-- create get tool window, one can then show the window with mcml content
function Task:CreateGetToolWindow()
	if(not self.window) then
		NPL.load("(gl)script/ide/System/Windows/Window.lua");
		local Window = commonlib.gettable("System.Windows.Window");
		local window = Window:new();
		self.window = window;
	end
	return self.window;
end

-- close and destroy the tool window
function Task:CloseWindow()
	if(self.window) then
		self.window:destroy();
		self.window = nil;
	end
end

-- hide the tool window without destroying it
function Task:HideWindow()
	if(self.window) then
		self.window:hide();
	end
end

-- add to undo manager
function Task:AddToUndoManager()
	UndoManager.PushCommand(self);
end

