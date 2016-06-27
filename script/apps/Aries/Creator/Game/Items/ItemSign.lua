--[[
Title: ItemSign
Author(s): LiXizhi
Date: 2015/6/18
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemSign.lua");
local ItemSign = commonlib.gettable("MyCompany.Aries.Game.Items.ItemSign");
local item = ItemSign:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");

local ItemSign = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemSign"));

block_types.RegisterItemClass("ItemSign", ItemSign);

function ItemSign:PickItemFromPosition(x,y,z)
	local entity = self:GetBlock():GetBlockEntity(x,y,z);
	if(entity) then
		if(entity.cmd and entity.cmd~="") then
			local itemStack = ItemStack:new():Init(self.id, 1);
			-- transfer filename from entity to item stack. 
			itemStack:SetTooltip(entity.cmd);
			return itemStack;
		end
	end
	return self._super.PickItemFromPosition(self, x,y,z);
end

-- return true if items are the same. 
-- @param left, right: type of ItemStack or nil. 
function ItemSign:CompareItems(left, right)
	if(self._super.CompareItems(self, left, right)) then
		if(left and right and left:GetTooltip() == right:GetTooltip()) then
			return true;
		end
	end
end


function ItemSign:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
	local text = itemStack:GetDataField("tooltip");

	local res = self._super.TryCreate(self, itemStack, entityPlayer, x,y,z, side, data, side_region);
	if(res and text and text~="") then
		local entity = self:GetBlock():GetBlockEntity(x,y,z);
		if(entity and entity:GetBlockId() == self.id) then
			entity.cmd = text;
			entity:Refresh();
		end
	end
	return res;
end
