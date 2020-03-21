--[[
Title: Bones variable
Author(s): LiXizhi
Date: 2015/9/8
Desc: all explicitly animated bones in actor. 
We can select one or all bones. Select no bones means querying all bones's key, values. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/BonesVariable.lua");
local BonesVariable = commonlib.gettable("MyCompany.Aries.Game.Movie.BonesVariable");
BonesVariables:init(actor)
BonesVariables:SetSelectedBone(name)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/BoneVariable.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/MultiAnimBlock.lua");
local MultiAnimBlock = commonlib.gettable("MyCompany.Aries.Game.Common.MultiAnimBlock");
local BoneVariable = commonlib.gettable("MyCompany.Aries.Game.Movie.BoneVariable");
local ATTRIBUTE_FIELDTYPE = commonlib.gettable("System.Core.ATTRIBUTE_FIELDTYPE");

local BonesVariable = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Common.MultiAnimBlock"), commonlib.gettable("MyCompany.Aries.Game.Movie.BonesVariable"));
BonesVariable.name = "bones";
BonesVariable.actorBoneRange = "on"; -- temp value

function BonesVariable:ctor()
	self.selectedName = nil;
	-- from name to variable
	self.variable_names = nil;
end

function BonesVariable:init(actor)
	self.actor = actor;
	self:LoadFromActor();
	return self;
end

function BonesVariable:GetActor()
	return self.actor;
end

-- get animation instance attribute model.
function BonesVariable:GetAnimInstance()
	if(not self.animInstance or not self.animInstance:IsValid()) then
		local entity = self.actor:GetEntity();
		if(entity) then
			local obj = entity:GetInnerObject();
			if(obj) then
				self.obj_attr = obj:GetAttributeObject();
				self.animInstance = self.obj_attr:GetChildAt(1,1);
			end
		end
	end
	return self.animInstance;
end

-- this should be called when animation instance's asset file is changed. 
function BonesVariable:OnAssetFileChanged()
	self:UnloadCachedVariables();
end

-- make sure that the low level C++ attributes contains the latest value.
function BonesVariable:UpdateAnimInstance()
	local anim = self:GetAnimInstance();
	if(anim) then
		anim:CallField("UpdateModel");
	end
end

-- clear the binded entity's bone external animations. 
function BonesVariable:UnbindAnimInstance()
	local animInstance = self:GetAnimInstance();
	if(not animInstance) then
		return;
	end
	animInstance:RemoveAllDynamicFields();
end

function BonesVariable:UnloadCachedVariables()
	if(self.bone_count) then
		self.variables:clear();
		self.variable_names = nil;
		self.bone_count = nil;
	end
end

-- load data from actor's timeseries to animation instance in C++ side if any 
function BonesVariable:LoadFromActor()
	local animInstance = self:GetAnimInstance();
	if(not animInstance) then
		return;
	end
	animInstance:RemoveAllDynamicFields();
	self:UnloadCachedVariables();

	local actor = self.actor;
	local bones = actor:GetTimeSeries():GetChild("bones");
	if(bones) then
		local HasEmptyVariable;
		local HasKeys;
		for i=1, bones:GetVariableCount() do
			local var = bones:GetVariableByIndex(i);
			if(var) then
				local keyCount = var:GetKeyNum();
				if(keyCount > 0) then
					local name = var.name;
					if(name == "range") then
						self.hasRange = true;
					else
						if(name:match("_rot$")) then
							animInstance:AddDynamicField(name, ATTRIBUTE_FIELDTYPE.FieldType_AnimatedQuaternion);
						else
							animInstance:AddDynamicField(name, ATTRIBUTE_FIELDTYPE.FieldType_AnimatedVector3);
						end
						local i=0;
						animInstance:SetFieldKeyNums(name, keyCount);
						for time, v in var:GetKeys_Iter(1, -1, 999999) do
							animInstance:SetFieldKeyTime(name, i, time);
							animInstance:SetFieldKeyValue(name, i, v);
							i = i + 1;
						end
						HasKeys = true;
					
					end
				else
					-- this should never happen
					HasEmptyVariable = true;
				end
			else
				HasEmptyVariable = true;
			end
		end
		if(not HasKeys or HasEmptyVariable) then
			self:RemoveEmptyVariables();
		end
	end
end

function BonesVariable:SaveToActor()
	for name, var in pairs(self:GetVariables()) do
		var:SaveToTimeVar();
	end
end

-- this is a special variable for specifying the ranges when bone animations are enabled. 
function BonesVariable:GetRangeVariable(bCreateGet)
	local var = self:GetTimeVariable("range")
	if(not var and bCreateGet) then
		var = self:CreateTimeVariable("range")
		self.hasRange = true;
	end
	return var;
end

function BonesVariable:HasRange()
	return self.hasRange;
end

function BonesVariable:IsEnabledAtTime(time)
	local var = self:GetRangeVariable()
	if(var) then
		local value = var:GetTime(1, time);
		return value == nil or value == "on";
	end
end

function BonesVariable:AutoEnableBonesAtTime(curTime)
	if(self:HasRange()) then
		local var = self:GetRangeVariable()
		if(var) then
			local actorBoneRange = var:getValue(1, curTime) or "on"
			if(actorBoneRange ~= self.actorBoneRange) then
				self.actorBoneRange = actorBoneRange;
				local time = actorBoneRange == "on" and -1 or -1000;
				for name, var in pairs(self:GetVariables()) do
					var:SetTime(time)
				end
			end
		end
	end
end

-- return the time series variable
function BonesVariable:GetTimeVariable(name)
	local bones = self.actor:GetTimeSeries():GetChild("bones");
	if(bones) then
		return bones:GetVariable(name);
	end
end

function BonesVariable:CreateTimeVariable(name)
	local bones = self.actor:GetTimeSeries():GetChild("bones");
	if(not bones) then
		bones = self.actor:GetTimeSeries():CreateChild("bones");
	end
	return bones:CreateVariableIfNotExist(name, "Discrete");
end

function BonesVariable:RemoveEmptyVariables()
	local bones = self.actor:GetTimeSeries():GetChild("bones");
	if(bones) then
		local hasBoneAnim;
		local removeVars;
		-- remove empty bone variable or even the entire bones. 
		for i=1, bones:GetVariableCount() do
			local var = bones:GetVariableByIndex(i);
			local keyCount = var:GetKeyNum();
			if(keyCount > 0) then
				hasBoneAnim = true;
			else
				removeVars = removeVars or {};
				removeVars[#removeVars+1] = var.name;
			end
		end
		if(not hasBoneAnim) then
			self.actor:GetTimeSeries():RemoveChild("bones");
		elseif(removeVars) then
			for i, name in ipairs(removeVars) do
				bones:RemoveVariable(name);
			end
		end
	end
end

-- this function will create all sub bone variable. There is a performance issue, so do not call this at play time
-- unless absolutely necessary, such as when some actor is linked to child bone's this actor.
-- return the time series variable
function BonesVariable:GetChild(name)
	if(name) then
		if(self.variable_names) then
			local child = self.variable_names[name];
			if(child) then
				return child;
			end
		end
		if((self.bone_count or 0) == 0) then
			local animInstance = self:GetAnimInstance();
			-- this fixed a bug of async loading when bone data is not available at play time.  
			if(animInstance and animInstance:GetChildCount(1)>0) then
				return self:GetVariables()[name];
			end
		end
	end
end

-- create get bone variables for advanced editing
-- This function is only called, when wants to edit variables. 
function BonesVariable:GetVariables()
	if(not self.variable_names) then
		self.variable_names = {};
		self.variables:clear();
		local animInstance = self:GetAnimInstance();
		if(animInstance) then
			self.bone_count = animInstance:GetChildCount(1);
			for i = 0, self.bone_count do
				local bone_attr = animInstance:GetChildAt(i, 1)
				local name = bone_attr:GetField("name", "");
				local var = self.variable_names[name];
				if(not var) then
					var = BoneVariable:new():init(bone_attr, animInstance, self);
					self.variable_names[name] = var;
					self.variables:add(var);
				end
			end
		end
		local var = self:GetRangeVariable(true)
		self.variables:add(var);
	end
	return self.variable_names;
end

function BonesVariable:SetSelectedBone(name)
	if(name) then
		if(self:GetVariables()[name]) then
			self.selectedName = name;
		end
	else
		self.selectedName = nil;
	end
end

function BonesVariable:GetSelectedBoneName()
	return self.selectedName;
end

-- get selected bone variable. 
function BonesVariable:GetSelectedBone()
	if(self.selectedName) then
		return self:GetVariables()[self.selectedName];
	end
end

-- variable is returned as an array of individual variable value at the given time. 
function BonesVariable:getValue(anim, time)
	local var = self:GetSelectedBone();
	if(var) then
		return var:getValue(anim, time);
	else
		local vars = BonesVariable._super.getValue(self, anim, time);
		local text = nil;

		local rangeVar = self:GetRangeVariable();
		if(rangeVar) then
			text = rangeVar:getValue(anim, time);
			if(text) then
				text = text == "on" and L"启用骨骼动画" or L"禁止骨骼动画"
				text = text.."\n"
			end
		end

		if(type(vars) == "table") then
			for index, v in pairs(vars) do
				local var = self:GetVariable(index)
				if(var and var.name) then
					text = (text or "")..var.name..";";
				end
			end
		end

		return text;
	end
end

function BonesVariable:AddKey(time, data)
	local var = self:GetSelectedBone();
	if(var) then
		var:AddKey(time, value);
	else
		return BonesVariable._super.AddKey(self, time, data);
	end
end

function  BonesVariable:GetLastTime()
	local var = self:GetSelectedBone();
	if(var) then
		return var:GetLastTime();
	else
		return BonesVariable._super.GetLastTime(self);
	end
end

function BonesVariable:MoveKeyFrame(key_time, from_keytime)
	local var = self:GetSelectedBone();
	if(var) then
		var:MoveKeyFrame(key_time, from_keytime);
	else
		return BonesVariable._super.MoveKeyFrame(self, key_time, from_keytime);
	end
end

function BonesVariable:CopyKeyFrame(key_time, from_keytime)
	local var = self:GetSelectedBone();
	if(var) then
		var:CopyKeyFrame(key_time, from_keytime);
	else
		return BonesVariable._super.CopyKeyFrame(self, key_time, from_keytime);
	end
end

-- Update or insert (Upsert) a key frame at given time.
-- @param data: data is cloned before updating. 
function BonesVariable:UpsertKeyFrame(key_time, data)
	local var = self:GetSelectedBone();
	if(var) then
		var:UpsertKeyFrame(key_time, data);
	else
		return BonesVariable._super.UpsertKeyFrame(self, key_time, data);
	end
end

function BonesVariable:RemoveKeyFrame(key_time)
	local var = self:GetSelectedBone();
	if(var) then
		var:RemoveKeyFrame(key_time);
	else
		return BonesVariable._super.RemoveKeyFrame(self, key_time);
	end
end

function BonesVariable:ShiftKeyFrame(shift_begin_time, offset_time)
	local var = self:GetSelectedBone();
	if(var) then
		var:ShiftKeyFrame(shift_begin_time, offset_time);
	else
		return BonesVariable._super.ShiftKeyFrame(self, shift_begin_time, offset_time);
	end
end

function BonesVariable:RemoveKeysInTimeRange(fromTime, toTime)
	local var = self:GetSelectedBone();
	if(var) then
		var:RemoveKeysInTimeRange(fromTime, toTime);
	else
		return BonesVariable._super.RemoveKeysInTimeRange(self, fromTime, toTime);
	end
end


function BonesVariable:TrimEnd(time)
	local var = self:GetSelectedBone();
	if(var) then
		var:TrimEnd(time);
	else
		return BonesVariable._super.TrimEnd(self, time);
	end
end

-- iterator that returns, all (time, values) pairs between (TimeFrom, TimeTo].  
-- the iterator works fine when there are identical time keys in the animation, like times={0,1,1,2,2,2,3,4}.  for time keys in range (0,2], 1,1,2,2,2, are returned. 
function BonesVariable:GetKeys_Iter(anim, TimeFrom, TimeTo)
	local var = self:GetSelectedBone();
	if(var) then
		return var:GetKeys_Iter(anim, TimeFrom, TimeTo);
	else
		-- this ensures that all variables are created. 
		self:GetVariables();
		return BonesVariable._super.GetKeys_Iter(self, anim, TimeFrom, TimeTo);
	end
end

-- a single attribute like rotation, trans or scaling on a bone. 
-- @param name: such as "boneName_rot", "boneName_trans", "boneName_scale"
function BonesVariable:GetBoneAttributeVariableByName(name)
	local boneName, typeName = (name or ""):match("^(.*)_(%w+)$")
	if(boneName and typeName) then
		local boneVar = self:GetChild(boneName);
		if(boneVar) then
			local boneAttrVar;
			if(boneVar:GetRotName() == name) then
				boneAttrVar = boneVar:GetVariable(1)
			elseif(boneVar:GetTransName() == name) then
				boneAttrVar = boneVar:GetVariable(2)
			elseif(boneVar:GetScaleName() == name) then
				boneAttrVar = boneVar:GetVariable(3)
			end
			return boneAttrVar;
		end
	end
end