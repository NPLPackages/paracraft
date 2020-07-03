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
NPL.load("(gl)script/ide/System/Core/Color.lua");
local Matrix4 = commonlib.gettable("mathlib.Matrix4");
local Quaternion = commonlib.gettable("mathlib.Quaternion");
local math3d = commonlib.gettable("mathlib.math3d");
local BonesVariable = commonlib.gettable("MyCompany.Aries.Game.Movie.BonesVariable");
local Color = commonlib.gettable("System.Core.Color");
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
-- @param isReuseActor: whether we will reuse actor in the scene with the same name instead of creating a new entity. default to false.
-- @param name: if not provided, it will use the name in itemStack
function Actor:Init(itemStack, movieclipEntity, isReuseActor, name)
	if(not Actor._super.Init(self, itemStack, movieclipEntity, isReuseActor, name)) then
		return;
	end
	local entity = self.entity;
	entity:Connect("clicked", self, self.OnClick);
	entity:Connect("collided", self, self.OnCollideWithEntity);
	entity:Connect("valueChanged", self, self.OnEntityPositionChange);
	return self;
end

function Actor:cloneFrom(fromActor)
	self:SetName(fromActor:GetName())
	if(self:GetTime() ~= fromActor:GetTime()) then
		self:SetTime(fromActor:GetTime());
		self:FrameMove(0, false);
	end
	local entity = self:GetEntity();
	local fromEntity = fromActor:GetEntity();
	if(entity and fromEntity) then
		local x, y, z = fromEntity:GetPosition()
		entity:SetPosition(x, y, z)
		-- for backward compatibility, we will not clone visibility
--		if(entity:IsVisible() ~= fromEntity:IsVisible()) then
--			entity:SetVisible(fromEntity:IsVisible())
--		end
		if(entity:GetFacing() ~= fromEntity:GetFacing()) then
			entity:SetFacing(fromEntity:GetFacing())
		end
		if(entity.scaling ~= fromEntity.scaling) then
			entity:SetScaling(fromEntity:GetScaling())
		end
		if(entity:GetOpacity() ~= fromEntity:GetOpacity()) then
			entity:SetOpacity(fromEntity:GetOpacity())
		end
	end
end

