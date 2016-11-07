--[[
Title: ItemTerrainBrush
Author(s): LiXizhi
Date: 2016/7/16
Desc: paint with current selected pen.

Usage:
   * alt + left mouse click: pick the current mouse block.
   * +/- key or shift+mousewheel: change radius size

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemTerrainBrush.lua");
local ItemTerrainBrush = commonlib.gettable("MyCompany.Aries.Game.Items.ItemTerrainBrush");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemToolBase.lua");
local ItemToolBase = commonlib.gettable("MyCompany.Aries.Game.Items.ItemToolBase");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemTerrainBrush = commonlib.inherit(ItemToolBase, commonlib.gettable("MyCompany.Aries.Game.Items.ItemTerrainBrush"));

ItemTerrainBrush:Property({"pen_radius", 5, "GetPenRadius", "SetPenRadius"})
ItemTerrainBrush:Property({"brush_strength", nil, "GetBrushStrength", "SetBrushStrength"})
ItemTerrainBrush:Property({"selected_blockid", 56, "GetSelectedBlockId", "SetSelectedBlockId"})
ItemTerrainBrush:Property({"selected_blockdata", nil, "GetSelectedBlockData", "SetSelectedBlockData"})

block_types.RegisterItemClass("ItemTerrainBrush", ItemTerrainBrush);

-- initial pen radius
ItemTerrainBrush.min_radius = 2;
ItemTerrainBrush.max_radius = 32;

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemTerrainBrush:ctor()
	self:SetOwnerDrawIcon(true);
end

-- @param itemStack: if nil it is current selected one
function ItemTerrainBrush:GetSelectedBlockIcon(itemStack)
	local block_id = self:GetSelectedBlockId(itemStack) or 56;
	local item = ItemClient.GetItem(block_id);
	if(item) then
		return item:GetIcon();
	end
end

-- @param itemStack: if nil it is current selected one
function ItemTerrainBrush:GetSelectedBlockId(itemStack)
	itemStack = itemStack or self:GetCurrentItemStack()
	return itemStack and itemStack:GetDataField("selected_blockid") or self.selected_blockid;
end

function ItemTerrainBrush:SetSelectedBlockId(selected_blockid)
	local itemStack = self:GetCurrentItemStack()
	return itemStack and itemStack:SetDataField("selected_blockid", selected_blockid);
end

function ItemTerrainBrush:GetBrushStrength()
	local itemStack = self:GetCurrentItemStack()
	return itemStack and itemStack:GetDataField("brush_strength") or self.brush_strength;
end

function ItemTerrainBrush:SetBrushStrength(brush_strength)
	local itemStack = self:GetCurrentItemStack()
	return itemStack and itemStack:SetDataField("brush_strength", brush_strength);
end

function ItemTerrainBrush:GetSelectedBlockData()
	local itemStack = self:GetCurrentItemStack()
	return itemStack and itemStack:GetDataField("selected_blockdata") or self.selected_blockdata;
end

function ItemTerrainBrush:SetSelectedBlockData(selected_blockdata)
	local itemStack = self:GetCurrentItemStack()
	return itemStack and itemStack:SetDataField("selected_blockdata", selected_blockdata);
end

function ItemTerrainBrush:GetPenRadiusInItem(itemStack)
	if(itemStack) then
		local pen_radius = itemStack:GetDataField("pen_radius") or self.pen_radius;
		return math.floor(pen_radius+0.5);
	else
		return self.pen_radius;
	end
end

function ItemTerrainBrush:GetPenRadius()
	local itemStack = self:GetCurrentItemStack()
	return self:GetPenRadiusInItem(itemStack);
end

function ItemTerrainBrush:SetPenRadius(radius)
	local pen_radius = self:GetPenRadius();
	if(radius~=pen_radius) then
		radius = (radius > pen_radius) and (pen_radius+1) or (pen_radius - 1);
	end
	if(radius~=pen_radius) then
		local itemStack = self:GetCurrentItemStack()
		if(itemStack) then
			local pen_radius = math.max(math.min(radius, self.max_radius), self.min_radius);
			itemStack:SetDataField("pen_radius", pen_radius);
			self:valueChanged();
		end
	end
end

-- virtual function: called when user clicked some other item while holding this item in hand.
-- @return true will cause other item to ignore the click event. This is useful when the hand block needs to process click event itself
function ItemTerrainBrush:HandleClickOtherItem(other_item_id)
	if(other_item_id) then
		local block_template = block_types.get(other_item_id);
		if(block_template and (block_template.solid or block_template.liquid or block_template.cubeMode)) then
			self:SetSelectedBlockId(other_item_id);
			return true;
		end
	end
end

-- virtual: draw icon with given size at current position (0,0)
-- @param width, height: size of the icon
-- @param itemStack: this may be nil. or itemStack instance. 
function ItemTerrainBrush:DrawIcon(painter, width, height, itemStack)
	ItemTerrainBrush._super.DrawIcon(self, painter, width, height, itemStack);
	painter:SetPen("#ffff00");
	painter:DrawText(1,1, tostring(self:GetPenRadiusInItem(itemStack)));
end

-- virtual function: 
function ItemTerrainBrush:CreateTask(itemStack)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TerrainBrush/TerrainBrushTask.lua");
	local TerrainBrushTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.TerrainBrushTask");
	return TerrainBrushTask:new():Init(self);
end