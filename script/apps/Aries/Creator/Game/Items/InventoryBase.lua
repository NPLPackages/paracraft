--[[
Title: InventoryBase
Author(s): LiXizhi
Date: 2013/12/25
Desc: Inventory for standard items. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/InventoryBase.lua");
local InventoryBase = commonlib.gettable("MyCompany.Aries.Game.Items.InventoryBase");
local item = InventoryBase:new()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemStack.lua");
local pe_mc_block = commonlib.gettable("MyCompany.Aries.Game.mcml.pe_mc_block");
local pe_mc_slot = commonlib.gettable("MyCompany.Aries.Game.mcml.pe_mc_slot");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local InventoryBase = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Items.InventoryBase"));

-- stack count limit for all slots in this inventory. 
InventoryBase.stackItemCountLimit = 64;

-- only used when we automatically pick an item. Currently only InventoryPlayer use this. 
InventoryBase.max_pick_item_count = nil;

-- @param template: icon
-- @param icon:
-- @param block_id:
function InventoryBase:ctor()
	self.slots = {};
end

-- if this entity is runing on client side and represent the current player
function InventoryBase:SetClient()
	self.isClient = true;
end

-- @param slotCount: slot count
-- @param slots: could be nil. 
function InventoryBase:Init(slotCount, slots)
	self.slotCount = slotCount or 27;
	if(slots) then
		self.slots = slots;
	end
	return self;
end

-- set the parent entity
function InventoryBase:SetParentEntity(entity)
	self.entity = entity;
end

-- set the parent entity
function InventoryBase:GetParentEntity()
	return self.entity;
end

-- check to see if bag is completely empty
function InventoryBase:IsEmpty()
	local slots = self.slots;
	for i=1, self:GetSlotCount() do
		local item = slots[i];
		if(item and item.count > 0) then
			return false;
		end
	end
	return true;
end

-- clear all inventory to empty.
-- @param from_slot_id: start from a given slot. if nil, it will search from beginning. 
function InventoryBase:Clear(from_slot_id, to_slot_id)
	local slots = self.slots;
	local count = 0;
	for i=(from_slot_id or 1), (to_slot_id or self.max_pick_item_count or self:GetSlotCount()) do
		local item = slots[i];
		if(item and item.count>0) then
			slots[i] = nil;
			count = count + 1;
		end			
	end
	if(count > 0) then
		self:OnInventoryChanged();
	end
end

-- clear items of the given count. 
-- @return the total number of items cleared
function InventoryBase:ClearItems(item_id, item_count, from_slot_id, to_slot_id)
	local count = 0;
	local slots = self.slots;
	for i=(from_slot_id or 1), (to_slot_id or self:GetSlotCount()) do
		local item = slots[i];
		if(item and item.id == item_id and item.count>0) then
			if(not item_count) then
				-- not item count. 
				slots[i] = nil;
				count = count + item.count;
			else
				item_count = item_count - item.count;
				if(item_count>=0) then
					slots[i] = nil;
					count = count + item.count;
					if(item_count == 0) then
						break;
					end
				else
					count = count + item.count + item_count;
					item.count = - item_count;
					break;
				end
			end
		end
	end
	if(count > 0) then
		self:OnInventoryChanged();
	end
	return count;
end

-- the number of slots in the inventory.
function InventoryBase:GetSlotCount()
	return self.slotCount;
end

-- set the number of slots in the inventory.
function InventoryBase:SetSlotCount(count)
	self.slotCount = count;
end

-- get item stack at given slot index
function InventoryBase:GetItem(slot_index)
	return self.slots[slot_index];
end

function InventoryBase:GetSlots()
	return self.slots;
end

-- this is usually the block in hand or the first item. 
function InventoryBase:GetCurrentItem()
	local item = self:GetItem(self:GetCurrentItemIndex());
	if(item and item.count > 0) then
		return item
	end
end

function InventoryBase:GetCurrentItemIndex()
	return 1;
end

function InventoryBase:IsFull()
	local slots = self.slots;
	for i=1, self:GetSlotCount() do
		local item = slots[i];
		if(not item or item.count == 0) then
			return false
		end
	end
	return true;
end

-- auto add item_stack to a free slot or merge with existing stack.
-- @param from_slot_id: start from a given slot. if nil, it will search from beginning. 
-- @return bAllAdded, slot_index: true if placed, false if impossible or only part of the item_stack is placed. 
function InventoryBase:AddItem(item_stack, from_slot_id, to_slot_id)
	local slots = self.slots;
	
	for i=(from_slot_id or 1), (to_slot_id or self.max_pick_item_count or self:GetSlotCount()) do
		local item = slots[i];
		if(not item or item.count == 0) then
			slots[i] = item_stack:SplitStack(nil);
			self:OnInventoryChanged(i);
			return true, i;
		elseif(item:IsSameItem(item_stack) and item:IsStackable() and item.count < self.stackItemCountLimit) then
			if( (self.stackItemCountLimit - item.count) > item_stack.count) then
				slots[i].count = slots[i].count + item_stack.count;	
				item_stack.count = 0;
				self:OnInventoryChanged(i);
				return true, i;
			else
				slots[i].count = self.stackItemCountLimit;	
				item_stack.count = item_stack.count - (self.stackItemCountLimit - item.count);
				self:OnInventoryChanged(i);
			end
		end
	end
	return false;
end

-- @return slotIndex, please note it has to be a perfect match by reference (NOT by value)
function InventoryBase:GetItemStackIndex(itemStack)
	local slots = self.slots;
	for i=1, self:GetSlotCount() do
		if(slots[i] == itemStack) then
			return i;
		end
	end
end

-- find a given item in slots. return the first one matched. 
-- @param item_id:
-- @param from_slot_id, to_slot_id: nil for begin to end
-- return itemstack, slot_index: return nil if not found. 
function InventoryBase:FindItem(item_id, from_slot_id, to_slot_id)
	local slots = self.slots;
	for i=(from_slot_id or 1), (to_slot_id or self:GetSlotCount()) do
		local item = slots[i];
		if(item and item.id == item_id and item.count>0) then
			return item, i;
		end
	end
end

-- get total item count in all stacks.
-- @param item_id: if nil, it count all items
-- @param from_slot_id: default to 1
-- @param to_slot_id: default to self:GetSlotCount()
-- @param filterFunc: can be nil, or function(itemStack) return true end. return true if item is counted. 
function InventoryBase:GetItemCount(item_id, from_slot_id, to_slot_id, filterFunc)
	local count = 0;
	local slots = self.slots;
	for i=(from_slot_id or 1), (to_slot_id or self:GetSlotCount()) do
		local item = slots[i];
		if(item and (not item_id or item.id == item_id) and item.count>0) then
			if(not filterFunc or filterFunc(item)) then
				count = count + item.count;
			end
		end
	end
	return count;
end

-- return a random item based on the total number of items in bags. 
--  Each item has equal chance.
-- @param bClone: if true, we will clone of item
-- @param filterFunc: can be nil, or function(itemStack) return true end. return true if item is counted. 
function InventoryBase:GetRandomItem(bClone, filterFunc)
	local itemStack;
	local nTotalCount = self:GetItemCount(nil, nil, nil, filterFunc);
	if(nTotalCount > 0) then
		local nIndex = math.random(1, nTotalCount);
		local nCount = 0;
		for i = 1, self:GetSlotCount() do
			local itemStack_ = self:GetItem(i);
			if(itemStack_) then
				if(not filterFunc or filterFunc(itemStack_)) then
					nCount = nCount + itemStack_.count;
					if(nIndex <= nCount) then
						itemStack = itemStack_;
						break
					end
				end
			else
				break;
			end
		end
	end
	if(itemStack) then
		if(bClone) then
			return itemStack:Copy();
		else
			return itemStack;
		end
	end
end

-- swap two items. 
function InventoryBase:SwapItem(from_slot_id, to_slot_id)
	if(from_slot_id ~= to_slot_id) then
		local from_item = self:GetItem(from_slot_id);
		local to_item = self:ReplaceItem(to_slot_id, from_item);
		self:ReplaceItem(from_slot_id, to_item);
	end
end

-- Removes from an inventory slot up to a specified count of items 
-- and returns them in a new item stack.
-- @sa ClearItems
-- @param count: if nil, it will remove all items in the given slot. 
function InventoryBase:RemoveItem(slot_index, count)
	local cur_item_stack = self.slots[slot_index];
	if (cur_item_stack) then
        local item_stack;
		if(not count) then
			count = cur_item_stack.count;
		end
        if (cur_item_stack.count <= count) then
            item_stack = cur_item_stack;
            self.slots[slot_index] = nil;
            self:OnInventoryChanged(slot_index);
            return item_stack;
        else
            item_stack = cur_item_stack:SplitStack(count);

            if (cur_item_stack.count == 0) then
                self.slots[slot_index] = nil;
           end
            self:OnInventoryChanged(slot_index);
            return item_stack;
        end
	end    
end

-- replace item at given slot index. such as armor position and crafting.
-- @param item_stack: can be nil. 
-- @return original item stack at the given position. 
function InventoryBase:ReplaceItem(slot_index, item_stack)
	local cur_item_stack = self.slots[slot_index];
	self.slots[slot_index] = item_stack;
	self:OnInventoryChanged(slot_index);
	return cur_item_stack;
end

-- name of the inventory
function InventoryBase:GetName()
	return self.name;
end

-- in most cases 64. 
function InventoryBase:GetStackItemCountLimit()
	return self.stackItemCountLimit;
end

-- Called when an the contents of an Inventory change, usually
-- @param slot_index: if only one slot is changed, this is the index. it could be nil, if index can not be determined. 
function InventoryBase:OnInventoryChanged(slot_index)
	-- TODO: invoke event listeners
	if(self.isClient) then
		pe_mc_slot.RefreshBlockIcons(self);
	end
	if(self.OnChangedCallback) then
		self.OnChangedCallback(self, slot_index);
	end
end

-- a custom user defined function for OnInventoryChanged(self, slot_index)
-- slot_index: if only one slot is changed, this is the index. it could be nil, if index can not be determined. 
function InventoryBase:SetOnChangedCallback(callbackfunc)
	self.OnChangedCallback = callbackfunc;
end

function InventoryBase:CanUseByEntity(entity)
	if(entity:GetType() == "Player") then
		return true;
	end
end

function InventoryBase:Open()
end

function InventoryBase:Close()
end

-- load from xml node without firing any on change event
function InventoryBase:LoadFromXMLNode(node)
	-- clear all 
	local slot_index, subnode = next(self.slots);
    while (slot_index) do
        self.slots[slot_index] = nil;
		slot_index, subnode = next(self.slots);
    end
	-- load from xml
	local count = 0;
	for slot_index, subnode in ipairs(node) do
		if(subnode.attr and subnode.attr.count) then
			self.slots[slot_index] = ItemStack:new():LoadFromXMLNode(subnode);
			count = slot_index;
		end
	end
	if(self:GetSlotCount() < count) then
		self:SetSlotCount(count)
	end
end

function InventoryBase:SaveToXMLNode(node, bSort)
	local last_empty;
	for i = 1, self:GetSlotCount() do
		local item = self:GetItem(i);
		if(item and item.count>0) then
			if(last_empty) then
				for j = last_empty, i-1 do
					node[#node+1] = {name="slot",};
				end
				last_empty = nil;
			end
			node[#node+1] = item:SaveToXMLNode({name="slot",}, bSort);
		else
			if(not last_empty) then
				last_empty = i;
			end
		end
	end
	return node;
end

-- returns true if item_stack can be placed to the given slot.
-- it does not check for stack limit or whether there is already item of different id. 
-- it simply checks for validity, such as player armor position. 
function InventoryBase:IsItemValidForSlot(slot_index, item_stack)
	return true;
end

-- get hand tool's bag pos index
function InventoryBase:GetHandToolIndex()
	return 1;
end

function InventoryBase:SetHandToolIndex()
end

-- given a given item in bag. 
-- @return bag_pos or nil if not exist
function InventoryBase:FindItemInBag(block_id)
	local item, slot_index = self:FindItem(block_id);
	if(item and item.count>0) then
		return slot_index;
	end
end

-- @param bag_pos:
-- @return block_id, count
function InventoryBase:GetItemByBagPos(bag_pos)
	local item = self:GetItem(bag_pos);
	if(item and item.count>0) then
		return item.id, item.count;
	end
end

-- return the block id, count in the right hand of the player. 
-- @return block_id, count
function InventoryBase:GetBlockInRightHand()
	return self:GetItemByBagPos(self:GetHandToolIndex());
end

-- return the itemStack in the right hand of the player. 
function InventoryBase:GetItemInRightHand()
	local item = self:GetItem(self:GetHandToolIndex());
	if(item and item.count > 0) then
		return item
	end
end

-- set block in right hand
function InventoryBase:SetBlockInRightHand(block_id)
	local last_block_id = self:GetBlockInRightHand();
	if(self:GetBlockInRightHand() ~= block_id) then
		local last_item = self:SetItemByBagPos(self:GetHandToolIndex(), block_id);
		if(last_item) then
			if(block_id == nil) then
				-- prevent to pick it again
				self:AddItemToInventory(last_item, self:GetHandToolIndex()+1);
			else
				self:AddItemToInventory(last_item);
			end
		end
	end
end

-- add item stack to inventory
function InventoryBase:AddItemToInventory(item_stack, from_slot)
	local isPicked, slot_index = self:AddItem(item_stack, from_slot or 1, self.max_pick_item_count);

	if(self.isClient) then
		-- self:NotifySlotChanged(slot_index, nil, item_stack.id);
	end

	return isPicked, slot_index;
end

-- set item by bag position. this is Client only function. 
function InventoryBase:SetItemByBagPos(bag_pos, block_id, count)
	if(not bag_pos) then
		return;
	end
	local last_item;
	if(not block_id or block_id == 0) then
		last_item = self:RemoveItem(bag_pos);
	else
		last_item = self:ReplaceItem(bag_pos, ItemStack:new():Init(block_id, count));
	end

	if(self.isClient) then
		local last_block_id
		if(last_item) then
			last_block_id = last_item.id
		end
			
		if(last_block_id == block_id and (not last_item or last_item.count == count)) then
			-- do nothing if nothing is changed
		else
			if(bag_pos == self:GetHandToolIndex()) then
				if(last_block_id ~= block_id) then
					--self:NotifyBlockInHandChanged(last_block_id, block_id);
				end
			end
		end
	end
	return last_item;
end
