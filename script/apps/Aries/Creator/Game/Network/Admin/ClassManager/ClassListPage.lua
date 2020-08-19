--[[
Title: Class List 
Author(s): Chenjinxian
Date: 2020/7/6
Desc: 
use the lib:
-------------------------------------------------------
local ClassListPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ClassListPage.lua");
ClassListPage.ShowPage()
-------------------------------------------------------
]]
local ClassManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ClassManager.lua");
local ClassListPage = NPL.export()

local page;

function ClassListPage.OnInit()
	page = document:GetPageCtrl();
end

function ClassListPage.ShowPage(onClose)
	ClassListPage.result = false;
	local params = {
		url = "script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ClassListPage.html", 
		name = "ClassListPage.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		enable_esc_key = true,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
		align = "_ct",
		x = -370 / 2,
		y = -230 / 2,
		width = 370,
		height = 230,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	params._page.OnClose = function()
		if(onClose) then
			onClose(ClassListPage.result);
		end
	end

	if (#ClassManager.ClassList > 0) then
		page:SetValue("ClassList", ClassManager.ClassList[1].classId);
	end
	if (#ClassManager.ProjectList > 0) then
		page:SetValue("WorldList", ClassManager.ProjectList[1].projectId);
	end
end

function ClassListPage.OnClose()
	page:CloseWindow();
end

function ClassListPage.GetClassList()
	local classes = {};
	for i = 1, #ClassManager.ClassList do
		classes[i] = {text = ClassManager.ClassList[i].name, value = ClassManager.ClassList[i].classId};
	end
	return classes;
end

function ClassListPage.OnSelectClass(name, value)
end

function ClassListPage.OnRemoveClass(value)
end

function ClassListPage.GetWorldList()
	local worldList = {};
	for i = 1, #ClassManager.ProjectList do
		worldList[i] = {text = ClassManager.ProjectList[i].projectName.."("..ClassManager.ProjectList[i].projectId..")", value = ClassManager.ProjectList[i].projectId};
	end
	return worldList;
end

function ClassListPage.OnSelectWorld(name, value)
end

function ClassListPage.OnRemoveWorld(value)
end

function ClassListPage.OnOK()
	local classId = page:GetValue("ClassList", nil);
	local worldId = page:GetValue("WorldList", nil);
	classId = tonumber(classId);
	worldId = tonumber(worldId);
	if (classId and worldId) then
		ClassManager.CreateClassroom(classId, worldId, function(result, data)
			if (result) then
				ClassListPage.result = true;
				page:CloseWindow();
			else
				_guihelper.MessageBox(L"所选择的班级或世界ID无效");
			end
		end);
	else
		_guihelper.MessageBox(L"请选择班级和世界ID");
	end
end
