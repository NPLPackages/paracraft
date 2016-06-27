--[[
Title: entity block container
Author(s): LiXizhi
Date: 2013/12/14
Desc: EntityManager dynamically create BlockContainer per block to hold entities that is inside a given block. 
Once there is no entities inside the block container, the block container automatically delete itself to save memory. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/BlockContainer.lua");
local BlockContainer = commonlib.gettable("MyCompany.Aries.Game.EntityManager.BlockContainer");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ChunkLocation.lua");
local ChunkLocation = commonlib.gettable("MyCompany.Aries.Game.Common.ChunkLocation");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local BlockContainer = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.EntityManager.BlockContainer"));

BlockContainer.auto_delete = true;
BlockContainer.entities = {};

-- @param x,y,z: initial real world position. 
-- @param radius: the half radius of the object. 
function BlockContainer:ctor()
	self.entities = {};
end

function BlockContainer:GetEntities()
	return self.entities;
end

function BlockContainer:Add(entity)
	self.entities[entity] = true;
	local chunkX, chunkZ = ChunkLocation:GetChunkPosFromWorldPos(self.x, self.z);
	local entities = EntityManager.GetEntitiesInChunkColumn(chunkX, chunkZ, true);
	entities:add(entity);
end

function BlockContainer:Remove(entity)
	self.entities[entity] = nil;
	local chunkX, chunkZ = ChunkLocation:GetChunkPosFromWorldPos(self.x, self.z);
	local entities = EntityManager.GetEntitiesInChunkColumn(chunkX, chunkZ, true);
	entities:removeByValue(entity); 
	if(not next(self.entities) and self.auto_delete) then
		EntityManager.SetBlockContainer(self.x,self.y,self.z, nil);
	end
end
