--[[
Title: QuestDialogPage
Author(s): yangguiyi
Date: 2021/01/17
Desc:  
Use Lib:
-------------------------------------------------------
local QuestDialogPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestDialogPage.lua");
QuestDialogPage.Show();
--]]
local QuestDialogPage = NPL.export();
local page;
QuestDialogPage.DialogData = {}
QuestDialogPage.CurDialogContent = ""
QuestDialogPage.end_callback = nil

function QuestDialogPage.OnInit()
	page = document:GetPageCtrl();
	page.OnClose = QuestDialogPage.CloseView
	page.OnCreate = QuestDialogPage.OnCreate()
end

function QuestDialogPage.OnCreate()
end

function QuestDialogPage.CloseView()
	QuestDialogPage.DialogData = {}
	QuestDialogPage.CurDialogContent = ""
	QuestDialogPage.end_callback = nil
end

function QuestDialogPage.Show(dialog_data, end_callback)
	if dialog_data == nil then
		return
	end

	if type(dialog_data) == "table" then
		QuestDialogPage.DialogData = dialog_data
	else
		table.insert(QuestDialogPage.DialogData, dialog_data)
	end
	QuestDialogPage.end_callback = end_callback
	QuestDialogPage.CurDialogContent = table.remove(QuestDialogPage.DialogData, 1)
	QuestDialogPage.ShowView()
end

function QuestDialogPage.ShowView()
	if page and page:IsVisible() then
		return
	end
	
	local view_width = 960
	local view_height = 580
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/Quest/QuestDialogPage.html",
			name = "QuestDialogPage.Show", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			zorder = 0,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
			align = "_fi",
			x = 0,
			y = 0,
			bAutoSize=true,
			width = 0,
			height = 0,
			isTopLevel = true
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function QuestDialogPage.GetCurDialogContent()
	return QuestDialogPage.CurDialogContent or ""
end

function QuestDialogPage.ToNextDialog()
	if page == nil then
		return
	end

	if #QuestDialogPage.DialogData == 0 then
		if QuestDialogPage.end_callback then
			QuestDialogPage.end_callback()
			QuestDialogPage.end_callback = nil
		end

		page:CloseWindow()
		QuestDialogPage.CloseView()
		return
	end

	QuestDialogPage.CurDialogContent = table.remove(QuestDialogPage.DialogData, 1)
	page:Refresh(0)
end