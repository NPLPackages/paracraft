--[[
Title: Overlay entity
Author(s): LiXizhi
Date: 2015/12/31
Desc: overlay entity is the base class for special owner draw objects that are rendered after all 3d scene is rendered. 

virtual functions:
	DoPaint(painter)
	paintEvent(painter)

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityOverlay.lua");
local EntityOverlay = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityOverlay")
local x, y, z = ParaScene.GetPlayer():GetPosition();
local entity = EntityOverlay:new({x=x,y=y,z=z}):init();
entity:Attach();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/math3d.lua");
NPL.load("(gl)script/ide/System/Scene/Overlays/Overlay.lua");
NPL.load("(gl)script/ide/System/Scene/Overlays/ShapesDrawer.lua");
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
NPL.load("(gl)script/ide/System/Scene/Cameras/Cameras.lua");
NPL.load("(gl)script/ide/math/Matrix4.lua");
local Matrix4 = commonlib.gettable("mathlib.Matrix4");
local vector3d = commonlib.gettable("mathlib.vector3d");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local Cameras = commonlib.gettable("System.Scene.Cameras");
local Screen = commonlib.gettable("System.Windows.Screen");
local ContainerView = commonlib.gettable("MyCompany.Aries.Game.Items.ContainerView");
local InventoryBase = commonlib.gettable("MyCompany.Aries.Game.Items.InventoryBase");
local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer");
local Overlay = commonlib.gettable("System.Scene.Overlays.Overlay");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local CodeUI = commonlib.gettable("MyCompany.Aries.Game.Code.CodeUI");

local math_abs = math.abs;
local math_random = math.random;
local math_floor = math.floor;

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.Entity"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityOverlay"));

Entity:Property({"scaling", 1.0, "GetScaling", "SetScaling"});
Entity:Property({"facing", 0, "GetFacing", "SetFacing", auto=true});
Entity:Property({"yaw", 0, "GetYaw", "SetYaw"});
Entity:Property({"pitch", 0, "GetPitch", "SetPitch", auto=true});
Entity:Property({"opacity", 1, "GetOpacity", "SetOpacity"});
Entity:Property({"isSolid", 1, "IsSolid", "SetSolid"});
Entity:Property({"isScreenMode", false, "IsScreenMode", "SetScreenMode"});
Entity:Property({"ui_x", 0, "GetScreenX", "SetScreenX", auto=true});
Entity:Property({"ui_y", 0, "GetScreenY", "SetScreenY", auto=true});
Entity:Property({"ui_align", "center", "GetAlignment", "SetAlignment", auto=true});
Entity:Property({"screen_half_width", 500, "GetScreenHalfWidth", "SetScreenHalfWidth", auto=true});
Entity:Property({"roll", 0, "GetRoll", "SetRoll", auto=true});
Entity:Property({"zorder", nil, "GetZOrder", "SetZOrder"});
Entity:Property({"color", "#ffffff", "GetColor", "SetColor", auto=true});
Entity:Property({"isPickingEnabled", false, "IsPickingEnabled", "SetSkipPicking"});

Entity:Signal("cameraHidden");
Entity:Signal("cameraShown");
Entity:Signal("targetChanged", function(newTarget, oldTarget) end);
Entity:Signal("clicked", function(mouse_button) end)

-- non-persistent object by default. 
Entity.is_persistent = false;
-- class name
Entity.class_name = "EntityOverlay";
-- register class
EntityManager.RegisterEntityClass(Entity.class_name, Entity);

-- enabled frame move. 
Entity.framemove_interval = nil;

-- disable F key for toggle flying. 
Entity.disable_toggle_fly = true;

-- half screen width is alway 500
local screenHalfWidth = 500;
-- screenHalfHeight is based on screenHalfWidth and aspect ratio
local screenHalfHeight = 300;

function Entity:ctor()
	self.inventory = InventoryBase:new():Init();
	self.inventory:SetClient();
	self:SetDummy(true);
end

-- let the camera focus on this player and take control of it. 
-- @return return true if focus is set
function Entity:SetFocus()
	EntityManager.SetFocus(self);
	return true;
end

function Entity:init()
	if(not Entity._super.init(self)) then
		return;
	end
	local overlay = self:CreateOverlay();
	return self;
end

