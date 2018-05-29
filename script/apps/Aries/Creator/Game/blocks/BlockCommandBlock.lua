--[[
Title: CommandBlock
Author(s): LiXizhi
Date: 2014/3/6
Desc: Block CommandBlock
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockCommandBlock.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockCommandBlock")
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local ItemCommandLine = commonlib.gettable("MyCompany.Aries.Game.Items.ItemCommandLine");
				
local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.blocks.BlockEntityBase"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockCommandBlock"));

-- register
block_types.RegisterBlockClass("BlockCommandBlock", block);


function block:ctor()
	-- self.ProvidePower = true;
end

-- some block like command blocks, may has an internal state number(like its last output result)
-- and some block may use its nearby blocks' state number to generate electric output or other behaviors.
-- @return nil or a number between [0-15]
function block:GetInternalStateNumber(x,y,z)
	local entity = self:GetBlockEntity(x,y,z)
	if(entity and entity.GetLastOutput) then
		return entity:GetLastOutput() or 0;
	else
		return 0;
	end
end

-- get the item stack when this block is broken & dropped. 
function block:GetDroppedItemStack(x,y,z)
	-- block._super.GetDroppedItemStack(self, x,y,z);

	if(GameLogic.GameMode:IsEditor()) then
		local entity = self:GetBlockEntity(x,y,z)
		if(entity) then
			if(entity.cmd and entity.cmd~="") then
				local itemStack = ItemStack:new():Init(block_types.names.CommandLine, 1);
				-- transfer commands from entity to item stack. 
				ItemCommandLine:SetCommandTable(itemStack, entity:GetCommandTable());
				return itemStack;
			end
		end
	end
end


function block:updateTick(x,y,z)
	if(not GameLogic.isRemote) then
		local entity = self:GetBlockEntity(x,y,z)
		if(entity and entity.OnBlockTick) then
			entity:OnBlockTick();
		end
	end
end
