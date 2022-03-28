--[[
Title: Camera Controller
Author(s): LiXizhi
Date: 2012/11/30
Desc: First person/Third person/View Bobbing, etc. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/CameraController.lua");
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/Desktop/GUIHelper/ClickToContinue.lua");
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/StereoVisionController.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/RemoteWorld.lua");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local StereoVisionController = commonlib.gettable("MyCompany.Aries.Game.StereoVisionController")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local CreatorDesktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.CreatorDesktop");
local vector3d = commonlib.gettable("mathlib.vector3d");
local ClickToContinue = commonlib.gettable("MyCompany.Aries.Desktop.GUIHelper.ClickToContinue");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local Cameras = commonlib.gettable("System.Scene.Cameras");
local RemoteWorld = commonlib.gettable('MyCompany.Aries.Creator.Game.Login.RemoteWorld')
local RailCarPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RailCar/RailCarPage.lua")

---------------------------
-- create class
---------------------------
local CameraController = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.CameraController"));
CameraController:Property("Name", "CameraController");

CameraController:Signal("modeChanged")

local eye_pos = {0,0,0};
local lookat_pos = {0,0,0};

local CameraModes = {
	ThirdPersonFreeLooking = 0,
	FirstPerson = 1,
	ThirdPersonLookCamera = 2,
}

local camera_mode = CameraModes.ThirdPersonFreeLooking;

-- if camera object distance is smaller than this value, the character will always face the lookat position
-- rather than the mouse picking point. 
local disable_facing_mouse_dist = 3;

-- default to false, whether to always rotation camera when mouse move. 
-- if false, only rotate camera when right button is held. 
CameraController.IsAlwaysRotateCameraWhenFPS = true;

local camera = {prevPosX=0, prevPosY=0, prevPosZ=0, distanceWalkedModified=0, prevDistanceWalkedModified=0, last_roll=0, roll = 0, dist = 0, last_bobbing_amount = 0, last_pitch=0}

-- temporary params. do not use it externally. 
local camera_params = {};

function CameraController.OnInit()
	CameraController:InitSingleton();
	Cameras:GetCurrent():EnableCameraFrameMove(false)
	local attr = ParaCamera.GetAttributeObject();
	if(GameLogic.options.CharacterLookupBoneIndex) then
		attr:SetField("CharacterLookupBoneIndex", GameLogic.options.CharacterLookupBoneIndex);
	end
	attr:SetField("On_FrameMove", ";MyCompany.Aries.Game.GameLogic.OnCameraFrameMove();");
	
	attr:SetField("MaxAllowedYShift", GameLogic.options.MaxAllowedYShift or 0);
	attr:SetField("CameraRollbackSpeed", GameLogic.options.CameraRollbackSpeed or 6);
	-- "EnableMouseLeftDrag" boolean attribute is added to ParaCamera.
	attr:SetField("EnableMouseLeftDrag", GameLogic.options.isMouseLeftDragEnabled == true);

	CameraController.InitRailCarCameraData()
end

function CameraController.InitRailCarCameraData()
	CameraController.RailCarCameraMod = {
		lock_first_person = {mod_func = CameraController.LockRailCarFirstPersonView},
		lock_surround = {mod_func = CameraController.LockRailCarSurroundView},
		lock_fixed = {mod_func = CameraController.LockRailCarFixedView},
		lock_movie_view = {mod_func = CameraController.LockRailCarMovieView},
	}

	GameLogic.GetFilters():add_filter("SyncWorldFinish", CameraController.OnSyncWorldFinish);
end

function CameraController.OnExit()
	local attr = ParaCamera.GetAttributeObject();
	attr:SetField("EnableMouseWheel", true);
	attr:SetField("IsShiftMoveSwitched", false);
	attr:SetField("MaxAllowedYShift", 0);
	if(ClickToContinue.Hide) then
		ClickToContinue.Hide();
	end
	if(CameraController.FPS_MouseTimer) then
		CameraController.FPS_MouseTimer:Change();
	end
end


function CameraController.ToggleFly(isFlying)
	if(isFlying) then
		ParaCamera.GetAttributeObject():SetField("MaxAllowedYShift", 0);
	else
		ParaCamera.GetAttributeObject():SetField("MaxAllowedYShift", GameLogic.options.MaxAllowedYShift or 0);
	end
end

local fps_ui_mode_apps = {};
function CameraController.SetFPSMouseUIMode(bUIMode, keyname)
	if(bUIMode) then
		fps_ui_mode_apps[keyname or ""] = true
	else
		fps_ui_mode_apps[keyname or ""] = nil;
	end
end

-- on FPS mouse timer, check if there is any window displayed, if so unlock the mouse, otherwise lock the mouse and set to center. 
function CameraController.OnFPSMouseTimer()
	local bAppHasFocus = ParaEngine.GetAttributeObject():GetField("AppHasFocus", true);
	if(bAppHasFocus) then
		
		local att = ParaCamera.GetAttributeObject();
		local state = System.GetState();
		-- if there is any window that require esc key, unlock the mouse
		if(type(state) == "table" and state.OnEscKey~=nil or CreatorDesktop.IsExpanded or next(fps_ui_mode_apps)) then
			-- unlock mouse if any top level window is there
			ParaUI.ShowCursor(true);
			ParaUI.LockMouse(false);
			ParaUI.GetUIObject("FPS_Cursor").visible = false;
			att:SetField("IsAlwaysRotateCameraWhenFPS", false);
		else
			-- lock mouse if no top level window is there
			ParaUI.ShowCursor(false);
			if(not System.options.IsMobilePlatform) then
				ParaUI.LockMouse(true);
				local root_ = ParaUI.GetUIObject("root");
				local _, _, width_screen, height_screen = root_:GetAbsPosition();
				root_:SetField("MousePosition", {width_screen / 2, height_screen / 2});
				ParaUI.GetUIObject("FPS_Cursor").visible = not (GameLogic.GameMode:IsViewMode());
				if(CameraController.IsAlwaysRotateCameraWhenFPS) then
					att:SetField("IsAlwaysRotateCameraWhenFPS", true);
				end
			end
		end
	end
end

-- whether we are at FPS view
function CameraController.IsFPSView()
	return GameLogic.IsFPSView;
end

function CameraController:SetMode(mode)
	if(camera_mode ~= mode) then
		camera_mode = mode;
		self:modeChanged();
	end
end
function CameraController:GetMode()
	return camera_mode;
end

-- may also toggle UI. 
-- toggle between 3 modes
-- @param IsFPSView: nil to toggle, otherwise to set
function CameraController.ToggleCamera(IsFPSView)	
	if CameraController.cur_railcar_camera_mod then
		CameraController.SetRailCarCameraMod(nil)
		RailCarPage.SelectType()
		IsFPSView = false
	end

	local self = CameraController;
	if(IsFPSView == nil) then
		self:SetMode((CameraController:GetMode()+1)%3);
		IsFPSView = CameraController:GetMode() == CameraModes.FirstPerson;
	else
		if(IsFPSView) then
			self:SetMode(CameraModes.FirstPerson);
		else
			self:SetMode(CameraModes.ThirdPersonFreeLooking);
		end
	end

	GameLogic.IsFPSView = IsFPSView;
	local att = ParaCamera.GetAttributeObject();
	if(IsFPSView) then
		-- eye position is 1.5 meters
		att:SetField("MaxCameraObjectDistance", 0.3);
		att:SetField("NearPlane", 0.1);
		-- att:SetField("FieldOfView", 60/180*3.1415926)

		--att:SetField("MoveScaler", 5);
		att:SetField("RotationScaler", 0.0025);
		--att:SetField("TotalDragTime", 5)
		--att:SetField("SmoothFramesNum", 8)

		att:SetField("IsShiftMoveSwitched", true);
		
		att:SetField("EnableMouseWheel", false);
		

		ParaScene.GetPlayer():SetDensity(1);

		if(CameraController.IsAlwaysRotateCameraWhenFPS) then
			if(not System.options.IsMobilePlatform) then
				att:SetField("IsAlwaysRotateCameraWhenFPS", true);
				ParaUI.ShowCursor(false);
				ParaUI.LockMouse(true);
				local root_ = ParaUI.GetUIObject("root")
				local _, _, width_screen, height_screen = root_:GetAbsPosition();
				root_:GetAttributeObject():SetField("MousePosition", {width_screen / 2, height_screen / 2});
				local _this = ParaUI.GetUIObject("FPS_Cursor");
				if(not _this:IsValid())then
					local _this = ParaUI.CreateUIObject("button", "FPS_Cursor", "_ct", 0, 0, 32, 32);
					local cursor = GameLogic.options.fps_cursor;
					_this.background = cursor.file;
					_this.x = -cursor.hot_x;
					_this.y = -cursor.hot_y;
			
					_this.enabled = false;
					_guihelper.SetUIColor(_this, "#ffffffff");

					local scene_viewport_center = false;
					if(scene_viewport_center) then
						NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
						local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
						local viewport = ViewportManager:GetSceneViewport();
						local parent = viewport:GetUIObject(true)
						parent:AddChild(_this);
					else
						_this:AttachToRoot();
					end
				end
			
				if( GameLogic.GameMode:IsMovieMode()) then
					_this.visible = false;
				else
					_this.visible = true;
				end
			end
		end
		if(not System.options.IsMobilePlatform) then
			CameraController.FPS_MouseTimer = CameraController.FPS_MouseTimer or commonlib.Timer:new({callbackFunc = CameraController.OnFPSMouseTimer})
			CameraController.FPS_MouseTimer:Change(500,500);
		end
	else
		-- external camera view.
		att:SetField("MaxCameraObjectDistance", 26);
		att:SetField("IsAlwaysRotateCameraWhenFPS", false);
		att:SetField("CameraObjectDistance", 8);
		att:SetField("NearPlane", 0.1);
		--att:SetField("FieldOfView", 60/180*3.1415926)

		--att:SetField("MoveScaler", 5);
		att:SetField("RotationScaler", 0.01);
		--att:SetField("TotalDragTime", 0.5)
		--att:SetField("SmoothFramesNum", 2)
		att:SetField("EnableMouseWheel", false);

		att:SetField("IsShiftMoveSwitched", true);
		ParaScene.GetPlayer():SetDensity(GameLogic.options.NormalDensity);
		ParaUI.ShowCursor(true);
		ParaUI.LockMouse(false);
		local _this = ParaUI.GetUIObject("FPS_Cursor");
		if(_this:IsValid())then
			_this.visible = false;
		end
		if(CameraController.FPS_MouseTimer) then
			CameraController.FPS_MouseTimer:Change();
		end
	end
end

-- toggle with last fov and the given gov
function CameraController.ToggleFov(fov, speed_fov)
	local self = CameraController;
	local cur_fov = self.target_fov or GameLogic.options.normal_fov;
	if(cur_fov == fov) then
		CameraController.AnimateFieldOfView(self.last_fov or GameLogic.options.normal_fov, speed_fov);
	else
		self.last_fov = cur_fov;
		CameraController.AnimateFieldOfView(fov, speed_fov);
	end
end

-- animate to a target field of view
function CameraController.AnimateFieldOfView(target_fov, speed_fov)
	local self = CameraController;
	self.target_fov = target_fov;
	if(ParaCamera.GetAttributeObject():GetField("FieldOfView", GameLogic.options.normal_fov) ~= target_fov) then
		if(speed_fov and (speed_fov<0 or speed_fov>=100)) then
			ParaCamera.GetAttributeObject():SetField("FieldOfView", target_fov);
		else
			self.fov_timer = self.fov_timer or commonlib.Timer:new({callbackFunc = function(timer)
				local target_fov = self.target_fov;
				local att = ParaCamera.GetAttributeObject();
				local old_fov = att:GetField("FieldOfView", GameLogic.options.normal_fov);
				local fov;
				local delta = timer:GetDelta()/1000 * (speed_fov or GameLogic.options.speed_fov);
				if(target_fov > old_fov) then
					fov = old_fov + delta;
				else
					fov = old_fov - delta;
				end
				if(math.abs(target_fov - old_fov) <= delta) then
					fov = target_fov;
					timer:Change();
				end
				att:SetField("FieldOfView", fov);
			end})
			self.fov_timer:Change(0, 30);
		end
	end
end

-- check to see if the camera has collided with any physical faces. 
-- we will possibly disable viewbobbing in such cases. 
function CameraController.HasCameraCollision()
	-- we check camera collision by testing if CameraObjectDistance is equal to length(eye-lookat)
	local att = ParaCamera.GetAttributeObject();
	local lookatPos = vector3d:new(att:GetField("Lookat position", {1, 1, 1}));
	local vEyePos = vector3d:new(att:GetField("Eye position", {1, 1, 1}));
	
	local eye_dist = (lookatPos - vEyePos):length();
	local no_collision_dist = att:GetField("CameraObjectDistance", 10);
	if( math.abs(no_collision_dist - eye_dist) > 0.1) then
		return true;
	end
end

-- when shift key is pressed while standing, we will enter the mode. 
function CameraController.CheckSetShiftKeyStandingMode(player)
	local shift_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RSHIFT);
	if(shift_pressed) then
		-- bent down if no speed and shift key is pressed. 
		CameraController.is_shift_pressed = true;
		local entity = EntityManager.GetFocus();
		if(entity and not entity:IsControlledExternally()) then
			entity:OnShiftKeyPressed();
		end
	else
		if(CameraController.is_shift_pressed) then
			CameraController.is_shift_pressed = nil;
			local entity = EntityManager.GetFocus();
			if(entity and not entity:IsControlledExternally()) then
				entity:OnShiftKeyReleased();
			end
		end
	end
