--[[
Title: Mirror blocks
Author(s): LiXizhi
Date: 2014/2/20
Desc: cloning blocks to a destination location, preserving as much information as possible
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MirrorBlocksTask.lua");

local task = MyCompany.Aries.Game.Tasks.MirrorBlocks:new({method="clone", flag, from_aabb, from_blocks, pivot_x=2000,pivot_y=2,pivot_z=20000, mirror_axis="x", })
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")

local MirrorBlocks = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.MirrorBlocks"));


function MirrorBlocks:ctor()
	self.history = {};
end

function MirrorBlocks:Run()
	self.finished = true;
	
	local from_blocks = self:FetchSourceBlock();
	if(from_blocks) then
		self:Mirror();

		if(GameLogic.GameMode:CanAddToHistory()) then
			if(#(self.history) > 0) then
				UndoManager.PushCommand(self);
			end
		end
	end
end

-- get all full info of source block
function MirrorBlocks:FetchSourceBlock()
	if(not self.from_blocks and self.from_aabb) then
		local blocks = {};
		local min = self.from_aabb:GetMin();
		local max = self.from_aabb:GetMax();
		for x = min[1], max[1] do
			for y = min[2], max[2] do
				for z = min[3], max[3] do
					local block_id, block_data, entity_data = BlockEngine:GetBlockFull(x,y,z);
					blocks[#blocks+1] = {x,y,z, block_id, block_data, entity_data}
				end
			end
		end
		self.from_blocks = blocks;
	else
		local blocks = self.from_blocks;
		if(blocks) then
			for i,b in ipairs(self.from_blocks) do
				b[4],b[5],b[6] = BlockEngine:GetBlockFull(b[1],b[2],b[3]);
			end
		end
	end
	return self.from_blocks;
end

function MirrorBlocks.GetMirrorPoint(src_x, src_y, src_z, pivot_x, pivot_y,pivot_z, mirror_axis)
	if(mirror_axis == "x") then
		return pivot_x*2 - src_x, src_y, src_z;
	elseif(mirror_axis == "y") then
		return src_x, pivot_y*2 - src_y, src_z;
	else -- if(mirror_axis == "z") then
		return src_x, src_y, pivot_z*2 - src_z;
	end
end

function MirrorBlocks:MirrorWithAxis(pivot_x, pivot_y,pivot_z, mirror_axis)
	local blocks = self.from_blocks;
	local flag = self.flag;
	local GetMirrorPoint = self.GetMirrorPoint;
	local only_sameblock = self.only_sameblock;
	local method = self.method;
	for i = 1, #blocks do
		local b = blocks[i];
		-- mirror position
		local x,y,z = GetMirrorPoint(b[1], b[2], b[3], pivot_x, pivot_y,pivot_z, mirror_axis);
		-- mirrot block data
		local blockTemplate = block_types.get(b[4]);
		local blockData = b[5];
		if(blockTemplate and blockData) then
			blockData = blockTemplate:MirrorBlockData(blockData, mirror_axis);
		end

		local block_id, block_data, entity_data = BlockEngine:GetBlockFull(x,y,z);

		if(not only_sameblock or b[4] == block_id) then
			self.history[#(self.history)+1] = {x,y,z, block_id, block_data, entity_data};
			
			BlockEngine:SetBlock(x,y,z, b[4] or 0, blockData, flag, b[6]);
			if(method == "no_clone") then
				-- remove source block
				block_id, block_data, entity_data = BlockEngine:GetBlockFull(b[1], b[2], b[3]);
				self.history[#(self.history)+1] = {b[1], b[2], b[3], block_id, block_data, entity_data};
				BlockEngine:SetBlock(b[1], b[2], b[3], 0, nil, flag);
			end
		end
	end
end

function MirrorBlocks:Mirror()
	self.history = {};
	if(not self.from_blocks) then
		return;
	end

	self:MirrorWithAxis(self.pivot_x, self.pivot_y,self.pivot_z, self.mirror_axis);
end

function MirrorBlocks:FrameMove()
	self.finished = true;
end

function MirrorBlocks:Redo()
	if((#self.history)>0) then
		self:Mirror();
	end
end

function MirrorBlocks:Undo()
	if((#self.history)>0) then
		local i, b;
		for i = #(self.history), 1, -1  do
			local b = self.history[i];
			BlockEngine:SetBlock(b[1],b[2],b[3], b[4] or 0, b[5], nil, b[6]);
		end
	end
end
