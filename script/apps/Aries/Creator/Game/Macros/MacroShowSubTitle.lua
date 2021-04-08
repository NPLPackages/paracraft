--[[
Title: Macro Show Sub Title
Author(s): LiXizhi
Date: 2021/4/3
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroShowSubTitle.lua");
local MacroShowSubTitle = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroShowSubTitle");
MacroShowSubTitle.ShowPage(text, duration, voiceType);
-------------------------------------------------------
]]
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local MacroShowSubTitle = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroShowSubTitle"));
local page;

function MacroShowSubTitle.OnInit()
	page = document:GetPageCtrl();
	GameLogic.GetFilters():add_filter("Macro_EndRecord", MacroShowSubTitle.CloseWindow);
end

-- @param text: if nil or "", we will close page
-- @param duration: in ms seconds
-- @param voiceType: default to a kid's voice
function MacroShowSubTitle.ShowPage(text, duration, voiceType)
	MacroShowSubTitle.text = text;
	if(page) then
		if(text and text~="") then
			page:Refresh(0.01);
		else
			page:CloseWindow();
		end
		return;
	else
		if(not text or text=="") then
			return;
		end
	end
	

	local params = {
		url = "script/apps/Aries/Creator/Game/Macros/MacroShowSubTitle.html", 
		name = "MacroShowSubTitleTask.ShowPage", 
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		isShowTitleBar = false,
		bShow = true,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 1000,
		bShow = true,
		click_through = true,
		directPosition = true,
			align = "_mb",
			x = 0,
			y = 80,
			width = 0,
			height = 60,
	}
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		page = nil;
	end;
end

function MacroShowSubTitle.CloseWindow()
	if(page) then
		page:CloseWindow();
	end
end