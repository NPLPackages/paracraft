--[[
Title: code behind for page ActRedhatNoEnough.html
Author(s): pengbinbin
Date: 2020/12/15
Desc:  script/apps/Aries/Creator/Game/Tasks/ActRedhat/ActRedhatNoEnough.html
Use Lib:
-------------------------------------------------------
	local ActRedhatNoEnough = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActRedhat/ActRedhatNoEnough.lua")
	ActRedhatNoEnough.ShowView()
-------------------------------------------------------
]]
local ActRedhatNoEnough = NPL.export();
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");

local page;
local my_hat = 0
local hat_gisd = 90000;
function ActRedhatNoEnough.OnInit(data)
	page = document:GetPageCtrl();
end

function ActRedhatNoEnough.ShowView()
    local twidth = 396
    local theight = 280
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/ActRedhat/ActRedhatNoEnough.html",
        name = "ActRedhat.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 1,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,                
        align = "_ct",
        x = -twidth/2,
        y = -theight/2,
        width = twidth,
        height = theight,
    };                
    System.App.Commands.Call("File.MCMLWindowFrame", params)
end

function ActRedhatNoEnough.getLeftHat()
    local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(hat_gisd)
	my_hat = copies or 0;

	return my_hat
end