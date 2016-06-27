--[[
Title: Select a model or character task
Author(s): LiXizhi
Date: 2013/1/26
Desc: Create a single model/character at the given position.
Left click to select. left click the object again to move it, right click to confirm. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectModelTask.lua");
local task = MyCompany.Aries.Game.Tasks.SelectModel:new({obj=obj})
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Assets/AssetsCommon.lua");
NPL.load("(gl)script/ide/Display3D/SceneNode.lua");
NPL.load("(gl)script/ide/Display3D/SceneManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/AI/LocalNPC.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local EntityCollectable = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCollectable")
local LocalNPC = commonlib.gettable("MyCompany.Aries.Creator.AI.LocalNPC");
local NPC = commonlib.gettable("MyCompany.Aries.Quest.NPC");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
local ObjEditor = commonlib.gettable("ObjEditor");

local SelectModel = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectModel"));

-- this is always a top level task. 
SelectModel.is_top_level = true;

local cur_instance;

function SelectModel:ctor()
end

function SelectModel.RegisterHooks()
	local self = cur_instance;
	self.sceneContext = self.sceneContext or Game.SceneContext.RedirectContext:new():RedirectInput(self);
	self.sceneContext:activate();
	self.sceneContext:UpdateManipulators();
end

function SelectModel.UnregisterHooks()
	local self = cur_instance;
	if(self and self.sceneContext) then
		self.sceneContext:close();
	end
end

function SelectModel:FrameMove()
	--if(self.entity) then
		--if(self.entity.bx) then
			--ParaTerrain.SelectBlock(self.entity.bx, self.entity.by, self.entity.bz, true);
		--end
	--end
end

function SelectModel:UpdateManipulators()
	self.sceneContext:DeleteManipulators();
	if(self.entity) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/Manipulators/ActorSelectManipContainer.lua");
		local ActorSelectManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.ActorSelectManipContainer");
		local manipCont = ActorSelectManipContainer:new();
		manipCont:init();
		self.sceneContext:AddManipulator(manipCont);
		manipCont:connectToDependNode(self.entity);
	end
end

function SelectModel:GetInnerObject()
	if(self.obj_id) then
		return ParaScene.GetObject(self.obj_id);
	end
end

function SelectModel:SetInnerObject(obj)
	if(obj) then
		self.obj_id = self.obj:GetID();
	else
		self.obj_id = nil;
	end
end

function SelectModel:Run()
	local obj = self.obj;
	if(obj and not TaskManager.AddTask(self)) then
		-- ignore the task if there is other top-level tasks.
		return;
	end
	if(not obj) then
		return;
	end

	cur_instance = self;
	self:SetInnerObject(obj)
	ParaSelection.AddObject(obj, 2);
	
	self.entity = EntityManager.GetEntityByObjectID(self.obj_id);
	if(self.entity) then
		-- signal
		self.entity:GetEditModel():Selected(); 
		ParaTerrain.DeselectAllBlock();
		self.obj_params = self.entity:GetPortaitObjectParams(true);
	else
		self.obj_params = ObjEditor.GetObjectParams(obj);
	end
	
	self.IsCharacter = self.obj_params.IsCharacter;
	
	if(self.IsCharacter) then
		self.obj_name = obj.name;
		self.obj_params.name = nil;

		self.group_id = obj:GetField("GroupID", 0);
	end
	

	SelectModel.finished = false;
	SelectModel.RegisterHooks();

	SelectModel.ShowPage();
end	

function SelectModel.IsEntity()
	local self = cur_instance;
	if(not self) then
		return
	end
	if(self.entity) then
		return true;
	end
end

-- get entity
function SelectModel.GetEntity()
	local self = cur_instance;
	if(self) then
		return self.entity;
	end
end

-- @param obj_type: "model", "character"
local function generate_name(obj_type)
	if(obj_type == "model") then
		return "s_"..ParaGlobal.GenerateUniqueID();
	else
		return "local:"..ParaGlobal.GenerateUniqueID();
	end
end

-- callback function only called when a minscene node is moved to main scene. 
-- @param entity: ParaObject 
-- @param params: parameters;
function SelectModel.OnUpdateEntity(entity, params, childnode)
	if(params.ischaracter) then
		local tag = childnode.tag;
		if(tag) then
			if(tag.DisplayName) then
				entity:SetDynamicField("AlwaysShowHeadOnText", true);
				entity:SetDynamicField("DisplayName", tag.DisplayName);
				Map3DSystem.ShowHeadOnDisplay(true, entity, tag.DisplayName, NPC.HeadOnDisplayColor);
			end
			if(not tag.IsPersistent) then
				entity:SetPersistent(false);
			end
			if(tag.ai_mods) then
				LocalNPC:ApplyAIModule(entity, tag.ai_mods);
			end
		end
	end
end

function SelectModel.OnUpdateEntity_miniscene(entity, params, childnode)
	if(params.ischaracter) then
		local tag = childnode.tag;
		if(tag) then
			if(tag.DisplayName) then
				entity:SetDynamicField("AlwaysShowHeadOnText", true);
				entity:SetDynamicField("DisplayName", tag.DisplayName);
				Map3DSystem.ShowHeadOnDisplay(true, entity, tag.DisplayName, NPC.HeadOnDisplayColor);
			end
		end
	end
end

-- swap the currently selected object to mini scene
-- this function can be called multiple time. so that all local modification happens in the mini-scene, and the changes
-- are only committed when exit editing. 
-- @return the objNode.
function SelectModel:SwapToMiniScene()
	if(not self.scene) then
		local obj = self:GetInnerObject();
		if(not obj) then
			return
		end
		obj:SetVisible(false);

		NPL.load("(gl)script/ide/Display3D/SceneManager.lua");
		self.scene = CommonCtrl.Display3D.SceneManager:new({
			uid = "select_miniscene",
			type = "miniscene",
			OnUpdateEntity = SelectModel.OnUpdateEntity_miniscene,
		});
		self.rootNode = CommonCtrl.Display3D.SceneNode:new({root_scene = self.scene,});
		local obj_params = self.obj_params;
		local global_name = obj_params.name;
		if(not obj_params.IsCharacter) then
			-- this is very tricky: we will ensure all model has a name that begin with "s_" (which does not save to script file like "g_"), so that we can delete by name. 
			-- otherwise successive undo/redo operation will not be possible. 
			if(not global_name or (not global_name:match("^s_") and not global_name:match("^g_"))) then
				global_name = generate_name("model");
			end
		else
			global_name = generate_name("char");
		end

		self.objNode = CommonCtrl.Display3D.SceneNode:new({
			uid = global_name,
			x = obj_params.x,
			y = obj_params.y,
			z = obj_params.z,
			facing = obj_params.facing,
			assetfile = obj_params.AssetFile,
			ischaracter = obj_params.IsCharacter,
			scaling = obj_params.scaling,
			rotation = obj_params.rotation,
			IsPersistent = obj_params.IsPersistent,
		});

		if(self.IsCharacter) then
			self.objNode.tag = {
				DisplayName = obj:GetDynamicField("DisplayName", ""), 
				IsPersistent = false,
				ai_mods = LocalNPC:GetNPCAIModule(self.obj_name),
			};
		end

		-- key a copy for undo
		self.original_node = self.objNode:Clone();
		self.original_node.uid = global_name;
		self.rootNode:AddChild(self.objNode);

		self.objNode:UpdateEntity();
		local obj = self.objNode:GetEntity();
		if(obj) then
			ParaSelection.AddObject(obj, 2);
		end
	end
	return self.objNode;
end

-- @param bCommitChange: true to commit all changes made 
function SelectModel.EndEditing(bCommitChange)
	SelectModel.finished = true;
	ParaSelection.ClearGroup(2);
	SelectModel.UnregisterHooks();
	SelectModel.ClosePage();
	
	ParaTerrain.DeselectAllBlock();

	if(cur_instance) then
		local self = cur_instance;

		cur_instance = nil;

		if(self.entity) then
			self.entity:GetEditModel():Deselected(); 
		end
		local obj = self:GetInnerObject();
		if(not obj) then
			return
		end

		if(self.scene and self.rootNode) then
			if(not self.is_modified or not bCommitChange) then
				obj:SetVisible(true);
				self.rootNode:Detach();
			else
				-- commit any changes in the mini scene to the real scene object. 
				if(self.IsCharacter) then
					LocalNPC:RemoveNPCCharacter(obj.name)
				end
				ParaScene.Delete(obj);
				
				-- detach from mini scene
				self.rootNode:Detach();

				-- attach to real scene
				local real_scene = CommonCtrl.Display3D.SceneManager:new({
					uid = "realscene",
					type = "scene",
					use_name_key = true,
					OnUpdateEntity = SelectModel.OnUpdateEntity,
				});
				self.rootNode:SetRootScene(real_scene);
				self.rootNode:Attach();
				self.real_scene = real_scene;

				-- add to history
				UndoManager.PushCommand(self);
			end
		end
	end
end

function SelectModel:Redo()
	if(self.obj_params and self.is_modified) then
		if(self.original_node) then
			self.original_node:Detach();
			self.rootNode:Attach();
		end
	end
end

function SelectModel:Undo()
	local obj_params = self.obj_params
	if(obj_params and self.is_modified) then
		-- attach to real scene
		self.rootNode:Detach();

		if(self.original_node) then
			local real_scene = self.real_scene or CommonCtrl.Display3D.SceneManager:new({uid = "realscene",type = "scene", use_name_key = true,OnUpdateEntity = SelectModel.OnUpdateEntity,});
			self.original_node:SetRootScene(real_scene);
			self.original_node:Attach();
		end
	end
end

function SelectModel:OnExit()
	SelectModel.EndEditing();
end

function SelectModel:mousePressEvent(event)
	local ctrl_pressed = event.ctrl_pressed;
	local shift_pressed = event.shift_pressed;
	
	local result = Game.SelectionManager:MousePickBlock();

	if(self.entity) then
		if(event.mouse_button == "left") then
			if(shift_pressed) then
				if(result.blockX)then
					ParaTerrain.DeselectAllBlock();
					local bx,by,bz = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
					self.entity:SetBlockPos(bx,by,bz);
					if(self.entity.bx) then
						ParaTerrain.SelectBlock(self.entity.bx, self.entity.by, self.entity.bz, true);
					end
				end
			end
		end
		return;
	end

	if((event.mouse_button == "left") and not self.is_moving and not ctrl_pressed and not shift_pressed) then
		local obj = self:GetInnerObject();
		
		if(result and result.obj and obj and obj:GetID() == self.obj_id ) then
			self.is_moving = true;
		else
			self.isLeftClick = true;
			return;
		end
	end

	-- pick any scene object
	if(result.x)then
		if(event.mouse_button == "left") then
			if(self.mode =="move" or self.mode =="copy") then
				self.mode = nil;
			else
				local objNode = self:SwapToMiniScene();
				local x, y, z = result.x, result.y, result.z;
				if(objNode) then
					if(ctrl_pressed) then
						self.mode = "copy";
						-- clone the last object. 
						local new_obj = objNode:Clone()
						
						if(self.IsCharacter) then
							new_obj.uid = generate_name("char");
						else
							new_obj.uid = generate_name("model");
						end

						self.rootNode:AddChild(new_obj);
					else
						self.mode = "move";
					end
					self.is_modified = true;

					objNode:SetPosition(x,y,z);
				end
			end
		end
	end
end

function SelectModel:mouseMoveEvent(event)
	local result = self.sceneContext:CheckMousePick();

	if(SelectModel.IsEntity()) then
		return;
	end
	
	local result = Game.SelectionManager:MousePickBlock(true, true, false);
	if(result.x)then
		local x, y, z = result.x, result.y, result.z;
		if(self.mode == "move" or self.mode == "copy") then
			local objNode = self:SwapToMiniScene();
			objNode:SetPosition(x,y,z);
			self.is_modified = true;

			GameLogic.PlayAnimation({animationName = "SelectObject",facingTarget = {x=x, y=y, z=z},});
		end
	end	
end

function SelectModel:mouseReleaseEvent(event)
	
	if(SelectModel.IsEntity()) then
		if(event.mouse_button == "left" and not self.shift_pressed) then
			-- exit editing mode. 
			SelectModel.EndEditing(true);
		end
	else
		if(event.mouse_button == "left") then
			local result = Game.SelectionManager:MousePickBlock();
			if(result.x)then
				if((self.shift_pressed and self.mode =="move") or (self.ctrl_pressed and self.mode =="copy")) then
					self.mode = nil;
				end
			end
			if(self.isLeftClick and event.dragDist<=5) then 
				-- exit editing mode if the user does not pick the same object the second time it left click the mouse.  
				SelectModel.EndEditing(true);
			end
			self.isLeftClick = nil;
		elseif(event.mouse_button == "right") then	
			if(event.dragDist<=5) then 
				-- exit editing mode. 
				SelectModel.EndEditing(true);
			end
		end		
	end
end

function SelectModel:keyPressEvent(event)
	local dik_key = event.keyname;

	if(dik_key == "DIK_ESCAPE")then
		-- exit editing mode without commit any changes. 
		SelectModel.EndEditing(false);
	elseif(dik_key == "DIK_EQUALS")then
		SelectModel.DoScaling(0.1);
	elseif(dik_key == "DIK_MINUS")then
		SelectModel.DoScaling(-0.1);
	elseif(dik_key == "DIK_LBRACKET")then
		SelectModel.DoFacing(0.1);
	elseif(dik_key == "DIK_RBRACKET")then
		SelectModel.DoFacing(-0.1);
	elseif(dik_key == "DIK_DELETE" or dik_key == "DIK_DECIMAL")then
		SelectModel.DoRemove();
	else
		self.sceneContext:keyPressEvent(event);
	end	
end

function SelectModel.GetObjParams()
	if(cur_instance) then
		return cur_instance.obj_params;
	end
end

function SelectModel.IsCharacterSelected()
	if(cur_instance) then
		return cur_instance.IsCharacter;
	end
end

------------------------
-- page function 
------------------------
local page;
function SelectModel.ShowPage()
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Tasks/SelectModelTask.html", 
			name = "SelectModelTask.ShowPage", 
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			isShowTitleBar = false,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 1,
			allowDrag = false,
			click_through = true,
			directPosition = true,
				align = "_lt",
				x = 0,
				y = 160,
				width = 128,
				height = 512,
		});
	MyCompany.Aries.Creator.ToolTipsPage.ShowPage(false);
