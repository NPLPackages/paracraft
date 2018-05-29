--[[
Title: Electric LightBlock
Author(s): LiXizhi
Date: 2013/12/8
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockElectricLight.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockElectricLight")
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockElectricLight"));

-- register
block_types.RegisterBlockClass("BlockElectricLight", block);

function block:ctor()
end

function block:Init()
	
end

-- virtual: Checks to see if its valid to put this block at the specified coordinates. Args: world, x, y, z
function block:canPlaceBlockAt(x,y,z)
	return true;
end

function block:OnBlockPlacedBy(x,y,z, entity)
end

function block:OnBlockAdded(x, y, z)
	if(not GameLogic.isRemote) then
		self:UpdateMe(x, y, z);
	end
end

function block:OnNeighborChanged(x,y,z,neighbor_block_id)
	if(not GameLogic.isRemote) then
		self:UpdateMe(x, y, z);
	end
end

function block:UpdateMe(x, y, z)
	local is_powered = BlockEngine:isBlockIndirectlyGettingPowered(x, y, z)

    if ( (self.light and not is_powered) or (not self.light and is_powered)) then
		self:OnToggle(x, y, z);
    end
end

-- Ticks the block if it's been scheduled
function block:updateTick(x,y,z)
	if(not GameLogic.isRemote) then
		self:UpdateMe(x, y, z);
	end
end