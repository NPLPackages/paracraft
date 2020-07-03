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
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");

local TeachingQuestPage = NPL.export();
TeachingQuestPage.ticketExid= 10002;
TeachingQuestPage.ticketGsid = 10003;
TeachingQuestPage.rewardGsid = 998;

TeachingQuestPage.MainWorldId = ParaEngine.GetAppCommandLineByParam("world_id", nil);

TeachingQuestPage.quests = {}
TeachingQuestPage.taskCallback = {}
TeachingQuestPage.currentType = "program";
TeachingQuestPage.currentIndex = -1;

-- task exid
-- TeachingQuestPage.programExid = 10003;
-- TeachingQuestPage.animationExid = 10004;
-- TeachingQuestPage.cadExid = 10005;
-- TeachingQuestPage.robotExid = 10006;
TeachingQuestPage.TaskExids = {10003, 10004, 10005, 10006};

-- task exid
-- TeachingQuestPage.programExidVip = 10013;
-- TeachingQuestPage.animationExidVip = 10014;
-- TeachingQuestPage.cadExidVip = 10015;
-- TeachingQuestPage.robotExidVip = 10016;
TeachingQuestPage.VipTaskExids = {10013, 10014, 10015, 10016};

-- task gsid
-- TeachingQuestPage.programGsid = 30202;
-- TeachingQuestPage.animationGsid = 30203;
-- TeachingQuestPage.cadGsid = 30204;
-- TeachingQuestPage.robotGsid = 30205;
TeachingQuestPage.totalTaskGsid = 30201;
TeachingQuestPage.TaskGsids = {30202, 30203, 30204, 30205};

-- teacher state
TeachingQuestPage.HasNewTask = 1;
TeachingQuestPage.TaskInProgress = 2;
TeachingQuestPage.AllFinished = 3;

-- task state
TeachingQuestPage.Finished = 1;
TeachingQuestPage.Activated = 2;
TeachingQuestPage.Acceptable = 3;
TeachingQuestPage.Locked = 4;

-- task type
TeachingQuestPage.ProgramType = 1;
TeachingQuestPage.AnimationType = 2;
TeachingQuestPage.CADType = 3;
TeachingQuestPage.RobotType = 4;
TeachingQuestPage.UnknowType = 5;

TeachingQuestPage.TaskTypeTexts = {L"编程", L"动画", L"CAD", L"机器人"};
TeachingQuestPage.TaskTypeNames = {"program", "animation", "CAD", "robot"};
TeachingQuestPage.TaskTypeIndex = {
	program = TeachingQuestPage.ProgramType,
	animation = TeachingQuestPage.AnimationType,
	CAD = TeachingQuestPage.CADType,
	robot = TeachingQuestPage.RobotType
};

local page;
function TeachingQuestPage.OnInit()
	page = document:GetPageCtrl();
end
function TeachingQuestPage.ShowPage(type)
	TeachingQuestPage.currentType = type;
	TeachingQuestPage.Current_Item_DS = TeachingQuestPage.quests[type] or {};
	TeachingQuestPage.CheckTaskCount(type);
	if (TeachingQuestPage.RefreshItem()) then
		return;
	end

	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestPage.html",
		name = "TeachingQuestPage.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		enable_esc_key = true,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
		align = "_ct",
		x = -680 / 2,
		y = -430 / 2,
		width = 680,
		height = 430,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	page:SetValue("TaskType", TeachingQuestPage.TaskTypeNames[type]);
	commonlib.TimerManager.SetTimeout(function()  
		local count = TeachingQuestPage.GetTaskItemCount(TeachingQuestPage.ticketGsid);
		local state = L"  （本周已发放一张）";
		KeepWorkItemManager.CheckExchange(TeachingQuestPage.ticketExid, function(canExchange)
			if (canExchange.data) then
				if (canExchange.data.reason == 5) then
					state = L"  （本周已发放两张）";
				elseif (canExchange.data.reason == 3) then
					state = L"  （已达到获取上限）";
				end
			end
			page:SetValue("TicketState", count..state);
		end, function(err, msg, data)
			page:SetValue("TicketState", count..state);
		end);
	end, 100)
end

function TeachingQuestPage.IsVip()
	local gsid = 10;
	local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(gsid)
	return (copies and copies > 0);
end

