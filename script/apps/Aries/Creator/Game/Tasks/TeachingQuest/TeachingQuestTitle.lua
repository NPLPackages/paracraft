--[[
Title: TeachingQuestTitle
Author(s): chenjinxian 
Date: 2020/6/3
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
	if (projectId == TeachingQuestPage.MainWorldId) then
		if(not KeepWorkItemManager.GetToken())then
			_guihelper.MessageBox(L"本世界只有登录的用户可以访问。即将退出世界！");
			commonlib.TimerManager.SetTimeout(function()  
				GameLogic.RunCommand("/leaveworld")
			end, 2000)
			return
		end
		commonlib.TimerManager.SetTimeout(function()  
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
			GameLogic.GetEvents():AddEventListener("DesktopMenuShow", TeachingQuestTitle.MoveDown, TeachingQuestTitle, "TeachingQuestTitle");
			GameLogic.GetEvents():AddEventListener("CodeBlockWindowShow", TeachingQuestTitle.MoveLeft, TeachingQuestTitle, "TeachingQuestTitle");
		end, 3000)
	else
		if (TeachingQuestPage.IsTaskProject(projectId)) then
			local state = TeachingQuestPage.GetTaskState(TeachingQuestPage.currentIndex);
			if (state == TeachingQuestPage.Finished or state == TeachingQuestPage.Activated) then
				commonlib.TimerManager.SetTimeout(function()  
					TeachingQuestTitle.ShowPage("?info=task");
					GameLogic.GetEvents():AddEventListener("DesktopMenuShow", TeachingQuestTitle.MoveDown, TeachingQuestTitle, "TeachingQuestTitle");
					GameLogic.GetEvents():AddEventListener("CodeBlockWindowShow", TeachingQuestTitle.MoveLeft, TeachingQuestTitle, "TeachingQuestTitle");
					GameLogic.GetFilters():add_filter("OnShowEscFrame", TeachingQuestTitle.OnShowEscFrame);
					GameLogic.GetFilters():add_filter("ShowExitDialog", TeachingQuestTitle.OnShowExitDialog);
				end, 2000)
			else
				_guihelper.MessageBox(L"本世界只能拥有入场券的用户可以访问。即将退出世界！");
				commonlib.TimerManager.SetTimeout(function()  
					GameLogic.RunCommand("/leaveworld")
				end, 2000)
			end
		end
	end
end

function TeachingQuestTitle:MoveDown(event)
	if (event.bShow) then
		TeachingQuestTitle.ShowPage(nil, 0, 32);
	else
		TeachingQuestTitle.ShowPage(nil, 0, 0);
	end
end

function TeachingQuestTitle:MoveLeft(event)
	if (event.bShow) then
		local x, y, width, height = ParaUI.GetUIObject("root"):GetAbsPosition();
		local offset = (width + 488)/2 - (width - event.width);
		TeachingQuestTitle.ShowPage(nil, -offset, 0);
	else
		TeachingQuestTitle.ShowPage(nil, 0, 0);
	end
end

function TeachingQuestTitle.OnShowEscFrame(bShow)
	if(bShow or bShow == nil) then
		NplBrowserResizedPage:Close();
	end
	return bShow;
end

function TeachingQuestTitle.OnShowExitDialog(p1)
	NplBrowserResizedPage:Close();
	return p1;
end

function TeachingQuestTitle.ShowPage(param, offsetX, offsetY)
	if (page) then
		page:CloseWindow();
	end
	TeachingQuestTitle.showParam = param or TeachingQuestTitle.showParam;
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestTitle.html"..TeachingQuestTitle.showParam, 
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
	--[[
	local task = TeachingQuestPage.GetCurrentSelectTask(TeachingQuestPage.currentIndex);
	if (task and task.info) then
		return task.info;
	else
		L"使用入场券开始任务";
	end
	]]
	return L"点击【开始任务】按钮观看视频，完整观看视频后自动获得知识豆奖励";
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
			if (canExchange.data and canExchange.data.ret == true) then
				TeachingQuestTitle.ShowPage("?info=main&ticket=receive");
			else
				if (canExchange.data and canExchange.data.reason == 5) then
					TeachingQuestTitle.ShowPage("?info=main&ticket=non_week");
				else
					TeachingQuestTitle.ShowPage("?info=main&ticket=non_today");
				end
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
			-- always set width=1080, height=630 if window'size > 1080 * 630
			local x, y, width, height = ParaUI.GetUIObject("root"):GetAbsPosition();
			local left, top = 2000, 1000;
			if (width >= 1080 and height >= 630) then
				left = (width - 1080) / 2;
				top = (height - 630) / 2;
			end
			NplBrowserResizedPage:Show(task.url, task.title, false, true, {left=left, top=top, right=left, bottom=top, fixed=true, candrag=true}, function(state)
				if (state == "ONSHOW") then
					TeachingQuestTitle.ShowPage("?info=task");
				elseif (state == "ONCLOSE") then
					if (firstStart) then
						firstStart = false;
						if (TeachingQuestPage.IsVip()) then
							_guihelper.MessageBox(L"普通用户完成任务后自动获得10知识豆，VIP用户获得20知识豆。您已开通VIP，自动获得了20知识豆！");
						else
							_guihelper.MessageBox(L"普通用户完成任务后自动获得10知识豆，VIP用户获得20知识豆，是否开通VIP获取双倍知识豆？", function(res)
								if(res and res == _guihelper.DialogResult.Yes) then
									ParaGlobal.ShellExecute("open", "explorer.exe", "https://keepwork.com/vip", "", 1); 
								end
							end, _guihelper.MessageBoxButtons.YesNo);
						end
					end
					NplBrowserResizedPage:Goto(task.url);
					TeachingQuestTitle.ShowPage("?info=task");
				end
			end);
			NplBrowserResizedPage:OnResize();
		end

		if (not TeachingQuestTitle.IsTaskFinished()) then
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
		else
			ShowTaskVideo(false);
		end
	end
end

function TeachingQuestTitle.OnClose()
	GameLogic.GetEvents():RemoveEventListener("DesktopMenuShow", TeachingQuestTitle.MoveDown, TeachingQuestTitle);
	GameLogic.GetEvents():RemoveEventListener("CodeBlockWindowShow", TeachingQuestTitle.MoveLeft, TeachingQuestTitle);
	page:CloseWindow();
	GameLogic.RunCommand("/leaveworld")
end

function TeachingQuestTitle.OnReturn()
	local function ReturnMainWorld()
		GameLogic.GetEvents():RemoveEventListener("DesktopMenuShow", TeachingQuestTitle.MoveDown, TeachingQuestTitle);
		GameLogic.GetEvents():RemoveEventListener("CodeBlockWindowShow", TeachingQuestTitle.MoveLeft, TeachingQuestTitle);
		GameLogic.GetFilters():remove_filter("OnShowEscFrame", TeachingQuestTitle.OnShowEscFrame);
		GameLogic.GetFilters():remove_filter("ShowExitDialog", TeachingQuestTitle.OnShowExitDialog);
		page:CloseWindow();
		GameLogic.RunCommand("/loadworld -force "..TeachingQuestPage.MainWorldId);
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
