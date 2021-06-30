--[[
Title: 
Author(s): Chenjinxian
Date: 
Desc: 
use the lib:
-------------------------------------------------------
local CameraViewport = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CameraBlocklyDef/CameraViewport.lua");
CameraViewport.ShowPage()
-------------------------------------------------------
]]
local CameraViewport = NPL.export()

local result = false;
local index = 1;
local page;
function CameraViewport.OnInit()
	page = document:GetPageCtrl();
end

function CameraViewport.ShowPage(_index, onClose)
	index = _index;
	result = false;
	if (page) then
		page:CloseWindow();
	end
	local params = {
		url = "script/apps/Aries/Creator/Game/Code/CameraBlocklyDef/CameraViewport.html", 
		name = "CameraViewport.ShowPage", 
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		click_through = true, 
		directPosition = true,
		align = "_fi", 
		x = 0,
		y = 0,
		width = 0,
		height = 0,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	params._page.OnClose = function()
		if (onClose) then
			onClose(result);
		end
	end
end

function CameraViewport.OnClose()
	result = false;
	if (page) then
		page:CloseWindow();
	end
end

function CameraViewport.OnOK()
	result = true;
	if (page) then
		page:CloseWindow();
	end
end

function CameraViewport.GetIndex()
	return index;
end
