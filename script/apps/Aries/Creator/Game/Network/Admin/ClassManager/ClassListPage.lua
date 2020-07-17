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
local ClassListPage = NPL.export()

local page;

function ClassListPage.OnInit()
	page = document:GetPageCtrl();
end

function ClassListPage.ShowPage()
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
end

function ClassListPage.OnClose()
	page:CloseWindow();
end

function ClassListPage.GetClassList()
	local classes = {}
	return classes;
end

function ClassListPage.OnSelectClass(name, value)
end

function ClassListPage.OnRemoveClass(value)
end

function ClassListPage.WriteClassName(name, mcmlNode)
	if (page) then
		local value = mcmlNode:GetUIValue();
		page:SetValue("ClassList", value);
	end
end

function ClassListPage.GetWorldList()
end

function ClassListPage.OnSelectWorld(name, value)
end

function ClassListPage.OnRemoveWorld(value)
end

function ClassListPage.WriteWorldName(name, mcmlNode)
	if (page) then
		local name = mcmlNode:GetUIValue();
		page:SetValue("WorldList", name);
	end
end

function ClassListPage.OnOK()
	local class = page:GetValue("ClassList");
	local world = page:GetValue("WorldList");
	if (class and #class > 0) then
		page:CloseWindow();
		local TeacherPanel = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/TeacherPanel.lua");
		TeacherPanel.SetInClass(class, world);
	else
		_guihelper.MessageBox(L"请输入班级名和世界ID");
	end
end
