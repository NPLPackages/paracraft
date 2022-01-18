--[[
Title: Picking Result
Author(s): LiXizhi
Date: 2016/3/14
Desc: this is the object returned by the SelectionManager
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/PickingResult.lua");
local PickingResult = commonlib.gettable("MyCompany.Aries.Game.SceneContext.PickingResult");
local result = PickingResult:new();
------------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local PickingResult = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.SceneContext.PickingResult"));

function PickingResult:ctor()
end

function PickingResult:Clear()
	self.length = nil;
	self.obj = nil;
	self.entity = nil;
	self.block_id = nil;
	self.x, self.y, self.z = nil, nil, nil;
	self.blockX, self.blockY, self.blockZ = nil, nil, nil;
	self.blockRealX, self.blockRealY, self.blockRealZ = nil, nil, nil;
	self.physicalX, self.physicalY, self.physicalZ = nil, nil, nil;
	self.blockLength = nil;
	self.block_template = nil;
	self.side = nil
end

function PickingResult:CopyFrom(obj)
	self.length = obj.length;
	self.obj = obj.obj;
	self.entity = obj.entity;
	self.block_id = obj.block_id;
	self.x, self.y, self.z = obj.x, obj.y, obj.z;
	self.blockX, self.blockY, self.blockZ = obj.blockX, obj.blockY, obj.blockZ;
	self.blockRealX, self.blockRealY, self.blockRealZ = obj.blockRealX, obj.blockRealY, obj.blockRealZ;
	self.physicalX, self.physicalY, self.physicalZ = obj.physicalX, obj.physicalY, obj.physicalZ;
	self.blockLength = self.blockLength;
	self.block_template = self.block_template;
	self.side = self.side
end

function PickingResult:CloneMe()
	local obj = PickingResult:new();
	obj:CopyFrom(self);
	return obj;
end

-- get the block template or nil. 
function PickingResult:GetBlock()
	if(not self.block_template) then
		if(self.block_id and self.block_id~=0 and self.blockX) then
			self.block_template = block_types.get(self.block_id);
		end
	end
	return self.block_template;
end

-- get the entity object or nil. 
function PickingResult:GetEntity()
	return self.entity;
end

-- get the block distance to current player
function PickingResult:GetBlockDistanceToPlayer()
	local block_template = self:GetBlock();
	if(block_template) then
		local player = EntityManager.GetPlayer();
		return player and math.sqrt(player:DistanceSqTo(self.blockX, self.blockY, self.blockZ)) or 0;
	end
	return 0;
end

-- get the distance to view point
function PickingResult:GetDistance()
	return self.length;
end

-- return block position: self.blockX, self.blockY, self.blockZ;
function PickingResult:GetBlockPos()
	return self.blockX, self.blockY, self.blockZ;
end