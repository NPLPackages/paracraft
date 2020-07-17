--[[
Title: Class List 
Author(s): Chenjinxian
Date: 2020/7/6
Desc: 
use the lib:
-------------------------------------------------------
local ShareUrlPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ShareUrlPage.lua");
ShareUrlPage.ShowPage()
-------------------------------------------------------
]]
local ShareUrlPage = NPL.export()

local page;

function ShareUrlPage.OnInit()
	page = document:GetPageCtrl();
end

function ShareUrlPage.ShowPage()
	local params = {
		url = "script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ShareUrlPage.html", 
		name = "ShareUrlPage.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		enable_esc_key = true,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
		align = "_ct",
		x = -380 / 2,
		y = -206 / 2,
		width = 380,
		height = 206,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ShareUrlPage.OnClose()
	page:CloseWindow();
end

function ShareUrlPage.ShareClassPage()
end

function ShareUrlPage.ShareOrganPage()
end

function ShareUrlPage.ShareInputUrl()
end
