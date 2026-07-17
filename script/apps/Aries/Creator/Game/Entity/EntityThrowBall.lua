--[[
Title: EntityThrowBall - Simplified Throw Ball Logic
Author(s): Generated based on original ThrowBall.lua
Date: 2025
Desc: A simplified throw ball entity for the new game framework
      Supports basic throwing mechanics: start, throwing, and end states
      Based on EntityLiveModel architecture

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityThrowBall.lua");
local EntityThrowBall = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityThrowBall");

-- Create and throw a ball
local entity = EntityThrowBall:Create({x=startX, y=startY, z=startZ});
entity:SetEndPoint(endX, endY, endZ);
entity:SetBallModel("model/07effect/v5/SnowBalloon/SnowBalloon_ball_anim.x");
entity:StartThrow();
------------------------------------------------------------
--]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityLiveModel.lua");
local EntityLiveModel = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityLiveModel");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");

local Entity = commonlib.inherit(EntityLiveModel, commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityThrowBall"));

-- Properties
Entity:Property({"startPoint", nil, "GetStartPoint", "SetStartPoint", auto=true});
Entity:Property({"endPoint", nil, "GetEndPoint", "SetEndPoint", auto=true});
Entity:Property({"throwDuration", 1.0, "GetThrowDuration", "SetThrowDuration", auto=true});
Entity:Property({"gravity", 0.025, "GetGravity", "SetGravity", auto=true});
Entity:Property({"maxDistance", 60, "GetMaxDistance", "SetMaxDistance", auto=true});
Entity:Property({"minDistance", 0.5, "GetMinDistance", "SetMinDistance", auto=true});
Entity:Property({"hitRadius", 0.2, "GetHitRadius", "SetHitRadius", auto=true});
Entity:Property({"ballModel", "model/07effect/v5/SnowBalloon/SnowBalloon_ball_anim.x", "GetBallModel", "SetBallModel", auto=true});
Entity:Property({"throwState", "idle", "GetThrowState", "SetThrowState", auto=true});

-- Signals
Entity:Signal("throwStarted");
Entity:Signal("throwUpdate", function(progress, x, y, z) end);
Entity:Signal("throwHit", function(hitX, hitY, hitZ) end);
Entity:Signal("throwEnded", function(x, y, z) end);

-- Class properties
Entity.class_name = "ThrowBall";
Entity.is_persistent = false;
Entity.is_regional = false;
Entity.framemove_interval = 1;

-- Register class
EntityManager.RegisterEntityClass(Entity.class_name, Entity);


function Entity:ctor()
    Entity._super.ctor(self);
    
    -- Throw state variables
    self.throwState = "idle"; -- "idle", "throwing", "hit", "ended"
    self.throwStartTime = 0;
    self.throwProgress = 0;
    self.initialPosition = nil;
    self.currentTrajectory = nil;
    
    -- Physics parameters
    self.throwDuration = 1.0;
    self.gravity = 0.025;
    self.maxDistance = 60;
    self.minDistance = 0.5;
    self.hitRadius = 0.2;
    
    -- Motion variables (similar to EntityMovable)
    self.motionX = 0;
    self.motionY = 0;
    self.motionZ = 0;
    
    -- Visual
    self.ballModel = "model/07effect/v5/SnowBalloon/SnowBalloon_ball_anim.x";
end

function Entity:init()
    if not Entity._super.init(self) then
        return
    end
    
    -- Set default model
    self:SetModelFile(self.ballModel);
    
    -- Initially hidden until throw starts
    self:SetVisible(false);
    
    return self;
end

-- Set the end point for throwing
function Entity:SetEndPoint(x, y, z)
    if type(x) == "table" then
        self.endPoint = {x = x.x or x[1], y = x.y or x[2], z = x.z or x[3]};
    else
        self.endPoint = {x = x, y = y, z = z};
    end
end

-- Get the end point
function Entity:GetEndPoint()
    return self.endPoint;
end

-- Set the start point for throwing
function Entity:SetStartPoint(x, y, z)
    if type(x) == "table" then
        self.startPoint = {x = x.x or x[1], y = x.y or x[2], z = x.z or x[3]};
    else
        self.startPoint = {x = x, y = y, z = z};
    end
end

-- Get the start point
function Entity:GetStartPoint()
    return self.startPoint;
end

-- Set the ball model file
function Entity:SetBallModel(modelFile)
    self.ballModel = modelFile;
    if self:GetInnerObject() then
        self:SetModelFile(modelFile);
    end
end

-- Get the ball model file
function Entity:GetBallModel()
    return self.ballModel;
end

-- Check if the throw is valid
function Entity:CanThrow()
    if not self.startPoint or not self.endPoint then
        return false;
    end
    
    local dx = self.endPoint.x - self.startPoint.x;
    local dy = self.endPoint.y - self.startPoint.y;
    local dz = self.endPoint.z - self.startPoint.z;
    
    local distance = math.sqrt(dx * dx + dz * dz);
    
    return distance >= self.minDistance and distance <= self.maxDistance;
end

-- Start the throwing process
function Entity:StartThrow()
    if not self:CanThrow() then
        LOG.std(nil, "warn", "EntityThrowBall", "Cannot throw: invalid start/end points or distance");
        return false;
    end
    
    -- Set initial state
    self.throwState = "throwing";
    self.throwStartTime = commonlib.TimerManager.GetCurrentTime();
    self.throwProgress = 0;
    
    -- Set position to start point
    self:SetPosition(self.startPoint.x, self.startPoint.y, self.startPoint.z);
    self:SetVisible(true);
    
    -- Calculate trajectory
    self:CalculateTrajectory();
    
    -- Enable high frequency frame move for smooth motion
    self:SetFrameMoveInterval(0.02);
    
    -- Fire start event
    self:throwStarted();
    
    LOG.std(nil, "info", "EntityThrowBall", "Throw started from (%f,%f,%f) to (%f,%f,%f)", 
        self.startPoint.x, self.startPoint.y, self.startPoint.z,
        self.endPoint.x, self.endPoint.y, self.endPoint.z);
    
    return true;
end

-- Calculate the trajectory parameters with realistic arc
function Entity:CalculateTrajectory()
    if not self.startPoint or not self.endPoint then
        return;
    end
    
    local dx = self.endPoint.x - self.startPoint.x;
    local dy = self.endPoint.y - self.startPoint.y;
    local dz = self.endPoint.z - self.startPoint.z;
    
    -- Calculate horizontal distance
    local horizontalDistance = math.sqrt(dx * dx + dz * dz);
    
    -- Calculate realistic arc height based on distance
    -- For short distances: lower arc, for long distances: higher arc
    local minArcHeight = 1.0;  -- Minimum arc height for very short throws
    local maxArcHeight = 8.0;  -- Maximum arc height for long throws
    local arcHeightFactor = math.min(horizontalDistance / self.maxDistance, 1.0);
    local arcHeight = minArcHeight + (maxArcHeight - minArcHeight) * arcHeightFactor;
    
    -- Calculate peak Y position (midpoint of trajectory)
    local startY = self.startPoint.y;
    local endY = self.endPoint.y;
    local peakY = math.max(startY, endY) + arcHeight;
    
    self.currentTrajectory = {
        startX = self.startPoint.x,
        startY = self.startPoint.y,
        startZ = self.startPoint.z,
        endX = self.endPoint.x,
        endY = self.endPoint.y,
        endZ = self.endPoint.z,
        peakY = peakY,
        arcHeight = arcHeight
    };
end

-- Update ball position during throw (time-based)
function Entity:UpdateThrowPosition(deltaTime)
    if self.throwState ~= "throwing" or not self.currentTrajectory then
        return;
    end
    
    -- Calculate progress based on elapsed time
    local currentTime = commonlib.TimerManager.GetCurrentTime();
    local elapsedTime = (currentTime - self.throwStartTime) / 1000; -- Convert to seconds
    local progress = elapsedTime / self.throwDuration;
    
    if progress >= 1.0 then
        -- Throw completed, set to target position
        progress = 1.0;
        self:SetPosition(self.currentTrajectory.endX, self.currentTrajectory.endY, self.currentTrajectory.endZ);
        self:CheckHit(self.currentTrajectory.endX, self.currentTrajectory.endY, self.currentTrajectory.endZ);
        self:throwUpdate(progress, self.currentTrajectory.endX, self.currentTrajectory.endY, self.currentTrajectory.endZ);
        self.throwProgress = progress;
        self:EndThrow();
        return;
    end
    
    -- Calculate position based on progress (0-1)
    local newX = self.currentTrajectory.startX + (self.currentTrajectory.endX - self.currentTrajectory.startX) * progress;
    local newZ = self.currentTrajectory.startZ + (self.currentTrajectory.endZ - self.currentTrajectory.startZ) * progress;
    
    -- Calculate Y position with parabolic arc
    local baseY = self.currentTrajectory.startY + (self.currentTrajectory.endY - self.currentTrajectory.startY) * progress;
    local arcProgress = 4 * progress * (1 - progress); -- Parabolic curve: peaks at 0.5
    local newY = baseY + self.currentTrajectory.arcHeight * arcProgress;
    
    -- Update position
    self:SetPosition(newX, newY, newZ);
    
    -- Check for hit
    self:CheckHit(newX, newY, newZ);
    
    -- Fire update event
    self:throwUpdate(progress, newX, newY, newZ);
    
    self.throwProgress = progress;
end

-- Check if the ball has hit the target
function Entity:CheckHit(x, y, z)
    if not self.endPoint then
        return false;
    end
    
    local dx = x - self.endPoint.x;
    local dy = y - self.endPoint.y;
    local dz = z - self.endPoint.z;
    
    local distance = math.sqrt(dx * dx + dy * dy + dz * dz);
    
    if distance <= self.hitRadius then
        self:OnHit(x, y, z);
        return true;
    end
    
    return false;
end

-- Handle hit event
function Entity:OnHit(x, y, z)
    if self.throwState == "throwing" then
        self.throwState = "hit";
        
        -- Fire hit event
        self:throwHit(x, y, z);
        
        LOG.std(nil, "info", "EntityThrowBall", "Ball hit target at (%f,%f,%f)", x, y, z);
        
        -- End throw after a short delay
        self:SetTimer(function()
            self:EndThrow();
        end, 0.1);
    end
end

-- End the throwing process
function Entity:EndThrow()
    if self.throwState == "ended" then
        return;
    end
    
    self.throwState = "ended";
    
    -- Fire end event
    local x,y,z = self:GetPosition()
    self:throwEnded(x,y,z);
    
    LOG.std(nil, "info", "EntityThrowBall", "Throw ended");
    
    -- Hide the ball
    self:SetVisible(false);
    
    -- Clean up after a delay
    self:SetTimer(function()
        self:Destroy();
    end, 0.5);
end

-- Frame move for updating throw state
function Entity:FrameMove(deltaTime)
    Entity._super.FrameMove(self, deltaTime);
    
    if self.throwState == "throwing" then
        self:UpdateThrowPosition(deltaTime);
    end
end

-- Reset the throw ball to idle state
function Entity:Reset()
    self.throwState = "idle";
    self.throwProgress = 0;
    self.throwStartTime = 0;
    self.currentTrajectory = nil;
    self:SetVisible(false);
    -- Restore normal frame move interval
    self:SetFrameMoveInterval(nil);
end

-- Get current throw state
function Entity:GetThrowState()
    return self.throwState;
end

-- Set throw state (internal use)
function Entity:SetThrowState(state)
    self.throwState = state;
end

-- Get throw progress (0-1)
function Entity:GetThrowProgress()
    return self.throwProgress or 0;
end

-- Destroy the entity
function Entity:Destroy()
    self:Reset();
    Entity._super.Destroy(self);
end

function Entity:SetTimer(func,delay)
    if not func then
        return;
    end
    if not delay then
        delay = 1
    end
    delay = delay * 1000
    commonlib.TimerManager.SetTimeout(func,delay);
end