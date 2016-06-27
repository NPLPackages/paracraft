--[[
Title: Slot
Author(s): LiXizhi
Date: 2014/1/1
Desc: a slot represents a single inventory bag position. We will create slots only when opening certain GUI
such as bag or chest. A ContainerView is created as a container of slots. Users can drag and drop items between slots. 
mcml tag pe_mc_block is usually used for GUI composing. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemSlot.lua");
local ItemSlot = commonlib.gettable("MyCompany.Aries.Game.Items.ItemSlot");
local slot = ItemSlot:new():Init(inventory, 1);
-------------------------------------------------------
]]
local ItemSlot = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Items.ItemSlot"));

function ItemSlot:ctor()
end

function ItemSlot:Init(inventory, slot_index)
	-- The index of the slot in the inventory.
	self.slotIndex = slot_index;
	-- The inventory we want to extract a slot from.
	self.inventory = inventory;
	-- the index in the ContainerView, assigned automatically when adding to ContainerView
    -- self.slotNumber;
	return self;
end

-- Check if the stack is a valid item for this slot. 
function ItemSlot:IsItemValid(item_stack)
    return true;
end

-- get the stack in the slot.
function ItemSlot:GetStack()
    return self.inventory:GetItem(self.slotIndex);
end

-- Returns if this slot contains a stack.
function ItemSlot:HasStack()
    return self:GetStack();
end

-- put a stack in the slot.
function ItemSlot:PutStack(item_stack)
    local oldItemStack = self.inventory:ReplaceItem(self.slotIndex, item_stack);
    self:OnSlotChanged();
	return oldItemStack;
end

-- Called when the stack in a Slot changes
function ItemSlot:OnSlotChanged()
    self.inventory:OnInventoryChanged();
end

-- Returns the maximum stack size for a given slot 
function ItemSlot:GetSlotStackLimit()
    return self.inventory:GetStackItemCountLimit();
end

-- Decrease the size of the stack in slot by the amount of count. Returns the new stack.
function ItemSlot:RemoveItem(count)
    return self.inventory:RemoveItem(self.slotIndex, count);
end

-- only possible when item in slot is same kind of input item stack.
function ItemSlot:AddItem(itemStack)
	return self.inventory:AddItem(itemStack, self.slotIndex, self.slotIndex);
end

-- returns true if this slot is in inventory's slot_index
function ItemSlot:IsSlotInInventory(inventory, slot_index)
    return inventory == self.inventory and slot_index == self.slotIndex;
end

-- Return whether this slot's stack can be taken from this slot.
function ItemSlot:CanTakeStack(entity)
    return true;
end