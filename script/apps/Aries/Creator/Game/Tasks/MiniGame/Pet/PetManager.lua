--[[
Title: PetManager
Author: 
Date: 2024-01-01
Desc: 新宠物系统 - 宠物管理器
管理场景中的所有宠物，包括主宠和副宠的创建、更新、同步等功能
]]

NPL.load("(gl)script/ide/System/Core/ToolBase.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/Pet/Pet.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMgr.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
local Pet = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.Pet.Pet")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager")
local MiniGameMgr = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.MiniGameMgr")

local PetManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.Pet.PetManager"))

-- 单例实例
PetManager.instance = nil

-- 宠物配置
PetManager.Config = {
    MAX_MAIN_PETS = 1,      -- 最大主宠数量
    MAX_FOLLOW_PETS = 3,    -- 最大副宠数量
    UPDATE_INTERVAL = 100,  -- 更新间隔 (毫秒)
}

PetManager.petConfigs = {
    purple = {
        [1] = {petId = 90001, mountId = -1},
        [2] = {petId = 90002, mountId = -1},
        [3] = {petId = 90003, mountId = 89003},
        [4] = {petId = 90004, mountId = 89004}
    },
    green = {
        [1] = {petId = 90005, mountId = -1},
        [2] = {petId = 90006, mountId = -1},
        [3] = {petId = 90007, mountId = 89007},
        [4] = {petId = 90008, mountId = 89008}
    },
    orange = {
        [1] = {petId = 90009, mountId = -1},
        [2] = {petId = 90010, mountId = -1},
        [3] = {petId = 90011, mountId = 89011},
        [4] = {petId = 90012, mountId = 89012}
    },
    black = { 
        [3] = {petId = 90013, mountId = 89013},
        [4] = {petId = 90014, mountId = 89014}
    },
    red = {
        [3] = {petId = 90015, mountId = 89015},
        [4] = {petId = 90016, mountId = 89016}
    }
}

local localPetId = 10001

-- 构造函数
function PetManager:ctor()
    -- 宠物存储 - 按用户分组
    self.pets = {}              -- 所有宠物 {compositeId -> Pet}
    self.userPets = {}          -- 按用户分组的宠物 {username -> {main: [], follow: []}}
    self.activePets = {}        -- 激活的宠物
    
    -- 兼容旧版本的主副宠列表
    self.mainPets = {}          -- 主宠列表 (向后兼容)
    self.followPets = {}        -- 副宠列表 (向后兼容)
    
    -- 当前登录用户
    self.currentUser = nil      -- 当前登录用户名
    self.playerEntity = nil     -- 玩家实体
    
    -- 注册的用户列表
    self.registeredUsers = {}   -- 已注册的用户 {username -> {entity, petIds}}
    
    -- 更新控制
    self.updateTimer = nil      -- 更新计时器
    self.lastUpdateTime = 0     -- 上次更新时间
    self.lastSyncTime = 0       -- 上次同步时间
    self.lastSaveTime = 0       -- 上次保存时间
    
    -- 状态管理
    self.isInitialized = false  -- 是否已初始化
    self.isActive = false       -- 是否激活
    
    -- 数据缓存
    self.petData = {}           -- 宠物数据缓存
end

-- 获取单例实例
function PetManager.GetInstance()
    if not PetManager.instance then
        PetManager.instance = PetManager:new()
    end
    return PetManager.instance
end

-- 初始化管理器
function PetManager:Init(currentUser)
    if self.isInitialized then
        LOG.std(nil, "warn", "PetManager", "PetManager already initialized")
        return true
    end
    self.currentUser = currentUser
    if not self.currentUser then
        self.currentUser = Mod.WorldShare.Store:Get('user/username') or ""
    end
    self.playerEntity = self:GetUserEntity(self.currentUser)
    
    if not self.playerEntity then
        LOG.std(nil, "error", "PetManager", "Failed to get player entity")
        return false
    end
    
    -- 启动更新循环
    self:StartUpdateLoop()
    
    self.isInitialized = true
    self.isActive = true
    
    LOG.std(nil, "info", "PetManager", "PetManager initialized for current user: " .. tostring(currentUser))
    return true
end

