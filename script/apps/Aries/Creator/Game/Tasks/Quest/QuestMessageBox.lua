--[[
Title: QuestMessageBox
Author(s): yangguiyi
Date: 2021/2/4
Desc:  
Use Lib:
-------------------------------------------------------
local QuestMessageBox = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestMessageBox.lua");
QuestMessageBox.Show();
--]]
local QuestMessageBox = NPL.export();
local VipToolNew = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipToolNew.lua")
commonlib.setfield("MyCompany.Aries.Creator.Game.Task.Quest.QuestMessageBox", QuestMessageBox);
local page;

function QuestMessageBox.OnInit()
	page = document:GetPageCtrl();
	page.OnClose = QuestMessageBox.CloseView
end

function QuestMessageBox.CloseView()
	-- body
end

function QuestMessageBox.Show(desc, sure_callback)
	QuestMessageBox.sure_callback = sure_callback
	QuestMessageBox.desc = desc or ""
	QuestMessageBox.ShowView()
end

function QuestMessageBox.ShowView()
	if page then
		page:CloseWindow();
	end

	local view_width = 630
	local view_height = 250
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/Quest/QuestMessageBox.html",
			name = "QuestMessageBox.Show", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			zorder = 0,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -view_width/2,
				y = -view_height/2,
				width = view_width,
				height = view_height,
				isTopLevel = true
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);	
end

function QuestMessageBox.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
end

function QuestMessageBox.Sure()
	page:CloseWindow()
	QuestMessageBox.CloseView()
	if QuestMessageBox.sure_callback then
		QuestMessageBox.sure_callback()
	end
end

function QuestMessageBox.OpenVip()
	page:CloseWindow()
	QuestMessageBox.CloseView()
    VipToolNew.Show("AI_lesson")
end

function QuestMessageBox.GetDesc2()
	return QuestMessageBox.desc
end