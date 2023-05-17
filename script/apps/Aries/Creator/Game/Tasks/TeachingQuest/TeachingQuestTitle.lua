﻿--[[
Title: TeachingQuestTitle
Author(s): chenjinxian 
Date: 2020/6/3
Desc:  
Use Lib:
-------------------------------------------------------
local TeachingQuestTitle = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestTitle.lua");
TeachingQuestTitle.ShowPage();
--]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldLoginAdapter.lua");
local ParaWorldLoginAdapter = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldLoginAdapter");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local TeachingQuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestPage.lua");
local NplBrowserManager = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserManager.lua");
local DailyTaskManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DailyTask/DailyTaskManager.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

local TeachingQuestTitle = NPL.export()

local page;
local TaskTime = 0
local TimeLimit = 20 -- 观看20秒算是完成任务
function TeachingQuestTitle.OnInit()
	page = document:GetPageCtrl();

end

function TeachingQuestTitle.StaticInit()
	GameLogic:Connect("WorldLoaded", TeachingQuestTitle, TeachingQuestTitle.OnWorldLoaded, "UniqueConnection");
end
function TeachingQuestTitle.CreateOrGetBrowserPage()
	return NplBrowserManager:CreateOrGet("TeachingQuest_BrowserPage");
end
function TeachingQuestTitle.OnWorldLoaded()
	local projectId = GameLogic.options:GetProjectId();
	projectId = tonumber(projectId);
	
	GameLogic.QuestAction.DailyWorldTask()
	
	TeachingQuestPage.ResetTasks();
	--TeachingQuestTitle.CreateOrGetBrowserPage():Close();
	if (page) then
		page:CloseWindow();
	end

	if (ParaWorldLoginAdapter.MainWorldId == nil) then
		local template = KeepWorkItemManager.GetItemTemplate(TeachingQuestPage.totalTaskGsid);
		if (template) then
			ParaWorldLoginAdapter.MainWorldId = tostring(template.desc);
		end
	end
	if (projectId ~= nil and projectId == ParaWorldLoginAdapter.MainWorldId) then
		if(not KeepWorkItemManager.GetToken())then
			_guihelper.MessageBox(L"本世界只有登录的用户可以访问。即将退出世界！");
			commonlib.TimerManager.SetTimeout(function()  
				GameLogic.RunCommand("/leaveworld")
			end, 3000)
			return
		end
		commonlib.TimerManager.SetTimeout(function()  
			TeachingQuestTitle.CheckAndShow();
			--GameLogic.GetEvents():AddEventListener("DesktopMenuShow", TeachingQuestTitle.MoveDown, TeachingQuestTitle, "TeachingQuestTitle");
			--GameLogic.GetEvents():AddEventListener("CodeBlockWindowShow", TeachingQuestTitle.MoveLeft, TeachingQuestTitle, "TeachingQuestTitle");
			GameLogic.GetFilters():add_filter("OnKeepWorkLogout", TeachingQuestTitle.OnKeepWorkLogout_Callback)
			GameLogic.RunCommand("/hide quickselectbar");

		end, 200)
	else
		if (TeachingQuestPage.IsTaskProject(tostring(projectId))) then
			local state = TeachingQuestPage.GetTaskState(TeachingQuestPage.currentIndex);
			if (state == TeachingQuestPage.Finished or state == TeachingQuestPage.Activated) then
				commonlib.TimerManager.SetTimeout(function()  
					TaskTime = 0
					if not DailyTaskManager.CheckTaskCompelete(DailyTaskManager.task_id_list.WeekWork) then
						local task = TeachingQuestPage.GetCurrentSelectTask(TeachingQuestPage.currentIndex);
						if (task and task.url ~= "") then
							GameLogic.AddBBS("desktop", L"至少需要学习20秒才能获得学习任务奖励哦~", 3000, "0 255 0"); 
						end
					end

					if (TeachingQuestPage.currentType < TeachingQuestPage.LanguageType) then
						TeachingQuestTitle.OnShowPanel();
					else
						TeachingQuestTitle.OnHidePanel();
					end
					GameLogic.GetEvents():AddEventListener("DesktopMenuShow", TeachingQuestTitle.MoveDown, TeachingQuestTitle, "TeachingQuestTitle");
					GameLogic.GetEvents():AddEventListener("CodeBlockWindowShow", TeachingQuestTitle.MoveLeft, TeachingQuestTitle, "TeachingQuestTitle");
					GameLogic.GetFilters():add_filter("OnShowEscFrame", TeachingQuestTitle.OnShowEscFrame);
					GameLogic.GetFilters():add_filter("OnKeepWorkLogout", TeachingQuestTitle.OnKeepWorkLogout_Callback)
				end, 1000)
			else
				--[[
				_guihelper.MessageBox(L"本世界只能拥有入场券的用户可以访问。即将退出世界！");
				commonlib.TimerManager.SetTimeout(function()  
					GameLogic.RunCommand("/leaveworld")
				end, 3000)
				]]
			end
		end
	end
