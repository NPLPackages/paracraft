--[[
Title: 
Author(s): leio
Date: 2017/7/26
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Partners/keepwork/KeepWorkBindingPage.lua");
local KeepWorkBindingPage = commonlib.gettable("MyCompany.Aries.Partners.keepwork.KeepWorkBindingPage");
KeepWorkBindingPage.ShowPage()
-------------------------------------------------------
]]
local KeepWorkBindingPage = commonlib.gettable("MyCompany.Aries.Partners.keepwork.KeepWorkBindingPage");
function KeepWorkBindingPage.ShowPage(user_id)
	if(System.options and System.options.isFromQQHall) then
		_guihelper.MessageBox("请先创建角色")
		return 
	end
    KeepWorkBindingPage.user_id = user_id;
	local width, height = 500, 350;
	local params = {
		url = "script/apps/Aries/Partners/keepwork/KeepWorkBindingPage.html", 
		name = "keepwork.KeepWorkBindingPage", 
		isShowTitleBar = false,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		enable_esc_key = true,
		isTopLevel = true,
		zorder = 1000,
		directPosition = true,
			align = "_ct",
			x = -width/2,
			y = -height/2 + 50,
			width = width,
			height = height,
	};
	
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end
