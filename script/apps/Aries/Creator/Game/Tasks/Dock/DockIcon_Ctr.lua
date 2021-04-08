--[[
Title: DockIcon_Ctr
Author(s): pbb
Date: 2021/4/1
Desc:  
Use Lib:
-------------------------------------------------------
local DockIcon_Ctr = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockIcon_Ctr.lua");
DockIcon_Ctr.ShowView();
--]]

local DockIcon_Ctr = NPL.export();
local page;


function DockIcon_Ctr.OnInit()
	page = document:GetPageCtrl();
end

function DockIcon_Ctr.IsHomeWorld()
	local isHomeWorld = false
	local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
	local currentWorldName = WorldCommon.GetWorldTag("name")
	local myName = string.format("%s的家园",System.User.keepworkUsername)
	local myOldName = string.format("%s_main",System.User.keepworkUsername)
	if currentWorldName == myName or currentWorldName == myOldName then
		isHomeWorld = true
	end	
	return isHomeWorld and not System.options.IsMobilePlatform
end

function DockIcon_Ctr.OnRefresh()
	if page then
		page:Refresh(0.1);
	end
end

function DockIcon_Ctr.IsVisible()
	if page then
		return page:IsVisible()
	end
	return false
end

function DockIcon_Ctr.ShowView(bShow)
	if page and page:IsVisible() then
		return
	end
	if not DockIcon_Ctr.IsHomeWorld() then
		return 
	end
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/Dock/DockIcon_Ctr.html",
		name = "DockIcon_Ctr.Show",
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		bShow = bShow,
		zorder = -3,
		ClickThrough = true,
		enable_esc_key = false,
		cancelShowAnimation = true,
		directPosition = true,
		align = "_ctr",
		x = 0,
		y = -70/2,
		width = 190,
		height = 70,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end