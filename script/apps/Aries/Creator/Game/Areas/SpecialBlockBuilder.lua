--[[
Title: The dock page
Author(s): LiXizhi
Date: 2012/12/28
Desc:  
There dock has 2 mode: one for editor and one for creator
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/SpecialBlockBuilder.lua");
local SpecialBlockBuilder = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.SpecialBlockBuilder");
SpecialBlockBuilder.ShowPage(true)
-------------------------------------------------------
]]
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local SpecialBlockBuilder = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.SpecialBlockBuilder");

function SpecialBlockBuilder.OnInit()
end

function SpecialBlockBuilder.ShowPage(bShow)
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Areas/SpecialBlockBuilder.html", 
			name = "SpecialBlockBuilder.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = false,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			bShow = bShow,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_rb",
				x = -260,
				y = -500,
				width = 250,
				height = 400,
		});
end
