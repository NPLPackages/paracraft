--[[
Title: Water Based Block
Author(s): LiXizhi
Date: 2013/11/29
Desc: Such as a character or mob that can walk and attack. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockLiquidStill.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockLiquidStill")
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockLiquidStill"));

-- register
block_types.RegisterBlockClass("BlockLiquidStill", block);

function block:ctor()
	self.isAutoUserData = true;
end

function block:Init()
end

function block:tickRate()
	return 5;
end

function block:OnBlockAdded(x, y, z)
	--block._super.OnBlockAdded(self, x, y, z);
	--self:OnNeighborChanged(x,y,z, 0);
end

function block:OnToggle(bx, by, bz)
end

-- if a still water block's neighbor changes, we will turn this water to flow water. 
function block:OnNeighborChanged(x,y,z,neighbor_block_id)
	if(not GameLogic.isRemote) then
		if(ParaTerrain.GetBlockTemplateByIdx(x,y,z) == self.id) then
			self:ChangeToFlowBlock(x,y,z);
		end
	end
end

-- Changes the block ID to that of an updating fluid.
function block:ChangeToFlowBlock(x,y,z)
	local data = ParaTerrain.GetBlockUserDataByIdx(x,y,z);
	BlockEngine:SetBlock(x,y,z, self.id - 1, data)
    GameLogic.GetSim():ScheduleBlockUpdate(x,y,z, self.id - 1, self:tickRate());
end

-- framemove 
function block:updateTick(x,y,z)
	-- TODO: lava may handle tick, water does not. 
	-- echo({"frame move", x,y,z, self.id})
end