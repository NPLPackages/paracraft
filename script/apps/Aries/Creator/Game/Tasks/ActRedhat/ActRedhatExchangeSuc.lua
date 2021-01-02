--[[
Title: code behind for page ActRedhatExchangeSuc.html
Author(s): pengbinbin
Date: 2020/12/15
Desc:  script/apps/Aries/Creator/Game/Tasks/ActRedhat/ActRedhatExchangeSuc.html
Use Lib:
-------------------------------------------------------
    local ActRedhatExchangeSuc = NPL.load("script/apps/Aries/Creator/Game/Tasks/ActRedhat/ActRedhatExchangeSuc.lua")
    ActRedhatExchangeSuc.ShowView({
        idx = 2,
        exid = 30002,
        name = "世界喇叭",
        needhat = "2个",
        num = 2,
        icon = "Texture/Aries/Creator/keepwork/items/item_30002_32bits.png",
        isrepeat = true,
    })
-------------------------------------------------------
]]
local ActRedhatExchangeSuc = NPL.export();
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");

local page;
local hat_gisd = 90000;
ActRedhatExchangeSuc.itemData = nil
function ActRedhatExchangeSuc.OnInit(data)
	page = document:GetPageCtrl();
end

function ActRedhatExchangeSuc.ShowView(data)
    local twidth = 396
    local theight = 280
    ActRedhatExchangeSuc.itemData = data
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/ActRedhat/ActRedhatExchangeSuc.html",
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

function ActRedhatExchangeSuc.getLeftHat()
    local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(hat_gisd)
	local my_hat = copies or 0;

	return my_hat
end

function ActRedhatExchangeSuc.getTipsDesc()
    local str = string.format("兑换成功！请在人物界面查看您获得的物品")
    return str
end

function ActRedhatExchangeSuc.getItemIcon()
    local itemIcon = ActRedhatExchangeSuc.itemData.icon or "Texture/Aries/Creator/keepwork/items/item_90000_32bits.png"
    return itemIcon
end