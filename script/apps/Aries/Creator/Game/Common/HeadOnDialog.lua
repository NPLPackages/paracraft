--[[
Title: Headon Interactive Dialog
Author(s): LiXizhi
Date: 2025/01/14
Desc: This module provides an interactive dialog box that appears above a specified entity in the 3D world, 
allowing for user interaction through buttons or multiline text input. 
The dialog dynamically updates its position based on the entity's location and the player's viewpoint.
There can be only one HeadOnDialog active at any time. Use HeadOnDisplay for non-interactive UI to show simultaneously. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/HeadOnDialog.lua");
local HeadOnDialog = commonlib.gettable("MyCompany.Aries.Game.Common.HeadOnDialog");
HeadOnDialog.ShowPage(GameLogic.EntityManager.GetPlayer(), "Enter Your Name", {{text="", type="text"}, "OK"}, function(inputText, btnIndex, allTextResults)
	if inputText then
		LOG.std(nil, "info", "HeadOnDialog", "User input: %s", inputText);
	else
		LOG.std(nil, "info", "HeadOnDialog", "Dialog cancelled or closed");
	end
end);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local HeadOnDialog = commonlib.gettable("MyCompany.Aries.Game.Common.HeadOnDialog");

local page;
local updateTimer;
-- Cache the parent container UI object to avoid repeated lookups by name
HeadOnDialog.parentContainer = nil;

-- Safely destroy the cached parent container UI object and clear the cache.
function HeadOnDialog.DestroyParentContainer()
	if HeadOnDialog.parentContainer and HeadOnDialog.parentContainer:IsValid() then
		ParaUI.Destroy(HeadOnDialog.parentContainer.id);
	end
	HeadOnDialog.parentContainer = nil;
end

function HeadOnDialog.OnInit()
	page = document:GetPageCtrl();
end

function HeadOnDialog.GetAvatarEntity()
	return HeadOnDialog.entity;
end

-- Convert 3D world position to 2D screen position
-- @return screenX, screenY in pixels, or nil if not visible
function HeadOnDialog.WorldToScreen(worldX, worldY, worldZ)
	if not worldX or not worldY or not worldZ then
		return nil;
	end
	
	-- Use cached screen pos table to avoid allocation
	if not HeadOnDialog.screenPosCache then
		HeadOnDialog.screenPosCache = {};
	end
	local screen_pos = HeadOnDialog.screenPosCache;
	
	-- Get screen position from 3D point
	screen_pos.x = -9999;
	screen_pos.y = -9999;
	local result = ParaScene.GetScreenPosFrom3DPoint(worldX, worldY, worldZ, screen_pos);
	
	if not result then
		return nil;
	end
	
	-- Use named fields, not indexed values
	local screenX = screen_pos.x;
	local screenY = screen_pos.y;
	
	-- Check if behind camera
	if screenX == -9999 then
		return nil;
	end
	
	return screenX, screenY;
end

-- Update dialog position based on entity position
function HeadOnDialog.UpdatePosition()
	if not HeadOnDialog.entity or not page then
		return false;
	end
	
	local entity = HeadOnDialog.entity;
	if not entity:IsValid() then
		HeadOnDialog.ClosePage();
		return false;
	end
	
	-- Check distance to focused player (15 meter range)
	local player = EntityManager.GetFocus();
	if player then
		local ex, ey, ez = entity:GetPosition();
		local px, py, pz = player:GetPosition();
		local distance = math.sqrt((ex - px)^2 + (ey - py)^2 + (ez - pz)^2);
		
		if distance > 15 then
			-- Player too far, hide dialog
			HeadOnDialog.SetPageVisible(false);
			return false;
		end
	end
	
	-- Get entity world position (top of entity)
	local ex, ey, ez = entity:GetPosition();
	local entityHeight = entity:GetHeight() or 2.0;
	ey = ey + entityHeight; -- Offset above entity head
	
	-- Convert to screen position
	local screenX, screenY = HeadOnDialog.WorldToScreen(ex, ey, ez);
	
	if not screenX or not screenY then
		-- Entity not in viewport, hide dialog
		HeadOnDialog.SetPageVisible(false);
		return false;
	end
	
	-- Check if dialog was hidden and now becoming visible
	local wasVisible = HeadOnDialog.isVisible;
	
	-- Entity is visible, show dialog and update position
	HeadOnDialog.SetPageVisible(true);
	
	-- Get the container UI object (cached)
	local container = HeadOnDialog.parentContainer;
	if container and container:IsValid() and page then
		-- Get the actual used size of the dialog content
		local dialogWidth, dialogHeight = page:GetUsedSize();
		
        -- Center dialog horizontally above entity position
        local dialogX = screenX - dialogWidth + 64;
        local dialogY = screenY - dialogHeight;
        
        -- Move the container
        -- Only update position if it has changed to avoid unnecessary reposition calls
        local curX, curY, curWidth, curHeight = container:GetAbsPosition();
        local newX, newY = math.floor(dialogX), math.floor(dialogY);
        
        if curX ~= newX or curY ~= newY or curWidth ~= dialogWidth or curHeight ~= dialogHeight then
            container:Reposition("_lt", newX, newY, dialogWidth, dialogHeight);
        end

        -- Play popup animation if dialog just became visible
		if not wasVisible then
			HeadOnDialog.PlayPopupAnimation(container);
		end
	end
	
	return true;
end

-- Set page visibility
function HeadOnDialog.SetPageVisible(visible)
	if HeadOnDialog.isVisible == visible then
		return; -- No change
	end
	
	HeadOnDialog.isVisible = visible;
	
	-- Set container visibility using cached parent container
	local container = HeadOnDialog.parentContainer;
	if container and container:IsValid() then
		container.visible = visible;
	end
end

-- Play a pop-up animation when dialog becomes visible (similar to ActionNameDetector)
function HeadOnDialog.PlayPopupAnimation(uiObject)
    if not uiObject or not uiObject:IsValid() then
		return;
	end
	
	-- Cancel any existing animation timer
	if HeadOnDialog.popupAnimTimer then
		HeadOnDialog.popupAnimTimer:Change();
		HeadOnDialog.popupAnimTimer = nil;
	end
	
	-- Animation parameters
	local startScale = 0;
	local endScale = 1.0; -- End at 100% size
	local duration = 500; -- Animation duration in milliseconds
	local startTime = commonlib.TimerManager.GetCurrentTime();
	
	-- Set initial scale
	uiObject.scalingx = startScale;
	uiObject.scalingy = startScale;
	uiObject:ApplyAnim();
	
	-- Create animation timer
	HeadOnDialog.popupAnimTimer = commonlib.Timer:new({
		callbackFunc = function(timer)
			if not uiObject or not uiObject:IsValid() then
				timer:Change();
				return;
			end
			
			local currentTime = commonlib.TimerManager.GetCurrentTime();
			local elapsed = currentTime - startTime;
			local progress = math.min(1.0, elapsed / duration);
			
			-- Easing function (ease out cubic for smooth deceleration)
			local easedProgress = 1 - math.pow(1 - progress, 3);
			
			-- Calculate current scale
			local currentScale = startScale + (endScale - startScale) * easedProgress;
			
			-- Apply scaling
			uiObject.scalingx = currentScale;
			uiObject.scalingy = currentScale;
			
			-- Stop animation when complete
			if progress >= 1.0 then
				uiObject.scalingx = endScale;
				uiObject.scalingy = endScale;
				timer:Change();
				HeadOnDialog.popupAnimTimer = nil;
			end
            uiObject:ApplyAnim();
		end
	});
	
	HeadOnDialog.popupAnimTimer:Change(0, 10);
end

-- Start frame move timer for position updates (30 FPS)
function HeadOnDialog.StartFrameMoveTimer()
    if updateTimer then
		return; -- Already running
	end
	
	updateTimer = commonlib.Timer:new({
		callbackFunc = function(timer)
			if not HeadOnDialog.UpdatePosition() then
				-- Entity invalid or not visible, make timer slower
                timer:Change(0, 200);
            else
                timer:Change(10, 10);
			end
		end
	});
	updateTimer:Change(0, 10);
end

-- Stop frame move timer
function HeadOnDialog.StopFrameMoveTimer()
	if updateTimer then
		updateTimer:Change();
		updateTimer = nil;
	end
end

function HeadOnDialog.ClosePage()
	-- Stop frame move timer
	HeadOnDialog.StopFrameMoveTimer();
	
	-- Clean up popup animation timer
	if HeadOnDialog.popupAnimTimer then
		HeadOnDialog.popupAnimTimer:Change();
		HeadOnDialog.popupAnimTimer = nil;
	end
	
	if page then
		page:CloseWindow();
		page = nil;
	end
	
	-- Destroy parent GUI container (use cached object if available)
	HeadOnDialog.DestroyParentContainer();
	
	-- Call callback with nil result (cancelled)
	if HeadOnDialog.callbackFunc then
		HeadOnDialog.callbackFunc(nil);
		HeadOnDialog.callbackFunc = nil;
	end
	
	-- Clean up
	HeadOnDialog.entity = nil;
	HeadOnDialog.isVisible = false;
end

function HeadOnDialog.OnClickButton(index)
	-- Stop frame move timer
	HeadOnDialog.StopFrameMoveTimer();
	
	-- Clean up popup animation timer
	if HeadOnDialog.popupAnimTimer then
		HeadOnDialog.popupAnimTimer:Change();
		HeadOnDialog.popupAnimTimer = nil;
	end
    local inputText = {}
    -- Iterate all buttons to find text input fields and collect their values
    if HeadOnDialog.buttons then
        for _, btn in ipairs(HeadOnDialog.buttons) do
            inputText[btn.index] = btn.text or "";
            if btn.type == "text" and page then
                inputText[btn.index] = page:GetUIValue("text" .. btn.index) or "";
            end
        end
    end
    -- Store the first text input value for backward compatibility
    if next(inputText) then
        HeadOnDialog.inputText = inputText[next(inputText)];
    else
        HeadOnDialog.inputText = nil;
    end
	
	if page then
		page:CloseWindow();
		page = nil;
	end
	
	-- Destroy parent GUI container (use cached object if available)
	HeadOnDialog.DestroyParentContainer();
	
	-- Clean up
	local callbackFunc = HeadOnDialog.callbackFunc;
	HeadOnDialog.entity = nil;
	HeadOnDialog.isVisible = false;
	HeadOnDialog.callbackFunc = nil;

	-- Handle callback - return input text if there's a text input button, otherwise return button index
	if callbackFunc then
		callbackFunc(HeadOnDialog.inputText, index, inputText);
	end
end

-- Show the ask dialog as a bubble above the entity
-- @param entity: EntityLiveModel to display avatar and position dialog above
-- @param text: string text to display (supports basic HTML)
-- @param buttons: nil or {"button1", "button2"}
-- {{text = "OK", default = true}, "button2"} format is also supported
-- {{text = "输入文字", type="text"}, "确定"} type of text is also supported
-- @param callbackFunc: function(textResult, btnIndex, allTextResults) 
-- textResult: string text input if any button is of type="text", otherwise it is button text
-- btnIndex: number index of button clicked (1-based)
-- allTextResults: table of all text input values by button index
function HeadOnDialog.ShowPage(entity, text, buttons, callbackFunc)
	HeadOnDialog.entity = entity;
	HeadOnDialog.text = text;
	HeadOnDialog.callbackFunc = callbackFunc;
	HeadOnDialog.inputText = "";
	HeadOnDialog.isVisible = false; -- Track visibility state
	HeadOnDialog.hasTextInput = false; -- Track if any button has type="text"
	
	-- Convert buttons array to indexed table
	if type(buttons) == "table" and #buttons > 0 then
		HeadOnDialog.buttons = {};
		for i, btn in ipairs(buttons) do
			if type(btn) == "table" then
				-- Button is already a table with text/default fields
				local buttonData = {text = btn.text or btn[1], index = i, type=btn.type or "button", default = btn.default == true};
				table.insert(HeadOnDialog.buttons, buttonData);
				-- Check if this button is a text input
				if btn.type == "text" then
					HeadOnDialog.hasTextInput = true;
				end
			else
				-- Button is a simple text string
				table.insert(HeadOnDialog.buttons, {text = btn, index = i, type = "button", default = false});
			end
		end
	else
		HeadOnDialog.buttons = nil;
	end
	
	-- Close existing page if any
	if page then
		page:CloseWindow();
		page = nil;
	end
	
	-- Create parent GUI container. Destroy existing cached container if present.
	HeadOnDialog.DestroyParentContainer();

	-- Create a small, initially hidden parent container to avoid a flash at top-left
	-- when the dialog is shown immediately (layout may not be ready yet).
	-- It will be resized and shown by UpdatePosition when valid screen coordinates are available.
	local _this = ParaUI.CreateUIObject("container", "HeadOnDialog_container", "_lt", 0, 0, 512, 512);
	_this.background = "";
	_this.zorder = HeadOnDialog.zorder or -10;
	-- hide initially until we can position it above the entity
	_this.visible = false;
	_this:AttachToRoot();
	-- Cache the created parent container UI object for future use
	HeadOnDialog.parentContainer = _this;
	
	-- Create MCML page control
	
	page = System.mcml.PageCtrl:new({url = "script/apps/Aries/Creator/Game/Common/HeadOnDialog.html"});
	page:Create("HeadOnDialog", _this, "_fi", 0, 0, 0, 0);
	
	HeadOnDialog.StartFrameMoveTimer();
end

function HeadOnDialog.SetVisible(visible)
	if(HeadOnDialog.parentContainer) then
		HeadOnDialog.parentContainer.visible = visible == true;
		if visible then
			HeadOnDialog.StartFrameMoveTimer();
		else
			HeadOnDialog.StopFrameMoveTimer();
		end
	end
end