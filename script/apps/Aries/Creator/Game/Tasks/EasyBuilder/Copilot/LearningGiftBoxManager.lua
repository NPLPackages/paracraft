--[[
Title: Learning Gift Box Manager
Author(s): GitHub Copilot
Date: 2026/02/09
Desc: Manages interactive gift boxes for learning tasks. When a learning tool is triggered,
      a gift box is spawned near the player. The player must click the gift box to accept
      and start the learning task. Provides periodic reminders and distance-based teleportation.

Use the lib:
------------------------------------------------------------
local LearningGiftBoxManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/LearningGiftBoxManager.lua");
LearningGiftBoxManager.GetSingleton():CreateGiftBox(toolName, params, callback)
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityLiveModel.lua");
NPL.load("(gl)script/ide/headon_speech.lua");

local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");

local LearningGiftBoxManager = NPL.export();

-- Constants
local MAX_GIFT_BOXES = 5;
local SPEECH_INTERVAL = 30000; -- 30 seconds in milliseconds
local MAX_DISTANCE = 15; -- blocks
local GIFT_BOX_SCALE = 0.8;
local ENTITY_NAME_PREFIX = "__learning_giftbox_";

-- Spawn animation constants
local SPAWN_DROP_HEIGHT = 6; -- blocks above target position
local SPAWN_ANIM_DURATION = 1200; -- milliseconds for fall animation
local SPAWN_BOUNCE_HEIGHT = 0.5; -- bounce height after landing
local SPAWN_BOUNCE_DURATION = 300; -- bounce animation duration
local SPAWN_SPIN_ROTATIONS = 2; -- number of full rotations during fall

-- Spacing constants to prevent overlap
local MIN_GIFTBOX_SPACING = 1.5; -- minimum distance between gift boxes (in blocks)
local MAX_SPAWN_ATTEMPTS = 8; -- maximum attempts to find non-overlapping position

-- Reminder constants when too many gift boxes exist
local GIFTBOX_WARNING_THRESHOLD = 3; -- number of gift boxes to trigger warning
local GIFTBOX_WARNING_COOLDOWN = 60000; -- 60 seconds cooldown between warnings (in milliseconds)

-- Gift box models (randomly selected)
local GIFT_BOX_MODELS = {
    "character/v5/06quest/GiftBox/GiftBox_Orange.x",
    "character/v5/06quest/GiftBox/GiftBox_Blue.x",
    "character/v5/06quest/GiftBox/GiftBox_Pink.x",
};

-- Speech reminder messages (randomly selected)
local SPEECH_MESSAGES = {
    L"点击我开始学习吧！",
    L"完成学习可获得知识币奖励喔~",
    L"快来挑战一下！",
    L"这里有学习任务等你哦！",
    L"点击领取学习礼物！",
};

-- Singleton instance
local singleton = nil;

-- Manager class
local Manager = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.LearningGiftBoxManager"));

function Manager:ctor()
    -- Active gift boxes: sessionId -> {entity, toolName, params, callback, createTime, speechTimer, distanceTimer}
    self.activeGiftBoxes = {};
    self.activeCount = 0;
    self.isInitialized = false;
    
    -- Throttle for "too many gift boxes" warning
    self.lastGiftBoxWarningTime = 0;
end

function Manager:Init()
    if self.isInitialized then
        return;
    end
    self.isInitialized = true;
    
    -- Register for world unload to cleanup
    GameLogic.GetFilters():add_filter("OnWorldUnload", function()
        self:ClearAllGiftBoxes();
        return true;
    end);
    
    LOG.std(nil, "info", "LearningGiftBoxManager", "Initialized");
end

--[[
    Get singleton instance
    @return Manager instance
]]
function LearningGiftBoxManager.GetSingleton()
    if not singleton then
        singleton = Manager:new();
        singleton:Init();
    end
    return singleton;
end

--[[
    Get player's current position in world coordinates
    @return x, y, z position
]]
function Manager:GetPlayerPosition()
    local player = EntityManager.GetFocus();
    if not player then
        return 0, 0, 0;
    end
    return player:GetPosition();
end

--[[
    Get a position in front of the player
    @param distance: number - Distance in front of player (default: 2)
    @return x, y, z position
]]
function Manager:GetPositionInFrontOfPlayer(distance)
    distance = distance or 2;
    local player = EntityManager.GetFocus();
    if not player then
        return 0, 0, 0;
    end
    local x, y, z = player:GetPosition();
    local facing = player:GetFacing();
    local dx = distance * math.cos(facing);
    local dz = -distance * math.sin(facing);
    return x + dx, y, z + dz;
end

--[[
    Check if a position is too close to any existing gift box
    @param x: number - X position to check
    @param z: number - Z position to check
    @param excludeSessionId: string (optional) - Session ID to exclude from check
    @return boolean - true if position overlaps with existing gift box
]]
function Manager:IsPositionOverlapping(x, z, excludeSessionId)
    for sessionId, giftBox in pairs(self.activeGiftBoxes) do
        if sessionId ~= excludeSessionId and giftBox.entity and giftBox.entity:IsValid() then
            local ex, ey, ez = giftBox.entity:GetPosition();
            local distance = math.sqrt((x - ex)^2 + (z - ez)^2);
            if distance < MIN_GIFTBOX_SPACING then
                return true;
            end
        end
    end
    return false;
end

--[[
    Find a non-overlapping spawn position for a new gift box
    Tries positions around the player in a spiral pattern
    @param excludeSessionId: string (optional) - Session ID to exclude from overlap check
    @return x, y, z - Non-overlapping position, or best available position
]]
function Manager:FindNonOverlappingPosition(excludeSessionId)
    local player = EntityManager.GetFocus();
    if not player then
        return 0, 0, 0;
    end
    
    local px, py, pz = player:GetPosition();
    local facing = player:GetFacing();
    
    -- Try different positions in front of player
    -- Start with direct front, then try angled positions
    local baseDistance = 2;
    local angleOffsets = {0, math.pi/4, -math.pi/4, math.pi/2, -math.pi/2, math.pi*3/4, -math.pi*3/4, math.pi};
    local distanceOffsets = {0, 0.5, 1, 1.5};
    
    for _, distOffset in ipairs(distanceOffsets) do
        for _, angleOffset in ipairs(angleOffsets) do
            local distance = baseDistance + distOffset;
            local angle = facing + angleOffset;
            local dx = distance * math.cos(angle);
            local dz = -distance * math.sin(angle);
            local testX = px + dx;
            local testZ = pz + dz;
            
            if not self:IsPositionOverlapping(testX, testZ, excludeSessionId) then
                return testX, py, testZ;
            end
        end
    end
    
    -- If all positions overlap, find the position with maximum distance from existing boxes
    local bestX, bestZ = px + baseDistance * math.cos(facing), pz - baseDistance * math.sin(facing);
    local bestMinDistance = 0;
    
    for _, distOffset in ipairs(distanceOffsets) do
        for _, angleOffset in ipairs(angleOffsets) do
            local distance = baseDistance + distOffset;
            local angle = facing + angleOffset;
            local dx = distance * math.cos(angle);
            local dz = -distance * math.sin(angle);
            local testX = px + dx;
            local testZ = pz + dz;
            
            -- Find minimum distance to any existing gift box
            local minDistToExisting = math.huge;
            for sessionId, giftBox in pairs(self.activeGiftBoxes) do
                if sessionId ~= excludeSessionId and giftBox.entity and giftBox.entity:IsValid() then
                    local ex, ey, ez = giftBox.entity:GetPosition();
                    local dist = math.sqrt((testX - ex)^2 + (testZ - ez)^2);
                    minDistToExisting = math.min(minDistToExisting, dist);
                end
            end
            
            -- Keep track of position with best (largest) minimum distance
            if minDistToExisting > bestMinDistance then
                bestMinDistance = minDistToExisting;
                bestX = testX;
                bestZ = testZ;
            end
        end
    end
    
    return bestX, py, bestZ;
end

--[[
    Get random gift box model path
    @return string - Model file path
]]
function Manager:GetRandomGiftBoxModel()
    local index = math.random(1, #GIFT_BOX_MODELS);
    return GIFT_BOX_MODELS[index];
end

--[[
    Get random speech message
    @return string - Speech message
]]
function Manager:GetRandomSpeechMessage()
    local index = math.random(1, #SPEECH_MESSAGES);
    return SPEECH_MESSAGES[index];
end

--[[
    Generate unique session ID
    @param toolName: string - Tool name
    @return string - Unique session ID
]]
function Manager:GenerateSessionId(toolName)
    return string.format("%s_%d_%d", toolName, os.time(), math.random(10000, 99999));
end

--[[
    Get entity name for a session
    @param sessionId: string - Session ID
    @return string - Entity name
]]
function Manager:GetEntityName(sessionId)
    return ENTITY_NAME_PREFIX .. sessionId;
end

--[[
    Check if at maximum capacity
    @return boolean
]]
function Manager:IsAtMaxCapacity()
    return self.activeCount >= MAX_GIFT_BOXES;
end

--[[
    Get active gift box count
    @return number
]]
function Manager:GetActiveCount()
    return self.activeCount;
end

--[[
    Check if there are too many gift boxes and warn user via TTS
    Uses throttling to avoid spamming the reminder
]]
function Manager:CheckAndWarnTooManyGiftBoxes()
    -- Check if we have enough gift boxes to warrant a warning
    if self.activeCount < GIFTBOX_WARNING_THRESHOLD then
        return;
    end
    
    -- Check cooldown (throttle)
    local currentTime = ParaGlobal.timeGetTime();
    if currentTime - self.lastGiftBoxWarningTime < GIFTBOX_WARNING_COOLDOWN then
        return;
    end
    
    -- Update last warning time
    self.lastGiftBoxWarningTime = currentTime;
    
    -- Get BackgroundAgent to speak the warning
    local BackgroundAgent = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BackgroundAgent");
    if BackgroundAgent and BackgroundAgent.GetInstance then
        local agent = BackgroundAgent:GetInstance();
        if agent and agent.SpeakText then
            local warningText = string.format(
                "哎呀，你有%d个学习礼盒等着你呢！快点击它们开始学习吧，完成后可以获得知识币奖励哦！",
                self.activeCount
            );
            agent:SpeakText(warningText, nil, false);
            LOG.std(nil, "info", "LearningGiftBoxManager", "TTS warning: %d gift boxes pending", self.activeCount);
        end
    end
end

--[[
    Create a gift box for a learning tool
    @param toolName: string - The learning tool name (test_multiple_choice, etc.)
    @param params: table - Tool parameters
    @param callback: function - Callback to invoke when tool completes
    @return boolean - true if gift box created, false if at capacity
]]
function Manager:CreateGiftBox(toolName, params, callback)
    self:Init();
    
    -- Check capacity
    if self:IsAtMaxCapacity() then
        LOG.std(nil, "info", "LearningGiftBoxManager", "At max capacity (%d/%d), rejecting new gift box", 
            self.activeCount, MAX_GIFT_BOXES);
        
        -- Notify AI that capacity is full
        if callback then
            callback({
                success = false,
                llm_result = string.format(
                    "学习任务已满(%d/%d)，请提醒玩家完成现有任务获得知识币奖励。玩家可以点击场景中的礼物盒来开始学习。",
                    self.activeCount, MAX_GIFT_BOXES
                ),
            });
        end
        return false;
    end
    
    -- Generate session ID
    local sessionId = self:GenerateSessionId(toolName);
    local entityName = self:GetEntityName(sessionId);
    
    -- Get target position (non-overlapping position near player)
    local targetX, targetY, targetZ = self:FindNonOverlappingPosition();
    
    -- Start position is high above target (for drop animation)
    local startY = targetY + SPAWN_DROP_HEIGHT;
    
    -- Create entity at high position
    local entity = GameLogic.EntityManager.EntityLiveModel:Create({
        x = targetX,
        y = startY,
        z = targetZ,
        item_id = block_types.names.LiveModel,
    });
    
    if not entity then
        LOG.std(nil, "error", "LearningGiftBoxManager", "Failed to create entity for session: %s", sessionId);
        if callback then
            callback({
                success = false,
                llm_result = "创建学习礼盒失败，请重试",
            });
        end
        return false;
    end
    
    -- Configure entity
    entity:SetModelFile(self:GetRandomGiftBoxModel());
    entity:setScale(0.1); -- Start small for dramatic effect
    entity:SetName(entityName);
    entity:SetStaticTag("actionname", L"学习任务");
    entity:SetPersistent(false);
    entity:SetCanDrag(false);
    entity:Attach();
    
    -- Play spawn animation (fall from sky with spin)
    self:PlaySpawnAnimation(entity, targetX, targetY, targetZ, sessionId);
    
    -- Register click event handler
    local clickEventName = "__giftbox_click_" .. sessionId;
    entity:SetOnClickEvent(clickEventName);
    
    -- Register click event listener
    GameLogic.GetCodeGlobal():RegisterTextEvent(clickEventName, function(args, msg)
        self:OnGiftBoxClicked(sessionId);
    end);
    
    -- Create speech timer (reminder every 30 seconds)
    local speechTimer = commonlib.Timer:new({
        callbackFunc = function()
            self:SpeakReminder(sessionId);
        end,
    });
    speechTimer:Change(SPEECH_INTERVAL, SPEECH_INTERVAL); -- Start after 30s, repeat every 30s
    
    -- Create distance check timer (every 5 seconds)
    local distanceTimer = commonlib.Timer:new({
        callbackFunc = function()
            self:CheckPlayerDistance(sessionId);
        end,
    });
    distanceTimer:Change(5000, 5000); -- Check every 5 seconds
    
    -- Store gift box data including callback for returning result to LLM
    self.activeGiftBoxes[sessionId] = {
        entity = entity,
        entityName = entityName,
        toolName = toolName,
        params = params,
        callback = callback, -- Store callback to return result to LLM when task completes
        createTime = os.time(),
        speechTimer = speechTimer,
        distanceTimer = distanceTimer,
        clickEventName = clickEventName,
    };
    self.activeCount = self.activeCount + 1;
    
    LOG.std(nil, "info", "LearningGiftBoxManager", "Created gift box for %s (session: %s, count: %d/%d)", 
        toolName, sessionId, self.activeCount, MAX_GIFT_BOXES);
    
    -- Initial speech after a short delay
    commonlib.TimerManager.SetTimeout(function()
        self:SpeakReminder(sessionId);
    end, 1000);
    
    -- Check if too many gift boxes and remind user via TTS (with throttling)
    self:CheckAndWarnTooManyGiftBoxes();
    
    return true, sessionId;
end

--[[
    Handle gift box click
    @param sessionId: string - Session ID of clicked gift box
]]
function Manager:OnGiftBoxClicked(sessionId)
    local giftBox = self.activeGiftBoxes[sessionId];
    if not giftBox then
        LOG.std(nil, "warn", "LearningGiftBoxManager", "Clicked unknown gift box: %s", sessionId);
        return;
    end
    
    -- Show confirmation dialog
    _guihelper.MessageBox(
        L"是否开始学习？<br/>完成后可获得知识币奖励！",
        function(res)
            if res == _guihelper.DialogResult.Yes then
                self:LaunchLearningUI(sessionId);
            end
        end,
        _guihelper.MessageBoxButtons.YesNo
    );
end

--[[
    Launch the learning UI for a gift box
    @param sessionId: string - Session ID
]]
function Manager:LaunchLearningUI(sessionId)
    local giftBox = self.activeGiftBoxes[sessionId];
    if not giftBox then
        return;
    end
    
    -- Stop timers while learning
    if giftBox.speechTimer then
        giftBox.speechTimer:Change(nil, nil);
    end
    if giftBox.distanceTimer then
        giftBox.distanceTimer:Change(nil, nil);
    end
    
    -- Get BackgroundAgent to launch the actual learning tool
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/LearningToolUI.lua");
    local LearningToolUI = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.LearningToolUI");
    
    LOG.std(nil, "info", "LearningGiftBoxManager", "Launching learning UI for %s (session: %s)", 
        giftBox.toolName, sessionId);
    
    -- Show the learning tool UI
    LearningToolUI.Show(giftBox.toolName, giftBox.params, sessionId, function(result)
        self:OnLearningComplete(sessionId, result);
    end);
end

--[[
    Handle learning completion
    @param sessionId: string - Session ID
    @param result: table - Result from learning tool {success, correct, score, userAnswer, ...}
]]
function Manager:OnLearningComplete(sessionId, result)
    local giftBox = self.activeGiftBoxes[sessionId];
    if not giftBox then
        return;
    end
    
    result = result or {};
    
    LOG.std(nil, "info", "LearningGiftBoxManager", "Learning completed for %s (session: %s, correct: %s)", 
        giftBox.toolName, sessionId, tostring(result.correct));
    
    -- Update learning progress in BackgroundAgent (for primary task tracking)
    self:UpdateBackgroundAgentProgress(giftBox, result);
    
    -- Play open animation and remove gift box
    self:PlayOpenAnimationAndRemove(sessionId, function()
        -- Award knowledge coins if successful
        if result.success ~= false and result.correct ~= false then
            self:AwardKnowledgeCoins(sessionId, result);
        end
        
        -- Build LLM result string
        local llm_result;
        if result.correct ~= nil then
            llm_result = string.format("Tool: %s, correct=%s", giftBox.toolName, tostring(result.correct));
            if result.score then
                llm_result = llm_result .. string.format(", score=%d", result.score);
            end
            if result.userAnswer then
                llm_result = llm_result .. string.format(", userAnswer=%s", tostring(result.userAnswer));
            end
        elseif result.cancelled or result.skipped then
            llm_result = string.format("Tool: %s was cancelled/skipped by user", giftBox.toolName);
        else
            llm_result = string.format("Tool: %s completed", giftBox.toolName);
        end
        
        LOG.std(nil, "info", "LearningGiftBoxManager", "Learning result: %s", llm_result);
        
        -- Return result to LLM via stored callback
        if giftBox.callback then
            LOG.std(nil, "info", "LearningGiftBoxManager", "Returning result to LLM for session: %s", sessionId);
            giftBox.callback({
                success = result.success ~= false,
                llm_result = llm_result,
            });
        end
        
        -- Cleanup
        self:RemoveGiftBox(sessionId);
    end);
end

--[[
    Update BackgroundAgent's learning progress for primary task tracking
    @param giftBox: table - Gift box data
    @param result: table - Learning result
]]
function Manager:UpdateBackgroundAgentProgress(giftBox, result)
    if not giftBox or not result then
        return;
    end
    
    -- Only update if we have a subject/word and a correct/incorrect result
    local subject = giftBox.params and (giftBox.params.subject or giftBox.params.word);
    if not subject or result.correct == nil then
        return;
    end
    
    -- Get BackgroundAgent instance and update progress
    local BackgroundAgent = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BackgroundAgent");
    if BackgroundAgent and BackgroundAgent.GetInstance then
        local agent = BackgroundAgent:GetInstance();
        if agent and agent.UpdateLearningProgress then
            agent:UpdateLearningProgress(subject, result.correct, {
                score = result.score,
                toolName = giftBox.toolName,
            });
            LOG.std(nil, "info", "LearningGiftBoxManager", "Updated learning progress for '%s': correct=%s", 
                subject, tostring(result.correct));
        end
    end
end

--[[
    Play spawn animation - gift box falls from sky with spin and bounce
    @param entity: Entity - The gift box entity
    @param targetX: number - Target X position
    @param targetY: number - Target Y position (landing position)
    @param targetZ: number - Target Z position
    @param sessionId: string - Session ID for logging
]]
function Manager:PlaySpawnAnimation(entity, targetX, targetY, targetZ, sessionId)
    if not entity or not entity:IsValid() then
        return;
    end
    
    local startY = targetY + SPAWN_DROP_HEIGHT;
    local startTime = commonlib.TimerManager.GetCurrentTime();
    local startScale = 0.1;
    local endScale = GIFT_BOX_SCALE;
    
    -- Easing function for bounce effect (ease out bounce)
    local function easeOutBounce(t)
        if t < 1/2.75 then
            return 7.5625 * t * t;
        elseif t < 2/2.75 then
            t = t - 1.5/2.75;
            return 7.5625 * t * t + 0.75;
        elseif t < 2.5/2.75 then
            t = t - 2.25/2.75;
            return 7.5625 * t * t + 0.9375;
        else
            t = t - 2.625/2.75;
            return 7.5625 * t * t + 0.984375;
        end
    end
    
    -- Easing function for smooth deceleration (ease out quad)
    local function easeOutQuad(t)
        return 1 - (1 - t) * (1 - t);
    end
    
    local animTimer = commonlib.Timer:new({
        callbackFunc = function(timer)
            local elapsed = commonlib.TimerManager.GetCurrentTime() - startTime;
            local totalDuration = SPAWN_ANIM_DURATION + SPAWN_BOUNCE_DURATION;
            local progress = math.min(elapsed / totalDuration, 1);
            
            if not entity or not entity:IsValid() then
                timer:Change(nil, nil);
                return;
            end
            
            if elapsed <= SPAWN_ANIM_DURATION then
                -- Phase 1: Falling from sky with spin
                local fallProgress = elapsed / SPAWN_ANIM_DURATION;
                local easedProgress = easeOutQuad(fallProgress);
                
                -- Calculate Y position (falling down)
                local currentY = startY - (startY - targetY) * easedProgress;
                
                -- Calculate rotation (spin during fall)
                local rotation = fallProgress * SPAWN_SPIN_ROTATIONS * math.pi * 2;
                
                -- Calculate scale (grow from small to full size)
                local currentScale = startScale + (endScale - startScale) * easedProgress;
                
                -- Apply transformations
                entity:SetPosition(targetX, currentY, targetZ);
                entity:SetFacing(rotation);
                entity:setScale(currentScale);
                
            elseif elapsed <= totalDuration then
                -- Phase 2: Bounce effect after landing
                local bounceElapsed = elapsed - SPAWN_ANIM_DURATION;
                local bounceProgress = bounceElapsed / SPAWN_BOUNCE_DURATION;
                
                -- Bounce: go up slightly then back down
                local bounceEased = math.sin(bounceProgress * math.pi);
                local bounceY = targetY + SPAWN_BOUNCE_HEIGHT * bounceEased;
                
                -- Slight scale pulse during bounce
                local scalePulse = 1 + 0.1 * bounceEased;
                
                entity:SetPosition(targetX, bounceY, targetZ);
                entity:setScale(endScale * scalePulse);
                
            else
                -- Animation complete
                timer:Change(nil, nil);
                entity:SetPosition(targetX, targetY, targetZ);
                entity:setScale(endScale);
                entity:SetFacing(0); -- Reset facing
                
                -- Play landing sparkle effect
                self:PlayLandingEffect(targetX, targetY, targetZ);
                
                LOG.std(nil, "info", "LearningGiftBoxManager", "Spawn animation completed for session: %s", sessionId);
            end
        end,
    });
    
    -- Run animation at 30fps (33ms interval)
    animTimer:Change(0, 33);
    
    LOG.std(nil, "info", "LearningGiftBoxManager", "Started spawn animation for session: %s", sessionId);
end

--[[
    Play a sparkle/star effect at the landing position
    @param x: number - X position
    @param y: number - Y position
    @param z: number - Z position
]]
function Manager:PlayLandingEffect(x, y, z)
    -- Create multiple sparkle particles around the landing point
    local effectModel = "character/CC/05effect/star.x";
    local numParticles = 5;
    
    for i = 1, numParticles do
        local angle = (i / numParticles) * math.pi * 2;
        local radius = 0.3;
        local particleX = x + radius * math.cos(angle);
        local particleZ = z + radius * math.sin(angle);
        
        local particle = GameLogic.EntityManager.EntityLiveModel:Create({
            x = particleX,
            y = y + 0.3,
            z = particleZ,
            item_id = block_types.names.LiveModel,
        });
        
        if particle then
            particle:SetModelFile(effectModel);
            particle:setScale(0.2);
            particle:SetPersistent(false);
            particle:SetDummy(true);
            particle:Attach();
            
            -- Animate particle: rise up and fade out
            local startTime = commonlib.TimerManager.GetCurrentTime();
            local duration = 800; -- ms
            local startY = y + 0.3;
            local endY = y + 1.5;
            
            local particleTimer = commonlib.Timer:new({
                callbackFunc = function(timer)
                    local elapsed = commonlib.TimerManager.GetCurrentTime() - startTime;
                    local progress = math.min(elapsed / duration, 1);
                    
                    if not particle or not particle:IsValid() then
                        timer:Change(nil, nil);
                        return;
                    end
                    
                    if progress < 1 then
                        -- Rise up with shrinking
                        local currentY = startY + (endY - startY) * progress;
                        local currentScale = 0.2 * (1 - progress * 0.8);
                        
                        particle:SetPosition(particleX, currentY, particleZ);
                        particle:setScale(math.max(0.02, currentScale));
                        
                        -- Add slight horizontal movement
                        local wobble = math.sin(progress * math.pi * 4) * 0.1;
                        particle:SetPosition(particleX + wobble, currentY, particleZ);
                    else
                        -- Destroy particle
                        timer:Change(nil, nil);
                        particle:Destroy();
                    end
                end,
            });
            particleTimer:Change(0, 33);
        end
    end
end

--[[
    Play gift box open animation then remove it
    @param sessionId: string - Session ID
    @param onComplete: function - Callback when animation completes
]]
function Manager:PlayOpenAnimationAndRemove(sessionId, onComplete)
    local giftBox = self.activeGiftBoxes[sessionId];
    if not giftBox or not giftBox.entity then
        if onComplete then
            onComplete();
        end
        return;
    end
    
    local entity = giftBox.entity;
    
    -- Simple scale up animation to simulate opening
    local startScale = GIFT_BOX_SCALE;
    local endScale = GIFT_BOX_SCALE * 1.5;
    local duration = 500; -- milliseconds
    local startTime = commonlib.TimerManager.GetCurrentTime();
    
    local animTimer = commonlib.Timer:new({
        callbackFunc = function(timer)
            local elapsed = commonlib.TimerManager.GetCurrentTime() - startTime;
            local progress = math.min(elapsed / duration, 1);
            
            if entity and entity:IsValid() then
                -- Scale up then fade (we'll just scale for now)
                if progress < 0.5 then
                    -- Scale up phase
                    local scale = startScale + (endScale - startScale) * (progress * 2);
                    entity:setScale(scale);
                else
                    -- Scale down phase (shrinking as it disappears)
                    local shrinkProgress = (progress - 0.5) * 2;
                    local scale = endScale * (1 - shrinkProgress);
                    entity:setScale(math.max(0.1, scale));
                end
            end
            
            if progress >= 1 then
                timer:Change(nil, nil);
                if onComplete then
                    onComplete();
                end
            end
        end,
    });
    animTimer:Change(0, 30); -- 30ms interval for smooth animation
end

--[[
    Award knowledge coins for completing a learning task
    @param sessionId: string - Session ID
    @param result: table - Learning result
]]
function Manager:AwardKnowledgeCoins(sessionId, result)
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMgr.lua");
    local MiniGameMgr = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.MiniGameMgr");
    local mgr = MiniGameMgr.GetSingleton and MiniGameMgr.GetSingleton();
    
    if not mgr then
        LOG.std(nil, "warn", "LearningGiftBoxManager", "MiniGameMgr not available for bean reward");
        return;
    end
    
    -- Award 1 knowledge coin for completing a learning task
    local beanCount = 0;
    if result.correct == true then
        beanCount = 10; -- Bonus for correct answer
        mgr:AchieveBean(beanCount, function(res)
            if res and res.achieve then
                LOG.std(nil, "info", "LearningGiftBoxManager", "Awarded %d knowledge beans for session: %s", 
                    res.beanNum or beanCount, sessionId);
            end
        end, true); -- Play get effect
    end
    
end

--[[
    Speak a reminder message from the gift box
    @param sessionId: string - Session ID
]]
function Manager:SpeakReminder(sessionId)
    local giftBox = self.activeGiftBoxes[sessionId];
    if not giftBox or not giftBox.entity then
        return;
    end
    
    local entityName = giftBox.entityName;
    local message = self:GetRandomSpeechMessage();
    
    -- Use headon_speech to show speech bubble
    headon_speech.Speek(entityName, message, 5, true);
end

--[[
    Check player distance and teleport gift box if too far
    @param sessionId: string - Session ID
]]
function Manager:CheckPlayerDistance(sessionId)
    local giftBox = self.activeGiftBoxes[sessionId];
    if not giftBox or not giftBox.entity then
        return;
    end
    
    local entity = giftBox.entity;
    if not entity:IsValid() then
        return;
    end
    
    local px, py, pz = self:GetPlayerPosition();
    local ex, ey, ez = entity:GetPosition();
    
    local distance = math.sqrt((px - ex)^2 + (pz - ez)^2);
    
    if distance > MAX_DISTANCE then
        -- Teleport gift box to non-overlapping position near player
        local newX, newY, newZ = self:FindNonOverlappingPosition(sessionId);
        entity:SetPosition(newX, newY, newZ);
        
        LOG.std(nil, "info", "LearningGiftBoxManager", "Teleported gift box %s to player (distance was: %.1f)", 
            sessionId, distance);
        
        -- Speak a message after teleporting
        commonlib.TimerManager.SetTimeout(function()
            headon_speech.Speek(giftBox.entityName, L"我来找你啦！快点击我开始学习吧！", 5, true);
        end, 500);
    end
end

--[[
    Remove a gift box and cleanup resources
    @param sessionId: string - Session ID
]]
function Manager:RemoveGiftBox(sessionId)
    local giftBox = self.activeGiftBoxes[sessionId];
    if not giftBox then
        return;
    end
    
    -- Stop timers
    if giftBox.speechTimer then
        giftBox.speechTimer:Change(nil, nil);
        giftBox.speechTimer = nil;
    end
    if giftBox.distanceTimer then
        giftBox.distanceTimer:Change(nil, nil);
        giftBox.distanceTimer = nil;
    end
    
    -- Unregister click event
    if giftBox.clickEventName then
        GameLogic.GetCodeGlobal():UnregisterTextEvent(giftBox.clickEventName);
    end
    
    -- Destroy entity
    if giftBox.entity and giftBox.entity:IsValid() then
        giftBox.entity:Destroy();
    end
    
    -- Remove from active list
    self.activeGiftBoxes[sessionId] = nil;
    self.activeCount = math.max(0, self.activeCount - 1);
    
    LOG.std(nil, "info", "LearningGiftBoxManager", "Removed gift box %s (remaining: %d)", 
        sessionId, self.activeCount);
end

--[[
    Clear all gift boxes (cleanup on world unload, etc.)
]]
function Manager:ClearAllGiftBoxes()
    LOG.std(nil, "info", "LearningGiftBoxManager", "Clearing all gift boxes (%d active)", self.activeCount);
    
    for sessionId, giftBox in pairs(self.activeGiftBoxes) do
        -- Stop timers
        if giftBox.speechTimer then
            giftBox.speechTimer:Change(nil, nil);
        end
        if giftBox.distanceTimer then
            giftBox.distanceTimer:Change(nil, nil);
        end
        
        -- Unregister click event
        if giftBox.clickEventName then
            pcall(function()
                GameLogic.GetCodeGlobal():UnregisterTextEvent(giftBox.clickEventName);
            end);
        end
        
        -- Destroy entity
        if giftBox.entity and giftBox.entity:IsValid() then
            giftBox.entity:Destroy();
        end
        
        -- Notify LLM that task was cancelled
        if giftBox.callback then
            giftBox.callback({
                success = false,
                llm_result = string.format("Tool: %s was cancelled (world unload/cleanup)", giftBox.toolName),
            });
        end
    end
    
    self.activeGiftBoxes = {};
    self.activeCount = 0;
end

--[[
    Get all active gift box info (for debugging)
    @return table - Array of {sessionId, toolName, createTime, ...}
]]
function Manager:GetActiveGiftBoxInfo()
    local result = {};
    for sessionId, giftBox in pairs(self.activeGiftBoxes) do
        table.insert(result, {
            sessionId = sessionId,
            toolName = giftBox.toolName,
            createTime = giftBox.createTime,
            entityName = giftBox.entityName,
        });
    end
    return result;
end

--[[
    Check if a specific learning tool is already pending
    @param toolName: string - Tool name to check
    @return boolean
]]
function Manager:HasPendingTool(toolName)
    for _, giftBox in pairs(self.activeGiftBoxes) do
        if giftBox.toolName == toolName then
            return true;
        end
    end
    return false;
end

return LearningGiftBoxManager;
