--[[
Title: MiniGame User Bag
    Author(s): ParaCraft Team
    Date: 2025/11/18
    Desc: 小游戏背包管理
    Use Lib:
    -------------------------------------------------------
    local InventoryManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/InventoryManager.lua");
]]
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager")
local UserBagItemManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/UserBagItemManager.lua");
local InventoryManager = NPL.export()

local candyPageName = "game_activity_candybox"
local candyItemKey = "gameData.inventory"

local userPageName = "user_inventory"
local userItemKey = "gameData.inventory"

local foodPageName = "food_inventory"
local foodItemKey = "gameData.inventory"


function InventoryManager.GetStoreUtil()
    if not InventoryManager.PersonalPageStore then
        NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/PersonalPageStore.lua");
        InventoryManager.PersonalPageStore = commonlib.gettable("MyCompany.Aries.Creator.Game.KeepWork.PersonalPageStore");
    end
    return InventoryManager.PersonalPageStore
end

local pillIcons = {
    "16045_ColorPill_Green","16046_ColorPill_Purple","16047_ColorPill_Orange","16048_ColorPill_Yellow","16049_ColorPill_DarkLava","16050_ColorPill_DarkBlood"
}
function InventoryManager.GetCandyIcon(item)
    local filepath = "Texture/Aries/Item/%s.png"
    if not item or not item.id then
        return string.format(filepath, "16045_ColorPill_Green")
    end
    local length = string.len(item.id)
    local iconsNum = #pillIcons
    local icon = pillIcons[length%iconsNum + 1]
    return string.format(filepath, icon)
end

function InventoryManager.LoadCandyItems(callback)
    local candyStoreUtil = InventoryManager.GetStoreUtil()
    candyStoreUtil:RefreshPageData(candyPageName)
    candyStoreUtil:LoadPageData(candyPageName, candyItemKey, function(data)
        local candyItems = data and commonlib.deepcopy(data) or {}
        for _, item in ipairs(candyItems) do
            item.icon = InventoryManager.GetCandyIcon(item)
            item.category = "candy"
            item.priority = InventoryManager.GetItemPriority(item)
        end
        InventoryManager.candyItems = candyItems
        InventoryManager.UpdateCandyItems()
        if callback and type(callback) == "function" then
            callback()
        end
    end)
end

function InventoryManager.UpdateCandyItems()
    local newItems = {}
    local isNeedUpdate = false
    local current = InventoryManager.GetServerTime()
    for _, item in ipairs(InventoryManager.candyItems) do
        if item.usedTime and item.usedTime > 0 then
            local expireTime = item.usedTime + 30 * 60
            local deadline = expireTime - current
            if deadline > 0 then
                table.insert(newItems, item)
            else
                if item.count and item.count > 0 then
                    item.usedTime = nil
                    table.insert(newItems, item)
                end
                isNeedUpdate = true
            end
        else
            table.insert(newItems, item)
        end
    end
    if isNeedUpdate then
        InventoryManager.candyItems = newItems
        InventoryManager.SaveCandyItems()
    end
end

function InventoryManager.SaveCandyItems()
    local candyStoreUtil = InventoryManager.GetStoreUtil()
    candyStoreUtil:SavePageData(candyPageName, candyItemKey, InventoryManager.candyItems,true)
end

function InventoryManager.GetItemPriority(item)
    if not item then
        return 0
    end
    local id = item.id
    local name = item.name or ""
    if id == 279 then
        return 9
    end
    if name == "builder" then
        return 10
    end
    if name == "cooking" then
        return 8
    end
    if name == "fishing_rod" then
        return 7
    end
    return item.priority or 0
end

function InventoryManager.GetCandyItemDeadline(item)
    if not item or not item.usedTime then
        return ""
    end
    local current = InventoryManager.GetServerTime()
    local expireTime = item.usedTime + 30 * 60
    local deadline = expireTime - current
    if deadline > 60 then
        local minite = math.ceil(deadline / 60)
        return string.format(L"%d分钟后失效", minite)
    else
        return string.format(L"%d秒后失效", deadline)
    end
