--[[  
Title: Pet
Author: 
Date: 2024-01-01
Desc: 新宠物系统 - 宠物类实现
包含副宠跟随、随机行走等功能
]]

NPL.load("(gl)script/ide/System/Core/ToolBase.lua")
NPL.load("(gl)script/ide/System/Scene/Overlays/ShapesDrawer.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua")

NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityLiveModel.lua");
local EntityLiveModel = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityLiveModel")
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager")
local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer")
local SentientGroupIDs = commonlib.gettable("MyCompany.Aries.Game.GameLogic.SentientGroupIDs");
local Pet = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.Pet.Pet"))
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local LOG = commonlib.gettable("LOG")

-- 宠物类型枚举
Pet.PetType = {
    MAIN = "main",     -- 主宠
    FOLLOW = "follow"  -- 副宠
}
-- 宠物状态枚举
Pet.PetStatus = {
    IDLE = "idle",
    WALKING = "walking",
    FOLLOWING = "following",
    FEEDING = "feeding",
    SLEEPING = "sleeping"
}

local sentient_radius = 50
-- 构造函数
function Pet:ctor()
    -- 基础属性
    self.id = nil                    -- 宠物唯一ID
    self.configId = nil              -- 配置ID (90000-90999)
    self.name = ""                   -- 宠物名称
    self.petType = Pet.PetType.MAIN  -- 宠物类型
    self.ownerName = ""              -- 主人名称
    
    -- 实体相关
    self.entity = nil                -- 宠物实体对象
    self.modelUrl = ""               -- 模型路径
    self.skinTexture = ""            -- 模型纹理路径
    self.scale = 1               -- 缩放比例
    
    -- 位置和移动
    self.position = {x = 0, y = 0, z = 0}  -- 当前位置
    self.followTarget = nil          -- 跟随目标
    self.followDistance = 5          -- 跟随距离
    self.lastValidPosition = nil     -- 上次有效位置
    
    -- 状态管理
    self.status = Pet.PetStatus.IDLE
    
    -- 行为控制
    self.randomWalkTimer = 0         -- 随机移动计时器
    self.randomWalkInterval = 8000   -- 随机行走间隔 (毫秒) - 调整为8秒，减少频繁移动
    self.lastMoveTime = 0            -- 上次移动时间
    self.lastUpdateTime = 0          -- 上次更新时间
    self.moveStableTime = 1500       -- 移动后稳定时间 (毫秒) - 增加到1.5秒
    self.isActive = true             -- 是否激活
    
    -- 传送相关
    self.teleportDistance = 15       -- 超过此距离时传送 - 增加到20单位
    
    self.needSync = false            -- 是否需要同步
    self.debugMode = false

    self.skin = "purple"
    self.stage = 1
    
    -- 初始化随机数种子，确保每个宠物实例的随机行为不同
    math.randomseed(os.time() + (self.id and string.len(tostring(self.id)) or 0))
end

-- 切换调试模式
function Pet:SetDebugMode(enabled)
    self.debugMode = enabled
    if enabled then
        print("宠物调试模式已启用")
    else
        print("宠物调试模式已禁用")
    end
end

-- 获取附近的随机位置
function Pet:GetRandomPositionNear(centerPos, minDistance, maxDistance)
    if not centerPos then 
        if self.debugMode then
            print("GetRandomPositionNear failed: centerPos is nil")
        end
        return nil 
    end
    
    local attempts = 0
    local maxAttempts = 10
    
    if self.debugMode then
        print(string.format("寻找随机位置，中心: (%.2f, %.2f, %.2f), 距离范围: %.1f-%.1f", 
              centerPos.x, centerPos.y, centerPos.z, minDistance, maxDistance))
    end
    
    while attempts < maxAttempts do
        local angle = math.random() * 2 * math.pi
        local distance = minDistance + math.random() * (maxDistance - minDistance)
        
        local x = centerPos.x + distance * math.cos(angle)
        local z = centerPos.z + distance * math.sin(angle)
        local y = centerPos.y
        
        local position = {x = x, y = y, z = z}
        
        if self:IsPositionValid(position) then
            if self.debugMode then
                print(string.format("找到有效随机位置: (%.2f, %.2f, %.2f), 尝试次数: %d", 
                      position.x, position.y, position.z, attempts + 1))
            end
            return position
        end
        
        attempts = attempts + 1
    end
    
    if self.debugMode then
        print(string.format("无法找到有效随机位置，已尝试 %d 次", maxAttempts))
    end
    
    return nil  -- 无法找到有效位置
