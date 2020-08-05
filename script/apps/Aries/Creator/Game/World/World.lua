--[[
Title: World
Author(s): LiXizhi
Date: 2014/6/30
Desc: the base world class
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/World.lua");
local World = commonlib.gettable("MyCompany.Aries.Game.World.World")
local world = World:new():Init(server_manager);
world:FrameMove();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldBlockAccess.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Physics/PhysicsWorld.lua");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local GameRules = commonlib.gettable("MyCompany.Aries.Game.GameRules");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

---------------------------
-- create class
---------------------------
local World = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.World.WorldBlockAccess"), commonlib.gettable("MyCompany.Aries.Game.World.World"))

World.class_name = "World";

function World:ctor()
	self.worldTrackers = commonlib.UnorderedArray:new();
	if(self.cpp_chunk == nil) then
		self.cpp_chunk = true;
	end
end

-- @param server_manager: can be nil for client or standalone
-- @param saveHandler: can be nil for WorldClient
function World:Init(server_manager, saveHandler)
	self:SetSeed(WorldCommon.GetWorldTag("seed") or GameLogic.options.world_seed);
	if(not saveHandler) then
		-- create a null handler if no one is specified. 
		NPL.load("(gl)script/apps/Aries/Creator/Game/World/SaveWorldHandler.lua");
		local SaveWorldHandler = commonlib.gettable("MyCompany.Aries.Game.SaveWorldHandler")
		saveHandler = SaveWorldHandler:new():Init("");
	end
	self.saveHandler = saveHandler;
	self.options = GameLogic.options;
	self.chunkProvider = self:CreateChunkProvider();
	self:InitBlockGenerator();
	return self;
end

-- virtual function: Creates the chunk provider for this world. Called in the constructor. 
function World:CreateChunkProvider()
    NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkProviderServer.lua");
	local ChunkProviderServer = commonlib.gettable("MyCompany.Aries.Game.World.ChunkProviderServer");
	return ChunkProviderServer:new():Init(self);
end

function World:GetChunkProvider()
	return self.chunkProvider;
end

function World:GetServerManager()
	return nil;
end

function World:GetPlayer()
	return EntityManager.GetPlayer();
end

function World:OnPreloadWorld()
	GameLogic.SetIsRemoteWorld(false, false);
end

function World:GetWorldPath()
	if(not self.worldpath) then
		self.worldpath = ParaWorld.GetWorldDirectory();
	end
	return self.worldpath;
end

-- world tag "world_generator", "seed"
function World:InitBlockGenerator()
	-- load block generator
	local block = commonlib.gettable("MyCompany.Aries.Game.block")
	local world_generator = WorldCommon.GetWorldTag("world_generator");
	local seed = WorldCommon.GetWorldTag("seed");
	
	block.auto_gen_terrain_block = true;

	local block_generator;
	if(world_generator and world_generator~="") then
		if(world_generator == "flat") then
			-- only used in haqi, Not in paracraft
			block.auto_gen_terrain_block = true;
			block_generator = self:GetChunkProvider():CreateGenerator("flat");
			block_generator:SetFlatLayers({
				{y = 126, block_id = block_types.names.underground_shell},
			});
		else
			-- generators in paracraft
			block.auto_gen_terrain_block = false;
			if(world_generator == "superflat") then
				block_generator = self:GetChunkProvider():CreateGenerator("flat");
			elseif(world_generator:match("^flat%d*")) then
				local land_y = world_generator:match("^flat(%d*)");
				land_y = tonumber(land_y) or 4;
				block_generator = self:GetChunkProvider():CreateGenerator("flat");
				local layers = {};
				layers[1] = {y = 0, block_id = block_types.names.Bedrock}
				for i = 1, land_y do
					layers[i+1] = {y = i, block_id = block_types.names.underground_shell}
				end
				block_generator:SetFlatLayers(layers);

			elseif(world_generator == "empty") then
				block_generator = self:GetChunkProvider():CreateGenerator("empty");
			else
				-- any custom generator by name. 
				block_generator = self:GetChunkProvider():CreateGenerator(world_generator);
			end
		end
		-- disable real world terrain 
		ParaTerrain.GetAttributeObject():SetField("RenderTerrain",false);
	else
		block_generator = self:GetChunkProvider():CreateGenerator("empty");
		-- enable real world terrain 
		ParaTerrain.GetAttributeObject():SetField("RenderTerrain",true);
	end
	self:GetChunkProvider():SetGenerator(block_generator);
	GameLogic.options.has_real_terrain = ParaTerrain.GetAttributeObject():GetField("RenderTerrain",true);
end

function World:ReplaceWorld(oldWorld)
	if(oldWorld) then
		oldWorld:OnWeaklyDestroyWorld();
	end
end

-- this function is called when the world is possibly replaced by another world object
-- thus as toggling from client world to server world, without leaving the world.
function World:OnWeaklyDestroyWorld()
	self:GetChunkProvider():OnExit();
end

function World:OnExit()
	self:OnWeaklyDestroyWorld();
end

-- world trackers may be temporily disabled and then enabled again, for example when client receives
-- block change packet and updates the local world. The updated blocks should not be tracked. 
function World:EnableWorldTracker(bEnabled)
	for i=1, #(self.worldTrackers) do
		self.worldTrackers[i]:EnableTracker(bEnabled);
	end
end


function World:IsClient()
	return false;
end


function World:AddWorldTracker(worldTracker)
	if(not self.worldTrackers:contains(worldTracker)) then
		self.worldTrackers:add(worldTracker);
	end
end

function World:RemoveWorldTracker(worldTracker)
	self.worldTrackers:removeByValue(worldTracker);
end

function World:ClearWorldTrackers()
	self.worldTrackers:clear();
end

function World:FrameMove(deltaTime)
end

-- set world size by center and extend. 
-- mostly used on 32/64bits server to prevent running out of memory. 
function World:SetWorldSize(x, y, z, dx, dy, dz)
	if(not x) then
		x, y, z = self:GetSpawnPoint();
		x, y, z = BlockEngine:block(x, y, z);
	end
	dx = dx or 256;
	dy = dy or 128;
	dz = dz or 256;
	-- set attribute to low level block engine. 
	local attr = ParaTerrain.GetBlockAttributeObject();
	attr:SetField("MinWorldPos", {x-dx, y-dy, z-dz});
	attr:SetField("MaxWorldPos", {x+dx, y+dy, z+dz});
end

-- get player home spawn position. 
function World:GetSpawnPoint()
	local x, y, z;
	local entity = EntityManager.GetEntity("player_spawn_point") or EntityManager.GetEntity("player_spawn");
	if(entity) then
		x, y, z = entity:GetPosition()
	end
	if(not x) then
		x, y, z = unpack(self.options.login_pos); 
	end
	return x, y, z;
end

-- set player home position. 
-- @param x, y, z: if nil, the current player position is used. 
function World:SetSpawnPoint(x,y,z)
	local pos = GameLogic.GetFilters():apply_filters("BeforeSetSpawnPoint", {x,y,z});
	if(pos) then
		x,y,z = unpack(pos);
		local entity = EntityManager.GetEntity("player_spawn_point")
		if(not entity) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateBlockTask.lua");
			local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({block_id = block_types.names.player_spawn_point, blockX=x, blockY=y, blockZ=z})
			task:Run();
			entity = EntityManager.GetEntity("player_spawn_point")
		end
		if(entity) then
			if(not x) then
				x,y,z = ParaScene.GetPlayer():GetPosition();
			end
			entity:SetPosition(x,y,z);
		end
	end
	GameLogic.GetFilters():apply_filters("SetSpawnPoint", nil, x,y,z);
	return x,y,z;
end

function World:GetWorldInfo()
	return WorldCommon:GetWorldInfo();
end

-- Called to place all entities as part of a world
function World:SpawnEntityInWorld(entity)
	entity:Attach();
end

function World:GetTotalWorldTime()
	return 10;
end

function World:GetWorldTime()
	return 10;
end

function World:GetGameRules()
	return GameRules;
end

-- Returns this world's current save handler
function World:GetSaveHandler()
	return self.saveHandler;
end

-- get player
-- @param name: if nil or "player", the current player is returned. 
function World:GetPlayer(name)
	return EntityManager.GetPlayer(name);
end

function World:GetEntityByID(id)
	return EntityManager.GetEntityById(id);
end

-- On the client, re-renders the block. On the server, sends the block to the client (which will re-render it),
-- including the tile entity description packet if applicable. 
function World:MarkBlockForUpdate(x, y, z)
	for i=1, #(self.worldTrackers) do
		self.worldTrackers[i]:MarkBlockForUpdate(x,y,z);
	end
end

-- on client does nothing, on server broadcase to observing client
function World:OnChunkGenerated(chunkX, chunkZ)
	for i=1, #(self.worldTrackers) do
		self.worldTrackers[i]:OnChunkGenerated(chunkX, chunkZ);
	end
end

-- On the client, re-renders this block. On the server, does nothing. 
function World:MarkBlockForRenderUpdate(x,y,z)
	for i=1, #(self.worldTrackers) do
		self.worldTrackers[i]:MarkBlockForRenderUpdate(x,y,z);
	end
end

-- On the client, re-renders all blocks in this range, inclusive. On the server, does nothing.
function World:MarkBlockRangeForRenderUpdate(min_x, min_y, min_z, max_x, max_y, max_z)
	for i=1, #(self.worldTrackers) do
		self.worldTrackers[i]:MarkBlockRangeForRenderUpdate(min_x, min_y, min_z, max_x, max_y, max_z);
	end
end

function World:OnEntityAdded(entity)
	for i=1, #(self.worldTrackers) do
		self.worldTrackers[i]:OnEntityCreate(entity);
	end
end

function World:OnEntityRemoved(entity)
	for i=1, #(self.worldTrackers) do
		self.worldTrackers[i]:OnEntityDestroy(entity);
	end
end

-- Called when an entity becomes a server entity or vice versa
function World:OnSetServerEntity(entity)
	for i=1, #(self.worldTrackers) do
		self.worldTrackers[i]:OnSetServerEntity(entity);
	end
end


function World:OnPlaySound(soundName, x, y, z, volume, pitch)
	for i=1, #(self.worldTrackers) do
		self.worldTrackers[i]:PlaySound(soundName, x, y, z, volume, pitch);
	end
end

-- virtual: set new damage to a given block
-- @param damage: [1-10), other values will remove it. 
function World:DestroyBlockPartially(entityId, x,y,z, damage)
	for i=1, #(self.worldTrackers) do
		self.worldTrackers[i]:DestroyBlockPartially(entityId, x,y,z, damage);
	end
end

function World:GetChunkFromChunkCoords(chunkX, chunkZ)
	return self.chunkProvider:ProvideChunk(chunkX, chunkZ);
end

-- total number of world ticks since the world is created. 
function World:GetTotalWorldTime()
    return self:GetWorldInfo():GetWorldTotalTime();
end

-- current world time in day-light cycle (repeat in a day).
function World:GetWorldTime()
    return self:GetWorldInfo():GetWorldTime();
end

function World:Tick()
	self:GetWorldInfo():SetTotalWorldTime(self:GetWorldInfo():GetWorldTotalTime() + 1);
end

-- update the entity in the world
-- @param bForceUpdate: default to true. if true, the entity's framemove function will be called.
function World:UpdateEntity(entity, bForceUpdate)
	if(not bForceUpdate) then
		bForceUpdate = true;
	end
    
    entity.lastTickPosX = entity.x;
    entity.lastTickPosY = entity.y;
    entity.lastTickPosZ = entity.z;
    entity.prevRotationYaw = entity.facing;
    entity.prevRotationPitch = entity.rotationPitch;

    if (bForceUpdate) then
        entity.ticksExisted = (entity.ticksExisted or 0) + 1;

        if (entity.ridingEntity) then
            entity:FrameMoveRidding(0);
        else
            entity:FrameMove(0);
        end
    end
    
    if (bForceUpdate and entity.riddenByEntity) then
        if (not entity.riddenByEntity:IsDead() and entity.riddenByEntity.ridingEntity == entity) then
            self:UpdateEntity(entity.riddenByEntity);
        else
            entity.riddenByEntity.ridingEntity = nil;
            entity.riddenByEntity = nil;
        end
    end
end


-- Returns a list of bounding boxes that collide with aabb including the passed in entity's collision. 
-- @param aabb: 
-- return array list of bounding box (all bounding box is read-only), modifications will lead to unexpected result. 
function World:GetCollidingBoundingBoxes(aabb, entity)
	return PhysicsWorld:GetCollidingBoundingBoxes(aabb, entity);
end

function World:RemoveEntity(entity)
	entity:Destroy();
end

-- Do NOT use this method to remove normal entities- use normal RemoveEntity
function World:RemovePlayerEntityDangerously(entity)
	entity:Destroy();
end

function World:GetBlockEntityList(from_x,from_y,from_z, to_x, to_y, to_z)
	return BlockEngine:GetBlockEntityList(from_x,from_y,from_z, to_x, to_y, to_z);
end

-- this is a faster way to interate all entities in the chunk. please note that it may contain non-block entities. 
function World:GetEntityListInChunk(chunkX, chunkZ)
	return EntityManager.GetEntitiesInChunkColumn(chunkX, chunkZ);
end


-- @param granularity: (0-1), 1 will generate 27 pieces, 0 will generate 0 pieces, default to 1. 
-- @param cx, cy, cz: center of break point. 
function World:CreateBlockPieces(block_template, blockX, blockY, blockZ, granularity, texture_filename, cx, cy, cz, color)
	if(block_template) then
		block_template:CreateBlockPieces(blockX, blockY, blockZ, granularity, texture_filename, cx, cy, cz, color);
	end
end

-- this function is called when chunk is loaded or unloaded for the first time. 
-- @param bLoad: true to create, false to unload
function World:DoPreChunk(chunkX, chunkZ, bLoad)
	-- TODO:
	if(bLoad) then
        self:GetChunkProvider():LoadChunk(chunkX, chunkZ);
    else
        self:GetChunkProvider():UnloadChunk(chunkX, chunkZ);
    end
end

-- this function is called before we apply new chunk data over existing chunks
function World:InvalidateBlockReceiveRegion(from_x,from_y,from_z, to_x, to_y, to_z)
	-- TODO: we need to call OnBlockRemoved for all blocks with entities, such as BlockSign, etc. 
	-- see also Chunk:FillChunk()
end