--[[
    author: pbb
    date: 2025-09-19
    desc: 皮肤解锁管理器 - 管理皮肤的解锁状态、条件验证和数据持久化
    useLib: 
        local SkinUnLockManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/SkinUnLockManager.lua")
        SkinUnLockManager.Init()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local SkinUnLockManager = NPL.export()

-- 数据存储page名
local SKIN_UNLOCK_DATA_KEY = "skinUnlockData"

local categoryMaps = {
    ["hair"] = true,
    ["eye"] = true,
    ["mouth"] = true,
    ["shirt"] = true,
    ["pants"] = true,
    ["right_hand_equipment"] = true,
    ["back"] = true,
    ["suit"] = true,
    ["action"] = true,
}

-- 皮肤解锁状态数据
local unlockedSkins = {}
local unlockedSkinMap = {}
local skinConfigs = {}
local isInitialized = false

-- 事件回调列表
local eventCallbacks = {
    onSkinUnlocked = {},
    onDataLoaded = {}
}

-- 初始化管理器
function SkinUnLockManager.Init(bForceLoad)
    if isInitialized and not bForceLoad then
        return
    end
    CustomCharItems:Init()
    PlayerAssetFile:Init()
    SkinUnLockManager.LoadUnlockData()
    SkinUnLockManager.LoadSkinConfigs()
    local FriendActionManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/FriendActionManager.lua");
    FriendActionManager.Init()
    local UserBagItemManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/UserBagItemManager.lua");
    UserBagItemManager.Init();
    isInitialized = true
end

function SkinUnLockManager.GetStoreUtil()
    if not SkinUnLockManager.PersonalPageStore then
        NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/PersonalPageStore.lua");
        SkinUnLockManager.PersonalPageStore = commonlib.gettable("MyCompany.Aries.Creator.Game.KeepWork.PersonalPageStore");
    end
    return SkinUnLockManager.PersonalPageStore
end

function SkinUnLockManager.LoadSkinConfigs()
    if not SkinUnLockManager.loadedConfig then
        local skinItemMaps = CustomCharItems.itemsIdMap or {}
        for _, v in pairs(skinItemMaps) do
            if v.data then
                skinConfigs[v.id] = v.data
            else
                skinConfigs[v.id] = v
            end
        end
        local suitItemMaps = CustomCharItems.suitItemIdMap or {}
        for _, v in pairs(suitItemMaps) do
            skinConfigs[v.id] = v
        end

        local animations = PlayerAssetFile:GetAllAnimations()
        for _, v in pairs(animations) do
            skinConfigs[v.id] = v
        end
        SkinUnLockManager.loadedConfig = true
    end
end

function SkinUnLockManager.GetAllSkinConfigs()
    return skinConfigs
end

function SkinUnLockManager.GetSkinConfig(skinId)
    return skinConfigs[skinId]
end

-- 加载解锁数据
function SkinUnLockManager.LoadUnlockData()
    local storeUtil = SkinUnLockManager.GetStoreUtil()
    storeUtil:LoadPageData(SKIN_UNLOCK_DATA_KEY, nil, function(data)
        unlockedSkins = data or {}
        for category, v in pairs(unlockedSkins) do
            if categoryMaps[category] then
                for _, v in pairs(v) do
                    unlockedSkinMap[v] = true
                end
            end
        end
        SkinUnLockManager.TriggerEvent("onDataLoaded", unlockedSkins)
    end)
end

-- 保存解锁数据
function SkinUnLockManager.SaveUnlockData()
    local storeUtil = SkinUnLockManager.GetStoreUtil()
    storeUtil:SaveKeys(SKIN_UNLOCK_DATA_KEY, unlockedSkins)
end

-- 解锁皮肤
function SkinUnLockManager.UnlockSkin(skinId, catgory, skipRequirements, bTemp)
    if not skinId or skinId == "" then
        return false, "物品ID不能为空"
    end
    if not catgory or catgory == "" then
        return false, "分类不能为空"
    end
    if not unlockedSkins[catgory] then
        unlockedSkins[catgory] = {}
    end
    -- 检查物品是否存在
    local skinConfig = skinConfigs[skinId]
    if not skinConfig then
        return false, "物品不存在: " .. skinId
    end
    
    -- 检查是否已解锁
    if SkinUnLockManager.IsUnlocked(skinId) then
        return false, "物品已解锁"
    end
    
    -- 验证解锁条件（除非跳过验证）
    if not skipRequirements then
        local canUnlock, reason = SkinUnLockManager.CanUnlock(skinId)
        if not canUnlock then
            return false, reason or "不满足解锁条件"
        end
    end
    if not bTemp then
        table.insert(unlockedSkins[catgory], skinId)
        SkinUnLockManager.SaveUnlockData()
    end
    unlockedSkinMap[skinId] = true
    SkinUnLockManager.TriggerEvent("onSkinUnlocked", skinId)
    
    return true, "解锁成功"
end

-- 检查皮肤是否已解锁
function SkinUnLockManager.IsUnlocked(skinId)
    return unlockedSkinMap[skinId] ~= nil
end

function SkinUnLockManager.GetUnlockedSkinMap()
    return unlockedSkinMap
end

-- 检查是否可以解锁皮肤
function SkinUnLockManager.CanUnlock(skinId)
    local skinConfig = skinConfigs[skinId]
    if not skinConfig then
        return false, "物品不存在"
    end
    
    -- 已解锁的物品不能重复解锁
    if SkinUnLockManager.IsUnlocked(skinId) then
        return false, "物品已解锁"
    end
    
    -- 默认物品总是可解锁
    if skinConfig.isDefault then
        return true
    end
    
    -- 检查解锁条件
    local requirements = skinConfig.requirements
    if not requirements then
        return true -- 无条件限制
    end
    
    if requirements.type == "vip" then

    end
    
    return true
end

-- 获取已解锁的皮肤列表
function SkinUnLockManager.GetUnlockedSkins()
    local result = {}
    for category, skinIds in pairs(unlockedSkins) do
        if categoryMaps[category] and type(skinIds) == "table" then
            for _, skinId in pairs(skinIds) do
                table.insert(result, {
                    skinId = skinId,
                    category = category,
                    skinConfig = skinConfigs[skinId],
                    unlockData = {category = category, skinId = skinId}
                })
            end
        end
    end
    return result
end

function SkinUnLockManager.GetUnlockedSkinsByCategory(category)
    local result = {}
    if category and unlockedSkins[category] then
        for _, skinId in pairs(unlockedSkins[category]) do
            table.insert(result, {
                skinId = skinId,
                category = category,
                skinConfig = skinConfigs[skinId],
                unlockData = {category = category, skinId = skinId}
            })
        end
    end
    return result
end

-- 锁定皮肤（管理员功能）
function SkinUnLockManager.LockSkin(skinId, category)
    if not skinId or skinId == "" then
        return false, "物品ID不能为空"
    end
    if not category or category == "" then
        return false, "分类不能为空"
    end
    
    local skinConfig = skinConfigs[skinId]
    if skinConfig and skinConfig.isDefault then
        return false, "不能锁定默认物品"
    end
    
    if not SkinUnLockManager.IsUnlocked(skinId) then
        return false, "物品未解锁"
    end
    if unlockedSkins[category] then
        for i, id in ipairs(unlockedSkins[category]) do
            if id == skinId then
                table.remove(unlockedSkins[category], i)
                break
            end
        end
        -- 如果分类为空，删除该分类
        if #unlockedSkins[category] == 0 then
            unlockedSkins[category] = nil
        end
    end
    unlockedSkinMap[skinId] = nil
    SkinUnLockManager.SaveUnlockData()
    SkinUnLockManager.TriggerEvent("onSkinLocked", skinId, category)
    return true, "锁定成功"
end

-- 事件系统
function SkinUnLockManager.RegisterEventCallback(eventType, callback)
    if eventCallbacks[eventType] and type(callback) == "function" then
        table.insert(eventCallbacks[eventType], callback)
        return true
    end
    return false
end

function SkinUnLockManager.TriggerEvent(eventType, ...)
    if eventCallbacks[eventType] then
        for _, callback in ipairs(eventCallbacks[eventType]) do
            pcall(callback, ...)
        end
    end
end