end

function InventoryManager.OnClickCandyItem(item, onUsed)
    if not item then
        return
    end
    local isVip = GameLogic.MiniGameMgr:IsVip()
    local isVipRequired = item.vipOnly
    if isVipRequired and not isVip then
        _guihelper.MessageBox(L"您需要成为会员才能使用此物品,是否开通vip", function()
            local MiniGameMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMainPage.lua");
            MiniGameMainPage.StartWebGame("game_activities",{type="vip"}, true)
        end)
        return
    end
    local message = string.format(L"您确定要使用 %s 吗？使用后物品生效时间为30分钟", item.name)
    if item.usedTime and item.usedTime > 0 then
        local current = InventoryManager.GetServerTime()
        local expireTime = item.usedTime + 30 * 60
        local deadline = expireTime - current
        if deadline > 0 then
            local min = math.floor(deadline / 60)
            local second = math.floor(deadline - min * 60)
            message = string.format(L"%s将在%d分%d秒后失效，是否继续使用？", item.name, min, second)
        else
            message = string.format(L"%s 已过期，是否继续使用？", item.name)
        end
    end
    _guihelper.MessageBox(message, function()
        InventoryManager.UseCandyItem(item)
        if onUsed and type(onUsed) == "function" then
            onUsed()
        end
    end)
end

function InventoryManager.UseCandyItem(item)
    if not item or not item.id then
        return
    end
    local current = InventoryManager.GetServerTime()
    local isCanUse = true
    local isNeedUpdate = false
    for i,v in ipairs(InventoryManager.candyItems or {}) do
        if v.id == item.id then
            if v.usedTime and v.usedTime > 0 then
                local expireTime = v.usedTime + 30 * 60
                local deadline = expireTime - current
                if deadline <= 0 then 
                    if v.count and v.count > 0 then
                        v.count = v.count - 1
                        v.usedTime = InventoryManager.GetServerTime()
                        isNeedUpdate = true
                    else
                        table.remove(InventoryManager.candyItems, i)
                        isCanUse = false
                    end
                end
            else
                if v.count and v.count > 0 then
                    v.count = v.count - 1
                    v.usedTime = InventoryManager.GetServerTime()
                    isNeedUpdate = true
                else
                    table.remove(InventoryManager.candyItems, i)
                    isCanUse = false
                end
            end
        end
    end
    if isNeedUpdate then
        InventoryManager.SaveCandyItems()
    end
    if isCanUse then
        local command = item.cmd
        if command and type(command) == "string" then
            GameLogic.RunCommand(command)
        end
        return
    end
    GameLogic.AddBBS(nil,L"使用失败")
end

function InventoryManager.GetDefaultUserItems()
    return {
        {id=279,name="mud", displayname=L"泥土",icon="Texture/blocks/farmland_dry.png"},
        {id=10011,name="fishing_rod", displayname=L"捕鱼道具",icon="Texture/Aries/Creator/keepwork/minigame/bag/fishing_64x64_32bits.png"},
        {id=999998,name="builder", displayname=L"建造",icon="Texture/3DMapSystem/AppIcons/Blueprint_64.dds"},
        {id=999999,name="cooking", displayname=L"烹饪",icon="Texture/Aries/Creator/keepwork/minigame/bag/coking_64x64_32bits.png"},
    }
end

