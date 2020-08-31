--[[
Title: TeachingQuestLinkPage
Author(s): 
Date: 2020/8/6
Desc:  
Use Lib:
-------------------------------------------------------
local TeachingQuestLinkPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/TeachingQuestLinkPage.lua");
TeachingQuestLinkPage.ShowPage();
--]]
local TeachingQuestLinkPage = NPL.export()
local page
function TeachingQuestLinkPage.OnInit()
    page = document:GetPageCtrl();
end
function TeachingQuestLinkPage.ShowPage()
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/User/TeachingQuestLinkPage.html",
			name = "TeachingQuestLinkPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			zorder = 0,
			--app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -400/2,
				y = -250/2,
				width = 400,
				height = 250,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end