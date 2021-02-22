--[[
Title: Entity Manager in block world
Author(s): LiXizhi
Date: 2013/1/23
Desc: It manages character object with AI in the block world. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
EntityManager.FrameMove();
EntityManager.AddObject(obj)
local entities = EntityManager.GetEntitiesInBlock(bx, by, bz)
if(entities) then
	for entity, _ in pairs(entities) do
	end
end
EntityManager.HasEntityInBlock(bx, by, bz)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/Entity.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/BlockContainer.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/RegionContainer.lua");
NPL.load("(gl)script/ide/math/bit.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ChunkLocation.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPool.lua");
local EntityPool = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPool");
local ChunkLocation = commonlib.gettable("MyCompany.Aries.Game.Common.ChunkLocation");
local RegionContainer = commonlib.gettable("MyCompany.Aries.Game.EntityManager.RegionContainer");
local BlockContainer = commonlib.gettable("MyCompany.Aries.Game.EntityManager.BlockContainer");
local EntityPlayer = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPlayer")
local EntityMob = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMob")
local EntityNPC = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityNPC")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local EntityCollectable = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCollectable")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;
local math_floor = math.floor;

local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
commonlib.add_interface(EntityManager, commonlib.gettable("System.Core.AttributeObject"))

local default_filename = "entity.xml";

-- all active dynamic world object
local dynamic_objects = commonlib.UnorderedArray:new();
local static_objects = {};
-- 512*512 region entities
local regions = {};
-- mapping from block index to entity object. 
local block_cache = {};
-- containers
local block_containers = {};
-- mapping from packed chunk column pos to array of block entities. 
local chunk_column_entities = {};

-- mapping from scene object id to entity object. 
local obj_id_maps = {};
-- mapping from entity name to entity object. 
local obj_name_maps = {};
-- entity ids
local entity_id_maps = {};

-- mapping from entity to true. 
local senstient_list = {};
-- mapping from chunk_index to frame_tick or -1. if -1 it is always active
local active_chunks = {};

-- temp framemove list
local framemove_queue_size = 0;
local framemove_queue = {};


local entity_count_stats = {};

local cur_player;
local cur_focus;
local players = {};
local frame_count = 0;

EntityManager.entity_classes = {};

function EntityManager.RegisterEntities()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCollectable.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMob.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityNPC.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPlayer.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntitySign.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityImage.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityItemFrame.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityChest.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCommandBlock.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityItem.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMusicBox.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityNote.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCmdTextureReplacer.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCollisionSensor.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityHomePoint.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockDynamic.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityDesktop.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMovieClip.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCamera.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityWeatherEffect.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityRainEffect.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntitySnowEffect.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityRailcar.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPlayerMP.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPlayerMPOther.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPlayerMPClient.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockModel.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntitySky.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockBone.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityOverlay.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityLight.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMemory.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCheckpoint.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCode.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/EntityCodeActor.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityAnimModel.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityAnimCharacter.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityLightChar.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityAgentSign.lua");
end

-- register a new entity class
function EntityManager.RegisterEntityClass(name, entity)
	EntityManager.entity_classes[name or entity.class_name] = entity;
end

-- get entity class
function EntityManager.GetEntityClass(class_name)
	return EntityManager.entity_classes[class_name or ""];
end

---------------------------------
-- attribute interface
---------------------------------
-- get child attribute object. this can be regarded as an intrusive data model of a given object. 
-- once you get an attribute object, you can use this model class to access all data in the hierarchy.
function EntityManager:GetChild(sName)
	return EntityManager.GetEntity(name);
end

-- @param nColumnIndex: nil to default to 0;
function EntityManager:GetChildAt(nRowIndex, nColumnIndex)
	if(nRowIndex == 0) then
		return System.Core.TableAttribute:create(obj_name_maps, "all_entities");
	elseif(nRowIndex == 1) then
		return System.Core.TableAttribute:create(senstient_list, "senstient_list");
	elseif(nRowIndex == 2) then
		return System.Core.TableAttribute:create(regions, "regions");
	end
end

-- @param nColumnIndex: if nil, default to 0. 
function EntityManager:GetChildCount(nColumnIndex)
	nColumnIndex = nColumnIndex or 0;
	if(nColumnIndex == 0) then
		return 3;
	end
	return 0;
end


function EntityManager.Clear()
	dynamic_objects:clear();

	for entity, _ in pairs(static_objects) do
		entity:OnRemoved();
	end
	static_objects = {};

	block_cache = {};
	block_containers = {};
	chunk_column_entities = {};
	obj_id_maps = {};
	obj_name_maps = {};
	entity_id_maps = {};
	regions = {};
	cur_player = nil;
	cur_focus = nil;
	players = {};
	senstient_list = {};
	framemove_queue = {};
	active_chunks = {};

	last_trigger_entity = nil;
	EntityPool:ClearAllPools();
end

-- whether the given block is blocked. 
-- TODO: cache the query result for a single framemove. this function may be called many times in a single frame. 
function EntityManager.IsBlocked(bx, by, bz)
	local block_id = ParaTerrain.GetBlockTemplateByIdx(bx, by, bz);	
	return block_id~=0;
end

-- add entity. 
function EntityManager.AddObject(entity)
	if(not entity) then
		LOG.std(nil, "warn", "EntityManager", "calling AddObject with invalid entity");
		return;
	end
	if(entity.is_dynamic) then
		dynamic_objects:push_back(entity)
	else
		static_objects[entity] = true;
	end
	if(entity.obj_id) then
		EntityManager.SetEntityByObjectID(entity.obj_id, entity);
	end
	if(entity.name) then
		obj_name_maps[entity.name] = entity;
	end
	if(entity.entityId) then
		entity_id_maps[entity.entityId] = entity;
	end
	EntityManager.AddEntityCount(entity.item_id, 1);
	if(entity.isServerEntity) then
		GameLogic.GetWorld():OnEntityAdded(entity);
	end
end

function EntityManager.AddEntityCount(item_id, delta_count)
	if(item_id) then
		entity_count_stats[item_id] = (entity_count_stats[item_id] or 0) + delta_count;
	end
end

-- remove entity from manager. 
function EntityManager.RemoveObject(entity)
	if(entity.isServerEntity) then
		GameLogic.GetWorld():OnEntityRemoved(entity);
	end
	static_objects[entity] = nil;
	if(entity.obj_id) then
		EntityManager.SetEntityByObjectID(entity.obj_id, nil);
		entity.obj_id = nil;
	end
	local name = entity.name;
	if(name and entity == obj_name_maps[name]) then
		obj_name_maps[name] = nil;
	end
	if(entity.entityId and entity_id_maps[entity.entityId] == entity) then
		entity_id_maps[entity.entityId] = nil;
	end
	EntityManager.AddEntityCount(entity.item_id, -1);
	entity:OnRemoved();
end

function EntityManager.GetAllEntities()
	return entity_id_maps;
end

-- get item count by block_id
function EntityManager.GetItemCount(item_id)
	return entity_count_stats[item_id] or 0;
end

-- Load all entity data from a given XML file. 
-- @param filename: if nil, it search the "[currentworld]/entity.xml"
-- @return true if there is local NPC file. or nil if not. 
function EntityManager.LoadFromFile(filename)
	entity_count_stats = {};

	EntityManager.RegisterEntities();
	EntityManager.InitPlayers();
	
	if(not filename) then
		local test_filename = format("%s%s", ParaWorld.GetWorldDirectory(), default_filename);
		if(ParaIO.DoesAssetFileExist(test_filename, true))then
			filename = test_filename;
		end
	end

	if(not filename) then
		return;
	end

	-- load using a temporary global region container
	RegionContainer:new():init(-1,-1, filename):LoadFromFile();
end

-- init player. Set and load current player. 
function EntityManager.InitPlayers()
	if(not cur_player) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPlayer.lua");
		local entity = EntityManager.LoadPlayer(GameLogic.options:GetPlayerName());
		if(not entity.displayName) then
			entity:SetDisplayName(tostring(System.User.nid) or "");	
		end
		entity:BindToScenePlayer(ParaScene.GetPlayer());
		entity:UpdateBlockContainer();
		entity:SetFocus();
		EntityManager.SetMainPlayer(entity);
	end
end

function EntityManager.GetPlayerFileName(name)
end

-- Returns true if there are no solid, live entities in the specified location, excluding the given entity
-- @param excludingEntity: usually the current player. 
function EntityManager.CheckNoEntityCollision(x,y,z, excludingEntity)
	local entities = EntityManager.GetEntitiesInBlock(x,y,z);
	if(entities) then
		for entity, _ in pairs(entities) do
			if(not entity.isDead and entity:IsVisible() and (not excludingEntity or entity~=excludingEntity)) then
				return false;
			end
		end
	end
	return true;
end

-- the lastest trigger entity, such as the one that pressed a button or step on a pressure plat, etc.  
function EntityManager.GetLastTriggerEntity()
	return last_trigger_entity;
end

-- set lastest trigger entity. 
function EntityManager.SetLastTriggerEntity(entity)
	last_trigger_entity = entity;
end

-- get or load or create a player of the given name. 
function EntityManager.LoadPlayer(name)
	local player = EntityManager.GetPlayer(name);
	if(not player) then
		local save_handler = GameLogic.GetSaveHandler();
		local world = GameLogic.GetWorld();
		if(save_handler and world) then
			player = EntityPlayer:new({username = name});
			save_handler:GetPlayerSaveHandler():ReadPlayerData(player);
			player:init(world);
			player:Attach();
			players[name] = player;
		end
	end
	return player;
end

-- set the main player that is being controlled. After this call, EntityManager.GetPlayer() will return the given player. 
-- the main player is always the player being controlled by the PlayerController.  
-- @param playerEntity: this could be EntityPlayerMP for server player, or EntityPlayer for standalone player, or EntityPlayerMPClient for client side main player
-- @return: the previous player if any. 
function EntityManager.SetMainPlayer(playerEntity)
	if(cur_player ~= playerEntity) then
		if(cur_player and cur_player.inventory) then
			-- this fixed a bug where quick select bar task is still selected. 
			cur_player.inventory:Clear();
		end
		local last_player = cur_player;
		cur_player = playerEntity;
		GameLogic.events:DispatchEvent({type = "OnPlayerReplaced" , });
		return last_player;
	else
		return cur_player;
	end
end

function EntityManager.SaveAllPlayers()
	local save_handler = GameLogic.GetSaveHandler();
	local world = GameLogic.GetWorld();
	if(save_handler and world) then
		for name, player in pairs(players) do
			save_handler:GetPlayerSaveHandler():WritePlayerData(player);
		end
	end
end


-- get player
-- @param name: if nil or "player", the current player is returned. 
function EntityManager.GetPlayer(name)
	if(not name) then
		return cur_player;
	else
		return players[name];
	end
end

-- get entity
function EntityManager.GetEntityByObjectID(obj_id)
	return obj_id_maps[obj_id];
end

-- get by name. 
function EntityManager.GetEntity(name)
	if(name) then
		return obj_name_maps[name];
	end
end

-- get by id. 
function EntityManager.GetEntityById(entityId)
	if(entityId) then
		return entity_id_maps[entityId];
	end
end

-- rename a given entity in the manager. 
function EntityManager.RenameEntity(entity, old_name, new_name)
	if(old_name) then
		if(obj_name_maps[old_name] == entity) then
			obj_name_maps[old_name] = nil;
		end
	end
	if(new_name) then
		obj_name_maps[new_name] = entity;
	end
end


-- get all entities by block id. 
-- @return nil or array of entities. 
function EntityManager.GetEntitiesByItemID(item_id)
	local entities;
	for _, entity in pairs(obj_name_maps) do
		if(entity.item_id == item_id) then
			entities = entities or {};
			entities[#entities+1] = entity;
		end
	end
	return entities;
end

function EntityManager.SetEntityByObjectID(obj_id, entity)
	obj_id_maps[obj_id] = entity;
end


-- return true if there is at least one entity at the blocok position. 
function EntityManager.HasEntityInBlock(bx, by, bz)
	local entities = EntityManager.GetEntitiesInBlock(bx, by, bz);
	if(entities) then
		local entity = next(entities);
		if(entity) then
			return true;
		end
	end
end

-- has non-player entity
function EntityManager.HasNonPlayerEntityInBlock(bx, by, bz)
	local entities = EntityManager.GetEntitiesInBlock(bx, by, bz);
	if(entities) then
		for entity,_ in pairs(entities) do
			if(entity:GetType() ~= "Player") then
				return true;
			end
		end
	end
end

-- get all entities in block. 
function EntityManager.GetEntitiesInBlock(bx, by, bz)
	local sparse_index = by*900000000+bx*30000+bz;
	local block_container = block_containers[sparse_index];
	if(block_container) then
		return block_container:GetEntities();
	end
end

-- get the block entity excluding other entity
function EntityManager.GetBlockEntity(bx, by, bz)
	local block = BlockEngine:GetBlock(bx, by, bz);
	if(block) then
		return block:GetBlockEntity(bx, by, bz);
	end
end

-- get the first entity that matches the class_name
function EntityManager.GetEntityInBlock(bx, by, bz, class_name)
	local entities = EntityManager.GetEntitiesInBlock(bx, by, bz);
	if(entities) then
		for entity,_ in pairs(entities) do
			if(entity:GetType() == class_name) then
				return entity;
			end
		end
	end
end

-- @param min_x, min_y, min_z: block position
-- @param max_x, max_y, max_z: block position
-- @param entity_class: nil to match any entity. 
function EntityManager.GetEntitiesByMinMax(min_x, min_y, min_z, max_x, max_y, max_z, entity_class)
	local output;
	for x = min_x, max_x do
		for y = min_y, max_y do
			for z = min_z, max_z do
				local entities = EntityManager.GetEntitiesInBlock(x, y, z);
				if(entities) then
					for entity,_ in pairs(entities) do
						if(not entity_class or entity:isa(entity_class)) then
							output = output or {};
							output[#output+1] = entity;
						end
					end
				end
			end
		end
	end
	return output;
end

-- @param entity_class: nil to match any entity. 
function EntityManager.GetEntitiesByAABBOfType(entity_class, aabb)
	if(not aabb) then
		return
	end
	local output;
	local min_x, min_y, min_z = aabb:GetMinValues();
	local max_x, max_y, max_z = aabb:GetMaxValues();
	
	min_x, min_y, min_z = BlockEngine:block(min_x, min_y, min_z);
	max_x, max_y, max_z = BlockEngine:block(max_x, max_y, max_z);

	for x = min_x, max_x do
		for y = min_y, max_y do
			for z = min_z, max_z do
				local entities = EntityManager.GetEntitiesInBlock(x, y, z);
				if(entities) then
					for entity,_ in pairs(entities) do
						if((not entity_class or entity:isa(entity_class)) and aabb:Intersect(entity:GetCollisionAABB())) then
							output = output or {};
							output[#output+1] = entity;
						end
					end
				end
			end
		end
	end
	return output;
end

-- Will get all entities within the specified AABB excluding the one passed into it. Args: entityToExclude, aabb
-- @return array of entities
function EntityManager.GetEntitiesByAABBExcept(aabb, excludingEntity)
	if(not aabb) then
		return
	end
	local output;
	local min_x, min_y, min_z = aabb:GetMinValues();
	local max_x, max_y, max_z = aabb:GetMaxValues();
	
	min_x, min_y, min_z = BlockEngine:block(min_x, min_y, min_z);
	max_x, max_y, max_z = BlockEngine:block(max_x, max_y, max_z);

	for x = min_x, max_x do
		for y = min_y, max_y do
			for z = min_z, max_z do
				
				local entities = EntityManager.GetEntitiesInBlock(x, y, z);
				if(entities) then
					for entity,_ in pairs(entities) do
						if(entity ~= excludingEntity) then
							output = output or {};
							output[#output+1] = entity;
						end
					end
				end
			end
		end
	end
	return output;
end

-- remove entity by its class_name at the given block position. 
-- all matching entities will be removed. 
function EntityManager.RemoveBlockEntity(bx, by, bz, class_name)
	local entities = EntityManager.GetEntitiesInBlock(bx, by, bz);
	if(entities) then
		local first_match, matches;
		for entity,_ in pairs(entities) do
			if(entity:GetType() == class_name) then
				if(not first_match) then
					first_match = entity;
				else
					matches = matches or {};
					matches[#matches+1] = entity;
				end
			end
		end
		if(first_match) then
			first_match:Destroy();
			if(matches) then
				for _, entity in ipairs(matches) do
					entity:Destroy();	
				end
			end
		end
		return;
	end
end

-- private: 
function EntityManager.GetBlockContainer(bx,by,bz)
	local sparse_index = by*900000000+bx*30000+bz;
	local block_container = block_containers[sparse_index];
	if(block_container) then
		return block_container;
	else
		block_container = BlockContainer:new({x=bx,y=by,z=bz})
		block_containers[sparse_index] = block_container;
		return block_container;
	end
end

function EntityManager.SetBlockContainer(bx,by,bz, block_container)
	local sparse_index = by*900000000+bx*30000+bz;
	block_containers[sparse_index] = block_container; 
end

-- @param cx, cz: chunk pos, if cz is nil, cx is packed index
-- return array of all entities in a given chunk column
function EntityManager.GetEntitiesInChunkColumn(cx, cz, bCreateIfNotExist)
	local packedChunkPos = cz and ChunkLocation.FromChunkToPackedChunk(cx, cz) or cx;
	local chunk_column = chunk_column_entities[packedChunkPos];
	if(not chunk_column and bCreateIfNotExist) then
		chunk_column = commonlib.UnorderedArraySet:new();
		chunk_column_entities[packedChunkPos] = chunk_column;
	end
	return chunk_column;
end

-- create get region object
function EntityManager.GetRegionContainer(bx,bz)
	local x = rshift(bx, 9);
	local z = rshift(bz, 9);

	local region = regions[x*128+z];
	if(region) then
		return region;
	else
		region = RegionContainer:new():init(x,z);
		regions[x*128+z] = region;
		return region;
	end
end

-- only get region without creating it. 
function EntityManager.GetRegion(bx,bz)
	local x = rshift(bx, 9);
	local z = rshift(bz, 9);

	local region = regions[x*128+z];
	if(region) then
		return region;
	end
end

function EntityManager.SaveToFile(bSaveToLastSaveFolder)
	local filename = format("%s%s", ParaWorld.GetWorldDirectory(), default_filename);
	
	
	local root = {name='entities', attr={file_version="0.1"} }
	local entity;
	local sortEntities = {};
		
	local x, y, z, posValue;
	for entity in pairs(static_objects) do 
		if( entity:IsPersistent() and not entity:IsRegional() and not entity:IsDead()) then
			local node = {name='entity', attr={}};
			entity:SaveToXMLNode(node, true);
			x, y, z = entity:GetBlockPos();

			posValue = (x or 0) * 100000000 +  (y or 0) * 1000000 + (z or 0);

			table.insert(sortEntities, {pos = posValue, node = node});

		end
	end
		
	table.sort(sortEntities, function(a, b)
		return a.pos < b.pos;
	end);
		
	for _, entity in ipairs(sortEntities) do
		table.insert(root, entity.node);
	end
			
	local xml_data = commonlib.Lua2XmlString(root,true, true) or "";
	if (#xml_data >= 10240) then
		local writer = ParaIO.CreateZip(filename, "");
		if (writer:IsValid()) then
			writer:ZipAddData("data", xml_data);
			writer:close();
		end
	else
		local file = ParaIO.open(filename, "w");
		if(file:IsValid()) then
			file:WriteString(xml_data);
			file:close();
		end
	end
		
	for _, region in pairs(regions) do
		if(region:IsModified()) then
			region:SaveToFile();
		end
	end

	EntityManager.SaveAllPlayers();
end

-- @param chunkX, chunkZ: chunk pos, if chunkZ is nil, chunkX is packed index
-- make the chunk at location always active or not. 
function EntityManager.SetChunkActive(chunkX, chunkZ, isActive)
	local nIndex = chunkZ and ChunkLocation.FromChunkToPackedChunk(chunkX, chunkZ) or chunkX;
	if(not active_chunks[nIndex]) then
		if(isActive) then
			active_chunks[nIndex] = -1;
		end
	else
		if(isActive) then
			active_chunks[nIndex] = -1;
		else
			active_chunks[nIndex] = nil;
		end
	end
end

-- @param chunkX, chunkZ: chunk pos, if chunkZ is nil, chunkX is packed index
-- @param tick: if nil, default to current frame_count
function EntityManager.TickChunk(chunkX, chunkZ, tick)
	local nIndex = chunkZ and ChunkLocation.FromChunkToPackedChunk(chunkX, chunkZ) or chunkX;
	local chunkValue = active_chunks[nIndex];
	tick = tick or frame_count;
	if(chunkValue~=-1 and chunkValue~=tick) then
		active_chunks[nIndex] = tick;
	end
end

-- set an entity so that its framemove function should always be called regardless of player position
function EntityManager.AddToSentientList(entity)
	if(entity) then
		senstient_list[entity] = true;
	end
end

-- remove an entity so that its framemove function should not be called unless it falls into player sensible range.
function EntityManager.RemoveFromSentientList(entity)
	if(entity) then
		senstient_list[entity] = nil;
	end
end

-- add to framemove entity list. 
-- framemove queue is necessary to prevent crash when adding or removing entity inside framemove function it self. 
local function AddEntityToFrameMoveQueue(entity)
	framemove_queue_size = framemove_queue_size + 1;
	framemove_queue[framemove_queue_size] = entity;
end

local destroy_list = commonlib.vector:new();

function EntityManager:GetDeltaTime()
	return self.deltaTime;
end

-- called every frame to simulate objects 
function EntityManager.FrameMove(deltaTime)
	local self = EntityManager;
	deltaTime = deltaTime/1000;
	self.deltaTime = deltaTime;

	local cur_time = commonlib.TimerManager.GetCurrentTime()/1000;
	local player = EntityManager.GetPlayer();
	if(not player) then
		return;
	end
	commonlib.npl_profiler.perf_begin("EntityManager.FrameMove");

	local focus_entity = EntityManager.GetFocus();
	if(focus_entity) then
		focus_entity:UpdatePosition();
		focus_entity:UpdateRotation();
	end
	if(player ~= focus_entity) then
		player:UpdatePosition();
		player:UpdateRotation();
	end

	frame_count = frame_count + 1;
	
	destroy_list:clear();
	
	-- dynamic entities
	EntityManager.FrameMoveDynamicObjects(deltaTime, cur_time, destroy_list);

	-- for always sentient objects, like CommandEntity with timed event
	EntityManager.FrameMoveSentientList(deltaTime, cur_time, destroy_list)

	-- make chunks near the current player active
	EntityManager.MakeChunksNearPlayerActive(player, player:GetSentientRadius(), frame_count);
	-- also framemove entities in active chunks
	EntityManager.FrameMoveAllActiveChunks(deltaTime, cur_time, destroy_list);

	-- frame move entities in pending queues in this frame. 
	EntityManager.FrameMoveQueueThisFrame(deltaTime, cur_time, destroy_list);

	if(#destroy_list>0) then
		for i = 1, #destroy_list do
			destroy_list[i]:Destroy();
		end
		destroy_list:clear();
	end
	commonlib.npl_profiler.perf_end("EntityManager.FrameMove");
end

-- pending list to framemove
function EntityManager.FrameMoveQueueThisFrame(deltaTime, cur_time, destroy_list)
	for i=1, framemove_queue_size do
		local entity = framemove_queue[i];
		entity:CheckFrameMove(deltaTime, cur_time, true);
	end
	framemove_queue_size = 0;
end

-- set focus to the given entity. 
-- The entity class's SetFocus() function should always call this fuction before it return true. 
function EntityManager.SetFocus(entity)
	if(cur_focus~=entity) then
		if(cur_focus) then
			cur_focus:OnFocusOut();
		end
		if(entity) then
			cur_focus = entity;
			entity:OnFocusIn();
		end
	end
end

-- get current focus
function EntityManager.GetFocus()
	return cur_focus;
end

-- dynamic object is always framemoved until they are dead. 
function EntityManager.FrameMoveDynamicObjects(deltaTime, cur_time, destroy_list)
	-- dynamic objects
	commonlib.npl_profiler.perf_begin("EntityManager.FrameMoveDynamicObjects");
	local i = 1;
	while i<=#dynamic_objects do
		local obj = dynamic_objects[i]
		obj:FrameMove(deltaTime);
		if(obj:IsDead()) then
			destroy_list[#destroy_list+1] = obj;
			dynamic_objects:remove(i);
		else
			i=i+1;
		end
	end
	commonlib.npl_profiler.perf_end("EntityManager.FrameMoveDynamicObjects");
end

function EntityManager.FrameMoveAllActiveChunks(deltaTime, cur_time, destroy_list)
	local inactive_chunks;
	local count = 0;
	for chunkIndex, value in pairs(active_chunks) do
		if(value == -1 or value == frame_count) then
			local entities = EntityManager.GetEntitiesInChunkColumn(chunkIndex);
			if(entities and #entities > 0) then
				EntityManager.FrameMoveEntities(entities, deltaTime, cur_time, destroy_list);
			end
			count = count + 1;
		else
			inactive_chunks = inactive_chunks or {};
			inactive_chunks[#inactive_chunks+1] = chunkIndex;
		end
	end
	if(inactive_chunks) then
		for _, chunkIndex in ipairs(inactive_chunks) do
			if(active_chunks[chunkIndex] ~= -1) then
				active_chunks[chunkIndex] = nil;
			end
		end
	end
end

-- all entities in the radius of the given player is framemoved. 
-- @param grid_radius: if nil, default to playerEntity:GetSentientRadius(). 
function EntityManager.MakeChunksNearPlayerActive(playerEntity, grid_radius)
	local blockX, blockY, blockZ = playerEntity:GetBlockPos(); 
	local cx, cz = ChunkLocation:GetChunkPosFromWorldPos(blockX, blockZ);
	grid_radius = grid_radius or playerEntity:GetSentientRadius(); -- so the actual radius is 8*16 = 128 meters. 
	local chunk_radius = math.floor(grid_radius / 16);
	for i = -chunk_radius, chunk_radius do
		for j = -chunk_radius, chunk_radius do
			EntityManager.TickChunk(cx+i, cz+j);
		end
	end
end

-- all entities in the list is framemoved. 
function EntityManager.FrameMoveEntities(entities, deltaTime, cur_time, destroy_list)
	-- static object may also has framemove
	for i=1, #entities do 
		local entity = entities[i];
		-- skip sentient object since we will framemove sentient object in another list. 
		if(entity and not senstient_list[entity]) then
			if(entity:IsDead()) then
				destroy_list[#destroy_list+1] = entity;
			else
				if( entity:CheckFrameMove(deltaTime, cur_time) ) then
					AddEntityToFrameMoveQueue(entity);
				end
			end
		end
	end
end

-- for always sentient objects, like CommandEntity with timed event
-- @param deltaTime: in seconds
-- @param cur_time: in seconds
function EntityManager.FrameMoveSentientList(deltaTime, cur_time, destroy_list)
	for entity,_ in pairs(senstient_list) do 
		if(entity:IsDead()) then
			destroy_list[#destroy_list+1] = entity;
		else
			if( entity:CheckFrameMove(deltaTime, cur_time) ) then
				AddEntityToFrameMoveQueue(entity);
			end
		end
	end
end

-- filter entity by params
-- @param params: {name, type, nontype, mname, count}
-- name: only entities with given name.
-- mname: match regular expression of the given name
-- type: only entities of given type. 
-- nontype: only entities not of the given type
-- r: get entities only less than r blocks from the origin
-- rm: get entities only more than rm blocks from the origin.
-- count: return as most this number of objects, usually in order of distance from the origin.
-- @param entities: nil or array of comparing entities
-- @return entity of nil
function EntityManager.FilterEntity(entity, params, entities)
	if(params.nontype and entity:IsOfType(params.nontype)) then
		return;
	end
	if(params.type and not entity:IsOfType(params.type)) then
		return;
	end
	if(params.name and entity:GetName() ~= params.name) then
		return;
	end
	if(params.mname and not entity:GetName():match(params.mname)) then
		return;
	end
	local distSq = 0;
	if(params.x) then
		distSq = entity:DistanceSqTo(params.x, params.y, params.z)
	end
	if(params.r and params.r*params.r < distSq) then
		return
	end
	if(params.rm and params.rm*params.rm > distSq) then
		return
	end
	if(params.count and entities and #entities>=params.count) then
		if(params.x) then
			-- replace by distance
			for i, entity_ in ipairs(entities) do
				if(entity_:DistanceSqTo(params.x, params.y, params.z) > distSq) then
					entities[i] = entity;
					break;
				end
			end
		end
	else
		return entity;
	end
end

-- find entities by a number of matching parameters
-- @param params: {category, type, nontype, name, x,y,z,dz,dy,dz,r,rm, count}
-- category: "e" all entities except block entities (if nil, it default to "e"),"p" for nearest player, "r" random player, "a" all players
-- "all" for all entities including block entities
-- "b" for block entities
-- "searchable" for all searchable entities including block entities 
-- name: only entities with given name.
-- type: only entities of given type. 
-- nontype: only entities not of the given type
-- x,y,z: center of origin to selects entities. 
-- r: get entities only less than r blocks from the origin
-- rm: get entities only more than rm blocks from the origin.
-- dx,dy,dz: this is a cubic volume as defined by extending these blocks from the origin.
-- count: return as most this number of objects, usually in order of distance from the origin.
-- @return nil or array of entities
function EntityManager.FindEntities(params)
	local output;
	if(not params.category or params.category == "e") then
		-- entities including players
		if(params.x) then
			if(params.r) then
				local radius = params.r;
				local min_x, min_y, min_z = params.x-radius, params.y-radius, params.z-radius;
				local max_x, max_y, max_z = params.x+radius, params.y+radius, params.z+radius;
			
				for x = min_x, max_x do
					for z = min_z, max_z do
						if(((x - params.x)^2 + (z - params.z)^2) <= radius*radius ) then
							for y = min_y, max_y do
								local entities = EntityManager.GetEntitiesInBlock(x, y, z);
								if(entities) then
									for entity,_ in pairs(entities) do
										if(not entity:IsBlockEntity() and EntityManager.FilterEntity(entity, params, output)) then
											output = output or {};
											output[#output+1] = entity;
										end
									end
								end
							end
						end
					end
				end
			elseif(params.dx or params.dy or params.dz) then
				local min_x, min_y, min_z = params.x, params.y, params.z;
				local max_x, max_y, max_z = params.x+(params.dx or 0), params.y+(params.dy or 0), params.z+(params.dz or 0);
				for x = min_x, max_x do
					for z = min_z, max_z do
						for y = min_y, max_y do
							local entities = EntityManager.GetEntitiesInBlock(x, y, z);
							if(entities) then
								for entity,_ in pairs(entities) do
									if(not entity:IsBlockEntity() and EntityManager.FilterEntity(entity, params, output)) then
										output = output or {};
										output[#output+1] = entity;
									end
								end
							end
						end
					end
				end
			end
		elseif(params.name) then
			local entity = EntityManager.GetEntity(params.name);
			if(entity) then
				output = output or {};
				output[#output+1] = entity;
			end
		end
	elseif(params.category == "p") then
		-- nearest players
		if(params.name) then
			local entity = EntityManager.GetPlayer(params.name);
			if(entity) then
				output = output or {};
				output[#output+1] = entity;
			end
		else
			for name, player in pairs(players) do
				if(EntityManager.FilterEntity(player, params, output)) then
					output = output or {};
					output[#output+1] = player;
				end
			end
		end
	elseif(params.category == "r") then
		-- random player, just return 1
		local i = 0;
		for name, player in pairs(players) do
			i = i + 1;
		end
		local index = i>1 and math.random(1, i) or 1;
		i = 0;
		for name, player in pairs(players) do
			i = i + 1;
			if(i == index) then
				output = output or {};
				output[#output+1] = player;
				break;
			end
		end
	elseif(params.category == "a") then
		-- all players
		for name, player in pairs(players) do
			if(EntityManager.FilterEntity(player, params, output)) then
				output = output or {};
				output[#output+1] = player;
			end
		end
	elseif(params.category == "all") then
		-- "all" for all entities including block entities 
		for _, entities in pairs(chunk_column_entities) do
			for i=1, #entities do
				local entity = entities[i];
				if(entity and EntityManager.FilterEntity(entity, params)) then
					output = output or {};
					output[#output+1] = entity;
				end
			end
		end
	elseif(params.category == "b") then
		-- "b" for block entities 
		for _, entities in pairs(chunk_column_entities) do
			for i=1, #entities do
				local entity = entities[i];
				if(entity and entity:IsBlockEntity() and EntityManager.FilterEntity(entity, params)) then
					output = output or {};
					output[#output+1] = entity;
				end
			end
		end
	elseif(params.category == "searchable") then
		-- "searchable" for all searchable entities including block entities 
		for _, entities in pairs(chunk_column_entities) do
			for i=1, #entities do
				local entity = entities[i];
				if(entity and entity:IsSearchable() and EntityManager.FilterEntity(entity, params)) then
					output = output or {};
					output[#output+1] = entity;
				end
			end
		end
	end
	return output;
end