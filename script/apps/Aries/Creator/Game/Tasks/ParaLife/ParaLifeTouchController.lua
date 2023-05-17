--[[
Title: Paralife Touch controller
Author(s): LiXizhi
Date: 2022/1/28
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeTouchController.lua");
local ParaLifeTouchController = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeTouchController")
ParaLifeTouchController.ShowPage(true)
------------------------------------------------------------
]]
local TouchSession = commonlib.gettable("MyCompany.Aries.Game.Common.TouchSession")
local MouseEvent = commonlib.gettable("System.Windows.MouseEvent");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ParaLifeTouchController = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeTouchController")

local page;
local touchEvents;
local self = ParaLifeTouchController
local defaultBallOpacity = 0.95
local walkPathGrid;

ParaLifeTouchController.maxPathFindingSteps = 16;
-- if player is dragging 200 pixels from starting point, we will use run speed instead of walk speed. 
ParaLifeTouchController.dragRunSpeed = 12
-- 5 meters/sec
ParaLifeTouchController.dragWalkSpeed = 5
-- 12 meters/second
ParaLifeTouchController.twoFingerDragSpeed = 12;

function ParaLifeTouchController.OnInit()
	page = document:GetPageCtrl();
	if(not walkPathGrid) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Common/WalkPathGrid.lua");
		local WalkPathGrid = commonlib.gettable("MyCompany.Aries.Game.WalkPathGrid");
		walkPathGrid = WalkPathGrid:new();
	end
end

function ParaLifeTouchController.OnPageLoaded()
	local touchScreen = page:FindControl("paralife_touch_scene")
	if(touchScreen) then
		touchScreen:SetScript("onmousedown", function()
			-- shall we disable clip cursor to app's window?
			touchScreen:SetField("MouseCaptured", true);
			local event = MouseEvent:init("mousePressEvent")
			ParaLifeTouchController.handleMouseEvent(event);
			ParaLifeTouchController.SetZorder(100)
		end);
		touchScreen:SetScript("onmouseup", function()
			touchScreen:SetField("MouseCaptured", false);
			local event = MouseEvent:init("mouseReleaseEvent")
			ParaLifeTouchController.handleMouseEvent(event);
			ParaLifeTouchController.SetZorder(-20)
		end);
		touchScreen:SetScript("onmousemove", function()
			local event = MouseEvent:init("mouseMoveEvent")
			ParaLifeTouchController.handleMouseEvent(event);
		end);
		touchScreen:SetScript("ontouch", function()
			ParaLifeTouchController.handleTouchEvent(msg)
		end);
	end	
	local touchBall = page:FindControl("touchBall")
	if(touchBall) then
		local obj = touchBall:GetObject()
		if(obj) then
			obj:SetField("EnableAnim", false);
			obj:SetField("AnimFrame", 0);
			obj:SetField("opacity", defaultBallOpacity);
		end
	end
end

function ParaLifeTouchController.SetBallMargin(margin)
	local touchBall = page and page:FindControl("touchBall")
	if(touchBall and touchBall.parent) then
		touchBall.parent.y = -228-margin
	end
end

function ParaLifeTouchController.SetZorder(zorder)
	if(page) then
		local window = page:GetWindow()
		if(window) then
			local frame = window:GetWindowFrame()
			if(frame) then
				local _parent = frame:GetWindowUIObject()
				if(_parent) then
					_parent.zorder = zorder
				end
			end
		end
	end
end

function ParaLifeTouchController.ShowPage(bShow)
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeTouchController.html", 
			name = "ParaLifeTouchController.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			zorder = -20;
			bShow = bShow~=false,
			click_through = true, 
			cancelShowAnimation = true,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ParaLifeTouchController.TurnPlayerHeadToCursor(event)
	local turnPlayerHeadToCursor;
	if(event.touchSession) then
		if(event:GetType() == "mousePressEvent" or not ParaLifeTouchController.lastPlayerHeadSession or ParaLifeTouchController.lastPlayerHeadSession:IsClosed()) then
			ParaLifeTouchController.lastPlayerHeadSession = event.touchSession;
		end
		if(ParaLifeTouchController.lastPlayerHeadSession == event.touchSession) then
			turnPlayerHeadToCursor = true
		end
	else
		turnPlayerHeadToCursor = true
	end
	if(turnPlayerHeadToCursor and event:GetType() ~= "mousePressEvent") then
		GameLogic.GetSceneContext():CheckMousePick(event)
	end
