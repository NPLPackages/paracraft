--[[
Title: Entity Pool
Author(s): LiXizhi
Date: 2014/9/8
Desc: useful when creating lots of pool entities like rain, snow particle, etc. 
Pooled entities are automatically recollected back to the pool when they are destoryed
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPool.lua");
local EntityPool = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPool");
local entity_pool = EntityPool:new():init(entity_class, maxPoolSize);
-- create from pool. 
local entity = entity_pool:CreateEntity();
if(entity) then
end

-- singleton class
local pool_manager = EntityPool:CreateGet(EntityManager.EntityWeatherEffect);

-- example usage: see EntityWeatherEffect 
function Entity:CreateFromPool()
	local pool_manager = EntityPool:CreateGet(self, max_pool_size);
	return pool_manager:CreateEntity();
end
-------------------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local EntityPool = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPool");
EntityPool.__index = EntityPool;
 
EntityPool.maxPoolSize = 2000;

function EntityPool:new()
	local o = {};
	-- List of entity stored in this Pool
	o.listEntities = commonlib.UnorderedArray:new();
	-- Next index to use when adding a Pool Entry.
	o.nextPoolIndex = 1;
	-- Largest index reached by this Pool since last CleanPool operation. 
	o.maxPoolIndex = 0;
	-- total number of pooled object created. 
	o.totalCount = 0;

	setmetatable(o, self);
	return o;
end

local entity_pools = {};
-- static function:
function EntityPool:CreateGet(entity_class, maxPoolSize)
	local pool_manager = entity_pools[entity_class];
	if(not pool_manager) then
		pool_manager = EntityPool:new():init(entity_class, maxPoolSize);
		entity_pools[entity_class] = pool_manager;
	end
	return pool_manager;
end

-- static function: should be called from 
function EntityPool:ClearAllPools()
	for _, pool_manager in pairs(entity_pools) do
		pool_manager:Clear();
	end
end

function EntityPool:init(entity_class, maxPoolSize)
	self.entity_class = entity_class;
	self.maxPoolSize = maxPoolSize;
	return self;
end

-- Creates a new entity, or reuses one that's no longer in use. 
-- @return may return nil, if max pool pooled entity is reached. 
function EntityPool:CreateEntity()
    local entity;
	if(self.listEntities:empty()) then
		entity = self.entity_class:new();
		entity.pool_manager = self;
		self.totalCount = self.totalCount + 1;
    else
        entity = self.listEntities:pop_back();
    end
    return entity;
end

-- this function should and can only be called after the entity is detached or destroyed. 
function EntityPool:RecollectEntity(entity)
	if(entity.pool_manager == self) then
		if(self.listEntities:size() < self.maxPoolSize) then
			entity:Reset();
			self.listEntities:push_back(entity);
			return true;
		else
			LOG.std(nil, "warn", "RecollectEntity", "entity %s exceeded pool size %d.", entity.name or "", self.maxPoolSize);
			self:RemoveEntity(entity);
		end
	else
		LOG.std(nil, "warn", "RecollectEntity", "collecting from unknown pool");
	end
end

function EntityPool:GetReusableCount()
    return self.listEntities:size();
end

function EntityPool:GetTotalCount()
    return self.totalCount;
end

-- can only be called when entity  is not in the reuse pool. 
function EntityPool:RemoveEntity(entity)
	if(entity.pool_manager == self) then
		entity.pool_manager = nil;
		self.totalCount = self.totalCount - 1;
	end
end

-- clear the pool
function EntityPool:Clear()
	for i=1, #(self.listEntities) do
		local entity = self.listEntities[i];
		entity.pool_manager = nil;
	end
	self.listEntities:clear();
	self.totalCount = 0;
end

