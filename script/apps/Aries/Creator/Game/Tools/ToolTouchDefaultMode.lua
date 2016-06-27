--[[
Title: touch default mode
Author(s): LiXizhi
Date: 2014/11/25
Desc: support pinch gesture, drag to rotate camera, basic scene interaction. 
gestures for selected blocks is only valid when the touch begins from one of the selected block. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/ToolTouchDefaultMode.lua");
local ToolTouchDefaultMode = commonlib.gettable("MyCompany.Aries.Game.Tools.ToolTouchDefaultMode");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/ToolTouchBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/TouchSelection.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchSession.lua");
local TouchSession = commonlib.gettable("MyCompany.Aries.Game.Common.TouchSession")
local TouchSelection = commonlib.gettable("MyCompany.Aries.Game.Tools.TouchSelection");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local Tool = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Tools.ToolTouchBase"), commonlib.gettable("MyCompany.Aries.Game.Tools.ToolTouchDefaultMode"));
Tool:Property("Name", "ToolTouchDefaultMode");
-- whether to show touch track. 
Tool:Property("ShowTouchTrack", false);
-- whether to allow selecting multiple blocks. 
Tool:Property("AllowMultiSelection", false);

-- default to 300 ms. 
Tool.min_hold_time = 300;
-- default to 30 pixels
Tool.finger_size = 30;
-- the smaller, the smoother. value between (0,1]. 1 is without smoothing. 
Tool.camera_smoothness = 0.4;

function Tool:ctor()
	self:LoadGestures();
end

function Tool:OnSelect()
	Tool._super.OnSelect(self);
	self.camera_start = nil;
end

function Tool:OnDeselect()
	Tool._super.OnDeselect(self);
	self.camera_start = nil;
end

function Tool:LoadGestures()
	-- register pinch gesture
	NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchGesturePinch.lua");
	local TouchGesturePinch = commonlib.gettable("MyCompany.Aries.Game.Common.TouchGesturePinch")
	local gesture_pinch = TouchGesturePinch:new({OnGestureRecognized = function(pinch_gesture)
		if(not GameLogic.IsFPSView) then
			-- only for third person view
			if(math.abs(pinch_gesture:GetDeltaDistance()) > 20) then
				-- zoom in/out one step every 20 pixels
				pinch_gesture:ResetLastDistance();
				NPL.load("(gl)script/apps/Aries/Creator/Game/World/CameraController.lua");
				local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
				if(pinch_gesture:GetPinchMode() == "open") then
					CameraController.ZoomInOut(true);
				else
					CameraController.ZoomInOut(false);
				end
			end
			return true;
		end
	end});
	self:RegisterGestureRecognizer(gesture_pinch);
	-- TODO: register other gestures here
end

function Tool:handleTouchSessionDown(touch_session, touch)
	Tool._super.handleTouchSessionDown(self, touch_session, touch);

	self.camera_start = touch_session;
	if(self:IsTouchedBlockSelected(touch_session)) then
		touch_session.IsTouchOnSelection = true;
	else
		touch_session.IsTouchOnSelection = false;
		self:RotateCamera();
	end
end

-- rotate camera 
function Tool:handleTouchSessionMove(touch_session, touch)
	Tool._super.handleTouchSessionMove(self, touch_session, touch);
	
	if(self.camera_start == touch_session and not touch_session.IsTouchOnSelection) then
		self:RotateCamera(touch_session);
	end
end

-- rotate the camera based on delta in the touch_session. 
function Tool:RotateCamera(touch_session)
	if(touch_session and self.liftup and self.rot_y) then
		local InvertMouse = GameLogic.options:GetInvertMouse();
		-- the bigger, the more precision. 
		local camera_sensitivity = GameLogic.options:GetSensitivity()*1000+10;
		local delta_x, delta_y = touch_session:GetOffsetFromStartLocation();
		
		if(delta_x~=0) then
			self.targetCameraYaw = self.rot_y - (delta_x) / camera_sensitivity * if_else(InvertMouse, 1, -1);
		end
		if(delta_y~=0) then
			local liftup = self.liftup - delta_y / camera_sensitivity * if_else(InvertMouse, 1, -1);
			self.targetCameraPitch = math.max(-1.57, math.min(liftup, 1.57));
		end
	else
		local att = ParaCamera.GetAttributeObject();
		self.rot_y = att:GetField("CameraRotY", 0);
		self.preCameraYaw = self.rot_y;
		self.liftup = att:GetField("CameraLiftupAngle", 0);
		self.preCameraPitch = self.liftup;
		self.camera_timer = self.camera_timer or commonlib.Timer:new({callbackFunc = function(timer)
			self:OnTickCamera(timer);
		end})
		self.camera_timer:Change(0.0166, 0.0166);
	end
end

function Tool:OnTickCamera(timer)
	local bCameraReached = true;
	if(self.preCameraYaw ~= self.targetCameraYaw and self.preCameraYaw and self.targetCameraYaw) then
		-- smoothing
		self.cameraYaw = self.preCameraYaw + (self.targetCameraYaw - self.preCameraYaw) * self.camera_smoothness;
		if(math.abs(self.targetCameraYaw - self.cameraYaw) < 0.001) then
			self.cameraYaw = self.targetCameraYaw;
		else
			bCameraReached = false;
		end
		local att = ParaCamera.GetAttributeObject();
		att:SetField("CameraRotY", self.cameraYaw);
		self.preCameraYaw = self.cameraYaw;
	end
	if(self.targetCameraPitch ~= self.preCameraPitch and self.targetCameraPitch and self.preCameraPitch) then
		-- smoothing
		self.cameraPitch = self.preCameraPitch + (self.targetCameraPitch - self.preCameraPitch) * self.camera_smoothness;
		if(math.abs(self.targetCameraPitch - self.cameraPitch) < 0.001) then
			self.cameraPitch = self.targetCameraPitch;
		else
			bCameraReached = false;
		end
		local att = ParaCamera.GetAttributeObject();
		att:SetField("CameraLiftupAngle", self.cameraPitch);
		self.preCameraPitch = self.cameraPitch;
	end
	if(bCameraReached and not self.camera_start) then
		timer:Change(nil);
	end
end

function Tool:handleTouchSessionUp(touch_session, touch)
	Tool._super.handleTouchSessionUp(self, touch_session, touch);
	self.camera_start = nil;
	self.liftup = nil;
	self.rot_y = nil;
	self.pre_liftup = 0;
	self.pre_rot_y = 0;
end

function Tool:handleTouchUpActionSingleBlock(touch_session, touch)
	local result = GameLogic.GetSceneContext():CheckMousePick();
	if(touch_session:IsClick()) then
		self:OnClickScene(result);
	elseif(touch_session:IsPressHold(self.min_hold_time, self.finger_size)) then
		-- long press to first try right edit box, then for delete block
		local isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, result.blockX, result.blockY, result.blockZ, "right", EntityManager.GetPlayer(), result.side);	
		if(not isProcessed) then
			self:TryDestoryBlock(result)
		end
	end
end

function Tool:OnClickScene(result)
	-- click to trigger default interaction logics. 
	-- first try the game logics if it is processed. such as a button
	local isProcessed;
	if(result) then
		isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, result.blockX, result.blockY, result.blockZ, "left", EntityManager.GetPlayer(), result.side);	
	end
	if(not isProcessed) then
		-- click to open a book or use the item in hand
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
	if(not isProcessed and result and result.blockX) then
		-- create the block at the given position. 
		if(GameLogic.GameMode:CanRightClickToCreateBlock()) then
			self:ScheduleFunctionCall(66, nil,	function()
				GameLogic.GetSceneContext():OnCreateBlock(result);
			end);
		end
	end
