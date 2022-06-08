--[[
Title: Camera entity
Author(s): LiXizhi
Date: 2014/3/19
Desc: camera entity that is only used in a movie clip. This is NOT the game camera. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCamera.lua");
local EntityCamera = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCamera")
local entity = EntityCamera:new({x,y,z,radius}):init();
entity:Attach();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/InventoryBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ContainerView.lua");
NPL.load("(gl)script/ide/math/math3d.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TimeSeries.lua");
local TimeSeries = commonlib.gettable("MyCompany.Aries.Game.Common.TimeSeries");
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
local ContainerView = commonlib.gettable("MyCompany.Aries.Game.Items.ContainerView");
local InventoryBase = commonlib.gettable("MyCompany.Aries.Game.Items.InventoryBase");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local math_abs = math.abs;
local math_random = math.random;
local math_floor = math.floor;

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMovable"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCamera"));

Entity:Property({"isAlwaysHidden", false, "IsAlwaysHidden", "SetAlwaysHidden", auto = true});
Entity:Signal("cameraHidden");
Entity:Signal("cameraShown");
Entity:Signal("targetChanged", function(newTarget, oldTarget) end);
Entity:Signal("beforeDestroyed")

-- persistent object by default. 
Entity.is_persistent = false;
-- class name
Entity.class_name = "EntityCamera";
-- register class
EntityManager.RegisterEntityClass(Entity.class_name, Entity);

-- enabled frame move. 
Entity.framemove_interval = 0.2;

-- disable F key for toggle flying. 
Entity.disable_toggle_fly = true;

function Entity:ctor()
	self.inventory = InventoryBase:new():Init();
	self.inventory:SetClient();
	self.inventory:SetParentEntity(self);
	self:SetDummy(true);
end

-- let the camera focus on this player and take control of it. 
-- @return return true if focus is set
function Entity:SetFocus()
	if(self:GetScene()) then
		self.has_focus = true;
	else
		EntityManager.SetFocus(self);
	end
	return true;
end

function Entity:init()
	if(not Entity._super.init(self)) then
		return;
	end
	local obj = self:GetInnerObject();
	if(obj) then
		-- make it can fly
		obj:SetField("CanFly",true);
		obj:SetField("AlwaysFlying",true);
		obj:SetField("ShadowCaster",false);
		obj:SetField("Physics Radius", 0.3);
		obj:SetField("PhysicsHeight", 0.5);
		obj:SetDensity(0);
		-- this fixed camera direction in mobile device. 
		obj:SetField("FlyUsingCameraDir", true);
	end
	return self;
end

function Entity:GetMainAssetPath()
	return "character/CC/02human/Camera/Camera.x";
end

function Entity:GetCommandTitle()
	return L"输入摄影机的名字"
end

function Entity:doesEntityTriggerPressurePlate()
	return false;
end

-- Returns true if the entity takes up space in its containing block, such as animals,mob and players. 
function Entity:CanBeCollidedWith(entity)
    return false;
end

-- Returns true if this entity should push and be pushed by other entities when colliding.
-- such as mob and players.
function Entity:CanBePushedBy(fromEntity)
    return false;
end

-- bool: whether show the bag panel
function Entity:HasBag()
	return false;
end

-- show nothing
function Entity:OnClick(x, y, z, mouse_button)
	if(mouse_button == "right" and GameLogic.GameMode:CanEditBlock()) then
		
		-- TODO: show camera editor?
	end
	return true;
end

-- get the camera settings before SetFocus is called. this usually stores the current player's camera settings
-- before a movie clip is played. we will usually restore the camera settings when camera is reset. 
function Entity:GetRestoreCamSettings()
	self.last_settings =  self.last_settings or {};
	return self.last_settings;
end

-- disable facing target
function Entity:FaceTarget(x,y,z)
	local obj = self:GetInnerObject();
	if(obj) then
		local eye_dist, eye_liftup, eye_rot_y = ParaCamera.GetEyePos();
		obj:SetFacing(eye_rot_y or 0);
		obj:SetField("HeadUpdownAngle", 0);
		obj:SetField("HeadTurningAngle", 0);
		local nx, ny, nz = mathlib.math3d.vec3Rotate(0, 1, 0, 0, 0, -(eye_liftup or 0))
		nx, ny, nz = mathlib.math3d.vec3Rotate(nx, ny, nz, 0, eye_rot_y or 0, 0)
		obj:SetField("normal", {nx, ny, nz});
	end
end

function Entity:SetRestoreCamSettings(settings)
	if(settings) then
		self.last_settings = settings;
	end
