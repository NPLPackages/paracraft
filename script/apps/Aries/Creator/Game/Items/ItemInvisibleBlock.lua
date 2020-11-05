--[[
Title: ItemInvisibleBlock
Author(s): LiXizhi
Date: 2020/10/15
Desc: the block is made visible when item is selected, and invisible if not. 


use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemInvisibleBlock.lua");
local ItemInvisibleBlock = commonlib.gettable("MyCompany.Aries.Game.Items.ItemInvisibleBlock");
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemInvisibleBlock = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemToolBase"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemInvisibleBlock"));

block_types.RegisterItemClass("ItemInvisibleBlock", ItemInvisibleBlock);

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemInvisibleBlock:ctor()
end


function ItemInvisibleBlock:OnSelect(itemStack)
	self:SetVisible(true)
	ItemInvisibleBlock._super.OnSelect(self);
end

function ItemInvisibleBlock:OnDeSelect()
	self:SetVisible(false)
	ItemInvisibleBlock._super.OnDeSelect(self);
end


function ItemInvisibleBlock:SetVisible(bVisible)
	local blockTemplate = block_types.get(self.id);
	if(blockTemplate) then
		blockTemplate.invisible = not bVisible;
		
		if(blockTemplate.light and not bVisible) then
			blockTemplate:SetInvisibleLightValue(15)
		else
			blockTemplate:SetVisible(not blockTemplate.invisible);
		end
	end
end
