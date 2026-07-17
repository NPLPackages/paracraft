--[[  
Title: VirtualBagManager
Author: System
Date: 2025
Desc: 虚拟背包UI封装层，提供简化的接口供外部UI调用
UseLib:
    -------------------------------------------------------
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/VirtualBagManager.lua");
    local VirtualBagManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.VirtualBagManager")
--]]
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
local VirtualBag = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameVirtualBag.lua");

-- 虚拟背包UI管理器
local VirtualBagManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.VirtualBagManager"))

-- 背包实例缓存
local bagInstances = {};

local userFreeItems = {
	{
		icon="Texture/Aries/Creator/keepwork/minigame/suit/suit01.png", --128x128
		displayname="小屁孩套装",
		name="suit01",
		vip=0,
		id = 1000,
		skin="80001;81010;82001;83215;84076;85097;87005;88019;" 
	},
	{
		icon="Texture/Aries/Creator/keepwork/minigame/suit/suit02.png", --128x128
		displayname="捣蛋鬼套装",
		name="suit02",
		vip=0,
		id = 1001,
		skin="80001;81033;82001;83219;84077;85100;87005;88002;"
	},
	{
		icon="Texture/Aries/Creator/keepwork/minigame/suit/suit03.png", --128x128
		displayname="大象睡衣套装",
		name="suit03",
		vip=1,
		id = 1002,
		skin="80001;81036;82001;83182;84120;85133;86016;87159;88021;" 
	},
	{
		icon="Texture/Aries/Creator/keepwork/minigame/suit/suit04.png", --128x128
		displayname="狮子原始人",
		name="suit04",
		vip=1,
		id = 1003,
		skin="80001;81005;82001;83184;84114;85128;86013;87176;88023;" 
	},
	{
		icon="Texture/Aries/Creator/keepwork/minigame/suit/suit05.png", --128x128
		displayname="可爱女套装",
		name="suit05",
		vip=1,
		id = 1004,
		skin="80001;81049;82001;83081;84107;85084;86039;87064;88016;" 
	},
	{
		icon="Texture/Aries/Creator/keepwork/minigame/suit/suit06.png", --128x128
		displayname="混搭小恶魔",
		name="suit06",
		vip=1,
		id = 1005,
		skin="80001;81005;82001;83160;84003;85007;86003;87129;88023;" 
	},
	{
		icon="Texture/Aries/Creator/keepwork/minigame/suit/suit07.png", --128x128
		displayname="合金白银套装",
		name="suit07",
		vip=1,
		id = 1006,
		skin="80001;81018;82001;83164;84056;85075;87188;88002;" 
	},
}

local freeCount = 3000
local vipCount = 0
-- 初始化背包UI管理器
function VirtualBagManager.Init()
    bagInstances = {};
    VirtualBagManager.GetBag("skin", freeCount, 0)  -- 装扮背包
    VirtualBagManager.GetBag("action", 999, 0)     -- 动作背包
    VirtualBagManager.ClearTempItems()
    VirtualBagManager.ClearSuitItems()
end

-- 检查用户是否为VIP
-- @return: boolean VIP状态
function VirtualBagManager.IsUserVip()
    local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
    return KeepWorkItemManager.IsVip()
end

function VirtualBagManager.GetSuitItemById(id)
    for _, item in ipairs(userFreeItems) do
        if item.id == id then
            return item
        end
    end
end

-- 获取适合当前用户的免费套装列表
-- @return: table 免费套装列表
function VirtualBagManager.GetUserFreeItems()
    local isVip = VirtualBagManager.IsUserVip();
    local freeItems = {};
    
    for _, item in ipairs(userFreeItems) do
        item.category = "suit"
        -- item.type = "skin"
        if isVip then
            -- VIP用户可以获得所有套装（包括VIP专属）
            table.insert(freeItems, item);
        else
            -- 非VIP用户只能获得免费套装（vip=0）
            if item.vip == 0 then
                table.insert(freeItems, item);
            end
        end
    end
    
    return freeItems;
end

-- 获取所有套装列表（包括VIP套装，用于展示）
-- @return: table 所有套装列表
function VirtualBagManager.GetAllSuitItems()
    return userFreeItems;
end

-- 获取VIP套装列表（非VIP用户在VIP槽位中展示用）
-- @return: table VIP套装列表
function VirtualBagManager.GetVipSuitItems()
    local vipItems = {};
    
    for _, item in ipairs(userFreeItems) do
        if item.vip == 1 then
            table.insert(vipItems, item);
        end
    end
    
    return vipItems;
end