end
-- 初始化宠物
function Pet:Init(data)
    if not data then return false end
    self.configId = data.configId
    self.name = data.name or "宠物"
    self.petType = data.petType or Pet.PetType.MAIN
    self.ownerName = data.ownerName or ""
    self.id = data.id
    self.modelUrl = data.modelUrl or ""
    self.scale = data.scale or 1
    self.skin = data.skin or "purple"
    self.stage = data.stage or 1
    if data.skinTexture and data.skinTexture ~= "" and self.stage and self.stage > 1 then
        self.skinTexture = data.skinTexture
    end
    -- 初始化位置
    if data.position then
        self.position = {x = data.position.x, y = data.position.y, z = data.position.z}
    end
    
    return true
end

-- 创建宠物实体
function Pet:CreateEntity()
    if not self.modelUrl or self.modelUrl == "" then
        LOG.std(nil, "error", "Pet", "CreateEntity failed: modelUrl is empty")
        return false
    end
    local x, y, z = self.position.x, self.position.y, self.position.z
    local bx, by, bz = BlockEngine:block(x, y, z)
    self.entity = GameLogic.EntityManager.EntityLiveModel:Create({
        bx = bx,
        by = by,
        bz = bz,
        item_id = block_types.names.LiveModel,
        facing = 0
    })
    if self.entity then
        self.entity:SetPosition(x, y, z)
        self.entity:SetName(self.name or ("pet_" .. self.id))
        self.entity:setScale(self.scale)
        self.entity.petId = self.id
        if self.entity.SetCanDrag then
            self.entity:SetCanDrag(false)  -- 禁止拖动
        end
        if self.entity.SetLocked then
            self.entity:SetLocked(true)    -- 锁定实体
        end
        if self.entity.SetPickable then
            self.entity:SetPickable(false) -- 禁止选中
        end
        if self.entity.SetPersistent then -- 是否可以保存到硬盘
            self.entity:SetPersistent(false)
        end
        if self.entity.SetSkipPicking then
            self.entity:SetSkipPicking(true);
        end
        self:UpdateSentient()
        self.entity:Refresh()
        self.entity:Attach()
        self:UpdateModel()
        self:FallDown()
        LOG.std(nil, "info", "Pet", "Pet entity created successfully: " .. self.id)
        return true
    else
        LOG.std(nil, "error", "Pet", "Failed to create pet entity: " .. self.id)
        return false
    end
end

function Pet:UpdateSentient()
    if not self.entity then
        return
    end
    local obj = self.entity:GetInnerObject()
    if obj and obj:IsValid() then
        obj:SetField("AlwaysSentient", false);
		obj:SetField("SentientField", 0);
		obj:SetField("Sentient", false);
        obj:SetField("IsControlledExternally", false)
		obj:SetGroupID(SentientGroupIDs["OPC"]);
		obj:SetSentientField(SentientGroupIDs["Player"], true);
		obj:SetField("Sentient Radius", sentient_radius);
		obj:SetField("MovementStyle", 4);
        if self.skinTexture and self.skinTexture ~= "" then
            obj:ToCharacter():SetSpeedScale(1)
        else
            obj:ToCharacter():SetSpeedScale(1.5)
        end
    end
end

function Pet:UpdateModel()
    if not self.entity then
        return
    end
     self.entity:SetModelFile(self.modelUrl)
     if self.skinTexture and self.skinTexture ~= "" then
         local obj = self.entity:GetInnerObject()
         local index = CustomCharItems:GetDDSSkinColorIndex(self.skinTexture)
         if index and index > 0 then
             if obj and obj:IsValid() then
                 local character = obj:ToCharacter()
                 if character and character:IsValid() then
                     character:SetBodyParams(index, -1, -1, -1, -1);
                 end
             end
         else
             if obj and obj:IsValid() then
                 obj:SetReplaceableTexture(1, ParaAsset.LoadTexture("", self.skinTexture, 1))
             end
         end
     end
end

-- 销毁宠物实体
function Pet:DestroyEntity()
    if self.entity then
        self.entity:Destroy()
        self.entity = nil
        LOG.std(nil, "info", "Pet", "Pet entity destroyed: " .. self.id)
    end
end

-- 更新宠物状态 (主循环)
function Pet:Update(deltaTime)
    if not self.isActive then return end
    self:SyncPosition()
    self:UpdateBehavior(deltaTime)
end

-- 更新行为
function Pet:UpdateBehavior(deltaTime)
    if not self.entity then 
        return 
    end
    if self.petType == Pet.PetType.MAIN then
        self:UpdateMainPetBehavior(deltaTime)
    else
        self:UpdateFollowBehavior()
    end
end