end

function TeachingQuestTitle.CheckAndShow()
	--[[
	KeepWorkItemManager.CheckExchange(TeachingQuestPage.ticketExid, function(canExchange)
		if (canExchange.data and canExchange.data.ret == true) then
			TeachingQuestTitle.ShowPage("?info=main&ticket=receive");
		else
			if (canExchange.data and canExchange.data.reason == 5) then
				TeachingQuestTitle.ShowPage("?info=main&ticket=non_week");
			else
				TeachingQuestTitle.ShowPage("?info=main&ticket=non_today");
			end
		end
	end, function(err, msg, data)
		TeachingQuestTitle.ShowPage("?info=main&ticket=non_today");
	end);
	]]

	--[[
	KeepWorkItemManager.CheckExchange(TeachingQuestPage.ticketExid, function(canExchange)
		if (canExchange.data and canExchange.data.ret == true) then
			KeepWorkItemManager.DoExtendedCost(TeachingQuestPage.ticketExid, function()
			end);
		end
	end);
	]]
end

function TeachingQuestTitle.OnShowPanel()
	TeachingQuestTitle.ShowPage();
end

function TeachingQuestTitle.OnHidePanel()
	TeachingQuestTitle.ShowPage(0, -100, false);
end

function TeachingQuestTitle:MoveDown(event)
	if (event.bShow) then
		TeachingQuestTitle.ShowPage(0, 32);
	else
		TeachingQuestTitle.ShowPage(0, 0);
	end
end

function TeachingQuestTitle:MoveLeft(event)
	if (event.bShow) then
		local x, y, width, height = ParaUI.GetUIObject("root"):GetAbsPosition();
		local offset = (width + 488)/2 - (width - event.width);
		TeachingQuestTitle.ShowPage(-offset, 0);
	else
		TeachingQuestTitle.ShowPage(0, 0);
	end
end

function TeachingQuestTitle.OnShowEscFrame(bShow)
	if(bShow or bShow == nil) then
		--TeachingQuestTitle.CreateOrGetBrowserPage():Close();
	end
	return bShow;
end

function TeachingQuestTitle.OnKeepWorkLogout_Callback(res)
	GameLogic.GetEvents():RemoveEventListener("DesktopMenuShow", TeachingQuestTitle.MoveDown, TeachingQuestTitle);
	GameLogic.GetEvents():RemoveEventListener("CodeBlockWindowShow", TeachingQuestTitle.MoveLeft, TeachingQuestTitle);
	GameLogic.GetFilters():remove_filter("OnShowEscFrame", TeachingQuestTitle.OnShowEscFrame);
	GameLogic.GetFilters():remove_filter("OnKeepWorkLogout", TeachingQuestTitle.OnKeepWorkLogout_Callback);
	if (page) then
		page:CloseWindow();
	end
	GameLogic.RunCommand("/leaveworld")
end

function TeachingQuestTitle.ShowPage(offsetX, offsetY, show)
	if (page) then
		page:CloseWindow();
	end
	if (show == nil) then show = true end
	TeachingQuestTitle.IsPanelVisible = show;
	
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestTitle.html", 
		name = "TeachingQuestTitle.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		bToggleShowHide=false, 
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		click_through = false, 
		bShow = true,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
			align = "_ctt",
			x = offsetX or 0,
			y = offsetY or 0,
			width = 488,
			height = 120,
		cancelShowAnimation = true,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function TeachingQuestTitle.GetTaskTitle()
	local task = TeachingQuestPage.GetCurrentSelectTask(TeachingQuestPage.currentIndex);
	if (task and task.title) then
		return task.title;
	else
		L"知识岛";
	end
end

function TeachingQuestTitle.GetTaskInfo()
	--[[
	local task = TeachingQuestPage.GetCurrentSelectTask(TeachingQuestPage.currentIndex);
	if (task and task.info) then
		return task.info;
	else
		L"使用入场券开始任务";
	end
	]]
	return L"点击【开始任务】按钮开始学习，完成学习任务后即可获得知识豆奖励哦";