function Actor:ApplyInitParams()
	local pos = self:GetInitParam("pos")
	if(pos) then
		local time = self:GetInitParam("startTime") or 0;
		if(self:GetTime() ~= time) then
			self:SetTime(time);
			self:FrameMove(0);
		end

		local entity = self:GetEntity();
		if(entity) then
			if(pos[1] and pos[2] and pos[3]) then
				self:SetBlockPos(pos[1], pos[2], pos[3]);
			end

			local yaw = self:GetInitParam("yaw")
			if(yaw) then
				entity:SetFacing(yaw*3.14/180);
			end
			local pitch = self:GetInitParam("pitch")
			if(pitch) then
				entity:SetPitch(pitch*3.14/180);
			end
			local roll = self:GetInitParam("roll")
			if(roll) then
				entity:SetRoll(roll*3.14/180);
			end

			local scaling = self:GetInitParam("scaling")
			if(scaling) then
				entity:SetScaling(scaling/100);
			end
		end
	end
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
		if(self:IsAgent() and self.entity) then
			self.entity:SetName(name);
		end
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
		local aabb = entity:GetCollisionAABB();
		local min_x, min_y, min_z = aabb:GetMinValues();
		local max_x, max_y, max_z = aabb:GetMaxValues();
	
		min_x, min_y, min_z = BlockEngine:block(min_x, min_y, min_z);
		max_x, max_y, max_z = BlockEngine:block(max_x, max_y, max_z);

		-- tricky: we will assume, the size of actorname is smaller than 1 block. 
		local actorSize = 1;
		local entities = EntityManager.GetEntitiesByMinMax(min_x-actorSize, min_y-actorSize, min_z-actorSize, max_x+actorSize, max_y+actorSize, max_z+actorSize, EntityManager[self.entityClass])
		if (entities and #entities > 1) then
			for i=1, #entities do
				local entity2 = entities[i];
				if(entity2 ~= entity and entity2:GetActor():GetName() == actorname and aabb:Intersect(entity2:GetCollisionAABB())) then
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

-- static function
local function CanBeCollidedWith_(destEntity, entity)
	if(destEntity:IsVisible() and destEntity:IsStaticBlocker()) then
		return true;
	end
end

function Actor:CalculatePushOut(dx, dy, dz)
	local entity = self:GetEntity();
	if(entity) then
		return entity:CalculatePushOut(dx, dy, dz, CanBeCollidedWith_)
	end
end

-- only bounce in horizontal XZ plain, it just changes the direction/facing of the actor, so that the actor moves away from the collision. 
function Actor:Bounce()
	if(not self.entity) then
		return;
	end
	local aabb = self.entity:GetCollisionAABB();
	local listCollisions = PhysicsWorld:GetCollidingBoundingBoxes(aabb, self.entity, CanBeCollidedWith_);

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
	self:KillTimer();
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
		-- we will move using real position which fixed a bug that moveTo() does not work 
		-- when we are already inside the target block
		bx, by, bz = BlockEngine:real_min(bx+0.5, by, bz+0.5);
		entity:SetPosition(bx, by, bz);
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

function Actor:OnEntityPositionChange()
	if(self:IsPlaying()) then
		self:ResetOffsetPosAndRotation();
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

function Actor:IsRunningEvent(event)
	local last_coroutine = self.codeEvents[event];
	if(last_coroutine) then
		return not last_coroutine:IsFinished();
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
	return Color.FromValueToStr(entity and entity:GetColor());
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

function Actor:SetFacingDegree(degree)
	self:SetFacing(degree/180*math.pi)
end

function Actor:GetFacingDegree()
	return self:GetFacing()*180/math.pi
end

-- floating point block position
function Actor:SetPosX(x)
	local x_, y_, z_ = self:GetPosition();
	self:SetPosition(BlockEngine:real_min(x), y_, z_);
end

function Actor:GetPosX()
	local x, y, z = self:GetPosition();
	if(x) then
		x,y,z = BlockEngine:block_float(x, y, z);
	end
	return x;
end

-- floating point block position
function Actor:SetPosZ(z)
	local x_, y_, z_ = self:GetPosition();
	self:SetPosition(x_, y_, BlockEngine:real_min(z));
end

function Actor:GetPosZ()
	local x, y, z = self:GetPosition();
	if(x) then
		x,y,z = BlockEngine:block_float(x, y, z);
	end
	return z;
end

-- floating point block position
function Actor:SetPosY(y)
	local x_, y_, z_ = self:GetPosition();
	self:SetPosition(x_, BlockEngine:realY(y), z_);
end

function Actor:GetPosY()
	local x, y, z = self:GetPosition();
	if(x) then
		x,y,z = BlockEngine:block_float(x, y, z);
	end
	return y;
end

-- set (physics) group id
-- actors of the same group does not collide with one another
function Actor:SetGroupId(id)
	self.groupId = id and tonumber(id);
end

-- get group id, default to nil
function Actor:GetGroupId()
	return self.groupId;
end

function Actor:SetRollDegree(degree)
	local entity = self:GetEntity();
	if(entity) then	
		entity:SetRoll(degree/180*math.pi);
	end
end

function Actor:GetRollDegree()
	local entity = self:GetEntity();
	return entity and (entity:GetRoll()*180/math.pi) or 0;
end

function Actor:SetPitchDegree(degree)
	local entity = self:GetEntity();
	if(entity) then	
		entity:SetPitch(degree/180*math.pi);
	end
end

function Actor:GetPitchDegree()
	local entity = self:GetEntity();
	return entity and (entity:GetPitch()*180/math.pi) or 0;
end

function Actor:SetMovieActorImp(itemStack, movie_entity)
	movie_entity = movie_entity or self:GetMovieClipEntity();
	local entity = self:GetEntity()
	if(entity) then
		local x, y, z = entity:GetPosition()
		local facing = entity:GetFacing()
		local wasVisible = entity:IsVisible()
		local variables = entity:GetVariables();
		local hasFocus = entity:HasFocus();
		self:DestroyEntity();
		self:Init(itemStack, movie_entity);
		self:FrameMove(self:GetTime() or 0, false);
		entity = self:GetEntity();
		if(entity) then
			if(hasFocus) then
				entity:SetFocus();
			end
			entity:SetPosition(x,y,z);
			entity:SetFacing(facing);
			if(not wasVisible) then
				entity:SetVisible(wasVisible);
			end
			variables:copyTo(entity:GetVariables());
		end
		self:EnableActorPicking(self:IsActorPickingEnabled());
	end
end

-- @param actorName: if nil or 1, it is the first one in movie block
-- if number it is the actor index in movie block, if string, it is its actor name
function Actor:SetMovieActor(actorName)
	actorName = actorName or 1;
	local movie_entity = self:GetMovieClipEntity();
	if(not movie_entity) then
		return
	end
	if(type(actorName) == "number") then
		local index = 0;
		for i = 1, movie_entity.inventory:GetSlotCount() do
			local itemStack = movie_entity.inventory:GetItem(i)
			if (itemStack and itemStack.count > 0) then
				if (itemStack.id == block_types.names.TimeSeriesNPC) then
					index = index + 1;
					if(index == actorName) then
						self:SetMovieActorImp(itemStack, movie_entity);
					end
				end
			end 
		end
	elseif(type(actorName) == "string" and actorName~="") then
		for i = 1, movie_entity.inventory:GetSlotCount() do
			local itemStack = movie_entity.inventory:GetItem(i)
			if (itemStack and itemStack.count > 0) then
				if (itemStack.id == block_types.names.TimeSeriesNPC) then
					if(itemStack:GetDisplayName() == actorName) then
						self:SetMovieActorImp(itemStack, movie_entity);
					end
				end
			end 
		end
	end
end

function Actor:SetMovieBlockPosition(pos)
	if(type(pos) == "table" and pos[1] and pos[2] and pos[3]) then
		local x, y, z = unpack(pos);
		local movie_entity = BlockEngine:GetBlockEntity(x,y,z)
		
		if (movie_entity and movie_entity.class_name == "EntityMovieClip" and  movie_entity.inventory 
			and movie_entity ~= self:GetMovieClipEntity()) then
			for i = 1, movie_entity.inventory:GetSlotCount() do
				local itemStack = movie_entity.inventory:GetItem(i)
				if (itemStack and itemStack.count > 0) then
					if (itemStack.id == block_types.names.TimeSeriesNPC) then
						self:SetMovieActorImp(itemStack, movie_entity);
					end
				end 
			end
		end
	end
end

-- @return {x,y,z} array
function Actor:GetMovieBlockPosition()
	local movie_entity = self:GetMovieClipEntity()
	if(movie_entity) then
		local x, y, z = movie_entity:GetBlockPos()
		return {x, y, z}
	end
end


function Actor:GetTime()
	return self.time or 0;
end

function Actor:SetTime(time)
	self.time = time;
end

function Actor:GetOpacity()
	return self:GetEntity() and self:GetEntity():GetOpacity() or 1;
end

function Actor:SetOpacity(opacity)
	local entity = self:GetEntity();
	if(entity) then	
		if(type(opacity) == "number") then
			entity:SetOpacity(opacity);
		end
	end
end

function Actor:GetIsBlocker()
	return self:GetEntity() and self:GetEntity():IsStaticBlocker();
end

function Actor:SetIsBlocker(bBlocker)
	local entity = self:GetEntity();
	if(entity) then	
		entity:SetStaticBlocker(bBlocker == true);
	end
end

function Actor:SetBillboarded(att)
	local entity = self:GetEntity();
	if entity then
		local obj = entity:GetInnerObject();
		if obj then
			obj:SetField("billboarded", att.yaw == true);
			obj:SetField("billboardedRoll", att.roll == true);
			obj:SetField("billboardedPitch", att.pitch == true);
		end
	end
end

function Actor:IsBillboarded()
	local entity = self:GetEntity();
	if entity then
		local obj = entity:GetInnerObject();
		if obj then
			return obj:GetField("billboarded"), obj:GetField("billboardedRoll"), obj:GetField("billboardedPitch");
		end
	end
	
	return false, false, false;
end

-- @param speed: default to 4 m/s
function Actor:SetWalkSpeed(speed)
	local entity = self:GetEntity();
	if entity then
		if(type(speed) == "string") then
			speed = tonumber(speed)
		end
		if(type(speed) == "number") then
			entity:SetWalkSpeed(speed)
		end
	end
end

function Actor:GetWalkSpeed()
	local entity = self:GetEntity();
	return entity and entity:GetWalkSpeed()
end

-- @param effectId: 0 will use unlit biped selection effect. 1 will use yellow border style. -1 to disable it.
function Actor:SetSelectionEffect(effectId)
	local entity = self:GetEntity();
	if entity then
		if(type(effectId) == "string") then
			effectId = tonumber(effectId)
		end
		if(type(effectId) == "number") then
			entity:SetSelectionEffect(effectId)
		end
	end
end

function Actor:GetSelectionEffect()
	local entity = self:GetEntity();
	return entity and entity:GetSelectionEffect()
end


function Actor:SetShaderCaster(enabled)
	local entity = self:GetEntity();
	if entity then
		if(type(enabled) == "string") then
			enabled = enabled == "true"
		end
		entity:SetShaderCaster(enabled == true)
	end
end

function Actor:IsShaderCaster()
	local entity = self:GetEntity();
	return entity and entity:SetShaderCaster()
end

function Actor:SetServerEntity(enabled)
	local entity = self:GetEntity();
	if entity then
		if(type(enabled) == "string") then
			enabled = enabled == "true"
		end
		entity:SetServerEntity(enabled == true)
	end
end

function Actor:IsServerEntity()
	local entity = self:GetEntity();
	return entity and entity:IsServerEntity()
end

-- actors of the same group does not collide with one another
function Actor:CanBeCollidedWith(entity)
	if(entity.m_actor and self.groupId) then
		return self.entity:IsStaticBlocker() and (self.groupId ~= entity.m_actor.groupId);
	else
		return self.entity:IsStaticBlocker();
	end
end

function Actor:SetVelocity(x,y,z)
	if(type(x) == "table") then
		x, y, z = x[1], x[2], x[3];
	end
	x, y, z = tonumber(x or 0), tonumber(y or 0), tonumber(z or 0)
	if(x and y and z) then
		self.entity:SetDummy(false);
		self.entity:EnableAnimation(true);
		self.entity:SetVelocity(x, y, z);
	end
end

function Actor:AddVelocity(x,y,z)
	if(type(x) == "table") then
		x, y, z = x[1], x[2], x[3];
	end
	x, y, z = tonumber(x or 0), tonumber(y or 0), tonumber(z or 0)
	if(x and y and z) then
		self.entity:SetDummy(false);
		self.entity:EnableAnimation(true);
		return self.entity:AddVelocity(x, y, z);
	end
end

function Actor:GetVelocity()
	return self.entity:GetVelocity();
end

function Actor:SetGravity(v)
	v = tonumber(v or 9.81)
	if(v) then
		self.entity:SetDummy(false);
		self.entity:EnableAnimation(true);
		self.entity:SetGravity(v );
	end
end

function Actor:GetGravity()
	return self.entity:GetGravity();
end

function Actor:SetSurfaceDecay(v)
	v = tonumber(v)
	if(v) then
		self.entity:SetDummy(false);
		self.entity:EnableAnimation(true);
		self.entity:SetSurfaceDecay(v);
	end
end

function Actor:GetSurfaceDecay()
	return self.entity:GetSurfaceDecay();
end

function Actor:SetAirDecay(v)
	v = tonumber(v)
	if(v) then
		self.entity:SetDummy(false);
		self.entity:EnableAnimation(true);
		self.entity:GetPhysicsObject():SetAirDecay(v);
	end
end

function Actor:GetAirDecay()
	return self.entity:GetPhysicsObject():GetAirDecay();
end

function Actor:SetDummy(isDummy)
	self.entity:SetDummy(isDummy == true);
end

function Actor:IsDummy()
	return self.entity:IsDummy();
end

function Actor:GetParentActor()
	local parentInfo = self:GetParentInfo()
	return parentInfo and parentInfo.actor;
end

function Actor:SetParentOffset(pos)
	local parentInfo = self:GetParentInfo()
	if(parentInfo) then
		if(type(pos) == "string") then
			pos = NPL.LoadTableFromString("{"..pos.."}")
		end
		if(type(pos) == "table" and pos[1] and pos[2] and pos[3]) then
			parentInfo.pos = pos;
		end
	end
end

function Actor:SetParentRot(rot)
	local parentInfo = self:GetParentInfo()
	if(parentInfo) then
		if(type(rot) == "string") then
			rot = NPL.LoadTableFromString("{"..rot.."}")
		end
		if(type(rot) == "table" and rot[1] and rot[2] and rot[3]) then
			parentInfo.rot = rot;
		end
	end
end

local internalValues = {
	["name"] = {setter = Actor.SetName, getter = Actor.GetName, isVariable = true}, 
	["time"] = {setter = Actor.SetTime, getter = Actor.GetTime, isVariable = true}, 
	["physicsRadius"] = {setter = Actor.SetPhysicsRadius, getter = Actor.GetPhysicsRadius, isVariable = false}, 
	["physicsHeight"] = {setter = Actor.SetPhysicsHeight, getter = Actor.GetPhysicsHeight, isVariable = false}, 
	["isBlocker"] = {setter = Actor.SetIsBlocker, getter = Actor.GetIsBlocker, isVariable = false}, 
	["groupId"] = {setter = Actor.SetGroupId, getter = Actor.GetGroupId, isVariable = false}, 
	["facing"] = {setter = Actor.SetFacingDegree, getter = Actor.GetFacingDegree, isVariable = false}, 
	-- tricky: pitch and roll are reversed
	["pitch"] = {setter = Actor.SetRollDegree, getter = Actor.GetRollDegree, isVariable = false}, 
	["roll"] = {setter = Actor.SetPitchDegree, getter = Actor.GetPitchDegree, isVariable = false}, 
	["x"] = {setter = Actor.SetPosX, getter = Actor.GetPosX, isVariable = false}, 
	["y"] = {setter = Actor.SetPosY, getter = Actor.GetPosY, isVariable = false}, 
	["z"] = {setter = Actor.SetPosZ, getter = Actor.GetPosZ, isVariable = false}, 
	["color"] = {setter = Actor.SetColor, getter = Actor.GetColor, isVariable = false}, 
	["opacity"] = {setter = Actor.SetOpacity, getter = Actor.GetOpacity, isVariable = false}, 
	["selectionEffect"] = {setter = Actor.SetSelectionEffect, getter = Actor.GetSelectionEffect, isVariable = false}, 
	["isAgent"] = {setter = function() end, getter = Actor.IsAgent, isVariable = false}, 
	["assetfile"] = {setter = Actor.SetAssetFile, getter = Actor.GetAssetFile, isVariable = false}, 
	["playSpeed"] = {setter = Actor.SetPlaySpeed, getter = Actor.GetPlaySpeed, isVariable = false}, 
	["movieblockpos"] = {setter = Actor.SetMovieBlockPosition, getter = Actor.GetMovieBlockPosition, isVariable = false}, 
	["movieactor"] = {setter = Actor.SetMovieActor, isVariable = false}, 

	["walkSpeed"] = {setter = Actor.SetWalkSpeed, getter = Actor.GetWalkSpeed, isVariable = false}, 
	["billboarded"] = {setter = Actor.SetBillboarded, getter = Actor.IsBillboarded, isVariable = false},
	["shadowCaster"] = {setter = Actor.SetShaderCaster, getter = Actor.IsShaderCaster, isVariable = false},
	["isServerEntity"] = {setter = Actor.SetServerEntity, getter = Actor.IsServerEntity, isVariable = false},
	
	["dummy"] = {setter = Actor.SetDummy, getter = Actor.IsDummy, isVariable = false}, 
	["gravity"] = {setter = Actor.SetGravity, getter = Actor.GetGravity, isVariable = false}, 
	["velocity"] = {setter = Actor.SetVelocity, getter = Actor.GetVelocity, isVariable = false}, 
	["addVelocity"] = {setter = Actor.AddVelocity, isVariable = false}, 
	["surfaceDecay"] = {setter = Actor.SetSurfaceDecay, getter = Actor.GetSurfaceDecay, isVariable = false}, 
	["airDecay"] = {setter = Actor.SetAirDecay, getter = Actor.GetAirDecay, isVariable = false}, 

	["initParams"] = {getter = Actor.GetInitParams, isVariable = false},
	["userData"] = {getter = Actor.GetCustomUserData, isVariable = false},
	["parent"] = {getter = Actor.GetParentActor, isVariable = false},
	["parentOffset"] = {setter = Actor.SetParentOffset, isVariable = false},
	["parentRot"] = {setter = Actor.SetParentRot, isVariable = false},
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

function Actor:SetActorValue(name, value, v2, v3)
	local entity = self:GetEntity()
	if(entity and name) then
		if(internalValues[name]) then
			internalValues[name].setter(self, value, v2, v3)
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

	if(self:IsActorPickingEnabled()) then
		entity:Connect("clicked", self, self.OnClick, "UniqueConnection");
		self:EnableActorPicking(true)
	end
	entity:Connect("collided", self, self.OnCollideWithEntity, "UniqueConnection");
	entity:Connect("valueChanged", self, self.OnEntityPositionChange, "UniqueConnection");
end

-- in block coordinates
function Actor:FindActorsByMinMax(min_x, min_y, min_z, max_x, max_y, max_z)
    local actors = {};
	local entities = EntityManager.GetEntitiesByMinMax(min_x, min_y, min_z, max_x, max_y, max_z, EntityManager.EntityCodeActor);
	if(entities and #entities>0) then
		local thisEntity = self:GetEntity();
		for i=1, #entities do
			local entity = entities[i]
			if(entity ~= thisEntity and entity.GetActor) then
				actors[#actors + 1] = entity:GetActor();
			end
		end
	end
	return actors;
end

-- in block coordinates
-- @param halfHeight: default to 0, which is the height search range. if it is 0, we will only search at the current actor's height. 
function Actor:FindActorsByRadius(radius, halfHeight)
	local entity = self:GetEntity();
	if entity then
		halfHeight = halfHeight or 0
		local cx,cy,cz = entity:GetBlockPos();
		return self:FindActorsByMinMax(cx-radius, cy-halfHeight, cz-radius, cx+radius, cy+halfHeight, cz+radius, EntityManager.EntityCodeActor);	
	else
		return {};
	end
end

function Actor:IsMatchMovie(name)
	-- TODO: 
	return false;
end

-- @param movieController: nil or a table of {time = 0, FrameMove = nil}, 
-- movieController.FrameMove(deltaTime) will be assigned by this function.
-- @return true if we can play the matched movie
function Actor:PlayMatchedMovie(name, movieController)
	local channel = MovieManager:CreateGetMovieChannel(name);
	if(channel:GetStartBlockPosition()) then
		-- TODO: 
	end
end

-- get bone's world position and rotation. 
-- @param boneName: like "R_Hand". can be nil.
-- @param localPos: if not nil, this is the local offset
-- @param localRot: if not nil, this is the local rotation {roll, pitch yaw}
-- @param bUseParentRotation: use the parent rotation.
-- @return x,y,z, roll, pitch yaw, scale: in world space.  
-- return nil, if such information is not available, such as during async loading.
function Actor:ComputeBoneWorldPosAndRot(boneName, localPos, localRot, bUseParentRotation)
	local entity = self.entity;
	if(entity) then
		local link_x, link_y, link_z = entity:GetPosition()
		local bFoundTarget;
		self.parentPivot = self.parentPivot or mathlib.vector3d:new();
		
		local parentBoneRotMat;
		if(boneName) then
			local bones = self:GetBonesVariable();
			local boneVar = bones:GetChild(boneName);
			if(boneVar) then
				self:UpdateAnimInstance();
				local pivot = boneVar:GetPivot(true);
				self.parentPivot:set(pivot);
				if(bUseParentRotation) then
					parentBoneRotMat = boneVar:GetPivotRotation(true);
				end
				bFoundTarget = true;
			end
		else
			self.parentPivot:set(0,0,0);
			bFoundTarget = true;
		end 
		if(bFoundTarget) then
			local parentObj = entity:GetInnerObject();
			local parentScale = parentObj:GetScale() or 1;
			local dx,dy,dz = 0,0,0;
			if(not bUseParentRotation and localPos) then
				self.parentPivot:add((localPos[1] or 0), (localPos[2] or 0), (localPos[3] or 0));
			end

			self.parentTrans = self.parentTrans or mathlib.Matrix4:new();
			self.parentTrans = parentObj:GetField("LocalTransform", self.parentTrans);
			self.parentPivot:multiplyInPlace(self.parentTrans);
			self.parentQuat = self.parentQuat or mathlib.Quaternion:new();
			if(parentScale~=1) then
				self.parentTrans:RemoveScaling();
			end
			self.parentQuat:FromRotationMatrix(self.parentTrans);
			if(bUseParentRotation and parentBoneRotMat) then
				self.parentPivotRot = self.parentPivotRot or Quaternion:new();
				self.parentPivotRot:FromRotationMatrix(parentBoneRotMat);
				self.parentQuat:multiplyInplace(self.parentPivotRot);

				if(localRot) then
					self.localRotQuat = self.localRotQuat or Quaternion:new();
					self.localRotQuat:FromEulerAngles((localRot[3] or 0), (localRot[1] or 0), (localRot[2] or 0));
					self.parentQuat:multiplyInplace(self.localRotQuat);
				end
		
				if(localPos) then
					self.localPos = self.localPos or mathlib.vector3d:new();
					self.localPos:set((localPos[1] or 0), (localPos[2] or 0), (localPos[3] or 0));
					self.localPos:rotateByQuatInplace(self.parentQuat);
					dx, dy, dz = self.localPos[1], self.localPos[2], self.localPos[3];
				end
			end
			
			local p_roll, p_pitch, p_yaw = self.parentQuat:ToEulerAnglesSequence("zxy");
			
			if(not bUseParentRotation and localRot) then
				-- just for backward compatibility, bUseParentRotation should be enabled in most cases
				p_roll = (localRot[1] or 0) + p_roll;
				p_pitch = (localRot[2] or 0) + p_pitch;
				p_yaw = (localRot[3] or 0) + p_yaw;
			end
			local x, y, z = link_x + self.parentPivot[1] + dx, link_y + self.parentPivot[2] + dy, link_z + self.parentPivot[3] + dz
			-- This fixed a bug where x or y or z could be NAN(0/0), because GetPivotRotation and GetPivot could return NAN
			if(x == x and y==y and z==z) then
				return x, y, z, p_roll, p_pitch, p_yaw, parentScale;
			end
		end
	end
end

-- @return nil or a table of {actor, boneName, pos, rot, use_rot}
function Actor:GetParentInfo()
	return self.parentInfo;
end

-- attach this code actor to another code actor. 
-- @param parentActor: which actor to attach to. if nil, it will detach from existing actor. 
-- @param boneName: which bone of the parent actor to attach to. default to root bone. 
-- @param pos: nil or 3d position offset
-- @param rot: nil or 3d rotation 
-- @param bUseRotation: whether to use the parent bone's rotation. default to true
function Actor:AttachTo(parentActor, boneName, pos, rot, bUseRotation)
	if(parentActor and parentActor.ComputeBoneWorldPosAndRot) then
		self.parentInfo = self.parentInfo or {};
		local parent = self.parentInfo;
		if(parent.actor ~= parentActor) then
			if(parent.actor) then
				parent.actor:Disconnect("beforeRemoved", self, self.Detach);
			end
			parent.actor = parentActor;
			self:ChangeTimer(10, self:GetFrameMoveInterval());
			parentActor:Connect("beforeRemoved", self, self.Detach, "UniqueConnection");
		end
		parent.boneName = boneName;
		parent.pos = pos;
		parent.rot = rot;
		parent.use_rot = bUseRotation~=false;
	else
		if(self.parentInfo and self.parentInfo.actor) then
			self.parentInfo.actor:Disconnect("beforeRemoved", self, self.Detach);
		end
		self.parentInfo = nil;
		self:KillTimer();
	end
end

function Actor:Detach()
	self:AttachTo(nil)
end

function Actor:UpdatePosAndRotFromParentActor()
	local parent = self:GetParentInfo();
	local entity = self.entity;
	if(parent and entity) then
		local obj = entity:GetInnerObject();
		local new_x, new_y, new_z, roll, pitch, yaw = parent.actor:ComputeBoneWorldPosAndRot(parent.boneName, parent.pos, parent.rot, parent.use_rot); 
		if(new_x) then
			entity:SetPosition(new_x, new_y, new_z);
			obj:SetField("yaw", yaw or 0);
			obj:SetField("roll", roll or 0);
			obj:SetField("pitch", pitch or 0);	
		end
	end
end

function Actor:OnTick()
	if(self.parentInfo) then
		self:UpdatePosAndRotFromParentActor();
	end
end
