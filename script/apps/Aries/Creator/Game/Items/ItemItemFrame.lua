--[[
Title: ItemItemFrame
Author(s): LiXizhi
Date: 2025/10/13
Desc: ItemFrame that can send code block events when interacted with in the scene.
It sends following global text event: 
    ItemFrame.selected
    ItemFrame.deselected
    ItemFrame.mousePress
    ItemFrame.mouseRelease
    ItemFrame.clicked.
They can be handled by code blocks using: 

    registerBroadcastEvent("ItemFrame.selected", function(msg)
        if(msg.name == "selected") then
            say(msg.itemStack:GetDataField("icon"));
        end
    end)
    registerBroadcastEvent("ItemFrame.deselected", function(msg)
        if(msg.name == "deselected") then
            say(nil);
        end
    end)
    registerBroadcastEvent("ItemFrame.mousePress", function(msg)
        if(msg.blockX) then
            say("you touched "..msg.blockX);
        end
        if(msg.entity) then
            say("you touched "..msg.entity.name);
        end
    end)

This allows code blocks to simulate custom scene context behavior.
Supports custom in-hand display for its icons.

@Note: if itemStack contains a icon property, the item will take over the entire scene context, 
which enable the code block to take full controll, otherwise the default BaseContext logics still apply. For example:

/take 213 {icon="Texture/radiobox.png", yourData=123}

All itemStack properties:
- display_item_id: the block/item ID to display in the item frame
- handOffsetX, handOffsetY, handOffsetZ: offset of the item frame model when held in hand
- handScaling: scaling of the item frame model when held in hand
- itemModel: if set (using x or bmax file), it will be used as the in-hand model instead of the default item frame model
- icon: if set, it will be drawn on the item frame and also take over the entire scene context

/take 213 {icon="Texture/radiobox.png", handOffsetY=0.2, handScaling=2}

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemItemFrame.lua");
local ItemItemFrame = commonlib.gettable("MyCompany.Aries.Game.Items.ItemItemFrame");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemToolBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeGlobals.lua");

local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");

local ItemItemFrame = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemToolBase"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemItemFrame"));

ItemItemFrame:Property({"allowTaskInGameMode", true, auto=true})

block_types.RegisterItemClass("ItemItemFrame", ItemItemFrame);

-- @param template: icon
function ItemItemFrame:ctor()
	self:SetOwnerDrawIcon(true);
end

-- virtual function: 
-- when selected in right hand
function ItemItemFrame:OnSelect(itemStack)
	ItemItemFrame._super.OnSelect(self, itemStack);
	
	-- Broadcast selection event to code blocks
	self:BroadcastEvent("selected", itemStack);
end

-- virtual function: 
-- when deselected in right hand
function ItemItemFrame:OnDeSelect()
	-- Broadcast unselection event to code blocks
	self:BroadcastEvent("deselected", self:GetSelectedItemStack());
	
	GameLogic.SetStatus(nil);
	ItemItemFrame._super.OnDeSelect(self);
end

-- Helper function to broadcast events to code blocks
-- @param eventName: the event name (selected, deselected, mousePress, mouseRelease, clicked)
-- @param itemStack: the item stack being used
-- @param extraData: optional extra data to include in the event
function ItemItemFrame:BroadcastEvent(eventName, itemStack, extraData)
	local codeGlobal = GameLogic.GetCodeGlobal();
    local fullEventName = "ItemFrame." .. eventName;
    local event = codeGlobal:GetTextEvent(fullEventName);
    if(event and event:HasEventListener("msg")) then
        local eventData = {
            name = eventName,
            itemStack = itemStack,
        };
        
        if(extraData) then
            for k, v in pairs(extraData) do
                eventData[k] = v;
            end
        end
        
        event:DispatchEvent({type = "msg", msg = eventData});
        return true;
    end
    return false;
end

