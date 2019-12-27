--[[
Title: NplMicroRobotAdapterPage
Author(s): leio
Date: 2019.12.25
Desc: 
use the lib:
------------------------------------------------------------
local NplMicroRobotAdapterPage = NPL.load("(gl)script/apps/Aries/Creator/Game/NodeJsRuntime/NplMicroRobotAdapterPage.lua");
NplMicroRobotAdapterPage.ShowPage();
------------------------------------------------------------
]]
local NplMicroRobotAdapterPage = NPL.export();
NplMicroRobotAdapterPage.bones = nil;
NplMicroRobotAdapterPage.callback = nil;
NplMicroRobotAdapterPage.channel_cnt = 16;
NplMicroRobotAdapterPage.url = "script/apps/Aries/Creator/Game/NodeJsRuntime/NplMicroRobotAdapterPage.html";
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
		allowDrag = true,
		zorder = -1,
		directPosition = true,
			align = "_ct",
			x = -500/2,
			y = -600/2,
			width = 500,
			height = 600,
	}
	System.App.Commands.Call("File.MCMLWindowFrame", params);	
end
function NplMicroRobotAdapterPage.GetListName(index)
        return string.format("channel_%s",tostring(index));
end
