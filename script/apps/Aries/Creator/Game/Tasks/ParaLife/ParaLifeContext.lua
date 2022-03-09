--[[
Title: Paralife Context
Author(s): LiXizhi
Date: 2022/1/12
Desc: use "/show paralife" command to activate this context during play mode. 
mouse event are disabled when moving accross endstone(id:155). 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeContext.lua");
local ParalifeContext = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParalifeContext")
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/BaseContext.lua");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local ParalifeContext = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.SceneContext.BaseContext"), commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParalifeContext"));

ParalifeContext:Property("Name", "ParalifeContext");
ParalifeContext:Property({"clickToMove", true, "IsClickToMoveEnabled", "EnableClickToMove", auto = true});
ParalifeContext:Property({"isHighLightEntity", false});
ParalifeContext:Property({"fingerRadius", 16});
ParalifeContext:Property({"borderMarkerBlockId", 155});
ParalifeContext:Property({"defaultCameraRotSpeed", 0.003});


-- if entity's radius is bigger than 0.3, we will not use finger picking
ParalifeContext:Property({"maxFingerPickingRadius", 0.3});


function ParalifeContext:ctor()
	self:EnableAutoCamera(true);
end

function ParalifeContext:IsClickToMoveEnabled()
	return self.clickToMove
end

function ParalifeContext:EnableClickToMove(enabled)
	self.clickToMove = enabled
end

-- virtual function: 
-- try to select this context. 
function ParalifeContext:OnSelect()
	self.itemLiveModel = ItemClient.GetItem(block_types.names.LiveModel)
	ParalifeContext._super.OnSelect(self);
	self:EnableMousePickTimer(true);
	GameLogic:Connect("gameEventFired", self, self.OnGameEvent, "UniqueConnection");
end

-- virtual function: 
-- return true if we are not in the middle of any operation and fire unselected signal. 
-- or false, if we can not unselect the scene tool context at the moment. 
function ParalifeContext:OnUnselect()
	ParalifeContext._super.OnUnselect(self);
	GameLogic:Disconnect("gameEventFired", self, self.OnGameEvent);

	local att = ParaCamera.GetAttributeObject();
	att:SetField("RotationScaler", 0.01);
	return true;
end

function ParalifeContext:OnLeftLongHoldBreakBlock()
	self:TryDestroyBlock(Game.SelectionManager:GetPickingResult());
end

-- For Numeric key 1-9
function ParalifeContext:HandleQuickSelectKey(event)
	if(not System.options.IsMobilePlatform) then
		-- For Numeric key 1-9
		local key_index = event.keyname:match("^DIK_(%d)");
		if(key_index) then
			key_index = tonumber(key_index);
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/QuickSelectBar.lua");
			local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
			QuickSelectBar.OnSelectByKeyIndex(key_index);
			event:accept();
			return true;
		end
	end
end

function ParalifeContext:UpdateMouseRotationSpeed()
	local att = ParaCamera.GetAttributeObject();
	att:SetField("RotationScaler", self.defaultCameraRotSpeed);
end

-- virtual: 
function ParalifeContext:mousePressEvent(event)
	if(not self:CanMoveToMouseCursor(event)) then
		return
	end
	ParalifeContext._super.mousePressEvent(self, event);
	if(event:isAccepted()) then
		return
	end
	local click_data = self:GetClickData();

	self:EnableMouseDownTimer(true);

	local result = self:CheckMousePick(event);
	self:UpdateClickStrength(0, result);
	self:UpdateMouseRotationSpeed();

	if(event.mouse_button == "left") then
		-- play touch step sound when left click on an object
		if(result and result.block_id and result.block_id > 0) then
			click_data.last_mouse_down_block.blockX, click_data.last_mouse_down_block.blockY, click_data.last_mouse_down_block.blockZ = result.blockX,result.blockY,result.blockZ;
			local block = block_types.get(result.block_id);
			if(block and result.blockX) then
				block:OnMouseDown(result.blockX,result.blockY,result.blockZ, event.mouse_button);
			end
		end
	end
end

-- virtual: 
function ParalifeContext:mouseMoveEvent(event)
	ParalifeContext._super.mouseMoveEvent(self, event);
	if(event:isAccepted()) then
		return
	end
	local result = self:CheckMousePick(event);
end

function ParalifeContext:handleLeftClickScene(event, result)
	local mode = GameLogic.GetMode();
	local click_data = self:GetClickData();
	if( click_data.left_holding_time < 150) then
		if(result and result.obj and (not result.block_id or result.block_id == 0)) then
			-- for scene object selection, blocks has higher selection priority.  
		else
			-- for blocks
			local is_shift_pressed = event.shift_pressed;
			local ctrl_pressed = event.ctrl_pressed;
			local alt_pressed = event.alt_pressed;

			local is_processed
			if(not is_shift_pressed and not alt_pressed and not ctrl_pressed and result and result.blockX) then
				-- if it is a left click, first try the game logics if it is processed. such as an action neuron block.
				if(result.entity and result.entity:IsBlockEntity() and result.entity:GetBlockId() == result.block_id) then
					-- this fixed a bug where block entity is larger than the block like the physics block model.
					local bx, by, bz = result.entity:GetBlockPos();
					is_processed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, bx, by, bz, event.mouse_button, EntityManager.GetPlayer(), result.side);
				else
					is_processed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, result.blockX, result.blockY, result.blockZ, event.mouse_button, EntityManager.GetPlayer(), result.side);
				end
			end
			if(is_processed) then
				-- do nothing if processed
				event:accept();
			elseif(mode == "game") then
				-- left click to move player to point
				if(not GameLogic.IsFPSView and System.options.leftClickToMove) then
					if(result and result.x) then
						System.HandleMouse.MovePlayerToPoint(result.x, result.y, result.z, true);
					end
				end
			elseif(mode == "survival") then
				-- do nothing
			end
		end
	elseif( click_data.left_holding_time > self.max_break_time) then
		if(mode == "survival") then
			-- long hold left click to delete the block
			self:TryDestroyBlock(result, true);	
		end
	end