end

-- touch event will be translated to emulated mouse event with event.touchSession. 
-- So we may have multiple mouse event as if there are multiple mouse cursors. 
-- if there is no event.touchSession, it means that the event come from standard mouse cursor. 
function ParaLifeTouchController.handleMouseEvent(event)
	if(not event.isEmulated and not event.touchSession) then
		event:updateModifiers();
		event.isEmulated = true;
	end
	if(ParaLifeTouchController.handleTouchBallEvent(event)) then
		return;
	end
	if(ParaLifeTouchController.handleTwoFingerMoveGestures(event)) then
		return;
	end

	local ctx = GameLogic.GetSceneContext()
	if ctx==nil then
		return
	end
	ctx:handleMouseEvent(event);

	-- try simulate C++ autocamera in script
	if(ctx:IsAutoCameraEnabled()) then
		if(not System.os.options.IsInputDisabled()) then
			CameraController.handleMouseEvent(event)
			ParaLifeTouchController.TurnPlayerHeadToCursor(event)
		end
	end
end

-- @param touchId: if not nil, we will only process all queued touch event for the given touch session,
-- if nil, we will process all queued events for all touch sessions. 
function ParaLifeTouchController.handleAllQueuedTouchEvents(touchId)
	if(touchEvents) then
		local touch = touchEvents:first();
		while (touch) do
			local session = TouchSession.GetExistingTouchSession(touch)
			if(not session) then
				touch = touchEvents:remove(touch)
			elseif(not touchId or touch.id == touchId) then
				ParaLifeTouchController.handleTouchEventImp(touch)
				touch = touchEvents:remove(touch)
			else
				touch = touchEvents:next(touch)
			end
		end
	end
end

local touchEventTimer;

-- one should only add "WM_POINTERUPDATE" to this queue. we will merged all such events.
-- @param newTouch: touch msg
function ParaLifeTouchController.addTouchEventToQueue(newTouch)
	touchEvents = touchEvents or commonlib.List:new();
	if(newTouch.type == "WM_POINTERUPDATE") then
		-- merge all pointer update message into one in the queue, only preserve the most recent one. 
		local touch = touchEvents:first();
		while (touch) do
			if(touch.id == newTouch.id and touch.type=="WM_POINTERUPDATE") then
				touch = touchEvents:remove(touch)
			else
				touch = touchEvents:next(touch)
			end
		end
	end
	touchEvents:add(newTouch);

	-- process it in the next tick frame. 
 	touchEventTimer = touchEventTimer or commonlib.Timer:new({callbackFunc = function(timer)
		ParaLifeTouchController.handleAllQueuedTouchEvents()
	end})
	if(not touchEventTimer:IsEnabled()) then
		touchEventTimer:Change(10);
	end
end

function ParaLifeTouchController.handleTouchEventImp(touch)
	local touchSession = TouchSession.GetTouchSession(touch)
	local event
	if(touch.type == "WM_POINTERDOWN") then
		event = MouseEvent:init("mousePressEvent")
	elseif(touch.type == "WM_POINTERUPDATE") then
		event = MouseEvent:init("mouseMoveEvent")
	elseif(touch.type == "WM_POINTERUP") then
		event = MouseEvent:init("mouseReleaseEvent")
	end
	if(event) then
		--echo({"1111", touch.id, touch})
		event.x, event.y = touch.x, touch.y
		event.touchSession = touchSession;
		-- touch event is always interpreted as mouse left click or drag. 
		event.mouse_button = "left";
		if(touch.type ~= "WM_POINTERUP") then
			event.buttons_state = 1;
		end
		ParaLifeTouchController.handleMouseEvent(event);

		if(touch.type == "WM_POINTERDOWN") then
			touchSession:Connect("touchForceClosed", function()
				if(touchSession.touch) then
					event = MouseEvent:init("mouseReleaseEvent")
					event.x, event.y = touchSession.touch.x, touchSession.touch.y
					event.touchSession = touchSession;
					event.mouse_button = "left";
					ParaLifeTouchController.handleMouseEvent(event);
					LOG.std(nil, "warn", "ParaLifeTouchController", "touchForceClosed detected for %d", touchSession.id or 0);
				end
			end)
		end
	end
