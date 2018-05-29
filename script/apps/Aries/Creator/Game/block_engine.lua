--[[
Title: A wrapper to the low level block terrain engine
Author(s): LiXizhi
Date: 2012/10/20
Desc: It contains various block generation, searching functions. And it provide simulation to ensure a closed space block world. 
Please note that the block engine it self does not keep the data for block level data. instead all static block data is loaded and saved
by the low level game engine. 

GameLogic filters:
 OnBeforeLoadBlockRegion(bContinue, x, y): false to disable loading region from file
 OnLoadBlockRegion(bContinue, x, y)
 OnUnLoadBlockRegion(bContinue, x, y)

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
BlockEngine:Connect();
BlockEngine:SetGameLogic(GameLogic);
-- your game goes inbetween connect and disconnect
BlockEngine:Disconnect();
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local npl_profiler = commonlib.gettable("commonlib.npl_profiler");
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local Materials = commonlib.gettable("MyCompany.Aries.Game.Materials");
local GameLogic;

local math_floor= math.floor;

---------------------------
-- create class
---------------------------
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

-- current eye position
BlockEngine.eye = {0,0,0};
BlockEngine.eye_block = {0,0,0};
-- simulation interval in ms
BlockEngine.sim_interval = 300;

-- block size in meters
-- width in metters
BlockEngine.region_width = 512;
BlockEngine.blocksize = BlockEngine.region_width/512;
BlockEngine.blocksize_inverse = 1/BlockEngine.blocksize;
BlockEngine.half_blocksize = BlockEngine.blocksize/2;
-- terrain region is usually 512*512 blocks
BlockEngine.region_size = 512;
-- height is usually (+128,-128)
BlockEngine.region_height = 128;
-- the block's origin in real world.
BlockEngine.offset_y = 0;
-- only used for debugggin purposes. 
BlockEngine.block_cache = {};
BlockEngine.tick_count = 0;

local block_framemove_count = 0;
-- framemove coroutine will yield if simulation step is bigger than block_sim_per_frame
local block_sim_per_frame = 100;
-- whether we will call all nearby block template's frame move function in a coroutine 
BlockEngine.is_do_per_block_framemove = false;

local blocksize = BlockEngine.blocksize;
local blocksize_inverse = BlockEngine.blocksize_inverse;
local region_size = BlockEngine.region_size;
local region_width = BlockEngine.region_width;
local region_height = BlockEngine.region_height;
local offset_y = BlockEngine.offset_y;

local custom_model_load_map = {};
local eye_pos = {};

-- set the current game logic to use. 
function BlockEngine:SetGameLogic(game_logic)
	GameLogic = game_logic;
end

-- call this function to connect the block engine with the current low level game engine's block terrain world. 
-- call this function when one enters the block based game.
function BlockEngine:Connect()
	-- clear the block cache
	self.block_cache = {};
	custom_model_load_map = {};

	local x, y, z = ParaScene.GetPlayer():GetPosition();
	ParaScene.GetPlayer():SetField("IsAlwaysAboveTerrain", false);

	local attr = ParaTerrain.GetAttributeObjectAt(x,z);
	
	if(ParaTerrain.GetBlockAttributeObject) then
		ParaTerrain.GetBlockAttributeObject():SetField("GeneratorScript", ";MyCompany.Aries.Game.BlockEngine.OnGeneratorScript();")
		ParaTerrain.GetBlockAttributeObject():SetField("OnBeforeLoadBlockRegion", ";return MyCompany.Aries.Game.BlockEngine.OnBeforeLoadBlockRegion();")
		ParaTerrain.GetBlockAttributeObject():SetField("OnSaveRegionCallbackScript", ";MyCompany.Aries.Game.BlockEngine.OnSaveBlockRegion();" )
		ParaTerrain.GetBlockAttributeObject():SetField("OnLoadBlockRegion", ";MyCompany.Aries.Game.BlockEngine.OnLoadBlockRegion();")
		ParaTerrain.GetBlockAttributeObject():SetField("OnUnLoadBlockRegion", ";MyCompany.Aries.Game.BlockEngine.OnUnLoadBlockRegion();")
	end
	

	self.region_width = attr:GetField("size", 533.3333); 
	region_width = BlockEngine.region_width;
	self.blocksize = self.region_width / self.region_size;
	blocksize = BlockEngine.blocksize;

	self.blocksize_inverse = self.region_size / self.region_width;
	blocksize_inverse = BlockEngine.blocksize_inverse;

	self.half_blocksize = blocksize / 2;


	-- default to offset 200 meters below the ground.
	--self:SetOffsetY(-200);
	self:SetOffsetY(-self.blocksize*128); -- just for debugging. 

	block_types:OnWorldLoaded();

	-- enter the block world with rendering.
    ParaTerrain.EnterBlockWorld(x,y,z);

	self:UpdateEyePosition(x, y, z);

	if(self.is_do_per_block_framemove) then
		self.framemove_co = self.framemove_co or coroutine.create(function ()
			self:FrameMove_Coroutine();
		end)
	end

	self.mytimer = self.mytimer or commonlib.Timer:new({callbackFunc = function(timer)
		self:OnFrameMove();
	end})
	self.mytimer:Change(self.sim_interval, self.sim_interval);
end

local results = {};

-- @return 0 or nil to proceed loading the region in async mode. 
-- return 1 to prevent the region from loaded
function BlockEngine.OnBeforeLoadBlockRegion()
	-- LOG.std(nil, "system", "BlockEngine", "before load block region %d %d", msg.x, msg.y);
	-- return 1 prevent the region from loaded, just in case you have your own load world logics. 
	if(GameLogic) then
		if(not GameLogic.GetFilters():apply_filters("OnBeforeLoadBlockRegion", true, msg.x, msg.y)) then
			return 1;
		end
	end
        return 0;
end

function BlockEngine.OnSaveBlockRegion()
	if(GameLogic) then
		GameLogic.GetFilters():apply_filters("OnSaveBlockRegion", true, msg.x, msg.y, msg.type);
	end
end

function BlockEngine.OnLoadBlockRegion()
	if(GameLogic) then
		if(not GameLogic.GetFilters():apply_filters("OnLoadBlockRegion", true, msg.x, msg.y)) then
			return;
		end
	end
	if(BlockEngine:IsRemote()) then
		return;
	end
	LOG.std(nil, "system", "BlockEngine", "loading block region %d %d", msg.x, msg.y);
	local region_id = msg.x*100000+msg.y;
	if(custom_model_load_map[region_id]) then
		return;
	end
	custom_model_load_map[region_id] = true;
	
	local startChunkX, startChunkY, startChunkZ = msg.x*32, 0, msg.y*32;
	local endChunkX, endChunkY, endChunkZ = startChunkX+32-1, 15, startChunkZ+32-1;

	ParaTerrain.GetBlocksInRegion(startChunkX, startChunkY, startChunkZ, endChunkX, endChunkY, endChunkZ, block.attributes.onload, results);
	
	if(results.count and results.count>0) then
		local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
		local region = EntityManager.GetRegionContainer(msg.x*512, msg.y*512);
		LOG.std(nil, "system", "BlockEngine", "calling onload for %d blocks in region %d %d", results.count, msg.x, msg.y);

		local results_x, results_y, results_z, results_tempId, results_data = results.x, results.y, results.z, results.tempId, results.data;
		for i = 1, results.count do
			local x,y,z,block_id, block_data = results_x[i], results_y[i], results_z[i], results_tempId[i], results_data[i];
			if(x and block_id) then
				local block_template = block_types.get(block_id);
				-- exclude cubeModel
				if(block_template) then
					block_template:OnBlockLoaded(x,y,z, block_data);
				end
			end
		end
	end
end

function BlockEngine.OnUnLoadBlockRegion()
	if(GameLogic) then
		if(not GameLogic.GetFilters():apply_filters("OnUnLoadBlockRegion", true, msg.x, msg.y)) then
			return;
		end
	end
	if(not BlockEngine:IsRemote()) then
		LOG.std(nil, "system", "BlockEngine", "unloading block region %d %d", msg.x, msg.y);
	end
end

function BlockEngine.OnGeneratorScript()
	if(GameLogic and not GameLogic.isRemote) then
		local block_generator = GameLogic.GetBlockGenerator();
		if(block_generator) then
			local region_x, region_y = msg.region_x, msg.region_y;
			if(not msg.chunk_x or msg.chunk_x<0) then
				block_generator:AddPendingRegion(region_x, region_y);
			else
				block_generator:AddPendingChunk(region_x, region_y, msg.chunk_x, msg.chunk_z);
			end
		end
	end
end

-- disconnect the block engine, so that no computation occurs afterwards. 
-- call this function when one exit the block based game
function BlockEngine:Disconnect()
	if(self.mytimer) then
		self.mytimer:Change();
	end
	-- call this to prevent block simultion.
	ParaTerrain.LeaveBlockWorld();
end

function BlockEngine:SetOffsetY(y)
	self.offset_y = y;
	self.max_y = y + self.blocksize*BlockEngine.region_height;
	self.min_y = y - self.blocksize*BlockEngine.region_height;
	offset_y = self.offset_y;
	ParaTerrain.SetBlockWorldYOffset(offset_y);
end

-- used to cache some game data per block
-- @return -1 means nil, 0 means empty, 1 means opaque block, 2 means deco, etc. 
function BlockEngine:GetBlockTypeInCache(x, y, z)
	local block = self:GetBlockInCache(x, y, z)
	if(block) then
		return block.type or 0;
	else
		return -1;
	end
end

-- used to cache some game data per block
-- @return -1 means nil, 0 means empty, 1 means opaque block, 2 means deco, etc. 
function BlockEngine:GetBlockTypeInCacheIdx(bx, by, bz)
	local block = self:GetBlockInCacheIdx(bx, by, bz)
	if(block) then
		return block.type or 0;
	else
		return -1;
	end
end

-- similar to GetBlockType except that index is block coordinates is uint16
-- @param bx,by,bz: block index
function BlockEngine:SetBlockAttributeInCache(x,y,z, name, value)
	local block = self:GetBlockInCache(x, y, z, true)
	if(block) then
		block[name] = value;
	end
end


-- one can set the block attribute at the given position
-- supported attributes are like "type", "texture", ...
function BlockEngine:GetBlockAttributeInCache(x,y,z, name)
	local block = self:GetBlockInCache(x, y, z)
	if(block) then
		return block[name];
	end
end

-- create/get block at given world position. 
function BlockEngine:GetBlockInCacheIdx(bx, by, bz, bCreateIfNotExist)
	local sparse_index = by*900000000+bx*30000+bz;
	local block = self.block_cache[sparse_index];
	if(block) then
		return block;
	elseif(bCreateIfNotExist) then
		-- create a default block
		block = {};
		self.block_cache[sparse_index] = block;
		return block;
	end
end

-- create/get block at given world position. 
-- @param x, y, z: real world position.
function BlockEngine:GetBlockInCache(x,y,z, bCreateIfNotExist)
	local bX, bY, bZ = self:block(x, y, z);
	local sparse_index = self:GetSparseIndex(bX, bY, bZ);
	local block = self.block_cache[sparse_index];
	if(block) then
		return block;
	elseif(bCreateIfNotExist) then
		-- create a default block
		block = {};
		self.block_cache[sparse_index] = block;
		return block;
	end
end

-- whether this block is freespace. 
function BlockEngine:IsBlockFreeSpace(bx, by, bz)
	local block_id = ParaTerrain.GetBlockTemplateByIdx(bx, by, bz);
	local block = block_types.get(block_id)
	if(not block or (not block.solid and block.obstruction)) then
		return true;
	end
end

-- get the region pos that contains x, z
function BlockEngine:GetRegionPos(x,z)
	local idx_x, idx_z;
	
	idx_x = math_floor(x / region_width);
	idx_z = math_floor(z / region_width);
	
	return idx_x, idx_z;
end

-- convert from block index to real world coordinate. use floating point operations. 
-- @param note: the returned position is always the center of the block.
function BlockEngine:ConvertToRealPosition_float(x,y,z)
	local real_x, real_y, real_z;
	
	real_x = math_floor(x / region_size);
	real_z = math_floor(z / region_size);
	local x_orgin = real_x * region_size;
	local z_orgin = real_z * region_size;
	-- local index
	local bx = (x - x_orgin + 0.5) * blocksize;
	local bz = (z - z_orgin + 0.5) * blocksize;

	real_x = real_x * region_width + bx
	real_y = (y + 0.5)*blocksize + offset_y
	real_z = real_z * region_width + bz

	return real_x, real_y, real_z;
end

-- only call this function when math is in 64 bits double, otherwise use the 32bits float version above, which is compatible with C++
function BlockEngine:ConvertToRealPosition(x,y,z)
	return (x+0.5)*blocksize, (y+0.5)*blocksize+offset_y, (z+0.5)*blocksize;
end
BlockEngine.real = BlockEngine.ConvertToRealPosition;

-- this is 64bits version. convert from block index position to real world bottom center position. 
-- @param x,y,z: block index (may be floating point index). y, z can be nil. x must be number. 
function BlockEngine:real_bottom(x,y,z)
	return (x+0.5)*blocksize, (y)*blocksize+offset_y, (z+0.5)*blocksize;
end

-- top center position of given block in real coordinate
function BlockEngine:real_top(x,y,z)
	return (x+0.5)*blocksize, (y+1)*blocksize+offset_y, (z+0.5)*blocksize;
end

-- this is 64bits version. convert from block index position to real world min position. 
-- @param x,y,z: block index (may be floating point index). y, z can be nil. x must be number. 
function BlockEngine:real_min(x,y,z)
	if(y) then
		return x*blocksize, y*blocksize+offset_y, z*blocksize;
	else
		return x*blocksize;
	end
end

-- return the real y. returned value is at the bottom of the y block.
function BlockEngine:realY(y)
	return y*blocksize + offset_y;
end

-- convert real world coordinate x,y,z to block index. use floating point operations.  
function BlockEngine:ConvertToBlockIndex_float(x,y,z)
	local idx_x, idx_y, idx_z;
	
	idx_x = math_floor(x / region_width);
	idx_z = math_floor(z / region_width);
	local x_orgin = idx_x * region_width;
	local z_orgin = idx_z * region_width;
	-- local index
	local bx = math_floor((x - x_orgin)/blocksize);
	local bz = math_floor((z - z_orgin)/blocksize);

	idx_x = idx_x*region_size + bx
	idx_y = math_floor((y-offset_y)/blocksize)
	idx_z = idx_z*region_size + bz

	local sparse_index = idx_y*900000000+idx_x*30000+bz;
	return idx_x, idx_y, idx_z, sparse_index;
end

-- only call this function when math is in 64 bits double, otherwise use the 32bits float version above, which is compatible with C++
function BlockEngine:ConvertToBlockIndex(x,y,z)
	return math_floor(x*blocksize_inverse), math_floor((y-offset_y)*blocksize_inverse), math_floor(z*blocksize_inverse);
end
BlockEngine.block = BlockEngine.ConvertToBlockIndex;

-- convert to block floating point index. 
-- @param x,y,z: real world cooridnate. y z can be nil. 
-- @return block index but NOT math.floored. 
function BlockEngine:block_float(x,y,z)
	if(y) then
		return x*blocksize_inverse, (y-offset_y)*blocksize_inverse, z*blocksize_inverse;
	else
		return x*blocksize_inverse;
	end
end

-- get the block center, based on a real world position.
function BlockEngine:GetBlockCenter(x,y,z)
	return BlockEngine:real(BlockEngine:block(x,y,z));
end
BlockEngine.center = BlockEngine.GetBlockCenter;

-- get sparse index
function BlockEngine:GetSparseIndex(x, y, z)
	return y*900000000+x*30000+z;
end

-- convert from sparse index to block x,y,z
-- @return x,y,z
function BlockEngine:FromSparseIndex(index)
	local x, y, z;
	y = math.floor(index / (900000000));
	index = index - y*900000000;
	x = math.floor(index / (30000));
	z = index - x*30000;
	return x,y,z;
end


local opposite_sides = {
	[0] = 1,[1] = 0,[2] = 3,[3] = 2,[4] = 5,[5] = 4,
}

function BlockEngine:GetOppositeSide(side)
	return opposite_sides[side];
end

-- @param x, y, z: block index
-- @return: x,y,z nearby block index. 
function BlockEngine:GetBlockIndexBySide(x,y,z,side)
	if(side == 0) then
		x = x - 1;
	elseif(side == 1) then
		x = x + 1;
	elseif(side == 2) then
		z = z - 1;
	elseif(side == 3) then
		z = z + 1;
	elseif(side == 4) then
		y = y - 1;
	elseif(side == 5) then
		y = y + 1;
	end
	return x,y,z
end

-- update eye position
function BlockEngine:UpdateEyePosition(x, y, z)
	if(y < self.min_y or y > self.max_y) then
		self.is_eye_outside = true;
	else
		self.is_eye_outside = false;
	end

	self.eye_block[1], self.eye_block[2], self.eye_block[3] = self:GetBlockCenter(x,y,z);
	self.eye[1], self.eye[2], self.eye[3] = x,y,z;
end


-- increase the block_framemove_count by one and yield coroutine if block_sim_per_frame has reached. 
-- call this function when some computation has just finished. 
local function block_compute_inc()
	block_framemove_count = block_framemove_count + 1;
	if(block_framemove_count > block_sim_per_frame) then
		block_framemove_count = 1;
		coroutine.yield(true);
	end
end

-- get the next dynamic object type in the block column x,z. It will start from the high y-1 and search downward, until one is found. 
-- @param max_dist: max dist to search downward. default to y. 
-- @return block_id, block_y: nil if no dynamic type is found downward. 
function BlockEngine:GetNextDynamicTypeInColumn(x,y,z, max_dist)
	local dist = ParaTerrain.FindFirstBlock(x,y,z, 5, max_dist or y, block.attributes.framemove);
	if(dist > 0) then
		y = y-dist;
		local block_id = ParaTerrain.GetBlockTemplateByIdx(x,y,z);
		return block_id, y;
	else
		return nil;
	end
end

-- @param attr: bitwise field. default to block.attributes.onload (which is usually entity block)
-- @return block_id, block_y: nil if no dynamic type is found downward. 
function BlockEngine:GetNextBlockOfTypeInColumn(x,y,z, attr, max_dist)
	attr = attr or block.attributes.onload;
	local dist = ParaTerrain.FindFirstBlock(x,y,z, 5, max_dist or y, attr);
	if(dist > 0) then
		y = y-dist;
		local block_id = ParaTerrain.GetBlockTemplateByIdx(x,y,z);
		return block_id, y;
	else
		return nil, nil;
	end
end

-- get the y pos of the first block of nBlockID, start searching from x, y, z in the side direction
-- @param x,y,z: y default to 0
-- @param nBlockId: the block id to search for
-- @param nSide: default to 5, which is downward, 4 if upward.
-- @param max_dist: default to 255
-- @return -1 if not found
function BlockEngine:GetFirstBlock(x, y, z, nBlockId, nSide, max_dist)
	return ParaTerrain.GetFirstBlock(x, y or 0, z, nBlockId, nSide or 5, max_dist or 255);
end

-- this is a coroutine and may yield every block_sim_per_frame framemove. 
function BlockEngine:FrameMove_Coroutine()
	-- inner radius, framemove all dynamic block near the eye position. 
	while(true) do
		local tick_count = BlockEngine.tick_count +1;

		BlockEngine.tick_count = tick_count;
		LOG.std(nil, "debug", "FrameMove_Coroutine",  "tick_count %d", tick_count)

		-- block index;
		local eye_x, eye_y, eye_z = self:block(self.eye_block[1], self.eye_block[2], self.eye_block[3]);
	
		if(tick_count%19 == 1) then
			self:FrameMoveRegion(eye_x, eye_y, eye_z, 50, 41);
		elseif(tick_count%10 == 1) then
			self:FrameMoveRegion(eye_x, eye_y, eye_z, 40, 31);
		elseif(tick_count%3 == 1) then
			self:FrameMoveRegion(eye_x, eye_y, eye_z, 30, 21);
		else
			self:FrameMoveRegion(eye_x, eye_y, eye_z, 20, 0);
		end
		coroutine.yield(true);
	end
end

-- main loop of the block engine.
function BlockEngine:OnFrameMove()
	local x, y, z = ParaScene.GetPlayer():GetPosition();
	self:UpdateEyePosition(x, y, z);

	-- resume per block framemove coroutine
	if(self.is_do_per_block_framemove) then
		if(coroutine.status(self.framemove_co) == "suspended") then
			local status, result = coroutine.resume(self.framemove_co);
			if not status then
				LOG.std(nil, "error", "BlockEngine", "framemove error in coroutine");
				echo(debug.traceback(self.framemove_co));
			end
		end
	end

	-- do per nearby game entity framemove
	-- TODO:
end


-- frame move all dynamic block in given square region.
-- @param x, y, z: the block index. y can be nil.
-- @param radius:  the square region radius
-- @param radius_from: default to nil or 0. if larger than 0, we will not simulate blocks which is in radius_from square. 
-- this allow us the framemove block with different interval according to distance to eye position. 
function BlockEngine:FrameMoveRegion(x, y, z, radius, radius_from)
	y = 255;
	local framemove_col = self.FrameMoveColumn;

	if(not radius_from or radius_from == 0) then
		local bx, by, bz;
		for bx = -radius, radius do
			for bz = -radius, radius do
				framemove_col(self, x+bx, y, z+bz);
			end
		end
	elseif(radius >= radius_from) then
		local thickness = radius - radius_from;
		local bx, by, bz;
		for bx = -radius, radius do
			for bz = -radius, -radius + thickness do
				framemove_col(self, x+bx, y, z+bz);
			end
			for bz = radius-thickness, radius do
				framemove_col(self, x+bx, y, z+bz);
			end
		end
		for bz = -radius_from+1, radius_from-1 do
			for bx = -radius, -radius + thickness do
				framemove_col(self, x+bx, y, z+bz);
			end
			for bx = radius-thickness, radius do
				framemove_col(self, x+bx, y, z+bz);
			end
		end
	else
		LOG.std(nil, "error", "BlockEngine", "error framemove region");
	end
	
end

-- framemove all blocks below y, in the x, z columns from top to bottom. 
-- @param x, y, z: the block index. y can be nil.
function BlockEngine:FrameMoveColumn(x,y,z)
	local block_id;
	-- column itself count as one. 
	block_compute_inc();

	block_id, y = self:GetNextDynamicTypeInColumn(x,y,z)
	while(block_id) do
		local block_template = block_types.create_get_type(block_id);
		if(block_template) then
			block_template:updateTick(x, y, z);
		end
		block_compute_inc();

		block_id, y = self:GetNextDynamicTypeInColumn(x,y,z);
	end
end

-- same as: BlockEngine:SetBlock(x,y,z,0, nil, flag)
function BlockEngine:SetBlockToAir(x,y,z, flag)
	BlockEngine:SetBlock(x,y,z,0,0, flag);
end

function BlockEngine:MarkBlockForUpdate(x, y, z)
	if(GameLogic) then
		GameLogic.world:MarkBlockForUpdate(x, y, z);
	end
end

function BlockEngine:IsRemote()
	if(GameLogic) then
		return GameLogic.isRemote;
	end
end


-- Sets the block ID and metadata at a given location. 
-- @param flag: bitwise field. 1 will notify neighbor blocks. 2 or nil will be the default. 3 is update with notification to nearby blocks. 
--  0 will just set block without calling the block callback func. 
-- @param entity_data: table of xml node as entity_data
-- @return true if a new block is created. 
function BlockEngine:SetBlock(x,y,z,block_id, block_data, flag, entity_data)
	local last_block_id = ParaTerrain.GetBlockTemplateByIdx(x,y,z);
	local last_block_data = ParaTerrain.GetBlockUserDataByIdx(x,y,z);
	block_id = block_id or last_block_id;
	block_data = block_data or 0;
	if(last_block_id==block_id and last_block_data == block_data and not entity_data) then
		return false
	else
		self:MarkBlockForUpdate(x, y, z);

		if(block_id ~= last_block_id) then
			ParaTerrain.SetBlockTemplateByIdx(x,y,z,block_id);

			if(last_block_data>0 and block_id > 0) then
				ParaTerrain.SetBlockUserDataByIdx(x,y,z,last_block_data); -- retain the last data
			end
		end
		
		if(last_block_id > 0) then
			local last_block = block_types.get(last_block_id);
			if(last_block) then
				if(not last_block.cubeMode and last_block.customModel) then
					last_block:DeleteModel(x,y,z);
				end
				if(flag ~= 0) then
					last_block:OnBlockRemoved(x,y,z,last_block_id, last_block_data);
				end
			end
		end
		
		if(block_id > 0) then
			local block = block_types.get(block_id);
			if(block) then
				if(block_data ~= last_block_data) then
					ParaTerrain.SetBlockUserDataByIdx(x,y,z, block_data);
				end
				if(not block.cubeMode and block.customModel) then
					block:UpdateModel(x,y,z, block_data)
				end
				if(flag ~= 0) then
					block:OnBlockAdded(x,y,z, block_data, entity_data);
				end
			end
		end

		if(flag and flag >= 3) then
			BlockEngine:NotifyNeighborBlocksChange(x, y, z, block_id);
		end
		return true;
	end
end

-- Sets the block metadata at a given location. 
-- @param flag: bitwise field. 1 will notify neighbor blocks. 2 or nil will be the default
function BlockEngine:SetBlockData(x,y,z,block_data, flag)
	local block_id = ParaTerrain.GetBlockTemplateByIdx(x,y,z);
	local block = block_types.get(block_id);
	if(block and block_data) then
		local last_data = ParaTerrain.GetBlockUserDataByIdx(x,y,z);
		if(last_data ~= block_data) then
			self:MarkBlockForUpdate(x, y, z);
			ParaTerrain.SetBlockUserDataByIdx(x,y,z, block_data);
			if(not block.cubeMode and block.customModel) then
				block:UpdateModel(x,y,z, block_data)
			end

			if(flag and flag>=3) then
				BlockEngine:NotifyNeighborBlocksChange(x,y,z, block.id);
			end
		end
	end
end

function BlockEngine:SetBlockDataForced(x,y,z,block_data)
	ParaTerrain.SetBlockUserDataByIdx(x,y,z, block_data);
	self:MarkBlockForUpdate(x, y, z);
end

function BlockEngine:GetBlockData(x,y,z)
	return ParaTerrain.GetBlockUserDataByIdx(x,y,z);
end

function BlockEngine:GetBlockId(x,y,z)
	return ParaTerrain.GetBlockTemplateByIdx(x,y,z);
end

function BlockEngine:GetBlockIdAndData(x, y, z)
	return ParaTerrain.GetBlockFullData(x, y, z);
end

-- get full info about a given block
-- @return block_id, block_data, entity_data
function BlockEngine:GetBlockFull(x,y,z)
	local block_id, user_data = ParaTerrain.GetBlockFullData(x, y, z);
	
	if block_id > 0 then
		local block = block_types.get(block_id);
		local node;
		if(block) then
			local entity = block:GetBlockEntity(x,y,z);
			if(entity) then
				node = entity:SaveToXMLNode();
			end
		end

		return block_id, user_data, node;
	else
		return block_id;
	end 

end

function BlockEngine:GetBlockEntityData(x,y,z)
	local block = self:GetBlock(x,y,z)
	if(block) then
		local entity = block:GetBlockEntity(x,y,z);
		if(entity) then
			return entity:SaveToXMLNode();
		end
	end
end

function BlockEngine:GetBlockEntity(x,y,z)
	local block = self:GetBlock(x,y,z)
	if(block) then
		return block:GetBlockEntity(x,y,z);
	end
end

function BlockEngine:GetBlockEntityList(from_x,from_y,from_z, to_x, to_y, to_z)
	local entityList;
	for x=from_x, to_x do
		for z=from_z, to_z do
			local block_id, y = self:GetNextBlockOfTypeInColumn(x,to_y+1,z)
			while(block_id and y >= from_y) do
				local entity = self:GetBlockEntity(x,y,z);
				if(entity) then
					entityList = entityList or {};
					entityList[#entityList+1] = entity;
				end
				block_id, y = self:GetNextBlockOfTypeInColumn(x,y,z)
			end
		end
	end 
	return entityList;
end

-- get full info about a given block
-- @return block_id, block_data, entity_data
function BlockEngine:GetBlockFull(x,y,z)
	local block_id, user_data = ParaTerrain.GetBlockFullData(x, y, z);
	
	if block_id > 0 then
		local block = block_types.get(block_id);
		local node;
		if(block) then
			local entity = block:GetBlockEntity(x,y,z);
			if(entity) then
				node = entity:SaveToXMLNode();
			end
		end

		return block_id, user_data, node;
	else
		return block_id;
	end 

end

-- return array of {x,y,z, id, data, entity_data}
function BlockEngine:GetAllBlocksInfoInAABB(aabb)
	local blocks = {};
	local min_x,min_y, min_z = aabb:GetMinValues();
	local max_x,max_y, max_z = aabb:GetMaxValues();
	for i=min_x, max_x do
		for j=min_y, max_y do
			for k=min_z, max_z do
				local id, data, entity_data = BlockEngine:GetBlockFull(i,j,k);
				if(id and id>0) then
					blocks[#blocks+1] = {i,j,k, id, data, entity_data};
				end
			end
		end
	end
	return blocks;
end


-- return the block template object. 
function BlockEngine:GetBlock(x,y,z)
	local block_id = ParaTerrain.GetBlockTemplateByIdx(x,y,z);
	if(block_id>0) then
		return block_types.get(block_id);
	end
end

-- return the block template table. 
function BlockEngine:GetBlockTemplateByIdx(bX, bY, bZ)
	local block_id = ParaTerrain.GetBlockTemplateByIdx(bX, bY, bZ);
	if(block_id > 0) then
		return block_types.get(block_id);
	end
end

-- Obsoleted: use BlockEngine:SetBlock
-- @param x, y, z: the block index. 
function BlockEngine.SetBlockTemplateByIdx(x,y,z,block_id, block_data)
	BlockEngine:SetBlock(x,y,z,block_id, block_data);
end

-- Obsoleted: use BlockEngine:SetBlockData
function BlockEngine.SetBlockUserDataByIdx(x,y,z,block_data)
	BlockEngine:SetBlockData(x,y,z,block_data);
end

-- is point under water
-- @param bX, bY, bZ: if nil, we will use the camera eye position. 
function BlockEngine:IsInLiquid(bX, bY, bZ)
	if(not bX) then
		eye_pos = ParaCamera.GetAttributeObject():GetField("Eye position", eye_pos);
		bX, bY, bZ = BlockEngine:block(eye_pos[1],eye_pos[2],eye_pos[3]); 
	end
	local block_id = ParaTerrain.GetBlockTemplateByIdx(bX, bY, bZ);
	if(block_id > 0) then
		local block = block_types.get(block_id);
		if(block and block.liquid) then
			return true;
		end
	end
end

-- if all 6 neighbour are empty. 
function BlockEngine:IsInAir(x,y,z)
	return ( ParaTerrain.GetBlockTemplateByIdx(x-1,y,z)==0 and  
		ParaTerrain.GetBlockTemplateByIdx(x+1,y,z)==0 and
		ParaTerrain.GetBlockTemplateByIdx(x,y-1,z)==0 and
		ParaTerrain.GetBlockTemplateByIdx(x,y+1,z)==0 and
		ParaTerrain.GetBlockTemplateByIdx(x,y,z-1)==0 and
		ParaTerrain.GetBlockTemplateByIdx(x,y,z+1)==0 );
end


-- TODO: is point under water
-- @param realX, realY, realZ: if nil, we will use the camera eye position. 
function BlockEngine:IsInLiquidReal(realX, realY, realZ)
	if(not realX) then
		eye_pos = ParaCamera.GetAttributeObject():GetField("Eye position", eye_pos);
		realX, realY, realZ = eye_pos[1],eye_pos[2],eye_pos[3]
	end
	local bX, bY, bZ = BlockEngine:block(realX, realY, realZ);
	if(not self:IsInLiquid(bX, bY, bZ)) then
		local cx, cy, cz = BlockEngine:real(bX, bY, bZ);
		if(realX<cx) then
			if(not self:IsInLiquid(bX-1, bY, bZ)) then
				if(realY<cy) then
					if(not self:IsInLiquid(bX-1, bY-1, bZ) and not self:IsInLiquid(bX, bY-1, bZ)) then
						-- TODO:
					end
				else
					if(not self:IsInLiquid(bX-1, bY+1, bZ) and not self:IsInLiquid(bX, bY-1, bZ)) then
						-- TODO:
					end
				end
			end
		else
			if(not self:IsInLiquid(bX+1, bY, bZ)) then
				if(realY<cy) then
					if(not self:IsInLiquid(bX+1, bY-1, bZ) and not self:IsInLiquid(bX, bY-1, bZ)) then
						-- TODO:
					end
				else
					if(not self:IsInLiquid(bX+1, bY+1, bZ) and not self:IsInLiquid(bX, bY-1, bZ)) then
						-- TODO:
					end
				end
			end
		end
	end
	return true;
end


-- Notifies all six neighboring blocks that from_block_id changed  
function BlockEngine:NotifyNeighborBlocksChange(x, y, z, from_block_id)
	self:OnNeighborBlockChange(x - 1, y, z, from_block_id);
	self:OnNeighborBlockChange(x + 1, y, z, from_block_id);
	self:OnNeighborBlockChange(x, y - 1, z, from_block_id);
	self:OnNeighborBlockChange(x, y + 1, z, from_block_id);
	self:OnNeighborBlockChange(x, y, z - 1, from_block_id);
	self:OnNeighborBlockChange(x, y, z + 1, from_block_id);
end

-- Notifies all six neighboring blocks that from_block_id changed, except the one on the given side. 
-- @param side: the block on this side is not notified. 
function BlockEngine:NotifyNeighborBlocksChangeNoSide(x, y, z, from_block_id, side)
    if (side ~= 0) then
        self:OnNeighborBlockChange(x - 1, y, z, from_block_id);
    end

    if (side ~= 1) then
        self:OnNeighborBlockChange(x + 1, y, z, from_block_id);
    end

    if (side ~= 4) then
        self:OnNeighborBlockChange(x, y - 1, z, from_block_id);
    end

    if (side ~= 5) then
        self:OnNeighborBlockChange(x, y + 1, z, from_block_id);
    end

    if (side ~= 2) then
        self:OnNeighborBlockChange(x, y, z - 1, from_block_id);
    end

    if (side ~= 3) then
        self:OnNeighborBlockChange(x, y, z + 1, from_block_id);
    end
end


-- Notifies a block that one of its neighbor change to the specified type
-- @param from_block_id: the block id that has changed
function BlockEngine:OnNeighborBlockChange(x, y, z, from_block_id)
    local block_id = ParaTerrain.GetBlockTemplateByIdx(x, y, z);
	if(block_id > 0) then
		local block = block_types.get(block_id)
		if (block) then
			block:OnNeighborChanged(x, y, z, from_block_id);
		end
	end
end

-- get block material
function BlockEngine:GetBlockMaterial(x,y,z)
	local block_id = ParaTerrain.GetBlockTemplateByIdx(x, y, z);
	if(block_id > 0) then
		local block = block_types.get(block_id)
		if (block) then
			return block.material;
		end
	end
	return Materials.air;
end



-- Is this block powering in the specified direction 
function BlockEngine:isBlockProvidingStrongPowerTo(x, y, z, direction)
    local block_id = ParaTerrain.GetBlockTemplateByIdx(x,y,z);
	if(block_id == 0) then
		return 0
	else
		local block_template = block_types.get(block_id);
		if(block_template) then
			return block_template:isProvidingStrongPower(x, y, z, direction);
		else
			return 0;
		end
	end
end

-- Returns the highest strong power input from this block's six neighbors. 
function BlockEngine:getBlockStrongPowerInput(x,y,z)
    local max_power = math.max(0, self:isBlockProvidingStrongPowerTo(x, y - 1, z, 5));

    if (max_power >= 15) then
        return max_power;
    else
        max_power = math.max(max_power, self:isBlockProvidingStrongPowerTo(x, y + 1, z, 4));

        if (max_power >= 15) then
            return max_power;
        else
            max_power = math.max(max_power, self:isBlockProvidingStrongPowerTo(x, y, z - 1, 3));

            if (max_power >= 15) then
                return max_power;
            else
                max_power = math.max(max_power, self:isBlockProvidingStrongPowerTo(x, y, z + 1, 2));

                if (max_power >= 15) then
                    return max_power;
                else
                    max_power = math.max(max_power, self:isBlockProvidingStrongPowerTo(x - 1, y, z, 1));

                    if (max_power >= 15) then
                        return max_power;
                    else
                        max_power = math.max(max_power, self:isBlockProvidingStrongPowerTo(x + 1, y, z, 0));
                        return max_power;
                    end
                end
            end
        end
    end
end


-- Returns the weak power being outputted by the given block to the given direction.
function BlockEngine:hasWeakPowerOutputTo(x,y,z,dir)
    return self:getWeakPowerOutputTo(x,y,z,dir) > 0;
end

-- Indicate if a material is a normal solid opaque cube.
function BlockEngine:isBlockNormalCube(x,y,z)
	local block = BlockEngine:GetBlockTemplateByIdx(x,y,z);
	return block and block:isBlockNormalCube();
end

-- Gets the indirect(weak) power level of this block to a given side. 
-- Normal cube block will output the highest strong power input as weak output to all of its six faces. 
function BlockEngine:getWeakPowerOutputTo(x,y,z,dir)
    if (BlockEngine:isBlockNormalCube(x, y, z)) then
        return self:getBlockStrongPowerInput(x, y, z);
    else
        local block = BlockEngine:GetBlockTemplateByIdx(x,y,z);
		if(block) then
			return block:isProvidingWeakPower(x, y, z, dir);
		else
			return 0;
		end
    end
end

-- Used to see if one of the blocks next to you or your block is getting power from a neighboring block. Used by
-- items like TNT or Doors so they don't have going straight into them.  
function BlockEngine:isBlockIndirectlyGettingPowered(x, y, z)
	if( self:getWeakPowerOutputTo(x, y - 1, z, 5) > 0 or self:getWeakPowerOutputTo(x, y + 1, z, 4) > 0 or 
		self:getWeakPowerOutputTo(x, y, z - 1, 3) > 0 or self:getWeakPowerOutputTo(x, y, z + 1, 2) > 0 or 
		self:getWeakPowerOutputTo(x - 1, y, z, 1) > 0 or self:getWeakPowerOutputTo(x + 1, y, z, 0) > 0 ) then
		return true;
	else
		return false;
	end
end

-- get strongest indirect power from the neighboring 6 blocks. wires will transmit indirect power to its neighbor
function BlockEngine:getStrongestIndirectPower(x, y, z)
    local max_power = 0;

    for dir = 0, 5 do
		local x1,y1,z1 = BlockEngine:GetBlockIndexBySide(x,y,z,dir)
        local power = self:getWeakPowerOutputTo(x1,y1,z1, BlockEngine:GetOppositeSide(dir));

        if (power >= 15) then
            return 15;
        elseif (power > max_power) then
            max_power = power;
        end
    end

    return max_power;
end

-- Performs check to see if the block is a normal, solid block, or if the metadata of the block indicates that its
-- facing puts its solid side upwards. (inverted stairs, for example)
-- Returns true if the block at the given coordinate has a solid (buildable) top surface.
function BlockEngine:DoesBlockHaveSolidTopSurface(x,y,z)
	local block = self:GetBlock(x,y,z);
    if(block and block:isNormalCube()) then
		return true;
	end
end    



-- dump the current state of the block engine
function BlockEngine:Dump()
	echo("----------------------dumping block engine -------------------");
	echo({eye_block = self.eye_block, eye = self.eye, min_y = self.min_y, max_y = self.max_y});
end


