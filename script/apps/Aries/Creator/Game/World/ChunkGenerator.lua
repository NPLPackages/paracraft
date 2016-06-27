--[[
Title: Base class for generating Chunks
Author(s): LiXizhi
Date: 2013/8/27, refactored 2015.11.17
Desc: There can be many custom chunk providers deriving from this class. 
Virtual functions:
	Init(world, seed)
	GenerateChunkImp(chunk, x, z, external)
	OnExit()

Simply overwrite GenerateChunkImp and register the provider by name. 
see FlatChunkGenerator.lua for example. 

-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkGenerator.lua");
local ChunkGenerator = commonlib.gettable("MyCompany.Aries.Game.World.ChunkGenerator");
-----------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local UniversalCoords = commonlib.gettable("MyCompany.Aries.Game.Common.UniversalCoords");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")

local ChunkGenerator = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.World.ChunkGenerator"))

-- generate nothing
ChunkGenerator.is_empty_generator = false;
-- must wait before chunks within this radius is finished. 
ChunkGenerator.must_gen_dist = 3;
-- generate one when camera is not moving. 6*16 = 96 meters 
ChunkGenerator.max_gen_radius = math.max(ChunkGenerator.must_gen_dist, 6);

local function GetChunkIndex(cx,cz)
	return cx*4096+cz;
end

local function UnpackChunkIndex(index)
	local cz = index % 4096;
	local cx = (index - cz)/4096;
	return cx, cz;
end

function ChunkGenerator:ctor()
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

function ChunkGenerator:OnExit()
	if(self.timer) then
		self.timer:Change();
	end
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
function ChunkGenerator:FindFirstBlock(x, y, z, side, dist)
	if(self.cpp_chunk) then
		local dist = ParaTerrain.FindFirstBlock(x,y,z,5, dist);
		if(dist>0) then
			y = y - dist;
			return y;
		end
	end
end

function ChunkGenerator:CanSeeTheSky(x, y, z, c)
	if(self.cpp_chunk) then
		if(y < 128) then
			return (ParaTerrain.FindFirstBlock(x,y,z,4, 128-y ) < 0);
		end
	else
		local by=y;
		-- TODO: test opacity instead of Air(0)
		while(c:GetType(x, by, z) == 0 and by<128) do
			by = by + 1
		end
		return by == 128;
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
	if(self.pending_chunks[GetChunkIndex(cx, cz)]) then
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

-- public function:
-- @param chunk: if nil, a new chunk will be created. 
-- @param x, z: chunk pos
function ChunkGenerator:GenerateChunk(chunk, x, z, external)
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

-- protected virtual funtion:
-- generate chunk for the entire chunk column at x, z
-- @param chunk: chunk object
-- @param x, z: chunk pos
function ChunkGenerator:GenerateChunkImp(chunk, x, z, external)
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
