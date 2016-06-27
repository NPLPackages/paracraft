--[[
Title: BUD 
Author(s): LiXizhi
Date: 2014/3/10
Desc: block update detector. whenever the neighbour block is changed(updated), this block is activated. 
and all neighboring command blocks are also updated. Please note, when this block is first added, BUD is inactive for 5 ticks. 
and BUD does not reactive to other BUD(when they are added or removed)

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockBlockUpdateDetector.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockBlockUpdateDetector")
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockBlockUpdateDetector"));

-- register
block_types.RegisterBlockClass("BlockBlockUpdateDetector", block);

function block:ctor()
end

function block:OnBlockAdded(x, y, z)
	if(not GameLogic.isRemote) then
		if(BlockEngine:GetBlockId(x,y,z) == self.id) then
			-- newly added block should be inactive for 5 ticks. 
			BlockEngine:SetBlockData(x,y,z, 1);
			GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self.id, 5);
		end
	end
end

function block:OnNeighborChanged(x,y,z,neighbor_block_id)
	if(not GameLogic.isRemote) then
		if(neighbor_block_id~=self.id) then
			-- does not reactive to other BUD. 
			self:TryActivate(x,y,z);
		end
	end
end


function block:TryActivate(x,y,z)
	if(BlockEngine:GetBlockId(x,y,z) == self.id) then
		if(BlockEngine:GetBlockData(x, y, z) == 0) then
			BlockEngine:SetBlockData(x,y,z, 1);
			self:ActivateThisAndNeighbors(x,y,z);
		end
		-- make activate again after 5 ticks
		GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self.id, 5);
	end
end

-- search neighbour for command block and activate them. 
function block:ActivateThisAndNeighbors(x,y,z)
	self:OnActivated(x,y,z);
	self:TryActivateCommandBlockAt(x - 1, y, z);
	self:TryActivateCommandBlockAt(x + 1, y, z);
	self:TryActivateCommandBlockAt(x, y - 1, z);
	self:TryActivateCommandBlockAt(x, y + 1, z);
	self:TryActivateCommandBlockAt(x, y, z - 1);
	self:TryActivateCommandBlockAt(x, y, z + 1);
end

function block:TryActivateCommandBlockAt(x,y,z)
	local block_template = BlockEngine:GetBlock(x,y,z);
	if(block_template and block_template.id == block_types.names.Command_Block) then
		block_template:OnActivated(x,y,z);
	end
end

-- Ticks the block if it's been scheduled
function block:updateTick(x,y,z)
	if(not GameLogic.isRemote) then
		if(BlockEngine:GetBlockData(x, y, z) == 1 and BlockEngine:GetBlockId(x, y, z) == self.id) then
			-- make active again. 
			BlockEngine:SetBlockData(x,y,z, 0);
		end		
	end
end