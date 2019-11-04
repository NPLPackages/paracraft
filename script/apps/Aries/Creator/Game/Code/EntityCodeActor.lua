--[[
Title: Actor entity animated by code block
Author(s): LiXizhi
Date: 2018/5/31
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/EntityCodeActor.lua");
local EntityCodeActor = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCodeActor")
local entity = MyCompany.Aries.Game.EntityManager.EntityCodeActor:new({x,y,z,radius});
entity:Attach();
-------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityNPC"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCodeActor"));

-- class name
Entity.class_name = "CodeActor";
Entity:Signal("clicked", function(mouse_button) end)
Entity:Signal("collided", function(fromEntity) end)

-- register class
EntityManager.RegisterEntityClass(Entity.class_name, Entity);

function Entity:ctor()
	self:SetPersistent(false);
	self:SetDummy(true);
	self:SetCanRandomMove(false);
	self:SetStaticBlocker(true);
	self:SetSurfaceDecay(1.0);
end

function Entity:init()
	if(not Entity._super.init(self)) then
		return;
	end
	local obj = self:GetInnerObject();
	if(obj) then
		obj:SetField("Physics Radius", self:GetPhysicsRadius());
		obj:SetField("PhysicsHeight", self:GetPhysicsHeight());
	end
	return self;
end
		

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	return node;
end

function Entity:OnClick(x, y, z, mouse_button)
	if(self:IsRemote() and self:IsServerEntity()) then
		GameLogic.GetPlayer():AddToSendQueue(GameLogic.Packets.PacketClickEntity:new():Init(entity or GameLogic.GetPlayer(), self, mouse_button, x, y, z));
	else
		self:clicked(mouse_button);
	end
	return true;
end

-- called every frame
function Entity:FrameMove(deltaTime)
	if(GameLogic.isRemote) then
		EntityManager.EntityMovable.FrameMove(self, deltaTime);		
	else
		local mob = self:UpdatePosition();
		if(not mob) then
			return;
		end
		if(not self:IsDummy()) then
			self:MoveEntity(deltaTime);
		end
	end
end

-- called after focus is set
function Entity:OnFocusIn()
	self.has_focus = true;
	local obj = self:GetInnerObject();
	if(obj) then
		if(obj.ToCharacter) then
			obj:ToCharacter():SetFocus();
		end
	end
	self:focusIn();
end

-- called before focus is lost
function Entity:OnFocusOut()
	self.has_focus = nil;
	self:focusOut();
end

-- check collision with nearby entities and broadcast collision event
function Entity:BroadcastCollision()
	local entities = EntityManager.GetEntitiesByAABBOfType(Entity, self:GetCollisionAABB())
	if (entities and #entities > 1) then
		for i=1, #entities do
			local entity2 = entities[i];
			if(entity2 ~= self and entity2:IsStaticBlocker() and self:GetCollisionAABB():Intersect(entity2:GetCollisionAABB())) then
				entity2:collided(self);
				self:collided(entity2);
			end
		end
	end
end

-- Returns true if the entity takes up space in its containing block, such as animals,mob and players. 
function Entity:CanBeCollidedWith(entity)
	return self:GetActor():CanBeCollidedWith(entity)
end