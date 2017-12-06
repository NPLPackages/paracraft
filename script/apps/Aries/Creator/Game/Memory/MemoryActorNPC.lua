--[[
Title: Memory Actor NPC
Author(s): LiXizhi
Date: 2017/6/2
Desc: Actor Entities that is NOT the current player. 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/MemoryActorNPC.lua");
local MemoryActorNPC = commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryActorNPC");
local actor = MemoryActorNPC:new():Init(itemStack, entity);
actor:Activate();
actor:Deactivate();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/MemoryActor.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/BonesVariable.lua");
local math3d = commonlib.gettable("mathlib.math3d");
local BonesVariable = commonlib.gettable("MyCompany.Aries.Game.Movie.BonesVariable");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")


local Actor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryActor"), commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryActorNPC"));
Actor:Property("Name", "MemoryActorNPC");
-- ignore any skin parameter set in the movie block. 
Actor:Property({"IgnoreSkin", true, "IsIgnoreSkin", "SetIgnoreSkin", auto=true,});

function Actor:ctor()
end

-- called when enter block world. 
function Actor:Init(itemStack, entity)
	-- base class must be called last, so that child actors have created their own variables on itemStack. 
	if(not Actor._super.Init(self, itemStack, entity)) then
		return;
	end
	local timeseries = self.TimeSeries;
	timeseries:CreateVariableIfNotExist("x", "Linear");
	timeseries:CreateVariableIfNotExist("y", "Linear");
	timeseries:CreateVariableIfNotExist("z", "Linear");
	timeseries:CreateVariableIfNotExist("facing", "LinearAngle");
	timeseries:CreateVariableIfNotExist("pitch", "LinearAngle");
	timeseries:CreateVariableIfNotExist("roll", "LinearAngle");
	timeseries:CreateVariableIfNotExist("HeadUpdownAngle", "Linear");
	timeseries:CreateVariableIfNotExist("HeadTurningAngle", "Linear");
	timeseries:CreateVariableIfNotExist("anim", "Discrete");
	timeseries:CreateVariableIfNotExist("assetfile", "Discrete");
	timeseries:CreateVariableIfNotExist("speedscale", "Discrete");
	timeseries:CreateVariableIfNotExist("scaling", "Linear");
	timeseries:CreateVariableIfNotExist("skin", "Discrete");
	timeseries:CreateVariableIfNotExist("blockinhand", "Discrete");

	self:CheckLoadBonesAnims();
	return self;
end

function Actor:GetBonesVariable()
	if(not self.bones_variable) then
		self.bones_variable = BonesVariable:new():init(self);
	end
	return self.bones_variable;
end

-- load bone animations if not loaded before, this function does nothing if no bones are in the time series. 
function Actor:CheckLoadBonesAnims()
	if(not self.bones_variable) then
		local bones = self:GetTimeSeries():GetChild("bones");
		if(bones) then
			self:GetBonesVariable();
		end
	end
end

-- make sure that the low level C++ attributes contains the latest value.
function Actor:UpdateAnimInstance()
	if(self:GetTime() ~= self.lastPlayTime) then
		local bIsUserControlled = self:IsUserControlled();
		self:FrameMovePlaying(0);
		if(bIsUserControlled) then
			self:SetControllable(bIsUserControlled);
		end
	end
	local bones = self:GetBonesVariable();
	if(bones) then
		bones:UpdateAnimInstance();
	end
end