-- 获取当前时间（格式化）
function VirtualBagManager.GetCurrentTime()
    return os.date("%Y-%m-%d %H:%M:%S")
end
-- @param bagType: 背包类型 ("action", "skin", "pet")
-- @param freeCount: 免费槽位数量
-- @param vipCount: VIP槽位数量
-- @return: 背包实例
function VirtualBagManager.GetBag(bagType, freeCount, vipCount)
    if not bagInstances[bagType] then
        local gsidMap = {
            action = 40007,
            skin = 40008,
            pet = 40009
        };
        
        local gsid = gsidMap[bagType];
        if not gsid then
            LOG.std(nil, "error", "VirtualBagManager", "Unknown bag type: %s", bagType or "nil");
            return nil;
        end
        
        bagInstances[bagType] = VirtualBag:Init(gsid, freeCount or 6, vipCount or 32);
    end
    
    return bagInstances[bagType];
end

-- 添加物品到背包
-- @param bagType: 背包类型
-- @param itemData: 物品数据 {id, count, expireTime, ...}
-- @param overflowStrategy: 溢出策略 ("overwrite" 或 "discard")
-- @return: 添加结果 {success, slot, message}
function VirtualBagManager.AddItem(bagType, itemData, overflowStrategy,callback)
    local bag = VirtualBagManager.GetBag(bagType);
    if not bag then
        if callback and type(callback) == "function" then
            callback(false, "背包类型无效");
        end
        return;
    end
    
    bag:AddItemToBag(itemData, overflowStrategy,function(result,message)
        if callback and type(callback) == "function" then
            callback(result, message);
        end
    end);
end

-- 移动物品到指定槽位
-- @param bagType: 背包类型
-- @param fromSlot: 源槽位
-- @param toSlot: 目标槽位
-- @return: 移动结果 {success, message}
function VirtualBagManager.MoveItem(bagType, fromSlot, toSlot)
    local bag = VirtualBagManager.GetBag(bagType);
    if not bag then
        return {success = false, message = "背包类型无效"};
    end
    
    local result = bag:MoveItemToSlot(fromSlot, toSlot);
    return {
        success = result.success,
        message = result.message or (result.success and "移动成功" or "移动失败")
    };
end

-- 销毁物品
-- @param bagType: 背包类型
-- @param slot: 槽位
-- @return: 销毁结果 {success, message}
function VirtualBagManager.DestroyItem(bagType, slot)
    local bag = VirtualBagManager.GetBag(bagType);
    if not bag then
        return {success = false, message = "背包类型无效"};
    end
    
    local result = bag:DestroyItem(slot);
    return {
        success = result.success,
        message = result.message or (result.success and "销毁成功" or "销毁失败")
    };
end

-- 获取物品信息
-- @param bagType: 背包类型
-- @param slot: 槽位
-- @return: 物品数据或nil
function VirtualBagManager.GetItem(bagType, slot)
    local bag = VirtualBagManager.GetBag(bagType);
    if not bag then
        return nil;
    end
    
    return bag:GetItemBySlot(slot);
end

-- 根据物品ID查找物品
-- @param bagType: 背包类型
-- @param itemId: 物品ID
-- @return: 物品数据数组
function VirtualBagManager.FindItemsById(bagType, itemId)
    local bag = VirtualBagManager.GetBag(bagType);
    if not bag then
        return {};
    end
    
    return bag:GetItemById(itemId);
end

function VirtualBagManager.HasItem(bagType, itemId, useCache)
    local bag = VirtualBagManager.GetBag(bagType);
    if not bag then
        return false;
    end
    local isInBag = bag:HasItem(itemId, useCache);
    if isInBag then
        return true;
    end
    return false;
end

function VirtualBagManager.HasItems(bagType, itemIds)
    local bag = VirtualBagManager.GetBag(bagType);
    if not bag then
        local result = {};
        for _, itemId in ipairs(itemIds or {}) do
            result[itemId] = false;
        end
        return result;
    end
    
    return bag:HasItems(itemIds);
end

-- 获取背包容量信息
-- @param bagType: 背包类型
-- @return: 容量信息 {total, free, vip, used, userMax}
function VirtualBagManager.GetCapacity(bagType)
    local bag = VirtualBagManager.GetBag(bagType);
    if not bag then
        return {total = 0, free = 0, vip = 0};
    end
    local total = bag:GetBagCapacity()
    local free = bag:GetFreeCapacity()
    local vip = bag:GetVipCapacity()
    local vipSlotStart,vipSlotEnd = bag:GetVipSlotRange()
    return {
        total = total,
        free = free,
        vip = vip,
        vipSlotStart = vipSlotStart,
        vipSlotEnd = vipSlotEnd,
    };
