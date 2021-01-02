--[[
    local ActRedhatExchange = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActRedhat/ActRedhatExchange.lua")
    ActRedhatExchange.ShowView()
]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local ActRedhatExchangeTip = NPL.load("script/apps/Aries/Creator/Game/Tasks/ActRedhat/ActRedhatExchangeTip.lua")
local ActRedhatNoEnough = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActRedhat/ActRedhatNoEnough.lua")
local ActRedhatExchange = NPL.export()
ActRedhatExchange.gisd = 90000
ActRedhatExchange.icon = "Texture/Aries/Creator/keepwork/items/item_90000_32bits.png"
ActRedhatExchange.my_hat = 0
local page
ActRedhatExchange.isOpen = false
ActRedhatExchange.exchangeDatas = 
{
    {
        idx = 1,
        exid = 30002,
        name = "世界喇叭",
        needhat = "2个",
        num = 2,
        itemId = 174,
        icon = "Texture/Aries/Creator/keepwork/items/exid_30002_32bits.png",
        isrepeat = true,
		user_behavior = "click.promotion.horm",
    },
    {
        idx = 2,
        exid = 30001,
        name = "知识豆X100",
        needhat = "10个",
        num = 10,
        itemId = 173,
        icon = "Texture/Aries/Creator/keepwork/items/exid_30001_32bits.png",
        isrepeat = true,
		user_behavior = "click.promotion.knowledge_bean",
    },    
    {
        idx = 3,
        exid = 30003,
        name = "圣诞皮肤",
        needhat = "50个",
        num = 50,
        itemId = 175,
        icon = "Texture/Aries/Creator/keepwork/items/exid_30003_32bits.png",
        isrepeat = false,
		user_behavior = "click.promotion.skin",
    },
}

ActRedhatExchange.cover = {
    {
        cover = "Texture/Aries/Creator/keepwork/ActRedhat/actredhat_bg_640X2863.jpg"
    },
}

function ActRedhatExchange.OnInit()
	page = document:GetPageCtrl();
end

function ActRedhatExchange.CheckCanShow()
    local day_time_stamp = os.time({year = 2021, month = 1, day = 6, hour=0, minute=0, second=0})
    local cur_time_stamp = os.time()
    -- print("time=================",cur_time_stamp,day_time_stamp)
    if cur_time_stamp >= day_time_stamp then
        return false
    end
    return true
end

function ActRedhatExchange.ShowView()
    local view_width = 960
	local view_height = 580
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/ActRedhat/ActRedhatExchange.html",
        name = "ActRedhatExchange.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
            align = "_ct",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    ActRedhatExchange.isOpen = true
end

function ActRedhatExchange.closeView()
    ActRedhatExchange.isOpen = false
end

function ActRedhatExchange.getLeftHat()
    local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(ActRedhatExchange.gisd)
	ActRedhatExchange.my_hat = copies or 0;

	return ActRedhatExchange.my_hat
end

function ActRedhatExchange.OnClickExchange(data)
    local itemData = data
    local isrepeat = itemData.isrepeat
    local needNum = itemData.num
    local exid = itemData.exid
    local myhatNum = ActRedhatExchange.getLeftHat()

    if myhatNum < needNum then
        -- if ActRedhatNoEnough then 
        --     --page:CloseWindow()           
        --     ActRedhatNoEnough.ShowView()
        -- end        
        return
    end

    if isrepeat then
        if ActRedhatExchangeTip then
            --page:CloseWindow()aa
            ActRedhatExchangeTip.ShowView(itemData)
        end
    else
        local gisd1 = 58002
        local gisd2 = 58003
        local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(gisd1)   
        local bHas1,guid1,bagid1,copies1 = KeepWorkItemManager.HasGSItem(gisd2)       
        if not bHas and not bHas1 then
            if ActRedhatExchangeTip then
                --page:CloseWindow()
                ActRedhatExchangeTip.ShowView(itemData)
            end
        else
            _guihelper.MessageBox("圣诞皮肤只可以兑换一次，您已经兑换过了哟")
        end
    end
end

function ActRedhatExchange.flushView()
    if page then
        page:Refresh(0.5)
    end
end