-- Handle mouse press events
function ItemItemFrame:mousePressEvent(event)
	local itemStack = self:GetSelectedItemStack();
	local extraData = {
		button = event:button(),
		x = event.x,
		y = event.y,
		ctrl_pressed = event.ctrl_pressed,
		shift_pressed = event.shift_pressed,
		alt_pressed = event.alt_pressed,
	};
	
	-- Check if clicking on an existing item frame entity
	local result = self:CheckGetMousePick(event);
	if(result) then
		extraData.entity = result.entity;
		extraData.blockX = result.blockX;
		extraData.blockY = result.blockY;
		extraData.blockZ = result.blockZ;
		extraData.blockId = result.blockId;
	end
	
	self:BroadcastEvent("mousePress", itemStack, extraData);
    event:accept();
end

function ItemItemFrame:mouseMoveEvent(event)
    event:accept();
end

-- Handle mouse release events
function ItemItemFrame:mouseReleaseEvent(event)
	local itemStack = self:GetSelectedItemStack();
	local extraData = {
		button = event:button(),
		x = event.x,
		y = event.y,
		ctrl_pressed = event.ctrl_pressed,
		shift_pressed = event.shift_pressed,
		alt_pressed = event.alt_pressed,
		isClick = event:isClick(),
		dragDist = event:GetDragDist(),
	};
	
	-- Check if clicking on an existing item frame entity
	local result = self:CheckGetMousePick(event);
	if(result) then
		extraData.entity = result.entity;
		extraData.blockX = result.blockX;
		extraData.blockY = result.blockY;
		extraData.blockZ = result.blockZ;
        extraData.blockId = result.blockId;
	end

    local hasExternalHandler;
    if(self:BroadcastEvent("mouseRelease", itemStack, extraData)) then
        hasExternalHandler = true;
    end

    -- If it's a click (not a drag), broadcast clicked event
    if(event:isClick() and event:GetDragDist() < 10) then
        if(self:BroadcastEvent("clicked", itemStack, extraData)) then
            hasExternalHandler = true;
        end
    end
    event:accept();
end

-- when alt key is pressed to pick a block in edit mode. 
function ItemItemFrame:PickItemFromPosition(x,y,z)
	local entity = self:GetBlock():GetBlockEntity(x,y,z);
	if(entity) then
		local itemStack = ItemStack:new():Init(self.id, 1);
		local itemframe_id = entity.itemframe_id
        if(itemframe_id) then
            self:SetDisplayItemId(itemStack, itemframe_id)
        end
		return itemStack;
	end
	return ItemItemFrame._super.PickItemFromPosition(self, x,y,z);
end

-- Helper function to pick item frame entities
function ItemItemFrame:CheckGetMousePick(event)
	local result = GameLogic.SelectionManager:MousePickBlock(nil, nil, nil, nil, event and event.x, event and event.y);
	return result;
end

-- Custom in-hand display
-- @param itemStack: the item stack in hand
-- @return the display model filename, or nil for default
function ItemItemFrame:GetItemModel(itemStack)
    if(itemStack) then
        -- First check for custom item model
        local itemModel = itemStack:GetDataField("itemModel");
        if(itemModel) then
            return itemModel;
        end
        
        -- If icon is set, return nil to use 3D block image rendering
        if(self:HasCustomIcon(itemStack)) then
            return nil;
        end
    end
    
    -- Return the default item frame model for in-hand display
    return "model/blockworld/ItemFrame/ItemFrame.x";
end

-- Custom in-hand model offset
function ItemItemFrame:GetItemModelInHandOffset(itemStack)
	-- Get custom offsets from item stack data fields
	local offsetX = itemStack and itemStack:GetDataField("handOffsetX");
	local offsetY = itemStack and itemStack:GetDataField("handOffsetY")
	local offsetZ = itemStack and itemStack:GetDataField("handOffsetZ")
    if(offsetX or offsetY or offsetZ) then
        return {x = offsetX or 0, y = offsetY or 0, z = offsetZ or 0};
    else
        return ItemItemFrame._super.GetItemModelInHandOffset(self, itemStack);
    end
end

-- item scaling when hold in hand. 
function ItemItemFrame:GetItemModelScaling(itemStack)
	if(itemStack) then
		local scaling = itemStack:GetDataField("handScaling");
		if(scaling) then
            return scaling;
        end
    end
    return ItemItemFrame._super.GetItemModelScaling(self, itemStack);
end

