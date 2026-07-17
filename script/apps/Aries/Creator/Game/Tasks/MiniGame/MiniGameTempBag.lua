--[[
    author: pbb
    date: 2025-04-08
    useLib: 
        local MiniGameTempBag = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameTempBag.lua")
        MiniGameTempBag.ShowTempBag()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/SkinDrawSystem.lua");
local SkinDrawSystem = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.SkinDrawSystem");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
local env
if (type(System.os.IsEmscripten) == 'function' and System.os.IsEmscripten()) then
    env = 'asIframeInWebParacraft'
else
    env = 'asWebviewInParacraftClient'
end
local base_url = string.format("https://keepwork.com/public/resource/miniGameProxy.html?projectPath=maisi/maisi/webgames/data&gameName=user_temp_bag&%s=true",env)

local MiniGamePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGamePage.lua")
local MiniGameTempBag = NPL.export()

function MiniGameTempBag.ShowTempBag()
    local userId = Mod.WorldShare.Store:Get('user/userId') or ""
    local url = base_url .. "&userId=" .. userId
    MiniGamePage.OpenBrowser(url,function()
                
    end)
end

function MiniGameTempBag.CloseTempBag()
    MiniGamePage.ClosePage()
end

function MiniGameTempBag.OnRecvMessage(msg)
    if msg and msg.type == "getTempBagData" then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/VirtualBagManager.lua");
        local VirtualBagManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.VirtualBagManager")
        local tempBagData = VirtualBagManager.GetTempBagData()
        if tempBagData then
            MiniGameTempBag.HandleTempBagData(tempBagData)
        end
    elseif msg and msg.type == "showTempBagVip" then
        MiniGameTempBag.CloseTempBag()
        
        commonlib.TimerManager.SetTimeout(function()
            local MiniGameMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMainPage.lua");
            MiniGameMainPage.StartWebGame("game_activities",{type="vip"}, true)
        end, 200)
    end
end

function MiniGameTempBag.SendTempBagData(sendData)
    local msg = {
        type="setGameConfig",
        data = sendData
    }
    GameLogic.MiniGameMgr:SendMessage("user_temp_bag",msg)
end

-- 处理临时背包数据，根据price区分去quality 和 rarity
function MiniGameTempBag.HandleTempBagData(bagData)
    if not bagData or #bagData == 0 then
        return
    end
    local sendData = {}

    for _, item in ipairs(bagData) do
        if item.bagType == "action" then
            local actionItem = PlayerAssetFile:GetAnimationItem(item.id)
            local rarity = SkinDrawSystem:GetSkinRarity(actionItem)
            sendData[#sendData+1] = {
                id = actionItem.id,
                name = System.Encoding.base64(actionItem.displayname),
                quantity = 1,
                category = "action",
                rarity = string.lower(rarity),
                temporary = true,
                expireAt = item.expireAt,
            }
        elseif item.bagType == "skin" then
            local skinItem = CustomCharItems:GetItemInCategoryById(item.id)
            if item.category ~= "suit" then
                local rarity = SkinDrawSystem:GetSkinRarity(skinItem)
                sendData[#sendData+1] = {
                    id = skinItem.id,
                    name = System.Encoding.base64(skinItem.name),
                    quantity = 1,
                    category = item.category,
                    rarity = string.lower(rarity),
                    temporary = true,
                    expireAt = item.expireAt,
                }
            end
        end
    end

    MiniGameTempBag.SendTempBagData(sendData)
end