function InventoryManager.LoadUserItems(callback)
    local store = InventoryManager.GetStoreUtil()
    store:RefreshPageData(userPageName)
    store:LoadPageData(userPageName, userItemKey, function(data)
        local items = data and commonlib.deepcopy(data) or {}
        local defaults = InventoryManager.GetDefaultUserItems()
        local exist = {}
        local isNeedUpdate = false
        for _, it in ipairs(items) do
            exist[it.id] = it
        end
        for _, def in ipairs(defaults) do
            if not exist[def.id] then
                table.insert(items, commonlib.deepcopy(def))
                isNeedUpdate = true
            elseif def.icon and def.icon ~= "" and exist[def.id].icon ~= def.icon then
                exist[def.id].icon = def.icon
                isNeedUpdate = true
            elseif def.displayname and def.displayname ~= "" and exist[def.id].displayname ~= def.displayname then
                exist[def.id].displayname = def.displayname
                isNeedUpdate = true
            end
        end
        for _, item in ipairs(items) do
            item.category = "useritem"
            item.priority = InventoryManager.GetItemPriority(item)
            if not item.icon or item.icon == "" then
                item.icon = "Texture/Aries/Creator/keepwork/Mall1/empty_128x128_32bits.png"
                isNeedUpdate = true
            end
        end
        table.sort(items, function(a, b)
            return a.priority > b.priority
        end)
        InventoryManager.userItems = items
        if isNeedUpdate then
            InventoryManager.SaveUserItems()
        end
        if callback and type(callback) == "function" then
            callback()
        end
    end)
end

function InventoryManager.SaveUserItems()
    local store = InventoryManager.GetStoreUtil()
    store:SavePageData(userPageName, userItemKey, InventoryManager.userItems,true)
end

function InventoryManager.UseUserItem(item)
    if not item or not item.id then
        return
    end
    local isCanUse = true
    for i,v in ipairs(InventoryManager.userItems or {}) do
        if v.id == item.id then
            if  v.count then
                if v.count > 0 then
                    v.count = v.count - 1
                else
                    table.remove(InventoryManager.userItems, i)
                    isCanUse = false
                end
            end
            break
        end
    end
    InventoryManager.SaveUserItems()
    if isCanUse then
        local command = item.cmd
        if command and type(command) == "string" then
            GameLogic.RunCommand(command)
        end
        return
    end
    GameLogic.AddBBS(nil,L"使用失败")
end

function InventoryManager.GetFoodType(item)
    if not item or not item.id or not InventoryManager.foodConfigById then
        return
    end
    local foodConfig = InventoryManager.foodConfigById[item.id]
    if foodConfig then
        return foodConfig.food_type
    end
    return nil
end

function InventoryManager.LoadFoodItems(callback)
    local UserBagItemManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/UserBagItemManager.lua");
    UserBagItemManager.LoadFoodConfig(function()
        InventoryManager.foodConfigById = UserBagItemManager.foodConfigById
        local store = InventoryManager.GetStoreUtil()
        store:RefreshPageData(foodPageName)
        store:LoadPageData(foodPageName, foodItemKey, function(data)
            local items = data and commonlib.deepcopy(data) or {}
            for _, item in ipairs(items) do
                item.category = "food"
                item.priority = InventoryManager.GetItemPriority(item)
                if not item.icon or item.icon == "" then
                    item.icon = "Texture/Aries/Creator/keepwork/Mall1/empty_128x128_32bits.png"
                end
            end
            InventoryManager.foodItems = items
            if callback and type(callback) == "function" then
                callback()
            end
        end)
    end)
end

function InventoryManager.SaveFoodItems()
    local store = InventoryManager.GetStoreUtil()
    store:SavePageData(foodPageName, foodItemKey, InventoryManager.foodItems,true)
end

function InventoryManager.ResumeFoodItems(item)
    if not item or not item.id then
        return
    end
    if not InventoryManager.usedFoodItems then
        InventoryManager.usedFoodItems = {}
    end
    if not InventoryManager.usedFoodItems[item.id] then
        InventoryManager.usedFoodItems[item.id] = 0
    end
    InventoryManager.usedFoodItems[item.id] = math.max(0, InventoryManager.usedFoodItems[item.id] - 1)
end

