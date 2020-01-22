--[[
Title: MicrobitEmulatorPage
Author(s): leio
Date: 2020.1.17
Desc: 
use the lib:
------------------------------------------------------------
local MicrobitEmulatorPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicroRobot/MicrobitEmulatorPage.lua");
MicrobitEmulatorPage.ShowPage();
------------------------------------------------------------
]]
local MicrobitEmulatorPage = NPL.export();
MicrobitEmulatorPage.url = "script/apps/Aries/Creator/Game/Code/NplMicroRobot/MicrobitEmulatorPage.html";
function MicrobitEmulatorPage.OnInit()
    MicrobitEmulatorPage.page = document:GetPageCtrl();
end
function MicrobitEmulatorPage.ShowPage()
     local params = {
		url = MicrobitEmulatorPage.url, 
		name = "MicrobitEmulatorPage.ShowPage", 
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
			align = "_lt",
			x = 0,
			y = 80,
			width = 300,
			height = 280,
	}
	System.App.Commands.Call("File.MCMLWindowFrame", params);	
end
