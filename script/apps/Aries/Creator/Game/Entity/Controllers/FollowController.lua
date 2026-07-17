--[[
Title: Follow Controller
Author(s): 
Date: 2025/11/08
Desc: Handles entity follow behavior logic with three modes:
  - FollowCurrent: Strictly follows target entity's current position, facing, and animation, 
    while keeping a distance. If too close, moves away slightly to maintain distance.
    Falls down to ground when within follow stop distance.
  - FollowTrack: Keeps a 0.5 second history of target's positions. Entity follows the exact 
    positions from the history track. If too far from the last track position, smoothly 
    moves to it.
  - FollowOnTop: Simply sets the player to the top of the target at the target's physics height.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/Controllers/FollowController.lua");
local FollowController = commonlib.gettable("MyCompany.Aries.Game.EntityManager.Controllers.FollowController");
local controller = FollowController:new();
controller:Init(entity);
controller:SetMode("FollowTrack");  -- Optional: set mode (default is "FollowCurrent")
controller:SetFollowTarget(targetEntity);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL/RingBuffer.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/SelectionManager.lua");
local RingBuffer = commonlib.gettable("commonlib.RingBuffer");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local Cameras = commonlib.gettable("System.Scene.Cameras");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local FollowController = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.Controllers.FollowController"));

local InterpolateLinear = function(factor, from, to)
	return from * (1.0 - factor) + to * factor
end

function FollowController:ctor()
	-- Follow behavior parameters
	self.delayMs = 300
	self.posLerpFactor = 1; -- 0.04
    self.facingLerpFactor = 0.2
	self.followStopDistance = 2
	self.followTarget = nil
	self.isWithinStopDistance = false
	self.lastFrameTime = nil
	
	-- Follow mode: "FollowCurrent", "FollowTrack", or "FollowOnTop"
	self.mode = "FollowCurrent"
	
	-- FollowTrack mode parameters
	self.trackHistoryDuration = 500  -- 0.5 seconds in milliseconds
	self.trackHistory = RingBuffer:new()  -- RingBuffer of {time, x, y, z, facing, anim}
	self.trackSmoothFactor = 0.15  -- Smooth factor when too far
	self.trackMaxSize = 50  -- Maximum number of history entries (at 60fps, 60 frames = 1 second)
	self.trackWithinStopDistanceTime = nil  -- Time when entity first entered stop distance (used in both FollowCurrent and FollowTrack)
	self.trackFallDownDelay = 500  -- 500ms delay before falling down
end

-- Initialize the controller with an entity
-- @param entity: the entity that this controller manages
function FollowController:Init(entity)
	self.entity = entity
	return self
end

-- Set the target entity to follow
-- @param target: the entity to follow, if target is already followed by another entity, we will follow the followed by entity instead,
-- this will recursively find the tail entity, that is not followed by any, also prevent circular following.
function FollowController:SetFollowTarget(target)
	if(self.followTarget) then
		self.followTarget:Disconnect("valueChanged", self, FollowController.CameraRenderFrameMove)
		self.followTarget.followedBy = nil;
	end
    if(self.entity) then
        if(target == nil) then
            if(self.entity:HasFocus()) then
                self.entity:SetControlledExternally(false);
            end
        else
            self.entity:SetControlledExternally(true);
        end
    end
	
	-- Recursively find the tail entity that is not followed by any
	-- Also prevent circular following by tracking visited entities
	if(target) then
		local visited = {}
		visited[self.entity] = true  -- Mark current entity as visited to prevent following itself
		
		local tailEntity = target
		while(tailEntity and tailEntity.followedBy) do
			-- Check if we've visited this entity (circular reference)
			if(visited[tailEntity.followedBy]) then
				-- Circular following detected, stop here
				break
			end
			
			visited[tailEntity] = true
			tailEntity = tailEntity.followedBy
		end
		
		target = tailEntity
	end
	
	self.followTarget = target
    self.isWithinStopDistance = false
    
    -- Clear track history when changing target
    if self.mode == "FollowTrack" then
        self.trackHistory = RingBuffer:new()
        self.trackWithinStopDistanceTime = nil
    end
	if(target) then
		Cameras:GetCurrent():EnableCameraFrameMove(true)
		Cameras:GetCurrent():Connect("beforeRenderFrameMoved", self, self.CameraRenderFrameMove, "UniqueConnection")
		target:Connect("valueChanged", self, self.CameraRenderFrameMove, "UniqueConnection")
		self.followTarget.followedBy = self.entity;
	else
		Cameras:GetCurrent():Disconnect("beforeRenderFrameMoved", self, self.CameraRenderFrameMove)
	end
end

-- Set the follow mode
-- @param mode: "FollowCurrent", "FollowTrack", or "FollowOnTop"
function FollowController:SetMode(mode)
    if mode == "FollowCurrent" or mode == "FollowTrack" or mode == "FollowOnTop" then
        self.mode = mode
        -- Clear track history when switching to FollowTrack mode
        if mode == "FollowTrack" then
            self.trackHistory = RingBuffer:new()
            self.trackWithinStopDistanceTime = nil
        end
    end
	return self;
end

-- Get the current follow mode
function FollowController:GetMode()
    return self.mode
end

-- Get the current follow target
function FollowController:GetFollowTarget()
	return self.followTarget
end

-- Check if currently following a target
function FollowController:HasFollowTarget()
	return self.followTarget ~= nil
end

function FollowController:CameraRenderFrameMove()
	if not self.followTarget or not self.entity then
		return
	end
    if not self.followTarget:IsValid() or not self.entity:IsValid() then
        self:SetFollowTarget(nil);
        return
    end

	-- tricky: this makes sure the positions are final before rendering. 
	-- Calculate time delta
	local currentTime = commonlib.TimerManager.GetCurrentTime()
	local timeDelta = 0
	if self.lastFrameTime then
		timeDelta = currentTime - self.lastFrameTime
	end
	self.lastFrameTime = currentTime
	
	-- Route to appropriate mode handler
	if self.mode == "FollowTrack" then
		self:FrameMoveFollowTrack(currentTime, timeDelta)
	elseif self.mode == "FollowOnTop" then
		self:FrameMoveFollowOnTop(currentTime, timeDelta)
	else
		self:FrameMoveFollowCurrent(currentTime, timeDelta)
	end
end

-- Update entity position and animation based on follow target
function FollowController:FrameMove()
end

-- Update entity using FollowCurrent mode (original behavior)
function FollowController:FrameMoveFollowCurrent(currentTime, timeDelta)
	-- Get target state
	local objTarget = self.followTarget:GetInnerObject()
	if not objTarget then
		return
	end
	local tanim = self.followTarget:GetAnimId()
	local tx, ty, tz = objTarget:GetPosition()
	local tfacing = objTarget:GetFacing() or 0;

	-- Update position with interpolation if beyond threshold
	local cx, cy, cz = self.entity:GetPosition()
	local dx, dy, dz = (tx - cx), (ty - cy), (tz - cz)
	local distSq = dx*dx + dy*dy + dz*dz
	local thresholdSq = self.followStopDistance * self.followStopDistance
	local tooCloseThresholdSq = thresholdSq / 4;
	
	local curAnim = self.entity:GetAnimId()
	local isPlayingExternalAnim = curAnim == tanim and tanim and tanim > 1000;

	if(not isPlayingExternalAnim) then
		if distSq < tooCloseThresholdSq then
			-- Too close, move away 
			local moveAwayDist = math.min(0.1, self.followStopDistance / 2)
			-- Calculate direction from target to entity
			local dirX = cx - tx
			local dirZ = cz - tz
			local dirLen = math.sqrt(dirX * dirX + dirZ * dirZ)
			if dirLen > 0.001 then
				-- Normalize and move away from target
				dirX = dirX / dirLen
				dirZ = dirZ / dirLen
				self.entity:SetPosition(cx + dirX * moveAwayDist, cy, cz + dirZ * moveAwayDist)
			else
				-- If exactly at the same position, just move along X axis
				self.entity:SetPosition(cx + moveAwayDist, cy, cz)
			end
			self.trackWithinStopDistanceTime = nil
			self.isWithinStopDistance = false
		elseif distSq > (thresholdSq + 0.01) then
			-- Move directly to followStopDistance
			local currentDist = math.sqrt(distSq)
			local targetDist = self.followStopDistance
			
			-- Calculate position at followStopDistance from target
			local scale = targetDist / currentDist
			local nx = tx - dx * scale
			local ny = ty - dy * scale
			local nz = tz - dz * scale
			
			self.entity:SetPosition(nx, ny, nz)
			self.trackWithinStopDistanceTime = nil
			self.isWithinStopDistance = false
		else
			-- Within stop distance - track time and possibly fall down
			if not self.trackWithinStopDistanceTime then
				self.trackWithinStopDistanceTime = currentTime
			end
			-- Check if we've been within stop distance for the delay duration
			if (currentTime - self.trackWithinStopDistanceTime) >= self.trackFallDownDelay then
				-- Fall down after delay
				if not self.isWithinStopDistance then
					self:FallDown()
					self.isWithinStopDistance = true
				end
			end
		end
		
		-- Update facing
		if tfacing then
			local currentFacing = self.entity:GetFacing()
			if currentFacing == tfacing then
				-- Skip update if facing is already equal
			else
				local facingDiff = math.abs(tfacing - currentFacing)
				local epsilon = 0.01
				if facingDiff < epsilon or (tanim or 0) > 1000 then
					-- Set accurate facing when difference is negligible or we are about to play an external animation
					self.entity:SetFacing(tfacing)
				else
					local newFacing = InterpolateLinear(self.facingLerpFactor, currentFacing, tfacing)
					self.entity:SetFacing(newFacing)
				end
			end
		end
	end

	-- Update animation
	if tanim then
		if curAnim ~= tanim then
			self.entity:SetAnimId(tanim)
			self.entity:SetAnimation(tanim)
			local isControlledExternally = self.entity:IsControlledExternally()
			if not isControlledExternally then
				self.entity:SetControlledExternally(true)
			end
		end
	end
end

-- Update entity using FollowTrack mode (history-based tracking)
function FollowController:FrameMoveFollowTrack(currentTime, timeDelta)
	-- Get current target state
	local objTarget = self.followTarget:GetInnerObject()
	if not objTarget then
		return
	end

	local tx, ty, tz = objTarget:GetPosition()
	local tfacing = objTarget:GetFacing() or 0;
	local tanim = self.followTarget:GetAnimId()
	
	-- Reuse or create track entry for RingBuffer
	local trackEntry
	local historySize = self.trackHistory:size()
	
	-- If buffer is full, reuse the oldest entry by cycling
	if historySize >= self.trackMaxSize then
		trackEntry = self.trackHistory:next()  -- Get next (oldest) entry and move pointer
	else
		-- Create new entry
		trackEntry = {}
		self.trackHistory:add(trackEntry)
	end
	
	-- Update the entry with current target data
	trackEntry.time = currentTime
	trackEntry.x = tx
	trackEntry.y = ty
	trackEntry.z = tz
	trackEntry.facing = tfacing
	trackEntry.anim = tanim
	
	-- Get current entity position for distance check
	local cx, cy, cz = self.entity:GetPosition()
	
	local thresholdSq = self.followStopDistance * self.followStopDistance

	-- Look back in history from 0, -1, -2, ... until we find an entry older than 0.5 seconds
	local targetTrack = nil
	for i = 0, -(historySize - 1), -1 do
		local entry = self.trackHistory:get(i)
		if entry and entry.time then
			local age = currentTime - entry.time
			
			-- Found suitable entry if old enough
			if age >= self.trackHistoryDuration then
				targetTrack = entry
				break
			end
		end
	end
	
	if targetTrack then
		-- Calculate distance to target track position
		local dx, dy, dz = (targetTrack.x - cx), (targetTrack.y - cy), (targetTrack.z - cz)
		local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
		local distSq = dx*dx + dy*dy + dz*dz
		
		local tooCloseThresholdSq = thresholdSq / 4
		
		-- Check if too close to target track position
		if( dist <= self.followStopDistance and self.lastTrackX) then
			-- Move to lastTrackY position first (only Y axis)
			-- Check if we're already at lastTrackY position within epsilon error
			local lastDy = self.lastTrackY - cy
			local epsilon = 0.005
			if math.abs(lastDy) < epsilon then
				-- Already at lastTrackY position, set exact position and clear lastTrackX
				self.entity:SetPosition(cx, self.lastTrackY, cz)
				self.lastTrackX = nil
				self.lastTrackY = nil
				self.lastTrackZ = nil
				self.lastTrackFacing = nil
			else
				-- Move towards lastTrackY position (only interpolate Y)
				local ny = InterpolateLinear(self.trackSmoothFactor, cy, self.lastTrackY)
				self.entity:SetPosition(cx, ny, cz)
			end
			
		elseif distSq < tooCloseThresholdSq then
			-- Too close, move away
			local moveAwayDist = math.min(0.1, self.followStopDistance / 2)
			-- Calculate direction from target to entity
			local dirX = cx - targetTrack.x
			local dirZ = cz - targetTrack.z
			local dirLen = math.sqrt(dirX * dirX + dirZ * dirZ)
			if dirLen > 0.001 then
				-- Normalize and move away from target
				dirX = dirX / dirLen
				dirZ = dirZ / dirLen
				self.entity:SetPosition(cx + dirX * moveAwayDist, cy, cz + dirZ * moveAwayDist)
			else
				-- If exactly at the same position, just move along X axis
				self.entity:SetPosition(cx + moveAwayDist, cy, cz)
			end
			self.trackWithinStopDistanceTime = nil
			self.isWithinStopDistance = false
		-- Check if within stop distance
		elseif dist <= self.followStopDistance then
			-- Within stop distance - track time and possibly fall down
			if not self.trackWithinStopDistanceTime then
				self.trackWithinStopDistanceTime = currentTime
			end
			
			-- Check if we've been within stop distance for 1 second
			if (currentTime - self.trackWithinStopDistanceTime) >= self.trackFallDownDelay then
				-- Fall down after 1 second
				if not self.isWithinStopDistance then
					self:FallDown()
					self.isWithinStopDistance = true
				end
			end
		else
			-- Outside stop distance - reset timer and move
			self.trackWithinStopDistanceTime = nil
			self.isWithinStopDistance = false
			self.lastTrackX = targetTrack.x
			self.lastTrackY = targetTrack.y
			self.lastTrackZ = targetTrack.z
			self.lastTrackFacing = targetTrack.facing

			local nx = InterpolateLinear(self.trackSmoothFactor, cx, targetTrack.x)
			local ny = InterpolateLinear(self.trackSmoothFactor, cy, targetTrack.y)
			local nz = InterpolateLinear(self.trackSmoothFactor, cz, targetTrack.z)
			self.entity:SetPosition(nx, ny, nz)
		end
		
		-- Update facing
		local tFacing = self.lastTrackFacing or targetTrack.facing
		if tFacing then
			local currentFacing = self.entity:GetFacing()
			if currentFacing ~= tFacing then
				local facingDiff = math.abs(tFacing - currentFacing)
				local epsilon = 0.01
				if facingDiff < epsilon then
					self.entity:SetFacing(tFacing)
				else
					local newFacing = InterpolateLinear(self.facingLerpFactor, currentFacing, tFacing)
					self.entity:SetFacing(newFacing)
				end
			end
		end
		
		-- Update animation
		if targetTrack.anim then
			local curAnim = self.entity:GetAnimId()
			if curAnim ~= targetTrack.anim then
				self.entity:SetAnimId(targetTrack.anim)
				self.entity:SetAnimation(targetTrack.anim)
			end
		end
	else
		-- No suitable track entry found, we will just copy facing and animation from target
		-- without changing position
		-- Update facing
		if tfacing then
			local currentFacing = self.entity:GetFacing()
			if currentFacing ~= tfacing then
				local facingDiff = math.abs(tfacing - currentFacing)
				local epsilon = 0.01
				if facingDiff < epsilon then
					self.entity:SetFacing(tfacing)
				else
					local newFacing = InterpolateLinear(self.facingLerpFactor, currentFacing, tfacing)
					self.entity:SetFacing(newFacing)
				end
			end
		end
		-- Update animation
		if tanim then
			local curAnim = self.entity:GetAnimId()
			if curAnim ~= tanim then
				self.entity:SetAnimId(tanim)
				self.entity:SetAnimation(tanim)
			end
		end
	end
end

-- Update entity using FollowOnTop mode (position on top of target at physics height)
function FollowController:FrameMoveFollowOnTop(currentTime, timeDelta)
	-- Get current target state
	local objTarget = self.followTarget:GetInnerObject()
	if not objTarget then
		return
	end

	local tx, ty, tz = objTarget:GetPosition()
	local tfacing = objTarget:GetFacing() or 0
	local tanim = self.followTarget:GetAnimId()
	
	-- Get target's physics height
	local physicsHeight = self.followTarget:GetPhysicsHeight() or 2
	
	-- Set entity position to top of target
	self.entity:SetPosition(tx, ty + physicsHeight, tz)
	self.entity:SetFacing(tfacing)
	
	-- Update animation
	if tanim then
		local curAnim = self.entity:GetAnimId()
		if curAnim ~= tanim then
			self.entity:SetAnimId(tanim)
			self.entity:SetAnimation(tanim)
		end
	end
end

function FollowController:FallDown()
    local entity = self.entity
    if(not entity or not self.followTarget) then return end
	
	local x, y, z = entity:GetPosition();
	
	-- Use SelectionManager:RayPicking to cast a ray downward
	local dist, result = SelectionManager:RayPicking(x, y + 1.1, z, 0, -1, 0, self.followStopDistance + 1.1);
	
	local min_y;
	if(dist) then
		-- Hit something with the ray, use the hit point's Y coordinate
		min_y = y + 1.1 - dist;
	end

	if(min_y and y ~= min_y) then
		-- Check if the position after falling down is still within followStopDistance
		local tx, ty, tz = self.followTarget:GetPosition()
		local dx, dy, dz = (tx - x), (ty - min_y), (tz - z)
		local distSq = dx*dx + dy*dy + dz*dz
		local thresholdSq = self.followStopDistance * self.followStopDistance
		
		if distSq <= thresholdSq then
			y = min_y;
			entity:SetPosition(x, y, z);
		end
	end
end

return FollowController;