end

function VirtualBagManager.CleanExpiredItems(bagType)
    local bag = VirtualBagManager.GetBag(bagType);
    if not bag then
        return {cleanedCount = 0, cleanedItems = {}};
    end
    
    return bag:CleanExpiredItems();
end

function VirtualBagManager.GetAllItems(bagType, includeEmpty)
    local bag = VirtualBagManager.GetBag(bagType);
    if not bag then
        return {};
    end
    local allItems = bag:GetAllItems();
    local items = {};
    local capacity = bag:GetMaxSlot();
    
    for slot = 1, capacity do
        local item = bag:GetItemBySlot(slot);
        if item or includeEmpty then
            table.insert(items, {
                slot = slot,
                item = item
            });
        end
    end
    
    return items;
end

function VirtualBagManager.IsItemExpired(bagType, slot)
    local bag = VirtualBagManager.GetBag(bagType);
    if not bag then
        return false;
    end
    
    local item = bag:GetItemBySlot(slot);
    if not item then
        return false;
    end
    
    return bag:IsItemExpired(item);
end

function VirtualBagManager.GetNextAvailableSlot(bagType)
    local bag = VirtualBagManager.GetBag(bagType);
    if not bag then
        return nil;
    end
    
    return bag:GetNextAvailableSlot();
end

function VirtualBagManager.AddItems(bagType, itemList, overflowStrategy)
    local results = {};
    local successCount = 0;
    
    for i, itemData in ipairs(itemList or {}) do
        local result = VirtualBagManager.AddItem(bagType, itemData, overflowStrategy);
        table.insert(results, result);
        if result.success then
            successCount = successCount + 1;
        end
    end
    
    return {
        results = results,
        successCount = successCount,
        totalCount = #itemList
    };
end

function VirtualBagManager.CompactBag(bagType)
    local bag = VirtualBagManager.GetBag(bagType);
    if not bag then
        return {success = false, message = "背包类型无效"};
    end
    
    local items = VirtualBagManager.GetAllItems(bagType, false);
    local moveCount = 0;
    
    -- 清空背包数据
    local clientData = bag:GetServerBagData();
    clientData.items = {};
    
    -- 重新紧凑排列
    for i, itemInfo in ipairs(items) do
        clientData.items[i] = itemInfo.item;
        if itemInfo.slot ~= i then
            moveCount = moveCount + 1;
        end
    end
    
    -- 保存数据
    bag:SetServerBagData(clientData);
    
    return {
        success = true,
        message = string.format("整理完成，移动了%d个物品", moveCount),
        moveCount = moveCount
    };
end

function VirtualBagManager.SearchItems(bagType, searchText)
    local bag = VirtualBagManager.GetBag(bagType);
    if not bag or not searchText or searchText == "" then
        return {};
    end
    
    local results = {};
    local items = VirtualBagManager.GetAllItems(bagType, false);
    
    for _, itemInfo in ipairs(items) do
        local item = itemInfo.item;
        if item then
            -- 按ID搜索
            if tostring(item.id) == tostring(searchText) then
                table.insert(results, itemInfo);
            -- 按名称搜索（如果有名称字段）
            elseif item.name and string.find(string.lower(item.name), string.lower(searchText)) then
                table.insert(results, itemInfo);
            end
        end
    end
    
    return results;
end

-- 获取背包类型列表
-- @return: 支持的背包类型列表
function VirtualBagManager.GetSupportedBagTypes()
    return {"action", "skin", "pet"};
end

function VirtualBagManager.RefreshUserFreeItems(bagType, forceRefresh)
    bagType = bagType or "skin";
    return VirtualBagManager.InitUserFreeItems(bagType, forceRefresh or false);
end

function VirtualBagManager.ResetBag(bagType)
    local bag = VirtualBagManager.GetBag(bagType);
    if not bag then
        return {success = false, message = "背包类型无效"};
    end
    
    local clientData = {
        items = {},
        lastUpdate = bag:GetServerTime()
    };
    
    bag:SetServerBagData(clientData);
    
    return {
        success = true,
        message = "背包已重置"
    };
end

-- 导出背包数据（用于备份或调试）
-- @param bagType: 背包类型
-- @return: 背包数据
function VirtualBagManager.ExportBagData(bagType)
    local bag = VirtualBagManager.GetBag(bagType);
    if not bag then
        return nil;
    end
    
    return {
        bagType = bagType,
        capacity = VirtualBagManager.GetCapacity(bagType),
        items = VirtualBagManager.GetAllItems(bagType, true),
        exportTime = bag:GetServerTime()
    };
