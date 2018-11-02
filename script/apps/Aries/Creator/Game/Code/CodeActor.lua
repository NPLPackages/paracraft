--[[
Title: Code Actor
Author(s): LiXizhi
Date: 2018/5/19
Desc: Code actor is the base class for CodeBlock-controlled actors. Code actor is managed by a Code Block.

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeActor.lua");
local CodeActor = commonlib.gettable("MyCompany.Aries.Game.Code.CodeActor");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorNPC.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/EntityCodeActor.lua");
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Physics/PhysicsWorld.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local math3d = commonlib.gettable("mathlib.math3d");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local vector3d = commonlib.gettable("mathlib.vector3d");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Actor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Movie.ActorNPC"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeActor"));
Actor:Property("Name", "CodeActor");
Actor:Property({"entityClass", "EntityCodeActor"});
-- frame move interval in milliseconds
Actor:Property({"frameMoveInterval", 30, "GetFrameMoveInterval", "SetFrameMoveInterval", auto=true});
Actor:Property({"time", 0, "GetTime", "SetTime", auto=true});
Actor:Property({"playSpeed", 1, "GetPlaySpeed", "SetPlaySpeed", auto=true});
Actor:Property({"enableActorPicking", false, "IsActorPickingEnabled", "EnableActorPicking", auto=false});
-- the itemstack(TimeSeries) is changed
Actor:Signal("dataSourceChanged");
Actor:Signal("clicked", function(actor, mouseButton) end);
Actor:Signal("collided", function(actor, fromActor) end);
Actor:Signal("beforeRemoved", function(self) end);
Actor:Signal("nameChanged", function(actor, oldName, newName) end);

function Actor:ctor()
	self.offsetPos = vector3d:new(0,0,0);
	self.fromPos = vector3d:new(0,0,0);
	self.offsetYaw = 0;
	self.codeEvents = {};
end


-- @param itemStack: movie block actor's item stack where time series data source of this entity is stored. 
function Actor:Init(itemStack, movieclipEntity)
	if(not Actor._super.Init(self, itemStack, movieclipEntity)) then
		return;
	end
	local entity = self.entity;
	entity:Connect("clicked", self, self.OnClick);
	entity:Connect("collided", self, self.OnCollideWithEntity);
	
	return self;
end


function Actor:IsActorPickingEnabled()
	return self.enableActorPicking;
end

function Actor:EnableActorPicking(bEnabled)
	self.enableActorPicking = bEnabled;
	if(self.entity) then
		self.entity:SetSkipPicking(not bEnabled);
	end
end

function Actor:SetName(name)
	if(self.name ~= name) then
		local oldName = self.name;
		self.name = name;
		self:nameChanged(self, oldName, name);
	end
end

function Actor:GetName()
	return self.name;
end

function Actor:OnClick(mouse_button)
	self:clicked(self, mouse_button);
end

function Actor:OnCollideWithEntity(fromEntity)
	self:collided(self, fromEntity:GetActor());
end

-- @param block_id: if nil, it means any obstruction block.
-- @return true
function Actor:IsTouchingBlock(block_id)
	if(not self.entity) then
		return;
	end
	local aabb = self.entity:GetCollisionAABB();
	local blockMinX,  blockMinY, blockMinZ = BlockEngine:block(aabb:GetMinValues());
	local blockMaxX,  blockMaxY, blockMaxZ = BlockEngine:block(aabb:GetMaxValues());

    for bx = blockMinX, blockMaxX do
        for bz = blockMinZ, blockMaxZ do
            for by = blockMinY, blockMaxY do
                local block_template = BlockEngine:GetBlock(bx, by, bz);
                if (block_template) then
					if(block_template.id == block_id) then
						return true;
					elseif(not block_id and block_template.obstruction) then
						return true;
					end
                end
            end
		end
	end
end

