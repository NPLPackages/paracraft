--[[
Title: Show Movie Text
Author(s): LiXizhi
Date: 2013/8/23
Desc: Show Movie Text
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/Mod/MovieText.lua");
local MovieText = commonlib.gettable("MyCompany.Aries.Game.Mod.MovieText");
MovieText.ShowPage(content, function(result)
	if(result == "click_screen") then
		-- user clicks screen to close the text
	end
end)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/Encoding.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/APISandbox/TextToMCML.lua");
local TextToMCML = commonlib.gettable("MyCompany.Aries.Game.APISandbox.TextToMCML");
local NeuronManager = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronManager");
local MovieText = commonlib.gettable("MyCompany.Aries.Game.Mod.MovieText");
NeuronManager.RegisterMod("MovieText", MovieText)

MovieText.version = "1.0";
------------------------
-- page function 
------------------------
local page;
function MovieText.ShowPage(content, callbackFunc)
	MovieText.result = nil;
	if(page) then
		MovieText.OnClose()
	end
	MovieText.callbackFunc = callbackFunc;

	-- for security reason
	content = commonlib.Encoding.EncodeStr(content);

	MovieText.content = content;

	if(content == "") then
		if(page) then
			page:CloseWindow();
		end
		return;
	end

	if(page) then
		if(page:IsVisible()) then
			-- just refresh if already exist
			page:Refresh(0.01);
			return;
		end
	end

	local params = {
		url = if_else(System.options.IsMobilePlatform, "script/apps/Aries/Creator/Game/Neuron/Mod/MovieText.mobile.html", "script/apps/Aries/Creator/Game/Neuron/Mod/MovieText.html"), 
		name = "MovieText.ShowPage", 
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		isShowTitleBar = false,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 100,
		allowDrag = false,
		click_through = false,
		directPosition = true,
			align = "_fi",
			x = 0,
			y = 0,
			width = 0,
			height = 0,
	};
	-- display a page containing all operations that can apply to current selection, like deletion, extruding, coloring, etc. 
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		page = nil;
		MovieText.OnClose();
	end 
end

function MovieText.OnInit()
	page = document:GetPageCtrl();
end

function MovieText.OnClose()
	if(MovieText.callbackFunc) then
		MovieText.callbackFunc(MovieText.result);
	end
end

function MovieText.GetContent()
	if(type(MovieText.content) == "string") then
		return TextToMCML:ConvertTextWikiStyle(MovieText.content);
		-- return MovieText.content;
	end
end