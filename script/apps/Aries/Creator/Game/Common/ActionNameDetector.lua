--[[
Title: Action name detector
Author(s): LiXizhi
Date: 2025/9/10
Desc: 
Use a global command `/show actionbutton` to enable; this is enabled by default.
1.	Automatically display [Interact: actionname] for the nearest NPC within 4 meters of the main character that has both an onclick event and an actionname static property.
2.	If not on the mobile version, add a shortcut key hint (T) at the end: Interact: Dialogue (T)
3.	entity:SetStaticTag("actionname", "Dialogue"): You can set the interaction text; if not set, nothing is displayed. The text should use pink color with shadow.
4.	On the mobile version, display an [Interact] button in the right area, equivalent to onclick.
5.  Action names can be separated by comma (,) to create multiple markers for the same entity, or by pipe (|) to create multiple buttons within a single marker.

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ActionNameDetector.lua");
local ActionNameDetector = commonlib.gettable("MyCompany.Aries.Game.Common.ActionNameDetector");
-- manual mode
ActionNameDetector:UpdateDetection(GameLogic.GetPlayer());
ActionNameDetector:TriggerCurrentAction()

-- auto detect mode
ActionNameDetector:Connect("actionChanged", function(actionname, entity)
	GameLogic.AddBBS("action", actionname);
end);
ActionNameDetector:SetEnabled(true);
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager")
local Cameras = commonlib.gettable("System.Scene.Cameras");
local ActionNameDetector = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Common.ActionNameDetector"))
ActionNameDetector:Signal("actionChanged", function(actionname, entity) end); -- if there is no actionname, then actionname is nil. entity may also be nil.
ActionNameDetector:Signal("actionTriggered", function(entity, actionIndex, actionName) end);
ActionNameDetector:Property({"Enabled", false, "IsEnabled", "SetEnabled"});
ActionNameDetector:Property({"align", "bottom", "GetAlignment", "SetAlignment", auto=true}); -- "top" or "bottom"
ActionNameDetector:Property({"show3DMarker", true, "IsShow3DMarker", "SetShow3DMarker", auto=true});
ActionNameDetector:Property({"updateInterval", 250}); -- in milliseconds
ActionNameDetector:Property({"positionUpdateInterval", 10}); -- in milliseconds
ActionNameDetector:Property({"DetectRadius", 5, auto=true});
ActionNameDetector:Property({"DetectRadiusY", 1, auto=true});
ActionNameDetector:Property({"MaxMarkers", 5, auto=true}); -- Maximum number of markers to display
ActionNameDetector:Property({"minMarkerSpacing", 15, auto=true}); -- Minimum pixel spacing between markers

function ActionNameDetector:ctor()
	self.updateTimer = nil
	self.positionTimer = nil
	self.currentEntity = nil
	self.currentActionName = nil
	self.actionNames = nil -- Cached split action names
	-- Multiple entities support
	self.entities = {} -- Array of {entity, actionName, distance}
	self.markers = {} -- Array of marker UI objects
	-- Position smoothing variables
	self.lastMarkerPos = {x = 0, y = 0}
	self.targetMarkerPos = {x = 0, y = 0}
	--self.smoothingFactor = 0.2 -- How much to interpolate per frame (0.0 = no movement, 1.0 = instant)
	self.smoothingFactor = 1;
	-- Track which entity+action combinations were visible in the previous frame
	self.visibleEntityActions = {} -- Set of entity:actionIndex:actionName keys
    self:StaticInit();
end

function ActionNameDetector:StaticInit()
	GameLogic:Connect("WorldLoaded", self, self.OnWorldLoad, "UniqueConnection");
	GameLogic:Connect("WorldUnloaded", self, self.OnWorldUnLoaded, "UniqueConnection");
end

function ActionNameDetector:OnWorldLoad()
	if self:IsEnabled() then
		self:StartDetection()
	end
end

function ActionNameDetector:OnWorldUnLoaded()
	self:StopDetection()
	self:StopPositionUpdates()
	-- Clean up popup animation timer
	if self.popupAnimTimer then
		self.popupAnimTimer:Change()
		self.popupAnimTimer = nil
	end
	self.currentEntity = nil
	self.currentActionName = nil
	self.entities = {}
	self.visibleEntityActions = {}
end

function ActionNameDetector:SetEnabled(bEnable)
	self.Enabled = bEnable
	
	if bEnable then
        self:StartDetection()
	else
		self:StopDetection()
	end
end

-- Start the detection timer
function ActionNameDetector:StartDetection()
	self.updateTimer = self.updateTimer or commonlib.Timer:new({
		callbackFunc = function(timer)
            if self:IsEnabled() then
			    self:UpdateDetection()
            end
		end
	})
	self.updateTimer:Change(0, self.updateInterval)
end

-- Stop the detection timer
function ActionNameDetector:StopDetection()
	if self.updateTimer then
		self.updateTimer:Change()
		self.updateTimer = nil
	end
	
	self:StopPositionUpdates()
	
	-- Clear current state and hide UI
	self:SetCurrentActions({})
end

-- Start the position update timer
function ActionNameDetector:StartPositionUpdates()
	if not self.positionTimer then
		self.positionTimer = commonlib.Timer:new({
			callbackFunc = function(timer)
				self:UpdateMarkerPosition()
			end
		})
	end
	self.positionTimer:Change(0, self.positionUpdateInterval)
	--Cameras:GetCurrent():EnableCameraFrameMove(true)
	--Cameras:GetCurrent():Connect("beforeRenderFrameMoved", self, self.UpdateMarkerPosition, "UniqueConnection")
end

-- Stop the position update timer
function ActionNameDetector:StopPositionUpdates()
	if self.positionTimer then
		self.positionTimer:Change()
		self.positionTimer = nil
	end
	-- Cameras:GetCurrent():Disconnect("beforeRenderFrameMoved", self, self.UpdateMarkerPosition)
end

function ActionNameDetector:IsEnabled()
	return self.Enabled
end

-- Main detection logic called every frame
-- @param player: optional, default to main player
function ActionNameDetector:UpdateDetection(player)
	player = player or EntityManager.GetFocus()
	if not player then
		return
	end
	
	-- Find multiple nearby interactable entities (up to MaxMarkers)
	local nearbyEntities = self:FindNearbyInteractableEntities(player)
	
	-- Update current state if changed
	if self:HasEntitiesChanged(nearbyEntities) then
		self:SetCurrentActions(nearbyEntities)
	end
end

local search_params = {
    category = "searchable",
    filterFunc = function(entity)
        if(entity:GetActionName() and not entity:IsPlayer()) then
            return true;
        end
        return false;
    end,
};

local search_other_player_params = {
    category = "e",
    filterFunc = function(entity)
		if(entity:IsPlayer() and entity:GetActionName()) then
            return true;
        end
        return false;
    end,
};

-- Find nearby interactable entities (NPCs and players) sorted by distance
function ActionNameDetector:FindNearbyInteractableEntities(player)
	if not player then
		return {}
	end
	
	local playerX, playerY, playerZ = player:GetPosition()
	local radius = self:GetDetectRadius()
	local radiusY = self:GetDetectRadiusY()
	local maxMarkers = self:GetMaxMarkers()
	
	local results = {}
	
	-- Helper function to process entities and add to results
	local function processEntities(entities)
		if entities and #entities > 0 then
			for _, entity in ipairs(entities) do
				-- Skip entities that are being dragged
				if entity:IsVisible() and player~=entity and not (entity.IsDragging and entity:IsDragging()) then
					-- Split by comma first to get action names
					local actionName = entity:GetActionName()
					
					-- Split by comma to create multiple markers for one entity
					if actionName and actionName:find(",") then
						local actionIndex = 0
						for name in string.gmatch(actionName, "[^,]+") do
							actionIndex = actionIndex + 1
							-- Use action point position for distance calculation
							local entityX, entityY, entityZ = entity:GetActionPoint(actionIndex)
							if entityX and entityY and entityZ then
								local distance = math.sqrt((entityX - playerX)^2 + (entityY - playerY)^2 + (entityZ - playerZ)^2)
								local actionRadius = entity:GetActionRadius(actionIndex)
								if actionRadius and distance <= actionRadius then
									table.insert(results, {
										entity = entity,
										actionName = name,
										distance = distance,
										actionIndex = actionIndex  -- Track which action this is
									})
								end
							end
						end
					else
						-- Use action point position for distance calculation
						local entityX, entityY, entityZ = entity:GetActionPoint(1)
						if entityX and entityY and entityZ then
							local distance = math.sqrt((entityX - playerX)^2 + (entityY - playerY)^2 + (entityZ - playerZ)^2)
							local actionRadius = entity:GetActionRadius(1)
							if actionRadius and distance <= actionRadius then
								table.insert(results, {
									entity = entity,
									actionName = actionName,
									distance = distance,
									actionIndex = 1
								})
							end
						end
					end
				end
			end
		end
	end
	
	-- Search for NPCs
	search_params.x, search_params.y, search_params.z = player:GetBlockPos()
	search_params.r = radius
	search_params.ry = radiusY
	local npcEntities = EntityManager.FindEntities(search_params)
	processEntities(npcEntities)
	
	-- Search for other players
	search_other_player_params.x, search_other_player_params.y, search_other_player_params.z = player:GetBlockPos()
	search_other_player_params.r = radius
	search_other_player_params.ry = radiusY
	local playerEntities = EntityManager.FindEntities(search_other_player_params)
	processEntities(playerEntities)
	
	-- Sort by distance (closest first)
	table.sort(results, function(a, b)
		return a.distance < b.distance
	end)
	
	-- Limit to max markers
	if #results > maxMarkers then
		commonlib.resize(results, maxMarkers)
	end
	
	return results
end

-- Check if the entities list has changed
function ActionNameDetector:HasEntitiesChanged(newEntities)
	if #newEntities ~= #self.entities then
		return true
	end
	
	for i, newEntry in ipairs(newEntities) do
		local oldEntry = self.entities[i]
		if not oldEntry or oldEntry.entity ~= newEntry.entity or 
		   oldEntry.actionName ~= newEntry.actionName or 
		   oldEntry.actionIndex ~= newEntry.actionIndex then
			return true
		end
	end
	
	return false
end

-- Set the current actions and update UI
function ActionNameDetector:SetCurrentActions(entities)
	-- Store old state for comparison
	local hadEntities = #self.entities > 0
	
	-- Update entities list
	self.entities = entities
	
	-- Update currentEntity to be the closest (first in list) for backward compatibility
	if #entities > 0 then
		self.currentEntity = entities[1].entity
		self.currentActionName = entities[1].actionName
		
		-- Cache split action names for the first entity
		if self.currentActionName then
			self.actionNames = {}
			for name in string.gmatch(self.currentActionName, "[^|]+") do
				table.insert(self.actionNames, name)
			end
		else
			self.actionNames = nil
		end
	else
		self.currentEntity = nil
		self.currentActionName = nil
		self.actionNames = nil
	end
	
	-- Fire signal for the closest entity (backward compatibility)
	self:actionChanged(self.currentActionName, self.currentEntity)
	
	-- Set alignment based on first entity type
	if self.currentEntity and self.currentEntity:isa(EntityManager.EntityPlayer) then
		self:SetAlignment("bottom")
	else
		-- self:SetAlignment("top")
	end
	
	-- Only update markers if 3D marker is enabled
	if self:IsShow3DMarker() then
		self:Update3DMarkers()
		
		-- Start or stop position updates based on whether we have entities
		if #entities > 0 then
			self:StartPositionUpdates()
		else
			self:StopPositionUpdates()
		end
	else
		-- If 3D marker is disabled, stop position updates
		self:StopPositionUpdates()
	end
end

-- Update only the marker positions (called by high-resolution timer)
function ActionNameDetector:UpdateMarkerPosition()
	-- Only update position if 3D marker is enabled
	if not self:IsShow3DMarker() then
		return
	end
	
	if #self.entities == 0 then
		return
	end
	
	-- Update position for each marker
	for i, entityData in ipairs(self.entities) do
		local marker = self.markers[i]
		if marker and marker.visible and marker:IsValid() then
			local entity = entityData.entity
			local x, y, z = entity:GetActionPoint(entityData.actionIndex)
			if entity and entity:IsValid() and x and y and z then
				local screen_pos = marker.screen_pos or {x=0, y=0}
				marker.screen_pos = screen_pos
				screen_pos.x = -9999;
				screen_pos.y = -9999;
				ParaScene.GetScreenPosFrom3DPoint(x, y, z, screen_pos)
				
				-- Calculate target position
				local targetX = math.floor(screen_pos.x - (marker.width / 2))
				local targetY
				if self.align == "top" then
					targetY = screen_pos.y - marker.height
				else
					targetY = screen_pos.y
				end
				local depth = screen_pos.z;
				
				-- Initialize last position if this is the first update
				if not marker.lastPos then
					marker.lastPos = {x = targetX, y = targetY}
				end
				
				-- Smoothly interpolate towards target position
				if(screen_pos.x == -9999) then
					marker.lastPos.x = targetX
					marker.lastPos.y = targetY
				else
					marker.lastPos.x = self:InterpolateLinear(self.smoothingFactor, marker.lastPos.x, targetX)
					marker.lastPos.y = self:InterpolateLinear(self.smoothingFactor, marker.lastPos.y, targetY)
				end
				
				-- Apply the smoothed position to the marker
				marker.x = marker.lastPos.x
				marker.y = marker.lastPos.y
			else
				-- Entity lost its action point, trigger update
				self:SetCurrentActions({})
				return
			end
		end
	end
	
	-- Check for overlaps and adjust positions
	self:AdjustOverlappingMarkers()
end

-- Adjust marker positions to prevent overlapping
function ActionNameDetector:AdjustOverlappingMarkers()
	local minSpacing = self.minMarkerSpacing
	
	for i = 1, #self.markers do
		local marker1 = self.markers[i]
		if marker1 and marker1.visible and marker1:IsValid() then
			for j = i + 1, #self.markers do
				local marker2 = self.markers[j]
				if marker2 and marker2.visible and marker2:IsValid() then
					-- Check if markers overlap
					local dx = marker2.x - marker1.x
					local dy = marker2.y - marker1.y
					local distance = math.sqrt(dx * dx + dy * dy)
					local minDistance = (marker1.width + marker2.width) / 2 + minSpacing
					
					if distance < minDistance and distance > 0 then
						-- Push marker2 away from marker1
						local pushDistance = (minDistance - distance) / 2
						local angle = math.atan2(dy, dx)
						marker2.x = marker2.x + math.cos(angle) * pushDistance
						marker2.y = marker2.y + math.sin(angle) * pushDistance
					end
				end
			end
		end
	end
end

function ActionNameDetector:SetAlignment(align)
	if self.align == align then
		return
	end
	self.align = align
	
	-- Update all markers
	for _, marker in ipairs(self.markers) do
		if marker and marker:IsValid() then
			local bg = marker:GetChild("action_bg")
			if bg then
				if self.align == "top" then
					bg:Reposition("_ctb", 0, 0, 12, 8)
					bg.background = "Texture/blocks/icons/arrow_down.png;12 28 40 31"
				else
					bg:Reposition("_ctt", 0, 0, 12, 8)
					bg.background = "Texture/blocks/icons/arrow_up.png;12 0 40 31"
				end
			end
			
			if marker.actionButtons then
				for i = 1, #marker.actionButtons do
					local actionBtn = marker.actionButtons[i]
					if actionBtn and actionBtn:IsValid() then
						local yOffset = self.align == "top" and 0 or 12
						actionBtn.y = yOffset
					end
				end
			end
		end
	end
end

function ActionNameDetector:Update3DMarkers()
	-- Only update markers if 3D marker is enabled
	if not self:IsShow3DMarker() then
		-- Hide all markers if 3D marker is disabled
		for _, marker in ipairs(self.markers) do
			if marker and marker:IsValid() then
				marker.visible = false
			end
		end
		self.visibleEntityActions = {}
		return
	end
	
	-- Track which entity+action combinations are visible in this frame
	local currentVisibleEntityActions = {}
	
	-- Update or create markers for each entity
	for i, entityData in ipairs(self.entities) do
		local entity = entityData.entity
		local actionName = entityData.actionName
		local actionIndex = entityData.actionIndex
		local isClosest = (i == 1) -- First entity is closest
		
		if entity and actionName and entity:IsValid() then
			-- Create a unique key for this entity+action combination
			local entityActionKey = tostring(entity.name) .. ":" .. tostring(actionIndex)
			currentVisibleEntityActions[entityActionKey] = true
			
			-- Check if this specific entity+action was visible in the last frame
			local wasVisibleLastFrame = self.visibleEntityActions[entityActionKey] == true
			
			-- Parse action names
			local actionNames = {}
			for name in string.gmatch(actionName, "[^|]+") do
				table.insert(actionNames, name)
			end
			
			-- Get or create marker
			local marker = self.markers[i]
			if not marker or not marker:IsValid() then
				-- Create container for the action UI
				marker = ParaUI.CreateUIObject("container", "action_container_" .. i, "_lt", 0, 0, 100, 48)
				marker.background = ""
				marker.zorder = -100
				marker.click_through = true
				
				-- Create background button for the container
				local bg
				if self.align == "top" then
					bg = ParaUI.CreateUIObject("button", "action_bg", "_ctb", 0, 0, 12, 8)
					bg.background = "Texture/blocks/icons/arrow_down.png;12 28 40 31"
				else
					bg = ParaUI.CreateUIObject("button", "action_bg", "_ctt", 0, 0, 12, 8)
					bg.background = "Texture/blocks/icons/arrow_up.png;12 0 40 31"
				end
				bg.enabled = false
				_guihelper.SetUIColor(bg, "#ffff00") -- fully transparent
				marker:AddChild(bg)
				
				marker:AttachToRoot()
				
				-- Initialize action buttons array for this marker
				marker.actionButtons = {}
				
				self.markers[i] = marker
			end
			
			-- Determine text color based on distance (closest is pink, others are grey)
			local textColor = isClosest and "#ff00ff" or "#88888880"
			
			-- Reuse or create buttons for each action name
			local totalWidth = 0
			local buttonSpacing = 2
			local xOffset = 0
			local yOffset = self.align == "top" and 0 or 12
			
			for j, name in ipairs(actionNames) do
				local actionBtn = marker.actionButtons[j]
				
				-- Create button if it doesn't exist
				if not actionBtn or not actionBtn:IsValid() then
					actionBtn = ParaUI.CreateUIObject("button", "b" .. j, "_lt", 0, yOffset, 36, 36)
					actionBtn.font = "System;14;bold"
					actionBtn.background = "Texture/Aries/Creator/keepwork/Mobile/icon/caozuoqiu_56x56_32bits.png#0 0 56 56:18 18 18 18"
					
					-- Store the marker index and action name index for the click handler
					local markerIndex = i
					local actionIndex = j
					actionBtn:SetScript("onclick", function()
						self:TriggerActionForEntity(markerIndex, actionIndex)
					end)
					
					marker:AddChild(actionBtn)
					marker.actionButtons[j] = actionBtn
				end
				
				-- Update button properties
				local text = name
				local btnWidth = math.max(36, _guihelper.GetTextWidth(text, "System;14;bold") + 32)
				actionBtn.width = btnWidth
				actionBtn.text = text
				actionBtn.x = xOffset
				actionBtn.y = yOffset
				actionBtn.visible = true
				_guihelper.SetFontColor(actionBtn, textColor)
				
				xOffset = xOffset + btnWidth + buttonSpacing
				totalWidth = xOffset - buttonSpacing
			end
			
			-- Hide unused buttons
			if marker.actionButtons then
				for j = #actionNames + 1, #marker.actionButtons do
					if marker.actionButtons[j] and marker.actionButtons[j]:IsValid() then
						marker.actionButtons[j].visible = false
					end
				end
			end
			
			-- Update marker width to fit all buttons
			marker.width = math.max(36, totalWidth)
			
			-- If this entity+action was NOT visible last frame, initialize scale to 0 before showing
			if not wasVisibleLastFrame then
				marker.scalingx = 0
				marker.scalingy = 0
				marker:ApplyAnim()
			end
			
			marker.visible = true
			
			-- Play pop-up animation only if this specific entity+action was not visible last frame
			if not wasVisibleLastFrame then
				self:PlayPopupAnimation(marker)
			end
			
			-- Reset position smoothing animation if this is a new entity+action
			if not wasVisibleLastFrame then
				marker.lastPos = nil
			end
		end
	end
	
	-- Hide unused markers
	for i = #self.entities + 1, #self.markers do
		local marker = self.markers[i]
		if marker and marker:IsValid() then
			marker.visible = false
		end
	end
	
	-- Update the visible entity actions for the next frame
	self.visibleEntityActions = currentVisibleEntityActions
	
	self:UpdateMarkerPosition()
end

-- Linear interpolation function for smooth position transitions
function ActionNameDetector:InterpolateLinear(factor, from, to)
	return from * (1.0 - factor) + to * factor
end

-- Play a pop-up animation when a marker becomes visible
function ActionNameDetector:PlayPopupAnimation(marker)
	if not marker or not marker:IsValid() then
		return
	end
	
	-- Cancel any existing animation timer for this marker
	if marker.popupAnimTimer then
		marker.popupAnimTimer:Change()
		marker.popupAnimTimer = nil
	end
	
	-- Animation parameters
	local startScale = 0
	local endScale = 1.0 -- End at 100% size
	local duration = 400 -- Animation duration in milliseconds
	local startTime = commonlib.TimerManager.GetCurrentTime()
	
	-- Create animation timer
	marker.popupAnimTimer = commonlib.Timer:new({
		callbackFunc = function(timer)
			if not marker or not marker:IsValid() then
				timer:Change()
				return
			end
			
			local currentTime = commonlib.TimerManager.GetCurrentTime()
			local elapsed = currentTime - startTime
			local progress = math.min(1.0, elapsed / duration)
			
			-- Easing function (ease out cubic for smooth deceleration)
			local easedProgress = 1 - math.pow(1 - progress, 3)
			
			-- Calculate current scale
			local currentScale = startScale + (endScale - startScale) * easedProgress
			
			-- Apply scaling
			marker.scalingx = currentScale
			marker.scalingy = currentScale
			marker:ApplyAnim()
			
			-- Stop animation when complete
			if progress >= 1.0 then
				marker.scalingx = endScale
				marker.scalingy = endScale
				timer:Change()
				marker.popupAnimTimer = nil
			end
		end
	})
	
	marker.popupAnimTimer:Change(0, 33)
end


-- Get the current entity that can be interacted with
function ActionNameDetector:GetCurrentEntity()
	return self.currentEntity
end

-- Get the current action name
function ActionNameDetector:GetCurrentActionName()
	return self.currentActionName
end

-- Trigger the current action (called when T is pressed or mobile button is tapped)
-- @param actionIndex: optional, the index of the action to trigger (1-based) when multiple actions are available
function ActionNameDetector:TriggerCurrentAction(actionIndex)
	if self.currentEntity and self.currentActionName then
		-- Use cached action names
		local actionNames = self.actionNames
		
		if not actionNames then
			return false
		end
		
		-- Default to first action if no index specified
		actionIndex = actionIndex or 1
		local selectedAction = actionNames[actionIndex]
		
		if not selectedAction then
			return false
		end
		
		-- Trigger the entity's onclick event with the selected action
		if self.currentEntity.DoAction then
			self.currentEntity:DoAction(actionIndex)
		elseif self.currentEntity.OnClick then
			local x, y, z = self.currentEntity:GetPosition()
			self.currentEntity:OnClick(x, y, z, "left")
		elseif self.currentEntity.onclick and self.currentEntity.onclick ~= "" then
			-- Handle onclick event string
		self.currentEntity:OnEvent(self.currentEntity.onclick)
	end
	self:actionTriggered(self.currentEntity, actionIndex, selectedAction);
	return true
end
return false
end

-- Trigger an action for a specific entity by marker index
-- @param markerIndex: the index of the marker/entity (1-based)
-- @param actionIndex: the index of the action within that entity's action list (1-based)
function ActionNameDetector:TriggerActionForEntity(markerIndex, actionIndex)
	local entityData = self.entities[markerIndex]
	if not entityData then
		return false
	end
	
	local entity = entityData.entity
	local actionName = entityData.actionName
	actionIndex = math.max(actionIndex or 1, entityData.actionIndex or 1)
	
	if not entity or not actionName then
		return false
	end
	
	-- Trigger the entity's onclick event with the selected action
	-- Pass the stored action index which represents which comma-separated action this is
	if entity.DoAction then
		entity:DoAction(actionIndex)
	elseif entity.OnClick then
		local x, y, z = entity:GetPosition()
		entity:OnClick(x, y, z, "left")
	elseif entity.onclick and entity.onclick ~= "" then
		-- Handle onclick event string
		entity:OnEvent(entity.onclick)
	end
	
	self:actionTriggered(entity, actionIndex, actionName);
	return true
end

ActionNameDetector:InitSingleton();

