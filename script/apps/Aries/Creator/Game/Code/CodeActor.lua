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
NPL.load("(gl)script/ide/math/vector.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Actor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Movie.ActorNPC"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeActor"));
Actor:Property("Name", "CodeActor");
-- the itemstack(TimeSeries) is changed
Actor:Signal("dataSourceChanged");
-- frame move interval in milliseconds
Actor:Property({"frameMoveInterval", 30, "GetFrameMoveInterval", "SetFrameMoveInterval", auto=true});
Actor:Property({"time", 0, "GetTime", "SetTime", auto=true});

function Actor:ctor()
	self.offsetPos = vector3d:new(0,0,0);
	self.offsetYaw = 0;
end

-- @param itemStack: movie block actor's item stack where time series data source of this entity is stored. 
function Actor:Init(itemStack, movieclipEntity)
	if(not Actor._super.Init(self, itemStack, movieclipEntity)) then
		return;
	end
	return self;
end

function Actor:SetVisible(bVisible)
	-- TODO: 	
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
	self:SetOffsetPos(eX - new_x, eY - new_y, eZ - new_z);
	self:SetOffsetYaw(obj:GetField("yaw", 0) - (yaw or 0));
end

function Actor:SetOffsetYaw(yaw)
	self.offsetYaw = yaw;
end

function Actor:GetOffsetYaw()
	return self.offsetYaw;
end

function Actor:SetOffsetPos(dx,dy,dz)
	self.offsetPos:set(dx,dy,dz);
end

function Actor:GetOffsetPos()
	return self.offsetPos:get();
end

function Actor:ComputePosAndRotation(curTime)
	local new_x, new_y, new_z, yaw, roll, pitch = Actor._super.ComputePosAndRotation(self, curTime);
	
	if(new_x) then
		local dx, dy, dz = self:GetOffsetPos();
		return new_x+dx, new_y+dy, new_z+dz, (yaw or 0)+self:GetOffsetYaw(), roll, pitch;
	end
end