end

-- player acceleration applied according to speed change. 
-- return true if it is slowing down
function CameraController.ApplyPlayerAcceleration()
	local playerEntity = EntityManager.GetFocus();
	
	local player;
	if(playerEntity) then
		player = playerEntity:GetInnerObject();
	end
	
	if(not player) then
		return;
	end
	
	
	if ( EntityManager.GetPlayer() == playerEntity) then
		local speed = player:GetField("LastSpeed", 0);
		local speed_scale = playerEntity:GetCurrentSpeedScale();
		player:SetField("Speed Scale", speed_scale);
		local accel_dist = player:GetField("AccelerationDist",0)
		if(accel_dist == 0) then
			speed = player:GetField("CurrentSpeed", 0);
		end
		if( speed ~= 0) then
			-- slow down the walking animation just in case the acceleration mode is turned on. 
			local cur_speed = player:GetField("CurrentSpeed", 0);
			-- return true if we are slowing down. current speed is 0 but last speed is not. 
			return cur_speed == 0;
		else
			CameraController.CheckSetShiftKeyStandingMode(player);
		end
	else
		-- for actors, do not apply acceleration key. 
		if(playerEntity.class_name == "EntityCamera") then
			local speed_scale = playerEntity:GetCurrentSpeedScale();
			player:SetField("Speed Scale", speed_scale);
		end
		CameraController.CheckSetShiftKeyStandingMode(player);
	end
