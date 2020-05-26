--[[
Title: Edit Code Block Context
Author(s): LiXizhi
Date: 2018/8/23
Desc: show translate and rotate manipulator for time 0 of the first actor in movie block, if and only if code block is not running. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/EditCodeBlockContext.lua");
local EditCodeBlockContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.EditCodeBlockContext");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/EditContext.lua");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EditCodeBlockContext = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.SceneContext.EditContext"), commonlib.gettable("MyCompany.Aries.Game.SceneContext.EditCodeBlockContext"));

EditCodeBlockContext:Property({"Name", "EditCodeBlockContext"});
EditCodeBlockContext:Property({"showBones", false, "IsShowBones", "SetShowBones"});

function EditCodeBlockContext:ctor()
end


-- virtual function: 
-- try to select this context. 
function EditCodeBlockContext:OnSelect()
	EditCodeBlockContext._super.OnSelect(self);
end

-- virtual function: 
-- return true if we are not in the middle of any operation and fire unselected signal. 
-- or false, if we can not unselect the scene tool context at the moment. 
function EditCodeBlockContext:OnUnselect()
	self:SetCodeEntity(nil);
	self:RemoveActor();
	EditCodeBlockContext._super.OnUnselect(self);
	return true;
end

-- virtual: 
function EditCodeBlockContext:mousePressEvent(event)
	EditCodeBlockContext._super.mousePressEvent(self, event);
	if(event:isAccepted()) then
		return
	end

	local click_data = self:GetClickData();
end

-- virtual: 
function EditCodeBlockContext:mouseMoveEvent(event)
	EditCodeBlockContext._super.mouseMoveEvent(self, event);
	if(event:isAccepted()) then
		return
	end
	local result = self:CheckMousePick();
end


function EditCodeBlockContext:handleLeftClickScene(event, result)
	EditCodeBlockContext._super.handleLeftClickScene(self, event, result);
	local click_data = self:GetClickData();
end

-- virtual: 
function EditCodeBlockContext:mouseReleaseEvent(event)
	EditCodeBlockContext._super.mouseReleaseEvent(self, event);
	if(event:isAccepted()) then
		return
	end
end

function EditCodeBlockContext:HandleGlobalKey(event)
	local dik_key = event.keyname;
	if(dik_key == "DIK_ESCAPE") then
		-- event:accept();
		-- GameLogic.AddBBS(nil, "code context");
	elseif(dik_key == "DIK_1") then
		self:SetShowBones(not self:IsShowBones())
	elseif(dik_key == "DIK_F" and event.shift_pressed and event.ctrl_pressed) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
		local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
		if(CodeBlockWindow.FindTextGlobally()) then
			event:accept()
		end
	end
	return EditCodeBlockContext._super.HandleGlobalKey(self, event);
end

function EditCodeBlockContext:UpdateCodeBlock()
	self:updateManipulators(0.01);
end

function EditCodeBlockContext:GetMovieEntity()
	local codeblock = self:GetCodeBlock();
	if(codeblock) then
		return codeblock:GetMovieEntity()
	end
end

-- create get code block
function EditCodeBlockContext:GetCodeBlock()
	if(self.entity) then
		return self.entity:GetCodeBlock(true)
	end
end

function EditCodeBlockContext:SetCodeEntity(entity)
	if(self.entity ~= entity) then
		local codeblock = self:GetCodeBlock();
		if(codeblock) then
			codeblock:Disconnect("stateChanged", self, self.UpdateCodeBlock);
			codeblock:RemoveAllInventoryMovieActors();
		end
		self.entity = entity;

		local codeblock = self:GetCodeBlock();
		if(codeblock) then
			codeblock:Connect("stateChanged", self, self.UpdateCodeBlock);
		end

		self:UpdateCodeBlock()
	end
end

function EditCodeBlockContext:GetCodeEntity()
	return self.entity;
end

function EditCodeBlockContext:RemoveActor()
	if(self.actor) then
		self.actor:OnRemove();
		self.actor:Destroy();
		self.actor = nil;
	end
end

function EditCodeBlockContext:IsCodeRunning()
	local codeblock = self:GetCodeBlock();
	if(codeblock) then
		return codeblock:IsLoaded() or codeblock:HasRunningTempCode();
	end
end

function EditCodeBlockContext:CreateGetActor()
	if(not self.actor) then
		local movieEntity = self:GetMovieEntity();
		if(movieEntity) then
			local itemStack = movieEntity:GetFirstActorStack();
			if(itemStack) then
				local item = itemStack:GetItem();
				if(item and item.CreateActorFromItemStack) then
					local actor = item:CreateActorFromItemStack(itemStack, movieEntity, false, "ActorForEditor_");
					if(actor) then
						self.actor = actor;
						self.actor:Connect("keyChanged", self, EditCodeBlockContext.UpdateActor);
						self.actor:SetTime(0);
						self.actor:FrameMove(0);
						local entity = self.actor:GetEntity();
						if(entity) then
							entity:SetSkipPicking(true)
						end
					end
				end
			end
		end
	end
	return self.actor;
end

function EditCodeBlockContext:UpdateActor()
	if(self.actor) then
		self.actor:FrameMovePlaying(0);

		-- tricky: this is the another place to modify movie block content, so we will send updates every 1 seconds on network.
		self.refreshInventoryTimer = self.refreshInventoryTimer or commonlib.Timer:new({callbackFunc = function(timer)
			local movieEntity = self:GetMovieEntity();
			if(movieEntity) then
				movieEntity:MarkForUpdate();
			end
		end})
		self.refreshInventoryTimer:Change(200);
	end
end

function EditCodeBlockContext:GetActor()
	return self.actor;
end

function EditCodeBlockContext:ShowGrid(bShow)
	if(self.isShowGrid ~= bShow) then
		self.isShowGrid = bShow
		self:updateManipulators(0.01);
	end
end

function EditCodeBlockContext:IsShowGrid()
	return self.isShowGrid;
end

function EditCodeBlockContext:updateManipulators(delaySeconds)
	if(delaySeconds and delaySeconds>0) then
		self.updateTimer = self.updateTimer or commonlib.Timer:new({callbackFunc = function(timer)
			self:updateManipulators();
		end})
		self.updateTimer:Change(math.floor(delaySeconds*1000));
		return;
	end

	self:DeleteManipulators();
	self:RemoveActor();
	if(self:IsCodeRunning()) then
		return;
	end

	local actor = self:CreateGetActor();
	if(actor) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/Manipulators/MoveManipContainer.lua");
		local MoveManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.MoveManipContainer");
		local manipCont = MoveManipContainer:new();
		manipCont:SetShowGrid(true);
		manipCont:SetSnapToGrid(false);
		manipCont:SetGridSize(BlockEngine.blocksize/2);
		manipCont:init();
		self:AddManipulator(manipCont);
		manipCont:connectToDependNode(actor);

		if(self:IsShowGrid()) then
			manipCont.translateManip:SetPlaneSize(10);
			manipCont.translateManip:SetPlaneColor(0);
			manipCont.translateManip:SetPlainLineColor(0x20000000);
			--manipCont.translateManip:SetShowXPlane(true)
			manipCont.translateManip:SetShowYPlane(true)
			--manipCont.translateManip:SetShowZPlane(true)
		end

		if(self:IsShowBones()) then
			NPL.load("(gl)script/ide/System/Scene/Manipulators/BonesManipContainer.lua");
			local BonesManipContainer = commonlib.gettable("System.Scene.Manipulators.BonesManipContainer");
			local manipCont = BonesManipContainer:new();
			manipCont:init();
			self:AddManipulator(manipCont);
			manipCont:connectToDependNode(actor);
		else
			-- rotation is disabled when bone is displayed such as for cad block
			NPL.load("(gl)script/ide/System/Scene/Manipulators/RotateManipContainer.lua");
			local RotateManipContainer = commonlib.gettable("System.Scene.Manipulators.RotateManipContainer");
			local manipCont = RotateManipContainer:new();
			manipCont:init();
			manipCont:SetYawPlugName("facing");
			manipCont:SetYawEnabled(true);
			manipCont:SetPitchEnabled(false);
			manipCont:SetRollEnabled(false);
			self:AddManipulator(manipCont);
			manipCont:connectToDependNode(actor);
		end
	end
	local codeblock = self:GetCodeBlock();
	if(codeblock) then
		codeblock:RefreshAllInventoryAsMovieActors()
	end
end

function EditCodeBlockContext:SetShowBones(bShowBones)
	if(self.showBones ~= bShowBones) then
		self.showBones = bShowBones;
		self:updateManipulators(0.01);
	end
end

function EditCodeBlockContext:IsShowBones()
	return self.showBones;
end