end

function SelectModel.ClosePage()
	if(page) then
		page:CloseWindow();
	end
end

function SelectModel.OnInit()
	page = document:GetPageCtrl();
end

function SelectModel.DoClick(name)
	local self = SelectModel;
	if(name == "move")then
		self.DoMoveNode();
	elseif(name == "left_rot")then
		self.DoFacing(0.1);
	elseif(name == "right_rot")then
		self.DoFacing(-0.1);
	elseif(name == "remove")then
		self.DoRemove();
	elseif(name == "descale")then
		self.DoScaling(-0.1);
	elseif(name == "scale")then
		self.DoScaling(0.1);
	elseif(name == "simple_talk")then
		self.DoSimpleTalk();
	elseif(name == "property")then
		self.DoProperty()
	end
end

-- translation
function SelectModel.DoMoveNode()
	local self = cur_instance;
	if(self)then
		if(not self.mode) then
			self.mode = "move";
		end
	end
end
-- rotation
function SelectModel.DoFacing(v)
	local self = cur_instance;
	if(self)then
		if(self.entity) then
			self.entity:SetFacingDelta(v);
		else
			local objNode = self:SwapToMiniScene();
			if(objNode) then
				objNode:SetFacingDelta(v);
				self.is_modified = true;
			end
		end
	end