end

-- take running and flying into account. 
function Entity:GetCurrentSpeedScale()
	local speedscale = self:GetSpeedScale();
	if(not self.has_focus) then
		return speedscale;
	else
		if(self:IsRunning()) then
			return speedscale * 10;
		else
			return speedscale;
		end
	end
end

function Entity:SaveCurrentCameraSetting()
	local settings = self:GetRestoreCamSettings();
	settings.is_fps = CameraController.IsFPSView();
	settings.eye_dist, settings.eye_liftup, settings.eye_rot_y = ParaCamera.GetEyePos();
end

function Entity:RestoreCameraSetting()
	local settings = self:GetRestoreCamSettings();
	if(settings.eye_dist) then
		if(CameraController.IsFPSView()~=settings.is_fps) then
			CameraController.ToggleCamera(settings.is_fps);
		end
		ParaCamera.SetEyePos(settings.eye_dist, settings.eye_liftup, settings.eye_rot_y);
	end
end

-- called after focus is set
function Entity:OnFocusIn()
	self:SaveCurrentCameraSetting();
	Entity._super.OnFocusIn(self);
	if(not self:HasCollision()) then
		ParaCamera.GetAttributeObject():SetField("EnableBlockCollision", false);	
	end
	self:CheckUpdateCameraGeometry();
end

-- the lookat height needs to be refreshed when asset is loaded
function Entity:CheckUpdateCameraGeometry()
	local obj = self:GetInnerObject();
	if(obj and not obj:GetPrimaryAsset():IsLoaded()) then
		obj:GetPrimaryAsset():LoadAsset();
		self.assetTimer = self.assetTimer or commonlib.Timer:new({callbackFunc = function(timer)
			local obj = self:GetInnerObject();
			if(obj and obj:IsValid()) then
				if(obj:GetPrimaryAsset():IsLoaded()) then
					-- tricky: this will update asset height for camera lookat height
					obj:SetField("Size Scale", obj:GetField("Size Scale", 1))
					LOG.std(nil, "debug", "EntityCamera", "camera entity geometry updated");
				else
					timer:Change(100)
				end
			end
		end})
		-- start the timer after 0 milliseconds, and signal every 1000 millisecond
		self.assetTimer:Change(100)
	end
end

-- called before focus is lost
function Entity:OnFocusOut()
	Entity._super.OnFocusOut(self);
	self:RestoreCameraSetting();
	if(not self:HasCollision()) then
		ParaCamera.GetAttributeObject():SetField("EnableBlockCollision", true);	
	end
end

-- this is called on each tick, when this entity has focus and user is pressing and holding shift key. 
function Entity:OnShiftKeyPressed()
	if (self.ridingEntity) then
		self:MountEntity(nil);
	end
	self:SetCameraCollision(false);
end

-- this is called, when this entity has focus and user is just released the shift key. 
function Entity:OnShiftKeyReleased()
	self:SetCameraCollision(true);
end

-- whether camera should collide with block world. 
function Entity:HasCollision()
	return self.has_collision;
end

function Entity:Destroy()
	self:beforeDestroyed();
	if(not self:HasCollision()) then
		ParaCamera.GetAttributeObject():SetField("EnableBlockCollision", true);	
	end
	Entity._super.Destroy(self);
end

function Entity:GetRidingOffsetY()
	return 1.5;
end

function Entity:IsInsideObstructedBlock()
	local x, y, z = self:GetBlockPos();
	local block_template = BlockEngine:GetBlock(x, y, z);
	if(block_template and (block_template.blockcamera or block_template.solid)) then
		-- if camera is inside a solid block, make the camera collision free, 
		-- this will correct some view glich, though it does not correct all of them. 
		return true;
	end
end

-- @param has_collision: 1 or true to enable, 0 or false to disable. 
function Entity:SetCameraCollision(has_collision)
	has_collision = has_collision == true or has_collision == 1;

	if(self.has_collision ~= has_collision) then
		self.has_collision = has_collision;

		local obj = self:GetInnerObject();
		if(obj) then
			if(has_collision and self:HasFocus()) then
				-- normal movement style
				obj:SetField("MovementStyle", 0)
			else
				-- linear movement style. 
				obj:SetField("MovementStyle", 3)
			end 
		end
	end

	if(has_collision) then
		ParaCamera.GetAttributeObject():SetField("EnableBlockCollision", true);
	else
		ParaCamera.GetAttributeObject():SetField("EnableBlockCollision", false);
	end
end

function Entity:IsCameraHidden()
	return not self:IsVisible();
