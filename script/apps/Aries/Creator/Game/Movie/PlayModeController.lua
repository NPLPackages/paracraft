--[[
Title: A special movie controller
Author(s): LiXizhi
Date: 2015/1/13
Desc: only shown when in read-only play mode. 
We can rotate the camera while playing, once untouched, camera returned to original position. 
TODO: in future we may add pause/resume/stop for currently playing movie in theater mode?
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/PlayModeController.lua");
local PlayModeController = commonlib.gettable("MyCompany.Aries.Game.Movie.PlayModeController");
PlayModeController:InitSingleton();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/KeyFrameCtrl.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/ToolTouchBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/CameraController.lua");
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");

local PlayModeController = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Tools.ToolTouchBase"), commonlib.gettable("MyCompany.Aries.Game.Movie.PlayModeController"));
PlayModeController:Property("Name", "PlayModeController");
-- whether to show touch track. 
PlayModeController:Property("ShowTouchTrack", false);
-- whether to allow selecting multiple blocks. 
PlayModeController:Property("AllowMultiSelection", false);

-- default to 300 ms. 
PlayModeController.min_hold_time = 300;
-- default to 30 pixels
PlayModeController.finger_size = 30;
-- the smaller, the smoother. value between (0,1]. 1 is without smoothing. 
PlayModeController.camera_smoothness = 0.4;

function PlayModeController:ctor()
	self:LoadGestures();
end

function PlayModeController.ShowPage(bShow)
	if(bShow == PlayModeController:IsVisible()) then
		return;
	end

	local params = {
			url = "script/apps/Aries/Creator/Game/Movie/PlayModeController.html", 
			name = "PC.PlayModeController", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = false,
			bShow = bShow,
			zorder = -9,
			-- click_through = false, 
			cancelShowAnimation = true,
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

local page;
function PlayModeController.OnInit()
	page = document:GetPageCtrl();
end

function PlayModeController:OnPostLoad()
	local _this = page:FindUIControl("touch_scene");
	if(_this) then
		_this:SetScript("onmousedown", function() self:OnMouseDown(); end);
		_this:SetScript("onmouseup", function() self:OnMouseUp(); end);
		_this:SetScript("onmousemove", function() self:OnMouseMove(); end);
	end
end

function PlayModeController.OnTouch(name, mcmlNode, touch)
	PlayModeController.mouse_touch_session = nil;
	PlayModeController:OnTouchScene(touch);
end

-- simulate the touch event
function PlayModeController:OnMouseDown()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchSession.lua");
	local TouchSession = commonlib.gettable("MyCompany.Aries.Game.Common.TouchSession")
	self.mouse_touch_session = TouchSession:new();
	self.mouse_touch_session:OnTouchEvent({type="WM_POINTERDOWN", x=mouse_x, y=mouse_y});
	self:handleTouchSessionDown(self.mouse_touch_session);
end

-- simulate the touch event
function PlayModeController:OnMouseUp()
	if(self.mouse_touch_session) then
		local touch = {type="WM_POINTERUP", x=mouse_x, y=mouse_y};
		self.mouse_touch_session:OnTouchEvent(touch);
		self:handleTouchSessionUp(self.mouse_touch_session, touch);
		self.mouse_touch_session = nil;
	end
end

-- simulate the touch event
function PlayModeController:OnMouseMove()
	if(self.mouse_touch_session) then
		self.mouse_touch_session:OnTouchEvent({type="WM_POINTERUPDATE", x=mouse_x, y=mouse_y});
		self:handleTouchSessionMove(self.mouse_touch_session);
	end
end

-- whether the page is visible. 
function PlayModeController:IsVisible()
	return if_else(page and page:IsVisible(), true, false);
end

-- when the game movie mode is changed
function PlayModeController:OnModeChanged(mode)
	if(mode == "movie" and not MovieManager:IsLastModeEditor()) then
		--LOG.std(nil, "info", "PlayModeController", "enter")
		PlayModeController.ShowPage(true);
	else
		--LOG.std(nil, "info", "PlayModeController", "leave")
		PlayModeController.ShowPage(false);
		self:RestoreCamera();
	end
end

function PlayModeController:LoadGestures()
	-- register pinch gesture
	NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchGesturePinch.lua");
	local TouchGesturePinch = commonlib.gettable("MyCompany.Aries.Game.Common.TouchGesturePinch")
	local gesture_pinch = TouchGesturePinch:new({OnGestureRecognized = function(pinch_gesture)
		if(not GameLogic.IsFPSView) then
			-- only for third person view
			if(math.abs(pinch_gesture:GetDeltaDistance()) > 20) then
				-- zoom in/out one step every 20 pixels
				pinch_gesture:ResetLastDistance();
				if(pinch_gesture:GetPinchMode() == "open") then
					-- CameraController.ZoomInOut(true);
				else
					-- CameraController.ZoomInOut(false);
				end
			end
			return true;
		end
	end});
	self:RegisterGestureRecognizer(gesture_pinch);
end

function PlayModeController:handleTouchSessionDown(touch_session, touch)
	self.camera_start = touch_session;
	self:RotateCamera();
end

-- rotate camera 
function PlayModeController:handleTouchSessionMove(touch_session, touch)
	if(self.camera_start == touch_session) then
		self:RotateCamera(touch_session);
	end
end

-- rotate the camera based on delta in the touch_session. 
function PlayModeController:RotateCamera(touch_session)
	if(touch_session and self.liftup and self.rot_y) then
		local InvertMouse = GameLogic.options:GetInvertMouse();
		-- the bigger, the more precision. 
		local camera_sensitivity = GameLogic.options:GetSensitivity()*1000+10;
		local delta_x, delta_y = touch_session:GetOffsetFromStartLocation();
		
		if(delta_x~=0) then
			self.targetCameraYaw = self.rot_y - (delta_x) / camera_sensitivity * if_else(InvertMouse, 1, -1);
		end
		if(delta_y~=0) then
			local liftup = self.liftup - delta_y / camera_sensitivity * if_else(InvertMouse, 1, -1);
			self.targetCameraPitch = math.max(-1.57, math.min(liftup, 1.57));
		end
	else
		local yaw, pitch, roll = CameraController:GetAdditionalCameraRotate();
		self.rot_y = yaw;
		self.preCameraYaw = self.rot_y;
		self.liftup = pitch;
		self.preCameraPitch = self.liftup;
		self.targetCameraPitch = nil;
		self.targetCameraYaw = nil;
		self.camera_timer = self.camera_timer or commonlib.Timer:new({callbackFunc = function(timer)
			self:OnTickCamera(timer);
		end})
		self.camera_timer:Change(0.0166, 0.0166);
	end
end

function PlayModeController:OnTickCamera(timer)
	local bCameraReached = true;
	if(self.preCameraYaw ~= self.targetCameraYaw and self.preCameraYaw and self.targetCameraYaw) then
		-- smoothing
		self.cameraYaw = self.preCameraYaw + (self.targetCameraYaw - self.preCameraYaw) * self.camera_smoothness;
		if(math.abs(self.targetCameraYaw - self.cameraYaw) < 0.001) then
			self.cameraYaw = self.targetCameraYaw;
		else
			bCameraReached = false;
		end
		CameraController:SetAdditionalCameraRotate(-self.cameraYaw, nil, nil);
		self.preCameraYaw = self.cameraYaw;
	end
	if(self.targetCameraPitch ~= self.preCameraPitch and self.targetCameraPitch and self.preCameraPitch) then
		-- smoothing
		self.cameraPitch = self.preCameraPitch + (self.targetCameraPitch - self.preCameraPitch) * self.camera_smoothness;
		if(math.abs(self.targetCameraPitch - self.cameraPitch) < 0.001) then
			self.cameraPitch = self.targetCameraPitch;
		else
			bCameraReached = false;
		end
		CameraController:SetAdditionalCameraRotate(nil, -self.cameraPitch, nil);
		self.preCameraPitch = self.cameraPitch;
	end
	if(bCameraReached and not self.camera_start) then
		timer:Change(nil);
	end
end

function PlayModeController:RestoreCamera()
	-- TODO: smoothly move back
	CameraController:SetAdditionalCameraRotate(0,0,0);
	if(self.camera_timer) then
		self.camera_timer:Change(nil);
	end
end

function PlayModeController:handleTouchSessionUp(touch_session, touch)
	self:RestoreCamera();
	self.camera_start = nil;
	self.liftup = nil;
	self.rot_y = nil;
	self.pre_liftup = 0;
	self.pre_rot_y = 0;
end