--[[
Title: RobotHomePage
Author(s): leio
Date: 2020/2/26
Desc: 
use the lib:
------------------------------------------------------------
local RobotHomePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicroRobot/WorkSpace/RobotHomePage.lua");
RobotHomePage.ShowPage();
------------------------------------------------------------
]]
local RobotHomePage = NPL.export();
RobotHomePage.url = "script/apps/Aries/Creator/Game/Code/NplMicroRobot/WorkSpace/RobotHomePage.html";
function RobotHomePage.OnInit()
    RobotHomePage.page = document:GetPageCtrl();
end
function RobotHomePage.ShowPage()
     local params = {
		url = RobotHomePage.url, 
		name = "RobotHomePage.ShowPage", 
		app_key=MyCompany.Aries.app.app_key, 
		isShowTitleBar = false,
		DestroyOnClose = true, 
		bToggleShowHide = false,
		enable_esc_key = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		zorder = -1,
        click_through = false,
		directPosition = true,
			align = "_ct",
			x = -650/2,
			y = -420/2,
			width = 650,
			height = 420,
	}
	System.App.Commands.Call("File.MCMLWindowFrame", params);	
end
