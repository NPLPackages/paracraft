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
local StudentPanel = NPL.export()

StudentPanel.IsLocked = false;
StudentPanel.IsChatting = false;
StudentPanel.CurrentClassName = "";
StudentPanel.CurrentWorldId = "";

local page;
function StudentPanel.OnInit()
	page = document:GetPageCtrl();
end

function StudentPanel.ShowPage(reset, offsetY)
	if (reset) then
		StudentPanel.OnClose()
	end
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
end

function StudentPanel.OnClose()
	if (page) then
		GameLogic.GetEvents():RemoveEventListener("DesktopMenuShow", StudentPanel.MoveDown, StudentPanel);
		page:CloseWindow();

		StudentPanel.Reset();
	end
end

function StudentPanel.Reset()
	StudentPanel.IsLocked = false;
	StudentPanel.CurrentClassName = "";
	StudentPanel.CurrentWorldId = "";
end

function StudentPanel:MoveDown(event)
	if (event.bShow) then
		StudentPanel.ShowPage(false, 32);
	else
		StudentPanel.ShowPage(false, 0);
	end
end

function StudentPanel.GetClassName()
	--return StudentPanel.CurrentClassName;
	return "编程1班";
end

function StudentPanel.GetClassTime()
	return "20";
end

function StudentPanel.GetTeacherName()
	return "张晓老师";
end

function StudentPanel.GetWorldID()
	local worldId = "当前上课世界ID：".."12345";
	return worldId;
end

function StudentPanel.OpenChat()
	StudentPanel.IsChatting = true;
	if (page) then
		page:Refresh(0);
	end
	local ChatRoomPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ChatRoomPage.lua");
	ChatRoomPage.ShowPage()
end

function StudentPanel.ShareUrl()
	StudentPanel.OnClose();
end

function StudentPanel.SetInClass(class, worldId)
	StudentPanel.CurrentClassName = class;
	StudentPanel.CurrentWorldId = worldId;
	if (worldId and #worldId > 1) then
		GameLogic:Connect("WorldLoaded", StudentPanel, StudentPanel.OnWorldLoaded, "UniqueConnection");
		GameLogic:Connect("WorldUnloaded", StudentPanel, StudentPanel.OnWorldUnload, "UniqueConnection");
		GameLogic.RunCommand("/loadworld -force "..worldId);
		return;
	end
	if (page) then
		page:Refresh(0);
	end
end

function StudentPanel.OnWorldLoaded()
	local projectId = tostring(GameLogic.options:GetProjectId());
	if (projectId == StudentPanel.CurrentWorldId) then
		commonlib.TimerManager.SetTimeout(function()
			StudentPanel.ShowPage();
		end, 1000);
	end
end

function StudentPanel.OnWorldUnload()
	local projectId = tostring(GameLogic.options:GetProjectId());
	if (projectId == StudentPanel.CurrentWorldId) then
		StudentPanel.Reset();
	end
end