end

-- @param touch: like {type="WM_POINTERUPDATE",x=242,y=426,id=0,time=ms}
function ParaLifeTouchController.handleTouchEvent(touch)
	if(touch.type == "WM_POINTERDOWN") then
		ParaLifeTouchController.handleTouchEventImp(touch)
	elseif(touch.type == "WM_POINTERUPDATE") then
		ParaLifeTouchController.addTouchEventToQueue(touch)
	elseif(touch.type == "WM_POINTERUP") then
		ParaLifeTouchController.handleAllQueuedTouchEvents(touch.id)
		ParaLifeTouchController.handleTouchEventImp(touch)
	end
end

------------------
-- drag ball implementations 
------------------

-- @param bIgnoreClosedSession: true to ignore closed session
local function IsDraggingTouchBall(event, bIgnoreClosedSession)
	local isDraggingTouchBall;
	if(event and event.touchSession) then
		if(bIgnoreClosedSession or not event.touchSession:IsClosed()) then
			isDraggingTouchBall = event.touchSession.isDraggingTouchBall;
		end
	else
		isDraggingTouchBall = ParaLifeTouchController.isDraggingTouchBall
	end
	return isDraggingTouchBall
end

-- @return state, dx, dy;
local function GetDirectionFromOffset(dx, dy)
	local rotation = mathlib.GetAngleFromOffset(dx, dy) * 180/math.pi  
	if rotation < 22.5 and rotation >= -22.5 then
		return "Right", 1, 0 
	elseif rotation < -22.5 and rotation >= -67.5 then
		return "DownRight", 1, 1
	elseif rotation < -67.5 and rotation >= -112.5 then
		return "Down", 0, 1
	elseif rotation < -112.5 and rotation >= -157.5 then
		return "DownLeft", -1, 1
	elseif rotation < -157.5 or rotation >= 157.5 then
		return "Left", -1, 0
	elseif rotation < 157.5 and rotation >= 112.5 then
		return "UpLeft", -1, -1
	elseif rotation < 112.5 and rotation >= 67.5 then
		return "Up", 0, -1
	elseif rotation < 67.5 and rotation >= 22.5 then
		return "UpRight", 1, -1
	end
end

local DirectionKey = {
	Up = {"W"},
	Down ={"S"},
	Left = {"A"},
	Right = {"D"},
	UpLeft = {"W","A"},
	UpRight = {"W","D"},
	DownLeft = {"S","A"},
	DownRight = {"S","D"},
}

local DefaultKeyLayout = {
	W = {vKey = DIK_SCANCODE.DIK_W, },
	A = {vKey = DIK_SCANCODE.DIK_A, },
	S = {vKey = DIK_SCANCODE.DIK_S, },
	D = {vKey = DIK_SCANCODE.DIK_D, },
}

local function SendRawKeyEvent(btnItem, isDown)
	if(btnItem.vKey) then
		if((btnItem.isDown and not isDown) or (not btnItem.isDown and isDown)) then
			btnItem.isDown = isDown
			Keyboard:SendKeyEvent(isDown and "keyDownEvent" or "keyUpEvent", btnItem.vKey);
		end
	end
end

-- @param str: such as "UpLeft", one of the DirectionKey keyname. 
local function UpdateMoveKeys(str)
	local keys = DirectionKey[str or ""] or {}
	for w, btn in pairs(DefaultKeyLayout) do
		local hasKey;
		for _, keyName in ipairs(keys) do
			if(keyName == w) then
				hasKey = true;
				break
			end
		end
		SendRawKeyEvent(btn, hasKey)
	end
