--[[
Title: EditSensor Task/Command
Author(s): LiXizhi
Date: 2020/1/15
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditSensorTask.lua");
local EditSensorTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditSensorTask");
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

local EditSensorTask = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.EditSensorTask"));

local curInstance;

-- this is always a top level task. 
EditSensorTask.is_top_level = true;

function EditSensorTask:ctor()
	self.position = vector3d:new(0,0,0);
	self.transformMode = false;
end

local page;
function EditSensorTask.InitPage(Page)
	page = Page;
end

-- get current instance
function EditSensorTask.GetInstance()
	return curInstance;
end

-- by default it is in select and create mode. 
function EditSensorTask:IsTransformMode()
	return self.transformMode;	
end

-- enable transform mode
function EditSensorTask:SetTransformMode(bEnable)
	bEnable	= bEnable == true or bEnable==nil;
	if(self.transformMode ~= bEnable) then
		self.transformMode = bEnable;
		if(EditSensorTask.GetInstance()) then
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

function EditSensorTask:RefreshPage()
	if(page) then
		page:Refresh(0.01);
	end
end

function EditSensorTask:Run()
	curInstance = self;
	self.finished = false;
	if(self:IsTransformMode()) then
		self:LoadSceneContext();
		self:GetSceneContext():setMouseTracking(true);
		self:GetSceneContext():setCaptureMouse(true);
	end
	self:ShowPage();
end

function EditSensorTask:OnExit()
	self:SelectModel(nil);
	self:SetFinished();
	self:UnloadSceneContext();
	self:CloseWindow();
	curInstance = nil;
end

function EditSensorTask:SelectModel(entityModel)
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

function EditSensorTask.GetItemID()
	local self = EditSensorTask.GetInstance();
	if(self.itemInHand) then
		return self.itemInHand.id
	end
end

function EditSensorTask:GetSelectedModel()
	return self.entityModel;
end

function EditSensorTask.OnResetModel()
	local self = EditSensorTask.GetInstance();
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

function EditSensorTask:UpdateManipulators()
	self:DeleteManipulators();

	if(self.entityModel) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelManipContainer.lua");
		local EditModelManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.EditModelManipContainer");
		local manipCont = EditModelManipContainer:new();
		manipCont:init();
		manipCont:ShowRotation(false)
		--manipCont:ShowScaling(false)
		self:AddManipulator(manipCont);
		manipCont:connectToDependNode(self.entityModel);

		self:RefreshPage();
	end
end

function EditSensorTask:Redo()
end

function EditSensorTask:Undo()
end

function EditSensorTask:ShowPage()
	NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
	local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
	local viewport = ViewportManager:GetSceneViewport();
	local parent = viewport:GetUIObject(true)

	local window = self:CreateGetToolWindow();
	window:Show({
		name="EditSensorTask", 
		url="script/apps/Aries/Creator/Game/Tasks/EditModel/EditSensorTask.html",
		alignment="_ctb", left=0, top=-55, width = 360, height = 64, parent = parent
	});
end

-- @param result: can be nil
function EditSensorTask:PickModelAtMouse(result)
	local result = result or Game.SelectionManager:MousePickBlock(true, true, false);
	if(result.blockX) then
		local x,y,z = result.blockX,result.blockY,result.blockZ;
		local modelEntity = BlockEngine:GetBlockEntity(x,y,z) or result.entity;
		if(modelEntity and modelEntity:isa(EntityManager.EntityInvisibleClickSensor)) then
			return modelEntity;
		end
	end
end

function EditSensorTask:handleLeftClickScene(event, result)
	local modelEntity = self:PickModelAtMouse();
	if(modelEntity) then
		self:SelectModel(modelEntity);
		self:SetTransformMode(true);
	else
		self:SetTransformMode(false);
	end
	event:accept();
end

function EditSensorTask:handleRightClickScene(event, result)
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

function EditSensorTask:mouseMoveEvent(event)
	self:GetSceneContext():mouseMoveEvent(event);
end

function EditSensorTask:mouseWheelEvent(event)
	self:GetSceneContext():mouseWheelEvent(event);
end

function EditSensorTask:keyPressEvent(event)
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

function EditSensorTask:SetItemInHand(itemStack)
	self.itemInHand = itemStack;
end

function EditSensorTask:GetModelFileInHand()
	if(self.itemInHand) then
		return self.itemInHand:GetDataField("tooltip");
	end
end

function EditSensorTask:GetOnClickEventInHand()
	if(self.itemInHand) then
		return self.itemInHand:GetDataField("onclickEvent");
	end
end

function EditSensorTask.OnClickChangeModelFile()
	local self = EditSensorTask.GetInstance();
	if(self and self.itemInHand) then
		local item = self.itemInHand:GetItem();
		if(item and item.SelectModelFile) then
			item:SelectModelFile(self.itemInHand);
		end
	end
end

function EditSensorTask:UpdateValueToPage()
	self:RefreshPage()
end

function EditSensorTask:GetFacingDegree()
	local facing = 0;
	local modelEntity = self:GetSelectedModel()
	if(modelEntity) then
		facing = modelEntity:GetFacing();
	end
	return math.floor(mathlib.WrapAngleTo180(facing/math.pi*180)+0.5);
end

function EditSensorTask:SetFacingDegree(degree)
	local modelEntity = self:GetSelectedModel()
	if(modelEntity and degree) then
		modelEntity:SetFacing(mathlib.ToStandardAngle(degree/180*math.pi));
	end
end

function EditSensorTask.OnFacingDegreeChanged(text)
	local self = EditSensorTask.GetInstance();
	if(self) then
		self:SetFacingDegree(tonumber(text));
	end
end

function EditSensorTask.OnScalingChanged(text)
	local self = EditSensorTask.GetInstance();
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

function EditSensorTask.OnChangeOnClickEvent(text)
	local self = EditSensorTask.GetInstance();
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

function EditSensorTask.OnClickTogglePhysics()
	local self = EditSensorTask.GetInstance();
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

function EditSensorTask.GetMountPointCount()
	local self = EditSensorTask.GetInstance();
	if(self) then
		local modelEntity = self:GetSelectedModel()
		if(modelEntity and modelEntity:GetMountPoints()) then
			return modelEntity:GetMountPoints():GetCount()
		end
	end
	return 0
end

function EditSensorTask.OnMountPointCountChanged(text)
	local self = EditSensorTask.GetInstance();
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

function EditSensorTask.OnClickDeleteModel()
	local self = EditSensorTask.GetInstance();
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

function EditSensorTask.OnClickProperty()
	local self = EditSensorTask.GetInstance();
	if(self) then
		local modelEntity = self:GetSelectedModel()
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelProperty.lua");
		local EditModelProperty = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditModelProperty");
		EditModelProperty.ShowForEntity(modelEntity)
	end
end