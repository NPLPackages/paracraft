--[[
Title: VipRewardPage
Author(s): ygy
Date: 2022/2/16
Desc:  
Use Lib:
-------------------------------------------------------
local VipRewardPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/VipRewardPage.lua");
VipRewardPage.ShowPage();
--]]

local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
-- 7天vip奖励
local VipRewardPage = NPL.export()
local page

function VipRewardPage.OnInit()
    page = document:GetPageCtrl();
	page.OnCreate = VipRewardPage.OnCreate
end
function VipRewardPage.RefreshPage()
	if(page)then
		page:Refresh(0);
	end
end
function VipRewardPage.ClosePage()
	if(page)then
		page:CloseWindow(true)
	end
end

function VipRewardPage.SetShow(flag)
	VipRewardPage.need_show = true
end


function VipRewardPage.ShowPage()
	if not VipRewardPage.need_show then
		return
	end

	VipRewardPage.need_show = false
    local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/User/VipRewardPage.html",
			name = "VipRewardPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			zorder = 0,
			directPosition = true,
				align = "_ct",
				x = -488/2,
				y = -373/2,
				width = 488,
				height = 373,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function VipRewardPage.GetUserName()
    local profile = KeepWorkItemManager.GetProfile() or {}
    local player_name = profile.nickname
    if player_name == nil or player_name == "" then
        player_name = profile.username
    end
	return commonlib.GetLimitLabel(player_name)
end