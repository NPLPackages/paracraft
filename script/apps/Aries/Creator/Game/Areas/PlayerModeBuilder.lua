--[[
Title: The dock page
Author(s): LiXizhi
Date: 2012/12/28
Desc:  
There dock has 2 mode: one for editor and one for creator
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/PlayerModeBuilder.lua");
local PlayerModeBuilder = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.PlayerModeBuilder");
PlayerModeBuilder.ShowPage(true)
-------------------------------------------------------
]]
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local PlayerModeBuilder = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.PlayerModeBuilder");

function PlayerModeBuilder.OnInit()
end

function PlayerModeBuilder.ShowPage(bShow)
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Areas/PlayerModeBuilder.html", 
			name = "PlayerModeBuilder.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = false,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			bShow = bShow,
			directPosition = true,
			app_key = Desktop.App.app_key, 
			align = "_rb",
				x = -260,
				y = -500,
				width = 250,
				height = 400,
		});
end