end

function Entity:HideCameraModel()
	if(not self:IsCameraHidden()) then
		self:SetVisible(false);
		self:cameraHidden();
	end
end

function Entity:ShowCameraModel()
	if(self:IsCameraHidden() and not self:IsAlwaysHidden()) then
		self:SetVisible(true);
		self:cameraShown();
	end
end

function Entity:SetTarget(actor)
	if(self.m_target~=actor) then
		local oldTarget = self.m_target;
		self.m_target = actor;
		self:targetChanged(self.m_target, oldTarget);
	end
end

function Entity:GetTarget()
	return self.m_target;
end

-- @param actor: the parent ActorNPC
function Entity:SetActor(actor)
	self.m_actor = actor;
end

-- @param actor: the parent ActorNPC
function Entity:GetActor()
	return self.m_actor;
end

-- called every frame
function Entity:FrameMove(deltaTime)
	self:UpdatePosition();
	EntityManager.Entity.FrameMove(self, deltaTime);
	-- return Entity._super.FrameMove(self, deltaTime);
end

-- call this funciton before calling GetValue to fetch from time series
function Entity:BindToItemStack(itemStack)
	local timeseries = itemStack:GetDataField("timeseries");
	if(not timeseries) then
		timeseries = {};
		itemStack:SetDataField("timeseries", timeseries);
	end
	self.TimeSeries = self.TimeSeries or TimeSeries:new{name = "Actor",};
	self.TimeSeries:LoadFromTable(timeseries);
end

function Entity:GetVariable(keyname)
	return self.TimeSeries and self.TimeSeries:GetVariable(keyname);
end

-- @param bStartFromFirstKeyFrame: whether we will only value after the time of first key frame. default to false.
function Entity:GetValue(keyname, time, bStartFromFirstKeyFrame)
	local v = self:GetVariable(keyname);
	if(v and time) then
		if(not bStartFromFirstKeyFrame) then
			-- default to animId = 1
			return v:getValue(1, time);
		else
			local firstTime = v:GetFirstTime();
			if(firstTime and firstTime <= time) then
				return v:getValue(1, time);
			end
		end
	end
end

function Entity:GetEyeLifeup()
	return self.eye_liftup;
end

function Entity:SetEyeLifeup(eye_liftup)
	self.eye_liftup = eye_liftup;

	local obj = self:GetInnerObject();
	if(obj) then
		obj:SetField("HeadUpdownAngle", 0);
		obj:SetField("HeadTurningAngle", 0);
		local nx, ny, nz = mathlib.math3d.vec3Rotate(0, 1, 0, 0, 0, -(eye_liftup or 0))
		nx, ny, nz = mathlib.math3d.vec3Rotate(nx, ny, nz, 0, self:GetFacing() or 0, 0)
		obj:SetField("normal", {nx, ny, nz});
	end
end

function Entity:GetEyeRoll()
	return self.eye_roll;
end

function Entity:SetEyeRoll(eye_roll)
	self.eye_roll = eye_roll;
	local obj = self:GetInnerObject();
	if(obj) then
		obj:SetField("pitch", eye_roll);
	end
end

-- one needs to bind to a time series first before calling this function. 
-- @param curTime: if nil, we will play to current time or 0. 
function Entity:PlayToTime(curTime)
	curTime = curTime or self.curTime or 0;
	self.curTime = curTime
	local x = self:GetValue("lookat_x", curTime);
	local y = self:GetValue("lookat_y", curTime);
	local z = self:GetValue("lookat_z", curTime);
	local eye_dist = self:GetValue("eye_dist", curTime) or 3;
	self.eye_dist = eye_dist;
	local eye_liftup = self:GetValue("eye_liftup", curTime) or 0;
	local eye_rot_y = self:GetValue("eye_rot_y", curTime) or 0;
	local eye_roll = self:GetValue("eye_roll", curTime) or 0;
	self:SetPosition(x, y, z);
	self:SetFacing(eye_rot_y);
	self:SetEyeLifeup(eye_liftup);
	self:SetEyeRoll(eye_roll);

	if(self:HasFocus()) then
		if(self:GetScene()) then
			local scene = ParaScene.GetMiniSceneGraph(self:GetScene());
			scene:CameraSetLookAtPos(x, y, z);
			scene:CameraSetEyePosByAngle(eye_rot_y, eye_liftup, eye_dist);
		else
			ParaCamera.SetEyePos(eye_dist, eye_liftup, eye_rot_y);
		end
	end
end




function Entity:GetEyeDist()
	return self.eye_dist or 3;
end