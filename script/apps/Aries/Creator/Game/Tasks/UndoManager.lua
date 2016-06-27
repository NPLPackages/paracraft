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
NPL.load("(gl)script/ide/TooltipHelper.lua");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")

local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");

local max_history = 100;
local inform_save_count = 15;
local last_save_inform_count = 1;
local undo_list = commonlib.List:new();
local redo_list = commonlib.List:new();

-- add a new cmd(Task) to the undo manager
-- @param cmd: the cmd must implement the cmd.Undo and cmd.Redo method. 
--  if not, the cmd will be escaped during undo or redo operation. 
function UndoManager.PushCommand(cmd)
	if(type(cmd) == "table") then
		redo_list:clear();
		undo_list:push_back({cmd});

		last_save_inform_count = last_save_inform_count + 1;
		if(last_save_inform_count > inform_save_count) then
			last_save_inform_count = 1;
			if(not GameLogic.IsRemoteWorld()) then
				if(System.options.IsMobilePlatform) then
					BroadcastHelper.PushLabel({id="UndoManager", label = L"记得保存你的世界～", max_duration=5000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
				else
					BroadcastHelper.PushLabel({id="UndoManager", label = L"记得保存你的世界哦～(Ctrl+S)", max_duration=5000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
				end
			end
		end
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
