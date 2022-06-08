--[[
Title: BlockModel
Author(s): LiXizhi
Date: 2015/5/25
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockModel.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockModel")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.blocks.BlockEntityBase"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockModel"));

-- register
block_types.RegisterBlockClass("BlockModel", block);

function block:ctor()
end


function block:Init()
end

-- virtual: Checks to see if its valid to put this block at the specified coordinates. Args: world, x, y, z
function block:canPlaceBlockAt(x,y,z)
	return true;
end

function block:GetMetaDataFromEnv(blockX, blockY, blockZ, side, side_region, camx,camy,camz, lookat_x,lookat_y,lookat_z)
	return 0;
end

function block:RotateBlockEntityData(entityData, angle, axis)
	if(not axis or axis == "y") then
		if(entityData and entityData.attr) then
			local lastFacing = entityData.attr.facing or 0;
			if(lastFacing) then
				facing = lastFacing + angle;
				if(facing < 0) then
					facing = facing + 6.28;
				end
				facing = (math.floor(facing/1.57+0.5) % 4) * 1.57;

				entityData = commonlib.copy(entityData);
				entityData.attr.facing = facing;
			end
		end
	else
		-- TODO: other axis
	end
	
	return entityData;
end

function block:getMobilityFlag()
	return -1;
end

function block:OnMouseDown(event, bx, by, bz, pickingResult)
end

-- virtual function:
function block:OnMouseMove(event, bx, by, bz, pickingResult)
end

-- virtual function:
function block:OnMouseUp(event, bx, by, bz, pickingResult)
	if(pickingResult and event.mouse_button=="left" and GameLogic.GameMode:CanEditBlock()) then
		local bx1, by1, bz1 = pickingResult.blockX, pickingResult.blockY, pickingResult.blockZ
		-- at least drag 1 block away to trigger converter dialog
		if(((bx1-bx)^2 + (by1-by)^2 + (bz1-bz)^2) > 1) then
			_guihelper.MessageBox(L"是否将静态的方块模型转化为可拖动的活动模型?", function(res)
				if(res and res == _guihelper.DialogResult.Yes) then
					self:ConvertToLiveModel(bx, by, bz)
				end
			end, _guihelper.MessageBoxButtons.YesNoCancel);
			event:accept();
		end
	end
end

function block:ConvertToLiveModel(bx, by, bz)
	local entity = EntityManager.GetBlockEntity(bx, by, bz)
	if(entity and entity.TransformToLiveModel) then
		return entity:TransformToLiveModel();
	end
end