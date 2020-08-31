--[[
Title: Teacher Panel
Author(s): Chenjinxian
Date: 2020/7/6
Desc: 
use the lib:
-------------------------------------------------------
local TeacherPanel = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/TeacherPanel.lua");
TeacherPanel.ShowPage()
-------------------------------------------------------
]]
local ClassManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ClassManager.lua");
local TChatRoomPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/TChatRoomPage.lua");
local TeacherPanel = NPL.export()

TeacherPanel.IsLocked = false;
TeacherPanel.IsChatting = false;

local page;
function TeacherPanel.OnInit()
	page = document:GetPageCtrl();
end

function TeacherPanel.ShowPage()
	if (page) then
		page:CloseWindow();
	end
	GameLogic.IsVip("OnlineTeaching", true, function(result)
		if (result) then
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
						y = 0,
						width = 0,
						height = 48,
				};
			System.App.Commands.Call("File.MCMLWindowFrame", params);

			--GameLogic.GetEvents():AddEventListener("DesktopMenuShow", TeacherPanel.MoveDown, TeacherPanel, "TeacherPanel");
		end
	end);
end

function TeacherPanel.OnClose()
	if (page) then
		--GameLogic.GetEvents():RemoveEventListener("DesktopMenuShow", TeacherPanel.MoveDown, TeacherPanel);
		page:CloseWindow();
	end
end

function TeacherPanel:MoveDown(event)
	if (event.bShow) then
		TeacherPanel.ShowPage(false, 32);
	else
		TeacherPanel.ShowPage(false, 0);
	end
end

function TeacherPanel.Refresh()
	if (page) then
		page:Refresh(0);
	end
end

function TeacherPanel.SelectClass()
	ClassManager.LoadAllClasses(function()
		ClassManager.LoadAllProjects(function()
			if (#ClassManager.ClassList > 0 and #ClassManager.ProjectList > 0) then
				local ClassListPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ClassListPage.lua");
				ClassListPage.ShowPage();
			else
				_guihelper.MessageBox(L"获取班级信息失败, 请重试！");
			end
		end);
	end);
end

function TeacherPanel.LeaveClass()
	_guihelper.MessageBox(L"确定要结束上课吗？", function(res)
		if(res == _guihelper.DialogResult.OK) then
			ClassManager.DismissClassroom(ClassManager.CurrentClassroomId, function(result, data)
				if (result) then
					ClassManager.LeaveClassroom(ClassManager.CurrentClassroomId);
					if (page) then
						page:Refresh(0);
					end
					TChatRoomPage.ShowPage(false);
				else
					_guihelper.MessageBox(L"请重试！");
				end
			end);
		end
	end, _guihelper.MessageBoxButtons.OKCancel);
end

function TeacherPanel.GetClassName()
	return ClassManager.ClassNameFromId(ClassManager.CurrentClassId) or ClassManager.CurrentClassName;
end

function TeacherPanel.GetClassStudents()
	local count = ClassManager.GetOnlineCount();
	if (count > 0) then
		count = count - 1;
	end
	local student = string.format(L"在课学生：%d人", count);
	return student;
end

function TeacherPanel.Lock()
	TeacherPanel.IsLocked = true;
	if (page) then
		page:Refresh(0);
	end
	ClassManager.SendMessage("cmd:lock");
end

function TeacherPanel.UnLock()
	TeacherPanel.IsLocked = false;
	if (page) then
		page:Refresh(0);
	end
	ClassManager.SendMessage("cmd:unlock");
end

function TeacherPanel.OpenChat()
	TeacherPanel.IsChatting = true;
	if (page) then
		page:Refresh(0);
	end
	TChatRoomPage.ShowPage(true);
end

function TeacherPanel.CloseChat()
	TeacherPanel.IsChatting = false;
	if (page) then
		page:Refresh(0);
	end
end

function TeacherPanel.ConnectClass()
	_guihelper.MessageBox(L"确定要开启联机模式吗？", function(res)
		if(res == _guihelper.DialogResult.OK) then
			GameLogic.RunCommand("/connectGGS -isSyncBlock");
			ClassManager.SendMessage("cmd:connect");
			GameLogic.AddBBS(nil, L"联机成功！", 3000, "0 255 0");
		end
	end, _guihelper.MessageBoxButtons.OKCancel);
end

function TeacherPanel.ShareUrl()
	local orgUrl = ClassManager.GetCurrentOrgUrl();
	if (orgUrl) then
		local ShareUrlPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ShareUrlPage.lua");
		ShareUrlPage.ShowPage()
	else
		ClassManager.LoadAllClasses(function()
			local ShareUrlPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ShareUrlPage.lua");
			ShareUrlPage.ShowPage()
		end);
	end
end

function TeacherPanel.IsClassStarted()
	return ClassManager.InClass;
end

function TeacherPanel.StartClass()
	ClassManager.JoinClassroom(ClassManager.CurrentClassroomId);
	local projectId = GameLogic.options:GetProjectId();
	if (projectId and tonumber(projectId) == ClassManager.CurrentWorldId) then
		if (page) then
			page:Refresh(0);
		else
			TeacherPanel.ShowPage();
		end
	else
		TeacherPanel.EnterTeachingWorld(ClassManager.CurrentWorldId)
	end
end

function TeacherPanel.EnterTeachingWorld(worldId)
	GameLogic:Connect("WorldLoaded", TeacherPanel, TeacherPanel.OnWorldLoaded, "UniqueConnection");
	--GameLogic:Connect("WorldUnloaded", TeacherPanel, TeacherPanel.OnWorldUnload, "UniqueConnection");
	local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
	UserConsole:HandleWorldId(worldId, "force");
end

function TeacherPanel.OnWorldLoaded()
	local projectId = GameLogic.options:GetProjectId();
	if (projectId and tonumber(projectId) == ClassManager.CurrentWorldId) then
		commonlib.TimerManager.SetTimeout(function()
			TeacherPanel.ShowPage();
		end, 1000);
	end
end

function TeacherPanel.OnWorldUnload()
	local projectId = tostring(GameLogic.options:GetProjectId());
end

