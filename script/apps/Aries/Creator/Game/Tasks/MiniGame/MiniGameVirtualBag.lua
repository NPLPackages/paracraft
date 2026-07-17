--[[
    author: pbb
    date: 2025-01-20
    description: 虚拟背包管理逻辑
    40007-排课系统记录用     ----> 虚拟动作背包    免费6， 付费32
    40008-冬奥会课程记录用  ----> 虚拟装备背包    免费6， 付费32
    40010-消防安全数据记录用  --> 虚拟宠物背包  （用户获得的坐骑和宠物）免费3， 付费32
    uselib:
     local VirtualBag = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameVirtualBag.lua")
     local virtualActionBag = VirtualBag:Init(40007, freeCount, vipCount)
     local virtualInventoryBag = VirtualBag:Init(40008, freeCount, vipCount)
     local virtualPetBag = VirtualBag:Init(40010, freeCount, vipCount)
]]

local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");

local VirtualBag = NPL.export()

-- 背包变化监听器
local bagChangeListeners = {}

-- 背包类型配置
local BAG_TYPE_CONFIGS = {
    [40007] = {
        name = "虚拟动作背包",
        default_free_slots = 9999,
        default_paid_slots = 26
    },
    [40008] = {
        name = "虚拟装备背包",
        default_free_slots = 9999,
        default_paid_slots = 26
    },
    [40010] = {
        name = "虚拟宠物背包",
        default_free_slots = 9999,
        default_paid_slots = 26
    }
}

-- 物品过期处理策略
local OVERFLOW_STRATEGY = {
    REPLACE_LAST = "replace_last",  -- 覆盖最后一个slot
    DISCARD = "discard"             -- 丢弃新物品
}

-- 