end

-- virtual: 
function ParalifeContext:mouseReleaseEvent(event)
	if(not self:CanMoveToMouseCursor()) then
		self:RestoreDraggingEntity(event)
		event:accept()
		return
	end
	ParalifeContext._super.mouseReleaseEvent(self, event);
	if(event:isAccepted()) then
		return
	end

	if(self.is_click) then
		local result = self:CheckMousePick(event);
		local isClickProcessed;
		
		-- escape alt key for entity event, since alt key is for picking entity. 
		if( not event.alt_pressed and result and result.obj and result.entity and (not result.block_id or result.block_id == 0)) then
			-- since we already processed live model
			isClickProcessed = GameLogic.GetPlayerController():OnClickEntity(result.entity, result.blockX, result.blockY, result.blockZ, event.mouse_button);
		end

		if(isClickProcessed) then	
			-- do nothing
			event:accept();
		elseif(event.mouse_button == "left") then
			self:handleLeftClickScene(event, result)
		elseif(event.mouse_button == "right") then
			if(self:handleRightClickScene(event, result)) then
				event:accept();
			end
		end

		if(event.mouse_button == "left" and not event:IsCtrlKeysPressed() and not event:isAccepted() and result and result.x and GameLogic.GetPlayerController():OnClickSensorsByPoint(result.x, result.y, result.z, event.mouse_button)) then
			-- check for click sensors
			event:accept();
		elseif(not event:isAccepted() and self:IsClickToMoveEnabled()) then
			if(not result or not result.blockZ) then
				result = SelectionManager:MousePickBlock(true, true, true, 256, event.x, event.y)
			end
			if(result and result.blockZ) then
				if(result.physicalX) then
					-- when clicking on physical mesh, we will only move if the point in close to horizontal plane. 
					local x, y, z = result.physicalX, result.physicalY, result.physicalZ;
					-- we also need to ensure that there is 4 meters free space above the click point. 
					local entity, x1, y1, z1 = self:RayPickPhysicalLiveModel(x, y+4, z, 0, -1, 0, 10)
					if(entity and y1 and math.abs(y-y1) < 0.1) then
						self:SetTargetPosition(x, y, z)
						event:accept();
					end
				elseif(result.side) then
					local block = BlockEngine:GetBlock(result.blockX, result.blockY, result.blockZ)
					if(block) then
						if(self:MovePlayerToBlock(result.blockX, result.blockY, result.blockZ, result.block_id, result.side)) then
							event:accept();
						end
					end
				end
			end
		end
	end
end

-- @param x,y,z: ray origin in world space
-- @param dirX, dirY, dirZ: ray direction, default to 0, -1, 0
-- @param maxDistance: default to 10
-- @return entityLiveModel, hitX, hitY, hitZ: return entity live model that is hit by the ray. 
function ParalifeContext:RayPickPhysicalLiveModel(x, y, z, dirX, dirY, dirZ, maxDistance)
	local pt = ParaScene.Pick(x, y, z, dirX or 0, dirY or -1, dirZ or 0, maxDistance or 10, "point")
	if(pt:IsValid())then
		local entityName = pt:GetName();
		if(entityName and entityName~="") then
			local entity = EntityManager.GetEntity(entityName);
			if(entity and entity:isa(EntityManager.EntityLiveModel)) then
				local x1, y1, z1 = pt:GetPosition();
				return entity, x1, y1, z1;
			end
		end
	end