end

function Tool:TryDestoryBlock(result)
	if(result and result.blockX) then
		GameLogic.GetSceneContext():TryDestroyBlock(result);
	end
end

function Tool:handleTouchUpActionEntity(touch_session, touch)
	local isClickProcessed;
	local result = GameLogic.GetSceneContext():CheckMousePick();
	if(result.entity and result.blockX) then
		if(touch_session:IsPressHold()) then
			isClickProcessed = GameLogic.GetPlayerController():OnClickEntity(result.entity, result.blockX, result.blockY, result.blockZ, "right");
		elseif(touch_session:IsClick()) then
			isClickProcessed = GameLogic.GetPlayerController():OnClickEntity(result.entity, result.blockX, result.blockY, result.blockZ, "left");
		end
	end
	return isClickProcessed;
end


-- whether the first block in touch_session is currently selected. 
function Tool:IsTouchedBlockSelected(touch_session)
	if(TouchSelection:GetSelectionCount() >= 1 ) then
		local blocks = touch_session:GetBlocks();
		if(#blocks >= 1) then
			local curSelBlock = blocks[1];
			for i, curTouchBlock in ipairs(TouchSelection:GetCurSelection()) do
				if(curSelBlock[1] == curTouchBlock[1] and curSelBlock[2] == curTouchBlock[2] and curSelBlock[3] == curTouchBlock[3]) then
					return true;
				end	
			end
		end
	end
end

-- tap (special case): if there is only a single selected block, and we tap on it, it will trigger the block editor (right click).
-- @return true if processed
function Tool:checkHandleSingleClickOnSelection(touch_session)
	TouchSelection:EditSelection();
end

function Tool:ClearAllSelections()
	ParaTerrain.DeselectAllBlock(self.groupindex_selection);
	TouchSelection:ClearAll();
	self.last_select_entity = nil;
end

-- handle all kinds of touch gestures on current selected blocks
function Tool:handleTouchUpGesture(touch_session, touch)
	if(self:GetActiveTouchCount() == 0) then
		if(touch_session:IsClick()) then
			-- tap (special case): if there is only a single selected block, and we tap on it, it will trigger the block editor (right click).
			if(self:checkHandleSingleClickOnSelection(touch_session)) then
				-- right click on a editable block, such as sign block.
			else
				-- gesture: "single tap" to deselect all selected blocks
				LOG.std(nil, "debug", "Tool", "all block selections are cleared.");
				-- TODO: add ctrl+click for AABB selection here.  Ctrl key is the middle one on the left bottom corner. 
				self:ClearAllSelections();
			end
		elseif(touch_session.IsTouchOnSelection) then
			if(GameLogic.GameMode:IsEditor()) then
				local dx, dy = touch_session:GetOffsetFromStartLocation();
				if(dy > self.default_finger_size) then
					-- gesture: single swipe downward to delete selection. 
					TouchSelection:DeleteAllBlocks();
				elseif(dy<-self.default_finger_size) then
					-- gesture: single swipe upward to extrude selection upward. 
					TouchSelection:ExtrudeSelection(0, 1, 0);
				end
			end
		end
	else
		-- TODO: multiple tap gestures
	end
end

-- virtual function: decide what kind of touches: 
-- @return: basically three kinds "gesture", "action", and "selection"
function Tool:ComputeEndingTouchType(touch_session)
	if(TouchSelection:IsEmpty()) then
		return "touch_action";
	else
		-- gestures for selected blocks is only valid when the touch begins from one of the selected block.
		return "touch_gesture";
	end
end