--[[
Title: paraworld list
Author(s): chenjinxian
Date: 2020/9/8
Desc: 
use the lib:
------------------------------------------------------------
local ParaWorldAdminSeat = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldAdminSeat.lua");
ParaWorldAdminSeat.ShowPage();
-------------------------------------------------------
]]
local ParaWorldAdminSeat = NPL.export();

ParaWorldAdminSeat.WorldList = {};

local result = false;
local username = nil;
local page;
function ParaWorldAdminSeat.OnInit()
	page = document:GetPageCtrl();
end

function ParaWorldAdminSeat.ShowPage(onClose)
	result = false;
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldAdminSeat.html",
		name = "ParaWorldAdminSeat.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		enable_esc_key = true,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
		align = "_ct",
		x = -400 / 2,
		y = -200 / 2,
		width = 400,
		height = 200,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	params._page.OnClose = function()
		if (onClose) then
			onClose(result, username);
		end
	end
end

function ParaWorldAdminSeat.OnOK()
	username = page:GetValue("user_name", "");
	if (username == "") then
		_guihelper.MessageBox(L"请输入有效的用户名");
		return;
	end
	result = (username ~= nil);
	page:CloseWindow();
end

function ParaWorldAdminSeat.OnClose()
	result = false;
	page:CloseWindow();
end
