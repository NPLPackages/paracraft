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
				local block = block_types.get(result.block_id);
				if(not block) then
					-- remove blocks for non-exist blocks
					LOG.std(nil, "warn", "MousePick", "non-exist block detected with id %d", result.block_id);
					BlockEngine:SetBlock(result.blockX,result.blockY,result.blockZ, 0);
				elseif(block.material:isLiquid() and block_types.names.LilyPad ~= GameLogic.GetBlockInRightHand()) then
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
				end
			end
			local root_ = ParaUI.GetUIObject("root");
			local mouse_pos = root_:GetAttributeObject():GetField("MousePosition", {0,0});
		end
	end

	-- pick any point (like terrain and phyical mesh)
	if(bPickPoint~=false) then
		local pt = ParaScene.MousePick(picking_dist, "point");
		if(pt:IsValid())then
		
			local x, y, z = pt:GetPosition();
			local blockX, blockY, blockZ = BlockEngine:block(x,y+0.1,z); -- tricky we will slightly add 0.1 to y value. 
		
			local length = math.sqrt((eye_pos[1] - x)^2 + (eye_pos[2] - y)^2 + (eye_pos[3] - z)^2);
		
			if(not result.length or (result.length>=picking_dist) or (result.length > length)) then
				result.length = length;
				result.x, result.y, result.z = x, y, z;
				result.blockX, result.blockY, result.blockZ = blockX, blockY-1, blockZ;
				result.side = 5;
				result.block_id = nil;
				local entityName = pt:GetName();
				if(entityName) then
					local bx, by, bz = entityName:match("^(%d+),(%d+),(%d+)$");
					if(bx and by and bz) then
						bx = tonumber(bx);
						by = tonumber(by);
						bz = tonumber(bz);
						local entity = BlockEngine:GetBlockEntity(bx, by, bz);
						if(entity) then
							result.entity = entity;
							result.block_id = result.block_id or entity:GetBlockId();
							result.blockY = blockY; -- restore blockY-1 in case terrain point is picked. 
						end
					end
				end
			end
		end
	end

	-- pick any scene object
	if(bPickObjects~=false) then
		local obj_filter;
		local obj = ParaScene.MousePick(result.length or picking_dist, "anyobject"); 
		if(not obj:GetField("visible", false) or obj.name == "_bm_") then
			-- ignore block custom model or invisible ones
			obj = nil;
		else
			result.obj = obj;
			local x, y, z = obj:GetPosition();
			local length = math.sqrt((eye_pos[1] - x)^2 + (eye_pos[2] - y)^2 + (eye_pos[3] - z)^2);
			--if(not result.length or result.length > length) then
				result.length = length;
				result.x, result.y, result.z = x, y, z;
				local blockX, blockY, blockZ = BlockEngine:block(x,y+0.1,z); -- tricky we will slightly add 0.1 to y value. 
				result.blockX, result.blockY, result.blockZ = blockX, blockY-1, blockZ;
				result.side = 5;
				result.block_id = nil;
			--end
			result.entity = EntityManager.GetEntityByObjectID(obj:GetID());
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

SelectionManager:InitSingleton();


