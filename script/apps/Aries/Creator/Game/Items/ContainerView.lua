--[[
Title: base class for container view
Author(s): LiXizhi
Date: 2014/1/2
Desc: ContainerView is usually linked to a gui data source for manipulation of item slots, such as drag and drop. 
On the server side, it also manage transaction. There can be multiple entity observers for a single view. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ContainerView.lua");
local ContainerView = commonlib.gettable("MyCompany.Aries.Game.Items.ContainerView");
local cont = ContainerView:new();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemSlot.lua");
local ItemSlot = commonlib.gettable("MyCompany.Aries.Game.Items.ItemSlot");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ContainerView = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Items.ContainerView"));

function ContainerView:ctor()
	-- array of all slots
	self.slots = {};
	-- array that can be used as datasource to mcml page. it only contains data field, without inventory references.
	self.slots_ds = {}; 
	-- TODO: entities that are observing this view. 
	self.observer_entities = {};
end

-- map default view (full view)
function ContainerView:Init(inventory)
	self:UpdateFromInventory(inventory);
	return self;
end

-- @param inventory: a new inventory. If nil, it will update slot count if existing inventory's slot count changed. 
function ContainerView:UpdateFromInventory(inventory)
	if(not inventory) then
		if(self.slots[1]) then
			inventory = self.slots[1].inventory;
		end
		if(not inventory) then
			return self;
		end
	end
	local nCount = #self.slots;
	if( nCount == 0) then
		for i=1, inventory:GetSlotCount() do
			self:AddSlotToContainer(ItemSlot:new():Init(inventory, i));
		end
	else
		local nNewCount = inventory:GetSlotCount();
		if(nCount < nNewCount) then 
			for i=1, nCount do
				self:GetSlot(i):Init(inventory, i);
			end
			for i=nCount+1, nNewCount do
				self:AddSlotToContainer(ItemSlot:new():Init(inventory, i));
			end
		elseif(nCount > nNewCount) then
			for i=1, nNewCount do
				self:GetSlot(i):Init(inventory, i);
			end
			for i=nCount, nNewCount+1, -1 do
				self.slots[i] = nil;
				self.slots_ds[i] = nil;
			end
		end
	end
	return self;
end

-- The slot is assumed empty
function ContainerView:AddSlotToContainer(slot)
    slot.slotNumber = #(self.slots)+1;
    self.slots[slot.slotNumber] = slot;
	self.slots_ds[slot.slotNumber] = {slotNumber = slot.slotNumber};
    return slot;
end


-- get slot by index, this function can also be used as the ds function to pe:mc_slot
-- @param slot_index: if nil, return the total count
function ContainerView:GetSlot(slot_index)
	if(slot_index) then
		return self.slots[slot_index];
	else
		return #(self.slots);
	end
end

-- get slot by index, this function can also be used as the ds function to pe:mc_slot
-- @param slot_index: if nil, return the total count
function ContainerView:GetSlotDS(slot_index)
	if(slot_index) then
		return self.slots_ds[slot_index];
	else
		return #(self.slots);
	end
end

-- return itemStack or nil. 
function ContainerView:GetSlotItemStack(slot_index)
	local slot = self:GetSlot(slot_index)
	if(slot) then
		return slot:GetStack();
	end
end

function ContainerView:GetSlotFromInventory(inventory, slot_index)
    for i =1, #(self.slots) do
        local slot = self.slots[i];
        if (slot:IsSlotInInventory(inventory, slot_index)) then
            return slot;
        end
    end
end

-- Returns true if the player can "drag-spilt" items into this slot,. returns true by default. 
--  Called to check if the slot can be added to a list of Slots to split the held ItemStack across.
function ContainerView:CanDragIntoSlot(slot)
    return true;
end

-- move all items in the given slot to the inventory
function ContainerView:ShiftClickSlot(slot_index, count, inventory)
	if(inventory) then
		local slot = self:GetSlot(slot_index);
		if(not slot) then
			return;
		end
		local itemStack = slot:GetStack();
		if(itemStack and itemStack.count>0) then
			inventory:AddItem(itemStack);
			if(itemStack.count == 0) then
				slot:RemoveItem(0);
			end
		end
	end
end

-- @param entityPlayer: entity player. entityPlayer:GetDragItemStack()
-- @param transfer_mode: "PlayerToSlot" or "SlotToPlayer"
-- @param count: default to 1. 
-- @return itemStack that is currently dragging. 
function ContainerView:ClickSlot(slot_index, transfer_mode, count, entityPlayer)
	local dragStack = entityPlayer:GetDragItem();
	local slot = self:GetSlot(slot_index);
	if(not slot) then
		return;
	end
	local itemStack = slot:GetStack();

	if(transfer_mode == "PlayerToSlot") then
		if(dragStack) then
			if(itemStack and itemStack.count>0) then
				if(dragStack.id == itemStack.id) then
					if(dragStack:IsStackable()) then
						local newItemStack = dragStack:SplitStack(count);
						if(newItemStack) then
							slot:AddItem(newItemStack);
							dragStack.count = dragStack.count + newItemStack.count;
							
							if(dragStack.count<=0) then
								entityPlayer:SetDragItem(nil);
							end
						end
					end
				else
					-- swap items if item id differs
					local newItemStack = slot:PutStack(dragStack);
					entityPlayer:SetDragItem(newItemStack);
				end
			else
				local newItemStack = dragStack:SplitStack(count);
				if(dragStack.count<=0) then
					entityPlayer:SetDragItem(nil);
				end
				slot:PutStack(newItemStack);
			end	
		end
	elseif(transfer_mode == "SlotToPlayer") then
		if(itemStack and itemStack.count>0) then
			if(dragStack) then
				if(dragStack.id == itemStack.id) then
					if(dragStack:IsStackable() and dragStack:GetMaxStackSize() >= (dragStack.count + (count or itemStack.count))) then
						local newItemStack = slot:RemoveItem(count);
						if(newItemStack) then
							dragStack.count = dragStack.count + newItemStack.count;
						end
					end
				else
					-- do nothing
				end
			else
				local newItemStack = slot:RemoveItem(count);
				entityPlayer:SetDragItem(newItemStack);
			end
		end
	end
	return entityPlayer:GetDragItem();
end

-- static function: average inventory item fullness rounded to value between [0,15]
function ContainerView.CalcElectricPowerFromInventory(entity)
    if (not entity or not entity.inventory) then
        return 0;
    else
        local slot_count = 0;
        local item_count_avg = 0.0;
		local inventory = entity.inventory;
		for i = 1, inventory:GetSlotCount() do
			local item_stack = inventory:GetItem(i);
			if(item_stack) then
				item_count_avg = item_count_avg + item_stack.count / math.min(inventory:GetStackItemCountLimit(), item_stack:GetMaxStackSize());
				slot_count = slot_count + 1;
			end
		end
        item_count_avg = item_count_avg / inventory:GetSlotCount();
        return math.floor(item_count_avg * 14) + if_else(slot_count > 0, 1, 0);
    end
end
