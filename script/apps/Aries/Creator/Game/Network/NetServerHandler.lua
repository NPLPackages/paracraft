--[[
Title: NetServerHandler
Author(s): LiXizhi
Date: 2014/6/25
Desc: This represents a player proxy on the server. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetServerHandler.lua");
local NetServerHandler = commonlib.gettable("MyCompany.Aries.Game.Network.NetServerHandler");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetHandler.lua");
NPL.load("(gl)script/ide/math/bit.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");

local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;


local NetServerHandler = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.NetHandler"), commonlib.gettable("MyCompany.Aries.Game.Network.NetServerHandler"));

function NetServerHandler:ctor()
	-- is true when the player has moved since login or last teleport 
	self.currentTicks = 0;
end

-- @return true if we allow client to edit the given entity on server. 
function NetServerHandler:CheckAllowEditEntity(entity)
	return true;
end

function NetServerHandler:Init(playerConnection, playerEntity, server_manager)
	self.server_manager = server_manager;
	self.playerConnection = playerConnection;
	playerConnection:SetNetHandler(self);
	self.playerEntity = playerEntity;
	playerEntity:SetServerHandler(self);
	
	LOG.std(nil, "info", "NetServerHandler", "New player initialized");

	return self;
end

function NetServerHandler:GetEntityByID(id)
	if(id) then
		if(id == self.playerEntity.entityId) then
			return self.playerEntity;
		else
			return self.playerEntity:GetWorldServer():GetEntityByID(id);
		end
	end
end

function NetServerHandler:KickPlayerFromServer(reason)
    if (not self.connectionClosed) then
        self.playerEntity:MountEntityAndWakeUp();
        self:SendPacketToPlayer(Packets.PacketKickDisconnect:new():Init(reason));
        self.playerConnection:ServerShutdown();
        self.server_manager:SendChatMsg("multiplayer.player.left"..self.playerEntity:GetDisplayName());
        self.server_manager:PlayerLoggedOut(self.playerEntity);
        self.connectionClosed = true;
    end
end

function NetServerHandler:SendPacketToPlayer(packet)
	return self.playerConnection:AddPacketToSendQueue(packet);
end

-- Moves the player to the specified destination and rotation
-- This function is only called during login, or when server detects that client pos and server server differs too much. 
function NetServerHandler:SetPlayerLocation(x,y,z, yaw, pitch)
    self.lastPosX = x;
    self.lastPosY = y;
    self.lastPosZ = z;
    self.playerEntity:SetPositionAndRotation(x,y,z, yaw, pitch);
    self.playerEntity:SendPacketToPlayer(Packets.PacketPlayerLookMove:new():Init(x, y, y, z, yaw, pitch, false));
end

-- run once each game tick
function NetServerHandler:NetworkTick()
	self.bHasMovePacketSinceLastTick = false;
	self.currentTicks = self.currentTicks + 1;
end

function NetServerHandler:GetServerManager()
	return self.server_manager;
end

function NetServerHandler:handleErrorMessage(text, data)
	LOG.std(nil, "info", "NetServerHandler", "%s lost connections %s", self.playerEntity:GetUserName(), text or "");
    self:GetServerManager():PlayerLoggedOut(self.playerEntity);
    self.connectionClosed = true;
	-- TODO: shut down server if it is admin player
end

-- this function actually framemoves the playerMP and applies all physics if any. 
function NetServerHandler:handleMove(packet_move)
    local worldserver = self:GetServerManager():GetWorldServerForDimension(self.playerEntity.dimension);
	if(not worldserver) then
		return;
	end
    self.bHasMovePacketSinceLastTick = true;

	if (not self.playerEntity.bDisableServerMovement) then
		--local hasMovedOrForceTick;
		--if (packet_move.y) then
            --local dy = packet_move.y - self.lastPosY;
            --hasMovedOrForceTick = math.abs(packet_move.x-self.lastPosX)>0.01 or dy * dy > 0.01 or math.abs(packet_move.z-self.lastPosZ)>0.01;
        --end
		--hasMovedOrForceTick = hasMovedOrForceTick or (self.currentTicks % 20 == 0);

		if (self.playerEntity:IsPlayerSleeping()) then
            self.playerEntity:OnUpdateEntity();
            self.playerEntity:SetPositionAndRotation(self.lastPosX, self.lastPosY, self.lastPosZ, self.playerEntity.facing, self.playerEntity.rotationPitch);
            worldserver:UpdateEntity(self.playerEntity);
            return;
        end

        local lastY = self.playerEntity.y;
		local posX = self.playerEntity.x;
        local posY = self.playerEntity.y;
        local posZ = self.playerEntity.z;
        self.lastPosX = posX;
        self.lastPosY = posY;
        self.lastPosZ = posZ;
            
		if (self.playerEntity:IsRiding()) then
			-- only update rotation, position is updated by the server. 
			if (packet_move.rotating) then
				self.playerEntity:SetRotation(packet_move.yaw, packet_move.pitch);
			end
			self.playerEntity:GetWorldServer():GetPlayerManager():UpdateMovingPlayer(self.playerEntity);
			return;
		end

        local rotYaw = self.playerEntity.facing;
        local rotPitch = self.playerEntity.rotationPitch;

        if (packet_move.moving and packet_move.y == -999 and packet_move.stance == -999) then
            packet_move.moving = false;
        end
    
        if (packet_move.moving and not self:IsTeleporting()) then
            posX = packet_move.x;
            posY = packet_move.y;
            posZ = packet_move.z;
            -- local jumpheight = packet_move.stance - packet_move.y;
			-- checking for illegal positions:

            if (math.abs(packet_move.x) > 320000 or math.abs(packet_move.z) > 320000) then
                self:KickPlayerFromServer("Illegal position");
                return;
            end
        end

        if (packet_move.rotating) then
            rotYaw = packet_move.yaw;
            rotPitch = packet_move.pitch;
        end

		self.playerEntity:OnUpdateEntity();
		self.playerEntity:SetPositionAndRotation(self.lastPosX, self.lastPosY, self.lastPosZ, rotYaw, rotPitch);

        local dx = posX - self.playerEntity.x;
        local dy = posY - self.playerEntity.y;
        local dz = posZ - self.playerEntity.z;
        local mx = math.max(math.abs(dx), math.abs(self.playerEntity.motionX));
        local my = math.max(math.abs(dy), math.abs(self.playerEntity.motionY));
        local mz = math.max(math.abs(dz), math.abs(self.playerEntity.motionZ));
        local mDistSq = mx * mx + my * my + mz * mz;

		local collision_offset = 0.0625;

		if (mDistSq > 100) then
			LOG.std(nil, "warn", "NetServerHandler", "%s moved too fast", self.playerEntity:GetUserName());
			-- server rule1: revert to old position
			--self:SetPlayerLocation(self.lastPosX, self.lastPosY, self.lastPosZ, rotYaw, rotPitch);

			-- server rule2: teleport to the given position. 
			self.playerEntity:SetPositionAndRotation(posX, posY+collision_offset, posZ, rotYaw, rotPitch);
		else
			local bNoCollision = worldserver:GetCollidingBoundingBoxes(self.playerEntity:GetCollisionAABB():clone_from_pool():Expand(-collision_offset, -collision_offset, -collision_offset), self.playerEntity) == nil;

			-- LOG.std(nil, "debug", "NetServerHandler", "handleMove entity id %d: displacement: %f %f %f  time:%d", self.playerEntity.entityId, dx, dy, dz, ParaGlobal.timeGetTime());
			self.playerEntity:MoveEntityByDisplacement(dx, dy, dz);
			self.playerEntity.onGround = packet_move.onGround;
			local cur_dy = dy;
			dx = posX - self.playerEntity.x;
			dy = posY - self.playerEntity.y;

			if (dy > -0.5 or dy < 0.5) then
				dy = 0;
			end

			dz = posZ - self.playerEntity.z;
			mDistSq = dx * dx + dy * dy + dz * dz;
			local bMovedTooMuch = false;

			if (mDistSq > 0.0625 and not self.playerEntity:IsPlayerSleeping()) then
				bMovedTooMuch = true;
				LOG.std(nil, "warn", "NetServerHandler", "%s moved wrongly", self.playerEntity:GetUserName());
			end

			self.playerEntity:SetPositionAndRotation(posX, posY, posZ, rotYaw, rotPitch);
			local bNoCollisionAfterMove = worldserver:GetCollidingBoundingBoxes(self.playerEntity:GetCollisionAABB():clone_from_pool():Expand(-collision_offset, -collision_offset, -collision_offset), self.playerEntity) == nil;

			if (bNoCollision and (bMovedTooMuch or not bNoCollisionAfterMove) and not self.playerEntity:IsPlayerSleeping()) then
				-- client has moved into a solid block or something, reset to old position.  
				self:SetPlayerLocation(self.lastPosX, self.lastPosY, self.lastPosZ, rotYaw, rotPitch);
				return;
			end	    
		end
		self.playerEntity.onGround = packet_move.onGround;
		self.playerEntity:GetWorldServer():GetPlayerManager():UpdateMovingPlayer(self.playerEntity);
		self.playerEntity:UpdateFallStateMP(self.playerEntity.y - lastY, packet_move.onGround);
    end
end

function NetServerHandler:handleEntityAction(packet_entity_action)
	local state = packet_entity_action.state;
	local param1 = packet_entity_action.param1;
	if(state == 0) then
		self.playerEntity:SetEntityAction(param1);
	elseif(state == 1) then
		-- mount/unmount on railcar, etc. 
		local vehicleEntity = self:GetEntityByID(packet_entity_action.entityId)
		if(vehicleEntity and vehicleEntity~=self.playerEntity) then
			self.playerEntity:MountEntity(vehicleEntity);
		else
			self.playerEntity:MountEntity(nil);
		end
	end
end

function NetServerHandler:handleEntityHeadRotation(packet_entity_head_rotation)
	local rot = packet_entity_head_rotation.rot;
	local pitch = packet_entity_head_rotation.pitch;
	self.playerEntity.rotationHeadYaw = rot;
	self.playerEntity.rotationHeadPitch = pitch;
	local obj = self.playerEntity:GetInnerObject();
	if(obj) then
		if(rot) then
			obj:SetField("HeadTurningAngle", rot);
		end
		if(pitch) then
			obj:SetField("HeadUpdownAngle", pitch);
		end
	end
end

function NetServerHandler:handleBlockChange(packet_BlockChange)
	-- for single block update, we will notify neighbor changes
	BlockEngine:SetBlock(packet_BlockChange.x, packet_BlockChange.y, packet_BlockChange.z, packet_BlockChange.blockid, packet_BlockChange.data, 3);
end

function NetServerHandler:handleBlockMultiChange(packet_BlockMultiChange)
    local cx = packet_BlockMultiChange.chunkX * 16;
    local cz = packet_BlockMultiChange.chunkZ * 16;
	local blockList = packet_BlockMultiChange.blockList;
	local idList = packet_BlockMultiChange.idList;
	local dataList = packet_BlockMultiChange.dataList;
    if (blockList) then
		for i = 1, #blockList do
			local packedIndex = blockList[i];
			local x, y, z;
			x = cx + band(rshift(packedIndex, 12), 15);
			y = band(packedIndex, 255);
			z = cz + band(rshift(packedIndex, 8), 15);
			-- for multiple blocks update, we will NOT notify neighbor changes (assuming some copy, paste operations on the client side)
			BlockEngine:SetBlock(x, y, z, idList[i], dataList[i]);
        end
	end
end

function NetServerHandler:handleBlockPieces(packet_BlockPieces)
	local block_template = block_types.get(packet_BlockPieces.blockid);
	if(block_template) then
		block_template:CreateBlockPieces(packet_BlockPieces.x,packet_BlockPieces.y,packet_BlockPieces.z, packet_BlockPieces.granularity);
	end
	self.playerEntity:GetWorldServer():GetPlayerManager():SendToObservingPlayers(packet_BlockPieces.x,packet_BlockPieces.y,packet_BlockPieces.z, packet_BlockPieces, self.playerEntity);
end

function NetServerHandler:handleClickBlock(packet_ClickBlock)
	local entity = self:GetEntityByID(packet_ClickBlock.entityId);
	GameLogic.GetPlayerController():OnClickBlock(packet_ClickBlock.block_id, packet_ClickBlock.x, packet_ClickBlock.y, packet_ClickBlock.z, packet_ClickBlock.mouse_button, entity, packet_ClickBlock.side)
end

function NetServerHandler:handleClickEntity(packet_ClickEntity)
	local playerEntity = self:GetEntityByID(packet_ClickEntity.playerEntityId);
	if(playerEntity ~= self.playerEntity) then
		-- TODO: we only allow click event on behalf of the client player.
		playerEntity = self.playerEntity;
	end

	local targetEntity;
	if(packet_ClickEntity.targetBlockX) then
		targetEntity = EntityManager.GetBlockEntity(packet_ClickEntity.targetBlockX, packet_ClickEntity.targetBlockY, packet_ClickEntity.targetBlockZ);
	else
		targetEntity = self:GetEntityByID(packet_ClickEntity.targetEntityId);	
	end
	GameLogic.GetPlayerController():OnClickEntity(targetEntity, packet_ClickEntity.x, packet_ClickEntity.y, packet_ClickEntity.z, packet_ClickEntity.mouse_button, playerEntity);
end

function NetServerHandler:handleEntityMetadata(packet_EntityMetadata)
	local entity = self:GetEntityByID(packet_EntityMetadata.entityId) or self.playerEntity;
    if (entity and self:CheckAllowEditEntity(entity) and packet_EntityMetadata:GetMetadata()) then
        local watcher = entity:GetDataWatcher();
		if(watcher) then
			watcher:UpdateWatchedObjectsFromList(packet_EntityMetadata:GetMetadata());
			if(entity ~= self.playerEntity and entity.LoadFromDataWatcher) then
				entity:LoadFromDataWatcher();
			end
		end
    end
end

function NetServerHandler:handleChat(packet_Chat)
    LOG.std(nil, "debug", "NetServerHandler.handleChat", "%s says: %s", self.playerEntity:GetUserName(), packet_Chat.text);
	packet_Chat.text = self.playerEntity:GetUserName()..": "..packet_Chat.text;
	local chat_msg = packet_Chat:ToChatMessage();

	Desktop.GetChatGUI():PrintChatMessage(chat_msg);
	self:GetServerManager():SendChatMsg(chat_msg);
end

function NetServerHandler:handleUpdateEntitySign(packet_UpdateEntitySign)
	local blockEntity = EntityManager.GetBlockEntity(packet_UpdateEntitySign.x, packet_UpdateEntitySign.y, packet_UpdateEntitySign.z)
	if(blockEntity) then
		blockEntity:OnUpdateFromPacket(packet_UpdateEntitySign);

		self:GetServerManager():SendPacketToAllPlayersExcept(Packets.PacketUpdateEntitySign:new():Init(packet_UpdateEntitySign.x, packet_UpdateEntitySign.y, packet_UpdateEntitySign.z, packet_UpdateEntitySign.text, packet_UpdateEntitySign.data, packet_UpdateEntitySign.text2), self.playerEntity);
	end
end

function NetServerHandler:handleUpdateEntityBlock(packet_UpdateEntityBlock)
	local blockEntity = EntityManager.GetBlockEntity(packet_UpdateEntityBlock.x, packet_UpdateEntityBlock.y, packet_UpdateEntityBlock.z)
	if(blockEntity) then
		blockEntity:OnUpdateFromPacket(packet_UpdateEntityBlock);

		self:GetServerManager():SendPacketToAllPlayersExcept(Packets.PacketUpdateEntityBlock:new():Init(packet_UpdateEntityBlock.x, packet_UpdateEntityBlock.y, packet_UpdateEntityBlock.z, packet_UpdateEntityBlock.data1, packet_UpdateEntityBlock.data2, packet_UpdateEntityBlock.data3), self.playerEntity);
	end
end

function NetServerHandler:handleClientCommand(packet_ClientCommand)
	local cmd = packet_ClientCommand.cmd;
	if(cmd) then
		local cmd_class, cmd_name, cmd_text = CommandManager:GetCmdByString(cmd);
		if(cmd_class and not cmd_class:IsLocal()) then
			CommandManager:RunFromConsole(cmd, self.playerEntity);
		end
	end
end

function NetServerHandler:handleUpdateEnv(packet_env)
	-- TODO: do we allow any client to change server environment?
end

function NetServerHandler:handleEntityFunction(packet_EntityFunction)
	local entity = self.playerEntity;
    if (entity) then
		local name = packet_EntityFunction.name;
		local param = packet_EntityFunction.param;
		if(name == "dropitem") then
			if(param.x and param.y and param.z and param.id) then
				-- TODO: we need to verify if entity.inventory actually contains the item and remove it?
				-- since we fully trust client in edit mode, we will simply spawn.
				local throwed_item_lifetime = 60;
				local itemStack = ItemStack:new():Init(param.id, param.count, param.serverdata);
				local entity = EntityManager.EntityItem:new():Init(param.x,param.y,param.z, itemStack, throwed_item_lifetime);
				entity:Attach();
			end
		elseif(name == "mobProperty") then
			entity = self:GetEntityByID(packet_EntityFunction.entityId);
			if(entity) then
--				if(param.displayName) then
--					entity:SetDisplayName(param.displayName);
--				end
--				if(param.name) then
--					entity:SetName(param.name);
--				end
				if(param.canRandomWalk~=nil) then
					entity:SetCanRandomMove(param.canRandomWalk);
				end
			end
		else
			-- TODO: for other one time commmand
		end
	end
end

function NetServerHandler:SetTeleporting(bValue)
	self.isServerTeleporting = bValue;
end

-- if true, we will ignore all client move packets
function NetServerHandler:IsTeleporting()
	return self.isServerTeleporting;
end

function NetServerHandler:handleEntityTeleport(packet_EntityTeleport)
	self:SetTeleporting(false);
end

-- handles a get file request from client
function NetServerHandler:handleGetFile(packet_GetFile)
	if(packet_GetFile.filename) then
		if(not packet_GetFile.data) then
			local data;
			local filename = Files.GetWorldFilePath(packet_GetFile.filename)
			if(filename) then
				local file = ParaIO.open(filename, "r")
				if(file:IsValid()) then
					data = file:GetText(0, -1);
					file:close();
				end
			end
			self:SendPacketToPlayer(Packets.PacketGetFile:new():Init(packet_GetFile.filename, data or ""));
		end
	end
end

function NetServerHandler:handlePutFile(packet_PutFile)
	if(packet_PutFile.filename) then
		if(packet_PutFile.data and packet_PutFile.data ~= "") then
			local filename = Files.WorldPathToFullPath(packet_PutFile.filename)
			if(filename) then
				ParaIO.CreateDirectory(filename);
				local file = ParaIO.open(filename, "w")
				if(file:IsValid()) then
					file:WriteString(packet_PutFile.data, #(packet_PutFile.data));
					file:close();
					LOG.std(nil, "info", "NetServerHandler", "world file received and saved to %s", filename)
					-- broadcast to all clients without file data, so the client can decide whether to request the file.
					self:GetServerManager():SendPacketToAllPlayers(Packets.PacketPutFile:new():Init(packet_PutFile.filename));
				end
			end
		end
	end
end

function NetServerHandler:handleMobSpawn(packet_MobSpawn)
	if(not packet_MobSpawn.x) then
		return 
	end
	local x = packet_MobSpawn.x / 32;
    local y = packet_MobSpawn.y / 32;
    local z = packet_MobSpawn.z / 32;
   
	local spawnedEntity;
    local entity_type = packet_MobSpawn.type;
	if(entity_type == 11) then
		spawnedEntity = EntityManager.EntityMob:Create({x=x,y=y,z=z, item_id = packet_MobSpawn.item_id or block_types.names["player_spawn_point"]});
		LOG.std(nil, "debug", "server::handleMobSpawn", "mob");
	elseif(entity_type == 12) then
		spawnedEntity = EntityManager.EntityNPC:Create({x=x,y=y,z=z, item_id = packet_MobSpawn.item_id or block_types.names["villager"]});
		LOG.std(nil, "debug", "server::handleMobSpawn", "NPC");
	elseif(entity_type == 13) then
		spawnedEntity = EntityManager.EntityItem:new():Init(x,y,z, ItemStack:new():Init(packet_MobSpawn.item_id,1));
		LOG.std(nil, "debug", "server::handleMobSpawn", "item: %d", packet_MobSpawn.item_id or -1);
	elseif(entity_type == 14) then
		local item_id = packet_MobSpawn.item_id or block_types.names["gold_coin"];
		local item = ItemClient.GetItem(item_id)
		if(item) then
			if(not item.max_count or item:GetInWorldCount() < item.max_count) then
				spawnedEntity = EntityManager.EntityCollectable:Create({x=x,y=y,z=z, item_id = item_id});
				LOG.std(nil, "debug", "server::handleMobSpawn", "Collectable: %d", packet_MobSpawn.item_id or -1);
			end
		end
	elseif(entity_type == 10) then
		spawnedEntity = EntityManager.EntityRailcar:Create({x=x,y=y,z=z, item_id = packet_MobSpawn.item_id or block_types.names["railcar"]});
		LOG.std(nil, "debug", "server::handleMobSpawn", "railcar: %d", packet_MobSpawn.item_id or -1);
	else
		-- TODO: add other types
	end
	
	-- add to world
	if(spawnedEntity) then
		spawnedEntity:Attach();
	end
end


function NetServerHandler:handleCodeBlockEvent(packet_CodeBlockEvent)
	local name = packet_CodeBlockEvent.name;
	if(name == "ps_broadcast" or name == "ps_redirect") then
		local data = packet_CodeBlockEvent.data;
		GameLogic.GetCodeGlobal():SendNetworkEvent(name, data.name, data.msg);
	else
		local data = packet_CodeBlockEvent.data;
		local entity = self.playerEntity;
		if (entity) then
			if(type(data) == "table") then
				data.username = entity:GetUserName();
			else
				data = {username = entity:GetUserName(), msg = data};
			end
		end
		GameLogic.GetCodeGlobal():handleNetworkEvent(name, data);
	end
end

function NetServerHandler:handleDestroyEntity(packet_DestroyEntity)
    for i =1, #(packet_DestroyEntity.entity_ids) do
		local entity = self:GetEntityByID(packet_DestroyEntity.entity_ids[i]);
        if(entity and not entity:IsPlayer() and self:CheckAllowEditEntity(entity)) then
			entity:Destroy();
		end
    end
end

-- this is usaully called periodially in addition to RelEntity, to force a complete position update. 
function NetServerHandler:handleEntityMove(packet_EntityMove)
	local entityOther = self:GetEntityByID(packet_EntityMove.entityId);
    if (entityOther and self:CheckAllowEditEntity(entityOther)) then
        entityOther.serverPosX = packet_EntityMove.x;
        entityOther.serverPosY = packet_EntityMove.y;
        entityOther.serverPosZ = packet_EntityMove.z;
        local x = entityOther.serverPosX / 32;
        local y = entityOther.serverPosY / 32 + 0.015625;
        local z = entityOther.serverPosZ / 32;
        local facing;
		if(packet_EntityMove.facing) then
			facing = packet_EntityMove.facing / 32;
		end
		local pitch;
		if(packet_EntityMove.pitch) then
			pitch = packet_EntityMove.pitch / 32;
		end
		entityOther:SetPositionAndRotation(x, y, z, facing, pitch);
    end
end