--[[
Title: Edit Movie Context
Author(s): LiXizhi
Date: 2015/8/9
Desc: When a movie block is activated or opened, we will be entering this context. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/EditMovieContext.lua");
local EditMovieContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.EditMovieContext");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/BaseContext.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieUISound.lua");
local MovieClipController = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipController");
local MovieUISound = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieUISound");
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local BaseContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.BaseContext");
local EditMovieContext = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.SceneContext.EditContext"), commonlib.gettable("MyCompany.Aries.Game.SceneContext.EditMovieContext"));

EditMovieContext:Property("Name", "EditMovieContext");
EditMovieContext:Property({"ReadOnlyMode", false, "IsReadOnlyMode", "SetReadOnlyMode", auto=true});
-- following property is used by GameMode 
EditMovieContext:Property({"ModeShouldHideTouchController", nil, "GetModeShouldHideTouchController", });
EditMovieContext:Property({"ModeCanSelect", nil, "GetModeCanSelect", });
EditMovieContext:Property({"ModeCanRightClickToCreateBlock", nil, "GetModeCanRightClickToCreateBlock", });
EditMovieContext:Property({"ModeHasJumpRestriction", true});


function EditMovieContext:ctor()
end

function EditMovieContext:GetModeShouldHideTouchController()
	local movieClip = MovieManager:GetActiveMovieClip()
	if(movieClip) then
		return movieClip:IsPlayingMode();
	else
		return true;
	end
end

function EditMovieContext:GetModeCanSelect()
	local movieClip = MovieManager:GetActiveMovieClip()
	if(movieClip) then
		return (not movieClip:IsPlayingMode() and MovieManager:IsLastModeEditor() and not MovieManager:IsCapturing());
	end
end

function EditMovieContext:GetModeCanRightClickToCreateBlock()
	local actor = MovieClipController.GetMovieActor()
	if(actor and not actor:CanCreateBlocks()) then
		return false;
	else
		return true;
	end
end

-- virtual function: 
-- try to select this context. 
function EditMovieContext:OnSelect()
	self:SetReadOnlyMode(not MovieManager:IsLastModeEditor());
	self:EnableAutoCamera(not self:IsReadOnlyMode());
	-- initialize manipulators and actors
	self:OnSelectedActorChange();
	SelectionManager:Connect("selectedActorChanged", self, self.OnSelectedActorChange);
	SelectionManager:Connect("selectedActorVariableChanged", self, self.OnSelectedActorVariableChange);
	BaseContext.OnSelect(self);
	self:EnableMousePickTimer(true);
	MovieClipController:Connect("afterActorFocusChanged", self, self.OnAfterActorFocusChanged, "UniqueConnection");
end

-- virtual function: 
-- return true if we are not in the middle of any operation and fire unselected signal. 
-- or false, if we can not unselect the scene tool context at the moment. 
function EditMovieContext:OnUnselect()
	EditMovieContext._super.OnUnselect(self);
	SelectionManager:Disconnect("selectedActorChanged", self, self.OnSelectedActorChange);
	SelectionManager:Disconnect("selectedActorVariableChanged", self, self.OnSelectedActorVariableChange);
	self:SetActorAt("cur_actor", nil);
	GameLogic.AddBBS("EditMovieContext", nil);
	self:SetUseFreeCamera(false);
	MovieClipController:Disconnect("afterActorFocusChanged", self, self.OnAfterActorFocusChanged);
	return true;
end

function EditMovieContext:OnSelectedActorChange(actor)
	local actor = SelectionManager:GetSelectedActor();
	self:SetActorAt("cur_actor", actor);
	self:updateManipulators();
end

function EditMovieContext:OnSelectedActorVariableChange(variable, actor)
	if(actor and actor.class_name == "ActorCommands" and variable and (variable.name=="blocks" or variable.name=="movieblock")) then
		self:SetAllowEditMode(true);
	else
		self:SetAllowEditMode(false);
	end
end

function EditMovieContext:IsAllowEditMode()
	return self.is_allow_edit_mode_;
end

function EditMovieContext:SetAllowEditMode(bAllow)
	self.is_allow_edit_mode_ = bAllow;
end

local channels = {"cur_actor", }
function EditMovieContext:HasActor(actor)
	return actor and (self:GetActorAt(channels[1]) == actor);
end

-- get actor at given channel
function EditMovieContext:GetActorAt(channel_name)
	return self[channel_name];
end

function EditMovieContext:GetActor()
	local actor = self:GetActorAt("cur_actor");
	if(actor and not actor.wasDeleted) then
		return actor;
	end
end

-- set actor that is being watched (edited). 
-- @param channel_name: "cur_actor", "sub_actor"
function EditMovieContext:SetActorAt(channel_name, actor)
	local oldActor = self:GetActorAt(channel_name);
	if(oldActor ~= actor) then
		self[channel_name] = nil;
		if(oldActor and not self:HasActor(oldActor)) then
			oldActor:Disconnect("currentEditVariableChanged", self, self.updateManipulators);
		end
		if(actor and not self:HasActor(actor)) then
			actor:Connect("currentEditVariableChanged", self, self.updateManipulators);
		end
		self[channel_name] = actor;
	end
end

function EditMovieContext:updateManipulators()
	self:DeleteManipulators();
	GameLogic.AddBBS("EditMovieContext", nil);

	if(self:IsReadOnlyMode()) then
		return;
	end

	local bUseFreeCamera = false;
	local bRestoreLastActorFreeCameraPos;
	local actor = SelectionManager:GetSelectedActor();
	if(actor) then
		local var = actor:GetEditableVariable();
		if(var) then
			self:SetAllowEditMode(false);
			if(var.name == "pos") then
				NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/Manipulators/MoveManipContainer.lua");
				local MoveManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.MoveManipContainer");
				local manipCont = MoveManipContainer:new();
				manipCont:SetShowGrid(true);
				manipCont:SetSnapToGrid(false);
				manipCont:SetGridSize(BlockEngine.blocksize/2);
				manipCont:init();
				self:AddManipulator(manipCont);
				manipCont:connectToDependNode(actor);
				GameLogic.AddBBS("EditMovieContext", L"移动: 拖动箭头移动位置, 中键可瞬移", 10000);
				bUseFreeCamera = true;
			elseif(var.name == "facing") then
				NPL.load("(gl)script/ide/System/Scene/Manipulators/RotateManipContainer.lua");
				local RotateManipContainer = commonlib.gettable("System.Scene.Manipulators.RotateManipContainer");
				local manipCont = RotateManipContainer:new();
				manipCont:init();
				--manipCont:SetShowLastAngles(true);
				manipCont:SetYawPlugName("facing");
				manipCont:SetYawEnabled(true);
				manipCont:SetPitchEnabled(false);
				manipCont:SetRollEnabled(false);
				self:AddManipulator(manipCont);
				manipCont:connectToDependNode(actor);
				GameLogic.AddBBS("EditMovieContext", L"Yaw旋转", 10000);
				bUseFreeCamera = true;
			elseif(var.name == "rot") then
				NPL.load("(gl)script/ide/System/Scene/Manipulators/RotateManipContainer.lua");
				local RotateManipContainer = commonlib.gettable("System.Scene.Manipulators.RotateManipContainer");
				local manipCont = RotateManipContainer:new();
				manipCont:init();
				--manipCont:SetShowLastAngles(true);
				manipCont:SetYawPlugName("facing");
				manipCont:SetRollPlugName("roll");
				manipCont:SetPitchPlugName("pitch");
				self:AddManipulator(manipCont);
				manipCont:connectToDependNode(actor);
				GameLogic.AddBBS("EditMovieContext", L"3轴旋转", 10000);
				bUseFreeCamera = true;
			elseif(var.name == "head") then
				NPL.load("(gl)script/ide/System/Scene/Manipulators/RotateManipContainer.lua");
				local RotateManipContainer = commonlib.gettable("System.Scene.Manipulators.RotateManipContainer");
				local manipCont = RotateManipContainer:new();
				manipCont:init();
				-- manipCont:SetShowLastAngles(true);
				manipCont:SetYawPlugName("HeadTurningAngle");
				manipCont:SetYawEnabled(true);
				manipCont:SetPitchPlugName("HeadUpdownAngle");
				manipCont:SetPitchEnabled(true);
				manipCont:SetPitchInverted(true);
				manipCont:SetRollEnabled(false);
				self:AddManipulator(manipCont);
				manipCont:connectToDependNode(actor);
				GameLogic.AddBBS("EditMovieContext", L"头部旋转", 10000);
				bUseFreeCamera = true;
			elseif(var.name == "scaling" or var.name == "eye_dist") then
				NPL.load("(gl)script/ide/System/Scene/Manipulators/ScaleManipContainer.lua");
				local ScaleManipContainer = commonlib.gettable("System.Scene.Manipulators.ScaleManipContainer");
				local manipCont = ScaleManipContainer:new();
				manipCont:init();
				self:AddManipulator(manipCont);
				manipCont:connectToDependNode(actor);
				GameLogic.AddBBS("EditMovieContext", L"放缩", 10000);
				bUseFreeCamera = true;
			elseif(var.name == "bones") then
				NPL.load("(gl)script/ide/System/Scene/Manipulators/BonesManipContainer.lua");
				local BonesManipContainer = commonlib.gettable("System.Scene.Manipulators.BonesManipContainer");
				local manipCont = BonesManipContainer:new();
				manipCont:init();
				self:AddManipulator(manipCont);
				-- this should be connected before connectToDependNode to ensure signal be sent during initialization.
				manipCont:Connect("varNameChanged", SelectionManager, SelectionManager.varNameChanged);
				manipCont:connectToDependNode(actor);
				manipCont:Connect("beforeDestroyed", actor, actor.SaveFreeCameraPosition);
				manipCont:Connect("keyAdded", self, self.OnBoneKeyAdded);
				manipCont:Connect("boneChanged", self, self.OnBoneChanged);
				bUseFreeCamera = true;
				bRestoreLastActorFreeCameraPos = true;
				self:OnBoneChanged(nil);
			elseif(var.name == "parent") then
				NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/Manipulators/ParentLinkManipContainer.lua");
				local ParentLinkManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.ParentLinkManipContainer");
				local manipCont = ParentLinkManipContainer:new();
				manipCont:init();
				self:AddManipulator(manipCont);
				manipCont:connectToDependNode(actor);
				bUseFreeCamera = true;
			end
		end
		-- add selected actor's entity AABB display in all cases
		local entity = actor:GetEntity();
		if(entity and actor:CanShowSelectManip()) then
			if(bUseFreeCamera and entity:isa(EntityManager.EntityCamera)) then
				bUseFreeCamera = false;
			end
			NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/Manipulators/ActorSelectManipContainer.lua");
			local ActorSelectManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.ActorSelectManipContainer");
			local manipCont = ActorSelectManipContainer:new();
			manipCont:init();
			self:AddManipulator(manipCont);
			manipCont:connectToDependNode(entity);
		end
	end

	
	if(bUseFreeCamera) then
		-- always lock actors when free camera is used. 
		self:ToggleLockAllActors(true);
	end
	self:SetUseFreeCamera(bUseFreeCamera);
	self:SetRestoreActorFreeCameraPos(bRestoreLastActorFreeCameraPos);
end

local tip_count = 0;
function EditMovieContext:OnBoneChanged(name)
	local actor = self:GetActor();	
	if(actor) then
		if(name) then
			local selName = format("%s::bones::%s", actor:GetDisplayName(), name);
			actor:GetMovieClipEntity():SetLastSelectionName(selName);
		end
	end
	if(tip_count < 2) then
		if(name and name~="") then
			GameLogic.AddBBS("EditMovieContext", L"2,3,4键切换编辑工具;双击2键位置", 10000);
			tip_count = tip_count + 1;
		else
			GameLogic.AddBBS("EditMovieContext", L"左键选择骨骼, ESC取消选择, -/+遍历选择", 10000);
		end
	else
		GameLogic.AddBBS("EditMovieContext", nil);
	end
end

function EditMovieContext:OnBoneKeyAdded()
	-- play a sound when it is adding key, instead of modifying key
	MovieUISound.PlayAddKey();
end

function EditMovieContext:OnFreeCameraFocusLost()
	if(self.m_bSaveActorFreeCameraPos) then
		local actor = self:GetActor();	
		if(actor) then
			actor:SaveFreeCameraPosition(true);
		end
	end
end

-- whether to use a free camera rather than a actor focused camera. 
function EditMovieContext:SetUseFreeCamera(bUseFreeCamera)
	local cameraEntity = GameLogic.GetFreeCamera();

	local actor = self:GetActor();

	if(bUseFreeCamera) then
		if(cameraEntity ~= EntityManager.GetFocus()) then
			if(actor) then
				local x, y, z = actor:GetPosition();
				if(x and y and z) then
					cameraEntity:SetPosition(x, y, z);
					cameraEntity:SetFocus();
				end
			end
		end
		cameraEntity:ShowCameraModel();
		cameraEntity:SetTarget(actor);
	else
		cameraEntity:SetTarget(nil);
		if(cameraEntity == EntityManager.GetFocus()) then
			if(actor) then
				actor:SetFocus();
			else
				EntityManager.GetPlayer():SetFocus();
			end
		end
		cameraEntity:HideCameraModel();
	end
	
	if(not bUseFreeCamera) then
		self.m_bSaveActorFreeCameraPos = false;
		cameraEntity:Disconnect("focusOut", self, self.OnFreeCameraFocusLost);
	end
end

-- @param bRestoreLastActorFreeCameraPos: if true, restore last actor free camera pos, and also hook focusOut event
-- to save free camera position. 
function EditMovieContext:SetRestoreActorFreeCameraPos(bRestoreLastActorFreeCameraPos)
	local cameraEntity = GameLogic.GetFreeCamera();
	local actor = self:GetActor();
	if(bRestoreLastActorFreeCameraPos) then
		self.m_bSaveActorFreeCameraPos = true;
		actor:RestoreLastFreeCameraPosition();
		cameraEntity:Connect("focusOut", self, self.OnFreeCameraFocusLost, "UniqueConnection");
	else
		self.m_bSaveActorFreeCameraPos = false;
		cameraEntity:Disconnect("focusOut", self, self.OnFreeCameraFocusLost);
	end
end

function EditMovieContext:OnAfterActorFocusChanged()
	local cameraEntity = GameLogic.GetFreeCamera();
	if(cameraEntity and not cameraEntity:IsCameraHidden() and cameraEntity:GetTarget() == self:GetActor()) then
		self:SetUseFreeCamera(true);
	end
end

-- usually when k key is pressed
function EditMovieContext:AddKeyFrame()
	local movieclip = MovieManager:GetActiveMovieClip();
	if(movieclip and not movieclip:IsPlayingMode()) then
		local actor = SelectionManager:GetSelectedActor();
		if(actor and movieclip:IsPaused()) then
			if(not actor:IsAllowUserControl()) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipTimeLine.lua");
				local MovieClipTimeLine = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipTimeLine");
				MovieClipTimeLine.OnClickAddSubFrameKey();
			else
				MovieClipController.OnAddKeyFrame();
			end
			return true
		end
	end	
end

-- @param block: if nil, means toggle
function EditMovieContext:ToggleLockAllActors(block)
	local movieclip = MovieManager:GetActiveMovieClip();
	if(movieclip and not movieclip:IsPlayingMode()) then
		if(movieclip:IsPaused()) then
			MovieClipController.ToggleLockAllActors(block);
		end
		return true;
	end
end

function EditMovieContext:HandleGlobalKey(event)
	local dik_key = event.keyname;
	local actor = SelectionManager:GetSelectedActor();
	local player = EntityManager.GetFocus();
	if(actor and player) then
		if(player:IsControlledExternally()) then
			if(dik_key == "DIK_W" or dik_key == "DIK_A" or dik_key == "DIK_D" or dik_key == "DIK_S" or dik_key == "DIK_SPACE") then
				GameLogic.AddBBS("lock", L"人物在锁定模式不可运动(L键可解锁)", 4000, "#808080");
				event:accept();
				return true;
			end
		end
		if(dik_key == "DIK_1") then
			-- switch between bones and animations. 
			-- select first variable (default one).
			if(actor:GetCurrentEditVariableIndex() ~= 1) then
				actor:SetCurrentEditVariableIndex(1);
			else
				-- bones tools
				local index = actor:FindEditVariableByName("bones");
				if(index and index~=actor:GetCurrentEditVariableIndex()) then
					actor:SetCurrentEditVariableIndex(index);
				else
					actor:SetCurrentEditVariableIndex(1);
				end	
			end
			event:accept();
		elseif(dik_key == "DIK_2") then
			-- move tool
			local index = actor:FindEditVariableByName("pos");
			if(index) then
				actor:SetCurrentEditVariableIndex(index);
			end
			event:accept();
		elseif(dik_key == "DIK_3") then
			-- switch between rotate and facing
			local index = actor:FindEditVariableByName("facing");
			if(actor:GetCurrentEditVariableIndex() == index or not index) then
				index = actor:FindEditVariableByName("rot");
			end
			if(index) then
				actor:SetCurrentEditVariableIndex(index);
			end
			event:accept();
		elseif(dik_key == "DIK_4") then
			--  scale
			local index = actor:FindEditVariableByName("scaling");
			if(index) then
				actor:SetCurrentEditVariableIndex(index);
			end
			event:accept();
		end
	end
	if(dik_key == "DIK_K") then
		if(self:AddKeyFrame()) then
			event:accept();
		end
	elseif(dik_key == "DIK_L") then
		if(self:ToggleLockAllActors()) then
			event:accept();
		end
	elseif(dik_key == "DIK_R") then
		if(not event.ctrl_pressed) then
			if(MovieClipController.OnRecordKeyPressed()) then
				event:accept();
			end
		end
	elseif(dik_key == "DIK_P") then
		local movieclip = MovieManager:GetActiveMovieClip();
		if(movieclip) then
			if(event.ctrl_pressed) then
				movieclip:Stop();
				MovieManager:SetActiveMovieClip(nil);
			else
				if(not movieclip:IsPaused()) then
					movieclip:Pause();
				else
					movieclip:Resume();
				end
			end
			event:accept();
		end
	end

	if(not event:isAccepted()) then
		return EditMovieContext._super.HandleGlobalKey(self, event);
	end

	return event:isAccepted();
end

-- virtual: 
function EditMovieContext:mousePressEvent(event)
	if(self:IsReadOnlyMode()) then
		return
	end
	BaseContext.mousePressEvent(self, event);
	if(event:isAccepted()) then
		return
	end
end

-- virtual: 
function EditMovieContext:mouseMoveEvent(event)
	if(self:IsReadOnlyMode()) then
		return
	end
	BaseContext.mouseMoveEvent(self, event);
	if(event:isAccepted()) then
		return
	end
end

function EditMovieContext:HighlightPickBlock(result)
	if(self:HasManipulators() and not self:IsInSelectMode() and not self:IsAllowEditMode()) then
		-- we will only highlight movie block
		if(result.block_id == block_types.names.MovieClip) then
			EditMovieContext._super.HighlightPickBlock(self, result);
		else
			self:ClearBlockPickDisplay();
		end
	else
		EditMovieContext._super.HighlightPickBlock(self, result);
	end
end

function EditMovieContext:HighlightPickEntity(result)
	local bSelectNew;
	if(not result.block_id and result.entity and result.obj) then
		local actor = self:GetActor();
		if(actor and actor:GetEntity()== result.entity) then
			result.entity = nil;
			result.obj = nil;
		else
			bSelectNew = true;
		end
	end

	local click_data = self:GetClickData();
	if(bSelectNew) then
		click_data.last_select_entity = result.entity;
		ParaSelection.AddObject(result.obj, 1);
	elseif(click_data.last_select_entity) then
		click_data.last_select_entity = nil;
		ParaSelection.ClearGroup(1);
	end
end

-- whether actor is in recording mode. 
function EditMovieContext:IsActorRecording()
	local actor = self:GetActor();
	if(actor and actor:IsRecording()) then
		return true;
	end
end

function EditMovieContext:mouseReleaseEvent(event)
	if(self:IsReadOnlyMode()) then
		return
	end
	BaseContext.mouseReleaseEvent(self, event);
	if(event:isAccepted()) then
		return
	end

	if(self.is_click) then
		
		local result = self:CheckMousePick();
		local isClickProcessed;
		
		-- escape alt key for entity event, since alt key is for picking entity. 
		if( not event.alt_pressed and result and result.obj and result.entity and (not result.block_id or result.block_id == 0)) then
			-- click to select actor if any
			local movieClip = MovieManager:GetActiveMovieClip();
			if(movieClip) then
				local actor = movieClip:GetActorByEntity(result.entity);
				if(actor) then
					if(not result.entity:HasFocus()) then
						actor:OpenEditor();
						isClickProcessed = true;
					end
				end
			end

			if(self:HasManipulators() and not self:IsActorRecording()) then
				return;
			end

			if(not isClickProcessed) then
				isClickProcessed = GameLogic.GetPlayerController():OnClickEntity(result.entity, result.blockX, result.blockY, result.blockZ, event.mouse_button);
			end
		end

		if(self:HasManipulators() and not self:IsActorRecording() and not self:IsInSelectMode() and not self:IsAllowEditMode()) then
			return;
		end

		if(isClickProcessed) then	
			-- do nothing
		elseif(event.mouse_button == "left") then
			self:handleLeftClickScene(event, result);
		elseif(event.mouse_button == "right") then
			self:handleRightClickScene(event, result);
		elseif(event.mouse_button == "middle") then
			self:handleMiddleClickScene(event, result);
		end
	end
end

function EditMovieContext:handleLeftClickScene(event, result)
	EditMovieContext._super.handleLeftClickScene(self, event, result);
	if(event:isAccepted()) then
		return
	end
end

-- virtual: 
function EditMovieContext:mouseWheelEvent(event)
	if(event.shift_pressed or self:IsActorRecording()) then
		EditMovieContext._super.mouseWheelEvent(self, event);
	else
		self:handleCameraWheelEvent(event);
	end
end

-- virtual: actually means key stroke. 
function EditMovieContext:keyPressEvent(event)
	EditMovieContext._super.keyPressEvent(self, event);
	if(event:isAccepted()) then
		return
	end
end


-- user has drag and dropped an existing file to the context
-- automatically create an actor based on the dropped file. 
-- @param fileType: "model", "blocktemplate"
function EditMovieContext:handleDropFile(filename, fileType)
	if(fileType~="model") then
		return;
	end
	local movieclip = MovieManager:GetActiveMovieClip();
	if(movieclip and not movieclip:IsPlayingMode()) then
		local itemStack = movieclip:CreateNPC();
		if(itemStack) then
			MovieClipController.SetFocusToItemStack(itemStack);
			local actor = MovieClipController.GetMovieActor();
			if(actor) then
				local entity = actor:GetEntity();
				if(entity and entity:isa(EntityManager.EntityMob)) then
					-- set new model
					entity:SetModelFile(filename);
					NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/MobPropertyPage.lua");
					local MobPropertyPage = commonlib.gettable("MyCompany.Aries.Game.GUI.MobPropertyPage");
					MobPropertyPage.ShowPage(entity, nil, function()
						actor:SaveStaticAppearance();
					end);
				end
			end
		end
	end
end