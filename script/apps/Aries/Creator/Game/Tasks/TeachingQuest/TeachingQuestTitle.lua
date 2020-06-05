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
local TeachingQuestMessage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestMessage.lua");
local TeachingQuestTitle = NPL.export()

function TeachingQuestTitle.StaticInit()
	GameLogic:Connect("WorldLoaded", TeachingQuestTitle, TeachingQuestTitle.OnWorldLoaded, "UniqueConnection");
end

function TeachingQuestTitle.OnWorldLoaded()
	local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
		local projectId = GameLogic.options:GetProjectId();
		if (projectId == TeachingQuestPage.MainWorldId) then
			-- main project
			TeachingQuestTitle.ShowPage()
		elseif (TeachingQuestPage.IsTaskProject(projectId)) then
			-- task project
			TeachingQuestTitle.ShowPage("?info=task", "&state=start_task")
		end
	end})
	mytimer:Change(2000, nil);
end

local page;
function TeachingQuestTitle.OnInit()
	page = document:GetPageCtrl();
end

function TeachingQuestTitle.ShowPage(info, state)
	info = info or "?info=main";
	state = state or "&state=start_task";
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestTitle.html"..info, 
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

function TeachingQuestTitle.GetTotalPoints()
	return "10";
end

function TeachingQuestTitle.ExchangePoints()
end

function TeachingQuestTitle.ReceiveTicket()
	local profile = KeepWorkItemManager.GetProfile();
	local userId = profile.id;
	local exid = TeachingQuestPage.ticketId;
	if (not userId or not exId) then
		return;
	end

	keepwork.items.exchange({userId = userId, exid = exid}, function(err, msg, data)
	end);
end

function TeachingQuestTitle.StartTask()
	local task = TeachingQuestPage.GetCurrentSelectTask();
	task.url = "https://keepwork.com/grand123/CVIP/CAD/1_1_11921";
	if (task and task.url) then
		local NplBrowserResizedPage = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserResizedPage.lua");
		NplBrowserResizedPage:Show(task.url, task.title, false, false, {left=100, top=250, right=100, bottom=50;}, function(state)
			if(state == "ONCLOSE")then
				commonlib.echo("close browsesr");
			end
		end);
	end
end

function TeachingQuestTitle.OnClose()
	page:CloseWindow();
	GameLogic.RunCommand("/leaveworld")
end

function TeachingQuestTitle.OnReturn()
	TeachingQuestMessage.ShowPage(function(result)
		if (result == "ok") then
			page:CloseWindow();
			GameLogic.RunCommand("/loadworld "..TeachingQuestPage.MainWorldId);
		end
	end);
end