end


local function HasAnyMoveKeyDown()
	for w, btn in pairs(DefaultKeyLayout) do
		if(btn.isDown) then
			return true;
		end
	end
end

local dragTouchBallTimer;
local keepRollingTimer;
local lastDragballMoveEvent = MouseEvent:new():init("mouseMoveEvent");

-- we are using touch ball to control the player position. 
function ParaLifeTouchController.handleTouchBallEvent(event)
	local touchBall = page and page:FindControl("touchBall")
	if(touchBall) then
		local lastIsDraggingBall = IsDraggingTouchBall(event, true)
		if(event:GetType() == "mousePressEvent") then
			local x, y, width, height = touchBall:GetContainer():GetAbsPosition()
			if(((x+width/2-event.x)^2 + (y + height/2- event.y)^2) < ((width/2)^2)) then
				if(event.touchSession) then
					event.touchSession.isDraggingTouchBall = true;
					ParaLifeTouchController.isDraggingTouchBall = false;
				else
					ParaLifeTouchController.isDraggingTouchBall = true;
				end
				lastDragballMoveEvent.x, lastDragballMoveEvent.y = event.x, event.y
				lastDragballMoveEvent.lastX, lastDragballMoveEvent.lastY = event.x, event.y
				lastDragballMoveEvent.lastTime = commonlib.TimerManager.GetCurrentTime()
				lastDragballMoveEvent.dragSpeed = 0;
			else
				ParaLifeTouchController.isDraggingTouchBall = false;
			end
		elseif(event:GetType() == "mouseReleaseEvent") then
			if(event.touchSession) then
				event.touchSession.isDraggingTouchBall = false;
			else
				ParaLifeTouchController.isDraggingTouchBall = false;
			end
		elseif(event:GetType() == "mouseMoveEvent") then
			if(lastIsDraggingBall) then
				-- repeat last mouse move event. 
				lastDragballMoveEvent.x, lastDragballMoveEvent.y = event.x, event.y
				lastDragballMoveEvent.touchSession = event.touchSession;
				local curTime = commonlib.TimerManager.GetCurrentTime()
				local deltaTime = curTime - (lastDragballMoveEvent.lastTime or 0);
				if(deltaTime > 10) then
					lastDragballMoveEvent.lastTime = curTime
					-- drag speed is usually 0-2500 pixels/sec, the rotation speed is usually less than 500 pixels/sec if the finger stops before releasing. 
					lastDragballMoveEvent.dragSpeed = math.sqrt(((lastDragballMoveEvent.lastX or event.x) - event.x)^2 + ((lastDragballMoveEvent.lastY or event.y) -event.y)^2) / deltaTime*1000
					lastDragballMoveEvent.lastX, lastDragballMoveEvent.lastY = event.x, event.y
				end

				dragTouchBallTimer = dragTouchBallTimer or commonlib.Timer:new({callbackFunc = function(timer)
					if(IsDraggingTouchBall(lastDragballMoveEvent)) then
						ParaLifeTouchController.handleTouchBallEvent(lastDragballMoveEvent)
					elseif(HasAnyMoveKeyDown()) then
						-- this is only called when touch up event is missing for some reason. 
						UpdateMoveKeys()
					end
				end})
				dragTouchBallTimer:Change(10);
			end
		end
		local isDraggingTouchBall = IsDraggingTouchBall(event)

		if(isDraggingTouchBall) then
			ParaLifeTouchController.DoDragMove(event, lastDragballMoveEvent.dragSpeed)
			return true;
		else
			if(lastIsDraggingBall) then
				if((lastDragballMoveEvent.dragSpeed or 0) > 500) then
					-- keep rolling the ball until drag speed is 0. 
					ParaLifeTouchController.DoDragMove(lastDragballMoveEvent, lastDragballMoveEvent.dragSpeed)
					keepRollingTimer = keepRollingTimer or commonlib.Timer:new({callbackFunc = function(timer)
						if(not IsDraggingTouchBall(lastDragballMoveEvent)) then
							lastDragballMoveEvent.dragSpeed = lastDragballMoveEvent.dragSpeed - 30;
							if(lastDragballMoveEvent.dragSpeed > 0) then
								ParaLifeTouchController.DoDragMove(lastDragballMoveEvent, lastDragballMoveEvent.dragSpeed)
								timer:Change(10);
								return
							end
							ParaLifeTouchController.StopDragMove()
						end
					end})
					keepRollingTimer:Change(10);
				else
					ParaLifeTouchController.StopDragMove()
				end
				return true;
			end
		end
	end
