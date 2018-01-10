--[[
Title: Checkpoint block Entity
Author(s): LiXizhi
Date: 2017/12/6
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBuildTask.lua");
local EntityBuildTask = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBuildTask")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCommandBlock.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/BuildTaskEditPage.lua");

local BuildTaskEditPage = commonlib.gettable("MyCompany.Aries.Game.GUI.BuildTaskEditPage");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ContainerView = commonlib.gettable("MyCompany.Aries.Game.Items.ContainerView");
local InventoryBase = commonlib.gettable("MyCompany.Aries.Game.Items.InventoryBase");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBuildTask"));

-- class name
Entity.class_name = "EntityBuildTask";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;



function Entity:ctor()	

end

function Entity:setRule(path, taskType)
	self.bindBmaxPath = path;
	self.taskType = taskType;
end	

-- virtual function: handle some external input. 
-- default is do nothing. return true is something is processed. 
function Entity:OnActivated(triggerEntity)
	local styleOpt = self.taskType or "";


	local btCmd;
	if self.isUseCustomPos then
		btCmd = string.format("/buildtask  start %d %d %d {src=\"%s\"} %s", self.activateX, self.activateY, self.activateZ, self.bindBmaxPath, styleOpt);
	else	
		btCmd = string.format("/buildtask  start {src=\"%s\"} %s", self.bindBmaxPath, styleOpt);
	end
	GameLogic.RunCommand(btCmd);
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

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	local attr = node.attr;
	attr.bindBmaxPath = self.bindBmaxPath;
	attr.taskType = self.taskType;
	return node;
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	local attr = node.attr;
	self.bindBmaxPath = attr.bindBmaxPath;
	self.taskType = attr.taskType;
end

-- TODO: move this function to `/checkpoint list `
function Entity:ShowListPage()	
end

-- virtual function: right click to edit. 
function Entity:OpenEditor(editor_name, entity)
	BuildTaskEditPage.ShowPage(self, entity);
end

-- called when the user clicks on the block
-- @return: return true if it is an action block and processed . 
function Entity:OnClick(x, y, z, mouse_button, entity, side)
	if(GameLogic.isRemote) then
		return true;
	else
		if(mouse_button=="left") then
			--self:ShowListPage();
		elseif(mouse_button=="right" and GameLogic.GameMode:CanEditBlock()) then
			self:OpenEditor("entity", entity);
		end
	end
	return true;
end