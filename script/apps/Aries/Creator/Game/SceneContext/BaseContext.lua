--[[
Title: Base Context
Author(s): LiXizhi
Date: 2015/7/10
Desc: handles global scene key/mouse events. This is usually the base class to other scene context. 
virtual functions:
	mousePressEvent(event)
	mouseMoveEvent
	mouseReleaseEvent
	mouseWheelEvent
	keyPressEvent
	keyReleaseEvent: not implemented

	OnSelect()
	OnUnselect()
	OnLeftLongHoldBreakBlock()
	OnLeftMouseHold(fDelta)
	OnRightMouseHold(fDelta)

	handleHistoryKeyEvent();
	handlePlayerKeyEvent();

	GetClickData()

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/BaseContext.lua");
local BaseContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.BaseContext");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/SceneContext.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_hotkey.lua");
local hotkey_manager = commonlib.gettable("System.mcml_controls.hotkey_manager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local ModManager = commonlib.gettable("Mod.ModManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local vector3d = commonlib.gettable("mathlib.vector3d");

local BaseContext = commonlib.inherit(commonlib.gettable("System.Core.SceneContext"), commonlib.gettable("MyCompany.Aries.Game.SceneContext.BaseContext"));

BaseContext:Property({"Name", "BaseContext"});
-- in ms seconds
BaseContext:Property({"max_break_time", 500});
-- if true, left click to delete; if false, left click to move the player to the block. 
BaseContext:Property({"LeftClickToDelete", true});
BaseContext:Property({"ShowClickStrengthUI", false});
-- the block id for the edit marker. usually 155 (ending stone). if specified,
-- mouse block picking is only valid when there is a marker block below. 
BaseContext:Property({"EditMarkerBlockId", nil, auto=true});

-- temporary data to break a block. 
local click_data = {
	-- time in ms to break a block. if a block requires 500 strength to break it , then the user must keeps pressing the button for 500ms to delete it. 
	strength = nil, 
	last_select_block = {},
	is_button_down = false,
	left_holding_time = 0,
	right_holding_time = 0,
	last_select_entity = nil,
	last_mouse_down_block = {},
};
BaseContext.click_data = click_data;

function BaseContext:ctor()
	if(not System.options.mc) then
		-- leak events to hook chain for old haqi interfaces, such as terrain painting. 
		self:SetAcceptAllEvents(false);
	end
	if(System.options.IsTouchDevice) then
		self.pickingPointSize = 24;
	end
end

function BaseContext:OnSelect()
	BaseContext._super.OnSelect(self);
end

-- virtual function: 
-- return true if we are not in the middle of any operation and fire unselected signal. 
-- or false, if we can not unselect the scene tool context at the moment. 
function BaseContext:OnUnselect()
	self:EnableMouseDownTimer(false);
	self:EnableMousePickTimer(false);
	self:ClearPickDisplay();
	self:UpdateClickStrength(-1);
	click_data.selector = nil;
	return true;
end

function BaseContext:GetClickData()
	return click_data;
end

-- user has drag and dropped an existing file to the context
-- @param fileType: "model", "blocktemplate"
function BaseContext:handleDropFile(filename, fileType)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemStack.lua");
	local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
	local item_stack = ItemStack:new():Init(block_types.names.BlockModel);
	item_stack:SetTooltip(filename);
	GameLogic.GetPlayerController():SetBlockInRightHand(item_stack);
	GameLogic.AddBBS(nil, format(L"模型物品: %s 在你手中了", filename));
end

-- enable mouse down timer to repeatedly receive OnMouseDownTimer callback. 
-- mouse down timer is automatically stopped when there is no mouse event. so one only need to enable it in mouse press event. 
function BaseContext:EnableMouseDownTimer(bEnable)
	if(bEnable) then
		self.mouse_down_timer = self.mouse_down_timer or commonlib.Timer:new({callbackFunc = function(timer)
			self:OnMouseDownTimer(timer);
		end});
		self.mouse_down_timer:Change(50, 30);
	else
		if(self.mouse_down_timer) then
			self.mouse_down_timer:Change();
		end
	end
end

function BaseContext:EnableMousePickTimer(bEnable)
	if(bEnable) then
		self.mousepick_timer = self.mousepick_timer or commonlib.Timer:new({callbackFunc = function(timer)
			local result = self:CheckMousePick();
		end})
		self:CheckMousePick();
	else
		if(self.mousepick_timer) then
			self.mousepick_timer:Change();
			self.mousepick_timer = nil;
		end
	end
end

--virtual function: called repeatedly whenever mouse button is down. 
function BaseContext:OnMouseDownTimer(timer)
	local bLeftButtonDown = ParaUI.IsMousePressed(0)
	local bRightButtonDown = ParaUI.IsMousePressed(1)
	if(bLeftButtonDown and not bRightButtonDown) then
		self:OnLeftMouseHold(timer:GetDelta());
	elseif(bRightButtonDown and not bLeftButtonDown) then
		self:OnRightMouseHold(timer:GetDelta());
	else
		self:UpdateClickStrength(-1)
		timer:Change();
	end
end

-- return true if handled
function BaseContext:handleHookedMouseEvent(event)
	if(ModManager:handleMouseEvent(event)) then
		return true;
	end

	if(self:handleItemMouseEvent(event)) then
		return true;
	end

	if(event:GetType() == "mousePressEvent") then
		if(GameLogic.GetCodeGlobal():BroadcastKeyPressedEvent("mouse_buttons", event)) then
			-- we need to leak event to global scene, even we processed it
			-- return true;
		end
	elseif(event:GetType() == "mouseReleaseEvent") then
		if(event:button() == "left" and event:GetDragDist() < 10) then
			if(GameLogic.GetCodeGlobal():BroadcastBlockClickEvent("BroadcastBlockClickEvent", event)) then
				-- we need to leak event to global scene, even we processed it
				-- return true;
			end
		end
	end

	return event:isAccepted();
end

-- if item accept mousePressEvent, it will also handle mouseMove and mouseRelease on its own. 
-- if item does not accept mousePressEvent, it will not receive any mouseMove or mouseRelease event, and the default handler is used. 
-- return true if handled
function BaseContext:handleItemMouseEvent(event)
	local curItem = GameLogic.GetPlayerController():GetItemInRightHand();
	local event_type = event:GetType();
	if(event_type == "mousePressEvent") then
		curItem:event(event);
		if(event:isAccepted()) then
			self.lastMouseDownItem = curItem;	
		else
			self.lastMouseDownItem = nil;
		end
	elseif(event_type == "mouseWheelEvent") then
		curItem:event(event);
	else
		-- mouse move and release event are only sent to the same last mouse down item.
		if(self.lastMouseDownItem) then
			self.lastMouseDownItem:event(event);
			-- accept anyway
			event:accept();
			if(event_type == "mouseReleaseEvent") then
				self.lastMouseDownItem = nil;
			end
		elseif(event_type == "mouseMoveEvent" and not curItem:hasMouseTracking()) then
			-- skip mouseMoveEvent if mouse-tracking is off 
		else
			curItem:event(event);
		end
	end
	return event:isAccepted();
end

-- this function is called repeatedly if MousePickTimer is enabled. 
-- it can also be called independently. 
-- @return the picking result table
function BaseContext:CheckMousePick()
	if(self.mousepick_timer) then
		self.mousepick_timer:Change(50, nil);
	end

	local result = SelectionManager:MousePickBlock();

	if(self:GetEditMarkerBlockId() and result and result.block_id and result.block_id>0 and result.blockX) then
		local y = BlockEngine:GetFirstBlock(result.blockX, result.blockY, result.blockZ, self:GetEditMarkerBlockId(), 5);
		if(y<0) then
			-- if there is no helper blocks below the picking position, we will return nothing. 
			SelectionManager:ClearPickingResult();
			self:ClearPickDisplay();
			return;
		end
	end

	CameraController.OnMousePick(result, SelectionManager:GetPickingDist());
	
	if(result.length and result.blockX) then
        if(EntityManager.GetFocus())then
            if(not EntityManager.GetFocus():CanReachBlockAt(result.blockX,result.blockY,result.blockZ)) then
			    SelectionManager:ClearPickingResult();
		    end
        end
	end
	
	-- highlight the block or terrain that the mouse picked
	if(result.length and result.length<SelectionManager:GetPickingDist() and GameLogic.GameMode:CanSelect()) then
		if (GameLogic.GameMode:IsEditor()) then
			self:HighlightPickBlock(result);
		end
		self:HighlightPickEntity(result);
		return result;
	else
		self:ClearPickDisplay();
	end
end

function BaseContext:HighlightPickBlock(result)
	if(not click_data or not click_data.last_select_block or not result) then
		return;
	end
	if(click_data.last_select_block.blockX ~= result.blockX or click_data.last_select_block.blockY ~= result.blockY or click_data.last_select_block.blockZ ~= result.blockZ) then
		if(click_data.last_select_block.blockX) then
				
			ParaTerrain.SelectBlock(click_data.last_select_block.blockX,click_data.last_select_block.blockY, click_data.last_select_block.blockZ,false,GameLogic.options.wire_frame_group_id);
			GameLogic.events:DispatchEvent({type = "HighlightPickBlock",
				x = click_data.last_select_block.blockX, y = click_data.last_select_block.blockY, z = click_data.last_select_block.blockZ, select = false});
		end
		if(click_data.last_select_block.group_index) then
			ParaSelection.ClearGroup(click_data.last_select_block.group_index);
			click_data.last_select_block.group_index = nil;
		end

		local selection_effect;
		if(result and result.block_id and result.block_id > 0) then
			local block = block_types.get(result.block_id);
			if(block) then
				selection_effect = block.selection_effect;
				if(selection_effect == "model_highlight") then
					if(block:AddToSelection(result.blockX,result.blockY, result.blockZ, 2)) then
						selection_effect = "none";
						click_data.last_select_block.group_index = 2;
					end
				end
			end
		end
			
		if(not selection_effect) then
			ParaTerrain.SelectBlock(result.blockX,result.blockY, result.blockZ,true, GameLogic.options.wire_frame_group_id);	
			GameLogic.events:DispatchEvent({type = "HighlightPickBlock" , x = result.blockX, y = result.blockY, z = result.blockZ, select = true});
		elseif(selection_effect == "none") then
			--  do nothing
		else
			-- TODO: other effect. 
			ParaTerrain.SelectBlock(result.blockX,result.blockY, result.blockZ,true, GameLogic.options.wire_frame_group_id);	
		end
		click_data.last_select_block.blockX, click_data.last_select_block.blockY, click_data.last_select_block.blockZ = result.blockX,result.blockY, result.blockZ;
	end
end

function BaseContext:HighlightPickEntity(result)
	if(not result.block_id and result.entity and result.obj) then
		click_data.last_select_entity = result.entity;
		ParaSelection.AddObject(result.obj, 1);
		self:ClearBlockPickDisplay();
	elseif(click_data.last_select_entity) then
		click_data.last_select_entity = nil;
		ParaSelection.ClearGroup(1);
	end
end

function BaseContext:ClearBlockPickDisplay()
	ParaTerrain.DeselectAllBlock(GameLogic.options.wire_frame_group_id);
	click_data.last_select_block.blockX, click_data.last_select_block.blockY, click_data.last_select_block.blockZ = nil, nil,nil;
	GameLogic.events:DispatchEvent({type = "ClearPickDisplay"});
end

function BaseContext:ClearPickDisplay()
	self:ClearBlockPickDisplay();
	if(click_data.last_select_entity) then
		click_data.last_select_entity = nil;
		ParaSelection.ClearGroup(1);
	end
end

-- called every 30 milliseconds, when user is holding the left button without releasing it. 
-- @param fDelta: 
function BaseContext:OnLeftMouseHold(fDelta)
	local last_x, last_y, last_z = click_data.last_mouse_down_block.blockX, click_data.last_mouse_down_block.blockY, click_data.last_mouse_down_block.blockZ;
	local result = self:CheckMousePick();
	
	if(result) then
		if(result.block_id) then
			click_data.last_mouse_down_block.blockX, click_data.last_mouse_down_block.blockY, click_data.last_mouse_down_block.blockZ = result.blockX,result.blockY,result.blockZ;
			local block = block_types.get(result.block_id);

			if(block and (last_x~=result.blockX or last_y~=result.blockY or  last_z~=result.blockZ)) then
				block:OnMouseDown(result.blockX,result.blockY,result.blockZ, "left");
			end
			
			if(block and block:CanDestroyBlockAt(result.blockX,result.blockY,result.blockZ)) then
				self:UpdateClickStrength(fDelta, result);

				click_data.left_holding_time = click_data.left_holding_time + fDelta;

				if(GameMode:AllowLongHoldToDestoryBlock()) then
					if(click_data.strength and click_data.strength > self.max_break_time) then
						self:OnLeftLongHoldBreakBlock();
						click_data.left_holding_time = 0;
					end
				end
			end
		elseif(GameLogic.GameMode:IsEditor() and result.blockX) then
			self:UpdateClickStrength(fDelta, result);
			click_data.left_holding_time = click_data.left_holding_time + fDelta;
		end
	end
end

-- virtual function: when user is holding the left button for long enough. 
function BaseContext:OnLeftLongHoldBreakBlock()
end

function BaseContext:OnRightMouseHold(fDelta)
	click_data.right_holding_time = click_data.right_holding_time + fDelta;
end

function BaseContext:UpdateClickStrength(fDelta, result)
	if(not fDelta or fDelta<0)	then
		click_data.strength = nil;
		click_data.result = nil;
	else
		if(click_data.result == nil and result) then
			click_data.result = commonlib.clone(result);
			click_data.strength = 0;
		elseif(result) then
			if(click_data.result.blockX == result.blockX and click_data.result.blockY == result.blockY and click_data.result.blockZ == result.blockZ) then
				click_data.strength = (click_data.strength or 0) + fDelta;
				-- TODO: clicking on terrain. 
			else
				click_data.result = commonlib.clone(result);
				-- tricky: if the user keeps pressing the button on multiple blocks, the strength does not vanish to 0 immediately, 
				-- instead, it only decreases for a small number like 250(self.max_break_time*0.5). 
				local block_id = ParaTerrain.GetBlockTemplateByIdx(result.blockX,result.blockY,result.blockZ);
				if(block_id > 0) then
					-- holding on a different block 
					click_data.strength = 0; -- math.max(0, (click_data.strength or 0) - self.max_break_time*0.5);
				else
					-- holding on the terrain
					click_data.strength = 0;
				end
			end
		else
			click_data.result = nil;
			click_data.strength = nil;
		end
	end

	-- update block texture animation
	if(click_data.strength and click_data.result and click_data.result.blockX) then
		local damage_degree;
		if(click_data.result.block_id) then
			local block = block_types.get(click_data.result.block_id);
			if(block and block.selection_effect == "model_highlight") then
				local degree = math.min(click_data.strength/self.max_break_time,1)*0.7;
				if(degree<0.35) then
					damage_degree = 0;
				end
			end
		end
		ParaTerrain.SetDamagedBlock(click_data.result.blockX,click_data.result.blockY,click_data.result.blockZ);
		ParaTerrain.SetDamagedDegree(damage_degree or math.min(click_data.strength/self.max_break_time,1)*0.7);
	else
		ParaTerrain.SetDamagedDegree(0.0);
	end
	
	-- TODO: upadte 3d effect. 

	-- update ui animation
	if(self.ShowClickStrengthUI) then
		local _this = ParaUI.GetUIObject("click_strength");
		if(not _this:IsValid())then
			local _this = ParaUI.CreateUIObject("button", "click_strength", "_lt", -32, -32, 64, 64);
			_this.background = "Texture/Aries/Common/ThemeTeen/circle_32bits.png";
			_this.enabled = false;
			_guihelper.SetUIColor(_this, "#ffffffff");
			_this:AttachToRoot();
		end
		if(click_data.strength) then
			_this.visible = true;
			local scale = math.min(1, (click_data.strength + 30)/500);
			_this.scalingx = scale;
			_this.scalingy = scale;
			local mouseX, mouseY = ParaUI.GetMousePosition();
			_this.translationx = mouseX;
			_this.translationy = mouseY;
		else
			_this.visible = false;
		end
	end
end

local last_camera_pos = {0,0,0};
local last_lookat_params = {0,0,0}; -- facing, height, angle

-- call this function in mouse down event and then call EndMouseClickCheck() in mouse up event. 
-- if the latter return true, it is a mouse click, otherwise the camera has moved during begin/end pair. 
function BaseContext:BeginMouseClickCheck()
	local att = ParaCamera.GetAttributeObject();
	
	last_camera_pos = vector3d:new(att:GetField("Eye position", last_camera_pos));
	last_lookat_params = vector3d:new({att:GetField("CameraObjectDistance", 0), att:GetField("CameraLiftupAngle", 0), att:GetField("CameraRotY", 0)});
end

-- @param event: mouse release event
-- return true if it is a mouse click
function BaseContext:EndMouseClickCheck(event)
	if(not GameLogic.IsFPSView) then
		local att = ParaCamera.GetAttributeObject();
		local eye_pos = vector3d:new(att:GetField("Eye position", {0,0,0}));
		local lookat_params = vector3d:new({att:GetField("CameraObjectDistance", 0), att:GetField("CameraLiftupAngle", 0), att:GetField("CameraRotY", 0)});
		local diff = last_camera_pos - eye_pos;
		local diff2 = last_lookat_params - lookat_params;
		if(diff:length2() < 0.2) then
			if(math.abs(diff2[1])<0.2 and math.abs(diff2[2])<0.05 and math.abs(diff2[3])<0.05) then
				if(event and event:GetDragDist() > 10) then
					return;
				end
				return true;
			end
		end
	else
		local att = ParaCamera.GetAttributeObject();
		local lookat_params = vector3d:new({att:GetField("CameraObjectDistance", 0), att:GetField("CameraLiftupAngle", 0), att:GetField("CameraRotY", 0)});
		local diff2 = last_lookat_params - lookat_params;
		if(math.abs(diff2[1])<0.2 and math.abs(diff2[2])<0.05 and math.abs(diff2[3])<0.05) then
			if(event and event:GetDragDist() > 10) then
				return;
			end
			return true;
		end
	end
end

-- virtual: 
function BaseContext:mousePressEvent(event)
	if GameLogic.GetFilters():apply_filters("BaseContextMousePressEvent", false, event) then
		return
	end
	local temp = ParaUI.GetUIObjectAtPoint(event.x, event.y);
	if(temp:IsValid()) then
		return;
	end
	if(self:handleHookedMouseEvent(event)) then
		return;
	end
	self:BeginMouseClickCheck();
	if(event.mouse_button == "left") then
		click_data.left_holding_time = 0;
	elseif(event.mouse_button == "right") then
		click_data.right_holding_time = 0;
	end
end

-- virtual: 
function BaseContext:mouseMoveEvent(event)
	if(self:handleHookedMouseEvent(event)) then
		return;
	end
end

-- virtual: 
function BaseContext:mouseReleaseEvent(event)
	if GameLogic.GetFilters():apply_filters("BaseContextMouseReleaseEvent", false, event) then
		return
	end
	if(self:handleHookedMouseEvent(event)) then
		return;
	end
	self.is_click = self:EndMouseClickCheck(event); 
	self.left_holding_time = click_data.left_holding_time;
	self.right_holding_time = click_data.right_holding_time;
	
	if(event.mouse_button == "left") then
		click_data.left_holding_time = 0;
	end
	click_data.last_mouse_down_block.blockX, click_data.last_mouse_down_block.blockY, click_data.last_mouse_down_block.blockZ = nil, nil, nil;
end

function BaseContext:handleCameraWheelEvent(event)
	local CameraObjectDistance = ParaCamera.GetAttributeObject():GetField("CameraObjectDistance", 8);
	CameraObjectDistance = CameraObjectDistance - mouse_wheel * CameraObjectDistance * 0.1;
	CameraObjectDistance = math.max(2, math.min(CameraObjectDistance, 20));
	ParaCamera.GetAttributeObject():SetField("CameraObjectDistance", CameraObjectDistance);
end

-- virtual: 
function BaseContext:mouseWheelEvent(event)
	if(self:handleHookedMouseEvent(event)) then
		return;
	end

	if(not ParaCamera.GetAttributeObject():GetField("EnableMouseWheel", false)) then
		if(GameLogic.IsFPSView or (GameLogic.options.lock_mouse_wheel and not event.ctrl_pressed) or (not GameLogic.options.lock_mouse_wheel and event.ctrl_pressed)) then
			-- mouse wheel to toggle item in hand
			GameLogic.GetPlayerController():SetHandToolIndex(GameLogic.GetPlayerController():GetHandToolIndex() - mouse_wheel);
		else
			-- control + mouse wheel to zoom camera
			self:handleCameraWheelEvent(event);
		end
	end

	if(GameLogic.GetCodeGlobal():BroadcastKeyPressedEvent("mouse_wheel", mouse_wheel)) then
		return true;
	end
end

-- virtual: return true if handled
function BaseContext:handleHookedKeyEvent(event)
	if(ModManager:handleKeyEvent(event)) then
		return true;
	end

	if(self:handleItemKeyEvent(event)) then
		return true;
	end

	-- mcml based hotkey
	if(hotkey_manager.handle_key_event(event.virtual_key)) then
		return true;
	end

	if(GameLogic.GetCodeGlobal():BroadcastKeyPressedEvent(event.keyname)) then
		event:accept();
		return true;
	end
end

function BaseContext:handleItemKeyEvent(event)
	GameLogic.GetPlayerController():GetItemInRightHand():event(event);
	if(event:isAccepted()) then
		return true;
	end
end

-- virtual: actually means key stroke. 
function BaseContext:keyPressEvent(event)
	GameLogic.GetFilters():apply_filters("KeyPressEvent", false, event)
	if(event:isAccepted()) then
		return true;
	end
	if(self:handleHookedKeyEvent(event)) then
		return true;
	end
	if(self:HandleGlobalKey(event)) then
		return true;
	end
end

-- virtual function handle escape key
function BaseContext:HandleEscapeKey()
	if GameLogic.GetFilters():apply_filters("HandleEscapeKey") then
		return false
	end

	local state = System.GetState();
	if(type(state) == "table" and state.OnEscKey~=nil) then
		if(state.name ~= "MessageBox") then
			System.PopState(state.name);
		end
		if(type(state.OnEscKey)=="function") then
			state.OnEscKey();
		elseif(type(state.OnEscKey)=="string") then
			NPL.DoString(state.OnEscKey);
		end
		return
	end
		
	if(ParaScene.IsSceneEnabled()) then
		local ChatEdit = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatEdit");
		if(ChatEdit.HasFocus and ChatEdit.HasFocus()) then
			if(ChatEdit.handleEscKey) then
				ChatEdit.handleEscKey();
			end
		else
			GameLogic.ToggleDesktop("esc");
		end
	end
end


-- try to destroy the block at picking result
-- if the terrain block is hit, click_data.strength must be larger than max_break_time
-- @param is_allow_delete_terrain: true 
function BaseContext:TryDestroyBlock(result, is_allow_delete_terrain)
	-- try to destroy block
	if(result and result.blockX) then
		local click_data = self:GetClickData();
		-- removed the block
		local block_template = BlockEngine:GetBlock(result.blockX,result.blockY,result.blockZ);
		
		if(block_template and block_template:CanDestroyBlockAt(result.blockX,result.blockY,result.blockZ)) then
			if(EntityManager.GetFocus():CanReachBlockAt(result.blockX,result.blockY,result.blockZ)) then
				local task = MyCompany.Aries.Game.Tasks.DestroyBlock:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, is_allow_delete_terrain=is_allow_delete_terrain})
				task:Run();
				GameLogic.GetFilters():apply_filters("user_event_stat", "block", "destroy:"..tostring(block_template.id), 1, nil);
			end
		elseif(result.entity) then
			local bx, by, bz = result.entity:GetBlockPos();
			local block_template = BlockEngine:GetBlock(bx, by, bz);
			if(block_template and block_template:CanDestroyBlockAt(bx, by, bz)) then
				local task = MyCompany.Aries.Game.Tasks.DestroyBlock:new({blockX = bx,blockY = by, blockZ = bz, })
				task:Run();
				GameLogic.GetFilters():apply_filters("user_event_stat", "block", "destroy:"..tostring(block_template.id), 1, nil);
			end
		else
			-- if there is no block, we may have hit the terrain. 
			if(is_allow_delete_terrain and click_data.strength and click_data.strength > self.max_break_time) then
				--block.RemoveTerrainBlock(result.blockX,result.blockY,result.blockZ);
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateTerrainHoleTask.lua");
				local task = MyCompany.Aries.Game.Tasks.CreateTerrainHole:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ})
				task:Run();
			end
		end
	end