end

function TeachingQuestTitle.GetTotalPoints()
	local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(TeachingQuestPage.rewardGsid)
	copies = copies or 0;
	return tostring(copies);
end

function TeachingQuestTitle.ExchangePoints()
end

function TeachingQuestTitle.IsTaskFinished()
	local state = TeachingQuestPage.GetTaskState(TeachingQuestPage.currentIndex);
	return state == TeachingQuestPage.Finished;
end

local taskInProcess = false;
function TeachingQuestTitle.IsTaskInProcess()
	return taskInProcess;
end

function TeachingQuestTitle.GetTotalTickets()
	local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(TeachingQuestPage.ticketGsid)
	copies = copies or 0;
	return tostring(copies);
end

--[[
function TeachingQuestTitle.ReceiveTicket()
	KeepWorkItemManager.DoExtendedCost(TeachingQuestPage.ticketExid, function()
		TeachingQuestTitle.CheckAndShow();
		TeachingQuestPage.RefreshItem();
	end, function(err, msg, data)
		TeachingQuestTitle.ShowPage("?info=main&ticket=non_today");
	end);
end
]]

local firstStart = true;
function TeachingQuestTitle.StartTask()
	local task = TeachingQuestPage.GetCurrentSelectTask(TeachingQuestPage.currentIndex);
	--task.url = "https://keepwork.com/official/tips/cad/1_2_11921";
	if (task and task.url) then
		local function ShowTaskVideo(first)
			--[[
			-- always set width=1080, height=656 if window'size > 1080 * 656
			local x, y, width, height = ParaUI.GetUIObject("root"):GetAbsPosition();
			local left, top = 2000, 1000;
			if (width >= 1100 and height >= 800) then
				left = (width - 1080) / 2;
				top = (height - 656) / 2;
			end

			local options = {left=left, top=top, right=left, bottom=top, fixed=true, candrag=true, autoscale=true, resizefunc=function()
				local x, y, w, h= ParaUI.GetUIObject("root"):GetAbsPosition();
				if (w >= 1100 and h >= 800) then
					return 1080, 656;
				else
					if (w / (h-200) > 1080 / 656) then
						return (h-200)/656*1080, (h-200);
					else
						return (w-20), (w-20)*656/1080;
					end
				end
			end};
			TeachingQuestTitle.CreateOrGetBrowserPage():Show(task.url, task.title, false, true, options, function(state)
				if (state == "ONSHOW") then
					--TeachingQuestTitle.ShowPage("?info=task");
					if (page) then
						page:CloseWindow();
					end
				elseif (state == "ONCLOSE") then
					if (firstStart) then
						firstStart = false;
						if (TeachingQuestPage.IsVip()) then
							GameLogic.AddBBS("statusBar", L"获得了20个知识豆。", 3000, "0 255 0");
							_guihelper.MessageBox(L"普通用户完成任务后自动获得10知识豆，VIP用户获得20知识豆。您已开通VIP，自动获得了20知识豆！");
						else
							GameLogic.AddBBS("statusBar", L"获得了10个知识豆。", 3000, "0 255 0");
							_guihelper.MessageBox(L"普通用户完成任务后自动获得10知识豆，VIP用户获得20知识豆，是否开通VIP获取双倍知识豆？", function(res)
								if(res and res == _guihelper.DialogResult.Yes) then
									ParaGlobal.ShellExecute("open", "explorer.exe", "https://keepwork.com/vip", "", 1); 
								end
							end, _guihelper.MessageBoxButtons.YesNo);
						end
					end
					TeachingQuestTitle.CreateOrGetBrowserPage():GotoEmpty();
					TeachingQuestTitle.ShowPage("?info=task");
				end
			end);
			TeachingQuestTitle.CreateOrGetBrowserPage():OnResize();
			]]
			firstStart = first;
			taskInProcess = true;
			
			if task.url == "" then
				TeachingQuestTitle.FinishedTask(true)
			else
				ParaGlobal.ShellExecute("open", task.url, "", "", 1);
				TeachingQuestTitle.ShowPage();
			end
		end

		if (not TeachingQuestTitle.IsTaskFinished()) then

			--[[
			_guihelper.MessageBox(L"是否使用1张入场券开始当前世界任务？", function(res)
				if(res and res == _guihelper.DialogResult.Yes) then
					local exid = TeachingQuestPage.TaskExids[TeachingQuestPage.currentType]
					if (TeachingQuestPage.IsVip()) then
						exid = TeachingQuestPage.VipTaskExids[TeachingQuestPage.currentType]
					end
					KeepWorkItemManager.DoExtendedCost(exid, function()
						ShowTaskVideo(true);
					end);
				end
			end, _guihelper.MessageBoxButtons.YesNo);
			]]
			if (taskInProcess) then
				return;
			end
			taskInProcess = true;
			TaskTime = os.time()

			-- GameLogic.IsVip("VipWeeklyTraining", false, function(result)

			-- end);
			local exid = TeachingQuestPage.TaskExids[TeachingQuestPage.currentType]
			if (TeachingQuestPage.IsVip()) then
				exid = TeachingQuestPage.VipTaskExids[TeachingQuestPage.currentType]
			end
			KeepWorkItemManager.DoExtendedCost(exid, function()
				ShowTaskVideo(true);
			end);

		else
			ShowTaskVideo(false);
		end
	end