end

-- private function: let the camera view swing left, right and a little bit up and down. 
-- also add some roll and pitch to make walking more real. 
function CameraController.UpdateViewBobbing()
	
	local bIsSlowingDown = CameraController.ApplyPlayerAcceleration();

	local player = ParaScene.GetPlayer();
	local speed = player:GetField("LastSpeed", 0);

	
	if(bIsSlowingDown) then
		-- if it is sliding and last sliding speed is not too big, stop animation. 
		if(math.abs(speed) < 3) then
			speed = 0;
			player:SetField("AnimID", 0);
		end
	end
	
	-- swing amplitude
	if(GameLogic.options.ViewBobbing and not CameraController.IsAutoRoomViewEnabled()) then
		local amp = speed * GameLogic.options.ViewBobbingAmpScale;

		local att = ParaCamera.GetAttributeObject();

		local dist_walked = - camera.dist_walked * 1.4;
		local dx, dy, dz, roll, pitch = 0,0,0,0,0;
		if( GameLogic.GetPlayerController():IsInAir() or att:GetField("CameraObjectDistance", 10) >= 10 or 
			(not GameLogic.IsFPSView and CameraController.HasCameraCollision()) ) then
			-- diable bobbing when in air or camera collide with wall in third person view.
			amp = 0;
		end

		-- max allowed bobbing amp change per millisecond.
		local max_delta_amp = camera.deltaTime*0.0002;
		camera.last_amp = camera.last_amp or amp;
		amp = math.min(math.max(camera.last_amp - max_delta_amp,amp), camera.last_amp + max_delta_amp);

		if(amp > 0) then
			dx = math.sin(dist_walked) * amp * 0.4;
			dy = - math.abs(math.cos(dist_walked) * amp * 0.25);
			roll = math.sin(dist_walked) * amp * 3;
			pitch = math.abs(math.cos(dist_walked - 0.2) * amp) * 5;
		end
		camera.last_amp = amp;

		camera_params[1], camera_params[2], camera_params[3] = dx,dy,0;
		att:SetField("CameraLookatOffset", camera_params);

		CameraController:ApplyAdditionalCameraRotate(0 , pitch * 0.015, roll*0.015);
	else
		CameraController:ApplyAdditionalCameraRotate();
	end