-- advance the animation by deltaTime;
function Actor:FrameMovePlaying(deltaTime)
	local curTime = self:GetTime();
	self.lastPlayTime = curTime;
	curTime = curTime + (deltaTime or 0);
	if(self:GetLastTime() < curTime and self.lastPlayTime < self:GetLastTime()) then
		-- ensure the last frame is always played
		curTime = self:GetLastTime();
	end
	self:SetTime(curTime);
	local entity = self:GetEntity();
	if(not entity or not curTime or self:GetLastTime() < curTime) then
		self:Deactivate();
		return		
	end

	local obj = entity:GetInnerObject();
	local new_x = self:GetValue("x", curTime);
	local new_y = self:GetValue("y", curTime);
	local new_z = self:GetValue("z", curTime);
	new_x, new_y, new_z = self:TransformToEntityPosition(new_x, new_y, new_z);
	entity:SetPosition(new_x, new_y, new_z);

	local HeadUpdownAngle, HeadTurningAngle, anim, yaw, roll, pitch, skin, speedscale, scaling, gravity, opacity, blockinhand, assetfile;
	HeadUpdownAngle = self:GetValue("HeadUpdownAngle", curTime);
	HeadTurningAngle = self:GetValue("HeadTurningAngle", curTime);
	anim = self:GetValue("anim", curTime);
	yaw = self:TransformToEntityFacing(self:GetValue("facing", curTime));
	roll = self:GetValue("roll", curTime);
	pitch = self:GetValue("pitch", curTime);
	skin = self:GetValue("skin", curTime);
	speedscale = self:GetValue("speedscale", curTime);
	scaling = self:GetValue("scaling", curTime);
	gravity = self:GetValue("gravity", curTime);
	opacity = self:GetValue("opacity", curTime);
	assetfile = self:GetValue("assetfile", curTime);
	blockinhand = self:GetValue("blockinhand", curTime);

	if(obj) then
		-- in case of explicit animation
		obj:SetField("Time", curTime); 
		obj:SetField("IsControlledExternally", true);
		entity:SetCheckCollision(false);
		obj:SetField("EnableAnim", false);

		obj:SetField("yaw", yaw or 0);
		obj:SetField("roll", roll or 0);
		obj:SetField("pitch", pitch or 0);
		
		local bNeedRefreshModel;
		if(entity:SetMainAssetPath(PlayerAssetFile:GetFilenameByName(assetfile))) then
			bNeedRefreshModel = true;
		end
		
		if(skin and not self:IsIgnoreSkin()) then
			entity:SetSkin(skin);
		end
		entity:SetBlockInRightHand(blockinhand);

		if(bNeedRefreshModel) then
			entity:RefreshClientModel();
		end
		
		if(anim) then
			if(anim~=obj:GetField("AnimID", 0)) then
				obj:SetField("AnimID", anim);
			end
			local var = self:GetVariable("anim");
			if(var) then
				-- get the time when model assetfile just takes effect. 
				local start_time = 0;
				local varAssetFile = self:GetVariable("assetfile");
				if(varAssetFile and varAssetFile:GetKeyNum()>1) then
					start_time = varAssetFile:getStartTime(1, curTime);
					if(varAssetFile:GetFirstTime() == start_time) then
						start_time = 0;
					end
				end
				-- get the time, when the animation is first started
				local fromTime = var:getStartTime(1, curTime);
				local localTime = curTime;
				if(var:GetFirstTime() == fromTime) then
					-- force looping from first frame
					fromTime = start_time;
				elseif(fromTime < start_time) then
					-- in case the asset model is changed, the start time is relative to the asset model. 
					fromTime = start_time;
				end

				localTime = curTime - fromTime;
				-- calculate speedscale? 
				local varSpeed = self:GetVariable("speedscale");
				if(varSpeed and varSpeed:GetKeyNum()>1) then
					local fromTimeSpeed, toTimeSpeed = varSpeed:getTimeRange(1, fromTime);
					if(toTimeSpeed >= curTime) then
						localTime = localTime * (speedscale or 1);
					else
						-- we need more calculations, here:  localtime = Sigma_sum{delta_time*speedscale(time)}
						local totalScaledTime = 0;
						local calculatedTime = fromTime;
						local lastTime, lastValue;
						for time, v in varSpeed:GetKeys_Iter(1, fromTimeSpeed-1, curTime) do
							local dt = time - calculatedTime;
							if(dt > 0) then
								totalScaledTime = totalScaledTime + dt * (lastValue or v);
								calculatedTime = time;
							end
							lastTime = time;
							lastValue = v;
						end
						if(curTime > calculatedTime) then
							totalScaledTime = totalScaledTime + (curTime - calculatedTime) * speedscale;
						end
						localTime = totalScaledTime;
					end
				else
					localTime = localTime * (speedscale or 1);
				end
				obj:SetField("AnimFrame", localTime);
				local default_blending_time = 250;
				if( localTime < default_blending_time and 
					-- if this the first animation, set it without using a blending factor. 
					fromTime ~= 0) then
					obj:SetField("BlendingFactor", 1 - localTime / default_blending_time);
				else
					-- this is actually already set in obj:SetField("AnimFrame", localTime); so no need to set again. 
					-- obj:SetField("BlendingFactor", 0);
				end
			end
		end
		obj:SetField("HeadUpdownAngle", HeadUpdownAngle or 0);
		obj:SetField("HeadTurningAngle", HeadTurningAngle or 0);
		
		entity:SetSpeedScale(speedscale or 1);
		obj:SetField("Speed Scale", speedscale or 1);
		obj:SetScale(scaling or 1);
	end
