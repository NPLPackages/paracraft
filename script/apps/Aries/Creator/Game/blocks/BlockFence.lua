--[[
Title: Fence Based Block
Author(s): LiXizhi
Date: 2013/12/13
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockFence.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockFence")
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

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockFence"));

-- register
block_types.RegisterBlockClass("BlockFence", block);

function block:ctor()
end


function block:Init()
	
end

function block:GetMetaDataFromEnv(blockX, blockY, blockZ, side, side_region, camx,camy,camz, lookat_x,lookat_y,lookat_z)
	return block._super.GetMetaDataFromEnv(self, blockX, blockY, blockZ);
end

function block:RotateBlockData(blockData, angle, axis)
	return self:RotateBlockDataUsingModelFacing(blockData, angle, axis);
end

