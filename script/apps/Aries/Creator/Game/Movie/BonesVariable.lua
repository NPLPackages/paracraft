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

-- make sure that the low level C++ attributes contains the latest value.
function BonesVariable:UpdateAnimInstance()
	local anim = self:GetAnimInstance();
	if(anim) then
		anim:CallField("UpdateModel");
	end
end

-- load data from actor's timeseries to animation instance in C++ side if any 
function BonesVariable:LoadFromActor()
	local animInstance = self:GetAnimInstance();
	if(not animInstance) then
		return;
	end
	animInstance:RemoveAllDynamicFields();
	self.variables:clear();
	self.variable_names = nil;

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
		return BonesVariable._super.getValue(self, anim, time);
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
