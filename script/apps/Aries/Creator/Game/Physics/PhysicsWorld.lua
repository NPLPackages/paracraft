--[[
Title: Physic Engine in block world
Author(s): LiXizhi
Date: 2013/1/23
Desc: It manages dynamic object in pure block world. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Physics/PhysicsWorld.lua");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
PhysicsWorld.FrameMove();
PhysicsWorld.AddDynamicObject(obj)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Physics/DynamicObject.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
NPL.load("(gl)script/ide/math/AABBPool.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/QuadTree.lua");
local QuadTree = commonlib.gettable("MyCompany.Aries.Game.Common.QuadTree")
local AABBPool = commonlib.gettable("mathlib.AABBPool");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local FolderManager = commonlib.gettable("MyCompany.Aries.Game.GameLogic.FolderManager")

local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");

-- all active dynamic world object
local active_dynamic_obj = commonlib.List:new();
-- bounding boxes
PhysicsWorld.collidingBoundingBoxes = commonlib.vector:new();
-- quadtree for all static triggers
PhysicsWorld.triggerQuadTree = nil;

function PhysicsWorld:StaticInit()
end

-- before world is loaded
function PhysicsWorld:Init()
	PhysicsWorld.triggerQuadTree = QuadTree:new():Init({minWidth = 32, minHeight = 32, left = 0, top = 0, right = 64*512, bottom = 64*512, splitThreshold = 20});
end

function PhysicsWorld.Clear()
	active_dynamic_obj:clear();
end

function PhysicsWorld:AddStaticTrigger(triggerObject)
	local left, top, right, bottom = triggerObject:GetQuadSize();
	local fromHeight, toHeight = triggerObject:GetHeightMinMax();
	PhysicsWorld.triggerQuadTree:AddObject(triggerObject, left, top, right, bottom, fromHeight, toHeight);
end

function PhysicsWorld:RemoveStaticTrigger(triggerObject)
	PhysicsWorld.triggerQuadTree:RemoveObject(triggerObject)
end

-- whether the given block is blocked. 
-- TODO: cache the query result for a single framemove. this function may be called many times in a single frame. 
function PhysicsWorld.IsBlocked(bx, by, bz)
	local block_template = BlockEngine:GetBlock(bx, by, bz);	
	if(block_template and block_template.obstruction) then
		return true;
	end
end

-- called every frame to simulate objects 
function PhysicsWorld.FrameMove(deltaTime)
	deltaTime = deltaTime/1000;

	AABBPool.GetSingleton():CleanPool();

	local obj_cont = active_dynamic_obj:first();
	while (obj_cont) do
		local obj = obj_cont.obj;
		if(not obj.is_destroyed) then
			obj:FrameMove(deltaTime);
			if(obj.is_stopped and not obj.is_persistent) then
				obj_cont = active_dynamic_obj:remove(obj_cont);
			else
				obj_cont = active_dynamic_obj:next(obj_cont)
			end
		else
			obj_cont = active_dynamic_obj:remove(obj_cont);
		end
	end
	PhysicsWorld.UpdateTriggers()
end

function PhysicsWorld.AddDynamicObject(obj)
	active_dynamic_obj:push_back({obj=obj})
end


-- static function: default filterEntityFunc
local function CanBeCollidedWith_(destEntity, entity)
	return destEntity:CanBeCollidedWith(entity);
end


-- Returns a list of bounding boxes that collide with aabb including the passed in entity's collision. 
-- @param aabb: 
-- @param entity: 
-- @param filterEntityFunc: nil or a function(destEntity, entity) end, this function should return true for destEntity's collision to be considered.
-- @param max_entity_collision_count: max number of entity collisions to return. too many collisions will lead to HIGH CPU and AABB pool overflow.
-- Entity.CanBeCollidedWith and Entity.IsVisible are good choices for this function. If nil, it will return all. 
-- Please note block collisions are always returned regardless of this. 
-- return array list of bounding box (all bounding box is read-only), modifications will lead to unexpected result. 
function PhysicsWorld:GetCollidingBoundingBoxes(aabb, entity, filterEntityFunc, max_entity_collision_count)
    self.collidingBoundingBoxes:clear();
	
    local blockMinX,  blockMinY, blockMinZ = BlockEngine:block(aabb:GetMinValues());
	local blockMaxX,  blockMaxY, blockMaxZ = BlockEngine:block(aabb:GetMaxValues());
    

    for bx = blockMinX, blockMaxX do
        for bz = blockMinZ, blockMaxZ do
            for by = blockMinY - 1, blockMaxY do
                local block_template = BlockEngine:GetBlock(bx, by, bz);
                if (block_template) then
                    block_template:AddCollisionBoxesToList(bx, by, bz, aabb, self.collidingBoundingBoxes, entity);
                end
            end
		end
	end

    local distExpand = 0.25;
    local listEntities = EntityManager.GetEntitiesByAABBExcept(aabb:clone():Expand(distExpand, distExpand, distExpand), entity);

	local count = 0;

	if(listEntities) then
		filterEntityFunc = filterEntityFunc or CanBeCollidedWith_;
		for _, entityCollided in ipairs(listEntities) do
			if(filterEntityFunc(entityCollided, entity)) then
				local collisionAABB = entityCollided:GetCollisionAABB();
				if(collisionAABB and collisionAABB:Intersect(aabb)) then
					
					self.collidingBoundingBoxes:add(collisionAABB);
					count = count + 1;
					if(max_entity_collision_count and count>=max_entity_collision_count) then
						break;
					end
				end
				collisionAABB = entity:CheckGetCollisionBox(entityCollided);
				if(collisionAABB and collisionAABB:Intersect(aabb)) then
					self.collidingBoundingBoxes:add(collisionAABB);
					count = count + 1;
					if(max_entity_collision_count and count>=max_entity_collision_count) then
						break;
					end
				end
			end
		end
	end
    return self.collidingBoundingBoxes;
end

function PhysicsWorld.UpdateTriggers()
	local triggerQuadTree = PhysicsWorld.triggerQuadTree
	local count = triggerQuadTree:GetObjectCount()
	if(count == 0) then
		return
	end

	local player = EntityManager.GetPlayer();
	if(player) then
		local x, y, z = player:GetBlockPos()
		local triggers = triggerQuadTree:GetObjectsBy3DPoint(x, y, z)
		player:SetInsideTriggers(triggers);
	end
end
