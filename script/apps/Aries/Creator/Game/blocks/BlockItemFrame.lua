--[[
Title: BlockItemFrame
Author(s): LiXizhi
Date: 2013/12/13
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockItemFrame.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockItemFrame")
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

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.blocks.BlockEntityBase"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockItemFrame"));

-- register
block_types.RegisterBlockClass("BlockItemFrame", block);

function block:ctor()
end


function block:Init()
end

-- virtual: Checks to see if its valid to put this block at the specified coordinates. Args: world, x, y, z
function block:canPlaceBlockAt(x,y,z)
	return true;
end

function block:GetMetaDataFromEnv(blockX, blockY, blockZ, side, side_region, camx,camy,camz, lookat_x,lookat_y,lookat_z)
	local data = 0;
	if(side) then
		data = Direction.GetDirection3DFromCamera(camx,camy,camz, lookat_x,lookat_y,lookat_z);
		if(data == 4) then
			-- horizontal
			local direction = Direction.GetDirection2DFromCamera(camx,camy,camz, lookat_x,lookat_y,lookat_z);
			data = 4 + direction;
		elseif(data == 5) then
			local direction = Direction.GetDirection2DFromCamera(camx,camy,camz, lookat_x,lookat_y,lookat_z);
			data = 8 + direction;
		end
	end
	return data;
end

function block:RotateBlockData(blockData, angle, axis)
	return self:RotateBlockDataUsingModelFacing(blockData, angle, axis);
end