function Entity:GetInnerObject()
	return self.overlay;
end

function Entity:Destroy()
	if(self:IsPickingEnabled()) then
		CodeUI:RemoveEntityOverlay(self);
	end
	self:DestroyOverlay()
	Entity._super.Destroy(self);
end

function Entity:SetHighlight(bHighlight)
end

function Entity:SetScaling(v)
	self.scaling = v;
end

function Entity:GetScaling(v)
	return self.scaling or 1;
end

function Entity:GetYaw()
	return self:GetFacing();
end

function Entity:SetYaw(value)
	self:SetFacing(value);
end


function Entity:DestroyOverlay()
	if(self.overlay) then
		self.overlay:Destroy();
		self.overlay = nil;
	end
end

-- zorder 
function Entity:SetZOrder(zorder)
	if(self.overlay) then
		self.overlay:SetZOrder(zorder)
	end
end

function Entity:GetZOrder()
	if(self.overlay) then
		return self.overlay:GetZOrder()
	end
	return 0;
end


function Entity:CreateOverlay(parent)
	self:DestroyOverlay();
	if(not self.overlay) then
		self.overlay = Overlay:new():init(parent);
		self.overlay.EnableZPass = false;
		self.overlay.paintEvent = function(overlay, painter)
			return self:paintEvent(painter);
		end
	end
	if(not parent) then
		local x, y, z = self:GetPosition();
		self.overlay:SetPosition(x, y, z);
	end
	return self.overlay;
end

-- default to false. solid object is rendered before all transparent ones in the scene. 
function Entity:SetSolid(bIsSolid)
	if(self.overlay) then
		self.overlay:SetSolid(bIsSolid)
	end
end

function Entity:IsSolid()
	if(self.overlay) then
		return self.overlay:SetSolid(bIsSolid)
	end
end

function Entity:GetOpacity()
	return self.opacity or 1;
end

-- @param opacity: [0-1] means transparent. greater than 1 means solid, which allows us to use opacity to set whether object is solid. 
function Entity:SetOpacity(opacity)
	self.opacity = opacity or 1;
	if(self.opacity <= 1) then
		self:SetSolid(false);
	else
		self.opacity = 1;
		self:SetSolid(true);
	end
end

function Entity:SetBoundingRadius(radius)
	if(self.overlay) then
		self.overlay:SetBoundRadius(radius*self:GetScaling())
	end
end

-- overlay pixel picking
function Entity:HasPickingName(pickingName)
	return self.pickingName == pickingName and self:IsPickingEnabled() and self.overlay and (self:GetPickingFrameNumber() == self.overlay:GetPickingFrameNumber());
end

-- NOT USED. find a way to update world position when screen pos and camera changes. 
function Entity:UpdateWorldPositionFromScreenPos()
	local overlay = Entity.rootScreenOverlay;
	if(overlay and overlay.matInverseView and overlay.vWorld) then
		self.screenPos = self.screenPos or mathlib.vector3d:new();
		self.screenPos[1] = self.ui_x/100;
		
		if(self.ui_align == "top") then
			self.screenPos[2] = (self.ui_y + screenHalfHeight) /100;
		elseif(self.ui_align == "bottom") then
			self.screenPos[2] = (self.ui_y - screenHalfHeight) /100;
		else -- if(self.ui_align == "center") then
			self.screenPos[2] = self.ui_y/100;
		end
		self.screenPos[3] = 0;
		local offsetPos = self.screenPos * overlay.matInverseView;
		self:SetPosition(offsetPos[1] + overlay.vWorld[1], offsetPos[2] + overlay.vWorld[2], offsetPos[3] + overlay.vWorld[3]);
	end
end

function Entity:GetPickingFrameNumber()
	return self.pickingFrameNumber;
end

