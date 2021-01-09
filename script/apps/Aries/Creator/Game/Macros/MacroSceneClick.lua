--[[
Title: Macro Scene Click
Author(s): LiXizhi
Date: 2021/1/4
Desc: a macro for the clicking of a named button in GUI. 

Use Lib:
-------------------------------------------------------
GameLogic.Macros:AddMacro("SceneClick", GameLogic.Macros.GetButtonTextFromClickEvent(event), GameLogic.Macros.GetSceneClickParams())
-------------------------------------------------------
]]
-------------------------------------
-- single Macro base
-------------------------------------
NPL.load("(gl)script/ide/System/Windows/Mouse.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
NPL.load("(gl)script/ide/System/Core/SceneContextManager.lua");
NPL.load("(gl)script/ide/System/Windows/MouseEvent.lua");
NPL.load("(gl)script/ide/System/Scene/Cameras/Cameras.lua");
local Cameras = commonlib.gettable("System.Scene.Cameras");
local MouseEvent = commonlib.gettable("System.Windows.MouseEvent");
local SceneContextManager = commonlib.gettable("System.Core.SceneContextManager");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local Screen = commonlib.gettable("System.Windows.Screen");
local Mouse = commonlib.gettable("System.Windows.Mouse");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")

-- @return angleX, angleY: angle offset from the center
function Macros.GetSceneClickParams()
	local mouse_x, mouse_y = Mouse:GetMousePosition()

	local viewport = ViewportManager:GetSceneViewport();
	local screenWidth, screenHeight = Screen:GetWidth()-viewport:GetMarginRight(), Screen:GetHeight() - viewport:GetMarginBottom();

	local camobjDist, LiftupAngle, CameraRotY = ParaCamera.GetEyePos();
	local lookatX, lookatY, lookatZ = ParaCamera.GetLookAtPos();

	local fov = Cameras:GetCurrent():GetFieldOfView()
	local aspectRatio = Cameras:GetCurrent():GetAspectRatio()
	
	return (mouse_x / screenWidth * 2 - 1) * fov * aspectRatio * 0.5, (mouse_y /screenHeight * 2 - 1) * (fov) * 0.5;
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
	event.shift_pressed = button:match("shift") and true 
	event.alt_pressed = button:match("alt") and true
	event.ctrl_pressed = button:match("ctrl") and true
end

--@param mouse_button: "left", "right", default to "left", such as "ctrl+left"
--@param angleX, angleY
function Macros.SceneClick(button, angleX, angleY)
	local viewport = ViewportManager:GetSceneViewport();
	local curScreenWidth, curScreenHeight = Screen:GetWidth()-viewport:GetMarginRight(), Screen:GetHeight() - viewport:GetMarginBottom();

	local curFov = Cameras:GetCurrent():GetFieldOfView()
	local curAspectRatio = Cameras:GetCurrent():GetAspectRatio()
	
	-- mouse_x and mouse_y are global variable
	mouse_x = math.floor(angleX / (curFov * curAspectRatio  / 2) * (curScreenWidth / 2) + (curScreenWidth / 2));
	mouse_y = math.floor(angleY / (curFov / 2) * (curScreenHeight / 2) + (curScreenHeight / 2));
	ParaUI.SetMousePosition(mouse_x, mouse_y);
	-- mouse_button is a global variable
	if(button:match("left")) then
		mouse_button = "left"
	elseif(button:match("right")) then
		mouse_button = "right"
	elseif(button:match("middle")) then
		mouse_button = "middle"
	end

	local event = MouseEvent:init("mouseMoveEvent");
	SetMouseEventFromButtonText(event, button)
	local ctx = GameLogic.GetSceneContext()
	ctx:mousePressEvent(event);

	local event = MouseEvent:init("mouseReleaseEvent");
	event.dragDist = 0;
	SetMouseEventFromButtonText(event, button)
	ctx:mouseReleaseEvent(event);
	return Macros.Idle(1);
end





