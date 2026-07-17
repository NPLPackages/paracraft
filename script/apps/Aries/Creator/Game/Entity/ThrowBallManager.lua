--[[
Title: ThrowBallManager - Simplified Throw Ball Manager
Author(s): Generated based on original ThrowBall.lua
Date: 2024
Desc: A simplified throw ball manager for the new game framework
      Provides high-level API for throwing mechanics
      Manages EntityThrowBall instances

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/ThrowBallManager.lua");
local ThrowBallManager = commonlib.gettable("MyCompany.Aries.Game.Entity.ThrowBallManager");

-- Simple throw
ThrowBallManager:ThrowBall(startX, startY, startZ, endX, endY, endZ);

-- Advanced throw with options
ThrowBallManager:ThrowBallAdvanced({
    startPoint = {x=0, y=10, z=0},
    endPoint = {x=10, y=10, z=10},
    ballModel = "model/custom_ball.x",
    duration = 2.0,
    onHit = function(x, y, z) print("Ball hit at", x, y, z) end
});
------------------------------------------------------------
--]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityThrowBall.lua");
local EntityThrowBall = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityThrowBall");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");

local ThrowBallManager = commonlib.gettable("MyCompany.Aries.Game.Entity.ThrowBallManager");

-- Active throw balls
ThrowBallManager.activeBalls = {};

-- Default settings
ThrowBallManager.defaultSettings = {
    ballModel = "model/07effect/v5/SnowBalloon/SnowBalloon_ball_anim.x",
    duration = 1.0,
    gravity = 0.025,
    maxDistance = 60,
    minDistance = 0.5,
    hitRadius = 0.2
};

-- Initialize the manager
function ThrowBallManager:Init()
    self.activeBalls = {};
    LOG.std(nil, "info", "ThrowBallManager", "ThrowBallManager initialized");
end

-- Simple throw ball function
-- @param startX, startY, startZ: starting position (block coordinates)
-- @param endX, endY, endZ: target position (block coordinates)
-- @param options: optional table with settings
-- @return: EntityThrowBall instance or nil if failed
function ThrowBallManager:ThrowBall(startX, startY, startZ, endX, endY, endZ, options)
    options = options or {};
    
    -- Convert block coordinates to real world coordinates
    local realStartX, realStartY, realStartZ = BlockEngine:real(startX, startY, startZ);
    local realEndX, realEndY, realEndZ = BlockEngine:real(endX, endY, endZ);
    
    local throwOptions = {
        startPoint = {x = realStartX, y = realStartY, z = realStartZ},
        endPoint = {x = realEndX, y = realEndY, z = realEndZ},
        ballModel = options.ballModel or self.defaultSettings.ballModel,
        duration = options.duration or self.defaultSettings.duration,
        gravity = options.gravity or self.defaultSettings.gravity,
        maxDistance = options.maxDistance or self.defaultSettings.maxDistance,
        minDistance = options.minDistance or self.defaultSettings.minDistance,
        hitRadius = options.hitRadius or self.defaultSettings.hitRadius,
        onStart = options.onStart,
        onUpdate = options.onUpdate,
        onHit = options.onHit,
        onEnd = options.onEnd
    };
    
    return self:ThrowBallAdvanced(throwOptions);
end

-- Advanced throw ball function with full options
-- @param options: table with all throw parameters (real world coordinates)
-- @return: EntityThrowBall instance or nil if failed
function ThrowBallManager:ThrowBallAdvanced(options)
    if not options or not options.startPoint or not options.endPoint then
        LOG.std(nil, "warn", "ThrowBallManager", "Invalid throw options: missing start or end point");
        return nil;
    end
    
    -- Create entity at start position (using real world coordinates)
    local entity = EntityThrowBall:Create({
        x = options.startPoint.x,
        y = options.startPoint.y,
        z = options.startPoint.z
    });
    
    if not entity then
        LOG.std(nil, "error", "ThrowBallManager", "Failed to create EntityThrowBall");
        return nil;
    end
    
    -- Configure entity
    entity:SetStartPoint(options.startPoint);
    entity:SetEndPoint(options.endPoint);
    
    if options.ballModel then
        entity:SetBallModel(options.ballModel);
    end
    
    if options.duration then
        entity:SetThrowDuration(options.duration);
    end
    
    if options.gravity then
        entity:SetGravity(options.gravity);
    end
    
    if options.maxDistance then
        entity:SetMaxDistance(options.maxDistance);
    end
    
    if options.minDistance then
        entity:SetMinDistance(options.minDistance);
    end
    
    if options.hitRadius then
        entity:SetHitRadius(options.hitRadius);
    end
    
    -- Connect event handlers
    if options.onStart then
        entity:Connect("throwStarted", entity, options.onStart);
    end
    
    if options.onUpdate then
        entity:Connect("throwUpdate", entity, function(entity, progress, x, y, z)
            options.onUpdate(progress, x, y, z);
        end);
    end
    
    if options.onHit then
        entity:Connect("throwHit", entity, function(entity, x, y, z)
            options.onHit(x, y, z);
        end);
    end
    
    if options.onEnd then
        entity:Connect("throwEnded", entity, options.onEnd);
    end
    
    -- Connect cleanup handler
    entity:Connect("throwEnded", self, function()
        self:RemoveActiveBall(entity);
    end);
    
    -- Add to active balls
    self:AddActiveBall(entity);
    
    -- Start the throw
    if entity:StartThrow() then
        LOG.std(nil, "info", "ThrowBallManager", "Successfully started throw ball");
        return entity;
    else
        LOG.std(nil, "warn", "ThrowBallManager", "Failed to start throw ball");
        entity:Destroy();
        self:RemoveActiveBall(entity);
        return nil;
    end
