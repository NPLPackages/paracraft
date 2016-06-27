--[[
Title: item railcar
Author(s): LiXizhi
Date: 2014/6/8
Desc: rail cars 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemRailcar.lua");
local ItemRailcar = commonlib.gettable("MyCompany.Aries.Game.Items.ItemRailcar");
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local BlockRailBase = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockRailBase")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemRailcar = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemRailcar"));

block_types.RegisterItemClass("ItemRailcar", ItemRailcar);


function ItemRailcar:ctor()
end


-- virtual function: use the item. 
function ItemRailcar:OnUse()
end

-- virtual function: when selected in right hand
function ItemRailcar:OnSelect()
end

-- virtual function: when deselected in right hand
function ItemRailcar:OnDeSelect()
end

-- Returns true if the given Entity can be placed on the given side of the given block position.
-- @param x,y,z: this is the position where the block should be placed
-- @param side: this is the OPPOSITE of the side of contact. 
function ItemRailcar:CanPlaceOnSide(x,y,z,side, data, side_region, entityPlayer, itemStack)
    if (not EntityManager.HasNonPlayerEntityInBlock(x,y,z) and not BlockEngine:isBlockNormalCube(x,y,z)) then
        return true;
    end
end

-- virtual function:
-- @param result: picking result. {side, blockX, blockY, blockZ}
-- @return: return true if created
function ItemRailcar:OnCreate(result)
	if(result.blockX) then
		-- local bx,by,bz = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
		local bx, by, bz = result.blockX, result.blockY, result.blockZ;
		local block = BlockEngine:GetBlock(bx, by, bz);
		if(not BlockRailBase.isRailBlockAt(bx, by, bz)) then
			local side = BlockEngine:GetOppositeSide(result.side);
			bx, by, bz = BlockEngine:GetBlockIndexBySide(bx, by, bz,side)
			if(not BlockRailBase.isRailBlockAt(bx, by, bz)) then
				return;
			end
		end

		if(not EntityManager.HasNonPlayerEntityInBlock(bx,by,bz)) then 
			if(GameLogic.isRemote) then
				-- TODO: send creation request packet to server?
				GameLogic.AddBBS("warn", L"目前只有Server可以创建此类物品", 4000, "255 0 0")
			else
				local x, y, z = BlockEngine:real(bx,by,bz);
				local entity = MyCompany.Aries.Game.EntityManager.EntityRailcar:Create({x=x,y=y,z=z, item_id = self.block_id});
				EntityManager.AddObject(entity);
				return true;
			end
		end	
	end
end

-- called every frame
function ItemRailcar:FrameMove(deltaTime)
end