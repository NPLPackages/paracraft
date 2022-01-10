--[[
Title: selection manager
Author(s): LiXizhi
Date: 2015/8/3
Desc: selection manager (singleton class)
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/SelectionManager.lua");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local result = SelectionManager:GetPickingResult()
SelectionManager:IsMousePickingEntity(entity)
------------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local Matrix4 = commonlib.gettable("mathlib.Matrix4");

local SelectionManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.SelectionManager"));
SelectionManager:Property("Name", "SelectionManager");
SelectionManager:Property({"m_picking_dist", 50,})

SelectionManager:Signal("selectedActorChanged");
-- when user changed the current selected variable, please note the actor may not be selected actor.
SelectionManager:Signal("selectedActorVariableChanged", function(name, actor) end);
-- variable name is changed
SelectionManager:Signal("varNameChanged", function(name) end);

local default_picking_dist = 50;
local result = nil;
local eye_pos = {0,0,0};

function SelectionManager:ctor()
	NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/PickingResult.lua");
	local PickingResult = commonlib.gettable("MyCompany.Aries.Game.SceneContext.PickingResult");
	result = PickingResult:new();
	self.result = result;
end

-- get the current mouse picking result. 
function SelectionManager:GetPickingResult()
	return self.result;
end

function SelectionManager:SetPickingDist(dist)
	GameLogic.options:SetPickingDist(dist or default_picking_dist)
end

function SelectionManager:GetPickingDist()
	return GameLogic.options:GetPickingDist();
end

function SelectionManager:Clear()
	self:ClearPickingResult();
	self:SetSelectedActor(nil);
end

function SelectionManager:ClearPickingResult()
	result:Clear();
end

-- @param callbackFunc: callback function
-- @param callbackFuncSelf: one can also provide a class instance if callbackFunc is a member function of callbackFuncSelf
function SelectionManager:SetEntityFilterFunction(callbackFunc, callbackFuncSelf)
	self.entityFilterFuncSelf = callbackFuncSelf;
	self.entityFilterFunc = callbackFunc;
end

-- @return true if entity can be picked
function SelectionManager:FilterEntity(entity)
	if(entity and self.entityFilterFunc) then
		if(self.entityFilterFuncSelf) then
			return self.entityFilterFunc(self.entityFilterFuncSelf, entity)
		else
			return self.entityFilterFunc(entity)
		end
	else
		return true;
	end
end

-- return true if mouse is picking the given entity. Please note this will disregard SkipPicking attribute on the entity. 
-- @param entity: if nil,  we will use main player
function SelectionManager:IsMousePickingEntity(entity)
	entity = entity or EntityManager.GetPlayer();
	local bIsLastSkipPicking = entity:IsSkipPicking()
	if(bIsLastSkipPicking) then
		entity:SetSkipPicking(false)
	end
	local result = self:MousePickBlock()
	if(bIsLastSkipPicking) then
		entity:SetSkipPicking(true)
	end
	if(result.entity == entity) then
		return true;
	end
end

-- @param bPickBlocks, bPickPoint, bPickObjects: default to true
-- return result;
function SelectionManager:MousePickBlock(bPickBlocks, bPickPoint, bPickObjects, picking_dist)
	self:ClearPickingResult();
	
	local filter;
	eye_pos = ParaCamera.GetAttributeObject():GetField("Eye position", eye_pos);
	
	picking_dist = picking_dist or self:GetPickingDist();
	
	-- pick blocks
	if(bPickBlocks~=false) then
		result = ParaTerrain.MousePick(picking_dist, result, 0xffffffff);
		if(result.blockX) then
			result.block_id = ParaTerrain.GetBlockTemplateByIdx(result.blockX,result.blockY,result.blockZ);
			if(result.block_id > 0) then
				result.blockRealX, result.blockRealY, result.blockRealZ = result.x, result.y, result.z;
				result.blockLength = result.length;
				local block = block_types.get(result.block_id);
				if(not block) then
					-- remove blocks for non-exist blocks
					LOG.std(nil, "warn", "MousePick", "non-exist block detected with id %d", result.block_id);
					BlockEngine:SetBlock(result.blockX,result.blockY,result.blockZ, 0);
				elseif(block.material:isLiquid() and block_types.names.LilyPad ~= GameLogic.GetBlockInRightHand() and not GameLogic.options:GetWorldOption("selectWater")) then
					-- if we are picking a liquid object, we discard it and pick again for solid or obstruction or customModel object. 
					result = ParaTerrain.MousePick(picking_dist, result, 0x85);
					if(result.blockX) then
						result.block_id = ParaTerrain.GetBlockTemplateByIdx(result.blockX,result.blockY,result.blockZ);
					end
				elseif(block.invisible and not block.solid) then
					-- we will skip picking for invisible non solid block. instead we will only pick solid or customModel object.
					result = ParaTerrain.MousePick(picking_dist, result, 0x84);
					if(result.blockX) then
						result.block_id = ParaTerrain.GetBlockTemplateByIdx(result.blockX,result.blockY,result.blockZ);
					end
				elseif(block.nopicking) then
					local curBlockId = EntityManager.GetPlayer():GetBlockInRightHand()
					if(curBlockId ~= result.block_id) then
						result.block_id = nil;
						result.blockX, result.blockY, result.blockZ = nil, nil, nil
					end
				end
			end
			local root_ = ParaUI.GetUIObject("root");
			local mouse_pos = root_:GetAttributeObject():GetField("MousePosition", {0,0});
		else
			-- ParaTerrain.MousePick will modify the length and side for unknown reasons, since we will use these two parameters, we will reset them if no picking result is found. 
			result.length = nil;
			result.side = nil;
		end
	end

	-- pick any physical point (like terrain and phyical mesh)
	if(bPickPoint~=false) then
		local pt = ParaScene.MousePick(picking_dist, "point");
		if(pt:IsValid())then
			local x, y, z = pt:GetPosition();
			local blockX, blockY, blockZ = BlockEngine:block(x,y+0.1,z); -- tricky we will slightly add 0.1 to y value. 
			blockY = blockY - 1;
			local block_id = nil;
			local length = math.sqrt((eye_pos[1] - x)^2 + (eye_pos[2] - y)^2 + (eye_pos[3] - z)^2);
			local entity
			if(not result.length or (result.length>=picking_dist) or (result.length > length)) then
				local entityName = pt:GetName();
				if(entityName) then
					local bx, by, bz = entityName:match("^(%d+),(%d+),(%d+)$");
					if(bx and by and bz) then
						bx = tonumber(bx);
						by = tonumber(by);
						bz = tonumber(bz);
						local entityBlock = BlockEngine:GetBlockEntity(bx, by, bz);
						if(entityBlock) then
							entity = entityBlock;
							block_id = entity:GetBlockId();
							blockY = blockY + 1; -- restore blockY-1 in case terrain point is picked. 
						end
					end
					if(entityName~="") then
						local entity1 = EntityManager.GetEntity(entityName);
						if(entity1) then
							if(true) then
								entity = entity1;
							else
								-- no long verify distance since we may be dealing with big physical meshes
								local x1, y1, z1 = entity1:GetPosition()
								local lengthSq = ((x1 - x)^2 + (y1 - y)^2 + (z1 - z)^2);
								-- tricky: if the entity and hit points are close to each other, it is likely that they are the same object. 
								if(lengthSq < (10^2)) then
									entity = entity1
									blockY = blockY + 1; -- restore blockY-1 in case terrain point is picked. 
								end
							end
						end
					end
				end
				if(not entity or self:FilterEntity(entity)) then
					result.entity = entity;
					result.length = length;
					result.x, result.y, result.z = x, y, z;
					result.physicalX, result.physicalY, result.physicalZ = result.x, result.y, result.z;
					result.blockX, result.blockY, result.blockZ = blockX, blockY, blockZ;
					result.side = 5;
					result.block_id = block_id;
				end
			end
		end
	end

	-- pick any scene object with AABB bounding box
	if(bPickObjects~=false) then
		local lastEntity = result.entity;
		local lastLength = result.length;
		-- pick recursively and ignore physical objects along the eye ray
		-- @return entity that is picked. It will also fill result.obj with its object. 
		local function PickEntity_()
			local obj = ParaScene.MousePick(lastLength or picking_dist, "anyobject"); 
			if(not obj:GetField("visible", false) or obj.name == "_bm_") then
				-- ignore block custom model or invisible ones
			else
				local entity = EntityManager.GetEntityByObjectID(obj:GetID());
				result.obj = obj;
				local finalEntity;
				if(entity) then
					local canPickEntity = true;
					if(entity and not self:FilterEntity(entity)) then
						canPickEntity = false;
					elseif(entity and entity:HasRealPhysics()) then
						if(entity.IsAlwaysLoadPhysics and entity:IsAlwaysLoadPhysics()) then
							if(entity.CheckLoadPhysics and entity:CheckLoadPhysics()) then
								-- we will rely on the physics engine for picking instead of AABB bounding box picking. 
								canPickEntity = false;
							end
						end
					end
					if(not canPickEntity and entity) then
						result.obj = nil;
						-- we will skip the physical entity, and try pick entities behind it. 
						local lastSkipPicking = entity:IsSkipPicking();
						if(not lastSkipPicking) then
							entity:SetSkipPicking(true)
							finalEntity = PickEntity_()
							entity:SetSkipPicking(false)
						end
					end
				end
				if(result.obj) then
					return finalEntity or entity;
				end
			end
		end
		local entity = PickEntity_()
		if(lastEntity ~= entity and entity and result.obj) then
			local x, y, z = result.obj:GetPosition();
			local length = math.sqrt((eye_pos[1] - x)^2 + (eye_pos[2] - y)^2 + (eye_pos[3] - z)^2);
			--if(not result.length or result.length > length) then
				result.length = length;
				result.x, result.y, result.z = x, y, z;
				local blockX, blockY, blockZ = BlockEngine:block(x,y+0.1,z); -- tricky we will slightly add 0.1 to y value. 
				result.blockX, result.blockY, result.blockZ = blockX, blockY-1, blockZ;
				result.side = 5;
				result.block_id = nil;
			--end
			result.entity = entity;
		end
	end
	return result;
end

-- @return nil of a table of selected blocks.
function SelectionManager:GetSelectedBlocks()
	-- TODO replace SelectBlocks's implementation with local implementation. 
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
	local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
	local select_task = SelectBlocks.GetCurrentInstance();
	if(select_task) then
		local cur_selection = select_task:GetSelectedBlocks();
		return cur_selection;
	end
end

-- get selected movie actor
function SelectionManager:GetSelectedActor()
	return self.actor;	
end

-- get the previously selected actor. 
function SelectionManager:GetLastSelectedActor()
	return self.lastSelectedActor;
end

function SelectionManager:SetSelectedActor(actor)
	if(self.actor~=actor) then
		if(self.actor) then
			self.lastSelectedActor = self.actor;
		end
		self.actor = actor;
		self:selectedActorChanged(actor);
	end
end

-- get the intersection point between the mouse ray and a world space aabb. 
-- @param aabb: world space aabb. usually from Entity:GetInnerObjectAABB()
-- @return x, y, z: nil or a hit point
function SelectionManager:GetMouseInteractionPointWithAABB(aabb)
	local Cameras = commonlib.gettable("System.Scene.Cameras");
	local mouseRay = Cameras:GetCurrent():GetMouseRay(nil, nil, Matrix4.IDENTITY);
	
	aabb = aabb:clone_from_pool();
	local origin = ParaCamera.GetAttributeObject():GetField("RenderOrigin", {0,0,0});
	aabb:Offset(-origin[1], -origin[2], -origin[3])
	

	local hit, dist, hitpoint = mouseRay:intersectsAABB(aabb)
	if(hit) then
		local x, y, z = mouseRay:GetOriginValues()
		local dx, dy, dz = mouseRay:GetDirValues()
		return origin[1]+x+dx*dist, origin[2]+y+dy*dist, origin[3]+z+dz*dist
	end
end

SelectionManager:InitSingleton();


