--[[
Title: Item entity
Author(s): LiXizhi
Date: 2013/7/14
Desc: Item is an icon x count in the bag or quick launch bar. It usually has a use function. 
This is the base class, but it also handle all visible blocks [0-256). blocks with id > 1000, are special item blocks.

virtual functions for derived classes:
	event(event): handle all kinds of system events
	mousePressEvent(event)
	mouseMoveEvent
	mouseReleaseEvent
	mouseWheelEvent
	keyPressEvent
	keyReleaseEvent : not implemented
	OnActivate(itemStack, entity)
	handleEntityEvent(itemStack, entity, event)

	OnClick
	TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
	PickItemFromPosition
	CompareItems

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/Item.lua");
local Item = commonlib.gettable("MyCompany.Aries.Game.Items.Item");
local item_ = Item:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/GameMode.lua");
NPL.load("(gl)script/ide/System/Core/Color.lua");
NPL.load("(gl)script/ide/math/bit.lua");
local Color = commonlib.gettable("System.Core.Color");
local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");
local ObjEditor = commonlib.gettable("ObjEditor");
local Image3DDisplay = commonlib.gettable("MyCompany.Aries.Game.Effects.Image3DDisplay");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

local Item = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Items.Item"));

-- whether to draw the icon with DrawIcon virtual function. 
Item:Property({"m_bIsOwnerDrawIcon", false, "IsOwnerDrawIcon", "SetOwnerDrawIcon", auto=true})
Item:Property({"IconColor", "#ffffff", auto=true})

Item.mouseTracking = false;
-- texture altas size of item/block icons
Item.icon_atlas_size = 512;
-- icon size in icon texture atlas
Item.icon_size= 32;


-- @param template: icon
-- @param icon:
-- @param block_id:
function Item:ctor()
	self.gold_count = tonumber(self.gold_count);
	self.max_count = tonumber(self.max_count);
	self.id = self.id or self.block_id;
	self.block_id = self.block_id or self.id;
	if(self:HasColorData()) then
		self:SetOwnerDrawIcon(true);
	end
end

function Item:GetMaxCount()
	return self.max_count or 64;
end

-- get block template. 
function Item:GetBlock()
	return block_types.get(self.block_id);
end

-- static function:
-- get item current selected item stack
function Item:GetSelectedItemStack()
	return EntityManager.GetPlayer() and EntityManager.GetPlayer():GetItemInRightHand();
end

 -- Called whenever this item is equipped and the right mouse button is pressed.
-- @return itemStack, hasHandled:  the new item stack to put in the position. hasHandled is true if handled. 
function Item:OnItemRightClick(itemStack, entityPlayer)
    return itemStack, false;
end

-- virtual function, called when world is closed. 
function Item:OnLeaveWorld()
end

-- called whenever this item is clicked on the user interface when it is holding in hand of a given player (current player). 
-- by default, if there is selected blocks, we will replace selection with current block in hand. 
function Item:OnClickInHand(itemStack, entityPlayer)
	if(GameLogic.GameMode:IsEditor() and entityPlayer == EntityManager.GetPlayer()) then
		local selected_blocks = Game.SelectionManager:GetSelectedBlocks();
		if(selected_blocks) then
			if(self.id>0 and self.id < 1000) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ReplaceBlockTask.lua");
				local task = MyCompany.Aries.Game.Tasks.ReplaceBlock:new({blocks = commonlib.clone(selected_blocks), to_id = self.id, to_data=nil})
				task:Run();
			end
		end
	end
end

-- virtual function: called when user clicked some other item while holding this item in hand.
-- @return true will cause other item to ignore the click event. This is useful when the hand block needs to process click event itself
function Item:HandleClickOtherItem(other_item_id)
	-- return true;
end

-- virtual: click from user interface
function Item:OnClick()
	local block_id = self.id;
	if(self.CreateAtPlayerFeet) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateBlockTask.lua");
		local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({block_id = block_id})
		task:Run();
	end

	if(self.auto_equip) then
		
	else
		local hand_block_id = GameLogic.GetBlockInRightHand();
		if(hand_block_id and hand_block_id>0) then
			local hand_item = ItemClient.GetItem(hand_block_id);
			if(hand_item and hand_item:HandleClickOtherItem(block_id)) then
				return;
			end
		end
		-- normal block
		if(GameMode:IsUseCreatorBag()) then
			if(self.block_data or self.server_data) then
				local item = ItemStack:new():Init(block_id, 1, self.server_data);
				item:SetPreferredBlockData(self.block_data)
				GameLogic.SetBlockInRightHand(item);
			else
				GameLogic.SetBlockInRightHand(block_id);
			end
		else
			EntityManager.GetPlayer().inventory:PickBlock(block_id);
		end
	end
end

-- called when this function is activated when the entity is activated. 
-- it will return false when the last trigger entity's inventory has more than itemStack.count items. 
-- @param itemStack: the containing itemStack
-- @param entity: this is usually a command block or entity that contains this entity. 
-- @param entityPlayer: the triggering entity
-- @return false if the entity should stop activating other items in its bag. 
function Item:OnActivate(itemStack, entityContainer, entityTrigger)
	local trigger_entity = EntityManager.GetLastTriggerEntity();
	if(trigger_entity and trigger_entity.inventory) then
		if((trigger_entity.inventory:GetItemCount(itemStack.id)>=itemStack.count)) then
			return true;
		end
	end
	return false;
end

-- called when entity receives a custom event via one of its rule bag items. 
function Item:handleEntityEvent(itemStack, entity, event)
end

-- whether the item can be spawned using spawn command. 
function Item:CanSpawn()
	return false;
end

-- whether we can create item at given block position.
-- only basic check is performed. such as:  
-- we allow any block(except liquid) to create on empty or liquid block.
function Item:CanCreateItemAt(x,y,z)
	local cur_block = BlockEngine:GetBlock(x,y,z);
	local block_template = block_types.get(self.block_id);
	if(not cur_block or (cur_block.material:isLiquid() and (block_template and not block_template.material:isLiquid()))) then
		return true;
	end
end

-- max durability. nil for infinite (not damagable). 
function Item:GetMaxDamage()
	return;
end

-- Returns true if players can use this item to affect the world (e.g. placing blocks, placing ender eyes in portal)
function Item:CanItemEditBlocks()
	return true;
end

-- called when this item is used and deal 2 damage to the item's durability. 
function Item:OnUseItem(itemStack, fromEntity)
	if(itemStack) then
		itemStack:DamageItem(2, fromEntity)
	end
end

-- Returns true if the given Entity can be placed on the given side of the given block position.
-- @param x,y,z: this is the position where the block should be placed
-- @param side: this is the OPPOSITE of the side of contact. 
function Item:CanPlaceOnSide(x,y,z,side, data, side_region, entityPlayer, itemStack)
	
    if (not EntityManager.CheckNoEntityCollision(x,y,z, entityPlayer)) then
        return false;
    else
		local block_template = block_types.get(self.block_id);
		local cur_block = BlockEngine:GetBlock(x,y,z);

		if(not cur_block or (cur_block.material:isLiquid() and (block_template and not block_template.material:isLiquid())) or 
			cur_block.material:isReplaceable()) then

			if(not block_template or block_template:canPlaceBlockOnSide(x,y,z,side)) then
				return true;
			end
        end
    end
end

-- Right clicking in 3d world with the block in hand will trigger this function. 
-- Alias: OnUseItem;
-- @param itemStack: can be nil
-- @param entityPlayer: can be nil
-- @param side: this is OPPOSITE of the touching side
-- @return isUsed, entityCreated: isUsed is true if something happens.
function Item:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
	if (itemStack and itemStack.count == 0) then
		return;
	elseif (entityPlayer and not entityPlayer:CanPlayerEdit(x,y,z, data, itemStack)) then
		return;
	elseif (self:CanPlaceOnSide(x,y,z,side, data, side_region, entityPlayer, itemStack)) then
		-- 4096 is hard coded
		if(self.id and self.id > 4096) then
			if(not self.max_count or self:GetInWorldCount() < self.max_count) then
				local facing;
				if(self:HasFacing()) then
					facing =  ParaScene.GetPlayer():GetFacing();
				end
				local bCreated, entityCreated = self:OnCreate({blockX = x, blockY = y, blockZ = z, facing = facing, side=side, itemStack = itemStack});
				if(bCreated and itemStack) then
					itemStack.count = itemStack.count - 1;
				end
				return true, entityCreated;
			else
				if(self.max_count == 1) then
					-- move it if there is only one. 
					local entities = EntityManager.GetEntitiesByItemID(self.id);
					if(entities) then
						entities[1]:SetBlockPos(x,y,z);
					else
						self:OnCreate({blockX = x, blockY = y, blockZ = z, facing = 0, side=side});
					end
					return true;
				else
					_guihelper.MessageBox(string.format("世界中最多可以放置%d个[%s]. 已经超出上限", self.max_count or 0,  self.text or ""));
				end
			end
		else
			local block_id = self.block_id;
			local block_template = block_types.get(block_id);

			if(block_template) then
				if(not data) then
					data = block_template:GetMetaDataFromEnv(x, y, z, side, side_region);
					data = block_template:CalculatePreferredData(data, itemStack and itemStack:GetPreferredBlockData());
				end

				if(BlockEngine:SetBlock(x, y, z, block_id, data, 3)) then
					block_template:play_create_sound();

					block_template:OnBlockPlacedBy(x,y,z, entityPlayer);
					if(itemStack) then
						itemStack.count = itemStack.count - 1;
					end
				end
				return true;
			end
		end
	end
end


-- virtual function:
-- @param result: picking result. {block_id, blockX, blockY, blockZ}
-- @return: return true if created
function Item:OnCreate(result)
end

-- static function
-- get Icon texture altas
function Item:GetIconAtlas()
	if(not Item.icon_atlas) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/TextureAtlas.lua");
		local TextureAtlas = commonlib.gettable("MyCompany.Aries.Game.blocks.TextureAtlas")
		Item.icon_atlas = TextureAtlas:new():init("block_icon_atlas", Item.icon_atlas_size, Item.icon_atlas_size, Item.icon_size);
		GameLogic:Connect("texturePackChanged", Item.icon_atlas, Item.icon_atlas.RefreshAllBlocks, "UniqueConnection");
		--GameLogic:Connect("WorldLoaded", Item.icon_atlas, Item.icon_atlas.MakeDirty, "UniqueConnection");
		GameLogic:Connect("WorldLoaded", Item.icon_atlas, Item.icon_atlas.RefreshAllBlocks, "UniqueConnection");
	end
	return Item.icon_atlas;
end

-- @param block_data: default to nil
function Item:GetIcon(block_data)
	local needGenerate = not self.icon_generated;
	if(block_data and block_data~=0) then
		self.icons_generated = self.icons_generated or {};
		if(not self.icons_generated[block_data]) then
			self.icons_generated[block_data] = true;
			needGenerate = true;
		end
	end

	if(needGenerate) then
		self.icon_generated = true;
		if(not self.disable_gen_icon) then
			local model_filename = self:GetItemModel();	
			if(model_filename and model_filename ~= "icon") then
				-- only add block with real models. 
				local atlas = self:GetIconAtlas();
				if(self.block_id and self.block_id>0 and self.block_id < 4096) then
					local region = atlas:AddRegionByBlockId(self.block_id, block_data);
					if(region) then
						if(block_data and block_data~=0) then
							self.icons_generated[block_data] = region:GetTexturePath();
						else
							self.icon = region:GetTexturePath();
						end
					end
				end
			end
		end
	end
	
	if(block_data and block_data~=0) then
		local icon = self.icons_generated[block_data];
		if(type(icon) == "string") then
			return icon;
		end
	end
	if(self.icon) then
		return self.icon;
	else
		local block_template = block_types.get(self.block_id);
		if(block_template) then
			return block_template:GetIcon();
		end
	end
	return "";
end

-- get the primary texture file for this item. 
function Item:GetTexture()
	local block_template = block_types.get(self.block_id);
	if(block_template) then
		return block_template:GetTexture();
	else
		return self:GetIcon();
	end
end

-- @return ParaAsset icon
function Item:GetIconObject()
	if(self.icon_obj~=nil) then
		return self.icon_obj;
	else
		local icon = self:GetIcon();
		if(icon and icon~="") then
			self.icon_obj = ParaAsset.LoadTexture("", icon, 1);
			return self.icon_obj;
		else
			self.icon_obj = false;
			return false;
		end
	end
end

-- get the primary asset file
function Item:GetAssetFile()
	if(self.filename) then
		return self.filename;
	elseif(self.models) then
		return self.models[1].assetfile;
	end
end

-- get skin 
function Item:GetSkinFile()
	if(self.skin) then
		return self.skin;
	elseif(self.models) then
		return self.models[1].skin;
	end
end

function Item:GetTooltipFromItemStack(itemStack)
	local text = self:GetTooltip();
	if(self:HasColorData()) then
		local data = itemStack:GetPreferredBlockData();
		if(data) then
			return string.format("%s Color:#%06x", text or "", self:DataToColor(data));
		end
	end
	return text;
end

function Item:GetOffsetY()
	if(self.offset_y) then
		return self.offset_y;
	elseif(self.models) then
		return self.models[1].offset_y or 0;
	end
	return 0;
end

function Item:GetScaling()
	if(self.scaling) then
		return self.scaling;
	elseif(self.models) then
		return self.models[1].scaling;
	end
end

function Item:HasFacing()
end

function Item:GetTooltip()
	if(self.tooltip) then
		return self.tooltip;
	else
		local block_template = block_types.get(self.block_id);
		if(block_template) then
			self.tooltip = block_template:GetTooltip() or "";
		else
			self.tooltip = ""
		end
		return self.tooltip;
	end
end

-- virtual function: try to get block data from itemStack. 
-- in most cases, this return nil
-- @return nil or a number 
function Item:GetBlockData(itemStack)
end

-- virtual function: try to get block entity data from itemStack. 
-- in most cases, this return nil
-- @return nil or an xml table
function Item:GetBlockEntityData(itemStack)
end

function Item:GetStatName()
	return self:GetDisplayName()
end

-- get a string containing search keys in lower case
function Item:GetSearchKey()
	if(self.searchkey) then
		return self.searchkey;
	else
		local block_template = block_types.get(self.block_id);
		if(block_template and block_template.searchkey) then
			self.searchkey = block_template.searchkey;
		else
			self.searchkey = self:GetDisplayName():lower();
		end
	end
	return self.searchkey;
end

function Item:GetDisplayName()
	if(self.displayname) then
		return self.displayname;
	else
		local block_template = block_types.get(self.block_id);
		if(block_template) then
			return block_template:GetDisplayName();
		else
			return self.text or self.name or tostring(self.block_id);
		end
	end
end

-- virtual function: use the item. 
function Item:OnUse()
end

-- virtual function: when selected in right hand
function Item:OnSelect(itemStack)
	
end

-- virtual function: when deselected in right hand
function Item:OnDeSelect()
	
end

-- virtual function: called when loading world. 
function Item:OnLoadWorld()
	-- number of items that has been put into the 3d world. 
	self.inworld_count = nil;
end

-- update in world count
-- @param bIgnoreUpperConstraint: true or nil to ignore self.max_count
-- @return count the actual count diff. 
function Item:UpdateInWorldCount(nDiffCount, bIgnoreUpperConstraint)
	local last_count = self.inworld_count or 0;
	local new_count = last_count + nDiffCount;
	if(new_count < 0) then
		new_count = 0;
	end
	if(bIgnoreUpperConstraint~=true and self.max_count and self.max_count < new_count) then
		new_count = self.max_count;
	end
	self.inworld_count = new_count;
	return new_count - last_count;
end

-- get the number of items that is already used in the current world, such as collectables.
function Item:GetInWorldCount()
	return self.inworld_count or 0;
end


-- @param granularity: (0-1), 1 will generate 27 pieces, 0 will generate 0 pieces, default to 1. 
function Item:CreateBlockPieces(blockX, blockY, blockZ, granularity)
	-- simply use block 1 for break sound
	local block_id = 1;
	local block_template = block_types.get(block_id);
	if(block_template) then
		if(self.icon) then
			block_template:CreateBlockPieces(blockX, blockY, blockZ, granularity, self.icon);
		end
	end
end

-- called every frame
function Item:OnObtain()
end

function Item:GetItemModel()
	local block = self:GetBlock();
	if(block) then
		return block:GetItemModel();
	end
end

-- item scaling when hold in hand. 
function Item:GetItemModelScaling()
	local block = self:GetBlock();
	if(block) then
		return block:GetItemModelScaling() or 1;
	end
	return 1;
end

-- item offset when hold in hand. 
-- @return nil or {x,y,z}
function Item:GetItemModelInHandOffset()
	return self.inhandOffset;
end

function Item:CreateItemModel(x,y,z, facing, scaling)
	local model_filename = self:GetItemModel();
	return obj;
end

function Item:setMouseTracking(enable)
	self.mouseTracking = enable;
end

-- if true, we will receive mouse move event even mouse down is not accepted by the item. 
-- if false, we will only receive mouse move event if mouse down is accepted. 
-- default to false. 
function Item:hasMouseTracking()
	return self.mouseTracking;
end

-- called whenever an event comes. Subclass can overwrite this function. 
-- @param handlerName: "sizeEvent", "paintEvent", "mouseDownEvent", "mouseUpEvent", etc. 
-- @param event: the event object. 
function Item:event(event)
	local event_type = event:GetType();
	local func = self[event:GetHandlerFuncName()];
	if(type(func) == "function") then
		func(self, event);
	end
end

function Item:mousePressEvent(event)
end
function Item:mouseMoveEvent(event)
end
function Item:mouseReleaseEvent(event)
end
function Item:mouseWheelEvent(event)
end
function Item:keyReleaseEvent(event)
end
function Item:keyPressEvent(event)
end

-- virtual:
-- when alt key is pressed to pick a block in edit mode. 
function Item:PickItemFromPosition(x,y,z)
	local itemStack = ItemStack:new():Init(self.id, 1)
	if(self:HasColorData()) then
		local block_data = BlockEngine:GetBlockData(x,y,z);
		if(block_data and block_data~=0) then
			local block_template = BlockEngine:GetBlock(x,y,z);
			if(block_template) then
				if(block_template.color8_data) then
					block_data = band(block_data, 0xff00);
				end
			end
			if(block_data ~= 0) then
				itemStack:SetPreferredBlockData(block_data);
			end
		end
	end
	return itemStack;
end

-- virtual: convert entity to item stack. 
-- such as when alt key is pressed to pick a entity in edit mode. 
function Item:ConvertEntityToItem(entity)
	return ItemStack:new():Init(self.id, 1);
end

-- virtual:
-- compare two item stacks of the same item. 
-- return true if items are the same. 
-- @param left, right: type of ItemStack or nil. 
function Item:CompareItems(left, right)
	if(left == right) then
		return true;
	elseif(left and right) then
		return left.id == right.id and left.blockData==right.blockData;
	end
end

function Item:HasColorData()
	if(self.hasColorData == nil) then
		local block_template = self:GetBlock();
		if(block_template and (block_template.color8_data or block_template.color_data)) then
			self.hasColorData = true;
		else
			self.hasColorData = false;
		end
	end
	return self.hasColorData;
end

-- whether we use 8 bits color data 
function Item:IsColorData8Bits()
	if(self.colorData8Bit == nil) then
		local block_template = self:GetBlock();
		if(block_template and block_template.color8_data) then
			self.colorData8Bit = true;
		else
			self.colorData8Bit = false;
		end
	end
	return self.colorData8Bit;
end


-- static function: from color to data
-- @param bitCount: 8 or 16, default to current item setting
function Item:ColorToData(color, bitCount)
	if(bitCount~=16 and self:IsColorData8Bits()) then
		return lshift((0xFF - Color.convert32_8(bor(color, 0xff000000))), 8);
	else
		return Color.convert32_16(color);
	end
end

-- @param bitCount: 8 or 16, default to current item setting
-- @return without alpha, 0xff0000
function Item:DataToColor(data, bitCount)
	if(bitCount~=16 and self:IsColorData8Bits()) then
		data = 0xFF - rshift(data, 8);
		return band(Color.convert8_32(data), 0x00ffffff);
	else
		return Color.convert16_32(data);
	end
end

-- virtual: draw icon with given size at current position (0,0)
-- this function is only called when IsOwnerDrawIcon property is true. 
-- @param width, height: size of the icon
-- @param itemStack: this may be nil. or itemStack instance. 
function Item:DrawIcon(painter, width, height, itemStack)
	if(self:HasColorData()) then
		local data = itemStack:GetPreferredBlockData() or 0;
		local color = self:DataToColor(data);
		painter:SetPen(Color.ChangeOpacity(color));
	else
		painter:SetPen(self:GetIconColor());
	end
	painter:DrawRectTexture(0, 0, width, height, self:GetIcon());

	if(itemStack) then
		if(itemStack.count>1) then
			-- draw count at the corner: no clipping, right aligned, single line
			painter:SetPen("#000000");	
			painter:DrawText(0, height-15+1, width, 15, tostring(itemStack.count), 0x122);
			painter:SetPen("#ffffff");	
			painter:DrawText(0, height-15, width-1, 15, tostring(itemStack.count), 0x122);
		end
	end
end

function Item:SerializeServerData(serverdata, bSort)
	return commonlib.serialize_compact(serverdata, bSort);
end