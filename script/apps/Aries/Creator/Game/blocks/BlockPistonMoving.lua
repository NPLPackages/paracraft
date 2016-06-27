--[[
Title: PistonMoving(NOT USED: since blocks are moved by piston immediately)
Author(s): LiXizhi
Date: 2013/12/3
Desc: this class is currently not used. Just in case, we will animate piston moving, 
we will use this block to tempararily hold blocks that is moving, and then set them back. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockPistonMoving.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockPistonMoving")
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockPistonMoving"));

-- register
block_types.RegisterBlockClass("BlockPistonMoving", block);

function block:ctor()
	self.ProvidePower = true;
end

function block:Init()
end


-- if a still water block's neighbor changes, we will turn this water to flow water. 
function block:OnNeighborChanged(x,y,z,neighbor_block_id)
	-- TODO: remove block when no neighbor is solid. 
end

function block:OnBlockRemoved(x, y, z, last_id, last_data)

end


-- goto pressed state and then schedule tickUpdate to go off again after some ticks
function block:OnActivated(x, y, z)
end

function block:OnToggle(x, y, z)
end

-- revert back to unpressed state
function block:updateTick(x,y,z)

end



