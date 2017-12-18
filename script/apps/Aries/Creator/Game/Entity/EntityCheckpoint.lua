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
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/CheckpointEditPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/CheckpointListPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CheckPointIO.lua");

local CheckpointListPage = commonlib.gettable("MyCompany.Aries.Game.GUI.CheckpointListPage");
local CheckpointEditPage = commonlib.gettable("MyCompany.Aries.Game.GUI.CheckpointEditPage");
local CheckPointIO = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CheckPointIO");
			
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ContainerView = commonlib.gettable("MyCompany.Aries.Game.Items.ContainerView");
local InventoryBase = commonlib.gettable("MyCompany.Aries.Game.Items.InventoryBase");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCheckpoint"));

-- class name
Entity.class_name = "EntityCheckpoint";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;

function Entity.setLoadInx(loadInx)
	Entity.loadInx = loadInx;
end

function Entity.getLoadInx()
	return Entity.loadInx;
end

function Entity.onLoadWorldFinshed()
	CheckPointIO.readAll();
end

GameLogic:Connect("WorldLoaded", Entity, Entity.onLoadWorldFinshed, "EntityCheckpoint")	


function Entity:ctor()	
	self.cmpBag = InventoryBase:new():Init(40);
	self.cmpBagView = ContainerView:new():Init(self.cmpBag);
	self.cmpBag:SetClient();
end

-- virtual function: handle some external input. 
-- default is do nothing. return true is something is processed. 
function Entity:OnActivated(triggerEntity)
	if self.bindName then
		local save_cmd = string.format("/checkpoint save %s", self.bindName);
		local load_cmd = string.format("/checkpoint load %s", self.bindName);
		GameLogic.RunCommand(save_cmd);
		GameLogic.RunCommand(load_cmd);
	end
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
	CheckpointListPage.ShowPage();
end

-- the title text to display (can be mcml)
function Entity:GetCommandTitle2()
	return L"输入命令行(可以多行): <div>例如:/echo Hello</div>"
end

function Entity:GetBindCheckPoint()
	local name = self.bindName;
	local ret = CheckPointIO.read(name);
	return ret;
end	

-- virtual function: right click to edit. 
function Entity:OpenEditor(editor_name, entity)
	CheckpointEditPage.ShowPage(self, entity);
end

function Entity:GetDefaultCheckPointName()
	local x,y,z = self:GetBlockPos();
	local defaultName = string.format("cb_%d_%d_%d", x, y, z);
	return defaultName;
end

function Entity:GetBindName()
	return self.bindName;
end

function Entity:SetBindName(cpname)
	self.bindName = cpname;
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	local attr = node.attr;
	attr.bindName = self.bindName;
	return node;
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	local attr = node.attr;
	self.bindName = attr.bindName;
end

function Entity:writeCheckPoint(params, cpName)
	local cpName = cpName or self:GetBindName();	
	if cpName then
		local cmpBagNode = self.cmpBag:SaveToXMLNode({name="cmpBag"}, true);	
		local childNodes = {[1] = cmpBagNode};	
		CheckPointIO.write(cpName, params, false, childNodes);
	end	
end

-- called when the user clicks on the block
-- @return: return true if it is an action block and processed . 
function Entity:OnClick(x, y, z, mouse_button, entity, side)
	if(GameLogic.isRemote) then
		return true;
	else
		if(mouse_button=="left") then
			self:ShowListPage();
		elseif(mouse_button=="right" and GameLogic.GameMode:CanEditBlock()) then
			self:OpenEditor("entity", entity);
		end
	end
	return true;
end

-- the title text to display (can be mcml)
function Entity:GetRuleTitle2()
	return L"物品规则";
end