end

local dragBallStartX, dragBallStartY;
local dragBallQuaternion

function ParaLifeTouchController.StopDragMove()
	local touchBall = page:FindControl("touchBall")
	if(touchBall) then
		local obj = touchBall:GetObject()
		if(obj) then
			local facing = obj:GetFacing();
			obj:SetField("opacity", defaultBallOpacity);
			UpdateMoveKeys()
		end
	end
end

-- @param x,y,z: ray origin in world space
-- @param dirX, dirY, dirZ: ray direction, default to 0, -1, 0
-- @param maxDistance: default to 10
-- @return entityLiveModel, hitX, hitY, hitZ: return entity live model that is hit by the ray. 
function ParaLifeTouchController.RayPickPhysicalModel(x, y, z, dirX, dirY, dirZ, maxDistance)
	local pt = ParaScene.Pick(x, y, z, dirX or 0, dirY or -1, dirZ or 0, maxDistance or 10, "point")
	if(pt:IsValid())then
		local entityName = pt:GetName();
		if(entityName and entityName~="") then
			local entity = EntityManager.GetEntity(entityName);
			if(entity) then
				local x1, y1, z1 = pt:GetPosition();
				return entity, x1, y1, z1;
			end
		end
	end
end

-- both obstruction block and physical mesh is taken into account. 
function ParaLifeTouchController.CanPlayerStayAtCurrentPosition()
	local context = GameLogic.GetSceneContext()
	if( context and not context:GetTargetPosition()) then
		return true
	else
		local player = EntityManager.GetPlayer();
		if(player) then
			local bx, by, bz = player:GetBlockPos();
			local block = BlockEngine:GetBlock(bx, by, bz)
			if(not block or not block.obstruction) then
				block = BlockEngine:GetBlock(bx, by+1, bz)
				if(not block or not block.obstruction) then
				-- we also need to ensure that there is 4 meters free space above the standing point. 
				local x, y, z = player:GetPosition();
				local entity, x1, y1, z1 = ParaLifeTouchController.RayPickPhysicalModel(x, y+4, z, 0, -1, 0, 10)
				if(entity) then
					if(y1 and math.abs(y-y1) < 0.1) then
						return true
					else
						return false
					end
				end
					return true;
				end
			end
		end
	end
end