end

function BaseContext:OnCreateSingleBlock(x,y,z, block_id, result)
	local side_region;
	if(result.y) then
		if(result.side == 4) then
			side_region = "upper";
		elseif(result.side == 5) then
			side_region = "lower";
		else
			local _, center_y, _ = BlockEngine:real(0,result.blockY,0);
			if(result.y > center_y) then
				side_region = "upper";
			elseif(result.y < center_y) then
				side_region = "lower";
			end
		end
	end

	if(EntityManager.GetFocus():CanReachBlockAt(result.blockX,result.blockY,result.blockZ)) then
		local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blockX = x,blockY = y, blockZ = z, entityPlayer = EntityManager.GetPlayer(), block_id = block_id, side = result.side, from_block_id = result.block_id, side_region=side_region })
		task:Run();
	end
end

function BaseContext:OnCreateBlock(result)
	if result.blockX == nil or result.blockY == nil or result.blockZ == nil then
		return;
	end	
	local x,y,z = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
	local itemStack = EntityManager.GetPlayer():GetItemInRightHand();
	local block_id = 0;
	local block_data = nil;
	if(itemStack) then
		block_id = itemStack.id;
		local item = itemStack:GetItem();
		if(item) then
			block_data = item:GetBlockData(itemStack);
		else
			LOG.std(nil, "debug", "BaseContext", "no block definition for %d", block_id or 0);
			return;
		end
	end
	
	if(block_id and block_id > 4096) then
		-- for special blocks. 
		local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blockX = x,blockY = y, blockZ = z, block_id = block_id, side = result.side, entityPlayer = EntityManager.GetPlayer()})
		task:Run();
		GameLogic.GetFilters():apply_filters("user_event_stat", "block", "create:"..tostring(block_id), 1, nil);
	else
		local ctrl_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL);
		local shift_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RSHIFT);
		local alt_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LMENU) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RMENU);
		
		GameLogic.GetFilters():apply_filters("user_event_stat", "block", "create:"..tostring(block_id or result.block_id), 1, nil);

		if(GameLogic.GameMode:IsEditor()) then
			if(alt_pressed and shift_pressed) then
				if(block_id or result.block_id == block_types.names.water) then
					-- if ctrl key is pressed, we will replace block at the cursor with the current block in right hand. 
					NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ReplaceBlockTask.lua");
					local task = MyCompany.Aries.Game.Tasks.ReplaceBlock:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, to_id = block_id or 0, to_data = block_data, max_radius = 30})
					task:Run();
				end
			elseif(shift_pressed) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/FillLineTask.lua");
				local task = MyCompany.Aries.Game.Tasks.FillLine:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, to_data = block_data, side = result.side})
				task:Run();
			elseif(alt_pressed) then
				if(block_id) then
					-- if alt key is pressed, we will replace block at the cursor with the current block in right hand. 
					NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ReplaceBlockTask.lua");
					local task = MyCompany.Aries.Game.Tasks.ReplaceBlock:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, to_id = block_id, max_radius = 0, side = result.side})
					task:Run();
				end
			else
				self:OnCreateSingleBlock(x,y,z, block_id, result)
			end
		else
			self:OnCreateSingleBlock(x,y,z, block_id, result)
		end
	end