end

-- private: 
function CameraController:ApplyAdditionalCameraRotate(d_yaw, d_pitch, d_roll)
	local yaw_, pitch_, roll_ = CameraController:GetAdditionalCameraRotate();
	local att = ParaCamera.GetAttributeObject();
	camera_params[1], camera_params[2], camera_params[3] = yaw_+ (d_yaw or 0) , pitch_ + (d_pitch or 0), roll_ + (d_roll or 0);
	local entity = EntityManager:GetFocus();
	if(entity) then
		camera_params[3] = camera_params[3] + entity:GetCameraRoll();
	end
	att:SetField("AdditionalCameraRotate", camera_params);
end

-- @param yaw, pitch, roll: can be nil
function CameraController:SetAdditionalCameraRotate(yaw, pitch, roll)
	local params = camera_params;
	params[1] = yaw or self.additional_yaw or 0;
	params[2] = pitch or self.additional_pitch or 0;
	params[3] = roll or self.additional_roll or 0;
	self.additional_yaw, self.additional_pitch, self.additional_roll = params[1], params[2], params[3];
end

-- @return yaw, pitch, roll
function CameraController:GetAdditionalCameraRotate()
	return self.additional_yaw or 0, self.additional_pitch or 0, self.additional_roll or 0;
end

function CameraController.IsLockPlayerHead()
	return camera_mode ~= CameraModes.ThirdPersonFreeLooking;
end


-- @param result: result.x, result.y, result.z, result.length.  picking result. 
-- @param max_picking_dist: the global picking distance 
function CameraController.OnMousePick(result, max_picking_dist)
	if(not CameraController.IsLockPlayerHead() and result) then
		local player = EntityManager.GetFocus();
		if(player) then
			if(ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LEFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RIGHT)) then
				-- do not turn when left or right key is pressed
				player:FaceTarget(nil);
				return
			end
			local attr = ParaCamera.GetAttributeObject();
			local cam_dist = attr:GetField("CameraObjectDistance", 10);
			if(cam_dist < disable_facing_mouse_dist) then
				-- looking at the camera look at position. 
				local eye_dist, eye_liftup, eye_rot_y = ParaCamera.GetEyePos();
				player:FaceTarget(eye_dist, -eye_liftup, eye_rot_y, true);
			else
				-- looking at the picking point
				if(result.length and result.length<max_picking_dist and result.x) then
					player:FaceTarget(result.x, result.y, result.z);
				else
					player:FaceTarget(nil);
				end
			end
		end
	end
end

-- called per camera frame move. 
function CameraController.UpdateCameraFrameStats()
	camera.prevPosX, camera.prevPosY, camera.prevPosZ = camera.posX, camera.posY, camera.posZ;
	camera.last_time = camera.cur_time;
	camera.cur_time = commonlib.TimerManager.GetCurrentTime();
	camera.deltaTime = camera.cur_time - (camera.last_time or camera.cur_time);

	local player = ParaScene.GetPlayer();
	camera.posX, camera.posY, camera.posZ = player:GetPosition();
	local diffX = camera.posX - (camera.prevPosX or camera.posX);
	local diffZ = camera.posZ - (camera.prevPosZ or camera.posZ);
	camera.curDiffX, camera.curDiffZ = diffX, diffZ;

	local dist_walked = diffX * diffX + diffZ * diffZ;
	if(dist_walked > 0.0001) then
		dist_walked = math.sqrt(diffX * diffX + diffZ * diffZ);
		camera.lastDiffX, camera.lastDiffZ = diffX, diffZ;
	else
		dist_walked = 0;
	end
	if(dist_walked > 10) then
		dist_walked = 10;
	end
	camera.dist_walked = (camera.dist_walked or 0) + dist_walked;

	camera.prevDistanceWalkedModified = camera.distanceWalkedModified;
	camera.distanceWalkedModified = camera.distanceWalkedModified + dist_walked;
end

-- same as render frame rate
function CameraController.OnCameraFrameMove()
	CameraController.UpdateCameraFrameStats()

	CameraController.UpdateViewBobbing();
	
	CameraController.UpdateFlyMode();

	Cameras:GetCurrent():FrameMoveCameraControl()

	if(not GameLogic.GameMode:IsMovieMode()) then
		local bIsAnimatingView;
		if(CameraController.IsAutoRoomViewEnabled()) then
			bIsAnimatingView = not CameraController.ApplyAutoRoomViewCamera();
		end
		if(not bIsAnimatingView and CameraController.IsCameraRotationGridEnabled()) then
			CameraController.ApplyCameraRotationGridRestrictions();
		end
		CameraController.ApplyCameraRestrictions()
	end
end

function CameraController.ClearCameraRestrictions()
	CameraController.SetCameraRestrictions()
end

-- @param minYaw, maxYaw: in radians, if nil, means no restrictions
-- @param minDist, maxDist: camera object distance
-- @param minPitch, maxPitch: angles
function CameraController.SetCameraRestrictions(minYaw, maxYaw, minDist, maxDist, minPitch, maxPitch)
	local self = CameraController;
	self.minYaw, self.maxYaw, self.minDist, self.maxDist, self.minPitch, self.maxPitch = minYaw, maxYaw, minDist, maxDist, minPitch, maxPitch
end

