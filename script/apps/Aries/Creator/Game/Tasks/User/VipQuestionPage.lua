--[[
Title: VipQuestionPage
Author(s): leio
Date: 2021/7/9
Desc:  
Use Lib:
-------------------------------------------------------
local VipQuestionPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/VipQuestionPage.lua");
VipQuestionPage.ShowPage();
--]]
local VipQuestionPage = NPL.export()
local page


VipQuestionPage.GridDs = {{}}

function VipQuestionPage.OnInit()
    page = document:GetPageCtrl();
	page.OnCreate = VipQuestionPage.OnCreate
end
function VipQuestionPage.GetPageCtrl()
    return page;
end
function VipQuestionPage.RefreshPage()
	if(page)then
		page:Refresh(0);
	end
end
function VipQuestionPage.ClosePage()
	if(page)then
		page:CloseWindow(true)
	end
end

function VipQuestionPage.ShowPage()
    local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/User/VipQuestionPage.html",
		name = "VipQuestionPage.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		-- allowDrag = true,
		enable_esc_key = true,
		directPosition = true,
		isTopLevel = true,
		zorder = 11,
		align = "_ct",
		x = -323,
		y = -218,
		width = 647,
		height = 437,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params)
end