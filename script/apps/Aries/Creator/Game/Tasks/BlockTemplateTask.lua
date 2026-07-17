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
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Task.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/FastRandom.lua");
NPL.load("(gl)script/ide/System/Core/Color.lua");
local Color = commonlib.gettable("System.Core.Color");
local FastRandom = commonlib.gettable("MyCompany.Aries.Game.Common.CustomGenerator.FastRandom");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
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
	-- According to the tier to load
	TierLoad = 5,
	-- just load the template to memory, without actually creating blocks.
	LoadToMemory = 6,
}
-- current operation
BlockTemplate.operation = BlockTemplate.Operations.Load;
-- how many concurrent creation point allowed: currently this must be 1
BlockTemplate.concurrent_creation_point_count = 1;
-- true to disable history
BlockTemplate.nohistory = nil;
-- true to export hollow model
BlockTemplate.hollow = nil;
-- true to export externally referenced files, such as bmax files in movie or model block.
BlockTemplate.exportReferencedFiles = nil;

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
	elseif(self.operation == BlockTemplate.Operations.TierLoad) then
		return self:LoadTemplate();
	elseif(self.operation == BlockTemplate.Operations.LoadToMemory) then
		return self:LoadTemplateToMemory();
	else
		LOG.std(nil, "warn", "BlockTemplate", "unknown operation: %d", self.operation);
		return false;
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

-- return table map {filename=referenceCount} of referenced external files, usually bmax files in the world directory. such as {"abc.bmax", "a.fbx", }
-- if no external files are referenced, we will return nil.
function BlockTemplate:GetReferenceFiles(blocks, liveEntities)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMovieClip.lua");
	local EntityMovieClip = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMovieClip")
	local movieBlockId = block_types.names.MovieClip;
	local PhysicsModel = block_types.names.PhysicsModel;
	local BlockModel = block_types.names.BlockModel;

	local files = {};
	for i, block in ipairs(blocks) do
		local block_id = block[4];
		if(block_id == movieBlockId) then
			local entityData = block[6];
			if(entityData) then
				local movieEntity = EntityMovieClip:new();
				movieEntity:LoadFromXMLNode(entityData);
				local files_ = movieEntity:GetReferenceFiles();
				if(files_) then
					for filename, _ in pairs(files_) do
						files[filename] = (files[filename] or 0) + 1;
					end
				end
			end
		elseif(block_id == PhysicsModel or block_id == BlockModel) then
			local entityData = block[6];
			if(entityData and entityData.attr.filename and entityData.attr.filename~="") then
				files[entityData.attr.filename] = (files[entityData.attr.filename] or 0) + 1;
			end
		end
	end
	if(liveEntities) then
		for _, entityData in ipairs(liveEntities) do
			if(entityData and entityData.attr.filename and entityData.attr.filename~="") then
				files[entityData.attr.filename] = (files[entityData.attr.filename] or 0) + 1;
			end
		end
	end

	if(next(files)) then
		return files;
	end
end

