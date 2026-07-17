--[[
    author:{pbb}
    time:2025-02-18 13:50:48
    uselib:
    local BuyConfirm = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/AIGC/BuyConfirm.lua")
    BuyConfirm.ShowPage(skinData,function(result)
    
end)
]]

local BuyConfirm = NPL.export()
local SkinManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/SkinManager.lua")
BuyConfirm.skinData = nil
BuyConfirm.callback = nil
local totalPrice = 0
local maxSkinNum = 0

local page
function BuyConfirm.OnInit()
    page = document:GetPageCtrl()
end

function BuyConfirm.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function BuyConfirm.ShowPage(skinData, callback)
    BuyConfirm.skinData = skinData or {}
    BuyConfirm.callback = callback
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Community/AIGC/BuyConfirm.html",
        name = "BuyConfirm.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        directPosition = true,
        cancelShowAnimation = true,
        align = "_fi",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
function BuyConfirm.GetBeanNum()
	local BEAN_GSID = 998;
	local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(BEAN_GSID)
	return copies or 0;
end

function BuyConfirm.IsVip()
    return KeepWorkItemManager.IsVip()
end

function BuyConfirm.GetBuyText()
    local price = tonumber(BuyConfirm.skinData.price)
    local isVipFree = BuyConfirm.skinData.isVipFree
    local beanNum = BuyConfirm.GetBeanNum()
    if isVipFree == "1" and not BuyConfirm.IsVip() then
        return string.format("你当前有%d知识豆，需要%d知识豆购买，开通会员后可免费获得。", beanNum, price)
    end
    return string.format("你当前有%d知识豆，需要%d知识豆购买。（开通会员后可获得更多专属会员穿搭）", beanNum, price)
end

function BuyConfirm.OnClickFirm()
    BuyConfirm.ClosePage()
    if BuyConfirm.callback and type(BuyConfirm.callback) == "function" then
        BuyConfirm.callback(true)
    end
end

function BuyConfirm.OpenVip()
    local MiniGameMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMainPage.lua");
    MiniGameMainPage.StartWebGame("game_activities",{type="vip"}, true)
end
