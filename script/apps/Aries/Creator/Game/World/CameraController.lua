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
local StereoVisionController = commonlib.gettable("MyCompany.Aries.Game.StereoVisionController")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local CreatorDesktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.CreatorDesktop");
local vector3d = commonlib.gettable("mathlib.vector3d");
local ClickToContinue = commonlib.gettable("MyCompany.Aries.Desktop.GUIHelper.ClickToContinue");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

---------------------------
-- create class
---------------------------
local CameraController = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.CameraController"));
CameraController:Property("Name", "CameraController");

CameraController:Signal("modeChanged")

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
	local attr = ParaCamera.GetAttributeObject();
	if(GameLogic.options.CharacterLookupBoneIndex) then
		attr:SetField("CharacterLookupBoneIndex", GameLogic.options.CharacterLookupBoneIndex);
	end
	attr:SetField("On_FrameMove", ";MyCompany.Aries.Game.GameLogic.OnCameraFrameMove();");
	
	attr:SetField("MaxAllowedYShift", GameLogic.options.MaxAllowedYShift or 0);
	attr:SetField("CameraRollbackSpeed", GameLogic.options.CameraRollbackSpeed or 6);
	-- "EnableMouseLeftDrag" boolean attribute is added to ParaCamera.
	attr:SetField("EnableMouseLeftDrag", GameLogic.options.isMouseLeftDragEnabled == true);
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
			player:ToCharacter():PlayAnimation(0);
		end
	end
	
	-- swing amplitude
	if(GameLogic.options.ViewBobbing) then
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

-- same as render frame rate
function CameraController.OnCameraFrameMove()
	-- update camera stats
	camera.prevPosX, camera.prevPosY, camera.prevPosZ = camera.posX, camera.posY, camera.posZ;
	camera.last_time = camera.cur_time;
	camera.cur_time = commonlib.TimerManager.GetCurrentTime();
	camera.deltaTime = camera.cur_time - (camera.last_time or camera.cur_time);

	local player = ParaScene.GetPlayer();
	camera.posX, camera.posY, camera.posZ = player:GetPosition();
	local diffX = camera.posX - (camera.prevPosX or camera.posX);
	local diffZ = camera.posZ - (camera.prevPosZ or camera.posZ);
	local dist_walked = diffX * diffX + diffZ * diffZ;
	if(dist_walked > 0.0001) then
		dist_walked = math.sqrt(diffX * diffX + diffZ * diffZ);
	else
		dist_walked = 0;
	end
	if(dist_walked > 10) then
		dist_walked = 10;
	end
	camera.dist_walked = (camera.dist_walked or 0) + dist_walked;

	camera.prevDistanceWalkedModified = camera.distanceWalkedModified;
	camera.distanceWalkedModified = camera.distanceWalkedModified + dist_walked;

	CameraController.UpdateViewBobbing();

	CameraController.UpdateFlyMode();
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
local eye_pos = {0,0,0};

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
