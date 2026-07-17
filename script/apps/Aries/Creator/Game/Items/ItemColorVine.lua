--[[
Title: ItemColorVine
Author(s): LiXizhi
Date: 2024/1/10
Desc: a picture thin vine block that can be painted with any color. 
right click to rotate when creating on top of the same block. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemColorVine.lua");
local ItemColorVine = commonlib.gettable("MyCompany.Aries.Game.Items.ItemColorVine");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/Color.lua");
NPL.load("(gl)script/ide/math/bit.lua");
local Color = commonlib.gettable("System.Core.Color");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

local ItemColorVine = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemColorBlock"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemColorVine"));

block_types.RegisterItemClass("ItemColorVine", ItemColorVine);

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemColorVine:ctor()
end

-- virtual: draw icon with given size at current position (0,0)
-- @param width, height: size of the icon
-- @param itemStack: this may be nil. or itemStack instance. 
function ItemColorVine:DrawIcon(painter, width, height, itemStack)
	if(self:HasColorData()) then
		painter:SetPen(Color.ChangeOpacity(self:GetPenColor(itemStack)));
		painter:DrawRectTexture(0, 0, width, height, self:GetIcon());

		if(itemStack) then
			if(itemStack.count>1) then
				painter:SetPen("#ffffff");	
				painter:DrawText(0, height-15, width-1, 15, tostring(itemStack.count), 0x122);
			end
		end
	else
		ItemColorVine._super.DrawIcon(self, painter, width, height, itemStack)
	end
end

-- Right clicking in 3d world with the block in hand will trigger this function. 
-- Alias: OnUseItem;
-- @param itemStack: can be nil
-- @param entityPlayer: can be nil
-- @return isUsed: isUsed is true if something happens.
function ItemColorVine:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
	local x_, y_, z_ = BlockEngine:GetBlockIndexBySide(x,y,z,BlockEngine:GetOppositeSide(side));
	local block_id = BlockEngine:GetBlockId(x_, y_, z_);
	if(block_id == self.block_id) then
		-- rotate when creating on top of the same block. 
		local blockData = BlockEngine:GetBlockData(x_, y_, z_);
		local highColorData = mathlib.bit.band(blockData, 0xff00)
		blockData = mathlib.bit.band(blockData, 0xff);
		blockData = (blockData%6) + ((math.floor(blockData/6) + 1)%4)*6; -- side + dir * 6
		data = blockData + highColorData;
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ReplaceBlockTask.lua");
		local task = MyCompany.Aries.Game.Tasks.ReplaceBlock:new({blockX = x_,blockY = y_, blockZ = z_, 
			to_id = self.block_id, to_data=data, max_radius = 0})
		task:Run();
		return true;
	else
		return ItemColorVine._super.TryCreate(self, itemStack, entityPlayer, x,y,z, side, data, side_region);
	end
end
