--[[
Title: MiniGame User Bag
    Author(s): ParaCraft Team
    Date: 2025/1/1
    Desc: 小游戏用户背包界面
    Use Lib:
    -------------------------------------------------------
    local MiniGameUserBag = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameUserBag.lua");
    MiniGameUserBag.ClosePage()
    MiniGameUserBag.ShowPage(category);
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMgr.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/VirtualBagManager.lua")
local CostumeInventory = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/CostumeInventory.lua")
local MiniGameSmileyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameSmileyPage.lua")
local InventoryManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/InventoryManager.lua")
local MiniGameMgr = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.MiniGameMgr")
local VirtualBagManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.VirtualBagManager")
local MiniGameUserBag = NPL.export()

-- 分类到虚拟背包的映射
local categoryToBagMap = {
    costumes = "skin",  -- 我的装扮 -> skin背包
    actions = "action",     -- 我的动作 -> action背包
    expressions = "smiley", -- 我的表情 -> 使用MiniGameSmileyPage逻辑
	throwItems = "throwItems", -- 我的投掷 -> throwItems背包
    userItems = "userItems", -- 我的道具 -> userItems背包
    food = "food", -- 我的食物 -> food背包
}

-- 物品类型映射
local itemTypeMap = {
    costumes = "skin",
    actions = "action",
    expressions = "smiley",
	throwItems = "throwItems",
    userItems = "userItems",
    food = "food",
}

local throwItems = {
    {
        icon ="Texture/Aries/Item/9501_WaterBalloon.png", --64x64
        asset ="model/07effect/v5/WaterBalloon/WaterBalloon.x",
        name="WaterBalloon",
        displayname ="水球",
        gsid=9501,
        descFile={hitstyle="model/07effect/v5/WaterBalloon/WaterBalloon1.x",showpic="Texture/Aries/Smiley/animated/face10_32bits_fps10_a005.png"},
        duration=1
    },
    {
        icon ="Texture/Aries/Item/9504_SnowBall.png", --64x64
        asset ="model/07effect/v5/SnowBalloon/SnowBalloon_ball_anim.x",
        name="SnowBall",
        displayname ="雪球",
        gsid=9504,
        descFile={hitstyle="model/07effect/v5/SnowBalloon/SnowBalloon1.x"},
        duration=0.8
    }
}

-- 占位符
local placeholder = {
    icon = "",
    name = "空",
    count = 0,
    id = 0,
    type = "empty"
}

local maxSlot = 38

local page
local currentCategory = "costumes" -- 当前选中的分类
local categories = {
    { key = "costumes", name = "我的装扮" ,icon="Texture/Aries/Creator/keepwork/minigame/bag/skin_64x64_32bits.png"},
    { key = "actions", name = "我的动作" ,icon="Texture/Aries/Creator/keepwork/minigame/bag/action_64x64_32bits.png"},
    { key = "expressions", name = "我的表情" ,icon="Texture/Aries/Creator/keepwork/minigame/bag/smiley_64x64_32bits.png"},
    { key = "userItems", name = "我的道具" ,icon="Texture/Aries/Creator/keepwork/minigame/bag/item_64x64_32bits.png"},
    { key = "food", name = "我的食物" ,icon="Texture/Aries/Creator/keepwork/minigame/bag/food_64x64_32bits.png"},
    -- { key = "throwItems", name = "我的物品" ,icon="Texture/Aries/Creator/keepwork/minigame/bag/throwItems_64x64_32bits.png"},
}

local userBg = "Texture/Aries/Creator/keepwork/minigame/bag/box_97x104_32bits.png#0 0 97 104"
local lockBg = "Texture/Aries/Creator/keepwork/minigame/bag/box1_97x104_32bits.png#0 0 97 104"
local isVipUser = false -- 用户是否为会员

function MiniGameUserBag.OnInit()
    page = document:GetPageCtrl()
end

-- 加载当前分类的收藏物品
function MiniGameUserBag.LoadCategoryItems(category)
    category = category or currentCategory
    local items = {}
    
    if category == "expressions" then
        return MiniGameUserBag.LoadSmileyItems()
    elseif category == "throwItems" then
		return throwItems
	elseif category == "costumes" then
        -- do not use gsid for costumes bag, instead using SkinUnLockManager
        local SkinUnLockManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/SkinUnLockManager.lua")
        local unlockedSkins = SkinUnLockManager.GetUnlockedSkinMap()
        NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
        local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
        
        for skinId, _ in pairs(unlockedSkins) do
            local itemData = CustomCharItems:GetItemById(skinId) or VirtualBagManager.GetSuitItemInfo(skinId)
            
            if itemData then
                local item = {
                    icon = itemData.icon,
                    name = itemData.name or tostring(skinId),
                    unlocked = true,
                    id = skinId,
                    type = "skin",
                    bg = userBg,
                    vip_required = false,
                }
                table.insert(items, item)
            end
        end
        return items
    elseif category == "food" then
        return InventoryManager.GetCombinedFoodAndCandyItems()
    elseif category == "userItems" then
        return MiniGameUserBag.GetUserItems()
    elseif category == "actions" then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
        local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile");
        local SkinUnLockManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/SkinUnLockManager.lua")
        local allAnimations = PlayerAssetFile:GetAllAnimations()
        if not allAnimations or #allAnimations == 0 then
            return {}
        end
        for k, v in pairs(allAnimations) do
            local isInBag = SkinUnLockManager.IsUnlocked(v.id)
            if isInBag then
                local item = {
                    icon = v.smallicon,
                    name = v.displayname or "动作"..tostring(v.id),
                    unlocked = true,
                    id = v.id,
                    type = "action",
                    bg = userBg,
                    vip_required = false,
                }
                table.insert(items, item)
            end
        end
        return items
	end

    
    local bagType = categoryToBagMap[category]
    if not bagType then
        return MiniGameUserBag.FillEmptySlots({})
    end
    
    -- 从虚拟背包获取物品数据，并按slot定位到UI位置
    local bagItems = VirtualBagManager.GetAllItems(bagType, false)
    local maxSlots = maxSlot
    for _, itemInfo in ipairs(bagItems) do
        local bagItem = itemInfo.item
        if bagItem then
            local item = MiniGameUserBag.ConvertBagItemToDisplayItem(bagItem, category)
            if item and item.slot and item.slot >= 1 and item.slot <= maxSlots then
                items[item.slot] = item
            end
        end
    end
    return MiniGameUserBag.FillEmptySlots(items)
end

function MiniGameUserBag.GetUserItems()
    return InventoryManager.userItems or {}
end

function MiniGameUserBag.GetCandyItems()
    return InventoryManager.candyItems or {}
end

function MiniGameUserBag.GetItemDeadline(index)
    local idx = tonumber(index)
    if not idx then
        return ""
    end
    local item = MiniGameUserBag.pageItems and MiniGameUserBag.pageItems[idx] or nil
    return InventoryManager.GetCandyItemDeadline(item)
end

function MiniGameUserBag.OnClickFoodItem(index)
    local idx = tonumber(index)
    if not idx then
        return
    end
    local item = MiniGameUserBag.pageItems and MiniGameUserBag.pageItems[idx] or nil
    if not item then
        return
    end
    MiniGameUserBag.ClosePage()
    if item.category == "candy" then
        InventoryManager.OnClickCandyItem(item)
        return
    end
    if item.category == "food" then
        InventoryManager.UseFoodItem(item,MiniGameUserBag.isFromFriend)
        return
    end
end

function MiniGameUserBag.RefreshPage()
    if page then
        page:Refresh(0.01)
    end
end

-- 获取服务器时间
function MiniGameUserBag.GetServerTime()
    if System.options.isDevMode then
        return os.time()
    end
    local time_stamp = GameLogic.GetFilters():apply_filters('service.session.get_current_server_time')
    return time_stamp or os.time()
end

function MiniGameUserBag.GetCandyStoreUtil()
    return InventoryManager.GetStoreUtil()
end

function MiniGameUserBag.LoadSmileyItems()
    local items = {}
    
    -- 获取MiniGameSmileyPage的表情数据
    if MiniGameSmileyPage.pageSymbols then
        for i, smiley in pairs(MiniGameSmileyPage.pageSymbols) do
            if smiley.gsid and smiley.gsid > 0 then
                local item = {
                    icon = smiley.icon,
                    name = smiley.symbol or ("表情" .. smiley.gsid),
                    unlocked = true,
                    id = smiley.gsid,
                    type = "expression",
                    vip_required = false,
                    symbol = smiley.symbol
                }
                table.insert(items, item)
            end
        end
    end
    
    return items
end

function MiniGameUserBag.OnClickSmileyIcon(index)
    MiniGameSmileyPage.OnClickIcon(index)
end

function MiniGameUserBag.OnClickThrowItem(index)
	local index = tonumber(index)
	if not index then
		return
	end
	MiniGameUserBag.ClosePage()
	local item = throwItems[index]
	if item then
		MiniGameUserBag.selectThrowIndex = index
	end
end

-- 将背包物品转换为显示物品
function MiniGameUserBag.ConvertBagItemToDisplayItem(bagItem, category)
    if not bagItem or not bagItem.id then
        return nil
    end
    
    local itemType = itemTypeMap[category] or "unknown"
    local capacity = VirtualBagManager.GetCapacity(itemType)
    local total, free, vip = capacity.total, capacity.free, capacity.vip
    
    -- 检查是否为VIP占位符
    if bagItem.data and bagItem.data.isVipPlaceholder then
        return {
            icon = bagItem.data.icon or "",
            name = bagItem.data.displayName or bagItem.name or "VIP套装",
            id = bagItem.id,
            type = itemType,
            slot = bagItem.slot,
            bg = lockBg, -- VIP占位符使用锁定背景
            vip_required = true,
            data = bagItem.data
        }
    end
    
    if category == "actions" then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
        local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile");
        local animationData = PlayerAssetFile:GetAnimationItem(bagItem.id)
        if animationData then
            return {
                icon = animationData.smallicon,
                name = animationData.displayname or ("动作" .. bagItem.id),
                id = bagItem.id,
                type = itemType,
                slot = bagItem.slot,
                bg = bagItem.slot <= total and userBg or lockBg,
            }
        end
    elseif category == "costumes" then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
        local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
        local itemData = CustomCharItems:GetItemById(bagItem.id)
		local suitItem = VirtualBagManager.GetSuitItemInfo(bagItem.id)
        if itemData then
            return {
                icon = itemData.icon,
                name = itemData.name or ("服装" .. bagItem.id),
                id = bagItem.id,
                type = itemType,
                slot = bagItem.slot,
                bg = bagItem.slot <= total and userBg or lockBg,
            }
		elseif bagItem.name:find("suit") and suitItem then
			return {
                icon = suitItem.icon,
                name = suitItem.displayname,
                id = bagItem.id,
                type = "skin",
                slot = bagItem.slot,
                bg = userBg,
            }
        end
    end
end

-- 填充空槽位
function MiniGameUserBag.FillEmptySlots(items)
    -- local maxSlots = maxSlot
    -- local itemType = itemTypeMap[currentCategory] or "unknown"
    -- local capacity = VirtualBagManager.GetCapacity(itemType)
    -- local total, free, vip = capacity.total, capacity.free, capacity.vip
    -- for i = 1, maxSlots do
    --     if not items[i] then
    --         local item = {
    --             icon = placeholder.icon,
    --             name = i <= total and placeholder.name or "Vip可用",
    --             count = 0,
    --             id = 0,
    --             type = "empty",
    --             slot = i,
    --             bg = i <= total and userBg or lockBg,
    --         }
    --         items[i] = item
    --     end
    -- end
    
    return items
end

local isRegisterMouse = false
-- 显示收藏页面
-- @param category: 分类名称
-- @param targetEntity: 目标实体，nil表示使用当前焦点实体
function MiniGameUserBag.ShowPage(category, targetEntity, isFromFriend)
    MiniGameUserBag.targetEntity = targetEntity
    MiniGameUserBag.isFromFriend = isFromFriend
    if category == "food" then
        InventoryManager.LoadFoodItems(function()
            InventoryManager.LoadCandyItems(function()
                MiniGameUserBag.ShowView(category)
            end)
        end)
        return
    elseif category == "userItems" then
        InventoryManager.LoadUserItems(function()
            MiniGameUserBag.ShowView(category)
        end)
        return
    end
    MiniGameUserBag.ShowView(category)
end

function MiniGameUserBag.ShowView(category)
    if MiniGameUserBag.IsVisible() then
        MiniGameUserBag.ClosePage()
    end
    currentCategory = category or "costumes"
    MiniGameUserBag.pageItems = MiniGameUserBag.LoadCategoryItems(currentCategory)
    -- 检查用户会员状态
    isVipUser = MiniGameMgr:IsVip()
    local view_width = 420
    local view_height = 600
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameUserBag.html",
        name = "MiniGameUserBag.Show",
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide = true,
        enable_esc_key = false,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        zorder = 0,
        directPosition = true,
        click_through = true,
        align = "_rt",
        x = -view_width,
        y = 64,
        width = view_width,
        height = view_height,
        --DesignResolutionWidth = 1280,
        --DesignResolutionHeight = 720,
    }
    
    System.App.Commands.Call("File.MCMLWindowFrame", params)
	if not isRegisterMouse then
		GameLogic.GetFilters():remove_filter("BaseContextMouseReleaseEvent", MiniGameUserBag.OnMouseReleaseEvent)
        GameLogic.GetFilters():add_filter("BaseContextMouseReleaseEvent", MiniGameUserBag.OnMouseReleaseEvent)
		isRegisterMouse = true
	end
end

-- 关闭页面
function MiniGameUserBag.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
    CostumeInventory.Close()
    MiniGameUserBag.targetEntity = nil
end

function MiniGameUserBag.IsVisible()
    return page and page:IsVisible()
end

-- 获取目标实体，如果没有指定则返回当前焦点实体
function MiniGameUserBag.GetTargetEntity()
    if MiniGameUserBag.targetEntity then
        return MiniGameUserBag.targetEntity
    end
    -- 如果没有指定目标实体，返回焦点实体
    return GameLogic.EntityManager.GetFocus()
end

-- 点击物品事件
function MiniGameUserBag.OnClickItem(index)
    local index = tonumber(index)
    if not index then
        return
    end
    
    local item = MiniGameUserBag.pageItems[index]
    if not item or item.id == 0 then
        return
    end
    
    -- 检查是否为VIP占位符或锁定的VIP物品
    if item.name == "Vip可用" or (item.data and item.data.isVipPlaceholder) then
        MiniGameUserBag.ShowVipRequiredDialog(item)
        return
    end
    
    -- 检查是否需要VIP权限的物品
    if item.vip_required and not MiniGameUserBag.IsVipUser() then
        MiniGameUserBag.ShowVipRequiredDialog(item)
        return
    end
    
    MiniGameUserBag.UseCollectionItem(item)
end

-- 切换分类
function MiniGameUserBag.SwitchCategory(name)
    local index = tonumber(name)
    if not index then
        return false
    end
    local category = categories[index]
    if category and category.key ~= currentCategory then
        CostumeInventory.Close()
        currentCategory = category.key
        if currentCategory == "food" then
            InventoryManager.LoadFoodItems(function()
                InventoryManager.LoadCandyItems(function()
                    MiniGameUserBag.pageItems = MiniGameUserBag.LoadCategoryItems(currentCategory)
                    MiniGameUserBag.RefreshPage()
                end)
            end)
            return
        elseif currentCategory == "userItems" then
            InventoryManager.LoadUserItems(function()
                MiniGameUserBag.pageItems = MiniGameUserBag.LoadCategoryItems(currentCategory)
                MiniGameUserBag.RefreshPage()
            end)
            return
        end
        MiniGameUserBag.pageItems = MiniGameUserBag.LoadCategoryItems(currentCategory)
        MiniGameUserBag.RefreshPage()
    end
end

function MiniGameUserBag.CheckCategorySelected(name)
    local index = tonumber(name)
    if not index then
        return false
    end
    local category = categories[index]
    if category and category.key == currentCategory then
        return true
    end
    return false
end

-- 获取当前分类名称
function MiniGameUserBag.GetCurrentCategoryName()
    for _, cat in pairs(categories) do
        if cat.key == currentCategory then
            return cat.name
        end
    end
end

-- 使用收藏物品
function MiniGameUserBag.UseCollectionItem(item)
    if not item then
        return
    end
    -- 根据物品类型执行不同操作
    if item.type == "skin" then
        MiniGameUserBag.EquipCostume(item)
    elseif item.type == "action" then
        MiniGameUserBag.PerformAction(item)
    else
        GameLogic.AddBBS(nil, string.format(L"查看了 %s", item.name))
    end
end

-- 装备服装
function MiniGameUserBag.EquipCostume(item)
    local targetEntity = MiniGameUserBag.GetTargetEntity()
    if CostumeInventory.IsVisible() then
        CostumeInventory.SetSkinItems(item)
        return
    end
    CostumeInventory.Show(item, targetEntity)
end

-- 执行动作
function MiniGameUserBag.PerformAction(item)
    local targetEntity = MiniGameUserBag.GetTargetEntity()
    local entityName = targetEntity and targetEntity:GetName() or "player"
    GameLogic.AddBBS(nil, string.format(L"执行了动作: %s", item.displayname or item.name))
    
    -- 通过虚拟背包管理器处理动作逻辑
    if item.id and tonumber(item.id) >= 100001 then
        -- 如果指定了目标实体，在目标实体上执行动作
        if targetEntity and targetEntity ~= GameLogic.EntityManager.GetFocus() then
            -- 对其他实体执行动作，使用实体名称
            GameLogic.RunCommand(string.format("/anim @%s %d", entityName, item.id))
        else
            -- 对当前玩家执行动作
            GameLogic.RunCommand("/anim " .. item.id)
        end
    end
end

-- 显示表情
function MiniGameUserBag.SendExpression(item)
    -- 表情使用MiniGameSmileyPage的逻辑
    if item.symbol and MiniGameSmileyPage.SendSmileySymbol then
        MiniGameSmileyPage.SendSmileySymbol(item.symbol)
    else
        GameLogic.AddBBS(nil, string.format(L"显示了表情: %s", item.name))
    end
end

-- 显示会员权限对话框
function MiniGameUserBag.ShowVipRequiredDialog(item)
    local text = string.format(L"使用 %s 需要开通会员，是否立即开通？", item.name)
    _guihelper.MessageBox(text, function(result)
        if result and result == _guihelper.DialogResult.Yes then
            MiniGameUserBag.OpenVipDialog()
        end
    end, _guihelper.MessageBoxButtons.YesNo)
end

-- 开通会员对话框
function MiniGameUserBag.OpenVipDialog()
    -- 这里可以打开会员开通界面
    GameLogic.AddBBS(nil, L"正在打开会员开通界面...")

    local MiniGameMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMainPage.lua");
    MiniGameMainPage.StartWebGame("game_activities",{type="vip"}, true)
end

-- 更新收藏数据
function MiniGameUserBag.UpdateCollectionData(item)
    if not item then
        return
    end
    
    -- 表情分类不需要更新到虚拟背包
    if currentCategory == "expressions" or currentCategory == "throwItems" then
        return
    end
    
    local bagType = categoryToBagMap[currentCategory]
    if bagType and item.slot then
        -- 通过虚拟背包管理器更新数据
        local bagItem = VirtualBagManager.GetItem(bagType, item.slot)
        if bagItem then
            bagItem.unlocked = item.unlocked
            bagItem.vip_required = item.vip_required
        end
    end
end

-- 获取分类列表
function MiniGameUserBag.GetCategories()
    return categories
end

-- 获取当前分类
function MiniGameUserBag.GetCurrentCategory()
    return currentCategory
end

-- 检查用户是否为会员
function MiniGameUserBag.IsVipUser()
    return isVipUser
end

-- 解锁物品（用于游戏逻辑）
function MiniGameUserBag.UnlockItem(itemId)
    for k, v in pairs(MiniGameUserBag.pageItems or {}) do
        if v.id == itemId then
            v.unlocked = true
            MiniGameUserBag.UpdateCollectionData(v)
            MiniGameUserBag.RefreshPage()
            return true
        end
    end
    return false
end

-- 添加物品到当前分类背包
function MiniGameUserBag.AddItemToCurrentCategory(itemData)
    if currentCategory == "expressions" then
        -- 表情分类不支持添加
        return {success = false, message = "表情分类不支持添加物品"}
    end
    
    local bagType = categoryToBagMap[currentCategory]
    if not bagType then
        return {success = false, message = "无效的分类"}
    end
    
    local result = VirtualBagManager.AddItem(bagType, itemData)
    if result.success then
        MiniGameUserBag.pageItems = MiniGameUserBag.LoadCategoryItems(currentCategory)
        MiniGameUserBag.RefreshPage()
    end
    return result
end

-- 移除物品从当前分类背包
function MiniGameUserBag.RemoveItemFromCurrentCategory(slot)
    if currentCategory == "expressions" then
        -- 表情分类不支持移除
        return {success = false, message = "表情分类不支持移除物品"}
    end
    
    local bagType = categoryToBagMap[currentCategory]
    if not bagType then
        return {success = false, message = "无效的分类"}
    end
    
    local result = VirtualBagManager.DestroyItem(bagType, slot)
    if result.success then
        MiniGameUserBag.pageItems = MiniGameUserBag.LoadCategoryItems(currentCategory)
        MiniGameUserBag.RefreshPage()
    end
    
    return result
end

-- 获取当前分类背包容量信息
function MiniGameUserBag.GetCurrentCategoryCapacity()
    if currentCategory == "expressions" then
        -- 表情分类返回固定容量
        local smileyCount = 0
        if MiniGameSmileyPage and MiniGameSmileyPage.pageSymbols then
            for _, smiley in pairs(MiniGameSmileyPage.pageSymbols) do
                if smiley.gsid and smiley.gsid > 0 then
                    smileyCount = smileyCount + 1
                end
            end
        end
        return {total = 12, used = smileyCount, free = 12 - smileyCount, vip = 0}
    end
    
    local bagType = categoryToBagMap[currentCategory]
    if not bagType then
        return {total = 0, used = 0, free = 0, vip = 0}
    end
    
    return VirtualBagManager.GetCapacity(bagType)
end

NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/ThrowBallManager.lua");
local ThrowBallManager = commonlib.gettable("MyCompany.Aries.Game.Entity.ThrowBallManager");
function MiniGameUserBag.OnMouseReleaseEvent()
    if MiniGameUserBag.selectThrowIndex then
        local index = MiniGameUserBag.selectThrowIndex
		MiniGameUserBag.selectThrowIndex = nil
		local throwItem = throwItems[index]
        local result = Game.SelectionManager:GetPickingResult();
        if result  then -- 点击非实体
            if result.entity then
                local targetName = result.entity:GetName()
                ThrowBallManager:ThrowFromPlayerToEntity(result.entity, {
                    duration = throwItem.duration,
					ballModel = throwItem.asset,
                    onHit = function(x, y, z) 
                        local codeGloabal = GameLogic.GetCodeGlobal()
                        if codeGloabal then
                            local msg = {x=x,y=y,z=z,target={name=targetName},projectileType=throwItem.displayname}
                            codeGloabal:BroadcastTextEvent("minigame_throw_hit", msg,function()
                                LOG.std(nil, "info", "minigame_throw_hit", commonlib.serialize(msg))
                            end);
                        end
                    end
                })
            elseif result.bx then
                local x,y,z = result.bx,result.by,result.bz
                ThrowBallManager:ThrowFromPlayer(x,y,z,{duration = throwItem.duration,ballModel = throwItem.asset,})
            end
        end
    end
end


function MiniGameUserBag.OnClickUserItem(index)
    if index and index > 0 and index <= #MiniGameUserBag.pageItems then
        local item = MiniGameUserBag.pageItems[index]
        if item then
            MiniGameUserBag.ClosePage()
            local result
            if item.id == 279 then
                result = MiniGameUserBag.OnUseMudItems()
            elseif item.name == "builder" then
                result = MiniGameUserBag.OnUseBuilderItems()
            elseif item.name == "cooking" then
                result = MiniGameUserBag.OnUseCookingItems()
            else
                GameLogic.GetCodeGlobal():BroadcastTextEvent("use_user_item",item)
                result = true
            end
        end
    end
end

function MiniGameUserBag.OnUseCookingItems()
    local EasyModelStove = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyModelStove.lua");
    EasyModelStove.EnsureBase()
    return true
end

function MiniGameUserBag.OnUseBuilderItems()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditableWorld.lua");
    local EasyEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld");
    if not EasyEditableWorld.HasLoadedAnyWorld() then
        GameLogic.AddBBS(nil,L"您需要先创建或加载一个存档才能使用此物品")
        return
    end

    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyModel.lua");
    local EasyModel = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyModel");
    local MiniGameMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMainPage.lua");
    if not MiniGameMainPage.IsStoryMode() then
        MiniGameMainPage.ChangeUIMode("Story")
        EasyModel.SelectMeInHand(0)
        return true
    end
    EasyModel.SelectMeInHand(0)
    return true
end

function MiniGameUserBag.OnUseMudItems()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditableWorld.lua");
    local EasyEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld");
    if not EasyEditableWorld.HasLoadedAnyWorld() then
        GameLogic.AddBBS(nil,L"您需要先创建或加载一个存档才能使用此物品")
        return
    end
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyModel.lua");
    local EasyModel = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyModel");
    local MiniGameMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMainPage.lua");
    if not MiniGameMainPage.IsStoryMode() then
        MiniGameMainPage.ChangeUIMode("Story")
        EasyModel.TakeItem(279)
        return true
    end
    EasyModel.TakeItem(279)
    return true
end