-- @param dragSpeed: drag speed is usually 0-2500 pixels/sec, the rotation speed is usually less than 500 pixels/sec if the finger stops before releasing
function ParaLifeTouchController.DoDragMove(event, dragSpeed)
	local touchBall = page:FindControl("touchBall")
	if(touchBall) then
		local dx, dy = 0, 0;
		if(event:GetType() == "mousePressEvent") then
			dragBallStartX, dragBallStartY = event.x, event.y
			dragBallQuaternion = dragBallQuaternion or mathlib.Quaternion:new():identity()
		elseif(dragBallStartX) then
			dx, dy = event.x - dragBallStartX, event.y - dragBallStartY
		end
		local obj = touchBall:GetObject()
		if(obj and dragBallQuaternion and event:GetDragDist() > 5) then
			local canMove = true;
			local disableKeyMovement;
			local moveAngleDelta = -mathlib.GetAngleFromOffset(dx, dy) + math.pi/2;
			local player = EntityManager.GetPlayer()
			local sceneContext = GameLogic.GetSceneContext()
			if(sceneContext and sceneContext:GetTargetPosition()) then
				disableKeyMovement = true
			end
					
			if(player) then
				if(not player:IsVisible()) then
					-- using A* path finding when player is not visible
					disableKeyMovement = true
					if(ParaLifeTouchController.CanPlayerStayAtCurrentPosition()) then
						local fromX, fromY, fromZ = player:GetPosition()
						local facing = GameLogic.RunCommand("/camerayaw") + moveAngleDelta
						local dragDistance = math.sqrt(dx^2 + dy^2)
						local hasSolution, toX, toY, toZ = walkPathGrid:ComputeGridByCenterAndFacing(fromX, fromY, fromZ, facing, 
							ParaLifeTouchController.maxPathFindingSteps, 1, 5)
						if(hasSolution and toX) then
							local speed = dragDistance > 200 and ParaLifeTouchController.dragRunSpeed or ParaLifeTouchController.dragWalkSpeed; -- 5 meters/second
							local dTime = math.sqrt((fromX - toX)^2 + (fromZ - toZ)^2) / speed;
							GameLogic.GetSceneContext():SetTargetPosition(toX, toY, toZ, math.min(0.4, dTime));
						end
					end
				end
			end
			if(canMove) then
				local yaw = obj:GetField("yaw", 0);
				local pitch = obj:GetField("pitch", 0);
				local roll = obj:GetField("roll", 0);
				dragBallQuaternion:FromEulerAnglesSequence(roll,pitch,yaw, "zxy")
				local dir, dx, dy = GetDirectionFromOffset(dx, dy)
				local speed = 0.02 * math.max(1, (dragSpeed or 0)/200);
				if(dx~=0) then
					dragBallQuaternion = mathlib.Quaternion:new():FromAngleAxis(dx > 0 and -speed or speed, mathlib.vector3d.unit_y) * dragBallQuaternion
				end
				if(dy~=0) then
					dragBallQuaternion = mathlib.Quaternion:new():FromAngleAxis(dy > 0 and speed or -speed, mathlib.vector3d.unit_x) * dragBallQuaternion
				end
				roll, pitch, yaw = dragBallQuaternion:ToEulerAnglesSequence("zxy")
				obj:SetField("roll", roll);
				obj:SetField("yaw", yaw);
				obj:SetField("pitch", pitch);
				obj:SetField("opacity", 1);
				if(not disableKeyMovement) then
					UpdateMoveKeys(dir)
				else
					UpdateMoveKeys()
				end
			else
				UpdateMoveKeys()
			end
		end
	end
end


------------------
-- two finger dragging ground to move implementations 
------------------

