--[[
Title: SharePage.html code-behind script
Author(s): LiXizhi
Date: 2010/2/7
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/SharePage.lua");
MyCompany.Aries.Creator.SharePage.ShowPage()
-------------------------------------------------------
]]
local SharePage = commonlib.gettable("MyCompany.Aries.Creator.SharePage")

local page;

function SharePage.ShowPage()
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/SharePage.html", 
			name = "Aries.Creator.SharePage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			isTopLevel = true,
			directPosition = true,
				align = "_ct",
				x = -540/2,
				y = -330/2,
				width = 540,
				height = 330,
		});
end

function SharePage.OnInit()
	page = document:GetPageCtrl();	
end

function SharePage.CloseWindow()
	page:CloseWindow();
end