end

-- Add ball to active list
function ThrowBallManager:AddActiveBall(entity)
    if entity then
        table.insert(self.activeBalls, entity);
    end
end

-- Remove ball from active list
function ThrowBallManager:RemoveActiveBall(entity)
    if not entity then
        return;
    end
    
    for i, ball in ipairs(self.activeBalls) do
        if ball == entity then
            table.remove(self.activeBalls, i);
            break;
        end
    end
end

-- Get all active throw balls
function ThrowBallManager:GetActiveBalls()
    return self.activeBalls;
end

-- Get count of active throw balls
function ThrowBallManager:GetActiveBallCount()
    return #self.activeBalls;
end

-- Stop all active throws
function ThrowBallManager:StopAllThrows()
    for _, ball in ipairs(self.activeBalls) do
        if ball and ball.EndThrow then
            ball:EndThrow();
        end
    end
    
    self.activeBalls = {};
    LOG.std(nil, "info", "ThrowBallManager", "Stopped all active throws");
end

-- Clean up finished throws
function ThrowBallManager:CleanupFinishedThrows()
    local activeCount = 0;
    local newActiveBalls = {};
    
    for _, ball in ipairs(self.activeBalls) do
        if ball and ball:GetThrowState() ~= "ended" then
            table.insert(newActiveBalls, ball);
            activeCount = activeCount + 1;
        end
    end
    
    self.activeBalls = newActiveBalls;
    
    if activeCount ~= #self.activeBalls then
        LOG.std(nil, "info", "ThrowBallManager", "Cleaned up finished throws, active count: %d", activeCount);
    end
end

-- Update default settings
function ThrowBallManager:SetDefaultSettings(settings)
    if settings then
        for key, value in pairs(settings) do
            if self.defaultSettings[key] ~= nil then
                self.defaultSettings[key] = value;
            end
        end
        LOG.std(nil, "info", "ThrowBallManager", "Updated default settings");
    end
end

-- Get default settings
function ThrowBallManager:GetDefaultSettings()
    return self.defaultSettings;
end

-- Throw ball from player to target position
-- @param targetX, targetY, targetZ: target position (block coordinates)
-- @param options: optional settings
function ThrowBallManager:ThrowFromPlayer(targetX, targetY, targetZ, options)
    local player = GameLogic.GetPlayer();
    if not player then
        return
    end
    local startPos;
    
    if player and player.GetPosition then
        -- Player entity (already in real world coordinates)
        local x, y, z = player:GetPosition();
        startPos = {x = x, y = y + 1.5, z = z}; -- Add height offset
    else
        LOG.std(nil, "warn", "ThrowBallManager", "Invalid player parameter for ThrowFromPlayer");
        return nil;
    end
    
    -- Convert target block coordinates to real world coordinates
    local realTargetX, realTargetY, realTargetZ = BlockEngine:real(targetX, targetY, targetZ);
    
    -- Use ThrowBallAdvanced with real world coordinates
    local throwOptions = {
        startPoint = startPos,
        endPoint = {x = realTargetX, y = realTargetY, z = realTargetZ},
        ballModel = options and options.ballModel or self.defaultSettings.ballModel,
        duration = options and options.duration or self.defaultSettings.duration,
        gravity = options and options.gravity or self.defaultSettings.gravity,
        maxDistance = options and options.maxDistance or self.defaultSettings.maxDistance,
        minDistance = options and options.minDistance or self.defaultSettings.minDistance,
        hitRadius = options and options.hitRadius or self.defaultSettings.hitRadius,
        onStart = options and options.onStart,
        onUpdate = options and options.onUpdate,
        onHit = options and options.onHit,
        onEnd = options and options.onEnd
    };
    
    return self:ThrowBallAdvanced(throwOptions);