-- Get the item to display in the item frame from item stack
-- @param itemStack: the ItemItemFrame's item stack
-- @return the block/item ID to display, or nil
function ItemItemFrame:GetDisplayItemId(itemStack)
	if(itemStack) then
		return itemStack:GetDataField("display_item_id");
	end
end

-- Set the item to display in the item frame
-- @param itemStack: the ItemItemFrame's item stack
-- @param displayItemId: the block/item ID to display
function ItemItemFrame:SetDisplayItemId(itemStack, displayItemId)
	if(itemStack) then
		itemStack:SetDataField("display_item_id", displayItemId);
	end
end

-- Get tooltip with display item info
function ItemItemFrame:GetTooltipFromItemStack(itemStack)
	local tooltip = ItemItemFrame._super.GetTooltipFromItemStack(self, itemStack);
	
	local displayItemId = self:GetDisplayItemId(itemStack);
	if(displayItemId) then
		local displayItem = ItemClient.GetItem(displayItemId);
		if(displayItem) then
			tooltip = tooltip .. "\n" .. L"展示: " .. displayItem:GetDisplayName();
		end
	end
	
	return tooltip;
end

function ItemItemFrame:GetIcon(itemStack)
    local icon = itemStack and itemStack:GetDataField("icon");
    if(not icon) then
        -- Draw the display item if any
        local displayItemId = self:GetDisplayItemId(itemStack);
        if(displayItemId) then
            local displayItem = ItemClient.GetItem(displayItemId);
            if(displayItem) then
                icon = displayItem:GetIcon();
            end
        end
    end
    return icon or ItemItemFrame._super.GetIcon(self, itemStack);
end

function ItemItemFrame:HasCustomIcon(itemStack)
    local icon = itemStack and itemStack:GetDataField("icon");
    return icon ~= nil;
end


-- Override drawing to show the contained item
-- @param painter: the painter object
-- @param x, y, width, height: the drawing area
function ItemItemFrame:DrawIcon(painter, width, height, itemStack)
	if(not painter or not itemStack) then
		return;
	end
	
    local icon = itemStack and itemStack:GetDataField("icon");
    if(not icon) then
        -- Draw the display item if any
        local displayItemId = self:GetDisplayItemId(itemStack);
        if(displayItemId) then
            local displayItem = ItemClient.GetItem(displayItemId);
            if(displayItem) then
                icon = displayItem:GetIcon();
            end
        end
    end
	
    if(icon) then
        painter:SetPen("#ffffff");
        painter:DrawRect(0, 0, width, height);

        -- Draw the item icon in the center, slightly smaller
        local padding = width * 0.15;
        painter:DrawRectTexture(padding, padding, 
            width - padding * 2, height - padding * 2, icon);
    else
        -- Draw the base frame
	    ItemItemFrame._super.DrawIcon(self, painter, width, height, itemStack);
	end
end

-- Try to create/place an item frame in the world
-- @param itemStack: the item stack being placed
-- @param entityPlayer: the player entity placing the item
-- @param x,y,z: block coordinates
-- @param side: which face of the block was clicked
-- @param data: block data value
-- @param side_region: region within the face that was clicked
-- @return true if successfully created
function ItemItemFrame:TryCreate(itemStack, entityPlayer, x, y, z, side, data, side_region)
    -- First try to create the block
    local res = ItemItemFrame._super.TryCreate(self, itemStack, entityPlayer, x, y, z, side, data, side_region);
    
    if(res) then
        -- If block was created successfully, set up the entity with display item
        local displayItemId = self:GetDisplayItemId(itemStack);
        if(displayItemId) then
            local entity = self:GetBlock():GetBlockEntity(x, y, z);
            if(entity and entity:isa(EntityManager.EntityItemFrame)) then
                entity.itemframe_id = displayItemId;
                entity:Refresh()
            end
        end
    end
    
    return res;
end

-- virtual: create the task when this item is selected
function ItemItemFrame:CreateTask(itemStack)
    if(itemStack and itemStack:GetDataField("icon")) then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ItemFrameTask.lua");
        local ItemFrameTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.ItemFrameTask");
        local task = ItemFrameTask:new();
        task:SetItemStack(itemStack);
        return task;    
    end
end