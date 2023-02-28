--[[
Title: SpecialAreaVipPage
Author(s): ygy
Date: 2022/7/6
Desc:  
Use Lib:
-------------------------------------------------------
local SpecialAreaVipPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/SpecialAreaVipPage.lua");
SpecialAreaVipPage.ShowPage();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local SpecialAreaVipPage = NPL.export()
local page

function SpecialAreaVipPage.OnInit()
    page = document:GetPageCtrl();
	page.OnCreate = SpecialAreaVipPage.OnCreate
end
function SpecialAreaVipPage.GetPageCtrl()
    return page;
end
function SpecialAreaVipPage.RefreshPage()
	if(page)then
		page:Refresh(0);
	end
end
function SpecialAreaVipPage.ClosePage()
	if(page)then
		page:CloseWindow(true)
	end
end
function SpecialAreaVipPage.VipIsValidCallback()
	SpecialAreaVipPage.ClosePage();
end

function SpecialAreaVipPage.ShowPage(key, desc)
	GameLogic.GetFilters():remove_filter("became_vip", SpecialAreaVipPage.VipIsValidCallback);
	GameLogic.GetFilters():add_filter("became_vip", SpecialAreaVipPage.VipIsValidCallback);
    local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/User/SpecialAreaVipPage.html",
		name = "SpecialAreaVipPage.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		enable_esc_key = true,
		zorder = 10,
		directPosition = true,
		isTopLevel = true,
			align = "_ct",
			x = -488/2,
			y = -344/2,
			width = 488,
			height = 344,
	};
System.App.Commands.Call("File.MCMLWindowFrame", params);
end