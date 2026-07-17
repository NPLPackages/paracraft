--[[
Title: Bag Full Tip
Author: pbb
Date: 2025-09-08
Desc: 背包已满提示
Use Lib:
    local BagFullTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/BagFullTip.lua")
    BagFullTip.Show()
]]

local BagFullTip = NPL.export()

local page 

function BagFullTip.OnInit()
    page = document:GetPageCtrl()
end

function BagFullTip.Show()
    local view_width = 192
    local view_height = 96
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/MiniGame/BagFullTip.html",
        name = "BagFullTip.Show",
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide = false,
        enable_esc_key = false,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        zorder = -10,
        directPosition = true,
        click_through = false,
        align = "_ctb",
        x = -view_width - 40,
        y = -view_height + 30 ,
        width = view_width,
        height = view_height,
        DesignResolutionWidth = 1280,
        DesignResolutionHeight = 720,
    }

    System.App.Commands.Call("File.MCMLWindowFrame", params)
end

function  BagFullTip.ShowTempBag()
    local MiniGameTempBag = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameTempBag.lua")
    MiniGameTempBag.ShowTempBag()
end