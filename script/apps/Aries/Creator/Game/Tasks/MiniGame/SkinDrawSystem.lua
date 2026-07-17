--[[
Title: SkinDrawSystem - 皮肤抽取系统
Author(s): System
Date: 2025
Desc: 独立的皮肤抽取系统，包含皮肤抽取、购买、统计等功能

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/SkinDrawSystem.lua");
local SkinDrawSystem = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.SkinDrawSystem");

-- 随机抽取3个皮肤
SkinDrawSystem:RandomDrawSkins(3, nil, nil, function(skins)
    -- 处理抽取结果
end)

-- 智能抽取5个皮肤，保证至少1个稀有
SkinDrawSystem:SmartDrawSkins(5, true, function(skins)
    -- 处理抽取结果
end)

-- 按分类抽取：1个发型，1个衣服，1个裤子
SkinDrawSystem:DrawSkinsByCategory({hair=1, shirt=1, pants=1}, function(skins)
    -- 处理抽取结果
end)

-- 获取统计信息
local stats = SkinDrawSystem:GetSkinDrawStats()
------------------------------------------------------------
--]]

-- 依赖模块加载
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local Keepwork = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/Keepwork.lua")
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems");
local SkinManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/SkinManager.lua");

local SkinDrawSystem = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.SkinDrawSystem"));

-- 皮肤抽取相关常量配置
local SKIN_ITEM_TYPE = {
    FREE = "0",
    SVIP = "1",
    ONLY_BEANS_CAN_PURCHASE = "2",
    ACTIVITY_GOOD = "3",
    VIP = "4",
    SUIT_PART = "5"
}

-- 皮肤分类权重配置
local SKIN_CATEGORY_WEIGHTS = {
    hair = 20,      -- 发型
    eye = 15,      -- 眼睛
    mouth = 10,       -- 嘴巴
    shirt = 10,     -- 衣服
    pants = 15,       -- 裤子
    right_hand_equipment = 20,      -- 手持
    back = 10       -- 背部
}

-- 皮肤稀有度配置
local SKIN_RARITY_CONFIG = {
    COMMON = {
        name = "普通",
        weight = 60, -- 抽取权重
        color = "#FFFFFF",
        minPrice = 0,
        maxPrice = 19
    },
    RARE = {
        name = "稀有", 
        weight = 25,
        color = "#4169E1",
        minPrice = 20,
        maxPrice = 49
    },
    EPIC = {
        name = "史诗",
        weight = 10,
        color = "#9932CC", 
        minPrice = 50,
        maxPrice = 99
    },
    LEGENDARY = {
        name = "传说",
        weight = 5,
        color = "#FFD700",
        minPrice = 100,
        maxPrice = 999999
    }
}

function SkinDrawSystem:ctor()
    CustomCharItems:Init()
end

-- 获取所有可抽取的皮肤数据
function SkinDrawSystem:GetAllDrawableSkins()
    local allSkins = {}
    local categories = { "hair", "shirt", "eye", "mouth", "pants", "right_hand_equipment", "back" }
    local modelUrl = "character/CC/02human/CustomGeoset/actor.x"
    for _, category in ipairs(categories) do
        local categoryItems = CustomCharItems:GetModelItems(modelUrl, category, "", true) or {}
        
        for _, item in ipairs(categoryItems) do
            -- 过滤可抽取的皮肤
            if self:IsSkinDrawable(item) then
                -- 设置皮肤稀有度
                item.rarity = self:GetSkinRarity(item)
                item.category = category
                table.insert(allSkins, item)
            end
        end
    end
    
    return allSkins
end

-- 判断皮肤是否可抽取
function SkinDrawSystem:IsSkinDrawable(skinItem)
    if not skinItem or not skinItem.id then
        return false
    end
    
    -- 排除已拥有的皮肤
    if self:IsPlayerOwnedSkin(skinItem.id) then
        return false
    end
    
    -- 只包含知识豆可购买的皮肤
    if skinItem.price and tonumber(skinItem.price) > 0 then
        return true
    end
    
    return false
end

