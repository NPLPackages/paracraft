--[[
Title: Mobile Context
Author(s): Pbb
Date: 2022/10/31
Desc: mobile mode for paracraft. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileContext.lua")
local MobileContext = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileContext");
------------------------------------------------------------
]]
_G.MOBILE_BUTTON_STATE = {
	STATE_BATCH = 1,
	STATE_SELECT = 2,
    STATE_DELETE = 3,
	STATE_DRAW = 4,
	STATE_REPLACE = 5,
    STATE_OTHER = -1,
}
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local MobileContext = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.SceneContext.EditContext"), commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileContext"));

local open_on_click_blockid_list = {
	[10513] = 1,
	[10516] = 1,
	[211] = 1,
	[271] = 1,
	[228] = 1,
	[212] = 1,
}
MobileContext:Property("Name", "MobileContext");

function MobileContext:ctor()
	self.isSelectContext = false
end

-- virtual function: 
-- try to select this context. 
function MobileContext:OnSelect()
	MobileContext._super.OnSelect(self);
	self.isSelectContext = true
	self.state = MOBILE_BUTTON_STATE.STATE_OTHER
end

-- virtual function: 
-- return true if we are not in the middle of any operation and fire unselected signal. 
-- or false, if we can not unselect the scene tool context at the moment. 
function MobileContext:OnUnselect()
	MobileContext._super.OnUnselect(self);
	self.isSelectContext = false
	self.state = MOBILE_BUTTON_STATE.STATE_OTHER
	return true;
end

function MobileContext:SelectState(state)
	if not self.isSelectContext then
		self.state = MOBILE_BUTTON_STATE.STATE_OTHER
		return 
	end
    self.state = state
end

function MobileContext:GetState()
    if not self.state then
        self.state = MOBILE_BUTTON_STATE.STATE_OTHER
    end
    return self.state
end

function MobileContext:IsDeleteStatus()
	return self.state == MOBILE_BUTTON_STATE.STATE_DELETE
end

function MobileContext:handleRightClickScene(event, result) 
	local click_data = self:GetClickData();
	local ctrl_pressed, shift_pressed, alt_pressed;
	if(event) then
		ctrl_pressed, shift_pressed, alt_pressed = event.ctrl_pressed, event.shift_pressed, event.alt_pressed
	else
		ctrl_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL);
		shift_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RSHIFT);
		alt_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LMENU) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RMENU);
	end
	if(result) then
		if shift_pressed and not ctrl_pressed and not alt_pressed then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DestroyNearbyBlocksTask.lua");
			-- just around the player
			local task = MyCompany.Aries.Game.Tasks.DestroyNearbyBlocks:new({blockX=result.blockX, blockY=result.blockY, blockZ=result.blockZ, block_id = result.block_id, explode_time=200, })
			task:Run();
			event:accept();
			return			
		end	
		local isProcessed
		if(result.entity and result.entity:IsBlockEntity() and result.entity:GetBlockId() == result.block_id) then
			-- this fixed a bug where block entity is larger than the block like the physics block model.
			local bx, by, bz = result.entity:GetBlockPos();
			isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, bx, by, bz, event.mouse_button, EntityManager.GetPlayer(), result.side);
		else
			isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, result.blockX, result.blockY, result.blockZ, event.mouse_button, EntityManager.GetPlayer(), result.side);
		end
		if isProcessed then
			event:accept();
			return 
		end
		self:TryDestroyBlock(result, true);
		event:accept();
	end
end

