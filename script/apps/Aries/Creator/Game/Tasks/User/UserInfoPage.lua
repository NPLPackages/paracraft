--[[
Title: UserInfoPage
Author(s): 
Date: 2020/8/6
Desc:  
Use Lib:
-------------------------------------------------------
local UserInfoPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserInfoPage.lua");
UserInfoPage.ShowPage();
--]]
local UserInfoPage = NPL.export()
local page
function UserInfoPage.OnInit()
    page = document:GetPageCtrl();
end
function UserInfoPage.ShowPage()
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/User/UserInfoPage.html",
			name = "UserInfoPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			zorder = 100,
			--app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -600/2,
				y = -500/2,
				width = 600,
				height = 500,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end