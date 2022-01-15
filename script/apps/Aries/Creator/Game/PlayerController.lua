--[[
Title: main player controller
Author(s): LiXizhi
Date: 2012/10/18
Desc: main player controller for the client side's main character. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/PlayerController.lua");
local PlayerController = commonlib.gettable("MyCompany.Aries.Game.PlayerController")
local x, y, z = ParaScene.GetPlayer():GetPosition()

PlayerController:SetHandToolIndex(nIndex)
PlayerController:GetHandToolIndex()
PlayerController:SetHandToolIndex(nIndex);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/mathlib.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/BlockInEntityHand.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchMiniKeyboard.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local pe_mc_slot = commonlib.gettable("MyCompany.Aries.Game.mcml.pe_mc_slot");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local mathlib = commonlib.gettable("mathlib");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local BlockInEntityHand = commonlib.gettable("MyCompany.Aries.Game.EntityManager.BlockInEntityHand");
local TouchMiniKeyboard = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchMiniKeyboard");

-- create class
local PlayerController = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.PlayerController"));

local throwed_item_lifetime = 60;

function PlayerController:ctor()
	self.netClientHandler = nil;
	GameLogic.GetFilters():add_filter("basecontext_after_handle_mouse_event", function(event)
		self:OnMouseEvent(event)
		return event
	end);
end

function PlayerController:Init(netClientHandler)
	self.netClientHandler = netClientHandler;
end

function PlayerController:GetPlayer()
	return EntityManager.GetPlayer();
end

-- static function:
-- this function may be called before world is loaded
function PlayerController:GetMainAssetPath()
	local player = EntityManager.GetPlayer();
	if(player) then
		return player:GetMainAssetPath();
	else
		local filename = GameLogic.options:GetMainPlayerAssetName();
		if(filename) then
			return filename;
		else
			-- this function may be called before world is loaded, so check load block_types
			block_types.init();
			local item = ItemClient.GetItem(block_types.names.player);
			if(item) then
				return item:GetAssetFile();
			end
		end
	end
end

-- static function: if no skin is set, we will return the default one set is block_types.xml. 
function PlayerController:GetSkinTexture()
	local player = EntityManager.GetPlayer();
	local skin;
	if(player) then
		skin = player:GetSkin();
	end
	if(not skin) then
		-- this function may be called before world is loaded, so check load block_types
		skin = GameLogic.options:GetMainPlayerSkins();
		if (skin) then
			return skin;
		end
		block_types.init();
		local item = ItemClient.GetItem(block_types.names.player);
		if(item) then
			skin = item:GetSkinFile();
		end
	end

	-- hide pet skin
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
	local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
	CustomCharItems.RemovePetIdFromSkinIds(skin);

	return skin;
end

function PlayerController:PickBlockAt(x, y, z)
	local block_template = BlockEngine:GetBlock(x, y, z);
	if(block_template) then
		local item = ItemClient.GetItem(block_template.id);
		if(item) then
			local item_stack = item:PickItemFromPosition(x, y, z);
			self:SetBlockInRightHand(item_stack);
		end
	end
end

function PlayerController:PickItemByEntity(entity)
	if(entity and entity.GetItemClass) then
		local item = entity:GetItemClass()
		if(item) then
			local item_stack = item:ConvertEntityToItem(entity);
			self:SetBlockInRightHand(item_stack);
		end
	end
end

-- local settings
function PlayerController:LoadFromCurrentWorld()
	local filename = format("%sPlayer.xml", GameLogic.current_worlddir);
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(xmlRoot) then
		self.IsModified = false;
		LOG.std(nil, "info", "Player", "loaded file from %s", filename);
	end

	EntityManager.InitPlayers();

	self:CheckSetMode();
	GameLogic.events:AddEventListener("game_mode_change", self.OnGameModeChanged, self, "Player");
end

function PlayerController:SaveToCurrentWorld()
	if(self.IsModified) then
		self.IsModified = false;
		local filename = format("%sPlayer.xml", GameLogic.current_worlddir);

		local input = {name="player", attr={version=1}, };
		
		local code = commonlib.Lua2XmlString(input, true, true);
		local file = ParaIO.open(filename, "w");
		file:WriteString(code);
		file:close();

		LOG.std(nil, "info", "Player", "saved to %s", filename);
	end
end

-- input hooked event handler
function PlayerController:OnGameModeChanged(events)
	self:CheckSetMode();
end

function PlayerController:CheckSetMode()
	-- refresh all
	pe_mc_slot.RefreshBlockIcons();
end

function PlayerController:SetSkin(filename)
	EntityManager.GetPlayer():SetSkin(filename);
end

function PlayerController:IsInWater()
	local player = EntityManager.GetPlayer();
	if(player) then
		local x, y, z = player:GetBlockPos();
		local block = BlockEngine:GetBlock(x, y, z);
		if(block) then
			if(block.material:isLiquid()) then
				return true;
			end
		end
	end
end

function PlayerController:IsInAir()
	-- we use the FSM of the character animation states to check the player jumping status
	local player = ParaScene.GetPlayer();
	local animID = player:GetAnimation();
	-- 37  JUMPSTART
	-- 38  JUMP
	-- 39  JUMPEND
	if(animID == 37 or animID == 38) then
		return true;
	else -- if(self.asset_gsid)then
		local speed = math.abs(player:GetField("VerticalSpeed", -1000));
		if(speed > 0.01) then
			-- LOG.std(nil, "info", "category", speed);
			return true;
		end
	end
	return false;
end

function PlayerController:GetHealth()
	return self.health or 5;
end

-- set health value and update the ui
function PlayerController:SetHealth(value)
	self.health = value;
end

-- set the hand tool bag pos index
function PlayerController:SetHandToolIndex(nIndex)
	local player = EntityManager.GetPlayer();
	if(player) then
		return player:SetHandToolIndex(nIndex, true);
	end
end

-- set the hand tool bag pos index
function PlayerController:OnClickHandToolIndex(nIndex)
	local player = EntityManager.GetPlayer();
	if(player) then
		local res = player:SetHandToolIndex(nIndex, true);
		local itemStack = player:GetItemInRightHand();
		if(itemStack) then
			local item = itemStack:GetItem();
			if(item and item.OnClickInHand) then
				item:OnClickInHand(itemStack, player);
			end
		end
	end
end

-- toggle the last selected tool
function PlayerController:ToggleHandToolIndex()
	local player = EntityManager.GetPlayer();
	if(player) then
		return player:ToggleHandToolIndex();
	end
end

-- get hand tool's bag pos index
function PlayerController:GetHandToolIndex()
	local player = EntityManager.GetPlayer();
	if(player) then
		return player.inventory:GetHandToolIndex();
	end
end

-- called when player is loaded and GUI scene context is initialized. 
function PlayerController:InitMainPlayerHandTool()
	local player = EntityManager.GetPlayer();
	if(player.inventory and not player.is_hand_tool_initialized) then
		player.is_hand_tool_initialized = true;
		player.inventory:OnInventoryChanged(player.inventory:GetHandToolIndex());
	end
end

function PlayerController:DeselectMainPlayerHandTool()
	local item = self:GetItemInRightHand();
	if(item) then
		item:OnDeSelect();
	end
end

-- return the block id in the right hand of the player. 
function PlayerController:GetBlockInRightHand()
	local player = EntityManager.GetPlayer();
	if(player) then
		return player:GetBlockInRightHand();
	end
end

-- get item stack 
function PlayerController:GetItemStackInRightHand()
	local player = EntityManager.GetPlayer();
	if(player) then
		local res = player:SetHandToolIndex(nIndex, true);
		local itemStack = player:GetItemInRightHand();
		if(itemStack) then
			return itemStack;
		end
	end
end

-- if there is nothing in the hand ItemEmpty is returned. 
function PlayerController:GetItemInRightHand()
	local item;
	local block_id = self:GetBlockInRightHand();
	if(block_id) then
		item = ItemClient.GetItem(block_id);
	end
	return item or block_types.GetItemClass("ItemEmpty");
end

-- set block in right hand
-- @param blockid_or_item_stack:  block_id or ItemStack object. 
-- @param bIsReplace: if true, we will replace instead of moving to other empty slot
function PlayerController:SetBlockInRightHand(blockid_or_item_stack, bIsReplace)
	LOG.std(nil, 'info', 'SetBlockInRightHand');
	local player = EntityManager.GetPlayer();
	if(player) then
		if(player.petObj) then
			BlockInEntityHand.RefreshRightHand(nil, blockid_or_item_stack, player.petObj)
		end
		if(type(blockid_or_item_stack) == "number") then
			local item = ItemClient.GetItem(blockid_or_item_stack)
			if(item and item:GetPreferredBlockData()) then
				local itemStack = ItemStack:new():Init(blockid_or_item_stack, 1);
				itemStack:SetPreferredBlockData(item:GetPreferredBlockData())
				blockid_or_item_stack = itemStack;
			end
		end
		return player:SetBlockInRightHand(blockid_or_item_stack, bIsReplace);		
	end
end

-- throw entity to the x,y,z location. 
-- @param x,y,z: real coordinate. if nil the current mouse pick location is used. 
function PlayerController:ThrowBlockInHand(x,y,z)
	local player = EntityManager.GetPlayer();
	if(player) then
		self:DropItemTo3DScene(player.inventory, player.inventory:GetHandToolIndex(), 1);
	end
end

-- drop the itemStack to 3d scene. 
-- @param inventory, slot_id, count: if nil, it will drop currently dragged item to 3d scene. 
-- @param x,y,z: real coordinate. if nil the current mouse pick location is used. 
function PlayerController:DropItemTo3DScene(inventory, slot_id, count, x, y, z)
	if(not x) then
		local result = Game.SelectionManager:MousePickBlock();
		if(result and result.x) then
			if(result.side and result.blockX) then
				x,y,z = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
				x,y,z = BlockEngine:real(x,y,z);
			else
				x,y,z = result.x, result.y, result.z;
			end
		else
			return
		end
	end

	local itemStack;

	if(GameLogic.isRemote) then
		-- TODO: this logics should move to server side one day. 
		if(not inventory or not slot_id) then
			itemStack = EntityManager.GetPlayer():GetDragItem();
			EntityManager.GetPlayer():SetDragItem(nil);
		else
			itemStack = inventory:RemoveItem(slot_id, count);
		end
	
		if(itemStack) then
			-- send a packet to server
			local clientMP = EntityManager.GetPlayer();
			if(clientMP and clientMP.AddToSendQueue) then
				clientMP:AddToSendQueue(Packets.PacketEntityFunction:new():Init(clientMP, "dropitem", {x=x, y=y,z=z, id = itemStack.id, count = itemStack.count, serverdata=itemStack.serverdata}));
			end
		end
	else
		if(not inventory or not slot_id) then
			itemStack = EntityManager.GetPlayer():GetDragItem();
			EntityManager.GetPlayer():SetDragItem(nil);
		else
			itemStack = inventory:RemoveItem(slot_id, count);
		end
	
		if(itemStack) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityItem.lua");
			local EntityItem = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityItem")
			local entity = EntityItem:new():Init(x,y,z,itemStack, throwed_item_lifetime);
			entity:Attach();
			-- TESTING
			entity:AddVelocity(0,5,0);
		end
	end
end

-- user clicks on an OPC
function PlayerController:OnPlayerRightClick(player, x,y,z, mouse_button)
	player = player or EntityManager.GetPlayer();
end

-- save local user data for a given world
function PlayerController:SaveLocalUserWorldData(name, value, bIsGlobal, bDeferSave)
	name = GameLogic.GetWorldDirectory()..(name or "")
	return self:SaveLocalData(name, value, bIsGlobal, bDeferSave)
end

function PlayerController:SaveLocalData(name, value, bIsGlobal, bDeferSave)
	local ls = System.localserver.CreateStore(nil, 3, if_else(System.options.version == "teen", "userdata.teen", "userdata"));
	if(not ls) then
		return;
	end
	-- make url
	local url;
	if(not bIsGlobal) then
		url = NPL.EncodeURLQuery(name, {"nid", System.User.nid})
	else
		url = name;
	end
	
	-- make entry
	local item = {
		entry = System.localserver.WebCacheDB.EntryInfo:new({
			url = url,
		}),
		payload = System.localserver.WebCacheDB.PayloadInfo:new({
			status_code = System.localserver.HttpConstants.HTTP_OK,
			data = {value = value},
		}),
	}
	-- save to database entry
	local res = ls:PutItem(item, not bDeferSave);
	if(res) then 
		LOG.std("", "debug","Player", "Local user data %s is saved to local server", tostring(url));
		return true;
	else	
		LOG.std("", "warn","Player", "failed saving local user data %s to local server", tostring(url))
	end
end

-- load local user data for a given world
function PlayerController:LoadLocalUserWorldData(name, default_value, bIsGlobal)
	name = GameLogic.GetWorldDirectory()..(name or "")
	return self:LoadLocalData(name, default_value, bIsGlobal)
end

function PlayerController:LoadLocalData(name, default_value, bIsGlobal)
	local ls = System.localserver.CreateStore(nil, 3, if_else(System.options.version == "teen", "userdata.teen", "userdata"));
	if(not ls) then
		LOG.std(nil, "warn", "Player", "Player.LoadLocalData %s failed because userdata db is not valid", name)
		return default_value;
	end
	local url;
	-- make url
	if(not bIsGlobal) then
		url = NPL.EncodeURLQuery(name, {"nid", System.User.nid})
	else
		url = name;
	end
	
	local item = ls:GetItem(url)
			
	if(item and item.entry and item.payload) then
		local output_msg = commonlib.LoadTableFromString(item.payload.data);
		if(output_msg) then
			return output_msg.value;
		end
	end
	return default_value;
end

function PlayerController:LoadRemoteData(name, default_value)
	local value = GameLogic.GetFilters():apply_filters('Player.LoadRemoteData', nil, name, default_value)
	if(value~=nil) then
		return value
	end
	if(System.User.username) then
		name = NPL.EncodeURLQuery(name, {"name", System.User.username})
	end
	value = self:LoadLocalData(name, default_value, true)
	return value;
end

function PlayerController:SaveRemoteData(name, value, bDeferSave)
	local result = GameLogic.GetFilters():apply_filters('Player.SaveRemoteData', nil, name, value, bDeferSave)
	if(result~=nil) then
		return result
	end
	if(System.User.username) then
		name = NPL.EncodeURLQuery(name, {"name", System.User.username})
	end
	return self:SaveLocalData(name, value, true, bDeferSave)
end


function PlayerController:FlushLocalData()
	local ls = System.localserver.CreateStore(nil, 3, if_else(System.options.version == "teen", "userdata.teen", "userdata"));
	if(ls) then
		return ls:Flush();
	end
end

function PlayerController:CreateNewClientPlayerMP(world, entityId, netClientHandler)
	self:Init(netClientHandler);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPlayerMPClient.lua");
	local entityPlayer = EntityManager.EntityPlayerMPClient:new();
	entityPlayer:init(world, netClientHandler, entityId);
	entityPlayer:SetMainAssetPath(GameLogic.options:GetMainPlayerAssetName())
	return entityPlayer;
end

-- set the player that is being controlled. 
function PlayerController:SetMainPlayer(entityPlayer)
	entityPlayer:SetFocus();
	local last_player = EntityManager.SetMainPlayer(entityPlayer);
	
	if(last_player) then
		if(last_player:isa(EntityManager.EntityPlayerMP)) then
			-- we do not delete old ones for debugging networking using loopback interface 
			-- using the same process. 
		else
			-- remove old player since we no longer use it. 
			last_player:Destroy();
		end
	end
end

-- return true if processed. 
function PlayerController:OnClickBlock(block_id, bx, by, bz, mouse_button, entity, side)
	if(block_id) then
		local block = block_types.get(block_id);
		if(block) then
			return block:OnClick(bx, by, bz, mouse_button, entity, side);
		end
	end
end

-- return true if processed. 
function PlayerController:OnClickEntity(target_entity, bx, by, bz, mouse_button, triggerEntity)
	if(target_entity) then
		return target_entity:OnClick(bx, by, bz, mouse_button, triggerEntity);
	end
end

function PlayerController:SetFlyUsingCameraDir(bEnable)
	local player = EntityManager.GetPlayer();
	if(player) then
		local obj = player:GetInnerObject();
		if(obj) then
			obj:SetField("FlyUsingCameraDir", bEnable == true);
		end
	end
end

-- whether to enable mouse dragging on player to move around. 
function PlayerController:SetEnableDragPlayerToMove(bEnable)
	if bEnable ~= self.isDragPlayerToMoveEnabled then
		-- left dragging is always enabled
		if bEnable then
			local att = ParaCamera.GetAttributeObject();
			GameLogic.options:SetEnableMouseLeftDrag(true)
		else
			if( not (System.options.IsTouchDevice or GameLogic.options:HasTouchDevice()) ) then
				GameLogic.options:SetEnableMouseLeftDrag(false)
			end
		end
	end
	self.isDragPlayerToMoveEnabled = bEnable
end

function PlayerController:OnMouseEvent(event)
	if not self.isDragPlayerToMoveEnabled then
		return
	end

	if event:isAccepted() then
		if self.move_center_pos then
			self.move_center_pos = nil
			local TouchMiniKeyboardSingleton = TouchMiniKeyboard.GetSingleton()
			TouchMiniKeyboardSingleton:StopMoveState()
		end
		return
	end

	if event:isClick() and event.isDoubleClick then
		if(GameLogic.SelectionManager:IsMousePickingEntity()) then
			GameLogic.DoJump()
		end
	end

	local event_type = event:GetType()
	local TouchMiniKeyboardSingleton = TouchMiniKeyboard.GetSingleton()
	if event_type == "mousePressEvent" then
		local is_right_mouse = event.RightButton and event:RightButton()
		if GameLogic.SelectionManager:IsMousePickingEntity() and not is_right_mouse then
			self.move_center_pos = {ParaUI.GetMousePosition()}
			event:accept();
		end
		
	elseif event_type == "mouseMoveEvent" then
		if self.move_center_pos then
			local x, y = ParaUI.GetMousePosition()
			TouchMiniKeyboardSingleton:ChangeMoveState(x, y, self.move_center_pos, true)
			event:accept();
		end
	else
		self.move_center_pos = nil
		TouchMiniKeyboardSingleton:StopMoveState()
		event:accept();
	end
end