function Actor:IsTouchingActorByName(actorname)
	local entity = self:GetEntity();
	if(entity) then
		local entities = EntityManager.GetEntitiesByAABBOfType(EntityManager[self.entityClass], entity:GetCollisionAABB())
		if (entities and #entities > 1) then
			for i=1, #entities do
				local entity2 = entities[i];
				if(entity2 ~= entity and entity2:GetActor():GetName() == actorname and entity:GetCollisionAABB():Intersect(entity2:GetCollisionAABB())) then
					return true
				end
			end
		end
		return false;
	end
end

-- @return false;
function Actor:IsTouchingEntity(entity2)
	if(not entity2) then
		return false;
	end
	local entity = self:GetEntity();
	if(entity and entity:GetCollisionAABB():Intersect(entity2:GetCollisionAABB())) then
		return true;
	end
end

-- only bounce in horizontal XZ plain, it just changes the direction/facing of the actor, so that the actor moves aways from the collision. 
function Actor:Bounce()
	if(not self.entity) then
		return;
	end
	local aabb = self.entity:GetCollisionAABB();
	local listCollisions = PhysicsWorld:GetCollidingBoundingBoxes(aabb, self.entity);

	local facing = self.entity:GetFacing();
	local dx, dz;
	dx = math.cos(facing) * 0.1;
	dz = -math.sin(facing) * 0.1;
	local offsetX, offsetZ = dx, dz;
	for i= 1, listCollisions:size() do
		offsetX = listCollisions:get(i):CalculateXOffset(aabb, offsetX, 0.3);
	end
	for i= 1, listCollisions:size() do
		offsetZ = listCollisions:get(i):CalculateZOffset(aabb, offsetZ, 0.3);
	end
	if(offsetX~=dx and offsetX*dx<0) then
		dx = -dx
	end
	if(offsetZ~=dz and offsetZ*dz<0) then
		dz = -dz
	end
	local newFacing = Direction.GetFacingFromOffset(dx, 0, dz);
	self.entity:SetFacing(newFacing);
end

function Actor:IsTouchingPlayers()
	if(not self.entity) then
		return;
	end
	local distExpand = 0.25;
	local aabb = self.entity:GetCollisionAABB();
    local listEntities = EntityManager.GetEntitiesByAABBExcept(aabb:clone():Expand(distExpand, distExpand, distExpand), self.entity);
	if(listEntities) then
		for _, entityCollided in ipairs(listEntities) do
			if(entityCollided:IsPlayer()) then
				return true;
			end
		end
	end
end

function Actor:DistanceTo(actor2)
	local entity = self:GetEntity();
	if(entity) then
		local entity2 = actor2:GetEntity();
		if(entity2) then
			local x, y, z = entity2:GetPosition();
			local dist = entity:GetDistanceSq(x,y,z);
			if(dist > 0.0001) then
				return math.sqrt(dist);
			else
				return dist;
			end
		end
	end
end

function Actor:DeleteThisActor()
	self:OnRemove();
	self:Destroy();
end

function Actor:RestoreEntityControl()
	local entity = self:GetEntity();
	if(entity) then
		entity:SetDummy(false);
		local obj = entity:GetInnerObject();
		if(obj) then
			obj:SetField("IsControlledExternally", false);
			obj:SetField("EnableAnim", true);
			
		end
		self:UnbindAnimInstance()
	end
end

function Actor:OnRemove()
	if(self:IsAgent() and self:GetEntity() == EntityManager.GetPlayer()) then
		self:RestoreEntityControl();
	end

	if(self:HasFocus()) then
		self:RestoreFocus();
	end
	self:beforeRemoved(self);

	Actor._super.OnRemove(self);
end

function Actor:SetVisible(bVisible)
	local entity = self:GetEntity();
	if(entity) then
		entity:SetVisible(bVisible);
	end
end

function Actor:SetHighlight(bHighlight)
	local entity = self:GetEntity();
	if(entity) then
		entity:SetHighlight(bHighlight);
	end
end

function Actor:SetBlockPos(bx, by, bz)
	local entity = self:GetEntity();
	if(entity) then	
		entity:SetDummy(true);
		entity:SetBlockPos(bx, by, bz);
		if(self:IsPlaying()) then
			self:ResetOffsetPosAndRotation();
		end
	end
end

function Actor:GetPosition()
	local entity = self:GetEntity();
	if(entity) then	
		return entity:GetPosition();
	end
end

function Actor:SetPosition(targetX,targetY,targetZ)
	local entity = self:GetEntity();
	if(entity) then	
		entity:SetDummy(true);
		entity:SetPosition(targetX,targetY,targetZ);
		if(self:IsPlaying()) then
			self:ResetOffsetPosAndRotation();
		end
	end
end

function Actor:SetFacingDelta(v)
	local entity = self:GetEntity();
	if(entity) then	
		entity:SetFacingDelta(v);
		if(self:IsPlaying()) then
			self:ResetOffsetPosAndRotation();
		end
	end
end

function Actor:SetFacing(facing)
	local entity = self:GetEntity();
	if(entity) then	
		entity:SetFacing(facing);
		if(self:IsPlaying()) then
			self:ResetOffsetPosAndRotation();
		end
	end
end

function Actor:GetFacing()
	local entity = self:GetEntity()
	if(entity) then
		return entity:GetFacing();
	end
end

function Actor:IsPlaying()
	if(self.playTimer and self.playTimer:IsEnabled()) then
		return true;
	end
end

-- this allows us to play animation in movie block from current movie time to be relative to current entity's position
-- @param time: if nil, it means the current time. 
function Actor:ResetOffsetPosAndRotation()
	local curTime = self:GetTime();
	local entity = self.entity;

	if(not entity or not curTime) then
		return
	end
	local eX, eY, eZ = entity:GetPosition();
	local new_x, new_y, new_z, yaw, roll, pitch = Actor._super.ComputePosAndRotation(self, curTime);
	if(not new_x) then
		new_x, new_y, new_z = eX, eY, eZ;
	end;
	local obj = entity:GetInnerObject();
	self:SetOffsetPos(eX - new_x, eY - new_y, eZ - new_z, new_x, new_y, new_z);
	self:SetOffsetYaw(obj:GetField("yaw", 0) - (yaw or 0), yaw);
end

function Actor:ComputeScaling(curTime)
	local scale = self:GetValue("scaling", curTime)
	if(not scale) then
		local entity = self:GetEntity();
		if(entity) then
			scale = entity:GetScaling();
		end
	end
	return scale or 1;
end

function Actor:SetOffsetYaw(yaw)
	self.offsetYaw = yaw;
end

function Actor:GetOffsetYaw()
	return self.offsetYaw;
end

function Actor:SetOffsetPos(dx,dy,dz, fromX, fromY, fromZ)
	self.offsetPos:set(dx,dy,dz);
	self.fromPos:set(fromX, fromY, fromZ);
end

function Actor:GetOffsetPos()
	return self.offsetPos:get();
end

function Actor:ComputePosAndRotation(curTime)
	local new_x, new_y, new_z, yaw, roll, pitch = Actor._super.ComputePosAndRotation(self, curTime);
	
	if(new_x) then
		yaw = yaw or 0;
		local dx,dy,dz = new_x - self.fromPos[1], new_y - self.fromPos[2],  new_z - self.fromPos[3];
		if((dx~=0 or dy~=0 or dz~=0) and self.offsetYaw ~=0) then
			dx, dy, dz = math3d.vec3Rotate(dx,dy,dz, 0, self.offsetYaw, 0);
			new_x, new_y, new_z = self.fromPos[1] + dx, self.fromPos[2] + dy, self.fromPos[3] + dz;
		end
		dx, dy, dz = self:GetOffsetPos();
		return new_x+dx, new_y+dy, new_z+dz, self:GetOffsetYaw() + yaw, roll, pitch;
	end
end

-- if the same event is called multiple times, the previous one is always stopped before a new one is fired. 
function Actor:SetCodeEvent(event, co)
	local last_coroutine = self.codeEvents[event];
	if(last_coroutine) then
		last_coroutine:Stop();
	end
	self.codeEvents[event] = co;
end

-- if the same event is called multiple times, the previous one is always stopped before a new one is fired. 
function Actor:StopLastCodeEvent(event)
	local last_coroutine = self.codeEvents[event];
	if(last_coroutine) then
		last_coroutine:Stop();
		self.codeEvents[event] = nil;
	end
end

function Actor:InRunningEvent(event)
	local last_coroutine = self.codeEvents[event];
	if(last_coroutine) then
		return last_coroutine:InRunning();
	end
end

-- let the camera focus on this player and take control of it. 
function Actor:SetFocus()
	local entity = self:GetEntity();
	if(entity) then
		entity:SetFocus();
	end
end

function Actor:HasFocus()
	local entity = self:GetEntity();
	if(entity) then
		return entity:HasFocus();
	end
end

function Actor:RestoreFocus()
	EntityManager.GetPlayer():SetFocus();
end

function Actor:GetPhysicsRadius()
	local entity = self:GetEntity();
	return entity and (entity:GetPhysicsRadius() * BlockEngine.blocksize_inverse) or 0.25;
end

function Actor:SetPhysicsRadius(radius)
	local entity = self:GetEntity();
	if(entity) then	
		radius = tonumber(radius);
		entity:SetPhysicsRadius(radius * BlockEngine.blocksize);
	end
end

function Actor:GetPhysicsHeight()
	local entity = self:GetEntity();
	return entity and (entity:GetPhysicsHeight() * BlockEngine.blocksize_inverse) or 1;
end

function Actor:SetPhysicsHeight(height)
	local entity = self:GetEntity();
	if(entity) then	
		height = tonumber(height);
		if(height) then
			entity:SetPhysicsHeight(height * BlockEngine.blocksize);
		end
	end
end

function Actor:GetAssetFile()
	local entity = self:GetEntity();
	return entity and entity:GetMainAssetPath();
end

function Actor:SetAssetFile(filename)
	local entity = self:GetEntity();
	if(entity) then	
		filename = PlayerAssetFile:GetFilenameByName(filename)
		entity:SetMainAssetPath(filename);
	end
end

function Actor:GetColor()
	local entity = self:GetEntity();
	return entity and entity:GetColor();
end

function Actor:SetColor(color)
	local entity = self:GetEntity();
	if(entity) then	
		entity:SetColor(color);
	end
end

function Actor:Say(text, duration)
	local entity = self:GetEntity();
	if(entity) then	
		entity:Say(text, duration)
	end
end

local internalValues = {
	["name"] = {setter = Actor.SetName, getter = Actor.GetName, isVariable = true}, 
	["physicsRadius"] = {setter = Actor.SetPhysicsRadius, getter = Actor.GetPhysicsRadius, isVariable = false}, 
	["physicsHeight"] = {setter = Actor.SetPhysicsHeight, getter = Actor.GetPhysicsHeight, isVariable = false}, 
	["color"] = {setter = Actor.SetColor, getter = Actor.GetColor, isVariable = false}, 
	["isAgent"] = {setter = function() end, getter = Actor.IsAgent, isVariable = false}, 
	["assetfile"] = {setter = Actor.SetAssetFile, getter = Actor.GetAssetFile, isVariable = false}, 
}

function Actor:GetActorValue(name)
	local entity = self:GetEntity()
	if(entity and name) then
		if(internalValues[name]) then
			return internalValues[name].getter(self)
		end
		local variables = entity:GetVariables();
		if(variables) then
			return variables:GetVariable(name);
		end
	end
end


function Actor:SetActorValue(name, value)
	local entity = self:GetEntity()
	if(entity and name) then
		if(internalValues[name]) then
			internalValues[name].setter(self, value)
			if(not internalValues[name].isVariable) then
				return
			end
		end
		local variables = entity:GetVariables();
		if(variables) then
			variables:SetVariable(name, value);
		end
	end
end

function Actor:BecomeAgent(entity)
	Actor._super.BecomeAgent(self, entity);
end