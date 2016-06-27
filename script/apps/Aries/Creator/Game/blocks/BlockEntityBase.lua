--[[
Title: BlockEntityBase
Author(s): LiXizhi
Date: 2013/12/13
Desc: base block that is container of entity, such as BlockSign, BlockChest, etc.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockEntityBase.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockEntityBase")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockEntityBase"));

-- register
block_types.RegisterBlockClass("BlockEntityBase", block);

function block:ctor()
end


function block:Init()
end

-- virtual function: this function is called whenever container block is first added to the scene. 
-- @return the entity created. 
function block:CreateBlockEntity(x,y,z, block_data, serverdata)
	local entity_class = self:GetEntityClass();
	if(entity_class) then
		local entity = entity_class:new({item_id = self.id, bx = x, by = y, bz = z})
		if(serverdata and type(serverdata) == "table") then
			entity:LoadFromXMLNode(serverdata);
		end
		if(entity:init()) then
			entity:Attach();
			return entity;
		end
	else
		LOG.std(nil, "error", "block %d does not have entity class defined", self.id);
	end
end

function block:OnBlockAdded(x,y,z, block_data, serverdata)
	local entity = self:GetBlockEntity(x,y,z)
	if(not entity) then
		entity = self:CreateBlockEntity(x,y,z,block_data, serverdata);
		-- LOG.std(nil, "debug", "BlockEntityBase", "OnBlockAdded block %d: %d %d %d", self.id, x, y, z);
	end
	if(entity) then
		entity:OnBlockAdded(x,y,z, block_data, serverdata);
	end
end

function block:OnBlockLoaded(x,y,z, block_data)
	local entity = self:GetBlockEntity(x,y,z)
	if(not entity) then
		entity = self:CreateBlockEntity(x,y,z, block_data);
	end
	if(entity) then
		entity:OnBlockLoaded(x,y,z, block_data);
	end
end

-- called when the user clicks on the block
-- @return: return true if it is an action block and processed . 
function block:OnClick(x, y, z, mouse_button, entity, side)
	if(self.hasAction) then
		local entity = self:GetBlockEntity(x,y,z)
		if(entity) then
			return entity:OnClick(x,y,z, mouse_button, entity, side);
		end
	end
end

-- virtual function
function block:OnActivated(x, y, z, triggerEntity)
	local bRes;
	local entity = self:GetBlockEntity(x,y,z)
	if(entity) then
		if(entity:OnActivated(triggerEntity)) then
			bRes = true;
		end
	end
	-- do neuron activation
	return block._super.OnActivated(self, x, y, z) or bRes;
end

-- Lets the block know when one of its neighbor changes. 
function block:OnNeighborChanged(x, y, z, from_block_id)
	local entity = self:GetBlockEntity(x,y,z)
	if(entity) then
		entity:OnNeighborChanged(x, y, z, from_block_id)
	end
end

function block:OnBlockRemoved(x,y,z, last_id, last_data)
	EntityManager.RemoveBlockEntity(x, y, z, self:GetEntityClass():GetType());
end

-- when ever an event is received. 
function block:OnBlockEvent(x,y,z, event_id, event_param)
	local entity = self:GetBlockEntity(x,y,z)
	if(entity) then
		return entity:OnBlockEvent(x,y,z, event_id, event_param);
	end
end