-- 更新跟随行为 (副宠)
function Pet:UpdateFollowBehavior()
    if not self.followTarget or not self.followTarget.GetPosition then
        return
    end
    local currentTime = commonlib.TimerManager.GetCurrentTime()
    if self.lastMoveTime == 0 then
        self.lastMoveTime = currentTime
    end
    local x,y,z = self.followTarget:GetPosition()
    local targetPos = {x = x,y = y,z = z,}
    local distance = self:GetDistanceToPosition(targetPos)
    
    local timeDis = currentTime - self.lastMoveTime
    local inStablePeriod = timeDis < self.moveStableTime
     
    if distance > self.teleportDistance then
        local success = self:TeleportToTarget(targetPos)
        if success then
            self.lastMoveTime = currentTime
        end
        return
    end
    
    if not inStablePeriod then
        if distance > self.followDistance then
            local followPos = self:CalculateFollowPosition(targetPos)
            local success = self:MoveTo(followPos)
            self.lastMoveTime = currentTime
            if success then
                self.status = Pet.PetStatus.FOLLOWING
            end
        else
            self.randomWalkTimer = self.randomWalkTimer + (currentTime - (self.lastUpdateTime or currentTime))
            self.lastUpdateTime = currentTime
            if self.randomWalkTimer >= 10000 then  -- 副宠每10秒检查一次随机移动
                if math.random() < 0.3 then  -- 30%概率随机移动（比主宠低）
                    print("random walk===============")
                    self:StartRandomWalk()
                    self.lastMoveTime = currentTime
                end
                self.randomWalkTimer = 0
            end
        end
    end
end

-- 更新主宠行为（跟随+5单位内随机行走）
function Pet:UpdateMainPetBehavior(deltaTime)
    if not self.followTarget then 
        return 
    end
    local currentTime = commonlib.TimerManager.GetCurrentTime()
    if self.lastMoveTime == 0 then
        self.lastMoveTime = currentTime
    end
    local timeDis = currentTime - self.lastMoveTime
    local inStablePeriod = timeDis < self.moveStableTime
    if not self.followTarget or not self.followTarget.GetPosition then
        return
    end
    local x,y,z = self.followTarget:GetPosition()
    local targetPos = {x = x,y = y,z = z}
    local distance = self:GetDistanceToPosition(targetPos)
    if distance > self.teleportDistance then
        local success = self:TeleportToTarget(targetPos)
        if success then
            self.status = Pet.PetStatus.FOLLOWING
            self.lastMoveTime = currentTime
            self:FallDown()
        end
        return
    end
    
    if not inStablePeriod then
        if distance > self.followDistance then
            local followPos = self:CalculateFollowPosition(targetPos)
            local success = self:MoveTo(followPos)
            self.lastMoveTime = currentTime
            if success then
                self.status = Pet.PetStatus.FOLLOWING
            end
        else
            self.randomWalkTimer = self.randomWalkTimer + (currentTime - (self.lastUpdateTime or currentTime))
            self.lastUpdateTime = currentTime
            if self.randomWalkTimer >= self.randomWalkInterval then
                if math.random() < 0.5 then  -- 50%概率随机移动
                    self:StartMainPetRandomWalk(targetPos)
                    self.lastMoveTime = currentTime
                end
                self.randomWalkTimer = 0
            end
            if distance < 1 and self.status ~= Pet.PetStatus.IDLE then
                self.status = Pet.PetStatus.IDLE
                self:StopMoving()
            end
        end
    end
end

-- 开始随机行走（副宠用）
function Pet:StartRandomWalk()
    if not self.followTarget or not self.followTarget.GetPosition then 
        return 
    end
    
    local x,y,z = self.followTarget:GetPosition()
    local targetPos = {x = x,y = y,z = z,}
    local currentTime = commonlib.TimerManager.GetCurrentTime()
    math.randomseed(currentTime + math.random(1000))
    local angle = math.random() * math.pi * 2
    local distance = math.random() + math.random(3, 6)  -- 3-7格距离，减少移动范围
    
    local randomPos = {
        x = targetPos.x + math.cos(angle) * distance,
        y = targetPos.y,
        z = targetPos.z + math.sin(angle) * distance
    }
    local success = self:MoveTo(randomPos)
    if success then
        self.status = Pet.PetStatus.WALKING
    end
end

-- 主宠在5单位范围内随机行走
function Pet:StartMainPetRandomWalk(targetPos)
    if not targetPos then 
        return 
    end
    local randomPos = self:GetRandomPositionNear(targetPos, 2, 5)  -- 2-5块范围内随机位置
    if randomPos then
        local success = self:MoveTo(randomPos)
        if success then
            self.status = Pet.PetStatus.WALKING
        end
    end
end

function Pet:FallDown()
    if not self.entity or not self.entity.FallDown then
        return false
    end
    local innerObject = self.entity:GetInnerObject()
    if innerObject and innerObject:IsValid() and innerObject:IsStanding() then
        self.entity:FallDown()
    end