function CameraController.ApplyCameraRestrictions()
	local self = CameraController;
	--  and not GameLogic.GameMode:IsEditor()
	if(not GameLogic.GameMode:IsMovieMode()) then
		if(not ParaUI.IsMousePressed(0) and not ParaUI.IsMousePressed(1) and not Cameras:GetCurrent():IsDragging()) then
			-- apply restrictions
			local att = ParaCamera.GetAttributeObject();
			local dist, pitch, yaw = att:GetField("CameraObjectDistance", 0), att:GetField("CameraLiftupAngle", 0), att:GetField("CameraRotY", 0);
			local dist1, pitch1, yaw1 = dist, pitch, yaw
			if(self.minYaw and self.maxYaw) then
				if(self.minYaw > self.maxYaw) then
					self.maxYaw = self.maxYaw + math.pi* 2;
				end
				if(yaw < self.minYaw or yaw > self.maxYaw) then
					if(math.abs(mathlib.ToStandardAngle(yaw-self.minYaw)) < math.abs(mathlib.ToStandardAngle(yaw-self.maxYaw))) then
						yaw1 = self.minYaw
					else
						yaw1 = self.maxYaw
					end
				else
					yaw1 = math.min(math.max(self.minYaw, yaw), self.maxYaw)	
				end
			end
			if(self.minDist and self.maxDist) then
				dist1 = math.min(math.max(self.minDist, dist), self.maxDist)
			end
			if(self.minPitch and self.maxPitch) then
				pitch1 = math.min(math.max(self.minPitch, pitch), self.maxPitch)
			end
			att:SetField("CameraObjectDistance", dist1)
			att:SetField("CameraLiftupAngle", pitch1)
			att:SetField("CameraRotY", yaw1);
		end
	end
end

function CameraController.UpdateFlyMode()
	local entity = EntityManager.GetFocus();
	if(entity and entity:IsFlying() and not entity:IsControlledExternally()) then
		ParaCamera.GetAttributeObject():SetField("UseRightButtonBipedFacing", true);
	else
		ParaCamera.GetAttributeObject():SetField("UseRightButtonBipedFacing", false);
	end
end

local tick_count = 0;

-- 30 FPS from game_logic
function CameraController.OnFrameMove()
	tick_count = tick_count + 1;
	if(tick_count%15 == 0) then
		-- this sometimes makes movie recording difficult. 
		if(ClickToContinue.FrameMove) then
			ClickToContinue.FrameMove(true);
		end
	end

	if(camera_mode ==  CameraModes.ThirdPersonLookCamera) then
		eye_pos = ParaCamera.GetAttributeObject():GetField("Eye position", eye_pos);
		local player = EntityManager.GetFocus();
		if(player) then
			player:FaceTarget(eye_pos[1], eye_pos[2], eye_pos[3]);
		end
	end

	--local CameraObjectDistance = ParaCamera.GetAttributeObject():GetField("CameraObjectDistance", 5);
	--if(CameraObjectDistance < 2) then
		--if(not GameLogic.IsFPSView) then
			--GameLogic.ToggleCamera(true)
		--end
	--else
		--if(GameLogic.IsFPSView) then
			--GameLogic.ToggleCamera(false)
		--end
	--end
end

-- zoom in/out in third person view when movie mode is not enabled. 
-- @param bIsZoomIn: 
function CameraController.ZoomInOut(bIsZoomIn)
	if(not CameraController.IsFPSView() and not GameLogic.GameMode:IsMovieMode()) then
		local attr = ParaCamera.GetAttributeObject();
		local cam_dist = attr:GetField("CameraObjectDistance", 10);
		if(bIsZoomIn) then
			cam_dist = cam_dist*0.9;
			if(cam_dist < 2) then
				cam_dist = 2;
			end
		else
			cam_dist = cam_dist*1.1;
			if(cam_dist > 16) then
				cam_dist = 16;
			end
		end
		attr:SetField("CameraObjectDistance", cam_dist);
	end	
end

function CameraController.LockCamera(is_lock)
	CameraController.is_lock_camera = is_lock

    local att = ParaCamera.GetAttributeObject();
	
	if is_lock then
		if CameraController.lock_temp_data == nil then
			CameraController.lock_temp_data = {}
			CameraController.lock_temp_data.enable_mouse_wheel = att:GetField("EnableMouseWheel");
			CameraController.lock_temp_data.enable_mouse_right_drag = att:GetField("EnableMouseRightDrag");
			CameraController.lock_temp_data.enable_mouse_left_drag = att:GetField("EnableMouseLeftDrag");
		end

		att:SetField("EnableMouseWheel", false);
		att:SetField("EnableMouseRightDrag", false);
		att:SetField("EnableMouseLeftDrag", false);
	else
		local temp_data = CameraController.lock_temp_data or {}
		att:SetField("EnableMouseWheel", temp_data.enable_mouse_wheel or false);
		att:SetField("EnableMouseRightDrag", temp_data.enable_mouse_right_drag or true);
		att:SetField("EnableMouseLeftDrag", temp_data.enable_mouse_left_drag or true);

		CameraController.lock_temp_data = nil
	end
end

function CameraController.LockRailCarFirstPersonView()
	local entity = EntityManager.GetFocus();
	if entity and entity.ridingEntity then
		CameraController.LockCamera(true)

		local att = ParaCamera.GetAttributeObject();
		att:SetField("MaxCameraObjectDistance", 0.3);
		att:SetField("NearPlane", 0.1);
		att:SetField("RotationScaler", 0.0025);
		att:SetField("IsShiftMoveSwitched", true);
		local facing = entity.ridingEntity:GetFacing() or 0
		local rotation_pitch = entity.ridingEntity:GetRotationPitch()
		local move_angle = entity.ridingEntity:GetmoveAngle()
		local is_moving = entity.ridingEntity:IsMoving()
		CameraController.UpdateCameraRotation(facing, rotation_pitch, move_angle, is_moving)
	end
end

