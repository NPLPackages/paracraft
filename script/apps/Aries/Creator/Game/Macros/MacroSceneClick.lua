--[[
Title: Macro Scene Click
Author(s): LiXizhi
Date: 2021/1/4
Desc: a macro for the clicking and draging in the 3d scene context. 

Use Lib:
-------------------------------------------------------
GameLogic.Macros:AddMacro("SceneClick", GameLogic.Macros.GetButtonTextFromClickEvent(event), GameLogic.Macros.GetSceneClickParams())

local mousePressEvent = GameLogic.Macros:GetLastMousePressEvent()
local startAngleX, startAngleY = GameLogic.Macros.GetSceneClickParams(mousePressEvent.x, mousePressEvent.y)
local endAngleX, endAngleY = GameLogic.Macros.GetSceneClickParams()
GameLogic.Macros:AddMacro("SceneDrag", GameLogic.Macros.GetButtonTextFromClickEvent(event), startAngleX, startAngleY, endAngleX, endAngleY)

-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Mouse.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
NPL.load("(gl)script/ide/System/Core/SceneContextManager.lua");
NPL.load("(gl)script/ide/System/Windows/MouseEvent.lua");
NPL.load("(gl)script/ide/System/Scene/Cameras/Cameras.lua");
local MacroPlayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroPlayer");
local Cameras = commonlib.gettable("System.Scene.Cameras");
local MouseEvent = commonlib.gettable("System.Windows.MouseEvent");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local SceneContextManager = commonlib.gettable("System.Core.SceneContextManager");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local Screen = commonlib.gettable("System.Windows.Screen");
local Mouse = commonlib.gettable("System.Windows.Mouse");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")


-- @return angleX, angleY: angle offset from the center
function Macros.GetSceneClickParams(mouse_x, mouse_y)
	if(not mouse_x) then
		mouse_x, mouse_y = Mouse:GetMousePosition()
	end
	local viewParams = Macros:GetViewportParams()
	
	return (mouse_x / viewParams.screenWidth * 2 - 1) * viewParams.fov * viewParams.aspectRatio * 0.5, (mouse_y /viewParams.screenHeight * 2 - 1) * (viewParams.fov) * 0.5;
end

-- @param event: mouse event object
-- @return string like "shift+ctrl+left", "left"
function Macros.GetButtonTextFromClickEvent(event)
	local buttons = event.mouse_button or "";
	if(event.ctrl_pressed) then
		buttons = "ctrl+"..buttons;
	end
	if(event.alt_pressed) then
		buttons = "alt+"..buttons;
	end
	if(event.shift_pressed) then
		buttons = "shift+"..buttons;
	end
	return buttons;
end

local function SetMouseEventFromButtonText(event, button)
	-- mouse_button is a global variable
	event.isEmulated= true;
	event.shift_pressed = button and button:match("shift") and true 
	event.alt_pressed = button and button:match("alt") and true
	event.ctrl_pressed = button and button:match("ctrl") and true
	if(button and button:match("left") ) then
		event.buttons_state = 1;
		event.mouse_button = "left"
	elseif(button and button:match("right") ) then
		event.buttons_state = 2;
		event.mouse_button = "right"
	elseif(button and button:match("middle") ) then
		event.buttons_state = 0;
		event.mouse_button = "middle"
	else
		event.buttons_state = 0;
	end
end

local function SetKeyboardFromButtonText(emulatedKeys, button)
	-- mouse_button is a global variable
	emulatedKeys.shift_pressed = button and button:match("shift") and true 
	emulatedKeys.alt_pressed = button and button:match("alt") and true
	emulatedKeys.ctrl_pressed = button and button:match("ctrl") and true
end

function Macros.MouseAngleToScreenPos(angleX, angleY, button)
	local viewport = ViewportManager:GetSceneViewport();
	local curScreenWidth, curScreenHeight = Screen:GetWidth()-viewport:GetMarginRight(), Screen:GetHeight() - viewport:GetMarginBottom();

	local curFov = Cameras:GetCurrent():GetFieldOfView()
	local curAspectRatio = Cameras:GetCurrent():GetAspectRatio()
	
	local mouse_x, mouse_y, mouse_button;
	mouse_x = math.floor(angleX / (curFov * curAspectRatio  / 2) * (curScreenWidth / 2) + (curScreenWidth / 2) + 0.5);
	mouse_y = math.floor(angleY / (curFov / 2) * (curScreenHeight / 2) + (curScreenHeight / 2) + 0.5);
	
	if(button) then
		if(button:match("left")) then
			mouse_button = "left"
		elseif(button:match("right")) then
			mouse_button = "right"
		elseif(button:match("middle")) then
			mouse_button = "middle"
		end
	end
	return mouse_x, mouse_y, mouse_button;
end

--@param mouse_button: "left", "right", default to "left", such as "ctrl+left"
--@param angleX, angleY
function Macros.SceneClick(button, angleX, angleY)
	Macros.PrepareLastCameraView()
	-- mouse_x, mouse_y, mouse_button are global variables
	mouse_x, mouse_y, mouse_button = Macros.MouseAngleToScreenPos(angleX, angleY, button)
	ParaUI.SetMousePosition(mouse_x, mouse_y);

	local event = MouseEvent:init("mousePressEvent");
	SetMouseEventFromButtonText(event, button)
	local ctx = GameLogic.GetSceneContext()
	ctx:handleMouseEvent(event);

	local event = MouseEvent:init("mouseReleaseEvent");
	event.dragDist = 0;
	SetMouseEventFromButtonText(event, button)
	ctx:handleMouseEvent(event);
	
	return Macros.Idle(1);
end

-- mouse drag
function Macros.SceneDrag(button, startAngleX, startAngleY, endAngleX, endAngleY, duration)
	Macros.PrepareLastCameraView()
	local emulatedKeys = Keyboard:GetEmulatedKeys()
	SetKeyboardFromButtonText(emulatedKeys, button)
	if(Keyboard:IsAltKeyPressed() or Keyboard:IsCtrlKeyPressed() or Keyboard:IsShiftKeyPressed()) then
		Macros.KeyPress(button)
	end
	local callback = {};

	commonlib.TimerManager.SetTimeout(function()
		mouse_x, mouse_y, mouse_button = Macros.MouseAngleToScreenPos(startAngleX, startAngleY, button)
		ParaUI.SetMousePosition(mouse_x, mouse_y);
		local event = MouseEvent:init("mousePressEvent");
		SetMouseEventFromButtonText(event, button)
		local ctx = GameLogic.GetSceneContext()
		ctx:handleMouseEvent(event);

		local startX, startY = mouse_x, mouse_y;
		local endX, endY, endMouseButton = Macros.MouseAngleToScreenPos(endAngleX, endAngleY)

		local ticks = 0;
		local pixelDist = math.sqrt((startX - endX)^2 + (startY - endY)^2)
		-- 200 pixels per seconds at most. 
		local totalTicks = math.max( math.floor(pixelDist / 200)*30,  30);
		
		local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			ticks = ticks + 1;
			if(ticks <= totalTicks) then
				mouse_button = endMouseButton;
				local ratio = math.min(1, ticks / totalTicks);
				mouse_x = math.floor(startX * (1 - ratio) + endX * ratio + 0.5)
				mouse_y = math.floor(startY * (1 - ratio) + endY * ratio + 0.5)
				ParaUI.SetMousePosition(mouse_x, mouse_y);
				local event = MouseEvent:init("mouseMoveEvent");
				SetMouseEventFromButtonText(event, button)
				SetKeyboardFromButtonText(emulatedKeys, button)
				local ctx = GameLogic.GetSceneContext()
				ctx:handleMouseEvent(event);
				timer:Change(33);
			elseif(ticks == (totalTicks + 1)) then
				mouse_x, mouse_y, mouse_button = endX, endY, endMouseButton
				ParaUI.SetMousePosition(mouse_x, mouse_y);
				local event = MouseEvent:init("mouseReleaseEvent");
				SetMouseEventFromButtonText(event, button)
				SetKeyboardFromButtonText(emulatedKeys, button)
				local ctx = GameLogic.GetSceneContext()
				ctx:handleMouseEvent(event);

				timer:Change(200);
			else
				-- clear all keyboard emulations
				SetKeyboardFromButtonText(emulatedKeys, "")
				if(callback.OnFinish) then
					callback.OnFinish();
				end
			end
		end})
		mytimer:Change(33)
	end, 100)

	
	return callback;
end


--@param mouse_button: "left", "right", default to "left", such as "ctrl+left"
--@param angleX, angleY
-- @return nil or {OnFinish=function() end}
function Macros.SceneClickTrigger(button, angleX, angleY)
	Macros.PrepareLastCameraView()
	local mouseX, mouseY = Macros.MouseAngleToScreenPos(angleX, angleY, button)

	local callback = {};
	MacroPlayer.SetClickTrigger(mouseX, mouseY, button, function()
		if(callback.OnFinish) then
			callback.OnFinish();
		end
	end);
	return callback;
end

function Macros.SceneDragTrigger(button, startAngleX, startAngleY, endAngleX, endAngleY)
	Macros.PrepareLastCameraView()
	local startX, startY = Macros.MouseAngleToScreenPos(startAngleX, startAngleY)
	local endX, endY = Macros.MouseAngleToScreenPos(endAngleX, endAngleY)

	local callback = {};
	MacroPlayer.SetDragTrigger(startX, startY, endX, endY, button, function()
		if(callback.OnFinish) then
			callback.OnFinish();
		end
	end);
	return callback;
end