end

-- 移动到指定位置
function Pet:MoveTo(position)
    if not self.entity or not position then
        return false
    end
    local validPosition = self:FindValidPosition(position)
    if not validPosition then
        validPosition = position
    end
    self.lastValidPosition = self.position or {}
    local innerObject = self.entity:GetInnerObject()
    if innerObject then
        self:FallDown()
        local petCharacter = innerObject:ToCharacter()
        if petCharacter and petCharacter:IsValid() then
            local disX = validPosition.x - self.position.x
            local disZ = validPosition.z - self.position.z
            local disY = 0--validPosition.y - self.position.y
            petCharacter:MoveTo(disX, disY, disZ)
        end
    end

    return true
end

-- 停止移动
function Pet:StopMoving()
    if not self.entity then
        return
    end
    local petCharacter = self.entity:GetInnerObject():ToCharacter()
    if petCharacter and petCharacter:IsValid() then
        petCharacter:Stop()
    end
end

-- 传送到目标附近
function Pet:TeleportToTarget(targetPos)
    if not targetPos or not self.entity then 
        return false
    end
    local petCharacter = self.entity:GetInnerObject():ToCharacter()
    if petCharacter and petCharacter:IsValid() then
        petCharacter:Stop()
    end
    local teleportPos = self:CalculateFollowPosition(targetPos)
    self.entity:SetPosition(teleportPos.x, teleportPos.y, teleportPos.z)
    self.position.x = teleportPos.x
    self.position.y = teleportPos.y
    self.position.z = teleportPos.z
    return true
end

-- 计算跟随位置
function Pet:CalculateFollowPosition(targetPos)
    local maxAttempts = 8  -- 最多尝试8个方向
    local distance = self.followDistance * 0.8  -- 稍微近一点
    for i = 1, maxAttempts do
        local angle = (i - 1) * (math.pi * 2 / maxAttempts) + math.random() * 0.5
        local candidatePos = {
            x = targetPos.x + math.cos(angle) * distance,
            y = targetPos.y,
            z = targetPos.z + math.sin(angle) * distance
        }
        if self:IsPositionValid(candidatePos) then
            return candidatePos
        end
    end
    return {
        x = targetPos.x + math.random(-1, 1),
        y = targetPos.y,
        z = targetPos.z + math.random(-1, 1)
    }
end

function Pet:GetDistanceToPosition(position)
    if not position or not self.entity then return math.huge end
    local x, y, z = self.entity:GetPosition()
    local currentPos = {x = x, y = y, z = z}
    local dx = currentPos.x - position.x
    local dz = currentPos.z - position.z
    local distance = math.sqrt(dx * dx + dz * dz)
    return distance
end

function Pet:IsPositionValid(position)
    if not position then return false end
    local bx, by, bz = BlockEngine:block(position.x, position.y, position.z)
    local blockId = BlockEngine:GetBlockId(bx, by, bz)
    if blockId and blockId ~= 0 then
        return false  -- 有障碍物
    end
    local hasSupport = false
    for yOffset = 0, 5 do  -- 增加搜索范围
        local groundBlockId = BlockEngine:GetBlockId(bx, by - yOffset, bz)
        if groundBlockId and groundBlockId ~= 0 then
            hasSupport = true
            break
        end
    end
    return true
end

function Pet:FindValidPosition(position)
    if self:IsPositionValid(position) then
        return position
    end
    
    local adjustedPos = {x = position.x, y = position.y + 1, z = position.z}
    if self:IsPositionValid(adjustedPos) then
        return adjustedPos
    end
    return position
end

-- 计算两点间距离
function Pet:GetDistance(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dz = pos1.z - pos2.z
    return math.sqrt(dx*dx + dz*dz)
end

-- 设置跟随目标
function Pet:SetFollowTarget(target)
    self.followTarget = target
end

-- 激活/停用宠物
function Pet:SetActive(active)
    self.isActive = active
    if self.entity then
        self.entity:SetVisible(active)
    end
end

-- 同步实体位置到self.position
function Pet:SyncPosition()
    if self.entity then
        self.entity:UpdatePosition()
        local x, y, z = self.entity:GetPosition()
        self.position = {x = x, y = y, z = z}
    end
end

function Pet:Say(text)
    if not self.debugMode then
        text = text or self.name .."("..self.petType..")"
    end
    if self.entity then
        self.entity:Say(text)
    end
end

function Pet:GetEntity()
    return self.entity
end

function Pet:SetAssetFile(assetFile)
    if not assetFile or assetFile == "" then
        LOG.std(nil, "warn", "Pet", "Asset file cannot be empty")
        return false
    end
    if self.entity then
        self.entity:SetModelFile(assetFile)
    end
end

return Pet