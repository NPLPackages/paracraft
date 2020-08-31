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

local page;
function StudentPanel.OnInit()
	page = document:GetPageCtrl();
end

function StudentPanel.ShowPage()
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
				y = 0,
				width = 0,
				height = 48,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function StudentPanel.OnClose()
	if (page) then
		GameLogic.GetEvents():RemoveEventListener("DesktopMenuShow", StudentPanel.MoveDown, StudentPanel);
		page:CloseWindow();

		StudentPanel.Reset();
	end
end

function StudentPanel:MoveDown(event)
	if (event.bShow) then
		StudentPanel.ShowPage(false, 32);
	else
		StudentPanel.ShowPage(false, 0);
	end
end

function StudentPanel.Reset()
end

function StudentPanel.LeaveClass()
	if (page) then
		page:Refresh(0);
	end
	SChatRoomPage.ShowPage(false);
end

function StudentPanel.GetClassName()
	return ClassManager.ClassNameFromId(ClassManager.CurrentClassId) or ClassManager.CurrentClassName;
end

function StudentPanel.GetClassTime()
	return "20";
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
	ClassManager.JoinClassroom(ClassManager.CurrentClassroomId);
	ClassManager.SendMessage("tip:join");
	local projectId = GameLogic.options:GetProjectId();
	if (projectId and tonumber(projectId) == ClassManager.CurrentWorldId) then
		if (page) then
			page:Refresh(0);
		else
			StudentPanel.ShowPage();
		end
	else
		StudentPanel.EnterTeachingWorld(ClassManager.CurrentWorldId)
	end
end

function StudentPanel.EnterTeachingWorld(worldId)
	GameLogic:Connect("WorldLoaded", StudentPanel, StudentPanel.OnWorldLoaded, "UniqueConnection");
	--GameLogic:Connect("WorldUnloaded", StudentPanel, StudentPanel.OnWorldUnload, "UniqueConnection");
	local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
	UserConsole:HandleWorldId(worldId, "force");
end

function StudentPanel.OnWorldLoaded()
	local projectId = GameLogic.options:GetProjectId();
	if (projectId and tonumber(projectId) == ClassManager.CurrentWorldId) then
		commonlib.TimerManager.SetTimeout(function()
			StudentPanel.ShowPage();
		end, 1000);
	end
end

function StudentPanel.OnWorldUnload()
	local projectId = tostring(GameLogic.options:GetProjectId());
end