end

-- 注册背包变化监听器
-- @param bagType: 背包类型
-- @param listener: 监听器函数，参数为(eventType, data)
--   eventType: "bag_full" - 背包已满且有临时物品
--   data: { gsid, tempItemCount, bagCapacity, currentItemCount, message }
-- @return: 注册结果 {success, message}
function VirtualBagManager.RegisterBagChangeListener(bagType, listener)
    if type(listener) ~= "function" then
        return {success = false, message = "监听器必须是函数类型"};
    end
    
    local bag = VirtualBagManager.GetBag(bagType);
    if not bag then
        return {success = false, message = "背包类型无效"};
    end
    
    local gsid = bag:GetGsid();
    VirtualBag.RegisterBagChangeListener(gsid, listener);
    
    return {success = true, message = "监听器注册成功"};
end

-- 移除背包变化监听器
-- @param bagType: 背包类型
-- @param listener: 要移除的监听器函数
-- @return: 移除结果 {success, message}
function VirtualBagManager.RemoveBagChangeListener(bagType, listener)
    local bag = VirtualBagManager.GetBag(bagType);
    if not bag then
        return {success = false, message = "背包类型无效"};
    end
    
    local gsid = bag:GetGsid();
    VirtualBag.RemoveBagChangeListener(gsid, listener);
    
    return {success = true, message = "监听器移除成功"};
end

-- 清除指定背包的所有监听器
-- @param bagType: 背包类型
-- @return: 清除结果 {success, message}
function VirtualBagManager.ClearBagChangeListeners(bagType)
    local bag = VirtualBagManager.GetBag(bagType);
    if not bag then
        return {success = false, message = "背包类型无效"};
    end
    
    local gsid = bag:GetGsid();
    VirtualBag.ClearBagChangeListeners(gsid);
    
    return {success = true, message = "所有监听器已清除"};
end

-- 导入背包数据（用于恢复备份）
-- @param bagType: 背包类型
-- @param data: 导入的数据
-- @return: 导入结果
function VirtualBagManager.ImportBagData(bagType, data)
    if not data or not data.items then
        return {success = false, message = "无效的导入数据"};
    end
    
    local bag = VirtualBagManager.GetBag(bagType);
    if not bag then
        return {success = false, message = "背包类型无效"};
    end
    
    local clientData = {
        items = {},
        lastUpdate = bag:GetServerTime()
    };
    
    -- 导入物品数据
    for _, itemInfo in ipairs(data.items) do
        if itemInfo.item then
            clientData.items[itemInfo.slot] = itemInfo.item;
        end
    end
    
    bag:SetServerBagData(clientData);
    
    return {
        success = true,
        message = string.format("成功导入%d个物品", #data.items)
    };
end

-- 获取背包变更通知回调
-- @param bagType: 背包类型
-- @param callback: 回调函数
function VirtualBagManager.SetChangeCallback(bagType, callback)
    local bag = VirtualBagManager.GetBag(bagType);
    if bag and callback then
        -- 这里可以扩展为支持变更通知的机制
        bag._changeCallback = callback;
    end
end

-- 触发背包变更通知
local function TriggerChangeCallback(bag, changeType, data)
    if bag and bag._changeCallback then
        bag._changeCallback(changeType, data);
    end
end

function VirtualBagManager.GetSuitItemInfo(itemId)
    local suitItem = CustomCharItems:GetSuitItemById(itemId)
    return suitItem
end

function VirtualBagManager.GetTempBagData()
    local bagTypes = {"action", "skin"};
    local tempBagData = {}
    for _, bagType in ipairs(bagTypes) do
        local bag = VirtualBagManager.GetBag(bagType)
        if bag then
            local temps = bag:GetTempBagData()
            for slot, item in pairs(temps) do
                item.bagType = bagType
                tempBagData[#tempBagData + 1] = item
            end
        end
    end
    return tempBagData
end

function VirtualBagManager.ClearTempItems()
    local bagTypes = {"action", "skin"};
    for _, bagType in ipairs(bagTypes) do
        local bag = VirtualBagManager.GetBag(bagType)
        if bag then
            bag:ClearTempBagData()
        end
    end
end

function VirtualBagManager.ClearSuitItems()
    local suitItemIds = {1000,1001,1002,1003,1004,1005,1006}
    local bag = VirtualBagManager.GetBag("skin")
    if bag then
        bag:ClearItems(suitItemIds)
    end
end

-- 初始化单例
VirtualBagManager:InitSingleton().Init()
