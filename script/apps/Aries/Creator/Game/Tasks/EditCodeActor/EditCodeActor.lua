--[[
Title: EditCodeActor Task/Command
Author(s): LiXizhi
Date: 2019/1/31
Desc: 
- right click to create an instance and select it in the 3d scene
- select an actor instance in the UI to make changes to its init parameters
- 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditCodeActor/EditCodeActor.lua");
local EditCodeActor = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditCodeActor");
local task = EditCodeActor:new():Init(entityCode);
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
NPL.load("(gl)script/ide/System/Util/Binding/Bindings.lua");
local Binding = commonlib.gettable("System.Util.Binding");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local vector3d = commonlib.gettable("mathlib.vector3d");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local EditCodeActor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.EditCodeActor"));

local curInstance;
local curItemStack;

-- this is always a top level task. 
EditCodeActor.is_top_level = true;

function EditCodeActor:ctor()
end

function EditCodeActor:Init(entityCode)
	self.entityCode = entityCode;
	return self;
end

local page;
function EditCodeActor.InitPage(Page)
	page = Page;
end

-- get current instance
function EditCodeActor.GetInstance()
	return curInstance;
end

function EditCodeActor:RefreshPage()
	if(page) then
		page:Refresh(0.01);
	end
end

function EditCodeActor:Run()
	if(curInstance) then
		-- always close the previous one
		curInstance:OnExit();
	end
	curInstance = self;
	self.finished = false;
	
	self:LoadSceneContext();
	self:GetSceneContext():setMouseTracking(true);
	self:GetSceneContext():setCaptureMouse(true);
	curInstance = self;
	self:ShowPage(true);
	local entityCode = self:GetEntityCode()
	if(entityCode) then
		entityCode:RefreshInventoryActors();
		entityCode:Connect("inventoryChanged", self, self.OnInventoryChanged, "UniqueConnection");
	end

	EditCodeActor.SetFocusToActor()
end

function EditCodeActor:OnUnselect()
	if(not self.isExiting) then
		self:OnExit();
	end
end

function EditCodeActor:OnExit()
	self.isExiting = true
	local entityCode = self:GetEntityCode()
	if(entityCode) then
		entityCode:Disconnect("inventoryChanged", self, self.OnInventoryChanged);
	end
	self:SetFinished();
	self:UnloadSceneContext();
	self:ClosePage();
	local codeblock = self:GetCodeBlock()
	if(codeblock) then
		codeblock:RemoveAllInventoryMovieActors();
	end

	curInstance = nil;
	self.isExiting = nil;
end

function EditCodeActor:GetCodeActorItem()
	return ItemClient.GetItemByName("CodeActor");
end

function EditCodeActor.OnResetModel()
	local self = EditCodeActor.GetInstance();
	if(self) then
		local entity = self:GetSelectedModel();
		if(entity) then
			entity:setYaw(0);
			entity:setScale(1);
		end
	end
end

function EditCodeActor:UpdateManipulators()
	self:DeleteManipulators();

	if(self.actor) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditCodeActor/EditCodeActorManipContainer.lua");
		local EditCodeActorManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.EditCodeActorManipContainer");
		local manipCont = EditCodeActorManipContainer:new();
		manipCont:init();
		self:AddManipulator(manipCont);
		manipCont:connectToDependNode(self.actor);

		self:RefreshPage();
	end
end

function EditCodeActor:Redo()
end

function EditCodeActor:Undo()
end

function EditCodeActor:ShowPage(bShow)
	if(not page) then
		local width,height = 200, 330;
		local params = {
				url = "script/apps/Aries/Creator/Game/Tasks/EditCodeActor/EditCodeActor.html", 
				name = "EditCodeActor.ShowPage", 
				isShowTitleBar = false,
				DestroyOnClose = true,
				bToggleShowHide=false, 
				style = CommonCtrl.WindowFrame.ContainerStyle,
				allowDrag = true,
				enable_esc_key = false,
				bShow = bShow,
				click_through = false, 
				zorder = 1,
				app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
				directPosition = true,
					align = "_lt",
					x = 0,
					y = 160,
					width = width,
					height = height,
			};
		System.App.Commands.Call("File.MCMLWindowFrame", params);
		if(params._page) then
			params._page.OnClose = function()
				page = nil;
			end
		end
	else
		if(bShow == false) then
			page:CloseWindow();
		else
			page:Refresh(0.1);
		end
	end
end

function EditCodeActor:ClosePage()
	self:ShowPage(false);
end

function EditCodeActor:handleLeftClickScene(event, result)
end

function EditCodeActor:handleRightClickScene(event, result)
	local result = Game.SelectionManager:MousePickBlock();
	if(result.entity) then
		if(result.entity.GetActor) then
			local actor = result.entity:GetActor()
			if(actor and actor.codeActorItemStack) then
				local item = actor.codeActorItemStack;
				if(item.entityCode == self:GetEntityCode()) then
					EditCodeActor.SetFocusToItemStack(item:GetItemStack())
					return	
				end
			end
		end
	end
	if(result.blockX) then
		local blockTemplate = BlockEngine:GetBlock(result.blockX,result.blockY,result.blockZ);
		if(blockTemplate and blockTemplate.id == block_types.names.CodeBlock) then
			local codeEntity = BlockEngine:GetBlockEntity(result.blockX,result.blockY,result.blockZ);
			if(codeEntity) then
				codeEntity:OpenEditor();
				return
			end
		end
	end

	-- self:CreateActorInstanceAtMousePos();
end

function EditCodeActor:CreateActorInstanceAtMousePos()
	local item = self:GetCodeActorItem();
	if(item) then
		local result = SelectionManager:MousePickBlock(true, false, false); 
		if(result and result.blockX) then
			local x,y,z = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
			x, y, z = BlockEngine:real_min(x+0.5, y, z+0.5)
			item:CreateActorInstance(self:GetEntityCode(), x, y, z);
		end
	end
end

function EditCodeActor:mouseMoveEvent(event)
	self:GetSceneContext():mouseMoveEvent(event);
end

function EditCodeActor:mouseWheelEvent(event)
	self:GetSceneContext():mouseWheelEvent(event);
end

function EditCodeActor:keyPressEvent(event)
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

function EditCodeActor:GetActorName()
	if(self.codeblock) then
		return self.codeblock:GetBlockName();
	end
end

function EditCodeActor:GetSelectedModel()
	return self.entityActor;
end

function EditCodeActor:GetFacingDegree()
	local facing = 0;
	local modelEntity = self:GetSelectedModel()
	if(modelEntity) then
		facing = modelEntity:GetFacing();
	end
	return math.floor(mathlib.WrapAngleTo180(facing/math.pi*180)+0.5);
end

function EditCodeActor:SetFacingDegree(degree)
	local modelEntity = self:GetSelectedModel()
	if(modelEntity and degree) then
		modelEntity:SetFacing(mathlib.ToStandardAngle(degree/180*math.pi));
	end
end

function EditCodeActor.OnFacingDegreeChanged(text)
	local self = EditCodeActor.GetInstance();
	if(self) then
		self:SetFacingDegree(tonumber(text));
	end
end

function EditCodeActor.OnScalingChanged(text)
	local self = EditCodeActor.GetInstance();
	if(self) then
		local modelEntity = self:GetSelectedModel()
		if(modelEntity and text) then
			local scaling = tonumber(text);
			if(scaling and scaling >= 0.1 and scaling<=10) then
				modelEntity:SetScaling(scaling);
			end
		end
	end
end

function EditCodeActor:EditCodeBlock()
	local codeblock = self:GetCodeBlock()
	if(codeblock) then
		codeblock:GetEntity():OpenEditor();
	end
end

function EditCodeActor:GotoCodeBlock()
	local codeblock = self:GetCodeBlock()
	if(codeblock) then
		local x, y, z = codeblock:GetBlockPos()
		if(x and y and z) then
			GameLogic.RunCommand(format("/goto %d %d %d", x, y+1, z));
		end
	end
end

function EditCodeActor.OnClickCodeBlock()
	local self = EditCodeActor.GetInstance();
	if(self) then
		if(mouse_button == "left") then
			self:GotoCodeBlock()
		elseif(mouse_button == "right") then
			self:EditCodeBlock()
		end
	end
end

function EditCodeActor.SetFocusToItemStack(itemStack)
	if(curItemStack~=itemStack) then
		curItemStack = itemStack;
		local self = EditCodeActor.GetInstance();
		if(self) then
			self:RefreshPage()
		end
		EditCodeActor.SetFocusToActor();
	end
end

function EditCodeActor.SetFocusToActor()
	local self = EditCodeActor.GetInstance();
	if(curItemStack and self) then
		local entityCode = self:GetEntityCode();
		if(entityCode) then
			local slotIndex = entityCode:GetItemStackIndex(curItemStack);
			if(slotIndex) then
				local actorItemStackProxy = entityCode:GetCodeActorItemStack(slotIndex)
				if(actorItemStackProxy) then
					if(self.actor) then
						self.actor:Disconnect("valueChanged", EditCodeActor, EditCodeActor.OnActorValueChange, "UniqueConnection");
					end
					self.actor = actorItemStackProxy;
					self.actor:Connect("valueChanged", EditCodeActor, EditCodeActor.OnActorValueChange, "UniqueConnection");
					self:UpdateManipulators()
					self:UpdatePageFromActor();
				end
			end
		end
	end
end


function EditCodeActor:UpdatePageFromActor()
	local self = EditCodeActor.GetInstance();
	if(self and page) then
		if(self.actor) then
			Binding.StringToString(self.actor, "name", nil, page, "name", "");
			Binding.StringToString(self.actor, "userData", nil, page, "userData", "");
			Binding.NumberToString(self.actor, "startTime", nil, page, "startTime", "0", nil, "int", 0);
			Binding.NumberToString(self.actor, "scaling", nil, page, "scaling", "100", 0.001, nil, 0);
			Binding.PosVec3ToString(self.actor, "pos", nil, page, "pos", nil, 0.01);
			Binding.XYZToString(self.actor, "yaw", "pitch", "roll", nil, page, "rot", "0,0,0", 0.01, "int");
		else
			page:SetValue("name", "")
			page:SetValue("startTime", "")
			page:SetValue("pos", "")
			page:SetValue("rot", "")
			page:SetValue("userData", "")
			page:SetValue("scaling", "")
		end
	end
end

function EditCodeActor.UpdateActorFromPage()
	local self = EditCodeActor.GetInstance();
	if(self and page and self.actor) then
		Binding.StringToString(page, "name", "", self.actor, "name", nil);
		Binding.StringToString(page, "userData", "", self.actor, "userData", nil);
		Binding.StringToNumber(page, "startTime", "0", self.actor, "startTime", nil, nil, "int", 0);
		Binding.StringToNumber(page, "scaling", "100", self.actor, "scaling", nil, 0.01, nil, 0);
		Binding.StringToPosVec3(page, "pos", nil, self.actor, "pos", nil, 0.01);
		Binding.StringToXYZ(page, "rot", "0,0,0", self.actor, "yaw", "pitch", "roll", nil, 0.01, "int");
	end
end

function EditCodeActor:OnActorValueChange()
	local self = EditCodeActor.GetInstance();
	if(self and self.actor and page) then
		self:UpdatePageFromActor();
	end
end

function EditCodeActor.GetSelectedItemStack()
	return curItemStack;
end


function EditCodeActor.GetActorInventoryView()
	local self = EditCodeActor.GetInstance();
	if(self) then
		local entityCode = self:GetEntityCode()
		if(entityCode) then
			return entityCode:GetInventoryView();
		end
	end
end

function EditCodeActor.DS_Actor_Inventory(index)
	local view = EditCodeActor.GetActorInventoryView();
	if(view) then
        return view:GetSlotDS(index);
	else
		if(index == nil) then
			return 0;
        end
	end	
end

function EditCodeActor:GetEntityCode()
	return self.entityCode;
end

function EditCodeActor:GetCodeBlock()
	return self:GetEntityCode() and self:GetEntityCode():GetCodeBlock(true);
end


-- whenever the inventory is changed. 
function EditCodeActor:OnInventoryChanged(slotIndex)
	if(slotIndex) then
		-- TODO: refresh page if it is the selected index
	end
end

-- create at player block center position
function EditCodeActor.OnClickAddActor()
	local self = EditCodeActor.GetInstance();
	if(self) then
		local item = self:GetCodeActorItem();
		if(item) then
			local x, y, z = EntityManager.GetPlayer():GetBlockPos();
			x, y, z = BlockEngine:real_bottom(x, y, z);
			local facing = Direction.directionTo3DFacing[Direction.GetDirection2DFromCamera()]-3.14;
			item:CreateActorInstance(self:GetEntityCode(), x, y, z, facing);
		end
	end
end

function EditCodeActor.OnClose()
	local self = EditCodeActor.GetInstance();
	if(self) then
		self:OnExit()
	elseif(page) then
		page:CloseWindow();
	end
end

function EditCodeActor.OnClickTakeActor()
	local self = EditCodeActor.GetInstance();
	if(self) then
		local codeblock = self:GetCodeBlock()
		if(codeblock) then
			local x, y, z = codeblock:GetBlockPos();
			GameLogic.RunCommand(string.format("/take CodeActor {codeblock={%d,%d,%d}, tooltip=%q}", x, y, z, codeblock:GetBlockName() or ""));
		end
	end
end