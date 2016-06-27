--[[
Title: Grass Based Block
Author(s): LiXizhi
Date: 2013/11/29
Desc: Such as a character or mob that can walk and attack. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockGrass.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockGrass")
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockGrass"));

-- register
block_types.RegisterBlockClass("BlockGrass", block);

function block:ctor()
end

function block:Init()
	
end

-- virtual: Checks to see if its valid to put this block at the specified coordinates. Args: world, x, y, z
function block:canPlaceBlockAt(x,y,z)
	local below_block = BlockEngine:GetBlock(x, y-1, z);
	if(not below_block) then
		-- grass do not grow on air
		return false;
	elseif(below_block.transparent) then
		-- grass do not grow on other transparent object (possibly other grass). 
		return false;
	end
	return true;
end