function MobileContext:handleLeftClickScene(event, result) 
	local click_data = self:GetClickData();
	local result = result or self:CheckMousePick();
	local ctrl_pressed, shift_pressed, alt_pressed;
	if(event) then
		ctrl_pressed, shift_pressed, alt_pressed = event.ctrl_pressed, event.shift_pressed, event.alt_pressed
	else
		ctrl_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL);
		shift_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RSHIFT);
		alt_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LMENU) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RMENU);
	end
	-- print("pressed=====",ctrl_pressed, shift_pressed, alt_pressed)
	if(result) then
		if self:IsDeleteStatus() then
			self:TryDestroyBlock(result, true);
			event:accept();
			return
		end
		if ctrl_pressed then
			if(result.block_id) and not alt_pressed then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
				local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
				local task = SelectBlocks:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ})
				task:Run();
				if shift_pressed then
				 	task:RefreshImediately();
				 	-- Ctrl + shift + left click to select all connected blocks
				 	task.SelectAll(true);
				else
					NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/InfoWindow.lua");
					local InfoWindow = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.InfoWindow");
					InfoWindow.CopyToClipboard("mousepos")
				end
				event:accept();
				return
			end	
			if alt_pressed then
				self:DoReplaceOperate(result)
				event:accept();
				return
			end
		else
			if shift_pressed and alt_pressed then
				self:DoReplaceOperate(result,30)
				event:accept();
				return
			end
			if shift_pressed then
				self:DoBatchOperate(result)
				event:accept();
				return
			end
			if alt_pressed then
				if result then
					if (not result.block_id or result.block_id == 0) and (result.obj or result.entity) then
						GameLogic.GetPlayerController():PickItemByEntity(result.entity)
					elseif result.block_id and result.block_id ~= 0 and result.blockX then
						GameLogic.GetPlayerController():PickBlockAt(result.blockX, result.blockY, result.blockZ, result.side)
					end
					event:accept();
					return
				end
			end
		end
		if result then
			local isProcessed
			if(result.entity and result.entity:IsBlockEntity() and result.entity:GetBlockId() == result.block_id) then
				-- this fixed a bug where block entity is larger than the block like the physics block model.
				local bx, by, bz = result.entity:GetBlockPos();
				isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, bx, by, bz, event.mouse_button, GameLogic.EntityManager.GetPlayer(), result.side);
			else
				isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, result.blockX, result.blockY, result.blockZ, event.mouse_button, GameLogic.EntityManager.GetPlayer(), result.side);
			end
			
			if isProcessed then
				if result.block_id and open_on_click_blockid_list[result.block_id] then
					GameLogic.GetPlayerController():OnClickBlock(result.block_id, result.blockX, result.blockY, result.blockZ, "right", GameLogic.EntityManager.GetPlayer(), result.side)
				end
				return 
			end
			local itemStack = GameLogic.EntityManager.GetPlayer():GetItemInRightHand();
			local block_id = 0
			if(itemStack) then
				block_id = itemStack.id
			end
			if(result.blockX) then
				local x,y,z = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
				self:OnCreateSingleBlock(x,y,z, block_id, result)
				GameLogic.GetFilters():apply_filters("create_block_event","CreateSingleBlock");
			end
			event:accept();
		end	
	end
end

function MobileContext:DoBatchOperate(result)
	if not result then
		return 
	end
	local itemStack = EntityManager.GetPlayer():GetItemInRightHand();
	local block_id = 0;
	local block_data = nil;
	local processed;
	if(itemStack) then
		block_id = itemStack.id;
		local item = itemStack:GetItem();
		if(item) then
			block_data = item:GetBlockData(itemStack);
		else
			LOG.std(nil, "debug", "MobileConetxt", "no block definition for %d", block_id or 0)
			return
		end
	end
	if block_id and block_id > 4096 then
		if GameLogic.GameMode:IsEditor() then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/FillLineTask.lua");
			local task = MyCompany.Aries.Game.Tasks.FillLine:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, to_data = block_data, side = result.side})
			task:Run();
			processed = true
		end
		if(not processed) then
			local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, block_id = block_id, side = result.side, entityPlayer = EntityManager.GetPlayer()})
			task:Run();
		end
	else
		if GameLogic.GameMode:IsEditor() then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/FillLineTask.lua");
			local task = MyCompany.Aries.Game.Tasks.FillLine:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, to_data = block_data, side = result.side})
			task:Run();
		else
			local x,y,z = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
			self:OnCreateSingleBlock(x,y,z, block_id, result)
			GameLogic.GetFilters():apply_filters("create_block_event","CreateSingleBlock");
		end
	end
end

function MobileContext:DoReplaceOperate(result,radius)
	if not result then
		return
	end
	local itemStack = EntityManager.GetPlayer():GetItemInRightHand();
	local block_id = 0;
	local block_data = nil;
	if(itemStack) then
		block_id = itemStack.id;
		local item = itemStack:GetItem();
		if(item) then
			block_data = item:GetBlockData(itemStack);
		else
			LOG.std(nil, "debug", "MobileConetxt", "no block definition for %d", block_id or 0);
			return;
		end
	end
	if block_id or result.block_id == block_types.names.water and block_id ~= block_types.names.PhysicsModel and block_id ~= block_types.names.BlockModel then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ReplaceBlockTask.lua");
		local task = MyCompany.Aries.Game.Tasks.ReplaceBlock:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, to_id = block_id or 0,max_radius = (radius ~= nil and radius or nil), to_data = block_data, preserveRotation=true})
		task:Run();
		GameLogic.GetFilters():apply_filters("create_block_event","ReplaceBlocks",task);
	end
end


