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
	self.block_template = nil;
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