-- return true if the event is handled as two finger player movement. 
function ParaLifeTouchController.handleTwoFingerMoveGestures(event)
	if(event.touchSession) then
		-- disable movement with two fingers if player is shown, since we will always use touch ball to move instead. 
		local player = EntityManager.GetPlayer()
		if(player:IsVisible()) then
			return;
		end

		local touch_sessions = touch_sessions or TouchSession.GetAllSessions();
		if(event:GetType() == "mousePressEvent" and event.touchSession:IsEnabled()) then
			if(#touch_sessions >= 2) then
				local startTime = event.touchSession:GetStartTime()
				for i, session in ipairs(touch_sessions) do
					-- two finger must be less than 300ms
					if(event.touchSession~=session and math.abs(session:GetStartTime() - startTime) < 300 and session:GetMaxDragDistance() < 5 and not session:IsClosed() and session:IsEnabled()) then
						-- tricky: by disable touch session, we will invalidate any previous drag or auto-camera operations and let the mouse gesture to process this session instead. 
						session:SetEnabled(false); 
						session.twoFingerDrag = event.touchSession.id
						event.touchSession:SetEnabled(false);
						event.touchSession.twoFingerDrag = event.touchSession.id
					end
				end
			end
		end
		if(event.touchSession.twoFingerDrag == event.touchSession.id) then
			local otherSession;
			for i, session in ipairs(touch_sessions) do
				if(session.twoFingerDrag == event.touchSession.id and session~=event.touchSession) then
					otherSession = session
				end
			end
			if(otherSession) then
				-- shall we verify that the two finger's movement path are almost identical, i.e. not a pinch operation 
				local touch1 = event.touchSession;
				local touch2 = otherSession;
				touch2.distance = TouchSession:GetTouchDistanceBetween(touch1:GetCurrentTouch(), touch2:GetCurrentTouch());
				if(not touch2.initialDistance) then
					touch2.initialDistance = touch2.distance
				end
				local sceneContext = GameLogic.GetSceneContext()
				local deltaDistance = touch2.distance - touch2.initialDistance;
				if(math.abs(deltaDistance) < 100 and ParaLifeTouchController.CanPlayerStayAtCurrentPosition()) then
					if(event:GetType() == "mouseMoveEvent") then
						touch1.lastX = touch1.lastX or touch1:GetStartTouch().x;
						touch1.lastY = touch1.lastY or touch1:GetStartTouch().y;
						touch1.lastTime = touch1.lastTime or touch1:GetStartTime()
						local dx, dy = event.x - touch1.lastX, event.y - touch1.lastY;
						-- at least move 5 pixels before we change direction. 
						if(dx^2 + dy^2 > 5^2) then
							touch1.lastTime = touch1:GetLastTickTime();
							touch1.lastX, touch1.lastY = event.x, event.y;
							ParaLifeTouchController.DoTwoFingerMove(dx, dy)
						end
					end
				end
			end
			return true
		end
	end
end

function ParaLifeTouchController.DoTwoFingerMove(dx, dy)
	local player = EntityManager.GetPlayer()
	local touchBall = page:FindControl("touchBall")
	if(not touchBall) then
		return 
	end
	local obj = touchBall:GetObject()
	local fromX, fromY, fromZ = player:GetPosition()
	local moveAngleDelta = mathlib.GetAngleFromOffset(-dx, dy) + math.pi/2;
	local facing = GameLogic.RunCommand("/camerayaw") + moveAngleDelta

	local maxDist = 5;
	local blocksPerPixel = 0.05; -- move speed
	local minDist = math.min(maxDist, math.sqrt(dx^2 + dy^2)*blocksPerPixel);
	
	-- using A* path finding
	local hasSolution, toX, toY, toZ = walkPathGrid:ComputeGridByCenterAndFacing(fromX, fromY, fromZ, facing, 
		ParaLifeTouchController.maxPathFindingSteps, minDist, maxDist)
	if(obj and hasSolution and toX) then
		local speed = ParaLifeTouchController.twoFingerDragSpeed;
		local dTime = math.sqrt((fromX - toX)^2 + (fromZ - toZ)^2) / speed;
		dTime = math.min(0.1, dTime);
		GameLogic.GetSceneContext():SetTargetPosition(toX, toY, toZ, dTime);
		
		local yaw = obj:GetField("yaw", 0);
		local pitch = obj:GetField("pitch", 0);
		local roll = obj:GetField("roll", 0);
		dragBallQuaternion = dragBallQuaternion or mathlib.Quaternion:new():identity()
		dragBallQuaternion:FromEulerAnglesSequence(roll,pitch,yaw, "zxy")
		local dir, dx, dy = GetDirectionFromOffset(dx, dy)
		local speed = 0.02 * 3;
		if(dx~=0) then
			dragBallQuaternion = mathlib.Quaternion:new():FromAngleAxis(dx < 0 and -speed or speed, mathlib.vector3d.unit_y) * dragBallQuaternion
		end
		if(dy~=0) then
			dragBallQuaternion = mathlib.Quaternion:new():FromAngleAxis(dy < 0 and speed or -speed, mathlib.vector3d.unit_x) * dragBallQuaternion
		end
		roll, pitch, yaw = dragBallQuaternion:ToEulerAnglesSequence("zxy")
		obj:SetField("roll", roll);
		obj:SetField("yaw", yaw);
		obj:SetField("pitch", pitch);
		obj:SetField("opacity", 1);
	end
end