--[[
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditLight/EditLightTask.lua");
local EditLightTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditLightTask");
local task = EditLightTask:new();
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateBlockTask.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DestroyBlockTask.lua");
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
NPL.load("(gl)script/ide/System/Util/Binding/Bindings.lua");
local Binding = commonlib.gettable("System.Util.Binding");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local vector3d = commonlib.gettable("mathlib.vector3d");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local EditLightTask = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.EditLightTask"));

local curInstance;
local light;

-- this is always a top level task. 
EditLightTask.is_top_level = true;

function EditLightTask:ctor()
end

local page;
function EditLightTask.InitPage(Page)
	page = Page;
end

-- get current instance
function EditLightTask.GetInstance()
	return curInstance;
end

function EditLightTask:Run()
	curInstance = self;

	self:LoadSceneContext();
	self:GetSceneContext():setMouseTracking(true);
	self:GetSceneContext():setCaptureMouse(true);
end

function EditLightTask:OnExit()
	self:ShowPage(false);

	self:SetFinished();
	self:UnloadSceneContext();
	self:CloseWindow();

	curInstance = nil;
	light = nil;
end

function EditLightTask:RefreshPage()
	if(page) then
		page:Refresh(0.01);
	end
end

function EditLightTask:UpdateManipulators()
	self:DeleteManipulators();

	if(light) then
		local x, y, z = light:GetPosition();

		if(light.modelFilepath and light.modelFilepath ~= "") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditLight/EditLightModelManipContainer.lua");
			local EditLightModelManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.EditLightModelManipContainer");
			local lightModelManipCont = EditLightModelManipContainer:new();
			lightModelManipCont:init(light);

			self:AddManipulator(lightModelManipCont);
			lightModelManipCont:connectToDependNode(light);
		end

		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditLight/EditLightManipContainer.lua");
		local EditLightManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.EditLightManipContainer");
		local manipCont = EditLightManipContainer:new();
		manipCont:init(light);

		self:AddManipulator(manipCont);
		manipCont:connectToDependNode(light);

		self:RefreshPage();
	end
end

function EditLightTask:Redo()
end

function EditLightTask:Undo()
end

function EditLightTask:ShowPage(bShow)
	if(not page) then
		local width,height = 200, 600;
		local params = {
				url = "script/apps/Aries/Creator/Game/Tasks/EditLight/EditLightTask.html", 
				name = "EditLightTask.ShowPage", 
				isShowTitleBar = false,
				DestroyOnClose = true,
				bToggleShowHide=false, 
				style = CommonCtrl.WindowFrame.ContainerStyle,
				allowDrag = true,
				enable_esc_key = false,
				bShow = bShow,
				click_through = false, 
				app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
				directPosition = true,
					align = "_lt",
					x = 0,
					y = 60,
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

function EditLightTask:GetSelectedLight()
	return light;
end

function EditLightTask:SelectLight(entityLight)
	self:ShowPage(true);

	if(light~=entityLight) then
		if(light) then
			light:Disconnect("valueChanged", EditLightTask, EditLightTask.OnLightValueChange);	
		end

		light = entityLight;
		light:Connect("valueChanged", EditLightTask, EditLightTask.OnLightValueChange, "UniqueConnection");
		self.UpdatePageFromLight();
		self:UpdateManipulators();
	end
end

function EditLightTask.OnLightValueChange()
	local self = EditLightTask.GetInstance();
	self:UpdatePageFromLight();
	if(light) then
		light:MarkForUpdate()
	end
end


function EditLightTask:PickLightAtMouse(result)
	local result = result or Game.SelectionManager:MousePickBlock(true, true, false);
	if(result.blockX) then
		local x,y,z = result.blockX,result.blockY,result.blockZ;
		local lightEntity = BlockEngine:GetBlockEntity(x,y,z) or result.entity;
		if(lightEntity and lightEntity:isa(EntityManager.EntityLight)) then
			return lightEntity;
		end
	end
end

function EditLightTask.CancelSelection()
	local self = EditLightTask.GetInstance();

	self:ShowPage(false);
	self:DeleteManipulators();
	if(light) then
		light:Disconnect("valueChanged", EditLightTask, EditLightTask.OnLightValueChange);	
		light = nil;
	end
end

function EditLightTask:handleLeftClickScene(event, result)
	local lightEntity = self:PickLightAtMouse();
	if(lightEntity) then
		self:SelectLight(lightEntity);
	else
		EditLightTask.CancelSelection()
	end
	event:accept();
end

function EditLightTask:handleRightClickScene(event, result)
	if(not GameLogic.GameMode:IsEditor()) then
		return;
	end

	local result = result or Game.SelectionManager:MousePickBlock(true, false, false);
	if(result and result.blockX) then
		local x,y,z = BlockEngine:GetBlockIndexBySide(result.blockX, result.blockY, result.blockZ, result.side);

		local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blockX = x, blockY = y, blockZ = z, entityPlayer = EntityManager.GetPlayer(), block_id = 264, side = result.side, from_block_id = result.block_id, side_region=side_region })
		task:Run();
		event:accept();
	end
end

function EditLightTask:mouseMoveEvent(event)
	self:GetSceneContext():mouseMoveEvent(event);
end

function EditLightTask:mouseWheelEvent(event)
	self:GetSceneContext():mouseWheelEvent(event);
end

function EditLightTask:keyPressEvent(event)
	local dik_key = event.keyname;
	if(dik_key == "DIK_Z")then
		UndoManager.Undo();
		event:accept();
	elseif(dik_key == "DIK_Y")then
		UndoManager.Redo();
		event:accept();
	end
	self:GetSceneContext():keyPressEvent(event);
end

function EditLightTask:SetItemInHand(itemStack)
	self.itemInHand = itemStack;
end

function EditLightTask:GetModelFileInHand()
	if(self.itemInHand) then
		return self.itemInHand:GetDataField("tooltip");
	end
end

function EditLightTask:UpdateValueToPage()
	self:RefreshPage()
end

function EditLightTask:UpdatePageFromLight()
	local self = EditLightTask.GetInstance();
	if(self and page) then
		if(light) then
			local lightModel = light:GetField("modelFilepath", "");
			page:SetValue("modelFilepath", string.gsub(lightModel, ".*/", ""));

			Binding.NumberToString(light, "LightType", 0, page, "LightType", "0", nil, "int");

			Binding.PosVec3ToString(light, "Diffuse", {1, 1, 1}, page, "Diffuse", {1, 1, 1}, 0.001, "int");
			Binding.PosVec3ToString(light, "Specular", {1, 1, 1}, page, "Specular", {1, 1, 1}, 0.001, "int");
			Binding.PosVec3ToString(light, "Ambient", {1, 1, 1}, page, "Ambient", {1, 1, 1}, 0.001, "int");

			Binding.PosVec3ToString(light, "modelOffsetPos", {1, 1, 1}, page, "Position", {1, 1, 1}, 0.001, "float");
			Binding.XYZToString(light, "Yaw", "Pitch", "Roll", 0, page, "Rotation", "0,0,0", 0.001, "int");

			Binding.NumberToString(light, "Range", 0, page, "Range", "0", 0.001, "float");
			Binding.NumberToString(light, "Falloff", 0, page, "Falloff", "0", 0.001, "float");

			Binding.NumberToString(light, "Attenuation0", 0, page, "Attenuation0", "0", 0.001, "float");
			Binding.NumberToString(light, "Attenuation1", 0, page, "Attenuation1", "0", 0.001, "float");
			Binding.NumberToString(light, "Attenuation2", 0, page, "Attenuation2", "0", 0.001, "float");

			Binding.NumberToString(light, "Theta", 0, page, "Theta", "0", 0.001, "int");
			Binding.NumberToString(light, "Phi", 0, page, "Phi", "0", 0.001, "int");
		else
			page:SetValue("modelFilepath", "")
			page:SetValue("LightType", "")
			page:SetValue("Diffuse", "")
			page:SetValue("Specular", "")
			page:SetValue("Ambient", "")
			page:SetValue("modelOffsetPos", "")
			page:SetValue("Rotation", "")
			page:SetValue("Range", "")
			page:SetValue("Falloff", "")
			page:SetValue("Attenuation0", "")
			page:SetValue("Attenuation1", "")
			page:SetValue("Attenuation2", "")
			page:SetValue("Theta", "")
			page:SetValue("Phi", "")
		end
	end
end

function EditLightTask.ChangeLightModel()
	local self = EditLightTask.GetInstance();
	if(self and page and light) then
		local local_filename = light:GetField("modelFilepath", "");

		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenAssetFileDialog.lua");
		local OpenAssetFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenAssetFileDialog");
		OpenAssetFileDialog.ShowPage(
			L"请输入bmax, x或fbx文件的相对路径, <br/>你也可以随时将外部文件拖入窗口中",
			function(result)
				if(light and result~=local_filename) then
					light:SetField("modelFilepath", result or "");
					self:UpdateManipulators();
				end
			end,
			local_filename,
			L"选择模型文件",
			"model",
			nil,
			nil
		)
	end
end

function EditLightTask.ChangeLightType()
	local self = EditLightTask.GetInstance();
	if(self and page and light) then
		Binding.StringToNumber(page, "LightType", "0", light, "LightType", 0, nil, "int");
		self:UpdateManipulators();
	end
end

function EditLightTask.ChangeDiffuseColor(r, g, b)
	local color = {r, g, b};

	if light then
		light:SetField("Diffuse", color)
	end
end

function EditLightTask.ChangeSpecularColor(r, g, b)
	local color = {r, g, b};

	if light then
		light:SetField("Specular", color)
	end
end

function EditLightTask.ChangeAmbientColor(r, g, b)
	local color = {r, g, b};

	if light then
		light:SetField("Ambient", color)
	end
end

function EditLightTask.UpdateLightFromPage()
	local self = EditLightTask.GetInstance();
	if(self and page and light) then
		Binding.StringToXYZ(page, "Rotation", "0,0,0", light, "Yaw", "Pitch", "Roll", 0, 0.001, "int");

		Binding.StringToNumber(page, "Range", "0", light, "Range", 0, 0.001, "float");
		Binding.StringToNumber(page, "Falloff", "0", light, "Falloff", 0, 0.001, "float");

		Binding.StringToNumber(page, "Attenuation0", "0", light, "Attenuation0", 0, 0.001, "float");
		Binding.StringToNumber(page, "Attenuation1", "0", light, "Attenuation1", 0, 0.001, "float");
		Binding.StringToNumber(page, "Attenuation2", "0", light, "Attenuation2", 0, 0.001, "float");

		Binding.StringToNumber(page, "Theta", "0", light, "Theta", 0, 0.001, "int");
		Binding.StringToNumber(page, "Phi", "0", light, "Phi", 0, 0.001, "int");
	end
end