-- virtual function. 
function Entity:paintEvent(painter)
	if(self.overlay:IsPickingPass() and not self:IsPickingEnabled()) then
		return;
	end
	painter:Save()
	painter:PushMatrix();
	if(self:IsScreenMode()) then
		if(self.ui_align == "top") then
			painter:TranslateMatrix(self.ui_x/100, (self.ui_y + screenHalfHeight)/100, 0);
		elseif(self.ui_align == "bottom") then
			painter:TranslateMatrix(self.ui_x/100, (self.ui_y - screenHalfHeight)/100, 0);
		else -- if(self.ui_align == "center") then
			painter:TranslateMatrix(self.ui_x/100, self.ui_y/100, 0);
		end
	end

	painter:SetOpacity(self:GetOpacity());
	if(self:GetFacing()~=0) then
		painter:RotateMatrix(self:GetFacing(), 0,1,0);	
	end

	if(self:GetPitch()~=0) then
		painter:RotateMatrix(self:GetPitch(), 1,0,0);	
	end

	if(self:GetRoll()~=0) then
		painter:RotateMatrix(self:GetRoll(), 0,0,1);	
	end

	if(not self:IsScreenMode()) then
		-- facing positive X
		painter:RotateMatrix(-1.57, 0,1,0);
	end

	-- scaling
	if(self:GetScaling()~=1) then
		local scaling = self:GetScaling();
		painter:ScaleMatrix(scaling, scaling, scaling);
	end

	-- pen color	
	if(self.overlay:IsPickingPass()) then
		self.pickingFrameNumber = self.overlay:GetPickingFrameNumber();
		self.pickingName = self.overlay:GetNextPickingName();
		self.overlay:SetColorAndName(painter, self.pickingName, self.pickingName)
	else
		painter:SetPen(self:GetColor() or "#ffffff");	
	end
	
	-- do the actual local rendering
	self:DoPaint(painter);

	painter:PopMatrix();
	painter:Restore()
end

-- virtual function:
function Entity:DoPaint(painter)
	-- scale 100 times, match 1 pixel to 1 centimeter in the scene. 
	--painter:ScaleMatrix(0.01, 0.01, 0.01);
	--painter:SetPen("#80808080");
	--painter:DrawRect(0, 0, 250, 64);
	--painter:SetPen("#ff0000");
	--painter:DrawText(0,0, "painter:DrawText(0,0,'hello world');");
end

function Entity:GetMainAssetPath()
	return "";
end

function Entity:GetCommandTitle()
	return L"输入HTML/MCML代码"
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

-- disable facing target
function Entity:FaceTarget(x,y,z)
end

-- @param actor: the parent ActorNPC
function Entity:SetActor(actor)
	self.m_actor = actor;
end

-- @param actor: the parent ActorNPC
function Entity:GetActor()
	return self.m_actor;
end

function Entity:SetScreenPos(ui_x, ui_y)
	self.ui_x = ui_x;
	self.ui_y = ui_y;
end

function Entity:GetScreenPos()
	return self.ui_x, self.ui_y;
end

function Entity:SetPosition(x,y,z)
	if(self:IsScreenMode()) then
		if(self.x~=x or self.y~=y or self.z~=z ) then
			self.x, self.y, self.z = x, y, z;

			local bx, by, bz = BlockEngine:block(x, y+0.1, z);
			if(self.bx~=bx or self.by~=by or self.bz~=bz ) then
				self.bx, self.by, self.bz = bx, by, bz;
			end
			self:valueChanged();
		end
	else
		Entity._super.SetPosition(self, x,y,z);
	end
end

-- static function 
function Entity:CreateGetRootScreenOverlay()
	if(not Entity.rootScreenOverlay) then
		Entity:EnableScreenTimer(true);

		Entity.rootScreenOverlay = Overlay:new():init();
		-- renders last after all other 3d transparent overlays
		Entity.rootScreenOverlay:SetRenderOrder(1000);

		-- TODO: can we setup a simple view model transform, instead of using billboarding
--		Entity.rootScreenOverlay.BeginPaint = function(self, painter)
--			painter:SetMatrixMode(0)
--			painter:PushMatrix();
--			painter:LoadIdentityMatrix();
--			painter:TranslateMatrix(0,0,10);
--	
--			painter:SetMatrixMode(1);
--			painter:PushMatrix();
--			painter:LoadIdentityMatrix();
--		end
--
--		Entity.rootScreenOverlay.EndPaint = function(self, painter)
--			painter:SetMatrixMode(0)
--			painter:PopMatrix();
--			painter:SetMatrixMode(1)
--			painter:PopMatrix();
--		end
		
	end
	return Entity.rootScreenOverlay;
end

