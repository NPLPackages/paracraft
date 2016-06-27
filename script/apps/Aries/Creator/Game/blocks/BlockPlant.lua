--[[
Title: Plant Block
Author(s): LiXizhi
Date: 2013/12/15
Desc: click to toggle 4 states of the plant
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockPlant.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockPlant")
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockPlant"));

-- register
block_types.RegisterBlockClass("BlockPlant", block);

function block:ctor()
end

function block:Init()
	
end

-- virtual: Checks to see if its valid to put this block at the specified coordinates. Args: world, x, y, z
function block:canPlaceBlockAt(x,y,z)
	local last_block_id = ParaTerrain.GetBlockTemplateByIdx(x, y-1, z);
	if(last_block_id == 0) then
		-- Plant do not grow on air
		return false;
	else
		local below_block = block_types.get(last_block_id);
		if(below_block and below_block.transparent) then
			-- Plant do not grow on other transparent object (possibly other Plant). 
			return false;
		end	
	end
	return true;
end

function block:OnActivated(x, y, z)
	-- Delete this: for testing we will cycle all meta data here
	local data = BlockEngine:GetBlockData(x, y, z);	
	BlockEngine:SetBlockData(x, y, z, (data+1)%4);	
	return true;
end