-- 销毁管理器
function PetManager:Destroy()
    -- 停止更新循环
    self:StopUpdateLoop()
    
    -- 销毁所有宠物
    for petId, pet in pairs(self.pets) do
        pet:DestroyEntity()
    end
    
    -- 清空数据
    self.pets = {}
    self.userPets = {}
    self.mainPets = {}
    self.followPets = {}
    self.activePets = {}
    self.registeredUsers = {}
    
    self.isInitialized = false
    self.isActive = false
    
    LOG.std(nil, "info", "PetManager", "PetManager destroyed")
end

-- 启动更新循环
function PetManager:StartUpdateLoop()
    if self.updateTimer then
        self.updateTimer:Change()
    end
    
    self.updateTimer = commonlib.Timer:new({
        callbackFunc = function(timer)
            self:Update()
        end
    })
    
    self.updateTimer:Change(0, PetManager.Config.UPDATE_INTERVAL)
    LOG.std(nil, "info", "PetManager", "Update loop started")
end

-- 停止更新循环
function PetManager:StopUpdateLoop()
    if self.updateTimer then
        self.updateTimer:Change()
        self.updateTimer = nil
        LOG.std(nil, "info", "PetManager", "Update loop stopped")
    end
end

-- 主更新循环
function PetManager:Update()
    if not self.isActive then return end
    
    local currentTime = ParaGlobal.timeGetTime()
    local deltaTime = currentTime - self.lastUpdateTime
    self.lastUpdateTime = currentTime
    
    -- 调试：输出activePets总数
    local activePetCount = 0
    for _ in pairs(self.activePets) do
        activePetCount = activePetCount + 1
    end
    
    -- 更新所有激活的宠物
    for petId, pet in pairs(self.activePets) do        
        if pet and pet.isActive then
            pet:Update(deltaTime)
        else
            if not pet or not pet.isActive then
                -- print(string.format("[PetManager] 宠物未激活，跳过更新: %s", petId))
            end
        end
    end
end

