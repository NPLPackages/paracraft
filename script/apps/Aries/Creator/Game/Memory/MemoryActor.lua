--[[
Title: Memory Actor
Author(s): LiXizhi
Date: 2017/6/2
Desc: Actor is the base class for a tightly related group of time-series-based concept(entity) in memory.
A memory clip may contain one or more memory actors. Actor is like an abstract concept in the brain that never separates.

When an actor is activated, it will play-back the time-series into the virtual world inside the brain by incarnation. 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/MemoryActor.lua");
local MemoryActor = commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryActor");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TimeSeries.lua");
local TimeSeries = commonlib.gettable("MyCompany.Aries.Game.Common.TimeSeries");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Actor = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryActor"));
Actor:Property("Name", "MemoryActor");
-- the itemstack(TimeSeries) is changed
Actor:Signal("dataSourceChanged");
-- frame move interval in milliseconds
Actor:Property({"frameMoveInterval", 30, "GetFrameMoveInterval", "SetFrameMoveInterval", auto=true});
Actor:Property({"time", 0, "GetTime", "SetTime", auto=true});
Actor:Property({"lastTime", nil, "GetLastTime",});
Actor:Property({"active", false, "IsActive", "SetActive"});
Actor:Property({"offset_facing", 0, "GetOffsetFacing", "SetOffsetFacing", auto=true});

function Actor:ctor()
	self.TimeSeries = TimeSeries:new{name = "Actor",};
end

-- @param itemStack: movie block actor's item stack where time series data source of this entity is stored. 
-- @param entity: the world entity that this actor is controlling, such as EntityPlayer, EntityNPC, EntityModel, etc. 
function Actor:Init(itemStack, entity)
	self:SetEntity(entity);
	self:SetItemStack(itemStack);
	return self;
end

-- get the last time of all time series of this actor. 
-- this is calculated on demand on first call and cached the result. 
function Actor:GetLastTime()
	if(not self.lastTime) then
		self.lastTime = self:GetTimeSeries():GetLastTime()
	end
	return self.lastTime;
end

function Actor:SetItemStack(itemStack)
	self.lastTime = nil;
	self.itemStack = itemStack;
	self:BindItemStackToTimeSeries();
end

function Actor:GetItemStack()
	return self.itemStack;
end

function Actor:GetTimeSeries()
	return self.TimeSeries;
end

function Actor:BindItemStackToTimeSeries()
	-- needs to clear all multi variable, otherwise undo function will not work properly. 
	self.custom_vars = {};
	local timeseries = self.itemStack:GetDataField("timeseries");
	if(not timeseries) then
		timeseries = {};
		self.itemStack:SetDataField("timeseries", timeseries);
	end
	self.TimeSeries:LoadFromTable(timeseries);
	self:dataSourceChanged();
	self:SetModified();
end

function Actor:SetModified()
	-- self:valueChanged();
	-- self:keyChanged();
end

-- the world entity that this actor is controlling
function Actor:GetEntity()
	return self.entity;
end

-- the world entity that this actor is controlling
function Actor:SetEntity(entity)
	self.entity = entity;
end

-- @return the entity position if any
function Actor:GetPosition()
	if(self.entity) then
		return self.entity:GetPosition();
	end
end

function Actor:GetVariable(keyname)
	return self.TimeSeries:GetVariable(keyname);
end

-- @param keypath: keyname or key local path. such as "x", "bones::root" 
function Actor:GetChildVariableByPath(keypath)
	if(keypath) then
		local subkey;
		keypath, subkey = keypath:match("^([^:]+):*(.*)"); 
		local var = self.TimeSeries:GetChild(keypath);
		if(var) then
			if(subkey and subkey~="" and var.GetChild) then
				return var:GetChild(subkey);
			end
		end
	end
	return;
end

-- @param bStartFromFirstKeyFrame: whether we will only value after the time of first key frame. default to false.
function Actor:GetValue(keyname, time, bStartFromFirstKeyFrame)
	local v = self:GetVariable(keyname);
	if(v and time) then
		if(not bStartFromFirstKeyFrame) then
			-- default to animId = 1
			return v:getValue(1, time);
		else
			local firstTime = v:GetFirstTime();
			if(firstTime and firstTime <= time) then
				return v:getValue(1, time);
			end
		end
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
	return facing and (facing + (self.offset_facing or 0));
end

-- return the animation instance. 
function Actor:GetAnimInstance()
	local entity = self:GetEntity();
	if(entity) then
		local obj = entity:GetInnerObject();
		if(obj) then
			local animInstance = obj:GetAttributeObject():GetChildAt(1,1);
			if(animInstance and animInstance:IsValid()) then
				return animInstance;
			end
		end
	end
end


function Actor:IsActive()
	return self.active;
end

function Actor:SetActive(bActive)
	self.active = bActive;
end

-- virtual function: 
function Actor:Activate()
	self:SetActive(true);
	self:SetTime(0);
end

-- virtual function: 
function Actor:Deactivate()
	self:SetActive(false);
end

-- start calling FrameMove() function
function Actor:BeginFrameMove()
	self.mytimer = self.mytimer or commonlib.Timer:new({callbackFunc = function(timer)
		self:FrameMove(timer:GetDelta());
	end})
	self.mytimer:Change(10, self:GetFrameMoveInterval());
end

-- end calling FrameMove() function, usually called when actor is deactivated. 
function Actor:EndFrameMove()
	if(self.mytimer) then
		self.mytimer:Change();
	end
end

-- virtual function: called every framemove. 
-- @param deltaTime: in millisecond ticks
function Actor:FrameMove(deltaTime)
end
