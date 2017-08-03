--[[
Title: InventoryPlayer
Author(s): LiXizhi
Date: 2013/12/25
Desc: Inventory for Player entity.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/InventoryPlayer.lua");
local InventoryPlayer = commonlib.gettable("MyCompany.Aries.Game.Items.InventoryPlayer");
local item = InventoryPlayer:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/InventoryBase.lua");
local pe_mc_block = commonlib.gettable("MyCompany.Aries.Game.mcml.pe_mc_block");
local pe_mc_slot = commonlib.gettable("MyCompany.Aries.Game.mcml.pe_mc_slot");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");


local InventoryPlayer = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.InventoryBase"), commonlib.gettable("MyCompany.Aries.Game.Items.InventoryPlayer"));

-- the total slot is 40. another 4 for crafting table
InventoryPlayer.max_pick_item_count = 36;

-- @param template: icon
-- @param icon:
-- @param block_id:
function InventoryPlayer:ctor()
end

function InventoryPlayer:LoadFromXMLNode(node)
	if(node.attr) then
		self.handtool_bagpos = tonumber(node.attr.handtool_bagpos) or 1;
	end
	return InventoryPlayer._super.LoadFromXMLNode(self, node);
end

function InventoryPlayer:SaveToXMLNode(node, bSort)
	node.attr = node.attr or {};
	node.attr.handtool_bagpos = self.handtool_bagpos or 1;

	return InventoryPlayer._super.SaveToXMLNode(self, node, bSort);
end

-- the number of slots in the inventory.
function InventoryPlayer:GetSlotCount()
	return 40;
end

-- @param bag_pos:
-- @return block_id, count
function InventoryPlayer:GetItemByBagPos(bag_pos)
	local item = self:GetItem(bag_pos);
	if(item and item.count>0) then
		return item.id, item.count;
	end
end

-- return the block index in the right hand of the player. 
function InventoryPlayer:GetBlockInRightHand()
	return self:GetItemByBagPos(self:GetHandToolIndex());
end

-- return the itemStack in the right hand of the player. 
function InventoryPlayer:GetItemInRightHand()
	local item = self:GetItem(self:GetHandToolIndex());
	if(item and item.count > 0) then
		return item
	end
end

function InventoryPlayer:GetCurrentItemIndex()
	return self:GetHandToolIndex();
end

-- set block in right hand
-- @param blockid_or_item_stack:  block_id or ItemStack object. 
function InventoryPlayer:SetBlockInRightHand(blockid_or_item_stack)
	local block_id, count, item_stack;
	if(type(blockid_or_item_stack) == "table") then
		block_id, count = blockid_or_item_stack.id, blockid_or_item_stack.count;
		item_stack = blockid_or_item_stack;
	else
		block_id = blockid_or_item_stack;
	end

	local bIsSameItem = false;
	if(item_stack) then
		local item = item_stack:GetItem();
		if(item and item:CompareItems(item_stack, self:GetItemInRightHand())) then
			bIsSameItem = true;
		end
	else
		bIsSameItem = self:GetBlockInRightHand() == block_id;
	end
			
	if(not bIsSameItem) then
		local lastIndex = self:GetHandToolIndex();
		local last_item = self:SetItemByBagPos(lastIndex, block_id, count, item_stack);
		if(last_item) then
			-- we will only insert it to blocks after the current index, to prevent a full inventory to pick the block at the old position.
			self:AddItemToInventory(last_item, lastIndex+1);
		end
	end
end

-- get hand tool's bag pos index
function InventoryPlayer:GetHandToolIndex()
	return self.handtool_bagpos or 1;
end

-- whether the inventory belongs to the current main player in control.
function InventoryPlayer:IsMainPlayer()
	return EntityManager.GetPlayer() == self:GetParentEntity();
end

-- Called when an the contents of an Inventory change, usually
-- @param slot_index: if only one slot is changed, this is the index. it could be nil, if index can not be determined. 
function InventoryPlayer:OnInventoryChanged(slot_index)
	InventoryPlayer._super.OnInventoryChanged(self);
	if(self:IsMainPlayer()) then
		if(not slot_index) then
			if(self.last_block_inhand_id ~= self:GetBlockInRightHand()) then
				self:NotifyBlockInHandChanged(self.last_block_inhand_id, self:GetBlockInRightHand());
			end
		elseif(slot_index == self:GetHandToolIndex()) then
			self:NotifyBlockInHandChanged(self.last_block_inhand_id, self:GetBlockInRightHand());
		end
	end
end

-- only used on client side's main player
function InventoryPlayer:NotifySlotChanged(slot_index, last_item_id, item_id)
	if(self:IsMainPlayer()) then
		if(slot_index == self:GetHandToolIndex()) then
			self:NotifyBlockInHandChanged(last_item_id, item_id);
		end
	elseif(GameLogic.isServer and self.entity and self.entity.SendPacketToPlayer) then
		-- this is on server, notify client of inventory changes. 
		self.entity:SendPacketToPlayer(Packets.PacketPlayerInventory:new():Init(self.entity.entityId, slot_index, self:GetItem(slot_index)));
	end
end

-- only used on client side's main player
-- @param last_block_id, block_id: if both nil, it means that last block id is not trackable. 
function InventoryPlayer:NotifyBlockInHandChanged(last_block_id, block_id)
	if(self:IsMainPlayer()) then
		self.last_block_inhand_id = block_id;
		if(last_block_id and last_block_id>0) then
			local item = ItemClient.CreateGetByBlockID(last_block_id);
			item:OnDeSelect();
		end
		if(block_id and block_id>0) then
			local item = ItemClient.CreateGetByBlockID(block_id);
			local itemStack = self:GetItemInRightHand();
			if(not itemStack or itemStack.id ~= block_id) then
				itemStack = nil;
			end
			item:OnSelect(itemStack);
		end
		EntityManager.GetPlayer():RefreshRightHand();
		GameLogic.events:DispatchEvent({type = "SetBlockInRightHand" , block_id = block_id, last_block_id=last_block_id});
	end
end

-- set the hand tool bag pos index
function InventoryPlayer:SetHandToolIndex(nIndex)
	nIndex = nIndex or 1;
	if(nIndex > 9) then
		nIndex = 9;
	end
	if(nIndex < 1) then
		nIndex = 1;
	end
	if(self.isClient and self:IsMainPlayer()) then
		local last_block_id = self:GetBlockInRightHand();
		if(nIndex~=self.handtool_bagpos) then
			self.last_handtool_bagpos = self.handtool_bagpos;
			self.handtool_bagpos = nIndex;
			GameLogic.events:DispatchEvent({type = "OnHandToolIndexChanged" , bagpos = nIndex,});

			local block_id = self:GetBlockInRightHand();
			self:NotifyBlockInHandChanged(last_block_id, block_id);
		elseif(nIndex==self.handtool_bagpos) then
			-- this is a click event even through th block is not actually changed
			GameLogic.events:DispatchEvent({type = "SetBlockInRightHand" , block_id = last_block_id, last_block_id = last_block_id});
		end
	end
end

-- take the given item in hand and equip it. 
-- it is slightly different from SetBlockInRightHand
function InventoryPlayer:EquipSingleItem(block_id)
	local bag_pos = self:FindItemInBag(block_id);
	if(bag_pos) then
		self:SwapItem(bag_pos, self:GetHandToolIndex())
	else
		self:SetBlockInRightHand(block_id);
	end
end

-- set item by bag position. this is Client only function. 
-- @param block_id, count: 
-- @param item_stack: if available, block_id and count will be ignored. 
function InventoryPlayer:SetItemByBagPos(bag_pos, block_id, count, item_stack)
	if(not bag_pos) then
		return;
	end
	if(item_stack) then
		block_id, count = item_stack.id, item_stack.count;
	end
	local last_item;
	if(not block_id or block_id == 0) then
		last_item = self:RemoveItem(bag_pos);
	else
		last_item = self:ReplaceItem(bag_pos, item_stack or ItemStack:new():Init(block_id, count));
	end

	if(self.isClient and self:IsMainPlayer()) then
		local last_block_id
		if(last_item) then
			last_block_id = last_item.id
		end
			
		if(last_block_id == block_id and (not last_item or last_item.count == count)) then
			-- do nothing if nothing is changed
		else
			if(bag_pos == self:GetHandToolIndex()) then
				if(last_block_id ~= block_id) then
					self:NotifyBlockInHandChanged(last_block_id, block_id);
				end
			end
		end
	end
	return last_item;
end

-- pick a given block. Use AddItemToInventory instead
-- @return true: if already exist or successfully picked. false if bag is full. 
function InventoryPlayer:PickBlock(block_id, ignore_bagpos)
	if(not block_id) then
		return;
	end
	local block_item = ItemClient.GetItem(block_id);
	if(not block_item) then
		return;
	end
	return self:AddItemToInventory(ItemStack:new():Init(block_id, 1));
end


-- add item stack to inventory
function InventoryPlayer:AddItemToInventory(item_stack, from_slot_id)
	local isPicked, slot_index = self:AddItem(item_stack, from_slot_id, self.max_pick_item_count);

	self:NotifySlotChanged(slot_index, nil, item_stack.id);
	return isPicked, slot_index;
end

-- take the specified number of items from the given slot_index and return it. 
-- @param count: if nil, it will take all. 
function InventoryPlayer:RemoveItem(slot_index, count)
	local throwed_item = InventoryPlayer._super.RemoveItem(self, slot_index, count);
	if(throwed_item) then
		self:NotifySlotChanged(slot_index, throwed_item.id, nil);
		return throwed_item;
	end
end

