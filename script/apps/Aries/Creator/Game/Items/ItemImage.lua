--[[
Title: ItemImage
Author(s): LiXizhi
Date: 2014/5/4
Desc: when BlockImage is destroyed, it will generate an ItemImage whose tooltip contains its filepath. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemImage.lua");
local ItemImage = commonlib.gettable("MyCompany.Aries.Game.Items.ItemImage");
local item = ItemImage:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
local Player = commonlib.gettable("MyCompany.Aries.Player");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");

local ItemImage = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemImage"));

block_types.RegisterItemClass("ItemImage", ItemImage);

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemImage:ctor()
end

-- just incase the tooltip contains the image path
function ItemImage:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
	if(ItemImage._super.TryCreate(self, itemStack, entityPlayer, x,y,z, side, data, side_region)) then
		local tooltip = itemStack:GetTooltip();
		if(tooltip and tooltip~="" and (tooltip:match("png$") or tooltip:match("jpg$"))) then
			local block_template = BlockEngine:GetBlock(x,y,z);
			if(block_template) then
				local entity = block_template:GetBlockEntity(x,y,z);
				if(entity) then
					entity:SetCommand(tooltip);
					entity:Refresh(true);
				end
			end
		end
		return true;
	end
end

function ItemImage:PickItemFromPosition(x,y,z)
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
function ItemImage:CompareItems(left, right)
	if(self._super.CompareItems(self, left, right)) then
		if(left and right and left:GetTooltip() == right:GetTooltip()) then
			return true;
		end
	end
end