-- 检查玩家是否已拥有该皮肤
function SkinDrawSystem:IsPlayerOwnedSkin(skinId)
    local serverSkins = SkinManager.GetServerSkinData() or {}
    
    for _, skin in ipairs(serverSkins) do
        if skin.itemId == tonumber(skinId) then
            return true
        end
    end
    
    return false
end

-- 获取皮肤稀有度
function SkinDrawSystem:GetSkinRarity(skinItem)
    if not skinItem or not skinItem.price then
        return "COMMON"
    end
    
    local price = tonumber(skinItem.price) or 0
    
    -- 根据价格区间判断稀有度
    for rarity, config in pairs(SKIN_RARITY_CONFIG) do
        if price >= config.minPrice and price <= config.maxPrice then
            return rarity
        end
    end
    
    return "COMMON"
end

-- 获取稀有度显示名称
function SkinDrawSystem:GetRarityDisplayName(rarity)
    local config = SKIN_RARITY_CONFIG[rarity]
    return config and config.name or "普通"
end

-- 获取稀有度颜色
function SkinDrawSystem:GetRarityColor(rarity) 
    local config = SKIN_RARITY_CONFIG[rarity]
    return config and config.color or "#FFFFFF"
end

-- 根据权重随机选择稀有度
function SkinDrawSystem:GetRandomRarity()
    local totalWeight = 0
    for _, config in pairs(SKIN_RARITY_CONFIG) do
        totalWeight = totalWeight + config.weight
    end
    
    local randomValue = math.random(1, totalWeight)
    local currentWeight = 0
    
    for rarity, config in pairs(SKIN_RARITY_CONFIG) do
        currentWeight = currentWeight + config.weight
        if randomValue <= currentWeight then
            return rarity
        end
    end
    
    return "COMMON"
end

-- 获取稀有度权重
function SkinDrawSystem:GetRarityWeight(rarity)
    local config = SKIN_RARITY_CONFIG[rarity]
    return config and config.weight or 0
end

-- 检查是否为有效稀有度
function SkinDrawSystem:IsValidRarity(rarity)
    return SKIN_RARITY_CONFIG[rarity] ~= nil
end

-- 根据权重随机选择分类
function SkinDrawSystem:GetRandomCategory()
    local totalWeight = 0
    for _, weight in pairs(SKIN_CATEGORY_WEIGHTS) do
        totalWeight = totalWeight + weight
    end
    
    local randomValue = math.random(1, totalWeight)
    local currentWeight = 0
    
    for category, weight in pairs(SKIN_CATEGORY_WEIGHTS) do
        currentWeight = currentWeight + weight
        if randomValue <= currentWeight then
            return category
        end
    end
    
    return "hair"
end

-- 随机抽取指定数量的皮肤
    
