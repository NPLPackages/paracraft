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
local task = EditModelTask:new();
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
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
				self:UnloadSceneContext();
			end
		end
	end
end

-- static page event handler
function EditModelTask.OnClickToggleMode()
	local self = EditModelTask.GetInstance();
	self:SetTransformMode(not self:IsTransformMode());
	self:RefreshPage();
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
	self:SetFinished();
	self:UnloadSceneContext();
	self:CloseWindow();
	curInstance = nil;
end

function EditModelTask:SelectModel(entityModel)
	if(self.entityModel~=entityModel) then
		self.entityModel = entityModel;
		self:UpdateManipulators();
	end
end

function EditModelTask:GetSelectedModel()
	return self.entityModel;
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
	local window = self:CreateGetToolWindow();
	window:Show({
		name="EditModelTask", 
		url="script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelTask.html",
		alignment="_ctb", left=0, top=-55, width = 256, height = 64,
	});
end

-- @param result: can be nil
function EditModelTask:PickModelAtMouse(result)
	local result = result or Game.SelectionManager:MousePickBlock(true, true, false);
	if(result.blockX) then
		local x,y,z = result.blockX,result.blockY,result.blockZ;
		local modelEntity = BlockEngine:GetBlockEntity(x,y,z) or result.entity;
		if(modelEntity and modelEntity:isa(EntityManager.EntityBlockModel)) then
			return modelEntity;
		end
	end
end

function EditModelTask:handleLeftClickScene(event, result)
	local modelEntity = self:PickModelAtMouse();
	if(modelEntity) then
		self:SelectModel(modelEntity);
	end
end

function EditModelTask:handleRightClickScene(event, result)
	local modelEntity = self:PickModelAtMouse();
	if(modelEntity) then
		modelEntity:OpenEditor("entity", modelEntity);
	end
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