end

-- Throw ball to target entity
-- @param startX, startY, startZ: starting position (block coordinates)
-- @param targetEntity: target entity (real world coordinates)
-- @param options: optional settings
function ThrowBallManager:ThrowToEntity(startX, startY, startZ, targetEntity, options)
    if not targetEntity or not targetEntity.GetPosition then
        LOG.std(nil, "warn", "ThrowBallManager", "Invalid target entity for ThrowToEntity");
        return nil;
    end
    
    -- Convert start block coordinates to real world coordinates
    local realStartX, realStartY, realStartZ = BlockEngine:real(startX, startY, startZ);
    
    -- Get target entity position (already in real world coordinates)
    local x, y, z = targetEntity:GetPosition();
    
    -- Use ThrowBallAdvanced with real world coordinates
    local throwOptions = {
        startPoint = {x = realStartX, y = realStartY, z = realStartZ},
        endPoint = {x = x, y = y + 1, z = z}, -- Add small height offset for target
        ballModel = options and options.ballModel or self.defaultSettings.ballModel,
        duration = options and options.duration or self.defaultSettings.duration,
        gravity = options and options.gravity or self.defaultSettings.gravity,
        maxDistance = options and options.maxDistance or self.defaultSettings.maxDistance,
        minDistance = options and options.minDistance or self.defaultSettings.minDistance,
        hitRadius = options and options.hitRadius or self.defaultSettings.hitRadius,
        onStart = options and options.onStart,
        onUpdate = options and options.onUpdate,
        onHit = options and options.onHit,
        onEnd = options and options.onEnd
    };
    
    return self:ThrowBallAdvanced(throwOptions);
end

function ThrowBallManager:ThrowFromPlayerToEntity(targetEntity, options)
    if not targetEntity or not targetEntity.GetPosition then
        LOG.std(nil, "warn", "ThrowBallManager", "Invalid target entity for ThrowFromPlayerToEntity");
        return nil;
    end
    local player = GameLogic.GetPlayer();
    if not player then
        LOG.std(nil, "warn", "ThrowBallManager", "No player found for ThrowFromPlayerToEntity");
        return nil;
    end
    
    local startPos;
    
    if player and player.GetPosition then
        -- Player entity (already in real world coordinates)
        local x, y, z = player:GetPosition();
        startPos = {x = x, y = y + 1.5, z = z}; -- Add height offset
    else
        LOG.std(nil, "warn", "ThrowBallManager", "Invalid player parameter for ThrowFromPlayerToEntity");
        return nil;
    end
    
    -- Get target entity position (already in real world coordinates)
    local targetX, targetY, targetZ = targetEntity:GetPosition();
    local blockX, blockY, blockZ = BlockEngine:block(targetX, targetY, targetZ);
    LOG.std(nil, "info", "ThrowBallManager", "ThrowFromPlayerToEntity targetX: %s, targetY: %s, targetZ: %s, blockX: %s, blockY: %s, blockZ: %s", targetX, targetY, targetZ, blockX, blockY, blockZ);
    LOG.std(nil, "info", "ThrowBallManager", "ThrowFromPlayerToEntity startX: %s, startY: %s, startZ: %s", startPos.x, startPos.y, startPos.z);
    -- Use ThrowBallAdvanced with real world coordinates
    local throwOptions = {
        startPoint = startPos,
        endPoint = {x = targetX, y = targetY + 1, z = targetZ}, -- Add small height offset for target
        ballModel = options and options.ballModel or self.defaultSettings.ballModel,
        duration = options and options.duration or self.defaultSettings.duration,
        gravity = options and options.gravity or self.defaultSettings.gravity,
        maxDistance = options and options.maxDistance or self.defaultSettings.maxDistance,
        minDistance = options and options.minDistance or self.defaultSettings.minDistance,
        hitRadius = options and options.hitRadius or self.defaultSettings.hitRadius,
        onStart = options and options.onStart,
        onUpdate = options and options.onUpdate,
        onHit = options and options.onHit,
        onEnd = options and options.onEnd
    };
    
    return self:ThrowBallAdvanced(throwOptions);
end

-- Initialize on load
ThrowBallManager:Init();