-- @param count: 抽取数量，如果为nil则随机1-5个
-- @param rarityFilter: 稀有度过滤器，可选值："COMMON", "RARE", "EPIC", "LEGENDARY", "LIMITED"
-- @param categoryFilter: 分类过滤器，可选值："hair", "shirt", "eye", "mouth", "pants", "right_hand_equipment", "back"
-- @param callback: 回调函数，参数为抽取结果数组
function SkinDrawSystem:RandomDrawSkins(count, rarityFilter, categoryFilter, callback)
    -- 参数处理
    count = count or math.random(1, 5)
    
    -- 获取所有可抽取皮肤
    local allSkins = self:GetAllDrawableSkins()
    
    if #allSkins == 0 then
        LOG.std(nil, "warn", "SkinDrawSystem", "没有可抽取的皮肤")
        if callback then callback({}) end
        return
    end
    
    -- 应用过滤器
    local filteredSkins = {}
    for _, skin in ipairs(allSkins) do
        local matchRarity = not rarityFilter or skin.rarity == rarityFilter
        local matchCategory = not categoryFilter or skin.category == categoryFilter
        
        if matchRarity and matchCategory then
            table.insert(filteredSkins, skin)
        end
    end
    
    if #filteredSkins == 0 then
        LOG.std(nil, "warn", "SkinDrawSystem", "没有符合条件的皮肤")
        if callback then callback({}) end
        return
    end
    
    -- 随机抽取
    local drawnSkins = {}
    local availableSkins = {}
    
    -- 复制可用皮肤列表
    for _, skin in ipairs(filteredSkins) do
        table.insert(availableSkins, skin)
    end
    
    -- 确保抽取数量不超过可用皮肤数量
    count = math.min(count, #availableSkins)
    
    for i = 1, count do
        if #availableSkins == 0 then
            break
        end
        
        local randomIndex = math.random(1, #availableSkins)
        local selectedSkin = availableSkins[randomIndex]
        
        -- 添加抽取时间戳
        selectedSkin.drawTime = os.time()
        selectedSkin.drawIndex = i
        
        table.insert(drawnSkins, selectedSkin)
        table.remove(availableSkins, randomIndex)
    end
    
    -- 记录抽取日志
    LOG.std(nil, "info", "SkinDrawSystem", string.format("随机抽取了%d个皮肤", #drawnSkins))
    
    if callback then
        callback(drawnSkins)
    end
    
    return drawnSkins
end

-- 智能抽取皮肤（基于稀有度权重）
-- @param count: 抽取数量
-- @param guaranteeRare: 是否保证至少一个稀有皮肤
-- @param callback: 回调函数
function SkinDrawSystem:SmartDrawSkins(count, guaranteeRare, callback)
    count = count or 3
    guaranteeRare = guaranteeRare or false
    
    local allSkins = self:GetAllDrawableSkins()
    
    if #allSkins == 0 then
        LOG.std(nil, "warn", "SkinDrawSystem", "没有可抽取的皮肤")
        if callback then callback({}) end
        return
    end
    
    local drawnSkins = {}
    local availableSkins = {}
    
    -- 复制可用皮肤列表
    for _, skin in ipairs(allSkins) do
        table.insert(availableSkins, skin)
    end
    
    -- 如果需要保证稀有皮肤，先抽取一个稀有以上的皮肤
    if guaranteeRare and count > 0 then
        local rareSkins = {}
        for _, skin in ipairs(availableSkins) do
            if skin.rarity ~= "COMMON" then
                table.insert(rareSkins, skin)
            end
        end
        
        if #rareSkins > 0 then
            local randomIndex = math.random(1, #rareSkins)
            local selectedSkin = rareSkins[randomIndex]
            selectedSkin.drawTime = os.time()
            selectedSkin.drawIndex = 1
            selectedSkin.isGuaranteed = true
            
            table.insert(drawnSkins, selectedSkin)
            
            -- 从可用列表中移除
            for i, skin in ipairs(availableSkins) do
                if skin.id == selectedSkin.id then
                    table.remove(availableSkins, i)
                    break
                end
            end
            
            count = count - 1
        end
    end
    
    -- 抽取剩余皮肤
    for i = 1, count do
        if #availableSkins == 0 then
            break
        end
        
        -- 根据稀有度权重选择
        local targetRarity = self:GetRandomRarity()
        local targetSkins = {}
        
        -- 收集目标稀有度的皮肤
        for _, skin in ipairs(availableSkins) do
            if skin.rarity == targetRarity then
                table.insert(targetSkins, skin)
            end
        end
        
        -- 如果没有目标稀有度的皮肤，从所有可用皮肤中选择
        if #targetSkins == 0 then
            targetSkins = availableSkins
        end
        
        local randomIndex = math.random(1, #targetSkins)
        local selectedSkin = targetSkins[randomIndex]
        
        selectedSkin.drawTime = os.time()
        selectedSkin.drawIndex = #drawnSkins + 1
        
        table.insert(drawnSkins, selectedSkin)
        
        -- 从可用列表中移除
        for j, skin in ipairs(availableSkins) do
            if skin.id == selectedSkin.id then
                table.remove(availableSkins, j)
                break
            end
        end
    end
    
    -- 按稀有度排序（传说>史诗>稀有>普通）
    local rarityOrder = { LEGENDARY = 4, EPIC = 3, RARE = 2, COMMON = 1 }
    table.sort(drawnSkins, function(a, b)
        return (rarityOrder[a.rarity] or 0) > (rarityOrder[b.rarity] or 0)
    end)
    
    -- 重新设置索引
    for i, skin in ipairs(drawnSkins) do
        skin.drawIndex = i
    end
    
    LOG.std(nil, "info", "SkinDrawSystem", string.format("智能抽取了%d个皮肤", #drawnSkins))
    
    if callback then
        callback(drawnSkins)
    end
    
    return drawnSkins
end

-- 按分类抽取皮肤
-- @param categoryCount: 每个分类抽取的数量，格式：{ hair = 1, eye = 1 }
-- @param callback: 回调函数
function SkinDrawSystem:DrawSkinsByCategory(categoryCount, callback)
    categoryCount = categoryCount or { hair = 1, eye = 1 }
    
    local allDrawnSkins = {}
    local totalCount = 0
    
    for category, count in pairs(categoryCount) do
        totalCount = totalCount + count
    end
    
    local completedCategories = 0
    
    for category, count in pairs(categoryCount) do
        self:RandomDrawSkins(count, nil, category, function(skins)
            for _, skin in ipairs(skins) do
                table.insert(allDrawnSkins, skin)
            end
            
            completedCategories = completedCategories + 1
            
            -- 所有分类都完成后调用回调
            if completedCategories >= #categoryCount then
                -- 按分类和稀有度排序
                table.sort(allDrawnSkins, function(a, b)
                    if a.category ~= b.category then
                        return a.category < b.category
                    end
                    local rarityOrder = { LEGENDARY = 4, EPIC = 3, RARE = 2, COMMON = 1 }
                    return (rarityOrder[a.rarity] or 0) > (rarityOrder[b.rarity] or 0)
                end)
                
                -- 重新设置索引
                for i, skin in ipairs(allDrawnSkins) do
                    skin.drawIndex = i
                end
                
                LOG.std(nil, "info", "SkinDrawSystem", string.format("按分类抽取了%d个皮肤", #allDrawnSkins))
                
                if callback then
                    callback(allDrawnSkins)
                end
            end
        end)
    end
end

-- 获取皮肤抽取统计信息
function SkinDrawSystem:GetSkinDrawStats()
    local allSkins = self:GetAllDrawableSkins()
    local stats = {
        total = #allSkins,
        byRarity = {},
        byCategory = {},
        byPrice = { cheap = 0, medium = 0, expensive = 0, luxury = 0 }
    }
    
    -- 统计稀有度分布
    for rarity, _ in pairs(SKIN_RARITY_CONFIG) do
        stats.byRarity[rarity] = 0
    end
    
    -- 统计分类分布
    for category, _ in pairs(SKIN_CATEGORY_WEIGHTS) do
        stats.byCategory[category] = 0
    end
    
    for _, skin in ipairs(allSkins) do
        -- 稀有度统计
        if stats.byRarity[skin.rarity] then
            stats.byRarity[skin.rarity] = stats.byRarity[skin.rarity] + 1
        end
        
        -- 分类统计
        if stats.byCategory[skin.category] then
            stats.byCategory[skin.category] = stats.byCategory[skin.category] + 1
        end
        
        -- 价格统计
        local price = tonumber(skin.price) or 0
        if price < 20 then
            stats.byPrice.cheap = stats.byPrice.cheap + 1
        elseif price < 50 then
            stats.byPrice.medium = stats.byPrice.medium + 1
        elseif price < 100 then
            stats.byPrice.expensive = stats.byPrice.expensive + 1
        else
            stats.byPrice.luxury = stats.byPrice.luxury + 1
        end
    end
    
    return stats
end

-- 添加购买逻辑
function SkinDrawSystem:PurchaseItems(purchaseItems,bFree,callback)
    if not purchaseItems or #purchaseItems == 0 then
        LOG.std(nil, "error", "SkinDrawSystem", "PurchaseItems: No purchase items provided")
        if callback and type(callback) == "function" then
            callback(false, "没有提供购买物品")
        end
        return
    end
    
    -- 检查用户登录状态
    local userId = Mod.WorldShare.Store:Get('user/userId')
    if not userId then
        GameLogic.AddBBS(nil, L"请先登录...")
        if callback and type(callback) == "function" then
            callback(false, "用户未登录")
        end
        return
    end
    
    -- 检查物品是否存在
    local newItems = {}
    for i, item in ipairs(purchaseItems) do
        if CustomCharItems:IsSkinItem(item.id) then 
            table.insert(newItems, item)
        end
    end
    purchaseItems = newItems
    -- 如果是免费购买，直接处理
    if bFree then
        -- 免费购买逻辑
        local time_stamp = os.time()
        local items = {}
        
        for i, item in ipairs(purchaseItems) do
            table.insert(items, {
                category = item.category,
                itemId = tonumber(item.id or item.itemId),
                price = 0, -- 免费
                startAt = commonlib.timehelp.FormatTimeStampToDate(time_stamp)
            })
        end
        
        -- 获取当前皮肤数据并添加新物品
        local currentSkins = SkinManager.GetServerSkinData()
        
        for i, item in ipairs(items) do
            currentSkins[#currentSkins + 1] = item
        end
        
        -- 保存到服务器
        SkinManager.SetServerSkinData(currentSkins, function()
            KeepWorkItemManager.LoadItems(nil, function()
                --GameLogic.AddBBS(nil, L"免费获得成功~", 3000, "255 255 255")
                LOG.std(nil, "info", "SkinDrawSystem", "PurchaseItems: Free purchase success")
                if callback and type(callback) == "function" then
                    callback(true, "免费获得成功")
                end
            end)
        end)
        return
    end
    
    -- 付费购买逻辑
    local totalPrice = 0
    local items = {}
    local time_stamp = os.time()
    
    -- 计算总价格
    for i, item in ipairs(purchaseItems) do
        local price = tonumber(item.price) or 0
        if price > 0 then
            totalPrice = totalPrice + price
            table.insert(items, {
                category = item.category,
                itemId = tonumber(item.id or item.itemId),
                price = price,
                startAt = commonlib.timehelp.FormatTimeStampToDate(time_stamp)
            })
        end
    end
    
    -- 检查是否有需要付费的物品
    if totalPrice <= 0 then
        LOG.std(nil, "warn", "SkinDrawSystem", "PurchaseItems: No paid items found")
        if callback and type(callback) == "function" then
            callback(false, "没有需要付费的物品")
        end
        return
    end
    
    -- 检查知识豆余额
    local myBean = SkinManager.GetBeanNum()
    
    if myBean < totalPrice then
        local tipStr = "你当前拥有" .. myBean .. "知识豆，知识豆不足, 无法购买~"
        GameLogic.AddBBS(nil, tipStr)
        LOG.std(nil, "warn", "SkinDrawSystem", "PurchaseItems: Insufficient knowledge beans")
        if callback and type(callback) == "function" then
            callback(false, tipStr)
        end
        return
    end
    
    -- 消费知识豆
    self:ConsumeKnowledgeBean(totalPrice, function(success)
        if success then
            -- 获取当前皮肤数据并添加新物品
            local currentSkins = SkinManager.GetServerSkinData()
            
            for i, item in ipairs(items) do
                currentSkins[#currentSkins + 1] = item
            end
            
            -- 保存到服务器
            SkinManager.SetServerSkinData(currentSkins, function()
                KeepWorkItemManager.LoadItems(nil, function()
                    --GameLogic.AddBBS(nil, L"购买成功~", 3000, "255 255 255")
                    LOG.std(nil, "info", "SkinDrawSystem", "PurchaseItems: Purchase success, consumed " .. totalPrice .. " knowledge beans")
                    if callback and type(callback) == "function" then
                        callback(true, "购买成功，消费" .. totalPrice .. "知识豆")
                    end
                end)
            end)
        else
            GameLogic.AddBBS(nil, L"购买失败，请稍后再试~")
            LOG.std(nil, "error", "SkinDrawSystem", "PurchaseItems: Failed to consume knowledge beans")
            if callback and type(callback) == "function" then
                callback(false, "知识豆消费失败")
            end
        end
    end)
end

-- 消耗抽卡物品
function SkinDrawSystem:ConsumeDrawSkins(skinDatas)
    local  skinDatas = skinDatas or {}
    -- 获取当前服务器皮肤数据
    local currentSkins = SkinManager.GetServerSkinData() or {}
    local time_stamp = os.time()
    
    -- 将抽取的皮肤添加到服务器数据中
    for i, skinData in ipairs(skinDatas) do
        if skinData.id and skinData.category then
            local newSkinItem = {
                category = skinData.category,
                itemId = tonumber(skinData.id),
                price = 0, -- 抽卡获得的皮肤设为免费
                startAt = commonlib.timehelp.FormatTimeStampToDate(time_stamp)
            }
            table.insert(currentSkins, newSkinItem)
        end
    end
    
    -- 保存到服务器
    SkinManager.SetServerSkinData(currentSkins, function()
        -- 构建新的皮肤字符串
        local newSkinString = SkinDrawSystem:BuildSkinStringFromDrawSkins(skinDatas)
        -- 应用皮肤到主角
        if newSkinString and newSkinString ~= "" then
            SkinDrawSystem:ApplySkinToPlayer(newSkinString)
            LOG.std(nil, "info", "SkinDrawSystem", "ConsumeDrawSkins success, applied skins: " .. newSkinString)
        end
    end)
end

-- 根据抽取的皮肤数据构建皮肤字符串
function SkinDrawSystem:BuildSkinStringFromDrawSkins(skinDatas)
    if not skinDatas or #skinDatas == 0 then
        return CustomCharItems.defaultSkinString
    end
    -- 获取当前主角皮肤
    local currentSkin = GameLogic.GetPlayerController():GetSkinTexture() or CustomCharItems.defaultSkinString
    local buySkin = ""
    for k,v in pairs(skinDatas) do
        if v.id then
            buySkin = buySkin .. v.id .. ";"
        end
    end
    if buySkin == "" then
        return currentSkin
    end
    local newSkinString = CustomCharItems:MergeSkinString(currentSkin, buySkin)
    return newSkinString

end

-- 应用皮肤到主角
function SkinDrawSystem:ApplySkinToPlayer(skinString)
    if not skinString or skinString == "" then
        skinString = CustomCharItems.defaultSkinString
    end
    
    -- 获取主角实体
    local playerEntity = GameLogic.GetPlayerController():GetPlayer()
    if not playerEntity then
        LOG.std(nil, "error", "SkinDrawSystem", "ApplySkinToPlayer: Player entity not found")
        return
    end
    
    -- 设置主角皮肤
    local asset = GameLogic.GetPlayerController():GetMainAssetPath() or "character/CC/02human/CustomGeoset/actor.x"
    playerEntity:SetSkin(skinString)
    playerEntity:SetMainAssetPath(asset)
    
    -- 更新游戏选项
    GameLogic.options:SetMainPlayerAssetName(asset)
    GameLogic.options:SetMainPlayerSkins(skinString)
    GameLogic.GetFilters():apply_filters("user_skin_change", skinString)
    
    -- 更新服务器用户信息
    local userinfo = Keepwork:GetUserInfo()
    if userinfo and userinfo.id then
        local extra = userinfo.extra or {}
        extra.ParacraftPlayerEntityInfo = extra.ParacraftPlayerEntityInfo or {}
        extra.ParacraftPlayerEntityInfo.skin = skinString
        extra.ParacraftPlayerEntityInfo.assetSkinGoodsItemId = 0
        GameLogic.MiniGameMgr:UpdateUserExtra(extra)
    end
end

--消费知识豆
function SkinDrawSystem:ConsumeKnowledgeBean(beanNum,callback)
    local userId = Mod.WorldShare.Store:Get('user/userId')
    if not userId then
        GameLogic.AddBBS(nil,L"请先登录...")
        if callback and type(callback) == "function" then
            callback(false)
        end
        return
    end
    keepwork.user.bean_reduce({
        count = beanNum,
    },function(err,msg,data)
        if err == 200 then
            KeepWorkItemManager.LoadItems(nil,function()
                if callback and type(callback) == "function" then
                    callback(true)
                end
            end)
            LOG.std(nil,"info","SkinDrawSystem","消耗"..beanNum.."知识豆成功")
            return
        end 
        if callback and type(callback) == "function" then
            callback(false)
        end
        GameLogic.AddBBS(nil,L"知识豆不足")
    end)
end

-- 初始化成单列模式
SkinDrawSystem:InitSingleton()