end

-- for Numeric key 1-9
function BaseContext:HandleQuickSelectKey(event)
end

function BaseContext:handleLeftClickScene(event, result)
end

function BaseContext:handleMiddleClickScene(event, result)
	result = result or SelectionManager:GetPickingResult();
	if(result and result.blockX) then
		
		if(GameMode:IsAllowGlobalEditorKey()) then
			local x, y, z = result.blockX, result.blockY, result.blockZ;
			local block_template = BlockEngine:GetBlock(x, y, z);
			if(block_template and not block_template.obstruction) then
				local block_template = BlockEngine:GetBlock(x, y-1, z);
				if(block_template and block_template.obstruction) then
					y = y - 1;
				end
			end
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeleportPlayerTask.lua");
			local task = MyCompany.Aries.Game.Tasks.TeleportPlayer:new({blockX = x, blockY = y, blockZ = z})
			task:Run();	
		end
	end
end

function BaseContext:handleRightClickScene(event, result)
	result = result or SelectionManager:GetPickingResult();
	local isProcessed;
	if(not isProcessed and result and result.blockX) then
		if(click_data.right_holding_time<400) then
			if(not event.shift_pressed and not event.alt_pressed and result.block_id and result.block_id>0) then
				-- if it is a right click, first try the game logics if it is processed. such as an action neuron block.
				if(result.entity and result.entity:IsBlockEntity() and result.entity:GetBlockId() == result.block_id) then
					-- this fixed a bug where block entity is larger than the block like the physics block model.
					local bx, by, bz = result.entity:GetBlockPos();
					isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, bx, by, bz, event.mouse_button, EntityManager.GetPlayer(), result.side);
				else
					isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, result.blockX, result.blockY, result.blockZ, event.mouse_button, EntityManager.GetPlayer(), result.side);
				end
				
			end
		end
	end
	if(not isProcessed and click_data.right_holding_time<400) then
		local player = EntityManager.GetPlayer();
		if(player) then
			local itemStack = player.inventory:GetItemInRightHand();
			if(itemStack) then
				local newStack, hasHandled = itemStack:OnItemRightClick(player);
				if(hasHandled) then
					isProcessed = hasHandled;
				end
			end
		end
	end
	if(not isProcessed and click_data.right_holding_time<400 and result and result.blockX) then
		if(GameMode:CanRightClickToCreateBlock()) then
			self:OnCreateBlock(result);
		end
	end
