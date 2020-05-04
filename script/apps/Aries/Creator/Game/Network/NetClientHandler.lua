--[[
Title: NetClientHandler
Author(s): LiXizhi
Date: 2014/6/25
Desc: used on client side, represent a connection to server. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetClientHandler.lua");
local NetClientHandler = commonlib.gettable("MyCompany.Aries.Game.Network.NetClientHandler");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetHandler.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ConnectionTCP.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet_Types.lua");
NPL.load("(gl)script/ide/math/bit.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetworkMain.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local NetworkMain = commonlib.gettable("MyCompany.Aries.Game.Network.NetworkMain");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local ConnectionTCP = commonlib.gettable("MyCompany.Aries.Game.Network.ConnectionTCP");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");

local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

local NetClientHandler = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.NetHandler"), commonlib.gettable("MyCompany.Aries.Game.Network.NetClientHandler"));

function NetClientHandler:ctor()
end

-- create a tcp connection to server. 
function NetClientHandler:Init(ip, port, username, password, worldClient, tunnelClient)
	self.worldClient = worldClient;
	local nid;
	if(tunnelClient) then
		-- TODO: this should be the username of the private host server. 
		-- here we just use "_admin" for the first user in the room. 
		nid = "_admin";
	else
		nid = self:CheckGetNidFromIPAddress(ip, port);
	end
	
	BroadcastHelper.PushLabel({id="NetClientHandler", label = format(L"正在建立链接:%s:%s", ip, port or ""), max_duration=7000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
	self.connection = ConnectionTCP:new():Init(nid, nil, self, tunnelClient);
	self.connection:Connect(5, function(bSucceed)
		-- try authenticate
		if(bSucceed) then
			BroadcastHelper.PushLabel({id="NetClientHandler", label = format(L"成功建立链接:%s:%s", ip, port or ""), max_duration=4000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
			self:SendLoginPacket(username, password);
		end
	end);
	return self;
end

function NetClientHandler:SendLoginPacket(username, password)
	self.last_username = username;
	self.last_password = password;
	self:AddToSendQueue(Packets.PacketAuthUser:new():Init(username, password));
end

function NetClientHandler:GetUserName()
	return self.last_username;
end

function NetClientHandler:GetNid()
	return self.connection:GetNid();
end

 -- Adds the packet to the send queue
function NetClientHandler:AddToSendQueue(packet)
    if (not self.disconnected and self.connection) then
        return self.connection:AddPacketToSendQueue(packet);
    end
end

-- clean up connection. 
function NetClientHandler:Cleanup()
    if (self.connection) then
        self.connection:NetworkShutdown();
    end
    self.connection = nil;
	if(self.worldClient) then
	end
end

function NetClientHandler:handleErrorMessage(text)
	LOG.std(nil, "info", "NetClientHandler", "client connection error %s", text or "");

	if(text == "ConnectionNotEstablished") then
		BroadcastHelper.PushLabel({id="NetClientHandler", label = L"无法链接到这个服务器", max_duration=6000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
		_guihelper.MessageBox(L"无法链接到这个服务器,可能该服务器未开启或已关闭.详情请联系该服务器管理员.");
	else --if(text == "OnConnectionLost") then
		if(GameLogic.GetWorld() == self.worldClient) then
			BroadcastHelper.PushLabel({id="NetClientHandler", label = L"与服务器的连接断开了", max_duration=6000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
			NetworkMain.isClient = false;
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ServerPage.lua");
			local ServerPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.ServerPage");
			ServerPage.ResetClientInfo()
			local player = EntityManager.GetPlayer()
			if(player) then
				player:SetHeadOnDisplay({url=ParaXML.LuaXML_ParseString(format('<pe:mcml><div style="background-color:red;margin-left:-50px;margin-top:-20">%s</div></pe:mcml>', L"与服务器的连接断开了"))})
			end
			_guihelper.MessageBox(L"已与服务器断开连接,可能服务器已关闭或有其他用户使用该帐号登录.点击\"确定\"返回本地世界",function (result)
--				NPL.load("(gl)script/apps/Aries/Creator/Game/Login/InternetLoadWorld.lua");
--				local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
--				InternetLoadWorld.EnterWorld()
				--if(result == _guihelper.DialogResult.Yes) then
				--end
			end,_guihelper.MessageBoxButtons.OK);
			--local player = self.worldClient:GetPlayer();
			--if(player) then
				--player:UpdateDisplayName("oops! ConnectionLost!");
			--end
		else
			_guihelper.MessageBox(L"服务器返回错误信息"..(text or ""));
		end
	end
	self:Cleanup();
end

function NetClientHandler:GetEntityByID(id)
	if(id == self.worldClient:GetPlayer().entityId) then
		return self.worldClient:GetPlayer();
	else
		return self.worldClient:GetEntityByID(id);
	end
end

function NetClientHandler:handleAuthUser(packet_AuthUser)
	if(packet_AuthUser.result == "ok") then
		-- load empty world first and then login. 
		self.last_username = packet_AuthUser.username;
		-- create the client side player entity
		self.worldClient.isRemote = true;
	
		-- only add when this is a connected world
		NetworkMain:AddClient(self.worldClient);
		--NetworkMain:SetAsClient();
		NetworkMain.isClient = true;
		local bStartNewWorld = true;
		if(bStartNewWorld) then
			-- spawn in a new world
			MyCompany.Aries.Game.StartEmptyClientWorld(self.worldClient, function()
				-- empty world is prepared, so request to login. 
				self:AddToSendQueue(Packets.PacketLoginClient:new():Init());
			end);
		else
			-- replace current world: only used in debugging
			if(not GameLogic.GetWorld() or (not GameLogic.GetWorld():isa(MyCompany.Aries.Game.World.WorldClient) and not GameLogic.GetWorld():isa(MyCompany.Aries.Game.World.WorldServer))) then
				GameLogic.ReplaceWorld(self.worldClient);
			end
			self:AddToSendQueue(Packets.PacketLoginClient:new():Init());
		end
	elseif(packet_AuthUser.result == "failed") then
		if(not self.last_password or self.last_password=="") then
			BroadcastHelper.PushLabel({id="NetClientHandler", label = L"连接成功：此服务器需要认证", max_duration=7000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
		else
			BroadcastHelper.PushLabel({id="NetClientHandler", label = L"用户名密码不正确", max_duration=7000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
		end
		
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ServerPage.lua");
		local ServerPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.ServerPage");
		ServerPage.ShowUserLoginPage(self,packet_AuthUser.info);
	elseif(packet_AuthUser.result == "not allowed") then
		local text = L"服务器暂时不允许链接， 可能是已经满了。"..(packet_AuthUser.info.errMsg or "");
		BroadcastHelper.PushLabel({id="NetClientHandler", label = text, max_duration=7000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
		self:Cleanup();
	end
end

function NetClientHandler:handleLogin(packet_login)
	local entityPlayer = self.worldClient:CreateClientPlayer(packet_login.clientEntityId, self);
	self.currentServerMaxPlayers = packet_login.maxPlayers;
	packet_login = GameLogic.GetFilters():apply_filters("handleLogin", packet_login);
	entityPlayer:AutoFindPosition(true);

	GameLogic:event(System.Core.Event:new():init("ps_client_login"));
end

function NetClientHandler:handleSpawnPosition(packet_SpawnPosition)
	LOG.std(nil, "debug", "NetClientHandler.handleSpawnPosition", packet_SpawnPosition);
    self.worldClient:SetSpawnPoint(packet_SpawnPosition.x, packet_SpawnPosition.y, packet_SpawnPosition.z);
end

function NetClientHandler:handleChat(packet_Chat)
    LOG.std(nil, "debug", "NetClientHandler.handleChat", "%s", packet_Chat.text);
	Desktop.GetChatGUI():PrintChatMessage(packet_Chat:ToChatMessage())
end

function NetClientHandler:handleAnimation(packet_Animation)
    local entity = self:GetEntityByID(packet_Animation.entityId);
	if(entity) then
		entity:SetAnimation(packet_Animation.anim_id);
	end
end

function NetClientHandler:handlePlayerInfo(packet_PlayerInfo)
end


-- this is usaully called periodially in addition to RelEntity, to force a complete position update. 
function NetClientHandler:handleEntityMove(packet_EntityMove)
	local entityOther = self:GetEntityByID(packet_EntityMove.entityId);
    if (entityOther) then
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

-- server wants us to teleport to a given position. 
function NetClientHandler:handleEntityTeleport(packet_EntityTeleport)
	local entityOther = self:GetEntityByID(packet_EntityTeleport.entityId);

    if (entityOther) then
        entityOther.serverPosX = packet_EntityTeleport.x;
        entityOther.serverPosY = packet_EntityTeleport.y;
        entityOther.serverPosZ = packet_EntityTeleport.z;
        local x = entityOther.serverPosX / 32;
        local y = entityOther.serverPosY / 32 + 0.015625;
        local z = entityOther.serverPosZ / 32;
        local facing;
		if(packet_EntityTeleport.facing) then
			facing = packet_EntityTeleport.facing / 32;
		end
		local pitch;
		if(packet_EntityTeleport.pitch) then
			pitch = packet_EntityTeleport.pitch / 32;
		end
		entityOther:SetPositionAndRotation(x, y, z, facing, pitch);

		-- send acknowledge msg back to server
		self:AddToSendQueue(Packets.PacketEntityTeleport:new());
    end
end

-- the server tells us to move to this accurate and unscaled location. 
function NetClientHandler:handleMove(packet_Move)
	local curPlayer;
	if(packet_Move.entityId) then
		curPlayer = self:GetEntityByID(packet_Move.entityId);
	else
		curPlayer = self.worldClient:GetPlayer();
	end
	
	if(curPlayer) then
		-- teleport the player, and confirm with a reply
		local posX = curPlayer.x;
		local posY = curPlayer.y;
		local posZ = curPlayer.z;
		local yaw = curPlayer.facing;
		local pitch = curPlayer.rotationPitch;
		if (packet_Move.x) then
			posX = packet_Move.x;
			posY = packet_Move.y;
			posZ = packet_Move.z;
		end
		if (packet_Move.yaw) then
			yaw = packet_Move.yaw;
			pitch = packet_Move.pitch;
		end
		curPlayer:SetPositionAndRotation(posX, posY, posZ, yaw, pitch);
		packet_Move.x = curPlayer.x;
		packet_Move.y = curPlayer.y;
		packet_Move.stance = curPlayer.y;
		packet_Move.z = curPlayer.z;
		self:AddToSendQueue(packet_Move);
	end
end


function NetClientHandler:handleEntityPlayerSpawn(packet_EntityPlayerSpawn)
	local x = packet_EntityPlayerSpawn.x / 32;
    local y = packet_EntityPlayerSpawn.y / 32;
    local z = packet_EntityPlayerSpawn.z / 32;
    local facing = packet_EntityPlayerSpawn.facing / 32;
	
    local pitch = packet_EntityPlayerSpawn.pitch / 32;
	local clientMP = self:GetEntityByID(packet_EntityPlayerSpawn.entityId);
	if(not clientMP or not clientMP:isa(EntityManager.EntityPlayerMPOther)) then
		clientMP = EntityManager.EntityPlayerMPOther:new():init(self.worldClient, packet_EntityPlayerSpawn.name, packet_EntityPlayerSpawn.entityId);	
	else
		LOG.std(nil, "warn", "NetClientHandler", "client MP with id %d already exist", packet_EntityPlayerSpawn.entityId);
	end
    clientMP.prevPosX = packet_EntityPlayerSpawn.x;
	clientMP.lastTickPosX = packet_EntityPlayerSpawn.x;
	clientMP.serverPosX = packet_EntityPlayerSpawn.x;
    clientMP.prevPosY = packet_EntityPlayerSpawn.y;
	clientMP.lastTickPosY = packet_EntityPlayerSpawn.y;
	clientMP.serverPosY = packet_EntityPlayerSpawn.y;
    clientMP.prevPosZ = packet_EntityPlayerSpawn.z;
	clientMP.lastTickPosZ = packet_EntityPlayerSpawn.z;
	clientMP.serverPosZ = packet_EntityPlayerSpawn.z;
    clientMP:SetPositionAndRotation(x, y, z, facing, pitch);
	local watcher = clientMP:GetDataWatcher();
	if(watcher) then
		watcher:UpdateWatchedObjectsFromList(packet_EntityPlayerSpawn:GetMetadata());
	end

	clientMP:Attach();
end


function NetClientHandler:handleEntityHeadRotation(packet_entity_head_rotation)
	local entityOther = self:GetEntityByID(packet_entity_head_rotation.entityId);
	if(entityOther) then
		local rot = (packet_entity_head_rotation.rot or 0)/32;
		local pitch = (packet_entity_head_rotation.pitch or 0)/32;
		
		if(entityOther.SetTargetHeadRotation) then
			entityOther:SetTargetHeadRotation(rot, pitch, 3);
		end
	end
end

-- when entity of other entityMP moves relatively. 
function NetClientHandler:handleRelEntity(packet_RelEntity)
    local entityOther = self:GetEntityByID(packet_RelEntity.entityId);

    if (entityOther) then
        entityOther.serverPosX = entityOther.serverPosX + (packet_RelEntity.x or 0);
        entityOther.serverPosY = entityOther.serverPosY + (packet_RelEntity.y or 0);
        entityOther.serverPosZ = entityOther.serverPosZ + (packet_RelEntity.z or 0);
        local x = entityOther.serverPosX / 32;
        local y = entityOther.serverPosY / 32;
        local z = entityOther.serverPosZ / 32;

		local facing;
		if(packet_RelEntity.facing) then
			facing = packet_RelEntity.facing / 32;
		end
		local pitch;
		if(packet_RelEntity.pitch) then
			pitch = packet_RelEntity.pitch / 32;
		end
        entityOther:SetPositionAndRotation2(x, y, z, facing, pitch, 3);
    end
end
 
function NetClientHandler:handleEntityMetadata(packet_EntityMetadata)
    local entity = self:GetEntityByID(packet_EntityMetadata.entityId);

	if(entity~=self.worldClient:GetPlayer()) then
		-- ignore metadata for current player. 
		if (entity and packet_EntityMetadata:GetMetadata()) then
			local watcher = entity:GetDataWatcher();
			if(watcher) then
				watcher:UpdateWatchedObjectsFromList(packet_EntityMetadata:GetMetadata());

				-- tricky: for dummy object, framemove is not called, we will call it now to force entity.SyncDataWatcher to be called. 
				if (entity:IsDummy()) then
					entity:FrameMove(0);
				end
			end
		end
	end
end

function NetClientHandler:handleDestroyEntity(packet_DestroyEntity)
    for i =1, #(packet_DestroyEntity.entity_ids) do
        self.worldClient:RemoveEntityFromWorld(packet_DestroyEntity.entity_ids[i]);
    end
end

function NetClientHandler:handleBlockChange(packet_BlockChange)
	-- force local changes are commited before applying server patch
	self.worldClient:GetPlayerManager():SendAllChunkUpdates(true);
	self.worldClient:EnableWorldTracker(false);
	BlockEngine:SetBlock(packet_BlockChange.x, packet_BlockChange.y, packet_BlockChange.z, packet_BlockChange.blockid, packet_BlockChange.data);
	self.worldClient:EnableWorldTracker(true);
end    

function NetClientHandler:handleBlockMultiChange(packet_BlockMultiChange)
	-- force local changes are commited before applying server patch
	self.worldClient:GetPlayerManager():SendAllChunkUpdates(true);

	self.worldClient:EnableWorldTracker(false);
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
			BlockEngine:SetBlock(x, y, z, idList[i], dataList[i]);
        end
	end
	self.worldClient:EnableWorldTracker(true);
end

function NetClientHandler:handleBlockPieces(packet_BlockPieces)
	local block_template = block_types.get(packet_BlockPieces.blockid);
	if(block_template) then
		block_template:CreateBlockPieces(packet_BlockPieces.x,packet_BlockPieces.y,packet_BlockPieces.z, packet_BlockPieces.granularity);
	end
end

-- full chunk update of blocks, metadata
function NetClientHandler:handleMapChunk(packet_MapChunk)
	-- force local changes are commited before applying server patch
	self.worldClient:GetPlayerManager():SendAllChunkUpdates(true);

	if (packet_MapChunk.bIncludeInit) then
        if (packet_MapChunk.chunkExistFlag == 0) then
            self.worldClient:DoPreChunk(packet_MapChunk.x, packet_MapChunk.z, false);
            return;
        end
	end

    self.worldClient:InvalidateBlockReceiveRegion(packet_MapChunk.x*16, 0, packet_MapChunk.z*16, (packet_MapChunk.x*16) + 15, 256, (packet_MapChunk.z*16) + 15);
    local chunk = self.worldClient:GetChunkFromChunkCoords(packet_MapChunk.x, packet_MapChunk.z);

    if (packet_MapChunk.bIncludeInit and not chunk) then
        self.worldClient:DoPreChunk(packet_MapChunk.x, packet_MapChunk.z, true);
        chunk = self.worldClient:GetChunkFromChunkCoords(packet_MapChunk.x, packet_MapChunk.z);
    end

    if (chunk) then
		chunk:FillChunk(packet_MapChunk:GetCompressedChunkData(), packet_MapChunk.chunkExistFlag, packet_MapChunk.includeInitialize);
        -- mark re render the blocks. 
        if (not packet_MapChunk.bIncludeInit) then
            chunk:ResetRelightChecks();
        end
    end
end

-- initial chunk updates
function NetClientHandler:handleMapChunks(packet_MapChunks)
	for i = 1, packet_MapChunks:GetNumberOfChunks() do
        local chunkX = packet_MapChunks:GetChunkPosX(i);
        local chunkZ = packet_MapChunks:GetChunkPosZ(i);
        self.worldClient:DoPreChunk(chunkX, chunkZ, true);
        self.worldClient:InvalidateBlockReceiveRegion(chunkX*16, 0, chunkZ*16, (chunkX*16) + 15, 256, (chunkZ*16) + 15);
        local chunk = self.worldClient:GetChunkFromChunkCoords(chunkX, chunkZ);
		
		if (chunk) then
			chunk:FillChunk(packet_MapChunks:GetCompressedChunkData(i), packet_MapChunks.chunkExistFlag[i], true);
			-- mark re render the blocks. 
			chunk:ResetRelightChecks();
        end
    end
end

function NetClientHandler:handleKickDisconnect(packet_KickDisconnect)
	
end

function NetClientHandler:handleUpdateEntitySign(packet_UpdateEntitySign)
	local blockEntity = EntityManager.GetBlockEntity(packet_UpdateEntitySign.x, packet_UpdateEntitySign.y, packet_UpdateEntitySign.z)
	if(blockEntity) then
		blockEntity:OnUpdateFromPacket(packet_UpdateEntitySign);
	end
end

function NetClientHandler:handleUpdateEntityBlock(packet_UpdateEntityBlock)
	local blockEntity = EntityManager.GetBlockEntity(packet_UpdateEntityBlock.x, packet_UpdateEntityBlock.y, packet_UpdateEntityBlock.z)
	if(blockEntity) then
		blockEntity:OnUpdateFromPacket(packet_UpdateEntityBlock);
	end
end

function NetClientHandler:handleMobSpawn(packet_MobSpawn)
	local x = packet_MobSpawn.x / 32;
    local y = packet_MobSpawn.y / 32;
    local z = packet_MobSpawn.z / 32;
   
	local spawnedEntity;
    local entity_type = packet_MobSpawn.type;
	if(entity_type == 11) then
		spawnedEntity = EntityManager.EntityMob:Create({x=x,y=y,z=z, item_id = packet_MobSpawn.item_id or block_types.names["player_spawn_point"]});
		LOG.std(nil, "debug", "client::handleMobSpawn", "mob");
	elseif(entity_type == 12) then
		spawnedEntity = EntityManager.EntityNPC:Create({x=x,y=y,z=z, item_id = packet_MobSpawn.item_id or block_types.names["villager"]});
		LOG.std(nil, "debug", "client::handleMobSpawn", "NPC");
	elseif(entity_type == 13) then
		spawnedEntity = EntityManager.EntityItem:new():Init(x,y,z, ItemStack:new():Init(packet_MobSpawn.item_id,1));
		LOG.std(nil, "debug", "client::handleMobSpawn", "item: %d", packet_MobSpawn.item_id or -1);
	elseif(entity_type == 14) then
		spawnedEntity = EntityManager.EntityCollectable:Create({x=x,y=y,z=z, item_id = packet_MobSpawn.item_id or block_types.names["gold_coin"]});
		LOG.std(nil, "debug", "client::handleMobSpawn", "Collectable: %d", packet_MobSpawn.item_id or -1);
	elseif(entity_type == 10) then
		spawnedEntity = EntityManager.EntityRailcar:Create({x=x,y=y,z=z, item_id = packet_MobSpawn.item_id or block_types.names["railcar"]});
		LOG.std(nil, "debug", "client::handleMobSpawn", "railcar: %d", packet_MobSpawn.item_id or -1);
	else
		-- TODO: add other types
	end

	if(spawnedEntity) then
		spawnedEntity.serverPosX = packet_MobSpawn.x;
        spawnedEntity.serverPosY = packet_MobSpawn.y;
        spawnedEntity.serverPosZ = packet_MobSpawn.z;
		spawnedEntity.rotationYaw = packet_MobSpawn.yaw / 32;
        spawnedEntity.rotationPitch = packet_MobSpawn.pitch / 32;
		spawnedEntity.entityId = packet_MobSpawn.entityId;
		
		spawnedEntity:SetPositionAndRotation2(x, y, z, spawnedEntity.rotationYaw, spawnedEntity.rotationPitch);

		local watcher = spawnedEntity:GetDataWatcher();
		if(watcher) then
			watcher:UpdateWatchedObjectsFromList(packet_MobSpawn:GetMetadata());
		end

		-- add to world
		spawnedEntity:Attach();
	end	
end

function NetClientHandler:handleMovableSpawn(packet_EntityMovableSpawn)
	local x = packet_EntityMovableSpawn.x / 32;
    local y = packet_EntityMovableSpawn.y / 32;
    local z = packet_EntityMovableSpawn.z / 32;
   
	local spawnedEntity;
    local entity_type = packet_EntityMovableSpawn.type;
	if(entity_type == 10) then
		spawnedEntity = EntityManager.EntityRailcar:Create({x=x,y=y,z=z, item_id = block_types.names["railcar"]});
	else
		-- TODO: add other types
	end

	if(spawnedEntity) then
		spawnedEntity.serverPosX = packet_EntityMovableSpawn.x;
        spawnedEntity.serverPosY = packet_EntityMovableSpawn.y;
        spawnedEntity.serverPosZ = packet_EntityMovableSpawn.z;
		spawnedEntity.rotationYaw = packet_EntityMovableSpawn.yaw / 32;
        spawnedEntity.rotationPitch = packet_EntityMovableSpawn.pitch / 32;
		spawnedEntity.entityId = packet_EntityMovableSpawn.entityId;
		
		spawnedEntity:SetPositionAndRotation2(x, y, z, spawnedEntity.rotationYaw, spawnedEntity.rotationPitch);

		-- add to world
		spawnedEntity:Attach();
	end
end

function NetClientHandler:handleAttachEntity(packet_AttachEntity)
	local fromEntity = self:GetEntityByID(packet_AttachEntity.entityId);
	local toEntity;
	if(packet_AttachEntity.vehicleEntityId and packet_AttachEntity.vehicleEntityId>=0) then
		toEntity = self:GetEntityByID(packet_AttachEntity.vehicleEntityId);
	end
	if(fromEntity) then
		fromEntity:MountEntity(toEntity);
	end
end

function NetClientHandler:handleUpdateEnv(packet_env)
	if(packet_env.texturePack) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/TextureModPage.lua");
		local TextureModPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TextureModPage");
		TextureModPage.OnApplyTexturePack(packet_env.texturePack.type,packet_env.texturePack.path,packet_env.texturePack.url, nil, packet_env.text);
	end
	if(packet_env.customBlocks) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
		local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
		ItemClient.LoadCustomBlocks(packet_env.customBlocks)
	end
	-- LOG.std(nil, "info", "handleUpdateEnv", packet_env);
end

function NetClientHandler:handleEntityFunction(packet_EntityFunction)
	local fromEntity = self:GetEntityByID(packet_EntityFunction.entityId);
	if(fromEntity) then
		local name = packet_EntityFunction.name;
		local param = packet_EntityFunction.param;
		if(name == "say") then
			if(param and param.text) then
				fromEntity:Say(param.text, param.duration, param.bAbove3D);
			end
		end
	end
end

function NetClientHandler:handlePlayerInventory(packet_PlayerInventory)
	local fromEntity = self:GetEntityByID(packet_PlayerInventory.entityId);
	if(fromEntity and fromEntity.inventory and packet_PlayerInventory.slot_index) then
		local itemStack = packet_PlayerInventory.itemStack or {};
		fromEntity.inventory:SetItemByBagPos(packet_PlayerInventory.slot_index, itemStack.id, itemStack.count);
	end
end

function NetClientHandler:handleClientCommand(packet_ClientCommand)
	local cmd = packet_ClientCommand.cmd;
	if(cmd) then
		local cmd_class, cmd_name, cmd_text = CommandManager:GetCmdByString(cmd);
		-- only local command is callable by server. 
		if(cmd_class and cmd_class:IsLocal()) then
			CommandManager:RunFromConsole(cmd, self.playerEntity);
		end
	end
end

-- server replied with a file
function NetClientHandler:handleGetFile(packet_GetFile)
	if(packet_GetFile.filename and packet_GetFile.data) then
		if(packet_GetFile.data ~= "") then
			local filename = Files.WorldPathToFullPath(packet_GetFile.filename, false)
			if(filename) then
				ParaIO.CreateDirectory(filename);
				local file = ParaIO.open(filename, "w")
				if(file:IsValid()) then
					file:WriteString(packet_GetFile.data, #(packet_GetFile.data));
					file:close();
					LOG.std(nil, "info", "NetClientHandler", "world file received and saved to %s", filename)
				end
			end
		end
	end
end

function NetClientHandler:handlePutFile(packet_PutFile)
	if(packet_PutFile.filename and not packet_PutFile.data) then
		local filename = Files.WorldPathToFullPath(packet_PutFile.filename)
		if(ParaIO.DoesFileExist(filename, true)) then
			-- only request from server if file is already used. 
			self:AddToSendQueue(Packets.PacketGetFile:new():Init(packet_PutFile.filename));		
		end
	end
end

function NetClientHandler:handleCodeBlockEvent(packet_CodeBlockEvent)
	local name = packet_CodeBlockEvent.name;
	if(name == "ps_broadcast" or name == "ps_redirect") then
		-- do nothing
	elseif(name == "ps_restart_codeblock") then
		local data = packet_CodeBlockEvent.data
		if(data and data.name) then
			
		end
	else
  		GameLogic.GetCodeGlobal():handleNetworkEvent(name, packet_CodeBlockEvent.data);
	end
end
