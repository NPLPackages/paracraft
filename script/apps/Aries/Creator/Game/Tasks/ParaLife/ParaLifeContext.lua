--[[
Title: Paralife Context
Author(s): LiXizhi
Date: 2022/1/12
Desc: handles scene key/mouse events. This is the default play mode scene context 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeContext.lua");
local ParalifeContext = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParalifeContext")
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/BaseContext.lua");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local ParalifeContext = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.SceneContext.BaseContext"), commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParalifeContext"));

ParalifeContext:Property("Name", "ParalifeContext");
ParalifeContext:Property({"clickToMove", true, "IsClickToMoveEnabled", "EnableClickToMove", auto = true});

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
	ParalifeContext._super.OnSelect(self);
	self:EnableMousePickTimer(true);
	self:EnablePlayerTimer()
end

-- virtual function: 
-- return true if we are not in the middle of any operation and fire unselected signal. 
-- or false, if we can not unselect the scene tool context at the moment. 
function ParalifeContext:OnUnselect()
	ParalifeContext._super.OnUnselect(self);
	self:DisablePlayerTimer();
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

-- virtual: 
function ParalifeContext:mousePressEvent(event)
	ParalifeContext._super.mousePressEvent(self, event);
	if(event:isAccepted()) then
		return
	end
	local click_data = self:GetClickData();

	self:EnableMouseDownTimer(true);

	local result = self:CheckMousePick();
	self:UpdateClickStrength(0, result);

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
	local result = self:CheckMousePick();
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
	ParalifeContext._super.mouseReleaseEvent(self, event);
	if(event:isAccepted()) then
		return
	end

	if(self.is_click) then
		local result = self:CheckMousePick();
		local isClickProcessed;
		
		-- escape alt key for entity event, since alt key is for picking entity. 
		if( not event.alt_pressed and result and result.obj and result.entity and (not result.block_id or result.block_id == 0)) then
			-- for entities. 
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

		if(not event:isAccepted() and self:IsClickToMoveEnabled() and result and result.blockZ and result.side) then
			local block = BlockEngine:GetBlock(result.blockX, result.blockY, result.blockZ)
			if(block) then
				self:MovePlayerToBlock(result.blockX, result.blockY, result.blockZ, result.block_id, result.side)
				event:accept();
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

function ParalifeContext:EnablePlayerTimer()
	self.playerTimer = self.playerTimer or commonlib.Timer:new({callbackFunc = function(timer)
		self:OnPlayerTimer(timer)
	end})
	self.playerTimer:Change(30, 30)
end

function ParalifeContext:DisablePlayerTimer()
	if(self.playerTimer) then
		self.playerTimer:Change();
	end
	self:SetTargetBlockPosition(nil)
	self:SetTargetFacing(nil)
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

function ParalifeContext:GetFreeFallPosition(bx, by, bz)
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
	return bx, by, bz;
end

-- refactor this to another task file
function ParalifeContext:MovePlayerToBlock(bx, by, bz, blockId, side)
	local oldBx, oldBy, oldBz = bx, by, bz
	local bx, by, bz = BlockEngine:GetBlockIndexBySide(bx, by, bz, side)
	bx, by, bz = self:GetFreeFallPosition(bx, by, bz)

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
			end

			local facing = Direction.directionTo3DFacing[side]
			if(facing) then
				self:SetTargetFacing(facing)
			end
		end
	end

	self:SetTargetBlockPosition(bx, by, bz)
end

function ParalifeContext:SetTargetFacing(facing)
	self.targetFacing = facing
end

function ParalifeContext:SetTargetBlockPosition(bx, by, bz)
	local player = EntityManager.GetPlayer()
	local obj = player:GetInnerObject()
	local attr = ParaCamera.GetAttributeObject();
	self.startPlayerX, self.startPlayerY, self.startPlayerZ = player:GetPosition()
	self.targetX, self.targetY, self.targetZ = bx, by, bz;
	self.timeUsed = 0;
	if(self.targetX) then
		local eye_pos = attr:GetField("Eye position", {0,0,0});
		local lookat_pos = attr:GetField("Lookat position", {0,0,0});
		local camobjDist, LiftupAngle, CameraRotY = attr:GetField("CameraObjectDistance", 0), attr:GetField("CameraLiftupAngle", 0), attr:GetField("CameraRotY", 0);
		local dist, pitch, yaw = camobjDist, LiftupAngle, CameraRotY;

		local eyeX, eyeY, eyeZ = eye_pos[1], eye_pos[2], eye_pos[3]
		local lookatX, lookatY, lookatZ = lookat_pos[1], lookat_pos[2], lookat_pos[3]
		local cameraEyeDistance = math.sqrt((eyeX-lookatX)^2 + (eyeY-lookatY)^2 + (eyeZ-lookatZ)^2)
		if(cameraEyeDistance+0.1 > camobjDist) then
			-- only disable camera collision if the current camera is not in collision 
			attr:SetField("EnableBlockCollision", false);
		end
		-- only linear movement style. 
		obj:SetField("MovementStyle", 3)
	else
		-- normal movement style
		obj:SetField("MovementStyle", 0)
		attr:SetField("EnableBlockCollision", true);
	end
end

-- called on player frame move
function ParalifeContext:OnPlayerTimer(timer)
	local reachTargetTimeLeft;
	if(self.targetX) then
		local player = EntityManager.GetPlayer()
		local px, py, pz = self.startPlayerX, self.startPlayerY, self.startPlayerZ;
		local tx, ty, tz = BlockEngine:real_bottom(self.targetX, self.targetY, self.targetZ);
		local fromBX, fromBY, fromBZ = BlockEngine:block(self.startPlayerX, self.startPlayerY, self.startPlayerZ);
		
		local dist = math.sqrt((tx - px) ^ 2 + (ty - py) ^ 2 + (tz - pz) ^ 2)
		local deltaTime = timer:GetDelta() / 1000
		self.timeUsed = self.timeUsed + deltaTime;
		-- player move speed will increase according to move distance
		local moveDist = math.min(100, (10 + (dist^2)/20)) * self.timeUsed
		
		if(dist > moveDist and dist > 0.1) then
			local ratio = moveDist / dist;
			reachTargetTimeLeft = self.timeUsed / ratio * (1 - ratio)

			local x = px + (tx - px) * ratio
			local y = py + (ty - py) * ratio
			local z = pz + (tz - pz) * ratio
			
			player:SetPosition(x, y, z)
		else
			-- we already reached the target position
			player:SetPosition(tx, ty, tz)
			self:SetTargetBlockPosition(nil)
		end
	end
	if(self.targetFacing) then
		local player = EntityManager.GetPlayer()
		local deltaTime = timer:GetDelta() / 1000
		local attr = ParaCamera.GetAttributeObject();
		local cameraRotY = attr:GetField("CameraRotY", 0);
		local targetRotY = self.targetFacing;

		local newRotY, bReached = mathlib.SmoothMoveAngle(cameraRotY, targetRotY, (30+(math.abs(mathlib.ToStandardAngle(targetRotY-cameraRotY))*100)^2/30) * deltaTime/180*math.pi)
		attr:SetField("CameraRotY", newRotY)
		if(bReached) then
			self:SetTargetFacing(nil)
		end
	end
end