end

-- virtual: undo/redo related key events, such as ctrl+Z/Y
-- return true if processed
function BaseContext:handleHistoryKeyEvent(event)
end

-- virtual function: handle player controller key event
-- return true if processed
function BaseContext:handlePlayerKeyEvent(event)
	local dik_key = event.keyname;
	if(event.ctrl_pressed and event.alt_pressed) then
		if(event.virtual_key == Event_Mapping.EM_KEY_PAGE_UP) then
			local last_value = ParaCamera.GetAttributeObject():GetField("LookAtShiftY", 0);
			ParaCamera.GetAttributeObject():SetField("LookAtShiftY", last_value+0.03);
		elseif(event.virtual_key == Event_Mapping.EM_KEY_PAGE_DOWN) then
			local last_value = ParaCamera.GetAttributeObject():GetField("LookAtShiftY", 0);
			ParaCamera.GetAttributeObject():SetField("LookAtShiftY", last_value-0.03);
		end
		event:accept();
	elseif(not event.ctrl_pressed and not event.alt_pressed) then
		if(dik_key == "DIK_SPACE") then
			GameLogic.DoJump();
			event:accept();
		elseif(dik_key == "DIK_F") then
			-- fly mode
			if(GameMode:CanFly()) then
				GameLogic.ToggleFly();
			else
				NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
				local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
				local generatorName = WorldCommon.GetWorldTag("world_generator");
				if (generatorName == "paraworld") then
					GameLogic.GetFilters():apply_filters("VipNotice", true, "fly_on_paraworld",function()
						local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
						if (KeepWorkItemManager.IsVip()) then
							GameLogic.options:SetCanJumpInAir(true);
						end
					end);
				else
					_guihelper.MessageBox(L"此世界禁止飞行哦！");
				end
			end
			event:accept();
		elseif(dik_key == "DIK_B") then
			if(System.options.mc) then
				GameLogic.ToggleDesktop("bag");
				event:accept();
			end
		elseif(dik_key == "DIK_W") then
			GameLogic.WalkForward();
			event:accept();
		elseif(dik_key == "DIK_E") then
			GameLogic.ToggleDesktop("builder");
			event:accept();
		elseif(dik_key == "DIK_Q") then
			GameLogic.GetPlayerController():ThrowBlockInHand();
			event:accept();
		elseif(dik_key == "DIK_F5") then
			GameLogic.ToggleCamera();
			event:accept();
		elseif(dik_key == "DIK_X") then
			GameLogic.TalkToNearestNPC();
			event:accept();
		elseif(dik_key == "DIK_R") then
			local KeepWorkMallPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallPage.lua");
			local MovieClipController = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipController");
			if not MovieClipController.IsVisible() then
				if KeepWorkMallPage.isOpen then
					KeepWorkMallPage.Close()
				else
					KeepWorkMallPage.Show();
				end
				event:accept();
			end
		end
	elseif(self:HandleQuickSelectKey(event)) then
		-- quick select key
	end
	return event:isAccepted();