-- 创建虚拟背包实例
function VirtualBag:Init(gsid, freeCount, vipCount)
    local o = {
        gsid = gsid,
        freeCount = freeCount or (BAG_TYPE_CONFIGS[gsid] and BAG_TYPE_CONFIGS[gsid].default_free_slots) or 6,
        vipCount = vipCount or (BAG_TYPE_CONFIGS[gsid] and BAG_TYPE_CONFIGS[gsid].default_paid_slots) or 26,
        name = BAG_TYPE_CONFIGS[gsid] and BAG_TYPE_CONFIGS[gsid].name or "未知背包"
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

-- 获取服务器背包数据
function VirtualBag:GetServerBagData()
    local clientData = KeepWorkItemManager.GetClientData(self.gsid) or {}
    local items = clientData.items or {}
    
    -- 确保每个物品都有slot信息
    for i, item in ipairs(items) do
        if not item.slot then
            item.slot = i
        end
    end
    return items
end

function VirtualBag:UpdateItems(items)
    if self.gsid ~= 40008 then --只更新皮肤
        return items
    end
    local isVipUser = self:IsVipUser()
    local bagCapacity = self:GetBagCapacity()
    local suitItems = {}
    local skinItems = {}
    for _, item in ipairs(items) do
        if item.category == "suit" then
            table.insert(suitItems, item)
        else
            table.insert(skinItems, item)
        end
    end
    local newItems = {}
    local remainSkinItems = {}
    local slot = 1
    for _, item in ipairs(suitItems) do
        item.slot = slot
        slot = slot + 1
        table.insert(newItems, item)
    end

    for _, item in ipairs(skinItems) do
        item.slot = slot
        slot = slot + 1
        table.insert(newItems, item)
    end
    self:SetServerBagData(newItems)
    return newItems
end

-- 设置服务器背包数据
function VirtualBag:SetServerBagData(items, callback)
    local clientData = KeepWorkItemManager.GetClientData(self.gsid) or {}
    clientData.items = items
    
    -- 清除缓存，因为数据已经改变
    self:ClearItemCache()
    
    local newData = commonlib.serialize(clientData);
    self.lastData = self.lastData or {};
    if(self.lastData[self.gsid] ~= newData) then
        self.lastData[self.gsid] = newData
        LOG.std(nil, "info", "VirtualBag", "SetServerBagData for gsid: " .. tostring(self.gsid) .. " data: " .. newData)
        KeepWorkItemManager.SetClientData(self.gsid, clientData, function()
            LOG.std(nil, "info", "VirtualBag", "SetServerBagData success for gsid: " .. tostring(self.gsid))
            if callback then callback(true) end
        end)
    end
end

-- 获取服务器时间
function VirtualBag:GetServerTime()
    if System.options.isDevMode then
        return os.time()
    end
    local time_stamp = GameLogic.GetFilters():apply_filters('service.session.get_current_server_time')
    return time_stamp or os.time()
end

-- 格式化时间
function VirtualBag:FormatTime(datetime)
    local time_stamp = type(datetime) == "string" and commonlib.timehelp.GetTimeStampByDateTime(datetime) or datetime
    local year = os.date("%Y", time_stamp)
    local month = os.date("%m", time_stamp)
    local day = os.date("%d", time_stamp)
    local hour = os.date("%H", time_stamp)
    local min = os.date("%M", time_stamp)
    local sec = os.date("%S", time_stamp)
    return string.format("%s-%s-%s %s:%s:%s", year, month, day, hour, min, sec)
end

-- 检查物品是否过期
function VirtualBag:IsItemExpired(item)
    if not item.expireAt then
        return false  -- 没有过期时间的物品永不过期
    end
    
    local current_time = self:GetServerTime()
    local expire_time = commonlib.timehelp.GetTimeStampByDateTime(item.expireAt)
    
    return current_time > expire_time
end

-- 更新背包数据，移除过期物品
function VirtualBag:UpdateBagByExpireTime(items)
    if not items then
        items = self:GetServerBagData()
    end
    
    local newItems = {}
    local hasExpired = false
    
    for i, item in ipairs(items) do
        if not self:IsItemExpired(item) then
            table.insert(newItems, item)
        else
            hasExpired = true
            LOG.std(nil, "info", "VirtualBag", "Item expired: " .. tostring(item.id))
        end
    end
    -- 重新整理slot
    for i, item in ipairs(newItems) do
        local isVipPlaceholder = item.data and item.data.isVipPlaceholder
        if not isVipPlaceholder then
            item.slot = i
        end
    end
    
    if hasExpired then
        self:SetServerBagData(newItems, function(success)
            if success then
                LOG.std(nil, "info", "VirtualBag", "UpdateBagByExpireTime success for gsid: " .. tostring(self.gsid))
            end
        end)
    end
    
    return newItems
end

-- 检查用户是否为VIP
function VirtualBag:IsVipUser()
    return KeepWorkItemManager.IsVip()
end

-- 获取背包最大容量
function VirtualBag:GetBagCapacity()
    -- 根据用户VIP状态返回不同容量
    if self:IsVipUser() then
        return self.freeCount + self.vipCount
    else
        return self.freeCount  -- 非VIP用户只能使用免费槽位
    end
end

-- 获取背包最大槽位
function VirtualBag:GetMaxSlot()
    return self.freeCount + self.vipCount
end


-- 检查槽位是否为VIP槽位
function VirtualBag:IsVipSlot(slot)
    if not slot or slot < 1 then
        return false
    end
    return slot > self.freeCount and slot <= (self.freeCount + self.vipCount)
end

-- 获取免费槽位范围
function VirtualBag:GetFreeSlotRange()
    return 1, self.freeCount
end

-- 获取VIP槽位范围
function VirtualBag:GetVipSlotRange()
    return self.freeCount + 1, self.freeCount + self.vipCount
end

-- 获取免费容量
function VirtualBag:GetFreeCapacity()
    return self.freeCount
end

-- 获取VIP容量
function VirtualBag:GetVipCapacity()
    return self.vipCount
end

-- 获取下一个可用slot
function VirtualBag:GetNextAvailableSlot(items, capacity)
    items = items or self:GetServerBagData()
    capacity = capacity or self:GetBagCapacity()
    
    local usedSlots = {}
    for _, item in ipairs(items) do
        if item.slot then
            usedSlots[item.slot] = true
        end
    end
    
    -- 根据VIP状态限制可用槽位范围
    local maxSlot = capacity
    if not self:IsVipUser() then
        maxSlot = self.freeCount  -- 非VIP用户只能使用免费槽位
    end
    
    for i = 1, maxSlot do
        if not usedSlots[i] then
            return i
        end
    end
    
    return nil  -- 没有可用slot
end

-- 检查槽位是否在用户权限范围内
function VirtualBag:IsSlotAccessible(slot)
    if not slot or slot < 1 then
        return false
    end
    
    if self:IsVipUser() then
        return slot <= (self.freeCount + self.vipCount)
    else
        return slot <= self.freeCount
    end
end

-- 添加物品到背包
function VirtualBag:AddItemToBag(itemData, strategy, callback)
    strategy = strategy or OVERFLOW_STRATEGY.REPLACE_LAST
    
    local items = self:GetServerBagData()
    items = self:UpdateBagByExpireTime(items)
    table.sort(items, function(a, b)
        return a.slot < b.slot
    end)
    local capacity = self:GetBagCapacity()
    -- 设置物品基本信息
    local newItem = {
        id = itemData.id,
        name = itemData.name or "",
        category = itemData.category or "",
        addedAt = self:FormatTime(self:GetServerTime()),
        expireAt = itemData.expireAt,  -- 可选的过期时间
        data = itemData.data or {}     -- 额外数据
    }
    
    -- 检查是否有可用slot
    local availableSlot = self:GetNextAvailableSlot(items, capacity)
    if availableSlot and self:IsSlotAccessible(availableSlot) then
        newItem.slot = availableSlot
        table.insert(items, newItem)
    else
        -- 对于免费用户，如果背包满了，自动添加到临时背包
        if not self:IsVipUser() and not availableSlot then
            LOG.std(nil, "info", "VirtualBag", "Free user bag full, adding to temp bag: " .. tostring(itemData.id))
            if callback then callback(true, "背包已满，物品收藏失败") end
            return
        end
        
        if strategy == OVERFLOW_STRATEGY.REPLACE_LAST then
            local lastAccessibleSlot = self:IsVipUser() and capacity or self.freeCount
            
            if not self:IsSlotAccessible(lastAccessibleSlot) then
                local message = self:IsVipUser() and "背包已满，物品收藏失败" or "需要VIP权限才能使用更多槽位"
                LOG.std(nil, "warn", "VirtualBag", "No accessible slot for item: " .. tostring(itemData.id))
                if callback then callback(false, message) end
                return
            end
            newItem.slot = lastAccessibleSlot
            for i, item in ipairs(items) do
                if item.slot == lastAccessibleSlot then
                    table.remove(items, i)
                    break
                end
            end
            table.insert(items, newItem)

        elseif strategy == OVERFLOW_STRATEGY.DISCARD then
            -- 丢弃新物品
            local message = availableSlot and "需要VIP权限才能使用更多槽位" or "背包已满，物品收藏失败"
            LOG.std(nil, "warn", "VirtualBag", "Item discarded: " .. tostring(itemData.id))
            if callback then callback(false, message) end
            return
        end
    end
    table.sort(items, function(a, b)
        return a.slot < b.slot
    end)
    -- 保存到服务器
    self:SetServerBagData(items, function(success)
        if success then
            LOG.std(nil, "info", "VirtualBag", "AddItemToBag success: " .. tostring(itemData.id))
            -- 检查并通知背包状态变化
            self:CheckAndNotifyBagStatus()
            if callback then callback(true, "物品添加成功") end
        else
            if callback then callback(false, "保存失败") end
        end
    end)
end

-- 移动物品到指定slot
function VirtualBag:MoveItemToSlot(itemId, targetSlot, callback)
    local items = self:GetServerBagData()
    local capacity = self:GetBagCapacity()
    
    -- 检查目标槽位是否有效
    if targetSlot < 1 or targetSlot > capacity then
        if callback then callback(false, "无效的slot位置") end
        return
    end
    
    -- 检查用户是否有权限访问目标槽位
    if not self:IsSlotAccessible(targetSlot) then
        local message = "需要VIP权限才能使用该槽位"
        if callback then callback(false, message) end
        return
    end
    
    -- 找到要移动的物品
    local sourceItem = nil
    local sourceIndex = nil
    for i, item in ipairs(items) do
        if item.id == itemId then
            sourceItem = item
            sourceIndex = i
            break
        end
    end
    
    if not sourceItem then
        if callback then callback(false, "物品不存在") end
        return
    end
    
    -- 检查目标slot是否被占用
    local targetItem = nil
    local targetIndex = nil
    for i, item in ipairs(items) do
        if item.slot == targetSlot then
            targetItem = item
            targetIndex = i
            break
        end
    end
    
    if targetItem then
        -- 交换位置
        local oldSlot = sourceItem.slot
        
        -- 检查目标物品是否能移动到源槽位（如果源槽位是VIP槽位）
        if not self:IsSlotAccessible(oldSlot) then
            -- 如果源槽位是VIP槽位且用户不是VIP，则不能交换
            local message = "无法交换：源槽位需要VIP权限"
            if callback then callback(false, message) end
            return
        end
        
        sourceItem.slot = targetSlot
        targetItem.slot = oldSlot
    else
        -- 直接移动
        sourceItem.slot = targetSlot
    end
    
    -- 保存到服务器
    self:SetServerBagData(items, function(success)
        if success then
            LOG.std(nil, "info", "VirtualBag", "MoveItemToSlot success: " .. tostring(itemId) .. " to slot " .. tostring(targetSlot))
            if callback then callback(true, "物品移动成功") end
        else
            if callback then callback(false, "保存失败") end
        end
    end)
end

-- 销毁物品
function VirtualBag:DestroyItem(itemId, callback)
    local items = self:GetServerBagData()
    
    -- 找到并移除物品
    local removed = false
    for i = #items, 1, -1 do
        if items[i].id == itemId then
            table.remove(items, i)
            removed = true
            break
        end
    end
    
    if not removed then
        if callback then callback(false, "物品不存在") end
        return
    end
    
    -- 重新整理slot
    table.sort(items, function(a, b) return a.slot < b.slot end)
    -- for i, item in ipairs(items) do
    --     item.slot = i
    -- end
    
    -- 保存到服务器
    self:SetServerBagData(items, function(success)
        if success then
            LOG.std(nil, "info", "VirtualBag", "DestroyItem success: " .. tostring(itemId))
            if callback then callback(true, "物品销毁成功") end
        else
            if callback then callback(false, "保存失败") end
        end
    end)
end

-- 获取物品详情
function VirtualBag:GetItemById(itemId)
    local items = self:GetServerBagData()
    
    for _, item in ipairs(items) do
        if item.id == itemId then
            return item
        end
    end
    
    return nil
end

-- 获取指定slot的物品
function VirtualBag:GetItemBySlot(slot)
    local items = self:GetServerBagData()
    
    for _, item in ipairs(items) do
        if item.slot == slot then
            return item
        end
    end
    
    return nil
end

-- 清理所有过期物品
function VirtualBag:CleanExpiredItems(callback)
    local items = self:GetServerBagData()
    local newItems = self:UpdateBagByExpireTime(items)
    
    if callback then
        callback(true, "过期物品清理完成")
    end
end

-- 获取所有物品
function VirtualBag:GetAllItems()
    return self:GetServerBagData()
end

-- 获取背包名称
function VirtualBag:GetBagName()
    return self.name
end

-- 获取背包GSID
function VirtualBag:GetGsid()
    return self.gsid
end

function VirtualBag:HasItem(itemId, useCache)
    if useCache == nil then useCache = true end
    
    -- 如果使用缓存且缓存存在，直接从缓存查找
    if useCache and self._itemCache then
        return self._itemCache[itemId] ~= nil
    end
    
    -- 获取物品列表并构建缓存
    local items = self:GetServerBagData()
    
    if useCache then
        -- 构建物品ID缓存哈希表
        self._itemCache = {}
        for _, item in ipairs(items) do
            if item.id then
                self._itemCache[item.id] = true
            end
        end
        
        return self._itemCache[itemId] ~= nil
    else
        -- 不使用缓存，直接遍历查找
        for _, item in ipairs(items) do
            if item.id == itemId then
                return true
            end
        end
        return false
    end
end

-- 清除物品缓存（在背包数据发生变化时调用）
function VirtualBag:ClearItemCache()
    self._itemCache = nil
end

function VirtualBag:HasItems(itemIds)
    if not itemIds or #itemIds == 0 then
        return {}
    end
    
    -- 确保缓存存在
    if not self._itemCache then
        self:HasItem(itemIds[1], true)  -- 触发缓存构建
    end
    
    local result = {}
    for _, itemId in ipairs(itemIds) do
        result[itemId] = self._itemCache[itemId] ~= nil
    end
    
    return result
end

function VirtualBag:ClearItems(itemIds)
    if not itemIds or #itemIds == 0 then
        return
    end
    local result = self:HasItems(itemIds) or {}
    local items = self:GetServerBagData()
    local newItems = {}
    for i = #items, 1, -1 do
        if not result[items[i].id] then
            table.insert(newItems, items[i])
        end
    end
    for i, item in ipairs(newItems) do
        item.slot = i
    end
    self:SetServerBagData(newItems, function(success)
        if success then
            LOG.std(nil, "info", "VirtualBag", "clear items success: ".. commonlib.serialize(result))
        else
            LOG.std(nil, "error", "VirtualBag", "clear items failed: ".. commonlib.serialize(result))
        end
    end)
end

-- 临时背包配置
local TEMP_BAG_CONFIG = {
    MAX_FREE_CAPACITY = 20,  -- 免费用户临时背包最大容量
    DEFAULT_EXPIRE_HOURS = 24,  -- 默认过期时间（小时）
    AUTO_TRANSFER_ON_VIP = true  -- VIP升级时自动转移到正式背包
}

-- 获取临时背包数据
function VirtualBag:GetTempBagData()
    local clientData = KeepWorkItemManager.GetClientData(self.gsid) or {}
    local tempItems = clientData.tempItems or {}
    local preTempNum = #tempItems
    tempItems = self:UpdateTempBagByExpireTime(tempItems)
    local cleanNum = preTempNum - #tempItems
    if cleanNum > 0 then
        LOG.std(nil, "info", "VirtualBag", "GetTempBagData cleanNum: " .. cleanNum)
    end
    -- 确保每个临时物品都有必要的字段
    for i, item in ipairs(tempItems) do
        if not item.slot then
            item.slot = i
        end
        if not item.addedAt then
            item.addedAt = self:FormatTime(self:GetServerTime())
        end
        -- 如果没有过期时间，设置默认过期时间
        if not item.expireAt and not item.data.isPermanent then
            local expireTime = self:GetServerTime() + (TEMP_BAG_CONFIG.DEFAULT_EXPIRE_HOURS * 3600)
            item.expireAt = self:FormatTime(expireTime)
        end
    end
    
    return tempItems
end

-- 设置临时背包数据
function VirtualBag:SetTempBagData(items, callback)
    local clientData = KeepWorkItemManager.GetClientData(self.gsid) or {}
    clientData.tempItems = items
    KeepWorkItemManager.SetClientData(self.gsid, clientData, function()
        LOG.std(nil, "info", "VirtualBag", "SetTempBagData success for gsid: " .. tostring(self.gsid))
        if callback then callback(true) end
    end)
end

-- 获取临时背包最大容量
function VirtualBag:GetTempBagCapacity()
    -- 免费用户临时背包容量固定
    return TEMP_BAG_CONFIG.MAX_FREE_CAPACITY
end

-- 添加物品到临时背包
function VirtualBag:AddItemToTempBag(itemData, callback)
    if itemData and itemData.category == "suit" then
        return
    end
    local tempItems = self:GetTempBagData()
    
    local capacity = self:GetTempBagCapacity()
    
    -- 设置临时物品基本信息
    local newTempItem = {
        id = itemData.id,
        name = itemData.name or "",
        category = itemData.category or "",
        addedAt = self:FormatTime(self:GetServerTime()),
        expireAt = itemData.expireAt,  -- 可选的过期时间
        data = itemData.data or {},
        isTemp = true  -- 标记为临时物品
    }
    
    -- 如果没有设置过期时间且不是永久物品，设置默认过期时间
    if not newTempItem.expireAt and not newTempItem.data.isPermanent then
        local expireTime = self:GetServerTime() + (TEMP_BAG_CONFIG.DEFAULT_EXPIRE_HOURS * 3600)
        newTempItem.expireAt = self:FormatTime(expireTime)
    end
    
    -- 检查容量限制
    if #tempItems >= capacity then
        -- 移除最早添加的物品
        table.sort(tempItems, function(a, b)
            local timeA = commonlib.timehelp.GetTimeStampByDateTime(a.addedAt)
            local timeB = commonlib.timehelp.GetTimeStampByDateTime(b.addedAt)
            return timeA < timeB
        end)
        
        table.remove(tempItems, 1)  -- 移除最早的物品
        LOG.std(nil, "info", "VirtualBag", "Temp bag full, removed oldest item for gsid: " .. tostring(self.gsid))
    end
    
    -- 设置slot
    newTempItem.slot = #tempItems + 1
    table.insert(tempItems, newTempItem)
    
    -- 保存临时背包数据
    self:SetTempBagData(tempItems, function(success)
        if success then
            LOG.std(nil, "info", "VirtualBag", "AddItemToTempBag success: " .. tostring(itemData.id))
            -- 通知临时背包状态变化
            self:CheckAndNotifyBagStatus()
            if callback then callback(true, "物品已添加到临时背包") end
        else
            if callback then callback(false, "保存失败") end
        end
    end)
end

-- 更新临时背包数据，移除过期物品
function VirtualBag:UpdateTempBagByExpireTime(tempItems)
    if not tempItems then
        tempItems = self:GetTempBagData()
    end
    
    local newTempItems = {}
    local hasExpired = false
    
    for i, item in ipairs(tempItems) do
        if not self:IsItemExpired(item) then
            table.insert(newTempItems, item)
        else
            hasExpired = true
            LOG.std(nil, "info", "VirtualBag", "Temp item expired: " .. tostring(item.id))
        end
    end
    
    -- 重新整理slot
    for i, item in ipairs(newTempItems) do
        item.slot = i
    end
    
    if hasExpired then
        self:SetTempBagData(newTempItems, function(success)
            if success then
                LOG.std(nil, "info", "VirtualBag", "UpdateTempBagByExpireTime success for gsid: " .. tostring(self.gsid))
            end
        end)
    end
    
    return newTempItems
end

-- 清理临时背包中的过期物品
function VirtualBag:CleanExpiredTempItems(callback)
    local tempItems = self:GetTempBagData()
    local newTempItems = self:UpdateTempBagByExpireTime(tempItems)
    
    if callback then
        callback(true, "临时背包过期物品清理完成")
    end
end

-- 从临时背包移除物品
function VirtualBag:RemoveItemFromTempBag(itemId, callback)
    local tempItems = self:GetTempBagData()
    
    -- 找到并移除物品
    local removed = false
    for i = #tempItems, 1, -1 do
        if tempItems[i].id == itemId then
            table.remove(tempItems, i)
            removed = true
            break
        end
    end
    
    if not removed then
        if callback then callback(false, "临时物品不存在") end
        return
    end
    
    -- 重新整理slot
    for i, item in ipairs(tempItems) do
        item.slot = i
    end
     
    -- 保存临时背包数据
    self:SetTempBagData(tempItems, function(success)
        if success then
            LOG.std(nil, "info", "VirtualBag", "RemoveItemFromTempBag success: " .. tostring(itemId))
            -- 检查并通知背包状态变化（临时背包物品减少）
            self:CheckAndNotifyBagStatus()
            if callback then callback(true, "临时物品移除成功") end
        else
            if callback then callback(false, "保存失败") end
        end
    end)
end

-- 将临时背包物品转移到正式背包
function VirtualBag:TransferTempItemsToBag(callback)
    local tempItems = self:GetTempBagData()
    
    if #tempItems == 0 then
        if callback then callback(true, "没有临时物品需要转移") end
        return
    end
    
    local transferCount = 0
    local failedItems = {}
    
    -- 逐个转移临时物品到正式背包
    local function transferNext(index)
        if index > #tempItems then
            -- 转移完成，清空临时背包
            self:SetTempBagData({}, function(success)
                if success then
                    local message = string.format("成功转移 %d 个物品到正式背包", transferCount)
                    if #failedItems > 0 then
                        message = message .. string.format("，%d 个物品转移失败", #failedItems)
                    end
                    LOG.std(nil, "info", "VirtualBag", "TransferTempItemsToBag completed: " .. message)
                    if callback then callback(true, message) end
                else
                    if callback then callback(false, "清空临时背包失败") end
                end
            end)
            return
        end
        
        local tempItem = tempItems[index]
        -- 移除临时标记
        tempItem.isTemp = nil
        
        -- 添加到正式背包
        self:AddItemToBag(tempItem, OVERFLOW_STRATEGY.REPLACE_LAST, function(success, message)
            if success then
                transferCount = transferCount + 1
            else
                table.insert(failedItems, tempItem)
                LOG.std(nil, "warn", "VirtualBag", "Failed to transfer temp item: " .. tostring(tempItem.id) .. ", reason: " .. tostring(message))
            end
            
            -- 继续转移下一个物品
            transferNext(index + 1)
        end)
    end
    
    -- 开始转移
    transferNext(1)
end

-- 检查VIP升级并提示转移临时物品
function VirtualBag:CheckVipUpgradeAndPromptTransfer(callback)
    if not self:IsVipUser() then
        if callback then callback(false, "用户不是VIP") end
        return
    end
    
    local tempItems = self:GetTempBagData()
    
    if #tempItems == 0 then
        if callback then callback(true, "没有临时物品需要处理") end
        return
    end
    
    if #tempItems == 0 then
        if callback then callback(true, "临时物品已过期，无需转移") end
        return
    end
    
    -- 如果配置了自动转移
    if TEMP_BAG_CONFIG.AUTO_TRANSFER_ON_VIP then
        self:TransferTempItemsToBag(callback)
    else
        -- 返回提示信息，让上层决定是否转移
        local message = string.format("检测到您已开通VIP，临时背包中有 %d 个物品可以转移到正式背包", #tempItems)
        if callback then callback(true, message, tempItems) end
    end
end

-- 获取所有临时物品
function VirtualBag:GetAllTempItems()
    return self:GetTempBagData()
end

-- 检查临时背包中是否存在指定物品
function VirtualBag:HasTempItem(itemId)
    local tempItems = self:GetTempBagData()
    
    for _, item in ipairs(tempItems) do
        if item.id == itemId then
            return true
        end
    end
    
    return false
end

-- 清空临时背包数据
function VirtualBag:ClearTempBagData()
    self:SetTempBagData({}, function(success)
        if success then
            LOG.std(nil, "info", "VirtualBag", "ClearTempBagData success")
        else
            LOG.std(nil, "warn", "VirtualBag", "ClearTempBagData failed")
        end
    end)
end

-- 注册背包变化监听器
-- @param gsid: 背包GSID
-- @param listener: 监听器函数，参数为(eventType, data)
--   eventType: "bag_full" - 背包已满且有临时物品
--   data: { gsid, tempItemCount, bagCapacity, message }
function VirtualBag.RegisterBagChangeListener(gsid, listener)
    if not bagChangeListeners[gsid] then
        bagChangeListeners[gsid] = {}
    end
    table.insert(bagChangeListeners[gsid], listener)
end

-- 移除背包变化监听器
function VirtualBag.RemoveBagChangeListener(gsid, listener)
    if not bagChangeListeners[gsid] then
        return
    end
    
    for i = #bagChangeListeners[gsid], 1, -1 do
        if bagChangeListeners[gsid][i] == listener then
            table.remove(bagChangeListeners[gsid], i)
            break
        end
    end
end

-- 清除指定背包的所有监听器
function VirtualBag.ClearBagChangeListeners(gsid)
    bagChangeListeners[gsid] = nil
end

-- 触发背包变化事件
function VirtualBag:TriggerBagChangeEvent(eventType, data)
    local listeners = bagChangeListeners[self.gsid]
    if not listeners or #listeners == 0 then
        return
    end
    
    for _, listener in ipairs(listeners) do
        if type(listener) == "function" then
            pcall(listener, eventType, data)
        end
    end
end

-- 检查并通知背包状态
function VirtualBag:CheckAndNotifyBagStatus()
    local tempItems = self:GetTempBagData()
    local tempItemCount = #tempItems
    
    -- 只有当临时背包有数据时才通知
    if tempItemCount > 0 then
        local capacity = self:GetBagCapacity()
        local items = self:GetServerBagData()
        local currentItemCount = #items
        
        -- 检查背包是否已满或接近满
        if currentItemCount >= capacity then
            local data = {
                gsid = self.gsid,
                tempItemCount = tempItemCount,
                bagCapacity = capacity,
                currentItemCount = currentItemCount,
                message = string.format("背包已满，临时背包中有 %d 个物品", tempItemCount)
            }
            
            self:TriggerBagChangeEvent("bag_full", data)
            LOG.std(nil, "info", "VirtualBag", "Bag full notification sent for gsid: " .. tostring(self.gsid))
        end
    end
end

return VirtualBag
