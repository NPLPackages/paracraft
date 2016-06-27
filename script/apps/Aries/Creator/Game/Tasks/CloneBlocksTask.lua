--[[
Title: Clone blocks
Author(s): LiXizhi
Date: 2014/2/20
Desc: cloning blocks to a destination location, preserving as much information as possible
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CloneBlocksTask.lua");

local task = MyCompany.Aries.Game.Tasks.CloneBlocks:new({flag, from_aabb, from_blocks, to_aabb, to_x,to_y,to_z, only_sameblock=bool})
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")

local CloneBlocks = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.CloneBlocks"));


function CloneBlocks:ctor()
	self.history = {};
end

function CloneBlocks:Run()
	self.finished = true;
	
	local from_blocks = self:FetchSourceBlock();
	if(from_blocks) then
		self:Clone();

		if(GameLogic.GameMode:CanAddToHistory()) then
			if(#(self.history) > 0) then
				UndoManager.PushCommand(self);
			end
		end
	end
end

-- get all full info of source block
function CloneBlocks:FetchSourceBlock()
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

function CloneBlocks:CopyToDeltaPosition(dx,dy,dz)
	local blocks = self.from_blocks;
	local flag = self.flag;
	
	for i = 1, #blocks do
		local b = blocks[i];
		local x,y,z = b[1]+dx,b[2]+dy,b[3]+dz;

		local block_id, block_data, entity_data = BlockEngine:GetBlockFull(x,y,z);

		if(not self.only_sameblock or b[4] == block_id) then
			self.history[#(self.history)+1] = {x,y,z, block_id, block_data, entity_data};
			BlockEngine:SetBlock(x,y,z, b[4] or 0, b[5], flag, b[6]);
		end
	end
end

function CloneBlocks:CopyToAABB(aabb)
	local first_block = self.from_blocks[1];
	local from_x, from_y, from_z = first_block[1], first_block[2], first_block[3];
	local history = self.history;
	local min = aabb:GetMin();
	local max = aabb:GetMax();
	for x = min[1], max[1] do
		for y = min[2], max[2] do
			for z = min[3], max[3] do
				self:CopyToDeltaPosition(x-from_x, y-from_y, z-from_z);
			end
		end
	end
end

function CloneBlocks:Clone()
	self.history = {};
	if(not self.from_blocks) then
		return;
	end
	if(self.to_aabb) then
		self:CopyToAABB(self.to_aabb)
	elseif(self.to_x) then
		local first_block = self.from_blocks[1];
		if(first_block) then
			local from_x, from_y, from_z = first_block[1], first_block[2], first_block[3];
			self:CopyToDeltaPosition(self.to_x-from_x, self.to_y-from_y, self.to_z-from_z);
		end
	end
end

function CloneBlocks:FrameMove()
	self.finished = true;
end

function CloneBlocks:Redo()
	if((#self.history)>0) then
		self:Clone();
	end
end

function CloneBlocks:Undo()
	if((#self.history)>0) then
		local i, b;
		for i = #(self.history), 1, -1  do
			local b = self.history[i];
			BlockEngine:SetBlock(b[1],b[2],b[3], b[4] or 0, b[5], nil, b[6]);
		end
	end
end