-- 注册用户宠物
function PetManager:AddPetsByUser(username, petDatas)
    if not username or not petDatas then
        return false, "用户名和宠物列表不能为空"
    end
    local userEntity = self:GetUserEntity(username)
    if not userEntity then
        LOG.std(nil, "warn", "PetManager", string.format("Failed to get user entity for username: %s", username))
        return false, "用户实体不存在"
    end
    -- 注册用户信息
    self.registeredUsers[username] = {
        entity = userEntity,
        petDatas = petDatas
    }
    self.userPets = self.userPets or {}
    -- 初始化用户宠物分组
    if not self.userPets[username] then
        self.userPets[username] = {
            main = {},
            follow = {}
        }
    end
    -- 为用户创建宠物
    for _, petInfo in ipairs(petDatas) do
        local success, pet = self:CreatePetForUser(username, petInfo)
        local isNeedShow =  (petInfo.isVisible == true or petInfo.isVisible == nil)
        if petInfo and petInfo.type == "main" and success then
            pet:SetActive(isNeedShow)
        end
        if not success then
            LOG.std(nil, "warn", "PetManager", string.format("Failed to create pet %s for user %s: %s", petInfo.id, username, pet or "unknown error"))
        end
    end
    
    LOG.std(nil, "info", "PetManager", string.format("Registered %d pets for user: %s", #petDatas, username))
    return true, "用户宠物注册成功"
end

function PetManager:GetUserEntity(username)
    local userEntity = GameLogic.EntityManager.GetPlayer(username)
    if not userEntity then
        userEntity = GameLogic.GetPlayer()
    end
    NPL.load("Mod/GeneralGameServerMod/App/Client/AppGeneralGameClient.lua");
    local AppGeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient");
    if AppGeneralGameClient:IsLogin() then
        local world = AppGeneralGameClient:GetWorld()
        if not world then
             return userEntity
        end
        local playerManager = world:GetPlayerManager()
        if not playerManager then
            return userEntity
        end
        local ggsEntity = playerManager:GetEntityByUser(username)
        if ggsEntity then
            return ggsEntity
        end
    end
    
    return userEntity
end

-- 为指定用户创建宠物
function PetManager:CreatePetForUser(username, petInfo)
    if not petInfo or not petInfo.type then
        return false, "宠物信息不能为空"
    end
    local userEntity = self:GetUserEntity(username)
    if not userEntity then
        print("CreatePetForUser===========userEntity not found",username)
        userEntity = GameLogic.GetPlayer()
    end
    self.userPets = self.userPets or {}
    if not self.userPets[username] then
        self.userPets[username] = {main = {},follow = {}}
    end
    local petType = petInfo.type
    local userPetGroup = self.userPets[username]
    if petType == Pet.PetType.MAIN and #userPetGroup.main >= PetManager.Config.MAX_MAIN_PETS then
        return false, "主宠数量已达上限"
    elseif petType == Pet.PetType.FOLLOW and #userPetGroup.follow >= PetManager.Config.MAX_FOLLOW_PETS then
        return false, "副宠数量已达上限"
    end
    local petId = petInfo.id
    local petConfig
    if petInfo.stage and petInfo.skin then
        petConfig = self:GetPetConfig(petInfo.skin,petInfo.stage)
        if petConfig then
            petId = petConfig.petId
        end
    end
    local petCustomConfig = self:GetCustomPetConfig(petId)
    if not petCustomConfig then
        return false, "宠物配置不存在: " .. tostring(petId)
    end
    
    -- 创建宠物实例
    local pet = Pet:new()
    local petData = {
        id = "pet_"..username .. "_" .. localPetId,
        configId = petId,
        name = (petCustomConfig.name or "宠物") .. localPetId,
        petType = petType,
        ownerName = username,
        modelUrl = petCustomConfig.modelUrl,
        position = self:GetDefaultPositionForUser(userEntity),
        skin = petInfo.skin,
        stage = petInfo.stage,
        scale = tonumber(petCustomConfig.scale) or 1,
        skinTexture = petCustomConfig.skinTexture or "",
    }
    if not pet:Init(petData) then
        return false, "宠物初始化失败"
    end
    
    if not pet:CreateEntity() then
        return false, "宠物实体创建失败"
    end
    
    if userEntity then
        pet:SetFollowTarget(userEntity)
    else
        LOG.std(nil, "warn", "PetManager", "No userEntity provided for pet " .. pet.id .. ", followTarget not set")
    end
    
    -- 添加到管理器
    local compositeId = pet.id  -- 已经是ownerName_petId格式
    self.pets[compositeId] = pet
    self.activePets[compositeId] = pet
    -- 添加到用户分组
    if petType == Pet.PetType.MAIN then
        table.insert(userPetGroup.main, compositeId)
    else
        table.insert(userPetGroup.follow, compositeId)
    end
    
    LOG.std(nil, "info", "PetManager", string.format("Pet created for user %s: %s (type: %s, config: %d)", username, pet.id, petType, petId))
    localPetId = localPetId + 1
    return pet.id, pet
end

-- 移除宠物 (支持复合ID)
function PetManager:RemovePet(petId)
    -- 参数类型检查和转换
    if type(petId) ~= "string" then
        petId = tostring(petId or "")
    end
    
    -- 如果传入的是简单petId，需要构造完整的复合ID
    local compositeId = petId
    local ownerPrefix = self.currentUser
    if not string.find(petId, ownerPrefix .. "_") then
        compositeId = ownerPrefix .. "_" .. petId
    end
    
    local pet = self.pets[compositeId]
    if not pet then
        return false, "宠物不存在"
    end
    
    -- 检查权限：只能移除自己的宠物
    if pet.ownerName ~= self.currentUser then
        return false, "无权限操作其他用户的宠物"
    end
    
    -- 销毁实体
    pet:DestroyEntity()
    
    -- 从列表中移除
    self.pets[compositeId] = nil
    self.activePets[compositeId] = nil
    
    -- 从用户分组中移除
    local userPetGroup = self.userPets[pet.ownerName]
    if userPetGroup then
        for i, id in ipairs(userPetGroup.main) do
            if id == compositeId then
                table.remove(userPetGroup.main, i)
                break
            end
        end
        
        for i, id in ipairs(userPetGroup.follow) do
            if id == compositeId then
                table.remove(userPetGroup.follow, i)
                break
            end
        end
    end
    LOG.std(nil, "info", "PetManager", "Pet removed: " .. compositeId)
    return true, "宠物移除成功"
end

-- 根据用户名删除宠物
function PetManager:RemovePetsByUser(username)
    if not username or username == "" then
        return false, "用户名不能为空"
    end
    
    local removedCount = 0
    local petsToRemove = {}
    
    -- 遍历所有宠物，找到ownerName匹配的宠物
    for compositeId, pet in pairs(self.pets) do
        if pet.ownerName == username then
            table.insert(petsToRemove, compositeId)
        end
    end
    
    -- 批量移除找到的宠物
    for _, compositeId in ipairs(petsToRemove) do
        local pet = self.pets[compositeId]
        if pet then
            -- 销毁实体
            pet:DestroyEntity()
            
            -- 从列表中移除
            self.pets[compositeId] = nil
            self.activePets[compositeId] = nil
            
            removedCount = removedCount + 1
            LOG.std(nil, "info", "PetManager", "Removed pet by user: " .. compositeId .. " (user: " .. username .. ")")
        end
    end
    
    -- 清理用户分组数据
    if self.userPets[username] then
        self.userPets[username] = nil
        LOG.std(nil, "info", "PetManager", "Cleared user pet group for: " .. username)
    end
    
    -- 标记需要保存
    if removedCount > 0 then
    end
    
    if removedCount > 0 then
        return true, "成功移除用户 " .. username .. " 的 " .. removedCount .. " 只宠物"
    else
        return false, "未找到用户 " .. username .. " 的宠物"
    end
end

function PetManager:GetPet(petId)
    if type(petId) ~= "string" then
        petId = tostring(petId or "")
    end    
    return self.pets[compositeId]
end

-- 获取指定用户的主宠
function PetManager:GetMainPet(username)
    username = username or self.currentUser
    local userPetGroup = self.userPets[username]
    if userPetGroup and #userPetGroup.main > 0 then
        return self.pets[userPetGroup.main[1]]
    end
    return nil
end

-- 获取指定用户的所有副宠
function PetManager:GetFollowPets(username)
    username = username or self.currentUser
    local pets = {}
    local userPetGroup = self.userPets[username]
    if userPetGroup then
        for _, petId in ipairs(userPetGroup.follow) do
            local pet = self.pets[petId]
            if pet then
                table.insert(pets, pet)
            end
        end
    end
    return pets
end

-- 获取所有宠物 (可按用户过滤)
function PetManager:GetAllPets(username)
    local allPets = {}
    if username then
        -- 获取指定用户的宠物
        local userPetGroup = self.userPets[username]
        if userPetGroup then
            for _, petId in ipairs(userPetGroup.main) do
                local pet = self.pets[petId]
                if pet then
                    table.insert(allPets, pet)
                end
            end
            for _, petId in ipairs(userPetGroup.follow) do
                local pet = self.pets[petId]
                if pet then
                    table.insert(allPets, pet)
                end
            end
        end
    else
        -- 获取所有宠物
        for petId, pet in pairs(self.pets) do
            table.insert(allPets, pet)
        end
    end
    return allPets
end

-- 激活/停用宠物 (支持复合ID)
function PetManager:SetPetActive(petId, active)
    -- 参数类型检查和转换
    if type(petId) ~= "string" then
        petId = tostring(petId or "")
    end
    
    -- 如果传入的是简单petId，需要构造完整的复合ID
    local compositeId = petId
    if not string.find(petId, "_") then
        compositeId = self.currentUser .. "_" .. petId
    end
    
    local pet = self.pets[compositeId]
    if not pet then
        return false, "宠物不存在"
    end
    
    -- 检查权限：只能操作自己的宠物
    if pet.ownerName ~= self.currentUser then
        return false, "无权限操作其他用户的宠物"
    end
    
    pet:SetActive(active)
    
    if active then
        self.activePets[compositeId] = pet
    else
        self.activePets[compositeId] = nil
    end
    
    LOG.std(nil, "info", "PetManager", string.format("Pet %s %s", compositeId, active and "activated" or "deactivated"))
    return true, "操作成功"
end

-- 获取宠物配置
function PetManager:GetCustomPetConfig(configId)
    local item = CustomCharItems:GetItemById(tostring(configId))
    if item then
        local filename = CustomCharItems:GetModelBySkinDDS(item.filename)
        local config = {
            name = "pet_"..os.time(),
            modelUrl = item.filename,
            scale = tonumber(item.scale or 1) or 1,
        }
        if filename and filename ~= "" and filename ~= item.filename then
            config.modelUrl = filename
            config.skinTexture = item.filename
        end
        return config
    end
    
    return nil
end

-- 获取默认位置
function PetManager:GetDefaultPosition()
    if self.playerEntity then
        local x,y,z =self.playerEntity:GetPosition()
        local pos = {
            x = x,
            y = y,
            z = z,
        }
        return {
            x = pos.x + math.random(-2, 2),
            y = pos.y,
            z = pos.z + math.random(-2, 2)
        }
    end
    
    return {x = 0, y = 0, z = 0}
end

-- 获取指定用户的默认位置
local defaultUserPos = {x = 19200, y = 5, z = 19200}
function PetManager:GetDefaultPositionForUser(userEntity)
    if userEntity and userEntity.GetPosition then
        local x,y,z = userEntity:GetPosition()
        if x and y and z then
            return {
                x = x + math.random(-2, 2),
                y = y,
                z = z + math.random(-2, 2)
            }
        end
    end
    local player = GameLogic.GetPlayer()
    if player and player.GetPosition then
        local x,y,z = player:GetPosition()
        if x and y and z then
            return {
                x = x + math.random(-2, 2),
                y = y,
                z = z + math.random(-2, 2)
            }
        end
    end
    return defaultUserPos
end

-- 设置管理器激活状态
function PetManager:SetActive(active)
    self.isActive = active
    
    -- 设置所有宠物的激活状态
    for petId, pet in pairs(self.pets) do
        pet:SetActive(active)
    end
    
    LOG.std(nil, "info", "PetManager", "PetManager " .. (active and "activated" or "deactivated"))
end

-- 获取宠物数量 (可按用户过滤)
function PetManager:GetPetCount(username)
    if username then
        local userPetGroup = self.userPets[username]
        if userPetGroup then
            return #userPetGroup.main + #userPetGroup.follow
        end
        return 0
    else
        local count = 0
        for _ in pairs(self.pets) do
            count = count + 1
        end
        return count
    end
end

-- 获取激活宠物数量 (可按用户过滤)
function PetManager:GetActivePetCount(username)
    local count = 0
    if username then
        -- 统计指定用户的激活宠物
        for petId, pet in pairs(self.activePets) do
            if pet.ownerName == username then
                count = count + 1
            end
        end
    else
        -- 统计所有激活宠物
        for _ in pairs(self.activePets) do
            count = count + 1
        end
    end
    return count
end

function PetManager:OnGGSLogIn(packetPlayerInfo)
    local playerInfo = packetPlayerInfo and packetPlayerInfo.playerInfo or {}
    local userInfo = playerInfo and playerInfo.userinfo or {}
    local petInfo = userInfo and userInfo.petInfo or {}
    local username = packetPlayerInfo and packetPlayerInfo.username or ""
    if username ~= "" and username ~= self.currentUser then
        self:AddPetsByUser(username, petInfo)
    end
end

function PetManager:OnGGSLogout(username)
    if username and username ~= self.currentUser then
        self.userPetInfo = self.userPetInfo or {}
        self.userPetInfo[username] = nil
        self:RemovePetsByUser(username)
    end
end

function PetManager:OnGGSUpdatePetItem(packetPlayerInfo)
    local username = packetPlayerInfo and packetPlayerInfo.username or ""
    local petInfoStr = packetPlayerInfo and packetPlayerInfo.petItemStr or ""
    if username ~= "" and username ~= self.currentUser then
        local tempStrList = commonlib.split(petInfoStr, ";")
        local petInfo = {}
        for _, strPet in ipairs(tempStrList) do
            local pet = {}
            local tempPetList = commonlib.split(strPet, ",")
            if #tempPetList >= 3 then
                pet.type = tempPetList[1]
                pet.id = tempPetList[2]
                pet.isVisible = tempPetList[3] == "1"
                table.insert(petInfo, pet)
            end
        end
        
        self:RemovePetsByUser(username)
        self:AddPetsByUser(username, petInfo)
    end
end

function PetManager:UpdatePetStatus(callback,petInfo)
    if not petInfo or not self.currentUser or self.currentUser == "" then return end
    self.userPetInfo = self.userPetInfo or {}
    self.userPetInfo[self.currentUser] = petInfo
    local petInfo = self.userPetInfo[self.currentUser]
    self:RemovePetsByUser(self.currentUser)
    self:AddPetsByUser(self.currentUser, petInfo)
    if callback and type(callback) == "function" then
        callback()
        self:SendGGSPetInfo(petInfo)
    end
end

function PetManager:SendGGSPetInfo(petInfo)
    if not petInfo then return end
    local player = GameLogic.GetPlayer()
    if not player then return end
    local petStr = ""
    for _, pet in pairs(petInfo) do
        local strPet = ""
        if pet.type ~= "" then
            strPet = strPet .. pet.type .. ","
        end
        if pet.id and tonumber(pet.id) > 0 then
            strPet = strPet .. pet.id .. ","
        end
        strPet = strPet ..(pet.isVisible == false and "0" or "1")
        petStr = petStr .. strPet..";"
    end
    player:SetPetItem(petStr)
end

function PetManager:HideAllPets()
    -- 隐藏所有宠物
    for compositeId, pet in pairs(self.pets) do
        if pet and pet.isActive then
            pet:SetActive(false)
            self.activePets[compositeId] = nil
            LOG.std(nil, "info", "PetManager", "Hidden pet: " .. compositeId)
        end
    end
    LOG.std(nil, "info", "PetManager", "All pets hidden")
end

function PetManager:ShowAllPets()
    -- 显示所有宠物
    for compositeId, pet in pairs(self.pets) do
        if pet and not pet.isActive then
            pet:SetActive(true)
            self.activePets[compositeId] = pet
            LOG.std(nil, "info", "PetManager", "Shown pet: " .. compositeId)
        end
    end
    LOG.std(nil, "info", "PetManager", "All pets shown")
end

function PetManager:HideUserPets(username)
    -- 参数验证
    if not username or username == "" then
        LOG.std(nil, "warn", "PetManager", "Username cannot be empty")
        return false, "用户名不能为空"
    end
    
    local hiddenCount = 0
    
    -- 遍历所有宠物，隐藏指定用户的宠物
    for compositeId, pet in pairs(self.pets) do
        print("hide user pets=============",pet.ownerName,pet.isActive,compositeId,pet.petType,username)
        if pet and pet.ownerName == username and pet.isActive then
            pet:SetActive(false)
            self.activePets[compositeId] = nil
            hiddenCount = hiddenCount + 1
            LOG.std(nil, "info", "PetManager", "Hidden pet: " .. compositeId .. " (user: " .. username .. ")")
        end
    end
    
    if hiddenCount > 0 then
        LOG.std(nil, "info", "PetManager", string.format("Hidden %d pets for user: %s", hiddenCount, username))
        return true, string.format("成功隐藏用户 %s 的 %d 只宠物", username, hiddenCount)
    else
        LOG.std(nil, "warn", "PetManager", "No active pets found for user: " .. username)
        return false, "未找到用户 " .. username .. " 的激活宠物"
    end
end

function PetManager:ShowUserPets(username)
    -- 参数验证
    if not username or username == "" then
        LOG.std(nil, "warn", "PetManager", "Username cannot be empty")
        return false, "用户名不能为空"
    end
    
    local shownCount = 0
    
    -- 遍历所有宠物，显示指定用户的宠物
    for compositeId, pet in pairs(self.pets) do
        if pet and pet.ownerName == username and not pet.isActive then
            pet:SetActive(true)
            self.activePets[compositeId] = pet
            shownCount = shownCount + 1
            LOG.std(nil, "info", "PetManager", "Shown pet: " .. compositeId .. " (user: " .. username .. ")")
        end
    end
    
    if shownCount > 0 then
        LOG.std(nil, "info", "PetManager", string.format("Shown %d pets for user: %s", shownCount, username))
        return true, string.format("成功显示用户 %s 的 %d 只宠物", username, shownCount)
    else
        LOG.std(nil, "warn", "PetManager", "No hidden pets found for user: " .. username)
        return false, "未找到用户 " .. username .. " 的隐藏宠物"
    end
end

function PetManager:HideMainPet(username)
    local mainPet = self:GetMainPet(username)
    if mainPet then
        mainPet:SetActive(false)
    end
end

function PetManager:ShowMainPet(username)
    local mainPet = self:GetMainPet(username)
    if mainPet then
        mainPet:SetActive(true)
    end
end

function PetManager:GetPetConfig(skin,stage)
    local petConfig = PetManager.petConfigs[skin]
    if not petConfig then
        return
    end
    local stageConfig = petConfig[stage]
    if not stageConfig then
        return
    end
    return stageConfig
end

function PetManager:GeneratePetMap()
    if not self.petMap then
        self.petMap = {}
        for _, petConfig in pairs(self.petConfigs) do
            for _, stageConfig in pairs(petConfig) do
                self.petMap[stageConfig.id] = stageConfig
            end
        end
    end
    return self.petMap
end

function PetManager:GetPetConfigById(petId)
    local petMap = self:GeneratePetMap()
    return petMap[petId]
end