end

-- virtual: 
function ParalifeContext:mouseWheelEvent(event)
	ParalifeContext._super.mouseWheelEvent(self, event);
	if(event:isAccepted()) then
		return
	end
end

-- virtual: actually means key stroke. 
function ParalifeContext:keyPressEvent(event)
	ParalifeContext._super.keyPressEvent(self, event);
	if(event:isAccepted()) then
		return
	end
	if( self:handlePlayerKeyEvent(event)) then
		return;
	end

	local dik_key = event.keyname;
	if(dik_key == "DIK_B") then
	elseif(dik_key == "DIK_Q") then
		
	elseif(self:HandleQuickSelectKey(event)) then
		-- quick select key
	end
end

-- @return {wallHeight=0, wallToWallDistance = 0, wallWidth = 0}
function ParalifeContext:CalculateWallParamsByBlockSide(bx, by, bz, side)
	local params = {wallHeight = 0, wallToWallDistance = 0, wallWidth = 0};
	if(side and side>=0 and side<=3) then
		local block = BlockEngine:GetBlock(bx, by, bz)
		local upperWallHeight = 0;
		local lowerWallHeight = 0;
		params.floorY = by;
		-- wall height
		for i = 1, 10 do 
			local block = BlockEngine:GetBlock(bx, by+i, bz)
			if(block and (block.solid or block.obstruction)) then
				local bx1, by1, bz1 = BlockEngine:GetBlockIndexBySide(bx, by+i, bz, side)
				local block = BlockEngine:GetBlock(bx1, by1, bz1)
				if(not block or (not block.solid and not block.obstruction)) then
					upperWallHeight = upperWallHeight + 1;
				end
			else
				break
			end
		end
		for i = -1, -10, -1 do 
			local block = BlockEngine:GetBlock(bx, by+i, bz)
			if(block and (block.solid or block.obstruction)) then
				local bx1, by1, bz1 = BlockEngine:GetBlockIndexBySide(bx, by+i, bz, side)
				local block = BlockEngine:GetBlock(bx1, by1, bz1)
				if(not block or (not block.solid and not block.obstruction)) then
					lowerWallHeight = lowerWallHeight + 1;
					params.floorY = by1
				end
			else
				break
			end
		end

		-- wall to wall distance
		local dx, dy, dz = Direction.GetOffsetBySide(side)
		for i = 1, 20 do
			local block = BlockEngine:GetBlock(bx+dx*i, params.floorY, bz+dz*i)
			if(block and (block.solid or block.obstruction)) then
				break;
			else
				params.wallToWallDistance = params.wallToWallDistance + 1;
			end
		end
		params.wallHeight = upperWallHeight + lowerWallHeight + 1;

		-- wall width
		local dx, dz = 0, 0;
		if(side == 0 or side == 1) then
			dz = 1;
		else
			dx = 1
		end
		local widthLeft, widthRight = 0, 0;
		for i = 1, 10 do
			local block = BlockEngine:GetBlock(bx+dx*i, params.floorY, bz+dz*i)
			if(block and (block.solid or block.obstruction)) then
				local bx1, by1, bz1 = BlockEngine:GetBlockIndexBySide(bx+dx*i, params.floorY, bz+dz*i, side)
				local block = BlockEngine:GetBlock(bx1, by1, bz1)
				if(not block or (not block.solid and not block.obstruction)) then
					widthLeft = widthLeft + 1;
				end
			else
				break;
			end
		end
		for i = -1, -10,-1 do
			local block = BlockEngine:GetBlock(bx+dx*i, params.floorY, bz+dz*i)
			if(block and (block.solid or block.obstruction)) then
				local bx1, by1, bz1 = BlockEngine:GetBlockIndexBySide(bx+dx*i, params.floorY, bz+dz*i, side)
				local block = BlockEngine:GetBlock(bx1, by1, bz1)
				if(not block or (not block.solid and not block.obstruction)) then
					widthRight = widthRight + 1;
				end
			else
				break;
			end
		end
		params.wallWidth = widthLeft + widthRight + 1;
	end
	return params
end