-- singleton callback
function Entity.WorldUnloaded()
	Entity:EnableScreenTimer(false);
	if(Entity.rootScreenOverlay) then
		Entity.rootScreenOverlay:Destroy()
		Entity.rootScreenOverlay = nil;
	end
end

-- static function 
function Entity:EnableScreenTimer(bEnable)
	if(bEnable) then
		if(not Entity.rootScreenOverlayTick) then
			Entity.rootScreenOverlayTick = Overlay:new():init();
			GameLogic:Connect("WorldUnloaded", Entity.WorldUnloaded, nil, "UniqueConnection")
			Entity.rootScreenOverlayTick.EnableZPass = true;
			Entity.rootScreenOverlayTick:SetUseCameraPos(true);
			Entity.rootScreenOverlayTick.paintZPassEvent = function(self, painter)
				-- we will just make sure that ticking is called before rootScreenOverlay
				Entity.OnScreenTimer();
			end
		end
	else
		if(Entity.rootScreenOverlayTick) then
			Entity.rootScreenOverlayTick:Destroy()
			Entity.rootScreenOverlayTick = nil;
		end
	end
end

-- static function. Only one instance is used.
function Entity.OnScreenTimer(timer)
	local overlay = Entity.rootScreenOverlay;

	local matView = Cameras:GetCurrent():GetViewMatrix();
	local matInverseView = matView:inverse();
	overlay.matInverseView = matInverseView;

	--local viewport = ViewportManager:GetSceneViewport();
	--local screenWidth, screenHeight = Screen:GetWidth()-viewport:GetMarginRight(), Screen:GetHeight() - viewport:GetMarginBottom();
	
	-- x range is in [-500, 500] pixels
	
	local aspect = Cameras:GetCurrent():GetAspectRatio();
	screenHalfHeight = screenHalfWidth / aspect;

	local ui_x, ui_y = 0, 0;
	local ui_z = screenHalfWidth / aspect / math.tan(Cameras:GetCurrent():GetFieldOfView()*0.5);

	local vScreen = mathlib.vector3d:new(ui_x/100, ui_y/100, ui_z/100);
	local vRenderOrigin = Cameras:GetCurrent():GetRenderOrigin();
	local vWorld = vScreen * matInverseView + vRenderOrigin;
	
	local eyePos = Cameras:GetCurrent():GetEyePosition();
	vWorld[1] = vWorld[1] + vRenderOrigin[1] - eyePos[1];
	vWorld[2] = vWorld[2] + vRenderOrigin[2] - eyePos[2];
	vWorld[3] = vWorld[3] + vRenderOrigin[3] - eyePos[3];

	overlay.vWorld = vWorld;
	overlay:SetPosition(vWorld[1], vWorld[2], vWorld[3]);
	overlay:SetLocalTransform(matInverseView);
end

function Entity:IsScreenMode()
	return self.isScreenMode;
end

function Entity:SetScreenMode(isScreenMode)
	if(self.isScreenMode ~= isScreenMode) then
		self.isScreenMode = isScreenMode;

		if(isScreenMode) then
			local parent = self:CreateGetRootScreenOverlay();
			local overlay = self:CreateOverlay(parent);
			overlay:SetZPassOpacity(1);
			overlay.EnableZPass = true;
		else
			local overlay = self:CreateOverlay(nil)
			overlay.EnableZPass = false;
		end
	end
end

-- right click to show editor?
function Entity:OnClick(x, y, z, mouse_button)
	self:clicked(mouse_button);
	return true;
end

function Entity:SetSkipPicking(bSkipPicking)
	if(self.isPickingEnabled ~= not bSkipPicking) then
		self.isPickingEnabled = not bSkipPicking;
		if(self.isPickingEnabled) then
			CodeUI:AddEntityOverlay(self);
		else
			CodeUI:RemoveEntityOverlay(self);
		end
	end
end

function Entity:IsPickingEnabled()
	return self.isPickingEnabled;
end

function Entity:mousePressEvent(mouse_event)
	mouse_event:accept();
end

function Entity:mouseMoveEvent(event)
end

function Entity:mouseReleaseEvent(mouse_event)
	mouse_event:accept();
	if(mouse_event:GetDragDist() < 10) then
		self:OnClick(nil, nil, nil, mouse_event:button())
	end
end

function Entity:Say(text, duration, bAbove3D)
end
