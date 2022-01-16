--[[
Title: EditModel Task/Command
Author(s): LiXizhi
Date: 2016/8/30
Desc: There are two modes.
- create mode: this is the default mode which uses the default scene context
- transform mode: use a special scene context
	- left click to select model in the 3d scene
	- TODO: use manipulators to scale, rotate the model
	- TODO: a timer is used to highlight all Model blocks near the player
	- TODO: support undo/redo

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelTask.lua");
local EditModelTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditModelTask");
local entity = EntityManager.EntityLiveModel:Create({bx=bx,by=by,bz=bz,});
entity:SetModelFile(filename)
entity:Attach();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local vector3d = commonlib.gettable("mathlib.vector3d");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local EditModelTask = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.EditModelTask"));

local curInstance;

-- this is always a top level task. 
EditModelTask.is_top_level = true;

function EditModelTask:ctor()
	self.position = vector3d:new(0,0,0);
	self.transformMode = false;
end

local page;
function EditModelTask.InitPage(Page)
	page = Page;
end

-- get current instance
function EditModelTask.GetInstance()
	return curInstance;
end

-- by default it is in select and create mode. 
function EditModelTask:IsTransformMode()
	return self.transformMode;	
end

-- enable transform mode
function EditModelTask:SetTransformMode(bEnable)
	bEnable	= bEnable == true or bEnable==nil;
	if(self.transformMode ~= bEnable) then
		self.transformMode = bEnable;
		if(EditModelTask.GetInstance()) then
			if(bEnable) then
				self:LoadSceneContext();
				self:GetSceneContext():setMouseTracking(true);
				self:GetSceneContext():setCaptureMouse(true);
			else
				self:SelectModel(nil);
				self:UnloadSceneContext();
			end
			self:RefreshPage();
		end
	end
end

-- static page event handler
function EditModelTask.OnClickToggleMode()
	local self = EditModelTask.GetInstance();
	self:SetTransformMode(not self:IsTransformMode());
end

function EditModelTask:RefreshPage()
	if(page) then
		page:Refresh(0.01);
	end
end

function EditModelTask:Run()
	curInstance = self;
	self.finished = false;
	if(self:IsTransformMode()) then
		self:LoadSceneContext();
		self:GetSceneContext():setMouseTracking(true);
		self:GetSceneContext():setCaptureMouse(true);
	end
	self:ShowPage();
end

function EditModelTask:OnExit()
	self:SelectModel(nil);
	self:SetFinished();
	self:UnloadSceneContext();
	self:CloseWindow();
	curInstance = nil;
end

function EditModelTask:SelectModel(entityModel)
	if(self.entityModel~=entityModel) then
		if(self.entityModel and self.entityModel.isLastSkipPicking==false) then
			self.entityModel:SetSkipPicking(false);
		end
		self.entityModel = entityModel;
		if(entityModel) then
			entityModel.isLastSkipPicking = entityModel:IsSkipPicking();
			if(not entityModel.isLastSkipPicking) then
				entityModel:SetSkipPicking(true);
			end
		end
		self:UpdateManipulators();
	end
end

function EditModelTask.GetItemID()
	local self = EditModelTask.GetInstance();
	if(self:GetSelectedModel()) then
		return self:GetSelectedModel():GetItemId()
	else
		if(self.itemInHand) then
			return self.itemInHand.id
		end
	end
end

function EditModelTask:GetSelectedModel()
	return self.entityModel;
end

function EditModelTask.OnResetModel()
	local self = EditModelTask.GetInstance();
	if(self) then
		local entity = self:GetSelectedModel();
		if(entity) then
			entity:setYaw(0);
			entity:setScale(1);
			if(entity.SetOffsetPos) then
				entity:SetOffsetPos({0,0,0});
			end
		end
	end
end

function EditModelTask:UpdateManipulators()
	self:DeleteManipulators();

	if(self.entityModel) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelManipContainer.lua");
		local EditModelManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.EditModelManipContainer");
		local manipCont = EditModelManipContainer:new();
		manipCont:init();
		self:AddManipulator(manipCont);
		manipCont:connectToDependNode(self.entityModel);

		self:RefreshPage();
	end
end

function EditModelTask:Redo()
end

function EditModelTask:Undo()
end

function EditModelTask:ShowPage()
	NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
	local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
	local viewport = ViewportManager:GetSceneViewport();
	local parent = viewport:GetUIObject(true)

	local window = self:CreateGetToolWindow();
	window:Show({
		name="EditModelTask", 
		url="script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelTask.html",
		alignment="_ctb", left=0, top=-55, width = 360, height = 64, parent = parent
	});
end

-- @param result: can be nil
function EditModelTask:PickModelAtMouse(result)
	local result = result or Game.SelectionManager:MousePickBlock(true, true, false);
	if(result.blockX) then
		local x,y,z = result.blockX,result.blockY,result.blockZ;
		local modelEntity = BlockEngine:GetBlockEntity(x,y,z) or result.entity;
		if(modelEntity and (modelEntity:isa(EntityManager.EntityBlockModel) or modelEntity:isa(EntityManager.EntityLiveModel))) then
			return modelEntity;
		end
	end
end

function EditModelTask:handleLeftClickScene(event, result)
	local modelEntity = self:PickModelAtMouse();
	if(modelEntity) then
		self:SelectModel(modelEntity);
		self:SetTransformMode(true);
	else
		self:SetTransformMode(false);
	end
	event:accept();
end

function EditModelTask:handleRightClickScene(event, result)
	local modelEntity = self:PickModelAtMouse();
	if(modelEntity) then
		local ctrl_pressed = System.Windows.Keyboard:IsCtrlKeyPressed();
		if(ctrl_pressed) then
			modelEntity:OpenEditor("entity", modelEntity);
		else
			self:SelectModel(modelEntity);
			self:SetTransformMode(true);
		end
	else
		self:SetTransformMode(false);
	end
	event:accept();
end

function EditModelTask:mouseMoveEvent(event)
	self:GetSceneContext():mouseMoveEvent(event);
end

function EditModelTask:mouseWheelEvent(event)
	self:GetSceneContext():mouseWheelEvent(event);
end

function EditModelTask:keyPressEvent(event)
	local dik_key = event.keyname;
	if(dik_key == "DIK_ADD" or dik_key == "DIK_EQUALS") then
		-- increase scale
		
	elseif(dik_key == "DIK_SUBTRACT" or dik_key == "DIK_MINUS") then
		-- decrease scale
		
	elseif(dik_key == "DIK_Z")then
		UndoManager.Undo();
	elseif(dik_key == "DIK_Y")then
		UndoManager.Redo();
	end
	self:GetSceneContext():keyPressEvent(event);
end

function EditModelTask:SetItemInHand(itemStack)
	self.itemInHand = itemStack;
end

function EditModelTask:GetModelFileInHand()
	if(self.itemInHand) then
		return self.itemInHand:GetDataField("tooltip");
	end
end

function EditModelTask:GetOnClickEventInHand()
	if(self.itemInHand) then
		return self.itemInHand:GetDataField("onclickEvent");
	end
end

function EditModelTask.OnClickChangeModelFile()
	local self = EditModelTask.GetInstance();
	if(self and self.itemInHand) then
		local item = self.itemInHand:GetItem();
		if(item and item.SelectModelFile) then
			item:SelectModelFile(self.itemInHand);
		end
	end
end

function EditModelTask:UpdateValueToPage()
	self:RefreshPage()
end

function EditModelTask:GetFacingDegree()
	local facing = 0;
	local modelEntity = self:GetSelectedModel()
	if(modelEntity) then
		facing = modelEntity:GetFacing();
	end
	return math.floor(mathlib.WrapAngleTo180(facing/math.pi*180)+0.5);
end

function EditModelTask:SetFacingDegree(degree)
	local modelEntity = self:GetSelectedModel()
	if(modelEntity and degree) then
		modelEntity:SetFacing(mathlib.ToStandardAngle(degree/180*math.pi));
	end
end

function EditModelTask.OnFacingDegreeChanged(text)
	local self = EditModelTask.GetInstance();
	if(self) then
		self:SetFacingDegree(tonumber(text));
	end
end

function EditModelTask.OnScalingChanged(text)
	local self = EditModelTask.GetInstance();
	if(self) then
		local modelEntity = self:GetSelectedModel()
		if(modelEntity and modelEntity.setScale and text) then
			local scaling = tonumber(text);
			if(scaling and scaling >= (modelEntity.minScale or 0.1) and scaling <= (modelEntity.maxScale or 10)) then
				modelEntity:setScale(scaling);
			end
		end
	end
end

function EditModelTask.OnChangeOnClickEvent(text)
	local self = EditModelTask.GetInstance();
	if(self) then
		local modelEntity = self:GetSelectedModel()
		if(modelEntity and modelEntity.SetOnClickEvent and text) then
			if(text == "") then
				text = nil
			end
			modelEntity:SetOnClickEvent(text)
		end
	end
end

function EditModelTask.OnClickTogglePhysics()
	local self = EditModelTask.GetInstance();
	if(self) then
		local modelEntity = self:GetSelectedModel()
		if(modelEntity) then
			local modelEntityNew = modelEntity:EnablePhysics(not modelEntity:HasRealPhysics())
			if(modelEntityNew ~= modelEntity and type(modelEntityNew) == "table") then
				self:SelectModel(modelEntityNew)
			end
			self:UpdateValueToPage()
		end
	end
end

function EditModelTask.GetMountPointCount()
	local self = EditModelTask.GetInstance();
	if(self) then
		local modelEntity = self:GetSelectedModel()
		if(modelEntity and modelEntity:GetMountPoints()) then
			return modelEntity:GetMountPoints():GetCount()
		end
	end
	return 0
end

function EditModelTask.OnMountPointCountChanged(text)
	local self = EditModelTask.GetInstance();
	if(self) then
		text = tonumber(text)
		local modelEntity = self:GetSelectedModel()
		if(modelEntity and modelEntity:GetMountPointsCount() ~= text) then
			if(text == 0) then
				if(modelEntity:GetMountPoints()) then
					modelEntity:GetMountPoints():Clear()
				end
			elseif(text) then
				local maxCount = 9;
				if(text > 0 and text <= maxCount) then
					modelEntity:CreateGetMountPoints():Resize(text)
				elseif(page) then
					page:SetUIValue("mountpointCount", maxCount);
				end
			end
			self:UpdateManipulators();
		end
	end
end

function EditModelTask.OnClickDeleteModel()
	local self = EditModelTask.GetInstance();
	if(self) then
		local modelEntity = self:GetSelectedModel()
		if(modelEntity) then
			self:SetTransformMode(false);
			
			if(GameLogic.GameMode:IsEditor()) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DragEntityTask.lua");
				local dragTask = MyCompany.Aries.Game.Tasks.DragEntity:new({})
				dragTask:DeleteEntity(modelEntity)
			end
			modelEntity:SetDead();
		end
	end
end


function EditModelTask.OnChangeSkin()
	local self = EditModelTask.GetInstance();
	if(self) then
		local entity = self:GetSelectedModel()
		if(entity) then
			local assetFilename = entity:GetMainAssetPath();
			local old_value = entity:GetSkin();

			if(entity.IsCustomModel and entity:IsCustomModel()) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditCCS/EditCCSTask.lua");
				local EditCCSTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditCCSTask");
				EditCCSTask:ShowPage(entity, function(ccsString)
					if(ccsString ~= old_value) then
						GameLogic.IsVip("ChangeAvatarSkin", true, function(isVip) 
							if(isVip) then
								entity:SetSkin(ccsString);
							end
						end)
					end
				end);
			elseif(entity.HasCustomGeosets and entity:HasCustomGeosets()) then
				local old_value = entity:GetSkin()
				NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/CustomSkinPage.lua");
				local CustomSkinPage = commonlib.gettable("MyCompany.Aries.Game.Movie.CustomSkinPage");
				CustomSkinPage.ShowPage(function(filename, skin)
					if (filename and skin~=old_value) then
						entity:SetSkin(skin);
					end
				end, old_value);
			else
				assetFilename = PlayerAssetFile:GetNameByFilename(assetFilename)
				NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/EditSkinPage.lua");
				local EditSkinPage = commonlib.gettable("MyCompany.Aries.Game.Movie.EditSkinPage");
				EditSkinPage.ShowPage(function(result)
					if(result and result~=old_value) then
						GameLogic.IsVip("ChangeAvatarSkin", true, function(isVip) 
							if(isVip) then
								entity:SetSkin(result);
							end
						end)
					end
				end, old_value, "", assetFilename)
			end
		end
	end
end

function EditModelTask.OnClickProperty()
	local self = EditModelTask.GetInstance();
	if(self) then
		local modelEntity = self:GetSelectedModel()
		if(modelEntity) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelProperty.lua");
			local EditModelProperty = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditModelProperty");
			EditModelProperty.ShowForEntity(modelEntity)
		end
	end
end

function EditModelTask.OnChangeModelType()
	local self = EditModelTask.GetInstance();
	if(self) then
		local modelEntity = self:GetSelectedModel()
		if(modelEntity) then
			if(self.itemInHand) then
				local oldX, oldY, oldZ = modelEntity:GetPosition();
				if(self.itemInHand.id == block_types.names.BlockModel or self.itemInHand.id == block_types.names.PhysicsModel) then
					-- TODO: convert from physical model to live model
					
				elseif(self.itemInHand.id == block_types.names.LiveModel) then
					-- TODO: convert from live model to physical model

				end
			end
		else
			-- toggle between physical and non-physical block model. 
			if(self.itemInHand) then
				local itemStack = self.itemInHand:Copy();
				if(self.itemInHand.id == block_types.names.BlockModel) then
					itemStack.id = block_types.names.PhysicsModel;
				elseif(self.itemInHand.id == block_types.names.PhysicsModel) then
					itemStack.id = block_types.names.LiveModel;
				elseif(self.itemInHand.id == block_types.names.LiveModel) then
					itemStack.id = block_types.names.BlockModel;
				end
				GameLogic.GetPlayerController():SetBlockInRightHand(itemStack, true)
			end
		end
	end
end