-- @return bx, by, bz: it will return nil if no free fall position is found. 
function ParalifeContext:GetFreeFallPosition(bx, by, bz)
	local lastY = by;
	while(by > 0) do
		local block = BlockEngine:GetBlock(bx, by, bz)
		if(block and (block.solid or block.obstruction)) then
			-- we will try to move upwards to find free space. 
			by = by + 1
			break;
		else
			by = by - 1
		end
	end
	if(by <= lastY) then
		-- check 2 blocks above for free space, since the main player is 2 blocks high by default. 
		for i=0, 1 do
			local block = BlockEngine:GetBlock(bx, by+i, bz)
			if(block and (block.solid or block.obstruction)) then
				return;
			end
		end

		return bx, by, bz;
	end
end

-- refactor this to another task file
-- @return true if we are moving or false if can not move to target
function ParalifeContext:MovePlayerToBlock(bx, by, bz, blockId, side)
	local oldBx, oldBy, oldBz = bx, by, bz
	local bx, by, bz = BlockEngine:GetBlockIndexBySide(bx, by, bz, side)
	bx, by, bz = self:GetFreeFallPosition(bx, by, bz)
	if(not bx) then
		return
	end
	if(side and side>=0 and side<=3) then
		local params = self:CalculateWallParamsByBlockSide(oldBx, oldBy, oldBz, side);
		if(params.wallHeight >= 4 and params.wallWidth >= 4) then
			-- if the user click the side wall, we will move the camera. 
			if(params.wallToWallDistance > 10) then
				-- if the user clicks the side wall, we will ensure some minDistanceToWall. 
				local minDistanceToWall = 5;
				local dx, dy, dz = Direction.GetOffsetBySide(side)
				bx, bz = bx+dx*minDistanceToWall, bz+dz*minDistanceToWall
				bx, by, bz = self:GetFreeFallPosition(bx, by, bz)
				if(not bx) then
					return;
				end
			end

			local facing = Direction.directionTo3DFacing[side]
			if(facing) then
				self:SetTargetFacing(facing)
			end
		end
	end

	self:SetTargetBlockPosition(bx, by, bz)
	return true;
end

local gameEvents_ = {
	__entity_onclick = "OnHandleEntityClickEvent",
	__entity_onhover = "OnHandleEntityOnHover",
	__entity_onmount = "OnHandleEntityOnMount",
	__entity_onbegindrag = "OnHandleEntityBeginDrag",
	__entity_onenddrag = "OnHandleEntityEndDrag",
}
function ParalifeContext:OnGameEvent(event, lastReturnValue)
	if(not lastReturnValue) then
		local eventType = event:GetType();
		if(gameEvents_[eventType]) then
			lastReturnValue = ParalifeContext[gameEvents_[eventType]](self, event)
		end
	end
	return lastReturnValue;
end

function ParalifeContext:OnHandleEntityClickEvent(event)
	local msg = commonlib.totable(event.cmd_text)
	if(msg.name) then
		local entity = EntityManager.GetEntity(msg.name)
		if(entity and entity:isa(EntityManager.EntityLiveModel)) then
			local category = entity:GetCategory();
			if(category == "cameraClickSensor" and msg.facing) then
				local yaw = GameLogic.RunCommand("/camerayaw");
				local diff = mathlib.ToStandardAngle(msg.facing-yaw)
				if(math.abs(diff) < math.pi *0.3) then
					local x, y, z = entity:GetPosition()
					GameLogic.GetSceneContext():SetTargetPosition(x, y, z)
					GameLogic.GetSceneContext():SetTargetFacing(msg.facing)
					return true
				end
			end
		end
	end
end

function ParalifeContext:OnHandleEntityOnHover(event)
	local msg = commonlib.totable(event.cmd_text)
	if(msg.name) then
		local entity = EntityManager.GetEntity(msg.name)
		if(entity and entity:isa(EntityManager.EntityLiveModel)) then
		end
	end
end

function ParalifeContext:OnHandleEntityOnMount(event)
	local msg = commonlib.totable(event.cmd_text)
	if(msg.name) then
		local entity = EntityManager.GetEntity(msg.name)
		if(entity and entity:isa(EntityManager.EntityLiveModel)) then
		end
	end
end

function ParalifeContext:OnHandleEntityBeginDrag(event)
	local msg = commonlib.totable(event.cmd_text)
	if(msg.name) then
		local entity = EntityManager.GetEntity(msg.name)
		if(entity and entity:isa(EntityManager.EntityLiveModel)) then
		end
	end
end

