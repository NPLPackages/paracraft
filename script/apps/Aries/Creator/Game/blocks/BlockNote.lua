--[[
Title: BlockNote
Author(s): LiXizhi
Date: 2014/1/9
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockNote.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockNote")
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

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.blocks.BlockEntityBase"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockNote"));

-- register
block_types.RegisterBlockClass("BlockNote", block);

function block:ctor()
end

function block:Init()
end

-- virtual: Checks to see if its valid to put this block at the specified coordinates. Args: world, x, y, z
function block:canPlaceBlockAt(x,y,z)
	return true;
end

-- call when use press mouse down button over the block
function block:OnMouseDown(x,y,z,mouse_button)
	-- disable play any step sound, as the default behavior. 	
	local entity = self:GetBlockEntity(x,y,z)
	if(entity and entity.PlayNote) then
		entity:PlayNote();
	end
end

function block:GetMetaDataFromEnv(blockX, blockY, blockZ, side, side_region, camx,camy,camz, lookat_x,lookat_y,lookat_z)
	return 0;
end


