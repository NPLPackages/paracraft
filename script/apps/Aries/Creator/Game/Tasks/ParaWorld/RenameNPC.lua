--[[
Title: 
Author(s): chenjinxian
Date: 2020/11/2
Desc: 
use the lib:
------------------------------------------------------------
local RenameNPC = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/RenameNPC.lua");
RenameNPC.ShowPage();
-------------------------------------------------------
]]
local RenameNPC = NPL.export();

local result = nil;
local page;
function RenameNPC.OnInit()
	page = document:GetPageCtrl();
end

function RenameNPC.ShowPage(onClose)
	result = nil;
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/ParaWorld/RenameNPC.html",
		name = "RenameNPC.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		enable_esc_key = true,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
		align = "_ctt",
		x = 0,
		y = 60,
		width = 300,
		height = 100,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	params._page.OnClose = function()
		if (onClose) then
			onClose(result);
		end
	end
end

function RenameNPC.OnClose()
	page:CloseWindow();
end

function RenameNPC.OnOK()
	result = page:GetValue("npc_name");
	if (commonlib.utf8.len(result) > 10) then
		_guihelper.MessageBox(L"输入的名称太长，请控制在10个字以内");
		result = nil;
		return;
	end
	page:CloseWindow();
end
