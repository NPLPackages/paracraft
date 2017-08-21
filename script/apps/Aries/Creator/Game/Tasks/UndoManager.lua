--[[
Title: Undo Manager
Author(s): LiXizhi
Date: 2013/1/20
Desc: undo/redo the last block operation. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
UndoManager.PushCommand(cmd)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL.lua");
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")

local UndoManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.UndoManager"));

local max_history = 100;
local undo_list = commonlib.List:new();
local redo_list = commonlib.List:new();

-- whenever a new command is added
UndoManager:Signal("commandAdded");

-- add a new cmd(Task) to the undo manager
-- @param cmd: the cmd must implement the cmd.Undo and cmd.Redo method. 
--  if not, the cmd will be escaped during undo or redo operation. 
function UndoManager.PushCommand(cmd)
	if(type(cmd) == "table") then
		redo_list:clear();
		undo_list:push_back({cmd});
		
		UndoManager:commandAdded(); -- signal

		if(undo_list:size() > max_history) then
			undo_list:remove(undo_list:first());
		end
	end
end
UndoManager.Add = UndoManager.PushCommand; -- shortcut name

function UndoManager.Clear()
	undo_list:clear();
	redo_list:clear();
end

function UndoManager.Undo()
	local cmd = undo_list:last()
	if(cmd) then
		if(cmd[1].Undo) then
			cmd[1]:Undo();
		end
		undo_list:remove(cmd);
		redo_list:push_back(cmd);
	end
end

function UndoManager.Redo()
	local cmd = redo_list:last()
	if(cmd) then
		if(cmd[1].Redo) then
			cmd[1]:Redo();
		end
		redo_list:remove(cmd);
		undo_list:push_back(cmd);
	end
end

UndoManager:InitSingleton();