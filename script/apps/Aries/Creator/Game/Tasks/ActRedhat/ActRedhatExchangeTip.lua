--[[
Title: code behind for page ActRedhatExchangeTip.html
Author(s): pengbinbin
Date: 2020/12/15
Desc:  script/apps/Aries/Creator/Game/Tasks/ActRedhat/ActRedhatExchangeTip.html
Use Lib:
-------------------------------------------------------
    local tblData = {
        idx = 2,
        exid = 30002,
        name = "世界喇叭",
        needhat = "2个",
        num = 2,
        icon = "Texture/Aries/Creator/keepwork/items/item_30002_32bits.png",
        isrepeat = true,
    }
    local ActRedhatExchangeTip = NPL.load("script/apps/Aries/Creator/Game/Tasks/ActRedhat/ActRedhatExchangeTip.lua")
    ActRedhatExchangeTip.ShowView(tblData)
-------------------------------------------------------
]]
local ActRedhatExchangeTip = NPL.export();
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local ActRedhatExchangeSuc = NPL.load("script/apps/Aries/Creator/Game/Tasks/ActRedhat/ActRedhatExchangeSuc.lua")
local ActRedhatExchange = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActRedhat/ActRedhatExchange.lua")
local page;
local hat_gisd = 90000;
ActRedhatExchangeTip.itemData = nil
function ActRedhatExchangeTip.OnInit()
	page = document:GetPageCtrl();
end

function ActRedhatExchangeTip.ShowView(data)
    local twidth = 396
    local theight = 280
    ActRedhatExchangeTip.itemData = data
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/ActRedhat/ActRedhatExchangeTip.html",
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

function ActRedhatExchangeTip.getLeftHat()
    local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(hat_gisd)
	local my_hat = copies or 0;

	return my_hat
end

function ActRedhatExchangeTip.getTipsDesc()
    local needhat = ActRedhatExchangeTip.itemData.num or 0
    local have_num = ActRedhatExchangeTip.getLeftHat()
    local str = string.format("需要%d个爷爷的帽子，您现有%d个爷爷的帽子，确定要兑换吗？",needhat,have_num)
    return str
end

function ActRedhatExchangeTip.getItemIcon()
    local itemIcon = ActRedhatExchangeTip.itemData.icon or "Texture/Aries/Creator/keepwork/items/item_90000_32bits.png"
    return itemIcon
end

function ActRedhatExchangeTip.onClickExchange()
    local exid = ActRedhatExchangeTip.itemData.exid
    page:CloseWindow()
    KeepWorkItemManager.DoExtendedCost(exid, function()        
        ActRedhatExchangeTip.openGetItemView(ActRedhatExchangeTip.itemData)
		GameLogic.GetFilters():apply_filters("user_behavior", 1 ,ActRedhatExchangeTip.itemData.user_behavior);
    end,function() 
        GameLogic.AddBBS("statusBar", L"兑换失败!", 3000, "0 255 0");
    end);

end

function ActRedhatExchangeTip.openGetItemView(data)
    if ActRedhatExchangeSuc then
        ActRedhatExchangeSuc.ShowView(data)
        if ActRedhatExchange.isOpen then
            ActRedhatExchange.flushView()
        end
    end
end