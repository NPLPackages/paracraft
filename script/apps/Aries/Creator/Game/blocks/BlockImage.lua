--[[
Title: BlockImage
Author(s): LiXizhi
Date: 2014/1/9
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockImage.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockImage")
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
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.blocks.BlockEntityBase"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockImage"));

-- register
block_types.RegisterBlockClass("BlockImage", block);

function block:ctor()
end

function block:Init()
end

function block:GetMetaDataFromEnv(blockX, blockY, blockZ, side, side_region, camx,camy,camz, lookat_x,lookat_y,lookat_z)
	local data = 0;
	if(side) then
		data = Direction.GetDirection2DFromCamera(camx,camy,camz, lookat_x,lookat_y,lookat_z);
	end
	return data;
end

-- virtual: Checks to see if its valid to put this block at the specified coordinates. Args: world, x, y, z
function block:canPlaceBlockAt(x,y,z)
	return true;
end

-- Lets the block know when one of its neighbor changes. 
function block:OnNeighborChanged(x, y, z, from_block_id)
	if(self.id ~= from_block_id) then
		return;
	end
	local entity = self:GetBlockEntity(x,y,z)
	if(entity) then
		entity:OnNeighborChanged(x, y, z, from_block_id)
	end
end

function block:OnBlockRemoved(x,y,z, last_id, last_data)
	local entity = self:GetBlockEntity(x,y,z);
	if(entity.image_filename and entity.image_filename ~= "") then
		entity:ResetDerivedPaintings();
	else
		BlockEngine:NotifyNeighborBlocksChange(x, y, z, self.id);
	end

	EntityManager.RemoveBlockEntity(x, y, z, self:GetEntityClass():GetType());
end

local imagefile_inited_times = 0;

-- Ticks the block if it's been scheduled
function block:updateTick(x,y,z)
	local entity = self:GetBlockEntity(x,y,z);
	if(entity) then
		entity:updateTick(x,y,z);
	end
end

function block:RotateBlockData(blockData, angle, axis)
	return self:RotateBlockDataUsingModelFacing(blockData, angle, axis);
end