-- load block template to memory only, without actually creating blocks.
-- one can later get via self.blocks and self.liveEntities or using API like get GetBlock, GetBlockEntity
-- @param filename: can be nil in which case self.filename will be used
-- @return boolean, blocks, liveEntities: true if succeed and blocks and liveEntities tables
function BlockTemplate:LoadTemplateToMemory(filename)
	filename = filename or Files.GetFilePath(self.filename);
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(xmlRoot) then
		local root_node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate");
		if(root_node and root_node[1]) then
			local dx, dy, dz;
			if(self.UseAbsolutePos and root_node.attr and root_node.attr.pivot) then
				local x, y, z = root_node.attr.pivot:match("^(%d+)%D+(%d+)%D+(%d+)");
				if(x and y and z) then
					dx = tonumber(x);
					dy = tonumber(y);
					dz = tonumber(z);
				end
			end
			
			local node = commonlib.XPath.selectNode(root_node, "/pe:blocks");
			if(node and node[1]) then
				local blocks = NPL.LoadTableFromString(node[1]);
				if(blocks and #blocks > 0) then
					self.blocks = blocks
					if(dx and dy and dz) then
						for _, b in ipairs(self.blocks) do
							b[1] = b[1] + dx;
							b[2] = b[2] + dy;
							b[3] = b[3] + dz;
						end
					end
				end
			end

			local node = commonlib.XPath.selectNode(root_node, "/pe:entities");
			if(node) then
				local entities = NPL.LoadTableFromString(node[1]);
				if(entities and #entities > 0) then
					self.liveEntities = entities;
					
					-- precalculate dx, dy, dz with blocksize
					local dx_blocksize, dy_blocksize, dz_blocksize
					if dx and dy and dz then
						dx_blocksize = dx * BlockEngine.blocksize
						dy_blocksize = dy * BlockEngine.blocksize
						dz_blocksize = dz * BlockEngine.blocksize
					end

					for _, entity in ipairs(self.liveEntities) do
						if(entity.attr and entity.attr.x) then
							if(dx_blocksize and dy_blocksize and dz_blocksize) then
								entity.attr.x = entity.attr.x + dx_blocksize;
								entity.attr.y = entity.attr.y + dy_blocksize;
								entity.attr.z = entity.attr.z + dz_blocksize;
							end
						end
					end
				end
			end
			return true, self.blocks, self.liveEntities;
		end
	end
end

function BlockTemplate:GetBlock(x,y,z)
	if(not self.blockIndexMap and self.blocks) then
		-- Lazy initialization of blockIndexMap
		self.blockIndexMap = {}
		for _, b in ipairs(self.blocks) do
			self.blockIndexMap[BlockEngine:GetSparseIndex(b[1], b[2], b[3])] = b
		end
	end
	if(self.blockIndexMap) then
		return self.blockIndexMap[BlockEngine:GetSparseIndex(x, y, z)]
	end
end

function BlockTemplate:GetBlockId(x,y,z)
	local block = self:GetBlock(x,y,z)
	if(block) then
		return block[4]
	end
end

function BlockTemplate:GetBlockEntity(x,y,z)
	if(not self.blockEntityIndexMap and self.liveEntities) then
		-- Lazy initialization of blockEntityIndexMap
		self.blockEntityIndexMap = {}
		for _, entity in ipairs(self.liveEntities) do
			if(entity.attr and entity.attr.x) then
				local bx, by, bz = BlockEngine:block(entity.attr.x, entity.attr.y, entity.attr.z);
				self.blockEntityIndexMap[BlockEngine:GetSparseIndex(bx, by, bz)] = entity
			end
		end
	end
	if(self.blockEntityIndexMap) then
		return self.blockEntityIndexMap[BlockEngine:GetSparseIndex(x, y, z)]
	end
end

-- @param filename: can be nil
-- @return true if succeed
function BlockTemplate:LoadTemplateFromXmlNode(xmlRoot, filename)
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
			
			local node = commonlib.XPath.selectNode(root_node, "/references");
			if(node) then
				for _, fileNode in ipairs(node) do
					local filename = fileNode.attr.filename
					local filepath 
					if self.write_reference_from_path then
						filename = filename:match("[^/\\]+$")
						filepath = Files.GetTempPath().."createPlatform/"..commonlib.Encoding.Utf8ToDefault(filename);
					elseif(filename:find("temp/", 1, true)) then
						filepath = ParaIO.GetWritablePath()..commonlib.Encoding.Utf8ToDefault(filename);
					else
						filepath = GameLogic.GetWorldDirectory()..commonlib.Encoding.Utf8ToDefault(filename);
					end
					if(not ParaIO.DoesFileExist(filepath, true)) then
						local text = fileNode[1];
						NPL.load("(gl)script/ide/System/Encoding/base64.lua");
						text = System.Encoding.unbase64(text)
						ParaIO.CreateDirectory(filepath)
						local file = ParaIO.open(filepath, "w")
						if(file:IsValid()) then
							file:WriteString(text, #text);
							file:close();
						else
							LOG.std(nil, "warn", "BlockTemplate", "failed to write file to: %s", filepath);
						end
					else
						LOG.std(nil, "info", "BlockTemplate", "load template ignored existing world file: %s", filename);
					end
				end
			end

			local node = commonlib.XPath.selectNode(root_node, "/pe:entities");
			local liveEntities;
			if(node) then
				local entities = NPL.LoadTableFromString(node[1]);
				if(entities and #entities > 0) then
					liveEntities = entities;
				end
			end
			
			if liveEntities and self.write_reference_from_path then
				for k,v in pairs(liveEntities) do
					if v.attr and v.attr.filename and v.attr.filename ~= "" then
						v.attr.filename = "createPlatform/"..v.attr.filename:match("[^/\\]+$")
					end
				end
			end

			local node = commonlib.XPath.selectNode(root_node, "/pe:blocks");
			if(node and node[1]) then
				local blocks = NPL.LoadTableFromString(node[1]);
				local bx, by, bz = self:GetBlockPosition();
				LOG.std(nil, "info", "BlockTemplate", "LoadTemplate from file: %s at pos:%d %d %d", filename, bx, by, bz);

				if(blocks and #blocks > 0) then
					if(root_node.attr and root_node.attr.relative_motion == "true") then
						self:CalculateRelativeMotion(blocks, bx, by, bz);
					end
				end
				if((blocks and #blocks > 0) or liveEntities) then
					NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateBlockTask.lua");

					if self.operation == BlockTemplate.Operations.TierLoad then
						local layer_blocks = {}
						local layer_y = blocks[1][2]
						local layer_index = 1
						for index, block in ipairs(blocks) do
							if block[2] ~= layer_y then
								layer_y = block[2]
								layer_index = layer_index + 1
							end
		
							if layer_blocks[layer_index] == nil then
								layer_blocks[layer_index] = {}
							end
		
							local layer = layer_blocks[layer_index]
							layer[#layer + 1] = block
						end
						
						if #layer_blocks > 0 then
							local index = 1
							self.tire_load_timer = self.tire_load_timer or commonlib.Timer:new({callbackFunc = function(timer)
								local target_layer = layer_blocks[index]
								if not target_layer then
									self.tire_load_timer:Change();
									return 
								end
	
								local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blockX = bx,blockY = by, blockZ = bz, blocks = target_layer, liveEntities=liveEntities, bSelect=self.bSelect, nohistory = self.nohistory, isSilent = true,rename = self.rename})
								task:Run();
								index = index + 1
							end})
	
							local interval = math.floor(self.load_anim_duration * 1000/#layer_blocks)
							self.tire_load_timer:Change(0,interval);
						else
							local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blockX = bx,blockY = by, blockZ = bz, blocks = blocks, liveEntities=liveEntities, bSelect=self.bSelect, nohistory = self.nohistory, isSilent = true,rename = self.rename})
							task:Run();
						end
					else
						local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blockX = bx,blockY = by, blockZ = bz, blocks = blocks, liveEntities=liveEntities, 
							bSelect=self.bSelect, nohistory = self.nohistory, add_to_history = self.add_to_history,
							isSilent = true,rename = self.rename,
							keepEntityReferences = self.keepEntityReferences
						})
						task:Run();
						if(self.keepEntityReferences) then
							self.entity_references = task.entity_references;
						end
					end
					
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
				end
			end
			return true;
		end
	end
end

-- @param filename: *.ply point cloud file
function BlockTemplate:LoadTemplateFromPly(filename)
	local file = ParaIO.open(filename, "r");
	if(file:IsValid()) then
		local line = file:readline();
		local vertex_count = 0;
		local vertex_data = {};
		while(line) do
			if(line:match("^element vertex")) then
				vertex_count = tonumber(line:match("%d+"));
			elseif(line:match("^end_header")) then
				break;
			end
			line = file:readline();
		end
		if(vertex_count > 0) then
			local vMinX, vMinY, vMinZ = 999999, 999999, 999999;
			local vMaxX, vMaxY, vMaxZ = -999999, -999999, -999999;
			for i = 1, vertex_count do
				line = file:readline();
				local x, y, z, color = line:match("([%d%.%-]+) ([%d%.%-]+) ([%d%.%-]+)(.*)");
				if(x and y and z) then
					x = tonumber(x);
					y = tonumber(y);
					z = tonumber(z);
					vMinX = math.min(vMinX, x);
					vMinY = math.min(vMinY, y);
					vMinZ = math.min(vMinZ, z);
					vMaxX = math.max(vMaxX, x);
					vMaxY = math.max(vMaxY, y);
					vMaxZ = math.max(vMaxZ, z);

					local r, g, b = color:match("(%d+) (%d+) (%d+)");
					if(r) then
						r = tonumber(r);
						g = tonumber(g);
						b = tonumber(b);
					else
						r = 255;
						g = 255;
						b = 255;
					end
					local color16 = Color.convert32_16(Color.RGB_TO_DWORD(r,g,b))
					-- swap y and z
					vertex_data[#vertex_data+1] = {x, z, y, color16};
				end
			end
			local vol = (vMaxX - vMinX) * (vMaxY - vMinY) * (vMaxZ - vMinZ);
			if(vertex_count > 0 and (vertex_count / vol) > 1 and 
				(vMinX~=math.floor(vMinX+0.5) or vMinY~=math.floor(vMinY+0.5) or vMinZ~=math.floor(vMinZ+0.5) or vMaxX~=math.floor(vMaxX+0.5) or vMaxY~=math.floor(vMaxY+0.5) or vMaxZ~=math.floor(vMaxZ+0.5)) ) then
				-- iPhone will generate floating point positions, we will scale by a factor.  
				local scale = vertex_count / vol;
				LOG.std(nil, "info", "BlockTemplate", "automatically scaling floating point vertex positions by %f", scale);
				for i = 1, vertex_count do
					local v = vertex_data[i];
					v[1] = math.floor(v[1] * scale + 0.5);
					v[2] = math.floor(v[2] * scale + 0.5);
					v[3] = math.floor(v[3] * scale + 0.5);
				end
			end
		end
		file:close();
		if(vertex_count > 0) then
			local bx, by, bz = self:GetBlockPosition();
			local blocks = {};
			local block_id = block_types.names.ColorBlock;
			for i = 1, vertex_count do
				local x, y, z, color16 = unpack(vertex_data[i]);
				blocks[#blocks+1] = {x, y, z, block_id, color16};
			end
			local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blockX = bx,blockY = by, blockZ = bz, blocks = blocks, bSelect=self.bSelect, nohistory = self.nohistory, isSilent = true})
			task:Run();
			return true;
		end
	end
end

-- Load template
function BlockTemplate:LoadTemplate()
	local filename = Files.GetFilePath(self.filename);
	if(not filename) then
		LOG.std(nil, "warn", "BlockTemplate", "failed to load template from file: %s", self.filename);
		return;
	end
	if(filename:match("%.ply$")) then
		return self:LoadTemplateFromPly(filename)
	end
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);

	if (self.opaque) then
		local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");

		local root_node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate");
		local node = commonlib.XPath.selectNode(root_node, "/pe:blocks");

		if(node and node[1]) then
			local blocks = NPL.LoadTableFromString(node[1]);
			for key, item in ipairs(blocks) do
				if (item and item[4] == 0) then
					item[4] = 10
				elseif (item and item[4] ~= 0 and item[4] ~= 10) then
					local beExist = false

					if (item and type(item[4]) == 'number') then
						for iKey, iItem in ipairs(ItemClient.GetBlockDS()) do
							if (iItem and iItem.block_id == item[4]) then
								beExist = true;
								break;
							end
						end
					end

					if (not beExist) then
						item[5] = item[4] % 4096;
						item[4] = 10;
					end
				end
			end
			
			xmlRoot[1][1][1] = commonlib.serialize(blocks)
		end
	end

	if(not self:LoadTemplateFromXmlNode(xmlRoot, filename)) then
		LOG.std(nil, "warn", "BlockTemplate", "failed to load template from file: %s", filename);
	else
		return true
	end
end

-- remove template
function BlockTemplate:RemoveTemplate()
	local filename = self.filename;
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(xmlRoot) then
		if(self.UseAbsolutePos) then
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
			end
		end
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

-- remove blocks whose six sides are all solid blocks. 
function BlockTemplate:MakeHollow()
	local blocks = self.blocks;
	if(blocks and #blocks > 0) then
		local blockmap = {}
		for index, b in ipairs(blocks) do
			local x, y, z, block_id = b[1], b[2], b[3], b[4];
			local block = block_types.get(block_id);
			if(block and block:isNormalCube()) then
				blockmap[BlockEngine:GetSparseIndex(x, y, z)] = index;
			end
		end
		local hollowblocks = {}
		local removeIndex
		for _, index in pairs(blockmap) do
			local b = blocks[index];
			local x, y, z = b[1], b[2], b[3];
			local isHollow = true;
			for side=0, 5 do
				local dx, dy, dz = Direction.GetOffsetBySide(side)
				if(not blockmap[BlockEngine:GetSparseIndex(x+dx, y+dy, z+dz)]) then
					isHollow = false
					break;
				end
			end
			if(isHollow) then
				hollowblocks[index] = true;
			end
		end
		if(next(hollowblocks)) then
			local newBlocks = {}
			for index, b in ipairs(blocks) do
				if(not hollowblocks[index]) then
					newBlocks[#newBlocks+1] = b;
				end
			end
			self.blocks = newBlocks
		end
	end
end

-- @param fileData: bmax file content string
function BlockTemplate:GetBlockCountInString(fileData)
	local count = 0;
	local xmlRoot = ParaXML.LuaXML_ParseString(fileData);
	if(xmlRoot) then
		local node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate");
		if(node and node.attr and node.attr.count) then
			count = tonumber(node.attr.count) or 0
		elseif(node and node[1]) then
			local blocks = NPL.LoadTableFromString(node[1]);
			if(blocks and #blocks > 0) then
				count = #blocks;
			end
		end
	end
	return count;
end

-- return xml string or nil
function BlockTemplate:SaveTemplateToString()
	self.params = self.params or {};
	self.params.auto_scale = self.auto_scale;
	if(not self.params.relative_motion) then
		self.params.relative_motion = self.relative_motion;
	end
	if(not self.params.relative_to_player) then
		self.params.relative_to_player = self.relative_to_player;
	end
	local o = {name="pe:blocktemplate", attr = self.params};
	
	if(not self.blocks) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
		local select_task = MyCompany.Aries.Game.Tasks.SelectBlocks.GetCurrentInstance();
		if(select_task) then
			local pivot = select_task:GetPivotPoint();
			if(self.auto_pivot) then
				local x,y,z = select_task:GetSelectionPivot();
				pivot = {x,y,z}
			end
			self.params.pivot = string.format("%d,%d,%d",pivot[1],pivot[2],pivot[3]);
			self.blocks = select_task:GetCopyOfBlocks(pivot, self.sort_blocks);
			if(self.withentity) then
				self.liveEntities = select_task.GetLiveEntitiesInAABB(select_task.aabb, pivot) 
			end
		else
			return;
		end
	end

	if(self.hollow) then
		self:MakeHollow()
	end
	local totalCount = #(self.blocks);

	--保存bmax嵌套
	for i=1,totalCount do
		local block = self.blocks[i]
		local attr = block[6] and block[6].attr or nil
		if  attr and attr.item_id == 254 then
			local modelFile = attr.filename
			if type(modelFile) == "string" and string.len(modelFile) ~= ParaMisc.GetUnicodeCharNum(modelFile) then --存在中文
				self.blocks[i][6].attr.filename = commonlib.Encoding.Utf8ToDefault(modelFile)
			end
		end
	end

	o[1] = {name="pe:blocks", [1]=commonlib.serialize_compact(self.blocks, true),};
	local ref = {name="references", };
	if(self.liveEntities and (#(self.liveEntities)) > 0) then
		o[#o+1] = {name="pe:entities", attr={count=#(self.liveEntities)}, [1]=commonlib.serialize_compact(self.liveEntities, true),};
	end
	if(self.exportReferencedFiles) then
		local files = self:GetReferenceFiles(self.blocks, self.liveEntities)
		if(files) then
			for filename, refCount in pairs(files) do
				-- only export files in the current world directory. 
				if(not self.onlyExportTempFiles or filename:find("temp/", 1, true)) then
					local filepath = (self.onlyExportTempFiles or self.write_reference_from_path) and  commonlib.Encoding.Utf8ToDefault(filename) or (GameLogic.GetWorldDirectory()..commonlib.Encoding.Utf8ToDefault(filename));
					local file = ParaIO.open(filepath, "r")
					if(file:IsValid()) then
						local text = file:GetText(0, -1);
						local fileBlockCount = self:GetBlockCountInString(text);
						totalCount = totalCount + refCount * fileBlockCount;
						file:close();
						if(text and text~="") then
							NPL.load("(gl)script/ide/System/Encoding/base64.lua");
							ref[#ref+1] = {name="file", attr={filename=filename, encoding="base64"}, [1] = System.Encoding.base64(text)}
						end
					end
				end
			end
		end
	end
	if(#ref > 0) then
		o[#o+1] = ref;
	end
	o.attr.count = totalCount;
	self.params.count = totalCount;
	local xml_data = commonlib.Lua2XmlString(o, true, true);
	return xml_data;
end

-- export to ply point cloud file 
function BlockTemplate:SaveToPly()
	local filename = self.filename;
	ParaIO.CreateDirectory(filename);
	local pivot;
	if(not self.blocks) then
		self.params = self.params or {};
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
		local select_task = MyCompany.Aries.Game.Tasks.SelectBlocks.GetCurrentInstance();
		if(select_task) then
			local pivot = select_task:GetPivotPoint();
			local x,y,z = select_task:GetSelectionPivot();
			pivot = {x,y,z}
			self.blocks = select_task:GetCopyOfBlocks(pivot);
		else
			return;
		end
	end
	if(not pivot) then
		for _, b in ipairs(self.blocks) do
			local x,y,z = b[1], b[2], b[3]
			if(not pivot) then
				pivot = {x,y,z};
			else
				pivot[1] = math.min(pivot[1], x);
				pivot[2] = math.min(pivot[2], y);
				pivot[3] = math.min(pivot[3], z);
			end
		end
	end

	local blocks = {}
	local idDataColors = {};
	for _, b in ipairs(self.blocks) do
		local x,y,z, block_id, block_data = b[1], b[2], b[3], b[4], b[5];
		x = x - pivot[1]
		y = y - pivot[2]
		z = z - pivot[3]
		block_data = block_data or 0
		local dataColors = idDataColors[id];
		if(not dataColors) then
			dataColors = {};
			idDataColors[id] = dataColors;
		end
		local color = dataColors[block_data];
		if(not color) then
			color = {255, 255, 255};
			dataColors[block_data] = color;

			local block_template = block_types.get(block_id);
			if(block_template) then
				local c = block_template:GetDiffuseColorByData(block_data or 0);
				if(c) then
					color[1], color[2], color[3] = Color.DWORD_TO_RGBA(c)
				end
			end
		end
		-- swap y and z
		blocks[#blocks+1] = string.format("%d %d %d %d %d %d", x, z, y, color[1], color[2], color[3]);
	end
	local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		file:WriteString(string.format("ply\nformat ascii 1.0\ncomment Created by Paracraft\n"));
		file:WriteString(string.format("element vertex %d\n", #blocks));
		file:WriteString("property float x\nproperty float y\nproperty float z\nproperty uchar red\nproperty uchar green\nproperty uchar blue\n");
		file:WriteString("end_header\n");
		file:WriteString(table.concat(blocks, "\n"));
		file:close();
		LOG.std(nil, "info", "BlockTemplate", "saved to ply file: %s", filename);
		return true;
	end
end

-- Save to template.
-- self.params: root level attributes
-- self.filename: 
-- self.blocks: if nil, the current selection is used. 
function BlockTemplate:SaveTemplate()
	local filename = self.filename;
	if(filename:match("%.ply$")) then
		return self:SaveToPly();
	end

	local xml_data = self:SaveTemplateToString()
	if (xml_data) then
		
		ParaIO.CreateDirectory(filename);
		if #xml_data >= 10240 then
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
	
		if(filename:match("%.bmax$")) then
			-- refresh it if it is a bmax model.
			ParaAsset.LoadParaX("", filename):UnloadAsset();
			LOG.std(nil, "info", "BlockTemplate", "unload to refresh %s", filename);

			Files.NotifyNetworkFileChange(filename);
		end
	end
	return true;
end

function BlockTemplate:Redo()
	if(self.blockX and self.fill_id and (#self.history)>0) then
		BlockEngine:BeginUpdate()
		for _, b in ipairs(self.history) do
			BlockEngine:SetBlock(b[1],b[2],b[3], b[4] or self.fill_id, b[7], nil, b[8]);
		end
		BlockEngine:EndUpdate()
	end
end

function BlockTemplate:Undo()
	if(self.blockX and self.fill_id and (#self.history)>0) then
		BlockEngine:BeginUpdate()
		for _, b in ipairs(self.history) do
			BlockEngine:SetBlock(b[1],b[2],b[3], b[5] or 0, b[6], nil, b[9]);
		end
		BlockEngine:EndUpdate()
	end
end

function BlockTemplate:IsAnimloadFinished()
	return self.finished
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
				if self.blocks_per_tick==nil then
					self.blocks_per_tick = math.floor((#blocks) / ((self.load_anim_duration or 5) * 20)+1);
				end

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
	if(not self.nohistory) then
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