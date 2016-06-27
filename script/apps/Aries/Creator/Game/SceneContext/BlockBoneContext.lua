--[[
Title: Block Bone Context
Author(s): LiXizhi
Date: 2015/9/22
Desc: When a Bone block is activated or opened, we will be entering this context. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/BlockBoneContext.lua");
local BlockBoneContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.BlockBoneContext");
------------------------------------------------------------
]]
local MovieUISound = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieUISound");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local BaseContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.BaseContext");
local BlockBoneContext = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.SceneContext.EditContext"), commonlib.gettable("MyCompany.Aries.Game.SceneContext.BlockBoneContext"));

BlockBoneContext:Property("Name", "BlockBoneContext");
BlockBoneContext:Signal("boneChanged", function(boneEntity) end);
function BlockBoneContext:ctor()
end

-- virtual function: 
-- try to select this context. 
function BlockBoneContext:OnSelect()
	BaseContext.OnSelect(self);
	self:EnableMousePickTimer(true);
	self:Connect("boneChanged", self, self.updateManipulators, "UniqueConnection");
	self:updateManipulators();
	GameLogic.AddBBS("BlockBoneContext", L"左键选择骨骼, 右键编辑骨骼", 10000);
end

-- change the bone entity selected
-- @param boneEntity: type of EntityBlockBone or nil
function BlockBoneContext:SetSelectedBone(boneEntity)
	if(self.boneEntity ~= boneEntity) then
		self.boneEntity = boneEntity;
		self:boneChanged(boneEntity);
	end
end

function BlockBoneContext:GetSelectedBone()
	return self.boneEntity;
end

-- virtual function: 
-- return true if we are not in the middle of any operation and fire unselected signal. 
-- or false, if we can not unselect the scene tool context at the moment. 
function BlockBoneContext:OnUnselect()
	BlockBoneContext._super.OnUnselect(self);
	self:Disconnect("boneChanged", self, self.updateManipulators);
	self:SetSelectedBone(nil);
	GameLogic.AddBBS("BlockBoneContext", nil);
	return true;
end

function BlockBoneContext:updateManipulators()
	self:DeleteManipulators();
	local boneEntity = self:GetSelectedBone();
	if(boneEntity) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/Manipulators/BlockBoneManipContainer.lua");
		local BlockBoneManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.BlockBoneManipContainer");
		local manipCont = BlockBoneManipContainer:new();
		manipCont:init();
		self:AddManipulator(manipCont);
		manipCont:connectToDependNode(boneEntity);
		manipCont:Connect("boneChanged", self, self.SetSelectedBone);
	end
end


function BlockBoneContext:HandleGlobalKey(event)
	local dik_key = event.keyname;
	if(dik_key == "DIK_ESCAPE") then
		self:close();
		event:accept();
	else
		BlockBoneContext._super.HandleGlobalKey(self, event);
	end
	if(event:isAccepted()) then
		return true;
	end
	
	if(dik_key == "DIK_3") then
		event:accept();
	end
	return event:isAccepted();
end

-- virtual: 
function BlockBoneContext:mousePressEvent(event)
	BaseContext.mousePressEvent(self, event);
	if(event:isAccepted()) then
		return
	end
end

-- virtual: 
function BlockBoneContext:mouseMoveEvent(event)
	BaseContext.mouseMoveEvent(self, event);
	if(event:isAccepted()) then
		return
	end
end

function BlockBoneContext:HighlightPickBlock(result)
	-- we will only highlight bone block
	if(result.block_id == block_types.names.Bone) then
		BlockBoneContext._super.HighlightPickBlock(self, result);
	else
		result.block_id = nil;
		self:ClearBlockPickDisplay();
	end
end

function BlockBoneContext:HighlightPickEntity(result)
	-- diable entity selection
	if(not result.block_id and result.entity and result.obj) then
		result.entity = nil;
		result.obj = nil;
	end
	local click_data = self:GetClickData();
	if(click_data.last_select_entity) then
		click_data.last_select_entity = nil;
		ParaSelection.ClearGroup(1);
	end
end

function BlockBoneContext:mouseReleaseEvent(event)
	BaseContext.mouseReleaseEvent(self, event);
	if(event:isAccepted()) then
		return
	end

	if(self.is_click) then
		local result = self:CheckMousePick();
		if( result and (result.block_id == block_types.names.Bone)) then
			-- click on the bone block to switch to it
			local boneEntity = BlockEngine:GetBlockEntity(result.blockX, result.blockY, result.blockZ);
			if(boneEntity) then
				self:SetSelectedBone(boneEntity);
				event:accept();
				if(event:button() == "right") then
					if(boneEntity and boneEntity.OpenBagEditor) then
						boneEntity:OpenBagEditor();
					end
				end
				return;
			end
		end

		if(event:button() == "left") then
			-- left click to exit bone mode
			self:close();
		end
		event:accept();
	end
end

-- virtual: actually means key stroke. 
function BlockBoneContext:keyPressEvent(event)
	BlockBoneContext._super.keyPressEvent(self, event);
	if(event:isAccepted()) then
		return
	end
end