--备份
function MobileContext:handleLeftClickScene1(event, result) --长按逻辑
	local click_data = self:GetClickData();
	if( self.left_holding_time < 150 and result) then
		if self:GetState() == MOBILE_BUTTON_STATE.STATE_BATCH then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DestroyNearbyBlocksTask.lua");
			-- just around the player
			local task = MyCompany.Aries.Game.Tasks.DestroyNearbyBlocks:new({blockX=result.blockX, blockY=result.blockY, blockZ=result.blockZ, block_id = result.block_id, explode_time=200, })
			task:Run();
		elseif self:GetState() == MOBILE_BUTTON_STATE.STATE_OTHER then
			local isProcessed
			if(result.entity and result.entity:IsBlockEntity() and result.entity:GetBlockId() == result.block_id) then
				-- this fixed a bug where block entity is larger than the block like the physics block model.
				local bx, by, bz = result.entity:GetBlockPos();
				isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, bx, by, bz, event.mouse_button, EntityManager.GetPlayer(), result.side);
			else
				isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, result.blockX, result.blockY, result.blockZ, event.mouse_button, EntityManager.GetPlayer(), result.side);
			end
			if isProcessed then
				return 
			end
			self:TryDestroyBlock(result, true);
		end	
	end
end

function MobileContext:handleRightClickScene1(event, result) 
	local click_data = self:GetClickData();
	local result = result or self:CheckMousePick();
	if(result) then
		if self:GetState() == MOBILE_BUTTON_STATE.STATE_SELECT then
			if(result.block_id) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
				local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
				local task = SelectBlocks:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ})
				task:Run();
				-- if(is_shift_pressed) then
				-- 	task:RefreshImediately();
				-- 	-- Ctrl + shift + left click to select all connected blocks
				-- 	task.SelectAll(true);
				-- end
			end
		elseif self:GetState() == MOBILE_BUTTON_STATE.STATE_DELETE then
			self:TryDestroyBlock(result, true);
		elseif self:GetState() == MOBILE_BUTTON_STATE.STATE_BATCH then 
			self:DoBatchOperate(result)
		elseif self:GetState() == MOBILE_BUTTON_STATE.STATE_DRAW then
			if result then
				if (not result.block_id or result.block_id == 0) and (result.obj or result.entity) then
					GameLogic.GetPlayerController():PickItemByEntity(result.entity)
				elseif result.block_id and result.block_id ~= 0 and result.blockX then
					GameLogic.GetPlayerController():PickBlockAt(result.blockX, result.blockY, result.blockZ, result.side)
				end
			end
		elseif self:GetState() == MOBILE_BUTTON_STATE.STATE_REPLACE then
			if result then
				local itemStack = GameLogic.EntityManager.GetPlayer():GetItemInRightHand();
				local block_id = 0;
				local block_data = nil;
				if(itemStack) then
					block_id = itemStack.id;
					local item = itemStack:GetItem();
					if(item) then
						block_data = item:GetBlockData(itemStack);
					else
						LOG.std(nil, "debug", "MobileConetxt", "no block definition for %d", block_id or 0);
						return;
					end
				end
				if block_id or result.block_id == block_types.names.water and block_id ~= block_types.names.PhysicsModel and block_id ~= block_types.names.BlockModel then
					NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ReplaceBlockTask.lua");
					local task = MyCompany.Aries.Game.Tasks.ReplaceBlock:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, to_id = block_id or 0, to_data = block_data, max_radius = 30, preserveRotation=true})
					task:Run();
					GameLogic.GetFilters():apply_filters("create_block_event","ReplaceBlocks",task);
				end
			end
		elseif self:GetState() == MOBILE_BUTTON_STATE.STATE_OTHER then
			if result then
				local isProcessed
				if(result.entity and result.entity:IsBlockEntity() and result.entity:GetBlockId() == result.block_id) then
					-- this fixed a bug where block entity is larger than the block like the physics block model.
					local bx, by, bz = result.entity:GetBlockPos();
					isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, bx, by, bz, event.mouse_button, GameLogic.EntityManager.GetPlayer(), result.side);
				else
					isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, result.blockX, result.blockY, result.blockZ, event.mouse_button, GameLogic.EntityManager.GetPlayer(), result.side);
				end
				if isProcessed then
					return 
				end
				local itemStack = GameLogic.EntityManager.GetPlayer():GetItemInRightHand();
				local block_id = 0
				if(itemStack) then
					block_id = itemStack.id
				end
				local x,y,z = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
				self:OnCreateSingleBlock(x,y,z, block_id, result)
				GameLogic.GetFilters():apply_filters("create_block_event","CreateSingleBlock");
			end
		end	
	end
end


-- virtual: 
function MobileContext:mouseWheelEvent(event)
	if(self:handleHookedMouseEvent(event)) then
		return;
	end

	if(not ParaCamera.GetAttributeObject():GetField("EnableMouseWheel", false)) then
		self:handleCameraWheelEvent(event);
	end

	if(GameLogic.GetCodeGlobal():BroadcastKeyPressedEvent("mouse_wheel", mouse_wheel)) then
		return true;
	end
end

