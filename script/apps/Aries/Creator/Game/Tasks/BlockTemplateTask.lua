--[[
Title: Block Template Task
Author(s): LiXizhi
Date: 2014/6/15
Desc: loading and saving block template. Block template plays a very important role that in future 
it allow user to create more discrete objects. if block position is nil or 0, it will use absolute position. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
-- if block position is nil or 0, it will load using absolute position if any. 
local task = BlockTemplate:new({operation = BlockTemplate.Operations.Load, filename = filename,
		blockX = bx,blockY = by, blockZ = bz, bSelect=bSelect, UseAbsolutePos = false, TeleportPlayer = false})
task:Run();

local task = BlockTemplate:new({operation = BlockTemplate.Operations.Save, filename = filename, params = params, blocks = blocks})
task:Run();

-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/FastRandom.lua");
local FastRandom = commonlib.gettable("MyCompany.Aries.Game.Common.CustomGenerator.FastRandom");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")

local BlockTemplate = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate"));

-- operations enumerations
BlockTemplate.Operations = {
	-- load a block template
	Load = 1,
	-- save template
	Save = 2,
	-- load with block creation animation
	AnimLoad = 3,
	-- remove blocks 
	Remove = 4,
}
-- current operation
BlockTemplate.operation = BlockTemplate.Operations.Load;
-- how many concurrent creation point allowed: currently this must be 1
BlockTemplate.concurrent_creation_point_count = 1;
-- true to add to history. 
BlockTemplate.add_to_history = nil;

function BlockTemplate:ctor()
	self.step = 1;
	self.history = {};
	self.active_points = {};
end

function BlockTemplate:Run()
	self.finished = true;
	if(self.operation == BlockTemplate.Operations.Load) then
		return self:LoadTemplate();
	elseif(self.operation == BlockTemplate.Operations.Save) then
		return self:SaveTemplate();
	elseif(self.operation == BlockTemplate.Operations.AnimLoad) then
		return self:AnimLoadTemplate();
	elseif(self.operation == BlockTemplate.Operations.Remove) then
		return self:RemoveTemplate();
	end
end

-- add simulation point
function BlockTemplate:AddActivePoint(x,y,z)
	local sparse_index = BlockEngine:GetSparseIndex(x, y, z);
	self.active_points[sparse_index] = 1;
end

function BlockTemplate:GetBlockPosition()
	if(not self.blockX) then
		local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
		local player = self.entityPlayer or EntityManager.GetPlayer();
		if(player) then
			self.blockX, self.blockY, self.blockZ = player:GetBlockPos();
		end
	end
	return self.blockX, self.blockY, self.blockZ
end

-- when relative_motion is true in the template file, we will need to convert actors positions in movie blocks to relative position. 
function BlockTemplate:CalculateRelativeMotion(blocks, bx, by, bz)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMovieClip.lua");
	local EntityMovieClip = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMovieClip")
	local movieBlockId = block_types.names.MovieClip; -- id is 228
	for i, block in ipairs(blocks) do
		local block_id = block[4];
		if(block_id == movieBlockId) then
			local entityData = block[6];
			if(entityData) then
				local ox, oy, oz = entityData.attr.bx, entityData.attr.by, entityData.attr.bz;
				if(ox and oy and oz) then
					local offset_x, offset_y, offset_z = bx + block[1]- ox, by + block[2]- oy, bz + block[3] - oz;
					local movieEntity = EntityMovieClip:new();
					movieEntity:LoadFromXMLNode(entityData);
					movieEntity:OffsetActorPositions(offset_x, offset_y, offset_z);
					movieEntity.bx = movieEntity.bx + offset_x;
					movieEntity.by = movieEntity.by + offset_y;
					movieEntity.bz = movieEntity.bz + offset_z;
					-- save data back to block[6]
					block[6] = movieEntity:SaveToXMLNode();
				end
			end
		end
	end
end

-- Load template
function BlockTemplate:LoadTemplate()
	local filename = self.filename;
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(xmlRoot) then
		local root_node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate");
		if(root_node and root_node[1]) then
			if( self.UseAbsolutePos and root_node.attr and root_node.attr.pivot) then
				local x, y, z = root_node.attr.pivot:match("^(%d+)%D+(%d+)%D+(%d+)");
				if(x and y and z) then
					self.blockX = tonumber(x);
					self.blockY = tonumber(y);
					self.blockZ = tonumber(z);
				end
			end

			local node = commonlib.XPath.selectNode(root_node, "/pe:blocks");
			if(node and node[1]) then
				local blocks = NPL.LoadTableFromString(node[1]);
				if(blocks and #blocks > 0) then
					local bx, by, bz = self:GetBlockPosition();
					LOG.std(nil, "info", "BlockTemplate", "LoadTemplate from file: %s at pos:%d %d %d", filename, bx, by, bz);

					if(root_node.attr and root_node.attr.relative_motion == "true") then
						self:CalculateRelativeMotion(blocks, bx, by, bz);
					end

					NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateBlockTask.lua");
					local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blockX = bx,blockY = by, blockZ = bz, blocks = blocks, bSelect=self.bSelect})
					task:Run();
					
					if( self.TeleportPlayer and root_node.attr.player_pos) then
						local x, y, z = root_node.attr.player_pos:match("^(%d+)%D+(%d+)%D+(%d+)");
						if(x and y and z) then
							x = tonumber(x);
							y = tonumber(y);
							z = tonumber(z);
							NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeleportPlayerTask.lua");
							local task = MyCompany.Aries.Game.Tasks.TeleportPlayer:new({blockX = x,blockY = y, blockZ = z})
							task:Run();
						end
					end
					return true;
				end
			end
		end
	end
	LOG.std(nil, "warn", "BlockTemplate", "failed to load template from file: %s", filename);
end

-- remove template
function BlockTemplate:RemoveTemplate()
	local filename = self.filename;
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(xmlRoot) then
		local node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate/pe:blocks");
		if(node and node[1]) then
			local blocks = NPL.LoadTableFromString(node[1]);
			if(blocks and #blocks > 0) then
				local px, py, pz = self.blockX, self.blockY, self.blockZ;
				for _, b in ipairs(blocks) do
					BlockEngine:SetBlock(b[1]+px, b[2]+py, b[3]+pz, 0);
				end
				return true;
			end
		end
	end
end

-- Save to template. if no 
-- self.params: root level attributes
-- self.filename: 
-- self.blocks: if nil, the current selection is used. 
function BlockTemplate:SaveTemplate()
	local filename = self.filename;
	ParaIO.CreateDirectory(filename);
	local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then 
		self.params = self.params or {};
		self.params.auto_scale = self.auto_scale;
		local o = {name="pe:blocktemplate", attr = self.params};

		if(not self.blocks) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
			local select_task = MyCompany.Aries.Game.Tasks.SelectBlocks.GetCurrentInstance();
			if(select_task) then
				local pivot = select_task:GetPivotPoint();
				-- local block_pivot = BlockEngine:GetBlock(pivot[1],pivot[2],pivot[3]);
				-- if(block_pivot and block_pivot.id == block_types.names.Command_Block) then
				-- 	-- TODO: use the displayed pivot point if it is on a command block. 
				-- end
				self.blocks = select_task:GetCopyOfBlocks(pivot);
			else
				return;
			end
		end

		o[1] = {name="pe:blocks", [1]=commonlib.serialize_compact(self.blocks),}
		file:WriteString(commonlib.Lua2XmlString(o, true));
		file:close();
		
		if(filename:match("%.bmax$")) then
			-- refresh it if it is a bmax model.
			ParaAsset.LoadParaX("", filename):UnloadAsset();
		end
		return true;
	end
end

function BlockTemplate:Redo()
	if(self.blockX and self.fill_id and (#self.history)>0) then
		local _, b;
		for _, b in ipairs(self.history) do
			BlockEngine:SetBlock(b[1],b[2],b[3], b[4] or self.fill_id);
		end
	end
end

function BlockTemplate:Undo()
	if(self.blockX and self.fill_id and (#self.history)>0) then
		local _, b;
		for _, b in ipairs(self.history) do
			BlockEngine:SetBlock(b[1],b[2],b[3], b[4] or 0);
		end
	end
end

-- Anim Load template
-- self.load_anim_duration: number of seconds to load the block
function BlockTemplate:AnimLoadTemplate()
	local filename = self.filename;
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(xmlRoot) then
		local node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate/pe:blocks");
		if(node and node[1]) then
			local blocks = NPL.LoadTableFromString(node[1]);
			if(blocks and #blocks > 0) then
				self.blocks = blocks;
				self.blocks_per_tick = math.floor((#blocks) / ((self.load_anim_duration or 5) * 20)+1);

				local unfinished_blocks = {};
				for index, b in ipairs(blocks) do
					unfinished_blocks[BlockEngine:GetSparseIndex(b[1], b[2], b[3])] = index;
				end
				self.unfinished_blocks = unfinished_blocks;

				self.create_locations = {};
				self.random = FastRandom:new({_seed = #blocks});

				self:AutoPickCreateLocation();

				self.finished = false;
				TaskManager.AddTask(self);
				return true;
			end
		end
	end
end

function BlockTemplate:AddBlock(block_id, x,y,z,block_data, entity_data, bCheckCanCreate)
	if(self.add_to_history) then
		local from_id = BlockEngine:GetBlockId(x,y,z);
		local from_data, last_entity_data;
		if(from_id and from_id>0) then
			from_data = BlockEngine:GetBlockData(x,y,z);
			from_entity_data = BlockEngine:GetBlockEntityData(x,y,z);
		end
		self.history[#(self.history)+1] = {x,y,z, block_id, from_id, from_data, block_data, entity_data, from_entity_data};
	end
	local block_template = block_types.get(block_id);
	if(block_template) then
		block_template:Create(x,y,z, bCheckCanCreate~=false, block_data, nil, nil, entity_data);
	end
end

-- automatically pick a location to create from. it will search suitable location from the bottom up
-- this function can be called multiple times to create multiple locations at once. 
function BlockTemplate:AutoPickCreateLocation()
	local candidate;
	local blocks = self.blocks;
	for parse_index, index in pairs(self.unfinished_blocks) do
		if(not candidate or candidate[2] > blocks[index][2]) then
			candidate = blocks[index];
		end
	end
	if(candidate) then
		-- self.unfinished_blocks[BlockEngine:GetSparseIndex(candidate[1], candidate[2], candidate[3])] = nil;
		self.create_locations[#(self.create_locations) + 1] = candidate;
		-- init interation count
		candidate.iter_count = 0;
	end
end

function BlockTemplate:RecursiveAddAllConnectedBlocks(x,y,z, count, iter_count)
	local sparse_idx = BlockEngine:GetSparseIndex(x,y,z);
	local idx = self.unfinished_blocks[sparse_idx];
	if(idx) then
		local b = self.blocks[idx];
		if(b) then
			iter_count = (iter_count or 0);
			if(count <= 0 or not x) then
				self.create_locations[#(self.create_locations)+1] = b;
				b.iter_count = iter_count;
				return count;
			else
				self:AddBlock(b[4], x+self.blockX, y+self.blockY, z+self.blockZ, b[5], b[6], nil);
				self.unfinished_blocks[sparse_idx] = nil;
				count = count - 1;
				local nBuildFactor = self.random:randomDouble();
				if(nBuildFactor < 50/(50+iter_count) ) then
					count = self:RecursiveAddAllConnectedBlocks(x-1,y,z, count, iter_count+1);
					count = self:RecursiveAddAllConnectedBlocks(x+1,y,z, count, iter_count+1);
					count = self:RecursiveAddAllConnectedBlocks(x,y-1,z, count, iter_count+1);
					if(nBuildFactor < (1/(5+iter_count*3))) then
						-- make it harder to build upward. 
						count = self:RecursiveAddAllConnectedBlocks(x,y+1,z, count, iter_count*3+5);
					end
					count = self:RecursiveAddAllConnectedBlocks(x,y,z-1, count, iter_count+1);
					count = self:RecursiveAddAllConnectedBlocks(x,y,z+1, count, iter_count+1);
				end
			end
		end
	end
	return count;
end

function BlockTemplate:FrameMove()
	self.step = self.step + 1;

	local count = self.blocks_per_tick or 10;

	while(count > 0) do
		while(#(self.create_locations) > 0 and count>0) do
			local nSize = #(self.create_locations);
			local b = self.create_locations[nSize];
			self.create_locations[nSize] = nil;
			count = self:RecursiveAddAllConnectedBlocks(b[1], b[2], b[3], count);
		end
		if(#(self.create_locations) < self.concurrent_creation_point_count) then
			self:AutoPickCreateLocation();
			if(#(self.create_locations) == 0) then
				-- end of blocks
				count = 0;
			end
		end
	end

	if(not next(self.unfinished_blocks)) then
		self.finished = true;
	end
end

