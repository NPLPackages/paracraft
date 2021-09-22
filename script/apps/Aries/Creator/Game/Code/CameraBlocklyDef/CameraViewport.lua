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

	NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
	local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
	local viewport = ViewportManager:GetSceneViewport();
	local _parent = viewport:GetUIObject(true)

	page = page or System.mcml.PageCtrl:new({
		url="script/apps/Aries/Creator/Game/Code/CameraBlocklyDef/CameraViewport.html",
		click_through = true,
	});
	CameraViewport.onCloseCallback = onClose;
	page:Create("CameraViewport.ShowPage", _parent, "_ct", -200, -150, 400, 300)
end

function CameraViewport.CloseWindow()
	if (page) then
		page:Close();

		if(CameraViewport.onCloseCallback) then
			CameraViewport.onCloseCallback(result);
			CameraViewport.onCloseCallback = nil;
		end
	end
end

function CameraViewport.OnClose()
	CameraViewport.CloseWindow()
end

function CameraViewport.OnOK()
	result = true;
	CameraViewport.CloseWindow()
end

function CameraViewport.GetIndex()
	return index;
end