function CameraController.LockRailCarSurroundView()
	local entity = EntityManager.GetFocus();
	if entity and entity.ridingEntity then
		CameraController.LockCamera(true)

		local att = ParaCamera.GetAttributeObject();
		local facing = entity.ridingEntity:GetFacing() or 0
		local rotation_pitch = entity.ridingEntity:GetRotationPitch()
		local target_facing = facing - math.pi/2
		if CameraController.RailCarCameraTimer then
			local cur_facing = att:GetField("CameraRotY", 0) % (math.pi * 2)
			target_facing = (math.floor(cur_facing/(math.pi/2)) + 1) * math.pi/2
		end
		
		
		att:SetField("CameraLiftupAngle", 0.2);
		att:SetField("CameraRotY", target_facing);

		CameraController.StartSurroundCamrea()
	end
end

function CameraController.LockRailCarFixedView()
	local fiexd_camera_data = CameraController.LoadFiexdCameraSetting()
	if fiexd_camera_data == nil then
		return
	end

	if fiexd_camera_data.movies_list == nil or #fiexd_camera_data.movies_list == 0 then
		return
	end

	local movies_list = fiexd_camera_data.movies_list
	local movies_pos_list = {}

	local World2In1 = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1.lua");
	if World2In1.IsInVisitPorject() then
		for i, v in ipairs(movies_list) do
			movies_pos_list[i] = World2In1.TurnWorldPosToMiniPos(v.pos)
		end
	else
		for i, v in ipairs(movies_list) do
			movies_pos_list[i] = v.pos
		end
	end

	local time = fiexd_camera_data.change_time or 10
	local is_random = fiexd_camera_data.is_random

	CameraController.StartFiexdCamrea(movies_pos_list, time, is_random)
end

function CameraController.LockRailCarMovieView()
	local movies_pos = {18674,2,19141}
	if movies_pos then
		-- local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
		-- local movie_entity = BlockEngine:GetBlockEntity(movies_pos[1] or 0, movies_pos[2] or 0, movies_pos[3] or 0);
		-- if movie_entity.movieClip then
		-- 	movie_entity:ExecuteCommand()
		-- end

		local channel = MovieManager:CreateGetMovieChannel("railcar_fiexd_moives");
		if channel then
			channel:SetStartBlockPosition(math.floor(movies_pos[1]),math.floor(movies_pos[2]),math.floor(movies_pos[3]));
			local movieClip = channel:CreateGetStartMovieClip()
			channel:PlayLooped(0, -1);
		end
		
	end
end

function CameraController.ClearRailCarCameraModData(is_toggle_camera)
	CameraController.LockCamera(false)
	CameraController.ChangeCameraFreeLookMod()
	if CameraController.RailCarCameraTimer then
		CameraController.RailCarCameraTimer:Change()
		CameraController.RailCarCameraTimer = nil
	end

	local channel = MovieManager:CreateGetMovieChannel("railcar_fiexd_moives");
	if channel then
		channel:Stop();	
	end

	MovieManager:SetActiveMovieClip(nil)
end

function CameraController.SetRailCarCameraMod(mode)
	CameraController.cur_railcar_camera_mod = mode
	CameraController.ClearRailCarCameraModData(is_toggle_camera)

	if mode == nil then
		return
	end

	if CameraController.RailCarCameraMod[mode] then
		local camera_mod_data = CameraController.RailCarCameraMod[mode]
		if camera_mod_data.mod_func then
			camera_mod_data.mod_func()
		end
	end
end

function CameraController.UpdateCameraRotation(facing, pitch, move_angel, is_moving)
	
	move_angel = move_angel and -move_angel or 0
	local dir = move_angel >= 0 and 1 or -1
	local att = ParaCamera.GetAttributeObject()
	att:SetField("CameraLiftupAngle", (pitch*math.pi/180 + math.pi/15) * dir);
	local camera_facing = is_moving and move_angel or facing
	att:SetField("CameraRotY", camera_facing);
end

function CameraController.IsLockRailCarFirstPersonView()
	return CameraController.cur_railcar_camera_mod == "lock_first_person"
end

function CameraController.StartSurroundCamrea()
	if CameraController.RailCarCameraTimer then
		CameraController.RailCarCameraTimer:Change()
	end

	local att = ParaCamera.GetAttributeObject()
	local start_facing = att:GetField("CameraRotY", 0)
	CameraController.RailCarCameraTimer =  commonlib.Timer:new({callbackFunc = function()

		local facing = att:GetField("CameraRotY", 0)
		if facing - start_facing >= math.pi then
			local cur_facing = facing%(math.pi * 2)
			target_facing = math.floor(cur_facing/(math.pi/2)) * math.pi/2
			att:SetField("CameraRotY", target_facing);
			CameraController.StartSurroundCamrea()
			return
		end

		facing = facing + math.pi/180;
		att:SetField("CameraRotY", facing);
	end})
	CameraController.RailCarCameraTimer:Change(5000,50);
end