function TeachingQuestPage.CheckTaskCount(type)
	local template = KeepWorkItemManager.GetItemTemplate(TeachingQuestPage.TaskGsids[type]);
	if (template) then
		if (#TeachingQuestPage.Current_Item_DS > template.max) then
			for i = #TeachingQuestPage.Current_Item_DS, template.max+1, -1 do
				TeachingQuestPage.Current_Item_DS[i] = nil;
			end
		end
	else
		TeachingQuestPage.Current_Item_DS = {};
	end
end

function TeachingQuestPage.AddTasks(tasks, type)
	TeachingQuestPage.quests[type] = tasks;
	commonlib.TimerManager.SetTimeout(function()  
		local count = TeachingQuestPage.GetTaskItemCount(TeachingQuestPage.TaskGsids[type]);
		local max = TeachingQuestPage.GetTaskItemMax(TeachingQuestPage.TaskGsids[type]);
		local ticket = TeachingQuestPage.GetTaskItemCount(TeachingQuestPage.ticketGsid);
		if (count < max) then
			if (ticket > 0) then
				TeachingQuestPage.taskCallback[type](TeachingQuestPage.TaskInProgress);
			else
				TeachingQuestPage.taskCallback[type](TeachingQuestPage.HasNewTask);
			end
		else
			TeachingQuestPage.taskCallback[type](TeachingQuestPage.AllFinished);
		end
	end, 2000)
end

function TeachingQuestPage.RegisterTasksChanged(callback, type)
	TeachingQuestPage.taskCallback[type] = callback;
end

function TeachingQuestPage.GetTaskOptions()
	local taskOptions = {};
	for i = 1, #TeachingQuestPage.quests do
		if (#(TeachingQuestPage.quests[i]) > 0) then
			table.insert(taskOptions, {text=TeachingQuestPage.TaskTypeTexts[i], value=TeachingQuestPage.TaskTypeNames[i]});
		end
	end
	return taskOptions;
end

function TeachingQuestPage.GetCurrentSelectTask(index)
	if (TeachingQuestPage.currentType and index > 0) then
		return TeachingQuestPage.quests[TeachingQuestPage.currentType][index];
	else
		return nil;
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

function TeachingQuestPage.GetTaskItemMax(gsid)
	local template = KeepWorkItemManager.GetItemTemplate(gsid);
	if (template) then
		return template.max or 0;
	else
		return 0;
	end
end

function TeachingQuestPage.GetTaskItemCount(gsid)
	local bOwn, guid, bag, copies = KeepWorkItemManager.HasGSItem(gsid);
	copies = copies or 0;
	return copies;
end

function TeachingQuestPage.GetTotalTickets()
	local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(TeachingQuestPage.ticketGsid)
	copies = copies or 0;
	return tostring(copies);
end

function TeachingQuestPage.OnClose()
	page:CloseWindow();
end

function TeachingQuestPage.RefreshItem()
	if (page) then
		page:Refresh(0);
		page:SetValue("TaskType", TeachingQuestPage.TaskTypeNames[TeachingQuestPage.currentType]);
		return;
	end
end

function TeachingQuestPage.GetUnlockedTasks()
	local type = TeachingQuestPage.currentType;
	local count = TeachingQuestPage.GetTaskItemCount(TeachingQuestPage.TaskGsids[type]);
	local max = TeachingQuestPage.GetTaskItemMax(TeachingQuestPage.TaskGsids[type]);
	local ticket = TeachingQuestPage.GetTaskItemCount(TeachingQuestPage.ticketGsid);
	if (ticket > 0 and count < max) then
		count = count + 1;
	end
	return string.format("%d/%d", count, max);
end

function TeachingQuestPage.GetFinishedTasks()
	local type = TeachingQuestPage.currentType;
	local count = TeachingQuestPage.GetTaskItemCount(TeachingQuestPage.TaskGsids[type]);
	local max = TeachingQuestPage.GetTaskItemMax(TeachingQuestPage.TaskGsids[type]);
	return string.format("%d/%d", count, max);
end

function TeachingQuestPage.OnSelectTaskType(name, value)
	TeachingQuestPage.currentType = TeachingQuestPage.TaskTypeIndex[value];
	TeachingQuestPage.Current_Item_DS = TeachingQuestPage.quests[TeachingQuestPage.currentType] or {};
	TeachingQuestPage.CheckTaskCount(TeachingQuestPage.currentType);
	page:Refresh(0);
	page:SetValue("TaskType", TeachingQuestPage.TaskTypeNames[TeachingQuestPage.currentType]);
end

function TeachingQuestPage.GetTaskState(index)
	local task = TeachingQuestPage.GetCurrentSelectTask(index);
	if (task) then
		local count = TeachingQuestPage.GetTaskItemCount(TeachingQuestPage.TaskGsids[TeachingQuestPage.currentType]);
		if (index <= count) then
			return TeachingQuestPage.Finished;
		elseif (index > count + 1) then
			return TeachingQuestPage.Locked;
		else
			local ticket = TeachingQuestPage.GetTaskItemCount(TeachingQuestPage.ticketGsid);
			if (ticket > 0) then
				return TeachingQuestPage.Activated;
			else
				return TeachingQuestPage.Acceptable;
			end
		end
	else
		return TeachingQuestPage.Locked;
	end
end

function TeachingQuestPage.GetTaskTitle(index)
	local task = TeachingQuestPage.GetCurrentSelectTask(index);
	if (task) then
		return task.title;
	else
		return L"";
	end
end

function TeachingQuestPage.OnClickItem(index)
	local function StartTask()
		TeachingQuestPage.currentIndex = index;
		local task = TeachingQuestPage.GetCurrentSelectTask(index);
		if (task) then
			page:CloseWindow();
			GameLogic.RunCommand("/loadworld -force "..task.pid);
		end
	end
	local state = TeachingQuestPage.GetTaskState(index);
	if (state == TeachingQuestPage.Finished) then
		StartTask();
	elseif (state == TeachingQuestPage.Activated) then
		local exid = TeachingQuestPage.TaskExids[TeachingQuestPage.currentType]
		if (TeachingQuestPage.IsVip()) then
			exid = TeachingQuestPage.VipTaskExids[TeachingQuestPage.currentType]
		end
		KeepWorkItemManager.CheckExchange(exid, function(canExchange)
			if (canExchange.data) then
				StartTask();
			end
		end);
	else
		-- task is locked
	end
end
