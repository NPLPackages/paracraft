--[[
Title: Memory Actor Block Model 
Author(s): LiXizhi
Date: 2017/6/11
Desc: Actor Entities that is usually a static block model. 
block model does not move outside of a block, but it can be animated with bones. 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/MemoryActorBlockModel.lua");
local MemoryActorBlockModel = commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryActorBlockModel");
local actor = MemoryActorBlockModel:new():Init(itemStack, entity);
actor:Activate();
actor:Deactivate();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/MemoryActor.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/BonesVariable.lua");
local math3d = commonlib.gettable("mathlib.math3d");
local BonesVariable = commonlib.gettable("MyCompany.Aries.Game.Movie.BonesVariable");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")


local Actor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryActor"), commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryActorBlockModel"));
Actor:Property("Name", "MemoryActorBlockModel");
-- whether to retain last bone pose after memory clip is finished. 
Actor:Property({"isRetainPose", true, "IsRetainPose", "SetRetainPose", auto=true});

function Actor:ctor()
end

-- called when enter block world. 
function Actor:Init(itemStack, entity)
	-- base class must be called last, so that child actors have created their own variables on itemStack. 
	if(not Actor._super.Init(self, itemStack, entity)) then
		return;
	end
	local timeseries = self.TimeSeries;
	timeseries:CreateVariableIfNotExist("facing", "LinearAngle");
	timeseries:CreateVariableIfNotExist("scaling", "Linear");
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
		self:FrameMovePlaying(0);
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

	local yaw,scaling;
	yaw = self:TransformToEntityFacing(self:GetValue("facing", curTime));
	scaling = self:GetValue("scaling", curTime);

	if(obj) then
		-- in case of explicit animation
		obj:SetField("Time", curTime); 
		obj:SetField("EnableAnim", false);
		obj:SetField("yaw", yaw or 0);
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

function Actor:Activate()
	self:SetActive(true);
	self:SetTime(0);
	self:LoadBoneAnimationsToEntity();
	self:FrameMovePlaying(0);
	self:BeginFrameMove();
end

-- when deactivated we will release the control to human player with this function.
function Actor:ReleaseEntityControl()
	if(self:IsRetainPose()) then
		-- Do not release animation, but retaining the last bone pose in the memory clip.
	else
		local entity = self:GetEntity();
		if(entity) then
			local obj = entity:GetInnerObject();
			if(obj) then
				obj:SetField("EnableAnim", true);
			end
		end

		if(self.bones_variable) then
			self.bones_variable:UnbindAnimInstance();
		end
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