function CameraController.StartFiexdCamrea(movies_pos_list, time, is_random)
	if movies_pos_list == nil or #movies_pos_list == 0 then
		local channel = MovieManager:CreateGetMovieChannel("railcar_fiexd_moives");
		if channel then
			channel:Stop();	
		end
		return
	end

	local remove_index = is_random and math.random(1, #movies_pos_list) or 1
	local movies_pos = table.remove(movies_pos_list, remove_index)
	local channel = MovieManager:CreateGetMovieChannel("railcar_fiexd_moives");
	if channel then
		channel:SetStartBlockPosition(math.floor(movies_pos[1]),math.floor(movies_pos[2]),math.floor(movies_pos[3]));
		local movieClip = channel:CreateGetStartMovieClip()
		channel:PlayLooped(0, -1);
	end

	CameraController.RailCarCameraTimer =  commonlib.Timer:new({callbackFunc = function()
		CameraController.StartFiexdCamrea(movies_pos_list, time, is_random) 
	end})
	CameraController.RailCarCameraTimer:Change(time * 1000);
end

function CameraController.LoadFiexdCameraSetting()
	local World2In1 = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1.lua");
	-- 二合一世界作品区特殊处理
	if World2In1.IsInVisitPorject() then
		local world_info = World2In1.GetCurProjectServerData()
		if world_info.extra and world_info.extra.railcar_fiexd_setting then
			return world_info.extra.railcar_fiexd_setting
		end
		return
	end

	local filename = "railcar_setting.txt"
    local world_data = Mod.WorldShare.Store:Get('world/currentWorld')
	if world_data == nil then
		return
	end
	
    if GameLogic.GameMode:IsEditor() or (GameLogic.GameMode:GetMode() == "game" and not GameLogic.IsReadOnly()) then
		local disk_folder = world_data.worldpath
		local file_path = string.format("%s/%s", disk_folder, filename)
		if ParaIO.DoesFileExist(file_path) then
			local file = ParaIO.open(file_path, "r")
			if(file:IsValid()) then
				local data = file:GetText();
				return commonlib.Json.Decode(data)
			end
		end
	elseif GameLogic.IsReadOnly() then
		local world = RemoteWorld.LoadFromHref(world_data.remotefile, "self")
		local projectId = world_data.kpProjectId or 0
		world:SetProjectId(projectId)
		local fileUrl = world:GetLocalFileName()
		if ParaIO.DoesFileExist(fileUrl) then
			local path = fileUrl
			local parentPath = path:gsub("[^/\\]+$", "")
			ParaAsset.OpenArchive(path, true)
		
			local revision = 0
			local output = {}
			commonlib.Files.Find(output, "", 0, 10000, ":railcar_setting.txt", path)
		
			if #output ~= 0 then
				local file = ParaIO.open(parentPath .. output[1].filename, "r")
				if file:IsValid() then
					local data = file:GetText();
					return commonlib.Json.Decode(data)
				end
			end
		
			ParaAsset.CloseArchive(path)
		end
    end
end

function CameraController.ChangeCameraFreeLookMod()
	local self = CameraController;
	self:SetMode(CameraModes.ThirdPersonFreeLooking);
	GameLogic.IsFPSView = false;
	local att = ParaCamera.GetAttributeObject();
	att:SetField("MaxCameraObjectDistance", 26);
	att:SetField("IsAlwaysRotateCameraWhenFPS", false);
	att:SetField("CameraObjectDistance", 8);
	att:SetField("NearPlane", 0.1);
	--att:SetField("FieldOfView", 60/180*3.1415926)

	--att:SetField("MoveScaler", 5);
	att:SetField("RotationScaler", 0.01);
	--att:SetField("TotalDragTime", 0.5)
	--att:SetField("SmoothFramesNum", 2)
	att:SetField("EnableMouseWheel", false);

	att:SetField("IsShiftMoveSwitched", true);
	ParaScene.GetPlayer():SetDensity(GameLogic.options.NormalDensity);
	ParaUI.ShowCursor(true);
	ParaUI.LockMouse(false);
	local _this = ParaUI.GetUIObject("FPS_Cursor");
	if(_this:IsValid())then
		_this.visible = false;
	end
	if(CameraController.FPS_MouseTimer) then
		CameraController.FPS_MouseTimer:Change();
	end
end

function CameraController.OnSyncWorldFinish()
    local world_data = Mod.WorldShare.Store:Get('world/currentWorld')
	if world_data == nil then
		return
	end

	local disk_folder = world_data.worldpath
	local filename = "railcar_setting.txt"

	local file_path = string.format("%s/%s", disk_folder, filename)
	if ParaIO.DoesFileExist(file_path) then
		local file = ParaIO.open(file_path, "r")
		local setting = nil
		if(file:IsValid()) then
			local data = file:GetText();
			setting = commonlib.Json.Decode(data)
			if setting and (not setting.has_upload or setting.kpProjectId ~= world_data.kpProjectId) then
				local params = {
					extra = {}
				}
				params.extra.railcar_fiexd_setting = setting;
				local KeepworkServiceProject = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Project.lua")
				KeepworkServiceProject:UpdateProject(world_data.kpProjectId, params, function(data, err)
					if err == 200 then
						setting.has_upload = true
						setting.kpProjectId = world_data.kpProjectId
						data = commonlib.Json.Encode(setting);
						file = ParaIO.open(file_path, "w");
						if(file) then
							file:write(data, #data);
							file:close();
						end
					end
				end)
			end
		end
	end
end

-- @param yaw: yaw grid restriction value, if nil or 0 we will disable it.
-- @param pitch: pitch grid restriction value, if nil or 0 we will disable it.
function CameraController.EnableCameraRotationGrid(yaw, pitch)
	if(yaw and yaw == 0) then
		yaw = nil;
	end
	if(pitch and pitch == 0) then
		pitch = nil;
	end
	CameraController.gridYaw = yaw
	CameraController.gridPitch = pitch
end

function CameraController.IsCameraRotationGridEnabled()
	return CameraController.gridYaw or CameraController.gridPitch
end

function CameraController.ApplyCameraRotationGridRestrictions()
	if(not CameraController.IsCameraRotationGridEnabled() or CameraController.IsFPSView()) then
		return
	end
	local isCameraKeyPressed = ParaUI.IsMousePressed(0) or Cameras:GetCurrent():IsDragging();
	-- this fixed a temporary android bug where ParaUI.IsMousePressed(1) always return true until we long hold to right click. 
	if(not System.os.IsMobilePlatform() and ParaUI.IsMousePressed(1)) then
		isCameraKeyPressed = true;
	end
	
	if(not isCameraKeyPressed) then
		local attr = ParaCamera.GetAttributeObject()
		local eye_pos = attr:GetField("Eye position", eye_pos);
		local lookat_pos = attr:GetField("Lookat position", lookat_pos);
		local camobjDist, LiftupAngle, CameraRotY = attr:GetField("CameraObjectDistance", 0), attr:GetField("CameraLiftupAngle", 0), attr:GetField("CameraRotY", 0);
	
		local dist, pitch, yaw = camobjDist, LiftupAngle, CameraRotY;

		local eyeX, eyeY, eyeZ = eye_pos[1], eye_pos[2], eye_pos[3]
		local lookatX, lookatY, lookatZ = lookat_pos[1], lookat_pos[2], lookat_pos[3]
		----------------
		-- only limit camera rotation grid, when user is not dragging the camera view, such as holding the right or left mouse button. 
		----------------
		if(not CameraController.IsAutoRoomViewEnabled() and CameraController.gridPitch) then
			local pitchTarget = math.floor(pitch / CameraController.gridPitch + 0.5) * CameraController.gridPitch
			-- 60 degrees per second with some accelerations when the angle diff is very big. 
			if(math.abs(pitchTarget - pitch) > 0.01) then
				local newPitch = mathlib.SmoothMoveFloat(pitch, pitchTarget, (60+(math.abs(pitch-pitchTarget)*100)^2/10) * camera.deltaTime/1000/180*math.pi)
				attr:SetField("CameraLiftupAngle", newPitch)
			end
		end
		if(CameraController.gridYaw) then
			local yawTarget = math.floor(yaw / CameraController.gridYaw + 0.5) * CameraController.gridYaw
			-- 60 degrees per second with some accelerations when the angle diff is very big. 
			if(math.abs(yawTarget - yaw) > 0.01) then
				local newYaw = mathlib.SmoothMoveFloat(yaw, yawTarget, (60+(math.abs(yaw-yawTarget)*100)^2/10) * camera.deltaTime/1000/180*math.pi)
				attr:SetField("CameraRotY", newYaw)
			end
		end
	end
end

-- we will automatically adjust camera, so that the user can always see the main player in a scene. 
-- we also apply some basic third-person down view restrictions. The algorithm ensures that the smallest view adjustment is applied. 
-- The algorithm we will also try to find doors on the wall of a room, once a door is detected, it will face the door or the other room 
-- according to the current player walk direction. 
-- room view can be enabled inside small room or even an outdoor scene as well. It is best enabled for users who can not control the camera very well. 
-- With room view enabled, the user only need to take control of the player position. 
function CameraController.EnableAutoRoomView(bEnabled)
	CameraController.isAutoRoomViewEnabled = bEnabled;
end

function CameraController.IsAutoRoomViewEnabled()
	return CameraController.isAutoRoomViewEnabled;
end

-- return true if room view restrictions are satisfied
function CameraController.ApplyAutoRoomViewCamera()
	local roomViewSatisfied = true;
	if(not CameraController.IsAutoRoomViewEnabled() or CameraController.IsFPSView()) then
		return roomViewSatisfied;
	end
	local isCameraKeyPressed = ParaUI.IsMousePressed(0) or Cameras:GetCurrent():IsDragging();
	-- this fixed a temporary android bug where ParaUI.IsMousePressed(1) always return true until we long hold to right click. 
	if(not System.os.IsMobilePlatform() and ParaUI.IsMousePressed(1)) then
		isCameraKeyPressed = true;
	end
	
	if(not isCameraKeyPressed) then
		local attr = ParaCamera.GetAttributeObject()
		local eye_pos = attr:GetField("Eye position", eye_pos);
		local lookat_pos = attr:GetField("Lookat position", lookat_pos);
		local camobjDist, LiftupAngle, CameraRotY = attr:GetField("CameraObjectDistance", 0), attr:GetField("CameraLiftupAngle", 0), attr:GetField("CameraRotY", 0);
	
		local dist, pitch, yaw = camobjDist, LiftupAngle, CameraRotY;

		local eyeX, eyeY, eyeZ = eye_pos[1], eye_pos[2], eye_pos[3]
		local lookatX, lookatY, lookatZ = lookat_pos[1], lookat_pos[2], lookat_pos[3]
		----------------
		-- only limit camera pitching, when user is not dragging the camera view, such as holding the right or left mouse button. 
		----------------
		local minPitch, maxPitch = 15/180*math.pi, 40/180*math.pi
		local pitchTarget = math.min(math.max(minPitch, pitch), maxPitch)
	
		-- 60 degrees per second with some accelerations when the angle diff is very big. 
		if(pitchTarget ~= pitch) then
			if(math.abs(pitch-pitchTarget)>0.01) then
				roomViewSatisfied = false;
			end
			local newPitch = mathlib.SmoothMoveFloat(pitch, pitchTarget, (60+(math.abs(pitch-pitchTarget)*100)^2/10) * camera.deltaTime/1000/180*math.pi)
			attr:SetField("CameraLiftupAngle", newPitch)
		end

		----------------
		-- find a yaw angle with enough cameraEyeDistance, so that we can always see the entire player. 
		-- only do the adjustment of yaw, when pitch is already adjusted and that the camera is not moving in the last frame. 
		----------------
		if(pitchTarget == pitch and camera.dist_walked == 0) then
			local minCamEyeDist = 5;
			if(camobjDist < minCamEyeDist) then
				attr:SetField("CameraObjectDistance", minCamEyeDist)	
			else
				local cameraEyeDistance = math.sqrt((eyeX-lookatX)^2 + (eyeY-lookatY)^2 + (eyeZ-lookatZ)^2)
				if(cameraEyeDistance < minCamEyeDist) then
					if(camera.lastDiffX ~= 0 or camera.lastDiffZ ~= 0) then
						-- use last walk direction as a hint to find a new camera yaw location. 
					end
				end	
			end
		end
	end
	return roomViewSatisfied;
end

-- handling mouse event for basic camera control
function CameraController.handleMouseEvent(event)
	Cameras:GetCurrent():handleMouseEvent(event)
end