end
-- scaling
function SelectModel.DoScaling(v)
	local self = cur_instance;
	if(self)then
		if(self.entity) then
			self.entity:SetScalingDelta(v);
		else
			local objNode = self:SwapToMiniScene();
			if(objNode) then
				objNode:SetScalingDelta(v);
				self.is_modified = true;
			end	
		end
	end
end
-- remove
function SelectModel.DoRemove()
	local self = cur_instance;
	if(self)then
		if(SelectModel.IsEntity()) then
			self.entity:Destroy();
			--self.is_modified = true;
			SelectModel.EndEditing(true);
		else
			local objNode = self:SwapToMiniScene();
			if(objNode and self.rootNode) then
				self.is_modified = true;
				self.rootNode:ClearAllChildren();
				SelectModel.EndEditing(true);
			end
		end
	end
end

-- character only: simple talk ai
function SelectModel.DoSimpleTalk()
	local self = cur_instance;
	if(self)then
		if(self.entity) then
			self.entity:OpenEditor("entity", EntityManager.GetPlayer());
		else
			local obj = self:GetInnerObject();
			
			if(obj and obj:IsCharacter()) then
				LocalNPC:InvokeEditor(obj, "SimpleTalk");
			end	
		end
	end
end

-- character only: property
function SelectModel.DoProperty()
	local self = cur_instance;
	if(self)then
		if(self.entity) then
			self.entity:OpenEditor("property", EntityManager.GetPlayer());
		else
			local obj = self:GetInnerObject();
		
			if(obj and obj:IsCharacter()) then
				LocalNPC:InvokeEditor(obj, "aimod_base");
			end	
		end
	end
end

