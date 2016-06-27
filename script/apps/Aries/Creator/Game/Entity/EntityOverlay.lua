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
local ContainerView = commonlib.gettable("MyCompany.Aries.Game.Items.ContainerView");
local InventoryBase = commonlib.gettable("MyCompany.Aries.Game.Items.InventoryBase");
local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer");
local Overlay = commonlib.gettable("System.Scene.Overlays.Overlay");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local math_abs = math.abs;
local math_random = math.random;
local math_floor = math.floor;

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.Entity"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityOverlay"));

Entity:Property({"scaling", 1.0, "GetScaling", "SetScaling"});
Entity:Property({"facing", 0, "GetFacing", "SetFacing", auto=true});
Entity:Property({"pitch", 0, "GetPitch", "SetPitch", auto=true});
Entity:Property({"opacity", 1, "GetOpacity", "SetOpacity", auto=true});
Entity:Property({"roll", 0, "GetRoll", "SetRoll", auto=true});
Entity:Property({"color", "#ffffff", "GetColor", "SetColor", auto=true});

Entity:Signal("cameraHidden");
Entity:Signal("cameraShown");
Entity:Signal("targetChanged", function(newTarget, oldTarget) end);

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

function Entity:ctor()
	self.inventory = InventoryBase:new():Init();
	self.inventoryView = ContainerView:new():Init(self.inventory);
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
	if(self.overlay) then
		self.overlay:Destroy();
		self.overlay = nil;
	end
	Entity._super.Destroy(self);
end

function Entity:SetScaling(v)
	self.scaling = v;
end

function Entity:GetScaling(v)
	return self.scaling or 1;
end

function Entity:CreateOverlay()
	if(not self.overlay) then
		self.overlay = Overlay:new():init();
		self.overlay.EnableZPass = false;
		self.overlay.paintEvent = function(overlay, painter)
			return self:paintEvent(painter);
		end
	end
	local x, y, z = self:GetPosition();
	self.overlay:SetPosition(x, y, z);
	return self.overlay;
end

function Entity:SetBoundingRadius(radius)
	if(self.overlay) then
		self.overlay:SetBoundRadius(radius*self:GetScaling())
	end
end

-- virtual function. 
function Entity:paintEvent(painter)
	if(self.overlay:IsPickingPass()) then
		return;
	end
	painter:Save()
	painter:PushMatrix();
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

	-- facing positive X
	painter:RotateMatrix(-1.57, 0,1,0);

	-- scaling
	if(self:GetScaling()~=1) then
		local scaling = self:GetScaling();
		painter:ScaleMatrix(scaling, scaling, scaling);
	end

	-- pen color	
	painter:SetPen(self:GetColor() or "#ffffff");

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

-- right click to show editor?
function Entity:OnClick(x, y, z, mouse_button)
	return Entity._super.OnClick(self, x, y, z, mouse_button);
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