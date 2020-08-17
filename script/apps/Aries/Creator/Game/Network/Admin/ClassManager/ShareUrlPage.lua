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
local ClassManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ClassManager.lua");
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

function ShareUrlPage.ShareOrgPage()
end

function ShareUrlPage.ShareInputUrl()
	local text = page:GetValue("url", nil);
	if (text and text ~= "") then
		ClassManager.SendMessage("link:"..text);
	else
		_guihelper.MessageBox(L"请输入要分享的链接");
	end
end
