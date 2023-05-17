--[[
Title: Change block types(Color blocks)
Author(s): LiXizhi
Date: 2013/1/19
Desc: Replace all blocks with a given block_id; 
Support undo/redo
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ReplaceBlockTask.lua");
local task = MyCompany.Aries.Game.Tasks.ReplaceBlock:new({blockX, blockY, blockZ, from_id, [from_data,] to_id, to_data=nil, max_radius = 20, preserveRotation = true})
-- if max_radius=0, it just replace the one clicked
local task = MyCompany.Aries.Game.Tasks.ReplaceBlock:new({blocks={}, to_id=number})
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local ReplaceBlock = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.ReplaceBlock"));
local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

ReplaceBlock.max_radius = 0;
ReplaceBlock.to_data = 0;
ReplaceBlock.from_data = 0;
ReplaceBlock.preserveRotation = false;
ReplaceBlock.replace_num = 0
function ReplaceBlock:ctor()
	self.step = 1;
	self.blocks = self.blocks or {};
	self.new_blocks = {};
	self.history = {};
	self.replaced_map = {};
end

function ReplaceBlock:Run()
	if(not self.to_id) then
		return;
	elseif(self.to_id > 256 ) then
		-- maybe a custom block?
		local block = block_types.get(self.to_id);
		if(not block) then
			return;
		end
	end
	self.to_data = self.to_data or 0;

	if(self.radius and self.blockX and self.mode=="all" and self.from_id and self.to_id) then
		if(self:ReplaceBlockInRegion(self.blockX,self.blockZ, self.radius or 256, self.from_id, self.to_id) > 0) then
			TaskManager.AddTask(self);
			GameLogic.SetModified();
		end
	elseif(next(self.blocks) and self.to_id) then
		local _, block
		for _, block in ipairs(self.blocks) do
			self:ReplaceBlock(block[1], block[2], block[3]);
		end
		TaskManager.AddTask(self);
		GameLogic.SetModified();
	elseif(self.blockX and self.to_id) then
		if(not self.from_id) then
			self.from_id, self.from_data = BlockEngine:GetBlockFull(self.blockX, self.blockY, self.blockZ);
			if(self.from_id and self.from_id>0 and 
				(self.from_id ~= self.to_id or self.from_data~=self.to_data) ) then
				
				self:ReplaceBlock(self.blockX, self.blockY, self.blockZ);
				self.blocks[#(self.blocks)+1] = {self.blockX, self.blockY, self.blockZ};

				local tx, ty, tz = BlockEngine:real(self.blockX,self.blockY,self.blockZ);
				GameLogic.PlayAnimation({animationName = "Create",facingTarget = {x=tx, y=ty, z=tz},});
				TaskManager.AddTask(self);
				GameLogic.SetModified();
			end
		end
	end
end

-- replace all blocks in a given region
function ReplaceBlock:ReplaceBlockInRegion(cx,cz, radius, from_id, to_id)
	local count = 0;
	for x = cx-radius, cx+radius do
		for z = cz-radius, cz+radius do
			count = self:ReplaceBlockInColumn(x,z, from_id, to_id) + count;
		end
	end
	return count;
end

function ReplaceBlock:ReplaceBlockInColumn(x,z, from_id, to_id)
	local count = 0;
	local y = 256;
	while(y>0) do
		local dist = ParaTerrain.GetFirstBlock(x,y,z,from_id, 5, 255);
		if(dist>0) then
			y = y - dist;
			self:ReplaceBlock(x,y,z);
			count = count + 1;
		else
			y = -1;
		end
	end
	return count;
end

function ReplaceBlock:ReplaceBlock(x, y, z)
	local from_id, from_data, from_entity_data = BlockEngine:GetBlockFull(x,y,z)
	if(not self.from_id) then
		if(from_id ~= self.to_id or (self.to_data or 0) ~= from_data) then
			BlockEngine:SetBlock(x,y,z, self.to_id, self.to_data or 0, 3);
			ReplaceBlock.replace_num = ReplaceBlock.replace_num + 1
			if(GameLogic.GameMode:CanAddToHistory()) then
				self.history[#(self.history)+1] = {x,y,z, from_id, from_data, from_entity_data};
			end
		end
	elseif( from_id == self.from_id) then
		local fromBlock = block_types.get(from_id);
		if( (fromBlock and fromBlock.color_data and from_data == self.from_data) or 
			(fromBlock and fromBlock.color8_data and band(from_data, 0xff00)==band(self.from_data, 0xff00)) or 
			(fromBlock and not fromBlock.color8_data and not fromBlock.color_data)) then
			local idx = BlockEngine:GetSparseIndex(x,y,z);
			if(not self.replaced_map[idx]) then
				self.replaced_map[idx] = true;
				self.new_blocks[#(self.new_blocks)+1] = {x,y,z};

				local to_data = self.to_data or 0;
				if(self.preserveRotation) then
					local toBlock = block_types.get(self.to_id);
					if(toBlock and fromBlock and ((toBlock == fromBlock) or (toBlock.modelName and toBlock.modelName == fromBlock.modelName))) then
						-- they are of the same block model type. 
						if(toBlock.color8_data) then
							to_data = band(from_data, 0x00ff) + band(to_data, 0xff00);
						elseif(fromBlock.color8_data) then
							to_data = band(from_data, 0x00ff);
						elseif(toBlock ~= fromBlock) then
							to_data = from_data or to_data
						end
					end
				end
				BlockEngine:SetBlock(x,y,z, self.to_id, to_data or 0, 3);
				ReplaceBlock.replace_num = ReplaceBlock.replace_num + 1
				if(GameLogic.GameMode:CanAddToHistory()) then
					self.history[#(self.history)+1] = {x,y,z, from_id, from_data, from_entity_data};
				end
			end
		end
	end
end

function ReplaceBlock:FrameMove()
	if(self.max_radius >0) then
		local from_id = self.from_id;
		local _, block;
		self.new_blocks = {};
		self.step = self.step + 1;
		for _, block in ipairs(self.blocks) do
			local x, y, z = block[1], block[2], block[3];
			self:ReplaceBlock(x+1,y,z);
			self:ReplaceBlock(x-1,y,z);
			self:ReplaceBlock(x,y+1,z);
			self:ReplaceBlock(x,y-1,z);
			self:ReplaceBlock(x,y,z+1);
			self:ReplaceBlock(x,y,z-1);
		end
	end

	if(#(self.new_blocks) > 0 and self.step < self.max_radius) then
		self.blocks = self.new_blocks;
	else
		self.finished = true;
		if(GameLogic.GameMode:CanAddToHistory()) then
			if(#(self.history) > 0) then
				UndoManager.PushCommand(self);
			end
		end
		GameLogic.GetFilters():apply_filters("lessonbox_change_region_blocks",ReplaceBlock.replace_num)
		ReplaceBlock.replace_num = 0
	end
end

function ReplaceBlock:Redo()
	if(self.to_id and (#self.history)>0) then
		local _, b;
		for _, b in ipairs(self.history) do
			BlockEngine:SetBlock(b[1],b[2],b[3], self.to_id, self.to_data or 0, 3);
		end
	end
end

function ReplaceBlock:Undo()
	if((#self.history)>0) then
		local _, b;
		for _, b in ipairs(self.history) do
			BlockEngine:SetBlock(b[1],b[2],b[3], self.from_id or b[4], b[5] or 0, 3, b[6]);
		end
	end
end

-- @param blocks: if nil, it means entire blocks, or it will only replace in these blocks
-- @param bRegularExpression: true to use regular expression. 
-- @return the number of blocks replaced
function ReplaceBlock:ReplaceFile(from, to, blocks, bRegularExpression)
	if(from == to or not from or not to) then
		return
	end
	
	local entities;
	if(not blocks) then
		-- all blocks & entities in the world
		entities = EntityManager.FindEntities({category="all", });
	else
		entities = {};
		-- only selected blocks
		for _, b in ipairs(blocks) do
			local entity = EntityManager.GetBlockEntity(b[1], b[2], b[3])
			if(entity) then
				entities[#entities+1] = entity;
			end
		end
	end
	local count = self:ReplaceFileInEntities(from, to, entities, bRegularExpression);
	GameLogic.AddBBS(nil, format(L"%d个方块中的文件被替换", count))
	return count;
end

-- @param from, to: utf8 encoded string
function ReplaceBlock:ReplaceFileInEntities(from, to, entities, bRegularExpression)
	local movieBlockId = block_types.names.MovieClip;
	local PhysicsModel = block_types.names.PhysicsModel;
	local BlockModel = block_types.names.BlockModel;

	local count = 0;
	if(entities) then
		if(bRegularExpression) then
			local fromDefaultEncoding = commonlib.Encoding.Utf8ToDefault(from)
			local toDefaultEncoding = commonlib.Encoding.Utf8ToDefault(to)
			for _, entity in ipairs(entities) do
				local block_id = entity:GetBlockId()
				if(entity:IsPersistent() and entity.ReplaceFileRegularExpression and entity:ReplaceFileRegularExpression(fromDefaultEncoding, toDefaultEncoding)>0) then
					count = count + 1;
				end
			end
		else
			for _, entity in ipairs(entities) do
				local block_id = entity:GetBlockId()
				if(block_id == movieBlockId) then
					if(entity:ReplaceFile(from, to)>0) then
						count = count + 1;
					end
				elseif(block_id == PhysicsModel or block_id == BlockModel) then
					if(entity:GetModelFile() == from) then
						entity:SetModelFile(to);
						entity:Refresh()
						count = count + 1;
					end
				elseif(entity:IsPersistent() and entity.ReplaceFile and entity:ReplaceFile(from, to)>0) then
					count = count + 1;
				end
			end
		end
	end
	return count;
end