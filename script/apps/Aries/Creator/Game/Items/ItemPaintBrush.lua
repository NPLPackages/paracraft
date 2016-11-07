--[[
Title: ItemPaintBrush
Author(s): LiXizhi
Date: 2017/7/20
Desc: paint with current selected pen.

Usage:
   * alt + left mouse click: pick the current mouse block.
   * +/- key or shift+mousewheel: change radius size

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemPaintBrush.lua");
local ItemPaintBrush = commonlib.gettable("MyCompany.Aries.Game.Items.ItemPaintBrush");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemTerrainBrush.lua");
local ItemTerrainBrush = commonlib.gettable("MyCompany.Aries.Game.Items.ItemTerrainBrush");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemPaintBrush = commonlib.inherit(ItemTerrainBrush, commonlib.gettable("MyCompany.Aries.Game.Items.ItemPaintBrush"));

block_types.RegisterItemClass("ItemPaintBrush", ItemPaintBrush);

-- initial pen radius
ItemPaintBrush.min_radius = 0.5;
ItemPaintBrush.max_radius = 32;

function ItemPaintBrush:ctor()
end

function ItemPaintBrush:CreateTask(itemStack)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TerrainBrush/PaintBrushTask.lua");
	local PaintBrushTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.PaintBrushTask");
	return PaintBrushTask:new():Init(self);
end

-- virtual: draw icon with given size at current position (0,0)
-- @param width, height: size of the icon
-- @param itemStack: this may be nil. or itemStack instance. 
function ItemPaintBrush:DrawIcon(painter, width, height, itemStack)
	local icon = self:GetSelectedBlockIcon(itemStack);
	if(icon) then
		painter:SetPen("#ffffff");
		painter:DrawRectTexture(0, 0, width, height, icon);
	end
	ItemPaintBrush._super.DrawIcon(self, painter, width, height, itemStack);
end