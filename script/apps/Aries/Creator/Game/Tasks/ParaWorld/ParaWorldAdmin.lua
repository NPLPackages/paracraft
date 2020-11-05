--[[
Title: paraworld list
Author(s): chenjinxian
Date: 2020/9/8
Desc: 
use the lib:
------------------------------------------------------------
local ParaWorldAdmin = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldAdmin.lua");
ParaWorldAdmin.ShowPage();
-------------------------------------------------------
]]
local ParaWorldAdmin = NPL.export();

ParaWorldAdmin.WorldList = {};

local username;
local result = _guihelper.DialogResult.Cancel;
local page;
function ParaWorldAdmin.OnInit()
	page = document:GetPageCtrl();
end

function ParaWorldAdmin.ShowPage(user_name, onClose)
	username = user_name;
	result = _guihelper.DialogResult.Cancel;
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldAdmin.html",
		name = "ParaWorldAdmin.ShowPage", 
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
			onClose(result);
		end
	end
end

function ParaWorldAdmin.OnYes()
	result = _guihelper.DialogResult.Yes;
	page:CloseWindow();
end

function ParaWorldAdmin.OnNo()
	result = _guihelper.DialogResult.No;
	page:CloseWindow();
end

function ParaWorldAdmin.OnClose()
	result = _guihelper.DialogResult.Cancel;
	page:CloseWindow();
end

function ParaWorldAdmin.GetInfo()
	if (username) then
		return string.format(L"【%s】已入驻，是否需要？", username);
	else
		return L"已入驻，是否需要？";
	end
end
