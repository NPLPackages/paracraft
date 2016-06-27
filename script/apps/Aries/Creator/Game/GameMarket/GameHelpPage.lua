--[[
Title: Enter Game 
Author(s): LiXizhi
Date: 2013/2/16
Desc:  The very first page shown to the user. It asks the user to create or load or download a game from game market. 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/GameHelpPage.lua");
local GameHelpPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.GameHelpPage");
GameHelpPage.ShowPage(true)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/main.lua");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local GameHelpPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.GameHelpPage");

function GameHelpPage.OnInit()
end

function GameHelpPage.ShowPage(bShow)
	local width, height = 680, 560;
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/GameMarket/GameHelpPage.html", 
			name = "GameHelpPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			bShow = bShow,
			enable_esc_key = true,
			directPosition = true,
				align = "_ct",
				x = -width/2,
				y = -height/2,
				width = width,
				height = height,
		});
end
