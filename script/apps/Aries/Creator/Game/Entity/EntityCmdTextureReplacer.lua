--[[
Title: CmdTextureReplacer Entity
Author(s): LiXizhi
Date: 2014/2/12
Desc: replace the first block with second block in bag. 
try the block below this block if second inventory slot does not exist. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCmdTextureReplacer.lua");
local EntityCmdTextureReplacer = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCmdTextureReplacer")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCommandBlock.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/NeuronManager.lua");
local NeuronManager = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronManager");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCommandBlock"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCmdTextureReplacer"));

-- class name
Entity.class_name = "EntityCmdTextureReplacer";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;
-- command line text

function Entity:ctor()
	
end

-- @param Entity: the half radius of the object. 
function Entity:init()
	if(not Entity._super.init(self)) then
		return
	end
	-- TODO: 
	return self;
end

function Entity:Refresh()
end

-- replace the one item inside the inventory with the second one. 
function Entity:ExecuteCommand()
	Entity._super.ExecuteCommand(self);

	local itemStack_from = self.inventory:GetItem(1);
	if(itemStack_from) then
		local block_template = block_types.get(itemStack_from.id);
		if(block_template) then
			local itemStack_to = self.inventory:GetItem(2);
			local to_filename;
			if(itemStack_to) then
				to_filename = itemStack_to:GetItem():GetTexture();
			else
				-- try the block below this block if second inventory slot does not exist. 
				local x, y, z = self:GetBlockPos();
				local block_to = BlockEngine:GetBlock(x,y-1,z);
				if(block_to) then
					to_filename = block_to:GetTexture();
				end
			end
			block_template:ReplaceTexture(to_filename or "Texture/Transparent.png");
		end
	end
end

function Entity:OnNeighborChanged(x,y,z, from_block_id)
	return Entity._super.OnNeighborChanged(self, x,y,z, from_block_id);
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	self.isPowered = node.attr.isPowered == "true";
end

function Entity:SaveToXMLNode(node)
	node = Entity._super.SaveToXMLNode(self, node);
	if(self.isPowered) then
		node.attr.isPowered = true;
	end
	return node;
end

-- the title text to display (can be mcml)
function Entity:GetBagTitle()
	return "将场景中所有和背包中第一个方块一样的方块的贴图替换为背包中的第二个方块的材质。<div style='float:left' tooltip='如果背包中只有一个方块,那么将看下方的方块，如果下方也无，则为透明方块'>更多...</div>"
end

function Entity:HasCommand()
	return false;
end

-- called every frame
function Entity:FrameMove(deltaTime)
end