end

-- deactivate this context and switch back to default scene context with the current game mode. 
function BaseContext:close()
	return GameLogic.ActivateDefaultContext();
end

-- handle all global key events that should always be available to the user regardless of whatever scene context. 
-- return true if key is handled. 
function BaseContext:HandleGlobalKey(event)
	local dik_key = event.keyname;
	local ctrl_pressed = event.ctrl_pressed;
	if(System.options.isAB_SDK or System.options.mc) then
		if(dik_key == "DIK_F12" and not ctrl_pressed) then
			System.App.Commands.Call("Help.Debug");
			event:accept();
		elseif(dik_key == "DIK_F3" and ctrl_pressed) then
			System.App.Commands.Call("File.MCMLBrowser");
			event:accept();
		elseif(dik_key == "DIK_F4") then
			if(ctrl_pressed) then
				System.App.Commands.Call("Help.ToggleReportAndBoundingBox");
			else
				System.App.Commands.Call("Help.ToggleWireFrame");
			end
			event:accept();
		end
		if(event:isAccepted()) then
			return true;
		end
	end
		
	
	if(GameMode:IsAllowGlobalEditorKey()) then
		if(dik_key == "DIK_TAB") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeleportPlayerTask.lua");
			local task = MyCompany.Aries.Game.Tasks.TeleportPlayer:new({mode="vertical", isUpward = not event.shift_pressed, add_to_history=false});
			task:Run();
			event:accept();
		elseif(dik_key == "DIK_F3") then
			if(event.shift_pressed) then
				NPL.load("(gl)script/ide/GUI_inspector_simple.lua");
				-- call this function at any time to inspect UI at the current mouse position
				CommonCtrl.GUI_inspector_simple.InspectUI(); 
			else
				if(not ctrl_pressed) then
					CommandManager:RunCommand("/show info");
				end
			end
			event:accept();
		elseif(dik_key == "DIK_F11") then
			CommandManager:RunCommand("/open npl://console");
			event:accept();
		elseif(ctrl_pressed and dik_key == "DIK_P") then
			CommandManager:RunCommand("/stop");
			event:accept();
		else
			-- ctrl + Keys
			if(ctrl_pressed) then
				if(dik_key == "DIK_T") then
					NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/InfoWindow.lua");
					local InfoWindow = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.InfoWindow");
					InfoWindow.CopyToClipboard("mousepos")
					event:accept();
				elseif(dik_key == "DIK_R") then
					NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/InfoWindow.lua");
					local InfoWindow = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.InfoWindow");
					InfoWindow.CopyToClipboard("relativemousepos")
					event:accept();
				elseif(dik_key == "DIK_D") then
					-- toggle selection
					NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
					local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
					SelectBlocks.ToggleLastInstance();
					event:accept();
				elseif(dik_key == "DIK_M") then
					-- show module manager
					GameLogic.RunCommand("/show mod");
					event:accept();
				elseif(dik_key == "DIK_O") then
					-- show module manager
					GameLogic.RunCommand("/menu file.loadworld");
					event:accept();
				elseif(dik_key == "DIK_N") then
					-- show module manager
					GameLogic.RunCommand("/menu file.createworld");
					event:accept();
				elseif(dik_key == "DIK_F") then
					-- find block 
					if(event.shift_pressed) then
						GameLogic.RunCommand("/findfile");
					else
						GameLogic.RunCommand("/menu window.find");
					end
					event:accept();
				elseif(dik_key == "DIK_C") then
					-- copy current mouse cursor block to clipboard
					NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
					local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
					SelectBlocks.CopyToClipboard();
					event:accept();
				elseif(dik_key == "DIK_V") then
					-- paste from clipboard
					NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
					local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
					SelectBlocks.PasteFromClipboard();
					event:accept();
				end
			end
		end
	end
	
	if(dik_key == "DIK_F9") then
		CommandManager:RunCommand("record");
		event:accept();
	elseif(dik_key == "DIK_RETURN") then
		if not GameLogic.GetFilters():apply_filters("HandleGlobalKeyByRETURN") then
			if(GameLogic.GameMode:CanChat()) then
				--System.App.Commands.Call(System.App.Commands.GetDefaultCommand("EnterChat"));
				NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatWindow.lua");
				MyCompany.Aries.ChatSystem.ChatWindow.ShowAllPage(true);
				event:accept();
			end
		end
	elseif(dik_key == "DIK_SLASH") then
		if not GameLogic.GetFilters():apply_filters("HandleGlobalKeyBySLASH") then
			if(GameLogic.GameMode:CanChat()) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatWindow.lua");
				MyCompany.Aries.ChatSystem.ChatWindow.ShowAllPage(true);
				MyCompany.Aries.ChatSystem.ChatEdit.SetText("/");
				event:accept();
			end
		end
	elseif(dik_key == "DIK_GRAVE") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/World/CameraController.lua");
		local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
		CameraController.ToggleFov(GameLogic.options.inspector_fov);
		event:accept();
	elseif(event.ctrl_pressed and (dik_key == "DIK_F6" or dik_key == "DIK_G")) then
		GameLogic.ToggleGameMode();
		event:accept();
	elseif(dik_key == "DIK_ESCAPE") then
		-- handle escape key
		self:HandleEscapeKey();
		event:accept();
	elseif(dik_key == "DIK_LWIN") then
		-- the menu key on andriod. 
		if(System.options.IsMobilePlatform and ParaScene.IsSceneEnabled()) then
			GameLogic.ToggleDesktop("esc");
		end
	elseif(dik_key == "DIK_S" and ctrl_pressed) then
		event:accept();
		GameLogic.RunCommand("/save");
		
	elseif(dik_key == "DIK_F12" and ctrl_pressed) then
		System.App.Commands.Call("ScreenShot.HideAllUI");
	elseif(dik_key == "DIK_I" and ctrl_pressed and event.shift_pressed) then
		GameLogic.RunCommand("/open npl://debugger");
	elseif(dik_key == "DIK_F1") then
		GameLogic.RunCommand("/menu help.help");
	end

	if (ctrl_pressed and event.alt_pressed) then
		if (dik_key == "DIK_1") then
			CommandManager:RunCommand("share", "10");
			event:accept();
		elseif (dik_key == "DIK_3") then
			CommandManager:RunCommand("share", "30");
			event:accept();
		end
	end
	return event:isAccepted();
end
