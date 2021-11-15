--[[
Title: LanQiaoBeiPage
Author(s):
Date: 2021/10/13
Desc:
Use Lib:
-------------------------------------------------------
local LanQiaoBeiPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Race/LanQiaoBeiPage.lua")
LanQiaoBeiPage.Show()
--]]

local LanQiaoBeiPage = NPL.export()
LanQiaoBeiPage.index = 1

local page

function LanQiaoBeiPage.OnInit()
	page = document:GetPageCtrl()
end

function LanQiaoBeiPage.Show()
	local view_width = LanQiaoBeiPage.index== 1 and 584 or 790
    local view_height = 700
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/Race/LanQiaoBeiPage.html",
			name = "LanQiaoBeiPage.Show",
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = false,
			cancelShowAnimation = true,
			isTopLevel = true,
			is_click_to_close = true,
			--app_key = 0,
			directPosition = true,
			align = "_ct",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
		}
	System.App.Commands.Call("File.MCMLWindowFrame", params)
end

function  LanQiaoBeiPage.SetSelectIndex(index)
	LanQiaoBeiPage.index = index
end