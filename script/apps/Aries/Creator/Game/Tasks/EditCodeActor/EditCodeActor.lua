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
local task = EditCodeActor:new();
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local vector3d = commonlib.gettable("mathlib.vector3d");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local EditCodeActor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.EditCodeActor"));

local curInstance;
local curItemStack;

-- this is always a top level task. 
EditCodeActor.is_top_level = true;

function EditCodeActor:ctor()
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

function EditCodeActor:SetItemStack(itemStack)
	self.itemStack = itemStack;
end

function EditCodeActor:GetItemStack()
	return self.itemStack;
end


function EditCodeActor:Run()
	curInstance = self;
	self.finished = false;
	
	self:LoadSceneContext();
	self:GetSceneContext():setMouseTracking(true);
	self:GetSceneContext():setCaptureMouse(true);
	
	self:ShowPage(true);
end

function EditCodeActor:OnExit()
	self:SetFinished();
	self:UnloadSceneContext();
	self:ClosePage();
	curInstance = nil;
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
		local width,height = 200, 300;
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
	local item = self:GetCodeActorItem();
	if(item) then
		local result = SelectionManager:MousePickBlock(true, false, false); 
		if(result and result.blockX) then
			local x,y,z = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
			item:TryCreate(self:GetItemStack(), EntityManager.GetPlayer(), x, y, z);
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

function EditCodeActor:SetCodeBlock(codeblock)
	self.codeblock = codeblock;
end

function EditCodeActor:GetCodeBlock()
	return self.codeblock;
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
		if(page) then
			page:Refresh(0.1);
		end
	end
	EditCodeActor.SetFocusToActor();
end

function EditCodeActor.SetFocusToActor()
	-- TODO
end

function EditCodeActor.GetSelectedItemStack()
	return curItemStack;
end


function EditCodeActor.GetActorInventoryView()
	local entityCode = EditCodeActor.GetEntityCode()
	if(entityCode) then
		return entityCode:GetInventoryView();
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

function EditCodeActor.GetEntityCode()
	local self = EditCodeActor.GetInstance();
	local codeblock = self:GetCodeBlock()
	if(codeblock) then
		return codeblock:GetEntity()
	end
end

function EditCodeActor.OnClickAddActor()
	local entityCode = EditCodeActor.GetEntityCode()
	if(entityCode) then
		local itemStack = entityCode:CreateActorItemStack();
		if(itemStack) then
			EditCodeActor.SetFocusToItemStack(itemStack);
		end
	end
end