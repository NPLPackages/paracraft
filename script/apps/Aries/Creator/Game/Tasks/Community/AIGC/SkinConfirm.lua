--[[
    author:{pbb}
    time:2025-02-18 13:50:48
    uselib:
    local SkinConfirm = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/AIGC/SkinConfirm.lua")
    SkinConfirm.ShowPage(skinData,function(result)
    
end)
]]
local SkinManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/SkinManager.lua")
local SkinConfirm = NPL.export()
SkinConfirm.skinData = nil
SkinConfirm.callback = nil
local totalPrice = 0
local maxSkinNum = 0

local page
function SkinConfirm.OnInit()
    page = document:GetPageCtrl()
end

function SkinConfirm.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function SkinConfirm.ShowPage(skinData, callback)
    SkinConfirm.skinData = skinData or {}
    SkinConfirm.callback = callback
    SkinConfirm.HandleSkinData()
    print("SkinConfirm.ShowPage=========",maxSkinNum)
    if maxSkinNum == 0 then
        if SkinConfirm.callback and type(SkinConfirm.callback) == "function" then
            SkinConfirm.callback(true)
        end
        return
    end
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Community/AIGC/SkinConfirm.html",
        name = "SkinConfirm.ShowPage", 
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
    SkinConfirm.UpdateSkinButton()
end

function SkinConfirm.HandleSkinData()
    local temp = {}
    for i,v in ipairs(SkinConfirm.skinData) do
        if v.price and tonumber(v.price) > 0 then
            temp[#temp+1] = v
            totalPrice = totalPrice + tonumber(v.price)
        end
    end
    maxSkinNum = #temp
    SkinConfirm.skinData = temp
end

function SkinConfirm.GetBuyText()
    local buyNum = 0
    local price = 0
    for i,v in ipairs(SkinConfirm.skinData) do
        price = price + tonumber(v.price)
        buyNum = buyNum + 1
    end
    return string.format("您更换了 <div style='float:left; color:#FF4B4B'> %d </div>件物品，需要支付 <div style='float:left; color:#FF4B4B'> %d </div> 知识币", buyNum, price)
end

function SkinConfirm.OnClickPreview()
    local item_bg = ParaUI.GetUIObject("item_bg")
    if not item_bg or not item_bg:IsValid() then
        return
    end
    item_bg.x = item_bg.x + 110
    if item_bg.x >= 0 then
        item_bg.x = 0
    end
    SkinConfirm.UpdateSkinButton()
end

function SkinConfirm.UpdateSkinButton()
    local preBtn = ParaUI.GetUIObject("SkinConfirm.previewAvatar")
    local nextBtn = ParaUI.GetUIObject("SkinConfirm.nextAvatar")
    if not preBtn or not preBtn:IsValid() or not nextBtn or not nextBtn:IsValid() then
        return
    end
    local basePath = "Texture/Aries/Creator/keepwork/Community/community_userinfo.png#"
    local buttonType = SkinConfirm.GetButtonType()
    if buttonType == 1 then
        preBtn.background = basePath .."215 445 28 26"
        nextBtn.background = basePath .."215 485 28 26"
    elseif buttonType == 2 then
        preBtn.background = basePath .."247 447 28 26"
        nextBtn.background = basePath .."215 485 28 26"
    elseif buttonType == 3 then
        preBtn.background = basePath .."247 447 28 26"
        nextBtn.background = basePath .."281 445 28 26"
    else
        preBtn.background = basePath .."215 445 28 26"
        nextBtn.background = basePath .."281 445 28 26"
    end
end

function SkinConfirm.OnClickNext()
    local item_bg = ParaUI.GetUIObject("item_bg")
    if not item_bg or not item_bg:IsValid() then
        return
    end
    
    item_bg.x = item_bg.x - 110
    local maxWidth = -(maxSkinNum - 3)*110
    if item_bg.x < maxWidth then
        item_bg.x = maxWidth
    end
    SkinConfirm.UpdateSkinButton()
end

function SkinConfirm.GetButtonType()
    local item_bg = ParaUI.GetUIObject("item_bg")
    if not item_bg or not item_bg:IsValid() then
        return 0
    end
    if item_bg.x == 0 then -- 右边
        return 1
    end
    if item_bg.x < 0 and item_bg.x > -(maxSkinNum - 3)*110 then -- 左右
        return 2
    end
    if item_bg.x == -(maxSkinNum - 3)*110 then -- 左边
        return 3
    end
    return 0
end

function SkinConfirm.OnClickFirm()
    SkinConfirm.BuySkin(function()
        SkinConfirm.ClosePage()
        if SkinConfirm.callback and type(SkinConfirm.callback) == "function" then
            SkinConfirm.callback(true)
        end
    end)
end

function SkinConfirm.BuySkin(callback)
    SkinManager.PurchaseSkin(SkinConfirm.skinData,function(result)
        if not result then
            SkinConfirm.ClosePage()
            return
        end
        if callback and type(callback) == "function" then
            callback()
        end
    end)
end
