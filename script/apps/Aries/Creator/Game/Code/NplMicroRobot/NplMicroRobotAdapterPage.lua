--[[
Title: NplMicroRobotAdapterPage
Author(s): leio
Date: 2019.12.25
Desc: 
use the lib:
------------------------------------------------------------
local NplMicroRobotAdapterPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicroRobot/NplMicroRobotAdapterPage.lua");
NplMicroRobotAdapterPage.ShowPage();
------------------------------------------------------------
]]
local NplMicroRobotAdapterPage = NPL.export();
NplMicroRobotAdapterPage.bones = nil;
NplMicroRobotAdapterPage.callback = nil;
NplMicroRobotAdapterPage.channel_cnt = 16;
NplMicroRobotAdapterPage.url = "script/apps/Aries/Creator/Game/Code/NplMicroRobot/NplMicroRobotAdapterPage.html";
function NplMicroRobotAdapterPage.OnInit()
    NplMicroRobotAdapterPage.page = document:GetPageCtrl();
end
function NplMicroRobotAdapterPage.ShowPage(bones,callback)
    NplMicroRobotAdapterPage.datasource = bones;
    NplMicroRobotAdapterPage.callback = callback;
     local params = {
		url = NplMicroRobotAdapterPage.url, 
		name = "NplMicroRobotAdapterPage.ShowPage", 
		app_key=MyCompany.Aries.app.app_key, 
		isShowTitleBar = false,
		DestroyOnClose = true, 
		bToggleShowHide = true,
		enable_esc_key = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		zorder = -1,
        click_through = false,
		directPosition = true,
			align = "_lt",
			x = 10,
			y = 100,
			width = 560,
			height = 550,
	}
	System.App.Commands.Call("File.MCMLWindowFrame", params);	
end
function NplMicroRobotAdapterPage.GetListName(index)
        return string.format("channel_%s",tostring(index));
end
