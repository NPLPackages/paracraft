--[[
Title: Teacher Panel
Author(s): Chenjinxian
Date: 2020/7/6
Desc: 
use the lib:
-------------------------------------------------------
local TeacherPanel = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/TeacherPanel.lua");
TeacherPanel.ShowPage(true)
-------------------------------------------------------
]]
local TeacherPanel = NPL.export()

TeacherPanel.InClass = false;
TeacherPanel.IsLocked = false;
TeacherPanel.IsChatting = false;
TeacherPanel.CurrentClassName = "";
TeacherPanel.CurrentWorldId = "";

local page;
function TeacherPanel.OnInit()
	page = document:GetPageCtrl();
end

function TeacherPanel.ShowPage(reset, offsetY)
	if (reset) then
		TeacherPanel.OnClose()
	end
	local params = {
			url = "script/apps/Aries/Creator/Game/Network/Admin/ClassManager/TeacherPanel.html", 
			name = "TeacherPanel.ShowPage", 
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

	GameLogic.GetEvents():AddEventListener("DesktopMenuShow", TeacherPanel.MoveDown, TeacherPanel, "TeacherPanel");
end

function TeacherPanel.OnClose()
	if (page) then
		GameLogic.GetEvents():RemoveEventListener("DesktopMenuShow", TeacherPanel.MoveDown, TeacherPanel);
		page:CloseWindow();

		TeacherPanel.Reset();
	end
end

function TeacherPanel.Reset()
	TeacherPanel.InClass = false;
	TeacherPanel.IsLocked = false;
	TeacherPanel.CurrentClassName = "";
	TeacherPanel.CurrentWorldId = "";
end

function TeacherPanel:MoveDown(event)
	if (event.bShow) then
		TeacherPanel.ShowPage(false, 32);
	else
		TeacherPanel.ShowPage(false, 0);
	end
end

function TeacherPanel.SelectClass()
	local ClassListPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ClassListPage.lua");
	ClassListPage.ShowPage();
end

function TeacherPanel.LeaveClass()
	TeacherPanel.Reset();
	if (page) then
		page:Refresh(0);
	end
end

function TeacherPanel.GetClassName()
	return TeacherPanel.CurrentClassName;
end

function TeacherPanel.GetClassStudents()
	return "在课学生：10人";
end

function TeacherPanel.Lock()
	TeacherPanel.IsLocked = true;
	if (page) then
		page:Refresh(0);
	end
end

function TeacherPanel.UnLock()
	TeacherPanel.IsLocked = false;
	if (page) then
		page:Refresh(0);
	end
end

function TeacherPanel.OpenChat()
	TeacherPanel.IsChatting = true;
	if (page) then
		page:Refresh(0);
	end
	local ChatRoomPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ChatRoomPage.lua");
	ChatRoomPage.ShowPage()
end

function TeacherPanel.ConnectClass()
end

function TeacherPanel.ShareUrl()
	local ShareUrlPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ShareUrlPage.lua");
	ShareUrlPage.ShowPage()
	TeacherPanel.OnClose();
end

function TeacherPanel.SetInClass(class, worldId)
	TeacherPanel.InClass = true;
	TeacherPanel.CurrentClassName = class;
	TeacherPanel.CurrentWorldId = worldId;
	if (worldId and #worldId > 1) then
		GameLogic:Connect("WorldLoaded", TeacherPanel, TeacherPanel.OnWorldLoaded, "UniqueConnection");
		GameLogic:Connect("WorldUnloaded", TeacherPanel, TeacherPanel.OnWorldUnload, "UniqueConnection");
		GameLogic.RunCommand("/loadworld -force "..worldId);
		return;
	end
	if (page) then
		page:Refresh(0);
	end
end

function TeacherPanel.OnWorldLoaded()
	local projectId = tostring(GameLogic.options:GetProjectId());
	if (projectId == TeacherPanel.CurrentWorldId) then
		commonlib.TimerManager.SetTimeout(function()
			TeacherPanel.ShowPage();
		end, 1000);
	end
end

function TeacherPanel.OnWorldUnload()
	local projectId = tostring(GameLogic.options:GetProjectId());
	if (projectId == TeacherPanel.CurrentWorldId) then
		TeacherPanel.Reset();
	end
end

