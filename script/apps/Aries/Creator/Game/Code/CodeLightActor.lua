--[[
Title: Code UI Actor
Author(s): LiXizhi
Date: 2018/5/19
Desc: UI actor that is always aligned with camera
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeLightActor.lua");
local CodeLightActor = commonlib.gettable("MyCompany.Aries.Game.Code.CodeLightActor");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorLight.lua");
NPL.load("(gl)script/ide/math/vector.lua");
local math3d = commonlib.gettable("mathlib.math3d");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local vector3d = commonlib.gettable("mathlib.vector3d");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Actor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Movie.ActorLight"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeLightActor"));
Actor:Property("Name", "CodeLightActor");
Actor:Property({"entityClass", "EntityCodeActor"});
Actor:Property({"enableActorPicking", false, "IsActorPickingEnabled", "EnableActorPicking", auto=false});
-- frame move interval in milliseconds
Actor:Property({"frameMoveInterval", 30, "GetFrameMoveInterval", "SetFrameMoveInterval", auto=true});
Actor:Property({"sentientRadius", -1, "GetSentientRadius", "SetSentientRadius", auto=true});
Actor:Property({"time", 0, "GetTime", "SetTime", auto=true});
Actor:Property({"playSpeed", 1, "GetPlaySpeed", "SetPlaySpeed", auto=true});
Actor:Signal("dataSourceChanged");
Actor:Signal("clicked", function(actor, mouseButton) end);
Actor:Signal("beforeRemoved", function(self) end);
Actor:Signal("nameChanged", function(actor, oldName, newName) end);

function Actor:ctor()
	self.offsetPos = vector3d:new(0,0,0);
	self.fromPos = vector3d:new(0,0,0);
	self.offsetYaw = 0;
	self.codeEvents = {};
	self:EnablePicking(false);
end

-- @param itemStack: movie block actor's item stack where time series data source of this entity is stored. 
function Actor:Init(itemStack, movieclipEntity)
	if(not Actor._super.Init(self, itemStack, movieclipEntity)) then
		return;
	end
	local entity = self.entity;
	entity:Connect("clicked", self, self.OnClick);
	entity:Connect("valueChanged", self, self.OnEntityPositionChange);
	return self;
end

function Actor:cloneFrom(fromActor)
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
		end
	end
end

function Actor:IsActorPickingEnabled()
	return self.enableActorPicking;
end

function Actor:EnableActorPicking(bEnabled)
	self.enableActorPicking = bEnabled;
	self:EnablePicking(bEnabled);
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

function Actor:IsTouchingBlock(block_id)
	return false;
end

function Actor:IsTouchingActorByName(actorname)
	return false;
end

-- @return false;
function Actor:IsTouchingEntity(entity2)
	return false;
end

function Actor:Bounce()
end

function Actor:IsTouchingPlayers()
	return false;
end

function Actor:DistanceTo(actor2)
	return 999999
end

function Actor:DeleteThisActor()
	self:OnRemove();
	self:Destroy();
end

function Actor:OnRemove()
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
	self:SetOffsetPos(eX - new_x, eY - new_y, eZ - new_z, new_x, new_y, new_z);
	self:SetOffsetYaw(entity:GetFacing() - (yaw or 0), yaw);
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

function Actor:SetFocus()
end

function Actor:HasFocus()
	return false;
end

function Actor:RestoreFocus()
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

function Actor:GetDisplayText()
	return self.displayText or self:GetText();
end

function Actor:SetDisplayText(text)
	self.displayText = text;
	self:SetText(text);
end

function Actor:ComputeText(curTime)
	return self.displayText or self:GetValue("text", curTime);
end

function Actor:Say(text, duration)
	self:SetDisplayText(text or "");
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
function Actor:SetGroupId(id)
	self.groupId = id;
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
		
		self:DestroyEntity();
		self:Init(itemStack, movie_entity);
		self:FrameMove(self:GetTime(), false);
		entity = self:GetEntity();
		entity:SetPosition(x,y,z);
		entity:SetFacing(facing);
		
		if(not wasVisible) then
			entity:SetVisible(wasVisible);
		end
		variables:copyTo(entity:GetVariables());
		
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
				if (itemStack.id == block_types.names.TimeSeriesOverlay) then
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
				if (itemStack.id == block_types.names.TimeSeriesOverlay) then
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
					if (itemStack.id == block_types.names.TimeSeriesLight) then
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
	["groupId"] = {setter = Actor.SetGroupId, getter = Actor.GetGroupId, isVariable = false}, 
	["color"] = {setter = Actor.SetColor, getter = Actor.GetColor, isVariable = false}, 
	["text"] = {setter = Actor.SetDisplayText, getter = Actor.GetDisplayText, isVariable = false}, 
	["facing"] = {setter = Actor.SetFacingDegree, getter = Actor.GetFacingDegree, isVariable = false}, 
	["sentientRadius"] = {setter = Actor.SetSentientRadius, getter = Actor.GetSentientRadius, isVariable = false}, 
	-- tricky: pitch and roll are reversed
	["pitch"] = {setter = Actor.SetRollDegree, getter = Actor.GetRollDegree, isVariable = false}, 
	["roll"] = {setter = Actor.SetPitchDegree, getter = Actor.GetPitchDegree, isVariable = false}, 
	["x"] = {setter = Actor.SetPosX, getter = Actor.GetPosX, isVariable = false}, 
	["y"] = {setter = Actor.SetPosY, getter = Actor.GetPosY, isVariable = false}, 
	["z"] = {setter = Actor.SetPosZ, getter = Actor.GetPosZ, isVariable = false}, 
	["playSpeed"] = {setter = Actor.SetPlaySpeed, getter = Actor.GetPlaySpeed, isVariable = false}, 
	["movieblockpos"] = {setter = Actor.SetMovieBlockPosition, getter = Actor.GetMovieBlockPosition, isVariable = false}, 
	["movieactor"] = {setter = Actor.SetMovieActor, isVariable = false}, 
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
end

function Actor:IsMatchMovie(name)
	return false;
end

-- @param movieController: nil or a table of {time = 0, FrameMove = nil}, 
-- movieController.FrameMove(deltaTime) will be assigned by this function.
-- @return true if we can play the matched movie
function Actor:PlayMatchedMovie(name, movieController)
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
