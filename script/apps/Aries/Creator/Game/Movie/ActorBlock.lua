--[[
Title: block actor
Author(s): LiXizhi
Date: 2014/4/17
Desc: for recording and playing back of block creation and deletion. 
This is different from ActorBlocks, in that it will record one creation or deletion action per keyframe. 
This class is thus used by ActorNPC for block creation and deletion playback. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorBlocks.lua");
local actor = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorBlock");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/Actor.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TimeSeries.lua");
local TimeSeries = commonlib.gettable("MyCompany.Aries.Game.Common.TimeSeries");
local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks")
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Actor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Movie.Actor"), commonlib.gettable("MyCompany.Aries.Game.Movie.ActorBlock"));

function Actor:ctor()
	-- this is precalculated temporary data set. 
	self.TimeSeries_blocks = TimeSeries:new{name = "Actor",};
	self.blocks = self.TimeSeries_blocks:CreateVariableIfNotExist("blocks", "Discrete");
end

function Actor:Init(itemStack, movieclipEntity)
	if(not Actor._super.Init(self, itemStack, movieclipEntity)) then
		return;
	end
	
	local timeseries = self.TimeSeries;
	timeseries:CreateVariableIfNotExist("block", "Discrete");

	self:InitializeTimeSeries();
	return self;
end

-- remove all blocks
function Actor:OnRemove()
	local blocks = self.blocks:getValue(1, 0);
	if(blocks) then
		for sparse_index, b in pairs(blocks) do
			if(b[1]) then
				BlockEngine:SetBlock(b[1], b[2], b[3], b[4], b[5]);
			end
		end
	end
end

-- update block set in block time series variable as well as the given new_blocks 
-- precalculate time series
function Actor:InitializeTimeSeries()
	local v = self:GetVariable("block");
	
	local block_set = {};
	local block_set_time0 = {};
	for i, blocks in ipairs(v.data) do
		for sparse_index, b in pairs(blocks) do
			if(not block_set[sparse_index]) then
				block_set[sparse_index] = b;
				local x,y,z = b[1], b[2], b[3];
				block_set_time0[sparse_index] = {x,y,z, BlockEngine:GetBlockId(x,y,z), BlockEngine:GetBlockData(x,y,z)}
			end
		end
	end
	self.blocks:TrimEnd(0);
	self.blocks:AutoAppendKey(0, block_set_time0, true);

	local last_block_set = block_set_time0;
	for i, blocks in ipairs(v.data) do
		local cur_set = commonlib.copy(last_block_set);
		for sparse_index, b in pairs(blocks) do
			cur_set[sparse_index] = b;
		end
		local time = v.times[i];
		self.blocks:AutoAppendKey(time, cur_set, true);
		last_block_set = cur_set;
	end
end

-- clear all record to a given time. if curTime is nil, it will use the current time. 
function Actor:ClearRecordToTime(curTime)
	Actor._super.ClearRecordToTime(self, curTime);
	self.blocks:TrimEnd(curTime);
end

-- add movie blocks at the current time. 
-- @param blocks: {{x,y,z,block_id, block_data, last_block_id = number, last_block_data = number, }, ...}
function Actor:AddKeyFrameOfBlocks(new_blocks)
	if(new_blocks) then
		local curTime = self:GetTime();

		local last_blocks = self.blocks:getValue(1, curTime);
		if(not last_blocks) then
			last_blocks = {};
			self.blocks:AutoAppendKey(0, last_blocks, true);
		end
		local blocks = {};
		
		for _, b in ipairs(new_blocks) do
			-- {x,y,z,block_id, block_data}
			local x,y,z = b[1], b[2], b[3];
			if(x and y and z) then
				local sparse_index = BlockEngine:GetSparseIndex(x,y,z);
				blocks[sparse_index] = {x,y,z, b[4], b[5]};
			
				local last_block_id = b.last_block_id or BlockEngine:GetBlockId(x,y,z);
				local last_block_data = b.last_block_data or BlockEngine:GetBlockData(x,y,z);

				if(not last_blocks[sparse_index]) then
					for i, blocks in ipairs(self.blocks.data) do
						blocks[sparse_index] = {x,y,z, last_block_id, last_block_data};
					end
				end
			end
		end
		if(next(blocks)) then
			self:AddKeyFrameByName("block", curTime, blocks);

			local cur_set = commonlib.copy(last_blocks);
			for sparse_index, b in pairs(blocks) do
				cur_set[sparse_index] = b;
			end
			self.blocks:AutoAppendKey(curTime, cur_set, true);
		end
	end
end

-- @param blocks: update blocks. 
function Actor:UpdateBlocks(blocks, curTime)
	if(blocks) then
		local block_pieces_count = 0;
		for sparse_index, b in pairs(blocks) do
			local x,y,z = b[1], b[2], b[3];
			local cur_block_id = BlockEngine:GetBlockId(x,y,z);
			local new_block_id = b[4];
			if( cur_block_id ~= new_block_id) then
				if(new_block_id == 0) then
					BlockEngine:SetBlockToAir(x,y,z);

					block_pieces_count = block_pieces_count + 1;
					if(block_pieces_count <= 27) then
						-- create some block pieces
						local block_template = block_types.get(cur_block_id);
						if(block_template) then
							block_template:CreateBlockPieces(x,y,z);
						end
					end
				else
					BlockEngine:SetBlock(x,y,z, new_block_id, b[5]);
				end
			end
		end
	end
end

function Actor:FrameMovePlaying(deltaTime)
	local curTime = self:GetTime();
	if(not curTime) then
		return
	end
	local blocks = self.blocks:getValue2(1, curTime);
	if(self.last_blocks ~= blocks) then
		self.last_blocks = blocks;
		self:UpdateBlocks(blocks);
	end
end
