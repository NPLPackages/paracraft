--[[
Title: Bone variable
Author(s): LiXizhi
Date: 2015/9/8
Desc: a single bone variable, it is a multi variable containing rotation, translation and scaling attribute variable. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/BoneVariable.lua");
local BoneVariable = commonlib.gettable("MyCompany.Aries.Game.Movie.BoneVariable");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/MultiAnimBlock.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/BoneAttributeVariable.lua");
NPL.load("(gl)script/ide/math/Quaternion.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local Quaternion = commonlib.gettable("mathlib.Quaternion");
local Matrix4 = commonlib.gettable("mathlib.Matrix4");
local BoneAttributeVariable = commonlib.gettable("MyCompany.Aries.Game.Movie.BoneAttributeVariable");
local ATTRIBUTE_FIELDTYPE = commonlib.gettable("System.Core.ATTRIBUTE_FIELDTYPE");

local BoneVariable = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Common.MultiAnimBlock"), commonlib.gettable("MyCompany.Aries.Game.Movie.BoneVariable"));
BoneVariable.name = "";

function BoneVariable:ctor()
end

-- @param attr: parax bone attribute model
-- @param animInstance: the animation instance 
-- @param parent: get the parent BonesVariable.
function BoneVariable:init(attr, animInstance, parent)
	self.parent = parent;
	self.name = attr:GetField("name", "");
	self.rot_name = attr:GetField("RotName", "");
	self.trans_name = attr:GetField("TransName", "");
	self.scale_name = attr:GetField("ScaleName", "");

	self.variables:add(BoneAttributeVariable:new():init(self.rot_name, "rot", attr, animInstance, parent));
	self.variables:add(BoneAttributeVariable:new():init(self.trans_name, "trans", attr, animInstance, parent));
	self.variables:add(BoneAttributeVariable:new():init(self.scale_name, "scale", attr, animInstance, parent));

	self.attr = attr;
	self.animInstance = animInstance;
	return self;
end

-- get current bone pivot. 
-- please note this could return NAN
function BoneVariable:GetPivot(bRefresh)
	self.pivot = self.pivot or vector3d:new({0,0,0})
	if(bRefresh) then
		self.pivot = self.attr:GetField("AnimatedPivotPoint", self.pivot);
	end
	return self.pivot;
end

-- force local time of bone variable
-- @param time: if nil or -1, the bone will use character animation instance's time
-- if -1000, it will temporarily disable external bone animation. 
-- otherwise it will force using the given time from the time series, such allowing 
-- users to control each bone's play time in time series. 
function BoneVariable:SetTime(time)
	self.time_name = self.time_name or self.attr:GetField("TimeName", "");
	self.animInstance:SetDynamicField(self.time_name, time or -1);
end

-- get current rotation
-- @return the rotation quaternion
function BoneVariable:GetRotation(bRefresh)
	self.rot = self.rot or Quaternion:new()
	if(bRefresh) then
		self.rot = self.attr:GetField("FinalRot", self.rot);
	end
	return self.rot;
end

-- please note this could return NAN
function BoneVariable:GetPivotRotation(bRefresh)
	self.pivot_rot = self.pivot_rot or Matrix4:new()
	if(bRefresh) then
		self.pivot_rot = self.attr:GetField("PivotRotMatrix", self.pivot_rot);
	end
	return self.pivot_rot;
end

-- save from C++'s current anim instance to actor's timeseries
function BoneVariable:SaveToTimeVar()
	for i=1, #(self.variables) do
		self.variables[i]:SaveToTimeVar();
	end
end

-- Load from actor's timeseries to C++'s current anim instance. 
function BoneVariable:LoadFromTimeVar()
	for i=1, #(self.variables) do
		self.variables[i]:LoadFromTimeVar();
	end
end

function BoneVariable:GetRotName()
	return self.rot_name;
end

function BoneVariable:GetScaleName()
	return self.scale_name;
end

function BoneVariable:GetTransName()
	return self.trans_name;
end

function BoneVariable:getValue(anim, time)
	local v = BoneVariable._super.getValue(self, anim, time);
	if(v and not next(v)) then
		v = nil;
	end
	return v;
end

function BoneVariable:GetVarByName(name)
	if(self:GetRotName() == name) then
		return self.variables[1]
	elseif(self:GetTransName() == name) then
		return self.variables[2]
	elseif(self:GetScaleName() == name) then
		return self.variables[3]
	end
end