--[[
Title: 
Author: leio
Date: 2020/5/21
Desc: 
-----------------------------------------------
local TeachingQuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestPage.lua");
TeachingQuestPage.ShowPage();
-----------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestMessage.lua");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local TeachingQuestMessage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestMessage.lua");

local TeachingQuestPage = NPL.export();
TeachingQuestPage.MainWorldId = "10373";
TeachingQuestPage.quests = {}
TeachingQuestPage.taskCallback = {}
TeachingQuestPage.currentType = "program";
TeachingQuestPage.currentIndex = 1;

local page;
function TeachingQuestPage.OnInit()
	page = document:GetPageCtrl();
end
function TeachingQuestPage.ShowPage(type)
	TeachingQuestPage.currentType = type;
	TeachingQuestPage.Current_Item_DS = TeachingQuestPage.quests[TeachingQuestPage.TaskTypeToIndex(type)];

	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestPage.html",
		name = "TeachingQuestPage.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		enable_esc_key = true,
		zorder = -1,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
		align = "_ct",
		x = -650 / 2,
		y = -430 / 2,
		width = 650,
		height = 430,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	page:SetValue("TaskType", type);
end
function TeachingQuestPage.AddTasks(tasks, type)
	TeachingQuestPage.quests[TeachingQuestPage.TaskTypeToIndex(type)] = tasks;
	TeachingQuestPage.taskCallback[TeachingQuestPage.TaskTypeToIndex(type)](true);
end

function TeachingQuestPage.RegisterTasksChanged(callback, type)
	TeachingQuestPage.taskCallback[TeachingQuestPage.TaskTypeToIndex(type)] = callback;
end

function TeachingQuestPage.GetCurrentSelectTask(index)
	index = index or TeachingQuestPage.currentIndex;
	if (TeachingQuestPage.currentType and index) then
		return TeachingQuestPage.quests[TeachingQuestPage.TaskTypeToIndex(TeachingQuestPage.currentType)][index];
	else
		return nil;
	end
end

function TeachingQuestPage.TaskTypeToIndex(type)
	if (type == "program") then
		return 1
	elseif (type == "animation") then
		return 2
	elseif (type == "CAD") then
		return 3
	else
		return 4
	end
end

function TeachingQuestPage.IsTaskProject(pid)
	for _, tasks in ipairs(TeachingQuestPage.quests) do
		for i = 1, #tasks do
			if (pid == tostring(tasks[i].pid)) then
				return true;
			end
		end
	end
	return false;
end

-- index start as 1
function TeachingQuestPage.IsFinished(exid, index)
	index = index or 1;
	local cnt = TeachingQuestPage.GetMarkItemCnt(exid);
	index = index - 1
	if(index < cnt)then
		return true
	end
end
function TeachingQuestPage.CanAccept(exid, index)
	local precondition, cost, goal = KeepWorkItemManager.GetConditions(exid);
	if(not precondition)then
		return true
	end
--    for k,v in ipairs(precondition) do
--        local gsid = v.goods.gsId;
--        local amount = v.amount or 0;
--        local bOwn, guid, bag, copies = KeepWorkItemManager.HasGSItem(gsId);
--        copies = copies or 0;
--        if(copies < amount)then
--            return false;
--        end
--    end
	return true;
end
function TeachingQuestPage.IsActived(exid, index)
	local cnt = TeachingQuestPage.GetMarkItemCnt(exid);
	index = index - 1
	if(index == cnt)then
		return true
	end
end

function TeachingQuestPage.IsLocked(exid, index)
	local cnt = TeachingQuestPage.GetMarkItemCnt(exid);
	index = index - 1
	if(index > cnt)then
		return true
	end
end
function TeachingQuestPage.GetMarkItem(exid)
	local precondition, cost, goal = KeepWorkItemManager.GetConditions(exid);
	if(not goal)then
		return
	end
	if(goal[1] and goal[1]["goods"])then
		local mark_item = goal[1]["goods"][1]["goods"];
		return mark_item;
	end
end
function TeachingQuestPage.GetMarkItemCnt(exid)
	local item = TeachingQuestPage.GetMarkItem(exid);
	if(not item)then
		return 0;
	end
	local gsid = item.gsId;
	local bOwn, guid, bag, copies = KeepWorkItemManager.HasGSItem(gsid);
	copies = copies or 0;
	return copies;
end

function TeachingQuestPage.OnClickItem(index)
	TeachingQuestPage.currentIndex = index;
	local task = TeachingQuestPage.GetCurrentSelectTask(index);
	if (task) then
		GameLogic.RunCommand("/loadworld "..task.pid);
		page:CloseWindow();
	end
end

function TeachingQuestPage.GetUnlockedTasks()
	return "3/20";
end

function TeachingQuestPage.GetFinishedTasks()
	return "2/20";
end

function TeachingQuestPage.OnSelectTaskType(name, value)
	TeachingQuestPage.currentType = value;
	TeachingQuestPage.Current_Item_DS = TeachingQuestPage.quests[TeachingQuestPage.TaskTypeToIndex(value)];
	page:Refresh(0);
end

function TeachingQuestPage.OnClose()
	page:CloseWindow();
end

function TeachingQuestPage.GetTaskState(index)
	return L"已激活";
end

function TeachingQuestPage.GetTaskTitle(index)
	local task = TeachingQuestPage.GetCurrentSelectTask(index);
	if (task) then
		return task.title;
	else
		return L"";
	end
end
