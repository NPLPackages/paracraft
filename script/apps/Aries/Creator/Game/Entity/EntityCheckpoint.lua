--[[
Title: Checkpoint block Entity
Author(s): LiXizhi
Date: 2017/12/6
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCheckpoint.lua");
local EntityCheckpoint = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCheckpoint")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCommandBlock.lua");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCheckpoint"));

-- class name
Entity.class_name = "EntityCheckpoint";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;

function Entity:ctor()
end

-- virtual function: handle some external input. 
-- default is do nothing. return true is something is processed. 
function Entity:OnActivated(triggerEntity)
	GameLogic.RunCommand("/checkpoint save -force"..self:GetCheckpointName())
end

function Entity:OnNeighborChanged(x,y,z, from_block_id)
	if(not GameLogic.isRemote) then
		local isPowered = BlockEngine:isBlockIndirectlyGettingPowered(x,y,z);
		if(self.isPowered ~= isPowered) then
			self.isPowered = isPowered;
			if(isPowered) then
				self.timer = self.timer or commonlib.Timer:new({callbackFunc = function(timer)
					local x,y,z = self:GetBlockPos();
					local isPowered = BlockEngine:isBlockIndirectlyGettingPowered(x,y,z);
					if(isPowered) then
						self:OnActivated();
					end
				end})
				self.timer:Change(30, nil);
			end
		end
	end
end

-- TODO: move this function to `/checkpoint list `
function Entity:ShowListPage()
	local params = {
		url = "script/apps/Aries/Creator/Game/GUI/CheckpointListPage.html", 
		name = "CheckpointListPage.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		bToggleShowHide=false, 
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		enable_esc_key = true,
		bShow = true,
		click_through = true, 
		zorder = -1,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		bAutoSize = true,
		bAutoHeight = true,
		-- cancelShowAnimation = true,
		directPosition = true,
			align = "_ct",
			x = -200,
			y = -250,
			width = 400,
			height = 560,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

-- virtual function: right click to edit. 
function Entity:OpenEditor(editor_name, entity)
	EntityManager.SetLastTriggerEntity(entity);
	self:BeginEdit();
	local params = {
		url = "script/apps/Aries/Creator/Game/GUI/CheckpointEditPage.html", 
		name = "CheckpointEditPage.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		bToggleShowHide=false, 
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		enable_esc_key = true,
		bShow = true,
		click_through = true, 
		zorder = -1,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		bAutoSize = true,
		bAutoHeight = true,
		-- cancelShowAnimation = true,
		directPosition = true,
			align = "_ct",
			x = -200,
			y = -250,
			width = 400,
			height = 560,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		EntityManager.SetLastTriggerEntity(nil);
		self:EndEdit();
	end
end

function Entity:GetCheckpointName()
	return self:GetCommand() or "";
end

-- called when the user clicks on the block
-- @return: return true if it is an action block and processed . 
function Entity:OnClick(x, y, z, mouse_button, entity, side)
	if(GameLogic.isRemote) then
		return true;
	else
		if(mouse_button=="left") then
			GameLogic.RunCommand("/checkpoint save "..self:GetCheckpointName());
			-- GameLogic.RunCommand("/checkpoint list");
			self:ShowListPage();
		elseif(mouse_button=="right" and GameLogic.GameMode:CanEditBlock()) then
			self:OpenEditor("entity", entity);
		end
	end
	return true;
end