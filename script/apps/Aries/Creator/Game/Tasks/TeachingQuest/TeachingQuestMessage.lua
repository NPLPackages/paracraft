--[[
Title: learning system messagebox
Author(s): 
Date: 
Desc: 
use the lib:
-------------------------------------------------------
local TeachingQuestMessage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestMessage.lua");
TeachingQuestMessage.ShowPage();
-------------------------------------------------------
]]
local TeachingQuestMessage = NPL.export()

local page;
function TeachingQuestMessage.OnInit()
	page = document:GetPageCtrl();
end

function TeachingQuestMessage.ShowPage(OnClose, condition)
	TeachingQuestMessage.result = nil;
	condition = condition or "?name=tip1"
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestMessage.html"..condition, 
		name = "TeachingQuestMessage.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		bToggleShowHide=false, 
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		click_through = false, 
		bShow = true,
		isTopLevel = true,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
			align = "_ct",
			x = -400/2,
			y = -210/2,
			width = 400,
			height = 210,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	params._page.OnClose = function()
		if (OnClose) then
			OnClose(TeachingQuestMessage.result);
		end
	end
end

function TeachingQuestMessage.OnClose()
	page:CloseWindow();
end

function TeachingQuestMessage.OnOK()
	if (page) then
		TeachingQuestMessage.result = "ok";
		page:CloseWindow();
	end
end