end

-- apply time series to entity 
function Actor:LoadBoneAnimationsToEntity()
	local boneVars = self:GetBonesVariable();
	if(boneVars) then
		boneVars:LoadFromActor();
		return true;
	end
end

-- from data source coordinate to entity coordinate according to CalculateRelativeParams()
function Actor:TransformToEntityPosition(x, y, z)
	x = x + (self.offset_x or 0);
	y = y + (self.offset_y or 0);
	z = z + (self.offset_z or 0);
	
	if(self.offset_facing ~= 0) then
		local dx, _, dz = math3d.vec3Rotate(x - self.origin_x, 0, z - self.origin_z, 0, self.offset_facing, 0);
		x = dx + self.origin_x;
		z = dz + self.origin_z;
	end
	return x,y,z;
end

-- from data source coordinate to entity coordinate according to CalculateRelativeParams()
function Actor:TransformToEntityFacing(facing)
	return facing + (self.offset_facing or 0);
end

-- calculate relative params at time 0 according to the current entity's parameters
-- so that all time series values are relative to time 0, instead of absolute values in data source. 
-- currently, only entity position and facing are taking in to account and snapped to block position and 4 direction. 
-- calculated values in self.offset_x, self.offset_y, self.offset_z, self.offset_facing
function Actor:CalculateRelativeParams()
	local entity = self:GetEntity();
	if(entity) then
		local obj = entity:GetInnerObject();
		if(not obj) then
			return
		end	
		-- relative position
		local entity_bx, entity_by, entity_bz = entity:GetBlockPos();
		local entity_x, entity_y, entity_z = entity:GetPosition();
		local entity_facing = entity:GetFacing() or 0;
		
		local memory_x, memory_y, memory_z = self:GetValue("x", 0), self:GetValue("y", 0), self:GetValue("z", 0);
		local memory_bx, memory_by, memory_bz = BlockEngine:block(memory_x, memory_y+0.1, memory_z);
		local memory_facing = self:GetValue("facing", 0) or 0;
		
		self.offset_x = (entity_bx - memory_bx)*BlockEngine.blocksize;
		self.offset_y = (entity_by - memory_by)*BlockEngine.blocksize;
		self.offset_z = (entity_bz - memory_bz)*BlockEngine.blocksize;
		self.origin_x, self.origin_y, self.origin_z = BlockEngine:real(entity_bx, entity_by, entity_bz);

		-- relative facing
		local memory_dir_facing = Direction.NormalizeFacing(memory_facing)
		local entity_dir_facing = Direction.NormalizeFacing(entity_facing)
		self.offset_facing = mathlib.ToStandardAngle(entity_dir_facing - memory_dir_facing);

		-- echo({self.offset_x, self.offset_y, self.offset_z, self.offset_facing})
	end
end

function Actor:Activate()
	self:SetActive(true);
	self:SetTime(0);
	self:CalculateRelativeParams();
	self:LoadBoneAnimationsToEntity();
	self:FrameMovePlaying(0);
	self:BeginFrameMove();
end

-- when deactivated we will release the control to human player with this function.
function Actor:ReleaseEntityControl()
	local entity = self:GetEntity();
	if(entity) then
		
		local obj = entity:GetInnerObject();
		if(obj) then
			obj:SetField("IsControlledExternally", false);
			entity:SetCheckCollision(true);
			obj:SetField("EnableAnim", true);
		end
	end

	if(self.bones_variable) then
		self.bones_variable:UnbindAnimInstance();
	end
end

-- deactivate and release entity animation control. 
function Actor:Deactivate()
	self:SetActive(false);
	self:EndFrameMove();
	self:ReleaseEntityControl();
end


function Actor:FrameMove(deltaTime)
	self:FrameMovePlaying(deltaTime);
end