function ParalifeContext:OnHandleEntityEndDrag(event)
	local msg = commonlib.totable(event.cmd_text)
	if(msg.name) then
		local entity = EntityManager.GetEntity(msg.name)
		if(entity and entity:isa(EntityManager.EntityLiveModel)) then
		end
	end
end

-- this function is called repeatedly if MousePickTimer is enabled. 
-- it can also be called independently. 
-- @param event: nil or a mouse event invoking this method. 
-- @return the picking result table
function ParalifeContext:CheckMousePick(event)
	local result = self.itemLiveModel and self.itemLiveModel:MousePickBlock(event)
	
	CameraController.OnMousePick(result, SelectionManager:GetPickingDist());
	-- highlight the block or terrain that the mouse picked
	if(result.length and result.length<SelectionManager:GetPickingDist() and GameLogic.GameMode:CanSelect()) then
		if(self.isHighLightEntity) then
			if (GameLogic.GameMode:IsEditor()) then
				self:HighlightPickBlock(result);
			end
			self:HighlightPickEntity(result);
		end
		return result;
	else
		self:ClearPickDisplay();
	end
	return result;
end

function ParalifeContext:CanMoveToMouseCursor(event)
	local player = EntityManager.GetPlayer()
	if(player) then
		local fromX, fromY, fromZ = player:GetBlockPos()
		local result = SelectionManager:MousePickBlock(true, true, true, 256)
		if(result.blockX) then
			local toX, toY, toZ = result.blockX, result.blockY, result.blockZ
			return self:CanMoveFromSrcToDest(fromX, fromY, fromZ, toX, toY, toZ)
		end
	end
	return true;
end

-- @param moveTime: if nil, we will move to target location with automatic speed.
-- if not, it will be the exact time to spend to move to the target. 
function ParalifeContext:SetTargetPosition(x, y, z, moveTime)
	local player = EntityManager.GetPlayer()
	if(player) then
		local fromX, fromY, fromZ = player:GetPosition()
		if(not x or self:CanMovePlayerFromSrcToDest(fromX, fromY, fromZ, x, y, z)) then
			ParalifeContext._super.SetTargetPosition(self, x, y, z, moveTime)
		end
	end
end

-- This is used for continous moving player 
-- @param fromX, fromY, fromZ: real world coordinates
-- @param toX, toY, toZ: real world coordinates
function ParalifeContext:CanMovePlayerFromSrcToDest(fromX, fromY, fromZ, toX, toY, toZ)
	if(self:HasInvisibleBlockerFromSrcToDest(fromX, fromY, fromZ, toX, toY, toZ)) then
		return false;
	end
	fromX, fromY, fromZ = BlockEngine:block(fromX, fromY, fromZ);
	toX, toY, toZ = BlockEngine:block(toX, toY, toZ);
	if(not self:CanMoveFromSrcToDest(fromX, fromY, fromZ, toX, toY, toZ)) then
		return false;
	end
	return true
end

-- we will check if there is endstone(id:155) between from_point and to_point. if there is, we will return false, otherwise true. 
-- if fromX, fromZ is on endstone, we will always return true
-- @param fromX, fromY, fromZ: block world coordinates
-- @param toX, toY, toZ: block world coordinates
-- @return boolean: true if there is no endstone in between.
function ParalifeContext:CanMoveFromSrcToDest(fromX, fromY, fromZ, toX, toY, toZ)
	local borderMarkerBlockId = self.borderMarkerBlockId;

	local dx = toX - fromX;
	local dz = toZ - fromZ;
	local dist = dx^2 + dz^2;

	local function HasMarkerBlock(bx, bz)
		local y = BlockEngine:GetFirstBlock(bx, 0, bz, borderMarkerBlockId, 4);
		return y>=0;
	end

	if(dist < 0.5 or HasMarkerBlock(fromX, fromZ)) then
		return true
	end
	dist = math.sqrt(dist);
	local step = 1/dist;
	local lastX, lastZ;
	local bHasMarker;
	for i = 0, math.floor(dist)+1 do
		local percent = math.min(1, step * i);
		local x, z = math.floor(fromX + percent * dx), math.floor(fromZ + percent * dz);
		if(lastX~=x or lastZ~=z) then
			lastX, lastZ = x, z;
			if(HasMarkerBlock(x, z)) then
				bHasMarker = true
				break;
			end
		end
	end
	return not bHasMarker;
end

function ParalifeContext:RestoreDraggingEntity(event)
	if(self.itemLiveModel) then
		self.itemLiveModel:RestoreDraggingEntity(event)
	end
end