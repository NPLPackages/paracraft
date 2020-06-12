--[[
Title: TeachingQuestTitle
Author(s): 
Date: 
Desc:  
Use Lib:
-------------------------------------------------------
local TeachingQuestTitle = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestTitle.lua");
TeachingQuestTitle.ShowPage();
--]]

local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local TeachingQuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestPage.lua");
local NplBrowserResizedPage = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserResizedPage.lua");
local TeachingQuestTitle = NPL.export()

local page;
function TeachingQuestTitle.OnInit()
	page = document:GetPageCtrl();
end

function TeachingQuestTitle.StaticInit()
	GameLogic:Connect("WorldLoaded", TeachingQuestTitle, TeachingQuestTitle.OnWorldLoaded, "UniqueConnection");
end

function TeachingQuestTitle.OnWorldLoaded()
	NplBrowserResizedPage:Close();
	if (page) then
		page:CloseWindow();
	end
	local projectId = tostring(GameLogic.options:GetProjectId());
	commonlib.echo(projectId);
	if (projectId == TeachingQuestPage.MainWorldId) then
		commonlib.TimerManager.SetTimeout(function()  
			KeepWorkItemManager.CheckExchange(TeachingQuestPage.ticketExid, function(canExchange)
				if (canExchange.data) then
					TeachingQuestTitle.ShowPage("?info=main&ticket=receive");
				else
					TeachingQuestTitle.ShowPage("?info=main&ticket=non_today");
				end
			end, function(err, msg, data)
				TeachingQuestTitle.ShowPage("?info=main&ticket=receive");
			end);
		end, 3000)
	else
		commonlib.TimerManager.SetTimeout(function()  
			if (TeachingQuestPage.IsTaskProject(projectId)) then
				local state = TeachingQuestPage.GetTaskState(TeachingQuestPage.currentIndex);
				if (state == TeachingQuestPage.Finished or state == TeachingQuestPage.Activated) then
					TeachingQuestTitle.ShowPage("?info=task");
				else
					GameLogic.RunCommand("/leaveworld")
				end
			end
		end, 2000)
	end
end

function TeachingQuestTitle.ShowPage(param)
	if (page) then
		page:CloseWindow();
	end
	param = param or "?info=main&ticket=receive";
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestTitle.html"..param, 
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
			x = 0,
			y = 0,
			width = 488,
			height = 110,
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
	local task = TeachingQuestPage.GetCurrentSelectTask(TeachingQuestPage.currentIndex);
	if (task and task.info) then
		return task.info;
	else
		L"使用入场券开始任务";
	end
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

function TeachingQuestTitle.IsTaskInProcess()
	return NplBrowserResizedPage:IsVisible();
end

function TeachingQuestTitle.GetTotalTickets()
	local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(TeachingQuestPage.ticketGsid)
	copies = copies or 0;
	return tostring(copies);
end

function TeachingQuestTitle.ReceiveTicket()
	KeepWorkItemManager.DoExtendedCost(TeachingQuestPage.ticketExid, function()
		KeepWorkItemManager.CheckExchange(TeachingQuestPage.ticketExid, function(canExchange)
			if (canExchange.data) then
				TeachingQuestTitle.ShowPage("?info=main&ticket=receive");
			else
				TeachingQuestTitle.ShowPage("?info=main&ticket=non_today");
			end
		end, function()
			TeachingQuestTitle.ShowPage("?info=main&ticket=non_today");
		end);
	end, function(err, msg, data)
		TeachingQuestTitle.ShowPage("?info=main&ticket=non_today");
	end);
end

function TeachingQuestTitle.StartTask()
	local task = TeachingQuestPage.GetCurrentSelectTask(TeachingQuestPage.currentIndex);
	--task.url = "https://keepwork.com/official/tips/p1/1_10_11536";
	if (task and task.url) then
		local function ShowTaskVideo(firstStart)
			-- always set width=1080, height=622 if window'size > 1080 * 622
			local x, y, width, height = ParaUI.GetUIObject("root"):GetAbsPosition();
			local left, top = 2000, 1000;
			if (width >= 1080 and height >= 622) then
				left = (width - 1080) / 2;
				top = (height - 622) / 2;
			end
			NplBrowserResizedPage:Show(task.url, task.title, false, true, {left=left, top=top, right=left, bottom=top;}, function(state)
				if (state == "ONSHOW") then
					TeachingQuestTitle.ShowPage("?info=task");
				elseif (state == "ONCLOSE") then
					if (firstStart) then
						firstStart = false;
						if (TeachingQuestPage.IsVip()) then
							_guihelper.MessageBox(L"尊贵的VIP用户，完成任务后自动奖励了2倍的知识豆");
						else
							_guihelper.MessageBox(L"完成任务后自动奖励了10知识豆，升级为VIP可以奖励2倍知识豆，确定升级吗？", function(res)
								if(res and res == _guihelper.DialogResult.Yes) then
									ParaGlobal.ShellExecute("open", "explorer.exe", "https://keepwork.com/vip", "", 1); 
								end
							end, _guihelper.MessageBoxButtons.YesNo);
						end
					end
					TeachingQuestTitle.ShowPage("?info=task");
				end
			end);
			NplBrowserResizedPage:OnResize();
		end

		if (not TeachingQuestTitle.IsTaskFinished()) then
			_guihelper.MessageBox(L"是否要使用 1 入场券开始任务？", function(res)
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
		else
			ShowTaskVideo(false);
		end
	end
end

function TeachingQuestTitle.OnClose()
	page:CloseWindow();
	GameLogic.RunCommand("/leaveworld")
end

function TeachingQuestTitle.OnReturn()
	if (not TeachingQuestTitle.IsTaskFinished()) then
		_guihelper.MessageBox(L"任务尚未开始，确定要退出吗？", function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
				page:CloseWindow();
				GameLogic.RunCommand("/loadworld -force "..TeachingQuestPage.MainWorldId);
			end
		end, _guihelper.MessageBoxButtons.YesNo);
	else
		page:CloseWindow();
		GameLogic.RunCommand("/loadworld -force "..TeachingQuestPage.MainWorldId);
	end
end
