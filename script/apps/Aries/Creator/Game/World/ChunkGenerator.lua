--[[
Title: Base class for generating Chunks
Author(s): LiXizhi
Date: 2013/8/27, refactored 2015.11.17
Desc: 
There can be many custom chunk providers deriving from this base class. 

```
Virtual functions:
	Init(world, seed)
	GenerateChunkImp(chunk, x, z, external)
	PostGenerateChunkImp(chunk, x, z)
	OnExit()

	IsSupportAsyncMode
	GetClassAddress
	GenerateChunkAsyncImp
```

## Synchronous generator
By default generator runs in the main thread, so that your generator can safely use all API. 
Simply derive from `ChunkGenerator` and overwrite `GenerateChunkImp`, and register the provider by name. 

see `FlatChunkGenerator.lua` for example. 

## Asynchronous generator
Some generators may take a long time to compute and generate large number of blocks. 
It becomes impossible to run it in the main thread without dropping render frame rates. 
In such occasions, one needs to use asynchronous generator, which runs in one or more worker threads. 
Actually, you can turn your synchronous generator into asynchronous ones by simply 
overwriting `IsSupportAsyncMode` and `GetClassAddress` method. 

If `IsSupportAsyncMode` returns true, the chunk provider will send each chunk request 
to one of the worker threads for processing (see `SetWorkerThreadCount` function). 
The worker thread picks up the request and recreate the chunk provider instance 
based on `GetClassAddress` in that thread and pass a fake in-memory `Chunk` object (see also Chunk.lua)
to its `GenerateChunkImp` function. Finally it sends back the data in `Chunk` object in compressed
binary format to the main thread, which will apply the chunk data to the real `ChunkCpp` object (see also ChunkCpp.lua) in the main thread. 
BTW, applying all chunk data to chunk column in one API may be one-hundred times faster than setting individual blocks in the chunk. 

However, there is limitations of asynchronous generator. The `GenerateChunkImp` should only 
set or get chunk data based on the requested chunk only. It can not query or set entities or advanced information 
that is only available in the main thread. However, one can overwrite `PostGenerateChunkImp` to generate 
some add-on blocks/entities in the main thread, because `PostGenerateChunkImp` is always called for both async and sync mode in the main thread.

See `NatureV1ChunkGenerator` generator for example. 

-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkGenerator.lua");
local ChunkGenerator = commonlib.gettable("MyCompany.Aries.Game.World.ChunkGenerator");
-----------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkGenerators.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/UniversalCoords.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/Chunk.lua");
local Chunk = commonlib.gettable("MyCompany.Aries.Game.World.Chunk");
local ChunkGenerators = commonlib.gettable("MyCompany.Aries.Game.World.ChunkGenerators");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local UniversalCoords = commonlib.gettable("MyCompany.Aries.Game.Common.UniversalCoords");

local ChunkGenerator = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.World.ChunkGenerator"))

-- generate nothing
ChunkGenerator.is_empty_generator = false;
-- must wait before chunks within this radius is finished. 
ChunkGenerator.must_gen_dist = 3;
-- generate one when camera is not moving. 6*16 = 96 meters 
ChunkGenerator.max_gen_radius = math.max(ChunkGenerator.must_gen_dist, 6);
-- max number of generator worker threads in async mode. See IsSupportAsyncMode().
ChunkGenerator.worker_count = 2;

local function GetChunkIndex(cx,cz)
	return cx*4096+cz;
end

local function UnpackChunkIndex(index)
	local cz = index % 4096;
	local cx = (index - cz)/4096;
	return cx, cz;
end


-- there can be only one generator at a time
local cur_generator = nil;

function ChunkGenerator:ctor()
	cur_generator = nil;
	self.pending_chunks = {}
	self.forced_chunks = {};
	self.last_pos = UniversalCoords:new();
	self.cur_pos = UniversalCoords:new();
end

-- @param world: WorldManager, if nil, it means a local generator. 
-- @param seed: a number
function ChunkGenerator:Init(world, seed)
	self._Seed = seed;
	self._World = world;
	self.cpp_chunk = world.cpp_chunk;
	return self;
end

function ChunkGenerator:GetSeed()
	return self._Seed;
end

function ChunkGenerator:OnExit()
	if(self.timer) then
		self.timer:Change();
	end
end

-- virtual function:
function ChunkGenerator:OnSaveWorld()
end

function ChunkGenerator:OnLoadWorld()
end

function ChunkGenerator:GetWorld()
	return self._World;
end

function ChunkGenerator:AddPendingChunksFrom(chunkGenerator)
	if(not chunkGenerator) then
		return
	end
	self.pending_chunks = chunkGenerator.pending_chunks;
	chunkGenerator.pending_chunks = {};
	self.last_pos:Clone(chunkGenerator.last_pos);
	self.cur_pos:Clone(chunkGenerator.cur_pos);

	if(next(self.pending_chunks)) then
		self:StartTimer(300, 100);
	end
end

-- @return y : height of the grass block
function ChunkGenerator:FindFirstBlock(x, y, z, side, dist, chunk)
	if(self.cpp_chunk) then
		local dist = ParaTerrain.FindFirstBlock(x,y,z,5, dist);
		if(dist>0) then
			y = y - dist;
			return y;
		end
	elseif(chunk) then
		local dist = chunk:FindFirstBlock(x, y, z, side, dist);
		if(dist>0) then
			y = y - dist;
			return y;
		end
	end
end

function ChunkGenerator:CanSeeTheSky(x, y, z, chunk)
	if(self.cpp_chunk) then
		if(y < 128) then
			return (ParaTerrain.FindFirstBlock(x,y,z,4, 128-y ) < 0);
		end
	elseif(chunk) then
		if(y < 128) then
			return (chunk:FindFirstBlock(x,y,z,4, 128-y ) < 0);
		end
	end
end

-- public function:
function ChunkGenerator:AddPendingRegion(region_x, region_y)
	-- LOG.std(nil, "debug", "ChunkGenerator", "generate region %d %d", region_x, region_y)

	-- when terrain region is first loaded, all must_gen_dist chunks must be loaded. 
	local old_must_gen_dist = self.must_gen_dist;
	self.must_gen_dist = self.max_gen_radius;

	local cx, cz;
	for cx = 0, 31 do
		for cz = 0, 31 do
			self:AddPendingChunk(region_x, region_y, cx, cz);
		end
	end

	if(self.timer) then
		self:OnTimer(self.timer);
	end

	self.must_gen_dist = old_must_gen_dist;
end

-- @param radius: in chunk unit. default to 6. which is 6*16=96 blocks. 
function ChunkGenerator:SetMaxGenRadius(radius)
	self.max_gen_radius = radius or self.max_gen_radius;
end

function ChunkGenerator:AddForcedChunk(cx,cz)
	local index = GetChunkIndex(cx, cz);
	self.forced_chunks[index] = true;
	if(not self.HasPendingChunk) then
		self.HasPendingChunk = true;
		self:StartTimer(100, 100);
	end
end

-- @param dist_from_player: if nil, it will always be in range
-- return true, if there is still pending chunks
function ChunkGenerator:TryProcessChunk(cx,cz, dist_from_player)
	local c = self.pending_chunks[GetChunkIndex(cx, cz)];
	if(c) then
		if((dist_from_player or 0)<= self.must_gen_dist or self.ProcessedCount < 1) then
			self.ProcessedCount = self.ProcessedCount + 1;
			if(self._World) then
				local chunk = self._World:GetChunk(cx, cz, true);
				if(chunk) then
					self._World:GetChunkProvider():AutoGenerateChunk(chunk);
				end
			end
		else
			self.HasPendingChunk = true;
			if(self.timer) then
				-- self.timer:Change(dist_from_player*dist_from_player*30, 50);
				self.timer:Change(10,10);
			end
			return true;
		end
	end
end

-- called every frame move to check for ungenerated terrain. 
function ChunkGenerator:OnTimer(timer)
	local x, y, z = ParaScene.GetPlayer():GetPosition();

	-- local bCameraMoved = ParaCamera.GetAttributeObject():GetField("IsCameraMoved", false);
	if( not self.last_x or (self.HasPendingChunk) or 
		math.abs(self.last_x-x)>16 or math.abs(self.last_z-z)>16) then
		
		self.last_x = x;
		self.last_z = z;

		local bx,by,bz = BlockEngine:block(x, y-0.1, z);
		self.cur_pos:FromWorld(bx,by,bz);

		local cx, cz = self.cur_pos:GetChunkX(), self.cur_pos:GetChunkZ();

		local x,y,z,zi = 0,0,0,0;

		self.ProcessedCount = 0;
		self.HasPendingChunk = false;
		-- from inner ring to outer ring
		for radius = 1, self.max_gen_radius do
			local radius_sq = radius*radius;
			local inner_radius = radius-1;
			local radius_inner_sq = inner_radius*inner_radius;

			local last_z = radius;
			for x=0, radius do
				z = math.floor(math.sqrt(radius_sq - x*x)+0.5);
				if(x<inner_radius) then
					zi = math.floor(math.sqrt(radius_inner_sq - x*x)+0.5);
				else
					zi = 0;
				end

				local z_;
				local z_to = math.max(last_z -1, z);
				for z_ = zi, z_to do
					if(self:TryProcessChunk(x+cx,z_+cz, radius)) then
						return;
					end
					if(z_ ~=0) then
						if(self:TryProcessChunk(x+cx,-z_+cz, radius)) then
							return;
						end
					end
					if(x ~= 0) then
						if(self:TryProcessChunk(-x+cx,z_+cz, radius)) then
							return;
						end
						if(z_ ~=0) then
							if(self:TryProcessChunk(-x+cx,-z_+cz, radius)) then
								return;
							end
						end
					end
				end
				last_z = z;
			end
		end

		-- process forced chunks
		local index = next(self.forced_chunks);
		while(index) do
			local cx,cz = UnpackChunkIndex(index);
			index = next(self.forced_chunks, index);
			if(self:TryProcessChunk(cx,cz)) then
				return;
			end
		end

		if(not self.HasPendingChunk and timer) then
			timer:Change(300,300);
		end
	end
end

function ChunkGenerator:StartTimer(nextTime, duration)
	if(not self.timer) then
		self.timer = commonlib.Timer:new({callbackFunc = function(timer)
			self:OnTimer(timer);
		end})
	end
	self.timer:Change(nextTime, duration);
end

function ChunkGenerator:AddPendingChunk(region_x, region_y, cx, cz)
	local from_x = region_x*32;
	local from_z = region_y*32;

	local nIndex = GetChunkIndex(from_x+cx, from_z+cz)
	if(not self.pending_chunks[nIndex]) then
		
		self.pending_chunks[nIndex] = true;
		self.HasPendingChunk = true;
		self:StartTimer(10, 10);
	end
end


-- simple function for testing: generate flat plane at given height
function ChunkGenerator:GeneratePlane(c, x, z, height, block_id)
	local by = height or 4;
	block_id = block_id or 62; -- default to grass
	for bx = 0, 15 do
		for bz = 0, 15 do
			c:SetType(bx, by, bz, block_id, false);
		end
	end
end

local workers = {};
local worker_index = 0;
-- return the activation file name
function ChunkGenerator:GetFreeWorkerName()
	worker_index = (worker_index+1) % (self.worker_count);
	local worker_name = workers[worker_index];
	if(not worker_name) then
		local name = "gen"..worker_index;
		worker_name = format("(%s)%s", name, "script/apps/Aries/Creator/Game/World/ChunkGenerator.lua");
		workers[worker_index] = worker_name;
		NPL.CreateRuntimeState(name, 0):Start();
		local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names");
		NPL.activate(worker_name, {cmd="InitBlockTypes", names = names});
		LOG.std(nil, "info", "chunk generator", "generator worker thread `%s` created", name);
	end
	return worker_name;
end

local next_gen_id = 1;
function ChunkGenerator:GetId()
	if(not self.id) then
		self.id = next_gen_id;
		next_gen_id = next_gen_id + 1;
	end
	return self.id;
end

-- protected function:
-- @param chunk: 
function ChunkGenerator:GenerateChunkAsync(chunk, x, z)
	local index = GetChunkIndex(x, z);
	if(self.pending_chunks[index] ~= true) then
		return;
	end
	self.pending_chunks[index] = chunk;
	local worker_name = self:GetFreeWorkerName();
	cur_generator = self;
	NPL.activate(worker_name, {x=x, z=z, gen_id=self:GetId(), cmd="GenerateChunk", seed = self:GetSeed(), address = self:GetClassAddress()});
end

-- apply chunk data in main thread
function ChunkGenerator:ApplyChunkData(x,z, chunkData)
	local index = GetChunkIndex(x, z);
	local chunk = self.pending_chunks[index];
	if(type(chunk) == "table") then
		self.pending_chunks[index] = nil;
		self.forced_chunks[index] = nil;
		-- data is available now. 
		local is_suspended_before = ParaTerrain.GetBlockAttributeObject():GetField("IsLightUpdateSuspended", false);
		if(not is_suspended_before) then
			ParaTerrain.GetBlockAttributeObject():CallField("SuspendLightUpdate");
		end

		-- LOG.std(nil, "debug", "ApplyChunkData", "chunk %d %d", x, z);

		if(GameLogic.GetFilters():apply_filters("before_generate_chunk", x, z)) then
			chunk:ApplyMapChunkData(chunkData, 0xffff);
			self:PostGenerateChunk(chunk, x, z);

			GameLogic.GetFilters():apply_filters("after_generate_chunk", x, z)
		end

		if(not is_suspended_before) then
			ParaTerrain.GetBlockAttributeObject():CallField("ResumeLightUpdate");
		end

		if(self._World) then
			chunk:MarkToSave();
			chunk:SetTimeStamp(1);
			chunk:Clear();
		end
		return chunk;
	end
end

-- public function:
-- @param chunk: if nil, a new chunk will be created. 
-- @param x, z: chunk pos
-- @param bForceSyncMode: this is usually nil. only true when in server mode.
-- @return chunk if chunk is generated. or nil if it is async generated. 
function ChunkGenerator:GenerateChunk(chunk, x, z, bForceSyncMode)
	if(self:IsSupportAsyncMode() and not bForceSyncMode) then
		return self:GenerateChunkAsync(chunk, x, z);
	end

	local index = GetChunkIndex(x, z);
	self.pending_chunks[index] = nil;
	self.forced_chunks[index] = nil;
	
	if(not self.is_empty_generator) then
		local is_suspended_before = ParaTerrain.GetBlockAttributeObject():GetField("IsLightUpdateSuspended", false);
		if(not is_suspended_before) then
			ParaTerrain.GetBlockAttributeObject():CallField("SuspendLightUpdate");
		end

		LOG.std(nil, "debug", "GenerateChunk", "chunk %d %d", x, z);

		if(GameLogic.GetFilters():apply_filters("before_generate_chunk", x, z)) then
			self:GenerateChunkImp(chunk, x, z, external);
			self:PostGenerateChunk(chunk, x, z);
			GameLogic.GetFilters():apply_filters("after_generate_chunk", x, z)
		end

		if(not is_suspended_before) then
			ParaTerrain.GetBlockAttributeObject():CallField("ResumeLightUpdate");
		end
	end

	if(self._World) then
		chunk:MarkToSave();
		chunk:SetTimeStamp(1);
		chunk:Clear();
	end
	return chunk;
end

-- max number of generator worker threads in async mode. See IsSupportAsyncMode().
function ChunkGenerator:SetWorkerThreadCount(worker_count)
	self.worker_count = worker_count;
end

-- virtual function: 
-- whether this chunk generator can run in any thread, if so, we may run it in several threads. 
-- if this one returns true, one must also provide GetClassAddress() function
function ChunkGenerator:IsSupportAsyncMode()
	return false;
end

-- virtual function: get the class address for sending to worker thread. 
function ChunkGenerator:GetClassAddress()
	LOG.std(nil, "warn", "ChunkGenerator", "GetClassAddress must be implemented if IsSupportAsyncMode() returns true");
	return {filename="script/apps/Aries/Creator/Game/World/ChunkGenerator.lua", classpath="MyCompany.Aries.Game.World.ChunkGenerator"}
end

-- protected virtual funtion: overwrite this function to provide your own chunk generator
-- generate chunk for the entire chunk column at x, z
-- @param chunk: chunk object
-- @param x, z: chunk pos
function ChunkGenerator:GenerateChunkImp(chunk, x, z, external)
	LOG.std(nil, "warn", "ChunkGenerator", "GenerateChunkImp not implemented");
	-- TODO: call lots of set blocks here in your custom chunk provider. for example:
	--local block_id, block_data = 62, 0;
	--for by = 0, 1 do
		--for bx = 0, 15 do
			-- local worldX = bx + (x * 16);
			--for bz = 0, 15 do
				-- local worldZ = bz + (z * 16);
				--chunk:SetType(bx, by, bz, block_id, false);
				--chunk:SetData(bx, by, bz, block_data, false);
			--end
		--end
	--end
end

-- virtual function:
-- This is always called for both async and sync mode in the main thread.
function ChunkGenerator:PostGenerateChunkImp(chunk, x, z)
end

-- virtual function: this is run in worker thread. It should only use data in the provided chunk.
-- if this function returns false, we will use GenerateChunkImp() instead. 
function ChunkGenerator:GenerateChunkAsyncImp(chunk, x, z)
	return false
end

-- This is always called for both async and sync mode in the main thread.
function ChunkGenerator:PostGenerateChunk(chunk, x, z)
	self:PostGenerateChunkImp(chunk, x, z);
	if(self._World) then
		self._World:OnChunkGenerated(x, z)
	end
end


-- return gen_id of the most recent request
local function VerifyOutOfWorldRequest()
	local thread = __rts__;
	local nSize = thread:GetCurrentQueueSize();
	local processed;
	local gen_id;
	for i=nSize-1, 0, -1 do
		local msg = thread:PeekMessage(i, {filename=true, msg=true});
		if( msg and msg.filename == "script/apps/Aries/Creator/Game/World/ChunkGenerator.lua" and type(msg.msg)=="table" and msg.msg.cmd == "GenerateChunk") then
			if(not gen_id) then
				gen_id = msg.msg.gen_id;
			else
				if(msg.msg.gen_id ~= gen_id) then
					LOG.std(nil, "debug", "GenerateChunkAsync", "skipping out of world chunk %d %d", msg.msg.x, msg.msg.z);
					-- pop message without processing it
					thread:PopMessageAt(i, {});
					i = i + 1;
				end
			end
		end
	end
	return gen_id;
end

NPL.this(function()
	local msg = msg;
	if( msg.cmd == "GenerateChunk") then
		-- peek message queue and remove chunks whose gen_id is different from the top. 
		if((VerifyOutOfWorldRequest() or msg.gen_id) ~= msg.gen_id) then
			LOG.std(nil, "debug", "GenerateChunkAsync", "skipping out of world chunk %d %d", msg.x, msg.z);
			return;
		end
		
		if(not cur_generator or cur_generator.id ~= msg.gen_id or cur_generator:GetSeed() ~= msg.seed) then
			local world = {};
			local generator = ChunkGenerators:GetClassByAddress(msg.address);
			cur_generator = generator:new():Init(world, msg.seed);
			cur_generator.id = msg.gen_id;
		end

		local gen = cur_generator;
		
		if(gen) then
			local chunk = Chunk:new():Init(world, msg.x, msg.z);
			LOG.std(nil, "debug", "GenerateChunkAsync", "chunk %d %d", msg.x, msg.z);
			-- create chunk and world.
			if(not gen:GenerateChunkAsyncImp(chunk, msg.x, msg.z)) then
				gen:GenerateChunkImp(chunk, msg.x, msg.z)
			end
			NPL.activate("(main)script/apps/Aries/Creator/Game/World/ChunkGenerator.lua", {
				cmd="ApplyChunkData", data = chunk:GetMapChunkData(), x = msg.x, z = msg.z, gen_id = msg.gen_id
			});
		end
	elseif( msg.cmd == "ApplyChunkData") then
		if(cur_generator and cur_generator:GetId() == msg.gen_id) then
			cur_generator:ApplyChunkData(msg.x, msg.z, msg.data);
		else
			LOG.std(nil, "debug", "GenerateChunkAsync", "discard out of world chunk %d %d", msg.x, msg.z);
		end
	elseif( msg.cmd == "InitBlockTypes") then
		local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names");
		commonlib.partialcopy(names, msg.names);
	elseif( msg.cmd == "ReleaseGenerator") then
		cur_generator = nil;
		collectgarbage("collect");
	end
end);