end

function TeachingQuestTitle.FinishedTask(complete_task_directly)
	if (firstStart) then
		firstStart = false;
		-- if (TeachingQuestPage.IsVip()) then
		-- 	GameLogic.AddBBS("statusBar", L"获得了20个知识豆。", 3000, "0 255 0");
		-- 	--_guihelper.MessageBox(L"普通用户完成任务后自动获得10知识豆，VIP用户获得20知识豆。您已开通VIP，自动获得了20知识豆！");
		-- else
		-- 	GameLogic.AddBBS("statusBar", L"获得了10个知识豆。", 3000, "0 255 0");
		-- 	--[[
		-- 	_guihelper.MessageBox(L"普通用户完成任务后自动获得10知识豆，VIP用户获得20知识豆，是否开通VIP获取双倍知识豆？", function(res)
		-- 		if(res and res == _guihelper.DialogResult.Yes) then
		-- 			ParaGlobal.ShellExecute("open", "explorer.exe", "https://keepwork.com/vip", "", 1); 
		-- 		end
		-- 	end, _guihelper.MessageBoxButtons.YesNo);
		-- 	]]
		-- end
		
		if not DailyTaskManager.CheckTaskCompelete(DailyTaskManager.task_id_list.WeekWork) and (os.time() - TaskTime >= TimeLimit or complete_task_directly) then
			DailyTaskManager.AchieveTask(DailyTaskManager.task_id_list.WeekWork, function ()
				TeachingQuestTitle.ShowPage();
			end)
			
		end
	end
	taskInProcess = false;
	TeachingQuestTitle.ShowPage();
end

function TeachingQuestTitle.OnClose()
	taskInProcess = false;
	GameLogic.GetEvents():RemoveEventListener("DesktopMenuShow", TeachingQuestTitle.MoveDown, TeachingQuestTitle);
	GameLogic.GetEvents():RemoveEventListener("CodeBlockWindowShow", TeachingQuestTitle.MoveLeft, TeachingQuestTitle);
	page:CloseWindow();
	GameLogic.RunCommand("/leaveworld")
end

function TeachingQuestTitle.OnReturn()
	local function ReturnMainWorld()
		taskInProcess = false;
		GameLogic.GetEvents():RemoveEventListener("DesktopMenuShow", TeachingQuestTitle.MoveDown, TeachingQuestTitle);
		GameLogic.GetEvents():RemoveEventListener("CodeBlockWindowShow", TeachingQuestTitle.MoveLeft, TeachingQuestTitle);
		GameLogic.GetFilters():remove_filter("OnShowEscFrame", TeachingQuestTitle.OnShowEscFrame);
		GameLogic.GetFilters():remove_filter("OnKeepWorkLogout", TeachingQuestTitle.OnKeepWorkLogout_Callback);
		page:CloseWindow();
		--GameLogic.RunCommand("/loadworld -force "..ParaWorldLoginAdapter.MainWorldId);
		ParaWorldLoginAdapter:EnterWorld(true);
	end
	if (not TeachingQuestTitle.IsTaskFinished()) then
		_guihelper.MessageBox(L"任务尚未开始，是否确定退出当前任务世界？", function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
				ReturnMainWorld()
			end
		end, _guihelper.MessageBoxButtons.YesNo);
	else
		ReturnMainWorld()
	end
end