function InventoryManager.UseFoodItem(item, isFromFriend)
    if not item or not item.id then
        return
    end
    local food_type = InventoryManager.GetFoodType(item)
    if not food_type then
        return
    end
    if food_type == 1 then
        if not InventoryManager.usedFoodItems then
            InventoryManager.usedFoodItems = {}
        end
        if not InventoryManager.usedFoodItems[item.id] then
            InventoryManager.usedFoodItems[item.id] = 0
        end
        
        local isCanUse = false
        for i,v in ipairs(InventoryManager.foodItems or {}) do
            if v.id == item.id and v.count > InventoryManager.usedFoodItems[item.id] then
                isCanUse = true
                InventoryManager.usedFoodItems[item.id] = InventoryManager.usedFoodItems[item.id] + 1
                break
            end
        end
        if not isCanUse then
            GameLogic.AddBBS(nil,L"使用失败，数量不足")
            return
        end
        if isFromFriend then
            UserBagItemManager.AddSceneItem(item)
        else
            InventoryManager.RemoveFoodItem(item)
            InventoryManager.EatFoodItem(item)
        end
    elseif food_type == 0 then
        local EasyModelStove = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyModelStove.lua");
        EasyModelStove.EnsureBase()
        GameLogic.GetCodeGlobal():BroadcastTextEvent("on_click_cooking_pot")
    end
end

function InventoryManager.EatFoodItem(item)
    local player = EntityManager.GetPlayer()
    if not player or not item or not item.id then return end
    local foodConfig = UserBagItemManager.GetFoodConfigById(item.id) or {}
    local x, y, z = player:GetPosition()
    local playerName = player:GetUserName()
    local startY = y + (player:GetHeight() or 1.8) + 0.5
    local entityName = playerName.."_"..item.id.."_"..ParaGlobal.GenerateUniqueID()
    x = math.floor(x * 10) / 10
    y = math.floor(startY * 10) / 10
    z = math.floor(z * 10) / 10
    local entity = EntityManager.EntityLiveModel:Create({
        x = x, y = y, z = z,
        item_id = block_types.names.LiveModel,
        name = entityName
    })
    
    entity:SetPersistent(false)
    entity:SetDummy(false)
    entity:SetCanDrag(false)
    entity.nohistory = true
    local icon = item.icon or ""
    local model = item.model or foodConfig.model
    if model and model ~= "" then
        entity:SetModelFile(model)
        entity:Refresh();
    else
        BlockInEntityHand.TransformEntityTo3DTexture(entity, icon)
    end
    local facing = player:GetFacing()
    entity:SetFacing(math.floor(facing * 10) / 10)
    entity:SetScaling(tonumber(item.scale) or 1)
    entity:SetPosition(x, y, z)
    entity:Attach()

    local itemData = {
        id = item.id,
        entityName = entityName,
        eatName = playerName
    }
    UserBagItemManager.PlaySingleEatFoodEffect(itemData,playerName, function()
        UserBagItemManager.UseItem(item)
    end)
end

function InventoryManager.RemoveFoodItem(item)
    if not item or not item.id then
        return
    end
    local isRemove = false
    for i,v in ipairs(InventoryManager.foodItems or {}) do
        if v.id == item.id then
            if v.count and v.count > 0 then
                v.count = v.count - 1
                if v.count <= 0 then
                    table.remove(InventoryManager.foodItems, i)
                end
                isRemove = true
            else
                table.remove(InventoryManager.foodItems, i)
                isRemove = true
            end
            break
        end
    end
    if isRemove then
        InventoryManager.usedFoodItems[item.id] = math.max(0, InventoryManager.usedFoodItems[item.id] - 1)
        InventoryManager.SaveFoodItems()
    end
    return isRemove
end

function InventoryManager.GetCombinedFoodAndCandyItems()
    local list = {}
    local foodItems = InventoryManager.foodItems or {}
    table.sort(foodItems, function(a,b) 
        local aType = InventoryManager.GetFoodType(a)
        local bType = InventoryManager.GetFoodType(b)
        return aType and bType and aType > bType
    end)
    for _, v in ipairs(foodItems) do
        table.insert(list, v)
    end
    
    local candyItems = InventoryManager.candyItems or {}
    for _, v in ipairs(candyItems) do
        table.insert(list, v)
    end
    
    return list
end

function InventoryManager.GetServerTime()
    if System.options.isDevMode then
        return os.time()
    end
    local time_stamp = GameLogic.GetFilters():apply_filters('service.session.get_current_server_time')
    return time_stamp or os.time()
end