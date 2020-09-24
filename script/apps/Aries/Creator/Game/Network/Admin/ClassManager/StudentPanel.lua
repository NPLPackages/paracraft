--[[
Title: Teacher Panel
Author(s): Chenjinxian
Date: 2020/7/6
Desc: 
use the lib:
-------------------------------------------------------
local StudentPanel = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/StudentPanel.lua");
StudentPanel.ShowPage(true)
-------------------------------------------------------
]]
local ClassManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ClassManager.lua");
local ShareUrlContext = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ShareUrlContext.lua");
local SChatRoomPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/SChatRoomPage.lua");
local StudentPanel = NPL.export()

StudentPanel.IsChatting = false;
StudentPanel.ShowUrl = false;
StudentPanel.IsPanelVisible = true;
StudentPanel.TickCount = 0;

local page;
function StudentPanel.OnInit()
	page = document:GetPageCtrl();
end

function StudentPanel.ShowPage(offsetY)
	StudentPanel.OnClose()
	local params = {
			url = "script/apps/Aries/Creator/Game/Network/Admin/ClassManager/StudentPanel.html", 
			name = "StudentPanel.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			zorder = 0,
			click_through = false, 
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_mt",
				x = 0,
				y = offsetY or 0,
				width = 0,
				height = 48,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	GameLogic.GetEvents():AddEventListener("DesktopMenuShow", StudentPanel.MoveDown, StudentPanel, "StudentPanel");
	GameLogic.GetEvents():AddEventListener("CodeBlockWindowShow", StudentPanel.MoveLeft, StudentPanel, "StudentPanel");
end

function StudentPanel.OnClose()
	if (page) then
		GameLogic.GetEvents():RemoveEventListener("DesktopMenuShow", StudentPanel.MoveDown, StudentPanel);
		GameLogic.GetEvents():RemoveEventListener("CodeBlockWindowShow", StudentPanel.MoveLeft, StudentPanel);
		page:CloseWindow();
	end
end

function StudentPanel:MoveDown(event)
	if (event.bShow) then
		if (StudentPanel.IsPanelVisible) then
			StudentPanel.ShowPage(32);
		else
			StudentPanel.ShowPage(32-32);
		end
	else
		if (StudentPanel.IsPanelVisible) then
			StudentPanel.ShowPage();
		else
			StudentPanel.ShowPage(-32);
		end
	end
end

function StudentPanel:MoveLeft(event)
	if (event.bShow) then
		StudentPanel.OnHidePanel();
	else
		StudentPanel.OnShowPanel();
	end
end

function StudentPanel.OnShowPanel()
	if (not StudentPanel.IsPanelVisible) then
		StudentPanel.IsPanelVisible = true;
		StudentPanel.ShowPage();
	end
end

function StudentPanel.OnHidePanel()
	if (StudentPanel.IsPanelVisible) then
		StudentPanel.IsPanelVisible = false;
		StudentPanel.ShowPage(-32);
	end
end

function StudentPanel.LeaveClass()
	StudentPanel.timer:Change();
	if (page) then
		page:Refresh(0);
	end
	SChatRoomPage.ShowPage(false);
end

function StudentPanel.GetClassName()
	return ClassManager.ClassNameFromId(ClassManager.CurrentClassId) or ClassManager.CurrentClassName;
end

function StudentPanel.GetClassTime()
	local classtime = string.format(L"已上课%d分钟", StudentPanel.TickCount);
	return classtime;
end

function StudentPanel.GetTeacherName()
	return ClassManager.GetMemberUIName(ClassManager.GetCurrentTeacher(), true);
end

function StudentPanel.GetWorldID()
	local worldId = "当前上课世界ID："..ClassManager.CurrentWorldId;
	return worldId;
end

function StudentPanel.OpenChat()
	StudentPanel.IsChatting = true;
	if (page) then
		page:Refresh(0);
	end
	SChatRoomPage.ShowPage(true);
end

function StudentPanel.CloseChat()
	StudentPanel.IsChatting = false;
	if (page) then
		page:Refresh(0);
	end
end

function StudentPanel.ShareUrl()
	if (StudentPanel.ShowUrl) then
		ShareUrlContext.OnClose()
	else
		ShareUrlContext.ShowPage()
	end
	StudentPanel.ShowUrl = not StudentPanel.ShowUrl;
	if (page) then
		page:Refresh(0);
	end
end

function StudentPanel.IsClassStarted()
	return ClassManager.InClass;
end

function StudentPanel.StartClass()
	local projectId = GameLogic.options:GetProjectId();
	if (projectId and tonumber(projectId) == ClassManager.CurrentWorldId) then
		if (page) then
			page:Refresh(0);
		else
			StudentPanel.ShowPage();
		end
		ClassManager.JoinClassroom(ClassManager.CurrentClassroomId);
		ClassManager.SendMessage("tip:join");
		StudentPanel.StartTick();
	else
		StudentPanel.EnterTeachingWorld(ClassManager.CurrentWorldId)
	end
end

function StudentPanel.EnterTeachingWorld(worldId)
	GameLogic:Connect("WorldLoaded", StudentPanel, StudentPanel.OnWorldLoaded, "UniqueConnection");
	local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
	UserConsole:HandleWorldId(worldId, "force");
end

function StudentPanel.OnWorldLoaded()
	local projectId = GameLogic.options:GetProjectId();
	if (projectId and tonumber(projectId) == ClassManager.CurrentWorldId) then
		commonlib.TimerManager.SetTimeout(function()
			StudentPanel.ShowPage();
			ClassManager.JoinClassroom(ClassManager.CurrentClassroomId);
			ClassManager.SendMessage("tip:join");
			StudentPanel.StartTick();
		end, 1000);
	end
end

function StudentPanel.StartTick()
	StudentPanel.timer = StudentPanel.timer or commonlib.Timer:new({callbackFunc = function(timer)
		if (page) then
			page:Refresh(0);
		end
		StudentPanel.TickCount = StudentPanel.TickCount + 1;
	end});
	StudentPanel.timer:Change(100, 1000 * 60);
end

function StudentPanel.UpdateClassTime(updatedTime)
	local diff = updatedTime - ClassManager.CreatedTime;
	if (diff > 0) then
		StudentPanel.TickCount = diff;
		if (page) then
			page:Refresh(0);
		end
	end
end